/* Compare the optimized RGB conversion with the existing per-pixel indexed
   renderer over randomized hardware state, including far offsets and splits. */
#include "pc/platform.h"
#include <stdio.h>
#include <stdlib.h>
static uint32_t rng=0x683d;
static unsigned random_byte(void){rng=rng*1664525u+1013904223u;return rng>>24;}
static void reg(unsigned port,unsigned index,unsigned value){vga_port_write((uint16_t)port,(uint8_t)index);vga_port_write((uint16_t)(port+1),(uint8_t)value);}
static uint8_t indexed[720*480];
static uint32_t rgb[720*480],physical[720*480];
int main(void) {
    pc_program p={PC_PSP_SEG,0x3100,0x3900,0x4000,0x3d00,0xa000};
    pc_load_program(&p,NULL,0);pc_clock_manual(1);
    for(unsigned plane=0;plane<4;++plane)
        for(unsigned i=0;i<65536;++i)vga_plane((int)plane)[i]=(uint8_t)random_byte();
    for(unsigned trial=0;trial<90;++trial) {
        unsigned mode=trial%3==0 ? 0x0d : trial%3==1 ? 0x10 : 0x12;
        vga_set_adapter((trial&1)!=0);bios_set_mode((uint8_t)(mode|0x80));
        reg(0x3d4,0x0c,random_byte());reg(0x3d4,0x0d,random_byte());
        reg(0x3d4,0x13,random_byte());reg(0x3d4,0x18,random_byte());
        reg(0x3d4,0x07,random_byte()&16);reg(0x3d4,0x09,(random_byte()&64)|(mode==0x0d ? 128 : 0));
        uint8_t dummy;vga_port_read(0x3da,&dummy);
        vga_port_write(0x3c0,0x33);vga_port_write(0x3c0,(uint8_t)(random_byte()&7));
        vga_port_write(0x3c0,0x30);vga_port_write(0x3c0,(uint8_t)(random_byte()&32));
        vga_port_write(0x3c0,0x32);vga_port_write(0x3c0,(uint8_t)(random_byte()&15));
        int w,h,pw,ph;vga_dimensions(&w,&h);vga_scanout_dimensions(&pw,&ph);
        vga_render_indexed(indexed);vga_render_rgb(rgb);vga_render_scanout_rgb(physical);
        const uint8_t *palette=vga_palette_registers();
        for(int y=0;y<h;++y)for(int x=0;x<w;++x) {
            uint32_t expected=0xff000000u|vga_colour_rgb(palette[indexed[y*w+x]]);
            if(rgb[y*w+x]!=expected || physical[(y*(ph/h))*pw+x]!=expected) {
                fprintf(stderr,"RGB mismatch trial=%u x=%d y=%d\n",trial,x,y);return 1;
            }
        }
    }
    puts("PASS 90 randomized planar RGB/indexed comparisons and physical scanlines");return 0;
}
