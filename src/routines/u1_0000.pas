{@decls}
type
  TObjectRecord = record
    X: Integer;
    Y: Integer;
    Padding: array[1..28] of Byte;
  end;
var
  d_34CE: array[0..64] of TObjectRecord;
{@stubs}
{@body}
function u1_0000(Distance, Item: Integer): Boolean;
begin
  if d_34CE[Item].X < d_6838 - Distance then
    u1_0000 := False
  else if d_34CE[Item].X > d_6838 + 320 + Distance then
    u1_0000 := False
  else if d_34CE[Item].Y < d_683A - Distance then
    u1_0000 := False
  else if d_34CE[Item].Y > d_683A + 184 + Distance then
    u1_0000 := False
  else
    u1_0000 := True;
end;
