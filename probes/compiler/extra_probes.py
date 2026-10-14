from research import *
from directive_probe import UNIT,MAIN
from full_runtime_probe import inline_nops
from runtime_probe import calls
def external_probe():
    p=setup('50','external')
    shutil.copy2(Path(VERSIONS['50'])/'BINOBJ.EXE',p/'BINOBJ.EXE')
    for name,raw in [('HELP',b'\x90'*76+b'\xcb'),('AXIS',b'\x31\xc0\xca\x02\x00')]:
        (p/(name+'.BIN')).write_bytes(raw)
        r=subprocess.run(['C:/tools/nmlgcdos/msdos.exe','BINOBJ.EXE',name+'.BIN',name+'.OBJ',name],cwd=p,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        (p/(name+'.log')).write_text(r.stdout.decode('cp437'))
    text='''unit Joy;
{$S-}{$B-}{$R-}
interface
function Exists:boolean;
function Btn1:boolean;
function Btn2:boolean;
procedure Help;
function Axis(n:integer):integer;
implementation
{$L HELP.OBJ}
{$L AXIS.OBJ}
function Exists:boolean;
var x,y:integer;
begin
 x:=Axis(0); y:=Axis(1);
 if (x=-1) and (y=-1) then Exists:=False else Exists:=True
end;
function Btn1:boolean;
begin Btn1:=(Port[$201] and $10)=0 end;
function Btn2:boolean;
begin Btn2:=(Port[$201] and $20)=0 end;
procedure Help; external;
function Axis(n:integer):integer; external;
begin end.
'''
    result=[]
    for tag,bflag in [('short','-'),('complete','+')]:
        (p/'JOY.PAS').write_text(text.replace('{$B-}','{$B%s}'%bflag))
        exe=compile('50','program JoyTest;\nuses Joy;\nvar b:boolean;\nbegin b:=Exists; b:=Btn1; b:=Btn2; Help end.','JOYTEST',folder='external')
        obj=load(exe); segs,pubs=map_info(exe)
        sg=next(s for s in segs if s['name']=='JOY')
        code=obj.image[sg['start']:sg['end']]
        oracle=(REPO/'build/oracle/sam1/image.bin').read_bytes()[0x286e0:0x287e0]
        result.append({'variant':tag,'publics':[x for x in pubs if x['seg']*16==sg['start']],
                       'first_0x38_equal':code[:0x38]==oracle[:0x38],
                       'pascal_0x7f_equal':code[:0x7f]==oracle[:0x7f],'code_hex':code.hex()})
        (p/('JOY_'+tag+'.asm')).write_text(dis(code))
        shutil.copy2(p/'JOYTEST.MAP',p/('JOY_'+tag+'.MAP'))
        print('external',tag,result[-1]['publics'],'first38',result[-1]['first_0x38_equal'])
    return result
def memory_probe():
    result=[]
    for stack,hmin,hmax in [(16384,0,655360),(8192,0,655360),(16384,4096,655360),(16384,0,327680),
                           (16384,16,655359),(16384,1023,655359),(16384,1024,655359),(16384,0,655359)]:
        exe=compile('50','program Mem;\n{$M %d,%d,%d}\nvar a:array[1..1000]of byte;\nbegin a[1]:=1 end.\n'%(stack,hmin,hmax),'MEM',folder='memory_%d_%d_%d'%(stack,hmin,hmax))
        obj=load(exe)
        h=obj.header
        result.append({'directive':[stack,hmin,hmax],'header':h,'image_size':len(obj.image),
            'min_end':len(obj.image)+16*h['minalloc'],'stack_end':h['ss']*16+h['sp'],
            'max_minus_min':h['maxalloc']-h['minalloc']})
    return result
def compatibility_probe():
    result=[]
    for flag in ('+','-'):
        p=setup('50','varstring_'+('plus' if flag=='+' else 'minus'))
        (p/'UPROBE.PAS').write_text(UNIT%'{$S-}')
        try:
            exe=compile('50','{$V%s}\n'%flag+MAIN.replace('s:string;','s:string[20];'),'VSTR',folder=p.name)
            result.append({'V':flag,'compiles':True})
        except RuntimeError as e:result.append({'V':flag,'compiles':False,'error':str(e)})
    p=setup('55','mixed50')
    shutil.copy2(Path(VERSIONS['50'])/'TURBO.TPL',p/'TURBO.TPL')
    try:
        compile('55','program Mixed;\nbegin end.','MIXED',folder='mixed50')
        result.append({'tp55_with_tp50_tpl':'compiles'})
    except RuntimeError as e:result.append({'tp55_with_tp50_tpl':'fails','error':str(e)})
    return result
def forward_probe():
    p=setup('50','forward')
    unit='''unit Fwd;
{$S-}
interface
procedure Target;
procedure Helper;
procedure Sentinel;
implementation
procedure Helper;
begin inline($90) end;
procedure Target;
begin Helper end;
procedure Sentinel;
begin end;
begin end.
'''
    (p/'FWD.PAS').write_text(unit)
    exe=compile('50','program ForwardTest;\nuses Fwd;\nbegin Target; Sentinel end.','FWDTEST',folder='forward')
    obj=load(exe);segs,pubs=map_info(exe)
    sg=next(s for s in segs if s['name']=='FWD')
    code=obj.image[sg['start']:sg['end']]
    (p/'FWD.asm').write_text(dis(code))
    first={'publics':[x for x in pubs if x['seg']*16==sg['start']],'code_hex':code.hex()}
    unit='''unit Fwd;
{$S-}
interface
procedure Target;
procedure Sentinel;
implementation
procedure Helper; forward;
procedure Target;
begin Helper end;
procedure Sentinel;
begin end;
procedure Helper;
begin inline($90) end;
begin end.
'''
    (p/'FWD.PAS').write_text(unit)
    shutil.copy2(p/'FWDTEST.MAP',p/'BODY_ORDER.MAP')
    exe=compile('50','program ForwardTest;\nuses Fwd;\nbegin Target; Sentinel end.','FWDTEST',folder='forward')
    obj=load(exe);segs,pubs=map_info(exe)
    sg=next(s for s in segs if s['name']=='FWD')
    code=obj.image[sg['start']:sg['end']]
    (p/'SENTINEL.asm').write_text(dis(code))
    return {'body_order':first,'target_first_sentinel':{'publics':[x for x in pubs if x['seg']*16==sg['start']],'code_hex':code.hex()}}
if __name__=='__main__':
    results={'external':external_probe(),'memory':memory_probe(),'compatibility':compatibility_probe(),'forward':forward_probe()}
    (ROOT/'extra_results.json').write_text(json.dumps(results,indent=2))
    print(json.dumps(results['memory'],indent=2)); print(results['compatibility']);print(results['forward'])
