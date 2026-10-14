{@decls}

{@stubs}

{@body}
function u1_008d(margin: Integer; slot: Word): Boolean;
begin
  if d_685A[slot].X < d_6838 - margin then
  begin
    u1_008d := False;
    Exit;
  end;
  if d_685A[slot].X > d_6838 + $0140 + margin then
  begin
    u1_008d := False;
    Exit;
  end;
  if d_685A[slot].Y < d_683A - margin then
  begin
    u1_008d := False;
    Exit;
  end;
  if d_685A[slot].Y > d_683A + $00B8 + margin then
  begin
    u1_008d := False;
    Exit;
  end;
  u1_008d := True;
end;
