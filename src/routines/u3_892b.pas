{@decls}
var
  d_67FA: Byte;
  d_67FB: Byte;
  d_6814: Word;
{@stubs}
procedure u3_079e;
function u3_1601(Mode: Byte): Byte;
function u3_a6f6(KeyCode: Word): String;
{@body}
procedure u3_892b;
var
  KeyRight, KeyLeft, KeyUp, KeyDown, KeyFire, KeyJump, SpareWord: Word;
  Retry, ContinueRedefining: Boolean;
  procedure u3_8587;
  begin
    u3_079e;
    d_7068 := 'LEFT  - ' + d_7068;
    d_6FC4 := 'RIGHT - ' + d_6FC4;
    d_6ECE := 'UP    - ' + d_6ECE;
    d_6F20 := 'DOWN  - ' + d_6F20;
    d_7016 := 'JUMP  - ' + d_7016;
    d_6F72 := 'FIRE  - ' + d_6F72;
    d_3812[1] := 'KEYBOARD REDEFINED';
    d_3812[2][0] := #0;
    d_3812[3] := d_7068;
    d_3812[4] := d_6FC4;
    d_3812[5] := d_6ECE;
    d_3812[6] := d_6F20;
    d_3812[7] := d_7016;
    d_3812[8] := d_6F72;
    d_3812[9][0] := #0;
    d_3812[10] := 'Are these selections ok (Y-N): ^';
    d_3812[11][0] := #0;
    d_3812[12] := 'END OF WINDOW';
    d_67FA := $15;
    d_67FB := $31;
    d_6814 := u3_1601(0);
    if d_6814 = $31 then
      u3_892b
    else
    begin
      d_70C2 := KeyFire;
      d_70BE := KeyLeft;
      d_70C0 := KeyRight;
      d_70BA := KeyUp;
      d_70BC := KeyDown;
      d_70C4 := KeyJump;
    end;
  end;

  procedure u3_87fd;
  var
    KeyCode: Word;
  begin
    u3_079e;
    d_3812[1] := 'Sorry, that key is unavailable.';
    d_3812[2][0] := #0;
    d_3812[3] := '  Press any key to continue.';
    d_3812[4][0] := #0;
    d_3812[5] := '               ^';
    d_3812[6] := 'END OF WINDOW';
    KeyCode := u3_1601(1);
  end;
begin
  ContinueRedefining := True;

  repeat
    Retry := True;
    u3_079e;
    d_3812[1] := 'KEYBOARD REDEFINE';
    d_3812[2][0] := #0;
    d_3812[3] := 'Select key to move left: ^';
    d_3812[4] := 'END OF WINDOW';
    KeyLeft := u3_1601(1);
    if KeyLeft = 1 then
      ContinueRedefining := False;
    d_7068 := u3_a6f6(KeyLeft);
    if ContinueRedefining and (d_7068 = 'NULL') then
    begin
      u3_87fd;
      Retry := False;
    end;
  until Retry;

  if ContinueRedefining then
  begin
    repeat
      Retry := True;
      u3_079e;
      d_3812[1] := 'KEYBOARD REDEFINE';
      d_3812[2][0] := #0;
      d_3812[3] := 'Select key to move right: ^';
      d_3812[4] := 'END OF WINDOW';
      d_67FA := 1;
      KeyRight := u3_1601(1);
      if KeyRight = 1 then
        ContinueRedefining := False;
      d_6FC4 := u3_a6f6(KeyRight);
      if ContinueRedefining and
         ((d_6FC4 = 'NULL') or (d_6FC4 = d_7068)) then
      begin
        u3_87fd;
        Retry := False;
      end;
    until Retry;
  end;

  if ContinueRedefining then
  begin
    repeat
      Retry := True;
      u3_079e;
      d_3812[1] := 'KEYBOARD REDEFINE';
      d_3812[2][0] := #0;
      d_3812[3] := 'Select key to move up: ^';
      d_3812[4] := 'END OF WINDOW';
      d_67FA := 1;
      KeyUp := u3_1601(1);
      if KeyUp = 1 then
        ContinueRedefining := False;
      d_6ECE := u3_a6f6(KeyUp);
      if ContinueRedefining and
         ((d_6ECE = 'NULL') or (d_6ECE = d_7068) or
          (d_6ECE = d_6FC4)) then
      begin
        u3_87fd;
        Retry := False;
      end;
    until Retry;
  end;

  if ContinueRedefining then
  begin
    repeat
      Retry := True;
      u3_079e;
      d_3812[1] := 'KEYBOARD REDEFINE';
      d_3812[2][0] := #0;
      d_3812[3] := 'Select key to move down: ^';
      d_3812[4] := 'END OF WINDOW';
      d_67FA := 1;
      KeyDown := u3_1601(1);
      if KeyDown = 1 then
        ContinueRedefining := False;
      d_6F20 := u3_a6f6(KeyDown);
      if ContinueRedefining and
         ((d_6F20 = 'NULL') or (d_6F20 = d_7068) or
          (d_6F20 = d_6FC4) or (d_6F20 = d_6ECE)) then
      begin
        u3_87fd;
        Retry := False;
      end;
    until Retry;
  end;

  if ContinueRedefining then
  begin
    repeat
      Retry := True;
      u3_079e;
      d_3812[1] := 'KEYBOARD REDEFINE';
      d_3812[2][0] := #0;
      d_3812[3] := 'Select key to jump: ^';
      d_3812[4] := 'END OF WINDOW';
      d_67FA := 1;
      KeyJump := u3_1601(1);
      if KeyJump = 1 then
        ContinueRedefining := False;
      d_7016 := u3_a6f6(KeyJump);
      if ContinueRedefining and
         ((d_7016 = 'NULL') or (d_7016 = d_7068) or
          (d_7016 = d_6FC4) or (d_7016 = d_6ECE) or
          (d_7016 = d_6F20)) then
      begin
        u3_87fd;
        Retry := False;
      end;
    until Retry;
  end;

  if ContinueRedefining then
  begin
    repeat
      Retry := True;
      u3_079e;
      d_3812[1] := 'KEYBOARD REDEFINE';
      d_3812[2][0] := #0;
      d_3812[3] := 'Select key to fire: ^';
      d_3812[4] := 'END OF WINDOW';
      KeyFire := u3_1601(1);
      if KeyFire = 1 then
        ContinueRedefining := False;
      d_6F72 := u3_a6f6(KeyFire);
      if ContinueRedefining and
         ((d_6F72 = 'NULL') or (d_6F72 = d_7068) or
          (d_6F72 = d_6FC4) or (d_7016 = d_6ECE) or
          (d_7016 = d_6F20) or (d_6F72 = d_7016)) then
      begin
        u3_87fd;
        Retry := False;
      end;
    until Retry;
  end;

  if ContinueRedefining then
    u3_8587;

  MemW[$0000:$041C] := MemW[$0000:$041A];
end;
