unit U2;
{$A+}{$D+}{$L+}{$F-}
interface
uses U8;
var
  d_0296: array[1..40, 1..25] of TCell;
procedure u2_0000(X, Y: Integer);
procedure u2_1185(X, Y: Integer);
procedure u2_2530(X, Y: Integer);
procedure u2_2c6e(X, Y, Tile, A, B: Integer; C, D, Foreground: Byte);
procedure u2_2e88(X, Y: Integer; Symbol: String);
procedure u2_3a91(X, Y: Integer; Symbol: String; Foreground: Byte);
procedure u2_68a9(rowIndex: Integer; row: TLevelRow);
procedure u2_a1ae(Level: Integer);
implementation
uses Dos, U9, Crt, U7, U6, U5, U4, U3;
{$F+}
procedure u2_0000(X, Y: Integer);
var
  X0, Y0, X1, Y1, ScreenX, ScreenY: Integer;
begin
  X0 := X shr 4;
  Y0 := Y shr 4;
  if (X0 >= 0) and (X0 <= 39) and (Y0 >= 0) then
  begin
    X1 := (X shr 4) + 1;
    Y1 := (Y shr 4) + 1;
    ScreenX := X0 shl 1;
    ScreenY := Y0 shl 4;
    case d_0296[X1, Y1].Tile of
      0: ;
      1..8: u9_2e6d(ScreenX, ScreenY + d_6840, d_0296[X1, Y1].Tile - 1);
      9..50: u9_2a9f(d_6D72^.Images[d_0296[X1, Y1].Tile].Pixels[1], ScreenX, ScreenY + d_6840);
      101: u9_2e6d(ScreenX, ScreenY + d_6840, 4);
      100, 102..150: u9_2a9f(d_6D76^.Images[d_0296[X1, Y1].Tile - 100].Pixels[1], ScreenX, ScreenY + d_6840);
      179:
        if d_6840 = 16 then
          u9_2a9f(d_6D96^.Images[29].Pixels[1], ScreenX, ScreenY + d_6840)
        else
          u9_2a9f(d_6D96^.Images[30].Pixels[1], ScreenX, ScreenY + d_6840);
      151..200: u9_2a9f(d_6D96^.Images[d_0296[X1, Y1].Tile - 150].Pixels[1], ScreenX, ScreenY + d_6840);
      201..250: u9_2a9f(d_6D9A^.Images[d_0296[X1, Y1].Tile - 200].Pixels[1], ScreenX, ScreenY + d_6840);
      251..300: u9_2a9f(d_6DAA^.Images[d_0296[X1, Y1].Tile - 250].Pixels[1], ScreenX, ScreenY + d_6840);
      301..350: u9_2a9f(d_6DA2^.Images[d_0296[X1, Y1].Tile - 300].Pixels[1], ScreenX, ScreenY + d_6840);
      351..400: u9_2a9f(d_6DAE^.Images[d_0296[X1, Y1].Tile - 350].Pixels[1], ScreenX, ScreenY + d_6840);
      401..450: u9_2a9f(d_6D7E^.Images[d_0296[X1, Y1].Tile - 400].Pixels[1], ScreenX, ScreenY + d_6840);
      499:
        if d_6840 = 16 then
          u9_2a9f(d_6D82^.Images[49].Pixels[1], ScreenX, ScreenY + d_6840)
        else
          u9_2a9f(d_6D82^.Images[1].Pixels[1], ScreenX, ScreenY + d_6840);
      451..500: u9_2a9f(d_6D82^.Images[d_0296[X1, Y1].Tile - 450].Pixels[1], ScreenX, ScreenY + d_6840);
      535:
        if d_6840 = 16 then
          u9_2a9f(d_6D72^.Images[21].Pixels[1], ScreenX, ScreenY + d_6840)
        else
          u9_2a9f(d_6D72^.Images[35].Pixels[1], ScreenX, ScreenY + d_6840);
      501..550: u9_2a9f(d_6D72^.Images[d_0296[X1, Y1].Tile - 500].Pixels[1], ScreenX, ScreenY + d_6840);
      613:
        if d_6840 = 16 then
          u9_2a9f(d_6D86^.Images[13].Pixels[1], X0 shl 1, (Y0 shl 4) + d_6840)
        else
          u9_2a9f(d_6D86^.Images[17].Pixels[1], X0 shl 1, (Y0 shl 4) + d_6840);
      601..650: u9_2a9f(d_6D86^.Images[d_0296[X1, Y1].Tile - 600].Pixels[1], ScreenX, ScreenY + d_6840);
      651..700: u9_2a9f(d_6D8A^.Images[d_0296[X1, Y1].Tile - 650].Pixels[1], ScreenX, ScreenY + d_6840);
      701..750: u9_2a9f(d_6D8E^.Images[d_0296[X1, Y1].Tile - 700].Pixels[1], ScreenX, ScreenY + d_6840);
      751..800: u9_2a9f(d_6D92^.Images[d_0296[X1, Y1].Tile - 750].Pixels[1], ScreenX, ScreenY + d_6840);
    end;
    case d_0296[X1, Y1].Overlay of
      0: ;
      1..50: u9_0475(d_6D72^.Images[d_0296[X1, Y1].Overlay].Pixels[1], ScreenX, ScreenY + d_6840);
      100..150: u9_0475(d_6D76^.Images[d_0296[X1, Y1].Overlay - 100].Pixels[1], ScreenX, ScreenY + d_6840);
      179:
        if d_6840 = 16 then
          u9_0475(d_6D96^.Images[29].Pixels[1], ScreenX, ScreenY + d_6840)
        else
          u9_0475(d_6D96^.Images[30].Pixels[1], ScreenX, ScreenY + d_6840);
      151..200: u9_0475(d_6D96^.Images[d_0296[X1, Y1].Overlay - 150].Pixels[1], ScreenX, ScreenY + d_6840);
      201..250: u9_0475(d_6D9A^.Images[d_0296[X1, Y1].Overlay - 200].Pixels[1], ScreenX, ScreenY + d_6840);
      251..300: u9_0475(d_6DAA^.Images[d_0296[X1, Y1].Overlay - 250].Pixels[1], ScreenX, ScreenY + d_6840);
      301..350: u9_0475(d_6DA2^.Images[d_0296[X1, Y1].Overlay - 300].Pixels[1], ScreenX, ScreenY + d_6840);
      351..400: u9_0475(d_6DAE^.Images[d_0296[X1, Y1].Overlay - 350].Pixels[1], ScreenX, ScreenY + d_6840);
      401..450: u9_0475(d_6D7E^.Images[d_0296[X1, Y1].Overlay - 400].Pixels[1], ScreenX, ScreenY + d_6840);
      499:
        if d_6840 = 16 then
          u9_0475(d_6D82^.Images[49].Pixels[1], ScreenX, ScreenY + d_6840)
        else
          u9_0475(d_6D82^.Images[1].Pixels[1], ScreenX, ScreenY + d_6840);
      451..500: u9_0475(d_6D82^.Images[d_0296[X1, Y1].Overlay - 450].Pixels[1], ScreenX, ScreenY + d_6840);
      501..550: u9_0475(d_6D72^.Images[d_0296[X1, Y1].Overlay - 500].Pixels[1], ScreenX, ScreenY + d_6840);
      613:
        if d_6840 = 16 then
          u9_0475(d_6D86^.Images[13].Pixels[1], X0 shl 1, (Y0 shl 4) + d_6840)
        else
          u9_0475(d_6D86^.Images[17].Pixels[1], X0 shl 1, (Y0 shl 4) + d_6840);
      601..650: u9_0475(d_6D86^.Images[d_0296[X1, Y1].Overlay - 600].Pixels[1], ScreenX, ScreenY + d_6840);
      651..700: u9_0475(d_6D8A^.Images[d_0296[X1, Y1].Overlay - 650].Pixels[1], ScreenX, ScreenY + d_6840);
      701..750: u9_0475(d_6D8E^.Images[d_0296[X1, Y1].Overlay - 700].Pixels[1], ScreenX, ScreenY + d_6840);
      751..800: u9_0475(d_6D92^.Images[d_0296[X1, Y1].Overlay - 750].Pixels[1], ScreenX, ScreenY + d_6840);
    end;
    case d_0296[X1, Y1].Aux of
      0: ;
      1..50: u9_0475(d_6D72^.Images[d_0296[X1, Y1].Aux].Pixels[1], ScreenX, ScreenY + d_6840);
      100..150: u9_0475(d_6D76^.Images[d_0296[X1, Y1].Aux - 100].Pixels[1], ScreenX, ScreenY + d_6840);
      179:
        if d_6840 = 16 then
          u9_0475(d_6D96^.Images[29].Pixels[1], ScreenX, ScreenY + d_6840)
        else
          u9_0475(d_6D96^.Images[30].Pixels[1], ScreenX, ScreenY + d_6840);
      151..200: u9_0475(d_6D96^.Images[d_0296[X1, Y1].Aux - 150].Pixels[1], ScreenX, ScreenY + d_6840);
      201..250: u9_0475(d_6D9A^.Images[d_0296[X1, Y1].Aux - 200].Pixels[1], ScreenX, ScreenY + d_6840);
      251..300: u9_0475(d_6DAA^.Images[d_0296[X1, Y1].Aux - 250].Pixels[1], ScreenX, ScreenY + d_6840);
      301..350: u9_0475(d_6DA2^.Images[d_0296[X1, Y1].Aux - 300].Pixels[1], ScreenX, ScreenY + d_6840);
      351..400: u9_0475(d_6DAE^.Images[d_0296[X1, Y1].Aux - 350].Pixels[1], ScreenX, ScreenY + d_6840);
      401..450: u9_0475(d_6D7E^.Images[d_0296[X1, Y1].Aux - 400].Pixels[1], ScreenX, ScreenY + d_6840);
      499:
        if d_6840 = 16 then
          u9_0475(d_6D82^.Images[49].Pixels[1], ScreenX, ScreenY + d_6840)
        else
          u9_0475(d_6D82^.Images[1].Pixels[1], ScreenX, ScreenY + d_6840);
      451..500: u9_0475(d_6D82^.Images[d_0296[X1, Y1].Aux - 450].Pixels[1], ScreenX, ScreenY + d_6840);
      501..550: u9_0475(d_6D72^.Images[d_0296[X1, Y1].Aux - 500].Pixels[1], ScreenX, ScreenY + d_6840);
      613:
        if d_6840 = 16 then
          u9_0475(d_6D86^.Images[13].Pixels[1], X0 shl 1, (Y0 shl 4) + d_6840)
        else
          u9_0475(d_6D86^.Images[17].Pixels[1], X0 shl 1, (Y0 shl 4) + d_6840);
      601..602: u9_0475(d_6D86^.Images[d_0296[X1, Y1].Aux - 600].Pixels[1], ScreenX, ScreenY + d_6840);
      603:
        if d_6840 = 416 then
          u9_0475(d_6D86^.Images[d_0296[X1, Y1].Aux - 600].Pixels[1], ScreenX, ScreenY + d_6840);
      604..623: u9_0475(d_6D86^.Images[d_0296[X1, Y1].Aux - 600].Pixels[1], ScreenX, ScreenY + d_6840);
      624:
        if d_6840 = 416 then
          u9_0475(d_6D86^.Images[d_0296[X1, Y1].Aux - 600].Pixels[1], ScreenX, ScreenY + d_6840)
        else
          u9_0475(d_6D86^.Images[d_0296[X1, Y1].Aux - 582].Pixels[1], ScreenX, ScreenY + d_6840);
      625..650: u9_0475(d_6D86^.Images[d_0296[X1, Y1].Aux - 600].Pixels[1], ScreenX, ScreenY + d_6840);
      651..700: u9_0475(d_6D8A^.Images[d_0296[X1, Y1].Aux - 650].Pixels[1], ScreenX, ScreenY + d_6840);
      701..750: u9_0475(d_6D8E^.Images[d_0296[X1, Y1].Aux - 700].Pixels[1], ScreenX, ScreenY + d_6840);
      751..800: u9_0475(d_6D92^.Images[d_0296[X1, Y1].Aux - 750].Pixels[1], ScreenX, ScreenY + d_6840);
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u2_1185(X, Y: Integer);
var
  TileX, TileY: Integer;
begin
  TileX := X shr 4;
  TileY := Y shr 4;
  if d_0296[TileX + 1, TileY + 1].Tile = 2 then
    d_0296[TileX + 1, TileY + 1].Tile := d_681A;
  if d_0296[TileX + 1, TileY + 1].Tile = 5 then
    d_0296[TileX + 1, TileY + 1].Tile := d_681A + 1;
  if d_0296[TileX + 1, TileY + 1].Tile = 6 then
    d_0296[TileX + 1, TileY + 1].Tile := d_681A + 2;
  if d_0296[TileX + 1, TileY + 1].Tile = 7 then
    d_0296[TileX + 1, TileY + 1].Tile := d_681A + 3;
  if d_0296[TileX + 1, TileY + 1].Tile = 8 then
    d_0296[TileX + 1, TileY + 1].Tile := 667;
  case d_0296[TileX + 1, TileY + 1].Tile of
    1..50:
      u9_2a9f(d_6D72^.Images[d_0296[TileX + 1, TileY + 1].Tile].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    100..150:
      u9_2a9f(d_6D76^.Images[d_0296[TileX + 1, TileY + 1].Tile - 100].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    179:
      if d_6840 = 16 then
        u9_2a9f(d_6D96^.Images[29].Pixels[1], TileX * 2, TileY * 16 + d_6840)
      else
        u9_2a9f(d_6D96^.Images[30].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    151..200:
      u9_2a9f(d_6D96^.Images[d_0296[TileX + 1, TileY + 1].Tile - 150].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    201..250:
      u9_2a9f(d_6D9A^.Images[d_0296[TileX + 1, TileY + 1].Tile - 200].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    251..300:
      u9_2a9f(d_6DAA^.Images[d_0296[TileX + 1, TileY + 1].Tile - 250].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    301..350:
      u9_2a9f(d_6DA2^.Images[d_0296[TileX + 1, TileY + 1].Tile - 300].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    351..400:
      u9_2a9f(d_6DAE^.Images[d_0296[TileX + 1, TileY + 1].Tile - 350].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    401..450:
      u9_2a9f(d_6D7E^.Images[d_0296[TileX + 1, TileY + 1].Tile - 400].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    499:
      if d_6840 = 16 then
        u9_2a9f(d_6D82^.Images[49].Pixels[1], TileX * 2, TileY * 16 + d_6840)
      else
        u9_2a9f(d_6D82^.Images[1].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    451..500:
      u9_2a9f(d_6D82^.Images[d_0296[TileX + 1, TileY + 1].Tile - 450].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    501..550:
      u9_2a9f(d_6D72^.Images[d_0296[TileX + 1, TileY + 1].Tile - 500].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    613:
      if d_6840 = 16 then
        u9_2a9f(d_6D86^.Images[13].Pixels[1], TileX * 2, TileY * 16 + d_6840)
      else
        u9_2a9f(d_6D86^.Images[17].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    601..650:
      u9_2a9f(d_6D86^.Images[d_0296[TileX + 1, TileY + 1].Tile - 600].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    651..700:
      u9_2a9f(d_6D8A^.Images[d_0296[TileX + 1, TileY + 1].Tile - 650].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    701..750:
      u9_2a9f(d_6D8E^.Images[d_0296[TileX + 1, TileY + 1].Tile - 700].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    751..800:
      u9_2a9f(d_6D92^.Images[d_0296[TileX + 1, TileY + 1].Tile - 750].Pixels[1], TileX * 2, TileY * 16 + d_6840);
  end;
  if d_0296[TileX + 1, TileY + 1].Tile = d_681A then
    d_0296[TileX + 1, TileY + 1].Tile := 2;
  if d_0296[TileX + 1, TileY + 1].Tile = d_681A + 1 then
    d_0296[TileX + 1, TileY + 1].Tile := 5;
  if d_0296[TileX + 1, TileY + 1].Tile = d_681A + 2 then
    d_0296[TileX + 1, TileY + 1].Tile := 6;
  if d_0296[TileX + 1, TileY + 1].Tile = d_681A + 3 then
    d_0296[TileX + 1, TileY + 1].Tile := 7;
  if d_0296[TileX + 1, TileY + 1].Tile = 667 then
    d_0296[TileX + 1, TileY + 1].Tile := 8;
  case d_0296[TileX + 1, TileY + 1].Overlay of
    0: ;
    1..50:
      u9_0475(d_6D72^.Images[d_0296[TileX + 1, TileY + 1].Overlay].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    100..150:
      u9_0475(d_6D76^.Images[d_0296[TileX + 1, TileY + 1].Overlay - 100].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    179:
      if d_6840 = 16 then
        u9_0475(d_6D96^.Images[29].Pixels[1], TileX * 2, TileY * 16 + d_6840)
      else
        u9_0475(d_6D96^.Images[30].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    151..200:
      u9_0475(d_6D96^.Images[d_0296[TileX + 1, TileY + 1].Overlay - 150].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    201..250:
      u9_0475(d_6D9A^.Images[d_0296[TileX + 1, TileY + 1].Overlay - 200].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    251..300:
      u9_0475(d_6DAA^.Images[d_0296[TileX + 1, TileY + 1].Overlay - 250].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    301..350:
      u9_0475(d_6DA2^.Images[d_0296[TileX + 1, TileY + 1].Overlay - 300].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    351..400:
      u9_0475(d_6DAE^.Images[d_0296[TileX + 1, TileY + 1].Overlay - 350].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    401..450:
      u9_0475(d_6D7E^.Images[d_0296[TileX + 1, TileY + 1].Overlay - 400].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    499:
      if d_6840 = 16 then
        u9_0475(d_6D82^.Images[49].Pixels[1], TileX * 2, TileY * 16 + d_6840)
      else
        u9_0475(d_6D82^.Images[1].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    451..500:
      u9_0475(d_6D82^.Images[d_0296[TileX + 1, TileY + 1].Overlay - 450].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    501..550:
      u9_0475(d_6D72^.Images[d_0296[TileX + 1, TileY + 1].Overlay - 500].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    613:
      if d_6840 = 16 then
        u9_0475(d_6D86^.Images[13].Pixels[1], TileX * 2, TileY * 16 + d_6840)
      else
        u9_0475(d_6D86^.Images[17].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    601..650:
      u9_0475(d_6D86^.Images[d_0296[TileX + 1, TileY + 1].Overlay - 600].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    651..700:
      u9_0475(d_6D8A^.Images[d_0296[TileX + 1, TileY + 1].Overlay - 650].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    701..750:
      u9_0475(d_6D8E^.Images[d_0296[TileX + 1, TileY + 1].Overlay - 700].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    751..800:
      u9_0475(d_6D92^.Images[d_0296[TileX + 1, TileY + 1].Overlay - 750].Pixels[1], TileX * 2, TileY * 16 + d_6840);
  end;
  case d_0296[TileX + 1, TileY + 1].Aux of
    0: ;
    1..50:
      u9_0475(d_6D72^.Images[d_0296[TileX + 1, TileY + 1].Aux].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    100..150:
      u9_0475(d_6D76^.Images[d_0296[TileX + 1, TileY + 1].Aux - 100].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    179:
      if d_6840 = 16 then
        u9_0475(d_6D96^.Images[29].Pixels[1], TileX * 2, TileY * 16 + d_6840)
      else
        u9_0475(d_6D96^.Images[30].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    151..200:
      u9_0475(d_6D96^.Images[d_0296[TileX + 1, TileY + 1].Aux - 150].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    201..250:
      u9_0475(d_6D9A^.Images[d_0296[TileX + 1, TileY + 1].Aux - 200].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    251..300:
      u9_0475(d_6DAA^.Images[d_0296[TileX + 1, TileY + 1].Aux - 250].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    301..350:
      u9_0475(d_6DA2^.Images[d_0296[TileX + 1, TileY + 1].Aux - 300].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    351..400:
      u9_0475(d_6DAE^.Images[d_0296[TileX + 1, TileY + 1].Aux - 350].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    401..450:
      u9_0475(d_6D7E^.Images[d_0296[TileX + 1, TileY + 1].Aux - 400].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    499:
      if d_6840 = 16 then
        u9_0475(d_6D82^.Images[49].Pixels[1], TileX * 2, TileY * 16 + d_6840)
      else
        u9_0475(d_6D82^.Images[1].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    451..500:
      u9_0475(d_6D82^.Images[d_0296[TileX + 1, TileY + 1].Aux - 450].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    501..550:
      u9_0475(d_6D72^.Images[d_0296[TileX + 1, TileY + 1].Aux - 500].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    613:
      if d_6840 = 16 then
        u9_0475(d_6D86^.Images[13].Pixels[1], TileX * 2, TileY * 16 + d_6840)
      else
        u9_0475(d_6D86^.Images[17].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    601..650:
      u9_0475(d_6D86^.Images[d_0296[TileX + 1, TileY + 1].Aux - 600].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    651..700:
      u9_0475(d_6D8A^.Images[d_0296[TileX + 1, TileY + 1].Aux - 650].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    701..750:
      u9_0475(d_6D8E^.Images[d_0296[TileX + 1, TileY + 1].Aux - 700].Pixels[1], TileX * 2, TileY * 16 + d_6840);
    751..800:
      u9_0475(d_6D92^.Images[d_0296[TileX + 1, TileY + 1].Aux - 750].Pixels[1], TileX * 2, TileY * 16 + d_6840);
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u2_2530(X, Y: Integer);
var
  X0, Y0: Integer;
begin
  X0 := X shr 4;
  Y0 := Y shr 4;
  if (X0 >= 0) and (X0 <= 39) and (Y0 >= 0) then
  begin
    case d_0296[X0 + 1, Y0 + 1].Aux of
      0: ;
      1..50:
        u9_0475(d_6D72^.Images[d_0296[X0 + 1, Y0 + 1].Aux].Pixels[1],
          X0 shl 1, (Y0 shl 4) + d_6840);
      179:
        if d_6840 = 16 then
          u9_0475(d_6D96^.Images[29].Pixels[1], X0 shl 1, (Y0 shl 4) + d_6840)
        else
          u9_0475(d_6D96^.Images[30].Pixels[1], X0 shl 1, (Y0 shl 4) + d_6840);
      100..150:
        u9_0475(d_6D76^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 100].Pixels[1],
          X0 shl 1, (Y0 shl 4) + d_6840);
      151..200:
        u9_0475(d_6D96^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 150].Pixels[1],
          X0 shl 1, (Y0 shl 4) + d_6840);
      201..250:
        u9_0475(d_6D9A^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 200].Pixels[1],
          X0 shl 1, (Y0 shl 4) + d_6840);
      251..300:
        u9_0475(d_6DAA^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 250].Pixels[1],
          X0 shl 1, (Y0 shl 4) + d_6840);
      301..350:
        u9_0475(d_6DA2^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 300].Pixels[1],
          X0 shl 1, (Y0 shl 4) + d_6840);
      351..400:
        u9_0475(d_6DAE^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 350].Pixels[1],
          X0 shl 1, (Y0 shl 4) + d_6840);
      401..450:
        u9_0475(d_6D7E^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 400].Pixels[1],
          X0 shl 1, (Y0 shl 4) + d_6840);
      499:
        if d_6840 = 16 then
          u9_0475(d_6D82^.Images[49].Pixels[1], X0 shl 1, (Y0 shl 4) + d_6840)
        else
          u9_0475(d_6D82^.Images[1].Pixels[1], X0 shl 1, (Y0 shl 4) + d_6840);
      451..500:
        u9_0475(d_6D82^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 450].Pixels[1],
          X0 shl 1, (Y0 shl 4) + d_6840);
      613:
        if d_6840 = 16 then
          u9_0475(d_6D86^.Images[13].Pixels[1], X0 shl 1, (Y0 shl 4) + d_6840)
        else
          u9_0475(d_6D86^.Images[17].Pixels[1], X0 shl 1, (Y0 shl 4) + d_6840);
      601..602:
        u9_0475(d_6D86^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 600].Pixels[1],
          X0 shl 1, (Y0 shl 4) + d_6840);
      603:
        if d_6840 = 416 then
          u9_0475(d_6D86^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 600].Pixels[1],
            X0 shl 1, (Y0 shl 4) + d_6840);
      604..623:
        u9_0475(d_6D86^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 600].Pixels[1],
          X0 shl 1, (Y0 shl 4) + d_6840);
      624:
        if d_6840 = 416 then
          u9_0475(d_6D86^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 600].Pixels[1],
            X0 shl 1, (Y0 shl 4) + d_6840)
        else
          u9_0475(d_6D86^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 582].Pixels[1],
            X0 shl 1, (Y0 shl 4) + d_6840);
      625..650:
        u9_0475(d_6D86^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 600].Pixels[1],
          X0 shl 1, (Y0 shl 4) + d_6840);
      651..700:
        u9_0475(d_6D8A^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 650].Pixels[1],
          X0 shl 1, (Y0 shl 4) + d_6840);
      701..750:
        u9_0475(d_6D8E^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 700].Pixels[1],
          X0 shl 1, (Y0 shl 4) + d_6840);
      751..800:
        u9_0475(d_6D92^.Images[d_0296[X0 + 1, Y0 + 1].Aux - 750].Pixels[1],
          X0 shl 1, (Y0 shl 4) + d_6840);
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u2_2c6e(X, Y, Tile, A, B: Integer; C, D, Foreground: Byte);
begin
  if Foreground <> 0 then
  begin
    d_0296[X + 1, Y + 1].Aux := B;
    d_6840 := $0010;
    u2_2530(X shl 4, Y shl 4);
    d_6840 := $01A0;
    u2_2530(X shl 4, Y shl 4);
    d_6840 := $0010;
  end
  else
  begin
    d_0296[X + 1, Y + 1].Tile := Tile;
    d_0296[X + 1, Y + 1].Overlay := A;
    d_0296[X + 1, Y + 1].Aux := B;
    d_0296[X + 1, Y + 1].Solid := C;
    d_0296[X + 1, Y + 1].Special := D;
    d_6840 := $0010;
    if Y = 24 then
      u2_1185(X shl 4, Y shl 4)
    else
      u2_0000(X shl 4, Y shl 4);
    u2_2530(X shl 4, Y shl 4);
    d_6840 := $01A0;
    if Y = 24 then
      u2_1185(X shl 4, Y shl 4)
    else
      u2_0000(X shl 4, Y shl 4);
    u2_2530(X shl 4, Y shl 4);
    d_6840 := $0010;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u2_2e88(X, Y: Integer; Symbol: String);
var
  I, Count: Integer;
  Foreground: Byte;
begin
  d_6842 := 0;
  Foreground := 0;
  Count := 0;
  for I := 2 to 17 do
    if d_69BA[I] = 1 then Inc(Count);
  if Count = 15 then d_6842 := 1;
  if d_681C = 1 then
  begin
    if Symbol = 'A' then
      u2_2c6e(X, Y, 501, 0, 0, 0, 0, Foreground);
    if Symbol = 'B' then
      u2_2c6e(X, Y, 502, 0, 0, 1, 0, Foreground);
    if Symbol = 'C' then
      u2_2c6e(X, Y, 503, 0, 0, 1, 0, Foreground);
    if Symbol = 'D' then
      u2_2c6e(X, Y, 504, 0, 0, 1, 0, Foreground);
    if Symbol = 'E' then
      u2_2c6e(X, Y, 505, 0, 0, 1, 0, Foreground);
    if Symbol = 'F' then
      u2_2c6e(X, Y, 506, 0, 0, 1, 0, Foreground);
    if Symbol = 'G' then
      u2_2c6e(X, Y, 507, 0, 0, 1, 0, Foreground);
    if Symbol = 'H' then
      u2_2c6e(X, Y, d_681A, 0, 0, 0, 0, Foreground);
    if Symbol = 'I' then
      u2_2c6e(X, Y, d_681A, 0, 0, 0, 0, Foreground);
    if Symbol = 'J' then
      u2_2c6e(X, Y, 661, 0, 0, 0, 0, Foreground);
    if Symbol = 'K' then
      u2_2c6e(X, Y, d_681A, 0, 0, 0, 0, Foreground);
    if Symbol = 'L' then
      u2_2c6e(X, Y, d_681A, 0, 0, 0, 0, Foreground);
    if Symbol = 'M' then
    begin
      if d_69BA[d_6834 + 2] <> 0 then
        u2_2c6e(X, Y, d_6834 + 2, 0, 517, 0, 0, Foreground)
      else
        u2_2c6e(X, Y, d_6834 + 2, 0, 513, 0, 0, Foreground);
    end;
    if Symbol = 'N' then
    begin
      if d_69BA[d_6834 + 2] <> 0 then
        u2_2c6e(X, Y, d_6834 + 2, 0, 518, 0, 0, Foreground)
      else
        u2_2c6e(X, Y, d_6834 + 2, 0, 514, 0, 0, Foreground);
      Inc(d_6834);
    end;
    if Symbol = 'O' then
    begin
      if d_69BA[d_6834 + 2] <> 0 then
        u2_2c6e(X, Y, d_6834 + 2, 0, 519, 0, 0, Foreground)
      else
        u2_2c6e(X, Y, d_6834 + 2, 0, 515, 0, 0, Foreground);
      Inc(d_6834);
    end;
    if Symbol = 'P' then
    begin
      if d_69BA[d_6834 + 2] <> 0 then
        u2_2c6e(X, Y, d_6834 + 2, 0, 520, 0, 0, Foreground)
      else
        u2_2c6e(X, Y, d_6834 + 2, 0, 516, 0, 0, Foreground);
      Inc(d_6834);
    end;
    if Symbol = 'Q' then
      u2_2c6e(X, Y, 517, 0, 0, 0, 0, Foreground);
    if Symbol = 'R' then
      u2_2c6e(X, Y, 518, 0, 0, 0, 0, Foreground);
    if Symbol = 'S' then
      u2_2c6e(X, Y, 519, 0, 0, 0, 0, Foreground);
    if Symbol = 'T' then
      u2_2c6e(X, Y, 520, 0, 0, 0, 0, Foreground);
    if Symbol = 'U' then
      u2_2c6e(X, Y, 521, 0, 0, 1, 0, Foreground);
    if Symbol = 'V' then
      u2_2c6e(X, Y, 522, 0, 0, 0, 0, Foreground);
    if Symbol = 'W' then
      u2_2c6e(X, Y, 523, 0, 0, 0, 0, Foreground);
    if Symbol = 'X' then
      u2_2c6e(X, Y, 524, 0, 0, 0, 0, Foreground);
    if Symbol = '0' then
      u2_2c6e(X, Y, 525, 0, 0, 0, 0, Foreground);
    if Symbol = 'Z' then
      u2_2c6e(X, Y, 526, 0, 0, 0, 0, Foreground);
    if Symbol = 'a' then
      u2_2c6e(X, Y, 527, 0, 0, 1, 0, Foreground);
    if Symbol = 'b' then
      u2_2c6e(X, Y, 528, 0, 0, 0, 0, Foreground);
    if Symbol = 'c' then
      u2_2c6e(X, Y, 529, 0, 0, 0, 0, Foreground);
    if Symbol = 'd' then
      u2_2c6e(X, Y, 530, 0, 0, 0, 0, Foreground);
    if Symbol = 'e' then
      u2_2c6e(X, Y, 531, 0, 0, 0, 0, Foreground);
    if Symbol = 'f' then
      u2_2c6e(X, Y, 532, 0, 0, 1, 0, Foreground);
    if Symbol = 'g' then
      u2_2c6e(X, Y, 533, 0, 0, 1, 0, Foreground);
    if Symbol = 'h' then
      u2_2c6e(X, Y, 534, 0, 0, 0, 0, Foreground);
    if Symbol = 'i' then
      u2_2c6e(X, Y, 535, 0, 0, 0, 0, Foreground);
    if Symbol = 'j' then
      u2_2c6e(X, Y, 536, 0, 0, 0, 0, Foreground);
    if Symbol = 'k' then
      u2_2c6e(X, Y, 537, 0, 0, 0, 0, Foreground);
    if Symbol = 'l' then
    begin
      if d_6842 = 0 then
        u2_2c6e(X, Y, 508, 0, 0, 1, 0, Foreground)
      else
        u2_2c6e(X, Y, d_681A, 0, 0, 0, 0, Foreground);
    end;
    if Symbol = 'm' then
      u2_2c6e(X, Y, d_681A, 0, 665, 0, 0, Foreground);
    if Symbol = 'n' then
      u2_2c6e(X, Y, d_681A, 0, 666, 0, 0, Foreground);
    if Symbol = 'o' then
      u2_2c6e(X, Y, d_681A, 671, 0, 0, 1, Foreground);
    if Symbol = 'p' then
      u2_2c6e(X, Y, d_681A, 672, 0, 0, 1, Foreground);
    if Symbol = 'q' then
      u2_2c6e(X, Y, d_681A, 673, 0, 0, 1, Foreground);
    if Symbol = 'r' then
      u2_2c6e(X, Y, d_681A, 674, 0, 0, 1, Foreground);
    if Symbol = 's' then
      u2_2c6e(X, Y, 683, 0, 0, 0, 0, Foreground);
    if Symbol = 't' then
      u2_2c6e(X, Y, d_681A, 0, 684, 0, 0, Foreground);
    if Symbol = 'u' then
      u2_2c6e(X, Y, d_681A, 0, 685, 0, 0, Foreground);
    if Symbol = 'v' then
      u2_2c6e(X, Y, d_681A, 0, 686, 0, 0, Foreground);
    if Symbol = 'x' then
      u2_2c6e(X, Y, d_681A, 0, 688, 0, 0, Foreground);
    if Symbol = 'y' then
      u2_2c6e(X, Y, d_681A, 0, 689, 0, 0, Foreground);
    if Symbol = 'z' then
      u2_2c6e(X, Y, 690, 0, 0, 0, 0, Foreground);
    if Symbol = 'w' then
      u2_2c6e(X, Y, d_681A, 0, 687, 0, 0, Foreground);
    if Symbol = 'w' then
    begin
      u2_2c6e(X, Y - 1, 2, 0, 179, 1, 0, Foreground);
      u2_2c6e(X, Y, 2, 0, 183, 0, 0, Foreground);
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u2_3a91(X, Y: Integer; Symbol: String; Foreground: Byte);
begin
  if Symbol = #174 then { 3ABC }
  begin { 3ABC }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 3ADC }
    Inc(d_682E); { 3ADF }
    u9_19f9(PByteArray(d_6DA6)^[1923], (X * 16), ((Y * 16) + 16)); { 3B02 }
    u9_19f9(PByteArray(d_6DA6)^[1923], (X * 16), ((Y * 16) + 416)); { 3B26 }
    u9_19f9(PByteArray(d_6DA6)^[1283], ((X + 1) * 16), ((Y * 16) + 16)); { 3B4B }
    u9_19f9(PByteArray(d_6DA6)^[1283], ((X + 1) * 16), ((Y * 16) + 416)); { 3B70 }
    d_34EC[d_682E].State := 0; { 3B7F }
    d_34EC[d_682E].Sprite := 851; { 3B8B }
    d_34EC[d_682E].X := (X * 16); { 3BA1 }
    d_34EC[d_682E].Y := (Y * 16); { 3BB5 }
    d_34EC[d_682E].OldX := (X * 16); { 3BC9 }
    d_34EC[d_682E].OldY := (Y * 16); { 3BDD }
    if Random(2) > 0 then { 3BEC }
    begin { 3BEC }
      d_34EC[d_682E].DX := 1; { 3BF6 }
    end { 3BFC }
    else { 3BFC }
    begin { 3BFE }
      d_34EC[d_682E].DX := -1; { 3C06 }
    end; { 3C0C }
    d_34EC[d_682E].DY := 0; { 3C16 }
    if d_34EC[d_682E].DX = 1 then { 3C27 }
    begin { 3C27 }
      d_34EC[d_682E].Frame := 1; { 3C31 }
    end { 3C37 }
    else { 3C37 }
    begin { 3C39 }
      d_34EC[d_682E].Frame := 41; { 3C41 }
    end; { 3C47 }
    d_34EC[d_682E].Speed := 2; { 3C4F }
    d_34EC[d_682E].Tick := 0; { 3C5F }
    d_34EC[d_682E].Limit := 0; { 3C6D }
    d_34EC[d_682E].Aux1 := 3; { 3C79 }
    d_34EC[d_682E].Kind := 42; { 3C87 }
    d_34EC[d_682E].Inactive := 0; { 3C95 }
    d_34EC[d_682E].Marked := 0; { 3CA2 }
  end; { 3CA7 }
  if Symbol = '8' then { 3CB7 }
  begin { 3CB7 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 3CD7 }
    Inc(d_682E); { 3CDA }
    u9_19f9(PByteArray(d_6DAE)^[3], (X * 16), ((Y * 16) + 16)); { 3CFD }
    u9_19f9(PByteArray(d_6DAE)^[3], (X * 16), ((Y * 16) + 416)); { 3D21 }
    d_34EC[d_682E].State := 0; { 3D30 }
    d_34EC[d_682E].Sprite := 351; { 3D3C }
    d_34EC[d_682E].X := (X * 16); { 3D52 }
    d_34EC[d_682E].Y := (Y * 16); { 3D66 }
    d_34EC[d_682E].OldX := (X * 16); { 3D7A }
    d_34EC[d_682E].OldY := (Y * 16); { 3D8E }
    if Random(2) > 0 then { 3D9D }
    begin { 3D9D }
      d_34EC[d_682E].DX := 1; { 3DA7 }
    end { 3DAD }
    else { 3DAD }
    begin { 3DAF }
      d_34EC[d_682E].DX := -1; { 3DB7 }
    end; { 3DBD }
    d_34EC[d_682E].DY := 0; { 3DC7 }
    if d_34EC[d_682E].DX = 1 then { 3DD8 }
    begin { 3DD8 }
      d_34EC[d_682E].Frame := 1; { 3DE2 }
    end { 3DE8 }
    else { 3DE8 }
    begin { 3DEA }
      d_34EC[d_682E].Frame := 21; { 3DF2 }
    end; { 3DF8 }
    d_34EC[d_682E].Speed := 1; { 3E00 }
    d_34EC[d_682E].Tick := 0; { 3E10 }
    d_34EC[d_682E].Limit := 0; { 3E1E }
    d_34EC[d_682E].Kind := 1; { 3E2A }
    d_34EC[d_682E].Inactive := 0; { 3E38 }
    d_34EC[d_682E].Marked := 0; { 3E45 }
  end; { 3E4A }
  if Symbol = '9' then { 3E5A }
  begin { 3E5A }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 3E7A }
    Inc(d_682E); { 3E7D }
    u9_19f9(PByteArray(d_6DAE)^[1283], (X * 16), ((Y * 16) + 16)); { 3EA0 }
    u9_19f9(PByteArray(d_6DAE)^[1283], (X * 16), ((Y * 16) + 416)); { 3EC4 }
    d_34EC[d_682E].State := 0; { 3ED3 }
    d_34EC[d_682E].Sprite := 359; { 3EDF }
    d_34EC[d_682E].X := (X * 16); { 3EF5 }
    d_34EC[d_682E].Y := (Y * 16); { 3F09 }
    d_34EC[d_682E].OldX := (X * 16); { 3F1D }
    d_34EC[d_682E].OldY := (Y * 16); { 3F31 }
    if Random(2) > 0 then { 3F40 }
    begin { 3F40 }
      d_34EC[d_682E].DX := 1; { 3F4A }
    end { 3F50 }
    else { 3F50 }
    begin { 3F52 }
      d_34EC[d_682E].DX := -1; { 3F5A }
    end; { 3F60 }
    d_34EC[d_682E].DY := 0; { 3F6A }
    if d_34EC[d_682E].DX = 1 then { 3F7B }
    begin { 3F7B }
      d_34EC[d_682E].Frame := 1; { 3F85 }
    end { 3F8B }
    else { 3F8B }
    begin { 3F8D }
      d_34EC[d_682E].Frame := 21; { 3F95 }
    end; { 3F9B }
    d_34EC[d_682E].Speed := 1; { 3FA3 }
    d_34EC[d_682E].Tick := 0; { 3FB3 }
    d_34EC[d_682E].Kind := 2; { 3FBF }
    d_34EC[d_682E].Inactive := 0; { 3FCD }
    d_34EC[d_682E].Marked := 0; { 3FDA }
  end; { 3FDF }
  if Symbol = '0' then { 3FEF }
  begin { 3FEF }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 400F }
    Inc(d_682E); { 4012 }
    u9_19f9(PByteArray(d_6DAE)^[2563], (X * 16), ((Y * 16) + 16)); { 4035 }
    u9_19f9(PByteArray(d_6DAE)^[2563], (X * 16), ((Y * 16) + 416)); { 4059 }
    d_34EC[d_682E].State := 0; { 4068 }
    d_34EC[d_682E].Sprite := 367; { 4074 }
    d_34EC[d_682E].X := (X * 16); { 408A }
    d_34EC[d_682E].Y := (Y * 16); { 409E }
    d_34EC[d_682E].OldX := (X * 16); { 40B2 }
    d_34EC[d_682E].OldY := (Y * 16); { 40C6 }
    if Random(2) > 0 then { 40D5 }
    begin { 40D5 }
      d_34EC[d_682E].DX := 1; { 40DF }
    end { 40E5 }
    else { 40E5 }
    begin { 40E7 }
      d_34EC[d_682E].DX := -1; { 40EF }
    end; { 40F5 }
    d_34EC[d_682E].DY := 0; { 40FF }
    if d_34EC[d_682E].DX = 1 then { 4110 }
    begin { 4110 }
      d_34EC[d_682E].Frame := 1; { 411A }
    end { 4120 }
    else { 4120 }
    begin { 4122 }
      d_34EC[d_682E].Frame := 21; { 412A }
    end; { 4130 }
    d_34EC[d_682E].Speed := 2; { 4138 }
    d_34EC[d_682E].Tick := 0; { 4148 }
    d_34EC[d_682E].Kind := 3; { 4154 }
    d_34EC[d_682E].Inactive := 0; { 4162 }
    d_34EC[d_682E].Marked := 0; { 416F }
  end; { 4174 }
  if Symbol = 'g' then { 4184 }
  begin { 4184 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 41A4 }
    Inc(d_682E); { 41A7 }
    u9_19f9(PByteArray(d_6DAE)^[3843], (X * 16), ((Y * 16) + 16)); { 41CA }
    u9_19f9(PByteArray(d_6DAE)^[3843], (X * 16), ((Y * 16) + 416)); { 41EE }
    d_34EC[d_682E].State := 0; { 41FD }
    d_34EC[d_682E].Sprite := 375; { 4209 }
    d_34EC[d_682E].X := (X * 16); { 421F }
    d_34EC[d_682E].Y := (Y * 16); { 4233 }
    d_34EC[d_682E].OldX := (X * 16); { 4247 }
    d_34EC[d_682E].OldY := (Y * 16); { 425B }
    if Random(2) > 0 then { 426A }
    begin { 426A }
      d_34EC[d_682E].DX := 1; { 4274 }
    end { 427A }
    else { 427A }
    begin { 427C }
      d_34EC[d_682E].DX := -1; { 4284 }
    end; { 428A }
    d_34EC[d_682E].DY := 0; { 4294 }
    if d_34EC[d_682E].DX = 1 then { 42A5 }
    begin { 42A5 }
      d_34EC[d_682E].Frame := 1; { 42AF }
    end { 42B5 }
    else { 42B5 }
    begin { 42B7 }
      d_34EC[d_682E].Frame := 21; { 42BF }
    end; { 42C5 }
    d_34EC[d_682E].Speed := 2; { 42CD }
    d_34EC[d_682E].Tick := (Random(50) + 50); { 42E7 }
    d_34EC[d_682E].Limit := 0; { 42F5 }
    d_34EC[d_682E].Kind := 4; { 4301 }
    d_34EC[d_682E].Inactive := 0; { 430F }
    d_34EC[d_682E].Marked := 0; { 431C }
  end; { 4321 }
  if Symbol = 'G' then { 4331 }
  begin { 4331 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 4351 }
    Inc(d_682E); { 4354 }
    u9_19f9(PByteArray(d_6DAE)^[5123], (X * 16), ((Y * 16) + 16)); { 4377 }
    u9_19f9(PByteArray(d_6DAE)^[5123], (X * 16), ((Y * 16) + 416)); { 439B }
    d_34EC[d_682E].State := 0; { 43AA }
    d_34EC[d_682E].Sprite := 383; { 43B6 }
    d_34EC[d_682E].X := (X * 16); { 43CC }
    d_34EC[d_682E].Y := (Y * 16); { 43E0 }
    d_34EC[d_682E].OldX := (X * 16); { 43F4 }
    d_34EC[d_682E].OldY := (Y * 16); { 4408 }
    if Random(2) > 0 then { 4417 }
    begin { 4417 }
      d_34EC[d_682E].DX := 1; { 4421 }
    end { 4427 }
    else { 4427 }
    begin { 4429 }
      d_34EC[d_682E].DX := -1; { 4431 }
    end; { 4437 }
    d_34EC[d_682E].DY := 0; { 4441 }
    if d_34EC[d_682E].DX = 1 then { 4452 }
    begin { 4452 }
      d_34EC[d_682E].Frame := 1; { 445C }
    end { 4462 }
    else { 4462 }
    begin { 4464 }
      d_34EC[d_682E].Frame := 21; { 446C }
    end; { 4472 }
    d_34EC[d_682E].Speed := 2; { 447A }
    d_34EC[d_682E].Tick := (Random(20) + 30); { 4494 }
    d_34EC[d_682E].Limit := 0; { 44A2 }
    d_34EC[d_682E].Kind := 5; { 44AE }
    d_34EC[d_682E].Inactive := 0; { 44BC }
    d_34EC[d_682E].Marked := 0; { 44C9 }
  end; { 44CE }
  if Symbol = 'V' then { 44DE }
  begin { 44DE }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 44FE }
    Inc(d_682E); { 4501 }
    u9_19f9(PByteArray(d_6D9E)^[3], (X * 16), (((Y * 16) + 16) - 16)); { 4527 }
    u9_19f9(PByteArray(d_6D9E)^[3], (X * 16), (((Y * 16) + 416) - 16)); { 454E }
    u9_19f9(PByteArray(d_6D9E)^[643], (X * 16), ((Y * 16) + 16)); { 4572 }
    u9_19f9(PByteArray(d_6D9E)^[643], (X * 16), ((Y * 16) + 416)); { 4596 }
    d_34EC[d_682E].State := 0; { 45A5 }
    d_34EC[d_682E].Sprite := 801; { 45B1 }
    d_34EC[d_682E].X := (X * 16); { 45C7 }
    d_34EC[d_682E].Y := (Y * 16); { 45DB }
    d_34EC[d_682E].OldX := (X * 16); { 45EF }
    d_34EC[d_682E].OldY := (Y * 16); { 4603 }
    if Random(2) > 0 then { 4612 }
    begin { 4612 }
      d_34EC[d_682E].DX := 1; { 461C }
    end { 4622 }
    else { 4622 }
    begin { 4624 }
      d_34EC[d_682E].DX := -1; { 462C }
    end; { 4632 }
    d_34EC[d_682E].DY := 0; { 463C }
    if d_34EC[d_682E].DX = 1 then { 464D }
    begin { 464D }
      d_34EC[d_682E].Frame := 1; { 4657 }
    end { 465D }
    else { 465D }
    begin { 465F }
      d_34EC[d_682E].Frame := 41; { 4667 }
    end; { 466D }
    d_34EC[d_682E].Speed := 2; { 4675 }
    d_34EC[d_682E].Tick := (Random(20) + 30); { 468F }
    d_34EC[d_682E].Limit := 0; { 469D }
    d_34EC[d_682E].Aux1 := 3; { 46A9 }
    d_34EC[d_682E].Kind := 30; { 46B7 }
    d_34EC[d_682E].Inactive := 0; { 46C5 }
    d_34EC[d_682E].Marked := 0; { 46D2 }
  end; { 46D7 }
  if Symbol = 'X' then { 46E7 }
  begin { 46E7 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 4707 }
    Inc(d_682E); { 470A }
    u9_19f9(PByteArray(d_6D9E)^[2563], (X * 16), (((Y * 16) + 16) - 16)); { 4730 }
    u9_19f9(PByteArray(d_6D9E)^[2563], (X * 16), (((Y * 16) + 416) - 16)); { 4757 }
    u9_19f9(PByteArray(d_6D9E)^[3203], (X * 16), ((Y * 16) + 16)); { 477B }
    u9_19f9(PByteArray(d_6D9E)^[3203], (X * 16), ((Y * 16) + 416)); { 479F }
    d_34EC[d_682E].State := 0; { 47AE }
    d_34EC[d_682E].Sprite := 817; { 47BA }
    d_34EC[d_682E].X := (X * 16); { 47D0 }
    d_34EC[d_682E].Y := (Y * 16); { 47E4 }
    d_34EC[d_682E].OldX := (X * 16); { 47F8 }
    d_34EC[d_682E].OldY := (Y * 16); { 480C }
    if Random(2) > 0 then { 481B }
    begin { 481B }
      d_34EC[d_682E].DX := 1; { 4825 }
    end { 482B }
    else { 482B }
    begin { 482D }
      d_34EC[d_682E].DX := -1; { 4835 }
    end; { 483B }
    d_34EC[d_682E].DY := 0; { 4845 }
    if d_34EC[d_682E].DX = 1 then { 4856 }
    begin { 4856 }
      d_34EC[d_682E].Frame := 61; { 4860 }
    end { 4866 }
    else { 4866 }
    begin { 4868 }
      d_34EC[d_682E].Frame := 1; { 4870 }
    end; { 4876 }
    d_34EC[d_682E].Speed := 2; { 487E }
    d_34EC[d_682E].Tick := 60; { 488C }
    d_34EC[d_682E].Limit := 0; { 489C }
    d_34EC[d_682E].Aux1 := 3; { 48A8 }
    d_34EC[d_682E].Aux2 := (Random(20) + 60); { 48C2 }
    d_34EC[d_682E].Kind := 31; { 48CE }
    d_34EC[d_682E].Inactive := 0; { 48DC }
    d_34EC[d_682E].Marked := 0; { 48E9 }
  end; { 48EE }
  if Symbol = '#' then { 48FE }
  begin { 48FE }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 491E }
    Inc(d_682E); { 4921 }
    u9_19f9(PByteArray(d_6D96)^[3], (X * 16), ((Y * 16) + 16)); { 4944 }
    u9_19f9(PByteArray(d_6D96)^[3], (X * 16), ((Y * 16) + 416)); { 4968 }
    d_34EC[d_682E].State := 0; { 4977 }
    d_34EC[d_682E].Sprite := 151; { 4983 }
    d_34EC[d_682E].X := (X * 16); { 4999 }
    d_34EC[d_682E].Y := (Y * 16); { 49AD }
    d_34EC[d_682E].OldX := (X * 16); { 49C1 }
    d_34EC[d_682E].OldY := (Y * 16); { 49D5 }
    d_34EC[d_682E].DX := 1; { 49E1 }
    d_34EC[d_682E].DY := 0; { 49F1 }
    d_34EC[d_682E].Frame := 1; { 49FD }
    d_34EC[d_682E].Speed := 0; { 4A0D }
    d_34EC[d_682E].Tick := 3; { 4A19 }
    d_34EC[d_682E].Kind := 32; { 4A27 }
    d_34EC[d_682E].Inactive := 0; { 4A35 }
    d_34EC[d_682E].Marked := 0; { 4A42 }
  end; { 4A47 }
  if Symbol = 'c' then { 4A57 }
  begin { 4A57 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 4A77 }
    Inc(d_682E); { 4A7A }
    u9_19f9(PByteArray(d_6D9E)^[6403], (X * 16), (((Y * 16) + 16) - 16)); { 4AA0 }
    u9_19f9(PByteArray(d_6D9E)^[6403], (X * 16), (((Y * 16) + 416) - 16)); { 4AC7 }
    u9_19f9(PByteArray(d_6D9E)^[6403], (X * 16), ((Y * 16) + 16)); { 4AEB }
    u9_19f9(PByteArray(d_6D9E)^[6403], (X * 16), ((Y * 16) + 416)); { 4B0F }
    d_34EC[d_682E].State := 0; { 4B1E }
    d_34EC[d_682E].Sprite := 837; { 4B2A }
    d_34EC[d_682E].X := (X * 16); { 4B40 }
    d_34EC[d_682E].Y := (Y * 16); { 4B54 }
    d_34EC[d_682E].OldX := (X * 16); { 4B68 }
    d_34EC[d_682E].OldY := (Y * 16); { 4B7C }
    if Random(2) > 0 then { 4B8B }
    begin { 4B8B }
      d_34EC[d_682E].DX := 1; { 4B95 }
    end { 4B9B }
    else { 4B9B }
    begin { 4B9D }
      d_34EC[d_682E].DX := -1; { 4BA5 }
    end; { 4BAB }
    d_34EC[d_682E].DY := 0; { 4BB5 }
    if d_34EC[d_682E].DX = 1 then { 4BC6 }
    begin { 4BC6 }
      d_34EC[d_682E].Frame := 1; { 4BD0 }
    end { 4BD6 }
    else { 4BD6 }
    begin { 4BD8 }
      d_34EC[d_682E].Frame := 21; { 4BE0 }
    end; { 4BE6 }
    d_34EC[d_682E].Speed := 2; { 4BEE }
    d_34EC[d_682E].Tick := (Random(20) + 30); { 4C08 }
    d_34EC[d_682E].Limit := 0; { 4C16 }
    d_34EC[d_682E].Aux1 := 3; { 4C22 }
    d_34EC[d_682E].Kind := 33; { 4C30 }
    d_34EC[d_682E].Inactive := 0; { 4C3E }
    d_34EC[d_682E].Marked := 0; { 4C4B }
  end; { 4C50 }
  if Symbol = 'e' then { 4C60 }
  begin { 4C60 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 4C80 }
    Inc(d_682E); { 4C83 }
    u9_19f9(PByteArray(d_6D76)^[2563], (X * 16), ((Y * 16) + 16)); { 4CA6 }
    u9_19f9(PByteArray(d_6D76)^[2563], (X * 16), ((Y * 16) + 416)); { 4CCA }
    d_34EC[d_682E].State := 0; { 4CD9 }
    d_34EC[d_682E].Sprite := 117; { 4CE5 }
    d_34EC[d_682E].X := (X * 16); { 4CFB }
    d_34EC[d_682E].Y := (Y * 16); { 4D0F }
    d_34EC[d_682E].OldX := (X * 16); { 4D23 }
    d_34EC[d_682E].OldY := (Y * 16); { 4D37 }
    if Random(2) > 0 then { 4D46 }
    begin { 4D46 }
      d_34EC[d_682E].DX := 1; { 4D50 }
    end { 4D56 }
    else { 4D56 }
    begin { 4D58 }
      d_34EC[d_682E].DX := -1; { 4D60 }
    end; { 4D66 }
    d_34EC[d_682E].DY := 0; { 4D70 }
    if d_34EC[d_682E].DX = 1 then { 4D81 }
    begin { 4D81 }
      d_34EC[d_682E].Frame := 1; { 4D8B }
    end { 4D91 }
    else { 4D91 }
    begin { 4D93 }
      d_34EC[d_682E].Frame := 21; { 4D9B }
    end; { 4DA1 }
    d_34EC[d_682E].Speed := 2; { 4DA9 }
    d_34EC[d_682E].Tick := 0; { 4DB9 }
    d_34EC[d_682E].Limit := 0; { 4DC7 }
    d_34EC[d_682E].Aux1 := 3; { 4DD3 }
    d_34EC[d_682E].Kind := 34; { 4DE1 }
    d_34EC[d_682E].Inactive := 0; { 4DEF }
    d_34EC[d_682E].Marked := 0; { 4DFC }
  end; { 4E01 }
  if Symbol = 'u' then { 4E11 }
  begin { 4E11 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 4E31 }
    Inc(d_682E); { 4E34 }
    u9_19f9(PByteArray(d_6D76)^[1283], (X * 16), ((Y * 16) + 16)); { 4E57 }
    u9_19f9(PByteArray(d_6D76)^[1283], (X * 16), ((Y * 16) + 416)); { 4E7B }
    d_34EC[d_682E].State := 0; { 4E8A }
    d_34EC[d_682E].Sprite := 109; { 4E96 }
    d_34EC[d_682E].X := (X * 16); { 4EAC }
    d_34EC[d_682E].Y := (Y * 16); { 4EC0 }
    d_34EC[d_682E].OldX := (X * 16); { 4ED4 }
    d_34EC[d_682E].OldY := (Y * 16); { 4EE8 }
    d_34EC[d_682E].DX := 1; { 4EF4 }
    d_34EC[d_682E].DY := 0; { 4F04 }
    d_34EC[d_682E].Frame := 1; { 4F10 }
    d_34EC[d_682E].Speed := 0; { 4F20 }
    d_34EC[d_682E].Tick := 0; { 4F2E }
    d_34EC[d_682E].Limit := 0; { 4F3C }
    d_34EC[d_682E].Aux1 := 3; { 4F48 }
    d_34EC[d_682E].Kind := 35; { 4F56 }
    d_34EC[d_682E].Inactive := 0; { 4F64 }
    d_34EC[d_682E].Marked := 0; { 4F71 }
  end; { 4F76 }
  if Symbol = 'v' then { 4F86 }
  begin { 4F86 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 4FA6 }
    Inc(d_682E); { 4FA9 }
    u9_19f9(PByteArray(d_6D76)^[1923], (X * 16), ((Y * 16) + 16)); { 4FCC }
    u9_19f9(PByteArray(d_6D76)^[1923], (X * 16), ((Y * 16) + 416)); { 4FF0 }
    d_34EC[d_682E].State := 0; { 4FFF }
    d_34EC[d_682E].Sprite := 113; { 500B }
    d_34EC[d_682E].X := (X * 16); { 5021 }
    d_34EC[d_682E].Y := (Y * 16); { 5035 }
    d_34EC[d_682E].OldX := (X * 16); { 5049 }
    d_34EC[d_682E].OldY := (Y * 16); { 505D }
    d_34EC[d_682E].DX := 1; { 5069 }
    d_34EC[d_682E].DY := 0; { 5079 }
    d_34EC[d_682E].Frame := 1; { 5085 }
    d_34EC[d_682E].Speed := 0; { 5095 }
    d_34EC[d_682E].Tick := 0; { 50A3 }
    d_34EC[d_682E].Limit := 10; { 50AF }
    d_34EC[d_682E].Aux1 := 10; { 50BD }
    d_34EC[d_682E].Kind := 36; { 50CB }
    d_34EC[d_682E].Inactive := 0; { 50D9 }
    d_34EC[d_682E].Marked := 0; { 50E6 }
  end; { 50EB }
  if Symbol = 'n' then { 50FB }
  begin { 50FB }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 511B }
    Inc(d_682E); { 511E }
    u9_19f9(PByteArray(d_6D76)^[5123], (X * 16), ((Y * 16) + 16)); { 5141 }
    u9_19f9(PByteArray(d_6D76)^[5123], (X * 16), ((Y * 16) + 416)); { 5165 }
    d_34EC[d_682E].State := 0; { 5174 }
    d_34EC[d_682E].Sprite := 133; { 5180 }
    d_34EC[d_682E].X := (X * 16); { 5196 }
    d_34EC[d_682E].Y := (Y * 16); { 51AA }
    d_34EC[d_682E].OldX := (X * 16); { 51BE }
    d_34EC[d_682E].OldY := (Y * 16); { 51D2 }
    if Random(2) > 0 then { 51E1 }
    begin { 51E1 }
      d_34EC[d_682E].DX := 1; { 51EB }
    end { 51F1 }
    else { 51F1 }
    begin { 51F3 }
      d_34EC[d_682E].DX := -1; { 51FB }
    end; { 5201 }
    d_34EC[d_682E].DY := 0; { 520B }
    d_34EC[d_682E].Frame := 1; { 5217 }
    d_34EC[d_682E].Speed := 2; { 5225 }
    d_34EC[d_682E].Tick := (Random(20) + 30); { 523F }
    d_34EC[d_682E].Limit := 0; { 524D }
    d_34EC[d_682E].Aux1 := 3; { 5259 }
    d_34EC[d_682E].Aux2 := (Random(50) + 100); { 5273 }
    d_34EC[d_682E].Kind := 38; { 527F }
    d_34EC[d_682E].Inactive := 0; { 528D }
    d_34EC[d_682E].Marked := 0; { 529A }
  end; { 529F }
  if Symbol = '$' then { 52AF }
  begin { 52AF }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 52CF }
    Inc(d_682E); { 52D2 }
    u9_19f9(PByteArray(d_6D76)^[3], (X * 16), (((Y * 16) + 16) - 16)); { 52F8 }
    u9_19f9(PByteArray(d_6D76)^[3], (X * 16), (((Y * 16) + 416) - 16)); { 531F }
    u9_19f9(PByteArray(d_6D76)^[643], (X * 16), ((Y * 16) + 16)); { 5343 }
    u9_19f9(PByteArray(d_6D76)^[643], (X * 16), ((Y * 16) + 416)); { 5367 }
    d_34EC[d_682E].State := 0; { 5376 }
    d_34EC[d_682E].Sprite := 101; { 5382 }
    d_34EC[d_682E].X := (X * 16); { 5398 }
    d_34EC[d_682E].Y := (Y * 16); { 53AC }
    d_34EC[d_682E].OldX := (X * 16); { 53C0 }
    d_34EC[d_682E].OldY := (Y * 16); { 53D4 }
    if Random(2) > 0 then { 53E3 }
    begin { 53E3 }
      d_34EC[d_682E].DX := 1; { 53ED }
    end { 53F3 }
    else { 53F3 }
    begin { 53F5 }
      d_34EC[d_682E].DX := -1; { 53FD }
    end; { 5403 }
    d_34EC[d_682E].DY := 0; { 540D }
    if d_34EC[d_682E].DX = 1 then { 541E }
    begin { 541E }
      d_34EC[d_682E].Frame := 201; { 5428 }
    end { 542E }
    else { 542E }
    begin { 5430 }
      d_34EC[d_682E].Frame := 1; { 5438 }
    end; { 543E }
    d_34EC[d_682E].Speed := 2; { 5446 }
    d_34EC[d_682E].Tick := 60; { 5454 }
    d_34EC[d_682E].Limit := 0; { 5464 }
    d_34EC[d_682E].Aux1 := 3; { 5470 }
    d_34EC[d_682E].Aux2 := (Random(20) + 60); { 548A }
    d_34EC[d_682E].Kind := 39; { 5496 }
    d_34EC[d_682E].Inactive := 0; { 54A4 }
    d_34EC[d_682E].Marked := 0; { 54B1 }
  end; { 54B6 }
  if Symbol = '[' then { 54C6 }
  begin { 54C6 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 54E6 }
    Inc(d_682E); { 54E9 }
    d_34EC[d_682E].State := 0; { 54F7 }
    d_34EC[d_682E].Sprite := 435; { 5503 }
    d_34EC[d_682E].X := (X * 16); { 5519 }
    d_34EC[d_682E].Y := (Y * 16); { 552D }
    d_34EC[d_682E].OldX := (X * 16); { 5541 }
    d_34EC[d_682E].OldY := (Y * 16); { 5555 }
    d_34EC[d_682E].DX := 0; { 5563 }
    d_34EC[d_682E].DY := 0; { 5571 }
    d_34EC[d_682E].Frame := 1; { 557D }
    d_34EC[d_682E].Speed := 0; { 558D }
    d_34EC[d_682E].Tick := 0; { 559B }
    d_34EC[d_682E].Limit := 0; { 55A9 }
    d_34EC[d_682E].Aux1 := 0; { 55B7 }
    d_34EC[d_682E].Aux2 := 0; { 55C5 }
    d_34EC[d_682E].Kind := 41; { 55D1 }
    d_34EC[d_682E].Inactive := 0; { 55DF }
    d_34EC[d_682E].Marked := 0; { 55EC }
  end; { 55F1 }
  if Symbol = #127 then { 5601 }
  begin { 5601 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 5621 }
    Inc(d_682E); { 5624 }
    u9_19f9(PByteArray(d_6D86)^[1283], (X * 16), ((Y * 16) + 16)); { 5647 }
    u9_19f9(PByteArray(d_6D86)^[1283], (X * 16), ((Y * 16) + 416)); { 566B }
    d_34EC[d_682E].State := 0; { 567A }
    d_34EC[d_682E].Sprite := 609; { 5686 }
    d_34EC[d_682E].X := (X * 16); { 569C }
    d_34EC[d_682E].Y := (Y * 16); { 56B0 }
    d_34EC[d_682E].OldX := (X * 16); { 56C4 }
    d_34EC[d_682E].OldY := (Y * 16); { 56D8 }
    if Random(2) > 0 then { 56E7 }
    begin { 56E7 }
      d_34EC[d_682E].DX := 1; { 56F1 }
    end { 56F7 }
    else { 56F7 }
    begin { 56F9 }
      d_34EC[d_682E].DX := -1; { 5701 }
    end; { 5707 }
    d_34EC[d_682E].DY := 0; { 5711 }
    d_34EC[d_682E].Frame := 1; { 571D }
    d_34EC[d_682E].Speed := 2; { 572B }
    d_34EC[d_682E].Tick := 2; { 5739 }
    d_34EC[d_682E].Limit := 11; { 5747 }
    d_34EC[d_682E].Kind := 6; { 5755 }
    d_34EC[d_682E].Inactive := 0; { 5763 }
    d_34EC[d_682E].Marked := 0; { 5770 }
  end; { 5775 }
  if Symbol = 'R' then { 5785 }
  begin { 5785 }
    u2_2c6e(X, Y, 2, 464, 0, 0, 0, Foreground); { 57A6 }
    Inc(d_682E); { 57A9 }
    u9_19f9(PByteArray(d_6D82)^[2083], (X * 16), ((Y * 16) + 16)); { 57CC }
    u9_19f9(PByteArray(d_6D82)^[2083], (X * 16), ((Y * 16) + 416)); { 57F0 }
    d_34EC[d_682E].State := 0; { 57FF }
    d_34EC[d_682E].Sprite := 464; { 580B }
    d_34EC[d_682E].X := (X * 16); { 5821 }
    d_34EC[d_682E].Y := (Y * 16); { 5835 }
    d_34EC[d_682E].OldX := (X * 16); { 5849 }
    d_34EC[d_682E].OldY := (Y * 16); { 585D }
    d_34EC[d_682E].DX := 1; { 5869 }
    d_34EC[d_682E].DY := 0; { 5879 }
    d_34EC[d_682E].Frame := 1; { 5885 }
    d_34EC[d_682E].Speed := 0; { 5895 }
    d_34EC[d_682E].Tick := (Random(20) + 55); { 58AD }
    d_34EC[d_682E].Limit := 0; { 58BB }
    d_34EC[d_682E].Kind := 10; { 58C7 }
    d_34EC[d_682E].Inactive := 0; { 58D5 }
    d_34EC[d_682E].Marked := 0; { 58E2 }
  end; { 58E7 }
  if Symbol = 'Q' then { 58F7 }
  begin { 58F7 }
    u2_2c6e(X, Y, 2, 465, 0, 0, 0, Foreground); { 5918 }
    Inc(d_682E); { 591B }
    u9_19f9(PByteArray(d_6D82)^[2243], (X * 16), ((Y * 16) + 16)); { 593E }
    u9_19f9(PByteArray(d_6D82)^[2243], (X * 16), ((Y * 16) + 416)); { 5962 }
    d_34EC[d_682E].State := 0; { 5971 }
    d_34EC[d_682E].Sprite := 465; { 597D }
    d_34EC[d_682E].X := (X * 16); { 5993 }
    d_34EC[d_682E].Y := (Y * 16); { 59A7 }
    d_34EC[d_682E].OldX := (X * 16); { 59BB }
    d_34EC[d_682E].OldY := (Y * 16); { 59CF }
    d_34EC[d_682E].DX := 1; { 59DB }
    d_34EC[d_682E].DY := 0; { 59EB }
    d_34EC[d_682E].Frame := 1; { 59F7 }
    d_34EC[d_682E].Speed := 0; { 5A07 }
    d_34EC[d_682E].Tick := (Random(20) + 55); { 5A1F }
    d_34EC[d_682E].Limit := 0; { 5A2D }
    d_34EC[d_682E].Kind := 11; { 5A39 }
    d_34EC[d_682E].Inactive := 0; { 5A47 }
    d_34EC[d_682E].Marked := 0; { 5A54 }
  end; { 5A59 }
  if Symbol = '<' then { 5A69 }
  begin { 5A69 }
    u2_2c6e(X, Y, 2, 0, 487, 1, 0, Foreground); { 5A8A }
    Inc(d_682E); { 5A8D }
    u9_19f9(PByteArray(d_6D82)^[5763], (X * 16), ((Y * 16) + 16)); { 5AB0 }
    u9_19f9(PByteArray(d_6D82)^[5763], (X * 16), ((Y * 16) + 416)); { 5AD4 }
    d_34EC[d_682E].State := 0; { 5AE3 }
    d_34EC[d_682E].Sprite := 487; { 5AEF }
    d_34EC[d_682E].X := (X * 16); { 5B05 }
    d_34EC[d_682E].Y := (Y * 16); { 5B19 }
    d_34EC[d_682E].OldX := (X * 16); { 5B2D }
    d_34EC[d_682E].OldY := (Y * 16); { 5B41 }
    d_34EC[d_682E].DX := 1; { 5B4D }
    d_34EC[d_682E].DY := 0; { 5B5D }
    d_34EC[d_682E].Frame := 1; { 5B69 }
    d_34EC[d_682E].Speed := 0; { 5B79 }
    d_34EC[d_682E].Tick := (Random(20) + 55); { 5B91 }
    d_34EC[d_682E].Limit := 0; { 5B9F }
    d_34EC[d_682E].Kind := 12; { 5BAB }
    d_34EC[d_682E].Inactive := 0; { 5BB9 }
    d_34EC[d_682E].Marked := 0; { 5BC6 }
  end; { 5BCB }
  if Symbol = '=' then { 5BDB }
  begin { 5BDB }
    u2_2c6e(X, Y, 2, 0, 491, 1, 0, Foreground); { 5BFC }
    Inc(d_682E); { 5BFF }
    u9_19f9(PByteArray(d_6D82)^[6403], (X * 16), ((Y * 16) + 16)); { 5C22 }
    u9_19f9(PByteArray(d_6D82)^[6403], (X * 16), ((Y * 16) + 416)); { 5C46 }
    d_34EC[d_682E].State := 0; { 5C55 }
    d_34EC[d_682E].Sprite := 491; { 5C61 }
    d_34EC[d_682E].X := (X * 16); { 5C77 }
    d_34EC[d_682E].Y := (Y * 16); { 5C8B }
    d_34EC[d_682E].OldX := (X * 16); { 5C9F }
    d_34EC[d_682E].OldY := (Y * 16); { 5CB3 }
    d_34EC[d_682E].DX := 1; { 5CBF }
    d_34EC[d_682E].DY := 0; { 5CCF }
    d_34EC[d_682E].Frame := 1; { 5CDB }
    d_34EC[d_682E].Speed := 0; { 5CEB }
    d_34EC[d_682E].Tick := (Random(20) + 55); { 5D03 }
    d_34EC[d_682E].Limit := 0; { 5D11 }
    d_34EC[d_682E].Kind := 13; { 5D1D }
    d_34EC[d_682E].Inactive := 0; { 5D2B }
    d_34EC[d_682E].Marked := 0; { 5D38 }
  end; { 5D3D }
  if Symbol = ';' then { 5D4D }
  begin { 5D4D }
    u2_2c6e(X, (Y - 2), 2, 0, 428, 1, 0, 0); { 5D71 }
    u2_2c6e(X, (Y - 1), 2, 0, 0, 0, 0, Foreground); { 5D91 }
    u2_2c6e(X, Y, 2, 0, 427, 1, 0, 0); { 5DAF }
    Inc(d_682E); { 5DB2 }
    u9_19f9(PByteArray(d_6D7E)^[4323], (X * 16), (((Y - 2) * 16) + 16)); { 5DD8 }
    u9_19f9(PByteArray(d_6D7E)^[4323], (X * 16), (((Y - 2) * 16) + 416)); { 5DFF }
    u9_19f9(PByteArray(d_6D7E)^[4163], (X * 16), ((Y * 16) + 16)); { 5E23 }
    u9_19f9(PByteArray(d_6D7E)^[4163], (X * 16), ((Y * 16) + 416)); { 5E47 }
    d_34EC[d_682E].State := 0; { 5E56 }
    d_34EC[d_682E].Sprite := 435; { 5E62 }
    d_34EC[d_682E].X := (X * 16); { 5E78 }
    d_34EC[d_682E].Y := ((Y - 1) * 16); { 5E8D }
    d_34EC[d_682E].OldX := (X * 16); { 5EA1 }
    d_34EC[d_682E].OldY := ((Y - 1) * 16); { 5EB6 }
    d_34EC[d_682E].DX := 1; { 5EC2 }
    d_34EC[d_682E].DY := 0; { 5ED2 }
    d_34EC[d_682E].Frame := 1; { 5EDE }
    d_34EC[d_682E].Speed := 0; { 5EEE }
    d_34EC[d_682E].Tick := 30; { 5EFA }
    d_34EC[d_682E].Limit := Random(30); { 5F11 }
    d_34EC[d_682E].Kind := 15; { 5F1D }
    d_34EC[d_682E].Inactive := 0; { 5F2B }
    d_34EC[d_682E].Marked := 0; { 5F38 }
  end; { 5F3D }
  if Symbol = '>' then { 5F4D }
  begin { 5F4D }
    u2_2c6e((X - 2), Y, 2, 0, 433, 1, 0, Foreground); { 5F72 }
    u2_2c6e((X - 1), Y, 2, 0, 0, 0, 0, Foreground); { 5F92 }
    u2_2c6e(X, Y, 2, 0, 434, 1, 0, Foreground); { 5FB1 }
    Inc(d_682E); { 5FB4 }
    u9_19f9(PByteArray(d_6D7E)^[5123], ((X - 2) * 16), ((Y * 16) + 16)); { 5FDA }
    u9_19f9(PByteArray(d_6D7E)^[5123], ((X - 2) * 16), ((Y * 16) + 416)); { 6001 }
    u9_19f9(PByteArray(d_6D7E)^[5283], (X * 16), ((Y * 16) + 16)); { 6025 }
    u9_19f9(PByteArray(d_6D7E)^[5283], (X * 16), ((Y * 16) + 416)); { 6049 }
    d_34EC[d_682E].State := 0; { 6058 }
    d_34EC[d_682E].Sprite := 435; { 6064 }
    d_34EC[d_682E].X := ((X - 1) * 16); { 607B }
    d_34EC[d_682E].Y := (Y * 16); { 608F }
    d_34EC[d_682E].OldX := ((X - 1) * 16); { 60A4 }
    d_34EC[d_682E].OldY := (Y * 16); { 60B8 }
    d_34EC[d_682E].DX := 1; { 60C4 }
    d_34EC[d_682E].DY := 0; { 60D4 }
    d_34EC[d_682E].Frame := 1; { 60E0 }
    d_34EC[d_682E].Speed := 0; { 60F0 }
    d_34EC[d_682E].Tick := 30; { 60FC }
    d_34EC[d_682E].Limit := Random(30); { 6113 }
    d_34EC[d_682E].Kind := 16; { 611F }
    d_34EC[d_682E].Inactive := 0; { 612D }
    d_34EC[d_682E].Marked := 0; { 613A }
  end; { 613F }
  if Symbol = '?' then { 614F }
  begin { 614F }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 616F }
    Inc(d_682E); { 6172 }
    d_34EC[d_682E].State := 0; { 6180 }
    d_34EC[d_682E].Sprite := 435; { 618C }
    d_34EC[d_682E].X := (X * 16); { 61A2 }
    d_34EC[d_682E].Y := (Y * 16); { 61B6 }
    d_34EC[d_682E].OldX := (X * 16); { 61CA }
    d_34EC[d_682E].OldY := (Y * 16); { 61DE }
    d_34EC[d_682E].DX := 1; { 61EA }
    d_34EC[d_682E].DY := 0; { 61FA }
    d_34EC[d_682E].Frame := 1; { 6206 }
    d_34EC[d_682E].Speed := 0; { 6216 }
    d_34EC[d_682E].Tick := 30; { 6222 }
    d_34EC[d_682E].Limit := Random(30); { 6239 }
    d_34EC[d_682E].Kind := 17; { 6245 }
    d_34EC[d_682E].Inactive := 0; { 6253 }
    d_34EC[d_682E].Marked := 0; { 6260 }
  end; { 6265 }
  if Symbol = 'A' then { 6275 }
  begin { 6275 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 6295 }
    Inc(d_682E); { 6298 }
    d_34EC[d_682E].State := 0; { 62A6 }
    d_34EC[d_682E].Sprite := 435; { 62B2 }
    d_34EC[d_682E].X := (X * 16); { 62C8 }
    d_34EC[d_682E].Y := (Y * 16); { 62DC }
    d_34EC[d_682E].OldX := (X * 16); { 62F0 }
    d_34EC[d_682E].OldY := (Y * 16); { 6304 }
    d_34EC[d_682E].DX := 1; { 6310 }
    d_34EC[d_682E].DY := 0; { 6320 }
    d_34EC[d_682E].Frame := 1; { 632C }
    d_34EC[d_682E].Speed := 0; { 633C }
    d_34EC[d_682E].Tick := 30; { 6348 }
    d_34EC[d_682E].Limit := Random(30); { 635F }
    d_34EC[d_682E].Kind := 18; { 636B }
    d_34EC[d_682E].Inactive := 0; { 6379 }
    d_34EC[d_682E].Marked := 0; { 6386 }
  end; { 638B }
  if Symbol = '@' then { 639B }
  begin { 639B }
    u2_2c6e(X, Y, 2, 0, 302, 0, 0, Foreground); { 63BC }
    Inc(d_682E); { 63BF }
    d_34EC[d_682E].State := 0; { 63CD }
    d_34EC[d_682E].Sprite := 305; { 63D9 }
    d_34EC[d_682E].X := (X * 16); { 63EF }
    d_34EC[d_682E].Y := ((Y - 1) * 16); { 6404 }
    d_34EC[d_682E].OldX := (X * 16); { 6418 }
    d_34EC[d_682E].OldY := ((Y - 1) * 16); { 642D }
    d_34EC[d_682E].DX := 0; { 643B }
    d_34EC[d_682E].DY := 0; { 6449 }
    d_34EC[d_682E].Frame := (Random(18) + 1); { 645F }
    d_34EC[d_682E].Speed := 0; { 646D }
    d_34EC[d_682E].Tick := 0; { 647B }
    d_34EC[d_682E].Limit := 5; { 6487 }
    d_34EC[d_682E].Kind := 43; { 6495 }
    d_34EC[d_682E].Inactive := 0; { 64A3 }
    d_34EC[d_682E].Marked := 0; { 64B0 }
  end; { 64B5 }
  if Symbol = #212 then { 64C5 }
  begin { 64C5 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 64E5 }
    Inc(d_682E); { 64E8 }
    d_34EC[d_682E].State := 0; { 64F6 }
    d_34EC[d_682E].Sprite := 309; { 6502 }
    d_34EC[d_682E].X := (X * 16); { 6518 }
    d_34EC[d_682E].Y := (Y * 16); { 652C }
    d_34EC[d_682E].OldX := (X * 16); { 6540 }
    d_34EC[d_682E].OldY := (Y * 16); { 6554 }
    d_34EC[d_682E].DX := 0; { 6562 }
    d_34EC[d_682E].DY := 0; { 6570 }
    d_34EC[d_682E].Frame := 1; { 657C }
    d_34EC[d_682E].Speed := 0; { 658C }
    d_34EC[d_682E].Tick := 0; { 659A }
    d_34EC[d_682E].Limit := 2; { 65A6 }
    d_34EC[d_682E].Kind := 44; { 65B4 }
    d_34EC[d_682E].Inactive := 0; { 65C2 }
    d_34EC[d_682E].Marked := 0; { 65CF }
  end; { 65D4 }
  if Symbol = 'x' then { 65E4 }
  begin { 65E4 }
    u2_2c6e(X, Y, 2, 0, 0, 0, 0, Foreground); { 6604 }
    Inc(d_682E); { 6607 }
    d_34EC[d_682E].State := 0; { 6615 }
    d_34EC[d_682E].Sprite := 259; { 6621 }
    d_34EC[d_682E].X := (X * 16); { 6637 }
    d_34EC[d_682E].Y := (Y * 16); { 664B }
    d_34EC[d_682E].OldX := (X * 16); { 665F }
    d_34EC[d_682E].OldY := (Y * 16); { 6673 }
    d_34EC[d_682E].DX := 0; { 6681 }
    d_34EC[d_682E].DY := 0; { 668F }
    d_34EC[d_682E].Frame := 1; { 669B }
    d_34EC[d_682E].Speed := 0; { 66AB }
    d_34EC[d_682E].Tick := 0; { 66B9 }
    d_34EC[d_682E].Limit := 2; { 66C5 }
    d_34EC[d_682E].Kind := 44; { 66D3 }
    d_34EC[d_682E].Inactive := 0; { 66E1 }
    d_34EC[d_682E].Marked := 0; { 66EE }
  end; { 66F3 }
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u2_68a9(rowIndex: Integer; row: TLevelRow);
var
  col: Integer;
  symbol: string;
  savedCol, savedRow: Integer;
  overlay: Boolean;
begin
  if row[1] <> '*' then
  begin
    overlay := False;
    for col := 1 to 40 do
    begin
      d_0296[col, rowIndex + 1].Tile := 0;
      d_0296[col, rowIndex + 1].Overlay := 0;
      d_0296[col, rowIndex + 1].Aux := 0;
      d_0296[col, rowIndex + 1].Solid := 0;
      d_0296[col, rowIndex + 1].Special := 0;
    end;
  end
  else
    overlay := True;
  for col := 0 to 39 do
  begin
    { 697F } MemW[0:1052] := MemW[0:1050];
    { 6993 } symbol := row[(col + 1)];
    { 69B7 } if symbol = ' ' then
    begin
      { 69C9 } if not overlay then
      begin
        { 69D0 } u2_2c6e(col, rowIndex, 2, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
    end;
    { 69EF } if d_681C > 1 then
    begin
      { 69F9 } if symbol = '1' then
      begin
        { 6A0B } u2_2c6e(col, rowIndex, 1, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 6A2A } if symbol = '2' then
      begin
        { 6A3C } u2_2c6e(col, rowIndex, 3, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 6A5B } if symbol = '3' then
      begin
        { 6A6D } u2_2c6e(col, rowIndex, 4, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 6A8C } if symbol = '5' then
      begin
        { 6A9E } u2_2c6e(col, rowIndex, 5, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6ABD } if symbol = '6' then
      begin
        { 6ACF } u2_2c6e(col, rowIndex, 6, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6AEE } if symbol = '7' then
      begin
        { 6B00 } u2_2c6e(col, rowIndex, 7, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6B1F } if symbol = #30 then
      begin
        { 6B31 } u2_2c6e(col, rowIndex, 8, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6B50 } if symbol = 'w' then
      begin
        { 6B62 } u2_2c6e(col, (rowIndex - 1), 2, 0, 179, Ord(True), Ord(False), Ord(overlay));
        { 6B84 } u2_2c6e(col, rowIndex, 2, 0, 183, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6BA4 } if symbol = #1 then
      begin
        { 6BB6 } u2_2c6e(col, rowIndex, 2, 0, 619, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6BD6 } if symbol = #2 then
      begin
        { 6BE8 } u2_2c6e(col, rowIndex, 2, 161, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6C08 } if symbol = #3 then
      begin
        { 6C1A } u2_2c6e(col, rowIndex, 2, 162, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6C3A } if symbol = #4 then
      begin
        { 6C4C } u2_2c6e(col, rowIndex, 2, 155, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6C6C } if symbol = #6 then
      begin
        { 6C7E } u2_2c6e(col, rowIndex, 2, 158, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6C9E } if symbol = #5 then
      begin
        { 6CB0 } u2_2c6e((col - 1), rowIndex, 156, 0, 0, Ord(False), Ord(True), Ord(overlay));
        { 6CD1 } u2_2c6e(col, rowIndex, 157, 0, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 6CF0 } if symbol = #7 then
      begin
        { 6D02 } u2_2c6e(col, rowIndex, 2, 174, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6D22 } if symbol = #8 then
      begin
        { 6D34 } u2_2c6e((col - 1), rowIndex, 2, 181, 0, Ord(False), Ord(True), Ord(overlay));
        { 6D56 } u2_2c6e(col, rowIndex, 2, 182, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 6D76 } if symbol = #12 then
      begin
        { 6D88 } u2_2c6e((col - 1), rowIndex, 2, 185, 0, Ord(False), Ord(True), Ord(overlay));
        { 6DAA } u2_2c6e(col, rowIndex, 2, 186, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 6DCA } if symbol = #11 then
      begin
        { 6DDC } u2_2c6e(col, rowIndex, 2, 178, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 6DFC } if symbol = #14 then
      begin
        { 6E0E } u2_2c6e(col, rowIndex, 2, 733, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6E2E } if symbol = #15 then
      begin
        { 6E40 } u2_2c6e(col, rowIndex, 2, 734, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6E60 } if symbol = #16 then
      begin
        { 6E72 } u2_2c6e(col, rowIndex, 2, 735, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6E92 } if symbol = #17 then
      begin
        { 6EA4 } u2_2c6e(col, rowIndex, 2, 737, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6EC4 } if symbol = #18 then
      begin
        { 6ED6 } u2_2c6e(col, rowIndex, 2, 741, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6EF6 } if symbol = #19 then
      begin
        { 6F08 } u2_2c6e(col, rowIndex, 2, 743, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6F28 } if symbol = #20 then
      begin
        { 6F3A } u2_2c6e(col, (rowIndex - 1), 2, 745, 0, Ord(False), Ord(False), Ord(overlay));
        { 6F5C } u2_2c6e(col, rowIndex, 2, 749, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6F7C } if symbol = #21 then
      begin
        { 6F8E } u2_2c6e(col, rowIndex, 2, 746, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6FAE } if symbol = #22 then
      begin
        { 6FC0 } u2_2c6e(col, rowIndex, 2, 750, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 6FE0 } if symbol = #23 then
      begin
        { 6FF2 } u2_2c6e(col, rowIndex, 2, 677, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7012 } if symbol = #24 then
      begin
        { 7024 } u2_2c6e(col, rowIndex, 2, 678, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7044 } if symbol = #25 then
      begin
        { 7056 } u2_2c6e(col, (rowIndex - 1), 2, 251, 0, Ord(False), Ord(True), Ord(overlay));
        { 7078 } u2_2c6e(col, rowIndex, 2, 255, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7098 } if symbol = #27 then
      begin
        { 70AD } u2_2c6e((col - 1), (rowIndex - 1), 2, 252, 0, Ord(False), Ord(True), Ord(overlay));
        { 70D1 } u2_2c6e(col, (rowIndex - 1), 2, 253, 0, Ord(False), Ord(True), Ord(overlay));
        { 70F3 } u2_2c6e((col - 1), rowIndex, 2, 256, 0, Ord(False), Ord(False), Ord(overlay));
        { 7115 } u2_2c6e(col, rowIndex, 2, 257, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7135 } if symbol = #28 then
      begin
        { 7147 } u2_2c6e(col, (rowIndex - 1), 2, 254, 0, Ord(False), Ord(True), Ord(overlay));
        { 7169 } u2_2c6e(col, rowIndex, 2, 258, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7189 } if symbol = '^' then
      begin
        { 719B } u2_2c6e(col, rowIndex, 2, 0, 314, Ord(False), Ord(False), Ord(overlay));
      end;
      { 71BB } if symbol = 'K' then
      begin
        { 71CD } u2_2c6e(col, rowIndex, 2, 0, 606, Ord(False), Ord(False), Ord(overlay));
      end;
      { 71ED } if symbol = 'I' then
      begin
        { 71FF } u2_2c6e(col, rowIndex, d_681A, 0, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 721E } if symbol = #211 then
      begin
        { 7230 } u2_2c6e(col, rowIndex, d_681A, 0, -1, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7250 } if symbol = 'r' then
      begin
        { 7262 } u2_2c6e(col, rowIndex, 2, 0, 607, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7282 } if symbol = 's' then
      begin
        { 7294 } u2_2c6e(col, rowIndex, 2, 0, 301, Ord(False), Ord(False), Ord(overlay));
      end;
      { 72B4 } if symbol = 'N' then
      begin
        { 72C6 } u2_2c6e(col, rowIndex, 2, 0, 313, Ord(False), Ord(False), Ord(overlay));
      end;
      { 72E6 } if symbol = 'T' then
      begin
        { 72F8 } u2_2c6e(col, rowIndex, 2, 0, 316, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7318 } if symbol = 'W' then
      begin
        { 732A } u2_2c6e(col, rowIndex, 2, 0, 618, Ord(False), Ord(False), Ord(overlay));
      end;
      { 734A } if symbol = '\' then
      begin
        { 735C } u2_2c6e(col, rowIndex, 2, 0, 620, Ord(False), Ord(False), Ord(overlay));
      end;
      { 737C } if symbol = ']' then
      begin
        { 738E } u2_2c6e(col, rowIndex, 2, 0, 629, Ord(False), Ord(False), Ord(overlay));
      end;
      { 73AE } if symbol = 'd' then
      begin
        { 73C0 } u2_2c6e(col, rowIndex, 2, 0, 630, Ord(False), Ord(False), Ord(overlay));
      end;
      { 73E0 } if symbol = 'f' then
      begin
        { 73F2 } u2_2c6e(col, rowIndex, 2, 0, 631, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7412 } if symbol = 'h' then
      begin
        { 7424 } u2_2c6e(col, rowIndex, 2, 0, 632, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7444 } if symbol = ':' then
      begin
        { 7456 } u2_2c6e(col, rowIndex, 2, 0, 466, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7476 } if symbol = 'H' then
      begin
        { 7488 } u2_2c6e(col, rowIndex, 2, 0, 468, Ord(False), Ord(False), Ord(overlay));
      end;
      { 74A8 } if symbol = 'M' then
      begin
        { 74BA } u2_2c6e(col, rowIndex, 2, 0, 624, Ord(False), Ord(False), Ord(overlay));
      end;
      { 74DA } if symbol = 'P' then
      begin
        { 74EC } u2_2c6e(col, rowIndex, 2, 0, 304, Ord(False), Ord(False), Ord(overlay));
      end;
      { 750C } if symbol = 'p' then
      begin
        { 751E } u2_2c6e((col - 1), rowIndex, 2, 159, 0, Ord(False), Ord(False), Ord(overlay));
        { 7540 } u2_2c6e(col, rowIndex, 2, 160, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7560 } if symbol = #139 then
      begin
        { 7572 } u2_2c6e((col - 1), rowIndex, d_681A, 163, 0, Ord(True), Ord(False), Ord(overlay));
        { 7594 } u2_2c6e(col, rowIndex, d_681A, 164, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 75B4 } if symbol = #154 then
      begin
        { 75C6 } u2_2c6e((col - 1), rowIndex, d_681A, 166, 0, Ord(True), Ord(False), Ord(overlay));
        { 75E8 } u2_2c6e(col, rowIndex, d_681A, 165, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 7608 } if symbol = #31 then
      begin
        { 761A } u2_2c6e(col, rowIndex, d_681A, 166, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 763A } if symbol = #168 then
      begin
        { 764C } u2_2c6e(col, rowIndex, 2, 0, 175, Ord(False), Ord(False), Ord(overlay));
      end;
      { 766C } if symbol = #169 then
      begin
        { 767E } u2_2c6e(col, rowIndex, 2, 0, 176, Ord(False), Ord(False), Ord(overlay));
      end;
      { 769E } if symbol = #170 then
      begin
        { 76B0 } u2_2c6e(col, rowIndex, 2, 0, 177, Ord(False), Ord(False), Ord(overlay));
      end;
      { 76D0 } if symbol = #171 then
      begin
        { 76E2 } u2_2c6e(col, (rowIndex - 1), 194, 0, 0, Ord(False), Ord(True), Ord(overlay));
        { 7703 } u2_2c6e(col, rowIndex, 198, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7722 } if symbol = #172 then
      begin
        { 7734 } u2_2c6e(col, rowIndex, 2, 197, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7754 } if symbol = #173 then
      begin
        { 7766 } u2_2c6e(col, rowIndex, 193, 0, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 7785 } if symbol = #133 then
      begin
        { 779A } u2_2c6e((col - 3), rowIndex, 2, 0, 221, Ord(False), Ord(False), Ord(overlay));
        { 77BE } u2_2c6e((col - 2), rowIndex, 2, 0, 222, Ord(False), Ord(True), Ord(overlay));
        { 77E2 } u2_2c6e((col - 1), rowIndex, 2, 0, 223, Ord(False), Ord(False), Ord(overlay));
        { 7804 } u2_2c6e(col, rowIndex, 2, 0, 224, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7824 } if symbol = #134 then
      begin
        { 7836 } u2_2c6e((col - 2), rowIndex, 2, 0, 229, Ord(False), Ord(False), Ord(overlay));
        { 785A } u2_2c6e((col - 1), rowIndex, 2, 0, 230, Ord(False), Ord(True), Ord(overlay));
        { 787C } u2_2c6e(col, rowIndex, 2, 0, 231, Ord(False), Ord(False), Ord(overlay));
      end;
      { 789C } if symbol = '+' then
      begin
        { 78AE } u2_2c6e(col, rowIndex, 2, 0, 421, Ord(False), Ord(False), Ord(overlay));
      end;
      { 78CE } if symbol = ',' then
      begin
        { 78E0 } u2_2c6e(col, rowIndex, 2, 0, 422, Ord(True), Ord(False), Ord(overlay));
      end;
      { 7900 } if symbol = '-' then
      begin
        { 7912 } u2_2c6e(col, rowIndex, 2, 0, 423, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7932 } if symbol = '.' then
      begin
        { 7944 } u2_2c6e(col, rowIndex, 2, 0, 424, Ord(True), Ord(False), Ord(overlay));
      end;
      { 7964 } if symbol = '/' then
      begin
        { 7976 } u2_2c6e(col, rowIndex, 2, 0, 425, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7996 } if symbol = '4' then
      begin
        { 79A8 } u2_2c6e(col, rowIndex, 2, 0, 426, Ord(True), Ord(False), Ord(overlay));
      end;
      { 79C8 } if symbol = 'o' then
      begin
        { 79DA } u2_2c6e(col, rowIndex, d_681A, 417, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 79FA } if symbol = 'i' then
      begin
        { 7A0C } u2_2c6e(col, rowIndex, 441, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7A2B } if symbol = 'j' then
      begin
        { 7A3D } u2_2c6e(col, rowIndex, d_681A, 442, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 7A5D } if symbol = 'k' then
      begin
        { 7A6F } u2_2c6e(col, rowIndex, d_681A, 443, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 7A8F } if symbol = 'l' then
      begin
        { 7AA1 } u2_2c6e(col, rowIndex, d_681A, 444, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 7AC1 } if symbol = #149 then
      begin
        { 7AD3 } u2_2c6e(col, rowIndex, 2, 449, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7AF3 } if symbol = '|' then
      begin
        { 7B05 } u2_2c6e(col, rowIndex, 2, 419, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7B25 } if symbol = '~' then
      begin
        { 7B37 } u2_2c6e(col, rowIndex, 2, 420, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7B57 } if symbol = 'm' then
      begin
        { 7B6C } u2_2c6e(col, rowIndex, 2, 0, 0, Ord(False), Ord(False), Ord(overlay));
        { 7B8B } Inc(d_682E);
        { 7B8F } u9_19f9(d_6D7E^.Images[45].Pixels[1], (col * 16), ((rowIndex * 16) + 16));
        { 7BB3 } u9_19f9(d_6D7E^.Images[45].Pixels[1], (col * 16), ((rowIndex * 16) + 416));
        { 7BD7 } d_34EC[d_682E].State := 0;
        { 7BE5 } d_34EC[d_682E].Sprite := 445;
        { 7BF3 } d_34EC[d_682E].X := (col * 16);
        { 7C07 } d_34EC[d_682E].Y := (rowIndex * 16);
        { 7C1B } d_34EC[d_682E].OldX := (col * 16);
        { 7C2F } d_34EC[d_682E].OldY := (rowIndex * 16);
        { 7C43 } if Random(2) > 0 then
        begin
          { 7C50 } d_34EC[d_682E].DX := 1;
        end
        else
        begin
          { 7C60 } d_34EC[d_682E].DX := -1;
        end;
        { 7C6E } d_34EC[d_682E].DY := 0;
        { 7C7C } d_34EC[d_682E].Frame := 1;
        { 7C8A } d_34EC[d_682E].Speed := 1;
        { 7C98 } d_34EC[d_682E].Tick := 0;
        { 7CA6 } d_34EC[d_682E].Limit := 0;
        { 7CB4 } d_34EC[d_682E].Kind := 20;
        { 7CC2 } d_34EC[d_682E].Inactive := 0;
        { 7CCF } d_34EC[d_682E].Marked := 0;
      end;
      { 7CDC } if symbol = 'a' then
      begin
        { 7CEE } u2_2c6e(col, rowIndex, 500, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 7D0D } if symbol = '`' then
      begin
        { 7D1F } u2_2c6e(col, rowIndex, 2, 0, 499, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7D3F } if symbol = '_' then
      begin
        { 7D54 } u2_2c6e(col, rowIndex, 2, 0, 0, Ord(False), Ord(False), Ord(overlay));
        { 7D73 } Inc(d_682E);
        { 7D77 } u9_19f9(d_6D82^.Images[45].Pixels[1], (col * 16), ((rowIndex * 16) + 16));
        { 7D9B } u9_19f9(d_6D82^.Images[45].Pixels[1], (col * 16), ((rowIndex * 16) + 416));
        { 7DBF } d_34EC[d_682E].State := 0;
        { 7DCD } d_34EC[d_682E].X := (col * 16);
        { 7DE1 } d_34EC[d_682E].Y := (rowIndex * 16);
        { 7DF5 } d_34EC[d_682E].OldX := (col * 16);
        { 7E09 } d_34EC[d_682E].OldY := (rowIndex * 16);
        { 7E1D } if Random(2) > 0 then
        begin
          { 7E2A } d_34EC[d_682E].DX := 1;
        end
        else
        begin
          { 7E3A } d_34EC[d_682E].DX := -1;
        end;
        { 7E48 } if d_34EC[d_682E].DX = 1 then
        begin
          { 7E57 } d_34EC[d_682E].Sprite := 497;
        end
        else
        begin
          { 7E67 } d_34EC[d_682E].Sprite := 495;
        end;
        { 7E75 } d_34EC[d_682E].DY := 0;
        { 7E83 } d_34EC[d_682E].Frame := 1;
        { 7E91 } d_34EC[d_682E].Speed := 1;
        { 7E9F } d_34EC[d_682E].Tick := 0;
        { 7EAD } d_34EC[d_682E].Limit := 0;
        { 7EBB } d_34EC[d_682E].Kind := 21;
        { 7EC9 } d_34EC[d_682E].Inactive := 0;
        { 7ED6 } d_34EC[d_682E].Marked := 0;
      end;
      { 7EE3 } if symbol = 'D' then
      begin
        { 7EF5 } u2_2c6e(col, rowIndex, 2, 0, 613, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7F15 } if symbol = 'E' then
      begin
        { 7F27 } u2_2c6e(col, rowIndex, d_681A, 0, 614, Ord(False), Ord(True), Ord(overlay));
      end;
      { 7F47 } if symbol = 'O' then
      begin
        { 7F59 } u2_2c6e(col, rowIndex, 2, 0, 615, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7F79 } if symbol = 'U' then
      begin
        { 7F8B } u2_2c6e(col, rowIndex, 2, 0, 616, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7FAB } if symbol = #128 then
      begin
        { 7FBD } u2_2c6e(col, rowIndex, 2, 0, 601, Ord(False), Ord(False), Ord(overlay));
      end;
      { 7FDD } if symbol = #129 then
      begin
        { 7FEF } u2_2c6e(col, rowIndex, 2, 0, 602, Ord(False), Ord(False), Ord(overlay));
      end;
      { 800F } if symbol = #130 then
      begin
        { 8021 } u2_2c6e(col, rowIndex, 2, 0, 603, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8041 } if symbol = #131 then
      begin
        { 8053 } u2_2c6e(col, rowIndex, 2, 0, 604, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8073 } if symbol = #132 then
      begin
        { 8085 } u2_2c6e(col, rowIndex, 2, 0, 605, Ord(False), Ord(False), Ord(overlay));
      end;
      { 80A5 } if symbol = #140 then
      begin
        { 80B7 } u2_2c6e(col, rowIndex, 2, 0, 621, Ord(False), Ord(False), Ord(overlay));
      end;
      { 80D7 } if symbol = #141 then
      begin
        { 80E9 } u2_2c6e(col, rowIndex, 2, 0, 622, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8109 } if symbol = #142 then
      begin
        { 811B } u2_2c6e(col, rowIndex, 2, 0, 623, Ord(False), Ord(False), Ord(overlay));
      end;
      { 813B } if symbol = '%' then
      begin
        { 814D } u2_2c6e((col - 1), rowIndex, 2, 0, 452, Ord(False), Ord(False), Ord(overlay));
        { 816F } u2_2c6e(col, rowIndex, 2, 0, 453, Ord(False), Ord(False), Ord(overlay));
      end;
      { 818F } if symbol = '&' then
      begin
        { 81A4 } u2_2c6e((col - 1), (rowIndex - 1), 455, 0, 0, Ord(True), Ord(False), Ord(overlay));
        { 81C7 } u2_2c6e(col, (rowIndex - 1), 456, 0, 0, Ord(True), Ord(False), Ord(overlay));
        { 81E8 } u2_2c6e((col - 1), rowIndex, 459, 0, 0, Ord(True), Ord(False), Ord(overlay));
        { 8209 } u2_2c6e(col, rowIndex, 460, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 8228 } if symbol = '(' then
      begin
        { 823D } u2_2c6e((col - 1), (rowIndex - 1), 457, 0, 0, Ord(True), Ord(False), Ord(overlay));
        { 8260 } u2_2c6e(col, (rowIndex - 1), 458, 0, 0, Ord(True), Ord(False), Ord(overlay));
        { 8281 } u2_2c6e((col - 1), rowIndex, 461, 0, 0, Ord(True), Ord(False), Ord(overlay));
        { 82A2 } u2_2c6e(col, rowIndex, 462, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 82C1 } if symbol = ')' then
      begin
        { 82D3 } u2_2c6e(col, rowIndex, 2, 0, 463, Ord(False), Ord(False), Ord(overlay));
      end;
      { 82F3 } if symbol = '*' then
      begin
        { 8305 } if col > 0 then
        begin
          { 830B } u2_2c6e(col, rowIndex, 2, 0, 467, Ord(False), Ord(False), Ord(overlay));
        end;
      end;
      { 832B } if symbol = 'q' then
      begin
        { 833D } u2_2c6e(col, (rowIndex - 1), 2, 0, 633, Ord(True), Ord(False), Ord(overlay));
        { 835F } u2_2c6e(col, rowIndex, 2, 0, 637, Ord(True), Ord(False), Ord(overlay));
      end;
      { 837F } if symbol = 't' then
      begin
        { 8391 } u2_2c6e(col, rowIndex, 2, 0, 635, Ord(False), Ord(False), Ord(overlay));
      end;
      { 83B1 } u2_3a91(col, rowIndex, symbol, Ord(overlay));
      { 83C6 } if symbol = #175 then
      begin
        { 83D8 } u2_2c6e(col, rowIndex, 349, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 83F7 } if symbol = #143 then
      begin
        { 8409 } u2_2c6e(col, rowIndex, d_681A, 651, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 8429 } if symbol = #144 then
      begin
        { 843B } u2_2c6e(col, rowIndex, 652, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 845A } if symbol = #145 then
      begin
        { 846C } u2_2c6e(col, rowIndex, d_681A, 653, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 848C } if symbol = #146 then
      begin
        { 849E } u2_2c6e(col, rowIndex, d_681A, 654, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 84BE } if symbol = #147 then
      begin
        { 84D0 } u2_2c6e(col, rowIndex, 655, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 84EF } if symbol = #148 then
      begin
        { 8501 } u2_2c6e(col, rowIndex, 656, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 8520 } if symbol = #150 then
      begin
        { 8532 } u2_2c6e(col, rowIndex, 2, 0, 658, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8552 } if symbol = #151 then
      begin
        { 8564 } u2_2c6e(col, rowIndex, 2, 0, 659, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8584 } if symbol = #152 then
      begin
        { 8596 } u2_2c6e(col, rowIndex, 2, 0, 660, Ord(False), Ord(False), Ord(overlay));
      end;
      { 85B6 } if symbol = #153 then
      begin
        { 85C8 } u2_2c6e(col, rowIndex, 661, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 85E7 } if symbol = #155 then
      begin
        { 85F9 } u2_2c6e(col, rowIndex, 2, 0, 663, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8619 } if symbol = #156 then
      begin
        { 862B } u2_2c6e(col, rowIndex, 2, 0, 664, Ord(False), Ord(False), Ord(overlay));
      end;
      { 864B } if symbol = #157 then
      begin
        { 865D } u2_2c6e(col, rowIndex, 2, 665, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 867D } if symbol = #158 then
      begin
        { 868F } u2_2c6e(col, rowIndex, 2, 666, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 86AF } if symbol = #163 then
      begin
        { 86C1 } u2_2c6e(col, rowIndex, d_681A, 671, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 86E1 } if symbol = #164 then
      begin
        { 86F3 } u2_2c6e(col, rowIndex, d_681A, 672, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 8713 } if symbol = #165 then
      begin
        { 8725 } u2_2c6e(col, rowIndex, d_681A, 673, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 8745 } if symbol = #166 then
      begin
        { 8757 } u2_2c6e(col, rowIndex, d_681A, 674, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 8777 } if symbol = #176 then
      begin
        { 8789 } u2_2c6e(col, rowIndex, 2, 0, 684, Ord(False), Ord(False), Ord(overlay));
      end;
      { 87A9 } if symbol = #177 then
      begin
        { 87BB } u2_2c6e(col, rowIndex, 2, 0, 685, Ord(False), Ord(False), Ord(overlay));
      end;
      { 87DB } if symbol = #178 then
      begin
        { 87ED } u2_2c6e(col, rowIndex, 2, 0, 686, Ord(False), Ord(False), Ord(overlay));
      end;
      { 880D } if symbol = #179 then
      begin
        { 881F } u2_2c6e(col, rowIndex, 2, 0, 687, Ord(False), Ord(False), Ord(overlay));
      end;
      { 883F } if symbol = #180 then
      begin
        { 8851 } u2_2c6e(col, rowIndex, 2, 0, 688, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8871 } if symbol = #181 then
      begin
        { 8883 } u2_2c6e(col, rowIndex, 2, 0, 689, Ord(False), Ord(False), Ord(overlay));
      end;
      { 88A3 } if symbol = #183 then
      begin
        { 88B5 } u2_2c6e(col, rowIndex, 2, 0, 691, Ord(False), Ord(False), Ord(overlay));
      end;
      { 88D5 } if symbol = #184 then
      begin
        { 88E7 } u2_2c6e(col, rowIndex, 2, 0, 692, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8907 } if symbol = #185 then
      begin
        { 8919 } u2_2c6e(col, rowIndex, 2, 0, 693, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8939 } if symbol = #186 then
      begin
        { 894B } u2_2c6e((col - 1), rowIndex, 690, 0, 0, Ord(False), Ord(True), Ord(overlay));
        { 896C } u2_2c6e(col, rowIndex, 694, 0, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 898B } if symbol = #187 then
      begin
        { 899D } u2_2c6e(col, rowIndex, 695, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 89BC } if symbol = #188 then
      begin
        { 89CE } u2_2c6e(col, rowIndex, 698, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 89ED } if symbol = #189 then
      begin
        { 89FF } u2_2c6e(col, rowIndex, 696, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8A1E } if symbol = #190 then
      begin
        { 8A30 } u2_2c6e(col, rowIndex, 697, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8A4F } if symbol = #191 then
      begin
        { 8A61 } u2_2c6e((col - 1), rowIndex, 679, 0, 0, Ord(False), Ord(True), Ord(overlay));
        { 8A82 } u2_2c6e(col, rowIndex, 680, 0, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 8AA1 } if symbol = 'y' then
      begin
        { 8AB3 } u2_2c6e((col - 1), rowIndex, 318, 0, 0, Ord(False), Ord(True), Ord(overlay));
        { 8AD4 } u2_2c6e(col, rowIndex, 319, 0, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 8AF3 } if symbol = 'z' then
      begin
        { 8B05 } u2_2c6e(col, rowIndex, 2, 317, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8B25 } if symbol = #135 then
      begin
        { 8B37 } u2_2c6e((col - 1), rowIndex, 323, 0, 0, Ord(False), Ord(True), Ord(overlay));
        { 8B58 } u2_2c6e(col, rowIndex, 324, 0, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 8B77 } if symbol = #182 then
      begin
        { 8B89 } u2_2c6e(col, rowIndex, 2, 681, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8BA9 } if symbol = #192 then
      begin
        { 8BBB } u2_2c6e((col - 1), rowIndex, 699, 0, 0, Ord(False), Ord(True), Ord(overlay));
        { 8BDC } u2_2c6e(col, rowIndex, 700, 0, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 8BFB } if symbol = #136 then
      begin
        { 8C0D } u2_2c6e(col, rowIndex, 2, 345, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8C2D } if symbol = #137 then
      begin
        { 8C3F } u2_2c6e(col, rowIndex, 2, 346, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8C5F } if symbol = #138 then
      begin
        { 8C71 } u2_2c6e(col, rowIndex, 2, 347, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8C91 } if symbol = #162 then
      begin
        { 8CA3 } u2_2c6e(col, rowIndex, 2, 348, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 8CC3 } if symbol = #193 then
      begin
        { 8CD5 } u2_2c6e(col, rowIndex, 701, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 8CF4 } if symbol = #194 then
      begin
        { 8D06 } u2_2c6e(col, rowIndex, 702, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 8D25 } if symbol = #195 then
      begin
        { 8D37 } u2_2c6e(col, rowIndex, 703, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 8D56 } if symbol = #196 then
      begin
        { 8D68 } u2_2c6e(col, rowIndex, 704, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 8D87 } if symbol = #197 then
      begin
        { 8D99 } u2_2c6e(col, rowIndex, 705, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 8DB8 } if symbol = #198 then
      begin
        { 8DCA } u2_2c6e(col, rowIndex, 706, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 8DE9 } if symbol = #199 then
      begin
        { 8DFB } u2_2c6e(col, rowIndex, 707, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 8E1A } if symbol = #200 then
      begin
        { 8E2C } u2_2c6e(col, rowIndex, 708, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 8E4B } if symbol = #201 then
      begin
        { 8E5D } u2_2c6e(col, rowIndex, 709, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 8E7C } if symbol = #202 then
      begin
        { 8E8E } u2_2c6e(col, rowIndex, 2, 0, 710, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8EAE } if symbol = #203 then
      begin
        { 8EC0 } u2_2c6e(col, rowIndex, d_681A, 0, 711, Ord(False), Ord(True), Ord(overlay));
      end;
      { 8EE0 } if symbol = #204 then
      begin
        { 8EF2 } u2_2c6e(col, rowIndex, d_681A, 0, 712, Ord(False), Ord(True), Ord(overlay));
      end;
      { 8F12 } if symbol = #205 then
      begin
        { 8F24 } u2_2c6e(col, rowIndex, d_681A, 0, 713, Ord(False), Ord(True), Ord(overlay));
      end;
      { 8F44 } if symbol = #206 then
      begin
        { 8F56 } u2_2c6e(col, rowIndex, 2, 0, 714, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8F76 } if symbol = #207 then
      begin
        { 8F88 } u2_2c6e(col, rowIndex, 2, 0, 715, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8FA8 } if symbol = #208 then
      begin
        { 8FBA } u2_2c6e(col, rowIndex, 2, 0, 716, Ord(False), Ord(False), Ord(overlay));
      end;
      { 8FDA } if symbol = #209 then
      begin
        { 8FEF } u2_2c6e(col, rowIndex, 2, 0, 0, Ord(False), Ord(False), Ord(overlay));
        { 900E } Inc(d_682E);
        { 9012 } u9_19f9(d_6DAE^.Images[1].Pixels[1], (col * 16), ((rowIndex * 16) + 16));
        { 9036 } u9_19f9(d_6DAE^.Images[1].Pixels[1], (col * 16), ((rowIndex * 16) + 416));
        { 905A } d_34EC[d_682E].State := 0;
        { 9068 } d_34EC[d_682E].Sprite := 717;
        { 9076 } d_34EC[d_682E].X := (col * 16);
        { 908A } d_34EC[d_682E].Y := (rowIndex * 16);
        { 909E } d_34EC[d_682E].OldX := (col * 16);
        { 90B2 } d_34EC[d_682E].OldY := (rowIndex * 16);
        { 90C6 } d_34EC[d_682E].DX := 1;
        { 90D4 } d_34EC[d_682E].DY := 0;
        { 90E2 } d_34EC[d_682E].Frame := 1;
        { 90F0 } d_34EC[d_682E].Speed := 0;
        { 90FE } d_34EC[d_682E].Tick := 0;
        { 910C } d_34EC[d_682E].Limit := 0;
        { 911A } d_34EC[d_682E].Kind := 26;
        { 9128 } d_34EC[d_682E].Inactive := 0;
        { 9135 } d_34EC[d_682E].Marked := 0;
      end;
      { 9142 } if symbol = #210 then
      begin
        { 9157 } u2_2c6e((col - 1), (rowIndex - 1), 191, 0, 0, Ord(False), Ord(True), Ord(overlay));
        { 917A } u2_2c6e(col, (rowIndex - 1), 192, 0, 0, Ord(False), Ord(True), Ord(overlay));
        { 919B } u2_2c6e((col - 1), rowIndex, 195, 0, 0, Ord(False), Ord(False), Ord(overlay));
        { 91BC } u2_2c6e(col, rowIndex, 196, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 91DB } if symbol = #213 then
      begin
        { 91ED } u2_2c6e(col, rowIndex, d_681A, 721, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 920D } if symbol = #214 then
      begin
        { 921F } u2_2c6e(col, rowIndex, d_681A, 722, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 923F } if symbol = #215 then
      begin
        { 9251 } u2_2c6e(col, rowIndex, d_681A, 723, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 9271 } if symbol = #217 then
      begin
        { 9283 } u2_2c6e(col, rowIndex, 2, 725, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 92A3 } if symbol = #218 then
      begin
        { 92B5 } u2_2c6e(col, rowIndex, d_681A, 726, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 92D5 } if symbol = #219 then
      begin
        { 92E7 } u2_2c6e(col, rowIndex, d_681A, 727, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 9307 } if symbol = #220 then
      begin
        { 9319 } u2_2c6e(col, rowIndex, d_681A, 728, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 9339 } if symbol = #221 then
      begin
        { 934B } u2_2c6e(col, rowIndex, 2, 729, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 936B } if symbol = #222 then
      begin
        { 937D } u2_2c6e(col, rowIndex, d_681A, 730, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 939D } if symbol = #223 then
      begin
        { 93AF } u2_2c6e(col, rowIndex, 201, 0, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 93CE } if symbol = #224 then
      begin
        { 93E0 } u2_2c6e(col, rowIndex, 202, 0, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 93FF } if symbol = #225 then
      begin
        { 9411 } u2_2c6e(col, rowIndex, 203, 0, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 9430 } if symbol = #226 then
      begin
        { 9442 } u2_2c6e(col, rowIndex, 205, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 9461 } if symbol = #227 then
      begin
        { 9473 } u2_2c6e(col, rowIndex, 206, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 9492 } if symbol = #228 then
      begin
        { 94A4 } u2_2c6e(col, rowIndex, 207, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 94C3 } if symbol = '!' then
      begin
        { 94D5 } u2_2c6e(col, rowIndex, 751, 0, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 94F4 } if symbol = 'B' then
      begin
        { 9506 } u2_2c6e(col, rowIndex, d_681A, 753, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 9526 } if symbol = 'C' then
      begin
        { 9538 } u2_2c6e(col, rowIndex, 755, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 9557 } if symbol = 'F' then
      begin
        { 9569 } u2_2c6e(col, rowIndex, d_681A, 756, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 9589 } if symbol = 'J' then
      begin
        { 959B } u2_2c6e(col, rowIndex, d_681A, 757, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 95BB } if symbol = #229 then
      begin
        { 95CD } u2_2c6e(col, rowIndex, 758, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 95EC } if symbol = #230 then
      begin
        { 95FE } u2_2c6e(col, rowIndex, 2, 0, 759, Ord(False), Ord(False), Ord(overlay));
      end;
      { 961E } if symbol = #231 then
      begin
        { 9630 } u2_2c6e(col, rowIndex, 2, 0, 760, Ord(False), Ord(False), Ord(overlay));
      end;
      { 9650 } if symbol = #232 then
      begin
        { 9662 } u2_2c6e(col, rowIndex, 2, 0, 761, Ord(False), Ord(False), Ord(overlay));
      end;
      { 9682 } if symbol = #233 then
      begin
        { 9694 } u2_2c6e(col, rowIndex, 2, 0, 762, Ord(False), Ord(False), Ord(overlay));
      end;
      { 96B4 } if symbol = #234 then
      begin
        { 96C6 } u2_2c6e(col, rowIndex, 2, 0, 763, Ord(False), Ord(False), Ord(overlay));
      end;
      { 96E6 } if symbol = #235 then
      begin
        { 96F8 } u2_2c6e(col, rowIndex, 2, 0, 764, Ord(False), Ord(False), Ord(overlay));
      end;
      { 9718 } if symbol = #236 then
      begin
        { 972A } u2_2c6e(col, rowIndex, 2, 0, 765, Ord(False), Ord(False), Ord(overlay));
      end;
      { 974A } if symbol = #237 then
      begin
        { 975C } u2_2c6e((col - 1), rowIndex, 199, 0, 0, Ord(False), Ord(True), Ord(overlay));
        { 977D } u2_2c6e(col, rowIndex, 200, 0, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 979C } if symbol = #216 then
      begin
        { 97AE } u2_2c6e((col - 1), rowIndex, 268, 0, 0, Ord(False), Ord(True), Ord(overlay));
        { 97CF } u2_2c6e(col, rowIndex, 269, 0, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 97EE } if symbol = #238 then
      begin
        { 9800 } u2_2c6e((col - 2), rowIndex, 2, 264, 0, Ord(False), Ord(True), Ord(overlay));
        { 9824 } u2_2c6e((col - 1), rowIndex, 2, 265, 0, Ord(False), Ord(True), Ord(overlay));
        { 9846 } u2_2c6e(col, rowIndex, 2, 266, 0, Ord(False), Ord(True), Ord(overlay));
      end;
      { 9866 } if symbol = #239 then
      begin
        { 9878 } u2_2c6e(col, (rowIndex - 1), 2, 263, 0, Ord(False), Ord(True), Ord(overlay));
        { 989A } u2_2c6e(col, rowIndex, 2, 267, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 98BA } if symbol = #241 then
      begin
        { 98CC } u2_2c6e(col, rowIndex, 775, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 98EB } if symbol = #242 then
      begin
        { 98FD } u2_2c6e(col, rowIndex, 776, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 991C } if symbol = #243 then
      begin
        { 992E } u2_2c6e(col, rowIndex, 777, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 994D } if symbol = #244 then
      begin
        { 995F } u2_2c6e(col, rowIndex, 778, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 997E } if symbol = #245 then
      begin
        { 9990 } u2_2c6e(col, rowIndex, 779, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 99AF } if symbol = #246 then
      begin
        { 99C1 } u2_2c6e(col, rowIndex, 780, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 99E0 } if symbol = #247 then
      begin
        { 99F2 } u2_2c6e(col, rowIndex, 781, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 9A11 } if symbol = #248 then
      begin
        { 9A23 } u2_2c6e(col, rowIndex, 782, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 9A42 } if symbol = #249 then
      begin
        { 9A54 } u2_2c6e(col, rowIndex, 783, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 9A73 } if symbol = #250 then
      begin
        { 9A85 } u2_2c6e(col, rowIndex, 784, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 9AA4 } if symbol = #251 then
      begin
        { 9AB6 } u2_2c6e(col, rowIndex, 785, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 9AD5 } if symbol = #252 then
      begin
        { 9AE7 } u2_2c6e(col, rowIndex, 786, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 9B06 } if symbol = #253 then
      begin
        { 9B18 } u2_2c6e(col, rowIndex, d_681A, 787, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 9B38 } if symbol = #254 then
      begin
        { 9B4A } u2_2c6e(col, rowIndex, 788, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 9B69 } if symbol = 'L' then
      begin
        { 9B7B } u2_2c6e(col, rowIndex, d_681A, 789, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 9B9B } if symbol = #159 then
      begin
        { 9BAD } u2_2c6e(col, rowIndex, d_681A, 791, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 9BCD } if symbol = #160 then
      begin
        { 9BDF } u2_2c6e(col, rowIndex, 792, 0, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 9BFE } if symbol = #161 then
      begin
        { 9C10 } u2_2c6e(col, rowIndex, d_681A, 793, 0, Ord(True), Ord(False), Ord(overlay));
      end;
      { 9C30 } if symbol = 'S' then
      begin
        { 9C42 } u2_2c6e(col, rowIndex, 2, 0, 790, Ord(False), Ord(False), Ord(overlay));
      end;
      { 9C62 } if symbol = 'Z' then
      begin
        { 9C77 } u2_2c6e((col - 1), (rowIndex - 1), 2, 795, 0, Ord(False), Ord(True), Ord(overlay));
        { 9C9B } u2_2c6e(col, (rowIndex - 1), 2, 796, 0, Ord(False), Ord(True), Ord(overlay));
        { 9CBD } u2_2c6e((col - 1), rowIndex, 2, 799, 0, Ord(False), Ord(False), Ord(overlay));
        { 9CDF } u2_2c6e(col, rowIndex, 2, 800, 0, Ord(False), Ord(False), Ord(overlay));
      end;
      { 9CFF } if symbol = #167 then
      begin
        { 9D14 } u2_2c6e(col, rowIndex, 2, 0, 0, Ord(False), Ord(False), Ord(overlay));
        { 9D33 } Inc(d_682E);
        { 9D37 } u9_19f9(d_6D8A^.Images[25].Pixels[1], (col * 16), ((rowIndex * 16) + 16));
        { 9D5B } u9_19f9(d_6D8A^.Images[25].Pixels[1], (col * 16), ((rowIndex * 16) + 416));
        { 9D7F } d_34EC[d_682E].State := 0;
        { 9D8D } d_34EC[d_682E].Sprite := 675;
        { 9D9B } d_34EC[d_682E].X := (col * 16);
        { 9DAF } d_34EC[d_682E].Y := (rowIndex * 16);
        { 9DC3 } d_34EC[d_682E].OldX := (col * 16);
        { 9DD7 } d_34EC[d_682E].OldY := (rowIndex * 16);
        { 9DEB } d_34EC[d_682E].DX := 1;
        { 9DF9 } d_34EC[d_682E].DY := 0;
        { 9E07 } d_34EC[d_682E].Frame := 1;
        { 9E15 } d_34EC[d_682E].Speed := 0;
        { 9E23 } d_34EC[d_682E].Tick := 0;
        { 9E31 } d_34EC[d_682E].Limit := 0;
        { 9E3F } d_34EC[d_682E].Kind := 27;
        { 9E4D } d_34EC[d_682E].Inactive := 0;
        { 9E5A } d_34EC[d_682E].Marked := 0;
      end;
      { 9E67 } if symbol = 'b' then
      begin
        { 9E7C } u2_2c6e(col, rowIndex, 2, 0, 0, Ord(False), Ord(False), Ord(overlay));
        { 9E9B } Inc(d_682E);
        { 9E9F } u9_19f9(d_6D8A^.Images[26].Pixels[1], (col * 16), ((rowIndex * 16) + 16));
        { 9EC3 } u9_19f9(d_6D8A^.Images[26].Pixels[1], (col * 16), ((rowIndex * 16) + 416));
        { 9EE7 } d_34EC[d_682E].State := 0;
        { 9EF5 } d_34EC[d_682E].Sprite := 676;
        { 9F03 } d_34EC[d_682E].X := (col * 16);
        { 9F17 } d_34EC[d_682E].Y := (rowIndex * 16);
        { 9F2B } d_34EC[d_682E].OldX := (col * 16);
        { 9F3F } d_34EC[d_682E].OldY := (rowIndex * 16);
        { 9F53 } if Random(2) > 0 then
        begin
          { 9F60 } d_34EC[d_682E].DX := 1;
        end
        else
        begin
          { 9F70 } d_34EC[d_682E].DX := -1;
        end;
        { 9F7E } d_34EC[d_682E].DY := 0;
        { 9F8C } d_34EC[d_682E].Frame := 1;
        { 9F9A } d_34EC[d_682E].Speed := 2;
        { 9FA8 } d_34EC[d_682E].Tick := 0;
        { 9FB6 } d_34EC[d_682E].Limit := 0;
        { 9FC4 } d_34EC[d_682E].Kind := 28;
        { 9FD2 } d_34EC[d_682E].Inactive := 0;
        { 9FDF } d_34EC[d_682E].Marked := 0;
      end;
    end;
    { 9FEC } u2_2e88(col, rowIndex, symbol);
    { 9FFC } if symbol = 'Y' then
    begin
      { A011 } u2_2c6e(col, rowIndex, 2, 0, 0, Ord(False), Ord(False), Ord(overlay));
      { A030 } savedCol := col;
      { A037 } savedRow := rowIndex;
      { A03E } if d_6D18.X <> 0 then
      begin
        { A045 } if d_681C = 1 then
        begin
          { A04C } col := (d_6D18.X shr 4);
          { A057 } rowIndex := (d_6D18.Y shr 4);
        end;
      end;
      { A062 } u9_19f9(d_6D7A^.Images[1].Pixels[1], (col * 16), ((rowIndex * 16) + 16));
      { A086 } u9_19f9(d_6D7A^.Images[1].Pixels[1], (col * 16), ((rowIndex * 16) + 416));
      { A0AA } d_34EC[1].State := 0;
      { A0AF } d_34EC[1].Sprite := 9;
      { A0B5 } d_34EC[1].X := (col * 16);
      { A0C0 } d_34EC[1].Y := (rowIndex * 16);
      { A0CB } d_34EC[1].OldX := (col * 16);
      { A0D6 } d_34EC[1].OldY := (rowIndex * 16);
      { A0E1 } d_34EC[1].DX := 1;
      { A0E7 } d_34EC[1].DY := 0;
      { A0EC } d_34EC[1].Frame := 1;
      { A0F2 } d_34EC[1].Speed := 2;
      { A0F8 } d_34EC[1].Tick := 0;
      { A0FD } d_34EC[1].Kind := 99;
      { A103 } d_34EC[1].Inactive := 0;
      { A108 } d_34EC[1].Marked := 0;
      { A10D } d_6838 := ((col * 16) - 160);
      { A11B } if d_6838 < 0 then
      begin
        { A122 } d_6838 := 0;
      end;
      { A127 } if d_6838 > 320 then
      begin
        { A12F } d_6838 := 320;
      end;
      { A135 } d_683A := ((rowIndex * 16) - 100);
      { A143 } if d_683A < 0 then
      begin
        { A14A } d_683A := 0;
      end;
      { A14F } if d_683A > 184 then
      begin
        { A157 } d_683A := 184;
      end;
      { A15D } if d_70C6 = 0 then
      begin
        { A164 } u9_01f9(d_6838, (d_683A + 16));
      end
      else
      begin
        { A176 } u9_024c(d_6838, (d_683A + 16));
      end;
      { A186 } col := savedCol;
      { A18D } rowIndex := savedRow;
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u2_a1ae(Level: Integer);
var
  I: Integer;
  F: t_u2_a1ae_tlevelfileviews;
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
{$S-}{$I-}{$R-}{$B-}{$F-}
begin
end.
