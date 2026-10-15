"""Measure a Windows child's total CPU seconds / elapsed seconds (one-core %).

Scripts drive the original game controls; warm-up/sampling windows are recorded.
No game memory, timer or generated-code instrumentation selects a scenario.
"""
from pathlib import Path
import argparse
import ctypes as C
from ctypes import wintypes as W
import json
import os
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]
kernel=C.WinDLL('kernel32',use_last_error=True)
kernel.GetProcessTimes.argtypes=[W.HANDLE,*([C.POINTER(W.FILETIME)]*4)]
kernel.GetProcessTimes.restype=W.BOOL
class ThreadEntry(C.Structure):
    _fields_=[('size',W.DWORD),('usage',W.DWORD),('tid',W.DWORD),('pid',W.DWORD),
              ('priority',W.LONG),('delta',W.LONG),('flags',W.DWORD)]
kernel.CreateToolhelp32Snapshot.argtypes=[W.DWORD,W.DWORD];kernel.CreateToolhelp32Snapshot.restype=W.HANDLE
kernel.Thread32First.argtypes=[W.HANDLE,C.POINTER(ThreadEntry)];kernel.Thread32Next.argtypes=kernel.Thread32First.argtypes
kernel.OpenThread.argtypes=[W.DWORD,W.BOOL,W.DWORD];kernel.OpenThread.restype=W.HANDLE
kernel.GetThreadTimes.argtypes=kernel.GetProcessTimes.argtypes
kernel.GetThreadDescription.argtypes=[W.HANDLE,C.POINTER(W.LPWSTR)]
kernel.LocalFree.argtypes=[C.c_void_p];kernel.CloseHandle.argtypes=[W.HANDLE]

def thread_cpu(pid):
    snapshot=kernel.CreateToolhelp32Snapshot(4,0);e=ThreadEntry();e.size=C.sizeof(e);found={}
    ok=kernel.Thread32First(snapshot,C.byref(e))
    while ok:
        if e.pid==pid:
            handle=kernel.OpenThread(0x0800,False,e.tid)
            if handle:
                values=[W.FILETIME() for _ in range(4)];name=W.LPWSTR()
                if kernel.GetThreadTimes(handle,*[C.byref(v) for v in values]):
                    kernel.GetThreadDescription(handle,C.byref(name))
                    found[e.tid]={'name':name.value or '',
                        'cpu':sum((v.dwHighDateTime<<32)|v.dwLowDateTime for v in values[2:])*1e-7}
                    if name:kernel.LocalFree(C.cast(name,C.c_void_p))
                kernel.CloseHandle(handle)
        ok=kernel.Thread32Next(snapshot,C.byref(e))
    kernel.CloseHandle(snapshot);return found

def cpu(process):
    values=[W.FILETIME() for _ in range(4)]
    if not kernel.GetProcessTimes(int(process._handle),*[C.byref(v) for v in values]):
        raise C.WinError(C.get_last_error())
    return sum((v.dwHighDateTime<<32)|v.dwLowDateTime for v in values[2:])*1e-7

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--exe',type=Path,required=True)
    ap.add_argument('--output',type=Path,required=True)
    ap.add_argument('--seconds',type=float,default=8)
    ap.add_argument('--scenarios',default='title,popup,gameplay,fade')
    ap.add_argument('--headless',action='store_true')
    ap.add_argument('--no-audio',action='store_true')
    ap.add_argument('--metrics',action='store_true')
    ap.add_argument('--move-start',type=int,default=8000,help='mission route: Right make time, ms')
    ap.add_argument('--move-end',type=int,default=10000,help='mission route: Right break time, ms')
    ap.add_argument('--warmup',type=float,help='override mission sampling start, seconds')
    a=ap.parse_args();out=a.output.resolve();out.mkdir(parents=True,exist_ok=True)
    receipts=[]
    for scenario in a.scenarios.split(','):
        folder=out/scenario;folder.mkdir(exist_ok=True)
        events=['1500 key space'];warm=3.0;seconds=a.seconds
        if scenario in ('popup','island','gameplay','fade','audio'): events += ['2500 key space']
        if scenario in ('island','gameplay','fade','audio'): events += ['3250 key n']
        if scenario in ('gameplay','audio'):
            events += [f'{a.move_start} keydown right',f'{a.move_end} keyup right']
        if scenario=='popup':warm=3.5
        elif scenario=='island':warm=8
        elif scenario in ('gameplay','audio'):warm=16
        elif scenario=='fade':warm=3.3;seconds=0.6
        elif scenario!='title':raise ValueError(scenario)
        if a.warmup is not None:warm=a.warmup
        if scenario=='audio':
            for ms in range(int(warm*1000),int((warm+seconds)*1000),500):
                events += [f'{ms} key alt',f'{ms+200} key ctrl']
        end=warm+seconds
        events += [f'{int(warm*1000)} shot sample-start.png',f'{int(end*1000)} shot sample-end.png',
                   f'{int(end*1000+70)} shot state.png',f'{int(end*1000+200)} quit']
        script=folder/'input.script';script.write_text('\n'.join(events)+'\n')
        command=[str(a.exe.resolve()),'--episode','2','--data',str(ROOT/'assets'),
                 '--script',str(script),'--realtime-script','--settings',str(folder/'sam.json')]
        if a.headless:command+=['--headless']
        if a.no_audio:command+=['--no-audio']
        env=os.environ.copy();env['PATH']='C:/tools/sdl3-3.4.16-mingw/SDL3-3.4.16/x86_64-w64-mingw32/bin;'+env.get('PATH','')
        if a.metrics:env['SAM_HOST_METRICS']=str(folder/'metrics.jsonl')
        env['SAM_DIAG_FLIPS']=str(folder/'flips.csv')
        with (folder/'stdout.txt').open('wb') as stdout,(folder/'stderr.txt').open('wb') as stderr:
            start=time.perf_counter();p=subprocess.Popen(command,cwd=ROOT,env=env,stdout=stdout,stderr=stderr)
            def marker(name):
                path=folder/name;deadline=time.perf_counter()+warm+seconds+15
                while time.perf_counter()<deadline:
                    if p.poll() is not None:raise RuntimeError('child exited before '+name)
                    try:
                        if path.is_file() and path.read_bytes()[-8:-4]==b'IEND':return
                    except OSError:pass
                    time.sleep(0.001)
                raise TimeoutError(name)
            marker('sample-start.png')
            before_time=time.perf_counter();before_cpu=cpu(p)
            before_threads=thread_cpu(p.pid)
            marker('sample-end.png')
            after_cpu=cpu(p);after_time=time.perf_counter()
            after_threads=thread_cpu(p.pid)
            p.wait(timeout=10)
        r={'scenario':scenario,'returncode':p.returncode,'command':command,
           'warm_seconds':warm,'marker_clock':'emulated-time screenshot completion',
           'sample_start_seconds':before_time-start,'sample_end_seconds':after_time-start,
           'cpu_seconds':after_cpu-before_cpu,'wall_seconds':after_time-before_time,
           'percent_one_core':100*(after_cpu-before_cpu)/(after_time-before_time)}
        r['threads']=[{'id':tid,'name':v['name'],'cpu_seconds':v['cpu']-before_threads.get(tid,{'cpu':0})['cpu']}
                      for tid,v in after_threads.items()]
        receipts.append(r);print(scenario,round(r['percent_one_core'],3),'% of one core',flush=True)
        (out/'checks.json').write_text(json.dumps(receipts,indent=2)+'\n')
    return 0 if all(r['returncode']==0 for r in receipts) else 1

if __name__=='__main__':raise SystemExit(main())
