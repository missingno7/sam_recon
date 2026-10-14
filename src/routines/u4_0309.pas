{@decls}
{@stubs}
procedure u4_0101(A, B, C, D, E, F, G: Integer);
procedure u4_0097(A, B, C, D, E, F: Integer);
{@body}
procedure u4_0309(A, B, C, D, E, F, G: Integer);
begin
  u4_0101(A, B, C, D, E, F, G);
  u4_0097(A + 1, B + 1, C - 1, D - 1, E, F);
end;
