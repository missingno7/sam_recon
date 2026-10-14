{@decls}
type
  TSaveFile = file of TSaveData;
{@stubs}

{@body}
function u3_3f8c(Slot: Integer): Boolean;
var
  F: TSaveFile;
  I: Integer;
  NumberString: string;
  OK: Boolean;
begin
  Str(Slot:1, NumberString);
{$I-}
{$IFDEF SAM1}
  Assign(F, 'SAM1-' + NumberString + '.SAV');
{$ENDIF}
{$IFDEF SAM2}
  Assign(F, 'SAM2-' + NumberString + '.SAV');
{$ENDIF}
{$IFDEF SAM3}
  Assign(F, 'SAM3-' + NumberString + '.SAV');
{$ENDIF}
  Reset(F);
  OK := IOResult = 0;
  Reset(F);
  OK := IOResult = 0;

  if OK then
  begin
    Read(F, d_6D18);
    Close(F);
    d_34EC[1].X := d_6D18.X;
    d_34EC[1].Y := d_6D18.Y;
    d_699A := d_6D18.Score;
    d_699E := d_6D18.Count;
    d_6858 := d_6D18.Ammo;
    d_69A2 := d_6D18.ProjectileCount;
    for I := 1 to 20 do
      d_6844[I] := d_6D18.FlagsA[I];
    d_69A4 := d_6D18.TimerA;
    d_69A6 := d_6D18.TimerB;
    d_69AD := d_6D18.Mode;
    d_69AA := d_6D18.TimerC;
    d_69AC := d_6D18.FlagA;
    d_69B0 := d_6D18.FlagB;
    d_69AE := d_6D18.TimerD;
    d_69B2 := d_6D18.ValueA;
    d_69B6 := d_6D18.ValueB;
    d_69B8 := d_6D18.ValueC;
    for I := 1 to 20 do
      d_69BA[I] := d_6D18.FlagsB[I];
    d_69DC := d_6D18.FlagC;
    u3_3f8c := True;
  end
  else
  begin
    u3_9b3e('File Not Found!');
    u3_3f8c := False;
  end;
{$I+}
end;
