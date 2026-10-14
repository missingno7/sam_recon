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
    pts = sorted((o, n) for o, n in globals_at if start <= o < end)
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


def generate(candidate: str, ep: str, function: str | None = None, sizes: dict | None = None,
             options: list | None = None) -> Harness:
    sec = split_sections(candidate)
    cand = parse_decls(sec["decls"])
    stubs = parse_stubs(sec["stubs"])
    tgt = target_name(sec["body"])
    if function and function.lower() != tgt:
        raise HarnessError(f"body defines {tgt}, expected {function}")
    tunit = unit_of(tgt)
    sizes = sizes or {}
    an = anchors(ep)
    glob = episode_globals(ep)
    missing = [n for n in cand.globals if n not in glob]
    for n in missing:            # a global this episode does not have: drop the view
        del cand.globals[n]
    pts = [(o, n) for n, o in glob.items()]
    h_const = _region(pts, 0, an["game_const_end"], cand, True, sizes)
    h_var = _region(pts, an["game_var_start"], an["crt_var_start"], cand, False, sizes)
    u9_var = _region(pts, an["u9_var_start"], an["u9_var_end"], cand, False, sizes)

    shared = ""
    for kind, st in cand.shared:
        shared += f"{kind}\n  {st};\n"
    sources = {"SAMTYPES.PAS": "unit SAMTYPES;\ninterface\n" + shared + "implementation\nend.\n"}

    own, other = [], {}
    for name, hdr in stubs:
        u = unit_of(name)
        if name == tgt:
            continue
        if u == tunit:
            own.append((name, hdr))
        elif u in GAME_UNITS:
            other.setdefault(u, []).append((name, hdr))
        else:
            raise HarnessError(f"stub {name} is not a game routine id (u1..u9_XXXX)")
    for u in GAME_UNITS:
        hdrs = other.get(u, [])
        body = "".join(f"{h}\n" for _, h in hdrs)
        impl = "".join(f"{h.split('(')[0].split(':')[0].rstrip(';').strip()};\nbegin\nend;\n" for _, h in hdrs)
        data = ""
        if u == "u9" and u9_var:
            data = "var\n" + "\n".join("  " + d for d in u9_var) + "\n"
        uses = "uses Dos, SAMTYPES;\n" if u == "u9" else "uses SAMTYPES;\n"
        sources[f"{u.upper()}.PAS"] = (f"unit {u.upper()};\ninterface\n{uses}{data}{body}"
                                       f"implementation\n{impl}end.\n")
    stub_units = [u.upper() for u in GAME_UNITS if u != "u9"]
    lines = ["program H;", "uses Dos, U9, Crt, SAMTYPES, " + ", ".join(stub_units) + ";"]
    if h_const:
        lines.append("const")
        lines += ["  " + d for d in h_const]
    if h_var:
        lines.append("var")
        lines += ["  " + d for d in h_var]
    for name, hdr in own:
        far = is_far(ep, name)
        lines.append(("{$F+}\n" if far else "{$F-}\n") + hdr + "\n  forward;")
    far = is_far(ep, tgt)
    lines.append("{$F+}" if far else "{$F-}")
    lines.append(sec["body"].strip("\n"))
    lines.append("{$F-}")
    for name, hdr in own:
        far = is_far(ep, name)
        lines.append(("{$F+}" if far else "{$F-}") + f"\n{hdr.split('(')[0].split(':')[0].rstrip(';').strip()};\nbegin\nend;")
    lines.append("{$F-}")
    # The smart linker drops unreferenced data: keep every skeleton global.
    keep = [n for d in h_const + h_var + u9_var for n in re.findall(r"(?m)^\s*(\w+)\s*:", d)]
    lines.append("begin\n  if @" + tgt + " = nil then Halt;")
    lines += [f"  if @{k} = nil then Halt;" for k in keep]
    lines.append("end.")
    sources["H.PAS"] = "\n".join(lines) + "\n"
    return Harness(ep, tgt, sources)


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
    cand = parse_decls(split_sections(candidate)["decls"])
    sizes = {}
    order = sorted(pub.items(), key=lambda kv: kv[1])
    for i, (n, o) in enumerate(order):
        if n in cand.globals:
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
