/* Minimal pc.h test double for the differential harness. */
#include "pc.h"
#include "testdouble.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

uint8_t pc_mem[PC_MEM_SIZE];

static pc_program current_program;
static uint8_t port_values[65536];
static libdiff_port_read port_reads[4096];
static uint32_t port_read_count;
static libdiff_port_read port_script[4096];
static uint32_t port_script_count;
static uint32_t port_script_position;
static uint8_t cmos_values[128];
static uint8_t cmos_index;
static uint8_t bios_mode = 3;
static uint8_t bios_adapter_class = 3;
static uint8_t bios_ega_mono;
static int interrupts_enabled = 1;
static uint32_t poll_count;
static uint64_t emulated_time;
static char data_directory[1024] = ".";
static libdiff_port_write port_writes[4096];
static uint32_t port_write_count;
static libdiff_interrupt interrupt_log[256];
static uint32_t interrupt_count;
static FILE *dos_handles[256];
static farptr next_code_address = FP(0xf000, 0x0100);
static struct {
    farptr address;
    pc_code_fn function;
    const char *name;
} registered_code[256];
static size_t registered_code_count;

static uint32_t physical_address(uint16_t segment, uint16_t offset)
{
    return PC_LINEAR(segment, offset);
}

static void append_port_write(uint16_t port, uint8_t value)
{
    if (port_write_count < sizeof(port_writes) / sizeof(port_writes[0])) {
        port_writes[port_write_count].port = port;
        port_writes[port_write_count].value = value;
        ++port_write_count;
    }
}

static void set_carry(pc_regs *registers, int set)
{
    if (set)
        registers->flags |= 1;
    else
        registers->flags &= (uint16_t)~1u;
}

static void dos_open(pc_regs *registers)
{
    char name[260];
    uint16_t segment = registers->ds;
    uint16_t offset = registers->dx;
    size_t i;
    FILE *file;
    uint16_t handle;
    for (i = 0; i + 1 < sizeof(name); ++i) {
        name[i] = (char)pc_rd8(segment, (uint16_t)(offset + i));
        if (name[i] == '\0')
            break;
    }
    name[sizeof(name) - 1] = '\0';
    file = (FILE *)pc_fopen(name, "rb");
    if (file == NULL) {
        registers->ax = 2;
        set_carry(registers, 1);
        return;
    }
    for (handle = 5; handle < 256 && dos_handles[handle] != NULL; ++handle) {
    }
    if (handle >= 256) {
        fclose(file);
        registers->ax = 4;
        set_carry(registers, 1);
        return;
    }
    dos_handles[handle] = file;
    registers->ax = handle;
    set_carry(registers, 0);
}

static void dos_read(pc_regs *registers)
{
    uint16_t handle = registers->bx;
    uint16_t segment = registers->ds;
    uint16_t offset = registers->dx;
    uint16_t requested = registers->cx;
    uint8_t temp[65536];
    size_t count;
    if (handle >= 256 || dos_handles[handle] == NULL) {
        registers->ax = 6;
        set_carry(registers, 1);
        return;
    }
    count = fread(temp, 1, requested, dos_handles[handle]);
    for (size_t i = 0; i < count; ++i)
        pc_wr8(segment, (uint16_t)(offset + i), temp[i]);
    registers->ax = (uint16_t)count;
    set_carry(registers, ferror(dos_handles[handle]) != 0);
}

static void dos_seek(pc_regs *registers)
{
    uint16_t handle = registers->bx;
    uint32_t target = ((uint32_t)registers->cx << 16) | registers->dx;
    long position;
    if (handle >= 256 || dos_handles[handle] == NULL ||
        fseek(dos_handles[handle], (long)target, SEEK_SET) != 0) {
        registers->ax = 1;
        set_carry(registers, 1);
        return;
    }
    position = ftell(dos_handles[handle]);
    registers->ax = (uint16_t)position;
    registers->dx = (uint16_t)((uint32_t)position >> 16);
    set_carry(registers, 0);
}

static void bios_video(pc_regs *registers)
{
    uint8_t ah = (uint8_t)(registers->ax >> 8);
    uint8_t al = (uint8_t)registers->ax;
    if (ah == 0x0f) {
        registers->ax = (uint16_t)((80u << 8) | bios_mode);
        registers->bx = (uint16_t)(registers->bx & 0x00ff);
    } else if (ah == 0) {
        bios_mode = al;
        if (al == 0x0d)
            libdiff_vga_reset();
        registers->ax = (uint16_t)((registers->ax & 0xff00) | al);
    } else if (registers->ax == 0x1c00) {
        registers->ax = (uint16_t)((registers->ax & 0xff00) | 0x1c);
    } else if (registers->ax == 0x1200) {
        if ((uint8_t)registers->bx == 0x32) {
            registers->ax = (uint16_t)((registers->ax & 0xff00) |
                                       (bios_adapter_class == 3 ? 0x12 : 0));
        } else if ((uint8_t)registers->bx == 0x10) {
            registers->cx = bios_adapter_class == 2 ? 0 : 0xffff;
            registers->bx = (uint16_t)((registers->bx & 0x00ff) |
                                       ((uint16_t)bios_ega_mono << 8));
            registers->ax &= 0xff00;
        }
    } else if (ah == 0x10 && al == 0) {
        (void)vga_port_write(0x3c0, (uint8_t)registers->bx);
        (void)vga_port_write(0x3c0, (uint8_t)(registers->bx >> 8));
    } else if (registers->ax == 0x1130) {
        registers->es = 0xf000;
        registers->bp = (uint16_t)((registers->bx >> 8) == 2 ? 0xfa6e : 0xf000);
    }
}

void pc_bios_int(uint8_t vector, pc_regs *registers)
{
    pc_regs input = *registers;
    uint8_t input_memory[260];
    uint16_t input_memory_length = 0;
    if (vector == 0x21 && (uint8_t)(registers->ax >> 8) == 0x3d) {
        for (uint16_t i = 0; i < sizeof(input_memory); ++i) {
            input_memory[i] = pc_rd8(registers->ds, (uint16_t)(registers->dx + i));
            input_memory_length = (uint16_t)(i + 1);
            if (input_memory[i] == 0)
                break;
        }
    }
    if (vector == 0x10) {
        bios_video(registers);
    } else if (vector == 0x21) {
        uint8_t function = (uint8_t)(registers->ax >> 8);
        switch (function) {
        case 0x2b: case 0x2d:
            registers->ax = 0;
            set_carry(registers, 0);
            break;
        case 0x3d: dos_open(registers); break;
        case 0x3e: {
            uint16_t handle = registers->bx;
            if (handle < 256 && dos_handles[handle] != NULL) {
                fclose(dos_handles[handle]);
                dos_handles[handle] = NULL;
                registers->ax = 0;
                set_carry(registers, 0);
            } else {
                registers->ax = 6;
                set_carry(registers, 1);
            }
            break;
        }
        case 0x3f: dos_read(registers); break;
        case 0x42: dos_seek(registers); break;
        default: set_carry(registers, 0); break;
        }
    }
    if (interrupt_count < sizeof(interrupt_log) / sizeof(interrupt_log[0])) {
        interrupt_log[interrupt_count].vector = vector;
        interrupt_log[interrupt_count].input = input;
        interrupt_log[interrupt_count].output = *registers;
        interrupt_log[interrupt_count].input_memory_length = input_memory_length;
        memcpy(interrupt_log[interrupt_count].input_memory, input_memory,
               input_memory_length);
        ++interrupt_count;
    }
}

uint8_t pc_inb(uint16_t port)
{
    uint8_t value;
    if (port_script_position < port_script_count &&
        port_script[port_script_position].port == port) {
        value = port_script[port_script_position++].value;
    } else if (vga_port_read(port, &value)) {
        /* VGA register and status reads use the shared test-double model. */
    } else if (port == 0x71) {
        value = cmos_values[cmos_index & 0x7f];
    } else {
        value = port_values[port];
    }
    if (port_read_count < sizeof(port_reads) / sizeof(port_reads[0])) {
        port_reads[port_read_count].port = port;
        port_reads[port_read_count].value = value;
        ++port_read_count;
    }
    return value;
}

void pc_outb(uint16_t port, uint8_t value)
{
    if (vga_port_write(port, value))
        return;
    append_port_write(port, value);
    if (port == 0x70)
        cmos_index = value & 0x7f;
}

uint16_t pc_inw(uint16_t port)
{
    uint8_t lo = pc_inb(port);
    uint8_t hi = pc_inb((uint16_t)(port + 1));
    return (uint16_t)(lo | ((uint16_t)hi << 8));
}

void pc_outw(uint16_t port, uint16_t value)
{
    pc_outb(port, (uint8_t)value);
    pc_outb((uint16_t)(port + 1), (uint8_t)(value >> 8));
}

uint8_t *pc_host(uint16_t segment, uint16_t offset)
{
    if (segment == 0xa000) {
        fputs("pc_host called for planar A000 memory\n", stderr);
        abort();
    }
    return &pc_mem[physical_address(segment, offset)];
}

uint8_t pc_rd8(uint16_t segment, uint16_t offset)
{
    return pc_mem[physical_address(segment, offset)];
}

uint16_t pc_rd16(uint16_t segment, uint16_t offset)
{
    uint8_t lo = pc_rd8(segment, offset);
    uint8_t hi = pc_rd8(segment, (uint16_t)(offset + 1));
    return (uint16_t)(lo | ((uint16_t)hi << 8));
}

void pc_wr8(uint16_t segment, uint16_t offset, uint8_t value)
{
    pc_mem[physical_address(segment, offset)] = value;
}

void pc_wr16(uint16_t segment, uint16_t offset, uint16_t value)
{
    pc_wr8(segment, offset, (uint8_t)value);
    pc_wr8(segment, (uint16_t)(offset + 1), (uint8_t)(value >> 8));
}

void pc_load_program(const pc_program *layout, const uint8_t *ds_image, size_t ds_size)
{
    current_program = *layout;
    if (ds_image != NULL && ds_size <= 0x10000)
        memcpy(&pc_mem[physical_address(layout->ds_seg, 0)], ds_image, ds_size);
}

const pc_program *pc_current_program(void) { return &current_program; }
farptr pc_register_code(pc_code_fn fn, const char *name)
{
    farptr result;
    for (size_t i = 0; i < registered_code_count; ++i)
        if (registered_code[i].function == fn && strcmp(registered_code[i].name, name) == 0)
            return registered_code[i].address;
    if (registered_code_count >= sizeof(registered_code) / sizeof(registered_code[0])) {
        fputs("pc_register_code table is full\n", stderr);
        abort();
    }
    result = next_code_address;
    next_code_address = FP(FP_SEG(next_code_address), (uint16_t)(FP_OFF(next_code_address) + 16));
    registered_code[registered_code_count].address = result;
    registered_code[registered_code_count].function = fn;
    registered_code[registered_code_count].name = name;
    ++registered_code_count;
    return result;
}
void pc_call_far(farptr target)
{
    for (size_t i = 0; i < registered_code_count; ++i) {
        if (registered_code[i].address == target) {
            registered_code[i].function();
            return;
        }
    }
    fprintf(stderr, "pc_call_far called unregistered address %04X:%04X\n",
            FP_SEG(target), FP_OFF(target));
    abort();
}
void pc_cli(void) { interrupts_enabled = 0; }
void pc_sti(void) { interrupts_enabled = 1; }
int pc_interrupts_enabled(void) { return interrupts_enabled; }
void pc_int(uint8_t vector) { pc_regs registers = {0}; pc_bios_int(vector, &registers); }
void pc_chain_interrupt(farptr old_vector) { (void)old_vector; }
void pc_poll(void) { ++poll_count; ++emulated_time; }
uint64_t pc_time_us(void) { return emulated_time; }
void pc_delay_ms(uint16_t ms) { emulated_time += ms * 1000u; }
const char *pc_data_dir(void) { return data_directory; }
void *pc_fopen(const char *dos_name, const char *mode)
{
    char path[2048];
    if (dos_name == NULL || mode == NULL)
        return NULL;
    if (dos_name[0] == '/' || (dos_name[0] != '\0' && dos_name[1] == ':'))
        return fopen(dos_name, mode);
    (void)snprintf(path, sizeof(path), "%s/%s", data_directory, dos_name);
    return fopen(path, mode);
}
_Noreturn void pc_terminate(uint8_t exit_code) { exit(exit_code); }

void libdiff_reset(void)
{
    memset(pc_mem, 0, sizeof(pc_mem));
    memset(port_values, 0, sizeof(port_values));
    memset(port_reads, 0, sizeof(port_reads));
    memset(cmos_values, 0, sizeof(cmos_values));
    memset(dos_handles, 0, sizeof(dos_handles));
    memset(port_writes, 0, sizeof(port_writes));
    memset(interrupt_log, 0, sizeof(interrupt_log));
    memset(&current_program, 0, sizeof(current_program));
    cmos_index = 0;
    bios_mode = 3;
    bios_adapter_class = 3;
    bios_ega_mono = 0;
    interrupts_enabled = 1;
    poll_count = 0;
    emulated_time = 0;
    port_write_count = 0;
    port_read_count = 0;
    port_script_count = 0;
    port_script_position = 0;
    interrupt_count = 0;
    libdiff_vga_reset();
    samlib_bind_data_offsets(NULL);
}

void libdiff_set_program(uint16_t ds_seg, uint16_t ss_seg, uint16_t sp)
{
    current_program.ds_seg = ds_seg;
    current_program.ss_seg = ss_seg;
    current_program.sp = sp;
    current_program.psp_seg = 0x0800;
}

void libdiff_set_data_dir(const char *path)
{
    if (path != NULL)
        (void)snprintf(data_directory, sizeof(data_directory), "%s", path);
}

void libdiff_set_port_input(uint16_t port, uint8_t value) { port_values[port] = value; }
void libdiff_set_port_script(const libdiff_port_read *reads, uint32_t count)
{
    if (count > sizeof(port_script) / sizeof(port_script[0])) {
        fputs("port script exceeds test-double capacity\n", stderr);
        abort();
    }
    if (reads != NULL && count != 0)
        memcpy(port_script, reads, count * sizeof(*reads));
    port_script_count = count;
    port_script_position = 0;
}
void libdiff_set_interrupts_enabled(int enabled) { interrupts_enabled = enabled != 0; }
void libdiff_set_cmos(uint8_t index, uint8_t value) { cmos_values[index & 0x7f] = value; }
void libdiff_set_bios_mode(uint8_t mode) { bios_mode = mode; }
void libdiff_set_bios_adapter(uint8_t adapter_class, uint8_t ega_mono)
{
    bios_adapter_class = adapter_class;
    bios_ega_mono = ega_mono;
}
uint32_t libdiff_port_write_count(void) { return port_write_count; }
libdiff_port_write libdiff_port_write_at(uint32_t index)
{
    libdiff_port_write empty = {0, 0};
    return index < port_write_count ? port_writes[index] : empty;
}
uint32_t libdiff_port_read_count(void) { return port_read_count; }
libdiff_port_read libdiff_port_read_at(uint32_t index)
{
    libdiff_port_read empty = {0, 0};
    return index < port_read_count ? port_reads[index] : empty;
}
uint32_t libdiff_interrupt_count(void) { return interrupt_count; }
libdiff_interrupt libdiff_interrupt_at(uint32_t index)
{
    libdiff_interrupt empty;
    memset(&empty, 0, sizeof(empty));
    return index < interrupt_count ? interrupt_log[index] : empty;
}
int libdiff_interrupts_enabled(void) { return interrupts_enabled; }
uint32_t libdiff_poll_count(void) { return poll_count; }
void libdiff_set_data_offsets(const samlib_data_offsets *offsets) { samlib_bind_data_offsets(offsets); }

const char *libdiff_code_name(farptr address)
{
    for (size_t i = 0; i < registered_code_count; ++i)
        if (registered_code[i].address == address)
            return registered_code[i].name;
    return NULL;
}
