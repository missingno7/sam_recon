{@decls}

{@stubs}

{@body}
function u6_0000: Boolean;
var
  X, Y: Integer;
begin
  X := u6_00cc(0);
  Y := u6_00cc(1);
  if (X = -1) and (Y = -1) then
    u6_0000 := False
  else
    u6_0000 := True;
end;
