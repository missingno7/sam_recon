unit GAMEJOY;
{$A+}{$D+}{$L+}{$F-}
interface
uses SAMDATA;
function IsJoystickPresent: Boolean;
function IsJoystickButton0Pressed: Boolean;
function IsJoystickButton1Pressed: Boolean;
function ReadJoystickAxis(AxisIndex: Word): Integer;
implementation
uses Dos, PROGRPHX, Crt, SAMSOUND;
{$L JOYSTICK.OBJ}
{ Times game-port bit 1 shl Axis with interrupts disabled, returning -1 on timeout. }
function ReadJoystickAxis; external;
{$F+}
{ Reads axes 0 and 1 and reports absent only when both time out with -1. }
function IsJoystickPresent: Boolean;
var
  Axis0Time, Axis1Time: Integer;
begin
  Axis0Time := ReadJoystickAxis(0);
  Axis1Time := ReadJoystickAxis(1);
  if (Axis0Time = -1) and (Axis1Time = -1) then
    IsJoystickPresent := False
  else
    IsJoystickPresent := True;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Tests the active-low game-port bit 10h; u1_6a0e uses this button for jump. }
function IsJoystickButton0Pressed: Boolean;
begin
  IsJoystickButton0Pressed := (Port[$201] and $10) = 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Tests the active-low game-port bit 20h; p_08a2 uses this button for firing. }
function IsJoystickButton1Pressed: Boolean;
begin
  IsJoystickButton1Pressed := (Port[$201] and $20) = 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
begin
end.
