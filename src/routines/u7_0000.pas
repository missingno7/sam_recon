{@decls}

{@stubs}

{@body}
procedure u7_0000(N: Integer);
var
  Value: Integer;
  Uninitialized: Integer;
begin
  if d_34AE <> 0 then
  begin
    case N of
      1..12: Value := d_341E^[N, 301];
      13..24: Value := d_3422^[N - 12, 301];
      25..36: Value := d_3426^[N - 24, 301];
    end;

    case d_34AA of
      1..12: Value := d_341E^[d_34AA, 301];
      13..24: Value := d_3422^[d_34AA - 12, 301];
      25..36: Value := d_3426^[d_34AA - 24, 301];
    end;

    if Value >= Uninitialized then
    begin
      d_34AC := 1;
      d_34AE := 1;
      d_34AA := N;
    end;
  end
  else
  begin
    d_34AC := 1;
    d_34AE := 1;
    d_34AA := N;
  end;
end;
