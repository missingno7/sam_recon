"""Rewrite local views of canonical globals into accesses of the canonical declaration.

    python tools/rewrite_views.py [--dry-run]

Families (each rewrite is re-proven in every recipe episode before promotion):
  * byte views d_67FA .. d_680D  ->  d_67FA[k]  (canonical array[1..20] of Byte)
  * record wrappers of the text-line buffer d_3812 (array[1..299] of string[40]):
    d_3812[i].Field -> d_3812[i];  a two-line record view (.first/.second) -> d_3812[1]/[2]
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, RECIPES, ROOT, load_json  # noqa: E402
import consolidate  # noqa: E402
import harness  # noqa: E402
import promote  # noqa: E402


def split(text: str) -> tuple:
    i, j = text.index("{@decls}"), text.index("{@stubs}")
    return text[:i], text[i:j], text[j:]


def byte_views(text: str) -> str:
    head, decls, rest = split(text)
    names = {f"d_{0x67FA + k:04x}": k + 1 for k in range(20)}
    local = [n for n in names if re.search(rf"(?im)^\s*(var\s+)?{n}\s*:\s*byte\s*;", decls)]
    if not local:
        return text
    for n in local:
        decls = consolidate.drop_global(head + decls + "{@stubs}", n.upper())[len(head):-len("{@stubs}")]
    body = rest
    for n, k in names.items():
        body = re.sub(rf"(?i)\b{n}\b(?!\s*\[)", f"d_67FA[{k}]", body)
    return head + decls + body


def text_views(text: str) -> str:
    head, decls, rest = split(text)
    m = re.search(r"(?im)^\s*(var\s+)?d_3812\s*:\s*([^;]+);", decls)
    if not m or re.match(r"(?i)array\[1\.\.299\] of string\[40\]", m.group(2).strip()):
        return text
    view = m.group(2).strip()
    decls = consolidate.drop_global(head + decls + "{@stubs}", "D_3812")[len(head):-len("{@stubs}")]
    if view.lower().startswith("array"):
        rest = re.sub(r"(?i)(d_3812\s*\[[^\]]*\])\s*\.\s*\w+", r"\1", rest)
    else:                                   # a record of consecutive string[40] fields
        tname = view.lower()
        tm = re.search(rf"(?is)\b{re.escape(tname)}\s*=\s*(?:packed\s+)?record(.*?)\bend\s*;", decls)
        if not tm:
            return text
        fields = [f.split(":")[0].strip() for f in tm.group(1).split(";") if ":" in f]
        flat = []
        for f in fields:
            flat += [x.strip() for x in f.split(",")]
        for k, f in enumerate(flat, 1):
            rest = re.sub(rf"(?i)d_3812\s*\.\s*{re.escape(f)}\b", f"d_3812[{k}]", rest)
    return head + decls + rest


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    done, failed = [], []
    for rp in sorted(RECIPES.glob("*.json")):
        rec = load_json(rp)
        if rec.get("kind") == "asm":
            continue
        path = ROOT / rec["source"]
        text = path.read_text(encoding="latin-1")
        new = text_views(byte_views(text))
        if new == text:
            continue
        if not consolidate.proves(rec["function"], new, rec["equal"]):
            failed.append(rec["function"])
            out = BUILD / "consolidate" / "failed" / f"{rec['function']}.pas"
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(new, encoding="latin-1")
            continue
        done.append(rec["function"])
        if not a.dry_run:
            tmp = BUILD / "consolidate" / f"{rec['function']}.pas"
            tmp.write_text(new, encoding="latin-1")
            promote.acquire()
            try:
                promote.promote(rec["function"], tmp, "rewrite_views: canonical d_67FA/d_3812")
            finally:
                promote.release()
    print(f"rewritten: {', '.join(done)}")
    print(f"not proven (left as is, see build/consolidate/failed/): {', '.join(failed)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
