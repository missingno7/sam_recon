{ Proposed by sol-consolidate; see notes.md for decisions and proofs. }
{@types}
type
  TLevelRow = array[1..42] of Char;
type
  TActor = record
    State, X, Y, OldX, OldY, Frame, Tick, Limit, Aux1, Aux2,
    Sprite, DX, DY, Speed, Kind: Integer;
    Inactive, Marked: Byte;
  end;
type
  TCell = record
    Tile, Overlay, Aux: Word;
    Solid, Special: Byte;
  end;
type
  TConfig = packed record
    Names: array[1..10] of string[40];
    Scores: array[1..10] of LongInt;
    OldMode: Byte;
    Old70BA, Old70BC, Old70BE, Old70C0, Old70C4, Old70C2,
    Old70C6, Old70C8: Word;
  end;
type
  TSaveData = packed record
    X, Y: Integer;
    Score: LongInt;
    Count, Ammo, ProjectileCount: Integer;
    FlagsA: array[1..20] of Byte;
    TimerA, TimerB: Integer;
    Mode: Byte;
    TimerC: Integer;
    FlagA, FlagB: Byte;
    TimerD, ValueA, ValueB, ValueC: Integer;
    FlagsB: array[1..20] of Byte;
    FlagC: Byte;
  end;
type
  TMusicTable = array[1..12, 1..305] of Integer;
type
  PMusicTable = ^TMusicTable;
type
  TWindowBuffer = array[0..29999] of Byte;
type
  PWindowBuffer = ^TWindowBuffer;
type
  TSprite16 = packed record Header: array[1..3] of Byte; Pixels: array[1..157] of Byte; end;
type
  TSpriteBank = packed record Images: array[1..50] of TSprite16; Tail: array[1..64] of Byte; end;
type
  PSpriteBank = ^TSpriteBank;
type
  TGlyph8 = packed record Header: array[1..3] of Byte; Pixels: array[1..37] of Byte; end;
type
  TGlyphBank = packed record Glyphs: array[1..50] of TGlyph8; Tail: array[1..48] of Byte; end;
type
  PGlyphBank = ^TGlyphBank;
type
  TByteArray = array[0..32767] of Byte;
type
  PByteArray = ^TByteArray;
type
  TGenusIdentity = packed record
    Product: array[0..31] of Char;
    Copyright: array[0..51] of Char;
    Rights: array[0..21] of Char;
    Author: array[0..23] of Char;
    EMSDriver: array[0..7] of Char;
  end;
  TGenusDisplayDescriptions = array[0..21] of string[20];
  TGenusDisplay = packed record
    DisplayType: Byte;                 { +00 }
    Description: string[20];           { +01, populated by GetDisplayInformation }
    BIOSMode, BitsPerPixel: Byte;      { +16, +17 }
    Width, Height: Word;               { +18, +1A }
    HorizontalScale, VerticalScale: Byte; { +1C, +1D }
    VideoSegment, PageBytes, DeviceClass: Word; { +1E, +20, +22 }
    DecodeContinuation: Pointer;       { +24, far jump target, not a Pascal call }
    Reserved: array[0..7] of Word;      { +28..+37, initialized to zero by U5 }
  end;
  PGenusDisplay = ^TGenusDisplay;
  TGenusWorkState = packed record
    BufferSize, BufferSegment, BufferOffset: Word;
    FileHandle: Integer;
    FilePositionHigh, FilePositionLow: Word;
    DisplayDispatchReady: Byte;
    AdapterFlags: array[0..3] of Byte;
  end;
  TGenusPrinterState = packed record
    Port, Scale, FormFeed, ResetPrinter, ScanlineBytes: Word;
    AlternateScanline: Byte;
    ResetCommand: string[2];           { +0B, DS:3395, ESC E }
    CopiesCommand: string[5];          { +0E, ESC &l1X }
    OrientationCommand: string[5];     { +14, ESC &l0O }
    MarginCommand: string[7];          { +1A, ESC &l2E ESC 9 }
    FormFeedCommand: string[5];        { +22, ESC &l0H }
    PositionCommand: string[13];       { +28, ESC *p then decimal X/Y }
    Resolution100: string[7];          { +36, ESC *t100R }
    Resolution150: string[7];          { +3E, ESC *t150R }
    Resolution300: string[7];          { +46, ESC *t300R }
    BeginRasterCommand: string[5];     { +4E, ESC *r1A }
    EndRasterCommand: string[4];       { +54, ESC *rB }
    ScanlineCommand: string[15];       { +59, ESC *b then decimal byte count }
    DecimalDivisors: array[0..9] of LongInt; { +69, 10^9 down to 1 }
  end;
{@globals}
var
  d_0294: array[0..1] of byte;
  d_0296: array[1..40, 1..25] of TCell;
  d_21d6: word;
  d_21d8: byte;
  d_21da: longint;
  d_341C: Boolean;
  d_341E: PMusicTable;
  d_3422: PMusicTable;
  d_3426: PMusicTable;
  d_34aa: integer;
  d_34ac: integer;
  d_34ae: byte;
  d_34af: byte;
  d_34B0: array[1..19] of Byte;
  d_34C4: array[1..38] of Byte;
  d_34ea: byte;
  d_34EC: array[1..25] of TActor;
  d_380c: integer;
  d_380e: integer;
  d_3810: integer;
  d_3812: array[1..299] of string[40];
  d_67F6: PWindowBuffer;
  d_67FA: array[1..20] of Byte;
  d_6814: Word;
  d_6816: byte;
  d_6818: integer;
  d_681a: word;
  d_681C: Integer;
  d_681e: word;
  d_6820: Integer;
  d_6822: integer;
  d_6824: Integer;
  d_6826: integer;
  d_6828: integer;
  d_682C: Integer;
  d_682E: Integer;
  d_6830: Integer;
  d_6832: Integer;
  d_6834: Integer;
  d_6836: byte;
  d_6838: Integer;
  d_683A: Integer;
  d_683C: Integer;
  d_683E: Integer;
  d_6840: Integer;
  d_6842: byte;
  d_6843: byte;
  d_6844: array[1..20] of Byte;
  d_6858: Integer;
  d_685A: array[1..10] of TActor;
  d_699A: LongInt;
  d_699E: Integer;
  d_69A0: Integer;
  d_69A2: Integer;
  d_69A4: Integer;
  d_69A6: Integer;
  d_69A8: Integer;
  d_69AA: Integer;
  d_69ac: byte;
  d_69ad: byte;
  d_69AE: Integer;
  d_69b0: byte;
  d_69B2: Integer;
  d_69b4: byte;
  d_69B6: Integer;
  d_69B8: Integer;
  d_69BA: array[1..20] of Byte;
  d_69ce: byte;
  d_69cf: byte;
  d_69d0: byte;
  d_69d1: byte;
  d_69d2: byte;
  d_69d3: byte;
  d_69d4: byte;
  d_69d5: byte;
  d_69d6: byte;
  d_69d7: byte;
  d_69d8: byte;
  d_69d9: byte;
  d_69da: byte;
  d_69db: byte;
  d_69dc: byte;
  d_69dd: byte;
  d_69de: byte;
  d_69df: byte;
  d_69e0: byte;
  d_69E2: Integer;
  d_69E4: Integer;
  d_69E6: Integer;
  d_69e8: byte;
  d_69e9: byte;
  d_69ea: byte;
  d_69eb: byte;
  d_69ec: byte;
  d_69ed: byte;
  d_69ee: byte;
  d_69ef: byte;
  d_69f0: byte;
  d_69f1: byte;
  d_69f2: byte;
  d_69f3: byte;
  d_69f4: byte;
  d_69f5: byte;
  d_69f6: byte;
  d_69F8: array[1..35] of Integer;
  d_6a3e: byte;
  d_6a3f: byte;
  d_6a40: byte;
  d_6a41: byte;
  d_6a42: byte;
  d_6A44: string;
  d_6B44: TConfig;
  d_6D18: TSaveData;
  d_6D60: Integer;
  d_6d62: integer;
  d_6d64: integer;
  d_6d66: byte;
  d_6D68: Integer;
  d_6D6A: Integer;
  d_6d6c: integer;
  d_6d6e: integer;
  d_6d70: byte;
  d_6d71: byte;
  d_6D72: PSpriteBank;
  d_6D76: PSpriteBank;
  d_6D7A: PSpriteBank;
  d_6D7E: PSpriteBank;
  d_6D82: PSpriteBank;
  d_6D86: PSpriteBank;
  d_6D8A: PSpriteBank;
  d_6D8E: PSpriteBank;
  d_6D92: PSpriteBank;
  d_6D96: PSpriteBank;
  d_6D9A: PSpriteBank;
  d_6D9E: PSpriteBank;
  d_6DA2: PSpriteBank;
  d_6DA6: PSpriteBank;
  d_6DAA: PSpriteBank;
  d_6DAE: PSpriteBank;
  d_6E32: PGlyphBank;
  d_6E36: PGlyphBank;
  d_6E3A: PGlyphBank;
  d_6ebe: byte;
  d_6ebf: byte;
  d_6ec0: byte;
  d_6ec1: byte;
  d_6ec2: byte;
  d_6ec3: byte;
  d_6ec4: byte;
  d_6ec5: byte;
  d_6ec6: byte;
  d_6ec7: byte;
  d_6ec8: byte;
  d_6ec9: byte;
  d_6eca: byte;
  d_6ecb: byte;
  d_6ecd: byte;
  d_6ece: string[80];
  d_6f20: string[80];
  d_6f72: string[80];
  d_6fc4: string[80];
  d_7016: string[80];
  d_7068: string[80];
  d_70ba: word;
  d_70bc: word;
  d_70be: word;
  d_70c0: word;
  d_70c2: word;
  d_70c4: word;
  d_70c6: word;
  d_70c8: word;
  d_70ca: pointer;
  d_70ce: pointer;
  d_70d2: pointer;
  d_7140: string[80];
const
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
  d_21E0: Integer;                     { selected display; -1 before selection }
  d_21E2: Integer;                     { graphics/text state; initially -1 }
  d_21E4: Integer;                     { display page state; initially -1 }
  d_21E6: Word;                        { mode-change policy }
  d_2280: array[0..2047] of Byte;       { default PCX file-read buffer }
  d_2A8A: TGenusWorkState;
  d_2A9C: array[0..1023] of Byte;       { printer scanline, in-place resampling }
  d_2E9C: Word;                        { current printed source row }
  d_2E9E: Word;                        { selected printer/device class }
  d_2EA0: Word;                        { raster resolution class }
  d_2EA2: array[0..21] of TGenusDisplay; { 22 records, 38h bytes per record }
  d_3372: array[0..11] of Byte;         { Hercules graphics CRTC registers }
  d_337E: array[0..11] of Byte;         { Hercules text CRTC registers }
  d_338A: TGenusPrinterState;           { strings and divisors filled by U5_20A2 }
{@routines}
procedure p_0000;
procedure p_08a2;
procedure p_0be5;
procedure p_0e33;
procedure p_0e67;
procedure p_0ec2;
procedure p_0ef2;
procedure p_0f75;
procedure p_sam2_107a;
function u1_0000(Distance, Item: Integer): Boolean;
function u1_008d(margin: Integer; slot: Word): Boolean;
procedure u1_011a;
procedure u1_012d;
procedure u1_01c4(x, y: Integer);
function u1_027c(X, Y: Integer): Boolean;
procedure u1_03f0(param1, param2: Integer; param3: Word);
procedure u1_0584(X, Y, TypeCode, Value, EntryId: Integer);
procedure u1_0837(X, Y: Integer; Item: Word; I, J: Word);
procedure u1_2f6b;
function u1_65d9(xOffset, yOffset: Word): Boolean;
procedure u1_66b3;
procedure u1_68f5;
procedure u1_6a0e;
procedure u1_6d0e(X, Y: Integer);
procedure u1_86df;
procedure u2_0000(X, Y: Integer);
procedure u2_1185(X, Y: Integer);
procedure u2_2530(X, Y: Integer);
procedure u2_2c6e(X, Y, Tile, A, B: Integer; C, D, Foreground: Byte);
procedure u2_2e88(X, Y: Integer; Symbol: String);
procedure u2_3a91(X, Y: Integer; Symbol: String; Foreground: Byte);
procedure u2_68a9(rowIndex: Integer; row: TLevelRow);
procedure u2_a1ae(Level: Integer);
function u3_0000: Char;
procedure u3_007c;
procedure u3_00a3;
procedure u3_00db(ticks: Word);
procedure u3_0232(Ticks: Word);
procedure u3_0261;
procedure u3_079e;
procedure u3_0892(X, Y: Integer; Text: string);
function u3_1601(mode: Byte): Byte;
function u3_1e2a(MaxInput: Integer): String;
function u3_26cf(Mode: Byte): Byte;
procedure u3_344c;
procedure u3_3505;
procedure u3_3712;
procedure u3_38ae;
procedure u3_3c93;
procedure u3_3cb8;
procedure u3_3d6b;
procedure u3_3e29(slot: Integer);
function u3_3f8c(Slot: Integer): Boolean;
procedure u3_4e64;
procedure u3_6ea9;
procedure u3_7c17;
procedure u3_848e;
procedure u3_87fd(Arg: Word);
procedure u3_892b;
function u3_8ea3: Word;
procedure u3_8fb6;
function u3_9163: Integer;
function u3_9340: Char;
function u3_97bb: Char;
procedure u3_9a71;
procedure u3_9b3e(input: string);
procedure u3_9bdf;
procedure u3_9ca9;
procedure u3_9de0;
procedure u3_a027;
procedure u3_a1d8;
procedure u3_a3b6;
function u3_a6f6(key: Word): string;
procedure u3_acdd;
procedure u3_af56;
procedure u3_b4d6;
procedure u3_b898;
procedure u3_c10d;
procedure u3_cf40;
procedure u3_d323;
procedure u3_d645;
procedure u3_d820;
procedure u3_dbc2;
procedure u3_ddd2;
function u4_0000(A, B: Byte): Byte;
function u4_0045(Count: Byte; Ch: Char): string;
procedure u4_0097(X1, Y1, X2, Y2, Fore, Back: Integer);
procedure u4_0101(A, B, C, D, E, F, G: Integer);
procedure u4_0309(A, B, C, D, E, F, G: Integer);
procedure u4_0349(A, B, C: Word; Text: string);
procedure u4_0399(x: Word; y: Integer; fg, bg: Word; source: String);
procedure u4_045e;
procedure u4_04bf(X, Y, Attr: Byte; Text: string);
function u4_0557: Byte;
function u4_05c3: Byte;
function u5_000f(N: Word): Integer;
function u5_0047(N: Word): Integer;
function u5_1915(P: String; A, B, C: Word): Integer;
function u6_0000: Boolean;
function u6_0038: Boolean;
function u6_0058: Boolean;
function u6_00cc(Axis: Word): Integer;
procedure u7_0000(N: Integer);
procedure u8_0136;
procedure u8_07d5;
procedure u8_0a89;
function u9_01d3(N: Word): Integer;
procedure u9_01f9(A, B: Word);
procedure u9_024c(A, B: Word);
procedure u9_0625(Value: Word);
procedure u9_07ee(A, B, C, D: Word);
procedure u9_19f9(var Source; X, Y: Integer);
procedure u9_2f32;
function u5_00eb: Integer;
function u5_01ac(DisplayType: Word): PGenusDisplay;
function u5_0d2d(Image: Pointer; BufferBytes, X, Y, Page: Word): Integer;
procedure u5_0dc7;
function u5_1ac6(Width, X, Y: Word): Integer;
procedure u5_1bf7;
function u5_2020(Value: LongInt; Digits: Pointer): Word;
procedure u9_02db;
