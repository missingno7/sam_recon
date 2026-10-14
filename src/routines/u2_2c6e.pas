{@decls}

{@stubs}

{@body}
procedure u2_2c6e(X, Y, Tile, A, B: Integer; C, D, Foreground: Byte);
begin
  if Foreground <> 0 then
  begin
    d_0296[X + 1, Y + 1].Aux := B;
    d_6840 := $0010;
    u2_2530(X shl 4, Y shl 4);
    d_6840 := $01A0;
    u2_2530(X shl 4, Y shl 4);
    d_6840 := $0010;
  end
  else
  begin
    d_0296[X + 1, Y + 1].Tile := Tile;
    d_0296[X + 1, Y + 1].Overlay := A;
    d_0296[X + 1, Y + 1].Aux := B;
    d_0296[X + 1, Y + 1].Solid := C;
    d_0296[X + 1, Y + 1].Special := D;
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
