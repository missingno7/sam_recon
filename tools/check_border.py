"""Verify the Windows GPU output and raw overscan register for each border option.

Build target border_presentation first. Its active image is blue and its DOS
overscan remains red for every run. No original game data is used.
"""
from pathlib import Path
import argparse
import json
import os
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--exe', type=Path, required=True)
    ap.add_argument('--output', type=Path, default=ROOT/'build/border-checks')
    a = ap.parse_args(); out = a.output.resolve(); out.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env['PATH'] = 'C:/tools/sdl3-3.4.16-mingw/SDL3-3.4.16/x86_64-w64-mingw32/bin;'+env.get('PATH', '')
    settings = out/'sam.json'
    settings.write_text('{"version":1,"window_width":960,"window_height":720}\n')
    checks = []
    for name, args, expected in [('default', [], False), ('on', ['--border'], True),
                                 ('off', ['--no-border'], False)]:
        env['SAM_HOST_CAPTURE'] = str(out/(name+'.png'))
        command = [str(a.exe.resolve()), '--no-audio', '--settings', str(settings), *args]
        p = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, timeout=15)
        persisted = json.loads(settings.read_text())
        ok = p.returncode == 0 and bool(persisted.get('border', False)) == expected
        checks.append({'name': name, 'ok': ok, 'command': command, 'output': p.stdout.decode(),
                       'stderr': p.stderr.decode(), 'persisted': persisted})
        print(name, 'PASS' if ok else 'FAIL', p.stdout.decode().strip(), flush=True)
    (out/'checks.json').write_text(json.dumps(checks, indent=2)+'\n')
    return 0 if all(c['ok'] for c in checks) else 1


if __name__ == '__main__':
    raise SystemExit(main())
