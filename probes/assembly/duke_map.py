from probe import *
work=OUT/'probes'/'duke_toolbox';work.mkdir(parents=True,exist_ok=True)
source=Path('D:/Prog/duke1_recon/src/TOOLBOX.ASM').read_text()
(work/'TOOLBOX.ASM').write_text(source)
r=run(TOOLS['tasm100'],['TOOLBOX.ASM,TOOLBOX.OBJ,TOOLBOX.LST;'],work)
if (work/'TOOLBOX.OBJ').exists():r['omf']=omf(work/'TOOLBOX.OBJ')
(work/'receipt.json').write_text(json.dumps(r,indent=2))
print(r['output']);print(r.get('omf',{}).get('publics',{}))
if 'omf' in r:
    data=bytes.fromhex(r['omf']['segments']['1']);dn=Path('D:/Prog/duke1_recon/build/oracle/dn1/image.bin').read_bytes()
    # A unique function prefix ignores linked CS absolute table fixups further on.
    proc=r['omf']['publics']['_SET_VIDEO_MODE'][1];base=dn.find(data[proc:proc+31])-proc
    print('toolbox absolute image base',hex(base))
    sys.path.insert(0,str(OUT.parents[2]/'build/python'));from capstone import *
    md=Cs(CS_ARCH_X86,CS_MODE_16)
    rows=[f'{i.address:04x} {i.bytes.hex():<20} {i.mnemonic:<9} {i.op_str}' for i in md.disasm(dn[base+proc:base+len(data)],base+proc)]
    (OUT/'duke_toolbox_disasm.txt').write_text('\n'.join(rows))
    mapping={name:{'object_offset':off,'image_offset':base+off} for name,(seg,off) in r['omf']['publics'].items()}
    (OUT/'duke_publics.json').write_text(json.dumps(mapping,indent=2))
