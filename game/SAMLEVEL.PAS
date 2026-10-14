{ Level unit: reads encoded maps, places actors and draws tile layers
  for the island map and missions. }
unit SAMLEVEL;
{$A+}{$D+}{$L+}{$F-}
interface
uses SAMDATA;
var
  LevelCells: array[1..GameMapColumnCount, 1..GameMapRowCount] of TLevelCell;
procedure RedrawLevelCell(WorldX, WorldY: Integer);
procedure DrawLevelCellResolved(WorldX, WorldY: Integer);
procedure DrawCellForeground(WorldX, WorldY: Integer);
procedure SetAndDrawLevelCell(TileColumn, TileRow, BaseTile,
  MiddleTile, FrontTile: Integer; BlocksMovement,
  SupportsLanding, ForegroundOnly: Byte);
procedure DecodeIslandSymbol(TileColumn, TileRow: Integer; MapSymbol: String);
procedure SpawnActorFromMapSymbol(TileColumn, TileRow: Integer;
  MapSymbol: String; ForegroundOnly: Byte);
procedure DecodeLevelRow(TileRow: Integer; EncodedRow: TLevelFileRow);
procedure LoadLevelMap(LevelNumber: Integer);
implementation
uses Dos, PROGRPHX, Crt, SAMSOUND, GAMEJOY, PCXGENUS, TEXT80, SAMUI;

{ Background and foreground tile drawing. }
{$F+}
{ Restores opaque base and masked middle/foreground layers in the selected buffer.
  The original guard checks horizontal bounds and nonnegative Y only; its
  missing upper-row check is preserved for exactness. }
procedure RedrawLevelCell(WorldX, WorldY: Integer);
var
  TileColumn, TileRow, CellColumn, CellRow, VideoByteX, TilePixelY: Integer;
begin
  TileColumn := WorldX shr GameTilePixelShift;
  TileRow := WorldY shr GameTilePixelShift;
  if (TileColumn >= 0) and (TileColumn <= GameMapLastColumn) and (TileRow >= 0) then
  begin
    CellColumn := (WorldX shr GameTilePixelShift) + 1;
    CellRow := (WorldY shr GameTilePixelShift) + 1;
    VideoByteX := TileColumn shl 1;
    TilePixelY := TileRow shl GameTilePixelShift;
    case LevelCells[CellColumn, CellRow].CellBaseTile of
      0: ;
      1..8:
        PgCopyCachedVideoTile16x16(VideoByteX, TilePixelY + GameDrawBufferRow, LevelCells[CellColumn,
          CellRow].CellBaseTile - 1);
      9..50:
        PgBlitOpaque16x16(SpriteBank001^.SpriteEntries[LevelCells[CellColumn,
          CellRow].CellBaseTile].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      101:
        PgCopyCachedVideoTile16x16(VideoByteX, TilePixelY + GameDrawBufferRow, 4);
      100, 102..150:
        PgBlitOpaque16x16(SpriteBank101^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
          100].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      179:
        if GameDrawBufferRow = GamePlayfieldTopBufferRow then
          PgBlitOpaque16x16(SpriteBank151^.SpriteEntries[29].SpriteDataBytes[1], VideoByteX, TilePixelY +
            GameDrawBufferRow)
        else
          PgBlitOpaque16x16(SpriteBank151^.SpriteEntries[30].SpriteDataBytes[1], VideoByteX, TilePixelY +
            GameDrawBufferRow);
      151..200:
        PgBlitOpaque16x16(SpriteBank151^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
          150].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      201..250:
        PgBlitOpaque16x16(SpriteBank201^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
          200].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      251..300:
        PgBlitOpaque16x16(SpriteBank251^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
          250].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      GameTileAmmo..350:
        PgBlitOpaque16x16(SpriteBank301^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
          300].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      351..400:
        PgBlitOpaque16x16(SpriteBank351^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
          350].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      401..450:
        PgBlitOpaque16x16(SpriteBank401^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
          400].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      499:
        if GameDrawBufferRow = GamePlayfieldTopBufferRow then
          PgBlitOpaque16x16(SpriteBank451^.SpriteEntries[49].SpriteDataBytes[1], VideoByteX, TilePixelY +
            GameDrawBufferRow)
        else
          PgBlitOpaque16x16(SpriteBank451^.SpriteEntries[1].SpriteDataBytes[1], VideoByteX, TilePixelY +
            GameDrawBufferRow);
      451..500:
        PgBlitOpaque16x16(SpriteBank451^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
          450].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      535:
        if GameDrawBufferRow = GamePlayfieldTopBufferRow then
          PgBlitOpaque16x16(SpriteBank001^.SpriteEntries[21].SpriteDataBytes[1], VideoByteX, TilePixelY +
            GameDrawBufferRow)
        else
          PgBlitOpaque16x16(SpriteBank001^.SpriteEntries[35].SpriteDataBytes[1], VideoByteX, TilePixelY +
            GameDrawBufferRow);
      501..550:
        PgBlitOpaque16x16(SpriteBank001^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
          500].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      613:
        if GameDrawBufferRow = GamePlayfieldTopBufferRow then
          PgBlitOpaque16x16(SpriteBank601^.SpriteEntries[13].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl
            GameTilePixelShift) + GameDrawBufferRow)
        else
          PgBlitOpaque16x16(SpriteBank601^.SpriteEntries[17].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl
            GameTilePixelShift) + GameDrawBufferRow);
      601..650:
        PgBlitOpaque16x16(SpriteBank601^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
          600].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      651..700:
        PgBlitOpaque16x16(SpriteBank651^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
          650].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      701..750:
        PgBlitOpaque16x16(SpriteBank701^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
          700].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      751..800:
        PgBlitOpaque16x16(SpriteBank751^.SpriteEntries[LevelCells[CellColumn, CellRow].CellBaseTile -
          750].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
    end;
    case LevelCells[CellColumn, CellRow].CellOverlayTile of
      0: ;
      1..50:
        PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[CellColumn,
          CellRow].CellOverlayTile].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      100..150:
        PgBlitMasked16x16(SpriteBank101^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
          100].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      179:
        if GameDrawBufferRow = GamePlayfieldTopBufferRow then
          PgBlitMasked16x16(SpriteBank151^.SpriteEntries[29].SpriteDataBytes[1], VideoByteX, TilePixelY +
            GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank151^.SpriteEntries[30].SpriteDataBytes[1], VideoByteX, TilePixelY +
            GameDrawBufferRow);
      151..200:
        PgBlitMasked16x16(SpriteBank151^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
          150].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      201..250:
        PgBlitMasked16x16(SpriteBank201^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
          200].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      251..300:
        PgBlitMasked16x16(SpriteBank251^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
          250].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      GameTileAmmo..350:
        PgBlitMasked16x16(SpriteBank301^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
          300].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      351..400:
        PgBlitMasked16x16(SpriteBank351^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
          350].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      401..450:
        PgBlitMasked16x16(SpriteBank401^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
          400].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      499:
        if GameDrawBufferRow = GamePlayfieldTopBufferRow then
          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[49].SpriteDataBytes[1], VideoByteX, TilePixelY +
            GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[1].SpriteDataBytes[1], VideoByteX, TilePixelY +
            GameDrawBufferRow);
      451..500:
        PgBlitMasked16x16(SpriteBank451^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
          450].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      501..550:
        PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
          500].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      613:
        if GameDrawBufferRow = GamePlayfieldTopBufferRow then
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[13].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl
            GameTilePixelShift) + GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[17].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl
            GameTilePixelShift) + GameDrawBufferRow);
      601..650:
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
          600].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      651..700:
        PgBlitMasked16x16(SpriteBank651^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
          650].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      701..750:
        PgBlitMasked16x16(SpriteBank701^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
          700].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      751..800:
        PgBlitMasked16x16(SpriteBank751^.SpriteEntries[LevelCells[CellColumn, CellRow].CellOverlayTile -
          750].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
    end;
    case LevelCells[CellColumn, CellRow].CellObjectCode of
      0: ;
      1..50:
        PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[CellColumn,
          CellRow].CellObjectCode].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      100..150:
        PgBlitMasked16x16(SpriteBank101^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          100].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      179:
        if GameDrawBufferRow = GamePlayfieldTopBufferRow then
          PgBlitMasked16x16(SpriteBank151^.SpriteEntries[29].SpriteDataBytes[1], VideoByteX, TilePixelY +
            GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank151^.SpriteEntries[30].SpriteDataBytes[1], VideoByteX, TilePixelY +
            GameDrawBufferRow);
      151..200:
        PgBlitMasked16x16(SpriteBank151^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          150].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      201..250:
        PgBlitMasked16x16(SpriteBank201^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          200].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      251..300:
        PgBlitMasked16x16(SpriteBank251^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          250].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      GameTileAmmo..350:
        PgBlitMasked16x16(SpriteBank301^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          300].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      351..400:
        PgBlitMasked16x16(SpriteBank351^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          350].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      401..450:
        PgBlitMasked16x16(SpriteBank401^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          400].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      499:
        if GameDrawBufferRow = GamePlayfieldTopBufferRow then
          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[49].SpriteDataBytes[1], VideoByteX, TilePixelY +
            GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[1].SpriteDataBytes[1], VideoByteX, TilePixelY +
            GameDrawBufferRow);
      451..500:
        PgBlitMasked16x16(SpriteBank451^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          450].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      501..550:
        PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          500].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      613:
        if GameDrawBufferRow = GamePlayfieldTopBufferRow then
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[13].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl
            GameTilePixelShift) + GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[17].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl
            GameTilePixelShift) + GameDrawBufferRow);
      601..602:
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          600].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      GameTileLaserField:
        if GameDrawBufferRow = GamePlayfieldBottomBufferRow then
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
            600].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      GameTileComputer..GameTileBonusThird:
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          600].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      624:
        if GameDrawBufferRow = GamePlayfieldBottomBufferRow then
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
            600].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
            582].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      625..650:
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          600].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      651..700:
        PgBlitMasked16x16(SpriteBank651^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          650].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      701..750:
        PgBlitMasked16x16(SpriteBank701^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          700].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
      751..800:
        PgBlitMasked16x16(SpriteBank751^.SpriteEntries[LevelCells[CellColumn, CellRow].CellObjectCode -
          750].SpriteDataBytes[1], VideoByteX, TilePixelY + GameDrawBufferRow);
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}

{$F+}
{ Draws generic backdrop codes using the current level's real images, then
  restores the generic map codes so later collision/redraw logic sees them. }
procedure DrawLevelCellResolved(WorldX, WorldY: Integer);
var
  TileColumn, TileRow: Integer;
begin
  TileColumn := WorldX shr GameTilePixelShift;
  TileRow := WorldY shr GameTilePixelShift;
  if LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile = GameTileBackdropPlaceholder then
    LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile := LevelBackdropTile;
  if LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile = GameTileBackdropPlusOne then
    LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile := LevelBackdropTile + 1;
  if LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile = GameTileBackdropPlusTwo then
    LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile := LevelBackdropTile + 2;
  if LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile = GameTileBackdropPlusThree then
    LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile := LevelBackdropTile + 3;
  if LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile = 8 then
    LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile := 667;
  case LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile of
    1..50:
      PgBlitOpaque16x16(SpriteBank001^.SpriteEntries[LevelCells[TileColumn + 1, TileRow +
        1].CellBaseTile].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    100..150:
      PgBlitOpaque16x16(SpriteBank101^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile -
        100].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    179:
      if GameDrawBufferRow = GamePlayfieldTopBufferRow then
        PgBlitOpaque16x16(SpriteBank151^.SpriteEntries[29].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow)
      else
        PgBlitOpaque16x16(SpriteBank151^.SpriteEntries[30].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow);
    151..200:
      PgBlitOpaque16x16(SpriteBank151^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile -
        150].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    201..250:
      PgBlitOpaque16x16(SpriteBank201^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile -
        200].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    251..300:
      PgBlitOpaque16x16(SpriteBank251^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile -
        250].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    GameTileAmmo..350:
      PgBlitOpaque16x16(SpriteBank301^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile -
        300].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    351..400:
      PgBlitOpaque16x16(SpriteBank351^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile -
        350].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    401..450:
      PgBlitOpaque16x16(SpriteBank401^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile -
        400].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    499:
      if GameDrawBufferRow = GamePlayfieldTopBufferRow then
        PgBlitOpaque16x16(SpriteBank451^.SpriteEntries[49].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow)
      else
        PgBlitOpaque16x16(SpriteBank451^.SpriteEntries[1].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow);
    451..500:
      PgBlitOpaque16x16(SpriteBank451^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile -
        450].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    501..550:
      PgBlitOpaque16x16(SpriteBank001^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile -
        500].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    613:
      if GameDrawBufferRow = GamePlayfieldTopBufferRow then
        PgBlitOpaque16x16(SpriteBank601^.SpriteEntries[13].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow)
      else
        PgBlitOpaque16x16(SpriteBank601^.SpriteEntries[17].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow);
    601..650:
      PgBlitOpaque16x16(SpriteBank601^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile -
        600].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    651..700:
      PgBlitOpaque16x16(SpriteBank651^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile -
        650].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    701..750:
      PgBlitOpaque16x16(SpriteBank701^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile -
        700].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    751..800:
      PgBlitOpaque16x16(SpriteBank751^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile -
        750].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
  end;
  if LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile = LevelBackdropTile then
    LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile := GameTileBackdropPlaceholder;
  if LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile = LevelBackdropTile + 1 then
    LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile := GameTileBackdropPlusOne;
  if LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile = LevelBackdropTile + 2 then
    LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile := GameTileBackdropPlusTwo;
  if LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile = LevelBackdropTile + 3 then
    LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile := GameTileBackdropPlusThree;
  if LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile = 667 then
    LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile := 8;
  case LevelCells[TileColumn + 1, TileRow + 1].CellOverlayTile of
    0: ;
    1..50:
      PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[TileColumn + 1, TileRow +
        1].CellOverlayTile].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels +
        GameDrawBufferRow);
    100..150:
      PgBlitMasked16x16(SpriteBank101^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellOverlayTile -
        100].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    179:
      if GameDrawBufferRow = GamePlayfieldTopBufferRow then
        PgBlitMasked16x16(SpriteBank151^.SpriteEntries[29].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow)
      else
        PgBlitMasked16x16(SpriteBank151^.SpriteEntries[30].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow);
    151..200:
      PgBlitMasked16x16(SpriteBank151^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellOverlayTile -
        150].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    201..250:
      PgBlitMasked16x16(SpriteBank201^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellOverlayTile -
        200].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    251..300:
      PgBlitMasked16x16(SpriteBank251^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellOverlayTile -
        250].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    GameTileAmmo..350:
      PgBlitMasked16x16(SpriteBank301^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellOverlayTile -
        300].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    351..400:
      PgBlitMasked16x16(SpriteBank351^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellOverlayTile -
        350].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    401..450:
      PgBlitMasked16x16(SpriteBank401^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellOverlayTile -
        400].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    499:
      if GameDrawBufferRow = GamePlayfieldTopBufferRow then
        PgBlitMasked16x16(SpriteBank451^.SpriteEntries[49].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow)
      else
        PgBlitMasked16x16(SpriteBank451^.SpriteEntries[1].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow);
    451..500:
      PgBlitMasked16x16(SpriteBank451^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellOverlayTile -
        450].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    501..550:
      PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellOverlayTile -
        500].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    613:
      if GameDrawBufferRow = GamePlayfieldTopBufferRow then
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[13].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow)
      else
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[17].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow);
    601..650:
      PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellOverlayTile -
        600].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    651..700:
      PgBlitMasked16x16(SpriteBank651^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellOverlayTile -
        650].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    701..750:
      PgBlitMasked16x16(SpriteBank701^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellOverlayTile -
        700].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    751..800:
      PgBlitMasked16x16(SpriteBank751^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellOverlayTile -
        750].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
  end;
  case LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode of
    0: ;
    1..50:
      PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[TileColumn + 1, TileRow +
        1].CellObjectCode].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels +
          GameDrawBufferRow);
    100..150:
      PgBlitMasked16x16(SpriteBank101^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
        100].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    179:
      if GameDrawBufferRow = GamePlayfieldTopBufferRow then
        PgBlitMasked16x16(SpriteBank151^.SpriteEntries[29].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow)
      else
        PgBlitMasked16x16(SpriteBank151^.SpriteEntries[30].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow);
    151..200:
      PgBlitMasked16x16(SpriteBank151^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
        150].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    201..250:
      PgBlitMasked16x16(SpriteBank201^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
        200].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    251..300:
      PgBlitMasked16x16(SpriteBank251^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
        250].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    GameTileAmmo..350:
      PgBlitMasked16x16(SpriteBank301^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
        300].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    351..400:
      PgBlitMasked16x16(SpriteBank351^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
        350].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    401..450:
      PgBlitMasked16x16(SpriteBank401^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
        400].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    499:
      if GameDrawBufferRow = GamePlayfieldTopBufferRow then
        PgBlitMasked16x16(SpriteBank451^.SpriteEntries[49].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow)
      else
        PgBlitMasked16x16(SpriteBank451^.SpriteEntries[1].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow);
    451..500:
      PgBlitMasked16x16(SpriteBank451^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
        450].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    501..550:
      PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
        500].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    613:
      if GameDrawBufferRow = GamePlayfieldTopBufferRow then
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[13].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow)
      else
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[17].SpriteDataBytes[1], TileColumn * 2, TileRow *
          GameTileSizePixels + GameDrawBufferRow);
    601..650:
      PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
        600].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    651..700:
      PgBlitMasked16x16(SpriteBank651^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
        650].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    701..750:
      PgBlitMasked16x16(SpriteBank701^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
        700].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
    751..800:
      PgBlitMasked16x16(SpriteBank751^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
        750].SpriteDataBytes[1], TileColumn * 2, TileRow * GameTileSizePixels + GameDrawBufferRow);
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}

{$F+}
{ Draws the CellObjectCode layer after actors so foreground art covers them.
  Some interactive tiles select different images in the two playfield buffers. }
procedure DrawCellForeground(WorldX, WorldY: Integer);
var
  TileColumn, TileRow: Integer;
begin
  TileColumn := WorldX shr GameTilePixelShift;
  TileRow := WorldY shr GameTilePixelShift;
  if (TileColumn >= 0) and (TileColumn <= GameMapLastColumn) and (TileRow >= 0) then
  begin
    case LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode of
      0: ;
      1..50:
        PgBlitMasked16x16(SpriteBank001^.SpriteEntries[LevelCells[TileColumn + 1, TileRow +
          1].CellObjectCode].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) +
          GameDrawBufferRow);
      179:
        if GameDrawBufferRow = GamePlayfieldTopBufferRow then
          PgBlitMasked16x16(SpriteBank151^.SpriteEntries[29].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl
            GameTilePixelShift) + GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank151^.SpriteEntries[30].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl
            GameTilePixelShift) + GameDrawBufferRow);
      100..150:
        PgBlitMasked16x16(SpriteBank101^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
          100].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow);
      151..200:
        PgBlitMasked16x16(SpriteBank151^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
          150].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow);
      201..250:
        PgBlitMasked16x16(SpriteBank201^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
          200].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow);
      251..300:
        PgBlitMasked16x16(SpriteBank251^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
          250].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow);
      GameTileAmmo..350:
        PgBlitMasked16x16(SpriteBank301^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
          300].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow);
      351..400:
        PgBlitMasked16x16(SpriteBank351^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
          350].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow);
      401..450:
        PgBlitMasked16x16(SpriteBank401^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
          400].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow);
      499:
        if GameDrawBufferRow = GamePlayfieldTopBufferRow then
          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[49].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl
            GameTilePixelShift) + GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank451^.SpriteEntries[1].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl
            GameTilePixelShift) + GameDrawBufferRow);
      451..500:
        PgBlitMasked16x16(SpriteBank451^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
          450].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow);
      613:
        if GameDrawBufferRow = GamePlayfieldTopBufferRow then
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[13].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl
            GameTilePixelShift) + GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[17].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl
            GameTilePixelShift) + GameDrawBufferRow);
      601..602:
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
          600].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow);
      GameTileLaserField:
        if GameDrawBufferRow = GamePlayfieldBottomBufferRow then
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode
            - 600].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow);
      GameTileComputer..GameTileBonusThird:
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
          600].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow);
      624:
        if GameDrawBufferRow = GamePlayfieldBottomBufferRow then
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode
            - 600].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow)
        else
          PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode
            - 582].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow);
      625..650:
        PgBlitMasked16x16(SpriteBank601^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
          600].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow);
      651..700:
        PgBlitMasked16x16(SpriteBank651^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
          650].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow);
      701..750:
        PgBlitMasked16x16(SpriteBank701^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
          700].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow);
      751..800:
        PgBlitMasked16x16(SpriteBank751^.SpriteEntries[LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode -
          750].SpriteDataBytes[1], TileColumn shl 1, (TileRow shl GameTilePixelShift) + GameDrawBufferRow);
    end;
  end;
end;

{ Map changes and island-symbol decoding. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Writes cell layers/collision flags (or only foreground on overlay rows) and redraws both buffers at Y. }
procedure SetAndDrawLevelCell(TileColumn, TileRow, BaseTile,
  MiddleTile, FrontTile: Integer; BlocksMovement,
  SupportsLanding, ForegroundOnly: Byte);
begin
  if ForegroundOnly <> 0 then
  begin
    LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode := FrontTile;
    GameDrawBufferRow := GamePlayfieldTopBufferRow;
    DrawCellForeground(TileColumn shl GameTilePixelShift, TileRow shl GameTilePixelShift);
    GameDrawBufferRow := GamePlayfieldBottomBufferRow;
    DrawCellForeground(TileColumn shl GameTilePixelShift, TileRow shl GameTilePixelShift);
    GameDrawBufferRow := GamePlayfieldTopBufferRow;
  end
  else
  begin
    LevelCells[TileColumn + 1, TileRow + 1].CellBaseTile := BaseTile;
    LevelCells[TileColumn + 1, TileRow + 1].CellOverlayTile := MiddleTile;
    LevelCells[TileColumn + 1, TileRow + 1].CellObjectCode := FrontTile;
    LevelCells[TileColumn + 1, TileRow + 1].CellSolidFlag := BlocksMovement;
    LevelCells[TileColumn + 1, TileRow + 1].SupportsLanding := SupportsLanding;
    GameDrawBufferRow := GamePlayfieldTopBufferRow;
    if TileRow = GameMapLastRow then
      DrawLevelCellResolved(TileColumn shl GameTilePixelShift, TileRow shl GameTilePixelShift)
    else
      RedrawLevelCell(TileColumn shl GameTilePixelShift, TileRow shl GameTilePixelShift);
    DrawCellForeground(TileColumn shl GameTilePixelShift, TileRow shl GameTilePixelShift);
    GameDrawBufferRow := GamePlayfieldBottomBufferRow;
    if TileRow = GameMapLastRow then
      DrawLevelCellResolved(TileColumn shl GameTilePixelShift, TileRow shl GameTilePixelShift)
    else
      RedrawLevelCell(TileColumn shl GameTilePixelShift, TileRow shl GameTilePixelShift);
    DrawCellForeground(TileColumn shl GameTilePixelShift, TileRow shl GameTilePixelShift);
    GameDrawBufferRow := GamePlayfieldTopBufferRow;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}

{$F+}
{ When level=1, translates island-map symbols, numbered entrances and completed-level graphics. }
procedure DecodeIslandSymbol(TileColumn, TileRow: Integer; MapSymbol: String);
var
  LevelIndex, CompletedLevelCount: Integer;
  ForegroundOnly: Byte;
begin
  AllMissionsComplete := 0;
  ForegroundOnly := 0;
  CompletedLevelCount := 0;
  for LevelIndex := 2 to GameLastMissionLevel do
    if LevelCompletedFlags[LevelIndex] = 1 then
      Inc(CompletedLevelCount);
  if CompletedLevelCount = GameMissionsForFortress then
    AllMissionsComplete := 1;
  if CurrentLevelNumber = GameIslandLevelNumber then
  begin
    if MapSymbol = 'A' then
      SetAndDrawLevelCell(TileColumn, TileRow, 501, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'B' then
      SetAndDrawLevelCell(TileColumn, TileRow, 502, 0, 0, 1, 0, ForegroundOnly);
    if MapSymbol = 'C' then
      SetAndDrawLevelCell(TileColumn, TileRow, 503, 0, 0, 1, 0, ForegroundOnly);
    if MapSymbol = 'D' then
      SetAndDrawLevelCell(TileColumn, TileRow, 504, 0, 0, 1, 0, ForegroundOnly);
    if MapSymbol = 'E' then
      SetAndDrawLevelCell(TileColumn, TileRow, 505, 0, 0, 1, 0, ForegroundOnly);
    if MapSymbol = 'F' then
      SetAndDrawLevelCell(TileColumn, TileRow, 506, 0, 0, 1, 0, ForegroundOnly);
    if MapSymbol = 'G' then
      SetAndDrawLevelCell(TileColumn, TileRow, 507, 0, 0, 1, 0, ForegroundOnly);
    if MapSymbol = 'H' then
      SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'I' then
      SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'J' then
      SetAndDrawLevelCell(TileColumn, TileRow, 661, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'K' then
      SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'L' then
      SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'M' then
    begin
      if LevelCompletedFlags[IslandEntranceIndex + 2] <> 0 then
        SetAndDrawLevelCell(TileColumn, TileRow, IslandEntranceIndex + 2, 0, 517, 0, 0, ForegroundOnly)
      else
        SetAndDrawLevelCell(TileColumn, TileRow, IslandEntranceIndex + 2, 0, 513, 0, 0, ForegroundOnly);
    end;
    if MapSymbol = 'N' then
    begin
      if LevelCompletedFlags[IslandEntranceIndex + 2] <> 0 then
        SetAndDrawLevelCell(TileColumn, TileRow, IslandEntranceIndex + 2, 0, 518, 0, 0, ForegroundOnly)
      else
        SetAndDrawLevelCell(TileColumn, TileRow, IslandEntranceIndex + 2, 0, 514, 0, 0, ForegroundOnly);
      Inc(IslandEntranceIndex);
    end;
    if MapSymbol = 'O' then
    begin
      if LevelCompletedFlags[IslandEntranceIndex + 2] <> 0 then
        SetAndDrawLevelCell(TileColumn, TileRow, IslandEntranceIndex + 2, 0, 519, 0, 0, ForegroundOnly)
      else
        SetAndDrawLevelCell(TileColumn, TileRow, IslandEntranceIndex + 2, 0, 515, 0, 0, ForegroundOnly);
      Inc(IslandEntranceIndex);
    end;
    if MapSymbol = 'P' then
    begin
      if LevelCompletedFlags[IslandEntranceIndex + 2] <> 0 then
        SetAndDrawLevelCell(TileColumn, TileRow, IslandEntranceIndex + 2, 0, 520, 0, 0, ForegroundOnly)
      else
        SetAndDrawLevelCell(TileColumn, TileRow, IslandEntranceIndex + 2, 0, 516, 0, 0, ForegroundOnly);
      Inc(IslandEntranceIndex);
    end;
    if MapSymbol = 'Q' then
      SetAndDrawLevelCell(TileColumn, TileRow, 517, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'R' then
      SetAndDrawLevelCell(TileColumn, TileRow, 518, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'S' then
      SetAndDrawLevelCell(TileColumn, TileRow, 519, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'T' then
      SetAndDrawLevelCell(TileColumn, TileRow, 520, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'U' then
      SetAndDrawLevelCell(TileColumn, TileRow, 521, 0, 0, 1, 0, ForegroundOnly);
    if MapSymbol = 'V' then
      SetAndDrawLevelCell(TileColumn, TileRow, 522, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'W' then
      SetAndDrawLevelCell(TileColumn, TileRow, 523, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'X' then
      SetAndDrawLevelCell(TileColumn, TileRow, 524, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = '0' then
      SetAndDrawLevelCell(TileColumn, TileRow, 525, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'Z' then
      SetAndDrawLevelCell(TileColumn, TileRow, 526, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'a' then
      SetAndDrawLevelCell(TileColumn, TileRow, 527, 0, 0, 1, 0, ForegroundOnly);
    if MapSymbol = 'b' then
      SetAndDrawLevelCell(TileColumn, TileRow, 528, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'c' then
      SetAndDrawLevelCell(TileColumn, TileRow, 529, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'd' then
      SetAndDrawLevelCell(TileColumn, TileRow, 530, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'e' then
      SetAndDrawLevelCell(TileColumn, TileRow, 531, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'f' then
      SetAndDrawLevelCell(TileColumn, TileRow, 532, 0, 0, 1, 0, ForegroundOnly);
    if MapSymbol = 'g' then
      SetAndDrawLevelCell(TileColumn, TileRow, 533, 0, 0, 1, 0, ForegroundOnly);
    if MapSymbol = 'h' then
      SetAndDrawLevelCell(TileColumn, TileRow, 534, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'i' then
      SetAndDrawLevelCell(TileColumn, TileRow, 535, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'j' then
      SetAndDrawLevelCell(TileColumn, TileRow, 536, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'k' then
      SetAndDrawLevelCell(TileColumn, TileRow, 537, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'l' then
    begin
      if AllMissionsComplete = 0 then
        SetAndDrawLevelCell(TileColumn, TileRow, 508, 0, 0, 1, 0, ForegroundOnly)
      else
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 0, 0, 0, ForegroundOnly);
    end;
    if MapSymbol = 'm' then
      SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 665, 0, 0, ForegroundOnly);
    if MapSymbol = 'n' then
      SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 666, 0, 0, ForegroundOnly);
    if MapSymbol = 'o' then
      SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 671, 0, 0, 1, ForegroundOnly);
    if MapSymbol = 'p' then
      SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 672, 0, 0, 1, ForegroundOnly);
    if MapSymbol = 'q' then
      SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 673, 0, 0, 1, ForegroundOnly);
    if MapSymbol = 'r' then
      SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 674, 0, 0, 1, ForegroundOnly);
    if MapSymbol = 's' then
      SetAndDrawLevelCell(TileColumn, TileRow, 683, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 't' then
      SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 684, 0, 0, ForegroundOnly);
    if MapSymbol = 'u' then
      SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 685, 0, 0, ForegroundOnly);
    if MapSymbol = 'v' then
      SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 686, 0, 0, ForegroundOnly);
    if MapSymbol = 'x' then
      SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 688, 0, 0, ForegroundOnly);
    if MapSymbol = 'y' then
      SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 689, 0, 0, ForegroundOnly);
    if MapSymbol = 'z' then
      SetAndDrawLevelCell(TileColumn, TileRow, 690, 0, 0, 0, 0, ForegroundOnly);
    if MapSymbol = 'w' then
      SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 687, 0, 0, ForegroundOnly);
    { Original duplicate 'w' dispatch preserved: the earlier call draws 687,
      then these calls overwrite the cell and its upper teleporter half. }
    if MapSymbol = 'w' then
    begin
      SetAndDrawLevelCell(TileColumn, TileRow - 1, GameTileBackdropPlaceholder, 0, 179, 1, 0, ForegroundOnly);
      SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileTeleportPad, 0, 0,
        ForegroundOnly);
    end;
  end;
end;

{ Actor placement from mission symbols. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Creates mission actors from encoded map characters and draws their first pose
  in both buffers. LoadedActorCount advances without a capacity check; the
  original placement behavior is preserved. }
procedure SpawnActorFromMapSymbol(TileColumn, TileRow: Integer;
  MapSymbol: String; ForegroundOnly: Byte);
begin
  if MapSymbol = #174 then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank851^.SpriteEntries[13].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank851^.SpriteEntries[13].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    PgBlitMaskedShifted16x16(SpriteBank851^.SpriteEntries[9].SpriteDataBytes[1], ((TileColumn + 1) *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank851^.SpriteEntries[9].SpriteDataBytes[1], ((TileColumn + 1) *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 851;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    if Random(2) > 0 then
    begin
      GameActors[LoadedActorCount].ActorDirectionX := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorDirectionX := -1;
    end;
    GameActors[LoadedActorCount].DirectionY := 0;
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 41;
    end;
    GameActors[LoadedActorCount].ActorMovementStep := 2;
    GameActors[LoadedActorCount].ActorCounterA := 0;
    GameActors[LoadedActorCount].ActorCounterB := 0;
    GameActors[LoadedActorCount].ActorKindValue1 := 3;
    GameActors[LoadedActorCount].ActorKindCode := 42;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = '8' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank351^.SpriteEntries[1].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank351^.SpriteEntries[1].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 351;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    if Random(2) > 0 then
    begin
      GameActors[LoadedActorCount].ActorDirectionX := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorDirectionX := -1;
    end;
    GameActors[LoadedActorCount].DirectionY := 0;
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 21;
    end;
    GameActors[LoadedActorCount].ActorMovementStep := 1;
    GameActors[LoadedActorCount].ActorCounterA := 0;
    GameActors[LoadedActorCount].ActorCounterB := 0;
    GameActors[LoadedActorCount].ActorKindCode := 1;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = '9' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank351^.SpriteEntries[9].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank351^.SpriteEntries[9].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 359;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    if Random(2) > 0 then
    begin
      GameActors[LoadedActorCount].ActorDirectionX := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorDirectionX := -1;
    end;
    GameActors[LoadedActorCount].DirectionY := 0;
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 21;
    end;
    GameActors[LoadedActorCount].ActorMovementStep := 1;
    GameActors[LoadedActorCount].ActorCounterA := 0;
    GameActors[LoadedActorCount].ActorKindCode := 2;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = '0' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank351^.SpriteEntries[17].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank351^.SpriteEntries[17].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 367;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    if Random(2) > 0 then
    begin
      GameActors[LoadedActorCount].ActorDirectionX := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorDirectionX := -1;
    end;
    GameActors[LoadedActorCount].DirectionY := 0;
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 21;
    end;
    GameActors[LoadedActorCount].ActorMovementStep := 2;
    GameActors[LoadedActorCount].ActorCounterA := 0;
    GameActors[LoadedActorCount].ActorKindCode := 3;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = 'g' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank351^.SpriteEntries[25].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank351^.SpriteEntries[25].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 375;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    if Random(2) > 0 then
    begin
      GameActors[LoadedActorCount].ActorDirectionX := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorDirectionX := -1;
    end;
    GameActors[LoadedActorCount].DirectionY := 0;
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 21;
    end;
    GameActors[LoadedActorCount].ActorMovementStep := 2;
    GameActors[LoadedActorCount].ActorCounterA := (Random(50) + 50);
    GameActors[LoadedActorCount].ActorCounterB := 0;
    GameActors[LoadedActorCount].ActorKindCode := 4;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = 'G' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank351^.SpriteEntries[33].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank351^.SpriteEntries[33].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 383;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    if Random(2) > 0 then
    begin
      GameActors[LoadedActorCount].ActorDirectionX := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorDirectionX := -1;
    end;
    GameActors[LoadedActorCount].DirectionY := 0;
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 21;
    end;
    GameActors[LoadedActorCount].ActorMovementStep := 2;
    GameActors[LoadedActorCount].ActorCounterA := (Random(20) + 30);
    GameActors[LoadedActorCount].ActorCounterB := 0;
    GameActors[LoadedActorCount].ActorKindCode := 5;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = 'V' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[1].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), (((TileRow * GameTileSizePixels) + 16) - 16));
    PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[1].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), (((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow) - 16));
    PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[5].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[5].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 801;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    if Random(2) > 0 then
    begin
      GameActors[LoadedActorCount].ActorDirectionX := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorDirectionX := -1;
    end;
    GameActors[LoadedActorCount].DirectionY := 0;
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 41;
    end;
    GameActors[LoadedActorCount].ActorMovementStep := 2;
    GameActors[LoadedActorCount].ActorCounterA := (Random(20) + 30);
    GameActors[LoadedActorCount].ActorCounterB := 0;
    GameActors[LoadedActorCount].ActorKindValue1 := 3;
    GameActors[LoadedActorCount].ActorKindCode := 30;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = 'X' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[17].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), (((TileRow * GameTileSizePixels) + 16) - 16));
    PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[17].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), (((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow) - 16));
    PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[21].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[21].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 817;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    if Random(2) > 0 then
    begin
      GameActors[LoadedActorCount].ActorDirectionX := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorDirectionX := -1;
    end;
    GameActors[LoadedActorCount].DirectionY := 0;
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 61;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    end;
    GameActors[LoadedActorCount].ActorMovementStep := 2;
    GameActors[LoadedActorCount].ActorCounterA := 60;
    GameActors[LoadedActorCount].ActorCounterB := 0;
    GameActors[LoadedActorCount].ActorKindValue1 := 3;
    GameActors[LoadedActorCount].StateValueB := (Random(20) + 60);
    GameActors[LoadedActorCount].ActorKindCode := 31;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = '#' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank151^.SpriteEntries[1].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank151^.SpriteEntries[1].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 151;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorDirectionX := 1;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    GameActors[LoadedActorCount].ActorMovementStep := 0;
    GameActors[LoadedActorCount].ActorCounterA := 3;
    GameActors[LoadedActorCount].ActorKindCode := 32;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = 'c' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[41].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), (((TileRow * GameTileSizePixels) + 16) - 16));
    PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[41].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), (((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow) - 16));
    PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[41].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank801^.SpriteEntries[41].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 837;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    if Random(2) > 0 then
    begin
      GameActors[LoadedActorCount].ActorDirectionX := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorDirectionX := -1;
    end;
    GameActors[LoadedActorCount].DirectionY := 0;
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 21;
    end;
    GameActors[LoadedActorCount].ActorMovementStep := 2;
    GameActors[LoadedActorCount].ActorCounterA := (Random(20) + 30);
    GameActors[LoadedActorCount].ActorCounterB := 0;
    GameActors[LoadedActorCount].ActorKindValue1 := 3;
    GameActors[LoadedActorCount].ActorKindCode := 33;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = 'e' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[17].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[17].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 117;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    if Random(2) > 0 then
    begin
      GameActors[LoadedActorCount].ActorDirectionX := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorDirectionX := -1;
    end;
    GameActors[LoadedActorCount].DirectionY := 0;
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 21;
    end;
    GameActors[LoadedActorCount].ActorMovementStep := 2;
    GameActors[LoadedActorCount].ActorCounterA := 0;
    GameActors[LoadedActorCount].ActorCounterB := 0;
    GameActors[LoadedActorCount].ActorKindValue1 := 3;
    GameActors[LoadedActorCount].ActorKindCode := 34;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = 'u' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[9].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[9].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 109;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorDirectionX := 1;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    GameActors[LoadedActorCount].ActorMovementStep := 0;
    GameActors[LoadedActorCount].ActorCounterA := 0;
    GameActors[LoadedActorCount].ActorCounterB := 0;
    GameActors[LoadedActorCount].ActorKindValue1 := 3;
    GameActors[LoadedActorCount].ActorKindCode := 35;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = 'v' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[13].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[13].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 113;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorDirectionX := 1;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    GameActors[LoadedActorCount].ActorMovementStep := 0;
    GameActors[LoadedActorCount].ActorCounterA := 0;
    GameActors[LoadedActorCount].ActorCounterB := 10;
    GameActors[LoadedActorCount].ActorKindValue1 := 10;
    GameActors[LoadedActorCount].ActorKindCode := 36;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = 'n' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[33].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[33].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 133;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    if Random(2) > 0 then
    begin
      GameActors[LoadedActorCount].ActorDirectionX := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorDirectionX := -1;
    end;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    GameActors[LoadedActorCount].ActorMovementStep := 2;
    GameActors[LoadedActorCount].ActorCounterA := (Random(20) + 30);
    GameActors[LoadedActorCount].ActorCounterB := 0;
    GameActors[LoadedActorCount].ActorKindValue1 := 3;
    GameActors[LoadedActorCount].StateValueB := (Random(50) + 100);
    GameActors[LoadedActorCount].ActorKindCode := 38;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = '$' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[1].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), (((TileRow * GameTileSizePixels) + 16) - 16));
    PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[1].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), (((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow) - 16));
    PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[5].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank101^.SpriteEntries[5].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 101;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    if Random(2) > 0 then
    begin
      GameActors[LoadedActorCount].ActorDirectionX := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorDirectionX := -1;
    end;
    GameActors[LoadedActorCount].DirectionY := 0;
    if GameActors[LoadedActorCount].ActorDirectionX = 1 then
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 201;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    end;
    GameActors[LoadedActorCount].ActorMovementStep := 2;
    GameActors[LoadedActorCount].ActorCounterA := 60;
    GameActors[LoadedActorCount].ActorCounterB := 0;
    GameActors[LoadedActorCount].ActorKindValue1 := 3;
    GameActors[LoadedActorCount].StateValueB := (Random(20) + 60);
    GameActors[LoadedActorCount].ActorKindCode := 39;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = '[' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 435;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorDirectionX := 0;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    GameActors[LoadedActorCount].ActorMovementStep := 0;
    GameActors[LoadedActorCount].ActorCounterA := 0;
    GameActors[LoadedActorCount].ActorCounterB := 0;
    GameActors[LoadedActorCount].ActorKindValue1 := 0;
    GameActors[LoadedActorCount].StateValueB := 0;
    GameActors[LoadedActorCount].ActorKindCode := 41;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = #127 then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank601^.SpriteEntries[9].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank601^.SpriteEntries[9].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 609;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    if Random(2) > 0 then
    begin
      GameActors[LoadedActorCount].ActorDirectionX := 1;
    end
    else
    begin
      GameActors[LoadedActorCount].ActorDirectionX := -1;
    end;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    GameActors[LoadedActorCount].ActorMovementStep := 2;
    GameActors[LoadedActorCount].ActorCounterA := 2;
    GameActors[LoadedActorCount].ActorCounterB := 11;
    GameActors[LoadedActorCount].ActorKindCode := 6;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = 'R' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 464, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[14].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[14].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 464;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorDirectionX := 1;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    GameActors[LoadedActorCount].ActorMovementStep := 0;
    GameActors[LoadedActorCount].ActorCounterA := (Random(20) + 55);
    GameActors[LoadedActorCount].ActorCounterB := 0;
    GameActors[LoadedActorCount].ActorKindCode := 10;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = 'Q' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 465, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[15].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[15].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 465;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorDirectionX := 1;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    GameActors[LoadedActorCount].ActorMovementStep := 0;
    GameActors[LoadedActorCount].ActorCounterA := (Random(20) + 55);
    GameActors[LoadedActorCount].ActorCounterB := 0;
    GameActors[LoadedActorCount].ActorKindCode := 11;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = '<' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 487, 1, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[37].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[37].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 487;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorDirectionX := 1;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    GameActors[LoadedActorCount].ActorMovementStep := 0;
    GameActors[LoadedActorCount].ActorCounterA := (Random(20) + 55);
    GameActors[LoadedActorCount].ActorCounterB := 0;
    GameActors[LoadedActorCount].ActorKindCode := 12;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = '=' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 491, 1, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[41].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[41].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 491;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorDirectionX := 1;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    GameActors[LoadedActorCount].ActorMovementStep := 0;
    GameActors[LoadedActorCount].ActorCounterA := (Random(20) + 55);
    GameActors[LoadedActorCount].ActorCounterB := 0;
    GameActors[LoadedActorCount].ActorKindCode := 13;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = ';' then
  begin
    SetAndDrawLevelCell(TileColumn, (TileRow - 2), GameTileBackdropPlaceholder, 0, 428, 1, 0, 0);
    SetAndDrawLevelCell(TileColumn, (TileRow - 1), GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 427, 1, 0, 0);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank401^.SpriteEntries[28].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), (((TileRow - 2) * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank401^.SpriteEntries[28].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), (((TileRow - 2) * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    PgBlitMaskedShifted16x16(SpriteBank401^.SpriteEntries[27].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank401^.SpriteEntries[27].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 435;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := ((TileRow - 1) * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := ((TileRow - 1) * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorDirectionX := 1;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    GameActors[LoadedActorCount].ActorMovementStep := 0;
    GameActors[LoadedActorCount].ActorCounterA := 30;
    GameActors[LoadedActorCount].ActorCounterB := Random(30);
    GameActors[LoadedActorCount].ActorKindCode := 15;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = '>' then
  begin
    SetAndDrawLevelCell((TileColumn - 2), TileRow, GameTileBackdropPlaceholder, 0, 433, 1, 0, ForegroundOnly);
    SetAndDrawLevelCell((TileColumn - 1), TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 434, 1, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    PgBlitMaskedShifted16x16(SpriteBank401^.SpriteEntries[33].SpriteDataBytes[1], ((TileColumn - 2) *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank401^.SpriteEntries[33].SpriteDataBytes[1], ((TileColumn - 2) *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    PgBlitMaskedShifted16x16(SpriteBank401^.SpriteEntries[34].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
    PgBlitMaskedShifted16x16(SpriteBank401^.SpriteEntries[34].SpriteDataBytes[1], (TileColumn *
      GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 435;
    GameActors[LoadedActorCount].ActorWorldX := ((TileColumn - 1) * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := ((TileColumn - 1) * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorDirectionX := 1;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    GameActors[LoadedActorCount].ActorMovementStep := 0;
    GameActors[LoadedActorCount].ActorCounterA := 30;
    GameActors[LoadedActorCount].ActorCounterB := Random(30);
    GameActors[LoadedActorCount].ActorKindCode := 16;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = '?' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 435;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorDirectionX := 1;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    GameActors[LoadedActorCount].ActorMovementStep := 0;
    GameActors[LoadedActorCount].ActorCounterA := 30;
    GameActors[LoadedActorCount].ActorCounterB := Random(30);
    GameActors[LoadedActorCount].ActorKindCode := 17;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = 'A' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 435;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorDirectionX := 1;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    GameActors[LoadedActorCount].ActorMovementStep := 0;
    GameActors[LoadedActorCount].ActorCounterA := 30;
    GameActors[LoadedActorCount].ActorCounterB := Random(30);
    GameActors[LoadedActorCount].ActorKindCode := 18;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = '@' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 302, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 305;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := ((TileRow - 1) * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := ((TileRow - 1) * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorDirectionX := 0;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := (Random(18) + 1);
    GameActors[LoadedActorCount].ActorMovementStep := 0;
    GameActors[LoadedActorCount].ActorCounterA := 0;
    GameActors[LoadedActorCount].ActorCounterB := 5;
    GameActors[LoadedActorCount].ActorKindCode := 43;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = #212 then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 309;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorDirectionX := 0;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    GameActors[LoadedActorCount].ActorMovementStep := 0;
    GameActors[LoadedActorCount].ActorCounterA := 0;
    GameActors[LoadedActorCount].ActorCounterB := 2;
    GameActors[LoadedActorCount].ActorKindCode := 44;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
  if MapSymbol = 'x' then
  begin
    SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, 0, 0, ForegroundOnly);
    Inc(LoadedActorCount);
    GameActors[LoadedActorCount].FlashFrames := 0;
    GameActors[LoadedActorCount].ActorSpriteBase := 259;
    GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
    GameActors[LoadedActorCount].ActorDirectionX := 0;
    GameActors[LoadedActorCount].DirectionY := 0;
    GameActors[LoadedActorCount].ActorAnimationCounter := 1;
    GameActors[LoadedActorCount].ActorMovementStep := 0;
    GameActors[LoadedActorCount].ActorCounterA := 0;
    GameActors[LoadedActorCount].ActorCounterB := 2;
    GameActors[LoadedActorCount].ActorKindCode := 44;
    GameActors[LoadedActorCount].ActorSlotInactive := 0;
    GameActors[LoadedActorCount].ActorRemovalPending := 0;
  end;
end;

{ Encoded level rows and file loading. }
{$S-}{$I-}{$R-}{$B-}{$F-}
{$F+}
{ Expands map characters into tiles and actors. A '*' row changes foreground
  without clearing the underlying cells; 'Y' places the player and centers
  the camera, including saved-position handling when restoring the island. }
procedure DecodeLevelRow(TileRow: Integer; EncodedRow: TLevelFileRow);
var
  TileColumn: Integer;
  MapSymbol: String;
  SavedStartColumn, SavedStartRow: Integer;
  ForegroundOnly: Boolean;
begin
  if EncodedRow[1] <> '*' then
  begin
    ForegroundOnly := False;
    for TileColumn := 1 to GameMapColumnCount do
    begin
      LevelCells[TileColumn, TileRow + 1].CellBaseTile := 0;
      LevelCells[TileColumn, TileRow + 1].CellOverlayTile := 0;
      LevelCells[TileColumn, TileRow + 1].CellObjectCode := 0;
      LevelCells[TileColumn, TileRow + 1].CellSolidFlag := 0;
      LevelCells[TileColumn, TileRow + 1].SupportsLanding := 0;
    end;
  end
  else
    ForegroundOnly := True;
  for TileColumn := 0 to GameMapLastColumn do
  begin
    { Empty the BIOS keyboard queue while decoding each map column. }
    MemW[0:GameBiosKeyboardTailLinear] := MemW[0:GameBiosKeyboardHeadLinear];
    MapSymbol := EncodedRow[(TileColumn + 1)];
    if MapSymbol = ' ' then
    begin
      if not ForegroundOnly then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
    end;
    if CurrentLevelNumber > GameIslandLevelNumber then
    begin
      if MapSymbol = '1' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 1, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = '2' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 3, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = '3' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 4, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = '5' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 5, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = '6' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 6, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = '7' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 7, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #30 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 8, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = 'w' then
      begin
        SetAndDrawLevelCell(TileColumn, (TileRow - 1), GameTileBackdropPlaceholder, 0, 179, Ord(True),
          Ord(False), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileTeleportPad,
          Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #1 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 619, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #2 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 161, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #3 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 162, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #4 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 155, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #6 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 158, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #5 then
      begin
        SetAndDrawLevelCell((TileColumn - 1), TileRow, 156, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, 157, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
      end;
      if MapSymbol = #7 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 174, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #8 then
      begin
        SetAndDrawLevelCell((TileColumn - 1), TileRow, GameTileBackdropPlaceholder, 181, 0, Ord(False),
          Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 182, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #12 then
      begin
        SetAndDrawLevelCell((TileColumn - 1), TileRow, GameTileBackdropPlaceholder, 185, 0, Ord(False),
          Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 186, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #11 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 178, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #14 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 733, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #15 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 734, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #16 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 735, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #17 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 737, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #18 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 741, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #19 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 743, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #20 then
      begin
        SetAndDrawLevelCell(TileColumn, (TileRow - 1), GameTileBackdropPlaceholder, 745, 0, Ord(False),
          Ord(False), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 749, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #21 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 746, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #22 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 750, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #23 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 677, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #24 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 678, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #25 then
      begin
        SetAndDrawLevelCell(TileColumn, (TileRow - 1), GameTileBackdropPlaceholder, 251, 0, Ord(False),
          Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 255, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #27 then
      begin
        SetAndDrawLevelCell((TileColumn - 1), (TileRow - 1), GameTileBackdropPlaceholder, 252, 0, Ord(False),
          Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, (TileRow - 1), GameTileBackdropPlaceholder, 253, 0, Ord(False),
          Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell((TileColumn - 1), TileRow, GameTileBackdropPlaceholder, 256, 0, Ord(False),
          Ord(False), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 257, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #28 then
      begin
        SetAndDrawLevelCell(TileColumn, (TileRow - 1), GameTileBackdropPlaceholder, 254, 0, Ord(False),
          Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 258, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = '^' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileShotPower, Ord(False),
          Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = 'K' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 606, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'I' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #211 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, -1, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'r' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 607, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 's' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileAmmo, Ord(False),
          Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = 'N' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileSpeedBoost, Ord(False),
          Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = 'T' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 316, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'W' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 618, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = '\' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 620, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = ']' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 629, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'd' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 630, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'f' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 631, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'h' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 632, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = ':' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileReverseControls,
          Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = 'H' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileSlowMovement,
          Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = 'M' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 624, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'P' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileBlueprint, Ord(False),
          Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = 'p' then
      begin
        SetAndDrawLevelCell((TileColumn - 1), TileRow, GameTileBackdropPlaceholder, 159, 0, Ord(False),
          Ord(False), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 160, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #139 then
      begin
        SetAndDrawLevelCell((TileColumn - 1), TileRow, LevelBackdropTile, 163, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 164, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #154 then
      begin
        SetAndDrawLevelCell((TileColumn - 1), TileRow, LevelBackdropTile, 166, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 165, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #31 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 166, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #168 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 175, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #169 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 176, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #170 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 177, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #171 then
      begin
        SetAndDrawLevelCell(TileColumn, (TileRow - 1), 194, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, 198, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #172 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 197, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #173 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 193, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
      end;
      if MapSymbol = #133 then
      begin
        SetAndDrawLevelCell((TileColumn - 3), TileRow, GameTileBackdropPlaceholder, 0, 221, Ord(False),
          Ord(False), Ord(ForegroundOnly));
        SetAndDrawLevelCell((TileColumn - 2), TileRow, GameTileBackdropPlaceholder, 0, 222, Ord(False),
          Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell((TileColumn - 1), TileRow, GameTileBackdropPlaceholder, 0, 223, Ord(False),
          Ord(False), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 224, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #134 then
      begin
        SetAndDrawLevelCell((TileColumn - 2), TileRow, GameTileBackdropPlaceholder, 0, 229, Ord(False),
          Ord(False), Ord(ForegroundOnly));
        SetAndDrawLevelCell((TileColumn - 1), TileRow, GameTileBackdropPlaceholder, 0, 230, Ord(False),
          Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 231, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = '+' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileKeyOne, Ord(False),
          Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = ',' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileDoorOne, Ord(True),
          Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = '-' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileKeyTwo, Ord(False),
          Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = '.' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileDoorTwo, Ord(True),
          Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = '/' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileKeyThree, Ord(False),
          Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = '4' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileDoorThree, Ord(True),
          Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = 'o' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 417, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'i' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 441, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = 'j' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 442, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'k' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 443, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'l' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 444, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #149 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 449, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = '|' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 419, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = '~' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 420, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'm' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
        Inc(LoadedActorCount);
        PgBlitMaskedShifted16x16(SpriteBank401^.SpriteEntries[45].SpriteDataBytes[1], (TileColumn *
          GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
        PgBlitMaskedShifted16x16(SpriteBank401^.SpriteEntries[45].SpriteDataBytes[1], (TileColumn *
          GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
        GameActors[LoadedActorCount].FlashFrames := 0;
        GameActors[LoadedActorCount].ActorSpriteBase := 445;
        GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
        if Random(2) > 0 then
        begin
          GameActors[LoadedActorCount].ActorDirectionX := 1;
        end
        else
        begin
          GameActors[LoadedActorCount].ActorDirectionX := -1;
        end;
        GameActors[LoadedActorCount].DirectionY := 0;
        GameActors[LoadedActorCount].ActorAnimationCounter := 1;
        GameActors[LoadedActorCount].ActorMovementStep := 1;
        GameActors[LoadedActorCount].ActorCounterA := 0;
        GameActors[LoadedActorCount].ActorCounterB := 0;
        GameActors[LoadedActorCount].ActorKindCode := 20;
        GameActors[LoadedActorCount].ActorSlotInactive := 0;
        GameActors[LoadedActorCount].ActorRemovalPending := 0;
      end;
      if MapSymbol = 'a' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 500, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = '`' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 499, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = '_' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
        Inc(LoadedActorCount);
        PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[45].SpriteDataBytes[1], (TileColumn *
          GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
        PgBlitMaskedShifted16x16(SpriteBank451^.SpriteEntries[45].SpriteDataBytes[1], (TileColumn *
          GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
        GameActors[LoadedActorCount].FlashFrames := 0;
        GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
        if Random(2) > 0 then
        begin
          GameActors[LoadedActorCount].ActorDirectionX := 1;
        end
        else
        begin
          GameActors[LoadedActorCount].ActorDirectionX := -1;
        end;
        if GameActors[LoadedActorCount].ActorDirectionX = 1 then
        begin
          GameActors[LoadedActorCount].ActorSpriteBase := 497;
        end
        else
        begin
          GameActors[LoadedActorCount].ActorSpriteBase := 495;
        end;
        GameActors[LoadedActorCount].DirectionY := 0;
        GameActors[LoadedActorCount].ActorAnimationCounter := 1;
        GameActors[LoadedActorCount].ActorMovementStep := 1;
        GameActors[LoadedActorCount].ActorCounterA := 0;
        GameActors[LoadedActorCount].ActorCounterB := 0;
        GameActors[LoadedActorCount].ActorKindCode := 21;
        GameActors[LoadedActorCount].ActorSlotInactive := 0;
        GameActors[LoadedActorCount].ActorRemovalPending := 0;
      end;
      if MapSymbol = 'D' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 613, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'E' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 614, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'O' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 615, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'U' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 616, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #128 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 601, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #129 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 602, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #130 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileLaserField, Ord(False),
          Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #131 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileComputer, Ord(False),
          Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #132 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileFloppyDisk, Ord(False),
          Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #140 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileBonusFirst, Ord(False),
          Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #141 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileBonusSecond,
          Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #142 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileBonusThird, Ord(False),
          Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = '%' then
      begin
        SetAndDrawLevelCell((TileColumn - 1), TileRow, GameTileBackdropPlaceholder, 0, 452, Ord(False),
          Ord(False), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 453, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = '&' then
      begin
        SetAndDrawLevelCell((TileColumn - 1), (TileRow - 1), 455, 0, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, (TileRow - 1), 456, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
        SetAndDrawLevelCell((TileColumn - 1), TileRow, 459, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, 460, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = '(' then
      begin
        SetAndDrawLevelCell((TileColumn - 1), (TileRow - 1), 457, 0, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, (TileRow - 1), 458, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
        SetAndDrawLevelCell((TileColumn - 1), TileRow, 461, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, 462, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = ')' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 463, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = '*' then
      begin
        if TileColumn > 0 then
        begin
          SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 467, Ord(False), Ord(False),
            Ord(ForegroundOnly));
        end;
      end;
      if MapSymbol = 'q' then
      begin
        SetAndDrawLevelCell(TileColumn, (TileRow - 1), GameTileBackdropPlaceholder, 0, 633, Ord(True),
          Ord(False), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileBlastDoor, Ord(True),
          Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = 't' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, GameTileDynamite, Ord(False),
          Ord(False), Ord(ForegroundOnly));
      end;
      SpawnActorFromMapSymbol(TileColumn, TileRow, MapSymbol, Ord(ForegroundOnly));
      if MapSymbol = #175 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 349, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #143 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 651, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #144 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 652, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #145 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 653, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #146 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 654, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #147 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 655, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #148 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 656, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #150 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 658, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #151 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 659, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #152 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 660, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #153 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 661, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #155 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 663, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #156 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 664, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #157 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 665, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #158 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 666, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #163 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 671, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #164 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 672, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #165 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 673, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #166 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 674, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #176 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 684, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #177 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 685, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #178 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 686, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #179 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 687, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #180 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 688, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #181 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 689, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #183 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 691, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #184 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 692, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #185 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 693, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #186 then
      begin
        SetAndDrawLevelCell((TileColumn - 1), TileRow, 690, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, 694, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
      end;
      if MapSymbol = #187 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 695, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #188 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 698, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #189 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 696, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #190 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 697, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #191 then
      begin
        SetAndDrawLevelCell((TileColumn - 1), TileRow, 679, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, 680, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
      end;
      if MapSymbol = 'y' then
      begin
        SetAndDrawLevelCell((TileColumn - 1), TileRow, 318, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, 319, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
      end;
      if MapSymbol = 'z' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 317, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #135 then
      begin
        SetAndDrawLevelCell((TileColumn - 1), TileRow, 323, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, 324, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
      end;
      if MapSymbol = #182 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 681, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #192 then
      begin
        SetAndDrawLevelCell((TileColumn - 1), TileRow, 699, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, 700, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
      end;
      if MapSymbol = #136 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 345, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #137 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 346, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #138 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 347, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #162 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 348, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #193 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 701, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #194 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 702, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #195 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 703, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #196 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 704, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #197 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 705, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #198 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 706, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #199 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 707, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #200 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 708, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #201 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 709, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #202 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 710, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #203 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 711, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #204 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 712, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #205 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 0, 713, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #206 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 714, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #207 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 715, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #208 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 716, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #209 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
        Inc(LoadedActorCount);
        PgBlitMaskedShifted16x16(SpriteBank351^.SpriteEntries[1].SpriteDataBytes[1], (TileColumn *
          GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
        PgBlitMaskedShifted16x16(SpriteBank351^.SpriteEntries[1].SpriteDataBytes[1], (TileColumn *
          GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
        GameActors[LoadedActorCount].FlashFrames := 0;
        GameActors[LoadedActorCount].ActorSpriteBase := 717;
        GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorDirectionX := 1;
        GameActors[LoadedActorCount].DirectionY := 0;
        GameActors[LoadedActorCount].ActorAnimationCounter := 1;
        GameActors[LoadedActorCount].ActorMovementStep := 0;
        GameActors[LoadedActorCount].ActorCounterA := 0;
        GameActors[LoadedActorCount].ActorCounterB := 0;
        GameActors[LoadedActorCount].ActorKindCode := 26;
        GameActors[LoadedActorCount].ActorSlotInactive := 0;
        GameActors[LoadedActorCount].ActorRemovalPending := 0;
      end;
      if MapSymbol = #210 then
      begin
        SetAndDrawLevelCell((TileColumn - 1), (TileRow - 1), 191, 0, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, (TileRow - 1), 192, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell((TileColumn - 1), TileRow, 195, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, 196, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #213 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 721, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #214 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 722, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #215 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 723, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #217 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 725, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #218 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 726, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #219 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 727, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #220 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 728, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #221 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 729, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #222 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 730, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #223 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 201, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
      end;
      if MapSymbol = #224 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 202, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
      end;
      if MapSymbol = #225 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 203, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
      end;
      if MapSymbol = #226 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 205, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #227 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 206, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #228 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 207, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = '!' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 751, 0, 0, Ord(False), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = 'B' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 753, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'C' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 755, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = 'F' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 756, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'J' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 757, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #229 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 758, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #230 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 759, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #231 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 760, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #232 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 761, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #233 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 762, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #234 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 763, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #235 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 764, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #236 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 765, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #237 then
      begin
        SetAndDrawLevelCell((TileColumn - 1), TileRow, 199, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, 200, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
      end;
      if MapSymbol = #216 then
      begin
        SetAndDrawLevelCell((TileColumn - 1), TileRow, 268, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, 269, 0, 0, Ord(False), Ord(True), Ord(ForegroundOnly));
      end;
      if MapSymbol = #238 then
      begin
        SetAndDrawLevelCell((TileColumn - 2), TileRow, GameTileBackdropPlaceholder, 264, 0, Ord(False),
          Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell((TileColumn - 1), TileRow, GameTileBackdropPlaceholder, 265, 0, Ord(False),
          Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 266, 0, Ord(False), Ord(True),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #239 then
      begin
        SetAndDrawLevelCell(TileColumn, (TileRow - 1), GameTileBackdropPlaceholder, 263, 0, Ord(False),
          Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 267, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #241 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 775, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #242 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 776, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #243 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 777, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #244 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 778, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #245 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 779, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #246 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 780, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #247 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 781, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #248 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 782, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #249 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 783, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #250 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 784, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #251 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 785, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #252 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 786, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #253 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 787, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #254 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 788, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = 'L' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 789, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #159 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 791, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #160 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, 792, 0, 0, Ord(True), Ord(False), Ord(ForegroundOnly));
      end;
      if MapSymbol = #161 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, LevelBackdropTile, 793, 0, Ord(True), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'S' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 790, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = 'Z' then
      begin
        SetAndDrawLevelCell((TileColumn - 1), (TileRow - 1), GameTileBackdropPlaceholder, 795, 0, Ord(False),
          Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, (TileRow - 1), GameTileBackdropPlaceholder, 796, 0, Ord(False),
          Ord(True), Ord(ForegroundOnly));
        SetAndDrawLevelCell((TileColumn - 1), TileRow, GameTileBackdropPlaceholder, 799, 0, Ord(False),
          Ord(False), Ord(ForegroundOnly));
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 800, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
      end;
      if MapSymbol = #167 then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
        Inc(LoadedActorCount);
        PgBlitMaskedShifted16x16(SpriteBank651^.SpriteEntries[25].SpriteDataBytes[1], (TileColumn *
          GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
        PgBlitMaskedShifted16x16(SpriteBank651^.SpriteEntries[25].SpriteDataBytes[1], (TileColumn *
          GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
        GameActors[LoadedActorCount].FlashFrames := 0;
        GameActors[LoadedActorCount].ActorSpriteBase := 675;
        GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorDirectionX := 1;
        GameActors[LoadedActorCount].DirectionY := 0;
        GameActors[LoadedActorCount].ActorAnimationCounter := 1;
        GameActors[LoadedActorCount].ActorMovementStep := 0;
        GameActors[LoadedActorCount].ActorCounterA := 0;
        GameActors[LoadedActorCount].ActorCounterB := 0;
        GameActors[LoadedActorCount].ActorKindCode := 27;
        GameActors[LoadedActorCount].ActorSlotInactive := 0;
        GameActors[LoadedActorCount].ActorRemovalPending := 0;
      end;
      if MapSymbol = 'b' then
      begin
        SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, Ord(False), Ord(False),
          Ord(ForegroundOnly));
        Inc(LoadedActorCount);
        PgBlitMaskedShifted16x16(SpriteBank651^.SpriteEntries[26].SpriteDataBytes[1], (TileColumn *
          GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
        PgBlitMaskedShifted16x16(SpriteBank651^.SpriteEntries[26].SpriteDataBytes[1], (TileColumn *
          GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
        GameActors[LoadedActorCount].FlashFrames := 0;
        GameActors[LoadedActorCount].ActorSpriteBase := 676;
        GameActors[LoadedActorCount].ActorWorldX := (TileColumn * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorWorldY := (TileRow * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorPreviousX := (TileColumn * GameTileSizePixels);
        GameActors[LoadedActorCount].ActorPreviousY := (TileRow * GameTileSizePixels);
        if Random(2) > 0 then
        begin
          GameActors[LoadedActorCount].ActorDirectionX := 1;
        end
        else
        begin
          GameActors[LoadedActorCount].ActorDirectionX := -1;
        end;
        GameActors[LoadedActorCount].DirectionY := 0;
        GameActors[LoadedActorCount].ActorAnimationCounter := 1;
        GameActors[LoadedActorCount].ActorMovementStep := 2;
        GameActors[LoadedActorCount].ActorCounterA := 0;
        GameActors[LoadedActorCount].ActorCounterB := 0;
        GameActors[LoadedActorCount].ActorKindCode := 28;
        GameActors[LoadedActorCount].ActorSlotInactive := 0;
        GameActors[LoadedActorCount].ActorRemovalPending := 0;
      end;
    end;
    DecodeIslandSymbol(TileColumn, TileRow, MapSymbol);
    if MapSymbol = 'Y' then
    begin
      SetAndDrawLevelCell(TileColumn, TileRow, GameTileBackdropPlaceholder, 0, 0, Ord(False), Ord(False),
        Ord(ForegroundOnly));
      SavedStartColumn := TileColumn;
      SavedStartRow := TileRow;
      if GameSnapshot.SavedPlayerX <> 0 then
      begin
        if CurrentLevelNumber = GameIslandLevelNumber then
        begin
          TileColumn := (GameSnapshot.SavedPlayerX shr GameTilePixelShift);
          TileRow := (GameSnapshot.SavedPlayerY shr GameTilePixelShift);
        end;
      end;
      PgBlitMaskedShifted16x16(PlayerSpriteBank^.SpriteEntries[1].SpriteDataBytes[1], (TileColumn *
        GameTileSizePixels), ((TileRow * GameTileSizePixels) + 16));
      PgBlitMaskedShifted16x16(PlayerSpriteBank^.SpriteEntries[1].SpriteDataBytes[1], (TileColumn *
        GameTileSizePixels), ((TileRow * GameTileSizePixels) + GamePlayfieldBottomBufferRow));
      GameActors[GamePlayerActorSlot].FlashFrames := 0;
      GameActors[GamePlayerActorSlot].ActorSpriteBase := 9;
      GameActors[GamePlayerActorSlot].ActorWorldX := (TileColumn * GameTileSizePixels);
      GameActors[GamePlayerActorSlot].ActorWorldY := (TileRow * GameTileSizePixels);
      GameActors[GamePlayerActorSlot].ActorPreviousX := (TileColumn * GameTileSizePixels);
      GameActors[GamePlayerActorSlot].ActorPreviousY := (TileRow * GameTileSizePixels);
      GameActors[GamePlayerActorSlot].ActorDirectionX := 1;
      GameActors[GamePlayerActorSlot].DirectionY := 0;
      GameActors[GamePlayerActorSlot].ActorAnimationCounter := 1;
      GameActors[GamePlayerActorSlot].ActorMovementStep := 2;
      GameActors[GamePlayerActorSlot].ActorCounterA := 0;
      GameActors[GamePlayerActorSlot].ActorKindCode := GameActorKindPlayer;
      GameActors[GamePlayerActorSlot].ActorSlotInactive := 0;
      GameActors[GamePlayerActorSlot].ActorRemovalPending := 0;
      CameraX := ((TileColumn * GameTileSizePixels) - (GameScreenWidthPixels shr 1));
      if CameraX < 0 then
      begin
        CameraX := 0;
      end;
      if CameraX > GameCameraMaxX then
      begin
        CameraX := GameCameraMaxX;
      end;
      CameraY := ((TileRow * GameTileSizePixels) - (GameScreenHeightPixels shr 1));
      if CameraY < 0 then
      begin
        CameraY := 0;
      end;
      if CameraY > GameCameraMaxY then
      begin
        CameraY := GameCameraMaxY;
      end;
      if AlternateVideoTiming = 0 then
      begin
        PgPanDisplayAtRetraceStart(CameraX, (CameraY + GamePlayfieldTopBufferRow));
      end
      else
      begin
        PgPanDisplayAtRetraceEnd(CameraX, (CameraY + GamePlayfieldTopBufferRow));
      end;
      TileColumn := SavedStartColumn;
      TileRow := SavedStartRow;
    end;
  end;
end;
{$S-}{$I-}{$R-}{$B-}{$F-}

{$F+}
{ Loads a 48-record level slot: backdrop header, bottom row, then playable rows.
  Only the first 40 bytes of each 42-byte record are decrypted. A '*' record
  overlays the preceding row, so the original code decrements the loop index.
  The sequential skip and loop-variable writes are retained for exactness. }
procedure LoadLevelMap(LevelNumber: Integer);
var
  LoadIndex: Integer;
  LevelFile: TLevelFileAccess;
  EncodedRow: TLevelFileRow;
  LevelBackdropCodeText: String[40];
begin
  LoadedActorCount := 1;
  PgCopyStatusBandTemplate;
  StatusBarCameraX := -1;
  for LoadIndex := 2 to GameActorSlotCount do
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
  for LoadIndex := 1 to GamePlayerShotSlotCount do
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
  { Read and discard any previous DOS I/O error before opening the map. }
  if IOResult <> 0 then ;
  case LevelNumber of
    1:
      begin
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
        Reset(LevelFile.RawFile, GameLevelRowBytes);
        Read(LevelFile.RowFile, EncodedRow);
        DecryptGameAssetBuffer(EncodedRow, GameLevelRowPayloadBytes);
        LevelBackdropCodeText := EncodedRow[1] + EncodedRow[2] + EncodedRow[3];
        Val(LevelBackdropCodeText, LevelBackdropTile, LoadIndex);
        Read(LevelFile.RowFile, EncodedRow);
        DecryptGameAssetBuffer(EncodedRow, GameLevelRowPayloadBytes);
        DecodeLevelRow(GameMapLastRow, EncodedRow);
        for LoadIndex := 0 to 23 do
        begin
          Read(LevelFile.RowFile, EncodedRow);
          DecryptGameAssetBuffer(EncodedRow, GameLevelRowPayloadBytes);
          if EncodedRow[1] = '*' then
            Dec(LoadIndex);
          DecodeLevelRow(LoadIndex, EncodedRow);
        end;
        Close(LevelFile.RawFile);
      end;
    2..17:
      begin
{$IFDEF SAM1}
        Assign(LevelFile.RawFile, 'SAM103.GFX');
{$ENDIF}
{$IFDEF SAM2}
        Assign(LevelFile.RawFile, 'SAM203.GFX');
{$ENDIF}
{$IFDEF SAM3}
        Assign(LevelFile.RawFile, 'SAM303.GFX');
{$ENDIF}
        Reset(LevelFile.RawFile, GameLevelRowBytes);
        for LoadIndex := 1 to (LevelNumber - 1) * GameLevelSlotRecords do
          Read(LevelFile.RowFile, EncodedRow);
        Read(LevelFile.RowFile, EncodedRow);
        DecryptGameAssetBuffer(EncodedRow, GameLevelRowPayloadBytes);
        LevelBackdropCodeText := EncodedRow[1] + EncodedRow[2] + EncodedRow[3];
        Val(LevelBackdropCodeText, LevelBackdropTile, LoadIndex);
        Read(LevelFile.RowFile, EncodedRow);
        DecryptGameAssetBuffer(EncodedRow, GameLevelRowPayloadBytes);
        DecodeLevelRow(GameMapLastRow, EncodedRow);
        for LoadIndex := 0 to 23 do
        begin
          Read(LevelFile.RowFile, EncodedRow);
          DecryptGameAssetBuffer(EncodedRow, GameLevelRowPayloadBytes);
          if EncodedRow[1] = '*' then
            Dec(LoadIndex);
          DecodeLevelRow(LoadIndex, EncodedRow);
        end;
        Close(LevelFile.RawFile);
      end;
  end;
  PgSetDrawColor(0);
  PgFillRectangleByteAligned(0, GameVideoStrideBytes, 0, 8);
  RestoreGamePalette(20);
  StartSoundEffect(GameSfxLevelStart);
end;
{$S-}{$I-}{$R-}{$B-}{$F-}
{ Empty begin/end unit initialization body. }
begin
end.
