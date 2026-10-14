{ Shared data unit: defines game state and library data layouts, installs
  defaults, resets game/level state and exposes the asset decoder. }
unit SAMDATA;
{$A+}{$D+}{$L+}{$F-}
interface
uses Dos, PROGRPHX;
const
  { Screen, map and EGA playfield-buffer geometry. }
  GameScreenWidthPixels = 320;
  GameScreenHeightPixels = 200;
  GamePlayfieldHeightPixels = 184;
  GameTileSizePixels = 16;
  GameTilePixelShift = 4;
  GameTileOffsetMask = $000F;
  GameTileAlignMask = $FFF0;
  GameMapColumnCount = 40;
  GameMapRowCount = 25;
  GameMapLastColumn = 39;
  GameMapLastRow = 24;
  GamePlayfieldTopBufferRow = 16;
  GamePlayfieldBottomBufferRow = 416;
  GamePlayfieldBufferRowSum = 432;
  GameCameraMaxX = 320;
  GameCameraMaxY = 184;

  { Fixed game-state capacities and the island's level number. }
  GamePlayerActorSlot = 1;
  GameActorSlotCount = 25;
  GamePlayerShotSlotCount = 10;
  GameLevelFlagSlotCount = 20;
  GameBlueprintResetSlotCount = 15;
  GameMissionsForFortress = 15;
  GameLastMissionLevel = 17;
  GameIslandLevelNumber = 1;

  { Encoded map rows include two trailing bytes outside the encrypted payload. }
  GameLevelRowBytes = 42;
  GameLevelRowPayloadBytes = 40;
  GameLevelSlotRecords = 48;

  { Sprite and PC-speaker resource record dimensions. }
  GameVideoStrideBytes = 80;
  GameSpriteEntriesPerBank = 50;
  GameSpriteHeaderBytes = 3;
  GameSpritePayloadBytes = 157;
  GameGlyphPayloadBytes = 37;
  GameSoundEffectsPerBank = 12;
  GameSoundBankValueCount = 305;
  GameSoundPriorityColumn = 301;

  { PC keyboard make codes used by the default controls. }
  GameScanCodeEscape = $01;
  GameScanCodeControl = $1D;
  GameScanCodeAlt = $38;
  GameScanCodeUp = $48;
  GameScanCodeLeft = $4B;
  GameScanCodeRight = $4D;
  GameScanCodeDown = $50;

  { Sound-bank effect numbers identified by their gameplay callers. }
  GameSfxJump = 1;
  GameSfxScorePickup = 4;
  GameSfxItemPickup = 5;
  GameSfxDoorOpen = 6;
  GameSfxOrderedBonus = 12;
  GameSfxLevelStart = 13;
  GameSfxPlayerDeath = 22;
  GameSfxTeleport = 23;
  GameSfxComputerActivate = 24;
  GameSfxComputerNeedsDisk = 25;
  GameSfxReverseControls = 26;
  GameSfxSlowMovement = 27;
  GameSfxLevelEntrance = 28;

  { Actor kinds used by both placement and gameplay code. }
  GameActorKindPlayer = 99;
  GameActorKindScorePopup = 5001;

  { BIOS keyboard-buffer pointers, addressed through segment zero. }
  GameBiosKeyboardHeadLinear = $041A;
  GameBiosKeyboardTailLinear = $041C;

  { Inventory and death-animation limits used by resets and contact handling. }
  GamePlayerFullHealth = 3;
  GamePlayerAmmoLimit = 99;
  GamePlayerShotPowerLimit = 2;
  GamePlayerDeathFrameCount = 35;

  { Generic backdrop codes are resolved to the selected level's real tiles. }
  GameTileBackdropPlaceholder = 2;
  GameTileBackdropPlusOne = 5;
  GameTileBackdropPlusTwo = 6;
  GameTileBackdropPlusThree = 7;

  { Interactive foreground tile IDs; key/door numbers match inventory slots. }
  GameTileTeleportPad = 183;
  GameTileAmmo = 301;
  GameTileBlueprint = 304;
  GameTileSpeedBoost = 313;
  GameTileShotPower = 314;
  GameTileKeyOne = 421;
  GameTileDoorOne = 422;
  GameTileKeyTwo = 423;
  GameTileDoorTwo = 424;
  GameTileKeyThree = 425;
  GameTileDoorThree = 426;
  GameTileReverseControls = 466;
  GameTileSlowMovement = 468;
  GameTileLaserField = 603;
  GameTileComputer = 604;
  GameTileFloppyDisk = 605;
  GameTileBonusFirst = 621;
  GameTileBonusSecond = 622;
  GameTileBonusThird = 623;
  GameTileDynamite = 635;
  GameTileBlastDoor = 637;
  GameTileMissionExit = 638;

type
  { Game-state, map and save-file records. }
  TLevelFileRow = array[1..GameLevelRowBytes] of Char;

  TGameActor = record
    FlashFrames, ActorWorldX, ActorWorldY, ActorPreviousX, ActorPreviousY, ActorAnimationCounter, ActorCounterA,
    ActorCounterB, ActorKindValue1, StateValueB,
    ActorSpriteBase, ActorDirectionX, DirectionY, ActorMovementStep, ActorKindCode: Integer;
    ActorSlotInactive, ActorRemovalPending: Byte;
  end;

  TLevelCell = record
    CellBaseTile, CellOverlayTile, CellObjectCode: Word;
    CellSolidFlag, SupportsLanding: Byte;
  end;

  TGameConfiguration = packed record
    ConfigScoreLines: array[1..10] of String[40];
    ConfigRankedScores: array[1..10] of LongInt;
    ConfigSoundEnabled: Byte;
    ConfigUpScanCode, ConfigDownScanCode, ConfigLeftScanCode, ConfigRightScanCode, ConfigJumpScanCode,
      ConfigFireScanCode,
    ConfigAlternateVideo, ConfigJoystickEnabled: Word;
  end;

  TGameSnapshot = packed record
    SavedPlayerX, SavedPlayerY: Integer;
    SavedPlayerScore: LongInt;
    SavedProgressCount, SavedPlayerAmmo, SavedProjectileLimit: Integer;
    SavedBlueprintFlags: array[1..GameLevelFlagSlotCount] of Byte;
    SavedSpeedBoost, SavedSpeedTimeLeft: Integer;
    SavedControlsReversed: Byte;
    SavedConfusionTimeLeft: Integer;
    SavedConfusionEndedPending, SavedSlowMovement: Byte;
    SavedSlowTimeLeft, SavedAuxiliaryValue, SavedEntranceAnimationTick, SavedEnteredLevelNumber: Integer;
    SavedCompletedLevelFlags: array[1..GameLevelFlagSlotCount] of Byte;
    SavedExtraAmmoCheatUsed: Byte;
  end;

  { Sound and graphics resource buffers. }
  TSpeakerSoundBank = array[1..GameSoundEffectsPerBank, 1..GameSoundBankValueCount] of Integer;

  PSpeakerSoundBank = ^TSpeakerSoundBank;

  TPopupImageBuffer = array[0..29999] of Byte;

  PPopupImageBuffer = ^TPopupImageBuffer;

  { A sprite record is 160 bytes: three leading bytes and 157 image bytes. }
  TSpriteSlot16 = packed record
    SpriteLeadingBytes: array[1..GameSpriteHeaderBytes] of Byte;
    SpriteDataBytes: array[1..GameSpritePayloadBytes] of Byte;
  end;

  TSpriteFileBlock = packed record
    SpriteEntries: array[1..GameSpriteEntriesPerBank] of TSpriteSlot16;
    SpriteBlockTail: array[1..64] of Byte;
  end;

  PSpriteFileBlock = ^TSpriteFileBlock;

  { An 8x8 glyph record is 40 bytes: three leading bytes and 37 image bytes. }
  TGlyphStride40 = packed record
    GlyphLeadingBytes: array[1..GameSpriteHeaderBytes] of Byte;
    GlyphDataBytes: array[1..GameGlyphPayloadBytes] of Byte;
  end;

  TGlyphFileBlock = packed record
    GlyphEntries: array[1..GameSpriteEntriesPerBank] of TGlyphStride40;
    GlyphBlockTail: array[1..48] of Byte;
  end;

  PGlyphFileBlock = ^TGlyphFileBlock;

  TRawByteView = array[0..32767] of Byte;

  PRawByteView = ^TRawByteView;

  { Genus PCX descriptor and printer records. }
  TPcxIdentity = packed record
    PcxIdentityProduct: array[0..31] of Char;
    PcxIdentityCopyright: array[0..51] of Char;
    PcxIdentityRights: array[0..21] of Char;
    PcxIdentityAuthor: array[0..23] of Char;
    PcxIdentityEmsDriverName: array[0..7] of Char;
  end;

  TPcxDisplayNameTable = array[0..21] of String[20];

  TPcxDisplayInfo = packed record
    PcxDisplayTypeCode: Byte;
    PcxDisplayDescription: String[20];
    PcxDisplayBiosMode, PcxDisplayBitsPerPixel: Byte;
    PcxDisplayWidth, PcxDisplayHeight: Word;
    PcxDisplayScaleX, PcxDisplayScaleY: Byte;
    PcxDisplayVideoSegment, PcxDisplayPageBytes, PcxDisplayDeviceClass: Word;
    PcxDisplayDecodeTarget: Pointer;
    { Unused words retain the PCX descriptor layout. }
    UnusedPcxDisplayWords: array[0..7] of Word;
  end;

  PPcxDisplayInfo = ^TPcxDisplayInfo;

  TPcxReadState = packed record
    PcxReadBufferBytes, PcxReadBufferSegment, PcxReadBufferOffset: Word;
    PcxReadFileHandle: Integer;
    PcxReadPositionHigh, PcxReadPositionLow: Word;
    PcxReadDispatchReady: Byte;
    PcxReadAdapterFlags: array[0..3] of Byte;
  end;

  TPcxPrinterState = packed record
    PcxPrintPortIndex, PcxPrintScaleMode, PcxPrintFormFeedEnabled, PcxPrintResetEnabled, PcxPrintScanlineBytes:
      Word;
    PcxPrintAlternateRow: Byte;
    PcxPrintResetCommand: String[2];
    PcxPrintCopiesCommand: String[5];
    PcxPrintOrientationCommand: String[5];
    PcxPrintMarginCommand: String[7];
    PcxPrintFormFeedCommand: String[5];
    PcxPrintPositionCommand: String[13];
    PcxPrintResolution100: String[7];
    PcxPrintResolution150: String[7];
    PcxPrintResolution300: String[7];
    PcxPrintBeginRasterCommand: String[5];
    PcxPrintEndRasterCommand: String[4];
    PcxPrintScanlineCommand: String[15];
    PcxPrintDecimalDivisors: array[0..9] of LongInt;
  end;

  { File handles and retained local declaration views. }
  TGameConfigFile = file of TGameConfiguration;

  TGameConfigInputFile = file of TGameConfiguration;

{$IFDEF SAM1}
{$ELSE}
  TVideoBiosRegs = record
    case Integer of
      0: (AX, BX, CX, DX, BP, SI, DI, DS, ES, Flags: Word);
      1: (AL, AH, BL, BH, CL, CH, DL, DH: Byte);
  end;

{$ENDIF}
  TMapCellView = record
    BaseTile, MiddleTile, FrontTile: Word;
    BlocksMovement, SupportsLanding: Byte;
  end;

  TForegroundCellView = record
    BaseTile, MiddleTile, FrontTile: Word;
    BlocksMovement, SupportsLanding: Byte;
  end;

  TEncodedLevelFile = file of TLevelFileRow;
  TLevelFileAccess = record
    case Byte of
      0: (RawFile: File);
      1: (RowFile: TEncodedLevelFile);
  end;
{$IFDEF SAM1}

  PVideoFlagByte = ^Byte;
  PVideoFlagPointer = ^Pointer;
{$ENDIF}

  TPopupLineText = String[40];
  TPopupLineWrapper = packed record
    PopupWrappedLine: TPopupLineText;
  end;
  TPopupBufferTail = array[37..32767] of Byte;
  PPopupBufferTail = ^TPopupBufferTail;

  TScrollablePopupLine = String[40];

  PHighScoreByteView = ^Byte;

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

  TSaveGameOutputFile = file of TGameSnapshot;

  TSaveGameInputFile = file of TGameSnapshot;

  TInstructionLine = String[40];

  TMissionBriefingLine = String[40];
  TMissionBriefingRow = array[1..42] of Char;

  TMissionSuccessRow = array[1..42] of Char;

  THighScoreNameText = String[40];

  TWarpLevelText = String[40];

  TSaveMenuLineView = packed record
    SaveMenuWrappedLine: String[40];
  end;

  TRestoreMenuLineView = packed record
    RestoreMenuWrappedLine: String[40];
  end;

  TMainMenuText = array[1..299] of String[40];

  TGameOptionsLine = String[40];

  TMessageLineView = packed record
    MessageWrappedLine: String[40];
  end;
  TPopupStringViews = packed record
    case Byte of
      0: (PopupFullString: String[255]);
      1: (PopupLineString: String[40]);
  end;

  TQuitPromptLinePair = packed record
    QuitPromptFirstLine: String[40];
    QuitPromptSecondLine: String[40];
  end;

  TQuitDestinationText = array[1..6] of String[40];

  TSoundPromptLineView = packed record
    SoundPromptWrappedLine: String[40];
  end;

  TJoystickPromptLinePair = packed record
    JoystickPromptFirstLine: String[40];
    JoystickPromptSecondLine: String[40];
  end;

  TBbsTextLines = array[1..299] of String[40];

  TAboutApogeeLine = String[40];

  TFortressMessageLineView = packed record
    FortressMessageWrappedLine: String[40];
  end;

  TPerfectHealthText = array[1..6] of String[40];
const
  DosExitBorder = #176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176;
var
  { Motion tables, actors and popup state. }
  PlayerVerticalMotionTable: array[1..19] of Byte;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedJumpTablePadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedJumpTablePadLater: Byte;
{$ENDIF}
  AlternateVerticalMotionTable: array[1..38] of Byte;
  PlayerVerticalMotionStep: Byte;
  AlternateVerticalMotionStep: Byte;
  GameActors: array[1..GameActorSlotCount] of TGameActor;
  { Unused storage retains DATA layout. }
  UnusedStartupWord1: Integer;
  { Unused storage retains DATA layout. }
  UnusedStartupWord2: Integer;
  { Unused storage retains DATA layout. }
  UnusedStartupWord3: Integer;
  PopupTextLines: array[1..299] of String[40];
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedPopupTextPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedPopupTextPadLater: Byte;
{$ENDIF}
  PopupSavedBackground: PPopupImageBuffer;
  PopupAcceptedScanCodes: array[1..20] of Byte;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedPopupKeyStorageSam1: array[0..5] of Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedPopupKeyStorageLater: array[0..5] of Byte;
{$ENDIF}
  PopupSelectionScanCode: Word;
  GameOptionsRequested: Byte;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedOptionsPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedOptionsPadLater: Byte;
{$ENDIF}
  { World, camera and frame state. }
  PlayerLandingCount: Integer;
  LevelBackdropTile: Word;
  CurrentLevelNumber: Integer;
  MoveRampTicks: Word;
  PlayerHorizontalStep: Integer;
  VideoStrideResult: Integer;
  LastKeyboardScanCode: Integer;
  SharedLoopIndexA: Integer;
  SharedLoopIndexB: Integer;
  SharedLoopIndexC: Integer;
  GameTickCounter: Integer;
  LoadedActorCount: Integer;
  { Unused storage retains DATA layout. }
  UnusedGameStateWord: Integer;
  StatusBarCameraX: Integer;
  IslandEntranceIndex: Integer;
  SpecialMovementMode: Byte;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedMovementPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedMovementPadLater: Byte;
{$ENDIF}
  CameraX: Integer;
  CameraY: Integer;
  DisplayedBufferRow: Integer;
  GameDrawBufferIndex: Integer;
  GameDrawBufferRow: Integer;
  AllMissionsComplete: Byte;
  { Unused storage retains DATA layout. }
  UnusedLevelStatusByte: Byte;
  LevelBlueprintFlags: array[1..GameLevelFlagSlotCount] of Byte;
  { Player inventory, effects and mission progress. }
  PlayerAmmo: Integer;
  PlayerShots: array[1..GamePlayerShotSlotCount] of TGameActor;
  PlayerScore: LongInt;
  PlayerProgressCount: Integer;
  Pickup31Count: Integer;
  PlayerProjectileLimit: Integer;
  PlayerSpeedBoost: Integer;
  SpeedBoostTimeLeft: Integer;
  SpecialMovementDuration: Integer;
  ConfusionTimeLeft: Integer;
  ConfusionEndedMessagePending: Byte;
  PlayerControlsReversed: Byte;
  SlowMovementTimeLeft: Integer;
  PlayerSlowMovement: Byte;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedSlowMovementPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedSlowMovementPadLater: Byte;
{$ENDIF}
  SavedAuxiliaryCounter: Integer;
  PlayerInputLocked: Byte;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedInputLockPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedInputLockPadLater: Byte;
{$ENDIF}
  LevelEntranceAnimationTick: Integer;
  EnteredLevelNumber: Integer;
  LevelCompletedFlags: array[1..GameLevelFlagSlotCount] of Byte;
  LevelRadarDestroyed: Byte;
  WarpChordOHeld: Byte;
  WarpChordNHeld: Byte;
  WarpChordDHeld: Byte;
  LevelCheatPBHeld: Byte;
  WarpLevelRequested: Byte;
  GodChordPHeld: Byte;
  GodChordJHeld: Byte;
  GodChordXHeld: Byte;
  GodModeMessagePending: Byte;
  TeleportRelocatePending: Byte;
  AmmoChordUHeld: Byte;
  AmmoChordVHeld: Byte;
  AmmoChordKHeld: Byte;
  ExtraAmmoCheatUsed: Byte;
  InventoryChordZHeld: Byte;
  InventoryChordGHeld: Byte;
  InventoryChordIHeld: Byte;
  PlayerTeleporting: Byte;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedTeleportPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedTeleportPadLater: Byte;
{$ENDIF}
  TeleportAnimationTick: Integer;
  TeleportDestinationX: Integer;
  TeleportDestinationY: Integer;
  { Unused storage retains DATA layout. }
  UnusedInventoryFlag: Byte;
  HasKeyOne: Byte;
  HasKeyTwo: Byte;
  HasKeyThree: Byte;
  PlayerHasFloppyDisk: Byte;
  ComputerMessageShown: Byte;
  BlastDoorContactHandled: Byte;
  CeilingLauncherDisabled: Byte;
  BonusStep621Collected: Byte;
  BonusStep622Collected: Byte;
  BonusPickupOrderValid: Byte;
  PlayerGodMode: Byte;
  PlayerHasDynamite: Byte;
  PlayerDying: Byte;
  DeathAnimationTick: Byte;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedDeathStatePadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedDeathStatePadLater: Byte;
{$ENDIF}
  DeathVerticalMotionTable: array[1..GamePlayerDeathFrameCount] of Integer;
  PlayerLeavingLevel: Byte;
  LevelExitAnimationTick: Byte;
  PlayerHealth: Byte;
  PlayerDamageGraceActive: Byte;
  PlayerDamageGraceTick: Byte;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedDamageStatePadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedDamageStatePadLater: Byte;
{$ENDIF}
  { Configuration, saved campaign and joystick calibration. }
  PopupInputResult: String;
  GameConfiguration: TGameConfiguration;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedConfigPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedConfigPadLater: Byte;
{$ENDIF}
  GameSnapshot: TGameSnapshot;
  PendingRestoreScanCode: Integer;
  EntrancePlayerX: Integer;
  EntrancePlayerY: Integer;
  EpisodeBlueprintCollected: Byte;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedBlueprintPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedBlueprintPadLater: Byte;
{$ENDIF}
  JoystickCenterX: Integer;
  JoystickCenterY: Integer;
  JoystickAxisX: Integer;
  JoystickAxisY: Integer;
  JoystickHorizontalMoved: Byte;
  JoystickVerticalMoved: Byte;
  { Sprite and glyph bank handles. }
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
  { Input and scene-transition state. }
  GameMenuResult: Byte;
  JoystickFirePosePending: Byte;
  PlayerFalling: Byte;
  PlayerJumping: Byte;
  PlayerOnMovingSupport: Byte;
  PlayerUpHeld: Byte;
  PlayerDownHeld: Byte;
  EscapePressed: Byte;
  QuitGameRequested: Byte;
  ReturnToTitleRequested: Byte;
  RestoreSnapshotRequested: Byte;
  { Unused storage retains DATA layout. }
  UnusedTransitionFlag: Byte;
  PlayerLeftHeld: Byte;
  PlayerRightHeld: Byte;
  { Unused storage retains DATA layout. }
  UnusedPopupInputFlag: Byte;
  PlayerJumpHeld: Byte;
  { Key descriptions, bindings and saved handlers. }
  UpKeyDisplayText: String[80];
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedUpKeyTextPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedUpKeyTextPadLater: Byte;
{$ENDIF}
  DownKeyDisplayText: String[80];
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedDownKeyTextPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedDownKeyTextPadLater: Byte;
{$ENDIF}
  FireKeyDisplayText: String[80];
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedFireKeyTextPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedFireKeyTextPadLater: Byte;
{$ENDIF}
  RightKeyDisplayText: String[80];
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedRightKeyTextPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedRightKeyTextPadLater: Byte;
{$ENDIF}
  JumpKeyDisplayText: String[80];
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedJumpKeyTextPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedJumpKeyTextPadLater: Byte;
{$ENDIF}
  LeftKeyDisplayText: String[80];
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedLeftKeyTextPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedLeftKeyTextPadLater: Byte;
{$ENDIF}
  UpKeyScanCode: Word;
  DownKeyScanCode: Word;
  LeftKeyScanCode: Word;
  RightKeyScanCode: Word;
  FireKeyScanCode: Word;
  JumpKeyScanCode: Word;
  AlternateVideoTiming: Word;
  JoystickSettingEnabled: Word;
  SavedExitProc: Pointer;
  SavedTimerVector: Pointer;
  SavedKeyboardVector: Pointer;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedVectorStorageSam1: array[0..3] of Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedVectorStorageLater: array[0..3] of Byte;
{$ENDIF}
procedure InitializeGameDefaults;
procedure ResetNewGameState;
procedure ResetLevelTransientState;
procedure DecryptGameAssetBuffer(var AssetBuffer; AssetByteCount: Word);
implementation
uses Crt;

{ Asset decoding. }
{$L DECODE.OBJ}
{ Reverses each byte's bit order and XORs a cyclic 28-byte Copyright 1991 Peder Jungck key in place. }
procedure DecryptGameAssetBuffer; external;

{ Game and level reset routines. }
{$F+}
{ Installs default keys/high scores, clears session state and fills the jump/death motion tables. }
procedure InitializeGameDefaults;
var
  InitIndex: Integer;
  InitialScoreRankLong: LongInt;
begin
  for InitIndex := 1 to GameActorSlotCount do
    GameActors[InitIndex].ActorSlotInactive := 1;
  CameraX := 0;
  PgCopyStatusBandTemplate;
  StatusBarCameraX := -1;
  CameraY := 0;
  GameTickCounter := 0;
  AlternateVideoTiming := 0;
  JoystickSettingEnabled := 0;
  UpKeyScanCode := GameScanCodeUp;
  DownKeyScanCode := GameScanCodeDown;
  LeftKeyScanCode := GameScanCodeLeft;
  RightKeyScanCode := GameScanCodeRight;
  FireKeyScanCode := GameScanCodeAlt;
  JumpKeyScanCode := GameScanCodeControl;
  for InitIndex := 1 to 10 do
  begin
    case InitIndex of
      1:
        GameConfiguration.ConfigScoreLines[InitIndex] := 'James Bond              200000';
      2:
        GameConfiguration.ConfigScoreLines[InitIndex] := 'Matt Helm               190000';
      3:
        GameConfiguration.ConfigScoreLines[InitIndex] := 'Flint                   180000';
      4:
        GameConfiguration.ConfigScoreLines[InitIndex] := 'Jack Ryan               170000';
      5:
        GameConfiguration.ConfigScoreLines[InitIndex] := 'Jim Phelps              160000';
      6:
        GameConfiguration.ConfigScoreLines[InitIndex] := 'Columbo                 150000';
      7:
        GameConfiguration.ConfigScoreLines[InitIndex] := 'Maxwell Smart           140000';
      8:
        GameConfiguration.ConfigScoreLines[InitIndex] := 'Frank Drebin            130000';
      9:
        GameConfiguration.ConfigScoreLines[InitIndex] := 'Underdog                120000';
      10:
        GameConfiguration.ConfigScoreLines[InitIndex] := 'The A Team              110000';
    end;
    InitialScoreRankLong := InitIndex;
    GameConfiguration.ConfigRankedScores[InitIndex] := 200000 - (InitialScoreRankLong - 1) * 10000;
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
  UnusedTransitionFlag := 0;
  PlayerOnMovingSupport := 0;
  PlayerJumping := 0;
  PlayerJumpHeld := 0;
  PlayerFalling := 0;
  CurrentLevelNumber := GameIslandLevelNumber;
  UnusedGameStateWord := 0;
  GameDrawBufferRow := GamePlayfieldTopBufferRow;
  GameDrawBufferIndex := 0;
  DisplayedBufferRow := 0;
  PlayerHorizontalStep := 0;
  SpecialMovementMode := 1;
  PlayerScore := 0;
  PlayerProgressCount := 1;
  PlayerAmmo := 5;
  PlayerProjectileLimit := 1;
  Pickup31Count := 0;
  { Original partial reset preserved: only blueprint slots 1..15 of 20 are cleared. }
  for InitIndex := 1 to GameBlueprintResetSlotCount do
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
  UnusedInventoryFlag := 0;
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
  for InitIndex := 1 to GameLevelFlagSlotCount do
    LevelCompletedFlags[InitIndex] := 0;
  PlayerDying := 0;
  DeathAnimationTick := GamePlayerDeathFrameCount;
  PlayerLeavingLevel := 0;
  LevelExitAnimationTick := 8;
  PlayerHealth := GamePlayerFullHealth;
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
  for InitIndex := 1 to GameLevelFlagSlotCount do
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
  for InitIndex := 1 to GameLevelFlagSlotCount do
    GameSnapshot.SavedCompletedLevelFlags[InitIndex] := LevelCompletedFlags[InitIndex];
  PendingRestoreScanCode := 0;
  { Table entries stay as individual assignments to preserve the original code. }
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
  { This alternate profile has no consumer; its storage and writes are retained. }
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
  { The death arc is read backward from frame 35 down to frame 1. }
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
{ Resets score, inventory and progress, then captures a reset snapshot.
  Configured controls and high scores are retained. }
procedure ResetNewGameState;
var
  ResetIndex: Integer;
begin
  EpisodeBlueprintCollected := 0;
  for ResetIndex := 1 to GameActorSlotCount do
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
  UnusedTransitionFlag := 0;
  PlayerOnMovingSupport := 0;
  PlayerJumping := 0;
  PlayerJumpHeld := 0;
  PlayerFalling := 0;
  CurrentLevelNumber := GameIslandLevelNumber;
  UnusedGameStateWord := 0;
  GameDrawBufferRow := GamePlayfieldTopBufferRow;
  GameDrawBufferIndex := 0;
  DisplayedBufferRow := 0;
  PlayerHorizontalStep := 0;
  SpecialMovementMode := 1;
  PlayerScore := 0;
  PlayerProgressCount := 1;
  PlayerAmmo := 5;
  PlayerProjectileLimit := 1;
  Pickup31Count := 0;
  { Original partial reset preserved: only blueprint slots 1..15 of 20 are cleared. }
  for ResetIndex := 1 to GameBlueprintResetSlotCount do
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
  UnusedInventoryFlag := 0;
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
  for ResetIndex := 1 to GameLevelFlagSlotCount do
    LevelCompletedFlags[ResetIndex] := 0;
  PlayerDying := 0;
  DeathAnimationTick := GamePlayerDeathFrameCount;
  LevelRadarDestroyed := 0;
  PlayerLeavingLevel := 0;
  LevelExitAnimationTick := 8;
  PlayerHealth := GamePlayerFullHealth;
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
  for ResetIndex := 1 to GameLevelFlagSlotCount do
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
  for ResetIndex := 1 to GameLevelFlagSlotCount do
    GameSnapshot.SavedCompletedLevelFlags[ResetIndex] := LevelCompletedFlags[ResetIndex];
  GameSnapshot.SavedExtraAmmoCheatUsed := ExtraAmmoCheatUsed;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}

{$F+}
{ Clears the status band, movement/inventory/transition flags and temporary effects while retaining score. }
procedure ResetLevelTransientState;
var
  { Unused locals retain the original stack frame. }
  UnusedResetWord: Word;
begin
  EpisodeBlueprintCollected := 0;
  PgSetDrawColor(0);
  PgFillRectangleByteAligned(0, GameVideoStrideBytes, 0, 8);
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
  UnusedTransitionFlag := 0;
  PlayerOnMovingSupport := 0;
  PlayerJumping := 0;
  PlayerJumpHeld := 0;
  PlayerFalling := 0;
  UnusedGameStateWord := 0;
  PlayerHorizontalStep := 0;
  CeilingLauncherDisabled := 0;
  PlayerHasFloppyDisk := 0;
  ComputerMessageShown := 0;
  UnusedInventoryFlag := 0;
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
  PlayerHealth := GamePlayerFullHealth;
  PlayerDamageGraceActive := 0;
  PlayerDamageGraceTick := 0;
  PlayerDying := 0;
  DeathAnimationTick := GamePlayerDeathFrameCount;
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
