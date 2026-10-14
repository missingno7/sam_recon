{@decls}
type
  TMapCell = record
    F00: Word;
    F02: Word;
    F04: Word;
    F06: Byte;
    F07: Byte;
  end;
var
  d_0296: array[1..40, 1..25] of TMapCell;
  d_6840: Word;
{@stubs}
procedure u2_0000(X, Y: Integer);
procedure u2_1185(X, Y: Integer);
procedure u2_2530(X, Y: Integer);
{@body}
procedure u2_2c6e(X, Y, Tile, A, B: Integer; C, D, Foreground: Byte);
begin
  if Foreground <> 0 then
  begin
    d_0296[X + 1, Y + 1].F04 := B;
    d_6840 := $0010;
    u2_2530(X shl 4, Y shl 4);
    d_6840 := $01A0;
    u2_2530(X shl 4, Y shl 4);
    d_6840 := $0010;
  end
  else
  begin
    d_0296[X + 1, Y + 1].F00 := Tile;
    d_0296[X + 1, Y + 1].F02 := A;
    d_0296[X + 1, Y + 1].F04 := B;
    d_0296[X + 1, Y + 1].F06 := C;
    d_0296[X + 1, Y + 1].F07 := D;
    d_6840 := $0010;
    if Y = 24 then
      u2_1185(X shl 4, Y shl 4)
    else
      u2_0000(X shl 4, Y shl 4);
    u2_2530(X shl 4, Y shl 4);
    d_6840 := $01A0;
    if Y = 24 then
      u2_1185(X shl 4, Y shl 4)
    else
      u2_0000(X shl 4, Y shl 4);
    u2_2530(X shl 4, Y shl 4);
    d_6840 := $0010;
  end;
end;
