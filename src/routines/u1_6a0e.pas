{@decls}
type
  TStepBytes = array[1..19] of Byte;
var
  d_341C: Byte;
  d_34B0: TStepBytes;
  d_3500: Word;
{@stubs}
function u1_65d9(YOffset, XOffset: Integer): Boolean;
procedure u1_66b3;
function u6_0038: Boolean;
procedure u7_0000(N: Word);
{@body}
procedure u1_6a0e;
begin
  if (d_6EC1 = 0) and (d_6EC2 = 0) then
    u1_66b3;

  if (d_69B4 = 0) and (d_6EC1 = 0) and (d_6EC0 = 0) then
    if (d_6ECD <> 0) or (u6_0038 and (d_341C <> 0)) then
    begin
      if d_0296[(((d_34EE + 3) shr 4) + 1), (((d_34F0 - 3) shr 4) + 1)].D = 0 then
      begin
        if d_0296[(((d_34EE + 12) shr 4) + 1), (((d_34F0 - 3) shr 4) + 1)].D = 0 then
        begin
          if (d_3500 = 1) or (d_3500 = 9) or (d_3500 = 11) or (d_3500 = 13) then
            d_3500 := 13
          else
            d_3500 := 14;
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
          if d_683A + 80 > d_34F0 then
          begin
            Dec(d_683A, d_34B0[d_34EA]);
            if d_683A < 0 then
              d_683A := 0;
          end;
        Dec(d_34F0, d_34B0[d_34EA]);
      end
      else
      begin
        d_34EA := 9;
        d_6EC1 := 0;
      end;
  end;
end;
