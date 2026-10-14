"""Build a standalone game tree and verify it without regenerating game sources.

    python tools/standalone.py build/workers/sol-standalone/game
    python tools/standalone.py GAME --episodes sam1,sam3

Each episode receives a fresh, source-only DOS directory. BUILD.BAT's pinned
assembly/compile/copy/pack recipe is checked before execution. TASM and TPC
run under MS-DOS Player; LZEXE runs under DOSBox-X. All products, diagnostic
compiles and receipts stay below build/workers/sol-standalone/standalone/.
The only permitted image differences are the accepted undefined OMF holes,
whose sizes/ranges are independently checked against the assembly recipes.
No generated game sources, cached objects/TPUs, hole fillers or patches enter
the build. Packed equality to the original is reported separately from proof.
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import uuid
from pathlib import Path
from types import SimpleNamespace

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, EPISODES, EVIDENCE, ROOT, atomic_json, load_json, sha256, sha256_file
import asmproof
import lz91
import mergeeps
import mz
import oracle
from omf import OmfReader
import progbuild
import rename
import toolchain
import tpc
import tpmap

OUT = BUILD / "workers/sol-standalone/standalone"
KNOWN_HEADER = ("ss", "sp", "minalloc", "maxalloc", "cs", "ip")


def build_steps(batch: str, episode: str, options: list[str]) -> list[tuple[str, list[str]]]:
    """Validate the reviewable DOS batch before executing its build recipe.

    Ignored lines are only the exact control/cleanup lines emitted by mergeeps;
    an added build command or changed compiler switch cannot silently be ignored.
    """
    if episode not in EPISODES:
        raise ValueError("unknown episode")
    expected = mergeeps.build_batch(options).splitlines()
    actual = mergeeps.normalize(batch).splitlines()
    aliases = progbuild.canonical_symbols()
    # Only supported filename substitutions are accepted; the pinned commands
    # and switches still have to match the original recipe exactly.
    canonical = lambda s: re.sub(r"(?i)\b([A-Za-z_][A-Za-z_0-9]*)(?=\.TPU\b)",
                                lambda m: aliases.get(m[1].upper(), m[1]), s)
    meaningful = lambda lines: [s.strip().lower() for s in lines
                                if s.strip() and not s.strip().lower().startswith("rem ")]
    if meaningful([canonical(s) for s in actual]) != meaningful(expected):
        raise ValueError("BUILD.BAT differs from the supported pinned recipe (tools/mergeeps.py)")
    steps = []
    for line in actual:
        words = line.strip().replace("%1", episode[-1]).split()
        if words and words[0].lower() in ("tasm", "tpc", "copy", "lzexe"):
            steps.append((words[0].lower(), words[1:]))
    return steps


def copy_sources(tree: Path, work: Path) -> dict:
    """Copy text inputs only; refuse stale binary inputs and directory escapes."""
    tree = tree.resolve(strict=True)
    if not tree.is_dir():
        raise ValueError("game tree must be a directory")
    inputs = {}
    for path in sorted(tree.iterdir()):
        if path.is_symlink() or not path.is_file() or path.resolve().parent != tree:
            raise ValueError(f"standalone inputs must be ordinary top-level files: {path.name}")
        if path.suffix.upper() not in (".PAS", ".ASM", ".BAT", ".MD"):
            raise ValueError(f"standalone tree must contain source text only: {path.name}")
        name = path.name.upper()
        if name in inputs:
            raise ValueError(f"duplicate DOS filename: {name}")
        if not re.fullmatch(r"[A-Z0-9_]{1,8}\.[A-Z0-9]{1,3}", name):
            raise ValueError(f"not a DOS 8.3 filename: {name}")
        blob = path.read_bytes()
        inputs[name] = sha256(blob)
        (work / name).write_bytes(blob)
    units = progbuild.semantic_names().get("units", {})
    required = {"SAM.PAS", "BUILD.BAT", *(name + ".ASM" for name in mergeeps.OBJECT_NAMES.values())}
    missing = required - inputs.keys()
    for filename in mergeeps.PASCAL_FILES:
        if filename == "SAM.PAS":
            continue
        unit = Path(filename).stem.lower()
        semantic = units.get(unit, {}).get("name", unit).upper() + ".PAS"
        if filename not in inputs and semantic not in inputs:
            missing.add(filename + " or " + semantic)
    if missing:
        raise ValueError("missing standalone inputs: " + ", ".join(sorted(missing)))
    return inputs


def assembly_context(unit: str, episode: str):
    """Bind semantic OMF externs/publics to the unchanged coordinate oracle."""
    ctx = asmproof.original_context(unit, episode)
    names = progbuild.semantic_names()
    for lid, row in names.get("routines", {}).items():
        if lid.lower() in ctx.routines:
            ctx.routines[row["name"].lower()] = ctx.routines[lid.lower()]
    for old, row in names.get("globals", {}).items():
        offset = ctx.globals.get(old.upper())
        if offset is None:
            offset = ctx.extra_offset(old, episode) if ctx.extra_offset else None
        if offset is not None:
            ctx.globals[row["name"].upper()] = offset
    return ctx


def source_layout(work: Path, episode: str) -> tuple[dict, set]:
    """Independently inventory real declarations, including typed constants.

    Referenced DS coordinates may point inside records/arrays; only declared
    variables are expected map publics. Missing required publics are failures.
    """
    import harness
    offsets = harness.episode_globals(episode)
    aliases = progbuild.canonical_symbols()
    globals_, routines = {}, set()
    for path in sorted(work.glob("*.PAS")):
        pas = rename.Pascal(mergeeps.select_episode(path.read_text("latin1"), episode), path.name)
        module = aliases.get(pas.root.name.upper(), pas.root.name.upper())
        unit = "p" if module == "SAM" else module.lower()
        for n in pas.root.variables:
            original = aliases.get(n.upper(), n.upper())
            if progbuild.GLOBAL_RX.fullmatch(original):
                offset = offsets.get(original)
                if offset is None:
                    offset = harness.extra_offset(original, episode)
                if offset is None:
                    raise ValueError(f"{episode}: no independently known offset for declared {original}")
                globals_[original] = {"unit": unit, "offset": offset}
        for scope in pas.root.children:
            if scope.interface or module == "SAM" and scope.definition:
                routines.add(aliases.get(scope.name.upper(), scope.name.upper()).lower())
    for path in work.glob("*.ASM"):
        text = mergeeps.select_episode(path.read_text("latin1"), episode, "asm")
        for line in re.findall(r"(?im)^\s*public\s+([^;\r\n]+)", text):
            for n in line.split(","):
                n = n.strip().upper()
                routines.add(aliases.get(n, n).lower())
    return globals_, routines


def run_tasm(args: list[str], work: Path) -> dict:
    """asmproof's runner/pins, with real standalone filenames and /DSAMn."""
    lk = toolchain.lock()
    program, host = Path(lk["assembler"]["executable"]), Path(lk["runner"]["executable"])
    toolchain._check(program, lk["assembler"]["sha256"])
    toolchain._check(host, lk["runner"]["sha256"])
    env = {"PATH": str(program.parent), "MSDOS_PATH": str(program.parent),
           "TEMP": str(work), "TMP": str(work), "MSDOS_TEMP": str(work),
           "SystemRoot": os.environ.get("SystemRoot", "C:\\Windows")}
    argv = [str(host), *lk["runner"]["args"], str(program), *args]
    stem = args[-1].split(",")[0].rsplit(".", 1)[0].upper()
    source = (work / (stem + ".ASM")).read_text("latin1")
    if re.search(r"(?im)^\s*(?:include|incbin)\b", source):
        raise ValueError("standalone ASM must not import unstaged inputs")
    try:
        p = subprocess.run(argv, cwd=work, env=env, stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                           timeout=60, **toolchain._no_window())
        rc, log = p.returncode, p.stdout
    except subprocess.TimeoutExpired as exc:
        rc, log = -9, (exc.output or b"") + b"\nTIMEOUT\n"
    (work / (stem + ".LOG")).write_bytes(log)
    obj = work / (stem + ".OBJ")
    ok = rc == 0 and obj.is_file() and b"**Error**" not in log
    return {"argv": argv, "returncode": rc, "ok": ok, "log_sha256": sha256(log),
            "object_sha256": sha256_file(obj) if obj.is_file() else None,
            "assembler_sha256": lk["assembler"]["sha256"], "runner_sha256": lk["runner"]["sha256"]}


def verify_comparison(original: bytes, candidate: bytes, holes: list[dict], comparison: dict,
                      segments: dict) -> dict:
    """Phase-3 acceptance: image equality outside independently proven holes."""
    allowed = set()
    for h in holes:
        a, b = h["original_range"]
        if h["candidate_range"] != [a, b] or h["candidate_bytes"] is None:
            raise ValueError("undefined object storage did not link at its proven position")
        base = segments[h["unit"]]["start"]
        if not 0 <= base + a <= base + b <= len(original):
            raise ValueError("object hole outside the original image")
        sites = set(range(base + a, base + b))
        if sites & allowed:
            raise ValueError("overlapping object holes")
        allowed |= sites
    if len(candidate) != len(original):
        return {"ok": False, "error": f"image size {len(candidate)} != {len(original)}"}
    diffs = [i for i, (a, b) in enumerate(zip(original, candidate)) if a != b]
    outside = [i for i in diffs if i not in allowed]
    dl, hdr = comparison["data_length"], comparison["header"]
    checks = {
        "relocation set": comparison["relocations"]["equal"],
        "DATA length / SS:SP / alloc": (dl["actual"] + 15) // 16 == (dl["expected"] + 15) // 16
            and all(hdr[k]["equal"] for k in KNOWN_HEADER),
        "link order": comparison["link_order"]["equal"],
        "init chain": comparison["init_chain"]["equal"],
        "segment layout": (not comparison["unexpected_segments"] or
            comparison["unexpected_segments"] == ["HEAP"] and comparison.get("zero_length_heap", False))
            and comparison["overlay_size"] == 0
            and all(r.get("original_para") == r.get("candidate_para")
                    and r.get("original_size") == r.get("candidate_size")
                    for r in comparison["segments"]),
        "library data anchors": all(r["equal"] for r in comparison["anchors"]),
        "global offsets": all(r["equal"] for r in comparison.get("globals", [])),
        "routine entries": all(r["equal"] for r in comparison["routine_entries"]),
    }
    return {"ok": not outside and all(checks.values()), "image_size": len(original),
            "equal_bytes": len(original) - len(diffs), "differing_bytes": len(diffs),
            "residue_bytes_differing": len(diffs) - len(outside), "allowed_residue_bytes": len(allowed),
            "outside_residue_count": len(outside), "outside_residue": [f"{i:05X}" for i in outside[:20]],
            "checks": checks}


def pack_episode(work: Path, episode: str, executable: bytes, original_packed: bytes) -> dict:
    packer = toolchain.lock()["packer"]
    pack_path = Path(packer["executable"])
    toolchain._check(pack_path, packer["sha256"])
    shutil.copyfile(pack_path, work / "LZEXE.EXE")
    name = episode.upper()
    rc, argv = toolchain.run_dosbox(work, [f"LZEXE.EXE {name}.EXE > LZEXE.LOG"], timeout=240)
    old = work / (name + ".OLD")
    if not old.is_file() or old.read_bytes() != executable:
        raise RuntimeError(f"LZEXE failed or backup differs from linked EXE (return code {rc})")
    packed = (work / (name + ".EXE")).read_bytes()
    u, before = lz91.unpack(packed), mz.parse(executable)
    roundtrip = (u.image == before.image and set(mz.linear(u.relocs)) == set(mz.linear(before.relocs))
                 and len(u.relocs) == len(before.relocs)
                 and (u.ss, u.sp, u.min_extra_paras, u.max_extra_paras, u.cs, u.ip) ==
                     tuple(before.header[k] for k in KNOWN_HEADER))
    return {"status": "EQUAL" if packed == original_packed else "DIFF",
            "reason": "packed equality is not required when documented object residue differs",
            "roundtrip_equal": roundtrip, "size": len(packed), "sha256": sha256(packed),
            "original_size": len(original_packed), "original_sha256": sha256(original_packed),
            "first_difference": progbuild.first_difference(original_packed, packed),
            "returncode": rc, "argv": argv, "packer_sha256": packer["sha256"]}


def build_episode(tree: Path, episode: str, directory: Path) -> dict:
    work = directory / "dos"
    work.mkdir(parents=True, exist_ok=False)
    report = {"episode": episode, "ok": False, "status": "FAIL", "problems": [],
              "directory": str(directory), "assemblies": {}, "packed": {"status": "SKIPPED"}}
    try:
        report["inputs"] = copy_sources(tree, work)
        profiles = load_json(ROOT / "layout/profiles.json")
        profile = profiles["default"]
        options = profiles["profiles"][profile]["options"]
        steps = build_steps((work / "BUILD.BAT").read_text("latin1"), episode, options)
        report["profile"], report["steps"] = profile, steps
        atlas = load_json(EVIDENCE / "atlas.json")
        kinds = load_json(ROOT / "layout/routine-kinds.json")
        project = SimpleNamespace(atlas=atlas, kinds=kinds)
        # No fallback that writes build/oracle or any supervisor-owned products.
        for name in ("image.bin", "relocs.json", "unpacked.exe"):
            if not (oracle.OUT / episode / name).is_file():
                raise RuntimeError("missing oracle prerequisite; run tools/oracle.py first")
        image, relocs = oracle.load_image(episode)
        unpacked = (oracle.OUT / episode / "unpacked.exe").read_bytes()
        locked = load_json(oracle.LOCK)["episodes"][episode]
        if sha256(unpacked) != locked["unpacked"]["canonical_mz_sha256"]:
            raise ValueError("canonical oracle MZ differs from its lock")
        original_packed = oracle.find_asset(oracle.EXE_NAMES[episode]).read_bytes()
        if sha256(original_packed) != locked["packed"]["sha256"]:
            raise ValueError("original packed asset differs from its lock")
        census_path = BUILD / "census" / (episode + ".json")
        cen = load_json(census_path)
        report["proof_inputs"] = {str(p.relative_to(ROOT)): sha256_file(p) for p in (
            census_path, EVIDENCE / "atlas.json", ROOT / "layout/routine-kinds.json",
            ROOT / "layout/profiles.json", ROOT / "layout/toolchain.json", oracle.LOCK,
            BUILD / "datamap" / (episode + ".json"),
            *[Path(__file__).with_name(n) for n in ("standalone.py", "mergeeps.py", "progbuild.py",
                "asmproof.py", "omf.py", "tpc.py", "toolchain.py", "mz.py", "tpmap.py", "oracle.py", "lz91.py",
                "rename.py")])}
        names_path = ROOT / "layout/names.json"
        if names_path.is_file():
            report["proof_inputs"]["layout/names.json"] = sha256_file(names_path)
        objects = {}
        for command, args in steps:
            if command != "tasm":
                continue
            name = args[-1].split(",")[0].rsplit(".", 1)[0].upper()
            unit = next(u for u, n in mergeeps.OBJECT_NAMES.items() if n == name)
            assembly = run_tasm(args, work)
            report["assemblies"][unit] = assembly
            if not assembly["ok"]:
                raise RuntimeError(f"{name}: TASM failed; see {work / (name + '.LOG')}")
            objects[unit] = obj = OmfReader().read((work / (name + ".OBJ")).read_bytes(), name + ".OBJ")
            proof = asmproof.prove(obj, assembly_context(unit, episode))
            recipe_path = ROOT / "recipes" / ("obj_" + unit + ".json")
            recipe = load_json(recipe_path)["episodes"][episode]
            report["proof_inputs"][str(recipe_path.relative_to(ROOT))] = sha256_file(recipe_path)
            assembly["proof"] = vars(proof)
            if proof.status != "EQUAL" or [list(r) for r in proof.holes] != recipe["holes"] or proof.size != recipe["size"]:
                raise ValueError(f"{name}: assembled bytes/extent/undefined storage differs from accepted object proof")
        shutil.copyfile(toolchain.tool("TURBO.TPL"), work / "TURBO.TPL")
        toolchain.verify_all()
        args = next(args for command, args in steps if command == "tpc")
        rc, log, argv = toolchain.run_dos("TPC.EXE", args, work)
        (work / "TPC.LOG").write_bytes(log)
        report["compile"] = {"argv": argv, "returncode": rc, "toolchain": toolchain.identity(),
                             "log_sha256": sha256(log)}
        if rc != 0 or b"Error" in log or not (work / "SAM.EXE").is_file() or not (work / "SAM.MAP").is_file():
            raise RuntimeError(f"TPC failed; see {work / 'TPC.LOG'}")
        executable, map_text = (work / "SAM.EXE").read_bytes(), (work / "SAM.MAP").read_text("latin1")
        report["compile"]["executable_sha256"] = sha256(executable)
        # Measure the same runtime DATA anchors as progbuild. This diagnostic
        # compile is isolated and contributes no object/TPU to the game build.
        with progbuild.isolated_tools(directory / "diagnostics"):
            anchors = progbuild.library_anchors(episode, project, cen, image, [f"/DSAM{episode[-1]}", *options])
        report["library_anchors"] = anchors
        globals_, expected_routines = source_layout(work, episode)
        generated = SimpleNamespace(episode=episode, globals=globals_, routines={},
                                    expected_routines=expected_routines)
        report["comparison"] = comparison = progbuild.compare_image(project, generated, cen, image, relocs,
            mz.parse(unpacked).header, executable, map_text, anchors)
        # TP5's ordinary empty heap is outside the loaded image. progbuild's
        # generic unexpected-segment list includes it; validate it explicitly.
        heap = [s for s in tpmap.parse(map_text).segments if s.name.upper() == "HEAP"]
        header = mz.parse(executable).header
        comparison["zero_length_heap"] = len(heap) == 1 and heap[0].cls.upper() == "HEAP" and heap[0].length == 0 \
            and heap[0].start == header["ss"] * 16 + header["sp"]
        report["object_holes"] = holes = progbuild.object_holes(project, episode, cen, image, objects, executable, map_text)
        report.update(verify_comparison(image, mz.parse(executable).image, holes, comparison,
                                       dict(zip(atlas["units"], cen["segments"]))))
        copy_args = next(args for command, args in steps if command == "copy")
        shutil.copyfile(work / copy_args[0], work / copy_args[1])
        report["packed"] = pack_episode(work, episode, executable, original_packed)
        report.setdefault("checks", {})["LZEXE round trip"] = report["packed"]["roundtrip_equal"]
        report["ok"] = report["ok"] and report["packed"]["roundtrip_equal"]
        if report["ok"] and report["differing_bytes"] == 0 and report["packed"]["status"] != "EQUAL":
            report["ok"] = False
            report["problems"].append("equal load image must also repack byte-identically")
        # Build tools must not edit any input source.
        if any(sha256_file(work / n) != h for n, h in report["inputs"].items()):
            raise ValueError("a standalone input was modified during the build")
        report["status"] = "OK" if report["ok"] else "FAIL"
    except (OSError, ValueError, KeyError, RuntimeError, TimeoutError, StopIteration) as exc:
        report["ok"], report["status"] = False, "FAIL"
        report["problems"].append(str(exc))
    atomic_json(directory / "report.json", report)
    return report


def summary(report: dict) -> str:
    ep = report["episode"]
    if "equal_bytes" not in report:
        return f"{ep}: FAIL: " + "; ".join(report["problems"])
    checks = ", ".join(f"{k} {'equal' if v else 'DIFFERS'}" for k, v in report["checks"].items())
    line = (f"{ep}: {report['status']} {report['equal_bytes']}/{report['image_size']} bytes equal; "
            f"{report['residue_bytes_differing']} residue bytes differ; "
            f"{report['outside_residue_count']} outside residue; {checks}; "
            f"packed vs original {report['packed']['status']}")
    return line + ("; " + "; ".join(report["problems"]) if report["problems"] else "")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("tree", type=Path)
    ap.add_argument("--episodes", default=",".join(EPISODES))
    ap.add_argument("--output-dir", type=Path, default=OUT,
                    help="receipt directory (default: standalone worker directory)")
    args = ap.parse_args(argv)
    eps = args.episodes.split(",")
    if not eps or any(ep not in EPISODES for ep in eps) or len(set(eps)) != len(eps):
        ap.error("--episodes must be a comma-separated subset of sam1,sam2,sam3")
    run = args.output_dir / uuid.uuid4().hex[:12]
    reports = {}
    for ep in eps:
        print(f"{ep}: building standalone sources in {run / ep}", flush=True)
        reports[ep] = build_episode(args.tree, ep, run / ep)
        print(summary(reports[ep]), flush=True)
    atomic_json(run / "report.json", reports)
    atomic_json(args.output_dir / "latest.json", {"run": str(run), "episodes": reports})
    (run / "report.txt").write_text("\n".join(summary(r) for r in reports.values()) + "\n")
    print(f"Report: {run / 'report.json'}")
    return 0 if all(r["ok"] for r in reports.values()) else 1


if __name__ == "__main__":
    sys.exit(main())
