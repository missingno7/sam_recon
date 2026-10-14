program TextIO;
{$S-}{$R-}{$I-}{$B-}
var f: Text; s: String[5]; i,c: Integer; ch: Char;
begin
  Assign(f,'TEXTPROB.DAT'); Rewrite(f); Writeln(IOResult);
  Writeln(f,123:6,' ','abcdef'); Writeln(f,'-42 tail'); Close(f);
  Reset(f); Read(f,i); Readln(f,s); Writeln(i,' [',s,'] ',Length(s));
  Read(f,i); Read(f,ch); Readln(f,s); Writeln(i,' ',Ord(ch),' [',s,']');
  Writeln(Eof(f)); Read(f,ch); c:=IOResult; Writeln(Ord(ch),' ',c); Close(f);
end.
