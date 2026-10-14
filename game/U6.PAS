unit U6;
{$A+}{$D+}{$L+}{$F-}
interface
uses U8;
function u6_0000: Boolean;
function u6_0038: Boolean;
function u6_0058: Boolean;
function u6_00cc(Axis: Word): Integer;
implementation
uses Dos, U9, Crt, U7;
{$L JOYSTICK.OBJ}
function u6_00cc; external;
{$F+}
function u6_0000: Boolean;
var
  X, Y: Integer;
begin
  X := u6_00cc(0);
  Y := u6_00cc(1);
  if (X = -1) and (Y = -1) then
    u6_0000 := False
  else
    u6_0000 := True;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
function u6_0038: Boolean;
begin
  u6_0038 := (Port[$201] and $10) = 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
function u6_0058: Boolean;
begin
  u6_0058 := (Port[$201] and $20) = 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
begin
end.
