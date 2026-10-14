from probe import *
base=OUT/'probes'/'tp_codegen';base.mkdir(parents=True,exist_ok=True)
results={}
pas='''program Style;
{$S-}
var b: Byte;
procedure P(w:Word);
var v:Word;
begin v:=w; v:=v+1; b:=Port[$201]; b:=b and $10; if b=0 then b:=1 else b:=0 end;
procedure I;
begin Inline($FA/$FB/$90) end;
begin P(1); I end.
'''
for name,toolroot in [('tp500',Path('C:/tools/borland-turbo-pascal-5.00')),('tp600',Path('C:/tools/tp6'))]:
    work=base/name;work.mkdir(parents=True,exist_ok=True)
    (work/'TURBO.TPL').write_bytes((toolroot/'TURBO.TPL').read_bytes());(work/'STYLE.PAS').write_text(pas)
    results[name+'_pascal']=run(toolroot/'TPC.EXE',['STYLE.PAS','/B'],work)
    (work/'ASMSTYLE.PAS').write_text('''program AsmStyle;
{$S-}
procedure P(w:Word); assembler;
asm
 mov bp,sp
 mov sp,bp
 mov ax,bx
 mov bx,ax
 xor ax,ax
 xor ah,ah
 jmp @forward
 nop
@forward:
 nop
end;
begin P(1) end.
''')
    results[name+'_asm']=run(toolroot/'TPC.EXE',['ASMSTYLE.PAS','/B'],work)
    (work/'ISR.PAS').write_text('program Isr; {$S-} var b:byte; p:pointer; procedure IntProc; interrupt; begin Inc(b) end; begin p:=@IntProc end.\n')
    results[name+'_interrupt']=run(toolroot/'TPC.EXE',['ISR.PAS','/B'],work)
    print(name,results[name+'_pascal']['returncode'],results[name+'_asm']['output'])
(base/'receipts.json').write_text(json.dumps(results,indent=2))
