"""Run all four gates and platform/boot checks in the reconciled test bed."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import subprocess
import sys
from pas2c_paths import WORK, ROOT
CMAKE = Path('C:/Program Files/Microsoft Visual Studio/2022/Community/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe')

def main(argv=None):
    default = WORK if (WORK / 'port/pc/platform.h').is_file() else WORK / 'integration'
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--stage', type=Path, default=default)
    args = parser.parse_args(argv)
    stage = args.stage.resolve()
    if not stage.is_relative_to(WORK):
        raise RuntimeError('integration stage escaped worker')
    build = stage / 'build'
    build.mkdir(exist_ok=True)
    env = os.environ.copy()
    temporary = build / 'tmp'
    temporary.mkdir(exist_ok=True)
    env['TMP'] = env['TEMP'] = str(temporary)
    env['PATH'] = 'C:/tools/sdl3-3.4.16-mingw/SDL3-3.4.16/x86_64-w64-mingw32/bin;' + env.get('PATH', '')
    commands = []

    def run(label, argv):
        print(label, flush=True)
        result = subprocess.run([str(a) for a in argv], cwd=ROOT, env=env, stdout=subprocess.PIPE,
             stderr=subprocess.STDOUT)
        log = build / (label + '.log')
        log.write_bytes(result.stdout)
        commands.append({'step': label, 'argv': [str(a) for a in argv], 'exit_code': result.returncode,
             'log': str(log)})
        print(result.stdout.decode(errors='replace').replace('\r', '')[-1800:], flush=True)
        if result.returncode:
            raise RuntimeError(label + ' failed; inspect ' + str(log))
    python = [sys.executable, '-B']
    try:
        run('no-dos-build', python + [stage / 'tools/pas2c_no_dos_check.py'])
        run('prepare-reference', python + [stage / 'tools/prepare_reference.py'])
        run('placement', python + [stage / 'tools/pas2c_placement_check.py'])
        builds = [build / 'o0', build / 'o2']
        for (opt, path) in zip((0, 2), builds):
            run('configure-o' + str(opt), [CMAKE, '-S', stage / 'port', '-B', path, '-G',
                 'MinGW Makefiles', '-DCMAKE_C_COMPILER=C:/msys64/mingw64/bin/gcc.exe', '-DCMAKE_MAKE_PROGRAM=C:/msys64/mingw64/bin/mingw32-make.exe',
                 '-DSAM_OPTIMIZATION=' + str(opt)])
            run('build-o' + str(opt), [CMAKE, '--build', path, '-j4'])
            run('ctest-o' + str(opt), [CMAKE.parent / 'ctest.exe', '--test-dir', path,
                 '--output-on-failure'])
        # Retain the declaration-derived double and its complete startup call
        # log alongside the real-platform boots and the full semantic corpus.
        run('stub-gates', python + [stage / 'tools/pas2c_check.py', '--only', 'game', '--skip-reference',
             '--reference-dir', build / 'reference', '--keep'])
        stub = json.loads((stage / 'build/checks.json').read_text())
        run('layout-real', python + [stage / 'tools/check_layout.py', *builds])
        for (opt, path) in zip((0, 2), builds):
            run('semantics-o' + str(opt), python + [stage / 'tools/check_semantics.py', path])
        run('boot-all', python + [stage / 'tools/check_boot.py', *builds])
        receipts = {'ok': True, 'scope': 'all episodes; stub and real platform; O0/O2; TP5 reference on DOSBox-X FAT',
             'no_dos_build': json.loads((build / 'no-dos-checks.json').read_text()),
             'placement': json.loads((build / 'placement-checks.json').read_text()), 'commands': commands,
             'stub_gates': stub, 'gate1': json.loads((build / 'layout-checks.json').read_text()), 'gate3': json.loads((build / 'boot-checks.json').read_text()),
             'gate4': {opt: json.loads((build / 'semantics' / opt / 'checks.json').read_text()) for opt in ('o0',
             'o2')}}
        receipts['gate2'] = {opt: {'ok': True, 'warnings': (build / ('build-' + opt + '.log')).read_text(errors='replace').count('warning:'),
             'flags': ['-std=c11', '-Wall', '-Wextra', '-Wpedantic', '-O' + opt[-1], '-fno-strict-aliasing']} for opt in ('o0',
             'o2')}
        receipts['source_sha256'] = {str(p.relative_to(stage)): hashlib.sha256(p.read_bytes()).hexdigest() for directory in ('tools',
             'port', 'tests/port/semantics') for p in sorted((stage / directory).rglob('*')) if p.is_file() and '__pycache__' not in p.parts}
        receipts['abi_changes_from_integrated_snapshot'] = []
    except RuntimeError as error:
        receipts = {'ok': False, 'commands': commands, 'error': str(error)}
    (stage / 'build/integration-checks.json').write_text(json.dumps(receipts, indent=2) + '\n')
    if stage != WORK:
        (WORK / 'build/integration-checks.json').write_text(json.dumps(receipts, indent=2) + '\n')
    print('PASS' if receipts['ok'] else 'FAIL', stage / 'build/integration-checks.json', flush=True)
    return 0 if receipts['ok'] else 1
if __name__ == '__main__':
    sys.exit(main())
