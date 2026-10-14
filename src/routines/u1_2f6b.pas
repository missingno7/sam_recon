{@decls}

{@stubs}
procedure u9_0352(X, Y: Integer);
{@body}
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
