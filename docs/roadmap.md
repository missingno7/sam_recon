# Roadmap

## Reconstruction phase (closed 2026-10-14)

1. **Oracle** - three LZEXE 0.91 executables locked, decoded, cross-checked by their own
   decompressor stubs, repacked byte for byte ([oracle.md](oracle.md)).
2. **Toolchain** - Turbo Pascal 5.0 proven by reproducing System/Crt/Dos byte for byte; TASM 1.0 as
   the working assembler for the linked objects ([compiler.md](compiler.md), [assembly.md](assembly.md)).
3. **Routines** - all 170 game routines (nested ones, unit init blocks, the 16.6 KB program body) and
   all six linked objects proven individually in SAM1/2/3 (per-routine harness, OMF-level object
   proofs; preserved in the `matching-archive` tag).
4. **Whole program** - one declaration per global, Genus typed constants, external headers; the
   linked program equals the originals in every byte except 92/80/31 bytes of undefined object
   storage ([object-holes.md](object-holes.md); user decision: documented residue, never filled).
5. **Standalone, readable tree** - [game/](../game/) with semantic names ([names.json](names.json)
   records the evidence), named constants, comments, readable assembly; `python tools/verify.py`
   rebuilds and compares all three episodes.
6. **Independent DOS build** - `game/BUILD.BAT`, run unmodified in DOSBox-X with only the pinned
   TPC/TURBO.TPL, TASM and LZEXE on the PATH (`python tools/verify.py --dos`), produces the same
   unpacked programs, and its packed `SAMn.EXE` unpacks to exactly them. Packed files differ from the
   originals only through the residue bytes.
7. **Documentation for what follows** - [formats.md](formats.md), [actors.md](actors.md),
   [runtime.md](runtime.md), `tools/assets.py`.

Every change to `game/` must keep `python tools/validate.py` green.

## Next phase: SDL3 / Android port (planned)

Keep `game/` (Turbo Pascal 5.0) as the single source of truth and generate the port's C from it with
a purpose-built translator, as duke1_recon does with `tools/port_gen.py`:

* the translator encodes TP 5.0 semantics: 16-bit arithmetic with TP's operand typing (Integer op Word
  -> LongInt), short strings and their truncation, sets, nested procedures (explicit parent frame),
  `case` ranges, 1-based arrays, `var` parameters, typed files;
* exact System behaviour where the game depends on it: `Random` (RandSeed LCG), string routines;
* a C platform layer on SDL3 (reusing duke1's EGA/PIT/keyboard/speaker work): ProGraphx and Genus
  rewritten at their API level onto an emulated EGA framebuffer, the 140 Hz timer interrupt,
  keyboard interrupt state, PC speaker, file I/O ([runtime.md](runtime.md) is the checklist);
* one binary for all three episodes; port-only changes in the platform layer, never in `game/`;
* differential testing against the original in DOSBox-X (scripted input, frame/state comparison);
* Android last: SDL3's Android project, assets in the APK, touch input mapped to virtual keys.
