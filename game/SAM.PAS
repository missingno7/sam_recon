{ Secret Agent program: installs input/timer handlers, loads configuration,
  and runs the game loop and scene transitions. }
program SAMMAIN;
{$M 16384,0,655360}
{$A+}{$D+}{$L+}{$F-}
uses Dos, PROGRPHX, Crt, SAMDATA, SAMSOUND, GAMEJOY, PCXGENUS, TEXT80, SAMUI, SAMLEVEL, SAMPLAY;
var
  TimerSubticks: array[0..1] of byte;
{$IFDEF SAM1}
{$ELSE}
  VideoBiosRegisters: TVideoBiosRegs;
  DetectedBiosVideoMode: Word;
  DetectedVideoAdapter: Byte;
  { Unused storage retains DATA layout. }
  UnusedVideoProbePadLater: Byte;
{$ENDIF}

{ DOS clock and programmable timer helpers. }
{$L CMOSPIT.OBJ}
{$F+}
{ Reads CMOS time/date and invokes DOS INT 21h AH=$2D and $2B to set DOS time/date. }
procedure SyncDosClockFromCmos; external;
{$F-}
{$F+}
{ Programs PIT channel 0 via ports $43/$40 with mode $36 and divisor $2147; called before the game loop. }
procedure SetFastGameTimer; external;
{$F-}
{$F+}
{ Programs PIT channel 0 with mode $36 and zero divisor, restoring the default 65536-count period. }
procedure RestoreDefaultTimer; external;

{ Keyboard, joystick and timer processing. }
{$F-}
{$F-}
{ Reads scan codes from port $60, handles make/break controls and cheat chords. }
procedure KeyboardInterrupt; interrupt;
var
  ShotSlot: Integer;
  ShotSpawned: Byte;
begin
  LastKeyboardScanCode := Port[$60];
  if PlayerControlsReversed = 1 then
  begin
    if LastKeyboardScanCode = Integer(LeftKeyScanCode) then
      LastKeyboardScanCode := Integer(RightKeyScanCode)
    else if Integer(LeftKeyScanCode) + 128 = LastKeyboardScanCode then
      LastKeyboardScanCode := Integer(RightKeyScanCode) + 128
    else if LastKeyboardScanCode = Integer(RightKeyScanCode) then
      LastKeyboardScanCode := Integer(LeftKeyScanCode)
    else if Integer(RightKeyScanCode) + 128 = LastKeyboardScanCode then
      LastKeyboardScanCode := Integer(LeftKeyScanCode) + 128;
  end;

  if PlayerInputLocked = 0 then
  begin
    if LastKeyboardScanCode = Integer(LeftKeyScanCode) then
    begin
      PlayerLeftHeld := 1;
      PlayerRightHeld := 0;
      PlayerOnMovingSupport := 0;
      GameActors[1].ActorSpriteBase := 5;
      if PlayerJumping <> 0 then
        GameActors[1].ActorSpriteBase := 14;
    end
    else if Integer(LeftKeyScanCode) + 128 = LastKeyboardScanCode then
    begin
      PlayerLeftHeld := 0;
      if PlayerJumping = 0 then
      begin
        if PlayerRightHeld = 0 then
          GameActors[1].ActorSpriteBase := 10
        else
          GameActors[1].ActorSpriteBase := 1;
      end
      else if PlayerRightHeld = 1 then
        GameActors[1].ActorSpriteBase := 13
      else
        GameActors[1].ActorSpriteBase := 14;
    end
    else if LastKeyboardScanCode = Integer(RightKeyScanCode) then
    begin
      PlayerRightHeld := 1;
      PlayerLeftHeld := 0;
      PlayerOnMovingSupport := 0;
      GameActors[1].ActorSpriteBase := 1;
      if PlayerJumping <> 0 then
        GameActors[1].ActorSpriteBase := 13;
    end
    else if Integer(RightKeyScanCode) + 128 = LastKeyboardScanCode then
    begin
      PlayerRightHeld := 0;
      if PlayerJumping = 0 then
      begin
        if PlayerLeftHeld = 0 then
          GameActors[1].ActorSpriteBase := 9
        else
          GameActors[1].ActorSpriteBase := 5;
      end
      else if PlayerLeftHeld = 1 then
        GameActors[1].ActorSpriteBase := 14
      else
        GameActors[1].ActorSpriteBase := 13;
    end
    else if LastKeyboardScanCode = Integer(FireKeyScanCode) then
    begin
      if PlayerAmmo = 0 then
        StartSoundEffect(20)
      else if PlayerAmmo > 0 then
      begin
        if PlayerDying = 0 then
        begin
          if CurrentLevelNumber > 1 then
          begin
            ShotSpawned := 0;
            ShotSlot := 0;
            repeat
              Inc(ShotSlot);
              if PlayerShots[ShotSlot].ActorSlotInactive = 1 then
              begin
                PlayerShots[ShotSlot].ActorWorldX := GameActors[1].ActorWorldX;
                PlayerShots[ShotSlot].ActorWorldY := GameActors[1].ActorWorldY;
                PlayerShots[ShotSlot].ActorPreviousX := GameActors[1].ActorPreviousX;
                PlayerShots[ShotSlot].ActorPreviousY := GameActors[1].ActorPreviousY;
                PlayerShots[ShotSlot].ActorSpriteBase := 39;
                if (GameActors[1].ActorSpriteBase = 1) or (GameActors[1].ActorSpriteBase = 13) or
                (GameActors[1].ActorSpriteBase
                = 9) or (GameActors[1].ActorSpriteBase = 11) then
                begin
                  PlayerShots[ShotSlot].ActorDirectionX := 1;
                  GameActors[1].ActorSpriteBase := 11;
                end
                else
                begin
                  PlayerShots[ShotSlot].ActorDirectionX := -1;
                  GameActors[1].ActorSpriteBase := 12;
                end;
                PlayerShots[ShotSlot].DirectionY := 0;
                PlayerShots[ShotSlot].ActorAnimationCounter := 1;
                PlayerShots[ShotSlot].ActorMovementStep := 8;
                PlayerShots[ShotSlot].ActorCounterA := 0;
                PlayerShots[ShotSlot].ActorCounterB := 0;
                PlayerShots[ShotSlot].ActorKindCode := 7;
                PlayerShots[ShotSlot].ActorSlotInactive := 0;
                PlayerShots[ShotSlot].ActorRemovalPending := 0;
                ShotSpawned := 1;
                Dec(PlayerAmmo);
                StatusBarCameraX := -1;
                StartSoundEffect(2);
                if (GameActors[1].ActorSpriteBase = 1) or (GameActors[1].ActorSpriteBase = 9) or
                (GameActors[1].ActorSpriteBase
                = 13) or (GameActors[1].ActorSpriteBase = 11) then
                  GameActors[1].ActorSpriteBase := 11
                else
                  GameActors[1].ActorSpriteBase := 12;
              end;
            until (ShotSlot = PlayerProjectileLimit) or (ShotSpawned <> 0);
          end;
        end;
      end;
    end  else if Integer(FireKeyScanCode) + 128 = LastKeyboardScanCode then
    begin
      if GameActors[1].ActorSpriteBase = 11 then
        GameActors[1].ActorSpriteBase := 9
      else if GameActors[1].ActorSpriteBase = 12 then
        GameActors[1].ActorSpriteBase := 10;
    end
    else if LastKeyboardScanCode = Integer(JumpKeyScanCode) then
    begin
      PlayerJumpHeld := 1;
    end
    else if Integer(JumpKeyScanCode) + 128 = LastKeyboardScanCode then
    begin
      PlayerJumpHeld := 0;
    end
    else if LastKeyboardScanCode = Integer(UpKeyScanCode) then
    begin
      if CurrentLevelNumber = 1 then
      begin
        PlayerUpHeld := 1;
        PlayerDownHeld := 0;
        if (GameActors[1].ActorSpriteBase = 1) or (GameActors[1].ActorSpriteBase = 9) or (GameActors[1].ActorSpriteBase = 11)
        then
          GameActors[1].ActorSpriteBase := 1
        else
          GameActors[1].ActorSpriteBase := 5;
      end;
    end
    else if Integer(UpKeyScanCode) + 128 = LastKeyboardScanCode then
    begin
      if CurrentLevelNumber = 1 then
      begin
        PlayerUpHeld := 0;
        if (GameActors[1].ActorSpriteBase = 1) or (GameActors[1].ActorSpriteBase = 9) or (GameActors[1].ActorSpriteBase = 11)
        then
          GameActors[1].ActorSpriteBase := 9
        else
          GameActors[1].ActorSpriteBase := 10;
      end;
    end
    else if LastKeyboardScanCode = Integer(DownKeyScanCode) then
    begin
      if CurrentLevelNumber = 1 then
      begin
        PlayerDownHeld := 1;
        PlayerUpHeld := 0;
        if (GameActors[1].ActorSpriteBase = 1) or (GameActors[1].ActorSpriteBase = 9) or (GameActors[1].ActorSpriteBase = 11)
        then
          GameActors[1].ActorSpriteBase := 1
        else
          GameActors[1].ActorSpriteBase := 5;
      end;
    end
    else if Integer(DownKeyScanCode) + 128 = LastKeyboardScanCode then
    begin
      if CurrentLevelNumber = 1 then
      begin
        PlayerDownHeld := 0;
        if (GameActors[1].ActorSpriteBase = 1) or (GameActors[1].ActorSpriteBase = 9) or (GameActors[1].ActorSpriteBase = 11)
        then
          GameActors[1].ActorSpriteBase := 9
        else
          GameActors[1].ActorSpriteBase := 10;
      end;
    end
    else if LastKeyboardScanCode = 1 then
    begin
      EscapePressed := 1;
      GameOptionsRequested := 1;
    end
    else if LastKeyboardScanCode = 16 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = 59 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = 60 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = 61 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = 62 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = 63 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = 64 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = 65 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = 66 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = 67 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = 68 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = $16 then
    begin
      AmmoChordUHeld := 1;
      if (AmmoChordVHeld <> 0) and (AmmoChordKHeld <> 0) and (ExtraAmmoCheatUsed = 0) then
      begin
        PlayerAmmo := PlayerAmmo + 25;
        ExtraAmmoCheatUsed := 1;
        StatusBarCameraX := -1;
      end;
    end
    else if LastKeyboardScanCode = $96 then
      AmmoChordUHeld := 0
    else if LastKeyboardScanCode = $2F then
    begin
      AmmoChordVHeld := 1;
      if (AmmoChordUHeld <> 0) and (AmmoChordKHeld <> 0) and (ExtraAmmoCheatUsed = 0) then
      begin
        PlayerAmmo := PlayerAmmo + 25;
        ExtraAmmoCheatUsed := 1;
        StatusBarCameraX := -1;
      end;
    end
    else if LastKeyboardScanCode = $AF then
      AmmoChordVHeld := 0
    else if LastKeyboardScanCode = $25 then
    begin
      AmmoChordKHeld := 1;
      if (AmmoChordUHeld <> 0) and (AmmoChordVHeld <> 0) and (ExtraAmmoCheatUsed = 0) then
      begin
        PlayerAmmo := PlayerAmmo + 25;
        ExtraAmmoCheatUsed := 1;
        StatusBarCameraX := -1;
      end;
    end
    else if LastKeyboardScanCode = $A5 then
      AmmoChordKHeld := 0
    else if LastKeyboardScanCode = $2C then
    begin
      InventoryChordZHeld := 1;
      if (InventoryChordGHeld <> 0) and (InventoryChordIHeld <> 0) then
      begin
        PlayerHasFloppyDisk := 1;
        PlayerHasDynamite := 1;
        StatusBarCameraX := -1;
      end;
    end
    else if LastKeyboardScanCode = $AC then
      InventoryChordZHeld := 0
    else if LastKeyboardScanCode = $22 then
    begin
      InventoryChordGHeld := 1;
      if (InventoryChordZHeld <> 0) and (InventoryChordIHeld <> 0) then
      begin
        PlayerHasFloppyDisk := 1;
        PlayerHasDynamite := 1;
        StatusBarCameraX := -1;
      end;
    end
    else if LastKeyboardScanCode = $A2 then
      InventoryChordGHeld := 0
    else if LastKeyboardScanCode = $17 then
    begin
      InventoryChordIHeld := 1;
      if (InventoryChordGHeld <> 0) and (InventoryChordZHeld <> 0) then
      begin
        PlayerHasFloppyDisk := 1;
        PlayerHasDynamite := 1;
        StatusBarCameraX := -1;
      end;
    end
    else if LastKeyboardScanCode = $97 then
      InventoryChordIHeld := 0
    else if LastKeyboardScanCode = $19 then
    begin
      GodChordPHeld := 1;
      if (GodChordJHeld <> 0) and (GodChordXHeld <> 0) then
      begin
        if PlayerGodMode = 0 then
          PlayerGodMode := 1
        else
          PlayerGodMode := 0;
        GodModeMessagePending := 1;
      end;
      LevelCheatPBHeld := 1;
      if (WarpChordOHeld <> 0) and (WarpChordNHeld <> 0) and (WarpChordDHeld <> 0) then
        WarpLevelRequested := 1;
    end
    else if LastKeyboardScanCode = $99 then
    begin
      GodChordPHeld := 0;
      LevelCheatPBHeld := 0;
    end
    else if LastKeyboardScanCode = $24 then
    begin
      GodChordJHeld := 1;
      if (GodChordPHeld <> 0) and (GodChordXHeld <> 0) then
      begin
        if PlayerGodMode = 0 then
          PlayerGodMode := 1
        else
          PlayerGodMode := 0;
        GodModeMessagePending := 1;
      end;
    end
    else if LastKeyboardScanCode = $A4 then
      GodChordJHeld := 0
    else if LastKeyboardScanCode = $2D then
    begin
      GodChordXHeld := 1;
      if (GodChordPHeld <> 0) and (GodChordJHeld <> 0) then
      begin
        if PlayerGodMode = 0 then
          PlayerGodMode := 1
        else
          PlayerGodMode := 0;
        GodModeMessagePending := 1;
      end;
    end
    else if LastKeyboardScanCode = $30 then
      LevelCheatPBHeld := 1
    else if LastKeyboardScanCode = $B0 then
      LevelCheatPBHeld := 0
    else if LastKeyboardScanCode = $AD then
      GodChordXHeld := 0
    else if LastKeyboardScanCode = $18 then
    begin
      WarpChordOHeld := 1;
      if (LevelCheatPBHeld <> 0) and (WarpChordNHeld <> 0) and (WarpChordDHeld <> 0) then
        WarpLevelRequested := 1;
    end
    else if LastKeyboardScanCode = $98 then
      WarpChordOHeld := 0
    else if LastKeyboardScanCode = $31 then
    begin
      WarpChordNHeld := 1;
      if (WarpChordOHeld <> 0) and (LevelCheatPBHeld <> 0) and (WarpChordDHeld <> 0) then
        WarpLevelRequested := 1;
    end
    else if LastKeyboardScanCode = $B1 then
      WarpChordNHeld := 0
    else if LastKeyboardScanCode = $20 then
    begin
      WarpChordDHeld := 1;
      if (WarpChordOHeld <> 0) and (WarpChordNHeld <> 0) and (LevelCheatPBHeld <> 0) then
        WarpLevelRequested := 1;
    end
    else if LastKeyboardScanCode = $A0 then
      WarpChordDHeld := 0;

  end;
  if (PlayerUpHeld = 0) and (PlayerDownHeld = 0) and (PlayerRightHeld = 0) and (PlayerLeftHeld = 0) then
    MoveRampTicks := 0;
  { chain to the previous INT 9 handler (SavedKeyboardVector, saved by InstallGameHandlers) }
  inline($FF/$36/>SavedKeyboardVector+2/     { push word ptr SavedKeyboardVector+2 }
         $FF/$36/>SavedKeyboardVector/       { push word ptr SavedKeyboardVector }
         $5B/$58/$87/$5E/$0E/$87/$46/$10/$89/$EC/$5D/$07/$1F/$5F/$5E/$5A/$59/$CB);
  { acknowledge the keyboard and send EOI (unreachable after the chain; the original
    has $80 where MOV AL,20h would be $B0) }
  inline($E4/$61/$8A/$E0/$0C/$80/$E6/$61/$86/$E0/$E6/$61/$80/$20/$E6/$20);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Reads joystick axes, compares each with calibrated center +/-50. }
procedure PollJoystickControls;
var
  ShotSlot: Integer;
  ShotSpawned: Byte;
begin
  JoystickAxisX := ReadJoystickAxis(0);
  JoystickAxisY := ReadJoystickAxis(1);
  if JoystickFirePosePending <> 0 then
  begin
    JoystickFirePosePending := 0;
    if GameActors[1].ActorSpriteBase = 11 then
      GameActors[1].ActorSpriteBase := 9
    else if GameActors[1].ActorSpriteBase = 12 then
      GameActors[1].ActorSpriteBase := 10;
  end;
  if JoystickCenterX - 50 > JoystickAxisX then
  begin
    PlayerLeftHeld := 1;
    PlayerRightHeld := 0;
    PlayerOnMovingSupport := 0;
    JoystickHorizontalMoved := 1;
    if (PlayerJumping = 0) and (PlayerFalling = 0) then
      GameActors[1].ActorSpriteBase := 5
    else
      GameActors[1].ActorSpriteBase := 14;
  end
  else if JoystickCenterX + 50 < JoystickAxisX then
  begin
    PlayerRightHeld := 1;
    PlayerLeftHeld := 0;
    PlayerOnMovingSupport := 0;
    JoystickHorizontalMoved := 1;
    if (PlayerJumping = 0) and (PlayerFalling = 0) then
      GameActors[1].ActorSpriteBase := 1
    else
      GameActors[1].ActorSpriteBase := 13;
  end
  else if JoystickHorizontalMoved <> 0 then
  begin
    if (PlayerRightHeld = 1) or (GameActors[1].ActorSpriteBase = 1) then
      GameActors[1].ActorSpriteBase := 9
    else
      GameActors[1].ActorSpriteBase := 10;
    PlayerRightHeld := 0;
    PlayerLeftHeld := 0;
    JoystickHorizontalMoved := 0;
  end;

  if CurrentLevelNumber = 1 then
  begin
    if JoystickCenterY - 50 > JoystickAxisY then
    begin
      PlayerUpHeld := 1;
      JoystickVerticalMoved := 1;
      if (GameActors[1].ActorSpriteBase = 1) or (GameActors[1].ActorSpriteBase = 9) or (GameActors[1].ActorSpriteBase = 11)
      then
        GameActors[1].ActorSpriteBase := 1
      else
        GameActors[1].ActorSpriteBase := 5;
    end
    else if JoystickCenterY + 50 < JoystickAxisY then
    begin
      PlayerDownHeld := 1;
      JoystickVerticalMoved := 1;
      if (GameActors[1].ActorSpriteBase = 1) or (GameActors[1].ActorSpriteBase = 9) or (GameActors[1].ActorSpriteBase = 11)
      then
        GameActors[1].ActorSpriteBase := 1
      else
        GameActors[1].ActorSpriteBase := 5;
    end
    else if JoystickVerticalMoved <> 0 then
    begin
      JoystickVerticalMoved := 0;
      PlayerUpHeld := 0;
      PlayerDownHeld := 0;
      if (GameActors[1].ActorSpriteBase = 1) or (GameActors[1].ActorSpriteBase = 9) or (GameActors[1].ActorSpriteBase = 11)
      then
        GameActors[1].ActorSpriteBase := 9
      else
        GameActors[1].ActorSpriteBase := 10;
    end;
  end;

  if not IsJoystickButton1Pressed then
    Exit;
  if PlayerAmmo <= 0 then
    Exit;
  if CurrentLevelNumber <= 1 then
    Exit;
  if PlayerDying <> 0 then
    Exit;

  ShotSpawned := 0;
  ShotSlot := 0;
  repeat
    Inc(ShotSlot);
    if PlayerShots[ShotSlot].ActorSlotInactive = 1 then
    begin
      PlayerShots[ShotSlot].ActorWorldX := GameActors[1].ActorWorldX;
      PlayerShots[ShotSlot].ActorWorldY := GameActors[1].ActorWorldY;
      PlayerShots[ShotSlot].ActorPreviousX := GameActors[1].ActorPreviousX;
      PlayerShots[ShotSlot].ActorPreviousY := GameActors[1].ActorPreviousY;
      PlayerShots[ShotSlot].ActorSpriteBase := 39;
      if (GameActors[1].ActorSpriteBase = 1) or (GameActors[1].ActorSpriteBase = 13) or (GameActors[1].ActorSpriteBase = 9) or
      (GameActors[1].ActorSpriteBase = 11) then
      begin
        PlayerShots[ShotSlot].ActorDirectionX := 1;
        JoystickFirePosePending := 1;
        GameActors[1].ActorSpriteBase := 11;
      end
      else
      begin
        PlayerShots[ShotSlot].ActorDirectionX := -1;
        JoystickFirePosePending := 1;
        GameActors[1].ActorSpriteBase := 12;
      end;
      PlayerShots[ShotSlot].DirectionY := 0;
      PlayerShots[ShotSlot].ActorAnimationCounter := 1;
      PlayerShots[ShotSlot].ActorMovementStep := 8;
      PlayerShots[ShotSlot].ActorCounterA := 0;
      PlayerShots[ShotSlot].ActorCounterB := 0;
      PlayerShots[ShotSlot].ActorKindCode := 7;
      PlayerShots[ShotSlot].ActorSlotInactive := 0;
      PlayerShots[ShotSlot].ActorRemovalPending := 0;
      ShotSpawned := 1;
      Dec(PlayerAmmo);
      StatusBarCameraX := -1;
      StartSoundEffect(2);
      if (GameActors[1].ActorSpriteBase = 1) or (GameActors[1].ActorSpriteBase = 9) or (GameActors[1].ActorSpriteBase = 13) or
      (GameActors[1].ActorSpriteBase = 11) then
        GameActors[1].ActorSpriteBase := 11
      else
        GameActors[1].ActorSpriteBase := 12;
    end;
  until (ShotSlot = PlayerProjectileLimit) or (ShotSpawned <> 0);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F-}
{ INT 1Ch handler increments timing counters, expires speed/confusion/slow effects and advances PC-speaker. }
procedure TimerInterrupt; interrupt;
begin
  inline($FA);
  Inc(GameTickCounter);
  Inc(TimerSubticks[0]);
  if TimerSubticks[0] = 20 then
  begin
    TimerSubticks[0] := 0;
    if SpeedBoostTimeLeft > 0 then
    begin
      Dec(SpeedBoostTimeLeft);
      if SpeedBoostTimeLeft = 0 then
      begin
        PlayerSpeedBoost := 0;
        StatusBarCameraX := -1;
      end;
    end;
    if SlowMovementTimeLeft > 0 then
    begin
      Dec(SlowMovementTimeLeft, 2);
      if SlowMovementTimeLeft = 0 then
      begin
        PlayerSlowMovement := 0;
        StatusBarCameraX := -1;
      end;
    end;
    if ConfusionTimeLeft > 0 then
    begin
      Dec(ConfusionTimeLeft, 2);
      if ConfusionTimeLeft = 0 then
      begin
        ConfusionEndedMessagePending := 1;
        PlayerControlsReversed := 0;
        StatusBarCameraX := -1;
      end;
    end;
  end;

  if (SoundPlaying <> 0) and (SoundEnabled <> 0) then
  begin
    case CurrentSoundEffect of
      1..12:
        begin
          Sound(SoundBankOne^[CurrentSoundEffect, SoundSampleIndex]);
          Inc(SoundSampleIndex);
          if SoundSampleIndex mod SoundBankOne^[CurrentSoundEffect, 303] = 0 then
            NoSound;
          if SoundBankOne^[CurrentSoundEffect, SoundSampleIndex] = -1 then
          begin
            SoundPlaying := 0;
            SoundSampleIndex := 1;
            NoSound;
          end;
        end;
      13..24:
        begin
          Sound(SoundBankTwo^[CurrentSoundEffect - 12, SoundSampleIndex]);
          Inc(SoundSampleIndex);
          if SoundSampleIndex mod SoundBankTwo^[CurrentSoundEffect - 12, 303] = 0 then
            NoSound;
          if SoundBankTwo^[CurrentSoundEffect - 12, SoundSampleIndex] = -1 then
          begin
            SoundPlaying := 0;
            SoundSampleIndex := 1;
            NoSound;
          end;
        end;
      25..36:
        begin
          Sound(SoundBankThree^[CurrentSoundEffect - 24, SoundSampleIndex]);
          Inc(SoundSampleIndex);
          if SoundSampleIndex mod SoundBankThree^[CurrentSoundEffect - 24, 303] = 0 then
            NoSound;
          if SoundBankThree^[CurrentSoundEffect - 24, SoundSampleIndex] = -1 then
          begin
            SoundPlaying := 0;
            SoundSampleIndex := 1;
            NoSound;
          end;
        end;
    end;
  end;
  inline($FB);
end;

{ Interrupt and exit-handler installation/restoration. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Restores ExitProc and the saved INT 1Ch and INT 9 vectors. }
procedure RestoreExitHandlers;
begin
  ExitProc := SavedExitProc;
  SetIntVec($1C, SavedTimerVector);
  SetIntVec($09, SavedKeyboardVector);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F-}
{ Saves ExitProc/INT 1Ch/INT 9 and installs RestoreExitHandlers, TimerInterrupt and KeyboardInterrupt. }
procedure InstallGameHandlers;
begin
  SavedExitProc := ExitProc;
  ExitProc := @RestoreExitHandlers;
  GetIntVec($1C, SavedTimerVector);
  SetIntVec($1C, @TimerInterrupt);
  GetIntVec($09, SavedKeyboardVector);
  SetIntVec($09, @KeyboardInterrupt);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F-}
{ Restores only the two saved timer and keyboard interrupt vectors. }
procedure RestoreGameInterrupts;
begin
  SetIntVec($1C, SavedTimerVector);
  SetIntVec($09, SavedKeyboardVector);
end;

{ Persistent episode configuration. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Copies sound/input/video settings into GameConfiguration and writes SAM1.CFG/SAM2.CFG/SAM3.CFG. }
procedure SaveGameConfig;
var
  ConfigFile: TGameConfigFile;
begin
  GameConfiguration.ConfigSoundEnabled := SoundEnabled;
  GameConfiguration.ConfigUpScanCode := UpKeyScanCode;
  GameConfiguration.ConfigDownScanCode := DownKeyScanCode;
  GameConfiguration.ConfigLeftScanCode := LeftKeyScanCode;
  GameConfiguration.ConfigRightScanCode := RightKeyScanCode;
  GameConfiguration.ConfigJumpScanCode := JumpKeyScanCode;
  GameConfiguration.ConfigFireScanCode := FireKeyScanCode;
  GameConfiguration.ConfigAlternateVideo := AlternateVideoTiming;
  GameConfiguration.ConfigJoystickEnabled := JoystickSettingEnabled;
{$I-}
{$IFDEF SAM1}
  Assign(ConfigFile, 'SAM1.CFG');
{$ENDIF}
{$IFDEF SAM2}
  Assign(ConfigFile, 'SAM2.CFG');
{$ENDIF}
{$IFDEF SAM3}
  Assign(ConfigFile, 'SAM3.CFG');
{$ENDIF}
  Rewrite(ConfigFile);
  Write(ConfigFile, GameConfiguration);
  Close(ConfigFile);
{$I+}
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Reads the episode CFG into high scores/settings or installs default arrows, Ctrl jump. }
procedure LoadGameConfig;
var
  ConfigFile: TGameConfigInputFile;
  ConfigOpened: Boolean;
begin
{$I-}
{$IFDEF SAM1}
  Assign(ConfigFile, 'SAM1.CFG');
{$ENDIF}
{$IFDEF SAM2}
  Assign(ConfigFile, 'SAM2.CFG');
{$ENDIF}
{$IFDEF SAM3}
  Assign(ConfigFile, 'SAM3.CFG');
{$ENDIF}
  Reset(ConfigFile);
  ConfigOpened := IOResult = 0;
  Reset(ConfigFile);
  ConfigOpened := IOResult = 0;

  if ConfigOpened then
  begin
    Read(ConfigFile, GameConfiguration);
    Close(ConfigFile);
    SoundEnabled := GameConfiguration.ConfigSoundEnabled;
    UpKeyScanCode := GameConfiguration.ConfigUpScanCode;
    DownKeyScanCode := GameConfiguration.ConfigDownScanCode;
    LeftKeyScanCode := GameConfiguration.ConfigLeftScanCode;
    RightKeyScanCode := GameConfiguration.ConfigRightScanCode;
    JumpKeyScanCode := GameConfiguration.ConfigJumpScanCode;
    FireKeyScanCode := GameConfiguration.ConfigFireScanCode;
    AlternateVideoTiming := GameConfiguration.ConfigAlternateVideo;
    JoystickSettingEnabled := GameConfiguration.ConfigJoystickEnabled;
    if JoystickSettingEnabled = 1 then
      JoystickActive := IsJoystickPresent
    else
      JoystickActive := False;
  end
  else
  begin
    SoundEnabled := 1;
    UpKeyScanCode := $48;
    DownKeyScanCode := $50;
    LeftKeyScanCode := $4B;
    RightKeyScanCode := $4D;
    JumpKeyScanCode := $1D;
    FireKeyScanCode := $38;
    AlternateVideoTiming := 0;
    JoystickSettingEnabled := 0;
    JoystickActive := False;
  end;
{$I+}
end;

{ BIOS video probing for episodes 2 and 3. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$IFDEF SAM1}
{$ELSE}
{$F+}
{ Uses INT 10h AH=$0F, AX=$1A00 and AH=$12/BL=$10 to obtain the video mode and mapped adapter class. }
procedure DetectBiosVideoAdapter;
begin
  DetectedVideoAdapter := 1;
  VideoBiosRegisters.AH := $0F;
  Intr($10, Registers(VideoBiosRegisters));
  DetectedBiosVideoMode := VideoBiosRegisters.AL and $7F;
  VideoBiosRegisters.AX := $1A00;
  Intr($10, Registers(VideoBiosRegisters));
  if VideoBiosRegisters.AL = $1A then
  begin
    if VideoBiosRegisters.BL <> $FF then
      DetectedVideoAdapter := BiosAdapterClassMap[VideoBiosRegisters.BL];
  end
  else
  begin
    VideoBiosRegisters.AH := $12;
    VideoBiosRegisters.BL := $10;
    Intr($10, Registers(VideoBiosRegisters));
    if VideoBiosRegisters.BL <> $10 then
      DetectedVideoAdapter := 3;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$ENDIF}
{ Startup, resource loading, island/mission transitions and the main game loop. }
begin
  if MemAvail < 200000 then
  begin
    Writeln('Secret Agent Requires 450k free Memory to run!');
    Halt;
  end;
{$IFDEF SAM1}
  if DetectGameVideoAdapter <> 'U' then
{$ELSE}
  DetectBiosVideoAdapter;
  if (DetectedVideoAdapter=3) or (DetectedVideoAdapter=4) then
{$ENDIF}
  begin
    InstallGameHandlers;
    SetFastGameTimer;
    SoundPlaying := 0;
    GetMem(SoundBankOne, 7320);
{$IFDEF SAM1}
    Assign(SoundResourceFile, 'SAM101E.SND');
{$ENDIF}
{$IFDEF SAM2}
    Assign(SoundResourceFile, 'SAM201E.SND');
{$ENDIF}
{$IFDEF SAM3}
    Assign(SoundResourceFile, 'SAM301E.SND');
{$ENDIF}
    Reset(SoundResourceFile);
    Read(SoundResourceFile, SoundBankOne^);
    DecryptGameAssetBuffer(SoundBankOne^, 7320);
    Close(SoundResourceFile);
    GetMem(SoundBankTwo, 7320);
{$IFDEF SAM1}
    Assign(SoundResourceFile, 'SAM102E.SND');
{$ENDIF}
{$IFDEF SAM2}
    Assign(SoundResourceFile, 'SAM202E.SND');
{$ENDIF}
{$IFDEF SAM3}
    Assign(SoundResourceFile, 'SAM302E.SND');
{$ENDIF}
    Reset(SoundResourceFile);
    Read(SoundResourceFile, SoundBankTwo^);
    DecryptGameAssetBuffer(SoundBankTwo^, 7320);
    Close(SoundResourceFile);
    GetMem(SoundBankThree, 7320);
{$IFDEF SAM1}
    Assign(SoundResourceFile, 'SAM103E.SND');
{$ENDIF}
{$IFDEF SAM2}
    Assign(SoundResourceFile, 'SAM203E.SND');
{$ENDIF}
{$IFDEF SAM3}
    Assign(SoundResourceFile, 'SAM303E.SND');
{$ENDIF}
    Reset(SoundResourceFile);
    Read(SoundResourceFile, SoundBankThree^);
    DecryptGameAssetBuffer(SoundBankThree^, 7320);
    Close(SoundResourceFile);
    SoundEnabled := 1;
    InitializeGameDefaults;
    CaptureGameSnapshot;
    UnusedStartupWord1 := 0;
    UnusedStartupWord2 := 0;
    UnusedStartupWord3 := 0;
    RestoreGamePalette(0);
    JoystickActive := IsJoystickPresent;
    JoystickHorizontalMoved := 0;
    if JoystickActive then
    begin
      JoystickCenterX := ReadJoystickAxis(0);
      JoystickCenterY := ReadJoystickAxis(1);
    end;
    LoadGameConfig;
    Writeln('Decompressing Graphics Files...');
    LoadGameSpriteBanks;
    PgSetToolboxVideoMode(0);
    ShowApogeeSplash;
    while QuitGameRequested = 0 do
    begin
      PgSetToolboxVideoMode(0);
      ShowTitleAndCredits;
      if QuitGameRequested = 0 then ResetNewGameState;
      if (QuitGameRequested = 0) and (ReturnToTitleRequested = 0) then
      begin
        VideoStrideResult := PgSetScreenStride(80);
        PgSetBorderColor(4);
        BlackenGamePalette;
        if AlternateVideoTiming = 0 then PgPanDisplayAtRetraceStart(0,16)
        else PgPanDisplayAtRetraceEnd(0,16);
        ResetLevelTransientState;
        if PendingRestoreScanCode <> 0 then
        begin
          case PendingRestoreScanCode of
            2..10: if ReadSavedGame(PendingRestoreScanCode-1) then;
            11: if ReadSavedGame(0) then;
          end;
          PendingRestoreScanCode := 0;
        end;
        LoadLevelMap(1);
{$IFDEF SAM1}
        if DetectGameVideoAdapter = 'V' then
{$ELSE}
        if DetectedVideoAdapter=4 then
{$ENDIF}
          PgSetVgaSplitScanline(384)
        else PgSetEgaSplitScanline(190);
        while (QuitGameRequested = 0) and (ReturnToTitleRequested = 0) do
        begin
          if StatusBarCameraX <> CameraX then DrawGameStatusBar;
          if GameTickCounter > 7 then
          begin
            GameTickCounter := 0;
            if JoystickActive then PollJoystickControls;
            if (GameActors[1].ActorSpriteBase = 9) and (PlayerRightHeld <> 0) then
              GameActors[1].ActorSpriteBase := 1
            else if (GameActors[1].ActorSpriteBase = 10) and (PlayerLeftHeld <> 0) then
              GameActors[1].ActorSpriteBase := 5
            else if ((GameActors[1].ActorSpriteBase = 10) or (GameActors[1].ActorSpriteBase = 9))
              and ((PlayerDownHeld <> 0) or (PlayerUpHeld <> 0)) then
              GameActors[1].ActorSpriteBase := 1;
            ToggleGameDrawBuffer;
            RedrawLevelCell(GameActors[1].ActorPreviousX-16,GameActors[1].ActorPreviousY-16);
            RedrawLevelCell(GameActors[1].ActorPreviousX-16,GameActors[1].ActorPreviousY);
            RedrawLevelCell(GameActors[1].ActorPreviousX-16,GameActors[1].ActorPreviousY+16);
            RedrawLevelCell(GameActors[1].ActorPreviousX,GameActors[1].ActorPreviousY-16);
            RedrawLevelCell(GameActors[1].ActorPreviousX,GameActors[1].ActorPreviousY);
            RedrawLevelCell(GameActors[1].ActorPreviousX,GameActors[1].ActorPreviousY+16);
            RedrawLevelCell(GameActors[1].ActorPreviousX+16,GameActors[1].ActorPreviousY-16);
            RedrawLevelCell(GameActors[1].ActorPreviousX+16,GameActors[1].ActorPreviousY);
            RedrawLevelCell(GameActors[1].ActorPreviousX+16,GameActors[1].ActorPreviousY+16);

            for SharedLoopIndexA := 2 to 25 do
              if GameActors[SharedLoopIndexA].ActorSlotInactive = 0 then
                if GameActors[SharedLoopIndexA].ActorRemovalPending <> 0 then
                begin
                  GameActors[SharedLoopIndexA].ActorSlotInactive := 1;
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX,GameActors[SharedLoopIndexA].ActorPreviousY);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX-16,GameActors[SharedLoopIndexA].ActorPreviousY);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX+16,GameActors[SharedLoopIndexA].ActorPreviousY);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX+32,GameActors[SharedLoopIndexA].ActorPreviousY);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX-16,GameActors[SharedLoopIndexA].ActorPreviousY-
                  16);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX-16,GameActors[SharedLoopIndexA].ActorPreviousY+
                  16);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX+16,GameActors[SharedLoopIndexA].ActorPreviousY-
                  16);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX+16,GameActors[SharedLoopIndexA].ActorPreviousY+
                  16);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX,GameActors[SharedLoopIndexA].ActorPreviousY-16);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX,GameActors[SharedLoopIndexA].ActorPreviousY+16);
                end
                else if ActorNearViewport(40,SharedLoopIndexA) or (GameActors[SharedLoopIndexA].ActorKindCode=28)
                  or (GameActors[SharedLoopIndexA].ActorKindCode=21) or (GameActors[SharedLoopIndexB].ActorKindCode=14)
                  or (GameActors[SharedLoopIndexB].ActorRemovalPending<>0) then
                begin
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX,GameActors[SharedLoopIndexA].ActorPreviousY);
                  if GameActors[SharedLoopIndexA].ActorPreviousX and 15 > 0 then
                    RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX+16,
                    GameActors[SharedLoopIndexA].ActorPreviousY);
                  case GameActors[SharedLoopIndexA].ActorSpriteBase of
                    851: begin
                      RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX+48,
                      GameActors[SharedLoopIndexA].ActorPreviousY);
                      RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX+32,
                      GameActors[SharedLoopIndexA].ActorPreviousY);
                      RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX+16,
                      GameActors[SharedLoopIndexA].ActorPreviousY);
                    end;
                    801..899,5001: begin
                      RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX,GameActors[SharedLoopIndexA].ActorPreviousY-
                      16);
                      if GameActors[SharedLoopIndexA].ActorPreviousX and 15 > 0 then
                        RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX+15,
                        GameActors[SharedLoopIndexA].ActorPreviousY-16);
                    end;
                    114: begin
                      RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX,GameActors[SharedLoopIndexA].ActorPreviousY-
                      16);
                      RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX,GameActors[SharedLoopIndexA].ActorPreviousY+
                      16);
                      if GameActors[SharedLoopIndexA].ActorPreviousX and 15 > 0 then
                      begin
                        RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX+15,
                        GameActors[SharedLoopIndexA].ActorPreviousY+16);
                        RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX+15,
                        GameActors[SharedLoopIndexA].ActorPreviousY-16);
                      end;
                    end;
                    101: begin
                      RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX,GameActors[SharedLoopIndexA].ActorPreviousY-
                      16);
                      if GameActors[SharedLoopIndexA].ActorPreviousX and 15 > 0 then
                        RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX+15,
                        GameActors[SharedLoopIndexA].ActorPreviousY-16);
                    end;
                  end;
                end;

            for SharedLoopIndexA := 1 to PlayerProjectileLimit do
            begin
              RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorPreviousX,PlayerShots[SharedLoopIndexA].ActorPreviousY);
              RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorPreviousX+16,PlayerShots[SharedLoopIndexA].ActorPreviousY);
              RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorPreviousX,PlayerShots[SharedLoopIndexA].ActorPreviousY+16);
              RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorPreviousX+16,PlayerShots[SharedLoopIndexA].ActorPreviousY+
              16);
            end;

            if (PlayerDying=0) and (PlayerLeavingLevel=0) then
            begin
              MovePlayerAndCamera;
              if CurrentLevelNumber > 1 then UpdatePlayerJump;
              MemW[0:$41C] := MemW[0:$41A];
              CheckPlayerTileContacts;
              PlayerOnMovingSupport := 0;
            end
            else if PlayerDying <> 0 then
            begin
              GameActors[1].ActorPreviousX := GameActors[1].ActorWorldX;
              GameActors[1].ActorPreviousY := GameActors[1].ActorWorldY;
              if GameActors[1].ActorSpriteBase <> 15 then GameActors[1].ActorSpriteBase := 15
              else GameActors[1].ActorSpriteBase := 16;
              if DeathAnimationTick=35 then StartSoundEffect(22);
              Dec(DeathAnimationTick);
              if DeathAnimationTick=0 then RequestIslandReturn;
              if DeathAnimationTick>0 then
              begin
                Dec(GameActors[1].ActorWorldY,DeathVerticalMotionTable[DeathAnimationTick]);
                if GameActors[1].ActorWorldY < 16 then GameActors[1].ActorWorldY := 16
                else if CameraY+184 < GameActors[1].ActorWorldY then
                  GameActors[1].ActorWorldY := CameraY+184;
              end;
            end
            else if PlayerLeavingLevel<>0 then
            begin
              GameActors[1].ActorPreviousX := GameActors[1].ActorWorldX;
              GameActors[1].ActorPreviousY := GameActors[1].ActorWorldY;
              if LevelExitAnimationTick=8 then StartSoundEffect(8);
              Dec(LevelExitAnimationTick);
              if LevelExitAnimationTick=0 then
              begin
                FadeGamePaletteToBlack(20);
                CurrentLevelNumber := 1;
                ResetLevelTransientState;
                LoadLevelMap(CurrentLevelNumber);
                if AllMissionsComplete<>0 then ShowFortressUnlockedMessage;
              end
              else if LevelExitAnimationTick>0 then
                if GameActors[1].ActorDirectionX=-1 then Dec(GameActors[1].ActorWorldX,2)
                else Inc(GameActors[1].ActorWorldX,2);
            end;
            UpdateActorsAndShots;

            for SharedLoopIndexA := 1 to PlayerProjectileLimit do
              if PlayerShots[SharedLoopIndexA].ActorSlotInactive=0 then
              begin
                if PlayerShots[SharedLoopIndexA].ActorRemovalPending<>0 then
                begin
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX,PlayerShots[SharedLoopIndexA].ActorWorldY);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX+16,PlayerShots[SharedLoopIndexA].ActorWorldY);
                  DrawCellForeground(PlayerShots[SharedLoopIndexA].ActorWorldX,PlayerShots[SharedLoopIndexA].ActorWorldY);
                  DrawCellForeground(PlayerShots[SharedLoopIndexA].ActorWorldX+16,PlayerShots[SharedLoopIndexA].ActorWorldY);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX,PlayerShots[SharedLoopIndexA].ActorWorldY+16);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX+16,PlayerShots[SharedLoopIndexA].ActorWorldY+16);
                  DrawCellForeground(PlayerShots[SharedLoopIndexA].ActorWorldX,PlayerShots[SharedLoopIndexA].ActorWorldY+16);
                  DrawCellForeground(PlayerShots[SharedLoopIndexA].ActorWorldX+16,PlayerShots[SharedLoopIndexA].ActorWorldY+
                  16);
                  PlayerShots[SharedLoopIndexA].ActorSlotInactive := 1;
                end
                else
                begin
                  if PlayerShots[SharedLoopIndexA].ActorSpriteBase=626 then
                  begin
                    PgBlitMaskedShifted16x16(SpriteBank601^.SpriteEntries[(PlayerShots[SharedLoopIndexA].ActorCounterB shr
                    1)+25].SpriteDataBytes[1],
    PlayerShots[SharedLoopIndexA].ActorWorldX,
    PlayerShots[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
                    Dec(PlayerShots[SharedLoopIndexA].ActorCounterB);
                    if PlayerShots[SharedLoopIndexA].ActorCounterB<=0 then
                    begin
                      PlayerShots[SharedLoopIndexA].ActorRemovalPending := 1;
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX,PlayerShots[SharedLoopIndexA].ActorWorldY);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX-16,PlayerShots[SharedLoopIndexA].ActorWorldY);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX+16,PlayerShots[SharedLoopIndexA].ActorWorldY);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX,PlayerShots[SharedLoopIndexA].ActorWorldY+16);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX-16,PlayerShots[SharedLoopIndexA].ActorWorldY+16);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX+16,PlayerShots[SharedLoopIndexA].ActorWorldY+16);
                    end;
                  end
                  else if not ShotNearViewport(40,SharedLoopIndexA) then
                  begin
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX,PlayerShots[SharedLoopIndexA].ActorWorldY);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX+16,PlayerShots[SharedLoopIndexA].ActorWorldY);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX,PlayerShots[SharedLoopIndexA].ActorWorldY+16);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX+16,PlayerShots[SharedLoopIndexA].ActorWorldY+16);
                    PlayerShots[SharedLoopIndexA].ActorRemovalPending := 1;
                  end
                  else
                  begin
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX,PlayerShots[SharedLoopIndexA].ActorWorldY);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX+16,PlayerShots[SharedLoopIndexA].ActorWorldY);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX,PlayerShots[SharedLoopIndexA].ActorWorldY+16);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX+16,PlayerShots[SharedLoopIndexA].ActorWorldY+16);
                    PgBlitMasked16x16(SpriteBank001^.SpriteEntries[PlayerShots[SharedLoopIndexA].ActorSpriteBase-1+
                    PlayerShots[SharedLoopIndexA].ActorAnimationCounter].SpriteDataBytes[1],
    PlayerShots[SharedLoopIndexA].ActorWorldX shr 3,

                  PlayerShots[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
                  end;
                  DrawCellForeground(PlayerShots[SharedLoopIndexA].ActorWorldX,PlayerShots[SharedLoopIndexA].ActorWorldY);
                  DrawCellForeground(PlayerShots[SharedLoopIndexA].ActorWorldX+16,PlayerShots[SharedLoopIndexA].ActorWorldY);
                  DrawCellForeground(PlayerShots[SharedLoopIndexA].ActorWorldX,PlayerShots[SharedLoopIndexA].ActorWorldY+16);
                  DrawCellForeground(PlayerShots[SharedLoopIndexA].ActorWorldX+16,PlayerShots[SharedLoopIndexA].ActorWorldY+
                  16);
                end;
              end;

            if PlayerTeleporting<>0 then
            begin
              Dec(TeleportAnimationTick);
              if TeleportAnimationTick=0 then TeleportRelocatePending := 1
              else if TeleportAnimationTick=-19 then
              begin
                PlayerInputLocked := 0;
                PlayerTeleporting := 0;
              end;
            end;
            if TeleportRelocatePending<>0 then
            begin
              TeleportRelocatePending := 0;
              GameActors[1].ActorWorldX := TeleportDestinationX;
              GameActors[1].ActorWorldY := TeleportDestinationY;
              CameraX := GameActors[1].ActorWorldX-160;
              if CameraX<0 then CameraX := 0;
              if CameraX>320 then CameraX := 320;
              CameraY := GameActors[1].ActorWorldY-100;
              if CameraY<0 then CameraY := 0;
              if CameraY>184 then CameraY := 184;
              if AlternateVideoTiming=0 then PgPanDisplayAtRetraceStart(CameraX,CameraY+16)
              else PgPanDisplayAtRetraceEnd(CameraX,CameraY+16);
            end;
            SharedLoopIndexA := 1;
            if (GameActors[1].ActorSpriteBase=1) or (GameActors[1].ActorSpriteBase=5) then
            begin
              Inc(GameActors[1].ActorAnimationCounter,GameActors[1].ActorMovementStep);
              if GameActors[1].ActorAnimationCounter>19 then GameActors[1].ActorAnimationCounter := 1;
            end
            else GameActors[1].ActorAnimationCounter := 1;
            if PlayerDamageGraceActive<>0 then
            begin
              Dec(PlayerDamageGraceTick);
              case PlayerDamageGraceTick of
                0: PlayerDamageGraceActive := 0;
                10: GameActors[1].FlashFrames := 5;
                20: GameActors[1].FlashFrames := 5;
                30: GameActors[1].FlashFrames := 5;
              end;
            end;

            if GameActors[1].FlashFrames>0 then
            begin
              PgOrShifted16x16(PlayerSpriteBank^.SpriteEntries[GameActors[1].ActorAnimationCounter div
              5+GameActors[1].ActorSpriteBase].SpriteDataBytes[1],
    GameActors[1].ActorWorldX,
    GameActors[1].ActorWorldY+GameDrawBufferRow);
              Dec(GameActors[1].FlashFrames);
            end
            else if GameActors[1].ActorWorldX and 7 = 0 then
              PgBlitMasked16x16(PlayerSpriteBank^.SpriteEntries[GameActors[1].ActorAnimationCounter div
              5+GameActors[1].ActorSpriteBase].SpriteDataBytes[1],
    GameActors[1].ActorWorldX shr 3,
    GameActors[1].ActorWorldY+GameDrawBufferRow)
            else
              PgBlitMaskedShifted16x16(PlayerSpriteBank^.SpriteEntries[GameActors[1].ActorAnimationCounter div
              5+GameActors[1].ActorSpriteBase].SpriteDataBytes[1],
    GameActors[1].ActorWorldX,
    GameActors[1].ActorWorldY+GameDrawBufferRow);
            if PlayerTeleporting<>0 then
              if TeleportAnimationTick<0 then
                PgBlitMaskedShifted16x16(SpriteBank151^.SpriteEntries[TeleportAnimationTick div
                5+40].SpriteDataBytes[1],GameActors[1].ActorWorldX,GameActors[1].ActorWorldY+GameDrawBufferRow)
              else
                PgBlitMaskedShifted16x16(SpriteBank151^.SpriteEntries[40-TeleportAnimationTick div
                5].SpriteDataBytes[1],GameActors[1].ActorWorldX,GameActors[1].ActorWorldY+GameDrawBufferRow);
            if (PlayerLeftHeld<>0) and (GameActors[1].ActorSpriteBase=12) then
              GameActors[1].ActorSpriteBase := 5
            else if (PlayerRightHeld<>0) and (GameActors[1].ActorSpriteBase=11) then
              GameActors[1].ActorSpriteBase := 1;

            for SharedLoopIndexA := 2 to 25 do
              if GameActors[SharedLoopIndexA].ActorSlotInactive=0 then
                if GameActors[SharedLoopIndexA].ActorRemovalPending=0 then
                  if ActorNearViewport(32,SharedLoopIndexA) or (GameActors[SharedLoopIndexA].ActorKindCode=28)
                    or (GameActors[SharedLoopIndexA].ActorKindCode=21) or (GameActors[SharedLoopIndexB].ActorKindCode=14) then
                    if GameActors[SharedLoopIndexA].FlashFrames>0 then
                    begin
case GameActors[SharedLoopIndexA].ActorSpriteBase of
1..50:
  PgOrShifted16x16(SpriteBank001^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
101: begin
    if GameActors[SharedLoopIndexA].StateValueB=0 then
    begin
      PgOrShifted16x16(SpriteBank101^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-100+
      GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16);
      if GameActors[SharedLoopIndexA].ActorDirectionX<0 then
        PgOrShifted16x16(SpriteBank101^.SpriteEntries[5].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
        GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow)
      else
        PgOrShifted16x16(SpriteBank101^.SpriteEntries[45].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
        GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
    end
    else
    begin
      if GameActors[SharedLoopIndexA].ActorDirectionX<0 then
        PgOrShifted16x16(SpriteBank101^.SpriteEntries[1].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
        GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16)
      else
        PgOrShifted16x16(SpriteBank101^.SpriteEntries[41].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
        GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16);
      PgOrShifted16x16(SpriteBank101^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-96+
      GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
    end;
  end;
102..150:
  PgOrShifted16x16(SpriteBank101^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-100+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
151..200:
  PgOrShifted16x16(SpriteBank151^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-150+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
251..300:
  PgOrShifted16x16(SpriteBank251^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-250+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
301..350:
  PgOrShifted16x16(SpriteBank301^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-300+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
351..400:
  PgOrShifted16x16(SpriteBank351^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-350+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
401..450:
  PgOrShifted16x16(SpriteBank401^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-400+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
451..487:
  PgOrShifted16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-450+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
488..490:
  PgOrShifted16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-450+
  GameActors[SharedLoopIndexA].ActorAnimationCounter shr 3].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
491:
  PgOrShifted16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-450+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
492..494:
  PgOrShifted16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-450+(
  GameActors[SharedLoopIndexA].ActorAnimationCounter-21) shr 3].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
495..500:
  PgOrShifted16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-450+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
501..550:
  PgOrShifted16x16(SpriteBank001^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-500+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
601..650:
  PgOrShifted16x16(SpriteBank601^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-600+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
651..700:
  PgOrShifted16x16(SpriteBank651^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-650+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
701..750:
  PgOrShifted16x16(SpriteBank701^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-700+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
751..800:
  PgOrShifted16x16(SpriteBank751^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-750+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
801: begin
PgOrShifted16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-800+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16);
PgOrShifted16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-796+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
end;
817: begin
    if GameActors[SharedLoopIndexA].StateValueB=0 then
    begin
      PgOrShifted16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-800+
      GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16);
      if GameActors[SharedLoopIndexA].ActorDirectionX<0 then
        PgOrShifted16x16(SpriteBank801^.SpriteEntries[21].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
        GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow)
      else
        PgOrShifted16x16(SpriteBank801^.SpriteEntries[33].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
        GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
    end
    else
    begin
      if GameActors[SharedLoopIndexA].ActorDirectionX<0 then
        PgOrShifted16x16(SpriteBank801^.SpriteEntries[17].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
        GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16)
      else
        PgOrShifted16x16(SpriteBank801^.SpriteEntries[29].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
        GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16);
      PgOrShifted16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-796+
      GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
    end;
  end;
825..828:
  PgOrShifted16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-800+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
837..850:
  PgOrShifted16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-800+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
851: begin
PgOrShifted16x16(SpriteBank851^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-850+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
PgOrShifted16x16(SpriteBank851^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-846+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX+16,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
end;
end;
                      Dec(GameActors[SharedLoopIndexA].FlashFrames);
                    end
                    else if GameActors[SharedLoopIndexA].ActorWorldX and 7 = 0 then
                    begin
case GameActors[SharedLoopIndexA].ActorSpriteBase of
1..50:
  PgBlitMasked16x16(SpriteBank001^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
101: begin
    if GameActors[SharedLoopIndexA].StateValueB=0 then
    begin
      PgBlitMasked16x16(SpriteBank101^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-100+
      GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16);
      if GameActors[SharedLoopIndexA].ActorDirectionX<0 then
        PgBlitMasked16x16(SpriteBank101^.SpriteEntries[5].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX shr
        3,GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow)
      else
        PgBlitMasked16x16(SpriteBank101^.SpriteEntries[45].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX shr
        3,GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
    end
    else
    begin
      if GameActors[SharedLoopIndexA].ActorDirectionX<0 then
        PgBlitMasked16x16(SpriteBank101^.SpriteEntries[1].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX shr
        3,GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16)
      else
        PgBlitMasked16x16(SpriteBank101^.SpriteEntries[41].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX shr
        3,GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16);
      PgBlitMasked16x16(SpriteBank101^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-96+
      GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
    end;
  end;
102..150:
  PgBlitMasked16x16(SpriteBank101^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-100+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
151..200:
  PgBlitMasked16x16(SpriteBank151^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-150+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
251..300:
  PgBlitMasked16x16(SpriteBank251^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-250+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
301..350:
  PgBlitMasked16x16(SpriteBank301^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-300+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
351..400:
  PgBlitMasked16x16(SpriteBank351^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-350+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
401..450:
  PgBlitMasked16x16(SpriteBank401^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-400+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
451..487:
  PgBlitMasked16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-450+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
488..490:
  PgBlitMasked16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-450+
  GameActors[SharedLoopIndexA].ActorAnimationCounter shr 3].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
491:
  PgBlitMasked16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-450+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
492..494:
  PgBlitMasked16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-450+(
  GameActors[SharedLoopIndexA].ActorAnimationCounter-21) shr 3].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
495..500:
  PgBlitMasked16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-450+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
501..550:
  PgBlitMasked16x16(SpriteBank001^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-500+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
601..624:
  PgBlitMasked16x16(SpriteBank601^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-600+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
625:
  PgBlitMasked16x16(SpriteBank601^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-600+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 3].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
626..650:
  PgBlitMasked16x16(SpriteBank601^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-600+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
651..700:
  PgBlitMasked16x16(SpriteBank651^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-650+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
701..750:
  PgBlitMasked16x16(SpriteBank701^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-700+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
751..800:
  PgBlitMasked16x16(SpriteBank751^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-750+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
801: begin
PgBlitMasked16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-800+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX shr 3,
      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16);
PgBlitMasked16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-796+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
end;
817: begin
    if GameActors[SharedLoopIndexA].StateValueB=0 then
    begin
      PgBlitMasked16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-800+
      GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16);
      if GameActors[SharedLoopIndexA].ActorDirectionX<0 then
        PgBlitMasked16x16(SpriteBank801^.SpriteEntries[21].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX shr
        3,GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow)
      else
        PgBlitMasked16x16(SpriteBank801^.SpriteEntries[33].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX shr
        3,GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
    end
    else
    begin
      if GameActors[SharedLoopIndexA].ActorDirectionX<0 then
        PgBlitMasked16x16(SpriteBank801^.SpriteEntries[17].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX shr
        3,GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16)
      else
        PgBlitMasked16x16(SpriteBank801^.SpriteEntries[29].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX shr
        3,GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16);
      PgBlitMasked16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-796+
      GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
    end;
  end;
825..828:
  PgBlitMasked16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-800+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
837..850:
  PgBlitMasked16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-800+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
851: begin
PgBlitMasked16x16(SpriteBank851^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-850+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
PgBlitMasked16x16(SpriteBank851^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-846+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX shr 3+2,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
end;
end;
                    end
                    else
                    begin
case GameActors[SharedLoopIndexA].ActorSpriteBase of
1..50:
  PgBlitMaskedShifted16x16(SpriteBank001^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
101: begin
    if GameActors[SharedLoopIndexA].StateValueB=0 then
    begin
      PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-100+
      GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16);
      if GameActors[SharedLoopIndexA].ActorDirectionX<0 then
        PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[5].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
        GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow)
      else
        PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[45].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
        GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
    end
    else
    begin
      if GameActors[SharedLoopIndexA].ActorDirectionX<0 then
        PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[1].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
        GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16)
      else
        PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[41].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
        GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16);
      PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-96+
      GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
    end;
  end;
102..150:
  PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-100+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
151..200:
  PgBlitMaskedShifted16x16(SpriteBank151^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-150+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
251..300:
  PgBlitMaskedShifted16x16(SpriteBank251^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-250+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
301..350:
  PgBlitMaskedShifted16x16(SpriteBank301^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-300+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
351..400:
  PgBlitMaskedShifted16x16(SpriteBank351^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-350+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
401..450:
  PgBlitMaskedShifted16x16(SpriteBank401^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-400+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
451..487:
  PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-450+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
488..490:
  PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-450+
  GameActors[SharedLoopIndexA].ActorAnimationCounter shr 3].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
491:
  PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-450+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
492..494:
  PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-450+(
  GameActors[SharedLoopIndexA].ActorAnimationCounter-21) shr 3].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
495..500:
  PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-450+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
501..550:
  PgBlitMaskedShifted16x16(SpriteBank001^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-500+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
601..650:
  PgBlitMaskedShifted16x16(SpriteBank601^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-600+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
      GameActors[SharedLoopIndexA].ActorWorldX,GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
651..700:
  PgBlitMaskedShifted16x16(SpriteBank651^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-650+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
701..750:
  PgBlitMaskedShifted16x16(SpriteBank701^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-700+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
751..800:
  PgBlitMaskedShifted16x16(SpriteBank751^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-750+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
801: begin
PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-800+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16);
PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-796+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
end;
817: begin
    if GameActors[SharedLoopIndexA].StateValueB=0 then
    begin
      PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-800+
      GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16);
      if GameActors[SharedLoopIndexA].ActorDirectionX<0 then
        PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[21].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
        GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow)
      else
        PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[33].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
        GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
    end
    else
    begin
      if GameActors[SharedLoopIndexA].ActorDirectionX<0 then
        PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[17].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
        GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16)
      else
        PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[29].SpriteDataBytes[1],GameActors[SharedLoopIndexA].ActorWorldX,
        GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow-16);
      PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-796+
      GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
    end;
  end;
825..828:
  PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-800+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
837..850:
  PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-800+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,

      GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
851: begin
PgBlitMaskedShifted16x16(SpriteBank851^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-850+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
PgBlitMaskedShifted16x16(SpriteBank851^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase-846+
  GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
    GameActors[SharedLoopIndexA].ActorWorldX+16,
    GameActors[SharedLoopIndexA].ActorWorldY+GameDrawBufferRow);
end;
end;
                    end;

  DrawCellForeground(GameActors[1].ActorPreviousX-16,GameActors[1].ActorPreviousY-16);
  DrawCellForeground(GameActors[1].ActorPreviousX-16,GameActors[1].ActorPreviousY);
  DrawCellForeground(GameActors[1].ActorPreviousX-16,GameActors[1].ActorPreviousY+16);
  DrawCellForeground(GameActors[1].ActorPreviousX,GameActors[1].ActorPreviousY-16);
  DrawCellForeground(GameActors[1].ActorPreviousX,GameActors[1].ActorPreviousY);
  DrawCellForeground(GameActors[1].ActorPreviousX,GameActors[1].ActorPreviousY+16);
  DrawCellForeground(GameActors[1].ActorPreviousX+16,GameActors[1].ActorPreviousY-16);
  DrawCellForeground(GameActors[1].ActorPreviousX+16,GameActors[1].ActorPreviousY);
  DrawCellForeground(GameActors[1].ActorPreviousX+16,GameActors[1].ActorPreviousY+16);
for SharedLoopIndexA := 2 to 25 do
  if GameActors[SharedLoopIndexA].ActorSlotInactive=0 then
    if GameActors[SharedLoopIndexA].ActorRemovalPending<>0 then
    begin
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX,GameActors[SharedLoopIndexA].ActorPreviousY);
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX-16,GameActors[SharedLoopIndexA].ActorPreviousY);
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX+16,GameActors[SharedLoopIndexA].ActorPreviousY);
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX-16,GameActors[SharedLoopIndexA].ActorPreviousY-16);
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX-16,GameActors[SharedLoopIndexA].ActorPreviousY+16);
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX+16,GameActors[SharedLoopIndexA].ActorPreviousY-16);
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX+16,GameActors[SharedLoopIndexA].ActorPreviousY+16);
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX,GameActors[SharedLoopIndexA].ActorPreviousY-16);
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX,GameActors[SharedLoopIndexA].ActorPreviousY+16);
    end
    else if ActorNearViewport(32,SharedLoopIndexA) or (GameActors[SharedLoopIndexA].ActorKindCode=28) or
    (GameActors[SharedLoopIndexA].ActorKindCode=27)
      or (GameActors[SharedLoopIndexA].ActorKindCode=21) or (GameActors[SharedLoopIndexB].ActorKindCode=14) then
    begin
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX,GameActors[SharedLoopIndexA].ActorWorldY);
      if GameActors[SharedLoopIndexA].ActorWorldX and 15>0 then
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX+15,GameActors[SharedLoopIndexA].ActorWorldY);
      if GameActors[SharedLoopIndexA].ActorKindCode=27 then
      begin
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX,GameActors[SharedLoopIndexA].ActorWorldY-16);
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX+16,GameActors[SharedLoopIndexA].ActorWorldY-16);
      end
      else
        case GameActors[SharedLoopIndexA].ActorSpriteBase of
          851: begin
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX+48,GameActors[SharedLoopIndexA].ActorWorldY);
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX+32,GameActors[SharedLoopIndexA].ActorWorldY);
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX+16,GameActors[SharedLoopIndexA].ActorWorldY);
          end;
          801..899,5001: begin
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX,GameActors[SharedLoopIndexA].ActorWorldY-16);
            if GameActors[SharedLoopIndexA].ActorWorldX and 15>0 then
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX+15,GameActors[SharedLoopIndexA].ActorWorldY-16);
          end;
          114: begin
            if GameActors[SharedLoopIndexA].ActorWorldY>15 then
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX,GameActors[SharedLoopIndexA].ActorWorldY-16);
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX,GameActors[SharedLoopIndexA].ActorWorldY+16);
            if GameActors[SharedLoopIndexA].ActorWorldX and 15>0 then
            begin
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX+15,GameActors[SharedLoopIndexA].ActorWorldY+16);
              if GameActors[SharedLoopIndexA].ActorWorldY>15 then
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX+15,GameActors[SharedLoopIndexA].ActorWorldY-16);
            end;
          end;
          101: begin
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX,GameActors[SharedLoopIndexA].ActorWorldY-16);
            if GameActors[SharedLoopIndexA].ActorWorldX and 15>0 then
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX+15,GameActors[SharedLoopIndexA].ActorWorldY-16);
          end;
        end;
    end
    else if (GameActors[SharedLoopIndexA].ActorKindCode=7) or (GameActors[SharedLoopIndexA].ActorKindCode=14) or
    (GameActors[SharedLoopIndexA].ActorKindCode=19)
      or (GameActors[SharedLoopIndexA].ActorKindCode=5000) then
    begin
      GameActors[SharedLoopIndexA].ActorRemovalPending := 1;
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX,GameActors[SharedLoopIndexA].ActorWorldY);
      if GameActors[SharedLoopIndexA].ActorWorldX and 15>0 then
      begin
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX+15,GameActors[SharedLoopIndexA].ActorWorldY);
  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX-15,GameActors[SharedLoopIndexA].ActorWorldY);
      end;
    end;
if PlayerDying<>0 then
  PgBlitMaskedShifted16x16(PlayerSpriteBank^.SpriteEntries[GameActors[1].ActorAnimationCounter div
  5+GameActors[1].ActorSpriteBase].SpriteDataBytes[1],
    GameActors[1].ActorWorldX,GameActors[1].ActorWorldY+GameDrawBufferRow);

            ShowGameDrawBuffer;
            if ConfusionEndedMessagePending <> 0 then
            begin
              ConfusionEndedMessagePending := 0;
              ShowGameMessage('YOU FEEL LESS CONFUSED');
            end;
            if GameOptionsRequested <> 0 then
            begin
              GameMenuResult := Ord(RunGameOptionsMenu);
              GameOptionsRequested := 0;
            end;
            if RestoreSnapshotRequested <> 0 then
            begin
              FadeGamePaletteToBlack(20);
              if PlayerAmmo < 15 then PlayerAmmo := 15;
              LevelCompletedFlags[EnteredLevelNumber] := 0;
              if PlayerDying = 0 then CurrentLevelNumber := 1;
              ResetLevelTransientState;
              RestoreGameSnapshot;
              LoadLevelMap(CurrentLevelNumber);
              StatusBarCameraX := -1;
            end;
            if WarpLevelRequested <> 0 then
            begin
              WarpLevelRequested := 0;
              SharedLoopIndexA := AskWarpLevel;
              if (SharedLoopIndexA >= 1) and (SharedLoopIndexA <= 16) then
              begin
                CurrentLevelNumber := SharedLoopIndexA+1;
                FadeGamePaletteToBlack(20);
                LevelCompletedFlags[EnteredLevelNumber] := 0;
                RestoreGameSnapshot;
                LoadLevelMap(CurrentLevelNumber);
                ResetLevelTransientState;
                StatusBarCameraX := -1;
              end;
            end;
            if GodModeMessagePending <> 0 then
            begin
              GodModeMessagePending := 0;
              if PlayerGodMode <> 0 then ShowGameMessage('GOD Mode On')
              else ShowGameMessage('GOD Mode Off');
            end;
          end;
        end;
      end;
      if EpisodeBlueprintCollected <> 0 then ShowEpisodeEnding;
    end;
    FadeGamePaletteToBlack(20);
    PgSetBiosVideoMode(3);
    if SoundEnabled <> 0 then
      while SoundPlaying <> 0 do;
    NoSound;
    ShowDosExitScreen;
    RestoreDefaultTimer;
    RestoreGameInterrupts;
    SyncDosClockFromCmos;
    SaveGameConfig;
  end
  else
  begin
    PgSetBiosVideoMode(3);
{$IFDEF SAM1}
    Writeln('This game requires and EGA or VGA Adapter!');
{$ELSE}
    Writeln('This game requires an EGA or VGA Adapter!');
{$ENDIF}
    NoSound;
  end;
end.
