# SDL3 port: design and contract

Goal: one program, `sam`, that plays all three episodes of Secret Agent on a modern system
(Windows/Linux first, Android later), generated from the same source that rebuilds the DOS
programs byte for byte. `game/` stays the single source of truth and is never edited for the
port; everything port-specific lives in `tools/pas2c.py` and `port/`.

## Shape

```
game/*.PAS --tools/pas2c.py, once per episode (SAM1/SAM2/SAM3)--> build/port-gen/samN/  (never committed)
game/*.ASM --rewritten once, by hand, in C ----------------------> port/lib/

sam(.exe) = episode 1 + episode 2 + episode 3   generated C, identifiers prefixed s1_/s2_/s3_
          + port/tp/    Turbo Pascal 5.0 System, Crt and Dos runtime (only what the game uses)
          + port/lib/   ProGraphx, Genus PCX toolkit, TEXTOUT, JOYSTICK, DECODE, CMOSPIT in C
          + port/pc/    the emulated PC: memory, interrupts, BIOS, PIT, speaker, keyboard
                        controller, game port, EGA/VGA, text mode; SDL3 underneath
          + port/launcher.c
```

The launcher discovers complete episode resource sets beside the executable (or in `--data`).
It starts a lone episode directly and otherwise uses an emulated text-mode chooser. A DOS exit
returns to that chooser; `--episode` retains single-run behavior for tests. Each start reloads
memory/devices and restores the assembly libraries' native CS-private initial state before
running the generated entry. SDL window and presentation preferences survive these DOS starts.
Host fullscreen, scaling, filter and window size live in `sam.json` beside the executable;
they do not alter the game, its `SAMn.CFG`, device timing or source-frame captures.

The game logic is never rewritten by hand: the translator encodes Turbo Pascal 5.0 semantics, so
the generated C does what the DOS program does, including its overflows and original bugs.
Everything below the game (TP runtime, assembly libraries, hardware) is C written against the
behaviour of the original code and tested against it.

## Memory model

The port keeps the DOS program's memory, because the game depends on it: arrays are overrun into
neighbouring globals (actor slots, see [actors.md](actors.md)), records are read and written as
raw file blocks, pointers are stored in records and in the save format, and the BIOS keyboard
buffer is cleared by writing its tail pointer.

* `pc_mem` is the real-mode address space: 1 MB plus the 64 KB wrap region. A far pointer is a
  `uint32_t` holding offset (low word) and segment (high word), exactly as a TP `Pointer` is
  stored. Linear address = `(seg << 4) + off`, wrapped to 20 bits.
* The program is "loaded" as DOS would load it: PSP at `PC_PSP_SEG`, the load image after it,
  DS and SS at the original relative paragraphs of each episode (oracle header: SS, and the DATA
  segment from the map). Code segments occupy their addresses but hold no code.
* **Every Pascal global and typed constant lives in emulated DS at its original offset.** The
  translator computes the layout with TP 5.0's rules (link order, typed constants then variables,
  `$A+` word alignment, smart-linker removal of unreferenced data) and emits each global as an
  lvalue over `pc_mem`; the tests require the translator's initial DS image to equal the
  original's DATA segment byte for byte.
* The heap is TP 5.0's own manager (HeapOrg, HeapPtr, FreeList, FreePtr) over `pc_mem`, with
  `$M 16384,0,655360` limits, so `GetMem`, `FreeMem`, `Mark`, `Release` and `MemAvail` return the
  original values. `New`/`GetMem` yield far pointers; `p^` dereferences through `pc_mem`.
* Locals and value parameters are C locals of the exact TP widths (`int16_t`, `uint16_t`,
  `uint8_t`, `int8_t`, `int32_t`, packed records, `uint8_t[n+1]` strings). `var` parameters are
  host pointers (into `pc_mem` for globals and heap data). Locals are zero-initialised; reads of
  uninitialised locals that the DOS program performs (e.g. the priority comparison in
  `StartSoundEffect`, [runtime.md](runtime.md)) are listed by the translator with the policy
  applied. This is a documented compatibility difference: the DOS program may
  read previous stack contents; the port reads zero. Differential tests apply the
  same policy to the original, generically from `diagnostics.json`: at each listed
  routine entry, zero exactly its reported local objects at translator-derived
  BP offsets, checked against the original TP prologue and BP references. They
  never exclude resulting sound state, PIT channel 2 or speaker history. Every
  comparison receipt records the rule, frame proofs and applied writes.
* Records are packed C structs with static size asserts; the hosts are little-endian.
* Segment A000 (EGA planes) is not plain memory: only `port/lib` and `port/pc` touch it, through
  the `vga_*` API. B800/B000 (text), 0040 (BIOS data) and the IVT are plain `pc_mem`.

## Interrupts and time

One thread runs the game; interrupts are delivered at **safe points**, which makes runs
deterministic and replayable:

* The translator inserts `pc_poll()` at every loop back-edge and procedure entry. `pc_poll` runs
  every interrupt that is due and enabled (IF set): IRQ0 at the rate programmed into PIT channel 0
  (the game sets divisor 8519, 140.06 Hz) through the BIOS INT 8 model to INT 1Ch, and IRQ1 for
  each queued key event through the INT 9 vector. It also captures a completed scanout at the
  emulated display rate and pumps SDL events. Host event pumping may be throttled in real-time
  runs, but runs before blocking; Windows input messages wake those waits immediately.
* Interrupt vectors live in the emulated IVT. Code that exists only as C (BIOS handlers, the
  game's `interrupt` procedures, `ExitProc` handlers) gets a far address from
  `pc_register_code`; calling a far address dispatches to the C function.
* `inline($FA)` / `inline($FB)` are `pc_cli()` / `pc_sti()`; `interrupt` procedures run with IF
  clear. The keyboard handler's chaining inline is translated to `pc_chain_interrupt(vector)`;
  its unreachable tail is dropped (documented in [runtime.md](runtime.md)). Any other `inline` is
  a translator error.
* Port 3DAh retrace status follows the VGA 400-line clock (25.175 MHz / 800 dots / 449 lines,
  70.0863 Hz) so retrace waits pace like
  the original. A busy-wait that keeps polling without anything becoming due sleeps until the
  next due event instead of burning the CPU.
* Real-time emulated time is latched at safe points. Productive work advances it by elapsed
  host time, capped at the next pending PIT, frame, script or enabled key edge. A status reader
  also caps it at the next relevant status transition. The caller observes that edge before
  another sample can advance time. Idle waits move to an exact emulated edge and pace against
  an absolute wall-time origin; they never adopt an overslept wall timestamp. Oversleep becomes
  lag and subsequent waits catch up without sleeping while behind. Lag beyond 100 ms rebases
  the wall origin, keeping the PC at its next edge rather than jumping across device history.
  Windows uses a high-resolution waitable timer, without a precision busy spin or a global
  timer-resolution change. The short retrace pulse remains lines 412-413, about 63.56 us.
* Windows real-time presentation runs on a separate D3D11 thread: a replaceable latest-frame
  mailbox feeds a vsynced flip swap chain with maximum frame latency one. It never runs game
  code, delivers interrupts or owns emulated memory. The PC thread only copies completed RGB
  frames under a short mutex; GPU work and vsync run outside that mutex. SDL window/input calls
  stay on the main thread. Monitor refresh does not change the emulated display clock.
  Manual-clock and lockstep timing are unchanged; other platforms use the SDL renderer.
* A hardware-library status loop can supply its mask and desired bits to
  `pc_wait_video_status`. In real time this selects the next relevant retrace edge, capped by
  other device deadlines. Port reads still evaluate the existing virtual-clock model at the
  actual read time. Manual-clock and differential runs treat the hint as an ordinary safe point.
* The audio callback follows an atomic publication of the emulated clock with a 10 ms replay
  margin. During host lag it holds the current PIT tone without consuming future device time;
  the oscillator still runs at the host sample rate. A long host stall therefore cannot leave
  audio permanently ahead after the clock rebases. Offline WAV replay retains the complete
  timestamped event history at 44.1 kHz. Live playback uses the device's native sample rate.

### Differential-test clock

The optional lockstep build advances emulated time only at shared wait events;
productive work costs no time. Normal play retains its wall clock and ordinary
safe points. Waits are reads of ports 3DAh/3BAh, 60h and 201h, BIOS INT 16h/1Ah,
Crt Delay, and interrupt-owned GameTickCounter, LastKeyboardScanCode and
SoundPlaying reads. BDA 0040:006C reads during Crt calibration are also waits.
The translator emits lockstep-only read hooks; the original watches matching
read instructions at translator DS offsets, excluding read/modify/write stores.
Crt Delay's original runtime entry charges the same wait as tp_Delay, then its
body executes with zero productive time, retaining runtime register/stack effects.

A spin is two successive wait events in the common event stream, regardless of
kind or intervening DS writes. Every wait delivers due events; every second wait
advances to the next device deadline and delivers again. Joystick quanta are at
most 8 us; retrace waits also consider the next scanline edge. Empty blocking
BIOS reads and Delay repeat their wait until satisfied. ISR-internal waits are
suppressed symmetrically during scheduler dispatch. Other safe points cannot
advance this clock or deliver IRQs. Input uses frame numbers or shared wait
counts, including offsets from named routine entries; both sides must consume
the same Random seeds at the same wait counts. There is no game-routine retiming.

## Naming and calling convention

| Kind | C name |
|---|---|
| game identifiers (per episode) | `s1_Name`, `s2_Name`, `s3_Name` (unit-qualified only on a collision) |
| TP library routines/variables used by the game | `tp_Name` (`tp_Delay`, `tp_Intr`, `tp_MemAvail` ...) |
| assembly routines (`external`) | the Pascal name (`PgBlitMasked16x16`), shared by the episodes |
| platform | `pc_*`, `bios_*`, `vga_*`, `platform_*` |

Parameters keep their Pascal types: value parameters by value with the exact widths, `var`
parameters as host pointers, `Pointer` and typed-pointer parameters as far pointers (`uint32_t`).
The assembly routines take their buffer arguments as far pointers and access them through
`pc_mem`, as the original code does through segment registers.

## Validation

1. **Translator, layout:** the generated initial DS image equals the original DATA segment of each
   episode; record sizes equal the TP sizes.
2. **Translator, semantics:** a corpus of small Pascal programs (integer typing and overflow,
   `shl`/`shr`, `div`/`mod`, comparisons of mixed signedness, `for` loops at type limits, strings
   and truncation, sets, `case`, nested procedures, `with`, typed files, `Str`/`Val`, `Random`) is
   compiled by the real TPC 5.0 (MS-DOS Player) and by pas2c + gcc; the outputs must be equal.
3. **Libraries:** each C rewrite of an assembly routine is run against the assembled routine
   (executed in unicorn from the `tools/verify.py` build, located with its map) on generated
   inputs; memory, registers it returns and the EGA state (planes, latches, registers) must match.
4. **Whole game:** `python tools/validate.py --lockstep` builds the optional test
   target and runs all scripted scenarios strictly. The original executes in Unicorn
   on the port's own emulated PC, using the differential-test clock above. Every
   boundary compares DS, heap, keyboard BDA, EGA state, PIT and speaker history,
   with only the named rules in `tests/port/lockstep/README.md`. This check needs
   the pinned DOS reference build for its routine MAP.

## Milestones

1. Translator output for all three episodes compiles and links headless against the runtime and a
   stub platform; DS images equal the originals.
2. SAM1 boots to the title screen in an SDL3 window.
3. All three episodes playable: gameplay, sound, keyboard and game controller, saves.
4. Differential tests (libraries, whole-game scripts) green.
5. One binary with the episode launcher; release build for Windows and Linux.
6. Android: SDL3's Android project, assets in the APK or picked by the user, touch controls
   mapped to the game's keys.

The platform reuses duke1_recon's port (`D:/Prog/duke1_recon/port`: EGA model `vga.c`, PIT and
speaker `pc_speaker.c`, SDL front end `pc_sdl.c`, script runner, `tools/dosref.py`), extended for
what Secret Agent uses beyond Duke: 640x400 virtual screens with an 80-byte stride, CRTC start
address and fine panning, the line-compare split for the status band, mode 10h for the font query,
and text mode 3 for the exit screen.
