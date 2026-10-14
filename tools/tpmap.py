"""Parser for Turbo Pascal 5.0 /GD map files.

A map gives the segment table (name, class, start, length), public symbols
(program-level routines and globals, unit interface routines and variables,
System/Crt/Dos variables) and per-module line-number records (line -> seg:off),
which mark routine entry points for routines the publics omit (unit
implementation and nested routines).
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

_SEG = re.compile(r"^\s*([0-9A-F]{5})H\s+([0-9A-F]{5})H\s+([0-9A-F]{5})H\s+(\S+)\s+(\S+)\s*$", re.M)
_PUB = re.compile(r"^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+(\S+)\s*$", re.M)
_LINEHDR = re.compile(r"^Line numbers for (\S+)\((\S+)\) segment (\S+)\s*$", re.M)
_LINE = re.compile(r"(\d+)\s+([0-9A-F]{4}):([0-9A-F]{4})")
_ENTRY = re.compile(r"Program entry point at ([0-9A-F]{4}):([0-9A-F]{4})")


@dataclass
class Segment:
    name: str
    cls: str
    start: int          # linear offset in the load image
    length: int

    @property
    def para(self) -> int:
        return self.start >> 4


@dataclass
class Map:
    segments: list = field(default_factory=list)
    publics: dict = field(default_factory=dict)     # name -> (para, off)
    by_addr: dict = field(default_factory=dict)     # (para, off) -> name (first)
    lines: dict = field(default_factory=dict)       # module -> [(line, para, off)]
    entry: tuple | None = None

    def segment(self, name: str) -> Segment:
        for s in self.segments:
            if s.name.upper() == name.upper():
                return s
        raise KeyError(name)

    def segment_at_para(self, para: int) -> Segment | None:
        for s in self.segments:
            if s.para == para:
                return s
        return None

    def data(self) -> Segment:
        return next(s for s in self.segments if s.cls.upper() == "DATA")


def parse(text: str) -> Map:
    m = Map()
    head = text.split("Publics by Value")[0]
    for a, b, ln, name, cls in _SEG.findall(head):
        m.segments.append(Segment(name, cls, int(a, 16), int(ln, 16)))
    pub = text.split("Publics by Value", 1)[1] if "Publics by Value" in text else ""
    pub = pub.split("Line numbers for", 1)[0].split("Program entry point", 1)[0]
    for seg, off, name in _PUB.findall(pub):
        key = (int(seg, 16), int(off, 16))
        m.publics[name.upper()] = key
        m.by_addr.setdefault(key, name.upper())
    parts = _LINEHDR.split(text)
    # parts: [pre, module, file, segment, body, module, file, segment, body, ...]
    for i in range(1, len(parts) - 3, 4):
        module, body = parts[i], parts[i + 3]
        body = body.split("Program entry point", 1)[0]
        m.lines[module.upper()] = [(int(l), int(s, 16), int(o, 16)) for l, s, o in _LINE.findall(body)]
    e = _ENTRY.search(text)
    if e:
        m.entry = (int(e.group(1), 16), int(e.group(2), 16))
    return m
