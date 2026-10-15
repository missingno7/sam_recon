#ifndef SAM_LOCKSTEP_H
#define SAM_LOCKSTEP_H
/* Optional differential instrumentation, deliberately outside the binding pc.h ABI. */
#include "pc.h"
#include <stdio.h>
typedef void (*pc_external_fn)(farptr);
typedef void (*pc_external_irq_fn)(uint8_t);
typedef int (*pc_observer_fn)(int kind, const char *name);
void pc_lockstep_external(pc_external_fn fn);
void pc_lockstep_cpu_host_write(uint16_t seg,uint16_t off,const uint8_t *data,unsigned count,const char *name);
void pc_lockstep_external_irq(pc_external_irq_fn fn);
void pc_lockstep_observer(pc_observer_fn fn);
void pc_lockstep_trace(const char *name);
void pc_lockstep_store(const char *name);
void pc_lockstep_before_store(void);
void pc_lockstep_cpu_poll(void);
void pc_lockstep_keypoll(void);
void pc_lockstep_keyboard_observe(int enabled);
int pc_lockstep_aborted(void);
int pc_lockstep_registered(farptr target);
void pc_lockstep_call(farptr target, pc_regs *r);
uint64_t pc_lockstep_deadline(void);
size_t pc_lockstep_vga(uint8_t *out);
size_t pc_lockstep_devices(uint8_t *out);
size_t pc_lockstep_speaker(uint8_t *out);
int pc_lockstep_original(void);
int pc_lockstep_enabled(void);
uint8_t pc_lockstep_status8(const uint8_t *p);
uint16_t pc_lockstep_key16(const uint16_t *p);
void pc_lockstep_mode(int enabled);
void pc_lockstep_wait(unsigned kind);
void pc_lockstep_flush(void);
uint16_t pc_lockstep_read16(const uint16_t *p);
const char *pc_lockstep_code_name(farptr target);
#endif
