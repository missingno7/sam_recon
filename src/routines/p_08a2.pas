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
    Reserved14: Integer;
    Reserved16: Integer;
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
  d_34EE: Integer;
  d_34F0: Integer;
  d_34F2: Integer;
  d_34F4: Integer;
  d_3500: Integer;
  d_681C: Integer;
  d_6832: Integer;
  d_685C: array[1..10] of TEntry;
  d_6858: Integer;
  d_69A2: Integer;
  d_69F5: Byte;
  d_6D68: Integer;
  d_6D6A: Integer;
  d_6D6C: Integer;
  d_6D6E: Integer;
  d_6D70: Byte;
  d_6D71: Byte;
  d_6EBF: Byte;
  d_6EC0: Byte;
  d_6EC1: Byte;
  d_6EC2: Byte;
  d_6EC3: Byte;
  d_6EC4: Byte;
  d_6ECA: Byte;
  d_6ECB: Byte;
{@stubs}
function u6_0058: Boolean;
function u6_00cc(value: Integer): Integer;
procedure u7_0000(value: Integer);
{@body}
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
    if d_3500 = 11 then
      d_3500 := 9
    else if d_3500 = 12 then
      d_3500 := 10;
  end;
  if d_6D68 - 50 > d_6D6C then
  begin
    d_6ECA := 1;
    d_6ECB := 0;
    d_6EC2 := 0;
    d_6D70 := 1;
    if (d_6EC1 = 0) and (d_6EC0 = 0) then
      d_3500 := 5
    else
      d_3500 := 14;
  end
  else if d_6D68 + 50 < d_6D6C then
  begin
    d_6ECB := 1;
    d_6ECA := 0;
    d_6EC2 := 0;
    d_6D70 := 1;
    if (d_6EC1 = 0) and (d_6EC0 = 0) then
      d_3500 := 1
    else
      d_3500 := 13;
  end
  else if d_6D70 <> 0 then
  begin
    if (d_6ECB = 1) or (d_3500 = 1) then
      d_3500 := 9
    else
      d_3500 := 10;
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
      if (d_3500 = 1) or (d_3500 = 9) or (d_3500 = 11) then
        d_3500 := 1
      else
        d_3500 := 5;
    end
    else if d_6D6A + 50 < d_6D6E then
    begin
      d_6EC4 := 1;
      d_6D71 := 1;
      if (d_3500 = 1) or (d_3500 = 9) or (d_3500 = 11) then
        d_3500 := 1
      else
        d_3500 := 5;
    end
    else if d_6D71 <> 0 then
    begin
      d_6D71 := 0;
      d_6EC3 := 0;
      d_6EC4 := 0;
      if (d_3500 = 1) or (d_3500 = 9) or (d_3500 = 11) then
        d_3500 := 9
      else
        d_3500 := 10;
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
        d_6EBF := 1;
        d_3500 := 11;
      end
      else
      begin
        d_685C[i].Field20 := -1;
        d_6EBF := 1;
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






