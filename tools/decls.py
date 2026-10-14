"""Canonical shared declarations (src/decls/canonical.pas).

    python tools/decls.py                 report: canonical views overridden by accepted sources,
                                          conflicting stub headers
    python tools/decls.py --write-routines   regenerate the {@routines} section

{@types} and {@globals} are curated by the supervisor.  {@routines} is
generated: an accepted routine's own header is authoritative; a routine not
yet accepted gets the stub header accepted sources agree on (signature-equal),
and is left out while they disagree.  Every harness includes the canonical
file (tools/harness.py), candidate declarations override it by name.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import SRC  # noqa: E402
import harness  # noqa: E402
from validate import norm, signature  # noqa: E402

HEADER_RX = r"(?is)(?:^|\n)\s*((?:procedure|function)\s+{name}\b\s*(?:\([^)]*\))?\s*(?::\s*[\w\[\]]+)?\s*;)"


def own_header(text: str) -> tuple | None:
    sec = harness.split_sections(text)
    body = harness._strip_comments(sec["body"])
    if re.match(r"(?is)^\s*begin\b", body.strip()):
        return None
    tgt = harness.target_name(sec["body"])
    m = re.search(HEADER_RX.format(name=re.escape(tgt)), body)
    if not m:
        return None
    h = re.sub(r"\s+", " ", m.group(1).strip())
    # drop directives that belong to the definition, not the declaration
    h = re.sub(r"(?i);\s*(interrupt|forward|external)\s*;$", ";", h)
    return tgt, h


def collect() -> tuple:
    own, stub_views = {}, {}
    for p in sorted((SRC / "routines").glob("*.pas")):
        text = p.read_text(encoding="latin-1")
        oh = own_header(text)
        if oh:
            own[oh[0]] = oh[1]
        for n, h in harness.parse_stubs(harness.split_sections(text)["stubs"]):
            stub_views.setdefault(n, {}).setdefault(signature(h), (re.sub(r"\s+", " ", h), []))[1].append(p.stem)
    return own, stub_views


def routines_section() -> tuple:
    own, stubs = collect()
    out, skipped = dict(own), []
    for n, views in stubs.items():
        if n in own:
            continue
        if len(views) == 1:
            out[n] = next(iter(views.values()))[0]
        else:
            skipped.append(n)
    return [out[k] for k in sorted(out)], skipped


def report() -> list:
    canon = harness.canonical()
    problems = []
    for p in sorted((SRC / "routines").glob("*.pas")):
        d = harness.parse_decls(harness.split_sections(p.read_text(encoding="latin-1"))["decls"])
        for n, decl in d.globals.items():
            c = canon["decls"].globals.get(n)
            if c and norm(c.split(":", 1)[1].split("=")[0]) != norm(decl.split(":", 1)[1].split("=")[0]):
                problems.append(f"{p.stem}: {n} declared `{decl.split(':', 1)[1].strip()}`, canonical `{c.split(':', 1)[1].strip()}`")
    own, stubs = collect()
    for n, views in stubs.items():
        sigs = set(views) | ({signature(own[n])} if n in own else set())
        if len(sigs) > 1:
            problems.append(f"header {n}: " + " | ".join(sorted(sigs)))
    return problems


def write_routines() -> None:
    text = harness.CANONICAL.read_text(encoding="latin-1") if harness.CANONICAL.exists() else \
        "{ Canonical shared declarations: every proof harness includes them (tools/decls.py). }\n{@types}\n{@globals}\n{@routines}\n"
    head = text.split("{@routines}")[0]
    lines, skipped = routines_section()
    body = "\n".join(lines) + "\n"
    harness.CANONICAL.parent.mkdir(parents=True, exist_ok=True)
    harness.CANONICAL.write_text(head + "{@routines}\n" + body, encoding="latin-1")
    print(f"{len(lines)} routine headers written; left out (disagreeing stubs): {', '.join(skipped) or 'none'}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--write-routines", action="store_true")
    a = ap.parse_args()
    if a.write_routines:
        write_routines()
    probs = report()
    for p in probs:
        print(p)
    print(f"{len(probs)} declaration differences")
    return 0


if __name__ == "__main__":
    sys.exit(main())
