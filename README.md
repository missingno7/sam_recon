# sam_recon

Historical matching reconstruction of Apogee's **Secret Agent** (1992), episodes 1-3
(`SAM1.EXE`, `SAM2.EXE`, `SAM3.EXE`), treated as three historical builds of one logical
program. Same method as `duke1_recon`:

> original binary -> independent evidence -> historically compiled candidate -> exact proof -> canonical source

Original game files and anything derived from them are ignored by git and never redistributed.

## Status

**Phase 1 complete (2026-10-14):** all 170 game routines (including nested routines, unit
initialisation blocks and the 16.6 KB program body) and all six linked assembly objects are proven
byte-identical in SAM1, SAM2 and SAM3: 181.7 KB of the 187.9 KB code image
([docs/progress.md](docs/progress.md); re-proven by `python tools/validate.py`). The remaining
6.2 KB is the Borland runtime, proven by the whole-program build (phase 2,
[docs/roadmap.md](docs/roadmap.md)).

**Phase 2 (whole program, 2026-10-14):** with one declaration per global (`src/decls/canonical.pas`),
`python tools/progbuild.py` generates SAM.PAS + U1..U9 from the accepted sources, assembles the six
objects and links each episode with the pinned TPC 5.0: every code segment (including Crt, Dos and
System), the DATA segment and the relocation set are byte-identical in SAM1/2/3. The only remaining
differences are the uninitialised `DB ?` bytes of two linked objects (102 bytes per episode), which
hold residual compiler-buffer contents of the original build (zeros in SAM3; fragments of the
original source text / symbol table in SAM1/SAM2).

* **Oracles locked:** all three LZEXE 0.91 executables are hashed, unpacked by `tools/lz91.py`,
  cross-checked by executing each file's own LZEXE stub in unicorn at two load segments
  (`tools/oracle.py --crosscheck`), and **repacked byte-identically** by the pinned LZEXE 0.91
  (`tools/repack.py --oracle`).
* **Language:** Turbo Pascal (not C): unit-initialisation far-call chain at the entry point,
  length-prefixed string literals in code segments, separate 16 KB stack segment,
  `maxalloc = minalloc + 0xA000` (TP default `$M` heap maximum 655360). The System unit
  matches Turbo Pascal 5.0 best (provisional; see `evidence/`).

## Requirements

* Python 3.11 with `capstone` 5.0.9 and `unicorn` 2.1.4; `python tools/setup_env.py` vendors them
  into `build/python`.
* Pinned tools outside the repo (hashes in `layout/toolchain.json`).
* The original files in `assets/` (or `$SAM_ASSET_DIR`).

```bash
python tools/setup_env.py
python tools/oracle.py --crosscheck
python tools/repack.py --oracle
```

## Findings (2026-10-14)

* **Compiler: Turbo Pascal 5.0** — a probe reproduces the complete System, Crt and Dos segments
  (padding and relocations included) in all three episodes; TP 5.5 fails specific runtime routines.
  Directives `$B- $I- $R- $S-`, `$M 16384,0,655360` ([docs/compiler.md](docs/compiler.md),
  `evidence/compiler-rules.json`, probes in `probes/compiler/`).
* **Units** (link order): program, u1-u4, u5 (Genus PCX Programmer's Toolkit 3.56: Pascal shell +
  assembly OBJ), u6 (joystick), u7, u8 (game data + asset decoder OBJ), Crt, u9 (ProGraphx 2.0 EGA
  toolbox by Peder Jungck: Pascal shell + 12 KB OBJ), Dos, System ([docs/assembly.md](docs/assembly.md)).
  Only u3 and the program differ in size between episodes.
* **Duke Nukem 1 lineage:** SAM's ProGraphx toolbox shares algorithms with DN1's toolbox
  (planar sprite packets, mode setting, retrace/split helpers) but not byte-identical code.

## Proof route

`tools/search.py` builds a harness program per episode that reproduces the original data segment
exactly (every referenced global, the Crt/u9/Dos/System blocks and the DS length are self-checked),
includes the canonical shared declarations (`src/decls/canonical.pas`), compiles the candidate
routine with the pinned TPC 5.0 and compares the routine's whole extent byte for byte; relocated
segments, far/near calls, procedure pointers and CS literals must bind to the same unit/routine.
Unit init blocks and the program body have their own harness modes. Progress: [docs/progress.md](docs/progress.md).
