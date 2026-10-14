program UnaryTest;
{$S-}{$R-}{$I-}{$B-}
var w: Word; i: Integer; b: Byte; l: LongInt;
begin
  w:=60000; i:=-32768; b:=255; l:=-2147483647;
  Writeln(+w,' ',-w,' ',not w,' ',not b,' ',-i);
  Writeln(w+1,' ',w+(-1),' ',w div (-1),' ',+w div 2);
  Writeln(l+l,' ',l*l,' ',-l,' ',l shr 31);
  b:=255; Writeln(Succ(b),' ',Pred(Byte(0)));
  i:=32767; Writeln(Succ(i),' ',Pred(Integer(-32768)));
end.
