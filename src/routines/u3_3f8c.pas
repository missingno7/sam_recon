{@decls}
type
  TSaveData = packed record
    MapX: Word;
    MapY: Word;
    MapAddress: Pointer;
    MapSize: Word;
    CurrentLevel: Word;
    PlayerInfo: Word;
    ObjectsA: array[1..20] of Byte;
    Score: Word;
    Lives: Word;
    PlayerMode: Byte;
    PlayerX: Word;
    PlayerState: Byte;
    PlayerDirection: Byte;
    PlayerY: Word;
    Energy: Word;
    Ammo: Word;
    Items: Word;
    ObjectsB: array[1..20] of Byte;
    LastValue: Byte;
  end;
  TSaveFile = file of TSaveData;
var
  d_6D18: TSaveData;
  d_6844: array[1..20] of Byte;
  d_6858: Word;
  d_699A: Pointer;
  d_699E: Word;
  d_69A2: Word;
  d_69A4: Word;
  d_69A6: Word;
  d_69AA: Word;
  d_69AE: Word;
  d_69B2: Word;
  d_69B6: Word;
  d_69B8: Word;
  d_69BA: array[1..20] of Byte;
{@stubs}
procedure u3_9b3e(input: string);
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
    d_34EE := d_6D18.MapX;
    d_34F0 := d_6D18.MapY;
    d_699A := d_6D18.MapAddress;
    d_699E := d_6D18.MapSize;
    d_6858 := d_6D18.CurrentLevel;
    d_69A2 := d_6D18.PlayerInfo;
    for I := 1 to 20 do
      d_6844[I] := d_6D18.ObjectsA[I];
    d_69A4 := d_6D18.Score;
    d_69A6 := d_6D18.Lives;
    d_69AD := d_6D18.PlayerMode;
    d_69AA := d_6D18.PlayerX;
    d_69AC := d_6D18.PlayerState;
    d_69B0 := d_6D18.PlayerDirection;
    d_69AE := d_6D18.PlayerY;
    d_69B2 := d_6D18.Energy;
    d_69B6 := d_6D18.Ammo;
    d_69B8 := d_6D18.Items;
    for I := 1 to 20 do
      d_69BA[I] := d_6D18.ObjectsB[I];
    d_69DC := d_6D18.LastValue;
    u3_3f8c := True;
  end
  else
  begin
    u3_9b3e('File Not Found!');
    u3_3f8c := False;
  end;
{$I+}
end;
