"""Instruction-level alignment of a candidate against the original function.

    python tools/asmdiff.py CAND.c FUNCTION [--episode dn1] [--context 6] [--max 3]

Operands that relocation, fixups or code layout change (absolute memory
operands, immediates, branch and call targets) are ignored; every instruction
is keyed by mnemonic, register operands and encoded length.  The first
divergent regions are printed with context ('*' marks the differing
instructions, C = candidate, O = original, offsets relative to the function).
Use it when search.py reports EXTENT_MISMATCH or a long diff: it shows WHERE
the control flow or code shape first differs.  Diagnostic only, not a proof.
"""
from __future__ import annotations

import argparse
import difflib
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import disasm  # noqa: E402
import omf  # noqa: E402
import oracle  # noqa: E402
import symbols  # noqa: E402
import tcc  # noqa: E402


def key(i) -> str:
    txt = f"{i.mnem} {i.ops}"
    if i.mnem.startswith(("j", "call", "lcall", "loop")):
        txt = i.mnem + " N"
    txt = re.sub(r"0x[0-9a-f]+|\b[0-9]+\b", "N", txt)
    if i.size >= 4 and re.search(r"\[(bx|si|di)\]", txt):
        txt = re.sub(r"\[(bx|si|di)\]", r"[\1 + N]", txt)      # disp16 holding a fixup value
    txt = txt.replace(" - N]", " + N]")                            # sign of a 16-bit displacement
    return f"{txt} /{i.size}"


def listing(buf: bytes, a: int, end: int, tables: list | None = None, base: int = 0) -> list:
    """tables: [(start, end)] absolute ranges to emit as one 'table' token; if None,
    tables are found from `jmp word ptr cs:[bx + T]` (T relative to `base`) and
    sized by the queue `table_sizes` attribute."""
    out = []
    pending = list(listing.table_sizes) if tables is None else []
    found = []
    while a < end:
        rng = next((r for r in (tables or found) if r[0] <= a < r[1]), None)
        if rng:
            out.append((a, f"table /{rng[1] - rng[0]}"))
            a = rng[1]
            continue
        i = disasm.decode(buf, a, 0)
        if tables is None and i is not None and i.mnem == "jmp" and "cs:[bx" in i.ops and pending:
            m = re.search(r"cs:\[bx \+ (0x[0-9a-f]+)\]", i.ops)
            if m:
                st = base + int(m.group(1), 16)
                found.append((st, st + pending.pop(0)))
        if i is None:
            out.append((a, "db /1"))
            a += 1
            continue
        out.append((a, key(i)))
        a += i.size
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("candidate")
    ap.add_argument("function")
    ap.add_argument("--episode", default="dn1")
    ap.add_argument("--context", type=int, default=6)
    ap.add_argument("--max", type=int, default=3)
    a = ap.parse_args()
    src = Path(a.candidate).read_text("latin-1")
    flags = tcc.profile_flags("tc20-l-gzo") + ([f"-DEPISODE={a.episode[-1]}"] if "EPISODE" in src else [])
    r = tcc.compile_c(src, flags)
    if not r.ok:
        print(r.log)
        return 1
    m = omf.OmfReader().read(r.obj)
    seg = next(s["name"] for s in m.segment_defs if s["class"] == "CODE")
    t = m.segments[seg]
    pubs = sorted(p["offset"] for p in m.publics if p["segment"] == seg)
    pub = next(p for p in m.publics if symbols.norm(p["name"]) == a.function)["offset"]
    end = min([o for o in pubs if o > pub] + [m.segment_lengths[seg]])
    img, _ = oracle.load_image(a.episode)
    loc = symbols.atlas()[a.function]["locations"][a.episode]
    census = symbols.census(a.episode)
    f = next(x for x in census["functions"] if x["start"] == loc["start"])
    otables = [tuple(r) for r in f.get("tables", [])]
    listing.table_sizes = [e - s for s, e in otables]
    A = listing(t, pub, end, None, 0)
    B = listing(img, loc["start"], loc["start"] + loc["size"], otables)
    sm = difflib.SequenceMatcher(None, [x[1] for x in A], [x[1] for x in B], autojunk=False)
    shown = 0
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            continue
        print(f"--- {tag}: candidate[{i1}:{i2}] original[{j1}:{j2}]")
        for k in range(max(0, i1 - a.context), min(len(A), i2 + a.context)):
            print(f"  C {A[k][0] - pub:04x} {'*' if i1 <= k < i2 else ' '} {A[k][1]}")
        for k in range(max(0, j1 - a.context), min(len(B), j2 + a.context)):
            print(f"  O {B[k][0] - loc['start']:04x} {'*' if j1 <= k < j2 else ' '} {B[k][1]}")
        shown += 1
        if shown >= a.max:
            break
    print(f"sizes: candidate {end - pub}, original {loc['size']}" + ("" if shown else "; instruction shapes identical"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
