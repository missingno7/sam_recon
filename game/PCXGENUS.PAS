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
  reserved_21e8: array[0..151] of Byte;
{$ELSE}
  reserved_220e: array[0..151] of Byte;
{$ENDIF}
  PcxDefaultReadBuffer: array[0..2047] of Byte;
{$IFDEF SAM1}
  reserved_2a80: array[0..9] of Byte;
{$ELSE}
  reserved_2aa6: array[0..9] of Byte;
{$ENDIF}
  PcxReadState: TPcxReadState;
{$IFDEF SAM1}
  reserved_2a9b: Byte;
{$ELSE}
  reserved_2ac1: Byte;
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
  reserved_341b: Byte;
{$ELSE}
  reserved_3441: Byte;
{$ENDIF}
  JoystickActive: Boolean;
{$IFDEF SAM1}
  reserved_341d: Byte;
{$ELSE}
  reserved_3443: Byte;
{$ENDIF}
function PcxSetDisplayType(DisplayIndex: Word): Integer;
function PcxSetGraphicsOrTextMode(GraphicsEnabled: Word): Integer;
function PcxGetDisplayType: Integer;
function PcxGetDisplayDescriptor(PcxGetDisplayDescr_DisplayIndex: Word): PPcxDisplayInfo;
procedure PcxInitializeVideoDescriptors;
function PcxDisplayBuffer(PcxImageBuffer: Pointer; AvailableBufferBytes, ImageX, ImageY, VideoPage: Word): Integer;
procedure PcxInitializeDisplayDispatch;
function PcxDisplayFile(ImageFileName: String; PcxDisplayFile_ImageX, PcxDisplayFile_ImageY, PcxDisplayFile_VideoPage: Word):
  Integer;
function PcxBeginPrinterImage(SourceRowBytes, PrinterX, PrinterY: Word): Integer;
procedure PcxEndPrinterImage;
function PcxFormatUnsignedDecimal(UnsignedValue: LongInt; DigitBuffer: Pointer): Word;
procedure PcxInitializePrinterState;
implementation
uses Dos, PROGRPHX, Crt, SAMSOUND, GAMEJOY;
{$L GENUS.OBJ}
{ src/asm/u5.asm u5_000f: pcx set display type. }
function PcxSetDisplayType; external;
{ src/asm/u5.asm u5_0047: pcx set graphics or text mode. }
function PcxSetGraphicsOrTextMode; external;
{ src/asm/u5.asm u5_00eb: pcx get display type. }
function PcxGetDisplayType; external;
{ src/asm/u5.asm u5_01ac: pcx get display descriptor. }
function PcxGetDisplayDescriptor; external;
{ src/asm/u5.asm u5_026b: pcx initialize video descriptors. }
procedure PcxInitializeVideoDescriptors; external;
{ src/asm/u5.asm u5_0d2d: pcx display buffer. }
function PcxDisplayBuffer; external;
{ src/asm/u5.asm u5_0dc7: pcx initialize display dispatch. }
procedure PcxInitializeDisplayDispatch; external;
{ Converts a Pascal filename, opens/reads/closes it with DOS INT 21h. }
function PcxDisplayFile; external;
{ src/asm/u5.asm u5_1ac6: pcx begin printer image. }
function PcxBeginPrinterImage; external;
{ src/asm/u5.asm u5_1bf7: pcx end printer image. }
procedure PcxEndPrinterImage; external;
{ src/asm/u5.asm u5_2020: pcx format unsigned decimal. }
function PcxFormatUnsignedDecimal; external;
{ src/asm/u5.asm u5_20a2: pcx initialize printer state. }
procedure PcxInitializePrinterState; external;
begin
  PcxInitializeVideoDescriptors;
  PcxInitializePrinterState;
end.
