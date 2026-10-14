from research import *
from runtime_probe import FEATURES,source,calls,extent
SELECTED=['memavail','getmem','freemem','strcopy','concat','copy','delete','pos','longmul',
          'setin','random','strlong','vallong','resettext','rewritetext','closetext',
          'writestr','writeln','assignfile','resetfile','rewritefile','closefile',
          'blockread','blockwrite','fillchar','ioresult']
def recipe(pad=600):
    text=source(pad)
    # Preserve source globals but link only the groups required by SAM.
    for name,statement in FEATURES:
        if name not in SELECTED:
            text=text.replace('\n P%s;\n'%name,'\n')
    text=text.replace('ss,tt:string;', 'ss,tt:string; ar,br:array[1..100] of byte;')
    text=text.replace('begin ii:=Padding[1];','begin ii:=Padding[1]; ar:=br;')
    text=text.replace('{$S-}', '{$S-}{$I-}')
    return text
def run():
    oracle=(REPO/'build/oracle/sam1/image.bin').read_bytes()[0x2cd00:0x2dea0]
    records=[]
    for v in ('50','55'):
        exe=compile(v,recipe(),'RECIPE')
        obj=load(exe); s=next(s for s in map_info(exe)[0] if s['name']=='SYSTEM')
        code=obj.image[s['start']:s['end']]
        (exe.parent/'recipe_system.asm').write_text(dis(code))
        diffs=[{'off':i,'oracle':a,'probe':b} for i,(a,b) in enumerate(zip(oracle,code)) if a!=b]
        records.append({'version':v,'system_length':len(code),'oracle_padded_length':len(oracle),
                        'system_segment':s['start']//16,'differences':diffs})
        print(v,'length',hex(len(code)),'diffs',len(diffs),'first',diffs[:40])
    (ROOT/'recipe_results.json').write_text(json.dumps(records,indent=2))
if __name__=='__main__':run()
