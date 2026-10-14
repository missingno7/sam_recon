"""Semantic, token-based rename of the standalone TP5 game tree.

    python tools/rename.py --merge
    python tools/rename.py game --dry-run
    python tools/rename.py game --apply

An apply stages text sources, builds all three episodes, compares the fresh
proof to a fresh baseline, and only then replaces the tree. Backups and all
receipts live in build/workers/sol-rename. No binary is copied back to game.
"""
from __future__ import annotations

import argparse
import copy
from dataclasses import dataclass, field
import hashlib
import json
import re
import shutil
import sys
import uuid
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import ROOT, atomic_json, load_json, sha256_file

OUT = ROOT / "build/workers/sol-rename"
NAMES = ROOT / "layout/names.json"
CATEGORIES = ("units", "routines", "globals", "types")
CONFIDENCE = {"low": 0, "medium": 1, "high": 2}
# Includes TP5 reserved words, predefined types/constants, System, Crt and Dos
# exports (including record members). A conservative superset also protects
# common Borland compiler directives and subsequent Borland runtime exports.
BORLAND = set("""
absolute and array asm begin case const constructor destructor div do downto
else end external file for forward function goto if implementation in inline
interface interrupt label mod nil not object of or packed procedure program
record repeat set shl shr string then to type unit until uses var virtual while
with xor assembler far near resident private public export index name
system crt dos byte shortint integer word longint real single double extended
comp boolean char text pointer true false maxint pi
abs addr arctan assigned assign blockread blockwrite break chdir chr close
concat continue copy cos cseg dec delete dispose eof eoln erase exclude exit
exp filepos filesize fillchar flush frac freemem getdir getmem halt hi inc
include insert int ioresult length ln lo low high mark mem memw meml move
new odd ofs ord paramcount paramstr pos pred ptr random randomize read readln
release rename reset rewrite rmdir round runerror seek seekeof seekeoln seg
sin sizeof sqr sqrt str succ swap trunc truncat upcase val write writeln
append exitproc exitcode erroraddr prefixseg randseed heaporg heapptr heapend
heaperror freeptr freelist ptrrec filerec textrec recsize mode handle bufsize
bufptr bufpos bufend openfunc inoutfunc flushfunc closefunc userdata buffer
input output checkbreak checkeof checkexec printflag printtextinbytecode
filemode test8087 maxavail memavail port portw sptr sseg settextbuf
clreol clrscr delay delline gotoxy highvideo insline keypressed lowvideo
normvideo nosound readkey sound textbackground textcolor textmode wherex
wherey window lastmode directvideo checkctrlc windmin windmax textattr
black blue green cyan red magenta brown lightgray darkgray lightblue
lightgreen lightcyan lightred lightmagenta yellow white blink bw40 co40
bw80 co80 mono font8x8 c40 c80
registers ax bx cx dx bp si di ds es flags al ah bl bh cl ch dl dh
searchrec time hour min sec sec100 year month day dayofweek attr size
fcarry fparity fauxiliary fzero fsign foverflow readonly hidden sysfile
volumeid directory archive anyfile fmclosed fminput fmoutput fminout
dosversion intr msdos getintvec setintvec getdate setdate gettime settime
getcbreak setcbreak getverify setverify findfirst findnext fsearch getfattr
setfattr getftime setftime diskfree disksize exec keep swapvectors
envcount envstr getenv packtime unpacktime doserror dosseg dosofs
""".split())
IDENT = re.compile(r"[A-Za-z][A-Za-z_0-9]{0,30}\Z")
DOS_DEVICES = {"CON", "PRN", "AUX", "NUL", *(f"COM{i}" for i in range(1, 10)),
               *(f"LPT{i}" for i in range(1, 10))}
PASLEX = re.compile(
    r"(?P<comment>\{[^}]*\}|\(\*.*?\*\)|//[^\r\n]*)|"
    r"(?P<string>'(?:[^']|'')*')|(?P<id>[A-Za-z_][A-Za-z_0-9]*)|"
    r"(?P<number>\$[0-9a-fA-F]+|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)|"
    r"(?P<symbol>:=|\.\.|<>|<=|>=|[^\s])", re.S)
ASMLEX = re.compile(
    r"(?P<comment>;[^\r\n]*)|(?P<string>'[^']*'|\"[^\"]*\")|"
    r"(?P<number>\b[0-9][A-Za-z0-9]*\b)|"
    r"(?P<id>[A-Za-z_][A-Za-z_0-9]*)|(?P<symbol>[^\s])")


@dataclass
class Token:
    text: str
    start: int
    end: int
    kind: str

    @property
    def low(self):
        return self.text.lower()


def lex(text: str, language="pas") -> list[Token]:
    rx = ASMLEX if language == "asm" else PASLEX
    return [Token(m[0], m.start(), m.end(), m.lastgroup)
            for m in rx.finditer(text) if m.lastgroup != "comment"]


@dataclass
class Type:
    kind: str = "unknown"
    name: str = ""
    item: Type | None = None
    fields: dict = field(default_factory=dict)
    declarations: dict = field(default_factory=dict)


@dataclass
class Scope:
    name: str
    start: int
    end: int = 0
    parent: Scope | None = None
    variables: dict = field(default_factory=dict)
    declarations: dict = field(default_factory=dict)
    params: set = field(default_factory=set)
    types: dict = field(default_factory=dict)
    children: list = field(default_factory=list)
    definition: bool = False
    body: int | None = None
    interface: bool = False

    def lookup(self, name):
        return self.variables.get(name) or (self.parent.lookup(name) if self.parent else None)


class Pascal:
    """Small declaration/block parser; source positions always refer to tokens.

    This deliberately supports TP5 declarations, record variants, casts,
    external/forward headers and nested routines, not a general Pascal AST.
    Unknown member accesses are reported and their whole type's fields stay
    unchanged. 'with' is rejected when fields are being renamed.
    """
    SECTIONS = {"type", "var", "const", "label"}
    BOUNDARIES = SECTIONS | {"procedure", "function", "begin", "implementation", "end"}

    def __init__(self, text, filename=""):
        self.text, self.filename, self.tokens = text, filename, lex(text)
        self.scopes, self.headers, self.field_tokens = [], {}, {}
        self.root = Scope("", 0, len(self.tokens))
        self.scopes.append(self.root)
        self.parse()

    def at(self, i):
        return self.tokens[i].low if i < len(self.tokens) else ""

    def matching(self, i, opening="(", closing=")"):
        depth = 0
        for j in range(i, len(self.tokens)):
            if self.at(j) == opening:
                depth += 1
            elif self.at(j) == closing:
                depth -= 1
                if not depth:
                    return j
        raise ValueError(f"{self.filename}: unclosed {opening}")

    def statement_end(self, i):
        depth = record = 0
        while i < len(self.tokens):
            t = self.at(i)
            if t in ("(", "["):
                depth += 1
            elif t in (")", "]"):
                depth -= 1
            elif t == "record":
                record += 1
            elif t == "end" and record:
                record -= 1
            elif t == ";" and not depth and not record:
                return i
            i += 1
        raise ValueError(f"{self.filename}: unterminated declaration")

    def type_expr(self, a, b):
        if a >= b:
            return Type()
        if self.at(a) == "packed":
            a += 1
        t = self.at(a)
        if t == "^":
            return Type("pointer", item=self.type_expr(a + 1, b))
        if t == "array":
            end = self.matching(a + 1, "[", "]")
            return Type("array", item=self.type_expr(end + 2, b))
        if t == "record":
            result = Type("record")
            # At ':' walk back over a comma-separated field-name group. Variant
            # tags (case Tag: Byte of) are fields too; anonymous tags are not.
            for i in range(a + 1, b):
                if self.at(i) != ":":
                    continue
                k = i - 1
                group = []
                while k > a and self.tokens[k].kind == "id":
                    group.append(k)
                    if self.at(k - 1) != ",":
                        break
                    k -= 2
                end = i + 1
                while end < b and self.at(end) not in (";", ")", "end"):
                    end += 1
                for k in group:
                    name = self.at(k)
                    result.fields[name] = self.type_expr(i + 1, end)
                    result.declarations[name] = k
            return result
        return Type("name", t)

    def variables(self, a, b, scope, params=False):
        # Semicolon-separated declarations/formal groups; a group may be
        # untyped (var Data), in which case it cannot resolve record accesses.
        start, depth = a, 0
        for i in range(a, b + 1):
            t = self.at(i) if i < b else ";"
            if t in ("(", "["):
                depth += 1
            elif t in (")", "]"):
                depth -= 1
            if t != ";" or depth:
                continue
            colon = next((j for j in range(start, i) if self.at(j) == ":"), i)
            names = [j for j in range(start, colon) if self.tokens[j].kind == "id"
                     and self.at(j) not in ("var", "const")]
            end = next((j for j in range(colon + 1, i) if self.at(j) == "="), i)
            typ = self.type_expr(colon + 1, end)
            for j in names:
                scope.variables[self.at(j)] = typ
                scope.declarations[self.at(j)] = j
                if params:
                    scope.params.add(self.at(j))
            start = i + 1

    def declarations(self, i, scope, interface=False):
        while i < len(self.tokens):
            t = self.at(i)
            if t in ("procedure", "function"):
                i = self.routine(i, scope, interface)
            elif t in self.SECTIONS:
                section = t
                i += 1
                while i < len(self.tokens) and self.at(i) not in self.BOUNDARIES:
                    end = self.statement_end(i)
                    if section == "type" and self.at(i + 1) == "=":
                        name = self.at(i)
                        typ = self.type_expr(i + 2, end)
                        scope.types[name] = typ
                        if typ.kind == "record":
                            for f, pos in typ.declarations.items():
                                self.field_tokens[pos] = (name, f)
                    elif section in ("var", "const"):
                        if section == "var" or any(self.at(j) == ":" for j in range(i, end)):
                            self.variables(i, end, scope)
                    i = end + 1
            else:
                break
        return i

    def routine(self, i, parent, interface):
        start, name = i, self.at(i + 1)
        end = self.statement_end(i)
        scope = Scope(name, start, parent=parent, interface=interface)
        self.scopes.append(scope)
        parent.children.append(scope)
        if self.at(i + 2) == "(":
            close = self.matching(i + 2)
            self.variables(i + 3, close, scope, params=True)
        elif name in self.headers:
            old = self.headers[name]
            scope.variables.update(old.variables)
            scope.params.update(old.params)
        self.headers[name] = scope
        i = end + 1
        # Calling-convention keywords are standalone directives after header.
        while self.at(i) in ("far", "near", "interrupt"):
            i = self.statement_end(i) + 1
        if interface:
            scope.end = i
            return i
        if self.at(i) in ("external", "forward", "inline"):
            scope.definition = self.at(i) != "forward"
            scope.end = self.statement_end(i) + 1
            return scope.end
        i = self.declarations(i, scope)
        if self.at(i) != "begin":
            raise ValueError(f"{self.filename}: missing body for {name} at {self.at(i)}")
        scope.definition, scope.body = True, i
        i = self.block_end(i) + 1
        if self.at(i) == ";":
            i += 1
        scope.end = i
        return i

    def block_end(self, i):
        depth = 0
        for j in range(i, len(self.tokens)):
            t = self.at(j)
            if t in ("begin", "case", "record"):
                depth += 1
            elif t == "end":
                depth -= 1
                if not depth:
                    return j
        raise ValueError(f"{self.filename}: missing end")

    def parse(self):
        i = 0
        if self.at(i) in ("unit", "program"):
            self.root.name = self.at(i + 1)
            i = self.statement_end(i) + 1
        if self.at(i) == "interface":
            i += 1
            interface = True
        else:
            interface = False
        if self.at(i) == "uses":
            i = self.statement_end(i) + 1
        i = self.declarations(i, self.root, interface)
        if self.at(i) == "implementation":
            i += 1
            if self.at(i) == "uses":
                i = self.statement_end(i) + 1
            i = self.declarations(i, self.root)
        if self.at(i) == "begin":
            self.root.body = i
            self.block_end(i)
        elif self.at(i) != "end":
            raise ValueError(f"{self.filename}: unexpected module token {self.at(i)}")

    def scope_at(self, i):
        scope = self.root
        while True:
            child = next((s for s in scope.children if s.start <= i < s.end), None)
            if not child:
                return scope
            scope = child


def symbol_names(names):
    return {old.lower(): row["name"] for cat in CATEGORIES
            for old, row in names.get(cat, {}).items() if "." not in old}


def reverse_names(names):
    result = {new.upper(): old.upper() for old, new in symbol_names(names).items()}
    # The program file remains SAM.PAS; its segment is named by 'program'.
    if "p" in names.get("units", {}):
        result[names["units"]["p"]["name"].upper()] = "SAM"
    return result


def validate_names(names):
    # Exported symbols share a namespace; record fields and routine locals
    # belong to their declaring scope and may repeat in unrelated scopes.
    seen, scoped = {}, {}
    for cat in CATEGORIES:
        for old, row in names.get(cat, {}).items():
            if row.get("confidence") not in CONFIDENCE or not row.get("evidence"):
                raise ValueError(f"{cat}.{old}: missing confidence/evidence")
            entries = [(old, row["name"], seen)]
            for key in ("fields", "params", "locals", "labels"):
                namespace = scoped.setdefault((cat, old, "fields" if key == "fields" else "routine"), {})
                entries += [(old + "." + key + "." + k, v, namespace)
                            for k, v in row.get(key, {}).items()]
            for entity, name, namespace in entries:
                # A no-op is not a new name (e.g. standard BIOS AX/AL fields).
                if entity.rsplit(".", 1)[-1].lower() == name.lower():
                    continue
                if not IDENT.fullmatch(name) or name.lower() in BORLAND:
                    raise ValueError(f"{entity}: invalid/reserved TP5 identifier {name}")
                if cat == "units" and len(name) > 8:
                    raise ValueError(f"{entity}: unit name exceeds DOS 8.3")
                if cat == "units" and name.upper() in DOS_DEVICES:
                    raise ValueError(f"{entity}: unit name is a reserved DOS device")
                if name.lower() in namespace:
                    raise ValueError(f"{entity}: {name} already used by {namespace[name.lower()]}")
                namespace[name.lower()] = entity
    return {**seen, **{name: entity for namespace in scoped.values()
                      for name, entity in namespace.items()}}


def merge_proposals(a, b, sources):
    """Higher confidence, then owning unit, then a; retain selected evidence."""
    parsed = {p: Pascal(text, p) for p, text in sources.items() if p.upper().endswith(".PAS")}
    owners = {}
    for filename, pas in parsed.items():
        unit = "p" if filename.upper() == "SAM.PAS" else pas.root.name
        for n in pas.root.variables.keys() | pas.root.types.keys():
            owners[n] = unit
    groups = {"a": {"p", "u1", "u2", "u7"}, "b": {"u3", "u4", "u5", "u6", "u8", "u9"}}
    merged, decisions = {cat: {} for cat in CATEGORIES}, []
    for cat in CATEGORIES:
        amap = {k.lower(): (k, v) for k, v in a[cat].items()}
        bmap = {k.lower(): (k, v) for k, v in b[cat].items()}
        for key in sorted(amap.keys() | bmap.keys()):
            choices = [(source, *table[key]) for source, table in (("a", amap), ("b", bmap)) if key in table]
            owner = key.split("_", 1)[0] if cat == "routines" else owners.get(key)
            winner = max(choices, key=lambda c: (CONFIDENCE[c[2]["confidence"]],
                         owner in groups[c[0]], c[0] == "a"))
            source, original, row = winner
            merged[cat][original] = copy.deepcopy(row)
            merged[cat][original]["proposal"] = "names-" + source
            if len(choices) == 2 and choices[0][2] != choices[1][2]:
                decisions.append({"category": cat, "key": original, "owner": owner,
                                  "selected": "names-" + source,
                                  "alternatives": [c[2] for c in choices]})
            # Scoped identifiers have their own assessments. Resolve each
            # field/formal/local key by the same rule rather than inheriting
            # the confidence of its parent type/routine name.
            target = merged[cat][original]
            for kind, singular in (("fields", "field"), ("params", "param"),
                                   ("locals", "local"), ("labels", "label")):
                members = {}
                for src, _, entry in choices:
                    for member, proposed in entry.get(kind, {}).items():
                        detail = copy.deepcopy(entry.get(singular + "_details", {}).get(member, {}))
                        detail.setdefault("confidence", entry.get(singular + "_confidence", {}).get(member, entry["confidence"]))
                        detail.setdefault("evidence", entry.get(singular + "_evidence", {}).get(member, entry["evidence"]))
                        detail["proposal"] = "names-" + src
                        members.setdefault(member.lower(), []).append((src, member, proposed, detail))
                if not members:
                    continue
                target[kind], target[singular + "_details"] = {}, {}
                target.pop(singular + "_confidence", None)
                target.pop(singular + "_evidence", None)
                for member_choices in members.values():
                    chosen = max(member_choices, key=lambda c: (CONFIDENCE[c[3]["confidence"]],
                                 owner in groups[c[0]], c[0] == "a"))
                    src, member, proposed, detail = chosen
                    target[kind][member] = proposed
                    target[singular + "_details"][member] = detail
                    if len(member_choices) > 1 and member_choices[0][2:] != member_choices[1][2:]:
                        decisions.append({"category": cat + "." + kind,
                            "key": original + "." + member, "owner": owner,
                            "selected": "names-" + src,
                            "alternatives": [{"name": c[2], **c[3]} for c in member_choices]})
    # Source generation lifted routine-local types to U8 and prefixed them.
    # Bind proposal keys to actual standalone declarations, preserving their
    # logical proposal key and separately renaming distinct declarations.
    actual_types = set().union(*(p.root.types.keys() for p in parsed.values()))
    types = {}
    for key, row in merged["types"].items():
        if "." in key:
            lid, typ = key.split(".", 1)
            actual = ["t_" + lid.lower() + "_" + typ.lower()]
        elif key.lower() in actual_types:
            actual = [key]
        else:
            actual = sorted(n for n in actual_types if n.endswith("_" + key.lower()))
        if not actual:
            actual = [key]   # retained as an unapplied proposal, reported below
        for name in actual:
            clone = copy.deepcopy(row)
            clone["proposal_key"] = key
            types[name] = clone
    merged["types"] = types
    # Reserve all existing tokens too: a new name must not capture an existing
    # local, Borland record member or an assembler register/opcode.
    used = set(BORLAND)
    for filename, text in sources.items():
        if filename.upper().endswith((".PAS", ".ASM")):
            used.update(t.low for t in lex(text, "asm" if filename.upper().endswith(".ASM") else "pas")
                        if t.kind == "id")
    changes = []

    def allocate(entity, old, wanted, prefix):
        if old.lower() == wanted.lower():
            return wanted
        candidate = wanted
        if not IDENT.fullmatch(candidate) or candidate.lower() in used:
            # Preserve the proposed semantic role; abbreviate only the scope
            # qualifier to stay within TASM 1.0's 31-character identifiers.
            qualifier = re.sub(r"[^A-Za-z_0-9]", "", prefix)[:max(4, 30 - len(wanted))]
            candidate = qualifier + "_" + wanted
            if len(candidate) > 31:
                candidate = candidate[:24] + "_" + hashlib.sha256(entity.encode()).hexdigest()[:6]
            if not candidate or not candidate[0].isalpha():
                candidate = "Named_" + candidate[:25]
            count = 2
            base = candidate
            while candidate.lower() in used:
                suffix = "_" + str(count)
                candidate = base[:31 - len(suffix)] + suffix
                count += 1
        used.add(candidate.lower())
        if candidate != wanted:
            changes.append({"entity": entity, "proposed": wanted, "name": candidate,
                            "reason": "program-wide uniqueness / existing or Borland identifier"})
        return candidate

    # Allocate exported names first, so a local cannot capture one.
    for cat in CATEGORIES:
        for old, row in merged[cat].items():
            row["name"] = allocate(cat + "." + old, old, row["name"], old)
    for cat in ("types", "routines"):
        for old, row in merged[cat].items():
            for kind in ("fields", "params", "locals", "labels"):
                for member, wanted in row.get(kind, {}).items():
                    entity = cat + "." + old + "." + kind + "." + member
                    row[kind][member] = allocate(entity, member, wanted, row["name"])
    merged["merge"] = {"policy": "confidence; owning unit; names-a", "decisions": decisions,
                       "qualified_names": changes}
    validate_names(merged)
    return merged


def description(row):
    text = row.get("description", row.get("evidence", ""))
    text = re.sub(r"\s+", " ", text).replace("{", "(").replace("}", ")").replace("*)", ")")
    text = text.encode("ascii", "replace").decode("ascii")
    # Keep complete short factual sentences; don't cut a word mid-description.
    if len(text) > 108:
        prefix = text[:105]
        boundary = max(prefix.rfind(";"), prefix.rfind(","))
        text = prefix[:boundary] if boundary >= 45 else prefix.rsplit(" ", 1)[0]
        text = re.sub(r"\s+(?:and|or|the|to|with|a|an)$", "", text).rstrip(".,;:") + "."
    return text


def edits_text(text, edits):
    for start, end, replacement in sorted(edits, reverse=True):
        text = text[:start] + replacement + text[end:]
    return text


def wrap_pascal(text, limit=126):
    """TP5 limits source lines; split only whitespace between lexical tokens."""
    protected = [(m.start(), m.end()) for m in PASLEX.finditer(text)
                 if m.lastgroup in ("string", "comment")]
    edits = []
    pos = 0
    for line in text.splitlines(keepends=True):
        content = line.rstrip("\r\n")
        newline = "\r\n" if line.endswith("\r\n") else "\n"
        indent = re.match(r"[ \t]*", content)[0]
        continuation = indent if len(indent) >= 2 else "  "
        start, extra = 0, 0
        while len(content) - start + extra > limit:
            choices = [m for m in re.finditer(r"[ \t]+", content)
                       if start < m.start() <= start + limit - extra
                       and not any(a <= pos + m.start() < b for a, b in protected)]
            if choices:
                gap = choices[-1]
                a, b = gap.start(), gap.end()
            else:
                # Compact expressions need a break after punctuation. These
                # are complete lexical tokens, never literal/comment bytes.
                boundaries = [m.end() for m in PASLEX.finditer(content)
                              if m.lastgroup == "symbol" and m[0] in (",", ";", "+", "-", "(", "=", ":=")
                              and start < m.end() <= start + limit - extra
                              and not any(a <= pos + m.start() < b for a, b in protected)]
                if not boundaries:
                    raise ValueError("Pascal line exceeds TP5 limit without a safe token boundary: " + content)
                a = b = boundaries[-1]
            edits.append((pos + a, pos + b, newline + continuation))
            start, extra = b, len(continuation)
        pos += len(line)
    return edits_text(text, edits)


class Renamer:
    def __init__(self, names, sources):
        validate_names(names)
        self.names, self.sources = names, sources
        self.flat = symbol_names(names)
        if "p" in names.get("units", {}):
            self.flat["sam"] = names["units"]["p"]["name"]
        self.pas = {n: Pascal(t, n) for n, t in sources.items() if n.upper().endswith(".PAS")}
        self.types = {}
        self.globals = {}
        for pas in self.pas.values():
            self.types.update(pas.root.types)
            self.globals.update(pas.root.variables)
        self.field_maps = {n.lower(): {f.lower(): new for f, new in row.get("fields", {}).items()
                           if f.lower() != new.lower()} for n, row in names.get("types", {}).items()}
        self.report = {"applied": {}, "skipped": [], "files": {}, "comments": 0}
        self.used = set()

    def resolve(self, typ):
        seen = set()
        while typ and typ.kind == "name" and typ.name in self.types and typ.name not in seen:
            seen.add(typ.name)
            typ = self.types[typ.name]
        return typ or Type()

    def record_name(self, typ):
        seen = set()
        while typ and typ.kind == "name" and typ.name in self.types and typ.name not in seen:
            seen.add(typ.name)
            value = self.types[typ.name]
            if value.kind == "record":
                return typ.name
            typ = value
        return None

    def field_accesses(self, pas):
        accesses = {}
        # Resolve variable[index]^, nested field chains, pointer casts and
        # typed record constants using the actual declared receiver type.
        for i, token in enumerate(pas.tokens):
            if token.kind != "id" or pas.at(i - 1) == "." and i:
                continue
            scope = pas.scope_at(i)
            typ = scope.lookup(token.low) or self.globals.get(token.low)
            j = i + 1
            if token.low in self.types and pas.at(j) == "(":
                typ = Type("name", token.low)
                j = pas.matching(j) + 1
            if not typ:
                continue
            while j < len(pas.tokens):
                if pas.at(j) == "[":
                    value = self.resolve(typ)
                    # Pascal's multi-dimensional array uses one bracket list.
                    typ = value.item if value.kind == "array" else Type()
                    j = pas.matching(j, "[", "]") + 1
                elif pas.at(j) == "^":
                    value = self.resolve(typ)
                    typ = value.item if value.kind == "pointer" else Type()
                    j += 1
                elif pas.at(j) == "." and pas.tokens[j + 1].kind == "id":
                    owner = self.record_name(typ)
                    accesses[j + 1] = (owner, pas.at(j + 1))
                    value = self.resolve(typ)
                    typ = value.fields.get(pas.at(j + 1), Type())
                    j += 2
                else:
                    break
        accesses.update(pas.field_tokens)
        # Named fields in typed record constants: (Name: value; ...).
        for n, pos in pas.root.declarations.items():
            typ = pas.root.variables[n]
            owner = self.record_name(typ)
            if not owner:
                continue
            end = pas.statement_end(pos)
            equal = next((i for i in range(pos, end) if pas.at(i) == "="), None)
            if equal is not None:
                for i in range(equal + 1, end):
                    if pas.at(i + 1) == ":" and pas.tokens[i].kind == "id":
                        accesses[i] = (owner, pas.at(i))
        return accesses

    def scoped_map(self, scope):
        row = self.names.get("routines", {}).get(scope.name, {})
        # Maps may preserve original mixed-case routine keys.
        if not row:
            row = next((v for k, v in self.names.get("routines", {}).items() if k.lower() == scope.name), {})
        maps = {old.lower(): new for kind in ("params", "locals", "labels")
                for old, new in row.get(kind, {}).items()}
        for old, canonical in row.get("param_aliases", {}).items():
            if canonical.lower() in maps:
                maps[old.lower()] = maps[canonical.lower()]
        # Only apply to a declared identifier, never a coincidental token in
        # another scope. Labels have declarations outside variable tables.
        labels = {n.lower() for n in row.get("labels", {})}
        return {old: new for old, new in maps.items() if old in scope.variables or old in labels}

    def rewrite_pascal(self, filename, text, blocked):
        pas, edits = self.pas[filename], []
        accesses = self.field_accesses(pas)
        scoped = {id(s): self.scoped_map(s) for s in pas.scopes}
        for i, token in enumerate(pas.tokens):
            if token.kind != "id":
                continue
            replacement = None
            if i in accesses:
                owner, member = accesses[i]
                if owner not in blocked:
                    replacement = self.field_maps.get(owner, {}).get(member)
                if replacement:
                    self.used.add(("fields", owner, member))
            elif i and pas.at(i - 1) == ".":
                # Unknown member, including Borland Registers fields: never
                # rename via a local/global token map.
                pass
            else:
                scope = pas.scope_at(i)
                current = scope
                while current:
                    if token.low in scoped[id(current)]:
                        replacement = scoped[id(current)][token.low]
                        self.used.add(("scoped", current.name, token.low))
                        break
                    if token.low in current.variables:
                        break
                    current = current.parent
                # Do not let a global/type name capture a shadowing local.
                if replacement is None and (scope is pas.root or token.low not in scope.variables):
                    replacement = self.flat.get(token.low)
                if replacement and token.low in self.flat:
                    self.used.add(("symbol", "p" if token.low == "sam" else token.low))
            if replacement and replacement != token.text:
                edits.append((token.start, token.end, replacement))
        newline = "\r\n" if "\r\n" in text else "\n"
        rows = {k.lower(): v for k, v in self.names.get("routines", {}).items()}
        for scope in pas.scopes[1:]:
            if scope.definition and scope.name in rows:
                at = text.rfind("\n", 0, pas.tokens[scope.start].start) + 1
                indent = text[at:pas.tokens[scope.start].start]
                edits.append((at, at, indent + "{ " + description(rows[scope.name]) + " }" + newline))
                self.report["comments"] += 1
        # Main/unit-initialization atlas entries have no Pascal routine name.
        # Describe the existing block without fabricating a procedure.
        if pas.root.body is not None:
            existing = {s.name for s in pas.scopes[1:]}
            unit = "p" if filename.upper() == "SAM.PAS" else pas.root.name
            body_rows = [row for lid, row in rows.items() if lid.startswith(unit + "_")
                         and lid not in existing
                         and (unit == "p" and lid == "p_1148" or unit != "p")]
            if len(body_rows) == 1:
                at = text.rfind("\n", 0, pas.tokens[pas.root.body].start) + 1
                comment = "{ " + description(body_rows[0]) + " }"
                if not text[:at].rstrip("\r\n").endswith(comment):
                    edits.append((at, at, comment + newline))
                    self.report["comments"] += 1
        return wrap_pascal(edits_text(text, edits)), len(edits)

    def rewrite_asm(self, text):
        edits = []
        for t in lex(text, "asm"):
            if t.kind == "id" and t.low in self.flat:
                self.used.add(("symbol", t.low))
                edits.append((t.start, t.end, self.flat[t.low]))
        newline = "\r\n" if "\r\n" in text else "\n"
        for m in re.finditer(r"(?im)^([ \t]*)(\w+)[ \t]+proc\b", text):
            row = self.names.get("routines", {}).get(m[2].lower())
            if row:
                edits.append((m.start(), m.start(), m[1] + "; " + description(row) + newline))
                self.report["comments"] += 1
        return edits_text(text, edits), len(edits)

    def transform(self):
        blocked = set()
        by_member = {}
        for owner, mapping in self.field_maps.items():
            for old in mapping:
                by_member.setdefault(old, set()).add(owner)
        for filename, pas in self.pas.items():
            accesses = self.field_accesses(pas)
            for i, token in enumerate(pas.tokens):
                if token.low == "with" and token.kind == "id" and any(self.field_maps.values()):
                    raise ValueError(f"{filename}: with requires explicit type resolution before field renaming")
                if i and pas.at(i - 1) == "." and token.low in by_member:
                    owner = accesses.get(i, (None, None))[0]
                    if owner is None:
                        # Known Borland Registers members are intentionally
                        # untouched; no game field map targets those names.
                        if token.low in BORLAND:
                            continue
                        candidates = by_member[token.low]
                        blocked |= candidates
                        self.report["skipped"].append({"file": filename, "field": token.text,
                            "line": pas.text.count("\n", 0, token.start) + 1,
                            "types": sorted(candidates), "reason": "unresolved record receiver; whole type fields preserved"})
        output = {}
        for filename, text in self.sources.items():
            suffix = Path(filename).suffix.upper()
            target = filename
            if suffix == ".PAS":
                result, count = self.rewrite_pascal(filename, text, blocked)
                if filename.upper() != "SAM.PAS" and Path(filename).stem.lower() in self.flat:
                    target = self.flat[Path(filename).stem.lower()].upper() + ".PAS"
            elif suffix == ".ASM":
                result, count = self.rewrite_asm(text)
            elif suffix == ".BAT":
                units = {k.lower(): v["name"].upper() for k, v in self.names.get("units", {}).items() if k.lower() != "p"}
                result = re.sub(r"(?i)\b(U[1-9])(?=\.TPU\b)", lambda m: units.get(m[1].lower(), m[1]), text)
                count = sum(a != b for a, b in zip(text.splitlines(), result.splitlines()))
            elif filename.upper() == "README.MD":
                result = self.rewrite_readme(text)
                count = int(result != text)
            else:
                result, count = text, 0
            if target.upper() in {n.upper() for n in output}:
                raise ValueError(f"renamed filename collision: {target}")
            output[target] = result
            self.report["files"][filename] = {"target": target, "edits": count}
        for cat in CATEGORIES:
            applied = []
            for old, row in self.names.get(cat, {}).items():
                if ("symbol", old.lower()) in self.used:
                    applied.append(old)
                else:
                    self.report["skipped"].append({"category": cat, "key": old, "reason": "no identifier in standalone tree (body/init label or absent declaration)"})
            self.report["applied"][cat] = applied
        self.report["applied"]["fields"] = [list(t[1:]) for t in sorted(self.used) if t[0] == "fields"]
        self.report["applied"]["scoped"] = [list(t[1:]) for t in sorted(self.used) if t[0] == "scoped"]
        self.report["blocked_field_types"] = sorted(blocked)
        return output, self.report

    def rewrite_readme(self, text):
        """Keep the standalone tree's existing filename/build documentation current."""
        units = self.names.get("units", {})
        newline = "\r\n" if "\r\n" in text else "\n"
        old = "| U1.PAS through U9.PAS | Original translation units; logical names retained |"
        if all(f"u{i}" in units for i in range(1, 10)):
            roles = ("Actor updates, movement, collision and pickups", "Level loading and layer drawing",
                     "Menus, HUD, saved games and resource loading", "Text-mode drawing and adapter detection",
                     "Genus PCX toolkit interface", "Joystick interface", "PC-speaker effect selection",
                     "Shared declarations, defaults and asset decoder", "ProGraphx EGA/VGA toolbox interface")
            replacement = newline.join(f"| {units[f'u{i}']['name'].upper()}.PAS | {role} (U{i}) |"
                                       for i, role in enumerate(roles, 1))
            text = text.replace(old, replacement)
        text = text.replace("nine generated U*.TPU files", "nine generated game-unit TPU files")
        text = text.replace("python tools/standalone.py build/workers/sol-standalone/game",
                            "python tools/standalone.py game")
        old = newline.join(("source appears once. Address identifiers and U1..U9 names are retained",
                            "for the later readability phase. Original binaries/assets and historical",
                            "tool binaries are not included in this tree."))
        program = units.get("p", {}).get("name", "SAM")
        replacement = newline.join((
            "source appears once. Semantic identifiers come from layout/names.json, which",
            "keeps their logical coordinates, confidence and behavioral evidence. Routine",
            "comments describe the existing code; main/unit initialization blocks retain",
            "their original structure. SAM.PAS stays the build entry file and its program",
            f"identifier is {program}. The six object filenames and link directives remain",
            "unchanged. Original binaries/assets and historical tool binaries are not",
            "included in this tree."))
        return text.replace(old, replacement)


def read_tree(tree):
    return {p.name: p.read_bytes().decode("latin1") for p in sorted(tree.iterdir())
            if p.is_file() and p.suffix.upper() in (".PAS", ".ASM", ".BAT", ".MD")}


def same_proof(before, after):
    keys = ("ok", "equal_bytes", "image_size", "differing_bytes", "residue_bytes_differing",
            "allowed_residue_bytes", "outside_residue_count")
    for ep in ("sam1", "sam2", "sam3"):
        a, b = before[ep], after[ep]
        if not a["ok"] or not b["ok"] or any(a.get(k) != b.get(k) for k in keys):
            raise ValueError(f"{ep}: renamed proof differs from baseline")
        holes = lambda r: [(h["unit"], h["original_range"], h["candidate_range"]) for h in r["object_holes"]]
        if holes(a) != holes(b) or not all(b["checks"].values()):
            raise ValueError(f"{ep}: renamed ranges/checks differ from baseline")


def apply_verified(tree, names, work, builder=None, source_tree=None):
    """Never edit the input until both fresh builds and the invariant proof pass."""
    tree, work = tree.resolve(), work.resolve()
    if tree == work or tree in work.parents or work in tree.parents:
        raise ValueError("staging and source trees must be disjoint")
    before_hashes = {p.name: sha256_file(p) for p in tree.iterdir() if p.is_file()}
    sources = read_tree(tree)
    output, report = Renamer(names, read_tree(source_tree) if source_tree else sources).transform()
    work.mkdir(parents=True, exist_ok=False)
    stage = work / "game"
    stage.mkdir()
    for n, t in output.items():
        (stage / n).write_bytes(t.encode("latin1"))
    atomic_json(work / "rename-report.json", report)
    if builder is None:
        import standalone
        builder = lambda source, ep, dest: standalone.build_episode(source, ep, dest)
    before, after = {}, {}
    for ep in ("sam1", "sam2", "sam3"):
        before[ep] = builder(tree, ep, work / "baseline" / ep)
        after[ep] = builder(stage, ep, work / "proof" / ep)
        print(f"{ep}: baseline {before[ep].get('status')}; renamed {after[ep].get('status')}", flush=True)
    atomic_json(work / "proof.json", {"before": before, "after": after})
    same_proof(before, after)
    if before_hashes != {p.name: sha256_file(p) for p in tree.iterdir() if p.is_file()}:
        raise ValueError("source tree changed during verification; refusing replacement")
    backup = work / "original"
    shutil.copytree(tree, backup)
    # Text-only replacement, with rollback on an I/O error. The source tree
    # directory stays in place, so open editors and relative paths still work.
    try:
        for p in tree.iterdir():
            if p.is_file() and p.name not in output:
                p.unlink()
        for n, t in output.items():
            (tree / n).write_bytes(t.encode("latin1"))
    except OSError:
        for p in tree.iterdir():
            if p.is_file() and p.name not in sources:
                p.unlink()
        for n, t in sources.items():
            (tree / n).write_bytes(t.encode("latin1"))
        raise
    atomic_json(work / "result.json", {"status": "EQUAL", "tree": str(tree),
                "backup": str(backup), "report": report, "proof": str(work / "proof.json")})
    return report


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("tree", type=Path, nargs="?", default=ROOT / "game")
    ap.add_argument("--names", type=Path, default=NAMES)
    ap.add_argument("--merge", action="store_true")
    mode = ap.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="default: stage/report without DOS or editing game")
    mode.add_argument("--apply", action="store_true", help="build baseline and renamed SAM1/2/3, then replace game")
    ap.add_argument("--work", type=Path)
    ap.add_argument("--source-tree", type=Path,
                    help="coordinate source backup to reapply an updated map to an already renamed tree")
    args = ap.parse_args(argv)
    if args.merge:
        proposals = [load_json(ROOT / f"build/workers/sol-names-{suffix}/names.json") for suffix in ("a", "b")]
        sources = read_tree(args.source_tree or args.tree)
        if not all(f"U{i}.PAS" in {n.upper() for n in sources} for i in range(1, 10)):
            ap.error("--merge requires the coordinate tree; use --source-tree with the verified original backup")
        names = merge_proposals(*proposals, sources)
        atomic_json(args.names, names)
        print(f"Merged names: {args.names}")
        if not args.apply and not args.dry_run:
            return 0
    else:
        names = load_json(args.names)
    work = args.work or OUT / ("rename-" + uuid.uuid4().hex[:12])
    if args.apply:
        report = apply_verified(args.tree, names, work, source_tree=args.source_tree)
    else:
        output, report = Renamer(names, read_tree(args.source_tree or args.tree)).transform()
        work.mkdir(parents=True, exist_ok=False)
        stage = work / "game"
        stage.mkdir()
        for filename, text in output.items():
            (stage / filename).write_bytes(text.encode("latin1"))
        atomic_json(work / "rename-report.json", report)
    print("Applied/staged: " + ", ".join(f"{len(v)} {k}" for k, v in report["applied"].items()))
    print(f"Skipped: {len(report['skipped'])}; report: {work / 'rename-report.json'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
