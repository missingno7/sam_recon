/* Provide the BIOS font pointers and ROM-resident character rows queried by video services. */
#include "pc_internal.h"
#include "font_data.h"

/* Return the BIOS ROM address for a font height supported by INT 10h. */
farptr pc_font_pointer(unsigned h) {
    return FP(PC_BIOS_ROM_SEGMENT, h == 8    ? PC_FONT_8X8_OFFSET
                                   : h == 14 ? PC_FONT_8X14_OFFSET
                                             : PC_FONT_8X16_OFFSET);
}
/* Expand the generated font data into ROM memory and install INT 1Fh/43h font vectors. */
void pc_fonts_init(void) {
    const unsigned heights[] = {8, 14, 16};
    for (unsigned n = 0; n < 3; ++n) {
        unsigned h = heights[n];
        farptr f = pc_font_pointer(h);
        for (unsigned c = 0; c < 256; ++c)
            for (unsigned y = 0; y < h; ++y) {
                /* Area resampling preserves narrow horizontal box-drawing strokes. */
                unsigned first = y * 16 / h, last = (y + 1) * 16 / h;
                uint8_t bits = 0;
                for (unsigned row = first; row < last; ++row)
                    bits |= font16[c][row];
                pc_wr8(FP_SEG(f), (uint16_t)(FP_OFF(f) + c * h + y), bits);
            }
    }
    farptr f = pc_font_pointer(8);
    pc_wr16(PC_IVT_SEGMENT, PC_INT_FONT_8X8 * PC_IVT_ENTRY_SIZE,
            FP_OFF(f) + PC_FONT_ALTERNATE_8X8_OFFSET);
    pc_wr16(PC_IVT_SEGMENT, PC_INT_FONT_8X8 * PC_IVT_ENTRY_SIZE + 2, FP_SEG(f));
    f = pc_font_pointer(vga_is_vga() ? 16 : 14);
    pc_wr16(PC_IVT_SEGMENT, PC_INT_FONT_8X16 * PC_IVT_ENTRY_SIZE, FP_OFF(f));
    pc_wr16(PC_IVT_SEGMENT, PC_INT_FONT_8X16 * PC_IVT_ENTRY_SIZE + 2, FP_SEG(f));
}
