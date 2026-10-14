program Constants;
{$S-}{$R-}{$I-}{$B-}
var i: Integer; w: Word; s: String;
begin
  Writeln(1 shl 15,' ',65535+1,' ',32767+1,' ',not 255);
  Writeln(32767*2,' ',65535*2,' ',-Word(60000),' ',not Byte(255));
  i:=-1; w:=60000;
  Writeln(i+60000,' ',i*60000,' ',w+(-1),' ',w<(-1));
  Str(123:300,s); Writeln(Length(s),' [',Copy(s,250,6),']');
end.
