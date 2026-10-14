{@decls}
type
  TByte20 = array[1..20] of Byte;
  TSnapshotTail = packed record
    F3A: Word;
    F3C: Word;
    F3E: Byte;
    F3F: Word;
    F41: Byte;
    F42: Byte;
    F43: Word;
    F45: Word;
    F47: Word;
    F49: Word;
    F4B: TByte20;
  end;
var
  d_34EE: Word;
  d_34F0: Word;
  d_6844: TByte20;
  d_6858: Word;
  d_699A: Pointer;
  d_699E: Word;
  d_69A2: Word;
  d_69A4: Word;
  d_69A6: Word;
  d_69AA: Word;
  d_69AC: Byte;
  d_69AD: Byte;
  d_69AE: Word;
  d_69B0: Byte;
  d_69B2: Word;
  d_69B6: Word;
  d_69B8: Word;
  d_69BA: TByte20;
  d_69DC: Byte;
  d_6D18: Word;
  d_6D1A: Word;
  d_6D1C: Pointer;
  d_6D20: Word;
  d_6D22: Word;
  d_6D24: Word;
  d_6D26: TByte20;
  d_6D3A: TSnapshotTail;
  d_6D5F: Byte;
{@stubs}
{@body}
procedure u3_3cb8;
var
  I: Integer;
begin
  d_6D18 := d_34EE;
  d_6D1A := d_34F0;
  d_6D1C := d_699A;
  d_6D20 := d_699E;
  d_6D22 := d_6858;
  d_6D24 := d_69A2;
  for I := 1 to 20 do
    d_6D26[I] := d_6844[I];
  d_6D3A.F3A := d_69A4;
  d_6D3A.F3C := d_69A6;
  d_6D3A.F3E := d_69AD;
  d_6D3A.F3F := d_69AA;
  d_6D3A.F41 := d_69AC;
  d_6D3A.F42 := d_69B0;
  d_6D3A.F43 := d_69AE;
  d_6D3A.F45 := d_69B2;
  d_6D3A.F47 := d_69B6;
  d_6D3A.F49 := d_69B8;
  for I := 1 to 20 do
    d_6D3A.F4B[I] := d_69BA[I];
  d_6D5F := d_69DC;
end;
