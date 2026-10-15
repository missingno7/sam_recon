"""Real Windows presentation regression: delayed vsync cannot hold the PC clock."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import struct
import subprocess
import tempfile
from check_boot import EPISODE_EXPECTED
ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--exe',type=Path,default=ROOT/'build/release/sam.exe')
    a=ap.parse_args();parent=ROOT/'build/host-checks';parent.mkdir(parents=True,exist_ok=True)
    output=Path(tempfile.mkdtemp(prefix='run-',dir=parent));checks=[]
    for name,delay in (('normal',0),('stalled',100)):
        work=output/name;work.mkdir()
        script=work/'input.script'
        script.write_text('800 shot apo.png\n1500 key space\n2200 shot title.png\n2400 quit\n')
        env=os.environ.copy();env['PATH']='C:/tools/sdl3-3.4.16-mingw/SDL3-3.4.16/x86_64-w64-mingw32/bin;'+env.get('PATH','')
        env.update(SAM_HOST_PRESENT_DELAY_MS=str(delay),SAM_HOST_CAPTURE=str(work/'host.png'),
                   SAM_HOST_METRICS=str(work/'metrics.jsonl'))
        command=[str(a.exe.resolve()),'--episode','2','--data',str(ROOT/'assets'),'--no-audio',
                 '--script',str(script),'--realtime-script','--settings',str(work/'sam.json')]
        p=subprocess.run(command,env=env,cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=20)
        (work/'stdout.txt').write_bytes(p.stdout);(work/'stderr.txt').write_bytes(p.stderr)
        text=p.stdout.decode(errors='replace');match=re.search(r'time_us=(\d+) irq0=(\d+) irq1=(\d+)',text)
        ok=p.returncode==0 and match is not None and (int(match[2]),int(match[3]))==(336,2)
        for kind in ('apo','title'):
            ok &= hashlib.sha256((work/(kind+'.png')).read_bytes()).hexdigest()==EPISODE_EXPECTED[2][kind]
        host=work/'host.png'
        dimensions=struct.unpack('>II',host.read_bytes()[16:24]) if host.exists() else None
        counters=[json.loads(line) for line in (work/'metrics.jsonl').read_text().splitlines()]
        presents=counters[-1]['present'];ok &= dimensions==(960,720) and presents>0
        checks.append({'name':name,'ok':bool(ok),'command':command,'output':text,
                       'host_dimensions':dimensions,'presents':presents})
        print(name,'PASS' if ok else 'FAIL',text.strip(),flush=True)
    receipt={'ok':all(c['ok'] for c in checks),'checks':checks}
    (output/'checks.json').write_text(json.dumps(receipt,indent=2)+'\n');(parent/'latest.txt').write_text(str(output)+'\n')
    print(output);return 0 if receipt['ok'] else 1
if __name__=='__main__':raise SystemExit(main())
