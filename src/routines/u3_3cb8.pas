{@decls}

{@stubs}

{@body}
procedure u3_3cb8;
var
  I: Integer;
begin
  d_6D18.X := d_34EC[1].X;
  d_6D18.Y := d_34EC[1].Y;
  d_6D18.Score := d_699A;
  d_6D18.Count := d_699E;
  d_6D18.Ammo := d_6858;
  d_6D18.ProjectileCount := d_69A2;
  for I := 1 to 20 do
    d_6D18.FlagsA[I] := d_6844[I];
  d_6D18.TimerA := d_69A4;
  d_6D18.TimerB := d_69A6;
  d_6D18.Mode := d_69AD;
  d_6D18.TimerC := d_69AA;
  d_6D18.FlagA := d_69AC;
  d_6D18.FlagB := d_69B0;
  d_6D18.TimerD := d_69AE;
  d_6D18.ValueA := d_69B2;
  d_6D18.ValueB := d_69B6;
  d_6D18.ValueC := d_69B8;
  for I := 1 to 20 do
    d_6D18.FlagsB[I] := d_69BA[I];
  d_6D18.FlagC := d_69DC;
end;
