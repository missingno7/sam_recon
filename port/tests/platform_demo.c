#include "pc/platform.h"
#include "tp/crt_dos.h"
#include <stdio.h>
static void crtc(unsigned r,unsigned v) {pc_outw(0x3d4,(uint16_t)(r|(v<<8)));}
static void attr(unsigned r,unsigned v) {(void)pc_inb(0x3da);pc_outb(0x3c0,(uint8_t)(r|32));pc_outb(0x3c0,(uint8_t)v);}
int main(int argc,char **argv)
{
    if(!platform_init(argc,argv)) return 2;
    pc_program p={PC_PSP_SEG,0x3100,0x3900,0x4000,0x3d00,0xa000};pc_load_program(&p,NULL,0);
    bios_set_mode(0x0d);crtc(0x13,40);
    for(unsigned y=0;y<416;++y) for(unsigned x=0;x<640;++x) {
        unsigned c=y<16 ? ((x/20)&15) : (((x/32)+(y/32))&15);
        if(y>=16 && (x%32==0 || y%32==16)) c=15;
        unsigned off=y*80+x/8;uint8_t bit=(uint8_t)(128>>(x&7));
        for(unsigned plane=0;plane<4;++plane) if(c&(1u<<plane)) vga_plane((int)plane)[off]|=bit;
    }
    attr(0x10,0x21);crtc(0x18,0x80);crtc(7,0x10);crtc(9,0x80);
    tp_Sound(440);uint64_t last=UINT64_MAX;
    while(!platform_quit_requested()) {
        unsigned pan=(unsigned)(pc_time_us()/10000u)%321;
        if(pan!=last) {
            unsigned start=16*80+(pan>>3);crtc(12,start>>8);crtc(13,start&255);attr(0x13,pan&7);last=pan;
        }
        if(pc_time_us()>250000) tp_NoSound();
        pc_poll();
    }
    printf("demo complete at %llu us\n",(unsigned long long)pc_time_us());platform_shutdown();return 0;
}
