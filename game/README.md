# Secret Agent - standalone game source

One source tree builds all three episodes with Turbo Pascal 5.0 (including
its original TURBO.TPL), Turbo Assembler 1.0 and LZEXE 0.91. Put TPC, TASM
and LZEXE on the DOS PATH, and make TURBO.TPL available beside TPC or in
this directory. Run BUILD 1, BUILD 2 or BUILD 3. Define exactly one SAMn
symbol; BUILD selects it for both Pascal and assembly. The batch assembles
all six objects, makes SAM.PAS and its units, copies SAM.EXE to SAMn.EXE,
then packs that copy. SAM.EXE and SAM.MAP retain the unpacked build.
BUILD removes the nine generated game-unit TPU files before compiling, so changing
episodes rebuilds every game unit. The host verifier always stages fresh,
isolated copies for each episode.

| File | Contents |
|---|---|
| SAM.PAS | Program, interrupt handlers and main loop |
| SAMPLAY.PAS | Actor updates, movement, collision and pickups (U1) |
| SAMLEVEL.PAS | Level loading and layer drawing (U2) |
| SAMUI.PAS | Menus, HUD, saved games and resource loading (U3) |
| TEXT80.PAS | Text-mode drawing and adapter detection (U4) |
| PCXGENUS.PAS | Genus PCX toolkit interface (U5) |
| GAMEJOY.PAS | Joystick interface (U6) |
| SAMSOUND.PAS | PC-speaker effect selection (U7) |
| SAMDATA.PAS | Shared declarations, defaults and asset decoder (U8) |
| PROGRPHX.PAS | ProGraphx EGA/VGA toolbox interface (U9) |
| CMOSPIT.ASM | Program CMOS/date/PIT routines |
| TEXTOUT.ASM | U4 text writer |
| GENUS.ASM | U5 Genus PCX Programmer's Toolkit 3.56 |
| JOYSTICK.ASM | U6 joystick routines |
| DECODE.ASM | U8 asset decoder |
| PROGRAPX.ASM | U9 ProGraphx 2.0 EGA toolbox |

Compiler options: /M /GD /DSAMn /$S- /$I- /$R- /$B-; the program sets
$M 16384,0,655360. Crt, Dos and System come from the pinned TP 5.0 library.
No Python, reconstruction recipe, harness or oracle is needed to build
the game under DOS. The host comparison needs this reconstruction repo,
the pinned tools in layout/toolchain.json and the original game files.
From the repo run:

    python tools/standalone.py game
    python tools/standalone.py game --episodes sam2

The accepted whole-program reconstruction proves every defined code byte,
the DATA image, relocation set, entry/stack/allocation fields, link order
and unit initialization chain for SAM1, SAM2 and SAM3. The original
unpacked MZ header's storage size/order was lost when LZEXE packed it and
cannot be claimed equal. See the host report for this standalone build's
fresh measurements and the LZEXE round-trip check.

Exception: 102 bytes of undefined DB ? object storage (7 in CMOSPIT,
95 in PROGRAPX) contain compiler-buffer residue. The earlier generated
builds differed at 89/80/31 of these bytes for SAM1/SAM2/SAM3. Source
merging and line-number changes can change that residue; the verifier
lists both sides and permits differences only in the accepted holes.
No hole is filled and no linked byte is patched. Packed executables
therefore also differ from the originals; packed byte equality is not
claimed. LZEXE must preserve the freshly linked load image exactly.

Episode conditionals preserve whole declarations/statements and shared
source appears once. Semantic identifiers come from layout/names.json, which
keeps their logical coordinates, confidence and behavioral evidence. Routine
comments describe the existing code; main/unit initialization blocks retain
their original structure. SAM.PAS stays the build entry file and its program
identifier is SAMMAIN. The six object filenames and link directives remain
unchanged. Original binaries/assets and historical tool binaries are not
included in this tree.
