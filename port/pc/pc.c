#include "pc_internal.h"
#include <stdlib.h>
#include <string.h>
#include <limits.h>

uint8_t pc_mem[PC_MEM_SIZE];
static pc_program program;
static struct { pc_code_fn fn; const char *name; } code[2048];
static unsigned code_count;
static int interrupt_flag=1, polling;
static uint64_t counts[256], eois;
static pc_regs *call_regs;
typedef struct irq_frame { jmp_buf jump; struct irq_frame *previous; } irq_frame;
static irq_frame *frame;
static jmp_buf exit_jump;
static int exit_ready, exit_status;
static int manual_clock;
static uint64_t manual_us, wall_origin, event_us;
static int event_clock;
static uint64_t pit_origin, pit_number=1, pit_next;
static uint32_t pit_divisor=65536;
static uint64_t frame_number=1, frame_next;
static unsigned spins;
static uint64_t last_poll;
typedef struct { uint64_t time; uint8_t scan; } key_event;
static key_event keys[8192];
static size_t key_count;

static void fatal(const char *message) { fprintf(stderr,"PC: %s\n",message); abort(); }
uint8_t *pc_host(uint16_t seg,uint16_t off)
{
    uint32_t addr=PC_LINEAR(seg,off);
    if (seg==0xa000 || (addr>=0xa0000 && addr<0xb0000)) fatal("A000 planar memory requires vga_* access");
    return pc_mem+addr;
}
uint8_t pc_rd8(uint16_t s,uint16_t o) { return *pc_host(s,o); }
uint16_t pc_rd16(uint16_t s,uint16_t o) { return (uint16_t)(pc_rd8(s,o)|(pc_rd8(s,(uint16_t)(o+1))<<8)); }
void pc_wr8(uint16_t s,uint16_t o,uint8_t v)
{
    uint32_t a=PC_LINEAR(s,o); *pc_host(s,o)=v;
    if (a<0x10000) pc_mem[0x100000+a]=v;
}
void pc_wr16(uint16_t s,uint16_t o,uint16_t v) { pc_wr8(s,o,(uint8_t)v); pc_wr8(s,(uint16_t)(o+1),(uint8_t)(v>>8)); }
const pc_program *pc_current_program(void) { return &program; }
farptr pc_register_code(pc_code_fn fn,const char *name)
{
    if (!fn) return 0;
    for (unsigned i=0;i<code_count;++i) if (code[i].fn==fn) return FP(0xf000,0x6000+i*4);
    if (code_count==2048) fatal("code registry full");
    code[code_count].fn=fn; code[code_count].name=name;
    return FP(0xf000,0x6000+code_count++*4);
}
void pc_call_far(farptr target)
{
    if (!target) return;
    /* Accept alias segment:offset spellings of a registered address. */
    uint32_t a=PC_LINEAR(FP_SEG(target),FP_OFF(target));
    if (a<0xf6000 || a>=0xf6000+code_count*4 || ((a-0xf6000)&3)) {
        fprintf(stderr,"PC: unregistered far call %04x:%04x\n",FP_SEG(target),FP_OFF(target)); abort();
    }
    code[(a-0xf6000)/4].fn();
}
void pc_cli(void) { interrupt_flag=0; }
void pc_sti(void) { interrupt_flag=1; }
int pc_interrupts_enabled(void) { return interrupt_flag; }
void pc_int(uint8_t n)
{
    int saved=interrupt_flag;
    irq_frame local; local.previous=frame; frame=&local;
    interrupt_flag=0; ++counts[n];
    if (!setjmp(local.jump)) pc_call_far(FP(pc_rd16(0,(uint16_t)(4*n+2)),pc_rd16(0,(uint16_t)(4*n))));
    frame=local.previous; interrupt_flag=saved;
}
void pc_chain_interrupt(farptr old)
{
    irq_frame *return_frame=frame;
    if (!return_frame) fatal("interrupt chain outside interrupt");
    pc_call_far(old);
    longjmp(return_frame->jump,1);
}
uint64_t pc_irq_count(unsigned n) { return n<256 ? counts[n] : 0; }
uint64_t pc_eoi_count(void) { return eois; }
void pc_pic_eoi(void) { ++eois; }

uint64_t pc_time_us(void)
{
    if (event_clock) return event_us;
    return manual_clock ? manual_us : SDL_GetTicksNS()/1000u-wall_origin;
}
void pc_clock_manual(int on)
{
    uint64_t now=pc_time_us(); manual_clock=on!=0; manual_us=now;
    if (!on) wall_origin=SDL_GetTicksNS()/1000u-now;
}
void pc_clock_advance(uint64_t t)
{
    if (!manual_clock || t<manual_us) fatal("invalid manual clock advance");
    manual_us=t;
}
static uint64_t pit_deadline(void)
{
    return pit_origin+(pit_number*pit_divisor*1000000u+PC_PIT_HZ-1)/PC_PIT_HZ;
}
void pc_pit_schedule(uint32_t divisor)
{
    pit_divisor=divisor; pit_origin=pc_time_us(); pit_number=1; pit_next=pit_deadline();
}
void pc_queue_scan(uint64_t t,uint8_t scan)
{
    if (key_count==sizeof keys/sizeof keys[0]) fatal("keyboard event queue full");
    size_t i=key_count++;
    while (i && keys[i-1].time>t) { keys[i]=keys[i-1]; --i; }
    keys[i].time=t; keys[i].scan=scan;
}
void pc_queue_key(uint64_t t,uint16_t scan,int down)
{
    if (scan&0xff00) pc_queue_scan(t,(uint8_t)(scan>>8));
    pc_queue_scan(t,(uint8_t)(scan | (down ? 0 : 128)));
}
void pc_wait_until(uint64_t when)
{
    uint64_t now=pc_time_us();
    if (when<=now) return;
    if (manual_clock) manual_us=when;
    else SDL_DelayNS((when-now)*1000u);
}
void pc_poll(void)
{
    if (polling) return; /* generated handler entry/back-edge safe points */
    polling=1;
    pc_host_pump();
    uint64_t target=pc_time_us();
    int work=0;
    for (;;) {
        uint64_t script=pc_script_next(), due=script;
        int kind=0;
        /* Equal timestamps: IRQ0, IRQ1, script commands, display. */
        if (interrupt_flag && pit_next<=due) { due=pit_next; kind=1; }
        if (interrupt_flag && key_count && keys[0].time<due) { due=keys[0].time; kind=2; }
        if (frame_next<due) { due=frame_next; kind=3; }
        if (due>target || due==UINT64_MAX) break;
        event_clock=1; event_us=due; work=1;
        if (kind==1) {
            ++pit_number; pit_next=pit_deadline(); pc_int(8);
        } else if (kind==2) {
            uint8_t scan=keys[0].scan;
            --key_count; memmove(keys,keys+1,key_count*sizeof keys[0]);
            pc_keyboard_latch(scan); pc_int(9);
        } else if (kind==3) {
            platform_present(); ++frame_number; frame_next=(frame_number*1000000u+69)/70;
        } else pc_script_dispatch(due);
        event_clock=0;
    }
    if (work || target>last_poll+1000) spins=0;
    else ++spins;
    last_poll=target;
    if (spins>=32) {
        uint64_t next=frame_next, script=pc_script_next();
        if (script<next) next=script;
        if (interrupt_flag && pit_next<next) next=pit_next;
        if (interrupt_flag && key_count && keys[0].time<next) next=keys[0].time;
        /* 3DA polling must also observe both horizontal blank/retrace phases. */
        uint64_t line=((target*70u*449u/1000000u+1)*1000000u+70u*449u-1)/(70u*449u);
        if (pc_retrace_polling() && line<next) next=line;
        pc_wait_until(next); spins=0;
    }
    polling=0;
    if(exit_ready && platform_quit_requested()) pc_terminate(0);
}
void pc_delay_ms(uint16_t ms)
{
    uint64_t end=pc_time_us()+(uint64_t)ms*1000u;
    while (pc_time_us()<end && !platform_quit_requested()) {
        pc_poll();
        uint64_t now=pc_time_us(), next=now+1000;
        if (pit_next>now && pit_next<next) next=pit_next;
        if (key_count && keys[0].time>now && keys[0].time<next) next=keys[0].time;
        if (pc_script_next()>now && pc_script_next()<next) next=pc_script_next();
        pc_wait_until(next<end ? next : end);
    }
    pc_poll();
}

static void bios_noop(void) {}
static void bios_timer(void)
{
    uint32_t tick=pc_rd16(0x40,0x6c)|((uint32_t)pc_rd16(0x40,0x6e)<<16);
    if (++tick>=0x1800b0) { tick=0; pc_wr8(0x40,0x70,(uint8_t)(pc_rd8(0x40,0x70)+1)); }
    pc_wr16(0x40,0x6c,(uint16_t)tick); pc_wr16(0x40,0x6e,(uint16_t)(tick>>16));
    pc_int(0x1c); pc_outb(0x20,0x20);
}
static void bios_equipment(void) { call_regs->ax=pc_rd16(0x40,0x10); }
static void bios_video_wrapper(void) { bios_video(call_regs); }
static void bios_key_wrapper(void) { bios_keyboard(call_regs); }
static void bios_dos_wrapper(void) { bios_dos(call_regs); }
static void bios_clock(void)
{
    if (!(call_regs->ax>>8)) {
        call_regs->cx=pc_rd16(0x40,0x6e); call_regs->dx=pc_rd16(0x40,0x6c);
        call_regs->ax=pc_rd8(0x40,0x70); pc_wr8(0x40,0x70,0);
    }
}
void pc_bios_int(uint8_t vector,pc_regs *r)
{
    if(getenv("SAM_TRACE")) fprintf(stderr,"INT%02x ax=%04x bx=%04x cx=%04x ds=%04x dx=%04x time=%llu\n",
                                  vector,r->ax,r->bx,r->cx,r->ds,r->dx,(unsigned long long)pc_time_us());
    pc_regs *previous=call_regs; call_regs=r; pc_int(vector); call_regs=previous;
}
void pc_load_program(const pc_program *layout,const uint8_t *image,size_t size)
{
    if (!layout || layout->psp_seg<0x100 || layout->mem_top_seg>0xa000 ||
        layout->heap_org_seg>layout->mem_top_seg || layout->ds_seg>=layout->mem_top_seg ||
        layout->ss_seg>=layout->mem_top_seg || size>65536 ||
        ((uint32_t)layout->ds_seg<<4)+size>((uint32_t)layout->mem_top_seg<<4)) fatal("invalid program placement");
    program=*layout; memset(pc_mem,0,sizeof pc_mem); memset(counts,0,sizeof counts);
    code_count=0; interrupt_flag=1; polling=event_clock=0; call_regs=NULL; frame=NULL;
    key_count=0; eois=0; wall_origin=SDL_GetTicksNS()/1000u; manual_us=0;
    pit_origin=0; pit_number=1; pit_divisor=65536; pit_next=pit_deadline();
    frame_number=1; frame_next=(1000000u+69)/70; spins=0; last_poll=0;
    pc_devices_reset(); pc_dos_reset(); speaker_reset();
    farptr empty=pc_register_code(bios_noop,"BIOS IRET");
    for (unsigned n=0;n<256;++n) { pc_wr16(0,(uint16_t)(4*n),FP_OFF(empty)); pc_wr16(0,(uint16_t)(4*n+2),FP_SEG(empty)); }
    const struct { unsigned n; pc_code_fn fn; const char *name; } services[]={
        {8,bios_timer,"BIOS IRQ0"},{9,bios_keyboard_irq,"BIOS IRQ1"},
        {0x10,bios_video_wrapper,"BIOS video"},{0x11,bios_equipment,"BIOS equipment"},
        {0x16,bios_key_wrapper,"BIOS keyboard"},{0x1a,bios_clock,"BIOS clock"},
        {0x21,bios_dos_wrapper,"DOS"}
    };
    for (size_t i=0;i<sizeof services/sizeof services[0];++i) {
        farptr f=pc_register_code(services[i].fn,services[i].name);
        pc_wr16(0,(uint16_t)(services[i].n*4),FP_OFF(f)); pc_wr16(0,(uint16_t)(services[i].n*4+2),FP_SEG(f));
    }
    pc_wr16(0x40,0x10,0x0021); /* disk present, colour display, no joystick initially */
    pc_wr16(0x40,0x13,640); pc_wr16(0x40,0x1a,0x1e); pc_wr16(0x40,0x1c,0x1e);
    pc_wr16(0x40,0x80,0x1e); pc_wr16(0x40,0x82,0x3e);
    pc_wr8(0x40,0x87,0x60); pc_wr8(0x40,0x88,9); pc_wr8(0x40,0x89,0x51); pc_wr8(0x40,0x96,0x10);
    pc_fonts_init(); bios_set_mode(3);
    uint16_t p=layout->psp_seg, env=(uint16_t)(p-0x10);
    pc_wr16(p,0,0x20cd); pc_wr16(p,2,layout->mem_top_seg); pc_wr16(p,0x16,p);
    pc_wr16(p,0x2c,env); pc_wr16(p,0x80,0x0d00);
    for (unsigned i=0;i<20;++i) pc_wr8(p,(uint16_t)(0x18+i),(uint8_t)(i<5 ? i : 255));
    pc_wr16(p,0x32,20); pc_wr16(p,0x34,0x18); pc_wr16(p,0x36,p);
    const char environment[]="PATH=.\0COMSPEC=COMMAND.COM\0\0\1\0SAM.EXE\0";
    memcpy(pc_host(env,0),environment,sizeof environment);
    if (size) { if (!image) fatal("missing DS image"); memcpy(pc_host(layout->ds_seg,0),image,size); }
}
int platform_run(void (*entry)(void))
{
    exit_ready=1; exit_status=0;
    if (!setjmp(exit_jump)) entry();
    exit_ready=0; polling=event_clock=0; frame=NULL; call_regs=NULL;
    return exit_status;
}
_Noreturn void pc_terminate(uint8_t status)
{
    exit_status=status;
    pc_outb(0x61,(uint8_t)(pc_inb(0x61)&~3u));
    if (exit_ready) longjmp(exit_jump,1);
    platform_shutdown(); exit(status);
}
