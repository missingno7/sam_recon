/* Visible host-only fixture: blue active image, red original overscan. Capture
   with SAM_HOST_CAPTURE and use --border / --no-border on the same settings. */
#include "pc/pc_internal.h"
#include "pc/settings.h"
#include <string.h>
int main(int argc,char **argv) {
    if(!platform_init(argc,argv))return 2;
    pc_program p={PC_PSP_SEG,0x3100,0x3900,0x4000,0x3d00,0xa000};
    pc_load_program(&p,NULL,0);bios_set_mode(0x0d);
    memset(vga_plane(0),255,65536);
    pc_regs r={0};r.ax=0x1001;r.bx=0x0400;pc_bios_int(0x10,&r);
    uint64_t blink=UINT64_MAX;
    while(pc_time_us()<2450000 && !platform_quit_requested()) {
        /* Keep the test image changing so the opt-in GPU capture happens even
           though a static image normally needs just one host presentation. */
        uint64_t now=pc_time_us()/100000;
        if(now!=blink){vga_plane(1)[40]=(uint8_t)(now&1 ? 255 : 0);blink=now;}
        pc_poll();
    }
    int ok=vga_palette_registers()[0x11]==4;
    const char *path=getenv("SAM_HOST_CAPTURE");
    SDL_Surface *host=path ? SDL_LoadPNG(path) : NULL;
    if(!host)ok=0;
    else {
        Uint8 red,green,blue,alpha;
        int x=platform_settings()->border ? 150 : 0;
        int y=platform_settings()->border ? 120 : 0;
        if(!SDL_ReadSurfacePixel(host,x,y,&red,&green,&blue,&alpha))ok=0;
        if(platform_settings()->border)ok &= red==170 && green==0 && blue==0;
        else ok &= red==0 && green==0 && blue==170;
        SDL_DestroySurface(host);
    }
    printf("%s host border=%d, original overscan=%u\n",ok ? "PASS" : "FAIL",
           platform_settings()->border,vga_palette_registers()[0x11]);
    platform_shutdown();return ok ? 0 : 1;
}
