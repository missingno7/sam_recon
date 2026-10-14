{ Text display unit: draws colored DOS text boxes and strings, queries
  the video adapter and selects the text-memory segment. }
unit TEXT80;
{$A+}{$D+}{$L+}{$F-}
interface
uses SAMDATA;
var
  TextVideoSegment: word;
  TextRetraceSyncEnabled: byte;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedTextSyncPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedTextSyncPadLater: Byte;
{$ENDIF}
  { Unused storage retains DATA layout. }
  UnusedTextAuxiliaryValue: longint;
  TextSavedBiosMode: byte;
  TextVideoAdapterClass: byte;
function MakeTextAttribute(ForegroundColor, BackgroundColor: Byte): Byte;
function RepeatTextCharacter(RepeatCount: Byte; RepeatedChar: Char): string;
procedure FillTextRectangle(LeftColumn, TopRow, RightColumn,
  BottomRow, ForegroundColor, BackgroundColor: Integer);
procedure DrawTextBoxBorder(LeftColumn, TopRow, RightColumn,
  BottomRow, ForegroundColor, BackgroundColor, BorderStyle: Integer);
procedure DrawFilledTextBox(LeftColumn, TopRow, RightColumn,
  BottomRow, ForegroundColor, BackgroundColor,
  BorderStyle: Integer);
procedure WriteCenteredText(TextRow, ForegroundColor, BackgroundColor: Word;
  DisplayText: string);
procedure WriteVerticalText(TextColumn: Word; FirstTextRow: Integer; ForegroundColor,
  BackgroundColor: Word; DisplayText: String);
procedure ConfigureTextVideoMemory;
procedure WriteColoredText(TextColumn, TextRow, ColorAttribute: Byte;
  DisplayText: string);
function DetectTextVideoAdapter: Byte;
function GetTextVideoMode: Byte;
implementation
uses Dos, PROGRPHX, Crt, SAMSOUND, GAMEJOY, PCXGENUS;

{ Assembly text output and BIOS queries. }
{$L TEXTOUT.OBJ}
{ Writes Pascal-string characters and attribute bytes to text VRAM, with optional CGA synchronization. }
procedure WriteColoredText; external;
{ BIOS capability calls classify the display adapter and return the class byte saved in TextVideoAdapterClass. }
function DetectTextVideoAdapter; external;
{ Calls the BIOS-mode helper and returns its AL result. }
function GetTextVideoMode; external;

{ Text attributes and string helpers. }
{$F+}
{ Packs background in the high nibble and foreground in the low nibble. }
function MakeTextAttribute(ForegroundColor, BackgroundColor: Byte): Byte;
begin
  MakeTextAttribute := (BackgroundColor shl 4) or ForegroundColor;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Creates a length-prefixed string of a repeated character, limiting the count to 1..80. }
function RepeatTextCharacter(RepeatCount: Byte; RepeatedChar: Char): string;
var
  RepeatedText: string;
begin
  if not (RepeatCount in [1..80]) then
    RepeatCount := 1;
  FillChar(RepeatedText, RepeatCount + 1, RepeatedChar);
  RepeatedText[0] := Chr(RepeatCount);
  RepeatTextCharacter := RepeatedText;
end;

{ Text rectangles and borders. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Writes space strings over each row of a text rectangle with the requested foreground/background. }
procedure FillTextRectangle(LeftColumn, TopRow, RightColumn,
  BottomRow, ForegroundColor, BackgroundColor: Integer);
var
  FillRow: Integer;
  FillAttr: Byte;
begin
  if RightColumn > 80 then
    RightColumn := 80;
  FillAttr := MakeTextAttribute(ForegroundColor, BackgroundColor);
  for FillRow := TopRow to BottomRow do
    WriteColoredText(LeftColumn, FillRow, FillAttr, RepeatTextCharacter(RightColumn -
    LeftColumn + 1, ' '));
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Selects single/double/custom box characters and draws four sides and corners. }
procedure DrawTextBoxBorder(LeftColumn, TopRow, RightColumn,
  BottomRow, ForegroundColor, BackgroundColor, BorderStyle: Integer);
var
  BorderRow: Integer;
  TopLeftChar, TopRightChar, BottomLeftChar, BottomRightChar, HorizontalChar, VerticalChar: Char;
  BorderAttr: Byte;
begin
  case BorderStyle of
    0:
    begin
      TopLeftChar := ' ';
      TopRightChar := ' ';
      BottomLeftChar := ' ';
      BottomRightChar := ' ';
      HorizontalChar := ' ';
      VerticalChar := ' ';
    end;
    1:
    begin
      TopLeftChar := #218;
      TopRightChar := #191;
      BottomLeftChar := #192;
      BottomRightChar := #217;
      HorizontalChar := #196;
      VerticalChar := #179;
    end;
    2:
    begin
      TopLeftChar := #201;
      TopRightChar := #187;
      BottomLeftChar := #200;
      BottomRightChar := #188;
      HorizontalChar := #205;
      VerticalChar := #186;
    end;
    3:
    begin
      TopLeftChar := #214;
      TopRightChar := #183;
      BottomLeftChar := #211;
      BottomRightChar := #189;
      HorizontalChar := #196;
      VerticalChar := #186;
    end;
    4:
    begin
      TopLeftChar := #213;
      TopRightChar := #184;
      BottomLeftChar := #212;
      BottomRightChar := #190;
      HorizontalChar := #205;
      VerticalChar := #179;
    end;
  else
    begin
      TopLeftChar := Chr(BorderStyle);
      TopRightChar := Chr(BorderStyle);
      BottomLeftChar := Chr(BorderStyle);
      BottomRightChar := Chr(BorderStyle);
      HorizontalChar := Chr(BorderStyle);
      VerticalChar := Chr(BorderStyle);
    end;
  end;

  BorderAttr := MakeTextAttribute(ForegroundColor, BackgroundColor);
  WriteColoredText(LeftColumn, TopRow, BorderAttr, TopLeftChar);
  WriteColoredText(LeftColumn + 1, TopRow, BorderAttr,
  RepeatTextCharacter(RightColumn - LeftColumn - 1, HorizontalChar));
  WriteColoredText(RightColumn, TopRow, BorderAttr, TopRightChar);
  for BorderRow := TopRow + 1 to BottomRow - 1 do
  begin
    WriteColoredText(LeftColumn, BorderRow, BorderAttr, VerticalChar);
    WriteColoredText(RightColumn, BorderRow, BorderAttr, VerticalChar);
  end;
  WriteColoredText(LeftColumn, BottomRow, BorderAttr, BottomLeftChar);
  WriteColoredText(LeftColumn + 1, BottomRow, BorderAttr,
  RepeatTextCharacter(RightColumn - LeftColumn - 1, HorizontalChar));
  WriteColoredText(RightColumn, BottomRow, BorderAttr, BottomRightChar);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Draws a text-box border and fills its interior with spaces. }
procedure DrawFilledTextBox(LeftColumn, TopRow, RightColumn,
  BottomRow, ForegroundColor, BackgroundColor,
  BorderStyle: Integer);
begin
  DrawTextBoxBorder(LeftColumn, TopRow, RightColumn,
  BottomRow, ForegroundColor, BackgroundColor,
  BorderStyle);
  FillTextRectangle(LeftColumn + 1, TopRow + 1, RightColumn - 1,
  BottomRow - 1, ForegroundColor, BackgroundColor);
end;

{ Centered and vertical text. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Computes column 40-Length(Text) div 2 and writes the colored string on the selected row. }
procedure WriteCenteredText(TextRow, ForegroundColor, BackgroundColor: Word;
  DisplayText: string);
begin
  WriteColoredText(40 - Ord(DisplayText[0]) div 2, Byte(TextRow),
  MakeTextAttribute(Byte(ForegroundColor), Byte(BackgroundColor)),
  DisplayText);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Writes successive source characters down a fixed column and truncates at screen row 25. }
procedure WriteVerticalText(TextColumn: Word; FirstTextRow: Integer; ForegroundColor,
  BackgroundColor: Word; DisplayText: String);
var
  CharacterIndex: Integer;
  CharacterText: String;
begin
  if Ord(DisplayText[0]) > Integer(26 - FirstTextRow) then
    Delete(DisplayText, 27 - FirstTextRow, 80);
  for CharacterIndex := 1 to Ord(DisplayText[0]) do
  begin
    CharacterText := DisplayText[CharacterIndex];
    WriteColoredText(Byte(TextColumn), FirstTextRow - 1 + CharacterIndex,
    MakeTextAttribute(Byte(ForegroundColor), Byte(BackgroundColor)),
    DisplayText[CharacterIndex]);
  end;
end;

{ Display-memory initialization. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Selects B000 for mode 7 or B800 otherwise and enables CGA retrace synchronization for adapter class 1. }
procedure ConfigureTextVideoMemory;
begin
  if GetTextVideoMode = 7 then
    TextVideoSegment := $B000
  else
    TextVideoSegment := $B800;
  TextRetraceSyncEnabled := Ord(DetectTextVideoAdapter = 1);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
begin
  ConfigureTextVideoMemory;
  UnusedTextAuxiliaryValue := 200;
end.
