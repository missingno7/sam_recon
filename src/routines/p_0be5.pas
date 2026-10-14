{@decls}

{@stubs}

{@body}
procedure p_0be5; interrupt;
begin
  inline($FA);
  Inc(d_682C);
  Inc(d_0294[0]);
  if d_0294[0] = 20 then
  begin
    d_0294[0] := 0;
    if d_69A6 > 0 then
    begin
      Dec(d_69A6);
      if d_69A6 = 0 then
      begin
        d_69A4 := 0;
        d_6832 := -1;
      end;
    end;
    if d_69AE > 0 then
    begin
      Dec(d_69AE, 2);
      if d_69AE = 0 then
      begin
        d_69B0 := 0;
        d_6832 := -1;
      end;
    end;
    if d_69AA > 0 then
    begin
      Dec(d_69AA, 2);
      if d_69AA = 0 then
      begin
        d_69AC := 1;
        d_69AD := 0;
        d_6832 := -1;
      end;
    end;
  end;

  if (d_34AE <> 0) and (d_34AF <> 0) then
  begin
    case d_34AA of
      1..12:
        begin
          Sound(d_341E^[d_34AA, d_34AC]);
          Inc(d_34AC);
          if d_34AC mod d_341E^[d_34AA, 303] = 0 then
            NoSound;
          if d_341E^[d_34AA, d_34AC] = -1 then
          begin
            d_34AE := 0;
            d_34AC := 1;
            NoSound;
          end;
        end;
      13..24:
        begin
          Sound(d_3422^[d_34AA - 12, d_34AC]);
          Inc(d_34AC);
          if d_34AC mod d_3422^[d_34AA - 12, 303] = 0 then
            NoSound;
          if d_3422^[d_34AA - 12, d_34AC] = -1 then
          begin
            d_34AE := 0;
            d_34AC := 1;
            NoSound;
          end;
        end;
      25..36:
        begin
          Sound(d_3426^[d_34AA - 24, d_34AC]);
          Inc(d_34AC);
          if d_34AC mod d_3426^[d_34AA - 24, 303] = 0 then
            NoSound;
          if d_3426^[d_34AA - 24, d_34AC] = -1 then
          begin
            d_34AE := 0;
            d_34AC := 1;
            NoSound;
          end;
        end;
    end;
  end;
  inline($FB);
end;
