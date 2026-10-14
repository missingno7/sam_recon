"""Routine census of the three oracle images.

    python tools/census.py            write build/census/<ep>.json and print a summary
    python tools/census.py --gaps     also list bytes no routine accounts for

Turbo Pascal layout (measured in the oracles, see evidence/compiler-rules.json):
code segments are paragraph aligned and every segment base is a relocation
target, so the set of relocated words partitions the image into the program
segment, one segment per unit, the data segment (DS) and the stack.  Routines
are found by recursive descent from the entry point, the unit-initialisation
far calls, every relocated far call `9A off seg`, every relocated far pointer
built as `mov reg,off ... seg` and every near call inside a segment.  Turbo
Pascal emits a routine's string literals immediately *before* its code, so a
routine's extent is [end of the previous routine's code, end of its own code).

Nothing here is a proof: the census is the coordinate system the atlas,
packets and proofs use.  Unaccounted bytes are reported, never guessed.
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, EPISODES, atomic_json, load_json, LAYOUT  # noqa: E402
import mz  # noqa: E402
import oracle  # noqa: E402

import capstone  # noqa: E402

OUT = BUILD / "census"
_MD = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
_MD.detail = False

COND = {0x70 + i for i in range(16)} | {0xE0, 0xE1, 0xE2, 0xE3}


def segments(img: bytes, relocs, entry_cs: int, ss: int) -> list:
    lin = mz.linear(relocs)
    vals = sorted({struct.unpack_from("<H", img, a)[0] for a in lin} | {entry_cs})
    vals = [v for v in vals if v * 16 < len(img)]
    out = []
    for i, s in enumerate(vals):
        end = vals[i + 1] * 16 if i + 1 < len(vals) else len(img)
        out.append({"para": s, "start": s * 16, "end": end})
    return out


def data_segment(img: bytes, segs: list) -> int:
    """System's init begins `mov dx,DATA / mov ds,dx`; the data segment is
    the last relocated paragraph, and the System unit is the segment whose
    first instructions load it."""
    for s in segs:
        b = img[s["start"]:s["start"] + 5]
        if b[0] == 0xBA and b[3:5] == b"\x8e\xda":
            return struct.unpack_from("<H", b, 1)[0]
    raise RuntimeError("System init (mov dx,DATA; mov ds,dx) not found")


def far_targets(img: bytes, relocs) -> list:
    """(seg, off, kind, site) for relocated far calls/jumps and far pointers."""
    out = []
    for a in mz.linear(relocs):
        seg = struct.unpack_from("<H", img, a)[0]
        if a >= 3 and img[a - 3] in (0x9A, 0xEA):
            out.append((seg, struct.unpack_from("<H", img, a - 2)[0], "call" if img[a - 3] == 0x9A else "jmp", a - 3))
    return out


class Walker:
    """Recursive descent over one code segment."""

    def __init__(self, img: bytes, seg: dict):
        self.img, self.seg = img, seg
        self.code = {}          # offset -> length (instruction starts, segment relative)
        self.calls = set()      # near-call targets (segment relative)
        self.owner = {}         # instruction offset -> routine entry
        self.far_out = {}       # routine entry -> set of (seg, off) far call targets
        self.near_out = {}      # routine entry -> set of near call targets
        self.indirect = {}      # routine entry -> count of indirect jumps

    def walk(self, entry: int) -> None:
        base, size = self.seg["start"], self.seg["end"] - self.seg["start"]
        todo, seen = [entry], set()
        self.far_out.setdefault(entry, set())
        self.near_out.setdefault(entry, set())
        while todo:
            off = todo.pop()
            while 0 <= off < size and off not in seen:
                seen.add(off)
                if off in self.owner and self.owner[off] != entry:
                    break       # flowed into code already owned (shared tail); stop
                ins = next(_MD.disasm(self.img[base + off:base + min(size, off + 16)], off), None)
                if ins is None:
                    break
                self.code[off] = ins.size
                self.owner.setdefault(off, entry)
                op = ins.bytes[0]
                nxt = off + ins.size
                if op == 0xE8:
                    t = (nxt + struct.unpack_from("<h", ins.bytes, 1)[0]) & 0xFFFF
                    self.calls.add(t)
                    self.near_out[entry].add(t)
                elif op == 0x9A:
                    o, s = struct.unpack_from("<HH", ins.bytes, 1)
                    self.far_out[entry].add((s, o))
                elif op in (0xEB, 0xE9):
                    t = (nxt + (struct.unpack_from("<b", ins.bytes, 1)[0] if op == 0xEB
                                else struct.unpack_from("<h", ins.bytes, 1)[0])) & 0xFFFF
                    todo.append(t)
                    break
                elif op in COND:
                    todo.append((nxt + struct.unpack_from("<b", ins.bytes, 1)[0]) & 0xFFFF)
                elif op == 0x0F and len(ins.bytes) > 1 and 0x80 <= ins.bytes[1] <= 0x8F:
                    todo.append((nxt + struct.unpack_from("<h", ins.bytes, 2)[0]) & 0xFFFF)
                elif op in (0xC3, 0xC2, 0xCB, 0xCA, 0xCF, 0xEA):
                    break
                elif op == 0xFF and len(ins.bytes) > 1 and ((ins.bytes[1] >> 3) & 7) in (4, 5):
                    self.indirect[entry] = self.indirect.get(entry, 0) + 1
                    break
                elif op == 0xCD and ins.bytes[1] == 0x20:
                    break
                off = nxt


def census(ep: str) -> dict:
    img, relocs = oracle.load_image(ep)
    lk = load_json(LAYOUT / "oracle.lock.json")["episodes"][ep]["unpacked"]
    segs = segments(img, relocs, lk["cs"], lk["ss"])
    ds = data_segment(img, segs)
    code_segs = [s for s in segs if s["para"] < ds]
    by_para = {s["para"]: s for s in code_segs}
    walkers = {s["para"]: Walker(img, s) for s in code_segs}

    # Entry chain: far calls to unit initialisers, then the program body.
    entry_off = lk["ip"]
    inits = []
    p = lk["cs"] * 16 + entry_off
    while img[p] == 0x9A:
        o, s = struct.unpack_from("<HH", img, p + 1)
        inits.append((s, o))
        p += 5
    seeds = {(lk["cs"], entry_off)} | set(inits)
    farlist = far_targets(img, relocs)
    seeds |= {(s, o) for s, o, _, _ in farlist if s in by_para}
    # Far procedure pointers (@Proc): the relocated segment word of a code segment
    # paired with an offset immediate in the forms TP emits.
    for a in set(mz.linear(relocs)):
        seg = struct.unpack_from("<H", img, a)[0]
        if seg not in by_para:
            continue
        w = lambda q: struct.unpack_from("<H", img, q)[0]  # noqa: E731
        if 0xB8 <= img[a - 1] <= 0xBF and 0xB8 <= img[a - 4] <= 0xBF:
            seeds.add((seg, w(a - 3)))                      # mov r,off ; mov r,seg
        if img[a - 1] == 0xB8 and img[a + 2] == 0x50 and img[a + 3] == 0xB8:
            seeds.add((seg, w(a + 4)))                      # mov ax,seg ; push ax ; mov ax,off
        if img[a - 4] == 0xC7 and img[a - 10] == 0xC7 and img[a - 3] == img[a - 9]:
            seeds.add((seg, w(a - 6)))                      # mov [m],off ; mov [m+2],seg
        if img[a - 3] == 0xC7 and img[a - 8] == 0xC7 and img[a - 7] == img[a - 2]                 and (img[a - 6] + 2) & 0xFF == img[a - 1]:
            seeds.add((seg, w(a - 5)))                      # mov [r+d8],off ; mov [r+d8+2],seg
    # Iterate to a fixpoint: near-call targets become routines too.
    pending = sorted(seeds)
    entries = {s: set() for s in by_para}
    while pending:
        s, o = pending.pop()
        if s not in walkers or o in entries[s]:
            continue
        if o >= by_para[s]["end"] - by_para[s]["start"]:
            continue
        entries[s].add(o)
        w = walkers[s]
        w.walk(o)
        pending += [(s, t) for t in w.near_out.get(o, ())]
        pending += [t for t in w.far_out.get(o, ()) if t[0] in walkers]

    segdocs = []
    for s in code_segs:
        w = walkers[s["para"]]
        size = s["end"] - s["start"]
        ents = sorted(entries[s["para"]])
        # code end of each routine = max instruction end owned by it
        ends = {}
        for off, ln in w.code.items():
            e = w.owner[off]
            ends[e] = max(ends.get(e, 0), off + ln)
        routines = []
        prev_end = 0
        for i, e in enumerate(ents):
            nxt = ents[i + 1] if i + 1 < len(ents) else size
            code_end = min(max(ends.get(e, e), e), nxt)
            routines.append({
                "entry": e, "start": prev_end, "code_end": code_end, "prefix": e - prev_end,
                "far_calls": sorted("%04X:%04X" % t for t in w.far_out.get(e, ())),
                "near_calls": sorted(w.near_out.get(e, ())),
                "indirect": w.indirect.get(e, 0),
            })
            prev_end = max(prev_end, code_end)
        tail = size - prev_end
        covered = sum(ln for ln in w.code.values())
        segdocs.append({"para": s["para"], "start": s["start"], "size": size, "routines": routines,
                        "tail": tail, "code_bytes": covered,
                        "init": next((o for ss, o in inits if ss == s["para"]), None)})
    return {"episode": ep, "image_size": len(img), "ds_para": ds, "entry": [lk["cs"], entry_off],
            "inits": [list(t) for t in inits], "segments": segdocs}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--gaps", action="store_true")
    a = ap.parse_args()
    for ep in EPISODES:
        doc = census(ep)
        atomic_json(OUT / f"{ep}.json", doc)
        print(f"{ep}: DS={doc['ds_para']:04X}, {len(doc['segments'])} code segments, "
              f"{sum(len(s['routines']) for s in doc['segments'])} routines")
        for s in doc["segments"]:
            gap = s["size"] - s["code_bytes"]
            print(f"  {s['para']:04X} size {s['size']:5X} routines {len(s['routines']):3d} "
                  f"code {s['code_bytes']:5X} non-code {gap:5X} tail {s['tail']:4X}"
                  + (f" init {s['init']:04X}" if s["init"] is not None else ""))
            if a.gaps:
                for r in s["routines"]:
                    if r["prefix"] > 0:
                        print(f"      {r['start']:04X}..{r['entry']:04X} prefix before {r['entry']:04X}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
