{@decls}
{@stubs}
procedure u3_079e;
function u3_1601(Mode: Byte): Byte;
{@body}
procedure u3_87fd(Arg: Word);
var
  KeyCode: Word;
begin
  u3_079e;
  d_3812[1] := 'Sorry, that key is unavailable.';
  d_3812[2][0] := #0;
  d_3812[3] := '  Press any key to continue.';
  d_3812[4][0] := #0;
  d_3812[5] := '               ^';
  d_3812[6] := 'END OF WINDOW';
  KeyCode := u3_1601(1);
end;
