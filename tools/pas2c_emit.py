"""Type checking and deterministic C emission; no game routine substitutions."""
from pas2c import *
import struct

class Emitter:

    def __init__(self, c):
        self.c = c
        self.routine = None
        self.withs = []
        self.counter = 0
        self.notes = []
        self.order_notes = []
        self.order = None
        self.array_accesses = {}
        self.frame_needed = False
        self.emitted_comments = set()
        self.comment_range = None

    def comments_before(self, file, line):
        """Keep active Pascal prose near the statement it describes."""
        out = []
        for comment in self.c.comments.get(file, []):
            key = (file, comment.line)
            if key in self.emitted_comments or comment.line >= line:
                continue
            if self.comment_range and (not self.comment_range[0] <= comment.line <= self.comment_range[1]):
                continue
            out.append('/* ' + comment.text.replace('*/', '* /') + ' */')
            self.emitted_comments.add(key)
        return out

    def global_far_name(self, s):
        """Keep absolute DS offsets in declarations, never in routine bodies."""
        return (self.c.prefix + s.cname if s.kind == 'runtimevar' else s.cname) + '_fp'

    def array_helper(self, e):
        t = self.type(e.args[0])
        count = len(e.args) - 1
        result = self.type(e)
        name = t.cname + '_at' + str(count)
        self.array_accesses[name] = (t, count, result)
        return name

    def global_array_name(self, e, suffix='at'):
        t = self.type(e.args[0])
        count = len(e.args) - 1
        tail = str(count) if len(t.bounds) > 1 else ''
        return e.args[0].sym.cname + '_' + suffix + tail

    def field_helper(self, t, field):
        return self.c.prefix + t.cname + '_' + field if t.cname == 'tp_registers' else t.cname + '_' + field

    def fixed_record(self, e):
        """Direct C fields are safe for host locals and fixed DS records.

        Dynamic far addresses instead use field accessors: adding a field
        offset must wrap at 64 KiB, even when the selected record straddles it.
        """
        if self.order and (id(e) in self.order.hosts or id(e) in self.order.fars):
            return False
        if e.op == 'name':
            return True
        if e.op == 'index' and e.args[0].op == 'name' and (e.args[0].sym.kind in ('global',
             'typedconst')):
            values = [self.constvalue(a) for a in e.args[1:]]
            if all((v is not None for v in values)):
                offset = e.args[0].sym.offset + int(self.indexoffset(e)) & 65535
                return offset + self.type(e).size <= 65536
        return not self.faraddress(e)

    def integer_operand(self, e, code, wide=False):
        """C promotions already represent narrow TP operands exactly.

        Widen to unsigned only where 32-bit overflow must be defined, or a
        Word product can exceed INT_MAX. Signed result truncation stays explicit.
        """
        if wide and (not re.fullmatch('\\d+', code)):
            return f'(uint32_t)({code})'
        if wide and re.fullmatch('\\d+', code) and (int(code) > 2147483647):
            return code + 'u'
        return code

    def local_far(self, e):
        self.frame_needed = True
        return f'tp_LocalFar({self.address(e)}, {self.type(e).size})'

    def file_address(self, e):
        address = self.address(e)
        return address if self.type(e).kind == 'file' else f'(tp_file *)({address})'

    def pascal_expr(self, e):
        if e.op == 'name':
            return e.value or e.sym.name
        if e.op == 'literal':
            return repr(e.value.decode('latin1')) if isinstance(e.value, bytes) else str(e.value)
        if e.op == 'call':
            return self.pascal_expr(e.args[0]) + '(' + ', '.join((self.pascal_expr(a) for a in e.args[1:])) + ')'
        if e.op == 'field':
            return self.pascal_expr(e.args[0]) + '.' + e.value
        if e.op == 'index':
            return self.pascal_expr(e.args[0]) + '[' + ', '.join((self.pascal_expr(a) for a in e.args[1:])) + ']'
        if e.op == 'deref':
            return self.pascal_expr(e.args[0]) + '^'
        if e.op == 'selected':
            return '<selected record>'
        if e.op == 'set':
            return '[' + ', '.join((self.pascal_expr(lo) if lo is hi else self.pascal_expr(lo) + '..' + self.pascal_expr(hi) for (lo,
                 hi) in e.args)) + ']'
        if e.op == 'format':
            return ':'.join((self.pascal_expr(a) for a in e.args if a is not None))
        if e.op.startswith('unary'):
            return e.op[5:] + '(' + self.pascal_expr(e.args[0]) + ')'
        return '(' + (' ' + e.op + ' ').join((self.pascal_expr(a) for a in e.args)) + ')'

    def unique(self, stem):
        self.counter += 1
        return self.c.prefix + stem + str(self.counter)

    def analyze_locals(self, r):
        """Conservative definite-assignment analysis, with branch intersections.
        Addressing an output intrinsic's operand is not a value read. Partial
        aggregate writes remain conservative; every reported read has the same
        explicitly specified zero-local compatibility policy.
        """
        observations = []

        def root(e):
            while e.op in ('field', 'index', 'deref'):
                e = e.args[0]
            return e.sym if e.op == 'name' else None

        def read(e, written, address=False):
            if not isinstance(e, Expr):
                return
            if e.op == 'name':
                s = e.sym
                if s and s.kind == 'local' and (s.scope.routine is r) and (s not in written) and (not address):
                    observations.append({'routine': r.cname, 'name': s.name, 'file': e.token.file,
                         'line': e.token.line, 'policy': 'zero-initialized local'})
                return
            if e.op == 'set':
                for (lo, hi) in e.args:
                    read(lo, written)
                    read(hi, written)
                return
            if e.op == 'call':
                s = e.args[0].sym
                n = s.name.lower() if s else ''
                outputs = {'assign': (0,), 'getmem': (0,), 'new': (0,), 'mark': (0,), 'str': (1,
                    ), 'val': (1, 2), 'read': tuple(range(1, len(e.args) - 1)), 'readln': tuple(range(1, len(e.args) - 1)),
                     'fillchar': (0,), 'move': (1,), 'getintvec': (1,)}.get(n, ())
                for (i, a) in enumerate(e.args[1:]):
                    read(a, written, i in outputs)
                for i in outputs:
                    if i + 1 < len(e.args):
                        target = root(e.args[i + 1])
                        if target:
                            written.add(target)
                return
            for a in e.args:
                read(a, written, address and e.op == 'field')

        def walk(s, written):
            written = set(written)
            if s.op == 'block':
                for x in s.args:
                    written = walk(x, written)
            elif s.op == 'assign':
                (lhs, rhs) = s.args
                read(rhs, written)
                read(lhs, written, True)
                target = root(lhs)
                if target and lhs.op == 'name':
                    written.add(target)
            elif s.op == 'call':
                read(s.args[0], written)
            elif s.op == 'if':
                (e, y, n) = s.args
                read(e, written)
                written = walk(y, written) & walk(n, written)
            elif s.op == 'case':
                (e, branches, other) = s.args
                read(e, written)
                paths = [walk(body, written) for (_, body) in branches] + [walk(other, written)]
                written = set.intersection(*paths)
            elif s.op == 'for':
                (v, a, b, d, body) = s.args
                read(a, written)
                read(b, written)
                target = root(v)
                if target:
                    written.add(target)
                walk(body, written)
            elif s.op == 'while':
                read(s.args[0], written)
                walk(s.args[1], written)
            elif s.op == 'repeat':
                written = walk(s.args[0], written)
                read(s.args[1], written)
            elif s.op == 'with':
                written = walk(s.args[1], written)
            return written
        walk(r.body, set(r.params))
        unique = {(x['routine'], x['name'], x['line']): x for x in observations}
        self.notes.extend(unique.values())

    def fail(self, e, msg):
        e.token.error(msg)

    def constvalue(self, e):
        if e.op == 'literal' and isinstance(e.value, int):
            return e.value
        if e.op == 'name' and e.sym and (e.sym.kind == 'const') and isinstance(e.sym.value, int):
            return e.sym.value
        if e.op in ('unary+', 'unary-', 'unarynot'):
            x = self.constvalue(e.args[0])
            if x is None:
                return None
            return x if e.op == 'unary+' else -x if e.op == 'unary-' else ~x
        if e.op == 'call' and e.args[0].sym and (len(e.args) == 2):
            s = e.args[0].sym
            x = self.constvalue(e.args[1])
            if x is None:
                return None
            if s.kind == 'type' and s.type.kind in ('ordinal', 'char', 'bool'):
                t = s.type
                x &= (1 << 8 * t.size) - 1
                if t.signed and x > t.hi:
                    x -= 1 << 8 * t.size
                return x
            if s.kind == 'builtin' and s.name.lower() in ('succ', 'pred', 'abs', 'sqr'):
                return {'succ': lambda : x + 1, 'pred': lambda : x - 1, 'abs': lambda : abs(x),
                     'sqr': lambda : x * x}[s.name.lower()]()
        if e.op in Parser.PRECEDENCE and e.op not in ('/', 'in'):
            a = self.constvalue(e.args[0])
            b = self.constvalue(e.args[1])
            if a is None or b is None:
                return None
            operations = {'+': lambda : a + b, '-': lambda : a - b, '*': lambda : a * b,
                 'div': lambda : int(a / b), 'mod': lambda : a - int(a / b) * b, 'and': lambda : a & b,
                 'or': lambda : a | b, 'xor': lambda : a ^ b, 'shl': lambda : a << b if 0 <= b < 32 else 0,
                 'shr': lambda : (a & 4294967295) >> b if 0 <= b < 32 else 0, '=': lambda : int(a == b),
                 '<>': lambda : int(a != b), '<': lambda : int(a < b), '>': lambda : int(a > b), '<=': lambda : int(a <= b),
                 '>=': lambda : int(a >= b)}
            try:
                return operations[e.op]()
            except ZeroDivisionError:
                self.fail(e, 'division by zero in constant expression')
        return None

    def resolve(self, e):
        for w in reversed(self.withs):
            t = self.type(w)
            if e.value.lower() in t.fields:
                e.op = 'field'
                e.args = [w]
                return None
        if e.sym:
            return e.sym
        self.fail(e, f'unresolved identifier {e.value}')

    def type(self, e):
        if e.type:
            return e.type
        op = e.op
        if op in Parser.PRECEDENCE or op in ('unary+', 'unary-', 'unarynot'):
            v = self.constvalue(e)
            if v is not None:
                boolean = op == 'unarynot' and self.type(e.args[0]).kind == 'bool'
                if boolean:
                    v = int(not self.constvalue(e.args[0]))
                e.op = 'literal'
                e.value = v
                e.type = BOOL if boolean or op in ('=', '<>', '<', '>', '<=', '>=') else Parser.consttype(v)
                return e.type
        if op == 'name':
            s = self.resolve(e)
            if s:
                e.type = s.type
            else:
                return self.type(e)
        elif op == 'call':
            cal = e.args[0]
            s = self.resolve(cal)
            if s.kind not in ('routine', 'builtin', 'type'):
                self.fail(e, 'call target is not callable')
            for a in e.args[1:]:
                self.type(a)
            if s.kind == 'type':
                if len(e.args) != 2:
                    self.fail(e, 'cast requires one argument')
                e.type = s.type
            elif s.kind == 'routine':
                if len(e.args) - 1 != len(s.params):
                    self.fail(e, f'{s.name}: parameter count mismatch')
                for (p, a) in zip(s.params, e.args[1:]):
                    at = self.type(a)
                    if p.byref and p.type is not UNTYPED and (p.type.size != at.size):
                        self.fail(e, f'{s.name}: var parameter {p.name} size mismatch')
                e.type = s.type
            else:
                n = s.name.lower()
                e.type = s.type
                if n in ('succ', 'pred', 'abs', 'sqr'):
                    e.type = self.type(e.args[1])
                if n in ('succ', 'pred', 'abs', 'sqr'):
                    v = self.constvalue(e)
                    if v is not None:
                        e.op = 'literal'
                        e.value = v
                        e.type = Parser.consttype(v)
                if n == 'ord':
                    t = self.type(e.args[1])
                    e.type = LONG if t.size == 4 else WORD if t is WORD else INTEGER
        elif op == 'deref':
            t = self.type(e.args[0])
            if t.kind != 'pointer' or t.elem is None:
                self.fail(e, 'dereference requires a typed pointer')
            e.type = t.elem
        elif op == 'field':
            base = e.args[0]
            if base.op == 'name' and base.value.lower() in self.c.units:
                u = self.c.units[base.value.lower()]
                s = u.interface.find(e.value)
                if not s:
                    self.fail(e, 'unknown unit member')
                e.op = 'name'
                e.sym = s
                e.type = s.type
            else:
                t = self.type(base)
                if t.kind != 'record' or e.value.lower() not in t.fields:
                    self.fail(e, f'unknown record field {e.value}')
                e.type = t.fields[e.value.lower()][1]
        elif op == 'index':
            t = self.type(e.args[0])
            for a in e.args[1:]:
                self.type(a)
            if e.args[0].op == 'name' and e.args[0].sym and (e.args[0].sym.kind == 'special'):
                e.type = t
            elif t.kind == 'string':
                e.type = CHAR
            elif t.kind == 'array':
                n = len(e.args) - 1
                if n > len(t.bounds):
                    self.fail(e, 'too many array indices')
                if n == len(t.bounds):
                    e.type = t.elem
                else:
                    size = t.elem.size
                    for (lo, hi) in t.bounds[n:]:
                        size *= hi - lo + 1
                    e.type = self.c.addtype(Type('array', size=size, elem=t.elem, bounds=t.bounds[n:]))
            else:
                self.fail(e, 'indexing requires array/string/memory/port')
        elif op == 'format':
            e.type = self.type(e.args[0])
        elif op.startswith('unary'):
            t = self.type(e.args[0])
            if op == 'unary@':
                e.type = POINTER
            elif op == 'unarynot':
                e.type = t
            elif op == 'unary+':
                e.type = t
            else:
                e.type = LONG if t.size == 4 or t is WORD else INTEGER
        elif op == 'in':
            self.type(e.args[0])
            self.type(e.args[1])
            e.type = BOOL
        elif op in Parser.PRECEDENCE:
            (a, b) = map(self.type, e.args)
            if op in ('=', '<>', '<', '>', '<=', '>='):
                e.type = BOOL
            elif a.kind == 'string' or b.kind == 'string' or (a.kind == b.kind == 'char' and op == '+'):
                e.type = STRING
            elif a.kind == b.kind == 'set':
                e.type = SET
            elif op in ('and', 'or', 'xor') and a.kind == b.kind == 'bool':
                e.type = BOOL
            elif op in ('shl', 'shr'):
                e.type = LONG if a.size == 4 else WORD if a is WORD else INTEGER
            elif a.size == 4 or b.size == 4:
                e.type = LONG
            elif a is WORD or b is WORD:
                other = e.args[1] if a is WORD else e.args[0]
                ot = b if a is WORD else a
                # A nonnegative untyped constant is compatible with Word.
                constant = other.op == 'literal' or (other.op == 'name' and other.sym and (other.sym.kind == 'const'))
                v = other.value if other.op == 'literal' else other.sym.value if constant else None
                if ot.signed and (not (constant and isinstance(v, int) and (v >= 0))):
                    e.type = LONG
                else:
                    e.type = WORD
            else:
                e.type = INTEGER
        else:
            self.fail(e, f'unsupported expression {op}')
        return e.type

    def promoted(self, a, b):
        if self.type(a).kind in ('char', 'bool') and self.type(b).kind in ('char', 'bool'):
            return INTEGER
        fake = Expr('+', [a, b], a.token)
        return self.type(fake)

    def cast(self, t, code, source=None):
        if t.kind in ('record', 'array', 'string', 'set', 'file', 'text'):
            return code
        if source and t.size == source.size and (t.signed == source.signed):
            return code
        if re.fullmatch('-?\\d+', code):
            value = int(code) & (1 << t.size * 8) - 1
            if t.signed and value >= 1 << t.size * 8 - 1:
                value -= 1 << t.size * 8
            return str(value)
        if t.size == 1:
            return f'({t.cname})({code})'
        if t.size == 2:
            return f'tp_i16({code})' if t.signed else f'(uint16_t)({code})'
        if t.size == 4:
            return f'tp_i32({code})' if t.signed else f'(uint32_t)({code})'
        return code

    def localaddress(self, s):
        owner = s.scope.routine
        if owner is self.routine or owner is None:
            return s.cname if s.byref else '&' + s.cname
        cur = self.routine
        path = 'tp_parent'
        while cur and cur.body_scope.parent.routine is not owner:
            cur = cur.body_scope.parent.routine
            path += '->tp_parent'
        if not cur:
            self.fail(Expr('name', token=s.token), 'invalid captured scope')
        return path + '->' + s.cname

    def faraddress(self, e):
        t = self.type(e)
        if self.order and id(e) in self.order.fars:
            return self.order.fars[id(e)]
        if e.op == 'selected':
            return e.value.get('far')
        if e.op == 'name' and e.sym.kind in ('global', 'typedconst'):
            return self.global_far_name(e.sym)
        if e.op == 'name' and e.sym.kind == 'runtimevar':
            return self.global_far_name(e.sym)
        if e.op == 'deref':
            return self.expr(e.args[0])
        if e.op == 'field':
            rt = self.type(e.args[0])
            name = rt.fields[e.value.lower()][0]
            p = self.faraddress(e.args[0])
            return f'tp_fp_add({p}, offsetof({rt.cname}, {name}))' if p else None
        if e.op == 'index':
            base = e.args[0]
            p = self.faraddress(base)
            if not p:
                return None
            if self.type(base).kind == 'array':
                helper = self.array_helper(e)
                args = ', '.join((self.expr(a) for a in e.args[1:]))
                if base.op == 'name' and base.sym.kind in ('global', 'typedconst'):
                    return f"{self.global_array_name(e, 'addr')}({args})"
                return f'{helper}_fp({p}, {args})'
            return f'tp_fp_add({p}, {self.indexoffset(e)})'
        if e.op == 'call' and e.args[0].sym.kind == 'type' and (t.kind not in ('ordinal',
             'char', 'bool', 'pointer')):
            return self.faraddress(e.args[1])
        return None

    def indexoffset(self, e):
        t = self.type(e.args[0])
        parts = []
        if t.kind == 'string':
            return self.expr(e.args[1])
        for (j, a) in enumerate(e.args[1:]):
            stride = t.elem.size
            for (lo, hi) in t.bounds[j + 1:]:
                stride *= hi - lo + 1
            value = self.constvalue(a)
            if value is not None:
                parts.append(str((value - t.bounds[j][0]) * stride))
                continue
            index = self.expr(a)
            lower = t.bounds[j][0]
            delta = index if not lower else f'({index} - {lower})'
            parts.append(delta if stride == 1 else f'{delta} * {stride}')
        if all((re.fullmatch('-?\\d+', p) for p in parts)):
            return str(sum(map(int, parts)))
        return ' + '.join(parts)

    def address(self, e):
        if self.order and id(e) in self.order.hosts:
            return self.order.hosts[id(e)]
        if e.op == 'selected':
            return e.value['host']
        t = self.type(e)
        if e.op == 'name':
            if e.sym.kind in ('runtimevar', 'global', 'typedconst'):
                return '&' + e.sym.cname
            if e.sym.kind in ('local', 'param'):
                return self.localaddress(e.sym)
        if e.op == 'field':
            return '&' + self.lvalue(e)
        if e.op == 'index' and self.type(e.args[0]).kind == 'array':
            return '&' + self.lvalue(e)
        far = self.faraddress(e)
        if far:
            return f'pc_host_fp({far})'
        if e.op == 'index':
            return f'((uint8_t *)({self.address(e.args[0])}) + ({self.indexoffset(e)}))'
        if e.op == 'call' and e.args[0].sym.kind == 'type':
            return self.address(e.args[1])
        self.fail(e, 'expression is not addressable')

    def lvalue(self, e):
        t = self.type(e)
        if e.op == 'name' and e.sym is self.routine:
            return 'tp_result'
        if self.order and id(e) in self.order.hosts:
            return f'(*({t.cname} *){self.order.hosts[id(e)]})'
        if e.op == 'name':
            s = e.sym
            if s.kind in ('global', 'typedconst', 'runtimevar'):
                return s.cname
            if s.scope.routine is self.routine or s.scope.routine is None:
                return f'(*{s.cname})' if s.byref else s.cname
            return f'(*{self.localaddress(s)})'
        if e.op == 'field':
            base = e.args[0]
            rt = self.type(base)
            field = rt.fields[e.value.lower()][0]
            if self.fixed_record(base):
                return f'{self.lvalue(base)}.{field}'
            if base.op == 'index' and base.args[0].op == 'name' and base.args[0].sym.kind in ('global', 'typedconst'):
                args = ', '.join(self.expr(a) for a in base.args[1:])
                return f'{self.global_array_name(base)}_{field}({args})'
            return f'{self.field_helper(rt, field)}({self.faraddress(base)})'
        if e.op == 'index' and self.type(e.args[0]).kind == 'array':
            base = e.args[0]
            helper = self.array_helper(e)
            args = ', '.join((self.expr(a) for a in e.args[1:]))
            if base.op == 'name' and base.sym.kind in ('global', 'typedconst'):
                return f'{self.global_array_name(e)}({args})'
            far = self.faraddress(base)
            return f'(*{helper}({far}, {args}))' if far else f'(*{helper}_host({self.address(base)}, {args}))'
        return f'(*({t.cname} *)({self.address(e)}))'

    def string(self, e):
        if self.order and id(e) in self.order.strings:
            return self.order.strings[id(e)]
        t = self.type(e)
        if e.op == 'format':
            return self.string(e.args[0])
        if e.op == 'literal' or (e.op == 'name' and e.sym and (e.sym.kind == 'const')):
            v = e.value if e.op == 'literal' else e.sym.value
            if not isinstance(v, bytes):
                self.fail(e, 'string expected')
            # Octal escapes retain byte values without depending on the source
            # encoding or accidentally consuming a following hex character.
            data = ''.join(chr(byte) if 32 <= byte < 127 and byte not in (34, 63, 92)
                           else '\\"' if byte == 34 else '\\\\' if byte == 92
                           else f'\\{byte:03o}' for byte in v)
            return f'tp_Sliteral((const uint8_t *)"{data}", {len(v)})'
        if t.kind == 'char':
            return f'tp_Schar({self.expr(e)})'
        if e.op == 'call' or (e.op == 'name' and e.sym.kind == 'routine') or e.op == '+':
            return self.expr(e)
        if e.op == 'name' and e.sym is self.routine:
            return 'tp_result'
        return f'tp_Sfrom({self.address(e)})'

    def expr(self, e):
        if self.order and id(e) in self.order.values:
            return self.order.values[id(e)]
        t = self.type(e)
        op = e.op
        if t.kind == 'set' and op in ('name', 'field', 'index', 'deref'):
            return f'tp_SetLoad({self.address(e)}, {t.lo}, {t.size})'
        if op == 'literal':
            if isinstance(e.value, bytes):
                return str(e.value[0]) if len(e.value) == 1 else self.string(e)
            return str(e.value)
        if op == 'name':
            s = e.sym
            if s is self.routine:
                return 'tp_result'
            if s.kind == 'const':
                if isinstance(s.value, bytes):
                    return str(s.value[0]) if len(s.value) == 1 else self.string(e)
                return str(s.value)
            if s.kind in ('routine', 'builtin'):
                return self.call(Expr('call', [e], e.token, type=s.type))
            if s.kind == 'type':
                return s.type.cname
            if s.kind in ('global', 'typedconst'):
                return s.cname
            return self.lvalue(e)
        if op == 'call':
            return self.call(e)
        if op == 'format':
            return self.expr(e.args[0])
        if op in ('index', 'field', 'deref'):
            if op == 'index' and e.args[0].op == 'name' and (e.args[0].sym.kind == 'special'):
                n = e.args[0].sym.name.lower()
                a = list(map(self.expr, e.args[1:]))
                if n in ('mem', 'memw'):
                    if len(a) != 2:
                        self.fail(e, 'Mem requires segment:offset')
                    return f"pc_rd{(16 if n == 'memw' else 8)}({a[0]}, {a[1]})"
                return f"pc_in{('w' if n == 'portw' else 'b')}({a[0]})"
            return self.lvalue(e)
        if op == 'unary@':
            x = e.args[0]
            if x.op == 'name' and x.sym.kind == 'routine':
                if x.sym.params or x.sym.type is not VOID:
                    self.fail(e, 'code address requires parameterless procedure')
                return f'pc_register_code({x.sym.cname}, "{x.sym.cname}")'
            p = self.faraddress(x)
            if not p:
                self.fail(e, 'far address of host local is not supported')
            return p
        if op.startswith('unary'):
            x = self.expr(e.args[0])
            if op == 'unarynot':
                return f'(!({x}))' if t.kind == 'bool' else self.cast(t, f'~(uint32_t)({x})')
            if op == 'unary-':
                return self.cast(t, f'0u - (uint32_t)({x})')
            return self.cast(t, x)
        if op == 'set':
            args = [f'tp_SetRange({self.expr(lo)}, {self.expr(hi)})' for (lo, hi) in e.args]
            result = 'tp_SetEmpty()'
            for x in args:
                result = f'tp_SetUnion({result}, {x})'
            return result
        (a, b) = e.args
        (at, bt) = (self.type(a), self.type(b))
        if op == 'in':
            return f'tp_SetContains({self.expr(b)}, {self.expr(a)})'
        if at.kind == 'set' and bt.kind == 'set':
            n = {'+': 'Union', '-': 'Diff', '*': 'Intersect', '=': 'Equal', '<>': 'Unequal',
                 '<=': 'Subset', '>=': 'Superset'}.get(op)
            if not n:
                self.fail(e, 'unsupported set operation')
            return f'tp_Set{n}({self.expr(a)}, {self.expr(b)})'
        if at.kind == 'string' or bt.kind == 'string' or (at.kind == bt.kind == 'char' and op == '+'):
            (ac, bc) = (self.string(a), self.string(b))
            if op == '+':
                return f'tp_Concat({ac}, {bc})'
            cop = {'=': '==', '<>': '!=', '<': '<', '>': '>', '<=': '<=', '>=': '>='}[op]
            return f'(tp_Compare({ac}, {bc}) {cop} 0)'
        (ac, bc) = (self.expr(a), self.expr(b))
        if op in ('and', 'or', 'xor') and t.kind == 'bool':
            if e.value and op in ('and', 'or'):
                cop = '&' if op == 'and' else '|'
            else:
                cop = {'and': '&&', 'or': '||', 'xor': '^'}[op]
            return f'({ac} {cop} {bc})'
        if op in ('=', '<>', '<', '>', '<=', '>='):
            p = self.promoted(a, b)
            cop = {'=': '==', '<>': '!='}.get(op, op)
            # Integer/Word both promote to a C int on this host. For LongInt
            # mixtures, the TP comparison is signed; preserve an explicit cast
            # only for an unsigned 32-bit operand (e.g. a stored far pointer).
            if p.signed:
                if at.size == 4 and (not at.signed):
                    ac = f'({p.cname})({ac})'
                if bt.size == 4 and (not bt.signed):
                    bc = f'({p.cname})({bc})'
            return f'({ac} {cop} {bc})'
        if op in ('shl', 'shr'):
            return self.cast(t, f"tp_Shift({ac}, {bc}, {t.size * 8}, {(1 if op == 'shr' else 0)})")
        if op in ('div', 'mod'):
            n = 'Div' if op == 'div' else 'Mod'
            return self.cast(t, f"tp_{n}{('S' if t.signed else 'U')}({ac}, {bc})")
        if op == '/':
            self.fail(e, 'real arithmetic is not implemented')
        cop = {'and': '&', 'or': '|', 'xor': '^'}.get(op, op)
        wide = t.size == 4 or (op == '*' and (at is WORD or bt is WORD))
        ac = self.integer_operand(a, ac, wide)
        bc = self.integer_operand(b, bc, wide)
        return self.cast(t, f'{ac} {cop} {bc}')

    def call(self, e):
        s = e.args[0].sym
        args = e.args[1:]
        n = s.name.lower()
        if s.kind == 'type':
            t = s.type
            if t.kind in ('ordinal', 'bool', 'char', 'pointer'):
                return self.cast(t, self.expr(args[0]))
            return self.lvalue(e)
        if s.kind == 'routine':
            vals = []
            parent = s.scope.routine
            if parent:
                vals.append('&tp_frame' if parent is self.routine else 'tp_parent')
            for (p, a) in zip(s.params, args):
                if p.byref:
                    if s.external:
                        f = self.faraddress(a)
                        if not f:
                            f = self.local_far(a)
                        vals.append(f)
                    else:
                        # Sequenced addresses are byte-pointer temporaries;
                        # typed var parameters still require their pointer cast.
                        vals.append(
                            f'({p.type.cname} *)({self.address(a)})'
                            if p.type is not UNTYPED and (
                                p.type is not self.type(a)
                                or a.op in ('deref', 'selected', 'call')
                                or self.order and id(a) in self.order.hosts
                            )
                            else self.address(a)
                        )
                elif p.type.kind == 'string':
                    vals.append(self.string(a))
                else:
                    vals.append(self.cast(p.type, self.expr(a), self.type(a)))
            target = self.c.prefix + 'call_' + s.cname if s.external and any((p.byref or p.type.kind == 'string' for p in s.params)) else s.cname
            return f"{target}({', '.join(vals)})"
        if n in ('length', 'copy', 'pos', 'concat', 'insert', 'delete'):
            if n == 'length':
                return f'tp_Length({self.string(args[0])})'
            if n == 'copy':
                return f'tp_Copy({self.string(args[0])}, {self.expr(args[1])}, {self.expr(args[2])})'
            if n == 'pos':
                return f'tp_Pos({self.string(args[0])}, {self.string(args[1])})'
            if n == 'concat':
                r = self.string(args[0])
                for a in args[1:]:
                    r = f'tp_Concat({r}, {self.string(a)})'
                return r
            if n == 'insert':
                return f'tp_Insert({self.string(args[0])}, {self.address(args[1])}, {self.type(args[1]).size - 1}, {self.expr(args[2])})'
            return f'tp_Delete({self.address(args[0])}, {self.expr(args[1])}, {self.expr(args[2])})'
        if n in ('inc', 'dec'):
            a = args[0]
            v = self.expr(args[1]) if len(args) > 1 else '1'
            cop = '+' if n == 'inc' else '-'
            wide = self.type(a).size == 4 or len(args) > 1 and self.type(args[1]).size == 4
            left = self.integer_operand(a, self.expr(a), wide)
            right = self.integer_operand(args[1] if len(args) > 1 else a, v, wide)
            calc = f'{left} {cop} {right}'
            return f'({self.lvalue(a)} = {self.cast(self.type(a), calc)})'
        if n in ('chr', 'ord', 'lo', 'hi', 'succ', 'pred', 'abs', 'sqr', 'odd', 'upcase'):
            x = self.expr(args[0])
            if n in ('chr', 'ord'):
                return self.cast(self.type(e), x)
            if n == 'lo':
                return f'((uint8_t)({x}))'
            if n == 'hi':
                return f'((uint8_t)((uint32_t)({x}) >> 8))'
            if n in ('succ', 'pred'):
                return self.cast(self.type(e), f"(uint32_t)({x}) {('+' if n == 'succ' else '-')} 1u")
            if n == 'abs':
                return self.cast(self.type(e), f'tp_Abs({x})')
            if n == 'sqr':
                return self.cast(self.type(e), f'(uint32_t)({x}) * (uint32_t)({x})')
            if n == 'odd':
                return f'(({x}) & 1u)'
            return f'tp_UpCase({x})'
        if n == 'sizeof':
            return str(self.type(args[0]).size)
        if n == 'ptr':
            return f'FP({self.expr(args[0])}, {self.expr(args[1])})'
        if n in ('seg', 'ofs'):
            p = self.faraddress(args[0])
            if not p:
                a = args[0]
                if a.op == 'name' and a.sym.kind == 'routine':
                    p = f'pc_register_code({a.sym.cname}, "{a.sym.cname}")'
                else:
                    p = self.local_far(a)
            return f"FP_{('SEG' if n == 'seg' else 'OFF')}({p})"
        if n in ('dseg', 'sseg', 'cseg'):
            return f"pc_current_program()->{('ds_seg' if n == 'dseg' else 'ss_seg')}"
        if n == 'fillchar':
            return f'tp_FillChar({self.address(args[0])}, {self.expr(args[1])}, {self.expr(args[2])})'
        if n == 'move':
            return f'tp_Move({self.address(args[0])}, {self.address(args[1])}, {self.expr(args[2])})'
        if n in ('new', 'dispose'):
            a = args[0]
            if self.type(a).kind != 'pointer' or not self.type(a).elem:
                self.fail(e, 'New/Dispose requires typed pointer')
            return f"tp_{('GetMem' if n == 'new' else 'FreeMem')}({(self.address(a) if n == 'new' else self.expr(a))}, {self.type(a).elem.size})"
        if n == 'getmem':
            return f'tp_GetMem({self.address(args[0])}, {self.expr(args[1])})'
        if n == 'freemem':
            return f'tp_FreeMem({self.expr(args[0])}, {self.expr(args[1])})'
        if n == 'mark':
            return f'tp_Mark({self.address(args[0])})'
        if n == 'release':
            return f'tp_Release({self.expr(args[0])})'
        if n == 'str':
            a = args[0]
            width = self.expr(a.args[1]) if a.op == 'format' else '0'
            dest = args[1]
            return f'tp_Str({self.expr(a)}, {width}, {self.address(dest)}, {self.type(dest).size - 1})'
        if n == 'val':
            a = args[1]
            err = args[2]
            return f'tp_Val({self.string(args[0])}, {self.address(a)}, {self.type(a).size}, {int(self.type(a).signed)}, (int16_t *)({self.address(err)}))'
        if n in ('assign', 'reset', 'rewrite', 'close', 'erase', 'seek', 'filesize', 'filepos',
             'eof', 'eoln'):
            f = args[0]
            ft = self.type(f)
            vs = [self.file_address(f)]
            if n == 'assign':
                vs.append(self.string(args[1]))
            if n in ('reset', 'rewrite'):
                size = self.expr(args[1]) if len(args) > 1 else str(ft.elem.size if ft.elem else 128)
                vs.extend([size, str(int(ft.kind == 'text'))])
            if n == 'seek':
                vs.append(self.expr(args[1]))
            return f"tp_{n.capitalize()}({', '.join(vs)})"
        if n in ('read', 'write', 'readln', 'writeln'):
            ft = self.type(args[0]) if args else None
            if ft and ft.kind == 'file':
                if len(args) != 2:
                    self.fail(e, 'typed Read/Write currently requires one item')
                return f'tp_{n.capitalize()}({self.file_address(args[0])}, {self.address(args[1])})'
            filearg = 'NULL'
            if ft and ft.kind == 'text':
                filearg = f'(tp_file *)({self.address(args[0])})'
                args = args[1:]
            if n in ('read', 'readln'):
                vs = []
                for a in args:
                    at = self.type(a)
                    if at.kind == 'char':
                        vs.append(f'tp_TextReadChar({filearg}, (uint8_t *)({self.address(a)}))')
                    elif at.kind == 'string':
                        vs.append(f'tp_TextReadString({filearg}, {self.address(a)}, {at.size - 1})')
                    elif at.kind == 'ordinal':
                        vs.append(f'tp_TextReadInteger({filearg}, {self.address(a)}, {at.size}, {int(at.signed)})')
                    else:
                        self.fail(e, 'unsupported Text Read item')
                if n == 'readln':
                    vs.append(f'tp_TextReadLn({filearg})')
                return vs[0] if len(vs) == 1 else '(' + ', '.join(vs) + ')' if vs else '(void)0'
            vs = []
            for a in args:
                at = self.type(a)
                width = self.expr(a.args[1]) if a.op == 'format' else '0'
                if at.kind in ('string', 'char'):
                    vs.append(f'tp_TextWriteString({filearg}, {self.string(a)}, {width})')
                elif at.kind == 'bool':
                    vs.append(f'tp_TextWriteBoolean({filearg}, {self.expr(a)}, {width})')
                else:
                    vs.append(f'tp_TextWriteInteger({filearg}, {self.expr(a)}, {width})')
            if n == 'writeln':
                vs.append(f'tp_TextWriteLn({filearg})')
            return vs[0] if len(vs) == 1 else '(' + ', '.join(vs) + ')' if vs else '(void)0'
        if n == 'exit':
            return '__TP_FRAME_END__return' if self.routine.type is VOID else '__TP_FRAME_END__return tp_result'
        names = {'random': 'Random', 'randomize': 'Randomize', 'memavail': 'MemAvail',
             'maxavail': 'MaxAvail', 'ioresult': 'IOResult', 'halt': 'Halt', 'delay': 'Delay', 'sound': 'Sound',
             'nosound': 'NoSound', 'keypressed': 'KeyPressed', 'readkey': 'ReadKey', 'intr': 'Intr',
             'msdos': 'MsDos', 'getintvec': 'GetIntVec', 'setintvec': 'SetIntVec', 'textmode': 'TextMode',
             'gotoxy': 'GotoXY', 'clrscr': 'ClrScr', 'textcolor': 'TextColor', 'textbackground': 'TextBackground'}
        if n not in names:
            self.fail(e, f'unimplemented intrinsic {n}')
        vs = []
        for (j, a) in enumerate(args):
            if n == 'getintvec' and j == 1:
                vs.append(f'(farptr *)({self.address(a)})')
            elif n in ('intr', 'msdos') and j == len(args) - 1:
                vs.append(self.address(a))
            else:
                vs.append(self.expr(a))
        if n == 'halt' and (not vs):
            vs = ['0']
        return f"tp_{names[n]}({', '.join(vs)})"

    def assignment(self, a, b):
        (at, bt) = (self.type(a), self.type(b))
        if a.op == 'index' and a.args[0].op == 'name' and (a.args[0].sym.kind == 'special'):
            n = a.args[0].sym.name.lower()
            vs = list(map(self.expr, a.args[1:])) + [self.expr(b)]
            return f"pc_{('wr16' if n == 'memw' else 'wr8' if n == 'mem' else 'outw' if n == 'portw' else 'outb')}({', '.join(vs)});"
        if at.kind == 'string':
            if a.op == 'name' and a.sym is self.routine:
                return f'tp_result = {self.string(b)};'
            return f'tp_AssignString({self.address(a)}, {at.size - 1}, {self.string(b)});'
        if at.kind in ('record', 'array'):
            return f'tp_Move({self.address(b)}, {self.address(a)}, {at.size});'
        if at.kind == 'set':
            return f'tp_SetStore({self.address(a)}, {at.lo}, {at.size}, {self.expr(b)});'
        return f'{self.lvalue(a)} = {self.cast(at, self.expr(b), bt)};'

    def condition(self, e):
        """The statement supplies its own outer condition parentheses."""
        code = self.expr(e)
        if self.type(e).kind == 'bool' and e.op in ('=', '<>', '<', '>', '<=', '>=', 'and', 'or', 'xor', 'unarynot'):
            if code.startswith('(') and code.endswith(')'):
                return code[1:-1]
        return code

    def statement(self, s, indent=1):
        comments = self.comments_before(s.token.file, s.token.line) if s.token else []
        return ['    ' * indent + line for line in comments] + self.statement_body(s, indent)

    def statement_body(self, s, indent=1):
        from pas2c_order import Order
        pad = '    ' * indent
        op = s.op
        if op == 'block':
            return [line for child in s.args for line in self.statement(child, indent)]
        if op == 'with':
            (es, body) = s.args
            selected = []
            out = []
            for e in es:
                prev = self.order
                ctx = Order(self, e, 'with selector')
                self.order = ctx
                try:
                    ctx.lower(e, 'host')
                    far = self.faraddress(e)
                    if e.op == 'name':
                        chosen = e
                    elif far:
                        fp = ctx.capture(e, 'far', True)
                        ctx.lines.append(f'(void){fp}; /* a later with selector may shadow this record */')
                        chosen = Expr('selected', type=self.type(e), token=e.token, value={'far': fp,
                             'host': f'pc_host_fp({fp})'})
                    else:
                        hp = ctx.capture(e, 'host', True)
                        ctx.lines.append(f'(void){hp}; /* a later with selector may shadow this record */')
                        chosen = Expr('selected', type=self.type(e), token=e.token, value={'host': hp})
                    ctx.rule('with selectors left-to-right, each selected record address retained for entire body')
                    out.extend((pad + x for x in ctx.lines))
                    ctx.finish()
                    selected.append(chosen)
                finally:
                    self.order = prev
            self.withs.extend(selected)
            try:
                out.extend(self.statement(body, indent))
            finally:
                del self.withs[-len(selected):]
            return out
        if op == 'call':
            e = s.args[0]
            self.type(e)
            sym = e.args[0].sym if e.op == 'call' else e.sym
            if sym and sym.kind == 'builtin' and (sym.name.lower() in ('write', 'writeln',
                 'read', 'readln')) and (e.op == 'call'):
                args = e.args[1:]
                n = sym.name.lower()
                ft = self.type(args[0]) if args else None
                if not ft or ft.kind != 'file':
                    fileargs = args[:1] if ft and ft.kind == 'text' else []
                    items = args[1:] if fileargs else args
                    out = []
                    # Console I/O is a sequence of calls, not one C argument list.
                    for item in items:
                        base = Expr('name', sym=self.c.system.find('write' if n.startswith('write') else 'read'),
                             token=e.token, value='write' if n.startswith('write') else 'read')
                        one = Expr('call', [base, *fileargs, item], e.token, type=VOID)
                        out.extend(self.ordered_statement(Stmt('call', [one], s.token), indent))
                    if n in ('writeln', 'readln'):
                        base = Expr('name', sym=sym, token=e.token, value=n)
                        one = Expr('call', [base, *fileargs], e.token, type=VOID)
                        out.extend(self.ordered_statement(Stmt('call', [one], s.token), indent))
                    return out
        if op == 'for':
            (v, first, last, direction, body) = s.args
            ty = self.type(v)
            bound = self.unique('limit_')
            iv = self.lvalue(v)
            out = [pad + '{']
            prev = self.order
            ctx = Order(self, last, 'for terminal bound before initial bound')
            self.order = ctx
            try:
                ctx.lower(last)
                out.extend((pad + '    ' + x for x in ctx.lines))
                out.append(pad + f'    {ty.cname} {bound} = {self.cast(ty, self.expr(last))};')
                ctx.rule('for terminal bound before initial bound')
                ctx.finish()
            finally:
                self.order = prev
            out.extend(self.ordered_statement(Stmt('assign', [v, first], s.token), indent + 1))
            out.extend([pad + f"    if ({iv} {('<=' if direction == 'to' else '>=')} {bound}) {{",
                 pad + '        for (;;) {'])
            out.extend(self.statement(body, indent + 3))
            out.append(pad + f'            if ({iv} == {bound}) break;')
            cop = '+' if direction == 'to' else '-'
            calc = f'(uint32_t)({iv}) {cop} 1u'
            out.extend([pad + f'            {iv} = {self.cast(ty, calc)};', pad + '            pc_poll();',
                 pad + '        }', pad + '    }', pad + '}'])
            return out
        return self.ordered_statement(s, indent)

    def ordered_statement(self, s, indent):
        from pas2c_order import Order
        op = s.op
        pad = '    ' * indent
        if op not in ('assign', 'call', 'if', 'while', 'repeat', 'case'):
            return self._statement(s, indent)
        root = s.args[1] if op == 'assign' else s.args[1] if op == 'repeat' else s.args[0]
        ctx = Order(self, root, op)
        prev = self.order
        self.order = ctx
        try:
            if op == 'assign':
                ctx.assignment(*s.args)
            else:
                ctx.lower(root)
            if op == 'while' and ctx.lines:
                (e, body) = s.args
                out = [pad + 'for (;;) {', *[pad + '    ' + x for x in ctx.lines], pad + f'    if (!({self.condition(e)})) break;']
                out.extend(self.statement(body, indent + 1))
                out.extend([pad + '    pc_poll();', pad + '}'])
            elif op == 'repeat' and ctx.lines:
                (body, e) = s.args
                out = [pad + 'for (;;) {']
                out.extend(self.statement(body, indent + 1))
                out.extend([pad + '    pc_poll();', *[pad + '    ' + x for x in ctx.lines],
                     pad + f'    if ({self.condition(e)}) break;', pad + '}'])
            else:
                out = [*[pad + x for x in ctx.lines], *self._statement(s, indent)]
            ctx.finish()
            return out
        finally:
            self.order = prev

    def _statement(self, s, indent=1):
        pad = '    ' * indent
        op = s.op
        out = []

        def line(x):
            out.append(pad + x)
        if op == 'block':
            for x in s.args:
                out.extend(self.statement(x, indent))
        elif op == 'assign':
            line(self.assignment(*s.args))
        elif op == 'call':
            line(self.expr(s.args[0]) + ';')
        elif op == 'if':
            (e, y, n) = s.args
            line(f'if ({self.condition(e)}) {{')
            out.extend(self.statement(y, indent + 1))
            line('}')
            if n.args:
                line('else {')
                out.extend(self.statement(n, indent + 1))
                line('}')
        elif op == 'while':
            (e, b) = s.args
            line(f'while ({self.condition(e)}) {{')
            out.extend(self.statement(b, indent + 1))
            line('    pc_poll();')
            line('}')
        elif op == 'repeat':
            (b, e) = s.args
            line('do {')
            out.extend(self.statement(b, indent + 1))
            line('    pc_poll();')
            line(f'}} while (!({self.condition(e)}));')
        elif op == 'for':
            (v, first, last, direction, b) = s.args
            ty = self.type(v)
            bound = self.unique('limit_')
            iv = self.lvalue(v)
            line('{')
            line(f'    {ty.cname} {bound} = {self.cast(ty, self.expr(last))};')
            line('    ' + self.assignment(v, first))
            line(f"    if ({iv} {('<=' if direction == 'to' else '>=')} {bound}) {{")
            line('        for (;;) {')
            out.extend(self.statement(b, indent + 3))
            line(f'            if ({iv} == {bound}) break;')
            cop = '+' if direction == 'to' else '-'
            calc = f'(uint32_t)({iv}) {cop} 1u'
            line(f'            {iv} = {self.cast(ty, calc)};')
            line('            pc_poll();')
            line('        }')
            line('    }')
            line('}')
        elif op == 'case':
            (e, branches, otherwise) = s.args
            name = self.unique('case_')
            ty = self.type(e)
            line('{')
            line(f'    {ty.cname} {name} = {self.expr(e)};')
            for (j, (labels, b)) in enumerate(branches):
                tests = []
                for (lo, hi) in labels:
                    (a, z) = (self.expr(lo), self.expr(hi))
                    tests.append(f'{name} == {a}' if lo is hi else f'({name} >= {a} && {name} <= {z})')
                line(f"    {('if' if j == 0 else 'else if')} ({' || '.join(tests)}) {{")
                out.extend(self.statement(b, indent + 2))
                line('    }')
            if otherwise.args:
                line('    else {')
                out.extend(self.statement(otherwise, indent + 2))
                line('    }')
            line('}')
        elif op == 'with':
            (es, b) = s.args
            self.withs.extend(es)
            out.extend(self.statement(b, indent))
            del self.withs[-len(es):]
        elif op == 'inline':
            ts = s.args[0]
            values = [x.value for x in ts]
            if values == [250]:
                line('pc_cli();')
            elif values == [251]:
                line('pc_sti();')
            else:
                pat = [255, '/', 54, '/', '>', None, '+', 2, '/', 255, '/', 54, '/', '>',
                     None, '/', 91, '/', 88, '/', 135, '/', 94, '/', 14, '/', 135, '/', 70, '/', 16, '/', 137,
                     '/', 236, '/', 93, '/', 7, '/', 31, '/', 95, '/', 94, '/', 90, '/', 89, '/', 203]
                dead = [228, 97, 138, 224, 12, 128, 230, 97, 134, 224, 230, 97, 128, 32, 230, 32]
                if len(values) == len(pat) and all((p is None or p == v for (p, v) in zip(pat,
                     values))) and (values[5] == values[14]):
                    sym = self.routine.body_scope.find(ts[5].text)
                    if not sym or sym.type.kind != 'pointer':
                        self.fail(Expr('inline', token=s.token), 'invalid interrupt chaining pointer')
                    line('__TP_FRAME_END__')
                    line(f'pc_chain_interrupt({sym.cname});')
                    line('return;')
                    self.chain_seen = True
                elif [v for v in values if v != '/'] == dead and getattr(self, 'chain_seen', False):
                    line('/* Unreachable acknowledgement after the interrupt chain. */')
                else:
                    self.fail(Expr('inline', token=s.token), 'unsupported inline sequence')
        else:
            self.fail(Expr('stmt', token=s.token), f'unsupported statement {op}')
        return out

    def prototype(self, r, adapter=False):
        vs = []
        if r.scope.routine:
            vs.append(f'struct {r.scope.routine.cname}_env *tp_parent')
        for p in r.params:
            ct = 'farptr' if r.external and (p.byref or (p.type.kind == 'string' and (not adapter))) else p.type.cname + ' *' if p.byref else 'tp_string' if p.type.kind == 'string' else p.type.cname
            vs.append(ct + ' ' + p.cname)
        ret = 'tp_string' if r.type.kind == 'string' else r.type.cname
        return f"{ret} {r.cname}({', '.join(vs) or 'void'})"

    def typedef(self, t):
        name = t.cname
        if t.kind == 'array':
            bounds = ', '.join((f'{lo}..{hi}' for (lo, hi) in t.bounds))
            dimensions = ''.join((f'[{hi - lo + 1}]' for (lo, hi) in t.bounds))
            return f'/* array [{bounds}] of {t.elem.cname}; use accessors for unchecked indices */\ntypedef struct {{ union {{ uint8_t bytes[{t.size}]; {t.elem.cname} items{dimensions}; }}; }} {name};\n_Static_assert(sizeof({name}) == {t.size}, "TP array size");'
        if t.kind == 'string':
            return f'typedef struct {{ uint8_t b[{t.size}]; }} {name};'
        if t.kind == 'set':
            return f'typedef struct {{ uint8_t b[{t.size}]; }} {name};'
        if t.kind == 'record':
            # Anonymous packed views expose all fields, including overlapping
            # variants. Each view starts at the TP-computed field offset.
            lines = ['#pragma pack(push, 1)', f'typedef struct {{ union {{ uint8_t tp_bytes[{t.size}];']
            for (field, ft, offset) in t.fields.values():
                padding = f'uint8_t tp_padding_{field}[{offset}]; ' if offset else ''
                lines.append(f'    struct {{ {padding}{ft.cname} {field}; }};')
            lines.extend([f'}}; }} {name};', '#pragma pack(pop)', f'_Static_assert(sizeof({name}) == {t.size}, "TP record size");'])
            for (field, ft, offset) in t.fields.values():
                lines.append(f'_Static_assert(offsetof({name}, {field}) == {offset}, "TP field offset");')
            return '\n'.join(lines)
        raise CompileError('internal: unexpected emitted type ' + t.kind)

    def routinecode(self, r):
        if r.external:
            return []
        if r.body is None:
            r.token.error('routine has no implementation')
        self.routine = r
        self.chain_seen = False
        self.frame_needed = False
        token = getattr(r, 'implementation_token', r.token)
        self.comment_range = (token.line, getattr(r.body, 'end_line', token.line))
        out = [f'/* {token.file}:{token.line} */', self.prototype(r) + ' {', '    pc_poll();']
        if r.scope.routine:
            out.append('    (void)tp_parent;')
        if r.type is not VOID:
            out.append(f"    {('tp_string' if r.type.kind == 'string' else r.type.cname)} tp_result = {{0}};")
        for s in r.locals:
            if s.value is not None:
                s.token.error('local absolute variable is not implemented')
            out.append(f'    {s.type.cname} {s.cname} = {{0}};')
        if r.nested:
            vals = []
            if r.scope.routine:
                vals.append('tp_parent')
            vals.extend((s.cname if s.byref else '&' + s.cname for s in r.params + r.locals))
            out.append(f"    struct {r.cname}_env tp_frame = {{{', '.join(vals)}}};")
        out.extend(self.statement(r.body))
        out.extend(('    ' + line for line in self.comments_before(token.file, self.comment_range[1] + 1)))
        self.analyze_locals(r)
        # Explicitly mark retained write-only/uninitialized policy locals as used.
        for s in r.locals:
            out.append(f'    (void){s.cname};')
        if self.frame_needed:
            out.insert(2, '    uint16_t tp_frame_mark = tp_FrameBegin();')
            out.append('    tp_FrameEnd(tp_frame_mark);')
        if r.type is not VOID:
            out.append('    return tp_result;')
        out.append('}')
        ending = 'tp_FrameEnd(tp_frame_mark); ' if self.frame_needed else ''
        return [line.replace('__TP_FRAME_END__', ending) for line in out if line.strip() != '__TP_FRAME_END__' or self.frame_needed]

    def initbytes(self, t, v):
        if t.kind in ('ordinal', 'bool', 'char', 'pointer'):
            if isinstance(v, bytes):
                v = v[0]
            return (v & (1 << 8 * t.size) - 1).to_bytes(t.size, 'little')
        if t.kind == 'string':
            v = v[:t.size - 1]
            return bytes([len(v)]) + v + bytes(t.size - 1 - len(v))
        if t.kind == 'array':
            if isinstance(v, bytes):
                return v[:t.size] + bytes(max(0, t.size - len(v)))
            elem = t.elem
            if len(t.bounds) > 1:
                size = elem.size
                for (lo, hi) in t.bounds[1:]:
                    size *= hi - lo + 1
                elem = Type('array', size=size, elem=t.elem, bounds=t.bounds[1:])
            expected = t.bounds[0][1] - t.bounds[0][0] + 1
            if len(v) != expected:
                raise CompileError('typed array initializer count mismatch')
            return b''.join((self.initbytes(elem, x) for x in v))
        if t.kind == 'record':
            out = bytearray(t.size)
            for (n, x) in v.items():
                (_, ft, off) = t.fields[n]
                out[off:off + ft.size] = self.initbytes(ft, x)
            return bytes(out)
        raise CompileError('unsupported initializer ' + t.kind)

    def write(self, path):
        prefix = self.c.prefix
        # Emit bodies first: type checking may create suffix-array types.
        sources = {}

        def allr(r):
            yield r
            for n in r.nested:
                yield from allr(n)
        routines = [r for u in self.c.units.values() for top in u.routines for r in allr(top)]
        for u in self.c.units.values():
            out = ['#include "generated.h"', '']
            first = min((getattr(r, 'implementation_token', r.token).line for r in u.routines if not r.external),
                 default=1)
            self.comment_range = None
            out.extend(self.comments_before(u.file, first))
            for top in u.routines:
                for r in reversed(list(allr(top))):
                    body = self.routinecode(r)
                    if body:
                        out.extend(body)
                        out.append('')
            self.routine = None
            self.comment_range = None
            init = self.statement(u.init)
            out.extend([f'void {prefix}{u.name}_init(void) {{', '    pc_poll();', *init, '}'])
            sources[u.file[:-4] + '.c'] = '\n'.join(out) + '\n'
        header = ['/* Generated from Pascal source; do not edit. */', '#ifndef ' + prefix.upper() + 'GENERATED_H',
             '#define ' + prefix.upper() + 'GENERATED_H', '#include "tp/tp.h"', f'extern uint16_t {prefix}ds;']
        header.extend((self.typedef(t) for t in self.c.types))
        # Field accessors preserve the 16-bit far-offset wrap that a native
        # record pointer's member access would lose at a segment boundary.
        records = [t for t in self.c.types if t.kind == 'record'] + [self.c.system.find('Registers').type]
        for t in records:
            for (field, ft, offset) in t.fields.values():
                helper = self.field_helper(t, field)
                header.append(f'#define {helper}(base) (*({ft.cname} *)pc_host_fp(tp_fp_add((base), offsetof({t.cname}, {field}))))')
        for (name, (t, count, result)) in self.array_accesses.items():
            indices = [f'i{j}' for j in range(count)]
            params = ', '.join(('int32_t ' + i for i in indices))
            terms = []
            for (j, index) in enumerate(indices):
                stride = t.elem.size
                for (lo, hi) in t.bounds[j + 1:]:
                    stride *= hi - lo + 1
                lo = t.bounds[j][0]
                # Unsigned calculation defines overflow; only its low word
                # reaches the emulated address. Negative indices also wrap.
                delta = f'(uint32_t){index}' if not lo else f'((uint32_t){index} - {lo & 4294967295}u)'
                terms.append(delta if stride == 1 else f'{delta} * {stride}u')
            offset = ' + '.join(terms)
            header.extend([f'static inline farptr {name}_fp(farptr base, {params}) {{',
                 f'    return tp_fp_add(base, tp_i32({offset}));', '}', f'static inline {result.cname} *{name}(farptr base, {params}) {{',
                 f"    return ({result.cname} *)pc_host_fp({name}_fp(base, {', '.join(indices)}));", '}',
                 f'static inline {result.cname} *{name}_host(void *base, {params}) {{', f'    return ({result.cname} *)((uint8_t *)base + tp_i32({offset}));',
                 '}'])
        for r in routines:
            if r.nested:
                header.append(f'struct {r.cname}_env {{')
                if r.scope.routine:
                    header.append(f'    struct {r.scope.routine.cname}_env *tp_parent;')
                header.extend((f'    {s.type.cname} *{s.cname};' for s in r.params + r.locals))
                header.append('};')
        for u in self.c.units.values():
            for s in u.globals:
                if s.value is not None and s.kind == 'global':
                    s.token.error('global absolute is not implemented')
                header.append(f'#define {s.cname} (*({s.type.cname} *)pc_host({prefix}ds, {s.offset}))')
                header.append(f'#define {self.global_far_name(s)} FP({prefix}ds, {s.offset})')
                if s.type.kind == 'array':
                    for count in range(1, len(s.type.bounds) + 1):
                        helper = s.type.cname + '_at' + str(count)
                        if helper not in self.array_accesses:
                            continue
                        indices = ', '.join((f'i{j}' for j in range(count)))
                        arguments = ', '.join((f'(i{j})' for j in range(count)))
                        tail = str(count) if len(s.type.bounds) > 1 else ''
                        header.append(f'#define {s.cname}_at{tail}({indices}) (*{helper}({s.cname}_fp, {arguments}))')
                        header.append(f'#define {s.cname}_addr{tail}({indices}) {helper}_fp({s.cname}_fp, {arguments})')
                        result = self.array_accesses[helper][2]
                        if result.kind == 'record':
                            for field, ft, offset in result.fields.values():
                                member = self.field_helper(result, field)
                                header.append(f'#define {s.cname}_at{tail}_{field}({indices}) {member}({s.cname}_addr{tail}({arguments}))')
            header.append(f'void {prefix}{u.name}_init(void);')
        for s in self.c.system.symbols.values():
            if s.kind == 'runtimevar' and s.name in self.c.runtime_symbols:
                header.append(f"#define {self.global_far_name(s)} FP({prefix}ds, {self.c.runtime_symbols[s.name]['offset']})")
        header.extend((self.prototype(r) + ';' for r in routines))
        for r in routines:
            if r.external and any((p.byref or p.type.kind == 'string' for p in r.params)):
                proto = self.prototype(r, adapter=True).replace(r.cname + '(', prefix + 'call_' + r.cname + '(')
                header.append('static inline ' + proto + ' {')
                owns_temporaries = any((p.type.kind == 'string' and (not p.byref) for p in r.params))
                if owns_temporaries:
                    header.append('    uint16_t tp_arg_mark = tp_FrameBegin();')
                vals = []
                for p in r.params:
                    if p.type.kind == 'string' and (not p.byref):
                        name = 'tp_far_' + p.cname
                        header.append(f'    farptr {name} = tp_TempFar({p.cname}.b, (uint16_t)({p.cname}.b[0]+1));')
                        vals.append(name)
                    else:
                        vals.append(p.cname)
                vals = ', '.join(vals)
                header.append('    tp_FarSyncIn();')
                if r.type is VOID:
                    header.append(f'    {r.cname}({vals});')
                else:
                    header.append(f'    {r.type.cname} result = {r.cname}({vals});')
                header.append('    tp_FarSyncOut();')
                if owns_temporaries:
                    header.append('    tp_FrameEnd(tp_arg_mark);')
                if r.type is not VOID:
                    header.append('    return result;')
                header.append('}')
        header.extend([f'void {prefix}run(void);', '#endif', ''])
        image = bytearray(self.c.ds_size)
        image[self.c.runtime_symbols['FileMode']['offset']] = 2
        for u in self.c.units.values():
            for s in u.globals:
                if s.kind == 'typedconst':
                    image[s.offset:s.offset + s.type.size] = self.initbytes(s.type, s.value)
        (path / 'ds.bin').write_bytes(image)
        game_libraries = 'pcxgenus' in self.c.units
        loader = ['#include "generated.h"']
        if game_libraries:
            loader.append('#include "lib/samlib.h"')
        loader.extend([f'uint16_t {prefix}ds;', f'static const uint8_t {prefix}data[{len(image)}] = {{'])
        for i in range(0, len(image), 24):
            loader.append('    ' + ','.join((str(x) for x in image[i:i + 24])) + ',')
        geometry = self.c.program_layout or (2048, 16384, 24576, 16384, 25600, 40960)
        layout = ', '.join((hex(x) for x in geometry))
        loader.extend(['};', f'void {prefix}run(void) {{', f'    const pc_program layout = {{{layout}}};',
             f'    pc_load_program(&layout, {prefix}data, sizeof({prefix}data));', f'    {prefix}ds = layout.ds_seg;',
             f'    tp_BindSystem(layout.ds_seg, {self.c.runtime_start});', f"    tp_BindStandardFiles({self.c.runtime_symbols['Input']['offset']}, {self.c.runtime_symbols['Output']['offset']});",
             '    tp_Init();'])
        if 'TextAttr' in self.c.runtime_symbols:
            crt_names = ('CheckBreak', 'CheckEOF', 'DirectVideo', 'CheckSnow', 'LastMode',
                 'TextAttr', 'WindMin', 'WindMax')
            offsets = ', '.join((str(self.c.runtime_symbols[n]['offset']) for n in crt_names))
            loader.extend([f'    const tp_crt_offsets crt_offsets = {{{offsets}}};', '    tp_BindCrt(layout.ds_seg, &crt_offsets);'])
        if game_libraries:
            byname = {s.name.lower(): s for u in self.c.units.values() for s in u.globals}
            fields = ('GenusPcxIdentity', 'PcxDisplayDescriptions', 'PcxSelectedDisplay',
                 'PcxGraphicsModeState', 'PcxDisplayPageState', 'PcxModeCheckPolicy', 'PcxDefaultReadBuffer',
                 'PcxReadState', 'PcxPrinterScanline', 'PcxPrintedSourceRow', 'PcxPrinterDeviceClass',
                 'PcxPrinterResolutionClass', 'PcxDisplayTable', 'PcxHerculesGraphicsCrtc', 'PcxHerculesTextCrtc',
                 'PcxPrinterState', 'TextVideoSegment', 'TextRetraceSyncEnabled', 'TextSavedBiosMode',
                 'TextVideoAdapterClass')
            loader.append('    const samlib_data_offsets lib_offsets = {')
            for n in fields:
                if n.lower() not in byname:
                    raise CompileError('assembly library DATA symbol missing: ' + n)
                loader.append(f'        .{n} = {byname[n.lower()].offset},')
            loader.extend(['    };', '    samlib_bind_data_offsets(&lib_offsets);'])
        for u in self.c.load_order[1:]:
            if u.name.lower() == 'crt':
                loader.append('    tp_CrtInit();')
            elif u.file:
                loader.append(f'    {prefix}{u.name}_init();')
        loader.append(f'    {prefix}{self.c.load_order[0].name}_init();')
        loader.append('    tp_Halt(0);')
        loader.extend(['}', ''])
        sources['loader.c'] = '\n'.join(loader)
        (path / 'generated.h').write_text('\n'.join(header))
        for (n, text) in sources.items():
            (path / n).write_text(text)
        (path / 'diagnostics.json').write_text(json.dumps({'local_initialization': 'zero; including original uninitialized reads',
             'possible_uninitialized_reads': self.notes, 'evaluation_order': self.order_notes, 'memory_layout_source': 'config/port.json' if self.c.program_layout else 'test geometry'},
             indent=2) + '\n')
