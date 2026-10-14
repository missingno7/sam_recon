{@decls}
type
  TMenuLines = array[1..299] of String[40];
{@stubs}

{@body}
procedure u3_cf40;
var
  menuIndex: Word;
  selectedValue: Word;
begin
  u3_079e;
  menuIndex := 0;
  Inc(menuIndex);
  d_3812[menuIndex] := '   THE OFFICIAL APOGEE BBS';
  Inc(menuIndex);
  d_3812[menuIndex] := '   -----------------------';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := 'The SOFTWARE CREATIONS BBS is';
  Inc(menuIndex);
  d_3812[menuIndex] := ' the home BBS for the latest';
  Inc(menuIndex);
  d_3812[menuIndex] := ' Apogee games.  Check out our';
  Inc(menuIndex);
  d_3812[menuIndex] := 'FREE "Apogee" file section for';
  Inc(menuIndex);
  d_3812[menuIndex] := '  new releases and updates.';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := '       BBS phone lines:';
  Inc(menuIndex);
  d_3812[menuIndex] := '(508) 365-2359  2400 baud';
  Inc(menuIndex);
  d_3812[menuIndex] := '(508) 365-9825  9600 baud';
  Inc(menuIndex);
  d_3812[menuIndex] := '(508) 365-9668  14.4k dual HST';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := '  Many node lines available!';
  Inc(menuIndex);
  d_3812[menuIndex][0] := #0;
  Inc(menuIndex);
  d_3812[menuIndex] := '        Press Any Key ^';
  Inc(menuIndex);
  d_3812[menuIndex] := 'END OF WINDOW';

  d_6824 := $03E7;
  MemW[$0000:$041C] := MemW[$0000:$041A];
  selectedValue := u3_1601(1);
  u3_acdd;
end;
