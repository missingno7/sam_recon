program ForZero;
{$S-}{$R-}{$I-}{$B-}
var I, Lo, Hi: Integer; B: Byte;
begin
  Lo := 1; Hi := 0; I := 123;
  for I := Lo to Hi do Write('bad');
  Writeln(I);
  I := 456;
  for I := Hi downto Lo do Write('bad');
  Writeln(I);
  I := 789;
  for I := 9 to 5 do Write('bad');
  Writeln(I);
  B := 77;
  for B := 4 to 2 do Write('bad');
  Writeln(B);
  I := 321;
  for I := 1 to 3 do Write(I);
  Writeln(' ', I);
end.
