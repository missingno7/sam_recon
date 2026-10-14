{@decls}

{@stubs}

{@body}
procedure u1_01c4(x, y: Integer);
begin
  if ((d_34EC[1].X >= x) and (x + 9 >= d_34EC[1].X)) or
     ((d_34EC[1].X + 9 >= x) and (d_34EC[1].X <= x)) then
  begin
    if ((d_34EC[1].Y >= y) and (y + 15 >= d_34EC[1].Y)) or
       ((d_34EC[1].Y + 15 >= y) and (d_34EC[1].Y <= y)) then
    begin
      if d_69F5 = 0 then
      begin
        if d_69F3 = 0 then
        begin
          if d_6A40 > 1 then
          begin
            if d_6A41 = 0 then
            begin
              d_6A41 := 1;
              d_6A42 := 30;
              Dec(d_6A40);
              d_6832 := -1;
              d_34EC[1].State := 5;
              u7_0000(7);
            end;
          end
          else
          begin
            if d_6A41 = 0 then
            begin
              u7_0000($16);
              d_69F5 := 1;
              d_69F6 := $23;
            end;
          end;
        end;
      end;
    end;
  end;
end;
