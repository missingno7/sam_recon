{@decls}
type
  TTextPair = packed record
    first: string[40];
    second: string[40];
  end;
var
  d_6814: Word;
  d_6824: Word;
{@stubs}
procedure u3_079e;
function u3_1601(value: Byte): Byte;
{@body}
procedure u3_9bdf;
begin
  u3_079e;
  d_3812[1] := 'Quit To Dos (Y-N) ^';
  d_3812[2] := 'END OF WINDOW';
  d_67FA[1] := 1;
  d_67FA[2] := $15;
  d_67FA[3] := $31;
  d_6814 := u3_1601(1);
  if d_6814 = $15 then
    d_6EC6 := 1;
  d_6EC5 := 0;
  d_6816 := 0;
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  MemW[0:$41C] := MemW[0:$41A];
  d_6824 := 0;
end;
