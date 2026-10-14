{ Pascal interface to Genus PCX Programmer's Toolkit 3.56.
  Provides PCX display, video-descriptor and printer routines from GENUS.OBJ. }
unit PCXGENUS;
{$A+}{$D+}{$L+}{$F-}
interface
uses SAMDATA;
const
{$IFDEF SAM1}
{$ELSE}
  BiosAdapterClassMap: array[0..13] of Byte = (5, 0, 1, 5, 3, 3, 5, 4, 4, 5, 1, 1, 1, 0);
{$ENDIF}
  GenusPcxIdentity: TPcxIdentity =
    (PcxIdentityProduct: ' PCX Programmer''s Toolkit 3.56 '#0
    ;PcxIdentityCopyright: ' Copyright (c) Genus Microprogramming, Inc. 1988-89'#0
    ;PcxIdentityRights: ' All Rights Reserved.'#0
    ;PcxIdentityAuthor: ' Christopher A. Howard '#0
    ;PcxIdentityEmsDriverName: 'EMMXXXX'#0);
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
  PcxDefaultReadBuffer: array[0..2047] of Byte;
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
  PcxPrinterScanline: array[0..1023] of Byte;
  PcxPrintedSourceRow: Word;
  PcxPrinterDeviceClass: Word;
  PcxPrinterResolutionClass: Word;
  PcxDisplayTable: array[0..21] of TPcxDisplayInfo;
  PcxHerculesGraphicsCrtc: array[0..11] of Byte;
  PcxHerculesTextCrtc: array[0..11] of Byte;
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
{ Selects the toolkit display type. }
function PcxSetDisplayType; external;
{ Switches the selected display between graphics and text modes. }
function PcxSetGraphicsOrTextMode; external;
{ Returns the selected display type. }
function PcxGetDisplayType; external;
{ Returns the descriptor for a display index. }
function PcxGetDisplayDescriptor; external;
{ Initializes the toolkit video descriptors. }
procedure PcxInitializeVideoDescriptors; external;
{ Decodes a PCX buffer at the requested position and video page. }
function PcxDisplayBuffer; external;
{ Selects decoding routines for the current display. }
procedure PcxInitializeDisplayDispatch; external;
{ Converts a Pascal filename, opens/reads/closes it with DOS INT 21h. }
function PcxDisplayFile; external;

{ Printer raster output and decimal formatting. }
{ Starts a printer raster image. }
function PcxBeginPrinterImage; external;
{ Ends printer raster output. }
procedure PcxEndPrinterImage; external;
{ Formats an unsigned value into decimal digits. }
function PcxFormatUnsignedDecimal; external;
{ Installs the default printer commands and scaling. }
procedure PcxInitializePrinterState; external;
begin
  PcxInitializeVideoDescriptors;
  PcxInitializePrinterState;
end.
