{ User interface unit: draws the HUD and popups, loads graphics resources,
  and handles menus, settings, saved games and information screens. }
unit SAMUI;
{$A+}{$D+}{$L+}{$F-}
interface
uses SAMDATA;
{$IFDEF SAM1}
function DetectGameVideoAdapter: Char;
{$ENDIF}
procedure ToggleGameDrawBuffer;
procedure ShowGameDrawBuffer;
procedure RestoreGamePalette(PaletteDelayMs: Word);
procedure FadeGamePaletteToBlack(PaletteDelayMs: Word);
procedure DrawGameStatusBar;
procedure ClearPopupText;
procedure DrawGameText(TextColumn, TextRow: Integer; DisplayText: String);
function ReadPopupScanCode(AcceptAnyKey: Byte): Byte;
function ReadPopupText(MaxInputLength: Integer): String;
function ReadScrollablePopupScanCode(AcceptAnyKey: Byte): Byte;
procedure ShowApogeeSplash;
procedure ShowTitleAndCredits;
procedure InsertPlayerHighScore;
procedure LoadGameSpriteBanks;
procedure BlackenGamePalette;
procedure CaptureGameSnapshot;
procedure RestoreGameSnapshot;
procedure WriteSavedGame(SaveSlot: Integer);
function ReadSavedGame(SaveSlot: Integer): Boolean;
procedure ShowGameInstructions;
procedure ShowMissionBriefing;
procedure ShowMissionSuccessText;
procedure AskHighScoreName;
procedure RedefineKeyboardBindings;
function AskWarpLevel: Word;
procedure ShowSaveGameMenu;
function ShowRestoreGameMenu: Integer;
function RunMainMenu: Char;
function RunGameOptionsMenu: Char;
procedure ShowHighScores;
procedure ShowGameMessage(MessageText: String);
procedure ConfirmQuitToDos;
procedure ShowQuitDestinationMenu;
procedure SelectSoundSetting;
procedure SelectVideoCompatibility;
procedure SelectJoystickSetting;
procedure CalibrateJoystickCenter;
function ScanCodeDisplayName(ScanCode: Word): String;
procedure PopupNoOpHook;
procedure ShowOrderContactDetails;
procedure ShowOrderPackageDetails;
procedure ShowOrderingInformation;
procedure ShowForeignDealers;
procedure ShowApogeeBbsInformation;
procedure ShowAboutApogee;
procedure ShowFortressUnlockedMessage;
procedure ShowPerfectHealthBonus;
procedure ShowDosExitScreen;
procedure ShowEpisodeEnding;
implementation
uses Dos, PROGRPHX, Crt, SAMSOUND, GAMEJOY, PCXGENUS, TEXT80;

const
  { Extended keys are accepted on release; these two sentinels are outside make codes. }
  UiIgnoredExtendedKey = 500;
  UiReleasedKeySentinel = 999;

  { Adapter discovery uses INT 11h, INT 10h AX=1B00 and segment-zero EGA flags. }
  UiEquipmentBiosInterrupt = $11;
  UiBiosVideoStateQuery = $1B00;
  UiBiosVideoStateReply = $1B;
  UiBiosEgaFlagsOffset = $0487;

  { Title-image mode, 40-byte image stride and final palette-register index. }
  UiPcxEga320x200 = 2;
  UiPcxGraphicsEnabled = 1;
  UiImageScreenStride = 40;
  UiPaletteLastRegister = 15;

  { Popup capacities, scroll step and animation limits. }
  UiPopupShortLineLimit = 20;
  UiScrollContentRowCap = 16;
  UiScrollPageStep = 17;
  UiPopupAnimationThreshold = 20;
  UiCursorFrameCount = 5;
  UiSparkFrameCount = 4;
  UiCursorGlyphBias = 45;
  UiSparkGlyphBias = 37;

  { Popup-frame glyphs and their data offsets: three header bytes per 40-byte glyph. }
  UiPopupTopLeftGlyph = 1;
  UiPopupTopEdgeGlyph = 2;
  UiPopupTopRightGlyph = 3;
  UiPopupBottomRightGlyph = 4;
  UiPopupBottomLeftGlyph = 5;
  UiPopupLeftEdgeGlyph = 6;
  UiPopupBottomEdgeGlyph = 7;
  UiPopupRightEdgeGlyph = 8;
  UiPopupFillGlyph = 9;
  UiPopupShadowGlyph = 10;
  UiPopupTopLeftData = 3;
  UiPopupTopEdgeData = 43;
  UiPopupTopRightData = 83;
  UiPopupBottomRightData = 123;
  UiPopupBottomLeftData = 163;
  UiPopupLeftEdgeData = 203;
  UiPopupBottomEdgeData = 243;
  UiPopupRightEdgeData = 283;
  UiPopupFillData = 323;
  UiPopupShadowData = 363;

  { HUD digit mapping and inventory/health glyphs in the status bank. }
  UiStatusDigitBias = $2F;
  UiStatusHealthGlyph = 12;
  UiStatusSpeedGlyph = 14;
  UiStatusKeyTwoGlyph = 18;
  UiStatusKeyThreeGlyph = 19;
  UiStatusKeyOneGlyph = 20;
  UiStatusDynamiteGlyph = 21;
  UiStatusFloppyGlyph = 22;

  { High-score display padding and the half-tile bias for saved positions. }
  UiHighScoreNamePadLimit = 22;
  UiSavePositionRoundBias = 8;

  { Screen delays used by menus and the title sequence. }
  UiPaletteStepDelay = 20;
  UiSplashTimeoutTicks = 720;
  UiTitleInitialPauseTicks = 144;
  UiTitlePauseTicks = 432;

{ Video adapter discovery for episode 1. }
{$IFDEF SAM1}
{$F+}
{ INT 10h AX=1B00 distinguishes VGA; the fallback examines BIOS EGA flags and returns V/E/U. }
function DetectGameVideoAdapter: Char;
var
  { Unused locals retain the original stack frame. }
  UnusedVideoProbeByte: Byte;
  BiosRegs: Registers;
  UnusedEquipmentDisplayBits: Word;
  { Unused locals retain the original stack frame. }
  UnusedVideoProbePad: array[1..6] of Byte;
  EgaDisplayFlags: Byte;
  AdapterCode: Char;
  VideoStateBuffer: array[1..64] of Byte;
begin
  BiosRegs.ES := Seg(VideoStateBuffer);
  BiosRegs.DI := Ofs(VideoStateBuffer);
  BiosRegs.AX := UiBiosVideoStateQuery;
  BiosRegs.BX := 0;
  Intr(GameVideoBiosInterrupt, BiosRegs);
  if Lo(BiosRegs.AX) = UiBiosVideoStateReply then
  begin
    AdapterCode := 'V';
  end
  else
  begin
    Intr(UiEquipmentBiosInterrupt, BiosRegs);
    { The equipment-display bits are computed but never consumed; keep the write. }
    UnusedEquipmentDisplayBits := (Lo(BiosRegs.AX) and $30) shr 4;
    EgaDisplayFlags := PVideoFlagByte(PVideoFlagPointer(Ptr(0, UiBiosEgaFlagsOffset))^)^;
    if EgaDisplayFlags <> 0 then
      AdapterCode := 'E'
    else
      AdapterCode := 'U';
  end;
  DetectGameVideoAdapter := AdapterCode;
end;

{ Display buffers, palette and status bar. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$ENDIF}
{$F+}
{ Alternates buffer index GameDrawBufferIndex and draw-row origin GameDrawBufferRow between 16 and 416. }
procedure ToggleGameDrawBuffer;
begin
  if GameDrawBufferIndex = 0 then
  begin
    GameDrawBufferIndex := 1;
    GameDrawBufferRow := GamePlayfieldBottomBufferRow;
  end
  else
  begin
    GameDrawBufferIndex := 0;
    GameDrawBufferRow := GamePlayfieldTopBufferRow;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Pans the display to CameraX and draw-row origin plus CameraY, then records the displayed row origin. }
procedure ShowGameDrawBuffer;
begin
  if AlternateVideoTiming = 0 then
    PgPanDisplayAtRetraceStart(CameraX, GameDrawBufferRow + CameraY)
  else
    PgPanDisplayAtRetraceEnd(CameraX, GameDrawBufferRow + CameraY);
  DisplayedBufferRow := GameDrawBufferRow;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Writes palette registers 0..15 to the standard EGA colors, with a Delay between writes. }
procedure RestoreGamePalette(PaletteDelayMs: Word);
begin
  PgSetPaletteRegister(0, 0);
  Delay(PaletteDelayMs);
  PgSetPaletteRegister(1, 1);
  Delay(PaletteDelayMs);
  PgSetPaletteRegister(2, 2);
  Delay(PaletteDelayMs);
  PgSetPaletteRegister(3, 3);
  Delay(PaletteDelayMs);
  PgSetPaletteRegister(4, 4);
  Delay(PaletteDelayMs);
  PgSetPaletteRegister(5, 5);
  Delay(PaletteDelayMs);
  PgSetPaletteRegister(6, 6);
  Delay(PaletteDelayMs);
  PgSetPaletteRegister(7, 7);
  Delay(PaletteDelayMs);
  PgSetPaletteRegister(8, 16);
  Delay(PaletteDelayMs);
  PgSetPaletteRegister(9, 17);
  Delay(PaletteDelayMs);
  PgSetPaletteRegister(10, 18);
  Delay(PaletteDelayMs);
  PgSetPaletteRegister(11, 19);
  Delay(PaletteDelayMs);
  PgSetPaletteRegister(12, 20);
  Delay(PaletteDelayMs);
  PgSetPaletteRegister(13, 21);
  Delay(PaletteDelayMs);
  PgSetPaletteRegister(14, 22);
  Delay(PaletteDelayMs);
  PgSetPaletteRegister(15, 23);
  Delay(PaletteDelayMs);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Sets each of the sixteen palette registers to zero after a configurable delay. }
procedure FadeGamePaletteToBlack(PaletteDelayMs: Word);
var
  PaletteIndex: Integer;
begin
  for PaletteIndex := 0 to UiPaletteLastRegister do
  begin
    Delay(PaletteDelayMs);
    PgSetPaletteRegister(PaletteIndex, 0);
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Formats the six-digit score, ammo, inventory indicators and health glyphs; handles horizontal pixel
  panning. }
procedure DrawGameStatusBar;
var
  DigitOrHealthIndex: Integer;
  StatusPanPixelOffset: Word;
  ScoreText: String[11];
begin
  PgCopyStatusBandTemplate;
  StatusBarCameraX := CameraX;
  StatusPanPixelOffset := CameraX and GamePlanarBytePixelMask;
  Str(PlayerScore: 6, ScoreText);
  for DigitOrHealthIndex := 1 to 6 do
    if ScoreText[DigitOrHealthIndex] = ' ' then
      ScoreText[DigitOrHealthIndex] := '0';

  if StatusPanPixelOffset = 0 then
  begin
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[1]) - UiStatusDigitBias].GlyphDataBytes[1], 0, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[2]) - UiStatusDigitBias].GlyphDataBytes[1], 1, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[3]) - UiStatusDigitBias].GlyphDataBytes[1], 2, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[4]) - UiStatusDigitBias].GlyphDataBytes[1], 3, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[5]) - UiStatusDigitBias].GlyphDataBytes[1], 4, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[6]) - UiStatusDigitBias].GlyphDataBytes[1], 5, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[13].GlyphDataBytes[1], 12, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[11].GlyphDataBytes[1], 13, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[PlayerAmmo div 10 + 1].GlyphDataBytes[1], 14, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[PlayerAmmo mod 10 + 1].GlyphDataBytes[1], 15, 1);
    if PlayerSpeedBoost > 0 then
      PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[UiStatusSpeedGlyph].GlyphDataBytes[1], 20, 1);
    if PlayerHasDynamite <> 0 then
      PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[UiStatusDynamiteGlyph].GlyphDataBytes[1], 25, 1);
    if HasKeyTwo <> 0 then
      PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[UiStatusKeyTwoGlyph].GlyphDataBytes[1], 27, 1);
    if HasKeyThree <> 0 then
      PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[UiStatusKeyThreeGlyph].GlyphDataBytes[1], 28, 1);
    if HasKeyOne <> 0 then
      PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[UiStatusKeyOneGlyph].GlyphDataBytes[1], 29, 1);
    if PlayerHasFloppyDisk <> 0 then
      PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[UiStatusFloppyGlyph].GlyphDataBytes[1], 30, 1);
    for DigitOrHealthIndex := 1 to Integer(PlayerHealth) do
      PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[UiStatusHealthGlyph].GlyphDataBytes[1], DigitOrHealthIndex + 32,
        1);
  end
  else
  begin
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[1]) - UiStatusDigitBias].GlyphDataBytes[1],
      StatusPanPixelOffset, 1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[2]) - UiStatusDigitBias].GlyphDataBytes[1],
      StatusPanPixelOffset + 8, 1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[3]) - UiStatusDigitBias].GlyphDataBytes[1],
      StatusPanPixelOffset + 16, 1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[4]) - UiStatusDigitBias].GlyphDataBytes[1],
      StatusPanPixelOffset + 24, 1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[5]) - UiStatusDigitBias].GlyphDataBytes[1],
      StatusPanPixelOffset + 32, 1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[6]) - UiStatusDigitBias].GlyphDataBytes[1],
      StatusPanPixelOffset + 40, 1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[13].GlyphDataBytes[1], StatusPanPixelOffset + 96, 1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[11].GlyphDataBytes[1], StatusPanPixelOffset + 104, 1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[PlayerAmmo div 10 + 1].GlyphDataBytes[1],
      StatusPanPixelOffset + 112, 1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[PlayerAmmo mod 10 + 1].GlyphDataBytes[1],
      StatusPanPixelOffset + 120, 1);
    if PlayerSpeedBoost > 0 then
      PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[UiStatusSpeedGlyph].GlyphDataBytes[1],
        StatusPanPixelOffset + 160, 1);
    if PlayerHasDynamite <> 0 then
      PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[UiStatusDynamiteGlyph].GlyphDataBytes[1],
        StatusPanPixelOffset + GameScreenHeightPixels, 1);
    if HasKeyTwo <> 0 then
      PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[UiStatusKeyTwoGlyph].GlyphDataBytes[1],
        StatusPanPixelOffset + 216, 1);
    if HasKeyThree <> 0 then
      PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[UiStatusKeyThreeGlyph].GlyphDataBytes[1],
        StatusPanPixelOffset + 224, 1);
    if HasKeyOne <> 0 then
      PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[UiStatusKeyOneGlyph].GlyphDataBytes[1],
        StatusPanPixelOffset + 232, 1);
    if PlayerHasFloppyDisk <> 0 then
      PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[UiStatusFloppyGlyph].GlyphDataBytes[1],
        StatusPanPixelOffset + 240, 1);
    for DigitOrHealthIndex := 1 to Integer(PlayerHealth) do
      PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[UiStatusHealthGlyph].GlyphDataBytes[1],
        StatusPanPixelOffset + $100 + (Word(DigitOrHealthIndex) shl GameGlyphPixelShift), 1);
  end;
end;

{ Text rendering and interactive popups. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Clears all 299 popup text strings and all 20 accepted scan-code entries. }
procedure ClearPopupText;
var
  LineOrKeyIndex: Integer;
begin
  for LineOrKeyIndex := 1 to GamePopupTextLineCount do
    PopupTextLines[LineOrKeyIndex][0] := #0;
  for LineOrKeyIndex := 1 to GamePopupAcceptedKeyCount do
    PopupAcceptedScanCodes[LineOrKeyIndex] := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Maps characters to 8x8 glyphs or 16x16 item sprites using byte columns.
  Caret marks the popup cursor and is not drawn; unsupported symbols retain the original mapping. }
procedure DrawGameText(TextColumn, TextRow: Integer; DisplayText: String);
var
  CharacterIndex, GlyphIndex: Integer;
  FontCharacterMap: String;
begin
  FontCharacterMap := '~~~~~~~~~~~~~~~~~~|||||||||||||| !"#$%& ()*+,-./0123456789:;' +
    '<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz' +
    #127#128#129#130#131#132#133#134#135#136#137#138#139#140 +
    #141#142#143#144#145#146#147#148#149#150#151#152#153#154 +
    #155#156#157#158#159#160#161#162#163#164#165#166#167#168 +
    #169#170#171#172#173#174#175#176#177#178#179#180#181#182#183#184;
  for CharacterIndex := 1 to Length(DisplayText) do
  begin
    GlyphIndex := Pos(Copy(DisplayText, CharacterIndex, 1), FontCharacterMap);
    if Copy(DisplayText, CharacterIndex, 1) <> '^' then
      if (GlyphIndex >= 93) and (GlyphIndex < 118) then
        PgBlitMasked8x8(PopupExtendedGlyphBank^.GlyphEntries[GlyphIndex - 93 + 21].GlyphDataBytes[1], TextColumn +
          CharacterIndex - 1, (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow)
      else if GlyphIndex <= 72 then
      begin
        case GlyphIndex of
          32 .. 72:
            PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[GlyphIndex - 32 + 10].GlyphDataBytes[1], TextColumn
              + CharacterIndex - 1, (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
        end;
      end
      else if GlyphIndex >= 118 then
      begin
        case GlyphIndex of
          118:
            PgBlitMasked16x16(SpriteBank851^.SpriteEntries[1].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          119:
            PgBlitMasked16x16(SpriteBank851^.SpriteEntries[7].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          120:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[15].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          121:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[16].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          122:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[13].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          123:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          124:
            PgBlitMasked16x16(SpriteBank101^.SpriteEntries[4].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          125:
            PgBlitMasked16x16(SpriteBank101^.SpriteEntries[8].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          126:
            PgBlitMasked16x16(SpriteBank101^.SpriteEntries[34].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          127:
            PgBlitMasked16x16(SpriteBank101^.SpriteEntries[21].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          128:
            PgBlitMasked16x16(SpriteBank401^.SpriteEntries[21].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          129:
            PgBlitMasked16x16(SpriteBank401^.SpriteEntries[23].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          130:
            PgBlitMasked16x16(SpriteBank401^.SpriteEntries[25].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          131:
            PgBlitMasked16x16(SpriteBank401^.SpriteEntries[22].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          132:
            PgBlitMasked16x16(SpriteBank401^.SpriteEntries[24].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          133:
            PgBlitMasked16x16(SpriteBank401^.SpriteEntries[26].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          134:
            PgBlitMasked16x16(SpriteBank401^.SpriteEntries[47].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          135:
            PgBlitMasked16x16(SpriteBank601^.SpriteEntries[4].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          136:
            PgBlitMasked16x16(SpriteBank601^.SpriteEntries[5].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          137:
            PgBlitMasked16x16(SpriteBank601^.SpriteEntries[33].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          138:
            PgBlitMasked16x16(SpriteBank601^.SpriteEntries[37].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          139:
            PgBlitMasked16x16(SpriteBank601^.SpriteEntries[19].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          140:
            PgBlitMasked16x16(SpriteBank601^.SpriteEntries[18].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          141:
            PgBlitMasked16x16(SpriteBank601^.SpriteEntries[20].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          142:
            PgBlitMasked16x16(SpriteBank601^.SpriteEntries[29].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          143:
            PgBlitMasked16x16(SpriteBank601^.SpriteEntries[30].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          144:
            PgBlitMasked16x16(SpriteBank601^.SpriteEntries[31].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          145:
            PgBlitMasked16x16(SpriteBank601^.SpriteEntries[32].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          146:
            PgBlitMasked16x16(SpriteBank601^.SpriteEntries[35].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          147:
            PgBlitMasked16x16(SpriteBank651^.SpriteEntries[25].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          148:
            PgBlitMasked16x16(SpriteBank301^.SpriteEntries[1].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          149:
            PgBlitMasked16x16(SpriteBank301^.SpriteEntries[4].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          150:
            PgBlitMasked16x16(SpriteBank301^.SpriteEntries[13].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          151:
            PgBlitMasked16x16(SpriteBank301^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          152:
            PgBlitMasked16x16(SpriteBank301^.SpriteEntries[16].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          153:
            PgBlitMasked16x16(SpriteBank801^.SpriteEntries[1].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          154:
            PgBlitMasked16x16(SpriteBank801^.SpriteEntries[5].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          155:
            PgBlitMasked16x16(SpriteBank801^.SpriteEntries[32].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          156:
            PgBlitMasked16x16(SpriteBank801^.SpriteEntries[36].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          157:
            PgBlitMasked16x16(SpriteBank801^.SpriteEntries[37].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          158:
            PgBlitMasked16x16(PlayerSpriteBank^.SpriteEntries[2].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          159:
            PgBlitMasked16x16(PlayerSpriteBank^.SpriteEntries[1].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          160:
            PgBlitMasked16x16(SpriteBank351^.SpriteEntries[1].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          161:
            PgBlitMasked16x16(SpriteBank351^.SpriteEntries[9].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          162:
            PgBlitMasked16x16(SpriteBank351^.SpriteEntries[18].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          163:
            PgBlitMasked16x16(SpriteBank351^.SpriteEntries[25].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          164:
            PgBlitMasked16x16(SpriteBank351^.SpriteEntries[36].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          165:
            PgBlitMasked16x16(SpriteBank151^.SpriteEntries[2].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          166:
            PgBlitMasked16x16(SpriteBank151^.SpriteEntries[30].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          167:
            PgBlitMasked16x16(SpriteBank151^.SpriteEntries[33].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          168:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          169:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          170:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          171:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          172:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          173:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          174:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          175:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          176:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          177:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          178:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          179:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          180:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          181:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          182:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
          183:
            PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
              (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
        end;
      end
      else
        PgBlitMasked8x8(PopupExtendedGlyphBank^.GlyphEntries[GlyphIndex - 72].GlyphDataBytes[1], TextColumn +
          CharacterIndex - 1, (TextRow shl GameGlyphPixelShift) + DisplayedBufferRow);
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Centers and draws a popup, waits for a scan code (optionally from PopupAcceptedScanCodes). }
function ReadPopupScanCode(AcceptAnyKey: Byte): Byte;
var
  CursorColumn: Integer;
  CursorRow: Integer;
  CursorFrame: Integer;
  MaxLineColumns: Integer;
  PopupRowCount: Integer;
  LeftColumn: Integer;
  TopRow: Integer;
  RightColumn: Integer;
  BottomRow: Integer;
  { Unused locals retain the original stack frame. }
  UnusedPopupWord: Integer;
  KeyScanCode: Integer;
  SparkColumn: Integer;
  SparkPixelY: Integer;
  SparkFrame: Integer;
  SparkOnTopBorder: Byte;
  SparkActive: Byte;
  KeyAccepted: Byte;
begin
  CursorFrame := 1;
  CursorColumn := 0;
  CursorRow := 0;
  MaxLineColumns := 0;
  PopupRowCount := 0;
  KeyAccepted := 0;
  SparkActive := 0;
  for SharedLoopIndexB := 1 to UiPopupShortLineLimit do
  begin
    if SharedLoopIndexB = 1 then
      MaxLineColumns := Ord(PopupTextLines[SharedLoopIndexB][0]) - 1;
    if Ord(PopupTextLines[SharedLoopIndexB][0]) > MaxLineColumns then
      MaxLineColumns := Ord(PopupTextLines[SharedLoopIndexB][0]) - 1;
    if PopupTextLines[SharedLoopIndexB] = 'END OF WINDOW' then
      PopupRowCount := SharedLoopIndexB - 2;
    for SharedLoopIndexA := 1 to Length(PopupTextLines[SharedLoopIndexB]) do
    begin
      if Copy(PopupTextLines[SharedLoopIndexB], SharedLoopIndexA, 1) = '^' then
      begin
        CursorColumn := Pos('^', PopupTextLines[SharedLoopIndexB]) + 1;
        CursorRow := SharedLoopIndexB + 1;
      end;
    end;
  end;
  Inc(PopupRowCount, 3);
  LeftColumn := (((GameScreenWidthPixels - (MaxLineColumns shl GameGlyphPixelShift)) div 2 + CameraX) div
    GameGlyphSizePixels) - 3;
  TopRow := (((GameScreenHeightPixels - (PopupRowCount shl GameGlyphPixelShift)) div 2 + CameraY) div
    GameGlyphSizePixels) - 2;
  if CursorColumn <> 0 then
    CursorColumn := CursorColumn + LeftColumn;
  CursorRow := CursorRow + TopRow;
  GetMem(PopupSavedBackground, GamePopupBackgroundBytes);
  PgCapturePlanarRectangle(PRawByteView(PopupSavedBackground)^[0], LeftColumn, (TopRow shl GameGlyphPixelShift) +
    DisplayedBufferRow, LeftColumn + MaxLineColumns + 5 + 1, ((TopRow + PopupRowCount + 2 + 1) shl GameGlyphPixelShift)
    + DisplayedBufferRow);
  RightColumn := LeftColumn + MaxLineColumns + 4;
  BottomRow := TopRow + PopupRowCount + 1;

  for SharedLoopIndexC := 1 to BottomRow - TopRow do
    for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
      PgBlitOpaque8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupFillData], SharedLoopIndexB, ((TopRow +
        SharedLoopIndexC) shl GameGlyphPixelShift) + DisplayedBufferRow);
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupTopLeftData], LeftColumn, (TopRow shl
    GameGlyphPixelShift) + DisplayedBufferRow);
  for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupTopEdgeData], SharedLoopIndexB, (TopRow shl
      GameGlyphPixelShift) + DisplayedBufferRow);
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupTopRightData], RightColumn, (TopRow shl
    GameGlyphPixelShift) + DisplayedBufferRow);
  for SharedLoopIndexB := 1 to BottomRow - TopRow do
  begin
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupLeftEdgeData], LeftColumn, ((TopRow +
      SharedLoopIndexB) shl GameGlyphPixelShift) + DisplayedBufferRow);
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupRightEdgeData], RightColumn, ((TopRow +
      SharedLoopIndexB) shl GameGlyphPixelShift) + DisplayedBufferRow);
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupShadowData], RightColumn + 1, ((TopRow +
      SharedLoopIndexB) shl GameGlyphPixelShift) + DisplayedBufferRow);
  end;
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupShadowData], RightColumn + 1, ((BottomRow - TopRow +
    TopRow + 1) shl GameGlyphPixelShift) + DisplayedBufferRow);
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupBottomLeftData], LeftColumn, (BottomRow shl
    GameGlyphPixelShift) + DisplayedBufferRow);
  for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupBottomEdgeData], SharedLoopIndexB, (BottomRow shl
      GameGlyphPixelShift) + DisplayedBufferRow);
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupBottomRightData], RightColumn, (BottomRow shl
    GameGlyphPixelShift) + DisplayedBufferRow);
  for SharedLoopIndexB := LeftColumn + 1 to RightColumn + 1 do
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupShadowData], SharedLoopIndexB, ((BottomRow + 1) shl
      GameGlyphPixelShift) + DisplayedBufferRow);

  for SharedLoopIndexB := 1 to PopupRowCount do
    if PopupTextLines[SharedLoopIndexB] <> 'END OF WINDOW' then
      DrawGameText(LeftColumn + 2, TopRow + SharedLoopIndexB + 1, PopupTextLines[SharedLoopIndexB]);

  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  repeat
    MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  until LastKeyboardScanCode > GameScanCodeBreakMask;
  StartSoundEffect(GameSfxPopupOpen);
  repeat
    repeat
      MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
      SharedLoopIndexB := Random(100);
      if (SparkActive = 0) and (SharedLoopIndexB >= 99) then
      begin
        SparkActive := 1;
        SparkFrame := 0;
        case Random(2) of
          0:
            begin
              SparkColumn := LeftColumn + Random(RightColumn - LeftColumn - 2) + 1;
              SparkPixelY := TopRow shl GameGlyphPixelShift;
              SparkOnTopBorder := 1;
            end;
          1:
            begin
              SparkColumn := LeftColumn;
              SparkPixelY := (TopRow + Random(BottomRow - TopRow - 2) + 1) * GameGlyphSizePixels;
              SparkOnTopBorder := 0;
            end;
        end;
      end;
      if (CursorColumn <> 0) and (GameTickCounter > UiPopupAnimationThreshold) then
      begin
        GameTickCounter := 0;
        PgBlitOpaque8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupFillData], CursorColumn, (CursorRow shl
          GameGlyphPixelShift) + DisplayedBufferRow);
        PgBlitMasked8x8(PopupExtendedGlyphBank^.GlyphEntries[CursorFrame + UiCursorGlyphBias].GlyphDataBytes[1],
          CursorColumn, (CursorRow shl GameGlyphPixelShift) + DisplayedBufferRow);
        Inc(CursorFrame);
        if CursorFrame > UiCursorFrameCount then
          CursorFrame := 1;
        if SparkActive <> 0 then
        begin
          Inc(SparkFrame);
          if SparkFrame > UiSparkFrameCount then
          begin
            SparkActive := 0;
            if SparkOnTopBorder <> 0 then
              PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupTopEdgeData], SparkColumn, SparkPixelY +
                DisplayedBufferRow)
            else
              PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupLeftEdgeData], SparkColumn, SparkPixelY +
                DisplayedBufferRow);
          end
          else
          begin
            if SparkOnTopBorder <> 0 then
              PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupTopEdgeData], SparkColumn, SparkPixelY +
                DisplayedBufferRow)
            else
              PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupLeftEdgeData], SparkColumn, SparkPixelY +
                DisplayedBufferRow);
            PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[SparkFrame + UiSparkGlyphBias].GlyphDataBytes[1],
              SparkColumn, SparkPixelY + DisplayedBufferRow);
          end;
        end;
      end;
    until (LastKeyboardScanCode < GameScanCodeBreakMask) or (LastKeyboardScanCode = GameScanCodeExtendedPrefix);
    { Extended keys are returned after release; retain the original whitelist and sentinels. }
    KeyScanCode := LastKeyboardScanCode;
    if KeyScanCode = GameScanCodeExtendedPrefix then
    begin
      repeat
        MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
      until LastKeyboardScanCode in [GameScanCodeEnterRelease, GameScanCodeControlRelease, GameScanCodeLeftShiftRelease,
        GameScanCodeSlashRelease, GameScanCodeAltRelease, GameScanCodeNumLockRelease, GameScanCodeHomeRelease,
          GameScanCodeUpRelease,
        GameScanCodePageUpRelease, GameScanCodeLeftRelease, GameScanCodeRightRelease, GameScanCodeEndRelease,
          GameScanCodeDownRelease,
        GameScanCodePageDownRelease, GameScanCodeInsertRelease, GameScanCodeDeleteRelease];
      if LastKeyboardScanCode in [GameScanCodeLeftShiftRelease, GameScanCodeNumLockRelease] then
        LastKeyboardScanCode := UiIgnoredExtendedKey;
      KeyScanCode := LastKeyboardScanCode - GameScanCodeBreakMask;
    end
    else
    begin
      repeat
        MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
      until LastKeyboardScanCode > GameScanCodeBreakMask;
    end;

    if AcceptAnyKey = 0 then
    begin
      for SharedLoopIndexB := 1 to GamePopupAcceptedKeyCount do
        if (PopupAcceptedScanCodes[SharedLoopIndexB] <> 0) and (PopupAcceptedScanCodes[SharedLoopIndexB] =
          KeyScanCode) then
        begin
          ReadPopupScanCode := Byte(KeyScanCode);
          KeyAccepted := 1;
        end;
    end
    else
    begin
      ReadPopupScanCode := Byte(KeyScanCode);
      KeyAccepted := 1;
    end;
  until KeyAccepted <> 0;
  PgRestorePlanarRectangle(PopupSavedBackground^[0], LeftColumn, (TopRow shl GameGlyphPixelShift) + DisplayedBufferRow);
  FreeMem(PopupSavedBackground, GamePopupBackgroundBytes);
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  UnusedPopupInputFlag := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Displays a popup and edits a bounded string using printable keys, Backspace and Enter. }
function ReadPopupText(MaxInputLength: Integer): String;
var
  CursorColumn, CursorRow: Integer;
  CursorFrame: Integer;
  MaxLineColumns, PopupRowCount: Integer;
  LeftColumn, TopRow, RightColumn, BottomRow, InputLength: Integer;
  { Unused locals retain the original stack frame. }
  UnusedPopupWord, SparkColumn, SparkPixelY, SparkFrame: Integer;
  SparkOnTopBorder, SparkActive: Byte;
  UnusedPopupTextFramePad: array[0..1] of Byte;
  EditedText: String;
  InputChar: Char;
begin
  CursorFrame := 1;
  CursorColumn := 0;
  MaxLineColumns := 0;
  PopupRowCount := 0;
  { This write has no reader; retain the two-byte local and its original stack slot. }
  UnusedPopupTextFramePad[1] := 0;
  SparkActive := 0;
  for SharedLoopIndexB := 1 to UiPopupShortLineLimit do
  begin
    if SharedLoopIndexB = 1 then
      MaxLineColumns := Length(PopupTextLines[SharedLoopIndexB]) - 1;
    if Length(PopupTextLines[SharedLoopIndexB]) > MaxLineColumns then
      MaxLineColumns := Length(PopupTextLines[SharedLoopIndexB]) - 1;
    if PopupTextLines[SharedLoopIndexB] = 'END OF WINDOW' then
      PopupRowCount := SharedLoopIndexB - 2;
    for SharedLoopIndexA := 1 to Length(PopupTextLines[SharedLoopIndexB]) do
      if Copy(PopupTextLines[SharedLoopIndexB], SharedLoopIndexA, 1) = '^' then
      begin
        CursorColumn := Pos('^', PopupTextLines[SharedLoopIndexB]) + 1;
        CursorRow := SharedLoopIndexB + 1;
      end;
  end;

  Inc(PopupRowCount, 3);
  LeftColumn := ((GameScreenWidthPixels - (MaxLineColumns shl GameGlyphPixelShift)) div 2 + CameraX) div
    GameGlyphSizePixels - 3;
  TopRow := ((GameScreenHeightPixels - (PopupRowCount shl GameGlyphPixelShift)) div 2 + CameraY) div GameGlyphSizePixels - 2;
  CursorColumn := CursorColumn + LeftColumn;
  CursorRow := CursorRow + TopRow;
  GetMem(PopupSavedBackground, GamePopupBackgroundBytes);
  PgCapturePlanarRectangle(PRawByteView(PopupSavedBackground)^, LeftColumn, (TopRow shl GameGlyphPixelShift) +
    DisplayedBufferRow, LeftColumn + MaxLineColumns + 5 + 1, (Succ(TopRow + PopupRowCount + 2) shl GameGlyphPixelShift)
    + DisplayedBufferRow);
  RightColumn := LeftColumn + MaxLineColumns + 4;
  BottomRow := TopRow + PopupRowCount + 1;

  for SharedLoopIndexC := 1 to BottomRow - TopRow do
    for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
      PgBlitOpaque8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupFillData], SharedLoopIndexB, ((TopRow +
        SharedLoopIndexC) shl GameGlyphPixelShift) + DisplayedBufferRow);

  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupTopLeftData], LeftColumn, (TopRow shl
    GameGlyphPixelShift) + DisplayedBufferRow);
  for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupTopEdgeData], SharedLoopIndexB, (TopRow shl
      GameGlyphPixelShift) + DisplayedBufferRow);
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupTopRightData], RightColumn, (TopRow shl
    GameGlyphPixelShift) + DisplayedBufferRow);
  for SharedLoopIndexB := 1 to BottomRow - TopRow do
  begin
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupLeftEdgeData], LeftColumn, ((TopRow +
      SharedLoopIndexB) shl GameGlyphPixelShift) + DisplayedBufferRow);
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupRightEdgeData], RightColumn, ((TopRow +
      SharedLoopIndexB) shl GameGlyphPixelShift) + DisplayedBufferRow);
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupShadowData], RightColumn + 1, ((TopRow +
      SharedLoopIndexB) shl GameGlyphPixelShift) + DisplayedBufferRow);
  end;
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupShadowData], RightColumn + 1, ((TopRow + (BottomRow -
    TopRow) + 1) shl GameGlyphPixelShift) + DisplayedBufferRow);
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupBottomLeftData], LeftColumn, (BottomRow shl
    GameGlyphPixelShift) + DisplayedBufferRow);
  for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupBottomEdgeData], SharedLoopIndexB, (BottomRow shl
      GameGlyphPixelShift) + DisplayedBufferRow);
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupBottomRightData], RightColumn, (BottomRow shl
    GameGlyphPixelShift) + DisplayedBufferRow);
  for SharedLoopIndexB := LeftColumn + 1 to RightColumn + 1 do
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupShadowData], SharedLoopIndexB, ((BottomRow + 1) shl
      GameGlyphPixelShift) + DisplayedBufferRow);

  for SharedLoopIndexB := 1 to PopupRowCount do
    if PopupTextLines[SharedLoopIndexB] <> 'END OF WINDOW' then
      DrawGameText(LeftColumn + 2, TopRow + SharedLoopIndexB + 1, PopupTextLines[SharedLoopIndexB]);

  PlayerUpHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  PlayerDownHeld := 0;
  repeat
    MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  until Port[GameKeyboardDataPort] > GameScanCodeBreakMask;

  EditedText[0] := #0;
  InputLength := 0;
  InputChar := 'Z';
  while InputChar <> #13 do
  begin
    if KeyPressed then
    begin
      InputChar := ReadKey;
      if InputChar in [' ', '0' .. '9', 'A' .. 'Z', 'a' .. 'z'] then
      begin
        if InputChar >= #32 then
        begin
          if InputChar <= #127 then
          begin
            if InputLength < MaxInputLength then
            begin
              EditedText := EditedText + InputChar;
              Inc(InputLength);
              PgBlitOpaque8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupFillData], CursorColumn, (CursorRow shl
                GameGlyphPixelShift) + DisplayedBufferRow);
              DrawGameText(CursorColumn, CursorRow, InputChar);
              Inc(CursorColumn);
            end;
          end;
        end;
      end
      else if InputChar = #8 then
      begin
        if InputLength > 0 then
        begin
          PgBlitOpaque8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupFillData], CursorColumn, (CursorRow shl
            GameGlyphPixelShift) + DisplayedBufferRow);
          Dec(CursorColumn);
          PgBlitOpaque8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupFillData], CursorColumn, (CursorRow shl
            GameGlyphPixelShift) + DisplayedBufferRow);
          Delete(EditedText, Length(EditedText), 1);
          Dec(InputLength);
        end;
      end;
    end;

    SharedLoopIndexB := Random(100);
    if (SparkActive = 0) and (SharedLoopIndexB >= 99) then
    begin
      SparkActive := 1;
      SparkFrame := 0;
      case Random(2) of
        0:
          begin
            SparkColumn := LeftColumn + Random(RightColumn - LeftColumn - 2) + 1;
            SparkPixelY := TopRow shl GameGlyphPixelShift;
            SparkOnTopBorder := 1;
          end;
        1:
          begin
            SparkColumn := LeftColumn;
            SparkPixelY := (TopRow + Random(BottomRow - TopRow - 2) + 1) * GameGlyphSizePixels;
            SparkOnTopBorder := 0;
          end;
      end;
    end;

    if GameTickCounter > UiPopupAnimationThreshold then
    begin
      GameTickCounter := 0;
      PgBlitOpaque8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupFillData], CursorColumn, (CursorRow shl
        GameGlyphPixelShift) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupExtendedGlyphBank^.GlyphEntries[CursorFrame + UiCursorGlyphBias].GlyphDataBytes[1],
        CursorColumn, (CursorRow shl GameGlyphPixelShift) + DisplayedBufferRow);
      Inc(CursorFrame);
      if CursorFrame > UiCursorFrameCount then
        CursorFrame := 1;
      if SparkActive <> 0 then
      begin
        Inc(SparkFrame);
        if SparkFrame > UiSparkFrameCount then
        begin
          SparkActive := 0;
          if SparkOnTopBorder <> 0 then
            PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupTopEdgeData], SparkColumn, SparkPixelY +
              DisplayedBufferRow)
          else
            PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupLeftEdgeData], SparkColumn, SparkPixelY +
              DisplayedBufferRow);
        end
        else
        begin
          if SparkOnTopBorder <> 0 then
            PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupTopEdgeData], SparkColumn, SparkPixelY +
              DisplayedBufferRow)
          else
            PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[UiPopupLeftEdgeData], SparkColumn, SparkPixelY +
              DisplayedBufferRow);
          PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[SparkFrame + UiSparkGlyphBias].GlyphDataBytes[1],
            SparkColumn, SparkPixelY + DisplayedBufferRow);
        end;
      end;
    end;
  end;

  ReadPopupText := EditedText;
  PgRestorePlanarRectangle(PRawByteView(PopupSavedBackground)^, LeftColumn, (TopRow shl GameGlyphPixelShift) +
    DisplayedBufferRow);
  FreeMem(PopupSavedBackground, GamePopupBackgroundBytes);
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  PlayerUpHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  PlayerDownHeld := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Pages through up to 299 text lines on Up/PgUp and Down/PgDn; returns the selected scan code. }
function ReadScrollablePopupScanCode(AcceptAnyKey: Byte): Byte;
var
  { Unused locals retain the original stack frame. }
  CursorColumn, CursorRow, UnusedFirstLine: Integer;
  MaxLineColumns, VisiblePopupRows, TotalTextRows: Integer;
  LeftColumn, TopRow, RightColumn,
  BottomRow: Integer;
  { Unused locals retain the original stack frame. }
  ScrollLineOffset, UnusedPreviousKey, KeyScanCode: Integer;
  SparkColumn, SparkPixelY, SparkFrameIndex: Integer;
  SparkOnTopBorder, IsSparkActive, KeyAccepted: Boolean;
begin
  UnusedFirstLine := 1;
  CursorColumn := 0;
  MaxLineColumns := 0;
  VisiblePopupRows := 0;
  TotalTextRows := 0;
  ScrollLineOffset := 0;
  KeyAccepted := False;
  IsSparkActive := False;
  { END OF WINDOW delimits the text; the cap and 17-line step are original. }
  for SharedLoopIndexB := 1 to GamePopupTextLineCount do
  begin
    if SharedLoopIndexB = 1 then
      MaxLineColumns := Length(PopupTextLines[SharedLoopIndexB]) - 1;
    if Length(PopupTextLines[SharedLoopIndexB]) > MaxLineColumns then
      MaxLineColumns := Length(PopupTextLines[SharedLoopIndexB]) - 1;
    if PopupTextLines[SharedLoopIndexB] = 'END OF WINDOW' then
      VisiblePopupRows := SharedLoopIndexB - 2;
    for SharedLoopIndexA := 1 to Length(PopupTextLines[SharedLoopIndexB]) do
      if Copy(PopupTextLines[SharedLoopIndexB], SharedLoopIndexA, 1) = '^' then
      begin
        CursorColumn := Pos('^', PopupTextLines[SharedLoopIndexB]) + 1;
        CursorRow := SharedLoopIndexB + 1;
      end;
  end;
  TotalTextRows := VisiblePopupRows;
  if VisiblePopupRows > UiScrollContentRowCap then
    VisiblePopupRows := UiScrollContentRowCap;
  Inc(VisiblePopupRows, 3);
  LeftColumn := (((GameScreenWidthPixels - (MaxLineColumns shl GameGlyphPixelShift)) div 2 + CameraX) div
    GameGlyphSizePixels) - 3;
  TopRow := (((GameScreenHeightPixels - (VisiblePopupRows shl GameGlyphPixelShift)) div 2 + CameraY) div
    GameGlyphSizePixels) - 2;
  CursorColumn := CursorColumn + LeftColumn;
  CursorRow := CursorRow + TopRow;
  GetMem(PopupSavedBackground, GamePopupBackgroundBytes);
  PgCapturePlanarRectangle(PopupSavedBackground^, LeftColumn, (TopRow shl GameGlyphPixelShift) + DisplayedBufferRow,
    LeftColumn + MaxLineColumns + 5 + 1, ((TopRow + VisiblePopupRows + 2 + 1) shl GameGlyphPixelShift) +
    DisplayedBufferRow);
  RightColumn := LeftColumn + MaxLineColumns + 4;
  BottomRow := TopRow + VisiblePopupRows + 1;
  for SharedLoopIndexC := 1 to BottomRow - TopRow do
    for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
      PgBlitOpaque8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupFillGlyph].GlyphDataBytes[1], SharedLoopIndexB,
        ((TopRow + SharedLoopIndexC) shl GameGlyphPixelShift) + DisplayedBufferRow);
  PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupTopLeftGlyph].GlyphDataBytes[1], LeftColumn, (TopRow
    shl GameGlyphPixelShift) + DisplayedBufferRow);
  for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
    PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupTopEdgeGlyph].GlyphDataBytes[1], SharedLoopIndexB,
      (TopRow shl GameGlyphPixelShift) + DisplayedBufferRow);
  PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupTopRightGlyph].GlyphDataBytes[1], RightColumn, (TopRow
    shl GameGlyphPixelShift) + DisplayedBufferRow);
  for SharedLoopIndexB := 1 to BottomRow - TopRow do
  begin
    PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupLeftEdgeGlyph].GlyphDataBytes[1], LeftColumn,
      ((TopRow + SharedLoopIndexB) shl GameGlyphPixelShift) + DisplayedBufferRow);
    PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupRightEdgeGlyph].GlyphDataBytes[1], RightColumn,
      ((TopRow + SharedLoopIndexB) shl GameGlyphPixelShift) + DisplayedBufferRow);
    PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupShadowGlyph].GlyphDataBytes[1], RightColumn + 1,
      ((TopRow + SharedLoopIndexB) shl GameGlyphPixelShift) + DisplayedBufferRow);
  end;
  PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupShadowGlyph].GlyphDataBytes[1], RightColumn + 1,
    ((BottomRow - TopRow + TopRow + 1) shl GameGlyphPixelShift) + DisplayedBufferRow);
  PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupBottomLeftGlyph].GlyphDataBytes[1], LeftColumn,
    (BottomRow shl GameGlyphPixelShift) + DisplayedBufferRow);
  for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
    PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupBottomEdgeGlyph].GlyphDataBytes[1], SharedLoopIndexB,
      (BottomRow shl GameGlyphPixelShift) + DisplayedBufferRow);
  PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupBottomRightGlyph].GlyphDataBytes[1], RightColumn,
    (BottomRow shl GameGlyphPixelShift) + DisplayedBufferRow);
  for SharedLoopIndexB := LeftColumn + 1 to RightColumn + 1 do
    PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupShadowGlyph].GlyphDataBytes[1], SharedLoopIndexB,
      ((BottomRow + 1) shl GameGlyphPixelShift) + DisplayedBufferRow);
  for SharedLoopIndexB := 1 to VisiblePopupRows - 2 do
    if PopupTextLines[SharedLoopIndexB] <> 'END OF WINDOW' then
      DrawGameText(LeftColumn + 2, TopRow + SharedLoopIndexB + 1, PopupTextLines[SharedLoopIndexB]);
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  repeat
    MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  until LastKeyboardScanCode > GameScanCodeBreakMask;
  repeat
    repeat
      MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
      SharedLoopIndexB := Random(100);
      if (not IsSparkActive) and (SharedLoopIndexB >= 99) then
      begin
        IsSparkActive := True;
        SparkFrameIndex := 0;
        case Random(2) of
          0:
            begin
              SparkColumn := LeftColumn + Random(RightColumn - LeftColumn - 2) + 1;
              SparkPixelY := TopRow shl GameGlyphPixelShift;
              SparkOnTopBorder := True;
            end;
          1:
            begin
              SparkColumn := LeftColumn;
              SparkPixelY := (TopRow + Random(BottomRow - TopRow - 2) + 1) * GameGlyphSizePixels;
              SparkOnTopBorder := False;
            end;
        end;
      end;
      if (CursorColumn <> 0) and (GameTickCounter > UiPopupAnimationThreshold) then
      begin
        GameTickCounter := 0;
        if IsSparkActive then
        begin
          Inc(SparkFrameIndex);
          if SparkFrameIndex > UiSparkFrameCount then
          begin
            IsSparkActive := False;
            if SparkOnTopBorder then
              PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupTopEdgeGlyph].GlyphDataBytes[1],
                SparkColumn, SparkPixelY + DisplayedBufferRow)
            else
              PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupLeftEdgeGlyph].GlyphDataBytes[1],
                SparkColumn, SparkPixelY + DisplayedBufferRow);
          end
          else
          begin
            if SparkOnTopBorder then
              PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupTopEdgeGlyph].GlyphDataBytes[1],
                SparkColumn, SparkPixelY + DisplayedBufferRow)
            else
              PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupLeftEdgeGlyph].GlyphDataBytes[1],
                SparkColumn, SparkPixelY + DisplayedBufferRow);
            PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[SparkFrameIndex +
              UiSparkGlyphBias].GlyphDataBytes[1], SparkColumn, SparkPixelY + DisplayedBufferRow);
          end;
        end;
      end;
    until (LastKeyboardScanCode < GameScanCodeBreakMask) or (LastKeyboardScanCode = GameScanCodeExtendedPrefix);
    { Extended keys are returned after release; retain the original whitelist and sentinels. }
    KeyScanCode := LastKeyboardScanCode;
    if KeyScanCode = GameScanCodeExtendedPrefix then
    begin
      repeat
        MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
      until Byte(LastKeyboardScanCode) in [GameScanCodeEnterRelease, GameScanCodeControlRelease, GameScanCodeLeftShiftRelease,
        GameScanCodeSlashRelease, GameScanCodeAltRelease, GameScanCodeNumLockRelease, GameScanCodeHomeRelease,
          GameScanCodeUpRelease,
        GameScanCodePageUpRelease, GameScanCodeLeftRelease, GameScanCodeRightRelease, GameScanCodeEndRelease,
          GameScanCodeDownRelease,
        GameScanCodePageDownRelease, GameScanCodeInsertRelease, GameScanCodeDeleteRelease];
      if Byte(LastKeyboardScanCode) in [GameScanCodeLeftShiftRelease, GameScanCodeNumLockRelease] then
        LastKeyboardScanCode := UiIgnoredExtendedKey;
      KeyScanCode := LastKeyboardScanCode - GameScanCodeBreakMask;
    end
    else
      repeat
        MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
      until LastKeyboardScanCode > GameScanCodeBreakMask;
    if (KeyScanCode = GameScanCodeDown) or (KeyScanCode = GameScanCodePageDown) then
    begin
      Inc(ScrollLineOffset, UiScrollPageStep);
      if TotalTextRows - UiScrollContentRowCap < ScrollLineOffset then
        ScrollLineOffset := TotalTextRows - UiScrollContentRowCap;
      for SharedLoopIndexC := 1 to BottomRow - TopRow - 1 do
        for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
          PgBlitOpaque8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupFillGlyph].GlyphDataBytes[1], SharedLoopIndexB,
            ((TopRow + SharedLoopIndexC) shl GameGlyphPixelShift) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupTopLeftGlyph].GlyphDataBytes[1], LeftColumn,
        (TopRow shl GameGlyphPixelShift) + DisplayedBufferRow);
      for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupTopEdgeGlyph].GlyphDataBytes[1], SharedLoopIndexB,
          (TopRow shl GameGlyphPixelShift) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupTopRightGlyph].GlyphDataBytes[1], RightColumn,
        (TopRow shl GameGlyphPixelShift) + DisplayedBufferRow);
      for SharedLoopIndexB := 1 to BottomRow - TopRow do
      begin
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupLeftEdgeGlyph].GlyphDataBytes[1], LeftColumn,
          ((TopRow + SharedLoopIndexB) shl GameGlyphPixelShift) + DisplayedBufferRow);
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupRightEdgeGlyph].GlyphDataBytes[1], RightColumn,
          ((TopRow + SharedLoopIndexB) shl GameGlyphPixelShift) + DisplayedBufferRow);
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupShadowGlyph].GlyphDataBytes[1], RightColumn + 1,
          ((TopRow + SharedLoopIndexB) shl GameGlyphPixelShift) + DisplayedBufferRow);
      end;
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupShadowGlyph].GlyphDataBytes[1], RightColumn + 1,
        ((BottomRow - TopRow + TopRow + 1) shl GameGlyphPixelShift) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupBottomLeftGlyph].GlyphDataBytes[1], LeftColumn,
        (BottomRow shl GameGlyphPixelShift) + DisplayedBufferRow);
      for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupBottomEdgeGlyph].GlyphDataBytes[1],
          SharedLoopIndexB, (BottomRow shl GameGlyphPixelShift) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupBottomRightGlyph].GlyphDataBytes[1], RightColumn,
        (BottomRow shl GameGlyphPixelShift) + DisplayedBufferRow);
      for SharedLoopIndexB := LeftColumn + 1 to RightColumn + 1 do
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupShadowGlyph].GlyphDataBytes[1], SharedLoopIndexB,
          ((BottomRow + 1) shl GameGlyphPixelShift) + DisplayedBufferRow);
      for SharedLoopIndexB := 1 to VisiblePopupRows - 2 do
        if PopupTextLines[SharedLoopIndexB] <> 'END OF WINDOW' then
          DrawGameText(LeftColumn + 2, TopRow + SharedLoopIndexB + 1, PopupTextLines[SharedLoopIndexB +
            ScrollLineOffset]);
    end;
    if (KeyScanCode = GameScanCodeUp) or (KeyScanCode = GameScanCodePageUp) then
    begin
      Dec(ScrollLineOffset, UiScrollPageStep);
      if ScrollLineOffset < 0 then
        ScrollLineOffset := 0;
      for SharedLoopIndexC := 1 to BottomRow - TopRow - 1 do
        for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
          PgBlitOpaque8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupFillGlyph].GlyphDataBytes[1], SharedLoopIndexB,
            ((TopRow + SharedLoopIndexC) shl GameGlyphPixelShift) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupTopLeftGlyph].GlyphDataBytes[1], LeftColumn,
        (TopRow shl GameGlyphPixelShift) + DisplayedBufferRow);
      for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupTopEdgeGlyph].GlyphDataBytes[1], SharedLoopIndexB,
          (TopRow shl GameGlyphPixelShift) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupTopRightGlyph].GlyphDataBytes[1], RightColumn,
        (TopRow shl GameGlyphPixelShift) + DisplayedBufferRow);
      for SharedLoopIndexB := 1 to BottomRow - TopRow do
      begin
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupLeftEdgeGlyph].GlyphDataBytes[1], LeftColumn,
          ((TopRow + SharedLoopIndexB) shl GameGlyphPixelShift) + DisplayedBufferRow);
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupRightEdgeGlyph].GlyphDataBytes[1], RightColumn,
          ((TopRow + SharedLoopIndexB) shl GameGlyphPixelShift) + DisplayedBufferRow);
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupShadowGlyph].GlyphDataBytes[1], RightColumn + 1,
          ((TopRow + SharedLoopIndexB) shl GameGlyphPixelShift) + DisplayedBufferRow);
      end;
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupShadowGlyph].GlyphDataBytes[1], RightColumn + 1,
        ((BottomRow - TopRow + TopRow + 1) shl GameGlyphPixelShift) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupBottomLeftGlyph].GlyphDataBytes[1], LeftColumn,
        (BottomRow shl GameGlyphPixelShift) + DisplayedBufferRow);
      for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupBottomEdgeGlyph].GlyphDataBytes[1],
          SharedLoopIndexB, (BottomRow shl GameGlyphPixelShift) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupBottomRightGlyph].GlyphDataBytes[1], RightColumn,
        (BottomRow shl GameGlyphPixelShift) + DisplayedBufferRow);
      for SharedLoopIndexB := LeftColumn + 1 to RightColumn + 1 do
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[UiPopupShadowGlyph].GlyphDataBytes[1], SharedLoopIndexB,
          ((BottomRow + 1) shl GameGlyphPixelShift) + DisplayedBufferRow);
      for SharedLoopIndexB := 1 to VisiblePopupRows - 2 do
        if PopupTextLines[SharedLoopIndexB] <> 'END OF WINDOW' then
          DrawGameText(LeftColumn + 2, TopRow + SharedLoopIndexB + 1, PopupTextLines[SharedLoopIndexB +
            ScrollLineOffset]);
    end;
    if AcceptAnyKey = 0 then
    begin
      for SharedLoopIndexB := 1 to GamePopupAcceptedKeyCount do
        if (PopupAcceptedScanCodes[SharedLoopIndexB] <> 0) and (PopupAcceptedScanCodes[SharedLoopIndexB] =
          KeyScanCode) then
        begin
          ReadScrollablePopupScanCode := KeyScanCode;
          KeyAccepted := True;
        end;
    end
    else
    begin
      ReadScrollablePopupScanCode := KeyScanCode;
      KeyAccepted := True;
    end;
  until KeyAccepted;
  PgRestorePlanarRectangle(PopupSavedBackground^, LeftColumn, (TopRow shl GameGlyphPixelShift) + DisplayedBufferRow);
  FreeMem(PopupSavedBackground, GamePopupBackgroundBytes);
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  UnusedPopupInputFlag := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
end;

{ Startup screens and high-score insertion. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Loads SAMn.APO, fades in the palette and waits for a key or a timer timeout. }
procedure ShowApogeeSplash;
var
  { Unused locals retain the original stack frame. }
  UnusedSplashWord1, UnusedSplashWord2, GraphicsCallResult, UnusedSplashWord4: Word;
begin
  FadeGamePaletteToBlack(0);
  GraphicsCallResult := PcxSetDisplayType(UiPcxEga320x200);
  GraphicsCallResult := PcxSetGraphicsOrTextMode(UiPcxGraphicsEnabled);
  GraphicsCallResult := PgSetScreenStride(UiImageScreenStride);
  CameraX := 0;
  CameraY := 0;
  DisplayedBufferRow := 0;
  GameDrawBufferRow := 0;
{$IFDEF SAM2}
  GraphicsCallResult := PcxDisplayFile('sam2.apo', 1, 0, 0);
{$ELSE}
{$IFDEF SAM3}
  GraphicsCallResult := PcxDisplayFile('sam3.apo', 1, 0, 0);
{$ELSE}
  GraphicsCallResult := PcxDisplayFile('sam1.apo', 1, 0, 0);
{$ENDIF}
{$ENDIF}
  RestoreGamePalette(UiPaletteStepDelay);
  StartSoundEffect(GameSfxApogeeSplash);
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  GameTickCounter := 0;
  repeat
  until KeyPressed or (GameTickCounter > UiSplashTimeoutTicks);
  GameTickCounter := 0;
  FadeGamePaletteToBlack(0);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Loads SAMn.CRD and SAMn.TTL, vertically pans between them, and handles the main-menu result. }
procedure ShowTitleAndCredits;
var
  PanDirection, PanDistance, GraphicsCallResult: Integer;
  MenuAction: Char;
begin
  FadeGamePaletteToBlack(0);
  GraphicsCallResult := PcxSetDisplayType(UiPcxEga320x200);
  GraphicsCallResult := PcxSetGraphicsOrTextMode(UiPcxGraphicsEnabled);
  GraphicsCallResult := PgSetScreenStride(UiImageScreenStride);
  CameraX := 0;
  CameraY := 0;
  DisplayedBufferRow := 0;
  GameDrawBufferRow := 0;
{$IFDEF SAM2}
  GraphicsCallResult := PcxDisplayFile('sam2.crd', 1, 0, 0);
{$ELSE}
{$IFDEF SAM3}
  GraphicsCallResult := PcxDisplayFile('sam3.crd', 1, 0, 0);
{$ELSE}
  GraphicsCallResult := PcxDisplayFile('sam1.crd', 1, 0, 0);
{$ENDIF}
{$ENDIF}
  PgCopyVideoScreenRegion320x200(0, 0, 0, GameScreenHeightPixels);
{$IFDEF SAM2}
  GraphicsCallResult := PcxDisplayFile('sam2.ttl', 1, 0, 0);
{$ELSE}
{$IFDEF SAM3}
  GraphicsCallResult := PcxDisplayFile('sam3.ttl', 1, 0, 0);
{$ELSE}
  GraphicsCallResult := PcxDisplayFile('sam1.ttl', 1, 0, 0);
{$ENDIF}
{$ENDIF}
  RestoreGamePalette(UiPaletteStepDelay);
  PanDirection := 1;
  PanDistance := 0;
  LastKeyboardScanCode := 0;
  MenuAction := ' ';
  GameTickCounter := 0;
  repeat
    if LastKeyboardScanCode > 0 then
    begin
      MenuAction := RunMainMenu;
      LastKeyboardScanCode := 0;
    end
    else
      LastKeyboardScanCode := 0;
  until (GameTickCounter > UiTitleInitialPauseTicks) or (MenuAction <> ' ');
  if (MenuAction <> 'B') and (MenuAction <> 'R') and (MenuAction <> 'Q') then
    repeat
      if (MenuAction <> 'B') and (MenuAction <> 'R') and (MenuAction <> 'Q') then
        MenuAction := ' ';
      if PanDirection = 1 then
      begin
        if AlternateVideoTiming = 0 then
          PgPanDisplayAtRetraceStart(0, PanDistance)
        else
          PgPanDisplayAtRetraceEnd(0, PanDistance);
        DisplayedBufferRow := PanDistance;
      end
      else
      begin
        if AlternateVideoTiming = 0 then
          PgPanDisplayAtRetraceStart(0, GameScreenHeightPixels - PanDistance)
        else
          PgPanDisplayAtRetraceEnd(0, GameScreenHeightPixels - PanDistance);
        DisplayedBufferRow := GameScreenHeightPixels - PanDistance;
      end;
      Inc(PanDistance);
      if PanDistance > GameScreenHeightPixels then
      begin
        PanDistance := 0;
        PanDirection := -PanDirection;
        GameTickCounter := 0;
        repeat
          if LastKeyboardScanCode > 0 then
          begin
            MenuAction := RunMainMenu;
            LastKeyboardScanCode := 0;
            GameTickCounter := 0;
          end;
        until (GameTickCounter > UiTitlePauseTicks) or (MenuAction <> ' ');
      end;
      PlayerUpHeld := 0;
      PlayerDownHeld := 0;
      PlayerLeftHeld := 0;
      PlayerRightHeld := 0;
      EscapePressed := 0;
      MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
      if LastKeyboardScanCode <> 0 then
      begin
        MenuAction := RunMainMenu;
        GameTickCounter := 0;
        LastKeyboardScanCode := 0;
      end;
    until (MenuAction = 'B') or (MenuAction = 'R') or (MenuAction = 'Q');
  StartSoundEffect(GameSfxOrderedBonus);
  FadeGamePaletteToBlack(0);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Compares the score to ten ranked scores, shifts lower entries and asks for the player's name. }
procedure InsertPlayerHighScore;
var
  RankIndex: Integer;
  InsertRank: Integer;
  FormattedScore: String[255];
begin
  if PlayerScore > GameConfiguration.ConfigRankedScores[GameHighScoreCount] then
  begin
    AskHighScoreName;
    for RankIndex := GameHighScoreCount downto 1 do
      if GameConfiguration.ConfigRankedScores[RankIndex] < PlayerScore then
        InsertRank := RankIndex;
    if InsertRank < GameHighScoreCount then
      for RankIndex := GameHighScoreCount downto InsertRank + 1 do
      begin
        GameConfiguration.ConfigRankedScores[RankIndex] := GameConfiguration.ConfigRankedScores[RankIndex - 1];
        GameConfiguration.ConfigScoreLines[RankIndex] := GameConfiguration.ConfigScoreLines[RankIndex - 1];
      end;
    { Original inclusive padding loop adds one more space than the usual width calculation. }
    for RankIndex := Ord(PopupInputResult[0]) to UiHighScoreNamePadLimit do
      PopupInputResult := PopupInputResult + ' ';
    Str(PlayerScore: 7, FormattedScore);
    PopupInputResult := PopupInputResult + FormattedScore;
    GameConfiguration.ConfigRankedScores[InsertRank] := PlayerScore;
    GameConfiguration.ConfigScoreLines[InsertRank] := PopupInputResult;
    ShowHighScores;
  end;
end;

{ Graphics resources and palette reset. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Reads and decrypts sixteen 8064-byte banks from SAMn01.GFX and three glyph banks from SAMn02.GFX. }
procedure LoadGameSpriteBanks;
begin
{$IFDEF SAM1}
  Assign(SpriteBankFileViews.SpriteUntypedFile, 'SAM101.GFX');
{$ENDIF}
{$IFDEF SAM2}
  Assign(SpriteBankFileViews.SpriteUntypedFile, 'SAM201.GFX');
{$ENDIF}
{$IFDEF SAM3}
  Assign(SpriteBankFileViews.SpriteUntypedFile, 'SAM301.GFX');
{$ENDIF}
  Reset(SpriteBankFileViews.SpriteUntypedFile, GameSpriteBankBytes);
  GetMem(SpriteBank851, GameSpriteBankBytes);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank851^);
  DecryptGameAssetBuffer(SpriteBank851^, GameSpriteBankBytes);
  GetMem(SpriteBank001, GameSpriteBankBytes);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank001^);
  DecryptGameAssetBuffer(SpriteBank001^, GameSpriteBankBytes);
  GetMem(SpriteBank101, GameSpriteBankBytes);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank101^);
  DecryptGameAssetBuffer(SpriteBank101^, GameSpriteBankBytes);
  GetMem(SpriteBank401, GameSpriteBankBytes);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank401^);
  DecryptGameAssetBuffer(SpriteBank401^, GameSpriteBankBytes);
  GetMem(SpriteBank451, GameSpriteBankBytes);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank451^);
  DecryptGameAssetBuffer(SpriteBank451^, GameSpriteBankBytes);
  GetMem(SpriteBank601, GameSpriteBankBytes);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank601^);
  DecryptGameAssetBuffer(SpriteBank601^, GameSpriteBankBytes);
  GetMem(SpriteBank651, GameSpriteBankBytes);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank651^);
  DecryptGameAssetBuffer(SpriteBank651^, GameSpriteBankBytes);
  GetMem(SpriteBank701, GameSpriteBankBytes);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank701^);
  DecryptGameAssetBuffer(SpriteBank701^, GameSpriteBankBytes);
  GetMem(SpriteBank751, GameSpriteBankBytes);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank751^);
  DecryptGameAssetBuffer(SpriteBank751^, GameSpriteBankBytes);
  GetMem(SpriteBank301, GameSpriteBankBytes);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank301^);
  DecryptGameAssetBuffer(SpriteBank301^, GameSpriteBankBytes);
  GetMem(SpriteBank151, GameSpriteBankBytes);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank151^);
  DecryptGameAssetBuffer(SpriteBank151^, GameSpriteBankBytes);
  GetMem(SpriteBank201, GameSpriteBankBytes);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank201^);
  DecryptGameAssetBuffer(SpriteBank201^, GameSpriteBankBytes);
  GetMem(SpriteBank801, GameSpriteBankBytes);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank801^);
  DecryptGameAssetBuffer(SpriteBank801^, GameSpriteBankBytes);
  GetMem(PlayerSpriteBank, GameSpriteBankBytes);
  Read(SpriteBankFileViews.SpriteTypedFile, PlayerSpriteBank^);
  DecryptGameAssetBuffer(PlayerSpriteBank^, GameSpriteBankBytes);
  GetMem(SpriteBank351, GameSpriteBankBytes);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank351^);
  DecryptGameAssetBuffer(SpriteBank351^, GameSpriteBankBytes);
  GetMem(SpriteBank251, GameSpriteBankBytes);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank251^);
  DecryptGameAssetBuffer(SpriteBank251^, GameSpriteBankBytes);
  Close(SpriteBankFileViews.SpriteUntypedFile);
{$IFDEF SAM1}
  Assign(GlyphBankFileViews.GlyphUntypedFile, 'SAM102.GFX');
{$ENDIF}
{$IFDEF SAM2}
  Assign(GlyphBankFileViews.GlyphUntypedFile, 'SAM202.GFX');
{$ENDIF}
{$IFDEF SAM3}
  Assign(GlyphBankFileViews.GlyphUntypedFile, 'SAM302.GFX');
{$ENDIF}
  Reset(GlyphBankFileViews.GlyphUntypedFile, GameGlyphBankBytes);
  GetMem(PopupFrameAndGlyphBank, GameGlyphBankBytes);
  Read(GlyphBankFileViews.GlyphTypedFile, PopupFrameAndGlyphBank^);
  DecryptGameAssetBuffer(PopupFrameAndGlyphBank^, GameGlyphBankBytes);
  GetMem(PopupExtendedGlyphBank, GameGlyphBankBytes);
  Read(GlyphBankFileViews.GlyphTypedFile, PopupExtendedGlyphBank^);
  DecryptGameAssetBuffer(PopupExtendedGlyphBank^, GameGlyphBankBytes);
  GetMem(StatusGlyphBank, GameGlyphBankBytes);
  Read(GlyphBankFileViews.GlyphTypedFile, StatusGlyphBank^);
  DecryptGameAssetBuffer(StatusGlyphBank^, GameGlyphBankBytes);
  Close(GlyphBankFileViews.GlyphUntypedFile);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Immediately writes zero to all sixteen EGA palette registers. }
procedure BlackenGamePalette;
var
  PaletteIndex: Integer;
begin
  for PaletteIndex := 0 to UiPaletteLastRegister do
    PgSetPaletteRegister(PaletteIndex, 0);
end;

{ Campaign snapshots and save files. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Copies player position, score, ammo, level flags and powerup state into GameSnapshot. }
procedure CaptureGameSnapshot;
var
  LevelFlagIndex: Integer;
begin
  GameSnapshot.SavedPlayerX := GameActors[GamePlayerActorSlot].ActorWorldX;
  GameSnapshot.SavedPlayerY := GameActors[GamePlayerActorSlot].ActorWorldY;
  GameSnapshot.SavedPlayerScore := PlayerScore;
  GameSnapshot.SavedPickup269Count := Pickup269Count;
  GameSnapshot.SavedPlayerAmmo := PlayerAmmo;
  GameSnapshot.SavedProjectileLimit := PlayerProjectileLimit;
  for LevelFlagIndex := 1 to GameLevelFlagSlotCount do
    GameSnapshot.SavedBlueprintFlags[LevelFlagIndex] := LevelBlueprintFlags[LevelFlagIndex];
  GameSnapshot.SavedSpeedBoost := PlayerSpeedBoost;
  GameSnapshot.SavedSpeedTimeLeft := SpeedBoostTimeLeft;
  GameSnapshot.SavedControlsReversed := PlayerControlsReversed;
  GameSnapshot.SavedConfusionTimeLeft := ConfusionTimeLeft;
  GameSnapshot.SavedConfusionEndedPending := ConfusionEndedMessagePending;
  GameSnapshot.SavedSlowMovement := PlayerSlowMovement;
  GameSnapshot.SavedSlowTimeLeft := SlowMovementTimeLeft;
  GameSnapshot.SavedAuxiliaryValue := SnapshotAuxiliaryValue;
  GameSnapshot.SavedEntranceProgress := LevelEntranceProgress;
  GameSnapshot.SavedEnteredLevelNumber := EnteredLevelNumber;
  for LevelFlagIndex := 1 to GameLevelFlagSlotCount do
    GameSnapshot.SavedCompletedLevelFlags[LevelFlagIndex] := LevelCompletedFlags[LevelFlagIndex];
  GameSnapshot.SavedExtraAmmoCheatUsed := ExtraAmmoCheatUsed;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Copies GameSnapshot back to the live player and game state. }
procedure RestoreGameSnapshot;
var
  LevelFlagIndex: Integer;
begin
  GameActors[GamePlayerActorSlot].ActorWorldX := GameSnapshot.SavedPlayerX;
  GameActors[GamePlayerActorSlot].ActorWorldY := GameSnapshot.SavedPlayerY;
  PlayerScore := GameSnapshot.SavedPlayerScore;
  Pickup269Count := GameSnapshot.SavedPickup269Count;
  PlayerAmmo := GameSnapshot.SavedPlayerAmmo;
  PlayerProjectileLimit := GameSnapshot.SavedProjectileLimit;
  for LevelFlagIndex := 1 to GameLevelFlagSlotCount do
    LevelBlueprintFlags[LevelFlagIndex] := GameSnapshot.SavedBlueprintFlags[LevelFlagIndex];
  PlayerSpeedBoost := GameSnapshot.SavedSpeedBoost;
  SpeedBoostTimeLeft := GameSnapshot.SavedSpeedTimeLeft;
  PlayerControlsReversed := GameSnapshot.SavedControlsReversed;
  ConfusionTimeLeft := GameSnapshot.SavedConfusionTimeLeft;
  ConfusionEndedMessagePending := GameSnapshot.SavedConfusionEndedPending;
  PlayerSlowMovement := GameSnapshot.SavedSlowMovement;
  SlowMovementTimeLeft := GameSnapshot.SavedSlowTimeLeft;
  SnapshotAuxiliaryValue := GameSnapshot.SavedAuxiliaryValue;
  LevelEntranceProgress := GameSnapshot.SavedEntranceProgress;
  EnteredLevelNumber := GameSnapshot.SavedEnteredLevelNumber;
  for LevelFlagIndex := 1 to GameLevelFlagSlotCount do
    LevelCompletedFlags[LevelFlagIndex] := GameSnapshot.SavedCompletedLevelFlags[LevelFlagIndex];
  ExtraAmmoCheatUsed := GameSnapshot.SavedExtraAmmoCheatUsed;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Snaps the player position to tile boundaries and writes the game record to SAMn-<slot>.SAV. }
procedure WriteSavedGame(SaveSlot: Integer);
var
  SaveOutputFile: TSaveGameOutputFile;
  LevelFlagIndex: Word;
  SlotNumberText: String;
begin
  GameSnapshot.SavedPlayerX := LongInt(GameActors[GamePlayerActorSlot].ActorWorldX + UiSavePositionRoundBias) and
    GameTileAlignMask;
  GameSnapshot.SavedPlayerY := LongInt(GameActors[GamePlayerActorSlot].ActorWorldY + UiSavePositionRoundBias) and
    GameTileAlignMask;
  GameSnapshot.SavedPlayerScore := PlayerScore;
  GameSnapshot.SavedPickup269Count := Pickup269Count;
  GameSnapshot.SavedPlayerAmmo := PlayerAmmo;
  GameSnapshot.SavedProjectileLimit := PlayerProjectileLimit;
  for LevelFlagIndex := 1 to GameLevelFlagSlotCount do
    GameSnapshot.SavedBlueprintFlags[LevelFlagIndex] := LevelBlueprintFlags[LevelFlagIndex];
  GameSnapshot.SavedSpeedBoost := PlayerSpeedBoost;
  GameSnapshot.SavedSpeedTimeLeft := SpeedBoostTimeLeft;
  GameSnapshot.SavedControlsReversed := PlayerControlsReversed;
  GameSnapshot.SavedConfusionTimeLeft := ConfusionTimeLeft;
  GameSnapshot.SavedConfusionEndedPending := ConfusionEndedMessagePending;
  GameSnapshot.SavedSlowMovement := PlayerSlowMovement;
  GameSnapshot.SavedSlowTimeLeft := SlowMovementTimeLeft;
  GameSnapshot.SavedAuxiliaryValue := SnapshotAuxiliaryValue;
  GameSnapshot.SavedEntranceProgress := LevelEntranceProgress;
  GameSnapshot.SavedEnteredLevelNumber := EnteredLevelNumber;
  for LevelFlagIndex := 1 to GameLevelFlagSlotCount do
    GameSnapshot.SavedCompletedLevelFlags[LevelFlagIndex] := LevelCompletedFlags[LevelFlagIndex];
  GameSnapshot.SavedExtraAmmoCheatUsed := ExtraAmmoCheatUsed;

  Str(SaveSlot: 1, SlotNumberText);
{$IFDEF SAM1}
  Assign(SaveOutputFile, 'SAM1-' + SlotNumberText + '.SAV');
{$ENDIF}
{$IFDEF SAM2}
  Assign(SaveOutputFile, 'SAM2-' + SlotNumberText + '.SAV');
{$ENDIF}
{$IFDEF SAM3}
  Assign(SaveOutputFile, 'SAM3-' + SlotNumberText + '.SAV');
{$ENDIF}
  Rewrite(SaveOutputFile);
  Write(SaveOutputFile, GameSnapshot);
  Close(SaveOutputFile);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Restores SAMn-<slot>.SAV; an open failure shows File Not Found and returns False. }
function ReadSavedGame(SaveSlot: Integer): Boolean;
var
  SaveInputFile: TSaveGameInputFile;
  LevelFlagIndex: Integer;
  SlotNumberText: String;
  FileOpenSucceeded: Boolean;
begin
  Str(SaveSlot: 1, SlotNumberText);
{$I-}
{$IFDEF SAM1}
  Assign(SaveInputFile, 'SAM1-' + SlotNumberText + '.SAV');
{$ENDIF}
{$IFDEF SAM2}
  Assign(SaveInputFile, 'SAM2-' + SlotNumberText + '.SAV');
{$ENDIF}
{$IFDEF SAM3}
  Assign(SaveInputFile, 'SAM3-' + SlotNumberText + '.SAV');
{$ENDIF}
  { Preserve the original duplicate Reset and IOResult check, even after a successful open. }
  Reset(SaveInputFile);
  FileOpenSucceeded := IOResult = 0;
  Reset(SaveInputFile);
  FileOpenSucceeded := IOResult = 0;

  if FileOpenSucceeded then
  begin
    Read(SaveInputFile, GameSnapshot);
    Close(SaveInputFile);
    GameActors[GamePlayerActorSlot].ActorWorldX := GameSnapshot.SavedPlayerX;
    GameActors[GamePlayerActorSlot].ActorWorldY := GameSnapshot.SavedPlayerY;
    PlayerScore := GameSnapshot.SavedPlayerScore;
    Pickup269Count := GameSnapshot.SavedPickup269Count;
    PlayerAmmo := GameSnapshot.SavedPlayerAmmo;
    PlayerProjectileLimit := GameSnapshot.SavedProjectileLimit;
    for LevelFlagIndex := 1 to GameLevelFlagSlotCount do
      LevelBlueprintFlags[LevelFlagIndex] := GameSnapshot.SavedBlueprintFlags[LevelFlagIndex];
    PlayerSpeedBoost := GameSnapshot.SavedSpeedBoost;
    SpeedBoostTimeLeft := GameSnapshot.SavedSpeedTimeLeft;
    PlayerControlsReversed := GameSnapshot.SavedControlsReversed;
    ConfusionTimeLeft := GameSnapshot.SavedConfusionTimeLeft;
    ConfusionEndedMessagePending := GameSnapshot.SavedConfusionEndedPending;
    PlayerSlowMovement := GameSnapshot.SavedSlowMovement;
    SlowMovementTimeLeft := GameSnapshot.SavedSlowTimeLeft;
    SnapshotAuxiliaryValue := GameSnapshot.SavedAuxiliaryValue;
    LevelEntranceProgress := GameSnapshot.SavedEntranceProgress;
    EnteredLevelNumber := GameSnapshot.SavedEnteredLevelNumber;
    for LevelFlagIndex := 1 to GameLevelFlagSlotCount do
      LevelCompletedFlags[LevelFlagIndex] := GameSnapshot.SavedCompletedLevelFlags[LevelFlagIndex];
    ExtraAmmoCheatUsed := GameSnapshot.SavedExtraAmmoCheatUsed;
    ReadSavedGame := True;
  end
  else
  begin
    ShowGameMessage('File Not Found!');
    ReadSavedGame := False;
  end;
{$I+}
end;

{ Instructions and mission pages. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Builds CONTROLLING AGENT 006, item, enemy, health and playing-tip pages and invokes the scrolling popup. }
procedure ShowGameInstructions;
var
  TextLineIndex: Word;
begin
  ClearPopupText;
  TextLineIndex := 0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'CONTROLLING AGENT 006     Pg. 1';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '         '#167'       '#168'  ';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Key                     Action';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'ALT  (Button 1)         FIRE';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'CTRL (Button 0)         JUMP';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'ARROW KEYS              MOVE';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'You start in keyboard mode.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press F1 during the game to';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'use the joystick, redefine the';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'keyboard or any other option.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'SHORT BRIEFING            Pg. 2';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Your mission is to infiltrate';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'the island fortress and';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'retrieve the missing satellite';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'blueprints.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '                  '#131' '#132;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'The main fortress      is well';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'guarded and you will have to';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'destroy the security radars '#174;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'on each level in order to';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'access it.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'ITEMS OF INTEREST         Pg. 3';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #137'  Keys match colored doors. '#140;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #157'  Extra shots';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #159'  Extra speed';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #160'  Gun power-up';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #156'  Pushable barrel.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'ITEMS OF INTEREST         Pg. 4';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #174'  Security radar. Destroy it.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #175'  Teleporter. Takes you to a';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   different spot on a level.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #176;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #155'  Dynamite.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #158'  Blueprints.  The object of';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   your mission.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'ITEMS OF INTEREST         Pg. 5';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #146'  Level exit doors.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #147;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #144'  Computer terminal.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #145'  Floppy disk.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'You will have to determine how';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'to use these objects, 006.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'BONUS ITEMS               Pg. 6';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'There are many bonuses to grab';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'as you play.  There are even a';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'couple of hidden ones.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #148'  Money bag.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #149'  Briefcase.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #150'  Toothpaste for that pearly';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   white superhero smile.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'BONUS ITEMS               Pg. 7';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #151'  Magnifying glass.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #152'  Computer card.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #154'  Spy watch.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #153'  Walkie-Talkie.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #161'  Teddy Bear.  The bonus of';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   choice with Commander Keen.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Enemies                   Pg. 8';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'You will face many types of ';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Dr. No Body@s security force.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Following is a description';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'of each.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #169'  Guard - Armed only with a';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   knife. Very little threat.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #170'  Sentry - Slightly stronger';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   than a guard, but no match';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   for your skills.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Enemies                   Pg. 9';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #171'  Ninja - Highly trained in';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   the art of Ninja. Watch out.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #172'  Ninja Master - A very deadly';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   enemy. Has ability to shoot.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #173'  Thug - The most deadly human';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   enemy. Can fire at will.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'These enemies are deadly, but';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'the bureau has obtained details';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'on the robotic enemies as well.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Robotic Enemies          Pg. 10';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #166'  This robot moves along the';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   ceiling and fires at you.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #135'  A flying robot that shoots';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   deadly electricity downward.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #136'  A ground based tank that has';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   very heavy armor plating.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #162;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   Robbie the Robot. Don@t get';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #163'  this enemy angry at you.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Robotic Enemies          Pg. 11';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #164;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   This robot is difficult to';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #165'  destroy and fires at you.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #133'  This half man-half robot ';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   has only one weakness.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #134;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := #127' '#128'  This robot dog is not';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '     man@s best friend.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Player Health            Pg. 12';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'When you start a new level, you';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'will begin with three health';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'hits, designated by three';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'pictures of your man on the';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'status line.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Each time you are hit, your';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'health decreases.  If you get';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'hit three times then you must';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'restart the level in order to';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'complete it.  You have infinite';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'men in order to win the game.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Playing Tips             Pg. 13';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '* Some barrels can be pushed.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '* Use Save and Restore (F1) to';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  save your progress.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '* Watch the robots carefully.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  They have certain weaknesses.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '* If you get stuck in a level,';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  then use the QUIT option to';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  the island map and restart.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Playing Tips             Pg. 14';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '* You can only carry ONE key of';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  each color at a time.  For';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  example, you CAN@T carry two';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  blue keys at the same time.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  You must use one first.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '* Conserve shots.  You may need';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  them later.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '* Avoid exploding dynamite.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '- END OF FILE...';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := GameScanCodeEscape;
  PopupSelectionScanCode := ReadScrollablePopupScanCode(0);
  EscapePressed := 0;
  GameOptionsRequested := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Builds CONFIDENTIAL/BACKGROUND FILE and YOUR MISSION pages describing the blueprints and DVS. }
procedure ShowMissionBriefing;
var
  TextLineIndex: Integer;
begin
  ClearPopupText;
  TextLineIndex := 1;
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'CONFIDENTIAL FILE         Pg. 1';
{$ELSE}
  PopupTextLines[TextLineIndex] := 'BACKGROUND FILE           Pg. 1';
{$ENDIF}
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'To:        Agent 006';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Priority:  For Your Eyes Only';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '**Destroy file after reading**';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Our government scientists have';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'been working on a secret';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'project: A ruby-powered laser';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'satellite with the ability to';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'pinpoint and fire upon any';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'target from Earth orbit, code';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'named "Red Rock Rover".';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
{$IFNDEF SAM1}
  PopupTextLines[TextLineIndex] := 'MISSION UPDATE            Pg. 2';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
{$IFDEF SAM2}
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '006 successfully infiltrated';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'DVS headquarters on the first';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'island, and gained possession of';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'the first of three blueprints.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Using a jet raft, 006 has';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'landed upon the second island';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'fortress, and must find the';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'next blueprint to the "Red Rock';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Rover" weapon.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
{$ELSE}
  PopupTextLines[TextLineIndex] := '006 has destroyed the DVS';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'headquarters on the first and';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'second island fortresses, and';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'secured possession of two';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'crucial blueprints.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Using scuba gear, 006 slipped';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'past the security net set up';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'around the final island.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Getting the final blueprint';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'will be the most dangerous';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'assignment yet, since this';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'island id the DVS stronghold!';
  Inc(TextLineIndex);
{$ENDIF}
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
{$ENDIF}
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'YOUR MISSION              Pg. 2';
{$ELSE}
  PopupTextLines[TextLineIndex] := 'YOUR MISSION              Pg. 3';
{$ENDIF}
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Two weeks ago the blueprints';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'were stolen by the Diabolical';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Villain Society (DVS), which';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'will use them to build the';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'ultimate terrorist threat.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'You@ve been chosen by the';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Bureau to infiltrate DVS';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'headquarters and secure the';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'blueprints.  The headquarters';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'are located on a series of';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'islands in the Pacific basin.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'YOUR MISSION              Pg. 3';
{$ELSE}
  PopupTextLines[TextLineIndex] := 'YOUR MISSION              Pg. 4';
{$ENDIF}
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Your mission, should you choose';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'to accept it, is to bring back';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'the secret blueprints to the';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '"Red Rock Rover" project.  You';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'will be isolated from outside';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'help.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'You should be warned that this';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'mission is of global importance';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'and must succeed in order to';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'maintain a balance of world';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'power.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'YOUR MISSION              Pg. 4';
{$ELSE}
  PopupTextLines[TextLineIndex] := 'YOUR MISSION              Pg. 5';
{$ENDIF}
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'We do not have a file on the';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'head of DVS, but he is';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'suspected to be very cunning';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'and dangerous.  DVS';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'headquarters are built up';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'as an elaborate series of';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'fortresses on three well';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'guarded islands.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'As always, should you be caught';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'the Bureau will disavow any';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'knowledge of your existence.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := GameScanCodeEscape;
  PopupSelectionScanCode := ReadScrollablePopupScanCode(0);
  EscapePressed := 0;
  GameOptionsRequested := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Builds MISSION SUCCESSFUL and HOW TO ORDER MORE GAMES pages for the current episode. }
procedure ShowMissionSuccessText;
var
  TextLineIndex: Integer;
begin
  ClearPopupText;
  TextLineIndex := 1;
  PopupTextLines[TextLineIndex] := 'MISSION SUCCESSFUL        Pg. 1';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Congratulations 006, you have';
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'successfully destroyed the';
{$ELSE}
  PopupTextLines[TextLineIndex] := 'successfully infiltrated DVS';
{$ENDIF}
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'first DVS headquarters and';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[TextLineIndex] := 'headquarters on the island,';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[TextLineIndex] := 'headquarters on the last island';
{$ENDIF}
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'retrieved the first blueprint.';
{$ELSE}
  PopupTextLines[TextLineIndex] := 'and gained possession of the';
{$ENDIF}
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := '';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[TextLineIndex] := 'second blueprint.  The Bureau';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[TextLineIndex] := 'final blueprint.';
{$ENDIF}
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'The Bureau has hidden a jet';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[TextLineIndex] := 'has hidden scuba gear on the';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[TextLineIndex] := '';
{$ENDIF}
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'raft on the island that you can';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[TextLineIndex] := 'island that you must use to';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[TextLineIndex] := 'Dr. No Body and the DVS have';
{$ENDIF}
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'use to reach the second island';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[TextLineIndex] := 'reach the third island';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[TextLineIndex] := 'all been stopped and the world';
{$ENDIF}
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'fortress.  Once there, you will';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[TextLineIndex] := 'fortress.  Once there, you will';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[TextLineIndex] := 'is once again safe, well for a';
{$ENDIF}
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'overcome new dangers and traps';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[TextLineIndex] := 'overcome new dangers and traps';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[TextLineIndex] := 'few more days anyway...';
{$ENDIF}
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'to secure the second blueprint';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[TextLineIndex] := 'to secure the final blueprint';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[TextLineIndex] := '';
{$ENDIF}
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'to the "Red Rock Rover" weapon.';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[TextLineIndex] := 'to the "Red Rock Rover" weapon.';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[TextLineIndex] := '';
{$ENDIF}
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'HOW TO ORDER MORE GAMES   Pg. 2';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '';
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'Be sure to play the next two';
{$ELSE}
  PopupTextLines[TextLineIndex] := 'Be sure to play all the';
{$ENDIF}
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'exciting missions, otherwise';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'the world will fall prey to the';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'evil intentions of the DVS!';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '';
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'The next two missions are:';
{$ELSE}
  PopupTextLines[TextLineIndex] := 'Get all the Secret Agent games:';
{$ENDIF}
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '';
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := ' * Kill Again Island';
{$ELSE}
  PopupTextLines[TextLineIndex] := ' * The Hunt For Red Rock Rover';
{$ENDIF}
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := ' * Dr. No Body';
{$ELSE}
  PopupTextLines[TextLineIndex] := ' * Kill Again Island';
{$ENDIF}
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := '';
{$ELSE}
  PopupTextLines[TextLineIndex] := ' * Dr. No Body';
{$ENDIF}
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'HOW TO ORDER MORE GAMES   Pg. 3';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '';
  Inc(TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[TextLineIndex] := 'In these two missions you will';
{$ELSE}
  PopupTextLines[TextLineIndex] := 'In the other missions you will';
{$ENDIF}
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'encounter all-new challenges,';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'hazards, henchmen, levels,';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'puzzles, prizes, and basically';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'put to test all of your secret';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'agent skills!';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'To order, call 1-800-GAME-123';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'between the hours of 8am - 7pm';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Central Standard Time (CST).';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Price: $34 (incl. $4 Shipping)';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'HOW TO ORDER MORE GAMES   Pg. 4';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'This price ($34) includes all';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'three Secret Agent missions,';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'which also sell for $15 apiece.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'You may also order by mail:';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '     Apogee Software';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '     P.O. Box 476389';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '     Garland, TX  75047';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'All orders include: hint sheet,';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'cheat password, and bonus game.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '-------------------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := GameScanCodeEscape;
  PopupSelectionScanCode := ReadScrollablePopupScanCode(0);
  EscapePressed := 0;
  GameOptionsRequested := 0;
end;

{ Keyboard setup, menus and settings dialogs. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Shows Congratulations! High score! and Enter your name; accepts at most twenty characters. }
procedure AskHighScoreName;
begin
  ClearPopupText;
  PopupTextLines[1] := 'Congratulations! High score!';
  PopupTextLines[2][0] := #0;
  PopupTextLines[3] := '      Enter your name:';
  PopupTextLines[4][0] := #0;
  PopupTextLines[5] := '    ^';
  PopupTextLines[6] := 'END OF WINDOW';
  PopupInputResult := ReadPopupText(GameHighScoreNameMaxLength);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Prompts for left/right/up/down/jump/fire, rejects unavailable or duplicate keys and confirms the choices. }
procedure RedefineKeyboardBindings;
var
  { Unused locals retain the original stack frame. }
  NewRightScanCode, NewLeftScanCode, NewUpScanCode, NewDownScanCode, NewFireScanCode, NewJumpScanCode,
    UnusedKeyBindingWord:
  Word;
  KeyIsValid, RedefineNotCancelled: Boolean;
  { Nested in RedefineKeyboardBindings; shows the six chosen key names, confirms Y/N and assigns the
    scan-code bindings. }
  procedure ConfirmKeyboardBindings;
  begin
    ClearPopupText;
    LeftKeyDisplayText := 'LEFT  - ' + LeftKeyDisplayText;
    RightKeyDisplayText := 'RIGHT - ' + RightKeyDisplayText;
    UpKeyDisplayText := 'UP    - ' + UpKeyDisplayText;
    DownKeyDisplayText := 'DOWN  - ' + DownKeyDisplayText;
    JumpKeyDisplayText := 'JUMP  - ' + JumpKeyDisplayText;
    FireKeyDisplayText := 'FIRE  - ' + FireKeyDisplayText;
    PopupTextLines[1] := 'KEYBOARD REDEFINED';
    PopupTextLines[2][0] := #0;
    PopupTextLines[3] := LeftKeyDisplayText;
    PopupTextLines[4] := RightKeyDisplayText;
    PopupTextLines[5] := UpKeyDisplayText;
    PopupTextLines[6] := DownKeyDisplayText;
    PopupTextLines[7] := JumpKeyDisplayText;
    PopupTextLines[8] := FireKeyDisplayText;
    PopupTextLines[9][0] := #0;
    PopupTextLines[10] := 'Are these selections ok (Y-N): ^';
    PopupTextLines[11][0] := #0;
    PopupTextLines[12] := 'END OF WINDOW';
    PopupAcceptedScanCodes[1] := GameScanCodeY;
    PopupAcceptedScanCodes[2] := GameScanCodeN;
    PopupSelectionScanCode := ReadPopupScanCode(0);
    if PopupSelectionScanCode = GameScanCodeN then
      RedefineKeyboardBindings
    else
    begin
      FireKeyScanCode := NewFireScanCode;
      LeftKeyScanCode := NewLeftScanCode;
      RightKeyScanCode := NewRightScanCode;
      UpKeyScanCode := NewUpScanCode;
      DownKeyScanCode := NewDownScanCode;
      JumpKeyScanCode := NewJumpScanCode;
    end;
  end;

  { Nested in RedefineKeyboardBindings; displays Sorry, that key is unavailable and waits for any scan code. }
  procedure ShowUnavailableKey;
  var
    DismissScanCode: Word;
  begin
    ClearPopupText;
    PopupTextLines[1] := 'Sorry, that key is unavailable.';
    PopupTextLines[2][0] := #0;
    PopupTextLines[3] := '  Press any key to continue.';
    PopupTextLines[4][0] := #0;
    PopupTextLines[5] := '               ^';
    PopupTextLines[6] := 'END OF WINDOW';
    DismissScanCode := ReadPopupScanCode(1);
  end;
begin
  RedefineNotCancelled := True;

  repeat
    KeyIsValid := True;
    ClearPopupText;
    PopupTextLines[1] := 'KEYBOARD REDEFINE';
    PopupTextLines[2][0] := #0;
    PopupTextLines[3] := 'Select key to move left: ^';
    PopupTextLines[4] := 'END OF WINDOW';
    NewLeftScanCode := ReadPopupScanCode(1);
    if NewLeftScanCode = GameScanCodeEscape then
      RedefineNotCancelled := False;
    LeftKeyDisplayText := ScanCodeDisplayName(NewLeftScanCode);
    if RedefineNotCancelled and (LeftKeyDisplayText = 'NULL') then
    begin
      ShowUnavailableKey;
      KeyIsValid := False;
    end;
  until KeyIsValid;

  if RedefineNotCancelled then
  begin
    repeat
      KeyIsValid := True;
      ClearPopupText;
      PopupTextLines[1] := 'KEYBOARD REDEFINE';
      PopupTextLines[2][0] := #0;
      PopupTextLines[3] := 'Select key to move right: ^';
      PopupTextLines[4] := 'END OF WINDOW';
      PopupAcceptedScanCodes[1] := GameScanCodeEscape;
      NewRightScanCode := ReadPopupScanCode(1);
      if NewRightScanCode = GameScanCodeEscape then
        RedefineNotCancelled := False;
      RightKeyDisplayText := ScanCodeDisplayName(NewRightScanCode);
      if RedefineNotCancelled and ((RightKeyDisplayText = 'NULL') or (RightKeyDisplayText = LeftKeyDisplayText)) then
      begin
        ShowUnavailableKey;
        KeyIsValid := False;
      end;
    until KeyIsValid;
  end;

  if RedefineNotCancelled then
  begin
    repeat
      KeyIsValid := True;
      ClearPopupText;
      PopupTextLines[1] := 'KEYBOARD REDEFINE';
      PopupTextLines[2][0] := #0;
      PopupTextLines[3] := 'Select key to move up: ^';
      PopupTextLines[4] := 'END OF WINDOW';
      PopupAcceptedScanCodes[1] := GameScanCodeEscape;
      NewUpScanCode := ReadPopupScanCode(1);
      if NewUpScanCode = GameScanCodeEscape then
        RedefineNotCancelled := False;
      UpKeyDisplayText := ScanCodeDisplayName(NewUpScanCode);
      if RedefineNotCancelled and ((UpKeyDisplayText = 'NULL') or (UpKeyDisplayText = LeftKeyDisplayText) or
        (UpKeyDisplayText = RightKeyDisplayText)) then
      begin
        ShowUnavailableKey;
        KeyIsValid := False;
      end;
    until KeyIsValid;
  end;

  if RedefineNotCancelled then
  begin
    repeat
      KeyIsValid := True;
      ClearPopupText;
      PopupTextLines[1] := 'KEYBOARD REDEFINE';
      PopupTextLines[2][0] := #0;
      PopupTextLines[3] := 'Select key to move down: ^';
      PopupTextLines[4] := 'END OF WINDOW';
      PopupAcceptedScanCodes[1] := GameScanCodeEscape;
      NewDownScanCode := ReadPopupScanCode(1);
      if NewDownScanCode = GameScanCodeEscape then
        RedefineNotCancelled := False;
      DownKeyDisplayText := ScanCodeDisplayName(NewDownScanCode);
      if RedefineNotCancelled and ((DownKeyDisplayText = 'NULL') or (DownKeyDisplayText = LeftKeyDisplayText) or
        (DownKeyDisplayText = RightKeyDisplayText) or (DownKeyDisplayText = UpKeyDisplayText)) then
      begin
        ShowUnavailableKey;
        KeyIsValid := False;
      end;
    until KeyIsValid;
  end;

  if RedefineNotCancelled then
  begin
    repeat
      KeyIsValid := True;
      ClearPopupText;
      PopupTextLines[1] := 'KEYBOARD REDEFINE';
      PopupTextLines[2][0] := #0;
      PopupTextLines[3] := 'Select key to jump: ^';
      PopupTextLines[4] := 'END OF WINDOW';
      PopupAcceptedScanCodes[1] := GameScanCodeEscape;
      NewJumpScanCode := ReadPopupScanCode(1);
      if NewJumpScanCode = GameScanCodeEscape then
        RedefineNotCancelled := False;
      JumpKeyDisplayText := ScanCodeDisplayName(NewJumpScanCode);
      if RedefineNotCancelled and ((JumpKeyDisplayText = 'NULL') or (JumpKeyDisplayText = LeftKeyDisplayText) or
        (JumpKeyDisplayText = RightKeyDisplayText) or (JumpKeyDisplayText = UpKeyDisplayText) or (JumpKeyDisplayText
        = DownKeyDisplayText)) then
      begin
        ShowUnavailableKey;
        KeyIsValid := False;
      end;
    until KeyIsValid;
  end;

  if RedefineNotCancelled then
  begin
    repeat
      KeyIsValid := True;
      ClearPopupText;
      PopupTextLines[1] := 'KEYBOARD REDEFINE';
      PopupTextLines[2][0] := #0;
      PopupTextLines[3] := 'Select key to fire: ^';
      PopupTextLines[4] := 'END OF WINDOW';
      NewFireScanCode := ReadPopupScanCode(1);
      if NewFireScanCode = GameScanCodeEscape then
        RedefineNotCancelled := False;
      FireKeyDisplayText := ScanCodeDisplayName(NewFireScanCode);
      { Original bug preserved: the Up/Down tests compare the jump binding,
      so the new fire key can duplicate Up or Down. }
      if RedefineNotCancelled and ((FireKeyDisplayText = 'NULL') or (FireKeyDisplayText = LeftKeyDisplayText) or
        (FireKeyDisplayText = RightKeyDisplayText) or (JumpKeyDisplayText = UpKeyDisplayText) or (JumpKeyDisplayText
        = DownKeyDisplayText) or (FireKeyDisplayText = JumpKeyDisplayText)) then
      begin
        ShowUnavailableKey;
        KeyIsValid := False;
      end;
    until KeyIsValid;
  end;

  if RedefineNotCancelled then
    ConfirmKeyboardBindings;

  MemW[$0000: GameBiosKeyboardTailLinear] := MemW[$0000: GameBiosKeyboardHeadLinear];
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Prompts Warp to which level? Select (1-16), parses the two-character response and returns it. }
function AskWarpLevel: Word;
var
  WarpLevelNumber, ParseErrorPosition: Word;
begin
  ClearPopupText;
  PopupTextLines[1] := 'Warp to which level?';
  PopupTextLines[2] := '--------------------';
  PopupTextLines[3][0] := #0;
  PopupTextLines[4] := 'Select (1-16) : ^';
  PopupTextLines[5][0] := #0;
  PopupTextLines[6] := 'END OF WINDOW';
  PopupInputResult := ReadPopupText(2);
  MemW[$0000: GameBiosKeyboardTailLinear] := MemW[$0000: GameBiosKeyboardHeadLinear];
  Val(PopupInputResult, WarpLevelNumber, ParseErrorPosition);
  AskWarpLevel := WarpLevelNumber;
  EscapePressed := 0;
  GameOptionsRequested := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Prompts Save Which Game? Select (0-9), writes the chosen slot and displays Game Saved/File Error. }
procedure ShowSaveGameMenu;
begin
  ClearPopupText;
  PopupTextLines[1] := 'Save Which Game?';
  PopupTextLines[2] := '----------------';
  PopupTextLines[3][0] := #0;
  PopupTextLines[4] := 'Select (0-9) : ^';
  PopupTextLines[5][0] := #0;
  PopupTextLines[6] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := GameScanCodeDigit1;
  PopupAcceptedScanCodes[2] := GameScanCodeDigit2;
  PopupAcceptedScanCodes[3] := GameScanCodeDigit3;
  PopupAcceptedScanCodes[4] := GameScanCodeDigit4;
  PopupAcceptedScanCodes[5] := GameScanCodeDigit5;
  PopupAcceptedScanCodes[6] := GameScanCodeDigit6;
  PopupAcceptedScanCodes[7] := GameScanCodeDigit7;
  PopupAcceptedScanCodes[8] := GameScanCodeDigit8;
  PopupAcceptedScanCodes[9] := GameScanCodeDigit9;
  PopupAcceptedScanCodes[10] := GameScanCodeDigit0;
  PopupAcceptedScanCodes[11] := GameScanCodeEnter;
  PopupAcceptedScanCodes[12] := GameScanCodeEscape;
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  PopupSelectionScanCode := ReadPopupScanCode(0);
  if IOResult = 0 then;
  case PopupSelectionScanCode of
    GameScanCodeDigit1 .. GameScanCodeDigit9:
      WriteSavedGame(PopupSelectionScanCode - 1);
    GameScanCodeDigit0:
      WriteSavedGame(0);
  end;
  EscapePressed := 0;
  GameOptionsRequested := 0;
  ClearPopupText;
  if IOResult = 0 then
    PopupTextLines[1] := 'Game Saved!'
  else
    PopupTextLines[1] := 'File Error!';
  PopupTextLines[2] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := GameScanCodeEnter;
  PopupAcceptedScanCodes[2] := GameScanCodeEscape;
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  PopupSelectionScanCode := ReadPopupScanCode(1);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Prompts Restore Which Game? Select (0-9), loads a slot and returns the selected scan code. }
function ShowRestoreGameMenu: Integer;
begin
  ClearPopupText;
  PopupTextLines[1] := 'Restore Which Game?';
  PopupTextLines[2] := '-------------------';
  PopupTextLines[3][0] := #0;
  PopupTextLines[4] := 'Select (0-9) : ^';
  PopupTextLines[5][0] := #0;
  PopupTextLines[6] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := GameScanCodeDigit1;
  PopupAcceptedScanCodes[2] := GameScanCodeDigit2;
  PopupAcceptedScanCodes[3] := GameScanCodeDigit3;
  PopupAcceptedScanCodes[4] := GameScanCodeDigit4;
  PopupAcceptedScanCodes[5] := GameScanCodeDigit5;
  PopupAcceptedScanCodes[6] := GameScanCodeDigit6;
  PopupAcceptedScanCodes[7] := GameScanCodeDigit7;
  PopupAcceptedScanCodes[8] := GameScanCodeDigit8;
  PopupAcceptedScanCodes[9] := GameScanCodeDigit9;
  PopupAcceptedScanCodes[10] := GameScanCodeDigit0;
  PopupAcceptedScanCodes[11] := GameScanCodeEnter;
  PopupAcceptedScanCodes[12] := GameScanCodeEscape;
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  PopupSelectionScanCode := ReadPopupScanCode(0);
  case PopupSelectionScanCode of
    GameScanCodeDigit1 .. GameScanCodeDigit9:
      if Ord(ReadSavedGame(PopupSelectionScanCode - 1)) = 0 then
        PopupSelectionScanCode := $1C;
    GameScanCodeDigit0:
      if Ord(ReadSavedGame(0)) = 0 then
        PopupSelectionScanCode := $1C;
  end;
  ShowRestoreGameMenu := PopupSelectionScanCode;
  EscapePressed := 0;
  GameOptionsRequested := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Dispatches MAIN MENU selections to New Game, Restore, Story, Instructions. }
function RunMainMenu: Char;
var
  TextLineIndex: Word;
begin
  TextLineIndex := 0;
  ClearPopupText;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '     MAIN MENU';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' N)ew Game';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' R)estore Old Game';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' S)tory';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' I)nstructions';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' H)igh Scores';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' O)rdering Info.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' F)oreign Orders';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' C)all Our BBS';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' V)ideo Support';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' A)bout Apogee';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' Q)uit to DOS';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Make a selection: ^';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';

  PopupAcceptedScanCodes[1] := GameScanCodeN;
  PopupAcceptedScanCodes[2] := GameScanCodeI;
  PopupAcceptedScanCodes[3] := GameScanCodeH;
  PopupAcceptedScanCodes[4] := GameScanCodeR;
  PopupAcceptedScanCodes[5] := GameScanCodeS;
  PopupAcceptedScanCodes[6] := GameScanCodeO;
  PopupAcceptedScanCodes[7] := GameScanCodeQ;
  PopupAcceptedScanCodes[8] := GameScanCodeEscape;
  PopupAcceptedScanCodes[9] := GameScanCodeSpace;
  PopupAcceptedScanCodes[10] := GameScanCodeEnter;
  PopupAcceptedScanCodes[11] := GameScanCodeF;
  PopupAcceptedScanCodes[12] := GameScanCodeA;
  PopupAcceptedScanCodes[13] := GameScanCodeC;
  PopupAcceptedScanCodes[14] := GameScanCodeV;

  PopupSelectionScanCode := ReadPopupScanCode(0);
  case PopupSelectionScanCode of
    GameScanCodeN, GameScanCodeSpace, GameScanCodeEnter:
      begin
        RunMainMenu := 'B';
        ReturnToTitleRequested := 0;
        Pickup269Count := 1;
      end;
    GameScanCodeI:
      begin
        ShowGameInstructions;
        RunMainMenu := 'I';
      end;
    GameScanCodeF:
      begin
        ShowForeignDealers;
        RunMainMenu := 'F';
      end;
    GameScanCodeC:
      begin
        ShowApogeeBbsInformation;
        RunMainMenu := 'A';
      end;
    GameScanCodeH:
      begin
        RunMainMenu := 'H';
        ShowHighScores;
      end;
    GameScanCodeA:
      begin
        RunMainMenu := 'A';
        ShowAboutApogee;
      end;
    GameScanCodeV:
      begin
        RunMainMenu := 'V';
        SelectVideoCompatibility;
      end;
    GameScanCodeR:
      begin
        RunMainMenu := 'R';
        Pickup269Count := 1;
        PendingRestoreScanCode := ShowRestoreGameMenu;
        if PendingRestoreScanCode = GameScanCodeEnter then
        begin
          PendingRestoreScanCode := 0;
          RunMainMenu := ' ';
        end
        else
          ReturnToTitleRequested := 0;
      end;
    GameScanCodeS:
      begin
        RunMainMenu := 'S';
        ShowMissionBriefing;
      end;
    GameScanCodeO:
      begin
        RunMainMenu := 'O';
        ShowOrderingInformation;
      end;
    GameScanCodeQ:
      begin
        ConfirmQuitToDos;
        if QuitGameRequested <> 0 then
          RunMainMenu := 'Q'
        else
          RunMainMenu := ' ';
      end;
    GameScanCodeEscape:
      begin
        EscapePressed := 0;
        RunMainMenu := ' ';
      end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Dispatches Operational Command Bank selections for help, sound/video/input settings, save/restore and quit.
  }
function RunGameOptionsMenu: Char;
var
  RestoreSelectionScanCode: Word;
begin
  ClearPopupText;
  PopupTextLines[1] := 'Operational Command Bank';
  PopupTextLines[2] := '------------------------';
  PopupTextLines[3][0] := #0;
  PopupTextLines[4] := 'H)elp';
  PopupTextLines[5] := 'T)oggle Sounds';
  PopupTextLines[6] := 'V)ideo Select';
  PopupTextLines[7] := 'J)oystick Toggle';
  PopupTextLines[8] := 'C)alibrate Joystick';
  PopupTextLines[9] := 'K)eyboard Config';
  PopupTextLines[10] := 'R)estore Game';
  PopupTextLines[11] := 'S)ave Game';
  PopupTextLines[12] := 'Q)uit';
  PopupTextLines[13][0] := #0;
  PopupTextLines[14] := 'Selection: ^';
  PopupTextLines[15][0] := #0;
  PopupTextLines[16] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := GameScanCodeH;
  PopupAcceptedScanCodes[2] := GameScanCodeT;
  PopupAcceptedScanCodes[3] := GameScanCodeV;
  PopupAcceptedScanCodes[4] := GameScanCodeJ;
  PopupAcceptedScanCodes[5] := GameScanCodeC;
  PopupAcceptedScanCodes[6] := GameScanCodeK;
  PopupAcceptedScanCodes[7] := GameScanCodeR;
  PopupAcceptedScanCodes[8] := GameScanCodeS;
  PopupAcceptedScanCodes[9] := GameScanCodeQ;
  PopupAcceptedScanCodes[10] := GameScanCodeEscape;

  PopupSelectionScanCode := ReadPopupScanCode(0);
  case PopupSelectionScanCode of
    GameScanCodeH:
      begin
        RunGameOptionsMenu := 'H';
        ShowGameInstructions;
      end;
    GameScanCodeT:
      begin
        RunGameOptionsMenu := 'T';
        SelectSoundSetting;
      end;
    GameScanCodeV:
      begin
        RunGameOptionsMenu := 'V';
        SelectVideoCompatibility;
      end;
    GameScanCodeJ:
      begin
        RunGameOptionsMenu := 'J';
        SelectJoystickSetting;
      end;
    GameScanCodeC:
      begin
        RunGameOptionsMenu := 'C';
        CalibrateJoystickCenter;
      end;
    GameScanCodeK:
      begin
        RunGameOptionsMenu := 'K';
        RedefineKeyboardBindings;
      end;
    GameScanCodeR:
      begin
        RunGameOptionsMenu := 'R';
        RestoreSelectionScanCode := ShowRestoreGameMenu;
        if RestoreSelectionScanCode <> GameScanCodeEnter then
          RestoreSnapshotRequested := 1;
      end;
    GameScanCodeS:
      begin
        RunGameOptionsMenu := 'S';
        if CurrentLevelNumber = 1 then
          ShowSaveGameMenu
        else
        begin
          ClearPopupText;
          PopupTextLines[1] := 'You can only save your game';
          PopupTextLines[2] := 'on the island map.  ';
          PopupTextLines[3][0] := #0;
          PopupTextLines[4] := 'Press ESCAPE';
          PopupTextLines[5] := 'END OF WINDOW';
          PopupAcceptedScanCodes[1] := GameScanCodeEscape;
          PopupSelectionScanCode := ReadPopupScanCode(0);
          EscapePressed := 0;
          GameOptionsRequested := 0;
        end;
      end;
    GameScanCodeQ:
      begin
        ShowQuitDestinationMenu;
        if QuitGameRequested <> 0 then
          RunGameOptionsMenu := 'Q'
        else
          RunGameOptionsMenu := ' ';
      end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Displays Secret Agents Hall of Fame and the ten formatted high-score entries. }
procedure ShowHighScores;
var
  HighScoreIndex: Word;
begin
  ClearPopupText;
  PopupTextLines[1] := '  Secret Agents Hall of Fame';
  PopupTextLines[2][0] := #0;
  PopupTextLines[3][0] := #0;
  for HighScoreIndex := 1 to GameHighScoreCount do
    PopupTextLines[HighScoreIndex + 3] := GameConfiguration.ConfigScoreLines[HighScoreIndex];
  PopupTextLines[14][0] := #0;
  PopupTextLines[15] := 'Press any key ^';
  PopupTextLines[16][0] := #0;
  PopupTextLines[17] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := GameScanCodeEscape;
  PopupSelectionScanCode := ReadPopupScanCode(1);
  EscapePressed := 0;
  GameOptionsRequested := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Displays the supplied message and Press ESCAPE using a popup with an Escape accepted scan code. }
procedure ShowGameMessage(MessageText: String);
begin
  ClearPopupText;
  PopupTextLines[1] := TPopupStringViews(MessageText).PopupLineString;
  PopupTextLines[2][0] := #0;
  PopupTextLines[3] := 'Press ESCAPE';
  PopupTextLines[4] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := GameScanCodeEscape;
  PopupSelectionScanCode := ReadPopupScanCode(0);
  EscapePressed := 0;
  GameOptionsRequested := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Prompts Quit To Dos (Y-N) and sets the quit flag when scan code 15h (Y) is returned. }
procedure ConfirmQuitToDos;
begin
  ClearPopupText;
  PopupTextLines[1] := 'Quit To Dos (Y-N) ^';
  PopupTextLines[2] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := GameScanCodeEscape;
  PopupAcceptedScanCodes[2] := GameScanCodeY;
  PopupAcceptedScanCodes[3] := GameScanCodeN;
  PopupSelectionScanCode := ReadPopupScanCode(1);
  if PopupSelectionScanCode = GameScanCodeY then
    QuitGameRequested := 1;
  EscapePressed := 0;
  GameOptionsRequested := 0;
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  LastKeyboardScanCode := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Offers DOS, Title Screen and Island Map and sets the corresponding loop-transition flags. }
procedure ShowQuitDestinationMenu;
begin
  ClearPopupText;
  PopupTextLines[1] := 'Quit to: ^';
  PopupTextLines[2][0] := #0;
  PopupTextLines[3] := ' D)os';
  PopupTextLines[4] := ' T)itle Screen';
  PopupTextLines[5] := ' I)sland Map';
  PopupTextLines[6] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := GameScanCodeD;
  PopupAcceptedScanCodes[2] := GameScanCodeT;
  PopupAcceptedScanCodes[3] := GameScanCodeI;
  PopupAcceptedScanCodes[4] := GameScanCodeEscape;
  PopupSelectionScanCode := ReadPopupScanCode(1);
  if PopupSelectionScanCode = GameScanCodeD then
  begin
    InsertPlayerHighScore;
    QuitGameRequested := 1;
    EpisodeBlueprintCollected := 0;
    StartSoundEffect(GameSfxQuitMenu);
  end
  else if PopupSelectionScanCode = GameScanCodeT then
  begin
    InsertPlayerHighScore;
    ReturnToTitleRequested := 1;
    EpisodeBlueprintCollected := 0;
    StartSoundEffect(GameSfxQuitMenu);
  end
  else if PopupSelectionScanCode = GameScanCodeI then
  begin
    RestoreSnapshotRequested := 1;
    EpisodeBlueprintCollected := 0;
  end;
  EscapePressed := 0;
  GameOptionsRequested := 0;
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  MemW[$0000: GameBiosKeyboardTailLinear] := MemW[$0000: GameBiosKeyboardHeadLinear];
  LastKeyboardScanCode := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Prompts Sounds On (Y-N) and assigns SoundEnabled, which gates PC-speaker sound in the timer ISR. }
procedure SelectSoundSetting;
begin
  ClearPopupText;
  PopupTextLines[1] := 'Sounds On (Y-N) ^';
  PopupTextLines[2] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := GameScanCodeY;
  PopupAcceptedScanCodes[2] := GameScanCodeN;
  PopupAcceptedScanCodes[3] := GameScanCodeEscape;
  PopupSelectionScanCode := ReadPopupScanCode(1);
  if PopupSelectionScanCode = GameScanCodeY then
    SoundEnabled := 1
  else
    SoundEnabled := 0;
  EscapePressed := 0;
  GameOptionsRequested := 0;
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  MemW[$0000: GameBiosKeyboardTailLinear] := MemW[$0000: GameBiosKeyboardHeadLinear];
  LastKeyboardScanCode := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Prompts Alternate video setting (Y-N); AlternateVideoTiming selects the alternate retrace-pan routine. }
procedure SelectVideoCompatibility;
begin
  ClearPopupText;
  PopupTextLines[1] := '    VIDEO BOARD COMPATIBILITY';
  PopupTextLines[2][0] := #0;
  PopupTextLines[3] := '    Some SuperVGA boards have';
  PopupTextLines[4] := '   compatibility problems that';
  PopupTextLines[5] := '  cause the screen to jerk when';
  PopupTextLines[6] := 'scrolling, or perform unreliably.';
  PopupTextLines[7][0] := #0;
  PopupTextLines[8] := ' This is the fault of the video';
  PopupTextLines[9] := ' board makers not producing 100%';
  PopupTextLines[10] := '   compatible graphics cards.';
  PopupTextLines[11][0] := #0;
  PopupTextLines[12] := ' We have tried to support all the';
  PopupTextLines[13] := 'boards we know of, but if you have';
  PopupTextLines[14] := '    problems, then toggle this';
  PopupTextLines[15] := '   setting and see if it helps.';
  PopupTextLines[16][0] := #0;
  PopupTextLines[17] := '  Alternate video setting (Y-N) ^ ';
  PopupTextLines[18] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := GameScanCodeY;
  PopupAcceptedScanCodes[2] := GameScanCodeN;
  PopupAcceptedScanCodes[3] := GameScanCodeEscape;
  PopupSelectionScanCode := ReadPopupScanCode(0);
  if PopupSelectionScanCode = GameScanCodeY then
    AlternateVideoTiming := 1
  else
    AlternateVideoTiming := 0;
  EscapePressed := 0;
  GameOptionsRequested := 0;
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  LastKeyboardScanCode := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Prompts Joystick On (Y-N), tests availability and assigns the persisted joystick setting. }
procedure SelectJoystickSetting;
begin
  ClearPopupText;
  PopupTextLines[1] := 'Joystick On (Y-N) ^';
  PopupTextLines[2] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := GameScanCodeY;
  PopupAcceptedScanCodes[2] := GameScanCodeN;
  PopupAcceptedScanCodes[3] := GameScanCodeEscape;
  PopupSelectionScanCode := ReadPopupScanCode(1);
  if PopupSelectionScanCode = GameScanCodeY then
  begin
    JoystickActive := IsJoystickPresent;
    JoystickSettingEnabled := 1;
  end
  else if PopupSelectionScanCode = GameScanCodeN then
  begin
    JoystickActive := False;
    JoystickSettingEnabled := 0;
  end;
  EscapePressed := 0;
  GameOptionsRequested := 0;
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  LastKeyboardScanCode := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Prompts for a centered joystick, then measures axes 0 and 1 into JoystickCenterX/JoystickCenterY. }
procedure CalibrateJoystickCenter;
var
  TextLineIndex: Word;
begin
  ClearPopupText;
  TextLineIndex := 0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  Set your joystick so that';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'it is in the middle position.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' ';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   Press SPACE when this is';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' done, and the joystick will';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '       be calibrated.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' ';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'This step is not necessary if';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' your joystick is set in the';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' middle when the game loads.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' ';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press Escape if your joystick';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '         is not on.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '              ^';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';

  PopupAcceptedScanCodes[1] := GameScanCodeEscape;
  PopupAcceptedScanCodes[2] := GameScanCodeSpace;
  PopupSelectionScanCode := ReadPopupScanCode(0);
  if PopupSelectionScanCode = GameScanCodeSpace then
  begin
    JoystickActive := IsJoystickPresent;
    if JoystickActive then
    begin
      JoystickCenterX := ReadJoystickAxis(0);
      JoystickCenterY := ReadJoystickAxis(1);
    end;
  end;

  EscapePressed := 0;
  GameOptionsRequested := 0;
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  LastKeyboardScanCode := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Maps keyboard scan codes to printable key names (CTRL, ALT, arrows etc.) or NULL. }
function ScanCodeDisplayName(ScanCode: Word): String;
begin
  case ScanCode of
    GameScanCodeDigit1:
      ScanCodeDisplayName := '1';
    GameScanCodeDigit2:
      ScanCodeDisplayName := '2';
    GameScanCodeDigit3:
      ScanCodeDisplayName := '3';
    GameScanCodeDigit4:
      ScanCodeDisplayName := '4';
    GameScanCodeDigit5:
      ScanCodeDisplayName := '5';
    GameScanCodeDigit6:
      ScanCodeDisplayName := '6';
    GameScanCodeDigit7:
      ScanCodeDisplayName := '7';
    GameScanCodeDigit8:
      ScanCodeDisplayName := '8';
    GameScanCodeDigit9:
      ScanCodeDisplayName := '9';
    GameScanCodeDigit0:
      ScanCodeDisplayName := '0';
    GameScanCodeQ:
      ScanCodeDisplayName := 'Q';
    GameScanCodeW:
      ScanCodeDisplayName := 'W';
    GameScanCodeE:
      ScanCodeDisplayName := 'E';
    GameScanCodeR:
      ScanCodeDisplayName := 'R';
    GameScanCodeT:
      ScanCodeDisplayName := 'T';
    GameScanCodeY:
      ScanCodeDisplayName := 'Y';
    GameScanCodeU:
      ScanCodeDisplayName := 'U';
    GameScanCodeI:
      ScanCodeDisplayName := 'I';
    GameScanCodeO:
      ScanCodeDisplayName := 'O';
    GameScanCodeP:
      ScanCodeDisplayName := 'P';
    GameScanCodeEnter:
      ScanCodeDisplayName := 'ENTER';
    GameScanCodeControl:
      ScanCodeDisplayName := 'CTRL';
    GameScanCodeA:
      ScanCodeDisplayName := 'A';
    GameScanCodeS:
      ScanCodeDisplayName := 'S';
    GameScanCodeD:
      ScanCodeDisplayName := 'D';
    GameScanCodeF:
      ScanCodeDisplayName := 'F';
    GameScanCodeG:
      ScanCodeDisplayName := 'G';
    GameScanCodeH:
      ScanCodeDisplayName := 'H';
    GameScanCodeJ:
      ScanCodeDisplayName := 'J';
    GameScanCodeK:
      ScanCodeDisplayName := 'K';
    GameScanCodeL:
      ScanCodeDisplayName := 'L';
    GameScanCodeLeftShift:
      ScanCodeDisplayName := 'L-SHIFT';
    GameScanCodeZ:
      ScanCodeDisplayName := 'Z';
    GameScanCodeX:
      ScanCodeDisplayName := 'X';
    GameScanCodeC:
      ScanCodeDisplayName := 'C';
    GameScanCodeV:
      ScanCodeDisplayName := 'V';
    GameScanCodeB:
      ScanCodeDisplayName := 'B';
    GameScanCodeN:
      ScanCodeDisplayName := 'N';
    GameScanCodeM:
      ScanCodeDisplayName := 'M';
    GameScanCodeComma:
      ScanCodeDisplayName := ',';
    GameScanCodePeriod:
      ScanCodeDisplayName := '.';
    GameScanCodeSlash:
      ScanCodeDisplayName := '/';
    GameScanCodeRightShift:
      ScanCodeDisplayName := 'R-SHIFT';
    GameScanCodeAlt:
      ScanCodeDisplayName := 'ALT';
    GameScanCodeSpace:
      ScanCodeDisplayName := 'SPACE';
    GameScanCodeHome:
      ScanCodeDisplayName := 'HOME';
    GameScanCodeUp:
      ScanCodeDisplayName := 'UP ARROW';
    GameScanCodePageUp:
      ScanCodeDisplayName := 'PGUP';
    GameScanCodeLeft:
      ScanCodeDisplayName := 'LEFT ARROW';
    GameScanCodeRight:
      ScanCodeDisplayName := 'RIGHT ARROW';
    GameScanCodeEnd:
      ScanCodeDisplayName := 'END';
    GameScanCodeDown:
      ScanCodeDisplayName := 'DOWN ARROW';
    GameScanCodePageDown:
      ScanCodeDisplayName := 'PGDN';
    GameScanCodeInsert:
      ScanCodeDisplayName := 'INSERT';
    GameScanCodeDelete:
      ScanCodeDisplayName := 'DELETE';
    else
      ScanCodeDisplayName := 'NULL';
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ The complete reconstructed procedure is empty; information-screen callers invoke it after popups. }
procedure PopupNoOpHook;
begin
end;

{ Ordering and publisher information. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Shows mail/phone ordering instructions and the ORDER.FRM fax ordering page. }
procedure ShowOrderContactDetails;
var
  TextLineIndex: Word;
  DismissScanCode: Word;
begin
  ClearPopupText;
  TextLineIndex := 0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'ORDERING THE SECRET AGENT SERIES!';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '    Please specify disk size:';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '         5.25"  or  3.5"';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   To order send $34, check or';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   money order (USA funds) to:';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '         Apogee Software';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '         P.O. Box 476386';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '     Garland, TX 75047  (USA)';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '     Or CALL NOW toll free:';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '         1-800-GAME123';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '     (Visa and MasterCard)';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '    Continued...Press Any Key';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  DismissScanCode := ReadPopupScanCode(1);
  EscapePressed := 1;
  PopupNoOpHook;
  ClearPopupText;
  TextLineIndex := 0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' USE YOUR FAX MACHINE TO ORDER!';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'You can now use your FAX machine';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' to order your favorite Apogee';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   games quickly and easily.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' Simply print out the ORDER.FRM';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  file, fill it out and FAX it';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  to us for prompt processing.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   FAX Orders: (214) 278-4670';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '          Press Any Key';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  DismissScanCode := ReadPopupScanCode(1);
  EscapePressed := 1;
  PopupNoOpHook;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Lists all three missions, hint sheet, cheat password and bonus game included with an order. }
procedure ShowOrderPackageDetails;
var
  TextLineIndex: Word;
  DismissScanCode: Word;
begin
  ClearPopupText;
  TextLineIndex := 0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'ORDERING THE SECRET AGENT SERIES!';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '     Order now and receive:';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  * All three devious missions';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  * The hints and tricks sheet';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  * The secret cheat password';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  * Exciting new bonus game';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '    To order, call toll free:';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '         1-800-426-3123';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  (Visa and MasterCard Welcome)';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Foreign orders:  Please read the';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  "Foreign Orders" menu option.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '    Continued...Press Any Key';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  DismissScanCode := ReadPopupScanCode(1);
  EscapePressed := 1;
  PopupNoOpHook;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Introduces the three-episode series and prices, then calls the package and contact detail pages. }
procedure ShowOrderingInformation;
var
  TextLineIndex: Word;
  DismissScanCode: Word;
begin
  ClearPopupText;
  TextLineIndex := 0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'ORDERING THE SECRET AGENT SERIES!';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' Secret Agent consists of three';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'original and incredible missions:';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  1) The Hunt for Red Rock Rover';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  2) Kill Again Island';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  3) Dr. No Body';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' You may order the entire series';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' for only $30, plus $4 shipping.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' Each episode is set on a unique';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'island, with all-new dangers, new';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' levels, and all-new challenges.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '    Continued...Press Any Key';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  DismissScanCode := ReadPopupScanCode(1);
  EscapePressed := 1;
  PopupNoOpHook;
  ShowOrderPackageDetails;
  ShowOrderContactDetails;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Displays official dealers and ordering details for Australia, Canada, Germany and the UK. }
procedure ShowForeignDealers;
var
  TextLineIndex: Word;
  DismissScanCode: Word;
begin
  ClearPopupText;
  TextLineIndex := 0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '       FOREIGN CUSTOMERS';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '       -----------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'The following screens list our';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  dealers outside the United';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'States, for Australia, Germany,';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Canada and the United Kingdom.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  These are official Apogee';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   dealers with the latest';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '      games and updates.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'If your country is not listed,';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' you may order directly from';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Apogee by phone or USA check.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '        Press Any Key ^';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';
  LastKeyboardScanCode := UiReleasedKeySentinel;
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  DismissScanCode := ReadPopupScanCode(1);
  PopupNoOpHook;

  ClearPopupText;
  TextLineIndex := 0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '      AUSTRALIAN CUSTOMERS';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'PRICE: $45 + $5 shipping.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'BudgetWare';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'P.O. Box 496';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Newtown, NSW  2042';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Phone:      (02) 519-4233';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Toll free:  (008) 022-064';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Fax:        (02) 516-4236';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'CompuServe: 71520,1475';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Use MasterCard, Visa, Bankcard,';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'cheques.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';
  LastKeyboardScanCode := UiReleasedKeySentinel;
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  DismissScanCode := ReadPopupScanCode(1);
  PopupNoOpHook;

  ClearPopupText;
  TextLineIndex := 0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '      AUSTRALIAN CUSTOMERS';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'PRICE: $45 + $5 shipping.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Manaccom';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '9 Camford Str.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Milton, Qld. 4064';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Phone: (07) 368-2366';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Fax:   (07) 369-7589';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Use MasterCard, Visa, Bankcard,';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'American Express, or cheques.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';
  LastKeyboardScanCode := UiReleasedKeySentinel;
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  DismissScanCode := ReadPopupScanCode(1);
  PopupNoOpHook;

  ClearPopupText;
  TextLineIndex := 0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '    CANADIAN CUSTOMERS';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'PRICE: $42 Canadian.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Distant Markets';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Box 1149';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '194 - 3803 Calgary Trail S.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Edmondton, Alb.  T6J 5M8';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'CANADA';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Orders:    1-800-661-7383';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Inquiries: (403) 436-3009';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Fax:       (403) 435-0928';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Use MasterCard, Visa or';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'money orders.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';
  LastKeyboardScanCode := UiReleasedKeySentinel;
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  DismissScanCode := ReadPopupScanCode(1);
  PopupNoOpHook;

  ClearPopupText;
  TextLineIndex := 0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '        GERMAN CUSTOMERS';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Price: 49,-- DM plus 10,-- DM';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Total: 59,-- DM (Deutsche Mark)';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'CDV-Software';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Ettlingerstr. 5';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '7500 Karlsruhe 1  GERMANY';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Phone: 0721-22295';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Fax:   0721-21314';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Compuserve: 1000022,274';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Use Visa, MasterCard, EuroCard,';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'American Express, cheque, money';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'order, or C.O.D.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';
  LastKeyboardScanCode := UiReleasedKeySentinel;
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  DismissScanCode := ReadPopupScanCode(1);
  PopupNoOpHook;

  ClearPopupText;
  TextLineIndex := 0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '    UNITED KINGDOM CUSTOMERS';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Price: /29 + VAT + /2 P&P';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Precision Software Applications';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Unit 3, Valley Court Offices';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Lower Rd';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Croydon, Near Royston';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Harts. SG8 0HF, United Kingdom';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Phone: +44 (0) 223 208 288';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'FAX:   +44 (0) 223 208 089';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Credit cards, Access, cheques,';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'postal & Bankers orders.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Make cheques payable to PSA.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';
  LastKeyboardScanCode := UiReleasedKeySentinel;
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  DismissScanCode := ReadPopupScanCode(1);
  PopupNoOpHook;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Displays THE OFFICIAL APOGEE BBS, Software Creations and modem phone numbers. }
procedure ShowApogeeBbsInformation;
var
  TextLineIndex: Word;
  DismissScanCode: Word;
begin
  ClearPopupText;
  TextLineIndex := 0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   THE OFFICIAL APOGEE BBS';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   -----------------------';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'The SOFTWARE CREATIONS BBS is';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' the home BBS for the latest';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' Apogee games.  Check out our';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'FREE "Apogee" file section for';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  new releases and updates.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '       BBS phone lines:';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '(508) 365-2359  2400 baud';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '(508) 365-9825  9600 baud';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '(508) 365-9668  14.4k dual HST';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  Many node lines available!';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '        Press Any Key ^';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';

  LastKeyboardScanCode := UiReleasedKeySentinel;
  MemW[$0000: GameBiosKeyboardTailLinear] := MemW[$0000: GameBiosKeyboardHeadLinear];
  DismissScanCode := ReadPopupScanCode(1);
  PopupNoOpHook;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Displays About Apogee Software and the shareware-support message. }
procedure ShowAboutApogee;
var
  TextLineIndex, DismissScanCode: Word;
begin
  ClearPopupText;
  TextLineIndex := 0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '     About Apogee Software';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Our goal is to establish Apogee';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  as the leader in commercial';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' quality shareware games. With';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' enthusiasm and dedication we';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'think our goal can be achieved.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'However,  we need your support.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Shareware is not free software.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  We thank you in advance for';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '   your contribution to the';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  growing shareware community.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '      Your honesty pays...';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '        Press any key ^';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';
  LastKeyboardScanCode := UiReleasedKeySentinel;
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  DismissScanCode := ReadPopupScanCode(1);
  PopupNoOpHook;
end;

{ Level-completion notices. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Announces that the island security system is knocked out and the blueprint level can now be entered. }
procedure ShowFortressUnlockedMessage;
var
  TextLineIndex: Word;
  DismissScanCode: Word;
begin
  ClearPopupText;
  TextLineIndex := 0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Good work 006, you@ve knocked';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'out the island security system';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '  and can now infiltrate the';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '     level containing the';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' blueprints to the "Red Rock';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '      Rover" satellite.';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press ESCAPE!          ';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := GameScanCodeEscape;
  PopupAcceptedScanCodes[2] := GameScanCodeEnter;
  PopupAcceptedScanCodes[3] := GameScanCodeSpace;
  LastKeyboardScanCode := UiReleasedKeySentinel;
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  DismissScanCode := ReadPopupScanCode(0);
  EscapePressed := 0;
  GameOptionsRequested := 0;
  PopupNoOpHook;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Displays the 25,000 point BONUS for finishing a level with perfect health. }
procedure ShowPerfectHealthBonus;
var
  TextLineIndex, DismissScanCode: Word;
begin
  ClearPopupText;
  TextLineIndex := 0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := ' 25,000 point BONUS for';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'finishing the level with';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := '    perfect health!';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex][0] := #0;
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'Press ESCAPE!          ';
  Inc(TextLineIndex);
  PopupTextLines[TextLineIndex] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := GameScanCodeEscape;
  PopupAcceptedScanCodes[2] := GameScanCodeEnter;
  PopupAcceptedScanCodes[3] := GameScanCodeSpace;
  LastKeyboardScanCode := UiReleasedKeySentinel;
  MemW[$0000: GameBiosKeyboardTailLinear] := MemW[$0000: GameBiosKeyboardHeadLinear];
  DismissScanCode := ReadPopupScanCode(0);
  EscapePressed := 0;
  GameOptionsRequested := 0;
  PopupNoOpHook;
end;

{ Exit and episode-ending screens. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Switches to text mode and draws the ordering screen (SAM1) or distribution notice (SAM2/3). }
procedure ShowDosExitScreen;
var
  { Unused locals retain the original stack frame. }
  BorderStripeIndex, UnusedExitScreenWord2, UnusedExitScreenWord3, UnusedExitScreenWord4: Word;
begin
  TextMode(GameBiosColorTextMode);
  ClrScr;
  GotoXY(1, 1);
  for BorderStripeIndex := 0 to 19 do
  begin
    WriteVerticalText(4 * BorderStripeIndex + 1, 1, 8, 0, DosExitBorder);
    WriteVerticalText(4 * BorderStripeIndex + 2, 1, 7, 0, DosExitBorder);
    WriteVerticalText(4 * BorderStripeIndex + 3, 1, 15, 0, DosExitBorder);
    WriteVerticalText(4 * BorderStripeIndex + 4, 1, 7, 0, DosExitBorder);
  end;
{$IFDEF SAM1}
  DrawFilledTextBox(9, 2, 72, 4, 15, 4, 3);
  WriteCenteredText(3, 15, 4, ' HOW TO ORDER THE FINAL TWO AMAZING EPISODES OF SECRET AGENT');
  DrawFilledTextBox(5, 7, 76, 21, 3, 4, 3);
  WriteCenteredText(8, 14, 4, ' The final two episodes of SECRET AGENT continue your adventure');
  WriteCenteredText(9, 14, 4, ' as the heroic super spy 006'#171'.  You''ll encounter fun and danger');
  WriteCenteredText(10, 14, 4, ' on two all-new islands, packed with new graphics and challenges.');
  WriteCenteredText(12, 14, 4, ' By ordering the final two episodes of SECRET AGENT you''ll get:');
  WriteCenteredText(13, 14, 4, ' The hints and tricks sheet, the cheat password, and an all-new');
  WriteCenteredText(14, 14, 4, ' bonus game from Apogee Software for you to try out.');
  WriteCenteredText(16, 15, 4, ' Apogee Software             CALL TOLL FREE!  ');
  WriteCenteredText(17, 15, 4, ' P.O. Box 476389              1-800-GAME123   ');
  WriteCenteredText(18, 15, 4, ' Garland, TX 75047          Visa or MasterCard ');
  WriteCenteredText(20, 14, 4, ' Or mail $34 (check or money order) to order SECRET AGENT.');
{$ELSE}
  DrawTextBoxBorder(1, 1, 80, 24, 3, 1, 4);
  DrawFilledTextBox(5, 3, 76, 6, 128, 6, 7);
  WriteCenteredText(4, 15, 6, ' NOTICE: THIS GAME IS NOT SHAREWARE, FREEWARE NOR PUBLIC DOMAIN!');
  WriteCenteredText(5, 15, 6, ' THIS GAME MAY ONLY BE DISTRIBUTED BY AUTHORIZED APOGEE DEALERS.');
  DrawFilledTextBox(5, 8, 76, 22, 2, 4, 3);
  WriteCenteredText(9, 15, 4, ' Only the first episode of SECRET AGENT is available as shareware.');
  WriteCenteredText(11, 14, 4, ' The remaining two episodes (including this episode), are only sold');
  WriteCenteredText(12, 14, 4, ' by Apogee Software, or through authorized distributors.');
  WriteCenteredText(14, 14, 4, ' Bulletin boards, shareware vendors, user groups and clubs MAY NOT');
  WriteCenteredText(15, 14, 4, ' distribute this episode of SECRET AGENT without lawful penalties.');
  WriteCenteredText(17, 14, 4, ' SECRET AGENT consists of three unique and exciting episodes:');
  WriteCenteredText(18, 14, 4, ' The Hunt for Red Rock Rover - Kill Again Island - Dr. No Body');
  WriteCenteredText(20, 15, 4, ' To order the complete SECRET AGENT trilogy, call 1-800-GAME123');
  WriteCenteredText(21, 15, 4, ' Or write:  Apogee Software  P.O. Box 476389  Garland, TX 75047');
{$ENDIF}
  TextColor(3);
  TextBackground(0);
  GotoXY(1, 24);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Loads SAMn.END (two screens in SAM3), shows success text. }
procedure ShowEpisodeEnding;
var
  EndingDelayIteration, GraphicsCallResult: Word;
begin
  PgSetToolboxVideoMode(0);
  GraphicsCallResult := PcxSetDisplayType(UiPcxEga320x200);
  GraphicsCallResult := PcxSetGraphicsOrTextMode(UiPcxGraphicsEnabled);
  GraphicsCallResult := PgSetScreenStride(UiImageScreenStride);
  CameraX := 0;
  CameraY := 0;
  DisplayedBufferRow := 0;
  GameDrawBufferRow := 0;
{$IFDEF SAM1}
  GraphicsCallResult := PcxDisplayFile('SAM1.END', 1, 0, 0);
{$ELSE}
{$IFDEF SAM2}
  GraphicsCallResult := PcxDisplayFile('SAM2.END', 1, 0, 0);
{$ELSE}
  GraphicsCallResult := PcxDisplayFile('SAM3A.END', 1, 0, 0);
{$ENDIF}
{$ENDIF}
  RestoreGamePalette(0);
  for EndingDelayIteration := 1 to 30 do
  begin
    Delay(50);
    MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  end;
  ShowMissionSuccessText;
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  repeat
  until KeyPressed;
{$IFDEF SAM3}
  FadeGamePaletteToBlack(0);
  GraphicsCallResult := PcxDisplayFile('SAM3B.END', 1, 0, 0);
  RestoreGamePalette(0);
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  repeat
  until KeyPressed;
{$ENDIF}
  MemW[0: GameBiosKeyboardTailLinear] := MemW[0: GameBiosKeyboardHeadLinear];
  InsertPlayerHighScore;
  ReturnToTitleRequested := 1;
  EpisodeBlueprintCollected := 0;
  QuitGameRequested := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{ No unit initialization is required. }
begin
end.
