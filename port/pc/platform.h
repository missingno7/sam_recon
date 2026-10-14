#ifndef SAM_PLATFORM_H
#define SAM_PLATFORM_H
#include "pc.h"
#include <setjmp.h>

/* Host lifecycle/test controls are deliberately outside the binding pc.h. */
int platform_init(int argc, char **argv);
void platform_shutdown(void);
int platform_quit_requested(void);
void platform_present(void);
int platform_screenshot(const char *path);
int platform_run(void (*entry)(void)); /* catches pc_terminate, returns DOS exit code */
void pc_clock_manual(int enabled);
void pc_clock_advance(uint64_t time_us); /* absolute, monotonic; poll delivers due events */
void pc_queue_scan(uint64_t time_us, uint8_t scan);
void pc_queue_key(uint64_t time_us, uint16_t set1, int down);
void pc_joystick_set(int connected, const int16_t axes[4], uint8_t buttons);
uint32_t pc_pit_divisor(unsigned channel);
uint64_t pc_irq_count(unsigned vector);
uint64_t pc_eoi_count(void);
int pc_speaker_capture(const char *path, uint64_t end_us);

void bios_set_mode(uint8_t mode);
uint8_t vga_mode(void);
void vga_set_adapter(int vga); /* default VGA; --ega chooses EGA */
int vga_is_vga(void);
void vga_dimensions(int *width, int *height);
void vga_render_indexed(uint8_t *pixels);
void vga_render_rgb(uint32_t *pixels); /* 0xAARRGGBB, up to 720x480 */
void vga_scanout_dimensions(int *width,int *height); /* doubled physical VGA lines */
void vga_render_scanout_rgb(uint32_t *pixels);
uint32_t vga_colour_rgb(uint8_t palette_code);
const uint8_t *vga_palette_registers(void);
uint32_t vga_border_rgb(void);
void bios_video(pc_regs *r);
void pc_fonts_init(void);
farptr pc_font_pointer(unsigned height);
#endif
