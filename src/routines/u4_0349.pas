{@decls}
{@stubs}
procedure u4_04bf(Center, A, Color: Byte; var Text: string);
function u4_0000(A, B: Byte): Byte;
{@body}
procedure u4_0349(A, B, C: Byte; var Text: string);
var
  Buffer: string;
begin
  Buffer := Text;
  u4_04bf(40 - Ord(Buffer[0]) div 2, A, u4_0000(B, C), Buffer);
end;
