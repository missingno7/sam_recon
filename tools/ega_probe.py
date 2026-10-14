"""Execute the ORIGINAL SAM1 adapter probe with independently captured BIOS state.
Original executable/RAM bytes remain test inputs; none are embedded in port sources.
"""
import json
from pathlib import Path
import re
import struct
import sys
from pas2c_paths import ROOT,WORK
sys.dont_write_bytecode=True
sys.path.insert(0,str(ROOT/'tools'))
import common
import oracle
from pas2c import memory_layout
from unicorn import Uc,UC_ARCH_X86,UC_MODE_16,UC_HOOK_INTR,UC_HOOK_CODE,UC_HOOK_MEM_READ
from unicorn.x86_const import *

_,original,_=oracle.describe('sam1')
reference=WORK/'build/reference/sam1/SAM.MAP'
psp,ds,ss,sp,heap,top=memory_layout(reference)
text=reference.read_text(encoding='latin1')
m=re.search(r'^\s+([0-9A-F]{4}):([0-9A-F]{4})\s+DETECTGAMEVIDEOADAPTER\s*$',text,re.M)
assert m
load=psp+16;cs=load+int(m[1],16);ip=int(m[2],16)
image=bytearray(original.image)
for seg,off in original.relocs:
    linear=seg*16+off
    value=struct.unpack_from('<H',image,linear)[0]
    struct.pack_into('<H',image,linear,(value+load)&65535)
replies=json.loads((WORK/'build/bios-reference/replies.json').read_text())
results={}
for label,machine,override in (('ega','ega',None),('ega_nonzero_low_byte','ega',1),('vgaonly','vgaonly',None)):
    captured=WORK/'build/bios-reference'/machine
    pc=Uc(UC_ARCH_X86,UC_MODE_16);pc.mem_map(0,0x110000)
    pc.mem_write(0,(captured/'LOWRAM.BIN').read_bytes())
    pc.mem_write(load*16,bytes(image))
    if override is not None:
        target_off,target_seg,_=replies[machine]['INDIRECT']
        pc.mem_write(target_seg*16+target_off,bytes([override]))
    vectors={}
    for n in (0x10,0x11):
        off,seg=struct.unpack('<HH',bytes(pc.mem_read(n*4,4)))
        vectors[seg*16+off]=n
        # Dos.Intr invokes the IVT entry through PUSHF/CALL FAR, rather than an
        # INT opcode. The BIOS boundary is a captured-reply shim followed by IRET.
        pc.mem_write(seg*16+off,b'\xcf')
    stop=0x70000
    pc.mem_write(ss*16+sp-4,struct.pack('<HH',0,stop>>4))
    for reg,value in ((UC_X86_REG_CS,cs),(UC_X86_REG_IP,ip),(UC_X86_REG_DS,ds),
                      (UC_X86_REG_SS,ss),(UC_X86_REG_SP,sp-4),(UC_X86_REG_EFLAGS,0x202)):
        pc.reg_write(reg,value)
    reads=[];ints=[];last=[];transfer=[];reached=[]
    def interrupt(uc,n,unused):
        ax=uc.reg_read(UC_X86_REG_AX);ints.append({'vector':n,'ax':ax})
        if n==0x10 and ax==0x1b00:
            response=replies[machine]['STATE'];uc.reg_write(UC_X86_REG_AX,response[0])
            if (response[0]&255)==0x1b:
                address=uc.reg_read(UC_X86_REG_ES)*16+uc.reg_read(UC_X86_REG_DI)
                uc.mem_write(address,(captured/'STATE.BIN').read_bytes())
        elif n==0x11:uc.reg_write(UC_X86_REG_AX,replies[machine]['EQUIP'][0])
        else:raise RuntimeError(f'unexpected interrupt {n:02x} AX={ax:04x}')
    def code(uc,address,size,unused):
        if address in vectors:interrupt(uc,vectors[address],None)
        opcode=uc.mem_read(address,1)[0]
        if opcode in (0xca,0xcb,0xcf):
            stack=uc.reg_read(UC_X86_REG_SS)*16+uc.reg_read(UC_X86_REG_SP)
            target_ip,target_cs=struct.unpack('<HH',bytes(uc.mem_read(stack,4)))
            consumed=6 if opcode==0xcf else 4
            if opcode==0xca:consumed+=int.from_bytes(uc.mem_read(address+1,2),'little')
            if opcode==0xcf:uc.reg_write(UC_X86_REG_EFLAGS,int.from_bytes(uc.mem_read(stack+4,2),'little'))
            uc.reg_write(UC_X86_REG_SP,(uc.reg_read(UC_X86_REG_SP)+consumed)&65535)
            if target_cs*16+target_ip==stop:reached.append(True)
            transfer.append((target_cs,target_ip));uc.emu_stop();return
        last.append((address,bytes(uc.mem_read(address,size)).hex(),uc.reg_read(UC_X86_REG_SP)))
        del last[:-20]
        if address==stop:uc.emu_stop()
    def read(uc,access,address,size,value,unused):
        if address==0x487 or address==0x489 or address<0x8100:
            reads.append({'address':address,'size':size,'bytes':bytes(uc.mem_read(address,size)).hex()})
    pc.hook_add(UC_HOOK_INTR,interrupt);pc.hook_add(UC_HOOK_CODE,code);pc.hook_add(UC_HOOK_MEM_READ,read)
    for _ in range(1000):
        pc.emu_start(pc.reg_read(UC_X86_REG_CS)*16+pc.reg_read(UC_X86_REG_IP),0x100000,count=100000)
        if not transfer:break
        next_cs,next_ip=transfer.pop()
        pc.reg_write(UC_X86_REG_CS,next_cs);pc.reg_write(UC_X86_REG_EIP,next_ip)
        if reached:break
    end=pc.reg_read(UC_X86_REG_CS)*16+pc.reg_read(UC_X86_REG_IP)
    if end!=stop:
        print('probe stopped at',hex(end),'CS:IP',hex(pc.reg_read(UC_X86_REG_CS)),hex(pc.reg_read(UC_X86_REG_IP)),
              'AX',hex(pc.reg_read(UC_X86_REG_AX)),'ints',ints,'last',last)
        raise RuntimeError('original probe did not return to sentinel')
    result=chr(pc.reg_read(UC_X86_REG_AX)&255)
    results[label]={'return':result,'interrupts':ints,'low_memory_reads':reads,
                      'bda':replies[machine]['BDA'],'indirect':replies[machine]['INDIRECT'],
                      'low_byte_override':override}
    print(label,result,'BIOS BDA',replies[machine]['BDA'],'indirect',replies[machine]['INDIRECT'])
(WORK/'build/bios-reference/original-probe.json').write_text(json.dumps(results,indent=2)+'\n')
assert results['vgaonly']['return']=='V'
assert results['ega']['return']=='U'
assert results['ega_nonzero_low_byte']['return']=='E'
