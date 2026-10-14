unit U9;
{$A+}{$D+}{$L+}{$F-}
interface
uses Dos;
var
{$IFDEF SAM1}
  reserved_70ee: array[0..81] of Byte;
{$ELSE}
  reserved_7114: array[0..81] of Byte;
{$ENDIF}
  d_7140: string[80];
{$IFDEF SAM1}
  reserved_7191: Byte;
{$ELSE}
  reserved_71b7: Byte;
{$ENDIF}
procedure u9_01a3(N: Word);
procedure u9_01c5(N: Word);
function u9_01d3(N: Word): Integer;
procedure u9_01f9(A, B: Word);
procedure u9_024c(A, B: Word);
procedure u9_029f(N: Word);
procedure u9_02db;
procedure u9_02fa(N: Word);
procedure u9_0337(N: Word);
procedure u9_0352(X, Y: Integer);
procedure u9_0475(var Data; X,Y: Integer);
procedure u9_051f(var Data; X, Y: Integer);
procedure u9_0625(Value: Word);
procedure u9_07ee(A, B, C, D: Word);
procedure u9_1795(var Data; X1, Y1, X2, Y2: Integer);
procedure u9_1831(var Data; X, Y: Integer);
procedure u9_19f9(var Source; X, Y: Integer);
procedure u9_1b27(var source: Byte; x, y: Word);
procedure u9_2463(var Data; X,Y: Integer);
procedure u9_27e2;
procedure u9_2981(Mode: Word);
procedure u9_2a9f(var Source; X, Y: Integer);
procedure u9_2b38(var Data; X, Y: Integer);
procedure u9_2e6d(X, Y, Color: Integer);
procedure u9_2ecf(A, B, C, D: Word);
procedure u9_2f32;
implementation
{$L PROGRAPX.OBJ}
procedure u9_01a3; external;
procedure u9_01c5; external;
function u9_01d3; external;
procedure u9_01f9; external;
procedure u9_024c; external;
procedure u9_029f; external;
procedure u9_02db; external;
procedure u9_02fa; external;
procedure u9_0337; external;
procedure u9_0352; external;
procedure u9_0475; external;
procedure u9_051f; external;
procedure u9_0625; external;
procedure u9_07ee; external;
procedure u9_1795; external;
procedure u9_1831; external;
procedure u9_19f9; external;
procedure u9_1b27; external;
procedure u9_2463; external;
procedure u9_27e2; external;
procedure u9_2981; external;
procedure u9_2a9f; external;
procedure u9_2b38; external;
procedure u9_2e6d; external;
procedure u9_2ecf; external;
procedure u9_2f32; external;
begin
  u9_01a3(1);
  u9_27e2;
  u9_2981(0);
  u9_01c5($10);
  u9_0625($0F);
  d_7140 := 'Copyright 1991 Peder Jungck';
  d_7140 := '1019 W Lovers Lane         ';
  d_7140 := 'Arlington, Texas  76013    ';
  d_7140 := '(817) 795-8903             ';
end.
