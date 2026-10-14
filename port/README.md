# sam - the SDL3 port

One executable, `sam`, that runs Secret Agent episodes 1-3 from the canonical Turbo Pascal source
in [../game/](../game/). Design, memory model and contract: [../docs/port.md](../docs/port.md).

```
game/*.PAS --tools/pas2c.py (per episode, at build time; never committed)--> build/.../port-gen/samN/*.c
sam = generated episodes (s1_/s2_/s3_) + tp/ (System, Crt, Dos) + lib/ (the six assembly objects
      in C) + pc/ (emulated PC: memory, interrupts, BIOS, PIT, speaker, keyboard, game port,
      EGA/VGA, text mode; SDL3 front end) + launcher.c
```

| Path | Contents |
|---|---|
| `pc/pc.h` | the binding platform contract |
| `pc/` | real-mode memory and program placement, far-code registry and IVT, safe-point interrupt scheduler, BIOS (INT 8/9/10h/11h/16h/1Ah/1Ch, used INT 21h services), PIT and PC speaker, keyboard controller, game port timing model, EGA/VGA (planes, latches, offset/start/pel panning/line compare), text mode with a CP437 font derived from GNU Unifont (SIL OFL 1.1, `pc/fonts-LICENSE.txt`, source in `pc/font-source/`), SDL3 window/input/audio/scripts |
| `tp/` | Turbo Pascal 5.0 runtime: `system.c` (strings, sets, heap manager, files, Random, Str/Val, Halt/ExitProc), `crt.c`, `dos.c`; `tp.h` is the generated-code ABI |
| `lib/` | ProGraphx, Genus PCX toolkit, TEXTOUT, JOYSTICK, DECODE and CMOSPIT routines in C (`samlib.h`) |
| `tests/` | platform self-tests, scripted determinism test, boot scripts |
| `launcher.c` | `sam --episode 1|2|3` |

## Build and run

MinGW-w64 gcc 12 (`C:/msys64/mingw64`), CMake 3.20+, SDL3 3.4.16 (`SDL3_ROOT` in CMakeLists.txt).

```bash
python -B tools/prepare_reference.py
```

```bash
cmake -S port -B build/port -G "MinGW Makefiles" -DSAM_OPTIMIZATION=2
```

```bash
cmake --build build/port -j4
```

`build/port/sam.exe --episode N --data DIR` runs episode N with its data files in DIR (SDL3.dll
beside the executable or on PATH). Options: `--headless`, `--no-audio`, `--script FILE`
(`<ms> key|keydown|keyup NAME`, `<ms> shot FILE.png`, `<ms> quit`), `--realtime-script`,
`--wav FILE`, `--ega`/`--vga`, `--physical-shots`.

`prepare_reference.py` currently builds the DOS reference program once to read its segment
placement (PSP/DS/SS/heap) from the map; DATA offsets are always computed by the translator.
Replacing that step with committed placement metadata is on the list below.

## Checks

`python tools/validate.py --port` (or `python -B tools/pas2c_check.py --integration`): DS layout
and record sizes against the originals, generated C for all three episodes, the semantic corpus
(`tests/port/semantics/`) against the real TP 5.0, platform CTest, and SAM1-3 booted headless to
their title screens at -O0 and -O2.

## Status

* Milestone 2 reached: all three episodes boot to their title screens.
* Open: gameplay verification, the full differential gate of `lib/` against the assembled
  routines, original-vs-port frame and speaker comparisons, readability of the generated C and of
  the runtime sources, placement metadata instead of the reference build, Android.
