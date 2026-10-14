{@decls}

{@stubs}

{@body}
function u1_027c(X, Y: Integer): Boolean;
var
  I: Integer;
begin
  u1_027c := False;
  for I := 1 to d_69A2 do
  begin
    if (d_685A[I].Inactive = 0) and
       (d_685A[I].X + 7 >= X) and
       (d_685A[I].X <= X + 6) and
       (d_685A[I].Y + 8 >= Y) and
       (d_685A[I].Y <= Y + 8) then
    begin
      u1_027c := True;
      d_685A[I].Marked := 1;
      u2_0000(d_685A[I].X, d_685A[I].Y);
      u2_2530(d_685A[I].X, d_685A[I].Y);
      if (X and $000F) > 0 then
      begin
        u2_0000(d_685A[I].X - 16, d_685A[I].Y);
        u2_0000(d_685A[I].X + 16, d_685A[I].Y);
        u2_2530(d_685A[I].X - 16, d_685A[I].Y);
        u2_2530(d_685A[I].X + 16, d_685A[I].Y);
      end;
    end;
  end;
end;
