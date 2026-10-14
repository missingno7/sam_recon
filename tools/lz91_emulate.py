"""Independent oracle cross-check: execute the original LZEXE stub.

The packed SAM?.EXE is loaded the way DOS loads it (PSP, load segment,
registers) into a unicorn 16-bit x86 emulator, and the program's *own*
decompressor runs until it transfers control to the unpacked entry point.
Nothing from tools/lz91.py is used to produce the result.

Running twice at two different load segments yields the relocation set
independently: exactly the words that differ by the load-segment delta.
The relocation table order is not observable this way (and not observable
at all: LZ91 stores relocations as ascending deltas).
"""
from __future__ import annotations

import struct

import unicorn
from unicorn import x86_const as X

MEM = 0x110000


class EmulationError(RuntimeError):
    pass


def run_stub(raw: bytes, psp: int) -> dict:
    h = struct.unpack_from("<14H", raw, 0)
    last, pages, nrel, hdr, minalloc = h[1], h[2], h[3], h[4], h[5]
    ss, sp, ip, cs = h[7], h[8], h[10], h[11]
    if nrel:
        raise EmulationError("packed file unexpectedly has relocations")
    size = pages * 512 - ((512 - last) % 512 if last else 0)
    module = raw[hdr * 16:size]
    load = psp + 0x10
    # The stub's info block holds the original entry it will jump to.
    info = struct.unpack_from("<4H", raw, (hdr + cs) * 16)
    target = ((load + info[1]) << 4) + info[0]

    uc = unicorn.Uc(unicorn.UC_ARCH_X86, unicorn.UC_MODE_16)
    uc.mem_map(0, MEM)
    # PSP: INT 20h at 0, top-of-memory segment at 2.
    uc.mem_write(psp * 16, b"\xcd\x20" + struct.pack("<H", 0xA000))
    uc.mem_write(load * 16, module)
    regs = {X.UC_X86_REG_CS: load + cs, X.UC_X86_REG_IP: ip, X.UC_X86_REG_SS: load + ss,
            X.UC_X86_REG_SP: sp, X.UC_X86_REG_DS: psp, X.UC_X86_REG_ES: psp,
            X.UC_X86_REG_AX: 0, X.UC_X86_REG_BX: 0, X.UC_X86_REG_CX: 0, X.UC_X86_REG_DX: 0,
            X.UC_X86_REG_SI: 0, X.UC_X86_REG_DI: 0, X.UC_X86_REG_BP: 0}
    for r, v in regs.items():
        uc.reg_write(r, v)
    interrupts = []

    def on_intr(u, intno, _):
        interrupts.append(intno)
        u.emu_stop()

    uc.hook_add(unicorn.UC_HOOK_INTR, on_intr)
    begin = ((load + cs) << 4) + ip
    uc.emu_start(begin, target, timeout=60_000_000, count=50_000_000)
    pc = (uc.reg_read(X.UC_X86_REG_CS) << 4) + uc.reg_read(X.UC_X86_REG_IP)
    if interrupts or pc != target:
        raise EmulationError(f"stub stopped at {pc:#x} (interrupts {interrupts}), expected {target:#x}")
    return {"load": load, "memory": bytes(uc.mem_read(load * 16, MEM - load * 16 - 0x100)),
            "cs": uc.reg_read(X.UC_X86_REG_CS) - load, "ip": uc.reg_read(X.UC_X86_REG_IP),
            "ss": uc.reg_read(X.UC_X86_REG_SS) - load, "sp": uc.reg_read(X.UC_X86_REG_SP)}


def crosscheck(raw: bytes, image: bytes, relocs) -> dict:
    """Compare tools/lz91 output (`image`, `relocs`) against two stub runs."""
    a = run_stub(raw, 0x0800)
    b = run_stub(raw, 0x1234)
    delta = b["load"] - a["load"]
    n = len(image)
    ma, mb = a["memory"][:n], b["memory"][:n]
    diff = [i for i in range(n) if ma[i] != mb[i]]
    sites = set()
    i = 0
    while i < len(diff):
        p = diff[i]
        # a relocated word may differ only in its low byte, only in its high
        # byte, or in both; resolve against both memory images.
        cand = [q for q in (p, p - 1) if 0 <= q and q + 2 <= n and
                (struct.unpack_from("<H", mb, q)[0] - struct.unpack_from("<H", ma, q)[0]) & 0xFFFF == delta]
        if not cand:
            raise EmulationError(f"byte {p:#x} differs between load segments but is not a relocated word")
        sites.add(cand[0])
        i += 1
        while i < len(diff) and diff[i] <= cand[0] + 1:
            i += 1
    ours = {(s << 4) + o for s, o in relocs}
    # A relocation whose stored value happens to make both loads agree cannot
    # exist (delta != 0), but a site whose word is relocated twice could; we
    # require exact set equality.
    unrelocated = bytearray(ma)
    for q in ours:
        v = (struct.unpack_from("<H", unrelocated, q)[0] - a["load"]) & 0xFFFF
        struct.pack_into("<H", unrelocated, q, v)
    return {
        "relocation_set_equal": sites == ours,
        "image_equal": bytes(unrelocated) == image,
        "registers": {k: a[k] for k in ("cs", "ip", "ss", "sp")},
        "derived_reloc_count": len(sites),
    }
