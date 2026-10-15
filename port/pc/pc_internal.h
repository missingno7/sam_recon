#ifndef SAM_PC_INTERNAL_H
#define SAM_PC_INTERNAL_H
/* Private shared device, scheduler, and SDL hooks for the emulated PC implementation. */
#include "platform.h"
#include <SDL3/SDL.h>
#include <stdio.h>
#define PC_PIT_HZ 1193182u
#define PC_AUDIO_RATE 44100u
void pc_devices_reset(void);
void pc_pic_eoi(void);
int pc_retrace_polling(void);
void pc_pit_schedule(uint32_t divisor);
void pc_keyboard_latch(uint8_t scan);
void bios_keyboard_irq(void);
void bios_keyboard(pc_regs *r);
void bios_dos(pc_regs *r);
void pc_dos_reset(void);
void pc_host_pump(void);
void pc_host_program_reset(void);
uint64_t pc_script_next(void);
void pc_script_dispatch(uint64_t now);
void pc_wait_until(uint64_t when);
void pc_request_quit(void);
void pc_set_data_dir(const char *dir);
void speaker_reset(void);
void speaker_change(uint32_t divisor, uint8_t gate, int restart);
int speaker_init(int enabled);
void speaker_shutdown(void);
void speaker_render(float *out, size_t count, uint64_t *sample_index, size_t *event_index,
                    uint32_t *divisor, uint8_t *gate, double *phase, float *filter);
#endif
