"""Compile/run a source-only semantic probe with the repository's pinned TP5."""
from pathlib import Path
import shutil
import sys

from pas2c_paths import ROOT, WORK
sys.dont_write_bytecode=True
sys.path.insert(0, str(ROOT / 'tools'))
import toolchain
import verify
# Restore staging-module priority after importing the canonical check helpers.
sys.path.insert(0, str(Path(__file__).resolve().parent))

def execute(executable: Path, work: Path, runner='dosbox'):
    work=work.resolve()
    if runner=='player':
        return verify._run(executable.resolve(), [], work, timeout=10)
    # A uniformly used FAT drive avoids localDrive::FileUnlink's Windows
    # fallback, which forcibly closes live DOS handles. No probe-specific
    # reference policy: execute every program on a fresh DOSBox-X FAT disk.
    if not work.is_relative_to(WORK.resolve()):
        raise RuntimeError('DOS reference scratch directory escaped worker')
    shutil.copyfile(executable,work/'RUNPROBE.EXE')
    image=work/'PROBE.IMA'
    if image.exists(): image.unlink()
    result=work/'RESULT.TXT'
    if result.exists(): result.unlink()
    commands=['IMGMAKE PROBE.IMA -t fd_1440 > MAKE.TXT',
              f'IMGMOUNT A "{image}" -t floppy > MOUNT.TXT',
              'COPY RUNPROBE.EXE A:\\RUNPROBE.EXE > COPY.TXT','A:',
              'RUNPROBE.EXE > RESULT.TXT','COPY RESULT.TXT C:\\RESULT.TXT','C:']
    rc,_=toolchain.run_dosbox(work,commands,timeout=20)
    if rc or not result.exists():
        raise RuntimeError('DOSBox-X FAT probe failed; inspect '+str(work/'dosbox.conf'))
    return rc,result.read_text(encoding='latin1')

def run(source: Path, work: Path, runner='dosbox'):
    work.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, work / source.name)
    shutil.copyfile(toolchain.tool('TURBO.TPL'), work / 'TURBO.TPL')
    rc, out, argv = toolchain.run_dos('TPC.EXE', ['/M', '/GD', '/$S-', '/$R-', '/$I-', '/$B-', source.name], work)
    (work / 'compile.log').write_bytes(out)
    if rc or b'Error' in out:
        raise RuntimeError(out.decode('latin1'))
    rc,out=execute(work/(source.stem+'.EXE'),work,runner)
    (work / 'dos.out').write_text(out, encoding='latin1')
    if rc:
        raise RuntimeError(out)
    return out

if __name__ == '__main__':
    p = Path(sys.argv[1]).resolve()
    print(run(p, WORK / 'build/scratch' / p.stem))
