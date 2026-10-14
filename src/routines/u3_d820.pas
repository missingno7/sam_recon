{@decls}
type
  TMenuText = array[1..6] of String[40];
var
  d_6824: Word;
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
  d_67FA[1] := 1;
  d_67FA[2] := $1C;
  d_67FA[3] := $39;
  d_6824 := $03E7;
  MemW[$0000:$041C] := MemW[$0000:$041A];
  selectedValue := u3_1601(0);
  d_6EC5 := 0;
  d_6816 := 0;
  u3_acdd;
end;
