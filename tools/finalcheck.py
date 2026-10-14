"""Phase-3 proof: the whole program, built from the accepted sources, against the original.

    python tools/finalcheck.py [--episodes sam1,sam2,sam3] [--no-build]

For each episode, runs tools/progbuild.py (unless --no-build) and requires:
  * every byte of the linked load image equal to the oracle image, EXCEPT bytes inside the
    undefined (`DB ?`) storage of the linked objects, which hold residual compiler-buffer
    contents of the original build (docs/object-holes.md; user decision: documented
    residue, compared, never patched or filled);
  * the relocation set, DATA length, link order and initialisation chain equal.
The MZ header-size fields are not compared: the original unpacked header does not exist
(LZEXE 0.91 stores no header; tools/lz91.py reconstructs a canonical one), and the packed
files cannot be equal while residue bytes differ.

Writes evidence/final-proof.json (per episode: equal bytes, residue ranges with both sides).
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, EPISODES, EVIDENCE, ROOT, atomic_json, load_json  # noqa: E402
import mz  # noqa: E402
import oracle  # noqa: E402


def check(ep: str) -> dict:
    rep = load_json(BUILD / "progbuild" / ep / "report.json")
    exe = BUILD / "progbuild" / ep / "SAM.EXE"
    out = {"episode": ep, "ok": False}
    if not exe.exists():
        out["error"] = f"no linked EXE ({rep.get('status')})"
        return out
    cand = mz.parse(exe.read_bytes()).image
    orig, _ = oracle.load_image(ep)
    cen = load_json(BUILD / "census" / f"{ep}.json")
    units = load_json(EVIDENCE / "atlas.json")["units"]
    seg_start = {units[k]: s["start"] for k, s in enumerate(cen["segments"])}
    allowed = set()
    residue = []
    for h in rep.get("object_holes", []):
        a, b = h["original_range"]
        base = seg_start[h["unit"]]
        allowed |= set(range(base + a, base + b))
        residue.append({"unit": h["unit"], "range": [f"{a:04X}", f"{b:04X}"],
                        "original": h["original_bytes"], "built": h["candidate_bytes"],
                        "equal": h["equal"]})
    if len(cand) != len(orig):
        out["error"] = f"image size {len(cand)} != {len(orig)}"
        return out
    diffs = [i for i in range(len(orig)) if orig[i] != cand[i]]
    outside = [i for i in diffs if i not in allowed]
    c = rep["comparison"]
    # the original DATA length is only known paragraph-rounded (SS - DS); SS:SP and minalloc
    # in the header comparison pin the rest
    dl = c["data_length"]
    hdr = c["header"]
    data_ok = ((dl["actual"] + 15) // 16 == (dl["expected"] + 15) // 16
               and all(hdr[k]["equal"] for k in ("ss", "sp", "minalloc", "maxalloc", "cs", "ip")))
    checks = {"relocation set": c["relocations"]["equal"], "DATA length / SS:SP / alloc": data_ok,
              "link order": c["link_order"]["equal"], "init chain": c["init_chain"]["equal"]}
    out.update({"image_size": len(orig), "differing_bytes": len(diffs),
                "outside_residue": [f"{i:05X}" for i in outside[:20]],
                "residue_bytes_differing": len(diffs) - len(outside),
                "residue_ranges": residue, "checks": checks,
                "equal_bytes": len(orig) - len(diffs)})
    out["ok"] = not outside and all(checks.values())
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--episodes", default=",".join(EPISODES))
    ap.add_argument("--no-build", action="store_true")
    a = ap.parse_args()
    eps = a.episodes.split(",")
    if not a.no_build:
        subprocess.run([sys.executable, str(ROOT / "tools" / "progbuild.py"), "--episodes", ",".join(eps)],
                       cwd=ROOT)
    results = {ep: check(ep) for ep in eps}
    atomic_json(EVIDENCE / "final-proof.json", results)
    for ep, r in results.items():
        if "error" in r:
            print(f"{ep}: FAIL {r['error']}")
            continue
        print(f"{ep}: {'OK' if r['ok'] else 'FAIL'} {r['equal_bytes']}/{r['image_size']} bytes equal; "
              f"{r['residue_bytes_differing']} residue bytes differ (documented object holes); "
              f"{len(r['outside_residue'])} outside residue; "
              + ", ".join(f"{k} {'equal' if v else 'DIFFERS'}" for k, v in r["checks"].items()))
    return 0 if all(r.get("ok") for r in results.values()) else 1


if __name__ == "__main__":
    sys.exit(main())
