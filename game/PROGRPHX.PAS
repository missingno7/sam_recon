{ Pascal interface to ProGraphx 2.0 by Peder Jungck.
  Provides EGA/VGA drawing, panning and buffer copies from PROGRAPX.OBJ. }
unit PROGRPHX;
{$A+}{$D+}{$L+}{$F-}
interface
uses Dos;
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
procedure PgBlitMasked16x16(var ImageSource; ByteColumn,PixelRow: Integer);
procedure PgBlitMasked8x8(var ImageSource; ByteColumn, PixelRow: Integer);
procedure PgSetDrawColor(DrawColor: Word);
procedure PgFillRectangleByteAligned(LeftByteColumn, WidthBytes, TopPixelRow, HeightRows: Word);
procedure PgCapturePlanarRectangle(var CapturedImage; LeftByteColumn, TopPixelRow,
  RightByteLimit, BottomPixelRow: Integer);
procedure PgRestorePlanarRectangle(var CapturedImage; ByteColumn,
  PixelRow: Integer);
procedure PgBlitMaskedShifted16x16(var SpriteSource; PixelX, PixelY: Integer);
procedure PgBlitMaskedShifted8x8(var GlyphSource: Byte; PixelX, PixelY: Word);
procedure PgOrShifted16x16(var SpriteSource; PixelX,PixelY: Integer);
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
{ Set toolbox video mode. }
procedure PgSetToolboxVideoMode; external;
{ Set bios video mode. }
procedure PgSetBiosVideoMode; external;
{ Set screen stride. }
function PgSetScreenStride; external;
{ Programs CRTC start address after retrace, then waits for bit 3 of port 3DAh to become set before. }
procedure PgPanDisplayAtRetraceStart; external;
{ Programs CRTC start address after retrace, then waits for bit 3 of port 3DAh to become clear before. }
procedure PgPanDisplayAtRetraceEnd; external;
{ Programs line-compare register 18h and overflow bit 8; RunSecretAgent calls this path when the adapter is not VGA. }
procedure PgSetEgaSplitScanline; external;
{ Wait vertical retrace. }
procedure PgWaitVerticalRetrace; external;
{ Programs line-compare and overflow registers including register 9; RunSecretAgent selects this path for VGA. }
procedure PgSetVgaSplitScanline; external;
{ Set border color. }
procedure PgSetBorderColor; external;
{ Set palette register. }
procedure PgSetPaletteRegister; external;

{ Planar sprites and rectangle capture. }
{ Blit masked 16x16. }
procedure PgBlitMasked16x16; external;
{ Blit masked 8x8. }
procedure PgBlitMasked8x8; external;
{ Stores the requested word in CS:draw_color, used as the four-plane fill/pixel color. }
procedure PgSetDrawColor; external;
{ Fill rectangle byte aligned. }
procedure PgFillRectangleByteAligned; external;
{ Capture planar rectangle. }
procedure PgCapturePlanarRectangle; external;
{ Restore planar rectangle. }
procedure PgRestorePlanarRectangle; external;
{ Blit masked shifted 16x16. }
procedure PgBlitMaskedShifted16x16; external;
{ Loops over exactly eight rows, splitting one mask and four plane bytes across two destination bytes. }
procedure PgBlitMaskedShifted8x8; external;
{ Processes 16 rows of two shifted byte groups using source masks and read-before-OR destination writes. }
procedure PgOrShifted16x16; external;

{ Font selection and video-buffer copies. }
{ Initialize rom fonts. }
procedure PgInitializeRomFonts; external;
{ Select rom font. }
procedure PgSelectRomFont; external;
{ Blit opaque 16x16. }
procedure PgBlitOpaque16x16; external;
{ Blit opaque 8x8. }
procedure PgBlitOpaque8x8; external;
{ Copy cached video tile 16x16. }
procedure PgCopyCachedVideoTile16x16; external;
{ Copy video screen region 320x200. }
procedure PgCopyVideoScreenRegion320x200; external;
{ Copies eight 40-byte rows from VRAM offset 28h to offset 0; DrawGameStatusBar calls it before drawing the status bar. }
procedure PgCopyStatusBandTemplate; external;
begin
  PgSetToolboxVideoMode(1);
  PgInitializeRomFonts;
  PgSelectRomFont(0);
  PgSetBiosVideoMode($10);
  PgSetDrawColor($0F);
  ProGraphxContactText := 'Copyright 1991 Peder Jungck';
  ProGraphxContactText := '1019 W Lovers Lane         ';
  ProGraphxContactText := 'Arlington, Texas  76013    ';
  ProGraphxContactText := '(817) 795-8903             ';
end.
