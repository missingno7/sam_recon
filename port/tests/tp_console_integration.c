/* Optional integration check against the other worker's real System runtime. */
#include "tp.h"
#include "crt_dos.h"
#include "pc/platform.h"
#include <stdio.h>
#define CHECK(e) do { if(!(e)) {fprintf(stderr,"integration FAIL line %d: %s\n",__LINE__,#e);return 1;} } while(0)
int main(int argc,char **argv)
{
    if(!platform_init(argc,argv)) return 2;
    pc_program p={PC_PSP_SEG,0x3100,0x3900,0x4000,0x3d00,0xa000};pc_load_program(&p,NULL,0);
    pc_clock_manual(1);tp_BindSystem(p.ds_seg,0);tp_BindStandardFiles(0x400,0x500);tp_Init();
    const tp_crt_offsets o={0x100,0x101,0x102,0x103,0x104,0x106,0x108,0x10a};
    tp_BindCrt(p.ds_seg,&o);tp_CrtInit();tp_ClrScr();
    CHECK(tp_PrefixSeg==p.psp_seg);
    CHECK((uint8_t *)&tp_Input==pc_host(p.ds_seg,0x400));
    CHECK((uint8_t *)&tp_Output==pc_host(p.ds_seg,0x500));
    CHECK((uint8_t *)&tp_TextAttr==pc_host(p.ds_seg,o.TextAttr));
    tp_TextColor(14);CHECK(pc_rd8(p.ds_seg,o.TextAttr)==14);
    pc_wr8(p.ds_seg,o.TextAttr,7);CHECK(tp_TextAttr==7);
    CHECK(pc_rd16(p.ds_seg,o.WindMax)==0x184f);
    tp_WriteString(tp_Sliteral((const uint8_t *)"sam",3),5);
    tp_WriteInteger(-123,6);tp_WriteBoolean(1,6);tp_WriteLn();
    const char *wanted="  sam  -123  TRUE";
    for(unsigned i=0;wanted[i];++i) CHECK(pc_rd16(0xb800,(uint16_t)(i*2))==(uint16_t)(0x0700|(uint8_t)wanted[i]));
    CHECK(tp_WhereX()==1&&tp_WhereY()==2);
    uint8_t local[64]={0};uint16_t mark=tp_FrameBegin();farptr f=tp_LocalFar(local,sizeof local);
    pc_regs cpu={0};cpu.ax=0x1b00;cpu.es=FP_SEG(f);cpu.di=FP_OFF(f);
    tp_registers regs;memcpy(regs.bytes,&cpu,sizeof cpu);tp_Intr(0x10,&regs);
    memcpy(&cpu,regs.bytes,sizeof cpu);CHECK(cpu.ax==0x1b&&local[4]==3&&local[5]==80);
    tp_FrameEnd(mark);platform_shutdown();puts("PASS real TP System -> Crt formatted Write/WriteLn and Dos.Intr host-local SS sync");return 0;
}
