{@decls}
type
  TMenuText = array[1..299] of String[40];
{@stubs}

{@body}
function u3_9340: Char;
var
  I: Word;
begin
  I := 0;
  u3_079e;
  Inc(I); d_3812[I] := '     MAIN MENU';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := ' N)ew Game';
  Inc(I); d_3812[I] := ' R)estore Old Game';
  Inc(I); d_3812[I] := ' S)tory';
  Inc(I); d_3812[I] := ' I)nstructions';
  Inc(I); d_3812[I] := ' H)igh Scores';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := ' O)rdering Info.';
  Inc(I); d_3812[I] := ' F)oreign Orders';
  Inc(I); d_3812[I] := ' C)all Our BBS';
  Inc(I); d_3812[I] := ' V)ideo Support';
  Inc(I); d_3812[I] := ' A)bout Apogee';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := ' Q)uit to DOS';
  Inc(I); d_3812[I][0] := #0;
  Inc(I); d_3812[I] := 'Make a selection: ^';
  Inc(I); d_3812[I] := 'END OF WINDOW';

  d_67FA[1] := $31;
  d_67FA[2] := $17;
  d_67FA[3] := $23;
  d_67FA[4] := $13;
  d_67FA[5] := $1F;
  d_67FA[6] := $18;
  d_67FA[7] := $10;
  d_67FA[8] := 1;
  d_67FA[9] := $39;
  d_67FA[10] := $1C;
  d_67FA[11] := $21;
  d_67FA[12] := $1E;
  d_67FA[13] := $2E;
  d_67FA[14] := $2F;

  d_6814 := u3_1601(0);
  case d_6814 of
    $31, $39, $1C:
      begin
        u3_9340 := 'B';
        d_6EC7 := 0;
        d_699E := 1;
      end;
    $17:
      begin
        u3_4e64;
        u3_9340 := 'I';
      end;
    $21:
      begin
        u3_c10d;
        u3_9340 := 'F';
      end;
    $2E:
      begin
        u3_cf40;
        u3_9340 := 'A';
      end;
    $23:
      begin
        u3_9340 := 'H';
        u3_9a71;
      end;
    $1E:
      begin
        u3_9340 := 'A';
        u3_d323;
      end;
    $2F:
      begin
        u3_9340 := 'V';
        u3_a027;
      end;
    $13:
      begin
        u3_9340 := 'R';
        d_699E := 1;
        d_6D60 := u3_9163;
        if d_6D60 = $1C then
        begin
          d_6D60 := 0;
          u3_9340 := ' ';
        end
        else
          d_6EC7 := 0;
      end;
    $1F:
      begin
        u3_9340 := 'S';
        u3_6ea9;
      end;
    $18:
      begin
        u3_9340 := 'O';
        u3_b898;
      end;
    $10:
      begin
        u3_9bdf;
        if d_6EC6 <> 0 then
          u3_9340 := 'Q'
        else
          u3_9340 := ' ';
      end;
    1:
      begin
        d_6EC5 := 0;
        u3_9340 := ' ';
      end;
  end;
end;
