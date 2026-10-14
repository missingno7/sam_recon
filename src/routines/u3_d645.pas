{@decls}
type
  TMessageSlot = packed record
    S: String[40];
  end;
var d_6824: Word;
{@stubs}
procedure u3_079e;
function u3_1601(value: Byte): Byte;
procedure u3_acdd;
{@body}
procedure u3_d645;
var
  i: Word;
  resultWord: Word;
begin
  u3_079e;
  i := 0;
  Inc(i);
  d_3812[i] := 'Good work 006, you@ve knocked';
  Inc(i);
  d_3812[i] := 'out the island security system';
  Inc(i);
  d_3812[i] := '  and can now infiltrate the';
  Inc(i);
  d_3812[i] := '     level containing the';
  Inc(i);
  d_3812[i] := ' blueprints to the "Red Rock';
  Inc(i);
  d_3812[i] := '      Rover" satellite.';
  Inc(i);
  d_3812[i][0] := #0;
  Inc(i);
  d_3812[i] := 'Press ESCAPE!          ';
  Inc(i);
  d_3812[i] := 'END OF WINDOW';
  d_67FA[1] := 1;
  d_67FA[2] := $1C;
  d_67FA[3] := $39;
  d_6824 := $03E7;
  MemW[0:$041C] := MemW[0:$041A];
  resultWord := u3_1601(0);
  d_6EC5 := 0;
  d_6816 := 0;
  u3_acdd;
end;
