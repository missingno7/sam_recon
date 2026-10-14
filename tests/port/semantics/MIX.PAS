program Mix;
{$S-}{$R-}{$I-}{$B-}
var b: Byte; s: ShortInt; i: Integer; w: Word; l: LongInt;
begin
  b := 200; s := -100; i := -30000; w := 60000; l := -1;
  Writeln(b*w,' ',s*w,' ',w+1,' ',w+10000,' ',w-1,' ',w-b);
  Writeln(w+s,' ',w+i,' ',w+(-1),' ',w+(-30000));
  Writeln(w<i,' ',i>w,' ',w<b,' ',w<s,' ',w>l);
  Writeln(w div b,' ',w div s,' ',w mod s);
  Writeln(b*b,' ',b+s,' ',s*s,' ',i+i,' ',i*2);
  Writeln(w shl 1,' ',w shr 16,' ',w shl 16,' ',i shr 16);
end.
