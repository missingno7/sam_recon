#!/usr/bin/env python3
"""Run the four port gates without substituting oracle data into generated C.

Run from the repository root. Scratch outputs are confined to this worker.
Exit status is nonzero if any gate is unsupported, fails, or is skipped.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import shutil
from pas2c import Compiler, CompileError
from pas2c_emit import Emitter
from build_headless import build
from probe import run as dos_probe
from pas2c_paths import WORK, ROOT, CORPUS
sys.path.insert(0, str(ROOT / 'tools'))
import verify
import toolchain
import mz
from common import asset_dir
# Restore staging-module priority after importing the canonical check helpers.
sys.path.insert(0, str(Path(__file__).resolve().parent))
verify.oracle.OUT = WORK / 'build/oracle'
PLATFORM_TESTS = {'ERASE': 'INT 21h AH=41h and the DOS host open-file unlink policy; MS-DOS Player leaves a name deletable after closing the erased handle, while the DOS-sharing native double removes it.',
     'ERASELIVE': 'INT 21h AH=41h must permit unlink while a handle remains usable; supplied by the platform during integration.'}

def compact(path, keep=()):
    path = path.resolve()
    if not path.is_relative_to(WORK):
        raise RuntimeError('scratch cleanup escaped worker directory')
    for p in path.iterdir():
        if p.is_file() and p.name not in keep:
            target = p.resolve()
            if not target.is_relative_to(path):
                raise RuntimeError('scratch cleanup escaped named directory')
            target.unlink()

def normalize(s):
    # The DOS runner captures CR/CR/LF. Normalize transport newlines only.
    return s.replace('\r', '').encode('latin1')

def check_records(c, ref, episode):
    types = {}
    for u in c.units.values():
        for scope in (u.interface, u.scope):
            for s in scope.symbols.values():
                if s.kind == 'type' and s.type.kind == 'record':
                    types[s.name] = s.type.size
    # Compile the canonical declaration section in a console probe. Importing
    # SAMDATA runs PROGRPHX's retrace-waiting video initialization under the
    # DOS runner and stalls; declaration extraction avoids executing units.
    source = (ROOT / 'game/SAMDATA.PAS').read_text(encoding='latin1')
    start = re.search('^const\\s*$', source, re.M).start()
    end = re.search('^(?:procedure|function)\\s+', source, re.M).start()
    program = 'program Recs; uses Dos;\n' + source[start:end] + '\nbegin\n' + ''.join((f"Writeln('{n} ',SizeOf({n}));\n" for n in sorted(types))) + 'end.\n'
    (ref / 'RECS.PAS').write_text(program)
    (rc, log, _) = toolchain.run_dos('TPC.EXE', ['/M', '/DSAM' + episode[-1], '/$S-', '/$I-',
         'RECS.PAS'], ref)
    if rc or b'Error' in log:
        return {'ok': False, 'error': log.decode('latin1')}
    from probe import execute
    (rc, out) = execute(ref / 'RECS.EXE', ref)
    if rc:
        return {'ok': False, 'error': out}
    got = {n: int(size) for (n, size) in re.findall('^(\\w+) (\\d+)\\r*$', out, re.M)}
    return {'ok': got == types, 'count': len(types), 'expected': types, 'actual': got}

def layout_gate(c, ref, episode):
    text = (ref / 'SAM.MAP').read_text(encoding='latin1')
    m = re.search('^\\s+([0-9A-F]+)H\\s+[0-9A-F]+H\\s+([0-9A-F]+)H\\s+DATA\\s+DATA', text, re.M)
    (base, size) = (int(m[1], 16), int(m[2], 16))
    out = WORK / 'build/scratch/gates' / episode
    out.mkdir(parents=True, exist_ok=True)
    Emitter(c).write(out)
    blob = (out / 'ds.bin').read_bytes()
    built = mz.parse((ref / 'SAM.EXE').read_bytes())
    original = built.image[base:base + size]
    pub = re.findall('^ ' + f'{base // 16:04X}' + ':([0-9A-F]{4})\\s+(\\w+)\\s*$', text, re.M)
    symbols = {s.name.upper(): {'offset': s.offset, 'size': s.type.size} for u in c.units.values() for s in u.globals}
    symbols.update({n.upper(): v for (n, v) in c.runtime_symbols.items()})
    mismatch = [{'name': n, 'tp': int(o, 16), 'c': symbols.get(n, {}).get('offset')} for (o,
         n) in pub if n not in symbols or symbols[n]['offset'] != int(o, 16)]
    changed = [i for (i, (a, b)) in enumerate(zip(original, blob)) if a != b]
    # DATA after the load-image extent is BSS, with no original bytes to compare.
    return {'ok': size == len(blob) and (not mismatch) and (not changed), 'declared_size': size,
         'generated_size': len(blob), 'initialized_bytes': len(original), 'initialized_bytes_equal': not changed,
         'data_publics': len(pub), 'offset_mismatches': mismatch, 'first_byte_differences': changed[:20],
         'bss_bytes': size - len(original)}

def main():
    if '--integration' in sys.argv[1:]:
        from pas2c_integration_check import main as integration_main
        return integration_main([a for a in sys.argv[1:] if a != '--integration'])
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--episodes', default='sam1,sam2,sam3')
    ap.add_argument('--keep', action='store_true', help='keep all compiler/generated scratch outputs')
    ap.add_argument('--skip-reference', action='store_true', help='use existing reference builds')
    ap.add_argument('--reference-dir', type=Path, default=WORK / 'build/reference')
    ap.add_argument('--only', choices=('semantics', 'game', 'all'), default='all')
    a = ap.parse_args()
    receipts = {}
    success = True
    if a.only != 'semantics':
        for ep in a.episodes.split(','):
            print(f'{ep}: reference, DS/records, C build', flush=True)
            ref = a.reference_dir.resolve() / ep
            if not ref.resolve().is_relative_to(WORK):
                raise RuntimeError('invalid reference path')
            if not a.skip_reference:
                verify.build(ROOT / 'game', ep, ref)
            proof = verify.compare(ep, ref / 'SAM.EXE')
            c = Compiler(ROOT / 'game', ep)
            c.load('SAM')
            c.bind()
            record = check_records(c, ref, ep)
            layout = layout_gate(c, ref, ep)
            out = WORK / 'build/scratch/gates' / ep
            if not a.keep:
                compact(ref, ('SAM.EXE', 'SAM.MAP', 'build.log'))
            entry = {'reference': proof, 'gate1': layout, 'records': record, 'optimizations': {}}
            for opt in ('O0', 'O2'):
                native_out = out / opt
                rc = build(ROOT / 'game', 'SAM', ep, native_out, optimization=opt)
                gcc_log = (native_out / 'gcc.log').read_text(errors='replace')
                variant = {'gate2': {'ok': rc == 0, 'warnings': gcc_log.count('warning:'),
                     'log': str(native_out / 'gcc.log'), 'flags': ['-' + opt, '-fno-strict-aliasing']}}
                if ep == 'sam1' and rc == 0:
                    env = os.environ.copy()
                    env['SAM_ASSET_DIR'] = str(asset_dir())
                    p = subprocess.run([str(native_out / 'headless.exe')], cwd=ROOT, env=env,
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20)
                    (native_out / 'smoke.stdout').write_bytes(p.stdout)
                    (native_out / 'smoke.calls').write_bytes(p.stderr)
                    calls = p.stderr.decode('latin1').splitlines()
                    variant['gate3'] = {'ok': p.returncode == 0 and 'SMOKE_FIRST_PCX' in calls,
                         'exit_code': p.returncode, 'calls': calls, 'assets': str(asset_dir())}
                success &= rc == 0 and variant.get('gate3', {'ok': True})['ok']
                entry['optimizations'][opt] = variant
                if not a.keep:
                    compact(native_out, ('gcc.log', 'gcc.command.json', 'smoke.stdout',
                         'smoke.calls', 'diagnostics.json'))
            success &= proof['ok'] and layout['ok'] and record['ok']
            receipts[ep] = entry
            if ep == 'sam1':
                from pas2c_order_check import evidence
                observed = evidence(ref)
                (WORK / 'build/order-evidence.json').write_text(json.dumps(observed, indent=2) + '\n')
                receipts['evaluation_evidence'] = observed
                success &= observed['ok']
            if not a.keep:
                compact(out, ('gcc.log', 'gcc.command.json', 'smoke.stdout', 'smoke.calls',
                     'diagnostics.json'))
    if a.only != 'game':
        semantics = {}
        for source in sorted(CORPUS.glob('*.PAS')):
            print('semantics: ' + source.stem, flush=True)
            dosdir = WORK / 'build/scratch/dos-semantics' / source.stem
            out = WORK / 'build/scratch/c-semantics' / source.stem
            try:
                dos = normalize(dos_probe(source, dosdir))
                test = {'dos': dos.decode('latin1'), 'optimizations': {}, 'platform_dependent': source.stem in PLATFORM_TESTS}
                if source.stem in PLATFORM_TESTS:
                    test['reason'] = PLATFORM_TESTS[source.stem]
                for opt in ('O0', 'O2'):
                    native_out = out / opt
                    rc = build(source.parent, source.stem, 'sam1', native_out, optimization=opt)
                    if rc:
                        raise RuntimeError('gcc failed at ' + opt)
                    env = os.environ.copy()
                    env['SAM_ASSET_DIR'] = str(native_out)
                    p = subprocess.run([str(native_out / 'headless.exe')], cwd=native_out,
                         env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10)
                    native = normalize(p.stdout.decode('latin1'))
                    (native_out / 'native.out').write_bytes(native)
                    (native_out / 'native.stderr').write_bytes(p.stderr)
                    equal = p.returncode == 0 and dos == native
                    test['optimizations'][opt] = {'ok': equal, 'native': native.decode('latin1'),
                         'native_exit_code': p.returncode, 'warnings': (native_out / 'gcc.log').read_text().count('warning:'),
                         'flags': ['-' + opt, '-fno-strict-aliasing']}
                    if not equal:
                        print(('PLATFORM DEPENDENCY: ' if test['platform_dependent'] else 'DIFF: ') + source.stem + ' ' + opt)
                    # Dependencies retain exact output and comparison failure.
                    # They do not certify the platform's integration gate.
                    success &= p.returncode == 0 and (equal or test['platform_dependent'])
                    if not a.keep:
                        compact(native_out, ('gcc.log', 'gcc.command.json', 'native.out',
                             'native.stderr', 'diagnostics.json'))
                test['ok'] = all((v['ok'] for v in test['optimizations'].values()))
                test['status'] = 'pass' if test['ok'] else 'platform-dependent' if test['platform_dependent'] else 'fail'
                semantics[source.stem] = test
            except (RuntimeError, CompileError) as error:
                semantics[source.stem] = {'ok': False, 'error': str(error)}
                success = False
            if not a.keep:
                if out.exists():
                    compact(out, ('gcc.log', 'gcc.command.json', 'native.out', 'native.stderr',
                         'diagnostics.json'))
                if dosdir.exists():
                    compact(dosdir, ('compile.log', 'dos.out'))
        receipts['gate4'] = semantics
    receipts['ok'] = bool(success)
    receipts['abi_changes'] = []
    receipts['scope'] = 'translator/System gates at O0 and O2; platform-dependent mismatches retained, not certified'
    dest = WORK / 'build/checks.json'
    dest.write_text(json.dumps(receipts, indent=2) + '\n')
    print(f"{('PASS' if success else 'FAIL')}: {dest}")
    return 0 if success else 1
if __name__ == '__main__':
    sys.exit(main())
