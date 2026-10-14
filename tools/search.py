"""Compile a candidate routine in the proof harness and compare it with the original.

    python tools/search.py CAND.pas --function u6_0000 [--episodes sam1,sam2,sam3] [--asm]
                           [--profile NAME] [--worker NAME] [--fresh]

Every attempt is appended to build/research/experiments.jsonl (candidate hash,
profile, per-episode status, first difference).  Exit code 0 only when every
requested episode is EQUAL.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, EPISODES, EVIDENCE, LAYOUT, load_json, sha256  # noqa: E402
import compare  # noqa: E402
import harness  # noqa: E402

import capstone  # noqa: E402

_MD = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
LOG = BUILD / "research" / "experiments.jsonl"


def profile_options(name: str | None) -> tuple:
    doc = load_json(LAYOUT / "profiles.json")
    name = name or doc["default"]
    return name, list(doc["profiles"][name]["options"])


def original_extent(ep: str, function: str, nested: int) -> dict | None:
    atlas = load_json(EVIDENCE / "atlas.json")
    r = atlas["routines"].get(function)
    if not r or ep not in r["episodes"]:
        return None
    e = r["episodes"][ep]
    cen = load_json(BUILD / "census" / f"{ep}.json")
    seg = cen["segments"][atlas["units"].index(e["unit"])]
    rs = seg["routines"]
    k = next(i for i, x in enumerate(rs) if x["entry"] == e["entry"])
    first = rs[k - nested]
    entries = [seg["start"] + x["entry"] for x in rs[k - nested:k + 1]]
    return {"unit": e["unit"], "start": seg["start"] + first["start"], "end": seg["start"] + e["end"],
            "entry": seg["start"] + e["entry"], "entries": entries}


def nested_count(body: str) -> int:
    heads = re.findall(r"(?im)^\s*(?:procedure|function)\s+\w+", harness._strip_comments(body))
    return len(heads) - 1


def listing(im, start: int, entry: int, end: int, marks: set) -> list:
    out = []
    if entry > start:
        out.append(f"  literals {im.img[start:entry].hex()}")
    a = entry
    for ins in _MD.disasm(im.img[entry:end], entry):
        rel = ins.address - start
        flag = "*" if any(rel + k in marks for k in range(ins.size)) else " "
        out.append(f"{flag} +{rel:04x} {ins.bytes.hex():<16} {ins.mnemonic} {ins.op_str}")
        a = ins.address + ins.size
    return out


def run_episode(text: str, function: str, ep: str, options: list, fresh: bool) -> tuple:
    sec = harness.split_sections(text)
    nested = nested_count(sec["body"])
    ext = original_extent(ep, function, nested)
    if ext is None:
        return compare.Result("MISSING", ep, function, note="routine not in this episode"), None
    try:
        h = harness.build(text, ep, options, function, fresh=fresh)
    except harness.HarnessError as exc:
        return compare.Result("COMPILE", ep, function, note=str(exc)), None
    if not h.receipt.ok:
        tail = " | ".join(l for l in h.receipt.log.splitlines()[-3:] if l.strip())
        return compare.Result("COMPILE", ep, function, note=tail), h
    if h.layout_errors:
        return compare.Result("LAYOUT", ep, function, note="; ".join(h.layout_errors[:4])), h
    orig = compare.original(ep)
    cand = compare.candidate(h.receipt.exe("H"), h.map, ext["unit"])
    hseg = h.map.segment("H")
    para, off = h.map.publics[function.upper()]
    c_entry = para * 16 + off
    c_start = c_entry - (ext["entry"] - ext["start"])
    c_entries = [c_start + (x - ext["start"]) for x in ext["entries"]]
    res = compare.compare(ep, function, orig, ext["start"], ext["entries"], ext["end"], ext["unit"],
                          cand, c_start, c_entries)
    notes = []
    if c_start != hseg.start:
        notes.append(f"candidate extent starts at H+{c_start - hseg.start:#x}, not at the segment start")
    size = ext["end"] - ext["start"]
    later = sorted(p * 16 + o for (p, o) in h.map.publics.values() if p == hseg.para and p * 16 + o > c_entry)
    if later and later[0] != c_start + size:
        notes.append(f"candidate code ends at +{later[0] - c_start:#x}, original at +{size:#x}")
        if res.status == "EQUAL":
            res.status = "DIFF"
            res.diffs.append(f"+{size:#06x} candidate is longer (next routine at +{later[0] - c_start:#x})")
            res.first_diff = size
    res.note = "; ".join(notes)
    res._views = (orig, ext, cand, c_start)
    return res, h


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("candidate")
    ap.add_argument("--function", required=True)
    ap.add_argument("--episodes", default=None)
    ap.add_argument("--profile", default=None)
    ap.add_argument("--asm", action="store_true")
    ap.add_argument("--worker", default="supervisor")
    ap.add_argument("--fresh", action="store_true")
    a = ap.parse_args()
    text = Path(a.candidate).read_text(encoding="latin-1")
    pname, options = profile_options(a.profile)
    eps = a.episodes.split(",") if a.episodes else list(EPISODES)
    results = []
    for ep in eps:
        res, h = run_episode(text, a.function.lower(), ep, options, a.fresh)
        results.append(res)
        print(res.short() + (f"  [{res.note}]" if res.note and res.status in ("EQUAL", "DIFF") else ""))
        if res.status == "DIFF":
            for d in res.diffs[:8]:
                print("    " + d)
        if a.asm and res.status in ("EQUAL", "DIFF"):
            orig, ext, cand, c_start = res._views
            marks = {int(d.split()[0][1:], 16) for d in res.diffs}
            lo = listing(orig, ext["start"], ext["entry"], ext["end"], marks)
            lc = listing(cand, c_start, c_start + (ext["entry"] - ext["start"]),
                         c_start + (ext["end"] - ext["start"]), marks)
            print(f"--- {ep} original | candidate")
            for i in range(max(len(lo), len(lc))):
                l = lo[i] if i < len(lo) else ""
                r = lc[i] if i < len(lc) else ""
                print(f"{l[:62]:<62} | {r[:62]}")
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps({"time": time.time(), "worker": a.worker, "function": a.function.lower(),
                            "candidate": sha256(text.encode("latin-1")), "path": a.candidate,
                            "profile": pname,
                            "results": {r.episode: {"status": r.status, "first_diff": r.first_diff,
                                                    "diffs": len(r.diffs)} for r in results}}) + "\n")
    return 0 if all(r.status == "EQUAL" for r in results) else 1


if __name__ == "__main__":
    sys.exit(main())
