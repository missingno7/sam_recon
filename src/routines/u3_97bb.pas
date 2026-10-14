{@decls}
type
  TString40 = string[40];
var
  d_3812: array[1..299] of TString40;
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
  d_6814: Word;
  d_6816: Byte;
  d_681C: Word;
  d_6EC5: Byte;
  d_6EC6: Byte;
  d_6EC8: Byte;
{@stubs}
procedure u3_079e; { far, ret [0] }
function u3_1601(Mode: Byte): Byte; { far, ret [2] }
procedure u3_4e64; { far, ret [0] }
procedure u3_892b; { far, ret [0] }
procedure u3_8fb6; { far, ret [0] }
function u3_9163: Integer; { far, ret [0] }
procedure u3_9ca9; { far, ret [0] }
procedure u3_9de0; { far, ret [0] }
procedure u3_a027; { far, ret [0] }
procedure u3_a1d8; { far, ret [0] }
procedure u3_a3b6; { far, ret [0] }
{@body}
function u3_97bb: Char;
var
  RestoreResult: Word;
begin
  u3_079e;
  d_3812[1] := 'Operational Command Bank';
  d_3812[2] := '------------------------';
  d_3812[3][0] := #0;
  d_3812[4] := 'H)elp';
  d_3812[5] := 'T)oggle Sounds';
  d_3812[6] := 'V)ideo Select';
  d_3812[7] := 'J)oystick Toggle';
  d_3812[8] := 'C)alibrate Joystick';
  d_3812[9] := 'K)eyboard Config';
  d_3812[10] := 'R)estore Game';
  d_3812[11] := 'S)ave Game';
  d_3812[12] := 'Q)uit';
  d_3812[13][0] := #0;
  d_3812[14] := 'Selection: ^';
  d_3812[15][0] := #0;
  d_3812[16] := 'END OF WINDOW';
  d_67FA := $23;
  d_67FB := $14;
  d_67FC := $2F;
  d_67FD := $24;
  d_67FE := $2E;
  d_67FF := $25;
  d_6800 := $13;
  d_6801 := $1F;
  d_6802 := $10;
  d_6803 := 1;

  d_6814 := u3_1601(0);
  case d_6814 of
    $23:
      begin
        u3_97bb := 'H';
        u3_4e64;
      end;
    $14:
      begin
        u3_97bb := 'T';
        u3_9de0;
      end;
    $2F:
      begin
        u3_97bb := 'V';
        u3_a027;
      end;
    $24:
      begin
        u3_97bb := 'J';
        u3_a1d8;
      end;
    $2E:
      begin
        u3_97bb := 'C';
        u3_a3b6;
      end;
    $25:
      begin
        u3_97bb := 'K';
        u3_892b;
      end;
    $13:
      begin
        u3_97bb := 'R';
        RestoreResult := u3_9163;
        if RestoreResult <> $1C then
          d_6EC8 := 1;
      end;
    $1F:
      begin
        u3_97bb := 'S';
        if d_681C = 1 then
          u3_8fb6
        else
        begin
          u3_079e;
          d_3812[1] := 'You can only save your game';
          d_3812[2] := 'on the island map.  ';
          d_3812[3][0] := #0;
          d_3812[4] := 'Press ESCAPE';
          d_3812[5] := 'END OF WINDOW';
          d_67FA := 1;
          d_6814 := u3_1601(0);
          d_6EC5 := 0;
          d_6816 := 0;
        end;
      end;
    $10:
      begin
        u3_9ca9;
        if d_6EC6 <> 0 then
          u3_97bb := 'Q'
        else
          u3_97bb := ' ';
      end;
  end;
end;
