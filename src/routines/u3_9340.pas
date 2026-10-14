{@decls}
type
  TMenuText = array[1..299] of String[40];
var
  d_67FA: Byte;
  d_67FB: Byte;
  d_67FC: Byte;
  d_67FD: Byte;
  d_67FE: Byte;
  d_67FF: Byte;
  d_6800: Byte;
  d_6801: Byte;
  d_6802: Byte;
  d_6803: Byte;
  d_6804: Byte;
  d_6805: Byte;
  d_6806: Byte;
  d_6807: Byte;
  d_6814: Word;
  d_699E: Word;
  d_6D60: Word;
{@stubs}
procedure u3_079e;
function u3_1601(Mode: Byte): Byte;
procedure u3_4e64;
procedure u3_6ea9;
function u3_9163: Integer;
procedure u3_9a71;
procedure u3_9bdf;
procedure u3_a027;
procedure u3_b898;
procedure u3_c10d;
procedure u3_cf40;
procedure u3_d323;
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

  d_67FA := $31;
  d_67FB := $17;
  d_67FC := $23;
  d_67FD := $13;
  d_67FE := $1F;
  d_67FF := $18;
  d_6800 := $10;
  d_6801 := 1;
  d_6802 := $39;
  d_6803 := $1C;
  d_6804 := $21;
  d_6805 := $1E;
  d_6806 := $2E;
  d_6807 := $2F;

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







