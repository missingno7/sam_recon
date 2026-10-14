{@decls}
type
  TObject = record
    Kind, X, Y, OldX, OldY, VX, W0C, W0E, W10, W12, Sprite,
    Direction, W18, W1A, W1C: Integer;
    Hidden, Special: Byte;
  end;
  TLine = array[0..159] of Byte;
  TBuffer = array[1..200] of TLine;
  PBuffer = ^TBuffer;
  TSound = array[1..7320] of Byte;
  PSound = ^TSound;
var
  d_sam2_02BA: Byte;
  d_341C: Boolean;
  d_341E, d_3422, d_3426: PSound;
  d_342A: file of TSound;
  d_34EC: array[1..25] of TObject;
  d_681C, d_682C, d_6832: Integer;
  d_683C: Integer;
  d_683E, d_6840: Integer;
  d_6858: Integer;
  d_685A: array[1..10] of TObject;
  d_69A2: Integer;
  d_69B8: Integer;
  d_69BA: array[1..20] of Byte;
  d_69E2, d_69E4, d_69E6: Integer;
  d_6D72, d_6D76, d_6D7A, d_6D7E, d_6D82, d_6D86, d_6D8A,
  d_6D8E, d_6D92, d_6D96, d_6D9E, d_6DA2, d_6DA6, d_6DAA, d_6DAE: PBuffer;
  d_6D60, d_6D68, d_6D6A: Integer;
{@stubs}
procedure p_sam2_107a;
procedure p_08a2;
procedure p_0e67;
procedure p_0ec2;
procedure p_0ef2;
procedure p_0f75;
procedure p_516d;
procedure p_51df;
procedure p_51f3;
function u1_0000(Distance, Item: Integer): Boolean;
function u1_008d(Distance, Item: Integer): Boolean;
procedure u1_011a;
procedure u1_2f6b;
procedure u1_68f5;
procedure u1_6a0e;
procedure u1_86df;
procedure u2_0000(X,Y: Integer);
procedure u2_2530(X,Y: Integer);
procedure u2_a1ae(Level: Integer);
function u3_0000: Char;
procedure u3_007c;
procedure u3_00a3;
procedure u3_00db(Ticks: Word);
procedure u3_0232(Ticks: Word);
procedure u3_0261;
procedure u3_344c;
procedure u3_3505;
procedure u3_38ae;
procedure u3_3c93;
procedure u3_3cb8;
procedure u3_3d6b;
function u3_3f8c(Slot: Integer): Boolean;
function u3_8ea3: Word;
function u3_97bb: Char;
procedure u3_9b3e(S: string);
procedure u3_d645;
procedure u3_dbc2;
procedure u3_ddd2;
function u6_0000: Boolean;
function u6_00cc(Axis: Word): Word;
procedure u7_0000(N: Integer);
procedure u8_0136;
procedure u8_07d5;
procedure u8_0a89;
procedure u8_0c14(var Data; Count: Word);
procedure u9_01a3(N: Word);
procedure u9_01c5(N: Word);
function u9_01d3(N: Integer): Word;
procedure u9_01f9(A,B: Word);
procedure u9_024c(A,B: Word);
procedure u9_029f(N: Word);
procedure u9_02fa(N: Word);
procedure u9_0337(N: Word);
procedure u9_0475(var Data; X,Y: Integer);
procedure u9_19f9(var Data; X,Y: Integer);
procedure u9_2463(var Data; X,Y: Integer);
{@body}
begin
  if MemAvail < 200000 then
  begin
    Writeln('Secret Agent Requires 450k free Memory to run!');
    Halt;
  end;
{$IFDEF SAM1}
  if u3_0000 <> 'U' then
{$ELSE}
  p_sam2_107a;
  if (d_sam2_02BA=3) or (d_sam2_02BA=4) then
{$ENDIF}
  begin
    p_0e67;
    p_51df;
    d_34AE := 0;
    GetMem(d_341E, 7320);
{$IFDEF SAM1}
    Assign(d_342A, 'SAM101E.SND');
{$ENDIF}
{$IFDEF SAM2}
    Assign(d_342A, 'SAM201E.SND');
{$ENDIF}
{$IFDEF SAM3}
    Assign(d_342A, 'SAM301E.SND');
{$ENDIF}
    Reset(d_342A);
    Read(d_342A, d_341E^);
    u8_0c14(d_341E^, 7320);
    Close(d_342A);
    GetMem(d_3422, 7320);
{$IFDEF SAM1}
    Assign(d_342A, 'SAM102E.SND');
{$ENDIF}
{$IFDEF SAM2}
    Assign(d_342A, 'SAM202E.SND');
{$ENDIF}
{$IFDEF SAM3}
    Assign(d_342A, 'SAM302E.SND');
{$ENDIF}
    Reset(d_342A);
    Read(d_342A, d_3422^);
    u8_0c14(d_3422^, 7320);
    Close(d_342A);
    GetMem(d_3426, 7320);
{$IFDEF SAM1}
    Assign(d_342A, 'SAM103E.SND');
{$ENDIF}
{$IFDEF SAM2}
    Assign(d_342A, 'SAM203E.SND');
{$ENDIF}
{$IFDEF SAM3}
    Assign(d_342A, 'SAM303E.SND');
{$ENDIF}
    Reset(d_342A);
    Read(d_342A, d_3426^);
    u8_0c14(d_3426^, 7320);
    Close(d_342A);
    d_34AF := 1;
    u8_0136;
    u3_3cb8;
    d_380C := 0;
    d_380E := 0;
    d_3810 := 0;
    u3_00db(0);
    d_341C := u6_0000;
    d_6D70 := 0;
    if d_341C then
    begin
      d_6D68 := u6_00cc(0);
      d_6D6A := u6_00cc(1);
    end;
    p_0f75;
    Writeln('Decompressing Graphics Files...');
    u3_38ae;
    u9_01a3(0);
    u3_344c;
    while d_6EC6 = 0 do
    begin
      u9_01a3(0);
      u3_3505;
      if d_6EC6 = 0 then u8_07d5;
      if (d_6EC6 = 0) and (d_6EC7 = 0) then
      begin
        d_6822 := u9_01d3(80);
        u9_0337(4);
        u3_3c93;
        if d_70C6 = 0 then u9_01f9(0,16)
        else u9_024c(0,16);
        u8_0a89;
        if d_6D60 <> 0 then
        begin
          case d_6D60 of
            2..10: if u3_3f8c(d_6D60-1) then;
            11: if u3_3f8c(0) then;
          end;
          d_6D60 := 0;
        end;
        u2_a1ae(1);
{$IFDEF SAM1}
        if u3_0000 = 'V' then
{$ELSE}
        if d_sam2_02BA=4 then
{$ENDIF}
          u9_02fa(384)
        else u9_029f(190);
        while (d_6EC6 = 0) and (d_6EC7 = 0) do
        begin
          if d_6832 <> d_6838 then u3_0261;
          if d_682C > 7 then
          begin
            d_682C := 0;
            if d_341C then p_08a2;
            if (d_34EC[1].Sprite = 9) and (d_6ECB <> 0) then
              d_34EC[1].Sprite := 1
            else if (d_34EC[1].Sprite = 10) and (d_6ECA <> 0) then
              d_34EC[1].Sprite := 5
            else if ((d_34EC[1].Sprite = 10) or (d_34EC[1].Sprite = 9))
              and ((d_6EC4 <> 0) or (d_6EC3 <> 0)) then
              d_34EC[1].Sprite := 1;
            u3_007c;
            u2_0000(d_34EC[1].OldX-16,d_34EC[1].OldY-16);
            u2_0000(d_34EC[1].OldX-16,d_34EC[1].OldY);
            u2_0000(d_34EC[1].OldX-16,d_34EC[1].OldY+16);
            u2_0000(d_34EC[1].OldX,d_34EC[1].OldY-16);
            u2_0000(d_34EC[1].OldX,d_34EC[1].OldY);
            u2_0000(d_34EC[1].OldX,d_34EC[1].OldY+16);
            u2_0000(d_34EC[1].OldX+16,d_34EC[1].OldY-16);
            u2_0000(d_34EC[1].OldX+16,d_34EC[1].OldY);
            u2_0000(d_34EC[1].OldX+16,d_34EC[1].OldY+16);
            {1554}
            for d_6826 := 2 to 25 do
              if d_34EC[d_6826].Hidden = 0 then
                if d_34EC[d_6826].Special <> 0 then
                begin
                  d_34EC[d_6826].Hidden := 1;
                  u2_0000(d_34EC[d_6826].OldX,d_34EC[d_6826].OldY);
                  u2_0000(d_34EC[d_6826].OldX-16,d_34EC[d_6826].OldY);
                  u2_0000(d_34EC[d_6826].OldX+16,d_34EC[d_6826].OldY);
                  u2_0000(d_34EC[d_6826].OldX+32,d_34EC[d_6826].OldY);
                  u2_0000(d_34EC[d_6826].OldX-16,d_34EC[d_6826].OldY-16);
                  u2_0000(d_34EC[d_6826].OldX-16,d_34EC[d_6826].OldY+16);
                  u2_0000(d_34EC[d_6826].OldX+16,d_34EC[d_6826].OldY-16);
                  u2_0000(d_34EC[d_6826].OldX+16,d_34EC[d_6826].OldY+16);
                  u2_0000(d_34EC[d_6826].OldX,d_34EC[d_6826].OldY-16);
                  u2_0000(d_34EC[d_6826].OldX,d_34EC[d_6826].OldY+16);
                end
                else if u1_0000(40,d_6826) or (d_34EC[d_6826].W1C=28)
                  or (d_34EC[d_6826].W1C=21) or (d_34EC[d_6828].W1C=14)
                  or (d_34EC[d_6828].Special<>0) then
                begin
                  u2_0000(d_34EC[d_6826].OldX,d_34EC[d_6826].OldY);
                  if d_34EC[d_6826].OldX and 15 > 0 then
                    u2_0000(d_34EC[d_6826].OldX+16,d_34EC[d_6826].OldY);
                  case d_34EC[d_6826].Sprite of
                    851: begin
                      u2_0000(d_34EC[d_6826].OldX+48,d_34EC[d_6826].OldY);
                      u2_0000(d_34EC[d_6826].OldX+32,d_34EC[d_6826].OldY);
                      u2_0000(d_34EC[d_6826].OldX+16,d_34EC[d_6826].OldY);
                    end;
                    801..899,5001: begin
                      u2_0000(d_34EC[d_6826].OldX,d_34EC[d_6826].OldY-16);
                      if d_34EC[d_6826].OldX and 15 > 0 then
                        u2_0000(d_34EC[d_6826].OldX+15,d_34EC[d_6826].OldY-16);
                    end;
                    114: begin
                      u2_0000(d_34EC[d_6826].OldX,d_34EC[d_6826].OldY-16);
                      u2_0000(d_34EC[d_6826].OldX,d_34EC[d_6826].OldY+16);
                      if d_34EC[d_6826].OldX and 15 > 0 then
                      begin
                        u2_0000(d_34EC[d_6826].OldX+15,d_34EC[d_6826].OldY+16);
                        u2_0000(d_34EC[d_6826].OldX+15,d_34EC[d_6826].OldY-16);
                      end;
                    end;
                    101: begin
                      u2_0000(d_34EC[d_6826].OldX,d_34EC[d_6826].OldY-16);
                      if d_34EC[d_6826].OldX and 15 > 0 then
                        u2_0000(d_34EC[d_6826].OldX+15,d_34EC[d_6826].OldY-16);
                    end;
                  end;
                end;
            {1978}
            for d_6826 := 1 to d_69A2 do
            begin
              u2_0000(d_685A[d_6826].OldX,d_685A[d_6826].OldY);
              u2_0000(d_685A[d_6826].OldX+16,d_685A[d_6826].OldY);
              u2_0000(d_685A[d_6826].OldX,d_685A[d_6826].OldY+16);
              u2_0000(d_685A[d_6826].OldX+16,d_685A[d_6826].OldY+16);
            end;
            {1a21}
            if (d_69F5=0) and (d_6A3E=0) then
            begin
              u1_68f5;
              if d_681C > 1 then u1_6a0e;
              MemW[0:$41C] := MemW[0:$41A];
              u1_86df;
              d_6EC2 := 0;
            end
            else if d_69F5 <> 0 then
            begin
              d_34EC[1].OldX := d_34EC[1].X;
              d_34EC[1].OldY := d_34EC[1].Y;
              if d_34EC[1].Sprite <> 15 then d_34EC[1].Sprite := 15
              else d_34EC[1].Sprite := 16;
              if d_69F6=35 then u7_0000(22);
              Dec(d_69F6);
              if d_69F6=0 then u1_011a;
              if d_69F6>0 then
              begin
                Dec(d_34EC[1].Y,d_69F8[d_69F6]);
                if d_34EC[1].Y < 16 then d_34EC[1].Y := 16
                else if d_683A+184 < d_34EC[1].Y then
                  d_34EC[1].Y := d_683A+184;
              end;
            end
            else if d_6A3E<>0 then
            begin
              d_34EC[1].OldX := d_34EC[1].X;
              d_34EC[1].OldY := d_34EC[1].Y;
              if d_6A3F=8 then u7_0000(8);
              Dec(d_6A3F);
              if d_6A3F=0 then
              begin
                u3_0232(20);
                d_681C := 1;
                u8_0a89;
                u2_a1ae(d_681C);
                if d_6842<>0 then u3_d645;
              end
              else if d_6A3F>0 then
                if d_34EC[1].Direction=-1 then Dec(d_34EC[1].X,2)
                else Inc(d_34EC[1].X,2);
            end;
            u1_2f6b;
            {1b62}
            for d_6826 := 1 to d_69A2 do
              if d_685A[d_6826].Hidden=0 then
              begin
                if d_685A[d_6826].Special<>0 then
                begin
                  u2_0000(d_685A[d_6826].X,d_685A[d_6826].Y);
                  u2_0000(d_685A[d_6826].X+16,d_685A[d_6826].Y);
                  u2_2530(d_685A[d_6826].X,d_685A[d_6826].Y);
                  u2_2530(d_685A[d_6826].X+16,d_685A[d_6826].Y);
                  u2_0000(d_685A[d_6826].X,d_685A[d_6826].Y+16);
                  u2_0000(d_685A[d_6826].X+16,d_685A[d_6826].Y+16);
                  u2_2530(d_685A[d_6826].X,d_685A[d_6826].Y+16);
                  u2_2530(d_685A[d_6826].X+16,d_685A[d_6826].Y+16);
                  d_685A[d_6826].Hidden := 1;
                end
                else
                begin
                  if d_685A[d_6826].Sprite=626 then
                  begin
                    u9_19f9(d_6D86^[(d_685A[d_6826].W0E shr 1)+25][3],d_685A[d_6826].X,d_685A[d_6826].Y+d_6840);
                    Dec(d_685A[d_6826].W0E);
                    if d_685A[d_6826].W0E<=0 then
                    begin
                      d_685A[d_6826].Special := 1;
                  u2_0000(d_685A[d_6826].X,d_685A[d_6826].Y);
                  u2_0000(d_685A[d_6826].X-16,d_685A[d_6826].Y);
                  u2_0000(d_685A[d_6826].X+16,d_685A[d_6826].Y);
                  u2_0000(d_685A[d_6826].X,d_685A[d_6826].Y+16);
                  u2_0000(d_685A[d_6826].X-16,d_685A[d_6826].Y+16);
                  u2_0000(d_685A[d_6826].X+16,d_685A[d_6826].Y+16);
                    end;
                  end
                  else if not u1_008d(40,d_6826) then
                  begin
                  u2_0000(d_685A[d_6826].X,d_685A[d_6826].Y);
                  u2_0000(d_685A[d_6826].X+16,d_685A[d_6826].Y);
                  u2_0000(d_685A[d_6826].X,d_685A[d_6826].Y+16);
                  u2_0000(d_685A[d_6826].X+16,d_685A[d_6826].Y+16);
                    d_685A[d_6826].Special := 1;
                  end
                  else
                  begin
                  u2_0000(d_685A[d_6826].X,d_685A[d_6826].Y);
                  u2_0000(d_685A[d_6826].X+16,d_685A[d_6826].Y);
                  u2_0000(d_685A[d_6826].X,d_685A[d_6826].Y+16);
                  u2_0000(d_685A[d_6826].X+16,d_685A[d_6826].Y+16);
                    u9_0475(d_6D72^[d_685A[d_6826].Sprite-1+d_685A[d_6826].VX][3],d_685A[d_6826].X shr 3,
                  d_685A[d_6826].Y+d_6840);
                  end;
                  u2_2530(d_685A[d_6826].X,d_685A[d_6826].Y);
                  u2_2530(d_685A[d_6826].X+16,d_685A[d_6826].Y);
                  u2_2530(d_685A[d_6826].X,d_685A[d_6826].Y+16);
                  u2_2530(d_685A[d_6826].X+16,d_685A[d_6826].Y+16);
                end;
              end;
            {2014}
            if d_69E0<>0 then
            begin
              Dec(d_69E2);
              if d_69E2=0 then d_69D8 := 1
              else if d_69E2=-19 then
              begin
                d_69B4 := 0;
                d_69E0 := 0;
              end;
            end;
            if d_69D8<>0 then
            begin
              d_69D8 := 0;
              d_34EC[1].X := d_69E4;
              d_34EC[1].Y := d_69E6;
              d_6838 := d_34EC[1].X-160;
              if d_6838<0 then d_6838 := 0;
              if d_6838>320 then d_6838 := 320;
              d_683A := d_34EC[1].Y-100;
              if d_683A<0 then d_683A := 0;
              if d_683A>184 then d_683A := 184;
              if d_70C6=0 then u9_01f9(d_6838,d_683A+16)
              else u9_024c(d_6838,d_683A+16);
            end;
            d_6826 := 1;
            if (d_34EC[1].Sprite=1) or (d_34EC[1].Sprite=5) then
            begin
              Inc(d_34EC[1].VX,d_34EC[1].W1A);
              if d_34EC[1].VX>19 then d_34EC[1].VX := 1;
            end
            else d_34EC[1].VX := 1;
            if d_6A41<>0 then
            begin
              Dec(d_6A42);
              case d_6A42 of
                0: d_6A41 := 0;
                10: d_34EC[1].Kind := 5;
                20: d_34EC[1].Kind := 5;
                30: d_34EC[1].Kind := 5;
              end;
            end;
            {2139}
            if d_34EC[1].Kind>0 then
            begin
              u9_2463(d_6D7A^[d_34EC[1].VX div 5+d_34EC[1].Sprite][3],d_34EC[1].X,d_34EC[1].Y+d_6840);
              Dec(d_34EC[1].Kind);
            end
            else if d_34EC[1].X and 7 = 0 then
              u9_0475(d_6D7A^[d_34EC[1].VX div 5+d_34EC[1].Sprite][3],d_34EC[1].X shr 3,d_34EC[1].Y+d_6840)
            else
              u9_19f9(d_6D7A^[d_34EC[1].VX div 5+d_34EC[1].Sprite][3],d_34EC[1].X,d_34EC[1].Y+d_6840);
            if d_69E0<>0 then
              if d_69E2<0 then
                u9_19f9(d_6D96^[d_69E2 div 5+40][3],d_34EC[1].X,d_34EC[1].Y+d_6840)
              else
                u9_19f9(d_6D96^[40-d_69E2 div 5][3],d_34EC[1].X,d_34EC[1].Y+d_6840);
            if (d_6ECA<>0) and (d_34EC[1].Sprite=12) then
              d_34EC[1].Sprite := 5
            else if (d_6ECB<>0) and (d_34EC[1].Sprite=11) then
              d_34EC[1].Sprite := 1;
            {227e}
            for d_6826 := 2 to 25 do
              if d_34EC[d_6826].Hidden=0 then
                if d_34EC[d_6826].Special=0 then
                  if u1_0000(32,d_6826) or (d_34EC[d_6826].W1C=28)
                    or (d_34EC[d_6826].W1C=21) or (d_34EC[d_6828].W1C=14) then
                    if d_34EC[d_6826].Kind>0 then
                    begin
case d_34EC[d_6826].Sprite of
1..50: u9_2463(d_6D72^[d_34EC[d_6826].Sprite+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
101: begin
    if d_34EC[d_6826].W12=0 then
    begin
      u9_2463(d_6D76^[d_34EC[d_6826].Sprite-100+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840-16);
      if d_34EC[d_6826].Direction<0 then
        u9_2463(d_6D76^[5][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840)
      else
        u9_2463(d_6D76^[45][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
    end
    else
    begin
      if d_34EC[d_6826].Direction<0 then
        u9_2463(d_6D76^[1][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16)
      else
        u9_2463(d_6D76^[41][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16);
      u9_2463(d_6D76^[d_34EC[d_6826].Sprite-96+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
    end;
  end;
102..150: u9_2463(d_6D76^[d_34EC[d_6826].Sprite-100+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
151..200: u9_2463(d_6D96^[d_34EC[d_6826].Sprite-150+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
251..300: u9_2463(d_6DAA^[d_34EC[d_6826].Sprite-250+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
301..350: u9_2463(d_6DA2^[d_34EC[d_6826].Sprite-300+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
351..400: u9_2463(d_6DAE^[d_34EC[d_6826].Sprite-350+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
401..450: u9_2463(d_6D7E^[d_34EC[d_6826].Sprite-400+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
451..487: u9_2463(d_6D82^[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
488..490: u9_2463(d_6D82^[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].VX shr 3][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
491: u9_2463(d_6D82^[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
492..494: u9_2463(d_6D82^[d_34EC[d_6826].Sprite-450+(d_34EC[d_6826].VX-21) shr 3][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
495..500: u9_2463(d_6D82^[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
501..550: u9_2463(d_6D72^[d_34EC[d_6826].Sprite-500+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
601..650: u9_2463(d_6D86^[d_34EC[d_6826].Sprite-600+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
651..700: u9_2463(d_6D8A^[d_34EC[d_6826].Sprite-650+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
701..750: u9_2463(d_6D8E^[d_34EC[d_6826].Sprite-700+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
751..800: u9_2463(d_6D92^[d_34EC[d_6826].Sprite-750+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
801: begin
u9_2463(d_6D9E^[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16);
u9_2463(d_6D9E^[d_34EC[d_6826].Sprite-796+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
end;
817: begin
    if d_34EC[d_6826].W12=0 then
    begin
      u9_2463(d_6D9E^[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840-16);
      if d_34EC[d_6826].Direction<0 then
        u9_2463(d_6D9E^[21][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840)
      else
        u9_2463(d_6D9E^[33][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
    end
    else
    begin
      if d_34EC[d_6826].Direction<0 then
        u9_2463(d_6D9E^[17][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16)
      else
        u9_2463(d_6D9E^[29][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16);
      u9_2463(d_6D9E^[d_34EC[d_6826].Sprite-796+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
    end;
  end;
825..828: u9_2463(d_6D9E^[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
837..850: u9_2463(d_6D9E^[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
851: begin
u9_2463(d_6DA6^[d_34EC[d_6826].Sprite-850+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
u9_2463(d_6DA6^[d_34EC[d_6826].Sprite-846+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X+16,d_34EC[d_6826].Y+d_6840);
end;
end;
                      Dec(d_34EC[d_6826].Kind);
                    end
                    else if d_34EC[d_6826].X and 7 = 0 then
                    begin
case d_34EC[d_6826].Sprite of
1..50: u9_0475(d_6D72^[d_34EC[d_6826].Sprite+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
101: begin
    if d_34EC[d_6826].W12=0 then
    begin
      u9_0475(d_6D76^[d_34EC[d_6826].Sprite-100+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840-16);
      if d_34EC[d_6826].Direction<0 then
        u9_0475(d_6D76^[5][3],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840)
      else
        u9_0475(d_6D76^[45][3],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840);
    end
    else
    begin
      if d_34EC[d_6826].Direction<0 then
        u9_0475(d_6D76^[1][3],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840-16)
      else
        u9_0475(d_6D76^[41][3],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840-16);
      u9_0475(d_6D76^[d_34EC[d_6826].Sprite-96+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
    end;
  end;
102..150: u9_0475(d_6D76^[d_34EC[d_6826].Sprite-100+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
151..200: u9_0475(d_6D96^[d_34EC[d_6826].Sprite-150+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
251..300: u9_0475(d_6DAA^[d_34EC[d_6826].Sprite-250+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
301..350: u9_0475(d_6DA2^[d_34EC[d_6826].Sprite-300+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
351..400: u9_0475(d_6DAE^[d_34EC[d_6826].Sprite-350+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
401..450: u9_0475(d_6D7E^[d_34EC[d_6826].Sprite-400+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
451..487: u9_0475(d_6D82^[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
488..490: u9_0475(d_6D82^[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].VX shr 3][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
491: u9_0475(d_6D82^[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
492..494: u9_0475(d_6D82^[d_34EC[d_6826].Sprite-450+(d_34EC[d_6826].VX-21) shr 3][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
495..500: u9_0475(d_6D82^[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
501..550: u9_0475(d_6D72^[d_34EC[d_6826].Sprite-500+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
601..624: u9_0475(d_6D86^[d_34EC[d_6826].Sprite-600+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
625: u9_0475(d_6D86^[d_34EC[d_6826].Sprite-600+d_34EC[d_6826].VX div 3][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
626..650: u9_0475(d_6D86^[d_34EC[d_6826].Sprite-600+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
651..700: u9_0475(d_6D8A^[d_34EC[d_6826].Sprite-650+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
701..750: u9_0475(d_6D8E^[d_34EC[d_6826].Sprite-700+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
751..800: u9_0475(d_6D92^[d_34EC[d_6826].Sprite-750+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
801: begin
u9_0475(d_6D9E^[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840-16);
u9_0475(d_6D9E^[d_34EC[d_6826].Sprite-796+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840);
end;
817: begin
    if d_34EC[d_6826].W12=0 then
    begin
      u9_0475(d_6D9E^[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840-16);
      if d_34EC[d_6826].Direction<0 then
        u9_0475(d_6D9E^[21][3],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840)
      else
        u9_0475(d_6D9E^[33][3],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840);
    end
    else
    begin
      if d_34EC[d_6826].Direction<0 then
        u9_0475(d_6D9E^[17][3],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840-16)
      else
        u9_0475(d_6D9E^[29][3],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840-16);
      u9_0475(d_6D9E^[d_34EC[d_6826].Sprite-796+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
    end;
  end;
825..828: u9_0475(d_6D9E^[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
837..850: u9_0475(d_6D9E^[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840);
851: begin
u9_0475(d_6DA6^[d_34EC[d_6826].Sprite-850+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840);
u9_0475(d_6DA6^[d_34EC[d_6826].Sprite-846+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X shr 3+2,d_34EC[d_6826].Y+d_6840);
end;
end;
                    end
                    else
                    begin
case d_34EC[d_6826].Sprite of
1..50: u9_19f9(d_6D72^[d_34EC[d_6826].Sprite+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
101: begin
    if d_34EC[d_6826].W12=0 then
    begin
      u9_19f9(d_6D76^[d_34EC[d_6826].Sprite-100+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840-16);
      if d_34EC[d_6826].Direction<0 then
        u9_19f9(d_6D76^[5][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840)
      else
        u9_19f9(d_6D76^[45][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
    end
    else
    begin
      if d_34EC[d_6826].Direction<0 then
        u9_19f9(d_6D76^[1][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16)
      else
        u9_19f9(d_6D76^[41][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16);
      u9_19f9(d_6D76^[d_34EC[d_6826].Sprite-96+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
    end;
  end;
102..150: u9_19f9(d_6D76^[d_34EC[d_6826].Sprite-100+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
151..200: u9_19f9(d_6D96^[d_34EC[d_6826].Sprite-150+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
251..300: u9_19f9(d_6DAA^[d_34EC[d_6826].Sprite-250+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
301..350: u9_19f9(d_6DA2^[d_34EC[d_6826].Sprite-300+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
351..400: u9_19f9(d_6DAE^[d_34EC[d_6826].Sprite-350+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
401..450: u9_19f9(d_6D7E^[d_34EC[d_6826].Sprite-400+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
451..487: u9_19f9(d_6D82^[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
488..490: u9_19f9(d_6D82^[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].VX shr 3][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
491: u9_19f9(d_6D82^[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
492..494: u9_19f9(d_6D82^[d_34EC[d_6826].Sprite-450+(d_34EC[d_6826].VX-21) shr 3][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
495..500: u9_19f9(d_6D82^[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
501..550: u9_19f9(d_6D72^[d_34EC[d_6826].Sprite-500+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
601..650: u9_19f9(d_6D86^[d_34EC[d_6826].Sprite-600+d_34EC[d_6826].VX div 5][3],
      d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
651..700: u9_19f9(d_6D8A^[d_34EC[d_6826].Sprite-650+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
701..750: u9_19f9(d_6D8E^[d_34EC[d_6826].Sprite-700+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
751..800: u9_19f9(d_6D92^[d_34EC[d_6826].Sprite-750+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
801: begin
u9_19f9(d_6D9E^[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16);
u9_19f9(d_6D9E^[d_34EC[d_6826].Sprite-796+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
end;
817: begin
    if d_34EC[d_6826].W12=0 then
    begin
      u9_19f9(d_6D9E^[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840-16);
      if d_34EC[d_6826].Direction<0 then
        u9_19f9(d_6D9E^[21][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840)
      else
        u9_19f9(d_6D9E^[33][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
    end
    else
    begin
      if d_34EC[d_6826].Direction<0 then
        u9_19f9(d_6D9E^[17][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16)
      else
        u9_19f9(d_6D9E^[29][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16);
      u9_19f9(d_6D9E^[d_34EC[d_6826].Sprite-796+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
    end;
  end;
825..828: u9_19f9(d_6D9E^[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
837..850: u9_19f9(d_6D9E^[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840);
851: begin
u9_19f9(d_6DA6^[d_34EC[d_6826].Sprite-850+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
u9_19f9(d_6DA6^[d_34EC[d_6826].Sprite-846+d_34EC[d_6826].VX div 5][3],d_34EC[d_6826].X+16,d_34EC[d_6826].Y+d_6840);
end;
end;
                    end;
            {49d1}
  u2_2530(d_34EC[1].OldX-16,d_34EC[1].OldY-16);
  u2_2530(d_34EC[1].OldX-16,d_34EC[1].OldY);
  u2_2530(d_34EC[1].OldX-16,d_34EC[1].OldY+16);
  u2_2530(d_34EC[1].OldX,d_34EC[1].OldY-16);
  u2_2530(d_34EC[1].OldX,d_34EC[1].OldY);
  u2_2530(d_34EC[1].OldX,d_34EC[1].OldY+16);
  u2_2530(d_34EC[1].OldX+16,d_34EC[1].OldY-16);
  u2_2530(d_34EC[1].OldX+16,d_34EC[1].OldY);
  u2_2530(d_34EC[1].OldX+16,d_34EC[1].OldY+16);
for d_6826 := 2 to 25 do
  if d_34EC[d_6826].Hidden=0 then
    if d_34EC[d_6826].Special<>0 then
    begin
  u2_2530(d_34EC[d_6826].OldX,d_34EC[d_6826].OldY);
  u2_2530(d_34EC[d_6826].OldX-16,d_34EC[d_6826].OldY);
  u2_2530(d_34EC[d_6826].OldX+16,d_34EC[d_6826].OldY);
  u2_2530(d_34EC[d_6826].OldX-16,d_34EC[d_6826].OldY-16);
  u2_2530(d_34EC[d_6826].OldX-16,d_34EC[d_6826].OldY+16);
  u2_2530(d_34EC[d_6826].OldX+16,d_34EC[d_6826].OldY-16);
  u2_2530(d_34EC[d_6826].OldX+16,d_34EC[d_6826].OldY+16);
  u2_2530(d_34EC[d_6826].OldX,d_34EC[d_6826].OldY-16);
  u2_2530(d_34EC[d_6826].OldX,d_34EC[d_6826].OldY+16);
    end
    else if u1_0000(32,d_6826) or (d_34EC[d_6826].W1C=28) or (d_34EC[d_6826].W1C=27)
      or (d_34EC[d_6826].W1C=21) or (d_34EC[d_6828].W1C=14) then
    begin
  u2_2530(d_34EC[d_6826].X,d_34EC[d_6826].Y);
      if d_34EC[d_6826].X and 15>0 then
  u2_2530(d_34EC[d_6826].X+15,d_34EC[d_6826].Y);
      if d_34EC[d_6826].W1C=27 then
      begin
  u2_2530(d_34EC[d_6826].X,d_34EC[d_6826].Y-16);
  u2_2530(d_34EC[d_6826].X+16,d_34EC[d_6826].Y-16);
      end
      else
        case d_34EC[d_6826].Sprite of
          851: begin
  u2_2530(d_34EC[d_6826].X+48,d_34EC[d_6826].Y);
  u2_2530(d_34EC[d_6826].X+32,d_34EC[d_6826].Y);
  u2_2530(d_34EC[d_6826].X+16,d_34EC[d_6826].Y);
          end;
          801..899,5001: begin
  u2_2530(d_34EC[d_6826].X,d_34EC[d_6826].Y-16);
            if d_34EC[d_6826].X and 15>0 then
  u2_2530(d_34EC[d_6826].X+15,d_34EC[d_6826].Y-16);
          end;
          114: begin
            if d_34EC[d_6826].Y>15 then
  u2_2530(d_34EC[d_6826].X,d_34EC[d_6826].Y-16);
  u2_2530(d_34EC[d_6826].X,d_34EC[d_6826].Y+16);
            if d_34EC[d_6826].X and 15>0 then
            begin
  u2_2530(d_34EC[d_6826].X+15,d_34EC[d_6826].Y+16);
              if d_34EC[d_6826].Y>15 then
  u2_2530(d_34EC[d_6826].X+15,d_34EC[d_6826].Y-16);
            end;
          end;
          101: begin
  u2_2530(d_34EC[d_6826].X,d_34EC[d_6826].Y-16);
            if d_34EC[d_6826].X and 15>0 then
  u2_2530(d_34EC[d_6826].X+15,d_34EC[d_6826].Y-16);
          end;
        end;
    end
    else if (d_34EC[d_6826].W1C=7) or (d_34EC[d_6826].W1C=14) or (d_34EC[d_6826].W1C=19)
      or (d_34EC[d_6826].W1C=5000) then
    begin
      d_34EC[d_6826].Special := 1;
  u2_2530(d_34EC[d_6826].X,d_34EC[d_6826].Y);
      if d_34EC[d_6826].X and 15>0 then
      begin
  u2_2530(d_34EC[d_6826].X+15,d_34EC[d_6826].Y);
  u2_2530(d_34EC[d_6826].X-15,d_34EC[d_6826].Y);
      end;
    end;
if d_69F5<>0 then
  u9_19f9(d_6D7A^[d_34EC[1].VX div 5+d_34EC[1].Sprite][3],
    d_34EC[1].X,d_34EC[1].Y+d_6840);
            {4fd4}
            u3_00a3;
            if d_69AC <> 0 then
            begin
              d_69AC := 0;
              u3_9b3e('YOU FEEL LESS CONFUSED');
            end;
            if d_6816 <> 0 then
            begin
              d_6EBE := Ord(u3_97bb);
              d_6816 := 0;
            end;
            if d_6EC8 <> 0 then
            begin
              u3_0232(20);
              if d_6858 < 15 then d_6858 := 15;
              d_69BA[d_69B8] := 0;
              if d_69F5 = 0 then d_681C := 1;
              u8_0a89;
              u3_3d6b;
              u2_a1ae(d_681C);
              d_6832 := -1;
            end;
            if d_69D3 <> 0 then
            begin
              d_69D3 := 0;
              d_6826 := u3_8ea3;
              if (d_6826 >= 1) and (d_6826 <= 16) then
              begin
                d_681C := d_6826+1;
                u3_0232(20);
                d_69BA[d_69B8] := 0;
                u3_3d6b;
                u2_a1ae(d_681C);
                u8_0a89;
                d_6832 := -1;
              end;
            end;
            if d_69D7 <> 0 then
            begin
              d_69D7 := 0;
              if d_69F3 <> 0 then u3_9b3e('GOD Mode On')
              else u3_9b3e('GOD Mode Off');
            end;
          end;
        end;
      end;
      if d_6D66 <> 0 then u3_ddd2;
    end;
    u3_0232(20);
    u9_01c5(3);
    if d_34AF <> 0 then
      while d_34AE <> 0 do;
    NoSound;
    u3_dbc2;
    p_51f3;
    p_0ec2;
    p_516d;
    p_0ef2;
  end
  else
  begin
    u9_01c5(3);
{$IFDEF SAM1}
    Writeln('This game requires and EGA or VGA Adapter!');
{$ELSE}
    Writeln('This game requires an EGA or VGA Adapter!');
{$ENDIF}
    NoSound;
  end;
end.



