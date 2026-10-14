unit U4;
{$A+}{$D+}{$L+}{$F-}
interface
uses U8;
var
  d_21d6: word;
  d_21d8: byte;
{$IFDEF SAM1}
  reserved_21d9: Byte;
{$ELSE}
  reserved_21ff: Byte;
{$ENDIF}
  d_21da: longint;
  d_21de: byte;
  d_21df: byte;
function u4_0000(A, B: Byte): Byte;
function u4_0045(Count: Byte; Ch: Char): string;
procedure u4_0097(X1, Y1, X2, Y2, Fore, Back: Integer);
procedure u4_0101(A, B, C, D, E, F, G: Integer);
procedure u4_0309(A, B, C, D, E, F, G: Integer);
procedure u4_0349(A, B, C: Word; Text: string);
procedure u4_0399(x: Word; y: Integer; fg, bg: Word; source: String);
procedure u4_045e;
procedure u4_04bf(X, Y, Attr: Byte; Text: string);
function u4_0557: Byte;
function u4_05c3: Byte;
implementation
uses Dos, U9, Crt, U7, U6, U5;
{$L TEXTOUT.OBJ}
procedure u4_04bf; external;
function u4_0557; external;
function u4_05c3; external;
{$F+}
function u4_0000(A, B: Byte): Byte;
begin
  u4_0000 := (B shl 4) or A;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
function u4_0045(Count: Byte; Ch: Char): string;
var
  S: string;
begin
  if not (Count in [1..80]) then
    Count := 1;
  FillChar(S, Count + 1, Ch);
  S[0] := Chr(Count);
  u4_0045 := S;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u4_0097(X1, Y1, X2, Y2, Fore, Back: Integer);
var
  Y: Integer;
  Attr: Byte;
begin
  if X2 > 80 then
    X2 := 80;
  Attr := u4_0000(Fore, Back);
  for Y := Y1 to Y2 do
    u4_04bf(X1, Y, Attr, u4_0045(X2 - X1 + 1, ' '));
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u4_0101(A, B, C, D, E, F, G: Integer);
var
  Y: Integer;
  TopLeft, TopRight, BottomLeft, BottomRight, Horizontal, Vertical: Char;
  Attr: Byte;
begin
  case G of
    0:
    begin
      TopLeft := ' ';
      TopRight := ' ';
      BottomLeft := ' ';
      BottomRight := ' ';
      Horizontal := ' ';
      Vertical := ' ';
    end;
    1:
    begin
      TopLeft := #218;
      TopRight := #191;
      BottomLeft := #192;
      BottomRight := #217;
      Horizontal := #196;
      Vertical := #179;
    end;
    2:
    begin
      TopLeft := #201;
      TopRight := #187;
      BottomLeft := #200;
      BottomRight := #188;
      Horizontal := #205;
      Vertical := #186;
    end;
    3:
    begin
      TopLeft := #214;
      TopRight := #183;
      BottomLeft := #211;
      BottomRight := #189;
      Horizontal := #196;
      Vertical := #186;
    end;
    4:
    begin
      TopLeft := #213;
      TopRight := #184;
      BottomLeft := #212;
      BottomRight := #190;
      Horizontal := #205;
      Vertical := #179;
    end;
  else
    begin
      TopLeft := Chr(G);
      TopRight := Chr(G);
      BottomLeft := Chr(G);
      BottomRight := Chr(G);
      Horizontal := Chr(G);
      Vertical := Chr(G);
    end;
  end;

  Attr := u4_0000(E, F);
  u4_04bf(A, B, Attr, TopLeft);
  u4_04bf(A + 1, B, Attr, u4_0045(C - A - 1, Horizontal));
  u4_04bf(C, B, Attr, TopRight);
  for Y := B + 1 to D - 1 do
  begin
    u4_04bf(A, Y, Attr, Vertical);
    u4_04bf(C, Y, Attr, Vertical);
  end;
  u4_04bf(A, D, Attr, BottomLeft);
  u4_04bf(A + 1, D, Attr, u4_0045(C - A - 1, Horizontal));
  u4_04bf(C, D, Attr, BottomRight);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u4_0309(A, B, C, D, E, F, G: Integer);
begin
  u4_0101(A, B, C, D, E, F, G);
  u4_0097(A + 1, B + 1, C - 1, D - 1, E, F);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u4_0349(A, B, C: Word; Text: string);
begin
  u4_04bf(40 - Ord(Text[0]) div 2, Byte(A), u4_0000(Byte(B), Byte(C)), Text);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u4_0399(x: Word; y: Integer; fg, bg: Word; source: String);
var
  i: Integer;
  chText: String;
begin
  if Ord(source[0]) > Integer(26 - y) then
    Delete(source, 27 - y, 80);
  for i := 1 to Ord(source[0]) do
  begin
    chText := source[i];
    u4_04bf(Byte(x), y - 1 + i, u4_0000(Byte(fg), Byte(bg)), source[i]);
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u4_045e;
begin
  if u4_05c3 = 7 then
    d_21D6 := $B000
  else
    d_21D6 := $B800;
  d_21D8 := Ord(u4_0557 = 1);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
begin
  u4_045e;
  d_21DA := 200;
end.
