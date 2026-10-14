import sys
sys.dont_write_bytecode = True
from pathlib import Path
import json, struct

p = Path(__file__).resolve().parent
root = p.parents[2]
rows = json.loads((p/'asm_routines.json').read_text(encoding='utf-8'))
lengths = {'0000':0x5200,'25e5':0x5d0,'2642':0x22c0,'286e':0x100,'2890':0xd00,'29c2':0x3040}
assert len(rows) == 125
assert len({(r['segment'],r['start']) for r in rows}) == len(rows)
assert all(0 <= int(r['start'],16) < int(r['end'],16) <= lengths[r['segment']] for r in rows)
assert all(int(r['start'],16) <= int(a,16) < int(z,16) <= int(r['end'],16) for r in rows for a,z in r['code_ranges'])
assert all(0 <= int(a,16) < int(z,16) <= lengths[r['segment']] for r in rows for a,z in r.get('external_code_ranges',[]))
checks = json.loads((p/'asm_episode_compare.json').read_text())
assert len(checks) == 123 and all(v['normalized_code_equal'] for r in checks for v in r['episodes'].values())
ident = json.loads((p/'toolbox_code_identity.json').read_text())
assert ident['bytes'] == 11848 and all(ident['equal'].values())
probes = json.loads((p/'assembler_probes.json').read_text())
assert len(probes) == 7 and all(v['returncode'] == 0 for v in probes.values())
assert len(set(v['omf']['segments']['1'] for v in probes.values())) == 1
b = (root/'build/oracle/sam1/image.bin').read_bytes()
expected = bytes.fromhex(next(iter(probes.values()))['omf']['segments']['1'])[:34]
assert expected == b[0x29c20+0x1a3:0x29c20+0x1c5]
exe = (p/'probes/tp_exact_layout/MAIN.EXE').read_bytes()
h = struct.unpack_from('<14H',exe)
load = exe[h[4]*16:]
unit = load[2*16:]
assert unit[:0x70] == b[0x29c20:0x29c20+0x70]
assert unit[0x70:0x7b] == b[0x29c20+0x70:0x29c20+0x7b]
assert unit[0x1a3:0x1c5] == expected
report = (p/'REPORT.md').read_text(encoding='utf-8')
assert 'decrypt_asset_buffer' in report and len(report) > 30000
assert 'external_code_ranges' in report
receipt = {'status':'pass','catalog_entries':len(rows),'cross_episode_routines':len(checks),
           'identical_toolbox_code_bytes':ident['bytes'],'assembler_tools':len(probes),
           'setmode_oracle_match_bytes':34,'tp5_layout_offsets':['0070','00e6','01a3'],
           'report_encoding':'utf-8'}
(p/'verification.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps(receipt))
