program Sets;
{$S-}{$R-}{$I-}{$B-}
type Small = set of 10..30;
var a,b: Small; i: Integer;
begin
  a := [10,15..20,30]; b := [15,30];
  Writeln(SizeOf(a));
  Writeln(10 in a,' ',9 in a,' ',b<=a,' ',a=b);
  a := (a-b)+[11]; b := a*[10..16];
  for i:=0 to 31 do if i in b then Write(i,' ');
  Writeln;
end.
