{@decls}

{@stubs}

{@body}
procedure u4_0101(A, B, C, D, E, F, G: Integer);
var
  Y: Integer;
  TopLeft, TopRight, BottomLeft, BottomRight, Horizontal, Vertical: Char;
  Attr: Byte;
begin
  case G of
    0:
    begin
      TopLeft := ' ';
      TopRight := ' ';
      BottomLeft := ' ';
      BottomRight := ' ';
      Horizontal := ' ';
      Vertical := ' ';
    end;
    1:
    begin
      TopLeft := #218;
      TopRight := #191;
      BottomLeft := #192;
      BottomRight := #217;
      Horizontal := #196;
      Vertical := #179;
    end;
    2:
    begin
      TopLeft := #201;
      TopRight := #187;
      BottomLeft := #200;
      BottomRight := #188;
      Horizontal := #205;
      Vertical := #186;
    end;
    3:
    begin
      TopLeft := #214;
      TopRight := #183;
      BottomLeft := #211;
      BottomRight := #189;
      Horizontal := #196;
      Vertical := #186;
    end;
    4:
    begin
      TopLeft := #213;
      TopRight := #184;
      BottomLeft := #212;
      BottomRight := #190;
      Horizontal := #205;
      Vertical := #179;
    end;
  else
    begin
      TopLeft := Chr(G);
      TopRight := Chr(G);
      BottomLeft := Chr(G);
      BottomRight := Chr(G);
      Horizontal := Chr(G);
      Vertical := Chr(G);
    end;
  end;

  Attr := u4_0000(E, F);
  u4_04bf(A, B, Attr, TopLeft);
  u4_04bf(A + 1, B, Attr, u4_0045(C - A - 1, Horizontal));
  u4_04bf(C, B, Attr, TopRight);
  for Y := B + 1 to D - 1 do
  begin
    u4_04bf(A, Y, Attr, Vertical);
    u4_04bf(C, Y, Attr, Vertical);
  end;
  u4_04bf(A, D, Attr, BottomLeft);
  u4_04bf(A + 1, D, Attr, u4_0045(C - A - 1, Horizontal));
  u4_04bf(C, D, Attr, BottomRight);
end;
