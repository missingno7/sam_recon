{@decls}
{@stubs}
{@body}
function u4_0045(Count: Byte; Ch: Char): string;
var
  S: string;
begin
  if not (Count in [1..80]) then
    Count := 1;
  FillChar(S, Count + 1, Ch);
  S[0] := Chr(Count);
  u4_0045 := S;
end;
