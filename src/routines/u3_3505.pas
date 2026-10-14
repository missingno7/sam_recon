{@decls}
var
  d_6824: Integer;
  d_682C: Integer;
  d_6838: Word;
  d_683A: Word;
  d_683C: Word;
  d_6840: Word;
  d_6EC3: Byte;
  d_6EC4: Byte;
  d_6EC5: Byte;
  d_6ECA: Byte;
  d_6ECB: Byte;
  d_70C6: Word;
{@stubs}
procedure u3_00db(N: Word);
procedure u3_0232(N: Word);
function u3_9340: Char;
function u5_000f(N: Word): Integer;
function u5_0047(N: Word): Integer;
function u5_1915(P: String; A, B, C: Word): Integer;
procedure u7_0000(N: Word);
procedure u9_01f9(A, B: Word);
procedure u9_024c(A, B: Word);
function u9_01d3(N: Word): Integer;
procedure u9_2ecf(A, B, C, D: Word);
{@body}
procedure u3_3505;
var
  Direction, I, ResultWord: Integer;
  Key: Char;
begin
  u3_0232(0);
  ResultWord := u5_000f(2);
  ResultWord := u5_0047(1);
  ResultWord := u9_01d3($28);
  d_6838 := 0;
  d_683A := 0;
  d_683C := 0;
  d_6840 := 0;
{$IFDEF SAM2}
  ResultWord := u5_1915('sam2.crd', 1, 0, 0);
{$ELSE}
{$IFDEF SAM3}
  ResultWord := u5_1915('sam3.crd', 1, 0, 0);
{$ELSE}
  ResultWord := u5_1915('sam1.crd', 1, 0, 0);
{$ENDIF}
{$ENDIF}
  u9_2ecf(0, 0, 0, $C8);
{$IFDEF SAM2}
  ResultWord := u5_1915('sam2.ttl', 1, 0, 0);
{$ELSE}
{$IFDEF SAM3}
  ResultWord := u5_1915('sam3.ttl', 1, 0, 0);
{$ELSE}
  ResultWord := u5_1915('sam1.ttl', 1, 0, 0);
{$ENDIF}
{$ENDIF}
  u3_00db($14);
  Direction := 1;
  I := 0;
  d_6824 := 0;
  Key := ' ';
  d_682C := 0;
  repeat
    if d_6824 > 0 then
    begin
      Key := u3_9340;
      d_6824 := 0;
    end
    else
      d_6824 := 0;
  until (d_682C > $90) or (Key <> ' ');
  if (Key <> 'B') and (Key <> 'R') and (Key <> 'Q') then
  repeat
  if (Key <> 'B') and (Key <> 'R') and (Key <> 'Q') then
    Key := ' ';
  if Direction = 1 then
  begin
    if d_70C6 = 0 then
      u9_01f9(0, I)
    else
      u9_024c(0, I);
    d_683C := I;
  end
  else
  begin
    if d_70C6 = 0 then
      u9_01f9(0, $C8 - I)
    else
      u9_024c(0, $C8 - I);
    d_683C := $C8 - I;
  end;
  Inc(I);
  if I > $C8 then
  begin
    I := 0;
    Direction := -Direction;
    d_682C := 0;
    repeat
      if d_6824 > 0 then
      begin
        Key := u3_9340;
        d_6824 := 0;
        d_682C := 0;
      end;
    until (d_682C > $1B0) or (Key <> ' ');
  end;
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  d_6EC5 := 0;
  MemW[0:$041C] := MemW[0:$041A];
  if d_6824 <> 0 then
  begin
    Key := u3_9340;
    d_682C := 0;
    d_6824 := 0;
  end;
  until (Key = 'B') or (Key = 'R') or (Key = 'Q');
  u7_0000($0C);
  u3_0232(0);
end;
