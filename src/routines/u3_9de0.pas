{@decls}
type
  TRec41 = packed record
    S: String[40];
  end;
var
  d_6814: Word;
  d_6824: Word;
{@stubs}
procedure u3_079e;
function u3_1601(Mode: Byte): Byte;
{@body}
procedure u3_9de0;
begin
  u3_079e;
  d_3812[1] := 'Sounds On (Y-N) ^';
  d_3812[2] := 'END OF WINDOW';
  d_67FA[1] := $15;
  d_67FA[2] := $31;
  d_67FA[3] := 1;
  d_6814 := u3_1601(1);
  if d_6814 = $15 then
    d_34AF := 1
  else
    d_34AF := 0;
  d_6EC5 := 0;
  d_6816 := 0;
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  MemW[$0000:$041C] := MemW[$0000:$041A];
  d_6824 := 0;
end;
