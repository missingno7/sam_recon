program Files;
{$S-}{$R-}{$I-}{$B-}
type R = packed record b: Byte; i: Integer end;
var f: file of R; a: R; c: Integer;
begin
  Assign(f,'PROBE.DAT'); Rewrite(f); c:=IOResult; Writeln(c);
  a.b:=255; a.i:=-32768; Write(f,a);
  a.b:=1; a.i:=1234; Write(f,a); Close(f);
  Reset(f); Writeln(IOResult,' ',FileSize(f),' ',FilePos(f));
  Read(f,a); Writeln(a.b,' ',a.i,' ',Eof(f));
  Read(f,a); Writeln(a.b,' ',a.i,' ',Eof(f));
  Read(f,a); Writeln(IOResult); Close(f);
  Assign(f,'NOFILE.DAT'); Reset(f); Writeln(IOResult);
end.
