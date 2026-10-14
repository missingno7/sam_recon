{@decls}

{@stubs}

{@body}
procedure u3_b4d6;
var
  Row: Word;
  ModeResult: Word;
begin
  u3_079e;
  Row := 0;
  Inc(Row);
  d_3812[Row] := 'ORDERING THE SECRET AGENT SERIES!';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := '     Order now and receive:';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := '  * All three devious missions';
  Inc(Row);
  d_3812[Row] := '  * The hints and tricks sheet';
  Inc(Row);
  d_3812[Row] := '  * The secret cheat password';
  Inc(Row);
  d_3812[Row] := '  * Exciting new bonus game';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := '    To order, call toll free:';
  Inc(Row);
  d_3812[Row] := '         1-800-426-3123';
  Inc(Row);
  d_3812[Row] := '  (Visa and MasterCard Welcome)';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := 'Foreign orders:  Please read the';
  Inc(Row);
  d_3812[Row] := '  "Foreign Orders" menu option.';
  Inc(Row);
  d_3812[Row][0] := #0;
  Inc(Row);
  d_3812[Row] := '    Continued...Press Any Key';
  Inc(Row);
  d_3812[Row] := 'END OF WINDOW';
  MemW[0:$041C] := MemW[0:$041A];
  ModeResult := u3_1601(1);
  d_6EC5 := 1;
  u3_acdd;
end;
