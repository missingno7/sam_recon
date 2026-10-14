{@decls}

{@stubs}

{@body}
procedure u3_b898;
var
  I: Word;
  KeyCode: Word;
begin
  u3_079e;
  I := 0;
  Inc(I); d_3812[I] := 'ORDERING THE SECRET AGENT SERIES!';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := ' Secret Agent consists of three';
  Inc(I); d_3812[I] := 'original and incredible missions:';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '  1) The Hunt for Red Rock Rover';
  Inc(I); d_3812[I] := '  2) Kill Again Island';
  Inc(I); d_3812[I] := '  3) Dr. No Body';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := ' You may order the entire series';
  Inc(I); d_3812[I] := ' for only $30, plus $4 shipping.';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := ' Each episode is set on a unique';
  Inc(I); d_3812[I] := 'island, with all-new dangers, new';
  Inc(I); d_3812[I] := ' levels, and all-new challenges.';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := '    Continued...Press Any Key';
  Inc(I); d_3812[I] := 'END OF WINDOW';
  MemW[0:$41C] := MemW[0:$41A];
  KeyCode := u3_1601(1);
  d_6EC5 := 1;
  u3_acdd;
  u3_b4d6;
  u3_af56;
end;
