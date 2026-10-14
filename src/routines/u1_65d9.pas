{@decls}
type
  TCell = record
    A, B, C: Word;
    D, E: Byte;
  end;
var
  d_34EE: Word;
  d_34F0: Word;
  d_681C: Integer;
{@stubs}
{@body}
function u1_65d9(xOffset, yOffset: Word): Boolean;
var
  x1: Word;
  y1: Word;
  x2: Word;
  y2: Word;
begin
  x1 := ((d_34EE + xOffset + 3) shr 4) + 1;
  x2 := ((d_34EE + xOffset + 12) shr 4) + 1;
  y1 := ((d_34F0 + yOffset) shr 4) + 1;
  y2 := ((d_34F0 + yOffset + 15) shr 4) + 1;

  if (d_0296[x1, y1].D <> 0) or
     (d_0296[x2, y1].D <> 0) or
     (d_0296[x1, y2].D <> 0) or
     (d_0296[x2, y2].D <> 0) then
  begin
    u1_65d9 := False;
    if d_681C > 1 then
      d_681E := 0;
  end
  else
    u1_65d9 := True;
end;
