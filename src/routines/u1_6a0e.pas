{@decls}

{@stubs}

{@body}
procedure u1_6a0e;
begin
  if (d_6EC1 = 0) and (d_6EC2 = 0) then
    u1_66b3;

  if (d_69B4 = 0) and (d_6EC1 = 0) and (d_6EC0 = 0) then
    if (d_6ECD <> 0) or (u6_0038 and (d_341C)) then
    begin
      if d_0296[(((d_34EC[1].X + 3) shr 4) + 1), (((d_34EC[1].Y - 3) shr 4) + 1)].Solid = 0 then
      begin
        if d_0296[(((d_34EC[1].X + 12) shr 4) + 1), (((d_34EC[1].Y - 3) shr 4) + 1)].Solid = 0 then
        begin
          if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) or (d_34EC[1].Sprite = 13) then
            d_34EC[1].Sprite := 13
          else
            d_34EC[1].Sprite := 14;
          u7_0000(1);
          d_6EC1 := 1;
          d_6EC2 := 0;
          d_34EA := 0;
        end;
      end;
    end;

  if d_6EC1 <> 0 then
  begin
    Inc(d_34EA);
    if d_34EA = 10 then
    begin
      d_6EC1 := 0;
      d_34EA := 9;
    end;
    if d_34EA < 17 then
      if u1_65d9(0, -Integer(d_34B0[d_34EA])) then
      begin
        if d_683A > 0 then
          if d_683A + 80 > d_34EC[1].Y then
          begin
            Dec(d_683A, d_34B0[d_34EA]);
            if d_683A < 0 then
              d_683A := 0;
          end;
        Dec(d_34EC[1].Y, d_34B0[d_34EA]);
      end
      else
      begin
        d_34EA := 9;
        d_6EC1 := 0;
      end;
  end;
end;
