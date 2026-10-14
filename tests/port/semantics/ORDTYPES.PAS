program OrdTypes;
{$S-}{$R-}{$I-}{$B-}
type TSet = set of 0..31;
var log,state,v: Integer; l: LongInt; w: Word; a: array[1..4,1..4] of Integer;
    b: Boolean; st: TSet;
function I(tag,value: Integer): Integer;
begin log:=log*10+tag; I:=value end;
function Lg(tag: Integer; value: LongInt): LongInt;
begin log:=log*10+tag; Lg:=value end;
function Wd(tag: Integer; value: Word): Word;
begin log:=log*10+tag; Wd:=value end;
function Change: Integer;
begin log:=log*10+2; state:=9; Change:=3 end;
begin
  log:=0; l:=Lg(1,100000)+Lg(2,300); Writeln(log,' ',l);
  log:=0; l:=Lg(1,100000) div Lg(2,300); Writeln(log,' ',l);
  log:=0; l:=I(1,3)+Lg(2,100000); Writeln(log,' ',l);
  log:=0; l:=Wd(1,60000)+I(2,-1); Writeln(log,' ',l);
  log:=0; w:=Wd(1,60000)+Wd(2,2); Writeln(log,' ',w);
  log:=0; b:=I(1,1)<I(2,2); Writeln(log,' ',b);
  log:=0; b:=Lg(1,1)<Lg(2,2); Writeln(log,' ',b);
  log:=0; v:=I(1,2) and I(2,3); Writeln(log,' ',v);
  log:=0; st:=[I(1,1)]+[I(2,2)]; Writeln(log,' ',1 in st);
  log:=0; b:=[I(1,1)]=[I(2,2)]; Writeln(log,' ',b);
  state:=1; log:=0; v:=state*2+Change; Writeln(log,' ',v);
  state:=1; log:=0; v:=Change+state*2; Writeln(log,' ',v);
  state:=1; log:=0; v:=Change+(state+1)*(state+2); Writeln(log,' ',v);
  a[1,2]:=5; log:=0; v:=a[I(1,1),2]+I(2,3); Writeln(log,' ',v);
  a[1,2]:=5; log:=0; v:=I(1,3)+a[I(2,1),2]; Writeln(log,' ',v);
end.
