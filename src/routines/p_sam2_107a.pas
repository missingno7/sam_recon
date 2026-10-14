{@decls}
type
  TRegisterBlock = record
    case Integer of
      0: (AX, BX, CX, DX, BP, SI, DI, DS, ES, Flags: Word);
      1: (AL, AH, BL, BH, CL, CH, DL, DH: Byte);
  end;
const
  d_0000: array[0..64] of Byte = (5, 0, 1, 5, 3, 3, 5, 4, 4, 5, 1, 1, 1, 0,
    32, 80, 67, 88, 32, 80, 114, 111, 103, 114, 97, 109, 109, 101, 114, 39,
    115, 32, 84, 111, 111, 108, 107, 105, 116, 32, 51, 46, 53, 54, 32, 0,
    32, 67, 111, 112, 121, 114, 105, 103, 104, 116, 32, 40, 99, 41, 32,
    71, 101, 110, 117);
var
  d_sam2_02A4: TRegisterBlock;
  d_sam2_02B8: Word;
  d_sam2_02BA: Byte;
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
      d_sam2_02BA := d_0000[d_sam2_02A4.BL];
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
