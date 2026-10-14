{@decls}
var
  d_6820: Integer;
{@stubs}
procedure u1_012d;
function u1_65d9(x, y: Integer): Boolean;
{@body}
procedure u1_68f5;
begin
  d_34F2 := d_34EE;
  d_34F4 := d_34F0;

  if d_6ECB <> 0 then
  begin
    u1_012d;
    if u1_65d9(d_6820, 0) then
    begin
      if d_6838 < 320 then
      begin
        if d_6838 + 170 < d_34EE then
        begin
          Inc(d_6838, d_6820);
          if d_6838 > 320 then
            d_6838 := 320;
        end;
      end;
      Inc(d_34EE, d_6820);
    end;
  end;

  if d_6ECA <> 0 then
  begin
    u1_012d;
    if u1_65d9(-d_6820, 0) then
    begin
      if d_6838 > 0 then
      begin
        if d_6838 + 150 > d_34EE then
        begin
          Dec(d_6838, d_6820);
          if d_6838 < 0 then
            d_6838 := 0;
        end;
      end;
      Dec(d_34EE, d_6820);
    end;
  end;

  if d_6EC4 <> 0 then
  begin
    if u1_65d9(0, 4) then
    begin
      if d_683A < 184 then
      begin
        if d_683A + 80 < d_34F0 then
          Inc(d_683A, 4);
      end;
      Inc(d_34F0, 4);
    end;
  end;

  if d_6EC3 <> 0 then
  begin
    if u1_65d9(0, -4) then
    begin
      if d_683A > 0 then
      begin
        if d_683A + 80 > d_34F0 then
        begin
          Dec(d_683A, 4);
          if d_683A < 0 then
            d_683A := 0;
        end;
      end;
      Dec(d_34F0, 4);
    end;
  end;
end;

