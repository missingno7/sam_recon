{@decls}
type
  TStr40 = string[40];
var
  d_3812: array[1..299] of TStr40;
  d_6A44: string;
  d_6EC5, d_6816: Byte;
{@stubs}
procedure u3_079e;
function u3_1e2a(mode: Word): string;
{@body}
function u3_8ea3: Word;
var
  level, code: Word;
begin
  u3_079e;
  d_3812[1] := 'Warp to which level?';
  d_3812[2] := '--------------------';
  d_3812[3][0] := #0;
  d_3812[4] := 'Select (1-16) : ^';
  d_3812[5][0] := #0;
  d_3812[6] := 'END OF WINDOW';
  d_6A44 := u3_1e2a(2);
  MemW[$0000:$041C] := MemW[$0000:$041A];
  Val(d_6A44, level, code);
  u3_8ea3 := level;
  d_6EC5 := 0;
  d_6816 := 0;
end;

