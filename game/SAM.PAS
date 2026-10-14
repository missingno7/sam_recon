program SAM;
{$M 16384,0,655360}
{$A+}{$D+}{$L+}{$F-}
uses Dos, U9, Crt, U8, U7, U6, U5, U4, U3, U2, U1;
var
  d_0294: array[0..1] of byte;
{$IFDEF SAM1}
{$ELSE}
  d_sam2_02A4: t_p_sam2_107a_tregisterblock;
  d_sam2_02B8: Word;
  d_sam2_02BA: Byte;
  reserved_02bb: Byte;
{$ENDIF}
{$L CMOSPIT.OBJ}
{$F+}
procedure p_516d; external;
{$F-}
{$F+}
procedure p_51df; external;
{$F-}
{$F+}
procedure p_51f3; external;
{$F-}
{$F-}
procedure p_0000; interrupt;
label
  done;
var
  i: Integer;
  changed: Byte;
begin
  d_6824 := Port[$60];
  if d_69AD = 1 then
  begin
    if d_6824 = Integer(d_70BE) then
      d_6824 := Integer(d_70C0)
    else if Integer(d_70BE) + 128 = d_6824 then
      d_6824 := Integer(d_70C0) + 128
    else if d_6824 = Integer(d_70C0) then
      d_6824 := Integer(d_70BE)
    else if Integer(d_70C0) + 128 = d_6824 then
      d_6824 := Integer(d_70BE) + 128;
  end;

  if d_69B4 <> 0 then
    goto done;

  if d_6824 = Integer(d_70BE) then
  begin
    d_6ECA := 1;
    d_6ECB := 0;
    d_6EC2 := 0;
    d_34EC[1].Sprite := 5;
    if d_6EC1 <> 0 then
      d_34EC[1].Sprite := 14;
  end
  else if Integer(d_70BE) + 128 = d_6824 then
  begin
    d_6ECA := 0;
    if d_6EC1 = 0 then
    begin
      if d_6ECB = 0 then
        d_34EC[1].Sprite := 10
      else
        d_34EC[1].Sprite := 1;
    end
    else if d_6ECB = 1 then
      d_34EC[1].Sprite := 13
    else
      d_34EC[1].Sprite := 14;
  end
  else if d_6824 = Integer(d_70C0) then
  begin
    d_6ECB := 1;
    d_6ECA := 0;
    d_6EC2 := 0;
    d_34EC[1].Sprite := 1;
    if d_6EC1 <> 0 then
      d_34EC[1].Sprite := 13;
  end
  else if Integer(d_70C0) + 128 = d_6824 then
  begin
    d_6ECB := 0;
    if d_6EC1 = 0 then
    begin
      if d_6ECA = 0 then
        d_34EC[1].Sprite := 9
      else
        d_34EC[1].Sprite := 5;
    end
    else if d_6ECA = 1 then
      d_34EC[1].Sprite := 14
    else
      d_34EC[1].Sprite := 13;
  end
  else if d_6824 = Integer(d_70C2) then
  begin
    if d_6858 = 0 then
      u7_0000(20)
    else if d_6858 > 0 then
    begin
      if d_69F5 = 0 then
      begin
        if d_681C > 1 then
        begin
          changed := 0;
          i := 0;
          repeat
            Inc(i);
            if d_685A[i].Inactive = 1 then
            begin
              d_685A[i].X := d_34EC[1].X;
              d_685A[i].Y := d_34EC[1].Y;
              d_685A[i].OldX := d_34EC[1].OldX;
              d_685A[i].OldY := d_34EC[1].OldY;
              d_685A[i].Sprite := 39;
              if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 13) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) then
              begin
                d_685A[i].DX := 1;
                d_34EC[1].Sprite := 11;
              end
              else
              begin
                d_685A[i].DX := -1;
                d_34EC[1].Sprite := 12;
              end;
              d_685A[i].DY := 0;
              d_685A[i].Frame := 1;
              d_685A[i].Speed := 8;
              d_685A[i].Tick := 0;
              d_685A[i].Limit := 0;
              d_685A[i].Kind := 7;
              d_685A[i].Inactive := 0;
              d_685A[i].Marked := 0;
              changed := 1;
              Dec(d_6858);
              d_6832 := -1;
              u7_0000(2);
              if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 13) or (d_34EC[1].Sprite = 11) then
                d_34EC[1].Sprite := 11
              else
                d_34EC[1].Sprite := 12;
            end;
          until (i = d_69A2) or (changed <> 0);
        end;
      end;
    end;
  end  else if Integer(d_70C2) + 128 = d_6824 then
  begin
    if d_34EC[1].Sprite = 11 then
      d_34EC[1].Sprite := 9
    else if d_34EC[1].Sprite = 12 then
      d_34EC[1].Sprite := 10;
  end
  else if d_6824 = Integer(d_70C4) then
  begin
    d_6ECD := 1;
  end
  else if Integer(d_70C4) + 128 = d_6824 then
  begin
    d_6ECD := 0;
  end
  else if d_6824 = Integer(d_70BA) then
  begin
    if d_681C = 1 then
    begin
      d_6EC3 := 1;
      d_6EC4 := 0;
      if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) then
        d_34EC[1].Sprite := 1
      else
        d_34EC[1].Sprite := 5;
    end;
  end
  else if Integer(d_70BA) + 128 = d_6824 then
  begin
    if d_681C = 1 then
    begin
      d_6EC3 := 0;
      if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) then
        d_34EC[1].Sprite := 9
      else
        d_34EC[1].Sprite := 10;
    end;
  end
  else if d_6824 = Integer(d_70BC) then
  begin
    if d_681C = 1 then
    begin
      d_6EC4 := 1;
      d_6EC3 := 0;
      if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) then
        d_34EC[1].Sprite := 1
      else
        d_34EC[1].Sprite := 5;
    end;
  end
  else if Integer(d_70BC) + 128 = d_6824 then
  begin
    if d_681C = 1 then
    begin
      d_6EC4 := 0;
      if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) then
        d_34EC[1].Sprite := 9
      else
        d_34EC[1].Sprite := 10;
    end;
  end
  else if d_6824 = 1 then
  begin
    d_6EC5 := 1;
    d_6816 := 1;
  end
  else if d_6824 = 16 then
    d_6816 := 1
  else if d_6824 = 59 then
    d_6816 := 1
  else if d_6824 = 60 then
    d_6816 := 1
  else if d_6824 = 61 then
    d_6816 := 1
  else if d_6824 = 62 then
    d_6816 := 1
  else if d_6824 = 63 then
    d_6816 := 1
  else if d_6824 = 64 then
    d_6816 := 1
  else if d_6824 = 65 then
    d_6816 := 1
  else if d_6824 = 66 then
    d_6816 := 1
  else if d_6824 = 67 then
    d_6816 := 1
  else if d_6824 = 68 then
    d_6816 := 1
  else if d_6824 = $16 then
  begin
    d_69D9 := 1;
    if (d_69DA <> 0) and (d_69DB <> 0) and (d_69DC = 0) then
    begin
      d_6858 := d_6858 + 25;
      d_69DC := 1;
      d_6832 := -1;
    end;
  end
  else if d_6824 = $96 then
    d_69D9 := 0
  else if d_6824 = $2F then
  begin
    d_69DA := 1;
    if (d_69D9 <> 0) and (d_69DB <> 0) and (d_69DC = 0) then
    begin
      d_6858 := d_6858 + 25;
      d_69DC := 1;
      d_6832 := -1;
    end;
  end
  else if d_6824 = $AF then
    d_69DA := 0
  else if d_6824 = $25 then
  begin
    d_69DB := 1;
    if (d_69D9 <> 0) and (d_69DA <> 0) and (d_69DC = 0) then
    begin
      d_6858 := d_6858 + 25;
      d_69DC := 1;
      d_6832 := -1;
    end;
  end
  else if d_6824 = $A5 then
    d_69DB := 0
  else if d_6824 = $2C then
  begin
    d_69DD := 1;
    if (d_69DE <> 0) and (d_69DF <> 0) then
    begin
      d_69EC := 1;
      d_69F4 := 1;
      d_6832 := -1;
    end;
  end
  else if d_6824 = $AC then
    d_69DD := 0
  else if d_6824 = $22 then
  begin
    d_69DE := 1;
    if (d_69DD <> 0) and (d_69DF <> 0) then
    begin
      d_69EC := 1;
      d_69F4 := 1;
      d_6832 := -1;
    end;
  end
  else if d_6824 = $A2 then
    d_69DE := 0
  else if d_6824 = $17 then
  begin
    d_69DF := 1;
    if (d_69DE <> 0) and (d_69DD <> 0) then
    begin
      d_69EC := 1;
      d_69F4 := 1;
      d_6832 := -1;
    end;
  end
  else if d_6824 = $97 then
    d_69DF := 0
  else if d_6824 = $19 then
  begin
    d_69D4 := 1;
    if (d_69D5 <> 0) and (d_69D6 <> 0) then
    begin
      if d_69F3 = 0 then
        d_69F3 := 1
      else
        d_69F3 := 0;
      d_69D7 := 1;
    end;
    d_69D2 := 1;
    if (d_69CF <> 0) and (d_69D0 <> 0) and (d_69D1 <> 0) then
      d_69D3 := 1;
  end
  else if d_6824 = $99 then
  begin
    d_69D4 := 0;
    d_69D2 := 0;
  end
  else if d_6824 = $24 then
  begin
    d_69D5 := 1;
    if (d_69D4 <> 0) and (d_69D6 <> 0) then
    begin
      if d_69F3 = 0 then
        d_69F3 := 1
      else
        d_69F3 := 0;
      d_69D7 := 1;
    end;
  end
  else if d_6824 = $A4 then
    d_69D5 := 0
  else if d_6824 = $2D then
  begin
    d_69D6 := 1;
    if (d_69D4 <> 0) and (d_69D5 <> 0) then
    begin
      if d_69F3 = 0 then
        d_69F3 := 1
      else
        d_69F3 := 0;
      d_69D7 := 1;
    end;
  end
  else if d_6824 = $30 then
    d_69D2 := 1
  else if d_6824 = $B0 then
    d_69D2 := 0
  else if d_6824 = $AD then
    d_69D6 := 0
  else if d_6824 = $18 then
  begin
    d_69CF := 1;
    if (d_69D2 <> 0) and (d_69D0 <> 0) and (d_69D1 <> 0) then
      d_69D3 := 1;
  end
  else if d_6824 = $98 then
    d_69CF := 0
  else if d_6824 = $31 then
  begin
    d_69D0 := 1;
    if (d_69CF <> 0) and (d_69D2 <> 0) and (d_69D1 <> 0) then
      d_69D3 := 1;
  end
  else if d_6824 = $B1 then
    d_69D0 := 0
  else if d_6824 = $20 then
  begin
    d_69D1 := 1;
    if (d_69CF <> 0) and (d_69D0 <> 0) and (d_69D2 <> 0) then
      d_69D3 := 1;
  end
  else if d_6824 = $A0 then
    d_69D1 := 0;

done:
  if (d_6EC3 = 0) and (d_6EC4 = 0) and (d_6ECB = 0) and (d_6ECA = 0) then
    d_681E := 0;
  { chain to the previous INT 9 handler (d_70D2, saved by p_0e67) }
  inline($FF/$36/>d_70D2+2/     { push word ptr OldInt9+2 }
         $FF/$36/>d_70D2/       { push word ptr OldInt9 }
         $5B/$58/$87/$5E/$0E/$87/$46/$10/$89/$EC/$5D/$07/$1F/$5F/$5E/$5A/$59/$CB);
  { acknowledge the keyboard and send EOI (unreachable after the chain; the original
    has $80 where MOV AL,20h would be $B0) }
  inline($E4/$61/$8A/$E0/$0C/$80/$E6/$61/$86/$E0/$E6/$61/$80/$20/$E6/$20);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure p_08a2;
var
  i: Integer;
  changed: Byte;
begin
  d_6D6C := u6_00cc(0);
  d_6D6E := u6_00cc(1);
  if d_6EBF <> 0 then
  begin
    d_6EBF := 0;
    if d_34EC[1].Sprite = 11 then
      d_34EC[1].Sprite := 9
    else if d_34EC[1].Sprite = 12 then
      d_34EC[1].Sprite := 10;
  end;
  if d_6D68 - 50 > d_6D6C then
  begin
    d_6ECA := 1;
    d_6ECB := 0;
    d_6EC2 := 0;
    d_6D70 := 1;
    if (d_6EC1 = 0) and (d_6EC0 = 0) then
      d_34EC[1].Sprite := 5
    else
      d_34EC[1].Sprite := 14;
  end
  else if d_6D68 + 50 < d_6D6C then
  begin
    d_6ECB := 1;
    d_6ECA := 0;
    d_6EC2 := 0;
    d_6D70 := 1;
    if (d_6EC1 = 0) and (d_6EC0 = 0) then
      d_34EC[1].Sprite := 1
    else
      d_34EC[1].Sprite := 13;
  end
  else if d_6D70 <> 0 then
  begin
    if (d_6ECB = 1) or (d_34EC[1].Sprite = 1) then
      d_34EC[1].Sprite := 9
    else
      d_34EC[1].Sprite := 10;
    d_6ECB := 0;
    d_6ECA := 0;
    d_6D70 := 0;
  end;

  if d_681C = 1 then
  begin
    if d_6D6A - 50 > d_6D6E then
    begin
      d_6EC3 := 1;
      d_6D71 := 1;
      if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) then
        d_34EC[1].Sprite := 1
      else
        d_34EC[1].Sprite := 5;
    end
    else if d_6D6A + 50 < d_6D6E then
    begin
      d_6EC4 := 1;
      d_6D71 := 1;
      if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) then
        d_34EC[1].Sprite := 1
      else
        d_34EC[1].Sprite := 5;
    end
    else if d_6D71 <> 0 then
    begin
      d_6D71 := 0;
      d_6EC3 := 0;
      d_6EC4 := 0;
      if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) then
        d_34EC[1].Sprite := 9
      else
        d_34EC[1].Sprite := 10;
    end;
  end;

  if not u6_0058 then
    Exit;
  if d_6858 <= 0 then
    Exit;
  if d_681C <= 1 then
    Exit;
  if d_69F5 <> 0 then
    Exit;

  changed := 0;
  i := 0;
  repeat
    Inc(i);
    if d_685A[i].Inactive = 1 then
    begin
      d_685A[i].X := d_34EC[1].X;
      d_685A[i].Y := d_34EC[1].Y;
      d_685A[i].OldX := d_34EC[1].OldX;
      d_685A[i].OldY := d_34EC[1].OldY;
      d_685A[i].Sprite := 39;
      if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 13) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 11) then
      begin
        d_685A[i].DX := 1;
        d_6EBF := 1;
        d_34EC[1].Sprite := 11;
      end
      else
      begin
        d_685A[i].DX := -1;
        d_6EBF := 1;
        d_34EC[1].Sprite := 12;
      end;
      d_685A[i].DY := 0;
      d_685A[i].Frame := 1;
      d_685A[i].Speed := 8;
      d_685A[i].Tick := 0;
      d_685A[i].Limit := 0;
      d_685A[i].Kind := 7;
      d_685A[i].Inactive := 0;
      d_685A[i].Marked := 0;
      changed := 1;
      Dec(d_6858);
      d_6832 := -1;
      u7_0000(2);
      if (d_34EC[1].Sprite = 1) or (d_34EC[1].Sprite = 9) or (d_34EC[1].Sprite = 13) or (d_34EC[1].Sprite = 11) then
        d_34EC[1].Sprite := 11
      else
        d_34EC[1].Sprite := 12;
    end;
  until (i = d_69A2) or (changed <> 0);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F-}
procedure p_0be5; interrupt;
begin
  inline($FA);
  Inc(d_682C);
  Inc(d_0294[0]);
  if d_0294[0] = 20 then
  begin
    d_0294[0] := 0;
    if d_69A6 > 0 then
    begin
      Dec(d_69A6);
      if d_69A6 = 0 then
      begin
        d_69A4 := 0;
        d_6832 := -1;
      end;
    end;
    if d_69AE > 0 then
    begin
      Dec(d_69AE, 2);
      if d_69AE = 0 then
      begin
        d_69B0 := 0;
        d_6832 := -1;
      end;
    end;
    if d_69AA > 0 then
    begin
      Dec(d_69AA, 2);
      if d_69AA = 0 then
      begin
        d_69AC := 1;
        d_69AD := 0;
        d_6832 := -1;
      end;
    end;
  end;

  if (d_34AE <> 0) and (d_34AF <> 0) then
  begin
    case d_34AA of
      1..12:
        begin
          Sound(d_341E^[d_34AA, d_34AC]);
          Inc(d_34AC);
          if d_34AC mod d_341E^[d_34AA, 303] = 0 then
            NoSound;
          if d_341E^[d_34AA, d_34AC] = -1 then
          begin
            d_34AE := 0;
            d_34AC := 1;
            NoSound;
          end;
        end;
      13..24:
        begin
          Sound(d_3422^[d_34AA - 12, d_34AC]);
          Inc(d_34AC);
          if d_34AC mod d_3422^[d_34AA - 12, 303] = 0 then
            NoSound;
          if d_3422^[d_34AA - 12, d_34AC] = -1 then
          begin
            d_34AE := 0;
            d_34AC := 1;
            NoSound;
          end;
        end;
      25..36:
        begin
          Sound(d_3426^[d_34AA - 24, d_34AC]);
          Inc(d_34AC);
          if d_34AC mod d_3426^[d_34AA - 24, 303] = 0 then
            NoSound;
          if d_3426^[d_34AA - 24, d_34AC] = -1 then
          begin
            d_34AE := 0;
            d_34AC := 1;
            NoSound;
          end;
        end;
    end;
  end;
  inline($FB);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure p_0e33;
begin
  ExitProc := d_70CA;
  SetIntVec($1C, d_70CE);
  SetIntVec($09, d_70D2);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F-}
procedure p_0e67;
begin
  d_70CA := ExitProc;
  ExitProc := @p_0e33;
  GetIntVec($1C, d_70CE);
  SetIntVec($1C, @p_0be5);
  GetIntVec($09, d_70D2);
  SetIntVec($09, @p_0000);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F-}
procedure p_0ec2;
begin
  SetIntVec($1C, d_70CE);
  SetIntVec($09, d_70D2);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure p_0ef2;
var
  f: t_p_0ef2_tconfigfile;
begin
  d_6B44.OldMode := d_34AF;
  d_6B44.Old70BA := d_70BA;
  d_6B44.Old70BC := d_70BC;
  d_6B44.Old70BE := d_70BE;
  d_6B44.Old70C0 := d_70C0;
  d_6B44.Old70C4 := d_70C4;
  d_6B44.Old70C2 := d_70C2;
  d_6B44.Old70C6 := d_70C6;
  d_6B44.Old70C8 := d_70C8;
{$I-}
{$IFDEF SAM1}
  Assign(f, 'SAM1.CFG');
{$ENDIF}
{$IFDEF SAM2}
  Assign(f, 'SAM2.CFG');
{$ENDIF}
{$IFDEF SAM3}
  Assign(f, 'SAM3.CFG');
{$ENDIF}
  Rewrite(f);
  Write(f, d_6B44);
  Close(f);
{$I+}
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure p_0f75;
var
  f: t_p_0f75_tconfigfile;
  OK: Boolean;
begin
{$I-}
{$IFDEF SAM1}
  Assign(f, 'SAM1.CFG');
{$ENDIF}
{$IFDEF SAM2}
  Assign(f, 'SAM2.CFG');
{$ENDIF}
{$IFDEF SAM3}
  Assign(f, 'SAM3.CFG');
{$ENDIF}
  Reset(f);
  OK := IOResult = 0;
  Reset(f);
  OK := IOResult = 0;

  if OK then
  begin
    Read(f, d_6B44);
    Close(f);
    d_34AF := d_6B44.OldMode;
    d_70BA := d_6B44.Old70BA;
    d_70BC := d_6B44.Old70BC;
    d_70BE := d_6B44.Old70BE;
    d_70C0 := d_6B44.Old70C0;
    d_70C4 := d_6B44.Old70C4;
    d_70C2 := d_6B44.Old70C2;
    d_70C6 := d_6B44.Old70C6;
    d_70C8 := d_6B44.Old70C8;
    if d_70C8 = 1 then
      d_341C := u6_0000
    else
      d_341C := False;
  end
  else
  begin
    d_34AF := 1;
    d_70BA := $48;
    d_70BC := $50;
    d_70BE := $4B;
    d_70C0 := $4D;
    d_70C4 := $1D;
    d_70C2 := $38;
    d_70C6 := 0;
    d_70C8 := 0;
    d_341C := False;
  end;
{$I+}
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$IFDEF SAM1}
{$ELSE}
{$F+}
procedure p_sam2_107a;
begin
  d_sam2_02BA := 1;
  d_sam2_02A4.AH := $0F;
  Intr($10, Registers(d_sam2_02A4));
  d_sam2_02B8 := d_sam2_02A4.AL and $7F;
  d_sam2_02A4.AX := $1A00;
  Intr($10, Registers(d_sam2_02A4));
  if d_sam2_02A4.AL = $1A then
  begin
    if d_sam2_02A4.BL <> $FF then
      d_sam2_02BA := d_sam2_0000[d_sam2_02A4.BL];
  end
  else
  begin
    d_sam2_02A4.AH := $12;
    d_sam2_02A4.BL := $10;
    Intr($10, Registers(d_sam2_02A4));
    if d_sam2_02A4.BL <> $10 then
      d_sam2_02BA := 3;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$ENDIF}
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
              if d_34EC[d_6826].Inactive = 0 then
                if d_34EC[d_6826].Marked <> 0 then
                begin
                  d_34EC[d_6826].Inactive := 1;
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
                else if u1_0000(40,d_6826) or (d_34EC[d_6826].Kind=28)
                  or (d_34EC[d_6826].Kind=21) or (d_34EC[d_6828].Kind=14)
                  or (d_34EC[d_6828].Marked<>0) then
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
                if d_34EC[1].DX=-1 then Dec(d_34EC[1].X,2)
                else Inc(d_34EC[1].X,2);
            end;
            u1_2f6b;
            {1b62}
            for d_6826 := 1 to d_69A2 do
              if d_685A[d_6826].Inactive=0 then
              begin
                if d_685A[d_6826].Marked<>0 then
                begin
                  u2_0000(d_685A[d_6826].X,d_685A[d_6826].Y);
                  u2_0000(d_685A[d_6826].X+16,d_685A[d_6826].Y);
                  u2_2530(d_685A[d_6826].X,d_685A[d_6826].Y);
                  u2_2530(d_685A[d_6826].X+16,d_685A[d_6826].Y);
                  u2_0000(d_685A[d_6826].X,d_685A[d_6826].Y+16);
                  u2_0000(d_685A[d_6826].X+16,d_685A[d_6826].Y+16);
                  u2_2530(d_685A[d_6826].X,d_685A[d_6826].Y+16);
                  u2_2530(d_685A[d_6826].X+16,d_685A[d_6826].Y+16);
                  d_685A[d_6826].Inactive := 1;
                end
                else
                begin
                  if d_685A[d_6826].Sprite=626 then
                  begin
                    u9_19f9(d_6D86^.Images[(d_685A[d_6826].Limit shr 1)+25].Pixels[1],
    d_685A[d_6826].X,
    d_685A[d_6826].Y+d_6840);
                    Dec(d_685A[d_6826].Limit);
                    if d_685A[d_6826].Limit<=0 then
                    begin
                      d_685A[d_6826].Marked := 1;
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
                    d_685A[d_6826].Marked := 1;
                  end
                  else
                  begin
                  u2_0000(d_685A[d_6826].X,d_685A[d_6826].Y);
                  u2_0000(d_685A[d_6826].X+16,d_685A[d_6826].Y);
                  u2_0000(d_685A[d_6826].X,d_685A[d_6826].Y+16);
                  u2_0000(d_685A[d_6826].X+16,d_685A[d_6826].Y+16);
                    u9_0475(d_6D72^.Images[d_685A[d_6826].Sprite-1+d_685A[d_6826].Frame].Pixels[1],
    d_685A[d_6826].X shr 3,
    
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
              Inc(d_34EC[1].Frame,d_34EC[1].Speed);
              if d_34EC[1].Frame>19 then d_34EC[1].Frame := 1;
            end
            else d_34EC[1].Frame := 1;
            if d_6A41<>0 then
            begin
              Dec(d_6A42);
              case d_6A42 of
                0: d_6A41 := 0;
                10: d_34EC[1].State := 5;
                20: d_34EC[1].State := 5;
                30: d_34EC[1].State := 5;
              end;
            end;
            {2139}
            if d_34EC[1].State>0 then
            begin
              u9_2463(d_6D7A^.Images[d_34EC[1].Frame div 5+d_34EC[1].Sprite].Pixels[1],
    d_34EC[1].X,
    d_34EC[1].Y+d_6840);
              Dec(d_34EC[1].State);
            end
            else if d_34EC[1].X and 7 = 0 then
              u9_0475(d_6D7A^.Images[d_34EC[1].Frame div 5+d_34EC[1].Sprite].Pixels[1],
    d_34EC[1].X shr 3,
    d_34EC[1].Y+d_6840)
            else
              u9_19f9(d_6D7A^.Images[d_34EC[1].Frame div 5+d_34EC[1].Sprite].Pixels[1],
    d_34EC[1].X,
    d_34EC[1].Y+d_6840);
            if d_69E0<>0 then
              if d_69E2<0 then
                u9_19f9(d_6D96^.Images[d_69E2 div 5+40].Pixels[1],d_34EC[1].X,d_34EC[1].Y+d_6840)
              else
                u9_19f9(d_6D96^.Images[40-d_69E2 div 5].Pixels[1],d_34EC[1].X,d_34EC[1].Y+d_6840);
            if (d_6ECA<>0) and (d_34EC[1].Sprite=12) then
              d_34EC[1].Sprite := 5
            else if (d_6ECB<>0) and (d_34EC[1].Sprite=11) then
              d_34EC[1].Sprite := 1;
            {227e}
            for d_6826 := 2 to 25 do
              if d_34EC[d_6826].Inactive=0 then
                if d_34EC[d_6826].Marked=0 then
                  if u1_0000(32,d_6826) or (d_34EC[d_6826].Kind=28)
                    or (d_34EC[d_6826].Kind=21) or (d_34EC[d_6828].Kind=14) then
                    if d_34EC[d_6826].State>0 then
                    begin
case d_34EC[d_6826].Sprite of
1..50: u9_2463(d_6D72^.Images[d_34EC[d_6826].Sprite+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    d_34EC[d_6826].Y+d_6840);
101: begin
    if d_34EC[d_6826].Aux2=0 then
    begin
      u9_2463(d_6D76^.Images[d_34EC[d_6826].Sprite-100+d_34EC[d_6826].Frame div 5].Pixels[1],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840-16);
      if d_34EC[d_6826].DX<0 then
        u9_2463(d_6D76^.Images[5].Pixels[1],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840)
      else
        u9_2463(d_6D76^.Images[45].Pixels[1],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
    end
    else
    begin
      if d_34EC[d_6826].DX<0 then
        u9_2463(d_6D76^.Images[1].Pixels[1],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16)
      else
        u9_2463(d_6D76^.Images[41].Pixels[1],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16);
      u9_2463(d_6D76^.Images[d_34EC[d_6826].Sprite-96+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    d_34EC[d_6826].Y+d_6840);
    end;
  end;
102..150: u9_2463(d_6D76^.Images[d_34EC[d_6826].Sprite-100+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
151..200: u9_2463(d_6D96^.Images[d_34EC[d_6826].Sprite-150+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
251..300: u9_2463(d_6DAA^.Images[d_34EC[d_6826].Sprite-250+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
301..350: u9_2463(d_6DA2^.Images[d_34EC[d_6826].Sprite-300+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
351..400: u9_2463(d_6DAE^.Images[d_34EC[d_6826].Sprite-350+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
401..450: u9_2463(d_6D7E^.Images[d_34EC[d_6826].Sprite-400+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
451..487: u9_2463(d_6D82^.Images[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
488..490: u9_2463(d_6D82^.Images[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].Frame shr 3].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
491: u9_2463(d_6D82^.Images[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    d_34EC[d_6826].Y+d_6840);
492..494: u9_2463(d_6D82^.Images[d_34EC[d_6826].Sprite-450+(d_34EC[d_6826].Frame-21) shr 3].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
495..500: u9_2463(d_6D82^.Images[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
501..550: u9_2463(d_6D72^.Images[d_34EC[d_6826].Sprite-500+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
601..650: u9_2463(d_6D86^.Images[d_34EC[d_6826].Sprite-600+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
651..700: u9_2463(d_6D8A^.Images[d_34EC[d_6826].Sprite-650+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
701..750: u9_2463(d_6D8E^.Images[d_34EC[d_6826].Sprite-700+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
751..800: u9_2463(d_6D92^.Images[d_34EC[d_6826].Sprite-750+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
801: begin
u9_2463(d_6D9E^.Images[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    d_34EC[d_6826].Y+d_6840-16);
u9_2463(d_6D9E^.Images[d_34EC[d_6826].Sprite-796+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    d_34EC[d_6826].Y+d_6840);
end;
817: begin
    if d_34EC[d_6826].Aux2=0 then
    begin
      u9_2463(d_6D9E^.Images[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].Frame div 5].Pixels[1],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840-16);
      if d_34EC[d_6826].DX<0 then
        u9_2463(d_6D9E^.Images[21].Pixels[1],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840)
      else
        u9_2463(d_6D9E^.Images[33].Pixels[1],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
    end
    else
    begin
      if d_34EC[d_6826].DX<0 then
        u9_2463(d_6D9E^.Images[17].Pixels[1],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16)
      else
        u9_2463(d_6D9E^.Images[29].Pixels[1],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16);
      u9_2463(d_6D9E^.Images[d_34EC[d_6826].Sprite-796+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    d_34EC[d_6826].Y+d_6840);
    end;
  end;
825..828: u9_2463(d_6D9E^.Images[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
837..850: u9_2463(d_6D9E^.Images[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
851: begin
u9_2463(d_6DA6^.Images[d_34EC[d_6826].Sprite-850+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    d_34EC[d_6826].Y+d_6840);
u9_2463(d_6DA6^.Images[d_34EC[d_6826].Sprite-846+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X+16,
    d_34EC[d_6826].Y+d_6840);
end;
end;
                      Dec(d_34EC[d_6826].State);
                    end
                    else if d_34EC[d_6826].X and 7 = 0 then
                    begin
case d_34EC[d_6826].Sprite of
1..50: u9_0475(d_6D72^.Images[d_34EC[d_6826].Sprite+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
101: begin
    if d_34EC[d_6826].Aux2=0 then
    begin
      u9_0475(d_6D76^.Images[d_34EC[d_6826].Sprite-100+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840-16);
      if d_34EC[d_6826].DX<0 then
        u9_0475(d_6D76^.Images[5].Pixels[1],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840)
      else
        u9_0475(d_6D76^.Images[45].Pixels[1],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840);
    end
    else
    begin
      if d_34EC[d_6826].DX<0 then
        u9_0475(d_6D76^.Images[1].Pixels[1],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840-16)
      else
        u9_0475(d_6D76^.Images[41].Pixels[1],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840-16);
      u9_0475(d_6D76^.Images[d_34EC[d_6826].Sprite-96+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
    end;
  end;
102..150: u9_0475(d_6D76^.Images[d_34EC[d_6826].Sprite-100+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
151..200: u9_0475(d_6D96^.Images[d_34EC[d_6826].Sprite-150+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
251..300: u9_0475(d_6DAA^.Images[d_34EC[d_6826].Sprite-250+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
301..350: u9_0475(d_6DA2^.Images[d_34EC[d_6826].Sprite-300+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
351..400: u9_0475(d_6DAE^.Images[d_34EC[d_6826].Sprite-350+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
401..450: u9_0475(d_6D7E^.Images[d_34EC[d_6826].Sprite-400+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
451..487: u9_0475(d_6D82^.Images[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
488..490: u9_0475(d_6D82^.Images[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].Frame shr 3].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
491: u9_0475(d_6D82^.Images[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
492..494: u9_0475(d_6D82^.Images[d_34EC[d_6826].Sprite-450+(d_34EC[d_6826].Frame-21) shr 3].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
495..500: u9_0475(d_6D82^.Images[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
501..550: u9_0475(d_6D72^.Images[d_34EC[d_6826].Sprite-500+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
601..624: u9_0475(d_6D86^.Images[d_34EC[d_6826].Sprite-600+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
625: u9_0475(d_6D86^.Images[d_34EC[d_6826].Sprite-600+d_34EC[d_6826].Frame div 3].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
626..650: u9_0475(d_6D86^.Images[d_34EC[d_6826].Sprite-600+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
651..700: u9_0475(d_6D8A^.Images[d_34EC[d_6826].Sprite-650+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
701..750: u9_0475(d_6D8E^.Images[d_34EC[d_6826].Sprite-700+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
751..800: u9_0475(d_6D92^.Images[d_34EC[d_6826].Sprite-750+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
801: begin
u9_0475(d_6D9E^.Images[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].Frame div 5].Pixels[1],d_34EC[d_6826].X shr 3,
      d_34EC[d_6826].Y+d_6840-16);
u9_0475(d_6D9E^.Images[d_34EC[d_6826].Sprite-796+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    d_34EC[d_6826].Y+d_6840);
end;
817: begin
    if d_34EC[d_6826].Aux2=0 then
    begin
      u9_0475(d_6D9E^.Images[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840-16);
      if d_34EC[d_6826].DX<0 then
        u9_0475(d_6D9E^.Images[21].Pixels[1],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840)
      else
        u9_0475(d_6D9E^.Images[33].Pixels[1],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840);
    end
    else
    begin
      if d_34EC[d_6826].DX<0 then
        u9_0475(d_6D9E^.Images[17].Pixels[1],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840-16)
      else
        u9_0475(d_6D9E^.Images[29].Pixels[1],d_34EC[d_6826].X shr 3,d_34EC[d_6826].Y+d_6840-16);
      u9_0475(d_6D9E^.Images[d_34EC[d_6826].Sprite-796+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
    end;
  end;
825..828: u9_0475(d_6D9E^.Images[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
837..850: u9_0475(d_6D9E^.Images[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    
      d_34EC[d_6826].Y+d_6840);
851: begin
u9_0475(d_6DA6^.Images[d_34EC[d_6826].Sprite-850+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3,
    d_34EC[d_6826].Y+d_6840);
u9_0475(d_6DA6^.Images[d_34EC[d_6826].Sprite-846+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X shr 3+2,
    d_34EC[d_6826].Y+d_6840);
end;
end;
                    end
                    else
                    begin
case d_34EC[d_6826].Sprite of
1..50: u9_19f9(d_6D72^.Images[d_34EC[d_6826].Sprite+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    d_34EC[d_6826].Y+d_6840);
101: begin
    if d_34EC[d_6826].Aux2=0 then
    begin
      u9_19f9(d_6D76^.Images[d_34EC[d_6826].Sprite-100+d_34EC[d_6826].Frame div 5].Pixels[1],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840-16);
      if d_34EC[d_6826].DX<0 then
        u9_19f9(d_6D76^.Images[5].Pixels[1],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840)
      else
        u9_19f9(d_6D76^.Images[45].Pixels[1],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
    end
    else
    begin
      if d_34EC[d_6826].DX<0 then
        u9_19f9(d_6D76^.Images[1].Pixels[1],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16)
      else
        u9_19f9(d_6D76^.Images[41].Pixels[1],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16);
      u9_19f9(d_6D76^.Images[d_34EC[d_6826].Sprite-96+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    d_34EC[d_6826].Y+d_6840);
    end;
  end;
102..150: u9_19f9(d_6D76^.Images[d_34EC[d_6826].Sprite-100+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
151..200: u9_19f9(d_6D96^.Images[d_34EC[d_6826].Sprite-150+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
251..300: u9_19f9(d_6DAA^.Images[d_34EC[d_6826].Sprite-250+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
301..350: u9_19f9(d_6DA2^.Images[d_34EC[d_6826].Sprite-300+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
351..400: u9_19f9(d_6DAE^.Images[d_34EC[d_6826].Sprite-350+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
401..450: u9_19f9(d_6D7E^.Images[d_34EC[d_6826].Sprite-400+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
451..487: u9_19f9(d_6D82^.Images[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
488..490: u9_19f9(d_6D82^.Images[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].Frame shr 3].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
491: u9_19f9(d_6D82^.Images[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    d_34EC[d_6826].Y+d_6840);
492..494: u9_19f9(d_6D82^.Images[d_34EC[d_6826].Sprite-450+(d_34EC[d_6826].Frame-21) shr 3].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
495..500: u9_19f9(d_6D82^.Images[d_34EC[d_6826].Sprite-450+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
501..550: u9_19f9(d_6D72^.Images[d_34EC[d_6826].Sprite-500+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
601..650: u9_19f9(d_6D86^.Images[d_34EC[d_6826].Sprite-600+d_34EC[d_6826].Frame div 5].Pixels[1],
      d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
651..700: u9_19f9(d_6D8A^.Images[d_34EC[d_6826].Sprite-650+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
701..750: u9_19f9(d_6D8E^.Images[d_34EC[d_6826].Sprite-700+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
751..800: u9_19f9(d_6D92^.Images[d_34EC[d_6826].Sprite-750+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
801: begin
u9_19f9(d_6D9E^.Images[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    d_34EC[d_6826].Y+d_6840-16);
u9_19f9(d_6D9E^.Images[d_34EC[d_6826].Sprite-796+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    d_34EC[d_6826].Y+d_6840);
end;
817: begin
    if d_34EC[d_6826].Aux2=0 then
    begin
      u9_19f9(d_6D9E^.Images[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].Frame div 5].Pixels[1],d_34EC[d_6826].X,
      d_34EC[d_6826].Y+d_6840-16);
      if d_34EC[d_6826].DX<0 then
        u9_19f9(d_6D9E^.Images[21].Pixels[1],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840)
      else
        u9_19f9(d_6D9E^.Images[33].Pixels[1],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840);
    end
    else
    begin
      if d_34EC[d_6826].DX<0 then
        u9_19f9(d_6D9E^.Images[17].Pixels[1],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16)
      else
        u9_19f9(d_6D9E^.Images[29].Pixels[1],d_34EC[d_6826].X,d_34EC[d_6826].Y+d_6840-16);
      u9_19f9(d_6D9E^.Images[d_34EC[d_6826].Sprite-796+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    d_34EC[d_6826].Y+d_6840);
    end;
  end;
825..828: u9_19f9(d_6D9E^.Images[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
837..850: u9_19f9(d_6D9E^.Images[d_34EC[d_6826].Sprite-800+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    
      d_34EC[d_6826].Y+d_6840);
851: begin
u9_19f9(d_6DA6^.Images[d_34EC[d_6826].Sprite-850+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X,
    d_34EC[d_6826].Y+d_6840);
u9_19f9(d_6DA6^.Images[d_34EC[d_6826].Sprite-846+d_34EC[d_6826].Frame div 5].Pixels[1],
    d_34EC[d_6826].X+16,
    d_34EC[d_6826].Y+d_6840);
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
  if d_34EC[d_6826].Inactive=0 then
    if d_34EC[d_6826].Marked<>0 then
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
    else if u1_0000(32,d_6826) or (d_34EC[d_6826].Kind=28) or (d_34EC[d_6826].Kind=27)
      or (d_34EC[d_6826].Kind=21) or (d_34EC[d_6828].Kind=14) then
    begin
  u2_2530(d_34EC[d_6826].X,d_34EC[d_6826].Y);
      if d_34EC[d_6826].X and 15>0 then
  u2_2530(d_34EC[d_6826].X+15,d_34EC[d_6826].Y);
      if d_34EC[d_6826].Kind=27 then
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
    else if (d_34EC[d_6826].Kind=7) or (d_34EC[d_6826].Kind=14) or (d_34EC[d_6826].Kind=19)
      or (d_34EC[d_6826].Kind=5000) then
    begin
      d_34EC[d_6826].Marked := 1;
  u2_2530(d_34EC[d_6826].X,d_34EC[d_6826].Y);
      if d_34EC[d_6826].X and 15>0 then
      begin
  u2_2530(d_34EC[d_6826].X+15,d_34EC[d_6826].Y);
  u2_2530(d_34EC[d_6826].X-15,d_34EC[d_6826].Y);
      end;
    end;
if d_69F5<>0 then
  u9_19f9(d_6D7A^.Images[d_34EC[1].Frame div 5+d_34EC[1].Sprite].Pixels[1],
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
