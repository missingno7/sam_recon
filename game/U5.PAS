unit U5;
{$A+}{$D+}{$L+}{$F-}
interface
uses U8;
const
{$IFDEF SAM1}
{$ELSE}
  d_sam2_0000: array[0..13] of Byte = (5, 0, 1, 5, 3, 3, 5, 4, 4, 5, 1, 1, 1, 0);
{$ENDIF}
  d_0000: TGenusIdentity =
    (Product: ' PCX Programmer''s Toolkit 3.56 '#0
    ;Copyright: ' Copyright (c) Genus Microprogramming, Inc. 1988-89'#0
    ;Rights: ' All Rights Reserved.'#0
    ;Author: ' Christopher A. Howard '#0
    ;EMSDriver: 'EMMXXXX'#0);
  d_008A: TGenusDisplayDescriptions = (
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
  d_21E0: Integer;
  d_21E2: Integer;
  d_21E4: Integer;
  d_21E6: Word;
{$IFDEF SAM1}
  reserved_21e8: array[0..151] of Byte;
{$ELSE}
  reserved_220e: array[0..151] of Byte;
{$ENDIF}
  d_2280: array[0..2047] of Byte;
{$IFDEF SAM1}
  reserved_2a80: array[0..9] of Byte;
{$ELSE}
  reserved_2aa6: array[0..9] of Byte;
{$ENDIF}
  d_2A8A: TGenusWorkState;
{$IFDEF SAM1}
  reserved_2a9b: Byte;
{$ELSE}
  reserved_2ac1: Byte;
{$ENDIF}
  d_2A9C: array[0..1023] of Byte;
  d_2E9C: Word;
  d_2E9E: Word;
  d_2EA0: Word;
  d_2EA2: array[0..21] of TGenusDisplay;
  d_3372: array[0..11] of Byte;
  d_337E: array[0..11] of Byte;
  d_338A: TGenusPrinterState;
{$IFDEF SAM1}
  reserved_341b: Byte;
{$ELSE}
  reserved_3441: Byte;
{$ENDIF}
  d_341C: Boolean;
{$IFDEF SAM1}
  reserved_341d: Byte;
{$ELSE}
  reserved_3443: Byte;
{$ENDIF}
function u5_000f(N: Word): Integer;
function u5_0047(N: Word): Integer;
function u5_00eb: Integer;
function u5_01ac(DisplayType: Word): PGenusDisplay;
procedure u5_026b;
function u5_0d2d(Image: Pointer; BufferBytes, X, Y, Page: Word): Integer;
procedure u5_0dc7;
function u5_1915(P: String; A, B, C: Word): Integer;
function u5_1ac6(Width, X, Y: Word): Integer;
procedure u5_1bf7;
function u5_2020(Value: LongInt; Digits: Pointer): Word;
procedure u5_20a2;
implementation
uses Dos, U9, Crt, U7, U6;
{$L GENUS.OBJ}
function u5_000f; external;
function u5_0047; external;
function u5_00eb; external;
function u5_01ac; external;
procedure u5_026b; external;
function u5_0d2d; external;
procedure u5_0dc7; external;
function u5_1915; external;
function u5_1ac6; external;
procedure u5_1bf7; external;
function u5_2020; external;
procedure u5_20a2; external;
begin
  u5_026b;
  u5_20a2;
end.
