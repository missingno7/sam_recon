unit SAMPLAY;
{$A+}{$D+}{$L+}{$F-}
interface
uses SAMDATA;
function ActorNearViewport(MarginPixels, ActorSlot: Integer): Boolean;
function ShotNearViewport(ShotNearViewport_MarginPixels: Integer; ShotNearViewport_ShotSlot: Word): Boolean;
procedure RequestIslandReturn;
procedure UpdatePlayerMoveSpeed;
procedure DamagePlayerOnContact(ContactX, ContactY: Integer);
function ConsumeShotsAtActor(TargetX, TargetY: Integer): Boolean;
procedure SpawnScorePopup(PopupX, PopupY: Integer; PopupImage: Word);
procedure SpawnEnemyProjectile(SpawnX, SpawnY, SpawnEnemyProjectile_Direction, MoveSpeed, ProjectileSprite: Integer);
procedure UpdateBasicActor(ProposedX, ProposedY: Integer; UpdateBasicActor_ActorSlot: Word; ScanColumn, ScanRow: Word);
procedure UpdateActorsAndShots;
function PlayerPositionIsClear(MoveOffsetX, MoveOffsetY: Word): Boolean;
procedure ApplyPlayerGravity;
procedure MovePlayerAndCamera;
procedure UpdatePlayerJump;
procedure ProcessPlayerTileContact(ProcessPlayerTileConta_ContactX, ProcessPlayerTileConta_ContactY: Integer);
procedure CheckPlayerTileContacts;
implementation
uses Dos, PROGRPHX, Crt, SAMSOUND, GAMEJOY, PCXGENUS, TEXT80, SAMUI, SAMLEVEL;
{$F+}
{ Checks d_34EC[Item] against camera bounds 320x184 enlarged by Distance. }
function ActorNearViewport(MarginPixels, ActorSlot: Integer): Boolean;
begin
  if GameActors[ActorSlot].ActorWorldX < CameraX - MarginPixels then
    ActorNearViewport := False
  else if GameActors[ActorSlot].ActorWorldX > CameraX + 320 + MarginPixels then
    ActorNearViewport := False
  else if GameActors[ActorSlot].ActorWorldY < CameraY - MarginPixels then
    ActorNearViewport := False
  else if GameActors[ActorSlot].ActorWorldY > CameraY + 184 + MarginPixels then
    ActorNearViewport := False
  else
    ActorNearViewport := True;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Checks d_685A[slot] against camera bounds 320x184 enlarged by margin. }
function ShotNearViewport(ShotNearViewport_MarginPixels: Integer; ShotNearViewport_ShotSlot: Word): Boolean;
begin
  if PlayerShots[ShotNearViewport_ShotSlot].ActorWorldX < CameraX - ShotNearViewport_MarginPixels then
  begin
    ShotNearViewport := False;
    Exit;
  end;
  if PlayerShots[ShotNearViewport_ShotSlot].ActorWorldX > CameraX + $0140 + ShotNearViewport_MarginPixels then
  begin
    ShotNearViewport := False;
    Exit;
  end;
  if PlayerShots[ShotNearViewport_ShotSlot].ActorWorldY < CameraY - ShotNearViewport_MarginPixels then
  begin
    ShotNearViewport := False;
    Exit;
  end;
  if PlayerShots[ShotNearViewport_ShotSlot].ActorWorldY > CameraY + $00B8 + ShotNearViewport_MarginPixels then
  begin
    ShotNearViewport := False;
    Exit;
  end;
  ShotNearViewport := True;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Sets d_6EC8 unless god mode is active; p_1148 responds by restoring campaign state/reloading the island map. }
procedure RequestIslandReturn;
begin
  if PlayerGodMode = 0 then
    RestoreSnapshotRequested := 1;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Increments the movement ramp and selects horizontal step 1, 2, 4 or boosted/halved speed. }
procedure UpdatePlayerMoveSpeed;
begin
  Inc(MoveRampTicks);
  if PlayerSlowMovement = 0 then
  begin
    case MoveRampTicks of
      1..2: PlayerHorizontalStep := 1;
      3: PlayerHorizontalStep := 2;
      4..6: PlayerHorizontalStep := 4;
      7..1000: PlayerHorizontalStep := PlayerSpeedBoost + 4;
    end;
  end
  else
  begin
    case MoveRampTicks of
      1..4: PlayerHorizontalStep := 1;
      5..6: PlayerHorizontalStep := 2;
      7..1000: PlayerHorizontalStep := (PlayerSpeedBoost + 4) shr 1;
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Tests a 10x16 contact box, consumes health with a hurt cooldown, or starts the death sequence. }
procedure DamagePlayerOnContact(ContactX, ContactY: Integer);
begin
  if ((GameActors[1].ActorWorldX >= ContactX) and (ContactX + 9 >= GameActors[1].ActorWorldX)) or
     ((GameActors[1].ActorWorldX + 9 >= ContactX) and (GameActors[1].ActorWorldX <= ContactX)) then
  begin
    if ((GameActors[1].ActorWorldY >= ContactY) and (ContactY + 15 >= GameActors[1].ActorWorldY)) or
       ((GameActors[1].ActorWorldY + 15 >= ContactY) and (GameActors[1].ActorWorldY <= ContactY)) then
    begin
      if PlayerDying = 0 then
      begin
        if PlayerGodMode = 0 then
        begin
          if PlayerHealth > 1 then
          begin
            if PlayerDamageGraceActive = 0 then
            begin
              PlayerDamageGraceActive := 1;
              PlayerDamageGraceTick := 30;
              Dec(PlayerHealth);
              StatusBarCameraX := -1;
              GameActors[1].FlashFrames := 5;
              StartSoundEffect(7);
            end;
          end
          else
          begin
            if PlayerDamageGraceActive = 0 then
            begin
              StartSoundEffect($16);
              PlayerDying := 1;
              DeathAnimationTick := $23;
            end;
          end;
        end;
      end;
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Returns true for overlapping player projectiles, marks them for removal and restores the tiles beneath them. }
function ConsumeShotsAtActor(TargetX, TargetY: Integer): Boolean;
var
  ConsumeShotsAtActor_ShotSlot: Integer;
begin
  ConsumeShotsAtActor := False;
  for ConsumeShotsAtActor_ShotSlot := 1 to PlayerProjectileLimit do
  begin
    if (PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorSlotInactive = 0) and
       (PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorWorldX + 7 >= TargetX) and
       (PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorWorldX <= TargetX + 6) and
       (PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorWorldY + 8 >= TargetY) and
       (PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorWorldY <= TargetY + 8) then
    begin
      ConsumeShotsAtActor := True;
      PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorRemovalPending := 1;
      RedrawLevelCell(PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorWorldX,
      PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorWorldY);
      DrawCellForeground(PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorWorldX,
      PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorWorldY);
      if (TargetX and $000F) > 0 then
      begin
        RedrawLevelCell(PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorWorldX - 16,
        PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorWorldY);
        RedrawLevelCell(PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorWorldX + 16,
        PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorWorldY);
        DrawCellForeground(PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorWorldX - 16,
        PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorWorldY);
        DrawCellForeground(PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorWorldX + 16,
        PlayerShots[ConsumeShotsAtActor_ShotSlot].ActorWorldY);
      end;
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Allocates a rising kind-5001 actor with sprite param3+150; callers choose images 17..23 for awarded scores. }
procedure SpawnScorePopup(PopupX, PopupY: Integer; PopupImage: Word);
var
  SpawnScorePopup_ActorSlot: Word;
  PopupAllocated: String[4];
begin
  SpawnScorePopup_ActorSlot := 0;
  PopupAllocated[1] := #0;
  repeat
    Inc(SpawnScorePopup_ActorSlot);
    if GameActors[SpawnScorePopup_ActorSlot].ActorSlotInactive = 1 then
    begin
      GameActors[SpawnScorePopup_ActorSlot].FlashFrames := 0;
      GameActors[SpawnScorePopup_ActorSlot].ActorWorldX := PopupX;
      GameActors[SpawnScorePopup_ActorSlot].ActorWorldY := PopupY;
      GameActors[SpawnScorePopup_ActorSlot].ActorPreviousX := PopupX;
      GameActors[SpawnScorePopup_ActorSlot].ActorPreviousY := PopupY;
      GameActors[SpawnScorePopup_ActorSlot].DirectionY := 0;
      GameActors[SpawnScorePopup_ActorSlot].ActorMovementStep := 0;
      GameActors[SpawnScorePopup_ActorSlot].ActorCounterA := 0;
      GameActors[SpawnScorePopup_ActorSlot].ActorCounterB := $10;
      GameActors[SpawnScorePopup_ActorSlot].ActorSlotInactive := 0;
      GameActors[SpawnScorePopup_ActorSlot].ActorRemovalPending := 0;
      GameActors[SpawnScorePopup_ActorSlot].ActorKindCode := $1389;
      GameActors[SpawnScorePopup_ActorSlot].ActorSpriteBase := PopupImage + $96;
      GameActors[SpawnScorePopup_ActorSlot].ActorAnimationCounter := 1;
      GameActors[SpawnScorePopup_ActorSlot].ActorMovementStep := 0;
      GameActors[SpawnScorePopup_ActorSlot].ActorDirectionX := 1;
      PgBlitMaskedShifted16x16(SpriteBank151^.SpriteEntries[PopupImage].SpriteDataBytes[1],
        GameActors[SpawnScorePopup_ActorSlot].ActorWorldX, Word((LongInt(GameActors[SpawnScorePopup_ActorSlot].ActorWorldY +
        8) and $fff0) + $10));
      PgBlitMaskedShifted16x16(SpriteBank151^.SpriteEntries[PopupImage].SpriteDataBytes[1],
        GameActors[SpawnScorePopup_ActorSlot].ActorWorldX, Word((LongInt(GameActors[SpawnScorePopup_ActorSlot].ActorWorldY +
        8) and $fff0) + $1a0));
      PopupAllocated[1] := #1;
    end;
  until (PopupAllocated[1] <> #0) or (SpawnScorePopup_ActorSlot = $19);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Allocates an actor projectile/effect, selecting direction, speed, sprite and behavior from EntryId. }
procedure SpawnEnemyProjectile(SpawnX, SpawnY, SpawnEnemyProjectile_Direction, MoveSpeed, ProjectileSprite: Integer);
var
  SpawnEnemyProjectile_ActorSlot, UnusedSpawnWord1, UnusedSpawnWord2: Integer;
  ProjectileAllocated: Boolean;
begin
  SpawnEnemyProjectile_ActorSlot := 0;
  ProjectileAllocated := False;
  repeat
    Inc(SpawnEnemyProjectile_ActorSlot);
    if GameActors[SpawnEnemyProjectile_ActorSlot].ActorSlotInactive = 1 then
    begin
      StartSoundEffect(3);
      GameActors[SpawnEnemyProjectile_ActorSlot].ActorDirectionX := SpawnEnemyProjectile_Direction;
      if GameActors[SpawnEnemyProjectile_ActorSlot].ActorDirectionX = -1 then
        GameActors[SpawnEnemyProjectile_ActorSlot].ActorAnimationCounter := $15
      else
        GameActors[SpawnEnemyProjectile_ActorSlot].ActorAnimationCounter := 1;
      GameActors[SpawnEnemyProjectile_ActorSlot].DirectionY := 0;
      GameActors[SpawnEnemyProjectile_ActorSlot].FlashFrames := 0;
      if ProjectileSprite <> $89 then
        GameActors[SpawnEnemyProjectile_ActorSlot].ActorWorldX := SpawnX and $FFF8
      else
        GameActors[SpawnEnemyProjectile_ActorSlot].ActorWorldX := SpawnX;
      GameActors[SpawnEnemyProjectile_ActorSlot].ActorWorldY := SpawnY;
      GameActors[SpawnEnemyProjectile_ActorSlot].ActorPreviousX := SpawnX;
      GameActors[SpawnEnemyProjectile_ActorSlot].ActorPreviousY := SpawnY;
      GameActors[SpawnEnemyProjectile_ActorSlot].ActorMovementStep := MoveSpeed;
      GameActors[SpawnEnemyProjectile_ActorSlot].ActorCounterA := 0;
      GameActors[SpawnEnemyProjectile_ActorSlot].ActorCounterB := 0;
      GameActors[SpawnEnemyProjectile_ActorSlot].ActorSlotInactive := 0;
      GameActors[SpawnEnemyProjectile_ActorSlot].ActorRemovalPending := 0;
      if ProjectileSprite = 0 then
      begin
        GameActors[SpawnEnemyProjectile_ActorSlot].ActorSpriteBase := $27;
        GameActors[SpawnEnemyProjectile_ActorSlot].ActorKindCode := 7;
        GameActors[SpawnEnemyProjectile_ActorSlot].ActorAnimationCounter := 1;
      end
      else
      begin
        GameActors[SpawnEnemyProjectile_ActorSlot].ActorSpriteBase := ProjectileSprite;
        if (GameActors[SpawnEnemyProjectile_ActorSlot].ActorSpriteBase = $1D6) or
           (GameActors[SpawnEnemyProjectile_ActorSlot].ActorSpriteBase = $7D) or
           (GameActors[SpawnEnemyProjectile_ActorSlot].ActorSpriteBase = $7E) then
        begin
          GameActors[SpawnEnemyProjectile_ActorSlot].ActorKindCode := 7;
          GameActors[SpawnEnemyProjectile_ActorSlot].ActorAnimationCounter := 1;
        end
        else if (GameActors[SpawnEnemyProjectile_ActorSlot].ActorSpriteBase = $339) or
                (GameActors[SpawnEnemyProjectile_ActorSlot].ActorSpriteBase = $33B) then
        begin
          GameActors[SpawnEnemyProjectile_ActorSlot].ActorKindCode := $13;
          GameActors[SpawnEnemyProjectile_ActorSlot].ActorAnimationCounter := 1;
        end
        else if GameActors[SpawnEnemyProjectile_ActorSlot].ActorSpriteBase = $72 then
        begin
          GameActors[SpawnEnemyProjectile_ActorSlot].ActorKindCode := $25;
          GameActors[SpawnEnemyProjectile_ActorSlot].ActorAnimationCounter := 1;
          GameActors[SpawnEnemyProjectile_ActorSlot].DirectionY := SpawnEnemyProjectile_Direction;
        end
        else if GameActors[SpawnEnemyProjectile_ActorSlot].ActorSpriteBase = $C7 then
        begin
          GameActors[SpawnEnemyProjectile_ActorSlot].ActorSpriteBase := $72;
          GameActors[SpawnEnemyProjectile_ActorSlot].ActorKindCode := $89;
          GameActors[SpawnEnemyProjectile_ActorSlot].ActorAnimationCounter := 1;
          GameActors[SpawnEnemyProjectile_ActorSlot].DirectionY := SpawnEnemyProjectile_Direction;
        end
        else if GameActors[SpawnEnemyProjectile_ActorSlot].ActorSpriteBase = $89 then
        begin
          GameActors[SpawnEnemyProjectile_ActorSlot].ActorKindCode := $28;
          GameActors[SpawnEnemyProjectile_ActorSlot].ActorAnimationCounter := 1;
          GameActors[SpawnEnemyProjectile_ActorSlot].ActorCounterB := $1E;
        end
        else
          GameActors[SpawnEnemyProjectile_ActorSlot].ActorKindCode := $0E;
      end;
      ProjectileAllocated := True;
    end;
  until ProjectileAllocated or (SpawnEnemyProjectile_ActorSlot = 25);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Dispatches behavior kinds below 30, including walkers, guns, hazards, explosions, pickups. }
procedure UpdateBasicActor(ProposedX, ProposedY: Integer; UpdateBasicActor_ActorSlot: Word; ScanColumn, ScanRow: Word);
var
  HorizontalWork, VerticalWork, RightCellColumn, UpperCellRow: Integer;
begin
  case GameActors[UpdateBasicActor_ActorSlot].ActorKindCode of
    1:
    begin
      HorizontalWork := (ProposedX shr 4) + 1;
      UpperCellRow := (ProposedY shr 4) + 1;
      VerticalWork := UpperCellRow + 1;
      RightCellColumn := ((ProposedX + 15) shr 4) + 1;
      if LevelCells[HorizontalWork, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := 1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end
      else if LevelCells[RightCellColumn, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end
      else if (LevelCells[HorizontalWork, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[HorizontalWork, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := 1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end
      else if (LevelCells[RightCellColumn, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[RightCellColumn, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end;
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter);
      if GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = 1 then
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 19 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end
      else
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 39 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end;
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldX := ProposedX;
      DamagePlayerOnContact(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldY);
      if ConsumeShotsAtActor(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldY) then
      begin
        StartSoundEffect(19);
        PlayerScore := PlayerScore + 100;
        StatusBarCameraX := -1;
        GameActors[UpdateBasicActor_ActorSlot].ActorKindCode := 5000;
        GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := 391;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
        GameActors[UpdateBasicActor_ActorSlot].ActorMovementStep := 0;
        PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[6403], GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY + 16);
        PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[6403], GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY + 416);
      end;
    end;
    2:
    begin
      HorizontalWork := (ProposedX shr 4) + 1;
      UpperCellRow := (ProposedY shr 4) + 1;
      VerticalWork := UpperCellRow + 1;
      RightCellColumn := ((ProposedX + 15) shr 4) + 1;
      if LevelCells[HorizontalWork, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := 1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end
      else if LevelCells[RightCellColumn, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end
      else if (LevelCells[HorizontalWork, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[HorizontalWork, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := 1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end
      else if (LevelCells[RightCellColumn, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[RightCellColumn, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end;
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter);
      if GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = 1 then
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 19 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end
      else
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 39 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end;
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldX := ProposedX;
      DamagePlayerOnContact(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldY);
      if ConsumeShotsAtActor(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldY) then
      begin
        StartSoundEffect(8);
        Dec(GameActors[UpdateBasicActor_ActorSlot].ActorKindCode);
        GameActors[UpdateBasicActor_ActorSlot].FlashFrames := 3;
        GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := 351;
        GameActors[UpdateBasicActor_ActorSlot].ActorMovementStep := 1;
        GameActors[UpdateBasicActor_ActorSlot].ActorCounterA := Random(50) + 50;
        GameActors[UpdateBasicActor_ActorSlot].ActorCounterB := 0;
        if GameActors[UpdateBasicActor_ActorSlot].ActorWorldX < GameActors[1].ActorWorldX then
          GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := 1
        else
          GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -1;
        if GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = 1 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1
        else
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end;
    end;
    3:
    begin
      HorizontalWork := (ProposedX shr 4) + 1;
      UpperCellRow := (ProposedY shr 4) + 1;
      VerticalWork := UpperCellRow + 1;
      RightCellColumn := ((ProposedX + 15) shr 4) + 1;
      if LevelCells[HorizontalWork, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := 1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end
      else if LevelCells[RightCellColumn, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end
      else if (LevelCells[HorizontalWork, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[HorizontalWork, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := 1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end
      else if (LevelCells[RightCellColumn, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[RightCellColumn, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end;
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter);
      if GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = 1 then
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 19 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end
      else
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 39 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end;
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldX := ProposedX;
      if ConsumeShotsAtActor(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldY) then
      begin
        StartSoundEffect(8);
        Dec(GameActors[UpdateBasicActor_ActorSlot].ActorKindCode);
        GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := 359;
        GameActors[UpdateBasicActor_ActorSlot].FlashFrames := 3;
        GameActors[UpdateBasicActor_ActorSlot].ActorMovementStep := 2;
        if GameActors[UpdateBasicActor_ActorSlot].ActorWorldX < GameActors[1].ActorWorldX then
          GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := 1
        else
          GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -1;
        if GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = 1 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1
        else
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end
      else
        DamagePlayerOnContact(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY);
    end;
    4:
    begin
      HorizontalWork := (ProposedX shr 4) + 1;
      UpperCellRow := (ProposedY shr 4) + 1;
      VerticalWork := UpperCellRow + 1;
      RightCellColumn := ((ProposedX + 15) shr 4) + 1;
      if LevelCells[HorizontalWork, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := 1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end
      else if LevelCells[RightCellColumn, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end
      else if (LevelCells[HorizontalWork, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[HorizontalWork, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := 1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end
      else if (LevelCells[RightCellColumn, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[RightCellColumn, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end;
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter);
      if GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = 1 then
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 19 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end
      else
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 39 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end;
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorCounterB);
      if GameActors[UpdateBasicActor_ActorSlot].ActorCounterB >= GameActors[UpdateBasicActor_ActorSlot].ActorCounterA then
      begin
        if (GameActors[UpdateBasicActor_ActorSlot].ActorWorldY shr 4) = ((GameActors[1].ActorWorldY + 8) shr 4) then
        begin
          if ((GameActors[UpdateBasicActor_ActorSlot].ActorWorldX < GameActors[1].ActorWorldX) and
          (GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = 1)) or
             ((GameActors[UpdateBasicActor_ActorSlot].ActorWorldX > GameActors[1].ActorWorldX) and
             (GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = -1)) then
          begin
            GameActors[UpdateBasicActor_ActorSlot].ActorCounterB := 0;
            SpawnEnemyProjectile(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
            GameActors[UpdateBasicActor_ActorSlot].ActorWorldY, GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX, 4, 0);
          end;
        end;
      end;
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldX := ProposedX;
      DamagePlayerOnContact(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldY);
      if ConsumeShotsAtActor(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldY) then
      begin
        StartSoundEffect(8);
        Dec(GameActors[UpdateBasicActor_ActorSlot].ActorKindCode);
        GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := 367;
        GameActors[UpdateBasicActor_ActorSlot].FlashFrames := 3;
        GameActors[UpdateBasicActor_ActorSlot].ActorMovementStep := 3;
        if GameActors[UpdateBasicActor_ActorSlot].ActorWorldX < GameActors[1].ActorWorldX then
          GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := 1
        else
          GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -1;
        if GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = 1 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1
        else
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end;
    end;
    5:
    begin
      HorizontalWork := (ProposedX shr 4) + 1;
      UpperCellRow := (ProposedY shr 4) + 1;
      VerticalWork := UpperCellRow + 1;
      RightCellColumn := ((ProposedX + 15) shr 4) + 1;
      if LevelCells[HorizontalWork, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := 1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end
      else if LevelCells[RightCellColumn, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end
      else if (LevelCells[HorizontalWork, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[HorizontalWork, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := 1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end
      else if (LevelCells[RightCellColumn, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[RightCellColumn, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -1;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end;
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter);
      if GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = 1 then
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 19 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end
      else
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 39 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end;
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorCounterB);
      if GameActors[UpdateBasicActor_ActorSlot].ActorCounterB >= GameActors[UpdateBasicActor_ActorSlot].ActorCounterA then
      begin
        if (GameActors[UpdateBasicActor_ActorSlot].ActorWorldY shr 4) = ((GameActors[1].ActorWorldY + 8) shr 4) then
        begin
          if ((GameActors[UpdateBasicActor_ActorSlot].ActorWorldX < GameActors[1].ActorWorldX) and
          (GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = 1)) or
             ((GameActors[UpdateBasicActor_ActorSlot].ActorWorldX > GameActors[1].ActorWorldX) and
             (GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = -1)) then
          begin
            GameActors[UpdateBasicActor_ActorSlot].ActorCounterB := 0;
            SpawnEnemyProjectile(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
            GameActors[UpdateBasicActor_ActorSlot].ActorWorldY, GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX, 4, 0);
          end;
        end;
      end;
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldX := ProposedX;
      DamagePlayerOnContact(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldY);
      if ConsumeShotsAtActor(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldY) then
      begin
        StartSoundEffect(8);
        Dec(GameActors[UpdateBasicActor_ActorSlot].ActorKindCode);
        GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := 375;
        GameActors[UpdateBasicActor_ActorSlot].FlashFrames := 3;
        if GameActors[UpdateBasicActor_ActorSlot].ActorWorldX < GameActors[1].ActorWorldX then
          GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := 1
        else
          GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -1;
        if GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = 1 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1
        else
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end;
    end;
    6:
    begin
      if (LevelCells[(ProposedX shr 4) + 1, (ProposedY shr 4) + 1].CellSolidFlag <> 0) or
         (LevelCells[((ProposedX + 15) shr 4) + 1, (ProposedY shr 4) + 1].CellSolidFlag <> 0) then
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX;
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter);
      if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 19 then
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldX := ProposedX;
      DamagePlayerOnContact(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldY);
      if GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase = 625 then
      begin
        Dec(GameActors[UpdateBasicActor_ActorSlot].ActorCounterB);
        if GameActors[UpdateBasicActor_ActorSlot].ActorCounterB <= 0 then
        begin
          GameActors[UpdateBasicActor_ActorSlot].ActorRemovalPending := 1;
          RedrawLevelCell(ProposedX, ProposedY);
          RedrawLevelCell(ProposedX - 16, ProposedY);
          RedrawLevelCell(ProposedX + 16, ProposedY);
          DrawCellForeground(ProposedX, ProposedY);
          DrawCellForeground(ProposedX - 16, ProposedY);
          DrawCellForeground(ProposedX + 16, ProposedY);
        end;
      end
      else
      begin
        if ConsumeShotsAtActor(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY) then
        begin
          StartSoundEffect(8);
          Dec(GameActors[UpdateBasicActor_ActorSlot].ActorCounterA);
          GameActors[UpdateBasicActor_ActorSlot].FlashFrames := 3;
          if GameActors[UpdateBasicActor_ActorSlot].ActorCounterA <= 0 then
          begin
            GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := 625;
            GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
            GameActors[UpdateBasicActor_ActorSlot].ActorMovementStep := 1;
          end;
        end;
      end;
    end;
    7:
    begin
      VerticalWork := (ProposedY shr 4) + 1;
      if (LevelCells[(ProposedX shr 4) + 1, VerticalWork].CellSolidFlag <> 0) or
         (LevelCells[((ProposedX + 15) shr 4) + 1, VerticalWork].CellSolidFlag <> 0) then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorRemovalPending := 1;
        RedrawLevelCell(ProposedX, ProposedY);
        RedrawLevelCell(ProposedX - 16, ProposedY);
        RedrawLevelCell(ProposedX + 16, ProposedY);
        DrawCellForeground(ProposedX, ProposedY);
        DrawCellForeground(ProposedX - 16, ProposedY);
        DrawCellForeground(ProposedX + 16, ProposedY);
      end
      else
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldX := ProposedX;
        HorizontalWork := GameActors[1].ActorWorldX - GameActors[UpdateBasicActor_ActorSlot].ActorWorldX;
        VerticalWork := GameActors[1].ActorWorldY - GameActors[UpdateBasicActor_ActorSlot].ActorWorldY;
        if (HorizontalWork < 8) and (HorizontalWork > -8) and (VerticalWork < 8) and (VerticalWork > -8) then
        begin
          if PlayerGodMode = 0 then
          begin
            if PlayerDying = 0 then
            begin
              if PlayerHealth > 1 then
              begin
                if PlayerDamageGraceActive = 0 then
                begin
                  PlayerDamageGraceActive := 1;
                  PlayerDamageGraceTick := 30;
                  Dec(PlayerHealth);
                  StatusBarCameraX := -1;
                  GameActors[1].FlashFrames := 5;
                end;
              end
              else
              begin
                if PlayerDamageGraceActive = 0 then
                begin
                  PlayerDying := 1;
                  DeathAnimationTick := 35;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
    10, 12:
    begin
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorCounterB);
      if GameActors[UpdateBasicActor_ActorSlot].ActorCounterB >= GameActors[UpdateBasicActor_ActorSlot].ActorCounterA then
      begin
        if (GameActors[UpdateBasicActor_ActorSlot].ActorWorldY and $FFF0) = ((GameActors[1].ActorWorldY + 8) and $FFF0) then
        begin
          if GameActors[UpdateBasicActor_ActorSlot].ActorWorldX < GameActors[1].ActorWorldX then
          begin
            GameActors[UpdateBasicActor_ActorSlot].ActorCounterB := 0;
            if GameActors[UpdateBasicActor_ActorSlot].ActorKindCode = 10 then
              SpawnEnemyProjectile(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX + 8,
              GameActors[UpdateBasicActor_ActorSlot].ActorWorldY, 1, 4, 470)
            else
              SpawnEnemyProjectile(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX + 16,
              GameActors[UpdateBasicActor_ActorSlot].ActorWorldY, 1, 4, 488);
          end;
        end;
      end;
    end;
    11, 13:
    begin
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorCounterB);
      if GameActors[UpdateBasicActor_ActorSlot].ActorCounterB >= GameActors[UpdateBasicActor_ActorSlot].ActorCounterA then
      begin
        if (GameActors[UpdateBasicActor_ActorSlot].ActorWorldY and $FFF0) = ((GameActors[1].ActorWorldY + 8) and $FFF0) then
        begin
          if GameActors[UpdateBasicActor_ActorSlot].ActorWorldX > GameActors[1].ActorWorldX then
          begin
            GameActors[UpdateBasicActor_ActorSlot].ActorCounterB := 0;
            if GameActors[UpdateBasicActor_ActorSlot].ActorKindCode = 11 then
              SpawnEnemyProjectile(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX - 8,
              GameActors[UpdateBasicActor_ActorSlot].ActorWorldY, -1, 4, 470)
            else
              SpawnEnemyProjectile(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX - 16,
              GameActors[UpdateBasicActor_ActorSlot].ActorWorldY, -1, 4, 492);
          end;
        end;
      end;
    end;
    14:
    begin
      VerticalWork := (ProposedY shr 4) + 1;
      if (LevelCells[(ProposedX shr 4) + 1, VerticalWork].CellSolidFlag <> 0) or
         (LevelCells[((ProposedX + 15) shr 4) + 1, VerticalWork].CellSolidFlag <> 0) then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorRemovalPending := 1;
        RedrawLevelCell(ProposedX, ProposedY);
        RedrawLevelCell(ProposedX - 16, ProposedY);
        RedrawLevelCell(ProposedX + 16, ProposedY);
        DrawCellForeground(ProposedX, ProposedY);
        DrawCellForeground(ProposedX - 16, ProposedY);
        DrawCellForeground(ProposedX + 16, ProposedY);
      end
      else
      begin
        Inc(GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter);
      if GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = 1 then
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 19 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end
      else
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 39 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 21;
      end;
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldX := ProposedX;
        DamagePlayerOnContact(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY);
      end;
    end;
    15:
    begin
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorCounterB);
      if GameActors[UpdateBasicActor_ActorSlot].ActorCounterB >= GameActors[UpdateBasicActor_ActorSlot].ActorCounterA then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := ((GameActors[UpdateBasicActor_ActorSlot].ActorCounterB -
        GameActors[UpdateBasicActor_ActorSlot].ActorCounterA) shr 2) + 429;
        if GameActors[UpdateBasicActor_ActorSlot].ActorCounterB = 45 then
        begin
          GameActors[UpdateBasicActor_ActorSlot].ActorCounterB := 0;
          GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := 435;
        end;
        DamagePlayerOnContact(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY);
      end;
    end;
    16:
    begin
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorCounterB);
      if GameActors[UpdateBasicActor_ActorSlot].ActorCounterB >= GameActors[UpdateBasicActor_ActorSlot].ActorCounterA then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := ((GameActors[UpdateBasicActor_ActorSlot].ActorCounterB -
        GameActors[UpdateBasicActor_ActorSlot].ActorCounterA) shr 2) + 437;
        if GameActors[UpdateBasicActor_ActorSlot].ActorCounterB = 45 then
        begin
          GameActors[UpdateBasicActor_ActorSlot].ActorCounterB := 0;
          GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := 435;
        end;
        DamagePlayerOnContact(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY);
      end;
    end;
    17:
    begin
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorCounterB);
      HorizontalWork := GameActors[UpdateBasicActor_ActorSlot].ActorCounterB -
      GameActors[UpdateBasicActor_ActorSlot].ActorCounterA;
      if HorizontalWork >= 0 then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := (HorizontalWork shr 2) + 471;
        if GameActors[UpdateBasicActor_ActorSlot].ActorCounterB = 60 then
        begin
          GameActors[UpdateBasicActor_ActorSlot].ActorCounterB := 0;
          GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := 435;
        end;
        DamagePlayerOnContact(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY + 8);
      end;
    end;
    18:
    begin
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorCounterB);
      HorizontalWork := GameActors[UpdateBasicActor_ActorSlot].ActorCounterB -
      GameActors[UpdateBasicActor_ActorSlot].ActorCounterA;
      if HorizontalWork >= 0 then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := (HorizontalWork shr 2) + 479;
        if GameActors[UpdateBasicActor_ActorSlot].ActorCounterB = 60 then
        begin
          GameActors[UpdateBasicActor_ActorSlot].ActorCounterB := 0;
          GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := 435;
        end;
        DamagePlayerOnContact(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY - 8);
      end;
    end;
    19:
    begin
      VerticalWork := (ProposedY shr 4) + 1;
      if (LevelCells[(ProposedX shr 4) + 1, VerticalWork].CellSolidFlag <> 0) or
         (LevelCells[((ProposedX + 15) shr 4) + 1, VerticalWork].CellSolidFlag <> 0) then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorRemovalPending := 1;
        RedrawLevelCell(ProposedX, ProposedY);
        RedrawLevelCell(ProposedX - 16, ProposedY);
        RedrawLevelCell(ProposedX + 16, ProposedY);
        DrawCellForeground(ProposedX, ProposedY);
        DrawCellForeground(ProposedX - 16, ProposedY);
        DrawCellForeground(ProposedX + 16, ProposedY);
      end
      else
      begin
        Inc(GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter);
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 9 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldX := ProposedX;
        DamagePlayerOnContact(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY);
      end;
    end;
    20:
    begin
      VerticalWork := ((ProposedY + 8) shr 4) + 1;
      HorizontalWork := ((ProposedX + 8) shr 4) + 1;
      if (LevelCells[((ProposedX + 3) shr 4) + 1, VerticalWork].CellSolidFlag <> 0) or
         (LevelCells[((ProposedX + 12) shr 4) + 1, VerticalWork].CellSolidFlag <> 0) or
         ((LevelCells[HorizontalWork, VerticalWork + 1].CellSolidFlag = 0) and (LevelCells[HorizontalWork, VerticalWork +
         1].SupportsLanding = 0)) then
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX;
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter);
      if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 19 then
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldX := ProposedX;
      DamagePlayerOnContact(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldY);
    end;
    21:
    begin
      if LevelCells[((ProposedX + 8) shr 4) + 1 + GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX,
                ((ProposedY + 8) shr 4) + 1].CellSolidFlag <> 0 then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX;
        if GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = 1 then
          GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := 497
        else
          GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := 495;
      end;
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter);
      if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 9 then
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldX := ProposedX;
      DamagePlayerOnContact(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldY);
    end;
    22:
    begin
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter);
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorCounterB);
      if (GameActors[UpdateBasicActor_ActorSlot].ActorCounterB = GameActors[UpdateBasicActor_ActorSlot].ActorCounterA) and
         (GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase = 635) then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
        GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := 625;
        GameActors[UpdateBasicActor_ActorSlot].ActorCounterB := GameActors[UpdateBasicActor_ActorSlot].ActorCounterB - 10;
      end
      else if GameActors[UpdateBasicActor_ActorSlot].ActorCounterB = GameActors[UpdateBasicActor_ActorSlot].ActorCounterA then
      begin
        StartSoundEffect(11);
        for ScanRow := 1 to 24 do
        begin
          for ScanColumn := 1 to 40 do
          begin
            if LevelCells[ScanColumn, ScanRow].CellObjectCode = 637 then
            begin
              LevelCells[ScanColumn, ScanRow].CellObjectCode := 638;
              LevelCells[ScanColumn, ScanRow].CellSolidFlag := 0;
              LevelCells[ScanColumn, ScanRow - 1].CellObjectCode := 0;
              LevelCells[ScanColumn, ScanRow - 1].CellOverlayTile := 634;
              LevelCells[ScanColumn, ScanRow - 1].CellSolidFlag := 0;
              Dec(ScanColumn);
              Dec(ScanRow);
              ScanColumn := ScanColumn shl 4;
              ScanRow := ScanRow shl 4;
              RedrawLevelCell(ScanColumn, ScanRow);
              DrawCellForeground(ScanColumn, ScanRow);
              RedrawLevelCell(ScanColumn - 16, ScanRow);
              DrawCellForeground(ScanColumn - 16, ScanRow);
              RedrawLevelCell(ScanColumn + 16, ScanRow);
              DrawCellForeground(ScanColumn + 16, ScanRow);
              RedrawLevelCell(ScanColumn, ScanRow - 16);
              DrawCellForeground(ScanColumn, ScanRow - 16);
              GameDrawBufferRow := 432 - GameDrawBufferRow;
              RedrawLevelCell(ScanColumn, ScanRow);
              DrawCellForeground(ScanColumn, ScanRow);
              RedrawLevelCell(ScanColumn - 16, ScanRow);
              DrawCellForeground(ScanColumn - 16, ScanRow);
              RedrawLevelCell(ScanColumn + 16, ScanRow);
              DrawCellForeground(ScanColumn + 16, ScanRow);
              RedrawLevelCell(ScanColumn, ScanRow - 16);
              DrawCellForeground(ScanColumn, ScanRow - 16);
              GameDrawBufferRow := 432 - GameDrawBufferRow;
              ScanColumn := ScanColumn shr 4;
              ScanRow := ScanRow shr 4;
              Inc(ScanColumn);
              Inc(ScanRow);
            end;
          end;
        end;
        DamagePlayerOnContact(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY);
      end;
      if GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase = 625 then
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 11 then
        begin
          GameActors[UpdateBasicActor_ActorSlot].ActorRemovalPending := 1;
          RedrawLevelCell(ProposedX, ProposedY);
          RedrawLevelCell(ProposedX - 16, ProposedY);
          RedrawLevelCell(ProposedX + 16, ProposedY);
          DrawCellForeground(ProposedX, ProposedY);
          DrawCellForeground(ProposedX - 16, ProposedY);
          DrawCellForeground(ProposedX + 16, ProposedY);
          GameDrawBufferRow := 432 - GameDrawBufferRow;
          RedrawLevelCell(ProposedX, ProposedY);
          RedrawLevelCell(ProposedX + 16, ProposedY);
          RedrawLevelCell(ProposedX - 16, ProposedY);
          DrawCellForeground(ProposedX, ProposedY);
          DrawCellForeground(ProposedX + 16, ProposedY);
          DrawCellForeground(ProposedX - 16, ProposedY);
          GameDrawBufferRow := 432 - GameDrawBufferRow;
        end;
      end
      else
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 9 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end;
    end;
    23:
    begin
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter);
      if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter = 11 then
        DamagePlayerOnContact(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY);
      if GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase = 625 then
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 11 then
        begin
          GameActors[UpdateBasicActor_ActorSlot].ActorRemovalPending := 1;
          RedrawLevelCell(ProposedX, ProposedY);
          RedrawLevelCell(ProposedX - 16, ProposedY);
          RedrawLevelCell(ProposedX + 16, ProposedY);
          DrawCellForeground(ProposedX, ProposedY);
          DrawCellForeground(ProposedX - 16, ProposedY);
          DrawCellForeground(ProposedX + 16, ProposedY);
          GameDrawBufferRow := 432 - GameDrawBufferRow;
          RedrawLevelCell(ProposedX, ProposedY);
          RedrawLevelCell(ProposedX + 16, ProposedY);
          RedrawLevelCell(ProposedX - 16, ProposedY);
          DrawCellForeground(ProposedX, ProposedY);
          DrawCellForeground(ProposedX + 16, ProposedY);
          DrawCellForeground(ProposedX - 16, ProposedY);
          GameDrawBufferRow := 432 - GameDrawBufferRow;
        end;
      end
      else
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 9 then
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      end;
    end;
    25:
    begin
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorCounterB);
      if GameActors[UpdateBasicActor_ActorSlot].ActorCounterB = GameActors[UpdateBasicActor_ActorSlot].ActorCounterA then
      begin
        GameActors[UpdateBasicActor_ActorSlot].ActorCounterB := 0;
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX;
      end;
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter);
      if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 19 then
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldX := ProposedX;
      if ConsumeShotsAtActor(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
      GameActors[UpdateBasicActor_ActorSlot].ActorWorldY) then
      begin
        StartSoundEffect(8);
        GameActors[UpdateBasicActor_ActorSlot].ActorRemovalPending := 0;
        PlayerScore := PlayerScore + 100;
        StatusBarCameraX := -1;
        GameActors[UpdateBasicActor_ActorSlot].ActorKindCode := 5000;
        GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := 391;
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
        GameActors[UpdateBasicActor_ActorSlot].ActorMovementStep := 0;
        PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[6403], GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY + 16);
        PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[6403], GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY + 416);
      end;
    end;
    26:
    begin
      Inc(GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter);
      if GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter > 19 then
        GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
      if ((GameActors[UpdateBasicActor_ActorSlot].ActorWorldX <= GameActors[1].ActorWorldX) and
          (GameActors[UpdateBasicActor_ActorSlot].ActorWorldX + 9 >= GameActors[1].ActorWorldX)) or
         ((GameActors[1].ActorWorldX + 9 >= GameActors[UpdateBasicActor_ActorSlot].ActorWorldX) and
          (GameActors[UpdateBasicActor_ActorSlot].ActorWorldX >= GameActors[1].ActorWorldX)) then
      begin
        if ((GameActors[UpdateBasicActor_ActorSlot].ActorWorldY <= GameActors[1].ActorWorldY) and
            (GameActors[UpdateBasicActor_ActorSlot].ActorWorldY + 15 >= GameActors[1].ActorWorldY)) or
           ((GameActors[1].ActorWorldY + 15 >= GameActors[UpdateBasicActor_ActorSlot].ActorWorldY) and
            (GameActors[UpdateBasicActor_ActorSlot].ActorWorldY >= GameActors[1].ActorWorldY)) then
        begin
          StartSoundEffect(5);
          PlayerScore := PlayerScore + 10000;
          StatusBarCameraX := -1;
          GameActors[UpdateBasicActor_ActorSlot].ActorKindCode := 5001;
          GameActors[UpdateBasicActor_ActorSlot].ActorCounterB := 16;
          GameActors[UpdateBasicActor_ActorSlot].ActorSpriteBase := 173;
          GameActors[UpdateBasicActor_ActorSlot].ActorAnimationCounter := 1;
          GameActors[UpdateBasicActor_ActorSlot].ActorMovementStep := 0;
          PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3523], GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
          GameActors[UpdateBasicActor_ActorSlot].ActorWorldY + 16);
          PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3523], GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
          GameActors[UpdateBasicActor_ActorSlot].ActorWorldY + 416);
        end;
      end;
    end;
    27:
    begin
      HorizontalWork := ((GameActors[UpdateBasicActor_ActorSlot].ActorWorldX + 3) shr 4) + 1;
      RightCellColumn := ((GameActors[UpdateBasicActor_ActorSlot].ActorWorldX + 13) shr 4) + 1;
      VerticalWork := (GameActors[UpdateBasicActor_ActorSlot].ActorWorldY shr 4) + 2;
      if (LevelCells[HorizontalWork, VerticalWork].CellSolidFlag = 0) and (LevelCells[RightCellColumn,
      VerticalWork].CellSolidFlag = 0) and
         (LevelCells[HorizontalWork, VerticalWork].SupportsLanding = 0) and (LevelCells[RightCellColumn,
         VerticalWork].SupportsLanding = 0) then
      begin
        RedrawLevelCell(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY);
        RedrawLevelCell(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX, GameActors[UpdateBasicActor_ActorSlot].ActorWorldY
        - 16);
        RedrawLevelCell(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX + 16,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY);
        RedrawLevelCell(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX + 16,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY - 16);
        RedrawLevelCell(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX, GameActors[UpdateBasicActor_ActorSlot].ActorWorldY
        + 8);
        RedrawLevelCell(GameActors[UpdateBasicActor_ActorSlot].ActorWorldX + 16,
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY + 8);
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY := GameActors[UpdateBasicActor_ActorSlot].ActorWorldY + 8;
        GameActors[UpdateBasicActor_ActorSlot].ActorKindValue1 := -1;
        PlayerOnMovingSupport := 0;
      end
      else
      begin
        GameActors[UpdateBasicActor_ActorSlot].DirectionY := 0;
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldY := GameActors[UpdateBasicActor_ActorSlot].ActorWorldY and $FFF0;
        if GameActors[UpdateBasicActor_ActorSlot].ActorKindValue1 = -1 then
        begin
          StartSoundEffect(29);
          GameActors[UpdateBasicActor_ActorSlot].ActorKindValue1 := 0;
        end;
      end;
      if ((GameActors[UpdateBasicActor_ActorSlot].ActorWorldX <= GameActors[1].ActorWorldX) and
          (GameActors[UpdateBasicActor_ActorSlot].ActorWorldX + 9 >= GameActors[1].ActorWorldX)) or
         ((GameActors[1].ActorWorldX + 9 >= GameActors[UpdateBasicActor_ActorSlot].ActorWorldX) and
          (GameActors[UpdateBasicActor_ActorSlot].ActorWorldX >= GameActors[1].ActorWorldX)) then
      begin
        if GameActors[UpdateBasicActor_ActorSlot].ActorWorldY = GameActors[1].ActorWorldY then
        begin
          if GameActors[UpdateBasicActor_ActorSlot].ActorWorldX < GameActors[1].ActorWorldX then
          begin
            if LevelCells[((GameActors[UpdateBasicActor_ActorSlot].ActorWorldX - 3) shr 4) + 1,
                      (GameActors[UpdateBasicActor_ActorSlot].ActorWorldY shr 4) + 1].CellSolidFlag = 0 then
              GameActors[UpdateBasicActor_ActorSlot].ActorWorldX := GameActors[1].ActorWorldX - 13;
          end
          else if GameActors[UpdateBasicActor_ActorSlot].ActorWorldX > GameActors[1].ActorWorldX then
          begin
            if LevelCells[((GameActors[UpdateBasicActor_ActorSlot].ActorWorldX + 3) shr 4) + 2,
                      (GameActors[UpdateBasicActor_ActorSlot].ActorWorldY shr 4) + 1].CellSolidFlag = 0 then
              GameActors[UpdateBasicActor_ActorSlot].ActorWorldX := GameActors[1].ActorWorldX + 13;
          end;
        end
        else
        begin
          if (GameActors[1].ActorWorldY + 16 >= GameActors[UpdateBasicActor_ActorSlot].ActorWorldY) and
             (GameActors[UpdateBasicActor_ActorSlot].ActorWorldY >= GameActors[1].ActorWorldY) then
          begin
            if PlayerJumping = 0 then
            begin
              GameActors[1].ActorWorldY := GameActors[UpdateBasicActor_ActorSlot].ActorWorldY - 16;
              PlayerJumping := 0;
              PlayerFalling := 0;
              PlayerOnMovingSupport := 1;
              if GameActors[1].ActorSpriteBase = 13 then
                GameActors[1].ActorSpriteBase := 9
              else if GameActors[1].ActorSpriteBase = 14 then
                GameActors[1].ActorSpriteBase := 10;
            end;
          end;
        end;
      end;
    end;
    28:
    begin
      VerticalWork := (ProposedY shr 4) + 1;
      if (LevelCells[(ProposedX shr 4) + 1, VerticalWork].CellSolidFlag <> 0) or
         (LevelCells[((ProposedX + 15) shr 4) + 1, VerticalWork].CellSolidFlag <> 0) then
        GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX := -GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX;
      if ((GameActors[UpdateBasicActor_ActorSlot].ActorWorldX <= GameActors[1].ActorWorldX) and
          (GameActors[UpdateBasicActor_ActorSlot].ActorWorldX + 9 >= GameActors[1].ActorWorldX)) or
         ((GameActors[1].ActorWorldX + 9 >= GameActors[UpdateBasicActor_ActorSlot].ActorWorldX) and
          (GameActors[UpdateBasicActor_ActorSlot].ActorWorldX >= GameActors[1].ActorWorldX)) then
      begin
        if (GameActors[1].ActorWorldY + 16 >= GameActors[UpdateBasicActor_ActorSlot].ActorWorldY) and
           (GameActors[UpdateBasicActor_ActorSlot].ActorWorldY > GameActors[1].ActorWorldY) then
        begin
          if PlayerJumping = 0 then
          begin
            GameActors[1].ActorWorldY := GameActors[UpdateBasicActor_ActorSlot].ActorWorldY - 16;
            PlayerJumping := 0;
            PlayerFalling := 0;
            PlayerOnMovingSupport := 1;
            if GameActors[1].ActorSpriteBase = 13 then
              GameActors[1].ActorSpriteBase := 9
            else if GameActors[1].ActorSpriteBase = 14 then
              GameActors[1].ActorSpriteBase := 10;
            if GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = 1 then
              GameActors[1].ActorWorldX := GameActors[UpdateBasicActor_ActorSlot].ActorMovementStep +
              GameActors[1].ActorWorldX
            else if GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = -1 then
              GameActors[1].ActorWorldX := GameActors[1].ActorWorldX -
              GameActors[UpdateBasicActor_ActorSlot].ActorMovementStep;
            if CameraX < 320 then
            begin
              if CameraX + 170 < GameActors[1].ActorWorldX then
              begin
                Inc(CameraX, GameActors[UpdateBasicActor_ActorSlot].ActorMovementStep);
                if CameraX > 320 then
                  CameraX := 320;
              end;
            end;
            if CameraX > 0 then
            begin
              if CameraX + 150 > GameActors[1].ActorWorldX then
              begin
                Dec(CameraX, GameActors[UpdateBasicActor_ActorSlot].ActorMovementStep);
                if CameraX < 0 then
                  CameraX := 0;
              end;
            end;
          end;
        end;
      end;
      if GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = 1 then
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldX := GameActors[UpdateBasicActor_ActorSlot].ActorWorldX +
        GameActors[UpdateBasicActor_ActorSlot].ActorMovementStep
      else if GameActors[UpdateBasicActor_ActorSlot].ActorDirectionX = -1 then
        GameActors[UpdateBasicActor_ActorSlot].ActorWorldX := GameActors[UpdateBasicActor_ActorSlot].ActorWorldX -
        GameActors[UpdateBasicActor_ActorSlot].ActorMovementStep;
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Iterates live actors, delegates kinds<30, handles larger behavior kinds. }
procedure UpdateActorsAndShots;
var
  UpdateActorsAndShots_ProposedX, UpdateActorsAndSho_VerticalWork, EntitySlot, UnusedScanSeedX, UnusedScanSeedY,
  UpdateActorsAndS_HorizontalWork, VerticalWork2, UpdateActorsAnd_RightCellColumn, UpdateActorsAndSho_UpperCellRow: Integer;
begin
  for EntitySlot := 2 to 25 do
    if GameActors[EntitySlot].ActorSlotInactive = 0 then
      if ActorNearViewport(32, EntitySlot) or (GameActors[EntitySlot].ActorKindCode = 28) or
         (GameActors[EntitySlot].ActorKindCode = 21) or (GameActors[EntitySlot].ActorKindCode = 14) then
      begin
        {2fd4} if GameActors[EntitySlot].ActorDirectionX = 1 then
        begin
          {2fec} UpdateActorsAndShots_ProposedX := (GameActors[EntitySlot].ActorWorldX +
          GameActors[EntitySlot].ActorMovementStep);
        end
        else
        begin
          {2ffd} if GameActors[EntitySlot].ActorDirectionX = -1 then
          begin
            {3015} UpdateActorsAndShots_ProposedX := (GameActors[EntitySlot].ActorWorldX -
            GameActors[EntitySlot].ActorMovementStep);
          end
          else
          begin
            {3025} UpdateActorsAndShots_ProposedX := GameActors[EntitySlot].ActorWorldX;
          end;
        end;
        {3034} if GameActors[EntitySlot].DirectionY = 1 then
        begin
          {304c} UpdateActorsAndSho_VerticalWork := (GameActors[EntitySlot].ActorWorldY +
          GameActors[EntitySlot].ActorMovementStep);
        end
        else
        begin
          {305d} if GameActors[EntitySlot].DirectionY = -1 then
          begin
            {3075} UpdateActorsAndSho_VerticalWork := (GameActors[EntitySlot].ActorWorldY -
            GameActors[EntitySlot].ActorMovementStep);
          end
          else
          begin
            {3085} UpdateActorsAndSho_VerticalWork := GameActors[EntitySlot].ActorWorldY;
          end;
        end;
        {309a} GameActors[EntitySlot].ActorPreviousX := GameActors[EntitySlot].ActorWorldX;
        {30b0} GameActors[EntitySlot].ActorPreviousY := GameActors[EntitySlot].ActorWorldY;
        {30c0} if GameActors[EntitySlot].ActorKindCode < 30 then
        begin
          {30d2} UpdateBasicActor(UpdateActorsAndShots_ProposedX, UpdateActorsAndSho_VerticalWork, EntitySlot,
          UnusedScanSeedX, UnusedScanSeedY);
        end
        else
        begin
          case GameActors[EntitySlot].ActorKindCode of
            5000: begin
              {3107} if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY) then
              begin
                {3110} StartSoundEffect(20);
                {3121} PlayerScore := (PlayerScore + 100);
                {3128} StatusBarCameraX := -1;
                {3135} GameActors[EntitySlot].ActorKindCode := 5001;
                {3142} GameActors[EntitySlot].ActorCounterB := 16;
                {314f} GameActors[EntitySlot].ActorSpriteBase := 167;
                {315c} GameActors[EntitySlot].ActorAnimationCounter := 1;
                {316b} GameActors[EntitySlot].ActorMovementStep := 0;
                {3193} PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[2563], GameActors[EntitySlot].ActorWorldX,
                (GameActors[EntitySlot].ActorWorldY + 16));
                {31bc} PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[2563], GameActors[EntitySlot].ActorWorldX,
                (GameActors[EntitySlot].ActorWorldY + 416));
              end
              else
              begin
                {31dc} if ((((GameActors[1].ActorWorldX + 3) >= (GameActors[EntitySlot].ActorWorldX + 3)) and
                ((GameActors[1].ActorWorldX + 3) <= (GameActors[EntitySlot].ActorWorldX +
                    12))) or (((GameActors[1].ActorWorldX + 12) >= (GameActors[EntitySlot].ActorWorldX + 3)) and
                    ((GameActors[1].ActorWorldX + 12) <=
                    (GameActors[EntitySlot].ActorWorldX + 12)))) and (((GameActors[EntitySlot].ActorWorldY <=
                    GameActors[1].ActorWorldY) and ((GameActors[EntitySlot].ActorWorldY + 15) >=
                    GameActors[1].ActorWorldY)) or (((GameActors[1].ActorWorldY + 15) >= GameActors[EntitySlot].ActorWorldY)
                    and ((GameActors[1].ActorWorldY + 15) <=
                    (GameActors[EntitySlot].ActorWorldY + 15)))) then
                begin
                  {328e} StartSoundEffect(4);
                  {329f} PlayerScore := (PlayerScore + 1000);
                  {32a6} StatusBarCameraX := -1;
                  {32b3} GameActors[EntitySlot].ActorKindCode := 5001;
                  {32c0} GameActors[EntitySlot].ActorCounterB := 16;
                  {32cd} GameActors[EntitySlot].ActorSpriteBase := 170;
                  {32da} GameActors[EntitySlot].ActorAnimationCounter := 1;
                  {32e9} GameActors[EntitySlot].ActorMovementStep := 0;
                  {3311} PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3203], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 16));
                  {333a} PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3203], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 416));
                end;
              end;
            end;
            5001: begin
              {3354} GameActors[EntitySlot].ActorPreviousX := UpdateActorsAndShots_ProposedX;
              {3362} GameActors[EntitySlot].ActorPreviousY := UpdateActorsAndSho_VerticalWork;
              {336d} Dec(GameActors[EntitySlot].ActorWorldY, 2);
              {337e} if GameActors[EntitySlot].ActorWorldY < 16 then
              begin
                {3380} UpdateActorsAndSho_VerticalWork := 16;
                {338c} GameActors[EntitySlot].ActorWorldY := 16;
                {3399} GameActors[EntitySlot].ActorPreviousY := 16;
              end;
              {33a6} Dec(GameActors[EntitySlot].ActorCounterB);
              {33b6} if GameActors[EntitySlot].ActorCounterB <= 0 then
              begin
                {33c2} GameActors[EntitySlot].ActorRemovalPending := 1;
                {33cd} RedrawLevelCell(UpdateActorsAndShots_ProposedX, UpdateActorsAndSho_VerticalWork);
                {33dc} RedrawLevelCell(UpdateActorsAndShots_ProposedX, (UpdateActorsAndSho_VerticalWork - 16));
                {33eb} RedrawLevelCell(UpdateActorsAndShots_ProposedX, (UpdateActorsAndSho_VerticalWork + 16));
                {33f6} DrawCellForeground(UpdateActorsAndShots_ProposedX, UpdateActorsAndSho_VerticalWork);
                {3405} DrawCellForeground(UpdateActorsAndShots_ProposedX, (UpdateActorsAndSho_VerticalWork + 16));
                {3414} DrawCellForeground(UpdateActorsAndShots_ProposedX, (UpdateActorsAndSho_VerticalWork - 16));
                {3423} RedrawLevelCell((UpdateActorsAndShots_ProposedX + 16), UpdateActorsAndSho_VerticalWork);
                {3436} RedrawLevelCell((UpdateActorsAndShots_ProposedX + 16), (UpdateActorsAndSho_VerticalWork + 16));
                {3449} RedrawLevelCell((UpdateActorsAndShots_ProposedX + 16), (UpdateActorsAndSho_VerticalWork - 16));
                {3458} DrawCellForeground((UpdateActorsAndShots_ProposedX + 16), UpdateActorsAndSho_VerticalWork);
                {346b} DrawCellForeground((UpdateActorsAndShots_ProposedX + 16), (UpdateActorsAndSho_VerticalWork + 16));
                {347e} DrawCellForeground((UpdateActorsAndShots_ProposedX + 16), (UpdateActorsAndSho_VerticalWork - 16));
              end
              else
              begin
                {348c} RedrawLevelCell(UpdateActorsAndShots_ProposedX, UpdateActorsAndSho_VerticalWork);
                {349b} RedrawLevelCell(UpdateActorsAndShots_ProposedX, (UpdateActorsAndSho_VerticalWork + 16));
                {34a6} DrawCellForeground(UpdateActorsAndShots_ProposedX, UpdateActorsAndSho_VerticalWork);
                {34b5} DrawCellForeground(UpdateActorsAndShots_ProposedX, (UpdateActorsAndSho_VerticalWork + 16));
                {34c4} RedrawLevelCell((UpdateActorsAndShots_ProposedX + 16), UpdateActorsAndSho_VerticalWork);
                {34d7} RedrawLevelCell((UpdateActorsAndShots_ProposedX + 16), (UpdateActorsAndSho_VerticalWork + 16));
                {34e6} DrawCellForeground((UpdateActorsAndShots_ProposedX + 16), UpdateActorsAndSho_VerticalWork);
                {34f9} DrawCellForeground((UpdateActorsAndShots_ProposedX + 16), (UpdateActorsAndSho_VerticalWork + 16));
                {3508} RedrawLevelCell((UpdateActorsAndShots_ProposedX - 16), UpdateActorsAndSho_VerticalWork);
                {351b} RedrawLevelCell((UpdateActorsAndShots_ProposedX - 16), (UpdateActorsAndSho_VerticalWork + 16));
                {352a} DrawCellForeground((UpdateActorsAndShots_ProposedX - 16), UpdateActorsAndSho_VerticalWork);
                {353d} DrawCellForeground((UpdateActorsAndShots_ProposedX - 16), (UpdateActorsAndSho_VerticalWork + 16));
              end;
            end;
            42: begin
              {3556} UpdateActorsAndS_HorizontalWork := ((UpdateActorsAndShots_ProposedX shr 4) + 1);
              {3562} UpdateActorsAndSho_UpperCellRow := ((UpdateActorsAndSho_VerticalWork shr 4) + 1);
              {3569} VerticalWork2 := (UpdateActorsAndSho_UpperCellRow + 1);
              {357a} UpdateActorsAnd_RightCellColumn := (((UpdateActorsAndShots_ProposedX + 15) shr 4) + 2);
              {3597} if LevelCells[UpdateActorsAndS_HorizontalWork, UpdateActorsAndSho_UpperCellRow].CellSolidFlag <> 0 then
              begin
                {35a0} GameActors[EntitySlot].ActorDirectionX := 1;
                {35ad} GameActors[EntitySlot].ActorAnimationCounter := 1;
              end
              else
              begin
                {35d0} if LevelCells[UpdateActorsAnd_RightCellColumn, UpdateActorsAndSho_UpperCellRow].CellSolidFlag <> 0 then
                begin
                  {35d9} GameActors[EntitySlot].ActorDirectionX := -1;
                  {35e6} GameActors[EntitySlot].ActorAnimationCounter := 41;
                end
                else
                begin
                  {3609} if (LevelCells[UpdateActorsAndS_HorizontalWork, VerticalWork2].CellSolidFlag = 0) and
                  (LevelCells[UpdateActorsAndS_HorizontalWork, VerticalWork2].SupportsLanding = 0) then
                  begin
                    {362e} GameActors[EntitySlot].ActorDirectionX := 1;
                    {363b} GameActors[EntitySlot].ActorAnimationCounter := 1;
                  end
                  else
                  begin
                    {365d} if (LevelCells[UpdateActorsAnd_RightCellColumn, VerticalWork2].CellSolidFlag = 0) and
                    (LevelCells[UpdateActorsAnd_RightCellColumn, VerticalWork2].SupportsLanding = 0) then
                    begin
                      {3682} GameActors[EntitySlot].ActorDirectionX := -1;
                      {368f} GameActors[EntitySlot].ActorAnimationCounter := 41;
                    end;
                  end;
                end;
              end;
              {369c} Inc(GameActors[EntitySlot].ActorAnimationCounter);
              {36ac} if GameActors[EntitySlot].ActorDirectionX = 1 then
              begin
                {36ba} if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                begin
                  {36c3} GameActors[EntitySlot].ActorAnimationCounter := 1;
                end;
              end
              else
              begin
                {36d7} if GameActors[EntitySlot].ActorAnimationCounter > 59 then
                begin
                  {36e0} GameActors[EntitySlot].ActorAnimationCounter := 41;
                end;
              end;
              {36f0} GameActors[EntitySlot].ActorWorldX := UpdateActorsAndShots_ProposedX;
              {370b} DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
              {3729} DamagePlayerOnContact((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
              {3748} if (ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY)) or
              (ConsumeShotsAtActor((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY)) then
              begin
                {3773} StartSoundEffect(8);
                {377f} GameActors[EntitySlot].FlashFrames := 3;
                {378c} Dec(GameActors[EntitySlot].ActorKindValue1);
                {379c} if GameActors[EntitySlot].ActorKindValue1 = 0 then
                begin
                  {37a5} StartSoundEffect(19);
                  {37b1} GameActors[EntitySlot].ActorRemovalPending := 1;
                  {37cc} RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                  {37eb} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), GameActors[EntitySlot].ActorWorldY);
                  {380a} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                  {3829} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 32), GameActors[EntitySlot].ActorWorldY);
                  {385b} SpawnScorePopup((LongInt(GameActors[EntitySlot].ActorWorldX) and 65520),
                  (LongInt(GameActors[EntitySlot].ActorWorldY) and 65520), 19);
                  {386a} PlayerScore := (PlayerScore + 500);
                  {3871} StatusBarCameraX := -1;
                end;
                {3886} if GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX then
                begin
                  {388f} GameActors[EntitySlot].ActorDirectionX := 1;
                end
                else
                begin
                  {389e} GameActors[EntitySlot].ActorDirectionX := -1;
                end;
                {38b0} if GameActors[EntitySlot].ActorDirectionX = 1 then
                begin
                  {38b9} GameActors[EntitySlot].ActorAnimationCounter := 1;
                end
                else
                begin
                  {38c8} GameActors[EntitySlot].ActorAnimationCounter := 41;
                end;
              end;
            end;
            30: begin
              {38e1} UpdateActorsAndS_HorizontalWork := (UpdateActorsAndShots_ProposedX shr 4);
              {38ec} VerticalWork2 := (UpdateActorsAndSho_VerticalWork shr 4);
              {38fb} UpdateActorsAnd_RightCellColumn := (((UpdateActorsAndShots_ProposedX + 15) shr 4) + 1);
              {3919} if (LevelCells[(UpdateActorsAndS_HorizontalWork + 1), VerticalWork2].CellSolidFlag <> 0) or
              ((LevelCells[UpdateActorsAnd_RightCellColumn, VerticalWork2].CellSolidFlag <> 0) or
              ((LevelCells[(UpdateActorsAndS_HorizontalWork + 1), (VerticalWork2
                    + 1)].CellSolidFlag <> 0) or (LevelCells[UpdateActorsAnd_RightCellColumn, (VerticalWork2 +
                    1)].CellSolidFlag <> 0))) then
              begin
                {3986} GameActors[EntitySlot].ActorDirectionX := (-GameActors[EntitySlot].ActorDirectionX);
                {3996} if GameActors[EntitySlot].ActorDirectionX = -1 then
                begin
                  {399f} GameActors[EntitySlot].ActorAnimationCounter := 41;
                end
                else
                begin
                  {39ae} GameActors[EntitySlot].ActorAnimationCounter := 1;
                end;
              end
              else
              begin
                {39d5} if (LevelCells[(UpdateActorsAndS_HorizontalWork + 1), (VerticalWork2 + 2)].CellSolidFlag = 0) and
                (LevelCells[(UpdateActorsAndS_HorizontalWork + 1), (VerticalWork2 + 2)].SupportsLanding = 0) then
                begin
                  {39fe} GameActors[EntitySlot].ActorDirectionX := 1;
                  {3a0b} GameActors[EntitySlot].ActorAnimationCounter := 1;
                end
                else
                begin
                  {3a30} if (LevelCells[UpdateActorsAnd_RightCellColumn, (VerticalWork2 + 2)].CellSolidFlag = 0) and
                  (LevelCells[UpdateActorsAnd_RightCellColumn, (VerticalWork2 + 2)].SupportsLanding = 0) then
                  begin
                    {3a58} GameActors[EntitySlot].ActorDirectionX := -1;
                    {3a65} GameActors[EntitySlot].ActorAnimationCounter := 41;
                  end;
                end;
              end;
              {3a72} Inc(GameActors[EntitySlot].ActorAnimationCounter);
              {3a82} if GameActors[EntitySlot].ActorDirectionX = 1 then
              begin
                {3a90} if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                begin
                  {3a99} GameActors[EntitySlot].ActorAnimationCounter := 1;
                end;
              end
              else
              begin
                {3aad} if GameActors[EntitySlot].ActorAnimationCounter > 59 then
                begin
                  {3ab6} GameActors[EntitySlot].ActorAnimationCounter := 41;
                end;
              end;
              {3ac8} if GameActors[EntitySlot].ActorCounterB > 0 then
              begin
                {3ad1} Dec(GameActors[EntitySlot].ActorCounterB);
              end;
              {3ae1} if (GameActors[EntitySlot].ActorCounterB = 0) and (((GameActors[EntitySlot].ActorWorldY shr 4) =
              ((GameActors[1].ActorWorldY + 8) shr 4)) and
                    (((GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX) and
                    (GameActors[EntitySlot].ActorDirectionX = 1)) or ((GameActors[EntitySlot].ActorWorldX >
                    GameActors[1].ActorWorldX) and
                    (GameActors[EntitySlot].ActorDirectionX = -1)))) then
              begin
                {3b4c} GameActors[EntitySlot].ActorCounterB := 70;
                {3b7c} SpawnEnemyProjectile(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY,
                GameActors[EntitySlot].ActorDirectionX, 4, 825);
              end;
              {3b89} GameActors[EntitySlot].ActorWorldX := UpdateActorsAndShots_ProposedX;
              {3ba9} if (ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY)) or
              (ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16))) then
              begin
                {3bdf} if GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX then
                begin
                  {3c0d} if (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), (VerticalWork2 +
                  1)].CellSolidFlag = 0) and
                    (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), VerticalWork2].CellSolidFlag = 0)
                    then
                  begin
                    {3c43} GameActors[EntitySlot].ActorDirectionX := 1;
                    {3c50} GameActors[EntitySlot].ActorAnimationCounter := 1;
                  end;
                end
                else
                begin
                  {3c81} if (LevelCells[((GameActors[EntitySlot].ActorWorldX shr 4) + 1), (VerticalWork2 + 1)].CellSolidFlag =
                  0) and (LevelCells[((GameActors[EntitySlot].ActorWorldX
                    shr 4) + 1), VerticalWork2].CellSolidFlag = 0) then
                  begin
                    {3cb4} GameActors[EntitySlot].ActorDirectionX := -1;
                    {3cc1} GameActors[EntitySlot].ActorAnimationCounter := 41;
                  end;
                end;
                {3cce} GameActors[EntitySlot].FlashFrames := 3;
                {3cdb} Dec(GameActors[EntitySlot].ActorKindValue1);
                {3ceb} if GameActors[EntitySlot].ActorKindValue1 = 0 then
                begin
                  {3cf4} StartSoundEffect(19);
                  {3d05} PlayerScore := (PlayerScore + 1000);
                  {3d0c} StatusBarCameraX := -1;
                  {3d19} GameActors[EntitySlot].ActorRemovalPending := 1;
                  {3d34} RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                  {3d53} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), GameActors[EntitySlot].ActorWorldY);
                  {3d72} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                  {3d95} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), (GameActors[EntitySlot].ActorWorldY -
                  16));
                  {3db8} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), (GameActors[EntitySlot].ActorWorldY -
                  16));
                  {3dd7} RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16));
                  {3e09} SpawnScorePopup((LongInt(GameActors[EntitySlot].ActorWorldX) and 65520),
                  (LongInt(GameActors[EntitySlot].ActorWorldY) and 65520), 20);
                end
                else
                begin
                  {3e12} StartSoundEffect(8);
                end;
              end
              else
              begin
                {3e30} DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                {3e4e} DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16));
              end;
            end;
            31: begin
              {3e64} UpdateActorsAndS_HorizontalWork := (UpdateActorsAndShots_ProposedX shr 4);
              {3e6f} VerticalWork2 := (UpdateActorsAndSho_VerticalWork shr 4);
              {3e7e} UpdateActorsAnd_RightCellColumn := (((UpdateActorsAndShots_ProposedX + 15) shr 4) + 1);
              {3e9c} if (LevelCells[(UpdateActorsAndS_HorizontalWork + 1), VerticalWork2].CellSolidFlag <> 0) or
              ((LevelCells[UpdateActorsAnd_RightCellColumn, VerticalWork2].CellSolidFlag <> 0) or
              ((LevelCells[(UpdateActorsAndS_HorizontalWork + 1), (VerticalWork2
                    + 1)].CellSolidFlag <> 0) or (LevelCells[UpdateActorsAnd_RightCellColumn, (VerticalWork2 +
                    1)].CellSolidFlag <> 0))) then
              begin
                {3f09} GameActors[EntitySlot].ActorDirectionX := (-GameActors[EntitySlot].ActorDirectionX);
                {3f19} if GameActors[EntitySlot].ActorDirectionX = -1 then
                begin
                  {3f22} GameActors[EntitySlot].ActorAnimationCounter := 1;
                end
                else
                begin
                  {3f31} GameActors[EntitySlot].ActorAnimationCounter := 61;
                end;
              end
              else
              begin
                {3f58} if (LevelCells[(UpdateActorsAndS_HorizontalWork + 1), (VerticalWork2 + 2)].CellSolidFlag = 0) and
                (LevelCells[(UpdateActorsAndS_HorizontalWork + 1), (VerticalWork2 + 2)].SupportsLanding = 0) then
                begin
                  {3f81} GameActors[EntitySlot].ActorDirectionX := 1;
                  {3f8e} GameActors[EntitySlot].ActorAnimationCounter := 61;
                end
                else
                begin
                  {3fb3} if (LevelCells[UpdateActorsAnd_RightCellColumn, (VerticalWork2 + 2)].CellSolidFlag = 0) and
                  (LevelCells[UpdateActorsAnd_RightCellColumn, (VerticalWork2 + 2)].SupportsLanding = 0) then
                  begin
                    {3fdb} GameActors[EntitySlot].ActorDirectionX := -1;
                    {3fe8} GameActors[EntitySlot].ActorAnimationCounter := 1;
                  end;
                end;
              end;
              {3ff5} Inc(GameActors[EntitySlot].ActorCounterB);
              {400f} if GameActors[EntitySlot].ActorCounterB >= GameActors[EntitySlot].ActorCounterA then
              begin
                {401d} GameActors[EntitySlot].ActorCounterB := 0;
                {4040} if ((GameActors[EntitySlot].ActorWorldY shr 4) = ((GameActors[1].ActorWorldY + 8) shr 4)) and
                (((GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX)
                    and (GameActors[EntitySlot].ActorDirectionX = 1)) or ((GameActors[EntitySlot].ActorWorldX >
                    GameActors[1].ActorWorldX) and (GameActors[EntitySlot].ActorDirectionX = -1))) then
                begin
                  {40aa} SpawnEnemyProjectile(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY,
                  GameActors[EntitySlot].ActorDirectionX, 4, 827);
                end;
              end;
              {40b9} if GameActors[EntitySlot].StateValueB > 0 then
              begin
                {40c2} Dec(GameActors[EntitySlot].StateValueB);
              end;
              {40d2} if GameActors[EntitySlot].StateValueB = 1 then
              begin
                {40db} GameActors[EntitySlot].ActorKindValue1 := 30;
              end
              else
              begin
                {40f0} if GameActors[EntitySlot].StateValueB = 0 then
                begin
                  {40f9} Inc(GameActors[EntitySlot].ActorAnimationCounter);
                  {4109} if GameActors[EntitySlot].ActorDirectionX = -1 then
                  begin
                    {4117} if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                    begin
                      {4120} GameActors[EntitySlot].ActorAnimationCounter := 19;
                    end;
                  end
                  else
                  begin
                    {4134} if GameActors[EntitySlot].ActorAnimationCounter > 79 then
                    begin
                      {413d} GameActors[EntitySlot].ActorAnimationCounter := 79;
                    end;
                  end;
                  {414a} Dec(GameActors[EntitySlot].ActorKindValue1);
                  {415a} if GameActors[EntitySlot].ActorKindValue1 = 0 then
                  begin
                    {4163} GameActors[EntitySlot].StateValueB := 80;
                  end;
                end
                else
                begin
                  {4172} Inc(GameActors[EntitySlot].ActorAnimationCounter);
                  {4182} if GameActors[EntitySlot].ActorDirectionX = -1 then
                  begin
                    {4190} if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                    begin
                      {4199} GameActors[EntitySlot].ActorAnimationCounter := 1;
                    end;
                  end
                  else
                  begin
                    {41ad} if GameActors[EntitySlot].ActorAnimationCounter > 79 then
                    begin
                      {41b6} GameActors[EntitySlot].ActorAnimationCounter := 61;
                    end;
                  end;
                  {41c6} GameActors[EntitySlot].ActorWorldX := UpdateActorsAndShots_ProposedX;
                end;
              end;
              {41e1} DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
              {41ff} DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16));
              {421e} if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY) then
              begin
                {4227} StartSoundEffect(8);
                {423b} if GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX then
                begin
                  {4269} if (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), (VerticalWork2 +
                  1)].CellSolidFlag = 0) and
                    (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), VerticalWork2].CellSolidFlag = 0)
                    then
                  begin
                    {429f} GameActors[EntitySlot].ActorDirectionX := 1;
                    {42ac} GameActors[EntitySlot].ActorAnimationCounter := 61;
                  end;
                end
                else
                begin
                  {42dd} if (LevelCells[((GameActors[EntitySlot].ActorWorldX shr 4) + 1), (VerticalWork2 + 1)].CellSolidFlag =
                  0) and (LevelCells[((GameActors[EntitySlot].ActorWorldX
                    shr 4) + 1), VerticalWork2].CellSolidFlag = 0) then
                  begin
                    {4310} GameActors[EntitySlot].ActorDirectionX := -1;
                    {431d} GameActors[EntitySlot].ActorAnimationCounter := 1;
                  end;
                end;
              end
              else
              begin
                {4346} if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16))
                then
                begin
                  {435a} if GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX then
                  begin
                    {4388} if (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), (VerticalWork2 +
                    1)].CellSolidFlag = 0) and
                    (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), VerticalWork2].CellSolidFlag = 0)
                    then
                    begin
                      {43be} GameActors[EntitySlot].ActorDirectionX := 1;
                      {43cb} GameActors[EntitySlot].ActorAnimationCounter := 61;
                    end;
                  end
                  else
                  begin
                    {43fc} if (LevelCells[((GameActors[EntitySlot].ActorWorldX shr 4) + 1), (VerticalWork2 + 1)].CellSolidFlag
                    = 0) and (LevelCells[((GameActors[EntitySlot].ActorWorldX
                    shr 4) + 1), VerticalWork2].CellSolidFlag = 0) then
                    begin
                      {442f} GameActors[EntitySlot].ActorDirectionX := -1;
                      {443c} GameActors[EntitySlot].ActorAnimationCounter := 1;
                    end;
                  end;
                  {444e} if GameActors[EntitySlot].StateValueB = 0 then
                  begin
                    {4457} StartSoundEffect(19);
                    {4468} PlayerScore := (PlayerScore + 1000);
                    {446f} StatusBarCameraX := -1;
                    {447c} GameActors[EntitySlot].ActorRemovalPending := 1;
                    {4497} RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                    {44b6} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), GameActors[EntitySlot].ActorWorldY);
                    {44d5} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                    {44f8} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), (GameActors[EntitySlot].ActorWorldY -
                    16));
                    {451b} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), (GameActors[EntitySlot].ActorWorldY -
                    16));
                    {453a} RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16));
                    {456c} SpawnScorePopup((LongInt(GameActors[EntitySlot].ActorWorldX) and 65520),
                    (LongInt(GameActors[EntitySlot].ActorWorldY) and 65520), 20);
                  end
                  else
                  begin
                    {4575} StartSoundEffect(8);
                  end;
                end;
              end;
            end;
            32: begin
              {458c} Inc(GameActors[EntitySlot].ActorAnimationCounter);
              {459c} if GameActors[EntitySlot].ActorAnimationCounter > 19 then
              begin
                {45a5} GameActors[EntitySlot].ActorAnimationCounter := 1;
              end;
              {45c7} if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY) then
              begin
                {45d3} Dec(GameActors[EntitySlot].ActorCounterA);
                {45de} GameActors[EntitySlot].FlashFrames := 3;
                {45f0} if GameActors[EntitySlot].ActorCounterA <= 0 then
                begin
                  for UpdateActorsAndS_HorizontalWork := 0 to 15 do
                    PgSetPaletteRegister(UpdateActorsAndS_HorizontalWork, 12);
                  {4611} SoundPlaying := 0;
                  {461a} StartSoundEffect(10);
                  {461f} LevelRadarDestroyed := 1;
                  {4630} PlayerScore := (PlayerScore + 5000);
                  {4637} StatusBarCameraX := -1;
                  {4644} GameActors[EntitySlot].ActorKindCode := 5001;
                  {4651} GameActors[EntitySlot].ActorCounterB := 16;
                  {465e} GameActors[EntitySlot].ActorSpriteBase := 172;
                  {466b} GameActors[EntitySlot].ActorAnimationCounter := 1;
                  {4695} PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3363], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 16));
                  {46be} PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3363], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 416));
                  {46c6} RestoreGamePalette(0);
                end
                else
                begin
                  {46d1} StartSoundEffect(8);
                end;
              end;
            end;
            33: begin
              {4707} if (LevelCells[((UpdateActorsAndShots_ProposedX shr 4) + 1), ((UpdateActorsAndSho_VerticalWork shr 4) +
              1)].CellSolidFlag <> 0) or ((LevelCells[(((UpdateActorsAndShots_ProposedX + 15) shr 4) +
                    1), ((UpdateActorsAndSho_VerticalWork shr 4) + 1)].CellSolidFlag <> 0) or
                    ((LevelCells[(((UpdateActorsAndShots_ProposedX + 8) shr 4) + 1), (UpdateActorsAndSho_VerticalWork shr
                    4)].SupportsLanding =
                    0) and (LevelCells[(((UpdateActorsAndShots_ProposedX + 8) shr 4) + 1), (UpdateActorsAndSho_VerticalWork
                    shr 4)].CellSolidFlag = 0))) then
              begin
                {479f} GameActors[EntitySlot].ActorDirectionX := (-GameActors[EntitySlot].ActorDirectionX);
                {47af} if GameActors[EntitySlot].ActorDirectionX = -1 then
                begin
                  {47b8} GameActors[EntitySlot].ActorAnimationCounter := 1;
                end
                else
                begin
                  {47c7} GameActors[EntitySlot].ActorAnimationCounter := 21;
                end;
              end;
              {47d4} Inc(GameActors[EntitySlot].ActorAnimationCounter);
              {47e4} if GameActors[EntitySlot].ActorDirectionX = -1 then
              begin
                {47f2} if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                begin
                  {47fb} GameActors[EntitySlot].ActorAnimationCounter := 1;
                end;
              end
              else
              begin
                {480f} if GameActors[EntitySlot].ActorAnimationCounter > 39 then
                begin
                  {4818} GameActors[EntitySlot].ActorAnimationCounter := 21;
                end;
              end;
              {4825} Inc(GameActors[EntitySlot].ActorCounterB);
              {483f} if GameActors[EntitySlot].ActorCounterB = GameActors[EntitySlot].ActorCounterA then
              begin
                {4853} if ((GameActors[EntitySlot].ActorWorldX - 16) < GameActors[1].ActorWorldX) and
                (((GameActors[EntitySlot].ActorWorldX + 16) > GameActors[1].ActorWorldX) and
                    (GameActors[EntitySlot].ActorWorldY < GameActors[1].ActorWorldY)) then
                begin
                  {4883} GameActors[EntitySlot].ActorCounterB := 0;
                  {48a6} SpawnEnemyProjectile(UpdateActorsAndShots_ProposedX, (GameActors[EntitySlot].ActorWorldY + 8), 1, 8,
                  199);
                end
                else
                begin
                  {48b2} Dec(GameActors[EntitySlot].ActorCounterB);
                end;
              end;
              {48c0} GameActors[EntitySlot].ActorWorldX := UpdateActorsAndShots_ProposedX;
              {48db} DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
              {48fa} if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY) then
              begin
                {4906} GameActors[EntitySlot].FlashFrames := 3;
                {4913} Dec(GameActors[EntitySlot].ActorKindValue1);
                {4923} if GameActors[EntitySlot].ActorKindValue1 <= 0 then
                begin
                  {492c} StartSoundEffect(19);
                  {493d} PlayerScore := (PlayerScore + 500);
                  {4944} StatusBarCameraX := -1;
                  {4960} RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                  {497f} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), GameActors[EntitySlot].ActorWorldY);
                  {499e} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                  {49aa} GameActors[EntitySlot].ActorKindCode := 5001;
                  {49b7} GameActors[EntitySlot].ActorCounterB := 16;
                  {49c4} GameActors[EntitySlot].ActorSpriteBase := 169;
                  {49d1} GameActors[EntitySlot].ActorAnimationCounter := 1;
                  {49f4} GameActors[EntitySlot].ActorWorldX := (LongInt((GameActors[EntitySlot].ActorWorldX + 8)) and 65520);
                  {4a1c} PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[2883], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 16));
                  {4a45} PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[2883], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 416));
                end
                else
                begin
                  {4a50} StartSoundEffect(8);
                end;
              end;
            end;
            34: begin
              {4a69} UpdateActorsAndS_HorizontalWork := ((UpdateActorsAndShots_ProposedX shr 4) + 1);
              {4a75} UpdateActorsAndSho_UpperCellRow := ((UpdateActorsAndSho_VerticalWork shr 4) + 1);
              {4a7c} VerticalWork2 := (UpdateActorsAndSho_UpperCellRow + 1);
              {4a8b} UpdateActorsAnd_RightCellColumn := (((UpdateActorsAndShots_ProposedX + 15) shr 4) + 1);
              {4aa8} if LevelCells[UpdateActorsAndS_HorizontalWork, UpdateActorsAndSho_UpperCellRow].CellSolidFlag <> 0 then
              begin
                {4ab1} GameActors[EntitySlot].ActorDirectionX := 1;
                {4abe} GameActors[EntitySlot].ActorAnimationCounter := 1;
              end
              else
              begin
                {4ae1} if LevelCells[UpdateActorsAnd_RightCellColumn, UpdateActorsAndSho_UpperCellRow].CellSolidFlag <> 0 then
                begin
                  {4aea} GameActors[EntitySlot].ActorDirectionX := -1;
                  {4af7} GameActors[EntitySlot].ActorAnimationCounter := 21;
                end
                else
                begin
                  {4b1a} if (LevelCells[UpdateActorsAndS_HorizontalWork, VerticalWork2].CellSolidFlag = 0) and
                  (LevelCells[UpdateActorsAndS_HorizontalWork, VerticalWork2].SupportsLanding = 0) then
                  begin
                    {4b3f} GameActors[EntitySlot].ActorDirectionX := 1;
                    {4b4c} GameActors[EntitySlot].ActorAnimationCounter := 1;
                  end
                  else
                  begin
                    {4b6e} if (LevelCells[UpdateActorsAnd_RightCellColumn, VerticalWork2].CellSolidFlag = 0) and
                    (LevelCells[UpdateActorsAnd_RightCellColumn, VerticalWork2].SupportsLanding = 0) then
                    begin
                      {4b93} GameActors[EntitySlot].ActorDirectionX := -1;
                      {4ba0} GameActors[EntitySlot].ActorAnimationCounter := 21;
                    end;
                  end;
                end;
              end;
              {4bad} Inc(GameActors[EntitySlot].ActorAnimationCounter);
              {4bbd} if GameActors[EntitySlot].ActorDirectionX = 1 then
              begin
                {4bcb} if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                begin
                  {4bd4} GameActors[EntitySlot].ActorAnimationCounter := 1;
                end;
              end
              else
              begin
                {4be8} if GameActors[EntitySlot].ActorAnimationCounter > 39 then
                begin
                  {4bf1} GameActors[EntitySlot].ActorAnimationCounter := 21;
                end;
              end;
              {4c01} GameActors[EntitySlot].ActorWorldX := UpdateActorsAndShots_ProposedX;
              {4c1c} DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
              {4c3b} if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY) then
              begin
                {4c47} GameActors[EntitySlot].FlashFrames := 3;
                {4c54} Dec(GameActors[EntitySlot].ActorKindValue1);
                {4c64} if GameActors[EntitySlot].ActorKindValue1 <= 0 then
                begin
                  {4c6d} StartSoundEffect(19);
                  {4c7e} PlayerScore := (PlayerScore + 1000);
                  {4c85} StatusBarCameraX := -1;
                  {4ca1} RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                  {4cc0} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), GameActors[EntitySlot].ActorWorldY);
                  {4cdf} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                  {4ceb} GameActors[EntitySlot].ActorKindCode := 5001;
                  {4cf8} GameActors[EntitySlot].ActorCounterB := 16;
                  {4d05} GameActors[EntitySlot].ActorSpriteBase := 170;
                  {4d12} GameActors[EntitySlot].ActorAnimationCounter := 1;
                  {4d35} GameActors[EntitySlot].ActorWorldX := (LongInt((GameActors[EntitySlot].ActorWorldX + 8)) and 65520);
                  {4d5d} PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3043], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 16));
                  {4d86} PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3043], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 416));
                  {4dae} SpawnEnemyProjectile(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY, -1, 4,
                  125);
                  {4dd4} SpawnEnemyProjectile(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY, 1, 4,
                  126);
                end
                else
                begin
                  {4ddd} StartSoundEffect(8);
                end;
              end;
            end;
            35: begin
              {4df4} Inc(GameActors[EntitySlot].ActorAnimationCounter);
              {4e04} if GameActors[EntitySlot].ActorAnimationCounter > 19 then
              begin
                {4e0d} GameActors[EntitySlot].ActorAnimationCounter := 1;
              end;
              {4e1d} GameActors[EntitySlot].ActorWorldX := UpdateActorsAndShots_ProposedX;
              {4e38} DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
              {4e57} if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY) then
              begin
                {4e63} GameActors[EntitySlot].FlashFrames := 3;
                {4e70} Dec(GameActors[EntitySlot].ActorKindValue1);
                {4e80} if GameActors[EntitySlot].ActorKindValue1 <= 0 then
                begin
                  {4e89} StartSoundEffect(19);
                  {4e9a} PlayerScore := (PlayerScore + 1000);
                  {4ea1} StatusBarCameraX := -1;
                  {4eae} GameActors[EntitySlot].ActorKindCode := 5001;
                  {4ebb} GameActors[EntitySlot].ActorCounterB := 16;
                  {4ec8} GameActors[EntitySlot].ActorSpriteBase := 170;
                  {4ed5} GameActors[EntitySlot].ActorAnimationCounter := 1;
                  {4ef8} GameActors[EntitySlot].ActorWorldX := (LongInt((GameActors[EntitySlot].ActorWorldX + 8)) and 65520);
                  {4f20} PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3043], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 16));
                  {4f49} PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3043], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 416));
                  {4f4e} CeilingLauncherDisabled := 1;
                end
                else
                begin
                  {4f59} StartSoundEffect(8);
                end;
              end;
            end;
            36: begin
              {4f73} GameActors[EntitySlot].ActorWorldX := UpdateActorsAndShots_ProposedX;
              {4f7e} Inc(GameActors[EntitySlot].ActorCounterB);
              {4f98} if GameActors[EntitySlot].ActorCounterB >= GameActors[EntitySlot].ActorKindValue1 then
              begin
                {4faf} GameActors[EntitySlot].ActorCounterB := GameActors[EntitySlot].ActorKindValue1;
                {4fcb} if ((GameActors[1].ActorWorldX + 8) >= (GameActors[EntitySlot].ActorWorldX - 4)) and
                (((GameActors[1].ActorWorldX + 8) <= (GameActors[EntitySlot].ActorWorldX +
                    4)) and ((GameActors[EntitySlot].ActorWorldY >= GameActors[1].ActorWorldY) and (CeilingLauncherDisabled =
                    0))) then
                begin
                  {5026} SpawnEnemyProjectile(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY + 8),
                  -1, 8, 114);
                  {5032} GameActors[EntitySlot].ActorCounterB := 0;
                end;
              end;
            end;
            137: begin
              {5052} VerticalWork2 := ((GameActors[EntitySlot].ActorWorldY shr 4) + 1);
              {507d} if (LevelCells[((GameActors[EntitySlot].ActorWorldX shr 4) + 1), VerticalWork2].CellSolidFlag <> 0) or
              (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr
                    4) + 1), VerticalWork2].CellSolidFlag <> 0) then
              begin
                {50bb} if GameActors[EntitySlot].ActorRemovalPending <> 0 then
                begin
                  {50c4} GameActors[EntitySlot].ActorSlotInactive := 1;
                end;
                {50d0} GameActors[EntitySlot].ActorRemovalPending := 1;
                {50e1} if GameActors[EntitySlot].ActorWorldY < 0 then
                begin
                  {50ec} GameActors[EntitySlot].ActorWorldY := 0;
                end;
                {5106} RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                {5125} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                {5144} RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY + 16));
                {5167} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), (GameActors[EntitySlot].ActorWorldY + 16));
                {5182} DrawCellForeground(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                {51a1} DrawCellForeground((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                {51c0} DrawCellForeground(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY + 16));
                {51e3} DrawCellForeground((GameActors[EntitySlot].ActorWorldX + 16), (GameActors[EntitySlot].ActorWorldY +
                16));
              end
              else
              begin
                {51f1} Inc(GameActors[EntitySlot].ActorAnimationCounter);
                {5201} if GameActors[EntitySlot].ActorAnimationCounter > 9 then
                begin
                  {520a} GameActors[EntitySlot].ActorAnimationCounter := 1;
                end;
                {521a} GameActors[EntitySlot].ActorWorldY := UpdateActorsAndSho_VerticalWork;
                {522a} if GameActors[EntitySlot].ActorWorldY < 0 then
                begin
                  {5235} GameActors[EntitySlot].ActorWorldY := 0;
                end;
                {5250} DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
              end;
            end;
            37: begin
              {526e} VerticalWork2 := (GameActors[EntitySlot].ActorWorldY shr 4);
              {5299} if (LevelCells[((GameActors[EntitySlot].ActorWorldX shr 4) + 1), VerticalWork2].CellSolidFlag <> 0) or
              (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr
                    4) + 1), VerticalWork2].CellSolidFlag <> 0) then
              begin
                {52d7} if GameActors[EntitySlot].ActorRemovalPending <> 0 then
                begin
                  {52e0} GameActors[EntitySlot].ActorSlotInactive := 1;
                end;
                {52ec} GameActors[EntitySlot].ActorRemovalPending := 1;
                {52fd} if GameActors[EntitySlot].ActorWorldY < 0 then
                begin
                  {5308} GameActors[EntitySlot].ActorWorldY := 0;
                end;
                {5322} RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                {5341} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                {5360} RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY + 16));
                {5383} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), (GameActors[EntitySlot].ActorWorldY + 16));
                {539e} DrawCellForeground(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                {53bd} DrawCellForeground((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                {53dc} DrawCellForeground(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY + 16));
                {53ff} DrawCellForeground((GameActors[EntitySlot].ActorWorldX + 16), (GameActors[EntitySlot].ActorWorldY +
                16));
              end
              else
              begin
                {540e} Inc(GameActors[EntitySlot].ActorAnimationCounter);
                {541e} if GameActors[EntitySlot].ActorAnimationCounter > 9 then
                begin
                  {5427} GameActors[EntitySlot].ActorAnimationCounter := 1;
                end;
                {5437} GameActors[EntitySlot].ActorWorldY := UpdateActorsAndSho_VerticalWork;
                {5447} if GameActors[EntitySlot].ActorWorldY < 0 then
                begin
                  {5452} GameActors[EntitySlot].ActorWorldY := 0;
                end;
                {545b} if (PlayerGodMode = 0) and ((((GameActors[EntitySlot].ActorWorldX <= GameActors[1].ActorWorldX) and
                ((GameActors[EntitySlot].ActorWorldX + 9) >=
                    GameActors[1].ActorWorldX)) or (((GameActors[1].ActorWorldX + 9) >= GameActors[EntitySlot].ActorWorldX)
                    and (GameActors[EntitySlot].ActorWorldX >= GameActors[1].ActorWorldX)))
                    and ((((GameActors[EntitySlot].ActorWorldY <= GameActors[1].ActorWorldY) and
                    ((GameActors[EntitySlot].ActorWorldY + 15) >= GameActors[1].ActorWorldY)) or
                    (((GameActors[1].ActorWorldY + 15) >= GameActors[EntitySlot].ActorWorldY) and
                    (GameActors[EntitySlot].ActorWorldY >= GameActors[1].ActorWorldY))) and (PlayerDying = 0)))
                    then
                begin
                  {54f9} PlayerDying := 1;
                  {54fe} DeathAnimationTick := 35;
                  {5507} StartSoundEffect(22);
                end;
              end;
            end;
            38: begin
              {553d} if (LevelCells[((UpdateActorsAndShots_ProposedX shr 4) + 1), ((UpdateActorsAndSho_VerticalWork shr 4) +
              1)].CellSolidFlag <> 0) or (LevelCells[(((UpdateActorsAndShots_ProposedX + 15) shr 4) +
                    1), ((UpdateActorsAndSho_VerticalWork shr 4) + 1)].CellSolidFlag <> 0) then
              begin
                {557e} GameActors[EntitySlot].ActorDirectionX := (-GameActors[EntitySlot].ActorDirectionX);
              end;
              {5589} Inc(GameActors[EntitySlot].ActorAnimationCounter);
              {5599} if GameActors[EntitySlot].ActorAnimationCounter > 19 then
              begin
                {55a2} GameActors[EntitySlot].ActorAnimationCounter := 1;
              end;
              {55b4} if GameActors[EntitySlot].StateValueB > 0 then
              begin
                {55bd} Dec(GameActors[EntitySlot].StateValueB);
              end;
              {55cd} if GameActors[EntitySlot].StateValueB = 0 then
              begin
                {55db} if GameActors[EntitySlot].ActorCounterB = 0 then
                begin
                  {5603} SpawnEnemyProjectile(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY + 16),
                  1, 0, 137);
                end;
                {560d} Inc(GameActors[EntitySlot].ActorCounterB);
                {5627} if GameActors[EntitySlot].ActorCounterB = GameActors[EntitySlot].ActorCounterA then
                begin
                  {5632} GameActors[EntitySlot].ActorCounterB := 0;
                  {563d} GameActors[EntitySlot].StateValueB := 110;
                end;
              end
              else
              begin
                {564f} GameActors[EntitySlot].ActorWorldX := UpdateActorsAndShots_ProposedX;
              end;
              {566a} DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
              {5689} if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY) then
              begin
                {568f} StartSoundEffect(8);
              end;
            end;
            39: begin
              {56a7} UpdateActorsAndS_HorizontalWork := (UpdateActorsAndShots_ProposedX shr 4);
              {56b2} VerticalWork2 := (UpdateActorsAndSho_VerticalWork shr 4);
              {56c1} UpdateActorsAnd_RightCellColumn := (((UpdateActorsAndShots_ProposedX + 15) shr 4) + 1);
              {56df} if (LevelCells[(UpdateActorsAndS_HorizontalWork + 1), VerticalWork2].CellSolidFlag <> 0) or
              ((LevelCells[UpdateActorsAnd_RightCellColumn, VerticalWork2].CellSolidFlag <> 0) or
              ((LevelCells[(UpdateActorsAndS_HorizontalWork + 1), (VerticalWork2
                    + 1)].CellSolidFlag <> 0) or (LevelCells[UpdateActorsAnd_RightCellColumn, (VerticalWork2 +
                    1)].CellSolidFlag <> 0))) then
              begin
                {574c} GameActors[EntitySlot].ActorDirectionX := (-GameActors[EntitySlot].ActorDirectionX);
                {575c} if GameActors[EntitySlot].ActorDirectionX = -1 then
                begin
                  {5765} GameActors[EntitySlot].ActorAnimationCounter := 1;
                end
                else
                begin
                  {5774} GameActors[EntitySlot].ActorAnimationCounter := 201;
                end;
              end
              else
              begin
                {579b} if (LevelCells[(UpdateActorsAndS_HorizontalWork + 1), (VerticalWork2 + 2)].CellSolidFlag = 0) and
                (LevelCells[(UpdateActorsAndS_HorizontalWork + 1), (VerticalWork2 + 2)].SupportsLanding = 0) then
                begin
                  {57c4} GameActors[EntitySlot].ActorDirectionX := 1;
                  {57d1} GameActors[EntitySlot].ActorAnimationCounter := 201;
                end
                else
                begin
                  {57f6} if (LevelCells[UpdateActorsAnd_RightCellColumn, (VerticalWork2 + 2)].CellSolidFlag = 0) and
                  (LevelCells[UpdateActorsAnd_RightCellColumn, (VerticalWork2 + 2)].SupportsLanding = 0) then
                  begin
                    {581e} GameActors[EntitySlot].ActorDirectionX := -1;
                    {582b} GameActors[EntitySlot].ActorAnimationCounter := 1;
                  end;
                end;
              end;
              {5838} Inc(GameActors[EntitySlot].ActorCounterB);
              {5852} if GameActors[EntitySlot].ActorCounterB >= GameActors[EntitySlot].ActorCounterA then
              begin
                {5860} GameActors[EntitySlot].ActorCounterB := 0;
                {5883} if ((GameActors[EntitySlot].ActorWorldY shr 4) = ((GameActors[1].ActorWorldY + 8) shr 4)) and
                (((GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX)
                    and (GameActors[EntitySlot].ActorDirectionX = 1)) or ((GameActors[EntitySlot].ActorWorldX >
                    GameActors[1].ActorWorldX) and (GameActors[EntitySlot].ActorDirectionX = -1))) then
                begin
                  {58ed} SpawnEnemyProjectile(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY,
                  GameActors[EntitySlot].ActorDirectionX, 4, 827);
                end;
              end;
              {58fc} if GameActors[EntitySlot].StateValueB > 0 then
              begin
                {5905} Dec(GameActors[EntitySlot].StateValueB);
              end;
              {5915} if GameActors[EntitySlot].StateValueB = 1 then
              begin
                {591e} GameActors[EntitySlot].ActorKindValue1 := 30;
              end
              else
              begin
                {5933} if GameActors[EntitySlot].StateValueB = 0 then
                begin
                  {593c} Inc(GameActors[EntitySlot].ActorAnimationCounter);
                  {594c} if GameActors[EntitySlot].ActorDirectionX = -1 then
                  begin
                    {595a} if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                    begin
                      {5963} GameActors[EntitySlot].ActorAnimationCounter := 19;
                    end;
                  end
                  else
                  begin
                    {5978} if GameActors[EntitySlot].ActorAnimationCounter > 219 then
                    begin
                      {5981} GameActors[EntitySlot].ActorAnimationCounter := 219;
                    end;
                  end;
                  {598e} Dec(GameActors[EntitySlot].ActorKindValue1);
                  {599e} if GameActors[EntitySlot].ActorKindValue1 = 0 then
                  begin
                    {59a7} GameActors[EntitySlot].StateValueB := 80;
                  end;
                end
                else
                begin
                  {59b6} Inc(GameActors[EntitySlot].ActorAnimationCounter);
                  {59c6} if GameActors[EntitySlot].ActorDirectionX = -1 then
                  begin
                    {59d4} if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                    begin
                      {59dd} GameActors[EntitySlot].ActorAnimationCounter := 1;
                    end;
                  end
                  else
                  begin
                    {59f2} if GameActors[EntitySlot].ActorAnimationCounter > 219 then
                    begin
                      {59fb} GameActors[EntitySlot].ActorAnimationCounter := 201;
                    end;
                  end;
                  {5a0b} GameActors[EntitySlot].ActorWorldX := UpdateActorsAndShots_ProposedX;
                end;
              end;
              {5a26} DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
              {5a44} DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16));
              {5a63} if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY) then
              begin
                {5a6c} StartSoundEffect(8);
                {5a80} if GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX then
                begin
                  {5aae} if (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), (VerticalWork2 +
                  1)].CellSolidFlag = 0) and
                    (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), VerticalWork2].CellSolidFlag = 0)
                    then
                  begin
                    {5ae4} GameActors[EntitySlot].ActorDirectionX := 1;
                    {5af1} GameActors[EntitySlot].ActorAnimationCounter := 201;
                  end;
                end
                else
                begin
                  {5b22} if (LevelCells[((GameActors[EntitySlot].ActorWorldX shr 4) + 1), (VerticalWork2 + 1)].CellSolidFlag =
                  0) and (LevelCells[((GameActors[EntitySlot].ActorWorldX
                    shr 4) + 1), VerticalWork2].CellSolidFlag = 0) then
                  begin
                    {5b55} GameActors[EntitySlot].ActorDirectionX := -1;
                    {5b62} GameActors[EntitySlot].ActorAnimationCounter := 1;
                  end;
                end;
              end
              else
              begin
                {5b8b} if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16))
                then
                begin
                  {5b9f} if GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX then
                  begin
                    {5bcd} if (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), (VerticalWork2 +
                    1)].CellSolidFlag = 0) and
                    (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), VerticalWork2].CellSolidFlag = 0)
                    then
                    begin
                      {5c03} GameActors[EntitySlot].ActorDirectionX := 1;
                      {5c10} GameActors[EntitySlot].ActorAnimationCounter := 201;
                    end;
                  end
                  else
                  begin
                    {5c41} if (LevelCells[((GameActors[EntitySlot].ActorWorldX shr 4) + 1), (VerticalWork2 + 1)].CellSolidFlag
                    = 0) and (LevelCells[((GameActors[EntitySlot].ActorWorldX
                    shr 4) + 1), VerticalWork2].CellSolidFlag = 0) then
                    begin
                      {5c74} GameActors[EntitySlot].ActorDirectionX := -1;
                      {5c81} GameActors[EntitySlot].ActorAnimationCounter := 1;
                    end;
                  end;
                  {5c93} if GameActors[EntitySlot].StateValueB = 0 then
                  begin
                    {5c9c} StartSoundEffect(19);
                    {5cad} PlayerScore := (PlayerScore + 1000);
                    {5cb4} StatusBarCameraX := -1;
                    {5cc1} GameActors[EntitySlot].ActorRemovalPending := 1;
                    {5cdc} RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                    {5cfb} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), GameActors[EntitySlot].ActorWorldY);
                    {5d1a} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                    {5d3d} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), (GameActors[EntitySlot].ActorWorldY -
                    16));
                    {5d60} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), (GameActors[EntitySlot].ActorWorldY -
                    16));
                    {5d7f} RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16));
                    {5db1} SpawnScorePopup((LongInt(GameActors[EntitySlot].ActorWorldX) and 65520),
                    (LongInt(GameActors[EntitySlot].ActorWorldY) and 65520), 20);
                  end
                  else
                  begin
                    {5dba} StartSoundEffect(8);
                  end;
                end;
              end;
            end;
            40: begin
              {5dd1} Inc(GameActors[EntitySlot].ActorAnimationCounter);
              {5de1} if GameActors[EntitySlot].ActorAnimationCounter > 19 then
              begin
                {5dea} GameActors[EntitySlot].ActorAnimationCounter := 1;
              end;
              {5df7} Dec(GameActors[EntitySlot].ActorCounterB);
              {5e07} if GameActors[EntitySlot].ActorCounterB = 0 then
              begin
                {5e13} GameActors[EntitySlot].ActorRemovalPending := 1;
                {5e1e} RedrawLevelCell(UpdateActorsAndShots_ProposedX, UpdateActorsAndSho_VerticalWork);
                {5e2d} RedrawLevelCell((UpdateActorsAndShots_ProposedX - 16), UpdateActorsAndSho_VerticalWork);
                {5e3c} RedrawLevelCell((UpdateActorsAndShots_ProposedX + 16), UpdateActorsAndSho_VerticalWork);
                {5e47} DrawCellForeground(UpdateActorsAndShots_ProposedX, UpdateActorsAndSho_VerticalWork);
                {5e56} DrawCellForeground((UpdateActorsAndShots_ProposedX - 16), UpdateActorsAndSho_VerticalWork);
                {5e65} DrawCellForeground((UpdateActorsAndShots_ProposedX + 16), UpdateActorsAndSho_VerticalWork);
                {5e71} GameDrawBufferRow := (432 - GameDrawBufferRow);
                {5e7a} RedrawLevelCell(UpdateActorsAndShots_ProposedX, UpdateActorsAndSho_VerticalWork);
                {5e89} RedrawLevelCell((UpdateActorsAndShots_ProposedX + 16), UpdateActorsAndSho_VerticalWork);
                {5e98} RedrawLevelCell((UpdateActorsAndShots_ProposedX - 16), UpdateActorsAndSho_VerticalWork);
                {5ea3} DrawCellForeground(UpdateActorsAndShots_ProposedX, UpdateActorsAndSho_VerticalWork);
                {5eb2} DrawCellForeground((UpdateActorsAndShots_ProposedX + 16), UpdateActorsAndSho_VerticalWork);
                {5ec1} DrawCellForeground((UpdateActorsAndShots_ProposedX - 16), UpdateActorsAndSho_VerticalWork);
                {5ecd} GameDrawBufferRow := (432 - GameDrawBufferRow);
              end
              else
              begin
                {5ee9} DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
              end;
            end;
            41: begin
              {5f04} if GameActors[EntitySlot].ActorSpriteBase = 435 then
              begin
                {5f17} UpdateActorsAndS_HorizontalWork := (GameActors[1].ActorWorldX - GameActors[EntitySlot].ActorWorldX);
                {5f28} VerticalWork2 := (GameActors[1].ActorWorldY - GameActors[EntitySlot].ActorWorldY);
                {5f2f} if (UpdateActorsAndS_HorizontalWork < 8) and ((UpdateActorsAndS_HorizontalWork > -8) and
                ((VerticalWork2 < 8) and (VerticalWork2 > -8))) then
                begin
                  while LevelCells[(UpdateActorsAndShots_ProposedX shr 4) + 1, UpdateActorsAndSho_VerticalWork shr
                  4].CellSolidFlag = 0 do
                    Dec(UpdateActorsAndSho_VerticalWork, 16);
                  {5f77} StartSoundEffect(9);
                  {5f86} GameActors[EntitySlot].ActorWorldY := UpdateActorsAndSho_VerticalWork;
                  {5f91} GameActors[EntitySlot].ActorSpriteBase := 619;
                  {5f9e} GameActors[EntitySlot].ActorMovementStep := 8;
                  {5fab} GameActors[EntitySlot].DirectionY := 1;
                end;
              end
              else
              begin
                {5fc7} VerticalWork2 := ((GameActors[EntitySlot].ActorWorldY shr 4) + 2);
                {5fde} UpdateActorsAndS_HorizontalWork := (((GameActors[EntitySlot].ActorWorldX + 3) shr 4) + 1);
                {5ff5} UpdateActorsAnd_RightCellColumn := (((GameActors[EntitySlot].ActorWorldX + 12) shr 4) + 1);
                {6012} if (LevelCells[UpdateActorsAndS_HorizontalWork, VerticalWork2].CellSolidFlag = 0) and
                ((LevelCells[UpdateActorsAnd_RightCellColumn, VerticalWork2].CellSolidFlag = 0) and
                ((LevelCells[UpdateActorsAndS_HorizontalWork, VerticalWork2].SupportsLanding =
                    0) and (LevelCells[UpdateActorsAnd_RightCellColumn, VerticalWork2].SupportsLanding = 0))) then
                begin
                  {6089} GameActors[EntitySlot].ActorWorldY := (GameActors[EntitySlot].ActorWorldY + 4);
                  {60a3} RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                  {60be} RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                  {60e1} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), (GameActors[EntitySlot].ActorWorldY -
                  16));
                  {6104} RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), (GameActors[EntitySlot].ActorWorldY -
                  16));
                end
                else
                begin
                  {6113} GameActors[EntitySlot].ActorRemovalPending := 1;
                  {611e} RedrawLevelCell(UpdateActorsAndShots_ProposedX, UpdateActorsAndSho_VerticalWork);
                  {612d} RedrawLevelCell((UpdateActorsAndShots_ProposedX - 16), UpdateActorsAndSho_VerticalWork);
                  {613c} RedrawLevelCell((UpdateActorsAndShots_ProposedX + 16), UpdateActorsAndSho_VerticalWork);
                  {614b} RedrawLevelCell(UpdateActorsAndShots_ProposedX, (UpdateActorsAndSho_VerticalWork - 16));
                  {615e} RedrawLevelCell((UpdateActorsAndShots_ProposedX - 16), (UpdateActorsAndSho_VerticalWork - 16));
                  {6171} RedrawLevelCell((UpdateActorsAndShots_ProposedX + 16), (UpdateActorsAndSho_VerticalWork - 16));
                  {617c} DrawCellForeground(UpdateActorsAndShots_ProposedX, UpdateActorsAndSho_VerticalWork);
                  {618b} DrawCellForeground((UpdateActorsAndShots_ProposedX - 16), UpdateActorsAndSho_VerticalWork);
                  {619a} DrawCellForeground((UpdateActorsAndShots_ProposedX + 16), UpdateActorsAndSho_VerticalWork);
                  {61a9} DrawCellForeground(UpdateActorsAndShots_ProposedX, (UpdateActorsAndSho_VerticalWork - 16));
                  {61bc} DrawCellForeground((UpdateActorsAndShots_ProposedX - 16), (UpdateActorsAndSho_VerticalWork - 16));
                  {61cf} DrawCellForeground((UpdateActorsAndShots_ProposedX + 16), (UpdateActorsAndSho_VerticalWork - 16));
                  {61db} GameDrawBufferRow := (432 - GameDrawBufferRow);
                  {61e4} RedrawLevelCell(UpdateActorsAndShots_ProposedX, UpdateActorsAndSho_VerticalWork);
                  {61f3} RedrawLevelCell((UpdateActorsAndShots_ProposedX + 16), UpdateActorsAndSho_VerticalWork);
                  {6202} RedrawLevelCell((UpdateActorsAndShots_ProposedX - 16), UpdateActorsAndSho_VerticalWork);
                  {6211} RedrawLevelCell(UpdateActorsAndShots_ProposedX, (UpdateActorsAndSho_VerticalWork - 16));
                  {6224} RedrawLevelCell((UpdateActorsAndShots_ProposedX + 16), (UpdateActorsAndSho_VerticalWork - 16));
                  {6237} RedrawLevelCell((UpdateActorsAndShots_ProposedX - 16), (UpdateActorsAndSho_VerticalWork - 16));
                  {6242} DrawCellForeground(UpdateActorsAndShots_ProposedX, UpdateActorsAndSho_VerticalWork);
                  {6251} DrawCellForeground((UpdateActorsAndShots_ProposedX + 16), UpdateActorsAndSho_VerticalWork);
                  {6260} DrawCellForeground((UpdateActorsAndShots_ProposedX - 16), UpdateActorsAndSho_VerticalWork);
                  {626f} DrawCellForeground(UpdateActorsAndShots_ProposedX, (UpdateActorsAndSho_VerticalWork - 16));
                  {6282} DrawCellForeground((UpdateActorsAndShots_ProposedX + 16), (UpdateActorsAndSho_VerticalWork - 16));
                  {6295} DrawCellForeground((UpdateActorsAndShots_ProposedX - 16), (UpdateActorsAndSho_VerticalWork - 16));
                  {62a1} GameDrawBufferRow := (432 - GameDrawBufferRow);
                end;
                {62b2} UpdateActorsAndS_HorizontalWork := (GameActors[1].ActorWorldX - GameActors[EntitySlot].ActorWorldX);
                {62c3} VerticalWork2 := (GameActors[1].ActorWorldY - GameActors[EntitySlot].ActorWorldY);
                {62ca} if (UpdateActorsAndS_HorizontalWork < 10) and ((UpdateActorsAndS_HorizontalWork > -10) and
                ((VerticalWork2 < 10) and (VerticalWork2 > -10))) then
                begin
                  {62f6} PlayerScore := (PlayerScore + 5000);
                  {62fd} StatusBarCameraX := -1;
                  {630a} GameActors[EntitySlot].ActorKindCode := 5001;
                  {6317} GameActors[EntitySlot].ActorCounterB := 16;
                  {6324} GameActors[EntitySlot].ActorSpriteBase := 172;
                  {6331} GameActors[EntitySlot].ActorAnimationCounter := 1;
                  {6340} GameActors[EntitySlot].ActorMovementStep := 0;
                  {6368} PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3203], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 16));
                  {6391} PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3203], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 416));
                end;
              end;
            end;
            43: begin
              {63a5} Inc(GameActors[EntitySlot].ActorCounterA);
              {63bf} if GameActors[EntitySlot].ActorCounterA = GameActors[EntitySlot].ActorCounterB then
              begin
                {63c8} Inc(GameActors[EntitySlot].ActorAnimationCounter);
                {63d8} if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                begin
                  {63eb} GameActors[EntitySlot].ActorAnimationCounter := (Random(5) + 1);
                end;
                {63f8} GameActors[EntitySlot].ActorCounterA := 0;
              end;
            end;
            44: begin
              {640a} Inc(GameActors[EntitySlot].ActorAnimationCounter);
              {641b} if GameActors[EntitySlot].ActorSpriteBase = 259 then
              begin
                {6424} Inc(GameActors[EntitySlot].ActorAnimationCounter);
                {643f} DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
              end;
              {644e} if GameActors[EntitySlot].ActorAnimationCounter > 19 then
              begin
                {6457} GameActors[EntitySlot].ActorAnimationCounter := 1;
              end;
            end;
          end;
        end;
      end;
  for EntitySlot := 1 to PlayerProjectileLimit do
  begin
    {648b} if (PlayerShots[EntitySlot].ActorSlotInactive = 0) and (PlayerShots[EntitySlot].ActorSpriteBase <> 626) then
    begin
      {64b4} PlayerShots[EntitySlot].ActorPreviousX := PlayerShots[EntitySlot].ActorWorldX;
      {64ca} PlayerShots[EntitySlot].ActorPreviousY := PlayerShots[EntitySlot].ActorWorldY;
      {64da} if PlayerShots[EntitySlot].ActorDirectionX = 1 then
      begin
        {64f2} UpdateActorsAndShots_ProposedX := (PlayerShots[EntitySlot].ActorWorldX +
        PlayerShots[EntitySlot].ActorMovementStep);
      end
      else
      begin
        {6503} if PlayerShots[EntitySlot].ActorDirectionX = -1 then
        begin
          {651b} UpdateActorsAndShots_ProposedX := (PlayerShots[EntitySlot].ActorWorldX -
          PlayerShots[EntitySlot].ActorMovementStep);
        end
        else
        begin
          {652b} UpdateActorsAndShots_ProposedX := PlayerShots[EntitySlot].ActorWorldX;
        end;
      end;
      {6542} UpdateActorsAndSho_VerticalWork := (((PlayerShots[EntitySlot].ActorWorldY + 8) shr 4) + 1);
      {6565} if (LevelCells[((UpdateActorsAndShots_ProposedX shr 4) + 1), UpdateActorsAndSho_VerticalWork].CellSolidFlag <> 0)
      or (LevelCells[(((UpdateActorsAndShots_ProposedX + 8) shr 4) + 1), UpdateActorsAndSho_VerticalWork].CellSolidFlag <> 0)
      then
      begin
        {6590} StartSoundEffect(7);
        {659c} PlayerShots[EntitySlot].ActorSpriteBase := 626;
        {65ab} PlayerShots[EntitySlot].ActorMovementStep := 0;
        {65b6} PlayerShots[EntitySlot].ActorCounterB := 7;
      end;
      {65c6} PlayerShots[EntitySlot].ActorWorldX := UpdateActorsAndShots_ProposedX;
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Tests the four corners of the player's prospective 10x16 collision rectangle against Solid cells. }
function PlayerPositionIsClear(MoveOffsetX, MoveOffsetY: Word): Boolean;
var
  LeftCellColumn: Word;
  TopCellRow: Word;
  PlayerPositionI_RightCellColumn: Word;
  BottomCellRow: Word;
begin
  LeftCellColumn := ((Word(GameActors[1].ActorWorldX) + MoveOffsetX + 3) shr 4) + 1;
  PlayerPositionI_RightCellColumn := ((Word(GameActors[1].ActorWorldX) + MoveOffsetX + 12) shr 4) + 1;
  TopCellRow := ((Word(GameActors[1].ActorWorldY) + MoveOffsetY) shr 4) + 1;
  BottomCellRow := ((Word(GameActors[1].ActorWorldY) + MoveOffsetY + 15) shr 4) + 1;

  if (LevelCells[LeftCellColumn, TopCellRow].CellSolidFlag <> 0) or
     (LevelCells[PlayerPositionI_RightCellColumn, TopCellRow].CellSolidFlag <> 0) or
     (LevelCells[LeftCellColumn, BottomCellRow].CellSolidFlag <> 0) or
     (LevelCells[PlayerPositionI_RightCellColumn, BottomCellRow].CellSolidFlag <> 0) then
  begin
    PlayerPositionIsClear := False;
    if CurrentLevelNumber > 1 then
      MoveRampTicks := 0;
  end
  else
    PlayerPositionIsClear := True;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Advances fall-table position, moves the player downward. }
procedure ApplyPlayerGravity;
begin
  Inc(PlayerVerticalMotionStep);
  if PlayerVerticalMotionStep > 19 then
    PlayerVerticalMotionStep := 19;
  PlayerFalling := 1;
  Inc(GameActors[1].ActorWorldY, PlayerVerticalMotionTable[PlayerVerticalMotionStep]);
  if (LevelCells[((GameActors[1].ActorWorldX + 3) shr 4) + 1, ((GameActors[1].ActorWorldY shr 4) + 2)].CellSolidFlag <> 0) or
     (LevelCells[((GameActors[1].ActorWorldX + 12) shr 4) + 1, ((GameActors[1].ActorWorldY shr 4) + 2)].CellSolidFlag <> 0)
     then
  begin
    Inc(PlayerLandingCount);
    GameActors[1].ActorWorldY := GameActors[1].ActorWorldY and $FFF0;
    PlayerFalling := 0;
  end;
  if PlayerVerticalMotionStep > 10 then
  begin
    if (LevelCells[((GameActors[1].ActorWorldX + 3) shr 4) + 1, ((GameActors[1].ActorWorldY + 16) shr 4) + 1].SupportsLanding
    <> 0) or
       (LevelCells[((GameActors[1].ActorWorldX + 12) shr 4) + 1, ((GameActors[1].ActorWorldY + 16) shr 4) + 1].SupportsLanding
       <> 0) then
    begin
      if GameActors[1].ActorWorldY < 5 then
      begin
        Inc(PlayerLandingCount);
        GameActors[1].ActorWorldY := GameActors[1].ActorWorldY and $FFF0;
        PlayerFalling := 0;
      end
      else if (LevelCells[((GameActors[1].ActorWorldX + 3) shr 4) + 1, ((GameActors[1].ActorWorldY + 7) shr 4) +
      1].SupportsLanding = 0) and
              (LevelCells[((GameActors[1].ActorWorldX + 12) shr 4) + 1, ((GameActors[1].ActorWorldY + 7) shr 4) +
              1].SupportsLanding = 0) then
      begin
        Inc(PlayerLandingCount);
        GameActors[1].ActorWorldY := GameActors[1].ActorWorldY and $FFF0;
        PlayerFalling := 0;
      end;
    end;
  end;
  if CameraY + 120 < GameActors[1].ActorWorldY then
  begin
    if CameraY + PlayerVerticalMotionTable[PlayerVerticalMotionStep] < 184 then
      Inc(CameraY, PlayerVerticalMotionTable[PlayerVerticalMotionStep])
    else
      CameraY := 184;
  end;
  if PlayerFalling <> 0 then
  begin
    if (GameActors[1].ActorSpriteBase = 1) or (GameActors[1].ActorSpriteBase = 9) or (GameActors[1].ActorSpriteBase = 11) or
    (GameActors[1].ActorSpriteBase = 13) then
      GameActors[1].ActorSpriteBase := 13
    else
      GameActors[1].ActorSpriteBase := 14;
  end
  else if GameActors[1].ActorSpriteBase = 13 then
  begin
    if PlayerRightHeld <> 0 then
      GameActors[1].ActorSpriteBase := 1
    else
      GameActors[1].ActorSpriteBase := 9;
  end
  else if GameActors[1].ActorSpriteBase = 14 then
  begin
    if PlayerLeftHeld <> 0 then
      GameActors[1].ActorSpriteBase := 5
    else
      GameActors[1].ActorSpriteBase := 10;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Moves in held directions when u1_65d9 permits, saves previous position and scrolls the bounded camera. }
procedure MovePlayerAndCamera;
begin
  GameActors[1].ActorPreviousX := GameActors[1].ActorWorldX;
  GameActors[1].ActorPreviousY := GameActors[1].ActorWorldY;

  if PlayerRightHeld <> 0 then
  begin
    UpdatePlayerMoveSpeed;
    if PlayerPositionIsClear(PlayerHorizontalStep, 0) then
    begin
      if CameraX < 320 then
      begin
        if CameraX + 170 < GameActors[1].ActorWorldX then
        begin
          Inc(CameraX, PlayerHorizontalStep);
          if CameraX > 320 then
            CameraX := 320;
        end;
      end;
      Inc(GameActors[1].ActorWorldX, PlayerHorizontalStep);
    end;
  end;

  if PlayerLeftHeld <> 0 then
  begin
    UpdatePlayerMoveSpeed;
    if PlayerPositionIsClear(-PlayerHorizontalStep, 0) then
    begin
      if CameraX > 0 then
      begin
        if CameraX + 150 > GameActors[1].ActorWorldX then
        begin
          Dec(CameraX, PlayerHorizontalStep);
          if CameraX < 0 then
            CameraX := 0;
        end;
      end;
      Dec(GameActors[1].ActorWorldX, PlayerHorizontalStep);
    end;
  end;

  if PlayerDownHeld <> 0 then
  begin
    if PlayerPositionIsClear(0, 4) then
    begin
      if CameraY < 184 then
      begin
        if CameraY + 80 < GameActors[1].ActorWorldY then
          Inc(CameraY, 4);
      end;
      Inc(GameActors[1].ActorWorldY, 4);
    end;
  end;

  if PlayerUpHeld <> 0 then
  begin
    if PlayerPositionIsClear(0, Word(-4)) then
    begin
      if CameraY > 0 then
      begin
        if CameraY + 80 > GameActors[1].ActorWorldY then
        begin
          Dec(CameraY, 4);
          if CameraY < 0 then
            CameraY := 0;
        end;
      end;
      Dec(GameActors[1].ActorWorldY, 4);
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Applies gravity, begins a keyboard/joystick jump when grounded with headroom. }
procedure UpdatePlayerJump;
begin
  if (PlayerJumping = 0) and (PlayerOnMovingSupport = 0) then
    ApplyPlayerGravity;

  if (PlayerInputLocked = 0) and (PlayerJumping = 0) and (PlayerFalling = 0) then
    if (PlayerJumpHeld <> 0) or (IsJoystickButton0Pressed and (JoystickActive)) then
    begin
      if LevelCells[(((GameActors[1].ActorWorldX + 3) shr 4) + 1), (((GameActors[1].ActorWorldY - 3) shr 4) +
      1)].CellSolidFlag = 0 then
      begin
        if LevelCells[(((GameActors[1].ActorWorldX + 12) shr 4) + 1), (((GameActors[1].ActorWorldY - 3) shr 4) +
        1)].CellSolidFlag = 0 then
        begin
          if (GameActors[1].ActorSpriteBase = 1) or (GameActors[1].ActorSpriteBase = 9) or (GameActors[1].ActorSpriteBase =
          11) or (GameActors[1].ActorSpriteBase = 13) then
            GameActors[1].ActorSpriteBase := 13
          else
            GameActors[1].ActorSpriteBase := 14;
          StartSoundEffect(1);
          PlayerJumping := 1;
          PlayerOnMovingSupport := 0;
          PlayerVerticalMotionStep := 0;
        end;
      end;
    end;

  if PlayerJumping <> 0 then
  begin
    Inc(PlayerVerticalMotionStep);
    if PlayerVerticalMotionStep = 10 then
    begin
      PlayerJumping := 0;
      PlayerVerticalMotionStep := 9;
    end;
    if PlayerVerticalMotionStep < 17 then
      if PlayerPositionIsClear(0, -Integer(PlayerVerticalMotionTable[PlayerVerticalMotionStep])) then
      begin
        if CameraY > 0 then
          if CameraY + 80 > GameActors[1].ActorWorldY then
          begin
            Dec(CameraY, PlayerVerticalMotionTable[PlayerVerticalMotionStep]);
            if CameraY < 0 then
              CameraY := 0;
          end;
        Dec(GameActors[1].ActorWorldY, PlayerVerticalMotionTable[PlayerVerticalMotionStep]);
      end
      else
      begin
        PlayerVerticalMotionStep := 9;
        PlayerJumping := 0;
      end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Dispatches foreground codes for pickups, colored keys/doors, level entrances/exits, radar gating. }
procedure ProcessPlayerTileContact(ProcessPlayerTileConta_ContactX, ProcessPlayerTileConta_ContactY: Integer);
var
  ContactWork, WorkX, WorkY: Integer;
begin
  case Integer(LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode)
  of
    0: ;
    $1A5,$1A7,$1A9:
      begin
        case Integer(LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr
        4)+1].CellObjectCode) of
          $1A5: HasKeyOne := 1;
          $1A7: HasKeyTwo := 1;
          $1A9: HasKeyThree := 1;
        end;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
        StatusBarCameraX := -1;
      end;
    $1A6,$1A8,$1AA:
      begin
        ContactWork := 0;
        case Integer(LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr
        4)+1].CellObjectCode) of
          $1A6: if HasKeyOne = 1 then begin ContactWork := 1; HasKeyOne := 0 end;
          $1A8: if HasKeyTwo = 1 then begin ContactWork := 1; HasKeyTwo := 0 end;
          $1AA: if HasKeyThree = 1 then begin ContactWork := 1; HasKeyThree := 0 end;
        end;
        if ContactWork = 1 then
        begin
          LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
          LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellSolidFlag := 0;
          StartSoundEffect(6);
          StatusBarCameraX := -1;
        end;
      end;
    $12D:
      begin
        PlayerAmmo := PlayerAmmo + 5;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        if PlayerAmmo > 99 then PlayerAmmo := 99;
        StatusBarCameraX := -1;
        StartSoundEffect(5);
      end;
    $13C:
      begin
        PlayerScore := PlayerScore + 1000;
        SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,20);
        StatusBarCameraX := -1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $26A:
      begin
        PlayerScore := PlayerScore + 250;
        SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,18);
        StatusBarCameraX := -1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $26B:
      begin
        PlayerScore := PlayerScore + 1000;
        SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,20);
        StatusBarCameraX := -1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $26C:
      begin
        PlayerScore := PlayerScore + 500;
        SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,19);
        StatusBarCameraX := -1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $275:
      begin
        PlayerScore := PlayerScore + 100;
        SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,17);
        StatusBarCameraX := -1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $276:
      begin
        PlayerScore := PlayerScore + 1000;
        SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,20);
        StatusBarCameraX := -1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $277:
      begin
        PlayerScore := PlayerScore + 500;
        SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,19);
        StatusBarCameraX := -1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $278:
      begin
        PlayerScore := PlayerScore + 100;
        SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,17);
        StatusBarCameraX := -1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $2C:
      begin
        PlayerScore := PlayerScore + 500;
        SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,19);
        StatusBarCameraX := -1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $26D..$26F:
      begin
        case Integer(LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr
        4)+1].CellObjectCode) of
          $26D:
            begin
              BonusStep621Collected := 1;
              PlayerScore := PlayerScore + 100;
              SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,17);
              StatusBarCameraX := -1;
              StartSoundEffect(4);
            end;
          $26E:
            if (BonusPickupOrderValid <> 0) and (BonusStep621Collected <> 0) then
            begin
              BonusStep622Collected := 1;
              PlayerScore := PlayerScore + 100;
              SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,17);
              StatusBarCameraX := -1;
              StartSoundEffect(4);
            end
            else
            begin
              BonusStep622Collected := 1;
              BonusPickupOrderValid := 0;
              PlayerScore := PlayerScore + 100;
              SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,17);
              StatusBarCameraX := -1;
              StartSoundEffect(4);
            end;
          $26F:
            if (BonusPickupOrderValid <> 0) and (BonusStep621Collected <> 0) and (BonusStep622Collected <> 0) then
            begin
              PlayerScore := PlayerScore + 10000;
              SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,23);
              StatusBarCameraX := -1;
              StartSoundEffect(12);
            end
            else
            begin
              PlayerScore := PlayerScore + 100;
              SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,17);
              StatusBarCameraX := -1;
              BonusPickupOrderValid := 0;
              StartSoundEffect(4);
            end;
        end;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
      end;
    $25E:
      begin
        PlayerScore := PlayerScore + 500;
        SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,19);
        StatusBarCameraX := -1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
        StatusBarCameraX := -1;
      end;
    $130:
      begin
        LevelBlueprintFlags[CurrentLevelNumber] := 1;
        PlayerScore := PlayerScore + 2000;
        SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,21);
        StatusBarCameraX := -1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
        EpisodeBlueprintCollected := 1;
      end;
    $25F:
      begin
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
        ShowGameMessage('You can see invisible platforms.');
        for ProcessPlayerTileConta_ContactY := 1 to 24 do
          for ProcessPlayerTileConta_ContactX := 1 to 40 do
            if Integer(LevelCells[ProcessPlayerTileConta_ContactX,ProcessPlayerTileConta_ContactY].CellObjectCode) = -1 then
            begin
              LevelCells[ProcessPlayerTileConta_ContactX,ProcessPlayerTileConta_ContactY].CellOverlayTile := $260;
              LevelCells[ProcessPlayerTileConta_ContactX,ProcessPlayerTileConta_ContactY].SupportsLanding := 1;
              RedrawLevelCell((ProcessPlayerTileConta_ContactX-1) shl 4,(ProcessPlayerTileConta_ContactY-1) shl 4);
              DrawCellForeground((ProcessPlayerTileConta_ContactX-1) shl 4,(ProcessPlayerTileConta_ContactY-1) shl 4);
              GameDrawBufferRow := 432 - GameDrawBufferRow;
              RedrawLevelCell((ProcessPlayerTileConta_ContactX-1) shl 4,(ProcessPlayerTileConta_ContactY-1) shl 4);
              DrawCellForeground((ProcessPlayerTileConta_ContactX-1) shl 4,(ProcessPlayerTileConta_ContactY-1) shl 4);
              GameDrawBufferRow := 432 - GameDrawBufferRow;
              StartSoundEffect(7);
              Delay(100);
            end;
      end;
    $201..$204:
      begin
        if SoundPlaying = 0 then StartSoundEffect(28);
        if PlayerGodMode = 0 then PlayerInputLocked := 1;
        LevelEntranceAnimationTick := 51;
        EntrancePlayerX := GameActors[1].ActorWorldX;
        EntrancePlayerY := GameActors[1].ActorWorldY;
        case Integer(LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr
        4)+1].CellObjectCode) of
          $113..$122:
            begin
              EnteredLevelNumber := Integer(LevelCells[(ProcessPlayerTileConta_ContactX shr
              4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode) - $111;
              LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode
              := $10C;
            end;
          $10C:
            if LevelEntranceAnimationTick > 15 then Inc(Integer(LevelCells[(ProcessPlayerTileConta_ContactX shr
            4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode));
          $10D:
            if LevelEntranceAnimationTick > 30 then Inc(Integer(LevelCells[(ProcessPlayerTileConta_ContactX shr
            4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode));
        end;
        if LevelEntranceAnimationTick > 50 then
        begin
          EnteredLevelNumber := Integer(LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY
          shr 4)+1].CellBaseTile);
          LevelEntranceAnimationTick := 0;
          FadeGamePaletteToBlack(20);
          CurrentLevelNumber := EnteredLevelNumber;
          CaptureGameSnapshot;
          if GameSnapshot.SavedPlayerX > (ProcessPlayerTileConta_ContactX and $FFF0) + 8 then
            GameSnapshot.SavedPlayerX := (GameSnapshot.SavedPlayerX and $FFF0) + 16
          else
            GameSnapshot.SavedPlayerX := (GameSnapshot.SavedPlayerX + 8) and $FFF0;
          if GameSnapshot.SavedPlayerY > (ProcessPlayerTileConta_ContactY and $FFF0) + 8 then
            GameSnapshot.SavedPlayerY := (GameSnapshot.SavedPlayerY and $FFF0) + 16
          else
            GameSnapshot.SavedPlayerY := (GameSnapshot.SavedPlayerY + 8) and $FFF0;
          LoadLevelMap(EnteredLevelNumber);
          ResetLevelTransientState;
          LevelCompletedFlags[EnteredLevelNumber] := 1;
          PlayerDownHeld := 0;
          PlayerUpHeld := 0;
        end;
      end;
    $27B:
      begin
        PlayerHasDynamite := 1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
        StatusBarCameraX := -1;
        SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,19);
        PlayerScore := PlayerScore + 500;
      end;
    $27D:
      begin
        if PlayerHasDynamite = 1 then
        begin
          PlayerHasDynamite := 0;
          StartSoundEffect(11);
          StatusBarCameraX := -1;
          if GameActors[1].ActorWorldX + 5 > ProcessPlayerTileConta_ContactX then
          begin
            WorkX := ((ProcessPlayerTileConta_ContactX shr 4)+1) shl 4;
            WorkY := ProcessPlayerTileConta_ContactY and $FFF0;
          end
          else
          begin
            WorkX := ((ProcessPlayerTileConta_ContactX shr 4)-1) shl 4;
            WorkY := ProcessPlayerTileConta_ContactY and $FFF0;
          end;
          PgBlitMaskedShifted16x16(PRawByteView(SpriteBank601)^[$1543],WorkX,WorkY+16);
          PgBlitMaskedShifted16x16(PRawByteView(SpriteBank601)^[$1543],WorkX,WorkY+416);
          ContactWork := 1;
          repeat
            Inc(ContactWork);
          until (GameActors[ContactWork].ActorSlotInactive = 1) or (ContactWork = 25);
          GameActors[ContactWork].FlashFrames := 0;
          GameActors[ContactWork].ActorSpriteBase := $27B;
          GameActors[ContactWork].ActorWorldX := WorkX;
          GameActors[ContactWork].ActorWorldY := WorkY;
          GameActors[ContactWork].ActorPreviousX := WorkX;
          GameActors[ContactWork].ActorPreviousY := WorkY;
          GameActors[ContactWork].ActorDirectionX := 1;
          GameActors[ContactWork].DirectionY := 0;
          GameActors[ContactWork].ActorAnimationCounter := 1;
          GameActors[ContactWork].ActorMovementStep := 0;
          GameActors[ContactWork].ActorCounterA := 40;
          GameActors[ContactWork].ActorCounterB := 0;
          GameActors[ContactWork].ActorKindCode := 22;
          GameActors[ContactWork].ActorSlotInactive := 0;
          GameActors[ContactWork].ActorRemovalPending := 0;
          BlastDoorContactHandled := 1;
        end
        else
          if BlastDoorContactHandled = 0 then
          begin
            BlastDoorContactHandled := 1;
            ClearPopupText;
            PopupTextLines[1] := 'You have no way to open';
            PopupTextLines[2] := 'this door right now.   ';
            PopupTextLines[3][0] := #0;
            PopupTextLines[4] := 'Press ESCAPE  ';
            PopupTextLines[5] := 'END OF WINDOW';
            PopupAcceptedScanCodes[1] := 1;
            PopupSelectionScanCode := ReadPopupScanCode(0);
            EscapePressed := 0;
            GameOptionsRequested := 0;
          end;
      end;
    $27E:
      begin
        if LevelRadarDestroyed <> 0 then
        begin
          if EpisodeBlueprintCollected <> 0 then QuitGameRequested := 1;
          PlayerLeavingLevel := 1;
          LevelCompletedFlags[CurrentLevelNumber] := 1;
          if PlayerHealth = 3 then
          begin
            ShowPerfectHealthBonus;
            PlayerScore := PlayerScore + 25000;
            StatusBarCameraX := -1;
          end;
          if (ProcessPlayerTileConta_ContactX shr 4 = 0) or
             (LevelCells[((ProcessPlayerTileConta_ContactX shr 4)+1)-1,(ProcessPlayerTileConta_ContactY shr
             4)+1].CellSolidFlag = 1) then
          begin
            GameActors[1].ActorPreviousX := GameActors[1].ActorWorldX;
            GameActors[1].ActorPreviousY := GameActors[1].ActorWorldY;
            GameActors[1].ActorWorldX := (ProcessPlayerTileConta_ContactX and $FFF0) + 16;
            GameActors[1].ActorWorldY := ProcessPlayerTileConta_ContactY and $FFF0;
            GameActors[1].ActorDirectionX := -1;
            GameActors[1].ActorSpriteBase := 5;
            PlayerJumping := 0;
            PlayerFalling := 0;
            PlayerLeftHeld := 1;
            PlayerRightHeld := 0;
          end
          else
          begin
            GameActors[1].ActorPreviousX := GameActors[1].ActorWorldX;
            GameActors[1].ActorPreviousY := GameActors[1].ActorWorldY;
            GameActors[1].ActorWorldX := (ProcessPlayerTileConta_ContactX and $FFF0) - 16;
            GameActors[1].ActorWorldY := ProcessPlayerTileConta_ContactY and $FFF0;
            GameActors[1].ActorDirectionX := 1;
            GameActors[1].ActorSpriteBase := 1;
            PlayerJumping := 0;
            PlayerFalling := 0;
            PlayerLeftHeld := 0;
            PlayerRightHeld := 1;
          end;
        end
        else
          if CurrentLevelNumber > 1 then
          begin
            StartSoundEffect(15);
            ClearPopupText;
            PopupTextLines[1] := '     MISSION ALERT!    ';
            PopupTextLines[2] := '                       ';
            PopupTextLines[3] := 'You failed to destroy a';
            PopupTextLines[4] := 'vital radar dish. Find ';
            PopupTextLines[5] := 'and destroy! ';
            PopupTextLines[6] := '                       ';
            PopupTextLines[7] := 'Press ESCAPE!          ';
            PopupTextLines[8] := 'END OF WINDOW';
            PopupAcceptedScanCodes[1] := 1;
            PopupSelectionScanCode := ReadPopupScanCode(0);
            EscapePressed := 0;
            GameOptionsRequested := 0;
            if (ProcessPlayerTileConta_ContactX shr 4 = 0) or
               (LevelCells[((ProcessPlayerTileConta_ContactX shr 4)+1)-1,(ProcessPlayerTileConta_ContactY shr
               4)+1].CellSolidFlag = 1) then
            begin
              GameActors[1].ActorPreviousX := GameActors[1].ActorWorldX;
              GameActors[1].ActorPreviousY := GameActors[1].ActorWorldY;
              GameActors[1].ActorWorldX := (ProcessPlayerTileConta_ContactX and $FFF0) + 16;
              GameActors[1].ActorWorldY := ProcessPlayerTileConta_ContactY and $FFF0;
              GameActors[1].ActorSpriteBase := 10;
              PlayerJumping := 0;
              PlayerFalling := 0;
              PlayerLeftHeld := 0;
              PlayerRightHeld := 0;
            end
            else
            begin
              GameActors[1].ActorPreviousX := GameActors[1].ActorWorldX;
              GameActors[1].ActorPreviousY := GameActors[1].ActorWorldY;
              GameActors[1].ActorWorldX := (ProcessPlayerTileConta_ContactX and $FFF0) - 16;
              GameActors[1].ActorWorldY := ProcessPlayerTileConta_ContactY and $FFF0;
              GameActors[1].ActorSpriteBase := 9;
              PlayerJumping := 0;
              PlayerFalling := 0;
              PlayerLeftHeld := 0;
              PlayerRightHeld := 0;
            end;
          end;
      end;
    $270:
      begin
        ContactWork := 1;
        repeat
          Inc(ContactWork);
        until (GameActors[ContactWork].ActorSlotInactive = 1) or (ContactWork = 25);
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        GameActors[ContactWork].FlashFrames := 0;
        GameActors[ContactWork].ActorSpriteBase := $271;
        GameActors[ContactWork].ActorWorldX := ProcessPlayerTileConta_ContactX and $FFF0;
        GameActors[ContactWork].ActorWorldY := ProcessPlayerTileConta_ContactY and $FFF0;
        GameActors[ContactWork].ActorPreviousX := ProcessPlayerTileConta_ContactX and $FFF0;
        GameActors[ContactWork].ActorPreviousY := ProcessPlayerTileConta_ContactY and $FFF0;
        GameActors[ContactWork].ActorDirectionX := 1;
        GameActors[ContactWork].DirectionY := 0;
        GameActors[ContactWork].ActorAnimationCounter := 1;
        GameActors[ContactWork].ActorMovementStep := 0;
        GameActors[ContactWork].ActorCounterA := 40;
        GameActors[ContactWork].ActorCounterB := 0;
        GameActors[ContactWork].ActorKindCode := 23;
        GameActors[ContactWork].ActorSlotInactive := 0;
        GameActors[ContactWork].ActorRemovalPending := 0;
        if PlayerGodMode = 0 then PlayerInputLocked := 1;
        if (PlayerDying = 0) and (PlayerGodMode = 0) then
        begin
          PlayerDying := 1;
          DeathAnimationTick := 35;
        end;
        PlayerUpHeld := 0;
        PlayerDownHeld := 0;
        PlayerLeftHeld := 0;
        PlayerRightHeld := 0;
        PlayerJumping := 0;
      end;
    $1F3,$25B,$265,$267,$268:
      if PlayerGodMode = 0 then
      begin
        PlayerDying := 1;
        DeathAnimationTick := 35;
        StartSoundEffect(22);
      end;
    $25C:
      begin
        if PlayerHasFloppyDisk = 1 then
        begin
          PlayerHasFloppyDisk := 0;
          ComputerMessageShown := 1;
          LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellSolidFlag := 0;
          StartSoundEffect(24);
          for ProcessPlayerTileConta_ContactY := 1 to 24 do
            for ProcessPlayerTileConta_ContactX := 1 to 40 do
              if Integer(LevelCells[ProcessPlayerTileConta_ContactX,ProcessPlayerTileConta_ContactY].CellObjectCode) = $25B
              then
              begin
                LevelCells[ProcessPlayerTileConta_ContactX,ProcessPlayerTileConta_ContactY].CellObjectCode := 0;
                RedrawLevelCell((ProcessPlayerTileConta_ContactX-1) shl 4,(ProcessPlayerTileConta_ContactY-1) shl 4);
                DrawCellForeground((ProcessPlayerTileConta_ContactX-1) shl 4,(ProcessPlayerTileConta_ContactY-1) shl 4);
                GameDrawBufferRow := 432 - GameDrawBufferRow;
                RedrawLevelCell((ProcessPlayerTileConta_ContactX-1) shl 4,(ProcessPlayerTileConta_ContactY-1) shl 4);
                DrawCellForeground((ProcessPlayerTileConta_ContactX-1) shl 4,(ProcessPlayerTileConta_ContactY-1) shl 4);
                GameDrawBufferRow := 432 - GameDrawBufferRow;
              end;
          ShowGameMessage('Laser Field has been De-Activated.');
        end
        else
          if ComputerMessageShown = 0 then
          begin
            StartSoundEffect(25);
            ComputerMessageShown := 1;
            ClearPopupText;
            PopupTextLines[1] := 'The computer needs a floppy';
            PopupTextLines[2] := 'disk to operate.';
            PopupTextLines[3][0] := #0;
            PopupTextLines[4] := 'Press ESCAPE';
            PopupTextLines[5] := 'END OF WINDOW';
            PopupAcceptedScanCodes[1] := 1;
            PopupSelectionScanCode := ReadPopupScanCode(0);
            EscapePressed := 0;
            GameOptionsRequested := 0;
          end;
      end;
    $25D:
      begin
        PlayerHasFloppyDisk := 1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
        StatusBarCameraX := -1;
        SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,19);
        PlayerScore := PlayerScore + 500;
      end;
    $B7:
      begin
        ProcessPlayerTileConta_ContactX := ProcessPlayerTileConta_ContactX and $FFF0;
        if (((GameActors[1].ActorWorldX > ProcessPlayerTileConta_ContactX) and
        (GameActors[1].ActorWorldX-ProcessPlayerTileConta_ContactX <= 2)) or
            ((GameActors[1].ActorWorldX < ProcessPlayerTileConta_ContactX) and
            (ProcessPlayerTileConta_ContactX-GameActors[1].ActorWorldX <= 2))) and
           (PlayerTeleporting = 0) then
        begin
          StatusBarCameraX := -1;
          StartSoundEffect(23);
          for WorkY := 1 to 24 do
            for WorkX := 1 to 40 do
              if Integer(LevelCells[WorkX,WorkY].CellObjectCode) = $B7 then
                if (((ProcessPlayerTileConta_ContactX shr 4)+1) <> WorkX) or (((ProcessPlayerTileConta_ContactY shr 4)+1) <>
                WorkY) then
                begin
                  TeleportDestinationX := (WorkX-1) shl 4;
                  TeleportDestinationY := (WorkY-1) shl 4;
                  if LevelCells[TeleportDestinationX shr 4,(TeleportDestinationY shr 4)+1].CellSolidFlag <> 0 then
                    TeleportDestinationX := TeleportDestinationX + 3
                  else
                    TeleportDestinationX := TeleportDestinationX - 3;
                  WorkX := 40;
                  WorkY := 24;
                end;
          PlayerTeleporting := 1;
          TeleportAnimationTick := 19;
          PlayerInputLocked := 1;
          if (PlayerRightHeld = 1) or (GameActors[1].ActorSpriteBase = 1) then
            GameActors[1].ActorSpriteBase := 9
          else
            GameActors[1].ActorSpriteBase := 10;
          PlayerUpHeld := 0;
          PlayerDownHeld := 0;
          PlayerLeftHeld := 0;
          PlayerRightHeld := 0;
          PlayerJumping := 0;
        end;
      end;
    $139:
      begin
        PlayerScore := PlayerScore + 250;
        SpawnScorePopup(ProcessPlayerTileConta_ContactX and $FFF0,ProcessPlayerTileConta_ContactY and $FFF0,18);
        StatusBarCameraX := -1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
        PlayerSpeedBoost := 4;
        SpeedBoostTimeLeft := 216;
      end;
    $143..$145:
      begin
        PlayerScore := PlayerScore + 100;
        StatusBarCameraX := -1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].SupportsLanding := 0;
        StartSoundEffect(4);
      end;
    $142:
      begin
        PlayerScore := PlayerScore + 1000;
        StatusBarCameraX := -1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
        SpecialMovementMode := 2;
        SpecialMovementDuration := 432;
      end;
    $31:
      begin
        PlayerScore := PlayerScore + 100;
        StatusBarCameraX := -1;
        Inc(Pickup31Count);
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
      end;
    $13A:
      begin
        PlayerScore := PlayerScore + 5000;
        StatusBarCameraX := -1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
        Inc(PlayerProjectileLimit);
        if PlayerProjectileLimit > 2 then PlayerProjectileLimit := 2;
        ShowGameMessage('Increased Shot Power!');
      end;
    $1D2:
      begin
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(26);
        PlayerControlsReversed := 1;
        PlayerLeftHeld := 0;
        PlayerRightHeld := 0;
        ConfusionTimeLeft := 216;
        ShowGameMessage('YOU FEEL A BIT CONFUSED!');
      end;
    $1D4:
      begin
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(27);
        PlayerSlowMovement := 1;
        SlowMovementTimeLeft := 216;
      end;
    $269:
      begin
        StatusBarCameraX := -1;
        LevelCells[(ProcessPlayerTileConta_ContactX shr 4)+1,(ProcessPlayerTileConta_ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
        Inc(PlayerProgressCount);
      end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Calls u1_6d0e at four inset corners of the 16x16 player footprint. }
procedure CheckPlayerTileContacts;
begin
  ProcessPlayerTileContact(GameActors[1].ActorWorldX + 1, GameActors[1].ActorWorldY);
  ProcessPlayerTileContact(GameActors[1].ActorWorldX + 14, GameActors[1].ActorWorldY);
  ProcessPlayerTileContact(GameActors[1].ActorWorldX + 1, GameActors[1].ActorWorldY + 15);
  ProcessPlayerTileContact(GameActors[1].ActorWorldX + 14, GameActors[1].ActorWorldY + 15);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{ Empty begin/end unit initialization body; no game state is changed. }
begin
end.
