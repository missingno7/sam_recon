"""Build an O2 Windows release and zip an explicit, game-data-free allowlist."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SDL = Path('C:/tools/sdl3-3.4.16-mingw/SDL3-3.4.16/x86_64-w64-mingw32')

def cmake_command():
    found = shutil.which('cmake')
    if found:
        return found
    matches = sorted(Path('C:/Program Files/Microsoft Visual Studio/2022').glob(
        '*/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe'))
    if not matches:
        raise RuntimeError('CMake not found; put cmake on PATH or pass --cmake')
    return str(matches[0])

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--build-dir', type=Path, default=ROOT/'build/release')
    ap.add_argument('--output', type=Path, default=ROOT/'build/releases/sam-windows-x64.zip')
    ap.add_argument('--sdl-root', type=Path, default=DEFAULT_SDL)
    ap.add_argument('--cmake')
    ap.add_argument('--no-build', action='store_true', help='package an existing sam.exe')
    a = ap.parse_args(argv)
    if os.name != 'nt':
        ap.error('Windows packaging requires a Windows build; build sam with CMake on Linux')
    build, output, sdl = a.build_dir.resolve(), a.output.resolve(), a.sdl_root.resolve()
    commands = []
    if not a.no_build:
        cmake = a.cmake or cmake_command()
        configure = [cmake, '-S', str(ROOT/'port'), '-B', str(build), '-G', 'MinGW Makefiles',
                     '-DSAM_OPTIMIZATION=2', '-DSAM_LOCKSTEP=OFF', '-DSDL3_ROOT='+str(sdl)]
        mingw = Path('C:/msys64/mingw64/bin')
        if (mingw/'gcc.exe').exists():
            configure += ['-DCMAKE_C_COMPILER='+str(mingw/'gcc.exe'),
                          '-DCMAKE_MAKE_PROGRAM='+str(mingw/'mingw32-make.exe')]
        commands = [configure, [cmake, '--build', str(build), '--target', 'sam', '-j4']]
        for command in commands:
            subprocess.run(command, cwd=ROOT, check=True)
    release = ROOT/'port/release'
    files = {
        'sam.exe': build/'sam.exe',
        'SDL3.dll': sdl/'bin/SDL3.dll',
        'README.txt': release/'README.txt',
        'NOTICES.txt': release/'NOTICES.txt',
        'LICENSE-SDL3.txt': release/'LICENSE-SDL3.txt',
        'LICENSE-FONTS.txt': ROOT/'port/pc/fonts-LICENSE.txt',
    }
    for path in files.values():
        if not path.is_file():
            raise RuntimeError('Missing release input: '+str(path))
    output.parent.mkdir(parents=True, exist_ok=True)
    receipt = {'commands': commands, 'files': {}}
    with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, path in files.items():
            data = path.read_bytes()
            # Fixed archive metadata makes identical inputs yield an identical zip.
            item = zipfile.ZipInfo(name, (2026, 1, 1, 0, 0, 0))
            item.compress_type = zipfile.ZIP_DEFLATED
            item.external_attr = 0o644 << 16
            archive.writestr(item, data)
            receipt['files'][name] = {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
    receipt['zip_sha256'] = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix('.json').write_text(json.dumps(receipt, indent=2)+'\n')
    print(output)
    print('Contains sam.exe, SDL3.dll and notices only; no episode data or configuration.')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
