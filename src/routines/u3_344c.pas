{ u3_344c: far, frame 8 bytes, parameters [0] bytes }
{@decls}
var
  d_682C: Integer;
  d_6838: Word;
  d_683A: Word;
  d_683C: Word;
  d_6840: Word;
{@stubs}
procedure u3_00db(N: Word);
procedure u3_0232(N: Word);
function u5_000f(N: Word): Integer;
function u5_0047(N: Word): Integer;
function u5_1915(P: String; A, B, C: Word): Integer;
procedure u7_0000(N: Word);
function u9_01d3(N: Word): Integer;
{@body}
procedure u3_344c;
var
  unused1, unused2, resultWord, unused4: Word;
begin
  u3_0232(0);
  resultWord := u5_000f(2);
  resultWord := u5_0047(1);
  resultWord := u9_01d3($28);
  d_6838 := 0;
  d_683A := 0;
  d_683C := 0;
  d_6840 := 0;
{$IFDEF SAM2}
  resultWord := u5_1915('sam2.apo', 1, 0, 0);
{$ELSE}
{$IFDEF SAM3}
  resultWord := u5_1915('sam3.apo', 1, 0, 0);
{$ELSE}
  resultWord := u5_1915('sam1.apo', 1, 0, 0);
{$ENDIF}
{$ENDIF}
  u3_00db($14);
  u7_0000($15);
  MemW[0:$041C] := MemW[0:$041A];
  d_682C := 0;
  repeat
  until KeyPressed or (d_682C > $02D0);
  d_682C := 0;
  u3_0232(0);
end;
