"""Per-episode data correspondence: one name per global, its DS offset in each episode.

    python tools/datalayout.py          write layout/data.json from the atlas and the oracles

For every atlas routine whose instruction shape is identical in two episodes,
the DS operands are paired instruction by instruction: SAM1 offset X in the
same position as SAM2 offset Y means X and Y are the same global (or the
same element of it).  Pairings are collected per SAM1 offset and must be
consistent; a global is then named `d_XXXX` after its SAM1 offset.  Offsets
seen only in one episode get `d_<ep>_XXXX`.

The layout records *referenced* offsets; extents and types of globals come
from the reconstruction (src/ declarations), never from here.
"""
from __future__ import annotations

import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, EPISODES, EVIDENCE, LAYOUT, atomic_json, load_json  # noqa: E402
import oracle  # noqa: E402

import capstone  # noqa: E402
from capstone import x86_const as X  # noqa: E402

_MD = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
_MD.detail = True


def ds_operands(code: bytes, base: int) -> list:
    """[(instruction index, operand index, offset, kind)] for DS-relative absolute
    displacements and `mov reg,imm ; push ds` address immediates."""
    out = []
    insns = list(_MD.disasm(code, base))
    for i, ins in enumerate(insns):
        for k, op in enumerate(ins.operands):
            if op.type == X.X86_OP_MEM:
                m = op.mem
                if m.segment not in (0, X.X86_REG_DS) or X.X86_REG_BP in (m.base, m.index):
                    continue
                if m.base == 0 and m.index == 0:
                    out.append((i, k, m.disp & 0xFFFF, "abs"))
                elif abs(m.disp) >= 0x40:
                    out.append((i, k, m.disp & 0xFFFF, "indexed"))
        if ins.mnemonic == "mov" and len(ins.operands) == 2 and ins.operands[1].type == X.X86_OP_IMM \
                and i + 1 < len(insns) and insns[i + 1].mnemonic == "push" and insns[i + 1].op_str == "ds":
            out.append((i, 1, ins.operands[1].imm & 0xFFFF, "address"))
    return out


def main() -> int:
    atlas = load_json(EVIDENCE / "atlas.json")
    cens = {ep: load_json(BUILD / "census" / f"{ep}.json") for ep in EPISODES}
    imgs = {ep: oracle.load_image(ep)[0] for ep in EPISODES}
    seg_start = {ep: {atlas["units"][k]: s["start"] for k, s in enumerate(cens[ep]["segments"])}
                 for ep in EPISODES}
    ref = EPISODES[0]
    pairs = {ep: defaultdict(set) for ep in EPISODES[1:]}
    seen = {ep: set() for ep in EPISODES}
    pairs23 = defaultdict(set)      # SAM2 -> SAM3, for globals SAM1 does not reference
    for lid, r in atlas["routines"].items():
        if r["unit"] == "sys":
            continue
        ops = {}
        for ep, e in r["episodes"].items():
            b = seg_start[ep][e["unit"]]
            ops[ep] = ds_operands(imgs[ep][b + e["entry"]:b + e["end"]], e["entry"])
            seen[ep] |= {o[2] for o in ops[ep]}
        if "sam2" in ops and "sam3" in ops and ops["sam2"] and                 len(ops["sam2"]) == len(ops["sam3"]) and r["episodes"]["sam2"]["shape"] == r["episodes"]["sam3"]["shape"]:
            for a, b in zip(ops["sam2"], ops["sam3"]):
                if a[:2] == b[:2]:
                    pairs23[a[2]].add(b[2])
        if ref not in ops or not r["identical_shape"]:
            continue
        for ep in EPISODES[1:]:
            if ep in ops and len(ops[ep]) == len(ops[ref]):
                for a, b in zip(ops[ref], ops[ep]):
                    if a[:2] == b[:2]:
                        pairs[ep][a[2]].add(b[2])
    globals_ = {}
    conflicts = []
    for off in sorted(seen[ref]):
        g = {ref: off}
        for ep in EPISODES[1:]:
            c = pairs[ep].get(off)
            if c and len(c) == 1:
                g[ep] = next(iter(c))
            elif c:
                conflicts.append((f"{off:04X}", ep, sorted(f"{x:04X}" for x in c)))
        globals_[f"d_{off:04X}"] = g
    mapped = {ep: {g[ep] for g in globals_.values() if ep in g} for ep in EPISODES[1:]}
    for off in sorted(seen["sam2"] - mapped["sam2"]):
        g = {"sam2": off}
        c = pairs23.get(off)
        if c and len(c) == 1 and next(iter(c)) not in mapped["sam3"]:
            g["sam3"] = next(iter(c))
            mapped["sam3"].add(g["sam3"])
        globals_[f"d_sam2_{off:04X}"] = g
    for off in sorted(seen["sam3"] - mapped["sam3"]):
        globals_[f"d_sam3_{off:04X}"] = {"sam3": off}
    # Offsets of a global in episodes where only the shape-changed routines use it are
    # inferred from the nearest mapped neighbours with the same delta (recorded as such).
    for name, g in globals_.items():
        if ref not in g:
            continue
        for ep in EPISODES[1:]:
            if ep in g:
                continue
            below = [(o, x[ep]) for o, x in ((v[ref], v) for v in globals_.values() if ref in v and ep in v)
                     if o < g[ref]]
            above = [(o, x[ep]) for o, x in ((v[ref], v) for v in globals_.values() if ref in v and ep in v)
                     if o > g[ref]]
            if below and above:
                lo, hi = max(below), min(above)
                if lo[1] - lo[0] == hi[1] - hi[0]:
                    g[ep] = g[ref] + lo[1] - lo[0]
                    g.setdefault("inferred", []).append(ep)
    doc = {"description": "Referenced DS offsets per episode, named after SAM1 (tools/datalayout.py).",
           "conflicts": conflicts,
           "globals": {k: {ep: (f"{v[ep]:04X}" if ep in v else None) for ep in EPISODES}
                       | ({"inferred": v["inferred"]} if "inferred" in v else {})
                       for k, v in sorted(globals_.items(), key=lambda kv: (min(
                           x for e, x in kv[1].items() if e in EPISODES), kv[0]))}}
    atomic_json(LAYOUT / "data.json", doc)
    full = sum(1 for v in globals_.values() if all(ep in v for ep in EPISODES))
    print(f"{len(globals_)} globals: {full} located in all episodes, "
          f"{sum(1 for v in globals_.values() if 'inferred' in v)} by neighbour delta, "
          f"{len(conflicts)} conflicting pairings")
    for c in conflicts[:20]:
        print("  conflict", c)
    for name, v in globals_.items():
        if not all(ep in v for ep in EPISODES):
            print("  partial", name, {e: f"{x:04X}" for e, x in v.items() if e in EPISODES})
    return 0


if __name__ == "__main__":
    sys.exit(main())
