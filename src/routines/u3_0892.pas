{@decls}

{@stubs}
procedure u9_0475(var Data; X, Y: Integer);
procedure u9_051f(var Data; X, Y: Integer);
{@body}
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
