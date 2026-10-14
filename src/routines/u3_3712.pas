{@decls}
type
  PByte = ^Byte;
  TFarPtr = record
    case Byte of
      0: (p: PByte);
      1: (ofs: Word; seg: Integer);
      2: (value: LongInt);
  end;
var
  d_699A: TFarPtr;
  d_6A44: String[255];
  d_6B44: array[1..10] of String[40];
  d_6CDE: array[1..10] of TFarPtr;
{@stubs}
procedure u3_848e;
procedure u3_9a71;
{@body}
procedure u3_3712;
var
  i: Integer;
  j: Integer;
  s: String[255];
begin
  if d_699A.value > d_6CDE[10].value then
  begin
    u3_848e;
    for i := 10 downto 1 do
      if d_6CDE[i].value < d_699A.value then
        j := i;
    if j < 10 then
      for i := 10 downto j + 1 do
      begin
        d_6CDE[i] := d_6CDE[i - 1];
        d_6B44[i] := d_6B44[i - 1];
      end;
    for i := Ord(d_6A44[0]) to 22 do
      d_6A44 := d_6A44 + ' ';
    Str(d_699A.value:7, s);
    d_6A44 := d_6A44 + s;
    d_6CDE[j] := d_699A;
    d_6B44[j] := d_6A44;
    u3_9a71;
  end;
end;











