from analyze import *
segnames=[s for s,n in SEGS]+[0x2dea]
eps=['sam1','sam2','sam3'];images={e:(ROOT/f'build/oracle/{e}/image.bin').read_bytes() for e in eps}
relocsites={e:{s*16+o for s,o in json.loads((ROOT/f'build/oracle/{e}/relocs.json').read_text())['relocs']} for e in eps}
targets={e:sorted(set(struct.unpack_from('<H',images[e],a)[0] for a in relocsites[e])) for e in eps}
maps={e:dict(zip(segnames,targets[e])) for e in eps}
def ranges(items):
    out=[]
    for i in items:
        if out and out[-1][1]==i:out[-1][1]=i+1
        else:out.append([i,i+1])
    return out
results=[]
for seg,n in SEGS[4:]:
    row={'sam1_segment':f'{seg:04x}','size':n,'episodes':{}}
    b=images['sam1'][seg*16:seg*16+n]
    rel1={a-seg*16 for a in relocsites['sam1'] if seg*16<=a<seg*16+n}
    norm1=bytearray(b)
    for a in rel1:norm1[a:a+2]=b'\0\0'
    for e in eps:
        s=maps[e][seg];c=images[e][s*16:s*16+n]
        rel2={a-s*16 for a in relocsites[e] if s*16<=a<s*16+n};norm2=bytearray(c)
        for a in rel2:norm2[a:a+2]=b'\0\0'
        diffs=[i for i,(x,y) in enumerate(zip(norm1,norm2)) if x!=y]
        row['episodes'][e]={'segment':f'{s:04x}','raw_equal':b==c,'normalized_equal':norm1==norm2,'relocation_sites_equal':rel1==rel2,'different_ranges':[[f'{a:04x}',f'{z:04x}',b[a:z].hex(),c[a:z].hex()] for a,z in ranges(diffs)]}
    results.append(row)
(OUT/'episode_compare.json').write_text(json.dumps(results,indent=2))
for row in results:
    print(row['sam1_segment'])
    for e in ['sam2','sam3']:
        sub=row['episodes'][e];print(' ',e,sub['segment'],sub['normalized_equal'],'different ranges',sub['different_ranges'][:90])
