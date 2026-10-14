{@decls}
type
  TLevelRow = array[1..42] of Char;
  TCell = record
    a, b, c: Word;
    solid, flag: Byte;
  end;
  TActor = record
    state: Word;
    x, y, oldX, oldY: Integer;
    phase, f12, f14, f16, f18: Word;
    sprite: Word;
    dx, dy: Integer;
    speed, f28: Word;
    flag1, flag2: Byte;
  end;
  TSpriteImage = array[1..160] of Byte;
  TSpriteBank = record
    header: array[1..3] of Byte;
    images: array[1..100] of TSpriteImage;
  end;
  PSpriteBank = ^TSpriteBank;
var
  d_34EC: array[1..25] of TActor;
  d_681C: Integer;
  d_682E: Word;
  d_6D18: Word;
  d_6D1A: Word;
  d_6D7A: PSpriteBank;
  d_6D7E: PSpriteBank;
  d_6D82: PSpriteBank;
  d_6D8A: PSpriteBank;
  d_6DAE: PSpriteBank;
{@stubs}
procedure u2_2c6e(x, y: Integer; a, b, c: Integer; solid, flag, overlay: Boolean);
procedure u2_2e88(x, y: Integer; var symbol: string);
procedure u2_3a91(x, y: Integer; var symbol: string; overlay: Boolean);
procedure u9_19f9(var sprite; x, y: Word);
{@body}
procedure u2_68a9(rowIndex: Integer; row: TLevelRow);
var
  col: Integer;
  symbol: string;
  savedCol, savedRow: Integer;
  overlay: Boolean;
begin
  if row[1] <> '*' then
  begin
    overlay := False;
    for col := 1 to 40 do
    begin
      d_0296[col, rowIndex + 1].a := 0;
      d_0296[col, rowIndex + 1].b := 0;
      d_0296[col, rowIndex + 1].c := 0;
      d_0296[col, rowIndex + 1].solid := 0;
      d_0296[col, rowIndex + 1].flag := 0;
    end;
  end
  else
    overlay := True;
  for col := 0 to 39 do
  begin
    { 697F } MemW[0:1052] := MemW[0:1050];
    { 6993 } symbol := row[(col + 1)];
    { 69B7 } if symbol = ' ' then
    begin
      { 69C9 } if not overlay then
      begin
        { 69D0 } u2_2c6e(col, rowIndex, 2, 0, 0, False, False, overlay);
      end;
    end;
    { 69EF } if d_681C > 1 then
    begin
      { 69F9 } if symbol = '1' then
      begin
        { 6A0B } u2_2c6e(col, rowIndex, 1, 0, 0, True, False, overlay);
      end;
      { 6A2A } if symbol = '2' then
      begin
        { 6A3C } u2_2c6e(col, rowIndex, 3, 0, 0, True, False, overlay);
      end;
      { 6A5B } if symbol = '3' then
      begin
        { 6A6D } u2_2c6e(col, rowIndex, 4, 0, 0, True, False, overlay);
      end;
      { 6A8C } if symbol = '5' then
      begin
        { 6A9E } u2_2c6e(col, rowIndex, 5, 0, 0, False, False, overlay);
      end;
      { 6ABD } if symbol = '6' then
      begin
        { 6ACF } u2_2c6e(col, rowIndex, 6, 0, 0, False, False, overlay);
      end;
      { 6AEE } if symbol = '7' then
      begin
        { 6B00 } u2_2c6e(col, rowIndex, 7, 0, 0, False, False, overlay);
      end;
      { 6B1F } if symbol = #30 then
      begin
        { 6B31 } u2_2c6e(col, rowIndex, 8, 0, 0, False, False, overlay);
      end;
      { 6B50 } if symbol = 'w' then
      begin
        { 6B62 } u2_2c6e(col, (rowIndex - 1), 2, 0, 179, True, False, overlay);
        { 6B84 } u2_2c6e(col, rowIndex, 2, 0, 183, False, False, overlay);
      end;
      { 6BA4 } if symbol = #1 then
      begin
        { 6BB6 } u2_2c6e(col, rowIndex, 2, 0, 619, False, False, overlay);
      end;
      { 6BD6 } if symbol = #2 then
      begin
        { 6BE8 } u2_2c6e(col, rowIndex, 2, 161, 0, False, False, overlay);
      end;
      { 6C08 } if symbol = #3 then
      begin
        { 6C1A } u2_2c6e(col, rowIndex, 2, 162, 0, False, False, overlay);
      end;
      { 6C3A } if symbol = #4 then
      begin
        { 6C4C } u2_2c6e(col, rowIndex, 2, 155, 0, False, False, overlay);
      end;
      { 6C6C } if symbol = #6 then
      begin
        { 6C7E } u2_2c6e(col, rowIndex, 2, 158, 0, False, False, overlay);
      end;
      { 6C9E } if symbol = #5 then
      begin
        { 6CB0 } u2_2c6e((col - 1), rowIndex, 156, 0, 0, False, True, overlay);
        { 6CD1 } u2_2c6e(col, rowIndex, 157, 0, 0, False, True, overlay);
      end;
      { 6CF0 } if symbol = #7 then
      begin
        { 6D02 } u2_2c6e(col, rowIndex, 2, 174, 0, False, False, overlay);
      end;
      { 6D22 } if symbol = #8 then
      begin
        { 6D34 } u2_2c6e((col - 1), rowIndex, 2, 181, 0, False, True, overlay);
        { 6D56 } u2_2c6e(col, rowIndex, 2, 182, 0, False, True, overlay);
      end;
      { 6D76 } if symbol = #12 then
      begin
        { 6D88 } u2_2c6e((col - 1), rowIndex, 2, 185, 0, False, True, overlay);
        { 6DAA } u2_2c6e(col, rowIndex, 2, 186, 0, False, True, overlay);
      end;
      { 6DCA } if symbol = #11 then
      begin
        { 6DDC } u2_2c6e(col, rowIndex, 2, 178, 0, False, True, overlay);
      end;
      { 6DFC } if symbol = #14 then
      begin
        { 6E0E } u2_2c6e(col, rowIndex, 2, 733, 0, False, False, overlay);
      end;
      { 6E2E } if symbol = #15 then
      begin
        { 6E40 } u2_2c6e(col, rowIndex, 2, 734, 0, False, False, overlay);
      end;
      { 6E60 } if symbol = #16 then
      begin
        { 6E72 } u2_2c6e(col, rowIndex, 2, 735, 0, False, False, overlay);
      end;
      { 6E92 } if symbol = #17 then
      begin
        { 6EA4 } u2_2c6e(col, rowIndex, 2, 737, 0, False, False, overlay);
      end;
      { 6EC4 } if symbol = #18 then
      begin
        { 6ED6 } u2_2c6e(col, rowIndex, 2, 741, 0, False, False, overlay);
      end;
      { 6EF6 } if symbol = #19 then
      begin
        { 6F08 } u2_2c6e(col, rowIndex, 2, 743, 0, False, False, overlay);
      end;
      { 6F28 } if symbol = #20 then
      begin
        { 6F3A } u2_2c6e(col, (rowIndex - 1), 2, 745, 0, False, False, overlay);
        { 6F5C } u2_2c6e(col, rowIndex, 2, 749, 0, False, False, overlay);
      end;
      { 6F7C } if symbol = #21 then
      begin
        { 6F8E } u2_2c6e(col, rowIndex, 2, 746, 0, False, False, overlay);
      end;
      { 6FAE } if symbol = #22 then
      begin
        { 6FC0 } u2_2c6e(col, rowIndex, 2, 750, 0, False, False, overlay);
      end;
      { 6FE0 } if symbol = #23 then
      begin
        { 6FF2 } u2_2c6e(col, rowIndex, 2, 677, 0, False, False, overlay);
      end;
      { 7012 } if symbol = #24 then
      begin
        { 7024 } u2_2c6e(col, rowIndex, 2, 678, 0, False, False, overlay);
      end;
      { 7044 } if symbol = #25 then
      begin
        { 7056 } u2_2c6e(col, (rowIndex - 1), 2, 251, 0, False, True, overlay);
        { 7078 } u2_2c6e(col, rowIndex, 2, 255, 0, False, False, overlay);
      end;
      { 7098 } if symbol = #27 then
      begin
        { 70AD } u2_2c6e((col - 1), (rowIndex - 1), 2, 252, 0, False, True, overlay);
        { 70D1 } u2_2c6e(col, (rowIndex - 1), 2, 253, 0, False, True, overlay);
        { 70F3 } u2_2c6e((col - 1), rowIndex, 2, 256, 0, False, False, overlay);
        { 7115 } u2_2c6e(col, rowIndex, 2, 257, 0, False, False, overlay);
      end;
      { 7135 } if symbol = #28 then
      begin
        { 7147 } u2_2c6e(col, (rowIndex - 1), 2, 254, 0, False, True, overlay);
        { 7169 } u2_2c6e(col, rowIndex, 2, 258, 0, False, False, overlay);
      end;
      { 7189 } if symbol = '^' then
      begin
        { 719B } u2_2c6e(col, rowIndex, 2, 0, 314, False, False, overlay);
      end;
      { 71BB } if symbol = 'K' then
      begin
        { 71CD } u2_2c6e(col, rowIndex, 2, 0, 606, False, False, overlay);
      end;
      { 71ED } if symbol = 'I' then
      begin
        { 71FF } u2_2c6e(col, rowIndex, d_681A, 0, 0, False, True, overlay);
      end;
      { 721E } if symbol = #211 then
      begin
        { 7230 } u2_2c6e(col, rowIndex, d_681A, 0, -1, False, False, overlay);
      end;
      { 7250 } if symbol = 'r' then
      begin
        { 7262 } u2_2c6e(col, rowIndex, 2, 0, 607, False, False, overlay);
      end;
      { 7282 } if symbol = 's' then
      begin
        { 7294 } u2_2c6e(col, rowIndex, 2, 0, 301, False, False, overlay);
      end;
      { 72B4 } if symbol = 'N' then
      begin
        { 72C6 } u2_2c6e(col, rowIndex, 2, 0, 313, False, False, overlay);
      end;
      { 72E6 } if symbol = 'T' then
      begin
        { 72F8 } u2_2c6e(col, rowIndex, 2, 0, 316, False, False, overlay);
      end;
      { 7318 } if symbol = 'W' then
      begin
        { 732A } u2_2c6e(col, rowIndex, 2, 0, 618, False, False, overlay);
      end;
      { 734A } if symbol = '\' then
      begin
        { 735C } u2_2c6e(col, rowIndex, 2, 0, 620, False, False, overlay);
      end;
      { 737C } if symbol = ']' then
      begin
        { 738E } u2_2c6e(col, rowIndex, 2, 0, 629, False, False, overlay);
      end;
      { 73AE } if symbol = 'd' then
      begin
        { 73C0 } u2_2c6e(col, rowIndex, 2, 0, 630, False, False, overlay);
      end;
      { 73E0 } if symbol = 'f' then
      begin
        { 73F2 } u2_2c6e(col, rowIndex, 2, 0, 631, False, False, overlay);
      end;
      { 7412 } if symbol = 'h' then
      begin
        { 7424 } u2_2c6e(col, rowIndex, 2, 0, 632, False, False, overlay);
      end;
      { 7444 } if symbol = ':' then
      begin
        { 7456 } u2_2c6e(col, rowIndex, 2, 0, 466, False, False, overlay);
      end;
      { 7476 } if symbol = 'H' then
      begin
        { 7488 } u2_2c6e(col, rowIndex, 2, 0, 468, False, False, overlay);
      end;
      { 74A8 } if symbol = 'M' then
      begin
        { 74BA } u2_2c6e(col, rowIndex, 2, 0, 624, False, False, overlay);
      end;
      { 74DA } if symbol = 'P' then
      begin
        { 74EC } u2_2c6e(col, rowIndex, 2, 0, 304, False, False, overlay);
      end;
      { 750C } if symbol = 'p' then
      begin
        { 751E } u2_2c6e((col - 1), rowIndex, 2, 159, 0, False, False, overlay);
        { 7540 } u2_2c6e(col, rowIndex, 2, 160, 0, False, False, overlay);
      end;
      { 7560 } if symbol = #139 then
      begin
        { 7572 } u2_2c6e((col - 1), rowIndex, d_681A, 163, 0, True, False, overlay);
        { 7594 } u2_2c6e(col, rowIndex, d_681A, 164, 0, True, False, overlay);
      end;
      { 75B4 } if symbol = #154 then
      begin
        { 75C6 } u2_2c6e((col - 1), rowIndex, d_681A, 166, 0, True, False, overlay);
        { 75E8 } u2_2c6e(col, rowIndex, d_681A, 165, 0, True, False, overlay);
      end;
      { 7608 } if symbol = #31 then
      begin
        { 761A } u2_2c6e(col, rowIndex, d_681A, 166, 0, True, False, overlay);
      end;
      { 763A } if symbol = #168 then
      begin
        { 764C } u2_2c6e(col, rowIndex, 2, 0, 175, False, False, overlay);
      end;
      { 766C } if symbol = #169 then
      begin
        { 767E } u2_2c6e(col, rowIndex, 2, 0, 176, False, False, overlay);
      end;
      { 769E } if symbol = #170 then
      begin
        { 76B0 } u2_2c6e(col, rowIndex, 2, 0, 177, False, False, overlay);
      end;
      { 76D0 } if symbol = #171 then
      begin
        { 76E2 } u2_2c6e(col, (rowIndex - 1), 194, 0, 0, False, True, overlay);
        { 7703 } u2_2c6e(col, rowIndex, 198, 0, 0, False, False, overlay);
      end;
      { 7722 } if symbol = #172 then
      begin
        { 7734 } u2_2c6e(col, rowIndex, 2, 197, 0, False, False, overlay);
      end;
      { 7754 } if symbol = #173 then
      begin
        { 7766 } u2_2c6e(col, rowIndex, 193, 0, 0, False, True, overlay);
      end;
      { 7785 } if symbol = #133 then
      begin
        { 779A } u2_2c6e((col - 3), rowIndex, 2, 0, 221, False, False, overlay);
        { 77BE } u2_2c6e((col - 2), rowIndex, 2, 0, 222, False, True, overlay);
        { 77E2 } u2_2c6e((col - 1), rowIndex, 2, 0, 223, False, False, overlay);
        { 7804 } u2_2c6e(col, rowIndex, 2, 0, 224, False, False, overlay);
      end;
      { 7824 } if symbol = #134 then
      begin
        { 7836 } u2_2c6e((col - 2), rowIndex, 2, 0, 229, False, False, overlay);
        { 785A } u2_2c6e((col - 1), rowIndex, 2, 0, 230, False, True, overlay);
        { 787C } u2_2c6e(col, rowIndex, 2, 0, 231, False, False, overlay);
      end;
      { 789C } if symbol = '+' then
      begin
        { 78AE } u2_2c6e(col, rowIndex, 2, 0, 421, False, False, overlay);
      end;
      { 78CE } if symbol = ',' then
      begin
        { 78E0 } u2_2c6e(col, rowIndex, 2, 0, 422, True, False, overlay);
      end;
      { 7900 } if symbol = '-' then
      begin
        { 7912 } u2_2c6e(col, rowIndex, 2, 0, 423, False, False, overlay);
      end;
      { 7932 } if symbol = '.' then
      begin
        { 7944 } u2_2c6e(col, rowIndex, 2, 0, 424, True, False, overlay);
      end;
      { 7964 } if symbol = '/' then
      begin
        { 7976 } u2_2c6e(col, rowIndex, 2, 0, 425, False, False, overlay);
      end;
      { 7996 } if symbol = '4' then
      begin
        { 79A8 } u2_2c6e(col, rowIndex, 2, 0, 426, True, False, overlay);
      end;
      { 79C8 } if symbol = 'o' then
      begin
        { 79DA } u2_2c6e(col, rowIndex, d_681A, 417, 0, True, False, overlay);
      end;
      { 79FA } if symbol = 'i' then
      begin
        { 7A0C } u2_2c6e(col, rowIndex, 441, 0, 0, False, False, overlay);
      end;
      { 7A2B } if symbol = 'j' then
      begin
        { 7A3D } u2_2c6e(col, rowIndex, d_681A, 442, 0, False, True, overlay);
      end;
      { 7A5D } if symbol = 'k' then
      begin
        { 7A6F } u2_2c6e(col, rowIndex, d_681A, 443, 0, True, False, overlay);
      end;
      { 7A8F } if symbol = 'l' then
      begin
        { 7AA1 } u2_2c6e(col, rowIndex, d_681A, 444, 0, False, True, overlay);
      end;
      { 7AC1 } if symbol = #149 then
      begin
        { 7AD3 } u2_2c6e(col, rowIndex, 2, 449, 0, False, False, overlay);
      end;
      { 7AF3 } if symbol = '|' then
      begin
        { 7B05 } u2_2c6e(col, rowIndex, 2, 419, 0, False, False, overlay);
      end;
      { 7B25 } if symbol = '~' then
      begin
        { 7B37 } u2_2c6e(col, rowIndex, 2, 420, 0, False, False, overlay);
      end;
      { 7B57 } if symbol = 'm' then
      begin
        { 7B6C } u2_2c6e(col, rowIndex, 2, 0, 0, False, False, overlay);
        { 7B8B } Inc(d_682E);
        { 7B8F } u9_19f9(d_6D7E^.images[45], (col * 16), ((rowIndex * 16) + 16));
        { 7BB3 } u9_19f9(d_6D7E^.images[45], (col * 16), ((rowIndex * 16) + 416));
        { 7BD7 } d_34EC[d_682E].state := 0;
        { 7BE5 } d_34EC[d_682E].sprite := 445;
        { 7BF3 } d_34EC[d_682E].x := (col * 16);
        { 7C07 } d_34EC[d_682E].y := (rowIndex * 16);
        { 7C1B } d_34EC[d_682E].oldX := (col * 16);
        { 7C2F } d_34EC[d_682E].oldY := (rowIndex * 16);
        { 7C43 } if Random(2) > 0 then
        begin
          { 7C50 } d_34EC[d_682E].dx := 1;
        end
        else
        begin
          { 7C60 } d_34EC[d_682E].dx := -1;
        end;
        { 7C6E } d_34EC[d_682E].dy := 0;
        { 7C7C } d_34EC[d_682E].phase := 1;
        { 7C8A } d_34EC[d_682E].speed := 1;
        { 7C98 } d_34EC[d_682E].f12 := 0;
        { 7CA6 } d_34EC[d_682E].f14 := 0;
        { 7CB4 } d_34EC[d_682E].f28 := 20;
        { 7CC2 } d_34EC[d_682E].flag1 := 0;
        { 7CCF } d_34EC[d_682E].flag2 := 0;
      end;
      { 7CDC } if symbol = 'a' then
      begin
        { 7CEE } u2_2c6e(col, rowIndex, 500, 0, 0, True, False, overlay);
      end;
      { 7D0D } if symbol = '`' then
      begin
        { 7D1F } u2_2c6e(col, rowIndex, 2, 0, 499, False, False, overlay);
      end;
      { 7D3F } if symbol = '_' then
      begin
        { 7D54 } u2_2c6e(col, rowIndex, 2, 0, 0, False, False, overlay);
        { 7D73 } Inc(d_682E);
        { 7D77 } u9_19f9(d_6D82^.images[45], (col * 16), ((rowIndex * 16) + 16));
        { 7D9B } u9_19f9(d_6D82^.images[45], (col * 16), ((rowIndex * 16) + 416));
        { 7DBF } d_34EC[d_682E].state := 0;
        { 7DCD } d_34EC[d_682E].x := (col * 16);
        { 7DE1 } d_34EC[d_682E].y := (rowIndex * 16);
        { 7DF5 } d_34EC[d_682E].oldX := (col * 16);
        { 7E09 } d_34EC[d_682E].oldY := (rowIndex * 16);
        { 7E1D } if Random(2) > 0 then
        begin
          { 7E2A } d_34EC[d_682E].dx := 1;
        end
        else
        begin
          { 7E3A } d_34EC[d_682E].dx := -1;
        end;
        { 7E48 } if d_34EC[d_682E].dx = 1 then
        begin
          { 7E57 } d_34EC[d_682E].sprite := 497;
        end
        else
        begin
          { 7E67 } d_34EC[d_682E].sprite := 495;
        end;
        { 7E75 } d_34EC[d_682E].dy := 0;
        { 7E83 } d_34EC[d_682E].phase := 1;
        { 7E91 } d_34EC[d_682E].speed := 1;
        { 7E9F } d_34EC[d_682E].f12 := 0;
        { 7EAD } d_34EC[d_682E].f14 := 0;
        { 7EBB } d_34EC[d_682E].f28 := 21;
        { 7EC9 } d_34EC[d_682E].flag1 := 0;
        { 7ED6 } d_34EC[d_682E].flag2 := 0;
      end;
      { 7EE3 } if symbol = 'D' then
      begin
        { 7EF5 } u2_2c6e(col, rowIndex, 2, 0, 613, False, False, overlay);
      end;
      { 7F15 } if symbol = 'E' then
      begin
        { 7F27 } u2_2c6e(col, rowIndex, d_681A, 0, 614, False, True, overlay);
      end;
      { 7F47 } if symbol = 'O' then
      begin
        { 7F59 } u2_2c6e(col, rowIndex, 2, 0, 615, False, False, overlay);
      end;
      { 7F79 } if symbol = 'U' then
      begin
        { 7F8B } u2_2c6e(col, rowIndex, 2, 0, 616, False, False, overlay);
      end;
      { 7FAB } if symbol = #128 then
      begin
        { 7FBD } u2_2c6e(col, rowIndex, 2, 0, 601, False, False, overlay);
      end;
      { 7FDD } if symbol = #129 then
      begin
        { 7FEF } u2_2c6e(col, rowIndex, 2, 0, 602, False, False, overlay);
      end;
      { 800F } if symbol = #130 then
      begin
        { 8021 } u2_2c6e(col, rowIndex, 2, 0, 603, False, False, overlay);
      end;
      { 8041 } if symbol = #131 then
      begin
        { 8053 } u2_2c6e(col, rowIndex, 2, 0, 604, False, False, overlay);
      end;
      { 8073 } if symbol = #132 then
      begin
        { 8085 } u2_2c6e(col, rowIndex, 2, 0, 605, False, False, overlay);
      end;
      { 80A5 } if symbol = #140 then
      begin
        { 80B7 } u2_2c6e(col, rowIndex, 2, 0, 621, False, False, overlay);
      end;
      { 80D7 } if symbol = #141 then
      begin
        { 80E9 } u2_2c6e(col, rowIndex, 2, 0, 622, False, False, overlay);
      end;
      { 8109 } if symbol = #142 then
      begin
        { 811B } u2_2c6e(col, rowIndex, 2, 0, 623, False, False, overlay);
      end;
      { 813B } if symbol = '%' then
      begin
        { 814D } u2_2c6e((col - 1), rowIndex, 2, 0, 452, False, False, overlay);
        { 816F } u2_2c6e(col, rowIndex, 2, 0, 453, False, False, overlay);
      end;
      { 818F } if symbol = '&' then
      begin
        { 81A4 } u2_2c6e((col - 1), (rowIndex - 1), 455, 0, 0, True, False, overlay);
        { 81C7 } u2_2c6e(col, (rowIndex - 1), 456, 0, 0, True, False, overlay);
        { 81E8 } u2_2c6e((col - 1), rowIndex, 459, 0, 0, True, False, overlay);
        { 8209 } u2_2c6e(col, rowIndex, 460, 0, 0, True, False, overlay);
      end;
      { 8228 } if symbol = '(' then
      begin
        { 823D } u2_2c6e((col - 1), (rowIndex - 1), 457, 0, 0, True, False, overlay);
        { 8260 } u2_2c6e(col, (rowIndex - 1), 458, 0, 0, True, False, overlay);
        { 8281 } u2_2c6e((col - 1), rowIndex, 461, 0, 0, True, False, overlay);
        { 82A2 } u2_2c6e(col, rowIndex, 462, 0, 0, True, False, overlay);
      end;
      { 82C1 } if symbol = ')' then
      begin
        { 82D3 } u2_2c6e(col, rowIndex, 2, 0, 463, False, False, overlay);
      end;
      { 82F3 } if symbol = '*' then
      begin
        { 8305 } if col > 0 then
        begin
          { 830B } u2_2c6e(col, rowIndex, 2, 0, 467, False, False, overlay);
        end;
      end;
      { 832B } if symbol = 'q' then
      begin
        { 833D } u2_2c6e(col, (rowIndex - 1), 2, 0, 633, True, False, overlay);
        { 835F } u2_2c6e(col, rowIndex, 2, 0, 637, True, False, overlay);
      end;
      { 837F } if symbol = 't' then
      begin
        { 8391 } u2_2c6e(col, rowIndex, 2, 0, 635, False, False, overlay);
      end;
      { 83B1 } u2_3a91(col, rowIndex, symbol, overlay);
      { 83C6 } if symbol = #175 then
      begin
        { 83D8 } u2_2c6e(col, rowIndex, 349, 0, 0, False, False, overlay);
      end;
      { 83F7 } if symbol = #143 then
      begin
        { 8409 } u2_2c6e(col, rowIndex, d_681A, 651, 0, True, False, overlay);
      end;
      { 8429 } if symbol = #144 then
      begin
        { 843B } u2_2c6e(col, rowIndex, 652, 0, 0, True, False, overlay);
      end;
      { 845A } if symbol = #145 then
      begin
        { 846C } u2_2c6e(col, rowIndex, d_681A, 653, 0, True, False, overlay);
      end;
      { 848C } if symbol = #146 then
      begin
        { 849E } u2_2c6e(col, rowIndex, d_681A, 654, 0, False, True, overlay);
      end;
      { 84BE } if symbol = #147 then
      begin
        { 84D0 } u2_2c6e(col, rowIndex, 655, 0, 0, True, False, overlay);
      end;
      { 84EF } if symbol = #148 then
      begin
        { 8501 } u2_2c6e(col, rowIndex, 656, 0, 0, True, False, overlay);
      end;
      { 8520 } if symbol = #150 then
      begin
        { 8532 } u2_2c6e(col, rowIndex, 2, 0, 658, False, False, overlay);
      end;
      { 8552 } if symbol = #151 then
      begin
        { 8564 } u2_2c6e(col, rowIndex, 2, 0, 659, False, False, overlay);
      end;
      { 8584 } if symbol = #152 then
      begin
        { 8596 } u2_2c6e(col, rowIndex, 2, 0, 660, False, False, overlay);
      end;
      { 85B6 } if symbol = #153 then
      begin
        { 85C8 } u2_2c6e(col, rowIndex, 661, 0, 0, False, False, overlay);
      end;
      { 85E7 } if symbol = #155 then
      begin
        { 85F9 } u2_2c6e(col, rowIndex, 2, 0, 663, False, False, overlay);
      end;
      { 8619 } if symbol = #156 then
      begin
        { 862B } u2_2c6e(col, rowIndex, 2, 0, 664, False, False, overlay);
      end;
      { 864B } if symbol = #157 then
      begin
        { 865D } u2_2c6e(col, rowIndex, 2, 665, 0, False, False, overlay);
      end;
      { 867D } if symbol = #158 then
      begin
        { 868F } u2_2c6e(col, rowIndex, 2, 666, 0, False, False, overlay);
      end;
      { 86AF } if symbol = #163 then
      begin
        { 86C1 } u2_2c6e(col, rowIndex, d_681A, 671, 0, False, True, overlay);
      end;
      { 86E1 } if symbol = #164 then
      begin
        { 86F3 } u2_2c6e(col, rowIndex, d_681A, 672, 0, False, True, overlay);
      end;
      { 8713 } if symbol = #165 then
      begin
        { 8725 } u2_2c6e(col, rowIndex, d_681A, 673, 0, False, True, overlay);
      end;
      { 8745 } if symbol = #166 then
      begin
        { 8757 } u2_2c6e(col, rowIndex, d_681A, 674, 0, False, True, overlay);
      end;
      { 8777 } if symbol = #176 then
      begin
        { 8789 } u2_2c6e(col, rowIndex, 2, 0, 684, False, False, overlay);
      end;
      { 87A9 } if symbol = #177 then
      begin
        { 87BB } u2_2c6e(col, rowIndex, 2, 0, 685, False, False, overlay);
      end;
      { 87DB } if symbol = #178 then
      begin
        { 87ED } u2_2c6e(col, rowIndex, 2, 0, 686, False, False, overlay);
      end;
      { 880D } if symbol = #179 then
      begin
        { 881F } u2_2c6e(col, rowIndex, 2, 0, 687, False, False, overlay);
      end;
      { 883F } if symbol = #180 then
      begin
        { 8851 } u2_2c6e(col, rowIndex, 2, 0, 688, False, False, overlay);
      end;
      { 8871 } if symbol = #181 then
      begin
        { 8883 } u2_2c6e(col, rowIndex, 2, 0, 689, False, False, overlay);
      end;
      { 88A3 } if symbol = #183 then
      begin
        { 88B5 } u2_2c6e(col, rowIndex, 2, 0, 691, False, False, overlay);
      end;
      { 88D5 } if symbol = #184 then
      begin
        { 88E7 } u2_2c6e(col, rowIndex, 2, 0, 692, False, False, overlay);
      end;
      { 8907 } if symbol = #185 then
      begin
        { 8919 } u2_2c6e(col, rowIndex, 2, 0, 693, False, False, overlay);
      end;
      { 8939 } if symbol = #186 then
      begin
        { 894B } u2_2c6e((col - 1), rowIndex, 690, 0, 0, False, True, overlay);
        { 896C } u2_2c6e(col, rowIndex, 694, 0, 0, False, True, overlay);
      end;
      { 898B } if symbol = #187 then
      begin
        { 899D } u2_2c6e(col, rowIndex, 695, 0, 0, False, False, overlay);
      end;
      { 89BC } if symbol = #188 then
      begin
        { 89CE } u2_2c6e(col, rowIndex, 698, 0, 0, False, False, overlay);
      end;
      { 89ED } if symbol = #189 then
      begin
        { 89FF } u2_2c6e(col, rowIndex, 696, 0, 0, False, False, overlay);
      end;
      { 8A1E } if symbol = #190 then
      begin
        { 8A30 } u2_2c6e(col, rowIndex, 697, 0, 0, False, False, overlay);
      end;
      { 8A4F } if symbol = #191 then
      begin
        { 8A61 } u2_2c6e((col - 1), rowIndex, 679, 0, 0, False, True, overlay);
        { 8A82 } u2_2c6e(col, rowIndex, 680, 0, 0, False, True, overlay);
      end;
      { 8AA1 } if symbol = 'y' then
      begin
        { 8AB3 } u2_2c6e((col - 1), rowIndex, 318, 0, 0, False, True, overlay);
        { 8AD4 } u2_2c6e(col, rowIndex, 319, 0, 0, False, True, overlay);
      end;
      { 8AF3 } if symbol = 'z' then
      begin
        { 8B05 } u2_2c6e(col, rowIndex, 2, 317, 0, False, False, overlay);
      end;
      { 8B25 } if symbol = #135 then
      begin
        { 8B37 } u2_2c6e((col - 1), rowIndex, 323, 0, 0, False, True, overlay);
        { 8B58 } u2_2c6e(col, rowIndex, 324, 0, 0, False, True, overlay);
      end;
      { 8B77 } if symbol = #182 then
      begin
        { 8B89 } u2_2c6e(col, rowIndex, 2, 681, 0, False, False, overlay);
      end;
      { 8BA9 } if symbol = #192 then
      begin
        { 8BBB } u2_2c6e((col - 1), rowIndex, 699, 0, 0, False, True, overlay);
        { 8BDC } u2_2c6e(col, rowIndex, 700, 0, 0, False, True, overlay);
      end;
      { 8BFB } if symbol = #136 then
      begin
        { 8C0D } u2_2c6e(col, rowIndex, 2, 345, 0, False, False, overlay);
      end;
      { 8C2D } if symbol = #137 then
      begin
        { 8C3F } u2_2c6e(col, rowIndex, 2, 346, 0, False, False, overlay);
      end;
      { 8C5F } if symbol = #138 then
      begin
        { 8C71 } u2_2c6e(col, rowIndex, 2, 347, 0, False, False, overlay);
      end;
      { 8C91 } if symbol = #162 then
      begin
        { 8CA3 } u2_2c6e(col, rowIndex, 2, 348, 0, False, True, overlay);
      end;
      { 8CC3 } if symbol = #193 then
      begin
        { 8CD5 } u2_2c6e(col, rowIndex, 701, 0, 0, True, False, overlay);
      end;
      { 8CF4 } if symbol = #194 then
      begin
        { 8D06 } u2_2c6e(col, rowIndex, 702, 0, 0, True, False, overlay);
      end;
      { 8D25 } if symbol = #195 then
      begin
        { 8D37 } u2_2c6e(col, rowIndex, 703, 0, 0, True, False, overlay);
      end;
      { 8D56 } if symbol = #196 then
      begin
        { 8D68 } u2_2c6e(col, rowIndex, 704, 0, 0, True, False, overlay);
      end;
      { 8D87 } if symbol = #197 then
      begin
        { 8D99 } u2_2c6e(col, rowIndex, 705, 0, 0, True, False, overlay);
      end;
      { 8DB8 } if symbol = #198 then
      begin
        { 8DCA } u2_2c6e(col, rowIndex, 706, 0, 0, True, False, overlay);
      end;
      { 8DE9 } if symbol = #199 then
      begin
        { 8DFB } u2_2c6e(col, rowIndex, 707, 0, 0, True, False, overlay);
      end;
      { 8E1A } if symbol = #200 then
      begin
        { 8E2C } u2_2c6e(col, rowIndex, 708, 0, 0, True, False, overlay);
      end;
      { 8E4B } if symbol = #201 then
      begin
        { 8E5D } u2_2c6e(col, rowIndex, 709, 0, 0, True, False, overlay);
      end;
      { 8E7C } if symbol = #202 then
      begin
        { 8E8E } u2_2c6e(col, rowIndex, 2, 0, 710, False, False, overlay);
      end;
      { 8EAE } if symbol = #203 then
      begin
        { 8EC0 } u2_2c6e(col, rowIndex, d_681A, 0, 711, False, True, overlay);
      end;
      { 8EE0 } if symbol = #204 then
      begin
        { 8EF2 } u2_2c6e(col, rowIndex, d_681A, 0, 712, False, True, overlay);
      end;
      { 8F12 } if symbol = #205 then
      begin
        { 8F24 } u2_2c6e(col, rowIndex, d_681A, 0, 713, False, True, overlay);
      end;
      { 8F44 } if symbol = #206 then
      begin
        { 8F56 } u2_2c6e(col, rowIndex, 2, 0, 714, False, False, overlay);
      end;
      { 8F76 } if symbol = #207 then
      begin
        { 8F88 } u2_2c6e(col, rowIndex, 2, 0, 715, False, False, overlay);
      end;
      { 8FA8 } if symbol = #208 then
      begin
        { 8FBA } u2_2c6e(col, rowIndex, 2, 0, 716, False, False, overlay);
      end;
      { 8FDA } if symbol = #209 then
      begin
        { 8FEF } u2_2c6e(col, rowIndex, 2, 0, 0, False, False, overlay);
        { 900E } Inc(d_682E);
        { 9012 } u9_19f9(d_6DAE^.images[1], (col * 16), ((rowIndex * 16) + 16));
        { 9036 } u9_19f9(d_6DAE^.images[1], (col * 16), ((rowIndex * 16) + 416));
        { 905A } d_34EC[d_682E].state := 0;
        { 9068 } d_34EC[d_682E].sprite := 717;
        { 9076 } d_34EC[d_682E].x := (col * 16);
        { 908A } d_34EC[d_682E].y := (rowIndex * 16);
        { 909E } d_34EC[d_682E].oldX := (col * 16);
        { 90B2 } d_34EC[d_682E].oldY := (rowIndex * 16);
        { 90C6 } d_34EC[d_682E].dx := 1;
        { 90D4 } d_34EC[d_682E].dy := 0;
        { 90E2 } d_34EC[d_682E].phase := 1;
        { 90F0 } d_34EC[d_682E].speed := 0;
        { 90FE } d_34EC[d_682E].f12 := 0;
        { 910C } d_34EC[d_682E].f14 := 0;
        { 911A } d_34EC[d_682E].f28 := 26;
        { 9128 } d_34EC[d_682E].flag1 := 0;
        { 9135 } d_34EC[d_682E].flag2 := 0;
      end;
      { 9142 } if symbol = #210 then
      begin
        { 9157 } u2_2c6e((col - 1), (rowIndex - 1), 191, 0, 0, False, True, overlay);
        { 917A } u2_2c6e(col, (rowIndex - 1), 192, 0, 0, False, True, overlay);
        { 919B } u2_2c6e((col - 1), rowIndex, 195, 0, 0, False, False, overlay);
        { 91BC } u2_2c6e(col, rowIndex, 196, 0, 0, False, False, overlay);
      end;
      { 91DB } if symbol = #213 then
      begin
        { 91ED } u2_2c6e(col, rowIndex, d_681A, 721, 0, False, True, overlay);
      end;
      { 920D } if symbol = #214 then
      begin
        { 921F } u2_2c6e(col, rowIndex, d_681A, 722, 0, False, True, overlay);
      end;
      { 923F } if symbol = #215 then
      begin
        { 9251 } u2_2c6e(col, rowIndex, d_681A, 723, 0, False, True, overlay);
      end;
      { 9271 } if symbol = #217 then
      begin
        { 9283 } u2_2c6e(col, rowIndex, 2, 725, 0, False, False, overlay);
      end;
      { 92A3 } if symbol = #218 then
      begin
        { 92B5 } u2_2c6e(col, rowIndex, d_681A, 726, 0, False, True, overlay);
      end;
      { 92D5 } if symbol = #219 then
      begin
        { 92E7 } u2_2c6e(col, rowIndex, d_681A, 727, 0, False, True, overlay);
      end;
      { 9307 } if symbol = #220 then
      begin
        { 9319 } u2_2c6e(col, rowIndex, d_681A, 728, 0, False, True, overlay);
      end;
      { 9339 } if symbol = #221 then
      begin
        { 934B } u2_2c6e(col, rowIndex, 2, 729, 0, False, False, overlay);
      end;
      { 936B } if symbol = #222 then
      begin
        { 937D } u2_2c6e(col, rowIndex, d_681A, 730, 0, False, True, overlay);
      end;
      { 939D } if symbol = #223 then
      begin
        { 93AF } u2_2c6e(col, rowIndex, 201, 0, 0, False, True, overlay);
      end;
      { 93CE } if symbol = #224 then
      begin
        { 93E0 } u2_2c6e(col, rowIndex, 202, 0, 0, False, True, overlay);
      end;
      { 93FF } if symbol = #225 then
      begin
        { 9411 } u2_2c6e(col, rowIndex, 203, 0, 0, False, True, overlay);
      end;
      { 9430 } if symbol = #226 then
      begin
        { 9442 } u2_2c6e(col, rowIndex, 205, 0, 0, False, False, overlay);
      end;
      { 9461 } if symbol = #227 then
      begin
        { 9473 } u2_2c6e(col, rowIndex, 206, 0, 0, False, False, overlay);
      end;
      { 9492 } if symbol = #228 then
      begin
        { 94A4 } u2_2c6e(col, rowIndex, 207, 0, 0, False, False, overlay);
      end;
      { 94C3 } if symbol = '!' then
      begin
        { 94D5 } u2_2c6e(col, rowIndex, 751, 0, 0, False, False, overlay);
      end;
      { 94F4 } if symbol = 'B' then
      begin
        { 9506 } u2_2c6e(col, rowIndex, d_681A, 753, 0, False, True, overlay);
      end;
      { 9526 } if symbol = 'C' then
      begin
        { 9538 } u2_2c6e(col, rowIndex, 755, 0, 0, True, False, overlay);
      end;
      { 9557 } if symbol = 'F' then
      begin
        { 9569 } u2_2c6e(col, rowIndex, d_681A, 756, 0, True, False, overlay);
      end;
      { 9589 } if symbol = 'J' then
      begin
        { 959B } u2_2c6e(col, rowIndex, d_681A, 757, 0, True, False, overlay);
      end;
      { 95BB } if symbol = #229 then
      begin
        { 95CD } u2_2c6e(col, rowIndex, 758, 0, 0, True, False, overlay);
      end;
      { 95EC } if symbol = #230 then
      begin
        { 95FE } u2_2c6e(col, rowIndex, 2, 0, 759, False, False, overlay);
      end;
      { 961E } if symbol = #231 then
      begin
        { 9630 } u2_2c6e(col, rowIndex, 2, 0, 760, False, False, overlay);
      end;
      { 9650 } if symbol = #232 then
      begin
        { 9662 } u2_2c6e(col, rowIndex, 2, 0, 761, False, False, overlay);
      end;
      { 9682 } if symbol = #233 then
      begin
        { 9694 } u2_2c6e(col, rowIndex, 2, 0, 762, False, False, overlay);
      end;
      { 96B4 } if symbol = #234 then
      begin
        { 96C6 } u2_2c6e(col, rowIndex, 2, 0, 763, False, False, overlay);
      end;
      { 96E6 } if symbol = #235 then
      begin
        { 96F8 } u2_2c6e(col, rowIndex, 2, 0, 764, False, False, overlay);
      end;
      { 9718 } if symbol = #236 then
      begin
        { 972A } u2_2c6e(col, rowIndex, 2, 0, 765, False, False, overlay);
      end;
      { 974A } if symbol = #237 then
      begin
        { 975C } u2_2c6e((col - 1), rowIndex, 199, 0, 0, False, True, overlay);
        { 977D } u2_2c6e(col, rowIndex, 200, 0, 0, False, True, overlay);
      end;
      { 979C } if symbol = #216 then
      begin
        { 97AE } u2_2c6e((col - 1), rowIndex, 268, 0, 0, False, True, overlay);
        { 97CF } u2_2c6e(col, rowIndex, 269, 0, 0, False, True, overlay);
      end;
      { 97EE } if symbol = #238 then
      begin
        { 9800 } u2_2c6e((col - 2), rowIndex, 2, 264, 0, False, True, overlay);
        { 9824 } u2_2c6e((col - 1), rowIndex, 2, 265, 0, False, True, overlay);
        { 9846 } u2_2c6e(col, rowIndex, 2, 266, 0, False, True, overlay);
      end;
      { 9866 } if symbol = #239 then
      begin
        { 9878 } u2_2c6e(col, (rowIndex - 1), 2, 263, 0, False, True, overlay);
        { 989A } u2_2c6e(col, rowIndex, 2, 267, 0, False, False, overlay);
      end;
      { 98BA } if symbol = #241 then
      begin
        { 98CC } u2_2c6e(col, rowIndex, 775, 0, 0, True, False, overlay);
      end;
      { 98EB } if symbol = #242 then
      begin
        { 98FD } u2_2c6e(col, rowIndex, 776, 0, 0, True, False, overlay);
      end;
      { 991C } if symbol = #243 then
      begin
        { 992E } u2_2c6e(col, rowIndex, 777, 0, 0, True, False, overlay);
      end;
      { 994D } if symbol = #244 then
      begin
        { 995F } u2_2c6e(col, rowIndex, 778, 0, 0, True, False, overlay);
      end;
      { 997E } if symbol = #245 then
      begin
        { 9990 } u2_2c6e(col, rowIndex, 779, 0, 0, True, False, overlay);
      end;
      { 99AF } if symbol = #246 then
      begin
        { 99C1 } u2_2c6e(col, rowIndex, 780, 0, 0, True, False, overlay);
      end;
      { 99E0 } if symbol = #247 then
      begin
        { 99F2 } u2_2c6e(col, rowIndex, 781, 0, 0, True, False, overlay);
      end;
      { 9A11 } if symbol = #248 then
      begin
        { 9A23 } u2_2c6e(col, rowIndex, 782, 0, 0, True, False, overlay);
      end;
      { 9A42 } if symbol = #249 then
      begin
        { 9A54 } u2_2c6e(col, rowIndex, 783, 0, 0, True, False, overlay);
      end;
      { 9A73 } if symbol = #250 then
      begin
        { 9A85 } u2_2c6e(col, rowIndex, 784, 0, 0, True, False, overlay);
      end;
      { 9AA4 } if symbol = #251 then
      begin
        { 9AB6 } u2_2c6e(col, rowIndex, 785, 0, 0, True, False, overlay);
      end;
      { 9AD5 } if symbol = #252 then
      begin
        { 9AE7 } u2_2c6e(col, rowIndex, 786, 0, 0, True, False, overlay);
      end;
      { 9B06 } if symbol = #253 then
      begin
        { 9B18 } u2_2c6e(col, rowIndex, d_681A, 787, 0, True, False, overlay);
      end;
      { 9B38 } if symbol = #254 then
      begin
        { 9B4A } u2_2c6e(col, rowIndex, 788, 0, 0, True, False, overlay);
      end;
      { 9B69 } if symbol = 'L' then
      begin
        { 9B7B } u2_2c6e(col, rowIndex, d_681A, 789, 0, True, False, overlay);
      end;
      { 9B9B } if symbol = #159 then
      begin
        { 9BAD } u2_2c6e(col, rowIndex, d_681A, 791, 0, True, False, overlay);
      end;
      { 9BCD } if symbol = #160 then
      begin
        { 9BDF } u2_2c6e(col, rowIndex, 792, 0, 0, True, False, overlay);
      end;
      { 9BFE } if symbol = #161 then
      begin
        { 9C10 } u2_2c6e(col, rowIndex, d_681A, 793, 0, True, False, overlay);
      end;
      { 9C30 } if symbol = 'S' then
      begin
        { 9C42 } u2_2c6e(col, rowIndex, 2, 0, 790, False, False, overlay);
      end;
      { 9C62 } if symbol = 'Z' then
      begin
        { 9C77 } u2_2c6e((col - 1), (rowIndex - 1), 2, 795, 0, False, True, overlay);
        { 9C9B } u2_2c6e(col, (rowIndex - 1), 2, 796, 0, False, True, overlay);
        { 9CBD } u2_2c6e((col - 1), rowIndex, 2, 799, 0, False, False, overlay);
        { 9CDF } u2_2c6e(col, rowIndex, 2, 800, 0, False, False, overlay);
      end;
      { 9CFF } if symbol = #167 then
      begin
        { 9D14 } u2_2c6e(col, rowIndex, 2, 0, 0, False, False, overlay);
        { 9D33 } Inc(d_682E);
        { 9D37 } u9_19f9(d_6D8A^.images[25], (col * 16), ((rowIndex * 16) + 16));
        { 9D5B } u9_19f9(d_6D8A^.images[25], (col * 16), ((rowIndex * 16) + 416));
        { 9D7F } d_34EC[d_682E].state := 0;
        { 9D8D } d_34EC[d_682E].sprite := 675;
        { 9D9B } d_34EC[d_682E].x := (col * 16);
        { 9DAF } d_34EC[d_682E].y := (rowIndex * 16);
        { 9DC3 } d_34EC[d_682E].oldX := (col * 16);
        { 9DD7 } d_34EC[d_682E].oldY := (rowIndex * 16);
        { 9DEB } d_34EC[d_682E].dx := 1;
        { 9DF9 } d_34EC[d_682E].dy := 0;
        { 9E07 } d_34EC[d_682E].phase := 1;
        { 9E15 } d_34EC[d_682E].speed := 0;
        { 9E23 } d_34EC[d_682E].f12 := 0;
        { 9E31 } d_34EC[d_682E].f14 := 0;
        { 9E3F } d_34EC[d_682E].f28 := 27;
        { 9E4D } d_34EC[d_682E].flag1 := 0;
        { 9E5A } d_34EC[d_682E].flag2 := 0;
      end;
      { 9E67 } if symbol = 'b' then
      begin
        { 9E7C } u2_2c6e(col, rowIndex, 2, 0, 0, False, False, overlay);
        { 9E9B } Inc(d_682E);
        { 9E9F } u9_19f9(d_6D8A^.images[26], (col * 16), ((rowIndex * 16) + 16));
        { 9EC3 } u9_19f9(d_6D8A^.images[26], (col * 16), ((rowIndex * 16) + 416));
        { 9EE7 } d_34EC[d_682E].state := 0;
        { 9EF5 } d_34EC[d_682E].sprite := 676;
        { 9F03 } d_34EC[d_682E].x := (col * 16);
        { 9F17 } d_34EC[d_682E].y := (rowIndex * 16);
        { 9F2B } d_34EC[d_682E].oldX := (col * 16);
        { 9F3F } d_34EC[d_682E].oldY := (rowIndex * 16);
        { 9F53 } if Random(2) > 0 then
        begin
          { 9F60 } d_34EC[d_682E].dx := 1;
        end
        else
        begin
          { 9F70 } d_34EC[d_682E].dx := -1;
        end;
        { 9F7E } d_34EC[d_682E].dy := 0;
        { 9F8C } d_34EC[d_682E].phase := 1;
        { 9F9A } d_34EC[d_682E].speed := 2;
        { 9FA8 } d_34EC[d_682E].f12 := 0;
        { 9FB6 } d_34EC[d_682E].f14 := 0;
        { 9FC4 } d_34EC[d_682E].f28 := 28;
        { 9FD2 } d_34EC[d_682E].flag1 := 0;
        { 9FDF } d_34EC[d_682E].flag2 := 0;
      end;
    end;
    { 9FEC } u2_2e88(col, rowIndex, symbol);
    { 9FFC } if symbol = 'Y' then
    begin
      { A011 } u2_2c6e(col, rowIndex, 2, 0, 0, False, False, overlay);
      { A030 } savedCol := col;
      { A037 } savedRow := rowIndex;
      { A03E } if d_6D18 <> 0 then
      begin
        { A045 } if d_681C = 1 then
        begin
          { A04C } col := (d_6D18 shr 4);
          { A057 } rowIndex := (d_6D1A shr 4);
        end;
      end;
      { A062 } u9_19f9(d_6D7A^.images[1], (col * 16), ((rowIndex * 16) + 16));
      { A086 } u9_19f9(d_6D7A^.images[1], (col * 16), ((rowIndex * 16) + 416));
      { A0AA } d_34EC[1].state := 0;
      { A0AF } d_34EC[1].sprite := 9;
      { A0B5 } d_34EC[1].x := (col * 16);
      { A0C0 } d_34EC[1].y := (rowIndex * 16);
      { A0CB } d_34EC[1].oldX := (col * 16);
      { A0D6 } d_34EC[1].oldY := (rowIndex * 16);
      { A0E1 } d_34EC[1].dx := 1;
      { A0E7 } d_34EC[1].dy := 0;
      { A0EC } d_34EC[1].phase := 1;
      { A0F2 } d_34EC[1].speed := 2;
      { A0F8 } d_34EC[1].f12 := 0;
      { A0FD } d_34EC[1].f28 := 99;
      { A103 } d_34EC[1].flag1 := 0;
      { A108 } d_34EC[1].flag2 := 0;
      { A10D } d_6838 := ((col * 16) - 160);
      { A11B } if d_6838 < 0 then
      begin
        { A122 } d_6838 := 0;
      end;
      { A127 } if d_6838 > 320 then
      begin
        { A12F } d_6838 := 320;
      end;
      { A135 } d_683A := ((rowIndex * 16) - 100);
      { A143 } if d_683A < 0 then
      begin
        { A14A } d_683A := 0;
      end;
      { A14F } if d_683A > 184 then
      begin
        { A157 } d_683A := 184;
      end;
      { A15D } if d_70C6 = 0 then
      begin
        { A164 } u9_01f9(d_6838, (d_683A + 16));
      end
      else
      begin
        { A176 } u9_024c(d_6838, (d_683A + 16));
      end;
      { A186 } col := savedCol;
      { A18D } rowIndex := savedRow;
    end;
  end;
end;
