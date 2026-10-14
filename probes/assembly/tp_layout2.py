from probe import *
base=OUT/'probes'/'tp_layout2';base.mkdir(parents=True,exist_ok=True)
results={}
for name,header,flags in [
 ('no_class',"CODE segment byte public",[]),
 ('word',"CODE segment word public 'CODE'",[]),
 ('private',"CODE segment byte",[]),
 ('case_l',"CODE segment byte public 'CODE'",['/ml']),
 ('case_x',"CODE segment byte public 'CODE'",['/mx']),
 ('allcaps',"CODE segment byte public 'CODE'",[]),
 ('ccode',"CODE segment byte public 'CODE'",['/m2']),
]:
    work=base/name;work.mkdir(parents=True,exist_ok=True)
    (work/'TURBO.TPL').write_bytes(Path('C:/tools/borland-turbo-pascal-5.00/TURBO.TPL').read_bytes())
    asm=ASM.replace("_TEXT segment byte public 'CODE'",header).replace('_TEXT','CODE').replace('public encodings','').replace('public aligned','')
    if name=='allcaps':asm=asm.upper()
    (work/'LINK.ASM').write_text(asm)
    ar=run(TOOLS['tasm100'],[*flags,'LINK.ASM,P.OBJ,LINK.LST;'],work)
    (work/'U.PAS').write_text('unit U;\ninterface\nprocedure SetMode(mode: Word);\nprocedure Wrapper(mode: Word);\nimplementation\nprocedure SetMode(mode: Word); external;\n{$L P.OBJ}\nprocedure Wrapper(mode: Word);\nbegin SetMode(mode) end;\nbegin SetMode(1) end.\n')
    (work/'MAIN.PAS').write_text('program Main; uses U; begin Wrapper(0) end.\n')
    tr=run('C:/tools/borland-turbo-pascal-5.00/TPC.EXE',['MAIN.PAS','/B'],work)
    results[name]={'assembler':ar,'pascal':tr}
    print(name,tr['returncode'],tr['output'][-220:].replace('\n',' '))
(base/'receipts.json').write_text(json.dumps(results,indent=2))
