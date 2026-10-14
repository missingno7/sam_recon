program Heap;
{$S-}{$R-}{$I-}{$B-}
type PByte = ^Byte;
var p,q,r,org: PByte; markptr: Pointer; n: LongInt;
begin
  Mark(markptr); org:=PByte(markptr); n:=MemAvail;
  Writeln(MaxAvail=MemAvail);
  GetMem(p,1); Writeln(n-MemAvail,' ',Ofs(p^),' ',Seg(p^)-Seg(org^));
  GetMem(q,17); Writeln(n-MemAvail,' ',Ofs(q^),' ',Seg(q^)-Seg(org^));
  GetMem(r,5); Writeln(n-MemAvail,' ',Ofs(r^),' ',Seg(r^)-Seg(org^));
  FreeMem(q,17); Writeln(n-MemAvail);
  GetMem(q,2); Writeln(n-MemAvail,' ',Ofs(q^),' ',Seg(q^)-Seg(org^));
  FreeMem(p,1); FreeMem(q,2); FreeMem(r,5); Writeln(n-MemAvail);
  Release(markptr); Writeln(n-MemAvail);
end.
