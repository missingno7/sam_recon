{@decls}
var
  d_34EC: Word;
  d_34EE: Integer;
  d_34F0: Integer;
  d_6832: Word;
  d_69F3: Byte;
  d_69F5: Byte;
  d_69F6: Byte;
  d_6A40: Byte;
  d_6A41: Byte;
  d_6A42: Byte;
{@stubs}
procedure u7_0000(mode: Integer);
{@body}
procedure u1_01c4(x, y: Integer);
begin
  if ((d_34EE >= x) and (x + 9 >= d_34EE)) or
     ((d_34EE + 9 >= x) and (d_34EE <= x)) then
  begin
    if ((d_34F0 >= y) and (y + 15 >= d_34F0)) or
       ((d_34F0 + 15 >= y) and (d_34F0 <= y)) then
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
              d_6832 := $FFFF;
              d_34EC := 5;
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







