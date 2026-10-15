# Runtime model and platform-layer checklist

The port's behavioral reference is [SAM.PAS](../game/SAM.PAS),
[SAMPLAY.PAS](../game/SAMPLAY.PAS), [SAMLEVEL.PAS](../game/SAMLEVEL.PAS),
and [SAMUI.PAS](../game/SAMUI.PAS), with hardware operations in the assembly
modules cited below. Routine-name citations remain usable while source line
numbers move during the readability pass. This document separates observed
DOS behavior from proposed SDL substitutions; no SDL backend has been built
or tested by this documentation task.

## Clock domains and interrupts

`CMOSPIT.SetFastGameTimer` writes `$36` to PIT control port `$43`, then low
and high bytes of divisor **$2147 = 8519** to channel 0, port `$40`, with
interrupts disabled. Using a nominal PIT input of 1193182 Hz gives
**140.0613 interrupts/sec**, period about 7.1397 ms. `InstallGameHandlers`
hooks **INT $1C**, the BIOS timer callback, rather than replacing IRQ0/INT 8.
The BIOS IRQ0 handler still runs at the faster rate. The game does not divide
that rate back down for the BIOS clock; normal shutdown resynchronizes DOS
time from CMOS instead. Source: [CMOSPIT.ASM](../game/CMOSPIT.ASM),
`SAM.InstallGameHandlers`, `TimerInterrupt`, normal program exit.

Each `TimerInterrupt` disables interrupts with CLI, increments
`GameTickCounter` and byte `TimerSubticks[0]`. Every 20 callbacks it resets
the subtick and updates powerups: speed time decrements by 1, slow/confusion
time by 2. A transition to exactly zero clears its flag and invalidates the
status bar; confusion also sets a message-pending flag. Effects start at 216:
speed therefore lasts about 30.84 seconds and slow/confusion about 15.42
seconds, subject to the current 20-tick phase. Every callback also advances
the selected sound effect if both playback and sound enable flags are set.
It executes STI before returning; it never invokes the saved INT 1C callback.
The saved callback is restored at exit.

`GameTickCounter` is shared by gameplay, popup animation and title/splash
timeouts, and callers frequently reset it. It is not a monotonic wall clock.
Menus do not suspend the timer handler: sound and temporary-effect timers
continue. Core gameplay, AI, damage grace, death/exit/teleport animation and
many counters advance on gameplay frames, not on every timer callback.
`PlayerDamageGraceTick` is decremented in the main program's frame block.

- [ ] Provide a deterministic 8519/PIT-clock callback schedule, a separate
  gameplay-frame gate, and wall-time delay support. Keep those three concepts
  distinct in the port.
- [ ] Keep the callback's ordering, including its 20-tick phase, powerup expiry
  flags and sound sample update. A single-threaded scheduler can replace real
  interrupt races while preserving ordering explicitly.
- [ ] Do not tie gameplay to Android display refresh. Record/replay should
  supply callback timing and input events as well as RNG state.

## Keyboard, text input and joystick

`KeyboardInterrupt` reads port `$60` and interprets PC set-1 make codes;
break code is make+$80. Configurable defaults are arrows, Ctrl jump, Alt
fire. Reversed controls exchange left/right **make and break** before the
rest of dispatch. This is a collection of held flags and event handlers,
not a 256-entry key-state array: a left make clears right, a right make
clears left; releases change standing/jumping poses. A make event can fire
a projectile directly in the interrupt, consume ammo and select a sound.
Repeat key events can therefore matter. It also sets menu/function-key and
cheat-chord flags. `PlayerInputLocked` gates the appropriate handlers;
there is no general E0/E1 multi-byte keyboard state machine.

The inline tail transfers to `SavedKeyboardVector` (the old INT 9 handler)
using a rewritten interrupt return frame and RETF. The old handler continues
BIOS buffering/acknowledgement. The following inline port-$61 toggle and
PIC `$20` acknowledgement bytes are unreachable after that transfer; they
also retain the original malformed `$80` byte where `$B0` would be MOV AL.
Do not execute that dead tail as a second acknowledgement in a port.

The BIOS ring-buffer tail at physical `$041C` is repeatedly assigned the
head at `$041A` to discard queued keys. Users include the main frame loop,
`SAMLEVEL.DecodeLevelRow`, and SAMUI popups, menu actions and transitions.
`ReadPopupScanCode` / `ReadScrollablePopupScanCode` consume
`LastKeyboardScanCode` and accepted-code lists. `ReadPopupText` additionally
polls port `$60` until a release, then uses `Crt.KeyPressed`/`ReadKey` for
characters, backspace and enter. Preserve the distinction between gameplay
scan events and character input for names and warp-level text.

The linked Crt `KeyPressed`/`ReadKey` path uses BIOS INT 16h AH=01h/00h;
it is a separate service from the custom INT 9 gameplay hook.
The Crt initialization also installs its Ctrl-Break handler for INT 1Bh
through DOS INT 21h AX=251Bh. That library hook is separate from the two
vectors explicitly saved/restored by the game's own code.

`GAMEJOY.IsJoystickPresent` reports absent only if **both** axes time out.
`JOYSTICK.ReadJoystickAxis` writes game port `$201` and counts until an axis
bit (1 shifted by axis index) clears, with a 65535-iteration timeout and CLI
around the timing loop. It returns -1 on timeout. Buttons are active-low
bits `$10` (jump) and `$20` (fire). `PollJoystickControls` compares axes with
calibrated center ±50, maps movement into held flags, and fires from button
1; `UpdatePlayerJump` reads button 0. Center calibration is runtime state,
not persisted with the joystick-enabled config setting. Source:
[GAMEJOY.PAS](../game/GAMEJOY.PAS), [JOYSTICK.ASM](../game/JOYSTICK.ASM),
`SAM.PollJoystickControls`, `SAMUI.CalibrateJoystickCenter`.

- [ ] Translate SDL keyboard/controller/touch controls into the existing
  held flags plus make/release actions; define repeat handling explicitly.
- [ ] Provide a separate UTF-8/text-input path with conversion to the game's
  supported glyphs and legacy byte strings. Clear pending input at the same
  dialog/scene boundaries where the DOS version clears the BIOS queue.
- [ ] Replace RC-loop joystick timing with normalized axes/deadzones while
  retaining button roles and movement/fire ordering.

## Frame loop, simulation and state

After defaults, sound loading, config and graphics loading, the program
shows APO then title/credits/main menu. Starting/restoring enters the island.
In the gameplay loop the status bar may refresh outside the frame gate.
The frame gate is **`GameTickCounter > 7`**, then sets it to zero: eight
callbacks minimum, nominally **17.5077 gameplay frames/sec**. Slow rendering
does not run catch-up simulation steps; ticks arriving during work remain
for the next gate. Retrace waits impose additional timing. Long popups,
palette fades and `Delay` calls block the frame loop while interrupts run.

A frame polls joystick, changes standing/walking poses, switches draw
buffer, erases previous player/actor/shot footprints by redrawing map cells,
moves the player and camera, applies mission jumping/gravity, discards BIOS
queued keys, processes four tile-contact corners, then updates actors and
shots. It draws the surviving objects, restores foreground over them,
handles teleport/death/exit effects and shows the draw buffer. Scene/menu
and restore/warp requests are processed by the surrounding program code.
Treat the statement order as part of compatibility: input can create shots
between frames; tile contacts precede `UpdateActorsAndShots`.

`GameActors[1..25]` has player in slot 1. `TGameActor` is 32 bytes: fifteen
signed 16-bit fields (flash, current/previous X,Y, animation, counters A/B,
kind value, state B, sprite base, X/Y directions, movement step, kind), then
inactive/removal bytes. `PlayerShots[1..10]` uses the same shape but a
separate pool; normal projectile limit starts at 1 and caps at 2. Map actors
are appended in load order without checking capacity. Several dynamic
allocators scan only up to slot 25 and overwrite that last slot when full.
`ActorRemovalPending` is distinct from `ActorSlotInactive`: erasure and
release happen in separate phases. See [actors.md](actors.md).

Most actors update only within a viewport rectangle enlarged by 32 pixels.
Kinds 14, 21 and 28 bypass this gate; their motion continues offscreen.
The erasure loop uses margin 40 and retains a few references to
`SharedLoopIndexB` where a reader might expect index A. Preserve or explicitly
decide how to handle those original mistakes; do not silently reinterpret
the source as idealized collision/visibility logic.

The world is 640×400; the displayed playfield is 320×184. Camera limits are
X 0..320, Y 0..184, so the 400-pixel world is not simply a 400-184 camera
range. Island movement is overhead; missions use a fixed 19-entry integer
vertical-motion table, no floating point physics. It is
`0,8,8,8,4,4,2,2,2,1,1,2,2,2,4,4,8,8,8`.
`UpdatePlayerJump`, `ApplyPlayerGravity` implement headroom, one-way landing
and snapped Y; `MovePlayerAndCamera` and `UpdatePlayerMoveSpeed` implement
the movement ramp (1,2,4, then 4+boost) and camera thresholds. Collision uses
the player inset X+3/X+12 and top/bottom Y; pickup checks use four corners.
Maintain signed 16-bit wrapping and bitwise alignment where observed;
`Word` offsets intentionally carry negative motion modulo 65536.

- [ ] Use the original fixed-step integer motion/state machine before tuning
  any touch controls or presentation interpolation.
- [ ] Implement island, mission, death return, save restore, exit, title and
  ending transitions; a save is a subset snapshot, not a whole simulation.
- [ ] Keep actor iteration order, offscreen-update exceptions and separate
  projectile pool. Test pool exhaustion and simultaneous contacts explicitly.

## Video, compositing and palette

`PROGRPHX` initialization switches toolbox mode 1 (BIOS `$10`, EGA 640×350),
queries ROM fonts with INT 10h AX=1130h, selects font 0 and draw color 15.
The game then selects toolbox mode 0 (BIOS **$0D**, 320×200, 16 colors).
The unused alternative toolbox mode selects BIOS `$12` (640×480). Genus
also selects display type 2 (320×200 EGA) for screen PCXs.

Gameplay sets stride to **80 bytes per EGA plane per row**, equivalent to
640 pixels. The visible viewport is still 320 pixels wide. It uses two
640×400 world drawings within the 64 KiB plane address space, beginning at
virtual pixel row **16** and **416** (byte offsets 1280 and 33280). This is
not BIOS display-page selection. `ToggleGameDrawBuffer` alternates origins;
`ShowGameDrawBuffer` sets CRTC start address to
`(bufferRow+CameraY)*80 + (CameraX >> 3)` and programs the attribute
controller for `CameraX & 7` fine panning. Two variants synchronize to
different retrace phases (`AlternateVideoTiming` config).

`PgSetEgaSplitScanline(190)` or `PgSetVgaSplitScanline(384)` establishes the
status-band line compare, with adapter-specific register treatment and
VGA scan doubling. Do not replace these literal values with an assumed
184 in the DOS model. `DrawGameStatusBar` draws eight-pixel glyphs near
VRAM origin; `PgCopyStatusBandTemplate` copies eight 40-byte rows from
offset `$28` to zero. Gameplay video has 320×184 logical playfield state
and a lower status region within the 320×200 output. A modern renderer
can compose that result explicitly without emulating CRTC scan registers.

Background, middle and foreground are separate cell fields. Actors/shots
are erased using previous positions and the cells underneath, then drawn
masked, and foreground is redrawn over sprites. `PgCopyCachedVideoTile16x16`
uses cached background tiles from the bottom map row. Several tiles change
appearance with the draw-buffer origin: teleporter upper half 179, water
499, tile 535, flame 613, laser 603 (visible on the lower buffer), and
624. Their visible alternation is tied to buffer alternation, not a stored
animation duration. Actor composites are assembled from 16×16 parts by
the main draw dispatch. See `SAMLEVEL.RedrawLevelCell`,
`DrawLevelCellResolved`, `DrawCellForeground` and the main program.

ProGraphx draws at segment `$A000`, using sequencer map mask at `$3C4/$3C5`
and graphics controller at `$3CE/$3CF`: read maps, bit mask, write modes,
latches, set/reset and data rotation. Capture/restore buffers are separate
from the on-disk sprite format; `PgCapturePlanarRectangle` stores height u16,
byte width u16, marker $FF, then sequential plane blocks in order 3,2,1,0.
`PgRestorePlanarRectangle` consumes them. `PgOrShifted16x16` performs
read-before-OR writes for flashing effects.
An RGBA renderer needs equivalent masks/OR behavior and layering; copying
the raw video-memory bytes into an SDL texture is insufficient.

`RestoreGamePalette` writes registers 0..7 to values 0..7, then registers
8..15 to values 16..23, via `PgSetPaletteRegister` (INT 10h AX=1000h).
These are hardware attribute palette codes, not 8-bit RGB intensities.
`FadeGamePaletteToBlack` waits then sets each register to zero in ascending
order; restore sets then waits per register. `BlackenGamePalette` sets
all immediately. The caller supplies per-register delays (commonly 20 ms).
`PgSetBorderColor` uses INT 10h AH=0Bh. The inspector's sprite PNGs use a
conventional DOS 16-color RGB palette; its PCXs use their embedded palette.
Exact EGA/VGA output color conversion should be a separate renderer choice.

Title/credits use stride 40, credits copied to row 200, title at row zero,
and retrace-synchronized panning between them. END screens use the same
PCX machinery; SAM3 shows A then B. `ShowDosExitScreen` uses text mode 3,
80×25 CP437 characters and attributes. TEXT80 assembly writes `$B800` or
`$B000` memory, optionally waiting on `$3DA` to avoid CGA snow.

- [ ] Provide indexed image decoding, binary write masks, opaque blits,
  shifted blits, OR flashing, foreground occlusion and captured popup regions.
- [ ] Reproduce world/viewport/camera geometry, logical buffer alternation,
  status-bar positioning and title panning; allow vsync presentation to be
  independent of simulation ticks.
- [ ] Keep palette-register fades and border state; make hardware-palette
  conversion explicit instead of baking screen palettes into game logic.

## Speaker playback

`SAMSOUND.StartSoundEffect` selects a one-based effect and sets its sample
index to 1. `TimerInterrupt` advances one frequency step per fast tick;
the exact gate/terminator order is in [formats.md](formats.md). `Crt.Sound`
programs PIT channel 2 via ports `$43/$42` and enables speaker gate/data
bits at `$61`; `NoSound` clears those two bits. The values passed to Sound
are frequencies. Original SAM1 Crt entry **2960:02C6** divides **1193181**
(`$0012:$34DD`) by the unsigned frequency and writes the divisor low/high
to $42. If neither low speaker bit is set, it first sets both and writes
mode $B6 to $43. Frequencies **0..18 return without changing anything**:
zero retains the previous speaker state. Silence comes from `NoSound`,
including the modulus gate. An authentic backend models integer PIT
divisors and phase/counter updates between events. The disassembly is
from the original images (research notes, not committed).

When sound is disabled, the timer **does not advance the current effect**
and that skipped branch does not itself call NoSound. It does not merely
mute an independently advancing stream. There is one
active effect, no mixing, and no music driver. The priority comparison in
`StartSoundEffect` is an original bug: it reads requested priority, overwrites
that local with current priority, then compares with a different uninitialized
local. Thus original interruption behavior is stack-dependent. The approved port
compatibility policy reads zero for uninitialised locals, retaining the faulty
comparison itself. The lockstep reference applies that policy at routine entry
only to diagnostics-listed locals, using verified translator BP-relative frame
slots. This is a documented compatibility difference, not a sound-state exclusion:
all sound globals, PIT channel 2 and timestamped speaker history remain exact.
See [port.md](port.md) for the generic memory-model rule.

- [ ] Use an SDL audio callback/ring buffer to synthesize timestamped speaker
  state changes; never block audio on graphics or asset I/O.
- [ ] Preserve timer-rate sample steps, silence gating, end detection and
  enable/disable behavior. Test the replacement policy for the priority bug.

## TP System Random

Game source calls `System.Random(n)` but never `Randomize` or assigns
`RandSeed`. The linked seed storage starts at zero in all three supplied
unpacked images. Disassembly of original SAM1 System entry **2CD0:0980**
and its helper **2CD0:09CF** gives:

```text
seed = (seed * 0x08088405 + 1) modulo 2^32
Random(n) = (seed >> 16) modulo n      # n > 0
Random(0) = 0                        # still advances the seed
```

The integer routine uses unsigned DIV and returns the remainder. This is
**not** the multiply-and-scale result found in later Pascal implementations.
The disassembly was taken from the original SAM1 load image (`python tools/oracle.py`
materialises it; research notes not committed). No new DOS compilation was used to infer this.
Executing that original entry in a 16-bit CPU emulator matched the formula
for 35 cases (five seeds including $FFFFFFFF, seven ranges including zero).
(Research notes, not committed.)

Calls in `SAMLEVEL.SpawnActorFromMapSymbol` / `DecodeLevelRow` choose initial
directions, cooldowns and animation phases. `SAMPLAY.UpdateBasicActor`
resets a guard timer with Random(50); `UpdateActorsAndShots` randomizes a
decorative animation. `SAMUI.ReadPopupScanCode`, `ReadPopupText` and
`ReadScrollablePopupScanCode` consume Random(100), Random(2) and position
ranges for spark animation. Those UI calls advance **the same global RNG**
as gameplay, so dialog timing changes later actor randomness. There is no
random seed in config/save records. Preserve call ordering for deterministic
compatibility, including calls whose result is only cosmetic.

- [ ] Implement the TP 5 integer RNG explicitly; avoid host `rand()` or a
  modern language's default RNG. Keep UI and gameplay streams shared for
  compatibility and include the seed in any new full-state save/replay.

## Files, heap and cleanup

The linked Crt initialization queries BIOS mode/cell attributes, selects
text mode 3 if it started in a graphics mode, and calibrates its delay loop
against the BIOS tick byte at **0040:006C**, before the program speeds up
the PIT. Later `Delay(ms)` runs that calibrated busy loop; its comparison
loop reads **0000:0000**, rather than waiting on the now-fast BIOS tick.
These details come from original SAM1 Crt 2960:0030/029E/02BE; the disassembly
was taken from the original image (research notes, not committed).
Native delays should use an application clock while continuing timer/audio
work, instead of trying to calibrate Android CPU spin loops.

All game asset/config/save accesses use fixed episode-relative filenames
in the DOS current directory. Pascal resources use typed `Read`/`Write`
through file variants with explicit record sizes; the game does not use
`BlockRead`/`BlockWrite`. Genus converts Pascal filenames to NUL-terminated
strings and uses DOS INT 21h AH=3Dh/3Fh/42h/3Eh, with a default 2048-byte
buffer. PCX loading begins with a retained **INT 3** instruction. It is not
encryption or a file signature; a native port needs no debugger interrupt.
Missing config installs defaults; missing save shows “File Not Found!”.
Other resource loads largely assume success. See formats.md for exact
filenames, serialization and stronger inspector validation.

Program memory directive is `$M 16384,0,655360`: 16 KiB stack, zero minimum
heap and up to DOS-available memory. Startup tests `MemAvail < 200000` and
prints a “450k free Memory” requirement before Halt. Actual long-lived
allocations are sixteen 8064-byte sprite banks (129024), three 2048-byte
glyph banks (6144), and three 7320-byte sound banks (21960): **157128 bytes**.
Popup routines allocate/free 30000-byte background capture buffers per
dialog. Source also has fixed shared globals (8000-byte map, 800-byte actor
array, 320-byte player-shot array, text arrays, counters). No dynamic actor
allocation, EMS/XMS asset cache or streaming sound is used. There are no
corresponding bank frees on normal exit; DOS reclaims the process memory.

`InstallGameHandlers` saves ExitProc and vectors 1C/09, replaces ExitProc
with `RestoreExitHandlers`. That handler restores ExitProc and those two
vectors only. On normal exit the program fades to black, selects BIOS text
mode 3, waits for active sound if enabled, calls NoSound, draws the DOS exit
screen, restores PIT channel 0 with divisor zero (=65536), restores vectors,
reads CMOS BCD registers through `$70/$71`, then sets DOS time/date using
INT 21h AH=2Dh/2Bh and saves config. CMOS year is interpreted as 1900+YY,
and time's hundredths field is set to 50. The ExitProc fallback alone does
not restore PIT/video/speaker/clock. The port should provide reliable native
cleanup rather than reproduce incomplete abnormal-exit cleanup.

- [ ] Package read-only data under an SDL/Android asset abstraction, and put
  mutable config/save files in writable application storage. Keep legacy
  parsing separate from new save/version policy.
- [ ] Replace segmented pointers/VRAM with owned buffers; retain exact legacy
  widths only where arithmetic or file layout depends on them.
- [ ] Restore/release audio, input capture, renderer and files on shutdown
  and Android lifecycle transitions. DOS clock setters and vector restoration
  become obsolete platform operations, not Android system-clock mutations.

## Hardware and interrupt inventory

The following is the port-layer boundary checklist. The assembly appendix
below inventories individual routines, including toolkit entries that are
present in the binary but not exposed/called by this game. Library support
does not imply that Secret Agent uses mouse, printer, Hercules or SVGA modes.

| Boundary | Source entry points and operations |
|---|---|
| Keyboard IRQ/data | `SAM.KeyboardInterrupt`: `$60`; inline transfer to old INT 9; dead `$61`/PIC `$20` tail |
| Vector/exit hooks | `SAM.InstallGameHandlers`, `RestoreGameInterrupts`, `RestoreExitHandlers`: GetIntVec/SetIntVec 1C/09, ExitProc |
| Shared BIOS keyboard memory | main program, `SAMLEVEL.DecodeLevelRow`, SAMUI input/menu/transition routines: MemW 0000:041A/041C |
| Video detection | `SAM.DetectBiosVideoAdapter` (SAM2/3): INT 10h AH=0Fh, AX=1A00h, AH=12h BL=10h; `SAMUI.DetectGameVideoAdapter`: INT 10h AX=1B00h and equipment INT 11h, then reads a far pointer at 0000:0487 and dereferences its byte; `TEXT80.DetectTextVideoAdapter`/`GetTextVideoMode` via TEXTOUT |
| BIOS video memory | `PgSetEgaSplitScanline` reads the CRTC base port from BDA 0040:0063 and polls base+6; text output selects B000/B800; ROM font addresses come from BIOS |
| EGA/VGA pixels and scanout | ProGraphx modes/blits/capture/copies: A000, sequencer 3C4/5, GC 3CE/F, CRTC 3D4/5, attribute 3C0, status 3DA, INT 10h |
| PCX file/display | Genus: DOS INT 21h open/read/seek/close, INT 3, EGA/SVGA ports and VRAM; game uses EGA path only |
| Speaker | `SAM.TimerInterrupt` via Crt.Sound/NoSound: PIT channel 2 $42/$43, gate $61; StartSoundEffect only changes shared state |
| PIT / RTC / DOS clock | `SetFastGameTimer`, `RestoreDefaultTimer`, `ReadCmosDecimal`, `SyncDosClockFromCmos` in CMOSPIT: $40/$43, $70/$71, INT 21h 2D/2B |
| Game controller | GAMEJOY button functions: Port[$201]; JOYSTICK axis functions: IN/OUT $201 and CLI/STI |
| Text console | TEXT80 / TEXTOUT: B000/B800, $3DA; Crt.TextMode/KeyPressed/ReadKey; Pascal Writeln/Halt and DOS process teardown |
| Crt initialization/delay | BIOS mode/cell queries through INT 10h; DOS INT 21h AX=251Bh installs INT 1Bh Ctrl-Break; calibrates at 0040:006C, later Delay compares 0000:0000 in a counted loop |
| Blocking delays | SAMUI palette functions and ending; `SAMPLAY.ProcessPlayerTileContact` invisible-platform reveal: Crt.Delay |
| Decode critical section | `DecryptGameAssetBuffer` CLI/STI; no hardware data dependency in its byte transform |
| Fonts | `PROGRAPX.PgInitializeRomFonts`: INT 10h AX=1130h to get BIOS ROM font pointers; game text primarily uses GFX glyphs |
| Unused toolkit services | Genus INT 17h printer and INT 16h keyboard abort; ProGraphx INT 33h mouse cursor, BIOS page/reset functions and general drawing; JOYSTICK four-axis entry |

The Pascal memory survey finds no other explicit `Mem[]`/`MemW[]` hardware
addresses. `Port[]` appears only in keyboard/popup release polling and game
port buttons. Genus has CGA B800 and Hercules B000 paths and SVGA register
access that are not exercised by the game's selected EGA descriptor.

<!-- ASSEMBLY_INVENTORY -->

### Assembly entry-point survey

Direct operations are listed per routine. INT operands and explicit
port loads are resolved from source equates where possible. A port
loaded through a variable/helper is described in the main inventory;
OUT DX,AX also writes the following data port. “VRAM” means a direct
video-segment reference; helper-only callers are covered by the group
descriptions above. This includes unused toolkit code.

**[CMOSPIT.ASM](../game/CMOSPIT.ASM)**

| Routine | Direct hardware operations |
|---|---|
| `ReadCmosDecimal` | IN/OUT 70h, 71h |
| `SyncDosClockFromCmos` | INT 21h |
| `SetFastGameTimer` | IN/OUT 40h, 43h; CLI/STI |
| `RestoreDefaultTimer` | IN/OUT 40h, 43h; CLI/STI |

**[DECODE.ASM](../game/DECODE.ASM)**

| Routine | Direct hardware operations |
|---|---|
| `DecryptGameAssetBuffer` | CLI/STI |

**[JOYSTICK.ASM](../game/JOYSTICK.ASM)**

| Routine | Direct hardware operations |
|---|---|
| `MeasureJoystickAxisToWord` | IN/OUT via DX/helper; CLI/STI |
| `ReadJoystickAxis` | IN/OUT 201h; CLI/STI |

**[TEXTOUT.ASM](../game/TEXTOUT.ASM)**

| Routine | Direct hardware operations |
|---|---|
| `TextCellAddress` | VRAM |
| `WriteColoredText` | IN/OUT 3dah; CLI/STI; text VRAM via TextCellAddress |
| `WriteTextCharacters` | IN/OUT 3dah; CLI/STI; text VRAM via TextCellAddress |
| `QueryAndSaveTextVideoMode` | INT 10h |
| `DetectTextVideoAdapter` | INT 10h |

**[GENUS.ASM](../game/GENUS.ASM)**

| Routine | Direct hardware operations |
|---|---|
| `PcxSetGraphicsOrTextMode` | INT 10h |
| `PcxInitializeVideoDescriptors` | VRAM |
| `PcxHerculesModeHelper` | IN/OUT 3b4h, 3b5h, 3b8h |
| `PcxSetHerculesControl` | IN/OUT 3bfh |
| `PcxDisplayBuffer` | INT 10h |
| `PcxCgaDecodeContinuation` | VRAM via display descriptor |
| `PcxEgaDecodeContinuation` | IN/OUT 3c4h, 3ceh; VRAM via display descriptor |
| `PcxVga256DecodeContinuation` | VRAM via display descriptor |
| `PcxHerculesDecodeContinuation` | VRAM via display descriptor |
| `PcxParadiseDecodeContinuation` | IN/OUT 3ceh; VRAM via display descriptor |
| `PcxTsengDecodeContinuation` | IN/OUT 3cdh; VRAM via display descriptor |
| `PcxVideo7DecodeContinuation` | IN/OUT 3c2h, 3c4h, 3cch; VRAM via display descriptor |
| `PcxDisplayFile` | INT 21h, 3 |
| `PcxRefillReadBuffer` | INT 21h |
| `PcxBeginPrinterImage` | INT 17h |
| `PcxSendPrinterString` | INT 17h |
| `PcxPrintScanline` | INT 16h, 17h |

**[PROGRAPX.ASM](../game/PROGRAPX.ASM)**

| Routine | Direct hardware operations |
|---|---|
| `PgSetToolboxVideoMode` | INT 10h |
| `PgSetBiosVideoMode` | INT 10h |
| `PgSetScreenStride` | IN/OUT 3d4h |
| `PgPanDisplayAtRetraceStart` | IN/OUT 3c0h, 3d4h, 3dah; CLI/STI |
| `PgPanDisplayAtRetraceEnd` | IN/OUT 3c0h, 3d4h, 3dah; CLI/STI |
| `PgSetEgaSplitScanline` | IN/OUT via DX/helper; BDA 0040:0063 |
| `PgWaitVerticalRetrace` | IN/OUT 3dah |
| `PgSetVgaSplitScanline` | IN/OUT 3d4h |
| `PgSetBorderColor` | INT 10h |
| `PgResetCurrentVideoMode` | INT 10h |
| `PgSetPaletteRegister` | INT 10h |
| `PgBlitMasked32x16` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgBlitMasked16x16` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgBlitMasked8x8` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgBlitSinglePlaneRectangle` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgPutPixel` | IN/OUT 3ceh, 3cfh; VRAM |
| `PgPutPixelClipped` | IN/OUT 3ceh, 3cfh; VRAM |
| `PgGetPixel` | IN/OUT 3ceh, 3cfh; VRAM |
| `PgShowVideoPageBios` | INT 10h |
| `PgSetMouseCursorShape` | INT 33h |
| `PgFillRectangleByteAligned` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgFillRectangleClipped` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgPixelAddressAndBitHelper` | VRAM |
| `PgDrawLineBresenham` | IN/OUT 3ceh |
| `PgDrawLineBresenhamVariant` | IN/OUT 3ceh |
| `PgDrawRectangleOutline` | IN/OUT 3ceh |
| `PgDrawRectangleOutlineClipped` | IN/OUT 3ceh |
| `PgFillRectangle` | IN/OUT 3ceh |
| `PgFillRectangleClippedPixels` | IN/OUT 3ceh |
| `PgDrawHorizontalSpan` | IN/OUT 3ceh |
| `PgDrawVerticalSpan` | IN/OUT 3ceh |
| `PgFillCircle` | IN/OUT 3ceh |
| `PgDrawCircle` | IN/OUT 3ceh |
| `PgCapturePlanarRectangle` | IN/OUT 3ceh; VRAM |
| `PgRestorePlanarRectangle` | IN/OUT 3c4h, 3c5h; VRAM |
| `PgBlitMaskedShifted32x16` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgBlitMaskedShifted16x16` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgBlitMaskedShifted8x8` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgDrawEllipse` | IN/OUT 3ceh |
| `PgPlotEllipseSymmetricPixels` | IN/OUT 3ceh |
| `PgBlitMasked32x16Clipped` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgBlitMasked16x16Clipped` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgCapturePixelRectangle` | IN/OUT 3ceh |
| `PgRestorePixelRectangle` | IN/OUT 3ceh |
| `PgOrShifted32x16` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgOrShifted16x16` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgOrShifted8x8` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgInitializeRomFonts` | INT 10h |
| `PgSetEgaBitMaskHelper` | IN/OUT 3ceh |
| `PgSetEgaSetResetHelper` | IN/OUT 3ceh |
| `PgSetEgaDataRotateHelper` | IN/OUT 3ceh |
| `PgFontPixelAddressHelper` | VRAM |
| `PgDrawFontPixelHelper` | IN/OUT 3ceh |
| `PgBlitOpaque32x16` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgBlitOpaque16x16` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgBlitOpaque8x8` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgBlitOpaque32x16Clipped` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgBlitOpaque16x16Clipped` | IN/OUT 3c4h, 3c5h, 3ceh; VRAM |
| `PgCopyCachedVideoTile16x16` | IN/OUT 3c5h, 3ceh, 3cfh; VRAM |
| `PgCopyVideoScreenRegion320x200` | IN/OUT 3c4h, 3c5h, 3ceh, 3cfh; VRAM |
| `PgCopyStatusBandTemplate` | IN/OUT 3c4h, 3c5h, 3ceh, 3cfh; VRAM |
| `PgCopyVideoTile16x16UnusedCdecl` | IN/OUT 3c4h, 3c5h, 3ceh, 3cfh; VRAM |
| `PgCopyVideoRectangleUnusedCdecl` | IN/OUT 3c4h, 3c5h, 3ceh, 3cfh; VRAM |

### Pascal BIOS keyboard queue users

Each listed routine writes the tail word at 0000:041C from the head
word at 0000:041A (possibly many times in polling loops).

- `SAM.PAS`: `program gameplay loop`.
- `SAMLEVEL.PAS`: `DecodeLevelRow`.
- `SAMUI.PAS`: `AskWarpLevel`, `CalibrateJoystickCenter`, `ConfirmQuitToDos`, `ReadPopupScanCode`, `ReadPopupText`, `ReadScrollablePopupScanCode`, `RedefineKeyboardBindings`, `SelectJoystickSetting`, `SelectSoundSetting`, `SelectVideoCompatibility`, `ShowAboutApogee`, `ShowApogeeBbsInformation`, `ShowApogeeSplash`, `ShowEpisodeEnding`, `ShowForeignDealers`, `ShowFortressUnlockedMessage`, `ShowOrderContactDetails`, `ShowOrderPackageDetails`, `ShowOrderingInformation`, `ShowPerfectHealthBonus`, `ShowQuitDestinationMenu`, `ShowRestoreGameMenu`, `ShowSaveGameMenu`, `ShowTitleAndCredits`.
