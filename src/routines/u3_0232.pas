{@decls}

{@stubs}
procedure u9_0352(X, Y: Integer);
{@body}
procedure u3_0232(Ticks: Word);
var
  I: Integer;
begin
  for I := 0 to 15 do
  begin
    Delay(Ticks);
    u9_0352(I, 0);
  end;
end;
