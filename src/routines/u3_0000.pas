{@decls}
type
  PByte = ^Byte;
type
  PPointer = ^Pointer;
{@stubs}

{@body}
function u3_0000: Char;
var
  prefixByte: Byte;
  regs: Registers;
  shift: Word;
  pad: array[1..6] of Byte;
  egaFlags: Byte;
  adapter: Char;
  buffer: array[1..64] of Byte;
begin
  regs.ES := Seg(buffer);
  regs.DI := Ofs(buffer);
  regs.AX := $1B00;
  regs.BX := 0;
  Intr($10, regs);
  if Lo(regs.AX) = $1B then
  begin
    adapter := 'V';
  end
  else
  begin
    Intr($11, regs);
    shift := (Lo(regs.AX) and $30) shr 4;
    egaFlags := PByte(PPointer(Ptr(0, $0487))^)^;
    if egaFlags <> 0 then
      adapter := 'E'
    else
      adapter := 'U';
  end;
  u3_0000 := adapter;
end;
