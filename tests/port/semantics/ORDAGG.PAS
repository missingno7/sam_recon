program OrdAgg;
{$S-}{$R-}{$I-}{$B-}
type TRec = record x: Integer end;
     TA = array[1..4] of Integer;
     PArr = ^TA;
     TSet = set of 0..31;
var strs: array[1..3] of String; recs: array[1..3] of TRec;
    arr: array[1..3] of TA; sets: array[1..3] of TSet;
    pa,qa: PArr; st,res: TSet; log,v,state: Integer;
    grid: array[1..4,1..4] of Integer;
function F(tag,value: Integer): Integer;
begin log:=log*10+tag; F:=value end;
function S: String;
begin log:=log*10+2; S:='x' end;
function MutateSet: Integer;
begin log:=log*10+2; st:=[2]; MutateSet:=2 end;
function SwapArray: Integer;
begin log:=log*10+1; pa:=qa; SwapArray:=1 end;
function ChangeIndex: Integer;
begin log:=log*10+1; state:=3; ChangeIndex:=1 end;
begin
  log:=0; strs[F(1,1)]:=S; Writeln(log);
  log:=0; recs[F(1,1)]:=recs[F(2,2)]; Writeln(log);
  log:=0; arr[F(1,1)]:=arr[F(2,2)]; Writeln(log);
  log:=0; sets[F(1,1)]:=[F(2,2)]; Writeln(log);
  st:=[1]; log:=0; res:=st+[MutateSet]; Writeln(log,' ',1 in res,' ',2 in res);
  st:=[1]; log:=0; Writeln(st=[MutateSet],' ',log);
  arr[1][1]:=1; arr[2][1]:=9; pa:=@arr[1]; qa:=@arr[2];
  log:=0; v:=pa^[SwapArray]; Writeln(log,' ',v);
  grid[1,1]:=11; grid[1,3]:=13; grid[3,1]:=31;
  state:=1; log:=0; v:=grid[ChangeIndex,state]; Writeln(log,' ',v);
  state:=1; log:=0; v:=grid[state,ChangeIndex]; Writeln(log,' ',v);
  log:=0; MemW[F(1,DSeg):F(2,Ofs(recs))]:=F(3,17); Writeln(log);
  log:=0; v:=MemW[F(1,DSeg):F(2,Ofs(recs))]+F(3,7); Writeln(log);
  log:=0; Inc(grid[F(1,1),F(2,1)],F(3,2)); Writeln(log);
  log:=0; Inc(grid[F(1,1),F(2,1)]); Writeln(log);
  log:=0; FillChar(grid[F(1,1),F(2,1)],F(3,2),F(4,0)); Writeln(log);
  log:=0; Str(F(1,7):F(2,2),strs[F(3,1)]); Writeln(log,' [',strs[1],']');
end.
