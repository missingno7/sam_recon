"""Prove a linked assembly contribution directly from 16-bit OMF, without TPC.

    python tools/asmproof.py CAND.ASM --object u6 --worker NAME --listing

EQUAL covers initialized bytes, bound FIXUPPs and every PUBDEF. HOLES are
explicitly unproven storage, even when the corresponding EXE bytes are zero.
No linker is used to create the candidate comparison image. Unsupported OMF
constructs fail closed. Extents come from routine-kinds, translated by all
available atlas anchors within the contribution (one consistent delta).
"""
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import uuid
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import (BUILD, EVIDENCE, EPISODES, LAYOUT, atomic_bytes, atomic_json,
                    content_key, load_json, sha256, sha256_file)
from omf import MatchError, ObjectModule, OmfReader
import mz
import oracle
import toolchain


@dataclass
class Assembly:
    key: str
    ok: bool
    directory: Path
    log: str
    data: dict
    cached: bool = False

    def obj(self) -> bytes:
        return (self.directory / "CAND.OBJ").read_bytes()


def assemble(source: str, *, listing: bool = False, cache_root: Path | None = None,
             scratch_root: Path | None = None, fresh: bool = False,
             timeout: int = 60) -> Assembly:
    """Pinned TASM in isolated scratch; verified content-addressed outputs.

    ASMPROOF_CACHE can relocate research outputs for a restricted worker.
    No includes or preexisting object files are staged into the assembler run.
    Concurrent producers use separate scratch dirs and atomic cache writes.
    """
    lk = toolchain.lock()
    asm, runner = lk["assembler"], lk["runner"]
    program, host = Path(asm["executable"]), Path(runner["executable"])
    toolchain._check(program, asm["sha256"])
    toolchain._check(host, runner["sha256"])
    if re.search(r"(?im)^\s*(?:include|incbin)\b", source):
        raise MatchError("Standalone source required: INCLUDE/INCBIN inputs are not staged or hashed")
    staged = source.replace("\r\n", "\n").replace("\n", "\r\n").encode("latin1")
    args = ["CAND.ASM,CAND.OBJ," + ("CAND.LST" if listing else "") + ";"]
    request = {"kind": "tasm", "source": sha256(staged), "argv": args,
               "assembler": asm["sha256"], "runner": runner["sha256"],
               "runner_args": runner["args"],
               "wrapper": sha256_file(Path(__file__)),
               "parser": sha256_file(Path(__file__).with_name("omf.py"))}
    key = content_key(request)
    cache = Path(cache_root or os.environ.get("ASMPROOF_CACHE", BUILD / "cc-cache"))
    dest = cache / key[:2] / key
    if not fresh and (dest / "receipt.json").is_file():
        data = load_json(dest / "receipt.json")
        outputs = data.get("outputs", {})
        if data.get("request") == request and outputs and all(
                (dest / n).is_file() and sha256_file(dest / n) == h
                for n, h in outputs.items()):
            return Assembly(key, data["ok"], dest,
                            (dest / "assembler.log").read_text("latin1"), data, True)
    work = Path(scratch_root or cache / "scratch" / "tasm") / uuid.uuid4().hex
    work.mkdir(parents=True)
    (work / "CAND.ASM").write_bytes(staged)
    bindir = str(program.parent)
    env = {"PATH": bindir, "MSDOS_PATH": bindir, "TEMP": str(work.resolve()),
           "TMP": str(work.resolve()), "MSDOS_TEMP": str(work.resolve()),
           "SystemRoot": os.environ.get("SystemRoot", "C:\\Windows")}
    argv = [str(host), *runner["args"], str(program), *args]
    try:
        proc = subprocess.run(argv, cwd=work, env=env, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                              timeout=timeout, **toolchain._no_window())
        rc, out = proc.returncode, proc.stdout
    except subprocess.TimeoutExpired as exc:
        rc, out = -9, (exc.output or b"") + b"\n[runner] TIMEOUT\n"
    ok = rc == 0 and (work / "CAND.OBJ").is_file() and b"**Error**" not in out
    outputs = {"CAND.ASM": staged, "assembler.log": out}
    for name in ("CAND.OBJ", "CAND.LST"):
        if (work / name).is_file():
            outputs[name] = (work / name).read_bytes()
    data = {"key": key, "request": request, "ok": ok, "returncode": rc,
            "argv": argv, "outputs": {n: sha256(b) for n, b in outputs.items()}}
    (work / "assembler.log").write_bytes(out)
    atomic_json(work / "receipt.json", data)
    for name, blob in outputs.items():
        atomic_bytes(dest / name, blob)
    atomic_json(dest / "receipt.json", data)
    return Assembly(key, ok, dest, out.decode("latin1"), data)


@dataclass
class Context:
    episode: str
    unit: str
    start: int                    # contribution offset in its original unit
    original: bytes               # exactly the contribution extent
    paras: dict                   # logical unit -> MZ paragraph, including DATA
    routines: dict                # logical id (lowercase) -> (unit, entry)
    globals: dict                 # d_XXXX (uppercase) -> DS offset
    relocs: set = field(default_factory=set)  # sites relative to contribution
    extra_offset: Callable | None = None

    def external(self, name: str) -> tuple[str, int]:
        if name.upper() in self.globals:
            return "DATA", self.globals[name.upper()]
        if re.fullmatch(r"d_(?:sam[123]_)?[0-9a-f]{4}", name, re.I):
            off = self.extra_offset(name.upper(), self.episode) if self.extra_offset else None
            if off is not None:
                return "DATA", off
        if name.lower() in self.routines:
            return self.routines[name.lower()]
        raise MatchError(f"Unbound EXTDEF {name}")


def translated_extent(unit: str, episode: str, objects: dict, atlas: dict) -> tuple[int, int]:
    spec = objects[unit]
    start, end = int(spec["sam1_start"], 16), int(spec["sam1_end"], 16)
    deltas = set()
    for row in atlas["routines"].values():
        a, b = row["episodes"].get("sam1"), row["episodes"].get(episode)
        if a and a["unit"] == unit and start <= a["entry"] < end:
            if b is None or b["unit"] != unit:
                raise MatchError(f"Object anchor absent or moved to another unit in {episode}")
            deltas.add(b["entry"] - a["entry"])
    if len(deltas) != 1:
        raise MatchError(f"Object {unit} has no unique atlas translation in {episode}: {deltas}")
    delta = deltas.pop()
    return start + delta, end + delta


def original_context(unit: str, episode: str) -> Context:
    atlas = load_json(EVIDENCE / "atlas.json")
    objects = load_json(LAYOUT / "routine-kinds.json")["objects"]
    start, end = translated_extent(unit, episode, objects, atlas)
    cen = load_json(BUILD / "census" / f"{episode}.json")
    segs = dict(zip(atlas["units"], cen["segments"]))
    seg = segs[unit]
    base = seg["para"] * 16
    if not 0 <= start < end <= seg["size"]:
        raise MatchError("Translated object extent exceeds census unit segment")
    img, relocs = oracle.load_image(episode)
    paras = {u: s["para"] for u, s in segs.items()}
    paras["DATA"] = cen["ds_para"]
    routines = {lid.lower(): (e["unit"], e["entry"])
                for lid, row in atlas["routines"].items()
                if (e := row["episodes"].get(episode))}
    globals_ = {n.upper(): int(v[episode], 16)
                for n, v in load_json(LAYOUT / "data.json")["globals"].items()
                if v.get(episode)}
    def extra(name, ep):
        import harness
        return harness.extra_offset(name, ep)
    return Context(episode, unit, start, img[base + start:base + end], paras,
                   routines, globals_, {a - base - start for a in mz.linear(relocs)
                                        if base + start <= a < base + end}, extra)


def code_segment(obj: ObjectModule) -> str:
    codes = [s for s in obj.segment_defs if s["name"].upper() == "CODE"]
    if len(codes) != 1:
        raise MatchError("Exactly one CODE SEGDEF is required")
    code = codes[0]
    if code["alignment"] != "byte" or code["combine"] != "public" or code["class"]:
        raise MatchError("TP5 object must use CODE SEGMENT BYTE PUBLIC, without a class")
    for s in obj.segment_defs:
        if s["name"] != code["name"] and s["length"]:
            raise MatchError(f"Non-CODE contribution {s['name']} is outside this proof")
    return code["name"]


def ranges(mask: bytes, value: int = 0) -> list[tuple[int, int]]:
    out, start = [], None
    for i, b in enumerate(mask + bytes([1 - value])):
        if b == value and start is None:
            start = i
        elif b != value and start is not None:
            out.append((start, i))
            start = None
    return out


def _address(kind: str, name: str, ctx: Context, obj: ObjectModule,
             code: str, *, frame: bool = False) -> tuple[str, int]:
    if kind == "external":
        unit, off = ctx.external(name)
        return unit, 0 if frame else off
    if kind in ("segment", "location"):
        if name == code:
            return ctx.unit, 0 if frame else ctx.start
        if name.upper() in ("DATA", "_DATA"):
            return "DATA", 0
        raise MatchError(f"Unbound segment {name}")
    if kind == "group":
        group = next((g for g in obj.groups if g["name"] == name), None)
        if group and group["segments"] and all(
                s.upper() in ("DATA", "_DATA") for s in group["segments"]):
            return "DATA", 0
        raise MatchError(f"Unbound group {name}")
    raise MatchError(f"Unsupported address kind {kind}: {name}")


def bind_fixup(f: dict, obj: ObjectModule, code: str, ctx: Context) -> tuple[bytes, set, str]:
    """Expected linked field and its MZ relocation sites, never a mask-only waiver."""
    loc, at, width = f["loc"], f["offset"], f["width"]
    if loc not in ("offset16", "base16", "pointer32") or width != {
            "offset16": 2, "base16": 2, "pointer32": 4}.get(loc):
        raise MatchError(f"Unsupported fixup location {loc}")
    target_unit, target_off = _address(f["target_kind"], f["target"], ctx, obj, code)
    if f["frame_kind"] == "target":
        frame_unit, frame_off = target_unit, 0
    else:
        frame_unit, frame_off = _address(f["frame_kind"], f["frame"], ctx, obj, code, frame=True)
    # TP5 resolves a code EXTRN through its Pascal symbol's owning unit. TASM
    # conventionally associates EXTRN foo:FAR with the current CODE SEGDEF;
    # TP does not use that frame to misaddress a call to another unit. A pinned
    # cross-unit/DS/near-call probe is retained in sol-asmproof/bindings/.
    if f["target_kind"] == "external" and target_unit != "DATA" and \
            f["frame_kind"] == "segment" and f["frame"] == code:
        frame_unit, frame_off = target_unit, 0
    if frame_unit not in ctx.paras or target_unit not in ctx.paras:
        raise MatchError("Fixup unit has no census segment")
    # TP5's contributions combine into unit segments; a DS frame cannot silently
    # bind a code target or vice versa, even if paragraph arithmetic coincides.
    if frame_unit != target_unit:
        raise MatchError(f"Fixup frame {frame_unit} differs from target {target_unit}")
    raw = obj.segment_bytes(code)[at:at + width]
    disp = f["displacement"]
    if f["target_kind"] == "segment" and f["target"] == code and loc != "base16":
        relative_target = disp + int.from_bytes(raw[:2], "little")
        if not 0 <= relative_target <= obj.segment_length(code):
            raise MatchError("Internal CODE reference points outside the object")
    if f["self_relative"]:
        if loc != "offset16" or target_unit != ctx.unit:
            raise MatchError("Self-relative reference must stay in the same unit")
        value = target_off + disp + int.from_bytes(raw, "little") - (ctx.start + at + width)
        return (value & 0xffff).to_bytes(2, "little"), set(), f"relative {f['target']}"
    reloc_sites = set()
    out = b""
    if loc in ("offset16", "pointer32"):
        value = target_off + disp + int.from_bytes(raw[:2], "little") - frame_off
        out = (value & 0xffff).to_bytes(2, "little")
    if loc in ("base16", "pointer32"):
        seg_at = at + (2 if loc == "pointer32" else 0)
        addend = int.from_bytes(raw[-2:], "little")
        if addend or (loc == "base16" and disp):
            raise MatchError("Nonzero segment addend/displacement is not a unit segment")
        out += ctx.paras[frame_unit].to_bytes(2, "little")
        reloc_sites.add(seg_at)
    return out, reloc_sites, f"{loc} {f['target']} -> {target_unit}:{target_off + disp:04x}"


@dataclass
class Proof:
    episode: str
    status: str = "EQUAL"
    size: int = 0
    defined: int = 0
    bound: int = 0
    publics: int = 0
    holes: list = field(default_factory=list)  # exclusive ranges in object coordinates
    first_diff: int | None = None
    reason: str = ""
    disassembly: str = ""

    def short(self) -> str:
        holes = sum(b - a for a, b in self.holes)
        hole_text = f"; HOLES {holes} " + ",".join(f"+{a:04x}-+{b:04x}" for a, b in self.holes) \
            if holes else "; HOLES 0"
        if self.status == "EQUAL":
            return (f"{self.episode}: EQUAL ({self.defined}/{self.size} defined bytes, "
                    f"{self.bound} bindings, {self.publics} publics){hole_text}")
        where = f" at +{self.first_diff:04x}" if self.first_diff is not None else ""
        return f"{self.episode}: DIFF{where}: {self.reason}{hole_text}" + \
            (f" | {self.disassembly}" if self.disassembly else "")


def _disassembly(original: bytes, candidate: bytes, offset: int, base: int, entries: list) -> str:
    import capstone
    md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
    # Start from the nearest public entry, avoiding decoding a fixup operand as
    # an instruction. CS data before the first public falls back to raw bytes.
    entry = max((e for e in entries if e <= offset), default=0)
    def describe(blob):
        for ins in md.disasm(blob[entry:], base + entry):
            if ins.address <= base + offset < ins.address + ins.size:
                return f"{ins.address:04x} {ins.bytes.hex()} {ins.mnemonic} {ins.op_str}"
        return blob[offset:offset + 8].hex()
    return "original " + describe(original) + " / candidate " + describe(candidate)


def prove(obj: ObjectModule, ctx: Context) -> Proof:
    result = Proof(ctx.episode, size=len(ctx.original))
    failures = []
    def fail(at, reason):
        failures.append((at, reason))
    try:
        code = code_segment(obj)
        length = obj.segment_length(code)
        if length != result.size:
            raise MatchError(f"SEGDEF length {length} differs from object extent {result.size}")
        mask = obj.segment_defined[code]
        if len(mask) != length:
            raise MatchError("Missing initialized-byte coverage")
        result.holes, result.defined = ranges(mask), sum(mask)
        raw = obj.segments.get(code, bytes(length))
        linked = bytearray(raw)
        patched, expected_relocs = set(), set()
        for f in obj.linker_fixups:
            if f["segment"] != code:
                raise MatchError("FIXUPP outside CODE")
            at, width = f["offset"], f["width"]
            sites = set(range(at, at + width))
            if at < 0 or at + width > length or not all(mask[at:at + width]):
                fail(at, "FIXUPP overlaps a hole or lies outside the extent")
                continue
            if sites & patched:
                fail(at, "Overlapping FIXUPPs")
                continue
            patched |= sites
            try:
                bound, relocs, description = bind_fixup(f, obj, code, ctx)
                linked[at:at + width] = bound
                expected_relocs |= relocs
                if bound != ctx.original[at:at + width]:
                    fail(at, f"Binding {description}: original {ctx.original[at:at + width].hex()} "
                             f"!= expected {bound.hex()}")
                else:
                    result.bound += 1
            except MatchError as exc:
                fail(at, str(exc))
        # Both relocation presence and the expected target unit must bind.
        # Relocations wholly within holes remain outside initialized-byte proof.
        original_relocs = {a for a in ctx.relocs if
                           any(mask[max(a, 0):min(a + 2, length)])}
        for at in sorted(expected_relocs ^ original_relocs):
            fail(at, "MZ relocation only in " + ("original" if at in original_relocs else "candidate"))
        seen = set()
        for p in obj.publics:
            name, at = p["name"].lower(), p["offset"]
            if p["segment"] != code or name in seen:
                fail(at, f"Invalid or duplicate PUBDEF {p['name']}")
                continue
            seen.add(name)
            if ctx.routines.get(name) != (ctx.unit, ctx.start + at) or not 0 <= at < length:
                fail(at, f"PUBDEF {p['name']} does not bind an original routine entry")
            else:
                result.publics += 1
        for at, defined in enumerate(mask):
            if defined and at not in patched and raw[at] != ctx.original[at]:
                fail(at, f"Byte {raw[at]:02x} != original {ctx.original[at]:02x}")
                break
        if failures:
            result.first_diff, result.reason = min(failures, key=lambda f: f[0])
            result.status = "DIFF"
            entries = [p["offset"] for p in obj.publics_in(code)] + [
                off - ctx.start for unit, off in ctx.routines.values()
                if unit == ctx.unit and ctx.start <= off < ctx.start + length]
            result.disassembly = _disassembly(ctx.original, bytes(linked), result.first_diff,
                                               ctx.start, entries)
    except MatchError as exc:
        result.status, result.reason = "DIFF", str(exc)
    return result


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("source", type=Path)
    ap.add_argument("--object", required=True, choices=("p", "u4", "u5", "u6", "u8", "u9"))
    ap.add_argument("--episodes", default=",".join(EPISODES))
    ap.add_argument("--worker")
    ap.add_argument("--listing", action="store_true")
    args = ap.parse_args()
    episodes = args.episodes.split(",")
    if not episodes or any(e not in EPISODES for e in episodes) or len(set(episodes)) != len(episodes):
        ap.error("--episodes must be a comma-separated subset of sam1,sam2,sam3")
    if args.worker and not re.fullmatch(r"[a-zA-Z0-9_-]+", args.worker):
        ap.error("Invalid worker name")
    try:
        assembled = assemble(args.source.read_text("latin1"), listing=args.listing)
        if not assembled.ok:
            for ep in episodes:
                print(f"{ep}: DIFF: assembly failed; {assembled.directory / 'assembler.log'}")
            print(assembled.log.rstrip(), file=sys.stderr)
            return 1
        obj = OmfReader().read(assembled.obj(), args.source.name)
        results = []
        for ep in episodes:
            try:
                result = prove(obj, original_context(args.object, ep))
            except (MatchError, OSError, ValueError, KeyError) as exc:
                result = Proof(ep, status="DIFF", reason=str(exc))
            results.append(result)
            print(result.short())
        if args.worker:
            doc = {"object": args.object, "source": str(args.source),
                   "source_sha256": sha256_file(args.source), "assembly": assembled.data,
                   "assembly_directory": str(assembled.directory),
                   "proof_inputs": {str(p.relative_to(LAYOUT.parent)): sha256_file(p)
                       for p in (Path(__file__), *[Path(__file__).with_name(n) for n in
                                 ("omf.py", "common.py", "toolchain.py", "oracle.py", "mz.py", "harness.py")],
                                 EVIDENCE / "atlas.json", LAYOUT / "routine-kinds.json",
                                 LAYOUT / "data.json", LAYOUT / "oracle.lock.json",
                                 *[BUILD / "census" / f"{ep}.json" for ep in episodes])},
                   "results": [vars(r) for r in results]}
            atomic_json(BUILD / "workers" / args.worker / "proofs" / args.object /
                        (assembled.key + ".json"), doc)
        return 0 if all(r.status == "EQUAL" for r in results) else 1
    except (MatchError, toolchain.ToolchainError, OSError, ValueError, KeyError) as exc:
        for ep in episodes:
            print(f"{ep}: DIFF: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
