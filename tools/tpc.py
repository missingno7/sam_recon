"""Isolated, content-addressed Turbo Pascal compiles.

Every compile:
  * stages the given sources (CRLF, latin-1) and binary inputs (e.g. .OBJ for
    {$L}) plus the pinned TURBO.TPL into a fresh scratch directory;
  * runs the pinned TPC.EXE under the pinned MS-DOS Player;
  * keeps every produced .EXE/.MAP/.TPU, the compiler log and a receipt;
  * is keyed by sha256(staged inputs, argv, toolchain identity, this file), so
    an identical request is served from build/cc-cache, and two processes
    asking for the same key at once coalesce on one compile (O_EXCL in-flight
    marker holding the owner PID; a dead owner's marker is taken over).

The cache is research state: deleting build/ only costs time.  Acceptance
(promote/validate) can force fresh compiles with fresh=True.

    python tools/tpc.py MAIN.PAS [OTHER.PAS ...] [--opt /GD] [--fresh]
"""
from __future__ import annotations

import json
import os
import shutil
import sys
import time
import uuid
from dataclasses import dataclass
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, LAYOUT, atomic_json, content_key, load_json, sha256, sha256_file  # noqa: E402
import toolchain  # noqa: E402

CACHE = BUILD / "cc-cache"
SCRATCH = BUILD / "scratch" / "tpc"
INFLIGHT = CACHE / "inflight"
SELF_SHA = sha256_file(Path(__file__))
OUTPUT_EXT = (".EXE", ".MAP", ".TPU")


@dataclass
class Receipt:
    key: str
    ok: bool
    outputs: dict          # NAME.EXT -> bytes (only .EXE/.MAP/.TPU)
    log: str
    directory: Path
    cached: bool
    data: dict

    def exe(self, stem: str) -> bytes | None:
        return self.outputs.get(stem.upper() + ".EXE")

    def map(self, stem: str) -> str | None:
        b = self.outputs.get(stem.upper() + ".MAP")
        return b.decode("latin-1") if b is not None else None


def profiles() -> dict:
    return load_json(LAYOUT / "profiles.json")["profiles"]


def dos_text(text: str) -> bytes:
    return text.replace("\r\n", "\n").replace("\n", "\r\n").encode("latin-1")


def _pid_alive(pid: int) -> bool:
    if pid <= 0:
        return False
    if os.name == "nt":
        import ctypes
        h = ctypes.windll.kernel32.OpenProcess(0x1000, False, pid)  # QUERY_LIMITED_INFORMATION
        if not h:
            return False
        code = ctypes.c_ulong()
        ctypes.windll.kernel32.GetExitCodeProcess(h, ctypes.byref(code))
        ctypes.windll.kernel32.CloseHandle(h)
        return code.value == 259  # STILL_ACTIVE
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def _load_cached(key: str) -> Receipt | None:
    d = CACHE / key[:2] / key
    rp = d / "receipt.json"
    if not rp.exists():
        return None
    data = load_json(rp)
    outs = {}
    for name, digest in data["outputs"].items():
        p = d / name
        if not p.exists() or sha256_file(p) != digest:
            return None  # corrupted cache entry: recompile
        outs[name] = p.read_bytes()
    log = (d / "compiler.log").read_text("latin-1") if (d / "compiler.log").exists() else ""
    return Receipt(key, data["ok"], outs, log, d, True, data)


def compile_program(sources: dict, main: str, options: list | None = None, *,
                    binaries: dict | None = None, fresh: bool = False,
                    timeout: int = 300) -> Receipt:
    """Compile `main` (a key of `sources`) with TPC.  `sources` maps DOS file
    names to Pascal text; `binaries` maps names to bytes (.OBJ for {$L}, data).
    `options` are TPC command-line options placed before the file name
    (e.g. ["/GD", "/$S-"]); /M (make) is added so used units are compiled."""
    staged = {k.upper(): dos_text(v) for k, v in sources.items()}
    for k, v in (binaries or {}).items():
        staged[k.upper()] = v
    main = main.upper()
    if main not in staged:
        raise KeyError(f"{main} not among the sources")
    argv = ["/M", *(options or []), main]
    request = {"kind": "tpc", "argv": argv,
               "inputs": {k: sha256(v) for k, v in sorted(staged.items())},
               "toolchain": toolchain.identity(), "wrapper": SELF_SHA}
    key = content_key(request)
    if not fresh:
        hit = _load_cached(key)
        if hit:
            return hit
    INFLIGHT.mkdir(parents=True, exist_ok=True)
    marker = INFLIGHT / key
    owned = False
    deadline = time.time() + timeout + 60
    while not owned:
        try:
            fd = os.open(marker, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            os.write(fd, str(os.getpid()).encode())
            os.close(fd)
            owned = True
        except FileExistsError:
            if not fresh:
                hit = _load_cached(key)
                if hit:
                    return hit
            try:
                pid = int(marker.read_text() or "0")
            except (OSError, ValueError):
                pid = 0
            if not _pid_alive(pid):
                try:
                    marker.unlink()
                except OSError:
                    pass
                continue
            if time.time() > deadline:
                raise TimeoutError(f"compile {key} held by live pid {pid} too long")
            time.sleep(0.2)
    try:
        if not fresh:
            hit = _load_cached(key)
            if hit:
                return hit
        work = SCRATCH / uuid.uuid4().hex
        work.mkdir(parents=True)
        for name, data in staged.items():
            (work / name).write_bytes(data)
        shutil.copyfile(toolchain.tool("TURBO.TPL"), work / "TURBO.TPL")
        toolchain.verify_all()
        rc, out, cmd = toolchain.run_dos("TPC.EXE", argv, work, timeout=timeout)
        (work / "compiler.log").write_bytes(out)
        produced = {p.name.upper(): p for p in work.iterdir()
                    if p.suffix.upper() in OUTPUT_EXT and p.name.upper() not in staged}
        stem = main.rsplit(".", 1)[0]
        ok = rc == 0 and (stem + ".EXE" in produced or stem + ".TPU" in produced) \
            and b"Error" not in out
        data = {"key": key, "request": request, "ok": ok, "returncode": rc,
                "outputs": {n: sha256_file(p) for n, p in sorted(produced.items())},
                "log_sha256": sha256(out)}
        atomic_json(work / "receipt.json", data)
        for p in work.iterdir():
            if p.name.upper() not in produced and p.name not in ("receipt.json", "compiler.log") \
                    and p.name.upper() not in {k for k in staged if k.endswith(".PAS")}:
                p.unlink()
        dest = CACHE / key[:2] / key
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists():
            shutil.rmtree(dest)
        os.replace(work, dest)
        outs = {n: (dest / n).read_bytes() for n in produced}
        return Receipt(key, ok, outs, out.decode("latin-1"), dest, False, data)
    finally:
        try:
            marker.unlink()
        except OSError:
            pass


if __name__ == "__main__":
    import argparse
    ap = argparse.ArgumentParser(description="compile a Pascal program with the pinned TPC")
    ap.add_argument("files", nargs="+", help="main program first, then units/includes/OBJs")
    ap.add_argument("--opt", action="append", default=[], help="TPC option, e.g. --opt=/GD")
    ap.add_argument("--fresh", action="store_true")
    a = ap.parse_args()
    src, binr = {}, {}
    for f in a.files:
        p = Path(f)
        if p.suffix.upper() in (".PAS", ".INC"):
            src[p.name] = p.read_text("latin-1")
        else:
            binr[p.name] = p.read_bytes()
    r = compile_program(src, Path(a.files[0]).name, a.opt, binaries=binr, fresh=a.fresh)
    print(json.dumps({"ok": r.ok, "key": r.key, "cached": r.cached, "dir": str(r.directory),
                      "outputs": sorted(r.outputs)}, indent=1))
    print(r.log)
