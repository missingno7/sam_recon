/* An oversleep may delay the PC, but may not hide a device status pulse.
   This uses raw port reads and ordinary safe points, without a library hint. */
#include "pc/pc_internal.h"
#include <stdio.h>
#define CHECK(x) do { if(!(x)) {fprintf(stderr,"FAIL clock edge line %d: %s\n",__LINE__,#x);return 1;} } while(0)
int main(int argc,char **argv) {
    if(!platform_init(argc,argv))return 2;
    const pc_program p={PC_PSP_SEG,0x3100,0x3900,0x4000,0x3d00,0xa000};
    pc_load_program(&p,NULL,0);pc_clock_manual(0);
    pc_outb(0x43,0x36);pc_outb(0x40,0x47);pc_outb(0x40,0x21);
    uint64_t previous=0;
    for(unsigned n=0;n<8;++n) {
        while(!(pc_inb(0x3da)&8))pc_poll();
        uint64_t start=pc_time_us();
        if(previous)CHECK(start-previous>=14267 && start-previous<=14269);
        previous=start;
        SDL_Delay(4); /* 60 times longer than the retrace pulse */
        CHECK(pc_time_us()==start && (pc_inb(0x3da)&8));
        while(pc_inb(0x3da)&8)pc_poll();
        CHECK(pc_time_us()-start>=63 && pc_time_us()-start<=64);
    }
    pc_poll();
    CHECK(pc_irq_count(8)==pc_time_us()*PC_PIT_HZ/(8519u*1000000ull));
    /* Bound catch-up after a long host stall, retaining the next PC edge. */
    uint64_t before=pc_time_us();SDL_Delay(120);pc_poll();
    CHECK(pc_time_us()>=before && pc_time_us()-before<=14269);
    platform_shutdown();puts("PASS raw retrace pulses survive 4-ms host stalls; PIT edges and bounded catch-up");
    return 0;
}
