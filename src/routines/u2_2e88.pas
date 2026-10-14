{@decls}
var
  d_681A: Word;
  d_681C: Integer;
  d_6834: Integer;
  d_6842: Byte;
  d_69BA: array[1..20] of Byte;
{@stubs}
procedure u2_2c6e(X, Y, Tile, A, B: Integer; C, D, Foreground: Byte);
{@body}
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
