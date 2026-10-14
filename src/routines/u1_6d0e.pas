{@decls}
type
  TCell = record
    A, B, C: Integer;
    D, E: Byte;
  end;
  TItem = record
    F34CC, F34CE, F34D0, F34D2, F34D4, F34D6, F34D8, F34DA: Integer;
    Reserved: array[0..3] of Byte;
    F34E0, F34E2, F34E4, F34E6, F34E8: Integer;
    F34EA, F34EB: Byte;
  end;
  TSpriteData = array[0..32767] of Byte;
  PSpriteData = ^TSpriteData;
var
  d_0296: array[1..40,1..25] of TCell;
  d_34AE: Byte;
  d_34EC: array[1..25] of TItem;
  d_3812: array[1..299] of String[40];
  d_67FA: Byte;
  d_6814: Word;
  d_6816: Byte;
  d_681C, d_6832: Integer;
  d_6836: Byte;
  d_6840: Integer;
  d_6844: array[1..20] of Byte;
  d_6858: Integer;
  d_699A: LongInt;
  d_699E, d_69A0, d_69A2, d_69A4, d_69A6, d_69A8, d_69AA: Integer;
  d_69AD: Byte;
  d_69AE: Integer;
  d_69B0, d_69B4: Byte;
  d_69B6, d_69B8: Integer;
  d_69BA: array[1..20] of Byte;
  d_69CE, d_69E0: Byte;
  d_69E2, d_69E4, d_69E6: Integer;
  d_69E9, d_69EA, d_69EB, d_69EC, d_69ED, d_69EE: Byte;
  d_69F0, d_69F1, d_69F2, d_69F3, d_69F4, d_69F5, d_69F6: Byte;
  d_6A3E, d_6A40: Byte;
  d_6D18, d_6D1A, d_6D62, d_6D64: Integer;
  d_6D66: Byte;
  d_6D86: PSpriteData;
  d_6EC0, d_6EC1, d_6EC3, d_6EC4, d_6EC5, d_6EC6, d_6ECA, d_6ECB: Byte;
{@stubs}
procedure u1_03f0(X, Y: Integer; Image: Word);
procedure u2_0000(X, Y: Integer);
procedure u2_2530(X, Y: Integer);
procedure u2_a1ae(Level: Integer);
procedure u3_0232(Ticks: Word);
procedure u3_079e;
function u3_1601(Value: Byte): Byte;
procedure u3_3cb8;
procedure u3_9b3e(Text: String);
procedure u3_d820;
procedure u7_0000(Sound: Word);
procedure u8_0a89;
procedure u9_19f9(var Sprite; X, Y: Integer);
{@body}
procedure u1_6d0e(X, Y: Integer);
var
  I, XX, YY: Integer;
begin
  case d_0296[(X shr 4)+1,(Y shr 4)+1].C of
    0: ;
    $1A5,$1A7,$1A9:
      begin
        case d_0296[(X shr 4)+1,(Y shr 4)+1].C of
          $1A5: d_69E9 := 1;
          $1A7: d_69EA := 1;
          $1A9: d_69EB := 1;
        end;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(5);
        d_6832 := -1;
      end;
    $1A6,$1A8,$1AA:
      begin
        I := 0;
        case d_0296[(X shr 4)+1,(Y shr 4)+1].C of
          $1A6: if d_69E9 = 1 then begin I := 1; d_69E9 := 0 end;
          $1A8: if d_69EA = 1 then begin I := 1; d_69EA := 0 end;
          $1AA: if d_69EB = 1 then begin I := 1; d_69EB := 0 end;
        end;
        if I = 1 then
        begin
          d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
          d_0296[(X shr 4)+1,(Y shr 4)+1].D := 0;
          u7_0000(6);
          d_6832 := -1;
        end;
      end;
    $12D:
      begin
        d_6858 := d_6858 + 5;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        if d_6858 > 99 then d_6858 := 99;
        d_6832 := -1;
        u7_0000(5);
      end;
    $13C:
      begin
        d_699A := d_699A + 1000;
        u1_03f0(X and $FFF0,Y and $FFF0,20);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(4);
      end;
    $26A:
      begin
        d_699A := d_699A + 250;
        u1_03f0(X and $FFF0,Y and $FFF0,18);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(4);
      end;
    $26B:
      begin
        d_699A := d_699A + 1000;
        u1_03f0(X and $FFF0,Y and $FFF0,20);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(4);
      end;
    $26C:
      begin
        d_699A := d_699A + 500;
        u1_03f0(X and $FFF0,Y and $FFF0,19);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(4);
      end;
    $275:
      begin
        d_699A := d_699A + 100;
        u1_03f0(X and $FFF0,Y and $FFF0,17);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(4);
      end;
    $276:
      begin
        d_699A := d_699A + 1000;
        u1_03f0(X and $FFF0,Y and $FFF0,20);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(4);
      end;
    $277:
      begin
        d_699A := d_699A + 500;
        u1_03f0(X and $FFF0,Y and $FFF0,19);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(4);
      end;
    $278:
      begin
        d_699A := d_699A + 100;
        u1_03f0(X and $FFF0,Y and $FFF0,17);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(4);
      end;
    $2C:
      begin
        d_699A := d_699A + 500;
        u1_03f0(X and $FFF0,Y and $FFF0,19);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(4);
      end;
    $26D..$26F:
      begin
        case d_0296[(X shr 4)+1,(Y shr 4)+1].C of
          $26D:
            begin
              d_69F0 := 1;
              d_699A := d_699A + 100;
              u1_03f0(X and $FFF0,Y and $FFF0,17);
              d_6832 := -1;
              u7_0000(4);
            end;
          $26E:
            if (d_69F2 <> 0) and (d_69F0 <> 0) then
            begin
              d_69F1 := 1;
              d_699A := d_699A + 100;
              u1_03f0(X and $FFF0,Y and $FFF0,17);
              d_6832 := -1;
              u7_0000(4);
            end
            else
            begin
              d_69F1 := 1;
              d_69F2 := 0;
              d_699A := d_699A + 100;
              u1_03f0(X and $FFF0,Y and $FFF0,17);
              d_6832 := -1;
              u7_0000(4);
            end;
          $26F:
            if (d_69F2 <> 0) and (d_69F0 <> 0) and (d_69F1 <> 0) then
            begin
              d_699A := d_699A + 10000;
              u1_03f0(X and $FFF0,Y and $FFF0,23);
              d_6832 := -1;
              u7_0000(12);
            end
            else
            begin
              d_699A := d_699A + 100;
              u1_03f0(X and $FFF0,Y and $FFF0,17);
              d_6832 := -1;
              d_69F2 := 0;
              u7_0000(4);
            end;
        end;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
      end;
    $25E:
      begin
        d_699A := d_699A + 500;
        u1_03f0(X and $FFF0,Y and $FFF0,19);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(4);
        d_6832 := -1;
      end;
    $130:
      begin
        d_6844[d_681C] := 1;
        d_699A := d_699A + 2000;
        u1_03f0(X and $FFF0,Y and $FFF0,21);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(5);
        d_6D66 := 1;
      end;
    $25F:
      begin
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(4);
        u3_9b3e('You can see invisible platforms.');
        for Y := 1 to 24 do
          for X := 1 to 40 do
            if d_0296[X,Y].C = -1 then
            begin
              d_0296[X,Y].B := $260;
              d_0296[X,Y].E := 1;
              u2_0000((X-1) shl 4,(Y-1) shl 4);
              u2_2530((X-1) shl 4,(Y-1) shl 4);
              d_6840 := 432 - d_6840;
              u2_0000((X-1) shl 4,(Y-1) shl 4);
              u2_2530((X-1) shl 4,(Y-1) shl 4);
              d_6840 := 432 - d_6840;
              u7_0000(7);
              Delay(100);
            end;
      end;
    $201..$204:
      begin
        if d_34AE = 0 then u7_0000(28);
        if d_69F3 = 0 then d_69B4 := 1;
        d_69B6 := 51;
        d_6D62 := d_34EC[1].F34CE;
        d_6D64 := d_34EC[1].F34D0;
        case d_0296[(X shr 4)+1,(Y shr 4)+1].C of
          $113..$122:
            begin
              d_69B8 := d_0296[(X shr 4)+1,(Y shr 4)+1].C - $111;
              d_0296[(X shr 4)+1,(Y shr 4)+1].C := $10C;
            end;
          $10C:
            if d_69B6 > 15 then Inc(d_0296[(X shr 4)+1,(Y shr 4)+1].C);
          $10D:
            if d_69B6 > 30 then Inc(d_0296[(X shr 4)+1,(Y shr 4)+1].C);
        end;
        if d_69B6 > 50 then
        begin
          d_69B8 := d_0296[(X shr 4)+1,(Y shr 4)+1].A;
          d_69B6 := 0;
          u3_0232(20);
          d_681C := d_69B8;
          u3_3cb8;
          if d_6D18 > (X and $FFF0) + 8 then
            d_6D18 := (d_6D18 and $FFF0) + 16
          else
            d_6D18 := (d_6D18 + 8) and $FFF0;
          if d_6D1A > (Y and $FFF0) + 8 then
            d_6D1A := (d_6D1A and $FFF0) + 16
          else
            d_6D1A := (d_6D1A + 8) and $FFF0;
          u2_a1ae(d_69B8);
          u8_0a89;
          d_69BA[d_69B8] := 1;
          d_6EC4 := 0;
          d_6EC3 := 0;
        end;
      end;
    $27B:
      begin
        d_69F4 := 1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(5);
        d_6832 := -1;
        u1_03f0(X and $FFF0,Y and $FFF0,19);
        d_699A := d_699A + 500;
      end;
    $27D:
      begin
        if d_69F4 = 1 then
        begin
          d_69F4 := 0;
          u7_0000(11);
          d_6832 := -1;
          if d_34EC[1].F34CE + 5 > X then
          begin
            XX := ((X shr 4)+1) shl 4;
            YY := Y and $FFF0;
          end
          else
          begin
            XX := ((X shr 4)-1) shl 4;
            YY := Y and $FFF0;
          end;
          u9_19f9(d_6D86^[$1543],XX,YY+16);
          u9_19f9(d_6D86^[$1543],XX,YY+416);
          I := 1;
          repeat
            Inc(I);
          until (d_34EC[I].F34EA = 1) or (I = 25);
          d_34EC[I].F34CC := 0;
          d_34EC[I].F34E0 := $27B;
          d_34EC[I].F34CE := XX;
          d_34EC[I].F34D0 := YY;
          d_34EC[I].F34D2 := XX;
          d_34EC[I].F34D4 := YY;
          d_34EC[I].F34E2 := 1;
          d_34EC[I].F34E4 := 0;
          d_34EC[I].F34D6 := 1;
          d_34EC[I].F34E6 := 0;
          d_34EC[I].F34D8 := 40;
          d_34EC[I].F34DA := 0;
          d_34EC[I].F34E8 := 22;
          d_34EC[I].F34EA := 0;
          d_34EC[I].F34EB := 0;
          d_69EE := 1;
        end
        else
          if d_69EE = 0 then
          begin
            d_69EE := 1;
            u3_079e;
            d_3812[1] := 'You have no way to open';
            d_3812[2] := 'this door right now.   ';
            d_3812[3][0] := #0;
            d_3812[4] := 'Press ESCAPE  ';
            d_3812[5] := 'END OF WINDOW';
            d_67FA := 1;
            d_6814 := u3_1601(0);
            d_6EC5 := 0;
            d_6816 := 0;
          end;
      end;
    $27E:
      begin
        if d_69CE <> 0 then
        begin
          if d_6D66 <> 0 then d_6EC6 := 1;
          d_6A3E := 1;
          d_69BA[d_681C] := 1;
          if d_6A40 = 3 then
          begin
            u3_d820;
            d_699A := d_699A + 25000;
            d_6832 := -1;
          end;
          if (X shr 4 = 0) or
             (d_0296[((X shr 4)+1)-1,(Y shr 4)+1].D = 1) then
          begin
            d_34EC[1].F34D2 := d_34EC[1].F34CE;
            d_34EC[1].F34D4 := d_34EC[1].F34D0;
            d_34EC[1].F34CE := (X and $FFF0) + 16;
            d_34EC[1].F34D0 := Y and $FFF0;
            d_34EC[1].F34E2 := -1;
            d_34EC[1].F34E0 := 5;
            d_6EC1 := 0;
            d_6EC0 := 0;
            d_6ECA := 1;
            d_6ECB := 0;
          end
          else
          begin
            d_34EC[1].F34D2 := d_34EC[1].F34CE;
            d_34EC[1].F34D4 := d_34EC[1].F34D0;
            d_34EC[1].F34CE := (X and $FFF0) - 16;
            d_34EC[1].F34D0 := Y and $FFF0;
            d_34EC[1].F34E2 := 1;
            d_34EC[1].F34E0 := 1;
            d_6EC1 := 0;
            d_6EC0 := 0;
            d_6ECA := 0;
            d_6ECB := 1;
          end;
        end
        else
          if d_681C > 1 then
          begin
            u7_0000(15);
            u3_079e;
            d_3812[1] := '     MISSION ALERT!    ';
            d_3812[2] := '                       ';
            d_3812[3] := 'You failed to destroy a';
            d_3812[4] := 'vital radar dish. Find ';
            d_3812[5] := 'and destroy! ';
            d_3812[6] := '                       ';
            d_3812[7] := 'Press ESCAPE!          ';
            d_3812[8] := 'END OF WINDOW';
            d_67FA := 1;
            d_6814 := u3_1601(0);
            d_6EC5 := 0;
            d_6816 := 0;
            if (X shr 4 = 0) or
               (d_0296[((X shr 4)+1)-1,(Y shr 4)+1].D = 1) then
            begin
              d_34EC[1].F34D2 := d_34EC[1].F34CE;
              d_34EC[1].F34D4 := d_34EC[1].F34D0;
              d_34EC[1].F34CE := (X and $FFF0) + 16;
              d_34EC[1].F34D0 := Y and $FFF0;
              d_34EC[1].F34E0 := 10;
              d_6EC1 := 0;
              d_6EC0 := 0;
              d_6ECA := 0;
              d_6ECB := 0;
            end
            else
            begin
              d_34EC[1].F34D2 := d_34EC[1].F34CE;
              d_34EC[1].F34D4 := d_34EC[1].F34D0;
              d_34EC[1].F34CE := (X and $FFF0) - 16;
              d_34EC[1].F34D0 := Y and $FFF0;
              d_34EC[1].F34E0 := 9;
              d_6EC1 := 0;
              d_6EC0 := 0;
              d_6ECA := 0;
              d_6ECB := 0;
            end;
          end;
      end;
    $270:
      begin
        I := 1;
        repeat
          Inc(I);
        until (d_34EC[I].F34EA = 1) or (I = 25);
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        d_34EC[I].F34CC := 0;
        d_34EC[I].F34E0 := $271;
        d_34EC[I].F34CE := X and $FFF0;
        d_34EC[I].F34D0 := Y and $FFF0;
        d_34EC[I].F34D2 := X and $FFF0;
        d_34EC[I].F34D4 := Y and $FFF0;
        d_34EC[I].F34E2 := 1;
        d_34EC[I].F34E4 := 0;
        d_34EC[I].F34D6 := 1;
        d_34EC[I].F34E6 := 0;
        d_34EC[I].F34D8 := 40;
        d_34EC[I].F34DA := 0;
        d_34EC[I].F34E8 := 23;
        d_34EC[I].F34EA := 0;
        d_34EC[I].F34EB := 0;
        if d_69F3 = 0 then d_69B4 := 1;
        if (d_69F5 = 0) and (d_69F3 = 0) then
        begin
          d_69F5 := 1;
          d_69F6 := 35;
        end;
        d_6EC3 := 0;
        d_6EC4 := 0;
        d_6ECA := 0;
        d_6ECB := 0;
        d_6EC1 := 0;
      end;
    $1F3,$25B,$265,$267,$268:
      if d_69F3 = 0 then
      begin
        d_69F5 := 1;
        d_69F6 := 35;
        u7_0000(22);
      end;
    $25C:
      begin
        if d_69EC = 1 then
        begin
          d_69EC := 0;
          d_69ED := 1;
          d_0296[(X shr 4)+1,(Y shr 4)+1].D := 0;
          u7_0000(24);
          for Y := 1 to 24 do
            for X := 1 to 40 do
              if d_0296[X,Y].C = $25B then
              begin
                d_0296[X,Y].C := 0;
                u2_0000((X-1) shl 4,(Y-1) shl 4);
                u2_2530((X-1) shl 4,(Y-1) shl 4);
                d_6840 := 432 - d_6840;
                u2_0000((X-1) shl 4,(Y-1) shl 4);
                u2_2530((X-1) shl 4,(Y-1) shl 4);
                d_6840 := 432 - d_6840;
              end;
          u3_9b3e('Laser Field has been De-Activated.');
        end
        else
          if d_69ED = 0 then
          begin
            u7_0000(25);
            d_69ED := 1;
            u3_079e;
            d_3812[1] := 'The computer needs a floppy';
            d_3812[2] := 'disk to operate.';
            d_3812[3][0] := #0;
            d_3812[4] := 'Press ESCAPE';
            d_3812[5] := 'END OF WINDOW';
            d_67FA := 1;
            d_6814 := u3_1601(0);
            d_6EC5 := 0;
            d_6816 := 0;
          end;
      end;
    $25D:
      begin
        d_69EC := 1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(5);
        d_6832 := -1;
        u1_03f0(X and $FFF0,Y and $FFF0,19);
        d_699A := d_699A + 500;
      end;
    $B7:
      begin
        X := X and $FFF0;
        if (((d_34EC[1].F34CE > X) and (d_34EC[1].F34CE-X <= 2)) or
            ((d_34EC[1].F34CE < X) and (X-d_34EC[1].F34CE <= 2))) and
           (d_69E0 = 0) then
        begin
          d_6832 := -1;
          u7_0000(23);
          for YY := 1 to 24 do
            for XX := 1 to 40 do
              if d_0296[XX,YY].C = $B7 then
                if (((X shr 4)+1) <> XX) or (((Y shr 4)+1) <> YY) then
                begin
                  d_69E4 := (XX-1) shl 4;
                  d_69E6 := (YY-1) shl 4;
                  if d_0296[d_69E4 shr 4,(d_69E6 shr 4)+1].D <> 0 then
                    d_69E4 := d_69E4 + 3
                  else
                    d_69E4 := d_69E4 - 3;
                  XX := 40;
                  YY := 24;
                end;
          d_69E0 := 1;
          d_69E2 := 19;
          d_69B4 := 1;
          if (d_6ECB = 1) or (d_34EC[1].F34E0 = 1) then
            d_34EC[1].F34E0 := 9
          else
            d_34EC[1].F34E0 := 10;
          d_6EC3 := 0;
          d_6EC4 := 0;
          d_6ECA := 0;
          d_6ECB := 0;
          d_6EC1 := 0;
        end;
      end;
    $139:
      begin
        d_699A := d_699A + 250;
        u1_03f0(X and $FFF0,Y and $FFF0,18);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(5);
        d_69A4 := 4;
        d_69A6 := 216;
      end;
    $143..$145:
      begin
        d_699A := d_699A + 100;
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        d_0296[(X shr 4)+1,(Y shr 4)+1].E := 0;
        u7_0000(4);
      end;
    $142:
      begin
        d_699A := d_699A + 1000;
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(5);
        d_6836 := 2;
        d_69A8 := 432;
      end;
    $31:
      begin
        d_699A := d_699A + 100;
        d_6832 := -1;
        Inc(d_69A0);
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(5);
      end;
    $13A:
      begin
        d_699A := d_699A + 5000;
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(5);
        Inc(d_69A2);
        if d_69A2 > 2 then d_69A2 := 2;
        u3_9b3e('Increased Shot Power!');
      end;
    $1D2:
      begin
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(26);
        d_69AD := 1;
        d_6ECA := 0;
        d_6ECB := 0;
        d_69AA := 216;
        u3_9b3e('YOU FEEL A BIT CONFUSED!');
      end;
    $1D4:
      begin
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(27);
        d_69B0 := 1;
        d_69AE := 216;
      end;
    $269:
      begin
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].C := 0;
        u7_0000(5);
        Inc(d_699E);
      end;
  end;
end;
