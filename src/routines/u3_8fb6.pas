{@decls}
type
  TRec41 = packed record
    S: string[40];
  end;
var d_6814: Integer;
{@stubs}
procedure u3_079e;
function u3_1601(Value: Byte): Byte;
procedure u3_3e29(Value: Integer);
{@body}
procedure u3_8fb6;
begin
  u3_079e;
  d_3812[1] := 'Save Which Game?';
  d_3812[2] := '----------------';
  d_3812[3][0] := #0;
  d_3812[4] := 'Select (0-9) : ^';
  d_3812[5][0] := #0;
  d_3812[6] := 'END OF WINDOW';
  d_67FA[1] := 2;
  d_67FA[2] := 3;
  d_67FA[3] := 4;
  d_67FA[4] := 5;
  d_67FA[5] := 6;
  d_67FA[6] := 7;
  d_67FA[7] := 8;
  d_67FA[8] := 9;
  d_67FA[9] := 10;
  d_67FA[10] := 11;
  d_67FA[11] := $1C;
  d_67FA[12] := 1;
  MemW[0:$041C] := MemW[0:$041A];
  d_6814 := u3_1601(0);
  if IOResult = 0 then ;
  case d_6814 of
    2..10: u3_3e29(d_6814 - 1);
    11: u3_3e29(0);
  end;
  d_6EC5 := 0;
  d_6816 := 0;
  u3_079e;
  if IOResult = 0 then
    d_3812[1] := 'Game Saved!'
  else
    d_3812[1] := 'File Error!';
  d_3812[2] := 'END OF WINDOW';
  d_67FA[1] := $1C;
  d_67FA[2] := 1;
  MemW[0:$041C] := MemW[0:$041A];
  d_6814 := u3_1601(1);
end;
