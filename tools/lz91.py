"""Independent LZEXE 0.91 (``LZ91``) unpacker.

Pure function of the packed bytes: no execution of the packed program, no
mutation of inputs.  The algorithm follows the published LZEXE 0.91 decoder
(bit-stream of little-endian 16-bit words, LSB first, refilled immediately
after the 16th bit is consumed) and the 0x158-offset compressed relocation
table.  A second, independent implementation (UNLZEXE 0.5 run under the
pinned MS-DOS Player) is used by ``tools/oracle.py --crosscheck``.
"""
from __future__ import annotations

import struct
from dataclasses import dataclass


class LZ91Error(ValueError):
    pass


@dataclass(frozen=True)
class Unpacked:
    image: bytes              # load module (what DOS copies to PSP+0x10)
    relocs: tuple             # ((seg, off), ...) in original table order
    cs: int
    ip: int
    ss: int
    sp: int
    min_extra_paras: int      # e_minalloc of the unpacked program (UNLZEXE rule)
    max_extra_paras: int
    packed_header: dict


class _Bits:
    __slots__ = ("data", "pos", "buf", "left")

    def __init__(self, data: bytes, pos: int):
        self.data = data
        self.pos = pos
        self.buf = self.word()
        self.left = 16

    def byte(self) -> int:
        if self.pos >= len(self.data):
            raise LZ91Error("truncated LZ91 stream (byte)")
        v = self.data[self.pos]
        self.pos += 1
        return v

    def word(self) -> int:
        if self.pos + 2 > len(self.data):
            raise LZ91Error("truncated LZ91 stream (word)")
        v = self.data[self.pos] | (self.data[self.pos + 1] << 8)
        self.pos += 2
        return v

    def bit(self) -> int:
        b = self.buf & 1
        self.left -= 1
        if self.left == 0:
            self.buf = self.word()
            self.left = 16
        else:
            self.buf >>= 1
        return b


def _decode(data: bytes, start: int, limit: int) -> bytes:
    bits = _Bits(data, start)
    out = bytearray()
    while True:
        if bits.bit():
            out.append(bits.byte())
            continue
        if not bits.bit():
            length = ((bits.bit() << 1) | bits.bit()) + 2
            span = bits.byte() - 0x100
        else:
            lo = bits.byte()
            hi = bits.byte()
            span = (lo | ((hi & 0xF8) << 5) | 0xE000) - 0x10000
            length = (hi & 7) + 2
            if length == 2:
                n = bits.byte()
                if n == 0:
                    break            # end of compressed load module
                if n == 1:
                    continue         # segment change marker
                length = n + 1
        src = len(out) + span
        if src < 0:
            raise LZ91Error(f"back-reference before start at output {len(out):#x}")
        for i in range(length):
            out.append(out[src + i])
        if len(out) > limit:
            raise LZ91Error("decoded image exceeds declared size")
    if bits.pos > limit + start + 0x10000:
        raise LZ91Error("stream overrun")
    return bytes(out)


def _relocs(data: bytes, pos: int) -> tuple:
    off = 0
    seg = 0
    out = []
    while True:
        if pos >= len(data):
            raise LZ91Error("truncated relocation table")
        span = data[pos]
        pos += 1
        if span == 0:
            span = struct.unpack_from("<H", data, pos)[0]
            pos += 2
            if span == 0:
                seg = (seg + 0x0FFF) & 0xFFFF
                continue
            if span == 1:
                break
        off += span
        seg = (seg + ((off & ~0x0F) >> 4)) & 0xFFFF
        off &= 0x0F
        out.append((seg, off))
    return tuple(out)


def unpack(raw: bytes) -> Unpacked:
    if raw[:2] != b"MZ" or raw[0x1C:0x20] != b"LZ91":
        raise LZ91Error("not an MZ/LZ91 executable")
    h = struct.unpack_from("<14H", raw, 0)
    hdr_paras, minalloc, maxalloc = h[4], h[5], h[6]
    e_ip, e_cs = h[10], h[11]
    if e_ip != 0x0E:
        raise LZ91Error(f"unexpected LZ91 entry IP {e_ip:#x}")
    loader = (hdr_paras + e_cs) << 4
    inf = struct.unpack_from("<8H", raw, loader)
    ip, cs, sp, ss, comp_paras, inc_paras, dec_size, _chk = inf
    image = _decode(raw, hdr_paras << 4, (comp_paras + inc_paras) << 4)
    relocs = _relocs(raw, loader + 0x158)
    grow = inc_paras + ((dec_size + 15) >> 4) + 9
    min_extra = (minalloc - grow) & 0xFFFF
    # LZEXE 0.91 adds the same growth to e_maxalloc unless it is 0xFFFF
    # (observed: repacking reproduces the original header only with this rule).
    max_extra = maxalloc if maxalloc == 0xFFFF else (maxalloc - grow) & 0xFFFF
    return Unpacked(
        image=image, relocs=relocs, cs=cs, ip=ip, ss=ss, sp=sp,
        min_extra_paras=min_extra, max_extra_paras=max_extra,
        packed_header={
            "hdr_paras": hdr_paras, "minalloc": minalloc, "maxalloc": maxalloc,
            "loader_cs": e_cs, "comp_paras": comp_paras, "inc_paras": inc_paras,
            "decompressor_size": dec_size, "checksum": _chk,
        },
    )


def build_mz(u: Unpacked) -> bytes:
    """Canonical unpacked MZ (UNLZEXE-compatible layout: 0x1C header, relocs,
    pad to 512-byte header)."""
    reloc_bytes = b"".join(struct.pack("<HH", off, seg) for seg, off in u.relocs)
    hdr_size = 0x1C + len(reloc_bytes)
    hdr_size += (-hdr_size) % 0x200
    total = hdr_size + len(u.image)
    hdr = struct.pack(
        "<14H", 0x5A4D, total % 512, (total + 511) // 512, len(u.relocs),
        hdr_size // 16, u.min_extra_paras, u.max_extra_paras, u.ss, u.sp, 0,
        u.ip, u.cs, 0x1C, 0)
    blob = hdr + reloc_bytes
    blob += b"\0" * (hdr_size - len(blob))
    return blob + u.image
