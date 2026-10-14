"""Minimal MZ header / relocation table reader."""
from __future__ import annotations

import struct
from dataclasses import dataclass


@dataclass(frozen=True)
class MZ:
    header: dict
    relocs: tuple          # ((seg, off), ...) in table order
    image: bytes           # load module
    overlay: bytes         # bytes past the declared file size


FIELDS = ("signature", "last_page_bytes", "pages", "reloc_count", "header_paras",
          "minalloc", "maxalloc", "ss", "sp", "checksum", "ip", "cs", "reloc_offset",
          "overlay_number")


def parse(data: bytes) -> MZ:
    if data[:2] not in (b"MZ", b"ZM"):
        raise ValueError("not an MZ executable")
    h = dict(zip(FIELDS, struct.unpack_from("<14H", data, 0)))
    size = h["pages"] * 512 - ((512 - h["last_page_bytes"]) % 512 if h["last_page_bytes"] else 0)
    start = h["header_paras"] * 16
    relocs = tuple((seg, off) for off, seg in (
        struct.unpack_from("<HH", data, h["reloc_offset"] + 4 * i) for i in range(h["reloc_count"])))
    return MZ(header=h, relocs=relocs, image=data[start:size], overlay=data[size:])


def linear(relocs) -> list:
    return [(seg << 4) + off for seg, off in relocs]
