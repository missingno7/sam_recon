"""Build a proof harness around one candidate routine.

Candidate file format (Pascal; markers are comments on their own line):

    {@decls}
    type TFoo = record ... end;          types and untyped constants  -> unit SAMTYPES
    const K = 5;
    var d_02A4: Word;                    globals, named d_<SAM1 offset> (layout/data.json)
    const d_01C6: array[0..3] of Word = (1, 2, 3, 4);   typed constants likewise
    {@stubs}
    procedure u3_1a2b(a: Integer);       every called game routine, by logical id
    function u5_0f9b(x: Word): Byte;
    {@body}
    procedure u3_6ea9(...);              the target (with its nested routines)
    begin ... end;

The harness reproduces the original data segment of the episode exactly:

  * program H holds the data of the program and units u1..u8 (typed constants
    first, then variables, both in offset order, gaps filled with byte arrays);
  * unit U9 holds u9's variables, linked between Crt and Dos as in the
    original (`uses Dos, U9, Crt` gives the link order H, ..., Crt, U9, Dos, System);
  * other game units become data-free stub units U1..U9 with the callees' headers;
  * routines of the target's own unit are forward-declared stubs in H (far when
    the original callee returns with RETF), the target itself is wrapped in
    {$F+} when the original returns with RETF.

The harness is compiled twice: the first map gives the real offsets of typed
declarations, the second fixes the gap arrays.  Every d_XXXX global and the
library anchors (PREFIXSEG, CHECKBREAK, DOSERROR, INPUT) must land on the
original offsets and the DATA segment must have the original length, or the
harness is rejected (a layout error is never a code mismatch).
"""
from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, EVIDENCE, LAYOUT, load_json  # noqa: E402
import oracle  # noqa: E402
import tpc  # noqa: E402
import tpmap  # noqa: E402

GAME_UNITS = ("u1", "u2", "u3", "u4", "u5", "u6", "u7", "u8", "u9")
_GLOBAL = re.compile(r"^d_(?:(sam[123])_)?([0-9A-F]{4})$", re.I)


class HarnessError(RuntimeError):
    """The harness could not be built or does not reproduce the data layout."""


# ---------------------------------------------------------------- candidate parsing

def split_sections(text: str) -> dict:
    out = {"decls": "", "stubs": "", "body": ""}
    cur = None
    buf: list = []
    for line in text.splitlines():
        m = re.match(r"^\s*\{@(decls|stubs|body)\}\s*$", line, re.I)
        if m:
            if cur:
                out[cur] = "\n".join(buf)
            cur, buf = m.group(1).lower(), []
            continue
        if cur:
            buf.append(line)
    if cur:
        out[cur] = "\n".join(buf)
    if not out["body"].strip():
        raise HarnessError("candidate has no {@body} section")
    return out


def _strip_comments(s: str) -> str:
    s = re.sub(r"\{[^$][^}]*\}|\{\}", " ", s)
    return re.sub(r"\(\*.*?\*\)", " ", s, flags=re.S)


def _statements(text: str) -> list:
    """Split declarations on ';' at nesting depth 0 (parentheses, record..end)."""
    out, cur, depth, i = [], [], 0, 0
    toks = re.findall(r"'(?:[^']|'')*'|\w+|[^\w\s]|\s+", text)
    for t in toks:
        lo = t.lower()
        if lo in ("record", "(") or (lo == "case" and depth > 0 and False):
            depth += 1
        elif lo in ("end", ")"):
            depth -= 1
        if t == ";" and depth == 0:
            out.append("".join(cur).strip())
            cur = []
        else:
            cur.append(t)
    if "".join(cur).strip():
        out.append("".join(cur).strip())
    return [s for s in out if s]


@dataclass
class Decls:
    shared: list = field(default_factory=list)     # type/untyped-const text blocks -> SAMTYPES
    globals: dict = field(default_factory=dict)    # name -> declaration ("name: T" or "name: T = v")
    typed_const: set = field(default_factory=set)


def parse_decls(text: str) -> Decls:
    d = Decls()
    section = None
    for st in _statements(_strip_comments(text)):
        m = re.match(r"^(type|const|var)\b\s*(.*)$", st, re.I | re.S)
        if m:
            section, st = m.group(1).lower(), m.group(2).strip()
            if not st:
                continue
        if section is None:
            raise HarnessError(f"declaration outside type/const/var: {st[:60]!r}")
        if section == "type":
            d.shared.append(("type", st))
            continue
        names = st.split(":", 1)[0] if ":" in st else st.split("=", 1)[0]
        if section == "const" and (":" not in st or st.index("=") < st.index(":")):
            d.shared.append(("const", st))
            continue
        for name in (n.strip() for n in names.split(",")):
            if not _GLOBAL.match(name):
                raise HarnessError(f"global {name!r} must be named d_XXXX after its SAM1 offset")
            d.globals[name.upper()] = name + ":" + st.split(":", 1)[1]
            if section == "const":
                d.typed_const.add(name.upper())
    return d


_HEADER = re.compile(r"^\s*(procedure|function)\s+(\w+)", re.I)


def parse_stubs(text: str) -> list:
    """[(name, header_text)] for every callee header."""
    out = []
    for st in _statements(_strip_comments(text)):
        m = _HEADER.match(st)
        if not m:
            raise HarnessError(f"stub is not a procedure/function header: {st[:60]!r}")
        out.append((m.group(2).lower(), st + ";"))
    return out


def target_name(body: str) -> str:
    """The last top-level routine header in the body (nested routines precede it)."""
    names = re.findall(r"(?im)^(?:procedure|function)\s+(\w+)", _strip_comments(body))
    if not names:
        raise HarnessError("no procedure/function in {@body}")
    return names[-1].lower()


# ---------------------------------------------------------------- original facts

def unit_of(lid: str) -> str:
    return lid.split("_", 1)[0].lower()


@__import__("functools").lru_cache(maxsize=None)
def is_far(ep: str, lid: str) -> bool | None:
    atlas = load_json(EVIDENCE / "atlas.json")
    r = atlas["routines"].get(lid)
    if not r or ep not in r["episodes"]:
        return None
    e = r["episodes"][ep]
    cen = load_json(BUILD / "census" / f"{ep}.json")
    seg = cen["segments"][atlas["units"].index(e["unit"])]
    img, _ = oracle.load_image(ep)
    import capstone
    md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
    kinds = {i.mnemonic for i in md.disasm(img[seg["start"] + e["entry"]:seg["start"] + e["end"]], 0)}
    if "iret" in kinds:
        return None
    if "retf" in kinds:
        return True
    if "ret" in kinds:
        return False
    return None


REF_PROGRAM = """program H;
uses Dos, U9, Crt;
begin
  ClrScr; DosError := 0; U9P;
end.
"""
REF_U9 = """unit U9;
interface
uses Dos;
procedure U9P;
implementation
procedure U9P;
begin
end;
end.
"""


def anchors(ep: str) -> dict:
    """Original DS offsets of the library anchors, measured by aligning the Crt and
    System initialisation code with a reference harness (tools/harness.py docs)."""
    cache = BUILD / "harness" / f"anchors-{ep}.json"
    if cache.exists():
        return load_json(cache)
    from datalayout import ds_operands
    ref = tpc.compile_program({"H.PAS": REF_PROGRAM, "U9.PAS": REF_U9}, "H.PAS", ["/GD"])
    m = tpmap.parse(ref.map("H"))
    exe = ref.exe("H")
    himg = exe[int.from_bytes(exe[8:10], "little") * 16:]
    img, _ = oracle.load_image(ep)
    cen = load_json(BUILD / "census" / f"{ep}.json")
    names = load_json(EVIDENCE / "atlas.json")["units"]
    d = m.data().para
    pub = {n: o for n, (s, o) in m.publics.items() if s == d}
    if not pub["CHECKBREAK"] < pub["DOSERROR"] < pub["INPUT"]:
        raise HarnessError(f"reference harness data order unexpected: {pub}")
    # Pair the DS operands of the Crt and System initialisation code; each operand
    # tells the delta of the library block it falls in.
    deltas = {"sysconst": set(), "crtvar": set(), "sysvar": set()}
    for unit, seg, n in (("crt", "CRT", 0x60), ("sys", "SYSTEM", 0x40)):
        s = cen["segments"][names.index(unit)]["start"]
        hs = m.segment(seg).start
        for x, y in zip(ds_operands(img[s:s + n], 0), ds_operands(himg[hs:hs + n], 0)):
            if x[:2] != y[:2]:
                continue
            block = ("sysconst" if y[2] < pub["CHECKBREAK"] else
                     "crtvar" if y[2] < pub["DOSERROR"] else "sysvar")
            deltas[block].add(x[2] - y[2])
    if any(len(v) != 1 for v in deltas.values()):
        raise HarnessError(f"inconsistent library deltas for {ep}: {deltas}")
    dc, dv, ds = (deltas[k].pop() for k in ("sysconst", "crtvar", "sysvar"))
    lock = load_json(LAYOUT / "oracle.lock.json")["episodes"][ep]["unpacked"]
    out = {"PREFIXSEG": pub["PREFIXSEG"] + dc,
           "CHECKBREAK": pub["CHECKBREAK"] + dv,
           "INPUT": pub["INPUT"] + ds,
           "DOSERROR": pub["DOSERROR"] + ds,
           "game_const_end": dc,                               # System's typed constants follow
           "game_var_start": dc + pub["CHECKBREAK"],           # ... and end where variables begin
           "crt_var_start": pub["CHECKBREAK"] + dv,
           "crt_var_end": pub["DOSERROR"] + dv,                # U9 is empty in the reference
           "ds_size": (lock["ss"] - cen["ds_para"]) * 16}
    # Turbo Pascal's smart linker drops unreferenced variables too: Dos's DosError
    # exists in the original only if some original code references it.
    refs = load_json(BUILD / "datamap" / f"{ep}.json")["refs"]
    if f"{out['DOSERROR']:04X}" not in refs:
        out["DOSERROR"] = None
    out["u9_var_start"] = out["crt_var_end"]
    out["u9_var_end"] = out["DOSERROR"] if out["DOSERROR"] is not None else out["INPUT"]
    cache.parent.mkdir(parents=True, exist_ok=True)
    cache.write_text(__import__("json").dumps(out, indent=1))
    return out


def extra_offset(name: str, ep: str) -> int | None:
    """Offset in `ep` of a candidate global the data map never saw referenced
    directly (e.g. a 1-based array whose code displacement is base - element size).
    d_XXXX is SAM1 offset XXXX, moved by the delta of the nearest mapped global
    below it; d_samN_XXXX exists only in that episode."""
    m = _GLOBAL.match(name)
    if not m:
        return None
    only, off = m.group(1), int(m.group(2), 16)
    if only:
        return off if only.lower() == ep else None
    g = load_json(LAYOUT / "data.json")["globals"]
    below = [(int(v["sam1"], 16), int(v[ep], 16)) for v in g.values()
             if v.get("sam1") and v.get(ep) and int(v["sam1"], 16) <= off]
    if not below:
        return off
    s1, e = max(below)
    return off + (e - s1)


def episode_globals(ep: str) -> dict:
    """name -> DS offset in `ep` for every referenced global."""
    g = load_json(LAYOUT / "data.json")["globals"]
    return {n.upper(): int(v[ep], 16) for n, v in g.items() if v.get(ep)}


# ---------------------------------------------------------------- generation

def _wrap(items: list, indent: str = "    ", width: int = 100) -> str:
    lines, cur = [], indent
    for it in items:
        if len(cur) + len(it) + 2 > width:
            lines.append(cur.rstrip())
            cur = indent
        cur += it + ", "
    lines.append(cur.rstrip().rstrip(","))
    return "\n".join(lines)


def _pad_decl(name: str, n: int, typed: bool, off: int | None = None) -> str:
    """Byte filler of n bytes at `off`.  Under {$A+} Turbo Pascal word-aligns every
    variable/typed constant larger than one byte, so a filler starting at an odd
    offset is a Byte followed by an (even) array."""
    if n <= 0:
        return ""
    if off is None:
        m = re.search(r"([0-9A-F]{4})$", name, re.I)
        off = int(m.group(1), 16) if m else 0
    if off % 2 and n > 1:
        return _pad_decl(name, 1, typed, off) + "\n  " + _pad_decl(f"pad_{off + 1:04X}", n - 1, typed, off + 1)
    t = f"{name}: Byte" if n == 1 else f"{name}: array[0..{n - 1}] of Byte"
    if typed:
        return t + (" = 0;" if n == 1 else " = (\n" + _wrap(["0"] * n) + ");")
    return t + ";"


def _region(globals_at: list, start: int, end: int, cand: Decls, typed: bool, sizes: dict) -> list:
    """Declarations covering [start, end) in offset order.  `globals_at` is
    [(offset, NAME)]; candidate-declared names use their own declaration (size from
    `sizes` once known), the rest are byte arrays up to the next global."""
    decls = []
    pts = []
    covered = -1
    for o, n in sorted((o, n) for o, n in globals_at if start <= o < end):
        if o < covered and n not in cand.globals:
            continue            # interior of a candidate-typed global (e.g. a pointer's segment word)
        pts.append((o, n))
        if n in cand.globals and sizes.get(n):
            covered = max(covered, o + sizes[n])
    pos = start
    for i, (off, name) in enumerate(pts):
        nxt = pts[i + 1][0] if i + 1 < len(pts) else end
        if off > pos:
            decls.append(_pad_decl(f"pad_{pos:04X}", off - pos, typed))
        if name in cand.globals:
            decls.append(cand.globals[name] + ";")
            size = sizes.get(name, 0)
            pos = off + size
            if size and pos < nxt:
                decls.append(_pad_decl(f"pad_{pos:04X}", nxt - pos, typed))
                pos = nxt
            elif not size:
                pos = off      # unknown until the first map
        else:
            decls.append(_pad_decl(name.lower(), nxt - off, typed, off))
            pos = nxt
    if pts and pts[-1][1] in cand.globals and sizes.get(pts[-1][1]) is None:
        pass
    elif pos < end:
        decls.append(_pad_decl(f"pad_{pos:04X}", end - pos, typed))
    return [d for d in decls if d]


@dataclass
class Harness:
    episode: str
    target: str
    sources: dict
    receipt: tpc.Receipt | None = None
    map: tpmap.Map | None = None
    layout_errors: list = field(default_factory=list)
    body_h_line: int = 0        # 1-based line of the body's first line in its module
    body_c_line: int = 0        # ... and in the candidate file
    mode: str = "routine"       # routine | init | main
    unit: str = ""
    body_module: str = "H"
    stub_lines: dict = field(default_factory=dict)
    init_names: dict = field(default_factory=dict)

    def stub_names(self) -> dict:
        """(segment paragraph, offset) -> stub name, from the map's line records."""
        out = {}
        for module, by_line in self.stub_lines.items():
            for ln, seg, off in (self.map.lines.get(module, []) if self.map else []):
                if ln in by_line:
                    out[(seg, off)] = by_line[ln]
        return out

    def candidate_line(self, linear: int) -> int | None:
        """Candidate source line whose code contains linear image offset `linear`."""
        if not self.map:
            return None
        recs = [(s * 16 + o, ln) for ln, s, o in self.map.lines.get(self.body_module, [])]
        best = max(((a, ln) for a, ln in recs if a <= linear), default=None)
        if best is None or best[1] < self.body_h_line:
            return None
        return best[1] - self.body_h_line + self.body_c_line


def init_lids(ep: str) -> dict:
    """unit -> logical id of its initialisation block (units with an init in the original)."""
    atlas = load_json(EVIDENCE / "atlas.json")
    cen = load_json(BUILD / "census" / f"{ep}.json")
    paras = [s["para"] for s in cen["segments"]]
    out = {}
    for seg, off in cen["inits"]:
        unit = atlas["units"][paras.index(seg)]
        for lid, r in atlas["routines"].items():
            e = r["episodes"].get(ep)
            if e and e["unit"] == unit and e["entry"] == off:
                out[unit] = lid
    return out


def _nlines(lines: list) -> int:
    return sum(x.count("\n") + 1 for x in lines)


CANONICAL = Path(__file__).resolve().parents[1] / "src" / "decls" / "canonical.pas"
_CANON_CACHE: dict = {}


def canonical() -> dict:
    """Shared declarations every harness includes: {@types} (types, untyped constants),
    {@globals} (var/const d_XXXX), {@routines} (one header per known routine)."""
    if not CANONICAL.exists():
        return {"decls": Decls(), "routines": []}
    st = CANONICAL.stat()
    key = (st.st_size, st.st_mtime_ns)
    if _CANON_CACHE.get("key") != key:
        text = CANONICAL.read_text(encoding="latin-1")
        parts = {"types": "", "globals": "", "routines": ""}
        cur = None
        for line in text.splitlines():
            m = re.match(r"^\s*\{@(types|globals|routines)\}\s*$", line, re.I)
            if m:
                cur = m.group(1).lower()
                continue
            if cur:
                parts[cur] += line + "\n"
        d = parse_decls(parts["types"] + "\n" + parts["globals"])
        _CANON_CACHE.update(key=key, value={"decls": d, "routines": parse_stubs(parts["routines"])})
    return _CANON_CACHE["value"]


def _decl_name(kind_st: tuple) -> str:
    return re.split(r"[=:\s]", kind_st[1].strip(), 1)[0].lower()


def merge_decls(canon: Decls, own: Decls, ep: str, sizes: dict) -> Decls:
    """Canonical declarations overridden by the candidate's: types/constants by name,
    globals by name; a canonical global overlapping a candidate global is dropped
    (sizes known after the first build pass)."""
    out = Decls()
    own_names = {_decl_name(x) for x in own.shared}
    out.shared = [x for x in canon.shared if _decl_name(x) not in own_names] + list(own.shared)
    out.globals = dict(canon.globals)
    out.typed_const = set(canon.typed_const)
    if sizes:
        glob = episode_globals(ep)

        def span(n):
            o = glob.get(n, extra_offset(n, ep))
            return (o, o + max(1, sizes.get(n, 1))) if o is not None else None
        mine = [span(n) for n in own.globals]
        for n in list(out.globals):
            if n in own.globals:
                continue
            s = span(n)
            if s and any(m and m[0] < s[1] and s[0] < m[1] for m in mine):
                del out.globals[n]
                out.typed_const.discard(n)
    for n, d in own.globals.items():
        out.globals[n] = d
        if n in own.typed_const:
            out.typed_const.add(n)
        else:
            out.typed_const.discard(n)
    return out


def merge_stubs(canon: list, own: list) -> list:
    names = {n for n, _ in own}
    return [x for x in canon if x[0] not in names] + list(own)


def _stub_def(hdr: str) -> str:
    """Short-form definition of a (forward/interface-declared) routine."""
    m = _HEADER.match(hdr)
    return f"{m.group(1)} {m.group(2)};"


def generate(candidate: str, ep: str, function: str | None = None, sizes: dict | None = None,
             options: list | None = None) -> Harness:
    """Modes: a routine ({@body} holds procedure/function definitions; the target is the
    last one), INIT (body `begin ... end.` of unit `function`'s initialisation) and MAIN
    (body `begin ... end.` of the program, function p_<entry>)."""
    sec = split_sections(candidate)
    own_decls = parse_decls(sec["decls"])
    canon = canonical()
    cand = merge_decls(canon["decls"], own_decls, ep, sizes or {})
    stubs = merge_stubs(canon["routines"], parse_stubs(sec["stubs"]))
    body = sec["body"].strip("\n")
    statement_body = re.match(r"(?is)^\s*begin\b", _strip_comments(body)) is not None
    if statement_body:
        if not function:
            raise HarnessError("an INIT/MAIN body needs --function")
        tgt = function.lower()
        tunit = unit_of(tgt)
        mode = "main" if tunit == "p" else "init"
        body = re.sub(r"(?is)end\s*[.;]?\s*$", "end.", body.rstrip())
    else:
        tgt = target_name(body)
        if function and function.lower() != tgt:
            raise HarnessError(f"body defines {tgt}, expected {function}")
        tunit = unit_of(tgt)
        mode = "routine"
    sizes = sizes or {}
    an = anchors(ep)
    glob = episode_globals(ep)
    for n in [n for n in cand.globals if n not in glob]:
        off = extra_offset(n, ep)
        if off is None:
            del cand.globals[n]      # a global this episode does not have: drop the view
        else:
            glob[n] = off
    pts = [(o, n) for n, o in glob.items()]
    h_const = _region(pts, 0, an["game_const_end"], cand, True, sizes)
    h_var = _region(pts, an["game_var_start"], an["crt_var_start"], cand, False, sizes)
    u9_var = _region(pts, an["u9_var_start"], an["u9_var_end"], cand, False, sizes)
    keep = [n for d in h_const + h_var + u9_var for n in re.findall(r"(?m)^\s*(\w+)\s*:", d)]
    inits = init_lids(ep)

    shared = ""
    for kind, st in cand.shared:
        shared += f"{kind}\n  {st};\n"
    sources = {"SAMTYPES.PAS": "unit SAMTYPES;\ninterface\n" + shared + "implementation\nend.\n"}
    # The program's and units u1..u8's data live in unit GDATA: `uses Dos, U9, Crt,
    # SAMTYPES, GDATA, U1..U8` links H, U8..U1, GDATA, Crt, U9, Dos, System, and only
    # GDATA, Crt, U9, Dos and System have data, so GDATA's data starts at DS:0 and
    # units (an INIT harness) can see the globals too.
    gdata = ["unit GDATA;", "interface", "uses SAMTYPES;"]
    if h_const:
        gdata += ["const"] + ["  " + d for d in h_const]
    if h_var:
        gdata += ["var"] + ["  " + d for d in h_var]
    gdata += ["implementation", "end."]
    sources["GDATA.PAS"] = "\n".join(gdata) + "\n"

    own, other = [], {}
    for name, hdr in stubs:
        u = unit_of(name)
        if name == tgt:
            continue
        if u == tunit:
            own.append((name, hdr))
        elif u in GAME_UNITS:
            other.setdefault(u, []).append((name, hdr))
        elif u == "p":
            continue                 # program routines are invisible to units (canonical header)
        else:
            raise HarnessError(f"stub {name} is not a game routine id (u1..u9_XXXX)")
    stub_lines = {}                  # module -> {line of the stub's `begin`: name}
    # Where the "keep every global" references go: the harness program body, except in
    # MAIN mode (the body is the candidate), where U1's init block carries them.
    keep_code = "".join(f"  if @{k} = nil then Halt;\n" for k in keep)

    for u in GAME_UNITS:
        if mode == "init" and u == tunit:
            continue
        hdrs = other.get(u, [])
        lines = [f"unit {u.upper()};", "interface",
                 "uses Dos, SAMTYPES;" if u == "u9" else "uses SAMTYPES, GDATA;"]
        if u == "u9" and u9_var:
            lines += ["var"] + ["  " + d for d in u9_var]
        lines += [h for _, h in hdrs]
        lines.append("implementation")
        for name, h in hdrs:
            lines.append(_stub_def(h))
            stub_lines.setdefault(u.upper(), {})[_nlines(lines) + 1] = name
            lines += ["begin", "end;"]
        if mode == "main" and u in inits:
            lines.append("begin")
            if u == "u1" and keep_code:
                lines.append(keep_code.rstrip("\n"))
            lines.append("end.")
        else:
            lines.append("end.")
        sources[f"{u.upper()}.PAS"] = "\n".join(lines) + "\n"

    body_h_line = 0
    body_module = "H"
    if mode == "init":
        lines = [f"unit {tunit.upper()};", "interface",
                 "uses Dos, SAMTYPES, GDATA, " + ", ".join(x.upper() for x in GAME_UNITS if x not in (tunit, "u9")) + ";"
                 if tunit != "u9" else "uses Dos, SAMTYPES;"]
        if tunit == "u9" and u9_var:
            lines += ["var"] + ["  " + d for d in u9_var]
        far_own = [(n, h) for n, h in own if is_far(ep, n)]
        near_own = [(n, h) for n, h in own if not is_far(ep, n)]
        lines += [h for _, h in far_own]
        lines.append("implementation")
        for name, h in near_own:
            lines.append(h)
            stub_lines.setdefault(tunit.upper(), {})[_nlines(lines) + 1] = name
            lines += ["begin", "end;"]
        for name, h in far_own:
            lines.append(_stub_def(h))
            stub_lines.setdefault(tunit.upper(), {})[_nlines(lines) + 1] = name
            lines += ["begin", "end;"]
        body_h_line = _nlines(lines) + 1
        body_module = tunit.upper()
        lines.append(body)
        sources[f"{tunit.upper()}.PAS"] = "\n".join(lines) + "\n"

    stub_units = [u.upper() for u in GAME_UNITS if u != "u9"]
    lines = ["program H;", "uses Dos, U9, Crt, SAMTYPES, GDATA, " + ", ".join(stub_units) + ";"]
    if mode in ("routine", "main"):
        for name, hdr in own:
            lines.append(("{$F+}\n" if is_far(ep, name) else "{$F-}\n") + hdr + "\n  forward;")
    if mode == "routine":
        lines.append("{$F+}" if is_far(ep, tgt) else "{$F-}")
        body_h_line = _nlines(lines) + 1
        lines.append(body)
        lines.append("{$F-}")
    if mode in ("routine", "main"):
        for name, hdr in own:
            lines.append(("{$F+}" if is_far(ep, name) else "{$F-}") + "\n" + _stub_def(hdr))
            stub_lines.setdefault("H", {})[_nlines(lines) + 1] = name
            lines.append("begin\nend;")
        lines.append("{$F-}")
    if mode == "main":
        body_h_line = _nlines(lines) + 1
        lines.append(body)
    else:
        lines.append("begin")
        if mode == "routine":
            lines.append("  if @" + tgt + " = nil then Halt;")
        if keep_code:
            lines.append(keep_code.rstrip("\n"))
        lines.append("end.")
    sources["H.PAS"] = "\n".join(lines) + "\n"
    cl = candidate.splitlines()
    mark = next(i for i, x in enumerate(cl) if re.match(r"^\s*\{@body\}\s*$", x, re.I))
    lead = len(sec["body"]) - len(sec["body"].lstrip("\n"))
    h = Harness(ep, tgt, sources, body_h_line=body_h_line, body_c_line=mark + 2 + lead)
    h.mode, h.unit, h.body_module, h.stub_lines, h.init_names = mode, tunit, body_module, stub_lines, inits
    return h


def build(candidate: str, ep: str, options: list, function: str | None = None,
          fresh: bool = False) -> Harness:
    """Two-pass build; returns the harness with receipt, map and layout errors."""
    defs = [f"/DSAM{ep[-1]}"]
    h = generate(candidate, ep, function)
    r = tpc.compile_program(h.sources, "H.PAS", ["/GD", *defs, *options], fresh=fresh)
    if not r.ok:
        h.receipt = r
        return h
    m = tpmap.parse(r.map("H"))
    d = m.data().para
    pub = {n: o for n, (s, o) in m.publics.items() if s == d}
    typed = set(merge_decls(canonical()["decls"], parse_decls(split_sections(candidate)["decls"]),
                            ep, {}).globals)
    sizes = {}
    order = sorted(pub.items(), key=lambda kv: kv[1])
    for i, (n, o) in enumerate(order):
        if n in typed:
            nxt = next((oo for nn, oo in order[i + 1:] if oo > o), None)
            sizes[n] = (nxt - o) if nxt is not None else 0
    if sizes:
        h = generate(candidate, ep, function, sizes)
        r = tpc.compile_program(h.sources, "H.PAS", ["/GD", *defs, *options], fresh=fresh)
        if not r.ok:
            h.receipt = r
            return h
        m = tpmap.parse(r.map("H"))
        d = m.data().para
        pub = {n: o for n, (s, o) in m.publics.items() if s == d}
    h.receipt, h.map = r, m
    want = {n: o for n, o in episode_globals(ep).items()}
    an = anchors(ep)
    errs = []
    for n, o in sorted(pub.items()):
        if _GLOBAL.match(n) and n in want and want[n] != o:
            errs.append(f"{n} at {o:04X}, original {want[n]:04X}")
    for n in ("PREFIXSEG", "CHECKBREAK", "DOSERROR", "INPUT"):
        if pub.get(n) != an[n] and not (an[n] is None and n not in pub):
            errs.append(f"{n} at {pub.get(n, -1):04X}, original {an[n]:04X}")
    if (m.data().length + 15) // 16 * 16 != an["ds_size"]:
        errs.append(f"DATA length {m.data().length:#x}, original {an['ds_size']:#x}")
    h.layout_errors = errs
    return h
