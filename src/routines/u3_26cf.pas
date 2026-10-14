{ Scrolling help window with an animated border and key selection. }
{@decls}
type
  THelpLine = string[40];
  TGlyph = packed record
    Header: array[1..3] of Byte;
    Pixels: array[1..37] of Byte;
  end;
  TGlyphArray = array[1..1638] of TGlyph;
  PGlyphArray = ^TGlyphArray;
  TWindowBuffer = array[0..29999] of Byte;
  PWindowBuffer = ^TWindowBuffer;
var
  d_3812: array[1..299] of THelpLine;
  d_67F6: PWindowBuffer;
  d_67FA: array[1..20] of Byte;
  d_6824, d_6826, d_6828, d_682A, d_682C: Integer;
  d_6838, d_683A, d_683C: Integer;
  d_6E36: PGlyphArray;
  d_6EC3, d_6EC4, d_6ECA, d_6ECB, d_6ECC: Byte;
{@stubs}
procedure u3_0892(X, Y: Integer; Text: string);
procedure u9_051f(var Data; X, Y: Integer);
procedure u9_1795(var Data; X1, Y1, X2, Y2: Integer);
procedure u9_1831(var Data; X, Y: Integer);
procedure u9_2b38(var Data; X, Y: Integer);
{@body}
function u3_26cf(Mode: Byte): Byte;
var
  CursorX, CursorY, FirstLine: Integer;
  Width, Height, LineCount: Integer;
  Left, Top, Right, Bottom: Integer;
  Scroll, PreviousKey, Key: Integer;
  SparkX, SparkY, SparkFrame: Integer;
  Horizontal, SparkActive, Done: Boolean;
begin
  FirstLine := 1;
  CursorX := 0;
  Width := 0;
  Height := 0;
  LineCount := 0;
  Scroll := 0;
  Done := False;
  SparkActive := False;
  for d_6828 := 1 to 299 do
  begin
    if d_6828 = 1 then Width := Length(d_3812[d_6828]) - 1;
    if Length(d_3812[d_6828]) > Width then
      Width := Length(d_3812[d_6828]) - 1;
    if d_3812[d_6828] = 'END OF WINDOW' then Height := d_6828 - 2;
    for d_6826 := 1 to Length(d_3812[d_6828]) do
      if Copy(d_3812[d_6828], d_6826, 1) = '^' then
      begin
        CursorX := Pos('^', d_3812[d_6828]) + 1;
        CursorY := d_6828 + 1;
      end;
  end;
  LineCount := Height;
  if Height > 16 then Height := 16;
  Inc(Height, 3);
  Left := (((320 - (Width shl 3)) div 2 + d_6838) div 8) - 3;
  Top := (((200 - (Height shl 3)) div 2 + d_683A) div 8) - 2;
  CursorX := CursorX + Left;
  CursorY := CursorY + Top;
  GetMem(d_67F6, 30000);
  u9_1795(d_67F6^, Left, (Top shl 3) + d_683C,
    Left + Width + 5 + 1, ((Top + Height + 2 + 1) shl 3) + d_683C);
  Right := Left + Width + 4;
  Bottom := Top + Height + 1;
  for d_682A := 1 to Bottom - Top do
    for d_6828 := Left + 1 to Right - 1 do
      u9_2b38(d_6E36^[9].Pixels[1], d_6828,
        ((Top + d_682A) shl 3) + d_683C);
  u9_051f(d_6E36^[1].Pixels[1], Left, (Top shl 3) + d_683C);
  for d_6828 := Left + 1 to Right - 1 do
    u9_051f(d_6E36^[2].Pixels[1], d_6828, (Top shl 3) + d_683C);
  u9_051f(d_6E36^[3].Pixels[1], Right, (Top shl 3) + d_683C);
  for d_6828 := 1 to Bottom - Top do
  begin
    u9_051f(d_6E36^[6].Pixels[1], Left,
      ((Top + d_6828) shl 3) + d_683C);
    u9_051f(d_6E36^[8].Pixels[1], Right,
      ((Top + d_6828) shl 3) + d_683C);
    u9_051f(d_6E36^[10].Pixels[1], Right + 1,
      ((Top + d_6828) shl 3) + d_683C);
  end;
  u9_051f(d_6E36^[10].Pixels[1], Right + 1,
    ((Bottom - Top + Top + 1) shl 3) + d_683C);
  u9_051f(d_6E36^[5].Pixels[1], Left, (Bottom shl 3) + d_683C);
  for d_6828 := Left + 1 to Right - 1 do
    u9_051f(d_6E36^[7].Pixels[1], d_6828, (Bottom shl 3) + d_683C);
  u9_051f(d_6E36^[4].Pixels[1], Right, (Bottom shl 3) + d_683C);
  for d_6828 := Left + 1 to Right + 1 do
    u9_051f(d_6E36^[10].Pixels[1], d_6828,
      ((Bottom + 1) shl 3) + d_683C);
  for d_6828 := 1 to Height - 2 do
    if d_3812[d_6828] <> 'END OF WINDOW' then
      u3_0892(Left + 2, Top + d_6828 + 1, d_3812[d_6828]);
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  repeat
    MemW[0:$41C] := MemW[0:$41A];
  until d_6824 > 128;
  repeat
    repeat
      MemW[0:$41C] := MemW[0:$41A];
      d_6828 := Random(100);
      if (not SparkActive) and (d_6828 >= 99) then
      begin
        SparkActive := True;
        SparkFrame := 0;
        case Random(2) of
          0: begin
            SparkX := Left + Random(Right - Left - 2) + 1;
            SparkY := Top shl 3;
            Horizontal := True;
          end;
          1: begin
            SparkX := Left;
            SparkY := (Top + Random(Bottom - Top - 2) + 1) * 8;
            Horizontal := False;
          end;
        end;
      end;
      if (CursorX <> 0) and (d_682C > 20) then
      begin
        d_682C := 0;
        if SparkActive then
        begin
          Inc(SparkFrame);
          if SparkFrame > 4 then
          begin
            SparkActive := False;
            if Horizontal then
              u9_051f(d_6E36^[2].Pixels[1], SparkX, SparkY + d_683C)
            else
              u9_051f(d_6E36^[6].Pixels[1], SparkX, SparkY + d_683C);
          end
          else
          begin
            if Horizontal then
              u9_051f(d_6E36^[2].Pixels[1], SparkX, SparkY + d_683C)
            else
              u9_051f(d_6E36^[6].Pixels[1], SparkX, SparkY + d_683C);
            u9_051f(d_6E36^[SparkFrame + 37].Pixels[1],
              SparkX, SparkY + d_683C);
          end;
        end;
      end;
    until (d_6824 < 128) or (d_6824 = 224);
    Key := d_6824;
    if Key = 224 then
    begin
      repeat
        MemW[0:$41C] := MemW[0:$41A];
      until Byte(d_6824) in [156,157,170,181,184,197,199,200,201,
        203,205,207,208,209,210,211];
      if Byte(d_6824) in [170,197] then d_6824 := 500;
      Key := d_6824 - 128;
    end
    else
      repeat
        MemW[0:$41C] := MemW[0:$41A];
      until d_6824 > 128;
    if (Key = 80) or (Key = 81) then
    begin
      Inc(Scroll, 17);
      if LineCount - 16 < Scroll then Scroll := LineCount - 16;
      for d_682A := 1 to Bottom - Top - 1 do
        for d_6828 := Left + 1 to Right - 1 do
          u9_2b38(d_6E36^[9].Pixels[1], d_6828,
            ((Top + d_682A) shl 3) + d_683C);
      u9_051f(d_6E36^[1].Pixels[1], Left, (Top shl 3) + d_683C);
      for d_6828 := Left + 1 to Right - 1 do
        u9_051f(d_6E36^[2].Pixels[1], d_6828, (Top shl 3) + d_683C);
      u9_051f(d_6E36^[3].Pixels[1], Right, (Top shl 3) + d_683C);
      for d_6828 := 1 to Bottom - Top do
      begin
        u9_051f(d_6E36^[6].Pixels[1], Left,
          ((Top + d_6828) shl 3) + d_683C);
        u9_051f(d_6E36^[8].Pixels[1], Right,
          ((Top + d_6828) shl 3) + d_683C);
        u9_051f(d_6E36^[10].Pixels[1], Right + 1,
          ((Top + d_6828) shl 3) + d_683C);
      end;
      u9_051f(d_6E36^[10].Pixels[1], Right + 1,
        ((Bottom - Top + Top + 1) shl 3) + d_683C);
      u9_051f(d_6E36^[5].Pixels[1], Left, (Bottom shl 3) + d_683C);
      for d_6828 := Left + 1 to Right - 1 do
        u9_051f(d_6E36^[7].Pixels[1], d_6828, (Bottom shl 3) + d_683C);
      u9_051f(d_6E36^[4].Pixels[1], Right, (Bottom shl 3) + d_683C);
      for d_6828 := Left + 1 to Right + 1 do
        u9_051f(d_6E36^[10].Pixels[1], d_6828,
          ((Bottom + 1) shl 3) + d_683C);
      for d_6828 := 1 to Height - 2 do
        if d_3812[d_6828] <> 'END OF WINDOW' then
          u3_0892(Left + 2, Top + d_6828 + 1, d_3812[d_6828 + Scroll]);
    end;
    if (Key = 72) or (Key = 73) then
    begin
      Dec(Scroll, 17);
      if Scroll < 0 then Scroll := 0;
      for d_682A := 1 to Bottom - Top - 1 do
        for d_6828 := Left + 1 to Right - 1 do
          u9_2b38(d_6E36^[9].Pixels[1], d_6828,
            ((Top + d_682A) shl 3) + d_683C);
      u9_051f(d_6E36^[1].Pixels[1], Left, (Top shl 3) + d_683C);
      for d_6828 := Left + 1 to Right - 1 do
        u9_051f(d_6E36^[2].Pixels[1], d_6828, (Top shl 3) + d_683C);
      u9_051f(d_6E36^[3].Pixels[1], Right, (Top shl 3) + d_683C);
      for d_6828 := 1 to Bottom - Top do
      begin
        u9_051f(d_6E36^[6].Pixels[1], Left,
          ((Top + d_6828) shl 3) + d_683C);
        u9_051f(d_6E36^[8].Pixels[1], Right,
          ((Top + d_6828) shl 3) + d_683C);
        u9_051f(d_6E36^[10].Pixels[1], Right + 1,
          ((Top + d_6828) shl 3) + d_683C);
      end;
      u9_051f(d_6E36^[10].Pixels[1], Right + 1,
        ((Bottom - Top + Top + 1) shl 3) + d_683C);
      u9_051f(d_6E36^[5].Pixels[1], Left, (Bottom shl 3) + d_683C);
      for d_6828 := Left + 1 to Right - 1 do
        u9_051f(d_6E36^[7].Pixels[1], d_6828, (Bottom shl 3) + d_683C);
      u9_051f(d_6E36^[4].Pixels[1], Right, (Bottom shl 3) + d_683C);
      for d_6828 := Left + 1 to Right + 1 do
        u9_051f(d_6E36^[10].Pixels[1], d_6828,
          ((Bottom + 1) shl 3) + d_683C);
      for d_6828 := 1 to Height - 2 do
        if d_3812[d_6828] <> 'END OF WINDOW' then
          u3_0892(Left + 2, Top + d_6828 + 1, d_3812[d_6828 + Scroll]);
    end;
    if Mode = 0 then
    begin
      for d_6828 := 1 to 20 do
        if (d_67FA[d_6828] <> 0) and (d_67FA[d_6828] = Key) then
        begin
          u3_26cf := Key;
          Done := True;
        end;
    end
    else
    begin
      u3_26cf := Key;
      Done := True;
    end;
  until Done;
  u9_1831(d_67F6^, Left, (Top shl 3) + d_683C);
  FreeMem(d_67F6, 30000);
  MemW[0:$41C] := MemW[0:$41A];
  d_6ECC := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  d_6EC3 := 0;
  d_6EC4 := 0;
end;
