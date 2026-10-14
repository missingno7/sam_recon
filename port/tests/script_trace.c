#include "pc/platform.h"
#include "tp/crt_dos.h"
#include <stdio.h>
static farptr old_key;
static void timer(void) {printf("%llu T\n",(unsigned long long)pc_time_us());}
static void keyboard(void) {printf("%llu K %02x\n",(unsigned long long)pc_time_us(),pc_inb(0x60));pc_chain_interrupt(old_key);}
int main(int argc,char **argv)
{
    if(!platform_init(argc,argv)) return 2;
    pc_program p={PC_PSP_SEG,0x3100,0x3900,0x4000,0x3d00,0xa000};pc_load_program(&p,NULL,0);
    tp_GetIntVec(9,&old_key);tp_SetIntVec(9,pc_register_code(keyboard,"trace IRQ1"));tp_SetIntVec(0x1c,pc_register_code(timer,"trace INT1C"));
    pc_outb(0x43,0x36);pc_outb(0x40,0x47);pc_outb(0x40,0x21);
    while(!platform_quit_requested()) pc_poll();
    printf("end %llu %llu\n",(unsigned long long)pc_irq_count(8),(unsigned long long)pc_irq_count(9));
    platform_shutdown();return 0;
}
