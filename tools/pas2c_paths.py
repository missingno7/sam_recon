"""Paths usable both in the worker staging tree and after supervisor merge."""
from pathlib import Path
CODE_ROOT = Path(__file__).resolve().parents[1]
# A worker snapshot contains game/ too. Canonical check helpers and test assets
# belong to the enclosing checkout; a source archive can use CODE_ROOT directly.
ROOT = next(
    (p for p in Path(__file__).resolve().parents
     if (p / 'game/SAM.PAS').is_file() and (p / 'port/pc/pc.h').is_file()
     and (p / '.git').exists()),
    CODE_ROOT,
)
WORK = CODE_ROOT
CORPUS = CODE_ROOT / 'tests/port/semantics'
