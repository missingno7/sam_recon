{@decls}
type
  TRegisterBlock = record
    case Integer of
      0: (AX, BX, CX, DX, BP, SI, DI, DS, ES, Flags: Word);
      1: (AL, AH, BL, BH, CL, CH, DL, DH: Byte);
  end;
var
  d_sam2_02A4: TRegisterBlock;
  d_sam2_02B8: Word;
  d_sam2_02BA: Byte;
const
  d_sam2_0000: array[0..13] of Byte = (5, 0, 1, 5, 3, 3, 5, 4, 4, 5, 1, 1, 1, 0);
{@stubs}

{@body}
procedure p_sam2_107a;
begin
  d_sam2_02BA := 1;
  d_sam2_02A4.AH := $0F;
  Intr($10, Registers(d_sam2_02A4));
  d_sam2_02B8 := d_sam2_02A4.AL and $7F;
  d_sam2_02A4.AX := $1A00;
  Intr($10, Registers(d_sam2_02A4));
  if d_sam2_02A4.AL = $1A then
  begin
    if d_sam2_02A4.BL <> $FF then
      d_sam2_02BA := d_sam2_0000[d_sam2_02A4.BL];
  end
  else
  begin
    d_sam2_02A4.AH := $12;
    d_sam2_02A4.BL := $10;
    Intr($10, Registers(d_sam2_02A4));
    if d_sam2_02A4.BL <> $10 then
      d_sam2_02BA := 3;
  end;
end;
