{@decls}
var
  d_6820: Word;
  d_69A4: Word;
{@stubs}
{@body}
procedure u1_012d;
begin
  Inc(d_681E);
  if d_69B0 = 0 then
  begin
    case d_681E of
      1..2: d_6820 := 1;
      3: d_6820 := 2;
      4..6: d_6820 := 4;
      7..1000: d_6820 := d_69A4 + 4;
    end;
  end
  else
  begin
    case d_681E of
      1..4: d_6820 := 1;
      5..6: d_6820 := 2;
      7..1000: d_6820 := (d_69A4 + 4) shr 1;
    end;
  end;
end;

