program FarField;
{$S-}{$R-}{$I-}{$B-}
type TRec = record first, second: Integer; last: Byte end;
     PRec = ^TRec;
var p: PRec;
begin
  { The second field's address wraps into DS:0. No scalar spans 0xFFFF. }
  p:=Ptr(DSeg,$FFFE);
  p^.first:=1234; p^.second:=-2345; p^.last:=67;
  Writeln(p^.first,' ',p^.second,' ',p^.last);
  Writeln(MemW[DSeg:$FFFE],' ',MemW[DSeg:0],' ',Mem[DSeg:2]);
end.
