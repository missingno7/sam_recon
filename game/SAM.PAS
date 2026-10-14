{ Secret Agent program: installs input/timer handlers, loads configuration,
  and runs the game loop and scene transitions. }
program SAMMAIN;
{$M 16384,0,655360}
{$A+}{$D+}{$L+}{$F-}
uses Dos, PROGRPHX, Crt, SAMDATA, SAMSOUND, GAMEJOY, PCXGENUS, TEXT80, SAMUI, SAMLEVEL, SAMPLAY;
const
  { Installed interrupt vectors and startup-only BIOS video-query selectors. }
  SamKeyboardVector = $09;
  SamTimerVector = $1C;
  SamBiosReadVideoMode = $0F;
  SamBiosVideoModeMask = $7F;
  SamBiosDisplayCombination = $1A00;
  SamBiosDisplayCombinationReply = $1A;
  SamBiosEgaInformation = $12;
  SamBiosEgaInformationSelector = $10;
  SamBiosEgaAdapter = 3;
  SamBiosVgaAdapter = 4;

  { Input thresholds, timer periods and startup resource limits. }
  SamJoystickDeadZone = 50;
  SamFrameTickThreshold = 7;
  SamPowerupTickPeriod = 20;
  SamExtraAmmoAmount = 25;
  SamMinimumFreeHeap = 200000;

  { Split-screen positions and actor redraw margins. }
  SamVgaStatusSplit = 384;
  SamEgaStatusSplit = 190;
  SamActorEraseMargin = 40;
  SamActorDrawMargin = 32;

var
  { Only element 0 divides power-up ticks; unused element 1 retains DATA layout. }
  PowerupTimerSubticks: array[0..1] of Byte;
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
  LastKeyboardScanCode := Port[GameKeyboardDataPort];
  if PlayerControlsReversed = 1 then
  begin
    if LastKeyboardScanCode = Integer(LeftKeyScanCode) then
      LastKeyboardScanCode := Integer(RightKeyScanCode)
    else if Integer(LeftKeyScanCode) + GameScanCodeBreakMask = LastKeyboardScanCode then
      LastKeyboardScanCode := Integer(RightKeyScanCode) + GameScanCodeBreakMask
    else if LastKeyboardScanCode = Integer(RightKeyScanCode) then
      LastKeyboardScanCode := Integer(LeftKeyScanCode)
    else if Integer(RightKeyScanCode) + GameScanCodeBreakMask = LastKeyboardScanCode then
      LastKeyboardScanCode := Integer(LeftKeyScanCode) + GameScanCodeBreakMask;
  end;

  if PlayerInputLocked = 0 then
  begin
    if LastKeyboardScanCode = Integer(LeftKeyScanCode) then
    begin
      PlayerLeftHeld := 1;
      PlayerRightHeld := 0;
      PlayerOnMovingSupport := 0;
      GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkLeft;
      if PlayerJumping <> 0 then
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteJumpLeft;
    end
    else if Integer(LeftKeyScanCode) + GameScanCodeBreakMask = LastKeyboardScanCode then
    begin
      PlayerLeftHeld := 0;
      if PlayerJumping = 0 then
      begin
        if PlayerRightHeld = 0 then
          GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteStandLeft
        else
          GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkRight;
      end
      else if PlayerRightHeld = 1 then
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteJumpRight
      else
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteJumpLeft;
    end
    else if LastKeyboardScanCode = Integer(RightKeyScanCode) then
    begin
      PlayerRightHeld := 1;
      PlayerLeftHeld := 0;
      PlayerOnMovingSupport := 0;
      GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkRight;
      if PlayerJumping <> 0 then
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteJumpRight;
    end
    else if Integer(RightKeyScanCode) + GameScanCodeBreakMask = LastKeyboardScanCode then
    begin
      PlayerRightHeld := 0;
      if PlayerJumping = 0 then
      begin
        if PlayerLeftHeld = 0 then
          GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteStandRight
        else
          GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkLeft;
      end
      else if PlayerLeftHeld = 1 then
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteJumpLeft
      else
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteJumpRight;
    end
    else if LastKeyboardScanCode = Integer(FireKeyScanCode) then
    begin
      if PlayerAmmo = 0 then
        StartSoundEffect(GameSfxEmptyWeapon)
      else if PlayerAmmo > 0 then
      begin
        if PlayerDying = 0 then
        begin
          if CurrentLevelNumber > GameIslandLevelNumber then
          begin
            ShotSpawned := 0;
            ShotSlot := 0;
            repeat
              Inc(ShotSlot);
              if PlayerShots[ShotSlot].ActorSlotInactive = 1 then
              begin
                PlayerShots[ShotSlot].ActorWorldX := GameActors[GamePlayerActorSlot].ActorWorldX;
                PlayerShots[ShotSlot].ActorWorldY := GameActors[GamePlayerActorSlot].ActorWorldY;
                PlayerShots[ShotSlot].ActorPreviousX := GameActors[GamePlayerActorSlot].ActorPreviousX;
                PlayerShots[ShotSlot].ActorPreviousY := GameActors[GamePlayerActorSlot].ActorPreviousY;
                PlayerShots[ShotSlot].ActorSpriteBase := GamePlayerShotSprite;
                if (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteWalkRight) or
                  (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteJumpRight) or
                  (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteStandRight) or
                  (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteFireRight) then
                begin
                  PlayerShots[ShotSlot].ActorDirectionX := 1;
                  GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteFireRight;
                end
                else
                begin
                  PlayerShots[ShotSlot].ActorDirectionX := -1;
                  GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteFireLeft;
                end;
                PlayerShots[ShotSlot].DirectionY := 0;
                PlayerShots[ShotSlot].ActorAnimationCounter := 1;
                PlayerShots[ShotSlot].ActorMovementStep := GamePlayerShotStep;
                PlayerShots[ShotSlot].ActorCounterA := 0;
                PlayerShots[ShotSlot].ActorCounterB := 0;
                PlayerShots[ShotSlot].ActorKindCode := GamePlayerShotKind;
                PlayerShots[ShotSlot].ActorSlotInactive := 0;
                PlayerShots[ShotSlot].ActorRemovalPending := 0;
                ShotSpawned := 1;
                Dec(PlayerAmmo);
                StatusBarCameraX := -1;
                StartSoundEffect(GameSfxPlayerShot);
                if (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteWalkRight) or
                  (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteStandRight) or
                  (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteJumpRight) or
                  (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteFireRight) then
                  GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteFireRight
                else
                  GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteFireLeft;
              end;
            until (ShotSlot = PlayerProjectileLimit) or (ShotSpawned <> 0);
          end;
        end;
      end;
    end
    else if Integer(FireKeyScanCode) + GameScanCodeBreakMask = LastKeyboardScanCode then
    begin
      if GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteFireRight then
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteStandRight
      else if GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteFireLeft then
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteStandLeft;
    end
    else if LastKeyboardScanCode = Integer(JumpKeyScanCode) then
    begin
      PlayerJumpHeld := 1;
    end
    else if Integer(JumpKeyScanCode) + GameScanCodeBreakMask = LastKeyboardScanCode then
    begin
      PlayerJumpHeld := 0;
    end
    else if LastKeyboardScanCode = Integer(UpKeyScanCode) then
    begin
      if CurrentLevelNumber = GameIslandLevelNumber then
      begin
        PlayerUpHeld := 1;
        PlayerDownHeld := 0;
        if (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteWalkRight) or
          (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteStandRight) or
          (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteFireRight) then
          GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkRight
        else
          GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkLeft;
      end;
    end
    else if Integer(UpKeyScanCode) + GameScanCodeBreakMask = LastKeyboardScanCode then
    begin
      if CurrentLevelNumber = GameIslandLevelNumber then
      begin
        PlayerUpHeld := 0;
        if (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteWalkRight) or
          (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteStandRight) or
          (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteFireRight) then
          GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteStandRight
        else
          GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteStandLeft;
      end;
    end
    else if LastKeyboardScanCode = Integer(DownKeyScanCode) then
    begin
      if CurrentLevelNumber = GameIslandLevelNumber then
      begin
        PlayerDownHeld := 1;
        PlayerUpHeld := 0;
        if (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteWalkRight) or
          (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteStandRight) or
          (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteFireRight) then
          GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkRight
        else
          GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkLeft;
      end;
    end
    else if Integer(DownKeyScanCode) + GameScanCodeBreakMask = LastKeyboardScanCode then
    begin
      if CurrentLevelNumber = GameIslandLevelNumber then
      begin
        PlayerDownHeld := 0;
        if (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteWalkRight) or
          (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteStandRight) or
          (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteFireRight) then
          GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteStandRight
        else
          GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteStandLeft;
      end;
    end
    else if LastKeyboardScanCode = GameScanCodeEscape then
    begin
      EscapePressed := 1;
      GameOptionsRequested := 1;
    end
    else if LastKeyboardScanCode = GameScanCodeQ then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = GameScanCodeF1 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = GameScanCodeF2 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = GameScanCodeF3 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = GameScanCodeF4 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = GameScanCodeF5 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = GameScanCodeF6 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = GameScanCodeF7 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = GameScanCodeF8 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = GameScanCodeF9 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = GameScanCodeF10 then
      GameOptionsRequested := 1
    else if LastKeyboardScanCode = GameScanCodeU then
    begin
      AmmoChordUHeld := 1;
      if (AmmoChordVHeld <> 0) and (AmmoChordKHeld <> 0) and (ExtraAmmoCheatUsed = 0) then
      begin
        PlayerAmmo := PlayerAmmo + SamExtraAmmoAmount;
        ExtraAmmoCheatUsed := 1;
        StatusBarCameraX := -1;
      end;
    end
    else if LastKeyboardScanCode = GameScanCodeURelease then
      AmmoChordUHeld := 0
    else if LastKeyboardScanCode = GameScanCodeV then
    begin
      AmmoChordVHeld := 1;
      if (AmmoChordUHeld <> 0) and (AmmoChordKHeld <> 0) and (ExtraAmmoCheatUsed = 0) then
      begin
        PlayerAmmo := PlayerAmmo + SamExtraAmmoAmount;
        ExtraAmmoCheatUsed := 1;
        StatusBarCameraX := -1;
      end;
    end
    else if LastKeyboardScanCode = GameScanCodeVRelease then
      AmmoChordVHeld := 0
    else if LastKeyboardScanCode = GameScanCodeK then
    begin
      AmmoChordKHeld := 1;
      if (AmmoChordUHeld <> 0) and (AmmoChordVHeld <> 0) and (ExtraAmmoCheatUsed = 0) then
      begin
        PlayerAmmo := PlayerAmmo + SamExtraAmmoAmount;
        ExtraAmmoCheatUsed := 1;
        StatusBarCameraX := -1;
      end;
    end
    else if LastKeyboardScanCode = GameScanCodeKRelease then
      AmmoChordKHeld := 0
    else if LastKeyboardScanCode = GameScanCodeZ then
    begin
      InventoryChordZHeld := 1;
      if (InventoryChordGHeld <> 0) and (InventoryChordIHeld <> 0) then
      begin
        PlayerHasFloppyDisk := 1;
        PlayerHasDynamite := 1;
        StatusBarCameraX := -1;
      end;
    end
    else if LastKeyboardScanCode = GameScanCodeZRelease then
      InventoryChordZHeld := 0
    else if LastKeyboardScanCode = GameScanCodeG then
    begin
      InventoryChordGHeld := 1;
      if (InventoryChordZHeld <> 0) and (InventoryChordIHeld <> 0) then
      begin
        PlayerHasFloppyDisk := 1;
        PlayerHasDynamite := 1;
        StatusBarCameraX := -1;
      end;
    end
    else if LastKeyboardScanCode = GameScanCodeGRelease then
      InventoryChordGHeld := 0
    else if LastKeyboardScanCode = GameScanCodeI then
    begin
      InventoryChordIHeld := 1;
      if (InventoryChordGHeld <> 0) and (InventoryChordZHeld <> 0) then
      begin
        PlayerHasFloppyDisk := 1;
        PlayerHasDynamite := 1;
        StatusBarCameraX := -1;
      end;
    end
    else if LastKeyboardScanCode = GameScanCodeIRelease then
      InventoryChordIHeld := 0
    else if LastKeyboardScanCode = GameScanCodeP then
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
    else if LastKeyboardScanCode = GameScanCodePRelease then
    begin
      GodChordPHeld := 0;
      LevelCheatPBHeld := 0;
    end
    else if LastKeyboardScanCode = GameScanCodeJ then
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
    else if LastKeyboardScanCode = GameScanCodeJRelease then
      GodChordJHeld := 0
    else if LastKeyboardScanCode = GameScanCodeX then
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
    else if LastKeyboardScanCode = GameScanCodeB then
      LevelCheatPBHeld := 1
    else if LastKeyboardScanCode = GameScanCodeBRelease then
      LevelCheatPBHeld := 0
    else if LastKeyboardScanCode = GameScanCodeXRelease then
      GodChordXHeld := 0
    else if LastKeyboardScanCode = GameScanCodeO then
    begin
      WarpChordOHeld := 1;
      if (LevelCheatPBHeld <> 0) and (WarpChordNHeld <> 0) and (WarpChordDHeld <> 0) then
        WarpLevelRequested := 1;
    end
    else if LastKeyboardScanCode = GameScanCodeORelease then
      WarpChordOHeld := 0
    else if LastKeyboardScanCode = GameScanCodeN then
    begin
      WarpChordNHeld := 1;
      if (WarpChordOHeld <> 0) and (LevelCheatPBHeld <> 0) and (WarpChordDHeld <> 0) then
        WarpLevelRequested := 1;
    end
    else if LastKeyboardScanCode = GameScanCodeNRelease then
      WarpChordNHeld := 0
    else if LastKeyboardScanCode = GameScanCodeD then
    begin
      WarpChordDHeld := 1;
      if (WarpChordOHeld <> 0) and (WarpChordNHeld <> 0) and (LevelCheatPBHeld <> 0) then
        WarpLevelRequested := 1;
    end
    else if LastKeyboardScanCode = GameScanCodeDRelease then
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
    if GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteFireRight then
      GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteStandRight
    else if GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteFireLeft then
      GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteStandLeft;
  end;
  if JoystickCenterX - SamJoystickDeadZone > JoystickAxisX then
  begin
    PlayerLeftHeld := 1;
    PlayerRightHeld := 0;
    PlayerOnMovingSupport := 0;
    JoystickHorizontalMoved := 1;
    if (PlayerJumping = 0) and (PlayerFalling = 0) then
      GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkLeft
    else
      GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteJumpLeft;
  end
  else if JoystickCenterX + SamJoystickDeadZone < JoystickAxisX then
  begin
    PlayerRightHeld := 1;
    PlayerLeftHeld := 0;
    PlayerOnMovingSupport := 0;
    JoystickHorizontalMoved := 1;
    if (PlayerJumping = 0) and (PlayerFalling = 0) then
      GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkRight
    else
      GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteJumpRight;
  end
  else if JoystickHorizontalMoved <> 0 then
  begin
    if (PlayerRightHeld = 1) or (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteWalkRight) then
      GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteStandRight
    else
      GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteStandLeft;
    PlayerRightHeld := 0;
    PlayerLeftHeld := 0;
    JoystickHorizontalMoved := 0;
  end;

  if CurrentLevelNumber = GameIslandLevelNumber then
  begin
    if JoystickCenterY - SamJoystickDeadZone > JoystickAxisY then
    begin
      PlayerUpHeld := 1;
      JoystickVerticalMoved := 1;
      if (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteWalkRight) or
        (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteStandRight) or
        (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteFireRight) then
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkRight
      else
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkLeft;
    end
    else if JoystickCenterY + SamJoystickDeadZone < JoystickAxisY then
    begin
      PlayerDownHeld := 1;
      JoystickVerticalMoved := 1;
      if (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteWalkRight) or
        (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteStandRight) or
        (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteFireRight) then
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkRight
      else
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkLeft;
    end
    else if JoystickVerticalMoved <> 0 then
    begin
      JoystickVerticalMoved := 0;
      PlayerUpHeld := 0;
      PlayerDownHeld := 0;
      if (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteWalkRight) or
        (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteStandRight) or
        (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteFireRight) then
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteStandRight
      else
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteStandLeft;
    end;
  end;

  if not IsJoystickButton1Pressed then
    Exit;
  if PlayerAmmo <= 0 then
    Exit;
  if CurrentLevelNumber <= GameIslandLevelNumber then
    Exit;
  if PlayerDying <> 0 then
    Exit;

  ShotSpawned := 0;
  ShotSlot := 0;
  repeat
    Inc(ShotSlot);
    if PlayerShots[ShotSlot].ActorSlotInactive = 1 then
    begin
      PlayerShots[ShotSlot].ActorWorldX := GameActors[GamePlayerActorSlot].ActorWorldX;
      PlayerShots[ShotSlot].ActorWorldY := GameActors[GamePlayerActorSlot].ActorWorldY;
      PlayerShots[ShotSlot].ActorPreviousX := GameActors[GamePlayerActorSlot].ActorPreviousX;
      PlayerShots[ShotSlot].ActorPreviousY := GameActors[GamePlayerActorSlot].ActorPreviousY;
      PlayerShots[ShotSlot].ActorSpriteBase := GamePlayerShotSprite;
      if (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteWalkRight) or
        (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteJumpRight) or
        (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteStandRight) or
        (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteFireRight) then
      begin
        PlayerShots[ShotSlot].ActorDirectionX := 1;
        JoystickFirePosePending := 1;
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteFireRight;
      end
      else
      begin
        PlayerShots[ShotSlot].ActorDirectionX := -1;
        JoystickFirePosePending := 1;
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteFireLeft;
      end;
      PlayerShots[ShotSlot].DirectionY := 0;
      PlayerShots[ShotSlot].ActorAnimationCounter := 1;
      PlayerShots[ShotSlot].ActorMovementStep := GamePlayerShotStep;
      PlayerShots[ShotSlot].ActorCounterA := 0;
      PlayerShots[ShotSlot].ActorCounterB := 0;
      PlayerShots[ShotSlot].ActorKindCode := GamePlayerShotKind;
      PlayerShots[ShotSlot].ActorSlotInactive := 0;
      PlayerShots[ShotSlot].ActorRemovalPending := 0;
      ShotSpawned := 1;
      Dec(PlayerAmmo);
      StatusBarCameraX := -1;
      StartSoundEffect(GameSfxPlayerShot);
      if (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteWalkRight) or
        (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteStandRight) or
        (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteJumpRight) or
        (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteFireRight) then
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteFireRight
      else
        GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteFireLeft;
    end;
  until (ShotSlot = PlayerProjectileLimit) or (ShotSpawned <> 0);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F-}
{ INT 1Ch handler increments timing counters, expires speed/confusion/slow effects and advances PC-speaker. }
procedure TimerInterrupt; interrupt;
begin
  { CLI protects the shared timer/sound state; STI below restores interrupts. }
  inline($FA);
  Inc(GameTickCounter);
  Inc(PowerupTimerSubticks[0]);
  if PowerupTimerSubticks[0] = SamPowerupTickPeriod then
  begin
    PowerupTimerSubticks[0] := 0;
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
      1 .. GameSoundEffectsPerBank:
        begin
          Sound(SoundBankOne^[CurrentSoundEffect, SoundSampleIndex]);
          Inc(SoundSampleIndex);
          if SoundSampleIndex mod SoundBankOne^[CurrentSoundEffect, GameSoundGatePeriodColumn] = 0 then
            NoSound;
          if SoundBankOne^[CurrentSoundEffect, SoundSampleIndex] = GameSoundEndMarker then
          begin
            SoundPlaying := 0;
            SoundSampleIndex := 1;
            NoSound;
          end;
        end;
      GameSoundBankTwoFirstEffect .. GameSoundBankTwoLastEffect:
        begin
          Sound(SoundBankTwo^[CurrentSoundEffect - GameSoundEffectsPerBank, SoundSampleIndex]);
          Inc(SoundSampleIndex);
          if SoundSampleIndex mod SoundBankTwo^[CurrentSoundEffect - GameSoundEffectsPerBank, GameSoundGatePeriodColumn] = 0
            then
            NoSound;
          if SoundBankTwo^[CurrentSoundEffect - GameSoundEffectsPerBank, SoundSampleIndex] = GameSoundEndMarker then
          begin
            SoundPlaying := 0;
            SoundSampleIndex := 1;
            NoSound;
          end;
        end;
      GameSoundBankThreeFirstEffect .. GameSoundBankThreeLastEffect:
        begin
          Sound(SoundBankThree^[CurrentSoundEffect - GameSoundBankTwoLastEffect, SoundSampleIndex]);
          Inc(SoundSampleIndex);
          if SoundSampleIndex mod SoundBankThree^[CurrentSoundEffect - GameSoundBankTwoLastEffect,
            GameSoundGatePeriodColumn] = 0 then
            NoSound;
          if SoundBankThree^[CurrentSoundEffect - GameSoundBankTwoLastEffect, SoundSampleIndex] = GameSoundEndMarker then
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
  SetIntVec(SamTimerVector, SavedTimerVector);
  SetIntVec(SamKeyboardVector, SavedKeyboardVector);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F-}
{ Saves ExitProc/INT 1Ch/INT 9 and installs RestoreExitHandlers, TimerInterrupt and KeyboardInterrupt. }
procedure InstallGameHandlers;
begin
  SavedExitProc := ExitProc;
  ExitProc := @RestoreExitHandlers;
  GetIntVec(SamTimerVector, SavedTimerVector);
  SetIntVec(SamTimerVector, @TimerInterrupt);
  GetIntVec(SamKeyboardVector, SavedKeyboardVector);
  SetIntVec(SamKeyboardVector, @KeyboardInterrupt);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F-}
{ Restores only the two saved timer and keyboard interrupt vectors. }
procedure RestoreGameInterrupts;
begin
  SetIntVec(SamTimerVector, SavedTimerVector);
  SetIntVec(SamKeyboardVector, SavedKeyboardVector);
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
  { The original retries Reset without closing; keep both attempts and IOResult reads. }
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
    UpKeyScanCode := GameScanCodeUp;
    DownKeyScanCode := GameScanCodeDown;
    LeftKeyScanCode := GameScanCodeLeft;
    RightKeyScanCode := GameScanCodeRight;
    JumpKeyScanCode := GameScanCodeControl;
    FireKeyScanCode := GameScanCodeAlt;
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
  VideoBiosRegisters.AH := SamBiosReadVideoMode;
  Intr(GameVideoBiosInterrupt, Registers(VideoBiosRegisters));
  DetectedBiosVideoMode := VideoBiosRegisters.AL and SamBiosVideoModeMask;
  VideoBiosRegisters.AX := SamBiosDisplayCombination;
  Intr(GameVideoBiosInterrupt, Registers(VideoBiosRegisters));
  if VideoBiosRegisters.AL = SamBiosDisplayCombinationReply then
  begin
    if VideoBiosRegisters.BL <> $FF then
      DetectedVideoAdapter := BiosAdapterClassMap[VideoBiosRegisters.BL];
  end
  else
  begin
    VideoBiosRegisters.AH := SamBiosEgaInformation;
    VideoBiosRegisters.BL := SamBiosEgaInformationSelector;
    Intr(GameVideoBiosInterrupt, Registers(VideoBiosRegisters));
    if VideoBiosRegisters.BL <> SamBiosEgaInformationSelector then
      DetectedVideoAdapter := SamBiosEgaAdapter;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$ENDIF}
{ Startup, resource loading, island/mission transitions and the main game loop. }
begin
  if MemAvail < SamMinimumFreeHeap then
  begin
    Writeln('Secret Agent Requires 450k free Memory to run!');
    Halt;
  end;
{$IFDEF SAM1}
  if DetectGameVideoAdapter <> 'U' then
{$ELSE}
  DetectBiosVideoAdapter;
  if (DetectedVideoAdapter = SamBiosEgaAdapter) or (DetectedVideoAdapter = SamBiosVgaAdapter) then
{$ENDIF}
  begin
    InstallGameHandlers;
    SetFastGameTimer;
    SoundPlaying := 0;
    GetMem(SoundBankOne, GameSoundBankBytes);
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
    DecryptGameAssetBuffer(SoundBankOne^, GameSoundBankBytes);
    Close(SoundResourceFile);
    GetMem(SoundBankTwo, GameSoundBankBytes);
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
    DecryptGameAssetBuffer(SoundBankTwo^, GameSoundBankBytes);
    Close(SoundResourceFile);
    GetMem(SoundBankThree, GameSoundBankBytes);
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
    DecryptGameAssetBuffer(SoundBankThree^, GameSoundBankBytes);
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
    { Allocate and decode resources before entering the title/game scene loop. }
    LoadGameConfig;
    Writeln('Decompressing Graphics Files...');
    LoadGameSpriteBanks;
    PgSetToolboxVideoMode(0);
    ShowApogeeSplash;
    while QuitGameRequested = 0 do
    begin
      PgSetToolboxVideoMode(0);
      ShowTitleAndCredits;
      if QuitGameRequested = 0 then
        ResetNewGameState;
      if (QuitGameRequested = 0) and (ReturnToTitleRequested = 0) then
      begin
        UnusedScreenStrideResult := PgSetScreenStride(GameVideoStrideBytes);
        PgSetBorderColor(4);
        BlackenGamePalette;
        if AlternateVideoTiming = 0 then
          PgPanDisplayAtRetraceStart(0, GamePlayfieldTopBufferRow)
        else
          PgPanDisplayAtRetraceEnd(0, GamePlayfieldTopBufferRow);
        ResetLevelTransientState;
        if PendingRestoreScanCode <> 0 then
        begin
          case PendingRestoreScanCode of
            2 .. 10:
              if ReadSavedGame(PendingRestoreScanCode - 1) then;
            11:
              if ReadSavedGame(0) then;
          end;
          PendingRestoreScanCode := 0;
        end;
        LoadLevelMap(1);
{$IFDEF SAM1}
        if DetectGameVideoAdapter = 'V' then
{$ELSE}
        if DetectedVideoAdapter = SamBiosVgaAdapter then
{$ENDIF}
          PgSetVgaSplitScanline(SamVgaStatusSplit)
        else
          PgSetEgaSplitScanline(SamEgaStatusSplit);
        while (QuitGameRequested = 0) and (ReturnToTitleRequested = 0) do
        begin
          if StatusBarCameraX <> CameraX then
            DrawGameStatusBar;
          if GameTickCounter > SamFrameTickThreshold then
          begin
            GameTickCounter := 0;
            if JoystickActive then
              PollJoystickControls;
            if (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteStandRight) and (PlayerRightHeld <> 0) then
              GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkRight
            else if (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteStandLeft) and (PlayerLeftHeld <>
              0) then
              GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkLeft
            else if ((GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteStandLeft) or
              (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteStandRight)) and ((PlayerDownHeld <> 0) or
              (PlayerUpHeld <> 0)) then
              GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkRight;
            { Erase old sprite footprints in the back buffer before updating positions. }
            ToggleGameDrawBuffer;
            RedrawLevelCell(GameActors[GamePlayerActorSlot].ActorPreviousX - GameTileSizePixels,
              GameActors[GamePlayerActorSlot].ActorPreviousY - GameTileSizePixels);
            RedrawLevelCell(GameActors[GamePlayerActorSlot].ActorPreviousX - GameTileSizePixels,
              GameActors[GamePlayerActorSlot].ActorPreviousY);
            RedrawLevelCell(GameActors[GamePlayerActorSlot].ActorPreviousX - GameTileSizePixels,
              GameActors[GamePlayerActorSlot].ActorPreviousY + GameTileSizePixels);
            RedrawLevelCell(GameActors[GamePlayerActorSlot].ActorPreviousX, GameActors[GamePlayerActorSlot].ActorPreviousY -
              GameTileSizePixels);
            RedrawLevelCell(GameActors[GamePlayerActorSlot].ActorPreviousX, GameActors[GamePlayerActorSlot].ActorPreviousY);
            RedrawLevelCell(GameActors[GamePlayerActorSlot].ActorPreviousX, GameActors[GamePlayerActorSlot].ActorPreviousY +
              GameTileSizePixels);
            RedrawLevelCell(GameActors[GamePlayerActorSlot].ActorPreviousX + GameTileSizePixels,
              GameActors[GamePlayerActorSlot].ActorPreviousY - GameTileSizePixels);
            RedrawLevelCell(GameActors[GamePlayerActorSlot].ActorPreviousX + GameTileSizePixels,
              GameActors[GamePlayerActorSlot].ActorPreviousY);
            RedrawLevelCell(GameActors[GamePlayerActorSlot].ActorPreviousX + GameTileSizePixels,
              GameActors[GamePlayerActorSlot].ActorPreviousY + GameTileSizePixels);
            { Original bug preserved: visibility tests also read stale SharedLoopIndexB.
              The actor loop itself uses SharedLoopIndexA. }
            for SharedLoopIndexA := 2 to GameActorSlotCount do
              if GameActors[SharedLoopIndexA].ActorSlotInactive = 0 then
                if GameActors[SharedLoopIndexA].ActorRemovalPending <> 0 then
                begin
                  GameActors[SharedLoopIndexA].ActorSlotInactive := 1;
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX,
                    GameActors[SharedLoopIndexA].ActorPreviousY);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX - GameTileSizePixels,
                    GameActors[SharedLoopIndexA].ActorPreviousY);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX + GameTileSizePixels,
                    GameActors[SharedLoopIndexA].ActorPreviousY);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX + 32,
                    GameActors[SharedLoopIndexA].ActorPreviousY);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX - GameTileSizePixels,
                    GameActors[SharedLoopIndexA].ActorPreviousY - GameTileSizePixels);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX - GameTileSizePixels,
                    GameActors[SharedLoopIndexA].ActorPreviousY + GameTileSizePixels);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX + GameTileSizePixels,
                    GameActors[SharedLoopIndexA].ActorPreviousY - GameTileSizePixels);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX + GameTileSizePixels,
                    GameActors[SharedLoopIndexA].ActorPreviousY + GameTileSizePixels);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX,
                    GameActors[SharedLoopIndexA].ActorPreviousY - GameTileSizePixels);
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX,
                    GameActors[SharedLoopIndexA].ActorPreviousY + GameTileSizePixels);
                end
                else if ActorNearViewport(SamActorEraseMargin, SharedLoopIndexA) or
                  (GameActors[SharedLoopIndexA].ActorKindCode = 28) or (GameActors[SharedLoopIndexA].ActorKindCode =
                  21) or (GameActors[SharedLoopIndexB].ActorKindCode = 14) or
                  (GameActors[SharedLoopIndexB].ActorRemovalPending <> 0) then
                begin
                  RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX,
                    GameActors[SharedLoopIndexA].ActorPreviousY);
                  if GameActors[SharedLoopIndexA].ActorPreviousX and GameTileOffsetMask > 0 then
                    RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX + GameTileSizePixels,
                      GameActors[SharedLoopIndexA].ActorPreviousY);
                  case GameActors[SharedLoopIndexA].ActorSpriteBase of
                    851:
                      begin
                        RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX + 48,
                          GameActors[SharedLoopIndexA].ActorPreviousY);
                        RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX + 32,
                          GameActors[SharedLoopIndexA].ActorPreviousY);
                        RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX + GameTileSizePixels,
                          GameActors[SharedLoopIndexA].ActorPreviousY);
                      end;
                    801 .. 899, 5001:
                      begin
                        RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX,
                          GameActors[SharedLoopIndexA].ActorPreviousY - GameTileSizePixels);
                        if GameActors[SharedLoopIndexA].ActorPreviousX and GameTileOffsetMask > 0 then
                          RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX + 15,
                            GameActors[SharedLoopIndexA].ActorPreviousY - GameTileSizePixels);
                      end;
                    114:
                      begin
                        RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX,
                          GameActors[SharedLoopIndexA].ActorPreviousY - GameTileSizePixels);
                        RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX,
                          GameActors[SharedLoopIndexA].ActorPreviousY + GameTileSizePixels);
                        if GameActors[SharedLoopIndexA].ActorPreviousX and GameTileOffsetMask > 0 then
                        begin
                          RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX + 15,
                            GameActors[SharedLoopIndexA].ActorPreviousY + GameTileSizePixels);
                          RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX + 15,
                            GameActors[SharedLoopIndexA].ActorPreviousY - GameTileSizePixels);
                        end;
                      end;
                    101:
                      begin
                        RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX,
                          GameActors[SharedLoopIndexA].ActorPreviousY - GameTileSizePixels);
                        if GameActors[SharedLoopIndexA].ActorPreviousX and GameTileOffsetMask > 0 then
                          RedrawLevelCell(GameActors[SharedLoopIndexA].ActorPreviousX + 15,
                            GameActors[SharedLoopIndexA].ActorPreviousY - GameTileSizePixels);
                      end;
                  end;
                end;

            for SharedLoopIndexA := 1 to PlayerProjectileLimit do
            begin
              RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorPreviousX,
                PlayerShots[SharedLoopIndexA].ActorPreviousY);
              RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorPreviousX + GameTileSizePixels,
                PlayerShots[SharedLoopIndexA].ActorPreviousY);
              RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorPreviousX,
                PlayerShots[SharedLoopIndexA].ActorPreviousY + GameTileSizePixels);
              RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorPreviousX + GameTileSizePixels,
                PlayerShots[SharedLoopIndexA].ActorPreviousY + GameTileSizePixels);
            end;

            if (PlayerDying = 0) and (PlayerLeavingLevel = 0) then
            begin
              MovePlayerAndCamera;
              if CurrentLevelNumber > GameIslandLevelNumber then
                UpdatePlayerJump;
              MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
              CheckPlayerTileContacts;
              PlayerOnMovingSupport := 0;
            end
            else if PlayerDying <> 0 then
            begin
              GameActors[GamePlayerActorSlot].ActorPreviousX := GameActors[GamePlayerActorSlot].ActorWorldX;
              GameActors[GamePlayerActorSlot].ActorPreviousY := GameActors[GamePlayerActorSlot].ActorWorldY;
              if GameActors[GamePlayerActorSlot].ActorSpriteBase <> GamePlayerSpriteDeathOne then
                GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteDeathOne
              else
                GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteDeathTwo;
              if DeathAnimationTick = 35 then
                StartSoundEffect(GameSfxPlayerDeath);
              Dec(DeathAnimationTick);
              if DeathAnimationTick = 0 then
                RequestIslandReturn;
              if DeathAnimationTick > 0 then
              begin
                Dec(GameActors[GamePlayerActorSlot].ActorWorldY, DeathVerticalMotionTable[DeathAnimationTick]);
                if GameActors[GamePlayerActorSlot].ActorWorldY < 16 then
                  GameActors[GamePlayerActorSlot].ActorWorldY := 16
                else if CameraY + GamePlayfieldHeightPixels < GameActors[GamePlayerActorSlot].ActorWorldY then
                  GameActors[GamePlayerActorSlot].ActorWorldY := CameraY + GamePlayfieldHeightPixels;
              end;
            end
            else if PlayerLeavingLevel <> 0 then
            begin
              GameActors[GamePlayerActorSlot].ActorPreviousX := GameActors[GamePlayerActorSlot].ActorWorldX;
              GameActors[GamePlayerActorSlot].ActorPreviousY := GameActors[GamePlayerActorSlot].ActorWorldY;
              if LevelExitAnimationTick = 8 then
                StartSoundEffect(GameSfxLevelExit);
              Dec(LevelExitAnimationTick);
              if LevelExitAnimationTick = 0 then
              begin
                FadeGamePaletteToBlack(20);
                CurrentLevelNumber := GameIslandLevelNumber;
                ResetLevelTransientState;
                LoadLevelMap(CurrentLevelNumber);
                if AllMissionsComplete <> 0 then
                  ShowFortressUnlockedMessage;
              end
              else if LevelExitAnimationTick > 0 then
                if GameActors[GamePlayerActorSlot].ActorDirectionX = -1 then
                  Dec(GameActors[GamePlayerActorSlot].ActorWorldX, 2)
                else
                  Inc(GameActors[GamePlayerActorSlot].ActorWorldX, 2);
            end;
            { Draw updated actors, then redraw foreground tiles to restore occlusion. }
            UpdateActorsAndShots;

            for SharedLoopIndexA := 1 to PlayerProjectileLimit do
              if PlayerShots[SharedLoopIndexA].ActorSlotInactive = 0 then
              begin
                if PlayerShots[SharedLoopIndexA].ActorRemovalPending <> 0 then
                begin
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX,
                    PlayerShots[SharedLoopIndexA].ActorWorldY);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX + GameTileSizePixels,
                    PlayerShots[SharedLoopIndexA].ActorWorldY);
                  DrawCellForeground(PlayerShots[SharedLoopIndexA].ActorWorldX,
                    PlayerShots[SharedLoopIndexA].ActorWorldY);
                  DrawCellForeground(PlayerShots[SharedLoopIndexA].ActorWorldX + GameTileSizePixels,
                    PlayerShots[SharedLoopIndexA].ActorWorldY);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX,
                    PlayerShots[SharedLoopIndexA].ActorWorldY + GameTileSizePixels);
                  RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX + GameTileSizePixels,
                    PlayerShots[SharedLoopIndexA].ActorWorldY + GameTileSizePixels);
                  DrawCellForeground(PlayerShots[SharedLoopIndexA].ActorWorldX,
                    PlayerShots[SharedLoopIndexA].ActorWorldY + GameTileSizePixels);
                  DrawCellForeground(PlayerShots[SharedLoopIndexA].ActorWorldX + GameTileSizePixels,
                    PlayerShots[SharedLoopIndexA].ActorWorldY + GameTileSizePixels);
                  PlayerShots[SharedLoopIndexA].ActorSlotInactive := 1;
                end
                else
                begin
                  if PlayerShots[SharedLoopIndexA].ActorSpriteBase = 626 then
                  begin
                    PgBlitMaskedShifted16x16(SpriteBank601^.SpriteEntries[(PlayerShots[
                      SharedLoopIndexA].ActorCounterB shr 1) + 25].SpriteDataBytes[1],
                      PlayerShots[SharedLoopIndexA].ActorWorldX, PlayerShots[SharedLoopIndexA].ActorWorldY +
                      GameDrawBufferRow);
                    Dec(PlayerShots[SharedLoopIndexA].ActorCounterB);
                    if PlayerShots[SharedLoopIndexA].ActorCounterB <= 0 then
                    begin
                      PlayerShots[SharedLoopIndexA].ActorRemovalPending := 1;
                      RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX,
                        PlayerShots[SharedLoopIndexA].ActorWorldY);
                      RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX - GameTileSizePixels,
                        PlayerShots[SharedLoopIndexA].ActorWorldY);
                      RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX + GameTileSizePixels,
                        PlayerShots[SharedLoopIndexA].ActorWorldY);
                      RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX,
                        PlayerShots[SharedLoopIndexA].ActorWorldY + GameTileSizePixels);
                      RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX - GameTileSizePixels,
                        PlayerShots[SharedLoopIndexA].ActorWorldY + GameTileSizePixels);
                      RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX + GameTileSizePixels,
                        PlayerShots[SharedLoopIndexA].ActorWorldY + GameTileSizePixels);
                    end;
                  end
                  else if not ShotNearViewport(SamActorEraseMargin, SharedLoopIndexA) then
                  begin
                    RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX,
                      PlayerShots[SharedLoopIndexA].ActorWorldY);
                    RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX + GameTileSizePixels,
                      PlayerShots[SharedLoopIndexA].ActorWorldY);
                    RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX,
                      PlayerShots[SharedLoopIndexA].ActorWorldY + GameTileSizePixels);
                    RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX + GameTileSizePixels,
                      PlayerShots[SharedLoopIndexA].ActorWorldY + GameTileSizePixels);
                    PlayerShots[SharedLoopIndexA].ActorRemovalPending := 1;
                  end
                  else
                  begin
                    RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX,
                      PlayerShots[SharedLoopIndexA].ActorWorldY);
                    RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX + GameTileSizePixels,
                      PlayerShots[SharedLoopIndexA].ActorWorldY);
                    RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX,
                      PlayerShots[SharedLoopIndexA].ActorWorldY + GameTileSizePixels);
                    RedrawLevelCell(PlayerShots[SharedLoopIndexA].ActorWorldX + GameTileSizePixels,
                      PlayerShots[SharedLoopIndexA].ActorWorldY + GameTileSizePixels);
                    PgBlitMasked16x16(SpriteBank001^.SpriteEntries[PlayerShots[SharedLoopIndexA].ActorSpriteBase - 1
                      + PlayerShots[SharedLoopIndexA].ActorAnimationCounter].SpriteDataBytes[1],
                      PlayerShots[SharedLoopIndexA].ActorWorldX shr 3, PlayerShots[SharedLoopIndexA].ActorWorldY +
                      GameDrawBufferRow);
                  end;
                  DrawCellForeground(PlayerShots[SharedLoopIndexA].ActorWorldX,
                    PlayerShots[SharedLoopIndexA].ActorWorldY);
                  DrawCellForeground(PlayerShots[SharedLoopIndexA].ActorWorldX + GameTileSizePixels,
                    PlayerShots[SharedLoopIndexA].ActorWorldY);
                  DrawCellForeground(PlayerShots[SharedLoopIndexA].ActorWorldX,
                    PlayerShots[SharedLoopIndexA].ActorWorldY + GameTileSizePixels);
                  DrawCellForeground(PlayerShots[SharedLoopIndexA].ActorWorldX + GameTileSizePixels,
                    PlayerShots[SharedLoopIndexA].ActorWorldY + GameTileSizePixels);
                end;
              end;

            if PlayerTeleporting <> 0 then
            begin
              Dec(TeleportAnimationTick);
              if TeleportAnimationTick = 0 then
                TeleportRelocatePending := 1
              else if TeleportAnimationTick = -19 then
              begin
                PlayerInputLocked := 0;
                PlayerTeleporting := 0;
              end;
            end;
            if TeleportRelocatePending <> 0 then
            begin
              TeleportRelocatePending := 0;
              GameActors[GamePlayerActorSlot].ActorWorldX := TeleportDestinationX;
              GameActors[GamePlayerActorSlot].ActorWorldY := TeleportDestinationY;
              CameraX := GameActors[GamePlayerActorSlot].ActorWorldX - GameCameraCenterX;
              if CameraX < 0 then
                CameraX := 0;
              if CameraX > GameCameraMaxX then
                CameraX := GameCameraMaxX;
              CameraY := GameActors[GamePlayerActorSlot].ActorWorldY - GameCameraCenterY;
              if CameraY < 0 then
                CameraY := 0;
              if CameraY > GameCameraMaxY then
                CameraY := GameCameraMaxY;
              if AlternateVideoTiming = 0 then
                PgPanDisplayAtRetraceStart(CameraX, CameraY + GamePlayfieldTopBufferRow)
              else
                PgPanDisplayAtRetraceEnd(CameraX, CameraY + GamePlayfieldTopBufferRow);
            end;
            SharedLoopIndexA := 1;
            if (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteWalkRight) or
              (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteWalkLeft) then
            begin
              Inc(GameActors[GamePlayerActorSlot].ActorAnimationCounter, GameActors[GamePlayerActorSlot].ActorMovementStep);
              if GameActors[GamePlayerActorSlot].ActorAnimationCounter > 19 then
                GameActors[GamePlayerActorSlot].ActorAnimationCounter := 1;
            end
            else
              GameActors[GamePlayerActorSlot].ActorAnimationCounter := 1;
            if PlayerDamageGraceActive <> 0 then
            begin
              Dec(PlayerDamageGraceTick);
              case PlayerDamageGraceTick of
                0:
                  PlayerDamageGraceActive := 0;
                10:
                  GameActors[GamePlayerActorSlot].FlashFrames := 5;
                20:
                  GameActors[GamePlayerActorSlot].FlashFrames := 5;
                30:
                  GameActors[GamePlayerActorSlot].FlashFrames := 5;
              end;
            end;

            if GameActors[GamePlayerActorSlot].FlashFrames > 0 then
            begin
              PgOrShifted16x16(PlayerSpriteBank^.SpriteEntries[GameActors[GamePlayerActorSlot].ActorAnimationCounter div 5
                + GameActors[GamePlayerActorSlot].ActorSpriteBase].SpriteDataBytes[1],
                GameActors[GamePlayerActorSlot].ActorWorldX, GameActors[GamePlayerActorSlot].ActorWorldY + GameDrawBufferRow);
              Dec(GameActors[GamePlayerActorSlot].FlashFrames);
            end
            else if GameActors[GamePlayerActorSlot].ActorWorldX and GamePlanarBytePixelMask = 0 then
              PgBlitMasked16x16(PlayerSpriteBank^.SpriteEntries[GameActors[GamePlayerActorSlot].ActorAnimationCounter div 5
                + GameActors[GamePlayerActorSlot].ActorSpriteBase].SpriteDataBytes[1],
                GameActors[GamePlayerActorSlot].ActorWorldX shr 3, GameActors[GamePlayerActorSlot].ActorWorldY +
                GameDrawBufferRow)
            else
              PgBlitMaskedShifted16x16(PlayerSpriteBank^.SpriteEntries[GameActors[
                GamePlayerActorSlot].ActorAnimationCounter div 5 +
                GameActors[GamePlayerActorSlot].ActorSpriteBase].SpriteDataBytes[1],
                  GameActors[GamePlayerActorSlot].ActorWorldX,
                GameActors[GamePlayerActorSlot].ActorWorldY + GameDrawBufferRow);
            if PlayerTeleporting <> 0 then
              if TeleportAnimationTick < 0 then
                PgBlitMaskedShifted16x16(SpriteBank151^.SpriteEntries[TeleportAnimationTick div 5 +
                  40].SpriteDataBytes[1], GameActors[GamePlayerActorSlot].ActorWorldX,
                  GameActors[GamePlayerActorSlot].ActorWorldY + GameDrawBufferRow)
              else
                PgBlitMaskedShifted16x16(SpriteBank151^.SpriteEntries[40 - TeleportAnimationTick div
                  5].SpriteDataBytes[1], GameActors[GamePlayerActorSlot].ActorWorldX,
                    GameActors[GamePlayerActorSlot].ActorWorldY
                  + GameDrawBufferRow);
            if (PlayerLeftHeld <> 0) and (GameActors[GamePlayerActorSlot].ActorSpriteBase = GamePlayerSpriteFireLeft) then
              GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkLeft
            else if (PlayerRightHeld <> 0) and (GameActors[GamePlayerActorSlot].ActorSpriteBase =
              GamePlayerSpriteFireRight) then
              GameActors[GamePlayerActorSlot].ActorSpriteBase := GamePlayerSpriteWalkRight;
            { Original bug preserved: visibility tests also read stale SharedLoopIndexB.
              The actor loop itself uses SharedLoopIndexA. }
            for SharedLoopIndexA := 2 to GameActorSlotCount do
              if GameActors[SharedLoopIndexA].ActorSlotInactive = 0 then
                if GameActors[SharedLoopIndexA].ActorRemovalPending = 0 then
                  if ActorNearViewport(SamActorDrawMargin, SharedLoopIndexA) or
                    (GameActors[SharedLoopIndexA].ActorKindCode = 28) or (GameActors[SharedLoopIndexA].ActorKindCode
                    = 21) or (GameActors[SharedLoopIndexB].ActorKindCode = 14) then
                    if GameActors[SharedLoopIndexA].FlashFrames > 0 then
                    begin
                      case GameActors[SharedLoopIndexA].ActorSpriteBase of
                        1 .. 50:
                          PgOrShifted16x16(SpriteBank001^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        101:
                          begin
                            if GameActors[SharedLoopIndexA].StateValueB = 0 then
                            begin
                              PgOrShifted16x16(SpriteBank101^.SpriteEntries[GameActors[
                                SharedLoopIndexA].ActorSpriteBase - 100 +
                                GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                                GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                                GameDrawBufferRow - GameTileSizePixels);
                              if GameActors[SharedLoopIndexA].ActorDirectionX < 0 then
                                PgOrShifted16x16(SpriteBank101^.SpriteEntries[5].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY
                                  + GameDrawBufferRow)
                              else
                                PgOrShifted16x16(SpriteBank101^.SpriteEntries[45].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY
                                  + GameDrawBufferRow);
                            end
                            else
                            begin
                              if GameActors[SharedLoopIndexA].ActorDirectionX < 0 then
                                PgOrShifted16x16(SpriteBank101^.SpriteEntries[1].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY
                                  + GameDrawBufferRow - GameTileSizePixels)
                              else
                                PgOrShifted16x16(SpriteBank101^.SpriteEntries[41].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY
                                  + GameDrawBufferRow - GameTileSizePixels);
                              PgOrShifted16x16(SpriteBank101^.SpriteEntries[GameActors[
                                SharedLoopIndexA].ActorSpriteBase - 96 +
                                GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                                GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                                GameDrawBufferRow);
                            end;
                          end;
                        102 .. 150:
                          PgOrShifted16x16(SpriteBank101^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 100 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        151 .. 200:
                          PgOrShifted16x16(SpriteBank151^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 150 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        251 .. 300:
                          PgOrShifted16x16(SpriteBank251^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 250 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        301 .. 350:
                          PgOrShifted16x16(SpriteBank301^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 300 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        351 .. 400:
                          PgOrShifted16x16(SpriteBank351^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 350 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        401 .. 450:
                          PgOrShifted16x16(SpriteBank401^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 400 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        451 .. 487:
                          PgOrShifted16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 450 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        488 .. 490:
                          PgOrShifted16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 450 + GameActors[SharedLoopIndexA].ActorAnimationCounter shr 3].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        491:
                          PgOrShifted16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 450 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        492 .. 494:
                          PgOrShifted16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 450 + (GameActors[SharedLoopIndexA].ActorAnimationCounter - 21) shr
                            3].SpriteDataBytes[1], GameActors[SharedLoopIndexA].ActorWorldX,
                            GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow);
                        495 .. 500:
                          PgOrShifted16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 450 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        501 .. 550:
                          PgOrShifted16x16(SpriteBank001^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 500 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        601 .. 650:
                          PgOrShifted16x16(SpriteBank601^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 600 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        651 .. 700:
                          PgOrShifted16x16(SpriteBank651^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 650 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        701 .. 750:
                          PgOrShifted16x16(SpriteBank701^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 700 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        751 .. 800:
                          PgOrShifted16x16(SpriteBank751^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 750 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        801:
                          begin
                            PgOrShifted16x16(SpriteBank801^.SpriteEntries[GameActors[
                              SharedLoopIndexA].ActorSpriteBase - 800 +
                              GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                              GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                              GameDrawBufferRow - GameTileSizePixels);
                            PgOrShifted16x16(SpriteBank801^.SpriteEntries[GameActors[
                              SharedLoopIndexA].ActorSpriteBase - 796 +
                              GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                              GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                              GameDrawBufferRow);
                          end;
                        817:
                          begin
                            if GameActors[SharedLoopIndexA].StateValueB = 0 then
                            begin
                              PgOrShifted16x16(SpriteBank801^.SpriteEntries[GameActors[
                                SharedLoopIndexA].ActorSpriteBase - 800 +
                                GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                                GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                                GameDrawBufferRow - GameTileSizePixels);
                              if GameActors[SharedLoopIndexA].ActorDirectionX < 0 then
                                PgOrShifted16x16(SpriteBank801^.SpriteEntries[21].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY
                                  + GameDrawBufferRow)
                              else
                                PgOrShifted16x16(SpriteBank801^.SpriteEntries[33].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY
                                  + GameDrawBufferRow);
                            end
                            else
                            begin
                              if GameActors[SharedLoopIndexA].ActorDirectionX < 0 then
                                PgOrShifted16x16(SpriteBank801^.SpriteEntries[17].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY
                                  + GameDrawBufferRow - GameTileSizePixels)
                              else
                                PgOrShifted16x16(SpriteBank801^.SpriteEntries[29].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY
                                  + GameDrawBufferRow - GameTileSizePixels);
                              PgOrShifted16x16(SpriteBank801^.SpriteEntries[GameActors[
                                SharedLoopIndexA].ActorSpriteBase - 796 +
                                GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                                GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                                GameDrawBufferRow);
                            end;
                          end;
                        825 .. 828:
                          PgOrShifted16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 800 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        837 .. 850:
                          PgOrShifted16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 800 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        851:
                          begin
                            PgOrShifted16x16(SpriteBank851^.SpriteEntries[GameActors[
                              SharedLoopIndexA].ActorSpriteBase - 850 +
                              GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                              GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                              GameDrawBufferRow);
                            PgOrShifted16x16(SpriteBank851^.SpriteEntries[GameActors[
                              SharedLoopIndexA].ActorSpriteBase - 846 +
                              GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                              GameActors[SharedLoopIndexA].ActorWorldX + GameTileSizePixels,
                              GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow);
                          end;
                      end;
                      Dec(GameActors[SharedLoopIndexA].FlashFrames);
                    end
                    else if GameActors[SharedLoopIndexA].ActorWorldX and GamePlanarBytePixelMask = 0 then
                    begin
                      case GameActors[SharedLoopIndexA].ActorSpriteBase of
                        1 .. 50:
                          PgBlitMasked16x16(SpriteBank001^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        101:
                          begin
                            if GameActors[SharedLoopIndexA].StateValueB = 0 then
                            begin
                              PgBlitMasked16x16(SpriteBank101^.SpriteEntries[GameActors[
                                SharedLoopIndexA].ActorSpriteBase - 100 +
                                GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                                GameActors[SharedLoopIndexA].ActorWorldX shr 3,
                                GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow - GameTileSizePixels);
                              if GameActors[SharedLoopIndexA].ActorDirectionX < 0 then
                                PgBlitMasked16x16(SpriteBank101^.SpriteEntries[5].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX shr 3,
                                  GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow)
                              else
                                PgBlitMasked16x16(SpriteBank101^.SpriteEntries[45].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX shr 3,
                                  GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow);
                            end
                            else
                            begin
                              if GameActors[SharedLoopIndexA].ActorDirectionX < 0 then
                                PgBlitMasked16x16(SpriteBank101^.SpriteEntries[1].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX shr 3,
                                  GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow - GameTileSizePixels)
                              else
                                PgBlitMasked16x16(SpriteBank101^.SpriteEntries[41].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX shr 3,
                                  GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow - GameTileSizePixels);
                              PgBlitMasked16x16(SpriteBank101^.SpriteEntries[GameActors[
                                SharedLoopIndexA].ActorSpriteBase - 96 +
                                GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                                GameActors[SharedLoopIndexA].ActorWorldX shr 3,
                                GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow);
                            end;
                          end;
                        102 .. 150:
                          PgBlitMasked16x16(SpriteBank101^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 100 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        151 .. 200:
                          PgBlitMasked16x16(SpriteBank151^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 150 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        251 .. 300:
                          PgBlitMasked16x16(SpriteBank251^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 250 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        301 .. 350:
                          PgBlitMasked16x16(SpriteBank301^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 300 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        351 .. 400:
                          PgBlitMasked16x16(SpriteBank351^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 350 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        401 .. 450:
                          PgBlitMasked16x16(SpriteBank401^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 400 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        451 .. 487:
                          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 450 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        488 .. 490:
                          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 450 + GameActors[SharedLoopIndexA].ActorAnimationCounter shr 3].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        491:
                          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 450 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        492 .. 494:
                          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 450 + (GameActors[SharedLoopIndexA].ActorAnimationCounter - 21) shr
                            3].SpriteDataBytes[1], GameActors[SharedLoopIndexA].ActorWorldX shr 3,
                            GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow);
                        495 .. 500:
                          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 450 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        501 .. 550:
                          PgBlitMasked16x16(SpriteBank001^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 500 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        601 .. 624:
                          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 600 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        625:
                          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 600 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 3].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        626 .. 650:
                          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 600 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        651 .. 700:
                          PgBlitMasked16x16(SpriteBank651^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 650 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        701 .. 750:
                          PgBlitMasked16x16(SpriteBank701^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 700 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        751 .. 800:
                          PgBlitMasked16x16(SpriteBank751^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 750 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        801:
                          begin
                            PgBlitMasked16x16(SpriteBank801^.SpriteEntries[GameActors[
                              SharedLoopIndexA].ActorSpriteBase - 800 +
                              GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                              GameActors[SharedLoopIndexA].ActorWorldX shr 3,
                              GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow - GameTileSizePixels);
                            PgBlitMasked16x16(SpriteBank801^.SpriteEntries[GameActors[
                              SharedLoopIndexA].ActorSpriteBase - 796 +
                              GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                              GameActors[SharedLoopIndexA].ActorWorldX shr 3,
                              GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow);
                          end;
                        817:
                          begin
                            if GameActors[SharedLoopIndexA].StateValueB = 0 then
                            begin
                              PgBlitMasked16x16(SpriteBank801^.SpriteEntries[GameActors[
                                SharedLoopIndexA].ActorSpriteBase - 800 +
                                GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                                GameActors[SharedLoopIndexA].ActorWorldX shr 3,
                                GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow - GameTileSizePixels);
                              if GameActors[SharedLoopIndexA].ActorDirectionX < 0 then
                                PgBlitMasked16x16(SpriteBank801^.SpriteEntries[21].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX shr 3,
                                  GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow)
                              else
                                PgBlitMasked16x16(SpriteBank801^.SpriteEntries[33].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX shr 3,
                                  GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow);
                            end
                            else
                            begin
                              if GameActors[SharedLoopIndexA].ActorDirectionX < 0 then
                                PgBlitMasked16x16(SpriteBank801^.SpriteEntries[17].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX shr 3,
                                  GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow - GameTileSizePixels)
                              else
                                PgBlitMasked16x16(SpriteBank801^.SpriteEntries[29].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX shr 3,
                                  GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow - GameTileSizePixels);
                              PgBlitMasked16x16(SpriteBank801^.SpriteEntries[GameActors[
                                SharedLoopIndexA].ActorSpriteBase - 796 +
                                GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                                GameActors[SharedLoopIndexA].ActorWorldX shr 3,
                                GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow);
                            end;
                          end;
                        825 .. 828:
                          PgBlitMasked16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 800 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        837 .. 850:
                          PgBlitMasked16x16(SpriteBank801^.SpriteEntries[GameActors[SharedLoopIndexA].ActorSpriteBase
                            - 800 + GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX shr 3, GameActors[SharedLoopIndexA].ActorWorldY
                            + GameDrawBufferRow);
                        851:
                          begin
                            PgBlitMasked16x16(SpriteBank851^.SpriteEntries[GameActors[
                              SharedLoopIndexA].ActorSpriteBase - 850 +
                              GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                              GameActors[SharedLoopIndexA].ActorWorldX shr 3,
                              GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow);
                            PgBlitMasked16x16(SpriteBank851^.SpriteEntries[GameActors[
                              SharedLoopIndexA].ActorSpriteBase - 846 +
                              GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                              GameActors[SharedLoopIndexA].ActorWorldX shr 3 + 2,
                              GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow);
                          end;
                      end;
                    end
                    else
                    begin
                      case GameActors[SharedLoopIndexA].ActorSpriteBase of
                        1 .. 50:
                          PgBlitMaskedShifted16x16(SpriteBank001^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase + GameActors[SharedLoopIndexA].ActorAnimationCounter
                            div 5].SpriteDataBytes[1], GameActors[SharedLoopIndexA].ActorWorldX,
                            GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow);
                        101:
                          begin
                            if GameActors[SharedLoopIndexA].StateValueB = 0 then
                            begin
                              PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[GameActors[
                                SharedLoopIndexA].ActorSpriteBase - 100 +
                                GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                                GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                                GameDrawBufferRow - GameTileSizePixels);
                              if GameActors[SharedLoopIndexA].ActorDirectionX < 0 then
                                PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[5].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY
                                  + GameDrawBufferRow)
                              else
                                PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[45].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY
                                  + GameDrawBufferRow);
                            end
                            else
                            begin
                              if GameActors[SharedLoopIndexA].ActorDirectionX < 0 then
                                PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[1].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY
                                  + GameDrawBufferRow - GameTileSizePixels)
                              else
                                PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[41].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY
                                  + GameDrawBufferRow - GameTileSizePixels);
                              PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[GameActors[
                                SharedLoopIndexA].ActorSpriteBase - 96 +
                                GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                                GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                                GameDrawBufferRow);
                            end;
                          end;
                        102 .. 150:
                          PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 100 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        151 .. 200:
                          PgBlitMaskedShifted16x16(SpriteBank151^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 150 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        251 .. 300:
                          PgBlitMaskedShifted16x16(SpriteBank251^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 250 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        301 .. 350:
                          PgBlitMaskedShifted16x16(SpriteBank301^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 300 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        351 .. 400:
                          PgBlitMaskedShifted16x16(SpriteBank351^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 350 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        401 .. 450:
                          PgBlitMaskedShifted16x16(SpriteBank401^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 400 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        451 .. 487:
                          PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 450 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        488 .. 490:
                          PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 450 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter shr 3].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        491:
                          PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 450 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        492 .. 494:
                          PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 450 +
                            (GameActors[SharedLoopIndexA].ActorAnimationCounter - 21) shr 3].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        495 .. 500:
                          PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 450 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        501 .. 550:
                          PgBlitMaskedShifted16x16(SpriteBank001^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 500 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        601 .. 650:
                          PgBlitMaskedShifted16x16(SpriteBank601^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 600 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        651 .. 700:
                          PgBlitMaskedShifted16x16(SpriteBank651^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 650 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        701 .. 750:
                          PgBlitMaskedShifted16x16(SpriteBank701^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 700 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        751 .. 800:
                          PgBlitMaskedShifted16x16(SpriteBank751^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 750 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        801:
                          begin
                            PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[GameActors[
                              SharedLoopIndexA].ActorSpriteBase - 800 +
                              GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                              GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                              GameDrawBufferRow - GameTileSizePixels);
                            PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[GameActors[
                              SharedLoopIndexA].ActorSpriteBase - 796 +
                              GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                              GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                              GameDrawBufferRow);
                          end;
                        817:
                          begin
                            if GameActors[SharedLoopIndexA].StateValueB = 0 then
                            begin
                              PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[GameActors[
                                SharedLoopIndexA].ActorSpriteBase - 800 +
                                GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                                GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                                GameDrawBufferRow - GameTileSizePixels);
                              if GameActors[SharedLoopIndexA].ActorDirectionX < 0 then
                                PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[21].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY
                                  + GameDrawBufferRow)
                              else
                                PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[33].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY
                                  + GameDrawBufferRow);
                            end
                            else
                            begin
                              if GameActors[SharedLoopIndexA].ActorDirectionX < 0 then
                                PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[17].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY
                                  + GameDrawBufferRow - GameTileSizePixels)
                              else
                                PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[29].SpriteDataBytes[1],
                                  GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY
                                  + GameDrawBufferRow - GameTileSizePixels);
                              PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[GameActors[
                                SharedLoopIndexA].ActorSpriteBase - 796 +
                                GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                                GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                                GameDrawBufferRow);
                            end;
                          end;
                        825 .. 828:
                          PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 800 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        837 .. 850:
                          PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[GameActors[
                            SharedLoopIndexA].ActorSpriteBase - 800 +
                            GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                            GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                            GameDrawBufferRow);
                        851:
                          begin
                            PgBlitMaskedShifted16x16(SpriteBank851^.SpriteEntries[GameActors[
                              SharedLoopIndexA].ActorSpriteBase - 850 +
                              GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                              GameActors[SharedLoopIndexA].ActorWorldX, GameActors[SharedLoopIndexA].ActorWorldY +
                              GameDrawBufferRow);
                            PgBlitMaskedShifted16x16(SpriteBank851^.SpriteEntries[GameActors[
                              SharedLoopIndexA].ActorSpriteBase - 846 +
                              GameActors[SharedLoopIndexA].ActorAnimationCounter div 5].SpriteDataBytes[1],
                              GameActors[SharedLoopIndexA].ActorWorldX + GameTileSizePixels,
                              GameActors[SharedLoopIndexA].ActorWorldY + GameDrawBufferRow);
                          end;
                      end;
                    end;

            DrawCellForeground(GameActors[GamePlayerActorSlot].ActorPreviousX - GameTileSizePixels,
              GameActors[GamePlayerActorSlot].ActorPreviousY - GameTileSizePixels);
            DrawCellForeground(GameActors[GamePlayerActorSlot].ActorPreviousX - GameTileSizePixels,
              GameActors[GamePlayerActorSlot].ActorPreviousY);
            DrawCellForeground(GameActors[GamePlayerActorSlot].ActorPreviousX - GameTileSizePixels,
              GameActors[GamePlayerActorSlot].ActorPreviousY + GameTileSizePixels);
            DrawCellForeground(GameActors[GamePlayerActorSlot].ActorPreviousX,
              GameActors[GamePlayerActorSlot].ActorPreviousY -
              GameTileSizePixels);
            DrawCellForeground(GameActors[GamePlayerActorSlot].ActorPreviousX,
              GameActors[GamePlayerActorSlot].ActorPreviousY);
            DrawCellForeground(GameActors[GamePlayerActorSlot].ActorPreviousX,
              GameActors[GamePlayerActorSlot].ActorPreviousY +
              GameTileSizePixels);
            DrawCellForeground(GameActors[GamePlayerActorSlot].ActorPreviousX + GameTileSizePixels,
              GameActors[GamePlayerActorSlot].ActorPreviousY - GameTileSizePixels);
            DrawCellForeground(GameActors[GamePlayerActorSlot].ActorPreviousX + GameTileSizePixels,
              GameActors[GamePlayerActorSlot].ActorPreviousY);
            DrawCellForeground(GameActors[GamePlayerActorSlot].ActorPreviousX + GameTileSizePixels,
              GameActors[GamePlayerActorSlot].ActorPreviousY + GameTileSizePixels);
            for SharedLoopIndexA := 2 to GameActorSlotCount do
              if GameActors[SharedLoopIndexA].ActorSlotInactive = 0 then
                if GameActors[SharedLoopIndexA].ActorRemovalPending <> 0 then
                begin
                  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX,
                    GameActors[SharedLoopIndexA].ActorPreviousY);
                  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX - GameTileSizePixels,
                    GameActors[SharedLoopIndexA].ActorPreviousY);
                  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX + GameTileSizePixels,
                    GameActors[SharedLoopIndexA].ActorPreviousY);
                  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX - GameTileSizePixels,
                    GameActors[SharedLoopIndexA].ActorPreviousY - GameTileSizePixels);
                  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX - GameTileSizePixels,
                    GameActors[SharedLoopIndexA].ActorPreviousY + GameTileSizePixels);
                  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX + GameTileSizePixels,
                    GameActors[SharedLoopIndexA].ActorPreviousY - GameTileSizePixels);
                  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX + GameTileSizePixels,
                    GameActors[SharedLoopIndexA].ActorPreviousY + GameTileSizePixels);
                  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX,
                    GameActors[SharedLoopIndexA].ActorPreviousY - GameTileSizePixels);
                  DrawCellForeground(GameActors[SharedLoopIndexA].ActorPreviousX,
                    GameActors[SharedLoopIndexA].ActorPreviousY + GameTileSizePixels);
                end
                else if ActorNearViewport(SamActorDrawMargin, SharedLoopIndexA) or
                  (GameActors[SharedLoopIndexA].ActorKindCode = 28) or (GameActors[SharedLoopIndexA].ActorKindCode =
                  27) or (GameActors[SharedLoopIndexA].ActorKindCode = 21) or
                  (GameActors[SharedLoopIndexB].ActorKindCode = 14) then
                begin
                  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX,
                    GameActors[SharedLoopIndexA].ActorWorldY);
                  if GameActors[SharedLoopIndexA].ActorWorldX and GameTileOffsetMask > 0 then
                    DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX + 15,
                      GameActors[SharedLoopIndexA].ActorWorldY);
                  if GameActors[SharedLoopIndexA].ActorKindCode = 27 then
                  begin
                    DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX,
                      GameActors[SharedLoopIndexA].ActorWorldY - GameTileSizePixels);
                    DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX + GameTileSizePixels,
                      GameActors[SharedLoopIndexA].ActorWorldY - GameTileSizePixels);
                  end
                  else
                    case GameActors[SharedLoopIndexA].ActorSpriteBase of
                      851:
                        begin
                          DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX + 48,
                            GameActors[SharedLoopIndexA].ActorWorldY);
                          DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX + 32,
                            GameActors[SharedLoopIndexA].ActorWorldY);
                          DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX + GameTileSizePixels,
                            GameActors[SharedLoopIndexA].ActorWorldY);
                        end;
                      801 .. 899, 5001:
                        begin
                          DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX,
                            GameActors[SharedLoopIndexA].ActorWorldY - GameTileSizePixels);
                          if GameActors[SharedLoopIndexA].ActorWorldX and GameTileOffsetMask > 0 then
                            DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX + 15,
                              GameActors[SharedLoopIndexA].ActorWorldY - GameTileSizePixels);
                        end;
                      114:
                        begin
                          if GameActors[SharedLoopIndexA].ActorWorldY > 15 then
                            DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX,
                              GameActors[SharedLoopIndexA].ActorWorldY - GameTileSizePixels);
                          DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX,
                            GameActors[SharedLoopIndexA].ActorWorldY + GameTileSizePixels);
                          if GameActors[SharedLoopIndexA].ActorWorldX and GameTileOffsetMask > 0 then
                          begin
                            DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX + 15,
                              GameActors[SharedLoopIndexA].ActorWorldY + GameTileSizePixels);
                            if GameActors[SharedLoopIndexA].ActorWorldY > 15 then
                              DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX + 15,
                                GameActors[SharedLoopIndexA].ActorWorldY - GameTileSizePixels);
                          end;
                        end;
                      101:
                        begin
                          DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX,
                            GameActors[SharedLoopIndexA].ActorWorldY - GameTileSizePixels);
                          if GameActors[SharedLoopIndexA].ActorWorldX and GameTileOffsetMask > 0 then
                            DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX + 15,
                              GameActors[SharedLoopIndexA].ActorWorldY - GameTileSizePixels);
                        end;
                    end;
                end
                else if (GameActors[SharedLoopIndexA].ActorKindCode = 7) or
                  (GameActors[SharedLoopIndexA].ActorKindCode = 14) or (GameActors[SharedLoopIndexA].ActorKindCode =
                  19) or (GameActors[SharedLoopIndexA].ActorKindCode = 5000) then
                begin
                  GameActors[SharedLoopIndexA].ActorRemovalPending := 1;
                  DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX,
                    GameActors[SharedLoopIndexA].ActorWorldY);
                  if GameActors[SharedLoopIndexA].ActorWorldX and GameTileOffsetMask > 0 then
                  begin
                    DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX + 15,
                      GameActors[SharedLoopIndexA].ActorWorldY);
                    DrawCellForeground(GameActors[SharedLoopIndexA].ActorWorldX - 15,
                      GameActors[SharedLoopIndexA].ActorWorldY);
                  end;
                end;
            if PlayerDying <> 0 then
              PgBlitMaskedShifted16x16(PlayerSpriteBank^.SpriteEntries[GameActors[
                GamePlayerActorSlot].ActorAnimationCounter div 5 +
                GameActors[GamePlayerActorSlot].ActorSpriteBase].SpriteDataBytes[1],
                  GameActors[GamePlayerActorSlot].ActorWorldX,
                GameActors[GamePlayerActorSlot].ActorWorldY + GameDrawBufferRow);

            ShowGameDrawBuffer;
            if ConfusionEndedMessagePending <> 0 then
            begin
              ConfusionEndedMessagePending := 0;
              ShowGameMessage('YOU FEEL LESS CONFUSED');
            end;
            if GameOptionsRequested <> 0 then
            begin
              UnusedOptionsMenuResult := Ord(RunGameOptionsMenu);
              GameOptionsRequested := 0;
            end;
            if RestoreSnapshotRequested <> 0 then
            begin
              FadeGamePaletteToBlack(20);
              if PlayerAmmo < 15 then
                PlayerAmmo := 15;
              LevelCompletedFlags[EnteredLevelNumber] := 0;
              if PlayerDying = 0 then
                CurrentLevelNumber := GameIslandLevelNumber;
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
                CurrentLevelNumber := SharedLoopIndexA + 1;
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
              if PlayerGodMode <> 0 then
                ShowGameMessage('GOD Mode On')
              else
                ShowGameMessage('GOD Mode Off');
            end;
          end;
        end;
      end;
      if EpisodeBlueprintCollected <> 0 then
        ShowEpisodeEnding;
    end;
    FadeGamePaletteToBlack(20);
    PgSetBiosVideoMode(GameBiosColorTextMode);
    if SoundEnabled <> 0 then
      while SoundPlaying <> 0 do;
    NoSound;
    ShowDosExitScreen;
    { Return BIOS timing and vectors to normal before resynchronizing the DOS clock. }
    RestoreDefaultTimer;
    RestoreGameInterrupts;
    SyncDosClockFromCmos;
    SaveGameConfig;
  end
  else
  begin
    PgSetBiosVideoMode(GameBiosColorTextMode);
{$IFDEF SAM1}
    Writeln('This game requires and EGA or VGA Adapter!');
{$ELSE}
    Writeln('This game requires an EGA or VGA Adapter!');
{$ENDIF}
    NoSound;
  end;
end.
