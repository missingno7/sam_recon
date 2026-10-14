{@decls}
type
  TMenuText = array[1..6] of String[40];
var
  d_6814: Word;
  d_6824: Word;
{@stubs}
procedure u3_079e;
function u3_1601(Value: Byte): Byte;
procedure u3_3712;
procedure u7_0000(Value: Word);
{@body}
procedure u3_9ca9;
begin
  u3_079e;
  d_3812[1] := 'Quit to: ^';
  d_3812[2][0] := #0;
  d_3812[3] := ' D)os';
  d_3812[4] := ' T)itle Screen';
  d_3812[5] := ' I)sland Map';
  d_3812[6] := 'END OF WINDOW';
  d_67FA[1] := $20;
  d_67FA[2] := $14;
  d_67FA[3] := $17;
  d_67FA[4] := 1;
  d_6814 := u3_1601(1);
  if d_6814 = $20 then
  begin
    u3_3712;
    d_6EC6 := 1;
    d_6D66 := 0;
    u7_0000($12);
  end
  else if d_6814 = $14 then
  begin
    u3_3712;
    d_6EC7 := 1;
    d_6D66 := 0;
    u7_0000($12);
  end
  else if d_6814 = $17 then
  begin
    d_6EC8 := 1;
    d_6D66 := 0;
  end;
  d_6EC5 := 0;
  d_6816 := 0;
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  MemW[$0000:$041C] := MemW[$0000:$041A];
  d_6824 := 0;
end;

