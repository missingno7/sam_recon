{@decls}
type
  TActor = record
    State: Word;
    X, Y, OldX, OldY: Integer;
    Phase, F12, F14, F16, F18: Word;
    Sprite: Word;
    DX, DY: Integer;
    Speed, F28: Word;
    Flag1, Flag2: Byte;
  end;
  TStageSlots = packed record
    case Byte of
      0: (F06: Word; F08, F0A: Word; Pad0C: array[0..5] of Byte;
          F12, F14, F16, F18, F1A: Word; Flag1, Flag2: Byte;
          Pad1E: array[0..1] of Byte);
      1: (HighF06: Byte; LevelBytes: array[0..24] of Byte);
  end;
  TStageInfo = packed record
    F00, F02, F04: Integer;
    Slots: TStageSlots;
  end;
  TLevelLine = array[1..42] of Char;
  TLevelFile = file of TLevelLine;
  TLevelFileViews = record
    case Byte of
      0: (Raw: File);
      1: (Typed: TLevelFile);
  end;
var
  d_34EC: array[1..25] of TActor;
  d_682E: Word;
  d_6832: Integer;
  d_6834: Word;
  d_683C: array[0..10] of TStageInfo;
{@stubs}
procedure u9_2f32;
procedure u8_0c14(var Data; Count: Word);
procedure u2_68a9(RowIndex: Integer; Row: TLevelLine);
procedure u9_0625(N: Word);
procedure u9_07ee(A, B, C, D: Word);
procedure u3_00db(N: Word);
procedure u7_0000(N: Word);
{@body}
procedure u2_a1ae(Level: Integer);
var
  I: Integer;
  F: TLevelFileViews;
  Row: TLevelLine;
  Work: String[40];
begin
  d_682E := 1;
  u9_2f32;
  d_6832 := -1;
  for I := 2 to 25 do
  begin
    d_34EC[I].State := 0;
    d_34EC[I].Sprite := 9;
    d_34EC[I].X := -41;
    d_34EC[I].Y := 0;
    d_34EC[I].OldX := -41;
    d_34EC[I].OldY := 0;
    d_34EC[I].DX := 1;
    d_34EC[I].DY := 0;
    d_34EC[I].Phase := 1;
    d_34EC[I].Speed := 1;
    d_34EC[I].F12 := 0;
    d_34EC[I].F14 := 0;
    d_34EC[I].F16 := 0;
    d_34EC[I].F18 := 0;
    d_34EC[I].F28 := 1;
    d_34EC[I].Flag1 := 1;
    d_34EC[I].Flag2 := 1;
  end;
  for I := 1 to 10 do
  begin
    d_683C[I].Slots.F12 := 7;
    d_683C[I].F00 := -41;
    d_683C[I].F02 := 0;
    d_683C[I].F04 := -41;
    d_683C[I].Slots.F06 := 0;
    d_683C[I].Slots.F14 := 1;
    d_683C[I].Slots.F16 := 0;
    d_683C[I].Slots.F08 := 1;
    d_683C[I].Slots.F18 := 8;
    d_683C[I].Slots.F0A := 0;
    d_683C[I].Slots.F1A := 1;
    d_683C[I].Slots.Flag1 := 1;
    d_683C[I].Slots.Flag2 := 0;
  end;
  d_683C[0].Slots.LevelBytes[Level] := 0;
  if IOResult <> 0 then ;
  case Level of
    1: begin
    d_6834 := 0;
{$IFDEF SAM1}
    Assign(F.Raw, 'SAM103.GFX');
{$ENDIF}
{$IFDEF SAM2}
    Assign(F.Raw, 'SAM203.GFX');
{$ENDIF}
{$IFDEF SAM3}
    Assign(F.Raw, 'SAM303.GFX');
{$ENDIF}
    Reset(F.Raw, 42);
    Read(F.Typed, Row);
    u8_0c14(Row, 40);
    Work := Row[1] + Row[2] + Row[3];
    Val(Work, d_681A, I);
    Read(F.Typed, Row);
    u8_0c14(Row, 40);
    u2_68a9(24, Row);
    for I := 0 to 23 do
    begin
      Read(F.Typed, Row);
      u8_0c14(Row, 40);
      if Row[1] = '*' then
        Dec(I);
      u2_68a9(I, Row);
    end;
    Close(F.Raw);
    end;
    2..17: begin
{$IFDEF SAM1}
    Assign(F.Raw, 'SAM103.GFX');
{$ENDIF}
{$IFDEF SAM2}
    Assign(F.Raw, 'SAM203.GFX');
{$ENDIF}
{$IFDEF SAM3}
    Assign(F.Raw, 'SAM303.GFX');
{$ENDIF}
    Reset(F.Raw, 42);
    for I := 1 to (Level - 1) * 48 do
      Read(F.Typed, Row);
    Read(F.Typed, Row);
    u8_0c14(Row, 40);
    Work := Row[1] + Row[2] + Row[3];
    Val(Work, d_681A, I);
    Read(F.Typed, Row);
    u8_0c14(Row, 40);
    u2_68a9(24, Row);
    for I := 0 to 23 do
    begin
      Read(F.Typed, Row);
      u8_0c14(Row, 40);
      if Row[1] = '*' then
        Dec(I);
      u2_68a9(I, Row);
    end;
    Close(F.Raw);
    end;
  end;
  u9_0625(0);
  u9_07ee(0, 80, 0, 8);
  u3_00db(20);
  u7_0000(13);
end;




