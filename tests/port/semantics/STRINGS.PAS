program Strings;
{$S-}{$R-}{$I-}{$B-}
var a: String[5]; b: String; c: String[12]; i: Integer; l: LongInt; w: Word;
begin
  a := 'abcdefgh'; Writeln(a,' ',Length(a));
  b := a + 'XYZ'; Writeln(b,' ',a < b,' ',a = 'abcde');
  Writeln(Copy(b,0,4),'|',Copy(b,1,0),'|',Copy(b,7,99));
  Writeln(Pos('',b),' ',Pos('deX',b),' ',Pos('abc',b));
  a := 'abcde'; Insert('XY',a,3); Writeln(a);
  a := 'abcde'; Insert('XY',a,0); Writeln(a);
  a := 'abcde'; Insert('XY',a,20); Writeln(a);
  b := 'abcdef'; Delete(b,0,3); Writeln(b);
  Delete(b,2,3); Writeln(b);
  Str(-32768:10,c); Writeln('[',c,']');
  Str(123:2,c); Writeln('[',c,']');
  b := '123'; Val(b,l,i); Writeln(l,' ',i);
  b := '  -12'; Val(b,l,i); Writeln(l,' ',i);
  b := '$FFFF'; Val(b,l,i); Writeln(l,' ',i);
  b := '12x'; Val(b,l,i); Writeln(l,' ',i);
  b := ''; Val(b,l,i); Writeln(l,' ',i);
  b := '65536'; Val(b,w,i); Writeln(w,' ',i);
end.
