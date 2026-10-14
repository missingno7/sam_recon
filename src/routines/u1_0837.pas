{@decls}
type
  TCell = record
    A, B, C: Word;
    D, E: Byte;
  end;
  TItem = record
    Timer, X, Y, OldX, OldY, Frame, Counter, Limit, F34dc, F34de,
    Sprite, DX, DY, Speed, Kind: Integer;
    Active, Flags: Byte;
  end;
  TSpriteBytes = array[0..32767] of Byte;
  PSpriteBytes = ^TSpriteBytes;
var
  d_34CC: array[0..64] of TItem;
  d_6832: Word;
  d_683C, d_6840: Integer;
  d_699A: LongInt;
  d_6D96, d_6DAE: PSpriteBytes;
{@stubs}
procedure u1_01c4(X, Y: Integer);
function u1_027c(X, Y: Integer): Boolean;
procedure u1_0584(X, Y, Direction, Sprite, Kind: Integer);
procedure u2_0000(X, Y: Integer);
procedure u2_2530(X, Y: Integer);
procedure u7_0000(N: Integer);
procedure u9_19f9(var Source; X, Y: Integer);
{@body}
procedure u1_0837(X, Y: Integer; Item: Word; I, J: Word);
var
  X1, Y2, X2, Y1: Integer;
begin
  case d_34CC[Item].Kind of
    1:
    begin
      X1 := (X shr 4) + 1;
      Y1 := (Y shr 4) + 1;
      Y2 := Y1 + 1;
      X2 := ((X + 15) shr 4) + 1;
      if d_0296[X1, Y1].D <> 0 then
      begin
        d_34CC[Item].DX := 1;
        d_34CC[Item].Frame := 1;
      end
      else if d_0296[X2, Y1].D <> 0 then
      begin
        d_34CC[Item].DX := -1;
        d_34CC[Item].Frame := 21;
      end
      else if (d_0296[X1, Y2].D = 0) and
              (d_0296[X1, Y2].E = 0) then
      begin
        d_34CC[Item].DX := 1;
        d_34CC[Item].Frame := 1;
      end
      else if (d_0296[X2, Y2].D = 0) and
              (d_0296[X2, Y2].E = 0) then
      begin
        d_34CC[Item].DX := -1;
        d_34CC[Item].Frame := 21;
      end;
      Inc(d_34CC[Item].Frame);
      if d_34CC[Item].DX = 1 then
      begin
        if d_34CC[Item].Frame > 19 then
          d_34CC[Item].Frame := 1;
      end
      else
      begin
        if d_34CC[Item].Frame > 39 then
          d_34CC[Item].Frame := 21;
      end;
      d_34CC[Item].X := X;
      u1_01c4(d_34CC[Item].X, d_34CC[Item].Y);
      if u1_027c(d_34CC[Item].X, d_34CC[Item].Y) then
      begin
        u7_0000(19);
        d_699A := d_699A + 100;
        d_6832 := $FFFF;
        d_34CC[Item].Kind := 5000;
        d_34CC[Item].Sprite := 391;
        d_34CC[Item].Frame := 1;
        d_34CC[Item].Speed := 0;
        u9_19f9(d_6DAE^[6403], d_34CC[Item].X, d_34CC[Item].Y + 16);
        u9_19f9(d_6DAE^[6403], d_34CC[Item].X, d_34CC[Item].Y + 416);
      end;
    end;
    2:
    begin
      X1 := (X shr 4) + 1;
      Y1 := (Y shr 4) + 1;
      Y2 := Y1 + 1;
      X2 := ((X + 15) shr 4) + 1;
      if d_0296[X1, Y1].D <> 0 then
      begin
        d_34CC[Item].DX := 1;
        d_34CC[Item].Frame := 1;
      end
      else if d_0296[X2, Y1].D <> 0 then
      begin
        d_34CC[Item].DX := -1;
        d_34CC[Item].Frame := 21;
      end
      else if (d_0296[X1, Y2].D = 0) and
              (d_0296[X1, Y2].E = 0) then
      begin
        d_34CC[Item].DX := 1;
        d_34CC[Item].Frame := 1;
      end
      else if (d_0296[X2, Y2].D = 0) and
              (d_0296[X2, Y2].E = 0) then
      begin
        d_34CC[Item].DX := -1;
        d_34CC[Item].Frame := 21;
      end;
      Inc(d_34CC[Item].Frame);
      if d_34CC[Item].DX = 1 then
      begin
        if d_34CC[Item].Frame > 19 then
          d_34CC[Item].Frame := 1;
      end
      else
      begin
        if d_34CC[Item].Frame > 39 then
          d_34CC[Item].Frame := 21;
      end;
      d_34CC[Item].X := X;
      u1_01c4(d_34CC[Item].X, d_34CC[Item].Y);
      if u1_027c(d_34CC[Item].X, d_34CC[Item].Y) then
      begin
        u7_0000(8);
        Dec(d_34CC[Item].Kind);
        d_34CC[Item].Timer := 3;
        d_34CC[Item].Sprite := 351;
        d_34CC[Item].Speed := 1;
        d_34CC[Item].Counter := Random(50) + 50;
        d_34CC[Item].Limit := 0;
        if d_34CC[Item].X < d_34CC[1].X then
          d_34CC[Item].DX := 1
        else
          d_34CC[Item].DX := -1;
        if d_34CC[Item].DX = 1 then
          d_34CC[Item].Frame := 1
        else
          d_34CC[Item].Frame := 21;
      end;
    end;
    3:
    begin
      X1 := (X shr 4) + 1;
      Y1 := (Y shr 4) + 1;
      Y2 := Y1 + 1;
      X2 := ((X + 15) shr 4) + 1;
      if d_0296[X1, Y1].D <> 0 then
      begin
        d_34CC[Item].DX := 1;
        d_34CC[Item].Frame := 1;
      end
      else if d_0296[X2, Y1].D <> 0 then
      begin
        d_34CC[Item].DX := -1;
        d_34CC[Item].Frame := 21;
      end
      else if (d_0296[X1, Y2].D = 0) and
              (d_0296[X1, Y2].E = 0) then
      begin
        d_34CC[Item].DX := 1;
        d_34CC[Item].Frame := 1;
      end
      else if (d_0296[X2, Y2].D = 0) and
              (d_0296[X2, Y2].E = 0) then
      begin
        d_34CC[Item].DX := -1;
        d_34CC[Item].Frame := 21;
      end;
      Inc(d_34CC[Item].Frame);
      if d_34CC[Item].DX = 1 then
      begin
        if d_34CC[Item].Frame > 19 then
          d_34CC[Item].Frame := 1;
      end
      else
      begin
        if d_34CC[Item].Frame > 39 then
          d_34CC[Item].Frame := 21;
      end;
      d_34CC[Item].X := X;
      if u1_027c(d_34CC[Item].X, d_34CC[Item].Y) then
      begin
        u7_0000(8);
        Dec(d_34CC[Item].Kind);
        d_34CC[Item].Sprite := 359;
        d_34CC[Item].Timer := 3;
        d_34CC[Item].Speed := 2;
        if d_34CC[Item].X < d_34CC[1].X then
          d_34CC[Item].DX := 1
        else
          d_34CC[Item].DX := -1;
        if d_34CC[Item].DX = 1 then
          d_34CC[Item].Frame := 1
        else
          d_34CC[Item].Frame := 21;
      end
      else
        u1_01c4(d_34CC[Item].X, d_34CC[Item].Y);
    end;
    4:
    begin
      X1 := (X shr 4) + 1;
      Y1 := (Y shr 4) + 1;
      Y2 := Y1 + 1;
      X2 := ((X + 15) shr 4) + 1;
      if d_0296[X1, Y1].D <> 0 then
      begin
        d_34CC[Item].DX := 1;
        d_34CC[Item].Frame := 1;
      end
      else if d_0296[X2, Y1].D <> 0 then
      begin
        d_34CC[Item].DX := -1;
        d_34CC[Item].Frame := 21;
      end
      else if (d_0296[X1, Y2].D = 0) and
              (d_0296[X1, Y2].E = 0) then
      begin
        d_34CC[Item].DX := 1;
        d_34CC[Item].Frame := 1;
      end
      else if (d_0296[X2, Y2].D = 0) and
              (d_0296[X2, Y2].E = 0) then
      begin
        d_34CC[Item].DX := -1;
        d_34CC[Item].Frame := 21;
      end;
      Inc(d_34CC[Item].Frame);
      if d_34CC[Item].DX = 1 then
      begin
        if d_34CC[Item].Frame > 19 then
          d_34CC[Item].Frame := 1;
      end
      else
      begin
        if d_34CC[Item].Frame > 39 then
          d_34CC[Item].Frame := 21;
      end;
      Inc(d_34CC[Item].Limit);
      if d_34CC[Item].Limit >= d_34CC[Item].Counter then
      begin
        if (d_34CC[Item].Y shr 4) = ((d_34CC[1].Y + 8) shr 4) then
        begin
          if ((d_34CC[Item].X < d_34CC[1].X) and (d_34CC[Item].DX = 1)) or
             ((d_34CC[Item].X > d_34CC[1].X) and (d_34CC[Item].DX = -1)) then
          begin
            d_34CC[Item].Limit := 0;
            u1_0584(d_34CC[Item].X, d_34CC[Item].Y, d_34CC[Item].DX, 4, 0);
          end;
        end;
      end;
      d_34CC[Item].X := X;
      u1_01c4(d_34CC[Item].X, d_34CC[Item].Y);
      if u1_027c(d_34CC[Item].X, d_34CC[Item].Y) then
      begin
        u7_0000(8);
        Dec(d_34CC[Item].Kind);
        d_34CC[Item].Sprite := 367;
        d_34CC[Item].Timer := 3;
        d_34CC[Item].Speed := 3;
        if d_34CC[Item].X < d_34CC[1].X then
          d_34CC[Item].DX := 1
        else
          d_34CC[Item].DX := -1;
        if d_34CC[Item].DX = 1 then
          d_34CC[Item].Frame := 1
        else
          d_34CC[Item].Frame := 21;
      end;
    end;
    5:
    begin
      X1 := (X shr 4) + 1;
      Y1 := (Y shr 4) + 1;
      Y2 := Y1 + 1;
      X2 := ((X + 15) shr 4) + 1;
      if d_0296[X1, Y1].D <> 0 then
      begin
        d_34CC[Item].DX := 1;
        d_34CC[Item].Frame := 1;
      end
      else if d_0296[X2, Y1].D <> 0 then
      begin
        d_34CC[Item].DX := -1;
        d_34CC[Item].Frame := 21;
      end
      else if (d_0296[X1, Y2].D = 0) and
              (d_0296[X1, Y2].E = 0) then
      begin
        d_34CC[Item].DX := 1;
        d_34CC[Item].Frame := 1;
      end
      else if (d_0296[X2, Y2].D = 0) and
              (d_0296[X2, Y2].E = 0) then
      begin
        d_34CC[Item].DX := -1;
        d_34CC[Item].Frame := 21;
      end;
      Inc(d_34CC[Item].Frame);
      if d_34CC[Item].DX = 1 then
      begin
        if d_34CC[Item].Frame > 19 then
          d_34CC[Item].Frame := 1;
      end
      else
      begin
        if d_34CC[Item].Frame > 39 then
          d_34CC[Item].Frame := 21;
      end;
      Inc(d_34CC[Item].Limit);
      if d_34CC[Item].Limit >= d_34CC[Item].Counter then
      begin
        if (d_34CC[Item].Y shr 4) = ((d_34CC[1].Y + 8) shr 4) then
        begin
          if ((d_34CC[Item].X < d_34CC[1].X) and (d_34CC[Item].DX = 1)) or
             ((d_34CC[Item].X > d_34CC[1].X) and (d_34CC[Item].DX = -1)) then
          begin
            d_34CC[Item].Limit := 0;
            u1_0584(d_34CC[Item].X, d_34CC[Item].Y, d_34CC[Item].DX, 4, 0);
          end;
        end;
      end;
      d_34CC[Item].X := X;
      u1_01c4(d_34CC[Item].X, d_34CC[Item].Y);
      if u1_027c(d_34CC[Item].X, d_34CC[Item].Y) then
      begin
        u7_0000(8);
        Dec(d_34CC[Item].Kind);
        d_34CC[Item].Sprite := 375;
        d_34CC[Item].Timer := 3;
        if d_34CC[Item].X < d_34CC[1].X then
          d_34CC[Item].DX := 1
        else
          d_34CC[Item].DX := -1;
        if d_34CC[Item].DX = 1 then
          d_34CC[Item].Frame := 1
        else
          d_34CC[Item].Frame := 21;
      end;
    end;
    6:
    begin
      if (d_0296[(X shr 4) + 1, (Y shr 4) + 1].D <> 0) or
         (d_0296[((X + 15) shr 4) + 1, (Y shr 4) + 1].D <> 0) then
        d_34CC[Item].DX := -d_34CC[Item].DX;
      Inc(d_34CC[Item].Frame);
      if d_34CC[Item].Frame > 19 then
        d_34CC[Item].Frame := 1;
      d_34CC[Item].X := X;
      u1_01c4(d_34CC[Item].X, d_34CC[Item].Y);
      if d_34CC[Item].Sprite = 625 then
      begin
        Dec(d_34CC[Item].Limit);
        if d_34CC[Item].Limit <= 0 then
        begin
          d_34CC[Item].Flags := 1;
          u2_0000(X, Y);
          u2_0000(X - 16, Y);
          u2_0000(X + 16, Y);
          u2_2530(X, Y);
          u2_2530(X - 16, Y);
          u2_2530(X + 16, Y);
        end;
      end
      else
      begin
        if u1_027c(d_34CC[Item].X, d_34CC[Item].Y) then
        begin
          u7_0000(8);
          Dec(d_34CC[Item].Counter);
          d_34CC[Item].Timer := 3;
          if d_34CC[Item].Counter <= 0 then
          begin
            d_34CC[Item].Sprite := 625;
            d_34CC[Item].Frame := 1;
            d_34CC[Item].Speed := 1;
          end;
        end;
      end;
    end;
    7:
    begin
      Y2 := (Y shr 4) + 1;
      if (d_0296[(X shr 4) + 1, Y2].D <> 0) or
         (d_0296[((X + 15) shr 4) + 1, Y2].D <> 0) then
      begin
        d_34CC[Item].Flags := 1;
        u2_0000(X, Y);
        u2_0000(X - 16, Y);
        u2_0000(X + 16, Y);
        u2_2530(X, Y);
        u2_2530(X - 16, Y);
        u2_2530(X + 16, Y);
      end
      else
      begin
        d_34CC[Item].X := X;
        X1 := d_34CC[1].X - d_34CC[Item].X;
        Y2 := d_34CC[1].Y - d_34CC[Item].Y;
        if (X1 < 8) and (X1 > -8) and (Y2 < 8) and (Y2 > -8) then
        begin
          if d_69F3 = 0 then
          begin
            if d_69F5 = 0 then
            begin
              if d_6A40 > 1 then
              begin
                if d_6A41 = 0 then
                begin
                  d_6A41 := 1;
                  d_6A42 := 30;
                  Dec(d_6A40);
                  d_6832 := $FFFF;
                  d_34CC[1].Timer := 5;
                end;
              end
              else
              begin
                if d_6A41 = 0 then
                begin
                  d_69F5 := 1;
                  d_69F6 := 35;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
    10, 12:
    begin
      Inc(d_34CC[Item].Limit);
      if d_34CC[Item].Limit >= d_34CC[Item].Counter then
      begin
        if (d_34CC[Item].Y and $FFF0) = ((d_34CC[1].Y + 8) and $FFF0) then
        begin
          if d_34CC[Item].X < d_34CC[1].X then
          begin
            d_34CC[Item].Limit := 0;
            if d_34CC[Item].Kind = 10 then
              u1_0584(d_34CC[Item].X + 8, d_34CC[Item].Y, 1, 4, 470)
            else
              u1_0584(d_34CC[Item].X + 16, d_34CC[Item].Y, 1, 4, 488);
          end;
        end;
      end;
    end;
    11, 13:
    begin
      Inc(d_34CC[Item].Limit);
      if d_34CC[Item].Limit >= d_34CC[Item].Counter then
      begin
        if (d_34CC[Item].Y and $FFF0) = ((d_34CC[1].Y + 8) and $FFF0) then
        begin
          if d_34CC[Item].X > d_34CC[1].X then
          begin
            d_34CC[Item].Limit := 0;
            if d_34CC[Item].Kind = 11 then
              u1_0584(d_34CC[Item].X - 8, d_34CC[Item].Y, -1, 4, 470)
            else
              u1_0584(d_34CC[Item].X - 16, d_34CC[Item].Y, -1, 4, 492);
          end;
        end;
      end;
    end;
    14:
    begin
      Y2 := (Y shr 4) + 1;
      if (d_0296[(X shr 4) + 1, Y2].D <> 0) or
         (d_0296[((X + 15) shr 4) + 1, Y2].D <> 0) then
      begin
        d_34CC[Item].Flags := 1;
        u2_0000(X, Y);
        u2_0000(X - 16, Y);
        u2_0000(X + 16, Y);
        u2_2530(X, Y);
        u2_2530(X - 16, Y);
        u2_2530(X + 16, Y);
      end
      else
      begin
        Inc(d_34CC[Item].Frame);
      if d_34CC[Item].DX = 1 then
      begin
        if d_34CC[Item].Frame > 19 then
          d_34CC[Item].Frame := 1;
      end
      else
      begin
        if d_34CC[Item].Frame > 39 then
          d_34CC[Item].Frame := 21;
      end;
        d_34CC[Item].X := X;
        u1_01c4(d_34CC[Item].X, d_34CC[Item].Y);
      end;
    end;
    15:
    begin
      Inc(d_34CC[Item].Limit);
      if d_34CC[Item].Limit >= d_34CC[Item].Counter then
      begin
        d_34CC[Item].Sprite := ((d_34CC[Item].Limit - d_34CC[Item].Counter) shr 2) + 429;
        if d_34CC[Item].Limit = 45 then
        begin
          d_34CC[Item].Limit := 0;
          d_34CC[Item].Sprite := 435;
        end;
        u1_01c4(d_34CC[Item].X, d_34CC[Item].Y);
      end;
    end;
    16:
    begin
      Inc(d_34CC[Item].Limit);
      if d_34CC[Item].Limit >= d_34CC[Item].Counter then
      begin
        d_34CC[Item].Sprite := ((d_34CC[Item].Limit - d_34CC[Item].Counter) shr 2) + 437;
        if d_34CC[Item].Limit = 45 then
        begin
          d_34CC[Item].Limit := 0;
          d_34CC[Item].Sprite := 435;
        end;
        u1_01c4(d_34CC[Item].X, d_34CC[Item].Y);
      end;
    end;
    17:
    begin
      Inc(d_34CC[Item].Limit);
      X1 := d_34CC[Item].Limit - d_34CC[Item].Counter;
      if X1 >= 0 then
      begin
        d_34CC[Item].Sprite := (X1 shr 2) + 471;
        if d_34CC[Item].Limit = 60 then
        begin
          d_34CC[Item].Limit := 0;
          d_34CC[Item].Sprite := 435;
        end;
        u1_01c4(d_34CC[Item].X, d_34CC[Item].Y + 8);
      end;
    end;
    18:
    begin
      Inc(d_34CC[Item].Limit);
      X1 := d_34CC[Item].Limit - d_34CC[Item].Counter;
      if X1 >= 0 then
      begin
        d_34CC[Item].Sprite := (X1 shr 2) + 479;
        if d_34CC[Item].Limit = 60 then
        begin
          d_34CC[Item].Limit := 0;
          d_34CC[Item].Sprite := 435;
        end;
        u1_01c4(d_34CC[Item].X, d_34CC[Item].Y - 8);
      end;
    end;
    19:
    begin
      Y2 := (Y shr 4) + 1;
      if (d_0296[(X shr 4) + 1, Y2].D <> 0) or
         (d_0296[((X + 15) shr 4) + 1, Y2].D <> 0) then
      begin
        d_34CC[Item].Flags := 1;
        u2_0000(X, Y);
        u2_0000(X - 16, Y);
        u2_0000(X + 16, Y);
        u2_2530(X, Y);
        u2_2530(X - 16, Y);
        u2_2530(X + 16, Y);
      end
      else
      begin
        Inc(d_34CC[Item].Frame);
        if d_34CC[Item].Frame > 9 then
          d_34CC[Item].Frame := 1;
        d_34CC[Item].X := X;
        u1_01c4(d_34CC[Item].X, d_34CC[Item].Y);
      end;
    end;
    20:
    begin
      Y2 := ((Y + 8) shr 4) + 1;
      X1 := ((X + 8) shr 4) + 1;
      if (d_0296[((X + 3) shr 4) + 1, Y2].D <> 0) or
         (d_0296[((X + 12) shr 4) + 1, Y2].D <> 0) or
         ((d_0296[X1, Y2 + 1].D = 0) and (d_0296[X1, Y2 + 1].E = 0)) then
        d_34CC[Item].DX := -d_34CC[Item].DX;
      Inc(d_34CC[Item].Frame);
      if d_34CC[Item].Frame > 19 then
        d_34CC[Item].Frame := 1;
      d_34CC[Item].X := X;
      u1_01c4(d_34CC[Item].X, d_34CC[Item].Y);
    end;
    21:
    begin
      if d_0296[((X + 8) shr 4) + 1 + d_34CC[Item].DX,
                ((Y + 8) shr 4) + 1].D <> 0 then
      begin
        d_34CC[Item].DX := -d_34CC[Item].DX;
        if d_34CC[Item].DX = 1 then
          d_34CC[Item].Sprite := 497
        else
          d_34CC[Item].Sprite := 495;
      end;
      Inc(d_34CC[Item].Frame);
      if d_34CC[Item].Frame > 9 then
        d_34CC[Item].Frame := 1;
      d_34CC[Item].X := X;
      u1_01c4(d_34CC[Item].X, d_34CC[Item].Y);
    end;
    22:
    begin
      Inc(d_34CC[Item].Frame);
      Inc(d_34CC[Item].Limit);
      if (d_34CC[Item].Limit = d_34CC[Item].Counter) and
         (d_34CC[Item].Sprite = 635) then
      begin
        d_34CC[Item].Frame := 1;
        d_34CC[Item].Sprite := 625;
        d_34CC[Item].Limit := d_34CC[Item].Limit - 10;
      end
      else if d_34CC[Item].Limit = d_34CC[Item].Counter then
      begin
        u7_0000(11);
        for J := 1 to 24 do
        begin
          for I := 1 to 40 do
          begin
            if d_0296[I, J].C = 637 then
            begin
              d_0296[I, J].C := 638;
              d_0296[I, J].D := 0;
              d_0296[I, J - 1].C := 0;
              d_0296[I, J - 1].B := 634;
              d_0296[I, J - 1].D := 0;
              Dec(I);
              Dec(J);
              I := I shl 4;
              J := J shl 4;
              u2_0000(I, J);
              u2_2530(I, J);
              u2_0000(I - 16, J);
              u2_2530(I - 16, J);
              u2_0000(I + 16, J);
              u2_2530(I + 16, J);
              u2_0000(I, J - 16);
              u2_2530(I, J - 16);
              d_6840 := 432 - d_6840;
              u2_0000(I, J);
              u2_2530(I, J);
              u2_0000(I - 16, J);
              u2_2530(I - 16, J);
              u2_0000(I + 16, J);
              u2_2530(I + 16, J);
              u2_0000(I, J - 16);
              u2_2530(I, J - 16);
              d_6840 := 432 - d_6840;
              I := I shr 4;
              J := J shr 4;
              Inc(I);
              Inc(J);
            end;
          end;
        end;
        u1_01c4(d_34CC[Item].X, d_34CC[Item].Y);
      end;
      if d_34CC[Item].Sprite = 625 then
      begin
        if d_34CC[Item].Frame > 11 then
        begin
          d_34CC[Item].Flags := 1;
          u2_0000(X, Y);
          u2_0000(X - 16, Y);
          u2_0000(X + 16, Y);
          u2_2530(X, Y);
          u2_2530(X - 16, Y);
          u2_2530(X + 16, Y);
          d_6840 := 432 - d_6840;
          u2_0000(X, Y);
          u2_0000(X + 16, Y);
          u2_0000(X - 16, Y);
          u2_2530(X, Y);
          u2_2530(X + 16, Y);
          u2_2530(X - 16, Y);
          d_6840 := 432 - d_6840;
        end;
      end
      else
      begin
        if d_34CC[Item].Frame > 9 then
          d_34CC[Item].Frame := 1;
      end;
    end;
    23:
    begin
      Inc(d_34CC[Item].Frame);
      if d_34CC[Item].Frame = 11 then
        u1_01c4(d_34CC[Item].X, d_34CC[Item].Y);
      if d_34CC[Item].Sprite = 625 then
      begin
        if d_34CC[Item].Frame > 11 then
        begin
          d_34CC[Item].Flags := 1;
          u2_0000(X, Y);
          u2_0000(X - 16, Y);
          u2_0000(X + 16, Y);
          u2_2530(X, Y);
          u2_2530(X - 16, Y);
          u2_2530(X + 16, Y);
          d_6840 := 432 - d_6840;
          u2_0000(X, Y);
          u2_0000(X + 16, Y);
          u2_0000(X - 16, Y);
          u2_2530(X, Y);
          u2_2530(X + 16, Y);
          u2_2530(X - 16, Y);
          d_6840 := 432 - d_6840;
        end;
      end
      else
      begin
        if d_34CC[Item].Frame > 9 then
          d_34CC[Item].Frame := 1;
      end;
    end;
    25:
    begin
      Inc(d_34CC[Item].Limit);
      if d_34CC[Item].Limit = d_34CC[Item].Counter then
      begin
        d_34CC[Item].Limit := 0;
        d_34CC[Item].DX := -d_34CC[Item].DX;
      end;
      Inc(d_34CC[Item].Frame);
      if d_34CC[Item].Frame > 19 then
        d_34CC[Item].Frame := 1;
      d_34CC[Item].X := X;
      if u1_027c(d_34CC[Item].X, d_34CC[Item].Y) then
      begin
        u7_0000(8);
        d_34CC[Item].Flags := 0;
        d_699A := d_699A + 100;
        d_6832 := $FFFF;
        d_34CC[Item].Kind := 5000;
        d_34CC[Item].Sprite := 391;
        d_34CC[Item].Frame := 1;
        d_34CC[Item].Speed := 0;
        u9_19f9(d_6DAE^[6403], d_34CC[Item].X, d_34CC[Item].Y + 16);
        u9_19f9(d_6DAE^[6403], d_34CC[Item].X, d_34CC[Item].Y + 416);
      end;
    end;
    26:
    begin
      Inc(d_34CC[Item].Frame);
      if d_34CC[Item].Frame > 19 then
        d_34CC[Item].Frame := 1;
      if ((d_34CC[Item].X <= d_34CC[1].X) and
          (d_34CC[Item].X + 9 >= d_34CC[1].X)) or
         ((d_34CC[1].X + 9 >= d_34CC[Item].X) and
          (d_34CC[Item].X >= d_34CC[1].X)) then
      begin
        if ((d_34CC[Item].Y <= d_34CC[1].Y) and
            (d_34CC[Item].Y + 15 >= d_34CC[1].Y)) or
           ((d_34CC[1].Y + 15 >= d_34CC[Item].Y) and
            (d_34CC[Item].Y >= d_34CC[1].Y)) then
        begin
          u7_0000(5);
          d_699A := d_699A + 10000;
          d_6832 := $FFFF;
          d_34CC[Item].Kind := 5001;
          d_34CC[Item].Limit := 16;
          d_34CC[Item].Sprite := 173;
          d_34CC[Item].Frame := 1;
          d_34CC[Item].Speed := 0;
          u9_19f9(d_6D96^[3523], d_34CC[Item].X, d_34CC[Item].Y + 16);
          u9_19f9(d_6D96^[3523], d_34CC[Item].X, d_34CC[Item].Y + 416);
        end;
      end;
    end;
    27:
    begin
      X1 := ((d_34CC[Item].X + 3) shr 4) + 1;
      X2 := ((d_34CC[Item].X + 13) shr 4) + 1;
      Y2 := (d_34CC[Item].Y shr 4) + 2;
      if (d_0296[X1, Y2].D = 0) and (d_0296[X2, Y2].D = 0) and
         (d_0296[X1, Y2].E = 0) and (d_0296[X2, Y2].E = 0) then
      begin
        u2_0000(d_34CC[Item].X, d_34CC[Item].Y);
        u2_0000(d_34CC[Item].X, d_34CC[Item].Y - 16);
        u2_0000(d_34CC[Item].X + 16, d_34CC[Item].Y);
        u2_0000(d_34CC[Item].X + 16, d_34CC[Item].Y - 16);
        u2_0000(d_34CC[Item].X, d_34CC[Item].Y + 8);
        u2_0000(d_34CC[Item].X + 16, d_34CC[Item].Y + 8);
        d_34CC[Item].Y := d_34CC[Item].Y + 8;
        d_34CC[Item].F34dc := -1;
        d_6EC2 := 0;
      end
      else
      begin
        d_34CC[Item].DY := 0;
        d_34CC[Item].Y := d_34CC[Item].Y and $FFF0;
        if d_34CC[Item].F34dc = -1 then
        begin
          u7_0000(29);
          d_34CC[Item].F34dc := 0;
        end;
      end;
      if ((d_34CC[Item].X <= d_34CC[1].X) and
          (d_34CC[Item].X + 9 >= d_34CC[1].X)) or
         ((d_34CC[1].X + 9 >= d_34CC[Item].X) and
          (d_34CC[Item].X >= d_34CC[1].X)) then
      begin
        if d_34CC[Item].Y = d_34CC[1].Y then
        begin
          if d_34CC[Item].X < d_34CC[1].X then
          begin
            if d_0296[((d_34CC[Item].X - 3) shr 4) + 1,
                      (d_34CC[Item].Y shr 4) + 1].D = 0 then
              d_34CC[Item].X := d_34CC[1].X - 13;
          end
          else if d_34CC[Item].X > d_34CC[1].X then
          begin
            if d_0296[((d_34CC[Item].X + 3) shr 4) + 2,
                      (d_34CC[Item].Y shr 4) + 1].D = 0 then
              d_34CC[Item].X := d_34CC[1].X + 13;
          end;
        end
        else
        begin
          if (d_34CC[1].Y + 16 >= d_34CC[Item].Y) and
             (d_34CC[Item].Y >= d_34CC[1].Y) then
          begin
            if d_6EC1 = 0 then
            begin
              d_34CC[1].Y := d_34CC[Item].Y - 16;
              d_6EC1 := 0;
              d_6EC0 := 0;
              d_6EC2 := 1;
              if d_34CC[1].Sprite = 13 then
                d_34CC[1].Sprite := 9
              else if d_34CC[1].Sprite = 14 then
                d_34CC[1].Sprite := 10;
            end;
          end;
        end;
      end;
    end;
    28:
    begin
      Y2 := (Y shr 4) + 1;
      if (d_0296[(X shr 4) + 1, Y2].D <> 0) or
         (d_0296[((X + 15) shr 4) + 1, Y2].D <> 0) then
        d_34CC[Item].DX := -d_34CC[Item].DX;
      if ((d_34CC[Item].X <= d_34CC[1].X) and
          (d_34CC[Item].X + 9 >= d_34CC[1].X)) or
         ((d_34CC[1].X + 9 >= d_34CC[Item].X) and
          (d_34CC[Item].X >= d_34CC[1].X)) then
      begin
        if (d_34CC[1].Y + 16 >= d_34CC[Item].Y) and
           (d_34CC[Item].Y > d_34CC[1].Y) then
        begin
          if d_6EC1 = 0 then
          begin
            d_34CC[1].Y := d_34CC[Item].Y - 16;
            d_6EC1 := 0;
            d_6EC0 := 0;
            d_6EC2 := 1;
            if d_34CC[1].Sprite = 13 then
              d_34CC[1].Sprite := 9
            else if d_34CC[1].Sprite = 14 then
              d_34CC[1].Sprite := 10;
            if d_34CC[Item].DX = 1 then
              d_34CC[1].X := d_34CC[Item].Speed + d_34CC[1].X
            else if d_34CC[Item].DX = -1 then
              d_34CC[1].X := d_34CC[1].X - d_34CC[Item].Speed;
            if d_6838 < 320 then
            begin
              if d_6838 + 170 < d_34CC[1].X then
              begin
                Inc(d_6838, d_34CC[Item].Speed);
                if d_6838 > 320 then
                  d_6838 := 320;
              end;
            end;
            if d_6838 > 0 then
            begin
              if d_6838 + 150 > d_34CC[1].X then
              begin
                Dec(d_6838, d_34CC[Item].Speed);
                if d_6838 < 0 then
                  d_6838 := 0;
              end;
            end;
          end;
        end;
      end;
      if d_34CC[Item].DX = 1 then
        d_34CC[Item].X := d_34CC[Item].X + d_34CC[Item].Speed
      else if d_34CC[Item].DX = -1 then
        d_34CC[Item].X := d_34CC[Item].X - d_34CC[Item].Speed;
    end;
  end;
end;
