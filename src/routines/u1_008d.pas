{@decls}
type
  TEntity = record
    x: Integer;
    y: Integer;
    padding: array[0..27] of Byte;
  end;
var
  d_6838: Integer;
  d_683A: Integer;
  d_683C: array[0..25] of TEntity;
{@stubs}
{@body}
function u1_008d(margin: Integer; slot: Word): Boolean;
begin
  if d_683C[slot].x < d_6838 - margin then
  begin
    u1_008d := False;
    Exit;
  end;
  if d_683C[slot].x > d_6838 + $0140 + margin then
  begin
    u1_008d := False;
    Exit;
  end;
  if d_683C[slot].y < d_683A - margin then
  begin
    u1_008d := False;
    Exit;
  end;
  if d_683C[slot].y > d_683A + $00B8 + margin then
  begin
    u1_008d := False;
    Exit;
  end;
  u1_008d := True;
end;



