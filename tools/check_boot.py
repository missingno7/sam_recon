"""Boot every episode at both optimization levels with the real platform."""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import sys
from pas2c_paths import ROOT,WORK

EXPECTED={'apo':'5e511fd5f7f243bb64f442f2ddf18ccebb1cfaed55e1ddeac78efcda1acdb3db',
          'title':'9791f8eab772c946c04be938ed116115e74369abcb85764ad0cbe24276f87d27',
          'wav':'4ccd2215819c141b41e1ceb99b0f429fe9640548c65c9cbc88039afa83d0b48a'}
EPISODE_EXPECTED={
    1: EXPECTED,
    2: {**EXPECTED, 'title':'6339aeda3a880f6c5d208ea390847d46bec66d8e9604b44e3d53be38bf462ef5',
        'wav':'0319d9d80e1b9a066a7522d34307029ba1455ed1918ff467f6f5b17ec9f87a79'},
    3: {**EXPECTED, 'title':'333184c0e48c25ab035177f095031a00049ece259432919f2dd144976b7497b8',
        'wav':'0319d9d80e1b9a066a7522d34307029ba1455ed1918ff467f6f5b17ec9f87a79'}
}

def check(builds):
    captures=WORK/'build/captures';captures.mkdir(exist_ok=True)
    receipts={};env=os.environ.copy()
    env['PATH']='C:/tools/sdl3-3.4.16-mingw/SDL3-3.4.16/x86_64-w64-mingw32/bin;'+env.get('PATH','')
    for episode in range(1,4):
        variants={}
        for opt,build in zip(('o0','o2'),builds):
            stem=opt+'-sam'+str(episode)
            paths={kind:captures/(stem+('-'+kind+'.png' if kind!='wav' else '.wav')) for kind in EXPECTED}
            script=WORK/'build'/(stem+'.script')
            script.write_text(f'800 shot {paths["apo"]}\n1500 key space\n2200 shot {paths["title"]}\n2400 quit\n')
            args=[str(build/'sam.exe'),'--episode',str(episode),'--data',str(ROOT/'assets'),
                  '--headless','--script',str(script),'--wav',str(paths['wav'])]
            process=subprocess.run(args,cwd=build,env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=20)
            (WORK/'build'/(stem+'.stdout')).write_bytes(process.stdout)
            (WORK/'build'/(stem+'.stderr')).write_bytes(process.stderr)
            hashes={kind:hashlib.sha256(path.read_bytes()).hexdigest() for kind,path in paths.items()}
            output=process.stdout.decode(errors='replace').strip()
            ok=process.returncode==0 and output==f'SAM{episode} exit=0 time_us=2400000 irq0=336 irq1=2'
            ok &= hashes==EPISODE_EXPECTED[episode]
            variants[opt]={'ok':ok,'exit_code':process.returncode,'output':output,'sha256':hashes,'command':args}
            print(stem,'PASS' if ok else 'FAIL',output,flush=True)
        receipts['sam'+str(episode)]={'ok':all(v['ok'] for v in variants.values()) and variants['o0']['sha256']==variants['o2']['sha256'],
                                      'optimizations':variants}
    (WORK/'build/boot-checks.json').write_text(json.dumps(receipts,indent=2)+'\n')
    return receipts

if __name__=='__main__':
    checks=check([Path(p).resolve() for p in sys.argv[1:]])
    sys.exit(0 if len(sys.argv)==3 and all(v['ok'] for v in checks.values()) else 1)
