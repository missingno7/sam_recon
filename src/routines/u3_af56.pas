{@decls}
var
{@stubs}
procedure u3_079e;
function u3_1601(Mode: Byte): Byte;
procedure u3_acdd;
{@body}
procedure u3_af56;
var
  I: Word;
  KeyCode: Word;
begin
  u3_079e;
  I := 0;
  Inc(I); d_3812[I] := 'ORDERING THE SECRET AGENT SERIES!';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '    Please specify disk size:';
  Inc(I); d_3812[I] := '         5.25"  or  3.5"';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '   To order send $34, check or';
  Inc(I); d_3812[I] := '   money order (USA funds) to:';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '         Apogee Software';
  Inc(I); d_3812[I] := '         P.O. Box 476386';
  Inc(I); d_3812[I] := '     Garland, TX 75047  (USA)';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '     Or CALL NOW toll free:';
  Inc(I); d_3812[I] := '         1-800-GAME123';
  Inc(I); d_3812[I] := '     (Visa and MasterCard)';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '    Continued...Press Any Key';
  Inc(I); d_3812[I] := 'END OF WINDOW';
  MemW[0:$41C] := MemW[0:$41A];
  KeyCode := u3_1601(1);
  d_6EC5 := 1;
  u3_acdd;
  u3_079e;
  I := 0;
  Inc(I); d_3812[I] := ' USE YOUR FAX MACHINE TO ORDER!';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := 'You can now use your FAX machine';
  Inc(I); d_3812[I] := ' to order your favorite Apogee';
  Inc(I); d_3812[I] := '   games quickly and easily.';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := ' Simply print out the ORDER.FRM';
  Inc(I); d_3812[I] := '  file, fill it out and FAX it';
  Inc(I); d_3812[I] := '  to us for prompt processing.';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '   FAX Orders: (214) 278-4670';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '          Press Any Key';
  Inc(I); d_3812[I] := 'END OF WINDOW';
  MemW[0:$41C] := MemW[0:$41A];
  KeyCode := u3_1601(1);
  d_6EC5 := 1;
  u3_acdd;
end;

