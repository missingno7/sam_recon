{ u3_a1d8: far, frame 0 bytes, parameters [0] bytes }
{@decls}
type
  TTextPair = packed record
    first: string[40];
    second: string[40];
  end;
var
  d_3812: TTextPair;
  d_341C: Byte;
  d_67FA: Byte;
  d_67FB: Byte;
  d_67FC: Byte;
  d_6814: Word;
  d_6816: Byte;
  d_6824: Word;
  d_6EC3: Byte;
  d_6EC4: Byte;
  d_6EC5: Byte;
  d_6ECA: Byte;
  d_6ECB: Byte;
  d_70C8: Word;
{@stubs}
procedure u3_079e;
function u3_1601(Value: Byte): Byte;
function u6_0000: Boolean;
{@body}
procedure u3_a1d8;
begin
  u3_079e;
  d_3812.first := 'Joystick On (Y-N) ^';
  d_3812.second := 'END OF WINDOW';
  d_67FA := $15;
  d_67FB := $31;
  d_67FC := 1;
  d_6814 := u3_1601(1);
  if d_6814 = $15 then
  begin
    d_341C := Ord(u6_0000);
    d_70C8 := 1;
  end
  else if d_6814 = $31 then
  begin
    d_341C := 0;
    d_70C8 := 0;
  end;
  d_6EC5 := 0;
  d_6816 := 0;
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  MemW[0:$041C] := MemW[0:$041A];
  d_6824 := 0;
end;
