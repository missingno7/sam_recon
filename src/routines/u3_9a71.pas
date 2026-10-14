{@decls}
type
  TString40 = string[40];
var
  d_6B44: array[1..10] of TString40;
  d_6814: Word;
{@stubs}
procedure u3_079e;
function u3_1601(Param: Byte): Byte;
{@body}
procedure u3_9a71;
var
  i: Word;
begin
  u3_079e;
  d_3812[1] := '  Secret Agents Hall of Fame';
  d_3812[2][0] := #0;
  d_3812[3][0] := #0;
  for i := 1 to 10 do
    d_3812[i + 3] := d_6B44[i];
  d_3812[14][0] := #0;
  d_3812[15] := 'Press any key ^';
  d_3812[16][0] := #0;
  d_3812[17] := 'END OF WINDOW';
  d_67FA[1] := 1;
  d_6814 := u3_1601(1);
  d_6EC5 := 0;
  d_6816 := 0;
end;
