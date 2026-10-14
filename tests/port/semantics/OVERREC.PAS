program OverRec;
{$S-}{$R-}{$I-}{$B-}
type TRec = record tag: Byte; value: Integer end;
     TVariant = record
       case Boolean of
         True: (wordValue: Word);
         False: (lowByte, highByte: Byte)
     end;
var records: array[1..2] of TRec; neighbour: TRec;
    v: TVariant; index: Integer;
procedure Change(var item: TRec);
begin item.tag:=7; item.value:=-123 end;
begin
  records[1].tag:=1; records[1].value:=11;
  records[2].tag:=2; records[2].value:=22;
  neighbour.tag:=3; neighbour.value:=33;
  index:=3; records[index].tag:=4; records[index].value:=44;
  Writeln(neighbour.tag,' ',neighbour.value,' ',SizeOf(TRec));
  Change(records[index]); Writeln(neighbour.tag,' ',neighbour.value);
  with records[index] do begin tag:=8; value:=99 end;
  Writeln(neighbour.tag,' ',neighbour.value);
  v.wordValue:=$1234; Writeln(v.lowByte,' ',v.highByte);
  v.highByte:=$AB; Writeln(v.wordValue);
end.
