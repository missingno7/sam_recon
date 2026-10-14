{@decls}
var
  d_683E: Word;
  d_6840: Word;
{@stubs}
{@body}
procedure u3_007c;
begin
  if d_683E = 0 then
  begin
    d_683E := 1;
    d_6840 := $01A0;
  end
  else
  begin
    d_683E := 0;
    d_6840 := $0010;
  end;
end;
