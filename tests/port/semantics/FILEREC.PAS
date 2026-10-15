program FileRec;
{$S-}{$R-}{$I-}{$B-}
type Bytes=array[0..255] of Byte;
var f:file of Integer; t:Text; b:Bytes; i:Integer; s:String;
procedure FDump;
begin
  Move(f,b,128);
  Writeln(b[0]+256*Word(b[1]),' ',b[2]+256*Word(b[3]),' ',b[4]+256*Word(b[5]),' ',b[60]);
end;
procedure TDump;
begin
  Move(t,b,256);
  Writeln(b[0]+256*Word(b[1]),' ',b[2]+256*Word(b[3]),' ',b[4]+256*Word(b[5]),' ',
    b[8]+256*Word(b[9]),' ',b[10]+256*Word(b[11]),' ',b[128],' ',b[129]);
end;
begin
  FillChar(f,SizeOf(f),165); Assign(f,'FREC.DAT'); FDump;
  Rewrite(f); FDump; i:=1234; Write(f,i); Close(f); FDump;
  Reset(f); FDump; Read(f,i); Writeln(i,' ',Eof(f)); Close(f);
  Assign(f,'MISSING.DAT'); Reset(f); Assign(f,'FREC.DAT'); i:=IOResult;
  Move(f,b,128); Writeln(i,' ',b[48],' ',b[49],' ',b[50],' ',b[51]);
  FillChar(t,SizeOf(t),165); Assign(t,'TREC.DAT'); TDump;
  Rewrite(t); Write(t,'AB'); TDump; Writeln(t); TDump; Close(t); TDump;
  Reset(t); Writeln(Eof(t)); TDump; Readln(t,s); Writeln(s); TDump; Close(t);
end.
