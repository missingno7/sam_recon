{ Mission-success text and ordering pages in the scrolling help window. }
{@decls}
type
  TLevelRow = array[1..42] of Char; { Required by a shared harness stub. }
var
  d_3812: array[1..299] of string[40];
  d_67FA: array[1..20] of Byte;
  d_6814: Word;
  d_6816, d_6EC5: Byte;
{@stubs}
procedure u3_079e;
function u3_26cf(Mode: Byte): Byte;
{@body}
procedure u3_7c17;
var
  Row: Integer;
begin
  u3_079e;
  Row := 1;
  d_3812[Row] := 'MISSION SUCCESSFUL        Pg. 1';
  Inc(Row);
  d_3812[Row] := '-------------------------------';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := 'Congratulations 006, you have';
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'successfully destroyed the';
{$ELSE}
  d_3812[Row] := 'successfully infiltrated DVS';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'first DVS headquarters and';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'headquarters on the island,';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := 'headquarters on the last island';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'retrieved the first blueprint.';
{$ELSE}
  d_3812[Row] := 'and gained possession of the';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := '';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'second blueprint.  The Bureau';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := 'final blueprint.';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'The Bureau has hidden a jet';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'has hidden scuba gear on the';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := '';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'raft on the island that you can';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'island that you must use to';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := 'Dr. No Body and the DVS have';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'use to reach the second island';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'reach the third island';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := 'all been stopped and the world';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'fortress.  Once there, you will';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'fortress.  Once there, you will';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := 'is once again safe, well for a';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'overcome new dangers and traps';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'overcome new dangers and traps';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := 'few more days anyway...';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'to secure the second blueprint';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'to secure the final blueprint';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := '';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'to the "Red Rock Rover" weapon.';
{$ENDIF}
{$IFDEF SAM2}
  d_3812[Row] := 'to the "Red Rock Rover" weapon.';
{$ENDIF}
{$IFDEF SAM3}
  d_3812[Row] := '';
{$ENDIF}
  Inc(Row);
  d_3812[Row] := '-------------------------------';
  Inc(Row);
  d_3812[Row] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(Row);
  d_3812[Row] := 'HOW TO ORDER MORE GAMES   Pg. 2';
  Inc(Row);
  d_3812[Row] := '-------------------------------';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'Be sure to play the next two';
{$ELSE}
  d_3812[Row] := 'Be sure to play all the';
{$ENDIF}
  Inc(Row);
  d_3812[Row] := 'exciting missions, otherwise';
  Inc(Row);
  d_3812[Row] := 'the world will fall prey to the';
  Inc(Row);
  d_3812[Row] := 'evil intentions of the DVS!';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'The next two missions are:';
{$ELSE}
  d_3812[Row] := 'Get all the Secret Agent games:';
{$ENDIF}
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := ' * Kill Again Island';
{$ELSE}
  d_3812[Row] := ' * The Hunt For Red Rock Rover';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := ' * Dr. No Body';
{$ELSE}
  d_3812[Row] := ' * Kill Again Island';
{$ENDIF}
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := '';
{$ELSE}
  d_3812[Row] := ' * Dr. No Body';
{$ENDIF}
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := '-------------------------------';
  Inc(Row);
  d_3812[Row] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(Row);
  d_3812[Row] := 'HOW TO ORDER MORE GAMES   Pg. 3';
  Inc(Row);
  d_3812[Row] := '-------------------------------';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
{$IFDEF SAM1}
  d_3812[Row] := 'In these two missions you will';
{$ELSE}
  d_3812[Row] := 'In the other missions you will';
{$ENDIF}
  Inc(Row);
  d_3812[Row] := 'encounter all-new challenges,';
  Inc(Row);
  d_3812[Row] := 'hazards, henchmen, levels,';
  Inc(Row);
  d_3812[Row] := 'puzzles, prizes, and basically';
  Inc(Row);
  d_3812[Row] := 'put to test all of your secret';
  Inc(Row);
  d_3812[Row] := 'agent skills!';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := 'To order, call 1-800-GAME-123';
  Inc(Row);
  d_3812[Row] := 'between the hours of 8am - 7pm';
  Inc(Row);
  d_3812[Row] := 'Central Standard Time (CST).';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := 'Price: $34 (incl. $4 Shipping)';
  Inc(Row);
  d_3812[Row] := '-------------------------------';
  Inc(Row);
  d_3812[Row] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(Row);
  d_3812[Row] := 'HOW TO ORDER MORE GAMES   Pg. 4';
  Inc(Row);
  d_3812[Row] := '-------------------------------';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := 'This price ($34) includes all';
  Inc(Row);
  d_3812[Row] := 'three Secret Agent missions,';
  Inc(Row);
  d_3812[Row] := 'which also sell for $15 apiece.';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := 'You may also order by mail:';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := '     Apogee Software';
  Inc(Row);
  d_3812[Row] := '     P.O. Box 476389';
  Inc(Row);
  d_3812[Row] := '     Garland, TX  75047';
  Inc(Row);
  d_3812[Row] := '';
  Inc(Row);
  d_3812[Row] := 'All orders include: hint sheet,';
  Inc(Row);
  d_3812[Row] := 'cheat password, and bonus game.';
  Inc(Row);
  d_3812[Row] := '-------------------------------';
  Inc(Row);
  d_3812[Row] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(Row);
  d_3812[Row] := 'END OF WINDOW';
  d_67FA[1] := 1;
  d_6814 := u3_26cf(0);
  d_6EC5 := 0;
  d_6816 := 0;
end;
