program StrByte;
{$S-}{$R-}{$I-}{$B-}
var s: String; i: Integer;
begin
  { These pairs form C trigraphs if emitted without question-mark escaping. }
  s:='??/??''??(??)??!??<??>??=??-';
  for i:=1 to Length(s) do Write(Ord(s[i]),' ');
  Writeln;
  s:=#0#1#9#10#13#127#128#255'"\A';
  for i:=1 to Length(s) do Write(Ord(s[i]),' ');
  Writeln;
end.
