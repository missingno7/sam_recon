{ Canonical shared declarations: every proof harness includes them (tools/decls.py).
  The types and globals sections are curated by the supervisor; the routines section is generated. }
{@types}
type
  TCell = record           { one 16x16 map cell }
    A, B, C: Word;
    D, E: Byte;
  end;
{@globals}
var
  d_0296: array[1..40, 1..25] of TCell;   { level map, 40 columns x 25 rows }
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
procedure p_0ef2;
procedure p_0f75;
function u1_0000(Distance, Item: Integer): Boolean;
function u1_008d(margin: Integer; slot: Word): Boolean;
procedure u1_011a;
procedure u1_012d;
procedure u1_01c4(x, y: Integer);
function u1_027c(X, Y: Integer): Boolean;
procedure u1_03f0(param1, param2: Integer; param3: Word);
function u1_65d9(xOffset, yOffset: Word): Boolean;
procedure u1_68f5;
procedure u1_6d0e(X, Y: Integer);
procedure u1_86df;
procedure u2_0000(X, Y: Integer);
procedure u2_2530(X, Y: Integer);
procedure u3_007c;
procedure u3_00a3;
procedure u3_00db(ticks: Word);
procedure u3_0232(Ticks: Word);
procedure u3_079e;
function u3_1601(Mode: Byte): Byte;
function u3_1e2a(Length: Word): string;
procedure u3_344c;
procedure u3_3712;
procedure u3_3c93;
procedure u3_3cb8;
procedure u3_3d6b;
procedure u3_3e29(slot: Integer);
function u3_3f8c(Slot: Integer): Boolean;
procedure u3_848e;
procedure u3_87fd(Arg: Word);
function u3_8ea3: Word;
function u3_9163: Integer;
procedure u3_9a71;
procedure u3_9b3e(var input: string);
procedure u3_9bdf;
procedure u3_9ca9;
procedure u3_9de0;
procedure u3_a1d8;
procedure u3_acdd;
procedure u3_d820;
function u4_0000(A, B: Byte): Byte;
function u4_0045(Count: Byte; Ch: Char): string;
procedure u4_0097(X1, Y1, X2, Y2, Fore, Back: Integer);
procedure u4_0101(A, B, C, D, E, F, G: Integer);
procedure u4_0309(A, B, C, D, E, F, G: Integer);
procedure u4_0349(A, B, C: Byte; var Text: string);
procedure u4_0399(x: Byte; y: Integer; fg, bg: Byte; var source: String);
procedure u4_045e;
function u4_0557: Byte;
function u4_05c3: Byte;
function u5_000f(N: Word): Integer;
function u5_0047(N: Word): Integer;
function u5_1915(P: String; A, B, C: Word): Integer;
function u6_0000: Boolean;
function u6_0038: Boolean;
function u6_0058: Boolean;
function u6_00cc(Axis: Word): Integer;
procedure u7_0000(N: Integer);
procedure u8_0a89;
function u9_01d3(N: Word): Integer;
procedure u9_01f9(A, B: Word);
procedure u9_024c(A, B: Word);
procedure u9_0625(Value: Word);
procedure u9_07ee(A, B, C, D: Word);
procedure u9_19f9(var source: Byte; xoff, count: Integer);
procedure u9_2f32;
