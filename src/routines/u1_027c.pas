{@decls}
type
  TObjectRecord = record
    X: Integer;
    Y: Integer;
    Padding: array[1..24] of Byte;
    Active: Byte;
    Marked: Byte;
    Tail: array[1..2] of Byte;
  end;
var
  d_683C: array[0..10] of TObjectRecord;
  d_69A2: Integer;
{@stubs}
procedure u2_0000(X, Y: Integer);
procedure u2_2530(X, Y: Integer);
{@body}
function u1_027c(X, Y: Integer): Boolean;
var
  I: Integer;
begin
  u1_027c := False;
  for I := 1 to d_69A2 do
  begin
    if (d_683C[I].Active = 0) and
       (d_683C[I].X + 7 >= X) and
       (d_683C[I].X <= X + 6) and
       (d_683C[I].Y + 8 >= Y) and
       (d_683C[I].Y <= Y + 8) then
    begin
      u1_027c := True;
      d_683C[I].Marked := 1;
      u2_0000(d_683C[I].X, d_683C[I].Y);
      u2_2530(d_683C[I].X, d_683C[I].Y);
      if (X and $000F) > 0 then
      begin
        u2_0000(d_683C[I].X - 16, d_683C[I].Y);
        u2_0000(d_683C[I].X + 16, d_683C[I].Y);
        u2_2530(d_683C[I].X - 16, d_683C[I].Y);
        u2_2530(d_683C[I].X + 16, d_683C[I].Y);
      end;
    end;
  end;
end;