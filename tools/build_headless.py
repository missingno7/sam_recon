"""Compile deterministic generated C plus the runtime and declared doubles."""
from pathlib import Path
import argparse
import subprocess
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from pas2c import Compiler, placement_layout
from pas2c_emit import Emitter

from pas2c_paths import WORK, ROOT, CODE_ROOT
GCC=Path('C:/msys64/mingw64/bin/gcc.exe')
def build(source,program,episode,out,placement_path=None,optimization='O0'):
    c=Compiler(source,episode); c.load(program); c.bind(); out.mkdir(parents=True,exist_ok=True)
    if program.upper()=='SAM': c.program_layout=placement_layout(placement_path or CODE_ROOT/'config/port.json',episode)
    Emitter(c).write(out)
    sources=list(out.glob('*.c'))
    external=[]
    for u in c.units.values():
        external.extend(r for r in u.routines if r.external)
    e=Emitter(c)
    stub=['#include "generated.h"','#include <stdio.h>','#include <stdlib.h>']
    if 'pcxgenus' in c.units:
        stub.extend(['#include "lib/samlib.h"',
                     'void samlib_bind_data_offsets(const samlib_data_offsets *o) { (void)o; fputs("samlib_bind_data_offsets\\n",stderr); }'])
    for r in external:
        stub.append(e.prototype(r)+' {')
        stub.append(f'    fputs("{r.name}\\n",stderr);')
        stub.extend(f'    (void){p.cname};' for p in r.params)
        if r.name.lower()=='pcxdisplayfile':
            stub.append('    fputs("SMOKE_FIRST_PCX\\n",stderr); exit(0);')
        if r.type.cname=='farptr': stub.append('    return 0;')
        elif r.type.cname!='void': stub.append('    return 0;')
        stub.append('}')
    stub.append(f'int main(void) {{ {c.prefix}run(); return 0; }}')
    (out/'library_stub.c').write_text('\n'.join(stub)+'\n')
    sources=[p for p in sources if p.name!='library_stub.c']+[out/'library_stub.c',CODE_ROOT/'port/tp/system.c',CODE_ROOT/'tests/port/double/pc_stub.c']
    command=[str(GCC),'-std=c11','-Wall','-Wextra','-'+optimization,'-fno-strict-aliasing','-I'+str(out),'-I'+str(CODE_ROOT/'port'),'-I'+str(ROOT/'port'),
             *map(str,sources),'-o',str(out/'headless.exe')]
    proc=subprocess.run(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (out/'gcc.log').write_bytes(proc.stdout)
    (out/'gcc.command.json').write_text(__import__('json').dumps(command,indent=2)+'\n')
    if proc.returncode: print(proc.stdout.decode('utf8',errors='replace')[-5000:])
    return proc.returncode
if __name__=='__main__':
    p=argparse.ArgumentParser(); p.add_argument('--source-dir',type=Path,default=ROOT/'game'); p.add_argument('--program',default='SAM')
    p.add_argument('--episode',default='sam1'); p.add_argument('--out',type=Path,required=True)
    p.add_argument('--placement',type=Path); p.add_argument('--optimization',choices=('O0','O2'),default='O0'); a=p.parse_args()
    sys.exit(build(a.source_dir,a.program,a.episode,a.out,a.placement,a.optimization))
