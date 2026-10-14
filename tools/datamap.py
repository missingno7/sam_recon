"""DS data map: which data-segment offsets the code references, how, and from where.

    python tools/datamap.py              write build/datamap/<ep>.json, print a summary
    python tools/datamap.py --show 2a4   list the references to one offset (SAM1)

Every instruction of every census routine is decoded; an operand counts as a
DS reference when it is a memory operand whose segment is DS (no override, or
an explicit `ds:`) with an absolute displacement and no BP base (BP addresses
the stack).  `mov reg,imm` / `push`-style immediates followed by `push ds`
(Turbo Pascal's way of passing a global by reference) are recorded as address
immediates.  Widths come from the operand size.  The map is evidence for the
data layout, not a proof.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, EPISODES, atomic_json, load_json  # noqa: E402
import oracle  # noqa: E402

import capstone  # noqa: E402
from capstone import x86_const as X  # noqa: E402

OUT = BUILD / "datamap"
_MD = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
_MD.detail = True


def refs_for(ep: str) -> dict:
    img, _ = oracle.load_image(ep)
    cen = load_json(BUILD / "census" / f"{ep}.json")
    atlas = load_json(Path(__file__).resolve().parents[1] / "evidence" / "atlas.json")
    names = atlas["units"]
    lid_of = {}
    for lid, r in atlas["routines"].items():
        e = r["episodes"].get(ep)
        if e:
            lid_of[(e["unit"], e["entry"])] = lid
    out = {}
    for k, seg in enumerate(cen["segments"]):
        unit = names[k]
        if unit in ("sys",):
            continue
        for r in seg["routines"]:
            lid = lid_of.get((unit, r["entry"]), f"{unit}_?{r['entry']:04x}")
            base = seg["start"]
            code = img[base + r["entry"]:base + r["code_end"]]
            insns = list(_MD.disasm(code, r["entry"]))
            for i, ins in enumerate(insns):
                for op in ins.operands:
                    if op.type == X.X86_OP_MEM:
                        m = op.mem
                        seg_reg = m.segment
                        if seg_reg not in (0, X.X86_REG_DS):
                            continue
                        if m.base in (X.X86_REG_BP,) or m.index == X.X86_REG_BP:
                            continue
                        if m.base == 0 and m.index == 0:
                            kind = "abs"
                        else:
                            kind = "indexed"
                            if m.base in (X.X86_REG_SI, X.X86_REG_DI, X.X86_REG_BX) and abs(m.disp) < 0x40:
                                continue    # small field offsets from a pointer register
                        off = m.disp & 0xFFFF
                        ent = out.setdefault(off, {"widths": set(), "kinds": set(), "routines": set()})
                        ent["widths"].add(op.size)
                        ent["kinds"].add(kind)
                        ent["routines"].add(lid)
                # address immediates: mov di/ax,imm ; push ds   (VAR parameter of a global)
                if ins.mnemonic == "mov" and len(ins.operands) == 2 and ins.operands[1].type == X.X86_OP_IMM \
                        and i + 1 < len(insns) and insns[i + 1].mnemonic == "push" \
                        and insns[i + 1].op_str == "ds":
                    off = ins.operands[1].imm & 0xFFFF
                    ent = out.setdefault(off, {"widths": set(), "kinds": set(), "routines": set()})
                    ent["kinds"].add("address")
                    ent["routines"].add(lid)
    return {f"{k:04X}": {"widths": sorted(v["widths"]), "kinds": sorted(v["kinds"]),
                         "routines": sorted(v["routines"])} for k, v in sorted(out.items())}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--show")
    a = ap.parse_args()
    if a.show:
        d = load_json(OUT / "sam1.json")
        print(d["refs"].get(a.show.upper().zfill(4)))
        return 0
    for ep in EPISODES:
        refs = refs_for(ep)
        img, _ = oracle.load_image(ep)
        cen = load_json(BUILD / "census" / f"{ep}.json")
        ds = cen["ds_para"] * 16
        lock = load_json(Path(__file__).resolve().parents[1] / "layout" / "oracle.lock.json")["episodes"][ep]["unpacked"]
        init_size = len(img) - ds
        ds_size = lock["ss"] * 16 - ds
        atomic_json(OUT / f"{ep}.json", {"episode": ep, "ds_para": cen["ds_para"],
                                         "initialised_size": init_size, "ds_size": ds_size, "refs": refs})
        offs = [int(k, 16) for k in refs]
        print(f"{ep}: DS {cen['ds_para']:04X}, initialised {init_size:#x}, DS size {ds_size:#x}, "
              f"{len(refs)} referenced offsets, {min(offs):#x}..{max(offs):#x}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
