"""Phase 2: generate and compare the actual linked Turbo Pascal program.

    python tools/progbuild.py [--episodes sam1,sam2,sam3] [--keep]

Only accepted recipe sources are inputs. No harness stubs, retention calls,
absolute overlays, copied oracle initializers, or post-link edits are used.
Incomplete/conflicting inputs produce a BLOCKED report and reviewable source
previews, never an EQUAL claim. Compiler and assembler research outputs are
isolated below build/progbuild, including their content-addressed caches.

generate() is pure and accepts measured declaration sizes and calling kinds;
the source-generation tests do not need DOS tools. The CLI measures SizeOf
with the pinned compiler before declaring BSS gaps, then checks every public
against the requested episode's layout. Object holes remain raw differences.
"""
from __future__ import annotations

import argparse
from contextlib import contextmanager
from dataclasses import dataclass, field
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import (BUILD, EPISODES, ROOT, atomic_bytes, atomic_json, load_json,
                    sha256, sha256_file)
import asmproof
import harness
import mz
import oracle
import toolchain
import tpc
import tpmap
from omf import OmfReader

OUT = BUILD / "progbuild"
GAME = ("p", *(f"u{i}" for i in range(1, 10)))
USES = ("Dos", "U9", "Crt", "U8", "U7", "U6", "U5", "U4", "U3", "U2", "U1")
MAP_NAMES = {"p": "SAM", "sys": "SYSTEM", "dos": "DOS", "crt": "CRT",
             **{u: u.upper() for u in GAME if u != "p"}}
GLOBAL_RX = re.compile(r"\bd_(?:(sam[123])_)?([0-9a-f]{4})\b", re.I)
LEX = re.compile(r"'(?:[^']|'')*'|\{[^}]*\}|\(\*.*?\*\)|[A-Za-z_][A-Za-z_0-9]*", re.S)
HEADER_RX = re.compile(r"(?im)^\s*(procedure|function)\s+(\w+)\b")


def norm(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip().rstrip(";")).lower()


def rename(text: str, names: dict) -> str:
    """Rename identifiers, preserving comments, directives and string literals."""
    return LEX.sub(lambda m: names.get(m[0].lower(), m[0]), text)


def signature(header: str) -> str:
    """Same signature convention as tools/decls.py; parameter names are irrelevant."""
    m = re.match(r"(procedure|function)\s+\w+\s*(?:\((.*)\))?\s*(?::\s*(.*))?$", norm(header))
    if not m:
        return norm(header)
    params = []
    for group in filter(None, (s.strip() for s in (m[2] or "").split(";"))):
        mode = "var " if group.startswith("var ") else ""
        if mode:
            group = group[len(mode):]
        names, _, typ = group.partition(":")
        params.extend([mode + typ.strip()] * len(names.split(",")))
    return m[1] + "(" + ", ".join(params) + ")" + (": " + m[3].strip() if m[3] else "")


def own_header(body: str, lid: str) -> str | None:
    text = harness._strip_comments(body)
    m = re.search(r"(?is)(?:^|\n)\s*((?:procedure|function)\s+" + re.escape(lid) +
                  r"\b\s*(?:\([^)]*\))?\s*(?::\s*[\w\[\]]+)?\s*;)", text)
    return m[1].strip() if m else None


def canonical_sections(text: str) -> dict:
    parts, current = {"types": "", "globals": "", "routines": ""}, None
    for line in text.splitlines():
        m = re.match(r"\s*\{@(types|globals|routines)\}\s*$", line, re.I)
        if m:
            current = m[1].lower()
        elif current:
            parts[current] += line + "\n"
    return parts


def referenced_types(typ: str, definitions: dict) -> dict:
    """Expand named dependencies so pointer/array aliases retain their local view."""
    found, pending = {}, [typ]
    while pending:
        text = pending.pop()
        for token in re.findall(r"\b[A-Za-z_]\w*\b", text):
            name = token.lower()
            if name in definitions and name not in found:
                found[name] = definitions[name]
                pending.append(definitions[name].split("=", 1)[-1])
    return found


@dataclass
class Candidate:
    lid: str
    recipe: dict
    text: str
    path: str = ""
    sections: dict = field(init=False)
    decls: harness.Decls = field(init=False)
    header: str | None = field(init=False)
    definitions: list = field(init=False)
    names: dict = field(init=False)

    def __post_init__(self):
        self.sections = harness.split_sections(self.text)
        self.decls = harness.parse_decls(self.sections["decls"])
        self.header = own_header(self.sections["body"], self.lid)
        self.definitions = [m[2].lower() for m in HEADER_RX.finditer(
            harness._strip_comments(self.sections["body"]))]
        # Preserve distinct source-local types without merging their field names.
        # Spelling changes have no effect on TP's type layout or instruction bytes.
        self.names = {harness._decl_name(x): "t_" + self.lid + "_" + harness._decl_name(x)
                      for x in self.decls.shared}

    @property
    def unit(self):
        return self.recipe.get("unit", self.lid.split("_", 1)[0])


@dataclass
class Project:
    atlas: dict
    data: dict
    extra: dict
    kinds: dict
    canonical: str
    candidates: dict
    objects: dict = field(default_factory=dict)  # unit -> (recipe, source text)
    input_hashes: dict = field(default_factory=dict)
    input_problems: list = field(default_factory=list)

    @classmethod
    def read(cls, root: Path = ROOT):
        paths = [root / n for n in ("evidence/atlas.json", "layout/data.json",
                 "layout/data-extra.json", "layout/routine-kinds.json",
                 "src/decls/canonical.pas", "layout/profiles.json", "layout/toolchain.json",
                 "layout/oracle.lock.json")]
        atlas, data, extra, kinds = (load_json(p) for p in paths[:4])
        project = cls(atlas, data["globals"], extra["globals"], kinds,
                      paths[4].read_text("latin1"), {})
        for path in sorted((root / "recipes").glob("*.json")):
            recipe = load_json(path)
            paths.append(path)
            source = (root / recipe["source"]).resolve()
            # Accepted input paths must stay within the canonical tree.
            if not source.is_relative_to((root / "src").resolve()):
                project.input_problems.append({"kind": "recipe", "message": f"{path.name}: source outside src"})
                continue
            if not source.is_file():
                project.input_problems.append({"kind": "missing_source", "message": recipe["source"]})
                continue
            blob = source.read_bytes()
            project.input_hashes[source.relative_to(root).as_posix()] = sha256(blob)
            if sha256(blob) != recipe.get("source_sha256"):
                project.input_problems.append({"kind": "source_identity", "message": recipe["source"],
                    "expected": recipe.get("source_sha256"), "actual": sha256(blob)})
            lid = recipe["function"].lower()
            if recipe.get("kind") == "asm":
                project.objects[recipe["unit"]] = (recipe, blob.decode("latin1"))
            else:
                project.candidates[lid] = Candidate(lid, recipe, blob.decode("latin1"), recipe["source"])
        project.input_hashes.update({p.relative_to(root).as_posix(): sha256_file(p) for p in paths})
        # Include every helper which can affect generation, compilation or comparison.
        for name in ("progbuild.py", "common.py", "harness.py", "datalayout.py", "tpc.py", "tpmap.py", "asmproof.py",
                     "omf.py", "mz.py", "oracle.py", "lz91.py", "toolchain.py", "repack.py"):
            p = root / "tools" / name
            if p.exists():
                project.input_hashes["tools/" + name] = sha256_file(p)
        return project

    def offset(self, name: str, ep: str) -> int | None:
        name = name.lower()
        m = GLOBAL_RX.fullmatch(name)
        if not m:
            return None
        if m[1]:
            # Some historical SAM2 names are shared by SAM2/3: explicit data binding wins.
            row = next((v for n, v in self.data.items() if n.lower() == name), None) or self.extra.get(name)
            return int(row[ep], 16) if row and row.get(ep) else (int(m[2], 16) if m[1].lower() == ep else None)
        row = self.extra.get(name) or next((v for n, v in self.data.items() if n.lower() == name), None)
        if row is not None:
            return int(row[ep], 16) if row.get(ep) else None
        # Unmapped starts follow the nearest measured lower address in the same DS region.
        off = int(m[2], 16)
        bounds = (0, 0x258, 0x294, 0x70DA, 0x10000)
        lo, hi = next((a, b) for a, b in zip(bounds, bounds[1:]) if a <= off < b)
        pairs = [(int(v["sam1"], 16), int(v[ep], 16)) for n, v in self.data.items()
                 if v.get("sam1") and v.get(ep) and lo <= int(v["sam1"], 16) < hi]
        below = [p for p in pairs if p[0] <= off]
        near = max(below) if below else (min(pairs) if pairs else (off, off))
        return off + near[1] - near[0]


@dataclass
class Generation:
    episode: str
    sources: dict
    problems: list
    globals: dict
    routines: dict
    shared: str
    size_types: dict
    selected: dict
    units: dict


def shared_declarations(project: Project, active: dict) -> str:
    sections = canonical_sections(project.canonical)
    canon = harness.parse_decls(sections["types"])
    chunks = [f"{kind}\n  {st};" for kind, st in canon.shared]
    for c in active.values():
        # Keep each original contiguous type section together (forward pointer types).
        previous = None
        for kind, st in c.decls.shared:
            if kind != previous:
                chunks.append(kind)
            chunks.append("  " + rename(st, c.names) + ";")
            previous = kind
    return "\n".join(chunks)


def bss_regions(project: Project, ep: str, anchors: dict) -> list:
    """Measured variable-block ownership; no BSS is fabricated to retain dead code."""
    boundary = lambda n: project.offset(n, ep)
    return [("p", anchors["game_var_start"], boundary("d_0296")),
            ("u2", boundary("d_0296"), boundary("d_21d6")),
            ("u4", boundary("d_21d6"), boundary("d_21e0")),
            ("u5", boundary("d_21e0"), boundary("d_341e")),
            ("u7", boundary("d_341e"), boundary("d_34b0")),
            ("u8", boundary("d_34b0"), anchors["crt_var_start"]),
            ("u9", anchors["u9_var_start"], anchors["u9_var_end"])]


def gaps(spans: list, start: int, end: int) -> list:
    out, pos = [], start
    for a, b in sorted(spans):
        if a > pos:
            out.append((pos, min(a, end)))
        pos = max(pos, b)
    if pos < end:
        out.append((pos, end))
    return [(a, b) for a, b in out if a < b and a < end]


def generate(project: Project, ep: str, sizes: dict, far: dict, anchors: dict) -> Generation:
    """Generate per-episode SAM/U1..U9 sources, preserving natural smart linking.

    Conflicting declarations select canonical (otherwise first source) for a
    clearly blocked preview only. No selection resolves the conflict in proof.
    Unreferenced offsets in the datamap are not extra variables: some are fields,
    array displacements or Borland-owned anchors.
    """
    if ep not in EPISODES:
        raise ValueError(f"unknown episode {ep}")
    problems = list(project.input_problems)
    active = {n: c for n, c in sorted(project.candidates.items())
              if ep in project.atlas["routines"].get(n, {}).get("episodes", {})}
    accepted = set()
    defined = {}
    for lid, c in active.items():
        if ep not in c.recipe.get("equal", []) or c.recipe.get("episodes", {}).get(ep, {}).get("status") != "EQUAL":
            problems.append({"kind": "unproven", "message": lid})
        accepted.add(lid)
        accepted.update(c.recipe.get("covers", []))
        for n in c.definitions:
            if n in defined:
                problems.append({"kind": "duplicate_definition", "message": n, "sources": [defined[n], lid]})
            defined[n] = lid
            if n != lid and n not in c.recipe.get("covers", []):
                problems.append({"kind": "unclaimed_nested", "message": n, "parent": lid,
                                 "detail": "source defines it, but parent recipe does not claim covers"})
    for unit, (recipe, _) in project.objects.items():
        accepted.update(recipe.get("covers", []))
        if ep not in recipe.get("equal", []):
            problems.append({"kind": "unproven_object", "message": unit})
    for unit in project.kinds.get("objects", {}):
        if unit not in project.objects:
            problems.append({"kind": "missing_object", "message": unit})
    missing = []
    for lid, row in project.atlas["routines"].items():
        e = row["episodes"].get(ep)
        if e and e["unit"] in GAME and lid not in accepted and lid not in defined:
            missing.append(lid)
            problems.append({"kind": "missing_routine", "message": lid, "extent": e})

    shared = shared_declarations(project, active)
    canon = harness.parse_decls("\n".join(canonical_sections(project.canonical)[k] for k in ("types", "globals")))
    canonical_types = {harness._decl_name(x): x[1] for x in canon.shared if x[0] == "type"}
    global_views, header_views = {}, {}
    selected = {}
    for n, declaration in canon.globals.items():
        selected[n] = (declaration, n in canon.typed_const, "canonical")
        typ, _, initializer = declaration.split(":", 1)[1].partition("=")
        global_views.setdefault(n, []).append({"source": "canonical", "declaration": declaration,
            "type": norm(typ), "typed": n in canon.typed_const, "initializer": norm(initializer),
            "local_types": referenced_types(typ, canonical_types)})
    headers = dict(harness.parse_stubs(canonical_sections(project.canonical)["routines"]))
    for lid, c in active.items():
        for n, d in c.decls.globals.items():
            typ = d.split(":", 1)[1].split("=", 1)[0].strip()
            definitions = dict(canonical_types)
            definitions.update({harness._decl_name(x): x[1] for x in c.decls.shared if x[0] == "type"})
            global_views.setdefault(n, []).append({"source": lid, "declaration": d, "type": norm(typ),
                "typed": n in c.decls.typed_const, "initializer": norm(d.partition("=")[2]),
                "local_types": referenced_types(typ, definitions)})
            selected.setdefault(n, (rename(d, c.names), n in c.decls.typed_const, lid))
        for n, h in harness.parse_stubs(c.sections["stubs"]):
            header_views.setdefault(n, []).append({"source": lid, "header": h, "signature": signature(h)})
            headers.setdefault(n, rename(h, c.names))
        if c.header:
            headers[lid] = rename(c.header, c.names)
            header_views.setdefault(lid, []).append({"source": lid + " (definition)", "header": c.header,
                                                     "signature": signature(c.header)})
    # Same named local type can have different record members or array bounds.
    # Report the full local definition in addition to the declaration spelling.
    for n, views in global_views.items():
        applicable = [v for v in views if project.offset(n, ep) is not None]
        shapes = {(v["type"], v["typed"], v["initializer"],
                   tuple(sorted((t, norm(s)) for t, s in v.get("local_types", {}).items()))) for v in applicable}
        if len(shapes) > 1:
            problems.append({"kind": "global_conflict", "message": n.lower(), "views": applicable})
    for n, views in header_views.items():
        if len({v["signature"] for v in views}) > 1:
            problems.append({"kind": "header_conflict", "message": n, "views": views})

    size_types = {n: d.split(":", 1)[1].split("=", 1)[0].strip() for n, (d, _, _) in selected.items()
                  if project.offset(n, ep) is not None}
    regions = bss_regions(project, ep, anchors)
    variables, constants = {u: [] for u in GAME}, {u: [] for u in GAME}
    expected = {}
    spans = {u: [] for u in GAME}
    for n, (d, typed, source) in selected.items():
        off = project.offset(n, ep)
        if off is None:
            continue
        if typed:
            owner = "u5"
            if not 0 <= off < anchors["game_const_end"]:
                problems.append({"kind": "constant_region", "message": n, "offset": off})
        else:
            owner = next((u for u, a, b in regions if a <= off < b), None)
            if owner is None:
                problems.append({"kind": "global_region", "message": n, "offset": off,
                                 "detail": "inside Borland-owned data or outside the measured game blocks"})
                continue
        size = sizes.get(n)
        if size is None:
            problems.append({"kind": "unknown_size", "message": n, "type": size_types[n]})
            size = 1  # preview only; cannot make a proof with an unknown size
        end = off + size
        expected[n] = {"offset": off, "size": size, "unit": owner, "typed": typed, "source": source,
                       "declaration": d}
        (constants if typed else variables)[owner].append((off, d + ";"))
        spans[owner].append((off, end, n, typed))
    # Missing initializers remain named gaps; never fill typed constants with oracle bytes or zeros.
    const_spans = [(x[0], x[1]) for values in spans.values() for x in values if x[3]]
    for a, b in gaps(const_spans, 0, anchors["game_const_end"]):
        problems.append({"kind": "missing_initializer", "message": f"DS:{a:04X}..{b:04X}",
                         "start": a, "end": b, "unit": "u5"})
        constants["u5"].append((a, f"{{ GAP: missing accepted typed constants DS:{a:04X}..{b:04X} }}"))
    for u, a, b in regions:
        occupied = [(x[0], x[1]) for x in spans[u] if not x[3]]
        for start, end in gaps(occupied, a, b):
            variables[u].append((start, harness._pad_decl(f"reserved_{start:04x}", end - start, False, start)))
        for start, end, n, typed in sorted(spans[u]):
            if not typed and end > b:
                problems.append({"kind": "block_overflow", "message": n, "unit": u,
                                 "end": end, "block_end": b})
        ordered = sorted(spans[u])
        for i, (start, end, n, typed) in enumerate(ordered):
            for s, e, other, other_typed in ordered[i + 1:]:
                if s < end and typed == other_typed:
                    problems.append({"kind": "global_overlap", "message": f"{n} / {other}",
                                     "range": [s, min(end, e)], "unit": u})

    # Measure ownership lower bounds from real source references, including OMF EXTRNs.
    rank = {"p": 0, **{f"u{i}": i for i in range(1, 10)}}
    refs = {}
    for lid, c in active.items():
        text = harness._strip_comments(c.sections["body"])
        for m in GLOBAL_RX.finditer(text):
            refs.setdefault(m[0].upper(), set()).add(c.unit)
    for unit, (_, text) in project.objects.items():
        for n in re.findall(r"(?im)^\s*extrn\s+(d_\w+)\s*:", text):
            refs.setdefault(n.upper(), set()).add(unit)
            if n.upper() not in expected:
                problems.append({"kind": "missing_object_global", "message": n, "unit": unit,
                                 "offset": project.offset(n, ep)})
    for n, units in refs.items():
        if n in expected:
            expected[n]["referenced_by"] = sorted(units)
            owner = expected[n]["unit"]
            if any(rank[u] > rank[owner] for u in units):
                problems.append({"kind": "ownership", "message": n, "owner": owner,
                                 "referenced_by": sorted(units)})

    sources, locations, unit_details = {}, {}, {}
    for unit in GAME:
        members = sorted((c for c in active.values() if c.unit == unit),
                         key=lambda c: project.atlas["routines"][c.lid]["episodes"][ep]["entry"])
        routine_ids = [c.lid for c in members if c.header]
        statements = [c for c in members if c.header is None]
        if len(statements) != 1:
            problems.append({"kind": "statement_body", "message": unit, "sources": [c.lid for c in statements]})
        ext_names = set()
        if unit in project.objects:
            ext_names = {n.lower() for line in project.objects[unit][1].splitlines()
                         if re.match(r"\s*public\s", line, re.I)
                         for n in re.sub(r"^\s*public\s+", "", line, flags=re.I).split(",")}
        ext_names = {n.strip() for n in ext_names}
        # Declare external publics with known Pascal headers. Uncalled object
        # helper publics do not need fabricated Pascal signatures.
        ext_headers = {n: headers[n] for n in sorted(ext_names) if n in headers}
        for n in sorted(ext_names - set(ext_headers)):
            problems.append({"kind": "missing_external_header", "message": n, "unit": unit,
                             "detail": "TASM PUBDEF needs a Pascal external declaration; no recipe/canonical/stub header is available"})
        unit_missing = [n for n in missing if project.atlas["routines"][n]["episodes"][ep]["unit"] == unit]
        exported = [n for n in routine_ids if far.get(n) is True] + [n for n in unit_missing if n in headers]
        filename = "SAM.PAS" if unit == "p" else unit.upper() + ".PAS"
        # Every dependency precedes this unit in the init chain. Implementation
        # uses hold game callees; interfaces only import the common types/globals.
        deps = ["Dos"] if unit == "u9" else ["Dos", "U9", "Crt", *[
            f"U{i}" for i in range(8, rank[unit], -1)]]
        if unit == "p":
            lines = ["program SAM;", "{$M 16384,0,655360}", "{$A+}{$D+}{$L+}{$F-}",
                     "uses " + ", ".join(USES) + ";"]
        else:
            base = ["Dos"] if unit == "u9" else ["Dos", "U9"] if unit == "u8" else ["U8"]
            lines = ["unit " + unit.upper() + ";", "{$A+}{$D+}{$L+}{$F-}", "interface",
                     "uses " + ", ".join(base) + ";"]
            if unit == "u8":
                lines.append(shared)
        if constants[unit]:
            # A section containing only GAP comments would be invalid Pascal;
            # emit those comments separately until real initializers exist.
            real = [d for _, d in sorted(constants[unit]) if not d.startswith("{ GAP:")]
            comments = [d for _, d in sorted(constants[unit]) if d.startswith("{ GAP:")]
            if real:
                lines += ["const", *["  " + d for d in real]]
            lines += comments
        if variables[unit]:
            lines += ["var", *["  " + d for _, d in sorted(variables[unit])]]
        if unit != "p":
            for n in exported:
                h = headers[n]
                c = active.get(n)
                if c and re.search(r"\binterrupt\s*;", c.sections["body"], re.I):
                    h += " interrupt;"
                lines.append(h)
            lines.extend(ext_headers.values())
            lines.append("implementation")
            more = [d for d in deps if d.lower() not in set(x.lower() for x in base)]
            if more:
                lines.append("uses " + ", ".join(more) + ";")
        if unit in project.objects:
            lines.append("{$L " + ("P" if unit == "p" else unit.upper()) + ".OBJ}")
        for n, h in ext_headers.items():
            if unit == "p":
                lines.append("{$F+}\n" + h + " external;\n{$F-}")
            else:
                lines.append(harness._stub_def(h) + " external;")
        # Forwards have no code position. Only implementation/private routines
        # need them; exported declarations already permit later definitions.
        order = {n: i for i, n in enumerate(routine_ids)}
        forward = set()
        for caller in members:
            if caller.header is None:
                continue
            tokens = {m[0].lower() for m in LEX.finditer(caller.sections["body"])
                      if re.fullmatch(r"[A-Za-z_][A-Za-z_0-9]*", m[0])}
            forward.update(n for n in routine_ids if n in tokens and order[n] > order[caller.lid]
                           and (unit == "p" or n not in exported))
        for n in routine_ids:
            if n in forward:
                lines.append(("{$F+}" if far.get(n) is True else "{$F-}") + "\n" + headers[n] +
                             (" interrupt;" if re.search(r"\binterrupt\s*;", active[n].sections["body"], re.I) else "") +
                             " forward;")
        for c in members:
            if c.header is None:
                continue
            lines.append("{$F+}" if far.get(c.lid) is True else "{$F-}")
            body = rename(c.sections["body"].strip(), c.names)
            first_line = sum(x.count("\n") + 1 for x in lines) + 1
            lines.append(body)
            locations[c.lid] = {"module": "SAM" if unit == "p" else unit.upper(), "file": filename,
                "first_line": first_line, "last_line": first_line + body.count("\n"),
                "source": c.path, "definitions": c.definitions}
            # A routine's local compiler switches must not leak to the next one.
            lines.append("{$S-}{$I-}{$R-}{$B-}{$F-}")
        for n in unit_missing:
            lines.append("{ GAP: missing accepted body " + n + " }")
        if statements:
            c = statements[0]
            body = rename(c.sections["body"].strip(), c.names)
            first_line = sum(x.count("\n") + 1 for x in lines) + 1
            lines.append(body)
            locations[c.lid] = {"module": "SAM" if unit == "p" else unit.upper(), "file": filename,
                "first_line": first_line, "last_line": first_line + body.count("\n"), "source": c.path,
                "definitions": []}
        else:
            lines.append("{ GAP: no accepted statement body }\nend.")
        sources[filename] = "\n".join(lines) + "\n"
        unit_details[unit] = {"routines": routine_ids, "exported": exported, "externals": ext_headers,
                              "statement_bodies": [c.lid for c in statements]}
    return Generation(ep, sources, problems, expected, locations, shared, size_types, selected, unit_details)


@contextmanager
def isolated_tools(directory: Path):
    """The existing wrappers are used unchanged, with task-owned output roots."""
    import repack
    previous = tpc.CACHE, tpc.SCRATCH, tpc.INFLIGHT, repack.BUILD
    tpc.CACHE = directory / "cc-cache"
    tpc.SCRATCH = directory / "scratch" / "tpc"
    tpc.INFLIGHT = tpc.CACHE / "inflight"
    repack.BUILD = directory
    try:
        yield
    finally:
        tpc.CACHE, tpc.SCRATCH, tpc.INFLIGHT, repack.BUILD = previous


def measure_sizes(generation: Generation, options: list) -> tuple:
    """Ask TP itself for sizes: real typed Word constants containing SizeOf(T).

    This is a separate diagnostic program, not linked into the game. No map
    distance assumptions, materialized BSS, or guessed record packing are used.
    """
    table = {f"sz_{i:04x}": n for i, n in enumerate(sorted(generation.size_types))}
    aliases = [f"  probe_{k} = {generation.size_types[n]};" for k, n in table.items()]
    declarations = [f"  {k}: Word = SizeOf(probe_{k});" for k in table]
    source = "program Sizes;\n{$A+}{$D+}{$L+}\nuses Dos;\n" + generation.shared + "\ntype\n" + \
        "\n".join(aliases) + "\nconst\n" + \
        "\n".join(declarations) + "\nbegin\n" + \
        "\n".join(f"  if {k} = 0 then Halt;" for k in table) + "\nend.\n"
    receipt = tpc.compile_program({"SIZES.PAS": source}, "SIZES.PAS", ["/GD", *options])
    if not receipt.ok:
        return {}, receipt
    m, exe = tpmap.parse(receipt.map("SIZES")), mz.parse(receipt.exe("SIZES"))
    sizes = {}
    for k, n in table.items():
        seg, off = m.publics[k.upper()]
        at = seg * 16 + off
        sizes[n] = int.from_bytes(exe.image[at:at + 2], "little")
    return sizes, receipt


def library_anchors(ep: str, project: Project, cen: dict, image: bytes, options: list) -> dict:
    """Re-measure the harness library anchors without writing build/harness/."""
    from datalayout import ds_operands
    ref = tpc.compile_program({"H.PAS": harness.REF_PROGRAM, "U9.PAS": harness.REF_U9},
                              "H.PAS", ["/GD", *options])
    if not ref.ok:
        raise RuntimeError("reference library compile failed: " + ref.log)
    m = tpmap.parse(ref.map("H"))
    original_ref = mz.parse(ref.exe("H")).image
    d = m.data().para
    pub = {n: o for n, (s, o) in m.publics.items() if s == d}
    deltas = {"sysconst": set(), "crtvar": set(), "sysvar": set()}
    for unit, name, length in (("crt", "CRT", 0x60), ("sys", "SYSTEM", 0x40)):
        start = cen["segments"][project.atlas["units"].index(unit)]["start"]
        hstart = m.segment(name).start
        for a, b in zip(ds_operands(image[start:start + length], 0),
                        ds_operands(original_ref[hstart:hstart + length], 0)):
            if a[:2] != b[:2]:
                continue
            block = "sysconst" if b[2] < pub["CHECKBREAK"] else "crtvar" if b[2] < pub["DOSERROR"] else "sysvar"
            deltas[block].add(a[2] - b[2])
    if any(len(x) != 1 for x in deltas.values()):
        raise RuntimeError(f"inconsistent reference library deltas: {deltas}")
    dc, dv, ds = (next(iter(deltas[k])) for k in ("sysconst", "crtvar", "sysvar"))
    lock = load_json(oracle.LOCK)["episodes"][ep]["unpacked"]
    doserror = pub["DOSERROR"] + ds
    refs = load_json(BUILD / "datamap" / f"{ep}.json")["refs"]
    doserror = doserror if f"{doserror:04X}" in refs else None
    return {"PREFIXSEG": pub["PREFIXSEG"] + dc, "CHECKBREAK": pub["CHECKBREAK"] + dv,
            "INPUT": pub["INPUT"] + ds, "DOSERROR": doserror, "game_const_end": dc,
            "game_var_start": dc + pub["CHECKBREAK"], "crt_var_start": pub["CHECKBREAK"] + dv,
            "crt_var_end": pub["DOSERROR"] + dv, "u9_var_start": pub["DOSERROR"] + dv,
            "u9_var_end": doserror if doserror is not None else pub["INPUT"] + ds,
            "ds_size": (lock["ss"] - cen["ds_para"]) * 16, "reference_compile_key": ref.key}


def calling_kinds(ep: str, project: Project, cen: dict, image: bytes) -> dict:
    import capstone
    md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
    segments = dict(zip(project.atlas["units"], cen["segments"]))
    result = {}
    for lid, row in project.atlas["routines"].items():
        e = row["episodes"].get(ep)
        if e is None or e["unit"] not in GAME:
            continue
        base = segments[e["unit"]]["start"]
        instructions = {i.mnemonic for i in md.disasm(image[base + e["entry"]:base + e["end"]], e["entry"])}
        result[lid] = None if "iret" in instructions else True if "retf" in instructions else False if "ret" in instructions else None
    return result


def first_difference(original: bytes, candidate: bytes) -> int | None:
    for i, (a, b) in enumerate(zip(original, candidate)):
        if a != b:
            return i
    return min(len(original), len(candidate)) if len(original) != len(candidate) else None


def original_owner(project: Project, ep: str, unit: str, off: int, globals_: dict) -> str:
    if unit == "data":
        rows = [(v["size"], n.lower()) for n, v in globals_.items()
                if v["offset"] <= off < v["offset"] + v["size"]]
        return min(rows)[1] if rows else f"DS:{off:04X} (library data or declaration gap)"
    rows = [(e["end"] - e["start"], n) for n, r in project.atlas["routines"].items()
            if (e := r["episodes"].get(ep)) and e["unit"] == unit and e["start"] <= off < e["end"]]
    return min(rows)[1] if rows else unit + " (object storage or paragraph padding)"


def candidate_owner(m: tpmap.Map, generation: Generation, unit: str, off: int) -> str | None:
    name = "DATA" if unit == "data" else MAP_NAMES[unit]
    try:
        seg = m.segment(name)
    except KeyError:
        return None
    if unit == "data":
        by_off = [(o, n) for n, (p, o) in m.publics.items() if p == seg.para and o <= off]
        return max(by_off)[1] if by_off else None
    lines = [(o, line) for line, para, o in m.lines.get(name, []) if para == seg.para and o <= off]
    if lines:
        line = max(lines)[1]
        for lid, loc in generation.routines.items():
            if loc["module"] == name and loc["first_line"] <= line <= loc["last_line"]:
                return lid
    symbols = [(o, n) for n, (p, o) in m.publics.items() if p == seg.para and o <= off]
    return max(symbols)[1] if symbols else None


def compare_image(project: Project, generation: Generation, cen: dict, original: bytes,
                  relocs: tuple, original_header: dict, executable: bytes, map_text: str,
                  anchors: dict) -> dict:
    """Raw segment, full image, MZ header and relocation-set comparison."""
    candidate, m = mz.parse(executable), tpmap.parse(map_text)
    report = {"image_equal": candidate.image == original, "original_image_size": len(original),
              "candidate_image_size": len(candidate.image), "segments": [], "globals": [], "anchors": []}
    rows = list(zip(project.atlas["units"], cen["segments"]))
    rows.append(("data", {"start": cen["ds_para"] * 16,
                           "size": len(original) - cen["ds_para"] * 16, "para": cen["ds_para"]}))
    starts = sorted(s.start for s in m.segments)
    for unit, segment in rows:
        name = "DATA" if unit == "data" else MAP_NAMES[unit]
        try:
            built = m.segment(name)
        except KeyError:
            report["segments"].append({"unit": unit, "status": "MISSING", "original_size": segment["size"]})
            continue
        next_start = next((a for a in starts if a > built.start), len(candidate.image))
        end = min(next_start, len(candidate.image))
        want = original[segment["start"]:segment["start"] + segment["size"]]
        got = candidate.image[built.start:end]
        at = first_difference(want, got)
        row = {"unit": unit, "status": "EQUAL" if at is None else "DIFF", "original_para": segment["para"],
               "candidate_para": built.para, "original_size": len(want), "candidate_size": len(got),
               "map_length": built.length, "first_difference": at}
        if at is not None:
            row.update(original_owner=original_owner(project, generation.episode, unit, at, generation.globals),
                       candidate_owner=candidate_owner(m, generation, unit, at),
                       original_bytes=want[at:at + 12].hex(), candidate_bytes=got[at:at + 12].hex())
        report["segments"].append(row)
    data_para = m.data().para
    for n, info in sorted(generation.globals.items(), key=lambda kv: kv[1]["offset"]):
        found = m.publics.get(n)
        equal = found == (data_para, info["offset"])
        report["globals"].append({"name": n, "unit": info["unit"], "expected": info["offset"],
                                  "actual": found[1] if found and found[0] == data_para else None, "equal": equal})
    for n in ("PREFIXSEG", "CHECKBREAK", "INPUT", "DOSERROR"):
        found, expected = m.publics.get(n), anchors[n]
        actual = found[1] if found and found[0] == data_para else None
        report["anchors"].append({"name": n, "expected": expected, "actual": actual, "equal": expected == actual})
    report["data_length"] = {"expected": anchors["ds_size"], "actual": m.data().length,
                             "equal": anchors["ds_size"] == m.data().length}
    report["header"] = {k: {"original": original_header[k], "candidate": candidate.header[k],
                             "equal": original_header[k] == candidate.header[k]} for k in mz.FIELDS}
    report["header_reference"] = "canonical unpacked MZ, reconstructed by tools/lz91.py; pre-pack header storage is not recovered"
    expected, actual = set(mz.linear(relocs)), set(mz.linear(candidate.relocs))
    report["relocations"] = {"equal": expected == actual and len(actual) == len(candidate.relocs),
        "original_count": len(relocs), "candidate_count": len(candidate.relocs),
        "candidate_duplicates": len(candidate.relocs) - len(actual),
        "only_original": sorted(expected - actual), "only_candidate": sorted(actual - expected),
        "ordered_equal": relocs == candidate.relocs}
    # Name every relocation mismatch as well as its linear offset.
    for side in ("only_original", "only_candidate"):
        named = []
        for site in report["relocations"][side]:
            table = rows if side == "only_original" else [(u, {"start": s.start, "size": s.length})
                for s in m.segments for u in [next((u for u, name in MAP_NAMES.items() if name == s.name.upper()), "data")]]
            unit, seg = next(((u, s) for u, s in table if s["start"] <= site < s["start"] + s["size"]), ("data", {"start": cen["ds_para"] * 16}))
            off = site - seg["start"]
            owner = original_owner(project, generation.episode, unit, off, generation.globals) if side == "only_original" else candidate_owner(m, generation, unit, off)
            named.append({"linear": site, "unit": unit, "offset": off, "owner": owner})
        report["relocations"][side + "_named"] = named
    report["unexpected_segments"] = [s.name for s in m.segments
        if s.name.upper() not in {*MAP_NAMES.values(), "DATA", "STACK"}]
    names_by_para = {s.para: next((u for u, name in MAP_NAMES.items() if name == s.name.upper()), s.name)
                     for s in m.segments if s.cls.upper() == "CODE"}
    actual_order = [names_by_para[s.para] for s in m.segments if s.cls.upper() == "CODE"]
    report["link_order"] = {"expected": project.atlas["units"], "actual": actual_order,
                            "equal": project.atlas["units"] == actual_order}
    # TP emits the initialisation chain at the MZ entry point as consecutive
    # far calls. Compare both the unit order and each init's actual offset.
    at = candidate.header["cs"] * 16 + candidate.header["ip"]
    actual_chain = []
    while at + 5 <= len(candidate.image) and candidate.image[at] == 0x9A:
        off = int.from_bytes(candidate.image[at + 1:at + 3], "little")
        para = int.from_bytes(candidate.image[at + 3:at + 5], "little")
        actual_chain.append([names_by_para.get(para, f"{para:04X}"), off])
        at += 5
    original_names = {s["para"]: u for u, s in zip(project.atlas["units"], cen["segments"])}
    expected_chain = [[original_names[p], o] for p, o in cen.get("inits", [])]
    report["init_chain"] = {"expected": expected_chain, "actual": actual_chain,
                            "equal": expected_chain == actual_chain}
    report["routine_entries"] = []
    for lid, row in project.atlas["routines"].items():
        e = row["episodes"].get(generation.episode)
        if e and e["unit"] in GAME and lid.upper() in m.publics:
            para, off = m.publics[lid.upper()]
            unit = names_by_para.get(para)
            report["routine_entries"].append({"name": lid, "expected_unit": e["unit"], "actual_unit": unit,
                "expected_offset": e["entry"], "actual_offset": off, "equal": unit == e["unit"] and off == e["entry"]})
    report["overlay_size"] = len(candidate.overlay)
    return report


def object_holes(project: Project, ep: str, cen: dict, image: bytes, objects: dict,
                 executable: bytes | None = None, map_text: str | None = None) -> list:
    """Record undefined OMF storage verbatim on both sides; never waive it."""
    parsed = mz.parse(executable) if executable else None
    m = tpmap.parse(map_text) if map_text else None
    segs = dict(zip(project.atlas["units"], cen["segments"]))
    result = []
    for unit, obj in objects.items():
        code = asmproof.code_segment(obj)
        start, _ = asmproof.translated_extent(unit, ep, project.kinds["objects"], project.atlas)
        placement = set()
        if m:
            for public in obj.publics_in(code):
                address = m.publics.get(public["name"].upper())
                if address:
                    placement.add(address[1] - public["offset"])
        linked_start = next(iter(placement)) if len(placement) == 1 else None
        for a, b in asmproof.ranges(obj.segment_defined[code]):
            want = image[segs[unit]["start"] + start + a:segs[unit]["start"] + start + b]
            got = None
            if parsed and m and linked_start is not None:
                at = m.segment(MAP_NAMES[unit]).start + linked_start
                got = parsed.image[at + a:at + b]
            result.append({"unit": unit, "object_range": [a, b], "original_range": [start + a, start + b],
                           "candidate_range": [linked_start + a, linked_start + b] if linked_start is not None else None,
                           "original_bytes": want.hex(), "candidate_bytes": got.hex() if got is not None else None,
                           "equal": got == want if got is not None else None,
                           "note": "undefined OMF storage; residual compiler-buffer bytes, included in raw image comparison"})
    return result


def build_episode(project: Project, ep: str, directory: Path, keep: bool) -> dict:
    directory.mkdir(parents=True, exist_ok=True)
    # A failed rerun must not leave a previous successful EXE beside its report.
    for name in ("SAM.EXE", "SAM.MAP", "SAM-PACKED.EXE"):
        (directory / name).unlink(missing_ok=True)
    report = {"episode": ep, "status": "BLOCKED", "inputs": dict(project.input_hashes), "problems": [],
              "comparison": None, "packed": {"status": "SKIPPED", "reason": "no equal load image"}}
    try:
        # Avoid oracle.load_image's materialization fallback: this worker reads oracles only.
        for name in ("image.bin", "relocs.json", "unpacked.exe"):
            if not (oracle.OUT / ep / name).is_file():
                raise RuntimeError(f"missing oracle prerequisite {oracle.OUT / ep / name}")
        image, relocs = oracle.load_image(ep)
        cen_path = BUILD / "census" / f"{ep}.json"
        cen = load_json(cen_path)
        report["inputs"][f"build/census/{ep}.json"] = sha256_file(cen_path)
        report["inputs"][f"build/datamap/{ep}.json"] = sha256_file(BUILD / "datamap" / f"{ep}.json")
        unpacked = (oracle.OUT / ep / "unpacked.exe").read_bytes()
        locked = load_json(oracle.LOCK)["episodes"][ep]
        if sha256(unpacked) != locked["unpacked"]["canonical_mz_sha256"]:
            raise RuntimeError("canonical unpacked MZ differs from oracle lock")
        original_header = mz.parse(unpacked).header
        profile_doc = load_json(ROOT / "layout" / "profiles.json")
        profile = profile_doc["default"]
        options = [f"/DSAM{ep[-1]}", *profile_doc["profiles"][profile]["options"]]
        report["profile"], report["options"] = profile, ["/GD", *options]
        anchors = library_anchors(ep, project, cen, image, options)
        report["library_anchors"] = anchors
        far = calling_kinds(ep, project, cen, image)
        preliminary = generate(project, ep, {}, far, anchors)
        sizes, sizing = measure_sizes(preliminary, options)
        report["size_probe"] = sizing.data
        atomic_bytes(directory / "size-probe.log", sizing.log.encode("latin1"))
        if keep:
            atomic_bytes(directory / "SIZES.PAS", (sizing.directory / "SIZES.PAS").read_bytes())
        generated = generate(project, ep, sizes, far, anchors)
        report["problems"] = generated.problems
        if not sizing.ok:
            report["problems"].append({"kind": "size_probe", "message": "compiler could not measure shared types; see size-probe.log"})
        report["generation"] = {"sources": {n: sha256(tpc.dos_text(s)) for n, s in generated.sources.items()},
            "routines": generated.routines, "globals": generated.globals, "units": generated.units}
        # Always retain source previews: they are small and necessary to review a BLOCKED report.
        for name, source in generated.sources.items():
            atomic_bytes(directory / name, tpc.dos_text(source))
        binaries, objects = {}, {}
        report["assemblies"] = {}
        for unit, (recipe, text) in sorted(project.objects.items()):
            assembled = asmproof.assemble(text, cache_root=OUT / "cc-cache", scratch_root=OUT / "scratch" / "tasm")
            report["assemblies"][unit] = assembled.data
            atomic_bytes(directory / (unit.upper() + "-assembler.log"), assembled.log.encode("latin1"))
            if assembled.ok:
                blob = assembled.obj()
                name = ("P" if unit == "p" else unit.upper()) + ".OBJ"
                binaries[name] = blob
                objects[unit] = OmfReader().read(blob, name)
                if keep:
                    atomic_bytes(directory / name, blob)
            else:
                report["problems"].append({"kind": "assembly", "message": unit + " failed"})
        report["object_holes"] = object_holes(project, ep, cen, image, objects)
        if len(binaries) != len(project.objects):
            raise RuntimeError("one or more linked objects failed assembly")
        receipt = tpc.compile_program(generated.sources, "SAM.PAS", ["/GD", *options], binaries=binaries)
        report["compile"] = receipt.data
        atomic_bytes(directory / "compiler.log", receipt.log.encode("latin1"))
        if not receipt.ok or receipt.exe("SAM") is None:
            report["problems"].append({"kind": "compile", "message": "actual program compilation failed; see compiler.log",
                                      "log_tail": receipt.log.strip()[-1600:]})
        else:
            exe, map_text = receipt.exe("SAM"), receipt.map("SAM")
            atomic_bytes(directory / "SAM.EXE", exe)
            atomic_bytes(directory / "SAM.MAP", map_text.encode("latin1"))
            report["comparison"] = compare_image(project, generated, cen, image, relocs, original_header, exe, map_text, anchors)
            report["object_holes"] = object_holes(project, ep, cen, image, objects, exe, map_text)
            comparison = report["comparison"]
            report["status"] = "BLOCKED" if report["problems"] else "DIFF"
            if comparison["image_equal"]:
                import repack
                packed = repack.pack(exe)
                original_packed = oracle.find_asset(oracle.EXE_NAMES[ep]).read_bytes()
                if sha256(original_packed) != locked["packed"]["sha256"]:
                    raise RuntimeError("packed asset differs from oracle lock")
                at = first_difference(original_packed, packed)
                report["packed"] = {"status": "EQUAL" if at is None else "DIFF", "first_difference": at,
                    "sha256": sha256(packed), "size": len(packed), "original_size": len(original_packed)}
                atomic_bytes(directory / "SAM-PACKED.EXE", packed)
                layout_equal = (all(r["equal"] for r in comparison["globals"] + comparison["anchors"])
                                and comparison["data_length"]["equal"] and not comparison["unexpected_segments"]
                                and comparison["link_order"]["equal"] and comparison["init_chain"]["equal"]
                                and all(r["equal"] for r in comparison["routine_entries"]))
                if at is None and not report["problems"] and comparison["relocations"]["equal"] and layout_equal:
                    report["status"] = "EQUAL"
            if keep:
                for name, blob in receipt.outputs.items():
                    atomic_bytes(directory / name, blob)
    except (OSError, ValueError, KeyError, RuntimeError, TimeoutError) as exc:
        report["problems"].append({"kind": "build", "message": str(exc)})
    if report["comparison"] is None:
        report["segments"] = [{"unit": u, "status": "UNASSESSED", "reason": "no linked EXE"}
                              for u in project.atlas["units"]] + [{"unit": "data", "status": "UNASSESSED", "reason": "no linked EXE"}]
    atomic_json(directory / "report.json", report)
    atomic_bytes(directory / "report.md", render_report(report).encode("utf8"))
    return report


def render_report(report: dict) -> str:
    lines = [f"# {report['episode']}: {report['status']}", "",
             "Generated from accepted sources with no oracle initializers, absolute views, retention calls or post-link patching.",
             "Source previews are not a proof while any input blocker remains.", ""]
    comparison = report.get("comparison")
    rows = comparison["segments"] if comparison else report.get("segments", [])
    lines += ["| Segment | Result | First difference | Original owner |", "|---|---|---|---|"]
    for row in rows:
        at = row.get("first_difference")
        lines.append(f"| {row['unit']} | {row['status']} | {f'{at:04X}' if at is not None else '—'} | {row.get('original_owner', '')} |")
    if comparison:
        lines += ["", f"Load image equal: {comparison['image_equal']}; relocation set equal: {comparison['relocations']['equal']}.",
                  comparison["header_reference"] + ".", "", "| MZ field | Original | Candidate |", "|---|---|---|"]
        for name, row in comparison["header"].items():
            lines.append(f"| {name} | {row['original']:04X} | {row['candidate']:04X} |")
    lines += ["", "Packed comparison: " + report["packed"]["status"] + ".", "", "## Input blockers", ""]
    for problem in report["problems"]:
        lines.append(f"- **{problem['kind']}**: {problem['message']}")
        if "views" in problem:
            for view in problem["views"]:
                text = view.get("declaration", view.get("header", ""))
                lines.append(f"  - {view['source']}: `{norm(text)}`")
                for name, declaration in view.get("local_types", {}).items():
                    lines.append(f"    - local type `{name}`: `{norm(declaration)}`")
    lines += ["", "## Object holes (no bytes patched or waived)", "", "| Unit | Original range | Original bytes | Candidate bytes |", "|---|---|---|---|"]
    for hole in report.get("object_holes", []):
        a, b = hole["original_range"]
        lines.append(f"| {hole['unit']} | {a:04X}..{b:04X} | `{hole['original_bytes']}` | " +
                     (f"`{hole['candidate_bytes']}`" if hole["candidate_bytes"] is not None else "UNASSESSED") + " |")
    lines += ["", "Full declarations, sizes, ownership, source hashes, receipts and comparisons are in report.json.", ""]
    return "\n".join(lines)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--episodes", default=",".join(EPISODES))
    parser.add_argument("--keep", action="store_true", help="also copy diagnostic sources, objects and TPUs into each episode directory")
    args = parser.parse_args(argv)
    episodes = args.episodes.split(",")
    if not episodes or any(e not in EPISODES for e in episodes) or len(set(episodes)) != len(episodes):
        parser.error("--episodes must be a comma-separated subset of sam1,sam2,sam3")
    project = Project.read()
    reports = []
    with isolated_tools(OUT):
        for ep in episodes:
            print(f"{ep}: generating and compiling accepted program sources", flush=True)
            report = build_episode(project, ep, OUT / ep, args.keep)
            reports.append(report)
            comparison = report.get("comparison")
            if comparison:
                desc = "; ".join(f"{r['unit']} {r['status']}" +
                    (f" +{r['first_difference']:04X} ({r.get('original_owner')})" if r.get("first_difference") is not None else "")
                    for r in comparison["segments"])
            else:
                desc = "no linked EXE; all segments UNASSESSED"
            print(f"{ep}: {report['status']}; {desc}; {len(report['problems'])} blockers; {OUT / ep / 'report.json'}", flush=True)
    atomic_json(OUT / "report.json", {"episodes": {r["episode"]: r for r in reports}})
    atomic_bytes(OUT / "report.md", "\n".join(render_report(r) for r in reports).encode("utf8"))
    return 0 if all(r["status"] == "EQUAL" for r in reports) else 1


if __name__ == "__main__":
    sys.exit(main())
