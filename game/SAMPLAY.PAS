{ Gameplay unit: updates actors and projectiles, moves the player and camera,
  and handles collisions, pickups, hazards and level exits. }
unit SAMPLAY;
{$A+}{$D+}{$L+}{$F-}
interface
uses SAMDATA;
function ActorNearViewport(MarginPixels, ActorSlot: Integer): Boolean;
function ShotNearViewport(MarginPixels: Integer; ShotSlot: Word): Boolean;
procedure RequestIslandReturn;
procedure UpdatePlayerMoveSpeed;
procedure DamagePlayerOnContact(ContactX, ContactY: Integer);
function ConsumeShotsAtActor(TargetX, TargetY: Integer): Boolean;
procedure SpawnScorePopup(PopupX, PopupY: Integer; PopupImage: Word);
procedure SpawnEnemyProjectile(SpawnX, SpawnY, Direction, MoveSpeed, ProjectileSprite: Integer);
procedure UpdateBasicActor(ProposedX, ProposedY: Integer; ActorSlot: Word; ScanColumn, ScanRow: Word);
procedure UpdateActorsAndShots;
function PlayerPositionIsClear(MoveOffsetX, MoveOffsetY: Word): Boolean;
procedure ApplyPlayerGravity;
procedure MovePlayerAndCamera;
procedure UpdatePlayerJump;
procedure ProcessPlayerTileContact(ContactX, ContactY: Integer);
procedure CheckPlayerTileContacts;
implementation
uses Dos, PROGRPHX, Crt, SAMSOUND, GAMEJOY, PCXGENUS, TEXT80, SAMUI, SAMLEVEL;

{ Viewport tests, player speed and contact damage. }
{$F+}
{ Checks GameActors[Item] against camera bounds 320x184 enlarged by Distance. }
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
{ Checks PlayerShots[slot] against camera bounds 320x184 enlarged by margin. }
function ShotNearViewport(MarginPixels: Integer; ShotSlot: Word): Boolean;
begin
  if PlayerShots[ShotSlot].ActorWorldX < CameraX - MarginPixels then
  begin
    ShotNearViewport := False;
    Exit;
  end;
  if PlayerShots[ShotSlot].ActorWorldX > CameraX + $0140 + MarginPixels then
  begin
    ShotNearViewport := False;
    Exit;
  end;
  if PlayerShots[ShotSlot].ActorWorldY < CameraY - MarginPixels then
  begin
    ShotNearViewport := False;
    Exit;
  end;
  if PlayerShots[ShotSlot].ActorWorldY > CameraY + $00B8 + MarginPixels then
  begin
    ShotNearViewport := False;
    Exit;
  end;
  ShotNearViewport := True;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Requests a saved-state restore unless god mode is active; the main loop reloads the island map. }
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
  ShotSlot: Integer;
begin
  ConsumeShotsAtActor := False;
  for ShotSlot := 1 to PlayerProjectileLimit do
  begin
    if (PlayerShots[ShotSlot].ActorSlotInactive = 0) and
       (PlayerShots[ShotSlot].ActorWorldX + 7 >= TargetX) and
       (PlayerShots[ShotSlot].ActorWorldX <= TargetX + 6) and
       (PlayerShots[ShotSlot].ActorWorldY + 8 >= TargetY) and
       (PlayerShots[ShotSlot].ActorWorldY <= TargetY + 8) then
    begin
      ConsumeShotsAtActor := True;
      PlayerShots[ShotSlot].ActorRemovalPending := 1;
      RedrawLevelCell(PlayerShots[ShotSlot].ActorWorldX,
      PlayerShots[ShotSlot].ActorWorldY);
      DrawCellForeground(PlayerShots[ShotSlot].ActorWorldX,
      PlayerShots[ShotSlot].ActorWorldY);
      if (TargetX and $000F) > 0 then
      begin
        RedrawLevelCell(PlayerShots[ShotSlot].ActorWorldX - 16,
        PlayerShots[ShotSlot].ActorWorldY);
        RedrawLevelCell(PlayerShots[ShotSlot].ActorWorldX + 16,
        PlayerShots[ShotSlot].ActorWorldY);
        DrawCellForeground(PlayerShots[ShotSlot].ActorWorldX - 16,
        PlayerShots[ShotSlot].ActorWorldY);
        DrawCellForeground(PlayerShots[ShotSlot].ActorWorldX + 16,
        PlayerShots[ShotSlot].ActorWorldY);
      end;
    end;
  end;
end;

{ Actor and projectile allocation. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Allocates a rising kind-5001 actor with sprite param3+150; callers choose images 17..23 for awarded scores. }
procedure SpawnScorePopup(PopupX, PopupY: Integer; PopupImage: Word);
var
  ActorSlot: Word;
  PopupAllocated: String[4];
begin
  ActorSlot := 0;
  PopupAllocated[1] := #0;
  repeat
    Inc(ActorSlot);
    if GameActors[ActorSlot].ActorSlotInactive = 1 then
    begin
      GameActors[ActorSlot].FlashFrames := 0;
      GameActors[ActorSlot].ActorWorldX := PopupX;
      GameActors[ActorSlot].ActorWorldY := PopupY;
      GameActors[ActorSlot].ActorPreviousX := PopupX;
      GameActors[ActorSlot].ActorPreviousY := PopupY;
      GameActors[ActorSlot].DirectionY := 0;
      GameActors[ActorSlot].ActorMovementStep := 0;
      GameActors[ActorSlot].ActorCounterA := 0;
      GameActors[ActorSlot].ActorCounterB := $10;
      GameActors[ActorSlot].ActorSlotInactive := 0;
      GameActors[ActorSlot].ActorRemovalPending := 0;
      GameActors[ActorSlot].ActorKindCode := $1389;
      GameActors[ActorSlot].ActorSpriteBase := PopupImage + $96;
      GameActors[ActorSlot].ActorAnimationCounter := 1;
      GameActors[ActorSlot].ActorMovementStep := 0;
      GameActors[ActorSlot].ActorDirectionX := 1;
      PgBlitMaskedShifted16x16(SpriteBank151^.SpriteEntries[PopupImage].SpriteDataBytes[1],
        GameActors[ActorSlot].ActorWorldX, Word((LongInt(GameActors[ActorSlot].ActorWorldY +
        8) and $fff0) + $10));
      PgBlitMaskedShifted16x16(SpriteBank151^.SpriteEntries[PopupImage].SpriteDataBytes[1],
        GameActors[ActorSlot].ActorWorldX, Word((LongInt(GameActors[ActorSlot].ActorWorldY +
        8) and $fff0) + $1a0));
      PopupAllocated[1] := #1;
    end;
  until (PopupAllocated[1] <> #0) or (ActorSlot = $19);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Allocates an actor projectile/effect, selecting direction, speed, sprite and behavior from EntryId. }
procedure SpawnEnemyProjectile(SpawnX, SpawnY, Direction, MoveSpeed, ProjectileSprite: Integer);
var
  { Unused locals retain the original stack frame. }
  ActorSlot, UnusedSpawnWord1, UnusedSpawnWord2: Integer;
  ProjectileAllocated: Boolean;
begin
  ActorSlot := 0;
  ProjectileAllocated := False;
  repeat
    Inc(ActorSlot);
    if GameActors[ActorSlot].ActorSlotInactive = 1 then
    begin
      StartSoundEffect(3);
      GameActors[ActorSlot].ActorDirectionX := Direction;
      if GameActors[ActorSlot].ActorDirectionX = -1 then
        GameActors[ActorSlot].ActorAnimationCounter := $15
      else
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      GameActors[ActorSlot].DirectionY := 0;
      GameActors[ActorSlot].FlashFrames := 0;
      if ProjectileSprite <> $89 then
        GameActors[ActorSlot].ActorWorldX := SpawnX and $FFF8
      else
        GameActors[ActorSlot].ActorWorldX := SpawnX;
      GameActors[ActorSlot].ActorWorldY := SpawnY;
      GameActors[ActorSlot].ActorPreviousX := SpawnX;
      GameActors[ActorSlot].ActorPreviousY := SpawnY;
      GameActors[ActorSlot].ActorMovementStep := MoveSpeed;
      GameActors[ActorSlot].ActorCounterA := 0;
      GameActors[ActorSlot].ActorCounterB := 0;
      GameActors[ActorSlot].ActorSlotInactive := 0;
      GameActors[ActorSlot].ActorRemovalPending := 0;
      if ProjectileSprite = 0 then
      begin
        GameActors[ActorSlot].ActorSpriteBase := $27;
        GameActors[ActorSlot].ActorKindCode := 7;
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else
      begin
        GameActors[ActorSlot].ActorSpriteBase := ProjectileSprite;
        if (GameActors[ActorSlot].ActorSpriteBase = $1D6) or
           (GameActors[ActorSlot].ActorSpriteBase = $7D) or
           (GameActors[ActorSlot].ActorSpriteBase = $7E) then
        begin
          GameActors[ActorSlot].ActorKindCode := 7;
          GameActors[ActorSlot].ActorAnimationCounter := 1;
        end
        else if (GameActors[ActorSlot].ActorSpriteBase = $339) or
                (GameActors[ActorSlot].ActorSpriteBase = $33B) then
        begin
          GameActors[ActorSlot].ActorKindCode := $13;
          GameActors[ActorSlot].ActorAnimationCounter := 1;
        end
        else if GameActors[ActorSlot].ActorSpriteBase = $72 then
        begin
          GameActors[ActorSlot].ActorKindCode := $25;
          GameActors[ActorSlot].ActorAnimationCounter := 1;
          GameActors[ActorSlot].DirectionY := Direction;
        end
        else if GameActors[ActorSlot].ActorSpriteBase = $C7 then
        begin
          GameActors[ActorSlot].ActorSpriteBase := $72;
          GameActors[ActorSlot].ActorKindCode := $89;
          GameActors[ActorSlot].ActorAnimationCounter := 1;
          GameActors[ActorSlot].DirectionY := Direction;
        end
        else if GameActors[ActorSlot].ActorSpriteBase = $89 then
        begin
          GameActors[ActorSlot].ActorKindCode := $28;
          GameActors[ActorSlot].ActorAnimationCounter := 1;
          GameActors[ActorSlot].ActorCounterB := $1E;
        end
        else
          GameActors[ActorSlot].ActorKindCode := $0E;
      end;
      ProjectileAllocated := True;
    end;
  until ProjectileAllocated or (ActorSlot = 25);
end;

{ Actor behavior and projectile updates. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Dispatches behavior kinds below 30, including walkers, guns, hazards, explosions, pickups. }
procedure UpdateBasicActor(ProposedX, ProposedY: Integer; ActorSlot: Word; ScanColumn, ScanRow: Word);
var
  HorizontalWork, VerticalWork, RightCellColumn, UpperCellRow: Integer;
begin
  case GameActors[ActorSlot].ActorKindCode of
    1:
    begin
      HorizontalWork := (ProposedX shr 4) + 1;
      UpperCellRow := (ProposedY shr 4) + 1;
      VerticalWork := UpperCellRow + 1;
      RightCellColumn := ((ProposedX + 15) shr 4) + 1;
      if LevelCells[HorizontalWork, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[ActorSlot].ActorDirectionX := 1;
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else if LevelCells[RightCellColumn, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[ActorSlot].ActorDirectionX := -1;
        GameActors[ActorSlot].ActorAnimationCounter := 21;
      end
      else if (LevelCells[HorizontalWork, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[HorizontalWork, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[ActorSlot].ActorDirectionX := 1;
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else if (LevelCells[RightCellColumn, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[RightCellColumn, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[ActorSlot].ActorDirectionX := -1;
        GameActors[ActorSlot].ActorAnimationCounter := 21;
      end;
      Inc(GameActors[ActorSlot].ActorAnimationCounter);
      if GameActors[ActorSlot].ActorDirectionX = 1 then
      begin
        if GameActors[ActorSlot].ActorAnimationCounter > 19 then
          GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else
      begin
        if GameActors[ActorSlot].ActorAnimationCounter > 39 then
          GameActors[ActorSlot].ActorAnimationCounter := 21;
      end;
      GameActors[ActorSlot].ActorWorldX := ProposedX;
      DamagePlayerOnContact(GameActors[ActorSlot].ActorWorldX,
      GameActors[ActorSlot].ActorWorldY);
      if ConsumeShotsAtActor(GameActors[ActorSlot].ActorWorldX,
      GameActors[ActorSlot].ActorWorldY) then
      begin
        StartSoundEffect(19);
        PlayerScore := PlayerScore + 100;
        StatusBarCameraX := -1;
        GameActors[ActorSlot].ActorKindCode := 5000;
        GameActors[ActorSlot].ActorSpriteBase := 391;
        GameActors[ActorSlot].ActorAnimationCounter := 1;
        GameActors[ActorSlot].ActorMovementStep := 0;
        PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[6403], GameActors[ActorSlot].ActorWorldX,
        GameActors[ActorSlot].ActorWorldY + 16);
        PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[6403], GameActors[ActorSlot].ActorWorldX,
        GameActors[ActorSlot].ActorWorldY + 416);
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
        GameActors[ActorSlot].ActorDirectionX := 1;
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else if LevelCells[RightCellColumn, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[ActorSlot].ActorDirectionX := -1;
        GameActors[ActorSlot].ActorAnimationCounter := 21;
      end
      else if (LevelCells[HorizontalWork, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[HorizontalWork, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[ActorSlot].ActorDirectionX := 1;
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else if (LevelCells[RightCellColumn, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[RightCellColumn, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[ActorSlot].ActorDirectionX := -1;
        GameActors[ActorSlot].ActorAnimationCounter := 21;
      end;
      Inc(GameActors[ActorSlot].ActorAnimationCounter);
      if GameActors[ActorSlot].ActorDirectionX = 1 then
      begin
        if GameActors[ActorSlot].ActorAnimationCounter > 19 then
          GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else
      begin
        if GameActors[ActorSlot].ActorAnimationCounter > 39 then
          GameActors[ActorSlot].ActorAnimationCounter := 21;
      end;
      GameActors[ActorSlot].ActorWorldX := ProposedX;
      DamagePlayerOnContact(GameActors[ActorSlot].ActorWorldX,
      GameActors[ActorSlot].ActorWorldY);
      if ConsumeShotsAtActor(GameActors[ActorSlot].ActorWorldX,
      GameActors[ActorSlot].ActorWorldY) then
      begin
        StartSoundEffect(8);
        Dec(GameActors[ActorSlot].ActorKindCode);
        GameActors[ActorSlot].FlashFrames := 3;
        GameActors[ActorSlot].ActorSpriteBase := 351;
        GameActors[ActorSlot].ActorMovementStep := 1;
        GameActors[ActorSlot].ActorCounterA := Random(50) + 50;
        GameActors[ActorSlot].ActorCounterB := 0;
        if GameActors[ActorSlot].ActorWorldX < GameActors[1].ActorWorldX then
          GameActors[ActorSlot].ActorDirectionX := 1
        else
          GameActors[ActorSlot].ActorDirectionX := -1;
        if GameActors[ActorSlot].ActorDirectionX = 1 then
          GameActors[ActorSlot].ActorAnimationCounter := 1
        else
          GameActors[ActorSlot].ActorAnimationCounter := 21;
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
        GameActors[ActorSlot].ActorDirectionX := 1;
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else if LevelCells[RightCellColumn, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[ActorSlot].ActorDirectionX := -1;
        GameActors[ActorSlot].ActorAnimationCounter := 21;
      end
      else if (LevelCells[HorizontalWork, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[HorizontalWork, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[ActorSlot].ActorDirectionX := 1;
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else if (LevelCells[RightCellColumn, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[RightCellColumn, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[ActorSlot].ActorDirectionX := -1;
        GameActors[ActorSlot].ActorAnimationCounter := 21;
      end;
      Inc(GameActors[ActorSlot].ActorAnimationCounter);
      if GameActors[ActorSlot].ActorDirectionX = 1 then
      begin
        if GameActors[ActorSlot].ActorAnimationCounter > 19 then
          GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else
      begin
        if GameActors[ActorSlot].ActorAnimationCounter > 39 then
          GameActors[ActorSlot].ActorAnimationCounter := 21;
      end;
      GameActors[ActorSlot].ActorWorldX := ProposedX;
      if ConsumeShotsAtActor(GameActors[ActorSlot].ActorWorldX,
      GameActors[ActorSlot].ActorWorldY) then
      begin
        StartSoundEffect(8);
        Dec(GameActors[ActorSlot].ActorKindCode);
        GameActors[ActorSlot].ActorSpriteBase := 359;
        GameActors[ActorSlot].FlashFrames := 3;
        GameActors[ActorSlot].ActorMovementStep := 2;
        if GameActors[ActorSlot].ActorWorldX < GameActors[1].ActorWorldX then
          GameActors[ActorSlot].ActorDirectionX := 1
        else
          GameActors[ActorSlot].ActorDirectionX := -1;
        if GameActors[ActorSlot].ActorDirectionX = 1 then
          GameActors[ActorSlot].ActorAnimationCounter := 1
        else
          GameActors[ActorSlot].ActorAnimationCounter := 21;
      end
      else
        DamagePlayerOnContact(GameActors[ActorSlot].ActorWorldX,
        GameActors[ActorSlot].ActorWorldY);
    end;
    4:
    begin
      HorizontalWork := (ProposedX shr 4) + 1;
      UpperCellRow := (ProposedY shr 4) + 1;
      VerticalWork := UpperCellRow + 1;
      RightCellColumn := ((ProposedX + 15) shr 4) + 1;
      if LevelCells[HorizontalWork, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[ActorSlot].ActorDirectionX := 1;
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else if LevelCells[RightCellColumn, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[ActorSlot].ActorDirectionX := -1;
        GameActors[ActorSlot].ActorAnimationCounter := 21;
      end
      else if (LevelCells[HorizontalWork, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[HorizontalWork, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[ActorSlot].ActorDirectionX := 1;
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else if (LevelCells[RightCellColumn, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[RightCellColumn, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[ActorSlot].ActorDirectionX := -1;
        GameActors[ActorSlot].ActorAnimationCounter := 21;
      end;
      Inc(GameActors[ActorSlot].ActorAnimationCounter);
      if GameActors[ActorSlot].ActorDirectionX = 1 then
      begin
        if GameActors[ActorSlot].ActorAnimationCounter > 19 then
          GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else
      begin
        if GameActors[ActorSlot].ActorAnimationCounter > 39 then
          GameActors[ActorSlot].ActorAnimationCounter := 21;
      end;
      Inc(GameActors[ActorSlot].ActorCounterB);
      if GameActors[ActorSlot].ActorCounterB >= GameActors[ActorSlot].ActorCounterA then
      begin
        if (GameActors[ActorSlot].ActorWorldY shr 4) = ((GameActors[1].ActorWorldY + 8) shr 4) then
        begin
          if ((GameActors[ActorSlot].ActorWorldX < GameActors[1].ActorWorldX) and
          (GameActors[ActorSlot].ActorDirectionX = 1)) or
             ((GameActors[ActorSlot].ActorWorldX > GameActors[1].ActorWorldX) and
             (GameActors[ActorSlot].ActorDirectionX = -1)) then
          begin
            GameActors[ActorSlot].ActorCounterB := 0;
            SpawnEnemyProjectile(GameActors[ActorSlot].ActorWorldX,
            GameActors[ActorSlot].ActorWorldY, GameActors[ActorSlot].ActorDirectionX, 4, 0);
          end;
        end;
      end;
      GameActors[ActorSlot].ActorWorldX := ProposedX;
      DamagePlayerOnContact(GameActors[ActorSlot].ActorWorldX,
      GameActors[ActorSlot].ActorWorldY);
      if ConsumeShotsAtActor(GameActors[ActorSlot].ActorWorldX,
      GameActors[ActorSlot].ActorWorldY) then
      begin
        StartSoundEffect(8);
        Dec(GameActors[ActorSlot].ActorKindCode);
        GameActors[ActorSlot].ActorSpriteBase := 367;
        GameActors[ActorSlot].FlashFrames := 3;
        GameActors[ActorSlot].ActorMovementStep := 3;
        if GameActors[ActorSlot].ActorWorldX < GameActors[1].ActorWorldX then
          GameActors[ActorSlot].ActorDirectionX := 1
        else
          GameActors[ActorSlot].ActorDirectionX := -1;
        if GameActors[ActorSlot].ActorDirectionX = 1 then
          GameActors[ActorSlot].ActorAnimationCounter := 1
        else
          GameActors[ActorSlot].ActorAnimationCounter := 21;
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
        GameActors[ActorSlot].ActorDirectionX := 1;
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else if LevelCells[RightCellColumn, UpperCellRow].CellSolidFlag <> 0 then
      begin
        GameActors[ActorSlot].ActorDirectionX := -1;
        GameActors[ActorSlot].ActorAnimationCounter := 21;
      end
      else if (LevelCells[HorizontalWork, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[HorizontalWork, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[ActorSlot].ActorDirectionX := 1;
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else if (LevelCells[RightCellColumn, VerticalWork].CellSolidFlag = 0) and
              (LevelCells[RightCellColumn, VerticalWork].SupportsLanding = 0) then
      begin
        GameActors[ActorSlot].ActorDirectionX := -1;
        GameActors[ActorSlot].ActorAnimationCounter := 21;
      end;
      Inc(GameActors[ActorSlot].ActorAnimationCounter);
      if GameActors[ActorSlot].ActorDirectionX = 1 then
      begin
        if GameActors[ActorSlot].ActorAnimationCounter > 19 then
          GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else
      begin
        if GameActors[ActorSlot].ActorAnimationCounter > 39 then
          GameActors[ActorSlot].ActorAnimationCounter := 21;
      end;
      Inc(GameActors[ActorSlot].ActorCounterB);
      if GameActors[ActorSlot].ActorCounterB >= GameActors[ActorSlot].ActorCounterA then
      begin
        if (GameActors[ActorSlot].ActorWorldY shr 4) = ((GameActors[1].ActorWorldY + 8) shr 4) then
        begin
          if ((GameActors[ActorSlot].ActorWorldX < GameActors[1].ActorWorldX) and
          (GameActors[ActorSlot].ActorDirectionX = 1)) or
             ((GameActors[ActorSlot].ActorWorldX > GameActors[1].ActorWorldX) and
             (GameActors[ActorSlot].ActorDirectionX = -1)) then
          begin
            GameActors[ActorSlot].ActorCounterB := 0;
            SpawnEnemyProjectile(GameActors[ActorSlot].ActorWorldX,
            GameActors[ActorSlot].ActorWorldY, GameActors[ActorSlot].ActorDirectionX, 4, 0);
          end;
        end;
      end;
      GameActors[ActorSlot].ActorWorldX := ProposedX;
      DamagePlayerOnContact(GameActors[ActorSlot].ActorWorldX,
      GameActors[ActorSlot].ActorWorldY);
      if ConsumeShotsAtActor(GameActors[ActorSlot].ActorWorldX,
      GameActors[ActorSlot].ActorWorldY) then
      begin
        StartSoundEffect(8);
        Dec(GameActors[ActorSlot].ActorKindCode);
        GameActors[ActorSlot].ActorSpriteBase := 375;
        GameActors[ActorSlot].FlashFrames := 3;
        if GameActors[ActorSlot].ActorWorldX < GameActors[1].ActorWorldX then
          GameActors[ActorSlot].ActorDirectionX := 1
        else
          GameActors[ActorSlot].ActorDirectionX := -1;
        if GameActors[ActorSlot].ActorDirectionX = 1 then
          GameActors[ActorSlot].ActorAnimationCounter := 1
        else
          GameActors[ActorSlot].ActorAnimationCounter := 21;
      end;
    end;
    6:
    begin
      if (LevelCells[(ProposedX shr 4) + 1, (ProposedY shr 4) + 1].CellSolidFlag <> 0) or
         (LevelCells[((ProposedX + 15) shr 4) + 1, (ProposedY shr 4) + 1].CellSolidFlag <> 0) then
        GameActors[ActorSlot].ActorDirectionX := -GameActors[ActorSlot].ActorDirectionX;
      Inc(GameActors[ActorSlot].ActorAnimationCounter);
      if GameActors[ActorSlot].ActorAnimationCounter > 19 then
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      GameActors[ActorSlot].ActorWorldX := ProposedX;
      DamagePlayerOnContact(GameActors[ActorSlot].ActorWorldX,
      GameActors[ActorSlot].ActorWorldY);
      if GameActors[ActorSlot].ActorSpriteBase = 625 then
      begin
        Dec(GameActors[ActorSlot].ActorCounterB);
        if GameActors[ActorSlot].ActorCounterB <= 0 then
        begin
          GameActors[ActorSlot].ActorRemovalPending := 1;
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
        if ConsumeShotsAtActor(GameActors[ActorSlot].ActorWorldX,
        GameActors[ActorSlot].ActorWorldY) then
        begin
          StartSoundEffect(8);
          Dec(GameActors[ActorSlot].ActorCounterA);
          GameActors[ActorSlot].FlashFrames := 3;
          if GameActors[ActorSlot].ActorCounterA <= 0 then
          begin
            GameActors[ActorSlot].ActorSpriteBase := 625;
            GameActors[ActorSlot].ActorAnimationCounter := 1;
            GameActors[ActorSlot].ActorMovementStep := 1;
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
        GameActors[ActorSlot].ActorRemovalPending := 1;
        RedrawLevelCell(ProposedX, ProposedY);
        RedrawLevelCell(ProposedX - 16, ProposedY);
        RedrawLevelCell(ProposedX + 16, ProposedY);
        DrawCellForeground(ProposedX, ProposedY);
        DrawCellForeground(ProposedX - 16, ProposedY);
        DrawCellForeground(ProposedX + 16, ProposedY);
      end
      else
      begin
        GameActors[ActorSlot].ActorWorldX := ProposedX;
        HorizontalWork := GameActors[1].ActorWorldX - GameActors[ActorSlot].ActorWorldX;
        VerticalWork := GameActors[1].ActorWorldY - GameActors[ActorSlot].ActorWorldY;
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
      Inc(GameActors[ActorSlot].ActorCounterB);
      if GameActors[ActorSlot].ActorCounterB >= GameActors[ActorSlot].ActorCounterA then
      begin
        if (GameActors[ActorSlot].ActorWorldY and $FFF0) = ((GameActors[1].ActorWorldY + 8) and $FFF0) then
        begin
          if GameActors[ActorSlot].ActorWorldX < GameActors[1].ActorWorldX then
          begin
            GameActors[ActorSlot].ActorCounterB := 0;
            if GameActors[ActorSlot].ActorKindCode = 10 then
              SpawnEnemyProjectile(GameActors[ActorSlot].ActorWorldX + 8,
              GameActors[ActorSlot].ActorWorldY, 1, 4, 470)
            else
              SpawnEnemyProjectile(GameActors[ActorSlot].ActorWorldX + 16,
              GameActors[ActorSlot].ActorWorldY, 1, 4, 488);
          end;
        end;
      end;
    end;
    11, 13:
    begin
      Inc(GameActors[ActorSlot].ActorCounterB);
      if GameActors[ActorSlot].ActorCounterB >= GameActors[ActorSlot].ActorCounterA then
      begin
        if (GameActors[ActorSlot].ActorWorldY and $FFF0) = ((GameActors[1].ActorWorldY + 8) and $FFF0) then
        begin
          if GameActors[ActorSlot].ActorWorldX > GameActors[1].ActorWorldX then
          begin
            GameActors[ActorSlot].ActorCounterB := 0;
            if GameActors[ActorSlot].ActorKindCode = 11 then
              SpawnEnemyProjectile(GameActors[ActorSlot].ActorWorldX - 8,
              GameActors[ActorSlot].ActorWorldY, -1, 4, 470)
            else
              SpawnEnemyProjectile(GameActors[ActorSlot].ActorWorldX - 16,
              GameActors[ActorSlot].ActorWorldY, -1, 4, 492);
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
        GameActors[ActorSlot].ActorRemovalPending := 1;
        RedrawLevelCell(ProposedX, ProposedY);
        RedrawLevelCell(ProposedX - 16, ProposedY);
        RedrawLevelCell(ProposedX + 16, ProposedY);
        DrawCellForeground(ProposedX, ProposedY);
        DrawCellForeground(ProposedX - 16, ProposedY);
        DrawCellForeground(ProposedX + 16, ProposedY);
      end
      else
      begin
        Inc(GameActors[ActorSlot].ActorAnimationCounter);
      if GameActors[ActorSlot].ActorDirectionX = 1 then
      begin
        if GameActors[ActorSlot].ActorAnimationCounter > 19 then
          GameActors[ActorSlot].ActorAnimationCounter := 1;
      end
      else
      begin
        if GameActors[ActorSlot].ActorAnimationCounter > 39 then
          GameActors[ActorSlot].ActorAnimationCounter := 21;
      end;
        GameActors[ActorSlot].ActorWorldX := ProposedX;
        DamagePlayerOnContact(GameActors[ActorSlot].ActorWorldX,
        GameActors[ActorSlot].ActorWorldY);
      end;
    end;
    15:
    begin
      Inc(GameActors[ActorSlot].ActorCounterB);
      if GameActors[ActorSlot].ActorCounterB >= GameActors[ActorSlot].ActorCounterA then
      begin
        GameActors[ActorSlot].ActorSpriteBase := ((GameActors[ActorSlot].ActorCounterB -
        GameActors[ActorSlot].ActorCounterA) shr 2) + 429;
        if GameActors[ActorSlot].ActorCounterB = 45 then
        begin
          GameActors[ActorSlot].ActorCounterB := 0;
          GameActors[ActorSlot].ActorSpriteBase := 435;
        end;
        DamagePlayerOnContact(GameActors[ActorSlot].ActorWorldX,
        GameActors[ActorSlot].ActorWorldY);
      end;
    end;
    16:
    begin
      Inc(GameActors[ActorSlot].ActorCounterB);
      if GameActors[ActorSlot].ActorCounterB >= GameActors[ActorSlot].ActorCounterA then
      begin
        GameActors[ActorSlot].ActorSpriteBase := ((GameActors[ActorSlot].ActorCounterB -
        GameActors[ActorSlot].ActorCounterA) shr 2) + 437;
        if GameActors[ActorSlot].ActorCounterB = 45 then
        begin
          GameActors[ActorSlot].ActorCounterB := 0;
          GameActors[ActorSlot].ActorSpriteBase := 435;
        end;
        DamagePlayerOnContact(GameActors[ActorSlot].ActorWorldX,
        GameActors[ActorSlot].ActorWorldY);
      end;
    end;
    17:
    begin
      Inc(GameActors[ActorSlot].ActorCounterB);
      HorizontalWork := GameActors[ActorSlot].ActorCounterB -
      GameActors[ActorSlot].ActorCounterA;
      if HorizontalWork >= 0 then
      begin
        GameActors[ActorSlot].ActorSpriteBase := (HorizontalWork shr 2) + 471;
        if GameActors[ActorSlot].ActorCounterB = 60 then
        begin
          GameActors[ActorSlot].ActorCounterB := 0;
          GameActors[ActorSlot].ActorSpriteBase := 435;
        end;
        DamagePlayerOnContact(GameActors[ActorSlot].ActorWorldX,
        GameActors[ActorSlot].ActorWorldY + 8);
      end;
    end;
    18:
    begin
      Inc(GameActors[ActorSlot].ActorCounterB);
      HorizontalWork := GameActors[ActorSlot].ActorCounterB -
      GameActors[ActorSlot].ActorCounterA;
      if HorizontalWork >= 0 then
      begin
        GameActors[ActorSlot].ActorSpriteBase := (HorizontalWork shr 2) + 479;
        if GameActors[ActorSlot].ActorCounterB = 60 then
        begin
          GameActors[ActorSlot].ActorCounterB := 0;
          GameActors[ActorSlot].ActorSpriteBase := 435;
        end;
        DamagePlayerOnContact(GameActors[ActorSlot].ActorWorldX,
        GameActors[ActorSlot].ActorWorldY - 8);
      end;
    end;
    19:
    begin
      VerticalWork := (ProposedY shr 4) + 1;
      if (LevelCells[(ProposedX shr 4) + 1, VerticalWork].CellSolidFlag <> 0) or
         (LevelCells[((ProposedX + 15) shr 4) + 1, VerticalWork].CellSolidFlag <> 0) then
      begin
        GameActors[ActorSlot].ActorRemovalPending := 1;
        RedrawLevelCell(ProposedX, ProposedY);
        RedrawLevelCell(ProposedX - 16, ProposedY);
        RedrawLevelCell(ProposedX + 16, ProposedY);
        DrawCellForeground(ProposedX, ProposedY);
        DrawCellForeground(ProposedX - 16, ProposedY);
        DrawCellForeground(ProposedX + 16, ProposedY);
      end
      else
      begin
        Inc(GameActors[ActorSlot].ActorAnimationCounter);
        if GameActors[ActorSlot].ActorAnimationCounter > 9 then
          GameActors[ActorSlot].ActorAnimationCounter := 1;
        GameActors[ActorSlot].ActorWorldX := ProposedX;
        DamagePlayerOnContact(GameActors[ActorSlot].ActorWorldX,
        GameActors[ActorSlot].ActorWorldY);
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
        GameActors[ActorSlot].ActorDirectionX := -GameActors[ActorSlot].ActorDirectionX;
      Inc(GameActors[ActorSlot].ActorAnimationCounter);
      if GameActors[ActorSlot].ActorAnimationCounter > 19 then
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      GameActors[ActorSlot].ActorWorldX := ProposedX;
      DamagePlayerOnContact(GameActors[ActorSlot].ActorWorldX,
      GameActors[ActorSlot].ActorWorldY);
    end;
    21:
    begin
      if LevelCells[((ProposedX + 8) shr 4) + 1 + GameActors[ActorSlot].ActorDirectionX,
                ((ProposedY + 8) shr 4) + 1].CellSolidFlag <> 0 then
      begin
        GameActors[ActorSlot].ActorDirectionX := -GameActors[ActorSlot].ActorDirectionX;
        if GameActors[ActorSlot].ActorDirectionX = 1 then
          GameActors[ActorSlot].ActorSpriteBase := 497
        else
          GameActors[ActorSlot].ActorSpriteBase := 495;
      end;
      Inc(GameActors[ActorSlot].ActorAnimationCounter);
      if GameActors[ActorSlot].ActorAnimationCounter > 9 then
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      GameActors[ActorSlot].ActorWorldX := ProposedX;
      DamagePlayerOnContact(GameActors[ActorSlot].ActorWorldX,
      GameActors[ActorSlot].ActorWorldY);
    end;
    22:
    begin
      Inc(GameActors[ActorSlot].ActorAnimationCounter);
      Inc(GameActors[ActorSlot].ActorCounterB);
      if (GameActors[ActorSlot].ActorCounterB = GameActors[ActorSlot].ActorCounterA) and
         (GameActors[ActorSlot].ActorSpriteBase = 635) then
      begin
        GameActors[ActorSlot].ActorAnimationCounter := 1;
        GameActors[ActorSlot].ActorSpriteBase := 625;
        GameActors[ActorSlot].ActorCounterB := GameActors[ActorSlot].ActorCounterB - 10;
      end
      else if GameActors[ActorSlot].ActorCounterB = GameActors[ActorSlot].ActorCounterA then
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
        DamagePlayerOnContact(GameActors[ActorSlot].ActorWorldX,
        GameActors[ActorSlot].ActorWorldY);
      end;
      if GameActors[ActorSlot].ActorSpriteBase = 625 then
      begin
        if GameActors[ActorSlot].ActorAnimationCounter > 11 then
        begin
          GameActors[ActorSlot].ActorRemovalPending := 1;
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
        if GameActors[ActorSlot].ActorAnimationCounter > 9 then
          GameActors[ActorSlot].ActorAnimationCounter := 1;
      end;
    end;
    23:
    begin
      Inc(GameActors[ActorSlot].ActorAnimationCounter);
      if GameActors[ActorSlot].ActorAnimationCounter = 11 then
        DamagePlayerOnContact(GameActors[ActorSlot].ActorWorldX,
        GameActors[ActorSlot].ActorWorldY);
      if GameActors[ActorSlot].ActorSpriteBase = 625 then
      begin
        if GameActors[ActorSlot].ActorAnimationCounter > 11 then
        begin
          GameActors[ActorSlot].ActorRemovalPending := 1;
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
        if GameActors[ActorSlot].ActorAnimationCounter > 9 then
          GameActors[ActorSlot].ActorAnimationCounter := 1;
      end;
    end;
    25:
    begin
      Inc(GameActors[ActorSlot].ActorCounterB);
      if GameActors[ActorSlot].ActorCounterB = GameActors[ActorSlot].ActorCounterA then
      begin
        GameActors[ActorSlot].ActorCounterB := 0;
        GameActors[ActorSlot].ActorDirectionX := -GameActors[ActorSlot].ActorDirectionX;
      end;
      Inc(GameActors[ActorSlot].ActorAnimationCounter);
      if GameActors[ActorSlot].ActorAnimationCounter > 19 then
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      GameActors[ActorSlot].ActorWorldX := ProposedX;
      if ConsumeShotsAtActor(GameActors[ActorSlot].ActorWorldX,
      GameActors[ActorSlot].ActorWorldY) then
      begin
        StartSoundEffect(8);
        GameActors[ActorSlot].ActorRemovalPending := 0;
        PlayerScore := PlayerScore + 100;
        StatusBarCameraX := -1;
        GameActors[ActorSlot].ActorKindCode := 5000;
        GameActors[ActorSlot].ActorSpriteBase := 391;
        GameActors[ActorSlot].ActorAnimationCounter := 1;
        GameActors[ActorSlot].ActorMovementStep := 0;
        PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[6403], GameActors[ActorSlot].ActorWorldX,
        GameActors[ActorSlot].ActorWorldY + 16);
        PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[6403], GameActors[ActorSlot].ActorWorldX,
        GameActors[ActorSlot].ActorWorldY + 416);
      end;
    end;
    26:
    begin
      Inc(GameActors[ActorSlot].ActorAnimationCounter);
      if GameActors[ActorSlot].ActorAnimationCounter > 19 then
        GameActors[ActorSlot].ActorAnimationCounter := 1;
      if ((GameActors[ActorSlot].ActorWorldX <= GameActors[1].ActorWorldX) and
          (GameActors[ActorSlot].ActorWorldX + 9 >= GameActors[1].ActorWorldX)) or
         ((GameActors[1].ActorWorldX + 9 >= GameActors[ActorSlot].ActorWorldX) and
          (GameActors[ActorSlot].ActorWorldX >= GameActors[1].ActorWorldX)) then
      begin
        if ((GameActors[ActorSlot].ActorWorldY <= GameActors[1].ActorWorldY) and
            (GameActors[ActorSlot].ActorWorldY + 15 >= GameActors[1].ActorWorldY)) or
           ((GameActors[1].ActorWorldY + 15 >= GameActors[ActorSlot].ActorWorldY) and
            (GameActors[ActorSlot].ActorWorldY >= GameActors[1].ActorWorldY)) then
        begin
          StartSoundEffect(5);
          PlayerScore := PlayerScore + 10000;
          StatusBarCameraX := -1;
          GameActors[ActorSlot].ActorKindCode := 5001;
          GameActors[ActorSlot].ActorCounterB := 16;
          GameActors[ActorSlot].ActorSpriteBase := 173;
          GameActors[ActorSlot].ActorAnimationCounter := 1;
          GameActors[ActorSlot].ActorMovementStep := 0;
          PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3523], GameActors[ActorSlot].ActorWorldX,
          GameActors[ActorSlot].ActorWorldY + 16);
          PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3523], GameActors[ActorSlot].ActorWorldX,
          GameActors[ActorSlot].ActorWorldY + 416);
        end;
      end;
    end;
    27:
    begin
      HorizontalWork := ((GameActors[ActorSlot].ActorWorldX + 3) shr 4) + 1;
      RightCellColumn := ((GameActors[ActorSlot].ActorWorldX + 13) shr 4) + 1;
      VerticalWork := (GameActors[ActorSlot].ActorWorldY shr 4) + 2;
      if (LevelCells[HorizontalWork, VerticalWork].CellSolidFlag = 0) and (LevelCells[RightCellColumn,
      VerticalWork].CellSolidFlag = 0) and
         (LevelCells[HorizontalWork, VerticalWork].SupportsLanding = 0) and (LevelCells[RightCellColumn,
         VerticalWork].SupportsLanding = 0) then
      begin
        RedrawLevelCell(GameActors[ActorSlot].ActorWorldX,
        GameActors[ActorSlot].ActorWorldY);
        RedrawLevelCell(GameActors[ActorSlot].ActorWorldX, GameActors[ActorSlot].ActorWorldY
        - 16);
        RedrawLevelCell(GameActors[ActorSlot].ActorWorldX + 16,
        GameActors[ActorSlot].ActorWorldY);
        RedrawLevelCell(GameActors[ActorSlot].ActorWorldX + 16,
        GameActors[ActorSlot].ActorWorldY - 16);
        RedrawLevelCell(GameActors[ActorSlot].ActorWorldX, GameActors[ActorSlot].ActorWorldY
        + 8);
        RedrawLevelCell(GameActors[ActorSlot].ActorWorldX + 16,
        GameActors[ActorSlot].ActorWorldY + 8);
        GameActors[ActorSlot].ActorWorldY := GameActors[ActorSlot].ActorWorldY + 8;
        GameActors[ActorSlot].ActorKindValue1 := -1;
        PlayerOnMovingSupport := 0;
      end
      else
      begin
        GameActors[ActorSlot].DirectionY := 0;
        GameActors[ActorSlot].ActorWorldY := GameActors[ActorSlot].ActorWorldY and $FFF0;
        if GameActors[ActorSlot].ActorKindValue1 = -1 then
        begin
          StartSoundEffect(29);
          GameActors[ActorSlot].ActorKindValue1 := 0;
        end;
      end;
      if ((GameActors[ActorSlot].ActorWorldX <= GameActors[1].ActorWorldX) and
          (GameActors[ActorSlot].ActorWorldX + 9 >= GameActors[1].ActorWorldX)) or
         ((GameActors[1].ActorWorldX + 9 >= GameActors[ActorSlot].ActorWorldX) and
          (GameActors[ActorSlot].ActorWorldX >= GameActors[1].ActorWorldX)) then
      begin
        if GameActors[ActorSlot].ActorWorldY = GameActors[1].ActorWorldY then
        begin
          if GameActors[ActorSlot].ActorWorldX < GameActors[1].ActorWorldX then
          begin
            if LevelCells[((GameActors[ActorSlot].ActorWorldX - 3) shr 4) + 1,
                      (GameActors[ActorSlot].ActorWorldY shr 4) + 1].CellSolidFlag = 0 then
              GameActors[ActorSlot].ActorWorldX := GameActors[1].ActorWorldX - 13;
          end
          else if GameActors[ActorSlot].ActorWorldX > GameActors[1].ActorWorldX then
          begin
            if LevelCells[((GameActors[ActorSlot].ActorWorldX + 3) shr 4) + 2,
                      (GameActors[ActorSlot].ActorWorldY shr 4) + 1].CellSolidFlag = 0 then
              GameActors[ActorSlot].ActorWorldX := GameActors[1].ActorWorldX + 13;
          end;
        end
        else
        begin
          if (GameActors[1].ActorWorldY + 16 >= GameActors[ActorSlot].ActorWorldY) and
             (GameActors[ActorSlot].ActorWorldY >= GameActors[1].ActorWorldY) then
          begin
            if PlayerJumping = 0 then
            begin
              GameActors[1].ActorWorldY := GameActors[ActorSlot].ActorWorldY - 16;
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
        GameActors[ActorSlot].ActorDirectionX := -GameActors[ActorSlot].ActorDirectionX;
      if ((GameActors[ActorSlot].ActorWorldX <= GameActors[1].ActorWorldX) and
          (GameActors[ActorSlot].ActorWorldX + 9 >= GameActors[1].ActorWorldX)) or
         ((GameActors[1].ActorWorldX + 9 >= GameActors[ActorSlot].ActorWorldX) and
          (GameActors[ActorSlot].ActorWorldX >= GameActors[1].ActorWorldX)) then
      begin
        if (GameActors[1].ActorWorldY + 16 >= GameActors[ActorSlot].ActorWorldY) and
           (GameActors[ActorSlot].ActorWorldY > GameActors[1].ActorWorldY) then
        begin
          if PlayerJumping = 0 then
          begin
            GameActors[1].ActorWorldY := GameActors[ActorSlot].ActorWorldY - 16;
            PlayerJumping := 0;
            PlayerFalling := 0;
            PlayerOnMovingSupport := 1;
            if GameActors[1].ActorSpriteBase = 13 then
              GameActors[1].ActorSpriteBase := 9
            else if GameActors[1].ActorSpriteBase = 14 then
              GameActors[1].ActorSpriteBase := 10;
            if GameActors[ActorSlot].ActorDirectionX = 1 then
              GameActors[1].ActorWorldX := GameActors[ActorSlot].ActorMovementStep +
              GameActors[1].ActorWorldX
            else if GameActors[ActorSlot].ActorDirectionX = -1 then
              GameActors[1].ActorWorldX := GameActors[1].ActorWorldX -
              GameActors[ActorSlot].ActorMovementStep;
            if CameraX < 320 then
            begin
              if CameraX + 170 < GameActors[1].ActorWorldX then
              begin
                Inc(CameraX, GameActors[ActorSlot].ActorMovementStep);
                if CameraX > 320 then
                  CameraX := 320;
              end;
            end;
            if CameraX > 0 then
            begin
              if CameraX + 150 > GameActors[1].ActorWorldX then
              begin
                Dec(CameraX, GameActors[ActorSlot].ActorMovementStep);
                if CameraX < 0 then
                  CameraX := 0;
              end;
            end;
          end;
        end;
      end;
      if GameActors[ActorSlot].ActorDirectionX = 1 then
        GameActors[ActorSlot].ActorWorldX := GameActors[ActorSlot].ActorWorldX +
        GameActors[ActorSlot].ActorMovementStep
      else if GameActors[ActorSlot].ActorDirectionX = -1 then
        GameActors[ActorSlot].ActorWorldX := GameActors[ActorSlot].ActorWorldX -
        GameActors[ActorSlot].ActorMovementStep;
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Iterates live actors, delegates kinds<30, handles larger behavior kinds. }
procedure UpdateActorsAndShots;
var
  { Unused locals retain the original stack frame. }
  ProposedX, VerticalWork, EntitySlot, UnusedScanSeedX, UnusedScanSeedY,
  HorizontalWork, VerticalWork2, RightCellColumn, UpperCellRow: Integer;
begin
  for EntitySlot := 2 to 25 do
    if GameActors[EntitySlot].ActorSlotInactive = 0 then
      if ActorNearViewport(32, EntitySlot) or (GameActors[EntitySlot].ActorKindCode = 28) or
         (GameActors[EntitySlot].ActorKindCode = 21) or (GameActors[EntitySlot].ActorKindCode = 14) then
      begin
         if GameActors[EntitySlot].ActorDirectionX = 1 then
        begin
           ProposedX := (GameActors[EntitySlot].ActorWorldX +
          GameActors[EntitySlot].ActorMovementStep);
        end
        else
        begin
           if GameActors[EntitySlot].ActorDirectionX = -1 then
          begin
             ProposedX := (GameActors[EntitySlot].ActorWorldX -
            GameActors[EntitySlot].ActorMovementStep);
          end
          else
          begin
             ProposedX := GameActors[EntitySlot].ActorWorldX;
          end;
        end;
         if GameActors[EntitySlot].DirectionY = 1 then
        begin
           VerticalWork := (GameActors[EntitySlot].ActorWorldY +
          GameActors[EntitySlot].ActorMovementStep);
        end
        else
        begin
           if GameActors[EntitySlot].DirectionY = -1 then
          begin
             VerticalWork := (GameActors[EntitySlot].ActorWorldY -
            GameActors[EntitySlot].ActorMovementStep);
          end
          else
          begin
             VerticalWork := GameActors[EntitySlot].ActorWorldY;
          end;
        end;
         GameActors[EntitySlot].ActorPreviousX := GameActors[EntitySlot].ActorWorldX;
         GameActors[EntitySlot].ActorPreviousY := GameActors[EntitySlot].ActorWorldY;
         if GameActors[EntitySlot].ActorKindCode < 30 then
        begin
           UpdateBasicActor(ProposedX, VerticalWork, EntitySlot,
          UnusedScanSeedX, UnusedScanSeedY);
        end
        else
        begin
          case GameActors[EntitySlot].ActorKindCode of
            5000: begin
               if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY) then
              begin
                 StartSoundEffect(20);
                 PlayerScore := (PlayerScore + 100);
                 StatusBarCameraX := -1;
                 GameActors[EntitySlot].ActorKindCode := 5001;
                 GameActors[EntitySlot].ActorCounterB := 16;
                 GameActors[EntitySlot].ActorSpriteBase := 167;
                 GameActors[EntitySlot].ActorAnimationCounter := 1;
                 GameActors[EntitySlot].ActorMovementStep := 0;
                 PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[2563], GameActors[EntitySlot].ActorWorldX,
                (GameActors[EntitySlot].ActorWorldY + 16));
                 PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[2563], GameActors[EntitySlot].ActorWorldX,
                (GameActors[EntitySlot].ActorWorldY + 416));
              end
              else
              begin
                 if ((((GameActors[1].ActorWorldX + 3) >= (GameActors[EntitySlot].ActorWorldX + 3)) and
                ((GameActors[1].ActorWorldX + 3) <= (GameActors[EntitySlot].ActorWorldX +
                    12))) or (((GameActors[1].ActorWorldX + 12) >= (GameActors[EntitySlot].ActorWorldX + 3)) and
                    ((GameActors[1].ActorWorldX + 12) <=
                    (GameActors[EntitySlot].ActorWorldX + 12)))) and (((GameActors[EntitySlot].ActorWorldY <=
                    GameActors[1].ActorWorldY) and ((GameActors[EntitySlot].ActorWorldY + 15) >=
                    GameActors[1].ActorWorldY)) or (((GameActors[1].ActorWorldY + 15) >= GameActors[EntitySlot].ActorWorldY)
                    and ((GameActors[1].ActorWorldY + 15) <=
                    (GameActors[EntitySlot].ActorWorldY + 15)))) then
                begin
                   StartSoundEffect(4);
                   PlayerScore := (PlayerScore + 1000);
                   StatusBarCameraX := -1;
                   GameActors[EntitySlot].ActorKindCode := 5001;
                   GameActors[EntitySlot].ActorCounterB := 16;
                   GameActors[EntitySlot].ActorSpriteBase := 170;
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                   GameActors[EntitySlot].ActorMovementStep := 0;
                   PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3203], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 16));
                   PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3203], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 416));
                end;
              end;
            end;
            5001: begin
               GameActors[EntitySlot].ActorPreviousX := ProposedX;
               GameActors[EntitySlot].ActorPreviousY := VerticalWork;
               Dec(GameActors[EntitySlot].ActorWorldY, 2);
               if GameActors[EntitySlot].ActorWorldY < 16 then
              begin
                 VerticalWork := 16;
                 GameActors[EntitySlot].ActorWorldY := 16;
                 GameActors[EntitySlot].ActorPreviousY := 16;
              end;
               Dec(GameActors[EntitySlot].ActorCounterB);
               if GameActors[EntitySlot].ActorCounterB <= 0 then
              begin
                 GameActors[EntitySlot].ActorRemovalPending := 1;
                 RedrawLevelCell(ProposedX, VerticalWork);
                 RedrawLevelCell(ProposedX, (VerticalWork - 16));
                 RedrawLevelCell(ProposedX, (VerticalWork + 16));
                 DrawCellForeground(ProposedX, VerticalWork);
                 DrawCellForeground(ProposedX, (VerticalWork + 16));
                 DrawCellForeground(ProposedX, (VerticalWork - 16));
                 RedrawLevelCell((ProposedX + 16), VerticalWork);
                 RedrawLevelCell((ProposedX + 16), (VerticalWork + 16));
                 RedrawLevelCell((ProposedX + 16), (VerticalWork - 16));
                 DrawCellForeground((ProposedX + 16), VerticalWork);
                 DrawCellForeground((ProposedX + 16), (VerticalWork + 16));
                 DrawCellForeground((ProposedX + 16), (VerticalWork - 16));
              end
              else
              begin
                 RedrawLevelCell(ProposedX, VerticalWork);
                 RedrawLevelCell(ProposedX, (VerticalWork + 16));
                 DrawCellForeground(ProposedX, VerticalWork);
                 DrawCellForeground(ProposedX, (VerticalWork + 16));
                 RedrawLevelCell((ProposedX + 16), VerticalWork);
                 RedrawLevelCell((ProposedX + 16), (VerticalWork + 16));
                 DrawCellForeground((ProposedX + 16), VerticalWork);
                 DrawCellForeground((ProposedX + 16), (VerticalWork + 16));
                 RedrawLevelCell((ProposedX - 16), VerticalWork);
                 RedrawLevelCell((ProposedX - 16), (VerticalWork + 16));
                 DrawCellForeground((ProposedX - 16), VerticalWork);
                 DrawCellForeground((ProposedX - 16), (VerticalWork + 16));
              end;
            end;
            42: begin
               HorizontalWork := ((ProposedX shr 4) + 1);
               UpperCellRow := ((VerticalWork shr 4) + 1);
               VerticalWork2 := (UpperCellRow + 1);
               RightCellColumn := (((ProposedX + 15) shr 4) + 2);
               if LevelCells[HorizontalWork, UpperCellRow].CellSolidFlag <> 0 then
              begin
                 GameActors[EntitySlot].ActorDirectionX := 1;
                 GameActors[EntitySlot].ActorAnimationCounter := 1;
              end
              else
              begin
                 if LevelCells[RightCellColumn, UpperCellRow].CellSolidFlag <> 0 then
                begin
                   GameActors[EntitySlot].ActorDirectionX := -1;
                   GameActors[EntitySlot].ActorAnimationCounter := 41;
                end
                else
                begin
                   if (LevelCells[HorizontalWork, VerticalWork2].CellSolidFlag = 0) and
                  (LevelCells[HorizontalWork, VerticalWork2].SupportsLanding = 0) then
                  begin
                     GameActors[EntitySlot].ActorDirectionX := 1;
                     GameActors[EntitySlot].ActorAnimationCounter := 1;
                  end
                  else
                  begin
                     if (LevelCells[RightCellColumn, VerticalWork2].CellSolidFlag = 0) and
                    (LevelCells[RightCellColumn, VerticalWork2].SupportsLanding = 0) then
                    begin
                       GameActors[EntitySlot].ActorDirectionX := -1;
                       GameActors[EntitySlot].ActorAnimationCounter := 41;
                    end;
                  end;
                end;
              end;
               Inc(GameActors[EntitySlot].ActorAnimationCounter);
               if GameActors[EntitySlot].ActorDirectionX = 1 then
              begin
                 if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                end;
              end
              else
              begin
                 if GameActors[EntitySlot].ActorAnimationCounter > 59 then
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 41;
                end;
              end;
               GameActors[EntitySlot].ActorWorldX := ProposedX;
               DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
               DamagePlayerOnContact((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
               if (ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY)) or
              (ConsumeShotsAtActor((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY)) then
              begin
                 StartSoundEffect(8);
                 GameActors[EntitySlot].FlashFrames := 3;
                 Dec(GameActors[EntitySlot].ActorKindValue1);
                 if GameActors[EntitySlot].ActorKindValue1 = 0 then
                begin
                   StartSoundEffect(19);
                   GameActors[EntitySlot].ActorRemovalPending := 1;
                   RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                   RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), GameActors[EntitySlot].ActorWorldY);
                   RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                   RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 32), GameActors[EntitySlot].ActorWorldY);
                   SpawnScorePopup((LongInt(GameActors[EntitySlot].ActorWorldX) and 65520),
                  (LongInt(GameActors[EntitySlot].ActorWorldY) and 65520), 19);
                   PlayerScore := (PlayerScore + 500);
                   StatusBarCameraX := -1;
                end;
                 if GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX then
                begin
                   GameActors[EntitySlot].ActorDirectionX := 1;
                end
                else
                begin
                   GameActors[EntitySlot].ActorDirectionX := -1;
                end;
                 if GameActors[EntitySlot].ActorDirectionX = 1 then
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                end
                else
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 41;
                end;
              end;
            end;
            30: begin
               HorizontalWork := (ProposedX shr 4);
               VerticalWork2 := (VerticalWork shr 4);
               RightCellColumn := (((ProposedX + 15) shr 4) + 1);
               if (LevelCells[(HorizontalWork + 1), VerticalWork2].CellSolidFlag <> 0) or
              ((LevelCells[RightCellColumn, VerticalWork2].CellSolidFlag <> 0) or
              ((LevelCells[(HorizontalWork + 1), (VerticalWork2
                    + 1)].CellSolidFlag <> 0) or (LevelCells[RightCellColumn, (VerticalWork2 +
                    1)].CellSolidFlag <> 0))) then
              begin
                 GameActors[EntitySlot].ActorDirectionX := (-GameActors[EntitySlot].ActorDirectionX);
                 if GameActors[EntitySlot].ActorDirectionX = -1 then
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 41;
                end
                else
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                end;
              end
              else
              begin
                 if (LevelCells[(HorizontalWork + 1), (VerticalWork2 + 2)].CellSolidFlag = 0) and
                (LevelCells[(HorizontalWork + 1), (VerticalWork2 + 2)].SupportsLanding = 0) then
                begin
                   GameActors[EntitySlot].ActorDirectionX := 1;
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                end
                else
                begin
                   if (LevelCells[RightCellColumn, (VerticalWork2 + 2)].CellSolidFlag = 0) and
                  (LevelCells[RightCellColumn, (VerticalWork2 + 2)].SupportsLanding = 0) then
                  begin
                     GameActors[EntitySlot].ActorDirectionX := -1;
                     GameActors[EntitySlot].ActorAnimationCounter := 41;
                  end;
                end;
              end;
               Inc(GameActors[EntitySlot].ActorAnimationCounter);
               if GameActors[EntitySlot].ActorDirectionX = 1 then
              begin
                 if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                end;
              end
              else
              begin
                 if GameActors[EntitySlot].ActorAnimationCounter > 59 then
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 41;
                end;
              end;
               if GameActors[EntitySlot].ActorCounterB > 0 then
              begin
                 Dec(GameActors[EntitySlot].ActorCounterB);
              end;
               if (GameActors[EntitySlot].ActorCounterB = 0) and (((GameActors[EntitySlot].ActorWorldY shr 4) =
              ((GameActors[1].ActorWorldY + 8) shr 4)) and
                    (((GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX) and
                    (GameActors[EntitySlot].ActorDirectionX = 1)) or ((GameActors[EntitySlot].ActorWorldX >
                    GameActors[1].ActorWorldX) and
                    (GameActors[EntitySlot].ActorDirectionX = -1)))) then
              begin
                 GameActors[EntitySlot].ActorCounterB := 70;
                 SpawnEnemyProjectile(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY,
                GameActors[EntitySlot].ActorDirectionX, 4, 825);
              end;
               GameActors[EntitySlot].ActorWorldX := ProposedX;
               if (ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY)) or
              (ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16))) then
              begin
                 if GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX then
                begin
                   if (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), (VerticalWork2 +
                  1)].CellSolidFlag = 0) and
                    (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), VerticalWork2].CellSolidFlag = 0)
                    then
                  begin
                     GameActors[EntitySlot].ActorDirectionX := 1;
                     GameActors[EntitySlot].ActorAnimationCounter := 1;
                  end;
                end
                else
                begin
                   if (LevelCells[((GameActors[EntitySlot].ActorWorldX shr 4) + 1), (VerticalWork2 + 1)].CellSolidFlag =
                  0) and (LevelCells[((GameActors[EntitySlot].ActorWorldX
                    shr 4) + 1), VerticalWork2].CellSolidFlag = 0) then
                  begin
                     GameActors[EntitySlot].ActorDirectionX := -1;
                     GameActors[EntitySlot].ActorAnimationCounter := 41;
                  end;
                end;
                 GameActors[EntitySlot].FlashFrames := 3;
                 Dec(GameActors[EntitySlot].ActorKindValue1);
                 if GameActors[EntitySlot].ActorKindValue1 = 0 then
                begin
                   StartSoundEffect(19);
                   PlayerScore := (PlayerScore + 1000);
                   StatusBarCameraX := -1;
                   GameActors[EntitySlot].ActorRemovalPending := 1;
                   RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                   RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), GameActors[EntitySlot].ActorWorldY);
                   RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                   RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), (GameActors[EntitySlot].ActorWorldY -
                  16));
                   RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), (GameActors[EntitySlot].ActorWorldY -
                  16));
                   RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16));
                   SpawnScorePopup((LongInt(GameActors[EntitySlot].ActorWorldX) and 65520),
                  (LongInt(GameActors[EntitySlot].ActorWorldY) and 65520), 20);
                end
                else
                begin
                   StartSoundEffect(8);
                end;
              end
              else
              begin
                 DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                 DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16));
              end;
            end;
            31: begin
               HorizontalWork := (ProposedX shr 4);
               VerticalWork2 := (VerticalWork shr 4);
               RightCellColumn := (((ProposedX + 15) shr 4) + 1);
               if (LevelCells[(HorizontalWork + 1), VerticalWork2].CellSolidFlag <> 0) or
              ((LevelCells[RightCellColumn, VerticalWork2].CellSolidFlag <> 0) or
              ((LevelCells[(HorizontalWork + 1), (VerticalWork2
                    + 1)].CellSolidFlag <> 0) or (LevelCells[RightCellColumn, (VerticalWork2 +
                    1)].CellSolidFlag <> 0))) then
              begin
                 GameActors[EntitySlot].ActorDirectionX := (-GameActors[EntitySlot].ActorDirectionX);
                 if GameActors[EntitySlot].ActorDirectionX = -1 then
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                end
                else
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 61;
                end;
              end
              else
              begin
                 if (LevelCells[(HorizontalWork + 1), (VerticalWork2 + 2)].CellSolidFlag = 0) and
                (LevelCells[(HorizontalWork + 1), (VerticalWork2 + 2)].SupportsLanding = 0) then
                begin
                   GameActors[EntitySlot].ActorDirectionX := 1;
                   GameActors[EntitySlot].ActorAnimationCounter := 61;
                end
                else
                begin
                   if (LevelCells[RightCellColumn, (VerticalWork2 + 2)].CellSolidFlag = 0) and
                  (LevelCells[RightCellColumn, (VerticalWork2 + 2)].SupportsLanding = 0) then
                  begin
                     GameActors[EntitySlot].ActorDirectionX := -1;
                     GameActors[EntitySlot].ActorAnimationCounter := 1;
                  end;
                end;
              end;
               Inc(GameActors[EntitySlot].ActorCounterB);
               if GameActors[EntitySlot].ActorCounterB >= GameActors[EntitySlot].ActorCounterA then
              begin
                 GameActors[EntitySlot].ActorCounterB := 0;
                 if ((GameActors[EntitySlot].ActorWorldY shr 4) = ((GameActors[1].ActorWorldY + 8) shr 4)) and
                (((GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX)
                    and (GameActors[EntitySlot].ActorDirectionX = 1)) or ((GameActors[EntitySlot].ActorWorldX >
                    GameActors[1].ActorWorldX) and (GameActors[EntitySlot].ActorDirectionX = -1))) then
                begin
                   SpawnEnemyProjectile(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY,
                  GameActors[EntitySlot].ActorDirectionX, 4, 827);
                end;
              end;
               if GameActors[EntitySlot].StateValueB > 0 then
              begin
                 Dec(GameActors[EntitySlot].StateValueB);
              end;
               if GameActors[EntitySlot].StateValueB = 1 then
              begin
                 GameActors[EntitySlot].ActorKindValue1 := 30;
              end
              else
              begin
                 if GameActors[EntitySlot].StateValueB = 0 then
                begin
                   Inc(GameActors[EntitySlot].ActorAnimationCounter);
                   if GameActors[EntitySlot].ActorDirectionX = -1 then
                  begin
                     if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                    begin
                       GameActors[EntitySlot].ActorAnimationCounter := 19;
                    end;
                  end
                  else
                  begin
                     if GameActors[EntitySlot].ActorAnimationCounter > 79 then
                    begin
                       GameActors[EntitySlot].ActorAnimationCounter := 79;
                    end;
                  end;
                   Dec(GameActors[EntitySlot].ActorKindValue1);
                   if GameActors[EntitySlot].ActorKindValue1 = 0 then
                  begin
                     GameActors[EntitySlot].StateValueB := 80;
                  end;
                end
                else
                begin
                   Inc(GameActors[EntitySlot].ActorAnimationCounter);
                   if GameActors[EntitySlot].ActorDirectionX = -1 then
                  begin
                     if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                    begin
                       GameActors[EntitySlot].ActorAnimationCounter := 1;
                    end;
                  end
                  else
                  begin
                     if GameActors[EntitySlot].ActorAnimationCounter > 79 then
                    begin
                       GameActors[EntitySlot].ActorAnimationCounter := 61;
                    end;
                  end;
                   GameActors[EntitySlot].ActorWorldX := ProposedX;
                end;
              end;
               DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
               DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16));
               if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY) then
              begin
                 StartSoundEffect(8);
                 if GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX then
                begin
                   if (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), (VerticalWork2 +
                  1)].CellSolidFlag = 0) and
                    (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), VerticalWork2].CellSolidFlag = 0)
                    then
                  begin
                     GameActors[EntitySlot].ActorDirectionX := 1;
                     GameActors[EntitySlot].ActorAnimationCounter := 61;
                  end;
                end
                else
                begin
                   if (LevelCells[((GameActors[EntitySlot].ActorWorldX shr 4) + 1), (VerticalWork2 + 1)].CellSolidFlag =
                  0) and (LevelCells[((GameActors[EntitySlot].ActorWorldX
                    shr 4) + 1), VerticalWork2].CellSolidFlag = 0) then
                  begin
                     GameActors[EntitySlot].ActorDirectionX := -1;
                     GameActors[EntitySlot].ActorAnimationCounter := 1;
                  end;
                end;
              end
              else
              begin
                 if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16))
                then
                begin
                   if GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX then
                  begin
                     if (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), (VerticalWork2 +
                    1)].CellSolidFlag = 0) and
                    (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), VerticalWork2].CellSolidFlag = 0)
                    then
                    begin
                       GameActors[EntitySlot].ActorDirectionX := 1;
                       GameActors[EntitySlot].ActorAnimationCounter := 61;
                    end;
                  end
                  else
                  begin
                     if (LevelCells[((GameActors[EntitySlot].ActorWorldX shr 4) + 1), (VerticalWork2 + 1)].CellSolidFlag
                    = 0) and (LevelCells[((GameActors[EntitySlot].ActorWorldX
                    shr 4) + 1), VerticalWork2].CellSolidFlag = 0) then
                    begin
                       GameActors[EntitySlot].ActorDirectionX := -1;
                       GameActors[EntitySlot].ActorAnimationCounter := 1;
                    end;
                  end;
                   if GameActors[EntitySlot].StateValueB = 0 then
                  begin
                     StartSoundEffect(19);
                     PlayerScore := (PlayerScore + 1000);
                     StatusBarCameraX := -1;
                     GameActors[EntitySlot].ActorRemovalPending := 1;
                     RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                     RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), GameActors[EntitySlot].ActorWorldY);
                     RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                     RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), (GameActors[EntitySlot].ActorWorldY -
                    16));
                     RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), (GameActors[EntitySlot].ActorWorldY -
                    16));
                     RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16));
                     SpawnScorePopup((LongInt(GameActors[EntitySlot].ActorWorldX) and 65520),
                    (LongInt(GameActors[EntitySlot].ActorWorldY) and 65520), 20);
                  end
                  else
                  begin
                     StartSoundEffect(8);
                  end;
                end;
              end;
            end;
            32: begin
               Inc(GameActors[EntitySlot].ActorAnimationCounter);
               if GameActors[EntitySlot].ActorAnimationCounter > 19 then
              begin
                 GameActors[EntitySlot].ActorAnimationCounter := 1;
              end;
               if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY) then
              begin
                 Dec(GameActors[EntitySlot].ActorCounterA);
                 GameActors[EntitySlot].FlashFrames := 3;
                 if GameActors[EntitySlot].ActorCounterA <= 0 then
                begin
                  for HorizontalWork := 0 to 15 do
                    PgSetPaletteRegister(HorizontalWork, 12);
                   SoundPlaying := 0;
                   StartSoundEffect(10);
                   LevelRadarDestroyed := 1;
                   PlayerScore := (PlayerScore + 5000);
                   StatusBarCameraX := -1;
                   GameActors[EntitySlot].ActorKindCode := 5001;
                   GameActors[EntitySlot].ActorCounterB := 16;
                   GameActors[EntitySlot].ActorSpriteBase := 172;
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                   PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3363], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 16));
                   PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3363], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 416));
                   RestoreGamePalette(0);
                end
                else
                begin
                   StartSoundEffect(8);
                end;
              end;
            end;
            33: begin
               if (LevelCells[((ProposedX shr 4) + 1), ((VerticalWork shr 4) +
              1)].CellSolidFlag <> 0) or ((LevelCells[(((ProposedX + 15) shr 4) +
                    1), ((VerticalWork shr 4) + 1)].CellSolidFlag <> 0) or
                    ((LevelCells[(((ProposedX + 8) shr 4) + 1), (VerticalWork shr
                    4)].SupportsLanding =
                    0) and (LevelCells[(((ProposedX + 8) shr 4) + 1), (VerticalWork
                    shr 4)].CellSolidFlag = 0))) then
              begin
                 GameActors[EntitySlot].ActorDirectionX := (-GameActors[EntitySlot].ActorDirectionX);
                 if GameActors[EntitySlot].ActorDirectionX = -1 then
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                end
                else
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 21;
                end;
              end;
               Inc(GameActors[EntitySlot].ActorAnimationCounter);
               if GameActors[EntitySlot].ActorDirectionX = -1 then
              begin
                 if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                end;
              end
              else
              begin
                 if GameActors[EntitySlot].ActorAnimationCounter > 39 then
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 21;
                end;
              end;
               Inc(GameActors[EntitySlot].ActorCounterB);
               if GameActors[EntitySlot].ActorCounterB = GameActors[EntitySlot].ActorCounterA then
              begin
                 if ((GameActors[EntitySlot].ActorWorldX - 16) < GameActors[1].ActorWorldX) and
                (((GameActors[EntitySlot].ActorWorldX + 16) > GameActors[1].ActorWorldX) and
                    (GameActors[EntitySlot].ActorWorldY < GameActors[1].ActorWorldY)) then
                begin
                   GameActors[EntitySlot].ActorCounterB := 0;
                   SpawnEnemyProjectile(ProposedX, (GameActors[EntitySlot].ActorWorldY + 8), 1, 8,
                  199);
                end
                else
                begin
                   Dec(GameActors[EntitySlot].ActorCounterB);
                end;
              end;
               GameActors[EntitySlot].ActorWorldX := ProposedX;
               DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
               if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY) then
              begin
                 GameActors[EntitySlot].FlashFrames := 3;
                 Dec(GameActors[EntitySlot].ActorKindValue1);
                 if GameActors[EntitySlot].ActorKindValue1 <= 0 then
                begin
                   StartSoundEffect(19);
                   PlayerScore := (PlayerScore + 500);
                   StatusBarCameraX := -1;
                   RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                   RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), GameActors[EntitySlot].ActorWorldY);
                   RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                   GameActors[EntitySlot].ActorKindCode := 5001;
                   GameActors[EntitySlot].ActorCounterB := 16;
                   GameActors[EntitySlot].ActorSpriteBase := 169;
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                   GameActors[EntitySlot].ActorWorldX := (LongInt((GameActors[EntitySlot].ActorWorldX + 8)) and 65520);
                   PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[2883], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 16));
                   PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[2883], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 416));
                end
                else
                begin
                   StartSoundEffect(8);
                end;
              end;
            end;
            34: begin
               HorizontalWork := ((ProposedX shr 4) + 1);
               UpperCellRow := ((VerticalWork shr 4) + 1);
               VerticalWork2 := (UpperCellRow + 1);
               RightCellColumn := (((ProposedX + 15) shr 4) + 1);
               if LevelCells[HorizontalWork, UpperCellRow].CellSolidFlag <> 0 then
              begin
                 GameActors[EntitySlot].ActorDirectionX := 1;
                 GameActors[EntitySlot].ActorAnimationCounter := 1;
              end
              else
              begin
                 if LevelCells[RightCellColumn, UpperCellRow].CellSolidFlag <> 0 then
                begin
                   GameActors[EntitySlot].ActorDirectionX := -1;
                   GameActors[EntitySlot].ActorAnimationCounter := 21;
                end
                else
                begin
                   if (LevelCells[HorizontalWork, VerticalWork2].CellSolidFlag = 0) and
                  (LevelCells[HorizontalWork, VerticalWork2].SupportsLanding = 0) then
                  begin
                     GameActors[EntitySlot].ActorDirectionX := 1;
                     GameActors[EntitySlot].ActorAnimationCounter := 1;
                  end
                  else
                  begin
                     if (LevelCells[RightCellColumn, VerticalWork2].CellSolidFlag = 0) and
                    (LevelCells[RightCellColumn, VerticalWork2].SupportsLanding = 0) then
                    begin
                       GameActors[EntitySlot].ActorDirectionX := -1;
                       GameActors[EntitySlot].ActorAnimationCounter := 21;
                    end;
                  end;
                end;
              end;
               Inc(GameActors[EntitySlot].ActorAnimationCounter);
               if GameActors[EntitySlot].ActorDirectionX = 1 then
              begin
                 if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                end;
              end
              else
              begin
                 if GameActors[EntitySlot].ActorAnimationCounter > 39 then
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 21;
                end;
              end;
               GameActors[EntitySlot].ActorWorldX := ProposedX;
               DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
               if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY) then
              begin
                 GameActors[EntitySlot].FlashFrames := 3;
                 Dec(GameActors[EntitySlot].ActorKindValue1);
                 if GameActors[EntitySlot].ActorKindValue1 <= 0 then
                begin
                   StartSoundEffect(19);
                   PlayerScore := (PlayerScore + 1000);
                   StatusBarCameraX := -1;
                   RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                   RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), GameActors[EntitySlot].ActorWorldY);
                   RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                   GameActors[EntitySlot].ActorKindCode := 5001;
                   GameActors[EntitySlot].ActorCounterB := 16;
                   GameActors[EntitySlot].ActorSpriteBase := 170;
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                   GameActors[EntitySlot].ActorWorldX := (LongInt((GameActors[EntitySlot].ActorWorldX + 8)) and 65520);
                   PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3043], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 16));
                   PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3043], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 416));
                   SpawnEnemyProjectile(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY, -1, 4,
                  125);
                   SpawnEnemyProjectile(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY, 1, 4,
                  126);
                end
                else
                begin
                   StartSoundEffect(8);
                end;
              end;
            end;
            35: begin
               Inc(GameActors[EntitySlot].ActorAnimationCounter);
               if GameActors[EntitySlot].ActorAnimationCounter > 19 then
              begin
                 GameActors[EntitySlot].ActorAnimationCounter := 1;
              end;
               GameActors[EntitySlot].ActorWorldX := ProposedX;
               DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
               if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY) then
              begin
                 GameActors[EntitySlot].FlashFrames := 3;
                 Dec(GameActors[EntitySlot].ActorKindValue1);
                 if GameActors[EntitySlot].ActorKindValue1 <= 0 then
                begin
                   StartSoundEffect(19);
                   PlayerScore := (PlayerScore + 1000);
                   StatusBarCameraX := -1;
                   GameActors[EntitySlot].ActorKindCode := 5001;
                   GameActors[EntitySlot].ActorCounterB := 16;
                   GameActors[EntitySlot].ActorSpriteBase := 170;
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                   GameActors[EntitySlot].ActorWorldX := (LongInt((GameActors[EntitySlot].ActorWorldX + 8)) and 65520);
                   PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3043], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 16));
                   PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3043], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 416));
                   CeilingLauncherDisabled := 1;
                end
                else
                begin
                   StartSoundEffect(8);
                end;
              end;
            end;
            36: begin
               GameActors[EntitySlot].ActorWorldX := ProposedX;
               Inc(GameActors[EntitySlot].ActorCounterB);
               if GameActors[EntitySlot].ActorCounterB >= GameActors[EntitySlot].ActorKindValue1 then
              begin
                 GameActors[EntitySlot].ActorCounterB := GameActors[EntitySlot].ActorKindValue1;
                 if ((GameActors[1].ActorWorldX + 8) >= (GameActors[EntitySlot].ActorWorldX - 4)) and
                (((GameActors[1].ActorWorldX + 8) <= (GameActors[EntitySlot].ActorWorldX +
                    4)) and ((GameActors[EntitySlot].ActorWorldY >= GameActors[1].ActorWorldY) and (CeilingLauncherDisabled =
                    0))) then
                begin
                   SpawnEnemyProjectile(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY + 8),
                  -1, 8, 114);
                   GameActors[EntitySlot].ActorCounterB := 0;
                end;
              end;
            end;
            137: begin
               VerticalWork2 := ((GameActors[EntitySlot].ActorWorldY shr 4) + 1);
               if (LevelCells[((GameActors[EntitySlot].ActorWorldX shr 4) + 1), VerticalWork2].CellSolidFlag <> 0) or
              (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr
                    4) + 1), VerticalWork2].CellSolidFlag <> 0) then
              begin
                 if GameActors[EntitySlot].ActorRemovalPending <> 0 then
                begin
                   GameActors[EntitySlot].ActorSlotInactive := 1;
                end;
                 GameActors[EntitySlot].ActorRemovalPending := 1;
                 if GameActors[EntitySlot].ActorWorldY < 0 then
                begin
                   GameActors[EntitySlot].ActorWorldY := 0;
                end;
                 RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                 RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                 RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY + 16));
                 RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), (GameActors[EntitySlot].ActorWorldY + 16));
                 DrawCellForeground(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                 DrawCellForeground((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                 DrawCellForeground(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY + 16));
                 DrawCellForeground((GameActors[EntitySlot].ActorWorldX + 16), (GameActors[EntitySlot].ActorWorldY +
                16));
              end
              else
              begin
                 Inc(GameActors[EntitySlot].ActorAnimationCounter);
                 if GameActors[EntitySlot].ActorAnimationCounter > 9 then
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                end;
                 GameActors[EntitySlot].ActorWorldY := VerticalWork;
                 if GameActors[EntitySlot].ActorWorldY < 0 then
                begin
                   GameActors[EntitySlot].ActorWorldY := 0;
                end;
                 DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
              end;
            end;
            37: begin
               VerticalWork2 := (GameActors[EntitySlot].ActorWorldY shr 4);
               if (LevelCells[((GameActors[EntitySlot].ActorWorldX shr 4) + 1), VerticalWork2].CellSolidFlag <> 0) or
              (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr
                    4) + 1), VerticalWork2].CellSolidFlag <> 0) then
              begin
                 if GameActors[EntitySlot].ActorRemovalPending <> 0 then
                begin
                   GameActors[EntitySlot].ActorSlotInactive := 1;
                end;
                 GameActors[EntitySlot].ActorRemovalPending := 1;
                 if GameActors[EntitySlot].ActorWorldY < 0 then
                begin
                   GameActors[EntitySlot].ActorWorldY := 0;
                end;
                 RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                 RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                 RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY + 16));
                 RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), (GameActors[EntitySlot].ActorWorldY + 16));
                 DrawCellForeground(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                 DrawCellForeground((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                 DrawCellForeground(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY + 16));
                 DrawCellForeground((GameActors[EntitySlot].ActorWorldX + 16), (GameActors[EntitySlot].ActorWorldY +
                16));
              end
              else
              begin
                 Inc(GameActors[EntitySlot].ActorAnimationCounter);
                 if GameActors[EntitySlot].ActorAnimationCounter > 9 then
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                end;
                 GameActors[EntitySlot].ActorWorldY := VerticalWork;
                 if GameActors[EntitySlot].ActorWorldY < 0 then
                begin
                   GameActors[EntitySlot].ActorWorldY := 0;
                end;
                 if (PlayerGodMode = 0) and ((((GameActors[EntitySlot].ActorWorldX <= GameActors[1].ActorWorldX) and
                ((GameActors[EntitySlot].ActorWorldX + 9) >=
                    GameActors[1].ActorWorldX)) or (((GameActors[1].ActorWorldX + 9) >= GameActors[EntitySlot].ActorWorldX)
                    and (GameActors[EntitySlot].ActorWorldX >= GameActors[1].ActorWorldX)))
                    and ((((GameActors[EntitySlot].ActorWorldY <= GameActors[1].ActorWorldY) and
                    ((GameActors[EntitySlot].ActorWorldY + 15) >= GameActors[1].ActorWorldY)) or
                    (((GameActors[1].ActorWorldY + 15) >= GameActors[EntitySlot].ActorWorldY) and
                    (GameActors[EntitySlot].ActorWorldY >= GameActors[1].ActorWorldY))) and (PlayerDying = 0)))
                    then
                begin
                   PlayerDying := 1;
                   DeathAnimationTick := 35;
                   StartSoundEffect(22);
                end;
              end;
            end;
            38: begin
               if (LevelCells[((ProposedX shr 4) + 1), ((VerticalWork shr 4) +
              1)].CellSolidFlag <> 0) or (LevelCells[(((ProposedX + 15) shr 4) +
                    1), ((VerticalWork shr 4) + 1)].CellSolidFlag <> 0) then
              begin
                 GameActors[EntitySlot].ActorDirectionX := (-GameActors[EntitySlot].ActorDirectionX);
              end;
               Inc(GameActors[EntitySlot].ActorAnimationCounter);
               if GameActors[EntitySlot].ActorAnimationCounter > 19 then
              begin
                 GameActors[EntitySlot].ActorAnimationCounter := 1;
              end;
               if GameActors[EntitySlot].StateValueB > 0 then
              begin
                 Dec(GameActors[EntitySlot].StateValueB);
              end;
               if GameActors[EntitySlot].StateValueB = 0 then
              begin
                 if GameActors[EntitySlot].ActorCounterB = 0 then
                begin
                   SpawnEnemyProjectile(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY + 16),
                  1, 0, 137);
                end;
                 Inc(GameActors[EntitySlot].ActorCounterB);
                 if GameActors[EntitySlot].ActorCounterB = GameActors[EntitySlot].ActorCounterA then
                begin
                   GameActors[EntitySlot].ActorCounterB := 0;
                   GameActors[EntitySlot].StateValueB := 110;
                end;
              end
              else
              begin
                 GameActors[EntitySlot].ActorWorldX := ProposedX;
              end;
               DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
               if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY) then
              begin
                 StartSoundEffect(8);
              end;
            end;
            39: begin
               HorizontalWork := (ProposedX shr 4);
               VerticalWork2 := (VerticalWork shr 4);
               RightCellColumn := (((ProposedX + 15) shr 4) + 1);
               if (LevelCells[(HorizontalWork + 1), VerticalWork2].CellSolidFlag <> 0) or
              ((LevelCells[RightCellColumn, VerticalWork2].CellSolidFlag <> 0) or
              ((LevelCells[(HorizontalWork + 1), (VerticalWork2
                    + 1)].CellSolidFlag <> 0) or (LevelCells[RightCellColumn, (VerticalWork2 +
                    1)].CellSolidFlag <> 0))) then
              begin
                 GameActors[EntitySlot].ActorDirectionX := (-GameActors[EntitySlot].ActorDirectionX);
                 if GameActors[EntitySlot].ActorDirectionX = -1 then
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                end
                else
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := 201;
                end;
              end
              else
              begin
                 if (LevelCells[(HorizontalWork + 1), (VerticalWork2 + 2)].CellSolidFlag = 0) and
                (LevelCells[(HorizontalWork + 1), (VerticalWork2 + 2)].SupportsLanding = 0) then
                begin
                   GameActors[EntitySlot].ActorDirectionX := 1;
                   GameActors[EntitySlot].ActorAnimationCounter := 201;
                end
                else
                begin
                   if (LevelCells[RightCellColumn, (VerticalWork2 + 2)].CellSolidFlag = 0) and
                  (LevelCells[RightCellColumn, (VerticalWork2 + 2)].SupportsLanding = 0) then
                  begin
                     GameActors[EntitySlot].ActorDirectionX := -1;
                     GameActors[EntitySlot].ActorAnimationCounter := 1;
                  end;
                end;
              end;
               Inc(GameActors[EntitySlot].ActorCounterB);
               if GameActors[EntitySlot].ActorCounterB >= GameActors[EntitySlot].ActorCounterA then
              begin
                 GameActors[EntitySlot].ActorCounterB := 0;
                 if ((GameActors[EntitySlot].ActorWorldY shr 4) = ((GameActors[1].ActorWorldY + 8) shr 4)) and
                (((GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX)
                    and (GameActors[EntitySlot].ActorDirectionX = 1)) or ((GameActors[EntitySlot].ActorWorldX >
                    GameActors[1].ActorWorldX) and (GameActors[EntitySlot].ActorDirectionX = -1))) then
                begin
                   SpawnEnemyProjectile(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY,
                  GameActors[EntitySlot].ActorDirectionX, 4, 827);
                end;
              end;
               if GameActors[EntitySlot].StateValueB > 0 then
              begin
                 Dec(GameActors[EntitySlot].StateValueB);
              end;
               if GameActors[EntitySlot].StateValueB = 1 then
              begin
                 GameActors[EntitySlot].ActorKindValue1 := 30;
              end
              else
              begin
                 if GameActors[EntitySlot].StateValueB = 0 then
                begin
                   Inc(GameActors[EntitySlot].ActorAnimationCounter);
                   if GameActors[EntitySlot].ActorDirectionX = -1 then
                  begin
                     if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                    begin
                       GameActors[EntitySlot].ActorAnimationCounter := 19;
                    end;
                  end
                  else
                  begin
                     if GameActors[EntitySlot].ActorAnimationCounter > 219 then
                    begin
                       GameActors[EntitySlot].ActorAnimationCounter := 219;
                    end;
                  end;
                   Dec(GameActors[EntitySlot].ActorKindValue1);
                   if GameActors[EntitySlot].ActorKindValue1 = 0 then
                  begin
                     GameActors[EntitySlot].StateValueB := 80;
                  end;
                end
                else
                begin
                   Inc(GameActors[EntitySlot].ActorAnimationCounter);
                   if GameActors[EntitySlot].ActorDirectionX = -1 then
                  begin
                     if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                    begin
                       GameActors[EntitySlot].ActorAnimationCounter := 1;
                    end;
                  end
                  else
                  begin
                     if GameActors[EntitySlot].ActorAnimationCounter > 219 then
                    begin
                       GameActors[EntitySlot].ActorAnimationCounter := 201;
                    end;
                  end;
                   GameActors[EntitySlot].ActorWorldX := ProposedX;
                end;
              end;
               DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
               DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16));
               if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY) then
              begin
                 StartSoundEffect(8);
                 if GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX then
                begin
                   if (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), (VerticalWork2 +
                  1)].CellSolidFlag = 0) and
                    (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), VerticalWork2].CellSolidFlag = 0)
                    then
                  begin
                     GameActors[EntitySlot].ActorDirectionX := 1;
                     GameActors[EntitySlot].ActorAnimationCounter := 201;
                  end;
                end
                else
                begin
                   if (LevelCells[((GameActors[EntitySlot].ActorWorldX shr 4) + 1), (VerticalWork2 + 1)].CellSolidFlag =
                  0) and (LevelCells[((GameActors[EntitySlot].ActorWorldX
                    shr 4) + 1), VerticalWork2].CellSolidFlag = 0) then
                  begin
                     GameActors[EntitySlot].ActorDirectionX := -1;
                     GameActors[EntitySlot].ActorAnimationCounter := 1;
                  end;
                end;
              end
              else
              begin
                 if ConsumeShotsAtActor(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16))
                then
                begin
                   if GameActors[EntitySlot].ActorWorldX < GameActors[1].ActorWorldX then
                  begin
                     if (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), (VerticalWork2 +
                    1)].CellSolidFlag = 0) and
                    (LevelCells[(((GameActors[EntitySlot].ActorWorldX + 15) shr 4) + 1), VerticalWork2].CellSolidFlag = 0)
                    then
                    begin
                       GameActors[EntitySlot].ActorDirectionX := 1;
                       GameActors[EntitySlot].ActorAnimationCounter := 201;
                    end;
                  end
                  else
                  begin
                     if (LevelCells[((GameActors[EntitySlot].ActorWorldX shr 4) + 1), (VerticalWork2 + 1)].CellSolidFlag
                    = 0) and (LevelCells[((GameActors[EntitySlot].ActorWorldX
                    shr 4) + 1), VerticalWork2].CellSolidFlag = 0) then
                    begin
                       GameActors[EntitySlot].ActorDirectionX := -1;
                       GameActors[EntitySlot].ActorAnimationCounter := 1;
                    end;
                  end;
                   if GameActors[EntitySlot].StateValueB = 0 then
                  begin
                     StartSoundEffect(19);
                     PlayerScore := (PlayerScore + 1000);
                     StatusBarCameraX := -1;
                     GameActors[EntitySlot].ActorRemovalPending := 1;
                     RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                     RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), GameActors[EntitySlot].ActorWorldY);
                     RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), GameActors[EntitySlot].ActorWorldY);
                     RedrawLevelCell((GameActors[EntitySlot].ActorWorldX + 16), (GameActors[EntitySlot].ActorWorldY -
                    16));
                     RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), (GameActors[EntitySlot].ActorWorldY -
                    16));
                     RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, (GameActors[EntitySlot].ActorWorldY - 16));
                     SpawnScorePopup((LongInt(GameActors[EntitySlot].ActorWorldX) and 65520),
                    (LongInt(GameActors[EntitySlot].ActorWorldY) and 65520), 20);
                  end
                  else
                  begin
                     StartSoundEffect(8);
                  end;
                end;
              end;
            end;
            40: begin
               Inc(GameActors[EntitySlot].ActorAnimationCounter);
               if GameActors[EntitySlot].ActorAnimationCounter > 19 then
              begin
                 GameActors[EntitySlot].ActorAnimationCounter := 1;
              end;
               Dec(GameActors[EntitySlot].ActorCounterB);
               if GameActors[EntitySlot].ActorCounterB = 0 then
              begin
                 GameActors[EntitySlot].ActorRemovalPending := 1;
                 RedrawLevelCell(ProposedX, VerticalWork);
                 RedrawLevelCell((ProposedX - 16), VerticalWork);
                 RedrawLevelCell((ProposedX + 16), VerticalWork);
                 DrawCellForeground(ProposedX, VerticalWork);
                 DrawCellForeground((ProposedX - 16), VerticalWork);
                 DrawCellForeground((ProposedX + 16), VerticalWork);
                 GameDrawBufferRow := (432 - GameDrawBufferRow);
                 RedrawLevelCell(ProposedX, VerticalWork);
                 RedrawLevelCell((ProposedX + 16), VerticalWork);
                 RedrawLevelCell((ProposedX - 16), VerticalWork);
                 DrawCellForeground(ProposedX, VerticalWork);
                 DrawCellForeground((ProposedX + 16), VerticalWork);
                 DrawCellForeground((ProposedX - 16), VerticalWork);
                 GameDrawBufferRow := (432 - GameDrawBufferRow);
              end
              else
              begin
                 DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
              end;
            end;
            41: begin
               if GameActors[EntitySlot].ActorSpriteBase = 435 then
              begin
                 HorizontalWork := (GameActors[1].ActorWorldX - GameActors[EntitySlot].ActorWorldX);
                 VerticalWork2 := (GameActors[1].ActorWorldY - GameActors[EntitySlot].ActorWorldY);
                 if (HorizontalWork < 8) and ((HorizontalWork > -8) and
                ((VerticalWork2 < 8) and (VerticalWork2 > -8))) then
                begin
                  while LevelCells[(ProposedX shr 4) + 1, VerticalWork shr
                  4].CellSolidFlag = 0 do
                    Dec(VerticalWork, 16);
                   StartSoundEffect(9);
                   GameActors[EntitySlot].ActorWorldY := VerticalWork;
                   GameActors[EntitySlot].ActorSpriteBase := 619;
                   GameActors[EntitySlot].ActorMovementStep := 8;
                   GameActors[EntitySlot].DirectionY := 1;
                end;
              end
              else
              begin
                 VerticalWork2 := ((GameActors[EntitySlot].ActorWorldY shr 4) + 2);
                 HorizontalWork := (((GameActors[EntitySlot].ActorWorldX + 3) shr 4) + 1);
                 RightCellColumn := (((GameActors[EntitySlot].ActorWorldX + 12) shr 4) + 1);
                 if (LevelCells[HorizontalWork, VerticalWork2].CellSolidFlag = 0) and
                ((LevelCells[RightCellColumn, VerticalWork2].CellSolidFlag = 0) and
                ((LevelCells[HorizontalWork, VerticalWork2].SupportsLanding =
                    0) and (LevelCells[RightCellColumn, VerticalWork2].SupportsLanding = 0))) then
                begin
                   GameActors[EntitySlot].ActorWorldY := (GameActors[EntitySlot].ActorWorldY + 4);
                   RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                   RedrawLevelCell(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
                   RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), (GameActors[EntitySlot].ActorWorldY -
                  16));
                   RedrawLevelCell((GameActors[EntitySlot].ActorWorldX - 16), (GameActors[EntitySlot].ActorWorldY -
                  16));
                end
                else
                begin
                   GameActors[EntitySlot].ActorRemovalPending := 1;
                   RedrawLevelCell(ProposedX, VerticalWork);
                   RedrawLevelCell((ProposedX - 16), VerticalWork);
                   RedrawLevelCell((ProposedX + 16), VerticalWork);
                   RedrawLevelCell(ProposedX, (VerticalWork - 16));
                   RedrawLevelCell((ProposedX - 16), (VerticalWork - 16));
                   RedrawLevelCell((ProposedX + 16), (VerticalWork - 16));
                   DrawCellForeground(ProposedX, VerticalWork);
                   DrawCellForeground((ProposedX - 16), VerticalWork);
                   DrawCellForeground((ProposedX + 16), VerticalWork);
                   DrawCellForeground(ProposedX, (VerticalWork - 16));
                   DrawCellForeground((ProposedX - 16), (VerticalWork - 16));
                   DrawCellForeground((ProposedX + 16), (VerticalWork - 16));
                   GameDrawBufferRow := (432 - GameDrawBufferRow);
                   RedrawLevelCell(ProposedX, VerticalWork);
                   RedrawLevelCell((ProposedX + 16), VerticalWork);
                   RedrawLevelCell((ProposedX - 16), VerticalWork);
                   RedrawLevelCell(ProposedX, (VerticalWork - 16));
                   RedrawLevelCell((ProposedX + 16), (VerticalWork - 16));
                   RedrawLevelCell((ProposedX - 16), (VerticalWork - 16));
                   DrawCellForeground(ProposedX, VerticalWork);
                   DrawCellForeground((ProposedX + 16), VerticalWork);
                   DrawCellForeground((ProposedX - 16), VerticalWork);
                   DrawCellForeground(ProposedX, (VerticalWork - 16));
                   DrawCellForeground((ProposedX + 16), (VerticalWork - 16));
                   DrawCellForeground((ProposedX - 16), (VerticalWork - 16));
                   GameDrawBufferRow := (432 - GameDrawBufferRow);
                end;
                 HorizontalWork := (GameActors[1].ActorWorldX - GameActors[EntitySlot].ActorWorldX);
                 VerticalWork2 := (GameActors[1].ActorWorldY - GameActors[EntitySlot].ActorWorldY);
                 if (HorizontalWork < 10) and ((HorizontalWork > -10) and
                ((VerticalWork2 < 10) and (VerticalWork2 > -10))) then
                begin
                   PlayerScore := (PlayerScore + 5000);
                   StatusBarCameraX := -1;
                   GameActors[EntitySlot].ActorKindCode := 5001;
                   GameActors[EntitySlot].ActorCounterB := 16;
                   GameActors[EntitySlot].ActorSpriteBase := 172;
                   GameActors[EntitySlot].ActorAnimationCounter := 1;
                   GameActors[EntitySlot].ActorMovementStep := 0;
                   PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3203], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 16));
                   PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3203], GameActors[EntitySlot].ActorWorldX,
                  (GameActors[EntitySlot].ActorWorldY + 416));
                end;
              end;
            end;
            43: begin
               Inc(GameActors[EntitySlot].ActorCounterA);
               if GameActors[EntitySlot].ActorCounterA = GameActors[EntitySlot].ActorCounterB then
              begin
                 Inc(GameActors[EntitySlot].ActorAnimationCounter);
                 if GameActors[EntitySlot].ActorAnimationCounter > 19 then
                begin
                   GameActors[EntitySlot].ActorAnimationCounter := (Random(5) + 1);
                end;
                 GameActors[EntitySlot].ActorCounterA := 0;
              end;
            end;
            44: begin
               Inc(GameActors[EntitySlot].ActorAnimationCounter);
               if GameActors[EntitySlot].ActorSpriteBase = 259 then
              begin
                 Inc(GameActors[EntitySlot].ActorAnimationCounter);
                 DamagePlayerOnContact(GameActors[EntitySlot].ActorWorldX, GameActors[EntitySlot].ActorWorldY);
              end;
               if GameActors[EntitySlot].ActorAnimationCounter > 19 then
              begin
                 GameActors[EntitySlot].ActorAnimationCounter := 1;
              end;
            end;
          end;
        end;
      end;
  for EntitySlot := 1 to PlayerProjectileLimit do
  begin
     if (PlayerShots[EntitySlot].ActorSlotInactive = 0) and (PlayerShots[EntitySlot].ActorSpriteBase <> 626) then
    begin
       PlayerShots[EntitySlot].ActorPreviousX := PlayerShots[EntitySlot].ActorWorldX;
       PlayerShots[EntitySlot].ActorPreviousY := PlayerShots[EntitySlot].ActorWorldY;
       if PlayerShots[EntitySlot].ActorDirectionX = 1 then
      begin
         ProposedX := (PlayerShots[EntitySlot].ActorWorldX +
        PlayerShots[EntitySlot].ActorMovementStep);
      end
      else
      begin
         if PlayerShots[EntitySlot].ActorDirectionX = -1 then
        begin
           ProposedX := (PlayerShots[EntitySlot].ActorWorldX -
          PlayerShots[EntitySlot].ActorMovementStep);
        end
        else
        begin
           ProposedX := PlayerShots[EntitySlot].ActorWorldX;
        end;
      end;
       VerticalWork := (((PlayerShots[EntitySlot].ActorWorldY + 8) shr 4) + 1);
       if (LevelCells[((ProposedX shr 4) + 1), VerticalWork].CellSolidFlag <> 0)
      or (LevelCells[(((ProposedX + 8) shr 4) + 1), VerticalWork].CellSolidFlag <> 0)
      then
      begin
         StartSoundEffect(7);
         PlayerShots[EntitySlot].ActorSpriteBase := 626;
         PlayerShots[EntitySlot].ActorMovementStep := 0;
         PlayerShots[EntitySlot].ActorCounterB := 7;
      end;
       PlayerShots[EntitySlot].ActorWorldX := ProposedX;
    end;
  end;
end;

{ Player movement, gravity and collision tests. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Tests the four corners of the player's prospective 10x16 collision rectangle against Solid cells. }
function PlayerPositionIsClear(MoveOffsetX, MoveOffsetY: Word): Boolean;
var
  LeftCellColumn: Word;
  TopCellRow: Word;
  RightCellColumn: Word;
  BottomCellRow: Word;
begin
  LeftCellColumn := ((Word(GameActors[1].ActorWorldX) + MoveOffsetX + 3) shr 4) + 1;
  RightCellColumn := ((Word(GameActors[1].ActorWorldX) + MoveOffsetX + 12) shr 4) + 1;
  TopCellRow := ((Word(GameActors[1].ActorWorldY) + MoveOffsetY) shr 4) + 1;
  BottomCellRow := ((Word(GameActors[1].ActorWorldY) + MoveOffsetY + 15) shr 4) + 1;

  if (LevelCells[LeftCellColumn, TopCellRow].CellSolidFlag <> 0) or
     (LevelCells[RightCellColumn, TopCellRow].CellSolidFlag <> 0) or
     (LevelCells[LeftCellColumn, BottomCellRow].CellSolidFlag <> 0) or
     (LevelCells[RightCellColumn, BottomCellRow].CellSolidFlag <> 0) then
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
{ Moves in held directions when PlayerPositionIsClear permits, saves previous position and scrolls the bounded camera. }
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

{ Tile effects, pickups and level exits. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Dispatches foreground codes for pickups, colored keys/doors, level entrances/exits, radar gating. }
procedure ProcessPlayerTileContact(ContactX, ContactY: Integer);
var
  ContactWork, WorkX, WorkY: Integer;
begin
  case Integer(LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode)
  of
    0: ;
    $1A5,$1A7,$1A9:
      begin
        case Integer(LevelCells[(ContactX shr 4)+1,(ContactY shr
        4)+1].CellObjectCode) of
          $1A5: HasKeyOne := 1;
          $1A7: HasKeyTwo := 1;
          $1A9: HasKeyThree := 1;
        end;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
        StatusBarCameraX := -1;
      end;
    $1A6,$1A8,$1AA:
      begin
        ContactWork := 0;
        case Integer(LevelCells[(ContactX shr 4)+1,(ContactY shr
        4)+1].CellObjectCode) of
          $1A6: if HasKeyOne = 1 then begin ContactWork := 1; HasKeyOne := 0 end;
          $1A8: if HasKeyTwo = 1 then begin ContactWork := 1; HasKeyTwo := 0 end;
          $1AA: if HasKeyThree = 1 then begin ContactWork := 1; HasKeyThree := 0 end;
        end;
        if ContactWork = 1 then
        begin
          LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
          LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellSolidFlag := 0;
          StartSoundEffect(6);
          StatusBarCameraX := -1;
        end;
      end;
    $12D:
      begin
        PlayerAmmo := PlayerAmmo + 5;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        if PlayerAmmo > 99 then PlayerAmmo := 99;
        StatusBarCameraX := -1;
        StartSoundEffect(5);
      end;
    $13C:
      begin
        PlayerScore := PlayerScore + 1000;
        SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,20);
        StatusBarCameraX := -1;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $26A:
      begin
        PlayerScore := PlayerScore + 250;
        SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,18);
        StatusBarCameraX := -1;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $26B:
      begin
        PlayerScore := PlayerScore + 1000;
        SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,20);
        StatusBarCameraX := -1;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $26C:
      begin
        PlayerScore := PlayerScore + 500;
        SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,19);
        StatusBarCameraX := -1;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $275:
      begin
        PlayerScore := PlayerScore + 100;
        SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,17);
        StatusBarCameraX := -1;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $276:
      begin
        PlayerScore := PlayerScore + 1000;
        SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,20);
        StatusBarCameraX := -1;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $277:
      begin
        PlayerScore := PlayerScore + 500;
        SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,19);
        StatusBarCameraX := -1;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $278:
      begin
        PlayerScore := PlayerScore + 100;
        SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,17);
        StatusBarCameraX := -1;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $2C:
      begin
        PlayerScore := PlayerScore + 500;
        SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,19);
        StatusBarCameraX := -1;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
      end;
    $26D..$26F:
      begin
        case Integer(LevelCells[(ContactX shr 4)+1,(ContactY shr
        4)+1].CellObjectCode) of
          $26D:
            begin
              BonusStep621Collected := 1;
              PlayerScore := PlayerScore + 100;
              SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,17);
              StatusBarCameraX := -1;
              StartSoundEffect(4);
            end;
          $26E:
            if (BonusPickupOrderValid <> 0) and (BonusStep621Collected <> 0) then
            begin
              BonusStep622Collected := 1;
              PlayerScore := PlayerScore + 100;
              SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,17);
              StatusBarCameraX := -1;
              StartSoundEffect(4);
            end
            else
            begin
              BonusStep622Collected := 1;
              BonusPickupOrderValid := 0;
              PlayerScore := PlayerScore + 100;
              SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,17);
              StatusBarCameraX := -1;
              StartSoundEffect(4);
            end;
          $26F:
            if (BonusPickupOrderValid <> 0) and (BonusStep621Collected <> 0) and (BonusStep622Collected <> 0) then
            begin
              PlayerScore := PlayerScore + 10000;
              SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,23);
              StatusBarCameraX := -1;
              StartSoundEffect(12);
            end
            else
            begin
              PlayerScore := PlayerScore + 100;
              SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,17);
              StatusBarCameraX := -1;
              BonusPickupOrderValid := 0;
              StartSoundEffect(4);
            end;
        end;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
      end;
    $25E:
      begin
        PlayerScore := PlayerScore + 500;
        SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,19);
        StatusBarCameraX := -1;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
        StatusBarCameraX := -1;
      end;
    $130:
      begin
        LevelBlueprintFlags[CurrentLevelNumber] := 1;
        PlayerScore := PlayerScore + 2000;
        SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,21);
        StatusBarCameraX := -1;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
        EpisodeBlueprintCollected := 1;
      end;
    $25F:
      begin
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(4);
        ShowGameMessage('You can see invisible platforms.');
        for ContactY := 1 to 24 do
          for ContactX := 1 to 40 do
            if Integer(LevelCells[ContactX,ContactY].CellObjectCode) = -1 then
            begin
              LevelCells[ContactX,ContactY].CellOverlayTile := $260;
              LevelCells[ContactX,ContactY].SupportsLanding := 1;
              RedrawLevelCell((ContactX-1) shl 4,(ContactY-1) shl 4);
              DrawCellForeground((ContactX-1) shl 4,(ContactY-1) shl 4);
              GameDrawBufferRow := 432 - GameDrawBufferRow;
              RedrawLevelCell((ContactX-1) shl 4,(ContactY-1) shl 4);
              DrawCellForeground((ContactX-1) shl 4,(ContactY-1) shl 4);
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
        case Integer(LevelCells[(ContactX shr 4)+1,(ContactY shr
        4)+1].CellObjectCode) of
          $113..$122:
            begin
              EnteredLevelNumber := Integer(LevelCells[(ContactX shr
              4)+1,(ContactY shr 4)+1].CellObjectCode) - $111;
              LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode
              := $10C;
            end;
          $10C:
            if LevelEntranceAnimationTick > 15 then Inc(Integer(LevelCells[(ContactX shr
            4)+1,(ContactY shr 4)+1].CellObjectCode));
          $10D:
            if LevelEntranceAnimationTick > 30 then Inc(Integer(LevelCells[(ContactX shr
            4)+1,(ContactY shr 4)+1].CellObjectCode));
        end;
        if LevelEntranceAnimationTick > 50 then
        begin
          EnteredLevelNumber := Integer(LevelCells[(ContactX shr 4)+1,(ContactY
          shr 4)+1].CellBaseTile);
          LevelEntranceAnimationTick := 0;
          FadeGamePaletteToBlack(20);
          CurrentLevelNumber := EnteredLevelNumber;
          CaptureGameSnapshot;
          if GameSnapshot.SavedPlayerX > (ContactX and $FFF0) + 8 then
            GameSnapshot.SavedPlayerX := (GameSnapshot.SavedPlayerX and $FFF0) + 16
          else
            GameSnapshot.SavedPlayerX := (GameSnapshot.SavedPlayerX + 8) and $FFF0;
          if GameSnapshot.SavedPlayerY > (ContactY and $FFF0) + 8 then
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
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
        StatusBarCameraX := -1;
        SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,19);
        PlayerScore := PlayerScore + 500;
      end;
    $27D:
      begin
        if PlayerHasDynamite = 1 then
        begin
          PlayerHasDynamite := 0;
          StartSoundEffect(11);
          StatusBarCameraX := -1;
          if GameActors[1].ActorWorldX + 5 > ContactX then
          begin
            WorkX := ((ContactX shr 4)+1) shl 4;
            WorkY := ContactY and $FFF0;
          end
          else
          begin
            WorkX := ((ContactX shr 4)-1) shl 4;
            WorkY := ContactY and $FFF0;
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
          if (ContactX shr 4 = 0) or
             (LevelCells[((ContactX shr 4)+1)-1,(ContactY shr
             4)+1].CellSolidFlag = 1) then
          begin
            GameActors[1].ActorPreviousX := GameActors[1].ActorWorldX;
            GameActors[1].ActorPreviousY := GameActors[1].ActorWorldY;
            GameActors[1].ActorWorldX := (ContactX and $FFF0) + 16;
            GameActors[1].ActorWorldY := ContactY and $FFF0;
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
            GameActors[1].ActorWorldX := (ContactX and $FFF0) - 16;
            GameActors[1].ActorWorldY := ContactY and $FFF0;
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
            if (ContactX shr 4 = 0) or
               (LevelCells[((ContactX shr 4)+1)-1,(ContactY shr
               4)+1].CellSolidFlag = 1) then
            begin
              GameActors[1].ActorPreviousX := GameActors[1].ActorWorldX;
              GameActors[1].ActorPreviousY := GameActors[1].ActorWorldY;
              GameActors[1].ActorWorldX := (ContactX and $FFF0) + 16;
              GameActors[1].ActorWorldY := ContactY and $FFF0;
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
              GameActors[1].ActorWorldX := (ContactX and $FFF0) - 16;
              GameActors[1].ActorWorldY := ContactY and $FFF0;
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
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        GameActors[ContactWork].FlashFrames := 0;
        GameActors[ContactWork].ActorSpriteBase := $271;
        GameActors[ContactWork].ActorWorldX := ContactX and $FFF0;
        GameActors[ContactWork].ActorWorldY := ContactY and $FFF0;
        GameActors[ContactWork].ActorPreviousX := ContactX and $FFF0;
        GameActors[ContactWork].ActorPreviousY := ContactY and $FFF0;
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
          LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellSolidFlag := 0;
          StartSoundEffect(24);
          for ContactY := 1 to 24 do
            for ContactX := 1 to 40 do
              if Integer(LevelCells[ContactX,ContactY].CellObjectCode) = $25B
              then
              begin
                LevelCells[ContactX,ContactY].CellObjectCode := 0;
                RedrawLevelCell((ContactX-1) shl 4,(ContactY-1) shl 4);
                DrawCellForeground((ContactX-1) shl 4,(ContactY-1) shl 4);
                GameDrawBufferRow := 432 - GameDrawBufferRow;
                RedrawLevelCell((ContactX-1) shl 4,(ContactY-1) shl 4);
                DrawCellForeground((ContactX-1) shl 4,(ContactY-1) shl 4);
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
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
        StatusBarCameraX := -1;
        SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,19);
        PlayerScore := PlayerScore + 500;
      end;
    $B7:
      begin
        ContactX := ContactX and $FFF0;
        if (((GameActors[1].ActorWorldX > ContactX) and
        (GameActors[1].ActorWorldX-ContactX <= 2)) or
            ((GameActors[1].ActorWorldX < ContactX) and
            (ContactX-GameActors[1].ActorWorldX <= 2))) and
           (PlayerTeleporting = 0) then
        begin
          StatusBarCameraX := -1;
          StartSoundEffect(23);
          for WorkY := 1 to 24 do
            for WorkX := 1 to 40 do
              if Integer(LevelCells[WorkX,WorkY].CellObjectCode) = $B7 then
                if (((ContactX shr 4)+1) <> WorkX) or (((ContactY shr 4)+1) <>
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
        SpawnScorePopup(ContactX and $FFF0,ContactY and $FFF0,18);
        StatusBarCameraX := -1;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
        PlayerSpeedBoost := 4;
        SpeedBoostTimeLeft := 216;
      end;
    $143..$145:
      begin
        PlayerScore := PlayerScore + 100;
        StatusBarCameraX := -1;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].SupportsLanding := 0;
        StartSoundEffect(4);
      end;
    $142:
      begin
        PlayerScore := PlayerScore + 1000;
        StatusBarCameraX := -1;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
        SpecialMovementMode := 2;
        SpecialMovementDuration := 432;
      end;
    $31:
      begin
        PlayerScore := PlayerScore + 100;
        StatusBarCameraX := -1;
        Inc(Pickup31Count);
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
      end;
    $13A:
      begin
        PlayerScore := PlayerScore + 5000;
        StatusBarCameraX := -1;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
        Inc(PlayerProjectileLimit);
        if PlayerProjectileLimit > 2 then PlayerProjectileLimit := 2;
        ShowGameMessage('Increased Shot Power!');
      end;
    $1D2:
      begin
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(26);
        PlayerControlsReversed := 1;
        PlayerLeftHeld := 0;
        PlayerRightHeld := 0;
        ConfusionTimeLeft := 216;
        ShowGameMessage('YOU FEEL A BIT CONFUSED!');
      end;
    $1D4:
      begin
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(27);
        PlayerSlowMovement := 1;
        SlowMovementTimeLeft := 216;
      end;
    $269:
      begin
        StatusBarCameraX := -1;
        LevelCells[(ContactX shr 4)+1,(ContactY shr 4)+1].CellObjectCode := 0;
        StartSoundEffect(5);
        Inc(PlayerProgressCount);
      end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Calls ProcessPlayerTileContact at four inset corners of the 16x16 player footprint. }
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
