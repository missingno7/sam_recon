# Whole-game original/port comparison

Build with `-DSAM_LOCKSTEP=ON`, then build target `sam_lockstep`. The option is
OFF by default. `pc.h` is unchanged. The DLL contains the real platform, fonts,
TP runtime, library, and all three translated episodes. No original bytes are
embedded in a delivered source file.

```powershell
python -B tools/prepare_reference.py
$cmake = 'C:/Program Files/Microsoft Visual Studio/2022/Community/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe'
& $cmake -S port -B build/lockstep -G 'MinGW Makefiles' -DCMAKE_C_COMPILER=C:/msys64/mingw64/bin/gcc.exe -DCMAKE_MAKE_PROGRAM=C:/msys64/mingw64/bin/mingw32-make.exe -DSAM_LOCKSTEP=ON
& $cmake --build build/lockstep --target sam_lockstep -j4
python -B tools/lockstep_checks.py
python -B tools/lockstep.py --episode sam1 --scenario tests/port/lockstep/mission-sam1.json --output build/mission-sam1
python -B tools/lockstep.py --episode sam1 --scenario tests/port/lockstep/save-restore-quit.json --output build/save-sam1
```

Use the matching mission script for sam2/sam3. A two-side run returns 0 only for
completed strict comparison, 1 for divergence/incomplete coverage, and 2 for a
child failure. A side-only run returns execution status, not a certification.
`--side compare` rechecks retained artifacts. Snapshots, copied data, reference
images, and screenshots are test outputs and must never be committed.

## Original execution

The original unpacked image comes from `oracle.load_image`, with relocations
at PSP+16 and DS/SS/heap placement from `config/port.json`. Unicorn maps the DLL's
actual `pc_mem` with `mem_map_ptr`; the region above 1 MB aliases low RAM. A0000
is MMIO through `vga_cpu_read/write`. IN/OUT use the shared platform. Registered
BIOS addresses call their actual C handlers. INT and IRQ entry push FLAGS/CS/IP,
clear IF/TF, and load the actual IVT. BIOS service returns implement IRET;
original RETF/IRET instructions otherwise execute normally. Pending hardware
IRQs are delivered at a stopped original instruction boundary, while IF allows
it. No game procedure is replaced or retimed.

## Symmetric test clock

Default `--clock wait` charges **zero time for productive instructions**, on both
sides. The normal game executable retains its wall clock and ordinary safe
points. `--clock instruction --cpu-mhz 20` preserves the earlier diagnostic CPU
model and is not the lockstep certification clock.

Wait events are reads of 3DAh/3BAh, 60h, or 201h; shared BIOS INT 16h/1Ah
services; Crt Delay waits; and reads of designated interrupt-owned DS words.
The translator emits read wrappers only for the lockstep build. The original
watches the matching direct DS reads, located by disassembly and layout offsets;
it excludes read/modify/write instructions such as the timer's INC. The CPU
stops before the read, services the wait, and resumes that same instruction once.
BIOS services use the identical shared C wait and flush pending IRQs on return.
Crt Delay's original runtime entry charges `pc_delay_ms`, the same wait as
`tp_Delay`, then resumes the original Delay body with zero productive-time cost.
That preserves its real CPU register and stack residue. No original game or TP
procedure is replaced.

A spin quantum is **two successive wait events in the wait-event stream**, even
when their kinds differ. Every wait delivers due events; every second wait
advances to the next platform device deadline and delivers again. DS writes do
not reset the quantum: popup polling consumes Random and writes DS on each
iteration. An empty blocking BIOS read repeats its wait event. Delay repeats
its wait event until its deadline. The next game-port quantum is at most 8 us;
retrace polling also considers the next VGA scanline edge. ISR-internal waits
are suppressed while the scheduler is already dispatching an interrupt, on
both sides. Other calls to `pc_poll` cannot advance the test clock or deliver
interrupts outside these shared wait/return points.

The requested GameTickCounter watch alone is insufficient for the original.
The instrument additionally designates these actual busy-wait state locations:

* BIOS BDA 0040:006C reads during Crt startup calibration. The C runtime executes
  the same two calibration waits in test mode; its speed-dependent result is
  excluded, not copied from the original.
* LastKeyboardScanCode: popup make/release waits have no port or timer reads.
* SoundPlaying: the shutdown loop waits for the timer to finish the effect.

These additions are explicit **proposed contract extensions**, requiring the
supervisor's decision. There is no RTC retiming and no per-game-routine delay.
The proposal for `docs/port.md` is in the worker REPORT.md.

## Input and frame boundaries

The gameplay boundary is immediately after the main program resets
GameTickCounter from >=8 to zero, before that frame's work. Popup resets are not
frames. Frame 1 and frames following a popup/load can inherit accumulated ticks;
the report measures these separately from ordinary eight-tick frames.

Each JSON event has raw XT make/break `scan` bytes and exactly one trigger:

* `frame`: enqueue after that boundary snapshot.
* `wait`: enqueue at that absolute count of shared wait events.
* `after`: routine entry (optional one-based `visit`), with `delay_waits` or
  `delay_us` relative to its entry.
* `poll`: count of BIOS keyboard checks; enabled only when the script uses it.
* `time_us`: absolute emulated time.

The queue supplies IRQ1 through the platform, never by editing Pascal state.
Scripts normally separate make and release; equal-time order is stable.
The walking and mission startup scripts use relative **wait counts**. The full
sequence of Random entry seeds and wait counts is retained and must match.
`frames`, `max_time_us`, `required_routines`, and optional `expect_exit` enforce
completion. `required_states` additionally checks observed fields and can compare
frames, so mission entry, jumping, firing, pickups, damage and moved-then-restored
position are enforced rather than inferred from a routine visit or input delivery.

## Comparison rules

Every checkpoint stores raw DS, all heap arena bytes (including free space and
allocator metadata), BDA keyboard flags/ring/bounds, four complete EGA planes,
VGA registers/latches/indices/flip-flops, PIT channel state including load times,
keyboard controller state, and timestamped speaker history. DS includes padding.
Raw artifacts are retained alongside a comparable DS projection. Projection is
limited to these named rules:

1. **Code-pointer identity.** ExitProc/SavedExitProc, all 22 Genus decoder
   pointers, and Input/Output Open/InOut/Flush/Close callbacks require equal
   symbolic names. Unknown nonzero identities fail. Original MAP publics,
   GENUS.LST decoder ranges, and TP5 System/Crt callback roles establish the
   names. The port resolves `pc_register_code` names. Addresses themselves are
   removed only from the byte projection; their required identities are compared
   separately on every snapshot. Typed FileRec has no function pointers.
2. **Crt calibration.** Exclude exactly the first two bytes of CrtPrivate,
   DelayCnt, whose value depends on CPU speed. ScreenMax, NormAttr, LastScan,
   BreakFlag and padding are compared.
3. **Intr/MsDos flags.** Compare CF/ZF/IF (0241h); PF/AF/SF/OF/TF and reserved
   bits are BIOS-implementation-defined. The persistent VideoBiosRegisters.Flags
   word is projected accordingly; other record bytes remain exact.

FileRec/TextRec are fully compared, including handles, modes, record/buffer
sizes, positions, pointers, names, and buffers. TP and Genus use the same DOS
handle table. No whole-file-record, RNG, sound, heap, or game-state exclusion is
permitted. Uninitialised StartSoundEffect priority has **no new policy**: a sound
mismatch remains a failing comparison.

The stack segment and C locals, code segments/assembly CS scratch, PSP/environment,
unrelated IVT entries, non-keyboard BDA, and host SDL/audio playback state are
outside the compared contract. Original CPU and shared-BIOS stack writes are nevertheless tracked
for the sound investigation. Each StartSoundEffect entry logs its requested
number, entry SP/caller BP/callee BP/callee SP, the BP-4 slot, both last-byte
writers, write values, widths, instruction addresses, and instruction counts.
The most recent MAP/native routine entries accompany snapshots. The comparison
reports the first differing globals by translator-layout name and every frame's
differing regions. PNGs are captured on both sides at selected frames.

## Current coverage status

The runner deliberately reports the uninitialised-sound divergence. The mission
routes and save/restore/quit scenario are diagnostic continuations after it;
none certifies whole-game equality. See REPORT.md for the actual reached states,
exact commands, all remaining decisions, and uncovered damage/death/key/door
work. Synthetic test programs and device checks are regression evidence, not
substitutes for those whole-game paths.
