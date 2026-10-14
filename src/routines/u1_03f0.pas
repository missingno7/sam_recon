{@decls}

{@stubs}

{@body}
procedure u1_03f0(param1, param2: Integer; param3: Word);
var
  idx: Word;
  found: String[4];
begin
  idx := 0;
  found[1] := #0;
  repeat
    Inc(idx);
    if d_34EC[idx].Inactive = 1 then
    begin
      d_34EC[idx].State := 0;
      d_34EC[idx].X := param1;
      d_34EC[idx].Y := param2;
      d_34EC[idx].OldX := param1;
      d_34EC[idx].OldY := param2;
      d_34EC[idx].DY := 0;
      d_34EC[idx].Speed := 0;
      d_34EC[idx].Tick := 0;
      d_34EC[idx].Limit := $10;
      d_34EC[idx].Inactive := 0;
      d_34EC[idx].Marked := 0;
      d_34EC[idx].Kind := $1389;
      d_34EC[idx].Sprite := param3 + $96;
      d_34EC[idx].Frame := 1;
      d_34EC[idx].Speed := 0;
      d_34EC[idx].DX := 1;
      u9_19f9(d_6D96^.Images[param3].Pixels[1],
        d_34EC[idx].X, Word((LongInt(d_34EC[idx].Y + 8) and $fff0) + $10));
      u9_19f9(d_6D96^.Images[param3].Pixels[1],
        d_34EC[idx].X, Word((LongInt(d_34EC[idx].Y + 8) and $fff0) + $1a0));
      found[1] := #1;
    end;
  until (found[1] <> #0) or (idx = $19);
end;
