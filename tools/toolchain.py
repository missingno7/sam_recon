"""Pinned historical toolchain and DOS runner.

The runner only executes already-pinned DOS binaries; it never supplies
compiler inputs.  Every run gets its own scratch directory, a reduced DOS
environment, and a captured log.  Tool hashes are verified before use (and
the verification is memoised per process, keyed by file size+mtime, so a
swapped binary is still detected).
"""
from __future__ import annotations

import os
import subprocess
from pathlib import Path

from common import LAYOUT, load_json, sha256_file

_VERIFIED: dict = {}


class ToolchainError(RuntimeError):
    pass


def lock() -> dict:
    return load_json(LAYOUT / "toolchain.json")


def root() -> Path:
    return Path(lock()["toolchain_root"])


def _check(path: Path, expected: str) -> None:
    st = path.stat()
    key = (str(path), st.st_size, st.st_mtime_ns)
    if _VERIFIED.get(key) == expected:
        return
    actual = sha256_file(path)
    if actual != expected:
        raise ToolchainError(f"pinned tool {path} has sha256 {actual}, expected {expected}")
    _VERIFIED[key] = expected


def tool(rel: str) -> Path:
    """Absolute path of a pinned toolchain file, verified."""
    info = lock()["files"].get(rel)
    if info is None:
        raise ToolchainError(f"{rel} is not a pinned toolchain file")
    path = root() / rel
    if not path.is_file():
        raise ToolchainError(f"pinned tool missing: {path}")
    _check(path, info["sha256"])
    return path


def verify_all() -> dict:
    lk = lock()
    for rel in lk["files"]:
        tool(rel)
    r = lk["runner"]
    _check(Path(r["executable"]), r["sha256"])
    for o in r.get("overrides", {}).values():
        _check(Path(o["executable"]), o["sha256"])
    return {"toolchain_root": lk["toolchain_root"], "files": len(lk["files"]), "runner": r["sha256"]}


def identity() -> dict:
    """What a compile receipt must record for its toolchain."""
    lk = lock()
    return {"files": {k: v["sha256"] for k, v in sorted(lk["files"].items())},
            "runner": lk["runner"]["sha256"],
            "overrides": {k: v["sha256"] for k, v in sorted(lk["runner"].get("overrides", {}).items())}}


def _no_window() -> dict:
    if os.name != "nt":
        return {}
    si = subprocess.STARTUPINFO()
    si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    si.wShowWindow = 0
    return {"startupinfo": si, "creationflags": subprocess.CREATE_NO_WINDOW}


def run_dos(program_rel: str, args: list, cwd: Path, timeout: int = 300) -> tuple:
    """Run one pinned DOS program in `cwd` under MS-DOS Player.

    Returns (returncode, captured_output_bytes, argv).  The DOS environment is
    reduced to PATH (the pinned BIN directory, so TCC -B finds TASM) and a
    TEMP inside the scratch directory.
    """
    program = tool(program_rel)
    lk = lock()["runner"]
    host = Path(lk["executable"])
    _check(host, lk["sha256"])
    override = lk.get("overrides", {}).get(program.name.upper())
    if override:
        host = Path(override["executable"])
        _check(host, override["sha256"])
    cwd = Path(cwd).resolve()
    bindir = str(program.parent)
    env = {"PATH": bindir, "MSDOS_PATH": bindir, "TEMP": str(cwd), "TMP": str(cwd),
           "MSDOS_TEMP": str(cwd), "SystemRoot": os.environ.get("SystemRoot", "C:\\Windows")}
    argv = [str(host), *lk["args"], str(program), *map(str, args)]
    try:
        proc = subprocess.run(argv, cwd=cwd, env=env, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                              timeout=timeout, **_no_window())
    except subprocess.TimeoutExpired as exc:
        return -9, (exc.output or b"") + b"\n[runner] TIMEOUT\n", argv
    return proc.returncode, proc.stdout, argv


def run_dosbox(work: Path, commands: list, timeout: int = 120) -> tuple:
    """Run DOS `commands` in headless DOSBox-X with `work` mounted as C:.

    Output of each command must be redirected by the caller into files under
    `work`; DOSBox-X has no usable stdout.  Returns (returncode, argv).
    """
    r = lock()["independent_runner"]
    exe = Path(r["executable"])
    _check(exe, r["sha256"])
    work = Path(work).resolve()
    lines = ["[sdl]", "output=surface", "[cpu]", "cycles=max", "[mixer]", "nosound=true",
             "[dosbox]", "memsize=16", "[autoexec]", f'mount c "{work}"', "c:", *commands, "exit"]
    conf = work / "dosbox.conf"
    conf.write_text("\n".join(lines) + "\n")
    env = os.environ.copy()
    env.update(SDL_VIDEODRIVER="dummy", SDL_AUDIODRIVER="dummy")
    argv = [str(exe), "-conf", str(conf), "-fastlaunch", "-exit", "-nopromptfolder"]
    try:
        proc = subprocess.run(argv, cwd=work, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                              stdin=subprocess.DEVNULL, timeout=timeout, **_no_window())
    except subprocess.TimeoutExpired:
        return -9, argv
    return proc.returncode, argv
