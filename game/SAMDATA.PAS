unit SAMDATA;
{$A+}{$D+}{$L+}{$F-}
interface
uses Dos, PROGRPHX;
type
  TLevelFileRow = array[1..42] of Char;
type
  TGameActor = record
    FlashFrames, ActorWorldX, ActorWorldY, ActorPreviousX, ActorPreviousY, ActorAnimationCounter, ActorCounterA,
    ActorCounterB, ActorKindValue1, StateValueB,
    ActorSpriteBase, ActorDirectionX, DirectionY, ActorMovementStep, ActorKindCode: Integer;
    ActorSlotInactive, ActorRemovalPending: Byte;
  end;
type
  TLevelCell = record
    CellBaseTile, CellOverlayTile, CellObjectCode: Word;
    CellSolidFlag, SupportsLanding: Byte;
  end;
type
  TGameConfiguration = packed record
    ConfigScoreLines: array[1..10] of string[40];
    ConfigRankedScores: array[1..10] of LongInt;
    ConfigSoundEnabled: Byte;
    ConfigUpScanCode, ConfigDownScanCode, ConfigLeftScanCode, ConfigRightScanCode, ConfigJumpScanCode, ConfigFireScanCode,
    ConfigAlternateVideo, ConfigJoystickEnabled: Word;
  end;
type
  TGameSnapshot = packed record
    SavedPlayerX, SavedPlayerY: Integer;
    SavedPlayerScore: LongInt;
    SavedProgressCount, SavedPlayerAmmo, SavedProjectileLimit: Integer;
    SavedBlueprintFlags: array[1..20] of Byte;
    SavedSpeedBoost, SavedSpeedTimeLeft: Integer;
    SavedControlsReversed: Byte;
    SavedConfusionTimeLeft: Integer;
    SavedConfusionEndedPending, SavedSlowMovement: Byte;
    SavedSlowTimeLeft, SavedAuxiliaryValue, SavedEntranceAnimationTick, SavedEnteredLevelNumber: Integer;
    SavedCompletedLevelFlags: array[1..20] of Byte;
    SavedExtraAmmoCheatUsed: Byte;
  end;
type
  TSpeakerSoundBank = array[1..12, 1..305] of Integer;
type
  PSpeakerSoundBank = ^TSpeakerSoundBank;
type
  TPopupImageBuffer = array[0..29999] of Byte;
type
  PPopupImageBuffer = ^TPopupImageBuffer;
type
  TSpriteSlot16 = packed record SpriteLeadingBytes: array[1..3] of Byte; SpriteDataBytes: array[1..157] of Byte; end;
type
  TSpriteFileBlock = packed record SpriteEntries: array[1..50] of TSpriteSlot16; SpriteBlockTail: array[1..64] of Byte; end;
type
  PSpriteFileBlock = ^TSpriteFileBlock;
type
  TGlyphStride40 = packed record GlyphLeadingBytes: array[1..3] of Byte; GlyphDataBytes: array[1..37] of Byte; end;
type
  TGlyphFileBlock = packed record GlyphEntries: array[1..50] of TGlyphStride40; GlyphBlockTail: array[1..48] of Byte; end;
type
  PGlyphFileBlock = ^TGlyphFileBlock;
type
  TRawByteView = array[0..32767] of Byte;
type
  PRawByteView = ^TRawByteView;
type
  TPcxIdentity = packed record
    PcxIdentityProduct: array[0..31] of Char;
    PcxIdentityCopyright: array[0..51] of Char;
    PcxIdentityRights: array[0..21] of Char;
    PcxIdentityAuthor: array[0..23] of Char;
    PcxIdentityEmsDriverName: array[0..7] of Char;
  end;
type
  TPcxDisplayNameTable = array[0..21] of string[20];
type
  TPcxDisplayInfo = packed record
    PcxDisplayTypeCode: Byte;                  
    PcxDisplayDescription: string[20];            
    PcxDisplayBiosMode, PcxDisplayBitsPerPixel: Byte;       
    PcxDisplayWidth, PcxDisplayHeight: Word;                
    PcxDisplayScaleX, PcxDisplayScaleY: Byte;  
    PcxDisplayVideoSegment, PcxDisplayPageBytes, PcxDisplayDeviceClass: Word;  
    PcxDisplayDecodeTarget: Pointer;        
    PcxDisplayReservedWords: array[0..7] of Word;       
  end;
type
  PPcxDisplayInfo = ^TPcxDisplayInfo;
type
  TPcxReadState = packed record
    PcxReadBufferBytes, PcxReadBufferSegment, PcxReadBufferOffset: Word;
    PcxReadFileHandle: Integer;
    PcxReadPositionHigh, PcxReadPositionLow: Word;
    PcxReadDispatchReady: Byte;
    PcxReadAdapterFlags: array[0..3] of Byte;
  end;
type
  TPcxPrinterState = packed record
    PcxPrintPortIndex, PcxPrintScaleMode, PcxPrintFormFeedEnabled, PcxPrintResetEnabled, PcxPrintScanlineBytes: Word;
    PcxPrintAlternateRow: Byte;
    PcxPrintResetCommand: string[2];            
    PcxPrintCopiesCommand: string[5];           
    PcxPrintOrientationCommand: string[5];      
    PcxPrintMarginCommand: string[7];           
    PcxPrintFormFeedCommand: string[5];         
    PcxPrintPositionCommand: string[13];        
    PcxPrintResolution100: string[7];           
    PcxPrintResolution150: string[7];           
    PcxPrintResolution300: string[7];           
    PcxPrintBeginRasterCommand: string[5];      
    PcxPrintEndRasterCommand: string[4];        
    PcxPrintScanlineCommand: string[15];        
    PcxPrintDecimalDivisors: array[0..9] of LongInt;  
  end;
type
  TGameConfigFile = file of TGameConfiguration;
type
  t_p_0f75_tconfi_TGameConfigFile = file of TGameConfiguration;
type
{$IFDEF SAM1}
{$ELSE}
  TVideoBiosRegs = record
    case Integer of
      0: (AX, BX, CX, DX, BP, SI, DI, DS, ES, Flags: Word);
      1: (AL, AH, BL, BH, CL, CH, DL, DH: Byte);
  end;
type
{$ENDIF}
  TMapCellView = record
    BaseTile, MiddleTile, FrontTile: Word;
    BlocksMovement, TMapCellView_SupportsLanding: Byte;
  end;
type
  t_u2_2530_tmapcell_TMapCellView = record
    t_u2_2530_tmapcell_TMa_BaseTile, t_u2_2530_tmapcell_T_MiddleTile, t_u2_2530_tmapcell_TM_FrontTile: Word;
    t_u2_2530_tmapce_BlocksMovement, t_u2_2530_tmapc_SupportsLanding: Byte;
  end;
type
  TEncodedLevelFile = file of TLevelFileRow;
  TLevelFileAccess = record
    case Byte of
      0: (RawFile: File);
      1: (RowFile: TEncodedLevelFile);
  end;
{$IFDEF SAM1}
type
  PVideoFlagByte = ^Byte;
  PVideoFlagPointer = ^Pointer;
{$ENDIF}
type
  t_u3_1601_tname = String[40];
  TPopupLineWrapper = packed record
    PopupWrappedLine: t_u3_1601_tname;
  end;
  t_u3_1601_tbytearray38 = array[37..32767] of Byte;
  t_u3_1601_pbytearray38 = ^t_u3_1601_tbytearray38;
type
  t_u3_26cf_thelpline = string[40];
type
  t_u3_3712_pbyte = ^Byte;
type
  TSpriteBankFile = file of TSpriteFileBlock;
  TGlyphBankFile = file of TGlyphFileBlock;
  TSpriteFileViews = record
    case Byte of
      0: (SpriteUntypedFile: File);
      1: (SpriteTypedFile: TSpriteBankFile);
  end;
  TGlyphFileViews = record
    case Byte of
      0: (GlyphUntypedFile: File);
      1: (GlyphTypedFile: TGlyphBankFile);
  end;
type
  TSaveGameOutputFile = file of TGameSnapshot;
type
  TSaveGameInputFile = file of TGameSnapshot;
type
  t_u3_4e64_thelpline = string[40];
type
  t_u3_6ea9_thelpline = string[40];
  t_u3_6ea9_tlevelrow = array[1..42] of Char;
type
  t_u3_7c17_tlevelrow = array[1..42] of Char;
type
  t_u3_848e_tstr40 = string[40];
type
  t_u3_8ea3_tstr40 = string[40];
type
  TSaveMenuLineView = packed record
    SaveMenuWrappedLine: string[40];
  end;
type
  TRestoreMenuLineView = packed record
    RestoreMenuWrappedLine: string[40];
  end;
type
  t_u3_9340_tmenutext = array[1..299] of String[40];
type
  t_u3_97bb_tstring40 = string[40];
type
  TMessageLineView = packed record
    MessageWrappedLine: string[40];
  end;
  TPopupStringViews = packed record
    case Byte of
      0: (PopupFullString: string[255]);
      1: (PopupLineString: string[40]);
  end;
type
  TQuitPromptLinePair = packed record
    QuitPromptFirstLine: string[40];
    QuitPromptSecondLine: string[40];
  end;
type
  t_u3_9ca9_tmenutext = array[1..6] of String[40];
type
  TSoundPromptLineView = packed record
    SoundPromptWrappedLine: String[40];
  end;
type
  TJoystickPromptLinePair = packed record
    JoystickPromptFirstLine: string[40];
    JoystickPromptSecondLine: string[40];
  end;
type
  t_u3_cf40_tmenulines = array[1..299] of String[40];
type
  t_u3_d323_tmenuline = String[40];
type
  TFortressMessageLineView = packed record
    FortressMessageWrappedLine: String[40];
  end;
type
  t_u3_d820_tmenutext = array[1..6] of String[40];
const
  t_u3_dbc2_border = #176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176;
var
  PlayerVerticalMotionTable: array[1..19] of Byte;
{$IFDEF SAM1}
  reserved_34c3: Byte;
{$ELSE}
  reserved_34e9: Byte;
{$ENDIF}
  AlternateVerticalMotionTable: array[1..38] of Byte;
  PlayerVerticalMotionStep: byte;
  AlternateVerticalMotionStep: Byte;
  GameActors: array[1..25] of TGameActor;
  StartupWorkOne: integer;
  StartupWorkTwo: integer;
  StartupWorkThree: integer;
  PopupTextLines: array[1..299] of string[40];
{$IFDEF SAM1}
  reserved_67f5: Byte;
{$ELSE}
  reserved_681b: Byte;
{$ENDIF}
  PopupSavedBackground: PPopupImageBuffer;
  PopupAcceptedScanCodes: array[1..20] of Byte;
{$IFDEF SAM1}
  reserved_680e: array[0..5] of Byte;
{$ELSE}
  reserved_6834: array[0..5] of Byte;
{$ENDIF}
  PopupSelectionScanCode: Word;
  GameOptionsRequested: byte;
{$IFDEF SAM1}
  reserved_6817: Byte;
{$ELSE}
  reserved_683d: Byte;
{$ENDIF}
  PlayerLandingCount: integer;
  LevelBackdropTile: word;
  CurrentLevelNumber: Integer;
  MoveRampTicks: word;
  PlayerHorizontalStep: Integer;
  VideoStrideResult: integer;
  LastKeyboardScanCode: Integer;
  SharedLoopIndexA: integer;
  SharedLoopIndexB: integer;
  SharedLoopIndexC: Integer;
  GameTickCounter: Integer;
  LoadedActorCount: Integer;
  GameReservedWord: Integer;
  StatusBarCameraX: Integer;
  IslandEntranceIndex: Integer;
  SpecialMovementMode: byte;
{$IFDEF SAM1}
  reserved_6837: Byte;
{$ELSE}
  reserved_685d: Byte;
{$ENDIF}
  CameraX: Integer;
  CameraY: Integer;
  DisplayedBufferRow: Integer;
  GameDrawBufferIndex: Integer;
  GameDrawBufferRow: Integer;
  AllMissionsComplete: byte;
  LevelStatusReservedByte: byte;
  LevelBlueprintFlags: array[1..20] of Byte;
  PlayerAmmo: Integer;
  PlayerShots: array[1..10] of TGameActor;
  PlayerScore: LongInt;
  PlayerProgressCount: Integer;
  Pickup31Count: Integer;
  PlayerProjectileLimit: Integer;
  PlayerSpeedBoost: Integer;
  SpeedBoostTimeLeft: Integer;
  SpecialMovementDuration: Integer;
  ConfusionTimeLeft: Integer;
  ConfusionEndedMessagePending: byte;
  PlayerControlsReversed: byte;
  SlowMovementTimeLeft: Integer;
  PlayerSlowMovement: byte;
{$IFDEF SAM1}
  reserved_69b1: Byte;
{$ELSE}
  reserved_69d7: Byte;
{$ENDIF}
  SavedAuxiliaryCounter: Integer;
  PlayerInputLocked: byte;
{$IFDEF SAM1}
  reserved_69b5: Byte;
{$ELSE}
  reserved_69db: Byte;
{$ENDIF}
  LevelEntranceAnimationTick: Integer;
  EnteredLevelNumber: Integer;
  LevelCompletedFlags: array[1..20] of Byte;
  LevelRadarDestroyed: byte;
  WarpChordOHeld: byte;
  WarpChordNHeld: byte;
  WarpChordDHeld: byte;
  LevelCheatPBHeld: byte;
  WarpLevelRequested: byte;
  GodChordPHeld: byte;
  GodChordJHeld: byte;
  GodChordXHeld: byte;
  GodModeMessagePending: byte;
  TeleportRelocatePending: byte;
  AmmoChordUHeld: byte;
  AmmoChordVHeld: byte;
  AmmoChordKHeld: byte;
  ExtraAmmoCheatUsed: byte;
  InventoryChordZHeld: byte;
  InventoryChordGHeld: byte;
  InventoryChordIHeld: byte;
  PlayerTeleporting: byte;
{$IFDEF SAM1}
  reserved_69e1: Byte;
{$ELSE}
  reserved_6a07: Byte;
{$ENDIF}
  TeleportAnimationTick: Integer;
  TeleportDestinationX: Integer;
  TeleportDestinationY: Integer;
  InventoryReservedFlag: byte;
  HasKeyOne: byte;
  HasKeyTwo: byte;
  HasKeyThree: byte;
  PlayerHasFloppyDisk: byte;
  ComputerMessageShown: byte;
  BlastDoorContactHandled: byte;
  CeilingLauncherDisabled: byte;
  BonusStep621Collected: byte;
  BonusStep622Collected: byte;
  BonusPickupOrderValid: byte;
  PlayerGodMode: byte;
  PlayerHasDynamite: byte;
  PlayerDying: byte;
  DeathAnimationTick: byte;
{$IFDEF SAM1}
  reserved_69f7: Byte;
{$ELSE}
  reserved_6a1d: Byte;
{$ENDIF}
  DeathVerticalMotionTable: array[1..35] of Integer;
  PlayerLeavingLevel: byte;
  LevelExitAnimationTick: byte;
  PlayerHealth: byte;
  PlayerDamageGraceActive: byte;
  PlayerDamageGraceTick: byte;
{$IFDEF SAM1}
  reserved_6a43: Byte;
{$ELSE}
  reserved_6a69: Byte;
{$ENDIF}
  PopupInputResult: string;
  GameConfiguration: TGameConfiguration;
{$IFDEF SAM1}
  reserved_6d17: Byte;
{$ELSE}
  reserved_6d3d: Byte;
{$ENDIF}
  GameSnapshot: TGameSnapshot;
  PendingRestoreScanCode: Integer;
  EntrancePlayerX: integer;
  EntrancePlayerY: integer;
  EpisodeBlueprintCollected: byte;
{$IFDEF SAM1}
  reserved_6d67: Byte;
{$ELSE}
  reserved_6d8d: Byte;
{$ENDIF}
  JoystickCenterX: Integer;
  JoystickCenterY: Integer;
  JoystickAxisX: integer;
  JoystickAxisY: integer;
  JoystickHorizontalMoved: byte;
  JoystickVerticalMoved: byte;
  SpriteBank001: PSpriteFileBlock;
  SpriteBank101: PSpriteFileBlock;
  PlayerSpriteBank: PSpriteFileBlock;
  SpriteBank401: PSpriteFileBlock;
  SpriteBank451: PSpriteFileBlock;
  SpriteBank601: PSpriteFileBlock;
  SpriteBank651: PSpriteFileBlock;
  SpriteBank701: PSpriteFileBlock;
  SpriteBank751: PSpriteFileBlock;
  SpriteBank151: PSpriteFileBlock;
  SpriteBank201: PSpriteFileBlock;
  SpriteBank801: PSpriteFileBlock;
  SpriteBank301: PSpriteFileBlock;
  SpriteBank851: PSpriteFileBlock;
  SpriteBank251: PSpriteFileBlock;
  SpriteBank351: PSpriteFileBlock;
  SpriteBankFileViews: TSpriteFileViews;
  StatusGlyphBank: PGlyphFileBlock;
  PopupFrameAndGlyphBank: PGlyphFileBlock;
  PopupExtendedGlyphBank: PGlyphFileBlock;
  GlyphBankFileViews: TGlyphFileViews;
  GameMenuResult: byte;
  JoystickFirePosePending: byte;
  PlayerFalling: byte;
  PlayerJumping: byte;
  PlayerOnMovingSupport: byte;
  PlayerUpHeld: byte;
  PlayerDownHeld: byte;
  EscapePressed: byte;
  QuitGameRequested: byte;
  ReturnToTitleRequested: byte;
  RestoreSnapshotRequested: byte;
  GameTransitionReservedFlag: byte;
  PlayerLeftHeld: byte;
  PlayerRightHeld: byte;
  PopupInputReservedFlag: Byte;
  PlayerJumpHeld: byte;
  UpKeyDisplayText: string[80];
{$IFDEF SAM1}
  reserved_6f1f: Byte;
{$ELSE}
  reserved_6f45: Byte;
{$ENDIF}
  DownKeyDisplayText: string[80];
{$IFDEF SAM1}
  reserved_6f71: Byte;
{$ELSE}
  reserved_6f97: Byte;
{$ENDIF}
  FireKeyDisplayText: string[80];
{$IFDEF SAM1}
  reserved_6fc3: Byte;
{$ELSE}
  reserved_6fe9: Byte;
{$ENDIF}
  RightKeyDisplayText: string[80];
{$IFDEF SAM1}
  reserved_7015: Byte;
{$ELSE}
  reserved_703b: Byte;
{$ENDIF}
  JumpKeyDisplayText: string[80];
{$IFDEF SAM1}
  reserved_7067: Byte;
{$ELSE}
  reserved_708d: Byte;
{$ENDIF}
  LeftKeyDisplayText: string[80];
{$IFDEF SAM1}
  reserved_70b9: Byte;
{$ELSE}
  reserved_70df: Byte;
{$ENDIF}
  UpKeyScanCode: word;
  DownKeyScanCode: word;
  LeftKeyScanCode: word;
  RightKeyScanCode: word;
  FireKeyScanCode: word;
  JumpKeyScanCode: word;
  AlternateVideoTiming: word;
  JoystickSettingEnabled: word;
  SavedExitProc: pointer;
  SavedTimerVector: pointer;
  SavedKeyboardVector: pointer;
{$IFDEF SAM1}
  reserved_70d6: array[0..3] of Byte;
{$ELSE}
  reserved_70fc: array[0..3] of Byte;
{$ENDIF}
procedure InitializeGameDefaults;
procedure ResetNewGameState;
procedure ResetLevelTransientState;
procedure DecryptGameAssetBuffer(var AssetBuffer; AssetByteCount: Word);
implementation
uses Crt;
{$L DECODE.OBJ}
{ Reverses each byte's bit order and XORs a cyclic 28-byte Copyright 1991 Peder Jungck key in place. }
procedure DecryptGameAssetBuffer; external;
{$F+}
{ Installs default keys/high scores, clears session state and fills the jump/death motion tables. }
procedure InitializeGameDefaults;
var
  InitIndex: Integer;
  RankAsLongInt: LongInt;
begin
  for InitIndex := 1 to 25 do
    GameActors[InitIndex].ActorSlotInactive := 1;
  CameraX := 0;
  PgCopyStatusBandTemplate;
  StatusBarCameraX := -1;
  CameraY := 0;
  GameTickCounter := 0;
  AlternateVideoTiming := 0;
  JoystickSettingEnabled := 0;
  UpKeyScanCode := $48;
  DownKeyScanCode := $50;
  LeftKeyScanCode := $4B;
  RightKeyScanCode := $4D;
  FireKeyScanCode := $38;
  JumpKeyScanCode := $1D;
  for InitIndex := 1 to 10 do
  begin
    case InitIndex of
      1: GameConfiguration.ConfigScoreLines[InitIndex] := 'James Bond              200000';
      2: GameConfiguration.ConfigScoreLines[InitIndex] := 'Matt Helm               190000';
      3: GameConfiguration.ConfigScoreLines[InitIndex] := 'Flint                   180000';
      4: GameConfiguration.ConfigScoreLines[InitIndex] := 'Jack Ryan               170000';
      5: GameConfiguration.ConfigScoreLines[InitIndex] := 'Jim Phelps              160000';
      6: GameConfiguration.ConfigScoreLines[InitIndex] := 'Columbo                 150000';
      7: GameConfiguration.ConfigScoreLines[InitIndex] := 'Maxwell Smart           140000';
      8: GameConfiguration.ConfigScoreLines[InitIndex] := 'Frank Drebin            130000';
      9: GameConfiguration.ConfigScoreLines[InitIndex] := 'Underdog                120000';
      10: GameConfiguration.ConfigScoreLines[InitIndex] := 'The A Team              110000';
    end;
    RankAsLongInt := InitIndex;
    GameConfiguration.ConfigRankedScores[InitIndex] := 200000 - (RankAsLongInt - 1) * 10000;
  end;
  JoystickFirePosePending := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  EscapePressed := 0;
  QuitGameRequested := 0;
  ReturnToTitleRequested := 0;
  RestoreSnapshotRequested := 0;
  GameTransitionReservedFlag := 0;
  PlayerOnMovingSupport := 0;
  PlayerJumping := 0;
  PlayerJumpHeld := 0;
  PlayerFalling := 0;
  CurrentLevelNumber := 1;
  GameReservedWord := 0;
  GameDrawBufferRow := $10;
  GameDrawBufferIndex := 0;
  DisplayedBufferRow := 0;
  PlayerHorizontalStep := 0;
  SpecialMovementMode := 1;
  PlayerScore := 0;
  PlayerProgressCount := 1;
  PlayerAmmo := 5;
  PlayerProjectileLimit := 1;
  Pickup31Count := 0;
  for InitIndex := 1 to 15 do
    LevelBlueprintFlags[InitIndex] := 0;
  PlayerSpeedBoost := 0;
  SpeedBoostTimeLeft := 0;
  SpecialMovementDuration := 0;
  PlayerControlsReversed := 0;
  ConfusionTimeLeft := 0;
  ConfusionEndedMessagePending := 0;
  PlayerSlowMovement := 0;
  SlowMovementTimeLeft := 0;
  SavedAuxiliaryCounter := 0;
  CeilingLauncherDisabled := 0;
  PlayerHasFloppyDisk := 0;
  ComputerMessageShown := 0;
  InventoryReservedFlag := 0;
  HasKeyOne := 0;
  HasKeyTwo := 0;
  HasKeyThree := 0;
  PlayerGodMode := 0;
  PlayerHasDynamite := 0;
  BlastDoorContactHandled := 0;
  PlayerInputLocked := 0;
  LevelEntranceAnimationTick := 0;
  EnteredLevelNumber := 1;
  BonusStep621Collected := 0;
  BonusStep622Collected := 0;
  BonusPickupOrderValid := 1;
  for InitIndex := 1 to 20 do
    LevelCompletedFlags[InitIndex] := 0;
  PlayerDying := 0;
  DeathAnimationTick := $23;
  PlayerLeavingLevel := 0;
  LevelExitAnimationTick := 8;
  PlayerHealth := 3;
  PlayerDamageGraceActive := 0;
  PlayerDamageGraceTick := 0;
  LevelRadarDestroyed := 0;
  GameOptionsRequested := 0;
  GodChordPHeld := 0;
  GodChordJHeld := 0;
  GodChordXHeld := 0;
  AmmoChordUHeld := 0;
  AmmoChordVHeld := 0;
  AmmoChordKHeld := 0;
  ExtraAmmoCheatUsed := 0;
  InventoryChordZHeld := 0;
  InventoryChordGHeld := 0;
  InventoryChordIHeld := 0;
  WarpChordOHeld := 0;
  WarpChordNHeld := 0;
  WarpChordDHeld := 0;
  LevelCheatPBHeld := 0;
  WarpLevelRequested := 0;
  GodModeMessagePending := 0;
  TeleportRelocatePending := 0;
  PlayerTeleporting := 0;
  TeleportAnimationTick := 0;
  TeleportDestinationX := 0;
  TeleportDestinationY := 0;
  GameSnapshot.SavedPlayerX := 0;
  GameSnapshot.SavedPlayerY := 0;
  GameSnapshot.SavedPlayerScore := PlayerScore;
  GameSnapshot.SavedProgressCount := PlayerProgressCount;
  GameSnapshot.SavedPlayerAmmo := PlayerAmmo;
  for InitIndex := 1 to 20 do
    GameSnapshot.SavedBlueprintFlags[InitIndex] := LevelBlueprintFlags[InitIndex];
  GameSnapshot.SavedSpeedBoost := PlayerSpeedBoost;
  GameSnapshot.SavedSpeedTimeLeft := SpeedBoostTimeLeft;
  GameSnapshot.SavedControlsReversed := PlayerControlsReversed;
  GameSnapshot.SavedConfusionTimeLeft := ConfusionTimeLeft;
  GameSnapshot.SavedConfusionEndedPending := ConfusionEndedMessagePending;
  GameSnapshot.SavedSlowMovement := PlayerSlowMovement;
  GameSnapshot.SavedSlowTimeLeft := SlowMovementTimeLeft;
  GameSnapshot.SavedAuxiliaryValue := SavedAuxiliaryCounter;
  GameSnapshot.SavedEntranceAnimationTick := LevelEntranceAnimationTick;
  GameSnapshot.SavedEnteredLevelNumber := EnteredLevelNumber;
  for InitIndex := 1 to 20 do
    GameSnapshot.SavedCompletedLevelFlags[InitIndex] := LevelCompletedFlags[InitIndex];
  PendingRestoreScanCode := 0;
  PlayerVerticalMotionTable[1] := 0;
  PlayerVerticalMotionTable[2] := 8;
  PlayerVerticalMotionTable[3] := 8;
  PlayerVerticalMotionTable[4] := 8;
  PlayerVerticalMotionTable[5] := 4;
  PlayerVerticalMotionTable[6] := 4;
  PlayerVerticalMotionTable[7] := 2;
  PlayerVerticalMotionTable[8] := 2;
  PlayerVerticalMotionTable[9] := 2;
  PlayerVerticalMotionTable[10] := 1;
  PlayerVerticalMotionTable[11] := 1;
  PlayerVerticalMotionTable[12] := 2;
  PlayerVerticalMotionTable[13] := 2;
  PlayerVerticalMotionTable[14] := 2;
  PlayerVerticalMotionTable[15] := 4;
  PlayerVerticalMotionTable[16] := 4;
  PlayerVerticalMotionTable[17] := 8;
  PlayerVerticalMotionTable[18] := 8;
  PlayerVerticalMotionTable[19] := 8;
  PlayerVerticalMotionStep := $12;
  AlternateVerticalMotionTable[1] := 0;
  AlternateVerticalMotionTable[2] := 8;
  AlternateVerticalMotionTable[3] := 8;
  AlternateVerticalMotionTable[4] := 6;
  AlternateVerticalMotionTable[5] := 6;
  AlternateVerticalMotionTable[6] := 4;
  AlternateVerticalMotionTable[7] := 4;
  AlternateVerticalMotionTable[8] := 4;
  AlternateVerticalMotionTable[9] := 4;
  AlternateVerticalMotionTable[10] := 4;
  AlternateVerticalMotionTable[11] := 4;
  AlternateVerticalMotionTable[12] := 2;
  AlternateVerticalMotionTable[13] := 2;
  AlternateVerticalMotionTable[14] := 2;
  AlternateVerticalMotionTable[15] := 2;
  AlternateVerticalMotionTable[16] := 2;
  AlternateVerticalMotionTable[17] := 1;
  AlternateVerticalMotionTable[18] := 1;
  AlternateVerticalMotionTable[19] := 1;
  AlternateVerticalMotionTable[20] := 1;
  AlternateVerticalMotionTable[21] := 0;
  AlternateVerticalMotionTable[22] := 0;
  AlternateVerticalMotionTable[23] := 0;
  AlternateVerticalMotionTable[24] := 2;
  AlternateVerticalMotionTable[25] := 2;
  AlternateVerticalMotionTable[26] := 2;
  AlternateVerticalMotionTable[27] := 2;
  AlternateVerticalMotionTable[28] := 4;
  AlternateVerticalMotionTable[29] := 4;
  AlternateVerticalMotionTable[30] := 4;
  AlternateVerticalMotionTable[31] := 4;
  AlternateVerticalMotionTable[32] := 4;
  AlternateVerticalMotionTable[33] := 4;
  AlternateVerticalMotionTable[34] := 4;
  AlternateVerticalMotionTable[35] := 6;
  AlternateVerticalMotionTable[36] := 6;
  AlternateVerticalMotionTable[37] := 8;
  AlternateVerticalMotionTable[38] := 8;
  AlternateVerticalMotionStep := $25;
  DeathVerticalMotionTable[1] := -8;
  DeathVerticalMotionTable[2] := -8;
  DeathVerticalMotionTable[3] := -8;
  DeathVerticalMotionTable[4] := -8;
  DeathVerticalMotionTable[5] := -8;
  DeathVerticalMotionTable[6] := -8;
  DeathVerticalMotionTable[7] := -8;
  DeathVerticalMotionTable[8] := -8;
  DeathVerticalMotionTable[9] := -8;
  DeathVerticalMotionTable[10] := -8;
  DeathVerticalMotionTable[11] := -8;
  DeathVerticalMotionTable[12] := -8;
  DeathVerticalMotionTable[13] := -8;
  DeathVerticalMotionTable[14] := -8;
  DeathVerticalMotionTable[15] := -8;
  DeathVerticalMotionTable[16] := -6;
  DeathVerticalMotionTable[17] := -6;
  DeathVerticalMotionTable[18] := -6;
  DeathVerticalMotionTable[19] := -6;
  DeathVerticalMotionTable[20] := -6;
  DeathVerticalMotionTable[21] := -6;
  DeathVerticalMotionTable[22] := -4;
  DeathVerticalMotionTable[23] := -4;
  DeathVerticalMotionTable[24] := -4;
  DeathVerticalMotionTable[25] := -4;
  DeathVerticalMotionTable[26] := 0;
  DeathVerticalMotionTable[27] := 0;
  DeathVerticalMotionTable[28] := 0;
  DeathVerticalMotionTable[29] := 4;
  DeathVerticalMotionTable[30] := 4;
  DeathVerticalMotionTable[31] := 8;
  DeathVerticalMotionTable[32] := 8;
  DeathVerticalMotionTable[33] := 8;
  DeathVerticalMotionTable[34] := 8;
  DeathVerticalMotionTable[35] := 8;
  EpisodeBlueprintCollected := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Clears game flags, resets score/ammo/level progress and captures the reset snapshot without replacing. }
procedure ResetNewGameState;
var
  ResetIndex: Integer;
begin
  EpisodeBlueprintCollected := 0;
  for ResetIndex := 1 to 25 do
    GameActors[ResetIndex].ActorSlotInactive := 1;
  CameraX := 0;
  PgCopyStatusBandTemplate;
  StatusBarCameraX := -1;
  CameraY := 0;
  GameTickCounter := 0;
  JoystickFirePosePending := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  EscapePressed := 0;
  QuitGameRequested := 0;
  ReturnToTitleRequested := 0;
  RestoreSnapshotRequested := 0;
  GameTransitionReservedFlag := 0;
  PlayerOnMovingSupport := 0;
  PlayerJumping := 0;
  PlayerJumpHeld := 0;
  PlayerFalling := 0;
  CurrentLevelNumber := 1;
  GameReservedWord := 0;
  GameDrawBufferRow := $10;
  GameDrawBufferIndex := 0;
  DisplayedBufferRow := 0;
  PlayerHorizontalStep := 0;
  SpecialMovementMode := 1;
  PlayerScore := 0;
  PlayerProgressCount := 1;
  PlayerAmmo := 5;
  PlayerProjectileLimit := 1;
  Pickup31Count := 0;
  for ResetIndex := 1 to 15 do
    LevelBlueprintFlags[ResetIndex] := 0;
  PlayerSpeedBoost := 0;
  SpeedBoostTimeLeft := 0;
  SpecialMovementDuration := 0;
  PlayerControlsReversed := 0;
  ConfusionTimeLeft := 0;
  ConfusionEndedMessagePending := 0;
  PlayerSlowMovement := 0;
  SlowMovementTimeLeft := 0;
  SavedAuxiliaryCounter := 0;
  CeilingLauncherDisabled := 0;
  PlayerHasFloppyDisk := 0;
  ComputerMessageShown := 0;
  InventoryReservedFlag := 0;
  HasKeyOne := 0;
  HasKeyTwo := 0;
  HasKeyThree := 0;
  PlayerGodMode := 0;
  PlayerHasDynamite := 0;
  BlastDoorContactHandled := 0;
  PlayerInputLocked := 0;
  LevelEntranceAnimationTick := 0;
  EnteredLevelNumber := 1;
  BonusStep621Collected := 0;
  BonusStep622Collected := 0;
  BonusPickupOrderValid := 1;
  for ResetIndex := 1 to 20 do
    LevelCompletedFlags[ResetIndex] := 0;
  PlayerDying := 0;
  DeathAnimationTick := $23;
  LevelRadarDestroyed := 0;
  PlayerLeavingLevel := 0;
  LevelExitAnimationTick := 8;
  PlayerHealth := 3;
  PlayerDamageGraceActive := 0;
  PlayerDamageGraceTick := 0;
  GameOptionsRequested := 0;
  GodChordPHeld := 0;
  GodChordJHeld := 0;
  GodChordXHeld := 0;
  AmmoChordUHeld := 0;
  AmmoChordVHeld := 0;
  AmmoChordKHeld := 0;
  ExtraAmmoCheatUsed := 0;
  InventoryChordZHeld := 0;
  InventoryChordGHeld := 0;
  InventoryChordIHeld := 0;
  WarpChordOHeld := 0;
  WarpChordNHeld := 0;
  WarpChordDHeld := 0;
  LevelCheatPBHeld := 0;
  WarpLevelRequested := 0;
  GodModeMessagePending := 0;
  TeleportRelocatePending := 0;
  PlayerTeleporting := 0;
  TeleportAnimationTick := 0;
  TeleportDestinationX := 0;
  TeleportDestinationY := 0;
  GameSnapshot.SavedPlayerX := 0;
  GameSnapshot.SavedPlayerY := 0;
  GameSnapshot.SavedPlayerScore := PlayerScore;
  GameSnapshot.SavedProgressCount := PlayerProgressCount;
  GameSnapshot.SavedPlayerAmmo := PlayerAmmo;
  for ResetIndex := 1 to 20 do
    GameSnapshot.SavedBlueprintFlags[ResetIndex] := LevelBlueprintFlags[ResetIndex];
  GameSnapshot.SavedSpeedBoost := PlayerSpeedBoost;
  GameSnapshot.SavedSpeedTimeLeft := SpeedBoostTimeLeft;
  GameSnapshot.SavedControlsReversed := PlayerControlsReversed;
  GameSnapshot.SavedConfusionTimeLeft := ConfusionTimeLeft;
  GameSnapshot.SavedConfusionEndedPending := ConfusionEndedMessagePending;
  GameSnapshot.SavedSlowMovement := PlayerSlowMovement;
  GameSnapshot.SavedSlowTimeLeft := SlowMovementTimeLeft;
  GameSnapshot.SavedAuxiliaryValue := SavedAuxiliaryCounter;
  GameSnapshot.SavedEntranceAnimationTick := LevelEntranceAnimationTick;
  GameSnapshot.SavedEnteredLevelNumber := EnteredLevelNumber;
  for ResetIndex := 1 to 20 do
    GameSnapshot.SavedCompletedLevelFlags[ResetIndex] := LevelCompletedFlags[ResetIndex];
  GameSnapshot.SavedExtraAmmoCheatUsed := ExtraAmmoCheatUsed;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Clears the status band, movement/inventory/transition flags and temporary effects while retaining score. }
procedure ResetLevelTransientState;
var
  FrameWord: Word;
begin
  EpisodeBlueprintCollected := 0;
  PgSetDrawColor(0);
  PgFillRectangleByteAligned(0, 80, 0, 8);
  PgCopyStatusBandTemplate;
  StatusBarCameraX := -1;
  JoystickFirePosePending := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  EscapePressed := 0;
  QuitGameRequested := 0;
  ReturnToTitleRequested := 0;
  RestoreSnapshotRequested := 0;
  GameTransitionReservedFlag := 0;
  PlayerOnMovingSupport := 0;
  PlayerJumping := 0;
  PlayerJumpHeld := 0;
  PlayerFalling := 0;
  GameReservedWord := 0;
  PlayerHorizontalStep := 0;
  CeilingLauncherDisabled := 0;
  PlayerHasFloppyDisk := 0;
  ComputerMessageShown := 0;
  InventoryReservedFlag := 0;
  HasKeyOne := 0;
  HasKeyTwo := 0;
  HasKeyThree := 0;
  PlayerHasDynamite := 0;
  BlastDoorContactHandled := 0;
  PlayerInputLocked := 0;
  BonusStep621Collected := 0;
  BonusStep622Collected := 0;
  BonusPickupOrderValid := 1;
  PlayerSpeedBoost := 0;
  SpeedBoostTimeLeft := 0;
  SpecialMovementDuration := 0;
  PlayerControlsReversed := 0;
  ConfusionTimeLeft := 0;
  ConfusionEndedMessagePending := 0;
  PlayerSlowMovement := 0;
  SlowMovementTimeLeft := 0;
  GameOptionsRequested := 0;
  PlayerLeavingLevel := 0;
  LevelExitAnimationTick := 8;
  PlayerHealth := 3;
  PlayerDamageGraceActive := 0;
  PlayerDamageGraceTick := 0;
  PlayerDying := 0;
  DeathAnimationTick := $23;
  LevelRadarDestroyed := 0;
  GodChordPHeld := 0;
  GodChordJHeld := 0;
  GodChordXHeld := 0;
  AmmoChordUHeld := 0;
  AmmoChordVHeld := 0;
  AmmoChordKHeld := 0;
  ExtraAmmoCheatUsed := 0;
  InventoryChordZHeld := 0;
  InventoryChordGHeld := 0;
  InventoryChordIHeld := 0;
  WarpChordOHeld := 0;
  WarpChordNHeld := 0;
  WarpChordDHeld := 0;
  LevelCheatPBHeld := 0;
  WarpLevelRequested := 0;
  GodModeMessagePending := 0;
  TeleportRelocatePending := 0;
  PlayerTeleporting := 0;
  TeleportAnimationTick := 0;
  TeleportDestinationX := 0;
  TeleportDestinationY := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{ The game-data unit initialization block is empty. }
begin
end.
