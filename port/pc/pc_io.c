#include "pc_internal.h"
#include <string.h>
#include <time.h>

typedef struct {
    uint32_t divisor; uint16_t latch; uint8_t access, mode, low, write_phase, read_phase, latched;
    uint64_t loaded;
} pit_channel;
static pit_channel pit[3];
static uint8_t scan_latch, speaker_port, cmos_index, keyboard_e0;
static uint8_t pressed[256];
static int joy_connected, retrace_reads;
static int16_t joy_axes[4];
static uint8_t joy_buttons;
static uint64_t joy_start;
static uint32_t joy_reads;

int pc_retrace_polling(void) { int v=retrace_reads; retrace_reads=0; return v; }
uint32_t pc_pit_divisor(unsigned n) { return n<3 ? pit[n].divisor : 0; }
void pc_keyboard_latch(uint8_t scan) { scan_latch=scan; }
void pc_devices_reset(void)
{
    memset(pit,0,sizeof pit); memset(pressed,0,sizeof pressed); keyboard_e0=0;
    for (unsigned n=0;n<3;++n) { pit[n].divisor=65536; pit[n].access=3; pit[n].mode=3; }
    speaker_port=0x0c; scan_latch=cmos_index=0; retrace_reads=0;
    joy_connected=0; joy_buttons=0; joy_reads=0; memset(joy_axes,0,sizeof joy_axes);
}
void pc_joystick_set(int connected,const int16_t axes[4],uint8_t buttons)
{
    joy_connected=connected!=0; if (axes) memcpy(joy_axes,axes,sizeof joy_axes);
    joy_buttons=buttons&15;
    uint16_t eq=pc_rd16(0x40,0x10); pc_wr16(0x40,0x10,(uint16_t)((eq&~0x1000u)|(joy_connected ? 0x1000 : 0)));
}
static uint16_t pit_counter(unsigned n)
{
    pit_channel *p=&pit[n];
    uint64_t elapsed=(pc_time_us()-p->loaded)*PC_PIT_HZ/1000000u;
    return (uint16_t)(p->divisor-elapsed%p->divisor);
}
static uint8_t pit_read(unsigned n)
{
    pit_channel *p=&pit[n]; uint16_t v=p->latched ? p->latch : pit_counter(n);
    uint8_t result=p->access==2 || (p->access==3 && p->read_phase) ? (uint8_t)(v>>8) : (uint8_t)v;
    if (p->access==3) p->read_phase^=1;
    if (p->access!=3 || !p->read_phase) p->latched=0;
    return result;
}
static uint8_t cmos_read(void)
{
    /* Fixed epoch + emulated seconds makes scripted RTC reads reproducible. */
    time_t epoch=946684800+(time_t)(pc_time_us()/1000000u);
    struct tm *t=gmtime(&epoch); unsigned v=0;
    switch(cmos_index&127) {
    case 0: v=(unsigned)t->tm_sec; break; case 2: v=(unsigned)t->tm_min; break;
    case 4: v=(unsigned)t->tm_hour; break; case 6: v=(unsigned)t->tm_wday+1; break;
    case 7: v=(unsigned)t->tm_mday; break; case 8: v=(unsigned)t->tm_mon+1; break;
    case 9: v=(unsigned)(t->tm_year+1900)%100; break;
    case 0x0a: return 0x26; case 0x0b: return 2; case 0x0d: return 128;
    }
    return (uint8_t)((v/10)*16+v%10);
}
uint8_t pc_inb(uint16_t port)
{
    uint8_t v;
    if (port==0x3da || port==0x3ba) retrace_reads=1;
    if (vga_port_read(port,&v)) return v;
    switch(port) {
    case 0x40: case 0x41: case 0x42: return pit_read(port-0x40);
    case 0x60: return scan_latch;
    case 0x61: return speaker_port;
    case 0x64: return 0x14;
    case 0x71: return cmos_read();
    case 0x201: {
        v=(uint8_t)(0xf0&~(joy_buttons<<4));
        ++joy_reads;
        /* One game-port read is one 8-us ISA loop quantum. Wall time can discharge
           the capacitor earlier. This also terminates translated CLI loops. */
        uint64_t dt=pc_time_us()-joy_start;
        uint64_t count=dt/8; if (count<joy_reads) count=joy_reads;
        for (unsigned a=0;a<4;++a) {
            unsigned limit=64u+((uint32_t)((int32_t)joy_axes[a]+32768)*512u/65536u);
            if (!joy_connected || count<=limit) v|=(uint8_t)(1u<<a);
        }
        return v;
    }
    default: return 255;
    }
}
uint16_t pc_inw(uint16_t p) { uint16_t v=pc_inb(p); return (uint16_t)(v|(pc_inb((uint16_t)(p+1))<<8)); }
static void pit_write(unsigned n,uint8_t v)
{
    pit_channel *p=&pit[n]; uint32_t d;
    if (p->access==1) d=v;
    else if (p->access==2) d=(uint32_t)v<<8;
    else if (!p->write_phase) { p->low=v; p->write_phase=1; return; }
    else { d=p->low|((uint32_t)v<<8); p->write_phase=0; }
    p->divisor=d ? d : 65536; p->loaded=pc_time_us();
    if (n==0) pc_pit_schedule(p->divisor);
    if (n==2) speaker_change(p->divisor,speaker_port&3,1);
}
void pc_outb(uint16_t port,uint8_t v)
{
    if (vga_port_write(port,v)) return;
    switch(port) {
    case 0x20: if (v&0x20) pc_pic_eoi(); break;
    case 0x40: case 0x41: case 0x42: pit_write(port-0x40,v); break;
    case 0x43: {
        unsigned n=v>>6; if (n>2) break; pit_channel *p=&pit[n];
        unsigned access=(v>>4)&3;
        if (!access) { if (!p->latched) { p->latch=pit_counter(n); p->latched=1; p->read_phase=0; } }
        else { p->access=(uint8_t)access; p->mode=(v>>1)&7; p->write_phase=p->read_phase=0; p->latched=0; }
        break;
    }
    case 0x60: scan_latch=v; break;
    case 0x61:
        if ((v&3)!=(speaker_port&3)) speaker_change(pit[2].divisor,v&3,(v&1) && !(speaker_port&1));
        speaker_port=v; break;
    case 0x70: cmos_index=v; break;
    case 0x201: joy_start=pc_time_us(); joy_reads=0; break;
    }
}
void pc_outw(uint16_t p,uint16_t v) { pc_outb(p,(uint8_t)v); pc_outb((uint16_t)(p+1),(uint8_t)(v>>8)); }

static const char normal[]="\0\x1b" "1234567890-=\b\tqwertyuiop[]\r\0asdfghjkl;'`\0\\zxcvbnm,./\0*\0 \0";
static const char shifted[]="\0\x1b" "!@#$%^&*()_+\b\tQWERTYUIOP{}\r\0ASDFGHJKL:\"~\0|ZXCVBNM<>?\0*\0 \0";
static void ring_put(uint16_t word)
{
    uint16_t h=pc_rd16(0x40,0x1a),t=pc_rd16(0x40,0x1c),next=(uint16_t)(t+2);
    if (next>=0x3e) next=0x1e;
    if (next==h) return;
    pc_wr16(0x40,t,word); pc_wr16(0x40,0x1c,next);
}
void bios_keyboard_irq(void)
{
    unsigned code=scan_latch;
    if (code==0xe0) { keyboard_e0=1; pc_wr8(0x40,0x96,(uint8_t)(pc_rd8(0x40,0x96)|2)); pc_outb(0x20,0x20); return; }
    unsigned sc=code&127, idx=sc+(keyboard_e0 ? 128 : 0); int released=(code&128)!=0;
    int old=pressed[idx]; pressed[idx]=(uint8_t)!released;
    uint8_t flags=pc_rd8(0x40,0x17),secondary=pc_rd8(0x40,0x18);
    if (!keyboard_e0 && (sc==0x2a || sc==0x36)) {
        uint8_t mask=sc==0x2a ? 2 : 1; flags=(uint8_t)((flags&~mask)|(released ? 0 : mask));
    }
    if (sc==0x1d) {
        flags=(uint8_t)((flags&~4u)|((pressed[0x1d]||pressed[0x9d]) ? 4 : 0));
        if (!keyboard_e0) secondary=(uint8_t)((secondary&~1u)|(released ? 0 : 1));
    }
    if (sc==0x38) {
        flags=(uint8_t)((flags&~8u)|((pressed[0x38]||pressed[0xb8]) ? 8 : 0));
        if (!keyboard_e0) secondary=(uint8_t)((secondary&~2u)|(released ? 0 : 2));
    }
    int insert=sc==0x52 && (keyboard_e0 || !(((flags&32)!=0)^((flags&3)!=0)));
    if((sc==0x3a || sc==0x45 || sc==0x46 || insert) && (!keyboard_e0 || insert)) {
        uint8_t mask=(uint8_t)(sc==0x3a ? 64 : sc==0x45 ? 32 : sc==0x46 ? 16 : 128);
        secondary=(uint8_t)((secondary&~mask)|(released ? 0 : mask));
        if(!released&&!old) flags^=mask;
    }
    pc_wr8(0x40,0x17,flags); pc_wr8(0x40,0x18,secondary);
    pc_wr8(0x40,0x96,(uint8_t)(0x10|(pressed[0x9d] ? 4 : 0)|(pressed[0xb8] ? 8 : 0)));
    if(!released && sc==0x46 && (flags&4)) {
        pc_wr8(0x40,0x71,(uint8_t)(pc_rd8(0x40,0x71)|128));
        pc_wr16(0x40,0x1c,pc_rd16(0x40,0x1a)); pc_int(0x1b);
    }
    if (!released && sc!=0x2a && sc!=0x36 && sc!=0x1d && sc!=0x38 && sc!=0x3a && sc!=0x45 && sc!=0x46) {
        uint8_t ascii=0,out_scan=(uint8_t)sc;
        int shift=(flags&3)!=0;
        if (sc<sizeof normal-1) {
            ascii=(uint8_t)(shift ? shifted[sc] : normal[sc]);
            if ((flags&64) && ((ascii>='a'&&ascii<='z')||(ascii>='A'&&ascii<='Z'))) ascii^=32;
            if (flags&4) {
                if ((ascii>='a'&&ascii<='z')||(ascii>='A'&&ascii<='Z')) ascii&=31;
                else if (sc==0x1c) ascii=10;
                else if (sc==0x0e) ascii=127;
                else if (sc==0x1a || sc==0x2b || sc==0x1b) ascii=(uint8_t)(sc==0x1a ? 27 : sc==0x2b ? 28 : 29);
            }
            if (flags&8) ascii=0;
        }
        if (sc>=0x3b && sc<=0x44) out_scan=(uint8_t)(sc+((flags&8) ? 0x2d : (flags&4) ? 0x23 : shift ? 0x19 : 0));
        if (sc==0x57 || sc==0x58) out_scan=(uint8_t)(0x85+sc-0x57+((flags&8) ? 6 : (flags&4) ? 4 : shift ? 2 : 0));
        if (sc>=0x47 && sc<=0x53) {
            const char keypad[]="789-456+1230.";
            if (!keyboard_e0 && (((flags&32)!=0)^shift)) ascii=(uint8_t)keypad[sc-0x47];
            else if (sc==0x4a) ascii='-'; else if(sc==0x4e) ascii='+';
        }
        if (keyboard_e0 && sc==0x35) ascii='/';
        if (ascii || (sc>=0x3b && sc<=0x53) || sc==0x57 || sc==0x58 || (flags&8)) ring_put((uint16_t)((out_scan<<8)|ascii));
    }
    keyboard_e0=0; pc_outb(0x61,(uint8_t)(speaker_port|128)); pc_outb(0x61,(uint8_t)(speaker_port&127)); pc_outb(0x20,0x20);
}
void bios_keyboard(pc_regs *r)
{
    unsigned ah=r->ax>>8;
    if (ah==2 || ah==0x12) { r->ax=pc_rd8(0x40,0x17); if(ah==0x12) r->ax|=(uint16_t)(pc_rd8(0x40,0x18)<<8); return; }
    if (ah!=0 && ah!=1 && ah!=0x10 && ah!=0x11) { fprintf(stderr,"unsupported INT16 AH=%02x\n",ah); abort(); }
    uint16_t h,t;
    for (;;) {
        h=pc_rd16(0x40,0x1a); t=pc_rd16(0x40,0x1c);
        if(h!=t || ah==1 || ah==0x11) break;
        pc_sti(); pc_poll();
        if (platform_quit_requested()) pc_terminate(0);
    }
    if (h==t) { r->flags|=0x40; return; }
    r->flags&=(uint16_t)~0x40u; r->ax=pc_rd16(0x40,h);
    if (ah==0 || ah==0x10) { h+=2; if(h>=0x3e) h=0x1e; pc_wr16(0x40,0x1a,h); }
}
