{ Joystick unit: tests game-port buttons and joystick presence, and exposes
  the assembly axis-timing routine used by player controls. }
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
const
  { Game-port axes, active-low button bits and the assembly timeout result. }
  JoystickGamePort = $201;
  JoystickXAxisIndex = 0;
  JoystickYAxisIndex = 1;
  JoystickAxisTimeout = -1;
  JoystickButton0Mask = $10;
  JoystickButton1Mask = $20;

{ Assembly axis measurement. }
{$L JOYSTICK.OBJ}
{ Times game-port bit 1 shl Axis with interrupts disabled, returning -1 on timeout. }
function ReadJoystickAxis; external;

{ Presence detection and button input. }
{$F+}
{ Reports absent only when both axes time out; a single responding axis is enough. }
function IsJoystickPresent: Boolean;
var
  JoystickPresenceXTime, JoystickPresenceYTime: Integer;
begin
  JoystickPresenceXTime := ReadJoystickAxis(JoystickXAxisIndex);
  JoystickPresenceYTime := ReadJoystickAxis(JoystickYAxisIndex);
  if (JoystickPresenceXTime = JoystickAxisTimeout) and (JoystickPresenceYTime = JoystickAxisTimeout) then
    IsJoystickPresent := False
  else
    IsJoystickPresent := True;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}

{$F+}
{ Tests the active-low game-port bit 10h; UpdatePlayerJump uses this button for jump. }
function IsJoystickButton0Pressed: Boolean;
begin
  IsJoystickButton0Pressed := (Port[JoystickGamePort] and JoystickButton0Mask) = 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}

{$F+}
{ Tests the active-low game-port bit 20h; PollJoystickControls uses this button for firing. }
function IsJoystickButton1Pressed: Boolean;
begin
  IsJoystickButton1Pressed := (Port[JoystickGamePort] and JoystickButton1Mask) = 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
begin
end.
