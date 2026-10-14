{@decls}
var
  d_6814: Word;
  d_6824: Word;
{@stubs}
procedure u3_079e;
function u3_1601(Value: Byte): Byte;
{@body}
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
