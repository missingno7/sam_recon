"""Map builtin names to the already byte-exact SAM runtime selection."""
from research import *
from system_recipe import recipe,SELECTED
from runtime_probe import FEATURES,calls,extent
EXTRA=['maxavail','mark','release','move','insert','valint','strint','appendtext','flush','randomize','assigntext','longdiv','longmod','blockread3','blockwrite3',
       'readstr','readln','eoftext','eoln','seekeof','seekeoln','filepos','filesize',
       'seek','truncate','stringcmp','stringchar','setunion','setinter','setdiff','seteq','runerror','halt',
       'writeint','writelong','erase','rename','paramstr','paramcount','getdir','realadd','readtyped','writetyped']
def run():
    oracle=(REPO/'build/oracle/sam1/image.bin').read_bytes()[0x2cd00:0x2cd00+0x1191]
    base=json.loads((ROOT/'recipe_results.json').read_text())[0]
    allowed={x['off'] for x in base['differences']}
    entries={}; attempts=[]
    for feature in ['base',*EXTRA]:
        s=recipe()
        if feature in ('readtyped','writetyped'):
            s=s.replace('ss,tt:string;', 'ss,tt:string; fr:file of integer;')
            body='procedure P%s;\nbegin %s(fr,ii) end;\n'%(feature,'Read' if feature=='readtyped' else 'Write')
            s=s.replace('begin ii:=Padding[1];',body+'begin ii:=Padding[1];')
        if feature!='base':s=s.rsplit('end.',1)[0]+' P%s;\nend.\n'%feature
        exe=compile('50',s,'CAT',folder='catalogue_'+feature)
        obj=load(exe);segs,pubs=map_info(exe)
        sg=next(x for x in segs if x['name']=='SYSTEM')
        code=obj.image[sg['start']:sg['end']]
        same=len(code)==len(oracle) and all(a==b or i in allowed for i,(a,b) in enumerate(zip(oracle,code)))
        attempts.append({'feature':feature,'system_length':len(code),'same_library_selection':same})
        if not same:continue
        pp=[x for x in pubs if x['seg']==0]
        for a,b in zip(pp,pp[1:]):
            tag=a['name'].lower()[1:]
            if tag not in dict(FEATURES) and tag not in ('readtyped','writetyped'):continue
            for cs,ip in calls(obj.image,a['off'],b['off']):
                if cs*16!=sg['start']:continue
                info=entries.setdefault(ip,{'offset':ip,'features':[],'extent':extent(code,ip)})
                if tag not in info['features']:info['features'].append(tag)
    obj=load(ROOT/'tp50/full_runtime/FULL.EXE');segs,pubs=map_info(ROOT/'tp50/full_runtime/FULL.EXE')
    external={}
    for name in ('DOS','CRT'):
        sg=next(x for x in segs if x['name']==name)
        external[name]=[x for x in pubs if x['seg']*16==sg['start']]
    result={'system':sorted(entries.values(),key=lambda x:x['offset']),
            'selection_tests':attempts,'publics':external}
    (ROOT/'runtime_catalogue.json').write_text(json.dumps(result,indent=2))
    print([(x['feature'],x['same_library_selection'],hex(x['system_length'])) for x in attempts])
    print([(hex(x['offset']),x['features'])for x in result['system']])
if __name__=='__main__':run()
