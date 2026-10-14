"""Vendor the Python decoder/emulator packages into build/python.

    python tools/setup_env.py

Sandboxed workers may not see the user's site-packages, and must not install
their own (decoder drift).  This copies the supervisor interpreter's pinned
capstone and unicorn packages into build/python (regenerable, never
committed); tools/common.py puts build/python first on sys.path.
"""
from __future__ import annotations

import importlib.metadata as md
import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "build" / "python"
PINS = {"capstone": "5.0.9", "unicorn": "2.1.4"}  # pip distribution versions (capstone core reports 5.0.7)


def main() -> int:
    DEST.mkdir(parents=True, exist_ok=True)
    versions = {}
    for name, want in PINS.items():
        dist = md.distribution(name)
        if dist.version != want:
            print(f"{name} {dist.version} installed, {want} pinned")
            return 1
        pkg = Path(dist.locate_file(name))
        info = Path(dist._path)  # the .dist-info directory
        for src in (pkg, info):
            dst = DEST / src.name
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(src, dst, ignore=shutil.ignore_patterns("__pycache__"))
        versions[name] = dist.version
    (DEST / "VERSIONS.json").write_text(json.dumps(versions, indent=1) + "\n")
    print(f"vendored {versions} into {DEST}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
