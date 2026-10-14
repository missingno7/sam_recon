"""Build a fresh port with DOS imports, executables and MAP reads denied.

The guard applies to every Python process CMake starts. It is a check-only
environment, not a dependency or a policy in the compiler itself.
"""
from pathlib import Path
import json
import os
import subprocess
import sys
from pas2c_paths import WORK

CMAKE = Path(
    'C:/Program Files/Microsoft Visual Studio/2022/Community/Common7/IDE/'
    'CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe'
)

GUARD = '''import builtins
import os
from pathlib import Path
import subprocess

with open(os.environ['PAS2C_GUARD_LOG'], 'a') as log:
    log.write('guard active\\n')

original_import = builtins.__import__
def guarded_import(name, *args, **kwargs):
    if name.split('.')[-1] in {'toolchain', 'verify', 'oracle', 'probe', 'capstone', 'unicorn'}:
        raise RuntimeError('DOS-free build attempted import: ' + name)
    return original_import(name, *args, **kwargs)
builtins.__import__ = guarded_import

original_read = Path.read_text
def guarded_read(self, *args, **kwargs):
    if self.suffix.upper() == '.MAP' or self.name == 'toolchain.json':
        raise RuntimeError('DOS-free build attempted reference read: ' + str(self))
    return original_read(self, *args, **kwargs)
Path.read_text = guarded_read

original_popen = subprocess.Popen
class GuardedPopen(original_popen):
    def __init__(self, args, *positional, **keywords):
        command = args[0] if isinstance(args, (list, tuple)) else args
        name = Path(str(command)).name.lower()
        if name in {'tpc.exe', 'tasm.exe', 'msdos.exe', 'dosbox-x.exe'}:
            raise RuntimeError('DOS-free build attempted executable: ' + name)
        super().__init__(args, *positional, **keywords)
subprocess.Popen = GuardedPopen
'''

def main():
    guard = WORK / 'build/no-dos-guard'
    guard.mkdir(parents=True, exist_ok=True)
    (guard / 'sitecustomize.py').write_text(GUARD)
    guard_log = guard / 'guard.log'
    guard_log.write_text('')
    env = os.environ.copy()
    env['PYTHONPATH'] = str(guard)
    env['PAS2C_GUARD_LOG'] = str(guard_log)
    build = WORK / 'build/no-dos-port'
    commands = [
        [CMAKE, '-S', WORK / 'port', '-B', build, '-G', 'MinGW Makefiles',
         '-DCMAKE_C_COMPILER=C:/msys64/mingw64/bin/gcc.exe',
         '-DCMAKE_MAKE_PROGRAM=C:/msys64/mingw64/bin/mingw32-make.exe',
         '-DSAM_OPTIMIZATION=2'],
        [CMAKE, '--build', build, '--clean-first', '-j4'],
    ]
    results = []
    for number, command in enumerate(commands):
        process = subprocess.run([str(arg) for arg in command], env=env,
                                 stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (guard / f'step{number}.log').write_bytes(process.stdout)
        results.append({'command':[str(arg) for arg in command], 'exit_code':process.returncode})
        if process.returncode:
            print(process.stdout.decode(errors='replace'))
            break
    checks = {'ok':all(result['exit_code']==0 for result in results) and len(results)==2,
              'commands':results, 'guarded_python_processes':len(guard_log.read_text().splitlines())}
    checks['ok'] &= checks['guarded_python_processes']>0
    (WORK / 'build/no-dos-checks.json').write_text(json.dumps(checks, indent=2)+'\n')
    print('PASS' if checks['ok'] else 'FAIL', 'DOS-free configure/build')
    return 0 if checks['ok'] else 1

if __name__=='__main__':
    raise SystemExit(main())
