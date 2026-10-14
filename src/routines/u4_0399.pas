{@decls}

{@stubs}

{@body}
procedure u4_0399(x: Word; y: Integer; fg, bg: Word; source: String);
var
  i: Integer;
  chText: String;
begin
  if Ord(source[0]) > Integer(26 - y) then
    Delete(source, 27 - y, 80);
  for i := 1 to Ord(source[0]) do
  begin
    chText := source[i];
    u4_04bf(Byte(x), y - 1 + i, u4_0000(Byte(fg), Byte(bg)), source[i]);
  end;
end;
