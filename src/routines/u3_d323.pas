{@decls}
type
  TMenuLine = String[40];
var
  d_6824: Word;
{@stubs}
procedure u3_079e;
function u3_1601(Value: Byte): Byte;
procedure u3_acdd;
{@body}
procedure u3_d323;
var
  menuIndex, selectedValue: Word;
begin
  u3_079e;
  menuIndex := 0;
  Inc(menuIndex);
  d_3812[menuIndex] := '     About Apogee Software';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := 'Our goal is to establish Apogee';
  Inc(menuIndex);
  d_3812[menuIndex] := '  as the leader in commercial';
  Inc(menuIndex);
  d_3812[menuIndex] := ' quality shareware games. With';
  Inc(menuIndex);
  d_3812[menuIndex] := ' enthusiasm and dedication we';
  Inc(menuIndex);
  d_3812[menuIndex] := 'think our goal can be achieved.';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := 'However,  we need your support.';
  Inc(menuIndex);
  d_3812[menuIndex] := 'Shareware is not free software.';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := '  We thank you in advance for';
  Inc(menuIndex);
  d_3812[menuIndex] := '   your contribution to the';
  Inc(menuIndex);
  d_3812[menuIndex] := '  growing shareware community.';
  Inc(menuIndex);
  d_3812[menuIndex] := '      Your honesty pays...';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := '        Press any key ^';
  Inc(menuIndex);
  d_3812[menuIndex] := 'END OF WINDOW';
  d_6824 := $03E7;
  MemW[0:$041C] := MemW[0:$041A];
  selectedValue := u3_1601(1);
  u3_acdd;
end;
