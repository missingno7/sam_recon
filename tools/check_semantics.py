"""Run the full translator corpus against TP5 on an independent DOSBox-X PC.
Native side links the real platform/System library, without any PC/DOS double.
"""
from pathlib import Path
import json
import os
import subprocess
import sys
from pas2c_paths import WORK,ROOT,CORPUS
from pas2c import Compiler
from pas2c_emit import Emitter
from probe import run

build=Path(sys.argv[1]).resolve()
import re
optimization=re.search(r'^SAM_OPTIMIZATION:STRING=([02])$',(build/'CMakeCache.txt').read_text(),re.M).group(1)
gcc='C:/msys64/mingw64/bin/gcc.exe'
sdl='C:/tools/sdl3-3.4.16-mingw/SDL3-3.4.16/x86_64-w64-mingw32'
receipts={}
for source in sorted(CORPUS.glob('*.PAS')):
    if source.stem=='BIOSREF':continue # hardware-reference capture, not a corpus test
    work=WORK/'build/semantics'/('o'+optimization)/source.stem;work.mkdir(parents=True,exist_ok=True)
    c=Compiler(source.parent,'sam1');c.load(source.stem);c.bind();Emitter(c).write(work)
    args=[gcc,'-std=c11','-Wall','-Wextra','-Wpedantic','-O'+optimization,'-fno-strict-aliasing',
          '-I',str(WORK/'port'),'-I',str(WORK/'port/tp'),'-I',str(work),
          str(WORK/'port/tests/corpus_runner.c'),*[str(p) for p in work.glob('*.c')],
          str(build/'libsam_platform.a'),'-L',sdl+'/lib','-lSDL3',
          '-ld3d11','-ldxgi','-ldxguid','-ld3dcompiler','-lm','-o',str(work/'native.exe')]
    compiled=subprocess.run(args,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (work/'gcc.log').write_bytes(compiled.stdout)
    if compiled.returncode:raise RuntimeError(compiled.stdout.decode(errors='replace'))
    native=subprocess.run([str(work/'native.exe'),'--headless','--no-audio','--data',str(work)],
                          cwd=work,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=15)
    reference=run(source,work/'dos').replace('\r','')
    actual=native.stdout.decode('latin1').replace('\r','')
    receipt={'ok':reference==actual and native.returncode==0,'dos':reference,'native':actual,
             'native_exit':native.returncode,'warnings':compiled.stdout.decode(errors='replace').count('warning:'),
             'platform_dependent':source.stem in ('ERASE','ERASELIVE'),
             'flags':['-O'+optimization,'-fno-strict-aliasing'],'command':args}
    if receipt['platform_dependent']:
        receipt['reason']='INT 21h AH=41h: DOS unlink succeeds while open and the surviving handle remains usable; checked against DOSBox-X using the real platform.'
    receipts[source.stem]=receipt
    print(source.stem,'PASS' if receipt['ok'] else 'DIFF',flush=True)
    if not receipt['ok']:print('DOS',repr(reference),'native',repr(actual),flush=True)
(WORK/'build/semantics'/('o'+optimization)/'checks.json').write_text(json.dumps(receipts,indent=2)+'\n')
sys.exit(0 if all(r['ok'] for r in receipts.values()) else 1)
