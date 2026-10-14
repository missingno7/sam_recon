{@decls}
var
  d_341C: Byte;
  d_6814: Word;
  d_6824: Word;
  d_6D68: Word;
  d_6D6A: Word;
{@stubs}
{@body}
procedure u3_a3b6;
var
  i: Word;
begin
  u3_079e;
  i := 0;
  Inc(i);
  d_3812[i] := '  Set your joystick so that';
  Inc(i);
  d_3812[i] := 'it is in the middle position.';
  Inc(i);
  d_3812[i] := ' ';
  Inc(i);
  d_3812[i] := '   Press SPACE when this is';
  Inc(i);
  d_3812[i] := ' done, and the joystick will';
  Inc(i);
  d_3812[i] := '       be calibrated.';
  Inc(i);
  d_3812[i] := ' ';
  Inc(i);
  d_3812[i] := 'This step is not necessary if';
  Inc(i);
  d_3812[i] := ' your joystick is set in the';
  Inc(i);
  d_3812[i] := ' middle when the game loads.';
  Inc(i);
  d_3812[i] := ' ';
  Inc(i);
  d_3812[i] := 'Press Escape if your joystick';
  Inc(i);
  d_3812[i] := '         is not on.';
  Inc(i);
  d_3812[i] := '              ^';
  Inc(i);
  d_3812[i] := 'END OF WINDOW';

  d_67FA[1] := 1;
  d_67FA[2] := $39;
  d_6814 := u3_1601(0);
  if d_6814 = $39 then
  begin
    d_341C := Ord(u6_0000);
    if d_341C <> 0 then
    begin
      d_6D68 := u6_00cc(0);
      d_6D6A := u6_00cc(1);
    end;
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
