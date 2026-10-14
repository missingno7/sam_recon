# Secret Agent standalone source

This source tree builds all three episodes of Apogee's Secret Agent. Pascal
identifiers describe the observed behavior; `docs/names.json` in the host
repository retains their original logical coordinates and naming evidence.
The program entry file is `SAM.PAS`, with program identifier `SAMMAIN`.

## Build under DOS

Use Turbo Pascal 5.0 with its original `TURBO.TPL`, Turbo Assembler 1.0 and
LZEXE 0.91. Put `TPC`, `TASM` and `LZEXE` on the DOS PATH and make
`TURBO.TPL` available beside TPC or in the source directory. From this
directory, select an episode:

```bat
BUILD 1
BUILD 2
BUILD 3
```

Each command defines exactly one `SAMn` symbol for Pascal and assembly,
assembles the six objects, removes the nine game-unit TPU files and compiles
the program. It leaves `SAM.EXE` and `SAM.MAP` from the unpacked build,
copies the executable to `SAMn.EXE` and packs that copy with LZEXE.

The compiler switches are `/M /GD /DSAMn /$S- /$I- /$R- /$B-`;
the program sets `$M 16384,0,655360`. System, Crt and Dos come from the
original TP 5.0 library. Python and the reconstruction tools are unnecessary
for a DOS build. The original episode assets are needed to run the game;
assets, original executables and historical tool binaries are not included
in this tree.

## Verified reconstruction

From the host repository root, run:

```text
python tools/verify.py
python tools/verify.py game --episodes sam2
```

The verifier stages source-only builds for each episode with the pinned
tools in `config/toolchain.json` and compares against the original unpacked
executables. The current proof is:

| Episode | Equal load-image bytes | Image size | Differences in accepted holes | Differences outside holes |
|---|---:|---:|---:|---:|
| SAM1 | 188644 | 188736 | 92 | 0 |
| SAM2 | 189664 | 189744 | 80 | 0 |
| SAM3 | 189761 | 189792 | 31 | 0 |

Every defined code and DATA byte matches. All checks are equal: relocation
set, DATA length, entry/stack/allocation fields, segment layout, link order,
unit initialization chain, library data anchors, global offsets and routine
entries. LZEXE also preserves each freshly linked load image through its
pack/unpack round trip.

There are 102 bytes of undefined `DB ?`/`DW ?` object storage: seven in
`CMOSPIT.ASM` and 95 in `PROGRAPX.ASM`. These contain compiler-buffer
residue. The verifier checks the accepted object-hole ranges independently
and permits differences only within those ranges; the differing-byte counts
are 92/80/31 above. The source retains the undefined storage without filling
holes or patching linked bytes. Comment or source-line changes can affect
this residue, so each readability batch is checked against the same totals.

Packed executable equality is not claimed: the residue differences also
change the packed files. The original unpacked MZ header's storage size and
ordering were lost during LZEXE packing, so those header details are not
claimed equal. The verifier reports both exceptions separately from the
defined-byte and structural proof.

Unused storage declarations and their original writes remain in place to
preserve DATA and stack layouts. Episode conditionals retain whole
declarations and statements; shared code appears once. The keyboard input
guard uses structured control flow and retains the original emitted bytes.

## Files

| File | Role |
|---|---|
| SAM.PAS | Startup, interrupt handlers, configuration and main game loop |
| SAMPLAY.PAS | Actor/projectile updates, player movement, collisions and pickups |
| SAMLEVEL.PAS | Level loading, symbol decoding, actor placement and tile layers |
| SAMUI.PAS | HUD, popups, menus, saved games, graphics resources and information screens |
| TEXT80.PAS | DOS text drawing and video-adapter queries |
| PCXGENUS.PAS | Pascal interface to Genus PCX Programmer's Toolkit 3.56 |
| GAMEJOY.PAS | Joystick presence, buttons and axis interface |
| SAMSOUND.PAS | PC-speaker effect selection |
| SAMDATA.PAS | Shared declarations, defaults, state resets and asset-decoder interface |
| PROGRPHX.PAS | Pascal interface to ProGraphx 2.0 by Peder Jungck |
| CMOSPIT.ASM | CMOS/DOS clock synchronization and PIT timer programming |
| TEXTOUT.ASM | Text-memory string output and BIOS video queries for TEXT80 |
| GENUS.ASM | Genus PCX Programmer's Toolkit 3.56 implementation |
| JOYSTICK.ASM | Game-port axis-timing routines for GAMEJOY |
| DECODE.ASM | In-place game-asset decoder for SAMDATA |
| PROGRAPX.ASM | ProGraphx 2.0 EGA/VGA drawing, sprites, fonts and buffer copies |
| BUILD.BAT | DOS assembly, Pascal compile and episode packing recipe |

The six object filenames and Pascal link directives are retained. This
directory contains only source and documentation; the host verifier writes
build products and proof receipts outside it.
