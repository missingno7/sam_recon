unit TEXT80;
{$A+}{$D+}{$L+}{$F-}
interface
uses SAMDATA;
var
  TextVideoSegment: word;
  TextRetraceSyncEnabled: byte;
{$IFDEF SAM1}
  reserved_21d9: Byte;
{$ELSE}
  reserved_21ff: Byte;
{$ENDIF}
  TextAuxiliaryValue: longint;
  TextSavedBiosMode: byte;
  TextVideoAdapterClass: byte;
function MakeTextAttribute(ForegroundColor, BackgroundColor: Byte): Byte;
function RepeatTextCharacter(RepeatCount: Byte; RepeatedChar: Char): string;
procedure FillTextRectangle(FillTextRectangle_LeftColumn, FillTextRectangle_TopRow, FillTextRectangle_RightColumn,
  FillTextRectangle_BottomRow, FillTextRectang_ForegroundColor, FillTextRectang_BackgroundColor: Integer);
procedure DrawTextBoxBorder(DrawTextBoxBorder_LeftColumn, DrawTextBoxBorder_TopRow, DrawTextBoxBorder_RightColumn,
  DrawTextBoxBorder_BottomRow, DrawTextBoxBord_ForegroundColor, DrawTextBoxBord_BackgroundColor, BorderStyle: Integer);
procedure DrawFilledTextBox(DrawFilledTextBox_LeftColumn, DrawFilledTextBox_TopRow, DrawFilledTextBox_RightColumn,
  DrawFilledTextBox_BottomRow, DrawFilledTextB_ForegroundColor, DrawFilledTextB_BackgroundColor,
  DrawFilledTextBox_BorderStyle: Integer);
procedure WriteCenteredText(WriteCenteredText_TextRow, WriteCenteredTe_ForegroundColor, WriteCenteredTe_BackgroundColor: Word;
  WriteCenteredText_DisplayText: string);
procedure WriteVerticalText(WriteVerticalText_TextColumn: Word; FirstTextRow: Integer; WriteVerticalTe_ForegroundColor,
  WriteVerticalTe_BackgroundColor: Word; WriteVerticalText_DisplayText: String);
procedure ConfigureTextVideoMemory;
procedure WriteColoredText(WriteColoredText_TextColumn, WriteColoredText_TextRow, WriteColoredText_TextAttr: Byte;
  WriteColoredText_DisplayText: string);
function DetectTextVideoAdapter: Byte;
function GetTextVideoMode: Byte;
implementation
uses Dos, PROGRPHX, Crt, SAMSOUND, GAMEJOY, PCXGENUS;
{$L TEXTOUT.OBJ}
{ Writes Pascal-string characters and attribute bytes to text VRAM, with optional CGA synchronization. }
procedure WriteColoredText; external;
{ BIOS capability calls classify the display adapter and return the class byte saved in d_21DF. }
function DetectTextVideoAdapter; external;
{ Calls the BIOS-mode helper and returns its AL result. }
function GetTextVideoMode; external;
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
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Writes space strings over each row of a text rectangle with the requested foreground/background. }
procedure FillTextRectangle(FillTextRectangle_LeftColumn, FillTextRectangle_TopRow, FillTextRectangle_RightColumn,
  FillTextRectangle_BottomRow, FillTextRectang_ForegroundColor, FillTextRectang_BackgroundColor: Integer);
var
  FillRow: Integer;
  FillAttr: Byte;
begin
  if FillTextRectangle_RightColumn > 80 then
    FillTextRectangle_RightColumn := 80;
  FillAttr := MakeTextAttribute(FillTextRectang_ForegroundColor, FillTextRectang_BackgroundColor);
  for FillRow := FillTextRectangle_TopRow to FillTextRectangle_BottomRow do
    WriteColoredText(FillTextRectangle_LeftColumn, FillRow, FillAttr, RepeatTextCharacter(FillTextRectangle_RightColumn -
    FillTextRectangle_LeftColumn + 1, ' '));
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Selects single/double/custom box characters and draws four sides and corners. }
procedure DrawTextBoxBorder(DrawTextBoxBorder_LeftColumn, DrawTextBoxBorder_TopRow, DrawTextBoxBorder_RightColumn,
  DrawTextBoxBorder_BottomRow, DrawTextBoxBord_ForegroundColor, DrawTextBoxBord_BackgroundColor, BorderStyle: Integer);
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

  BorderAttr := MakeTextAttribute(DrawTextBoxBord_ForegroundColor, DrawTextBoxBord_BackgroundColor);
  WriteColoredText(DrawTextBoxBorder_LeftColumn, DrawTextBoxBorder_TopRow, BorderAttr, TopLeftChar);
  WriteColoredText(DrawTextBoxBorder_LeftColumn + 1, DrawTextBoxBorder_TopRow, BorderAttr,
  RepeatTextCharacter(DrawTextBoxBorder_RightColumn - DrawTextBoxBorder_LeftColumn - 1, HorizontalChar));
  WriteColoredText(DrawTextBoxBorder_RightColumn, DrawTextBoxBorder_TopRow, BorderAttr, TopRightChar);
  for BorderRow := DrawTextBoxBorder_TopRow + 1 to DrawTextBoxBorder_BottomRow - 1 do
  begin
    WriteColoredText(DrawTextBoxBorder_LeftColumn, BorderRow, BorderAttr, VerticalChar);
    WriteColoredText(DrawTextBoxBorder_RightColumn, BorderRow, BorderAttr, VerticalChar);
  end;
  WriteColoredText(DrawTextBoxBorder_LeftColumn, DrawTextBoxBorder_BottomRow, BorderAttr, BottomLeftChar);
  WriteColoredText(DrawTextBoxBorder_LeftColumn + 1, DrawTextBoxBorder_BottomRow, BorderAttr,
  RepeatTextCharacter(DrawTextBoxBorder_RightColumn - DrawTextBoxBorder_LeftColumn - 1, HorizontalChar));
  WriteColoredText(DrawTextBoxBorder_RightColumn, DrawTextBoxBorder_BottomRow, BorderAttr, BottomRightChar);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Draws a text-box border and fills its interior with spaces. }
procedure DrawFilledTextBox(DrawFilledTextBox_LeftColumn, DrawFilledTextBox_TopRow, DrawFilledTextBox_RightColumn,
  DrawFilledTextBox_BottomRow, DrawFilledTextB_ForegroundColor, DrawFilledTextB_BackgroundColor,
  DrawFilledTextBox_BorderStyle: Integer);
begin
  DrawTextBoxBorder(DrawFilledTextBox_LeftColumn, DrawFilledTextBox_TopRow, DrawFilledTextBox_RightColumn,
  DrawFilledTextBox_BottomRow, DrawFilledTextB_ForegroundColor, DrawFilledTextB_BackgroundColor,
  DrawFilledTextBox_BorderStyle);
  FillTextRectangle(DrawFilledTextBox_LeftColumn + 1, DrawFilledTextBox_TopRow + 1, DrawFilledTextBox_RightColumn - 1,
  DrawFilledTextBox_BottomRow - 1, DrawFilledTextB_ForegroundColor, DrawFilledTextB_BackgroundColor);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Computes column 40-Length(Text) div 2 and writes the colored string on the selected row. }
procedure WriteCenteredText(WriteCenteredText_TextRow, WriteCenteredTe_ForegroundColor, WriteCenteredTe_BackgroundColor: Word;
  WriteCenteredText_DisplayText: string);
begin
  WriteColoredText(40 - Ord(WriteCenteredText_DisplayText[0]) div 2, Byte(WriteCenteredText_TextRow),
  MakeTextAttribute(Byte(WriteCenteredTe_ForegroundColor), Byte(WriteCenteredTe_BackgroundColor)),
  WriteCenteredText_DisplayText);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Writes successive source characters down a fixed column and truncates at screen row 25. }
procedure WriteVerticalText(WriteVerticalText_TextColumn: Word; FirstTextRow: Integer; WriteVerticalTe_ForegroundColor,
  WriteVerticalTe_BackgroundColor: Word; WriteVerticalText_DisplayText: String);
var
  WriteVerticalTex_CharacterIndex: Integer;
  CharacterText: String;
begin
  if Ord(WriteVerticalText_DisplayText[0]) > Integer(26 - FirstTextRow) then
    Delete(WriteVerticalText_DisplayText, 27 - FirstTextRow, 80);
  for WriteVerticalTex_CharacterIndex := 1 to Ord(WriteVerticalText_DisplayText[0]) do
  begin
    CharacterText := WriteVerticalText_DisplayText[WriteVerticalTex_CharacterIndex];
    WriteColoredText(Byte(WriteVerticalText_TextColumn), FirstTextRow - 1 + WriteVerticalTex_CharacterIndex,
    MakeTextAttribute(Byte(WriteVerticalTe_ForegroundColor), Byte(WriteVerticalTe_BackgroundColor)),
    WriteVerticalText_DisplayText[WriteVerticalTex_CharacterIndex]);
  end;
end;
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
  TextAuxiliaryValue := 200;
end.
