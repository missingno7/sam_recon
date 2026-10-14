{@decls}
var
  d_683C, d_6840: Word;
{@stubs}
procedure u3_00db(Ticks: Word);
procedure u3_0232(Ticks: Word);
procedure u3_3712;
procedure u3_7c17;
function u5_000f(N: Word): Integer;
function u5_0047(N: Word): Integer;
function u5_1915(P: String; A, B, C: Word): Integer;
procedure u9_01a3(N: Word);
function u9_01d3(N: Word): Integer;
{@body}
procedure u3_ddd2;
var
  I, ResultWord: Word;
begin
  u9_01a3(0);
  ResultWord := u5_000f(2);
  ResultWord := u5_0047(1);
  ResultWord := u9_01d3($28);
  d_6838 := 0;
  d_683A := 0;
  d_683C := 0;
  d_6840 := 0;
{$IFDEF SAM1}
  ResultWord := u5_1915('SAM1.END', 1, 0, 0);
{$ELSE}
{$IFDEF SAM2}
  ResultWord := u5_1915('SAM2.END', 1, 0, 0);
{$ELSE}
  ResultWord := u5_1915('SAM3A.END', 1, 0, 0);
{$ENDIF}
{$ENDIF}
  u3_00db(0);
  for I := 1 to 30 do
  begin
    Delay(50);
    MemW[0:$041C] := MemW[0:$041A];
  end;
  u3_7c17;
  MemW[0:$041C] := MemW[0:$041A];
  repeat until KeyPressed;
{$IFDEF SAM3}
  u3_0232(0);
  ResultWord := u5_1915('SAM3B.END', 1, 0, 0);
  u3_00db(0);
  MemW[0:$041C] := MemW[0:$041A];
  repeat until KeyPressed;
{$ENDIF}
  MemW[0:$041C] := MemW[0:$041A];
  u3_3712;
  d_6EC7 := 1;
  d_6D66 := 0;
  d_6EC6 := 0;
end;
