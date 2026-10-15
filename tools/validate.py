"""Re-derive every claim of the reconstruction from the committed inputs.

    python tools/validate.py [--crosscheck] [--pack | --dos] [--port] [--lockstep]

  1. the original files match the immutable oracle lock (tools/oracle.py), optionally
     cross-checked by running each file's own LZEXE stub in an emulator;
  2. game/ builds with the pinned tools (config/toolchain.json) for SAM1, SAM2 and SAM3 and
     equals the original load image in every byte outside the documented residue
     (tools/verify.py; --dos runs game/BUILD.BAT itself in DOSBox-X);
  3. the unit tests pass;
  4. with --port, the SDL3 port (docs/port.md): translator gates (DS layout, record sizes,
     compile), the semantic corpus against TP 5.0, the platform tests and the boot of all
     three episodes to their title screens, at -O0 and -O2 (tools/pas2c_check.py --integration).
"""
from __future__ import annotations

import argparse
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import ROOT  # noqa: E402


def step(name: str, argv: list) -> bool:
    print(f"== {name}")
    r = subprocess.run([sys.executable, *argv], cwd=ROOT)
    return r.returncode == 0


def main() -> int:
    started = time.monotonic()
    ap = argparse.ArgumentParser()
    ap.add_argument("--crosscheck", action="store_true", help="also execute the original LZEXE stubs")
    ap.add_argument("--pack", action="store_true", help="also pack the builds with LZEXE 0.91")
    ap.add_argument("--dos", action="store_true", help="run game/BUILD.BAT itself in DOSBox-X")
    ap.add_argument("--port", action="store_true", help="also build and check the SDL3 port")
    ap.add_argument("--lockstep", action="store_true",
                    help="also build the lockstep target and run every episode/scenario strictly; needs the DOS reference build for SAM.MAP")
    a = ap.parse_args()
    results = {
        "oracle": step("oracle", ["tools/oracle.py", *(["--crosscheck"] if a.crosscheck else [])]),
        "build": step("build game/ and compare", ["tools/verify.py", *(["--pack"] if a.pack else []), *(["--dos"] if a.dos else [])]),
        "tests": step("tests", ["-m", "unittest", "discover", "-s", "tests"]),
    }
    if a.port:
        results["port"] = step("SDL3 port", ["-B", "tools/pas2c_check.py", "--integration"])
    if a.lockstep:
        results["lockstep"] = step("strict original/port lockstep", ["-B", "tools/lockstep_gate.py"])
    print("== result: " + ", ".join(f"{k} {'OK' if v else 'FAILED'}" for k, v in results.items()))
    if a.lockstep:
        print(f"== full validation wall time: {time.monotonic()-started:.3f} seconds")
    return 0 if all(results.values()) else 1


if __name__ == "__main__":
    sys.exit(main())
