#!/usr/bin/env python3
"""Find direct far calls to the AX-dependent ProGraphx routines in verify MZs."""

from __future__ import annotations

import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
import tools.common  # Adds the repository's pinned Capstone package.
from capstone import Cs, CS_ARCH_X86, CS_MODE_16

LOAD_SEG = 0x1000
ROUTINES = {
    "PGBLITMASKED8X8": "PixelRow",
    "PGFILLRECTANGLEBYTEALIGNED": "HeightRows",
    "PGBLITOPAQUE8X8": "PixelRow",
}


def map_symbols(path: Path):
    publics: dict[str, tuple[int, int]] = {}
    code_segments: list[tuple[int, int, str]] = []
    in_publics = False
    for line in path.read_text(encoding="ascii", errors="replace").splitlines():
        if "Publics by Value" in line:
            in_publics = True
            continue
        if in_publics:
            found = re.match(r"\s*([0-9A-Fa-f]{4}):([0-9A-Fa-f]{4})\s+(\S+)", line)
            if found:
                publics[found[3].upper()] = (int(found[1], 16), int(found[2], 16))
        found = re.match(
            r"\s*([0-9A-Fa-f]+)H\s+[0-9A-Fa-f]+H\s+([0-9A-Fa-f]+)H\s+(\S+)\s+(CODE|DATA|STACK)",
            line,
        )
        if found and found[4].upper() == "CODE":
            code_segments.append((int(found[1], 16), int(found[2], 16), found[3]))
    return publics, code_segments


def relocated_module(path: Path) -> bytes:
    image = path.read_bytes()
    if image[:2] != b"MZ":
        raise ValueError(f"not an MZ image: {path}")
    reloc_count = struct.unpack_from("<H", image, 6)[0]
    header_bytes = struct.unpack_from("<H", image, 8)[0] * 16
    reloc_table = struct.unpack_from("<H", image, 24)[0]
    module = bytearray(image[header_bytes:])
    for index in range(reloc_count):
        offset, segment = struct.unpack_from("<HH", image, reloc_table + index * 4)
        location = segment * 16 + offset
        value = struct.unpack_from("<H", module, location)[0]
        struct.pack_into("<H", module, location, (value + LOAD_SEG) & 0xFFFF)
    return bytes(module)


def latest_build(episode: str) -> Path:
    builds = sorted((ROOT / "build" / "verify").glob(f"{episode}-*/SAM.EXE"),
                    key=lambda path: path.stat().st_mtime, reverse=True)
    if not builds:
        raise FileNotFoundError(f"run python tools/verify.py --episodes {episode} --keep first")
    return builds[0]


def previous_ax_write(instructions, index: int):
    from capstone.x86_const import X86_REG_AX

    for instruction in reversed(instructions[:index]):
        try:
            _reads, writes = instruction.regs_access()
        except Exception:
            continue
        if X86_REG_AX in writes:
            return instruction
    return None


def collect(episode: str):
    exe = latest_build(episode)
    map_path = exe.with_name("SAM.MAP")
    publics, segments = map_symbols(map_path)
    targets = {publics[name]: name for name in ROUTINES}
    module = relocated_module(exe)
    decoder = Cs(CS_ARCH_X86, CS_MODE_16)
    decoder.detail = True
    found = {name: [] for name in ROUTINES}
    for start, length, segment_name in segments:
        instructions = list(decoder.disasm(module[start:start + length], 0))
        for index, instruction in enumerate(instructions):
            if len(instruction.bytes) != 5 or instruction.bytes[0] != 0x9A:
                continue
            target_offset, target_segment = struct.unpack_from("<HH", instruction.bytes, 1)
            target = ((target_segment - LOAD_SEG) & 0xFFFF, target_offset)
            name = targets.get(target)
            if name is None:
                continue
            if index == 0 or instructions[index - 1].mnemonic != "push" or instructions[index - 1].op_str != "ax":
                raise RuntimeError(f"{episode} {name} call {segment_name}:{instruction.address:04X} is not preceded by PUSH AX")
            definition = previous_ax_write(instructions, index - 1)
            if definition is None:
                raise RuntimeError(f"{episode} {name} call {segment_name}:{instruction.address:04X} has no decoded AX definition")
            found[name].append((segment_name, instruction.address,
                                definition.address, definition.mnemonic, definition.op_str,
                                target_segment, target_offset))
    for name, entries in found.items():
        if not entries:
            raise RuntimeError(f"{episode}: no direct far calls found for {name}")
    return map_path, found


def main() -> int:
    for episode in ("sam1", "sam2", "sam3"):
        map_path, found = collect(episode)
        print(f"{episode} ({map_path})")
        for name, argument in ROUTINES.items():
            entries = found[name]
            targets = ", ".join(sorted({f"{seg:04X}:{off:04X}" for _, _, _, _, _, seg, off in entries}))
            print(f"  {name}: {len(entries)} sites; AX is {argument}; target {targets}")
            sites = "; ".join(
                f"{segment}:{site:04X} PUSH-AX@{site - 1:04X} "
                f"AX@{definition:04X}={mnemonic} {operands}"
                for segment, site, definition, mnemonic, operands, _, _ in entries
            )
            print(f"    {sites}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
