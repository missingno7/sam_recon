"""Build the source tree with the pinned historical tools and compare with the original.

    python tools/verify.py [TREE] [--episodes sam1,sam2,sam3] [--pack | --dos] [--keep]

TREE defaults to game/.  For each episode, in an isolated scratch copy of the tree, the
steps of BUILD.BAT are run with the pinned tools (config/toolchain.json):

    tasm /DSAMn X.ASM,X.OBJ,;          for every .ASM file
    tpc /M /GD /DSAMn <profile> SAM.PAS (config/profiles.json)

and the linked load image is compared with the oracle image (tools/oracle.py):

  * every byte equal, except inside the documented residue ranges (config/residue.json:
    undefined DB ? storage of the linked objects, holding residual compiler-buffer bytes
    of the original build; compared and reported, never filled or patched);
  * the relocation set equal;
  * the MZ fields that exist in an unpacked image equal: CS:IP, SS:SP, minalloc, maxalloc.
With --pack the build is also packed with LZEXE 0.91 (DOSBox-X); the packed file can
only equal the original when the residue bytes happen to match.
With --dos the tree's own BUILD.BAT is run unmodified in DOSBox-X with the pinned TPC,
TURBO.TPL, TASM and LZEXE on the DOS PATH; its SAM.EXE is compared as above and its
packed SAMn.EXE must unpack to exactly that program.
"""
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, EPISODES, LAYOUT, ROOT, load_json, sha256  # noqa: E402
import mz  # noqa: E402
import oracle  # noqa: E402
import toolchain  # noqa: E402

SCRATCH = BUILD / "verify"


def _run(program: Path, args: list, cwd: Path, timeout: int = 300) -> tuple:
    runner = toolchain.lock()["runner"]
    host = Path(runner["executable"])
    toolchain._check(host, runner["sha256"])
    env = {"PATH": str(program.parent), "MSDOS_PATH": str(program.parent), "TEMP": str(cwd),
           "TMP": str(cwd), "MSDOS_TEMP": str(cwd), "SystemRoot": os.environ.get("SystemRoot", "C:\\Windows")}
    argv = [str(host), *runner["args"], str(program), *args]
    try:
        p = subprocess.run(argv, cwd=cwd, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           stdin=subprocess.DEVNULL, timeout=timeout, **toolchain._no_window())
        return p.returncode, p.stdout.decode("latin-1")
    except subprocess.TimeoutExpired:
        return -9, "[runner] TIMEOUT"


def build(tree: Path, ep: str, work: Path) -> Path:
    """Run the BUILD.BAT steps for episode `ep`; returns the linked SAM.EXE."""
    if work.exists():
        shutil.rmtree(work)
    work.mkdir(parents=True)
    for p in tree.iterdir():
        if p.is_file() and p.suffix.upper() in (".PAS", ".ASM", ".INC"):
            text = p.read_text(encoding="latin-1").replace("\r\n", "\n").replace("\n", "\r\n")
            (work / p.name.upper()).write_bytes(text.encode("latin-1"))
    lock = toolchain.lock()
    tasm = Path(lock["assembler"]["executable"])
    toolchain._check(tasm, lock["assembler"]["sha256"])
    n = ep[-1]
    log = []
    for asm in sorted(work.glob("*.ASM")):
        rc, out = _run(tasm, [f"/DSAM{n}", f"{asm.stem}.ASM,{asm.stem}.OBJ,;"], work)
        log.append(out)
        if rc != 0 or "**Error**" in out or not (work / f"{asm.stem}.OBJ").exists():
            raise RuntimeError(f"{ep}: TASM failed on {asm.name}:\n{out[-800:]}")
    shutil.copyfile(toolchain.tool("TURBO.TPL"), work / "TURBO.TPL")
    prof = load_json(LAYOUT / "profiles.json")
    options = prof["profiles"][prof["default"]]["options"]
    rc, out = _run(toolchain.tool("TPC.EXE"), ["/M", "/GD", f"/DSAM{n}", *options, "SAM.PAS"], work)
    log.append(out)
    (work / "build.log").write_text("\n".join(log), encoding="latin-1")
    exe = work / "SAM.EXE"
    if rc != 0 or not exe.exists() or "Error" in out:
        raise RuntimeError(f"{ep}: TPC failed:\n{out[-800:]}")
    return exe


def dos_build(tree: Path, ep: str, work: Path) -> tuple:
    """Run the tree's own BUILD.BAT for episode `ep` in DOSBox-X, the pinned tools on PATH.

    Returns (linked SAM.EXE, packed SAMn.EXE)."""
    if work.exists():
        shutil.rmtree(work)
    (work / "BIN").mkdir(parents=True)
    for p in tree.iterdir():
        if p.is_file() and p.suffix.upper() in (".PAS", ".ASM", ".INC", ".BAT"):
            text = p.read_text(encoding="latin-1").replace("\r\n", "\n").replace("\n", "\r\n")
            (work / p.name.upper()).write_bytes(text.encode("latin-1"))
    lock = toolchain.lock()
    for exe, digest in ((lock["assembler"]["executable"], lock["assembler"]["sha256"]),
                        (lock["packer"]["executable"], lock["packer"]["sha256"])):
        toolchain._check(Path(exe), digest)
        shutil.copyfile(exe, work / "BIN" / Path(exe).name.upper())
    for rel in ("TPC.EXE", "TURBO.TPL"):
        shutil.copyfile(toolchain.tool(rel), work / "BIN" / rel)
    n = ep[-1]
    toolchain.run_dosbox(work, ["set PATH=C:\\BIN", f"BUILD {n}"], timeout=600)
    exe, packed = work / "SAM.EXE", work / f"SAM{n}.EXE"
    if not (exe.exists() and packed.exists() and (work / f"SAM{n}.OLD").exists()):
        made = sorted(p.name for p in work.iterdir() if p.suffix.upper() in (".OBJ", ".TPU", ".EXE"))
        raise RuntimeError(f"{ep}: BUILD.BAT did not produce SAM.EXE and packed SAM{n}.EXE (made: {made})")
    return exe, packed


def compare(ep: str, exe: Path) -> dict:
    built = mz.parse(exe.read_bytes())
    img, relocs = oracle.load_image(ep)
    lock = load_json(LAYOUT / "oracle.lock.json")["episodes"][ep]["unpacked"]
    residue = load_json(LAYOUT / "residue.json")["episodes"][ep]
    allowed = set()
    for r in residue:
        allowed |= set(range(int(r["start"], 16), int(r["end"], 16)))
    cand = built.image
    out = {"episode": ep, "image_size": len(img)}
    if len(cand) != len(img):
        out.update(ok=False, error=f"image size {len(cand)} != original {len(img)}")
        return out
    diffs = [i for i in range(len(img)) if img[i] != cand[i]]
    outside = [i for i in diffs if i not in allowed]
    h = built.header
    hdr = {"cs": (h["cs"], lock["cs"]), "ip": (h["ip"], lock["ip"]), "ss": (h["ss"], lock["ss"]),
           "sp": (h["sp"], lock["sp"]), "minalloc": (h["minalloc"], lock["min_extra_paras"]),
           "maxalloc": (h["maxalloc"], lock["max_extra_paras"])}
    rel_equal = sorted(mz.linear(built.relocs)) == sorted(mz.linear(relocs))
    out.update(equal_bytes=len(img) - len(diffs), residue_bytes_differing=len(diffs) - len(outside),
               outside_residue=[f"{i:05X}" for i in outside[:16]], relocations_equal=rel_equal,
               header={k: v[0] == v[1] for k, v in hdr.items()}, image_sha256=sha256(cand))
    out["ok"] = not outside and rel_equal and all(out["header"].values())
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("tree", nargs="?", default=str(ROOT / "game"))
    ap.add_argument("--episodes", default=",".join(EPISODES))
    ap.add_argument("--pack", action="store_true")
    ap.add_argument("--dos", action="store_true", help="run the tree's BUILD.BAT itself in DOSBox-X")
    ap.add_argument("--keep", action="store_true")
    a = ap.parse_args()
    tree = Path(a.tree)
    toolchain.verify_all()
    ok = True
    for ep in a.episodes.split(","):
        work = SCRATCH / f"{ep}-{uuid.uuid4().hex[:8]}"
        try:
            if a.dos:
                exe, packed_exe = dos_build(tree, ep, work)
            else:
                exe = build(tree, ep, work)
            r = compare(ep, exe)
        except RuntimeError as exc:
            print(f"{ep}: BUILD FAILED: {exc}")
            ok = False
            continue
        if a.dos:
            # BUILD.BAT's packed output must hold exactly the linked program, and
            # equals the original file only if the residue bytes happen to match.
            import lz91
            u = lz91.unpack(packed_exe.read_bytes())
            built = mz.parse(exe.read_bytes())
            h = built.header
            r["packed_roundtrip"] = (u.image == built.image
                                     and sorted(mz.linear(u.relocs)) == sorted(mz.linear(built.relocs))
                                     and (u.cs, u.ip, u.ss, u.sp, u.min_extra_paras, u.max_extra_paras)
                                     == (h["cs"], h["ip"], h["ss"], h["sp"], h["minalloc"], h["maxalloc"]))
            r["packed_equal"] = packed_exe.read_bytes() == oracle.find_asset(oracle.EXE_NAMES[ep]).read_bytes()
            r["ok"] &= r["packed_roundtrip"]
        elif a.pack and r["ok"]:
            import repack
            packed = repack.pack((work / "SAM.EXE").read_bytes())
            raw = oracle.find_asset(oracle.EXE_NAMES[ep]).read_bytes()
            r["packed_equal"] = packed == raw
        ok &= r["ok"]
        if "error" in r:
            print(f"{ep}: FAIL {r['error']}")
        else:
            print(f"{ep}: {'OK' if r['ok'] else 'FAIL'}  {r['equal_bytes']}/{r['image_size']} bytes equal, "
                  f"{r['residue_bytes_differing']} residue bytes differ, "
                  f"{len(r['outside_residue'])} outside residue {r['outside_residue']}; relocations "
                  f"{'equal' if r['relocations_equal'] else 'DIFFER'}; header "
                  f"{'equal' if all(r['header'].values()) else r['header']}"
                  + (f"; packed {'holds the build' if r['packed_roundtrip'] else 'DOES NOT hold the build'}"
                     if "packed_roundtrip" in r else "")
                  + (f"; packed {'EQUAL' if r['packed_equal'] else 'differs (residue)'}" if "packed_equal" in r else ""))
        if not a.keep:
            shutil.rmtree(work, ignore_errors=True)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
