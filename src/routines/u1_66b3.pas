{@decls}
var
  d_34B0: array[1..58] of Byte;
  d_3500: Integer;
{@stubs}
{@body}
procedure u1_66b3;
begin
  Inc(d_34EA);
  if d_34EA > 19 then
    d_34EA := 19;
  d_6EC0 := 1;
  Inc(d_34F0, d_34B0[d_34EA]);
  if (d_0296[((d_34EE + 3) shr 4) + 1, ((d_34F0 shr 4) + 2)].D <> 0) or
     (d_0296[((d_34EE + 12) shr 4) + 1, ((d_34F0 shr 4) + 2)].D <> 0) then
  begin
    Inc(d_6818);
    d_34F0 := d_34F0 and $FFF0;
    d_6EC0 := 0;
  end;
  if d_34EA > 10 then
  begin
    if (d_0296[((d_34EE + 3) shr 4) + 1, ((d_34F0 + 16) shr 4) + 1].E <> 0) or
       (d_0296[((d_34EE + 12) shr 4) + 1, ((d_34F0 + 16) shr 4) + 1].E <> 0) then
    begin
      if d_34F0 < 5 then
      begin
        Inc(d_6818);
        d_34F0 := d_34F0 and $FFF0;
        d_6EC0 := 0;
      end
      else if (d_0296[((d_34EE + 3) shr 4) + 1, ((d_34F0 + 7) shr 4) + 1].E = 0) and
              (d_0296[((d_34EE + 12) shr 4) + 1, ((d_34F0 + 7) shr 4) + 1].E = 0) then
      begin
        Inc(d_6818);
        d_34F0 := d_34F0 and $FFF0;
        d_6EC0 := 0;
      end;
    end;
  end;
  if d_683A + 120 < d_34F0 then
  begin
    if d_683A + d_34B0[d_34EA] < 184 then
      Inc(d_683A, d_34B0[d_34EA])
    else
      d_683A := 184;
  end;
  if d_6EC0 <> 0 then
  begin
    if (d_3500 = 1) or (d_3500 = 9) or (d_3500 = 11) or (d_3500 = 13) then
      d_3500 := 13
    else
      d_3500 := 14;
  end
  else if d_3500 = 13 then
  begin
    if d_6ECB <> 0 then
      d_3500 := 1
    else
      d_3500 := 9;
  end
  else if d_3500 = 14 then
  begin
    if d_6ECA <> 0 then
      d_3500 := 5
    else
      d_3500 := 10;
  end;
end;

