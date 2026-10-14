{@decls}
type
  TFarPtr = packed record
    case Byte of
      0: (p: Pointer);
      1: (ofs: Word; seg: Word);
      2: (value: LongInt);
  end;
  TGlyph = packed record
    Header: array[1..3] of Byte;
    Pixels: array[1..37] of Byte;
  end;
  TGlyphArray = array[1..1638] of TGlyph;
  PGlyphArray = ^TGlyphArray;
var
  d_6832: Word;
  d_6858: Integer;
  d_699A: TFarPtr;
  d_69A4: Integer;
  d_6E32: PGlyphArray;
{@stubs}

procedure u9_1b27(var source: Byte; x, y: Word);
procedure u9_2b38(var source: Byte; x, y: Word);
procedure u9_2f32;
{@body}
procedure u3_0261;
var
  i: Integer;
  xoff: Word;
  number: String[11];
begin
  u9_2f32;
  d_6832 := d_6838;
  xoff := d_6838 and 7;
  Str(d_699A.value:6, number);
  for i := 1 to 6 do
    if number[i] = ' ' then
      number[i] := '0';

  if xoff = 0 then
  begin
    u9_2b38(d_6E32^[Ord(number[1]) - $2F].Pixels[1], 0, 1);
    u9_2b38(d_6E32^[Ord(number[2]) - $2F].Pixels[1], 1, 1);
    u9_2b38(d_6E32^[Ord(number[3]) - $2F].Pixels[1], 2, 1);
    u9_2b38(d_6E32^[Ord(number[4]) - $2F].Pixels[1], 3, 1);
    u9_2b38(d_6E32^[Ord(number[5]) - $2F].Pixels[1], 4, 1);
    u9_2b38(d_6E32^[Ord(number[6]) - $2F].Pixels[1], 5, 1);
    u9_2b38(d_6E32^[13].Pixels[1], 12, 1);
    u9_2b38(d_6E32^[11].Pixels[1], 13, 1);
    u9_2b38(d_6E32^[d_6858 div 10 + 1].Pixels[1], 14, 1);
    u9_2b38(d_6E32^[d_6858 mod 10 + 1].Pixels[1], 15, 1);
    if d_69A4 > 0 then
      u9_2b38(d_6E32^[14].Pixels[1], 20, 1);
    if d_69F4 <> 0 then
      u9_2b38(d_6E32^[21].Pixels[1], 25, 1);
    if d_69EA <> 0 then
      u9_2b38(d_6E32^[18].Pixels[1], 27, 1);
    if d_69EB <> 0 then
      u9_2b38(d_6E32^[19].Pixels[1], 28, 1);
    if d_69E9 <> 0 then
      u9_2b38(d_6E32^[20].Pixels[1], 29, 1);
    if d_69EC <> 0 then
      u9_2b38(d_6E32^[22].Pixels[1], 30, 1);
    for i := 1 to Integer(d_6A40) do
      u9_2b38(d_6E32^[12].Pixels[1], i + 32, 1);
  end
  else
  begin
    u9_1b27(d_6E32^[Ord(number[1]) - $2F].Pixels[1], xoff, 1);
    u9_1b27(d_6E32^[Ord(number[2]) - $2F].Pixels[1], xoff + 8, 1);
    u9_1b27(d_6E32^[Ord(number[3]) - $2F].Pixels[1], xoff + 16, 1);
    u9_1b27(d_6E32^[Ord(number[4]) - $2F].Pixels[1], xoff + 24, 1);
    u9_1b27(d_6E32^[Ord(number[5]) - $2F].Pixels[1], xoff + 32, 1);
    u9_1b27(d_6E32^[Ord(number[6]) - $2F].Pixels[1], xoff + 40, 1);
    u9_1b27(d_6E32^[13].Pixels[1], xoff + 96, 1);
    u9_1b27(d_6E32^[11].Pixels[1], xoff + 104, 1);
    u9_1b27(d_6E32^[d_6858 div 10 + 1].Pixels[1], xoff + 112, 1);
    u9_1b27(d_6E32^[d_6858 mod 10 + 1].Pixels[1], xoff + 120, 1);
    if d_69A4 > 0 then
      u9_1b27(d_6E32^[14].Pixels[1], xoff + 160, 1);
    if d_69F4 <> 0 then
      u9_1b27(d_6E32^[21].Pixels[1], xoff + 200, 1);
    if d_69EA <> 0 then
      u9_1b27(d_6E32^[18].Pixels[1], xoff + 216, 1);
    if d_69EB <> 0 then
      u9_1b27(d_6E32^[19].Pixels[1], xoff + 224, 1);
    if d_69E9 <> 0 then
      u9_1b27(d_6E32^[20].Pixels[1], xoff + 232, 1);
    if d_69EC <> 0 then
      u9_1b27(d_6E32^[22].Pixels[1], xoff + 240, 1);
    for i := 1 to Integer(d_6A40) do
      u9_1b27(d_6E32^[12].Pixels[1], xoff + $100 + (Word(i) shl 3), 1);
  end;
end;
