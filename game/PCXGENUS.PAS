{ Pascal interface to Genus PCX Programmer's Toolkit 3.56.
  Provides PCX display, video-descriptor and printer routines from GENUS.OBJ. }
unit PCXGENUS;
{$A+}{$D+}{$L+}{$F-}
interface
uses SAMDATA;
const
  { Table sizes and byte capacities of the toolkit's fixed work buffers. }
  PcxDisplayCount = 22;
  PcxBiosAdapterClassCount = 14;
  PcxReadWorkBufferCapacity = 2048;
  PcxPrinterScanlineBytes = 1024;
  PcxHerculesCrtcRegisterCount = 12;

  { Initialized toolkit identity and display descriptions occupy DATA. }
{$IFDEF SAM1}
{$ELSE}
  BiosAdapterClassMap: array[0..PcxBiosAdapterClassCount - 1] of Byte =
    (5, 0, 1, 5, 3, 3, 5, 4, 4, 5, 1, 1, 1, 0);
{$ENDIF}
  GenusPcxIdentity: TPcxIdentity =
    (PcxIdentityProduct: ' PCX Programmer''s Toolkit 3.56 '#0;
     PcxIdentityCopyright: ' Copyright (c) Genus Microprogramming, Inc. 1988-89'#0;
     PcxIdentityRights: ' All Rights Reserved.'#0;
     PcxIdentityAuthor: ' Christopher A. Howard '#0;
     PcxIdentityEmsDriverName: 'EMMXXXX'#0);
  PcxDisplayDescriptions: TPcxDisplayNameTable = (
    'CGA 320x200x4       ', 'CGA 640x200x2       ',
    'EGA 320x200x16      ', 'EGA 640x200x16      ',
    'EGA 640x350x2       ', 'EGA 640x350x16      ',
    'VGA 640x480x2       ', 'VGA 640x480x16      ',
    'VGA 320x200x256     ', 'Hercules 720x348x2  ',
    'Tseng 800x600x16    ', 'Tseng 640x350x256   ',
    'Tseng 640x480x256   ', 'Tseng 800x600x256   ',
    'Paradise 800x600x16 ', 'Paradise 800x600x2  ',
    'Paradise 640x400x256', 'Paradise 640x480x256',
    'Video7 800x600x16   ', 'Video7 640x400x256  ',
    'Video7 640x480x256  ', 'Video7 800x600x256  ');
var
  PcxSelectedDisplay: Integer;
  PcxGraphicsModeState: Integer;
  PcxDisplayPageState: Integer;
  PcxModeCheckPolicy: Word;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedPcxModeStorageSam1: array[0..151] of Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedPcxModeStorageLater: array[0..151] of Byte;
{$ENDIF}
  PcxDefaultReadBuffer: array[0..PcxReadWorkBufferCapacity - 1] of Byte;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedPcxReadStorageSam1: array[0..9] of Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedPcxReadStorageLater: array[0..9] of Byte;
{$ENDIF}
  PcxReadState: TPcxReadState;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedPcxReadPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedPcxReadPadLater: Byte;
{$ENDIF}
  PcxPrinterScanline: array[0..PcxPrinterScanlineBytes - 1] of Byte;
  PcxPrintedSourceRow: Word;
  PcxPrinterDeviceClass: Word;
  PcxPrinterResolutionClass: Word;
  PcxDisplayTable: array[0..PcxDisplayCount - 1] of TPcxDisplayInfo;
  PcxHerculesGraphicsCrtc: array[0..PcxHerculesCrtcRegisterCount - 1] of Byte;
  PcxHerculesTextCrtc: array[0..PcxHerculesCrtcRegisterCount - 1] of Byte;
  PcxPrinterState: TPcxPrinterState;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedPcxPrinterPadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedPcxPrinterPadLater: Byte;
{$ENDIF}
  JoystickActive: Boolean;
{$IFDEF SAM1}
  { Unused storage retains DATA layout. }
  UnusedJoystickStatePadSam1: Byte;
{$ELSE}
  { Unused storage retains DATA layout. }
  UnusedJoystickStatePadLater: Byte;
{$ENDIF}
function PcxSetDisplayType(DisplayIndex: Word): Integer;
function PcxSetGraphicsOrTextMode(GraphicsEnabled: Word): Integer;
function PcxGetDisplayType: Integer;
function PcxGetDisplayDescriptor(DisplayIndex: Word): PPcxDisplayInfo;
procedure PcxInitializeVideoDescriptors;
function PcxDisplayBuffer(PcxImageBuffer: Pointer; AvailableBufferBytes, ImageX, ImageY, VideoPage: Word): Integer;
procedure PcxInitializeDisplayDispatch;
function PcxDisplayFile(ImageFileName: String; ImageX, ImageY, VideoPage: Word):
  Integer;
function PcxBeginPrinterImage(SourceRowBytes, PrinterX, PrinterY: Word): Integer;
procedure PcxEndPrinterImage;
function PcxFormatUnsignedDecimal(UnsignedValue: LongInt; DigitBuffer: Pointer): Word;
procedure PcxInitializePrinterState;
implementation
uses Dos, PROGRPHX, Crt, SAMSOUND, GAMEJOY;

{ Display configuration and PCX image loading. }
{$L GENUS.OBJ}
{ Accepts display indices 0..21; returns 0, or -6 for an invalid index. }
function PcxSetDisplayType; external;
{ GraphicsEnabled must be 0 or 1. Uses the selected descriptor's BIOS mode,
  with a direct CRTC path for Hercules; returns a toolkit status code. }
function PcxSetGraphicsOrTextMode; external;
{ Returns the selected display type. }
function PcxGetDisplayType; external;
{ Returns the descriptor for a display index. }
function PcxGetDisplayDescriptor; external;
{ Fills all 22 mode descriptors, Hercules CRTC tables, and work-buffer state. }
procedure PcxInitializeVideoDescriptors; external;
{ Checks the PCX header and selected mode, then dispatches to an adapter's
  RLE decoder at the requested position/page; returns a toolkit status code. }
function PcxDisplayBuffer; external;
{ Selects decoding routines for the current display. }
procedure PcxInitializeDisplayDispatch; external;
{ Converts the Pascal filename to a NUL-terminated DOS name, opens and reads
  the file into the configured work buffer, displays it, then closes it. }
function PcxDisplayFile; external;

{ Printer raster output and decimal formatting. }
{ Sets printer image position and row size, then sends raster setup commands. }
function PcxBeginPrinterImage; external;
{ Ends printer raster output. }
procedure PcxEndPrinterImage; external;
{ Treats all 32 bits as unsigned, writes decimal digits to DigitBuffer,
  appends a dollar-sign terminator, and returns the digit count.
  The public LongInt signature is original. }
function PcxFormatUnsignedDecimal; external;
{ Installs the default printer commands and scaling. }
procedure PcxInitializePrinterState; external;
begin
  PcxInitializeVideoDescriptors;
  PcxInitializePrinterState;
end.
