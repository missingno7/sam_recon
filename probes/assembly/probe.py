from pathlib import Path
import subprocess, os, json, struct, sys
OUT=Path(__file__).resolve().parent
RUN=Path('C:/tools/nmlgcdos/msdos.exe')
TOOLS={
 'tasm100':'C:/tools/tasm-1.00/files/disk04/TASM.EXE',
 'tasm101':'C:/tools/tasm-1.01/files/disk01/TASM.EXE',
 'tasm200':'C:/tools/tasm-2.00/files/disk01/expanded/TASM/TASM.EXE',
 'tasm201':'C:/tools/tasm-2.01/files/disk01/expanded/TASM/TASM.EXE',
 'masm400':'C:/tools/masm-4.00/files/MASM.EXE',
 'masm500':'C:/tools/masm-5.00/files/MASM.EXE',
 'masm510':'C:/tools/masm-5.10/files/MASM.EXE',
}
def run(tool,args,cwd):
    env={'PATH':str(Path(tool).parent),'MSDOS_PATH':str(Path(tool).parent),
         'TEMP':str(cwd),'TMP':str(cwd),'MSDOS_TEMP':str(cwd),'SystemRoot':os.environ.get('SystemRoot','C:/Windows')}
    si=subprocess.STARTUPINFO();si.dwFlags|=subprocess.STARTF_USESHOWWINDOW;si.wShowWindow=0
    cmd=[str(RUN),'-e','-v5.00',str(tool),*args]
    p=subprocess.run(cmd,cwd=cwd,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,stdin=subprocess.DEVNULL,timeout=45,startupinfo=si,creationflags=subprocess.CREATE_NO_WINDOW)
    return {'argv':cmd,'returncode':p.returncode,'output':p.stdout.decode('cp437',errors='replace')}
def idx(b,p=0):
    if b[p]&128:return ((b[p]&127)<<8)|b[p+1],p+2
    return b[p],p+1
def omf(path):
    data=path.read_bytes();p=0;records=[];segments={};pubs={}
    while p<len(data):
        kind=data[p];n=struct.unpack_from('<H',data,p+1)[0];body=data[p+3:p+2+n];p+=n+3
        rec={'type':hex(kind),'body':body.hex()}
        if kind==0xa0:
            seg,q=idx(body);off=struct.unpack_from('<H',body,q)[0];contents=body[q+2:]
            if seg not in segments:segments[seg]=bytearray()
            end=off+len(contents)
            if end>len(segments[seg]):segments[seg].extend(bytes(end-len(segments[seg])))
            segments[seg][off:end]=contents
            rec.update(segment=seg,offset=off,data=contents.hex())
        if kind==0x90:
            group,q=idx(body);seg,q=idx(body,q)
            if not seg:q+=2
            while q<len(body):
                length=body[q];q+=1;name=body[q:q+length].decode('ascii',errors='replace');q+=length
                off=struct.unpack_from('<H',body,q)[0];q+=2;typ,q=idx(body,q);pubs[name]=[seg,off]
        records.append(rec)
    return {'records':records,'segments':{str(k):v.hex() for k,v in segments.items()},'publics':pubs}
ASM='''_TEXT segment byte public 'CODE'
assume cs:_TEXT
public SetMode
SetMode proc far
 push bp
 mov bp,sp
 mov ax,[bp+6]
 cmp al,0
 jne mode1
 mov al,0dh
 jmp ready
mode1:
 cmp al,1
 je mode10
 xor ah,ah
 mov al,12h
 jmp ready
mode10:
 mov al,10h
ready:
 int 10h
 pop bp
 ret 2
SetMode endp
public encodings
encodings proc far
 mov bp,sp
 mov sp,bp
 mov ax,bx
 mov bx,ax
 mov cx,dx
 mov si,di
 mov ax,ax
 xor ax,ax
 xor bx,bx
 xor ah,ah
 add ax,bx
 sub ax,bx
 cmp ax,bx
 test ax,bx
 xchg ax,bx
 shl ax,1
 shl ax,cl
 jmp fwd
 nop
fwd:
 ret
encodings endp
public aligned
aligned: nop
_TEXT ends
end
'''
def assembler_probes():
    results={}
    for name,tool in TOOLS.items():
        work=OUT/'probes'/name;work.mkdir(parents=True,exist_ok=True)
        (work/'P.ASM').write_text(ASM)
        args=['P.ASM,P.OBJ,P.LST;']
        receipt=run(tool,args,work)
        if (work/'P.OBJ').exists():receipt['omf']=omf(work/'P.OBJ')
        (work/'receipt.json').write_text(json.dumps(receipt,indent=2))
        results[name]=receipt
        print(name,receipt['returncode'],receipt['output'][:250].replace('\n',' '),receipt.get('omf',{}).get('segments'))
    (OUT/'assembler_probes.json').write_text(json.dumps(results,indent=2))
def tp_probe():
    work=OUT/'probes'/'tp500';work.mkdir(parents=True,exist_ok=True)
    (work/'TURBO.TPL').write_bytes(Path('C:/tools/borland-turbo-pascal-5.00/TURBO.TPL').read_bytes())
    (work/'LINK.ASM').write_text(ASM.replace('public encodings','').replace('public aligned',''))
    link_receipt=run(TOOLS['tasm100'],['LINK.ASM,P.OBJ,LINK.LST;'],work)
    (work/'U.PAS').write_text('''unit U;
interface
procedure SetMode(mode: Word);
procedure Wrapper(mode: Word);
implementation
{$L P.OBJ}
procedure SetMode(mode: Word); external;
procedure Wrapper(mode: Word);
begin SetMode(mode) end;
begin SetMode(1) end.
''')
    (work/'MAIN.PAS').write_text('''program Main;
uses U;
begin Wrapper(0) end.
''')
    (work/'RUNTIME.PAS').write_text('''program Runtime;
uses Crt,Dos;
var r: Registers; p: Pointer;
begin
TextMode(3); ClrScr; Delay(1); Sound(440); NoSound;
GetIntVec($10,p); SetIntVec($10,p); Intr($10,r); MsDos(r);
end.
''')
    results={'LINK.ASM':link_receipt}
    for source in ['MAIN.PAS','RUNTIME.PAS']:
        results[source]=run('C:/tools/borland-turbo-pascal-5.00/TPC.EXE',[source,'/B','/IC:/tools/borland-turbo-pascal-5.00'],work)
        print(source,results[source]['returncode'],results[source]['output'])
    (work/'receipt.json').write_text(json.dumps(results,indent=2))
if __name__=='__main__':
    assembler_probes()
    tp_probe()
