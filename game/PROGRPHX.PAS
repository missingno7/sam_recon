unit PROGRPHX;
{$A+}{$D+}{$L+}{$F-}
interface
uses Dos;
var
{$IFDEF SAM1}
  reserved_70ee: array[0..81] of Byte;
{$ELSE}
  reserved_7114: array[0..81] of Byte;
{$ENDIF}
  ProGraphxContactText: string[80];
{$IFDEF SAM1}
  reserved_7191: Byte;
{$ELSE}
  reserved_71b7: Byte;
{$ENDIF}
procedure PgSetToolboxVideoMode(ToolboxMode: Word);
procedure PgSetBiosVideoMode(PgSetBiosVideoMode_BiosMode: Word);
function PgSetScreenStride(StrideBytes: Word): Integer;
procedure PgPanDisplayAtRetraceStart(PanPixelX, PanPixelY: Word);
procedure PgPanDisplayAtRetraceEnd(PgPanDisplayAtRetrace_PanPixelX, PgPanDisplayAtRetrace_PanPixelY: Word);
procedure PgSetEgaSplitScanline(SplitScanline: Word);
procedure PgWaitVerticalRetrace;
procedure PgSetVgaSplitScanline(PgSetVgaSplitScan_SplitScanline: Word);
procedure PgSetBorderColor(BorderColor: Word);
procedure PgSetPaletteRegister(PgSetPaletteRegist_PaletteIndex, PaletteColor: Integer);
procedure PgBlitMasked16x16(var ImageSource; ByteColumn,PixelRow: Integer);
procedure PgBlitMasked8x8(var PgBlitMasked8x8_ImageSource; PgBlitMasked8x8_ByteColumn, PgBlitMasked8x8_PixelRow: Integer);
procedure PgSetDrawColor(DrawColor: Word);
procedure PgFillRectangleByteAligned(LeftByteColumn, WidthBytes, TopPixelRow, HeightRows: Word);
procedure PgCapturePlanarRectangle(var CapturedImage; PgCapturePlanarR_LeftByteColumn, PgCapturePlanarRect_TopPixelRow,
  RightByteLimit, BottomPixelRow: Integer);
procedure PgRestorePlanarRectangle(var PgRestorePlanarRe_CapturedImage; PgRestorePlanarRecta_ByteColumn,
  PgRestorePlanarRectang_PixelRow: Integer);
procedure PgBlitMaskedShifted16x16(var SpriteSource; PixelX, PixelY: Integer);
procedure PgBlitMaskedShifted8x8(var GlyphSource: Byte; PgBlitMaskedShifted8x8_PixelX, PgBlitMaskedShifted8x8_PixelY: Word);
procedure PgOrShifted16x16(var PgOrShifted16x16_SpriteSource; PgOrShifted16x16_PixelX,PgOrShifted16x16_PixelY: Integer);
procedure PgInitializeRomFonts;
procedure PgSelectRomFont(FontIndex: Word);
procedure PgBlitOpaque16x16(var PgBlitOpaque16x16_ImageSource; PgBlitOpaque16x16_ByteColumn, PgBlitOpaque16x16_PixelRow:
  Integer);
procedure PgBlitOpaque8x8(var PgBlitOpaque8x8_ImageSource; PgBlitOpaque8x8_ByteColumn, PgBlitOpaque8x8_PixelRow: Integer);
procedure PgCopyCachedVideoTile16x16(PgCopyCachedVideoTil_ByteColumn, PgCopyCachedVideoTile1_PixelRow, CachedTileIndex:
  Integer);
procedure PgCopyVideoScreenRegion320x200(SourceByteColumn, SourcePixelRow, DestByteColumn, DestPixelRow: Word);
procedure PgCopyStatusBandTemplate;
implementation
{$L PROGRAPX.OBJ}
{ src/asm/u9.asm u9_01a3: set toolbox video mode. }
procedure PgSetToolboxVideoMode; external;
{ src/asm/u9.asm u9_01c5: set bios video mode. }
procedure PgSetBiosVideoMode; external;
{ src/asm/u9.asm u9_01d3: set screen stride. }
function PgSetScreenStride; external;
{ Programs CRTC start address after retrace, then waits for bit 3 of port 3DAh to become set before. }
procedure PgPanDisplayAtRetraceStart; external;
{ Programs CRTC start address after retrace, then waits for bit 3 of port 3DAh to become clear before. }
procedure PgPanDisplayAtRetraceEnd; external;
{ Programs line-compare register 18h and overflow bit 8; p_1148 calls this path when the adapter is not VGA. }
procedure PgSetEgaSplitScanline; external;
{ src/asm/u9.asm u9_02db: wait vertical retrace. }
procedure PgWaitVerticalRetrace; external;
{ Programs line-compare and overflow registers including register 9; p_1148 selects this path for VGA. }
procedure PgSetVgaSplitScanline; external;
{ src/asm/u9.asm u9_0337: set border color. }
procedure PgSetBorderColor; external;
{ src/asm/u9.asm u9_0352: set palette register. }
procedure PgSetPaletteRegister; external;
{ src/asm/u9.asm u9_0475: blit masked 16x16. }
procedure PgBlitMasked16x16; external;
{ src/asm/u9.asm u9_051f: blit masked 8x8. }
procedure PgBlitMasked8x8; external;
{ Stores the requested word in CS:draw_color, used as the four-plane fill/pixel color. }
procedure PgSetDrawColor; external;
{ src/asm/u9.asm u9_07ee: fill rectangle byte aligned. }
procedure PgFillRectangleByteAligned; external;
{ src/asm/u9.asm u9_1795: capture planar rectangle. }
procedure PgCapturePlanarRectangle; external;
{ src/asm/u9.asm u9_1831: restore planar rectangle. }
procedure PgRestorePlanarRectangle; external;
{ src/asm/u9.asm u9_19f9: blit masked shifted 16x16. }
procedure PgBlitMaskedShifted16x16; external;
{ Loops over exactly eight rows, splitting one mask and four plane bytes across two destination bytes. }
procedure PgBlitMaskedShifted8x8; external;
{ Processes 16 rows of two shifted byte groups using source masks and read-before-OR destination writes. }
procedure PgOrShifted16x16; external;
{ src/asm/u9.asm u9_27e2: initialize rom fonts. }
procedure PgInitializeRomFonts; external;
{ src/asm/u9.asm u9_2981: select rom font. }
procedure PgSelectRomFont; external;
{ src/asm/u9.asm u9_2a9f: blit opaque 16x16. }
procedure PgBlitOpaque16x16; external;
{ src/asm/u9.asm u9_2b38: blit opaque 8x8. }
procedure PgBlitOpaque8x8; external;
{ src/asm/u9.asm u9_2e6d: copy cached video tile 16x16. }
procedure PgCopyCachedVideoTile16x16; external;
{ src/asm/u9.asm u9_2ecf: copy video screen region 320x200. }
procedure PgCopyVideoScreenRegion320x200; external;
{ Copies eight 40-byte rows from VRAM offset 28h to offset 0; u3_0261 calls it before drawing the status bar. }
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
