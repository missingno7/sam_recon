{@decls}
type
  TMapCell = record
    A, B, C: Word;
    D, E: Byte;
  end;
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
