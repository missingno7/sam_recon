"""Immutable tri-episode oracle: identify, unpack, lock, verify, cross-check.

    python tools/oracle.py                 verify against config/oracle.lock.json and
                                           materialise build/oracle/<ep>/
    python tools/oracle.py --crosscheck    also execute each file's own LZEXE stub in an
                                           x86 emulator and require the identical image,
                                           relocation set and entry registers
    python tools/oracle.py --write-lock    bootstrap only; refuses to overwrite an
                                           existing lock

The original files are read from assets/ (or $SAM_ASSET_DIR), are never
modified, and are never committed.  Everything under build/oracle is
regenerable; the lock is the only committed identity.
"""
from __future__ import annotations

import argparse
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import (BUILD, EPISODES, LAYOUT, asset_dir, atomic_bytes, atomic_json,  # noqa: E402
                    content_key, load_json, sha256)
import lz91  # noqa: E402
import mz  # noqa: E402

LOCK = LAYOUT / "oracle.lock.json"
OUT = BUILD / "oracle"
EXE_NAMES = {"sam1": "SAM1.EXE", "sam2": "SAM2.EXE", "sam3": "SAM3.EXE"}


class OracleError(RuntimeError):
    pass


def find_asset(name: str) -> Path:
    d = asset_dir()
    for p in d.iterdir():
        if p.name.upper() == name.upper():
            return p
    raise OracleError(f"{name} not found in {d}")


def relocs_key(relocs) -> str:
    return content_key([list(r) for r in relocs])


def describe(ep: str) -> tuple:
    raw = find_asset(EXE_NAMES[ep]).read_bytes()
    packed = mz.parse(raw)
    u = lz91.unpack(raw)
    unpacked = lz91.build_mz(u)
    lin = mz.linear(u.relocs)
    if len(set(lin)) != len(lin):
        raise OracleError(f"{ep}: duplicate relocation sites")
    for a in lin:
        if a + 2 > len(u.image):
            raise OracleError(f"{ep}: relocation {a:#x} outside image")
    entry = {
        "packed": {"file": EXE_NAMES[ep], "sha256": sha256(raw), "size": len(raw),
                   "mz": packed.header, "lz91": u.packed_header},
        "unpacked": {
            "canonical_mz_sha256": sha256(unpacked), "canonical_mz_size": len(unpacked),
            "image_sha256": sha256(u.image), "image_size": len(u.image),
            "cs": u.cs, "ip": u.ip, "ss": u.ss, "sp": u.sp,
            "min_extra_paras": u.min_extra_paras, "max_extra_paras": u.max_extra_paras,
            "reloc_count": len(u.relocs),
            "relocs_ordered_key": relocs_key(u.relocs),
            "relocs_sorted_key": relocs_key(sorted(u.relocs)),
        },
    }
    return entry, u, unpacked


def fixture_inventory() -> dict:
    files = {}
    for p in sorted(asset_dir().iterdir(), key=lambda x: x.name.upper()):
        if p.is_file():
            b = p.read_bytes()
            files[p.name.upper()] = {"sha256": sha256(b), "size": len(b)}
    return files


def construct() -> tuple:
    eps, unpacked = {}, {}
    for ep in EPISODES:
        eps[ep], u, blob = describe(ep)
        unpacked[ep] = (u, blob)
    doc = {
        "fixture": "Secret Agent (Apogee, 1992), episodes 1-3, as supplied in assets/",
        "policy": "Originals and derived binaries are never committed or redistributed.",
        "unpacker": "tools/lz91.py (LZEXE 0.91 decoder); canonical_mz = UNLZEXE-compatible header layout",
        "episodes": eps,
        "fixture_files": fixture_inventory(),
    }
    return doc, unpacked


def materialise(unpacked: dict) -> None:
    for ep, (u, blob) in unpacked.items():
        d = OUT / ep
        atomic_bytes(d / "unpacked.exe", blob)
        atomic_bytes(d / "image.bin", u.image)
        atomic_json(d / "relocs.json", {"order": "original table order", "relocs": [list(r) for r in u.relocs]})


def verify(write_lock: bool = False) -> dict:
    doc, unpacked = construct()
    if write_lock:
        if LOCK.exists():
            raise OracleError(f"{LOCK} exists; the oracle lock is immutable")
        atomic_json(LOCK, doc)
    lock = load_json(LOCK)
    if lock != doc:
        diffs = [k for k in doc["episodes"] if doc["episodes"][k] != lock["episodes"].get(k)]
        extra = "" if lock["fixture_files"] == doc["fixture_files"] else " (fixture inventory differs)"
        raise OracleError(f"oracle identity differs from immutable lock: {diffs}{extra}")
    materialise(unpacked)
    return lock


def load_image(ep: str) -> tuple:
    """(image bytes, ordered relocs) from the materialised oracle, re-checked
    against the lock (cheap; avoids re-running the decoder in every tool)."""
    lock = load_json(LOCK)["episodes"][ep]["unpacked"]
    d = OUT / ep
    if not (d / "image.bin").exists():
        verify()
    img = (d / "image.bin").read_bytes()
    relocs = tuple(tuple(r) for r in load_json(d / "relocs.json")["relocs"])
    if sha256(img) != lock["image_sha256"] or relocs_key(relocs) != lock["relocs_ordered_key"]:
        raise OracleError(f"materialised oracle for {ep} is stale or corrupt; run tools/oracle.py")
    return img, relocs


def crosscheck() -> dict:
    """Independent check: run each original LZEXE stub in a unicorn x86
    emulator at two load segments (tools/lz91_emulate.py) and require the
    same image, relocation set and entry registers as tools/lz91.py.

    (UNLZEXE 0.5 was tried first but hangs under both MS-DOS Player and
    DOSBox-X, even for its usage banner; see docs/oracle.md.)"""
    import lz91_emulate
    results = {}
    for ep in EPISODES:
        raw = find_asset(EXE_NAMES[ep]).read_bytes()
        u = lz91.unpack(raw)
        res = lz91_emulate.crosscheck(raw, u.image, u.relocs)
        res["registers_equal"] = res["registers"] == {"cs": u.cs, "ip": u.ip, "ss": u.ss, "sp": u.sp}
        results[ep] = res
        if not (res["relocation_set_equal"] and res["image_equal"] and res["registers_equal"]):
            raise OracleError(f"{ep}: emulated original stub disagrees with tools/lz91.py: {res}")
    return results


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--write-lock", action="store_true")
    ap.add_argument("--crosscheck", action="store_true")
    a = ap.parse_args()
    lock = verify(write_lock=a.write_lock)
    for ep, e in lock["episodes"].items():
        un = e["unpacked"]
        print(f"{ep}: packed {e['packed']['sha256'][:16]} ({e['packed']['size']} B) -> image "
              f"{un['image_sha256'][:16]} ({un['image_size']} B), {un['reloc_count']} relocs, "
              f"CS:IP {un['cs']:04X}:{un['ip']:04X} SS:SP {un['ss']:04X}:{un['sp']:04X}")
    if a.crosscheck:
        res = crosscheck()
        atomic_json(OUT / "crosscheck.json", res)
        print("crosscheck: emulated original LZEXE stubs agree on image, relocation set and "
              "entry registers for", ", ".join(res))
    print("oracle OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
