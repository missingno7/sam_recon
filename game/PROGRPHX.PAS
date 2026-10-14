{ Pascal interface to ProGraphx 2.0 by Peder Jungck.
  Provides EGA/VGA drawing, panning and buffer copies from PROGRAPX.OBJ. }
unit PROGRPHX;
{$A+}{$D+}{$L+}{$F-}
interface
uses Dos;
const
  { Toolbox/BIOS modes used by this unit's original initialization. }
  PgToolboxEga640x350 = 1;
  PgBiosEga640x350 = $10;
  { ROM font selection and the four-plane EGA color value. }
  PgRomFont8x14 = 0;
  PgColorWhite = $0F;
var
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedPgContactStorageSam1: array[0..81] of Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedPgContactStorageLater: array[0..81] of Byte;
{$ENDIF}
  ProGraphxContactText: string[80];
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedPgContactPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedPgContactPadLater: Byte;
{$ENDIF}
procedure PgSetToolboxVideoMode(ToolboxMode: Word);
procedure PgSetBiosVideoMode(BiosMode: Word);
function PgSetScreenStride(StrideBytes: Word): Integer;
procedure PgPanDisplayAtRetraceStart(PanPixelX, PanPixelY: Word);
procedure PgPanDisplayAtRetraceEnd(PanPixelX, PanPixelY: Word);
procedure PgSetEgaSplitScanline(SplitScanline: Word);
procedure PgWaitVerticalRetrace;
procedure PgSetVgaSplitScanline(SplitScanline: Word);
procedure PgSetBorderColor(BorderColor: Word);
procedure PgSetPaletteRegister(PaletteIndex, PaletteColor: Integer);
procedure PgBlitMasked16x16(var ImageSource; ByteColumn, PixelRow: Integer);
procedure PgBlitMasked8x8(var ImageSource; ByteColumn, PixelRow: Integer);
procedure PgSetDrawColor(DrawColor: Word);
procedure PgFillRectangleByteAligned(LeftByteColumn, WidthBytes, TopPixelRow, HeightRows: Word);
procedure PgCapturePlanarRectangle(var CapturedImage; LeftByteColumn, TopPixelRow,
  RightByteLimit, BottomPixelRow: Integer);
procedure PgRestorePlanarRectangle(var CapturedImage; ByteColumn,
  PixelRow: Integer);
procedure PgBlitMaskedShifted16x16(var SpriteSource; PixelX, PixelY: Integer);
procedure PgBlitMaskedShifted8x8(var GlyphSource: Byte; PixelX, PixelY: Word);
procedure PgOrShifted16x16(var SpriteSource; PixelX, PixelY: Integer);
procedure PgInitializeRomFonts;
procedure PgSelectRomFont(FontIndex: Word);
procedure PgBlitOpaque16x16(var ImageSource; ByteColumn, PixelRow:
  Integer);
procedure PgBlitOpaque8x8(var ImageSource; ByteColumn, PixelRow: Integer);
procedure PgCopyCachedVideoTile16x16(ByteColumn, PixelRow, CachedTileIndex:
  Integer);
procedure PgCopyVideoScreenRegion320x200(SourceByteColumn, SourcePixelRow, DestByteColumn, DestPixelRow: Word);
procedure PgCopyStatusBandTemplate;
implementation

{ Video mode, panning and palette control. }
{$L PROGRAPX.OBJ}
{ Maps toolbox mode 0/1/other to BIOS EGA 320x200/640x350/VGA 640x480. }
procedure PgSetToolboxVideoMode; external;
{ Sets the BIOS video mode directly with INT 10h AH=0. }
procedure PgSetBiosVideoMode; external;
{ Clamps the planar row stride to at least 40 bytes and programs the CRTC.
  The declared Integer result is the original assembly's returned AX. }
function PgSetScreenStride; external;
{ Sets the CRTC start address after retrace, then waits for the next retrace
  start before updating the attribute controller's fine horizontal pan. }
procedure PgPanDisplayAtRetraceStart; external;
{ Sets the CRTC start address after retrace, then updates fine horizontal pan
  while retrace is clear. The two routines retain their original wait order. }
procedure PgPanDisplayAtRetraceEnd; external;
{ Programs line-compare register 18h and overflow bit 8; RunSecretAgent calls this path when the adapter is not VGA. }
procedure PgSetEgaSplitScanline; external;
{ Waits for the current vertical retrace to end and the next one to start. }
procedure PgWaitVerticalRetrace; external;
{ Programs line-compare and overflow registers including register 9; RunSecretAgent selects this path for VGA. }
procedure PgSetVgaSplitScanline; external;
{ Sets the BIOS border/overscan color. }
procedure PgSetBorderColor; external;
{ Assigns one EGA palette register through BIOS INT 10h AX=$1000. }
procedure PgSetPaletteRegister; external;

{ Planar sprites and rectangle capture. }
{ Draws 16 rows of mask plus four plane bytes at a byte-aligned position. }
procedure PgBlitMasked16x16; external;
{ Draws eight rows of mask plus four plane bytes at a byte-aligned position. }
procedure PgBlitMasked8x8; external;
{ Stores the four-plane fill/pixel color in assembly CS state. }
procedure PgSetDrawColor; external;
{ Fills WidthBytes by HeightRows on the selected draw page. X is in bytes. }
procedure PgFillRectangleByteAligned; external;
{ Captures four planes, preceded by a row-count/byte-width header. The horizontal
  range ends at RightByteLimit; the bottom row is included. }
procedure PgCapturePlanarRectangle; external;
{ Restores a captured row-count/byte-width header and four planes on the draw page. }
procedure PgRestorePlanarRectangle; external;
{ Draws a masked 16x16 sprite at a pixel position, splitting shifted bytes
  across neighboring destination bytes. }
procedure PgBlitMaskedShifted16x16; external;
{ Loops over exactly eight rows, splitting one mask and four plane bytes across two destination bytes. }
procedure PgBlitMaskedShifted8x8; external;
{ Processes 16 rows of two shifted byte groups using source masks and read-before-OR destination writes. }
procedure PgOrShifted16x16; external;

{ Font selection and video-buffer copies. }
{ Queries BIOS pointers for the 8-row and 14-row ROM fonts. }
procedure PgInitializeRomFonts; external;
{ Selects the 8-row font for index 1; all other values select the 14-row font. }
procedure PgSelectRomFont; external;
{ Draws 16 rows of four plane byte pairs, overwriting the destination. }
procedure PgBlitOpaque16x16; external;
{ Draws eight rows of four plane bytes, overwriting the destination. }
procedure PgBlitOpaque8x8; external;
{ Uses EGA latches to copy a 16x16 tile from the VRAM cache at offset $FA00. }
procedure PgCopyCachedVideoTile16x16; external;
{ Uses EGA latches to copy 200 rows of 40 bytes between video-memory regions. }
procedure PgCopyVideoScreenRegion320x200; external;
{ Copies eight 40-byte rows from VRAM offset 28h to offset 0; DrawGameStatusBar calls it before drawing the status bar. }
procedure PgCopyStatusBandTemplate; external;
begin
  PgSetToolboxVideoMode(PgToolboxEga640x350);
  PgInitializeRomFonts;
  PgSelectRomFont(PgRomFont8x14);
  PgSetBiosVideoMode(PgBiosEga640x350);
  PgSetDrawColor(PgColorWhite);
  { These repeated assignments are original; only the last text remains.
    Keep all four assignments and literals for byte-exact reconstruction. }
  ProGraphxContactText := 'Copyright 1991 Peder Jungck';
  ProGraphxContactText := '1019 W Lovers Lane         ';
  ProGraphxContactText := 'Arlington, Texas  76013    ';
  ProGraphxContactText := '(817) 795-8903             ';
end.
