"""Shared paths, hashing and atomic file helpers.

Nothing here knows about Secret Agent; everything game-specific lives in the
layout/ JSON files that the other tools read.
"""
from __future__ import annotations

import hashlib
import json
import os
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
_VENDOR = ROOT / "build" / "python"          # tools/setup_env.py: pinned capstone/unicorn
if _VENDOR.is_dir() and str(_VENDOR) not in sys.path:
    sys.path.insert(0, str(_VENDOR))
TOOLS = ROOT / "tools"
LAYOUT = ROOT / "layout"
EVIDENCE = ROOT / "evidence"
RECIPES = ROOT / "recipes"
SRC = ROOT / "src"
INCLUDE = ROOT / "include"
BUILD = ROOT / "build"
STATE = ROOT / "state"
EPISODES = ("sam1", "sam2", "sam3")


def asset_dir() -> Path:
    return Path(os.environ.get("SAM_ASSET_DIR", ROOT / "assets"))


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256(Path(path).read_bytes())


def canonical_json(value) -> str:
    """Stable JSON used for every committed or content-addressed document."""
    return json.dumps(value, indent=1, sort_keys=True, ensure_ascii=True) + "\n"


def content_key(value) -> str:
    return sha256(json.dumps(value, sort_keys=True, separators=(",", ":")).encode())


def load_json(path: Path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def atomic_bytes(path: Path, data: bytes) -> None:
    """mkstemp + fsync + os.replace, retrying Windows sharing violations."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=".tmp-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        for attempt in range(50):
            try:
                os.replace(tmp, path)
                return
            except PermissionError:
                if attempt == 49:
                    raise
                time.sleep(0.05 * (attempt + 1))
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)


def atomic_json(path: Path, value) -> None:
    atomic_bytes(path, canonical_json(value).encode("ascii"))


def rel(path: Path) -> str:
    try:
        return Path(path).resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return Path(path).as_posix()


def tree_hash(paths) -> str:
    """Hash of (relative path, bytes) for a set of files; used for input
    identities that make a stale receipt detectable."""
    h = hashlib.sha256()
    for p in sorted(Path(x) for x in paths):
        h.update(rel(p).encode() + b"\0")
        h.update(sha256_file(p).encode() + b"\n")
    return h.hexdigest()


def tool_identity() -> str:
    """Identity of the proof-relevant tool code (not tests/docs)."""
    names = ("common.py", "lz91.py", "mz.py", "omf.py", "oracle.py", "toolchain.py",
             "dosrun.py", "tcc.py", "compare.py", "census.py")
    return tree_hash([TOOLS / n for n in names if (TOOLS / n).exists()])
