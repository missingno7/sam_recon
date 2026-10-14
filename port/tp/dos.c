/* Turbo Pascal Dos interrupt/vector wrappers over the PC's emulated IVT and BIOS services. */
#include "crt_dos.h"
#include "../pc/platform.h"
#include <string.h>
/* Provided by TP System: copy address-taken C locals into/out of emulated SS. */
void tp_FarSyncIn(void);
void tp_FarSyncOut(void);
_Static_assert(sizeof(pc_regs) == 20, "Dos.Registers width");
/* Synchronise address-taken Pascal locals around an interrupt and copy back its registers. */
void tp_Intr(uint8_t n, void *regs) {
    pc_regs r;
    memcpy(&r, regs, sizeof r);
    tp_FarSyncIn();
    pc_bios_int(n, &r);
    tp_FarSyncOut();
    memcpy(regs, &r, sizeof r);
}
void tp_MsDos(void *regs) {
    tp_Intr(PC_INT_DOS, regs);
}
/* Read/write the four-byte far pointers stored in the real-mode interrupt vector table. */
void tp_GetIntVec(uint8_t n, farptr *p) {
    *p = FP(pc_rd16(PC_IVT_SEGMENT, (uint16_t)(PC_IVT_ENTRY_SIZE * n + 2)),
            pc_rd16(PC_IVT_SEGMENT, (uint16_t)(PC_IVT_ENTRY_SIZE * n)));
}
void tp_SetIntVec(uint8_t n, farptr p) {
    pc_wr16(PC_IVT_SEGMENT, (uint16_t)(PC_IVT_ENTRY_SIZE * n), FP_OFF(p));
    pc_wr16(PC_IVT_SEGMENT, (uint16_t)(PC_IVT_ENTRY_SIZE * n + 2), FP_SEG(p));
}
