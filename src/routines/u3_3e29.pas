{@decls}
type
  TSaveData = packed record
    x: Integer;
    y: Integer;
    world: Pointer;
    count: Integer;
    view: Integer;
    case Byte of
      0: (level: Integer; rawTail: array[0..57] of Byte);
      1: (levelLow: Byte;
          inventory: array[0..20] of Byte;
          score: Integer;
          flags: Integer;
          mode: Byte;
          state: Integer;
          key: Byte;
          room: Byte;
          pos: Integer;
          health: Integer;
          ammo: Integer;
          case Byte of
            0: (life: Integer; rest: array[0..20] of Byte);
            1: (lifeLow: Byte;
                extras: array[0..20] of Byte;
                last: Byte));
  end;
  TSaveFile = file of TSaveData;
  TOverlappedWordAndBytes = packed record
    case Byte of
      0: (whole: Integer; spare: array[0..19] of Byte);
      1: (low: Byte; values: array[0..20] of Byte);
  end;
var
  d_34EE: Integer;
  d_34F0: Integer;
  d_6843: Byte;
  d_6844: array[1..20] of Byte;
  d_6858: Integer;
  d_699A: Pointer;
  d_699E: Integer;
  d_69A2: Integer;
  d_69A4: Integer;
  d_69A6: Integer;
  d_69AA: Integer;
  d_69AC: Byte;
  d_69AD: Byte;
  d_69AE: Integer;
  d_69B0: Byte;
  d_69B2: Integer;
  d_69B6: Integer;
  d_69B8: TOverlappedWordAndBytes;
  d_69DC: Byte;
  d_6D18: TSaveData;
{@stubs}
{@body}
procedure u3_3e29(slot: Integer);
var
  f: TSaveFile;
  i: Word;
  slotText: string;
begin
  d_6D18.x := LongInt(d_34EE + 8) and $FFF0;
  d_6D18.y := LongInt(d_34F0 + 8) and $FFF0;
  d_6D18.world := d_699A;
  d_6D18.count := d_699E;
  d_6D18.view := d_6858;
  d_6D18.level := d_69A2;
  for i := 1 to 20 do
    d_6D18.inventory[i] := d_6844[i];
  d_6D18.score := d_69A4;
  d_6D18.flags := d_69A6;
  d_6D18.mode := d_69AD;
  d_6D18.state := d_69AA;
  d_6D18.key := d_69AC;
  d_6D18.room := d_69B0;
  d_6D18.pos := d_69AE;
  d_6D18.health := d_69B2;
  d_6D18.ammo := d_69B6;
  d_6D18.life := d_69B8.whole;
  for i := 1 to 20 do
    d_6D18.extras[i] := d_69B8.values[i];
  d_6D18.last := d_69DC;

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
