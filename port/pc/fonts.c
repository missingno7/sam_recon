#include "pc_internal.h"
#include "font_data.h"
farptr pc_font_pointer(unsigned h)
{
    return FP(0xf000,h==8 ? 0x0200 : h==14 ? 0x0a00 : 0x1800);
}
void pc_fonts_init(void)
{
    const unsigned heights[]={8,14,16};
    for(unsigned n=0;n<3;++n) {
        unsigned h=heights[n]; farptr f=pc_font_pointer(h);
        for(unsigned c=0;c<256;++c) for(unsigned y=0;y<h;++y) {
            /* Area resampling preserves narrow horizontal box-drawing strokes. */
            unsigned first=y*16/h,last=(y+1)*16/h; uint8_t bits=0;
            for(unsigned row=first;row<last;++row) bits|=font16[c][row];
            pc_wr8(FP_SEG(f),(uint16_t)(FP_OFF(f)+c*h+y),bits);
        }
    }
    farptr f=pc_font_pointer(8); pc_wr16(0,0x1f*4,FP_OFF(f)+128*8); pc_wr16(0,0x1f*4+2,FP_SEG(f));
    f=pc_font_pointer(vga_is_vga() ? 16 : 14); pc_wr16(0,0x43*4,FP_OFF(f)); pc_wr16(0,0x43*4+2,FP_SEG(f));
}
