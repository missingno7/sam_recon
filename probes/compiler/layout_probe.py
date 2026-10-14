from research import *
A='''unit Ua;
interface
const AC:word=$1111;
var AB:byte; AW:word;
procedure AFirst;
procedure ALast;
implementation
procedure PrivateUsed;
begin AW:=$4444 end;
procedure PrivateUnused;
begin AW:=$5555 end;
procedure ALast;
begin AW:=$2222; PrivateUsed end;
procedure AFirst;
var S:string[8];
begin S:='alpha'; AW:=$3333; ALast end;
begin AW:=$6666 end.
'''
B='''unit Ub;
interface
const BC:byte=$77;
var BB:byte; BW:word;
procedure BFirst;
procedure BUnused;
implementation
procedure BUnused;
begin BW:=$8888 end;
procedure BFirst;
const LC:word=$9999;
var S:string[8];
begin S:='beta'; BW:=LC end;
begin BW:=$AAAA end.
'''
MAIN='''program Layout;
uses %s;
const PC:word=$BBBB;
var PB:byte; PW:word;
procedure Unused;
begin PW:=$CCCC end;
procedure Used;
const TC:word=$DDDD;
var S:string[8];
begin S:='main'; PW:=TC end;
begin Used; AFirst; BFirst end.
'''
def run():
    for n,order in [('ab','Ua,Ub'),('ba','Ub,Ua'),('live','Ua,Ub'),('dep','Ua,Ub')]:
        p=setup('50','layout_'+n)
        aa,bb,mm=A,B,MAIN%order
        if n in ('live','dep'):
            aa=aa.replace('AW:=$3333','AW:=AC')
            bb=bb.replace('BW:=LC','BW:=LC+BC')
            mm=mm.replace('PW:=TC','PW:=TC+PC')
        if n=='dep':
            aa=aa.replace('interface\n','interface\nuses Uc;\n')
            bb=bb.replace('interface\n','interface\nuses Uc;\n')
            (p/'UC.PAS').write_text('unit Uc;\ninterface\nvar CW:word;\nimplementation\nbegin CW:=$EEEE end.\n')
        (p/'UA.PAS').write_text(aa); (p/'UB.PAS').write_text(bb)
        exe=compile('50',mm,'LAYOUT',folder='layout_'+n)
        obj=load(exe); segs,pubs=map_info(exe)
        for s in segs:
            if s['class']=='CODE':(p/(s['name']+'.asm')).write_text(dis(obj.image[s['start']:s['end']]))
        (p/'facts.json').write_text(json.dumps({'header':obj.header,'segments':segs,'publics':pubs,'data_hex':obj.image[next(s['start'] for s in segs if s['class']=='DATA'):].hex()},indent=2))
        print(n,segs,pubs)
if __name__=='__main__':run()
