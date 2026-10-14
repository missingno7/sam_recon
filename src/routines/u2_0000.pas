{@decls}
type
  TMapCell = record
    A, B, C: Word;
    D, E: Byte;
  end;
  TSprite = array[0..159] of Byte;
  TSpriteBuffer = array[1..200] of TSprite;
  PSpriteBuffer = ^TSpriteBuffer;
var
  d_0296: array[1..40, 1..25] of TMapCell;
  d_6840: Integer;
  d_6D72, d_6D76, d_6D7E, d_6D82, d_6D86, d_6D8A,
  d_6D8E, d_6D92, d_6D96, d_6D9A, d_6DA2, d_6DAA,
  d_6DAE: PSpriteBuffer;
{@stubs}
procedure u9_0475(var Source; X, Y: Integer);
procedure u9_2a9f(var Source; X, Y: Integer);
procedure u9_2e6d(X, Y, Color: Integer);
{@body}
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
    case d_0296[X1, Y1].A of
      0: ;
      1..8: u9_2e6d(ScreenX, ScreenY + d_6840, d_0296[X1, Y1].A - 1);
      9..50: u9_2a9f(d_6D72^[d_0296[X1, Y1].A][3], ScreenX, ScreenY + d_6840);
      101: u9_2e6d(ScreenX, ScreenY + d_6840, 4);
      100, 102..150: u9_2a9f(d_6D76^[d_0296[X1, Y1].A - 100][3], ScreenX, ScreenY + d_6840);
      179:
        if d_6840 = 16 then
          u9_2a9f(d_6D96^[29][3], ScreenX, ScreenY + d_6840)
        else
          u9_2a9f(d_6D96^[30][3], ScreenX, ScreenY + d_6840);
      151..200: u9_2a9f(d_6D96^[d_0296[X1, Y1].A - 150][3], ScreenX, ScreenY + d_6840);
      201..250: u9_2a9f(d_6D9A^[d_0296[X1, Y1].A - 200][3], ScreenX, ScreenY + d_6840);
      251..300: u9_2a9f(d_6DAA^[d_0296[X1, Y1].A - 250][3], ScreenX, ScreenY + d_6840);
      301..350: u9_2a9f(d_6DA2^[d_0296[X1, Y1].A - 300][3], ScreenX, ScreenY + d_6840);
      351..400: u9_2a9f(d_6DAE^[d_0296[X1, Y1].A - 350][3], ScreenX, ScreenY + d_6840);
      401..450: u9_2a9f(d_6D7E^[d_0296[X1, Y1].A - 400][3], ScreenX, ScreenY + d_6840);
      499:
        if d_6840 = 16 then
          u9_2a9f(d_6D82^[49][3], ScreenX, ScreenY + d_6840)
        else
          u9_2a9f(d_6D82^[1][3], ScreenX, ScreenY + d_6840);
      451..500: u9_2a9f(d_6D82^[d_0296[X1, Y1].A - 450][3], ScreenX, ScreenY + d_6840);
      535:
        if d_6840 = 16 then
          u9_2a9f(d_6D72^[21][3], ScreenX, ScreenY + d_6840)
        else
          u9_2a9f(d_6D72^[35][3], ScreenX, ScreenY + d_6840);
      501..550: u9_2a9f(d_6D72^[d_0296[X1, Y1].A - 500][3], ScreenX, ScreenY + d_6840);
      613:
        if d_6840 = 16 then
          u9_2a9f(d_6D86^[13][3], X0 shl 1, (Y0 shl 4) + d_6840)
        else
          u9_2a9f(d_6D86^[17][3], X0 shl 1, (Y0 shl 4) + d_6840);
      601..650: u9_2a9f(d_6D86^[d_0296[X1, Y1].A - 600][3], ScreenX, ScreenY + d_6840);
      651..700: u9_2a9f(d_6D8A^[d_0296[X1, Y1].A - 650][3], ScreenX, ScreenY + d_6840);
      701..750: u9_2a9f(d_6D8E^[d_0296[X1, Y1].A - 700][3], ScreenX, ScreenY + d_6840);
      751..800: u9_2a9f(d_6D92^[d_0296[X1, Y1].A - 750][3], ScreenX, ScreenY + d_6840);
    end;
    case d_0296[X1, Y1].B of
      0: ;
      1..50: u9_0475(d_6D72^[d_0296[X1, Y1].B][3], ScreenX, ScreenY + d_6840);
      100..150: u9_0475(d_6D76^[d_0296[X1, Y1].B - 100][3], ScreenX, ScreenY + d_6840);
      179:
        if d_6840 = 16 then
          u9_0475(d_6D96^[29][3], ScreenX, ScreenY + d_6840)
        else
          u9_0475(d_6D96^[30][3], ScreenX, ScreenY + d_6840);
      151..200: u9_0475(d_6D96^[d_0296[X1, Y1].B - 150][3], ScreenX, ScreenY + d_6840);
      201..250: u9_0475(d_6D9A^[d_0296[X1, Y1].B - 200][3], ScreenX, ScreenY + d_6840);
      251..300: u9_0475(d_6DAA^[d_0296[X1, Y1].B - 250][3], ScreenX, ScreenY + d_6840);
      301..350: u9_0475(d_6DA2^[d_0296[X1, Y1].B - 300][3], ScreenX, ScreenY + d_6840);
      351..400: u9_0475(d_6DAE^[d_0296[X1, Y1].B - 350][3], ScreenX, ScreenY + d_6840);
      401..450: u9_0475(d_6D7E^[d_0296[X1, Y1].B - 400][3], ScreenX, ScreenY + d_6840);
      499:
        if d_6840 = 16 then
          u9_0475(d_6D82^[49][3], ScreenX, ScreenY + d_6840)
        else
          u9_0475(d_6D82^[1][3], ScreenX, ScreenY + d_6840);
      451..500: u9_0475(d_6D82^[d_0296[X1, Y1].B - 450][3], ScreenX, ScreenY + d_6840);
      501..550: u9_0475(d_6D72^[d_0296[X1, Y1].B - 500][3], ScreenX, ScreenY + d_6840);
      613:
        if d_6840 = 16 then
          u9_0475(d_6D86^[13][3], X0 shl 1, (Y0 shl 4) + d_6840)
        else
          u9_0475(d_6D86^[17][3], X0 shl 1, (Y0 shl 4) + d_6840);
      601..650: u9_0475(d_6D86^[d_0296[X1, Y1].B - 600][3], ScreenX, ScreenY + d_6840);
      651..700: u9_0475(d_6D8A^[d_0296[X1, Y1].B - 650][3], ScreenX, ScreenY + d_6840);
      701..750: u9_0475(d_6D8E^[d_0296[X1, Y1].B - 700][3], ScreenX, ScreenY + d_6840);
      751..800: u9_0475(d_6D92^[d_0296[X1, Y1].B - 750][3], ScreenX, ScreenY + d_6840);
    end;
    case d_0296[X1, Y1].C of
      0: ;
      1..50: u9_0475(d_6D72^[d_0296[X1, Y1].C][3], ScreenX, ScreenY + d_6840);
      100..150: u9_0475(d_6D76^[d_0296[X1, Y1].C - 100][3], ScreenX, ScreenY + d_6840);
      179:
        if d_6840 = 16 then
          u9_0475(d_6D96^[29][3], ScreenX, ScreenY + d_6840)
        else
          u9_0475(d_6D96^[30][3], ScreenX, ScreenY + d_6840);
      151..200: u9_0475(d_6D96^[d_0296[X1, Y1].C - 150][3], ScreenX, ScreenY + d_6840);
      201..250: u9_0475(d_6D9A^[d_0296[X1, Y1].C - 200][3], ScreenX, ScreenY + d_6840);
      251..300: u9_0475(d_6DAA^[d_0296[X1, Y1].C - 250][3], ScreenX, ScreenY + d_6840);
      301..350: u9_0475(d_6DA2^[d_0296[X1, Y1].C - 300][3], ScreenX, ScreenY + d_6840);
      351..400: u9_0475(d_6DAE^[d_0296[X1, Y1].C - 350][3], ScreenX, ScreenY + d_6840);
      401..450: u9_0475(d_6D7E^[d_0296[X1, Y1].C - 400][3], ScreenX, ScreenY + d_6840);
      499:
        if d_6840 = 16 then
          u9_0475(d_6D82^[49][3], ScreenX, ScreenY + d_6840)
        else
          u9_0475(d_6D82^[1][3], ScreenX, ScreenY + d_6840);
      451..500: u9_0475(d_6D82^[d_0296[X1, Y1].C - 450][3], ScreenX, ScreenY + d_6840);
      501..550: u9_0475(d_6D72^[d_0296[X1, Y1].C - 500][3], ScreenX, ScreenY + d_6840);
      613:
        if d_6840 = 16 then
          u9_0475(d_6D86^[13][3], X0 shl 1, (Y0 shl 4) + d_6840)
        else
          u9_0475(d_6D86^[17][3], X0 shl 1, (Y0 shl 4) + d_6840);
      601..602: u9_0475(d_6D86^[d_0296[X1, Y1].C - 600][3], ScreenX, ScreenY + d_6840);
      603:
        if d_6840 = 416 then
          u9_0475(d_6D86^[d_0296[X1, Y1].C - 600][3], ScreenX, ScreenY + d_6840);
      604..623: u9_0475(d_6D86^[d_0296[X1, Y1].C - 600][3], ScreenX, ScreenY + d_6840);
      624:
        if d_6840 = 416 then
          u9_0475(d_6D86^[d_0296[X1, Y1].C - 600][3], ScreenX, ScreenY + d_6840)
        else
          u9_0475(d_6D86^[d_0296[X1, Y1].C - 582][3], ScreenX, ScreenY + d_6840);
      625..650: u9_0475(d_6D86^[d_0296[X1, Y1].C - 600][3], ScreenX, ScreenY + d_6840);
      651..700: u9_0475(d_6D8A^[d_0296[X1, Y1].C - 650][3], ScreenX, ScreenY + d_6840);
      701..750: u9_0475(d_6D8E^[d_0296[X1, Y1].C - 700][3], ScreenX, ScreenY + d_6840);
      751..800: u9_0475(d_6D92^[d_0296[X1, Y1].C - 750][3], ScreenX, ScreenY + d_6840);
    end;
  end;
end;
