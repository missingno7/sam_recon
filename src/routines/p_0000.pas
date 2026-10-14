{@decls}
type
  TEntry = packed record
    SourceX: Integer;
    SourceY: Integer;
    VelocityX: Integer;
    VelocityY: Integer;
    Field8: Integer;
    Field10: Integer;
    Field12: Integer;
    Field14: Integer;
    Field16: Integer;
    Field18: Integer;
    Field20: Integer;
    Field22: Integer;
    Field24: Integer;
    Field26: Integer;
    Active: Byte;
    Flag: Byte;
    Tail: array[0..1] of Byte;
  end;
var
  d_3500: Integer;
  d_681C: Integer;
  d_6824: Integer;
  d_6832: Integer;
  d_6858: Integer;
  d_685C: array[1..10] of TEntry;
  d_69A2: Integer;
  d_70BA: Integer;
  d_70BC: Integer;
  d_70BE: Integer;
  d_70C0: Integer;
  d_70C2: Integer;
  d_70C4: Integer;
  d_70D4: Word;
{@stubs}
procedure u7_0000(value: Integer);
{@body}
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
    if d_6824 = d_70BE then
      d_6824 := d_70C0
    else if d_70BE + 128 = d_6824 then
      d_6824 := d_70C0 + 128
    else if d_6824 = d_70C0 then
      d_6824 := d_70BE
    else if d_70C0 + 128 = d_6824 then
      d_6824 := d_70BE + 128;
  end;

  if d_69B4 <> 0 then
    goto done;

  if d_6824 = d_70BE then
  begin
    d_6ECA := 1;
    d_6ECB := 0;
    d_6EC2 := 0;
    d_3500 := 5;
    if d_6EC1 <> 0 then
      d_3500 := 14;
  end
  else if d_70BE + 128 = d_6824 then
  begin
    d_6ECA := 0;
    if d_6EC1 = 0 then
    begin
      if d_6ECB = 0 then
        d_3500 := 10
      else
        d_3500 := 1;
    end
    else if d_6ECB = 1 then
      d_3500 := 13
    else
      d_3500 := 14;
  end
  else if d_6824 = d_70C0 then
  begin
    d_6ECB := 1;
    d_6ECA := 0;
    d_6EC2 := 0;
    d_3500 := 1;
    if d_6EC1 <> 0 then
      d_3500 := 13;
  end
  else if d_70C0 + 128 = d_6824 then
  begin
    d_6ECB := 0;
    if d_6EC1 = 0 then
    begin
      if d_6ECA = 0 then
        d_3500 := 9
      else
        d_3500 := 5;
    end
    else if d_6ECA = 1 then
      d_3500 := 14
    else
      d_3500 := 13;
  end
  else if d_6824 = d_70C2 then
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
            if d_685C[i].Active = 1 then
            begin
              d_685C[i].SourceX := d_34EE;
              d_685C[i].SourceY := d_34F0;
              d_685C[i].VelocityX := d_34F2;
              d_685C[i].VelocityY := d_34F4;
              d_685C[i].Field18 := 39;
              if (d_3500 = 1) or (d_3500 = 13) or (d_3500 = 9) or (d_3500 = 11) then
              begin
                d_685C[i].Field20 := 1;
                d_3500 := 11;
              end
              else
              begin
                d_685C[i].Field20 := -1;
                d_3500 := 12;
              end;
              d_685C[i].Field22 := 0;
              d_685C[i].Field8 := 1;
              d_685C[i].Field24 := 8;
              d_685C[i].Field10 := 0;
              d_685C[i].Field12 := 0;
              d_685C[i].Field26 := 7;
              d_685C[i].Active := 0;
              d_685C[i].Flag := 0;
              changed := 1;
              Dec(d_6858);
              d_6832 := -1;
              u7_0000(2);
              if (d_3500 = 1) or (d_3500 = 9) or (d_3500 = 13) or (d_3500 = 11) then
                d_3500 := 11
              else
                d_3500 := 12;
            end;
          until (i = d_69A2) or (changed <> 0);
        end;
      end;
    end;
  end  else if d_70C2 + 128 = d_6824 then
  begin
    if d_3500 = 11 then
      d_3500 := 9
    else if d_3500 = 12 then
      d_3500 := 10;
  end
  else if d_6824 = d_70C4 then
  begin
    d_6ECD := 1;
  end
  else if d_70C4 + 128 = d_6824 then
  begin
    d_6ECD := 0;
  end
  else if d_6824 = d_70BA then
  begin
    if d_681C = 1 then
    begin
      d_6EC3 := 1;
      d_6EC4 := 0;
      if (d_3500 = 1) or (d_3500 = 9) or (d_3500 = 11) then
        d_3500 := 1
      else
        d_3500 := 5;
    end;
  end
  else if d_70BA + 128 = d_6824 then
  begin
    if d_681C = 1 then
    begin
      d_6EC3 := 0;
      if (d_3500 = 1) or (d_3500 = 9) or (d_3500 = 11) then
        d_3500 := 9
      else
        d_3500 := 10;
    end;
  end
  else if d_6824 = d_70BC then
  begin
    if d_681C = 1 then
    begin
      d_6EC4 := 1;
      d_6EC3 := 0;
      if (d_3500 = 1) or (d_3500 = 9) or (d_3500 = 11) then
        d_3500 := 1
      else
        d_3500 := 5;
    end;
  end
  else if d_70BC + 128 = d_6824 then
  begin
    if d_681C = 1 then
    begin
      d_6EC4 := 0;
      if (d_3500 = 1) or (d_3500 = 9) or (d_3500 = 11) then
        d_3500 := 9
      else
        d_3500 := 10;
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
