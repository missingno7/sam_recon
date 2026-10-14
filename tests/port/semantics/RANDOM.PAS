program Rng;
{$S-}{$R-}{$I-}{$B-}
var i: Integer;
begin
  RandSeed:=0;
  for i:=1 to 6 do Writeln(Random(100),' ',RandSeed);
  RandSeed:=-1; Writeln(Random(0),' ',RandSeed);
  Writeln(Random(65535),' ',RandSeed);
end.
