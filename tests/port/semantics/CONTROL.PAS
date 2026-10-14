program Control;
{$S-}{$R-}{$I-}{$B-}
type TRec = record x: Byte; y: Integer end;
var r: TRec; i: Integer; count: Byte;
function Touch: Boolean;
begin Inc(count); Touch := True end;
procedure Outer(var z: Integer);
var a: Integer;
  procedure Inner;
  begin Inc(a,3); Inc(z,a) end;
begin a:=2; Inner; Inner; Writeln(a,' ',z) end;
begin
  count:=0;
  if False and Touch then Writeln('bad');
  if True or Touch then Writeln(count);
  i:=1; Outer(i);
  with r do begin x:=200; y:=-32768; Writeln(x,' ',y) end;
  Writeln(SizeOf(r));
  for i:=-2 to 3 do
    case i of -2..0: Write('L'); 1,3: Write('H'); else Write('?') end;
  Writeln;
  i:=0; repeat Inc(i) until i=3;
  while i>0 do Dec(i);
  Writeln(i);
end.
