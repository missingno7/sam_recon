"""Require committed placement to equal independently rebuilt TP5 geometry."""
import json
from pas2c import PLACEMENT_FIELDS, memory_layout, placement_layout
from pas2c_paths import WORK, ROOT
import sys
sys.path.insert(0, str(ROOT / 'tools'))
import mz

def check():
    results = {}
    for episode in ('sam1', 'sam2', 'sam3'):
        committed = placement_layout(WORK / 'config/port.json', episode)
        rebuilt = memory_layout(WORK / 'build/reference' / episode / 'SAM.MAP')
        header = mz.parse((WORK / 'build/reference' / episode / 'SAM.EXE').read_bytes()).header
        load_segment = rebuilt[0] + 16
        header_equal = rebuilt[2] == load_segment + header['ss'] and rebuilt[3] == header['sp']
        results[episode] = {'ok': committed == rebuilt and header_equal, 'mz_stack_equal':header_equal, 'committed': dict(zip(PLACEMENT_FIELDS,
             committed)), 'reference': dict(zip(PLACEMENT_FIELDS, rebuilt))}
        print(episode, 'placement PASS' if committed == rebuilt else 'placement DIFF')
    (WORK / 'build/placement-checks.json').write_text(json.dumps(results, indent=2) + '\n')
    return all((result['ok'] for result in results.values()))
if __name__ == '__main__':
    raise SystemExit(0 if check() else 1)
