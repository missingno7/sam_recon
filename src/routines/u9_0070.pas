{@decls}
var
{@stubs}
procedure u9_01a3(Mode: Word);
procedure u9_01c5(Mode: Word);
procedure u9_0625(Mode: Word);
procedure u9_27e2;
procedure u9_2981(Mode: Word);
{@body}
begin
  u9_01a3(1);
  u9_27e2;
  u9_2981(0);
  u9_01c5($10);
  u9_0625($0F);
  d_7140 := 'Copyright 1991 Peder Jungck';
  d_7140 := '1019 W Lovers Lane         ';
  d_7140 := 'Arlington, Texas  76013    ';
  d_7140 := '(817) 795-8903             ';
end.
