#include "crt_dos.h"
#include "../pc/platform.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

uint8_t tp_CrtActive;
static uint16_t crt_ds,crt_offsets[8];
void tp_BindCrt(uint16_t ds,const tp_crt_offsets *offsets)
{
    crt_ds=ds;
    memcpy(crt_offsets,offsets,sizeof crt_offsets);
    tp_CrtActive=0;
}
void *tp_CrtAddress(uint8_t index)
{
    if(!crt_ds || index>=8) { fprintf(stderr,"Crt DATA offsets not bound\n"); abort(); }
    return pc_host(crt_ds,crt_offsets[index]);
}
static uint8_t x=1,y=1,read_pending,pending_scan;
static uint16_t video_seg=0xb800;
static unsigned left(void) { return tp_WindMin&255; }
static unsigned top(void) { return tp_WindMin>>8; }
static unsigned width(void) { return (tp_WindMax&255)-left()+1; }
static unsigned height(void) { return (tp_WindMax>>8)-top()+1; }
static uint16_t cell(unsigned cx,unsigned cy) { return (uint16_t)(((top()+cy-1)*80+left()+cx-1)*2); }
static void cursor(void)
{
    pc_regs r={0}; r.ax=0x0200; r.dx=(uint16_t)(((top()+y-1)<<8)|(left()+x-1)); pc_bios_int(0x10,&r);
}
static void break_handler(void) { if(tp_CheckBreak) pc_terminate(255); }
void tp_CrtInit(void)
{
    pc_regs r={0}; r.ax=0x0f00; pc_bios_int(0x10,&r);
    if ((r.ax&255)!=3) tp_TextMode(3);
    r.ax=0x0800; r.bx=0; pc_bios_int(0x10,&r); tp_TextAttr=(uint8_t)(r.ax>>8);
    tp_CheckBreak=tp_DirectVideo=1; tp_CheckEOF=tp_CheckSnow=0; read_pending=0;
    tp_CrtActive=1;
    tp_WindMin=0; tp_WindMax=0x184f; tp_LastMode=3; x=y=1;
    tp_SetIntVec(0x1b,pc_register_code(break_handler,"Crt Ctrl-Break")); cursor();
}
void tp_Delay(uint16_t ms) { pc_delay_ms(ms); }
void tp_Sound(uint16_t hz)
{
    if(hz<=18) return;
    if(!(pc_inb(0x61)&3)) { pc_outb(0x61,(uint8_t)(pc_inb(0x61)|3)); pc_outb(0x43,0xb6); }
    uint16_t d=(uint16_t)(1193181u/hz); pc_outb(0x42,(uint8_t)d); pc_outb(0x42,(uint8_t)(d>>8));
}
void tp_NoSound(void) { pc_outb(0x61,(uint8_t)(pc_inb(0x61)&~3u)); }
uint8_t tp_KeyPressed(void)
{
    if(read_pending) return 1;
    pc_poll(); pc_regs r={0}; r.ax=0x0100; pc_bios_int(0x16,&r); return (r.flags&0x40)==0;
}
uint8_t tp_ReadKey(void)
{
    if(read_pending) { read_pending=0; return pending_scan; }
    pc_regs r={0}; pc_bios_int(0x16,&r);
    if(!(r.ax&255)) { pending_scan=(uint8_t)(r.ax>>8); read_pending=1; }
    return (uint8_t)r.ax;
}
void tp_GotoXY(uint8_t nx,uint8_t ny) { if(nx&&ny&&nx<=width()&&ny<=height()) { x=nx; y=ny; cursor(); } }
uint8_t tp_WhereX(void) { return x; }
uint8_t tp_WhereY(void) { return y; }
void tp_TextColor(uint8_t c) { tp_TextAttr=(uint8_t)((tp_TextAttr&0x70)|(c&0x8f)); }
void tp_TextBackground(uint8_t c) { tp_TextAttr=(uint8_t)((tp_TextAttr&0x8f)|((c&7)<<4)); }
void tp_Window(uint8_t x1,uint8_t y1,uint8_t x2,uint8_t y2)
{
    if(!x1||!y1||x1>x2||y1>y2||x2>80||y2>25) return;
    tp_WindMin=(uint16_t)(((y1-1)<<8)|(x1-1)); tp_WindMax=(uint16_t)(((y2-1)<<8)|(x2-1)); x=y=1; cursor();
}
void tp_ClrScr(void)
{
    for(unsigned cy=1;cy<=height();++cy) for(unsigned cx=1;cx<=width();++cx)
        pc_wr16(video_seg,cell(cx,cy),(uint16_t)((tp_TextAttr<<8)|32));
    x=y=1; cursor();
}
void tp_ClrEol(void)
{
    for(unsigned cx=x;cx<=width();++cx) pc_wr16(video_seg,cell(cx,y),(uint16_t)((tp_TextAttr<<8)|32));
}
void tp_TextMode(int16_t m)
{
    pc_regs r={0}; r.ax=(uint16_t)m&255; pc_bios_int(0x10,&r);
    tp_LastMode=(uint16_t)m; video_seg=0xb800; tp_WindMin=0; tp_WindMax=0x184f; x=y=1; cursor();
}
static void newline(void)
{
    ++y;
    if(y<=height()) return;
    y=(uint8_t)height();
    for(unsigned cy=1;cy<height();++cy) for(unsigned cx=1;cx<=width();++cx)
        pc_wr16(video_seg,cell(cx,cy),pc_rd16(video_seg,cell(cx,cy+1)));
    for(unsigned cx=1;cx<=width();++cx) pc_wr16(video_seg,cell(cx,y),(uint16_t)((tp_TextAttr<<8)|32));
}
void tp_CrtWrite(const uint8_t *bytes,size_t length)
{
    for(size_t i=0;i<length;++i) {
        uint8_t ch=bytes[i];
        if(ch==13) x=1;
        else if(ch==10) newline();
        else if(ch==8) { if(x>1) --x; }
        else if(ch==7) { /* DOS BEL: briefly use the same speaker hardware. */ tp_Sound(880); tp_Delay(30); tp_NoSound(); }
        else { pc_wr16(video_seg,cell(x,y),(uint16_t)((tp_TextAttr<<8)|ch)); if(++x>width()) { x=1; newline(); } }
        pc_poll();
    }
    cursor();
}
void tp_CrtWriteLn(void) { const uint8_t end[]={13,10}; tp_CrtWrite(end,2); }
