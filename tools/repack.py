"""Pack an unpacked MZ executable with the pinned LZEXE 0.91 (DOSBox-X).

    python tools/repack.py IN.EXE OUT.EXE
    python tools/repack.py --oracle            repack each oracle's canonical unpacked
                                               image and compare with the original file

LZEXE 0.91 is deterministic and sorts relocations itself, so the packed file
is a function of the unpacked image, its relocation set and header fields.
"""
from __future__ import annotations

import shutil
import sys
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, EPISODES, sha256  # noqa: E402
import toolchain  # noqa: E402


def pack(unpacked: bytes) -> bytes:
    pk = toolchain.lock()["packer"]
    exe = Path(pk["executable"])
    toolchain._check(exe, pk["sha256"])
    w = BUILD / "scratch" / "repack" / uuid.uuid4().hex[:10]
    w.mkdir(parents=True)
    try:
        (w / "IN.EXE").write_bytes(unpacked)
        shutil.copy(exe, w / "LZEXE.EXE")
        rc, _ = toolchain.run_dosbox(w, ["LZEXE.EXE IN.EXE > LZ.LOG"], timeout=240)
        if not (w / "IN.OLD").exists():
            raise RuntimeError(f"LZEXE did not run (rc {rc})")
        return (w / "IN.EXE").read_bytes()
    finally:
        shutil.rmtree(w, ignore_errors=True)


def oracle_check() -> dict:
    import lz91
    import oracle
    out = {}
    for ep in EPISODES:
        raw = oracle.find_asset(oracle.EXE_NAMES[ep]).read_bytes()
        packed = pack(lz91.build_mz(lz91.unpack(raw)))
        out[ep] = {"equal": packed == raw, "sha256": sha256(packed), "size": len(packed)}
    return out


def main() -> int:
    if sys.argv[1:2] == ["--oracle"]:
        res = oracle_check()
        for ep, r in res.items():
            print(f"{ep}: repacked {r['size']} B {r['sha256'][:16]} {'== original' if r['equal'] else 'DIFFERS from original'}")
        return 0 if all(r["equal"] for r in res.values()) else 1
    Path(sys.argv[2]).write_bytes(pack(Path(sys.argv[1]).read_bytes()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
