from analyze import *
def direct_target(ins):
    if len(ins.operands)==1 and ins.operands[0].type==X86_OP_IMM:
        return ins.operands[0].imm & 0xffff
def walk(seg,start,n):
    pending=[start];seen={}
    while pending:
        pos=pending.pop()
        while 0<=pos<n and pos not in seen:
            ins=next(md.disasm(image[seg*16+pos:seg*16+n],pos,count=1),None)
            if not ins:break
            seen[pos]=ins;target=direct_target(ins)
            if ins.mnemonic in ('ret','retf','iret'):break
            if ins.mnemonic=='jmp':
                if target is not None:pending.append(target)
                break
            if ins.group(CS_GRP_JUMP) and target is not None:pending.append(target)
            pos+=ins.size
    return sorted(seen.values(),key=lambda x:x.address)
def compact(seg,start,end):
    ins=dis(seg,start,end)
    csrefs=collections.Counter();dsrefs=collections.Counter();args=collections.Counter();rets=[];calls=[];ports=[]
    for x in ins:
        if x.mnemonic in ('ret','retf','iret'):rets.append([hex(x.address),x.mnemonic,x.op_str])
        if x.mnemonic in ('call','lcall'):calls.append([hex(x.address),x.op_str])
        if x.mnemonic in ('in','out','int'):ports.append([hex(x.address),x.mnemonic,x.op_str])
        for op in x.operands:
            if op.type!=X86_OP_MEM:continue
            m=op.mem
            if m.base==X86_REG_BP and m.disp>0:args[hex(m.disp)]+=1
            if m.segment==X86_REG_CS:csrefs[hex(m.disp&0xffff)]+=1
            elif m.base==0 and m.index==0 and m.segment in (0,X86_REG_DS):dsrefs[hex(m.disp&0xffff)]+=1
    return {'start':hex(start),'end':hex(end),'head':[fmt(x) for x in ins[:16]],'tail':[fmt(x) for x in ins[-10:]],'csrefs':dict(csrefs),'dsrefs':dict(dsrefs),'args':dict(args),'returns':rets,'calls':calls,'ports':ports}
summary={}
for seg in [0x25e5,0x2642,0x286e,0x2890,0x29c2]:
    n=dict(SEGS)[seg];b=image[seg*16:seg*16+n]
    starts=[p for p in range(n-3) if b[p:p+3] in (b'\x55\x8b\xec',b'\x55\x89\xe5')]
    if seg==0x25e5:starts += [0x4a3,0x54f,0x557,0x5c3]
    if seg==0x29c2:starts += [0x2db,0x349]
    starts=sorted(set(starts))
    rows=[]
    for i,start in enumerate(starts):
        end=starts[i+1] if i+1<len(starts) else n
        row=compact(seg,start,end);rows.append(row)
    summary[f'{seg:04x}']=rows
    textrows=[]
    for row in rows:
        textrows.append(f"\n{seg:04x}:{int(row['start'],16):04x}..{int(row['end'],16):04x} args {row['args']} CS {row['csrefs']} DS {row['dsrefs']} ret {row['returns']} calls {row['calls']}")
        textrows.extend(row['head']);textrows.append('...');textrows.extend(row['tail'])
    (OUT/f'details_{seg:04x}.txt').write_text('\n'.join(textrows))
(OUT/'details.json').write_text(json.dumps(summary,indent=2))
# Every target segment relocation (includes far function pointers as well as calls).
target_counts=collections.Counter(struct.unpack_from('<H',image,a)[0] for a in sites)
print('relocation TARGET counts',[(hex(s),c) for s,c in target_counts.most_common()])
# Find exact runs from each segment in TP's shipped units; mask neither bytes nor layout here.
sources={str(p):p.read_bytes() for p in [Path('C:/tools/borland-turbo-pascal-5.00/TURBO.TPL'),Path('C:/tools/tp55/TURBO.TPL'),Path('C:/tools/tp6/TURBO.TPL')]}
matches={}
for s,n in SEGS:
    b=image[s*16:s*16+n];matches[f'{s:04x}']={}
    for name,data in sources.items():
        hits=[]
        for off in range(0,n-32,16):
            loc=data.find(b[off:off+32])
            if loc>=0:
                length=32
                while off+length<n and loc+length<len(data) and b[off+length]==data[loc+length]:length+=1
                if not hits or off>=hits[-1][0]+hits[-1][2]:hits.append([off,loc,length])
        matches[f'{s:04x}'][name]=hits
    print(f'{s:04x}',[(Path(name).parent.name,len(hits),sum(x[2] for x in hits),max((x[2] for x in hits),default=0)) for name,hits in matches[f'{s:04x}'].items()])
(OUT/'runtime_matches.json').write_text(json.dumps(matches,indent=2))
