"""Reproducible local Turbo Pascal research; all generated files stay here."""
import sys, re, json, struct, subprocess, shutil, hashlib
sys.dont_write_bytecode = True
from pathlib import Path
ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[2]
sys.path.insert(0, str(REPO / 'build/python'))
sys.path.insert(0, str(REPO / 'tools'))
import mz
import capstone
VERSIONS = {'40': 'C:/tools/borland-turbo-pascal-4.00',
            '50': 'C:/tools/borland-turbo-pascal-5.00', '55':'C:/tools/tp55',
            '60':'C:/tools/tp6', '70':'C:/tools/tp7'}
def setup(version, name=''):
    p = ROOT / ('tp'+version) / name
    p.mkdir(parents=True, exist_ok=True)
    for f in ('TPC.EXE','TURBO.TPL'):
        if not (p/f).exists(): shutil.copy2(Path(VERSIONS[version])/f,p/f)
    return p
def compile(version, source, name='PROBE', options=('/B','/GD'), folder=''):
    p=setup(version,folder)
    (p/(name+'.PAS')).write_text(source,encoding='ascii')
    r=subprocess.run(['C:/tools/nmlgcdos/msdos.exe','TPC.EXE',name+'.PAS',*options],cwd=p,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=45)
    log=r.stdout.decode('cp437',errors='replace')
    (p/(name+'.log')).write_text(log)
    if 'Error ' in log or not (p/(name+'.EXE')).exists():
        raise RuntimeError(log)
    return p/(name+'.EXE')
def load(exe): return mz.parse(Path(exe).read_bytes())
def dis(code, address=0):
    md=capstone.Cs(capstone.CS_ARCH_X86,capstone.CS_MODE_16)
    return '\n'.join(f'{i.address:04x} {bytes(i.bytes).hex():22} {i.mnemonic:7} {i.op_str}' for i in md.disasm(code,address))
def map_info(exe):
    text=Path(exe).with_suffix('.MAP').read_text()
    segs=[{'start':int(a,16),'end':int(b,16)+1,'name':n,'class':c}
          for a,b,z,n,c in re.findall(r'^ ([0-9A-F]+)H ([0-9A-F]+)H ([0-9A-F]+)H (\S+)\s+(\S+)',text,re.M)]
    pubs=[{'seg':int(s,16),'off':int(o,16),'name':n} for s,o,n in re.findall(r'^ ([0-9A-F]{4}):([0-9A-F]{4})\s+(\S+)',text,re.M)]
    return segs,pubs
def census():
    oracle=(REPO/'build/oracle/sam1/image.bin').read_bytes()
    records=[]
    for v in ('50','55','60','70'):
        exe=ROOT/('tp'+v)/'RICH.EXE'; image=load(exe).image
        segs,pubs=map_info(exe)
        for s in segs:
            if s['class']!='CODE':continue
            (ROOT/('tp'+v)/(s['name']+'.asm')).write_text(dis(image[s['start']:s['end']]))
            pp=[p for p in pubs if p['seg']*16==s['start']]
            for a,b in zip(pp,pp[1:]+[{'off':s['end']-s['start']}]):
                raw=image[s['start']+a['off']:s['start']+b['off']]
                positions=[]; i=oracle.find(raw)
                while i>=0 and len(raw)>=5:
                    positions.append(i);i=oracle.find(raw,i+1)
                records.append(dict(version=v,unit=s['name'],name=a['name'],off=a['off'],length=len(raw),sha256=hashlib.sha256(raw).hexdigest(),oracle_linear=positions))
    (ROOT/'public_matches.json').write_text(json.dumps(records,indent=2))
    for r in records:
        if r['oracle_linear'] and r['unit'] in ('DOS','CRT'):
            print(r['version'],r['unit'],r['name'],r['length'],[hex(i) for i in r['oracle_linear']])
def raw_system_matches():
    import difflib
    oracle=(REPO/'build/oracle/sam1/image.bin').read_bytes()[0x2cd00:0x2dea0]
    records=[]
    for v in ('50','55','60','70'):
        exe=ROOT/('tp'+v)/'RICH.EXE'; image=load(exe).image
        s=next(s for s in map_info(exe)[0] if s['name']=='SYSTEM' or s['name']=='System')
        code=image[s['start']:s['end']]
        blocks=difflib.SequenceMatcher(None,oracle,code,autojunk=False).get_matching_blocks()
        out=[]
        for a,b,n in blocks:
            if n>=20:
                out.append({'oracle_off':a,'probe_off':b,'length':n})
        (ROOT/('tp'+v)/'system_blocks.json').write_text(json.dumps(out,indent=2))
        print(v,out)
RICH = '''program Rich;
uses Crt, Dos;
var t: text; f:file; s:string; l:longint; i,j:integer; r:real;
    sr:SearchRec; regs:Registers; p:pointer; w:word; dr:DirStr; nm:NameStr; ex:ExtStr;
begin
  ClrScr; GotoXY(1,2); TextColor(3); TextBackground(4); LowVideo; HighVideo;
  NormVideo; Window(1,1,80,25); ClrEol; InsLine; DelLine; Sound(440); Delay(2);
  NoSound; i:=WhereX; j:=WhereY; if KeyPressed then s:=ReadKey; TextMode(3);
  GetDate(w,w,w,w); GetTime(w,w,w,w); SetDate(1990,1,1); SetTime(1,2,3,4);
  GetIntVec(9,p); SetIntVec(9,p); Intr(33,regs); MsDos(regs); SwapVectors;
  Exec('',''); FindFirst('*.*',AnyFile,sr); FindNext(sr); GetFAttr(f,w);
  SetFAttr(f,w); GetFTime(f,l); SetFTime(f,l); s:=FSearch('a','.');
  s:=FExpand(s); FSplit(s,dr,nm,ex); l:=DiskFree(0); l:=DiskSize(0);
  s:=GetEnv('PATH'); i:=EnvCount; s:=EnvStr(1); i:=DosExitCode; i:=DosVersion;
  Assign(t,'a'); Reset(t); Rewrite(t); Append(t); ReadLn(t,s); WriteLn(t,s,i,l,r);
  Flush(t); Close(t); Erase(t); Rename(t,'b'); i:=IOResult;
  Assign(f,'c'); Reset(f,1); Rewrite(f,1); BlockRead(f,s,1,w); BlockWrite(f,s,1,w);
  l:=FilePos(f); l:=FileSize(f); Seek(f,l); Truncate(f); Close(f);
  GetMem(p,4); FreeMem(p,4); p:=Ptr(0,0); l:=MemAvail; l:=MaxAvail;
  s:=Copy(s,1,2); Delete(s,1,1); Insert('z',s,1); i:=Pos('a',s); s:=Concat(s,'q');
  Val(s,l,i); Str(l,s); r:=1.2; l:=Round(r); l:=Trunc(r); r:=Sqrt(r);
  r:=Sin(r)+Cos(r)+Arctan(r)+Ln(r)+Exp(r); l:=l*12345; l:=l div 7; l:=l mod 8;
  Randomize; i:=Random(9); s:=ParamStr(1); i:=ParamCount; Halt(0)
end.
'''
if __name__=='__main__':
    if len(sys.argv)>1 and sys.argv[1]=='census': census()
    if len(sys.argv)>1 and sys.argv[1]=='blocks': raw_system_matches()
    if len(sys.argv)>1 and sys.argv[1]=='rich':
        for v in VERSIONS:
            try:
                p=compile(v,RICH,'RICH',options=('/B','/G') if v=='40' else ('/B','/GD'))
                print(v,load(p).header,flush=True)
            except Exception as e: print(v,e,flush=True)
