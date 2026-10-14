{ Canonical shared declarations: every proof harness includes them (tools/decls.py).
  The types and globals sections are curated by the supervisor; the routines section is generated. }
{@types}
{@globals}
var
  d_34EE: Integer;
  d_34F0: Integer;
  d_3812: array[1..299] of string[40];
  d_67FA: array[1..20] of Byte;
  d_6838: Integer;
  d_683A: Integer;
{@routines}
procedure p_0000;
procedure p_0be5;
procedure p_0e33;
procedure p_0e67;
procedure p_0ec2;
function u1_0000(Distance, Item: Integer): Boolean;
function u1_008d(margin: Integer; slot: Word): Boolean;
procedure u1_011a;
procedure u1_012d;
procedure u1_6d0e(X, Y: Integer);
procedure u1_86df;
procedure u3_007c;
procedure u3_00a3;
procedure u3_0232(Ticks: Word);
procedure u3_079e;
function u3_1601(value: Byte): Byte;
procedure u3_3c93;
procedure u3_3cb8;
procedure u3_3d6b;
procedure u3_9b3e(var input: string);
procedure u3_9bdf;
procedure u3_9de0;
procedure u3_acdd;
function u4_0000(A, B: Byte): Byte;
function u4_0045(Count: Byte; Ch: Char): string;
procedure u4_0097(X1, Y1, X2, Y2, Fore, Back: Integer);
procedure u4_0101(A, B, C, D, E, F, G: Integer);
procedure u4_0309(A, B, C, D, E, F, G: Integer);
procedure u4_0349(A, B, C: Byte; var Text: string);
procedure u4_045e;
function u4_0557: Byte;
function u4_05c3: Byte;
function u6_0000: Boolean;
function u6_0038: Boolean;
function u6_0058: Boolean;
function u6_00cc(Axis: Word): Integer;
procedure u7_0000(N: Integer);
procedure u9_01f9(A, B: Word);
procedure u9_024c(A, B: Word);
procedure u9_0352(Reg, Color: Integer);
