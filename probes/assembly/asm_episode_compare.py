from analyze import *
import hashlib
rows=json.loads((OUT/'asm_routines.json').read_text())
eps=['sam1','sam2','sam3'];imgs={e:(ROOT/f'build/oracle/{e}/image.bin').read_bytes() for e in eps}
rs={e:{s*16+o for s,o in json.loads((ROOT/f'build/oracle/{e}/relocs.json').read_text())['relocs']} for e in eps}
segnames=[s for s,n in SEGS]+[0x2dea]
maps={e:dict(zip(segnames,sorted(set(struct.unpack_from('<H',imgs[e],a)[0] for a in rs[e])))) for e in eps}
def normalized(seg,start,end,ep):
    s=maps[ep][seg];delta=imgs[ep].find(bytes.fromhex('e670eb00eb00e471'))-0x5151 if seg==0 else 0
    orig=imgs[ep][s*16+start+delta:s*16+end+delta];b=bytearray(orig);changes=[]
    for a in rs[ep]:
        off=a-(s*16+start+delta)
        if 0<=off<len(b)-1:b[off:off+2]=b'\0\0'
    for i in md.disasm(orig,start+delta):
        for op in i.operands:
            if op.type==X86_OP_MEM:
                m=op.mem
                if seg==0 and m.segment==X86_REG_CS and 0x514a+delta<=m.disp<=0x5150+delta:
                    off=i.address-start-delta+i.disp_offset
                    struct.pack_into('<H',b,off,m.disp-delta);changes.append([i.address-delta,'CS offset',m.disp-delta])
                elif seg in (0x25e5,0x2642) and m.segment in (0,X86_REG_DS,X86_REG_ES) and m.disp>=0x2000 and ep!='sam1':
                    ri=next(md.disasm(imgs['sam1'][seg*16+i.address:seg*16+i.address+i.size],i.address,count=1))
                    ref=next((x.mem.disp for x in ri.operands if x.type==X86_OP_MEM),None)
                    if ref is not None and m.disp-ref==0x26:
                        off=i.address-start+i.disp_offset
                        struct.pack_into('<H',b,off,ref);changes.append([i.address,'DS variable offset',ref])
        if seg==0 and i.mnemonic=='lcall' and i.bytes[0]==0x9a:
            off=i.address-start-delta+1;target=struct.unpack_from('<H',b,off)[0]
            if target==0x5151+delta:struct.pack_into('<H',b,off,target-delta);changes.append([i.address-delta,'call offset',target-delta])
        if seg==0x2642 and ep!='sam1' and i.mnemonic=='mov' and len(i.operands)==2 and i.operands[0].type==X86_OP_REG and i.operands[0].reg in (X86_REG_SI,X86_REG_DI,X86_REG_BX) and i.operands[1].type==X86_OP_IMM:
            value=i.operands[1].imm&65535;adjust=0
            ri=next(md.disasm(imgs['sam1'][seg*16+i.address:seg*16+i.address+i.size],i.address,count=1))
            ref=ri.operands[1].imm&65535
            if ref in (0x1a,0x8a) and value-ref==0xe:adjust=0xe
            elif 0x2000<=ref<=0x3500 and value-ref==0x26:adjust=0x26
            if adjust:
                off=i.address-start+i.imm_offset;struct.pack_into('<H',b,off,value-adjust);changes.append([i.address,'DS address immediate',value-adjust])
    return orig,bytes(b),changes
result=[]
for r in rows:
    if r['classification']!='linked_assembly_probable':continue
    seg=int(r['segment'],16);a=int(r['start'],16);z=int(r['end'],16)
    # Exclude helpers/data inside a bounding span; detailed instruction ranges carry exact scope.
    scopes=[(int(x,16),int(y,16)) for x,y in r['code_ranges']]
    refs={}
    for ep in eps:
        parts=[normalized(seg,x,y,ep) for x,y in scopes]
        refs[ep]={'raw':b''.join(x[0] for x in parts),'normalized':b''.join(x[1] for x in parts),'fixups':[v for x in parts for v in x[2]]}
    result.append({'segment':r['segment'],'start':r['start'],'name':r['name_guess'],
                   'episodes':{e:{'raw_code_equal':refs['sam1']['raw']==refs[e]['raw'],'normalized_code_equal':refs['sam1']['normalized']==refs[e]['normalized'],'fixups':refs[e]['fixups'],'sha256':hashlib.sha256(refs[e]['normalized']).hexdigest()} for e in eps}})
(OUT/'asm_episode_compare.json').write_text(json.dumps(result,indent=2))
for seg in sorted(set(r['segment'] for r in result)):
    rr=[r for r in result if r['segment']==seg]
    print(seg,len(rr),'raw equal', {e:sum(r['episodes'][e]['raw_code_equal'] for r in rr) for e in eps},'normalized equal', {e:sum(r['episodes'][e]['normalized_code_equal'] for r in rr) for e in eps})
    for r in rr:
        if not all(r['episodes'][e]['normalized_code_equal'] for e in eps):print('FAIL',r['start'],r['name'])
# Entire toolbox code, including all unreachable NOPs and trailing RETF n instructions.
data_ranges=[(0x59f,0x5a1),(0x7ec,0x7ee),(0x9c6,0x9ce),(0x12f2,0x12fc),(0x1586,0x1590),(0x18c2,0x18ca),(0x1b22,0x1b27),(0x1e7f,0x1e87),(0x26cf,0x26e9)]
code_offsets=[i for i in range(0x1a3,0x303a) if not any(a<=i<z for a,z in data_ranges)]
whole={e:bytes(imgs[e][maps[e][0x29c2]*16+i] for i in code_offsets) for e in eps}
w={'scope':'29c2:01A3..303A excluding documented interspersed data ranges','bytes':len(code_offsets),'equal':{e:whole[e]==whole['sam1'] for e in eps},'sha256':{e:hashlib.sha256(whole[e]).hexdigest() for e in eps},'excluded_data_ranges':data_ranges}
(OUT/'toolbox_code_identity.json').write_text(json.dumps(w,indent=2))
print('Whole toolbox code',w)
