"""16-bit x86 decoding helpers shared by census, atlas and compare.

Capstone is used for decoding only.  Two known capstone quirks are handled
here instead of trusted: far immediates (9A/EA) are decoded from the opcode
bytes, and 98/99 are reported as cbw/cwd.
"""
from __future__ import annotations

import struct
from dataclasses import dataclass

import capstone
from capstone import x86_const as X

_MD = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
_MD.detail = True

JCC = {"jo", "jno", "jb", "jae", "je", "jne", "jbe", "ja", "js", "jns", "jp", "jnp", "jl", "jge",
       "jle", "jg", "jcxz", "loop", "loope", "loopne"}
ENDS = {"ret", "retf", "iret"}


@dataclass
class Insn:
    off: int            # offset within the segment frame
    size: int
    raw: bytes
    mnem: str
    ops: str
    disp_off: int
    disp_size: int
    imm_off: int
    imm_size: int
    target: int | None = None        # near branch/call target (frame offset)
    far: tuple | None = None         # (seg, off) for 9A/EA
    mem_disp: int | None = None      # absolute DS-relative displacement, if any
    mem_seg: str | None = None       # segment override register name
    mem_base: bool = False           # memory operand uses a base/index register
    mem_bp: bool = False             # ... and that register is BP (stack frame)
    mem_size: int = 0                # operand size in bytes


def decode(code: bytes, off: int, frame_off: int = 0) -> Insn | None:
    """Decode one instruction at code[off]; addresses are frame offsets
    (frame_off is the frame offset of code[0])."""
    try:
        i = next(_MD.disasm(code[off:off + 16], frame_off + off, 1))
    except StopIteration:
        return None
    raw = bytes(i.bytes)
    mnem = i.mnemonic
    if raw[0] == 0x98:
        mnem = "cbw"
    elif raw[0] == 0x99:
        mnem = "cwd"
    ins = Insn(frame_off + off, i.size, raw, mnem, i.op_str, i.disp_offset, i.disp_size,
               i.imm_offset, i.imm_size)
    if raw[0] in (0x9A, 0xEA) and len(raw) == 5:
        o, s = struct.unpack_from("<HH", raw, 1)
        ins.far = (s, o)
        ins.mnem = "lcall" if raw[0] == 0x9A else "ljmp"
        return ins
    if mnem in JCC or mnem in ("jmp", "call"):
        if i.operands and i.operands[0].type == X.X86_OP_IMM:
            ins.target = i.operands[0].imm & 0xFFFF
    for op in i.operands:
        if op.type == X.X86_OP_MEM:
            seg = i.reg_name(op.mem.segment) if op.mem.segment else None
            ins.mem_seg = seg
            ins.mem_base = bool(op.mem.base or op.mem.index)
            ins.mem_bp = op.mem.base == X.X86_REG_BP
            ins.mem_size = op.size
            if i.disp_size:
                ins.mem_disp = op.mem.disp & 0xFFFF
    return ins


def is_end(ins: Insn) -> bool:
    return ins.mnem in ENDS or ins.mnem in ("jmp", "ljmp")


def shape(ins: Insn) -> bytes:
    """Instruction bytes with displacement and immediate fields blanked: the
    'instruction shape' used for cross-episode comparison."""
    b = bytearray(ins.raw)
    if ins.far:
        b[1:5] = b"\0\0\0\0"
        return bytes(b)
    for o, n in ((ins.disp_off, ins.disp_size), (ins.imm_off, ins.imm_size)):
        if n:
            b[o:o + n] = b"\0" * n
    if ins.target is not None and ins.mnem not in ("jmp", "call") and ins.mnem in JCC:
        b[-1] = 0
    elif ins.target is not None:
        n = len(b) - (2 if b[0] in (0xE8, 0xE9) else 1)
        b[n:] = b"\0" * (len(b) - n)
    return bytes(b)
