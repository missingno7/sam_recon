{@decls}
var
  d_70CA: Pointer;
  d_70CE: Pointer;
  d_70D2: Pointer;
{@stubs}
procedure p_0000;
procedure p_0be5;
procedure p_0e33;
{@body}
procedure p_0e67;
begin
  d_70CA := ExitProc;
  ExitProc := @p_0e33;
  GetIntVec($1C, d_70CE);
  SetIntVec($1C, @p_0be5);
  GetIntVec($09, d_70D2);
  SetIntVec($09, @p_0000);
end;
