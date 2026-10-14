# Roadmap: from proven routines to a standalone source tree

## Target state

A readable source tree that compiles and links **standalone**, with the pinned historical toolchain
and nothing else, into byte-identical SAM1.EXE, SAM2.EXE and SAM3.EXE:

```
sam/                          (final layout, names indicative)
  BUILD.BAT                   tasm the objects, tpc /M /DSAMn SAM.PAS, lzexe, once per episode
  SAM.PAS                     the program (main loop, keyboard/timer interrupt handlers, exit proc)
  U1.PAS .. U8.PAS            game units (semantic names later), u8 = the globals unit
  U5.PAS + GENUS.ASM          Genus PCX Programmer's Toolkit 3.56 shell + object
  U9.PAS + PROGRAPX.ASM       ProGraphx 2.0 EGA toolbox shell + object
  *.ASM                       the game's own small objects (CMOS clock/PIT, text writer, joystick,
                              asset decoder)
  (Crt, Dos, System come from the Turbo Pascal 5.0 TURBO.TPL)
```

## Phases

1. **Routine reconstruction** (done, 2026-10-14): every game routine (170, including nested ones,
   unit init blocks and the 16.6 KB program body) proven EQUAL in SAM1/2/3 in the harness
   (`tools/search.py`, `tools/validate.py`); the six linked objects proven at OMF level
   (`tools/asmproof.py`). Borland runtime reproduced by the compiler research probe.
2. **Whole program** (in progress): one declaration per global and one header per routine
   (`tools/consolidate.py`, `tools/rewrite_views.py`, workers sol-consolidate / sol-externals);
   the Genus typed constants and the asm-only globals declared; `tools/progbuild.py` builds
   SAM.PAS + U1..U9 per episode and compares the load image, MZ header and relocations, then
   LZEXE 0.91 against the original files. Open question: the `DB ?` holes of the linked objects
   (102 bytes per episode) hold residual compiler-buffer bytes in SAM1/2 (docs/assembly.md,
   build/workers/sol-asmproof/REPORT.md); reproducing them may need the original unit compile order.
3. **The build becomes the proof**: validate.py runs progbuild; any change that moves one byte fails.
4. **Readability pass** verified by phase 3: semantic names (routines, globals, types, fields; the
   DS-order constraint is per unit), comments, removal of address comments, structured control flow.
5. **Standalone tree** with BUILD.BAT and a host check script.

Constraints throughout: no original bytes injected as code, no post-link patching, no masking;
original binaries and assets are never committed.
