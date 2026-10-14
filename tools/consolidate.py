"""Declaration consolidation: one declaration per global across the accepted sources.

    python tools/consolidate.py --grow              add agreed built-in-typed globals to the canonical file
    python tools/consolidate.py --apply [--dry-run] drop local views that the canonical declaration
                                                    replaces; a view that differs is dropped only if
                                                    the routine still proves EQUAL without it

Every rewritten source is re-proven in every episode its recipe claims before it
replaces the canonical file (through tools/promote.py, so recipes and the log stay
consistent).  Views that cannot be dropped are listed for manual consolidation.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, RECIPES, ROOT, SRC, load_json  # noqa: E402
import harness  # noqa: E402
import promote  # noqa: E402
import search  # noqa: E402
from validate import norm  # noqa: E402

BUILTIN = re.compile(r"^(byte|word|integer|longint|shortint|boolean|char|pointer|string(\[\d+\])?|"
                     r"array\[\d+\.\.\d+\] of (byte|word|integer|longint|char|boolean|shortint)|"
                     r"array\[\d+\.\.\d+\] of string\[\d+\])$")


def type_of(decl: str) -> str:
    return norm(decl.split(":", 1)[1].split("=")[0])


def views() -> dict:
    out = {}
    for p in sorted((SRC / "routines").glob("*.pas")):
        d = harness.parse_decls(harness.split_sections(p.read_text(encoding="latin-1"))["decls"])
        for n, decl in d.globals.items():
            if n in d.typed_const:
                continue
            out.setdefault(n, {}).setdefault(type_of(decl), []).append(p.stem)
    return out


SIZES = {"byte": 1, "char": 1, "boolean": 1, "shortint": 1, "word": 2, "integer": 2,
         "longint": 4, "pointer": 4, "string": 256}


def type_size(t: str, records: dict) -> int | None:
    t = norm(t)
    if t in SIZES:
        return SIZES[t]
    if t in records:
        return records[t]
    m = re.match(r"^string\[(\d+)\]$", t)
    if m:
        return int(m.group(1)) + 1
    m = re.match(r"^array\[(-?\d+)\.\.(-?\d+)(?:,\s*(-?\d+)\.\.(-?\d+))?\] of (.+)$", t)
    if m:
        el = type_size(m.group(5), records)
        if el is None:
            return None
        n = int(m.group(2)) - int(m.group(1)) + 1
        if m.group(3):
            n *= int(m.group(4)) - int(m.group(3)) + 1
        return n * el
    return None


def record_sizes(shared: list) -> dict:
    out = {}
    for kind, st in shared:
        m = re.match(r"(?is)^(\w+)\s*=\s*(?:packed\s+)?record\s+(.*)\bend$", st.strip())
        if kind != "type" or not m:
            continue
        total = 0
        for field in filter(None, (f.strip() for f in m.group(2).split(";"))):
            names, _, ft = field.partition(":")
            s = type_size(ft, out)
            if s is None:
                total = None
                break
            total += s * len(names.split(","))
        if total is not None:
            out[m.group(1).lower()] = total
    return out


def spans(decls) -> list:
    rec = record_sizes(decls.shared)
    out = []
    for n, d in decls.globals.items():
        m = harness._GLOBAL.match(n)
        if not m or m.group(1):
            continue
        s = type_size(type_of(d), rec)
        out.append((int(m.group(2), 16), int(m.group(2), 16) + (s or 1), n))
    return out


def grow() -> list:
    cdecls = harness.canonical()["decls"]
    canon = cdecls.globals
    taken = spans(cdecls)
    added = []
    for n, vs in sorted(views().items()):
        if n in canon or len(vs) != 1:
            continue
        t = next(iter(vs))
        m = harness._GLOBAL.match(n)
        if not BUILTIN.match(t) or not m or m.group(1):
            continue
        lo = int(m.group(2), 16)
        hi = lo + (type_size(t, {}) or 1)
        if any(a < hi and lo < b for a, b, _ in taken):
            continue                 # inside (or overlapping) a canonical global: a view, not a global
        taken.append((lo, hi, n))
        added.append(f"  {n.lower()}: {t};")
    if added:
        text = harness.CANONICAL.read_text(encoding="latin-1")
        head, rest = text.split("{@routines}", 1)
        head = head.rstrip("\n") + "\n" + "\n".join(added) + "\n"
        harness.CANONICAL.write_text(head + "{@routines}" + rest, encoding="latin-1")
    return added


def drop_global(text: str, name: str) -> str:
    """Remove the declaration of `name` from {@decls} (one declaration per line forms)."""
    sec_start = text.index("{@decls}")
    sec_end = text.index("{@stubs}")
    decls = text[sec_start:sec_end]
    new = re.sub(rf"(?im)^\s*{re.escape(name)}\s*:[^;]*;[ \t]*(\{{[^}}]*\}})?[ \t]*\n", "", decls)
    new = re.sub(rf"(?im)^\s*var\s+{re.escape(name)}\s*:[^;]*;[ \t]*\n", "", new)
    new = re.sub(r"(?im)^\s*var\s*\n(?=\s*(\{@|type\b|const\b|var\b))", "", new)
    return text[:sec_start] + new + text[sec_end:]


def proves(fid: str, text: str, episodes: list) -> bool:
    _, options = search.profile_options(None)
    for ep in episodes:
        r, _ = search.run_episode(text, fid, ep, options, fresh=False)
        if r.status != "EQUAL":
            return False
    return True


def apply(dry: bool) -> tuple:
    canon = harness.canonical()["decls"].globals
    changed, stuck = [], []
    for rp in sorted(RECIPES.glob("*.json")):
        rec = load_json(rp)
        if rec.get("kind") == "asm":
            continue
        path = ROOT / rec["source"]
        text = path.read_text(encoding="latin-1")
        d = harness.parse_decls(harness.split_sections(text)["decls"])
        new = text
        for n, decl in d.globals.items():
            if n not in canon or n in d.typed_const:
                continue
            trial = drop_global(new, n)
            if trial == new:
                stuck.append(f"{rec['function']}: could not remove {n} (multi-name declaration?)")
                continue
            if type_of(decl) == type_of(canon[n]) or proves(rec["function"], trial, rec["equal"]):
                new = trial
            else:
                stuck.append(f"{rec['function']}: {n} `{type_of(decl)}` vs canonical `{type_of(canon[n])}`")
        if new != text:
            changed.append(rec["function"])
            if not dry:
                tmp = BUILD / "consolidate" / f"{rec['function']}.pas"
                tmp.parent.mkdir(parents=True, exist_ok=True)
                tmp.write_text(new, encoding="latin-1")
                promote.acquire()
                try:
                    promote.promote(rec["function"], tmp, "consolidate: canonical declarations")
                finally:
                    promote.release()
    return changed, stuck


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--grow", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    if a.grow:
        added = grow()
        print(f"{len(added)} globals added to the canonical file")
    if a.apply:
        changed, stuck = apply(a.dry_run)
        print(f"{len(changed)} sources rewritten: {', '.join(changed)}")
        for s in stuck:
            print("  " + s)
    return 0


if __name__ == "__main__":
    sys.exit(main())
