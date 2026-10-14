{@decls}
var
  d_21D6: Word;
  d_21D8: Byte;
{@stubs}
function u4_05c3: Byte;
function u4_0557: Byte;
{@body}
procedure u4_045e;
begin
  if u4_05c3 = 7 then
    d_21D6 := $B000
  else
    d_21D6 := $B800;
  d_21D8 := Ord(u4_0557 = 1);
end;

