"""Merge generated episode sources into a self-contained historical DOS tree.

    python tools/mergeeps.py --output build/workers/sol-standalone/game

Pascal is aligned on complete declarations and statements, not individual
tokens or repeated END lines. Strings, comments, parameter lists, records,
compound statements and existing conditional regions are indivisible. Common
compound statements can be refined recursively to their contained statements.
ASM is aligned on complete logical lines (including continuation lines).
"""
from __future__ import annotations

import argparse
import difflib
import json
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
EPISODES = ("sam1", "sam2", "sam3")
PASCAL_FILES = ("SAM.PAS", *(f"U{i}.PAS" for i in range(1, 10)))
OBJECT_NAMES = {"p": "CMOSPIT", "u4": "TEXTOUT", "u5": "GENUS",
                "u6": "JOYSTICK", "u8": "DECODE", "u9": "PROGRAPX"}
DEFAULT_OUTPUT = ROOT / "build/workers/sol-standalone/game"
TOKEN = re.compile(r"'(?:[^']|'')*'|\{[^}]*\}|\(\*.*?\*\)|"
                   r"[A-Za-z_][A-Za-z_0-9]*|\s+|.", re.S)
CONDITIONAL = re.compile(r"\{\$\s*(IFDEF|IFNDEF|IFOPT|ELSE|ENDIF)\b([^}]*)\}", re.I)


def normalize(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\r", "\n")


def pascal_atoms(text: str) -> list[str]:
    """Lossless, conservative statement/declaration boundaries for TP 5.0.

    A section keyword is a boundary; a declaration's internal semicolons
    (record fields, typed constants and formal parameters) never are. A
    BEGIN/CASE/REPEAT statement stays whole, including its closing END/UNTIL.
    Only line boundaries outside lexical tokens can receive new directives.
    """
    text = normalize(text)
    atoms, stack = [], []
    start = parens = brackets = conditions = 0
    complete = False
    for m in TOKEN.finditer(text):
        token, word = m[0], m[0].lower()
        directive = CONDITIONAL.fullmatch(token)
        if directive:
            kind = directive[1].upper()
            if kind.startswith("IF"):
                conditions += 1
            elif kind == "ENDIF":
                conditions -= 1
                if conditions < 0:
                    raise ValueError("unmatched Pascal ENDIF")
            complete = not stack and not parens and not brackets and not conditions
        elif token.startswith(("'", "{", "(*")):
            # Compiler switches/comments occupy their own complete lines.
            if not text[start:m.start()].strip() and not conditions:
                complete = not stack and not parens and not brackets
        elif token.isspace():
            if "\n" in token and complete and not (stack or parens or brackets or conditions):
                at = m.start() + token.index("\n") + 1
                atoms.append(text[start:at])
                start, complete = at, False
        else:
            if token == "(":
                parens += 1
            elif token == ")":
                parens -= 1
            elif token == "[":
                brackets += 1
            elif token == "]":
                brackets -= 1
            elif not parens and not brackets:
                if word in ("record", "begin", "repeat"):
                    stack.append(word)
                elif word == "case" and "record" not in stack:
                    stack.append(word)
                elif word == "end" and stack:
                    stack.pop()
                elif word == "until" and stack and stack[-1] == "repeat":
                    stack.pop()
            complete = not (stack or parens or brackets or conditions) and (
                token in (";", ".") or word in
                ("interface", "implementation", "type", "var", "const", "label"))
    if conditions:
        raise ValueError("unclosed Pascal conditional")
    if stack or parens or brackets:
        raise ValueError("unbalanced Pascal declaration/statement")
    if start < len(text):
        atoms.append(text[start:])
    return atoms


def asm_atoms(text: str) -> list[str]:
    atoms, pending = [], ""
    for line in normalize(text).splitlines(keepends=True):
        pending += line
        if not line.rstrip().endswith("\\"):
            atoms.append(pending)
            pending = ""
    if pending:
        atoms.append(pending)
    return atoms


def conditional(parts: list[str], language: str) -> str:
    """Use one branch for each distinct variant; omit empty positive branches."""
    def mark(kind, ep=""):
        return ("{$" + kind + (" " + ep.upper() if ep else "") + "}\n"
                if language == "pas" else kind + (" " + ep.upper() if ep else "") + "\n")
    parts = [s if not s or s.endswith("\n") else s + "\n" for s in parts]
    if len(set(parts)) == 1:
        return parts[0]
    if sum(bool(s) for s in parts) == 1:
        i = next(i for i, s in enumerate(parts) if s)
        return mark("IFDEF", EPISODES[i]) + parts[i] + mark("ENDIF")
    if len(set(parts)) == 2:
        single = next(i for i, s in enumerate(parts) if parts.count(s) == 1)
        shared = next(s for i, s in enumerate(parts) if i != single)
        return mark("IFDEF", EPISODES[single]) + parts[single] + mark("ELSE") + shared + mark("ENDIF")
    return "".join(mark("IFDEF", ep) + s + mark("ENDIF")
                   for ep, s in zip(EPISODES, parts) if s)


def common_anchors(sequences: list[list[str]]) -> list[tuple[int, int, int]]:
    maps = []
    for other in sequences[1:]:
        matches = difflib.SequenceMatcher(None, sequences[0], other, autojunk=False).get_matching_blocks()
        maps.append({a + i: b + i for a, b, size in matches for i in range(size)})
    return [(i, maps[0][i], maps[1][i]) for i in sorted(maps[0].keys() & maps[1].keys())]


def merge_sequences(sequences: list[list[str]], language: str) -> str:
    result, cursor = [], [0, 0, 0]
    for positions in [*common_anchors(sequences), tuple(map(len, sequences))]:
        parts = ["".join(s[a:b]) for s, a, b in zip(sequences, cursor, positions)]
        # Refine differing compound bodies while retaining whole nested controls.
        wrappers = [re.fullmatch(r"(\s*begin[^\S\n]*\n)(.*)(\n[^\S\n]*end[;.][^\S\n]*\n?)", s, re.I | re.S)
                    for s in parts] if language == "pas" and all(parts) else []
        if wrappers and all(wrappers) and len({m[1] for m in wrappers}) == len({m[3] for m in wrappers}) == 1:
            result.append(wrappers[0][1] + merge_sequences([pascal_atoms(m[2]) for m in wrappers], language) + wrappers[0][3])
        else:
            result.append(conditional(parts, language))
        if positions[0] < len(sequences[0]):
            result.append(sequences[0][positions[0]])
        cursor = [p + 1 for p in positions]
    return "".join(result)


def merge_text(sam1: str, sam2: str, sam3: str, language: str = "pas") -> str:
    if language not in ("pas", "asm"):
        raise ValueError("language must be pas or asm")
    texts = [normalize(s) for s in (sam1, sam2, sam3)]
    if len(set(texts)) == 1:
        return texts[0]
    split = pascal_atoms if language == "pas" else asm_atoms
    return merge_sequences([split(s) for s in texts], language)


def select_episode(text: str, episode: str, language: str = "pas") -> str:
    """DOS-free conditional evaluator used to verify merge round trips.

    Evaluate only episode IFDEF/IFNDEF; compiler switches and nonconditional
    comments/strings survive. Input conditionals must use the SAM symbols.
    """
    if episode not in EPISODES:
        raise ValueError("unknown episode")
    text = normalize(text)
    if language == "asm":
        rx = re.compile(r"(?im)^[ \t]*(IFDEF|IFNDEF|ELSE|ENDIF)\b([^\n]*)\n?")
        matches = list(rx.finditer(text))
    else:
        matches = [m for m in TOKEN.finditer(text) if CONDITIONAL.fullmatch(m[0])]
    result, stack, active, cursor = [], [], True, 0
    for m in matches:
        if active:
            result.append(text[cursor:m.start()])
        d = m if language == "asm" else CONDITIONAL.fullmatch(m[0])
        kind, symbol = d[1].upper(), d[2].strip().lower()
        end = m.end()
        if language == "pas" and not text[text.rfind("\n", 0, m.start()) + 1:m.start()].strip() and text[end:end + 1] == "\n":
            end += 1
        if kind in ("IFDEF", "IFNDEF"):
            if symbol not in EPISODES:
                raise ValueError(f"unsupported conditional symbol: {symbol}")
            truth = (symbol == episode) == (kind == "IFDEF")
            stack.append((active, truth, False))
            active = active and truth
        elif kind == "ELSE":
            if not stack or stack[-1][2]:
                raise ValueError("unmatched/duplicate ELSE")
            parent, truth, _ = stack[-1]
            stack[-1] = (parent, truth, True)
            active = parent and not truth
        elif kind == "ENDIF":
            if not stack:
                raise ValueError("unmatched ENDIF")
            active = stack.pop()[0]
        else:
            raise ValueError(f"unsupported conditional: {kind}")
        cursor = end
    if stack:
        raise ValueError("unclosed conditional")
    if active:
        result.append(text[cursor:])
    return "".join(result)


def build_batch(options: list[str]) -> str:
    lines = ["@echo off", "rem Turbo Pascal 5.0, TASM 1.0, LZEXE 0.91; tools on PATH.",
             'if "%1"=="1" goto build', 'if "%1"=="2" goto build',
             'if "%1"=="3" goto build', "echo Usage: BUILD 1 or BUILD 2 or BUILD 3", "goto end", ":build"]
    for name in OBJECT_NAMES.values():
        lines += [f"tasm /DSAM%1 {name}.ASM,{name}.OBJ,;", "if errorlevel 1 goto fail"]
    # /M does not invalidate an existing TPU merely because /D changed.
    for i in range(1, 10):
        lines.append(f"if exist U{i}.TPU del U{i}.TPU")
    lines += ["tpc /M /GD /DSAM%1 " + " ".join(options) + " SAM.PAS", "if errorlevel 1 goto fail",
              "copy SAM.EXE SAM%1.EXE > NUL", "if errorlevel 1 goto fail",
              "lzexe SAM%1.EXE", "if errorlevel 1 goto fail", "goto end", ":fail",
              "echo Build failed; see compiler or assembler output.", ":end"]
    return "\n".join(lines) + "\n"


def write_dos(path: Path, text: str):
    path.write_bytes(normalize(text).replace("\n", "\r\n").encode("latin1"))


def make_tree(variants: Path, output: Path, asm_sources: Path = ROOT / "src/asm") -> dict:
    """Read only generated game sources and accepted ASM; emit no binaries."""
    sources, manifest = {}, {"variants": {}, "files": {}}
    import hashlib
    for name in PASCAL_FILES:
        texts = [(variants / ep / name).read_text("latin1") for ep in EPISODES]
        merged = merge_text(*texts)
        for ep, original in zip(EPISODES, texts):
            if select_episode(merged, ep) != select_episode(original, ep):
                raise ValueError(f"merge round trip failed: {ep}/{name}")
        # Only the real external-object link names change, never $L+ switches.
        for unit, objname in OBJECT_NAMES.items():
            old = "P" if unit == "p" else unit.upper()
            merged = re.sub(r"\{\$L\s+" + old + r"\.OBJ\}", "{$L " + objname + ".OBJ}", merged, flags=re.I)
        sources[name] = merged
        manifest["variants"][name] = {ep: hashlib.sha256(normalize(t).encode("latin1")).hexdigest()
                                      for ep, t in zip(EPISODES, texts)}
    for unit, name in OBJECT_NAMES.items():
        texts = []
        for ep in EPISODES:
            # Support future generated per-episode ASM; currently all six agree.
            path = variants / ep / (unit.upper() + ".ASM")
            texts.append((path if path.exists() else asm_sources / (unit + ".asm")).read_text("latin1"))
        merged = merge_text(*texts, language="asm")
        for ep, original in zip(EPISODES, texts):
            if select_episode(merged, ep, "asm") != select_episode(original, ep, "asm"):
                raise ValueError(f"ASM merge round trip failed: {ep}/{name}")
        sources[name + ".ASM"] = merged
    profiles = json.loads((ROOT / "layout/profiles.json").read_text())
    options = profiles["profiles"][profiles["default"]]["options"]
    sources["BUILD.BAT"] = build_batch(options)
    sources["README.md"] = """# Secret Agent - standalone game source

One source tree builds all three episodes with Turbo Pascal 5.0 (including
its original TURBO.TPL), Turbo Assembler 1.0 and LZEXE 0.91. Put TPC, TASM
and LZEXE on the DOS PATH, and make TURBO.TPL available beside TPC or in
this directory. Run BUILD 1, BUILD 2 or BUILD 3. Define exactly one SAMn
symbol; BUILD selects it for both Pascal and assembly. The batch assembles
all six objects, makes SAM.PAS and its units, copies SAM.EXE to SAMn.EXE,
then packs that copy. SAM.EXE and SAM.MAP retain the unpacked build.
BUILD removes the nine generated U*.TPU files before compiling, so changing
episodes rebuilds every game unit. The host verifier always stages fresh,
isolated copies for each episode.

| File | Contents |
|---|---|
| SAM.PAS | Program, interrupt handlers and main loop |
| U1.PAS through U9.PAS | Original translation units; logical names retained |
| CMOSPIT.ASM | Program CMOS/date/PIT routines |
| TEXTOUT.ASM | U4 text writer |
| GENUS.ASM | U5 Genus PCX Programmer's Toolkit 3.56 |
| JOYSTICK.ASM | U6 joystick routines |
| DECODE.ASM | U8 asset decoder |
| PROGRAPX.ASM | U9 ProGraphx 2.0 EGA toolbox |

Compiler options: /M /GD /DSAMn /$S- /$I- /$R- /$B-; the program sets
$M 16384,0,655360. Crt, Dos and System come from the pinned TP 5.0 library.
No Python, reconstruction recipe, harness or oracle is needed to build
the game under DOS. The host comparison needs this reconstruction repo,
the pinned tools in layout/toolchain.json and the original game files.
From the repo run:

    python tools/standalone.py build/workers/sol-standalone/game
    python tools/standalone.py build/workers/sol-standalone/game --episodes sam2

The accepted whole-program reconstruction proves every defined code byte,
the DATA image, relocation set, entry/stack/allocation fields, link order
and unit initialization chain for SAM1, SAM2 and SAM3. The original
unpacked MZ header's storage size/order was lost when LZEXE packed it and
cannot be claimed equal. See the host report for this standalone build's
fresh measurements and the LZEXE round-trip check.

Exception: 102 bytes of undefined DB ? object storage (7 in CMOSPIT,
95 in PROGRAPX) contain compiler-buffer residue. The earlier generated
builds differed at 89/80/31 of these bytes for SAM1/SAM2/SAM3. Source
merging and line-number changes can change that residue; the verifier
lists both sides and permits differences only in the accepted holes.
No hole is filled and no linked byte is patched. Packed executables
therefore also differ from the originals; packed byte equality is not
claimed. LZEXE must preserve the freshly linked load image exactly.

Episode conditionals preserve whole declarations/statements and shared
source appears once. Address identifiers and U1..U9 names are retained
for the later readability phase. Original binaries/assets and historical
tool binaries are not included in this tree.
"""
    output.mkdir(parents=True, exist_ok=True)
    for name, text in sources.items():
        write_dos(output / name, text)
        manifest["files"][name] = hashlib.sha256((output / name).read_bytes()).hexdigest()
    return manifest


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--variants", type=Path, default=ROOT / "build/progbuild")
    ap.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = ap.parse_args(argv)
    manifest = make_tree(args.variants, args.output)
    (args.output.parent / "merge-report.json").write_text(json.dumps(manifest, indent=1) + "\n")
    print(f"Merged {len(manifest['files'])} files into {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
