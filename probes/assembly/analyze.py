from pathlib import Path
import json, sys, struct, collections
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'build/python'))
from capstone import *
from capstone.x86 import *
md=Cs(CS_ARCH_X86,CS_MODE_16); md.detail=True
SEGS=[(0x0000,0x5200),(0x0520,0x8730),(0x0d93,0xa660),(0x17f9,0xdec0),(0x25e5,0x5d0),(0x2642,0x22c0),(0x286e,0x100),(0x287e,0x120),(0x2890,0xd00),(0x2960,0x620),(0x29c2,0x3040),(0x2cc6,0xa0),(0x2cd0,0x11a0)]
INIT={0x29c2:0x70,0x2960:0,0x2890:0xc0d,0x287e:0x116,0x286e:0x78,0x2642:0,0x25e5:0x48c,0x17f9:0xdeaf,0x0d93:0xa658,0x0520:0x8724}
image=(ROOT/'build/oracle/sam1/image.bin').read_bytes()
relocs=json.loads((ROOT/'build/oracle/sam1/relocs.json').read_text())['relocs']
sites={s*16+o for s,o in relocs}
def dis(seg,start,end):
    return list(md.disasm(image[seg*16+start:seg*16+end],start))
def fmt(ins): return f'{ins.address:04x} {ins.bytes.hex():<20} {ins.mnemonic:<9} {ins.op_str}'
def findseg(addr):
    for s,n in SEGS:
        if s*16<=addr<s*16+n:return s,addr-s*16
calls=collections.defaultdict(list)
# Raw far calls: verify segment immediate relocation, so embedded data is filtered.
for a in range(len(image)-5):
    if image[a]==0x9a and a+3 in sites:
        o,s=struct.unpack_from('<HH',image,a+1)
        if s in dict(SEGS) and o<dict(SEGS)[s]:calls[(s,o)].append(findseg(a) or ('data',a))
summary={}
for s,n in SEGS:
    b=image[s*16:s*16+n]
    entries=sorted({o for seg,o in calls if seg==s}|({INIT[s]} if s in INIT else set()))
    # Every bytewise BP setup or Pascal INC BP prologue, not assumed all are real entries.
    bp=[i for i in range(n-3) if b[i:i+3] in (b'\x55\x8b\xec',b'\x55\x89\xe5')]
    ret=[(i,b[i:i+3].hex()) for i in range(n-2) if b[i] in (0xc2,0xca,0xcb,0xc3)]
    rows=['segment %04x size %04x init %s'%(s,n,hex(INIT[s]) if s in INIT else '-'), 'far-call targets '+','.join(f'{x:04x}' for x in entries), 'BP prologues '+','.join(f'{x:04x}' for x in bp)]
    # Linear sweep is useful for assembly; one-byte skip on undecodable instructions.
    pos=0
    while pos<n:
        ins=next(md.disasm(b[pos:],pos,count=1),None)
        if ins:
            rows.append(fmt(ins));pos+=ins.size
        else:rows.append(f'{pos:04x} {b[pos]:02x}                   db');pos+=1
    (OUT/f'seg_{s:04x}.txt').write_text('\n'.join(rows)+'\n')
    summary[f'{s:04x}']={'length':n,'init':INIT.get(s),'far_targets':entries,'bp_prologues':bp,'relocs':sum(s*16<=a<s*16+n for a in sites),'first_bytes':b[:64].hex()}
(OUT/'census.json').write_text(json.dumps(summary,indent=2))
(OUT/'calls.json').write_text(json.dumps({f'{s:04x}:{o:04x}':v for (s,o),v in sorted(calls.items())},indent=2))
for k,v in summary.items():
    print(k,'len',hex(v['length']),'relocs',v['relocs'],'targets',len(v['far_targets']),'bp',len(v['bp_prologues']),'first',v['first_bytes'][:40])
