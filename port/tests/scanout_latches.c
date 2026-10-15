/* Display history is distinct from readable registers. Exercise writes before,
   on, and after sync, including two bytes crossing it and reset in place. */
#include "pc/pc_internal.h"
#include <stdlib.h>
#define CHECK(x) do { if(!(x)) {fprintf(stderr,"FAIL line %d: %s\n",__LINE__,#x);return 1;} } while(0)
static void reg(unsigned index,unsigned value) {
    vga_port_write(0x3d4,(uint8_t)index);vga_port_write(0x3d5,(uint8_t)value);
}
static void pan(unsigned value) {
    uint8_t dummy;vga_port_read(0x3da,&dummy);
    vga_port_write(0x3c0,0x33);vga_port_write(0x3c0,(uint8_t)value);
}
static unsigned origin(void) {
    unsigned start,p,stride;vga_scanout_origin(&start,&p,&stride);
    return start*8+p;
}
static void at(uint64_t line) {pc_clock_advance(pc_video_line_time(line));}
static uint32_t pixels[320*400];
int main(void) {
    pc_program p={PC_PSP_SEG,0x3100,0x3900,0x4000,0x3d00,0xa000};
    for(int vga=0;vga<=1;++vga) {
        pc_load_program(&p,NULL,0);pc_clock_manual(1);vga_set_adapter(vga);bios_set_mode(0x0d);
        reg(0x13,40);reg(0x0c,0x12);reg(0x0d,0x34);pan(3);
        CHECK(origin()==0);
        at(412);reg(0x0d,0x35);pan(5); /* start was latched before this write */
        at(449);CHECK(origin()==0x1234*8+5);
        uint8_t readable;vga_port_write(0x3d4,0x0d);vga_port_read(0x3d5,&readable);
        CHECK(readable==0x35);
        at(449+411);reg(0x0c,0x56);
        at(449+412);reg(0x0d,0x78);pan(2); /* split-byte write really can tear */
        at(898);CHECK(origin()==0x5635*8+2);
        at(898+412);pan(7);at(1347);CHECK(origin()==0x5678*8+7);
        /* Address and pel pan are actually used by the displayed pixel path. */
        vga_plane(0)[0x5678]=1;
        vga_render_display_rgb(pixels,1);
        CHECK(pixels[0]==(0xff000000u|vga_colour_rgb(vga_palette_registers()[1])));
        /* Changes during active display cannot rewrite the sampled frame pair. */
        reg(0x0c,0);reg(0x0d,0);pan(0);CHECK(origin()==0x5678*8+7);
        bios_set_mode(0x0d);CHECK(origin()==0);
    }
    puts("PASS IBM EGA/VGA sync latch, next-frame pan sample, raw reads, pixels and reset");
    return 0;
}
