{@decls}
type
  TTextPair = packed record
    first: string[40];
    second: string[40];
  end;
var
  d_3812: TTextPair;
  d_67FA: Byte;
  d_67FB: Byte;
  d_67FC: Byte;
  d_6814: Word;
  d_6816: Byte;
  d_6824: Word;
  d_6EC3: Byte;
  d_6EC4: Byte;
  d_6EC5: Byte;
  d_6EC6: Byte;
  d_6ECA: Byte;
  d_6ECB: Byte;
{@stubs}
procedure u3_079e;
function u3_1601(value: Byte): Byte;
{@body}
procedure u3_9bdf;
begin
  u3_079e;
  d_3812.first := 'Quit To Dos (Y-N) ^';
  d_3812.second := 'END OF WINDOW';
  d_67FA := 1;
  d_67FB := $15;
  d_67FC := $31;
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
