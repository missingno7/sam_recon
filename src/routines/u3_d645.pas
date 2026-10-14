{@decls}
type
  TMessageSlot = packed record
    S: String[40];
  end;
var d_3812: array[1..299] of TMessageSlot;
var d_67FA: Byte;
var d_67FB: Byte;
var d_67FC: Byte;
var d_6816: Byte;
var d_6824: Word;
var d_6EC5: Byte;
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
  d_3812[i].S := 'Good work 006, you@ve knocked';
  Inc(i);
  d_3812[i].S := 'out the island security system';
  Inc(i);
  d_3812[i].S := '  and can now infiltrate the';
  Inc(i);
  d_3812[i].S := '     level containing the';
  Inc(i);
  d_3812[i].S := ' blueprints to the "Red Rock';
  Inc(i);
  d_3812[i].S := '      Rover" satellite.';
  Inc(i);
  d_3812[i].S[0] := #0;
  Inc(i);
  d_3812[i].S := 'Press ESCAPE!          ';
  Inc(i);
  d_3812[i].S := 'END OF WINDOW';
  d_67FA := 1;
  d_67FB := $1C;
  d_67FC := $39;
  d_6824 := $03E7;
  MemW[0:$041C] := MemW[0:$041A];
  resultWord := u3_1601(0);
  d_6EC5 := 0;
  d_6816 := 0;
  u3_acdd;
end;
