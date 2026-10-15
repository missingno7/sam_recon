program FileLife;
uses Dos;
{$S-}{$R-}{$I-}
procedure CreateFiles(Depth: Integer);
var F: file of Integer; I: Integer;
begin
  Assign(F,'LIFE.DAT'); Rewrite(F); I:=1234; Write(F,I); Close(F);
  if Depth>0 then CreateFiles(Depth-1);
  Reset(F); Read(F,I); Close(F);
  if I<>1234 then Writeln('BAD FILE');
end;
procedure CheckBuffer;
var B: array[1..192] of Byte; R: Registers; I: Integer; OK: Boolean;
begin
  FillChar(B,SizeOf(B),165);
  FillChar(R,SizeOf(R),0); R.AX:=$0F00; Intr($10,R);
  OK:=True;
  for I:=1 to 192 do if B[I]<>165 then OK:=False;
  Writeln(OK,' ',IOResult);
end;
begin
  CreateFiles(16); CheckBuffer; CreateFiles(16); CheckBuffer;
end.
