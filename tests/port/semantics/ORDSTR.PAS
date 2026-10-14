program OrdStr;
{$S-}{$R-}{$I-}{$B-}
type TRec = record x: Integer end;
     TArray = array[1..4] of Integer;
var text: String; a: TArray; r: TRec; log,state: Integer; ch: Char;
function Change: Integer;
begin log:=log*10+2; text:='new'; r.x:=9; a[1]:=9; Change:=3 end;
function S: String;
begin log:=log*10+2; text:='new'; S:='!' end;
function ChangeChar: Integer;
begin log:=log*10+2; ch:='Z'; ChangeChar:=3 end;
procedure Args(s: String; n: Integer);
begin Writeln(log,' ',s,' ',n) end;
procedure Recs(v: TRec; n: Integer);
begin Writeln(log,' ',v.x,' ',n) end;
procedure Arrays(v: TArray; n: Integer);
begin Writeln(log,' ',v[1],' ',n); v[1]:=7 end;
begin
  text:='old'; log:=0; Writeln(text+S,' ',log);
  text:='old'; log:=0; Writeln(S+text,' ',log);
  text:='old'; log:=0; Args(text,Change);
  r.x:=1; log:=0; Recs(r,Change);
  a[1]:=1; log:=0; Arrays(a,Change);
  Writeln(a[1]);
  ch:='A'; log:=0; Args(ch,ChangeChar);
end.
