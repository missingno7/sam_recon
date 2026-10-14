{@decls}

{@stubs}

{@body}
function u1_65d9(xOffset, yOffset: Word): Boolean;
var
  x1: Word;
  y1: Word;
  x2: Word;
  y2: Word;
begin
  x1 := ((Word(d_34EC[1].X) + xOffset + 3) shr 4) + 1;
  x2 := ((Word(d_34EC[1].X) + xOffset + 12) shr 4) + 1;
  y1 := ((Word(d_34EC[1].Y) + yOffset) shr 4) + 1;
  y2 := ((Word(d_34EC[1].Y) + yOffset + 15) shr 4) + 1;

  if (d_0296[x1, y1].Solid <> 0) or
     (d_0296[x2, y1].Solid <> 0) or
     (d_0296[x1, y2].Solid <> 0) or
     (d_0296[x2, y2].Solid <> 0) then
  begin
    u1_65d9 := False;
    if d_681C > 1 then
      d_681E := 0;
  end
  else
    u1_65d9 := True;
end;
