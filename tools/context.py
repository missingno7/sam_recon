"""What is this routine?  Annotated original, bindings, callers/callees, skeleton.

    python tools/context.py u3_6ea9                 annotated SAM1 listing + facts
    python tools/context.py u3_6ea9 --episode sam2
    python tools/context.py u3_6ea9 --skeleton      candidate template for tools/search.py
    python tools/context.py --list [--unit u3] [--max-size 200] [--open]

Names: game routines by logical id (evidence/atlas.json), globals by
d_<SAM1 offset> (layout/data.json), Borland runtime routines by
layout/library-names.json when known (else by unit:offset).
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, EPISODES, EVIDENCE, LAYOUT, SRC, load_json  # noqa: E402
import compare  # noqa: E402
import oracle  # noqa: E402

import capstone  # noqa: E402
from capstone import x86_const as X  # noqa: E402

_MD = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
_MD.detail = True


def load():
    atlas = load_json(EVIDENCE / "atlas.json")
    data = load_json(LAYOUT / "data.json")["globals"]
    libnames = {}
    p = LAYOUT / "library-names.json"
    if p.exists():
        libnames = load_json(p)["names"]
    return atlas, data, libnames


def global_names(data: dict, ep: str) -> dict:
    return {int(v[ep], 16): n for n, v in data.items() if v.get(ep)}


def extent(atlas: dict, lid: str, ep: str) -> dict:
    r = atlas["routines"][lid]
    e = r["episodes"][ep]
    cen = load_json(BUILD / "census" / f"{ep}.json")
    seg = cen["segments"][atlas["units"].index(e["unit"])]
    return {"unit": e["unit"], "base": seg["start"], "start": e["start"], "entry": e["entry"], "end": e["end"],
            "seg": seg}


def call_graph(atlas: dict, ep: str) -> tuple:
    """(callees, callers): lid -> set of lids (game) / library identities."""
    cen = load_json(BUILD / "census" / f"{ep}.json")
    para_unit = {s["para"]: atlas["units"][k] for k, s in enumerate(cen["segments"])}
    lid_at = {}
    for lid, r in atlas["routines"].items():
        e = r["episodes"].get(ep)
        if e:
            lid_at[(e["unit"], e["entry"])] = lid
    callees, callers = {}, {}
    for k, seg in enumerate(cen["segments"]):
        unit = atlas["units"][k]
        for r in seg["routines"]:
            me = lid_at.get((unit, r["entry"]))
            if not me:
                continue
            out = set()
            for t in r["near_calls"]:
                out.add(lid_at.get((unit, t), f"{unit}:{t:04X}"))
            for t in r["far_calls"]:
                s, o = (int(x, 16) for x in t.split(":"))
                u = para_unit.get(s, f"seg{s:04X}")
                out.add(lid_at.get((u, o), f"{u}:{o:04X}"))
            callees[me] = out
            for c in out:
                callers.setdefault(c, set()).add(me)
    return callees, callers


def pascal_strings(b: bytes) -> list:
    out, i = [], 0
    while i < len(b):
        n = b[i]
        s = b[i + 1:i + 1 + n]
        if n and len(s) == n and all(32 <= c < 127 or c in (10, 13) for c in s):
            out.append((i, s.decode("latin-1")))
            i += 1 + n
        else:
            i += 1
    return out


def annotate(lid: str, ep: str) -> list:
    atlas, data, libnames = load()
    ext = extent(atlas, lid, ep)
    img, relocs = oracle.load_image(ep)
    im = compare.original(ep)
    gnames = global_names(data, ep)
    bases = {u: p * 16 for p, u in im.seg_unit.items()}
    base = ext["base"]
    lines = []
    pre = img[base + ext["start"]:base + ext["entry"]]
    if pre:
        lines.append(f"; literal pool / nested routines before the entry: {len(pre)} bytes")
        for off, s in pascal_strings(pre):
            lines.append(f";   +{off:04x} string[{len(s)}] {s!r}")
    seg_routines = {r["entry"] for r in ext["seg"]["routines"]}
    for ins in _MD.disasm(img[base + ext["start"]:base + ext["end"]], ext["start"]):
        if ins.address < ext["entry"] and ins.address not in seg_routines:
            continue        # literal bytes, already shown
        note = []
        b = ins.bytes
        lin = base + ins.address
        if b[0] == 0xE8:
            t = (ins.address + ins.size + struct.unpack_from("<h", b, 1)[0]) & 0xFFFF
            if not (ext["start"] <= t < ext["end"]):
                note.append(compare.identity(im, bases, ext["unit"], t))
        elif b[0] in (0x9A, 0xEA):
            o, s = struct.unpack_from("<HH", b, 1)
            u = im.seg_unit.get(s, f"seg{s:04X}")
            ident = compare.identity(im, bases, u, o)
            note.append(libnames.get(ident, ident))
        for op in ins.operands:
            if op.type == X.X86_OP_MEM and op.mem.segment in (0, X.X86_REG_DS) \
                    and X.X86_REG_BP not in (op.mem.base, op.mem.index):
                d = op.mem.disp & 0xFFFF
                if d in gnames:
                    note.append(gnames[d])
                elif op.mem.base == 0 and op.mem.index == 0:
                    below = max((o for o in gnames if o <= d), default=None)
                    if below is not None and d - below < 0x400:
                        note.append(f"{gnames[below]}+{d - below:#x}")
            if op.type == X.X86_OP_IMM and (op.imm & 0xFFFF) in gnames and ins.mnemonic == "mov":
                note.append(f"@{gnames[op.imm & 0xFFFF]}?")
        if any(lin + k in im.relocs for k in range(ins.size)):
            note.append("reloc")
        mark = ">" if ins.address in seg_routines else " "
        lines.append(f"{mark}{ins.address:04x}  {b.hex():<16} {ins.mnemonic:<6} {ins.op_str:<28}"
                     + ("; " + ", ".join(note) if note else ""))
    return lines


def facts(lid: str, ep: str) -> dict:
    atlas, data, _ = load()
    r = atlas["routines"][lid]
    ext = extent(atlas, lid, ep)
    img, _ = oracle.load_image(ep)
    code = img[ext["base"] + ext["entry"]:ext["base"] + ext["end"]]
    insns = list(_MD.disasm(code, ext["entry"]))
    rets = {(i.mnemonic, i.op_str) for i in insns if i.mnemonic in ("ret", "retf", "iret")}
    frame = next((i.operands[1].imm for i in insns[:4] if i.mnemonic == "sub" and i.op_str.startswith("sp")), 0)
    kind = "interrupt" if any(m == "iret" for m, _ in rets) else \
        "far" if any(m == "retf" for m, _ in rets) else "near" if rets else "?"
    params = sorted({int(o, 16) if o else 0 for m, o in rets if m != "iret"})
    callees, callers = call_graph(atlas, ep)
    return {"unit": r["unit"], "kind": kind, "frame_bytes": frame, "param_bytes": params,
            "size": ext["end"] - ext["start"], "literal_prefix": ext["entry"] - ext["start"],
            "episodes": {e: f"{v['unit']} {v['entry']:04x} size {v['end'] - v['start']}"
                         for e, v in r["episodes"].items()},
            "identical_bytes": r["identical_bytes"], "identical_shape": r["identical_shape"],
            "callees": sorted(callees.get(lid, ())), "callers": sorted(callers.get(lid, ()))}


def skeleton(lid: str, ep: str) -> str:
    atlas, data, _ = load()
    f = facts(lid, ep)
    gn = global_names(data, ep)
    used = set()
    for line in annotate(lid, ep):
        for tok in line.replace(",", " ").split():
            if tok.startswith("d_") and tok.split("+")[0] in data:
                used.add(tok.split("+")[0])
    decls = "\n".join(f"{{ var {n}: ?; }}" for n in sorted(used))
    stubs = []
    for c in f["callees"]:
        if c in atlas["routines"] and c != lid:
            cf = facts(c, ep) if ep in atlas["routines"][c]["episodes"] else None
            pb = cf["param_bytes"] if cf else "?"
            stubs.append(f"procedure {c};  {{ {cf['kind'] if cf else '?'}, ret {pb}: fix the header }}")
    kw = "procedure"
    return (f"{{ {lid}: {f['kind']}, frame {f['frame_bytes']} bytes, parameters {f['param_bytes']} bytes }}\n"
            "{@decls}\n" + (decls + "\n" if decls else "") +
            "{@stubs}\n" + "\n".join(stubs) + ("\n" if stubs else "") +
            "{@body}\n" + f"{kw} {lid};\nbegin\nend;\n")


def accepted() -> set:
    p = SRC / "routines"
    return {x.stem.lower() for x in p.glob("*.pas")} if p.is_dir() else set()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("function", nargs="?")
    ap.add_argument("--episode", default=EPISODES[0])
    ap.add_argument("--skeleton", action="store_true")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--unit")
    ap.add_argument("--max-size", type=int)
    ap.add_argument("--open", action="store_true")
    a = ap.parse_args()
    atlas, _, _ = load()
    if a.list:
        acc = accepted()
        for lid, r in atlas["routines"].items():
            if a.unit and r["unit"] != a.unit:
                continue
            if a.max_size and r["size"] > a.max_size:
                continue
            if a.open and lid in acc:
                continue
            flag = "accepted" if lid in acc else ""
            print(f"{lid:16s} {r['size']:6d} B  eps {','.join(sorted(r['episodes'])):15s} "
                  f"{'same-bytes' if r['identical_bytes'] else 'same-shape' if r['identical_shape'] else 'differs':10s} {flag}")
        return 0
    lid = a.function.lower()
    if a.skeleton:
        print(skeleton(lid, a.episode), end="")
        return 0
    f = facts(lid, a.episode)
    for k, v in f.items():
        print(f"{k:16s} {v}")
    print()
    print("\n".join(annotate(lid, a.episode)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
