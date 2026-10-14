"""Compare the pinned TP5 ERASE program under two independent DOS hosts."""
from pathlib import Path
import shutil
import sys
from pas2c_paths import ROOT,WORK
sys.dont_write_bytecode=True
sys.path.insert(0,str(ROOT/'tools'))
import toolchain
from probe import run

source=WORK/'tests/port/semantics/ERASE.PAS'
dos=WORK/'build/erase-reference/player'
print('MS-DOS Player:',repr(run(source,dos,runner='player').replace('\r','')))
box=WORK/'build/erase-reference/dosbox'
box.mkdir(parents=True,exist_ok=True)
shutil.copyfile(dos/'ERASE.EXE',box/'TPPROBE.EXE')
rc,argv=toolchain.run_dosbox(box,['TPPROBE.EXE > OUT.TXT'],timeout=20)
print('DOSBox-X return',rc)
print('DOSBox-X:',repr((box/'OUT.TXT').read_text(encoding='latin1').replace('\r','')))
