{@decls}
type
  TRec41 = packed record
    S: string[40];
  end;
var d_3812: array[1..299] of TRec41;
var d_67FA: Byte;
var d_67FB: Byte;
var d_67FC: Byte;
var d_67FD: Byte;
var d_67FE: Byte;
var d_67FF: Byte;
var d_6800: Byte;
var d_6801: Byte;
var d_6802: Byte;
var d_6803: Byte;
var d_6804: Byte;
var d_6805: Byte;
var d_6814: Integer;
var d_6816: Byte;
var d_6EC5: Byte;
{@stubs}
procedure u3_079e;
function u3_1601(value: Byte): Byte;
function u3_3f8c(value: Integer): Byte;
{@body}
function u3_9163: Integer;
begin
  u3_079e;
  d_3812[1].S := 'Restore Which Game?';
  d_3812[2].S := '-------------------';
  d_3812[3].S[0] := #0;
  d_3812[4].S := 'Select (0-9) : ^';
  d_3812[5].S[0] := #0;
  d_3812[6].S := 'END OF WINDOW';
  d_67FA := 2;
  d_67FB := 3;
  d_67FC := 4;
  d_67FD := 5;
  d_67FE := 6;
  d_67FF := 7;
  d_6800 := 8;
  d_6801 := 9;
  d_6802 := 10;
  d_6803 := 11;
  d_6804 := $1C;
  d_6805 := 1;
  MemW[0:$041C] := MemW[0:$041A];
  d_6814 := u3_1601(0);
  case d_6814 of
    2..10:
      if u3_3f8c(d_6814 - 1) = 0 then
        d_6814 := $1C;
    11:
      if u3_3f8c(0) = 0 then
        d_6814 := $1C;
  end;
  u3_9163 := d_6814;
  d_6EC5 := 0;
  d_6816 := 0;
end;

