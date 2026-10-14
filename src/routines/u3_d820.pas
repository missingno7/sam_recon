{@decls}
type
  TMenuText = array[1..6] of String[40];
var
  d_3812: TMenuText;
  d_67FA: Byte;
  d_67FB: Byte;
  d_67FC: Byte;
  d_6816: Byte;
  d_6824: Word;
  d_6EC5: Byte;
{@stubs}
procedure u3_079e;
function u3_1601(Value: Byte): Byte;
procedure u3_acdd;
{@body}
procedure u3_d820;
var
  menuIndex, selectedValue: Word;
begin
  u3_079e;
  menuIndex := 0;
  Inc(menuIndex);
  d_3812[menuIndex] := ' 25,000 point BONUS for';
  Inc(menuIndex);
  d_3812[menuIndex] := 'finishing the level with';
  Inc(menuIndex);
  d_3812[menuIndex] := '    perfect health!';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := 'Press ESCAPE!          ';
  Inc(menuIndex);
  d_3812[menuIndex] := 'END OF WINDOW';
  d_67FA := 1;
  d_67FB := $1C;
  d_67FC := $39;
  d_6824 := $03E7;
  MemW[$0000:$041C] := MemW[$0000:$041A];
  selectedValue := u3_1601(0);
  d_6EC5 := 0;
  d_6816 := 0;
  u3_acdd;
end;
