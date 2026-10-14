{@decls}
type
  TMapCell = record
    F00, F02, F04: Word;
    F06, F07: Byte;
  end;
  TSpriteImage = array[1..160] of Byte;
  TSpriteBank = record
    Header: array[1..3] of Byte;
    Images: array[1..50] of TSpriteImage;
  end;
  PSpriteBank = ^TSpriteBank;
var
  d_0296: array[1..40, 1..25] of TMapCell;
  d_6840: Integer;
  d_6D72, d_6D76, d_6D7E, d_6D82, d_6D86, d_6D8A, d_6D8E,
  d_6D92, d_6D96, d_6D9A, d_6DA2, d_6DAA, d_6DAE: PSpriteBank;
{@stubs}
procedure u9_0475(var Sprite; X, Y: Integer);
procedure u9_2a9f(var Sprite; X, Y: Integer);
{@body}
procedure u2_1185(X, Y: Integer);
var
  TileX, TileY: Integer;
begin
  TileX := X shr 4;
  TileY := Y shr 4;
  if d_0296[TileX + 1, TileY + 1].F00 = 2 then
    d_0296[TileX + 1, TileY + 1].F00 := d_681A;
  if d_0296[TileX + 1, TileY + 1].F00 = 5 then
    d_0296[TileX + 1, TileY + 1].F00 := d_681A + 1;
  if d_0296[TileX + 1, TileY + 1].F00 = 6 then
    d_0296[TileX + 1, TileY + 1].F00 := d_681A + 2;
  if d_0296[TileX + 1, TileY + 1].F00 = 7 then
    d_0296[TileX + 1, TileY + 1].F00 := d_681A + 3;
  if d_0296[TileX + 1, TileY + 1].F00 = 8 then
    d_0296[TileX + 1, TileY + 1].F00 := 667;
  case d_0296[TileX + 1, TileY + 1].F00 of
    1..50:
      u9_2a9f(d_6D72^.Images[d_0296[TileX + 1, TileY + 1].F00], TileX * 2, TileY * 16 + d_6840);
    100..150:
      u9_2a9f(d_6D76^.Images[d_0296[TileX + 1, TileY + 1].F00 - 100], TileX * 2, TileY * 16 + d_6840);
    179:
      if d_6840 = 16 then
        u9_2a9f(d_6D96^.Images[29], TileX * 2, TileY * 16 + d_6840)
      else
        u9_2a9f(d_6D96^.Images[30], TileX * 2, TileY * 16 + d_6840);
    151..200:
      u9_2a9f(d_6D96^.Images[d_0296[TileX + 1, TileY + 1].F00 - 150], TileX * 2, TileY * 16 + d_6840);
    201..250:
      u9_2a9f(d_6D9A^.Images[d_0296[TileX + 1, TileY + 1].F00 - 200], TileX * 2, TileY * 16 + d_6840);
    251..300:
      u9_2a9f(d_6DAA^.Images[d_0296[TileX + 1, TileY + 1].F00 - 250], TileX * 2, TileY * 16 + d_6840);
    301..350:
      u9_2a9f(d_6DA2^.Images[d_0296[TileX + 1, TileY + 1].F00 - 300], TileX * 2, TileY * 16 + d_6840);
    351..400:
      u9_2a9f(d_6DAE^.Images[d_0296[TileX + 1, TileY + 1].F00 - 350], TileX * 2, TileY * 16 + d_6840);
    401..450:
      u9_2a9f(d_6D7E^.Images[d_0296[TileX + 1, TileY + 1].F00 - 400], TileX * 2, TileY * 16 + d_6840);
    499:
      if d_6840 = 16 then
        u9_2a9f(d_6D82^.Images[49], TileX * 2, TileY * 16 + d_6840)
      else
        u9_2a9f(d_6D82^.Images[1], TileX * 2, TileY * 16 + d_6840);
    451..500:
      u9_2a9f(d_6D82^.Images[d_0296[TileX + 1, TileY + 1].F00 - 450], TileX * 2, TileY * 16 + d_6840);
    501..550:
      u9_2a9f(d_6D72^.Images[d_0296[TileX + 1, TileY + 1].F00 - 500], TileX * 2, TileY * 16 + d_6840);
    613:
      if d_6840 = 16 then
        u9_2a9f(d_6D86^.Images[13], TileX * 2, TileY * 16 + d_6840)
      else
        u9_2a9f(d_6D86^.Images[17], TileX * 2, TileY * 16 + d_6840);
    601..650:
      u9_2a9f(d_6D86^.Images[d_0296[TileX + 1, TileY + 1].F00 - 600], TileX * 2, TileY * 16 + d_6840);
    651..700:
      u9_2a9f(d_6D8A^.Images[d_0296[TileX + 1, TileY + 1].F00 - 650], TileX * 2, TileY * 16 + d_6840);
    701..750:
      u9_2a9f(d_6D8E^.Images[d_0296[TileX + 1, TileY + 1].F00 - 700], TileX * 2, TileY * 16 + d_6840);
    751..800:
      u9_2a9f(d_6D92^.Images[d_0296[TileX + 1, TileY + 1].F00 - 750], TileX * 2, TileY * 16 + d_6840);
  end;
  if d_0296[TileX + 1, TileY + 1].F00 = d_681A then
    d_0296[TileX + 1, TileY + 1].F00 := 2;
  if d_0296[TileX + 1, TileY + 1].F00 = d_681A + 1 then
    d_0296[TileX + 1, TileY + 1].F00 := 5;
  if d_0296[TileX + 1, TileY + 1].F00 = d_681A + 2 then
    d_0296[TileX + 1, TileY + 1].F00 := 6;
  if d_0296[TileX + 1, TileY + 1].F00 = d_681A + 3 then
    d_0296[TileX + 1, TileY + 1].F00 := 7;
  if d_0296[TileX + 1, TileY + 1].F00 = 667 then
    d_0296[TileX + 1, TileY + 1].F00 := 8;
  case d_0296[TileX + 1, TileY + 1].F02 of
    0: ;
    1..50:
      u9_0475(d_6D72^.Images[d_0296[TileX + 1, TileY + 1].F02], TileX * 2, TileY * 16 + d_6840);
    100..150:
      u9_0475(d_6D76^.Images[d_0296[TileX + 1, TileY + 1].F02 - 100], TileX * 2, TileY * 16 + d_6840);
    179:
      if d_6840 = 16 then
        u9_0475(d_6D96^.Images[29], TileX * 2, TileY * 16 + d_6840)
      else
        u9_0475(d_6D96^.Images[30], TileX * 2, TileY * 16 + d_6840);
    151..200:
      u9_0475(d_6D96^.Images[d_0296[TileX + 1, TileY + 1].F02 - 150], TileX * 2, TileY * 16 + d_6840);
    201..250:
      u9_0475(d_6D9A^.Images[d_0296[TileX + 1, TileY + 1].F02 - 200], TileX * 2, TileY * 16 + d_6840);
    251..300:
      u9_0475(d_6DAA^.Images[d_0296[TileX + 1, TileY + 1].F02 - 250], TileX * 2, TileY * 16 + d_6840);
    301..350:
      u9_0475(d_6DA2^.Images[d_0296[TileX + 1, TileY + 1].F02 - 300], TileX * 2, TileY * 16 + d_6840);
    351..400:
      u9_0475(d_6DAE^.Images[d_0296[TileX + 1, TileY + 1].F02 - 350], TileX * 2, TileY * 16 + d_6840);
    401..450:
      u9_0475(d_6D7E^.Images[d_0296[TileX + 1, TileY + 1].F02 - 400], TileX * 2, TileY * 16 + d_6840);
    499:
      if d_6840 = 16 then
        u9_0475(d_6D82^.Images[49], TileX * 2, TileY * 16 + d_6840)
      else
        u9_0475(d_6D82^.Images[1], TileX * 2, TileY * 16 + d_6840);
    451..500:
      u9_0475(d_6D82^.Images[d_0296[TileX + 1, TileY + 1].F02 - 450], TileX * 2, TileY * 16 + d_6840);
    501..550:
      u9_0475(d_6D72^.Images[d_0296[TileX + 1, TileY + 1].F02 - 500], TileX * 2, TileY * 16 + d_6840);
    613:
      if d_6840 = 16 then
        u9_0475(d_6D86^.Images[13], TileX * 2, TileY * 16 + d_6840)
      else
        u9_0475(d_6D86^.Images[17], TileX * 2, TileY * 16 + d_6840);
    601..650:
      u9_0475(d_6D86^.Images[d_0296[TileX + 1, TileY + 1].F02 - 600], TileX * 2, TileY * 16 + d_6840);
    651..700:
      u9_0475(d_6D8A^.Images[d_0296[TileX + 1, TileY + 1].F02 - 650], TileX * 2, TileY * 16 + d_6840);
    701..750:
      u9_0475(d_6D8E^.Images[d_0296[TileX + 1, TileY + 1].F02 - 700], TileX * 2, TileY * 16 + d_6840);
    751..800:
      u9_0475(d_6D92^.Images[d_0296[TileX + 1, TileY + 1].F02 - 750], TileX * 2, TileY * 16 + d_6840);
  end;
  case d_0296[TileX + 1, TileY + 1].F04 of
    0: ;
    1..50:
      u9_0475(d_6D72^.Images[d_0296[TileX + 1, TileY + 1].F04], TileX * 2, TileY * 16 + d_6840);
    100..150:
      u9_0475(d_6D76^.Images[d_0296[TileX + 1, TileY + 1].F04 - 100], TileX * 2, TileY * 16 + d_6840);
    179:
      if d_6840 = 16 then
        u9_0475(d_6D96^.Images[29], TileX * 2, TileY * 16 + d_6840)
      else
        u9_0475(d_6D96^.Images[30], TileX * 2, TileY * 16 + d_6840);
    151..200:
      u9_0475(d_6D96^.Images[d_0296[TileX + 1, TileY + 1].F04 - 150], TileX * 2, TileY * 16 + d_6840);
    201..250:
      u9_0475(d_6D9A^.Images[d_0296[TileX + 1, TileY + 1].F04 - 200], TileX * 2, TileY * 16 + d_6840);
    251..300:
      u9_0475(d_6DAA^.Images[d_0296[TileX + 1, TileY + 1].F04 - 250], TileX * 2, TileY * 16 + d_6840);
    301..350:
      u9_0475(d_6DA2^.Images[d_0296[TileX + 1, TileY + 1].F04 - 300], TileX * 2, TileY * 16 + d_6840);
    351..400:
      u9_0475(d_6DAE^.Images[d_0296[TileX + 1, TileY + 1].F04 - 350], TileX * 2, TileY * 16 + d_6840);
    401..450:
      u9_0475(d_6D7E^.Images[d_0296[TileX + 1, TileY + 1].F04 - 400], TileX * 2, TileY * 16 + d_6840);
    499:
      if d_6840 = 16 then
        u9_0475(d_6D82^.Images[49], TileX * 2, TileY * 16 + d_6840)
      else
        u9_0475(d_6D82^.Images[1], TileX * 2, TileY * 16 + d_6840);
    451..500:
      u9_0475(d_6D82^.Images[d_0296[TileX + 1, TileY + 1].F04 - 450], TileX * 2, TileY * 16 + d_6840);
    501..550:
      u9_0475(d_6D72^.Images[d_0296[TileX + 1, TileY + 1].F04 - 500], TileX * 2, TileY * 16 + d_6840);
    613:
      if d_6840 = 16 then
        u9_0475(d_6D86^.Images[13], TileX * 2, TileY * 16 + d_6840)
      else
        u9_0475(d_6D86^.Images[17], TileX * 2, TileY * 16 + d_6840);
    601..650:
      u9_0475(d_6D86^.Images[d_0296[TileX + 1, TileY + 1].F04 - 600], TileX * 2, TileY * 16 + d_6840);
    651..700:
      u9_0475(d_6D8A^.Images[d_0296[TileX + 1, TileY + 1].F04 - 650], TileX * 2, TileY * 16 + d_6840);
    701..750:
      u9_0475(d_6D8E^.Images[d_0296[TileX + 1, TileY + 1].F04 - 700], TileX * 2, TileY * 16 + d_6840);
    751..800:
      u9_0475(d_6D92^.Images[d_0296[TileX + 1, TileY + 1].F04 - 750], TileX * 2, TileY * 16 + d_6840);
  end;
end;

