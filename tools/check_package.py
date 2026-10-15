"""Unpack a release into fresh folders; use original data only as local test input."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import tempfile
import zipfile
from check_boot import EPISODE_EXPECTED

ROOT = Path(__file__).resolve().parents[1]
ALLOW = {'sam.exe','SDL3.dll','README.txt','NOTICES.txt','LICENSE-SDL3.txt','LICENSE-FONTS.txt'}

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('zip', nargs='?', type=Path, default=ROOT/'build/releases/sam-windows-x64.zip')
    ap.add_argument('--window', action='store_true', help='also exercise a visible wall-clock run')
    a = ap.parse_args(argv)
    parent = ROOT/'build/package-checks'; parent.mkdir(parents=True,exist_ok=True)
    output = Path(tempfile.mkdtemp(prefix='run-', dir=parent))
    cases = []
    with zipfile.ZipFile(a.zip) as archive:
        assert set(archive.namelist()) == ALLOW, archive.namelist()
        def folder(name, episodes):
            dest = output/name; dest.mkdir(); archive.extractall(dest)
            for p in (ROOT/'assets').iterdir():
                if p.suffix.upper() in ('.EXE','.CFG'): continue
                if any(p.name.upper().startswith('SAM'+str(ep)) for ep in episodes):
                    shutil.copyfile(p,dest/p.name)
            return dest
        def run(name, episodes, script, args=(), expected=0, window=False, omit=()):
            dest = folder(name,episodes)
            for filename in omit:
                (dest/filename).unlink()
            script_path = dest/'test.script'; script_path.write_text(script)
            # An unrelated cwd and a PATH without the SDL installation verify relocation.
            env = os.environ.copy()
            env['PATH'] = os.environ.get('SystemRoot','C:/Windows')+'/System32'
            command = [str(dest/'sam.exe'),'--no-audio','--script',str(script_path),*args]
            command += ['--realtime-script'] if window else ['--headless']
            p = subprocess.run(command,cwd=output,env=env,stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE,timeout=35)
            (dest/'stdout.txt').write_bytes(p.stdout); (dest/'stderr.txt').write_bytes(p.stderr)
            result = {'name':name,'command':command,'returncode':p.returncode,
                      'stdout':p.stdout.decode(errors='replace'),'stderr':p.stderr.decode(errors='replace'),
                      'captures':{f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in dest.glob('*.png')}}
            cases.append(result)
            assert p.returncode == expected, result
            print(name, 'exit',p.returncode,flush=True)
            return dest,result
        try:
            for ep in (1,2,3):
                script = f'100 shot chooser.png\n250 key {ep}\n1050 shot apo.png\n1750 key space\n2450 shot title.png\n2650 quit\n'
                dest,r = run('choose-'+str(ep),(1,2,3),script)
                assert 'LAUNCHER episodes=123' in r['stdout'] and f'LAUNCH episode={ep}' in r['stdout']
                assert r['captures']['title.png'] == EPISODE_EXPECTED[ep]['title'],r
                assert r['captures']['apo.png'] == EPISODE_EXPECTED[ep]['apo'],r
            for ep in (1,2,3):
                dest,r = run('only-'+str(ep),(ep,),
                    '800 shot apo.png\n1500 key space\n2200 shot title.png\n2400 quit\n')
                assert 'LAUNCHER' not in r['stdout'] and f'LAUNCH episode={ep}' in r['stdout']
                assert r['captures']['title.png']==EPISODE_EXPECTED[ep]['title'],r
            dest,r = run('empty',(),'0 quit\n',expected=2)
            assert 'SAMN01.GFX' in r['stderr'] and 'SAM3B.END' in r['stderr']
            dest,r = run('partial',(1,2,3),
                '100 shot partial.png\n200 key 2\n400 quit\n',omit=('SAM203E.SND',))
            assert 'LAUNCHER episodes=13' in r['stdout'] and 'LAUNCH episode=' not in r['stdout'],r
            quit_script = ('800 shot apo.png\n1500 key space\n2200 shot title.png\n'
                           '2500 key space\n3250 key q\n4000 key y\n6300 shot returned.png\n7000 quit\n')
            dest,r = run('only-return',(2,),quit_script)
            assert r['stdout'].count('LAUNCH episode=2')==1 and 'LAUNCHER episodes=2' in r['stdout'],r
            dest,r = run('direct-quit',(1,),quit_script,args=('--episode','1'))
            assert 'LAUNCHER' not in r['stdout'] and 'returned.png' not in r['captures'],r
            dest,r = run('settings',(1,2,3),
                '100 shot chooser.png\n200 key s\n300 shot settings-before.png\n400 key i\n500 key m\n600 key w\n650 key b\n700 shot settings-after.png\n800 key escape\n900 shot chooser-after.png\n1000 quit\n')
            settings = json.loads((dest/'sam.json').read_text())
            assert settings['border'] is True and settings['scaling']=='fit' and settings['smooth'] is True and settings['window_width']==1280,settings
            # A later process loads the same file without passing any presentation switches.
            p = subprocess.run([str(dest/'sam.exe'),'--headless','--no-audio','--script',str(dest/'test.script')],
                               cwd=output,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=20)
            assert p.returncode==0
            settings2 = json.loads((dest/'sam.json').read_text())
            assert settings2['border'] is False and settings2['scaling']=='integer' and settings2['smooth'] is False and settings2['window_width']==640,settings2
            dest,r = run('border-switches',(1,2,3),'100 quit\n',args=('--border',))
            assert json.loads((dest/'sam.json').read_text())['border'] is True
            p = subprocess.run([str(dest/'sam.exe'),'--headless','--no-audio','--no-border',
                                '--script',str(dest/'test.script')], cwd=output,
                               stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=20)
            assert p.returncode==0 and json.loads((dest/'sam.json').read_text())['border'] is False
            events = ['100 shot chooser.png']
            for index,ep in enumerate((1,2,3,1)):
                start=250+index*6500
                events += [f'{start} key {ep}',f'{start+800} shot apo-{index}.png',
                    f'{start+1500} key space',f'{start+2200} shot title-{index}.png',
                    f'{start+2500} key space',f'{start+3250} key q',f'{start+4000} key y',
                    f'{start+6300} shot returned-{index}.png']
            events += ['26500 quit']
            dest,r = run('restart',(1,2,3),'\n'.join(events)+'\n')
            assert r['stdout'].count('LAUNCHER episodes=123')==5,r
            assert r['stdout'].count('LAUNCH episode=1')==2,r
            for index,ep in enumerate((1,2,3,1)):
                assert r['captures'][f'title-{index}.png']==EPISODE_EXPECTED[ep]['title'],r
                assert r['captures'][f'apo-{index}.png']==EPISODE_EXPECTED[ep]['apo'],r
            if a.window:
                dest,r = run('window',(1,2,3),
                    '100 shot chooser.png\n250 key 3\n1050 shot apo.png\n1750 key space\n2450 shot title.png\n2650 quit\n',window=True)
                assert r['captures']['title.png']==EPISODE_EXPECTED[3]['title'],r
            receipt={'ok':True,'cases':cases}
        except (AssertionError,OSError,subprocess.TimeoutExpired) as error:
            receipt={'ok':False,'cases':cases,'error':str(error)}
    (output/'checks.json').write_text(json.dumps(receipt,indent=2)+'\n')
    (parent/'latest.txt').write_text(str(output)+'\n')
    print('PASS' if receipt['ok'] else 'FAIL',output,flush=True)
    if not receipt['ok']:print(receipt['error'])
    return 0 if receipt['ok'] else 1

if __name__=='__main__':
    raise SystemExit(main())
