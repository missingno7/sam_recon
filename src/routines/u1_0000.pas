{@decls}

{@stubs}

{@body}
function u1_0000(Distance, Item: Integer): Boolean;
begin
  if d_34EC[Item].X < d_6838 - Distance then
    u1_0000 := False
  else if d_34EC[Item].X > d_6838 + 320 + Distance then
    u1_0000 := False
  else if d_34EC[Item].Y < d_683A - Distance then
    u1_0000 := False
  else if d_34EC[Item].Y > d_683A + 184 + Distance then
    u1_0000 := False
  else
    u1_0000 := True;
end;
