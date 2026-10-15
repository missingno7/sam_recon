"""Whole-DS libdiff regression for Genus video-descriptor initialization.

The reference is executed from the immutable original image, never embedded.
DATA offsets are read from pas2c's layout, not a dumped reference table.
"""
import ctypes as C
import json
from pathlib import Path
import sys
import random
import os
import copy
import subprocess
import lockstep

FIELDS = '''GenusPcxIdentity PcxDisplayDescriptions PcxSelectedDisplay
PcxGraphicsModeState PcxDisplayPageState PcxModeCheckPolicy PcxDefaultReadBuffer
PcxReadState PcxPrinterScanline PcxPrintedSourceRow PcxPrinterDeviceClass
PcxPrinterResolutionClass PcxDisplayTable PcxHerculesGraphicsCrtc
PcxHerculesTextCrtc PcxPrinterState TextVideoSegment TextRetraceSyncEnabled
TextSavedBiosMode TextVideoAdapterClass'''.split()

def call(m, name, words=()):
    target = m.routine_targets[name.upper()]
    m.set('ds',m.placement['ds_seg']); m.set('es',m.placement['ds_seg'])
    m.set('ss',m.placement['ss_seg']); m.set('sp',m.placement['sp'])
    for word in words: m.push(word)
    m.push(0xf000); m.push(0x5fe0)
    m.jump(target)
    m.depth = 1
    m.execute(until=0xf5fe0)
    if m.error: raise RuntimeError(m.error)
    assert m.get('sp') == m.placement['sp'], (name,'callee stack cleanup')

def vga(m):
    buf = C.create_string_buffer(4096)
    n = m.pc.pc_lockstep_vga(buf)
    return b''.join(C.string_at(m.pc.vga_plane(p),65536) for p in range(4)) + buf.raw[:n]

def main():
    root = Path(__file__).resolve().parents[1]
    build = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else root/'build/lockstep'
    results = []
    for episode in ('sam1','sam2','sam3'):
        args = lockstep.argparse.Namespace(library=build/('libsam_lockstep.dll' if os.name == 'nt' else 'libsam_lockstep.so'),
            generated=build/'port-gen',episode=episode,scenario=root/'tests/port/lockstep/boot.json',
            output=root/'build/lockstep-libcheck'/episode,side='original',
            map=root/'build/reference'/episode/'SAM.MAP',cpu_mhz=20)
        m = lockstep.Original(args)
        # Exercise every diagnostics-selected frame, including byte and aggregate
        # locals and scalar function results. Compare the entire poisoned frame
        # to prove that only selected objects are cleared, never padding/temps.
        for routine, proof in m.local_policy['proofs'].items():
            m.set('ss',m.placement['ss_seg']); m.set('sp',4096); m.set('bp',0x1234)
            m.jump(m.routine_targets[routine])
            bp=4094; start=bp-proof['allocated_bytes']
            poison=bytes([0xa5])*proof['allocated_bytes']
            C.memmove(m.base+m.placement['ss_seg']*16+start,poison,len(poison))
            expected=bytearray(poison)
            for slot in proof['locals']:
                off=proof['allocated_bytes']+slot['bp_offset']
                expected[off:off+slot['size']]=bytes(slot['size'])
            m.trace(routine)
            actual=C.string_at(m.base+m.placement['ss_seg']*16+start,len(poison))
            ok=actual==expected and m.get('sp')==4096 and m.get('bp')==0x1234
            results.append({'episode':episode,'routine':'zero-local exact frame: '+routine,'ok':ok})
            if not ok: raise RuntimeError('zero-local rule changed an unselected byte/register')
        # Corrupt generated metadata must fail closed before reference execution.
        altered=copy.deepcopy(m.diagnostics)
        note=altered['possible_uninitialized_reads'][0]
        altered['routine_frames'][note['routine']]['locals'][note['name']]['bp_offset']=-65536
        try:
            lockstep.policies(altered,m.routines,
                C.string_at(m.base+m.load_seg*16,(m.placement['ds_seg']-m.load_seg)*16),m.load_seg*16)
        except ValueError:
            rejected=True
        else:
            rejected=False
        results.append({'episode':episode,'routine':'zero-local rejects invalid frame metadata','ok':rejected})
        if not rejected: raise RuntimeError('invalid local layout was accepted')
        before = C.string_at(m.base+m.ds,m.layout['ds_size'])
        name = 'PCXINITIALIZEVIDEODESCRIPTORS'
        call(m,name)
        original = C.string_at(m.base+m.ds,m.layout['ds_size'])
        C.memmove(m.base+m.ds,before,len(before))
        offsets = (C.c_uint16 * len(FIELDS))(*[m.globals[n]['offset'] for n in FIELDS])
        m.pc.samlib_bind_data_offsets(offsets)
        m.pc.PcxInitializeVideoDescriptors()
        native = C.string_at(m.base+m.ds,len(before))
        differences = [i for i,(a,b) in enumerate(zip(original,native)) if a != b]
        result = {'episode':episode,'routine':name,'ok':not differences,
                  'compared_ds_bytes':len(before),'first_offsets':differences[:32],
                  'differing_bytes':len(differences),'original_instructions':m.instructions}
        results.append(result)
        print(json.dumps(result),flush=True)
        call(m,'PgSetScreenStride',[80])
        m.pc.PgSetScreenStride(80)
        rng = random.Random(71239)
        sprite = rng.randbytes(160)
        background = [rng.randbytes(65536) for _ in range(4)]
        for routine in ('PgBlitMasked16x16','PgBlitMaskedShifted16x16',
                        'PgBlitMaskedShifted8x8','PgOrShifted16x16'):
            for shift in range(8):
                x = 8+shift if routine == 'PgBlitMasked16x16' else 64+shift
                C.memmove(m.base+0x70100,sprite,len(sprite))
                m.pc.bios_set_mode(0x0d)
                for p,b in enumerate(background): C.memmove(m.pc.vga_plane(p),b,len(b))
                call(m,routine,[0x7000,0x100,x,48])
                reference = vga(m)
                m.pc.bios_set_mode(0x0d)
                for p,b in enumerate(background): C.memmove(m.pc.vga_plane(p),b,len(b))
                getattr(m.pc,routine)(C.c_uint32(0x70000100),C.c_int16(x),C.c_int16(48))
                native = vga(m)
                diff = [i for i,(a,b) in enumerate(zip(reference,native)) if a != b]
                result = {'episode':episode,'routine':routine,'shift':shift,'ok':not diff,
                          'compared_bytes':len(reference),'differing_bytes':len(diff),'first_offsets':diff[:8]}
                results.append(result)
                if diff: print(json.dumps(result),flush=True)
        key_vector = int.from_bytes(C.string_at(m.base+0x16*4,4),'little')
        assert m.pc.pc_lockstep_registered(key_vector)
        assert not m.pc.pc_lockstep_registered(0xf0007ffc)
        # Hardware IRQs preserve the saved flags even if the chained handler's
        # current CPU arithmetic flags differ. Software BIOS status must be
        # materialized in the return frame, not just copied into the CPU.
        m.set('ss',m.placement['ss_seg']); m.set('sp',m.placement['sp'])
        m.push(0x203); m.push(0x888); m.push(0x1234)
        irq=int.from_bytes(C.string_at(m.base+9*4,4),'little')
        m.jump(irq); m.set('eflags',0x242); m.service(irq)
        preserved=m.get('eflags')==0x203
        results.append({'episode':episode,'routine':'BIOS IRQ return preserves saved FLAGS','ok':preserved})
        if not preserved: raise RuntimeError('IRQ clobbered interrupted flags')
        C.memmove(m.base+0x41c,C.string_at(m.base+0x41a,2),2)
        m.set('sp',m.placement['sp']); m.push(0x202); m.push(0x888); m.push(0x1234)
        frame=m.get('ss')*16+m.get('sp')+4
        m.jump(key_vector); m.set('ax',0x100); m.set('eflags',0x202); m.service(key_vector)
        written=m.get('eflags')==0x242 and m.u16(frame)==0x242
        results.append({'episode':episode,'routine':'BIOS keyboard status writes IRET FLAGS','ok':written})
        if not written: raise RuntimeError('BIOS return flags were not materialized')
        # Runtime wait entry must sample guest IF, even if a preceding guest
        # CLI has not reached an ordinary polling batch yet. Delay(0) isolates
        # that synchronization without any timer/keyboard events.
        m.clock='wait'; m.pc.pc_lockstep_mode(1)
        m.pc.pc_lockstep_cpu_wait_mode(1,m.placement['ds_seg'])
        delay=(m.symbols.segments['CRT']<<16)|0x29e
        m.pc.pc_lockstep_cpu_delay((delay>>16)*16+(delay&65535))
        m.pc.pc_sti(); m.set('eflags',2); m.set('sp',m.placement['sp'])
        m.push(0); m.push(0xf000); m.push(0x5fe0); m.jump(delay)
        m.depth=1; m.execute(until=0xf5fe0)
        synced=not m.pc.pc_interrupts_enabled() and not (m.get('eflags')&0x200)
        results.append({'episode':episode,'routine':'Crt Delay wait samples guest IF','ok':synced})
        if not synced: raise RuntimeError('Delay used a stale platform IF')
        m.clock='instruction'; m.pc.pc_lockstep_mode(0)
        m.pc.pc_lockstep_cpu_wait_mode(0,m.placement['ds_seg']); m.pc.pc_sti()
        # A blocked C BIOS read must obey a test's time limit and unwind without
        # longjmp across Python or resuming the original with a fabricated key.
        m.script['max_time_us'] = 1
        regs = lockstep.Regs(ax=0)
        m.pc.pc_lockstep_call(key_vector,C.byref(regs))
        cancelled = bool(m.stopped and m.pc.pc_lockstep_aborted())
        results.append({'episode':episode,'routine':'BIOS blocking-read cancellation','ok':cancelled})
        if not cancelled: raise RuntimeError('blocking BIOS read did not cancel')
        m.pc.platform_shutdown()
    # A failing child cannot reuse retained success receipts from an older run.
    stale=root/'build/lockstep-libcheck/stale-receipts'
    stale.mkdir(parents=True,exist_ok=True)
    for side in ('original','port'):
        (stale/side).mkdir(exist_ok=True)
        (stale/side/'run.json').write_text('{"error": null}\n')
    (stale/'comparison.json').write_text('{"ok": true}\n')
    failed=subprocess.run([sys.executable,'-B',str(root/'tools/lockstep.py'),
        '--library',str(stale/'missing.dll'),'--output',str(stale)],
        stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    fresh=failed.returncode==2 and not (stale/'comparison.json').exists() and all(
        not (stale/side/'run.json').exists() for side in ('original','port'))
    results.append({'routine':'crashed child cannot reuse stale receipts','ok':fresh})
    if not fresh: raise RuntimeError(failed.stdout.decode(errors='replace'))
    dest = root/'build/lockstep-libcheck/checks.json'
    dest.parent.mkdir(parents=True,exist_ok=True)
    dest.write_text(json.dumps({'ok':all(r['ok'] for r in results),'results':results},indent=2)+'\n')
    return 0 if all(r['ok'] for r in results) else 1

if __name__ == '__main__':
    raise SystemExit(main())
