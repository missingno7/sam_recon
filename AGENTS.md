# Agent rules

The reconstruction phase is closed (tag `matching-archive` holds the per-routine matching machinery
and history). The canonical source is `game/`; its proof is `python tools/verify.py` (build with the
pinned TASM 1.0 / TPC 5.0, compare with the original load images).

## Editing game/

1. Every change must keep `python tools/validate.py` green: SAM1, SAM2 and SAM3 equal in every byte
   outside the documented residue (`config/residue.json`), relocations and header fields equal.
   Bytes inside the residue ranges may move when comments/lines change (they are leftover compiler
   memory); the residue is never filled or patched.
2. Readability edits only where the compiler output stays identical: names, comments, formatting,
   untyped constants, equivalent forms proven by the build. Never `goto`, no `inline` beyond what the
   original needs (documented in the source), no byte emission.
3. Episode differences stay `{$IFDEF SAM1}` / `{$IFDEF SAM2}` / `{$IFDEF SAM3}` blocks.
4. Record renames with their evidence in `docs/names.json`.
5. Original game files and anything derived from them (unpacked images, builds) are never committed.

## Workers

Workers (codex-workers skill) write only inside their own `build/workers/<name>/` directory and
hand back files or patches; the supervisor merges, runs `tools/validate.py` and commits.
