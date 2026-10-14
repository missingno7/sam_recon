"""Strict routine comparison: original extent vs the candidate's harness build.

Equality is byte equality over the whole extent (string-literal pool, nested
routines, code) with exactly these exceptions, each of which must *bind*:

  * relocated segment words: both sides relocated at the same offset, and the
    segments are the same unit (harness H = the target's unit, U1..U9 = u1..u9,
    CRT/DOS/SYSTEM = crt/dos/sys);
  * the offset word of a far call/jump (9A/EA) and of a far pointer built as
    `mov r,off ; mov r,seg`: same routine;
  * near calls (E8) leaving the extent: same routine.

A routine identity is its logical id for game code (original: atlas; candidate:
map publics, which name program-level routines and unit interface routines),
and a content signature for Borland runtime routines (both images contain the
same TP 5.0 code at different offsets).  Bound references are checked even when
their bytes happen to be equal.  DS operands are compared raw: the harness
reproduces the original data layout (tools/harness.py).
"""
from __future__ import annotations

import struct
import sys
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, EVIDENCE, load_json  # noqa: E402
import mz  # noqa: E402
import oracle  # noqa: E402

import capstone  # noqa: E402

_MD = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
LIBRARY = ("crt", "dos", "sys")
MAP_UNITS = {"CRT": "crt", "DOS": "dos", "SYSTEM": "sys"}


@dataclass
class Image:
    img: bytes
    relocs: set                     # linear offsets of relocated words
    seg_unit: dict                  # paragraph -> unit name
    names: dict                     # (unit, offset) -> routine id


@dataclass
class Result:
    status: str                     # EQUAL | DIFF | LAYOUT | COMPILE | MISSING
    episode: str
    function: str
    size: int = 0
    diffs: list = field(default_factory=list)
    first_diff: int | None = None
    bound: int = 0
    note: str = ""

    def short(self) -> str:
        if self.status == "EQUAL":
            return f"{self.episode}: EQUAL ({self.size} B, {self.bound} bound references)"
        if self.status == "DIFF":
            return (f"{self.episode}: DIFF at +{self.first_diff:#x} ({len(self.diffs)} differences "
                    f"in {self.size} B) {self.diffs[0]}")
        return f"{self.episode}: {self.status} {self.note}"


def original(ep: str) -> Image:
    img, relocs = oracle.load_image(ep)
    atlas = load_json(EVIDENCE / "atlas.json")
    cen = load_json(BUILD / "census" / f"{ep}.json")
    seg_unit = {s["para"]: atlas["units"][k] for k, s in enumerate(cen["segments"])}
    seg_unit[cen["ds_para"]] = "DATA"
    names = {}
    for lid, r in atlas["routines"].items():
        e = r["episodes"].get(ep)
        if e:
            names[(e["unit"], e["entry"])] = lid
    return Image(img, set(mz.linear(relocs)), seg_unit, names)


def candidate(exe: bytes, m, h_unit: str, stub_names: dict | None = None,
              init_names: dict | None = None) -> Image:
    """`h_unit`: the unit the harness program H stands for (the target's unit for a
    routine, `p` for the main body).  `stub_names`: (para, off) -> name for stubs the
    publics omit; `init_names`: unit -> logical id of that unit's init block."""
    hdr = mz.parse(exe)
    img = hdr.image
    seg_unit = {}
    for s in m.segments:
        n = s.name.upper()
        if s.cls.upper() == "DATA":
            seg_unit[s.para] = "DATA"
        elif n == "H":
            seg_unit[s.para] = h_unit
        elif n in MAP_UNITS:
            seg_unit[s.para] = MAP_UNITS[n]
        elif s.cls.upper() == "CODE":
            seg_unit.setdefault(s.para, n.lower())
    names = {}
    for name, (para, off) in m.publics.items():
        u = seg_unit.get(para)
        if u and u != "DATA":
            names[(u, off)] = name.lower()
    for (para, off), name in (stub_names or {}).items():
        names[(seg_unit.get(para), off)] = name
    for para, off in m.inits:
        u = seg_unit.get(para)
        if u in (init_names or {}):
            names[(u, off)] = init_names[u]
    return Image(img, set(mz.linear(hdr.relocs)), seg_unit, names)


def _library_signature(im: Image, lin: int, n: int = 40) -> tuple:
    out = []
    for ins in _MD.disasm(im.img[lin:lin + n], lin):
        b = bytearray(ins.bytes)
        for k in range(len(b)):
            if ins.address + k in im.relocs or ins.address + k - 1 in im.relocs:
                b[k] = 0
        if b[0] in (0xE8, 0xE9, 0x9A, 0xEA):
            b[1:] = bytes(len(b) - 1)
        out.append(bytes(b))
        if b[0] in (0xC3, 0xC2, 0xCB, 0xCA, 0xCF):
            break
    return tuple(out)


def identity(im: Image, seg_base: dict, unit: str, off: int) -> str:
    if unit in LIBRARY:
        base = seg_base.get(unit)
        if base is None:
            return f"{unit}:?"
        return f"{unit}:" + __import__("hashlib").sha256(
            b"|".join(_library_signature(im, base + off))).hexdigest()[:12]
    return im.names.get((unit, off), f"{unit}:{off:04X}")


def _bases(im: Image) -> dict:
    return {u: p * 16 for p, u in im.seg_unit.items()}


def references(im: Image, lin_start: int, lin_end: int, entries: list, seg_unit_self: str) -> dict:
    """{offset in extent: (kind, size, identity_or_unit)} for bound operands of the
    code reached from `entries` (linear addresses)."""
    out = {}
    bases = _bases(im)
    self_base = bases[seg_unit_self]
    seen = set()
    for e in entries:
        todo = [e]
        while todo:
            a = todo.pop()
            while lin_start <= a < lin_end and a not in seen:
                seen.add(a)
                ins = next(_MD.disasm(im.img[a:a + 16], a), None)
                if ins is None:
                    break
                b, n = ins.bytes, ins.size
                rel = a - lin_start
                for k in range(n - 1):
                    if a + k in im.relocs:
                        seg = struct.unpack_from("<H", im.img, a + k)[0]
                        out[rel + k] = ("seg", 2, im.seg_unit.get(seg, f"seg{seg:04X}"))
                if b[0] in (0x9A, 0xEA):
                    off, seg = struct.unpack_from("<HH", b, 1)
                    u = im.seg_unit.get(seg, f"seg{seg:04X}")
                    out[rel + 1] = ("far", 2, identity(im, bases, u, off))
                elif b[0] == 0xE8:
                    t = (a + n + struct.unpack_from("<h", b, 1)[0] - self_base) & 0xFFFF
                    if not (lin_start <= self_base + t < lin_end):
                        out[rel + 1] = ("near", 2, identity(im, bases, seg_unit_self, t))
                    else:
                        todo.append(self_base + t)
                elif 0xB8 <= b[0] <= 0xBF and a + n + 1 in im.relocs and 0xB8 <= im.img[a + n] <= 0xBF:
                    seg = struct.unpack_from("<H", im.img, a + n + 1)[0]
                    u = im.seg_unit.get(seg)
                    if u and u != "DATA":
                        out[rel + 1] = ("ptr", 2, identity(im, bases, u, struct.unpack_from("<H", b, 1)[0]))
                if b[0] in (0xEB, 0xE9) or (0x70 <= b[0] <= 0x7F) or b[0] in (0xE0, 0xE1, 0xE2, 0xE3):
                    if b[0] == 0xE9:
                        t = a + n + struct.unpack_from("<h", b, 1)[0]
                    else:
                        t = a + n + struct.unpack_from("<b", b, 1)[0]
                    todo.append(t)
                    if b[0] in (0xEB, 0xE9):
                        break
                if b[0] in (0xC3, 0xC2, 0xCB, 0xCA, 0xCF):
                    break
                if b[0] == 0xFF and ((b[1] >> 3) & 7) in (4, 5):
                    break
                a += n
    return out


def describe(im: Image, lin: int) -> str:
    ins = next(_MD.disasm(im.img[lin:lin + 16], lin), None)
    return f"{ins.bytes.hex()} {ins.mnemonic} {ins.op_str}" if ins else im.img[lin:lin + 4].hex()


def compare(ep: str, function: str, orig: Image, o_start: int, o_entries: list, o_end: int,
            o_unit: str, cand: Image, c_start: int, c_entries: list) -> Result:
    size = o_end - o_start
    res = Result("EQUAL", ep, function, size)
    c_end = c_start + size
    ro = references(orig, o_start, o_end, o_entries, o_unit)
    rc = references(cand, c_start, c_end, c_entries, o_unit)
    masked = set()
    for off, (kind, n, ident) in ro.items():
        masked |= set(range(off, off + n))
        other = rc.get(off)
        if other is None or other[0] != kind or other[2] != ident:
            res.diffs.append(f"+{off:#06x} {kind} {ident} vs {other[2] if other else 'unbound'}")
        else:
            res.bound += 1
    for off, (kind, n, ident) in rc.items():
        if off not in ro:
            masked |= set(range(off, off + n))
            res.diffs.append(f"+{off:#06x} candidate {kind} {ident} where the original has none")
    for i in range(size):
        if i in masked:
            continue
        if orig.img[o_start + i] != cand.img[c_start + i]:
            res.diffs.append(f"+{i:#06x} {describe(orig, o_start + i)}  |  {describe(cand, c_start + i)}")
            break_at = i
            # one entry per instruction-sized burst
            j = i + 1
            while j < size and j not in masked and orig.img[o_start + j] != cand.img[c_start + j]:
                masked.add(j)
                j += 1
    # relocation sets must agree exactly inside the extent
    rel_o = {a - o_start for a in orig.relocs if o_start <= a < o_end}
    rel_c = {a - c_start for a in cand.relocs if c_start <= a < c_end}
    for off in sorted(rel_o ^ rel_c):
        res.diffs.append(f"+{off:#06x} relocation only in {'original' if off in rel_o else 'candidate'}")
    if res.diffs:
        res.status = "DIFF"
        res.diffs.sort(key=lambda s: int(s.split()[0][1:], 16))
        res.first_diff = int(res.diffs[0].split()[0][1:], 16)
    return res
