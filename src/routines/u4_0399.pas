{@decls}
{@stubs}
function u4_0000(a, b: Byte): Byte;
procedure u4_04bf(x: Byte; idx: Byte; attr: Byte; s: String);
{@body}
procedure u4_0399(x: Byte; y: Integer; fg, bg: Byte; var source: String);
var
  work: String;
  i: Integer;
  chText: String;
begin
  work := source;
  if Ord(work[0]) > Integer(26 - y) then
    Delete(work, 27 - y, 80);
  for i := 1 to Ord(work[0]) do
  begin
    chText := work[i];
    u4_04bf(x, y - 1 + i, u4_0000(fg, bg), work[i]);
  end;
end;
