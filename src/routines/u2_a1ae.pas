{@decls}
type
  TLevelFile = file of TLevelRow;
type
  TLevelFileViews = record
    case Byte of
      0: (Raw: File);
      1: (Typed: TLevelFile);
  end;
{@stubs}
procedure u8_0c14(var Data; Count: Word);
{@body}
procedure u2_a1ae(Level: Integer);
var
  I: Integer;
  F: TLevelFileViews;
  Row: TLevelRow;
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
    d_34EC[I].Frame := 1;
    d_34EC[I].Speed := 1;
    d_34EC[I].Tick := 0;
    d_34EC[I].Limit := 0;
    d_34EC[I].Aux1 := 0;
    d_34EC[I].Aux2 := 0;
    d_34EC[I].Kind := 1;
    d_34EC[I].Inactive := 1;
    d_34EC[I].Marked := 1;
  end;
  for I := 1 to 10 do
  begin
    d_685A[I].Sprite := 7;
    d_685A[I].X := -41;
    d_685A[I].Y := 0;
    d_685A[I].OldX := -41;
    d_685A[I].OldY := 0;
    d_685A[I].DX := 1;
    d_685A[I].DY := 0;
    d_685A[I].Frame := 1;
    d_685A[I].Speed := 8;
    d_685A[I].Tick := 0;
    d_685A[I].Kind := 1;
    d_685A[I].Inactive := 1;
    d_685A[I].Marked := 0;
  end;
  d_6844[Level] := 0;
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
