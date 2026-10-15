/* Exercise real SDL events, config parsing and a second DOS load in one window. */
#include "pc/pc_internal.h"
#include "pc/settings.h"
#include <stdlib.h>
#include <string.h>
#define CHECK(x) do { if (!(x)) { fprintf(stderr,"FAIL line %d: %s\n",__LINE__,#x); return 1; } } while (0)
static void key(SDL_Scancode scan, SDL_Keymod mod, int down) {
    SDL_Event event = {0}; event.type = down ? SDL_EVENT_KEY_DOWN : SDL_EVENT_KEY_UP;
    event.key.scancode = scan; event.key.mod = mod; event.key.down = down != 0;
    SDL_PushEvent(&event);
}
int main(int argc, char **argv) {
    if (!platform_init(argc,argv)) return 2;
    pc_program p = {PC_PSP_SEG,0x3100,0x3900,0x4000,0x3d00,0xa000};
    const uint8_t image[] = {1,2,3,4};
    pc_load_program(&p,image,sizeof image); pc_clock_manual(1);
    pc_settings defaults = *platform_settings(), changed = defaults;
    changed.integer_scale = 0; changed.smooth = 1;
    changed.window_width = 640; changed.window_height = 480;
    CHECK(platform_apply_settings(&changed)); platform_present();
    CHECK(pc_settings_save("settings-roundtrip.json",platform_settings()));
    pc_settings loaded; pc_settings_defaults(&loaded);
    CHECK(pc_settings_load("settings-roundtrip.json",&loaded)==1);
    CHECK(loaded.smooth && !loaded.integer_scale && loaded.window_width==640 && loaded.window_height==480);
    FILE *bad = fopen("settings-invalid.json","w"); CHECK(bad);
    fputs("{\"window_width\": 800, \"smooth\": tru}",bad); fclose(bad);
    CHECK(pc_settings_load("settings-invalid.json",&loaded)==-1);
    CHECK(loaded.window_width==640); /* parse failure is transactional */
    key(SDL_SCANCODE_F11,0,1); key(SDL_SCANCODE_F11,0,0); pc_host_pump();
    CHECK(platform_settings()->fullscreen != defaults.fullscreen);
    key(SDL_SCANCODE_RETURN,SDL_KMOD_ALT,1); key(SDL_SCANCODE_RETURN,0,0); pc_host_pump();
    CHECK(platform_settings()->fullscreen == defaults.fullscreen);
    CHECK(pc_irq_count(PC_INT_KEYBOARD)==0); /* consumed host shortcuts */
    pc_clock_advance(200000); pc_poll();
    CHECK(pc_irq_count(PC_INT_KEYBOARD)==2);
    pc_wr8(p.ds_seg,0,255); pc_wr8(0xb800,0,'X');
    pc_outb(0x43,0x36); pc_outb(0x40,0x47); pc_outb(0x40,0x21);
    pc_outb(0x61,3); pc_cli();
    pc_load_program(&p,image,sizeof image);
    CHECK(pc_time_us()==0 && pc_interrupts_enabled());
    CHECK(pc_irq_count(PC_INT_KEYBOARD)==0 && pc_rd8(p.ds_seg,0)==1);
    CHECK(pc_rd8(0xb800,0)==' ' && pc_pit_divisor(0)==65536 && (pc_inb(0x61)&3)==0);
    CHECK(pc_rd16(0x40,0x1a)==pc_rd16(0x40,0x1c));
    pc_clock_advance(150000); pc_poll();
    CHECK(pc_irq_count(PC_INT_KEYBOARD)==2);
    pc_regs r={0};pc_bios_int(0x16,&r); CHECK((r.ax&255)=='b');
    /* The retained script cursor and rebased commands survived the reset. */
    CHECK(platform_apply_settings(&defaults));
    platform_shutdown();
    remove("settings-roundtrip.json"); remove("settings-invalid.json");
    puts("PASS host settings, shortcuts, DOS reset and session script clock");
    return 0;
}
