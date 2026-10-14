/* Trace deterministic BIOS timer and chained keyboard interrupts from scripted input. */
#include "pc/platform.h"
#include "tp/crt_dos.h"
#include <stdio.h>
static farptr old_key;
/* Mark each delivered INT 1Ch callback in the deterministic scheduler trace. */
static void timer(void) {
    printf("%llu T\n", (unsigned long long)pc_time_us());
}
/* Trace IRQ1 and chain to the saved BIOS handler to preserve its acknowledgement path. */
static void keyboard(void) {
    printf("%llu K %02x\n", (unsigned long long)pc_time_us(), pc_inb(PC_PORT_KEYBOARD_DATA));
    pc_chain_interrupt(old_key);
}
/* Install trace handlers and program PIT channel 0 before polling scripted events. */
int main(int argc, char **argv) {
    if (!platform_init(argc, argv))
        return 2;
    pc_program p = {PC_PSP_SEG, 0x3100, 0x3900, 0x4000, 0x3d00, PC_VIDEO_PLANAR_SEGMENT};
    pc_load_program(&p, NULL, 0);
    tp_GetIntVec(PC_INT_KEYBOARD, &old_key);
    tp_SetIntVec(PC_INT_KEYBOARD, pc_register_code(keyboard, "trace IRQ1"));
    tp_SetIntVec(PC_INT_TIMER_CALLBACK, pc_register_code(timer, "trace INT1C"));
    pc_outb(PC_PORT_PIT_CONTROL, PC_PIT_CMD_COUNTER0_LOHI_SQUARE_WAVE);
    pc_outb(PC_PORT_PIT_CHANNEL_0, 0x47);
    pc_outb(PC_PORT_PIT_CHANNEL_0, 0x21);
    while (!platform_quit_requested())
        pc_poll();
    printf("end %llu %llu\n", (unsigned long long)pc_irq_count(PC_INT_TIMER),
           (unsigned long long)pc_irq_count(PC_INT_KEYBOARD));
    platform_shutdown();
    return 0;
}
