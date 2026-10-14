"""Canonical promotion: the only writer of src/routines/, recipes/ and the promotion log.

    python tools/promote.py FUNCTION CANDIDATE.pas [--verify-only] [--note TEXT]
    python tools/promote.py --batch LIST.txt [--note TEXT]      (lines: FUNCTION CANDIDATE)

Rules enforced here:
  * the candidate parses as a harness candidate ({@decls}/{@stubs}/{@body}) whose
    body defines FUNCTION, and passes the lint (no inline machine code, no $L,
    no absolute addressing tricks, no hex literals standing in for DS offsets);
  * verification is fresh (no compile cache) in every episode that has the routine;
    at least one episode must be EQUAL and an existing recipe's EQUAL episodes may
    never shrink;
  * one writer at a time (build/locks/canonical.lock).
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, EPISODES, EVIDENCE, RECIPES, SRC, atomic_bytes, atomic_json, load_json, rel, sha256  # noqa: E402
import harness  # noqa: E402
import search  # noqa: E402

LOCK = BUILD / "locks" / "canonical.lock"
LOGF = EVIDENCE / "promotions.jsonl"


class PromotionError(RuntimeError):
    pass


def lint(text: str) -> list:
    problems = []
    code = harness._strip_comments(text)
    if re.search(r"(?i)\binline\s*\(", code):
        problems.append("inline machine code")
    if re.search(r"(?i)\{\$L\b", text):
        problems.append("{$L} object linking belongs to unit assembly, not a routine candidate")
    if re.search(r"(?i)\babsolute\b", code):
        problems.append("absolute variables (declare the global d_XXXX with its real type)")
    if re.search(r"(?i)\b(Mem|MemW|MemL)\s*\[\s*DSeg\b", code):
        problems.append("DS access through Mem[DSeg:...] (use the global)")
    return problems


def canonical_path(function: str) -> Path:
    return SRC / "routines" / f"{function}.pas"


def verify(function: str, text: str) -> dict:
    sec = harness.split_sections(text)
    if harness.target_name(sec["body"]) != function:
        raise PromotionError(f"the body does not define {function} as its last top-level routine")
    problems = lint(text)
    if problems:
        raise PromotionError("lint: " + "; ".join(problems))
    pname, options = search.profile_options(None)
    results = {}
    for ep in EPISODES:
        res, _ = search.run_episode(text, function, ep, options, fresh=True)
        if res.status == "MISSING":
            continue
        results[ep] = {"status": res.status, "size": res.size, "first_diff": res.first_diff,
                       "bound": res.bound, "note": res.note}
    return {"profile": pname, "options": options, "results": results}


def acquire():
    LOCK.parent.mkdir(parents=True, exist_ok=True)
    for _ in range(600):
        try:
            fd = os.open(LOCK, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            os.write(fd, str(os.getpid()).encode())
            os.close(fd)
            return
        except FileExistsError:
            time.sleep(0.5)
    raise PromotionError(f"canonical lock {LOCK} held too long")


def release():
    try:
        LOCK.unlink()
    except OSError:
        pass


def promote(function: str, cand: Path, note: str = "", verify_only: bool = False) -> dict:
    function = function.lower()
    text = cand.read_text(encoding="latin-1")
    out = verify(function, text)
    equal = sorted(e for e, v in out["results"].items() if v["status"] == "EQUAL")
    for ep, v in out["results"].items():
        print(f"  {function} {ep}: {v['status']}" + (f" (first diff +{v['first_diff']:#x})" if v["first_diff"] is not None else ""))
    if not equal:
        raise PromotionError(f"{function}: no episode EQUAL")
    rp = RECIPES / f"{function}.json"
    if rp.exists():
        old = set(load_json(rp)["equal"])
        if not old <= set(equal):
            raise PromotionError(f"{function}: proven episodes would shrink {sorted(old)} -> {equal}")
    if verify_only:
        return out
    if cand.read_text(encoding="latin-1") != text:
        raise PromotionError("candidate changed during verification")
    path = canonical_path(function)
    atomic_bytes(path, text.encode("latin-1"))
    atlas = load_json(EVIDENCE / "atlas.json")["routines"][function]
    recipe = {"function": function, "unit": atlas["unit"], "source": rel(path), "source_sha256": sha256(text.encode("latin-1")),
              "profile": out["profile"], "options": out["options"], "equal": equal,
              "episodes": {ep: {"status": v["status"], "size": v["size"],
                                "extent": {k: atlas["episodes"][ep][k] for k in ("unit", "start", "entry", "end")},
                                "raw": atlas["episodes"][ep]["raw"]}
                           for ep, v in out["results"].items()}}
    atomic_json(rp, recipe)
    LOGF.parent.mkdir(parents=True, exist_ok=True)
    with LOGF.open("a", encoding="utf-8") as f:
        f.write(json.dumps({"time": time.strftime("%Y-%m-%dT%H:%M:%S"), "function": function,
                            "equal": equal, "source_sha256": recipe["source_sha256"], "note": note},
                           sort_keys=True) + "\n")
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("function", nargs="?")
    ap.add_argument("candidate", nargs="?")
    ap.add_argument("--batch")
    ap.add_argument("--verify-only", action="store_true")
    ap.add_argument("--note", default="")
    a = ap.parse_args()
    items = []
    if a.batch:
        for line in Path(a.batch).read_text(encoding="utf-8").splitlines():
            if line.strip() and not line.startswith("#"):
                f, c = line.split()[:2]
                items.append((f, Path(c)))
    else:
        items.append((a.function, Path(a.candidate)))
    if not a.verify_only:
        acquire()
    failed = 0
    try:
        for f, c in items:
            try:
                promote(f, c, a.note, a.verify_only)
                print(f"{f}: {'verified' if a.verify_only else 'promoted'}")
            except (PromotionError, harness.HarnessError) as exc:
                failed += 1
                print(f"{f}: REFUSED: {exc}")
    finally:
        if not a.verify_only:
            release()
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
