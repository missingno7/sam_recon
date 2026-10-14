from probe import *
base=OUT/'probes'/'tp_layout';base.mkdir(parents=True,exist_ok=True)
results={}
for name,segment,order in [('code_first','CODE',True),('text_last','_TEXT',False),('code_last','CODE',False)]:
    work=base/name;work.mkdir(parents=True,exist_ok=True)
    (work/'TURBO.TPL').write_bytes(Path('C:/tools/borland-turbo-pascal-5.00/TURBO.TPL').read_bytes())
    asm=ASM.replace('_TEXT',segment).replace('public encodings','').replace('public aligned','')
    (work/'LINK.ASM').write_text(asm)
    ar=run(TOOLS['tasm100'],['LINK.ASM,P.OBJ,LINK.LST;'],work)
    l=['{$L P.OBJ}','procedure SetMode(mode: Word); external;']
    if not order:l.reverse()
    (work/'U.PAS').write_text('unit U;\ninterface\nprocedure SetMode(mode: Word);\nprocedure Wrapper(mode: Word);\nimplementation\n'+'\n'.join(l)+'\nprocedure Wrapper(mode: Word);\nbegin SetMode(mode) end;\nbegin SetMode(1) end.\n')
    (work/'MAIN.PAS').write_text('program Main; uses U; begin Wrapper(0) end.\n')
    tr=run('C:/tools/borland-turbo-pascal-5.00/TPC.EXE',['MAIN.PAS','/B'],work)
    results[name]={'assembler':ar,'pascal':tr}
    print(name,tr['returncode'],tr['output'])
(base/'receipts.json').write_text(json.dumps(results,indent=2))
