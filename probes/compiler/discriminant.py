"""Fair TP5.5 comparison: compensate its extra two initialized data bytes."""
from research import *
from runtime_probe import source,calls,extent
def run():
    exe=compile('55',source(598),'FAIR55')
    obj=load(exe); segs,pubs=map_info(exe)
    sg=next(s for s in segs if s['name']=='SYSTEM')
    code=obj.image[sg['start']:sg['end']]
    pp=[p for p in pubs if p['seg']==0]
    oracle=(REPO/'build/oracle/sam1/image.bin').read_bytes()
    targets={'memavail':(0x3b5,68),'maxavail':(0x3f9,77),'mark':(0x384,22),
             'release':(0x39a,27),'insert':(0x77c,84),'delete':(0x7d0,86)}
    records=[]
    for a,b in zip(pp,pp[1:]):
        tag=a['name'].lower()[1:]
        if tag not in targets:continue
        for cs,ip in calls(obj.image,a['off'],b['off']):
            if cs*16!=sg['start']:continue
            start,length=targets[tag]; original=oracle[0x2cd00+start:0x2cd00+start+length]
            e=extent(code,ip); candidate=code[ip:e['end']]
            diffs=[{'off':i,'sam':x,'tp55':y} for i,(x,y) in enumerate(zip(original,candidate)) if x!=y]
            records.append({'feature':tag,'offset':ip,'extent':e,'oracle_original_found':obj.image.find(original),
                            'differences':diffs,'byte_equal':original==candidate})
    (ROOT/'fair55_results.json').write_text(json.dumps(records,indent=2))
    print([(x['feature'],x['byte_equal'],len(x['differences'])) for x in records])
if __name__=='__main__':run()
