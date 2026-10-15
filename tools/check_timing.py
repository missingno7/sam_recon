"""Summarize opt-in CRTC start-address writes, including loading gaps.

SAM_DIAG_FLIPS records emulated time and host time; the supervisor's older
one-column diagnostic logs (emulated microseconds) are also accepted.
"""
from pathlib import Path
import argparse
from collections import Counter
import csv
import json
import statistics

def summarize(path,start,end):
    lines=path.read_text().splitlines()
    if lines and lines[0].startswith('emu_us,'):
        rows=list(csv.DictReader(lines));times=[int(r['emu_us']) for r in rows]
        host=[int(r['host_us']) for r in rows]
    else:
        times=[int(s) for s in lines if s.strip()];host=None
    indices=[i for i,t in enumerate(times) if start*1e6<=t<end*1e6]
    selected=[times[i] for i in indices]
    intervals=[b-a for a,b in zip(selected,selected[1:])]
    result={'log':str(path),'start':start,'end':end,'flips':len(selected),
            'flips_per_second':len(selected)/(end-start),
            'interval_us':{'min':min(intervals),'median':statistics.median(intervals),'max':max(intervals)},
            'interval_histogram_ms':dict(sorted(Counter(round(t/1000,1) for t in intervals).items()))}
    if host and len(indices)>1:
        diffs=[host[b]-host[a] for a,b in zip(indices,indices[1:])]
        result['host_interval_us']={'min':min(diffs),'median':statistics.median(diffs),'max':max(diffs)}
    return result

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('log',type=Path)
    ap.add_argument('--start',type=float,default=10)
    ap.add_argument('--end',type=float,default=22)
    ap.add_argument('--output',type=Path)
    a=ap.parse_args()
    result=summarize(a.log,a.start,a.end)
    text=json.dumps(result,indent=2)+'\n'
    if a.output:a.output.write_text(text)
    print(text,end='')
    return 0

if __name__=='__main__':raise SystemExit(main())
