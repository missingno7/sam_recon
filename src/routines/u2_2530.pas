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
  d_6840: Integer;
  d_6D72, d_6D76, d_6D7E, d_6D82, d_6D86, d_6D8A,
  d_6D8E, d_6D92, d_6D96, d_6D9A, d_6DA2, d_6DAA,
  d_6DAE: PSpriteBuffer;
{@stubs}
procedure u9_0475(var Data; X, Y: Integer);
{@body}
procedure u2_2530(X, Y: Integer);
var
  X0, Y0: Integer;
begin
  X0 := X shr 4;
  Y0 := Y shr 4;
  if (X0 >= 0) and (X0 <= 39) and (Y0 >= 0) then
  begin
    case d_0296[X0 + 1, Y0 + 1].C of
      0: ;
      1..50:
        u9_0475(d_6D72^[d_0296[X0 + 1, Y0 + 1].C][3],
          X0 shl 1, (Y0 shl 4) + d_6840);
      179:
        if d_6840 = 16 then
          u9_0475(d_6D96^[29][3], X0 shl 1, (Y0 shl 4) + d_6840)
        else
          u9_0475(d_6D96^[30][3], X0 shl 1, (Y0 shl 4) + d_6840);
      100..150:
        u9_0475(d_6D76^[d_0296[X0 + 1, Y0 + 1].C - 100][3],
          X0 shl 1, (Y0 shl 4) + d_6840);
      151..200:
        u9_0475(d_6D96^[d_0296[X0 + 1, Y0 + 1].C - 150][3],
          X0 shl 1, (Y0 shl 4) + d_6840);
      201..250:
        u9_0475(d_6D9A^[d_0296[X0 + 1, Y0 + 1].C - 200][3],
          X0 shl 1, (Y0 shl 4) + d_6840);
      251..300:
        u9_0475(d_6DAA^[d_0296[X0 + 1, Y0 + 1].C - 250][3],
          X0 shl 1, (Y0 shl 4) + d_6840);
      301..350:
        u9_0475(d_6DA2^[d_0296[X0 + 1, Y0 + 1].C - 300][3],
          X0 shl 1, (Y0 shl 4) + d_6840);
      351..400:
        u9_0475(d_6DAE^[d_0296[X0 + 1, Y0 + 1].C - 350][3],
          X0 shl 1, (Y0 shl 4) + d_6840);
      401..450:
        u9_0475(d_6D7E^[d_0296[X0 + 1, Y0 + 1].C - 400][3],
          X0 shl 1, (Y0 shl 4) + d_6840);
      499:
        if d_6840 = 16 then
          u9_0475(d_6D82^[49][3], X0 shl 1, (Y0 shl 4) + d_6840)
        else
          u9_0475(d_6D82^[1][3], X0 shl 1, (Y0 shl 4) + d_6840);
      451..500:
        u9_0475(d_6D82^[d_0296[X0 + 1, Y0 + 1].C - 450][3],
          X0 shl 1, (Y0 shl 4) + d_6840);
      613:
        if d_6840 = 16 then
          u9_0475(d_6D86^[13][3], X0 shl 1, (Y0 shl 4) + d_6840)
        else
          u9_0475(d_6D86^[17][3], X0 shl 1, (Y0 shl 4) + d_6840);
      601..602:
        u9_0475(d_6D86^[d_0296[X0 + 1, Y0 + 1].C - 600][3],
          X0 shl 1, (Y0 shl 4) + d_6840);
      603:
        if d_6840 = 416 then
          u9_0475(d_6D86^[d_0296[X0 + 1, Y0 + 1].C - 600][3],
            X0 shl 1, (Y0 shl 4) + d_6840);
      604..623:
        u9_0475(d_6D86^[d_0296[X0 + 1, Y0 + 1].C - 600][3],
          X0 shl 1, (Y0 shl 4) + d_6840);
      624:
        if d_6840 = 416 then
          u9_0475(d_6D86^[d_0296[X0 + 1, Y0 + 1].C - 600][3],
            X0 shl 1, (Y0 shl 4) + d_6840)
        else
          u9_0475(d_6D86^[d_0296[X0 + 1, Y0 + 1].C - 582][3],
            X0 shl 1, (Y0 shl 4) + d_6840);
      625..650:
        u9_0475(d_6D86^[d_0296[X0 + 1, Y0 + 1].C - 600][3],
          X0 shl 1, (Y0 shl 4) + d_6840);
      651..700:
        u9_0475(d_6D8A^[d_0296[X0 + 1, Y0 + 1].C - 650][3],
          X0 shl 1, (Y0 shl 4) + d_6840);
      701..750:
        u9_0475(d_6D8E^[d_0296[X0 + 1, Y0 + 1].C - 700][3],
          X0 shl 1, (Y0 shl 4) + d_6840);
      751..800:
        u9_0475(d_6D92^[d_0296[X0 + 1, Y0 + 1].C - 750][3],
          X0 shl 1, (Y0 shl 4) + d_6840);
    end;
  end;
end;

