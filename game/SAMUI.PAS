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
procedure FadeGamePaletteToBlack(FadeGamePaletteT_PaletteDelayMs: Word);
procedure DrawGameStatusBar;
procedure ClearPopupText;
procedure DrawGameText(TextColumn, TextRow: Integer; DisplayText: string);
function ReadPopupScanCode(AcceptAnyKey: Byte): Byte;
function ReadPopupText(MaxInputLength: Integer): String;
function ReadScrollablePopupScanCode(ReadScrollablePopu_AcceptAnyKey: Byte): Byte;
procedure ShowApogeeSplash;
procedure ShowTitleAndCredits;
procedure InsertPlayerHighScore;
procedure LoadGameSpriteBanks;
procedure BlackenGamePalette;
procedure CaptureGameSnapshot;
procedure RestoreGameSnapshot;
procedure WriteSavedGame(SaveSlot: Integer);
function ReadSavedGame(ReadSavedGame_SaveSlot: Integer): Boolean;
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
procedure ShowGameMessage(MessageText: string);
procedure ConfirmQuitToDos;
procedure ShowQuitDestinationMenu;
procedure SelectSoundSetting;
procedure SelectVideoCompatibility;
procedure SelectJoystickSetting;
procedure CalibrateJoystickCenter;
function ScanCodeDisplayName(ScanCode: Word): string;
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
{$IFDEF SAM1}
{$F+}
{ INT 10h AX=1B00 distinguishes VGA; the fallback examines BIOS EGA flags and returns V/E/U. }
function DetectGameVideoAdapter: Char;
var
  prefixByte: Byte;
  BiosRegs: Registers;
  EquipmentDisplayBits: Word;
  pad: array[1..6] of Byte;
  EgaDisplayFlags: Byte;
  AdapterCode: Char;
  VideoStateBuffer: array[1..64] of Byte;
begin
  BiosRegs.ES := Seg(VideoStateBuffer);
  BiosRegs.DI := Ofs(VideoStateBuffer);
  BiosRegs.AX := $1B00;
  BiosRegs.BX := 0;
  Intr($10, BiosRegs);
  if Lo(BiosRegs.AX) = $1B then
  begin
    AdapterCode := 'V';
  end
  else
  begin
    Intr($11, BiosRegs);
    EquipmentDisplayBits := (Lo(BiosRegs.AX) and $30) shr 4;
    EgaDisplayFlags := PVideoFlagByte(PVideoFlagPointer(Ptr(0, $0487))^)^;
    if EgaDisplayFlags <> 0 then
      AdapterCode := 'E'
    else
      AdapterCode := 'U';
  end;
  DetectGameVideoAdapter := AdapterCode;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$ENDIF}
{$F+}
{ Alternates buffer index d_683E and draw-row origin d_6840 between 16 and 416. }
procedure ToggleGameDrawBuffer;
begin
  if GameDrawBufferIndex = 0 then
  begin
    GameDrawBufferIndex := 1;
    GameDrawBufferRow := $01A0;
  end
  else
  begin
    GameDrawBufferIndex := 0;
    GameDrawBufferRow := $0010;
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
procedure FadeGamePaletteToBlack(FadeGamePaletteT_PaletteDelayMs: Word);
var
  PaletteIndex: Integer;
begin
  for PaletteIndex := 0 to 15 do
  begin
    Delay(FadeGamePaletteT_PaletteDelayMs);
    PgSetPaletteRegister(PaletteIndex, 0);
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Formats the six-digit score, ammo, inventory indicators and health glyphs; handles horizontal pixel panning. }
procedure DrawGameStatusBar;
var
  DigitOrHealthIndex: Integer;
  PanSubByteOffset: Word;
  ScoreText: String[11];
begin
  PgCopyStatusBandTemplate;
  StatusBarCameraX := CameraX;
  PanSubByteOffset := CameraX and 7;
  Str(PlayerScore:6, ScoreText);
  for DigitOrHealthIndex := 1 to 6 do
    if ScoreText[DigitOrHealthIndex] = ' ' then
      ScoreText[DigitOrHealthIndex] := '0';

  if PanSubByteOffset = 0 then
  begin
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[1]) - $2F].GlyphDataBytes[1], 0, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[2]) - $2F].GlyphDataBytes[1], 1, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[3]) - $2F].GlyphDataBytes[1], 2, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[4]) - $2F].GlyphDataBytes[1], 3, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[5]) - $2F].GlyphDataBytes[1], 4, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[6]) - $2F].GlyphDataBytes[1], 5, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[13].GlyphDataBytes[1], 12, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[11].GlyphDataBytes[1], 13, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[PlayerAmmo div 10 + 1].GlyphDataBytes[1], 14, 1);
    PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[PlayerAmmo mod 10 + 1].GlyphDataBytes[1], 15, 1);
    if PlayerSpeedBoost > 0 then
      PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[14].GlyphDataBytes[1], 20, 1);
    if PlayerHasDynamite <> 0 then
      PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[21].GlyphDataBytes[1], 25, 1);
    if HasKeyTwo <> 0 then
      PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[18].GlyphDataBytes[1], 27, 1);
    if HasKeyThree <> 0 then
      PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[19].GlyphDataBytes[1], 28, 1);
    if HasKeyOne <> 0 then
      PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[20].GlyphDataBytes[1], 29, 1);
    if PlayerHasFloppyDisk <> 0 then
      PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[22].GlyphDataBytes[1], 30, 1);
    for DigitOrHealthIndex := 1 to Integer(PlayerHealth) do
      PgBlitOpaque8x8(StatusGlyphBank^.GlyphEntries[12].GlyphDataBytes[1], DigitOrHealthIndex + 32, 1);
  end
  else
  begin
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[1]) - $2F].GlyphDataBytes[1], PanSubByteOffset, 1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[2]) - $2F].GlyphDataBytes[1], PanSubByteOffset + 8, 1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[3]) - $2F].GlyphDataBytes[1], PanSubByteOffset + 16,
    1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[4]) - $2F].GlyphDataBytes[1], PanSubByteOffset + 24,
    1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[5]) - $2F].GlyphDataBytes[1], PanSubByteOffset + 32,
    1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[Ord(ScoreText[6]) - $2F].GlyphDataBytes[1], PanSubByteOffset + 40,
    1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[13].GlyphDataBytes[1], PanSubByteOffset + 96, 1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[11].GlyphDataBytes[1], PanSubByteOffset + 104, 1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[PlayerAmmo div 10 + 1].GlyphDataBytes[1], PanSubByteOffset + 112, 1);
    PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[PlayerAmmo mod 10 + 1].GlyphDataBytes[1], PanSubByteOffset + 120, 1);
    if PlayerSpeedBoost > 0 then
      PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[14].GlyphDataBytes[1], PanSubByteOffset + 160, 1);
    if PlayerHasDynamite <> 0 then
      PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[21].GlyphDataBytes[1], PanSubByteOffset + 200, 1);
    if HasKeyTwo <> 0 then
      PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[18].GlyphDataBytes[1], PanSubByteOffset + 216, 1);
    if HasKeyThree <> 0 then
      PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[19].GlyphDataBytes[1], PanSubByteOffset + 224, 1);
    if HasKeyOne <> 0 then
      PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[20].GlyphDataBytes[1], PanSubByteOffset + 232, 1);
    if PlayerHasFloppyDisk <> 0 then
      PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[22].GlyphDataBytes[1], PanSubByteOffset + 240, 1);
    for DigitOrHealthIndex := 1 to Integer(PlayerHealth) do
      PgBlitMaskedShifted8x8(StatusGlyphBank^.GlyphEntries[12].GlyphDataBytes[1], PanSubByteOffset + $100 +
      (Word(DigitOrHealthIndex) shl 3), 1);
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Clears all 299 popup text strings and all 20 accepted scan-code entries. }
procedure ClearPopupText;
var
  LineOrKeyIndex: Integer;
begin
  for LineOrKeyIndex := 1 to 299 do
    PopupTextLines[LineOrKeyIndex][0] := #0;
  for LineOrKeyIndex := 1 to 20 do
    PopupAcceptedScanCodes[LineOrKeyIndex] := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Maps characters to the 8x8 glyph banks and embedded item sprites; caret marks the popup cursor. }
procedure DrawGameText(TextColumn, TextRow: Integer; DisplayText: string);
var
  CharacterIndex, GlyphIndex: Integer;
  FontCharacterMap: string;
begin
  FontCharacterMap := '~~~~~~~~~~~~~~~~~~|||||||||||||| !"#$%& ()*+,-./0123456789:;'
    + '<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    + #127#128#129#130#131#132#133#134#135#136#137#138#139#140
    + #141#142#143#144#145#146#147#148#149#150#151#152#153#154
    + #155#156#157#158#159#160#161#162#163#164#165#166#167#168
    + #169#170#171#172#173#174#175#176#177#178#179#180#181#182#183#184;
  for CharacterIndex := 1 to Length(DisplayText) do
  begin
    GlyphIndex := Pos(Copy(DisplayText, CharacterIndex, 1), FontCharacterMap);
    if Copy(DisplayText, CharacterIndex, 1) <> '^' then
      if (GlyphIndex >= 93) and (GlyphIndex < 118) then
        PgBlitMasked8x8(PopupExtendedGlyphBank^.GlyphEntries[GlyphIndex - 93 + 21].GlyphDataBytes[1], TextColumn +
        CharacterIndex - 1,
                 (TextRow shl 3) + DisplayedBufferRow)
      else if GlyphIndex <= 72 then
      begin
        case GlyphIndex of
          32..72: PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[GlyphIndex - 32 + 10].GlyphDataBytes[1],
                           TextColumn + CharacterIndex - 1, (TextRow shl 3) + DisplayedBufferRow);
        end;
      end
      else if GlyphIndex >= 118 then
      begin
        case GlyphIndex of
          118: PgBlitMasked16x16(SpriteBank851^.SpriteEntries[1].SpriteDataBytes[1], TextColumn + CharacterIndex - 1, (TextRow
          shl 3) + DisplayedBufferRow);
          119: PgBlitMasked16x16(SpriteBank851^.SpriteEntries[7].SpriteDataBytes[1], TextColumn + CharacterIndex - 1, (TextRow
          shl 3) + DisplayedBufferRow);
          120: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[15].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          121: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[16].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          122: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[13].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          123: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          124: PgBlitMasked16x16(SpriteBank101^.SpriteEntries[4].SpriteDataBytes[1], TextColumn + CharacterIndex - 1, (TextRow
          shl 3) + DisplayedBufferRow);
          125: PgBlitMasked16x16(SpriteBank101^.SpriteEntries[8].SpriteDataBytes[1], TextColumn + CharacterIndex - 1, (TextRow
          shl 3) + DisplayedBufferRow);
          126: PgBlitMasked16x16(SpriteBank101^.SpriteEntries[34].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          127: PgBlitMasked16x16(SpriteBank101^.SpriteEntries[21].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          128: PgBlitMasked16x16(SpriteBank401^.SpriteEntries[21].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          129: PgBlitMasked16x16(SpriteBank401^.SpriteEntries[23].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          130: PgBlitMasked16x16(SpriteBank401^.SpriteEntries[25].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          131: PgBlitMasked16x16(SpriteBank401^.SpriteEntries[22].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          132: PgBlitMasked16x16(SpriteBank401^.SpriteEntries[24].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          133: PgBlitMasked16x16(SpriteBank401^.SpriteEntries[26].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          134: PgBlitMasked16x16(SpriteBank401^.SpriteEntries[47].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          135: PgBlitMasked16x16(SpriteBank601^.SpriteEntries[4].SpriteDataBytes[1], TextColumn + CharacterIndex - 1, (TextRow
          shl 3) + DisplayedBufferRow);
          136: PgBlitMasked16x16(SpriteBank601^.SpriteEntries[5].SpriteDataBytes[1], TextColumn + CharacterIndex - 1, (TextRow
          shl 3) + DisplayedBufferRow);
          137: PgBlitMasked16x16(SpriteBank601^.SpriteEntries[33].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          138: PgBlitMasked16x16(SpriteBank601^.SpriteEntries[37].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          139: PgBlitMasked16x16(SpriteBank601^.SpriteEntries[19].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          140: PgBlitMasked16x16(SpriteBank601^.SpriteEntries[18].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          141: PgBlitMasked16x16(SpriteBank601^.SpriteEntries[20].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          142: PgBlitMasked16x16(SpriteBank601^.SpriteEntries[29].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          143: PgBlitMasked16x16(SpriteBank601^.SpriteEntries[30].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          144: PgBlitMasked16x16(SpriteBank601^.SpriteEntries[31].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          145: PgBlitMasked16x16(SpriteBank601^.SpriteEntries[32].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          146: PgBlitMasked16x16(SpriteBank601^.SpriteEntries[35].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          147: PgBlitMasked16x16(SpriteBank651^.SpriteEntries[25].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          148: PgBlitMasked16x16(SpriteBank301^.SpriteEntries[1].SpriteDataBytes[1], TextColumn + CharacterIndex - 1, (TextRow
          shl 3) + DisplayedBufferRow);
          149: PgBlitMasked16x16(SpriteBank301^.SpriteEntries[4].SpriteDataBytes[1], TextColumn + CharacterIndex - 1, (TextRow
          shl 3) + DisplayedBufferRow);
          150: PgBlitMasked16x16(SpriteBank301^.SpriteEntries[13].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          151: PgBlitMasked16x16(SpriteBank301^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          152: PgBlitMasked16x16(SpriteBank301^.SpriteEntries[16].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          153: PgBlitMasked16x16(SpriteBank801^.SpriteEntries[1].SpriteDataBytes[1], TextColumn + CharacterIndex - 1, (TextRow
          shl 3) + DisplayedBufferRow);
          154: PgBlitMasked16x16(SpriteBank801^.SpriteEntries[5].SpriteDataBytes[1], TextColumn + CharacterIndex - 1, (TextRow
          shl 3) + DisplayedBufferRow);
          155: PgBlitMasked16x16(SpriteBank801^.SpriteEntries[32].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          156: PgBlitMasked16x16(SpriteBank801^.SpriteEntries[36].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          157: PgBlitMasked16x16(SpriteBank801^.SpriteEntries[37].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          158: PgBlitMasked16x16(PlayerSpriteBank^.SpriteEntries[2].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          159: PgBlitMasked16x16(PlayerSpriteBank^.SpriteEntries[1].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          160: PgBlitMasked16x16(SpriteBank351^.SpriteEntries[1].SpriteDataBytes[1], TextColumn + CharacterIndex - 1, (TextRow
          shl 3) + DisplayedBufferRow);
          161: PgBlitMasked16x16(SpriteBank351^.SpriteEntries[9].SpriteDataBytes[1], TextColumn + CharacterIndex - 1, (TextRow
          shl 3) + DisplayedBufferRow);
          162: PgBlitMasked16x16(SpriteBank351^.SpriteEntries[18].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          163: PgBlitMasked16x16(SpriteBank351^.SpriteEntries[25].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          164: PgBlitMasked16x16(SpriteBank351^.SpriteEntries[36].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          165: PgBlitMasked16x16(SpriteBank151^.SpriteEntries[2].SpriteDataBytes[1], TextColumn + CharacterIndex - 1, (TextRow
          shl 3) + DisplayedBufferRow);
          166: PgBlitMasked16x16(SpriteBank151^.SpriteEntries[30].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          167: PgBlitMasked16x16(SpriteBank151^.SpriteEntries[33].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          168: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          169: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          170: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          171: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          172: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          173: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          174: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          175: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          176: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          177: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          178: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          179: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          180: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          181: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          182: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
          183: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[14].SpriteDataBytes[1], TextColumn + CharacterIndex - 1,
          (TextRow shl 3) + DisplayedBufferRow);
        end;
      end
      else
        PgBlitMasked8x8(PopupExtendedGlyphBank^.GlyphEntries[GlyphIndex - 72].GlyphDataBytes[1], TextColumn + CharacterIndex -
        1,
                 (TextRow shl 3) + DisplayedBufferRow);
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Centers and draws a popup, waits for a scan code (optionally from d_67FA). }
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
  unusedWord: Integer;
  KeyScanCode: Integer;
  SparkColumn: Integer;
  SparkPixelY: Integer;
  ReadPopupScanCode_SparkFrame: Integer;
  SparkOnTopBorder: Byte;
  ReadPopupScanCode_SparkActive: Byte;
  KeyAccepted: Byte;
begin
  CursorFrame := 1;
  CursorColumn := 0;
  CursorRow := 0;
  MaxLineColumns := 0;
  PopupRowCount := 0;
  KeyAccepted := 0;
  ReadPopupScanCode_SparkActive := 0;
  for SharedLoopIndexB := 1 to 20 do
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
  LeftColumn := (((320 - (MaxLineColumns shl 3)) div 2 + CameraX) div 8) - 3;
  TopRow := (((200 - (PopupRowCount shl 3)) div 2 + CameraY) div 8) - 2;
  if CursorColumn <> 0 then
    CursorColumn := CursorColumn + LeftColumn;
  CursorRow := CursorRow + TopRow;
  GetMem(PopupSavedBackground, 30000);
  PgCapturePlanarRectangle(PRawByteView(PopupSavedBackground)^[0], LeftColumn,
    (TopRow shl 3) + DisplayedBufferRow, LeftColumn + MaxLineColumns + 5 + 1,
    ((TopRow + PopupRowCount + 2 + 1) shl 3) + DisplayedBufferRow);
  RightColumn := LeftColumn + MaxLineColumns + 4;
  BottomRow := TopRow + PopupRowCount + 1;

  for SharedLoopIndexC := 1 to BottomRow - TopRow do
    for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
      PgBlitOpaque8x8(PRawByteView(PopupFrameAndGlyphBank)^[323], SharedLoopIndexB,
        ((TopRow + SharedLoopIndexC) shl 3) + DisplayedBufferRow);
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[3], LeftColumn, (TopRow shl 3) + DisplayedBufferRow);
  for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[43], SharedLoopIndexB, (TopRow shl 3) + DisplayedBufferRow);
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[83], RightColumn, (TopRow shl 3) + DisplayedBufferRow);
  for SharedLoopIndexB := 1 to BottomRow - TopRow do
  begin
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[203], LeftColumn,
      ((TopRow + SharedLoopIndexB) shl 3) + DisplayedBufferRow);
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[283], RightColumn,
      ((TopRow + SharedLoopIndexB) shl 3) + DisplayedBufferRow);
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[363], RightColumn + 1,
      ((TopRow + SharedLoopIndexB) shl 3) + DisplayedBufferRow);
  end;
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[363], RightColumn + 1,
    ((BottomRow - TopRow + TopRow + 1) shl 3) + DisplayedBufferRow);
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[163], LeftColumn, (BottomRow shl 3) + DisplayedBufferRow);
  for SharedLoopIndexB := LeftColumn + 1 to RightColumn - 1 do
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[243], SharedLoopIndexB, (BottomRow shl 3) + DisplayedBufferRow);
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[123], RightColumn, (BottomRow shl 3) + DisplayedBufferRow);
  for SharedLoopIndexB := LeftColumn + 1 to RightColumn + 1 do
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[363], SharedLoopIndexB, ((BottomRow + 1) shl 3) +
    DisplayedBufferRow);

  for SharedLoopIndexB := 1 to PopupRowCount do
    if PopupTextLines[SharedLoopIndexB] <> 'END OF WINDOW' then
      DrawGameText(LeftColumn + 2, TopRow + SharedLoopIndexB + 1,
        PopupTextLines[SharedLoopIndexB]);

  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  repeat
    MemW[0:$041C] := MemW[0:$041A];
  until LastKeyboardScanCode > $80;
  StartSoundEffect($11);
  repeat
    repeat
    MemW[0:$041C] := MemW[0:$041A];
    SharedLoopIndexB := Random(100);
    if (ReadPopupScanCode_SparkActive = 0) and (SharedLoopIndexB >= 99) then
    begin
      ReadPopupScanCode_SparkActive := 1;
      ReadPopupScanCode_SparkFrame := 0;
      case Random(2) of
        0:
          begin
            SparkColumn := LeftColumn + Random(RightColumn - LeftColumn - 2) + 1;
            SparkPixelY := TopRow shl 3;
            SparkOnTopBorder := 1;
          end;
        1:
          begin
            SparkColumn := LeftColumn;
            SparkPixelY := (TopRow + Random(BottomRow - TopRow - 2) + 1) * 8;
            SparkOnTopBorder := 0;
          end;
      end;
    end;
    if (CursorColumn <> 0) and (GameTickCounter > $14) then
    begin
      GameTickCounter := 0;
      PgBlitOpaque8x8(PRawByteView(PopupFrameAndGlyphBank)^[323], CursorColumn, (CursorRow shl 3) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupExtendedGlyphBank^.GlyphEntries[CursorFrame + 45].GlyphDataBytes[1], CursorColumn,
        (CursorRow shl 3) + DisplayedBufferRow);
      Inc(CursorFrame);
      if CursorFrame > 5 then
        CursorFrame := 1;
      if ReadPopupScanCode_SparkActive <> 0 then
      begin
        Inc(ReadPopupScanCode_SparkFrame);
        if ReadPopupScanCode_SparkFrame > 4 then
        begin
          ReadPopupScanCode_SparkActive := 0;
          if SparkOnTopBorder <> 0 then
            PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[43], SparkColumn, SparkPixelY + DisplayedBufferRow)
          else
            PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[203], SparkColumn, SparkPixelY + DisplayedBufferRow);
        end
        else
        begin
          if SparkOnTopBorder <> 0 then
            PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[43], SparkColumn, SparkPixelY + DisplayedBufferRow)
          else
            PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[203], SparkColumn, SparkPixelY + DisplayedBufferRow);
          PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[ReadPopupScanCode_SparkFrame + 37].GlyphDataBytes[1],
          SparkColumn,
            SparkPixelY + DisplayedBufferRow);
        end;
      end;
    end;
    until (LastKeyboardScanCode < $80) or (LastKeyboardScanCode = $E0);
    KeyScanCode := LastKeyboardScanCode;
      if KeyScanCode = $E0 then
      begin
        repeat
          MemW[0:$041C] := MemW[0:$041A];
        until LastKeyboardScanCode in [156,157,170,181,184,197,199,200,201,203,205,207,208,209,210,211];
        if LastKeyboardScanCode in [170,197] then
          LastKeyboardScanCode := 500;
        KeyScanCode := LastKeyboardScanCode - $80;
      end
      else
      begin
        repeat
          MemW[0:$041C] := MemW[0:$041A];
        until LastKeyboardScanCode > $80;
      end;

      if AcceptAnyKey = 0 then
      begin
        for SharedLoopIndexB := 1 to 20 do
          if (PopupAcceptedScanCodes[SharedLoopIndexB] <> 0) and (PopupAcceptedScanCodes[SharedLoopIndexB] = KeyScanCode) then
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
  PgRestorePlanarRectangle(PopupSavedBackground^[0], LeftColumn,
    (TopRow shl 3) + DisplayedBufferRow);
  FreeMem(PopupSavedBackground, 30000);
  MemW[0:$041C] := MemW[0:$041A];
  PopupInputReservedFlag := 0;
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
  ReadPopupText_CursorColumn, ReadPopupText_CursorRow: Integer;
  ReadPopupText_CursorFrame: Integer;
  ReadPopupText_MaxLineColumns, ReadPopupText_PopupRowCount: Integer;
  ReadPopupText_LeftColumn, ReadPopupText_TopRow, ReadPopupText_RightColumn, ReadPopupText_BottomRow, InputLength: Integer;
  UnusedWord, ReadPopupText_SparkColumn, ReadPopupText_SparkPixelY, ReadPopupText_SparkFrame: Integer;
  ReadPopupText_SparkOnTopBorder, ReadPopupText_SparkActive: Byte;
  FramePad: array[0..1] of Byte;
  EditedText: String;
  InputChar: Char;
begin
  ReadPopupText_CursorFrame := 1;
  ReadPopupText_CursorColumn := 0;
  ReadPopupText_MaxLineColumns := 0;
  ReadPopupText_PopupRowCount := 0;
  FramePad[1] := 0;
  ReadPopupText_SparkActive := 0;
  for SharedLoopIndexB := 1 to 20 do
  begin
    if SharedLoopIndexB = 1 then
      ReadPopupText_MaxLineColumns := Length(PopupTextLines[SharedLoopIndexB]) - 1;
    if Length(PopupTextLines[SharedLoopIndexB]) > ReadPopupText_MaxLineColumns then
      ReadPopupText_MaxLineColumns := Length(PopupTextLines[SharedLoopIndexB]) - 1;
    if PopupTextLines[SharedLoopIndexB] = 'END OF WINDOW' then
      ReadPopupText_PopupRowCount := SharedLoopIndexB - 2;
    for SharedLoopIndexA := 1 to Length(PopupTextLines[SharedLoopIndexB]) do
      if Copy(PopupTextLines[SharedLoopIndexB], SharedLoopIndexA, 1) = '^' then
      begin
        ReadPopupText_CursorColumn := Pos('^', PopupTextLines[SharedLoopIndexB]) + 1;
        ReadPopupText_CursorRow := SharedLoopIndexB + 1;
      end;
  end;

  Inc(ReadPopupText_PopupRowCount, 3);
  ReadPopupText_LeftColumn := ((320 - (ReadPopupText_MaxLineColumns shl 3)) div 2 + CameraX) div 8 - 3;
  ReadPopupText_TopRow := ((200 - (ReadPopupText_PopupRowCount shl 3)) div 2 + CameraY) div 8 - 2;
  ReadPopupText_CursorColumn := ReadPopupText_CursorColumn + ReadPopupText_LeftColumn;
  ReadPopupText_CursorRow := ReadPopupText_CursorRow + ReadPopupText_TopRow;
  GetMem(PopupSavedBackground, $7530);
  PgCapturePlanarRectangle(PRawByteView(PopupSavedBackground)^, ReadPopupText_LeftColumn, (ReadPopupText_TopRow shl 3) +
  DisplayedBufferRow,
    ReadPopupText_LeftColumn + ReadPopupText_MaxLineColumns + 5 + 1,
    (Succ(ReadPopupText_TopRow + ReadPopupText_PopupRowCount + 2) shl 3) + DisplayedBufferRow);
  ReadPopupText_RightColumn := ReadPopupText_LeftColumn + ReadPopupText_MaxLineColumns + 4;
  ReadPopupText_BottomRow := ReadPopupText_TopRow + ReadPopupText_PopupRowCount + 1;

  for SharedLoopIndexC := 1 to ReadPopupText_BottomRow - ReadPopupText_TopRow do
    for SharedLoopIndexB := ReadPopupText_LeftColumn + 1 to ReadPopupText_RightColumn - 1 do
      PgBlitOpaque8x8(PRawByteView(PopupFrameAndGlyphBank)^[323], SharedLoopIndexB,
        ((ReadPopupText_TopRow + SharedLoopIndexC) shl 3) + DisplayedBufferRow);

  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[3], ReadPopupText_LeftColumn, (ReadPopupText_TopRow shl 3) +
  DisplayedBufferRow);
  for SharedLoopIndexB := ReadPopupText_LeftColumn + 1 to ReadPopupText_RightColumn - 1 do
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[43], SharedLoopIndexB, (ReadPopupText_TopRow shl 3) +
    DisplayedBufferRow);
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[83], ReadPopupText_RightColumn, (ReadPopupText_TopRow shl 3) +
  DisplayedBufferRow);
  for SharedLoopIndexB := 1 to ReadPopupText_BottomRow - ReadPopupText_TopRow do
  begin
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[203], ReadPopupText_LeftColumn, ((ReadPopupText_TopRow +
    SharedLoopIndexB) shl 3) + DisplayedBufferRow);
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[283], ReadPopupText_RightColumn, ((ReadPopupText_TopRow +
    SharedLoopIndexB) shl 3) + DisplayedBufferRow);
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[363], ReadPopupText_RightColumn + 1, ((ReadPopupText_TopRow +
    SharedLoopIndexB) shl 3) + DisplayedBufferRow);
  end;
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[363], ReadPopupText_RightColumn + 1,
    ((ReadPopupText_TopRow + (ReadPopupText_BottomRow - ReadPopupText_TopRow) + 1) shl 3) + DisplayedBufferRow);
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[163], ReadPopupText_LeftColumn, (ReadPopupText_BottomRow shl 3) +
  DisplayedBufferRow);
  for SharedLoopIndexB := ReadPopupText_LeftColumn + 1 to ReadPopupText_RightColumn - 1 do
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[243], SharedLoopIndexB, (ReadPopupText_BottomRow shl 3) +
    DisplayedBufferRow);
  PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[123], ReadPopupText_RightColumn, (ReadPopupText_BottomRow shl 3) +
  DisplayedBufferRow);
  for SharedLoopIndexB := ReadPopupText_LeftColumn + 1 to ReadPopupText_RightColumn + 1 do
    PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[363], SharedLoopIndexB, ((ReadPopupText_BottomRow + 1) shl 3) +
    DisplayedBufferRow);

  for SharedLoopIndexB := 1 to ReadPopupText_PopupRowCount do
    if PopupTextLines[SharedLoopIndexB] <> 'END OF WINDOW' then
      DrawGameText(ReadPopupText_LeftColumn + 2, ReadPopupText_TopRow + SharedLoopIndexB + 1,
      PopupTextLines[SharedLoopIndexB]);

  PlayerUpHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  PlayerDownHeld := 0;
  repeat
    MemW[0:$041C] := MemW[0:$041A];
  until Port[$60] > $80;

  EditedText[0] := #0;
  InputLength := 0;
  InputChar := 'Z';
  while InputChar <> #13 do
  begin
    if KeyPressed then
    begin
      InputChar := ReadKey;
      if InputChar in [' ', '0'..'9', 'A'..'Z', 'a'..'z'] then
      begin
        if InputChar >= #32 then
        begin
          if InputChar <= #127 then
          begin
            if InputLength < MaxInputLength then
            begin
              EditedText := EditedText + InputChar;
              Inc(InputLength);
              PgBlitOpaque8x8(PRawByteView(PopupFrameAndGlyphBank)^[323], ReadPopupText_CursorColumn, (ReadPopupText_CursorRow
              shl 3) + DisplayedBufferRow);
              DrawGameText(ReadPopupText_CursorColumn, ReadPopupText_CursorRow, InputChar);
              Inc(ReadPopupText_CursorColumn);
            end;
          end;
        end;
      end
      else if InputChar = #8 then
      begin
        if InputLength > 0 then
        begin
            PgBlitOpaque8x8(PRawByteView(PopupFrameAndGlyphBank)^[323], ReadPopupText_CursorColumn, (ReadPopupText_CursorRow
            shl 3) + DisplayedBufferRow);
          Dec(ReadPopupText_CursorColumn);
            PgBlitOpaque8x8(PRawByteView(PopupFrameAndGlyphBank)^[323], ReadPopupText_CursorColumn, (ReadPopupText_CursorRow
            shl 3) + DisplayedBufferRow);
          Delete(EditedText, Length(EditedText), 1);
          Dec(InputLength);
        end;
      end;
    end;

    SharedLoopIndexB := Random(100);
    if (ReadPopupText_SparkActive = 0) and (SharedLoopIndexB >= 99) then
    begin
      ReadPopupText_SparkActive := 1;
      ReadPopupText_SparkFrame := 0;
      case Random(2) of
        0:
          begin
            ReadPopupText_SparkColumn := ReadPopupText_LeftColumn + Random(ReadPopupText_RightColumn -
            ReadPopupText_LeftColumn - 2) + 1;
            ReadPopupText_SparkPixelY := ReadPopupText_TopRow shl 3;
            ReadPopupText_SparkOnTopBorder := 1;
          end;
        1:
          begin
            ReadPopupText_SparkColumn := ReadPopupText_LeftColumn;
            ReadPopupText_SparkPixelY := (ReadPopupText_TopRow + Random(ReadPopupText_BottomRow - ReadPopupText_TopRow - 2) +
            1) * 8;
            ReadPopupText_SparkOnTopBorder := 0;
          end;
      end;
    end;

    if GameTickCounter > 20 then
    begin
      GameTickCounter := 0;
        PgBlitOpaque8x8(PRawByteView(PopupFrameAndGlyphBank)^[323], ReadPopupText_CursorColumn, (ReadPopupText_CursorRow shl
        3) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupExtendedGlyphBank^.GlyphEntries[ReadPopupText_CursorFrame + 45].GlyphDataBytes[1],
      ReadPopupText_CursorColumn,
        (ReadPopupText_CursorRow shl 3) + DisplayedBufferRow);
      Inc(ReadPopupText_CursorFrame);
      if ReadPopupText_CursorFrame > 5 then
        ReadPopupText_CursorFrame := 1;
      if ReadPopupText_SparkActive <> 0 then
      begin
        Inc(ReadPopupText_SparkFrame);
        if ReadPopupText_SparkFrame > 4 then
        begin
          ReadPopupText_SparkActive := 0;
          if ReadPopupText_SparkOnTopBorder <> 0 then
              PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[43], ReadPopupText_SparkColumn, ReadPopupText_SparkPixelY
              + DisplayedBufferRow)
          else
              PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[203], ReadPopupText_SparkColumn, ReadPopupText_SparkPixelY
              + DisplayedBufferRow);
        end
        else
        begin
          if ReadPopupText_SparkOnTopBorder <> 0 then
            PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[43], ReadPopupText_SparkColumn, ReadPopupText_SparkPixelY +
            DisplayedBufferRow)
          else
            PgBlitMasked8x8(PRawByteView(PopupFrameAndGlyphBank)^[203], ReadPopupText_SparkColumn, ReadPopupText_SparkPixelY +
            DisplayedBufferRow);
          PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[ReadPopupText_SparkFrame + 37].GlyphDataBytes[1],
          ReadPopupText_SparkColumn,
            ReadPopupText_SparkPixelY + DisplayedBufferRow);
        end;
      end;
    end;
  end;

  ReadPopupText := EditedText;
  PgRestorePlanarRectangle(PRawByteView(PopupSavedBackground)^, ReadPopupText_LeftColumn, (ReadPopupText_TopRow shl 3) +
  DisplayedBufferRow);
  FreeMem(PopupSavedBackground, $7530);
  MemW[0:$041C] := MemW[0:$041A];
  PlayerUpHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  PlayerDownHeld := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Pages through up to 299 text lines on Up/PgUp and Down/PgDn; returns the selected scan code. }
function ReadScrollablePopupScanCode(ReadScrollablePopu_AcceptAnyKey: Byte): Byte;
var
  ReadScrollablePopu_CursorColumn, ReadScrollablePopupSc_CursorRow, FirstLine: Integer;
  ReadScrollablePo_MaxLineColumns, VisiblePopupRows, TotalTextRows: Integer;
  ReadScrollablePopupS_LeftColumn, ReadScrollablePopupScanC_TopRow, ReadScrollablePopup_RightColumn,
  ReadScrollablePopupSc_BottomRow: Integer;
  ScrollLineOffset, PreviousKey, ReadScrollablePopup_KeyScanCode: Integer;
  ReadScrollablePopup_SparkColumn, ReadScrollablePopup_SparkPixelY, SparkFrameIndex: Integer;
  ReadScrollable_SparkOnTopBorder, IsSparkActive, ReadScrollablePopup_KeyAccepted: Boolean;
begin
  FirstLine := 1;
  ReadScrollablePopu_CursorColumn := 0;
  ReadScrollablePo_MaxLineColumns := 0;
  VisiblePopupRows := 0;
  TotalTextRows := 0;
  ScrollLineOffset := 0;
  ReadScrollablePopup_KeyAccepted := False;
  IsSparkActive := False;
  for SharedLoopIndexB := 1 to 299 do
  begin
    if SharedLoopIndexB = 1 then ReadScrollablePo_MaxLineColumns := Length(PopupTextLines[SharedLoopIndexB]) - 1;
    if Length(PopupTextLines[SharedLoopIndexB]) > ReadScrollablePo_MaxLineColumns then
      ReadScrollablePo_MaxLineColumns := Length(PopupTextLines[SharedLoopIndexB]) - 1;
    if PopupTextLines[SharedLoopIndexB] = 'END OF WINDOW' then VisiblePopupRows := SharedLoopIndexB - 2;
    for SharedLoopIndexA := 1 to Length(PopupTextLines[SharedLoopIndexB]) do
      if Copy(PopupTextLines[SharedLoopIndexB], SharedLoopIndexA, 1) = '^' then
      begin
        ReadScrollablePopu_CursorColumn := Pos('^', PopupTextLines[SharedLoopIndexB]) + 1;
        ReadScrollablePopupSc_CursorRow := SharedLoopIndexB + 1;
      end;
  end;
  TotalTextRows := VisiblePopupRows;
  if VisiblePopupRows > 16 then VisiblePopupRows := 16;
  Inc(VisiblePopupRows, 3);
  ReadScrollablePopupS_LeftColumn := (((320 - (ReadScrollablePo_MaxLineColumns shl 3)) div 2 + CameraX) div 8) - 3;
  ReadScrollablePopupScanC_TopRow := (((200 - (VisiblePopupRows shl 3)) div 2 + CameraY) div 8) - 2;
  ReadScrollablePopu_CursorColumn := ReadScrollablePopu_CursorColumn + ReadScrollablePopupS_LeftColumn;
  ReadScrollablePopupSc_CursorRow := ReadScrollablePopupSc_CursorRow + ReadScrollablePopupScanC_TopRow;
  GetMem(PopupSavedBackground, 30000);
  PgCapturePlanarRectangle(PopupSavedBackground^, ReadScrollablePopupS_LeftColumn, (ReadScrollablePopupScanC_TopRow shl 3) +
  DisplayedBufferRow,
    ReadScrollablePopupS_LeftColumn + ReadScrollablePo_MaxLineColumns + 5 + 1, ((ReadScrollablePopupScanC_TopRow +
    VisiblePopupRows + 2 + 1) shl 3) + DisplayedBufferRow);
  ReadScrollablePopup_RightColumn := ReadScrollablePopupS_LeftColumn + ReadScrollablePo_MaxLineColumns + 4;
  ReadScrollablePopupSc_BottomRow := ReadScrollablePopupScanC_TopRow + VisiblePopupRows + 1;
  for SharedLoopIndexC := 1 to ReadScrollablePopupSc_BottomRow - ReadScrollablePopupScanC_TopRow do
    for SharedLoopIndexB := ReadScrollablePopupS_LeftColumn + 1 to ReadScrollablePopup_RightColumn - 1 do
      PgBlitOpaque8x8(PopupFrameAndGlyphBank^.GlyphEntries[9].GlyphDataBytes[1], SharedLoopIndexB,
        ((ReadScrollablePopupScanC_TopRow + SharedLoopIndexC) shl 3) + DisplayedBufferRow);
  PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[1].GlyphDataBytes[1], ReadScrollablePopupS_LeftColumn,
  (ReadScrollablePopupScanC_TopRow shl 3) + DisplayedBufferRow);
  for SharedLoopIndexB := ReadScrollablePopupS_LeftColumn + 1 to ReadScrollablePopup_RightColumn - 1 do
    PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[2].GlyphDataBytes[1], SharedLoopIndexB,
    (ReadScrollablePopupScanC_TopRow shl 3) + DisplayedBufferRow);
  PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[3].GlyphDataBytes[1], ReadScrollablePopup_RightColumn,
  (ReadScrollablePopupScanC_TopRow shl 3) + DisplayedBufferRow);
  for SharedLoopIndexB := 1 to ReadScrollablePopupSc_BottomRow - ReadScrollablePopupScanC_TopRow do
  begin
    PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[6].GlyphDataBytes[1], ReadScrollablePopupS_LeftColumn,
      ((ReadScrollablePopupScanC_TopRow + SharedLoopIndexB) shl 3) + DisplayedBufferRow);
    PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[8].GlyphDataBytes[1], ReadScrollablePopup_RightColumn,
      ((ReadScrollablePopupScanC_TopRow + SharedLoopIndexB) shl 3) + DisplayedBufferRow);
    PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[10].GlyphDataBytes[1], ReadScrollablePopup_RightColumn + 1,
      ((ReadScrollablePopupScanC_TopRow + SharedLoopIndexB) shl 3) + DisplayedBufferRow);
  end;
  PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[10].GlyphDataBytes[1], ReadScrollablePopup_RightColumn + 1,
    ((ReadScrollablePopupSc_BottomRow - ReadScrollablePopupScanC_TopRow + ReadScrollablePopupScanC_TopRow + 1) shl 3) +
    DisplayedBufferRow);
  PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[5].GlyphDataBytes[1], ReadScrollablePopupS_LeftColumn,
  (ReadScrollablePopupSc_BottomRow shl 3) + DisplayedBufferRow);
  for SharedLoopIndexB := ReadScrollablePopupS_LeftColumn + 1 to ReadScrollablePopup_RightColumn - 1 do
    PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[7].GlyphDataBytes[1], SharedLoopIndexB,
    (ReadScrollablePopupSc_BottomRow shl 3) + DisplayedBufferRow);
  PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[4].GlyphDataBytes[1], ReadScrollablePopup_RightColumn,
  (ReadScrollablePopupSc_BottomRow shl 3) + DisplayedBufferRow);
  for SharedLoopIndexB := ReadScrollablePopupS_LeftColumn + 1 to ReadScrollablePopup_RightColumn + 1 do
    PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[10].GlyphDataBytes[1], SharedLoopIndexB,
      ((ReadScrollablePopupSc_BottomRow + 1) shl 3) + DisplayedBufferRow);
  for SharedLoopIndexB := 1 to VisiblePopupRows - 2 do
    if PopupTextLines[SharedLoopIndexB] <> 'END OF WINDOW' then
      DrawGameText(ReadScrollablePopupS_LeftColumn + 2, ReadScrollablePopupScanC_TopRow + SharedLoopIndexB + 1,
      PopupTextLines[SharedLoopIndexB]);
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  repeat
    MemW[0:$41C] := MemW[0:$41A];
  until LastKeyboardScanCode > 128;
  repeat
    repeat
      MemW[0:$41C] := MemW[0:$41A];
      SharedLoopIndexB := Random(100);
      if (not IsSparkActive) and (SharedLoopIndexB >= 99) then
      begin
        IsSparkActive := True;
        SparkFrameIndex := 0;
        case Random(2) of
          0: begin
            ReadScrollablePopup_SparkColumn := ReadScrollablePopupS_LeftColumn + Random(ReadScrollablePopup_RightColumn -
            ReadScrollablePopupS_LeftColumn - 2) + 1;
            ReadScrollablePopup_SparkPixelY := ReadScrollablePopupScanC_TopRow shl 3;
            ReadScrollable_SparkOnTopBorder := True;
          end;
          1: begin
            ReadScrollablePopup_SparkColumn := ReadScrollablePopupS_LeftColumn;
            ReadScrollablePopup_SparkPixelY := (ReadScrollablePopupScanC_TopRow + Random(ReadScrollablePopupSc_BottomRow -
            ReadScrollablePopupScanC_TopRow - 2) + 1) * 8;
            ReadScrollable_SparkOnTopBorder := False;
          end;
        end;
      end;
      if (ReadScrollablePopu_CursorColumn <> 0) and (GameTickCounter > 20) then
      begin
        GameTickCounter := 0;
        if IsSparkActive then
        begin
          Inc(SparkFrameIndex);
          if SparkFrameIndex > 4 then
          begin
            IsSparkActive := False;
            if ReadScrollable_SparkOnTopBorder then
              PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[2].GlyphDataBytes[1], ReadScrollablePopup_SparkColumn,
              ReadScrollablePopup_SparkPixelY + DisplayedBufferRow)
            else
              PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[6].GlyphDataBytes[1], ReadScrollablePopup_SparkColumn,
              ReadScrollablePopup_SparkPixelY + DisplayedBufferRow);
          end
          else
          begin
            if ReadScrollable_SparkOnTopBorder then
              PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[2].GlyphDataBytes[1], ReadScrollablePopup_SparkColumn,
              ReadScrollablePopup_SparkPixelY + DisplayedBufferRow)
            else
              PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[6].GlyphDataBytes[1], ReadScrollablePopup_SparkColumn,
              ReadScrollablePopup_SparkPixelY + DisplayedBufferRow);
            PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[SparkFrameIndex + 37].GlyphDataBytes[1],
              ReadScrollablePopup_SparkColumn, ReadScrollablePopup_SparkPixelY + DisplayedBufferRow);
          end;
        end;
      end;
    until (LastKeyboardScanCode < 128) or (LastKeyboardScanCode = 224);
    ReadScrollablePopup_KeyScanCode := LastKeyboardScanCode;
    if ReadScrollablePopup_KeyScanCode = 224 then
    begin
      repeat
        MemW[0:$41C] := MemW[0:$41A];
      until Byte(LastKeyboardScanCode) in [156,157,170,181,184,197,199,200,201,
        203,205,207,208,209,210,211];
      if Byte(LastKeyboardScanCode) in [170,197] then LastKeyboardScanCode := 500;
      ReadScrollablePopup_KeyScanCode := LastKeyboardScanCode - 128;
    end
    else
      repeat
        MemW[0:$41C] := MemW[0:$41A];
      until LastKeyboardScanCode > 128;
    if (ReadScrollablePopup_KeyScanCode = 80) or (ReadScrollablePopup_KeyScanCode = 81) then
    begin
      Inc(ScrollLineOffset, 17);
      if TotalTextRows - 16 < ScrollLineOffset then ScrollLineOffset := TotalTextRows - 16;
      for SharedLoopIndexC := 1 to ReadScrollablePopupSc_BottomRow - ReadScrollablePopupScanC_TopRow - 1 do
        for SharedLoopIndexB := ReadScrollablePopupS_LeftColumn + 1 to ReadScrollablePopup_RightColumn - 1 do
          PgBlitOpaque8x8(PopupFrameAndGlyphBank^.GlyphEntries[9].GlyphDataBytes[1], SharedLoopIndexB,
            ((ReadScrollablePopupScanC_TopRow + SharedLoopIndexC) shl 3) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[1].GlyphDataBytes[1], ReadScrollablePopupS_LeftColumn,
      (ReadScrollablePopupScanC_TopRow shl 3) + DisplayedBufferRow);
      for SharedLoopIndexB := ReadScrollablePopupS_LeftColumn + 1 to ReadScrollablePopup_RightColumn - 1 do
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[2].GlyphDataBytes[1], SharedLoopIndexB,
        (ReadScrollablePopupScanC_TopRow shl 3) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[3].GlyphDataBytes[1], ReadScrollablePopup_RightColumn,
      (ReadScrollablePopupScanC_TopRow shl 3) + DisplayedBufferRow);
      for SharedLoopIndexB := 1 to ReadScrollablePopupSc_BottomRow - ReadScrollablePopupScanC_TopRow do
      begin
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[6].GlyphDataBytes[1], ReadScrollablePopupS_LeftColumn,
          ((ReadScrollablePopupScanC_TopRow + SharedLoopIndexB) shl 3) + DisplayedBufferRow);
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[8].GlyphDataBytes[1], ReadScrollablePopup_RightColumn,
          ((ReadScrollablePopupScanC_TopRow + SharedLoopIndexB) shl 3) + DisplayedBufferRow);
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[10].GlyphDataBytes[1], ReadScrollablePopup_RightColumn + 1,
          ((ReadScrollablePopupScanC_TopRow + SharedLoopIndexB) shl 3) + DisplayedBufferRow);
      end;
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[10].GlyphDataBytes[1], ReadScrollablePopup_RightColumn + 1,
        ((ReadScrollablePopupSc_BottomRow - ReadScrollablePopupScanC_TopRow + ReadScrollablePopupScanC_TopRow + 1) shl 3) +
        DisplayedBufferRow);
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[5].GlyphDataBytes[1], ReadScrollablePopupS_LeftColumn,
      (ReadScrollablePopupSc_BottomRow shl 3) + DisplayedBufferRow);
      for SharedLoopIndexB := ReadScrollablePopupS_LeftColumn + 1 to ReadScrollablePopup_RightColumn - 1 do
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[7].GlyphDataBytes[1], SharedLoopIndexB,
        (ReadScrollablePopupSc_BottomRow shl 3) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[4].GlyphDataBytes[1], ReadScrollablePopup_RightColumn,
      (ReadScrollablePopupSc_BottomRow shl 3) + DisplayedBufferRow);
      for SharedLoopIndexB := ReadScrollablePopupS_LeftColumn + 1 to ReadScrollablePopup_RightColumn + 1 do
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[10].GlyphDataBytes[1], SharedLoopIndexB,
          ((ReadScrollablePopupSc_BottomRow + 1) shl 3) + DisplayedBufferRow);
      for SharedLoopIndexB := 1 to VisiblePopupRows - 2 do
        if PopupTextLines[SharedLoopIndexB] <> 'END OF WINDOW' then
          DrawGameText(ReadScrollablePopupS_LeftColumn + 2, ReadScrollablePopupScanC_TopRow + SharedLoopIndexB + 1,
          PopupTextLines[SharedLoopIndexB + ScrollLineOffset]);
    end;
    if (ReadScrollablePopup_KeyScanCode = 72) or (ReadScrollablePopup_KeyScanCode = 73) then
    begin
      Dec(ScrollLineOffset, 17);
      if ScrollLineOffset < 0 then ScrollLineOffset := 0;
      for SharedLoopIndexC := 1 to ReadScrollablePopupSc_BottomRow - ReadScrollablePopupScanC_TopRow - 1 do
        for SharedLoopIndexB := ReadScrollablePopupS_LeftColumn + 1 to ReadScrollablePopup_RightColumn - 1 do
          PgBlitOpaque8x8(PopupFrameAndGlyphBank^.GlyphEntries[9].GlyphDataBytes[1], SharedLoopIndexB,
            ((ReadScrollablePopupScanC_TopRow + SharedLoopIndexC) shl 3) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[1].GlyphDataBytes[1], ReadScrollablePopupS_LeftColumn,
      (ReadScrollablePopupScanC_TopRow shl 3) + DisplayedBufferRow);
      for SharedLoopIndexB := ReadScrollablePopupS_LeftColumn + 1 to ReadScrollablePopup_RightColumn - 1 do
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[2].GlyphDataBytes[1], SharedLoopIndexB,
        (ReadScrollablePopupScanC_TopRow shl 3) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[3].GlyphDataBytes[1], ReadScrollablePopup_RightColumn,
      (ReadScrollablePopupScanC_TopRow shl 3) + DisplayedBufferRow);
      for SharedLoopIndexB := 1 to ReadScrollablePopupSc_BottomRow - ReadScrollablePopupScanC_TopRow do
      begin
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[6].GlyphDataBytes[1], ReadScrollablePopupS_LeftColumn,
          ((ReadScrollablePopupScanC_TopRow + SharedLoopIndexB) shl 3) + DisplayedBufferRow);
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[8].GlyphDataBytes[1], ReadScrollablePopup_RightColumn,
          ((ReadScrollablePopupScanC_TopRow + SharedLoopIndexB) shl 3) + DisplayedBufferRow);
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[10].GlyphDataBytes[1], ReadScrollablePopup_RightColumn + 1,
          ((ReadScrollablePopupScanC_TopRow + SharedLoopIndexB) shl 3) + DisplayedBufferRow);
      end;
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[10].GlyphDataBytes[1], ReadScrollablePopup_RightColumn + 1,
        ((ReadScrollablePopupSc_BottomRow - ReadScrollablePopupScanC_TopRow + ReadScrollablePopupScanC_TopRow + 1) shl 3) +
        DisplayedBufferRow);
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[5].GlyphDataBytes[1], ReadScrollablePopupS_LeftColumn,
      (ReadScrollablePopupSc_BottomRow shl 3) + DisplayedBufferRow);
      for SharedLoopIndexB := ReadScrollablePopupS_LeftColumn + 1 to ReadScrollablePopup_RightColumn - 1 do
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[7].GlyphDataBytes[1], SharedLoopIndexB,
        (ReadScrollablePopupSc_BottomRow shl 3) + DisplayedBufferRow);
      PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[4].GlyphDataBytes[1], ReadScrollablePopup_RightColumn,
      (ReadScrollablePopupSc_BottomRow shl 3) + DisplayedBufferRow);
      for SharedLoopIndexB := ReadScrollablePopupS_LeftColumn + 1 to ReadScrollablePopup_RightColumn + 1 do
        PgBlitMasked8x8(PopupFrameAndGlyphBank^.GlyphEntries[10].GlyphDataBytes[1], SharedLoopIndexB,
          ((ReadScrollablePopupSc_BottomRow + 1) shl 3) + DisplayedBufferRow);
      for SharedLoopIndexB := 1 to VisiblePopupRows - 2 do
        if PopupTextLines[SharedLoopIndexB] <> 'END OF WINDOW' then
          DrawGameText(ReadScrollablePopupS_LeftColumn + 2, ReadScrollablePopupScanC_TopRow + SharedLoopIndexB + 1,
          PopupTextLines[SharedLoopIndexB + ScrollLineOffset]);
    end;
    if ReadScrollablePopu_AcceptAnyKey = 0 then
    begin
      for SharedLoopIndexB := 1 to 20 do
        if (PopupAcceptedScanCodes[SharedLoopIndexB] <> 0) and (PopupAcceptedScanCodes[SharedLoopIndexB] =
        ReadScrollablePopup_KeyScanCode) then
        begin
          ReadScrollablePopupScanCode := ReadScrollablePopup_KeyScanCode;
          ReadScrollablePopup_KeyAccepted := True;
        end;
    end
    else
    begin
      ReadScrollablePopupScanCode := ReadScrollablePopup_KeyScanCode;
      ReadScrollablePopup_KeyAccepted := True;
    end;
  until ReadScrollablePopup_KeyAccepted;
  PgRestorePlanarRectangle(PopupSavedBackground^, ReadScrollablePopupS_LeftColumn, (ReadScrollablePopupScanC_TopRow shl 3) +
  DisplayedBufferRow);
  FreeMem(PopupSavedBackground, 30000);
  MemW[0:$41C] := MemW[0:$41A];
  PopupInputReservedFlag := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Loads SAMn.APO, fades in the palette and waits for a key or a timer timeout. }
procedure ShowApogeeSplash;
var
  unused1, unused2, GraphicsCallResult, unused4: Word;
begin
  FadeGamePaletteToBlack(0);
  GraphicsCallResult := PcxSetDisplayType(2);
  GraphicsCallResult := PcxSetGraphicsOrTextMode(1);
  GraphicsCallResult := PgSetScreenStride($28);
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
  RestoreGamePalette($14);
  StartSoundEffect($15);
  MemW[0:$041C] := MemW[0:$041A];
  GameTickCounter := 0;
  repeat
  until KeyPressed or (GameTickCounter > $02D0);
  GameTickCounter := 0;
  FadeGamePaletteToBlack(0);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Loads SAMn.CRD and SAMn.TTL, vertically pans between them, and handles the main-menu result. }
procedure ShowTitleAndCredits;
var
  PanDirection, PanDistance, ShowTitleAnd_GraphicsCallResult: Integer;
  MenuAction: Char;
begin
  FadeGamePaletteToBlack(0);
  ShowTitleAnd_GraphicsCallResult := PcxSetDisplayType(2);
  ShowTitleAnd_GraphicsCallResult := PcxSetGraphicsOrTextMode(1);
  ShowTitleAnd_GraphicsCallResult := PgSetScreenStride($28);
  CameraX := 0;
  CameraY := 0;
  DisplayedBufferRow := 0;
  GameDrawBufferRow := 0;
{$IFDEF SAM2}
  ShowTitleAnd_GraphicsCallResult := PcxDisplayFile('sam2.crd', 1, 0, 0);
{$ELSE}
{$IFDEF SAM3}
  ShowTitleAnd_GraphicsCallResult := PcxDisplayFile('sam3.crd', 1, 0, 0);
{$ELSE}
  ShowTitleAnd_GraphicsCallResult := PcxDisplayFile('sam1.crd', 1, 0, 0);
{$ENDIF}
{$ENDIF}
  PgCopyVideoScreenRegion320x200(0, 0, 0, $C8);
{$IFDEF SAM2}
  ShowTitleAnd_GraphicsCallResult := PcxDisplayFile('sam2.ttl', 1, 0, 0);
{$ELSE}
{$IFDEF SAM3}
  ShowTitleAnd_GraphicsCallResult := PcxDisplayFile('sam3.ttl', 1, 0, 0);
{$ELSE}
  ShowTitleAnd_GraphicsCallResult := PcxDisplayFile('sam1.ttl', 1, 0, 0);
{$ENDIF}
{$ENDIF}
  RestoreGamePalette($14);
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
  until (GameTickCounter > $90) or (MenuAction <> ' ');
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
      PgPanDisplayAtRetraceStart(0, $C8 - PanDistance)
    else
      PgPanDisplayAtRetraceEnd(0, $C8 - PanDistance);
    DisplayedBufferRow := $C8 - PanDistance;
  end;
  Inc(PanDistance);
  if PanDistance > $C8 then
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
    until (GameTickCounter > $1B0) or (MenuAction <> ' ');
  end;
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  EscapePressed := 0;
  MemW[0:$041C] := MemW[0:$041A];
  if LastKeyboardScanCode <> 0 then
  begin
    MenuAction := RunMainMenu;
    GameTickCounter := 0;
    LastKeyboardScanCode := 0;
  end;
  until (MenuAction = 'B') or (MenuAction = 'R') or (MenuAction = 'Q');
  StartSoundEffect($0C);
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
  if PlayerScore > GameConfiguration.ConfigRankedScores[10] then
  begin
    AskHighScoreName;
    for RankIndex := 10 downto 1 do
      if GameConfiguration.ConfigRankedScores[RankIndex] < PlayerScore then
        InsertRank := RankIndex;
    if InsertRank < 10 then
      for RankIndex := 10 downto InsertRank + 1 do
      begin
        GameConfiguration.ConfigRankedScores[RankIndex] := GameConfiguration.ConfigRankedScores[RankIndex - 1];
        GameConfiguration.ConfigScoreLines[RankIndex] := GameConfiguration.ConfigScoreLines[RankIndex - 1];
      end;
    for RankIndex := Ord(PopupInputResult[0]) to 22 do
      PopupInputResult := PopupInputResult + ' ';
    Str(PlayerScore:7, FormattedScore);
    PopupInputResult := PopupInputResult + FormattedScore;
    GameConfiguration.ConfigRankedScores[InsertRank] := PlayerScore;
    GameConfiguration.ConfigScoreLines[InsertRank] := PopupInputResult;
    ShowHighScores;
  end;
end;
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
  Reset(SpriteBankFileViews.SpriteUntypedFile, $1F80);
  GetMem(SpriteBank851, $1F80);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank851^);
  DecryptGameAssetBuffer(SpriteBank851^, $1F80);
  GetMem(SpriteBank001, $1F80);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank001^);
  DecryptGameAssetBuffer(SpriteBank001^, $1F80);
  GetMem(SpriteBank101, $1F80);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank101^);
  DecryptGameAssetBuffer(SpriteBank101^, $1F80);
  GetMem(SpriteBank401, $1F80);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank401^);
  DecryptGameAssetBuffer(SpriteBank401^, $1F80);
  GetMem(SpriteBank451, $1F80);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank451^);
  DecryptGameAssetBuffer(SpriteBank451^, $1F80);
  GetMem(SpriteBank601, $1F80);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank601^);
  DecryptGameAssetBuffer(SpriteBank601^, $1F80);
  GetMem(SpriteBank651, $1F80);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank651^);
  DecryptGameAssetBuffer(SpriteBank651^, $1F80);
  GetMem(SpriteBank701, $1F80);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank701^);
  DecryptGameAssetBuffer(SpriteBank701^, $1F80);
  GetMem(SpriteBank751, $1F80);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank751^);
  DecryptGameAssetBuffer(SpriteBank751^, $1F80);
  GetMem(SpriteBank301, $1F80);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank301^);
  DecryptGameAssetBuffer(SpriteBank301^, $1F80);
  GetMem(SpriteBank151, $1F80);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank151^);
  DecryptGameAssetBuffer(SpriteBank151^, $1F80);
  GetMem(SpriteBank201, $1F80);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank201^);
  DecryptGameAssetBuffer(SpriteBank201^, $1F80);
  GetMem(SpriteBank801, $1F80);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank801^);
  DecryptGameAssetBuffer(SpriteBank801^, $1F80);
  GetMem(PlayerSpriteBank, $1F80);
  Read(SpriteBankFileViews.SpriteTypedFile, PlayerSpriteBank^);
  DecryptGameAssetBuffer(PlayerSpriteBank^, $1F80);
  GetMem(SpriteBank351, $1F80);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank351^);
  DecryptGameAssetBuffer(SpriteBank351^, $1F80);
  GetMem(SpriteBank251, $1F80);
  Read(SpriteBankFileViews.SpriteTypedFile, SpriteBank251^);
  DecryptGameAssetBuffer(SpriteBank251^, $1F80);
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
  Reset(GlyphBankFileViews.GlyphUntypedFile, $0800);
  GetMem(PopupFrameAndGlyphBank, $0800);
  Read(GlyphBankFileViews.GlyphTypedFile, PopupFrameAndGlyphBank^);
  DecryptGameAssetBuffer(PopupFrameAndGlyphBank^, $0800);
  GetMem(PopupExtendedGlyphBank, $0800);
  Read(GlyphBankFileViews.GlyphTypedFile, PopupExtendedGlyphBank^);
  DecryptGameAssetBuffer(PopupExtendedGlyphBank^, $0800);
  GetMem(StatusGlyphBank, $0800);
  Read(GlyphBankFileViews.GlyphTypedFile, StatusGlyphBank^);
  DecryptGameAssetBuffer(StatusGlyphBank^, $0800);
  Close(GlyphBankFileViews.GlyphUntypedFile);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Immediately writes zero to all sixteen EGA palette registers. }
procedure BlackenGamePalette;
var
  BlackenGamePalette_PaletteIndex: Integer;
begin
  for BlackenGamePalette_PaletteIndex := 0 to 15 do
    PgSetPaletteRegister(BlackenGamePalette_PaletteIndex, 0);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Copies player position, score, ammo, level flags and powerup state into d_6D18. }
procedure CaptureGameSnapshot;
var
  LevelFlagIndex: Integer;
begin
  GameSnapshot.SavedPlayerX := GameActors[1].ActorWorldX;
  GameSnapshot.SavedPlayerY := GameActors[1].ActorWorldY;
  GameSnapshot.SavedPlayerScore := PlayerScore;
  GameSnapshot.SavedProgressCount := PlayerProgressCount;
  GameSnapshot.SavedPlayerAmmo := PlayerAmmo;
  GameSnapshot.SavedProjectileLimit := PlayerProjectileLimit;
  for LevelFlagIndex := 1 to 20 do
    GameSnapshot.SavedBlueprintFlags[LevelFlagIndex] := LevelBlueprintFlags[LevelFlagIndex];
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
  for LevelFlagIndex := 1 to 20 do
    GameSnapshot.SavedCompletedLevelFlags[LevelFlagIndex] := LevelCompletedFlags[LevelFlagIndex];
  GameSnapshot.SavedExtraAmmoCheatUsed := ExtraAmmoCheatUsed;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Copies d_6D18 back to the live player and game state. }
procedure RestoreGameSnapshot;
var
  RestoreGameSnaps_LevelFlagIndex: Integer;
begin
  GameActors[1].ActorWorldX := GameSnapshot.SavedPlayerX;
  GameActors[1].ActorWorldY := GameSnapshot.SavedPlayerY;
  PlayerScore := GameSnapshot.SavedPlayerScore;
  PlayerProgressCount := GameSnapshot.SavedProgressCount;
  PlayerAmmo := GameSnapshot.SavedPlayerAmmo;
  PlayerProjectileLimit := GameSnapshot.SavedProjectileLimit;
  for RestoreGameSnaps_LevelFlagIndex := 1 to 20 do
    LevelBlueprintFlags[RestoreGameSnaps_LevelFlagIndex] := GameSnapshot.SavedBlueprintFlags[RestoreGameSnaps_LevelFlagIndex];
  PlayerSpeedBoost := GameSnapshot.SavedSpeedBoost;
  SpeedBoostTimeLeft := GameSnapshot.SavedSpeedTimeLeft;
  PlayerControlsReversed := GameSnapshot.SavedControlsReversed;
  ConfusionTimeLeft := GameSnapshot.SavedConfusionTimeLeft;
  ConfusionEndedMessagePending := GameSnapshot.SavedConfusionEndedPending;
  PlayerSlowMovement := GameSnapshot.SavedSlowMovement;
  SlowMovementTimeLeft := GameSnapshot.SavedSlowTimeLeft;
  SavedAuxiliaryCounter := GameSnapshot.SavedAuxiliaryValue;
  LevelEntranceAnimationTick := GameSnapshot.SavedEntranceAnimationTick;
  EnteredLevelNumber := GameSnapshot.SavedEnteredLevelNumber;
  for RestoreGameSnaps_LevelFlagIndex := 1 to 20 do
    LevelCompletedFlags[RestoreGameSnaps_LevelFlagIndex] :=
    GameSnapshot.SavedCompletedLevelFlags[RestoreGameSnaps_LevelFlagIndex];
  ExtraAmmoCheatUsed := GameSnapshot.SavedExtraAmmoCheatUsed;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Snaps the player position to tile boundaries and writes the game record to SAMn-<slot>.SAV. }
procedure WriteSavedGame(SaveSlot: Integer);
var
  SaveOutputFile: TSaveGameOutputFile;
  WriteSavedGame_LevelFlagIndex: Word;
  SlotNumberText: string;
begin
  GameSnapshot.SavedPlayerX := LongInt(GameActors[1].ActorWorldX + 8) and $FFF0;
  GameSnapshot.SavedPlayerY := LongInt(GameActors[1].ActorWorldY + 8) and $FFF0;
  GameSnapshot.SavedPlayerScore := PlayerScore;
  GameSnapshot.SavedProgressCount := PlayerProgressCount;
  GameSnapshot.SavedPlayerAmmo := PlayerAmmo;
  GameSnapshot.SavedProjectileLimit := PlayerProjectileLimit;
  for WriteSavedGame_LevelFlagIndex := 1 to 20 do
    GameSnapshot.SavedBlueprintFlags[WriteSavedGame_LevelFlagIndex] := LevelBlueprintFlags[WriteSavedGame_LevelFlagIndex];
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
  for WriteSavedGame_LevelFlagIndex := 1 to 20 do
    GameSnapshot.SavedCompletedLevelFlags[WriteSavedGame_LevelFlagIndex] :=
    LevelCompletedFlags[WriteSavedGame_LevelFlagIndex];
  GameSnapshot.SavedExtraAmmoCheatUsed := ExtraAmmoCheatUsed;

  Str(SaveSlot:1, SlotNumberText);
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
{ Reads SAMn-<slot>.SAV into the live game state; reports File Not Found and returns success. }
function ReadSavedGame(ReadSavedGame_SaveSlot: Integer): Boolean;
var
  SaveInputFile: TSaveGameInputFile;
  ReadSavedGame_LevelFlagIndex: Integer;
  ReadSavedGame_SlotNumberText: string;
  FileOpenSucceeded: Boolean;
begin
  Str(ReadSavedGame_SaveSlot:1, ReadSavedGame_SlotNumberText);
{$I-}
{$IFDEF SAM1}
  Assign(SaveInputFile, 'SAM1-' + ReadSavedGame_SlotNumberText + '.SAV');
{$ENDIF}
{$IFDEF SAM2}
  Assign(SaveInputFile, 'SAM2-' + ReadSavedGame_SlotNumberText + '.SAV');
{$ENDIF}
{$IFDEF SAM3}
  Assign(SaveInputFile, 'SAM3-' + ReadSavedGame_SlotNumberText + '.SAV');
{$ENDIF}
  Reset(SaveInputFile);
  FileOpenSucceeded := IOResult = 0;
  Reset(SaveInputFile);
  FileOpenSucceeded := IOResult = 0;

  if FileOpenSucceeded then
  begin
    Read(SaveInputFile, GameSnapshot);
    Close(SaveInputFile);
    GameActors[1].ActorWorldX := GameSnapshot.SavedPlayerX;
    GameActors[1].ActorWorldY := GameSnapshot.SavedPlayerY;
    PlayerScore := GameSnapshot.SavedPlayerScore;
    PlayerProgressCount := GameSnapshot.SavedProgressCount;
    PlayerAmmo := GameSnapshot.SavedPlayerAmmo;
    PlayerProjectileLimit := GameSnapshot.SavedProjectileLimit;
    for ReadSavedGame_LevelFlagIndex := 1 to 20 do
      LevelBlueprintFlags[ReadSavedGame_LevelFlagIndex] := GameSnapshot.SavedBlueprintFlags[ReadSavedGame_LevelFlagIndex];
    PlayerSpeedBoost := GameSnapshot.SavedSpeedBoost;
    SpeedBoostTimeLeft := GameSnapshot.SavedSpeedTimeLeft;
    PlayerControlsReversed := GameSnapshot.SavedControlsReversed;
    ConfusionTimeLeft := GameSnapshot.SavedConfusionTimeLeft;
    ConfusionEndedMessagePending := GameSnapshot.SavedConfusionEndedPending;
    PlayerSlowMovement := GameSnapshot.SavedSlowMovement;
    SlowMovementTimeLeft := GameSnapshot.SavedSlowTimeLeft;
    SavedAuxiliaryCounter := GameSnapshot.SavedAuxiliaryValue;
    LevelEntranceAnimationTick := GameSnapshot.SavedEntranceAnimationTick;
    EnteredLevelNumber := GameSnapshot.SavedEnteredLevelNumber;
    for ReadSavedGame_LevelFlagIndex := 1 to 20 do
      LevelCompletedFlags[ReadSavedGame_LevelFlagIndex] :=
      GameSnapshot.SavedCompletedLevelFlags[ReadSavedGame_LevelFlagIndex];
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
  PopupAcceptedScanCodes[1] := 1;
  PopupSelectionScanCode := ReadScrollablePopupScanCode(0);
  EscapePressed := 0;
  GameOptionsRequested := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Builds CONFIDENTIAL/BACKGROUND FILE and YOUR MISSION pages describing the blueprints and DVS. }
procedure ShowMissionBriefing;
var
  ShowMissionBriefi_TextLineIndex: Integer;
begin
  ClearPopupText;
  ShowMissionBriefi_TextLineIndex := 1;
{$IFDEF SAM1}
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'CONFIDENTIAL FILE         Pg. 1';
{$ELSE}
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'BACKGROUND FILE           Pg. 1';
{$ENDIF}
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex][0] := #0;
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'To:        Agent 006';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'Priority:  For Your Eyes Only';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex][0] := #0;
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := '**Destroy file after reading**';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex][0] := #0;
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'Our government scientists have';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'been working on a secret';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'project: A ruby-powered laser';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'satellite with the ability to';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'pinpoint and fire upon any';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'target from Earth orbit, code';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'named "Red Rock Rover".';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(ShowMissionBriefi_TextLineIndex);
{$IFNDEF SAM1}
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'MISSION UPDATE            Pg. 2';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionBriefi_TextLineIndex);
{$IFDEF SAM2}
  PopupTextLines[ShowMissionBriefi_TextLineIndex][0] := #0;
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := '006 successfully infiltrated';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'DVS headquarters on the first';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'island, and gained possession of';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'the first of three blueprints.';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex][0] := #0;
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'Using a jet raft, 006 has';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'landed upon the second island';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'fortress, and must find the';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'next blueprint to the "Red Rock';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'Rover" weapon.';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex][0] := #0;
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex][0] := #0;
  Inc(ShowMissionBriefi_TextLineIndex);
{$ELSE}
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := '006 has destroyed the DVS';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'headquarters on the first and';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'second island fortresses, and';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'secured possession of two';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'crucial blueprints.';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex][0] := #0;
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'Using scuba gear, 006 slipped';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'past the security net set up';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'around the final island.';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'Getting the final blueprint';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'will be the most dangerous';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'assignment yet, since this';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'island id the DVS stronghold!';
  Inc(ShowMissionBriefi_TextLineIndex);
{$ENDIF}
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(ShowMissionBriefi_TextLineIndex);
{$ENDIF}
{$IFDEF SAM1}
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'YOUR MISSION              Pg. 2';
{$ELSE}
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'YOUR MISSION              Pg. 3';
{$ENDIF}
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex][0] := #0;
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'Two weeks ago the blueprints';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'were stolen by the Diabolical';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'Villain Society (DVS), which';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'will use them to build the';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'ultimate terrorist threat.';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex][0] := #0;
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'You@ve been chosen by the';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'Bureau to infiltrate DVS';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'headquarters and secure the';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'blueprints.  The headquarters';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'are located on a series of';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'islands in the Pacific basin.';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(ShowMissionBriefi_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'YOUR MISSION              Pg. 3';
{$ELSE}
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'YOUR MISSION              Pg. 4';
{$ENDIF}
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex][0] := #0;
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'Your mission, should you choose';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'to accept it, is to bring back';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'the secret blueprints to the';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := '"Red Rock Rover" project.  You';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'will be isolated from outside';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'help.';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex][0] := #0;
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'You should be warned that this';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'mission is of global importance';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'and must succeed in order to';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'maintain a balance of world';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'power.';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(ShowMissionBriefi_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'YOUR MISSION              Pg. 4';
{$ELSE}
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'YOUR MISSION              Pg. 5';
{$ENDIF}
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex][0] := #0;
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'We do not have a file on the';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'head of DVS, but he is';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'suspected to be very cunning';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'and dangerous.  DVS';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'headquarters are built up';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'as an elaborate series of';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'fortresses on three well';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'guarded islands.';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex][0] := #0;
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'As always, should you be caught';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'the Bureau will disavow any';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'knowledge of your existence.';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(ShowMissionBriefi_TextLineIndex);
  PopupTextLines[ShowMissionBriefi_TextLineIndex] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := 1;
  PopupSelectionScanCode := ReadScrollablePopupScanCode(0);
  EscapePressed := 0;
  GameOptionsRequested := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Builds MISSION SUCCESSFUL and HOW TO ORDER MORE GAMES pages for the current episode. }
procedure ShowMissionSuccessText;
var
  ShowMissionSucces_TextLineIndex: Integer;
begin
  ClearPopupText;
  ShowMissionSucces_TextLineIndex := 1;
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'MISSION SUCCESSFUL        Pg. 1';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'Congratulations 006, you have';
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'successfully destroyed the';
{$ELSE}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'successfully infiltrated DVS';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'first DVS headquarters and';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'headquarters on the island,';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'headquarters on the last island';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'retrieved the first blueprint.';
{$ELSE}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'and gained possession of the';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'second blueprint.  The Bureau';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'final blueprint.';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'The Bureau has hidden a jet';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'has hidden scuba gear on the';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'raft on the island that you can';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'island that you must use to';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'Dr. No Body and the DVS have';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'use to reach the second island';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'reach the third island';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'all been stopped and the world';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'fortress.  Once there, you will';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'fortress.  Once there, you will';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'is once again safe, well for a';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'overcome new dangers and traps';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'overcome new dangers and traps';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'few more days anyway...';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'to secure the second blueprint';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'to secure the final blueprint';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'to the "Red Rock Rover" weapon.';
{$ENDIF}
{$IFDEF SAM2}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'to the "Red Rock Rover" weapon.';
{$ENDIF}
{$IFDEF SAM3}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'HOW TO ORDER MORE GAMES   Pg. 2';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'Be sure to play the next two';
{$ELSE}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'Be sure to play all the';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'exciting missions, otherwise';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'the world will fall prey to the';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'evil intentions of the DVS!';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'The next two missions are:';
{$ELSE}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'Get all the Secret Agent games:';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := ' * Kill Again Island';
{$ELSE}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := ' * The Hunt For Red Rock Rover';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := ' * Dr. No Body';
{$ELSE}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := ' * Kill Again Island';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
{$ELSE}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := ' * Dr. No Body';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'HOW TO ORDER MORE GAMES   Pg. 3';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
  Inc(ShowMissionSucces_TextLineIndex);
{$IFDEF SAM1}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'In these two missions you will';
{$ELSE}
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'In the other missions you will';
{$ENDIF}
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'encounter all-new challenges,';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'hazards, henchmen, levels,';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'puzzles, prizes, and basically';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'put to test all of your secret';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'agent skills!';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'To order, call 1-800-GAME-123';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'between the hours of 8am - 7pm';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'Central Standard Time (CST).';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'Price: $34 (incl. $4 Shipping)';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'HOW TO ORDER MORE GAMES   Pg. 4';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'This price ($34) includes all';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'three Secret Agent missions,';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'which also sell for $15 apiece.';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'You may also order by mail:';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '     Apogee Software';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '     P.O. Box 476389';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '     Garland, TX  75047';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'All orders include: hint sheet,';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'cheat password, and bonus game.';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := '-------------------------------';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'Press PgUp-PgDn        Esc-Exit';
  Inc(ShowMissionSucces_TextLineIndex);
  PopupTextLines[ShowMissionSucces_TextLineIndex] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := 1;
  PopupSelectionScanCode := ReadScrollablePopupScanCode(0);
  EscapePressed := 0;
  GameOptionsRequested := 0;
end;
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
  PopupInputResult := ReadPopupText(20);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Prompts for left/right/up/down/jump/fire, rejects unavailable or duplicate keys and confirms the choices. }
procedure RedefineKeyboardBindings;
var
  NewRightScanCode, NewLeftScanCode, NewUpScanCode, NewDownScanCode, NewFireScanCode, NewJumpScanCode, SpareWord: Word;
  KeyIsValid, RedefineNotCancelled: Boolean;
  { Nested in u3_892b; shows the six chosen key names, confirms Y/N and assigns the scan-code bindings. }
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
    PopupAcceptedScanCodes[1] := $15;
    PopupAcceptedScanCodes[2] := $31;
    PopupSelectionScanCode := ReadPopupScanCode(0);
    if PopupSelectionScanCode = $31 then
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

  { Nested in u3_892b; displays Sorry, that key is unavailable and waits for any scan code. }
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
    if NewLeftScanCode = 1 then
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
      PopupAcceptedScanCodes[1] := 1;
      NewRightScanCode := ReadPopupScanCode(1);
      if NewRightScanCode = 1 then
        RedefineNotCancelled := False;
      RightKeyDisplayText := ScanCodeDisplayName(NewRightScanCode);
      if RedefineNotCancelled and
         ((RightKeyDisplayText = 'NULL') or (RightKeyDisplayText = LeftKeyDisplayText)) then
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
      PopupAcceptedScanCodes[1] := 1;
      NewUpScanCode := ReadPopupScanCode(1);
      if NewUpScanCode = 1 then
        RedefineNotCancelled := False;
      UpKeyDisplayText := ScanCodeDisplayName(NewUpScanCode);
      if RedefineNotCancelled and
         ((UpKeyDisplayText = 'NULL') or (UpKeyDisplayText = LeftKeyDisplayText) or
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
      PopupAcceptedScanCodes[1] := 1;
      NewDownScanCode := ReadPopupScanCode(1);
      if NewDownScanCode = 1 then
        RedefineNotCancelled := False;
      DownKeyDisplayText := ScanCodeDisplayName(NewDownScanCode);
      if RedefineNotCancelled and
         ((DownKeyDisplayText = 'NULL') or (DownKeyDisplayText = LeftKeyDisplayText) or
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
      PopupAcceptedScanCodes[1] := 1;
      NewJumpScanCode := ReadPopupScanCode(1);
      if NewJumpScanCode = 1 then
        RedefineNotCancelled := False;
      JumpKeyDisplayText := ScanCodeDisplayName(NewJumpScanCode);
      if RedefineNotCancelled and
         ((JumpKeyDisplayText = 'NULL') or (JumpKeyDisplayText = LeftKeyDisplayText) or
          (JumpKeyDisplayText = RightKeyDisplayText) or (JumpKeyDisplayText = UpKeyDisplayText) or
          (JumpKeyDisplayText = DownKeyDisplayText)) then
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
      if NewFireScanCode = 1 then
        RedefineNotCancelled := False;
      FireKeyDisplayText := ScanCodeDisplayName(NewFireScanCode);
      if RedefineNotCancelled and
         ((FireKeyDisplayText = 'NULL') or (FireKeyDisplayText = LeftKeyDisplayText) or
          (FireKeyDisplayText = RightKeyDisplayText) or (JumpKeyDisplayText = UpKeyDisplayText) or
          (JumpKeyDisplayText = DownKeyDisplayText) or (FireKeyDisplayText = JumpKeyDisplayText)) then
      begin
        ShowUnavailableKey;
        KeyIsValid := False;
      end;
    until KeyIsValid;
  end;

  if RedefineNotCancelled then
    ConfirmKeyboardBindings;

  MemW[$0000:$041C] := MemW[$0000:$041A];
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
  MemW[$0000:$041C] := MemW[$0000:$041A];
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
  PopupAcceptedScanCodes[1] := 2;
  PopupAcceptedScanCodes[2] := 3;
  PopupAcceptedScanCodes[3] := 4;
  PopupAcceptedScanCodes[4] := 5;
  PopupAcceptedScanCodes[5] := 6;
  PopupAcceptedScanCodes[6] := 7;
  PopupAcceptedScanCodes[7] := 8;
  PopupAcceptedScanCodes[8] := 9;
  PopupAcceptedScanCodes[9] := 10;
  PopupAcceptedScanCodes[10] := 11;
  PopupAcceptedScanCodes[11] := $1C;
  PopupAcceptedScanCodes[12] := 1;
  MemW[0:$041C] := MemW[0:$041A];
  PopupSelectionScanCode := ReadPopupScanCode(0);
  if IOResult = 0 then ;
  case PopupSelectionScanCode of
    2..10: WriteSavedGame(PopupSelectionScanCode - 1);
    11: WriteSavedGame(0);
  end;
  EscapePressed := 0;
  GameOptionsRequested := 0;
  ClearPopupText;
  if IOResult = 0 then
    PopupTextLines[1] := 'Game Saved!'
  else
    PopupTextLines[1] := 'File Error!';
  PopupTextLines[2] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := $1C;
  PopupAcceptedScanCodes[2] := 1;
  MemW[0:$041C] := MemW[0:$041A];
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
  PopupAcceptedScanCodes[1] := 2;
  PopupAcceptedScanCodes[2] := 3;
  PopupAcceptedScanCodes[3] := 4;
  PopupAcceptedScanCodes[4] := 5;
  PopupAcceptedScanCodes[5] := 6;
  PopupAcceptedScanCodes[6] := 7;
  PopupAcceptedScanCodes[7] := 8;
  PopupAcceptedScanCodes[8] := 9;
  PopupAcceptedScanCodes[9] := 10;
  PopupAcceptedScanCodes[10] := 11;
  PopupAcceptedScanCodes[11] := $1C;
  PopupAcceptedScanCodes[12] := 1;
  MemW[0:$041C] := MemW[0:$041A];
  PopupSelectionScanCode := ReadPopupScanCode(0);
  case PopupSelectionScanCode of
    2..10:
      if Ord(ReadSavedGame(PopupSelectionScanCode - 1)) = 0 then
        PopupSelectionScanCode := $1C;
    11:
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
  RunMainMenu_TextLineIndex: Word;
begin
  RunMainMenu_TextLineIndex := 0;
  ClearPopupText;
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex] := '     MAIN MENU';
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex][0] := #0;
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex] := ' N)ew Game';
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex] := ' R)estore Old Game';
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex] := ' S)tory';
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex] := ' I)nstructions';
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex] := ' H)igh Scores';
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex][0] := #0;
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex] := ' O)rdering Info.';
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex] := ' F)oreign Orders';
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex] := ' C)all Our BBS';
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex] := ' V)ideo Support';
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex] := ' A)bout Apogee';
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex][0] := #0;
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex] := ' Q)uit to DOS';
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex][0] := #0;
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex] := 'Make a selection: ^';
  Inc(RunMainMenu_TextLineIndex); PopupTextLines[RunMainMenu_TextLineIndex] := 'END OF WINDOW';

  PopupAcceptedScanCodes[1] := $31;
  PopupAcceptedScanCodes[2] := $17;
  PopupAcceptedScanCodes[3] := $23;
  PopupAcceptedScanCodes[4] := $13;
  PopupAcceptedScanCodes[5] := $1F;
  PopupAcceptedScanCodes[6] := $18;
  PopupAcceptedScanCodes[7] := $10;
  PopupAcceptedScanCodes[8] := 1;
  PopupAcceptedScanCodes[9] := $39;
  PopupAcceptedScanCodes[10] := $1C;
  PopupAcceptedScanCodes[11] := $21;
  PopupAcceptedScanCodes[12] := $1E;
  PopupAcceptedScanCodes[13] := $2E;
  PopupAcceptedScanCodes[14] := $2F;

  PopupSelectionScanCode := ReadPopupScanCode(0);
  case PopupSelectionScanCode of
    $31, $39, $1C:
      begin
        RunMainMenu := 'B';
        ReturnToTitleRequested := 0;
        PlayerProgressCount := 1;
      end;
    $17:
      begin
        ShowGameInstructions;
        RunMainMenu := 'I';
      end;
    $21:
      begin
        ShowForeignDealers;
        RunMainMenu := 'F';
      end;
    $2E:
      begin
        ShowApogeeBbsInformation;
        RunMainMenu := 'A';
      end;
    $23:
      begin
        RunMainMenu := 'H';
        ShowHighScores;
      end;
    $1E:
      begin
        RunMainMenu := 'A';
        ShowAboutApogee;
      end;
    $2F:
      begin
        RunMainMenu := 'V';
        SelectVideoCompatibility;
      end;
    $13:
      begin
        RunMainMenu := 'R';
        PlayerProgressCount := 1;
        PendingRestoreScanCode := ShowRestoreGameMenu;
        if PendingRestoreScanCode = $1C then
        begin
          PendingRestoreScanCode := 0;
          RunMainMenu := ' ';
        end
        else
          ReturnToTitleRequested := 0;
      end;
    $1F:
      begin
        RunMainMenu := 'S';
        ShowMissionBriefing;
      end;
    $18:
      begin
        RunMainMenu := 'O';
        ShowOrderingInformation;
      end;
    $10:
      begin
        ConfirmQuitToDos;
        if QuitGameRequested <> 0 then
          RunMainMenu := 'Q'
        else
          RunMainMenu := ' ';
      end;
    1:
      begin
        EscapePressed := 0;
        RunMainMenu := ' ';
      end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Dispatches Operational Command Bank selections for help, sound/video/input settings, save/restore and quit. }
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
  PopupAcceptedScanCodes[1] := $23;
  PopupAcceptedScanCodes[2] := $14;
  PopupAcceptedScanCodes[3] := $2F;
  PopupAcceptedScanCodes[4] := $24;
  PopupAcceptedScanCodes[5] := $2E;
  PopupAcceptedScanCodes[6] := $25;
  PopupAcceptedScanCodes[7] := $13;
  PopupAcceptedScanCodes[8] := $1F;
  PopupAcceptedScanCodes[9] := $10;
  PopupAcceptedScanCodes[10] := 1;

  PopupSelectionScanCode := ReadPopupScanCode(0);
  case PopupSelectionScanCode of
    $23:
      begin
        RunGameOptionsMenu := 'H';
        ShowGameInstructions;
      end;
    $14:
      begin
        RunGameOptionsMenu := 'T';
        SelectSoundSetting;
      end;
    $2F:
      begin
        RunGameOptionsMenu := 'V';
        SelectVideoCompatibility;
      end;
    $24:
      begin
        RunGameOptionsMenu := 'J';
        SelectJoystickSetting;
      end;
    $2E:
      begin
        RunGameOptionsMenu := 'C';
        CalibrateJoystickCenter;
      end;
    $25:
      begin
        RunGameOptionsMenu := 'K';
        RedefineKeyboardBindings;
      end;
    $13:
      begin
        RunGameOptionsMenu := 'R';
        RestoreSelectionScanCode := ShowRestoreGameMenu;
        if RestoreSelectionScanCode <> $1C then
          RestoreSnapshotRequested := 1;
      end;
    $1F:
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
          PopupAcceptedScanCodes[1] := 1;
          PopupSelectionScanCode := ReadPopupScanCode(0);
          EscapePressed := 0;
          GameOptionsRequested := 0;
        end;
      end;
    $10:
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
  for HighScoreIndex := 1 to 10 do
    PopupTextLines[HighScoreIndex + 3] := GameConfiguration.ConfigScoreLines[HighScoreIndex];
  PopupTextLines[14][0] := #0;
  PopupTextLines[15] := 'Press any key ^';
  PopupTextLines[16][0] := #0;
  PopupTextLines[17] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := 1;
  PopupSelectionScanCode := ReadPopupScanCode(1);
  EscapePressed := 0;
  GameOptionsRequested := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Displays the supplied message and Press ESCAPE using a popup with an Escape accepted scan code. }
procedure ShowGameMessage(MessageText: string);
begin
  ClearPopupText;
  PopupTextLines[1] := TPopupStringViews(MessageText).PopupLineString;
  PopupTextLines[2][0] := #0;
  PopupTextLines[3] := 'Press ESCAPE';
  PopupTextLines[4] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := 1;
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
  PopupAcceptedScanCodes[1] := 1;
  PopupAcceptedScanCodes[2] := $15;
  PopupAcceptedScanCodes[3] := $31;
  PopupSelectionScanCode := ReadPopupScanCode(1);
  if PopupSelectionScanCode = $15 then
    QuitGameRequested := 1;
  EscapePressed := 0;
  GameOptionsRequested := 0;
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  MemW[0:$41C] := MemW[0:$41A];
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
  PopupAcceptedScanCodes[1] := $20;
  PopupAcceptedScanCodes[2] := $14;
  PopupAcceptedScanCodes[3] := $17;
  PopupAcceptedScanCodes[4] := 1;
  PopupSelectionScanCode := ReadPopupScanCode(1);
  if PopupSelectionScanCode = $20 then
  begin
    InsertPlayerHighScore;
    QuitGameRequested := 1;
    EpisodeBlueprintCollected := 0;
    StartSoundEffect($12);
  end
  else if PopupSelectionScanCode = $14 then
  begin
    InsertPlayerHighScore;
    ReturnToTitleRequested := 1;
    EpisodeBlueprintCollected := 0;
    StartSoundEffect($12);
  end
  else if PopupSelectionScanCode = $17 then
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
  MemW[$0000:$041C] := MemW[$0000:$041A];
  LastKeyboardScanCode := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Prompts Sounds On (Y-N) and assigns d_34AF, which gates PC-speaker sound in the timer ISR. }
procedure SelectSoundSetting;
begin
  ClearPopupText;
  PopupTextLines[1] := 'Sounds On (Y-N) ^';
  PopupTextLines[2] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := $15;
  PopupAcceptedScanCodes[2] := $31;
  PopupAcceptedScanCodes[3] := 1;
  PopupSelectionScanCode := ReadPopupScanCode(1);
  if PopupSelectionScanCode = $15 then
    SoundEnabled := 1
  else
    SoundEnabled := 0;
  EscapePressed := 0;
  GameOptionsRequested := 0;
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  MemW[$0000:$041C] := MemW[$0000:$041A];
  LastKeyboardScanCode := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Prompts Alternate video setting (Y-N); d_70C6 selects the alternate retrace-pan routine. }
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
  PopupAcceptedScanCodes[1] := $15;
  PopupAcceptedScanCodes[2] := $31;
  PopupAcceptedScanCodes[3] := 1;
  PopupSelectionScanCode := ReadPopupScanCode(0);
  if PopupSelectionScanCode = $15 then
    AlternateVideoTiming := 1
  else
    AlternateVideoTiming := 0;
  EscapePressed := 0;
  GameOptionsRequested := 0;
  PlayerUpHeld := 0;
  PlayerDownHeld := 0;
  PlayerLeftHeld := 0;
  PlayerRightHeld := 0;
  MemW[0:$041C] := MemW[0:$041A];
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
  PopupAcceptedScanCodes[1] := $15;
  PopupAcceptedScanCodes[2] := $31;
  PopupAcceptedScanCodes[3] := 1;
  PopupSelectionScanCode := ReadPopupScanCode(1);
  if PopupSelectionScanCode = $15 then
  begin
    JoystickActive := IsJoystickPresent;
    JoystickSettingEnabled := 1;
  end
  else if PopupSelectionScanCode = $31 then
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
  MemW[0:$041C] := MemW[0:$041A];
  LastKeyboardScanCode := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Prompts for a centered joystick, then measures axes 0 and 1 into d_6D68/d_6D6A. }
procedure CalibrateJoystickCenter;
var
  CalibrateJoystick_TextLineIndex: Word;
begin
  ClearPopupText;
  CalibrateJoystick_TextLineIndex := 0;
  Inc(CalibrateJoystick_TextLineIndex);
  PopupTextLines[CalibrateJoystick_TextLineIndex] := '  Set your joystick so that';
  Inc(CalibrateJoystick_TextLineIndex);
  PopupTextLines[CalibrateJoystick_TextLineIndex] := 'it is in the middle position.';
  Inc(CalibrateJoystick_TextLineIndex);
  PopupTextLines[CalibrateJoystick_TextLineIndex] := ' ';
  Inc(CalibrateJoystick_TextLineIndex);
  PopupTextLines[CalibrateJoystick_TextLineIndex] := '   Press SPACE when this is';
  Inc(CalibrateJoystick_TextLineIndex);
  PopupTextLines[CalibrateJoystick_TextLineIndex] := ' done, and the joystick will';
  Inc(CalibrateJoystick_TextLineIndex);
  PopupTextLines[CalibrateJoystick_TextLineIndex] := '       be calibrated.';
  Inc(CalibrateJoystick_TextLineIndex);
  PopupTextLines[CalibrateJoystick_TextLineIndex] := ' ';
  Inc(CalibrateJoystick_TextLineIndex);
  PopupTextLines[CalibrateJoystick_TextLineIndex] := 'This step is not necessary if';
  Inc(CalibrateJoystick_TextLineIndex);
  PopupTextLines[CalibrateJoystick_TextLineIndex] := ' your joystick is set in the';
  Inc(CalibrateJoystick_TextLineIndex);
  PopupTextLines[CalibrateJoystick_TextLineIndex] := ' middle when the game loads.';
  Inc(CalibrateJoystick_TextLineIndex);
  PopupTextLines[CalibrateJoystick_TextLineIndex] := ' ';
  Inc(CalibrateJoystick_TextLineIndex);
  PopupTextLines[CalibrateJoystick_TextLineIndex] := 'Press Escape if your joystick';
  Inc(CalibrateJoystick_TextLineIndex);
  PopupTextLines[CalibrateJoystick_TextLineIndex] := '         is not on.';
  Inc(CalibrateJoystick_TextLineIndex);
  PopupTextLines[CalibrateJoystick_TextLineIndex] := '              ^';
  Inc(CalibrateJoystick_TextLineIndex);
  PopupTextLines[CalibrateJoystick_TextLineIndex] := 'END OF WINDOW';

  PopupAcceptedScanCodes[1] := 1;
  PopupAcceptedScanCodes[2] := $39;
  PopupSelectionScanCode := ReadPopupScanCode(0);
  if PopupSelectionScanCode = $39 then
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
  MemW[0:$041C] := MemW[0:$041A];
  LastKeyboardScanCode := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Maps keyboard scan codes to printable key names (CTRL, ALT, arrows etc.) or NULL. }
function ScanCodeDisplayName(ScanCode: Word): string;
begin
  case ScanCode of
    2: ScanCodeDisplayName := '1';
    3: ScanCodeDisplayName := '2';
    4: ScanCodeDisplayName := '3';
    5: ScanCodeDisplayName := '4';
    6: ScanCodeDisplayName := '5';
    7: ScanCodeDisplayName := '6';
    8: ScanCodeDisplayName := '7';
    9: ScanCodeDisplayName := '8';
    10: ScanCodeDisplayName := '9';
    11: ScanCodeDisplayName := '0';
    16: ScanCodeDisplayName := 'Q';
    17: ScanCodeDisplayName := 'W';
    18: ScanCodeDisplayName := 'E';
    19: ScanCodeDisplayName := 'R';
    20: ScanCodeDisplayName := 'T';
    21: ScanCodeDisplayName := 'Y';
    22: ScanCodeDisplayName := 'U';
    23: ScanCodeDisplayName := 'I';
    24: ScanCodeDisplayName := 'O';
    25: ScanCodeDisplayName := 'P';
    28: ScanCodeDisplayName := 'ENTER';
    29: ScanCodeDisplayName := 'CTRL';
    30: ScanCodeDisplayName := 'A';
    31: ScanCodeDisplayName := 'S';
    32: ScanCodeDisplayName := 'D';
    33: ScanCodeDisplayName := 'F';
    34: ScanCodeDisplayName := 'G';
    35: ScanCodeDisplayName := 'H';
    36: ScanCodeDisplayName := 'J';
    37: ScanCodeDisplayName := 'K';
    38: ScanCodeDisplayName := 'L';
    42: ScanCodeDisplayName := 'L-SHIFT';
    44: ScanCodeDisplayName := 'Z';
    45: ScanCodeDisplayName := 'X';
    46: ScanCodeDisplayName := 'C';
    47: ScanCodeDisplayName := 'V';
    48: ScanCodeDisplayName := 'B';
    49: ScanCodeDisplayName := 'N';
    50: ScanCodeDisplayName := 'M';
    51: ScanCodeDisplayName := ',';
    52: ScanCodeDisplayName := '.';
    53: ScanCodeDisplayName := '/';
    54: ScanCodeDisplayName := 'R-SHIFT';
    56: ScanCodeDisplayName := 'ALT';
    57: ScanCodeDisplayName := 'SPACE';
    71: ScanCodeDisplayName := 'HOME';
    72: ScanCodeDisplayName := 'UP ARROW';
    73: ScanCodeDisplayName := 'PGUP';
    75: ScanCodeDisplayName := 'LEFT ARROW';
    77: ScanCodeDisplayName := 'RIGHT ARROW';
    79: ScanCodeDisplayName := 'END';
    80: ScanCodeDisplayName := 'DOWN ARROW';
    81: ScanCodeDisplayName := 'PGDN';
    82: ScanCodeDisplayName := 'INSERT';
    83: ScanCodeDisplayName := 'DELETE';
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
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Shows mail/phone ordering instructions and the ORDER.FRM fax ordering page. }
procedure ShowOrderContactDetails;
var
  ShowOrderContactD_TextLineIndex: Word;
  ShowOrderContac_DismissScanCode: Word;
begin
  ClearPopupText;
  ShowOrderContactD_TextLineIndex := 0;
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] :=
  'ORDERING THE SECRET AGENT SERIES!';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex][0] := #0;
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := '    Please specify disk size:';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := '         5.25"  or  3.5"';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex][0] := #0;
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := '   To order send $34, check or';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := '   money order (USA funds) to:';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex][0] := #0;
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := '         Apogee Software';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := '         P.O. Box 476386';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := '     Garland, TX 75047  (USA)';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex][0] := #0;
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := '     Or CALL NOW toll free:';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := '         1-800-GAME123';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := '     (Visa and MasterCard)';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex][0] := #0;
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := '    Continued...Press Any Key';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := 'END OF WINDOW';
  MemW[0:$41C] := MemW[0:$41A];
  ShowOrderContac_DismissScanCode := ReadPopupScanCode(1);
  EscapePressed := 1;
  PopupNoOpHook;
  ClearPopupText;
  ShowOrderContactD_TextLineIndex := 0;
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := ' USE YOUR FAX MACHINE TO ORDER!';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex][0] := #0;
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := 'You can now use your FAX machine';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := ' to order your favorite Apogee';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := '   games quickly and easily.';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex][0] := #0;
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := ' Simply print out the ORDER.FRM';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := '  file, fill it out and FAX it';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := '  to us for prompt processing.';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex][0] := #0;
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := '   FAX Orders: (214) 278-4670';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex][0] := #0;
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := '          Press Any Key';
  Inc(ShowOrderContactD_TextLineIndex); PopupTextLines[ShowOrderContactD_TextLineIndex] := 'END OF WINDOW';
  MemW[0:$41C] := MemW[0:$41A];
  ShowOrderContac_DismissScanCode := ReadPopupScanCode(1);
  EscapePressed := 1;
  PopupNoOpHook;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Lists all three missions, hint sheet, cheat password and bonus game included with an order. }
procedure ShowOrderPackageDetails;
var
  ShowOrderPackageD_TextLineIndex: Word;
  ShowOrderPackag_DismissScanCode: Word;
begin
  ClearPopupText;
  ShowOrderPackageD_TextLineIndex := 0;
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex] := 'ORDERING THE SECRET AGENT SERIES!';
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex][0] := #0;
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex] := '     Order now and receive:';
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex][0] := #0;
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex] := '  * All three devious missions';
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex] := '  * The hints and tricks sheet';
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex] := '  * The secret cheat password';
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex] := '  * Exciting new bonus game';
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex][0] := #0;
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex] := '    To order, call toll free:';
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex] := '         1-800-426-3123';
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex] := '  (Visa and MasterCard Welcome)';
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex][0] := #0;
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex] := 'Foreign orders:  Please read the';
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex] := '  "Foreign Orders" menu option.';
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex][0] := #0;
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex] := '    Continued...Press Any Key';
  Inc(ShowOrderPackageD_TextLineIndex);
  PopupTextLines[ShowOrderPackageD_TextLineIndex] := 'END OF WINDOW';
  MemW[0:$041C] := MemW[0:$041A];
  ShowOrderPackag_DismissScanCode := ReadPopupScanCode(1);
  EscapePressed := 1;
  PopupNoOpHook;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Introduces the three-episode series and prices, then calls the package and contact detail pages. }
procedure ShowOrderingInformation;
var
  ShowOrderingInfor_TextLineIndex: Word;
  ShowOrderingInf_DismissScanCode: Word;
begin
  ClearPopupText;
  ShowOrderingInfor_TextLineIndex := 0;
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex] :=
  'ORDERING THE SECRET AGENT SERIES!';
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex][0] := #0;
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex] := ' Secret Agent consists of three';
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex] :=
  'original and incredible missions:';
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex][0] := #0;
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex] := '  1) The Hunt for Red Rock Rover';
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex] := '  2) Kill Again Island';
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex] := '  3) Dr. No Body';
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex][0] := #0;
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex] := ' You may order the entire series';
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex] := ' for only $30, plus $4 shipping.';
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex][0] := #0;
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex] := ' Each episode is set on a unique';
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex] :=
  'island, with all-new dangers, new';
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex] := ' levels, and all-new challenges.';
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex][0] := #0;
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex] := '    Continued...Press Any Key';
  Inc(ShowOrderingInfor_TextLineIndex); PopupTextLines[ShowOrderingInfor_TextLineIndex] := 'END OF WINDOW';
  MemW[0:$41C] := MemW[0:$41A];
  ShowOrderingInf_DismissScanCode := ReadPopupScanCode(1);
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
  ShowForeignDealer_TextLineIndex: Word;
  ShowForeignDeal_DismissScanCode: Word;
begin
  ClearPopupText;
  ShowForeignDealer_TextLineIndex := 0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := '       FOREIGN CUSTOMERS';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := '       -----------------';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'The following screens list our';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := '  dealers outside the United';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'States, for Australia, Germany,';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Canada and the United Kingdom.';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := '  These are official Apogee';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := '   dealers with the latest';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := '      games and updates.';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'If your country is not listed,';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := ' you may order directly from';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Apogee by phone or USA check.';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := '        Press Any Key ^';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'END OF WINDOW';
  LastKeyboardScanCode := 999;
  MemW[0:$041C] := MemW[0:$041A];
  ShowForeignDeal_DismissScanCode := ReadPopupScanCode(1);
  PopupNoOpHook;

  ClearPopupText;
  ShowForeignDealer_TextLineIndex := 0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := '      AUSTRALIAN CUSTOMERS';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'PRICE: $45 + $5 shipping.';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'BudgetWare';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'P.O. Box 496';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Newtown, NSW  2042';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Phone:      (02) 519-4233';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Toll free:  (008) 022-064';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Fax:        (02) 516-4236';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'CompuServe: 71520,1475';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Use MasterCard, Visa, Bankcard,';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'cheques.';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'END OF WINDOW';
  LastKeyboardScanCode := 999;
  MemW[0:$041C] := MemW[0:$041A];
  ShowForeignDeal_DismissScanCode := ReadPopupScanCode(1);
  PopupNoOpHook;

  ClearPopupText;
  ShowForeignDealer_TextLineIndex := 0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := '      AUSTRALIAN CUSTOMERS';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'PRICE: $45 + $5 shipping.';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Manaccom';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := '9 Camford Str.';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Milton, Qld. 4064';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Phone: (07) 368-2366';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Fax:   (07) 369-7589';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Use MasterCard, Visa, Bankcard,';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'American Express, or cheques.';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'END OF WINDOW';
  LastKeyboardScanCode := 999;
  MemW[0:$041C] := MemW[0:$041A];
  ShowForeignDeal_DismissScanCode := ReadPopupScanCode(1);
  PopupNoOpHook;

  ClearPopupText;
  ShowForeignDealer_TextLineIndex := 0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := '    CANADIAN CUSTOMERS';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'PRICE: $42 Canadian.';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Distant Markets';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Box 1149';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := '194 - 3803 Calgary Trail S.';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Edmondton, Alb.  T6J 5M8';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'CANADA';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Orders:    1-800-661-7383';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Inquiries: (403) 436-3009';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Fax:       (403) 435-0928';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Use MasterCard, Visa or';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'money orders.';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'END OF WINDOW';
  LastKeyboardScanCode := 999;
  MemW[0:$041C] := MemW[0:$041A];
  ShowForeignDeal_DismissScanCode := ReadPopupScanCode(1);
  PopupNoOpHook;

  ClearPopupText;
  ShowForeignDealer_TextLineIndex := 0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := '        GERMAN CUSTOMERS';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Price: 49,-- DM plus 10,-- DM';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Total: 59,-- DM (Deutsche Mark)';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'CDV-Software';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Ettlingerstr. 5';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := '7500 Karlsruhe 1  GERMANY';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Phone: 0721-22295';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Fax:   0721-21314';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Compuserve: 1000022,274';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Use Visa, MasterCard, EuroCard,';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'American Express, cheque, money';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'order, or C.O.D.';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'END OF WINDOW';
  LastKeyboardScanCode := 999;
  MemW[0:$041C] := MemW[0:$041A];
  ShowForeignDeal_DismissScanCode := ReadPopupScanCode(1);
  PopupNoOpHook;

  ClearPopupText;
  ShowForeignDealer_TextLineIndex := 0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := '    UNITED KINGDOM CUSTOMERS';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Price: /29 + VAT + /2 P&P';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Precision Software Applications';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Unit 3, Valley Court Offices';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Lower Rd';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Croydon, Near Royston';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Harts. SG8 0HF, United Kingdom';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Phone: +44 (0) 223 208 288';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'FAX:   +44 (0) 223 208 089';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex][0] := #0;
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Credit cards, Access, cheques,';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'postal & Bankers orders.';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'Make cheques payable to PSA.';
  Inc(ShowForeignDealer_TextLineIndex);
  PopupTextLines[ShowForeignDealer_TextLineIndex] := 'END OF WINDOW';
  LastKeyboardScanCode := 999;
  MemW[0:$041C] := MemW[0:$041A];
  ShowForeignDeal_DismissScanCode := ReadPopupScanCode(1);
  PopupNoOpHook;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Displays THE OFFICIAL APOGEE BBS, Software Creations and modem phone numbers. }
procedure ShowApogeeBbsInformation;
var
  ShowApogeeBbsInfo_TextLineIndex: Word;
  ShowApogeeBbsIn_DismissScanCode: Word;
begin
  ClearPopupText;
  ShowApogeeBbsInfo_TextLineIndex := 0;
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex] := '   THE OFFICIAL APOGEE BBS';
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex] := '   -----------------------';
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex][0] := #0;
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex] := 'The SOFTWARE CREATIONS BBS is';
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex] := ' the home BBS for the latest';
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex] := ' Apogee games.  Check out our';
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex] := 'FREE "Apogee" file section for';
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex] := '  new releases and updates.';
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex][0] := #0;
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex] := '       BBS phone lines:';
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex] := '(508) 365-2359  2400 baud';
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex] := '(508) 365-9825  9600 baud';
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex] := '(508) 365-9668  14.4k dual HST';
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex][0] := #0;
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex] := '  Many node lines available!';
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex][0] := #0;
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex] := '        Press Any Key ^';
  Inc(ShowApogeeBbsInfo_TextLineIndex);
  PopupTextLines[ShowApogeeBbsInfo_TextLineIndex] := 'END OF WINDOW';

  LastKeyboardScanCode := $03E7;
  MemW[$0000:$041C] := MemW[$0000:$041A];
  ShowApogeeBbsIn_DismissScanCode := ReadPopupScanCode(1);
  PopupNoOpHook;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Displays About Apogee Software and the shareware-support message. }
procedure ShowAboutApogee;
var
  ShowAboutApogee_TextLineIndex, ShowAboutApogee_DismissScanCode: Word;
begin
  ClearPopupText;
  ShowAboutApogee_TextLineIndex := 0;
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex] := '     About Apogee Software';
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex][0] := #0;
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex] := 'Our goal is to establish Apogee';
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex] := '  as the leader in commercial';
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex] := ' quality shareware games. With';
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex] := ' enthusiasm and dedication we';
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex] := 'think our goal can be achieved.';
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex][0] := #0;
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex] := 'However,  we need your support.';
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex] := 'Shareware is not free software.';
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex][0] := #0;
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex] := '  We thank you in advance for';
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex] := '   your contribution to the';
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex] := '  growing shareware community.';
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex] := '      Your honesty pays...';
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex][0] := #0;
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex] := '        Press any key ^';
  Inc(ShowAboutApogee_TextLineIndex);
  PopupTextLines[ShowAboutApogee_TextLineIndex] := 'END OF WINDOW';
  LastKeyboardScanCode := $03E7;
  MemW[0:$041C] := MemW[0:$041A];
  ShowAboutApogee_DismissScanCode := ReadPopupScanCode(1);
  PopupNoOpHook;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Announces that the island security system is knocked out and the blueprint level can now be entered. }
procedure ShowFortressUnlockedMessage;
var
  ShowFortressUnloc_TextLineIndex: Word;
  ShowFortressUnl_DismissScanCode: Word;
begin
  ClearPopupText;
  ShowFortressUnloc_TextLineIndex := 0;
  Inc(ShowFortressUnloc_TextLineIndex);
  PopupTextLines[ShowFortressUnloc_TextLineIndex] := 'Good work 006, you@ve knocked';
  Inc(ShowFortressUnloc_TextLineIndex);
  PopupTextLines[ShowFortressUnloc_TextLineIndex] := 'out the island security system';
  Inc(ShowFortressUnloc_TextLineIndex);
  PopupTextLines[ShowFortressUnloc_TextLineIndex] := '  and can now infiltrate the';
  Inc(ShowFortressUnloc_TextLineIndex);
  PopupTextLines[ShowFortressUnloc_TextLineIndex] := '     level containing the';
  Inc(ShowFortressUnloc_TextLineIndex);
  PopupTextLines[ShowFortressUnloc_TextLineIndex] := ' blueprints to the "Red Rock';
  Inc(ShowFortressUnloc_TextLineIndex);
  PopupTextLines[ShowFortressUnloc_TextLineIndex] := '      Rover" satellite.';
  Inc(ShowFortressUnloc_TextLineIndex);
  PopupTextLines[ShowFortressUnloc_TextLineIndex][0] := #0;
  Inc(ShowFortressUnloc_TextLineIndex);
  PopupTextLines[ShowFortressUnloc_TextLineIndex] := 'Press ESCAPE!          ';
  Inc(ShowFortressUnloc_TextLineIndex);
  PopupTextLines[ShowFortressUnloc_TextLineIndex] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := 1;
  PopupAcceptedScanCodes[2] := $1C;
  PopupAcceptedScanCodes[3] := $39;
  LastKeyboardScanCode := $03E7;
  MemW[0:$041C] := MemW[0:$041A];
  ShowFortressUnl_DismissScanCode := ReadPopupScanCode(0);
  EscapePressed := 0;
  GameOptionsRequested := 0;
  PopupNoOpHook;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Displays the 25,000 point BONUS for finishing a level with perfect health. }
procedure ShowPerfectHealthBonus;
var
  ShowPerfectHealth_TextLineIndex, ShowPerfectHeal_DismissScanCode: Word;
begin
  ClearPopupText;
  ShowPerfectHealth_TextLineIndex := 0;
  Inc(ShowPerfectHealth_TextLineIndex);
  PopupTextLines[ShowPerfectHealth_TextLineIndex] := ' 25,000 point BONUS for';
  Inc(ShowPerfectHealth_TextLineIndex);
  PopupTextLines[ShowPerfectHealth_TextLineIndex] := 'finishing the level with';
  Inc(ShowPerfectHealth_TextLineIndex);
  PopupTextLines[ShowPerfectHealth_TextLineIndex] := '    perfect health!';
  Inc(ShowPerfectHealth_TextLineIndex);
  PopupTextLines[ShowPerfectHealth_TextLineIndex][0] := #0;
  Inc(ShowPerfectHealth_TextLineIndex);
  PopupTextLines[ShowPerfectHealth_TextLineIndex] := 'Press ESCAPE!          ';
  Inc(ShowPerfectHealth_TextLineIndex);
  PopupTextLines[ShowPerfectHealth_TextLineIndex] := 'END OF WINDOW';
  PopupAcceptedScanCodes[1] := 1;
  PopupAcceptedScanCodes[2] := $1C;
  PopupAcceptedScanCodes[3] := $39;
  LastKeyboardScanCode := $03E7;
  MemW[$0000:$041C] := MemW[$0000:$041A];
  ShowPerfectHeal_DismissScanCode := ReadPopupScanCode(0);
  EscapePressed := 0;
  GameOptionsRequested := 0;
  PopupNoOpHook;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Switches to text mode and draws the ordering screen (SAM1) or distribution notice (SAM2/3). }
procedure ShowDosExitScreen;
var
  BorderStripeIndex, D_2, D_3, D_4: Word;
begin
  TextMode(3);
  ClrScr;
  GotoXY(1, 1);
  for BorderStripeIndex := 0 to 19 do
  begin
    WriteVerticalText(4 * BorderStripeIndex + 1, 1, 8, 0, t_u3_dbc2_border);
    WriteVerticalText(4 * BorderStripeIndex + 2, 1, 7, 0, t_u3_dbc2_border);
    WriteVerticalText(4 * BorderStripeIndex + 3, 1, 15, 0, t_u3_dbc2_border);
    WriteVerticalText(4 * BorderStripeIndex + 4, 1, 7, 0, t_u3_dbc2_border);
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
  EndingDelayIteration, ShowEpisodeE_GraphicsCallResult: Word;
begin
  PgSetToolboxVideoMode(0);
  ShowEpisodeE_GraphicsCallResult := PcxSetDisplayType(2);
  ShowEpisodeE_GraphicsCallResult := PcxSetGraphicsOrTextMode(1);
  ShowEpisodeE_GraphicsCallResult := PgSetScreenStride($28);
  CameraX := 0;
  CameraY := 0;
  DisplayedBufferRow := 0;
  GameDrawBufferRow := 0;
{$IFDEF SAM1}
  ShowEpisodeE_GraphicsCallResult := PcxDisplayFile('SAM1.END', 1, 0, 0);
{$ELSE}
{$IFDEF SAM2}
  ShowEpisodeE_GraphicsCallResult := PcxDisplayFile('SAM2.END', 1, 0, 0);
{$ELSE}
  ShowEpisodeE_GraphicsCallResult := PcxDisplayFile('SAM3A.END', 1, 0, 0);
{$ENDIF}
{$ENDIF}
  RestoreGamePalette(0);
  for EndingDelayIteration := 1 to 30 do
  begin
    Delay(50);
    MemW[0:$041C] := MemW[0:$041A];
  end;
  ShowMissionSuccessText;
  MemW[0:$041C] := MemW[0:$041A];
  repeat until KeyPressed;
{$IFDEF SAM3}
  FadeGamePaletteToBlack(0);
  ShowEpisodeE_GraphicsCallResult := PcxDisplayFile('SAM3B.END', 1, 0, 0);
  RestoreGamePalette(0);
  MemW[0:$041C] := MemW[0:$041A];
  repeat until KeyPressed;
{$ENDIF}
  MemW[0:$041C] := MemW[0:$041A];
  InsertPlayerHighScore;
  ReturnToTitleRequested := 1;
  EpisodeBlueprintCollected := 0;
  QuitGameRequested := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{ The u3 unit initialization block is empty. }
begin
end.
