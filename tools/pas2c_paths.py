"""Paths usable both in the worker staging tree and after supervisor merge."""
from pathlib import Path
CODE_ROOT = Path(__file__).resolve().parents[1]
# A tracked-file snapshot is self-contained, even inside another Git checkout.
# Its checks and all derived output must use its own sources and build directory.
ROOT = next(
    (p for p in Path(__file__).resolve().parents
     if (p / 'game/SAM.PAS').is_file() and (p / 'port/pc/pc.h').is_file()),
    CODE_ROOT,
)
WORK = CODE_ROOT
CORPUS = CODE_ROOT / 'tests/port/semantics'
