unit U1;
{$A+}{$D+}{$L+}{$F-}
interface
uses U8;
function u1_0000(Distance, Item: Integer): Boolean;
function u1_008d(margin: Integer; slot: Word): Boolean;
procedure u1_011a;
procedure u1_012d;
procedure u1_01c4(x, y: Integer);
function u1_027c(X, Y: Integer): Boolean;
procedure u1_03f0(param1, param2: Integer; param3: Word);
procedure u1_0584(X, Y, TypeCode, Value, EntryId: Integer);
procedure u1_0837(X, Y: Integer; Item: Word; I, J: Word);
procedure u1_2f6b;
function u1_65d9(xOffset, yOffset: Word): Boolean;
procedure u1_66b3;
procedure u1_68f5;
procedure u1_6a0e;
procedure u1_6d0e(X, Y: Integer);
procedure u1_86df;
implementation
uses Dos, U9, Crt, U7, U6, U5, U4, U3, U2;
{$F+}
function u1_0000(Distance, Item: Integer): Boolean;
begin
  if d_34EC[Item].X < d_6838 - Distance then
    u1_0000 := False
  else if d_34EC[Item].X > d_6838 + 320 + Distance then
    u1_0000 := False
  else if d_34EC[Item].Y < d_683A - Distance then
    u1_0000 := False
  else if d_34EC[Item].Y > d_683A + 184 + Distance then
    u1_0000 := False
  else
    u1_0000 := True;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
function u1_008d(margin: Integer; slot: Word): Boolean;
begin
  if d_685A[slot].X < d_6838 - margin then
  begin
    u1_008d := False;
    Exit;
  end;
  if d_685A[slot].X > d_6838 + $0140 + margin then
  begin
    u1_008d := False;
    Exit;
  end;
  if d_685A[slot].Y < d_683A - margin then
  begin
    u1_008d := False;
    Exit;
  end;
  if d_685A[slot].Y > d_683A + $00B8 + margin then
  begin
    u1_008d := False;
    Exit;
  end;
  u1_008d := True;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u1_011a;
begin
  if d_69F3 = 0 then
    d_6EC8 := 1;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u1_012d;
begin
  Inc(d_681E);
  if d_69B0 = 0 then
  begin
    case d_681E of
      1..2: d_6820 := 1;
      3: d_6820 := 2;
      4..6: d_6820 := 4;
      7..1000: d_6820 := d_69A4 + 4;
    end;
  end
  else
  begin
    case d_681E of
      1..4: d_6820 := 1;
      5..6: d_6820 := 2;
      7..1000: d_6820 := (d_69A4 + 4) shr 1;
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u1_01c4(x, y: Integer);
begin
  if ((d_34EC[1].X >= x) and (x + 9 >= d_34EC[1].X)) or
     ((d_34EC[1].X + 9 >= x) and (d_34EC[1].X <= x)) then
  begin
    if ((d_34EC[1].Y >= y) and (y + 15 >= d_34EC[1].Y)) or
       ((d_34EC[1].Y + 15 >= y) and (d_34EC[1].Y <= y)) then
    begin
      if d_69F5 = 0 then
      begin
        if d_69F3 = 0 then
        begin
          if d_6A40 > 1 then
          begin
            if d_6A41 = 0 then
            begin
              d_6A41 := 1;
              d_6A42 := 30;
              Dec(d_6A40);
              d_6832 := -1;
              d_34EC[1].State := 5;
              u7_0000(7);
            end;
          end
          else
          begin
            if d_6A41 = 0 then
            begin
              u7_0000($16);
              d_69F5 := 1;
              d_69F6 := $23;
            end;
          end;
        end;
      end;
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
function u1_027c(X, Y: Integer): Boolean;
var
  I: Integer;
begin
  u1_027c := False;
  for I := 1 to d_69A2 do
  begin
    if (d_685A[I].Inactive = 0) and
       (d_685A[I].X + 7 >= X) and
       (d_685A[I].X <= X + 6) and
       (d_685A[I].Y + 8 >= Y) and
       (d_685A[I].Y <= Y + 8) then
    begin
      u1_027c := True;
      d_685A[I].Marked := 1;
      u2_0000(d_685A[I].X, d_685A[I].Y);
      u2_2530(d_685A[I].X, d_685A[I].Y);
      if (X and $000F) > 0 then
      begin
        u2_0000(d_685A[I].X - 16, d_685A[I].Y);
        u2_0000(d_685A[I].X + 16, d_685A[I].Y);
        u2_2530(d_685A[I].X - 16, d_685A[I].Y);
        u2_2530(d_685A[I].X + 16, d_685A[I].Y);
      end;
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u1_03f0(param1, param2: Integer; param3: Word);
var
  idx: Word;
  found: String[4];
begin
  idx := 0;
  found[1] := #0;
  repeat
    Inc(idx);
    if d_34EC[idx].Inactive = 1 then
    begin
      d_34EC[idx].State := 0;
      d_34EC[idx].X := param1;
      d_34EC[idx].Y := param2;
      d_34EC[idx].OldX := param1;
      d_34EC[idx].OldY := param2;
      d_34EC[idx].DY := 0;
      d_34EC[idx].Speed := 0;
      d_34EC[idx].Tick := 0;
      d_34EC[idx].Limit := $10;
      d_34EC[idx].Inactive := 0;
      d_34EC[idx].Marked := 0;
      d_34EC[idx].Kind := $1389;
      d_34EC[idx].Sprite := param3 + $96;
      d_34EC[idx].Frame := 1;
      d_34EC[idx].Speed := 0;
      d_34EC[idx].DX := 1;
      u9_19f9(d_6D96^.Images[param3].Pixels[1],
        d_34EC[idx].X, Word((LongInt(d_34EC[idx].Y + 8) and $fff0) + $10));
      u9_19f9(d_6D96^.Images[param3].Pixels[1],
        d_34EC[idx].X, Word((LongInt(d_34EC[idx].Y + 8) and $fff0) + $1a0));
      found[1] := #1;
    end;
  until (found[1] <> #0) or (idx = $19);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u1_0584(X, Y, TypeCode, Value, EntryId: Integer);
var
  I, Spare1, Spare2: Integer;
  Found: Boolean;
begin
  I := 0;
  Found := False;
  repeat
    Inc(I);
    if d_34EC[I].Inactive = 1 then
    begin
      u7_0000(3);
      d_34EC[I].DX := TypeCode;
      if d_34EC[I].DX = -1 then
        d_34EC[I].Frame := $15
      else
        d_34EC[I].Frame := 1;
      d_34EC[I].DY := 0;
      d_34EC[I].State := 0;
      if EntryId <> $89 then
        d_34EC[I].X := X and $FFF8
      else
        d_34EC[I].X := X;
      d_34EC[I].Y := Y;
      d_34EC[I].OldX := X;
      d_34EC[I].OldY := Y;
      d_34EC[I].Speed := Value;
      d_34EC[I].Tick := 0;
      d_34EC[I].Limit := 0;
      d_34EC[I].Inactive := 0;
      d_34EC[I].Marked := 0;
      if EntryId = 0 then
      begin
        d_34EC[I].Sprite := $27;
        d_34EC[I].Kind := 7;
        d_34EC[I].Frame := 1;
      end
      else
      begin
        d_34EC[I].Sprite := EntryId;
        if (d_34EC[I].Sprite = $1D6) or
           (d_34EC[I].Sprite = $7D) or
           (d_34EC[I].Sprite = $7E) then
        begin
          d_34EC[I].Kind := 7;
          d_34EC[I].Frame := 1;
        end
        else if (d_34EC[I].Sprite = $339) or
                (d_34EC[I].Sprite = $33B) then
        begin
          d_34EC[I].Kind := $13;
          d_34EC[I].Frame := 1;
        end
        else if d_34EC[I].Sprite = $72 then
        begin
          d_34EC[I].Kind := $25;
          d_34EC[I].Frame := 1;
          d_34EC[I].DY := TypeCode;
        end
        else if d_34EC[I].Sprite = $C7 then
        begin
          d_34EC[I].Sprite := $72;
          d_34EC[I].Kind := $89;
          d_34EC[I].Frame := 1;
          d_34EC[I].DY := TypeCode;
        end
        else if d_34EC[I].Sprite = $89 then
        begin
          d_34EC[I].Kind := $28;
          d_34EC[I].Frame := 1;
          d_34EC[I].Limit := $1E;
        end
        else
          d_34EC[I].Kind := $0E;
      end;
      Found := True;
    end;
  until Found or (I = 25);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u1_0837(X, Y: Integer; Item: Word; I, J: Word);
var
  X1, Y2, X2, Y1: Integer;
begin
  case d_34EC[Item].Kind of
    1:
    begin
      X1 := (X shr 4) + 1;
      Y1 := (Y shr 4) + 1;
      Y2 := Y1 + 1;
      X2 := ((X + 15) shr 4) + 1;
      if d_0296[X1, Y1].Solid <> 0 then
      begin
        d_34EC[Item].DX := 1;
        d_34EC[Item].Frame := 1;
      end
      else if d_0296[X2, Y1].Solid <> 0 then
      begin
        d_34EC[Item].DX := -1;
        d_34EC[Item].Frame := 21;
      end
      else if (d_0296[X1, Y2].Solid = 0) and
              (d_0296[X1, Y2].Special = 0) then
      begin
        d_34EC[Item].DX := 1;
        d_34EC[Item].Frame := 1;
      end
      else if (d_0296[X2, Y2].Solid = 0) and
              (d_0296[X2, Y2].Special = 0) then
      begin
        d_34EC[Item].DX := -1;
        d_34EC[Item].Frame := 21;
      end;
      Inc(d_34EC[Item].Frame);
      if d_34EC[Item].DX = 1 then
      begin
        if d_34EC[Item].Frame > 19 then
          d_34EC[Item].Frame := 1;
      end
      else
      begin
        if d_34EC[Item].Frame > 39 then
          d_34EC[Item].Frame := 21;
      end;
      d_34EC[Item].X := X;
      u1_01c4(d_34EC[Item].X, d_34EC[Item].Y);
      if u1_027c(d_34EC[Item].X, d_34EC[Item].Y) then
      begin
        u7_0000(19);
        d_699A := d_699A + 100;
        d_6832 := -1;
        d_34EC[Item].Kind := 5000;
        d_34EC[Item].Sprite := 391;
        d_34EC[Item].Frame := 1;
        d_34EC[Item].Speed := 0;
        u9_19f9(PByteArray(d_6DAE)^[6403], d_34EC[Item].X, d_34EC[Item].Y + 16);
        u9_19f9(PByteArray(d_6DAE)^[6403], d_34EC[Item].X, d_34EC[Item].Y + 416);
      end;
    end;
    2:
    begin
      X1 := (X shr 4) + 1;
      Y1 := (Y shr 4) + 1;
      Y2 := Y1 + 1;
      X2 := ((X + 15) shr 4) + 1;
      if d_0296[X1, Y1].Solid <> 0 then
      begin
        d_34EC[Item].DX := 1;
        d_34EC[Item].Frame := 1;
      end
      else if d_0296[X2, Y1].Solid <> 0 then
      begin
        d_34EC[Item].DX := -1;
        d_34EC[Item].Frame := 21;
      end
      else if (d_0296[X1, Y2].Solid = 0) and
              (d_0296[X1, Y2].Special = 0) then
      begin
        d_34EC[Item].DX := 1;
        d_34EC[Item].Frame := 1;
      end
      else if (d_0296[X2, Y2].Solid = 0) and
              (d_0296[X2, Y2].Special = 0) then
      begin
        d_34EC[Item].DX := -1;
        d_34EC[Item].Frame := 21;
      end;
      Inc(d_34EC[Item].Frame);
      if d_34EC[Item].DX = 1 then
      begin
        if d_34EC[Item].Frame > 19 then
          d_34EC[Item].Frame := 1;
      end
      else
      begin
        if d_34EC[Item].Frame > 39 then
          d_34EC[Item].Frame := 21;
      end;
      d_34EC[Item].X := X;
      u1_01c4(d_34EC[Item].X, d_34EC[Item].Y);
      if u1_027c(d_34EC[Item].X, d_34EC[Item].Y) then
      begin
        u7_0000(8);
        Dec(d_34EC[Item].Kind);
        d_34EC[Item].State := 3;
        d_34EC[Item].Sprite := 351;
        d_34EC[Item].Speed := 1;
        d_34EC[Item].Tick := Random(50) + 50;
        d_34EC[Item].Limit := 0;
        if d_34EC[Item].X < d_34EC[1].X then
          d_34EC[Item].DX := 1
        else
          d_34EC[Item].DX := -1;
        if d_34EC[Item].DX = 1 then
          d_34EC[Item].Frame := 1
        else
          d_34EC[Item].Frame := 21;
      end;
    end;
    3:
    begin
      X1 := (X shr 4) + 1;
      Y1 := (Y shr 4) + 1;
      Y2 := Y1 + 1;
      X2 := ((X + 15) shr 4) + 1;
      if d_0296[X1, Y1].Solid <> 0 then
      begin
        d_34EC[Item].DX := 1;
        d_34EC[Item].Frame := 1;
      end
      else if d_0296[X2, Y1].Solid <> 0 then
      begin
        d_34EC[Item].DX := -1;
        d_34EC[Item].Frame := 21;
      end
      else if (d_0296[X1, Y2].Solid = 0) and
              (d_0296[X1, Y2].Special = 0) then
      begin
        d_34EC[Item].DX := 1;
        d_34EC[Item].Frame := 1;
      end
      else if (d_0296[X2, Y2].Solid = 0) and
              (d_0296[X2, Y2].Special = 0) then
      begin
        d_34EC[Item].DX := -1;
        d_34EC[Item].Frame := 21;
      end;
      Inc(d_34EC[Item].Frame);
      if d_34EC[Item].DX = 1 then
      begin
        if d_34EC[Item].Frame > 19 then
          d_34EC[Item].Frame := 1;
      end
      else
      begin
        if d_34EC[Item].Frame > 39 then
          d_34EC[Item].Frame := 21;
      end;
      d_34EC[Item].X := X;
      if u1_027c(d_34EC[Item].X, d_34EC[Item].Y) then
      begin
        u7_0000(8);
        Dec(d_34EC[Item].Kind);
        d_34EC[Item].Sprite := 359;
        d_34EC[Item].State := 3;
        d_34EC[Item].Speed := 2;
        if d_34EC[Item].X < d_34EC[1].X then
          d_34EC[Item].DX := 1
        else
          d_34EC[Item].DX := -1;
        if d_34EC[Item].DX = 1 then
          d_34EC[Item].Frame := 1
        else
          d_34EC[Item].Frame := 21;
      end
      else
        u1_01c4(d_34EC[Item].X, d_34EC[Item].Y);
    end;
    4:
    begin
      X1 := (X shr 4) + 1;
      Y1 := (Y shr 4) + 1;
      Y2 := Y1 + 1;
      X2 := ((X + 15) shr 4) + 1;
      if d_0296[X1, Y1].Solid <> 0 then
      begin
        d_34EC[Item].DX := 1;
        d_34EC[Item].Frame := 1;
      end
      else if d_0296[X2, Y1].Solid <> 0 then
      begin
        d_34EC[Item].DX := -1;
        d_34EC[Item].Frame := 21;
      end
      else if (d_0296[X1, Y2].Solid = 0) and
              (d_0296[X1, Y2].Special = 0) then
      begin
        d_34EC[Item].DX := 1;
        d_34EC[Item].Frame := 1;
      end
      else if (d_0296[X2, Y2].Solid = 0) and
              (d_0296[X2, Y2].Special = 0) then
      begin
        d_34EC[Item].DX := -1;
        d_34EC[Item].Frame := 21;
      end;
      Inc(d_34EC[Item].Frame);
      if d_34EC[Item].DX = 1 then
      begin
        if d_34EC[Item].Frame > 19 then
          d_34EC[Item].Frame := 1;
      end
      else
      begin
        if d_34EC[Item].Frame > 39 then
          d_34EC[Item].Frame := 21;
      end;
      Inc(d_34EC[Item].Limit);
      if d_34EC[Item].Limit >= d_34EC[Item].Tick then
      begin
        if (d_34EC[Item].Y shr 4) = ((d_34EC[1].Y + 8) shr 4) then
        begin
          if ((d_34EC[Item].X < d_34EC[1].X) and (d_34EC[Item].DX = 1)) or
             ((d_34EC[Item].X > d_34EC[1].X) and (d_34EC[Item].DX = -1)) then
          begin
            d_34EC[Item].Limit := 0;
            u1_0584(d_34EC[Item].X, d_34EC[Item].Y, d_34EC[Item].DX, 4, 0);
          end;
        end;
      end;
      d_34EC[Item].X := X;
      u1_01c4(d_34EC[Item].X, d_34EC[Item].Y);
      if u1_027c(d_34EC[Item].X, d_34EC[Item].Y) then
      begin
        u7_0000(8);
        Dec(d_34EC[Item].Kind);
        d_34EC[Item].Sprite := 367;
        d_34EC[Item].State := 3;
        d_34EC[Item].Speed := 3;
        if d_34EC[Item].X < d_34EC[1].X then
          d_34EC[Item].DX := 1
        else
          d_34EC[Item].DX := -1;
        if d_34EC[Item].DX = 1 then
          d_34EC[Item].Frame := 1
        else
          d_34EC[Item].Frame := 21;
      end;
    end;
    5:
    begin
      X1 := (X shr 4) + 1;
      Y1 := (Y shr 4) + 1;
      Y2 := Y1 + 1;
      X2 := ((X + 15) shr 4) + 1;
      if d_0296[X1, Y1].Solid <> 0 then
      begin
        d_34EC[Item].DX := 1;
        d_34EC[Item].Frame := 1;
      end
      else if d_0296[X2, Y1].Solid <> 0 then
      begin
        d_34EC[Item].DX := -1;
        d_34EC[Item].Frame := 21;
      end
      else if (d_0296[X1, Y2].Solid = 0) and
              (d_0296[X1, Y2].Special = 0) then
      begin
        d_34EC[Item].DX := 1;
        d_34EC[Item].Frame := 1;
      end
      else if (d_0296[X2, Y2].Solid = 0) and
              (d_0296[X2, Y2].Special = 0) then
      begin
        d_34EC[Item].DX := -1;
        d_34EC[Item].Frame := 21;
      end;
      Inc(d_34EC[Item].Frame);
      if d_34EC[Item].DX = 1 then
      begin
        if d_34EC[Item].Frame > 19 then
          d_34EC[Item].Frame := 1;
      end
      else
      begin
        if d_34EC[Item].Frame > 39 then
          d_34EC[Item].Frame := 21;
      end;
      Inc(d_34EC[Item].Limit);
      if d_34EC[Item].Limit >= d_34EC[Item].Tick then
      begin
        if (d_34EC[Item].Y shr 4) = ((d_34EC[1].Y + 8) shr 4) then
        begin
          if ((d_34EC[Item].X < d_34EC[1].X) and (d_34EC[Item].DX = 1)) or
             ((d_34EC[Item].X > d_34EC[1].X) and (d_34EC[Item].DX = -1)) then
          begin
            d_34EC[Item].Limit := 0;
            u1_0584(d_34EC[Item].X, d_34EC[Item].Y, d_34EC[Item].DX, 4, 0);
          end;
        end;
      end;
      d_34EC[Item].X := X;
      u1_01c4(d_34EC[Item].X, d_34EC[Item].Y);
      if u1_027c(d_34EC[Item].X, d_34EC[Item].Y) then
      begin
        u7_0000(8);
        Dec(d_34EC[Item].Kind);
        d_34EC[Item].Sprite := 375;
        d_34EC[Item].State := 3;
        if d_34EC[Item].X < d_34EC[1].X then
          d_34EC[Item].DX := 1
        else
          d_34EC[Item].DX := -1;
        if d_34EC[Item].DX = 1 then
          d_34EC[Item].Frame := 1
        else
          d_34EC[Item].Frame := 21;
      end;
    end;
    6:
    begin
      if (d_0296[(X shr 4) + 1, (Y shr 4) + 1].Solid <> 0) or
         (d_0296[((X + 15) shr 4) + 1, (Y shr 4) + 1].Solid <> 0) then
        d_34EC[Item].DX := -d_34EC[Item].DX;
      Inc(d_34EC[Item].Frame);
      if d_34EC[Item].Frame > 19 then
        d_34EC[Item].Frame := 1;
      d_34EC[Item].X := X;
      u1_01c4(d_34EC[Item].X, d_34EC[Item].Y);
      if d_34EC[Item].Sprite = 625 then
      begin
        Dec(d_34EC[Item].Limit);
        if d_34EC[Item].Limit <= 0 then
        begin
          d_34EC[Item].Marked := 1;
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
        if u1_027c(d_34EC[Item].X, d_34EC[Item].Y) then
        begin
          u7_0000(8);
          Dec(d_34EC[Item].Tick);
          d_34EC[Item].State := 3;
          if d_34EC[Item].Tick <= 0 then
          begin
            d_34EC[Item].Sprite := 625;
            d_34EC[Item].Frame := 1;
            d_34EC[Item].Speed := 1;
          end;
        end;
      end;
    end;
    7:
    begin
      Y2 := (Y shr 4) + 1;
      if (d_0296[(X shr 4) + 1, Y2].Solid <> 0) or
         (d_0296[((X + 15) shr 4) + 1, Y2].Solid <> 0) then
      begin
        d_34EC[Item].Marked := 1;
        u2_0000(X, Y);
        u2_0000(X - 16, Y);
        u2_0000(X + 16, Y);
        u2_2530(X, Y);
        u2_2530(X - 16, Y);
        u2_2530(X + 16, Y);
      end
      else
      begin
        d_34EC[Item].X := X;
        X1 := d_34EC[1].X - d_34EC[Item].X;
        Y2 := d_34EC[1].Y - d_34EC[Item].Y;
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
                  d_6832 := -1;
                  d_34EC[1].State := 5;
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
      Inc(d_34EC[Item].Limit);
      if d_34EC[Item].Limit >= d_34EC[Item].Tick then
      begin
        if (d_34EC[Item].Y and $FFF0) = ((d_34EC[1].Y + 8) and $FFF0) then
        begin
          if d_34EC[Item].X < d_34EC[1].X then
          begin
            d_34EC[Item].Limit := 0;
            if d_34EC[Item].Kind = 10 then
              u1_0584(d_34EC[Item].X + 8, d_34EC[Item].Y, 1, 4, 470)
            else
              u1_0584(d_34EC[Item].X + 16, d_34EC[Item].Y, 1, 4, 488);
          end;
        end;
      end;
    end;
    11, 13:
    begin
      Inc(d_34EC[Item].Limit);
      if d_34EC[Item].Limit >= d_34EC[Item].Tick then
      begin
        if (d_34EC[Item].Y and $FFF0) = ((d_34EC[1].Y + 8) and $FFF0) then
        begin
          if d_34EC[Item].X > d_34EC[1].X then
          begin
            d_34EC[Item].Limit := 0;
            if d_34EC[Item].Kind = 11 then
              u1_0584(d_34EC[Item].X - 8, d_34EC[Item].Y, -1, 4, 470)
            else
              u1_0584(d_34EC[Item].X - 16, d_34EC[Item].Y, -1, 4, 492);
          end;
        end;
      end;
    end;
    14:
    begin
      Y2 := (Y shr 4) + 1;
      if (d_0296[(X shr 4) + 1, Y2].Solid <> 0) or
         (d_0296[((X + 15) shr 4) + 1, Y2].Solid <> 0) then
      begin
        d_34EC[Item].Marked := 1;
        u2_0000(X, Y);
        u2_0000(X - 16, Y);
        u2_0000(X + 16, Y);
        u2_2530(X, Y);
        u2_2530(X - 16, Y);
        u2_2530(X + 16, Y);
      end
      else
      begin
        Inc(d_34EC[Item].Frame);
      if d_34EC[Item].DX = 1 then
      begin
        if d_34EC[Item].Frame > 19 then
          d_34EC[Item].Frame := 1;
      end
      else
      begin
        if d_34EC[Item].Frame > 39 then
          d_34EC[Item].Frame := 21;
      end;
        d_34EC[Item].X := X;
        u1_01c4(d_34EC[Item].X, d_34EC[Item].Y);
      end;
    end;
    15:
    begin
      Inc(d_34EC[Item].Limit);
      if d_34EC[Item].Limit >= d_34EC[Item].Tick then
      begin
        d_34EC[Item].Sprite := ((d_34EC[Item].Limit - d_34EC[Item].Tick) shr 2) + 429;
        if d_34EC[Item].Limit = 45 then
        begin
          d_34EC[Item].Limit := 0;
          d_34EC[Item].Sprite := 435;
        end;
        u1_01c4(d_34EC[Item].X, d_34EC[Item].Y);
      end;
    end;
    16:
    begin
      Inc(d_34EC[Item].Limit);
      if d_34EC[Item].Limit >= d_34EC[Item].Tick then
      begin
        d_34EC[Item].Sprite := ((d_34EC[Item].Limit - d_34EC[Item].Tick) shr 2) + 437;
        if d_34EC[Item].Limit = 45 then
        begin
          d_34EC[Item].Limit := 0;
          d_34EC[Item].Sprite := 435;
        end;
        u1_01c4(d_34EC[Item].X, d_34EC[Item].Y);
      end;
    end;
    17:
    begin
      Inc(d_34EC[Item].Limit);
      X1 := d_34EC[Item].Limit - d_34EC[Item].Tick;
      if X1 >= 0 then
      begin
        d_34EC[Item].Sprite := (X1 shr 2) + 471;
        if d_34EC[Item].Limit = 60 then
        begin
          d_34EC[Item].Limit := 0;
          d_34EC[Item].Sprite := 435;
        end;
        u1_01c4(d_34EC[Item].X, d_34EC[Item].Y + 8);
      end;
    end;
    18:
    begin
      Inc(d_34EC[Item].Limit);
      X1 := d_34EC[Item].Limit - d_34EC[Item].Tick;
      if X1 >= 0 then
      begin
        d_34EC[Item].Sprite := (X1 shr 2) + 479;
        if d_34EC[Item].Limit = 60 then
        begin
          d_34EC[Item].Limit := 0;
          d_34EC[Item].Sprite := 435;
        end;
        u1_01c4(d_34EC[Item].X, d_34EC[Item].Y - 8);
      end;
    end;
    19:
    begin
      Y2 := (Y shr 4) + 1;
      if (d_0296[(X shr 4) + 1, Y2].Solid <> 0) or
         (d_0296[((X + 15) shr 4) + 1, Y2].Solid <> 0) then
      begin
        d_34EC[Item].Marked := 1;
        u2_0000(X, Y);
        u2_0000(X - 16, Y);
        u2_0000(X + 16, Y);
        u2_2530(X, Y);
        u2_2530(X - 16, Y);
        u2_2530(X + 16, Y);
      end
      else
      begin
        Inc(d_34EC[Item].Frame);
        if d_34EC[Item].Frame > 9 then
          d_34EC[Item].Frame := 1;
        d_34EC[Item].X := X;
        u1_01c4(d_34EC[Item].X, d_34EC[Item].Y);
      end;
    end;
    20:
    begin
      Y2 := ((Y + 8) shr 4) + 1;
      X1 := ((X + 8) shr 4) + 1;
      if (d_0296[((X + 3) shr 4) + 1, Y2].Solid <> 0) or
         (d_0296[((X + 12) shr 4) + 1, Y2].Solid <> 0) or
         ((d_0296[X1, Y2 + 1].Solid = 0) and (d_0296[X1, Y2 + 1].Special = 0)) then
        d_34EC[Item].DX := -d_34EC[Item].DX;
      Inc(d_34EC[Item].Frame);
      if d_34EC[Item].Frame > 19 then
        d_34EC[Item].Frame := 1;
      d_34EC[Item].X := X;
      u1_01c4(d_34EC[Item].X, d_34EC[Item].Y);
    end;
    21:
    begin
      if d_0296[((X + 8) shr 4) + 1 + d_34EC[Item].DX,
                ((Y + 8) shr 4) + 1].Solid <> 0 then
      begin
        d_34EC[Item].DX := -d_34EC[Item].DX;
        if d_34EC[Item].DX = 1 then
          d_34EC[Item].Sprite := 497
        else
          d_34EC[Item].Sprite := 495;
      end;
      Inc(d_34EC[Item].Frame);
      if d_34EC[Item].Frame > 9 then
        d_34EC[Item].Frame := 1;
      d_34EC[Item].X := X;
      u1_01c4(d_34EC[Item].X, d_34EC[Item].Y);
    end;
    22:
    begin
      Inc(d_34EC[Item].Frame);
      Inc(d_34EC[Item].Limit);
      if (d_34EC[Item].Limit = d_34EC[Item].Tick) and
         (d_34EC[Item].Sprite = 635) then
      begin
        d_34EC[Item].Frame := 1;
        d_34EC[Item].Sprite := 625;
        d_34EC[Item].Limit := d_34EC[Item].Limit - 10;
      end
      else if d_34EC[Item].Limit = d_34EC[Item].Tick then
      begin
        u7_0000(11);
        for J := 1 to 24 do
        begin
          for I := 1 to 40 do
          begin
            if d_0296[I, J].Aux = 637 then
            begin
              d_0296[I, J].Aux := 638;
              d_0296[I, J].Solid := 0;
              d_0296[I, J - 1].Aux := 0;
              d_0296[I, J - 1].Overlay := 634;
              d_0296[I, J - 1].Solid := 0;
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
        u1_01c4(d_34EC[Item].X, d_34EC[Item].Y);
      end;
      if d_34EC[Item].Sprite = 625 then
      begin
        if d_34EC[Item].Frame > 11 then
        begin
          d_34EC[Item].Marked := 1;
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
        if d_34EC[Item].Frame > 9 then
          d_34EC[Item].Frame := 1;
      end;
    end;
    23:
    begin
      Inc(d_34EC[Item].Frame);
      if d_34EC[Item].Frame = 11 then
        u1_01c4(d_34EC[Item].X, d_34EC[Item].Y);
      if d_34EC[Item].Sprite = 625 then
      begin
        if d_34EC[Item].Frame > 11 then
        begin
          d_34EC[Item].Marked := 1;
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
        if d_34EC[Item].Frame > 9 then
          d_34EC[Item].Frame := 1;
      end;
    end;
    25:
    begin
      Inc(d_34EC[Item].Limit);
      if d_34EC[Item].Limit = d_34EC[Item].Tick then
      begin
        d_34EC[Item].Limit := 0;
        d_34EC[Item].DX := -d_34EC[Item].DX;
      end;
      Inc(d_34EC[Item].Frame);
      if d_34EC[Item].Frame > 19 then
        d_34EC[Item].Frame := 1;
      d_34EC[Item].X := X;
      if u1_027c(d_34EC[Item].X, d_34EC[Item].Y) then
      begin
        u7_0000(8);
        d_34EC[Item].Marked := 0;
        d_699A := d_699A + 100;
        d_6832 := -1;
        d_34EC[Item].Kind := 5000;
        d_34EC[Item].Sprite := 391;
        d_34EC[Item].Frame := 1;
        d_34EC[Item].Speed := 0;
        u9_19f9(PByteArray(d_6DAE)^[6403], d_34EC[Item].X, d_34EC[Item].Y + 16);
        u9_19f9(PByteArray(d_6DAE)^[6403], d_34EC[Item].X, d_34EC[Item].Y + 416);
      end;
    end;
    26:
    begin
      Inc(d_34EC[Item].Frame);
      if d_34EC[Item].Frame > 19 then
        d_34EC[Item].Frame := 1;
      if ((d_34EC[Item].X <= d_34EC[1].X) and
          (d_34EC[Item].X + 9 >= d_34EC[1].X)) or
         ((d_34EC[1].X + 9 >= d_34EC[Item].X) and
          (d_34EC[Item].X >= d_34EC[1].X)) then
      begin
        if ((d_34EC[Item].Y <= d_34EC[1].Y) and
            (d_34EC[Item].Y + 15 >= d_34EC[1].Y)) or
           ((d_34EC[1].Y + 15 >= d_34EC[Item].Y) and
            (d_34EC[Item].Y >= d_34EC[1].Y)) then
        begin
          u7_0000(5);
          d_699A := d_699A + 10000;
          d_6832 := -1;
          d_34EC[Item].Kind := 5001;
          d_34EC[Item].Limit := 16;
          d_34EC[Item].Sprite := 173;
          d_34EC[Item].Frame := 1;
          d_34EC[Item].Speed := 0;
          u9_19f9(PByteArray(d_6D96)^[3523], d_34EC[Item].X, d_34EC[Item].Y + 16);
          u9_19f9(PByteArray(d_6D96)^[3523], d_34EC[Item].X, d_34EC[Item].Y + 416);
        end;
      end;
    end;
    27:
    begin
      X1 := ((d_34EC[Item].X + 3) shr 4) + 1;
      X2 := ((d_34EC[Item].X + 13) shr 4) + 1;
      Y2 := (d_34EC[Item].Y shr 4) + 2;
      if (d_0296[X1, Y2].Solid = 0) and (d_0296[X2, Y2].Solid = 0) and
         (d_0296[X1, Y2].Special = 0) and (d_0296[X2, Y2].Special = 0) then
      begin
        u2_0000(d_34EC[Item].X, d_34EC[Item].Y);
        u2_0000(d_34EC[Item].X, d_34EC[Item].Y - 16);
        u2_0000(d_34EC[Item].X + 16, d_34EC[Item].Y);
        u2_0000(d_34EC[Item].X + 16, d_34EC[Item].Y - 16);
        u2_0000(d_34EC[Item].X, d_34EC[Item].Y + 8);
        u2_0000(d_34EC[Item].X + 16, d_34EC[Item].Y + 8);
        d_34EC[Item].Y := d_34EC[Item].Y + 8;
        d_34EC[Item].Aux1 := -1;
        d_6EC2 := 0;
      end
      else
      begin
        d_34EC[Item].DY := 0;
        d_34EC[Item].Y := d_34EC[Item].Y and $FFF0;
        if d_34EC[Item].Aux1 = -1 then
        begin
          u7_0000(29);
          d_34EC[Item].Aux1 := 0;
        end;
      end;
      if ((d_34EC[Item].X <= d_34EC[1].X) and
          (d_34EC[Item].X + 9 >= d_34EC[1].X)) or
         ((d_34EC[1].X + 9 >= d_34EC[Item].X) and
          (d_34EC[Item].X >= d_34EC[1].X)) then
      begin
        if d_34EC[Item].Y = d_34EC[1].Y then
        begin
          if d_34EC[Item].X < d_34EC[1].X then
          begin
            if d_0296[((d_34EC[Item].X - 3) shr 4) + 1,
                      (d_34EC[Item].Y shr 4) + 1].Solid = 0 then
              d_34EC[Item].X := d_34EC[1].X - 13;
          end
          else if d_34EC[Item].X > d_34EC[1].X then
          begin
            if d_0296[((d_34EC[Item].X + 3) shr 4) + 2,
                      (d_34EC[Item].Y shr 4) + 1].Solid = 0 then
              d_34EC[Item].X := d_34EC[1].X + 13;
          end;
        end
        else
        begin
          if (d_34EC[1].Y + 16 >= d_34EC[Item].Y) and
             (d_34EC[Item].Y >= d_34EC[1].Y) then
          begin
            if d_6EC1 = 0 then
            begin
              d_34EC[1].Y := d_34EC[Item].Y - 16;
              d_6EC1 := 0;
              d_6EC0 := 0;
              d_6EC2 := 1;
              if d_34EC[1].Sprite = 13 then
                d_34EC[1].Sprite := 9
              else if d_34EC[1].Sprite = 14 then
                d_34EC[1].Sprite := 10;
            end;
          end;
        end;
      end;
    end;
    28:
    begin
      Y2 := (Y shr 4) + 1;
      if (d_0296[(X shr 4) + 1, Y2].Solid <> 0) or
         (d_0296[((X + 15) shr 4) + 1, Y2].Solid <> 0) then
        d_34EC[Item].DX := -d_34EC[Item].DX;
      if ((d_34EC[Item].X <= d_34EC[1].X) and
          (d_34EC[Item].X + 9 >= d_34EC[1].X)) or
         ((d_34EC[1].X + 9 >= d_34EC[Item].X) and
          (d_34EC[Item].X >= d_34EC[1].X)) then
      begin
        if (d_34EC[1].Y + 16 >= d_34EC[Item].Y) and
           (d_34EC[Item].Y > d_34EC[1].Y) then
        begin
          if d_6EC1 = 0 then
          begin
            d_34EC[1].Y := d_34EC[Item].Y - 16;
            d_6EC1 := 0;
            d_6EC0 := 0;
            d_6EC2 := 1;
            if d_34EC[1].Sprite = 13 then
              d_34EC[1].Sprite := 9
            else if d_34EC[1].Sprite = 14 then
              d_34EC[1].Sprite := 10;
            if d_34EC[Item].DX = 1 then
              d_34EC[1].X := d_34EC[Item].Speed + d_34EC[1].X
            else if d_34EC[Item].DX = -1 then
              d_34EC[1].X := d_34EC[1].X - d_34EC[Item].Speed;
            if d_6838 < 320 then
            begin
              if d_6838 + 170 < d_34EC[1].X then
              begin
                Inc(d_6838, d_34EC[Item].Speed);
                if d_6838 > 320 then
                  d_6838 := 320;
              end;
            end;
            if d_6838 > 0 then
            begin
              if d_6838 + 150 > d_34EC[1].X then
              begin
                Dec(d_6838, d_34EC[Item].Speed);
                if d_6838 < 0 then
                  d_6838 := 0;
              end;
            end;
          end;
        end;
      end;
      if d_34EC[Item].DX = 1 then
        d_34EC[Item].X := d_34EC[Item].X + d_34EC[Item].Speed
      else if d_34EC[Item].DX = -1 then
        d_34EC[Item].X := d_34EC[Item].X - d_34EC[Item].Speed;
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u1_2f6b;
var
  X, Y, I, A, B, J, K, L, M: Integer;
begin
  for I := 2 to 25 do
    if d_34EC[I].Inactive = 0 then
      if u1_0000(32, I) or (d_34EC[I].Kind = 28) or
         (d_34EC[I].Kind = 21) or (d_34EC[I].Kind = 14) then
      begin
        {2fd4} if d_34EC[I].DX = 1 then
        begin
          {2fec} X := (d_34EC[I].X + d_34EC[I].Speed);
        end
        else
        begin
          {2ffd} if d_34EC[I].DX = -1 then
          begin
            {3015} X := (d_34EC[I].X - d_34EC[I].Speed);
          end
          else
          begin
            {3025} X := d_34EC[I].X;
          end;
        end;
        {3034} if d_34EC[I].DY = 1 then
        begin
          {304c} Y := (d_34EC[I].Y + d_34EC[I].Speed);
        end
        else
        begin
          {305d} if d_34EC[I].DY = -1 then
          begin
            {3075} Y := (d_34EC[I].Y - d_34EC[I].Speed);
          end
          else
          begin
            {3085} Y := d_34EC[I].Y;
          end;
        end;
        {309a} d_34EC[I].OldX := d_34EC[I].X;
        {30b0} d_34EC[I].OldY := d_34EC[I].Y;
        {30c0} if d_34EC[I].Kind < 30 then
        begin
          {30d2} u1_0837(X, Y, I, A, B);
        end
        else
        begin
          case d_34EC[I].Kind of
            5000: begin
              {3107} if u1_027c(d_34EC[I].X, d_34EC[I].Y) then
              begin
                {3110} u7_0000(20);
                {3121} d_699A := (d_699A + 100);
                {3128} d_6832 := -1;
                {3135} d_34EC[I].Kind := 5001;
                {3142} d_34EC[I].Limit := 16;
                {314f} d_34EC[I].Sprite := 167;
                {315c} d_34EC[I].Frame := 1;
                {316b} d_34EC[I].Speed := 0;
                {3193} u9_19f9(PByteArray(d_6D96)^[2563], d_34EC[I].X, (d_34EC[I].Y + 16));
                {31bc} u9_19f9(PByteArray(d_6D96)^[2563], d_34EC[I].X, (d_34EC[I].Y + 416));
              end
              else
              begin
                {31dc} if ((((d_34EC[1].X + 3) >= (d_34EC[I].X + 3)) and ((d_34EC[1].X + 3) <= (d_34EC[I].X +
                    12))) or (((d_34EC[1].X + 12) >= (d_34EC[I].X + 3)) and ((d_34EC[1].X + 12) <=
                    (d_34EC[I].X + 12)))) and (((d_34EC[I].Y <= d_34EC[1].Y) and ((d_34EC[I].Y + 15) >=
                    d_34EC[1].Y)) or (((d_34EC[1].Y + 15) >= d_34EC[I].Y) and ((d_34EC[1].Y + 15) <=
                    (d_34EC[I].Y + 15)))) then
                begin
                  {328e} u7_0000(4);
                  {329f} d_699A := (d_699A + 1000);
                  {32a6} d_6832 := -1;
                  {32b3} d_34EC[I].Kind := 5001;
                  {32c0} d_34EC[I].Limit := 16;
                  {32cd} d_34EC[I].Sprite := 170;
                  {32da} d_34EC[I].Frame := 1;
                  {32e9} d_34EC[I].Speed := 0;
                  {3311} u9_19f9(PByteArray(d_6D96)^[3203], d_34EC[I].X, (d_34EC[I].Y + 16));
                  {333a} u9_19f9(PByteArray(d_6D96)^[3203], d_34EC[I].X, (d_34EC[I].Y + 416));
                end;
              end;
            end;
            5001: begin
              {3354} d_34EC[I].OldX := X;
              {3362} d_34EC[I].OldY := Y;
              {336d} Dec(d_34EC[I].Y, 2);
              {337e} if d_34EC[I].Y < 16 then
              begin
                {3380} Y := 16;
                {338c} d_34EC[I].Y := 16;
                {3399} d_34EC[I].OldY := 16;
              end;
              {33a6} Dec(d_34EC[I].Limit);
              {33b6} if d_34EC[I].Limit <= 0 then
              begin
                {33c2} d_34EC[I].Marked := 1;
                {33cd} u2_0000(X, Y);
                {33dc} u2_0000(X, (Y - 16));
                {33eb} u2_0000(X, (Y + 16));
                {33f6} u2_2530(X, Y);
                {3405} u2_2530(X, (Y + 16));
                {3414} u2_2530(X, (Y - 16));
                {3423} u2_0000((X + 16), Y);
                {3436} u2_0000((X + 16), (Y + 16));
                {3449} u2_0000((X + 16), (Y - 16));
                {3458} u2_2530((X + 16), Y);
                {346b} u2_2530((X + 16), (Y + 16));
                {347e} u2_2530((X + 16), (Y - 16));
              end
              else
              begin
                {348c} u2_0000(X, Y);
                {349b} u2_0000(X, (Y + 16));
                {34a6} u2_2530(X, Y);
                {34b5} u2_2530(X, (Y + 16));
                {34c4} u2_0000((X + 16), Y);
                {34d7} u2_0000((X + 16), (Y + 16));
                {34e6} u2_2530((X + 16), Y);
                {34f9} u2_2530((X + 16), (Y + 16));
                {3508} u2_0000((X - 16), Y);
                {351b} u2_0000((X - 16), (Y + 16));
                {352a} u2_2530((X - 16), Y);
                {353d} u2_2530((X - 16), (Y + 16));
              end;
            end;
            42: begin
              {3556} J := ((X shr 4) + 1);
              {3562} M := ((Y shr 4) + 1);
              {3569} K := (M + 1);
              {357a} L := (((X + 15) shr 4) + 2);
              {3597} if d_0296[J, M].Solid <> 0 then
              begin
                {35a0} d_34EC[I].DX := 1;
                {35ad} d_34EC[I].Frame := 1;
              end
              else
              begin
                {35d0} if d_0296[L, M].Solid <> 0 then
                begin
                  {35d9} d_34EC[I].DX := -1;
                  {35e6} d_34EC[I].Frame := 41;
                end
                else
                begin
                  {3609} if (d_0296[J, K].Solid = 0) and (d_0296[J, K].Special = 0) then
                  begin
                    {362e} d_34EC[I].DX := 1;
                    {363b} d_34EC[I].Frame := 1;
                  end
                  else
                  begin
                    {365d} if (d_0296[L, K].Solid = 0) and (d_0296[L, K].Special = 0) then
                    begin
                      {3682} d_34EC[I].DX := -1;
                      {368f} d_34EC[I].Frame := 41;
                    end;
                  end;
                end;
              end;
              {369c} Inc(d_34EC[I].Frame);
              {36ac} if d_34EC[I].DX = 1 then
              begin
                {36ba} if d_34EC[I].Frame > 19 then
                begin
                  {36c3} d_34EC[I].Frame := 1;
                end;
              end
              else
              begin
                {36d7} if d_34EC[I].Frame > 59 then
                begin
                  {36e0} d_34EC[I].Frame := 41;
                end;
              end;
              {36f0} d_34EC[I].X := X;
              {370b} u1_01c4(d_34EC[I].X, d_34EC[I].Y);
              {3729} u1_01c4((d_34EC[I].X + 16), d_34EC[I].Y);
              {3748} if (u1_027c(d_34EC[I].X, d_34EC[I].Y)) or (u1_027c((d_34EC[I].X + 16), d_34EC[I].Y)) then
              begin
                {3773} u7_0000(8);
                {377f} d_34EC[I].State := 3;
                {378c} Dec(d_34EC[I].Aux1);
                {379c} if d_34EC[I].Aux1 = 0 then
                begin
                  {37a5} u7_0000(19);
                  {37b1} d_34EC[I].Marked := 1;
                  {37cc} u2_0000(d_34EC[I].X, d_34EC[I].Y);
                  {37eb} u2_0000((d_34EC[I].X - 16), d_34EC[I].Y);
                  {380a} u2_0000((d_34EC[I].X + 16), d_34EC[I].Y);
                  {3829} u2_0000((d_34EC[I].X + 32), d_34EC[I].Y);
                  {385b} u1_03f0((LongInt(d_34EC[I].X) and 65520), (LongInt(d_34EC[I].Y) and 65520), 19);
                  {386a} d_699A := (d_699A + 500);
                  {3871} d_6832 := -1;
                end;
                {3886} if d_34EC[I].X < d_34EC[1].X then
                begin
                  {388f} d_34EC[I].DX := 1;
                end
                else
                begin
                  {389e} d_34EC[I].DX := -1;
                end;
                {38b0} if d_34EC[I].DX = 1 then
                begin
                  {38b9} d_34EC[I].Frame := 1;
                end
                else
                begin
                  {38c8} d_34EC[I].Frame := 41;
                end;
              end;
            end;
            30: begin
              {38e1} J := (X shr 4);
              {38ec} K := (Y shr 4);
              {38fb} L := (((X + 15) shr 4) + 1);
              {3919} if (d_0296[(J + 1), K].Solid <> 0) or ((d_0296[L, K].Solid <> 0) or ((d_0296[(J + 1), (K
                    + 1)].Solid <> 0) or (d_0296[L, (K + 1)].Solid <> 0))) then
              begin
                {3986} d_34EC[I].DX := (-d_34EC[I].DX);
                {3996} if d_34EC[I].DX = -1 then
                begin
                  {399f} d_34EC[I].Frame := 41;
                end
                else
                begin
                  {39ae} d_34EC[I].Frame := 1;
                end;
              end
              else
              begin
                {39d5} if (d_0296[(J + 1), (K + 2)].Solid = 0) and (d_0296[(J + 1), (K + 2)].Special = 0) then
                begin
                  {39fe} d_34EC[I].DX := 1;
                  {3a0b} d_34EC[I].Frame := 1;
                end
                else
                begin
                  {3a30} if (d_0296[L, (K + 2)].Solid = 0) and (d_0296[L, (K + 2)].Special = 0) then
                  begin
                    {3a58} d_34EC[I].DX := -1;
                    {3a65} d_34EC[I].Frame := 41;
                  end;
                end;
              end;
              {3a72} Inc(d_34EC[I].Frame);
              {3a82} if d_34EC[I].DX = 1 then
              begin
                {3a90} if d_34EC[I].Frame > 19 then
                begin
                  {3a99} d_34EC[I].Frame := 1;
                end;
              end
              else
              begin
                {3aad} if d_34EC[I].Frame > 59 then
                begin
                  {3ab6} d_34EC[I].Frame := 41;
                end;
              end;
              {3ac8} if d_34EC[I].Limit > 0 then
              begin
                {3ad1} Dec(d_34EC[I].Limit);
              end;
              {3ae1} if (d_34EC[I].Limit = 0) and (((d_34EC[I].Y shr 4) = ((d_34EC[1].Y + 8) shr 4)) and
                    (((d_34EC[I].X < d_34EC[1].X) and (d_34EC[I].DX = 1)) or ((d_34EC[I].X > d_34EC[1].X) and
                    (d_34EC[I].DX = -1)))) then
              begin
                {3b4c} d_34EC[I].Limit := 70;
                {3b7c} u1_0584(d_34EC[I].X, d_34EC[I].Y, d_34EC[I].DX, 4, 825);
              end;
              {3b89} d_34EC[I].X := X;
              {3ba9} if (u1_027c(d_34EC[I].X, d_34EC[I].Y)) or (u1_027c(d_34EC[I].X, (d_34EC[I].Y - 16))) then
              begin
                {3bdf} if d_34EC[I].X < d_34EC[1].X then
                begin
                  {3c0d} if (d_0296[(((d_34EC[I].X + 15) shr 4) + 1), (K + 1)].Solid = 0) and
                    (d_0296[(((d_34EC[I].X + 15) shr 4) + 1), K].Solid = 0) then
                  begin
                    {3c43} d_34EC[I].DX := 1;
                    {3c50} d_34EC[I].Frame := 1;
                  end;
                end
                else
                begin
                  {3c81} if (d_0296[((d_34EC[I].X shr 4) + 1), (K + 1)].Solid = 0) and (d_0296[((d_34EC[I].X
                    shr 4) + 1), K].Solid = 0) then
                  begin
                    {3cb4} d_34EC[I].DX := -1;
                    {3cc1} d_34EC[I].Frame := 41;
                  end;
                end;
                {3cce} d_34EC[I].State := 3;
                {3cdb} Dec(d_34EC[I].Aux1);
                {3ceb} if d_34EC[I].Aux1 = 0 then
                begin
                  {3cf4} u7_0000(19);
                  {3d05} d_699A := (d_699A + 1000);
                  {3d0c} d_6832 := -1;
                  {3d19} d_34EC[I].Marked := 1;
                  {3d34} u2_0000(d_34EC[I].X, d_34EC[I].Y);
                  {3d53} u2_0000((d_34EC[I].X - 16), d_34EC[I].Y);
                  {3d72} u2_0000((d_34EC[I].X + 16), d_34EC[I].Y);
                  {3d95} u2_0000((d_34EC[I].X + 16), (d_34EC[I].Y - 16));
                  {3db8} u2_0000((d_34EC[I].X - 16), (d_34EC[I].Y - 16));
                  {3dd7} u2_0000(d_34EC[I].X, (d_34EC[I].Y - 16));
                  {3e09} u1_03f0((LongInt(d_34EC[I].X) and 65520), (LongInt(d_34EC[I].Y) and 65520), 20);
                end
                else
                begin
                  {3e12} u7_0000(8);
                end;
              end
              else
              begin
                {3e30} u1_01c4(d_34EC[I].X, d_34EC[I].Y);
                {3e4e} u1_01c4(d_34EC[I].X, (d_34EC[I].Y - 16));
              end;
            end;
            31: begin
              {3e64} J := (X shr 4);
              {3e6f} K := (Y shr 4);
              {3e7e} L := (((X + 15) shr 4) + 1);
              {3e9c} if (d_0296[(J + 1), K].Solid <> 0) or ((d_0296[L, K].Solid <> 0) or ((d_0296[(J + 1), (K
                    + 1)].Solid <> 0) or (d_0296[L, (K + 1)].Solid <> 0))) then
              begin
                {3f09} d_34EC[I].DX := (-d_34EC[I].DX);
                {3f19} if d_34EC[I].DX = -1 then
                begin
                  {3f22} d_34EC[I].Frame := 1;
                end
                else
                begin
                  {3f31} d_34EC[I].Frame := 61;
                end;
              end
              else
              begin
                {3f58} if (d_0296[(J + 1), (K + 2)].Solid = 0) and (d_0296[(J + 1), (K + 2)].Special = 0) then
                begin
                  {3f81} d_34EC[I].DX := 1;
                  {3f8e} d_34EC[I].Frame := 61;
                end
                else
                begin
                  {3fb3} if (d_0296[L, (K + 2)].Solid = 0) and (d_0296[L, (K + 2)].Special = 0) then
                  begin
                    {3fdb} d_34EC[I].DX := -1;
                    {3fe8} d_34EC[I].Frame := 1;
                  end;
                end;
              end;
              {3ff5} Inc(d_34EC[I].Limit);
              {400f} if d_34EC[I].Limit >= d_34EC[I].Tick then
              begin
                {401d} d_34EC[I].Limit := 0;
                {4040} if ((d_34EC[I].Y shr 4) = ((d_34EC[1].Y + 8) shr 4)) and (((d_34EC[I].X < d_34EC[1].X)
                    and (d_34EC[I].DX = 1)) or ((d_34EC[I].X > d_34EC[1].X) and (d_34EC[I].DX = -1))) then
                begin
                  {40aa} u1_0584(d_34EC[I].X, d_34EC[I].Y, d_34EC[I].DX, 4, 827);
                end;
              end;
              {40b9} if d_34EC[I].Aux2 > 0 then
              begin
                {40c2} Dec(d_34EC[I].Aux2);
              end;
              {40d2} if d_34EC[I].Aux2 = 1 then
              begin
                {40db} d_34EC[I].Aux1 := 30;
              end
              else
              begin
                {40f0} if d_34EC[I].Aux2 = 0 then
                begin
                  {40f9} Inc(d_34EC[I].Frame);
                  {4109} if d_34EC[I].DX = -1 then
                  begin
                    {4117} if d_34EC[I].Frame > 19 then
                    begin
                      {4120} d_34EC[I].Frame := 19;
                    end;
                  end
                  else
                  begin
                    {4134} if d_34EC[I].Frame > 79 then
                    begin
                      {413d} d_34EC[I].Frame := 79;
                    end;
                  end;
                  {414a} Dec(d_34EC[I].Aux1);
                  {415a} if d_34EC[I].Aux1 = 0 then
                  begin
                    {4163} d_34EC[I].Aux2 := 80;
                  end;
                end
                else
                begin
                  {4172} Inc(d_34EC[I].Frame);
                  {4182} if d_34EC[I].DX = -1 then
                  begin
                    {4190} if d_34EC[I].Frame > 19 then
                    begin
                      {4199} d_34EC[I].Frame := 1;
                    end;
                  end
                  else
                  begin
                    {41ad} if d_34EC[I].Frame > 79 then
                    begin
                      {41b6} d_34EC[I].Frame := 61;
                    end;
                  end;
                  {41c6} d_34EC[I].X := X;
                end;
              end;
              {41e1} u1_01c4(d_34EC[I].X, d_34EC[I].Y);
              {41ff} u1_01c4(d_34EC[I].X, (d_34EC[I].Y - 16));
              {421e} if u1_027c(d_34EC[I].X, d_34EC[I].Y) then
              begin
                {4227} u7_0000(8);
                {423b} if d_34EC[I].X < d_34EC[1].X then
                begin
                  {4269} if (d_0296[(((d_34EC[I].X + 15) shr 4) + 1), (K + 1)].Solid = 0) and
                    (d_0296[(((d_34EC[I].X + 15) shr 4) + 1), K].Solid = 0) then
                  begin
                    {429f} d_34EC[I].DX := 1;
                    {42ac} d_34EC[I].Frame := 61;
                  end;
                end
                else
                begin
                  {42dd} if (d_0296[((d_34EC[I].X shr 4) + 1), (K + 1)].Solid = 0) and (d_0296[((d_34EC[I].X
                    shr 4) + 1), K].Solid = 0) then
                  begin
                    {4310} d_34EC[I].DX := -1;
                    {431d} d_34EC[I].Frame := 1;
                  end;
                end;
              end
              else
              begin
                {4346} if u1_027c(d_34EC[I].X, (d_34EC[I].Y - 16)) then
                begin
                  {435a} if d_34EC[I].X < d_34EC[1].X then
                  begin
                    {4388} if (d_0296[(((d_34EC[I].X + 15) shr 4) + 1), (K + 1)].Solid = 0) and
                    (d_0296[(((d_34EC[I].X + 15) shr 4) + 1), K].Solid = 0) then
                    begin
                      {43be} d_34EC[I].DX := 1;
                      {43cb} d_34EC[I].Frame := 61;
                    end;
                  end
                  else
                  begin
                    {43fc} if (d_0296[((d_34EC[I].X shr 4) + 1), (K + 1)].Solid = 0) and (d_0296[((d_34EC[I].X
                    shr 4) + 1), K].Solid = 0) then
                    begin
                      {442f} d_34EC[I].DX := -1;
                      {443c} d_34EC[I].Frame := 1;
                    end;
                  end;
                  {444e} if d_34EC[I].Aux2 = 0 then
                  begin
                    {4457} u7_0000(19);
                    {4468} d_699A := (d_699A + 1000);
                    {446f} d_6832 := -1;
                    {447c} d_34EC[I].Marked := 1;
                    {4497} u2_0000(d_34EC[I].X, d_34EC[I].Y);
                    {44b6} u2_0000((d_34EC[I].X - 16), d_34EC[I].Y);
                    {44d5} u2_0000((d_34EC[I].X + 16), d_34EC[I].Y);
                    {44f8} u2_0000((d_34EC[I].X + 16), (d_34EC[I].Y - 16));
                    {451b} u2_0000((d_34EC[I].X - 16), (d_34EC[I].Y - 16));
                    {453a} u2_0000(d_34EC[I].X, (d_34EC[I].Y - 16));
                    {456c} u1_03f0((LongInt(d_34EC[I].X) and 65520), (LongInt(d_34EC[I].Y) and 65520), 20);
                  end
                  else
                  begin
                    {4575} u7_0000(8);
                  end;
                end;
              end;
            end;
            32: begin
              {458c} Inc(d_34EC[I].Frame);
              {459c} if d_34EC[I].Frame > 19 then
              begin
                {45a5} d_34EC[I].Frame := 1;
              end;
              {45c7} if u1_027c(d_34EC[I].X, d_34EC[I].Y) then
              begin
                {45d3} Dec(d_34EC[I].Tick);
                {45de} d_34EC[I].State := 3;
                {45f0} if d_34EC[I].Tick <= 0 then
                begin
                  for J := 0 to 15 do
                    u9_0352(J, 12);
                  {4611} d_34AE := 0;
                  {461a} u7_0000(10);
                  {461f} d_69CE := 1;
                  {4630} d_699A := (d_699A + 5000);
                  {4637} d_6832 := -1;
                  {4644} d_34EC[I].Kind := 5001;
                  {4651} d_34EC[I].Limit := 16;
                  {465e} d_34EC[I].Sprite := 172;
                  {466b} d_34EC[I].Frame := 1;
                  {4695} u9_19f9(PByteArray(d_6D96)^[3363], d_34EC[I].X, (d_34EC[I].Y + 16));
                  {46be} u9_19f9(PByteArray(d_6D96)^[3363], d_34EC[I].X, (d_34EC[I].Y + 416));
                  {46c6} u3_00db(0);
                end
                else
                begin
                  {46d1} u7_0000(8);
                end;
              end;
            end;
            33: begin
              {4707} if (d_0296[((X shr 4) + 1), ((Y shr 4) + 1)].Solid <> 0) or ((d_0296[(((X + 15) shr 4) +
                    1), ((Y shr 4) + 1)].Solid <> 0) or ((d_0296[(((X + 8) shr 4) + 1), (Y shr 4)].Special =
                    0) and (d_0296[(((X + 8) shr 4) + 1), (Y shr 4)].Solid = 0))) then
              begin
                {479f} d_34EC[I].DX := (-d_34EC[I].DX);
                {47af} if d_34EC[I].DX = -1 then
                begin
                  {47b8} d_34EC[I].Frame := 1;
                end
                else
                begin
                  {47c7} d_34EC[I].Frame := 21;
                end;
              end;
              {47d4} Inc(d_34EC[I].Frame);
              {47e4} if d_34EC[I].DX = -1 then
              begin
                {47f2} if d_34EC[I].Frame > 19 then
                begin
                  {47fb} d_34EC[I].Frame := 1;
                end;
              end
              else
              begin
                {480f} if d_34EC[I].Frame > 39 then
                begin
                  {4818} d_34EC[I].Frame := 21;
                end;
              end;
              {4825} Inc(d_34EC[I].Limit);
              {483f} if d_34EC[I].Limit = d_34EC[I].Tick then
              begin
                {4853} if ((d_34EC[I].X - 16) < d_34EC[1].X) and (((d_34EC[I].X + 16) > d_34EC[1].X) and
                    (d_34EC[I].Y < d_34EC[1].Y)) then
                begin
                  {4883} d_34EC[I].Limit := 0;
                  {48a6} u1_0584(X, (d_34EC[I].Y + 8), 1, 8, 199);
                end
                else
                begin
                  {48b2} Dec(d_34EC[I].Limit);
                end;
              end;
              {48c0} d_34EC[I].X := X;
              {48db} u1_01c4(d_34EC[I].X, d_34EC[I].Y);
              {48fa} if u1_027c(d_34EC[I].X, d_34EC[I].Y) then
              begin
                {4906} d_34EC[I].State := 3;
                {4913} Dec(d_34EC[I].Aux1);
                {4923} if d_34EC[I].Aux1 <= 0 then
                begin
                  {492c} u7_0000(19);
                  {493d} d_699A := (d_699A + 500);
                  {4944} d_6832 := -1;
                  {4960} u2_0000(d_34EC[I].X, d_34EC[I].Y);
                  {497f} u2_0000((d_34EC[I].X - 16), d_34EC[I].Y);
                  {499e} u2_0000((d_34EC[I].X + 16), d_34EC[I].Y);
                  {49aa} d_34EC[I].Kind := 5001;
                  {49b7} d_34EC[I].Limit := 16;
                  {49c4} d_34EC[I].Sprite := 169;
                  {49d1} d_34EC[I].Frame := 1;
                  {49f4} d_34EC[I].X := (LongInt((d_34EC[I].X + 8)) and 65520);
                  {4a1c} u9_19f9(PByteArray(d_6D96)^[2883], d_34EC[I].X, (d_34EC[I].Y + 16));
                  {4a45} u9_19f9(PByteArray(d_6D96)^[2883], d_34EC[I].X, (d_34EC[I].Y + 416));
                end
                else
                begin
                  {4a50} u7_0000(8);
                end;
              end;
            end;
            34: begin
              {4a69} J := ((X shr 4) + 1);
              {4a75} M := ((Y shr 4) + 1);
              {4a7c} K := (M + 1);
              {4a8b} L := (((X + 15) shr 4) + 1);
              {4aa8} if d_0296[J, M].Solid <> 0 then
              begin
                {4ab1} d_34EC[I].DX := 1;
                {4abe} d_34EC[I].Frame := 1;
              end
              else
              begin
                {4ae1} if d_0296[L, M].Solid <> 0 then
                begin
                  {4aea} d_34EC[I].DX := -1;
                  {4af7} d_34EC[I].Frame := 21;
                end
                else
                begin
                  {4b1a} if (d_0296[J, K].Solid = 0) and (d_0296[J, K].Special = 0) then
                  begin
                    {4b3f} d_34EC[I].DX := 1;
                    {4b4c} d_34EC[I].Frame := 1;
                  end
                  else
                  begin
                    {4b6e} if (d_0296[L, K].Solid = 0) and (d_0296[L, K].Special = 0) then
                    begin
                      {4b93} d_34EC[I].DX := -1;
                      {4ba0} d_34EC[I].Frame := 21;
                    end;
                  end;
                end;
              end;
              {4bad} Inc(d_34EC[I].Frame);
              {4bbd} if d_34EC[I].DX = 1 then
              begin
                {4bcb} if d_34EC[I].Frame > 19 then
                begin
                  {4bd4} d_34EC[I].Frame := 1;
                end;
              end
              else
              begin
                {4be8} if d_34EC[I].Frame > 39 then
                begin
                  {4bf1} d_34EC[I].Frame := 21;
                end;
              end;
              {4c01} d_34EC[I].X := X;
              {4c1c} u1_01c4(d_34EC[I].X, d_34EC[I].Y);
              {4c3b} if u1_027c(d_34EC[I].X, d_34EC[I].Y) then
              begin
                {4c47} d_34EC[I].State := 3;
                {4c54} Dec(d_34EC[I].Aux1);
                {4c64} if d_34EC[I].Aux1 <= 0 then
                begin
                  {4c6d} u7_0000(19);
                  {4c7e} d_699A := (d_699A + 1000);
                  {4c85} d_6832 := -1;
                  {4ca1} u2_0000(d_34EC[I].X, d_34EC[I].Y);
                  {4cc0} u2_0000((d_34EC[I].X - 16), d_34EC[I].Y);
                  {4cdf} u2_0000((d_34EC[I].X + 16), d_34EC[I].Y);
                  {4ceb} d_34EC[I].Kind := 5001;
                  {4cf8} d_34EC[I].Limit := 16;
                  {4d05} d_34EC[I].Sprite := 170;
                  {4d12} d_34EC[I].Frame := 1;
                  {4d35} d_34EC[I].X := (LongInt((d_34EC[I].X + 8)) and 65520);
                  {4d5d} u9_19f9(PByteArray(d_6D96)^[3043], d_34EC[I].X, (d_34EC[I].Y + 16));
                  {4d86} u9_19f9(PByteArray(d_6D96)^[3043], d_34EC[I].X, (d_34EC[I].Y + 416));
                  {4dae} u1_0584(d_34EC[I].X, d_34EC[I].Y, -1, 4, 125);
                  {4dd4} u1_0584(d_34EC[I].X, d_34EC[I].Y, 1, 4, 126);
                end
                else
                begin
                  {4ddd} u7_0000(8);
                end;
              end;
            end;
            35: begin
              {4df4} Inc(d_34EC[I].Frame);
              {4e04} if d_34EC[I].Frame > 19 then
              begin
                {4e0d} d_34EC[I].Frame := 1;
              end;
              {4e1d} d_34EC[I].X := X;
              {4e38} u1_01c4(d_34EC[I].X, d_34EC[I].Y);
              {4e57} if u1_027c(d_34EC[I].X, d_34EC[I].Y) then
              begin
                {4e63} d_34EC[I].State := 3;
                {4e70} Dec(d_34EC[I].Aux1);
                {4e80} if d_34EC[I].Aux1 <= 0 then
                begin
                  {4e89} u7_0000(19);
                  {4e9a} d_699A := (d_699A + 1000);
                  {4ea1} d_6832 := -1;
                  {4eae} d_34EC[I].Kind := 5001;
                  {4ebb} d_34EC[I].Limit := 16;
                  {4ec8} d_34EC[I].Sprite := 170;
                  {4ed5} d_34EC[I].Frame := 1;
                  {4ef8} d_34EC[I].X := (LongInt((d_34EC[I].X + 8)) and 65520);
                  {4f20} u9_19f9(PByteArray(d_6D96)^[3043], d_34EC[I].X, (d_34EC[I].Y + 16));
                  {4f49} u9_19f9(PByteArray(d_6D96)^[3043], d_34EC[I].X, (d_34EC[I].Y + 416));
                  {4f4e} d_69EF := 1;
                end
                else
                begin
                  {4f59} u7_0000(8);
                end;
              end;
            end;
            36: begin
              {4f73} d_34EC[I].X := X;
              {4f7e} Inc(d_34EC[I].Limit);
              {4f98} if d_34EC[I].Limit >= d_34EC[I].Aux1 then
              begin
                {4faf} d_34EC[I].Limit := d_34EC[I].Aux1;
                {4fcb} if ((d_34EC[1].X + 8) >= (d_34EC[I].X - 4)) and (((d_34EC[1].X + 8) <= (d_34EC[I].X +
                    4)) and ((d_34EC[I].Y >= d_34EC[1].Y) and (d_69EF = 0))) then
                begin
                  {5026} u1_0584(d_34EC[I].X, (d_34EC[I].Y + 8), -1, 8, 114);
                  {5032} d_34EC[I].Limit := 0;
                end;
              end;
            end;
            137: begin
              {5052} K := ((d_34EC[I].Y shr 4) + 1);
              {507d} if (d_0296[((d_34EC[I].X shr 4) + 1), K].Solid <> 0) or (d_0296[(((d_34EC[I].X + 15) shr
                    4) + 1), K].Solid <> 0) then
              begin
                {50bb} if d_34EC[I].Marked <> 0 then
                begin
                  {50c4} d_34EC[I].Inactive := 1;
                end;
                {50d0} d_34EC[I].Marked := 1;
                {50e1} if d_34EC[I].Y < 0 then
                begin
                  {50ec} d_34EC[I].Y := 0;
                end;
                {5106} u2_0000(d_34EC[I].X, d_34EC[I].Y);
                {5125} u2_0000((d_34EC[I].X + 16), d_34EC[I].Y);
                {5144} u2_0000(d_34EC[I].X, (d_34EC[I].Y + 16));
                {5167} u2_0000((d_34EC[I].X + 16), (d_34EC[I].Y + 16));
                {5182} u2_2530(d_34EC[I].X, d_34EC[I].Y);
                {51a1} u2_2530((d_34EC[I].X + 16), d_34EC[I].Y);
                {51c0} u2_2530(d_34EC[I].X, (d_34EC[I].Y + 16));
                {51e3} u2_2530((d_34EC[I].X + 16), (d_34EC[I].Y + 16));
              end
              else
              begin
                {51f1} Inc(d_34EC[I].Frame);
                {5201} if d_34EC[I].Frame > 9 then
                begin
                  {520a} d_34EC[I].Frame := 1;
                end;
                {521a} d_34EC[I].Y := Y;
                {522a} if d_34EC[I].Y < 0 then
                begin
                  {5235} d_34EC[I].Y := 0;
                end;
                {5250} u1_01c4(d_34EC[I].X, d_34EC[I].Y);
              end;
            end;
            37: begin
              {526e} K := (d_34EC[I].Y shr 4);
              {5299} if (d_0296[((d_34EC[I].X shr 4) + 1), K].Solid <> 0) or (d_0296[(((d_34EC[I].X + 15) shr
                    4) + 1), K].Solid <> 0) then
              begin
                {52d7} if d_34EC[I].Marked <> 0 then
                begin
                  {52e0} d_34EC[I].Inactive := 1;
                end;
                {52ec} d_34EC[I].Marked := 1;
                {52fd} if d_34EC[I].Y < 0 then
                begin
                  {5308} d_34EC[I].Y := 0;
                end;
                {5322} u2_0000(d_34EC[I].X, d_34EC[I].Y);
                {5341} u2_0000((d_34EC[I].X + 16), d_34EC[I].Y);
                {5360} u2_0000(d_34EC[I].X, (d_34EC[I].Y + 16));
                {5383} u2_0000((d_34EC[I].X + 16), (d_34EC[I].Y + 16));
                {539e} u2_2530(d_34EC[I].X, d_34EC[I].Y);
                {53bd} u2_2530((d_34EC[I].X + 16), d_34EC[I].Y);
                {53dc} u2_2530(d_34EC[I].X, (d_34EC[I].Y + 16));
                {53ff} u2_2530((d_34EC[I].X + 16), (d_34EC[I].Y + 16));
              end
              else
              begin
                {540e} Inc(d_34EC[I].Frame);
                {541e} if d_34EC[I].Frame > 9 then
                begin
                  {5427} d_34EC[I].Frame := 1;
                end;
                {5437} d_34EC[I].Y := Y;
                {5447} if d_34EC[I].Y < 0 then
                begin
                  {5452} d_34EC[I].Y := 0;
                end;
                {545b} if (d_69F3 = 0) and ((((d_34EC[I].X <= d_34EC[1].X) and ((d_34EC[I].X + 9) >=
                    d_34EC[1].X)) or (((d_34EC[1].X + 9) >= d_34EC[I].X) and (d_34EC[I].X >= d_34EC[1].X)))
                    and ((((d_34EC[I].Y <= d_34EC[1].Y) and ((d_34EC[I].Y + 15) >= d_34EC[1].Y)) or
                    (((d_34EC[1].Y + 15) >= d_34EC[I].Y) and (d_34EC[I].Y >= d_34EC[1].Y))) and (d_69F5 = 0)))
                    then
                begin
                  {54f9} d_69F5 := 1;
                  {54fe} d_69F6 := 35;
                  {5507} u7_0000(22);
                end;
              end;
            end;
            38: begin
              {553d} if (d_0296[((X shr 4) + 1), ((Y shr 4) + 1)].Solid <> 0) or (d_0296[(((X + 15) shr 4) +
                    1), ((Y shr 4) + 1)].Solid <> 0) then
              begin
                {557e} d_34EC[I].DX := (-d_34EC[I].DX);
              end;
              {5589} Inc(d_34EC[I].Frame);
              {5599} if d_34EC[I].Frame > 19 then
              begin
                {55a2} d_34EC[I].Frame := 1;
              end;
              {55b4} if d_34EC[I].Aux2 > 0 then
              begin
                {55bd} Dec(d_34EC[I].Aux2);
              end;
              {55cd} if d_34EC[I].Aux2 = 0 then
              begin
                {55db} if d_34EC[I].Limit = 0 then
                begin
                  {5603} u1_0584(d_34EC[I].X, (d_34EC[I].Y + 16), 1, 0, 137);
                end;
                {560d} Inc(d_34EC[I].Limit);
                {5627} if d_34EC[I].Limit = d_34EC[I].Tick then
                begin
                  {5632} d_34EC[I].Limit := 0;
                  {563d} d_34EC[I].Aux2 := 110;
                end;
              end
              else
              begin
                {564f} d_34EC[I].X := X;
              end;
              {566a} u1_01c4(d_34EC[I].X, d_34EC[I].Y);
              {5689} if u1_027c(d_34EC[I].X, d_34EC[I].Y) then
              begin
                {568f} u7_0000(8);
              end;
            end;
            39: begin
              {56a7} J := (X shr 4);
              {56b2} K := (Y shr 4);
              {56c1} L := (((X + 15) shr 4) + 1);
              {56df} if (d_0296[(J + 1), K].Solid <> 0) or ((d_0296[L, K].Solid <> 0) or ((d_0296[(J + 1), (K
                    + 1)].Solid <> 0) or (d_0296[L, (K + 1)].Solid <> 0))) then
              begin
                {574c} d_34EC[I].DX := (-d_34EC[I].DX);
                {575c} if d_34EC[I].DX = -1 then
                begin
                  {5765} d_34EC[I].Frame := 1;
                end
                else
                begin
                  {5774} d_34EC[I].Frame := 201;
                end;
              end
              else
              begin
                {579b} if (d_0296[(J + 1), (K + 2)].Solid = 0) and (d_0296[(J + 1), (K + 2)].Special = 0) then
                begin
                  {57c4} d_34EC[I].DX := 1;
                  {57d1} d_34EC[I].Frame := 201;
                end
                else
                begin
                  {57f6} if (d_0296[L, (K + 2)].Solid = 0) and (d_0296[L, (K + 2)].Special = 0) then
                  begin
                    {581e} d_34EC[I].DX := -1;
                    {582b} d_34EC[I].Frame := 1;
                  end;
                end;
              end;
              {5838} Inc(d_34EC[I].Limit);
              {5852} if d_34EC[I].Limit >= d_34EC[I].Tick then
              begin
                {5860} d_34EC[I].Limit := 0;
                {5883} if ((d_34EC[I].Y shr 4) = ((d_34EC[1].Y + 8) shr 4)) and (((d_34EC[I].X < d_34EC[1].X)
                    and (d_34EC[I].DX = 1)) or ((d_34EC[I].X > d_34EC[1].X) and (d_34EC[I].DX = -1))) then
                begin
                  {58ed} u1_0584(d_34EC[I].X, d_34EC[I].Y, d_34EC[I].DX, 4, 827);
                end;
              end;
              {58fc} if d_34EC[I].Aux2 > 0 then
              begin
                {5905} Dec(d_34EC[I].Aux2);
              end;
              {5915} if d_34EC[I].Aux2 = 1 then
              begin
                {591e} d_34EC[I].Aux1 := 30;
              end
              else
              begin
                {5933} if d_34EC[I].Aux2 = 0 then
                begin
                  {593c} Inc(d_34EC[I].Frame);
                  {594c} if d_34EC[I].DX = -1 then
                  begin
                    {595a} if d_34EC[I].Frame > 19 then
                    begin
                      {5963} d_34EC[I].Frame := 19;
                    end;
                  end
                  else
                  begin
                    {5978} if d_34EC[I].Frame > 219 then
                    begin
                      {5981} d_34EC[I].Frame := 219;
                    end;
                  end;
                  {598e} Dec(d_34EC[I].Aux1);
                  {599e} if d_34EC[I].Aux1 = 0 then
                  begin
                    {59a7} d_34EC[I].Aux2 := 80;
                  end;
                end
                else
                begin
                  {59b6} Inc(d_34EC[I].Frame);
                  {59c6} if d_34EC[I].DX = -1 then
                  begin
                    {59d4} if d_34EC[I].Frame > 19 then
                    begin
                      {59dd} d_34EC[I].Frame := 1;
                    end;
                  end
                  else
                  begin
                    {59f2} if d_34EC[I].Frame > 219 then
                    begin
                      {59fb} d_34EC[I].Frame := 201;
                    end;
                  end;
                  {5a0b} d_34EC[I].X := X;
                end;
              end;
              {5a26} u1_01c4(d_34EC[I].X, d_34EC[I].Y);
              {5a44} u1_01c4(d_34EC[I].X, (d_34EC[I].Y - 16));
              {5a63} if u1_027c(d_34EC[I].X, d_34EC[I].Y) then
              begin
                {5a6c} u7_0000(8);
                {5a80} if d_34EC[I].X < d_34EC[1].X then
                begin
                  {5aae} if (d_0296[(((d_34EC[I].X + 15) shr 4) + 1), (K + 1)].Solid = 0) and
                    (d_0296[(((d_34EC[I].X + 15) shr 4) + 1), K].Solid = 0) then
                  begin
                    {5ae4} d_34EC[I].DX := 1;
                    {5af1} d_34EC[I].Frame := 201;
                  end;
                end
                else
                begin
                  {5b22} if (d_0296[((d_34EC[I].X shr 4) + 1), (K + 1)].Solid = 0) and (d_0296[((d_34EC[I].X
                    shr 4) + 1), K].Solid = 0) then
                  begin
                    {5b55} d_34EC[I].DX := -1;
                    {5b62} d_34EC[I].Frame := 1;
                  end;
                end;
              end
              else
              begin
                {5b8b} if u1_027c(d_34EC[I].X, (d_34EC[I].Y - 16)) then
                begin
                  {5b9f} if d_34EC[I].X < d_34EC[1].X then
                  begin
                    {5bcd} if (d_0296[(((d_34EC[I].X + 15) shr 4) + 1), (K + 1)].Solid = 0) and
                    (d_0296[(((d_34EC[I].X + 15) shr 4) + 1), K].Solid = 0) then
                    begin
                      {5c03} d_34EC[I].DX := 1;
                      {5c10} d_34EC[I].Frame := 201;
                    end;
                  end
                  else
                  begin
                    {5c41} if (d_0296[((d_34EC[I].X shr 4) + 1), (K + 1)].Solid = 0) and (d_0296[((d_34EC[I].X
                    shr 4) + 1), K].Solid = 0) then
                    begin
                      {5c74} d_34EC[I].DX := -1;
                      {5c81} d_34EC[I].Frame := 1;
                    end;
                  end;
                  {5c93} if d_34EC[I].Aux2 = 0 then
                  begin
                    {5c9c} u7_0000(19);
                    {5cad} d_699A := (d_699A + 1000);
                    {5cb4} d_6832 := -1;
                    {5cc1} d_34EC[I].Marked := 1;
                    {5cdc} u2_0000(d_34EC[I].X, d_34EC[I].Y);
                    {5cfb} u2_0000((d_34EC[I].X - 16), d_34EC[I].Y);
                    {5d1a} u2_0000((d_34EC[I].X + 16), d_34EC[I].Y);
                    {5d3d} u2_0000((d_34EC[I].X + 16), (d_34EC[I].Y - 16));
                    {5d60} u2_0000((d_34EC[I].X - 16), (d_34EC[I].Y - 16));
                    {5d7f} u2_0000(d_34EC[I].X, (d_34EC[I].Y - 16));
                    {5db1} u1_03f0((LongInt(d_34EC[I].X) and 65520), (LongInt(d_34EC[I].Y) and 65520), 20);
                  end
                  else
                  begin
                    {5dba} u7_0000(8);
                  end;
                end;
              end;
            end;
            40: begin
              {5dd1} Inc(d_34EC[I].Frame);
              {5de1} if d_34EC[I].Frame > 19 then
              begin
                {5dea} d_34EC[I].Frame := 1;
              end;
              {5df7} Dec(d_34EC[I].Limit);
              {5e07} if d_34EC[I].Limit = 0 then
              begin
                {5e13} d_34EC[I].Marked := 1;
                {5e1e} u2_0000(X, Y);
                {5e2d} u2_0000((X - 16), Y);
                {5e3c} u2_0000((X + 16), Y);
                {5e47} u2_2530(X, Y);
                {5e56} u2_2530((X - 16), Y);
                {5e65} u2_2530((X + 16), Y);
                {5e71} d_6840 := (432 - d_6840);
                {5e7a} u2_0000(X, Y);
                {5e89} u2_0000((X + 16), Y);
                {5e98} u2_0000((X - 16), Y);
                {5ea3} u2_2530(X, Y);
                {5eb2} u2_2530((X + 16), Y);
                {5ec1} u2_2530((X - 16), Y);
                {5ecd} d_6840 := (432 - d_6840);
              end
              else
              begin
                {5ee9} u1_01c4(d_34EC[I].X, d_34EC[I].Y);
              end;
            end;
            41: begin
              {5f04} if d_34EC[I].Sprite = 435 then
              begin
                {5f17} J := (d_34EC[1].X - d_34EC[I].X);
                {5f28} K := (d_34EC[1].Y - d_34EC[I].Y);
                {5f2f} if (J < 8) and ((J > -8) and ((K < 8) and (K > -8))) then
                begin
                  while d_0296[(X shr 4) + 1, Y shr 4].Solid = 0 do
                    Dec(Y, 16);
                  {5f77} u7_0000(9);
                  {5f86} d_34EC[I].Y := Y;
                  {5f91} d_34EC[I].Sprite := 619;
                  {5f9e} d_34EC[I].Speed := 8;
                  {5fab} d_34EC[I].DY := 1;
                end;
              end
              else
              begin
                {5fc7} K := ((d_34EC[I].Y shr 4) + 2);
                {5fde} J := (((d_34EC[I].X + 3) shr 4) + 1);
                {5ff5} L := (((d_34EC[I].X + 12) shr 4) + 1);
                {6012} if (d_0296[J, K].Solid = 0) and ((d_0296[L, K].Solid = 0) and ((d_0296[J, K].Special =
                    0) and (d_0296[L, K].Special = 0))) then
                begin
                  {6089} d_34EC[I].Y := (d_34EC[I].Y + 4);
                  {60a3} u2_0000(d_34EC[I].X, d_34EC[I].Y);
                  {60be} u2_0000(d_34EC[I].X, d_34EC[I].Y);
                  {60e1} u2_0000((d_34EC[I].X - 16), (d_34EC[I].Y - 16));
                  {6104} u2_0000((d_34EC[I].X - 16), (d_34EC[I].Y - 16));
                end
                else
                begin
                  {6113} d_34EC[I].Marked := 1;
                  {611e} u2_0000(X, Y);
                  {612d} u2_0000((X - 16), Y);
                  {613c} u2_0000((X + 16), Y);
                  {614b} u2_0000(X, (Y - 16));
                  {615e} u2_0000((X - 16), (Y - 16));
                  {6171} u2_0000((X + 16), (Y - 16));
                  {617c} u2_2530(X, Y);
                  {618b} u2_2530((X - 16), Y);
                  {619a} u2_2530((X + 16), Y);
                  {61a9} u2_2530(X, (Y - 16));
                  {61bc} u2_2530((X - 16), (Y - 16));
                  {61cf} u2_2530((X + 16), (Y - 16));
                  {61db} d_6840 := (432 - d_6840);
                  {61e4} u2_0000(X, Y);
                  {61f3} u2_0000((X + 16), Y);
                  {6202} u2_0000((X - 16), Y);
                  {6211} u2_0000(X, (Y - 16));
                  {6224} u2_0000((X + 16), (Y - 16));
                  {6237} u2_0000((X - 16), (Y - 16));
                  {6242} u2_2530(X, Y);
                  {6251} u2_2530((X + 16), Y);
                  {6260} u2_2530((X - 16), Y);
                  {626f} u2_2530(X, (Y - 16));
                  {6282} u2_2530((X + 16), (Y - 16));
                  {6295} u2_2530((X - 16), (Y - 16));
                  {62a1} d_6840 := (432 - d_6840);
                end;
                {62b2} J := (d_34EC[1].X - d_34EC[I].X);
                {62c3} K := (d_34EC[1].Y - d_34EC[I].Y);
                {62ca} if (J < 10) and ((J > -10) and ((K < 10) and (K > -10))) then
                begin
                  {62f6} d_699A := (d_699A + 5000);
                  {62fd} d_6832 := -1;
                  {630a} d_34EC[I].Kind := 5001;
                  {6317} d_34EC[I].Limit := 16;
                  {6324} d_34EC[I].Sprite := 172;
                  {6331} d_34EC[I].Frame := 1;
                  {6340} d_34EC[I].Speed := 0;
                  {6368} u9_19f9(PByteArray(d_6D96)^[3203], d_34EC[I].X, (d_34EC[I].Y + 16));
                  {6391} u9_19f9(PByteArray(d_6D96)^[3203], d_34EC[I].X, (d_34EC[I].Y + 416));
                end;
              end;
            end;
            43: begin
              {63a5} Inc(d_34EC[I].Tick);
              {63bf} if d_34EC[I].Tick = d_34EC[I].Limit then
              begin
                {63c8} Inc(d_34EC[I].Frame);
                {63d8} if d_34EC[I].Frame > 19 then
                begin
                  {63eb} d_34EC[I].Frame := (Random(5) + 1);
                end;
                {63f8} d_34EC[I].Tick := 0;
              end;
            end;
            44: begin
              {640a} Inc(d_34EC[I].Frame);
              {641b} if d_34EC[I].Sprite = 259 then
              begin
                {6424} Inc(d_34EC[I].Frame);
                {643f} u1_01c4(d_34EC[I].X, d_34EC[I].Y);
              end;
              {644e} if d_34EC[I].Frame > 19 then
              begin
                {6457} d_34EC[I].Frame := 1;
              end;
            end;
          end;
        end;
      end;
  for I := 1 to d_69A2 do
  begin
    {648b} if (d_685A[I].Inactive = 0) and (d_685A[I].Sprite <> 626) then
    begin
      {64b4} d_685A[I].OldX := d_685A[I].X;
      {64ca} d_685A[I].OldY := d_685A[I].Y;
      {64da} if d_685A[I].DX = 1 then
      begin
        {64f2} X := (d_685A[I].X + d_685A[I].Speed);
      end
      else
      begin
        {6503} if d_685A[I].DX = -1 then
        begin
          {651b} X := (d_685A[I].X - d_685A[I].Speed);
        end
        else
        begin
          {652b} X := d_685A[I].X;
        end;
      end;
      {6542} Y := (((d_685A[I].Y + 8) shr 4) + 1);
      {6565} if (d_0296[((X shr 4) + 1), Y].Solid <> 0) or (d_0296[(((X + 8) shr 4) + 1), Y].Solid <> 0) then
      begin
        {6590} u7_0000(7);
        {659c} d_685A[I].Sprite := 626;
        {65ab} d_685A[I].Speed := 0;
        {65b6} d_685A[I].Limit := 7;
      end;
      {65c6} d_685A[I].X := X;
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
function u1_65d9(xOffset, yOffset: Word): Boolean;
var
  x1: Word;
  y1: Word;
  x2: Word;
  y2: Word;
begin
  x1 := ((Word(d_34EC[1].X) + xOffset + 3) shr 4) + 1;
  x2 := ((Word(d_34EC[1].X) + xOffset + 12) shr 4) + 1;
  y1 := ((Word(d_34EC[1].Y) + yOffset) shr 4) + 1;
  y2 := ((Word(d_34EC[1].Y) + yOffset + 15) shr 4) + 1;

  if (d_0296[x1, y1].Solid <> 0) or
     (d_0296[x2, y1].Solid <> 0) or
     (d_0296[x1, y2].Solid <> 0) or
     (d_0296[x2, y2].Solid <> 0) then
  begin
    u1_65d9 := False;
    if d_681C > 1 then
      d_681E := 0;
  end
  else
    u1_65d9 := True;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u1_66b3;
begin
  Inc(d_34EA);
  if d_34EA > 19 then
    d_34EA := 19;
  d_6EC0 := 1;
  Inc(d_34EC[1].Y, d_34B0[d_34EA]);
  if (d_0296[((d_34EC[1].X + 3) shr 4) + 1, ((d_34EC[1].Y shr 4) + 2)].Solid <> 0) or
     (d_0296[((d_34EC[1].X + 12) shr 4) + 1, ((d_34EC[1].Y shr 4) + 2)].Solid <> 0) then
  begin
    Inc(d_6818);
    d_34EC[1].Y := d_34EC[1].Y and $FFF0;
    d_6EC0 := 0;
  end;
  if d_34EA > 10 then
  begin
    if (d_0296[((d_34EC[1].X + 3) shr 4) + 1, ((d_34EC[1].Y + 16) shr 4) + 1].Special <> 0) or
       (d_0296[((d_34EC[1].X + 12) shr 4) + 1, ((d_34EC[1].Y + 16) shr 4) + 1].Special <> 0) then
    begin
      if d_34EC[1].Y < 5 then
      begin
        Inc(d_6818);
        d_34EC[1].Y := d_34EC[1].Y and $FFF0;
        d_6EC0 := 0;
      end
      else if (d_0296[((d_34EC[1].X + 3) shr 4) + 1, ((d_34EC[1].Y + 7) shr 4) + 1].Special = 0) and
              (d_0296[((d_34EC[1].X + 12) shr 4) + 1, ((d_34EC[1].Y + 7) shr 4) + 1].Special = 0) then
      begin
        Inc(d_6818);
        d_34EC[1].Y := d_34EC[1].Y and $FFF0;
        d_6EC0 := 0;
      end;
    end;
  end;
  if d_683A + 120 < d_34EC[1].Y then
  begin
    if d_683A + d_34B0[d_34EA] < 184 then
      Inc(d_683A, d_34B0[d_34EA])
    else
      d_683A := 184;
  end;
  if d_6EC0 <> 0 then
  begin
    if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) or (d_34EC[1].Sprite = 13) then
      d_34EC[1].Sprite := 13
    else
      d_34EC[1].Sprite := 14;
  end
  else if d_34EC[1].Sprite = 13 then
  begin
    if d_6ECB <> 0 then
      d_34EC[1].Sprite := 1
    else
      d_34EC[1].Sprite := 9;
  end
  else if d_34EC[1].Sprite = 14 then
  begin
    if d_6ECA <> 0 then
      d_34EC[1].Sprite := 5
    else
      d_34EC[1].Sprite := 10;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u1_68f5;
begin
  d_34EC[1].OldX := d_34EC[1].X;
  d_34EC[1].OldY := d_34EC[1].Y;

  if d_6ECB <> 0 then
  begin
    u1_012d;
    if u1_65d9(d_6820, 0) then
    begin
      if d_6838 < 320 then
      begin
        if d_6838 + 170 < d_34EC[1].X then
        begin
          Inc(d_6838, d_6820);
          if d_6838 > 320 then
            d_6838 := 320;
        end;
      end;
      Inc(d_34EC[1].X, d_6820);
    end;
  end;

  if d_6ECA <> 0 then
  begin
    u1_012d;
    if u1_65d9(-d_6820, 0) then
    begin
      if d_6838 > 0 then
      begin
        if d_6838 + 150 > d_34EC[1].X then
        begin
          Dec(d_6838, d_6820);
          if d_6838 < 0 then
            d_6838 := 0;
        end;
      end;
      Dec(d_34EC[1].X, d_6820);
    end;
  end;

  if d_6EC4 <> 0 then
  begin
    if u1_65d9(0, 4) then
    begin
      if d_683A < 184 then
      begin
        if d_683A + 80 < d_34EC[1].Y then
          Inc(d_683A, 4);
      end;
      Inc(d_34EC[1].Y, 4);
    end;
  end;

  if d_6EC3 <> 0 then
  begin
    if u1_65d9(0, Word(-4)) then
    begin
      if d_683A > 0 then
      begin
        if d_683A + 80 > d_34EC[1].Y then
        begin
          Dec(d_683A, 4);
          if d_683A < 0 then
            d_683A := 0;
        end;
      end;
      Dec(d_34EC[1].Y, 4);
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u1_6a0e;
begin
  if (d_6EC1 = 0) and (d_6EC2 = 0) then
    u1_66b3;

  if (d_69B4 = 0) and (d_6EC1 = 0) and (d_6EC0 = 0) then
    if (d_6ECD <> 0) or (u6_0038 and (d_341C)) then
    begin
      if d_0296[(((d_34EC[1].X + 3) shr 4) + 1), (((d_34EC[1].Y - 3) shr 4) + 1)].Solid = 0 then
      begin
        if d_0296[(((d_34EC[1].X + 12) shr 4) + 1), (((d_34EC[1].Y - 3) shr 4) + 1)].Solid = 0 then
        begin
          if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) or (d_34EC[1].Sprite = 13) then
            d_34EC[1].Sprite := 13
          else
            d_34EC[1].Sprite := 14;
          u7_0000(1);
          d_6EC1 := 1;
          d_6EC2 := 0;
          d_34EA := 0;
        end;
      end;
    end;

  if d_6EC1 <> 0 then
  begin
    Inc(d_34EA);
    if d_34EA = 10 then
    begin
      d_6EC1 := 0;
      d_34EA := 9;
    end;
    if d_34EA < 17 then
      if u1_65d9(0, -Integer(d_34B0[d_34EA])) then
      begin
        if d_683A > 0 then
          if d_683A + 80 > d_34EC[1].Y then
          begin
            Dec(d_683A, d_34B0[d_34EA]);
            if d_683A < 0 then
              d_683A := 0;
          end;
        Dec(d_34EC[1].Y, d_34B0[d_34EA]);
      end
      else
      begin
        d_34EA := 9;
        d_6EC1 := 0;
      end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u1_6d0e(X, Y: Integer);
var
  I, XX, YY: Integer;
begin
  case Integer(d_0296[(X shr 4)+1,(Y shr 4)+1].Aux) of
    0: ;
    $1A5,$1A7,$1A9:
      begin
        case Integer(d_0296[(X shr 4)+1,(Y shr 4)+1].Aux) of
          $1A5: d_69E9 := 1;
          $1A7: d_69EA := 1;
          $1A9: d_69EB := 1;
        end;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(5);
        d_6832 := -1;
      end;
    $1A6,$1A8,$1AA:
      begin
        I := 0;
        case Integer(d_0296[(X shr 4)+1,(Y shr 4)+1].Aux) of
          $1A6: if d_69E9 = 1 then begin I := 1; d_69E9 := 0 end;
          $1A8: if d_69EA = 1 then begin I := 1; d_69EA := 0 end;
          $1AA: if d_69EB = 1 then begin I := 1; d_69EB := 0 end;
        end;
        if I = 1 then
        begin
          d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
          d_0296[(X shr 4)+1,(Y shr 4)+1].Solid := 0;
          u7_0000(6);
          d_6832 := -1;
        end;
      end;
    $12D:
      begin
        d_6858 := d_6858 + 5;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        if d_6858 > 99 then d_6858 := 99;
        d_6832 := -1;
        u7_0000(5);
      end;
    $13C:
      begin
        d_699A := d_699A + 1000;
        u1_03f0(X and $FFF0,Y and $FFF0,20);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(4);
      end;
    $26A:
      begin
        d_699A := d_699A + 250;
        u1_03f0(X and $FFF0,Y and $FFF0,18);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(4);
      end;
    $26B:
      begin
        d_699A := d_699A + 1000;
        u1_03f0(X and $FFF0,Y and $FFF0,20);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(4);
      end;
    $26C:
      begin
        d_699A := d_699A + 500;
        u1_03f0(X and $FFF0,Y and $FFF0,19);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(4);
      end;
    $275:
      begin
        d_699A := d_699A + 100;
        u1_03f0(X and $FFF0,Y and $FFF0,17);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(4);
      end;
    $276:
      begin
        d_699A := d_699A + 1000;
        u1_03f0(X and $FFF0,Y and $FFF0,20);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(4);
      end;
    $277:
      begin
        d_699A := d_699A + 500;
        u1_03f0(X and $FFF0,Y and $FFF0,19);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(4);
      end;
    $278:
      begin
        d_699A := d_699A + 100;
        u1_03f0(X and $FFF0,Y and $FFF0,17);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(4);
      end;
    $2C:
      begin
        d_699A := d_699A + 500;
        u1_03f0(X and $FFF0,Y and $FFF0,19);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(4);
      end;
    $26D..$26F:
      begin
        case Integer(d_0296[(X shr 4)+1,(Y shr 4)+1].Aux) of
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
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
      end;
    $25E:
      begin
        d_699A := d_699A + 500;
        u1_03f0(X and $FFF0,Y and $FFF0,19);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(4);
        d_6832 := -1;
      end;
    $130:
      begin
        d_6844[d_681C] := 1;
        d_699A := d_699A + 2000;
        u1_03f0(X and $FFF0,Y and $FFF0,21);
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(5);
        d_6D66 := 1;
      end;
    $25F:
      begin
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(4);
        u3_9b3e('You can see invisible platforms.');
        for Y := 1 to 24 do
          for X := 1 to 40 do
            if Integer(d_0296[X,Y].Aux) = -1 then
            begin
              d_0296[X,Y].Overlay := $260;
              d_0296[X,Y].Special := 1;
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
        d_6D62 := d_34EC[1].X;
        d_6D64 := d_34EC[1].Y;
        case Integer(d_0296[(X shr 4)+1,(Y shr 4)+1].Aux) of
          $113..$122:
            begin
              d_69B8 := Integer(d_0296[(X shr 4)+1,(Y shr 4)+1].Aux) - $111;
              d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := $10C;
            end;
          $10C:
            if d_69B6 > 15 then Inc(Integer(d_0296[(X shr 4)+1,(Y shr 4)+1].Aux));
          $10D:
            if d_69B6 > 30 then Inc(Integer(d_0296[(X shr 4)+1,(Y shr 4)+1].Aux));
        end;
        if d_69B6 > 50 then
        begin
          d_69B8 := Integer(d_0296[(X shr 4)+1,(Y shr 4)+1].Tile);
          d_69B6 := 0;
          u3_0232(20);
          d_681C := d_69B8;
          u3_3cb8;
          if d_6D18.X > (X and $FFF0) + 8 then
            d_6D18.X := (d_6D18.X and $FFF0) + 16
          else
            d_6D18.X := (d_6D18.X + 8) and $FFF0;
          if d_6D18.Y > (Y and $FFF0) + 8 then
            d_6D18.Y := (d_6D18.Y and $FFF0) + 16
          else
            d_6D18.Y := (d_6D18.Y + 8) and $FFF0;
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
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
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
          if d_34EC[1].X + 5 > X then
          begin
            XX := ((X shr 4)+1) shl 4;
            YY := Y and $FFF0;
          end
          else
          begin
            XX := ((X shr 4)-1) shl 4;
            YY := Y and $FFF0;
          end;
          u9_19f9(PByteArray(d_6D86)^[$1543],XX,YY+16);
          u9_19f9(PByteArray(d_6D86)^[$1543],XX,YY+416);
          I := 1;
          repeat
            Inc(I);
          until (d_34EC[I].Inactive = 1) or (I = 25);
          d_34EC[I].State := 0;
          d_34EC[I].Sprite := $27B;
          d_34EC[I].X := XX;
          d_34EC[I].Y := YY;
          d_34EC[I].OldX := XX;
          d_34EC[I].OldY := YY;
          d_34EC[I].DX := 1;
          d_34EC[I].DY := 0;
          d_34EC[I].Frame := 1;
          d_34EC[I].Speed := 0;
          d_34EC[I].Tick := 40;
          d_34EC[I].Limit := 0;
          d_34EC[I].Kind := 22;
          d_34EC[I].Inactive := 0;
          d_34EC[I].Marked := 0;
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
            d_67FA[1] := 1;
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
             (d_0296[((X shr 4)+1)-1,(Y shr 4)+1].Solid = 1) then
          begin
            d_34EC[1].OldX := d_34EC[1].X;
            d_34EC[1].OldY := d_34EC[1].Y;
            d_34EC[1].X := (X and $FFF0) + 16;
            d_34EC[1].Y := Y and $FFF0;
            d_34EC[1].DX := -1;
            d_34EC[1].Sprite := 5;
            d_6EC1 := 0;
            d_6EC0 := 0;
            d_6ECA := 1;
            d_6ECB := 0;
          end
          else
          begin
            d_34EC[1].OldX := d_34EC[1].X;
            d_34EC[1].OldY := d_34EC[1].Y;
            d_34EC[1].X := (X and $FFF0) - 16;
            d_34EC[1].Y := Y and $FFF0;
            d_34EC[1].DX := 1;
            d_34EC[1].Sprite := 1;
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
            d_67FA[1] := 1;
            d_6814 := u3_1601(0);
            d_6EC5 := 0;
            d_6816 := 0;
            if (X shr 4 = 0) or
               (d_0296[((X shr 4)+1)-1,(Y shr 4)+1].Solid = 1) then
            begin
              d_34EC[1].OldX := d_34EC[1].X;
              d_34EC[1].OldY := d_34EC[1].Y;
              d_34EC[1].X := (X and $FFF0) + 16;
              d_34EC[1].Y := Y and $FFF0;
              d_34EC[1].Sprite := 10;
              d_6EC1 := 0;
              d_6EC0 := 0;
              d_6ECA := 0;
              d_6ECB := 0;
            end
            else
            begin
              d_34EC[1].OldX := d_34EC[1].X;
              d_34EC[1].OldY := d_34EC[1].Y;
              d_34EC[1].X := (X and $FFF0) - 16;
              d_34EC[1].Y := Y and $FFF0;
              d_34EC[1].Sprite := 9;
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
        until (d_34EC[I].Inactive = 1) or (I = 25);
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        d_34EC[I].State := 0;
        d_34EC[I].Sprite := $271;
        d_34EC[I].X := X and $FFF0;
        d_34EC[I].Y := Y and $FFF0;
        d_34EC[I].OldX := X and $FFF0;
        d_34EC[I].OldY := Y and $FFF0;
        d_34EC[I].DX := 1;
        d_34EC[I].DY := 0;
        d_34EC[I].Frame := 1;
        d_34EC[I].Speed := 0;
        d_34EC[I].Tick := 40;
        d_34EC[I].Limit := 0;
        d_34EC[I].Kind := 23;
        d_34EC[I].Inactive := 0;
        d_34EC[I].Marked := 0;
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
          d_0296[(X shr 4)+1,(Y shr 4)+1].Solid := 0;
          u7_0000(24);
          for Y := 1 to 24 do
            for X := 1 to 40 do
              if Integer(d_0296[X,Y].Aux) = $25B then
              begin
                d_0296[X,Y].Aux := 0;
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
            d_67FA[1] := 1;
            d_6814 := u3_1601(0);
            d_6EC5 := 0;
            d_6816 := 0;
          end;
      end;
    $25D:
      begin
        d_69EC := 1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(5);
        d_6832 := -1;
        u1_03f0(X and $FFF0,Y and $FFF0,19);
        d_699A := d_699A + 500;
      end;
    $B7:
      begin
        X := X and $FFF0;
        if (((d_34EC[1].X > X) and (d_34EC[1].X-X <= 2)) or
            ((d_34EC[1].X < X) and (X-d_34EC[1].X <= 2))) and
           (d_69E0 = 0) then
        begin
          d_6832 := -1;
          u7_0000(23);
          for YY := 1 to 24 do
            for XX := 1 to 40 do
              if Integer(d_0296[XX,YY].Aux) = $B7 then
                if (((X shr 4)+1) <> XX) or (((Y shr 4)+1) <> YY) then
                begin
                  d_69E4 := (XX-1) shl 4;
                  d_69E6 := (YY-1) shl 4;
                  if d_0296[d_69E4 shr 4,(d_69E6 shr 4)+1].Solid <> 0 then
                    d_69E4 := d_69E4 + 3
                  else
                    d_69E4 := d_69E4 - 3;
                  XX := 40;
                  YY := 24;
                end;
          d_69E0 := 1;
          d_69E2 := 19;
          d_69B4 := 1;
          if (d_6ECB = 1) or (d_34EC[1].Sprite = 1) then
            d_34EC[1].Sprite := 9
          else
            d_34EC[1].Sprite := 10;
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
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(5);
        d_69A4 := 4;
        d_69A6 := 216;
      end;
    $143..$145:
      begin
        d_699A := d_699A + 100;
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Special := 0;
        u7_0000(4);
      end;
    $142:
      begin
        d_699A := d_699A + 1000;
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(5);
        d_6836 := 2;
        d_69A8 := 432;
      end;
    $31:
      begin
        d_699A := d_699A + 100;
        d_6832 := -1;
        Inc(d_69A0);
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(5);
      end;
    $13A:
      begin
        d_699A := d_699A + 5000;
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(5);
        Inc(d_69A2);
        if d_69A2 > 2 then d_69A2 := 2;
        u3_9b3e('Increased Shot Power!');
      end;
    $1D2:
      begin
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(26);
        d_69AD := 1;
        d_6ECA := 0;
        d_6ECB := 0;
        d_69AA := 216;
        u3_9b3e('YOU FEEL A BIT CONFUSED!');
      end;
    $1D4:
      begin
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(27);
        d_69B0 := 1;
        d_69AE := 216;
      end;
    $269:
      begin
        d_6832 := -1;
        d_0296[(X shr 4)+1,(Y shr 4)+1].Aux := 0;
        u7_0000(5);
        Inc(d_699E);
      end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u1_86df;
begin
  u1_6d0e(d_34EC[1].X + 1, d_34EC[1].Y);
  u1_6d0e(d_34EC[1].X + 14, d_34EC[1].Y);
  u1_6d0e(d_34EC[1].X + 1, d_34EC[1].Y + 15);
  u1_6d0e(d_34EC[1].X + 14, d_34EC[1].Y + 15);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
begin
end.
