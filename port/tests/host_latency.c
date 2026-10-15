/* Measure SDL event -> BIOS delivery while the PC is blocked on a real window.
   The timer posts ordinary SDL keys; it never writes emulated input/state. */
#include "pc/pc_internal.h"
#include <stdatomic.h>
static _Atomic uint64_t injected;
static uint64_t total,maximum;
static Uint32 SDLCALL inject(void *unused,SDL_TimerID id,Uint32 interval) {
    (void)unused;(void)id;(void)interval;
    SDL_Event e={0};e.type=SDL_EVENT_KEY_DOWN;e.key.scancode=SDL_SCANCODE_A;e.key.key=SDLK_A;
    e.key.down=true;e.key.timestamp=SDL_GetTicksNS();atomic_store(&injected,e.key.timestamp);
    SDL_PushEvent(&e);
    e.type=SDL_EVENT_KEY_UP;e.key.down=false;SDL_PushEvent(&e);
    return 0;
}
static void entry(void) {
    const pc_program p={PC_PSP_SEG,0x3100,0x3900,0x4000,0x3d00,0xa000};
    pc_load_program(&p,NULL,0);
    pc_outb(0x43,0x36);pc_outb(0x40,0x47);pc_outb(0x40,0x21);
    for(unsigned i=0;i<12;++i) {
        if(!SDL_AddTimer(20,inject,NULL))pc_terminate(2);
        pc_regs r={0};pc_bios_int(0x16,&r);
        if((r.ax&255)!='a')pc_terminate(3);
        uint64_t ns=SDL_GetTicksNS()-atomic_load(&injected);
        total+=ns;if(ns>maximum)maximum=ns;
    }
    pc_terminate(0);
}
int main(int argc,char **argv) {
    if(!platform_init(argc,argv))return 2;
    int status=platform_run(entry);platform_shutdown();
    printf("INPUT latency samples=12 average_us=%.1f max_us=%.1f\n",total/12000.0,maximum/1000.0);
    return status || maximum>10000000u;
}
