#include "pc/platform.h"
#include "tp/crt_dos.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CHECK(e) do { if(!(e)) { fprintf(stderr,"FAIL line %d: %s\n",__LINE__,#e); exit(1); } } while(0)
static const pc_program placement={PC_PSP_SEG,0x3100,0x3900,0x4000,0x3d00,0xa000};
static void reset(void) {
    pc_load_program(&placement,NULL,0); pc_clock_manual(1);
    const tp_crt_offsets o={0x100,0x101,0x102,0x103,0x104,0x106,0x108,0x10a};
    tp_BindCrt(placement.ds_seg,&o);
}
static void gc(unsigned i,unsigned v) { pc_outw(0x3ce,(uint16_t)(i|(v<<8))); }
static void seq(unsigned i,unsigned v) { pc_outw(0x3c4,(uint16_t)(i|(v<<8))); }
static void crtc(unsigned i,unsigned v) { pc_outw(0x3d4,(uint16_t)(i|(v<<8))); }
static void attr(unsigned i,unsigned v) { (void)pc_inb(0x3da); pc_outb(0x3c0,(uint8_t)(i|32)); pc_outb(0x3c0,(uint8_t)v); }
static void plane_write(unsigned p,uint16_t o,uint8_t v) { seq(2,1u<<p); vga_cpu_write(o,v); }

static void test_memory(void)
{
    uint8_t image[]={0x19,0x37,0x55,0x81};
    pc_load_program(&placement,image,sizeof image); pc_clock_manual(1);
    CHECK(!memcmp(pc_host(placement.ds_seg,0),image,sizeof image));
    CHECK(pc_current_program()->ss_seg==0x3900);
    CHECK(pc_rd16(PC_PSP_SEG,0)==0x20cd && pc_rd16(PC_PSP_SEG,2)==0xa000);
    CHECK(pc_rd16(PC_PSP_SEG,0x2c)==PC_PSP_SEG-0x10);
    CHECK(pc_rd16(0x40,0x13)==640 && pc_rd16(0x40,0x63)==0x3d4);
    CHECK(pc_rd16(0,8*4+2)==0xf000);
    pc_wr16(0x5000,0xffff,0xabcd);
    CHECK(pc_rd8(0x5000,0xffff)==0xcd && pc_rd8(0x5000,0)==0xab);
    CHECK(pc_rd16(0x5000,0xffff)==0xabcd);
    pc_wr8(0xffff,0x20,0x5b); CHECK(pc_rd8(0,0x10)==0x5b && pc_mem[0x100010]==0x5b);
    puts("PASS memory/program/BIOS placement and 20-bit/offset wrapping");
}
static void test_vga(void)
{
    reset(); bios_set_mode(0x0d);
    seq(2,5); vga_cpu_write(0x100,0xa5);
    CHECK(vga_plane(0)[0x100]==0xa5 && vga_plane(1)[0x100]==0 && vga_plane(2)[0x100]==0xa5);
    seq(2,15); gc(5,2); vga_cpu_write(0x110,5);
    for(unsigned p=0;p<4;++p) CHECK(vga_plane((int)p)[0x110]==((p==0||p==2)?255:0));
    gc(5,0); gc(0,5); gc(1,5); vga_cpu_write(0x120,0);
    CHECK(vga_plane(0)[0x120]==255&&vga_plane(1)[0x120]==0&&vga_plane(2)[0x120]==255);
    gc(1,0);
    for(unsigned p=0;p<4;++p) plane_write(p,0x130,0x55);
    seq(2,15); gc(8,0xf0); (void)vga_cpu_read(0x130); vga_cpu_write(0x130,0xaa);
    for(unsigned p=0;p<4;++p) CHECK(vga_plane((int)p)[0x130]==0xa5);
    gc(8,255); plane_write(0,0x138,15); (void)vga_cpu_read(0x138); gc(3,0x10); vga_cpu_write(0x138,0xf0);
    CHECK(vga_plane(0)[0x138]==255); gc(3,1); vga_cpu_write(0x139,3); CHECK(vga_plane(0)[0x139]==0x81);
    gc(3,0);
    for(unsigned p=0;p<4;++p) plane_write(p,0x140,(uint8_t)(0x12+0x22*p));
    seq(2,15); gc(5,1); (void)vga_cpu_read(0x140); vga_cpu_write(0x150,0xff);
    for(unsigned p=0;p<4;++p) CHECK(vga_plane((int)p)[0x150]==0x12+0x22*p);
    gc(5,0); gc(4,2); CHECK(vga_cpu_read(0x140)==0x56);
    plane_write(0,0x160,0xf0); plane_write(1,0x160,0xcc); plane_write(2,0x160,0xaa); plane_write(3,0x160,0);
    gc(2,5); gc(7,5); gc(5,8); CHECK(vga_cpu_read(0x160)==0xa0);
    puts("PASS VGA write modes, map mask, set/reset, rotation, ALU, latches, read compare");
}
static unsigned pattern(unsigned x,unsigned y) { return ((x/7)^(y/3))&15; }
static void set_pixel(unsigned x,unsigned y,unsigned c)
{
    uint16_t off=(uint16_t)(y*80+x/8); uint8_t bit=(uint8_t)(128>>(x&7));
    for(unsigned p=0;p<4;++p) if(c&(1u<<p)) vga_plane((int)p)[off]|=bit;
}
static void test_scanout(void)
{
    static uint8_t out[640*480];
    static uint32_t physical[640*480];
    reset(); bios_set_mode(0x0d);
    for(unsigned y=0;y<400;++y) for(unsigned x=0;x<640;++x) set_pixel(x,y,pattern(x,y));
    crtc(0x13,40); unsigned start=16*80+5; crtc(12,start>>8); crtc(13,start&255);
    attr(0x13,3); attr(0x10,0x21); crtc(0x18,0x80); crtc(7,0x10); crtc(9,0x80);
    vga_render_indexed(out);
    /* VGA compare 384: reset after that physical line, retaining odd phase. */
    for(unsigned y=0;y<200;++y) for(unsigned x=0;x<320;++x)
        CHECK(out[y*320+x]==(y<=192 ? pattern(x+43,y+16) : pattern(x,y-193)));
    vga_render_scanout_rgb(physical);
    const uint8_t *palette=vga_palette_registers();
    for(unsigned y=0;y<400;++y) for(unsigned x=0;x<320;++x) {
        unsigned c=y<=384 ? pattern(x+43,y/2+16) : pattern(x,(y-385)/2);
        CHECK(physical[y*320+x]==(0xff000000u|vga_colour_rgb(palette[c])));
    }
    CHECK(platform_screenshot("split-vga.png"));
    vga_set_adapter(0); bios_set_mode(0x0d);
    for(unsigned y=0;y<400;++y) for(unsigned x=0;x<640;++x) set_pixel(x,y,pattern(x,y));
    crtc(0x13,40); crtc(12,start>>8); crtc(13,start&255); attr(0x13,3); attr(0x10,0x21);
    crtc(0x18,190); crtc(7,0x01); /* EGA ignores VGA-only line-compare bit 9 */
    vga_render_indexed(out);
    for(unsigned y=0;y<200;++y) for(unsigned x=0;x<320;++x)
        CHECK(out[y*320+x]==(y<=190 ? pattern(x+43,y+16) : pattern(x,y-191)));
    CHECK(platform_screenshot("split-ega.png"));
    attr(0x10,1); vga_render_indexed(out); CHECK(out[191*320]==pattern(3,0));
    vga_set_adapter(1); bios_set_mode(0x10); int w,h; vga_dimensions(&w,&h); CHECK(w==640&&h==350);
    bios_set_mode(0x12); vga_dimensions(&w,&h); CHECK(w==640&&h==480);
    /* Both retrace and display-enable phases are functions of clock, never read count. */
    pc_clock_advance(0); CHECK((pc_inb(0x3da)&9)==0); CHECK(pc_inb(0x3da)==pc_inb(0x3da));
    pc_clock_advance(26); CHECK((pc_inb(0x3da)&1)==1);
    pc_clock_advance(13110); CHECK((pc_inb(0x3da)&8)==8);
    pc_clock_advance(13200); CHECK((pc_inb(0x3da)&8)==0);
    puts("PASS CRTC stride/start/panning, EGA/VGA split phase, modes, timed retrace");
}
static void test_text(void)
{
    static uint32_t out[720*480]; reset(); tp_CrtInit();
    tp_TextColor(14); tp_TextBackground(1); tp_Window(3,2,7,4); tp_ClrScr();
    const uint8_t msg[]="Hello"; tp_CrtWrite(msg,5);
    CHECK(pc_rd16(0xb800,((1*80)+2)*2)==0x1e48); CHECK(tp_WhereX()==1&&tp_WhereY()==2);
    tp_GotoXY(3,2); CHECK(tp_WhereX()==3); tp_ClrEol();
    tp_Window(1,1,80,25); tp_ClrScr();
    for(unsigned c=0;c<256;++c) pc_wr16(0xb800,(uint16_t)(c*2),(uint16_t)(0x1700|c));
    crtc(10,32); vga_render_rgb(out);
    unsigned lit=0; for(unsigned y=0;y<16;++y) for(unsigned xx=0;xx<9;++xx) if(out[y*720+65*9+xx]==0xffaaaaaa) ++lit;
    CHECK(lit>0 && lit<144); CHECK(platform_screenshot("text-cp437.png"));
    pc_wr16(0xb800,0,0x9700|65); vga_render_rgb(out); uint32_t before[144];
    for(unsigned y=0;y<16;++y) memcpy(before+y*9,out+y*720,9*sizeof(uint32_t));
    pc_clock_advance(266667); vga_render_rgb(out);
    for(unsigned y=0;y<16;++y) for(unsigned xx=0;xx<9;++xx) CHECK(out[y*720+xx]==0xff0000aa);
    attr(0x10,0); vga_render_rgb(out); CHECK(out[0]==0xff5555ff); /* high-intensity background */
    CHECK(before[0]!=0); crtc(10,14); crtc(11,15); pc_clock_advance(533334); vga_render_rgb(out);
    CHECK(out[14*720]==0xffaaaaaa); /* visible cursor */
    pc_regs r={0}; r.ax=0x1130;r.bx=0x0200;pc_bios_int(0x10,&r);CHECK(r.es==0xf000&&r.cx==16&&r.bp==0x0a00);
    r.ax=0x1130;r.bx=0x0300;pc_bios_int(0x10,&r);CHECK(r.cx==16&&r.bp==0x0200);
    r.ax=0x1130;r.bx=0x0600;pc_bios_int(0x10,&r);CHECK(r.cx==16&&r.bp==0x1800);
    puts("PASS text VRAM/Crt window, attributes, blink/intensity, cursor and licensed ROM fonts");
}
static uint16_t read_key(void) { pc_regs r={0}; pc_bios_int(0x16,&r); return r.ax; }
static unsigned break_calls;
static void break_hook(void) { ++break_calls; }
static void test_keyboard(void)
{
    reset(); pc_queue_key(1000,0x1e,1); pc_queue_key(2000,0x1e,0); pc_clock_advance(2000); pc_poll();
    pc_regs r={0}; r.ax=0x0100; pc_bios_int(0x16,&r); CHECK(!(r.flags&0x40)&&r.ax==0x1e61);
    CHECK(read_key()==0x1e61); r.ax=0x0100; pc_bios_int(0x16,&r); CHECK(r.flags&0x40);
    pc_queue_key(3000,0x2a,1); pc_queue_key(3000,0x1e,1); pc_queue_key(3000,0x2a,0); pc_clock_advance(3000); pc_poll(); CHECK(read_key()==0x1e41);
    pc_queue_key(4000,0xe04b,1); pc_clock_advance(4000); pc_poll(); CHECK(tp_ReadKey()==0); CHECK(tp_KeyPressed()); CHECK(tp_ReadKey()==0x4b);
    pc_queue_key(5000,0x1d,1); pc_queue_key(5000,0x2e,1); pc_clock_advance(5000); pc_poll(); CHECK(read_key()==0x2e03);
    r.ax=0x0200;pc_bios_int(0x16,&r);CHECK(r.ax&4);
    for(unsigned n=0;n<20;++n) pc_queue_key(6000,0x20,1);
    pc_clock_advance(6000);pc_poll();unsigned count=0;
    while(tp_KeyPressed()) { (void)read_key(); ++count; } CHECK(count==15);
    pc_queue_key(7000,0x12,1);pc_clock_advance(7000);pc_poll();
    pc_wr16(0x40,0x1c,pc_rd16(0x40,0x1a));CHECK(!tp_KeyPressed());
    pc_queue_key(8000,0x1d,0);pc_queue_key(10000,0x30,1);
    CHECK(read_key()==0x3062); CHECK(pc_time_us()>=10000); /* blocking INT16 allows IRQs */
    tp_SetIntVec(0x1b,pc_register_code(break_hook,"test Ctrl-Break"));
    pc_queue_key(11000,0x1d,1);pc_queue_key(11000,0x46,1);pc_clock_advance(11000);pc_poll();
    CHECK(break_calls==1&&(pc_rd8(0x40,0x71)&128)&&(pc_rd8(0x40,0x18)&16));
    pc_queue_key(12000,0x46,0);pc_clock_advance(12000);pc_poll();CHECK(!(pc_rd8(0x40,0x18)&16));
    puts("PASS BIOS keyboard ring, INT16 peek/read/shift, E0, Crt 0-prefix, full/discard/blocking");
}
static char trace[512];static unsigned trace_len;
static farptr saved_key;
static void tick(void) { CHECK(!pc_interrupts_enabled());trace[trace_len++]='T'; }
static void key_hook(void) { CHECK(!pc_interrupts_enabled());trace[trace_len++]='K';pc_chain_interrupt(saved_key);trace[trace_len++]='X'; }
static void test_scheduler(void)
{
    reset();trace_len=0;tp_GetIntVec(9,&saved_key);tp_SetIntVec(9,pc_register_code(key_hook,"test key"));tp_SetIntVec(0x1c,pc_register_code(tick,"test tick"));
    pc_queue_key(54926,0x1e,1);pc_clock_advance(54926);pc_poll();
    CHECK(trace_len==2&&!memcmp(trace,"TK",2));CHECK(read_key()==0x1e61);CHECK(pc_eoi_count()==2);
    pc_cli();pc_queue_key(60000,0x30,1);pc_clock_advance(120000);pc_poll();CHECK(trace_len==2);
    pc_sti();pc_poll();CHECK(trace_len==4&&!memcmp(trace,"TKKT",4));CHECK(pc_rd16(0x40,0x6c)==2);
    CHECK(pc_interrupts_enabled());
    pc_outb(0x43,0x36);pc_outb(0x40,0x47);pc_outb(0x40,0x21);CHECK(pc_pit_divisor(0)==8519);
    pc_clock_advance(1120000);pc_poll();CHECK(pc_irq_count(8)==142&&pc_rd16(0x40,0x6c)==142);
    CHECK(pc_eoi_count()==144); /* 142 timer + two keyboard IRQs */
    pc_outb(0x43,0);uint16_t counter=pc_inb(0x40);counter|=(uint16_t)(pc_inb(0x40)<<8);CHECK(counter<=8519);
    pc_outb(0x43,0x36);pc_outb(0x40,0);pc_outb(0x40,0);CHECK(pc_pit_divisor(0)==65536);
    uint64_t before=pc_irq_count(8);pc_clock_advance(2120000);pc_poll();CHECK(pc_irq_count(8)-before==18);
    puts("PASS IRQ ordering/IF/IRET/chain, BIOS tick/EOI, PIT rate/reprogram/latch");
}
static void test_joystick(void)
{
    reset();pc_outb(0x201,0);for(unsigned n=0;n<65535;++n) CHECK(pc_inb(0x201)&1);
    int16_t axes[4]={-32768,0,32767,0};pc_joystick_set(1,axes,3);pc_outb(0x201,0);
    unsigned counts[4]={0};
    for(unsigned n=0;n<600;++n) {uint8_t v=pc_inb(0x201);CHECK(!(v&0x30));for(unsigned a=0;a<4;++a) if(v&(1u<<a)) ++counts[a];}
    CHECK(counts[0]==64&&counts[1]==320&&counts[2]==575&&counts[3]==320);
    pc_outb(0x201,0);pc_clock_advance(3000);CHECK((pc_inb(0x201)&3)==0);
    puts("PASS game port RC-loop calibration, timeout, timed discharge and active-low buttons");
}
static void halt_entry(void) { pc_terminate(17); }
static void test_sound_dos(void)
{
    reset();tp_NoSound();tp_Sound(440);CHECK(pc_pit_divisor(2)==1193181/440&&(pc_inb(0x61)&3)==3);
    tp_Sound(0);tp_Sound(18);CHECK(pc_pit_divisor(2)==1193181/440);
    pc_clock_advance(100000);tp_Sound(880);pc_clock_advance(200000);tp_NoSound();pc_clock_advance(300000);
    CHECK(pc_speaker_capture("speaker.wav",300000));
    CHECK(platform_run(halt_entry)==17);
    FILE *f=pc_fopen("MixedCase.DAT","wb");CHECK(f);fwrite("abcde",1,5,f);fclose(f);
    pc_regs r={0};const char *name="mixedcase.dat";memcpy(pc_host(0x5000,0),name,strlen(name)+1);
    r.ax=0x3d00;r.ds=0x5000;pc_bios_int(0x21,&r);CHECK(!(r.flags&1));uint16_t handle=r.ax;
    r.ax=0x3f00;r.bx=handle;r.dx=100;r.cx=5;pc_bios_int(0x21,&r);CHECK(r.ax==5&&!memcmp(pc_host(0x5000,100),"abcde",5));
    r.ax=0x4200;r.cx=0;r.dx=2;pc_bios_int(0x21,&r);CHECK(r.ax==2);
    r.ax=0x4100;r.dx=0;pc_bios_int(0x21,&r);CHECK(!(r.flags&1));
    r.ax=0x4200;r.cx=0;r.dx=1;pc_bios_int(0x21,&r);CHECK(r.ax==1);
    r.ax=0x3f00;r.dx=100;r.cx=3;pc_bios_int(0x21,&r);
    CHECK(r.ax==3&&!memcmp(pc_host(0x5000,100),"bcd",3));
    r.ax=0x3e00;pc_bios_int(0x21,&r);CHECK(!(r.flags&1));
    r.ax=0x4100;r.dx=0;pc_bios_int(0x21,&r);CHECK((r.flags&1)&&r.ax==2);
    puts("PASS speaker TP Sound/NoSound/divisor/zero semantics/WAV, DOS files and launcher unwind");
}
int main(int argc,char **argv)
{
    if(!platform_init(argc,argv)) return 2;
    test_memory();test_vga();test_scanout();test_text();test_keyboard();test_scheduler();test_joystick();test_sound_dos();
    platform_shutdown();puts("ALL PLATFORM TESTS PASSED");return 0;
}
