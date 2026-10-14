program Ints;
{$S-}{$R-}{$I-}{$B-}
var b: Byte; s: ShortInt; i: Integer; w: Word; l: LongInt; n: Integer;
begin
  b := 255; s := -1; i := -1; w := 65535; l := 100000;
  Writeln(b+b, ' ', s+b, ' ', i+w, ' ', w+w);
  Writeln(b* b, ' ', w* w, ' ', i* w, ' ', l+i);
  Writeln(i<w, ' ', w>i, ' ', s<b, ' ', w=l, ' ', w<l);
  Writeln(i div 2, ' ', i mod 2, ' ', w div 2, ' ', w mod 2);
  Writeln(i div w, ' ', w div i, ' ', i mod w, ' ', w mod i);
  Writeln(w shr 1, ' ', i shr 1, ' ', b shl 8, ' ', l shl 16);
  Writeln(Integer(w), ' ', LongInt(w), ' ', Word(i), ' ', Byte(w));
  Inc(b); Inc(s); Inc(w); Dec(i, 32767);
  Writeln(b, ' ', s, ' ', w, ' ', i);
  Writeln(Ord(Chr(255)), ' ', Lo(l), ' ', Hi(l), ' ', Succ(b));
  b := 253; w := 255; n := 0;
  for b := b to w do Inc(n);
  Writeln(n, ' ', b);
  w := 65533; l := 65535; n := 0;
  for w := w to l do Inc(n);
  Writeln(n, ' ', w);
end.
