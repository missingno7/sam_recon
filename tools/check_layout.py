"""Read-only oracle check: source DATA layout and generated images, no substitution."""
import json
import re
import sys
from pathlib import Path
from pas2c_paths import ROOT,WORK
from pas2c import Compiler
sys.dont_write_bytecode=True
sys.path.insert(0,str(ROOT/'tools'))
import oracle
# Restore staging-module priority after importing the canonical check helpers.
sys.path.insert(0, str(Path(__file__).resolve().parent))

oracle.OUT=WORK/'build/oracle'
results={}
for episode in ('sam1','sam2','sam3'):
    c=Compiler(ROOT/'game',episode);c.load('SAM');c.bind()
    text=(WORK/'build/reference'/episode/'SAM.MAP').read_text(encoding='latin1')
    m=re.search(r'^\s+([0-9A-F]+)H\s+[0-9A-F]+H\s+([0-9A-F]+)H\s+DATA\s+DATA',text,re.M)
    base,size=int(m[1],16),int(m[2],16)
    symbols={s.name.upper():s.offset for u in c.units.values() for s in u.globals}
    symbols.update({n.upper():v['offset'] for n,v in c.runtime_symbols.items()})
    publics=re.findall(r'^ '+f'{base//16:04X}'+r':([0-9A-F]{4})\s+(\w+)\s*$',text,re.M)
    differences=[(name,int(off,16),symbols.get(name)) for off,name in publics if symbols.get(name)!=int(off,16)]
    _,original,_=oracle.describe(episode);reference=original.image[base:base+size]
    results[episode]={}
    for directory in sys.argv[1:]:
        build=Path(directory);data=(build/'port-gen'/episode/'ds.bin').read_bytes()
        ok=len(data)==size==c.ds_size and not differences and data[:len(reference)]==reference
        assert ok,(directory,differences)
        results[episode][str(build)]={'ok':ok,'data_bytes':size,'initialized_bytes':len(reference),'publics':len(publics)}
    print(f'PASS {episode} DATA: {len(reference)} initialized bytes, {size} declared bytes, {len(publics)} publics; both builds')
(WORK/'build/layout-checks.json').write_text(json.dumps(results,indent=2)+'\n')
