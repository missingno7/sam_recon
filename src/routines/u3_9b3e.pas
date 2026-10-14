{@decls}
type
  TStr40 = packed record
    Value: string[40];
  end;
type
  TBuffer = packed record
    case Byte of
      0: (Wide: string[255]);
      1: (Narrow: string[40]);
  end;
{@stubs}

{@body}
procedure u3_9b3e(input: string);
begin
  u3_079e;
  d_3812[1] := TBuffer(input).Narrow;
  d_3812[2][0] := #0;
  d_3812[3] := 'Press ESCAPE';
  d_3812[4] := 'END OF WINDOW';
  d_67FA[1] := 1;
  d_6814 := u3_1601(0);
  d_6EC5 := 0;
  d_6816 := 0;
end;
