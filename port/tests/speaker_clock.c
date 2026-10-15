/* Exercise the actual live callback renderer across a stalled PC clock:
   an oscillator keeps running, future gates/divisors stay in their history. */
#include "pc/pc_internal.h"
#include "tp/crt_dos.h"
#include <math.h>
#define CHECK(x) do {if(!(x)){fprintf(stderr,"FAIL speaker clock line %d: %s\n",__LINE__,#x);return 1;}} while(0)
static float out[4410];
static double frequency(unsigned start,unsigned end) {
    unsigned crossings=0;
    for(unsigned i=start+1;i<end;++i)if(out[i-1]<=0 && out[i]>0)++crossings;
    return crossings*44100.0/(end-start);
}
int main(int argc,char **argv) {
    if(!platform_init(argc,argv))return 2;
    const pc_program p={PC_PSP_SEG,0x3100,0x3900,0x4000,0x3d00,0xa000};
    pc_load_program(&p,NULL,0);pc_clock_manual(1);tp_Sound(440);
    pc_clock_advance(30000);speaker_render_live(out,3528);
    CHECK(fabs(frequency(441,3528)-440)<15);
    pc_clock_advance(40000);tp_Sound(880);speaker_render_live(out,3528);
    CHECK(fabs(frequency(441,3528)-440)<15); /* the 880 Hz change is still in the future */
    pc_clock_advance(60000);speaker_render_live(out,2205);
    CHECK(fabs(frequency(882,2205)-880)<35);
    tp_NoSound();pc_clock_advance(80000);speaker_render_live(out,2205);
    for(unsigned i=882;i<2205;++i)CHECK(fabs(out[i])<1e-10);
    platform_shutdown();puts("PASS live speaker clock: continuous 440 Hz during lag, future 880 Hz and gate held back");
    return 0;
}
