{ Text display unit: draws colored DOS text boxes and strings, queries
  the video adapter and selects the text-memory segment. }
unit TEXT80;
{$A+}{$D+}{$L+}{$F-}
interface
uses SAMDATA;
var
  TextVideoSegment: Word;
  TextRetraceSyncEnabled: Byte;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedTextSyncPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedTextSyncPadLater: Byte;
{$ENDIF}
  { Unused storage retains DATA layout. }
  UnusedTextAuxiliaryValue: LongInt;
  TextSavedBiosMode: Byte;
  TextVideoAdapterClass: Byte;
function MakeTextAttribute(ForegroundColor, BackgroundColor: Byte): Byte;
function RepeatTextCharacter(RepeatCount: Byte; RepeatedChar: Char): String;
procedure FillTextRectangle(LeftColumn, TopRow, RightColumn,
  BottomRow, ForegroundColor, BackgroundColor: Integer);
procedure DrawTextBoxBorder(LeftColumn, TopRow, RightColumn,
  BottomRow, ForegroundColor, BackgroundColor, BorderStyle: Integer);
procedure DrawFilledTextBox(LeftColumn, TopRow, RightColumn,
  BottomRow, ForegroundColor, BackgroundColor,
  BorderStyle: Integer);
procedure WriteCenteredText(TextRow, ForegroundColor, BackgroundColor: Word;
  DisplayText: String);
procedure WriteVerticalText(TextColumn: Word; FirstTextRow: Integer; ForegroundColor,
  BackgroundColor: Word; DisplayText: String);
procedure ConfigureTextVideoMemory;
procedure WriteColoredText(TextColumn, TextRow, ColorAttribute: Byte;
  DisplayText: String);
function DetectTextVideoAdapter: Byte;
function GetTextVideoMode: Byte;
implementation
uses Dos, PROGRPHX, Crt, SAMSOUND, GAMEJOY, PCXGENUS;

const
  { Geometry of the 80-column, 25-row DOS text screen. }
  TextScreenColumns = 80;
  TextScreenRows = 25;
  TextCenterColumn = 40;
  TextBackgroundShift = 4;

  { Border styles accepted by DrawTextBoxBorder. Other values are characters. }
  TextBorderBlank = 0;
  TextBorderSingle = 1;
  TextBorderDouble = 2;
  TextBorderSingleHorizontal = 3;
  TextBorderDoubleHorizontal = 4;

  { CP437 single, double and mixed box-drawing characters. }
  TextSingleTopLeft = #218;
  TextSingleTopRight = #191;
  TextSingleBottomLeft = #192;
  TextSingleBottomRight = #217;
  TextSingleHorizontal = #196;
  TextSingleVertical = #179;
  TextDoubleTopLeft = #201;
  TextDoubleTopRight = #187;
  TextDoubleBottomLeft = #200;
  TextDoubleBottomRight = #188;
  TextDoubleHorizontal = #205;
  TextDoubleVertical = #186;
  TextMixedSingleTopLeft = #214;
  TextMixedSingleTopRight = #183;
  TextMixedSingleBottomLeft = #211;
  TextMixedSingleBottomRight = #189;
  TextMixedDoubleTopLeft = #213;
  TextMixedDoubleTopRight = #184;
  TextMixedDoubleBottomLeft = #212;
  TextMixedDoubleBottomRight = #190;

  { BIOS mode, VRAM segments and the adapter class requiring CGA synchronization. }
  TextMonochromeMode = 7;
  TextMonochromeSegment = $B000;
  TextColorSegment = $B800;
  TextCgaAdapterClass = 1;

{ Assembly text output and BIOS queries. }
{$L TEXTOUT.OBJ}
{ Writes Pascal-String characters and attribute bytes to text VRAM, with optional CGA synchronization. }
procedure WriteColoredText; external;
{ BIOS capability calls classify the display adapter and return the class Byte saved in
  TextVideoAdapterClass. }
function DetectTextVideoAdapter; external;
{ Calls the BIOS-mode helper and returns its AL result. }
function GetTextVideoMode; external;

{ Text attributes and String helpers. }
{$F+}
{ Packs background in the high nibble and foreground in the low nibble. }
function MakeTextAttribute(ForegroundColor, BackgroundColor: Byte): Byte;
begin
  MakeTextAttribute := (BackgroundColor shl TextBackgroundShift) or ForegroundColor;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Creates a length-prefixed string of a repeated character, limiting the count to 1..80. }
function RepeatTextCharacter(RepeatCount: Byte; RepeatedChar: Char): String;
var
  RepeatedText: String;
begin
  { Invalid widths become one character; this is not saturation at 80. }
  if not (RepeatCount in [1 .. TextScreenColumns]) then
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
  if RightColumn > TextScreenColumns then
    RightColumn := TextScreenColumns;
  FillAttr := MakeTextAttribute(ForegroundColor, BackgroundColor);
  for FillRow := TopRow to BottomRow do
    WriteColoredText(LeftColumn, FillRow, FillAttr, RepeatTextCharacter(RightColumn - LeftColumn + 1, ' '));
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
    TextBorderBlank:
      begin
        TopLeftChar := ' ';
        TopRightChar := ' ';
        BottomLeftChar := ' ';
        BottomRightChar := ' ';
        HorizontalChar := ' ';
        VerticalChar := ' ';
      end;
    TextBorderSingle:
      begin
        TopLeftChar := TextSingleTopLeft;
        TopRightChar := TextSingleTopRight;
        BottomLeftChar := TextSingleBottomLeft;
        BottomRightChar := TextSingleBottomRight;
        HorizontalChar := TextSingleHorizontal;
        VerticalChar := TextSingleVertical;
      end;
    TextBorderDouble:
      begin
        TopLeftChar := TextDoubleTopLeft;
        TopRightChar := TextDoubleTopRight;
        BottomLeftChar := TextDoubleBottomLeft;
        BottomRightChar := TextDoubleBottomRight;
        HorizontalChar := TextDoubleHorizontal;
        VerticalChar := TextDoubleVertical;
      end;
    TextBorderSingleHorizontal:
      begin
        TopLeftChar := TextMixedSingleTopLeft;
        TopRightChar := TextMixedSingleTopRight;
        BottomLeftChar := TextMixedSingleBottomLeft;
        BottomRightChar := TextMixedSingleBottomRight;
        HorizontalChar := TextSingleHorizontal;
        VerticalChar := TextDoubleVertical;
      end;
    TextBorderDoubleHorizontal:
      begin
        TopLeftChar := TextMixedDoubleTopLeft;
        TopRightChar := TextMixedDoubleTopRight;
        BottomLeftChar := TextMixedDoubleBottomLeft;
        BottomRightChar := TextMixedDoubleBottomRight;
        HorizontalChar := TextDoubleHorizontal;
        VerticalChar := TextSingleVertical;
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
  WriteColoredText(LeftColumn + 1, TopRow, BorderAttr, RepeatTextCharacter(RightColumn - LeftColumn - 1,
    HorizontalChar));
  WriteColoredText(RightColumn, TopRow, BorderAttr, TopRightChar);
  for BorderRow := TopRow + 1 to BottomRow - 1 do
  begin
    WriteColoredText(LeftColumn, BorderRow, BorderAttr, VerticalChar);
    WriteColoredText(RightColumn, BorderRow, BorderAttr, VerticalChar);
  end;
  WriteColoredText(LeftColumn, BottomRow, BorderAttr, BottomLeftChar);
  WriteColoredText(LeftColumn + 1, BottomRow, BorderAttr, RepeatTextCharacter(RightColumn - LeftColumn - 1,
    HorizontalChar));
  WriteColoredText(RightColumn, BottomRow, BorderAttr, BottomRightChar);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Draws a text-box border and fills its interior with spaces. }
procedure DrawFilledTextBox(LeftColumn, TopRow, RightColumn,
  BottomRow, ForegroundColor, BackgroundColor,
  BorderStyle: Integer);
begin
  DrawTextBoxBorder(LeftColumn, TopRow, RightColumn, BottomRow, ForegroundColor, BackgroundColor, BorderStyle);
  FillTextRectangle(LeftColumn + 1, TopRow + 1, RightColumn - 1, BottomRow - 1, ForegroundColor, BackgroundColor);
end;

{ Centered and vertical text. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Computes column 40-Length(Text) div 2 and writes the colored String on the selected row. }
procedure WriteCenteredText(TextRow, ForegroundColor, BackgroundColor: Word;
  DisplayText: String);
begin
  WriteColoredText(TextCenterColumn - Ord(DisplayText[0]) div 2, Byte(TextRow),
    MakeTextAttribute(Byte(ForegroundColor), Byte(BackgroundColor)), DisplayText);
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
  { Keep rows through 25, inclusive; Delete starts at the first hidden character. }
  if Ord(DisplayText[0]) > Integer(TextScreenRows + 1 - FirstTextRow) then
    Delete(DisplayText, TextScreenRows + 2 - FirstTextRow, TextScreenColumns);
  for CharacterIndex := 1 to Ord(DisplayText[0]) do
  begin
    { This unused string assignment is retained for byte exactness. }
    CharacterText := DisplayText[CharacterIndex];
    WriteColoredText(Byte(TextColumn), FirstTextRow - 1 + CharacterIndex, MakeTextAttribute(Byte(ForegroundColor),
      Byte(BackgroundColor)), DisplayText[CharacterIndex]);
  end;
end;

{ Display-memory initialization. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Selects B000 for mode 7 or B800 otherwise and enables CGA retrace synchronization for adapter class 1. }
procedure ConfigureTextVideoMemory;
begin
  if GetTextVideoMode = TextMonochromeMode then
    TextVideoSegment := TextMonochromeSegment
  else
    TextVideoSegment := TextColorSegment;
  TextRetraceSyncEnabled := Ord(DetectTextVideoAdapter = TextCgaAdapterClass);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
begin
  ConfigureTextVideoMemory;
  UnusedTextAuxiliaryValue := 200;
end.
