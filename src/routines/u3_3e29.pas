{@decls}
type
  TSaveFile = file of TSaveData;
{@stubs}

{@body}
procedure u3_3e29(slot: Integer);
var
  f: TSaveFile;
  i: Word;
  slotText: string;
begin
  d_6D18.X := LongInt(d_34EC[1].X + 8) and $FFF0;
  d_6D18.Y := LongInt(d_34EC[1].Y + 8) and $FFF0;
  d_6D18.Score := d_699A;
  d_6D18.Count := d_699E;
  d_6D18.Ammo := d_6858;
  d_6D18.ProjectileCount := d_69A2;
  for i := 1 to 20 do
    d_6D18.FlagsA[i] := d_6844[i];
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
  for i := 1 to 20 do
    d_6D18.FlagsB[i] := d_69BA[i];
  d_6D18.FlagC := d_69DC;

  Str(slot:1, slotText);
{$IFDEF SAM1}
  Assign(f, 'SAM1-' + slotText + '.SAV');
{$ENDIF}
{$IFDEF SAM2}
  Assign(f, 'SAM2-' + slotText + '.SAV');
{$ENDIF}
{$IFDEF SAM3}
  Assign(f, 'SAM3-' + slotText + '.SAV');
{$ENDIF}
  Rewrite(f);
  Write(f, d_6D18);
  Close(f);
end;
