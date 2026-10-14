{@decls}
{@stubs}
function u4_0000(Fore, Back: Byte): Byte;
function u4_0045(Count: Byte; Ch: Char): string;
procedure u4_04bf(X, Y, Attr: Byte; S: string);
{@body}
procedure u4_0097(X1, Y1, X2, Y2, Fore, Back: Integer);
var
  Y: Integer;
  Attr: Byte;
begin
  if X2 > 80 then
    X2 := 80;
  Attr := u4_0000(Fore, Back);
  for Y := Y1 to Y2 do
    u4_04bf(X1, Y, Attr, u4_0045(X2 - X1 + 1, ' '));
end;
