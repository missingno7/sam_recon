"""TP5 evaluation scheduling, measured by ORDER/ORDTYPES/ORDSTR/ORDAGG.

This pass adds local temporaries; it does not change the generated-code ABI.
Numeric register expressions prioritize calls (right operand first when both
contain calls), while address operands are consumed after that calculation.
Argument pushing, string/set operators and constructors are separate rules.
"""
from pas2c import Expr, Type, VOID, STRING, SET, BOOL
PURE = {'length', 'copy', 'pos', 'concat', 'ord', 'chr', 'lo', 'hi', 'succ', 'pred', 'sizeof',
     'abs', 'sqr', 'odd', 'ptr', 'seg', 'ofs', 'cseg', 'dseg', 'sseg', 'upcase'}
INLINE = PURE - {'copy', 'pos', 'concat'}

class Order:

    def __init__(self, emitter, root, context):
        self.e = emitter
        self.root = root
        self.context = context
        self.values = {}
        self.strings = {}
        self.hosts = {}
        self.fars = {}
        self.lines = []
        self.steps = []
        self.rules = []

    def children(self, x):
        if x.op == 'set':
            return [a for pair in x.args for a in pair]
        return [a for a in x.args if isinstance(a, Expr)]

    def callable(self, x):
        if x.op == 'call':
            return x.args[0].sym
        if x.op == 'name' and x.sym and (x.sym.kind in ('routine', 'builtin')) and (x.sym is not self.e.routine):
            return x.sym
        return None

    def effects(self, x):
        self.e.type(x)
        s = self.callable(x)
        own = int(bool(s and (s.kind == 'routine' or (s.kind == 'builtin' and s.name.lower() not in PURE))))
        if x.op == 'index' and x.args[0].op == 'name' and (x.args[0].sym.kind == 'special'):
            own = 1
        if x.op == 'unary@':
            return 0
        return own + sum((self.effects(a) for a in self.children(x) if not (x.op == 'call' and a is x.args[0])))

    def calls(self, x):
        self.e.type(x)
        s = self.callable(x)
        own = int(bool(s and (s.kind == 'routine' or (s.kind == 'builtin' and s.name.lower() not in INLINE))))
        if x.op == 'unary@':
            return 0
        return own + sum((self.calls(a) for a in self.children(x) if not (x.op == 'call' and a is x.args[0])))

    def constant(self, x):
        self.e.type(x)
        if x.op == 'literal' or (x.op == 'name' and x.sym.kind in ('const', 'type')):
            return True
        return self.e.constvalue(x) is not None

    def addressable(self, x):
        return x.op in ('name', 'index', 'field', 'deref', 'selected') and (not (x.op == 'name' and x.sym.kind in ('const',
             'routine', 'builtin', 'type')))

    def rule(self, text):
        if text not in self.rules:
            self.rules.append(text)

    def code(self, x, mode):
        return {'value': self.e.expr, 'string': self.e.string, 'host': self.e.address,
             'far': self.e.faraddress}[mode](x)

    def capture(self, x, mode='value', force=False):
        table = {'value': self.values, 'string': self.strings, 'host': self.hosts, 'far': self.fars}[mode]
        if id(x) in table:
            return table[id(x)]
        if self.constant(x) and mode in ('value', 'string') and (not force):
            return self.code(x, mode)
        t = self.e.type(x)
        code = self.code(x, mode)
        name = self.e.unique('eval_')
        ct = 'tp_string' if mode == 'string' else 'uint8_t *' if mode == 'host' else 'farptr' if mode == 'far' else 'tp_set' if t.kind == 'set' else t.cname
        if ct == 'void':
            return code
        if mode == 'host':
            code = '(uint8_t *)(' + code + ')'
        self.lines.append(f'{ct} {name} = {code};')
        table[id(x)] = name
        if mode == 'string':
            self.values[id(x)] = name if t.kind == 'string' else f'{name}.b[1]'
        self.steps.append({'expression': self.e.pascal_expr(x), 'kind': mode, 'temporary': name})
        return name

    def borrow(self, x, kind):
        """Strings/arrays push a selected address; their callee copies later."""
        if self.addressable(x) and (kind != 'string' or self.e.type(x).kind == 'string'):
            self.lower(x, 'host')
            host = self.capture(x, 'host')
            if kind == 'string':
                self.strings[id(x)] = f'tp_Sfrom({host})'
            else:
                self.values[id(x)] = f'(*({self.e.type(x).cname} *)({host}))'
        else:
            self.lower(x, 'string' if kind == 'string' else 'value')
            self.capture(x, 'string' if kind == 'string' else 'value')

    def argmodes(self, x):
        s = self.callable(x)
        args = x.args[1:] if x.op == 'call' else []
        if s.kind == 'type':
            return ['host' if s.type.kind in ('record', 'array', 'file', 'text') else 'value']
        if s.kind == 'routine':
            return ['far' if s.external and p.byref else 'host' if p.byref else 'borrow-string' if p.type.kind == 'string' else 'borrow-array' if p.type.kind == 'array' else 'value' for p in s.params]
        n = s.name.lower()
        modes = ['value'] * len(args)
        address_args = {'fillchar': (0,), 'move': (0, 1), 'getmem': (0,), 'new': (0,),
             'mark': (0,), 'str': (1,), 'val': (1, 2), 'insert': (1,), 'delete': (0,), 'assign': (0,
            ), 'reset': (0,), 'rewrite': (0,), 'close': (0,), 'erase': (0,), 'seek': (0,), 'filesize': (0,
            ), 'filepos': (0,), 'eof': (0,), 'eoln': (0,), 'read': tuple(range(len(args))), 'getintvec': (1,
            ), 'intr': (1,), 'msdos': (0,), 'seg': (0,), 'ofs': (0,)}.get(n, ())
        for j in address_args:
            if j < len(modes):
                modes[j] = 'host'
        for j in {'length': (0,), 'copy': (0,), 'pos': (0, 1), 'concat': tuple(range(len(args))),
             'insert': (0,), 'val': (0,), 'assign': (1,)}.get(n, ()):
            if j < len(modes):
                modes[j] = 'borrow-string'
        if n == 'sizeof':
            return ['none'] * len(args)
        if n == 'write' and args and (self.e.type(args[0]).kind == 'file'):
            modes = ['host', 'host']
        return modes

    def lower_call(self, x):
        s = self.callable(x)
        args = x.args[1:] if x.op == 'call' else []
        if not args:
            return
        if s.kind == 'builtin' and s.name.lower() in ('inc', 'dec'):
            target = args[0]
            if len(args) > 1:
                amount = args[1]
                self.lower(amount)
                if self.effects(amount) or self.effects(target):
                    self.capture(amount)
            self.lower(target, 'host')
            if self.effects(target):
                self.capture(target, 'host')
            if self.effects(target) or (len(args) > 1 and self.effects(args[1])):
                self.rule('Inc/Dec amount before destination selection; destination selected once and then read/updated')
            return
        modes = self.argmodes(x)
        # Argument conflicts include early scalar reads/addresses that a later
        # function changes, and late reads following an earlier function.
        conflict = any((self.effects(a) for a in args)) and sum((not self.constant(a) for a in args)) > 1
        if conflict:
            self.rule('arguments left-to-right; string/array addresses early, contents copied at call')
        for (a, mode) in zip(args, modes):
            if mode == 'none':
                continue
            if mode.startswith('borrow-'):
                if conflict:
                    self.borrow(a, mode[7:])
                else:
                    self.lower(a, 'string' if mode == 'borrow-string' else 'value')
            else:
                # Far external var arguments may be address-taken host locals.
                actual = 'far' if mode == 'far' and self.e.faraddress(a) else 'host' if mode == 'far' else mode
                self.lower(a, actual)
                if conflict:
                    self.capture(a, actual)

    def lower(self, x, mode='value'):
        self.e.type(x)
        op = x.op
        if op in ('literal', 'selected'):
            return
        if op == 'name':
            return
        if op == 'call':
            self.lower_call(x)
            return
        if op == 'format':
            args = [a for a in x.args if a is not None]
            conflict = any((self.effects(a) for a in args)) and len(args) > 1
            if conflict:
                self.rule('formatted value before field width')
            first = args[0]
            if self.e.type(first).kind == 'string' and conflict:
                self.borrow(first, 'string')
            else:
                self.lower(first)
                if conflict:
                    self.capture(first)
            for a in args[1:]:
                self.lower(a)
                if conflict:
                    self.capture(a)
            return
        if op == 'index':
            indices = x.args[1:]

            def pointer_base(a):
                return a.op == 'deref' or (a.op in ('index', 'field') and pointer_base(a.args[0]))
            conflict = any((self.effects(a) for a in indices)) and (sum((not self.constant(a) for a in indices)) > 1 or pointer_base(x.args[0]))
            memory = x.args[0].op == 'name' and x.args[0].sym.kind == 'special' and (x.args[0].sym.name.lower() in ('mem',
                 'memw'))
            if conflict:
                self.rule('Mem segment before offset' if memory else 'array indices right-to-left, then base pointer')
            for a in indices if memory else reversed(indices):
                self.lower(a)
                if conflict:
                    self.capture(a)
            self.lower(x.args[0], 'host')
            return
        if op in ('field', 'deref'):
            self.lower(x.args[0], 'value' if op == 'deref' else 'host')
            return
        if op.startswith('unary'):
            if op != 'unary@':
                self.lower(x.args[0])
            else:
                self.lower(x.args[0], 'host')
            return
        if op == 'set':
            conflict = any((self.effects(a) for pair in x.args for a in pair))
            if conflict:
                self.rule('set items left-to-right; range lower bound before upper; singleton once')
            for (lo, hi) in x.args:
                self.lower(lo)
                if conflict:
                    self.capture(lo)
                if hi is not lo:
                    self.lower(hi)
                    if conflict:
                        self.capture(hi)
            return
        (a, b) = x.args
        t = self.e.type(x)
        (at, bt) = (self.e.type(a), self.e.type(b))
        if t.kind == 'bool' and op in ('and', 'or') and (not x.value):
            if self.effects(a) and self.effects(b):
                self.rule('$B- left-to-right, guarded RHS')
            self.lower(a)
            before = len(self.lines)
            self.lower(b)
            right = self.lines[before:]
            del self.lines[before:]
            if right:
                self.rule('$B- left-to-right, guarded RHS')
                name = self.e.unique('bool_')
                self.lines.append(f'uint8_t {name} = {self.e.expr(a)};')
                self.lines.append(f"if ({('!' if op == 'or' else '')}{name}) {{")
                self.lines.extend(('    ' + s for s in right))
                self.lines.append(f'    {name} = {self.e.expr(b)};')
                self.lines.append('}')
                self.values[id(x)] = name
            return
        strings = at.kind == 'string' or bt.kind == 'string' or (at.kind == bt.kind == 'char' and op == '+')
        ordered_lr = strings or at.kind == bt.kind == 'set' or op == 'in'
        conflict = self.effects(a) + self.effects(b) > 0 and (not (self.constant(a) or self.constant(b)))
        # Set membership cannot reverse the scalar/set operands as the C helper
        # argument order does; constructors themselves may also contain calls.
        if op == 'in' and (self.effects(a) or self.effects(b)):
            conflict = True
        order = [a, b] if ordered_lr else [b, a] if self.calls(b) else [a, b]
        if conflict:
            self.rule('string/set/membership operands left-to-right' if ordered_lr else 'numeric call-containing operands first; right before left if both contain calls; ordinary loads deferred')
        for child in order:
            childmode = 'string' if strings else 'value'
            self.lower(child, childmode)
            if conflict:
                self.capture(child, childmode)

    def assignment(self, lhs, rhs):
        # Every tested assignment type calculates RHS before the destination.
        self.lower(rhs, 'string' if self.e.type(lhs).kind == 'string' else 'value')
        lhs_effects = self.effects(lhs)

        def dynamic(x):
            if x.op == 'deref':
                return True
            if x.op == 'index':
                return any((not self.constant(a) for a in x.args[1:])) or dynamic(x.args[0])
            if x.op == 'field':
                return dynamic(x.args[0])
            return False
        if lhs_effects or (self.effects(rhs) and dynamic(lhs)):
            self.rule('assignment RHS before destination address/indices')
            self.capture(rhs, 'string' if self.e.type(lhs).kind == 'string' else 'host' if self.e.type(lhs).kind in ('array',
                 'record') else 'value')
        self.lower(lhs, 'host')

    def finish(self):
        if self.rules or self.steps:
            self.e.order_notes.append({'file': self.root.token.file, 'line': self.root.token.line,
                 'routine': self.e.routine.cname if self.e.routine else 'initialization', 'context': self.context,
                 'expression': self.e.pascal_expr(self.root), 'rules': self.rules, 'evaluation': self.steps})
