program BiosReference;
uses Dos;
type TState = array[1..64] of Byte;
var R: Registers; State: TState; F: file;
    Offs, Segm: Word;
begin
  FillChar(R,SizeOf(R),0); FillChar(State,SizeOf(State),0);
  R.AX := $1B00; R.BX := 0; R.ES := Seg(State); R.DI := Ofs(State);
  Intr($10,R); Writeln('STATE ',R.AX,' ',R.BX,' ',R.CX,' ',R.Flags);
  Assign(F,'STATE.BIN'); Rewrite(F,1); BlockWrite(F,State,64); Close(F);
  FillChar(R,SizeOf(R),0); R.AX := $1C00; R.CX := $FFFF;
  Intr($10,R); Writeln('SAVE ',R.AX,' ',R.BX,' ',R.CX,' ',R.Flags);
  FillChar(R,SizeOf(R),0); Intr($11,R); Writeln('EQUIP ',R.AX);
  Writeln('BDA ',Mem[$40:$87],' ',Mem[$40:$88],' ',Mem[$40:$89],' ',Mem[$40:$8A]);
  Offs := MemW[0:$487]; Segm := MemW[0:$489];
  Writeln('INDIRECT ',Offs,' ',Segm,' ',Mem[Segm:Offs]);
  Assign(F,'LOWRAM.BIN'); Rewrite(F,1); BlockWrite(F,Mem[0:0],65535); Close(F);
end.
