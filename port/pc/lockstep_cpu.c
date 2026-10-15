/* Native instruction hook for the pinned Unicorn C ABI. No game bytes or
   routine-specific emulation: addresses/names come from the reference MAP. */
#include "lockstep.h"
#include <string.h>
#include <stdlib.h>
typedef int (*uc_stop_fn)(void *);
static uc_stop_fn stop_cpu;
typedef int (*uc_read_fn)(void *, int, void *);
typedef int (*uc_write_fn)(void *, int, const void *);
static uc_read_fn read_reg;
static uc_write_fn write_reg;
static void *active_cpu;
static int registers[15]; /* pc_regs fields, then SS, SP, EFLAGS, CS, IP */
void pc_lockstep_cpu_api(uc_read_fn rd, uc_write_fn wr, const int *ids) {
    read_reg = rd; write_reg = wr; memcpy(registers, ids, sizeof registers);
}
static uint64_t instructions, stop_address, reason_value;
static int reason, requested, wait_enabled;
static uint64_t skip_wait=UINT64_MAX, delay_entry=UINT64_MAX;
static uint32_t watch_ds;
typedef struct { uint64_t address; unsigned kind; int es_di; } wait_point;
static wait_point wait_points[256];
static unsigned wait_count;
static const char *executing_routine="<startup>";
typedef struct { uint64_t value, instruction; uint32_t pc; uint16_t width; const char *routine; uint16_t start; uint8_t byte_value; } stack_writer;
static stack_writer stack_writes[65536];
void pc_lockstep_cpu_wait_mode(int enabled,uint16_t ds) { wait_enabled=enabled; watch_ds=ds; }
void pc_lockstep_cpu_wait_point(uint64_t address,unsigned kind,int es_di) {
    if (wait_count==256) abort();
    wait_points[wait_count++]=(wait_point){address,kind,es_di};
}
void pc_lockstep_cpu_skip_wait(uint64_t address) { skip_wait=address; }
void pc_lockstep_cpu_delay(uint64_t address) { delay_entry=address; }
void pc_lockstep_cpu_break(int kind, uint64_t value);
void pc_lockstep_cpu_stack_write(uint16_t ss,uint16_t off,unsigned size,uint64_t value,uint32_t address) {
    if (ss!=pc_current_program()->ss_seg) return;
    if (size>8) { pc_lockstep_cpu_break(9,size); return; }
    for (unsigned i=0;i<size;++i) stack_writes[(off+i)&65535]=(stack_writer){value,instructions,address,(uint16_t)size,executing_routine,off,(uint8_t)(value>>(8*i))};
}
void pc_lockstep_cpu_host_write(uint16_t seg,uint16_t off,const uint8_t *data,unsigned count,const char *name) {
    if (!active_cpu) return;
    const pc_program *program=pc_current_program();
    uint32_t address=PC_LINEAR(seg,off), start=(uint32_t)program->ss_seg*16;
    uint32_t cs=0,ip=0;
    if (address>=start+program->sp || address+count<=start) return;
    read_reg(active_cpu,registers[13],&cs); read_reg(active_cpu,registers[14],&ip);
    for (unsigned i=0;i<count;++i) if (address+i>=start && address+i<start+program->sp) {
        unsigned pos=address+i-start;
        pc_lockstep_cpu_stack_write(program->ss_seg,(uint16_t)pos,1,data[i],cs*16+ip);
        const char *identity=pc_lockstep_code_name(FP(cs,ip));
        stack_writes[pos].routine=identity ? identity : name;
    }
}
unsigned pc_lockstep_cpu_stack_start(unsigned off) { return stack_writes[off&65535].start; }
unsigned pc_lockstep_cpu_stack_byte(unsigned off) { return stack_writes[off&65535].byte_value; }
const char *pc_lockstep_cpu_stack_last(unsigned off,uint64_t *value,uint64_t *instruction,uint32_t *pc,unsigned *width) {
    stack_writer *w=&stack_writes[off&65535];
    *value=w->value; *instruction=w->instruction; *pc=w->pc; *width=w->width; return w->routine;
}
void pc_lockstep_cpu_memory_write(void *uc,int access,uint64_t address,int size,int64_t value,void *user) {
    (void)access; (void)user;
    uint32_t ss=0,cs=0,ip=0; read_reg(uc,registers[10],&ss);
    if (address<ss*16 || address>=ss*16+65536) return;
    read_reg(uc,registers[13],&cs); read_reg(uc,registers[14],&ip);
    pc_lockstep_cpu_stack_write((uint16_t)ss,(uint16_t)(address-ss*16),(unsigned)size,(uint64_t)value,cs*16+ip);
}
typedef struct { uint64_t address; char name[128]; int notify; } routine;
static routine routines[2048];
static size_t routine_count, recent_count;
static const char *recent[32];
void pc_lockstep_cpu_setup(uc_stop_fn fn) {
    stop_cpu = fn; instructions = 0; routine_count = recent_count = 0;
    active_cpu=NULL;
    reason = requested = 0; wait_count=0; skip_wait=delay_entry=UINT64_MAX;
    memset(stack_writes,0,sizeof stack_writes);
}
void pc_lockstep_cpu_routine(uint64_t address, const char *name, int notify) {
    if (routine_count == 2048) abort();
    size_t i = routine_count++;
    while (i && routines[i-1].address > address) { routines[i] = routines[i-1]; --i; }
    routines[i].address = address;
    snprintf(routines[i].name, sizeof routines[i].name, "%s", name);
    routines[i].notify = notify;
}
void pc_lockstep_cpu_prepare(uint64_t target) {
    reason = 0; stop_address = target;
}
void pc_lockstep_cpu_break(int kind, uint64_t value) { requested = kind; reason_value = value; }
uint64_t pc_lockstep_cpu_count(void) { return instructions; }
void pc_lockstep_cpu_iret(void) { ++instructions; }
int pc_lockstep_cpu_reason(void) { return reason; }
uint64_t pc_lockstep_cpu_value(void) { return reason_value; }
const char *pc_lockstep_cpu_recent(unsigned i) {
    return i < recent_count ? recent[i] : NULL;
}
void pc_lockstep_cpu_interrupt(void *uc, uint32_t vector, void *user) {
    (void)user;
    uint32_t ax=0, flags=0, cs=0, ip=0, ss=0, sp=0;
    read_reg(uc,registers[0],&ax);
    if (!vector || (vector == 0x21 && (ax >> 8) == 0x4c)) {
        reason = vector ? 6 : 5; reason_value = ax & 255; stop_cpu(uc); return;
    }
    read_reg(uc,registers[12],&flags); read_reg(uc,registers[13],&cs);
    read_reg(uc,registers[14],&ip); read_reg(uc,registers[10],&ss);
    read_reg(uc,registers[11],&sp);
    sp = (sp-2)&65535; pc_wr16((uint16_t)ss,(uint16_t)sp,(uint16_t)flags);
    sp = (sp-2)&65535; pc_wr16((uint16_t)ss,(uint16_t)sp,(uint16_t)cs);
    sp = (sp-2)&65535; pc_wr16((uint16_t)ss,(uint16_t)sp,(uint16_t)ip);
    pc_lockstep_cpu_stack_write((uint16_t)ss,(uint16_t)(sp+4),2,flags,cs*16+ip);
    pc_lockstep_cpu_stack_write((uint16_t)ss,(uint16_t)(sp+2),2,cs,cs*16+ip);
    pc_lockstep_cpu_stack_write((uint16_t)ss,(uint16_t)sp,2,ip,cs*16+ip);
    flags &= ~0x300u;
    cs = pc_rd16(0,(uint16_t)(vector*4+2)); ip = pc_rd16(0,(uint16_t)(vector*4));
    write_reg(uc,registers[11],&sp); write_reg(uc,registers[12],&flags);
    write_reg(uc,registers[13],&cs); write_reg(uc,registers[14],&ip);
    pc_cli();
}
void pc_lockstep_cpu_hook(void *uc, uint64_t address, uint32_t size, void *user) {
    (void)size; (void)user;
    active_cpu=uc;
    if (requested) { reason = requested; requested = 0; stop_cpu(uc); return; }
    if (address == stop_address) { reason = 2; stop_cpu(uc); return; }
    if (address >= 0xf6000 && address < 0xf8000 && !(address & 3)) {
        reason = 1; reason_value = address; stop_cpu(uc); return;
    }
    if (wait_enabled) {
        if (skip_wait==address) skip_wait=UINT64_MAX;
        else {
            if (address==delay_entry) { reason=8; stop_cpu(uc); return; }
            unsigned kind=0;
            uint8_t op=pc_mem[address];
            if (op==0xec || op==0xed || op==0xe4 || op==0xe5) {
                uint32_t dx=0; read_reg(uc,registers[3],&dx);
                unsigned port=(op==0xe4 || op==0xe5) ? pc_mem[address+1] : (dx&65535);
                if (port==0x3da || port==0x3ba || port==0x60 || port==0x201) kind=port;
            }
            unsigned lo=0,hi=wait_count;
            while (lo<hi) { unsigned mid=lo+(hi-lo)/2; if (wait_points[mid].address<address) lo=mid+1; else hi=mid; }
            if (!kind && lo<wait_count && wait_points[lo].address==address) {
                uint32_t seg=0; read_reg(uc,registers[wait_points[lo].es_di ? 8 : 7],&seg);
                if ((!wait_points[lo].es_di && seg==watch_ds) || (wait_points[lo].es_di && seg==0x40)) kind=wait_points[lo].kind;
            }
            if (kind) { reason=7; reason_value=kind; stop_cpu(uc); return; }
        }
    }
    size_t lo = 0, hi = routine_count;
    while (lo < hi) {
        size_t mid = lo + (hi-lo)/2;
        if (routines[mid].address < address) lo = mid+1; else hi = mid;
    }
    if (lo<routine_count && routines[lo].address==address) executing_routine=routines[lo].name;
    else if (lo) executing_routine=routines[lo-1].name;
    if (lo < routine_count && routines[lo].address == address) {
        if (recent_count == 32) { memmove(recent,recent+1,31*sizeof *recent); --recent_count; }
        recent[recent_count++] = routines[lo].name;
        if (routines[lo].notify) pc_lockstep_trace(routines[lo].name);
    }
    ++instructions;
}
