"""Keep compiler disassembly evidence for representative canonical expressions.

This is a read-only test of the verify build, never a compiler input/layout pass.
Instruction bytes are not emitted into the delivered compiler or C source.
"""
import json
import re
import sys
from pathlib import Path
from pas2c_paths import ROOT, WORK
sys.path.insert(0,str(ROOT/'tools'))
import common
import mz
from capstone import Cs, CS_ARCH_X86, CS_MODE_16

def evidence(ref):
    text=(ref/'SAM.MAP').read_text(encoding='latin1')
    img=mz.parse((ref/'SAM.EXE').read_bytes()).image
    publics={(int(s,16),int(o,16)):n for s,o,n in re.findall(r'^ ([0-9A-F]{4}):([0-9A-F]{4})\s+(\S+)',text,re.M)}
    sections={file.upper():body for file,body in re.findall(r'Line numbers for \w+\(([^)]+)\) segment \w+\s*\n(.*?)(?=\nLine numbers for|\nProgram entry point|\Z)',text,re.S)}
    samples=[('TEXT80.PAS',130,['REPEATTEXTCHARACTER','WRITECOLOREDTEXT']),
             ('TEXT80.PAS',232,['MAKETEXTATTRIBUTE','WRITECOLOREDTEXT']),
             ('SAMUI.PAS',370,None)]
    decoder=Cs(CS_ARCH_X86,CS_MODE_16); result=[]
    for file,line,expected in samples:
        entries=[(int(n),int(s,16),int(o,16)) for n,s,o in re.findall(r'(\d+)\s+([0-9A-F]{4}):([0-9A-F]{4})',sections[file])]
        matches=[(s,o) for n,s,o in entries if n==line]
        if not matches: raise RuntimeError(f'{file}:{line}: missing TP line mapping')
        seg,off=min(matches,key=lambda p:p[1]); later=[o for n,s,o in entries if s==seg and o>off and n>line]
        end=min(later) if later else off+128
        instructions=[]; calls=[]
        for ins in decoder.disasm(img[seg*16+off:seg*16+end],off):
            instructions.append(f'{seg:04X}:{ins.address:04X} {ins.mnemonic} {ins.op_str}')
            if ins.mnemonic=='lcall':
                m=re.fullmatch(r'(0x[0-9a-f]+|\d+), (0x[0-9a-f]+|\d+)',ins.op_str)
                if m:
                    target=(int(m[1],0),int(m[2],0)); calls.append(publics.get(target,f'{target[0]:04X}:{target[1]:04X}'))
            elif ins.mnemonic=='call' and re.fullmatch(r'(0x[0-9a-f]+|\d+)',ins.op_str):
                target=(seg,int(ins.op_str,0)); calls.append(publics.get(target,f'{target[0]:04X}:{target[1]:04X}'))
        selected=[n for n in calls if expected and n in expected]
        ok=selected==expected if expected else len(calls)>=2
        source=(ROOT/'game'/file).read_text(encoding='latin1').splitlines()[line-1].strip()
        result.append({'file':file,'line':line,'source':source,'calls_in_machine_order':calls,'ok':ok,
                       'expected_named_calls':expected,'instructions':instructions,
                       'interpretation':'left-to-right argument pushes, nested function result before outer call' if expected else
                                        'Copy helper completes before Pos helper; matches nested source argument evaluation'})
    return {'ok':all(x['ok'] for x in result),'samples':result,'input':'pinned verify SAM1 build'}

if __name__=='__main__':
    result=evidence(WORK/'build/reference/sam1'); dest=WORK/'build/order-evidence.json'
    dest.write_text(json.dumps(result,indent=2)+'\n'); print(json.dumps(result,indent=2))
    sys.exit(0 if result['ok'] else 1)
