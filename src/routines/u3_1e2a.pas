{@decls}
var
  d_6826: Integer;
  d_6828: Integer;
  d_682A: Integer;
  d_6838: Integer;
  d_683A: Integer;
  d_6EC3: Byte;
  d_6EC4: Byte;
  d_6ECA: Byte;
  d_6ECB: Byte;
{@stubs}
procedure u9_051f(var Data; X, Y: Integer);
procedure u9_1795(var Data; X1, Y1, X2, Y2: Integer);
procedure u9_1831(var Data; X, Y: Integer);
procedure u9_2b38(var Data; X, Y: Integer);
{@body}
function u3_1e2a(MaxInput: Integer): String;
var
  CursorX, CursorY: Integer;
  WindowIndex: Integer;
  MaxWidth, LastRow: Integer;
  Left, Top, Right, Bottom, Position: Integer;
  UnusedWord, BlinkX, BlinkY, BlinkCount: Integer;
  BlinkMode, StopFlag: Byte;
  FramePad: array[0..1] of Byte;
  InputText: String;
  Key: Char;
begin
  WindowIndex := 1;
  CursorX := 0;
  MaxWidth := 0;
  LastRow := 0;
  FramePad[1] := 0;
  StopFlag := 0;
  for d_6828 := 1 to 20 do
  begin
    if d_6828 = 1 then
      MaxWidth := Length(d_3812[d_6828]) - 1;
    if Length(d_3812[d_6828]) > MaxWidth then
      MaxWidth := Length(d_3812[d_6828]) - 1;
    if d_3812[d_6828] = 'END OF WINDOW' then
      LastRow := d_6828 - 2;
    for d_6826 := 1 to Length(d_3812[d_6828]) do
      if Copy(d_3812[d_6828], d_6826, 1) = '^' then
      begin
        CursorX := Pos('^', d_3812[d_6828]) + 1;
        CursorY := d_6828 + 1;
      end;
  end;

  Inc(LastRow, 3);
  Left := ((320 - (MaxWidth shl 3)) div 2 + d_6838) div 8 - 3;
  Top := ((200 - (LastRow shl 3)) div 2 + d_683A) div 8 - 2;
  CursorX := CursorX + Left;
  CursorY := CursorY + Top;
  GetMem(d_67F6, $7530);
  u9_1795(PByteArray(d_67F6)^, Left, (Top shl 3) + d_683C,
    Left + MaxWidth + 5 + 1,
    (Succ(Top + LastRow + 2) shl 3) + d_683C);
  Right := Left + MaxWidth + 4;
  Bottom := Top + LastRow + 1;

  for d_682A := 1 to Bottom - Top do
    for d_6828 := Left + 1 to Right - 1 do
      u9_2B38(PByteArray(d_6E36)^[323], d_6828,
        ((Top + d_682A) shl 3) + d_683C);

  u9_051F(PByteArray(d_6E36)^[3], Left, (Top shl 3) + d_683C);
  for d_6828 := Left + 1 to Right - 1 do
    u9_051F(PByteArray(d_6E36)^[43], d_6828, (Top shl 3) + d_683C);
  u9_051F(PByteArray(d_6E36)^[83], Right, (Top shl 3) + d_683C);
  for d_6828 := 1 to Bottom - Top do
  begin
    u9_051F(PByteArray(d_6E36)^[203], Left, ((Top + d_6828) shl 3) + d_683C);
    u9_051F(PByteArray(d_6E36)^[283], Right, ((Top + d_6828) shl 3) + d_683C);
    u9_051F(PByteArray(d_6E36)^[363], Right + 1, ((Top + d_6828) shl 3) + d_683C);
  end;
  u9_051F(PByteArray(d_6E36)^[363], Right + 1,
    ((Top + (Bottom - Top) + 1) shl 3) + d_683C);
  u9_051F(PByteArray(d_6E36)^[163], Left, (Bottom shl 3) + d_683C);
  for d_6828 := Left + 1 to Right - 1 do
    u9_051F(PByteArray(d_6E36)^[243], d_6828, (Bottom shl 3) + d_683C);
  u9_051F(PByteArray(d_6E36)^[123], Right, (Bottom shl 3) + d_683C);
  for d_6828 := Left + 1 to Right + 1 do
    u9_051F(PByteArray(d_6E36)^[363], d_6828, ((Bottom + 1) shl 3) + d_683C);

  for d_6828 := 1 to LastRow do
    if d_3812[d_6828] <> 'END OF WINDOW' then
      u3_0892(Left + 2, Top + d_6828 + 1, d_3812[d_6828]);

  d_6EC3 := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  d_6EC4 := 0;
  repeat
    MemW[0:$041C] := MemW[0:$041A];
  until Port[$60] > $80;

  InputText[0] := #0;
  Position := 0;
  Key := 'Z';
  while Key <> #13 do
  begin
    if KeyPressed then
    begin
      Key := ReadKey;
      if Key in [' ', '0'..'9', 'A'..'Z', 'a'..'z'] then
      begin
        if Key >= #32 then
        begin
          if Key <= #127 then
          begin
            if Position < MaxInput then
            begin
              InputText := InputText + Key;
              Inc(Position);
              u9_2B38(PByteArray(d_6E36)^[323], CursorX, (CursorY shl 3) + d_683C);
              u3_0892(CursorX, CursorY, Key);
              Inc(CursorX);
            end;
          end;
        end;
      end
      else if Key = #8 then
      begin
        if Position > 0 then
        begin
            u9_2B38(PByteArray(d_6E36)^[323], CursorX, (CursorY shl 3) + d_683C);
          Dec(CursorX);
            u9_2B38(PByteArray(d_6E36)^[323], CursorX, (CursorY shl 3) + d_683C);
          Delete(InputText, Length(InputText), 1);
          Dec(Position);
        end;
      end;
    end;

    d_6828 := Random(100);
    if (StopFlag = 0) and (d_6828 >= 99) then
    begin
      StopFlag := 1;
      BlinkCount := 0;
      case Random(2) of
        0:
          begin
            BlinkX := Left + Random(Right - Left - 2) + 1;
            BlinkY := Top shl 3;
            BlinkMode := 1;
          end;
        1:
          begin
            BlinkX := Left;
            BlinkY := (Top + Random(Bottom - Top - 2) + 1) * 8;
            BlinkMode := 0;
          end;
      end;
    end;

    if d_682C > 20 then
    begin
      d_682C := 0;
        u9_2B38(PByteArray(d_6E36)^[323], CursorX, (CursorY shl 3) + d_683C);
      u9_051F(d_6E3A^.Glyphs[WindowIndex + 45].Pixels[1], CursorX,
        (CursorY shl 3) + d_683C);
      Inc(WindowIndex);
      if WindowIndex > 5 then
        WindowIndex := 1;
      if StopFlag <> 0 then
      begin
        Inc(BlinkCount);
        if BlinkCount > 4 then
        begin
          StopFlag := 0;
          if BlinkMode <> 0 then
              u9_051F(PByteArray(d_6E36)^[43], BlinkX, BlinkY + d_683C)
          else
              u9_051F(PByteArray(d_6E36)^[203], BlinkX, BlinkY + d_683C);
        end
        else
        begin
          if BlinkMode <> 0 then
            u9_051F(PByteArray(d_6E36)^[43], BlinkX, BlinkY + d_683C)
          else
            u9_051F(PByteArray(d_6E36)^[203], BlinkX, BlinkY + d_683C);
          u9_051F(d_6E36^.Glyphs[BlinkCount + 37].Pixels[1], BlinkX,
            BlinkY + d_683C);
        end;
      end;
    end;
  end;

  u3_1e2a := InputText;
  u9_1831(PByteArray(d_67F6)^, Left, (Top shl 3) + d_683C);
  FreeMem(d_67F6, $7530);
  MemW[0:$041C] := MemW[0:$041A];
  d_6EC3 := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  d_6EC4 := 0;
end;
