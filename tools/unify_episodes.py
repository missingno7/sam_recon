"""Collapse per-episode views of one global into its episode-independent name.

    python tools/unify_episodes.py CAND.pas OUT.pas d_0296 d_sam1_0296 d_sam2_02BC d_sam3_02BC
                                   [--decl "d_0296: array[1..40, 1..25] of TCell;"]

Renames the episode views to the unified name, then merges consecutive
{$IFDEF SAM1} ... {$ENDIF} {$IFDEF SAM2} ... {$ENDIF} {$IFDEF SAM3} ... {$ENDIF}
blocks whose bodies became identical, and replaces the views' declarations by one
declaration (--decl, default: the SAM1 view's declaration renamed).  The result
must be re-proven with tools/search.py; this is an editing aid, not a proof.
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

BLOCK = re.compile(r"\{\$IFDEF SAM1\}\n(?P<a>.*?)\{\$ENDIF\}\n\{\$IFDEF SAM2\}\n(?P<b>.*?)\{\$ENDIF\}\n"
                   r"\{\$IFDEF SAM3\}\n(?P<c>.*?)\{\$ENDIF\}\n", re.S)


def unify(text: str, unified: str, views: list, decl: str | None) -> str:
    lines = text.splitlines(keepends=True)
    decl_lines = [i for i, l in enumerate(lines)
                  if any(re.match(rf"^\s*{re.escape(v)}\s*:", l, re.I) for v in views)]
    if decl_lines:
        first = lines[decl_lines[0]]
        indent = re.match(r"^\s*", first).group(0)
        new = decl or re.sub(rf"^\s*{re.escape(views[0])}", unified, first.strip(), flags=re.I)
        lines[decl_lines[0]] = indent + new + "\n"
        for i in decl_lines[1:]:
            lines[i] = ""
    text = "".join(lines)
    for v in views:
        text = re.sub(rf"\b{re.escape(v)}\b", unified, text, flags=re.I)

    def merge(m):
        return m.group("a") if m.group("a") == m.group("b") == m.group("c") else m.group(0)
    return BLOCK.sub(merge, text)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("candidate")
    ap.add_argument("out")
    ap.add_argument("unified")
    ap.add_argument("views", nargs="+")
    ap.add_argument("--decl")
    a = ap.parse_args()
    t = Path(a.candidate).read_text(encoding="latin-1")
    Path(a.out).write_text(unify(t, a.unified, a.views, a.decl), encoding="latin-1")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
