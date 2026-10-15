"""Differential original/translated execution on the very same emulated PC.

The optional SAM_LOCKSTEP CMake target supplies test instrumentation only.
Run --help; see tests/port/lockstep/README.md for synchronization and exclusions.
"""
from __future__ import annotations
import argparse
import ctypes as C
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import traceback
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
# In worker snapshots, use the enclosing checkout's pinned Python packages.
for parent in (ROOT, *ROOT.parents):
    vendor = parent / 'build/python'
    if vendor.is_dir():
        sys.path.insert(0, str(vendor))
        break
import common
import oracle
from lockstep_symbols import Symbols, pointer_fields, normalized_ds, canonical_name
from unicorn import (Uc, UC_ARCH_X86, UC_MODE_16, UC_PROT_ALL, UC_HOOK_CODE,
                     UC_HOOK_INTR, UC_HOOK_INSN, UC_HOOK_MEM_WRITE, UC_HOOK_MEM_READ)
from unicorn.x86_const import *
from unicorn.unicorn_py3.unicorn import uclib

class Regs(C.Structure):
    _fields_ = [(n, C.c_uint16) for n in 'ax bx cx dx bp si di ds es flags'.split()]
class Program(C.Structure):
    _fields_ = [(n, C.c_uint16) for n in 'psp_seg ds_seg ss_seg sp heap_org_seg mem_top_seg'.split()]

REG = {n: globals()['UC_X86_REG_' + n.upper()] for n in
       'ax bx cx dx bp si di ds es ss sp cs ip eflags'.split()}
EXTERNAL = C.CFUNCTYPE(None, C.c_uint32)
EXTERNAL_IRQ = C.CFUNCTYPE(None, C.c_uint8)
OBSERVER = C.CFUNCTYPE(C.c_int, C.c_int, C.c_char_p)

def bind(dll):
    signatures = {
        'platform_init': (C.c_int, [C.c_int, C.POINTER(C.c_char_p)]),
        'platform_run': (C.c_int, [C.c_void_p]),
        'pc_load_program': (None, [C.POINTER(Program), C.c_void_p, C.c_size_t]),
        'pc_clock_manual': (None, [C.c_int]), 'pc_clock_advance': (None, [C.c_uint64]),
        'pc_time_us': (C.c_uint64, []), 'pc_irq_count': (C.c_uint64, [C.c_uint]),
        'pc_lockstep_mode': (None,[C.c_int]),
        'pc_lockstep_wait': (None,[C.c_uint]),
        'pc_lockstep_flush': (None,[]),
        'pc_lockstep_code_name': (C.c_char_p,[C.c_uint32]),
        'pc_lockstep_cpu_wait_mode': (None,[C.c_int,C.c_uint16]),
        'pc_lockstep_cpu_wait_point': (None,[C.c_uint64,C.c_uint,C.c_int]),
        'pc_lockstep_cpu_skip_wait': (None,[C.c_uint64]),
        'pc_lockstep_cpu_delay': (None,[C.c_uint64]),
        'pc_lockstep_cpu_host_write': (None,[C.c_uint16,C.c_uint16,C.c_void_p,C.c_uint,C.c_char_p]),
        'pc_lockstep_cpu_stack_write': (None,[C.c_uint16,C.c_uint16,C.c_uint,C.c_uint64,C.c_uint32]),
        'pc_lockstep_cpu_stack_start': (C.c_uint,[C.c_uint]),
        'pc_lockstep_cpu_stack_byte': (C.c_uint,[C.c_uint]),
        'pc_lockstep_cpu_stack_last': (C.c_char_p,[C.c_uint,C.POINTER(C.c_uint64),C.POINTER(C.c_uint64),C.POINTER(C.c_uint32),C.POINTER(C.c_uint)]),
        'pc_lockstep_deadline': (C.c_uint64, []),
        'pc_lockstep_external': (None, [EXTERNAL]),
        'pc_lockstep_external_irq': (None, [EXTERNAL_IRQ]),
        'pc_lockstep_observer': (None, [OBSERVER]),
        'pc_lockstep_call': (None, [C.c_uint32, C.POINTER(Regs)]),
        'pc_lockstep_registered': (C.c_int, [C.c_uint32]),
        'pc_lockstep_cpu_setup': (None, [C.c_void_p]),
        'pc_lockstep_cpu_api': (None, [C.c_void_p, C.c_void_p, C.POINTER(C.c_int)]),
        'pc_lockstep_cpu_routine': (None, [C.c_uint64, C.c_char_p, C.c_int]),
        'pc_lockstep_cpu_prepare': (None, [C.c_uint64]),
        'pc_lockstep_cpu_break': (None, [C.c_int, C.c_uint64]),
        'pc_lockstep_cpu_count': (C.c_uint64, []),
        'pc_lockstep_cpu_iret': (None, []),
        'pc_lockstep_cpu_value': (C.c_uint64, []),
        'pc_lockstep_cpu_reason': (C.c_int, []),
        'pc_lockstep_cpu_recent': (C.c_char_p, [C.c_uint]),
        'pc_queue_scan': (None, [C.c_uint64, C.c_uint8]),
        'pc_inb': (C.c_uint8, [C.c_uint16]), 'pc_inw': (C.c_uint16, [C.c_uint16]),
        'pc_outb': (None, [C.c_uint16, C.c_uint8]),
        'pc_outw': (None, [C.c_uint16, C.c_uint16]),
        'vga_cpu_read': (C.c_uint8, [C.c_uint16]),
        'vga_cpu_write': (None, [C.c_uint16, C.c_uint8]),
        'vga_plane': (C.c_void_p, [C.c_int]),
        'platform_screenshot': (C.c_int, [C.c_char_p]),
    }
    for n in ('vga', 'devices', 'speaker'):
        signatures['pc_lockstep_' + n] = (C.c_size_t, [C.c_void_p])
    for name, (ret, args) in signatures.items():
        fn = getattr(dll, name)
        fn.restype, fn.argtypes = ret, args
    return dll

class Machine:
    def __init__(self, args):
        self.args = args
        if os.name == 'nt':
            C.windll.kernel32.SetErrorMode(3)
            self.dll_dirs = [os.add_dll_directory(str(p)) for p in
                (args.library.parent, Path('C:/msys64/mingw64/bin'),
                 Path('C:/tools/sdl3-3.4.16-mingw/SDL3-3.4.16/x86_64-w64-mingw32/bin'))]
        self.pc = bind(C.CDLL(str(args.library.resolve())))
        self.mem = (C.c_uint8 * 0x110000).in_dll(self.pc, 'pc_mem')
        self.base = C.addressof(self.mem)
        self.layout = json.loads((args.generated / args.episode / 'layout.json').read_text())
        self.globals = self.layout['globals'] | self.layout.get('runtime_symbols', {})
        self.placement = json.loads((ROOT / 'config/port.json').read_text())['episodes'][args.episode]
        self.ds = self.placement['ds_seg'] * 16
        self.script = json.loads(args.scenario.read_text())
        self.events = list(self.script.get('events', []))
        for e in self.events:
            if sum(k in e for k in ('time_us','frame','poll','after','wait')) != 1 or not e.get('scan'):
                raise ValueError('each input needs exactly one trigger and at least one scan byte')
            if any(not isinstance(s,int) or not 0 <= s <= 255 for s in e['scan']):
                raise ValueError('XT scan events must be bytes')
        self.delivered = set()
        self.frames, self.checkpoints, self.polls, self.waits = 0, 0, 0, 0
        self.wait_kinds = {}
        self.visit_waits = {}
        self.sound_calls = []
        self.rng_log = []
        self.clock = getattr(args,"clock","instruction")
        self.wall_start=time.monotonic()
        self.wall_beat=self.wall_start
        self.wait_tail = []
        self.history = []
        self.visits = {}
        self.visit_times = {}
        self.log = []
        self.error = None
        self.stopped = False
        self.exited = False
        self.last_tick = 0
        self.last_irq = 0
        self.heartbeat = -1
        self.frame_start = None
        self.work = []
        self.output = args.output / args.side
        self.output.mkdir(parents=True, exist_ok=True)
        (self.output/'pid.txt').write_text(str(os.getpid()))
        # Each side gets writable private files; never write through the asset junction.
        self.data = Path(tempfile.mkdtemp(prefix='data-',dir=self.output))
        import shutil
        for p in common.asset_dir().iterdir():
            if p.is_file() and p.suffix.upper() != '.EXE':
                shutil.copyfile(p, self.data / p.name)
        argv = [b'lockstep', b'--headless', b'--no-audio', b'--data', os.fsencode(self.data)]
        array = (C.c_char_p * len(argv))(*argv)
        if not self.pc.platform_init(len(argv), array):
            raise RuntimeError('platform_init failed')
        self.pc.pc_clock_manual(1)
        self.pc.pc_lockstep_mode(self.clock=="wait")
        self.observer = OBSERVER(self.observe)
        self.pc.pc_lockstep_observer(self.observer)
        self.pc.pc_lockstep_keyboard_observe(int(any('poll' in e for e in self.events)))
        self.tick_offset = self.globals['GameTickCounter']['offset']
        self.symbols=Symbols(args.map,self.placement['psp_seg']+16)

    def u16(self, addr):
        return int.from_bytes(C.string_at(self.base + addr, 2), 'little')

    def value(self, name):
        s = self.globals[name]
        return int.from_bytes(C.string_at(self.base + self.ds + s['offset'], s['size']), 'little')

    def inputs(self):
        now = self.pc.pc_time_us()
        for i, e in enumerate(self.events):
            if i in self.delivered:
                continue
            match = (('time_us' in e and now >= e['time_us']) or
                     ('frame' in e and self.frames >= e['frame']) or
                     ('poll' in e and self.polls >= e['poll']) or
                     ('wait' in e and self.waits >= e['wait']))
            if 'after' in e:
                times = self.visit_times.get(e['after'].upper(),[])
                visit = e.get('visit',1)
                anchor = times[visit-1] if 0 < visit <= len(times) else None
                if 'delay_waits' in e:
                    anchors=self.visit_waits.get(e['after'].upper(),[])
                    match=0<visit<=len(anchors) and self.waits>=anchors[visit-1]+e['delay_waits']
                else:
                    match = anchor is not None and now >= anchor + e.get('delay_us',0)
            if match:
                for scan in e['scan']:
                    self.pc.pc_queue_scan(now, scan)
                self.delivered.add(i)
                self.log.append({'input': e, 'time_us': now, 'frame': self.frames, 'poll': self.polls, 'wait':self.waits})

    def observe(self, kind, name):
        try:
            if self.args.side == 'original' and kind == 1 and hasattr(self,'accounted'):
                self.sync_clock()
            if name and kind == 1:
                self.trace(name.decode())
            if kind == 0:
                if time.monotonic()-self.wall_start>getattr(self.args,'wall_timeout',300):
                    self.error='wall-clock watchdog: scenario did not complete'
                self.inputs()
                beat = self.pc.pc_time_us() // 500000
                if beat > self.heartbeat:
                    self.heartbeat = beat
                    print('clock',self.args.side,self.pc.pc_time_us(),self.frames,flush=True)
                if self.pc.pc_time_us() >= self.script.get('max_time_us', 30_000_000):
                    self.stopped = True
            if kind == 3:
                self.last_tick = self.u16(self.ds + self.tick_offset)
            if kind == 5:
                self.waits += 1
                key=name.decode()
                self.wait_kinds[key]=self.wait_kinds.get(key,0)+1
                self.wait_tail.append(key); self.wait_tail=self.wait_tail[-32:]
                self.inputs()
            if kind == 4:
                self.polls += 1
                self.inputs()
            if kind == 2 and self.args.side == 'port':
                tick = self.u16(self.ds + self.tick_offset)
                if self.last_tick >= 8 and tick == 0 and name and name.endswith(b'_SAMMAIN_init'):
                    self.boundary(self.last_tick)
                self.last_tick = tick
            return int((self.args.side == 'port' or kind == 0) and (self.stopped or self.error is not None))
        except BaseException:
            self.error = traceback.format_exc()
            return int(self.args.side == 'port' or kind == 0)

    def trace(self, name):
        self.history.append(name)
        self.history = self.history[-32:]
        # Optional routine-entry checkpoints diagnose boot before the first frame.
        wanted = self.script.get('checkpoints', [])
        plain = re.sub(r'^s[123]_', '', name).upper()
        if plain == 'SHOWGAMEDRAWBUFFER' and self.frame_start is not None:
            record = {'frame':self.frames,'work_to_present_us':self.pc.pc_time_us()-self.frame_start[0]}
            if self.args.side == 'original':
                record['instructions_to_present'] = self.instructions-self.frame_start[1]
            self.work.append(record)
        if plain not in self.visits:
            self.visits[plain] = self.pc.pc_time_us()
        self.visit_waits.setdefault(plain,[]).append(self.waits)
        if plain=='TP.RANDOM': self.rng_log.append({'wait':self.waits,'seed':self.value('RandSeed')})
        if plain=='STARTSOUNDEFFECT' and self.args.side=='original': self.sound_call()
        self.visit_times.setdefault(plain,[]).append(self.pc.pc_time_us())
        if plain in [n.upper() for n in wanted]:
            self.snapshot('checkpoint-' + plain)

    def boundary(self, ticks):
        self.frames += 1
        self.snapshot('frame', ticks)
        self.frame_start = (self.pc.pc_time_us(),self.instructions if self.args.side == 'original' else 0)
        self.inputs()
        if self.frames >= self.script.get('frames', 100):
            self.stopped = True

    def snapshot(self, kind, ticks=None):
        if self.args.side == 'original':
            self.history = [n.decode() for i in range(32) if (n := self.pc.pc_lockstep_cpu_recent(i))]
        number = self.checkpoints
        self.checkpoints += 1
        stem = f'{number:05d}-{kind}'
        regions = {}
        def save(n, b):
            (self.output / (stem + '.' + n + '.bin')).write_bytes(b)
            regions[n] = {'size':len(b), 'sha256':hashlib.sha256(b).hexdigest()}
        raw_ds=C.string_at(self.base+self.ds,self.layout['ds_size'])
        save('ds',raw_ds)
        pointers={}
        for label,off in pointer_fields(self.globals):
            value=int.from_bytes(raw_ds[off:off+4],'little')
            native=self.pc.pc_lockstep_code_name(value)
            name=('NULL' if not value else canonical_name(native.decode()) if native else self.symbols.original(value) if self.args.side=='original' else None)
            pointers[label]={'offset':off,'address':f'{value>>16:04x}:{value&65535:04x}','name':name}
        save('ds_comparable',normalized_ds(raw_ds,self.globals,pointers))
        # Include the entire heap arena, also free bytes and allocator metadata.
        start = self.placement['heap_org_seg'] * 16
        end = self.placement['mem_top_seg'] * 16
        save('heap', C.string_at(self.base + start, end - start))
        save('keyboard', C.string_at(self.base + 0x417, 0x27) +
             C.string_at(self.base + 0x480,4) + C.string_at(self.base + 0x496,1))
        for p in range(4):
            save('plane' + str(p), C.string_at(self.pc.vga_plane(p), 65536))
        for n in ('vga', 'devices', 'speaker'):
            export = getattr(self.pc, 'pc_lockstep_' + n)
            size = export(None)
            buffer = C.create_string_buffer(size)
            if export(buffer) != size:
                raise RuntimeError('device state changed during snapshot')
            save(n, buffer.raw[:size])
        irq = self.pc.pc_irq_count(8)
        meta = {'kind':kind, 'frame':self.frames, 'stem':stem, 'regions':regions, 'code_pointers':pointers,
                'time_us':self.pc.pc_time_us(), 'ticks_at_gate':ticks,
                'irq0_since_previous':irq-self.last_irq, 'irq0_total':irq,
                'routines':self.history.copy(), 'polls':self.polls, 'waits':self.waits, 'wait_tail':self.wait_tail.copy()}
        meta['state']={n:self.value(n) for n in ('CurrentLevelNumber','EnteredLevelNumber','PlayerHealth','PlayerDying','PlayerScore','PlayerAmmo','PlayerJumping','HasKeyOne','HasKeyTwo','HasKeyThree') if n in self.globals}
        actor=self.ds+self.globals['GameActors']['offset']
        meta['state']['player_x']=self.u16(actor+2); meta['state']['player_y']=self.u16(actor+4)
        if self.args.side == 'original': meta['instructions'] = self.instructions
        self.last_irq = irq
        self.log.append(meta)
        if (self.frames in self.script.get('screenshots', []) or kind != 'frame'):
            self.pc.platform_screenshot(os.fsencode(self.output / (stem + '.png')))
        print(self.args.side, self.args.episode, kind, self.frames, meta['time_us'], flush=True)

    def finish(self):
        summary = {'side':self.args.side, 'episode':self.args.episode, 'frames':self.frames,
                   'checkpoints':self.checkpoints, 'error':self.error, 'log':self.log,
                   'time_us':self.pc.pc_time_us(), 'program_exited':self.exited,'events_delivered':len(self.delivered),'data_dir':str(self.data),
                   'waits':self.waits, 'wait_kinds':self.wait_kinds, 'sound_calls':self.sound_calls,'rng_log':self.rng_log,
                   'routines':self.history, 'visits':self.visits,'frame_work':self.work,
                   'coverage':{n:n.upper() in self.visits for n in self.script.get('required_routines',[])}}
        if self.args.side == 'original':
            summary['instructions'] = self.instructions
            summary['instructions_per_us'] = self.args.cpu_mhz
        (self.output / 'run.json').write_text(json.dumps(summary, indent=2) + '\n')
        self.pc.platform_shutdown()
        return 1 if self.error else 0

class Original(Machine):
    def __init__(self, args):
        super().__init__(args)
        self.cpu = Uc(UC_ARCH_X86, UC_MODE_16)
        # All RAM is the DLL's actual pc_mem, including IVT, BDA, DS, stack and heap.
        self.cpu.mem_map_ptr(0, 0xa0000, UC_PROT_ALL, self.base)
        self.cpu.mmio_map(0xa0000, 0x10000, self.video_read, None, self.video_write, None)
        self.cpu.mem_map_ptr(0xb0000, 0x50000, UC_PROT_ALL, self.base + 0xb0000)
        # 20-bit wrap aliases, never a second copy.
        self.cpu.mem_map_ptr(0x100000, 0x10000, UC_PROT_ALL, self.base)
        layout = Program(**self.placement)
        self.pc.pc_load_program(C.byref(layout), None, 0)
        oracle.OUT = ROOT / 'build/oracle'
        image, relocations = oracle.load_image(args.episode)
        data = bytearray(image)
        self.load_seg = self.placement['psp_seg'] + 16
        for seg, off in relocations:
            at = seg * 16 + off
            v = (int.from_bytes(data[at:at+2], 'little') + self.load_seg) & 65535
            data[at:at+2] = v.to_bytes(2, 'little')
        C.memmove(self.base + self.load_seg * 16, bytes(data), len(data))
        h = common.load_json(oracle.LOCK)['episodes'][args.episode]['unpacked']
        for name, value in dict(cs=self.load_seg+h['cs'], ip=h['ip'],
                ss=self.placement['ss_seg'], sp=h['sp'], ds=self.placement['psp_seg'],
                es=self.placement['psp_seg'], eflags=0x202).items():
            self.set(name, value)
        text = args.map.read_text()
        code_end = (self.placement['ds_seg'] - self.load_seg) * 16
        self.routines = {self.load_seg*16+int(s,16)*16+int(o,16):n for s,o,n in
                re.findall(r'^ ([0-9A-F]{4}):([0-9A-F]{4})\s+(\S+)\s*$',text,re.M)
                if int(s,16)*16+int(o,16) < code_end}
        self.routine_targets = {n:((self.load_seg+int(s,16))<<16)|int(o,16) for s,o,n in
                re.findall(r'^ ([0-9A-F]{4}):([0-9A-F]{4})\s+(\S+)\s*$',text,re.M)
                if int(s,16)*16+int(o,16) < code_end}
        # Private TP routines have identities established from runtime call roles.
        for pointer,name in self.symbols.names.items():
            linear=(pointer>>16)*16+(pointer&65535)
            if linear<self.ds: self.routines.setdefault(linear,name)
        self.routines[self.symbols.segments['CRT']*16+0x29e]='Crt.Delay'
        self.accounted = 0
        self.pending = None
        self.depth = 0
        self.external_count = 0
        self.external = EXTERNAL(self.external_call)
        self.pc.pc_lockstep_external(self.external)
        self.external_irq = EXTERNAL_IRQ(lambda n:self.external_call(
            int.from_bytes(C.string_at(self.base+n*4,4),'little')))
        self.pc.pc_lockstep_external_irq(self.external_irq)
        # Register the C callback through the pinned Unicorn ABI to avoid a Python
        # round trip on every instruction. There are no CPU semantics in this hook.
        self.pc.pc_lockstep_cpu_setup(C.cast(uclib.uc_emu_stop,C.c_void_p))
        ids = (C.c_int * 15)(*[REG[n if n != 'flags' else 'eflags'] for n,_ in Regs._fields_],
                            REG['ss'],REG['sp'],REG['eflags'],REG['cs'],REG['ip'])
        self.pc.pc_lockstep_cpu_api(C.cast(uclib.uc_reg_read,C.c_void_p),
                                    C.cast(uclib.uc_reg_write,C.c_void_p),ids)
        notify = {n.upper() for n in self.script.get('checkpoints',[])} | {
            e['after'].upper() for e in self.events if 'after' in e}
        notify.update(('SHOWGAMEDRAWBUFFER','STARTSOUNDEFFECT'))
        notify.update(n.upper() for n in self.script.get('required_routines',[]))
        for addr,name in self.routines.items():
            self.pc.pc_lockstep_cpu_routine(addr,name.encode(),int(name.upper() in notify))
        self.pc.pc_lockstep_cpu_routine(self.symbols.segments['SYSTEM']*16+0x980,b'TP.Random',1)
        self.pc.pc_lockstep_cpu_wait_mode(self.clock=='wait',self.placement['ds_seg'])
        if self.clock=='wait': self.setup_wait_watches(bytes(data),text)
        self.native_stack_hook=C.c_size_t()
        status=uclib.uc_hook_add(self.cpu._uch,C.byref(self.native_stack_hook),UC_HOOK_MEM_WRITE,
            C.cast(self.pc.pc_lockstep_cpu_memory_write,C.c_void_p),None,
            self.placement['ss_seg']*16,self.placement['ss_seg']*16+self.placement['sp']-1)
        if status: raise RuntimeError('stack write watch registration failed')
        self.native_hook = C.c_size_t()
        status = uclib.uc_hook_add(self.cpu._uch,C.byref(self.native_hook),UC_HOOK_CODE,
            C.cast(self.pc.pc_lockstep_cpu_hook,C.c_void_p),None,1,0)
        if status: raise RuntimeError('native Unicorn hook registration failed: '+str(status))
        self.native_intr = C.c_size_t()
        status = uclib.uc_hook_add(self.cpu._uch,C.byref(self.native_intr),UC_HOOK_INTR,
            C.cast(self.pc.pc_lockstep_cpu_interrupt,C.c_void_p),None,1,0)
        if status: raise RuntimeError('native interrupt hook registration failed: '+str(status))
        self.cpu.hook_add(UC_HOOK_MEM_WRITE, self.write, begin=self.ds+self.tick_offset,
                          end=self.ds+self.tick_offset+1)
        self.cpu.hook_add(UC_HOOK_INSN, self.input_port, None, 1, 0, UC_X86_INS_IN)
        self.cpu.hook_add(UC_HOOK_INSN, self.output_port, None, 1, 0, UC_X86_INS_OUT)

    def setup_wait_watches(self,image,map_text):
        from capstone import Cs, CS_ARCH_X86, CS_MODE_16, CS_AC_READ, CS_AC_WRITE
        from capstone.x86_const import X86_OP_MEM,X86_REG_ES,X86_REG_DI,X86_REG_DS
        md=Cs(CS_ARCH_X86,CS_MODE_16); md.detail=True; md.skipdata=True
        self.segments={n:int(a,16) for a,n in re.findall(r'^ ([0-9A-F]+)H\s+[0-9A-F]+H\s+[0-9A-F]+H\s+(\w+)\s+CODE',map_text,re.M)}
        code_end=(self.placement['ds_seg']-self.load_seg)*16
        boundaries=sorted(set([a-self.load_seg*16 for a in self.routines]+list(self.segments.values())+[code_end]))
        self.clock_watches=[]
        for a,b in zip(boundaries,boundaries[1:]):
            for ins in md.disasm(image[a:b],a):
                if not ins.id: continue
                for op in ins.operands:
                    if op.type!=X86_OP_MEM or not (op.access&CS_AC_READ) or op.access&CS_AC_WRITE: continue
                    m=op.mem
                    if m.disp in (self.tick_offset,self.globals['LastKeyboardScanCode']['offset'],self.globals['SoundPlaying']['offset']) and not m.base and not m.index and m.segment in (0,X86_REG_DS):
                        self.pc.pc_lockstep_cpu_wait_point(ins.address+self.load_seg*16,0x10000 if m.disp==self.tick_offset else 0x60 if m.disp==self.globals['LastKeyboardScanCode']['offset'] else 0x10003,0)
                        self.clock_watches.append({'address':hex(ins.address),'kind':'GameTickCounter' if m.disp==self.tick_offset else 'LastKeyboardScanCode' if m.disp==self.globals['LastKeyboardScanCode']['offset'] else 'SoundPlaying','instruction':ins.mnemonic+' '+ins.op_str})
                    if (self.segments['CRT']<=ins.address<self.segments['CRT']+0x99 or
                        ins.address==self.segments['CRT']+0x2be) and m.segment==X86_REG_ES and m.base==X86_REG_DI:
                        self.pc.pc_lockstep_cpu_wait_point(ins.address+self.load_seg*16,0x10002,1)
        self.pc.pc_lockstep_cpu_delay(self.load_seg*16+self.segments['CRT']+0x29e)
        (self.output/'clock-watches.json').write_text(json.dumps(self.clock_watches,indent=2))

    def sound_call(self):
        ss,sp,bp=self.get('ss'),self.get('sp'),self.get('bp')
        slot=(sp-6)&65535
        writers=[]
        for off in (slot,(slot+1)&65535):
            value=C.c_uint64(); count=C.c_uint64(); addr=C.c_uint32(); width=C.c_uint()
            name=self.pc.pc_lockstep_cpu_stack_last(off,C.byref(value),C.byref(count),C.byref(addr),C.byref(width))
            writers.append({'offset':off,'write_offset':self.pc.pc_lockstep_cpu_stack_start(off),
                'byte_value':self.pc.pc_lockstep_cpu_stack_byte(off),'routine':name.decode() if name else None,'value':value.value,
                'instruction_count':count.value,'pc_linear':addr.value,'width':width.value})
        self.sound_calls.append({'call':len(self.sound_calls)+1,'frame':self.frames,'wait':self.waits,
            'time_us':self.pc.pc_time_us(),'entry_ss':ss,'entry_sp':sp,'caller_bp':bp,
            'callee_bp':(sp-2)&65535,'callee_sp':slot,'slot_offset':slot,'slot_value':self.u16(ss*16+slot),
            'effect':self.u16(ss*16+((sp+4)&65535)),'playing':self.value('SoundPlaying'),
            'current_effect':self.value('CurrentSoundEffect'),'writers':writers})

    def get(self,n): return self.cpu.reg_read(REG[n])
    @property
    def instructions(self): return self.pc.pc_lockstep_cpu_count()
    def set(self,n,v): self.cpu.reg_write(REG[n],v)
    def push(self,v):
        sp = (self.get('sp') - 2) & 65535
        self.set('sp',sp)
        self.pc.pc_lockstep_cpu_stack_write(self.get('ss'),sp,2,v, self.get('cs')*16+self.get('ip'))
        C.memmove(self.base + self.get('ss')*16+sp, int(v & 65535).to_bytes(2,'little'),2)
    def pop(self):
        sp = self.get('sp')
        v = self.u16(self.get('ss')*16+sp)
        self.set('sp',(sp+2)&65535)
        return v
    def target(self): return (self.get('cs') << 16) | self.get('ip')
    def jump(self,target):
        self.set('cs',target >> 16)
        self.set('ip',target & 65535)
    def video_read(self, uc, off, size, data):
        return sum(self.pc.vga_cpu_read((off+i)&65535) << (8*i) for i in range(size))
    def video_write(self, uc, off, size, value, data):
        for i in range(size): self.pc.vga_cpu_write((off+i)&65535,(value>>(8*i))&255)
    def input_port(self, uc, port, size, data):
        self.sync_clock()
        return self.pc.pc_inw(port) if size == 2 else self.pc.pc_inb(port)
    def output_port(self, uc, port, size, value, data):
        self.sync_clock()
        (self.pc.pc_outw if size == 2 else self.pc.pc_outb)(port,value)
    def write(self, uc, access, addr, size, value, data):
        old = self.u16(self.ds+self.tick_offset)
        # The main program resets the gate; UI resets occur in other code segments.
        if size == 2 and value == 0 and old >= 8 and self.get('cs') == self.load_seg:
            self.pc.pc_lockstep_cpu_break(3,old)
            # Stop after the writing instruction, at the next instruction boundary.
    def service(self,target):
        r = Regs(**{n:self.get(n if n != 'flags' else 'eflags') & 65535 for n,_ in Regs._fields_})
        if os.environ.get('LOCKSTEP_TRACE'):
            print('BIOS',hex(target),hex(r.ax),hex(r.bx),hex(r.cx),hex(r.dx),flush=True)
        # INT services return CF/ZF in the saved FLAGS word; general IRQs preserve it.
        self.pc.pc_lockstep_call(target,C.byref(r))
        for n,_ in Regs._fields_:
            if n != 'flags': self.set(n,getattr(r,n))
        flag_address=self.get('ss')*16+((self.get('sp')+4)&65535)
        flags=self.u16(flag_address)
        name=self.pc.pc_lockstep_code_name(target)
        if name not in (b'BIOS IRQ0',b'BIOS IRQ1',b'BIOS IRET'):
            # A BIOS service returns status in its interrupted FLAGS word.
            # Materialize that write before IRET: stack residue is observable.
            flags=(flags & ~0x41) | (r.flags & 0x41) | 2
            data=flags.to_bytes(2,'little')
            C.memmove(self.base+flag_address,data,2)
            self.pc.pc_lockstep_cpu_host_write(self.get('ss'),(self.get('sp')+4)&65535,C.create_string_buffer(data),2,name or b'BIOS return')
        ip,cs,flags = self.pop(),self.pop(),self.pop()
        self.set('ip',ip); self.set('cs',cs)
        self.set('eflags',flags | 2)
        self.pc.pc_lockstep_cpu_iret()
        if self.clock=='wait':
            (self.pc.pc_sti if self.get('eflags')&0x200 else self.pc.pc_cli)()
            if target in (int.from_bytes(C.string_at(self.base+v*4,4),'little') for v in (0x16,0x1a)):
                self.pc.pc_lockstep_flush()
    def external_call(self,target):
        try:
            # The C BIOS calls an original ISR synchronously, as a hardware interrupt.
            return_address = self.get('cs')*16+self.get('ip')
            saved_cs, saved_ip, saved_flags = self.get('cs'),self.get('ip'),self.get('eflags')
            self.external_count += 1
            if os.environ.get('LOCKSTEP_TRACE'):
                print('IRQ enter',hex(target),'return',hex(return_address),'depth',self.depth,flush=True)
            self.push(self.get('eflags')); self.push(self.get('cs')); self.push(self.get('ip'))
            self.set('eflags',self.get('eflags') & ~0x300)
            self.jump(target)
            self.depth += 1
            self.execute(until=return_address)
            self.set('cs',saved_cs); self.set('ip',saved_ip); self.set('eflags',saved_flags)
            self.depth -= 1
            if os.environ.get('LOCKSTEP_TRACE'):
                print('IRQ leave',hex(self.get('cs')*16+self.get('ip')),'depth',self.depth,flush=True)
        except BaseException:
            self.error = traceback.format_exc()
    def execute(self,until=None):
        while not self.stopped and not self.error:
            if time.monotonic()-self.wall_beat>15:
                self.wall_beat=time.monotonic()
                print('CPU',hex(self.target()),'clock',self.pc.pc_time_us(),'instructions',self.instructions,'waits',self.waits,flush=True)
            if time.monotonic()-self.wall_start>getattr(self.args,"wall_timeout",300):
                self.error='wall-clock watchdog: scenario did not complete'; break
            address = self.get('cs')*16+self.get('ip')
            if address == until: return
            self.pc.pc_lockstep_cpu_prepare(until or 0xffffffffffffffff)
            remaining = self.pc.pc_lockstep_deadline()-self.pc.pc_time_us()
            budget = 2048 if self.clock=='wait' or self.depth else min(2048,max(1,remaining*self.args.cpu_mhz-(self.instructions-self.accounted)))
            self.cpu.emu_start(address,until or 0x110000,count=budget)
            self.sync_clock()
            reason = self.pc.pc_lockstep_cpu_reason()
            if reason == 1:
                self.pending = ('bios',self.target())
            elif reason == 2:
                return
            elif reason == 3:
                self.pending = ('frame',self.pc.pc_lockstep_cpu_value())
            elif reason == 7:
                (self.pc.pc_sti if self.get('eflags')&0x200 else self.pc.pc_cli)()
                self.pc.pc_lockstep_wait(self.pc.pc_lockstep_cpu_value())
                self.pc.pc_lockstep_cpu_skip_wait(self.get('cs')*16+self.get('ip'))
            elif reason == 8:
                (self.pc.pc_sti if self.get('eflags')&0x200 else self.pc.pc_cli)()
                ms=self.u16(self.get('ss')*16+((self.get('sp')+4)&65535))
                self.pc.pc_delay_ms(ms)
                # Charge only the wait, then execute TP's real Delay body with
                # zero productive-time cost. Its register/stack residue matters.
                self.pc.pc_lockstep_cpu_skip_wait(self.get('cs')*16+self.get('ip'))
            elif reason == 9:
                raise RuntimeError('unsupported original stack-store width: '+str(self.pc.pc_lockstep_cpu_value()))
            elif reason == 5:
                raise RuntimeError('original CPU division error')
            elif reason == 6:
                self.exited = self.stopped = True
                self.snapshot('exit')
            if self.pending:
                kind,value = self.pending
                self.pending = None
                if kind == 'bios': self.service(value)
                elif kind == 'frame': self.boundary(value)
            if not self.depth:
                (self.pc.pc_sti if self.get('eflags') & 0x200 else self.pc.pc_cli)()
                self.pc.pc_lockstep_cpu_poll()
        if until and not self.stopped and not self.error:
            raise RuntimeError('original ISR did not return')
    def sync_clock(self):
        if self.clock!='wait' and not self.depth:
            elapsed = (self.instructions-self.accounted)//self.args.cpu_mhz
            if elapsed:
                self.accounted += elapsed*self.args.cpu_mhz
                self.pc.pc_clock_advance(self.pc.pc_time_us()+elapsed)
    def run(self):
        try:
            self.execute()
        except BaseException:
            self.error = traceback.format_exc() + f'\nCS:IP={self.get("cs"):04x}:{self.get("ip"):04x}'
        return self.finish()

def state_coverage(run, script):
    """Check observed state, independently of merely visiting a routine."""
    frames={r['frame']:r['state'] for r in run['log'] if r.get('kind')=='frame'}
    results={}
    for check in script.get('required_states',[]):
        pool=[frames.get(check['frame'],{})] if 'frame' in check else list(frames.values())
        def matches(state):
            value=state.get(check['field'])
            if value is None: return False
            if 'equals' in check and value!=check['equals']: return False
            if 'min' in check and value<check['min']: return False
            if 'max' in check and value>check['max']: return False
            for op in ('equals_frame','differs_from_frame'):
                if op in check:
                    ref=frames.get(check[op],{}).get(check['field'])
                    if ref is None or (value==ref)!=(op=='equals_frame'): return False
            return True
        results[check['name']]=any(matches(state) for state in pool)
    return results

def compare(args):
    runs = {side:json.loads((args.output/side/'run.json').read_text()) for side in ('original','port')}
    snapshots = {s:[r for r in run['log'] if 'regions' in r] for s,run in runs.items()}
    result = {'ok':False,'episode':args.episode,'runs':runs,'first_divergence':None,
              'first_frame_divergence':None,'frame_comparisons':[],
              'exclusions':['stack segment and TP/C local storage','code segments and code-segment library scratch',
                            'unrelated IVT entries, PSP and environment','BDA outside keyboard state',
                            'host SDL/audio playback state'],
              'masked_ds_bytes':2,
              'comparison_rules':{'code-pointers':'nonzero pointers require the same established symbol identity; unknown identity fails',
                  'crt-calibration':'CrtPrivate.DelayCnt, exactly first two bytes; virtual CPU speed calibration',
                  'interrupt-flags':'Registers.Flags: compare CF/ZF/IF (0241h); other bits BIOS implementation defined'}}
    for a,b in zip(snapshots['original'],snapshots['port']):
        different = {}
        for region in a['regions']:
            if region=='ds': continue
            if a['regions'][region] != b['regions'][region]:
                aa = (args.output/'original'/(a['stem']+'.'+region+'.bin')).read_bytes()
                bb = (args.output/'port'/(b['stem']+'.'+region+'.bin')).read_bytes()
                offsets = [i for i,(x,y) in enumerate(zip(aa,bb)) if x != y]
                detail = {'bytes':len(offsets)+abs(len(aa)-len(bb)), 'first_offsets':offsets[:32]}
                if region == 'ds_comparable':
                    layout = json.loads((args.generated/args.episode/'layout.json').read_text())
                    symbols = layout['globals'] | layout.get('runtime_symbols',{})
                    detail['globals'] = {n:{'offset':s['offset'],'original':aa[s['offset']:s['offset']+s['size']].hex(),
                                'port':bb[s['offset']:s['offset']+s['size']].hex()} for n,s in symbols.items()
                                if any(s['offset'] <= i < s['offset']+s['size'] for i in offsets)}
                different[region] = detail
        pd={name:{'original':ptr,'port':b['code_pointers'].get(name)}
            for name,ptr in a['code_pointers'].items()
            if ptr['name'] is None or b['code_pointers'].get(name,{}).get('name')!=ptr['name']}
        if pd: different['code_pointers']={'bytes':4*len(pd),'pointers':pd}
        if a['time_us']!=b['time_us']: different['clock']={'bytes':0,'original':a['time_us'],'port':b['time_us']}
        if different or a['kind'] != b['kind']:
            detail = {'original':a,'port':b,'differences':different}
            if result['first_divergence'] is None: result['first_divergence'] = detail
            if a['kind'] == b['kind'] == 'frame' and result['first_frame_divergence'] is None:
                result['first_frame_divergence'] = detail
        if a['kind'] == b['kind'] == 'frame':
            result['frame_comparisons'].append({'frame':a['frame'],
                'equal':not different,'different_regions':list(different),
                'differing_globals':list(different.get('ds_comparable',{}).get('globals',{})),
                'bytes_by_region':{n:v['bytes'] for n,v in different.items()}})
    result['timer_measurements'] = {}
    for side,states in snapshots.items():
        frames = [s for s in states if s['kind'] == 'frame']
        steady = frames[1:]
        frame_irq_deltas=[b['irq0_total']-a['irq0_total'] for a,b in zip(frames,frames[1:])]
        result['timer_measurements'][side] = {'frames':len(frames),
            'first_frame_inherited_ticks':frames[0]['ticks_at_gate'] if frames else None,
            'steady_frames_with_eight_ticks':sum(s['ticks_at_gate'] == 8 for s in steady),
            'steady_frames_with_eight_irqs':sum(n==8 for n in frame_irq_deltas),
            'frame_irq_deltas':frame_irq_deltas,
            'work_measurement':'time to ShowGameDrawBuffer entry; includes scene/UI waits',
            'steady_tick_values':sorted({s['ticks_at_gate'] for s in steady}),
            'maximum_work_to_present_us':max((w['work_to_present_us'] for w in runs[side].get('frame_work',[])),default=None)}
    result['rng_consumption_equal']=runs['original'].get('rng_log')==runs['port'].get('rng_log')
    result['snapshot_counts_equal'] = len(snapshots['original']) == len(snapshots['port'])
    if not result['first_divergence']:
        result['ok'] = (len(snapshots['original']) == len(snapshots['port']) > 0 and
                        all(not r['error'] for r in runs.values()) and
                        all(r['program_exited'] if json.loads(args.scenario.read_text()).get('expect_exit') else r['frames'] >= json.loads(args.scenario.read_text()).get('frames',100) for r in runs.values()))
    result['state_coverage']={s:state_coverage(r,json.loads(args.scenario.read_text()))for s,r in runs.items()}
    result['coverage_complete'] = all(all(r.get('coverage',{}).values()) for r in runs.values()) and all(all(v.values())for v in result['state_coverage'].values())
    result['ok'] &= result['coverage_complete'] and result['rng_consumption_equal']
    (args.output/'comparison.json').write_text(json.dumps(result,indent=2)+'\n')
    print('PASS' if result['ok'] else 'DIVERGENCE / INCOMPLETE',args.output/'comparison.json')
    return 0 if result['ok'] else 1

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--episode',choices=('sam1','sam2','sam3'),default='sam1')
    ap.add_argument('--build',type=Path,default=ROOT/'build/lockstep')
    ap.add_argument('--library',type=Path)
    ap.add_argument('--generated',type=Path)
    ap.add_argument('--map',type=Path)
    ap.add_argument('--scenario',type=Path,default=ROOT/'tests/port/lockstep/boot.json')
    ap.add_argument('--output',type=Path,default=ROOT/'build/lockstep-results')
    ap.add_argument('--clock',choices=('wait','instruction'),default='wait')
    ap.add_argument('--wall-timeout',type=int,default=300,help='host watchdog seconds, independent of virtual time')
    ap.add_argument('--cpu-mhz',type=int,default=20,help='original instructions per microsecond')
    ap.add_argument('--side',choices=('original','port','compare'))
    args = ap.parse_args()
    if args.cpu_mhz < 1: ap.error('--cpu-mhz must be positive')
    args.library = args.library or args.build/('libsam_lockstep.dll' if os.name == 'nt' else 'libsam_lockstep.so')
    args.generated = args.generated or args.build/'port-gen'
    args.map = args.map or ROOT/'build/reference'/args.episode/'SAM.MAP'
    args.output.mkdir(parents=True,exist_ok=True)
    if args.side == 'compare': return compare(args)
    if args.side == 'original': return Original(args).run()
    if args.side == 'port':
        m = Machine(args)
        m.pc.platform_run(C.cast(getattr(m.pc,'s'+args.episode[-1]+'_run'),C.c_void_p))
        if not m.stopped and not m.error:
            m.exited=True
            m.snapshot('exit')
        return m.finish()
    for side in ('original','port'):
        cmd = [sys.executable,'-B',__file__,*sys.argv[1:],'--side',side]
        with (args.output/(side+'.log')).open('w') as log:
            p = subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT)
        print(side,'exit',p.returncode,flush=True)
        if p.returncode and not (args.output/side/'run.json').exists():
            print((args.output/(side+'.log')).read_text(errors='replace')[-4000:])
            return 2
    return compare(args)

if __name__ == '__main__':
    raise SystemExit(main())
