program EraseLive;
{$S-}{$R-}{$I-}{$B-}
var f: file of Byte; value: Byte;
begin
  Assign(f,'ERSLIVE.DAT'); Rewrite(f); value:=42; Write(f,value); Close(f);
  Reset(f); Erase(f); Writeln(IOResult);
  Seek(f,0); Read(f,value); Writeln(value,' ',IOResult);
  Close(f); Writeln(IOResult);
end.
