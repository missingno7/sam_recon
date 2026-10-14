"""Place stock runtime and its data exactly at SAM1's coordinates.

Game-unit bodies are NOP fillers, used only to reproduce linker layout.
No oracle bytes are injected into this probe.
"""
from research import *
from system_recipe import recipe
LENGTHS=[0x8730,0xa660,0xdec0,0x5d0,0x22c0,0x100,0x120,0xd00,0x3040]
def inline_nops(n):
    if not n:return ''
    if n>1024:return ''.join(inline_nops(min(1024,n-i)) for i in range(0,n,1024))
    return 'inline(\n'+ '/\n'.join('/'.join('$90' for _ in range(min(24,n-i))) for i in range(0,n,24))+'\n);\n'
def main_source(codepad,bsspad,typedpad=600):
    s=recipe(typedpad)
    s=s.replace('uses Crt,Dos;','uses Dos,G9,Crt,G8,G7,G6,G5,G4,G3,G2,G1;')
    s=s.replace('var ii,jj:integer;','var BssPadding:array[1..%d] of byte;\n    regs:Registers;\n    ii,jj:integer;'%max(1,bsspad))
    s=s.replace('procedure Pmemavail;', 'procedure Keyboard; interrupt;\nvar a,b:integer;\nbegin a:=1; b:=2 end;\nprocedure Pmemavail;')
    s=s.replace('begin ii:=Padding[1]; ar:=br;','begin ii:=Padding[1]; ar:=br;\n MsDos(regs); GetIntVec(9,pp); SetIntVec(9,pp);')
    s=s.replace('MsDos(regs);','pp:=@Keyboard; MsDos(regs);')
    s=s.rsplit('end.',1)[0]+inline_nops(codepad)+'end.\n'
    return s
def filler_unit(i,length,extra=164):
    unit='unit G%d;\n{$S-}\ninterface\n'%i
    if i==9:unit+='var Extra:array[1..%d] of byte;\n'%extra
    unit+='implementation\n'
    count=(length+14999)//15000
    total=length-(7+10*count)-(5 if i==9 else 0)
    sizes=[total//count+(1 if n<total%count else 0) for n in range(count)]
    for n,size in enumerate(sizes):
        unit+='procedure P%d;\nbegin\n'%n+inline_nops(size)+'end;\n'
    unit+='begin\n'+('Extra[1]:=1;\n' if i==9 else '')+''.join('P%d;\n'%n for n in range(count))+'end.\n'
    return unit
def run(episode='sam1'):
    oracle=(REPO/('build/oracle/'+episode+'/image.bin')).read_bytes()
    h=json.loads((REPO/'layout/oracle.lock.json').read_text())['episodes'][episode]['unpacked']
    entry=(h['cs']*16)+h['ip']
    initsegs=[struct.unpack_from('<H',oracle,entry+i*5+3)[0] for i in range(11)]
    sysseg,crtseg=initsegs[0],initsegs[2]
    game=[*reversed(initsegs[3:]),initsegs[1]]
    following=game[1:8]+[crtseg,sysseg-10]
    lengths=[(b-a)*16 for a,b in zip(game,following)]
    cb_target=struct.unpack_from('<H',oracle,crtseg*16+0x64)[0]
    input_target=struct.unpack_from('<H',oracle,sysseg*16+0x75)[0]
    typedpad=struct.unpack_from('<H',oracle,sysseg*16+7)[0]-0x30
    extra=input_target-cb_target-20
    p=setup('50','full_runtime'+('' if episode=='sam1' else '_'+episode))
    for i,length in enumerate(lengths,1):
        unit=filler_unit(i,length,extra)
        (p/('G%d.PAS'%i)).write_text(unit)
    # First link measures the remaining main-program and BSS gaps.
    exe=compile('50',main_source(0,1,typedpad),'FULL',folder=p.name)
    segs,pubs=map_info(exe)
    codepad=game[0]*16-((segs[0]['end']+15)//16*16)
    cb=next(x['off'] for x in pubs if x['name']=='CHECKBREAK')
    bsspad=1+cb_target-cb
    exe=compile('50',main_source(codepad,bsspad,typedpad),'FULL',folder=p.name)
    obj=load(exe);segs,pubs=map_info(exe)
    oracle_relocs={a*16+b for a,b in json.loads((REPO/('build/oracle/'+episode+'/relocs.json')).read_text())['relocs']}
    probe_relocs={a*16+b for a,b in obj.relocs}
    records=[]
    for name,start,length in [('DOS',(sysseg-10)*16,0xa0),('CRT',crtseg*16,0x620),('SYSTEM',sysseg*16,0x11a0)]:
        seg=next(s for s in segs if s['name']==name)
        raw=obj.image[seg['start']:seg['start']+length]
        target=oracle[start:start+length]
        diffs=[{'off':i,'oracle':a,'probe':b} for i,(a,b) in enumerate(zip(target,raw)) if a!=b]
        orr=sorted(a-start for a in oracle_relocs if start<=a<start+length)
        prr=sorted(a-seg['start'] for a in probe_relocs if seg['start']<=a<seg['start']+length)
        records.append({'unit':name,'probe_segment':seg['start']//16,'oracle_segment':start//16,
                        'padded_length':length,'raw_length':seg['end']-seg['start'],
                        'byte_equal':raw==target,'relocations_equal':orr==prr,'relocations':prr,
                        'sha256':hashlib.sha256(raw).hexdigest(),'differences':diffs})
        (p/(name+'.asm')).write_text(dis(raw))
        print(name,'equal',raw==target,'diffs',len(diffs),'first',diffs[:8],flush=True)
    memory_equal=all(obj.header[a]==h[b] for a,b in [('ss','ss'),('sp','sp'),('minalloc','min_extra_paras'),('maxalloc','max_extra_paras')])
    facts={'episode':episode,'typed_padding':typedpad,'code_padding':codepad,'bss_padding':bsspad,'header':obj.header,'memory_header_equal':memory_equal,'segments':segs,
           'runtime':records,'interrupt_prologue':{'length':19,'byte_equal':obj.image[:19]==oracle[:19],'raw':obj.image[:19].hex()},
           'data_publics':[x for x in pubs if x['seg']*16==next(s['start'] for s in segs if s['class']=='DATA')]}
    (ROOT/('full_runtime_results'+('' if episode=='sam1' else '_'+episode)+'.json')).write_text(json.dumps(facts,indent=2))
    print('header',obj.header,'codepad',codepad,'bsspad',bsspad)
    assert all(x['byte_equal'] and x['relocations_equal'] for x in records),facts
    assert memory_equal,facts
if __name__=='__main__':
    for episode in ('sam1','sam2','sam3'):run(episode)
