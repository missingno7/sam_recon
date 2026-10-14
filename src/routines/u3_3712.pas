{@decls}
type
  PByte = ^Byte;
{@stubs}

{@body}
procedure u3_3712;
var
  i: Integer;
  j: Integer;
  s: String[255];
begin
  if d_699A > d_6B44.Scores[10] then
  begin
    u3_848e;
    for i := 10 downto 1 do
      if d_6B44.Scores[i] < d_699A then
        j := i;
    if j < 10 then
      for i := 10 downto j + 1 do
      begin
        d_6B44.Scores[i] := d_6B44.Scores[i - 1];
        d_6B44.Names[i] := d_6B44.Names[i - 1];
      end;
    for i := Ord(d_6A44[0]) to 22 do
      d_6A44 := d_6A44 + ' ';
    Str(d_699A:7, s);
    d_6A44 := d_6A44 + s;
    d_6B44.Scores[j] := d_699A;
    d_6B44.Names[j] := d_6A44;
    u3_9a71;
  end;
end;
