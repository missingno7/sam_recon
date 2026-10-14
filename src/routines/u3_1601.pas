{@decls}
type
  TName = String[40];
type
  TNameRecord = packed record
    Name: TName;
  end;
type
  TByteArray38 = array[37..32767] of Byte;
type
  PByteArray38 = ^TByteArray38;
var
  d_67FA: array[1..20] of Byte;
  d_6826: Integer;
  d_6828: Integer;
  d_682A: Integer;
  d_6838: Integer;
  d_683A: Integer;
  d_6EC3: Byte;
  d_6EC4: Byte;
  d_6ECA: Byte;
  d_6ECB: Byte;
  d_6ECC: Byte;
{@stubs}
procedure u9_051f(var Data; X, Y: Integer);
procedure u9_1795(var Data; X1, Y1, X2, Y2: Integer);
procedure u9_1831(var Data; X, Y: Integer);
procedure u9_2b38(var Data; X, Y: Integer);
{@body}
function u3_1601(mode: Byte): Byte;
var
  xPos: Integer;
  yPos: Integer;
  phase: Integer;
  longestName: Integer;
  endRow: Integer;
  xOrigin: Integer;
  yOrigin: Integer;
  xLimit: Integer;
  yLimit: Integer;
  unusedWord: Integer;
  selectedCode: Integer;
  moveX: Integer;
  moveY: Integer;
  moveCount: Integer;
  moveVertical: Byte;
  selected: Byte;
  found: Byte;
begin
  phase := 1;
  xPos := 0;
  yPos := 0;
  longestName := 0;
  endRow := 0;
  found := 0;
  selected := 0;
  for d_6828 := 1 to 20 do
  begin
    if d_6828 = 1 then
      longestName := Ord(d_3812[d_6828][0]) - 1;
    if Ord(d_3812[d_6828][0]) > longestName then
      longestName := Ord(d_3812[d_6828][0]) - 1;
    if d_3812[d_6828] = 'END OF WINDOW' then
      endRow := d_6828 - 2;
    for d_6826 := 1 to Length(d_3812[d_6828]) do
    begin
      if Copy(d_3812[d_6828], d_6826, 1) = '^' then
      begin
        xPos := Pos('^', d_3812[d_6828]) + 1;
        yPos := d_6828 + 1;
      end;
    end;
  end;
  Inc(endRow, 3);
  xOrigin := (((320 - (longestName shl 3)) div 2 + d_6838) div 8) - 3;
  yOrigin := (((200 - (endRow shl 3)) div 2 + d_683A) div 8) - 2;
  if xPos <> 0 then
    xPos := xPos + xOrigin;
  yPos := yPos + yOrigin;
  GetMem(d_67F6, 30000);
  u9_1795(PByteArray(d_67F6)^[0], xOrigin,
    (yOrigin shl 3) + d_683C, xOrigin + longestName + 5 + 1,
    ((yOrigin + endRow + 2 + 1) shl 3) + d_683C);
  xLimit := xOrigin + longestName + 4;
  yLimit := yOrigin + endRow + 1;

  for d_682A := 1 to yLimit - yOrigin do
    for d_6828 := xOrigin + 1 to xLimit - 1 do
      u9_2b38(PByteArray(d_6E36)^[323], d_6828,
        ((yOrigin + d_682A) shl 3) + d_683C);
  u9_051f(PByteArray(d_6E36)^[3], xOrigin, (yOrigin shl 3) + d_683C);
  for d_6828 := xOrigin + 1 to xLimit - 1 do
    u9_051f(PByteArray(d_6E36)^[43], d_6828, (yOrigin shl 3) + d_683C);
  u9_051f(PByteArray(d_6E36)^[83], xLimit, (yOrigin shl 3) + d_683C);
  for d_6828 := 1 to yLimit - yOrigin do
  begin
    u9_051f(PByteArray(d_6E36)^[203], xOrigin,
      ((yOrigin + d_6828) shl 3) + d_683C);
    u9_051f(PByteArray(d_6E36)^[283], xLimit,
      ((yOrigin + d_6828) shl 3) + d_683C);
    u9_051f(PByteArray(d_6E36)^[363], xLimit + 1,
      ((yOrigin + d_6828) shl 3) + d_683C);
  end;
  u9_051f(PByteArray(d_6E36)^[363], xLimit + 1,
    ((yLimit - yOrigin + yOrigin + 1) shl 3) + d_683C);
  u9_051f(PByteArray(d_6E36)^[163], xOrigin, (yLimit shl 3) + d_683C);
  for d_6828 := xOrigin + 1 to xLimit - 1 do
    u9_051f(PByteArray(d_6E36)^[243], d_6828, (yLimit shl 3) + d_683C);
  u9_051f(PByteArray(d_6E36)^[123], xLimit, (yLimit shl 3) + d_683C);
  for d_6828 := xOrigin + 1 to xLimit + 1 do
    u9_051f(PByteArray(d_6E36)^[363], d_6828, ((yLimit + 1) shl 3) + d_683C);

  for d_6828 := 1 to endRow do
    if d_3812[d_6828] <> 'END OF WINDOW' then
      u3_0892(xOrigin + 2, yOrigin + d_6828 + 1,
        d_3812[d_6828]);

  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  repeat
    MemW[0:$041C] := MemW[0:$041A];
  until d_6824 > $80;
  u7_0000($11);
  repeat
    repeat
    MemW[0:$041C] := MemW[0:$041A];
    d_6828 := Random(100);
    if (selected = 0) and (d_6828 >= 99) then
    begin
      selected := 1;
      moveCount := 0;
      case Random(2) of
        0:
          begin
            moveX := xOrigin + Random(xLimit - xOrigin - 2) + 1;
            moveY := yOrigin shl 3;
            moveVertical := 1;
          end;
        1:
          begin
            moveX := xOrigin;
            moveY := (yOrigin + Random(yLimit - yOrigin - 2) + 1) * 8;
            moveVertical := 0;
          end;
      end;
    end;
    if (xPos <> 0) and (d_682C > $14) then
    begin
      d_682C := 0;
      u9_2b38(PByteArray(d_6E36)^[323], xPos, (yPos shl 3) + d_683C);
      u9_051f(d_6E3A^.Glyphs[phase + 45].Pixels[1], xPos,
        (yPos shl 3) + d_683C);
      Inc(phase);
      if phase > 5 then
        phase := 1;
      if selected <> 0 then
      begin
        Inc(moveCount);
        if moveCount > 4 then
        begin
          selected := 0;
          if moveVertical <> 0 then
            u9_051f(PByteArray(d_6E36)^[43], moveX, moveY + d_683C)
          else
            u9_051f(PByteArray(d_6E36)^[203], moveX, moveY + d_683C);
        end
        else
        begin
          if moveVertical <> 0 then
            u9_051f(PByteArray(d_6E36)^[43], moveX, moveY + d_683C)
          else
            u9_051f(PByteArray(d_6E36)^[203], moveX, moveY + d_683C);
          u9_051f(d_6E36^.Glyphs[moveCount + 37].Pixels[1], moveX,
            moveY + d_683C);
        end;
      end;
    end;
    until (d_6824 < $80) or (d_6824 = $E0);
    selectedCode := d_6824;
      if selectedCode = $E0 then
      begin
        repeat
          MemW[0:$041C] := MemW[0:$041A];
        until d_6824 in [156,157,170,181,184,197,199,200,201,203,205,207,208,209,210,211];
        if d_6824 in [170,197] then
          d_6824 := 500;
        selectedCode := d_6824 - $80;
      end
      else
      begin
        repeat
          MemW[0:$041C] := MemW[0:$041A];
        until d_6824 > $80;
      end;

      if mode = 0 then
      begin
        for d_6828 := 1 to 20 do
          if (d_67FA[d_6828] <> 0) and (d_67FA[d_6828] = selectedCode) then
          begin
            u3_1601 := Byte(selectedCode);
            found := 1;
          end;
      end
      else
      begin
        u3_1601 := Byte(selectedCode);
        found := 1;
      end;
  until found <> 0;
  u9_1831(d_67F6^[0], xOrigin,
    (yOrigin shl 3) + d_683C);
  FreeMem(d_67F6, 30000);
  MemW[0:$041C] := MemW[0:$041A];
  d_6ECC := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  d_6EC3 := 0;
  d_6EC4 := 0;
end;
