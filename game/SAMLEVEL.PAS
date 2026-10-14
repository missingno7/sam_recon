unit SAMLEVEL;
{$A+}{$D+}{$L+}{$F-}
interface
uses SAMDATA;
var
  LevelCells: array[1..40, 1..25] of TLevelCell;
procedure RedrawLevelCell(WorldX, WorldY: Integer);
procedure DrawLevelCellResolved(DrawLevelCellResolved_WorldX, DrawLevelCellResolved_WorldY: Integer);
procedure DrawCellForeground(DrawCellForeground_WorldX, DrawCellForeground_WorldY: Integer);
procedure SetAndDrawLevelCell(SetAndDrawLevelCell_TileColumn, SetAndDrawLevelCell_TileRow, SetAndDrawLevelCell_BaseTile,
  SetAndDrawLevelCell_MiddleTile, SetAndDrawLevelCell_FrontTile: Integer; SetAndDrawLevelC_BlocksMovement,
  SetAndDrawLevel_SupportsLanding, ForegroundOnly: Byte);
procedure DecodeIslandSymbol(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow: Integer; MapSymbol: String);
procedure SpawnActorFromMapSymbol(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow: Integer;
  SpawnActorFromMapSymb_MapSymbol: String; SpawnActorFromMa_ForegroundOnly: Byte);
procedure DecodeLevelRow(DecodeLevelRow_TileRow: Integer; EncodedRow: TLevelFileRow);
procedure LoadLevelMap(LevelNumber: Integer);
implementation
uses Dos, PROGRPHX, Crt, SAMSOUND, GAMEJOY, PCXGENUS, TEXT80, SAMUI;
{$F+}
{ Restores a cell's opaque base and masked middle/foreground layers at the selected playfield buffer offset. }
procedure RedrawLevelCell(WorldX, WorldY: Integer);
var
  TileColumn, TileRow, CellColumn, CellRow, VideoByteX, TilePixelY: Integer;
begin
  TileColumn := WorldX shr 4;
  TileRow := WorldY shr 4;
  if (TileColumn >= 0) and (TileColumn <= 39) and (TileRow >= 0) then
  begin
    CellColumn := (WorldX shr 4) + 1;
    CellRow := (WorldY shr 4) + 1;
    VideoByteX := TileColumn shl 1;
    TilePixelY := TileRow shl 4;
    case LevelCells[CellColumn, CellRow].CellBaseTile of
      0: ;
      1..8: PgCopyCachedVideoTile16x16(VideoByteX, TilePixelY + GameDrawBufferRow, LevelCells[CellColumn,
      CellRow].CellBaseTile - 1);
      9..50: PgBlitOpaque16x16(SpriteBank001^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile].SpriteDataBytes[1],
      VideoByteX, TilePixelY + GameDrawBufferRow);
      101: PgCopyCachedVideoTile16x16(VideoByteX, TilePixelY + GameDrawBufferRow, 4);
      100, 102..150: PgBlitOpaque16x16(SpriteBank101^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
      100].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      179:
        if GameDrawBufferRow = 16 then
          PgBlitOpaque16x16(SpriteBank151^.SpriteEntries[29].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow)
        else
          PgBlitOpaque16x16(SpriteBank151^.SpriteEntries[30].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      151..200: PgBlitOpaque16x16(SpriteBank151^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
      150].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      201..250: PgBlitOpaque16x16(SpriteBank201^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
      200].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      251..300: PgBlitOpaque16x16(SpriteBank251^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
      250].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      301..350: PgBlitOpaque16x16(SpriteBank301^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
      300].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      351..400: PgBlitOpaque16x16(SpriteBank351^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
      350].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      401..450: PgBlitOpaque16x16(SpriteBank401^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
      400].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      499:
        if GameDrawBufferRow = 16 then
          PgBlitOpaque16x16(SpriteBank451^.SpriteEntries[49].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow)
        else
          PgBlitOpaque16x16(SpriteBank451^.SpriteEntries[1].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      451..500: PgBlitOpaque16x16(SpriteBank451^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
      450].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      535:
        if GameDrawBufferRow = 16 then
          PgBlitOpaque16x16(SpriteBank001^.SpriteEntries[21].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow)
        else
          PgBlitOpaque16x16(SpriteBank001^.SpriteEntries[35].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      501..550: PgBlitOpaque16x16(SpriteBank001^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
      500].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      613:
        if GameDrawBufferRow = 16 then
          PgBlitOpaque16x16(SpriteBank601^.SpriteEntries[13].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl 4) +
          GameDrawBufferRow)
        else
          PgBlitOpaque16x16(SpriteBank601^.SpriteEntries[17].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl 4) +
          GameDrawBufferRow);
      601..650: PgBlitOpaque16x16(SpriteBank601^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
      600].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      651..700: PgBlitOpaque16x16(SpriteBank651^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
      650].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      701..750: PgBlitOpaque16x16(SpriteBank701^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
      700].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      751..800: PgBlitOpaque16x16(SpriteBank751^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
      750].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
    end;
    case LevelCells[CellColumn, CellRow].CellOverlayTile of
      0: ;
      1..50: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[CellColumn,
      CellRow].CellOverlayTile].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      100..150: PgBlitMasked16x16(SpriteBank101^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
      100].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      179:
        if GameDrawBufferRow = 16 then
          PgBlitMasked16x16(SpriteBank151^.SpriteEntries[29].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank151^.SpriteEntries[30].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      151..200: PgBlitMasked16x16(SpriteBank151^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
      150].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      201..250: PgBlitMasked16x16(SpriteBank201^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
      200].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      251..300: PgBlitMasked16x16(SpriteBank251^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
      250].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      301..350: PgBlitMasked16x16(SpriteBank301^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
      300].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      351..400: PgBlitMasked16x16(SpriteBank351^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
      350].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      401..450: PgBlitMasked16x16(SpriteBank401^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
      400].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      499:
        if GameDrawBufferRow = 16 then
          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[49].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[1].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      451..500: PgBlitMasked16x16(SpriteBank451^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
      450].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      501..550: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
      500].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      613:
        if GameDrawBufferRow = 16 then
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[13].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl 4) +
          GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[17].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl 4) +
          GameDrawBufferRow);
      601..650: PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
      600].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      651..700: PgBlitMasked16x16(SpriteBank651^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
      650].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      701..750: PgBlitMasked16x16(SpriteBank701^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
      700].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      751..800: PgBlitMasked16x16(SpriteBank751^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
      750].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
    end;
    case LevelCells[CellColumn, CellRow].CellObjectCode of
      0: ;
      1..50: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[CellColumn,
      CellRow].CellObjectCode].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      100..150: PgBlitMasked16x16(SpriteBank101^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
      100].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      179:
        if GameDrawBufferRow = 16 then
          PgBlitMasked16x16(SpriteBank151^.SpriteEntries[29].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank151^.SpriteEntries[30].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      151..200: PgBlitMasked16x16(SpriteBank151^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
      150].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      201..250: PgBlitMasked16x16(SpriteBank201^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
      200].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      251..300: PgBlitMasked16x16(SpriteBank251^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
      250].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      301..350: PgBlitMasked16x16(SpriteBank301^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
      300].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      351..400: PgBlitMasked16x16(SpriteBank351^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
      350].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      401..450: PgBlitMasked16x16(SpriteBank401^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
      400].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      499:
        if GameDrawBufferRow = 16 then
          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[49].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[1].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      451..500: PgBlitMasked16x16(SpriteBank451^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
      450].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      501..550: PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
      500].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      613:
        if GameDrawBufferRow = 16 then
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[13].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl 4) +
          GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[17].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl 4) +
          GameDrawBufferRow);
      601..602: PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
      600].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      603:
        if GameDrawBufferRow = 416 then
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          600].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      604..623: PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
      600].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      624:
        if GameDrawBufferRow = 416 then
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          600].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          582].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      625..650: PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
      600].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      651..700: PgBlitMasked16x16(SpriteBank651^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
      650].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      701..750: PgBlitMasked16x16(SpriteBank701^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
      700].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      751..800: PgBlitMasked16x16(SpriteBank751^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
      750].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Temporarily resolves generic tile codes 2/5/6/7/8 to the level backdrop. }
procedure DrawLevelCellResolved(DrawLevelCellResolved_WorldX, DrawLevelCellResolved_WorldY: Integer);
var
  DrawLevelCellResolve_TileColumn, DrawLevelCellResolved_TileRow: Integer;
begin
  DrawLevelCellResolve_TileColumn := DrawLevelCellResolved_WorldX shr 4;
  DrawLevelCellResolved_TileRow := DrawLevelCellResolved_WorldY shr 4;
  if LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile = 2 then
    LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile := LevelBackdropTile;
  if LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile = 5 then
    LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile := LevelBackdropTile + 1;
  if LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile = 6 then
    LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile := LevelBackdropTile + 2;
  if LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile = 7 then
    LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile := LevelBackdropTile + 3;
  if LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile = 8 then
    LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile := 667;
  case LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile of
    1..50:
      PgBlitOpaque16x16(SpriteBank001^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellBaseTile].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    100..150:
      PgBlitOpaque16x16(SpriteBank101^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellBaseTile - 100].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    179:
      if GameDrawBufferRow = 16 then
        PgBlitOpaque16x16(SpriteBank151^.SpriteEntries[29].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow)
      else
        PgBlitOpaque16x16(SpriteBank151^.SpriteEntries[30].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    151..200:
      PgBlitOpaque16x16(SpriteBank151^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellBaseTile - 150].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    201..250:
      PgBlitOpaque16x16(SpriteBank201^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellBaseTile - 200].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    251..300:
      PgBlitOpaque16x16(SpriteBank251^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellBaseTile - 250].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    301..350:
      PgBlitOpaque16x16(SpriteBank301^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellBaseTile - 300].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    351..400:
      PgBlitOpaque16x16(SpriteBank351^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellBaseTile - 350].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    401..450:
      PgBlitOpaque16x16(SpriteBank401^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellBaseTile - 400].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    499:
      if GameDrawBufferRow = 16 then
        PgBlitOpaque16x16(SpriteBank451^.SpriteEntries[49].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow)
      else
        PgBlitOpaque16x16(SpriteBank451^.SpriteEntries[1].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    451..500:
      PgBlitOpaque16x16(SpriteBank451^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellBaseTile - 450].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    501..550:
      PgBlitOpaque16x16(SpriteBank001^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellBaseTile - 500].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    613:
      if GameDrawBufferRow = 16 then
        PgBlitOpaque16x16(SpriteBank601^.SpriteEntries[13].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow)
      else
        PgBlitOpaque16x16(SpriteBank601^.SpriteEntries[17].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    601..650:
      PgBlitOpaque16x16(SpriteBank601^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellBaseTile - 600].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    651..700:
      PgBlitOpaque16x16(SpriteBank651^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellBaseTile - 650].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    701..750:
      PgBlitOpaque16x16(SpriteBank701^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellBaseTile - 700].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    751..800:
      PgBlitOpaque16x16(SpriteBank751^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellBaseTile - 750].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
  end;
  if LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile = LevelBackdropTile then
    LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile := 2;
  if LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile = LevelBackdropTile + 1
  then
    LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile := 5;
  if LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile = LevelBackdropTile + 2
  then
    LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile := 6;
  if LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile = LevelBackdropTile + 3
  then
    LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile := 7;
  if LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile = 667 then
    LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellBaseTile := 8;
  case LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellOverlayTile of
    0: ;
    1..50:
      PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellOverlayTile].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    100..150:
      PgBlitMasked16x16(SpriteBank101^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellOverlayTile - 100].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    179:
      if GameDrawBufferRow = 16 then
        PgBlitMasked16x16(SpriteBank151^.SpriteEntries[29].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow)
      else
        PgBlitMasked16x16(SpriteBank151^.SpriteEntries[30].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    151..200:
      PgBlitMasked16x16(SpriteBank151^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellOverlayTile - 150].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    201..250:
      PgBlitMasked16x16(SpriteBank201^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellOverlayTile - 200].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    251..300:
      PgBlitMasked16x16(SpriteBank251^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellOverlayTile - 250].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    301..350:
      PgBlitMasked16x16(SpriteBank301^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellOverlayTile - 300].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    351..400:
      PgBlitMasked16x16(SpriteBank351^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellOverlayTile - 350].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    401..450:
      PgBlitMasked16x16(SpriteBank401^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellOverlayTile - 400].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    499:
      if GameDrawBufferRow = 16 then
        PgBlitMasked16x16(SpriteBank451^.SpriteEntries[49].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow)
      else
        PgBlitMasked16x16(SpriteBank451^.SpriteEntries[1].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    451..500:
      PgBlitMasked16x16(SpriteBank451^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellOverlayTile - 450].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    501..550:
      PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellOverlayTile - 500].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    613:
      if GameDrawBufferRow = 16 then
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[13].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow)
      else
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[17].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    601..650:
      PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellOverlayTile - 600].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    651..700:
      PgBlitMasked16x16(SpriteBank651^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellOverlayTile - 650].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    701..750:
      PgBlitMasked16x16(SpriteBank701^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellOverlayTile - 700].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    751..800:
      PgBlitMasked16x16(SpriteBank751^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellOverlayTile - 750].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
  end;
  case LevelCells[DrawLevelCellResolve_TileColumn + 1, DrawLevelCellResolved_TileRow + 1].CellObjectCode of
    0: ;
    1..50:
      PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellObjectCode].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    100..150:
      PgBlitMasked16x16(SpriteBank101^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellObjectCode - 100].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    179:
      if GameDrawBufferRow = 16 then
        PgBlitMasked16x16(SpriteBank151^.SpriteEntries[29].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow)
      else
        PgBlitMasked16x16(SpriteBank151^.SpriteEntries[30].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    151..200:
      PgBlitMasked16x16(SpriteBank151^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellObjectCode - 150].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    201..250:
      PgBlitMasked16x16(SpriteBank201^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellObjectCode - 200].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    251..300:
      PgBlitMasked16x16(SpriteBank251^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellObjectCode - 250].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    301..350:
      PgBlitMasked16x16(SpriteBank301^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellObjectCode - 300].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    351..400:
      PgBlitMasked16x16(SpriteBank351^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellObjectCode - 350].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    401..450:
      PgBlitMasked16x16(SpriteBank401^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellObjectCode - 400].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    499:
      if GameDrawBufferRow = 16 then
        PgBlitMasked16x16(SpriteBank451^.SpriteEntries[49].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow)
      else
        PgBlitMasked16x16(SpriteBank451^.SpriteEntries[1].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    451..500:
      PgBlitMasked16x16(SpriteBank451^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellObjectCode - 450].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    501..550:
      PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellObjectCode - 500].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    613:
      if GameDrawBufferRow = 16 then
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[13].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow)
      else
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[17].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
        DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    601..650:
      PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellObjectCode - 600].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    651..700:
      PgBlitMasked16x16(SpriteBank651^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellObjectCode - 650].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    701..750:
      PgBlitMasked16x16(SpriteBank701^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellObjectCode - 700].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
    751..800:
      PgBlitMasked16x16(SpriteBank751^.SpriteEntries[LevelCells[DrawLevelCellResolve_TileColumn + 1,
      DrawLevelCellResolved_TileRow + 1].CellObjectCode - 750].SpriteDataBytes[1], DrawLevelCellResolve_TileColumn * 2,
      DrawLevelCellResolved_TileRow * 16 + GameDrawBufferRow);
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Blits only d_0296[].Aux with masked tile drawing; called after actor drawing for foreground occlusion. }
procedure DrawCellForeground(DrawCellForeground_WorldX, DrawCellForeground_WorldY: Integer);
var
  DrawCellForeground_TileColumn, DrawCellForeground_TileRow: Integer;
begin
  DrawCellForeground_TileColumn := DrawCellForeground_WorldX shr 4;
  DrawCellForeground_TileRow := DrawCellForeground_WorldY shr 4;
  if (DrawCellForeground_TileColumn >= 0) and (DrawCellForeground_TileColumn <= 39) and (DrawCellForeground_TileRow >= 0) then
  begin
    case LevelCells[DrawCellForeground_TileColumn + 1, DrawCellForeground_TileRow + 1].CellObjectCode of
      0: ;
      1..50:
        PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
        DrawCellForeground_TileRow + 1].CellObjectCode].SpriteDataBytes[1],
          DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      179:
        if GameDrawBufferRow = 16 then
          PgBlitMasked16x16(SpriteBank151^.SpriteEntries[29].SpriteDataBytes[1], DrawCellForeground_TileColumn shl 1,
          (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank151^.SpriteEntries[30].SpriteDataBytes[1], DrawCellForeground_TileColumn shl 1,
          (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      100..150:
        PgBlitMasked16x16(SpriteBank101^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
        DrawCellForeground_TileRow + 1].CellObjectCode - 100].SpriteDataBytes[1],
          DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      151..200:
        PgBlitMasked16x16(SpriteBank151^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
        DrawCellForeground_TileRow + 1].CellObjectCode - 150].SpriteDataBytes[1],
          DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      201..250:
        PgBlitMasked16x16(SpriteBank201^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
        DrawCellForeground_TileRow + 1].CellObjectCode - 200].SpriteDataBytes[1],
          DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      251..300:
        PgBlitMasked16x16(SpriteBank251^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
        DrawCellForeground_TileRow + 1].CellObjectCode - 250].SpriteDataBytes[1],
          DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      301..350:
        PgBlitMasked16x16(SpriteBank301^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
        DrawCellForeground_TileRow + 1].CellObjectCode - 300].SpriteDataBytes[1],
          DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      351..400:
        PgBlitMasked16x16(SpriteBank351^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
        DrawCellForeground_TileRow + 1].CellObjectCode - 350].SpriteDataBytes[1],
          DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      401..450:
        PgBlitMasked16x16(SpriteBank401^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
        DrawCellForeground_TileRow + 1].CellObjectCode - 400].SpriteDataBytes[1],
          DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      499:
        if GameDrawBufferRow = 16 then
          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[49].SpriteDataBytes[1], DrawCellForeground_TileColumn shl 1,
          (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[1].SpriteDataBytes[1], DrawCellForeground_TileColumn shl 1,
          (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      451..500:
        PgBlitMasked16x16(SpriteBank451^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
        DrawCellForeground_TileRow + 1].CellObjectCode - 450].SpriteDataBytes[1],
          DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      613:
        if GameDrawBufferRow = 16 then
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[13].SpriteDataBytes[1], DrawCellForeground_TileColumn shl 1,
          (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[17].SpriteDataBytes[1], DrawCellForeground_TileColumn shl 1,
          (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      601..602:
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
        DrawCellForeground_TileRow + 1].CellObjectCode - 600].SpriteDataBytes[1],
          DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      603:
        if GameDrawBufferRow = 416 then
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
          DrawCellForeground_TileRow + 1].CellObjectCode - 600].SpriteDataBytes[1],
            DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      604..623:
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
        DrawCellForeground_TileRow + 1].CellObjectCode - 600].SpriteDataBytes[1],
          DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      624:
        if GameDrawBufferRow = 416 then
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
          DrawCellForeground_TileRow + 1].CellObjectCode - 600].SpriteDataBytes[1],
            DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
          DrawCellForeground_TileRow + 1].CellObjectCode - 582].SpriteDataBytes[1],
            DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      625..650:
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
        DrawCellForeground_TileRow + 1].CellObjectCode - 600].SpriteDataBytes[1],
          DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      651..700:
        PgBlitMasked16x16(SpriteBank651^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
        DrawCellForeground_TileRow + 1].CellObjectCode - 650].SpriteDataBytes[1],
          DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      701..750:
        PgBlitMasked16x16(SpriteBank701^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
        DrawCellForeground_TileRow + 1].CellObjectCode - 700].SpriteDataBytes[1],
          DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
      751..800:
        PgBlitMasked16x16(SpriteBank751^.SpriteEntries[LevelCells[DrawCellForeground_TileColumn + 1,
        DrawCellForeground_TileRow + 1].CellObjectCode - 750].SpriteDataBytes[1],
          DrawCellForeground_TileColumn shl 1, (DrawCellForeground_TileRow shl 4) + GameDrawBufferRow);
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Writes cell layers/collision flags (or only foreground on overlay rows) and redraws both buffers at Y. }
procedure SetAndDrawLevelCell(SetAndDrawLevelCell_TileColumn, SetAndDrawLevelCell_TileRow, SetAndDrawLevelCell_BaseTile,
  SetAndDrawLevelCell_MiddleTile, SetAndDrawLevelCell_FrontTile: Integer; SetAndDrawLevelC_BlocksMovement,
  SetAndDrawLevel_SupportsLanding, ForegroundOnly: Byte);
begin
  if ForegroundOnly <> 0 then
  begin
    LevelCells[SetAndDrawLevelCell_TileColumn + 1, SetAndDrawLevelCell_TileRow + 1].CellObjectCode :=
    SetAndDrawLevelCell_FrontTile;
    GameDrawBufferRow := $0010;
    DrawCellForeground(SetAndDrawLevelCell_TileColumn shl 4, SetAndDrawLevelCell_TileRow shl 4);
    GameDrawBufferRow := $01A0;
    DrawCellForeground(SetAndDrawLevelCell_TileColumn shl 4, SetAndDrawLevelCell_TileRow shl 4);
    GameDrawBufferRow := $0010;
  end
  else
  begin
    LevelCells[SetAndDrawLevelCell_TileColumn + 1, SetAndDrawLevelCell_TileRow + 1].CellBaseTile :=
    SetAndDrawLevelCell_BaseTile;
    LevelCells[SetAndDrawLevelCell_TileColumn + 1, SetAndDrawLevelCell_TileRow + 1].CellOverlayTile :=
    SetAndDrawLevelCell_MiddleTile;
    LevelCells[SetAndDrawLevelCell_TileColumn + 1, SetAndDrawLevelCell_TileRow + 1].CellObjectCode :=
    SetAndDrawLevelCell_FrontTile;
    LevelCells[SetAndDrawLevelCell_TileColumn + 1, SetAndDrawLevelCell_TileRow + 1].CellSolidFlag :=
    SetAndDrawLevelC_BlocksMovement;
    LevelCells[SetAndDrawLevelCell_TileColumn + 1, SetAndDrawLevelCell_TileRow + 1].SupportsLanding :=
    SetAndDrawLevel_SupportsLanding;
    GameDrawBufferRow := $0010;
    if SetAndDrawLevelCell_TileRow = 24 then
      DrawLevelCellResolved(SetAndDrawLevelCell_TileColumn shl 4, SetAndDrawLevelCell_TileRow shl 4)
    else
      RedrawLevelCell(SetAndDrawLevelCell_TileColumn shl 4, SetAndDrawLevelCell_TileRow shl 4);
    DrawCellForeground(SetAndDrawLevelCell_TileColumn shl 4, SetAndDrawLevelCell_TileRow shl 4);
    GameDrawBufferRow := $01A0;
    if SetAndDrawLevelCell_TileRow = 24 then
      DrawLevelCellResolved(SetAndDrawLevelCell_TileColumn shl 4, SetAndDrawLevelCell_TileRow shl 4)
    else
      RedrawLevelCell(SetAndDrawLevelCell_TileColumn shl 4, SetAndDrawLevelCell_TileRow shl 4);
    DrawCellForeground(SetAndDrawLevelCell_TileColumn shl 4, SetAndDrawLevelCell_TileRow shl 4);
    GameDrawBufferRow := $0010;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ When level=1, translates island-map symbols, numbered entrances and completed-level graphics. }
procedure DecodeIslandSymbol(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow: Integer; MapSymbol: String);
var
  LevelIndex, CompletedLevelCount: Integer;
  DecodeIslandSymb_ForegroundOnly: Byte;
begin
  AllMissionsComplete := 0;
  DecodeIslandSymb_ForegroundOnly := 0;
  CompletedLevelCount := 0;
  for LevelIndex := 2 to 17 do
    if LevelCompletedFlags[LevelIndex] = 1 then Inc(CompletedLevelCount);
  if CompletedLevelCount = 15 then AllMissionsComplete := 1;
  if CurrentLevelNumber = 1 then
  begin
    if MapSymbol = 'A' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 501, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'B' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 502, 0, 0, 1, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'C' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 503, 0, 0, 1, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'D' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 504, 0, 0, 1, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'E' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 505, 0, 0, 1, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'F' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 506, 0, 0, 1, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'G' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 507, 0, 0, 1, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'H' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'I' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'J' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 661, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'K' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'L' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'M' then
    begin
      if LevelCompletedFlags[IslandEntranceIndex + 2] <> 0 then
        SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, IslandEntranceIndex + 2, 0, 517, 0, 0,
        DecodeIslandSymb_ForegroundOnly)
      else
        SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, IslandEntranceIndex + 2, 0, 513, 0, 0,
        DecodeIslandSymb_ForegroundOnly);
    end;
    if MapSymbol = 'N' then
    begin
      if LevelCompletedFlags[IslandEntranceIndex + 2] <> 0 then
        SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, IslandEntranceIndex + 2, 0, 518, 0, 0,
        DecodeIslandSymb_ForegroundOnly)
      else
        SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, IslandEntranceIndex + 2, 0, 514, 0, 0,
        DecodeIslandSymb_ForegroundOnly);
      Inc(IslandEntranceIndex);
    end;
    if MapSymbol = 'O' then
    begin
      if LevelCompletedFlags[IslandEntranceIndex + 2] <> 0 then
        SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, IslandEntranceIndex + 2, 0, 519, 0, 0,
        DecodeIslandSymb_ForegroundOnly)
      else
        SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, IslandEntranceIndex + 2, 0, 515, 0, 0,
        DecodeIslandSymb_ForegroundOnly);
      Inc(IslandEntranceIndex);
    end;
    if MapSymbol = 'P' then
    begin
      if LevelCompletedFlags[IslandEntranceIndex + 2] <> 0 then
        SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, IslandEntranceIndex + 2, 0, 520, 0, 0,
        DecodeIslandSymb_ForegroundOnly)
      else
        SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, IslandEntranceIndex + 2, 0, 516, 0, 0,
        DecodeIslandSymb_ForegroundOnly);
      Inc(IslandEntranceIndex);
    end;
    if MapSymbol = 'Q' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 517, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'R' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 518, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'S' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 519, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'T' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 520, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'U' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 521, 0, 0, 1, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'V' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 522, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'W' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 523, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'X' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 524, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = '0' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 525, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'Z' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 526, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'a' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 527, 0, 0, 1, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'b' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 528, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'c' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 529, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'd' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 530, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'e' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 531, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'f' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 532, 0, 0, 1, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'g' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 533, 0, 0, 1, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'h' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 534, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'i' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 535, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'j' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 536, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'k' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 537, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'l' then
    begin
      if AllMissionsComplete = 0 then
        SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 508, 0, 0, 1, 0,
        DecodeIslandSymb_ForegroundOnly)
      else
        SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 0, 0, 0, 0,
        DecodeIslandSymb_ForegroundOnly);
    end;
    if MapSymbol = 'm' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 0, 665, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'n' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 0, 666, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'o' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 671, 0, 0, 1,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'p' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 672, 0, 0, 1,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'q' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 673, 0, 0, 1,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'r' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 674, 0, 0, 1,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 's' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 683, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 't' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 0, 684, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'u' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 0, 685, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'v' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 0, 686, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'x' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 0, 688, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'y' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 0, 689, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'z' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 690, 0, 0, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'w' then
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, LevelBackdropTile, 0, 687, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    if MapSymbol = 'w' then
    begin
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow - 1, 2, 0, 179, 1, 0,
      DecodeIslandSymb_ForegroundOnly);
      SetAndDrawLevelCell(DecodeIslandSymbol_TileColumn, DecodeIslandSymbol_TileRow, 2, 0, 183, 0, 0,
      DecodeIslandSymb_ForegroundOnly);
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Maps selected encoded characters to initialized d_34EC actors with sprite, position, direction. }
procedure SpawnActorFromMapSymbol(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow: Integer;
  SpawnActorFromMapSymb_MapSymbol: String; SpawnActorFromMa_ForegroundOnly: Byte);
begin
  if SpawnActorFromMapSymb_MapSymbol = #174 then { 3ABC }
  begin { 3ABC }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 3ADC }
    Inc(LoadedActorCount); { 3ADF }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank851)^[1923], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 3B02 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank851)^[1923], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 3B26 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank851)^[1283], ((SpawnActorFromMapSym_TileColumn + 1) * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 3B4B }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank851)^[1283], ((SpawnActorFromMapSym_TileColumn + 1) * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 3B70 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 3B7F }
    GameActors[LoadedActorCount].ActorSpriteBase := 851; { 3B8B }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 3BA1 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 3BB5 }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 3BC9 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 3BDD }
    if Random(2) > 0 then { 3BEC }
    begin { 3BEC }
      GameActors[LoadedActorCount].ActorDirectionX := 1; { 3BF6 }
    end { 3BFC }
    else { 3BFC }
    begin { 3BFE }
      GameActors[LoadedActorCount].ActorDirectionX := -1; { 3C06 }
    end; { 3C0C }
    GameActors[LoadedActorCount].DirectionY := 0; { 3C16 }
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then { 3C27 }
    begin { 3C27 }
      GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 3C31 }
    end { 3C37 }
    else { 3C37 }
    begin { 3C39 }
      GameActors[LoadedActorCount].ActorAnimationCounter := 41; { 3C41 }
    end; { 3C47 }
    GameActors[LoadedActorCount].ActorMovementStep := 2; { 3C4F }
    GameActors[LoadedActorCount].ActorCounterA := 0; { 3C5F }
    GameActors[LoadedActorCount].ActorCounterB := 0; { 3C6D }
    GameActors[LoadedActorCount].ActorKindValue1 := 3; { 3C79 }
    GameActors[LoadedActorCount].ActorKindCode := 42; { 3C87 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 3C95 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 3CA2 }
  end; { 3CA7 }
  if SpawnActorFromMapSymb_MapSymbol = '8' then { 3CB7 }
  begin { 3CB7 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 3CD7 }
    Inc(LoadedActorCount); { 3CDA }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[3], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 3CFD }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[3], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 3D21 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 3D30 }
    GameActors[LoadedActorCount].ActorSpriteBase := 351; { 3D3C }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 3D52 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 3D66 }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 3D7A }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 3D8E }
    if Random(2) > 0 then { 3D9D }
    begin { 3D9D }
      GameActors[LoadedActorCount].ActorDirectionX := 1; { 3DA7 }
    end { 3DAD }
    else { 3DAD }
    begin { 3DAF }
      GameActors[LoadedActorCount].ActorDirectionX := -1; { 3DB7 }
    end; { 3DBD }
    GameActors[LoadedActorCount].DirectionY := 0; { 3DC7 }
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then { 3DD8 }
    begin { 3DD8 }
      GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 3DE2 }
    end { 3DE8 }
    else { 3DE8 }
    begin { 3DEA }
      GameActors[LoadedActorCount].ActorAnimationCounter := 21; { 3DF2 }
    end; { 3DF8 }
    GameActors[LoadedActorCount].ActorMovementStep := 1; { 3E00 }
    GameActors[LoadedActorCount].ActorCounterA := 0; { 3E10 }
    GameActors[LoadedActorCount].ActorCounterB := 0; { 3E1E }
    GameActors[LoadedActorCount].ActorKindCode := 1; { 3E2A }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 3E38 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 3E45 }
  end; { 3E4A }
  if SpawnActorFromMapSymb_MapSymbol = '9' then { 3E5A }
  begin { 3E5A }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 3E7A }
    Inc(LoadedActorCount); { 3E7D }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[1283], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 3EA0 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[1283], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 3EC4 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 3ED3 }
    GameActors[LoadedActorCount].ActorSpriteBase := 359; { 3EDF }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 3EF5 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 3F09 }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 3F1D }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 3F31 }
    if Random(2) > 0 then { 3F40 }
    begin { 3F40 }
      GameActors[LoadedActorCount].ActorDirectionX := 1; { 3F4A }
    end { 3F50 }
    else { 3F50 }
    begin { 3F52 }
      GameActors[LoadedActorCount].ActorDirectionX := -1; { 3F5A }
    end; { 3F60 }
    GameActors[LoadedActorCount].DirectionY := 0; { 3F6A }
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then { 3F7B }
    begin { 3F7B }
      GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 3F85 }
    end { 3F8B }
    else { 3F8B }
    begin { 3F8D }
      GameActors[LoadedActorCount].ActorAnimationCounter := 21; { 3F95 }
    end; { 3F9B }
    GameActors[LoadedActorCount].ActorMovementStep := 1; { 3FA3 }
    GameActors[LoadedActorCount].ActorCounterA := 0; { 3FB3 }
    GameActors[LoadedActorCount].ActorKindCode := 2; { 3FBF }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 3FCD }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 3FDA }
  end; { 3FDF }
  if SpawnActorFromMapSymb_MapSymbol = '0' then { 3FEF }
  begin { 3FEF }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 400F }
    Inc(LoadedActorCount); { 4012 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[2563], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 4035 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[2563], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 4059 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 4068 }
    GameActors[LoadedActorCount].ActorSpriteBase := 367; { 4074 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 408A }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 409E }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 40B2 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 40C6 }
    if Random(2) > 0 then { 40D5 }
    begin { 40D5 }
      GameActors[LoadedActorCount].ActorDirectionX := 1; { 40DF }
    end { 40E5 }
    else { 40E5 }
    begin { 40E7 }
      GameActors[LoadedActorCount].ActorDirectionX := -1; { 40EF }
    end; { 40F5 }
    GameActors[LoadedActorCount].DirectionY := 0; { 40FF }
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then { 4110 }
    begin { 4110 }
      GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 411A }
    end { 4120 }
    else { 4120 }
    begin { 4122 }
      GameActors[LoadedActorCount].ActorAnimationCounter := 21; { 412A }
    end; { 4130 }
    GameActors[LoadedActorCount].ActorMovementStep := 2; { 4138 }
    GameActors[LoadedActorCount].ActorCounterA := 0; { 4148 }
    GameActors[LoadedActorCount].ActorKindCode := 3; { 4154 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 4162 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 416F }
  end; { 4174 }
  if SpawnActorFromMapSymb_MapSymbol = 'g' then { 4184 }
  begin { 4184 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 41A4 }
    Inc(LoadedActorCount); { 41A7 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[3843], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 41CA }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[3843], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 41EE }
    GameActors[LoadedActorCount].FlashFrames := 0; { 41FD }
    GameActors[LoadedActorCount].ActorSpriteBase := 375; { 4209 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 421F }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 4233 }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 4247 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 425B }
    if Random(2) > 0 then { 426A }
    begin { 426A }
      GameActors[LoadedActorCount].ActorDirectionX := 1; { 4274 }
    end { 427A }
    else { 427A }
    begin { 427C }
      GameActors[LoadedActorCount].ActorDirectionX := -1; { 4284 }
    end; { 428A }
    GameActors[LoadedActorCount].DirectionY := 0; { 4294 }
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then { 42A5 }
    begin { 42A5 }
      GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 42AF }
    end { 42B5 }
    else { 42B5 }
    begin { 42B7 }
      GameActors[LoadedActorCount].ActorAnimationCounter := 21; { 42BF }
    end; { 42C5 }
    GameActors[LoadedActorCount].ActorMovementStep := 2; { 42CD }
    GameActors[LoadedActorCount].ActorCounterA := (Random(50) + 50); { 42E7 }
    GameActors[LoadedActorCount].ActorCounterB := 0; { 42F5 }
    GameActors[LoadedActorCount].ActorKindCode := 4; { 4301 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 430F }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 431C }
  end; { 4321 }
  if SpawnActorFromMapSymb_MapSymbol = 'G' then { 4331 }
  begin { 4331 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 4351 }
    Inc(LoadedActorCount); { 4354 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[5123], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 4377 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank351)^[5123], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 439B }
    GameActors[LoadedActorCount].FlashFrames := 0; { 43AA }
    GameActors[LoadedActorCount].ActorSpriteBase := 383; { 43B6 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 43CC }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 43E0 }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 43F4 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 4408 }
    if Random(2) > 0 then { 4417 }
    begin { 4417 }
      GameActors[LoadedActorCount].ActorDirectionX := 1; { 4421 }
    end { 4427 }
    else { 4427 }
    begin { 4429 }
      GameActors[LoadedActorCount].ActorDirectionX := -1; { 4431 }
    end; { 4437 }
    GameActors[LoadedActorCount].DirectionY := 0; { 4441 }
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then { 4452 }
    begin { 4452 }
      GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 445C }
    end { 4462 }
    else { 4462 }
    begin { 4464 }
      GameActors[LoadedActorCount].ActorAnimationCounter := 21; { 446C }
    end; { 4472 }
    GameActors[LoadedActorCount].ActorMovementStep := 2; { 447A }
    GameActors[LoadedActorCount].ActorCounterA := (Random(20) + 30); { 4494 }
    GameActors[LoadedActorCount].ActorCounterB := 0; { 44A2 }
    GameActors[LoadedActorCount].ActorKindCode := 5; { 44AE }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 44BC }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 44C9 }
  end; { 44CE }
  if SpawnActorFromMapSymb_MapSymbol = 'V' then { 44DE }
  begin { 44DE }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 44FE }
    Inc(LoadedActorCount); { 4501 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank801)^[3], (SpawnActorFromMapSym_TileColumn * 16),
    (((SpawnActorFromMapSymbol_TileRow * 16) + 16) - 16)); { 4527 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank801)^[3], (SpawnActorFromMapSym_TileColumn * 16),
    (((SpawnActorFromMapSymbol_TileRow * 16) + 416) - 16)); { 454E }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank801)^[643], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 4572 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank801)^[643], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 4596 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 45A5 }
    GameActors[LoadedActorCount].ActorSpriteBase := 801; { 45B1 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 45C7 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 45DB }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 45EF }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 4603 }
    if Random(2) > 0 then { 4612 }
    begin { 4612 }
      GameActors[LoadedActorCount].ActorDirectionX := 1; { 461C }
    end { 4622 }
    else { 4622 }
    begin { 4624 }
      GameActors[LoadedActorCount].ActorDirectionX := -1; { 462C }
    end; { 4632 }
    GameActors[LoadedActorCount].DirectionY := 0; { 463C }
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then { 464D }
    begin { 464D }
      GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 4657 }
    end { 465D }
    else { 465D }
    begin { 465F }
      GameActors[LoadedActorCount].ActorAnimationCounter := 41; { 4667 }
    end; { 466D }
    GameActors[LoadedActorCount].ActorMovementStep := 2; { 4675 }
    GameActors[LoadedActorCount].ActorCounterA := (Random(20) + 30); { 468F }
    GameActors[LoadedActorCount].ActorCounterB := 0; { 469D }
    GameActors[LoadedActorCount].ActorKindValue1 := 3; { 46A9 }
    GameActors[LoadedActorCount].ActorKindCode := 30; { 46B7 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 46C5 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 46D2 }
  end; { 46D7 }
  if SpawnActorFromMapSymb_MapSymbol = 'X' then { 46E7 }
  begin { 46E7 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 4707 }
    Inc(LoadedActorCount); { 470A }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank801)^[2563], (SpawnActorFromMapSym_TileColumn * 16),
    (((SpawnActorFromMapSymbol_TileRow * 16) + 16) - 16)); { 4730 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank801)^[2563], (SpawnActorFromMapSym_TileColumn * 16),
    (((SpawnActorFromMapSymbol_TileRow * 16) + 416) - 16)); { 4757 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank801)^[3203], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 477B }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank801)^[3203], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 479F }
    GameActors[LoadedActorCount].FlashFrames := 0; { 47AE }
    GameActors[LoadedActorCount].ActorSpriteBase := 817; { 47BA }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 47D0 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 47E4 }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 47F8 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 480C }
    if Random(2) > 0 then { 481B }
    begin { 481B }
      GameActors[LoadedActorCount].ActorDirectionX := 1; { 4825 }
    end { 482B }
    else { 482B }
    begin { 482D }
      GameActors[LoadedActorCount].ActorDirectionX := -1; { 4835 }
    end; { 483B }
    GameActors[LoadedActorCount].DirectionY := 0; { 4845 }
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then { 4856 }
    begin { 4856 }
      GameActors[LoadedActorCount].ActorAnimationCounter := 61; { 4860 }
    end { 4866 }
    else { 4866 }
    begin { 4868 }
      GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 4870 }
    end; { 4876 }
    GameActors[LoadedActorCount].ActorMovementStep := 2; { 487E }
    GameActors[LoadedActorCount].ActorCounterA := 60; { 488C }
    GameActors[LoadedActorCount].ActorCounterB := 0; { 489C }
    GameActors[LoadedActorCount].ActorKindValue1 := 3; { 48A8 }
    GameActors[LoadedActorCount].StateValueB := (Random(20) + 60); { 48C2 }
    GameActors[LoadedActorCount].ActorKindCode := 31; { 48CE }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 48DC }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 48E9 }
  end; { 48EE }
  if SpawnActorFromMapSymb_MapSymbol = '#' then { 48FE }
  begin { 48FE }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 491E }
    Inc(LoadedActorCount); { 4921 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 4944 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank151)^[3], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 4968 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 4977 }
    GameActors[LoadedActorCount].ActorSpriteBase := 151; { 4983 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 4999 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 49AD }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 49C1 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 49D5 }
    GameActors[LoadedActorCount].ActorDirectionX := 1; { 49E1 }
    GameActors[LoadedActorCount].DirectionY := 0; { 49F1 }
    GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 49FD }
    GameActors[LoadedActorCount].ActorMovementStep := 0; { 4A0D }
    GameActors[LoadedActorCount].ActorCounterA := 3; { 4A19 }
    GameActors[LoadedActorCount].ActorKindCode := 32; { 4A27 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 4A35 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 4A42 }
  end; { 4A47 }
  if SpawnActorFromMapSymb_MapSymbol = 'c' then { 4A57 }
  begin { 4A57 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 4A77 }
    Inc(LoadedActorCount); { 4A7A }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank801)^[6403], (SpawnActorFromMapSym_TileColumn * 16),
    (((SpawnActorFromMapSymbol_TileRow * 16) + 16) - 16)); { 4AA0 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank801)^[6403], (SpawnActorFromMapSym_TileColumn * 16),
    (((SpawnActorFromMapSymbol_TileRow * 16) + 416) - 16)); { 4AC7 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank801)^[6403], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 4AEB }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank801)^[6403], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 4B0F }
    GameActors[LoadedActorCount].FlashFrames := 0; { 4B1E }
    GameActors[LoadedActorCount].ActorSpriteBase := 837; { 4B2A }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 4B40 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 4B54 }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 4B68 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 4B7C }
    if Random(2) > 0 then { 4B8B }
    begin { 4B8B }
      GameActors[LoadedActorCount].ActorDirectionX := 1; { 4B95 }
    end { 4B9B }
    else { 4B9B }
    begin { 4B9D }
      GameActors[LoadedActorCount].ActorDirectionX := -1; { 4BA5 }
    end; { 4BAB }
    GameActors[LoadedActorCount].DirectionY := 0; { 4BB5 }
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then { 4BC6 }
    begin { 4BC6 }
      GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 4BD0 }
    end { 4BD6 }
    else { 4BD6 }
    begin { 4BD8 }
      GameActors[LoadedActorCount].ActorAnimationCounter := 21; { 4BE0 }
    end; { 4BE6 }
    GameActors[LoadedActorCount].ActorMovementStep := 2; { 4BEE }
    GameActors[LoadedActorCount].ActorCounterA := (Random(20) + 30); { 4C08 }
    GameActors[LoadedActorCount].ActorCounterB := 0; { 4C16 }
    GameActors[LoadedActorCount].ActorKindValue1 := 3; { 4C22 }
    GameActors[LoadedActorCount].ActorKindCode := 33; { 4C30 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 4C3E }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 4C4B }
  end; { 4C50 }
  if SpawnActorFromMapSymb_MapSymbol = 'e' then { 4C60 }
  begin { 4C60 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 4C80 }
    Inc(LoadedActorCount); { 4C83 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank101)^[2563], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 4CA6 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank101)^[2563], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 4CCA }
    GameActors[LoadedActorCount].FlashFrames := 0; { 4CD9 }
    GameActors[LoadedActorCount].ActorSpriteBase := 117; { 4CE5 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 4CFB }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 4D0F }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 4D23 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 4D37 }
    if Random(2) > 0 then { 4D46 }
    begin { 4D46 }
      GameActors[LoadedActorCount].ActorDirectionX := 1; { 4D50 }
    end { 4D56 }
    else { 4D56 }
    begin { 4D58 }
      GameActors[LoadedActorCount].ActorDirectionX := -1; { 4D60 }
    end; { 4D66 }
    GameActors[LoadedActorCount].DirectionY := 0; { 4D70 }
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then { 4D81 }
    begin { 4D81 }
      GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 4D8B }
    end { 4D91 }
    else { 4D91 }
    begin { 4D93 }
      GameActors[LoadedActorCount].ActorAnimationCounter := 21; { 4D9B }
    end; { 4DA1 }
    GameActors[LoadedActorCount].ActorMovementStep := 2; { 4DA9 }
    GameActors[LoadedActorCount].ActorCounterA := 0; { 4DB9 }
    GameActors[LoadedActorCount].ActorCounterB := 0; { 4DC7 }
    GameActors[LoadedActorCount].ActorKindValue1 := 3; { 4DD3 }
    GameActors[LoadedActorCount].ActorKindCode := 34; { 4DE1 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 4DEF }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 4DFC }
  end; { 4E01 }
  if SpawnActorFromMapSymb_MapSymbol = 'u' then { 4E11 }
  begin { 4E11 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 4E31 }
    Inc(LoadedActorCount); { 4E34 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank101)^[1283], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 4E57 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank101)^[1283], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 4E7B }
    GameActors[LoadedActorCount].FlashFrames := 0; { 4E8A }
    GameActors[LoadedActorCount].ActorSpriteBase := 109; { 4E96 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 4EAC }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 4EC0 }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 4ED4 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 4EE8 }
    GameActors[LoadedActorCount].ActorDirectionX := 1; { 4EF4 }
    GameActors[LoadedActorCount].DirectionY := 0; { 4F04 }
    GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 4F10 }
    GameActors[LoadedActorCount].ActorMovementStep := 0; { 4F20 }
    GameActors[LoadedActorCount].ActorCounterA := 0; { 4F2E }
    GameActors[LoadedActorCount].ActorCounterB := 0; { 4F3C }
    GameActors[LoadedActorCount].ActorKindValue1 := 3; { 4F48 }
    GameActors[LoadedActorCount].ActorKindCode := 35; { 4F56 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 4F64 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 4F71 }
  end; { 4F76 }
  if SpawnActorFromMapSymb_MapSymbol = 'v' then { 4F86 }
  begin { 4F86 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 4FA6 }
    Inc(LoadedActorCount); { 4FA9 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank101)^[1923], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 4FCC }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank101)^[1923], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 4FF0 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 4FFF }
    GameActors[LoadedActorCount].ActorSpriteBase := 113; { 500B }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 5021 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 5035 }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 5049 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 505D }
    GameActors[LoadedActorCount].ActorDirectionX := 1; { 5069 }
    GameActors[LoadedActorCount].DirectionY := 0; { 5079 }
    GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 5085 }
    GameActors[LoadedActorCount].ActorMovementStep := 0; { 5095 }
    GameActors[LoadedActorCount].ActorCounterA := 0; { 50A3 }
    GameActors[LoadedActorCount].ActorCounterB := 10; { 50AF }
    GameActors[LoadedActorCount].ActorKindValue1 := 10; { 50BD }
    GameActors[LoadedActorCount].ActorKindCode := 36; { 50CB }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 50D9 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 50E6 }
  end; { 50EB }
  if SpawnActorFromMapSymb_MapSymbol = 'n' then { 50FB }
  begin { 50FB }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 511B }
    Inc(LoadedActorCount); { 511E }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank101)^[5123], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 5141 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank101)^[5123], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 5165 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 5174 }
    GameActors[LoadedActorCount].ActorSpriteBase := 133; { 5180 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 5196 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 51AA }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 51BE }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 51D2 }
    if Random(2) > 0 then { 51E1 }
    begin { 51E1 }
      GameActors[LoadedActorCount].ActorDirectionX := 1; { 51EB }
    end { 51F1 }
    else { 51F1 }
    begin { 51F3 }
      GameActors[LoadedActorCount].ActorDirectionX := -1; { 51FB }
    end; { 5201 }
    GameActors[LoadedActorCount].DirectionY := 0; { 520B }
    GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 5217 }
    GameActors[LoadedActorCount].ActorMovementStep := 2; { 5225 }
    GameActors[LoadedActorCount].ActorCounterA := (Random(20) + 30); { 523F }
    GameActors[LoadedActorCount].ActorCounterB := 0; { 524D }
    GameActors[LoadedActorCount].ActorKindValue1 := 3; { 5259 }
    GameActors[LoadedActorCount].StateValueB := (Random(50) + 100); { 5273 }
    GameActors[LoadedActorCount].ActorKindCode := 38; { 527F }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 528D }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 529A }
  end; { 529F }
  if SpawnActorFromMapSymb_MapSymbol = '$' then { 52AF }
  begin { 52AF }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 52CF }
    Inc(LoadedActorCount); { 52D2 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank101)^[3], (SpawnActorFromMapSym_TileColumn * 16),
    (((SpawnActorFromMapSymbol_TileRow * 16) + 16) - 16)); { 52F8 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank101)^[3], (SpawnActorFromMapSym_TileColumn * 16),
    (((SpawnActorFromMapSymbol_TileRow * 16) + 416) - 16)); { 531F }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank101)^[643], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 5343 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank101)^[643], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 5367 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 5376 }
    GameActors[LoadedActorCount].ActorSpriteBase := 101; { 5382 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 5398 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 53AC }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 53C0 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 53D4 }
    if Random(2) > 0 then { 53E3 }
    begin { 53E3 }
      GameActors[LoadedActorCount].ActorDirectionX := 1; { 53ED }
    end { 53F3 }
    else { 53F3 }
    begin { 53F5 }
      GameActors[LoadedActorCount].ActorDirectionX := -1; { 53FD }
    end; { 5403 }
    GameActors[LoadedActorCount].DirectionY := 0; { 540D }
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then { 541E }
    begin { 541E }
      GameActors[LoadedActorCount].ActorAnimationCounter := 201; { 5428 }
    end { 542E }
    else { 542E }
    begin { 5430 }
      GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 5438 }
    end; { 543E }
    GameActors[LoadedActorCount].ActorMovementStep := 2; { 5446 }
    GameActors[LoadedActorCount].ActorCounterA := 60; { 5454 }
    GameActors[LoadedActorCount].ActorCounterB := 0; { 5464 }
    GameActors[LoadedActorCount].ActorKindValue1 := 3; { 5470 }
    GameActors[LoadedActorCount].StateValueB := (Random(20) + 60); { 548A }
    GameActors[LoadedActorCount].ActorKindCode := 39; { 5496 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 54A4 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 54B1 }
  end; { 54B6 }
  if SpawnActorFromMapSymb_MapSymbol = '[' then { 54C6 }
  begin { 54C6 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 54E6 }
    Inc(LoadedActorCount); { 54E9 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 54F7 }
    GameActors[LoadedActorCount].ActorSpriteBase := 435; { 5503 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 5519 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 552D }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 5541 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 5555 }
    GameActors[LoadedActorCount].ActorDirectionX := 0; { 5563 }
    GameActors[LoadedActorCount].DirectionY := 0; { 5571 }
    GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 557D }
    GameActors[LoadedActorCount].ActorMovementStep := 0; { 558D }
    GameActors[LoadedActorCount].ActorCounterA := 0; { 559B }
    GameActors[LoadedActorCount].ActorCounterB := 0; { 55A9 }
    GameActors[LoadedActorCount].ActorKindValue1 := 0; { 55B7 }
    GameActors[LoadedActorCount].StateValueB := 0; { 55C5 }
    GameActors[LoadedActorCount].ActorKindCode := 41; { 55D1 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 55DF }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 55EC }
  end; { 55F1 }
  if SpawnActorFromMapSymb_MapSymbol = #127 then { 5601 }
  begin { 5601 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 5621 }
    Inc(LoadedActorCount); { 5624 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank601)^[1283], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 5647 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank601)^[1283], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 566B }
    GameActors[LoadedActorCount].FlashFrames := 0; { 567A }
    GameActors[LoadedActorCount].ActorSpriteBase := 609; { 5686 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 569C }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 56B0 }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 56C4 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 56D8 }
    if Random(2) > 0 then { 56E7 }
    begin { 56E7 }
      GameActors[LoadedActorCount].ActorDirectionX := 1; { 56F1 }
    end { 56F7 }
    else { 56F7 }
    begin { 56F9 }
      GameActors[LoadedActorCount].ActorDirectionX := -1; { 5701 }
    end; { 5707 }
    GameActors[LoadedActorCount].DirectionY := 0; { 5711 }
    GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 571D }
    GameActors[LoadedActorCount].ActorMovementStep := 2; { 572B }
    GameActors[LoadedActorCount].ActorCounterA := 2; { 5739 }
    GameActors[LoadedActorCount].ActorCounterB := 11; { 5747 }
    GameActors[LoadedActorCount].ActorKindCode := 6; { 5755 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 5763 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 5770 }
  end; { 5775 }
  if SpawnActorFromMapSymb_MapSymbol = 'R' then { 5785 }
  begin { 5785 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 464, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 57A6 }
    Inc(LoadedActorCount); { 57A9 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank451)^[2083], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 57CC }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank451)^[2083], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 57F0 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 57FF }
    GameActors[LoadedActorCount].ActorSpriteBase := 464; { 580B }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 5821 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 5835 }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 5849 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 585D }
    GameActors[LoadedActorCount].ActorDirectionX := 1; { 5869 }
    GameActors[LoadedActorCount].DirectionY := 0; { 5879 }
    GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 5885 }
    GameActors[LoadedActorCount].ActorMovementStep := 0; { 5895 }
    GameActors[LoadedActorCount].ActorCounterA := (Random(20) + 55); { 58AD }
    GameActors[LoadedActorCount].ActorCounterB := 0; { 58BB }
    GameActors[LoadedActorCount].ActorKindCode := 10; { 58C7 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 58D5 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 58E2 }
  end; { 58E7 }
  if SpawnActorFromMapSymb_MapSymbol = 'Q' then { 58F7 }
  begin { 58F7 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 465, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 5918 }
    Inc(LoadedActorCount); { 591B }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank451)^[2243], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 593E }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank451)^[2243], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 5962 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 5971 }
    GameActors[LoadedActorCount].ActorSpriteBase := 465; { 597D }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 5993 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 59A7 }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 59BB }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 59CF }
    GameActors[LoadedActorCount].ActorDirectionX := 1; { 59DB }
    GameActors[LoadedActorCount].DirectionY := 0; { 59EB }
    GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 59F7 }
    GameActors[LoadedActorCount].ActorMovementStep := 0; { 5A07 }
    GameActors[LoadedActorCount].ActorCounterA := (Random(20) + 55); { 5A1F }
    GameActors[LoadedActorCount].ActorCounterB := 0; { 5A2D }
    GameActors[LoadedActorCount].ActorKindCode := 11; { 5A39 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 5A47 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 5A54 }
  end; { 5A59 }
  if SpawnActorFromMapSymb_MapSymbol = '<' then { 5A69 }
  begin { 5A69 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 487, 1, 0,
    SpawnActorFromMa_ForegroundOnly); { 5A8A }
    Inc(LoadedActorCount); { 5A8D }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank451)^[5763], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 5AB0 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank451)^[5763], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 5AD4 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 5AE3 }
    GameActors[LoadedActorCount].ActorSpriteBase := 487; { 5AEF }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 5B05 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 5B19 }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 5B2D }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 5B41 }
    GameActors[LoadedActorCount].ActorDirectionX := 1; { 5B4D }
    GameActors[LoadedActorCount].DirectionY := 0; { 5B5D }
    GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 5B69 }
    GameActors[LoadedActorCount].ActorMovementStep := 0; { 5B79 }
    GameActors[LoadedActorCount].ActorCounterA := (Random(20) + 55); { 5B91 }
    GameActors[LoadedActorCount].ActorCounterB := 0; { 5B9F }
    GameActors[LoadedActorCount].ActorKindCode := 12; { 5BAB }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 5BB9 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 5BC6 }
  end; { 5BCB }
  if SpawnActorFromMapSymb_MapSymbol = '=' then { 5BDB }
  begin { 5BDB }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 491, 1, 0,
    SpawnActorFromMa_ForegroundOnly); { 5BFC }
    Inc(LoadedActorCount); { 5BFF }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank451)^[6403], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 5C22 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank451)^[6403], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 5C46 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 5C55 }
    GameActors[LoadedActorCount].ActorSpriteBase := 491; { 5C61 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 5C77 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 5C8B }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 5C9F }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 5CB3 }
    GameActors[LoadedActorCount].ActorDirectionX := 1; { 5CBF }
    GameActors[LoadedActorCount].DirectionY := 0; { 5CCF }
    GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 5CDB }
    GameActors[LoadedActorCount].ActorMovementStep := 0; { 5CEB }
    GameActors[LoadedActorCount].ActorCounterA := (Random(20) + 55); { 5D03 }
    GameActors[LoadedActorCount].ActorCounterB := 0; { 5D11 }
    GameActors[LoadedActorCount].ActorKindCode := 13; { 5D1D }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 5D2B }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 5D38 }
  end; { 5D3D }
  if SpawnActorFromMapSymb_MapSymbol = ';' then { 5D4D }
  begin { 5D4D }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, (SpawnActorFromMapSymbol_TileRow - 2), 2, 0, 428, 1, 0, 0); { 5D71 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, (SpawnActorFromMapSymbol_TileRow - 1), 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 5D91 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 427, 1, 0, 0); { 5DAF }
    Inc(LoadedActorCount); { 5DB2 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank401)^[4323], (SpawnActorFromMapSym_TileColumn * 16),
    (((SpawnActorFromMapSymbol_TileRow - 2) * 16) + 16)); { 5DD8 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank401)^[4323], (SpawnActorFromMapSym_TileColumn * 16),
    (((SpawnActorFromMapSymbol_TileRow - 2) * 16) + 416)); { 5DFF }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank401)^[4163], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 5E23 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank401)^[4163], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 5E47 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 5E56 }
    GameActors[LoadedActorCount].ActorSpriteBase := 435; { 5E62 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 5E78 }
    GameActors[LoadedActorCount].ActorWorldY := ((SpawnActorFromMapSymbol_TileRow - 1) * 16); { 5E8D }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 5EA1 }
    GameActors[LoadedActorCount].ActorPreviousY := ((SpawnActorFromMapSymbol_TileRow - 1) * 16); { 5EB6 }
    GameActors[LoadedActorCount].ActorDirectionX := 1; { 5EC2 }
    GameActors[LoadedActorCount].DirectionY := 0; { 5ED2 }
    GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 5EDE }
    GameActors[LoadedActorCount].ActorMovementStep := 0; { 5EEE }
    GameActors[LoadedActorCount].ActorCounterA := 30; { 5EFA }
    GameActors[LoadedActorCount].ActorCounterB := Random(30); { 5F11 }
    GameActors[LoadedActorCount].ActorKindCode := 15; { 5F1D }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 5F2B }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 5F38 }
  end; { 5F3D }
  if SpawnActorFromMapSymb_MapSymbol = '>' then { 5F4D }
  begin { 5F4D }
    SetAndDrawLevelCell((SpawnActorFromMapSym_TileColumn - 2), SpawnActorFromMapSymbol_TileRow, 2, 0, 433, 1, 0,
    SpawnActorFromMa_ForegroundOnly); { 5F72 }
    SetAndDrawLevelCell((SpawnActorFromMapSym_TileColumn - 1), SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 5F92 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 434, 1, 0,
    SpawnActorFromMa_ForegroundOnly); { 5FB1 }
    Inc(LoadedActorCount); { 5FB4 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank401)^[5123], ((SpawnActorFromMapSym_TileColumn - 2) * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 5FDA }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank401)^[5123], ((SpawnActorFromMapSym_TileColumn - 2) * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 6001 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank401)^[5283], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 16)); { 6025 }
    PgBlitMaskedShifted16x16(PRawByteView(SpriteBank401)^[5283], (SpawnActorFromMapSym_TileColumn * 16),
    ((SpawnActorFromMapSymbol_TileRow * 16) + 416)); { 6049 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 6058 }
    GameActors[LoadedActorCount].ActorSpriteBase := 435; { 6064 }
    GameActors[LoadedActorCount].ActorWorldX := ((SpawnActorFromMapSym_TileColumn - 1) * 16); { 607B }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 608F }
    GameActors[LoadedActorCount].ActorPreviousX := ((SpawnActorFromMapSym_TileColumn - 1) * 16); { 60A4 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 60B8 }
    GameActors[LoadedActorCount].ActorDirectionX := 1; { 60C4 }
    GameActors[LoadedActorCount].DirectionY := 0; { 60D4 }
    GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 60E0 }
    GameActors[LoadedActorCount].ActorMovementStep := 0; { 60F0 }
    GameActors[LoadedActorCount].ActorCounterA := 30; { 60FC }
    GameActors[LoadedActorCount].ActorCounterB := Random(30); { 6113 }
    GameActors[LoadedActorCount].ActorKindCode := 16; { 611F }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 612D }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 613A }
  end; { 613F }
  if SpawnActorFromMapSymb_MapSymbol = '?' then { 614F }
  begin { 614F }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 616F }
    Inc(LoadedActorCount); { 6172 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 6180 }
    GameActors[LoadedActorCount].ActorSpriteBase := 435; { 618C }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 61A2 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 61B6 }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 61CA }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 61DE }
    GameActors[LoadedActorCount].ActorDirectionX := 1; { 61EA }
    GameActors[LoadedActorCount].DirectionY := 0; { 61FA }
    GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 6206 }
    GameActors[LoadedActorCount].ActorMovementStep := 0; { 6216 }
    GameActors[LoadedActorCount].ActorCounterA := 30; { 6222 }
    GameActors[LoadedActorCount].ActorCounterB := Random(30); { 6239 }
    GameActors[LoadedActorCount].ActorKindCode := 17; { 6245 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 6253 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 6260 }
  end; { 6265 }
  if SpawnActorFromMapSymb_MapSymbol = 'A' then { 6275 }
  begin { 6275 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 6295 }
    Inc(LoadedActorCount); { 6298 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 62A6 }
    GameActors[LoadedActorCount].ActorSpriteBase := 435; { 62B2 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 62C8 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 62DC }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 62F0 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 6304 }
    GameActors[LoadedActorCount].ActorDirectionX := 1; { 6310 }
    GameActors[LoadedActorCount].DirectionY := 0; { 6320 }
    GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 632C }
    GameActors[LoadedActorCount].ActorMovementStep := 0; { 633C }
    GameActors[LoadedActorCount].ActorCounterA := 30; { 6348 }
    GameActors[LoadedActorCount].ActorCounterB := Random(30); { 635F }
    GameActors[LoadedActorCount].ActorKindCode := 18; { 636B }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 6379 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 6386 }
  end; { 638B }
  if SpawnActorFromMapSymb_MapSymbol = '@' then { 639B }
  begin { 639B }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 302, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 63BC }
    Inc(LoadedActorCount); { 63BF }
    GameActors[LoadedActorCount].FlashFrames := 0; { 63CD }
    GameActors[LoadedActorCount].ActorSpriteBase := 305; { 63D9 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 63EF }
    GameActors[LoadedActorCount].ActorWorldY := ((SpawnActorFromMapSymbol_TileRow - 1) * 16); { 6404 }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 6418 }
    GameActors[LoadedActorCount].ActorPreviousY := ((SpawnActorFromMapSymbol_TileRow - 1) * 16); { 642D }
    GameActors[LoadedActorCount].ActorDirectionX := 0; { 643B }
    GameActors[LoadedActorCount].DirectionY := 0; { 6449 }
    GameActors[LoadedActorCount].ActorAnimationCounter := (Random(18) + 1); { 645F }
    GameActors[LoadedActorCount].ActorMovementStep := 0; { 646D }
    GameActors[LoadedActorCount].ActorCounterA := 0; { 647B }
    GameActors[LoadedActorCount].ActorCounterB := 5; { 6487 }
    GameActors[LoadedActorCount].ActorKindCode := 43; { 6495 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 64A3 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 64B0 }
  end; { 64B5 }
  if SpawnActorFromMapSymb_MapSymbol = #212 then { 64C5 }
  begin { 64C5 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 64E5 }
    Inc(LoadedActorCount); { 64E8 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 64F6 }
    GameActors[LoadedActorCount].ActorSpriteBase := 309; { 6502 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 6518 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 652C }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 6540 }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 6554 }
    GameActors[LoadedActorCount].ActorDirectionX := 0; { 6562 }
    GameActors[LoadedActorCount].DirectionY := 0; { 6570 }
    GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 657C }
    GameActors[LoadedActorCount].ActorMovementStep := 0; { 658C }
    GameActors[LoadedActorCount].ActorCounterA := 0; { 659A }
    GameActors[LoadedActorCount].ActorCounterB := 2; { 65A6 }
    GameActors[LoadedActorCount].ActorKindCode := 44; { 65B4 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 65C2 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 65CF }
  end; { 65D4 }
  if SpawnActorFromMapSymb_MapSymbol = 'x' then { 65E4 }
  begin { 65E4 }
    SetAndDrawLevelCell(SpawnActorFromMapSym_TileColumn, SpawnActorFromMapSymbol_TileRow, 2, 0, 0, 0, 0,
    SpawnActorFromMa_ForegroundOnly); { 6604 }
    Inc(LoadedActorCount); { 6607 }
    GameActors[LoadedActorCount].FlashFrames := 0; { 6615 }
    GameActors[LoadedActorCount].ActorSpriteBase := 259; { 6621 }
    GameActors[LoadedActorCount].ActorWorldX := (SpawnActorFromMapSym_TileColumn * 16); { 6637 }
    GameActors[LoadedActorCount].ActorWorldY := (SpawnActorFromMapSymbol_TileRow * 16); { 664B }
    GameActors[LoadedActorCount].ActorPreviousX := (SpawnActorFromMapSym_TileColumn * 16); { 665F }
    GameActors[LoadedActorCount].ActorPreviousY := (SpawnActorFromMapSymbol_TileRow * 16); { 6673 }
    GameActors[LoadedActorCount].ActorDirectionX := 0; { 6681 }
    GameActors[LoadedActorCount].DirectionY := 0; { 668F }
    GameActors[LoadedActorCount].ActorAnimationCounter := 1; { 669B }
    GameActors[LoadedActorCount].ActorMovementStep := 0; { 66AB }
    GameActors[LoadedActorCount].ActorCounterA := 0; { 66B9 }
    GameActors[LoadedActorCount].ActorCounterB := 2; { 66C5 }
    GameActors[LoadedActorCount].ActorKindCode := 44; { 66D3 }
    GameActors[LoadedActorCount].ActorSlotInactive := 0; { 66E1 }
    GameActors[LoadedActorCount].ActorRemovalPending := 0; { 66EE }
  end; { 66F3 }
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Expands 40 encoded symbols into cells/actors, recognizes '*' foreground rows and 'Y' player start. }
procedure DecodeLevelRow(DecodeLevelRow_TileRow: Integer; EncodedRow: TLevelFileRow);
var
  DecodeLevelRow_TileColumn: Integer;
  DecodeLevelRow_MapSymbol: string;
  SavedStartColumn, SavedStartRow: Integer;
  DecodeLevelRow_ForegroundOnly: Boolean;
begin
  if EncodedRow[1] <> '*' then
  begin
    DecodeLevelRow_ForegroundOnly := False;
    for DecodeLevelRow_TileColumn := 1 to 40 do
    begin
      LevelCells[DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow + 1].CellBaseTile := 0;
      LevelCells[DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow + 1].CellOverlayTile := 0;
      LevelCells[DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow + 1].CellObjectCode := 0;
      LevelCells[DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow + 1].CellSolidFlag := 0;
      LevelCells[DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow + 1].SupportsLanding := 0;
    end;
  end
  else
    DecodeLevelRow_ForegroundOnly := True;
  for DecodeLevelRow_TileColumn := 0 to 39 do
  begin
    { 697F } MemW[0:1052] := MemW[0:1050];
    { 6993 } DecodeLevelRow_MapSymbol := EncodedRow[(DecodeLevelRow_TileColumn + 1)];
    { 69B7 } if DecodeLevelRow_MapSymbol = ' ' then
    begin
      { 69C9 } if not DecodeLevelRow_ForegroundOnly then
      begin
        { 69D0 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
    end;
    { 69EF } if CurrentLevelNumber > 1 then
    begin
      { 69F9 } if DecodeLevelRow_MapSymbol = '1' then
      begin
        { 6A0B } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 1, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6A2A } if DecodeLevelRow_MapSymbol = '2' then
      begin
        { 6A3C } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 3, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6A5B } if DecodeLevelRow_MapSymbol = '3' then
      begin
        { 6A6D } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 4, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6A8C } if DecodeLevelRow_MapSymbol = '5' then
      begin
        { 6A9E } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 5, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6ABD } if DecodeLevelRow_MapSymbol = '6' then
      begin
        { 6ACF } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 6, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6AEE } if DecodeLevelRow_MapSymbol = '7' then
      begin
        { 6B00 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 7, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6B1F } if DecodeLevelRow_MapSymbol = #30 then
      begin
        { 6B31 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 8, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6B50 } if DecodeLevelRow_MapSymbol = 'w' then
      begin
        { 6B62 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, (DecodeLevelRow_TileRow - 1), 2, 0, 179, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 6B84 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 183, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6BA4 } if DecodeLevelRow_MapSymbol = #1 then
      begin
        { 6BB6 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 619, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6BD6 } if DecodeLevelRow_MapSymbol = #2 then
      begin
        { 6BE8 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 161, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6C08 } if DecodeLevelRow_MapSymbol = #3 then
      begin
        { 6C1A } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 162, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6C3A } if DecodeLevelRow_MapSymbol = #4 then
      begin
        { 6C4C } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 155, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6C6C } if DecodeLevelRow_MapSymbol = #6 then
      begin
        { 6C7E } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 158, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6C9E } if DecodeLevelRow_MapSymbol = #5 then
      begin
        { 6CB0 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 156, 0, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 6CD1 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 157, 0, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6CF0 } if DecodeLevelRow_MapSymbol = #7 then
      begin
        { 6D02 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 174, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6D22 } if DecodeLevelRow_MapSymbol = #8 then
      begin
        { 6D34 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 2, 181, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 6D56 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 182, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6D76 } if DecodeLevelRow_MapSymbol = #12 then
      begin
        { 6D88 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 2, 185, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 6DAA } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 186, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6DCA } if DecodeLevelRow_MapSymbol = #11 then
      begin
        { 6DDC } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 178, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6DFC } if DecodeLevelRow_MapSymbol = #14 then
      begin
        { 6E0E } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 733, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6E2E } if DecodeLevelRow_MapSymbol = #15 then
      begin
        { 6E40 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 734, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6E60 } if DecodeLevelRow_MapSymbol = #16 then
      begin
        { 6E72 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 735, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6E92 } if DecodeLevelRow_MapSymbol = #17 then
      begin
        { 6EA4 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 737, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6EC4 } if DecodeLevelRow_MapSymbol = #18 then
      begin
        { 6ED6 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 741, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6EF6 } if DecodeLevelRow_MapSymbol = #19 then
      begin
        { 6F08 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 743, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6F28 } if DecodeLevelRow_MapSymbol = #20 then
      begin
        { 6F3A } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, (DecodeLevelRow_TileRow - 1), 2, 745, 0, Ord(False),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 6F5C } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 749, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6F7C } if DecodeLevelRow_MapSymbol = #21 then
      begin
        { 6F8E } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 746, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6FAE } if DecodeLevelRow_MapSymbol = #22 then
      begin
        { 6FC0 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 750, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 6FE0 } if DecodeLevelRow_MapSymbol = #23 then
      begin
        { 6FF2 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 677, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7012 } if DecodeLevelRow_MapSymbol = #24 then
      begin
        { 7024 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 678, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7044 } if DecodeLevelRow_MapSymbol = #25 then
      begin
        { 7056 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, (DecodeLevelRow_TileRow - 1), 2, 251, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 7078 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 255, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7098 } if DecodeLevelRow_MapSymbol = #27 then
      begin
        { 70AD } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), (DecodeLevelRow_TileRow - 1), 2, 252, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 70D1 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, (DecodeLevelRow_TileRow - 1), 2, 253, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 70F3 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 2, 256, 0, Ord(False),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 7115 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 257, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7135 } if DecodeLevelRow_MapSymbol = #28 then
      begin
        { 7147 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, (DecodeLevelRow_TileRow - 1), 2, 254, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 7169 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 258, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7189 } if DecodeLevelRow_MapSymbol = '^' then
      begin
        { 719B } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 314, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 71BB } if DecodeLevelRow_MapSymbol = 'K' then
      begin
        { 71CD } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 606, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 71ED } if DecodeLevelRow_MapSymbol = 'I' then
      begin
        { 71FF } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 0, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 721E } if DecodeLevelRow_MapSymbol = #211 then
      begin
        { 7230 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 0, -1, Ord(False),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7250 } if DecodeLevelRow_MapSymbol = 'r' then
      begin
        { 7262 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 607, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7282 } if DecodeLevelRow_MapSymbol = 's' then
      begin
        { 7294 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 301, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 72B4 } if DecodeLevelRow_MapSymbol = 'N' then
      begin
        { 72C6 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 313, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 72E6 } if DecodeLevelRow_MapSymbol = 'T' then
      begin
        { 72F8 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 316, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7318 } if DecodeLevelRow_MapSymbol = 'W' then
      begin
        { 732A } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 618, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 734A } if DecodeLevelRow_MapSymbol = '\' then
      begin
        { 735C } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 620, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 737C } if DecodeLevelRow_MapSymbol = ']' then
      begin
        { 738E } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 629, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 73AE } if DecodeLevelRow_MapSymbol = 'd' then
      begin
        { 73C0 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 630, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 73E0 } if DecodeLevelRow_MapSymbol = 'f' then
      begin
        { 73F2 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 631, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7412 } if DecodeLevelRow_MapSymbol = 'h' then
      begin
        { 7424 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 632, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7444 } if DecodeLevelRow_MapSymbol = ':' then
      begin
        { 7456 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 466, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7476 } if DecodeLevelRow_MapSymbol = 'H' then
      begin
        { 7488 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 468, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 74A8 } if DecodeLevelRow_MapSymbol = 'M' then
      begin
        { 74BA } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 624, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 74DA } if DecodeLevelRow_MapSymbol = 'P' then
      begin
        { 74EC } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 304, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 750C } if DecodeLevelRow_MapSymbol = 'p' then
      begin
        { 751E } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 2, 159, 0, Ord(False),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 7540 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 160, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7560 } if DecodeLevelRow_MapSymbol = #139 then
      begin
        { 7572 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, LevelBackdropTile, 163, 0,
        Ord(True), Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 7594 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 164, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 75B4 } if DecodeLevelRow_MapSymbol = #154 then
      begin
        { 75C6 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, LevelBackdropTile, 166, 0,
        Ord(True), Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 75E8 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 165, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7608 } if DecodeLevelRow_MapSymbol = #31 then
      begin
        { 761A } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 166, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 763A } if DecodeLevelRow_MapSymbol = #168 then
      begin
        { 764C } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 175, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 766C } if DecodeLevelRow_MapSymbol = #169 then
      begin
        { 767E } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 176, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 769E } if DecodeLevelRow_MapSymbol = #170 then
      begin
        { 76B0 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 177, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 76D0 } if DecodeLevelRow_MapSymbol = #171 then
      begin
        { 76E2 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, (DecodeLevelRow_TileRow - 1), 194, 0, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 7703 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 198, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7722 } if DecodeLevelRow_MapSymbol = #172 then
      begin
        { 7734 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 197, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7754 } if DecodeLevelRow_MapSymbol = #173 then
      begin
        { 7766 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 193, 0, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7785 } if DecodeLevelRow_MapSymbol = #133 then
      begin
        { 779A } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 3), DecodeLevelRow_TileRow, 2, 0, 221, Ord(False),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 77BE } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 2), DecodeLevelRow_TileRow, 2, 0, 222, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 77E2 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 2, 0, 223, Ord(False),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 7804 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 224, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7824 } if DecodeLevelRow_MapSymbol = #134 then
      begin
        { 7836 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 2), DecodeLevelRow_TileRow, 2, 0, 229, Ord(False),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 785A } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 2, 0, 230, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 787C } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 231, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 789C } if DecodeLevelRow_MapSymbol = '+' then
      begin
        { 78AE } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 421, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 78CE } if DecodeLevelRow_MapSymbol = ',' then
      begin
        { 78E0 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 422, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7900 } if DecodeLevelRow_MapSymbol = '-' then
      begin
        { 7912 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 423, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7932 } if DecodeLevelRow_MapSymbol = '.' then
      begin
        { 7944 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 424, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7964 } if DecodeLevelRow_MapSymbol = '/' then
      begin
        { 7976 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 425, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7996 } if DecodeLevelRow_MapSymbol = '4' then
      begin
        { 79A8 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 426, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 79C8 } if DecodeLevelRow_MapSymbol = 'o' then
      begin
        { 79DA } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 417, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 79FA } if DecodeLevelRow_MapSymbol = 'i' then
      begin
        { 7A0C } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 441, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7A2B } if DecodeLevelRow_MapSymbol = 'j' then
      begin
        { 7A3D } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 442, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7A5D } if DecodeLevelRow_MapSymbol = 'k' then
      begin
        { 7A6F } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 443, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7A8F } if DecodeLevelRow_MapSymbol = 'l' then
      begin
        { 7AA1 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 444, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7AC1 } if DecodeLevelRow_MapSymbol = #149 then
      begin
        { 7AD3 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 449, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7AF3 } if DecodeLevelRow_MapSymbol = '|' then
      begin
        { 7B05 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 419, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7B25 } if DecodeLevelRow_MapSymbol = '~' then
      begin
        { 7B37 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 420, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7B57 } if DecodeLevelRow_MapSymbol = 'm' then
      begin
        { 7B6C } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
        { 7B8B } Inc(LoadedActorCount);
        { 7B8F } PgBlitMaskedShifted16x16(SpriteBank401^.SpriteEntries[45].SpriteDataBytes[1], (DecodeLevelRow_TileColumn *
        16), ((DecodeLevelRow_TileRow * 16) + 16));
        { 7BB3 } PgBlitMaskedShifted16x16(SpriteBank401^.SpriteEntries[45].SpriteDataBytes[1], (DecodeLevelRow_TileColumn *
        16), ((DecodeLevelRow_TileRow * 16) + 416));
        { 7BD7 } GameActors[LoadedActorCount].FlashFrames := 0;
        { 7BE5 } GameActors[LoadedActorCount].ActorSpriteBase := 445;
        { 7BF3 } GameActors[LoadedActorCount].ActorWorldX := (DecodeLevelRow_TileColumn * 16);
        { 7C07 } GameActors[LoadedActorCount].ActorWorldY := (DecodeLevelRow_TileRow * 16);
        { 7C1B } GameActors[LoadedActorCount].ActorPreviousX := (DecodeLevelRow_TileColumn * 16);
        { 7C2F } GameActors[LoadedActorCount].ActorPreviousY := (DecodeLevelRow_TileRow * 16);
        { 7C43 } if Random(2) > 0 then
        begin
          { 7C50 } GameActors[LoadedActorCount].ActorDirectionX := 1;
        end
        else
        begin
          { 7C60 } GameActors[LoadedActorCount].ActorDirectionX := -1;
        end;
        { 7C6E } GameActors[LoadedActorCount].DirectionY := 0;
        { 7C7C } GameActors[LoadedActorCount].ActorAnimationCounter := 1;
        { 7C8A } GameActors[LoadedActorCount].ActorMovementStep := 1;
        { 7C98 } GameActors[LoadedActorCount].ActorCounterA := 0;
        { 7CA6 } GameActors[LoadedActorCount].ActorCounterB := 0;
        { 7CB4 } GameActors[LoadedActorCount].ActorKindCode := 20;
        { 7CC2 } GameActors[LoadedActorCount].ActorSlotInactive := 0;
        { 7CCF } GameActors[LoadedActorCount].ActorRemovalPending := 0;
      end;
      { 7CDC } if DecodeLevelRow_MapSymbol = 'a' then
      begin
        { 7CEE } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 500, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7D0D } if DecodeLevelRow_MapSymbol = '`' then
      begin
        { 7D1F } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 499, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7D3F } if DecodeLevelRow_MapSymbol = '_' then
      begin
        { 7D54 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
        { 7D73 } Inc(LoadedActorCount);
        { 7D77 } PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[45].SpriteDataBytes[1], (DecodeLevelRow_TileColumn *
        16), ((DecodeLevelRow_TileRow * 16) + 16));
        { 7D9B } PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[45].SpriteDataBytes[1], (DecodeLevelRow_TileColumn *
        16), ((DecodeLevelRow_TileRow * 16) + 416));
        { 7DBF } GameActors[LoadedActorCount].FlashFrames := 0;
        { 7DCD } GameActors[LoadedActorCount].ActorWorldX := (DecodeLevelRow_TileColumn * 16);
        { 7DE1 } GameActors[LoadedActorCount].ActorWorldY := (DecodeLevelRow_TileRow * 16);
        { 7DF5 } GameActors[LoadedActorCount].ActorPreviousX := (DecodeLevelRow_TileColumn * 16);
        { 7E09 } GameActors[LoadedActorCount].ActorPreviousY := (DecodeLevelRow_TileRow * 16);
        { 7E1D } if Random(2) > 0 then
        begin
          { 7E2A } GameActors[LoadedActorCount].ActorDirectionX := 1;
        end
        else
        begin
          { 7E3A } GameActors[LoadedActorCount].ActorDirectionX := -1;
        end;
        { 7E48 } if GameActors[LoadedActorCount].ActorDirectionX = 1 then
        begin
          { 7E57 } GameActors[LoadedActorCount].ActorSpriteBase := 497;
        end
        else
        begin
          { 7E67 } GameActors[LoadedActorCount].ActorSpriteBase := 495;
        end;
        { 7E75 } GameActors[LoadedActorCount].DirectionY := 0;
        { 7E83 } GameActors[LoadedActorCount].ActorAnimationCounter := 1;
        { 7E91 } GameActors[LoadedActorCount].ActorMovementStep := 1;
        { 7E9F } GameActors[LoadedActorCount].ActorCounterA := 0;
        { 7EAD } GameActors[LoadedActorCount].ActorCounterB := 0;
        { 7EBB } GameActors[LoadedActorCount].ActorKindCode := 21;
        { 7EC9 } GameActors[LoadedActorCount].ActorSlotInactive := 0;
        { 7ED6 } GameActors[LoadedActorCount].ActorRemovalPending := 0;
      end;
      { 7EE3 } if DecodeLevelRow_MapSymbol = 'D' then
      begin
        { 7EF5 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 613, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7F15 } if DecodeLevelRow_MapSymbol = 'E' then
      begin
        { 7F27 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 0, 614, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7F47 } if DecodeLevelRow_MapSymbol = 'O' then
      begin
        { 7F59 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 615, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7F79 } if DecodeLevelRow_MapSymbol = 'U' then
      begin
        { 7F8B } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 616, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7FAB } if DecodeLevelRow_MapSymbol = #128 then
      begin
        { 7FBD } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 601, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 7FDD } if DecodeLevelRow_MapSymbol = #129 then
      begin
        { 7FEF } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 602, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 800F } if DecodeLevelRow_MapSymbol = #130 then
      begin
        { 8021 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 603, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8041 } if DecodeLevelRow_MapSymbol = #131 then
      begin
        { 8053 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 604, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8073 } if DecodeLevelRow_MapSymbol = #132 then
      begin
        { 8085 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 605, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 80A5 } if DecodeLevelRow_MapSymbol = #140 then
      begin
        { 80B7 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 621, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 80D7 } if DecodeLevelRow_MapSymbol = #141 then
      begin
        { 80E9 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 622, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8109 } if DecodeLevelRow_MapSymbol = #142 then
      begin
        { 811B } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 623, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 813B } if DecodeLevelRow_MapSymbol = '%' then
      begin
        { 814D } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 2, 0, 452, Ord(False),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 816F } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 453, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 818F } if DecodeLevelRow_MapSymbol = '&' then
      begin
        { 81A4 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), (DecodeLevelRow_TileRow - 1), 455, 0, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 81C7 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, (DecodeLevelRow_TileRow - 1), 456, 0, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 81E8 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 459, 0, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 8209 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 460, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8228 } if DecodeLevelRow_MapSymbol = '(' then
      begin
        { 823D } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), (DecodeLevelRow_TileRow - 1), 457, 0, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 8260 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, (DecodeLevelRow_TileRow - 1), 458, 0, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 8281 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 461, 0, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 82A2 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 462, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 82C1 } if DecodeLevelRow_MapSymbol = ')' then
      begin
        { 82D3 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 463, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 82F3 } if DecodeLevelRow_MapSymbol = '*' then
      begin
        { 8305 } if DecodeLevelRow_TileColumn > 0 then
        begin
          { 830B } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 467, Ord(False), Ord(False),
          Ord(DecodeLevelRow_ForegroundOnly));
        end;
      end;
      { 832B } if DecodeLevelRow_MapSymbol = 'q' then
      begin
        { 833D } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, (DecodeLevelRow_TileRow - 1), 2, 0, 633, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 835F } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 637, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 837F } if DecodeLevelRow_MapSymbol = 't' then
      begin
        { 8391 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 635, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 83B1 } SpawnActorFromMapSymbol(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, DecodeLevelRow_MapSymbol,
      Ord(DecodeLevelRow_ForegroundOnly));
      { 83C6 } if DecodeLevelRow_MapSymbol = #175 then
      begin
        { 83D8 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 349, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 83F7 } if DecodeLevelRow_MapSymbol = #143 then
      begin
        { 8409 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 651, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8429 } if DecodeLevelRow_MapSymbol = #144 then
      begin
        { 843B } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 652, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 845A } if DecodeLevelRow_MapSymbol = #145 then
      begin
        { 846C } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 653, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 848C } if DecodeLevelRow_MapSymbol = #146 then
      begin
        { 849E } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 654, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 84BE } if DecodeLevelRow_MapSymbol = #147 then
      begin
        { 84D0 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 655, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 84EF } if DecodeLevelRow_MapSymbol = #148 then
      begin
        { 8501 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 656, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8520 } if DecodeLevelRow_MapSymbol = #150 then
      begin
        { 8532 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 658, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8552 } if DecodeLevelRow_MapSymbol = #151 then
      begin
        { 8564 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 659, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8584 } if DecodeLevelRow_MapSymbol = #152 then
      begin
        { 8596 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 660, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 85B6 } if DecodeLevelRow_MapSymbol = #153 then
      begin
        { 85C8 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 661, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 85E7 } if DecodeLevelRow_MapSymbol = #155 then
      begin
        { 85F9 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 663, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8619 } if DecodeLevelRow_MapSymbol = #156 then
      begin
        { 862B } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 664, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 864B } if DecodeLevelRow_MapSymbol = #157 then
      begin
        { 865D } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 665, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 867D } if DecodeLevelRow_MapSymbol = #158 then
      begin
        { 868F } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 666, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 86AF } if DecodeLevelRow_MapSymbol = #163 then
      begin
        { 86C1 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 671, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 86E1 } if DecodeLevelRow_MapSymbol = #164 then
      begin
        { 86F3 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 672, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8713 } if DecodeLevelRow_MapSymbol = #165 then
      begin
        { 8725 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 673, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8745 } if DecodeLevelRow_MapSymbol = #166 then
      begin
        { 8757 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 674, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8777 } if DecodeLevelRow_MapSymbol = #176 then
      begin
        { 8789 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 684, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 87A9 } if DecodeLevelRow_MapSymbol = #177 then
      begin
        { 87BB } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 685, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 87DB } if DecodeLevelRow_MapSymbol = #178 then
      begin
        { 87ED } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 686, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 880D } if DecodeLevelRow_MapSymbol = #179 then
      begin
        { 881F } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 687, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 883F } if DecodeLevelRow_MapSymbol = #180 then
      begin
        { 8851 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 688, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8871 } if DecodeLevelRow_MapSymbol = #181 then
      begin
        { 8883 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 689, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 88A3 } if DecodeLevelRow_MapSymbol = #183 then
      begin
        { 88B5 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 691, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 88D5 } if DecodeLevelRow_MapSymbol = #184 then
      begin
        { 88E7 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 692, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8907 } if DecodeLevelRow_MapSymbol = #185 then
      begin
        { 8919 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 693, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8939 } if DecodeLevelRow_MapSymbol = #186 then
      begin
        { 894B } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 690, 0, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 896C } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 694, 0, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 898B } if DecodeLevelRow_MapSymbol = #187 then
      begin
        { 899D } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 695, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 89BC } if DecodeLevelRow_MapSymbol = #188 then
      begin
        { 89CE } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 698, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 89ED } if DecodeLevelRow_MapSymbol = #189 then
      begin
        { 89FF } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 696, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8A1E } if DecodeLevelRow_MapSymbol = #190 then
      begin
        { 8A30 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 697, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8A4F } if DecodeLevelRow_MapSymbol = #191 then
      begin
        { 8A61 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 679, 0, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 8A82 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 680, 0, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8AA1 } if DecodeLevelRow_MapSymbol = 'y' then
      begin
        { 8AB3 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 318, 0, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 8AD4 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 319, 0, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8AF3 } if DecodeLevelRow_MapSymbol = 'z' then
      begin
        { 8B05 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 317, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8B25 } if DecodeLevelRow_MapSymbol = #135 then
      begin
        { 8B37 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 323, 0, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 8B58 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 324, 0, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8B77 } if DecodeLevelRow_MapSymbol = #182 then
      begin
        { 8B89 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 681, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8BA9 } if DecodeLevelRow_MapSymbol = #192 then
      begin
        { 8BBB } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 699, 0, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 8BDC } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 700, 0, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8BFB } if DecodeLevelRow_MapSymbol = #136 then
      begin
        { 8C0D } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 345, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8C2D } if DecodeLevelRow_MapSymbol = #137 then
      begin
        { 8C3F } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 346, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8C5F } if DecodeLevelRow_MapSymbol = #138 then
      begin
        { 8C71 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 347, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8C91 } if DecodeLevelRow_MapSymbol = #162 then
      begin
        { 8CA3 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 348, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8CC3 } if DecodeLevelRow_MapSymbol = #193 then
      begin
        { 8CD5 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 701, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8CF4 } if DecodeLevelRow_MapSymbol = #194 then
      begin
        { 8D06 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 702, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8D25 } if DecodeLevelRow_MapSymbol = #195 then
      begin
        { 8D37 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 703, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8D56 } if DecodeLevelRow_MapSymbol = #196 then
      begin
        { 8D68 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 704, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8D87 } if DecodeLevelRow_MapSymbol = #197 then
      begin
        { 8D99 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 705, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8DB8 } if DecodeLevelRow_MapSymbol = #198 then
      begin
        { 8DCA } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 706, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8DE9 } if DecodeLevelRow_MapSymbol = #199 then
      begin
        { 8DFB } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 707, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8E1A } if DecodeLevelRow_MapSymbol = #200 then
      begin
        { 8E2C } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 708, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8E4B } if DecodeLevelRow_MapSymbol = #201 then
      begin
        { 8E5D } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 709, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8E7C } if DecodeLevelRow_MapSymbol = #202 then
      begin
        { 8E8E } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 710, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8EAE } if DecodeLevelRow_MapSymbol = #203 then
      begin
        { 8EC0 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 0, 711, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8EE0 } if DecodeLevelRow_MapSymbol = #204 then
      begin
        { 8EF2 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 0, 712, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8F12 } if DecodeLevelRow_MapSymbol = #205 then
      begin
        { 8F24 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 0, 713, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8F44 } if DecodeLevelRow_MapSymbol = #206 then
      begin
        { 8F56 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 714, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8F76 } if DecodeLevelRow_MapSymbol = #207 then
      begin
        { 8F88 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 715, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8FA8 } if DecodeLevelRow_MapSymbol = #208 then
      begin
        { 8FBA } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 716, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 8FDA } if DecodeLevelRow_MapSymbol = #209 then
      begin
        { 8FEF } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
        { 900E } Inc(LoadedActorCount);
        { 9012 } PgBlitMaskedShifted16x16(SpriteBank351^.SpriteEntries[1].SpriteDataBytes[1], (DecodeLevelRow_TileColumn *
        16), ((DecodeLevelRow_TileRow * 16) + 16));
        { 9036 } PgBlitMaskedShifted16x16(SpriteBank351^.SpriteEntries[1].SpriteDataBytes[1], (DecodeLevelRow_TileColumn *
        16), ((DecodeLevelRow_TileRow * 16) + 416));
        { 905A } GameActors[LoadedActorCount].FlashFrames := 0;
        { 9068 } GameActors[LoadedActorCount].ActorSpriteBase := 717;
        { 9076 } GameActors[LoadedActorCount].ActorWorldX := (DecodeLevelRow_TileColumn * 16);
        { 908A } GameActors[LoadedActorCount].ActorWorldY := (DecodeLevelRow_TileRow * 16);
        { 909E } GameActors[LoadedActorCount].ActorPreviousX := (DecodeLevelRow_TileColumn * 16);
        { 90B2 } GameActors[LoadedActorCount].ActorPreviousY := (DecodeLevelRow_TileRow * 16);
        { 90C6 } GameActors[LoadedActorCount].ActorDirectionX := 1;
        { 90D4 } GameActors[LoadedActorCount].DirectionY := 0;
        { 90E2 } GameActors[LoadedActorCount].ActorAnimationCounter := 1;
        { 90F0 } GameActors[LoadedActorCount].ActorMovementStep := 0;
        { 90FE } GameActors[LoadedActorCount].ActorCounterA := 0;
        { 910C } GameActors[LoadedActorCount].ActorCounterB := 0;
        { 911A } GameActors[LoadedActorCount].ActorKindCode := 26;
        { 9128 } GameActors[LoadedActorCount].ActorSlotInactive := 0;
        { 9135 } GameActors[LoadedActorCount].ActorRemovalPending := 0;
      end;
      { 9142 } if DecodeLevelRow_MapSymbol = #210 then
      begin
        { 9157 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), (DecodeLevelRow_TileRow - 1), 191, 0, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 917A } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, (DecodeLevelRow_TileRow - 1), 192, 0, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 919B } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 195, 0, 0, Ord(False),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 91BC } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 196, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 91DB } if DecodeLevelRow_MapSymbol = #213 then
      begin
        { 91ED } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 721, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 920D } if DecodeLevelRow_MapSymbol = #214 then
      begin
        { 921F } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 722, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 923F } if DecodeLevelRow_MapSymbol = #215 then
      begin
        { 9251 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 723, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9271 } if DecodeLevelRow_MapSymbol = #217 then
      begin
        { 9283 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 725, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 92A3 } if DecodeLevelRow_MapSymbol = #218 then
      begin
        { 92B5 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 726, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 92D5 } if DecodeLevelRow_MapSymbol = #219 then
      begin
        { 92E7 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 727, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9307 } if DecodeLevelRow_MapSymbol = #220 then
      begin
        { 9319 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 728, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9339 } if DecodeLevelRow_MapSymbol = #221 then
      begin
        { 934B } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 729, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 936B } if DecodeLevelRow_MapSymbol = #222 then
      begin
        { 937D } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 730, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 939D } if DecodeLevelRow_MapSymbol = #223 then
      begin
        { 93AF } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 201, 0, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 93CE } if DecodeLevelRow_MapSymbol = #224 then
      begin
        { 93E0 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 202, 0, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 93FF } if DecodeLevelRow_MapSymbol = #225 then
      begin
        { 9411 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 203, 0, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9430 } if DecodeLevelRow_MapSymbol = #226 then
      begin
        { 9442 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 205, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9461 } if DecodeLevelRow_MapSymbol = #227 then
      begin
        { 9473 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 206, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9492 } if DecodeLevelRow_MapSymbol = #228 then
      begin
        { 94A4 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 207, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 94C3 } if DecodeLevelRow_MapSymbol = '!' then
      begin
        { 94D5 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 751, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 94F4 } if DecodeLevelRow_MapSymbol = 'B' then
      begin
        { 9506 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 753, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9526 } if DecodeLevelRow_MapSymbol = 'C' then
      begin
        { 9538 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 755, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9557 } if DecodeLevelRow_MapSymbol = 'F' then
      begin
        { 9569 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 756, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9589 } if DecodeLevelRow_MapSymbol = 'J' then
      begin
        { 959B } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 757, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 95BB } if DecodeLevelRow_MapSymbol = #229 then
      begin
        { 95CD } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 758, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 95EC } if DecodeLevelRow_MapSymbol = #230 then
      begin
        { 95FE } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 759, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 961E } if DecodeLevelRow_MapSymbol = #231 then
      begin
        { 9630 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 760, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9650 } if DecodeLevelRow_MapSymbol = #232 then
      begin
        { 9662 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 761, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9682 } if DecodeLevelRow_MapSymbol = #233 then
      begin
        { 9694 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 762, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 96B4 } if DecodeLevelRow_MapSymbol = #234 then
      begin
        { 96C6 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 763, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 96E6 } if DecodeLevelRow_MapSymbol = #235 then
      begin
        { 96F8 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 764, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9718 } if DecodeLevelRow_MapSymbol = #236 then
      begin
        { 972A } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 765, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 974A } if DecodeLevelRow_MapSymbol = #237 then
      begin
        { 975C } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 199, 0, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 977D } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 200, 0, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 979C } if DecodeLevelRow_MapSymbol = #216 then
      begin
        { 97AE } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 268, 0, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 97CF } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 269, 0, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 97EE } if DecodeLevelRow_MapSymbol = #238 then
      begin
        { 9800 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 2), DecodeLevelRow_TileRow, 2, 264, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 9824 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 2, 265, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 9846 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 266, 0, Ord(False), Ord(True),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9866 } if DecodeLevelRow_MapSymbol = #239 then
      begin
        { 9878 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, (DecodeLevelRow_TileRow - 1), 2, 263, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 989A } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 267, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 98BA } if DecodeLevelRow_MapSymbol = #241 then
      begin
        { 98CC } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 775, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 98EB } if DecodeLevelRow_MapSymbol = #242 then
      begin
        { 98FD } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 776, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 991C } if DecodeLevelRow_MapSymbol = #243 then
      begin
        { 992E } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 777, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 994D } if DecodeLevelRow_MapSymbol = #244 then
      begin
        { 995F } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 778, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 997E } if DecodeLevelRow_MapSymbol = #245 then
      begin
        { 9990 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 779, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 99AF } if DecodeLevelRow_MapSymbol = #246 then
      begin
        { 99C1 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 780, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 99E0 } if DecodeLevelRow_MapSymbol = #247 then
      begin
        { 99F2 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 781, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9A11 } if DecodeLevelRow_MapSymbol = #248 then
      begin
        { 9A23 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 782, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9A42 } if DecodeLevelRow_MapSymbol = #249 then
      begin
        { 9A54 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 783, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9A73 } if DecodeLevelRow_MapSymbol = #250 then
      begin
        { 9A85 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 784, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9AA4 } if DecodeLevelRow_MapSymbol = #251 then
      begin
        { 9AB6 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 785, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9AD5 } if DecodeLevelRow_MapSymbol = #252 then
      begin
        { 9AE7 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 786, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9B06 } if DecodeLevelRow_MapSymbol = #253 then
      begin
        { 9B18 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 787, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9B38 } if DecodeLevelRow_MapSymbol = #254 then
      begin
        { 9B4A } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 788, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9B69 } if DecodeLevelRow_MapSymbol = 'L' then
      begin
        { 9B7B } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 789, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9B9B } if DecodeLevelRow_MapSymbol = #159 then
      begin
        { 9BAD } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 791, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9BCD } if DecodeLevelRow_MapSymbol = #160 then
      begin
        { 9BDF } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 792, 0, 0, Ord(True), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9BFE } if DecodeLevelRow_MapSymbol = #161 then
      begin
        { 9C10 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, LevelBackdropTile, 793, 0, Ord(True),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9C30 } if DecodeLevelRow_MapSymbol = 'S' then
      begin
        { 9C42 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 790, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9C62 } if DecodeLevelRow_MapSymbol = 'Z' then
      begin
        { 9C77 } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), (DecodeLevelRow_TileRow - 1), 2, 795, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 9C9B } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, (DecodeLevelRow_TileRow - 1), 2, 796, 0, Ord(False),
        Ord(True), Ord(DecodeLevelRow_ForegroundOnly));
        { 9CBD } SetAndDrawLevelCell((DecodeLevelRow_TileColumn - 1), DecodeLevelRow_TileRow, 2, 799, 0, Ord(False),
        Ord(False), Ord(DecodeLevelRow_ForegroundOnly));
        { 9CDF } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 800, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
      end;
      { 9CFF } if DecodeLevelRow_MapSymbol = #167 then
      begin
        { 9D14 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
        { 9D33 } Inc(LoadedActorCount);
        { 9D37 } PgBlitMaskedShifted16x16(SpriteBank651^.SpriteEntries[25].SpriteDataBytes[1], (DecodeLevelRow_TileColumn *
        16), ((DecodeLevelRow_TileRow * 16) + 16));
        { 9D5B } PgBlitMaskedShifted16x16(SpriteBank651^.SpriteEntries[25].SpriteDataBytes[1], (DecodeLevelRow_TileColumn *
        16), ((DecodeLevelRow_TileRow * 16) + 416));
        { 9D7F } GameActors[LoadedActorCount].FlashFrames := 0;
        { 9D8D } GameActors[LoadedActorCount].ActorSpriteBase := 675;
        { 9D9B } GameActors[LoadedActorCount].ActorWorldX := (DecodeLevelRow_TileColumn * 16);
        { 9DAF } GameActors[LoadedActorCount].ActorWorldY := (DecodeLevelRow_TileRow * 16);
        { 9DC3 } GameActors[LoadedActorCount].ActorPreviousX := (DecodeLevelRow_TileColumn * 16);
        { 9DD7 } GameActors[LoadedActorCount].ActorPreviousY := (DecodeLevelRow_TileRow * 16);
        { 9DEB } GameActors[LoadedActorCount].ActorDirectionX := 1;
        { 9DF9 } GameActors[LoadedActorCount].DirectionY := 0;
        { 9E07 } GameActors[LoadedActorCount].ActorAnimationCounter := 1;
        { 9E15 } GameActors[LoadedActorCount].ActorMovementStep := 0;
        { 9E23 } GameActors[LoadedActorCount].ActorCounterA := 0;
        { 9E31 } GameActors[LoadedActorCount].ActorCounterB := 0;
        { 9E3F } GameActors[LoadedActorCount].ActorKindCode := 27;
        { 9E4D } GameActors[LoadedActorCount].ActorSlotInactive := 0;
        { 9E5A } GameActors[LoadedActorCount].ActorRemovalPending := 0;
      end;
      { 9E67 } if DecodeLevelRow_MapSymbol = 'b' then
      begin
        { 9E7C } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 0, Ord(False), Ord(False),
        Ord(DecodeLevelRow_ForegroundOnly));
        { 9E9B } Inc(LoadedActorCount);
        { 9E9F } PgBlitMaskedShifted16x16(SpriteBank651^.SpriteEntries[26].SpriteDataBytes[1], (DecodeLevelRow_TileColumn *
        16), ((DecodeLevelRow_TileRow * 16) + 16));
        { 9EC3 } PgBlitMaskedShifted16x16(SpriteBank651^.SpriteEntries[26].SpriteDataBytes[1], (DecodeLevelRow_TileColumn *
        16), ((DecodeLevelRow_TileRow * 16) + 416));
        { 9EE7 } GameActors[LoadedActorCount].FlashFrames := 0;
        { 9EF5 } GameActors[LoadedActorCount].ActorSpriteBase := 676;
        { 9F03 } GameActors[LoadedActorCount].ActorWorldX := (DecodeLevelRow_TileColumn * 16);
        { 9F17 } GameActors[LoadedActorCount].ActorWorldY := (DecodeLevelRow_TileRow * 16);
        { 9F2B } GameActors[LoadedActorCount].ActorPreviousX := (DecodeLevelRow_TileColumn * 16);
        { 9F3F } GameActors[LoadedActorCount].ActorPreviousY := (DecodeLevelRow_TileRow * 16);
        { 9F53 } if Random(2) > 0 then
        begin
          { 9F60 } GameActors[LoadedActorCount].ActorDirectionX := 1;
        end
        else
        begin
          { 9F70 } GameActors[LoadedActorCount].ActorDirectionX := -1;
        end;
        { 9F7E } GameActors[LoadedActorCount].DirectionY := 0;
        { 9F8C } GameActors[LoadedActorCount].ActorAnimationCounter := 1;
        { 9F9A } GameActors[LoadedActorCount].ActorMovementStep := 2;
        { 9FA8 } GameActors[LoadedActorCount].ActorCounterA := 0;
        { 9FB6 } GameActors[LoadedActorCount].ActorCounterB := 0;
        { 9FC4 } GameActors[LoadedActorCount].ActorKindCode := 28;
        { 9FD2 } GameActors[LoadedActorCount].ActorSlotInactive := 0;
        { 9FDF } GameActors[LoadedActorCount].ActorRemovalPending := 0;
      end;
    end;
    { 9FEC } DecodeIslandSymbol(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, DecodeLevelRow_MapSymbol);
    { 9FFC } if DecodeLevelRow_MapSymbol = 'Y' then
    begin
      { A011 } SetAndDrawLevelCell(DecodeLevelRow_TileColumn, DecodeLevelRow_TileRow, 2, 0, 0, Ord(False), Ord(False),
      Ord(DecodeLevelRow_ForegroundOnly));
      { A030 } SavedStartColumn := DecodeLevelRow_TileColumn;
      { A037 } SavedStartRow := DecodeLevelRow_TileRow;
      { A03E } if GameSnapshot.SavedPlayerX <> 0 then
      begin
        { A045 } if CurrentLevelNumber = 1 then
        begin
          { A04C } DecodeLevelRow_TileColumn := (GameSnapshot.SavedPlayerX shr 4);
          { A057 } DecodeLevelRow_TileRow := (GameSnapshot.SavedPlayerY shr 4);
        end;
      end;
      { A062 } PgBlitMaskedShifted16x16(PlayerSpriteBank^.SpriteEntries[1].SpriteDataBytes[1], (DecodeLevelRow_TileColumn *
      16), ((DecodeLevelRow_TileRow * 16) + 16));
      { A086 } PgBlitMaskedShifted16x16(PlayerSpriteBank^.SpriteEntries[1].SpriteDataBytes[1], (DecodeLevelRow_TileColumn *
      16), ((DecodeLevelRow_TileRow * 16) + 416));
      { A0AA } GameActors[1].FlashFrames := 0;
      { A0AF } GameActors[1].ActorSpriteBase := 9;
      { A0B5 } GameActors[1].ActorWorldX := (DecodeLevelRow_TileColumn * 16);
      { A0C0 } GameActors[1].ActorWorldY := (DecodeLevelRow_TileRow * 16);
      { A0CB } GameActors[1].ActorPreviousX := (DecodeLevelRow_TileColumn * 16);
      { A0D6 } GameActors[1].ActorPreviousY := (DecodeLevelRow_TileRow * 16);
      { A0E1 } GameActors[1].ActorDirectionX := 1;
      { A0E7 } GameActors[1].DirectionY := 0;
      { A0EC } GameActors[1].ActorAnimationCounter := 1;
      { A0F2 } GameActors[1].ActorMovementStep := 2;
      { A0F8 } GameActors[1].ActorCounterA := 0;
      { A0FD } GameActors[1].ActorKindCode := 99;
      { A103 } GameActors[1].ActorSlotInactive := 0;
      { A108 } GameActors[1].ActorRemovalPending := 0;
      { A10D } CameraX := ((DecodeLevelRow_TileColumn * 16) - 160);
      { A11B } if CameraX < 0 then
      begin
        { A122 } CameraX := 0;
      end;
      { A127 } if CameraX > 320 then
      begin
        { A12F } CameraX := 320;
      end;
      { A135 } CameraY := ((DecodeLevelRow_TileRow * 16) - 100);
      { A143 } if CameraY < 0 then
      begin
        { A14A } CameraY := 0;
      end;
      { A14F } if CameraY > 184 then
      begin
        { A157 } CameraY := 184;
      end;
      { A15D } if AlternateVideoTiming = 0 then
      begin
        { A164 } PgPanDisplayAtRetraceStart(CameraX, (CameraY + 16));
      end
      else
      begin
        { A176 } PgPanDisplayAtRetraceEnd(CameraX, (CameraY + 16));
      end;
      { A186 } DecodeLevelRow_TileColumn := SavedStartColumn;
      { A18D } DecodeLevelRow_TileRow := SavedStartRow;
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Reads/decrypts SAMn03.GFX 42-byte records; each level uses a 48-record slot, with backdrop header. }
procedure LoadLevelMap(LevelNumber: Integer);
var
  LoadIndex: Integer;
  LevelFile: TLevelFileAccess;
  LoadLevelMap_EncodedRow: TLevelFileRow;
  BackdropText: String[40];
begin
  LoadedActorCount := 1;
  PgCopyStatusBandTemplate;
  StatusBarCameraX := -1;
  for LoadIndex := 2 to 25 do
  begin
    GameActors[LoadIndex].FlashFrames := 0;
    GameActors[LoadIndex].ActorSpriteBase := 9;
    GameActors[LoadIndex].ActorWorldX := -41;
    GameActors[LoadIndex].ActorWorldY := 0;
    GameActors[LoadIndex].ActorPreviousX := -41;
    GameActors[LoadIndex].ActorPreviousY := 0;
    GameActors[LoadIndex].ActorDirectionX := 1;
    GameActors[LoadIndex].DirectionY := 0;
    GameActors[LoadIndex].ActorAnimationCounter := 1;
    GameActors[LoadIndex].ActorMovementStep := 1;
    GameActors[LoadIndex].ActorCounterA := 0;
    GameActors[LoadIndex].ActorCounterB := 0;
    GameActors[LoadIndex].ActorKindValue1 := 0;
    GameActors[LoadIndex].StateValueB := 0;
    GameActors[LoadIndex].ActorKindCode := 1;
    GameActors[LoadIndex].ActorSlotInactive := 1;
    GameActors[LoadIndex].ActorRemovalPending := 1;
  end;
  for LoadIndex := 1 to 10 do
  begin
    PlayerShots[LoadIndex].ActorSpriteBase := 7;
    PlayerShots[LoadIndex].ActorWorldX := -41;
    PlayerShots[LoadIndex].ActorWorldY := 0;
    PlayerShots[LoadIndex].ActorPreviousX := -41;
    PlayerShots[LoadIndex].ActorPreviousY := 0;
    PlayerShots[LoadIndex].ActorDirectionX := 1;
    PlayerShots[LoadIndex].DirectionY := 0;
    PlayerShots[LoadIndex].ActorAnimationCounter := 1;
    PlayerShots[LoadIndex].ActorMovementStep := 8;
    PlayerShots[LoadIndex].ActorCounterA := 0;
    PlayerShots[LoadIndex].ActorKindCode := 1;
    PlayerShots[LoadIndex].ActorSlotInactive := 1;
    PlayerShots[LoadIndex].ActorRemovalPending := 0;
  end;
  LevelBlueprintFlags[LevelNumber] := 0;
  if IOResult <> 0 then ;
  case LevelNumber of
    1: begin
    IslandEntranceIndex := 0;
{$IFDEF SAM1}
    Assign(LevelFile.RawFile, 'SAM103.GFX');
{$ENDIF}
{$IFDEF SAM2}
    Assign(LevelFile.RawFile, 'SAM203.GFX');
{$ENDIF}
{$IFDEF SAM3}
    Assign(LevelFile.RawFile, 'SAM303.GFX');
{$ENDIF}
    Reset(LevelFile.RawFile, 42);
    Read(LevelFile.RowFile, LoadLevelMap_EncodedRow);
    DecryptGameAssetBuffer(LoadLevelMap_EncodedRow, 40);
    BackdropText := LoadLevelMap_EncodedRow[1] + LoadLevelMap_EncodedRow[2] + LoadLevelMap_EncodedRow[3];
    Val(BackdropText, LevelBackdropTile, LoadIndex);
    Read(LevelFile.RowFile, LoadLevelMap_EncodedRow);
    DecryptGameAssetBuffer(LoadLevelMap_EncodedRow, 40);
    DecodeLevelRow(24, LoadLevelMap_EncodedRow);
    for LoadIndex := 0 to 23 do
    begin
      Read(LevelFile.RowFile, LoadLevelMap_EncodedRow);
      DecryptGameAssetBuffer(LoadLevelMap_EncodedRow, 40);
      if LoadLevelMap_EncodedRow[1] = '*' then
        Dec(LoadIndex);
      DecodeLevelRow(LoadIndex, LoadLevelMap_EncodedRow);
    end;
    Close(LevelFile.RawFile);
    end;
    2..17: begin
{$IFDEF SAM1}
    Assign(LevelFile.RawFile, 'SAM103.GFX');
{$ENDIF}
{$IFDEF SAM2}
    Assign(LevelFile.RawFile, 'SAM203.GFX');
{$ENDIF}
{$IFDEF SAM3}
    Assign(LevelFile.RawFile, 'SAM303.GFX');
{$ENDIF}
    Reset(LevelFile.RawFile, 42);
    for LoadIndex := 1 to (LevelNumber - 1) * 48 do
      Read(LevelFile.RowFile, LoadLevelMap_EncodedRow);
    Read(LevelFile.RowFile, LoadLevelMap_EncodedRow);
    DecryptGameAssetBuffer(LoadLevelMap_EncodedRow, 40);
    BackdropText := LoadLevelMap_EncodedRow[1] + LoadLevelMap_EncodedRow[2] + LoadLevelMap_EncodedRow[3];
    Val(BackdropText, LevelBackdropTile, LoadIndex);
    Read(LevelFile.RowFile, LoadLevelMap_EncodedRow);
    DecryptGameAssetBuffer(LoadLevelMap_EncodedRow, 40);
    DecodeLevelRow(24, LoadLevelMap_EncodedRow);
    for LoadIndex := 0 to 23 do
    begin
      Read(LevelFile.RowFile, LoadLevelMap_EncodedRow);
      DecryptGameAssetBuffer(LoadLevelMap_EncodedRow, 40);
      if LoadLevelMap_EncodedRow[1] = '*' then
        Dec(LoadIndex);
      DecodeLevelRow(LoadIndex, LoadLevelMap_EncodedRow);
    end;
    Close(LevelFile.RawFile);
    end;
  end;
  PgSetDrawColor(0);
  PgFillRectangleByteAligned(0, 80, 0, 8);
  RestoreGamePalette(20);
  StartSoundEffect(13);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{ Empty begin/end unit initialization body. }
begin
end.
