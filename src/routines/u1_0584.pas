{@decls}
type
  TEntry = record
    Field0: Integer;
    X: Integer;
    Y: Integer;
    Field6: Integer;
    Field8: Integer;
    State: Integer;
    Field12: Integer;
    Field14: Integer;
    Field16: Integer;
    EntryId: Integer;
    Value: Integer;
    Field22: Integer;
    Field24: Integer;
    Field26: Integer;
    TypeCode: Integer;
    Active: Byte;
    Used: Byte;
  end;
var
  d_34CC: array[0..64] of TEntry;
{@stubs}
procedure u7_0000(Value: Integer);
{@body}
procedure u1_0584(X, Y, TypeCode, Value, EntryId: Integer);
var
  I, Spare1, Spare2: Integer;
  Found: Boolean;
begin
  I := 0;
  Found := False;
  repeat
    Inc(I);
    if d_34CC[I].Active = 1 then
    begin
      u7_0000(3);
      d_34CC[I].Field22 := TypeCode;
      if d_34CC[I].Field22 = -1 then
        d_34CC[I].State := $15
      else
        d_34CC[I].State := 1;
      d_34CC[I].Field24 := 0;
      d_34CC[I].Field0 := 0;
      if EntryId <> $89 then
        d_34CC[I].X := X and $FFF8
      else
        d_34CC[I].X := X;
      d_34CC[I].Y := Y;
      d_34CC[I].Field6 := X;
      d_34CC[I].Field8 := Y;
      d_34CC[I].Field26 := Value;
      d_34CC[I].Field12 := 0;
      d_34CC[I].Field14 := 0;
      d_34CC[I].Active := 0;
      d_34CC[I].Used := 0;
      if EntryId = 0 then
      begin
        d_34CC[I].Value := $27;
        d_34CC[I].TypeCode := 7;
        d_34CC[I].State := 1;
      end
      else
      begin
        d_34CC[I].Value := EntryId;
        if (d_34CC[I].Value = $1D6) or
           (d_34CC[I].Value = $7D) or
           (d_34CC[I].Value = $7E) then
        begin
          d_34CC[I].TypeCode := 7;
          d_34CC[I].State := 1;
        end
        else if (d_34CC[I].Value = $339) or
                (d_34CC[I].Value = $33B) then
        begin
          d_34CC[I].TypeCode := $13;
          d_34CC[I].State := 1;
        end
        else if d_34CC[I].Value = $72 then
        begin
          d_34CC[I].TypeCode := $25;
          d_34CC[I].State := 1;
          d_34CC[I].Field24 := TypeCode;
        end
        else if d_34CC[I].Value = $C7 then
        begin
          d_34CC[I].Value := $72;
          d_34CC[I].TypeCode := $89;
          d_34CC[I].State := 1;
          d_34CC[I].Field24 := TypeCode;
        end
        else if d_34CC[I].Value = $89 then
        begin
          d_34CC[I].TypeCode := $28;
          d_34CC[I].State := 1;
          d_34CC[I].Field14 := $1E;
        end
        else
          d_34CC[I].TypeCode := $0E;
      end;
      Found := True;
    end;
  until Found or (I = 25);
end;


