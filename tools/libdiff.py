#!/usr/bin/env python3
"""Differential checks: port/lib C rewrites against the assembled originals.

    python -B tools/libdiff.py --matrix [--cases 200] [--realistic-cases 16] [--only NAME]
    python -B tools/libdiff.py --screens

The original routines run in unicorn from the SAM1 reference build (tools/verify.py --keep;
located with SAM.MAP); the C routines run in a DLL built with the test doubles in
tests/port/libdiff/. Both sides share one EGA model, BIOS/DOS service model, CMOS values and
scripted port reads. Comparison rules:

* memory: the whole 1 MB, except the routine's own stack scratch (SS:0 up to entry SP plus the
  parameter bytes it pops); C code-segment state is projected onto the matching assembly
  state symbols and compared;
* code addresses stored in data (Genus decoder pointers) are compared by name;
* function results at their Pascal widths; INT calls as an ordered list of service, the input
  registers and memory that service reads, and its outputs; non-VGA port writes in order;
  final EGA planes, registers and latches;
* entry AX: PgSetScreenStride, PgBlitMasked8x8, PgBlitOpaque8x8 and PgFillRectangleByteAligned
  read AX, which every game call site loads with the last pushed argument
  (tools/callsite_report.py); the original side is entered with that AX.
"""

from __future__ import annotations

import argparse
import ctypes
from dataclasses import dataclass, field
import os
import random
import re
import struct
import subprocess
import sys
from pathlib import Path

try:
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import common  # noqa: F401  (adds the pinned Unicorn wheel under build/python)
    from unicorn import Uc, UcError, UC_ARCH_X86, UC_HOOK_CODE, UC_HOOK_INSN, UC_HOOK_INTR
    from unicorn import UC_HOOK_MEM_READ, UC_HOOK_MEM_WRITE, UC_MODE_16
    from unicorn.x86_const import *
except ImportError as error:  # pragma: no cover
    raise SystemExit(f"missing pinned harness dependency: {error}") from error

ROOT = Path(__file__).resolve().parents[1]
DOUBLES = ROOT / "tests" / "port" / "libdiff"   # test doubles of pc.h and the EGA model
OUT = ROOT / "build" / "libdiff"
MEM_SIZE = 0x100000
LOAD_SEG = 0x1000
RETURN_SEG = 0xF000
RETURN_OFF = 0x0100
RETURN_LINEAR = (RETURN_SEG << 4) + RETURN_OFF
GCC = Path("C:/msys64/mingw64/bin/gcc.exe")


class PcRegs(ctypes.Structure):
    _fields_ = [(name, ctypes.c_uint16) for name in
                ("ax", "bx", "cx", "dx", "bp", "si", "di", "ds", "es", "flags")]


class PortWrite(ctypes.Structure):
    _fields_ = [("port", ctypes.c_uint16), ("value", ctypes.c_uint8)]


class PortRead(ctypes.Structure):
    _fields_ = [("port", ctypes.c_uint16), ("value", ctypes.c_uint8)]


class InterruptEvent(ctypes.Structure):
    _fields_ = [("vector", ctypes.c_uint8), ("input", PcRegs), ("output", PcRegs),
                ("input_memory_length", ctypes.c_uint16),
                ("input_memory", ctypes.c_uint8 * 260)]


class DataOffsets(ctypes.Structure):
    _fields_ = [(name, ctypes.c_uint16) for name in (
        "GenusPcxIdentity", "PcxDisplayDescriptions", "PcxSelectedDisplay",
        "PcxGraphicsModeState", "PcxDisplayPageState", "PcxModeCheckPolicy",
        "PcxDefaultReadBuffer", "PcxReadState", "PcxPrinterScanline",
        "PcxPrintedSourceRow", "PcxPrinterDeviceClass", "PcxPrinterResolutionClass",
        "PcxDisplayTable", "PcxHerculesGraphicsCrtc", "PcxHerculesTextCrtc",
        "PcxPrinterState", "TextVideoSegment", "TextRetraceSyncEnabled",
        "TextSavedBiosMode", "TextVideoAdapterClass")]


def get_oracle() -> tuple[Path, Path]:
    paths = sorted((ROOT / "build" / "verify").glob("sam1-*/SAM.EXE"),
                   key=lambda path: path.stat().st_mtime, reverse=True)
    for exe in paths:
        map_file = exe.with_name("SAM.MAP")
        if map_file.exists():
            return exe, map_file
    raise FileNotFoundError("run python tools/verify.py --episodes sam1 --keep first")


def read_map(path: Path) -> tuple[dict[str, tuple[int, int]], dict[str, int]]:
    publics: dict[str, tuple[int, int]] = {}
    segments: dict[str, int] = {}
    in_publics = False
    for line in path.read_text(encoding="ascii", errors="replace").splitlines():
        if "Publics by Value" in line:
            in_publics = True
            continue
        if in_publics:
            found = re.match(r"\s*([0-9A-Fa-f]{4}):([0-9A-Fa-f]{4})\s+(\S+)", line)
            if found:
                publics[found[3].upper()] = (int(found[1], 16), int(found[2], 16))
        found = re.match(r"\s*([0-9A-Fa-f]+)H\s+[0-9A-Fa-f]+H\s+[0-9A-Fa-f]+H\s+(\S+)\s+(DATA|CODE|STACK)", line)
        if found:
            segments[found[2].upper()] = int(found[1], 16) >> 4
    return publics, segments


def load_mz(path: Path) -> tuple[bytes, int, int]:
    exe = path.read_bytes()
    if exe[:2] != b"MZ":
        raise ValueError(f"not an MZ executable: {path}")
    reloc_count = struct.unpack_from("<H", exe, 6)[0]
    header_bytes = struct.unpack_from("<H", exe, 8)[0] * 16
    reloc_table = struct.unpack_from("<H", exe, 24)[0]
    module = bytearray(exe[header_bytes:])
    for i in range(reloc_count):
        off, seg = struct.unpack_from("<HH", exe, reloc_table + i * 4)
        location = seg * 16 + off
        value = struct.unpack_from("<H", module, location)[0]
        struct.pack_into("<H", module, location, (value + LOAD_SEG) & 0xFFFF)
    return bytes(module), struct.unpack_from("<H", exe, 14)[0], struct.unpack_from("<H", exe, 16)[0]


def build_dll() -> Path:
    OUT.mkdir(parents=True, exist_ok=True)
    out = OUT / f"libsamlib_test_{os.getpid()}.dll"
    source_dir = ROOT / "port" / "lib"
    sources = sorted(source_dir.glob("*.c")) + [
        DOUBLES / "pc_mock.c",
        DOUBLES / "vga_model.c",
    ]
    subprocess.run([
        str(GCC), "-std=c11", "-Wall", "-Wextra", "-Werror", "-shared",
        "-Wl,--export-all-symbols", "-DSAM_LIBDIFF_TEST", "-I", str(source_dir),
        "-I", str(DOUBLES), "-I", str(ROOT / "port" / "pc"),
        *(str(source) for source in sources), "-o", str(out),
    ], cwd=ROOT, check=True)
    return out


def bind_dll(path: Path):
    dll = ctypes.CDLL(str(path))
    dll.pc_inb.argtypes = [ctypes.c_uint16]
    dll.pc_inb.restype = ctypes.c_uint8
    dll.pc_outb.argtypes = [ctypes.c_uint16, ctypes.c_uint8]
    dll.pc_inw.argtypes = [ctypes.c_uint16]
    dll.pc_inw.restype = ctypes.c_uint16
    dll.pc_outw.argtypes = [ctypes.c_uint16, ctypes.c_uint16]
    dll.pc_bios_int.argtypes = [ctypes.c_uint8, ctypes.POINTER(PcRegs)]
    dll.vga_cpu_read.argtypes = [ctypes.c_uint16]
    dll.vga_cpu_read.restype = ctypes.c_uint8
    dll.vga_cpu_write.argtypes = [ctypes.c_uint16, ctypes.c_uint8]
    dll.vga_plane.argtypes = [ctypes.c_int]
    dll.vga_plane.restype = ctypes.POINTER(ctypes.c_uint8)
    dll.libdiff_reset.argtypes = []
    dll.libdiff_set_program.argtypes = [ctypes.c_uint16, ctypes.c_uint16, ctypes.c_uint16]
    dll.libdiff_port_write_count.restype = ctypes.c_uint32
    dll.libdiff_port_read_count.restype = ctypes.c_uint32
    dll.libdiff_interrupt_count.restype = ctypes.c_uint32
    dll.libdiff_interrupts_enabled.restype = ctypes.c_int
    dll.libdiff_port_write_at.argtypes = [ctypes.c_uint32]
    dll.libdiff_port_write_at.restype = PortWrite
    dll.libdiff_port_read_at.argtypes = [ctypes.c_uint32]
    dll.libdiff_port_read_at.restype = PortRead
    dll.libdiff_set_port_script.argtypes = [ctypes.POINTER(PortRead), ctypes.c_uint32]
    dll.libdiff_set_interrupts_enabled.argtypes = [ctypes.c_int]
    dll.libdiff_interrupt_at.argtypes = [ctypes.c_uint32]
    dll.libdiff_interrupt_at.restype = InterruptEvent
    dll.libdiff_set_data_dir.argtypes = [ctypes.c_char_p]
    dll.libdiff_set_data_offsets.argtypes = [ctypes.POINTER(DataOffsets)]
    dll.libdiff_set_bios_mode.argtypes = [ctypes.c_uint8]
    dll.libdiff_set_bios_adapter.argtypes = [ctypes.c_uint8, ctypes.c_uint8]
    dll.libdiff_set_cmos.argtypes = [ctypes.c_uint8, ctypes.c_uint8]
    dll.libdiff_vga_copy_state.argtypes = [ctypes.POINTER(ctypes.c_uint8), ctypes.c_size_t]
    dll.libdiff_code_name.argtypes = [ctypes.c_uint32]
    dll.libdiff_code_name.restype = ctypes.c_char_p
    return dll


def prepare_memory(module: bytes, rng: random.Random) -> bytearray:
    memory = bytearray(rng.randbytes(MEM_SIZE))
    start = LOAD_SEG << 4
    memory[start:start + len(module)] = module
    memory[RETURN_LINEAR:RETURN_LINEAR + 2] = b"\xcd\xff"
    return memory


def run_decode_case(dll, module: bytes, data_seg: int, stack_seg: int,
                    stack_top: int, entry: tuple[int, int], rng: random.Random,
                    forced_count: int | None = None) -> tuple[bool, int, list[tuple[int, int]]]:
    count = rng.randrange(0, 258) if forced_count is None else forced_count
    buf_seg, buf_off = 0x5200, 0x0100
    buf_linear = ((buf_seg << 4) + buf_off) & 0xFFFFF
    payload = rng.randbytes(count)
    memory = prepare_memory(module, rng)
    memory[buf_linear:buf_linear + count] = payload

    sp = (stack_top - count * 0 - 10) & 0xFFFF
    ss = (LOAD_SEG + stack_seg) & 0xFFFF
    stack_linear = ((ss << 4) + sp) & 0xFFFFF
    # The assembly reads count at BP+6, then the far var pointer at BP+8.
    args = struct.pack("<HHH", count, buf_off, buf_seg)
    return_frame = struct.pack("<HH", RETURN_OFF, RETURN_SEG) + args
    memory[stack_linear:stack_linear + len(return_frame)] = return_frame

    dll.libdiff_reset()
    dll_mem = (ctypes.c_uint8 * MEM_SIZE).in_dll(dll, "pc_mem")
    ctypes.memmove(dll_mem, bytes(memory), MEM_SIZE)
    dll.libdiff_set_program((LOAD_SEG + data_seg) & 0xFFFF, ss, sp)

    emu = Uc(UC_ARCH_X86, UC_MODE_16)
    emu.mem_map(0, MEM_SIZE)
    emu.mem_write(0, bytes(memory))
    emu.reg_write(UC_X86_REG_CS, (LOAD_SEG + entry[0]) & 0xFFFF)
    emu.reg_write(UC_X86_REG_DS, (LOAD_SEG + data_seg) & 0xFFFF)
    emu.reg_write(UC_X86_REG_ES, rng.randrange(0x10000))
    emu.reg_write(UC_X86_REG_SS, ss)
    emu.reg_write(UC_X86_REG_SP, sp)
    for reg in (UC_X86_REG_AX, UC_X86_REG_BX, UC_X86_REG_CX, UC_X86_REG_DX,
                UC_X86_REG_BP, UC_X86_REG_SI, UC_X86_REG_DI):
        emu.reg_write(reg, rng.randrange(0x10000))
    emu.reg_write(UC_X86_REG_EFLAGS, 0x202 | (0x400 if rng.randrange(2) else 0))

    emu.hook_add(UC_HOOK_INSN, lambda _u, p, s, _d: dll.pc_inw(p) if s == 2 else dll.pc_inb(p),
                 None, 1, 0, UC_X86_INS_IN)
    emu.hook_add(UC_HOOK_INSN, lambda _u, p, s, v, _d: dll.pc_outw(p, v) if s == 2 else dll.pc_outb(p, v),
                 None, 1, 0, UC_X86_INS_OUT)

    def vram_read(machine, _access, address, size, _value, _data):
        if 0xA0000 <= address < 0xB0000:
            for i in range(size):
                value = dll.vga_cpu_read((address - 0xA0000 + i) & 0xFFFF)
                machine.mem_write(address + i, bytes((value,)))

    def vram_write(_machine, _access, address, size, value, _data):
        if 0xA0000 <= address < 0xB0000:
            for i in range(size):
                dll.vga_cpu_write((address - 0xA0000 + i) & 0xFFFF,
                                  (value >> (i * 8)) & 0xFF)

    emu.hook_add(UC_HOOK_MEM_READ, vram_read)
    emu.hook_add(UC_HOOK_MEM_WRITE, vram_write)
    sentinel = [False]
    return_state: list[tuple[int, int, bytes]] = []

    def code_trace(machine, address, _size, _data):
        if not return_state and machine.reg_read(UC_X86_REG_CS) == ((LOAD_SEG + entry[0]) & 0xFFFF) and machine.reg_read(UC_X86_REG_IP) == ((entry[1] + 0xE5) & 0xFFFF):
            ss_now = machine.reg_read(UC_X86_REG_SS)
            sp_now = machine.reg_read(UC_X86_REG_SP)
            address_now = ((ss_now << 4) + sp_now) & 0xFFFFF
            return_state.append((ss_now, sp_now, bytes(machine.mem_read(address_now, 10))))
            return_ip, return_cs = struct.unpack_from("<HH", return_state[0][2])
            if return_ip != RETURN_OFF or return_cs != RETURN_SEG:
                return_state.clear()
                raise RuntimeError(f"unexpected far return {return_cs:04X}:{return_ip:04X}")
            # Unicorn's 16-bit far-return emulation does not honor this MZ stack
            # frame reliably. The call scaffold applies the documented RETF 6.
            machine.reg_write(UC_X86_REG_CS, return_cs)
            machine.reg_write(UC_X86_REG_IP, return_ip)
            machine.reg_write(UC_X86_REG_SP, (sp_now + 10) & 0xFFFF)
            sentinel[0] = True
            machine.emu_stop()

    emu.hook_add(UC_HOOK_CODE, code_trace)

    def interrupt(machine, vector, _data):
        if vector == 0xFF:
            sentinel[0] = True
            machine.emu_stop()
            return
        if vector not in (0x10, 0x21):
            raise RuntimeError(f"unmodeled INT {vector:02X}h")
        ctypes.memmove(dll_mem, machine.mem_read(0, MEM_SIZE), MEM_SIZE)
        names = ("ax", "bx", "cx", "dx", "bp", "si", "di", "ds", "es", "flags")
        ids = (UC_X86_REG_AX, UC_X86_REG_BX, UC_X86_REG_CX, UC_X86_REG_DX,
               UC_X86_REG_BP, UC_X86_REG_SI, UC_X86_REG_DI, UC_X86_REG_DS,
               UC_X86_REG_ES, UC_X86_REG_EFLAGS)
        regs = PcRegs(*(machine.reg_read(reg) & 0xFFFF for reg in ids))
        dll.pc_bios_int(vector, ctypes.byref(regs))
        machine.mem_write(0, bytes(dll_mem))
        for name, reg in zip(names, ids):
            machine.reg_write(reg, getattr(regs, name))

    emu.hook_add(UC_HOOK_INTR, interrupt)
    cs = (LOAD_SEG + entry[0]) & 0xFFFF
    start = (cs << 4) + entry[1]
    try:
        emu.emu_start(start, RETURN_LINEAR + 2, count=1_000_000)
    except UcError as error:
        raise RuntimeError(f"Unicorn failed at {emu.reg_read(UC_X86_REG_CS):04X}:{emu.reg_read(UC_X86_REG_IP):04X}: {error}") from error
    if not sentinel[0]:
        raise RuntimeError(f"routine did not return to sentinel (CS:IP {emu.reg_read(UC_X86_REG_CS):04X}:{emu.reg_read(UC_X86_REG_IP):04X})")
    asm_interrupt_flag = bool(emu.reg_read(UC_X86_REG_EFLAGS) & 0x200)
    oracle_memory = bytes(emu.mem_read(0, MEM_SIZE))

    dll.DecryptGameAssetBuffer.argtypes = [ctypes.c_uint32, ctypes.c_uint16]
    dll.DecryptGameAssetBuffer.restype = None
    seed_c_call_frame(dll_mem, ss, stack_top, args)
    dll.DecryptGameAssetBuffer((buf_seg << 16) | buf_off, count)
    c_memory = bytes(dll_mem)
    c_payload = c_memory[buf_linear:buf_linear + count]
    asm_payload = oracle_memory[buf_linear:buf_linear + count]
    platform_effects_match = (
        asm_interrupt_flag == bool(dll.libdiff_interrupts_enabled()) and
        dll.libdiff_port_write_count() == 0 and dll.libdiff_interrupt_count() == 0
    )
    diff_count, ranges = masked_memory_difference(
        oracle_memory, c_memory, stack_scratch_exclusion(ss, sp, 6))
    return asm_payload == c_payload and platform_effects_match, diff_count, ranges


def bind_data_offsets(publics: dict[str, tuple[int, int]]) -> DataOffsets:
    missing = [name.upper() for name, _field_type in DataOffsets._fields_
               if name.upper() not in publics]
    if missing:
        raise KeyError("DATA symbols missing from SAM.MAP: " + ", ".join(missing))
    return DataOffsets(*(publics[name.upper()][1]
                         for name, _field_type in DataOffsets._fields_))


class HostBuffer:
    def __init__(self, segment: int, offset: int):
        self.segment = segment & 0xffff
        self.offset = offset & 0xffff


@dataclass
class Invocation:
    name: str
    stack_args: bytes
    c_args: tuple
    popped: int
    result_kind: str = "void"
    entry_ax: int | None = None
    asm_entry: tuple[int, int] | None = None


@dataclass
class RoutineCase:
    target: Invocation
    prelude: list[Invocation] = field(default_factory=list)
    postlude: list[Invocation] = field(default_factory=list)
    writes: list[tuple[int, int, bytes]] = field(default_factory=list)
    port_script: list[tuple[int, int]] = field(default_factory=list)
    cmos: dict[int, int] = field(default_factory=dict)
    bios_mode: int = 3
    bios_adapter: int = 3
    bios_ega_mono: int = 0
    initial_if: bool = True
    planar_state: tuple[bytes, bytes, bytes, bytes] | None = None
    code_initial_values: dict[str, int] = field(default_factory=dict)


def configure_c_abi(dll) -> None:
    u16, i16, u8, u32 = ctypes.c_uint16, ctypes.c_int16, ctypes.c_uint8, ctypes.c_uint32
    signatures = {
        "PgSetToolboxVideoMode": ([u16], None), "PgSetBiosVideoMode": ([u16], None),
        "PgSetScreenStride": ([u16], i16), "PgPanDisplayAtRetraceStart": ([u16, u16], None),
        "PgPanDisplayAtRetraceEnd": ([u16, u16], None), "PgSetEgaSplitScanline": ([u16], None),
        "PgWaitVerticalRetrace": ([], None), "PgSetVgaSplitScanline": ([u16], None),
        "PgSetBorderColor": ([u16], None), "PgSetPaletteRegister": ([i16, i16], None),
        "PgBlitMasked16x16": ([u32, i16, i16], None),
        "PgBlitMasked8x8": ([u32, i16, i16], None),
        "PgSetDrawColor": ([u16], None), "PgFillRectangleByteAligned": ([u16, u16, u16, u16], None),
        "PgCapturePlanarRectangle": ([u32, i16, i16, i16, i16], None),
        "PgRestorePlanarRectangle": ([u32, i16, i16], None),
        "PgBlitMaskedShifted16x16": ([u32, i16, i16], None),
        "PgBlitMaskedShifted8x8": ([u32, u16, u16], None),
        "PgOrShifted16x16": ([u32, i16, i16], None),
        "PgInitializeRomFonts": ([], None), "PgSelectRomFont": ([u16], None),
        "PgBlitOpaque16x16": ([u32, i16, i16], None),
        "PgBlitOpaque8x8": ([u32, i16, i16], None),
        "PgCopyCachedVideoTile16x16": ([i16, i16, i16], None),
        "PgCopyVideoScreenRegion320x200": ([u16, u16, u16, u16], None),
        "PgCopyStatusBandTemplate": ([], None),
        "PcxSetDisplayType": ([u16], i16), "PcxSetGraphicsOrTextMode": ([u16], i16),
        "PcxGetDisplayType": ([], i16), "PcxGetDisplayDescriptor": ([u16], u32),
        "PcxInitializeVideoDescriptors": ([], None),
        "PcxDisplayBuffer": ([u32, u16, u16, u16, u16], i16),
        "PcxInitializeDisplayDispatch": ([], None),
        "PcxDisplayFile": ([u32, u16, u16, u16], i16),
        "PcxInitializePrinterState": ([], None),
        "WriteColoredText": ([u8, u8, u8, u32], None),
        "DetectTextVideoAdapter": ([], u8), "GetTextVideoMode": ([], u8),
        "ReadJoystickAxis": ([u16], i16),
        "DecryptGameAssetBuffer": ([u32, u16], None),
        "SyncDosClockFromCmos": ([], None), "SetFastGameTimer": ([], None),
        "RestoreDefaultTimer": ([], None),
    }
    for name, (argtypes, restype) in signatures.items():
        function = getattr(dll, name)
        function.argtypes = argtypes
        function.restype = restype
    dll.libdiff_progrphx_set_state.argtypes = [ctypes.POINTER(u16)]
    dll.libdiff_progrphx_get_state.argtypes = [ctypes.POINTER(u16)]
    dll.libdiff_cmospit_set_state.argtypes = [ctypes.POINTER(u16)]
    dll.libdiff_cmospit_get_state.argtypes = [ctypes.POINTER(u16)]


def far_pointer(pointer: HostBuffer) -> int:
    return (pointer.segment << 16) | pointer.offset


def set_port_script(dll, script: list[tuple[int, int]]) -> None:
    if script:
        values = (PortRead * len(script))(*(PortRead(port, value) for port, value in script))
        dll.libdiff_set_port_script(values, len(script))


def set_planar_state(dll, planes: tuple[bytes, bytes, bytes, bytes]) -> None:
    for plane_index, contents in enumerate(planes):
        target = dll.vga_plane(plane_index)
        ctypes.memmove(target, contents, 65536)


def call_c(dll, dll_memory, invocation: Invocation) -> int | None:
    args = tuple(far_pointer(arg) if isinstance(arg, HostBuffer) else arg
                 for arg in invocation.c_args)
    result = getattr(dll, invocation.name)(*args)
    return None if invocation.result_kind == "void" else int(result)


def result_matches(invocation: Invocation, c_result: int | None,
                   asm_result: int, detail: dict[str, int]) -> bool:
    kind = invocation.result_kind
    if kind == "void":
        return True
    assert c_result is not None
    if kind == "u8":
        return (c_result & 0xff) == (asm_result & 0xff)
    if kind in ("u16", "i16"):
        return (c_result & 0xffff) == (asm_result & 0xffff)
    if kind == "farptr":
        asm_far = ((detail["dx"] << 16) | detail["ax"]) & 0xffffffff
        return (c_result & 0xffffffff) == asm_far
    raise ValueError(f"unknown Pascal result kind {kind}")


def _words(*values: int) -> bytes:
    return struct.pack("<" + "H" * len(values), *(value & 0xffff for value in values))


def _inv(name: str, stack_args: bytes = b"", c_args: tuple = (),
         result_kind: str = "void", entry_ax: int | None = None,
         asm_entry: tuple[int, int] | None = None) -> Invocation:
    return Invocation(name, stack_args, c_args, len(stack_args), result_kind,
                      entry_ax, asm_entry)


def decode_real_asset_bank(dll, module: bytes, publics, data_segment: int,
                           stack_segment: int, stack_top: int, raw: bytes,
                           seed: int) -> bytes:
    if len(raw) not in (8064, 2048):
        raise ValueError(f"real graphics bank has unexpected size {len(raw)}")
    rng = random.Random(seed)
    initial = prepare_memory(module, rng)
    segment, offset = 0x5000, 0x0100
    address = ((segment << 4) + offset) & 0xfffff
    initial[address:address + len(raw)] = raw
    initial = bytes(initial)
    dll.libdiff_reset()
    dll_memory = (ctypes.c_uint8 * MEM_SIZE).in_dll(dll, "pc_mem")
    ctypes.memmove(dll_memory, initial, MEM_SIZE)
    ss = (LOAD_SEG + stack_segment) & 0xffff
    dll.libdiff_set_program((LOAD_SEG + data_segment) & 0xffff, ss, stack_top)
    emu = make_screen_emulator(dll, initial, data_segment, stack_segment, stack_top)
    args = _words(len(raw), offset, segment)
    call_original(emu, dll, publics["DECRYPTGAMEASSETBUFFER"], args, ss, stack_top)
    return bytes(emu.mem_read(address, len(raw)))


def local_assembly_entry(build_dir: Path, listing_name: str, symbol: str,
                         segment: int) -> tuple[int, int]:
    listing = (build_dir / listing_name).read_text(encoding="ascii", errors="replace")
    pattern = re.compile(r"^\s*\d+\s+([0-9A-Fa-f]{4})\s+" +
                         re.escape(symbol) + r"\s+proc\s+far", re.I)
    for line in listing.splitlines():
        found = pattern.match(line)
        if found:
            return segment, int(found[1], 16)
    raise RuntimeError(f"{symbol} entry not found in {listing_name}")


PROGRAPX_STATE = (
    "PgScreenStrideBytes", "PgDrawPage", "PgDrawColor", "PgRom8Offset",
    "PgRom8Segment", "PgRom8Height", "PgRom14Offset", "PgRom14Segment",
    "PgRom14Height", "PgFontOffset", "PgFontSegment", "PgFontHeight",
    "PgTransferRowsRemaining", "PgTransferRowBytes",
    "PgSpriteBytesRemaining", "PgSpriteRightShift", "PgSpriteLeftShift",
    "PgSpriteSourceMask", "PgSpritePlane0Byte", "PgSpritePlane1",
    "PgSpritePlane2", "PgSpritePlane3", "PgGlyphLeftShift",
    "PgGlyphMaskHigh", "PgGlyphMaskLow",
)
CMOSPIT_STATE = (
    "CmosHourWork", "CmosMinuteWork", "CmosSecondWork", "CmosMonthWork",
    "CmosDayWork", "CmosYearWork",
)


def parse_code_static_symbols(build_dir: Path, listing_name: str,
                              names: tuple[str, ...], segment: int,
                              linked_base: int) -> dict[str, tuple[int, int, int]]:
    listing = (build_dir / listing_name).read_text(encoding="ascii", errors="replace")
    found: dict[str, tuple[int, int]] = {}
    pattern = re.compile(r"^\s*(\S+)\s+(Byte|Word)\s+CODE:([0-9A-Fa-f]{4})\s*$", re.I)
    for line in listing.splitlines():
        match = pattern.match(line)
        if match and match[1].upper() in {name.upper() for name in names}:
            found[match[1].upper()] = (int(match[3], 16), 1 if match[2].lower() == "byte" else 2)
    missing = [name for name in names if name.upper() not in found]
    if missing:
        raise RuntimeError(f"{listing_name} does not map code state: {', '.join(missing)}")
    return {name: ((LOAD_SEG + segment) & 0xffff,
                   (found[name.upper()][0] + linked_base) & 0xffff,
                   found[name.upper()][1])
            for name in names}


def local_proc_offset(build_dir: Path, listing_name: str, symbol: str) -> int:
    listing = (build_dir / listing_name).read_text(encoding="ascii", errors="replace")
    pattern = re.compile(r"^\s*\d+\s+([0-9A-Fa-f]{4})\s+" +
                         re.escape(symbol) + r"\s+proc\s+far", re.I)
    for line in listing.splitlines():
        found = pattern.match(line)
        if found:
            return int(found[1], 16)
    raise RuntimeError(f"{symbol} entry not found in {listing_name}")


def read_code_static(memory: bytes | bytearray,
                     symbol: tuple[int, int, int]) -> int:
    segment, offset, width = symbol
    linear = ((segment << 4) + offset) & 0xfffff
    return int.from_bytes(memory[linear:linear + width], "little")


def write_code_static(memory: bytearray, symbol: tuple[int, int, int], value: int) -> None:
    segment, offset, width = symbol
    write_far(memory, segment, offset, int(value).to_bytes(width, "little"))


def initialize_c_code_statics(dll, initial: bytes,
                              prographx_symbols: dict[str, tuple[int, int, int]],
                              cmospit_symbols: dict[str, tuple[int, int, int]]) -> None:
    values = (ctypes.c_uint16 * len(PROGRAPX_STATE))(
        *(read_code_static(initial, prographx_symbols[name]) for name in PROGRAPX_STATE))
    dll.libdiff_progrphx_set_state(values)
    values = (ctypes.c_uint16 * len(CMOSPIT_STATE))(
        *(read_code_static(initial, cmospit_symbols[name]) for name in CMOSPIT_STATE))
    dll.libdiff_cmospit_set_state(values)


def project_c_code_statics(dll, memory: bytes,
                           prographx_symbols: dict[str, tuple[int, int, int]],
                           cmospit_symbols: dict[str, tuple[int, int, int]]) -> bytes:
    projected = bytearray(memory)
    values = (ctypes.c_uint16 * len(PROGRAPX_STATE))()
    dll.libdiff_progrphx_get_state(values)
    for name, value in zip(PROGRAPX_STATE, values):
        write_code_static(projected, prographx_symbols[name], value)
    values = (ctypes.c_uint16 * len(CMOSPIT_STATE))()
    dll.libdiff_cmospit_get_state(values)
    for name, value in zip(CMOSPIT_STATE, values):
        write_code_static(projected, cmospit_symbols[name], value)
    return bytes(projected)


def _sprite_source(name: str, rng: random.Random, case_index: int,
                   sprite_bank: bytes, glyph_bank: bytes) -> tuple[HostBuffer, list[tuple[int, int, bytes]]]:
    base_segment, base_offset = 0x5000, 0x0100
    if "8x8" in name:
        glyph_index = case_index % 50 if case_index >= 0 else rng.randrange(50)
        payload_offset = 3 + glyph_index * 40
        return HostBuffer(base_segment, base_offset + payload_offset), [
            (base_segment, base_offset, glyph_bank)]
    sprite_index = case_index % 50 if case_index >= 0 else rng.randrange(50)
    payload_offset = 3 + sprite_index * 160
    return HostBuffer(base_segment, base_offset + payload_offset), [
        (base_segment, base_offset, sprite_bank)]


def make_routine_case(name: str, rng: random.Random, case_index: int,
                      realistic: bool, ds_segment: int,
                      data_offsets: DataOffsets,
                      sprite_bank: bytes, glyph_bank: bytes,
                      screen_names: tuple[str, ...]) -> RoutineCase:
    target: Invocation
    prelude: list[Invocation] = []
    writes: list[tuple[int, int, bytes]] = [
        (0, 0, rng.randbytes(0x500)),
        (0x6000, 0, rng.randbytes(0x2000)),
    ]
    port_script: list[tuple[int, int]] = []
    code_initial_values: dict[str, int] = {}
    cmos = {i: rng.randrange(256) for i in (0, 2, 4, 7, 8, 9)}
    bios_mode = rng.choice((3, 4, 7, 0x0d, 0x10))
    bios_adapter = rng.randrange(4)
    bios_ega_mono = rng.randrange(2)
    initial_if = bool(rng.randrange(2))
    planar = tuple(rng.randbytes(65536) for _ in range(4))
    buffer_segment, buffer_offset = 0x5000, 0x0100
    aux_offset = 0x4000

    def put_buffer(payload: bytes, offset: int = buffer_offset) -> HostBuffer:
        writes.append((buffer_segment, offset, payload))
        return HostBuffer(buffer_segment, offset)

    def random_surface() -> tuple[int, int]:
        if realistic and case_index % 8 < 8:
            positions = (0, 1, 7, 8, 39, 40, 319, 320, 639)
            rows = (0, 1, 7, 8, 199, 200, 349)
            return positions[case_index % len(positions)], rows[(case_index // 2) % len(rows)]
        return rng.randrange(640), rng.randrange(350)

    def random_byte_surface() -> tuple[int, int]:
        if realistic:
            columns = (0, 1, 7, 8, 31, 39)
            rows = (0, 1, 7, 8, 192, 199)
            return columns[case_index % len(columns)], rows[(case_index // 2) % len(rows)]
        return rng.randrange(40), rng.randrange(200)

    genus_init = _inv("PcxInitializeVideoDescriptors")
    genus_select = _inv("PcxSetDisplayType", _words(2), (2,), "i16")
    genus_mode = _inv("PcxSetGraphicsOrTextMode", _words(1), (1,), "i16")
    draw_page = rng.randrange(2) if not realistic else case_index & 1
    stride = rng.choice((40, 80)) if realistic else (40 if case_index & 1 else 80)
    if name.startswith("Pg") and name in {
        "PgPanDisplayAtRetraceStart", "PgPanDisplayAtRetraceEnd", "PgBlitMasked16x16",
        "PgBlitMasked8x8", "PgFillRectangleByteAligned", "PgCapturePlanarRectangle",
        "PgRestorePlanarRectangle", "PgBlitMaskedShifted16x16", "PgBlitMaskedShifted8x8",
        "PgOrShifted16x16", "PgBlitOpaque16x16", "PgBlitOpaque8x8",
        "PgCopyCachedVideoTile16x16", "PgCopyVideoScreenRegion320x200",
        "PgCopyStatusBandTemplate",
    }:
        prelude.append(_inv("PgSetScreenStride", _words(stride), (stride,), "i16", stride))
    if name in {
        "PgPanDisplayAtRetraceStart", "PgPanDisplayAtRetraceEnd", "PgBlitMasked16x16",
        "PgBlitMasked8x8", "PgFillRectangleByteAligned", "PgCapturePlanarRectangle",
        "PgRestorePlanarRectangle", "PgBlitMaskedShifted8x8", "PgBlitOpaque16x16",
        "PgBlitOpaque8x8", "PgCopyCachedVideoTile16x16", "PgCopyStatusBandTemplate",
    }:
        code_initial_values["PgDrawPage"] = draw_page
    if name == "PgFillRectangleByteAligned":
        draw_color = rng.randrange(16)
        prelude.append(_inv("PgSetDrawColor", _words(draw_color), (draw_color,)))
    if name in ("PgSetDrawColor", "PgSetScreenStride"):
        if name == "PgSetDrawColor":
            prelude.append(_inv("PgSetScreenStride", _words(stride), (stride,), "i16", stride))
        else:
            draw_color = rng.randrange(16)
            prelude.append(_inv("PgSetDrawColor", _words(draw_color), (draw_color,)))
        code_initial_values["PgDrawPage"] = draw_page
    if name.startswith("Pcx") and name not in ("PcxInitializeVideoDescriptors",):
        if name in ("PcxSetDisplayType", "PcxGetDisplayType", "PcxGetDisplayDescriptor",
                    "PcxSetGraphicsOrTextMode", "PcxInitializeDisplayDispatch",
                    "PcxDisplayBuffer", "PcxDisplayFile"):
            prelude.append(genus_init)
    if name in ("PcxGetDisplayType", "PcxDisplayBuffer", "PcxDisplayFile"):
        prelude.append(genus_select)
    if name == "PcxSetGraphicsOrTextMode":
        prelude.append(genus_select)
    if name in ("PcxDisplayBuffer", "PcxDisplayFile"):
        prelude.append(genus_mode)

    sprite_pointer: HostBuffer | None = None
    if name in ("PgBlitMasked16x16", "PgBlitMaskedShifted16x16", "PgOrShifted16x16",
                "PgBlitOpaque16x16"):
        sprite_pointer, sprite_writes = _sprite_source(name, rng, case_index if realistic else -1,
                                                       sprite_bank, glyph_bank)
        writes.extend(sprite_writes)
    if name in ("PgBlitMasked8x8", "PgBlitMaskedShifted8x8", "PgBlitOpaque8x8"):
        sprite_pointer, sprite_writes = _sprite_source(name, rng, case_index if realistic else -1,
                                                       sprite_bank, glyph_bank)
        writes.extend(sprite_writes)

    if name == "PgSetToolboxVideoMode":
        value = rng.randrange(0x10000)
        target = _inv(name, _words(value), (value,))
    elif name == "PgSetBiosVideoMode":
        value = rng.randrange(0x10000)
        target = _inv(name, _words(value), (value,))
    elif name == "PgSetScreenStride":
        value = rng.choice((40, 80)) if realistic else rng.randrange(256)
        target = _inv(name, _words(value), (value,), "i16", value)
    elif name in ("PgPanDisplayAtRetraceStart", "PgPanDisplayAtRetraceEnd"):
        x, y = random_surface()
        target = _inv(name, _words(y, x), (x, y))
        port_script = [(0x3da, v) for v in (8, 0, 8, 0, 8, 0, 8, 0)]
    elif name in ("PgSetEgaSplitScanline", "PgSetVgaSplitScanline"):
        value = rng.choice((0, 199, 200, 255, 256, 349, 350, 511)) if realistic else rng.randrange(512)
        target = _inv(name, _words(value), (value,))
        if name == "PgSetEgaSplitScanline":
            writes.append((0x40, 0x0063, _words(0x03d4)))
            port_script = [(0x3da, v) for v in (0, 8)]
        else:
            port_script = [(0x3da, v) for v in (0, 8)]
    elif name == "PgWaitVerticalRetrace":
        target = _inv(name)
        port_script = [(0x3da, v) for v in (0, 8)]
    elif name == "PgSetBorderColor":
        color = rng.randrange(16)
        target = _inv(name, _words(color), (color,))
    elif name == "PgSetPaletteRegister":
        index, color = rng.randrange(16), rng.randrange(64)
        target = _inv(name, _words(color, index), (index, color))
    elif name in ("PgBlitMasked16x16", "PgBlitMasked8x8", "PgBlitOpaque16x16", "PgBlitOpaque8x8"):
        x, y = random_byte_surface()
        target = _inv(name, _words(y, x, sprite_pointer.offset, sprite_pointer.segment),
                      (sprite_pointer, x, y), entry_ax=y if name in
                      ("PgBlitMasked8x8", "PgBlitOpaque8x8") else None)
    elif name == "PgSetDrawColor":
        color = rng.randrange(16)
        target = _inv(name, _words(color), (color,))
    elif name == "PgFillRectangleByteAligned":
        if realistic:
            x = (0, 1, 7, 32, 39)[case_index % 5]
            width = min((1, 2, 8, 4)[case_index % 4], 40 - x)
            y = (0, 1, 192, 199)[case_index % 4]
            height = min((1, 2, 8, 1)[case_index % 4], 200 - y)
        else:
            x = rng.randrange(40)
            width = rng.randrange(1, min(8, 41 - x))
            y = rng.randrange(200)
            height = rng.randrange(1, min(8, 201 - y))
        target = _inv(name, _words(height, y, width, x), (x, width, y, height),
                      entry_ax=height)
    elif name == "PgCapturePlanarRectangle":
        if realistic:
            left = (0, 1, 32, 39)[case_index % 4]
            width = min((1, 2, 8, 1)[case_index % 4], 40 - left)
            top = (0, 1, 192, 199)[case_index % 4]
            height = min((1, 2, 8, 1)[case_index % 4], 200 - top)
        else:
            left = rng.randrange(40)
            width = rng.randrange(1, min(8, 41 - left))
            top = rng.randrange(200)
            height = rng.randrange(1, min(8, 201 - top))
        output = put_buffer(rng.randbytes(0x2000), aux_offset)
        right, bottom = left + width, top + height - 1
        target = _inv(name, _words(bottom, right, top, left, output.offset, output.segment),
                      (output, left, top, right, bottom))
    elif name == "PgRestorePlanarRectangle":
        rows, width = ((1, 2, 8)[case_index % 3], (1, 2, 8)[case_index % 3]) if realistic else (
            rng.randrange(1, 8), rng.randrange(1, 9))
        block = _words(rows, width) + bytes((0xff,)) + rng.randbytes(rows * width * 4)
        source = put_buffer(block, aux_offset)
        x, y = random_byte_surface()
        target = _inv(name, _words(y, x, source.offset, source.segment), (source, x, y))
    elif name in ("PgBlitMaskedShifted16x16", "PgBlitMaskedShifted8x8", "PgOrShifted16x16"):
        x, y = random_surface()
        if realistic and case_index < 8:
            x = 80 + case_index
            y = 50
        if name == "PgBlitMaskedShifted8x8":
            x, y = x & 0xffff, y & 0xffff
        target = _inv(name, _words(y, x, sprite_pointer.offset, sprite_pointer.segment),
                      (sprite_pointer, x, y))
        if name == "PgBlitMaskedShifted8x8":
            port_script = []
    elif name == "PgInitializeRomFonts":
        target = _inv(name)
    elif name == "PgSelectRomFont":
        prelude.append(_inv("PgInitializeRomFonts"))
        font = rng.randrange(4)
        target = _inv(name, _words(font), (font,))
    elif name == "PgCopyCachedVideoTile16x16":
        x, y = random_byte_surface()
        tile = rng.randrange(50)
        target = _inv(name, _words(tile, y, x), (x, y, tile))
    elif name == "PgCopyVideoScreenRegion320x200":
        sx, sy = random_byte_surface()
        dx, dy = random_byte_surface()
        target = _inv(name, _words(dy, dx, sy, sx), (sx, sy, dx, dy))
    elif name == "PgCopyStatusBandTemplate":
        target = _inv(name)
    elif name == "PcxSetDisplayType":
        index = rng.randrange(26)
        target = _inv(name, _words(index), (index,), "i16")
    elif name == "PcxSetGraphicsOrTextMode":
        prelude.append(genus_select)
        value = rng.randrange(3)
        target = _inv(name, _words(value), (value,), "i16")
    elif name == "PcxGetDisplayType":
        target = _inv(name, result_kind="i16")
    elif name == "PcxGetDisplayDescriptor":
        index = rng.randrange(22)
        target = _inv(name, _words(index), (index,), "farptr")
    elif name == "PcxInitializeVideoDescriptors":
        target = _inv(name)
    elif name == "PcxDisplayBuffer":
        header = bytearray(rng.randbytes(2048))
        header[0] = rng.choice(tuple(range(0x0a)) + tuple(range(0x0b, 0x100)))
        buffer = put_buffer(bytes(header))
        available = rng.randrange(0, 2049)
        x, y = random_surface()
        page = rng.randrange(2)
        stack = _words(page, y, x, available, buffer.offset, buffer.segment)
        target = _inv(name, stack, (buffer.segment << 16 | buffer.offset,
                                    available, x, y, page), "i16")
    elif name == "PcxInitializeDisplayDispatch":
        target = _inv(name)
    elif name == "PcxDisplayFile":
        screen_name = (rng.choice(screen_names) if realistic
                       else f"Q{case_index:07X}.PCX")
        string_offset = 0x7000
        path = screen_name.encode("ascii")
        writes.append((ds_segment, string_offset,
                       bytes((len(path),)) + path + b"\x00"))
        if realistic:
            # All game call sites load EGA type 2 and display at (1,0,page 0).
            x, y, page = 1, 0, 0
        else:
            x, y = random_surface()
            page = rng.randrange(2)
        stack = _words(page, y, x, string_offset, ds_segment)
        target = _inv(name, stack, ((ds_segment << 16) | string_offset, x, y, page), "i16")
    elif name == "PcxInitializePrinterState":
        target = _inv(name)
    elif name == "WriteColoredText":
        length = rng.randrange(1, 7)
        text_bytes = bytes(rng.randrange(32, 127) for _ in range(length))
        string = put_buffer(bytes((length,)) + text_bytes)
        column, row, color = rng.randrange(1, 81), rng.randrange(1, 26), rng.randrange(256)
        sync = rng.randrange(2)
        writes.extend([
            (ds_segment, data_offsets.TextVideoSegment, _words(0xb800)),
            (ds_segment, data_offsets.TextRetraceSyncEnabled, bytes((sync,))),
        ])
        target = _inv(name, _words(column, row, color, string.segment, string.offset),
                      (column, row, color, (string.segment << 16) | string.offset))
        target.stack_args = _words(string.offset, string.segment, color, row, column)
        if sync:
            port_script = [(0x3da, v) for _ in range(length) for v in (0, 1)]
    elif name == "DetectTextVideoAdapter":
        writes.append((ds_segment, data_offsets.TextSavedBiosMode,
                       bytes((rng.choice((3, 7)),))))
        target = _inv(name, result_kind="u8")
    elif name == "GetTextVideoMode":
        target = _inv(name, result_kind="u8")
    elif name == "ReadJoystickAxis":
        axis = rng.randrange(4)
        mask = 1 << axis
        discharge, charge = rng.randrange(1, 8), rng.randrange(1, 8)
        port_script = ([(0x201, mask)] * discharge + [(0x201, 0)] +
                       [(0x201, mask)] * charge + [(0x201, 0)])
        target = _inv(name, _words(axis), (axis,), "i16")
    elif name == "DecryptGameAssetBuffer":
        count = rng.randrange(0, 2049)
        source = put_buffer(rng.randbytes(4096))
        target = _inv(name, _words(count, source.offset, source.segment),
                      (source, count))
    elif name == "SyncDosClockFromCmos":
        cmos = {0: 0x25, 2: 0x34, 4: 0x12, 7: 0x14, 8: 0x08, 9: rng.randrange(0x90, 0x100)}
        port_script = [(0x71, cmos[index]) for index in (0, 2, 4, 7, 8, 9)]
        target = _inv(name)
    elif name in ("SetFastGameTimer", "RestoreDefaultTimer"):
        target = _inv(name)
    else:
        raise KeyError(f"no differential case generator for {name}")

    if realistic and name == "PgSetScreenStride":
        value = (40, 80)[case_index & 1]
        target = _inv(name, _words(value), (value,), "i16", value)
    return RoutineCase(target=target, prelude=prelude,
                       writes=writes, port_script=port_script, cmos=cmos,
                       bios_mode=bios_mode, bios_adapter=bios_adapter,
                       bios_ega_mono=bios_ega_mono, initial_if=initial_if,
                       planar_state=planar,
                       code_initial_values=code_initial_values)


def call_original(emu: Uc, dll, entry: tuple[int, int],
                  args: bytes, stack_segment: int, stack_top: int,
                  entry_ax: int | None = None,
                  result_detail: dict[str, int] | None = None,
                  initial_registers: dict[str, int] | None = None) -> int:
    sp = (stack_top - len(args) - 4) & 0xFFFF
    ss = stack_segment
    stack_linear = ((ss << 4) + sp) & 0xFFFFF
    frame = struct.pack("<HH", RETURN_OFF, RETURN_SEG) + args
    emu.mem_write(stack_linear, frame)
    emu.reg_write(UC_X86_REG_SS, ss)
    emu.reg_write(UC_X86_REG_SP, sp)
    emu.reg_write(UC_X86_REG_ESP, sp)
    if initial_registers:
        register_ids = {
            "ax": UC_X86_REG_AX, "bx": UC_X86_REG_BX, "cx": UC_X86_REG_CX,
            "dx": UC_X86_REG_DX, "bp": UC_X86_REG_BP, "si": UC_X86_REG_SI,
            "di": UC_X86_REG_DI, "es": UC_X86_REG_ES,
        }
        for name, value in initial_registers.items():
            if name in register_ids:
                emu.reg_write(register_ids[name], value & 0xffff)
        if "flags" in initial_registers:
            emu.reg_write(UC_X86_REG_EFLAGS, initial_registers["flags"] & 0xffff)
    if entry_ax is not None:
        emu.reg_write(UC_X86_REG_AX, entry_ax & 0xffff)
    entry_sp = sp
    return_state: list[int] = []
    return_trace: list[tuple[int, int, int, bytes]] = []
    transfer = [False]

    def finish_far_return(machine, address, _size, _data):
        opcode = bytes(machine.mem_read(address, 3))
        if opcode[0] in (0xCA, 0xCB) and len(return_trace) < 128:
            return_trace.append((machine.reg_read(UC_X86_REG_CS), machine.reg_read(UC_X86_REG_IP),
                                 machine.reg_read(UC_X86_REG_SP), opcode))
        if opcode[0] == 0xCA:
            cleanup = struct.unpack_from("<H", opcode, 1)[0]
        elif opcode[0] == 0xCB:
            cleanup = 0
        else:
            return
        if machine.reg_read(UC_X86_REG_SS) == ss and machine.reg_read(UC_X86_REG_SP) == entry_sp:
            return_state.append(machine.reg_read(UC_X86_REG_AX) & 0xFFFF)
            if result_detail is not None:
                result_detail.update({
                    "ax": machine.reg_read(UC_X86_REG_AX) & 0xffff,
                    "dx": machine.reg_read(UC_X86_REG_DX) & 0xffff,
                    "bx": machine.reg_read(UC_X86_REG_BX) & 0xffff,
                    "cx": machine.reg_read(UC_X86_REG_CX) & 0xffff,
                    "flags": machine.reg_read(UC_X86_REG_EFLAGS) & 0xffff,
                })
            machine.reg_write(UC_X86_REG_CS, RETURN_SEG)
            machine.reg_write(UC_X86_REG_IP, RETURN_OFF)
            machine.reg_write(UC_X86_REG_SP, (entry_sp + 4 + cleanup) & 0xFFFF)
        else:
            current_ss = machine.reg_read(UC_X86_REG_SS)
            current_sp = machine.reg_read(UC_X86_REG_SP)
            stack_address = ((current_ss << 4) + current_sp) & 0xFFFFF
            return_ip, return_cs = struct.unpack("<HH", bytes(machine.mem_read(stack_address, 4)))
            machine.reg_write(UC_X86_REG_CS, return_cs)
            machine.reg_write(UC_X86_REG_IP, return_ip)
            machine.reg_write(UC_X86_REG_SP, (current_sp + 4 + cleanup) & 0xFFFF)
        transfer[0] = True
        machine.emu_stop()

    hook = emu.hook_add(UC_HOOK_CODE, finish_far_return)
    cs = (LOAD_SEG + entry[0]) & 0xFFFF
    emu.reg_write(UC_X86_REG_CS, cs)
    emu.reg_write(UC_X86_REG_IP, entry[1])
    try:
        while not return_state:
            transfer[0] = False
            current_cs = emu.reg_read(UC_X86_REG_CS)
            current_ip = emu.reg_read(UC_X86_REG_IP)
            emu.emu_start((current_cs << 4) + current_ip, MEM_SIZE, count=20_000_000)
            if not transfer[0] and not return_state:
                break
    except UcError as error:
        raise RuntimeError(f"Unicorn failed in {entry[0]:04X}:{entry[1]:04X} at {emu.reg_read(UC_X86_REG_CS):04X}:{emu.reg_read(UC_X86_REG_IP):04X} SS:SP={emu.reg_read(UC_X86_REG_SS):04X}:{emu.reg_read(UC_X86_REG_SP):04X}: {error}") from error
    finally:
        emu.hook_del(hook)
    if not return_state:
        raise RuntimeError(f"original routine did not return from {entry[0]:04X}:{entry[1]:04X} (CS:IP {emu.reg_read(UC_X86_REG_CS):04X}:{emu.reg_read(UC_X86_REG_IP):04X} SS:SP {emu.reg_read(UC_X86_REG_SS):04X}:{emu.reg_read(UC_X86_REG_SP):04X} returns={return_trace[-12:]})")
    return return_state[0]


def make_screen_emulator(dll, initial_memory: bytes, data_segment: int,
                         stack_segment: int, stack_top: int) -> Uc:
    emu = Uc(UC_ARCH_X86, UC_MODE_16)
    emu.mem_map(0, MEM_SIZE)
    emu.mem_write(0, initial_memory)
    emu.reg_write(UC_X86_REG_DS, (LOAD_SEG + data_segment) & 0xFFFF)
    emu.reg_write(UC_X86_REG_SS, (LOAD_SEG + stack_segment) & 0xFFFF)
    emu.reg_write(UC_X86_REG_SP, stack_top)
    emu.reg_write(UC_X86_REG_ESP, stack_top)
    emu.reg_write(UC_X86_REG_EFLAGS, 0x202)
    emu.hook_add(UC_HOOK_INSN,
                 lambda _u, port, size, _d: dll.pc_inw(port) if size == 2 else dll.pc_inb(port),
                 None, 1, 0, UC_X86_INS_IN)
    emu.hook_add(UC_HOOK_INSN,
                 lambda _u, port, size, value, _d: dll.pc_outw(port, value) if size == 2 else dll.pc_outb(port, value),
                 None, 1, 0, UC_X86_INS_OUT)

    def vram_read(machine, _access, address, size, _value, _data):
        if 0xA0000 <= address < 0xB0000:
            offset = address - 0xA0000
            for i in range(size):
                value = dll.vga_cpu_read((offset + i) & 0xFFFF)
                machine.mem_write(address + i, bytes((value,)))

    def vram_write(_machine, _access, address, size, value, _data):
        if 0xA0000 <= address < 0xB0000:
            offset = address - 0xA0000
            for i in range(size):
                dll.vga_cpu_write((offset + i) & 0xFFFF, (value >> (8 * i)) & 0xFF)

    emu.hook_add(UC_HOOK_MEM_READ, vram_read)
    emu.hook_add(UC_HOOK_MEM_WRITE, vram_write)
    dll_memory = (ctypes.c_uint8 * MEM_SIZE).in_dll(dll, "pc_mem")
    register_names = ("ax", "bx", "cx", "dx", "bp", "si", "di", "ds", "es", "flags")
    register_ids = (UC_X86_REG_AX, UC_X86_REG_BX, UC_X86_REG_CX, UC_X86_REG_DX,
                    UC_X86_REG_BP, UC_X86_REG_SI, UC_X86_REG_DI, UC_X86_REG_DS,
                    UC_X86_REG_ES, UC_X86_REG_EFLAGS)

    def interrupt(machine, vector, _data):
        if vector == 3:  # The original PCX object retains an INT 3 at entry.
            return
        if vector not in (0x10, 0x21):
            raise RuntimeError(f"unmodeled INT {vector:02X}h")
        ctypes.memmove(dll_memory, bytes(machine.mem_read(0, MEM_SIZE)), MEM_SIZE)
        registers = PcRegs(*(machine.reg_read(reg) & 0xFFFF for reg in register_ids))
        dll.pc_bios_int(vector, ctypes.byref(registers))
        machine.mem_write(0, bytes(dll_memory))
        for name, reg in zip(register_names, register_ids):
            machine.reg_write(reg, getattr(registers, name))

    emu.hook_add(UC_HOOK_INTR, interrupt)
    return emu


def _service_register(regs: PcRegs, name: str) -> int:
    if name == "AH":
        return regs.ax >> 8
    if name == "AL":
        return regs.ax & 0xff
    if name == "BH":
        return regs.bx >> 8
    if name == "BL":
        return regs.bx & 0xff
    if name == "CH":
        return regs.cx >> 8
    if name == "CL":
        return regs.cx & 0xff
    if name == "DH":
        return regs.dx >> 8
    if name == "DL":
        return regs.dx & 0xff
    if name == "CF":
        return regs.flags & 1
    return getattr(regs, name.lower())


def interrupt_service_tuple(event: InterruptEvent) -> tuple:
    """Normalize an interrupt to the input fields consumed by its service."""
    vector = event.vector
    incoming = event.input
    outgoing = event.output
    memory_read = bytes(event.input_memory[:event.input_memory_length])
    if vector == 0x10:
        if incoming.ax >> 8 == 0x0f:
            service, read_names, output_names = "10h/AH=0Fh", ("AH",), ("AL", "AH", "BH")
        elif incoming.ax >> 8 == 0:
            service, read_names, output_names = "10h/AH=00h", ("AL",), ("AL",)
        elif incoming.ax == 0x1c00:
            service, read_names, output_names = "10h/AX=1C00h", ("AX",), ("AL",)
        elif incoming.ax == 0x1200:
            if (incoming.bx & 0xff) == 0x32:
                output_names = ("AL",)
                service = "10h/AX=1200h-BL=32h"
            elif (incoming.bx & 0xff) == 0x10:
                output_names = ("AL", "BH", "CX")
                service = "10h/AX=1200h-BL=10h"
            else:
                output_names = ()
                service = "10h/AX=1200h-other-BL"
            read_names = ("AX", "BL")
        elif incoming.ax == 0x1000:
            service, read_names, output_names = "10h/AX=1000h", ("BL", "BH"), ()
        elif incoming.ax == 0x1001:
            service, read_names, output_names = "10h/AX=1001h", ("BH",), ()
        elif incoming.ax == 0x1130:
            service, read_names, output_names = "10h/AX=1130h", ("AX", "BH"), ("ES", "BP")
        else:
            raise RuntimeError(f"unmodeled BIOS video service AX={incoming.ax:04X}h")
    elif vector == 0x21:
        ah = incoming.ax >> 8
        if ah == 0x2b:
            service, read_names, output_names = "21h/AH=2Bh", ("AH", "CX", "DH", "DL"), ("AL", "CF")
        elif ah == 0x2d:
            service, read_names, output_names = "21h/AH=2Dh", ("AH", "CH", "CL", "DH", "DL"), ("AL", "CF")
        elif ah == 0x3d:
            service, read_names, output_names = "21h/AH=3Dh", ("AL", "DS", "DX"), ("AX", "CF")
        elif ah == 0x3e:
            service, read_names, output_names = "21h/AH=3Eh", ("BX",), ("AX", "CF")
        elif ah == 0x3f:
            service, read_names, output_names = "21h/AH=3Fh", ("BX", "CX", "DS", "DX"), ("AX", "CF")
        elif ah == 0x42:
            service, read_names, output_names = "21h/AH=42h", ("AL", "BX", "CX", "DX"), ("AX", "DX", "CF")
        else:
            raise RuntimeError(f"unmodeled DOS service AH={ah:02X}h")
    else:
        raise RuntimeError(f"unmodeled interrupt {vector:02X}h")
    register_inputs = tuple((name, _service_register(incoming, name)) for name in read_names)
    register_outputs = tuple((name, _service_register(outgoing, name)) for name in output_names)
    return vector, service, register_inputs, memory_read, register_outputs


def event_tuples(dll) -> tuple[list[tuple[int, int]], list[tuple[int, int]], list[tuple]]:
    port_reads = []
    for index in range(dll.libdiff_port_read_count()):
        item = dll.libdiff_port_read_at(index)
        vga_register_read = (0x03b4 <= item.port <= 0x03da or
                             0x03c0 <= item.port <= 0x03df)
        if not vga_register_read or item.port in (0x03ba, 0x03da):
            port_reads.append((item.port, item.value))
    port_writes = []
    for index in range(dll.libdiff_port_write_count()):
        item = dll.libdiff_port_write_at(index)
        port_writes.append((item.port, item.value))
    interrupt_events = []
    for index in range(dll.libdiff_interrupt_count()):
        item = dll.libdiff_interrupt_at(index)
        interrupt_events.append(interrupt_service_tuple(item))
    return port_reads, port_writes, interrupt_events


def vga_snapshot(dll) -> bytes:
    length = 4 * 65536 + 8 + 16 + 32 + 32 + 16 + 6
    buffer = (ctypes.c_uint8 * length)()
    dll.libdiff_vga_copy_state(buffer, length)
    return bytes(buffer)


def ranges_for_difference(left: bytes, right: bytes) -> tuple[int, list[tuple[int, int]]]:
    count = 0
    ranges: list[tuple[int, int]] = []
    start = None
    for address, (a, b) in enumerate(zip(left, right)):
        if a != b:
            count += 1
            if start is None:
                start = address
        elif start is not None:
            if len(ranges) < 8:
                ranges.append((start, address - 1))
            start = None
    if start is not None and len(ranges) < 8:
        ranges.append((start, len(left) - 1))
    return count, ranges


def stack_scratch_exclusion(stack_segment: int, entry_sp: int,
                            parameter_pop_bytes: int) -> list[tuple[int, int]]:
    """Return SS:[0000, entry SP + callee-popped arguments) as linear ranges."""
    end = (entry_sp + parameter_pop_bytes) & 0xffff
    start = ((stack_segment << 4) & 0xfffff)
    if end == 0:
        return []
    first = min(end, MEM_SIZE - start)
    ranges = [(start, start + first)]
    if first < end:
        ranges.append((0, end - first))
    return ranges


def merge_ranges(ranges: list[tuple[int, int]]) -> list[tuple[int, int]]:
    result: list[list[int]] = []
    for start, end in sorted(ranges):
        if start >= end:
            continue
        if result and start <= result[-1][1]:
            result[-1][1] = max(result[-1][1], end)
        else:
            result.append([start, end])
    return [(start, end) for start, end in result]


def masked_memory_difference(left: bytes, right: bytes,
                             excluded: list[tuple[int, int]]) -> tuple[int, list[tuple[int, int]]]:
    if len(left) != MEM_SIZE or len(right) != MEM_SIZE:
        raise ValueError("memory comparison must cover exactly the 1 MB real-mode space")
    excluded = merge_ranges(excluded)
    count = 0
    ranges: list[tuple[int, int]] = []
    diff_start = None
    range_index = 0
    for address, (a, b) in enumerate(zip(left, right)):
        while range_index < len(excluded) and address >= excluded[range_index][1]:
            range_index += 1
        ignored = (range_index < len(excluded) and
                   excluded[range_index][0] <= address < excluded[range_index][1])
        if ignored:
            if diff_start is not None:
                if len(ranges) < 8:
                    ranges.append((diff_start, address - 1))
                diff_start = None
            continue
        if a != b:
            count += 1
            if diff_start is None:
                diff_start = address
        elif diff_start is not None:
            if len(ranges) < 8:
                ranges.append((diff_start, address - 1))
            diff_start = None
    if diff_start is not None and len(ranges) < 8:
        ranges.append((diff_start, MEM_SIZE - 1))
    return count, ranges


def call_frame_bytes(args: bytes) -> bytes:
    return struct.pack("<HH", RETURN_OFF, RETURN_SEG) + args


def seed_c_call_frame(dll_memory, stack_segment: int, stack_top: int, args: bytes) -> int:
    entry_sp = (stack_top - len(args) - 4) & 0xffff
    address = ((stack_segment << 4) + entry_sp) & 0xfffff
    dll_memory[address:address + 4 + len(args)] = call_frame_bytes(args)
    return entry_sp


def genus_code_symbols(build_dir: Path) -> list[tuple[int, int, str]]:
    listing = (build_dir / "GENUS.LST").read_text(encoding="ascii", errors="replace")
    starts: dict[str, int] = {}
    ends: dict[str, int] = {}
    pattern = re.compile(r"^\s*\d+\s+([0-9A-Fa-f]{4})\s+(Pcx\w+DecodeContinuation)\s+(proc far|endp)", re.I)
    for line in listing.splitlines():
        found = pattern.match(line)
        if found:
            address, name, kind = int(found[1], 16), found[2], found[3].lower()
            (starts if kind == "proc far" else ends)[name] = address
    if len(starts) != 7 or set(starts) != set(ends):
        raise RuntimeError(f"GENUS.LST names {len(starts)} decoder continuations, expected 7")
    return [(starts[name], ends[name], name) for name in starts]


def canonicalize_genus_code_pointers(memory: bytes, dll, data_offsets: DataOffsets,
                                     data_segment: int, code_segment: int,
                                     original_symbols: list[tuple[int, int, str]],
                                     is_original: bool) -> tuple[bytes, tuple[str | None, ...]]:
    normalized = bytearray(memory)
    names: list[str | None] = []
    name_ids = {name: index + 1 for index, name in enumerate(sorted(
        {name for _start, _end, name in original_symbols} | {
            "PcxCgaDecodeContinuation", "PcxEgaDecodeContinuation",
            "PcxVga256DecodeContinuation", "PcxHerculesDecodeContinuation",
            "PcxTsengDecodeContinuation", "PcxParadiseDecodeContinuation",
            "PcxVideo7DecodeContinuation"}))}
    for display_index in range(22):
        offset = data_offsets.PcxDisplayTable + display_index * 0x38 + 0x24
        if offset + 4 > 0x10000:
            raise ValueError("PcxDisplayTable decoder pointer exceeds DATA segment")
        physical = (((LOAD_SEG + data_segment) << 4) + offset) & 0xfffff
        pointer_offset, pointer_segment = struct.unpack_from("<HH", memory, physical)
        if pointer_offset == 0 and pointer_segment == 0:
            names.append(None)
            continue
        if is_original:
            expected_segment = code_segment & 0xffff
            name = next((candidate for start, end, candidate in original_symbols
                         if pointer_segment == expected_segment and start <= pointer_offset < end), None)
        else:
            encoded = ((pointer_segment & 0xffff) << 16) | pointer_offset
            raw_name = dll.libdiff_code_name(encoded)
            name = raw_name.decode("ascii") if raw_name else None
        if name not in name_ids:
            raise RuntimeError(
                f"unmapped Genus decoder pointer for display {display_index}: "
                f"{pointer_segment:04X}:{pointer_offset:04X}"
                f" ({'original' if is_original else 'C'})")
        names.append(name)
        struct.pack_into("<HH", normalized, physical, name_ids[name], 0xfffe)
    return bytes(normalized), tuple(names)


CALLED_ROUTINES = (
    "PgSetToolboxVideoMode", "PgSetBiosVideoMode", "PgSetScreenStride",
    "PgPanDisplayAtRetraceStart", "PgPanDisplayAtRetraceEnd",
    "PgSetEgaSplitScanline", "PgWaitVerticalRetrace", "PgSetVgaSplitScanline",
    "PgSetBorderColor", "PgSetPaletteRegister", "PgBlitMasked16x16",
    "PgBlitMasked8x8", "PgSetDrawColor", "PgFillRectangleByteAligned",
    "PgCapturePlanarRectangle", "PgRestorePlanarRectangle",
    "PgBlitMaskedShifted16x16", "PgBlitMaskedShifted8x8", "PgOrShifted16x16",
    "PgInitializeRomFonts", "PgSelectRomFont", "PgBlitOpaque16x16",
    "PgBlitOpaque8x8", "PgCopyCachedVideoTile16x16",
    "PgCopyVideoScreenRegion320x200", "PgCopyStatusBandTemplate",
    "PcxSetDisplayType", "PcxSetGraphicsOrTextMode", "PcxGetDisplayType",
    "PcxGetDisplayDescriptor", "PcxInitializeVideoDescriptors", "PcxDisplayBuffer",
    "PcxInitializeDisplayDispatch", "PcxDisplayFile", "PcxInitializePrinterState",
    "WriteColoredText", "DetectTextVideoAdapter", "GetTextVideoMode",
    "ReadJoystickAxis", "DecryptGameAssetBuffer", "SyncDosClockFromCmos",
    "SetFastGameTimer", "RestoreDefaultTimer",
)


def write_far(memory: bytearray, segment: int, offset: int, payload: bytes) -> None:
    linear = ((segment << 4) + offset) & 0xfffff
    first = min(len(payload), MEM_SIZE - linear)
    memory[linear:linear + first] = payload[:first]
    if first < len(payload):
        memory[:len(payload) - first] = payload[first:]


def configure_platform(dll, initial: bytes, ds: int, ss: int,
                       stack_top: int, data_offsets: DataOffsets,
                       case: RoutineCase) -> ctypes.Array:
    dll.libdiff_reset()
    dll_memory = (ctypes.c_uint8 * MEM_SIZE).in_dll(dll, "pc_mem")
    ctypes.memmove(dll_memory, initial, MEM_SIZE)
    dll.libdiff_set_program(ds, ss, stack_top)
    dll.libdiff_set_data_offsets(ctypes.byref(data_offsets))
    dll.libdiff_set_data_dir(str(ROOT / "assets").encode("ascii"))
    dll.libdiff_set_bios_mode(case.bios_mode)
    dll.libdiff_set_bios_adapter(case.bios_adapter, case.bios_ega_mono)
    for index, value in case.cmos.items():
        dll.libdiff_set_cmos(index, value)
    if case.planar_state is not None:
        set_planar_state(dll, case.planar_state)
    set_port_script(dll, case.port_script)
    return dll_memory


def random_registers(rng: random.Random, initial_if: bool,
                     entry_ax: int | None) -> dict[str, int]:
    values = {name: rng.randrange(0x10000)
              for name in ("ax", "bx", "cx", "dx", "bp", "si", "di", "es")}
    if entry_ax is not None:
        values["ax"] = entry_ax & 0xffff
    # TF would inject INT 1 after every instruction; DF is clear at Pascal call boundaries.
    values["flags"] = 2 | (0x200 if initial_if else 0)
    return values


def invoke_c_sequence(dll, dll_memory, invocations: list[Invocation],
                      ds: int, ss: int, stack_top: int,
                      initial_if: bool, rng: random.Random) -> tuple[list[int | None], list[tuple[int, int]]]:
    results: list[int | None] = []
    stack_ranges: list[tuple[int, int]] = []
    for invocation in invocations:
        entry_sp = seed_c_call_frame(dll_memory, ss, stack_top, invocation.stack_args)
        stack_ranges.extend(stack_scratch_exclusion(ss, entry_sp, invocation.popped))
        dll.libdiff_set_program(ds, ss, entry_sp)
        dll.libdiff_set_interrupts_enabled(int(initial_if))
        results.append(call_c(dll, dll_memory, invocation))
    return results, stack_ranges


def invoke_asm_sequence(dll, emu: Uc, invocations: list[Invocation],
                        publics: dict[str, tuple[int, int]], ss: int,
                        stack_top: int, initial_if: bool,
                        rng: random.Random) -> tuple[list[int], list[dict[str, int]], list[tuple[int, int]]]:
    results: list[int] = []
    details: list[dict[str, int]] = []
    stack_ranges: list[tuple[int, int]] = []
    for invocation in invocations:
        entry = invocation.asm_entry or publics[invocation.name.upper()]
        detail: dict[str, int] = {}
        registers = random_registers(rng, initial_if, invocation.entry_ax)
        detail["entry_ax"] = registers["ax"]
        result = call_original(emu, dll, entry, invocation.stack_args, ss, stack_top,
                              result_detail=detail, initial_registers=registers)
        results.append(result)
        details.append(detail)
        entry_sp = (stack_top - len(invocation.stack_args) - 4) & 0xffff
        stack_ranges.extend(stack_scratch_exclusion(ss, entry_sp, invocation.popped))
    return results, details, stack_ranges


def run_routine_case(dll, module: bytes, publics, segments,
                     data_offsets: DataOffsets, original_symbols,
                     prographx_symbols, cmospit_symbols,
                     sprite_bank: bytes, glyph_bank: bytes,
                     screen_names: tuple[str, ...], case: RoutineCase,
                     rng: random.Random, stack_top: int) -> tuple[bool, str]:
    ds = (LOAD_SEG + segments["DATA"]) & 0xffff
    ss = (LOAD_SEG + segments["STACK"]) & 0xffff
    invocations = case.prelude + [case.target] + case.postlude

    initial = prepare_memory(module, rng)
    for segment, offset, payload in case.writes:
        write_far(initial, segment, offset, payload)
    for name, value in case.code_initial_values.items():
        write_code_static(initial, prographx_symbols[name], value)
    initial_bytes = bytes(initial)

    c_memory = configure_platform(dll, initial_bytes, ds, ss, stack_top,
                                  data_offsets, case)
    initialize_c_code_statics(dll, initial_bytes, prographx_symbols, cmospit_symbols)
    c_results, c_stack_ranges = invoke_c_sequence(
        dll, c_memory, invocations, ds, ss, stack_top, case.initial_if, rng)
    c_memory_bytes = project_c_code_statics(
        dll, bytes(c_memory), prographx_symbols, cmospit_symbols)
    c_vga = vga_snapshot(dll)
    c_reads, c_ports, c_interrupts = event_tuples(dll)
    c_if = bool(dll.libdiff_interrupts_enabled())

    configure_platform(dll, initial_bytes, ds, ss, stack_top, data_offsets, case)
    emu = make_screen_emulator(dll, initial_bytes, segments["DATA"],
                               segments["STACK"], stack_top)
    asm_results, asm_details, asm_stack_ranges = invoke_asm_sequence(
        dll, emu, invocations, publics, ss, stack_top, case.initial_if, rng)
    asm_memory_bytes = bytes(emu.mem_read(0, MEM_SIZE))
    asm_vga = vga_snapshot(dll)
    asm_reads, asm_ports, asm_interrupts = event_tuples(dll)
    asm_if = bool(emu.reg_read(UC_X86_REG_EFLAGS) & 0x200)
    c_if = bool(dll.libdiff_interrupts_enabled()) if not invocations else c_if

    normalize_code_pointers = any(invocation.name in {
        "PcxInitializeVideoDescriptors", "PcxInitializeDisplayDispatch",
        "PcxDisplayBuffer", "PcxDisplayFile",
    } for invocation in invocations)
    if normalize_code_pointers:
        code_segment = (LOAD_SEG + segments["PCXGENUS"]) & 0xffff
        asm_memory_bytes, asm_code_names = canonicalize_genus_code_pointers(
            asm_memory_bytes, dll, data_offsets, segments["DATA"], code_segment,
            original_symbols, True)
        c_memory_bytes, c_code_names = canonicalize_genus_code_pointers(
            c_memory_bytes, dll, data_offsets, segments["DATA"], code_segment,
            original_symbols, False)
    else:
        asm_code_names = c_code_names = ()

    memory_count, memory_ranges = masked_memory_difference(
        asm_memory_bytes, c_memory_bytes, c_stack_ranges + asm_stack_ranges)
    vga_count, vga_ranges = ranges_for_difference(asm_vga, c_vga)
    result_errors = []
    for index, invocation in enumerate(invocations):
        if not result_matches(invocation, c_results[index], asm_results[index],
                              asm_details[index]):
            result_errors.append(invocation.name)
    equal = (not result_errors and memory_count == 0 and vga_count == 0 and
             asm_reads == c_reads and asm_ports == c_ports and
             asm_interrupts == c_interrupts and asm_code_names == c_code_names and
             asm_if == c_if)
    if equal:
        return True, ""

    problems = []
    if result_errors:
        problems.append("results=" + ",".join(result_errors))
    if memory_count:
        first = ",".join(f"{lo:05X}-{hi:05X}" for lo, hi in memory_ranges[:4])
        values = ",".join(
            f"{asm_memory_bytes[lo:hi + 1].hex()}/{c_memory_bytes[lo:hi + 1].hex()}"
            for lo, hi in memory_ranges[:4])
        problems.append(f"memory={memory_count}@{first}[{values}]")
    if vga_count:
        problems.append(f"vga={vga_count}")
        if vga_ranges:
            problems.append("vga_ranges=" + ",".join(f"{lo:X}-{hi:X}" for lo, hi in vga_ranges[:2]))
    if asm_reads != c_reads:
        i = next((i for i, pair in enumerate(zip(asm_reads, c_reads)) if pair[0] != pair[1]),
                 min(len(asm_reads), len(c_reads)))
        pair = (asm_reads[i] if i < len(asm_reads) else None,
                c_reads[i] if i < len(c_reads) else None)
        problems.append(f"reads={len(asm_reads)}/{len(c_reads)} first={i}:{pair}")
    if asm_ports != c_ports:
        i = next((i for i, pair in enumerate(zip(asm_ports, c_ports)) if pair[0] != pair[1]),
                 min(len(asm_ports), len(c_ports)))
        problems.append(f"ports={len(asm_ports)}/{len(c_ports)} first={i}")
    if asm_interrupts != c_interrupts:
        i = next((i for i, pair in enumerate(zip(asm_interrupts, c_interrupts)) if pair[0] != pair[1]),
                 min(len(asm_interrupts), len(c_interrupts)))
        pair = (asm_interrupts[i] if i < len(asm_interrupts) else None,
                c_interrupts[i] if i < len(c_interrupts) else None)
        problems.append(f"ints={len(asm_interrupts)}/{len(c_interrupts)} first={i}:{pair}")
    if asm_code_names != c_code_names:
        problems.append(f"code_names={asm_code_names}/{c_code_names}")
    if asm_if != c_if:
        problems.append(f"IF={int(asm_if)}/{int(c_if)}")
    if case.target.name in ("PgBlitMaskedShifted16x16", "PgOrShifted16x16"):
        source_pointer = case.target.c_args[0]
        source_linear = ((source_pointer.segment << 4) + source_pointer.offset) & 0xfffff
        c_state = (ctypes.c_uint16 * len(PROGRAPX_STATE))()
        dll.libdiff_progrphx_get_state(c_state)
        problems.append(f"source={source_pointer.segment:04X}:{source_pointer.offset:04X} "
                        f"tail={initial_bytes[source_linear + 150:source_linear + 160].hex()} "
                        f"c_mask={c_state[17]:02X}")
    if case.target.name in ("PgSetScreenStride", "PgSetDrawColor", "PgBlitOpaque8x8"):
        c_state = (ctypes.c_uint16 * len(PROGRAPX_STATE))()
        dll.libdiff_progrphx_get_state(c_state)
        draw_page_symbol = prographx_symbols["PgDrawPage"]
        asm_draw_page = read_code_static(asm_memory_bytes, draw_page_symbol)
        c_draw_page = c_state[1]
        problems.append(f"drawpage=initial:{read_code_static(initial_bytes, draw_page_symbol)} "
                        f"asm:{asm_draw_page} c:{c_draw_page} stride:{c_state[0]} "
                        f"entry_ax={asm_details[invocations.index(case.target)]['entry_ax']:04X}")
    return False, " ".join(problems)


def test_routine_matrix(random_cases: int, realistic_cases: int, seed: int,
                        only: tuple[str, ...] = ()) -> int:
    exe_path, map_path = get_oracle()
    module, _initial_ss, _stack_top = load_mz(exe_path)
    publics, segments = read_map(map_path)
    data_offsets = bind_data_offsets(publics)
    original_symbols = genus_code_symbols(exe_path.parent)
    prographx_base = (publics["PGSETTOOLBOXVIDEOMODE"][1] -
                      local_proc_offset(exe_path.parent, "PROGRAPX.LST", "PgSetToolboxVideoMode")) & 0xffff
    cmospit_base = (publics["SYNCDOSCLOCKFROMCMOS"][1] -
                    local_proc_offset(exe_path.parent, "CMOSPIT.LST", "SyncDosClockFromCmos")) & 0xffff
    prographx_symbols = parse_code_static_symbols(
        exe_path.parent, "PROGRAPX.LST", PROGRAPX_STATE,
        segments["PROGRPHX"], prographx_base)
    cmospit_symbols = parse_code_static_symbols(
        exe_path.parent, "CMOSPIT.LST", CMOSPIT_STATE,
        segments["SAMMAIN"], cmospit_base)
    dll = bind_dll(build_dll())
    configure_c_abi(dll)
    dll.libdiff_set_data_dir(str(ROOT / "assets").encode("ascii"))
    asset_rng = random.Random(seed ^ 0xACCE55)
    sprite_bank = decode_real_asset_bank(
        dll, module, publics, segments["DATA"], segments["STACK"], _stack_top,
        (ROOT / "assets" / "SAM101.GFX").read_bytes()[:8064], asset_rng.randrange(1 << 30))
    glyph_bank = decode_real_asset_bank(
        dll, module, publics, segments["DATA"], segments["STACK"], _stack_top,
        (ROOT / "assets" / "SAM102.GFX").read_bytes()[:2048], asset_rng.randrange(1 << 30))
    if len(sprite_bank) != 8064 or len(glyph_bank) != 2048:
        raise RuntimeError(f"unexpected decoded sprite banks {len(sprite_bank)} / {len(glyph_bank)}")
    screen_names = tuple(path.name for path in sorted((ROOT / "assets").glob("SAM*.APO")) +
                         sorted((ROOT / "assets").glob("SAM*.CRD")) +
                         sorted((ROOT / "assets").glob("SAM*.TTL")) +
                         sorted((ROOT / "assets").glob("SAM*.END")))
    # Keep the same explicit episode variants used by the full PCX file suite.
    screen_names = ("SAM1.APO", "SAM1.CRD", "SAM1.TTL", "SAM1.END", "SAM2.APO",
                    "SAM2.CRD", "SAM2.TTL", "SAM2.END", "SAM3.APO", "SAM3.CRD",
                    "SAM3.TTL", "SAM3A.END", "SAM3B.END")
    routine_names = only or CALLED_ROUTINES
    unknown = [name for name in routine_names if name not in CALLED_ROUTINES]
    if unknown:
        raise ValueError("unknown called routine: " + ", ".join(unknown))
    missing = [name for name in routine_names if name.upper() not in publics]
    if missing:
        raise KeyError("called routine missing in SAM.MAP: " + ", ".join(missing))
    total_failures = 0
    counts: dict[str, tuple[int, int, int, int, str]] = {}
    rng = random.Random(seed)
    for name in routine_names:
        random_passed = 0
        realistic_passed = 0
        first_failure = ""
        for case_index in range(random_cases + realistic_cases):
            realistic = case_index >= random_cases
            local_index = case_index - random_cases if realistic else case_index
            case_rng = random.Random(rng.getrandbits(64))
            case = make_routine_case(
                name, case_rng, local_index, realistic, ds_segment=(LOAD_SEG + segments["DATA"]) & 0xffff,
                data_offsets=data_offsets, sprite_bank=sprite_bank, glyph_bank=glyph_bank,
                screen_names=screen_names)
            try:
                good, detail = run_routine_case(
                    dll, module, publics, segments, data_offsets, original_symbols,
                    prographx_symbols, cmospit_symbols, sprite_bank, glyph_bank,
                    screen_names, case, case_rng, _stack_top)
            except (RuntimeError, ValueError, OSError, KeyError, OverflowError) as error:
                good, detail = False, f"harness_error={error}"
            if good:
                if realistic:
                    realistic_passed += 1
                else:
                    random_passed += 1
            if not good and not first_failure:
                first_failure = f"case={case_index} {detail}"
                if "harness_error=" in detail:
                    break
        passed = random_passed + realistic_passed
        failures = random_cases + realistic_cases - passed
        total_failures += failures
        counts[name] = (random_passed, realistic_passed, random_cases,
                        realistic_cases, first_failure)
        result = "PASS" if failures == 0 else "FAIL"
        print(f"{name}: random={random_passed}/{random_cases} "
              f"realistic={realistic_passed}/{realistic_cases} result={result}" +
              (f" first={first_failure}" if first_failure else ""), flush=True)
    print(f"routine_matrix={len(routine_names)} routines failures={total_failures} "
          f"seed=0x{seed:X} oracle={map_path}")
    return 0 if total_failures == 0 else 1


def test_screen_files(selected_name: str | None = None) -> int:
    exe_path, map_path = get_oracle()
    module, initial_ss, stack_top = load_mz(exe_path)
    publics, segments = read_map(map_path)
    data_segment = segments["DATA"]
    data_offsets = bind_data_offsets(publics)
    original_symbol_ranges = genus_code_symbols(exe_path.parent)
    code_seg = (LOAD_SEG + segments["PCXGENUS"]) & 0xffff
    original_code_names = original_symbol_ranges
    dll = bind_dll(build_dll())
    dll.PcxInitializeVideoDescriptors.argtypes = []
    dll.PcxSetDisplayType.argtypes = [ctypes.c_uint16]
    dll.PcxSetDisplayType.restype = ctypes.c_int16
    dll.PcxSetGraphicsOrTextMode.argtypes = [ctypes.c_uint16]
    dll.PcxSetGraphicsOrTextMode.restype = ctypes.c_int16
    dll.PcxDisplayFile.argtypes = [ctypes.c_uint32, ctypes.c_uint16, ctypes.c_uint16, ctypes.c_uint16]
    dll.PcxDisplayFile.restype = ctypes.c_int16
    dll.PcxDisplayBuffer.argtypes = [ctypes.c_uint32, ctypes.c_uint16, ctypes.c_uint16,
                                    ctypes.c_uint16, ctypes.c_uint16]
    dll.PcxDisplayBuffer.restype = ctypes.c_int16
    dll.libdiff_set_data_dir(str(ROOT / "assets").encode("ascii"))
    names = ("SAM1.APO", "SAM1.CRD", "SAM1.TTL", "SAM1.END", "SAM2.APO",
             "SAM2.CRD", "SAM2.TTL", "SAM2.END", "SAM3.APO", "SAM3.CRD",
             "SAM3.TTL", "SAM3A.END", "SAM3B.END")
    if selected_name is not None:
        if selected_name not in names:
            raise ValueError(f"unknown game screen file: {selected_name}")
        names = (selected_name,)
    failures = 0
    rng = random.Random(0x51A6)
    for name in names:
        initial = prepare_memory(module, rng)
        screen_bytes = (ROOT / "assets" / name).read_bytes()
        ds = (LOAD_SEG + data_segment) & 0xFFFF
        string_offset = 0x7000
        string_linear = ((ds << 4) + string_offset) & 0xFFFFF
        name_bytes = name.encode("ascii")
        initial[string_linear:string_linear + len(name_bytes) + 1] = bytes((len(name_bytes),)) + name_bytes

        dll.libdiff_reset()
        dll_memory = (ctypes.c_uint8 * MEM_SIZE).in_dll(dll, "pc_mem")
        ctypes.memmove(dll_memory, bytes(initial), MEM_SIZE)
        ss = (LOAD_SEG + initial_ss) & 0xFFFF
        dll.libdiff_set_program(ds, ss, stack_top)
        dll.libdiff_set_data_offsets(ctypes.byref(data_offsets))
        dll.libdiff_set_bios_adapter(3, 0)
        c_stack_frames = []
        c_stack_frames.append((ss, seed_c_call_frame(dll_memory, ss, stack_top, b""), 0))
        dll.PcxInitializeVideoDescriptors()
        set_display_args = struct.pack("<H", 2)
        c_stack_frames.append((ss, seed_c_call_frame(dll_memory, ss, stack_top, set_display_args), 2))
        c_selected = dll.PcxSetDisplayType(2)
        mode_args = struct.pack("<H", 1)
        c_stack_frames.append((ss, seed_c_call_frame(dll_memory, ss, stack_top, mode_args), 2))
        c_mode = dll.PcxSetGraphicsOrTextMode(1)
        file_args = struct.pack("<HHHHH", 0, 0, 1, string_offset, ds)
        c_stack_frames.append((ss, seed_c_call_frame(dll_memory, ss, stack_top, file_args), 10))
        dll.libdiff_set_program(ds, ss, c_stack_frames[-1][1])
        c_result = dll.PcxDisplayFile((ds << 16) | string_offset, 1, 0, 0)
        c_memory = bytes(dll_memory)
        c_port_reads, c_ports, c_interrupts = event_tuples(dll)
        c_vga = vga_snapshot(dll)

        dll.libdiff_reset()
        ctypes.memmove(dll_memory, bytes(initial), MEM_SIZE)
        dll.libdiff_set_program(ds, ss, stack_top)
        dll.libdiff_set_bios_adapter(3, 0)
        emu = make_screen_emulator(dll, bytes(initial), data_segment, initial_ss, stack_top)
        call_original(emu, dll, publics["PCXINITIALIZEVIDEODESCRIPTORS"],
                      b"", ss, stack_top)
        asm_selected = call_original(emu, dll, publics["PCXSETDISPLAYTYPE"],
                                     struct.pack("<H", 2), ss, stack_top)
        asm_mode = call_original(emu, dll, publics["PCXSETGRAPHICSORTEXTMODE"],
                                 struct.pack("<H", 1), ss, stack_top)
        file_args = struct.pack("<HHHHH", 0, 0, 1, string_offset, ds)
        asm_result = call_original(emu, dll, publics["PCXDISPLAYFILE"],
                                   file_args, ss, stack_top)
        asm_memory = bytes(emu.mem_read(0, MEM_SIZE))
        asm_port_reads, asm_ports, asm_interrupts = event_tuples(dll)
        asm_vga = vga_snapshot(dll)
        asm_memory, asm_code_names = canonicalize_genus_code_pointers(
            asm_memory, dll, data_offsets, data_segment, code_seg,
            original_code_names, True)
        c_memory, c_code_names = canonicalize_genus_code_pointers(
            c_memory, dll, data_offsets, data_segment, code_seg,
            original_code_names, False)
        stack_exclusions = []
        for frame_ss, entry_sp, popped in c_stack_frames:
            stack_exclusions.extend(stack_scratch_exclusion(frame_ss, entry_sp, popped))
        memory_count, memory_ranges = masked_memory_difference(
            asm_memory, c_memory, stack_exclusions)
        vga_count, vga_ranges = ranges_for_difference(asm_vga, c_vga)
        status_ok = (c_selected == 0 and asm_selected == 0 and c_mode == 0 and asm_mode == 0 and
                     c_result == ctypes.c_int16(asm_result).value)
        vga_ok = vga_count == 0
        ports_ok = asm_ports == c_ports and asm_port_reads == c_port_reads
        interrupts_ok = asm_interrupts == c_interrupts
        code_names_ok = asm_code_names == c_code_names
        passed = (status_ok and vga_ok and ports_ok and interrupts_ok and
                  code_names_ok and memory_count == 0)
        failures += int(not passed)
        interrupt_state = ("PASS" if interrupts_ok else
                           f"DIFF({len(asm_interrupts)} calls; first reg mismatch at "
                           f"{next((i for i, pair in enumerate(zip(asm_interrupts, c_interrupts)) if pair[0] != pair[1]), min(len(asm_interrupts), len(c_interrupts)))})")
        print(f"{name}: status={'PASS' if status_ok else 'FAIL'} vga={'PASS' if vga_ok else f'DIFF({vga_count})'} "
              f"ports={'PASS' if ports_ok else 'DIFF'} interrupts={interrupt_state} "
              f"code_names={'PASS' if code_names_ok else 'DIFF'} "
              f"memory={'PASS' if memory_count == 0 else f'DIFF({memory_count})'}")
        if name == "SAM1.APO" and memory_ranges:
            print("  first_memory_ranges=" + ", ".join(f"0x{lo:05X}-0x{hi:05X}" for lo, hi in memory_ranges))
            for lo, hi in memory_ranges[:2]:
                print(f"  memory[{lo:05X}:{hi + 1:05X}] asm={asm_memory[lo:hi + 1].hex()} c={c_memory[lo:hi + 1].hex()}")
        if name == "SAM1.APO" and not interrupts_ok:
            first = next((i for i, pair in enumerate(zip(asm_interrupts, c_interrupts))
                          if pair[0] != pair[1]), None)
            if first is not None:
                print(f"  interrupt[{first}] asm={asm_interrupts[first]} c={c_interrupts[first]}")

        buffer_initial = bytearray(initial)
        buffer_segment, buffer_offset = 0x5000, 0x0100
        buffer_linear = ((buffer_segment << 4) + buffer_offset) & 0xfffff
        buffer_initial[buffer_linear:buffer_linear + len(screen_bytes)] = screen_bytes
        buffer_initial = bytes(buffer_initial)

        dll.libdiff_reset()
        ctypes.memmove(dll_memory, buffer_initial, MEM_SIZE)
        dll.libdiff_set_program(ds, ss, stack_top)
        dll.libdiff_set_data_offsets(ctypes.byref(data_offsets))
        dll.libdiff_set_bios_adapter(3, 0)
        c_buffer_frames = []
        c_buffer_frames.append((ss, seed_c_call_frame(dll_memory, ss, stack_top, b""), 0))
        dll.PcxInitializeVideoDescriptors()
        c_buffer_frames.append((ss, seed_c_call_frame(dll_memory, ss, stack_top, set_display_args), 2))
        c_buffer_selected = dll.PcxSetDisplayType(2)
        c_buffer_frames.append((ss, seed_c_call_frame(dll_memory, ss, stack_top, mode_args), 2))
        c_buffer_mode = dll.PcxSetGraphicsOrTextMode(1)
        buffer_args = struct.pack("<HHHHHH", 0, 0, 1, len(screen_bytes),
                                  buffer_offset, buffer_segment)
        c_buffer_frames.append((ss, seed_c_call_frame(dll_memory, ss, stack_top, buffer_args), 12))
        c_buffer_result = dll.PcxDisplayBuffer(
            (buffer_segment << 16) | buffer_offset, len(screen_bytes), 1, 0, 0)
        c_buffer_memory = bytes(dll_memory)
        c_buffer_reads, c_buffer_ports, c_buffer_interrupts = event_tuples(dll)
        c_buffer_vga = vga_snapshot(dll)

        dll.libdiff_reset()
        ctypes.memmove(dll_memory, buffer_initial, MEM_SIZE)
        dll.libdiff_set_program(ds, ss, stack_top)
        dll.libdiff_set_bios_adapter(3, 0)
        buffer_emu = make_screen_emulator(
            dll, buffer_initial, data_segment, initial_ss, stack_top)
        call_original(buffer_emu, dll, publics["PCXINITIALIZEVIDEODESCRIPTORS"],
                      b"", ss, stack_top)
        asm_buffer_selected = call_original(
            buffer_emu, dll, publics["PCXSETDISPLAYTYPE"], set_display_args, ss, stack_top)
        asm_buffer_mode = call_original(
            buffer_emu, dll, publics["PCXSETGRAPHICSORTEXTMODE"], mode_args, ss, stack_top)
        asm_buffer_result = call_original(
            buffer_emu, dll, publics["PCXDISPLAYBUFFER"], buffer_args, ss, stack_top)
        asm_buffer_memory = bytes(buffer_emu.mem_read(0, MEM_SIZE))
        asm_buffer_reads, asm_buffer_ports, asm_buffer_interrupts = event_tuples(dll)
        asm_buffer_vga = vga_snapshot(dll)
        asm_buffer_memory, asm_buffer_code_names = canonicalize_genus_code_pointers(
            asm_buffer_memory, dll, data_offsets, data_segment, code_seg,
            original_code_names, True)
        c_buffer_memory, c_buffer_code_names = canonicalize_genus_code_pointers(
            c_buffer_memory, dll, data_offsets, data_segment, code_seg,
            original_code_names, False)
        buffer_stack_exclusions = []
        for frame_ss, entry_sp, popped in c_buffer_frames:
            buffer_stack_exclusions.extend(
                stack_scratch_exclusion(frame_ss, entry_sp, popped))
        buffer_memory_count, _ = masked_memory_difference(
            asm_buffer_memory, c_buffer_memory, buffer_stack_exclusions)
        buffer_vga_count, _ = ranges_for_difference(asm_buffer_vga, c_buffer_vga)
        buffer_ok = (
            c_buffer_selected == asm_buffer_selected == 0 and
            c_buffer_mode == asm_buffer_mode == 0 and
            ctypes.c_int16(c_buffer_result).value == ctypes.c_int16(asm_buffer_result).value and
            buffer_memory_count == 0 and buffer_vga_count == 0 and
            asm_buffer_reads == c_buffer_reads and asm_buffer_ports == c_buffer_ports and
            asm_buffer_interrupts == c_buffer_interrupts and
            asm_buffer_code_names == c_buffer_code_names)
        failures += int(not buffer_ok)
        print(f"{name} PcxDisplayBuffer: {'PASS' if buffer_ok else 'FAIL'} "
              f"result={asm_buffer_result} ega={'PASS' if buffer_vga_count == 0 else 'DIFF'} "
              f"memory={'PASS' if buffer_memory_count == 0 else f'DIFF({buffer_memory_count})'}")
    print(f"screen_files={len(names)} failures={failures} oracle={map_path}")
    return 0 if failures == 0 else 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--screens", action="store_true",
                        help="differentially decode all game screen files through PcxDisplayFile")
    parser.add_argument("--screen-file", help="run one named game screen file")
    parser.add_argument("--matrix", action="store_true",
                        help="run every game-called assembly entrypoint against its C rewrite")
    parser.add_argument("--only", action="append", default=[], metavar="ROUTINE",
                        help="limit --matrix to a named entrypoint; repeatable for focused debugging")
    parser.add_argument("--realistic-cases", type=int, default=16,
                        help="number of asset/edge cases per routine in --matrix")
    parser.add_argument("--routine", choices=("DecryptGameAssetBuffer",), default="DecryptGameAssetBuffer")
    parser.add_argument("--cases", type=int, default=200)
    parser.add_argument("--seed", type=lambda value: int(value, 0), default=0x5A17)
    args = parser.parse_args()
    if args.cases < 1 or args.realistic_cases < 1:
        parser.error("--cases and --realistic-cases must be positive")
    try:
        if args.screens or args.screen_file:
            return test_screen_files(args.screen_file)
        if args.matrix:
            return test_routine_matrix(args.cases, args.realistic_cases, args.seed,
                                       tuple(args.only))
        exe, map_path = get_oracle()
        module, initial_ss, stack_top = load_mz(exe)
        publics, segments = read_map(map_path)
        entry = publics[args.routine.upper()]
        dll = bind_dll(build_dll())
        rng = random.Random(args.seed)
        payload_bad = 0
        memory_bad = 0
        memory_bytes = 0
        ranges: list[tuple[int, int]] = []
        for _case in range(args.cases):
            good, different, current_ranges = run_decode_case(
                dll, module, segments["DATA"], initial_ss, stack_top, entry, rng)
            payload_bad += int(not good)
            memory_bad += int(different != 0)
            memory_bytes += different
            if not ranges and current_ranges:
                ranges = current_ranges
        realistic_counts = (0, 1, 28, 84, 2048)
        for byte_count in realistic_counts:
            good, different, current_ranges = run_decode_case(
                dll, module, segments["DATA"], initial_ss, stack_top, entry, rng,
                forced_count=byte_count)
            payload_bad += int(not good)
            memory_bad += int(different != 0)
            memory_bytes += different
            if not ranges and current_ranges:
                ranges = current_ranges
        total_cases = args.cases + len(realistic_counts)
        print(f"routine={args.routine} random_cases={args.cases} realistic_cases={len(realistic_counts)} seed=0x{args.seed:X}")
        print(f"payload_and_platform={('PASS' if payload_bad == 0 else 'FAIL')} cases={total_cases} mismatches={payload_bad}")
        print(f"all_memory={('PASS' if memory_bad == 0 else 'DIFF')} differing_cases={memory_bad}/{total_cases} differing_bytes={memory_bytes}")
        if ranges:
            print("first_memory_ranges=" + ", ".join(f"0x{lo:05X}-0x{hi:05X}" for lo, hi in ranges))
        print(f"oracle={map_path}")
        return 0 if payload_bad == 0 and memory_bad == 0 else 1
    except (FileNotFoundError, KeyError, OSError, ValueError, subprocess.CalledProcessError, RuntimeError) as error:
        print(f"libdiff: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
