/* Pascal external entry points implemented by the assembly-library port. */
#ifndef SAMLIB_H
#define SAMLIB_H

#include <stdint.h>
#include "../pc/pc.h"

#ifdef __cplusplus
extern "C" {
#endif

/* The translator must bind the active episode's DATA offsets before calling
   these libraries. DATA offsets differ between SAM1 and SAM2/SAM3. */
typedef struct {
    /* Pascal DATA symbols referenced by the six assembly objects' EXTRNs. */
    uint16_t GenusPcxIdentity;
    uint16_t PcxDisplayDescriptions;
    uint16_t PcxSelectedDisplay;
    uint16_t PcxGraphicsModeState;
    uint16_t PcxDisplayPageState;
    uint16_t PcxModeCheckPolicy;
    uint16_t PcxDefaultReadBuffer;
    uint16_t PcxReadState;
    uint16_t PcxPrinterScanline;
    uint16_t PcxPrintedSourceRow;
    uint16_t PcxPrinterDeviceClass;
    uint16_t PcxPrinterResolutionClass;
    uint16_t PcxDisplayTable;
    uint16_t PcxHerculesGraphicsCrtc;
    uint16_t PcxHerculesTextCrtc;
    uint16_t PcxPrinterState;
    uint16_t TextVideoSegment;
    uint16_t TextRetraceSyncEnabled;
    uint16_t TextSavedBiosMode;
    uint16_t TextVideoAdapterClass;
} samlib_data_offsets;

void samlib_bind_data_offsets(const samlib_data_offsets *offsets);
/* Restore native CS-private state before loading another DOS process. */
void samlib_reset(void);

/* PROGRAPX.ASM / PROGRPHX.PAS */
void PgSetToolboxVideoMode(uint16_t toolbox_mode);
void PgSetBiosVideoMode(uint16_t bios_mode);
int16_t PgSetScreenStride(uint16_t stride_bytes);
void PgPanDisplayAtRetraceStart(uint16_t pan_pixel_x, uint16_t pan_pixel_y);
void PgPanDisplayAtRetraceEnd(uint16_t pan_pixel_x, uint16_t pan_pixel_y);
void PgSetEgaSplitScanline(uint16_t split_scanline);
void PgWaitVerticalRetrace(void);
void PgSetVgaSplitScanline(uint16_t split_scanline);
void PgSetBorderColor(uint16_t border_color);
void PgSetPaletteRegister(int16_t palette_index, int16_t palette_color);
void PgBlitMasked16x16(farptr image_source, int16_t byte_column, int16_t pixel_row);
void PgBlitMasked8x8(farptr image_source, int16_t byte_column, int16_t pixel_row);
void PgSetDrawColor(uint16_t draw_color);
void PgFillRectangleByteAligned(uint16_t left_byte_column, uint16_t width_bytes,
                                uint16_t top_pixel_row, uint16_t height_rows);
void PgCapturePlanarRectangle(farptr captured_image, int16_t left_byte_column,
                              int16_t top_pixel_row, int16_t right_byte_limit,
                              int16_t bottom_pixel_row);
void PgRestorePlanarRectangle(farptr captured_image, int16_t byte_column,
                              int16_t pixel_row);
void PgBlitMaskedShifted16x16(farptr sprite_source, int16_t pixel_x, int16_t pixel_y);
void PgBlitMaskedShifted8x8(farptr glyph_source, uint16_t pixel_x, uint16_t pixel_y);
void PgOrShifted16x16(farptr sprite_source, int16_t pixel_x, int16_t pixel_y);
void PgInitializeRomFonts(void);
void PgSelectRomFont(uint16_t font_index);
void PgBlitOpaque16x16(farptr image_source, int16_t byte_column, int16_t pixel_row);
void PgBlitOpaque8x8(farptr image_source, int16_t byte_column, int16_t pixel_row);
void PgCopyCachedVideoTile16x16(int16_t byte_column, int16_t pixel_row,
                                int16_t cached_tile_index);
void PgCopyVideoScreenRegion320x200(uint16_t source_byte_column, uint16_t source_pixel_row,
                                    uint16_t dest_byte_column, uint16_t dest_pixel_row);
void PgCopyStatusBandTemplate(void);

/* GENUS.ASM / PCXGENUS.PAS. */
int16_t PcxSetDisplayType(uint16_t display_index);
int16_t PcxSetGraphicsOrTextMode(uint16_t graphics_enabled);
int16_t PcxGetDisplayType(void);
farptr PcxGetDisplayDescriptor(uint16_t display_index);
void PcxInitializeVideoDescriptors(void);
int16_t PcxDisplayBuffer(farptr pcx_image_buffer, uint16_t available_buffer_bytes,
                         uint16_t image_x, uint16_t image_y, uint16_t video_page);
void PcxInitializeDisplayDispatch(void);
int16_t PcxDisplayFile(farptr image_file_name, uint16_t image_x,
                       uint16_t image_y, uint16_t video_page);
int16_t PcxBeginPrinterImage(uint16_t source_row_bytes, uint16_t printer_x,
                             uint16_t printer_y);
void PcxEndPrinterImage(void);
uint16_t PcxFormatUnsignedDecimal(int32_t unsigned_value, farptr digit_buffer);
void PcxInitializePrinterState(void);

/* TEXTOUT.ASM / TEXT80.PAS. */
void WriteColoredText(uint8_t text_column, uint8_t text_row, uint8_t color_attribute,
                      farptr display_text);
uint8_t DetectTextVideoAdapter(void);
uint8_t GetTextVideoMode(void);

/* JOYSTICK.ASM / GAMEJOY.PAS. */
int16_t ReadJoystickAxis(uint16_t axis_index);

/* DECODE.ASM / SAMDATA.PAS. */
void DecryptGameAssetBuffer(farptr asset_buffer, uint16_t asset_byte_count);

/* CMOSPIT.ASM / SAM.PAS. */
void SyncDosClockFromCmos(void);
void SetFastGameTimer(void);
void RestoreDefaultTimer(void);

#ifdef __cplusplus
}
#endif
#endif
