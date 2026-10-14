unit U8;
{$A+}{$D+}{$L+}{$F-}
interface
uses Dos, U9;
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
type
  TGenusDisplayDescriptions = array[0..21] of string[20];
type
  TGenusDisplay = packed record
    DisplayType: Byte;                  
    Description: string[20];            
    BIOSMode, BitsPerPixel: Byte;       
    Width, Height: Word;                
    HorizontalScale, VerticalScale: Byte;  
    VideoSegment, PageBytes, DeviceClass: Word;  
    DecodeContinuation: Pointer;        
    Reserved: array[0..7] of Word;       
  end;
type
  PGenusDisplay = ^TGenusDisplay;
type
  TGenusWorkState = packed record
    BufferSize, BufferSegment, BufferOffset: Word;
    FileHandle: Integer;
    FilePositionHigh, FilePositionLow: Word;
    DisplayDispatchReady: Byte;
    AdapterFlags: array[0..3] of Byte;
  end;
type
  TGenusPrinterState = packed record
    Port, Scale, FormFeed, ResetPrinter, ScanlineBytes: Word;
    AlternateScanline: Byte;
    ResetCommand: string[2];            
    CopiesCommand: string[5];           
    OrientationCommand: string[5];      
    MarginCommand: string[7];           
    FormFeedCommand: string[5];         
    PositionCommand: string[13];        
    Resolution100: string[7];           
    Resolution150: string[7];           
    Resolution300: string[7];           
    BeginRasterCommand: string[5];      
    EndRasterCommand: string[4];        
    ScanlineCommand: string[15];        
    DecimalDivisors: array[0..9] of LongInt;  
  end;
type
  t_p_0ef2_tconfigfile = file of TConfig;
type
  t_p_0f75_tconfigfile = file of TConfig;
type
{$IFDEF SAM1}
{$ELSE}
  t_p_sam2_107a_tregisterblock = record
    case Integer of
      0: (AX, BX, CX, DX, BP, SI, DI, DS, ES, Flags: Word);
      1: (AL, AH, BL, BH, CL, CH, DL, DH: Byte);
  end;
type
{$ENDIF}
  t_u2_0000_tmapcell = record
    A, B, C: Word;
    D, E: Byte;
  end;
type
  t_u2_2530_tmapcell = record
    A, B, C: Word;
    D, E: Byte;
  end;
type
  t_u2_a1ae_tlevelfile = file of TLevelRow;
  t_u2_a1ae_tlevelfileviews = record
    case Byte of
      0: (Raw: File);
      1: (Typed: t_u2_a1ae_tlevelfile);
  end;
{$IFDEF SAM1}
type
  t_u3_0000_pbyte = ^Byte;
  t_u3_0000_ppointer = ^Pointer;
{$ENDIF}
type
  t_u3_1601_tname = String[40];
  t_u3_1601_tnamerecord = packed record
    Name: t_u3_1601_tname;
  end;
  t_u3_1601_tbytearray38 = array[37..32767] of Byte;
  t_u3_1601_pbytearray38 = ^t_u3_1601_tbytearray38;
type
  t_u3_26cf_thelpline = string[40];
type
  t_u3_3712_pbyte = ^Byte;
type
  t_u3_38ae_tbigfile = file of TSpriteBank;
  t_u3_38ae_tsmallfile = file of TGlyphBank;
  t_u3_38ae_tbigfileviews = record
    case Byte of
      0: (Raw: File);
      1: (Typed: t_u3_38ae_tbigfile);
  end;
  t_u3_38ae_tsmallfileviews = record
    case Byte of
      0: (Raw: File);
      1: (Typed: t_u3_38ae_tsmallfile);
  end;
type
  t_u3_3e29_tsavefile = file of TSaveData;
type
  t_u3_3f8c_tsavefile = file of TSaveData;
type
  t_u3_4e64_thelpline = string[40];
type
  t_u3_6ea9_thelpline = string[40];
  t_u3_6ea9_tlevelrow = array[1..42] of Char;
type
  t_u3_7c17_tlevelrow = array[1..42] of Char;
type
  t_u3_848e_tstr40 = string[40];
type
  t_u3_8ea3_tstr40 = string[40];
type
  t_u3_8fb6_trec41 = packed record
    S: string[40];
  end;
type
  t_u3_9163_trec41 = packed record
    S: string[40];
  end;
type
  t_u3_9340_tmenutext = array[1..299] of String[40];
type
  t_u3_97bb_tstring40 = string[40];
type
  t_u3_9b3e_tstr40 = packed record
    Value: string[40];
  end;
  t_u3_9b3e_tbuffer = packed record
    case Byte of
      0: (Wide: string[255]);
      1: (Narrow: string[40]);
  end;
type
  t_u3_9bdf_ttextpair = packed record
    first: string[40];
    second: string[40];
  end;
type
  t_u3_9ca9_tmenutext = array[1..6] of String[40];
type
  t_u3_9de0_trec41 = packed record
    S: String[40];
  end;
type
  t_u3_a1d8_ttextpair = packed record
    first: string[40];
    second: string[40];
  end;
type
  t_u3_cf40_tmenulines = array[1..299] of String[40];
type
  t_u3_d323_tmenuline = String[40];
type
  t_u3_d645_tmessageslot = packed record
    S: String[40];
  end;
type
  t_u3_d820_tmenutext = array[1..6] of String[40];
const
  t_u3_dbc2_border = #176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176#176;
var
  d_34B0: array[1..19] of Byte;
{$IFDEF SAM1}
  reserved_34c3: Byte;
{$ELSE}
  reserved_34e9: Byte;
{$ENDIF}
  d_34C4: array[1..38] of Byte;
  d_34ea: byte;
  d_34EB: Byte;
  d_34EC: array[1..25] of TActor;
  d_380c: integer;
  d_380e: integer;
  d_3810: integer;
  d_3812: array[1..299] of string[40];
{$IFDEF SAM1}
  reserved_67f5: Byte;
{$ELSE}
  reserved_681b: Byte;
{$ENDIF}
  d_67F6: PWindowBuffer;
  d_67FA: array[1..20] of Byte;
{$IFDEF SAM1}
  reserved_680e: array[0..5] of Byte;
{$ELSE}
  reserved_6834: array[0..5] of Byte;
{$ENDIF}
  d_6814: Word;
  d_6816: byte;
{$IFDEF SAM1}
  reserved_6817: Byte;
{$ELSE}
  reserved_683d: Byte;
{$ENDIF}
  d_6818: integer;
  d_681a: word;
  d_681C: Integer;
  d_681e: word;
  d_6820: Integer;
  d_6822: integer;
  d_6824: Integer;
  d_6826: integer;
  d_6828: integer;
  d_682A: Integer;
  d_682C: Integer;
  d_682E: Integer;
  d_6830: Integer;
  d_6832: Integer;
  d_6834: Integer;
  d_6836: byte;
{$IFDEF SAM1}
  reserved_6837: Byte;
{$ELSE}
  reserved_685d: Byte;
{$ENDIF}
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
{$IFDEF SAM1}
  reserved_69b1: Byte;
{$ELSE}
  reserved_69d7: Byte;
{$ENDIF}
  d_69B2: Integer;
  d_69b4: byte;
{$IFDEF SAM1}
  reserved_69b5: Byte;
{$ELSE}
  reserved_69db: Byte;
{$ENDIF}
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
{$IFDEF SAM1}
  reserved_69e1: Byte;
{$ELSE}
  reserved_6a07: Byte;
{$ENDIF}
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
{$IFDEF SAM1}
  reserved_69f7: Byte;
{$ELSE}
  reserved_6a1d: Byte;
{$ENDIF}
  d_69F8: array[1..35] of Integer;
  d_6a3e: byte;
  d_6a3f: byte;
  d_6a40: byte;
  d_6a41: byte;
  d_6a42: byte;
{$IFDEF SAM1}
  reserved_6a43: Byte;
{$ELSE}
  reserved_6a69: Byte;
{$ENDIF}
  d_6A44: string;
  d_6B44: TConfig;
{$IFDEF SAM1}
  reserved_6d17: Byte;
{$ELSE}
  reserved_6d3d: Byte;
{$ENDIF}
  d_6D18: TSaveData;
  d_6D60: Integer;
  d_6d62: integer;
  d_6d64: integer;
  d_6d66: byte;
{$IFDEF SAM1}
  reserved_6d67: Byte;
{$ELSE}
  reserved_6d8d: Byte;
{$ENDIF}
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
  d_6DB2: t_u3_38ae_tbigfileviews;
  d_6E32: PGlyphBank;
  d_6E36: PGlyphBank;
  d_6E3A: PGlyphBank;
  d_6E3E: t_u3_38ae_tsmallfileviews;
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
  d_6ECC: Byte;
  d_6ecd: byte;
  d_6ece: string[80];
{$IFDEF SAM1}
  reserved_6f1f: Byte;
{$ELSE}
  reserved_6f45: Byte;
{$ENDIF}
  d_6f20: string[80];
{$IFDEF SAM1}
  reserved_6f71: Byte;
{$ELSE}
  reserved_6f97: Byte;
{$ENDIF}
  d_6f72: string[80];
{$IFDEF SAM1}
  reserved_6fc3: Byte;
{$ELSE}
  reserved_6fe9: Byte;
{$ENDIF}
  d_6fc4: string[80];
{$IFDEF SAM1}
  reserved_7015: Byte;
{$ELSE}
  reserved_703b: Byte;
{$ENDIF}
  d_7016: string[80];
{$IFDEF SAM1}
  reserved_7067: Byte;
{$ELSE}
  reserved_708d: Byte;
{$ENDIF}
  d_7068: string[80];
{$IFDEF SAM1}
  reserved_70b9: Byte;
{$ELSE}
  reserved_70df: Byte;
{$ENDIF}
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
{$IFDEF SAM1}
  reserved_70d6: array[0..3] of Byte;
{$ELSE}
  reserved_70fc: array[0..3] of Byte;
{$ENDIF}
procedure u8_0136;
procedure u8_07d5;
procedure u8_0a89;
procedure u8_0c14(var Data; Count: Word);
implementation
uses Crt;
{$L DECODE.OBJ}
procedure u8_0c14; external;
{$F+}
procedure u8_0136;
var
  i: Integer;
  value: LongInt;
begin
  for i := 1 to 25 do
    d_34EC[i].Inactive := 1;
  d_6838 := 0;
  u9_2f32;
  d_6832 := -1;
  d_683A := 0;
  d_682C := 0;
  d_70C6 := 0;
  d_70C8 := 0;
  d_70BA := $48;
  d_70BC := $50;
  d_70BE := $4B;
  d_70C0 := $4D;
  d_70C2 := $38;
  d_70C4 := $1D;
  for i := 1 to 10 do
  begin
    case i of
      1: d_6B44.Names[i] := 'James Bond              200000';
      2: d_6B44.Names[i] := 'Matt Helm               190000';
      3: d_6B44.Names[i] := 'Flint                   180000';
      4: d_6B44.Names[i] := 'Jack Ryan               170000';
      5: d_6B44.Names[i] := 'Jim Phelps              160000';
      6: d_6B44.Names[i] := 'Columbo                 150000';
      7: d_6B44.Names[i] := 'Maxwell Smart           140000';
      8: d_6B44.Names[i] := 'Frank Drebin            130000';
      9: d_6B44.Names[i] := 'Underdog                120000';
      10: d_6B44.Names[i] := 'The A Team              110000';
    end;
    value := i;
    d_6B44.Scores[i] := 200000 - (value - 1) * 10000;
  end;
  d_6EBF := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6EC5 := 0;
  d_6EC6 := 0;
  d_6EC7 := 0;
  d_6EC8 := 0;
  d_6EC9 := 0;
  d_6EC2 := 0;
  d_6EC1 := 0;
  d_6ECD := 0;
  d_6EC0 := 0;
  d_681C := 1;
  d_6830 := 0;
  d_6840 := $10;
  d_683E := 0;
  d_683C := 0;
  d_6820 := 0;
  d_6836 := 1;
  d_699A := 0;
  d_699E := 1;
  d_6858 := 5;
  d_69A2 := 1;
  d_69A0 := 0;
  for i := 1 to 15 do
    d_6844[i] := 0;
  d_69A4 := 0;
  d_69A6 := 0;
  d_69A8 := 0;
  d_69AD := 0;
  d_69AA := 0;
  d_69AC := 0;
  d_69B0 := 0;
  d_69AE := 0;
  d_69B2 := 0;
  d_69EF := 0;
  d_69EC := 0;
  d_69ED := 0;
  d_69E8 := 0;
  d_69E9 := 0;
  d_69EA := 0;
  d_69EB := 0;
  d_69F3 := 0;
  d_69F4 := 0;
  d_69EE := 0;
  d_69B4 := 0;
  d_69B6 := 0;
  d_69B8 := 1;
  d_69F0 := 0;
  d_69F1 := 0;
  d_69F2 := 1;
  for i := 1 to 20 do
    d_69BA[i] := 0;
  d_69F5 := 0;
  d_69F6 := $23;
  d_6A3E := 0;
  d_6A3F := 8;
  d_6A40 := 3;
  d_6A41 := 0;
  d_6A42 := 0;
  d_69CE := 0;
  d_6816 := 0;
  d_69D4 := 0;
  d_69D5 := 0;
  d_69D6 := 0;
  d_69D9 := 0;
  d_69DA := 0;
  d_69DB := 0;
  d_69DC := 0;
  d_69DD := 0;
  d_69DE := 0;
  d_69DF := 0;
  d_69CF := 0;
  d_69D0 := 0;
  d_69D1 := 0;
  d_69D2 := 0;
  d_69D3 := 0;
  d_69D7 := 0;
  d_69D8 := 0;
  d_69E0 := 0;
  d_69E2 := 0;
  d_69E4 := 0;
  d_69E6 := 0;
  d_6D18.X := 0;
  d_6D18.Y := 0;
  d_6D18.Score := d_699A;
  d_6D18.Count := d_699E;
  d_6D18.Ammo := d_6858;
  for i := 1 to 20 do
    d_6D18.FlagsA[i] := d_6844[i];
  d_6D18.TimerA := d_69A4;
  d_6D18.TimerB := d_69A6;
  d_6D18.Mode := d_69AD;
  d_6D18.TimerC := d_69AA;
  d_6D18.FlagA := d_69AC;
  d_6D18.FlagB := d_69B0;
  d_6D18.TimerD := d_69AE;
  d_6D18.ValueA := d_69B2;
  d_6D18.ValueB := d_69B6;
  d_6D18.ValueC := d_69B8;
  for i := 1 to 20 do
    d_6D18.FlagsB[i] := d_69BA[i];
  d_6D60 := 0;
  d_34B0[1] := 0;
  d_34B0[2] := 8;
  d_34B0[3] := 8;
  d_34B0[4] := 8;
  d_34B0[5] := 4;
  d_34B0[6] := 4;
  d_34B0[7] := 2;
  d_34B0[8] := 2;
  d_34B0[9] := 2;
  d_34B0[10] := 1;
  d_34B0[11] := 1;
  d_34B0[12] := 2;
  d_34B0[13] := 2;
  d_34B0[14] := 2;
  d_34B0[15] := 4;
  d_34B0[16] := 4;
  d_34B0[17] := 8;
  d_34B0[18] := 8;
  d_34B0[19] := 8;
  d_34EA := $12;
  d_34C4[1] := 0;
  d_34C4[2] := 8;
  d_34C4[3] := 8;
  d_34C4[4] := 6;
  d_34C4[5] := 6;
  d_34C4[6] := 4;
  d_34C4[7] := 4;
  d_34C4[8] := 4;
  d_34C4[9] := 4;
  d_34C4[10] := 4;
  d_34C4[11] := 4;
  d_34C4[12] := 2;
  d_34C4[13] := 2;
  d_34C4[14] := 2;
  d_34C4[15] := 2;
  d_34C4[16] := 2;
  d_34C4[17] := 1;
  d_34C4[18] := 1;
  d_34C4[19] := 1;
  d_34C4[20] := 1;
  d_34C4[21] := 0;
  d_34C4[22] := 0;
  d_34C4[23] := 0;
  d_34C4[24] := 2;
  d_34C4[25] := 2;
  d_34C4[26] := 2;
  d_34C4[27] := 2;
  d_34C4[28] := 4;
  d_34C4[29] := 4;
  d_34C4[30] := 4;
  d_34C4[31] := 4;
  d_34C4[32] := 4;
  d_34C4[33] := 4;
  d_34C4[34] := 4;
  d_34C4[35] := 6;
  d_34C4[36] := 6;
  d_34C4[37] := 8;
  d_34C4[38] := 8;
  d_34EB := $25;
  d_69F8[1] := -8;
  d_69F8[2] := -8;
  d_69F8[3] := -8;
  d_69F8[4] := -8;
  d_69F8[5] := -8;
  d_69F8[6] := -8;
  d_69F8[7] := -8;
  d_69F8[8] := -8;
  d_69F8[9] := -8;
  d_69F8[10] := -8;
  d_69F8[11] := -8;
  d_69F8[12] := -8;
  d_69F8[13] := -8;
  d_69F8[14] := -8;
  d_69F8[15] := -8;
  d_69F8[16] := -6;
  d_69F8[17] := -6;
  d_69F8[18] := -6;
  d_69F8[19] := -6;
  d_69F8[20] := -6;
  d_69F8[21] := -6;
  d_69F8[22] := -4;
  d_69F8[23] := -4;
  d_69F8[24] := -4;
  d_69F8[25] := -4;
  d_69F8[26] := 0;
  d_69F8[27] := 0;
  d_69F8[28] := 0;
  d_69F8[29] := 4;
  d_69F8[30] := 4;
  d_69F8[31] := 8;
  d_69F8[32] := 8;
  d_69F8[33] := 8;
  d_69F8[34] := 8;
  d_69F8[35] := 8;
  d_6D66 := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u8_07d5;
var
  i: Integer;
begin
  d_6D66 := 0;
  for i := 1 to 25 do
    d_34EC[i].Inactive := 1;
  d_6838 := 0;
  u9_2f32;
  d_6832 := -1;
  d_683A := 0;
  d_682C := 0;
  d_6EBF := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6EC5 := 0;
  d_6EC6 := 0;
  d_6EC7 := 0;
  d_6EC8 := 0;
  d_6EC9 := 0;
  d_6EC2 := 0;
  d_6EC1 := 0;
  d_6ECD := 0;
  d_6EC0 := 0;
  d_681C := 1;
  d_6830 := 0;
  d_6840 := $10;
  d_683E := 0;
  d_683C := 0;
  d_6820 := 0;
  d_6836 := 1;
  d_699A := 0;
  d_699E := 1;
  d_6858 := 5;
  d_69A2 := 1;
  d_69A0 := 0;
  for i := 1 to 15 do
    d_6844[i] := 0;
  d_69A4 := 0;
  d_69A6 := 0;
  d_69A8 := 0;
  d_69AD := 0;
  d_69AA := 0;
  d_69AC := 0;
  d_69B0 := 0;
  d_69AE := 0;
  d_69B2 := 0;
  d_69EF := 0;
  d_69EC := 0;
  d_69ED := 0;
  d_69E8 := 0;
  d_69E9 := 0;
  d_69EA := 0;
  d_69EB := 0;
  d_69F3 := 0;
  d_69F4 := 0;
  d_69EE := 0;
  d_69B4 := 0;
  d_69B6 := 0;
  d_69B8 := 1;
  d_69F0 := 0;
  d_69F1 := 0;
  d_69F2 := 1;
  for i := 1 to 20 do
    d_69BA[i] := 0;
  d_69F5 := 0;
  d_69F6 := $23;
  d_69CE := 0;
  d_6A3E := 0;
  d_6A3F := 8;
  d_6A40 := 3;
  d_6A41 := 0;
  d_6A42 := 0;
  d_6816 := 0;
  d_69D4 := 0;
  d_69D5 := 0;
  d_69D6 := 0;
  d_69D9 := 0;
  d_69DA := 0;
  d_69DB := 0;
  d_69DC := 0;
  d_69DD := 0;
  d_69DE := 0;
  d_69DF := 0;
  d_69CF := 0;
  d_69D0 := 0;
  d_69D1 := 0;
  d_69D2 := 0;
  d_69D3 := 0;
  d_69D7 := 0;
  d_69D8 := 0;
  d_69E0 := 0;
  d_69E2 := 0;
  d_69E4 := 0;
  d_69E6 := 0;
  d_6D18.X := 0;
  d_6D18.Y := 0;
  d_6D18.Score := d_699A;
  d_6D18.Count := d_699E;
  d_6D18.Ammo := d_6858;
  for i := 1 to 20 do
    d_6D18.FlagsA[i] := d_6844[i];
  d_6D18.TimerA := d_69A4;
  d_6D18.TimerB := d_69A6;
  d_6D18.Mode := d_69AD;
  d_6D18.TimerC := d_69AA;
  d_6D18.FlagA := d_69AC;
  d_6D18.FlagB := d_69B0;
  d_6D18.TimerD := d_69AE;
  d_6D18.ValueA := d_69B2;
  d_6D18.ValueB := d_69B6;
  d_6D18.ValueC := d_69B8;
  for i := 1 to 20 do
    d_6D18.FlagsB[i] := d_69BA[i];
  d_6D18.FlagC := d_69DC;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
procedure u8_0a89;
var
  FrameWord: Word;
begin
  d_6D66 := 0;
  u9_0625(0);
  u9_07ee(0, 80, 0, 8);
  u9_2f32;
  d_6832 := -1;
  d_6EBF := 0;
  d_6ECA := 0;
  d_6ECB := 0;
  d_6EC3 := 0;
  d_6EC4 := 0;
  d_6EC5 := 0;
  d_6EC6 := 0;
  d_6EC7 := 0;
  d_6EC8 := 0;
  d_6EC9 := 0;
  d_6EC2 := 0;
  d_6EC1 := 0;
  d_6ECD := 0;
  d_6EC0 := 0;
  d_6830 := 0;
  d_6820 := 0;
  d_69EF := 0;
  d_69EC := 0;
  d_69ED := 0;
  d_69E8 := 0;
  d_69E9 := 0;
  d_69EA := 0;
  d_69EB := 0;
  d_69F4 := 0;
  d_69EE := 0;
  d_69B4 := 0;
  d_69F0 := 0;
  d_69F1 := 0;
  d_69F2 := 1;
  d_69A4 := 0;
  d_69A6 := 0;
  d_69A8 := 0;
  d_69AD := 0;
  d_69AA := 0;
  d_69AC := 0;
  d_69B0 := 0;
  d_69AE := 0;
  d_6816 := 0;
  d_6A3E := 0;
  d_6A3F := 8;
  d_6A40 := 3;
  d_6A41 := 0;
  d_6A42 := 0;
  d_69F5 := 0;
  d_69F6 := $23;
  d_69CE := 0;
  d_69D4 := 0;
  d_69D5 := 0;
  d_69D6 := 0;
  d_69D9 := 0;
  d_69DA := 0;
  d_69DB := 0;
  d_69DC := 0;
  d_69DD := 0;
  d_69DE := 0;
  d_69DF := 0;
  d_69CF := 0;
  d_69D0 := 0;
  d_69D1 := 0;
  d_69D2 := 0;
  d_69D3 := 0;
  d_69D7 := 0;
  d_69D8 := 0;
  d_69E0 := 0;
  d_69E2 := 0;
  d_69E4 := 0;
  d_69E6 := 0;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
begin
end.
