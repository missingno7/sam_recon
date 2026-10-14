#ifndef SAM_LIBDIFF_TESTDOUBLE_H
#define SAM_LIBDIFF_TESTDOUBLE_H

#include "../lib/samlib.h"

#define LIBDIFF_EXPORT __declspec(dllexport)

typedef struct {
    uint16_t port;
    uint8_t value;
} libdiff_port_write;

typedef struct {
    uint8_t vector;
    pc_regs input;
    pc_regs output;
    uint16_t input_memory_length;
    uint8_t input_memory[260];
} libdiff_interrupt;

typedef struct {
    uint16_t port;
    uint8_t value;
} libdiff_port_read;

LIBDIFF_EXPORT void libdiff_reset(void);
LIBDIFF_EXPORT void libdiff_set_program(uint16_t ds_seg, uint16_t ss_seg, uint16_t sp);
LIBDIFF_EXPORT void libdiff_set_data_dir(const char *path);
LIBDIFF_EXPORT void libdiff_set_port_input(uint16_t port, uint8_t value);
LIBDIFF_EXPORT void libdiff_set_port_script(const libdiff_port_read *reads, uint32_t count);
LIBDIFF_EXPORT void libdiff_set_interrupts_enabled(int enabled);
LIBDIFF_EXPORT void libdiff_set_cmos(uint8_t index, uint8_t bcd_value);
LIBDIFF_EXPORT void libdiff_set_bios_mode(uint8_t mode);
LIBDIFF_EXPORT void libdiff_set_bios_adapter(uint8_t adapter_class, uint8_t ega_mono);
LIBDIFF_EXPORT uint32_t libdiff_port_write_count(void);
LIBDIFF_EXPORT libdiff_port_write libdiff_port_write_at(uint32_t index);
LIBDIFF_EXPORT uint32_t libdiff_port_read_count(void);
LIBDIFF_EXPORT libdiff_port_read libdiff_port_read_at(uint32_t index);
LIBDIFF_EXPORT uint32_t libdiff_interrupt_count(void);
LIBDIFF_EXPORT libdiff_interrupt libdiff_interrupt_at(uint32_t index);
LIBDIFF_EXPORT int libdiff_interrupts_enabled(void);
LIBDIFF_EXPORT uint32_t libdiff_poll_count(void);
LIBDIFF_EXPORT void libdiff_set_data_offsets(const samlib_data_offsets *offsets);
LIBDIFF_EXPORT void libdiff_vga_reset(void);
LIBDIFF_EXPORT void libdiff_vga_copy_state(uint8_t *dst, size_t capacity);
LIBDIFF_EXPORT const char *libdiff_code_name(farptr address);
#endif
