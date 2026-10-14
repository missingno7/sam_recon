/* pc.h - the emulated PC under the Secret Agent port (contract: docs/port.md).

   Users: the generated game code (tools/pas2c.py), the TP runtime (port/tp), the assembly
   libraries rewritten in C (port/lib) and the SDL front end.  Implemented in port/pc.
   Widths follow the DOS program; far pointers are uint32_t (offset low word, segment high). */

#ifndef SAM_PC_H
#define SAM_PC_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ---- real-mode memory ---- */
#define PC_MEM_SIZE 0x110000u                  /* 1 MB + the 64 KB above it (wrap region) */
extern uint8_t pc_mem[PC_MEM_SIZE];

typedef uint32_t farptr;                       /* TP Pointer: seg:off as stored in memory */
#define FP(seg, off)   ((farptr)(((uint32_t)(uint16_t)(seg) << 16) | (uint16_t)(off)))
#define FP_SEG(p)      ((uint16_t)((uint32_t)(p) >> 16))
#define FP_OFF(p)      ((uint16_t)(p))
#define PC_LINEAR(seg, off) ((((uint32_t)(uint16_t)(seg) << 4) + (uint16_t)(off)) & 0xFFFFFu)

/* Host address of seg:off.  A000:xxxx (EGA planes) is not plain memory: pc_host aborts with a
   message for it; planar video is reached through vga_* only. */
uint8_t *pc_host(uint16_t seg, uint16_t off);
static inline uint8_t *pc_host_fp(farptr p) { return pc_host(FP_SEG(p), FP_OFF(p)); }

/* Byte/word access with real-mode offset wrap inside the segment (a word at off 0xFFFF takes its
   high byte from off 0 of the same segment, as on the 8086). */
uint8_t  pc_rd8(uint16_t seg, uint16_t off);
uint16_t pc_rd16(uint16_t seg, uint16_t off);
void     pc_wr8(uint16_t seg, uint16_t off, uint8_t v);
void     pc_wr16(uint16_t seg, uint16_t off, uint16_t v);

/* Program placement: segments of the PSP, DS and SS for the episode being run, and the top of
   conventional memory (the heap ends there). */
#define PC_PSP_SEG 0x0800u
typedef struct {
    uint16_t psp_seg, ds_seg, ss_seg, sp, heap_org_seg, mem_top_seg;
} pc_program;
void pc_load_program(const pc_program *layout, const uint8_t *ds_image, size_t ds_size);
const pc_program *pc_current_program(void);

/* ---- code addresses ----
   C functions that the DOS program addresses as far pointers (interrupt procedures, ExitProc
   handlers, BIOS handlers) get a far address in a reserved segment. */
typedef void (*pc_code_fn)(void);
farptr pc_register_code(pc_code_fn fn, const char *name);
void   pc_call_far(farptr target);            /* call a registered far address */

/* ---- interrupts ----
   Delivery happens only at safe points (pc_poll) and only while IF is set; an interrupt handler
   runs with IF clear and the flags are restored after it (IRET). */
void pc_cli(void);
void pc_sti(void);
int  pc_interrupts_enabled(void);
void pc_int(uint8_t vector);                  /* software INT n through the emulated IVT */
void pc_chain_interrupt(farptr old_vector);    /* the TP interrupt-chaining idiom: jump to the
                                                  saved handler, which returns to the interrupted
                                                  code (the chaining handler does not resume) */
void pc_poll(void);                            /* safe point: due IRQs, frame presentation,
                                                  SDL events; sleeps when a loop only spins */

/* ---- CPU-level registers for INT calls (Dos.Registers layout) ---- */
typedef struct {
    uint16_t ax, bx, cx, dx, bp, si, di, ds, es, flags;
} pc_regs;
void pc_bios_int(uint8_t vector, pc_regs *r); /* INT 10h/11h/16h/1Ah/21h subsets the game uses */

/* ---- I/O ports ---- */
uint8_t pc_inb(uint16_t port);
void    pc_outb(uint16_t port, uint8_t value);
uint16_t pc_inw(uint16_t port);
void    pc_outw(uint16_t port, uint16_t value); /* low byte to port, high byte to port + 1 */

/* ---- time ---- */
uint64_t pc_time_us(void);                     /* monotonic emulated time */
void     pc_delay_ms(uint16_t ms);            /* waits, polling at safe points meanwhile */

/* ---- EGA/VGA (planar memory at A000 and its registers) ----
   Same model and API as duke1_recon/port/vga.c: map mask, read map, write modes 0-2,
   set/reset, rotate/function, bit mask, latches, CRTC start address, offset, line compare,
   attribute controller palette and pel panning. */
uint8_t *vga_plane(int plane);
void     vga_cpu_write(uint16_t offset, uint8_t value);
uint8_t  vga_cpu_read(uint16_t offset);
int      vga_port_write(uint16_t port, uint8_t value);   /* 1 if the port is a VGA port */
int      vga_port_read(uint16_t port, uint8_t *value);

/* ---- host files (case-insensitive lookup in the data directory) ---- */
const char *pc_data_dir(void);
void *pc_fopen(const char *dos_name, const char *mode); /* FILE * */

/* ---- program end ---- */
_Noreturn void pc_terminate(uint8_t exit_code);  /* INT 21h AH=4Ch: unwinds to the launcher */

#ifdef __cplusplus
}
#endif
#endif
