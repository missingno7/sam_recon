"""Check every composed frame during real mission and title/credits scrolling.

Uses ordinary scripted controls and scanout diagnostics, never game-memory edits.
Each invocation copies disposable data without CFG so player controls/settings do
not affect this regression. --exe can point at an older build as a negative test.
"""
from pathlib import Path
import argparse
import csv
import json
import os
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--exe', type=Path, required=True)
    ap.add_argument('--data', type=Path, default=ROOT/'assets')
    ap.add_argument('--output', type=Path, default=ROOT/'build/scroll-checks')
    ap.add_argument('--adapters', default='vga,ega')
    a = ap.parse_args()
    out = a.output.resolve(); out.mkdir(parents=True, exist_ok=True)
    data = out/'data'; data.mkdir(exist_ok=True)
    for source in a.data.iterdir():
        if source.suffix.upper() not in ('.EXE', '.CFG') and source.is_file():
            shutil.copyfile(source, data/source.name)
    env = os.environ.copy()
    env['PATH'] = 'C:/tools/sdl3-3.4.16-mingw/SDL3-3.4.16/x86_64-w64-mingw32/bin;'+env.get('PATH', '')
    checks = []
    for adapter in a.adapters.split(','):
        assert adapter in ('vga', 'ega')
        for name in ('mission', 'title-credits'):
            work = out/(adapter+'-'+name); work.mkdir(exist_ok=True)
            script = work/'input.script'
            script.write_text((ROOT/'port/tests/scroll.script').read_text() if name == 'mission'
                              else '1500 key space\n4000 shot title.png\n6500 shot credits.png\n16000 quit\n')
            env['SAM_DIAG_SCANOUT'] = str(work/'frames.csv')
            command = [str(a.exe.resolve()), '--episode', '2', '--data', str(data), '--headless',
                       '--no-audio', '--'+adapter, '--script', str(script), '--settings', str(work/'sam.json')]
            p = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, timeout=25)
            (work/'stdout.txt').write_bytes(p.stdout); (work/'stderr.txt').write_bytes(p.stderr)
            rows = [{k: int(v) if k != 'adapter' else v for k, v in row.items()}
                    for row in csv.DictReader((work/'frames.csv').open())]
            result = {'adapter': adapter, 'scenario': name, 'command': command,
                      'ok': p.returncode == 0, 'windows': []}
            if name == 'mission':
                for direction, lo, hi, sign in [('right', 16500000, 21000000, 1),
                                              ('left', 21500000, 25000000, -1)]:
                    samples = [r for r in rows if lo < r['emu_us'] < hi and r['mode'] == 13]
                    bad = [{'time': b['emu_us'], 'from': x['x'], 'to': b['x']}
                           for x, b in zip(samples, samples[1:]) if (b['x']-x['x'])*sign < 0]
                    span = (samples[-1]['x']-samples[0]['x'])*sign if samples else 0
                    result['windows'].append({'direction': direction, 'frames': len(samples),
                                              'span': span, 'backwards': bad})
                    result['ok'] &= len(samples) > 200 and span >= 100 and not bad
            else:
                samples = [r for r in rows if r['emu_us'] > 2200000 and r['mode'] == 13]
                delta = [b['y']-x['y'] for x, b in zip(samples, samples[1:])]
                steps = [d for d in delta if d]
                # At most one scanline per displayed frame; reversals only at
                # the ends of the 200-line title/credits virtual screen.
                bad = [{'time': b['emu_us'], 'from': x['y'], 'to': b['y']}
                       for x, b in zip(samples, samples[1:]) if abs(b['y']-x['y']) > 1]
                turns = [(x, b) for x, b in zip(steps, steps[1:]) if x*b < 0]
                positions = [r['y'] for r in samples]
                at_end = all(r['y'] in (0, 200) for i, r in enumerate(samples[1:-1], 1)
                             if (r['y']-samples[i-1]['y'])*(samples[i+1]['y']-r['y']) < 0)
                # Check direction for the complete ascending and descending
                # runs, retaining repeated frames and both end pauses.
                last_sign = 0
                for i, d in enumerate(delta):
                    if d and last_sign*d < 0 and samples[i]['y'] not in (0, 200): at_end = False
                    if d: last_sign = d
                result['windows'].append({'frames': len(samples), 'range': [min(positions), max(positions)],
                                          'up_steps': sum(d > 0 for d in delta),
                                          'down_steps': sum(d < 0 for d in delta), 'turns': len(turns),
                                          'backwards_or_skipped': bad})
                result['ok'] &= not bad and at_end and min(positions) == 0 and max(positions) == 200
                result['ok'] &= sum(d < 0 for d in delta) >= 200 and sum(d > 0 for d in delta) >= 200
            result['ok'] = bool(result['ok']); checks.append(result)
            print(adapter, name, 'PASS' if result['ok'] else 'FAIL', result['windows'], flush=True)
    (out/'checks.json').write_text(json.dumps(checks, indent=2)+'\n')
    return 0 if all(c['ok'] for c in checks) else 1


if __name__ == '__main__':
    raise SystemExit(main())
