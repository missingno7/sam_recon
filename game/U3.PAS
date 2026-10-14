unit U3;
{$A+}{$D+}{$L+}{$F-}
interface
uses U8;
{$IFDEF SAM1}
function u3_0000: Char;
{$ENDIF}
procedure u3_007c;
procedure u3_00a3;
procedure u3_00db(ticks: Word);
procedure u3_0232(Ticks: Word);
procedure u3_0261;
procedure u3_079e;
procedure u3_0892(X, Y: Integer; Text: string);
function u3_1601(mode: Byte): Byte;
function u3_1e2a(MaxInput: Integer): String;
function u3_26cf(Mode: Byte): Byte;
procedure u3_344c;
procedure u3_3505;
procedure u3_3712;
procedure u3_38ae;
procedure u3_3c93;
procedure u3_3cb8;
procedure u3_3d6b;
procedure u3_3e29(slot: Integer);
function u3_3f8c(Slot: Integer): Boolean;
procedure u3_4e64;
procedure u3_6ea9;
procedure u3_7c17;
procedure u3_848e;
procedure u3_892b;
function u3_8ea3: Word;
procedure u3_8fb6;
function u3_9163: Integer;
function u3_9340: Char;
function u3_97bb: Char;
procedure u3_9a71;
procedure u3_9b3e(input: string);
procedure u3_9bdf;
procedure u3_9ca9;
procedure u3_9de0;
procedure u3_a027;
procedure u3_a1d8;
procedure u3_a3b6;
function u3_a6f6(key: Word): string;
procedure u3_acdd;
procedure u3_af56;
procedure u3_b4d6;
procedure u3_b898;
procedure u3_c10d;
procedure u3_cf40;
procedure u3_d323;
procedure u3_d645;
procedure u3_d820;
procedure u3_dbc2;
procedure u3_ddd2;
implementation
uses Dos, U9, Crt, U7, U6, U5, U4;
{$IFDEF SAM1}
{$F+}
function u3_0000: Char;
var
  prefixByte: Byte;
  regs: Registers;
  shift: Word;
  pad: array[1..6] of Byte;
  egaFlags: Byte;
  adapter: Char;
  buffer: array[1..64] of Byte;
begin
  regs.ES := Seg(buffer);
  regs.DI := Ofs(buffer);
  regs.AX := $1B00;
  regs.BX := 0;
  Intr($10, regs);
  if Lo(regs.AX) = $1B then
  begin
    adapter := 'V';
  end
  else
  begin
    Intr($11, regs);
    shift := (Lo(regs.AX) and $30) shr 4;
    egaFlags := t_u3_0000_pbyte(t_u3_0000_ppointer(Ptr(0, $0487))^)^;
    if egaFlags <> 0 then
      adapter := 'E'
    else
      adapter := 'U';
  end;
  u3_0000 := adapter;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$ENDIF}
{$F+}
procedure u3_007c;
begin
  if d_683E = 0 then
  begin
    d_683E := 1;
    d_6840 := $01A0;
  end
  else
  begin
    d_683E := 0;
    d_6840 := $0010;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_00a3;
begin
  if d_70C6 = 0 then
    u9_01f9(d_6838, d_6840 + d_683A)
  else
    u9_024c(d_6838, d_6840 + d_683A);
  d_683C := d_6840;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_00db(ticks: Word);
begin
  u9_0352(0, 0);
  Delay(ticks);
  u9_0352(1, 1);
  Delay(ticks);
  u9_0352(2, 2);
  Delay(ticks);
  u9_0352(3, 3);
  Delay(ticks);
  u9_0352(4, 4);
  Delay(ticks);
  u9_0352(5, 5);
  Delay(ticks);
  u9_0352(6, 6);
  Delay(ticks);
  u9_0352(7, 7);
  Delay(ticks);
  u9_0352(8, 16);
  Delay(ticks);
  u9_0352(9, 17);
  Delay(ticks);
  u9_0352(10, 18);
  Delay(ticks);
  u9_0352(11, 19);
  Delay(ticks);
  u9_0352(12, 20);
  Delay(ticks);
  u9_0352(13, 21);
  Delay(ticks);
  u9_0352(14, 22);
  Delay(ticks);
  u9_0352(15, 23);
  Delay(ticks);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_0232(Ticks: Word);
var
  I: Integer;
begin
  for I := 0 to 15 do
  begin
    Delay(Ticks);
    u9_0352(I, 0);
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_0261;
var
  i: Integer;
  xoff: Word;
  number: String[11];
begin
  u9_2f32;
  d_6832 := d_6838;
  xoff := d_6838 and 7;
  Str(d_699A:6, number);
  for i := 1 to 6 do
    if number[i] = ' ' then
      number[i] := '0';

  if xoff = 0 then
  begin
    u9_2b38(d_6E32^.Glyphs[Ord(number[1]) - $2F].Pixels[1], 0, 1);
    u9_2b38(d_6E32^.Glyphs[Ord(number[2]) - $2F].Pixels[1], 1, 1);
    u9_2b38(d_6E32^.Glyphs[Ord(number[3]) - $2F].Pixels[1], 2, 1);
    u9_2b38(d_6E32^.Glyphs[Ord(number[4]) - $2F].Pixels[1], 3, 1);
    u9_2b38(d_6E32^.Glyphs[Ord(number[5]) - $2F].Pixels[1], 4, 1);
    u9_2b38(d_6E32^.Glyphs[Ord(number[6]) - $2F].Pixels[1], 5, 1);
    u9_2b38(d_6E32^.Glyphs[13].Pixels[1], 12, 1);
    u9_2b38(d_6E32^.Glyphs[11].Pixels[1], 13, 1);
    u9_2b38(d_6E32^.Glyphs[d_6858 div 10 + 1].Pixels[1], 14, 1);
    u9_2b38(d_6E32^.Glyphs[d_6858 mod 10 + 1].Pixels[1], 15, 1);
    if d_69A4 > 0 then
      u9_2b38(d_6E32^.Glyphs[14].Pixels[1], 20, 1);
    if d_69F4 <> 0 then
      u9_2b38(d_6E32^.Glyphs[21].Pixels[1], 25, 1);
    if d_69EA <> 0 then
      u9_2b38(d_6E32^.Glyphs[18].Pixels[1], 27, 1);
    if d_69EB <> 0 then
      u9_2b38(d_6E32^.Glyphs[19].Pixels[1], 28, 1);
    if d_69E9 <> 0 then
      u9_2b38(d_6E32^.Glyphs[20].Pixels[1], 29, 1);
    if d_69EC <> 0 then
      u9_2b38(d_6E32^.Glyphs[22].Pixels[1], 30, 1);
    for i := 1 to Integer(d_6A40) do
      u9_2b38(d_6E32^.Glyphs[12].Pixels[1], i + 32, 1);
  end
  else
  begin
    u9_1b27(d_6E32^.Glyphs[Ord(number[1]) - $2F].Pixels[1], xoff, 1);
    u9_1b27(d_6E32^.Glyphs[Ord(number[2]) - $2F].Pixels[1], xoff + 8, 1);
    u9_1b27(d_6E32^.Glyphs[Ord(number[3]) - $2F].Pixels[1], xoff + 16, 1);
    u9_1b27(d_6E32^.Glyphs[Ord(number[4]) - $2F].Pixels[1], xoff + 24, 1);
    u9_1b27(d_6E32^.Glyphs[Ord(number[5]) - $2F].Pixels[1], xoff + 32, 1);
    u9_1b27(d_6E32^.Glyphs[Ord(number[6]) - $2F].Pixels[1], xoff + 40, 1);
    u9_1b27(d_6E32^.Glyphs[13].Pixels[1], xoff + 96, 1);
    u9_1b27(d_6E32^.Glyphs[11].Pixels[1], xoff + 104, 1);
    u9_1b27(d_6E32^.Glyphs[d_6858 div 10 + 1].Pixels[1], xoff + 112, 1);
    u9_1b27(d_6E32^.Glyphs[d_6858 mod 10 + 1].Pixels[1], xoff + 120, 1);
    if d_69A4 > 0 then
      u9_1b27(d_6E32^.Glyphs[14].Pixels[1], xoff + 160, 1);
    if d_69F4 <> 0 then
      u9_1b27(d_6E32^.Glyphs[21].Pixels[1], xoff + 200, 1);
    if d_69EA <> 0 then
      u9_1b27(d_6E32^.Glyphs[18].Pixels[1], xoff + 216, 1);
    if d_69EB <> 0 then
      u9_1b27(d_6E32^.Glyphs[19].Pixels[1], xoff + 224, 1);
    if d_69E9 <> 0 then
      u9_1b27(d_6E32^.Glyphs[20].Pixels[1], xoff + 232, 1);
    if d_69EC <> 0 then
      u9_1b27(d_6E32^.Glyphs[22].Pixels[1], xoff + 240, 1);
    for i := 1 to Integer(d_6A40) do
      u9_1b27(d_6E32^.Glyphs[12].Pixels[1], xoff + $100 + (Word(i) shl 3), 1);
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_079e;
var
  I: Integer;
begin
  for I := 1 to 299 do
    d_3812[I][0] := #0;
  for I := 1 to 20 do
    d_67FA[I] := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_0892(X, Y: Integer; Text: string);
var
  I, Glyph: Integer;
  GlyphMap: string;
begin
  GlyphMap := '~~~~~~~~~~~~~~~~~~|||||||||||||| !"#$%& ()*+,-./0123456789:;'
    + '<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    + #127#128#129#130#131#132#133#134#135#136#137#138#139#140
    + #141#142#143#144#145#146#147#148#149#150#151#152#153#154
    + #155#156#157#158#159#160#161#162#163#164#165#166#167#168
    + #169#170#171#172#173#174#175#176#177#178#179#180#181#182#183#184;
  for I := 1 to Length(Text) do
  begin
    Glyph := Pos(Copy(Text, I, 1), GlyphMap);
    if Copy(Text, I, 1) <> '^' then
      if (Glyph >= 93) and (Glyph < 118) then
        u9_051f(d_6E3A^.Glyphs[Glyph - 93 + 21].Pixels[1], X + I - 1,
                 (Y shl 3) + d_683C)
      else if Glyph <= 72 then
      begin
        case Glyph of
          32..72: u9_051f(d_6E36^.Glyphs[Glyph - 32 + 10].Pixels[1],
                           X + I - 1, (Y shl 3) + d_683C);
        end;
      end
      else if Glyph >= 118 then
      begin
        case Glyph of
          118: u9_0475(d_6DA6^.Images[1].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          119: u9_0475(d_6DA6^.Images[7].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          120: u9_0475(d_6D72^.Images[15].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          121: u9_0475(d_6D72^.Images[16].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          122: u9_0475(d_6D72^.Images[13].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          123: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          124: u9_0475(d_6D76^.Images[4].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          125: u9_0475(d_6D76^.Images[8].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          126: u9_0475(d_6D76^.Images[34].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          127: u9_0475(d_6D76^.Images[21].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          128: u9_0475(d_6D7E^.Images[21].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          129: u9_0475(d_6D7E^.Images[23].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          130: u9_0475(d_6D7E^.Images[25].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          131: u9_0475(d_6D7E^.Images[22].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          132: u9_0475(d_6D7E^.Images[24].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          133: u9_0475(d_6D7E^.Images[26].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          134: u9_0475(d_6D7E^.Images[47].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          135: u9_0475(d_6D86^.Images[4].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          136: u9_0475(d_6D86^.Images[5].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          137: u9_0475(d_6D86^.Images[33].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          138: u9_0475(d_6D86^.Images[37].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          139: u9_0475(d_6D86^.Images[19].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          140: u9_0475(d_6D86^.Images[18].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          141: u9_0475(d_6D86^.Images[20].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          142: u9_0475(d_6D86^.Images[29].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          143: u9_0475(d_6D86^.Images[30].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          144: u9_0475(d_6D86^.Images[31].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          145: u9_0475(d_6D86^.Images[32].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          146: u9_0475(d_6D86^.Images[35].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          147: u9_0475(d_6D8A^.Images[25].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          148: u9_0475(d_6DA2^.Images[1].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          149: u9_0475(d_6DA2^.Images[4].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          150: u9_0475(d_6DA2^.Images[13].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          151: u9_0475(d_6DA2^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          152: u9_0475(d_6DA2^.Images[16].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          153: u9_0475(d_6D9E^.Images[1].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          154: u9_0475(d_6D9E^.Images[5].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          155: u9_0475(d_6D9E^.Images[32].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          156: u9_0475(d_6D9E^.Images[36].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          157: u9_0475(d_6D9E^.Images[37].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          158: u9_0475(d_6D7A^.Images[2].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          159: u9_0475(d_6D7A^.Images[1].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          160: u9_0475(d_6DAE^.Images[1].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          161: u9_0475(d_6DAE^.Images[9].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          162: u9_0475(d_6DAE^.Images[18].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          163: u9_0475(d_6DAE^.Images[25].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          164: u9_0475(d_6DAE^.Images[36].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          165: u9_0475(d_6D96^.Images[2].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          166: u9_0475(d_6D96^.Images[30].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          167: u9_0475(d_6D96^.Images[33].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          168: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          169: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          170: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          171: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          172: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          173: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          174: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          175: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          176: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          177: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          178: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          179: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          180: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          181: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          182: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
          183: u9_0475(d_6D72^.Images[14].Pixels[1], X + I - 1, (Y shl 3) + d_683C);
        end;
      end
      else
        u9_051f(d_6E3A^.Glyphs[Glyph - 72].Pixels[1], X + I - 1,
                 (Y shl 3) + d_683C);
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
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
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
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
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
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
      u9_2b38(d_6E36^.Glyphs[9].Pixels[1], d_6828,
        ((Top + d_682A) shl 3) + d_683C);
  u9_051f(d_6E36^.Glyphs[1].Pixels[1], Left, (Top shl 3) + d_683C);
  for d_6828 := Left + 1 to Right - 1 do
    u9_051f(d_6E36^.Glyphs[2].Pixels[1], d_6828, (Top shl 3) + d_683C);
  u9_051f(d_6E36^.Glyphs[3].Pixels[1], Right, (Top shl 3) + d_683C);
  for d_6828 := 1 to Bottom - Top do
  begin
    u9_051f(d_6E36^.Glyphs[6].Pixels[1], Left,
      ((Top + d_6828) shl 3) + d_683C);
    u9_051f(d_6E36^.Glyphs[8].Pixels[1], Right,
      ((Top + d_6828) shl 3) + d_683C);
    u9_051f(d_6E36^.Glyphs[10].Pixels[1], Right + 1,
      ((Top + d_6828) shl 3) + d_683C);
  end;
  u9_051f(d_6E36^.Glyphs[10].Pixels[1], Right + 1,
    ((Bottom - Top + Top + 1) shl 3) + d_683C);
  u9_051f(d_6E36^.Glyphs[5].Pixels[1], Left, (Bottom shl 3) + d_683C);
  for d_6828 := Left + 1 to Right - 1 do
    u9_051f(d_6E36^.Glyphs[7].Pixels[1], d_6828, (Bottom shl 3) + d_683C);
  u9_051f(d_6E36^.Glyphs[4].Pixels[1], Right, (Bottom shl 3) + d_683C);
  for d_6828 := Left + 1 to Right + 1 do
    u9_051f(d_6E36^.Glyphs[10].Pixels[1], d_6828,
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
              u9_051f(d_6E36^.Glyphs[2].Pixels[1], SparkX, SparkY + d_683C)
            else
              u9_051f(d_6E36^.Glyphs[6].Pixels[1], SparkX, SparkY + d_683C);
          end
          else
          begin
            if Horizontal then
              u9_051f(d_6E36^.Glyphs[2].Pixels[1], SparkX, SparkY + d_683C)
            else
              u9_051f(d_6E36^.Glyphs[6].Pixels[1], SparkX, SparkY + d_683C);
            u9_051f(d_6E36^.Glyphs[SparkFrame + 37].Pixels[1],
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
          u9_2b38(d_6E36^.Glyphs[9].Pixels[1], d_6828,
            ((Top + d_682A) shl 3) + d_683C);
      u9_051f(d_6E36^.Glyphs[1].Pixels[1], Left, (Top shl 3) + d_683C);
      for d_6828 := Left + 1 to Right - 1 do
        u9_051f(d_6E36^.Glyphs[2].Pixels[1], d_6828, (Top shl 3) + d_683C);
      u9_051f(d_6E36^.Glyphs[3].Pixels[1], Right, (Top shl 3) + d_683C);
      for d_6828 := 1 to Bottom - Top do
      begin
        u9_051f(d_6E36^.Glyphs[6].Pixels[1], Left,
          ((Top + d_6828) shl 3) + d_683C);
        u9_051f(d_6E36^.Glyphs[8].Pixels[1], Right,
          ((Top + d_6828) shl 3) + d_683C);
        u9_051f(d_6E36^.Glyphs[10].Pixels[1], Right + 1,
          ((Top + d_6828) shl 3) + d_683C);
      end;
      u9_051f(d_6E36^.Glyphs[10].Pixels[1], Right + 1,
        ((Bottom - Top + Top + 1) shl 3) + d_683C);
      u9_051f(d_6E36^.Glyphs[5].Pixels[1], Left, (Bottom shl 3) + d_683C);
      for d_6828 := Left + 1 to Right - 1 do
        u9_051f(d_6E36^.Glyphs[7].Pixels[1], d_6828, (Bottom shl 3) + d_683C);
      u9_051f(d_6E36^.Glyphs[4].Pixels[1], Right, (Bottom shl 3) + d_683C);
      for d_6828 := Left + 1 to Right + 1 do
        u9_051f(d_6E36^.Glyphs[10].Pixels[1], d_6828,
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
          u9_2b38(d_6E36^.Glyphs[9].Pixels[1], d_6828,
            ((Top + d_682A) shl 3) + d_683C);
      u9_051f(d_6E36^.Glyphs[1].Pixels[1], Left, (Top shl 3) + d_683C);
      for d_6828 := Left + 1 to Right - 1 do
        u9_051f(d_6E36^.Glyphs[2].Pixels[1], d_6828, (Top shl 3) + d_683C);
      u9_051f(d_6E36^.Glyphs[3].Pixels[1], Right, (Top shl 3) + d_683C);
      for d_6828 := 1 to Bottom - Top do
      begin
        u9_051f(d_6E36^.Glyphs[6].Pixels[1], Left,
          ((Top + d_6828) shl 3) + d_683C);
        u9_051f(d_6E36^.Glyphs[8].Pixels[1], Right,
          ((Top + d_6828) shl 3) + d_683C);
        u9_051f(d_6E36^.Glyphs[10].Pixels[1], Right + 1,
          ((Top + d_6828) shl 3) + d_683C);
      end;
      u9_051f(d_6E36^.Glyphs[10].Pixels[1], Right + 1,
        ((Bottom - Top + Top + 1) shl 3) + d_683C);
      u9_051f(d_6E36^.Glyphs[5].Pixels[1], Left, (Bottom shl 3) + d_683C);
      for d_6828 := Left + 1 to Right - 1 do
        u9_051f(d_6E36^.Glyphs[7].Pixels[1], d_6828, (Bottom shl 3) + d_683C);
      u9_051f(d_6E36^.Glyphs[4].Pixels[1], Right, (Bottom shl 3) + d_683C);
      for d_6828 := Left + 1 to Right + 1 do
        u9_051f(d_6E36^.Glyphs[10].Pixels[1], d_6828,
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
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_344c;
var
  unused1, unused2, resultWord, unused4: Word;
begin
  u3_0232(0);
  resultWord := u5_000f(2);
  resultWord := u5_0047(1);
  resultWord := u9_01d3($28);
  d_6838 := 0;
  d_683A := 0;
  d_683C := 0;
  d_6840 := 0;
{$IFDEF SAM2}
  resultWord := u5_1915('sam2.apo', 1, 0, 0);
{$ELSE}
{$IFDEF SAM3}
  resultWord := u5_1915('sam3.apo', 1, 0, 0);
{$ELSE}
  resultWord := u5_1915('sam1.apo', 1, 0, 0);
{$ENDIF}
{$ENDIF}
  u3_00db($14);
  u7_0000($15);
  MemW[0:$041C] := MemW[0:$041A];
  d_682C := 0;
  repeat
  until KeyPressed or (d_682C > $02D0);
  d_682C := 0;
  u3_0232(0);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_3505;
var
  Direction, I, ResultWord: Integer;
  Key: Char;
begin
  u3_0232(0);
  ResultWord := u5_000f(2);
  ResultWord := u5_0047(1);
  ResultWord := u9_01d3($28);
  d_6838 := 0;
  d_683A := 0;
  d_683C := 0;
  d_6840 := 0;
{$IFDEF SAM2}
  ResultWord := u5_1915('sam2.crd', 1, 0, 0);
{$ELSE}
{$IFDEF SAM3}
  ResultWord := u5_1915('sam3.crd', 1, 0, 0);
{$ELSE}
  ResultWord := u5_1915('sam1.crd', 1, 0, 0);
{$ENDIF}
{$ENDIF}
  u9_2ecf(0, 0, 0, $C8);
{$IFDEF SAM2}
  ResultWord := u5_1915('sam2.ttl', 1, 0, 0);
{$ELSE}
{$IFDEF SAM3}
  ResultWord := u5_1915('sam3.ttl', 1, 0, 0);
{$ELSE}
  ResultWord := u5_1915('sam1.ttl', 1, 0, 0);
{$ENDIF}
{$ENDIF}
  u3_00db($14);
  Direction := 1;
  I := 0;
  d_6824 := 0;
  Key := ' ';
  d_682C := 0;
  repeat
    if d_6824 > 0 then
    begin
      Key := u3_9340;
      d_6824 := 0;
    end
    else
      d_6824 := 0;
  until (d_682C > $90) or (Key <> ' ');
  if (Key <> 'B') and (Key <> 'R') and (Key <> 'Q') then
  repeat
  if (Key <> 'B') and (Key <> 'R') and (Key <> 'Q') then
    Key := ' ';
  if Direction = 1 then
  begin
    if d_70C6 = 0 then
      u9_01f9(0, I)
    else
      u9_024c(0, I);
    d_683C := I;
  end
  else
  begin
    if d_70C6 = 0 then
      u9_01f9(0, $C8 - I)
    else
      u9_024c(0, $C8 - I);
    d_683C := $C8 - I;
  end;
  Inc(I);
  if I > $C8 then
  begin
    I := 0;
    Direction := -Direction;
    d_682C := 0;
    repeat
      if d_6824 > 0 then
      begin
        Key := u3_9340;
        d_6824 := 0;
        d_682C := 0;
      end;
    until (d_682C > $1B0) or (Key <> ' ');
  end;
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  d_6EC5 := 0;
  MemW[0:$041C] := MemW[0:$041A];
  if d_6824 <> 0 then
  begin
    Key := u3_9340;
    d_682C := 0;
    d_6824 := 0;
  end;
  until (Key = 'B') or (Key = 'R') or (Key = 'Q');
  u7_0000($0C);
  u3_0232(0);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_3712;
var
  i: Integer;
  j: Integer;
  s: String[255];
begin
  if d_699A > d_6B44.Scores[10] then
  begin
    u3_848e;
    for i := 10 downto 1 do
      if d_6B44.Scores[i] < d_699A then
        j := i;
    if j < 10 then
      for i := 10 downto j + 1 do
      begin
        d_6B44.Scores[i] := d_6B44.Scores[i - 1];
        d_6B44.Names[i] := d_6B44.Names[i - 1];
      end;
    for i := Ord(d_6A44[0]) to 22 do
      d_6A44 := d_6A44 + ' ';
    Str(d_699A:7, s);
    d_6A44 := d_6A44 + s;
    d_6B44.Scores[j] := d_699A;
    d_6B44.Names[j] := d_6A44;
    u3_9a71;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_38ae;
begin
{$IFDEF SAM1}
  Assign(d_6DB2.Raw, 'SAM101.GFX');
{$ENDIF}
{$IFDEF SAM2}
  Assign(d_6DB2.Raw, 'SAM201.GFX');
{$ENDIF}
{$IFDEF SAM3}
  Assign(d_6DB2.Raw, 'SAM301.GFX');
{$ENDIF}
  Reset(d_6DB2.Raw, $1F80);
  GetMem(d_6DA6, $1F80);
  Read(d_6DB2.Typed, d_6DA6^);
  u8_0c14(d_6DA6^, $1F80);
  GetMem(d_6D72, $1F80);
  Read(d_6DB2.Typed, d_6D72^);
  u8_0c14(d_6D72^, $1F80);
  GetMem(d_6D76, $1F80);
  Read(d_6DB2.Typed, d_6D76^);
  u8_0c14(d_6D76^, $1F80);
  GetMem(d_6D7E, $1F80);
  Read(d_6DB2.Typed, d_6D7E^);
  u8_0c14(d_6D7E^, $1F80);
  GetMem(d_6D82, $1F80);
  Read(d_6DB2.Typed, d_6D82^);
  u8_0c14(d_6D82^, $1F80);
  GetMem(d_6D86, $1F80);
  Read(d_6DB2.Typed, d_6D86^);
  u8_0c14(d_6D86^, $1F80);
  GetMem(d_6D8A, $1F80);
  Read(d_6DB2.Typed, d_6D8A^);
  u8_0c14(d_6D8A^, $1F80);
  GetMem(d_6D8E, $1F80);
  Read(d_6DB2.Typed, d_6D8E^);
  u8_0c14(d_6D8E^, $1F80);
  GetMem(d_6D92, $1F80);
  Read(d_6DB2.Typed, d_6D92^);
  u8_0c14(d_6D92^, $1F80);
  GetMem(d_6DA2, $1F80);
  Read(d_6DB2.Typed, d_6DA2^);
  u8_0c14(d_6DA2^, $1F80);
  GetMem(d_6D96, $1F80);
  Read(d_6DB2.Typed, d_6D96^);
  u8_0c14(d_6D96^, $1F80);
  GetMem(d_6D9A, $1F80);
  Read(d_6DB2.Typed, d_6D9A^);
  u8_0c14(d_6D9A^, $1F80);
  GetMem(d_6D9E, $1F80);
  Read(d_6DB2.Typed, d_6D9E^);
  u8_0c14(d_6D9E^, $1F80);
  GetMem(d_6D7A, $1F80);
  Read(d_6DB2.Typed, d_6D7A^);
  u8_0c14(d_6D7A^, $1F80);
  GetMem(d_6DAE, $1F80);
  Read(d_6DB2.Typed, d_6DAE^);
  u8_0c14(d_6DAE^, $1F80);
  GetMem(d_6DAA, $1F80);
  Read(d_6DB2.Typed, d_6DAA^);
  u8_0c14(d_6DAA^, $1F80);
  Close(d_6DB2.Raw);
{$IFDEF SAM1}
  Assign(d_6E3E.Raw, 'SAM102.GFX');
{$ENDIF}
{$IFDEF SAM2}
  Assign(d_6E3E.Raw, 'SAM202.GFX');
{$ENDIF}
{$IFDEF SAM3}
  Assign(d_6E3E.Raw, 'SAM302.GFX');
{$ENDIF}
  Reset(d_6E3E.Raw, $0800);
  GetMem(d_6E36, $0800);
  Read(d_6E3E.Typed, d_6E36^);
  u8_0c14(d_6E36^, $0800);
  GetMem(d_6E3A, $0800);
  Read(d_6E3E.Typed, d_6E3A^);
  u8_0c14(d_6E3A^, $0800);
  GetMem(d_6E32, $0800);
  Read(d_6E3E.Typed, d_6E32^);
  u8_0c14(d_6E32^, $0800);
  Close(d_6E3E.Raw);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_3c93;
var
  I: Integer;
begin
  for I := 0 to 15 do
    u9_0352(I, 0);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_3cb8;
var
  I: Integer;
begin
  d_6D18.X := d_34EC[1].X;
  d_6D18.Y := d_34EC[1].Y;
  d_6D18.Score := d_699A;
  d_6D18.Count := d_699E;
  d_6D18.Ammo := d_6858;
  d_6D18.ProjectileCount := d_69A2;
  for I := 1 to 20 do
    d_6D18.FlagsA[I] := d_6844[I];
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
  for I := 1 to 20 do
    d_6D18.FlagsB[I] := d_69BA[I];
  d_6D18.FlagC := d_69DC;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_3d6b;
var
  I: Integer;
begin
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
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_3e29(slot: Integer);
var
  f: t_u3_3e29_tsavefile;
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
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
function u3_3f8c(Slot: Integer): Boolean;
var
  F: t_u3_3f8c_tsavefile;
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
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_4e64;
var
  I: Word;
begin
  u3_079e;
  I := 0;
  Inc(I);
  d_3812[I] := 'CONTROLLING AGENT 006     Pg. 1';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := '         '#167'       '#168'  ';
  Inc(I);
  d_3812[I] := 'Key                     Action';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'ALT  (Button 1)         FIRE';
  Inc(I);
  d_3812[I] := 'CTRL (Button 0)         JUMP';
  Inc(I);
  d_3812[I] := 'ARROW KEYS              MOVE';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'You start in keyboard mode.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'Press F1 during the game to';
  Inc(I);
  d_3812[I] := 'use the joystick, redefine the';
  Inc(I);
  d_3812[I] := 'keyboard or any other option.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
  d_3812[I] := 'SHORT BRIEFING            Pg. 2';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'Your mission is to infiltrate';
  Inc(I);
  d_3812[I] := 'the island fortress and';
  Inc(I);
  d_3812[I] := 'retrieve the missing satellite';
  Inc(I);
  d_3812[I] := 'blueprints.';
  Inc(I);
  d_3812[I] := '                  '#131' '#132;
  Inc(I);
  d_3812[I] := 'The main fortress      is well';
  Inc(I);
  d_3812[I] := 'guarded and you will have to';
  Inc(I);
  d_3812[I] := 'destroy the security radars '#174;
  Inc(I);
  d_3812[I] := 'on each level in order to';
  Inc(I);
  d_3812[I] := 'access it.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
  d_3812[I] := 'ITEMS OF INTEREST         Pg. 3';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #137'  Keys match colored doors. '#140;
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #157'  Extra shots';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #159'  Extra speed';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #160'  Gun power-up';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #156'  Pushable barrel.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
  d_3812[I] := 'ITEMS OF INTEREST         Pg. 4';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #174'  Security radar. Destroy it.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #175'  Teleporter. Takes you to a';
  Inc(I);
  d_3812[I] := '   different spot on a level.';
  Inc(I);
  d_3812[I] := #176;
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #155'  Dynamite.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #158'  Blueprints.  The object of';
  Inc(I);
  d_3812[I] := '   your mission.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
  d_3812[I] := 'ITEMS OF INTEREST         Pg. 5';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #146'  Level exit doors.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #147;
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #144'  Computer terminal.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #145'  Floppy disk.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'You will have to determine how';
  Inc(I);
  d_3812[I] := 'to use these objects, 006.';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
  d_3812[I] := 'BONUS ITEMS               Pg. 6';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'There are many bonuses to grab';
  Inc(I);
  d_3812[I] := 'as you play.  There are even a';
  Inc(I);
  d_3812[I] := 'couple of hidden ones.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #148'  Money bag.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #149'  Briefcase.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #150'  Toothpaste for that pearly';
  Inc(I);
  d_3812[I] := '   white superhero smile.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
  d_3812[I] := 'BONUS ITEMS               Pg. 7';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #151'  Magnifying glass.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #152'  Computer card.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #154'  Spy watch.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #153'  Walkie-Talkie.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #161'  Teddy Bear.  The bonus of';
  Inc(I);
  d_3812[I] := '   choice with Commander Keen.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
  d_3812[I] := 'Enemies                   Pg. 8';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'You will face many types of ';
  Inc(I);
  d_3812[I] := 'Dr. No Body@s security force.';
  Inc(I);
  d_3812[I] := 'Following is a description';
  Inc(I);
  d_3812[I] := 'of each.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #169'  Guard - Armed only with a';
  Inc(I);
  d_3812[I] := '   knife. Very little threat.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #170'  Sentry - Slightly stronger';
  Inc(I);
  d_3812[I] := '   than a guard, but no match';
  Inc(I);
  d_3812[I] := '   for your skills.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
  d_3812[I] := 'Enemies                   Pg. 9';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #171'  Ninja - Highly trained in';
  Inc(I);
  d_3812[I] := '   the art of Ninja. Watch out.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #172'  Ninja Master - A very deadly';
  Inc(I);
  d_3812[I] := '   enemy. Has ability to shoot.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #173'  Thug - The most deadly human';
  Inc(I);
  d_3812[I] := '   enemy. Can fire at will.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'These enemies are deadly, but';
  Inc(I);
  d_3812[I] := 'the bureau has obtained details';
  Inc(I);
  d_3812[I] := 'on the robotic enemies as well.';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
  d_3812[I] := 'Robotic Enemies          Pg. 10';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #166'  This robot moves along the';
  Inc(I);
  d_3812[I] := '   ceiling and fires at you.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #135'  A flying robot that shoots';
  Inc(I);
  d_3812[I] := '   deadly electricity downward.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #136'  A ground based tank that has';
  Inc(I);
  d_3812[I] := '   very heavy armor plating.';
  Inc(I);
  d_3812[I] := #162;
  Inc(I);
  d_3812[I] := '   Robbie the Robot. Don@t get';
  Inc(I);
  d_3812[I] := #163'  this enemy angry at you.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
  d_3812[I] := 'Robotic Enemies          Pg. 11';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #164;
  Inc(I);
  d_3812[I] := '   This robot is difficult to';
  Inc(I);
  d_3812[I] := #165'  destroy and fires at you.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #133'  This half man-half robot ';
  Inc(I);
  d_3812[I] := '   has only one weakness.';
  Inc(I);
  d_3812[I] := #134;
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := #127' '#128'  This robot dog is not';
  Inc(I);
  d_3812[I] := '     man@s best friend.';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
  d_3812[I] := 'Player Health            Pg. 12';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'When you start a new level, you';
  Inc(I);
  d_3812[I] := 'will begin with three health';
  Inc(I);
  d_3812[I] := 'hits, designated by three';
  Inc(I);
  d_3812[I] := 'pictures of your man on the';
  Inc(I);
  d_3812[I] := 'status line.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'Each time you are hit, your';
  Inc(I);
  d_3812[I] := 'health decreases.  If you get';
  Inc(I);
  d_3812[I] := 'hit three times then you must';
  Inc(I);
  d_3812[I] := 'restart the level in order to';
  Inc(I);
  d_3812[I] := 'complete it.  You have infinite';
  Inc(I);
  d_3812[I] := 'men in order to win the game.';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
  d_3812[I] := 'Playing Tips             Pg. 13';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '* Some barrels can be pushed.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '* Use Save and Restore (F1) to';
  Inc(I);
  d_3812[I] := '  save your progress.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '* Watch the robots carefully.';
  Inc(I);
  d_3812[I] := '  They have certain weaknesses.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '* If you get stuck in a level,';
  Inc(I);
  d_3812[I] := '  then use the QUIT option to';
  Inc(I);
  d_3812[I] := '  the island map and restart.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
  d_3812[I] := 'Playing Tips             Pg. 14';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '* You can only carry ONE key of';
  Inc(I);
  d_3812[I] := '  each color at a time.  For';
  Inc(I);
  d_3812[I] := '  example, you CAN@T carry two';
  Inc(I);
  d_3812[I] := '  blue keys at the same time.';
  Inc(I);
  d_3812[I] := '  You must use one first.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '* Conserve shots.  You may need';
  Inc(I);
  d_3812[I] := '  them later.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '* Avoid exploding dynamite.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '- END OF FILE...';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
  d_3812[I] := 'END OF WINDOW';
  d_67FA[1] := 1;
  d_6814 := u3_26cf(0);
  d_6EC5 := 0;
  d_6816 := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_6ea9;
var
  I: Integer;
begin
  u3_079e;
  I := 1;
{$IFDEF SAM1}
  d_3812[I] := 'CONFIDENTIAL FILE         Pg. 1';
{$ELSE}
  d_3812[I] := 'BACKGROUND FILE           Pg. 1';
{$ENDIF}
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'To:        Agent 006';
  Inc(I);
  d_3812[I] := 'Priority:  For Your Eyes Only';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '**Destroy file after reading**';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'Our government scientists have';
  Inc(I);
  d_3812[I] := 'been working on a secret';
  Inc(I);
  d_3812[I] := 'project: A ruby-powered laser';
  Inc(I);
  d_3812[I] := 'satellite with the ability to';
  Inc(I);
  d_3812[I] := 'pinpoint and fire upon any';
  Inc(I);
  d_3812[I] := 'target from Earth orbit, code';
  Inc(I);
  d_3812[I] := 'named "Red Rock Rover".';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
{$IFNDEF SAM1}
  d_3812[I] := 'MISSION UPDATE            Pg. 2';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
{$IFDEF SAM2}
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '006 successfully infiltrated';
  Inc(I);
  d_3812[I] := 'DVS headquarters on the first';
  Inc(I);
  d_3812[I] := 'island, and gained possession of';
  Inc(I);
  d_3812[I] := 'the first of three blueprints.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'Using a jet raft, 006 has';
  Inc(I);
  d_3812[I] := 'landed upon the second island';
  Inc(I);
  d_3812[I] := 'fortress, and must find the';
  Inc(I);
  d_3812[I] := 'next blueprint to the "Red Rock';
  Inc(I);
  d_3812[I] := 'Rover" weapon.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
{$ELSE}
  d_3812[I] := '006 has destroyed the DVS';
  Inc(I);
  d_3812[I] := 'headquarters on the first and';
  Inc(I);
  d_3812[I] := 'second island fortresses, and';
  Inc(I);
  d_3812[I] := 'secured possession of two';
  Inc(I);
  d_3812[I] := 'crucial blueprints.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'Using scuba gear, 006 slipped';
  Inc(I);
  d_3812[I] := 'past the security net set up';
  Inc(I);
  d_3812[I] := 'around the final island.';
  Inc(I);
  d_3812[I] := 'Getting the final blueprint';
  Inc(I);
  d_3812[I] := 'will be the most dangerous';
  Inc(I);
  d_3812[I] := 'assignment yet, since this';
  Inc(I);
  d_3812[I] := 'island id the DVS stronghold!';
  Inc(I);
{$ENDIF}
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
{$ENDIF}
{$IFDEF SAM1}
  d_3812[I] := 'YOUR MISSION              Pg. 2';
{$ELSE}
  d_3812[I] := 'YOUR MISSION              Pg. 3';
{$ENDIF}
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'Two weeks ago the blueprints';
  Inc(I);
  d_3812[I] := 'were stolen by the Diabolical';
  Inc(I);
  d_3812[I] := 'Villain Society (DVS), which';
  Inc(I);
  d_3812[I] := 'will use them to build the';
  Inc(I);
  d_3812[I] := 'ultimate terrorist threat.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'You@ve been chosen by the';
  Inc(I);
  d_3812[I] := 'Bureau to infiltrate DVS';
  Inc(I);
  d_3812[I] := 'headquarters and secure the';
  Inc(I);
  d_3812[I] := 'blueprints.  The headquarters';
  Inc(I);
  d_3812[I] := 'are located on a series of';
  Inc(I);
  d_3812[I] := 'islands in the Pacific basin.';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
{$IFDEF SAM1}
  d_3812[I] := 'YOUR MISSION              Pg. 3';
{$ELSE}
  d_3812[I] := 'YOUR MISSION              Pg. 4';
{$ENDIF}
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'Your mission, should you choose';
  Inc(I);
  d_3812[I] := 'to accept it, is to bring back';
  Inc(I);
  d_3812[I] := 'the secret blueprints to the';
  Inc(I);
  d_3812[I] := '"Red Rock Rover" project.  You';
  Inc(I);
  d_3812[I] := 'will be isolated from outside';
  Inc(I);
  d_3812[I] := 'help.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'You should be warned that this';
  Inc(I);
  d_3812[I] := 'mission is of global importance';
  Inc(I);
  d_3812[I] := 'and must succeed in order to';
  Inc(I);
  d_3812[I] := 'maintain a balance of world';
  Inc(I);
  d_3812[I] := 'power.';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
{$IFDEF SAM1}
  d_3812[I] := 'YOUR MISSION              Pg. 4';
{$ELSE}
  d_3812[I] := 'YOUR MISSION              Pg. 5';
{$ENDIF}
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'We do not have a file on the';
  Inc(I);
  d_3812[I] := 'head of DVS, but he is';
  Inc(I);
  d_3812[I] := 'suspected to be very cunning';
  Inc(I);
  d_3812[I] := 'and dangerous.  DVS';
  Inc(I);
  d_3812[I] := 'headquarters are built up';
  Inc(I);
  d_3812[I] := 'as an elaborate series of';
  Inc(I);
  d_3812[I] := 'fortresses on three well';
  Inc(I);
  d_3812[I] := 'guarded islands.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'As always, should you be caught';
  Inc(I);
  d_3812[I] := 'the Bureau will disavow any';
  Inc(I);
  d_3812[I] := 'knowledge of your existence.';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
  d_3812[I] := 'END OF WINDOW';
  d_67FA[1] := 1;
  d_6814 := u3_26cf(0);
  d_6EC5 := 0;
  d_6816 := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_7c17;
var
  Row: Integer;
begin
  u3_079e;
  Row := 1;
  d_3812[Row] := 'MISSION SUCCESSFUL        Pg. 1';
  Inc(Row);
  d_3812[Row] := '-------------------------------';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := 'Congratulations 006, you have';
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'successfully destroyed the';
{$ELSE}
  d_3812[Row] := 'successfully infiltrated DVS';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'first DVS headquarters and';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'headquarters on the island,';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := 'headquarters on the last island';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'retrieved the first blueprint.';
{$ELSE}
  d_3812[Row] := 'and gained possession of the';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := '';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'second blueprint.  The Bureau';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := 'final blueprint.';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'The Bureau has hidden a jet';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'has hidden scuba gear on the';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := '';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'raft on the island that you can';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'island that you must use to';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := 'Dr. No Body and the DVS have';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'use to reach the second island';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'reach the third island';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := 'all been stopped and the world';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'fortress.  Once there, you will';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'fortress.  Once there, you will';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := 'is once again safe, well for a';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'overcome new dangers and traps';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'overcome new dangers and traps';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := 'few more days anyway...';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'to secure the second blueprint';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'to secure the final blueprint';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := '';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'to the "Red Rock Rover" weapon.';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'to the "Red Rock Rover" weapon.';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := '';
{$ENDIF}
  Inc(Row);
  d_3812[Row] := '-------------------------------';
  Inc(Row);
  d_3812[Row] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(Row);
  d_3812[Row] := 'HOW TO ORDER MORE GAMES   Pg. 2';
  Inc(Row);
  d_3812[Row] := '-------------------------------';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'Be sure to play the next two';
{$ELSE}
  d_3812[Row] := 'Be sure to play all the';
{$ENDIF}
  Inc(Row);
  d_3812[Row] := 'exciting missions, otherwise';
  Inc(Row);
  d_3812[Row] := 'the world will fall prey to the';
  Inc(Row);
  d_3812[Row] := 'evil intentions of the DVS!';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'The next two missions are:';
{$ELSE}
  d_3812[Row] := 'Get all the Secret Agent games:';
{$ENDIF}
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := ' * Kill Again Island';
{$ELSE}
  d_3812[Row] := ' * The Hunt For Red Rock Rover';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := ' * Dr. No Body';
{$ELSE}
  d_3812[Row] := ' * Kill Again Island';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := '';
{$ELSE}
  d_3812[Row] := ' * Dr. No Body';
{$ENDIF}
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := '-------------------------------';
  Inc(Row);
  d_3812[Row] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(Row);
  d_3812[Row] := 'HOW TO ORDER MORE GAMES   Pg. 3';
  Inc(Row);
  d_3812[Row] := '-------------------------------';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'In these two missions you will';
{$ELSE}
  d_3812[Row] := 'In the other missions you will';
{$ENDIF}
  Inc(Row);
  d_3812[Row] := 'encounter all-new challenges,';
  Inc(Row);
  d_3812[Row] := 'hazards, henchmen, levels,';
  Inc(Row);
  d_3812[Row] := 'puzzles, prizes, and basically';
  Inc(Row);
  d_3812[Row] := 'put to test all of your secret';
  Inc(Row);
  d_3812[Row] := 'agent skills!';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := 'To order, call 1-800-GAME-123';
  Inc(Row);
  d_3812[Row] := 'between the hours of 8am - 7pm';
  Inc(Row);
  d_3812[Row] := 'Central Standard Time (CST).';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := 'Price: $34 (incl. $4 Shipping)';
  Inc(Row);
  d_3812[Row] := '-------------------------------';
  Inc(Row);
  d_3812[Row] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(Row);
  d_3812[Row] := 'HOW TO ORDER MORE GAMES   Pg. 4';
  Inc(Row);
  d_3812[Row] := '-------------------------------';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := 'This price ($34) includes all';
  Inc(Row);
  d_3812[Row] := 'three Secret Agent missions,';
  Inc(Row);
  d_3812[Row] := 'which also sell for $15 apiece.';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := 'You may also order by mail:';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := '     Apogee Software';
  Inc(Row);
  d_3812[Row] := '     P.O. Box 476389';
  Inc(Row);
  d_3812[Row] := '     Garland, TX  75047';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := 'All orders include: hint sheet,';
  Inc(Row);
  d_3812[Row] := 'cheat password, and bonus game.';
  Inc(Row);
  d_3812[Row] := '-------------------------------';
  Inc(Row);
  d_3812[Row] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(Row);
  d_3812[Row] := 'END OF WINDOW';
  d_67FA[1] := 1;
  d_6814 := u3_26cf(0);
  d_6EC5 := 0;
  d_6816 := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_848e;
begin
  u3_079e;
  d_3812[1] := 'Congratulations! High score!';
  d_3812[2][0] := #0;
  d_3812[3] := '      Enter your name:';
  d_3812[4][0] := #0;
  d_3812[5] := '    ^';
  d_3812[6] := 'END OF WINDOW';
  d_6A44 := u3_1e2a(20);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_892b;
var
  KeyRight, KeyLeft, KeyUp, KeyDown, KeyFire, KeyJump, SpareWord: Word;
  Retry, ContinueRedefining: Boolean;
  procedure u3_8587;
  begin
    u3_079e;
    d_7068 := 'LEFT  - ' + d_7068;
    d_6FC4 := 'RIGHT - ' + d_6FC4;
    d_6ECE := 'UP    - ' + d_6ECE;
    d_6F20 := 'DOWN  - ' + d_6F20;
    d_7016 := 'JUMP  - ' + d_7016;
    d_6F72 := 'FIRE  - ' + d_6F72;
    d_3812[1] := 'KEYBOARD REDEFINED';
    d_3812[2][0] := #0;
    d_3812[3] := d_7068;
    d_3812[4] := d_6FC4;
    d_3812[5] := d_6ECE;
    d_3812[6] := d_6F20;
    d_3812[7] := d_7016;
    d_3812[8] := d_6F72;
    d_3812[9][0] := #0;
    d_3812[10] := 'Are these selections ok (Y-N): ^';
    d_3812[11][0] := #0;
    d_3812[12] := 'END OF WINDOW';
    d_67FA[1] := $15;
    d_67FA[2] := $31;
    d_6814 := u3_1601(0);
    if d_6814 = $31 then
      u3_892b
    else
    begin
      d_70C2 := KeyFire;
      d_70BE := KeyLeft;
      d_70C0 := KeyRight;
      d_70BA := KeyUp;
      d_70BC := KeyDown;
      d_70C4 := KeyJump;
    end;
  end;

  procedure u3_87fd;
  var
    KeyCode: Word;
  begin
    u3_079e;
    d_3812[1] := 'Sorry, that key is unavailable.';
    d_3812[2][0] := #0;
    d_3812[3] := '  Press any key to continue.';
    d_3812[4][0] := #0;
    d_3812[5] := '               ^';
    d_3812[6] := 'END OF WINDOW';
    KeyCode := u3_1601(1);
  end;
begin
  ContinueRedefining := True;

  repeat
    Retry := True;
    u3_079e;
    d_3812[1] := 'KEYBOARD REDEFINE';
    d_3812[2][0] := #0;
    d_3812[3] := 'Select key to move left: ^';
    d_3812[4] := 'END OF WINDOW';
    KeyLeft := u3_1601(1);
    if KeyLeft = 1 then
      ContinueRedefining := False;
    d_7068 := u3_a6f6(KeyLeft);
    if ContinueRedefining and (d_7068 = 'NULL') then
    begin
      u3_87fd;
      Retry := False;
    end;
  until Retry;

  if ContinueRedefining then
  begin
    repeat
      Retry := True;
      u3_079e;
      d_3812[1] := 'KEYBOARD REDEFINE';
      d_3812[2][0] := #0;
      d_3812[3] := 'Select key to move right: ^';
      d_3812[4] := 'END OF WINDOW';
      d_67FA[1] := 1;
      KeyRight := u3_1601(1);
      if KeyRight = 1 then
        ContinueRedefining := False;
      d_6FC4 := u3_a6f6(KeyRight);
      if ContinueRedefining and
         ((d_6FC4 = 'NULL') or (d_6FC4 = d_7068)) then
      begin
        u3_87fd;
        Retry := False;
      end;
    until Retry;
  end;

  if ContinueRedefining then
  begin
    repeat
      Retry := True;
      u3_079e;
      d_3812[1] := 'KEYBOARD REDEFINE';
      d_3812[2][0] := #0;
      d_3812[3] := 'Select key to move up: ^';
      d_3812[4] := 'END OF WINDOW';
      d_67FA[1] := 1;
      KeyUp := u3_1601(1);
      if KeyUp = 1 then
        ContinueRedefining := False;
      d_6ECE := u3_a6f6(KeyUp);
      if ContinueRedefining and
         ((d_6ECE = 'NULL') or (d_6ECE = d_7068) or
          (d_6ECE = d_6FC4)) then
      begin
        u3_87fd;
        Retry := False;
      end;
    until Retry;
  end;

  if ContinueRedefining then
  begin
    repeat
      Retry := True;
      u3_079e;
      d_3812[1] := 'KEYBOARD REDEFINE';
      d_3812[2][0] := #0;
      d_3812[3] := 'Select key to move down: ^';
      d_3812[4] := 'END OF WINDOW';
      d_67FA[1] := 1;
      KeyDown := u3_1601(1);
      if KeyDown = 1 then
        ContinueRedefining := False;
      d_6F20 := u3_a6f6(KeyDown);
      if ContinueRedefining and
         ((d_6F20 = 'NULL') or (d_6F20 = d_7068) or
          (d_6F20 = d_6FC4) or (d_6F20 = d_6ECE)) then
      begin
        u3_87fd;
        Retry := False;
      end;
    until Retry;
  end;

  if ContinueRedefining then
  begin
    repeat
      Retry := True;
      u3_079e;
      d_3812[1] := 'KEYBOARD REDEFINE';
      d_3812[2][0] := #0;
      d_3812[3] := 'Select key to jump: ^';
      d_3812[4] := 'END OF WINDOW';
      d_67FA[1] := 1;
      KeyJump := u3_1601(1);
      if KeyJump = 1 then
        ContinueRedefining := False;
      d_7016 := u3_a6f6(KeyJump);
      if ContinueRedefining and
         ((d_7016 = 'NULL') or (d_7016 = d_7068) or
          (d_7016 = d_6FC4) or (d_7016 = d_6ECE) or
          (d_7016 = d_6F20)) then
      begin
        u3_87fd;
        Retry := False;
      end;
    until Retry;
  end;

  if ContinueRedefining then
  begin
    repeat
      Retry := True;
      u3_079e;
      d_3812[1] := 'KEYBOARD REDEFINE';
      d_3812[2][0] := #0;
      d_3812[3] := 'Select key to fire: ^';
      d_3812[4] := 'END OF WINDOW';
      KeyFire := u3_1601(1);
      if KeyFire = 1 then
        ContinueRedefining := False;
      d_6F72 := u3_a6f6(KeyFire);
      if ContinueRedefining and
         ((d_6F72 = 'NULL') or (d_6F72 = d_7068) or
          (d_6F72 = d_6FC4) or (d_7016 = d_6ECE) or
          (d_7016 = d_6F20) or (d_6F72 = d_7016)) then
      begin
        u3_87fd;
        Retry := False;
      end;
    until Retry;
  end;

  if ContinueRedefining then
    u3_8587;

  MemW[$0000:$041C] := MemW[$0000:$041A];
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
function u3_8ea3: Word;
var
  level, code: Word;
begin
  u3_079e;
  d_3812[1] := 'Warp to which level?';
  d_3812[2] := '--------------------';
  d_3812[3][0] := #0;
  d_3812[4] := 'Select (1-16) : ^';
  d_3812[5][0] := #0;
  d_3812[6] := 'END OF WINDOW';
  d_6A44 := u3_1e2a(2);
  MemW[$0000:$041C] := MemW[$0000:$041A];
  Val(d_6A44, level, code);
  u3_8ea3 := level;
  d_6EC5 := 0;
  d_6816 := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_8fb6;
begin
  u3_079e;
  d_3812[1] := 'Save Which Game?';
  d_3812[2] := '----------------';
  d_3812[3][0] := #0;
  d_3812[4] := 'Select (0-9) : ^';
  d_3812[5][0] := #0;
  d_3812[6] := 'END OF WINDOW';
  d_67FA[1] := 2;
  d_67FA[2] := 3;
  d_67FA[3] := 4;
  d_67FA[4] := 5;
  d_67FA[5] := 6;
  d_67FA[6] := 7;
  d_67FA[7] := 8;
  d_67FA[8] := 9;
  d_67FA[9] := 10;
  d_67FA[10] := 11;
  d_67FA[11] := $1C;
  d_67FA[12] := 1;
  MemW[0:$041C] := MemW[0:$041A];
  d_6814 := u3_1601(0);
  if IOResult = 0 then ;
  case d_6814 of
    2..10: u3_3e29(d_6814 - 1);
    11: u3_3e29(0);
  end;
  d_6EC5 := 0;
  d_6816 := 0;
  u3_079e;
  if IOResult = 0 then
    d_3812[1] := 'Game Saved!'
  else
    d_3812[1] := 'File Error!';
  d_3812[2] := 'END OF WINDOW';
  d_67FA[1] := $1C;
  d_67FA[2] := 1;
  MemW[0:$041C] := MemW[0:$041A];
  d_6814 := u3_1601(1);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
function u3_9163: Integer;
begin
  u3_079e;
  d_3812[1] := 'Restore Which Game?';
  d_3812[2] := '-------------------';
  d_3812[3][0] := #0;
  d_3812[4] := 'Select (0-9) : ^';
  d_3812[5][0] := #0;
  d_3812[6] := 'END OF WINDOW';
  d_67FA[1] := 2;
  d_67FA[2] := 3;
  d_67FA[3] := 4;
  d_67FA[4] := 5;
  d_67FA[5] := 6;
  d_67FA[6] := 7;
  d_67FA[7] := 8;
  d_67FA[8] := 9;
  d_67FA[9] := 10;
  d_67FA[10] := 11;
  d_67FA[11] := $1C;
  d_67FA[12] := 1;
  MemW[0:$041C] := MemW[0:$041A];
  d_6814 := u3_1601(0);
  case d_6814 of
    2..10:
      if Ord(u3_3f8c(d_6814 - 1)) = 0 then
        d_6814 := $1C;
    11:
      if Ord(u3_3f8c(0)) = 0 then
        d_6814 := $1C;
  end;
  u3_9163 := d_6814;
  d_6EC5 := 0;
  d_6816 := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
function u3_9340: Char;
var
  I: Word;
begin
  I := 0;
  u3_079e;
  Inc(I); d_3812[I] := '     MAIN MENU';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := ' N)ew Game';
  Inc(I); d_3812[I] := ' R)estore Old Game';
  Inc(I); d_3812[I] := ' S)tory';
  Inc(I); d_3812[I] := ' I)nstructions';
  Inc(I); d_3812[I] := ' H)igh Scores';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := ' O)rdering Info.';
  Inc(I); d_3812[I] := ' F)oreign Orders';
  Inc(I); d_3812[I] := ' C)all Our BBS';
  Inc(I); d_3812[I] := ' V)ideo Support';
  Inc(I); d_3812[I] := ' A)bout Apogee';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := ' Q)uit to DOS';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := 'Make a selection: ^';
  Inc(I); d_3812[I] := 'END OF WINDOW';

  d_67FA[1] := $31;
  d_67FA[2] := $17;
  d_67FA[3] := $23;
  d_67FA[4] := $13;
  d_67FA[5] := $1F;
  d_67FA[6] := $18;
  d_67FA[7] := $10;
  d_67FA[8] := 1;
  d_67FA[9] := $39;
  d_67FA[10] := $1C;
  d_67FA[11] := $21;
  d_67FA[12] := $1E;
  d_67FA[13] := $2E;
  d_67FA[14] := $2F;

  d_6814 := u3_1601(0);
  case d_6814 of
    $31, $39, $1C:
      begin
        u3_9340 := 'B';
        d_6EC7 := 0;
        d_699E := 1;
      end;
    $17:
      begin
        u3_4e64;
        u3_9340 := 'I';
      end;
    $21:
      begin
        u3_c10d;
        u3_9340 := 'F';
      end;
    $2E:
      begin
        u3_cf40;
        u3_9340 := 'A';
      end;
    $23:
      begin
        u3_9340 := 'H';
        u3_9a71;
      end;
    $1E:
      begin
        u3_9340 := 'A';
        u3_d323;
      end;
    $2F:
      begin
        u3_9340 := 'V';
        u3_a027;
      end;
    $13:
      begin
        u3_9340 := 'R';
        d_699E := 1;
        d_6D60 := u3_9163;
        if d_6D60 = $1C then
        begin
          d_6D60 := 0;
          u3_9340 := ' ';
        end
        else
          d_6EC7 := 0;
      end;
    $1F:
      begin
        u3_9340 := 'S';
        u3_6ea9;
      end;
    $18:
      begin
        u3_9340 := 'O';
        u3_b898;
      end;
    $10:
      begin
        u3_9bdf;
        if d_6EC6 <> 0 then
          u3_9340 := 'Q'
        else
          u3_9340 := ' ';
      end;
    1:
      begin
        d_6EC5 := 0;
        u3_9340 := ' ';
      end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
function u3_97bb: Char;
var
  RestoreResult: Word;
begin
  u3_079e;
  d_3812[1] := 'Operational Command Bank';
  d_3812[2] := '------------------------';
  d_3812[3][0] := #0;
  d_3812[4] := 'H)elp';
  d_3812[5] := 'T)oggle Sounds';
  d_3812[6] := 'V)ideo Select';
  d_3812[7] := 'J)oystick Toggle';
  d_3812[8] := 'C)alibrate Joystick';
  d_3812[9] := 'K)eyboard Config';
  d_3812[10] := 'R)estore Game';
  d_3812[11] := 'S)ave Game';
  d_3812[12] := 'Q)uit';
  d_3812[13][0] := #0;
  d_3812[14] := 'Selection: ^';
  d_3812[15][0] := #0;
  d_3812[16] := 'END OF WINDOW';
  d_67FA[1] := $23;
  d_67FA[2] := $14;
  d_67FA[3] := $2F;
  d_67FA[4] := $24;
  d_67FA[5] := $2E;
  d_67FA[6] := $25;
  d_67FA[7] := $13;
  d_67FA[8] := $1F;
  d_67FA[9] := $10;
  d_67FA[10] := 1;

  d_6814 := u3_1601(0);
  case d_6814 of
    $23:
      begin
        u3_97bb := 'H';
        u3_4e64;
      end;
    $14:
      begin
        u3_97bb := 'T';
        u3_9de0;
      end;
    $2F:
      begin
        u3_97bb := 'V';
        u3_a027;
      end;
    $24:
      begin
        u3_97bb := 'J';
        u3_a1d8;
      end;
    $2E:
      begin
        u3_97bb := 'C';
        u3_a3b6;
      end;
    $25:
      begin
        u3_97bb := 'K';
        u3_892b;
      end;
    $13:
      begin
        u3_97bb := 'R';
        RestoreResult := u3_9163;
        if RestoreResult <> $1C then
          d_6EC8 := 1;
      end;
    $1F:
      begin
        u3_97bb := 'S';
        if d_681C = 1 then
          u3_8fb6
        else
        begin
          u3_079e;
          d_3812[1] := 'You can only save your game';
          d_3812[2] := 'on the island map.  ';
          d_3812[3][0] := #0;
          d_3812[4] := 'Press ESCAPE';
          d_3812[5] := 'END OF WINDOW';
          d_67FA[1] := 1;
          d_6814 := u3_1601(0);
          d_6EC5 := 0;
          d_6816 := 0;
        end;
      end;
    $10:
      begin
        u3_9ca9;
        if d_6EC6 <> 0 then
          u3_97bb := 'Q'
        else
          u3_97bb := ' ';
      end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_9a71;
var
  i: Word;
begin
  u3_079e;
  d_3812[1] := '  Secret Agents Hall of Fame';
  d_3812[2][0] := #0;
  d_3812[3][0] := #0;
  for i := 1 to 10 do
    d_3812[i + 3] := d_6B44.Names[i];
  d_3812[14][0] := #0;
  d_3812[15] := 'Press any key ^';
  d_3812[16][0] := #0;
  d_3812[17] := 'END OF WINDOW';
  d_67FA[1] := 1;
  d_6814 := u3_1601(1);
  d_6EC5 := 0;
  d_6816 := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_9b3e(input: string);
begin
  u3_079e;
  d_3812[1] := t_u3_9b3e_tbuffer(input).Narrow;
  d_3812[2][0] := #0;
  d_3812[3] := 'Press ESCAPE';
  d_3812[4] := 'END OF WINDOW';
  d_67FA[1] := 1;
  d_6814 := u3_1601(0);
  d_6EC5 := 0;
  d_6816 := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_9bdf;
begin
  u3_079e;
  d_3812[1] := 'Quit To Dos (Y-N) ^';
  d_3812[2] := 'END OF WINDOW';
  d_67FA[1] := 1;
  d_67FA[2] := $15;
  d_67FA[3] := $31;
  d_6814 := u3_1601(1);
  if d_6814 = $15 then
    d_6EC6 := 1;
  d_6EC5 := 0;
  d_6816 := 0;
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  MemW[0:$41C] := MemW[0:$41A];
  d_6824 := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_9ca9;
begin
  u3_079e;
  d_3812[1] := 'Quit to: ^';
  d_3812[2][0] := #0;
  d_3812[3] := ' D)os';
  d_3812[4] := ' T)itle Screen';
  d_3812[5] := ' I)sland Map';
  d_3812[6] := 'END OF WINDOW';
  d_67FA[1] := $20;
  d_67FA[2] := $14;
  d_67FA[3] := $17;
  d_67FA[4] := 1;
  d_6814 := u3_1601(1);
  if d_6814 = $20 then
  begin
    u3_3712;
    d_6EC6 := 1;
    d_6D66 := 0;
    u7_0000($12);
  end
  else if d_6814 = $14 then
  begin
    u3_3712;
    d_6EC7 := 1;
    d_6D66 := 0;
    u7_0000($12);
  end
  else if d_6814 = $17 then
  begin
    d_6EC8 := 1;
    d_6D66 := 0;
  end;
  d_6EC5 := 0;
  d_6816 := 0;
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  MemW[$0000:$041C] := MemW[$0000:$041A];
  d_6824 := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_9de0;
begin
  u3_079e;
  d_3812[1] := 'Sounds On (Y-N) ^';
  d_3812[2] := 'END OF WINDOW';
  d_67FA[1] := $15;
  d_67FA[2] := $31;
  d_67FA[3] := 1;
  d_6814 := u3_1601(1);
  if d_6814 = $15 then
    d_34AF := 1
  else
    d_34AF := 0;
  d_6EC5 := 0;
  d_6816 := 0;
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  MemW[$0000:$041C] := MemW[$0000:$041A];
  d_6824 := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_a027;
begin
  u3_079e;
  d_3812[1] := '    VIDEO BOARD COMPATIBILITY';
  d_3812[2][0] := #0;
  d_3812[3] := '    Some SuperVGA boards have';
  d_3812[4] := '   compatibility problems that';
  d_3812[5] := '  cause the screen to jerk when';
  d_3812[6] := 'scrolling, or perform unreliably.';
  d_3812[7][0] := #0;
  d_3812[8] := ' This is the fault of the video';
  d_3812[9] := ' board makers not producing 100%';
  d_3812[10] := '   compatible graphics cards.';
  d_3812[11][0] := #0;
  d_3812[12] := ' We have tried to support all the';
  d_3812[13] := 'boards we know of, but if you have';
  d_3812[14] := '    problems, then toggle this';
  d_3812[15] := '   setting and see if it helps.';
  d_3812[16][0] := #0;
  d_3812[17] := '  Alternate video setting (Y-N) ^ ';
  d_3812[18] := 'END OF WINDOW';
  d_67FA[1] := $15;
  d_67FA[2] := $31;
  d_67FA[3] := 1;
  d_6814 := u3_1601(0);
  if d_6814 = $15 then
    d_70C6 := 1
  else
    d_70C6 := 0;
  d_6EC5 := 0;
  d_6816 := 0;
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  MemW[0:$041C] := MemW[0:$041A];
  d_6824 := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_a1d8;
begin
  u3_079e;
  d_3812[1] := 'Joystick On (Y-N) ^';
  d_3812[2] := 'END OF WINDOW';
  d_67FA[1] := $15;
  d_67FA[2] := $31;
  d_67FA[3] := 1;
  d_6814 := u3_1601(1);
  if d_6814 = $15 then
  begin
    d_341C := u6_0000;
    d_70C8 := 1;
  end
  else if d_6814 = $31 then
  begin
    d_341C := False;
    d_70C8 := 0;
  end;
  d_6EC5 := 0;
  d_6816 := 0;
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  MemW[0:$041C] := MemW[0:$041A];
  d_6824 := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_a3b6;
var
  i: Word;
begin
  u3_079e;
  i := 0;
  Inc(i);
  d_3812[i] := '  Set your joystick so that';
  Inc(i);
  d_3812[i] := 'it is in the middle position.';
  Inc(i);
  d_3812[i] := ' ';
  Inc(i);
  d_3812[i] := '   Press SPACE when this is';
  Inc(i);
  d_3812[i] := ' done, and the joystick will';
  Inc(i);
  d_3812[i] := '       be calibrated.';
  Inc(i);
  d_3812[i] := ' ';
  Inc(i);
  d_3812[i] := 'This step is not necessary if';
  Inc(i);
  d_3812[i] := ' your joystick is set in the';
  Inc(i);
  d_3812[i] := ' middle when the game loads.';
  Inc(i);
  d_3812[i] := ' ';
  Inc(i);
  d_3812[i] := 'Press Escape if your joystick';
  Inc(i);
  d_3812[i] := '         is not on.';
  Inc(i);
  d_3812[i] := '              ^';
  Inc(i);
  d_3812[i] := 'END OF WINDOW';

  d_67FA[1] := 1;
  d_67FA[2] := $39;
  d_6814 := u3_1601(0);
  if d_6814 = $39 then
  begin
    d_341C := u6_0000;
    if d_341C then
    begin
      d_6D68 := u6_00cc(0);
      d_6D6A := u6_00cc(1);
    end;
  end;

  d_6EC5 := 0;
  d_6816 := 0;
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  MemW[0:$041C] := MemW[0:$041A];
  d_6824 := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
function u3_a6f6(key: Word): string;
begin
  case key of
    2: u3_a6f6 := '1';
    3: u3_a6f6 := '2';
    4: u3_a6f6 := '3';
    5: u3_a6f6 := '4';
    6: u3_a6f6 := '5';
    7: u3_a6f6 := '6';
    8: u3_a6f6 := '7';
    9: u3_a6f6 := '8';
    10: u3_a6f6 := '9';
    11: u3_a6f6 := '0';
    16: u3_a6f6 := 'Q';
    17: u3_a6f6 := 'W';
    18: u3_a6f6 := 'E';
    19: u3_a6f6 := 'R';
    20: u3_a6f6 := 'T';
    21: u3_a6f6 := 'Y';
    22: u3_a6f6 := 'U';
    23: u3_a6f6 := 'I';
    24: u3_a6f6 := 'O';
    25: u3_a6f6 := 'P';
    28: u3_a6f6 := 'ENTER';
    29: u3_a6f6 := 'CTRL';
    30: u3_a6f6 := 'A';
    31: u3_a6f6 := 'S';
    32: u3_a6f6 := 'D';
    33: u3_a6f6 := 'F';
    34: u3_a6f6 := 'G';
    35: u3_a6f6 := 'H';
    36: u3_a6f6 := 'J';
    37: u3_a6f6 := 'K';
    38: u3_a6f6 := 'L';
    42: u3_a6f6 := 'L-SHIFT';
    44: u3_a6f6 := 'Z';
    45: u3_a6f6 := 'X';
    46: u3_a6f6 := 'C';
    47: u3_a6f6 := 'V';
    48: u3_a6f6 := 'B';
    49: u3_a6f6 := 'N';
    50: u3_a6f6 := 'M';
    51: u3_a6f6 := ',';
    52: u3_a6f6 := '.';
    53: u3_a6f6 := '/';
    54: u3_a6f6 := 'R-SHIFT';
    56: u3_a6f6 := 'ALT';
    57: u3_a6f6 := 'SPACE';
    71: u3_a6f6 := 'HOME';
    72: u3_a6f6 := 'UP ARROW';
    73: u3_a6f6 := 'PGUP';
    75: u3_a6f6 := 'LEFT ARROW';
    77: u3_a6f6 := 'RIGHT ARROW';
    79: u3_a6f6 := 'END';
    80: u3_a6f6 := 'DOWN ARROW';
    81: u3_a6f6 := 'PGDN';
    82: u3_a6f6 := 'INSERT';
    83: u3_a6f6 := 'DELETE';
  else
    u3_a6f6 := 'NULL';
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_acdd;
begin
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_af56;
var
  I: Word;
  KeyCode: Word;
begin
  u3_079e;
  I := 0;
  Inc(I); d_3812[I] := 'ORDERING THE SECRET AGENT SERIES!';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '    Please specify disk size:';
  Inc(I); d_3812[I] := '         5.25"  or  3.5"';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '   To order send $34, check or';
  Inc(I); d_3812[I] := '   money order (USA funds) to:';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '         Apogee Software';
  Inc(I); d_3812[I] := '         P.O. Box 476386';
  Inc(I); d_3812[I] := '     Garland, TX 75047  (USA)';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '     Or CALL NOW toll free:';
  Inc(I); d_3812[I] := '         1-800-GAME123';
  Inc(I); d_3812[I] := '     (Visa and MasterCard)';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '    Continued...Press Any Key';
  Inc(I); d_3812[I] := 'END OF WINDOW';
  MemW[0:$41C] := MemW[0:$41A];
  KeyCode := u3_1601(1);
  d_6EC5 := 1;
  u3_acdd;
  u3_079e;
  I := 0;
  Inc(I); d_3812[I] := ' USE YOUR FAX MACHINE TO ORDER!';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := 'You can now use your FAX machine';
  Inc(I); d_3812[I] := ' to order your favorite Apogee';
  Inc(I); d_3812[I] := '   games quickly and easily.';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := ' Simply print out the ORDER.FRM';
  Inc(I); d_3812[I] := '  file, fill it out and FAX it';
  Inc(I); d_3812[I] := '  to us for prompt processing.';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '   FAX Orders: (214) 278-4670';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '          Press Any Key';
  Inc(I); d_3812[I] := 'END OF WINDOW';
  MemW[0:$41C] := MemW[0:$41A];
  KeyCode := u3_1601(1);
  d_6EC5 := 1;
  u3_acdd;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_b4d6;
var
  Row: Word;
  ModeResult: Word;
begin
  u3_079e;
  Row := 0;
  Inc(Row);
  d_3812[Row] := 'ORDERING THE SECRET AGENT SERIES!';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := '     Order now and receive:';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := '  * All three devious missions';
  Inc(Row);
  d_3812[Row] := '  * The hints and tricks sheet';
  Inc(Row);
  d_3812[Row] := '  * The secret cheat password';
  Inc(Row);
  d_3812[Row] := '  * Exciting new bonus game';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := '    To order, call toll free:';
  Inc(Row);
  d_3812[Row] := '         1-800-426-3123';
  Inc(Row);
  d_3812[Row] := '  (Visa and MasterCard Welcome)';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Foreign orders:  Please read the';
  Inc(Row);
  d_3812[Row] := '  "Foreign Orders" menu option.';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := '    Continued...Press Any Key';
  Inc(Row);
  d_3812[Row] := 'END OF WINDOW';
  MemW[0:$041C] := MemW[0:$041A];
  ModeResult := u3_1601(1);
  d_6EC5 := 1;
  u3_acdd;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_b898;
var
  I: Word;
  KeyCode: Word;
begin
  u3_079e;
  I := 0;
  Inc(I); d_3812[I] := 'ORDERING THE SECRET AGENT SERIES!';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := ' Secret Agent consists of three';
  Inc(I); d_3812[I] := 'original and incredible missions:';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '  1) The Hunt for Red Rock Rover';
  Inc(I); d_3812[I] := '  2) Kill Again Island';
  Inc(I); d_3812[I] := '  3) Dr. No Body';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := ' You may order the entire series';
  Inc(I); d_3812[I] := ' for only $30, plus $4 shipping.';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := ' Each episode is set on a unique';
  Inc(I); d_3812[I] := 'island, with all-new dangers, new';
  Inc(I); d_3812[I] := ' levels, and all-new challenges.';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '    Continued...Press Any Key';
  Inc(I); d_3812[I] := 'END OF WINDOW';
  MemW[0:$41C] := MemW[0:$41A];
  KeyCode := u3_1601(1);
  d_6EC5 := 1;
  u3_acdd;
  u3_b4d6;
  u3_af56;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_c10d;
var
  Row: Word;
  KeyCode: Word;
begin
  u3_079e;
  Row := 0;
  Inc(Row);
  d_3812[Row] := '       FOREIGN CUSTOMERS';
  Inc(Row);
  d_3812[Row] := '       -----------------';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'The following screens list our';
  Inc(Row);
  d_3812[Row] := '  dealers outside the United';
  Inc(Row);
  d_3812[Row] := 'States, for Australia, Germany,';
  Inc(Row);
  d_3812[Row] := 'Canada and the United Kingdom.';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := '  These are official Apogee';
  Inc(Row);
  d_3812[Row] := '   dealers with the latest';
  Inc(Row);
  d_3812[Row] := '      games and updates.';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'If your country is not listed,';
  Inc(Row);
  d_3812[Row] := ' you may order directly from';
  Inc(Row);
  d_3812[Row] := 'Apogee by phone or USA check.';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := '        Press Any Key ^';
  Inc(Row);
  d_3812[Row] := 'END OF WINDOW';
  d_6824 := 999;
  MemW[0:$041C] := MemW[0:$041A];
  KeyCode := u3_1601(1);
  u3_acdd;

  u3_079e;
  Row := 0;
  Inc(Row);
  d_3812[Row] := '      AUSTRALIAN CUSTOMERS';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'PRICE: $45 + $5 shipping.';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'BudgetWare';
  Inc(Row);
  d_3812[Row] := 'P.O. Box 496';
  Inc(Row);
  d_3812[Row] := 'Newtown, NSW  2042';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Phone:      (02) 519-4233';
  Inc(Row);
  d_3812[Row] := 'Toll free:  (008) 022-064';
  Inc(Row);
  d_3812[Row] := 'Fax:        (02) 516-4236';
  Inc(Row);
  d_3812[Row] := 'CompuServe: 71520,1475';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Use MasterCard, Visa, Bankcard,';
  Inc(Row);
  d_3812[Row] := 'cheques.';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'END OF WINDOW';
  d_6824 := 999;
  MemW[0:$041C] := MemW[0:$041A];
  KeyCode := u3_1601(1);
  u3_acdd;

  u3_079e;
  Row := 0;
  Inc(Row);
  d_3812[Row] := '      AUSTRALIAN CUSTOMERS';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'PRICE: $45 + $5 shipping.';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Manaccom';
  Inc(Row);
  d_3812[Row] := '9 Camford Str.';
  Inc(Row);
  d_3812[Row] := 'Milton, Qld. 4064';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Phone: (07) 368-2366';
  Inc(Row);
  d_3812[Row] := 'Fax:   (07) 369-7589';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Use MasterCard, Visa, Bankcard,';
  Inc(Row);
  d_3812[Row] := 'American Express, or cheques.';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'END OF WINDOW';
  d_6824 := 999;
  MemW[0:$041C] := MemW[0:$041A];
  KeyCode := u3_1601(1);
  u3_acdd;

  u3_079e;
  Row := 0;
  Inc(Row);
  d_3812[Row] := '    CANADIAN CUSTOMERS';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'PRICE: $42 Canadian.';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Distant Markets';
  Inc(Row);
  d_3812[Row] := 'Box 1149';
  Inc(Row);
  d_3812[Row] := '194 - 3803 Calgary Trail S.';
  Inc(Row);
  d_3812[Row] := 'Edmondton, Alb.  T6J 5M8';
  Inc(Row);
  d_3812[Row] := 'CANADA';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Orders:    1-800-661-7383';
  Inc(Row);
  d_3812[Row] := 'Inquiries: (403) 436-3009';
  Inc(Row);
  d_3812[Row] := 'Fax:       (403) 435-0928';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Use MasterCard, Visa or';
  Inc(Row);
  d_3812[Row] := 'money orders.';
  Inc(Row);
  d_3812[Row] := 'END OF WINDOW';
  d_6824 := 999;
  MemW[0:$041C] := MemW[0:$041A];
  KeyCode := u3_1601(1);
  u3_acdd;

  u3_079e;
  Row := 0;
  Inc(Row);
  d_3812[Row] := '        GERMAN CUSTOMERS';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Price: 49,-- DM plus 10,-- DM';
  Inc(Row);
  d_3812[Row] := 'Total: 59,-- DM (Deutsche Mark)';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'CDV-Software';
  Inc(Row);
  d_3812[Row] := 'Ettlingerstr. 5';
  Inc(Row);
  d_3812[Row] := '7500 Karlsruhe 1  GERMANY';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Phone: 0721-22295';
  Inc(Row);
  d_3812[Row] := 'Fax:   0721-21314';
  Inc(Row);
  d_3812[Row] := 'Compuserve: 1000022,274';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Use Visa, MasterCard, EuroCard,';
  Inc(Row);
  d_3812[Row] := 'American Express, cheque, money';
  Inc(Row);
  d_3812[Row] := 'order, or C.O.D.';
  Inc(Row);
  d_3812[Row] := 'END OF WINDOW';
  d_6824 := 999;
  MemW[0:$041C] := MemW[0:$041A];
  KeyCode := u3_1601(1);
  u3_acdd;

  u3_079e;
  Row := 0;
  Inc(Row);
  d_3812[Row] := '    UNITED KINGDOM CUSTOMERS';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Price: /29 + VAT + /2 P&P';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Precision Software Applications';
  Inc(Row);
  d_3812[Row] := 'Unit 3, Valley Court Offices';
  Inc(Row);
  d_3812[Row] := 'Lower Rd';
  Inc(Row);
  d_3812[Row] := 'Croydon, Near Royston';
  Inc(Row);
  d_3812[Row] := 'Harts. SG8 0HF, United Kingdom';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Phone: +44 (0) 223 208 288';
  Inc(Row);
  d_3812[Row] := 'FAX:   +44 (0) 223 208 089';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Credit cards, Access, cheques,';
  Inc(Row);
  d_3812[Row] := 'postal & Bankers orders.';
  Inc(Row);
  d_3812[Row] := 'Make cheques payable to PSA.';
  Inc(Row);
  d_3812[Row] := 'END OF WINDOW';
  d_6824 := 999;
  MemW[0:$041C] := MemW[0:$041A];
  KeyCode := u3_1601(1);
  u3_acdd;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_cf40;
var
  menuIndex: Word;
  selectedValue: Word;
begin
  u3_079e;
  menuIndex := 0;
  Inc(menuIndex);
  d_3812[menuIndex] := '   THE OFFICIAL APOGEE BBS';
  Inc(menuIndex);
  d_3812[menuIndex] := '   -----------------------';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := 'The SOFTWARE CREATIONS BBS is';
  Inc(menuIndex);
  d_3812[menuIndex] := ' the home BBS for the latest';
  Inc(menuIndex);
  d_3812[menuIndex] := ' Apogee games.  Check out our';
  Inc(menuIndex);
  d_3812[menuIndex] := 'FREE "Apogee" file section for';
  Inc(menuIndex);
  d_3812[menuIndex] := '  new releases and updates.';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := '       BBS phone lines:';
  Inc(menuIndex);
  d_3812[menuIndex] := '(508) 365-2359  2400 baud';
  Inc(menuIndex);
  d_3812[menuIndex] := '(508) 365-9825  9600 baud';
  Inc(menuIndex);
  d_3812[menuIndex] := '(508) 365-9668  14.4k dual HST';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := '  Many node lines available!';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := '        Press Any Key ^';
  Inc(menuIndex);
  d_3812[menuIndex] := 'END OF WINDOW';

  d_6824 := $03E7;
  MemW[$0000:$041C] := MemW[$0000:$041A];
  selectedValue := u3_1601(1);
  u3_acdd;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_d323;
var
  menuIndex, selectedValue: Word;
begin
  u3_079e;
  menuIndex := 0;
  Inc(menuIndex);
  d_3812[menuIndex] := '     About Apogee Software';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := 'Our goal is to establish Apogee';
  Inc(menuIndex);
  d_3812[menuIndex] := '  as the leader in commercial';
  Inc(menuIndex);
  d_3812[menuIndex] := ' quality shareware games. With';
  Inc(menuIndex);
  d_3812[menuIndex] := ' enthusiasm and dedication we';
  Inc(menuIndex);
  d_3812[menuIndex] := 'think our goal can be achieved.';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := 'However,  we need your support.';
  Inc(menuIndex);
  d_3812[menuIndex] := 'Shareware is not free software.';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := '  We thank you in advance for';
  Inc(menuIndex);
  d_3812[menuIndex] := '   your contribution to the';
  Inc(menuIndex);
  d_3812[menuIndex] := '  growing shareware community.';
  Inc(menuIndex);
  d_3812[menuIndex] := '      Your honesty pays...';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := '        Press any key ^';
  Inc(menuIndex);
  d_3812[menuIndex] := 'END OF WINDOW';
  d_6824 := $03E7;
  MemW[0:$041C] := MemW[0:$041A];
  selectedValue := u3_1601(1);
  u3_acdd;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_d645;
var
  i: Word;
  resultWord: Word;
begin
  u3_079e;
  i := 0;
  Inc(i);
  d_3812[i] := 'Good work 006, you@ve knocked';
  Inc(i);
  d_3812[i] := 'out the island security system';
  Inc(i);
  d_3812[i] := '  and can now infiltrate the';
  Inc(i);
  d_3812[i] := '     level containing the';
  Inc(i);
  d_3812[i] := ' blueprints to the "Red Rock';
  Inc(i);
  d_3812[i] := '      Rover" satellite.';
  Inc(i);
  d_3812[i][0] := #0;
  Inc(i);
  d_3812[i] := 'Press ESCAPE!          ';
  Inc(i);
  d_3812[i] := 'END OF WINDOW';
  d_67FA[1] := 1;
  d_67FA[2] := $1C;
  d_67FA[3] := $39;
  d_6824 := $03E7;
  MemW[0:$041C] := MemW[0:$041A];
  resultWord := u3_1601(0);
  d_6EC5 := 0;
  d_6816 := 0;
  u3_acdd;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_d820;
var
  menuIndex, selectedValue: Word;
begin
  u3_079e;
  menuIndex := 0;
  Inc(menuIndex);
  d_3812[menuIndex] := ' 25,000 point BONUS for';
  Inc(menuIndex);
  d_3812[menuIndex] := 'finishing the level with';
  Inc(menuIndex);
  d_3812[menuIndex] := '    perfect health!';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := 'Press ESCAPE!          ';
  Inc(menuIndex);
  d_3812[menuIndex] := 'END OF WINDOW';
  d_67FA[1] := 1;
  d_67FA[2] := $1C;
  d_67FA[3] := $39;
  d_6824 := $03E7;
  MemW[$0000:$041C] := MemW[$0000:$041A];
  selectedValue := u3_1601(0);
  d_6EC5 := 0;
  d_6816 := 0;
  u3_acdd;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_dbc2;
var
  I, D_2, D_3, D_4: Word;
begin
  TextMode(3);
  ClrScr;
  GotoXY(1, 1);
  for I := 0 to 19 do
  begin
    u4_0399(4 * I + 1, 1, 8, 0, t_u3_dbc2_border);
    u4_0399(4 * I + 2, 1, 7, 0, t_u3_dbc2_border);
    u4_0399(4 * I + 3, 1, 15, 0, t_u3_dbc2_border);
    u4_0399(4 * I + 4, 1, 7, 0, t_u3_dbc2_border);
  end;
{$IFDEF SAM1}
  u4_0309(9, 2, 72, 4, 15, 4, 3);
  u4_0349(3, 15, 4, ' HOW TO ORDER THE FINAL TWO AMAZING EPISODES OF SECRET AGENT');
  u4_0309(5, 7, 76, 21, 3, 4, 3);
  u4_0349(8, 14, 4, ' The final two episodes of SECRET AGENT continue your adventure');
  u4_0349(9, 14, 4, ' as the heroic super spy 006'#171'.  You''ll encounter fun and danger');
  u4_0349(10, 14, 4, ' on two all-new islands, packed with new graphics and challenges.');
  u4_0349(12, 14, 4, ' By ordering the final two episodes of SECRET AGENT you''ll get:');
  u4_0349(13, 14, 4, ' The hints and tricks sheet, the cheat password, and an all-new');
  u4_0349(14, 14, 4, ' bonus game from Apogee Software for you to try out.');
  u4_0349(16, 15, 4, ' Apogee Software             CALL TOLL FREE!  ');
  u4_0349(17, 15, 4, ' P.O. Box 476389              1-800-GAME123   ');
  u4_0349(18, 15, 4, ' Garland, TX 75047          Visa or MasterCard ');
  u4_0349(20, 14, 4, ' Or mail $34 (check or money order) to order SECRET AGENT.');
{$ELSE}
  u4_0101(1, 1, 80, 24, 3, 1, 4);
  u4_0309(5, 3, 76, 6, 128, 6, 7);
  u4_0349(4, 15, 6, ' NOTICE: THIS GAME IS NOT SHAREWARE, FREEWARE NOR PUBLIC DOMAIN!');
  u4_0349(5, 15, 6, ' THIS GAME MAY ONLY BE DISTRIBUTED BY AUTHORIZED APOGEE DEALERS.');
  u4_0309(5, 8, 76, 22, 2, 4, 3);
  u4_0349(9, 15, 4, ' Only the first episode of SECRET AGENT is available as shareware.');
  u4_0349(11, 14, 4, ' The remaining two episodes (including this episode), are only sold');
  u4_0349(12, 14, 4, ' by Apogee Software, or through authorized distributors.');
  u4_0349(14, 14, 4, ' Bulletin boards, shareware vendors, user groups and clubs MAY NOT');
  u4_0349(15, 14, 4, ' distribute this episode of SECRET AGENT without lawful penalties.');
  u4_0349(17, 14, 4, ' SECRET AGENT consists of three unique and exciting episodes:');
  u4_0349(18, 14, 4, ' The Hunt for Red Rock Rover - Kill Again Island - Dr. No Body');
  u4_0349(20, 15, 4, ' To order the complete SECRET AGENT trilogy, call 1-800-GAME123');
  u4_0349(21, 15, 4, ' Or write:  Apogee Software  P.O. Box 476389  Garland, TX 75047');
{$ENDIF}
  TextColor(3);
  TextBackground(0);
  GotoXY(1, 24);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u3_ddd2;
var
  I, ResultWord: Word;
begin
  u9_01a3(0);
  ResultWord := u5_000f(2);
  ResultWord := u5_0047(1);
  ResultWord := u9_01d3($28);
  d_6838 := 0;
  d_683A := 0;
  d_683C := 0;
  d_6840 := 0;
{$IFDEF SAM1}
  ResultWord := u5_1915('SAM1.END', 1, 0, 0);
{$ELSE}
{$IFDEF SAM2}
  ResultWord := u5_1915('SAM2.END', 1, 0, 0);
{$ELSE}
  ResultWord := u5_1915('SAM3A.END', 1, 0, 0);
{$ENDIF}
{$ENDIF}
  u3_00db(0);
  for I := 1 to 30 do
  begin
    Delay(50);
    MemW[0:$041C] := MemW[0:$041A];
  end;
  u3_7c17;
  MemW[0:$041C] := MemW[0:$041A];
  repeat until KeyPressed;
{$IFDEF SAM3}
  u3_0232(0);
  ResultWord := u5_1915('SAM3B.END', 1, 0, 0);
  u3_00db(0);
  MemW[0:$041C] := MemW[0:$041A];
  repeat until KeyPressed;
{$ENDIF}
  MemW[0:$041C] := MemW[0:$041A];
  u3_3712;
  d_6EC7 := 1;
  d_6D66 := 0;
  d_6EC6 := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
begin
end.
