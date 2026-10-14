from research import *
from runtime_probe import extent
UNIT='''unit Uprobe;
%s
interface
var pad:byte; x,y:integer;
function BitBtn:boolean;
function Pack(lo,hi:byte):byte;
function Both:boolean;
procedure Frame;
procedure Arr;
procedure Strings(var s:string);
procedure Io;
implementation
var a:array[0..7] of integer; t:string[10]; tf:text;
procedure PrivateProc;
begin x:=1 end;
function BitBtn:boolean;
begin
 BitBtn:=(Port[$201] and $10)=0
end;
function Pack(lo,hi:byte):byte;
begin Pack:=(hi shl 4) or lo end;
function Both:boolean;
begin if (x=-1) and (y=-1) then Both:=False else Both:=True end;
procedure Frame;
var z:integer;
begin z:=x; if z=0 then x:=0; PrivateProc end;
procedure Arr;
begin a[x]:=y end;
procedure Strings(var s:string);
begin s:=t end;
procedure Io;
begin Rewrite(tf); Close(tf) end;
begin end.
'''
MAIN='''program Dir;
uses Uprobe;
var b:boolean; k:byte; s:string;
begin b:=BitBtn; k:=Pack(1,2); b:=Both; Frame; Arr; Strings(s); Io end.
'''
def run():
    records=[]
    variants={'base':'{$A+}{$B-}{$D+}{$E+}{$F-}{$I+}{$L+}{$N-}{$O-}{$R-}{$S-}{$V+}',
              'a_minus':'{$A-}', 'b_plus':'{$B+}', 'd_minus':'{$D-}', 'e_minus':'{$E-}',
              'f_plus':'{$F+}', 'i_minus':'{$I-}', 'l_minus':'{$L-}',
              'n_plus':'{$N+}', 'o_plus':'{$O+}', 'r_plus':'{$R+}',
              's_plus':'{$S+}', 'v_minus':'{$V-}'}
    for n,extra in variants.items():
        dirs=variants['base']+(extra if n!='base' else '')
        p=setup('50','dir_'+n)
        (p/'UPROBE.PAS').write_text(UNIT%dirs)
        # V controls call-site var-string compatibility; keep both units in sync.
        exe=compile('50',dirs+'\n'+MAIN,'DIR',folder='dir_'+n)
        obj=load(exe); segs,pubs=map_info(exe)
        s=next(s for s in segs if s['name']=='UPROBE')
        code=obj.image[s['start']:s['end']]
        out={}
        for pub in pubs:
            if pub['seg']*16!=s['start']:continue
            e=extent(code,pub['off'])
            if e and e['min']==e['start']:out[pub['name']]={'start':pub['off'],'end':e['end'],'raw':code[pub['off']:e['end']].hex()}
        oracle=(REPO/'build/oracle/sam1/image.bin').read_bytes()
        for name,dat in out.items():
            raw=bytes.fromhex(dat['raw']);dat['oracle_linear']=oracle.find(raw)
        (p/'UPROBE.asm').write_text(dis(code))
        records.append({'variant':n,'directives':dirs,'header':obj.header,'routines':out,'segments':segs,'publics':pubs,
                       'exe_sha256':hashlib.sha256(exe.read_bytes()).hexdigest(),
                       'program_hex':obj.image[:next(s['end'] for s in segs if s['start']==0)].hex()})
        print(n,[(key,len(bytes.fromhex(val['raw'])),hex(val['oracle_linear'])) for key,val in out.items()])
    (ROOT/'directive_results.json').write_text(json.dumps(records,indent=2))
if __name__=='__main__':run()
