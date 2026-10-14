{@decls}
type
  TSnapshot = packed record
    B3E: Byte;
    W3F: Integer;
    B41, B42: Byte;
    W43, W45, W47, W49: Integer;
    Bytes: array[1..20] of Byte;
  end;
  TBand = packed record
    First: Byte;
    Rest: array[1..31] of Byte;
  end;
  TScore = string[40];
var
  d_34B0: array[0..57] of Byte;
  d_34EA, d_34EB: Byte;
  d_350A: array[1..25] of TBand;
  d_6B44: array[1..10] of TScore;
  d_6816: Byte;
  d_681C, d_6820, d_682C, d_6830, d_6832: Integer;
  d_6836: Byte;
  d_6838, d_683A, d_683C, d_683E, d_6840: Integer;
  d_6844: array[1..15] of Byte;
  d_6858: Integer;
  d_699A: LongInt;
  d_699E, d_69A0, d_69A2, d_69A4, d_69A6, d_69A8, d_69AA: Integer;
  d_69AC, d_69AD: Byte;
  d_69AE: Integer;
  d_69B0: Byte;
  d_69B2: Integer;
  d_69B4: Byte;
  d_69B6, d_69B8: Integer;
  d_69BA: array[1..20] of Byte;
  d_69CE, d_69CF, d_69D0, d_69D1, d_69D2, d_69D3, d_69D4,
  d_69D5, d_69D6, d_69D7, d_69D8, d_69D9, d_69DA, d_69DB,
  d_69DC, d_69DD, d_69DE, d_69DF, d_69E0: Byte;
  d_69E2, d_69E4, d_69E6: Integer;
  d_69E8, d_69E9, d_69EA, d_69EB, d_69EC, d_69ED, d_69EE,
  d_69EF, d_69F0, d_69F1, d_69F2, d_69F3, d_69F4, d_69F5,
  d_69F6: Byte;
  d_69F8: array[0..24] of Integer;
  d_6A2A: array[0..2] of Integer;
  d_6A30: array[0..6] of Integer;
  d_6A3E, d_6A3F, d_6A40, d_6A41, d_6A42: Byte;
  d_6CDE: array[1..10] of LongInt;
  d_6D18, d_6D1A: Integer;
  d_6D1C: LongInt;
  d_6D20, d_6D22: Integer;
  d_6D26: array[1..20] of Byte;
  d_6D3A, d_6D3C: Integer;
  d_6D3E: TSnapshot;
  d_6D60: Integer;
  d_6D66: Byte;
  d_6EBF, d_6EC0, d_6EC1, d_6EC2, d_6EC3, d_6EC4, d_6EC5,
  d_6EC6, d_6EC7, d_6EC8, d_6EC9, d_6ECA, d_6ECB, d_6ECD: Byte;
  d_70BA: array[0..7] of Integer;
{@stubs}
procedure u9_2f32;
{@body}
procedure u8_0136;
var
  i: Integer;
  value: LongInt;
begin
  for i := 1 to 25 do
    d_350A[i].First := 1;
  d_6838 := 0;
  u9_2f32;
  d_6832 := -1;
  d_683A := 0;
  d_682C := 0;
  d_70BA[6] := 0;
  d_70BA[7] := 0;
  d_70BA[0] := $48;
  d_70BA[1] := $50;
  d_70BA[2] := $4B;
  d_70BA[3] := $4D;
  d_70BA[4] := $38;
  d_70BA[5] := $1D;
  for i := 1 to 10 do
  begin
    case i of
      1: d_6B44[i] := 'James Bond              200000';
      2: d_6B44[i] := 'Matt Helm               190000';
      3: d_6B44[i] := 'Flint                   180000';
      4: d_6B44[i] := 'Jack Ryan               170000';
      5: d_6B44[i] := 'Jim Phelps              160000';
      6: d_6B44[i] := 'Columbo                 150000';
      7: d_6B44[i] := 'Maxwell Smart           140000';
      8: d_6B44[i] := 'Frank Drebin            130000';
      9: d_6B44[i] := 'Underdog                120000';
      10: d_6B44[i] := 'The A Team              110000';
    end;
    value := i;
    d_6CDE[i] := 200000 - (value - 1) * 10000;
  end;
  d_6EBF := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6EC5 := 0;
  d_6EC6 := 0;
  d_6EC7 := 0;
  d_6EC8 := 0;
  d_6EC9 := 0;
  d_6EC2 := 0;
  d_6EC1 := 0;
  d_6ECD := 0;
  d_6EC0 := 0;
  d_681C := 1;
  d_6830 := 0;
  d_6840 := $10;
  d_683E := 0;
  d_683C := 0;
  d_6820 := 0;
  d_6836 := 1;
  d_699A := 0;
  d_699E := 1;
  d_6858 := 5;
  d_69A2 := 1;
  d_69A0 := 0;
  for i := 1 to 15 do
    d_6844[i] := 0;
  d_69A4 := 0;
  d_69A6 := 0;
  d_69A8 := 0;
  d_69AD := 0;
  d_69AA := 0;
  d_69AC := 0;
  d_69B0 := 0;
  d_69AE := 0;
  d_69B2 := 0;
  d_69EF := 0;
  d_69EC := 0;
  d_69ED := 0;
  d_69E8 := 0;
  d_69E9 := 0;
  d_69EA := 0;
  d_69EB := 0;
  d_69F3 := 0;
  d_69F4 := 0;
  d_69EE := 0;
  d_69B4 := 0;
  d_69B6 := 0;
  d_69B8 := 1;
  d_69F0 := 0;
  d_69F1 := 0;
  d_69F2 := 1;
  for i := 1 to 20 do
    d_69BA[i] := 0;
  d_69F5 := 0;
  d_69F6 := $23;
  d_6A3E := 0;
  d_6A3F := 8;
  d_6A40 := 3;
  d_6A41 := 0;
  d_6A42 := 0;
  d_69CE := 0;
  d_6816 := 0;
  d_69D4 := 0;
  d_69D5 := 0;
  d_69D6 := 0;
  d_69D9 := 0;
  d_69DA := 0;
  d_69DB := 0;
  d_69DC := 0;
  d_69DD := 0;
  d_69DE := 0;
  d_69DF := 0;
  d_69CF := 0;
  d_69D0 := 0;
  d_69D1 := 0;
  d_69D2 := 0;
  d_69D3 := 0;
  d_69D7 := 0;
  d_69D8 := 0;
  d_69E0 := 0;
  d_69E2 := 0;
  d_69E4 := 0;
  d_69E6 := 0;
  d_6D18 := 0;
  d_6D1A := 0;
  d_6D1C := d_699A;
  d_6D20 := d_699E;
  d_6D22 := d_6858;
  for i := 1 to 20 do
    d_6D26[i] := d_6844[i];
  d_6D3A := d_69A4;
  d_6D3C := d_69A6;
  d_6D3E.B3E := d_69AD;
  d_6D3E.W3F := d_69AA;
  d_6D3E.B41 := d_69AC;
  d_6D3E.B42 := d_69B0;
  d_6D3E.W43 := d_69AE;
  d_6D3E.W45 := d_69B2;
  d_6D3E.W47 := d_69B6;
  d_6D3E.W49 := d_69B8;
  for i := 1 to 20 do
    d_6D3E.Bytes[i] := d_69BA[i];
  d_6D60 := 0;
  d_34B0[0] := 0;
  d_34B0[1] := 8;
  d_34B0[2] := 8;
  d_34B0[3] := 8;
  d_34B0[4] := 4;
  d_34B0[5] := 4;
  d_34B0[6] := 2;
  d_34B0[7] := 2;
  d_34B0[8] := 2;
  d_34B0[9] := 1;
  d_34B0[10] := 1;
  d_34B0[11] := 2;
  d_34B0[12] := 2;
  d_34B0[13] := 2;
  d_34B0[14] := 4;
  d_34B0[15] := 4;
  d_34B0[16] := 8;
  d_34B0[17] := 8;
  d_34B0[18] := 8;
  d_34EA := $12;
  d_34B0[20] := 0;
  d_34B0[21] := 8;
  d_34B0[22] := 8;
  d_34B0[23] := 6;
  d_34B0[24] := 6;
  d_34B0[25] := 4;
  d_34B0[26] := 4;
  d_34B0[27] := 4;
  d_34B0[28] := 4;
  d_34B0[29] := 4;
  d_34B0[30] := 4;
  d_34B0[31] := 2;
  d_34B0[32] := 2;
  d_34B0[33] := 2;
  d_34B0[34] := 2;
  d_34B0[35] := 2;
  d_34B0[36] := 1;
  d_34B0[37] := 1;
  d_34B0[38] := 1;
  d_34B0[39] := 1;
  d_34B0[40] := 0;
  d_34B0[41] := 0;
  d_34B0[42] := 0;
  d_34B0[43] := 2;
  d_34B0[44] := 2;
  d_34B0[45] := 2;
  d_34B0[46] := 2;
  d_34B0[47] := 4;
  d_34B0[48] := 4;
  d_34B0[49] := 4;
  d_34B0[50] := 4;
  d_34B0[51] := 4;
  d_34B0[52] := 4;
  d_34B0[53] := 4;
  d_34B0[54] := 6;
  d_34B0[55] := 6;
  d_34B0[56] := 8;
  d_34B0[57] := 8;
  d_34EB := $25;
  d_69F8[0] := -8;
  d_69F8[1] := -8;
  d_69F8[2] := -8;
  d_69F8[3] := -8;
  d_69F8[4] := -8;
  d_69F8[5] := -8;
  d_69F8[6] := -8;
  d_69F8[7] := -8;
  d_69F8[8] := -8;
  d_69F8[9] := -8;
  d_69F8[10] := -8;
  d_69F8[11] := -8;
  d_69F8[12] := -8;
  d_69F8[13] := -8;
  d_69F8[14] := -8;
  d_69F8[15] := -6;
  d_69F8[16] := -6;
  d_69F8[17] := -6;
  d_69F8[18] := -6;
  d_69F8[19] := -6;
  d_69F8[20] := -6;
  d_69F8[21] := -4;
  d_69F8[22] := -4;
  d_69F8[23] := -4;
  d_69F8[24] := -4;
  d_6A2A[0] := 0;
  d_6A2A[1] := 0;
  d_6A2A[2] := 0;
  d_6A30[0] := 4;
  d_6A30[1] := 4;
  d_6A30[2] := 8;
  d_6A30[3] := 8;
  d_6A30[4] := 8;
  d_6A30[5] := 8;
  d_6A30[6] := 8;
  d_6D66 := 0;
end;
















