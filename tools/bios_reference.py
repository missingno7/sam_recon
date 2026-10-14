"""Capture EGA/VGA BIOS replies and low RAM under the pinned independent DOS PC."""
from pathlib import Path
import hashlib
import json
import os
import shutil
import subprocess
import sys
from pas2c_paths import ROOT,WORK
sys.dont_write_bytecode=True
sys.path.insert(0,str(ROOT/'tools'))
import toolchain

source=WORK/'tests/port/semantics/BIOSREF.PAS'
compile_dir=WORK/'build/bios-reference/compiler'
compile_dir.mkdir(parents=True,exist_ok=True)
shutil.copyfile(source,compile_dir/source.name)
shutil.copyfile(toolchain.tool('TURBO.TPL'),compile_dir/'TURBO.TPL')
rc,out,_=toolchain.run_dos('TPC.EXE',['/M','/GD','BIOSREF.PAS'],compile_dir)
(compile_dir/'compile.log').write_bytes(out)
if rc or b'Error' in out: raise RuntimeError(out.decode('latin1'))
toolchain.verify_all()
runner=toolchain.lock()['independent_runner']['executable']
results={}
for machine in ('ega','vgaonly'):
    work=WORK/'build/bios-reference'/machine;work.mkdir(exist_ok=True)
    shutil.copyfile(compile_dir/'BIOSREF.EXE',work/'RUNPROBE.EXE')
    conf=work/'dosbox.conf'
    conf.write_text('\n'.join(['[sdl]','output=surface','[cpu]','cycles=max','[mixer]',
                               'nosound=true','[dosbox]',f'machine={machine}','memsize=16',
                               '[autoexec]',f'mount c "{work.resolve()}"','c:',
                               'RUNPROBE.EXE > OUT.TXT','exit'])+'\n')
    env=os.environ.copy();env.update(SDL_VIDEODRIVER='dummy',SDL_AUDIODRIVER='dummy')
    p=subprocess.run([runner,'-conf',str(conf),'-fastlaunch','-exit','-nopromptfolder'],
                     cwd=work,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,
                     timeout=20,**toolchain._no_window())
    log=(work/'OUT.TXT').read_text(encoding='latin1').replace('\r','')
    print(machine,log,sep='\n')
    records={line.split()[0]:[int(v) for v in line.split()[1:]] for line in log.splitlines()}
    records['lowram_sha256']=hashlib.sha256((work/'LOWRAM.BIN').read_bytes()).hexdigest()
    records['exit_code']=p.returncode;results[machine]=records
(WORK/'build/bios-reference/replies.json').write_text(json.dumps(results,indent=2)+'\n')
