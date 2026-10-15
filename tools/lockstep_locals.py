"""Apply the documented zero-local compatibility rule to reference execution.

Only diagnostics-selected local objects are written. Fail closed on unknown
symbols, unsupported prologues, out-of-frame slots, or missing BP references.
No game routine names or offsets occur in this implementation.
"""
import re
from capstone import Cs, CS_ARCH_X86, CS_MODE_16
from capstone.x86_const import X86_OP_MEM, X86_REG_BP

RULE = ('diagnostic-zero-locals: at original routine entry zero exactly the '
        'diagnostics-listed local objects, using translator BP offsets verified '
        'against the TP5 prologue and BP references; sound/PIT/history stay exact')


def policies(diagnostics, routines, image, load_linear):
    md = Cs(CS_ARCH_X86, CS_MODE_16)
    md.detail = True
    selected = {}
    for note in diagnostics['possible_uninitialized_reads']:
        name = re.sub(r'^s[123]_', '', note['routine']).upper()
        selected.setdefault(name, set()).add((note['routine'], note['name']))
    byname = {name.upper(): address for address, name in routines.items()}
    boundaries = sorted(routines)
    result = {}
    for name, locals_ in sorted(selected.items()):
        address = byname[name]
        start = address - load_linear
        stop = min((a for a in boundaries if a > address), default=load_linear+len(image)) - load_linear
        ins = list(md.disasm(image[start:stop], address))
        if len(ins) < 3 or [(i.mnemonic, i.op_str) for i in ins[:2]] != [('push', 'bp'), ('mov', 'bp, sp')]:
            raise ValueError(f'{name}: unsupported TP5 frame prologue')
        allocation = ins[2]
        if allocation.mnemonic != 'sub' or allocation.op_str.split(',')[0] != 'sp':
            raise ValueError(f'{name}: missing TP5 local allocation')
        size = allocation.operands[1].imm
        slots = []
        for routine, local in sorted(locals_):
            frame = diagnostics['routine_frames'][routine]
            slot = dict(frame['locals'][local], name=local)
            off, width = slot['bp_offset'], slot['size']
            if frame['declared_bytes'] > size or not -size <= off < off+width <= 0:
                raise ValueError(f'{name}.{local}: translator local outside original frame')
            refs = [i for i in ins for op in i.operands if op.type == X86_OP_MEM
                    and op.mem.base == X86_REG_BP and not op.mem.index
                    and off <= op.mem.disp < off+width]
            if not refs:
                raise ValueError(f'{name}.{local}: no original BP reference proves the slot')
            slot['references'] = [{'address':hex(i.address), 'instruction':i.mnemonic+' '+i.op_str} for i in refs[:4]]
            slots.append(slot)
        result[name] = {'entry_linear':address, 'bp_from_entry_sp':-2,
                        'allocated_bytes':size, 'prologue': [i.mnemonic+' '+i.op_str for i in ins[:3]],
                        'locals':slots}
    return result
