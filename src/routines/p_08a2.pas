{@decls}

{@stubs}

{@body}
procedure p_08a2;
var
  i: Integer;
  changed: Byte;
begin
  d_6D6C := u6_00cc(0);
  d_6D6E := u6_00cc(1);
  if d_6EBF <> 0 then
  begin
    d_6EBF := 0;
    if d_34EC[1].Sprite = 11 then
      d_34EC[1].Sprite := 9
    else if d_34EC[1].Sprite = 12 then
      d_34EC[1].Sprite := 10;
  end;
  if d_6D68 - 50 > d_6D6C then
  begin
    d_6ECA := 1;
    d_6ECB := 0;
    d_6EC2 := 0;
    d_6D70 := 1;
    if (d_6EC1 = 0) and (d_6EC0 = 0) then
      d_34EC[1].Sprite := 5
    else
      d_34EC[1].Sprite := 14;
  end
  else if d_6D68 + 50 < d_6D6C then
  begin
    d_6ECB := 1;
    d_6ECA := 0;
    d_6EC2 := 0;
    d_6D70 := 1;
    if (d_6EC1 = 0) and (d_6EC0 = 0) then
      d_34EC[1].Sprite := 1
    else
      d_34EC[1].Sprite := 13;
  end
  else if d_6D70 <> 0 then
  begin
    if (d_6ECB = 1) or (d_34EC[1].Sprite = 1) then
      d_34EC[1].Sprite := 9
    else
      d_34EC[1].Sprite := 10;
    d_6ECB := 0;
    d_6ECA := 0;
    d_6D70 := 0;
  end;

  if d_681C = 1 then
  begin
    if d_6D6A - 50 > d_6D6E then
    begin
      d_6EC3 := 1;
      d_6D71 := 1;
      if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) then
        d_34EC[1].Sprite := 1
      else
        d_34EC[1].Sprite := 5;
    end
    else if d_6D6A + 50 < d_6D6E then
    begin
      d_6EC4 := 1;
      d_6D71 := 1;
      if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) then
        d_34EC[1].Sprite := 1
      else
        d_34EC[1].Sprite := 5;
    end
    else if d_6D71 <> 0 then
    begin
      d_6D71 := 0;
      d_6EC3 := 0;
      d_6EC4 := 0;
      if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) then
        d_34EC[1].Sprite := 9
      else
        d_34EC[1].Sprite := 10;
    end;
  end;

  if not u6_0058 then
    Exit;
  if d_6858 <= 0 then
    Exit;
  if d_681C <= 1 then
    Exit;
  if d_69F5 <> 0 then
    Exit;

  changed := 0;
  i := 0;
  repeat
    Inc(i);
    if d_685A[i].Inactive = 1 then
    begin
      d_685A[i].X := d_34EC[1].X;
      d_685A[i].Y := d_34EC[1].Y;
      d_685A[i].OldX := d_34EC[1].OldX;
      d_685A[i].OldY := d_34EC[1].OldY;
      d_685A[i].Sprite := 39;
      if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 13) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) then
      begin
        d_685A[i].DX := 1;
        d_6EBF := 1;
        d_34EC[1].Sprite := 11;
      end
      else
      begin
        d_685A[i].DX := -1;
        d_6EBF := 1;
        d_34EC[1].Sprite := 12;
      end;
      d_685A[i].DY := 0;
      d_685A[i].Frame := 1;
      d_685A[i].Speed := 8;
      d_685A[i].Tick := 0;
      d_685A[i].Limit := 0;
      d_685A[i].Kind := 7;
      d_685A[i].Inactive := 0;
      d_685A[i].Marked := 0;
      changed := 1;
      Dec(d_6858);
      d_6832 := -1;
      u7_0000(2);
      if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 13) or (d_34EC[1].Sprite = 11) then
        d_34EC[1].Sprite := 11
      else
        d_34EC[1].Sprite := 12;
    end;
  until (i = d_69A2) or (changed <> 0);
end;
