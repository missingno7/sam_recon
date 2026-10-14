{@decls}

{@stubs}

{@body}
procedure u1_66b3;
begin
  Inc(d_34EA);
  if d_34EA > 19 then
    d_34EA := 19;
  d_6EC0 := 1;
  Inc(d_34EC[1].Y, d_34B0[d_34EA]);
  if (d_0296[((d_34EC[1].X + 3) shr 4) + 1, ((d_34EC[1].Y shr 4) + 2)].Solid <> 0) or
     (d_0296[((d_34EC[1].X + 12) shr 4) + 1, ((d_34EC[1].Y shr 4) + 2)].Solid <> 0) then
  begin
    Inc(d_6818);
    d_34EC[1].Y := d_34EC[1].Y and $FFF0;
    d_6EC0 := 0;
  end;
  if d_34EA > 10 then
  begin
    if (d_0296[((d_34EC[1].X + 3) shr 4) + 1, ((d_34EC[1].Y + 16) shr 4) + 1].Special <> 0) or
       (d_0296[((d_34EC[1].X + 12) shr 4) + 1, ((d_34EC[1].Y + 16) shr 4) + 1].Special <> 0) then
    begin
      if d_34EC[1].Y < 5 then
      begin
        Inc(d_6818);
        d_34EC[1].Y := d_34EC[1].Y and $FFF0;
        d_6EC0 := 0;
      end
      else if (d_0296[((d_34EC[1].X + 3) shr 4) + 1, ((d_34EC[1].Y + 7) shr 4) + 1].Special = 0) and
              (d_0296[((d_34EC[1].X + 12) shr 4) + 1, ((d_34EC[1].Y + 7) shr 4) + 1].Special = 0) then
      begin
        Inc(d_6818);
        d_34EC[1].Y := d_34EC[1].Y and $FFF0;
        d_6EC0 := 0;
      end;
    end;
  end;
  if d_683A + 120 < d_34EC[1].Y then
  begin
    if d_683A + d_34B0[d_34EA] < 184 then
      Inc(d_683A, d_34B0[d_34EA])
    else
      d_683A := 184;
  end;
  if d_6EC0 <> 0 then
  begin
    if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) or (d_34EC[1].Sprite = 13) then
      d_34EC[1].Sprite := 13
    else
      d_34EC[1].Sprite := 14;
  end
  else if d_34EC[1].Sprite = 13 then
  begin
    if d_6ECB <> 0 then
      d_34EC[1].Sprite := 1
    else
      d_34EC[1].Sprite := 9;
  end
  else if d_34EC[1].Sprite = 14 then
  begin
    if d_6ECA <> 0 then
      d_34EC[1].Sprite := 5
    else
      d_34EC[1].Sprite := 10;
  end;
end;
