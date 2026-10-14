"""Paths usable both in the worker staging tree and after supervisor merge."""
from pathlib import Path

CODE_ROOT=Path(__file__).resolve().parents[1]
ROOT=next(p for p in Path(__file__).resolve().parents
          if (p/'game/SAM.PAS').is_file() and (p/'port/pc/pc.h').is_file())
WORK=CODE_ROOT
CORPUS=CODE_ROOT/'tests/port/semantics'
