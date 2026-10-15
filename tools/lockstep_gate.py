"""Build the optional lockstep target and run every scenario strictly.

Requires the pinned DOS reference build for SAM.MAP; ordinary port builds do not.
Each scenario JSON can restrict its episodes; otherwise it runs on all three.
"""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import argparse
import json
import os
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]


def cmake_command():
    found = shutil.which('cmake')
    if found:
        return found
    matches = sorted(Path('C:/Program Files/Microsoft Visual Studio/2022').glob(
        '*/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe'))
    if matches:
        return str(matches[0])
    raise RuntimeError('CMake not found; put cmake on PATH')


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--jobs', type=int, default=3, help='concurrent scenarios (default 3)')
    ap.add_argument('--build', type=Path, default=ROOT/'build/lockstep')
    ap.add_argument('--output', type=Path, default=ROOT/'build/lockstep-gate')
    a = ap.parse_args(argv)
    if a.jobs < 1:
        ap.error('--jobs must be positive')
    a.build, a.output = a.build.resolve(), a.output.resolve()
    a.output.mkdir(parents=True, exist_ok=True)
    started = time.monotonic()
    receipt = {'ok':False, 'strict':True, 'commands':[], 'scenarios':[]}

    def command(label, argv):
        before = time.monotonic()
        with (a.output/(label+'.log')).open('w') as log:
            p = subprocess.run([str(x) for x in argv], cwd=ROOT,
                               stdout=log, stderr=subprocess.STDOUT)
        item = {'name':label, 'argv':[str(x) for x in argv], 'returncode':p.returncode,
                'wall_seconds':round(time.monotonic()-before,3)}
        receipt['commands'].append(item)
        print(label, 'PASS' if not p.returncode else 'FAIL', flush=True)
        return item

    try:
        cmake = cmake_command()
        if command('reference', [sys.executable,'-B','tools/prepare_reference.py'])['returncode']:
            raise RuntimeError('DOS reference build/check failed; see reference.log')
        configure = [cmake,'-S','port','-B',a.build,'-DSAM_LOCKSTEP=ON','-DSAM_OPTIMIZATION=2']
        if os.name == 'nt':
            configure += ['-G','MinGW Makefiles',
                '-DCMAKE_C_COMPILER=C:/msys64/mingw64/bin/gcc.exe',
                '-DCMAKE_MAKE_PROGRAM=C:/msys64/mingw64/bin/mingw32-make.exe']
        if command('configure',configure)['returncode'] or command('build',[
                cmake,'--build',a.build,'--target','sam_lockstep','-j'+str(a.jobs)])['returncode']:
            raise RuntimeError('lockstep target build failed')
        if command('regressions',[sys.executable,'-B','tools/lockstep_checks.py',a.build])['returncode']:
            raise RuntimeError('lockstep regressions failed')
        cases = []
        for path in sorted((ROOT/'tests/port/lockstep').glob('*.json')):
            script = json.loads(path.read_text())
            episodes = script.get('episodes',['sam1','sam2','sam3'])
            if not episodes or len(set(episodes)) != len(episodes) or any(ep not in ('sam1','sam2','sam3') for ep in episodes):
                raise ValueError(str(path)+': invalid episodes')
            for ep in episodes:
                cases.append((path,ep))
        if not cases:
            raise RuntimeError('no lockstep scenarios found')

        def scenario(case):
            path,ep = case
            label = path.stem+'-'+ep
            dest = a.output/label
            item = command(label,[sys.executable,'-B','tools/lockstep.py','--build',a.build,
                '--episode',ep,'--scenario',path,'--output',dest])
            p = dest/'comparison.json'
            result = json.loads(p.read_text()) if p.exists() else {}
            return dict(item,episode=ep,scenario=str(path.relative_to(ROOT)),
                ok=item['returncode']==0 and result.get('ok') is True,
                comparison=str(p),frames=len(result.get('frame_comparisons',[])))

        with ThreadPoolExecutor(max_workers=a.jobs) as pool:
            receipt['scenarios'] = list(pool.map(scenario,cases))
        receipt['ok'] = all(item['ok'] for item in receipt['scenarios'])
    except (OSError, RuntimeError, ValueError) as error:
        receipt['error'] = str(error)
    receipt['wall_seconds'] = round(time.monotonic()-started,3)
    (a.output/'checks.json').write_text(json.dumps(receipt,indent=2)+'\n')
    print('PASS' if receipt['ok'] else 'FAIL', 'strict lockstep:',
          len(receipt['scenarios']), 'runs,',receipt['wall_seconds'],'seconds;',a.output/'checks.json')
    return 0 if receipt['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
