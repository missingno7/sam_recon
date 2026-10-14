{@decls}
type
  TBigChunk = array[0..$1F7F] of Byte;
  PBigChunk = ^TBigChunk;
  TSmallChunk = array[0..$07FF] of Byte;
  PSmallChunk = ^TSmallChunk;
  TBigFile = file of TBigChunk;
  TSmallFile = file of TSmallChunk;
  TBigFileViews = record
    case Byte of
      0: (Raw: File);
      1: (Typed: TBigFile);
  end;
  TSmallFileViews = record
    case Byte of
      0: (Raw: File);
      1: (Typed: TSmallFile);
  end;
var
  d_6D72, d_6D76, d_6D7A, d_6D7E, d_6D82, d_6D86, d_6D8A, d_6D8E,
  d_6D92, d_6D96, d_6D9A, d_6D9E, d_6DA2, d_6DA6, d_6DAA, d_6DAE: PBigChunk;
  d_6E32, d_6E36, d_6E3A: PSmallChunk;
  d_6DB2: TBigFileViews;
  d_6E3E: TSmallFileViews;
{@stubs}
procedure u8_0c14(var Buffer; Size: Word);
{@body}
procedure u3_38ae;
begin
{$IFDEF SAM1}
  Assign(d_6DB2.Raw, 'SAM101.GFX');
{$ENDIF}
{$IFDEF SAM2}
  Assign(d_6DB2.Raw, 'SAM201.GFX');
{$ENDIF}
{$IFDEF SAM3}
  Assign(d_6DB2.Raw, 'SAM301.GFX');
{$ENDIF}
  Reset(d_6DB2.Raw, $1F80);
  GetMem(d_6DA6, $1F80);
  Read(d_6DB2.Typed, d_6DA6^);
  u8_0c14(d_6DA6^, $1F80);
  GetMem(d_6D72, $1F80);
  Read(d_6DB2.Typed, d_6D72^);
  u8_0c14(d_6D72^, $1F80);
  GetMem(d_6D76, $1F80);
  Read(d_6DB2.Typed, d_6D76^);
  u8_0c14(d_6D76^, $1F80);
  GetMem(d_6D7E, $1F80);
  Read(d_6DB2.Typed, d_6D7E^);
  u8_0c14(d_6D7E^, $1F80);
  GetMem(d_6D82, $1F80);
  Read(d_6DB2.Typed, d_6D82^);
  u8_0c14(d_6D82^, $1F80);
  GetMem(d_6D86, $1F80);
  Read(d_6DB2.Typed, d_6D86^);
  u8_0c14(d_6D86^, $1F80);
  GetMem(d_6D8A, $1F80);
  Read(d_6DB2.Typed, d_6D8A^);
  u8_0c14(d_6D8A^, $1F80);
  GetMem(d_6D8E, $1F80);
  Read(d_6DB2.Typed, d_6D8E^);
  u8_0c14(d_6D8E^, $1F80);
  GetMem(d_6D92, $1F80);
  Read(d_6DB2.Typed, d_6D92^);
  u8_0c14(d_6D92^, $1F80);
  GetMem(d_6DA2, $1F80);
  Read(d_6DB2.Typed, d_6DA2^);
  u8_0c14(d_6DA2^, $1F80);
  GetMem(d_6D96, $1F80);
  Read(d_6DB2.Typed, d_6D96^);
  u8_0c14(d_6D96^, $1F80);
  GetMem(d_6D9A, $1F80);
  Read(d_6DB2.Typed, d_6D9A^);
  u8_0c14(d_6D9A^, $1F80);
  GetMem(d_6D9E, $1F80);
  Read(d_6DB2.Typed, d_6D9E^);
  u8_0c14(d_6D9E^, $1F80);
  GetMem(d_6D7A, $1F80);
  Read(d_6DB2.Typed, d_6D7A^);
  u8_0c14(d_6D7A^, $1F80);
  GetMem(d_6DAE, $1F80);
  Read(d_6DB2.Typed, d_6DAE^);
  u8_0c14(d_6DAE^, $1F80);
  GetMem(d_6DAA, $1F80);
  Read(d_6DB2.Typed, d_6DAA^);
  u8_0c14(d_6DAA^, $1F80);
  Close(d_6DB2.Raw);
{$IFDEF SAM1}
  Assign(d_6E3E.Raw, 'SAM102.GFX');
{$ENDIF}
{$IFDEF SAM2}
  Assign(d_6E3E.Raw, 'SAM202.GFX');
{$ENDIF}
{$IFDEF SAM3}
  Assign(d_6E3E.Raw, 'SAM302.GFX');
{$ENDIF}
  Reset(d_6E3E.Raw, $0800);
  GetMem(d_6E36, $0800);
  Read(d_6E3E.Typed, d_6E36^);
  u8_0c14(d_6E36^, $0800);
  GetMem(d_6E3A, $0800);
  Read(d_6E3E.Typed, d_6E3A^);
  u8_0c14(d_6E3A^, $0800);
  GetMem(d_6E32, $0800);
  Read(d_6E3E.Typed, d_6E32^);
  u8_0c14(d_6E32^, $0800);
  Close(d_6E3E.Raw);
end;
