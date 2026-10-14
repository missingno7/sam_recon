#!/usr/bin/env python3
"""A source front end for the Turbo Pascal subset used by Secret Agent.

The layout pass is source based. MAPs and DOS images are validation inputs only;
this module deliberately has no dependency on the oracle or historical binaries.
"""
from __future__ import annotations
import argparse
from dataclasses import dataclass, field
import json
from pathlib import Path
import re
import sys

class CompileError(Exception):
    pass

@dataclass
class Token:
    text: str
    value: object
    file: str
    line: int
    kind: str = 'symbol'
    end_line: int = 0

    def error(self, message):
        raise CompileError(f'{self.file}:{self.line}: {message}')

def lex(source: str, file: str, defines: set[str], comments=None):
    """Lex comments/directives and evaluate conditionals while preserving lines."""
    (out, stack) = ([], [])
    (active, i, line) = (True, 0, 1)
    while i < len(source):
        ch = source[i]
        if ch.isspace():
            line += ch == '\n'
            i += 1
            continue
        if ch == '{' or source.startswith('(*', i):
            ender = '}' if ch == '{' else '*)'
            begin = i + (1 if ch == '{' else 2)
            end = source.find(ender, begin)
            if end < 0:
                raise CompileError(f'{file}:{line}: unterminated comment')
            body = source[begin:end].strip()
            if active and (not body.startswith('$')) and (comments is not None):
                comments.append(Token(body, body, file, line, 'comment', line + source[i:end + len(ender)].count('\n')))
            if body.startswith('$'):
                words = body[1:].upper().split()
                op = words[0]
                if op in ('IFDEF', 'IFNDEF'):
                    yes = words[1] in defines
                    if op == 'IFNDEF':
                        yes = not yes
                    stack.append((active, yes, False))
                    active = active and yes
                elif op == 'ELSE':
                    if not stack or stack[-1][2]:
                        raise CompileError(f'{file}:{line}: unmatched ELSE')
                    (parent, yes, _) = stack[-1]
                    stack[-1] = (parent, yes, True)
                    active = parent and (not yes)
                elif op == 'ENDIF':
                    if not stack:
                        raise CompileError(f'{file}:{line}: unmatched ENDIF')
                    active = stack.pop()[0]
                elif op in ('DEFINE', 'UNDEF') and active:
                    if op == 'DEFINE':
                        defines.add(words[1])
                    else:
                        defines.discard(words[1])
                elif active:
                    # Emit semantic switches rather than losing their position.
                    if not re.fullmatch('(?:[ADLFSIRB][+-])+', body[1:].upper()) and op not in ('M',
                         'L'):
                        raise CompileError(f'{file}:{line}: unsupported directive {body}')
                    out.append(Token(body[1:], body[1:], file, line, 'directive'))
            line += source[i:end + len(ender)].count('\n')
            i = end + len(ender)
            continue
        if source.startswith('//', i):
            end = source.find('\n', i)
            i = len(source) if end < 0 else end
            continue
        (start, startline) = (i, line)
        if ch == "'":
            i += 1
            s = ''
            while i < len(source):
                if source[i] == "'":
                    i += 1
                    if i < len(source) and source[i] == "'":
                        s += "'"
                        i += 1
                    else:
                        break
                else:
                    s += source[i]
                    line += source[i] == '\n'
                    i += 1
            else:
                raise CompileError(f'{file}:{startline}: unterminated string')
            t = Token(source[start:i], s.encode('latin1'), file, startline, 'string')
        elif ch.isalpha() or ch == '_':
            i += 1
            while i < len(source) and (source[i].isalnum() or source[i] == '_'):
                i += 1
            t = Token(source[start:i], source[start:i].lower(), file, startline, 'id')
        elif ch.isdigit() or ch == '$':
            i += 1
            while i < len(source) and (source[i] in '0123456789abcdefABCDEF' if ch == '$' else source[i].isdigit()):
                i += 1
            text = source[start:i]
            t = Token(text, int(text[1:], 16) if ch == '$' else int(text), file, startline, 'number')
        else:
            i += 1
            if source[start:i + 1] in (':=', '..', '<=', '>=', '<>'):
                i += 1
            t = Token(source[start:i], source[start:i], file, startline)
        if active:
            out.append(t)
    if stack:
        raise CompileError(f'{file}:{line}: unterminated conditional')
    out.append(Token('<eof>', '<eof>', file, line))
    return out

@dataclass(eq=False)
class Type:
    kind: str
    name: str = ''
    size: int = 0
    signed: bool = False
    lo: int = 0
    hi: int = 0
    elem: Type | None = None
    bounds: list = field(default_factory=list)
    fields: dict = field(default_factory=dict)
    variants: list = field(default_factory=list)
    cname: str = ''
BYTE = Type('ordinal', 'Byte', 1, False, 0, 255, cname='uint8_t')
SHORT = Type('ordinal', 'ShortInt', 1, True, -128, 127, cname='int8_t')
INTEGER = Type('ordinal', 'Integer', 2, True, -32768, 32767, cname='int16_t')
WORD = Type('ordinal', 'Word', 2, False, 0, 65535, cname='uint16_t')
LONG = Type('ordinal', 'LongInt', 4, True, -2147483648, 2147483647, cname='int32_t')
CHAR = Type('char', 'Char', 1, False, 0, 255, cname='uint8_t')
BOOL = Type('bool', 'Boolean', 1, False, 0, 1, cname='uint8_t')
POINTER = Type('pointer', 'Pointer', 4, cname='farptr')
VOID = Type('void', cname='void')
UNTYPED = Type('untyped', cname='void')
STRING = Type('string', 'String', 256, cname='tp_string')
FILE = Type('file', 'File', 128, cname='tp_file')
TEXT = Type('text', 'Text', 256, cname='tp_text')
SET = Type('set', 'set', 32, elem=BYTE, cname='tp_set')

@dataclass(eq=False)
class Symbol:
    name: str
    kind: str
    type: Type = VOID
    value: object = None
    scope: Scope | None = None
    token: Token | None = None
    params: list = field(default_factory=list)
    body: object = None
    locals: list = field(default_factory=list)
    nested: list = field(default_factory=list)
    external: bool = False
    interrupt: bool = False
    byref: bool = False
    offset: int = 0
    cname: str = ''

class Scope:

    def __init__(self, name, parent=None):
        (self.name, self.parent) = (name, parent)
        (self.symbols, self.imports) = ({}, [])
        self.routine = None

    def add(self, sym):
        key = sym.name.lower()
        if key in self.symbols:
            sym.token.error(f'duplicate declaration {sym.name}')
        self.symbols[key] = sym
        sym.scope = self
        return sym

    def find(self, name):
        key = name.lower()
        if key in self.symbols:
            return self.symbols[key]
        for unit in reversed(self.imports):
            if key in unit.interface.symbols:
                return unit.interface.symbols[key]
        return self.parent.find(name) if self.parent else None

@dataclass
class Expr:
    op: str
    args: list = field(default_factory=list)
    token: Token | None = None
    type: Type | None = None
    value: object = None
    sym: Symbol | None = None

@dataclass
class Stmt:
    op: str
    args: list = field(default_factory=list)
    token: Token | None = None

@dataclass
class Unit:
    name: str
    file: str
    interface: Scope
    scope: Scope
    globals: list = field(default_factory=list)
    routines: list = field(default_factory=list)
    types: list = field(default_factory=list)
    init: object = None
    program: bool = False
BUILTIN_ROUTINES = {'length': INTEGER, 'copy': STRING, 'pos': INTEGER, 'concat': STRING,
     'ord': LONG, 'chr': CHAR, 'lo': BYTE, 'hi': BYTE, 'succ': INTEGER, 'pred': INTEGER, 'sizeof': WORD,
     'abs': INTEGER, 'sqr': INTEGER, 'odd': BOOL, 'ptr': POINTER, 'seg': WORD, 'ofs': WORD,
     'cseg': WORD, 'dseg': WORD, 'sseg': WORD, 'random': INTEGER, 'memavail': LONG, 'maxavail': LONG,
     'ioresult': INTEGER, 'keypressed': BOOL, 'readkey': CHAR, 'eof': BOOL, 'eoln': BOOL, 'filesize': LONG,
     'filepos': LONG, 'upcase': CHAR, **dict.fromkeys(('inc', 'dec', 'fillchar', 'move', 'insert',
     'delete', 'str', 'val', 'getmem', 'freemem', 'new', 'dispose', 'mark', 'release', 'assign',
     'reset', 'rewrite', 'close', 'erase', 'read', 'write', 'readln', 'writeln', 'seek', 'halt',
     'randomize', 'delay', 'sound', 'nosound', 'intr', 'msdos', 'getintvec', 'setintvec', 'textmode',
     'gotoxy', 'clrscr', 'textcolor', 'textbackground', 'exit'), VOID)}

class Compiler:

    def __init__(self, source_dir: Path, episode='sam1'):
        (self.source_dir, self.episode) = (source_dir, episode)
        self.prefix = 's' + episode[-1] + '_'
        (self.units, self.types, self.load_order, self.native_units) = ({}, [], [], {})
        self.system = Scope('System')
        for t in (BYTE, SHORT, INTEGER, WORD, LONG, CHAR, BOOL, POINTER, STRING, FILE, TEXT):
            self.system.add(Symbol(t.name, 'type', t))
        for (n, t, v) in [('True', BOOL, 1), ('False', BOOL, 0), ('Nil', POINTER, 0), ('MaxInt',
             INTEGER, 32767)]:
            self.system.add(Symbol(n, 'const', t, v))
        for (n, t) in BUILTIN_ROUTINES.items():
            self.system.add(Symbol(n, 'builtin', t, cname='tp_' + n))
        for (n, t) in [('ExitProc', POINTER), ('ExitCode', INTEGER), ('RandSeed', LONG),
             ('FileMode', BYTE), ('HeapOrg', POINTER), ('HeapPtr', POINTER), ('FreePtr', POINTER),
             ('FreeMin', WORD), ('HeapError', POINTER), ('ErrorAddr', POINTER), ('PrefixSeg', WORD),
             ('StackLimit', WORD), ('InOutRes', WORD), ('Test8087', BYTE), ('Input', TEXT), ('Output',
             TEXT)]:
            self.system.add(Symbol(n, 'runtimevar', t, cname='tp_' + n))
        regs = Type('record', 'Registers', 20, cname='tp_registers')
        for (j, n) in enumerate(('AX', 'BX', 'CX', 'DX', 'BP', 'SI', 'DI', 'DS', 'ES', 'Flags')):
            regs.fields[n.lower()] = (n, WORD, j * 2)
        for (j, n) in enumerate(('AL', 'AH', 'BL', 'BH', 'CL', 'CH', 'DL', 'DH')):
            regs.fields[n.lower()] = (n, BYTE, j)
        self.system.add(Symbol('Registers', 'type', regs))
        for n in ('Mem', 'MemW', 'Port', 'PortW'):
            self.system.add(Symbol(n, 'special', WORD if n.endswith('W') else BYTE))
        self.ds_size = 0
        self.program_layout = None
        self.comments = {}

    def load(self, name):
        key = name.lower()
        if key in ('system', 'dos', 'crt'):
            if key not in self.native_units:
                self.native_units[key] = Unit(name, '', self.system, self.system)
                self.load_order.append(self.native_units[key])
                if key == 'crt':
                    for (n, t) in [('CheckBreak', BOOL), ('CheckEOF', BOOL), ('DirectVideo',
                         BOOL), ('CheckSnow', BOOL), ('LastMode', WORD), ('TextAttr', BYTE), ('WindMin', WORD),
                         ('WindMax', WORD)]:
                        self.system.add(Symbol(n, 'runtimevar', t, cname='tp_' + n))
            return self.native_units[key]
        if key in self.units:
            return self.units[key]
        paths = [p for p in self.source_dir.iterdir() if p.name.lower() == key + '.pas']
        if not paths:
            raise CompileError(f'unit {name}: source not found in {self.source_dir}')
        scope = Scope(name, self.system)
        u = Unit(name, paths[0].name, scope, scope)
        self.units[key] = u
        self.load_order.append(u)
        comments = []
        Parser(self, u, lex(paths[0].read_text(encoding='latin1'), u.file, {self.episode.upper()},
             comments)).parse()
        self.comments[u.file] = comments
        return u

    def addtype(self, t, name=''):
        if not t.cname:
            t.cname = self.prefix + (name or f'type_{len(self.types)}')
            self.types.append(t)
        return t

    def bind(self):
        counts = {}

        def symbols(u):
            return list(dict.fromkeys([*u.interface.symbols.values(), *u.scope.symbols.values()]))
        for u in self.units.values():
            for s in symbols(u):
                if s.kind in ('global', 'typedconst', 'routine'):
                    counts[s.name.lower()] = counts.get(s.name.lower(), 0) + 1
        for u in self.units.values():
            for s in symbols(u):
                if s.kind in ('global', 'typedconst', 'routine'):
                    s.cname = s.name if s.external else self.prefix + (u.name + '_' if counts[s.name.lower()] > 1 else '') + s.name

            def nested(r, path):
                for s in r.locals + r.params:
                    s.cname = self.prefix + s.name
                for n in r.nested:
                    n.cname = self.prefix + path + '_' + n.name
                    nested(n, path + '_' + n.name)
            for r in u.routines:
                nested(r, r.name)
        # TP places typed constants in reverse code/link order, then reserves System,
        # then each module's variables in code/link order. Runtime layout is not yet
        # a certified implementation; gates explicitly reject the whole-image claim.
        loaded = self.load_order
        order = [loaded[0], *reversed(loaded[1:])]
        self.link_order = order
        p = 0
        for u in reversed(order):
            for s in u.globals:
                if s.kind == 'typedconst':
                    p = p + 1 & ~1
                    s.offset = p
                    p += s.type.size
        self.typed_end = p
        self.runtime_start = p + 1 & ~1
        self.runtime_symbols = {}
        runtime_decl = [('OvrCodeList', 2), ('OvrHeapSize', 2), ('OvrDebugPtr', 4), ('OvrHeapOrg',
             2), ('OvrHeapPtr', 2), ('OvrHeapEnd', 2), ('OvrLoadList', 2), ('OvrDosHandle', 2), ('OvrEmsHandle',
             2), ('HeapOrg', 4), ('HeapPtr', 4), ('FreePtr', 4), ('FreeMin', 2), ('HeapError', 4),
             ('ExitProc', 4), ('ExitCode', 2), ('ErrorAddr', 4), ('PrefixSeg', 2), ('StackLimit', 2),
             ('InOutRes', 2), ('RandSeed', 4), ('FileMode', 1), ('Test8087', 1)]
        rp = self.runtime_start
        for (n, size) in runtime_decl:
            self.runtime_symbols[n] = {'offset': rp, 'size': size}
            rp += size
        p = self.runtime_start + 60
        for u in order:
            if u.name.lower() == 'crt':
                p = p + 1 & ~1
                for (n, size) in [('CheckBreak', 1), ('CheckEOF', 1), ('DirectVideo', 1),
                     ('CheckSnow', 1), ('LastMode', 2), ('TextAttr', 1), ('CrtTextPad', 1), ('WindMin', 2),
                     ('WindMax', 2), ('CrtPrivate', 8)]:
                    self.runtime_symbols[n] = {'offset': p, 'size': size}
                    p += size
            for s in u.globals:
                if s.kind == 'global':
                    if s.value is not None:
                        continue
                    if s.type.size > 1:
                        p = p + 1 & ~1
                    s.offset = p
                    p += s.type.size
        p = p + 1 & ~1
        for (n, size) in [('Input', 256), ('Output', 256), *[(f'SaveInt{n:02X}', 4) for n in (0,
             2, 27, 35, 36, *range(52, 64), 117)]]:
            self.runtime_symbols[n] = {'offset': p, 'size': size}
            p += size
        self.ds_size = p

class Parser:

    def __init__(self, c, u, tokens):
        (self.c, self.u, self.tokens, self.i) = (c, u, tokens, 0)
        self.scope = u.scope
        self.booleval = False

    def skipdirectives(self):
        while self.tokens[self.i].kind == 'directive':
            d = self.tokens[self.i].text.upper()
            if 'B+' in d:
                self.booleval = True
            if 'B-' in d:
                self.booleval = False
            self.i += 1

    def peek(self):
        self.skipdirectives()
        return self.tokens[self.i].value

    def take(self):
        self.skipdirectives()
        t = self.tokens[self.i]
        self.i += 1
        return t

    def accept(self, x):
        if self.peek() == x:
            return self.take()

    def expect(self, x):
        t = self.take()
        if t.value != x:
            t.error(f'expected {x}, got {t.text}')
        return t

    def ident(self):
        t = self.take()
        if t.kind != 'id':
            t.error(f'expected identifier, got {t.text}')
        return t

    def names(self):
        a = [self.ident()]
        while self.accept(','):
            a.append(self.ident())
        return a

    def parse(self):
        t = self.take()
        if t.value not in ('unit', 'program'):
            t.error('expected unit or program')
        self.u.program = t.value == 'program'
        self.u.name = self.ident().text
        if self.accept('('):
            self.names()
            self.expect(')')
        self.expect(';')
        if not self.u.program:
            self.expect('interface')
        self.declarations(interface=not self.u.program)
        if not self.u.program:
            self.expect('implementation')
            self.u.scope = Scope(self.u.name, self.u.interface)
            self.scope = self.u.scope
            self.declarations()
        if self.accept('begin'):
            self.u.init = self.block_tail()
        else:
            self.expect('end')
            self.u.init = Stmt('block')
        self.expect('.')
        self.expect('<eof>')

    def declarations(self, interface=False, routine=None):
        while True:
            k = self.peek()
            if k == 'uses':
                self.take()
                for n in self.names():
                    self.scope.imports.append(self.c.load(n.text))
                self.expect(';')
            elif k == 'const':
                self.take()
                while self.tokens[self.i].kind == 'id' and self.peek() not in ('type',
                     'var', 'procedure', 'function', 'begin', 'implementation'):
                    n = self.ident()
                    if self.accept(':'):
                        ty = self.type()
                        self.expect('=')
                        value = self.initializer(ty)
                        s = self.scope.add(Symbol(n.text, 'typedconst', ty, value, token=n))
                        if routine:
                            n.error('local typed constants are not implemented')
                        self.u.globals.append(s)
                    else:
                        self.expect('=')
                        e = self.expr()
                        value = self.constant(e)
                        self.scope.add(Symbol(n.text, 'const', self.consttype(value), value, token=n))
                    self.expect(';')
            elif k == 'type':
                self.take()
                while self.tokens[self.i].kind == 'id' and self.peek() not in ('const',
                     'var', 'procedure', 'function', 'begin', 'implementation'):
                    n = self.ident()
                    self.expect('=')
                    ty = self.type(n.text)
                    self.scope.add(Symbol(n.text, 'type', ty, token=n))
                    self.expect(';')
            elif k == 'var':
                self.take()
                while self.tokens[self.i].kind == 'id' and self.peek() not in ('const',
                     'type', 'procedure', 'function', 'begin', 'implementation'):
                    ns = self.names()
                    self.expect(':')
                    ty = self.type()
                    absolute = self.expr() if self.accept('absolute') else None
                    for n in ns:
                        s = self.scope.add(Symbol(n.text, 'local' if routine else 'global',
                             ty, absolute, token=n))
                        (routine.locals if routine else self.u.globals).append(s)
                    self.expect(';')
            elif k in ('procedure', 'function'):
                self.routine(interface, routine)
            else:
                break

    def routine(self, interface, parent):
        fun = self.take().value == 'function'
        n = self.ident()
        previous = self.scope.find(n.text)
        (params, explicit) = ([], False)
        if self.accept('('):
            explicit = True
            if self.peek() != ')':
                while True:
                    ref = bool(self.accept('var'))
                    ns = self.names()
                    ty = self.type() if self.accept(':') else UNTYPED
                    for p in ns:
                        params.append(Symbol(p.text, 'param', ty, token=p, byref=ref))
                    if not self.accept(';'):
                        break
            self.expect(')')
        ty = self.type() if fun and self.accept(':') else VOID
        self.expect(';')
        if previous and previous.kind == 'routine' and (previous.scope in (self.scope,
             self.u.interface)):
            r = previous
            if explicit:
                r.params = params
            if ty is not VOID:
                r.type = ty
        else:
            r = self.scope.add(Symbol(n.text, 'routine', ty, token=n, params=params))
            (parent.nested if parent else self.u.routines).append(r)
        if self.accept('interrupt'):
            r.interrupt = True
            self.expect(';')
        if self.accept('external'):
            r.external = True
            self.expect(';')
            return
        if self.accept('forward'):
            return self.expect(';')
        if interface:
            return
        r.implementation_token = n
        old = self.scope
        rs = Scope(n.text, old)
        rs.routine = r
        self.scope = rs
        for p in r.params:
            rs.add(p)
        self.declarations(routine=r)
        self.expect('begin')
        r.body = self.block_tail()
        self.expect(';')
        r.body_scope = rs
        self.scope = old

    def type(self, name=''):
        packed = bool(self.accept('packed'))
        k = self.peek()
        if k == '^':
            self.take()
            n = self.ident()
            s = self.scope.find(n.text)
            if not s or s.kind != 'type':
                n.error(f'unresolved pointer target {n.text}')
            return self.c.addtype(Type('pointer', name, 4, elem=s.type, cname='farptr'))
        if k == 'array':
            self.take()
            self.expect('[')
            bounds = []
            while True:
                lo = self.constant(self.expr())
                if self.accept('..'):
                    hi = self.constant(self.expr())
                else:
                    self.tokens[self.i - 1].error('array index requires bounds')
                if isinstance(lo, bytes):
                    lo = lo[0]
                if isinstance(hi, bytes):
                    hi = hi[0]
                bounds.append((lo, hi))
                if not self.accept(','):
                    break
            self.expect(']')
            self.expect('of')
            elem = self.type()
            size = elem.size
            for (lo, hi) in bounds:
                size *= hi - lo + 1
            return self.c.addtype(Type('array', name, size, elem=elem, bounds=bounds), name)
        if k == 'record':
            self.take()
            t = Type('record', name)
            offset = 0
            while self.peek() not in ('end', 'case'):
                ns = self.names()
                self.expect(':')
                ty = self.type()
                for n in ns:
                    t.fields[n.value] = (n.text, ty, offset)
                    offset += ty.size
                if not self.accept(';') and self.peek() not in ('end', 'case'):
                    self.expect(';')
            if self.accept('case'):
                tag = self.ident()
                if self.accept(':'):
                    ty = self.type()
                    t.fields[tag.value] = (tag.text, ty, offset)
                    offset += ty.size
                else:
                    s = self.scope.find(tag.text)
                    if not s or s.kind != 'type':
                        tag.error('variant tag type is unknown')
                self.expect('of')
                high = offset
                while self.peek() != 'end':
                    self.expr()
                    while self.accept(','):
                        self.expr()
                    self.expect(':')
                    self.expect('(')
                    fields = {}
                    cur = offset
                    while self.peek() != ')':
                        ns = self.names()
                        self.expect(':')
                        ty = self.type()
                        for n in ns:
                            fields[n.value] = (n.text, ty, cur)
                            t.fields[n.value] = (n.text, ty, cur)
                            cur += ty.size
                        if not self.accept(';'):
                            break
                    self.expect(')')
                    self.accept(';')
                    t.variants.append(fields)
                    high = max(high, cur)
                offset = high
            self.expect('end')
            t.size = offset
            return self.c.addtype(t, name)
        if k == 'set':
            self.take()
            self.expect('of')
            elem = self.type()
            if elem.lo < 0 or elem.hi > 255:
                self.tokens[self.i - 1].error('set base must fit 0..255')
            (lo, hi) = (elem.lo // 8, elem.hi // 8)
            return self.c.addtype(Type('set', name, hi - lo + 1, lo=lo * 8, hi=hi * 8 + 7,
                 elem=elem), name)
        if k in ('file', 'text', 'string'):
            n = self.take()
            if k == 'text':
                return TEXT
            if k == 'file':
                return Type('file', name, 128, elem=self.type(), cname='tp_file') if self.accept('of') else FILE
            if self.accept('['):
                length = self.constant(self.expr())
                self.expect(']')
                if not 0 <= length <= 255:
                    n.error('invalid string length')
                return self.c.addtype(Type('string', name, length + 1), name)
            return STRING
        if k == '(':
            self.take()
            ns = self.names()
            self.expect(')')
            t = Type('ordinal', name, 1, False, 0, len(ns) - 1, cname='uint8_t')
            for (i, n) in enumerate(ns):
                self.scope.add(Symbol(n.text, 'const', t, i, token=n))
            return t
        t = self.tokens[self.i]
        if t.kind == 'id':
            s = self.scope.find(t.text)
            if s and s.kind == 'type':
                self.take()
                return s.type
        lo = self.constant(self.expr())
        self.expect('..')
        hi = self.constant(self.expr())
        if isinstance(lo, bytes):
            lo = lo[0]
        if isinstance(hi, bytes):
            hi = hi[0]
        ty = BYTE if lo >= 0 and hi <= 255 else SHORT if lo >= -128 and hi <= 127 else INTEGER if hi <= 32767 else WORD
        return Type('ordinal', name, ty.size, ty.signed, lo, hi, cname=ty.cname)

    def initializer(self, t):
        if t.kind == 'record':
            self.expect('(')
            result = {}
            while True:
                n = self.ident()
                self.expect(':')
                if n.value not in t.fields:
                    n.error('unknown initializer field')
                result[n.value] = self.initializer(t.fields[n.value][1])
                if not self.accept(';'):
                    break
            self.expect(')')
            return result
        if t.kind == 'array' and self.peek() == '(':
            self.take()
            values = []
            while True:
                child = t.elem if len(t.bounds) == 1 else Type('array', elem=t.elem, bounds=t.bounds[1:])
                values.append(self.initializer(child))
                if not self.accept(','):
                    break
            self.expect(')')
            return values
        return self.constant(self.expr())

    def block_tail(self):
        out = []
        while self.peek() != 'end':
            out.append(self.statement())
            if not self.accept(';') and self.peek() != 'end':
                self.tokens[self.i].error('expected statement separator')
        end = self.expect('end')
        result = Stmt('block', out)
        result.end_line = end.line
        return result

    def statement(self):
        t = self.tokens[self.i]
        k = self.peek()
        if self.accept('begin'):
            return self.block_tail()
        if self.accept('if'):
            e = self.expr()
            self.expect('then')
            yes = self.statement()
            no = self.statement() if self.accept('else') else Stmt('block')
            return Stmt('if', [e, yes, no], t)
        if self.accept('while'):
            e = self.expr()
            self.expect('do')
            return Stmt('while', [e, self.statement()], t)
        if self.accept('repeat'):
            body = []
            while self.peek() != 'until':
                body.append(self.statement())
                if not self.accept(';') and self.peek() != 'until':
                    self.tokens[self.i].error('expected ; or until')
            self.take()
            return Stmt('repeat', [Stmt('block', body), self.expr()], t)
        if self.accept('for'):
            v = self.primary()
            self.expect(':=')
            first = self.expr()
            direction = self.take()
            if direction.value not in ('to', 'downto'):
                direction.error('expected to or downto')
            last = self.expr()
            self.expect('do')
            return Stmt('for', [v, first, last, direction.value, self.statement()], t)
        if self.accept('case'):
            e = self.expr()
            self.expect('of')
            branches = []
            otherwise = Stmt('block')
            while self.peek() != 'end':
                if self.accept('else'):
                    body = []
                    while self.peek() != 'end':
                        body.append(self.statement())
                        if not self.accept(';'):
                            break
                    otherwise = Stmt('block', body)
                    break
                labels = []
                while True:
                    lo = self.expr()
                    hi = self.expr() if self.accept('..') else lo
                    labels.append((lo, hi))
                    if not self.accept(','):
                        break
                self.expect(':')
                branches.append((labels, self.statement()))
                self.accept(';')
            self.expect('end')
            return Stmt('case', [e, branches, otherwise], t)
        if self.accept('with'):
            es = [self.expr()]
            while self.accept(','):
                es.append(self.expr())
            self.expect('do')
            return Stmt('with', [es, self.statement()], t)
        if self.accept('inline'):
            self.expect('(')
            ts = []
            depth = 1
            while depth:
                x = self.take()
                if x.value == '<eof>':
                    x.error('unclosed inline')
                if x.value == '(':
                    depth += 1
                if x.value == ')':
                    depth -= 1
                if depth:
                    ts.append(x)
            return Stmt('inline', [ts], t)
        if k in (';', 'end', 'else', 'until'):
            return Stmt('block')
        if k in ('goto', 'asm', 'label'):
            t.error(f'unsupported construct {k}')
        e = self.expr()
        if self.accept(':='):
            return Stmt('assign', [e, self.expr()], t)
        return Stmt('call', [e], t)
    PRECEDENCE = {'=': 1, '<>': 1, '<': 1, '>': 1, '<=': 1, '>=': 1, 'in': 1, '+': 2, '-': 2,
         'or': 2, 'xor': 2, '*': 3, '/': 3, 'div': 3, 'mod': 3, 'and': 3, 'shl': 3, 'shr': 3}

    def expr(self, minp=0):
        left = self.primary()
        while self.peek() in self.PRECEDENCE and self.PRECEDENCE[self.peek()] >= minp:
            op = self.take()
            right = self.expr(self.PRECEDENCE[op.value] + 1)
            left = Expr(op.value, [left, right], op, value=self.booleval)
        return left

    def primary(self):
        t = self.take()
        k = t.value
        if k in ('+', '-', 'not', '@'):
            e = Expr('unary' + k, [self.primary()], t)
        elif k == '(':
            e = self.expr()
            self.expect(')')
        elif k == '[':
            es = []
            if self.peek() != ']':
                while True:
                    lo = self.expr()
                    hi = self.expr() if self.accept('..') else lo
                    es.append((lo, hi))
                    if not self.accept(','):
                        break
            self.expect(']')
            e = Expr('set', es, t, type=SET)
        elif t.kind == 'number':
            e = Expr('literal', token=t, type=self.consttype(k), value=k)
        elif t.kind == 'string' or k == '#':
            data = b''
            while True:
                if t.kind == 'string':
                    data += t.value
                else:
                    n = self.take()
                    if n.kind != 'number' or not 0 <= n.value <= 255:
                        n.error('invalid character constant')
                    data += bytes([n.value])
                if self.peek() == '#' or self.tokens[self.i].kind == 'string':
                    t = self.take()
                else:
                    break
            e = Expr('literal', token=t, type=CHAR if len(data) == 1 else STRING, value=data)
        elif t.kind == 'id':
            e = Expr('name', token=t, value=t.text, sym=self.scope.find(t.text))
            if self.accept('('):
                args = []
                if self.peek() != ')':
                    while True:
                        a = self.expr()
                        if self.accept(':'):
                            width = self.expr()
                            precision = self.expr() if self.accept(':') else None
                            a = Expr('format', [a, width, precision], t)
                        args.append(a)
                        if not self.accept(','):
                            break
                self.expect(')')
                e = Expr('call', [e, *args], t)
        else:
            t.error(f'expected expression, got {t.text}')
        while True:
            if self.accept('^'):
                e = Expr('deref', [e], t)
            elif self.accept('.'):
                n = self.ident()
                e = Expr('field', [e], n, value=n.text)
            elif self.accept('['):
                es = []
                while True:
                    es.append(self.expr())
                    if not (self.accept(',') or self.accept(':')):
                        break
                self.expect(']')
                e = Expr('index', [e, *es], t)
            else:
                break
        return e

    @staticmethod
    def consttype(v):
        if isinstance(v, bytes):
            return CHAR if len(v) == 1 else STRING
        return INTEGER if -32768 <= v <= 32767 else WORD if 0 <= v <= 65535 else LONG

    def constant(self, e):
        if e.op == 'literal':
            return e.value
        if e.op == 'name' and e.sym and (e.sym.kind == 'const'):
            return e.sym.value
        if e.op in ('unary+', 'unary-', 'unarynot'):
            v = self.constant(e.args[0])
            return v if e.op == 'unary+' else -v if e.op == 'unary-' else ~v
        if e.op in self.PRECEDENCE:
            (a, b) = map(self.constant, e.args)
            fs = {'+': lambda : a + b, '-': lambda : a - b, '*': lambda : a * b, 'div': lambda : int(a / b),
                 'mod': lambda : a - int(a / b) * b, 'shl': lambda : a << b, 'shr': lambda : a >> b, 'and': lambda : a & b,
                 'or': lambda : a | b, 'xor': lambda : a ^ b}
            if e.op in fs:
                return fs[e.op]()
        e.token.error('constant expression required')

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--episode', choices=('sam1', 'sam2', 'sam3'), required=True)
    ap.add_argument('--source-dir', type=Path, default=Path('game'))
    ap.add_argument('--program', default='SAM')
    ap.add_argument('--output-dir', '--out', type=Path, required=True)
    ap.add_argument('--parse-only', action='store_true')
    ap.add_argument('--placement', type=Path, default=Path(__file__).resolve().parents[1] / 'config/port.json',
         help='committed episode placement metadata; no DOS build needed')
    a = ap.parse_args()
    try:
        c = Compiler(a.source_dir, a.episode)
        c.load(a.program)
        c.bind()
        if a.program.upper() == 'SAM':
            c.program_layout = placement_layout(a.placement, a.episode)
        a.output_dir.mkdir(parents=True, exist_ok=True)
        info = {'episode': a.episode, 'ds_size': c.ds_size, 'typed_end': c.typed_end, 'runtime_symbols': c.runtime_symbols,
             'globals': {s.name: {'offset': s.offset, 'size': s.type.size, 'unit': u.name} for u in c.units.values() for s in u.globals},
             'types': {s.name: s.type.size for u in c.units.values() for scope in (u.interface, u.scope) for s in scope.symbols.values() if s.kind == 'type'}}
        (a.output_dir / 'layout.json').write_text(json.dumps(info, indent=2, sort_keys=True) + '\n')
        if not a.parse_only:
            from pas2c_emit import Emitter
            Emitter(c).write(a.output_dir)
        print(f'{a.episode}: parsed {len(c.units)} modules, {sum((len(u.routines) for u in c.units.values()))} routines, {c.ds_size} DS bytes')
        return 0
    except CompileError as e:
        print(e, file=sys.stderr)
        return 1

def memory_layout(map_path):
    """Check-only reconstruction of placement from a pinned TP MAP.

    Normal translation reads config/port.json, not the reference build.
    """
    text = map_path.read_text(encoding='latin1')
    values = {}
    for (start, stop, length, name, kind) in re.findall('^\\s+([0-9A-F]+)H\\s+([0-9A-F]+)H\\s+([0-9A-F]+)H\\s+(\\w+)\\s+(\\w+)\\s*$',
         text, re.M):
        if name in ('DATA', 'STACK', 'HEAP'):
            values[name] = (int(start, 16), int(length, 16))
    if set(values) != set(('DATA', 'STACK', 'HEAP')):
        raise CompileError(f'{map_path}: missing DATA/STACK/HEAP segments')
    load = 2048 + 16
    return (2048, load + values['DATA'][0] // 16, load + values['STACK'][0] // 16, values['STACK'][1],
         load + values['HEAP'][0] // 16, 40960)
PLACEMENT_FIELDS = ('psp_seg', 'ds_seg', 'ss_seg', 'sp', 'heap_org_seg', 'mem_top_seg')

def placement_layout(path, episode):
    """Read the six pc_program words without importing DOS tooling."""
    try:
        document = json.loads(path.read_text(encoding='utf-8'))
        if document['schema_version'] != 1:
            raise ValueError('unknown schema version')
        values = document['episodes'][episode]
        layout = tuple((values[name] for name in PLACEMENT_FIELDS))
        if any((type(value) is not int or not 0 <= value <= 65535 for value in layout)):
            raise ValueError('placement fields must be unsigned 16-bit integers')
        return layout
    except (OSError, ValueError, KeyError) as error:
        raise CompileError(f'{path}: invalid {episode} placement: {error}') from error
if __name__ == '__main__':
    sys.modules['pas2c'] = sys.modules[__name__]
    sys.exit(main())
