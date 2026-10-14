{ Mission briefing text, followed by the scrolling help window. }
{@decls}
type
  THelpLine = string[40];
  { Required by the canonical u2_68a9 stub header. }
  TLevelRow = array[1..42] of Char;
var
  d_67FA: array[1..20] of Byte;
  d_6814: Integer;
  d_6816, d_6EC5: Byte;
{@stubs}
procedure u3_079e;
function u3_26cf(Mode: Byte): Byte;
{@body}
procedure u3_6ea9;
var
  I: Integer;
begin
  u3_079e;
  I := 1;
{$IFDEF SAM1}
  d_3812[I] := 'CONFIDENTIAL FILE         Pg. 1';
{$ELSE}
  d_3812[I] := 'BACKGROUND FILE           Pg. 1';
{$ENDIF}
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'To:        Agent 006';
  Inc(I);
  d_3812[I] := 'Priority:  For Your Eyes Only';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '**Destroy file after reading**';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'Our government scientists have';
  Inc(I);
  d_3812[I] := 'been working on a secret';
  Inc(I);
  d_3812[I] := 'project: A ruby-powered laser';
  Inc(I);
  d_3812[I] := 'satellite with the ability to';
  Inc(I);
  d_3812[I] := 'pinpoint and fire upon any';
  Inc(I);
  d_3812[I] := 'target from Earth orbit, code';
  Inc(I);
  d_3812[I] := 'named "Red Rock Rover".';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
{$IFNDEF SAM1}
  d_3812[I] := 'MISSION UPDATE            Pg. 2';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
{$IFDEF SAM2}
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := '006 successfully infiltrated';
  Inc(I);
  d_3812[I] := 'DVS headquarters on the first';
  Inc(I);
  d_3812[I] := 'island, and gained possession of';
  Inc(I);
  d_3812[I] := 'the first of three blueprints.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'Using a jet raft, 006 has';
  Inc(I);
  d_3812[I] := 'landed upon the second island';
  Inc(I);
  d_3812[I] := 'fortress, and must find the';
  Inc(I);
  d_3812[I] := 'next blueprint to the "Red Rock';
  Inc(I);
  d_3812[I] := 'Rover" weapon.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
{$ELSE}
  d_3812[I] := '006 has destroyed the DVS';
  Inc(I);
  d_3812[I] := 'headquarters on the first and';
  Inc(I);
  d_3812[I] := 'second island fortresses, and';
  Inc(I);
  d_3812[I] := 'secured possession of two';
  Inc(I);
  d_3812[I] := 'crucial blueprints.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'Using scuba gear, 006 slipped';
  Inc(I);
  d_3812[I] := 'past the security net set up';
  Inc(I);
  d_3812[I] := 'around the final island.';
  Inc(I);
  d_3812[I] := 'Getting the final blueprint';
  Inc(I);
  d_3812[I] := 'will be the most dangerous';
  Inc(I);
  d_3812[I] := 'assignment yet, since this';
  Inc(I);
  d_3812[I] := 'island id the DVS stronghold!';
  Inc(I);
{$ENDIF}
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
{$ENDIF}
{$IFDEF SAM1}
  d_3812[I] := 'YOUR MISSION              Pg. 2';
{$ELSE}
  d_3812[I] := 'YOUR MISSION              Pg. 3';
{$ENDIF}
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'Two weeks ago the blueprints';
  Inc(I);
  d_3812[I] := 'were stolen by the Diabolical';
  Inc(I);
  d_3812[I] := 'Villain Society (DVS), which';
  Inc(I);
  d_3812[I] := 'will use them to build the';
  Inc(I);
  d_3812[I] := 'ultimate terrorist threat.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'You@ve been chosen by the';
  Inc(I);
  d_3812[I] := 'Bureau to infiltrate DVS';
  Inc(I);
  d_3812[I] := 'headquarters and secure the';
  Inc(I);
  d_3812[I] := 'blueprints.  The headquarters';
  Inc(I);
  d_3812[I] := 'are located on a series of';
  Inc(I);
  d_3812[I] := 'islands in the Pacific basin.';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
{$IFDEF SAM1}
  d_3812[I] := 'YOUR MISSION              Pg. 3';
{$ELSE}
  d_3812[I] := 'YOUR MISSION              Pg. 4';
{$ENDIF}
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'Your mission, should you choose';
  Inc(I);
  d_3812[I] := 'to accept it, is to bring back';
  Inc(I);
  d_3812[I] := 'the secret blueprints to the';
  Inc(I);
  d_3812[I] := '"Red Rock Rover" project.  You';
  Inc(I);
  d_3812[I] := 'will be isolated from outside';
  Inc(I);
  d_3812[I] := 'help.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'You should be warned that this';
  Inc(I);
  d_3812[I] := 'mission is of global importance';
  Inc(I);
  d_3812[I] := 'and must succeed in order to';
  Inc(I);
  d_3812[I] := 'maintain a balance of world';
  Inc(I);
  d_3812[I] := 'power.';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
{$IFDEF SAM1}
  d_3812[I] := 'YOUR MISSION              Pg. 4';
{$ELSE}
  d_3812[I] := 'YOUR MISSION              Pg. 5';
{$ENDIF}
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'We do not have a file on the';
  Inc(I);
  d_3812[I] := 'head of DVS, but he is';
  Inc(I);
  d_3812[I] := 'suspected to be very cunning';
  Inc(I);
  d_3812[I] := 'and dangerous.  DVS';
  Inc(I);
  d_3812[I] := 'headquarters are built up';
  Inc(I);
  d_3812[I] := 'as an elaborate series of';
  Inc(I);
  d_3812[I] := 'fortresses on three well';
  Inc(I);
  d_3812[I] := 'guarded islands.';
  Inc(I);
  d_3812[I][0] := #0;
  Inc(I);
  d_3812[I] := 'As always, should you be caught';
  Inc(I);
  d_3812[I] := 'the Bureau will disavow any';
  Inc(I);
  d_3812[I] := 'knowledge of your existence.';
  Inc(I);
  d_3812[I] := '-------------------------------';
  Inc(I);
  d_3812[I] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(I);
  d_3812[I] := 'END OF WINDOW';
  d_67FA[1] := 1;
  d_6814 := u3_26cf(0);
  d_6EC5 := 0;
  d_6816 := 0;
end;
