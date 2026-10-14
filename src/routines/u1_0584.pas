{@decls}

{@stubs}

{@body}
procedure u1_0584(X, Y, TypeCode, Value, EntryId: Integer);
var
  I, Spare1, Spare2: Integer;
  Found: Boolean;
begin
  I := 0;
  Found := False;
  repeat
    Inc(I);
    if d_34EC[I].Inactive = 1 then
    begin
      u7_0000(3);
      d_34EC[I].DX := TypeCode;
      if d_34EC[I].DX = -1 then
        d_34EC[I].Frame := $15
      else
        d_34EC[I].Frame := 1;
      d_34EC[I].DY := 0;
      d_34EC[I].State := 0;
      if EntryId <> $89 then
        d_34EC[I].X := X and $FFF8
      else
        d_34EC[I].X := X;
      d_34EC[I].Y := Y;
      d_34EC[I].OldX := X;
      d_34EC[I].OldY := Y;
      d_34EC[I].Speed := Value;
      d_34EC[I].Tick := 0;
      d_34EC[I].Limit := 0;
      d_34EC[I].Inactive := 0;
      d_34EC[I].Marked := 0;
      if EntryId = 0 then
      begin
        d_34EC[I].Sprite := $27;
        d_34EC[I].Kind := 7;
        d_34EC[I].Frame := 1;
      end
      else
      begin
        d_34EC[I].Sprite := EntryId;
        if (d_34EC[I].Sprite = $1D6) or
           (d_34EC[I].Sprite = $7D) or
           (d_34EC[I].Sprite = $7E) then
        begin
          d_34EC[I].Kind := 7;
          d_34EC[I].Frame := 1;
        end
        else if (d_34EC[I].Sprite = $339) or
                (d_34EC[I].Sprite = $33B) then
        begin
          d_34EC[I].Kind := $13;
          d_34EC[I].Frame := 1;
        end
        else if d_34EC[I].Sprite = $72 then
        begin
          d_34EC[I].Kind := $25;
          d_34EC[I].Frame := 1;
          d_34EC[I].DY := TypeCode;
        end
        else if d_34EC[I].Sprite = $C7 then
        begin
          d_34EC[I].Sprite := $72;
          d_34EC[I].Kind := $89;
          d_34EC[I].Frame := 1;
          d_34EC[I].DY := TypeCode;
        end
        else if d_34EC[I].Sprite = $89 then
        begin
          d_34EC[I].Kind := $28;
          d_34EC[I].Frame := 1;
          d_34EC[I].Limit := $1E;
        end
        else
          d_34EC[I].Kind := $0E;
      end;
      Found := True;
    end;
  until Found or (I = 25);
end;
