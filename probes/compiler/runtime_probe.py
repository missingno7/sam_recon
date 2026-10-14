"""Named wrappers identify System link targets and exact routine ranges."""
from research import *
FEATURES=[
 ('memavail','li:=MemAvail'),('maxavail','li:=MaxAvail'),('getmem','GetMem(pp,iw)'),
 ('freemem','FreeMem(pp,iw)'),('mark','Mark(pp)'),('release','Release(pp)'),
 ('move','Move(ss,tt,iw)'),('fillchar','FillChar(ss,iw,0)'),
 ('strcopy','ss:=tt'),('concat','ss:=ss+tt'),('copy','ss:=Copy(tt,ii,jj)'),
 ('delete','Delete(ss,ii,jj)'),('insert','Insert(tt,ss,ii)'),('pos','ii:=Pos(ss,tt)'),
 ('valint','Val(ss,ii,jj)'),('vallong','Val(ss,li,jj)'),('strint','Str(ii,ss)'),
 ('strlong','Str(li,ss)'),('paramstr','ss:=ParamStr(ii)'),('paramcount','ii:=ParamCount'),
 ('randomize','Randomize'),('random','ii:=Random(ii)'),('longmul','li:=li*lj'),
 ('longdiv','li:=li div lj'),('longmod','li:=li mod lj'),
 ('assigntext',"Assign(tf,'xx')"),('resettext','Reset(tf)'),('rewritetext','Rewrite(tf)'),
 ('appendtext','Append(tf)'),('closetext','Close(tf)'),('flush','Flush(tf)'),
 ('readstr','Read(tf,ss)'),('readln','ReadLn(tf)'),('writestr','Write(tf,ss)'),
 ('writeint','Write(tf,ii)'),('writelong','Write(tf,li)'),('writeln','WriteLn(tf)'),
 ('eoftext','bb:=Eof(tf)'),('eoln','bb:=Eoln(tf)'),('seekeof','bb:=SeekEof(tf)'),
 ('seekeoln','bb:=SeekEoln(tf)'),('assignfile',"Assign(ff,'yy')"),('resetfile','Reset(ff,1)'),
 ('rewritefile','Rewrite(ff,1)'),('closefile','Close(ff)'),('erase','Erase(ff)'),
 ('rename',"Rename(ff,'zz')"),('blockread','BlockRead(ff,ss,iw,jw)'),
 ('blockread3','BlockRead(ff,ss,iw)'),('blockwrite3','BlockWrite(ff,ss,iw)'),
 ('blockwrite','BlockWrite(ff,ss,iw,jw)'),('filepos','li:=FilePos(ff)'),
 ('filesize','li:=FileSize(ff)'),('seek','Seek(ff,li)'),('truncate','Truncate(ff)'),
 ('ioresult','ii:=IOResult'),('getdir','GetDir(ii,ss)'),('chdir','ChDir(ss)'),
 ('mkdir','MkDir(ss)'),('rmdir','RmDir(ss)'),('runerror','RunError(ii)'),('halt','Halt(ii)'),
 ('stringcmp','bb:=ss=tt'),('setunion','st:=st+su'),('setinter','st:=st*su'),
 ('stringchar','ss:=Chr(ii)'),
 ('setdiff','st:=st-su'),('seteq','bb:=st=su'),('setin','bb:=ii in st'),
 ('realadd','rr:=rr+rs'),('realmul','rr:=rr*rs'),('realdiv','rr:=rr/rs'),
 ('sqrt','rr:=Sqrt(rr)'),('sin','rr:=Sin(rr)'),('cos','rr:=Cos(rr)'),
 ('arctan','rr:=Arctan(rr)'),('ln','rr:=Ln(rr)'),('exp','rr:=Exp(rr)'),
 ('round','li:=Round(rr)'),('trunc','li:=Trunc(rr)'),('realstr','Str(rr,ss)'),
 ('realval','Val(ss,rr,ii)'),('readreal','Read(tf,rr)'),('writereal','Write(tf,rr)'),
]
def source(pad=600):
    init=',\n'.join(','.join('0' for _ in range(min(30,pad-i))) for i in range(0,pad,30))
    return '''program Runtime;
{$S-}
uses Crt,Dos;
const Padding:array[1..%d] of byte=(%s);
var ii,jj:integer; iw,jw:word; li,lj:longint; pp:pointer;
    ss,tt:string; tf:text; ff:file; bb:boolean; st,su:set of byte; rr,rs:real;
'''%(pad,init)+''.join('procedure P%s;\nbegin %s end;\n'%(n,s) for n,s in FEATURES)+'''
begin ii:=Padding[1];
'''+''.join(' P%s;\n'%n for n,s in FEATURES)+'end.\n'
MD=capstone.Cs(capstone.CS_ARCH_X86,capstone.CS_MODE_16)
MD.detail=True
def calls(code,start,end):
    out=[]
    for i in MD.disasm(code[start:end],start):
        raw=bytes(i.bytes)
        if raw[0]==0x9a: out.append((struct.unpack_from('<H',raw,3)[0],struct.unpack_from('<H',raw,1)[0]))
    return out
def extent(code,start):
    todo=[start]; seen={}; safety=0
    while todo:
        a=todo.pop()
        while a not in seen and 0<=a<len(code):
            safety+=1
            if safety>20000: return None
            it=list(MD.disasm(code[a:a+16],a,1))
            if not it:return None
            i=it[0]; seen[a]=i.size; nxt=a+i.size
            if i.mnemonic in ('ret','retf','iret','ljmp'):break
            if i.mnemonic=='jmp':
                if i.operands[0].type==capstone.x86_const.X86_OP_IMM:
                    todo.append(i.operands[0].imm&65535)
                break
            if i.mnemonic.startswith('j') or i.mnemonic.startswith('loop'):
                if i.operands and i.operands[0].type==capstone.x86_const.X86_OP_IMM:todo.append(i.operands[0].imm&65535)
            a=nxt
    if not seen:return None
    return {'start':start,'min':min(seen),'end':max(a+n for a,n in seen.items()),'instructions':len(seen)}
def run():
    oracle=(REPO/'build/oracle/sam1/image.bin').read_bytes()
    records=[]
    for v in ('50','55','60','70'):
        exe=compile(v,source(),'RUNTIME')
        obj=load(exe); segs,pubs=map_info(exe)
        syst=next(s for s in segs if s['name'].upper()=='SYSTEM')
        scode=obj.image[syst['start']:syst['end']]
        pp=[p for p in pubs if p['seg']==0]
        for p,q in zip(pp,pp[1:]):
            tag=p['name'].lower()[1:]
            if tag not in dict(FEATURES):continue
            targets=calls(obj.image,p['off'],q['off'])
            for sg,of in targets:
                if sg*16!=syst['start']:continue
                ex=extent(scode,of)
                if not ex:continue
                raw=scode[ex['start']:ex['end']] if ex['min']==ex['start'] else b''
                matches=[]; pos=oracle.find(raw) if raw else -1
                while pos>=0:
                    matches.append(pos);pos=oracle.find(raw,pos+1)
                records.append({'version':v,'feature':tag,'system_off':of,'extent':ex,
                    'length':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'oracle_linear':matches})
                if matches: print(v,tag,hex(of),len(raw),[hex(p) for p in matches])
        (ROOT/('tp'+v)/'runtime_system.asm').write_text(dis(scode))
    (ROOT/'runtime_matches.json').write_text(json.dumps(records,indent=2))
if __name__=='__main__':run()
