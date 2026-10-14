from probe import *
work=OUT/'probes'/'tp_exact_layout';work.mkdir(parents=True,exist_ok=True)
(work/'TURBO.TPL').write_bytes(Path('C:/tools/borland-turbo-pascal-5.00/TURBO.TPL').read_bytes())
asm=ASM.split('public encodings')[0].replace("_TEXT segment byte public 'CODE'",'CODE segment byte public').replace('_TEXT','CODE')
asm=asm.replace('public SetMode','db 0bdh dup (?)\npublic SetMode')
asm+='''public InitFonts,SetFont,BIOSMode,SetColor
InitFonts proc far
 ret
InitFonts endp
SetFont proc far
 ret 2
SetFont endp
BIOSMode proc far
 ret 2
BIOSMode endp
SetColor proc far
 ret 2
SetColor endp
CODE ends
end
'''
(work/'P.ASM').write_text(asm)
ar=run(TOOLS['tasm100'],['P.ASM,P.OBJ,P.LST;'],work)
unit='''unit U;
{$S-,F+}
interface
procedure SetMode(mode: Word);
implementation
const
  C1='Copyright 1991 Peder Jungck';
  C2='1019 W Lovers Lane         ';
  C3='Arlington, Texas  76013    ';
  C4='(817) 795-8903             ';
var Buffer: string[80];
procedure SetMode(mode: Word); external;
procedure InitFonts; external;
procedure SetFont(font: Word); external;
procedure BIOSMode(mode: Word); external;
procedure SetColor(color: Word); external;
{$L P.OBJ}
begin
  SetMode(1); InitFonts; SetFont(0); BIOSMode($10); SetColor($f);
  Buffer:=C1; Buffer:=C2; Buffer:=C3; Buffer:=C4
end.
'''
(work/'U.PAS').write_text(unit)
(work/'MAIN.PAS').write_text('program Main; uses U; begin SetMode(0) end.\n')
tr=run('C:/tools/borland-turbo-pascal-5.00/TPC.EXE',['MAIN.PAS','/B'],work)
(work/'receipt.json').write_text(json.dumps({'assembler':ar,'pascal':tr,'omf':omf(work/'P.OBJ')},indent=2))
print(ar['output'],tr['output'])
if (work/'MAIN.EXE').exists():
    sys.path.insert(0,str(OUT.parents[2]/'tools'));import mz
    sys.path.insert(0,str(OUT.parents[2]/'build/python'));from capstone import *
    m=mz.parse((work/'MAIN.EXE').read_bytes());md=Cs(CS_ARCH_X86,CS_MODE_16)
    targets=sorted(set(struct.unpack_from('<H',m.image,s*16+o)[0] for s,o in m.relocs))
    us=targets[0];b=m.image[us*16:targets[1]*16]
    print('unit segment',hex(us),'first bytes',b[:128])
    rows=[f'{i.address:04x} {i.bytes.hex():<20} {i.mnemonic} {i.op_str}' for i in md.disasm(b[0x70:],0x70)]
    (work/'unit_disasm.txt').write_text('\n'.join(rows))
    print('\n'.join(rows[:55]))
