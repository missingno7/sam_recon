#include "crt_dos.h"
#include <string.h>
/* Provided by TP System: copy address-taken C locals into/out of emulated SS. */
void tp_FarSyncIn(void);
void tp_FarSyncOut(void);
_Static_assert(sizeof(pc_regs)==20,"Dos.Registers width");
void tp_Intr(uint8_t n,void *regs)
{
    pc_regs r; memcpy(&r,regs,sizeof r);
    tp_FarSyncIn(); pc_bios_int(n,&r); tp_FarSyncOut();
    memcpy(regs,&r,sizeof r);
}
void tp_MsDos(void *regs) { tp_Intr(0x21,regs); }
void tp_GetIntVec(uint8_t n,farptr *p) { *p=FP(pc_rd16(0,(uint16_t)(4*n+2)),pc_rd16(0,(uint16_t)(4*n))); }
void tp_SetIntVec(uint8_t n,farptr p) { pc_wr16(0,(uint16_t)(4*n),FP_OFF(p)); pc_wr16(0,(uint16_t)(4*n+2),FP_SEG(p)); }
