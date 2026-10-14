{@decls}
var
  d_6838: Word;
  d_683A: Word;
  d_683C: Word;
  d_6840: Word;
  d_70C6: Word;
{@stubs}
procedure u9_01f9(A, B: Word);
procedure u9_024c(A, B: Word);
{@body}
procedure u3_00a3;
begin
  if d_70C6 = 0 then
    u9_01f9(d_6838, d_6840 + d_683A)
  else
    u9_024c(d_6838, d_6840 + d_683A);
  d_683C := d_6840;
end;
