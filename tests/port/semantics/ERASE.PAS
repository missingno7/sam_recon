program EraseTest;
{$S-}{$R-}{$I-}{$B-}
var f: file of Byte;
begin
  Assign(f,'ERSPROBE.DAT'); Rewrite(f); Erase(f); Writeln(IOResult);
  Close(f); Writeln(IOResult);
  Assign(f,'ersprobe.dat'); Erase(f); Writeln(IOResult);
  Erase(f); Writeln(IOResult);
end.
