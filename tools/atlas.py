"""Cross-episode atlas: one logical id per routine, mapped into SAM1/2/3.

    python tools/atlas.py            rebuild evidence/atlas.json from build/census
    python tools/atlas.py --check    rebuild and require equality with the committed atlas

Segments correspond by link order (the census finds the same 13 code segments
in every episode).  Inside a segment the routines are aligned by instruction
*shape* (mnemonics and registers; immediates, displacements and branch targets
abstracted), so routines that only moved or reference relocated data still
align.  Each logical id is `<unit>_<SAM1 entry offset>`; a routine absent
from SAM1 is named after its first episode (`<unit>_<ep>_<offset>`).

Per routine and episode the atlas records the census extent and two hashes:
`raw` (exact bytes) and `shape`; `same_raw` lists episode pairs whose bytes
are identical, which is the strongest cross-episode evidence (a proof in one
episode then needs only the binding check in the others).
"""
from __future__ import annotations

import argparse
import difflib
import hashlib
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, EPISODES, EVIDENCE, LAYOUT, atomic_json, load_json  # noqa: E402
import oracle  # noqa: E402

import capstone  # noqa: E402

_MD = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
ATLAS = EVIDENCE / "atlas.json"
_NUM = re.compile(r"0x[0-9a-f]+|\b\d+\b")


def unit_names() -> list:
    return [u["name"] for u in load_json(LAYOUT / "units.json")["units"]]


def similarity(a: list, b: list) -> float:
    return difflib.SequenceMatcher(None, a, b, autojunk=False).ratio()


def shape(code: bytes, base: int) -> str:
    out = []
    for ins in _MD.disasm(code, base):
        out.append(ins.mnemonic + " " + _NUM.sub("N", ins.op_str))
    return hashlib.sha256("\n".join(out).encode()).hexdigest()[:16]


def build() -> dict:
    names = unit_names()
    cens = {ep: load_json(BUILD / "census" / f"{ep}.json") for ep in EPISODES}
    imgs = {ep: oracle.load_image(ep)[0] for ep in EPISODES}
    nseg = {len(c["segments"]) for c in cens.values()}
    if nseg != {len(names)}:
        raise SystemExit(f"segment counts {nseg} do not match layout/units.json ({len(names)})")
    routines = {}
    all_groups = []
    for k, unit in enumerate(names):
        per = {}
        for ep in EPISODES:
            seg = cens[ep]["segments"][k]
            img = imgs[ep]
            rows = []
            for r in seg["routines"]:
                a = seg["start"] + r["start"]
                b = seg["start"] + r["code_end"]
                e = seg["start"] + r["entry"]
                rows.append({"ep": ep, "entry": r["entry"], "start": r["start"], "end": r["code_end"],
                             "raw": hashlib.sha256(img[a:b]).hexdigest()[:16],
                             "shape": shape(img[e:b], r["entry"]),
                             "mn": [i.mnemonic for i in _MD.disasm(img[e:b], r["entry"])]})
            per[ep] = rows
        # Align every episode onto the groups built so far (SAM1 first).  Equal shapes
        # pair directly; inside a changed block routines pair in order when their
        # mnemonic sequences are similar (edited routines); the rest become new groups
        # at their position.
        groups = [{EPISODES[0]: row} for row in per[EPISODES[0]]]
        for ep in EPISODES[1:]:
            other = per[ep]
            rep = [next(iter(g.values())) for g in groups]
            sm = difflib.SequenceMatcher(None, [x["shape"] for x in rep], [o["shape"] for o in other],
                                         autojunk=False)
            out = []
            for tag, i1, i2, j1, j2 in sm.get_opcodes():
                if tag == "equal":
                    for i, j in zip(range(i1, i2), range(j1, j2)):
                        groups[i][ep] = other[j]
                        out.append(groups[i])
                    continue
                j = j1
                for i in range(i1, i2):
                    k = j
                    while k < j2 and similarity(rep[i]["mn"], other[k]["mn"]) < 0.6:
                        k += 1
                    if k < j2:
                        out += [{ep: other[x]} for x in range(j, k)]
                        groups[i][ep] = other[k]
                        j = k + 1
                    out.append(groups[i])
                out += [{ep: other[x]} for x in range(j, j2)]
            groups = out
        all_groups.extend((unit, g) for g in groups)
    # A routine that moved to another unit between episodes: merge complementary
    # groups (disjoint episodes) of equal shape, or of similar instruction sequences
    # and size (a far routine that became near changes `retf` to `ret`).
    merged = True
    while merged:
        merged = False
        for x in range(len(all_groups)):
            for y in range(len(all_groups)):
                (ua, ga), (ub, gb) = all_groups[x], all_groups[y]
                if x == y or set(ga) & set(gb):
                    continue
                ra, rb = next(iter(ga.values())), next(iter(gb.values()))
                if ra["shape"] == rb["shape"] or (
                        abs((ra["end"] - ra["start"]) - (rb["end"] - rb["start"])) <= 4
                        and similarity(ra["mn"], rb["mn"]) >= 0.9):
                    for ep, r in gb.items():
                        r = dict(r, unit=ub)
                        ga[ep] = r
                    for r in ga.values():
                        r.setdefault("unit", ua)
                    del all_groups[y]
                    merged = True
                    break
            if merged:
                break
    for unit, g in all_groups:
        # A moved routine is named after (and listed under) its SAM1 unit; every
        # episode entry records the unit it is linked into.
        first = next(ep for ep in EPISODES if ep in g)
        unit = g[first].get("unit", unit)
        lid = f"{unit}_{g[first]['entry']:04x}" if first == EPISODES[0] else \
            f"{unit}_{first}_{g[first]['entry']:04x}"
        eps = {ep: {"entry": r["entry"], "start": r["start"], "end": r["end"],
                    "raw": r["raw"], "shape": r["shape"], "unit": r.get("unit", unit)}
               for ep, r in sorted(g.items())}
        raws = {r["raw"] for r in g.values()}
        shapes = {r["shape"] for r in g.values()}
        routines[lid] = {"unit": unit, "episodes": eps,
                         "size": g[first]["end"] - g[first]["start"],
                         "moved": len({r["unit"] for r in eps.values()}) > 1,
                         "identical_bytes": len(raws) == 1 and len(g) == len(EPISODES),
                         "identical_shape": len(shapes) == 1 and len(g) == len(EPISODES)}
    return {"description": "Logical routine atlas across SAM1/2/3 (tools/atlas.py).",
            "units": names, "routines": dict(sorted(routines.items()))}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    doc = build()
    if a.check:
        if load_json(ATLAS) != doc:
            print("atlas differs from evidence/atlas.json")
            return 1
    else:
        atomic_json(ATLAS, doc)
    r = doc["routines"]
    by_unit = {}
    for lid, x in r.items():
        u = by_unit.setdefault(x["unit"], [0, 0, 0, 0, 0])
        u[0] += 1
        u[1] += x["size"]
        u[2] += x["identical_bytes"]
        u[3] += x["identical_shape"] and not x["identical_bytes"]
        u[4] += len(x["episodes"]) < len(EPISODES)
    print(f"{len(r)} logical routines")
    for u, (n, sz, ib, ish, part) in by_unit.items():
        print(f"  {u:5s} {n:3d} routines {sz:6d} B  identical bytes {ib:3d}  same shape {ish:3d}  "
              f"not in all episodes {part}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
