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
| `launcher.c` | automatic episode discovery, emulated text-mode chooser and direct `--episode 1|2|3` starts |
| `release/` | player README and release notices; `tools/package_port.py` packages an explicit data-free allowlist |

## Build and run

MinGW-w64 gcc 12 (`C:/msys64/mingw64`), CMake 3.20+, SDL3 3.4.16 (`SDL3_ROOT` in CMakeLists.txt).

```bash
cmake -S port -B build/port -G "MinGW Makefiles" -DSAM_OPTIMIZATION=2
```

```bash
cmake --build build/port -j4
```

`sam` finds complete episodes in the executable's directory, independently of the current
working directory. A single installed episode starts immediately; multiple episodes open the
mission chooser. Use arrows and Enter or 1/2/3; S opens port settings and Esc exits. Quitting an
episode to DOS returns to the chooser. Each start reloads emulated memory, DS, devices, handles,
vectors and native assembly-library private state in place, keeping the SDL window. The chooser
uses BIOS text mode and the port's licensed CP437 font, without initializing a game for its UI.

`build/port/sam.exe --episode N --data DIR` runs episode N directly with its data files in DIR,
then exits when the episode ends (SDL3.dll beside the executable or on PATH). A complete episode
requires APO/TTL/CRD, three GFX files, three E.SND files and its END file(s); CFG and the DOS EXE
are not required. See [release/README.txt](release/README.txt) for exact names and controller use.
Options: `--headless`, `--no-audio`, `--script FILE`
(`<ms> key|keydown|keyup NAME`, `<ms> shot FILE.png`, `<ms> quit`), `--realtime-script`,
`--wav FILE`, `--ega`/`--vga`, `--physical-shots`.
Script times span the launcher session; future events are rebased when a DOS load resets the
device clock. Direct-start scripts keep their existing timing and captures.

Alt+Enter and F11 toggle fullscreen. Keyboard repeat remains the
PC's 500 ms delay / 30 Hz repeat. Controller left stick/D-pad and South/West buttons use the
emulated game port's X/Y and buttons 0/1 (jump/fire); enable/calibrate Joystick in the game's
options. No controller event edits game state or generates keyboard input.

Presentation settings are `sam.json` **beside the executable**, separate from the game's
`SAMn.CFG`. The chooser offers fullscreen, integer scaling versus aspect-correct fit, optional
smooth filtering and window sizes; resizing also saves the windowed size. Defaults retain the
existing integer/aspect presentation and nearest filtering. CLI overrides:
`--fullscreen` / `--windowed`, `--scaling integer|fit`, `--smooth` / `--no-smooth`,
`--window-size WIDTHxHEIGHT`, `--settings FILE`. The latter changes only the host settings path.
Use a writable directory for persistence; read-only locations report a save error and keep
playing. Malformed settings fall back to defaults. These options never change DOS scanout or
the source-frame screenshots, so the existing boot hashes remain unchanged.

Build a Windows release with `python tools/package_port.py`. It produces
`build/releases/sam-windows-x64.zip` containing only sam.exe, SDL3.dll and the player README and
SDL/font notices. No original data, CFG, saves, scripts or test outputs enter the archive.
`python -B tools/check_package.py --window` unpacks into fresh test folders, copies original data
there, and checks discovery, all three titles, auto-starts, settings persistence and four normal
episode quits/restarts, plus a visible window. Captures are disposable test outputs.

Linux source builds use the same CMake command with the system compiler, make/Ninja and an
SDL3 CMake package, without MinGW arguments. Linux execution was not tested here: WSL refuses
distribution enumeration with E_ACCESSDENIED. Windows-specific source calls are guarded by
`_WIN32`; packaging the Windows zip requires a Windows build.

Windows real-time play uses a D3D11 flip presenter on a separate thread, with vsync and one
pending frame. It displays the latest completed emulated scanout and replaces intermediate
frames when the monitor is slower than the emulated 70.0863 Hz display. A static frame remains in
the compositor without repeated rendering. Vsync, GPU work and resizing never hold the PC
thread or its timer interrupts; SDL window events and input stay on the main thread. This
backend requires Windows 10 version 1803 or later and a D3D11-capable graphics driver. Other
platforms retain the SDL renderer. Scaling, borders, fullscreen and filtering use the same
presentation settings. Manual-clock scripts retain their existing rendering and timing.

Host input pumping runs at most once per millisecond during productive work, and before every
blocking wait. Windows keyboard/window messages wake those waits immediately; an attached
controller bounds them to one millisecond. Hardware retrace loops can identify their requested
status-bit edge through `pc_wait_video_status`, without changing any returned port value. The
Windows wait uses a high-resolution waitable timer. Emulated time stops exactly at the next
device edge, so an oversleep cannot hide the retrace pulse; no precision busy spin is needed.
Later waits catch up against wall time, with lag beyond 100 ms rebasing wall pacing without
skipping PC history. Productive work samples elapsed wall time at safe points while preserving
pending device edges. The PIT and virtual display remain independent of host presentation.

Speaker playback uses the audio device's native rate to avoid resampling and a 10 ms replay
margin (previously 40 ms). Playback follows the emulated clock and holds the current PIT tone
during a host stall. The requested device period is 256 frames; the actual period is
device-dependent. WAV capture remains deterministic at 44.1 kHz. Opt-in `SAM_HOST_METRICS=FILE`
writes cumulative wall-time diagnostics once per second: safe points, event pumps, sleeps,
scanouts, presentations, audio work and late audible speaker changes. `tools/measure_host.py`
measures total process CPU as a percentage of one core in real-time title/menu/gameplay/fade
scripts; `tools/check_host.py` checks visible presentation and an intentionally stalled
presenter against the unchanged boot images and IRQ counts. `host_latency` measures an SDL
event reaching the BIOS keyboard ring while the PC is blocked.
`SAM_DIAG_FLIPS=FILE` logs each CRTC start-address high-byte write with emulated and host time;
`tools/check_timing.py FILE --start 10 --end 22` summarizes its cadence, including loading gaps.
The raw-port `clock_edges` regression inserts host stalls longer than the retrace pulse and
checks that every pulse and the PIT remain observable without a library wait hint.

No DOS tools are needed: each episode's memory placement (PSP, DS, SS, heap) comes from
[../config/port.json](../config/port.json); DATA offsets are computed by the translator. With the DOS
toolchain present, `tools/pas2c_placement_check.py` recomputes the placement from the reference
build and requires equality.

## Checks

`python tools/validate.py --port` (or `python -B tools/pas2c_check.py --integration`): DS layout
and record sizes against the originals, generated C for all three episodes, the semantic corpus
(`tests/port/semantics/`) against the real TP 5.0, platform CTest, and SAM1-3 booted headless to
their title screens at -O0 and -O2.

`lib/` against the assembled originals (needs the DOS reference builds,
`python tools/verify.py --episodes sam1,sam2,sam3 --keep`): `python -B tools/libdiff.py --matrix`
runs every routine the game calls (200 random + 16 realistic cases each; memory, EGA state,
ports, BIOS/DOS calls compared under the rules documented at the top of `tools/libdiff.py`),
`--screens` decodes all screen files through both
display paths, `tools/callsite_report.py` lists the call sites whose AX the C routines derive from
arguments.

## Status

* Milestones 1-5 reached: all three episodes run; the library differential gate covers all 43
  called routines and all 13 screens; strict lockstep against the original passes for 18
  scenarios of SAM1-3 (`python tools/validate.py --lockstep`); automatic launcher, presentation
  settings and the Windows release package.
* Open: Linux execution testing, ending-screen gameplay coverage. Android is deferred.

The optional `-DSAM_LOCKSTEP=ON` target and `tools/lockstep.py` run the original in Unicorn on
this port's PC model and compare it with the port at every gameplay frame. Usage,
synchronization, comparisons and the named rules (including the documented uninitialised
sound-priority difference) are in [tests/port/lockstep/README.md](../tests/port/lockstep/README.md).
