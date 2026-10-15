/* Real-mode memory, interrupt vectors, BIOS timer services, and safe-point scheduling. */
#include "pc_internal.h"
#include "host_metrics.h"
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <stdatomic.h>
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
static HANDLE host_timer;
#endif
static int video_wait;
static uint8_t video_mask,video_wanted;


uint8_t pc_mem[PC_MEM_SIZE];
#ifdef SAM_LOCKSTEP
static pc_external_fn external_code;
static pc_external_irq_fn external_irq;
static pc_observer_fn observer;
static int observe_keyboard;
static int cpu_aborted;
int pc_lockstep_aborted(void) { return cpu_aborted; }
void pc_lockstep_keyboard_observe(int enabled) { observe_keyboard = enabled; }
void pc_lockstep_external(pc_external_fn fn) { external_code = fn; }
void pc_lockstep_external_irq(pc_external_irq_fn fn) { external_irq = fn; }
void pc_lockstep_observer(pc_observer_fn fn) { observer = fn; }
void pc_lockstep_trace(const char *name) {
    if (observer && observer(1, name)) pc_terminate(0);
}
void pc_lockstep_store(const char *name) {
    if (observer && observer(2, name)) pc_terminate(0);
}
void pc_lockstep_before_store(void) {
    if (observer && observer(3, NULL)) pc_terminate(0);
}
void pc_lockstep_keypoll(void) {
    if (observe_keyboard && observer && observer(4, NULL)) pc_terminate(0);
}
#endif
static pc_program program;
static struct {
    pc_code_fn fn;
    const char *name;
} code[2048];
static unsigned code_count;
#ifdef SAM_LOCKSTEP
int pc_lockstep_registered(farptr target) {
    uint32_t a = PC_LINEAR(FP_SEG(target), FP_OFF(target));
    return a >= PC_CODE_REGISTRY_LINEAR &&
           a < PC_CODE_REGISTRY_LINEAR + code_count * PC_CODE_REGISTRY_SLOT_SIZE &&
           !(a & PC_CODE_REGISTRY_SLOT_ALIGNMENT_MASK);
}
#endif
static int interrupt_flag = 1, polling;
static uint64_t counts[256], eois;
static pc_regs *call_regs;
typedef struct irq_frame {
    jmp_buf jump;
    struct irq_frame *previous;
} irq_frame;
static irq_frame *frame;
static jmp_buf exit_jump;
static int exit_ready, exit_status;
#ifdef SAM_LOCKSTEP
static int wait_clock, wait_active;
static unsigned wait_previous, wait_streak;
int pc_lockstep_enabled(void) { return wait_clock; }
int pc_lockstep_original(void) { return external_code!=NULL; }
void pc_lockstep_mode(int enabled) { wait_clock=enabled; wait_previous=wait_streak=0; }
const char *pc_lockstep_code_name(farptr target) {
    if (!pc_lockstep_registered(target)) return NULL;
    return code[(PC_LINEAR(FP_SEG(target),FP_OFF(target))-PC_CODE_REGISTRY_LINEAR)/PC_CODE_REGISTRY_SLOT_SIZE].name;
}
#endif
static int manual_clock;
int pc_wall_clock(void) {
    return !manual_clock
#ifdef SAM_LOCKSTEP
        && !wait_clock
#endif
        ;
}
static uint64_t manual_us, wall_origin, event_us;
/* Wall time paces the PC; it is not itself the PC clock. A safe-point sample
   latches time, so the caller can observe a reached edge before the next sample.
   Dropped oversleep becomes lag; later waits catch up against wall_origin. */
static uint64_t real_us,real_sample;
static _Atomic uint64_t playback_us;
uint64_t pc_playback_time_us(void) {return atomic_load_explicit(&playback_us,memory_order_relaxed);}
static int event_clock;
static uint64_t pit_origin, pit_number = 1, pit_next;
static uint32_t pit_divisor = 65536;
static uint64_t frame_number = 1, frame_next;
static unsigned spins;
static uint64_t last_poll;
typedef struct {
    uint64_t time;
    uint8_t scan;
} key_event;
static key_event keys[8192];
static size_t key_count;

/* PSP field offsets used when constructing DOS's process block for the episode. */
enum {
    PSP_TERMINATE_VECTOR = 0x00,
    PSP_TOP_OF_MEMORY = 0x02,
    PSP_PARENT_SEGMENT = 0x16,
    PSP_FIRST_FCB = 0x18,
    PSP_ENVIRONMENT_SEGMENT = 0x2c,
    PSP_HANDLE_COUNT = 0x32,
    PSP_HANDLE_TABLE_OFFSET = 0x34,
    PSP_PARENT_PSP = 0x36,
    PSP_COMMAND_TAIL = 0x80
};

/* Route host access away from A000 planar memory, which has its own VGA latches/registers. */
static void fatal(const char *message) {
    fprintf(stderr, "PC: %s\n", message);
    abort();
}
/* Translate seg:off into the 20-bit host-backed address space. */
uint8_t *pc_host(uint16_t seg, uint16_t off) {
    uint32_t addr = PC_LINEAR(seg, off);
    if (seg == PC_VIDEO_PLANAR_SEGMENT ||
        (addr >= PC_VIDEO_PLANAR_ADDRESS && addr < PC_VIDEO_PLANAR_END))
        fatal("A000 planar memory requires vga_* access");
    return pc_mem + addr;
}
uint8_t pc_rd8(uint16_t s, uint16_t o) {
    return *pc_host(s, o);
}
/* Keep the 8086 word access's 16-bit offset wrap within its original segment. */
uint16_t pc_rd16(uint16_t s, uint16_t o) {
    return (uint16_t)(pc_rd8(s, o) | (pc_rd8(s, (uint16_t)(o + 1)) << 8));
}
void pc_wr8(uint16_t s, uint16_t o, uint8_t v) {
    uint32_t a = PC_LINEAR(s, o);
    *pc_host(s, o) = v;
#ifdef SAM_LOCKSTEP
    if (external_code) pc_lockstep_cpu_host_write(s,o,&v,1,"platform pc_wr8");
#endif
    /* Mirror writes to the first 64 KiB above 1 MiB for 20-bit wrapping. */
    if (a < PC_REAL_MODE_LOW_ALIAS_END)
        pc_mem[PC_REAL_MODE_WRAP_START + a] = v;
}
void pc_wr16(uint16_t s, uint16_t o, uint16_t v) {
    pc_wr8(s, o, (uint8_t)v);
    pc_wr8(s, (uint16_t)(o + 1), (uint8_t)(v >> 8));
}
const pc_program *pc_current_program(void) {
    return &program;
}
/* Give C interrupt handlers stable real-mode addresses in the reserved BIOS segment. */
farptr pc_register_code(pc_code_fn fn, const char *name) {
    if (!fn)
        return 0;
    for (unsigned i = 0; i < code_count; ++i)
        if (code[i].fn == fn)
            return FP(PC_BIOS_ROM_SEGMENT, PC_CODE_REGISTRY_BASE + i * PC_CODE_REGISTRY_SLOT_SIZE);
    if (code_count == 2048)
        fatal("code registry full");
    code[code_count].fn = fn;
    code[code_count].name = name;
#ifdef SAM_LOCKSTEP
    /* Original CPU clients call the C handler at this slot, then execute this
       synthetic BIOS IRET. No original BIOS or program bytes are embedded. */
    pc_mem[PC_CODE_REGISTRY_LINEAR + code_count * PC_CODE_REGISTRY_SLOT_SIZE] = 0xcf;
#endif
    return FP(PC_BIOS_ROM_SEGMENT,
              PC_CODE_REGISTRY_BASE + code_count++ * PC_CODE_REGISTRY_SLOT_SIZE);
}
/* Resolve the reserved ROM-segment slot assigned to a registered C interrupt/handler. */
void pc_call_far(farptr target) {
    if (!target)
        return;
    /* Accept alias segment:offset spellings of a registered address. */
    uint32_t a = PC_LINEAR(FP_SEG(target), FP_OFF(target));
    if (a < PC_CODE_REGISTRY_LINEAR ||
        a >= PC_CODE_REGISTRY_LINEAR + code_count * PC_CODE_REGISTRY_SLOT_SIZE ||
        ((a - PC_CODE_REGISTRY_LINEAR) & PC_CODE_REGISTRY_SLOT_ALIGNMENT_MASK)) {
#ifdef SAM_LOCKSTEP
        if (external_code) { external_code(target); return; }
#endif
        fprintf(stderr, "PC: unregistered far call %04x:%04x\n", FP_SEG(target), FP_OFF(target));
        abort();
    }
    code[(a - PC_CODE_REGISTRY_LINEAR) / PC_CODE_REGISTRY_SLOT_SIZE].fn();
}
void pc_cli(void) {
    interrupt_flag = 0;
}
void pc_sti(void) {
    interrupt_flag = 1;
}
int pc_interrupts_enabled(void) {
    return interrupt_flag;
}
/* Deliver an interrupt through the IVT with IF clear, restoring the caller's flags on IRET. */
void pc_int(uint8_t n) {
    int saved = interrupt_flag;
#ifdef SAM_LOCKSTEP
    if (external_irq && polling && !frame && (n == 8 || n == 9)) {
        interrupt_flag = 0;
        ++counts[n];
        external_irq(n);
        interrupt_flag = saved;
        return;
    }
#endif
    irq_frame local;
    local.previous = frame;
    frame = &local;
    interrupt_flag = 0;
    ++counts[n];
    if (!setjmp(local.jump))
        pc_call_far(FP(pc_rd16(PC_IVT_SEGMENT, (uint16_t)(PC_IVT_ENTRY_SIZE * n + 2)),
                       pc_rd16(PC_IVT_SEGMENT, (uint16_t)(PC_IVT_ENTRY_SIZE * n))));
    frame = local.previous;
    interrupt_flag = saved;
}
/* A chained INT handler transfers control to the old vector and does not resume its caller. */
void pc_chain_interrupt(farptr old) {
    irq_frame *return_frame = frame;
    if (!return_frame)
        fatal("interrupt chain outside interrupt");
    pc_call_far(old);
    longjmp(return_frame->jump, 1);
}
uint64_t pc_irq_count(unsigned n) {
    return n < 256 ? counts[n] : 0;
}
uint64_t pc_eoi_count(void) {
    return eois;
}
void pc_pic_eoi(void) {
    ++eois;
}

uint64_t pc_time_us(void) {
    if (event_clock)
        return event_us;
    return manual_clock ? manual_us : real_us;
}
void pc_clock_manual(int on) {
    uint64_t now = pc_time_us();
    manual_clock = on != 0;
    manual_us = now;
    atomic_store_explicit(&playback_us,now,memory_order_relaxed);
    if (!on) {
        real_us=now;real_sample=SDL_GetTicksNS()/1000u;
        wall_origin=real_sample-now;
    }
}
void pc_clock_advance(uint64_t t) {
    if (!manual_clock || t < manual_us)
        fatal("invalid manual clock advance");
    manual_us = t;
    atomic_store_explicit(&playback_us,t,memory_order_relaxed);
}
static uint64_t pit_deadline(void) {
    return pit_origin + (pit_number * pit_divisor * 1000000u + PC_PIT_HZ - 1) / PC_PIT_HZ;
}
/* Next edge of the devices whose changes must be observable at safe points. */
static uint64_t device_deadline(void) {
    uint64_t next=frame_next,script=pc_script_next();
    if(script<next)next=script;
    if(interrupt_flag && pit_next<next)next=pit_next;
    if(interrupt_flag && key_count && keys[0].time<next)next=keys[0].time;
    return next;
}
static uint64_t status_deadline(uint64_t now,int retrace) {
    if(!retrace && !video_wait)return UINT64_MAX;
    uint64_t tick=pc_video_line(now);
    if(video_wait && video_mask==8) {
        unsigned row=(unsigned)(tick%PC_VIDEO_LINES);
        unsigned value=row>=412 && row<414 ? 8 : 0;
        if(value==video_wanted)return now;
        uint64_t edge=tick/PC_VIDEO_LINES*PC_VIDEO_LINES+(video_wanted ? 412 : 414);
        if(edge<=tick)edge+=PC_VIDEO_LINES;
        return pc_video_line_time(edge);
    }
    /* A raw status reader can depend on either bit, so preserve horizontal
       display-disable transitions as well as every scanline/retrace boundary. */
    uint64_t line_start=tick*PC_VIDEO_LINE_NUM;
    uint64_t blank=(line_start+PC_VIDEO_LINE_NUM*4/5+PC_VIDEO_LINE_DEN-1)/PC_VIDEO_LINE_DEN;
    return blank>now ? blank : pc_video_line_time(tick+1);
}
static void real_clock_at(uint64_t value,uint64_t wall) {
    real_us=value;real_sample=wall;
    atomic_store_explicit(&playback_us,value,memory_order_relaxed);
    /* A debugger, suspended window or OS stall must not create unbounded
       catch-up. Rebase wall pacing after 100 ms; never jump over PC edges. */
    if(wall-wall_origin>value+100000u)wall_origin=wall-value;
}
static int real_clock_sample(uint64_t edge) {
    uint64_t wall=SDL_GetTicksNS()/1000u;
    uint64_t value=real_us+(wall-real_sample);
    if(edge<real_us)edge=real_us; /* an event queued at the current safe point */
    int reached=value>=edge && edge>real_us;
    if(value>edge)value=edge;
    real_clock_at(value,wall);
    return reached;
}
/* Start a fresh IRQ0 schedule from the selected PIT divisor. */
void pc_pit_schedule(uint32_t divisor) {
    pit_divisor = divisor;
    pit_origin = pc_time_us();
    pit_number = 1;
    pit_next = pit_deadline();
}
/* Keep queued scan bytes ordered so equal-time inputs preserve their insertion order. */
void pc_queue_scan(uint64_t t, uint8_t scan) {
    if (key_count == sizeof keys / sizeof keys[0])
        fatal("keyboard event queue full");
    size_t i = key_count++;
    while (i && keys[i - 1].time > t) {
        keys[i] = keys[i - 1];
        --i;
    }
    keys[i].time = t;
    keys[i].scan = scan;
}
/* Expand a logical make/break event into the set-1 byte sequence delivered to INT 9. */
void pc_queue_key(uint64_t t, uint16_t scan, int down) {
    if (scan & 0xff00)
        pc_queue_scan(t, (uint8_t)(scan >> 8));
    pc_queue_scan(t, (uint8_t)(scan | (down ? 0 : PC_SCAN_BREAK_BIT)));
}
/* Reach an exact PC timestamp, pacing against wall time without adopting an
   overslept timestamp. No busy spin is needed even for a 64-us retrace pulse. */
void pc_wait_until(uint64_t when) {
    uint64_t now = pc_time_us();
    if (when <= now)
        return;
    HOST_COUNT(HM_WAIT,1);
    HOST_COUNT(HM_WAIT_REQUEST_NS,(when-now)*1000u);
    HOST_COUNT(HM_SHORT_WAIT,when-now<100);
    uint64_t before=pc_metrics_enabled ? SDL_GetTicksNS() : 0;
    if (manual_clock) {
        manual_us = when;
        atomic_store_explicit(&playback_us,when,memory_order_relaxed);
    } else {
        pc_host_pump_force();
        uint64_t edge=device_deadline();if(edge<when)when=edge;
        if(pc_host_has_controller() && real_us+1000<when)when=real_us+1000;
        uint64_t wall=SDL_GetTicksNS()/1000u;
        if(when>real_us && wall<wall_origin+when) {
            uint64_t duration=(wall_origin+when-wall)*1000u;
            int interrupted=0;
#ifdef _WIN32
            if(!host_timer)host_timer=CreateWaitableTimerExW(NULL,NULL,0x2,TIMER_ALL_ACCESS);
            if(host_timer) {
                LARGE_INTEGER due;due.QuadPart=-(LONGLONG)((duration+99)/100);
                if(SetWaitableTimer(host_timer,&due,0,NULL,NULL,FALSE)) {
                    DWORD result=pc_host_window_messages() ?
                        MsgWaitForMultipleObjectsEx(1,&host_timer,INFINITE,QS_ALLINPUT,MWMO_INPUTAVAILABLE) :
                        WaitForSingleObject(host_timer,INFINITE);
                    if(result==WAIT_OBJECT_0+1)interrupted=1;
                } else SDL_DelayNS(duration);
            } else SDL_DelayNS(duration);
#else
            if(duration>1000000u) {duration=1000000u;interrupted=1;}
            SDL_DelayNS(duration);
#endif
            if(interrupted) {
                real_clock_sample(when);pc_host_pump_force();
            } else real_clock_at(when,SDL_GetTicksNS()/1000u);
        } else if(when>real_us) {
            real_clock_at(when,wall); /* lag catch-up: reach the edge without sleeping */
        }
    }
    if (pc_metrics_enabled) pc_metrics_add(HM_WAIT_NS,SDL_GetTicksNS()-before);
}
void pc_host_wait_shutdown(void) {
#ifdef _WIN32
    if(host_timer)CloseHandle(host_timer);
    host_timer=NULL;
#endif
}
void pc_wait_video_status(uint8_t mask,uint8_t wanted) {
    if(!pc_wall_clock()) {pc_poll();return;}
    video_wait=1;video_mask=mask;video_wanted=wanted;
    pc_poll();video_wait=0;
}
/* Deliver scheduled DOS interrupts and host events at deterministic safe points. */
void pc_poll(void) {
    HOST_COUNT(HM_POLL,1);
    if (polling)
        return; /* generated handler entry/back-edge safe points */
    polling = 1;
#ifdef SAM_LOCKSTEP
    if (observer && observer(0, NULL)) {
        if (external_code) {
            /* Cancel a CPU test without longjmp across its Python callbacks.
               A blocking BIOS key read checks this after polling and unwinds. */
            cpu_aborted = 1;
            polling = 0;
            return;
        }
        pc_terminate(0);
    }
#endif
#ifdef SAM_LOCKSTEP
    if (wait_clock && !wait_active) { polling=0; return; }
#endif
    int retrace=0,clock_reached=0;
    if(pc_wall_clock()) {
        retrace=pc_retrace_polling();
        uint64_t next=device_deadline(),status=status_deadline(real_us,retrace);
        if(status<next)next=status;
        clock_reached=real_clock_sample(next);
    }
    pc_host_pump();
    uint64_t target = pc_time_us();
    int work = 0;
    for (;;) {
        uint64_t script = pc_script_next(), due = script;
        int kind = 0;
        /* Equal timestamps: IRQ0, IRQ1, script commands, display. */
        if (interrupt_flag && pit_next <= due) {
            due = pit_next;
            kind = 1;
        }
        if (interrupt_flag && key_count && keys[0].time < due) {
            due = keys[0].time;
            kind = 2;
        }
        if (frame_next < due) {
            due = frame_next;
            kind = 3;
        }
        if (due > target || due == UINT64_MAX)
            break;
        event_clock = 1;
        event_us = due;
        work = 1;
        if (kind == 1) {
            ++pit_number;
            pit_next = pit_deadline();
            pc_int(PC_INT_TIMER);
        } else if (kind == 2) {
            uint8_t scan = keys[0].scan;
            --key_count;
            memmove(keys, keys + 1, key_count * sizeof keys[0]);
            pc_keyboard_latch(scan);
            pc_int(9);
        } else if (kind == 3) {
            platform_present();
            ++frame_number;
            frame_next = pc_video_frame_time(frame_number);
        } else
            pc_script_dispatch(due);
        event_clock = 0;
    }
    if (work || target > last_poll + 1000)
        spins = 0;
    else
        ++spins;
    last_poll = target;
    if (!clock_reached && (spins >= 32 || video_wait || (pc_wall_clock() && retrace))
#ifdef SAM_LOCKSTEP
        && !wait_clock
#endif
    ) {
        uint64_t next = frame_next, script = pc_script_next();
        if (script < next)
            next = script;
        if (interrupt_flag && pit_next < next)
            next = pit_next;
        if (interrupt_flag && key_count && keys[0].time < next)
            next = keys[0].time;
        /* Unhinted reads keep the conservative scanline deadline. A masked
           vertical-retrace reader may sleep to its actual requested edge. */
        if(pc_wall_clock()) {
            uint64_t status=status_deadline(target,retrace);
            if(status<next)next=status;
        } else {
            uint64_t line=pc_video_line_time(pc_video_line(target)+1);
            if(pc_retrace_polling() && line<next)next=line;
        }
        if(pc_wall_clock() && pc_host_has_controller() && target+1000<next)next=target+1000;
        pc_wait_until(next);
        spins = 0;
    }
    polling = 0;
    if (exit_ready && platform_quit_requested())
        pc_terminate(0);
}
/* Implement the Pascal delay while polling interrupts and host events at safe points. */
void pc_delay_ms(uint16_t ms) {
    HOST_COUNT(HM_DELAY,1);
    uint64_t end = pc_time_us() + (uint64_t)ms * 1000u;
#ifdef SAM_LOCKSTEP
    unsigned watchdog=0;
#endif
    while (pc_time_us() < end && !platform_quit_requested()) {
#ifdef SAM_LOCKSTEP
        if (++watchdog==1000000) {
            fprintf(stderr,"Delay stalled now=%llu end=%llu polling=%d event=%d active=%d IF=%d pit=%llu frame=%llu\n",(unsigned long long)pc_time_us(),(unsigned long long)end,polling,event_clock,wait_active,interrupt_flag,(unsigned long long)pit_next,(unsigned long long)frame_next);
            abort();
        }
#endif
#ifdef SAM_LOCKSTEP
        if (wait_clock) { pc_lockstep_wait(0x10001); continue; }
#endif
        pc_poll();
        uint64_t now = pc_time_us(), next = now + 1000;
        if (pit_next > now && pit_next < next)
            next = pit_next;
        if (key_count && keys[0].time > now && keys[0].time < next)
            next = keys[0].time;
        if (pc_script_next() > now && pc_script_next() < next)
            next = pc_script_next();
        pc_wait_until(next < end ? next : end);
    }
    pc_poll();
}

static void bios_noop(void) {
}
/* Maintain the BIOS midnight counter, invoke INT 1Ch, and acknowledge PIC IRQ0. */
static void bios_timer(void) {
    uint32_t tick = pc_rd16(PC_BDA_SEGMENT, PC_BDA_TIMER_TICKS_LOW) |
                    ((uint32_t)pc_rd16(PC_BDA_SEGMENT, PC_BDA_TIMER_TICKS_HIGH) << 16);
    if (++tick >= PC_BIOS_TICKS_PER_DAY) {
        tick = 0;
        pc_wr8(PC_BDA_SEGMENT, PC_BDA_MIDNIGHT_FLAG,
               (uint8_t)(pc_rd8(PC_BDA_SEGMENT, PC_BDA_MIDNIGHT_FLAG) + 1));
    }
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_TIMER_TICKS_LOW, (uint16_t)tick);
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_TIMER_TICKS_HIGH, (uint16_t)(tick >> 16));
    pc_int(PC_INT_TIMER_CALLBACK);
    pc_outb(PC_PORT_PIC_COMMAND, PC_PIC_NON_SPECIFIC_EOI);
}
static void bios_equipment(void) {
    call_regs->ax = pc_rd16(PC_BDA_SEGMENT, PC_BDA_EQUIPMENT);
}
static void bios_video_wrapper(void) {
    bios_video(call_regs);
}
static void bios_key_wrapper(void) {
    bios_keyboard(call_regs);
}
static void bios_dos_wrapper(void) {
    bios_dos(call_regs);
}
static void bios_clock(void) {
#ifdef SAM_LOCKSTEP
    pc_lockstep_wait(0x1a);
#endif
    if (!(call_regs->ax >> 8)) {
        call_regs->cx = pc_rd16(PC_BDA_SEGMENT, PC_BDA_TIMER_TICKS_HIGH);
        call_regs->dx = pc_rd16(PC_BDA_SEGMENT, PC_BDA_TIMER_TICKS_LOW);
        call_regs->ax = pc_rd8(PC_BDA_SEGMENT, PC_BDA_MIDNIGHT_FLAG);
        pc_wr8(PC_BDA_SEGMENT, PC_BDA_MIDNIGHT_FLAG, 0);
    }
}
/* Invoke the selected BIOS/DOS vector with the caller's register block. */
void pc_bios_int(uint8_t vector, pc_regs *r) {
    if (getenv("SAM_TRACE"))
        fprintf(stderr, "INT%02x ax=%04x bx=%04x cx=%04x ds=%04x dx=%04x time=%llu\n", vector,
                r->ax, r->bx, r->cx, r->ds, r->dx, (unsigned long long)pc_time_us());
    pc_regs *previous = call_regs;
    call_regs = r;
    pc_int(vector);
    call_regs = previous;
#ifdef SAM_LOCKSTEP
    if (vector==0x16 || vector==0x1a) pc_lockstep_flush();
#endif
}
#ifdef SAM_LOCKSTEP
void pc_lockstep_call(farptr target, pc_regs *r) {
    pc_regs *previous = call_regs;
    call_regs = r;
    pc_call_far(target);
    call_regs = previous;
}
uint64_t pc_lockstep_deadline(void) {
    uint64_t due = frame_next;
    if (interrupt_flag && pit_next < due) due = pit_next;
    if (interrupt_flag && key_count && keys[0].time < due) due = keys[0].time;
    return due;
}
void pc_lockstep_flush(void) {
    ++wait_active; pc_poll(); --wait_active;
}
void pc_lockstep_wait(unsigned kind) {
    if (!wait_clock || polling) return;
    char name[16]; snprintf(name,sizeof name,"%x",kind);
    if (observer && observer(5,name)) {
        if (external_code) { cpu_aborted=1; return; }
        pc_terminate(0);
    }
    wait_previous=kind; ++wait_streak;
    if (wait_streak>=2) {
        uint64_t next=pc_lockstep_deadline(), now=pc_time_us();
        if (kind==0x201 && now+8<next) next=now+8;
        if (kind==0x3da || kind==0x3ba) {
            uint64_t line=pc_video_line_time(pc_video_line(now)+1);
            if (line<next) next=line;
        }
        pc_clock_advance(next); wait_streak=0;
    }
    pc_lockstep_flush();
}
uint8_t pc_lockstep_status8(const uint8_t *p) { pc_lockstep_wait(0x10003); return *p; }
uint16_t pc_lockstep_key16(const uint16_t *p) { pc_lockstep_wait(0x60); return *p; }
uint16_t pc_lockstep_read16(const uint16_t *p) {
    pc_lockstep_wait(0x10000); return *p;
}
void pc_lockstep_cpu_poll(void) {
    /* The diagnostic instruction-clock mode charges instructions separately;
       wait-clock mode charges only its explicit wait events. Neither uses the
       native spin-sleep heuristic as another source of elapsed CPU time. */
    spins = 0;
    pc_poll();
}
#endif
/* Set up the PSP, IVT, BIOS Data Area, and DOS load image for one episode. */
void pc_load_program(const pc_program *layout, const uint8_t *image, size_t size) {
    if (!layout || layout->psp_seg < 0x100 || layout->mem_top_seg > PC_VIDEO_PLANAR_SEGMENT ||
        layout->heap_org_seg > layout->mem_top_seg || layout->ds_seg >= layout->mem_top_seg ||
        layout->ss_seg >= layout->mem_top_seg || size > 65536 ||
        ((uint32_t)layout->ds_seg << 4) + size > ((uint32_t)layout->mem_top_seg << 4))
        fatal("invalid program placement");
    pc_host_program_reset();
    program = *layout;
    video_wait=0;
#ifdef SAM_LOCKSTEP
    cpu_aborted = 0;
#endif
    memset(pc_mem, 0, sizeof pc_mem);
    memset(counts, 0, sizeof counts);
    code_count = 0;
    interrupt_flag = 1;
    polling = event_clock = 0;
    call_regs = NULL;
    frame = NULL;
    key_count = 0;
    eois = 0;
    wall_origin = SDL_GetTicksNS() / 1000u;
    real_us=0;real_sample=wall_origin;
    atomic_store_explicit(&playback_us,0,memory_order_relaxed);
    manual_us = 0;
    pit_origin = 0;
    pit_number = 1;
    pit_divisor = 65536;
    pit_next = pit_deadline();
    frame_number = 1;
    frame_next = pc_video_frame_time(1);
    spins = 0;
    last_poll = 0;
    pc_devices_reset();
    pc_dos_reset();
    speaker_reset();
    farptr empty = pc_register_code(bios_noop, "BIOS IRET");
    for (unsigned n = 0; n < 256; ++n) {
        pc_wr16(PC_IVT_SEGMENT, (uint16_t)(PC_IVT_ENTRY_SIZE * n), FP_OFF(empty));
        pc_wr16(PC_IVT_SEGMENT, (uint16_t)(PC_IVT_ENTRY_SIZE * n + 2), FP_SEG(empty));
    }
    const struct {
        unsigned n;
        pc_code_fn fn;
        const char *name;
    } services[] = {{PC_INT_TIMER, bios_timer, "BIOS IRQ0"},
                    {PC_INT_KEYBOARD, bios_keyboard_irq, "BIOS IRQ1"},
                    {PC_INT_VIDEO, bios_video_wrapper, "BIOS video"},
                    {PC_INT_EQUIPMENT, bios_equipment, "BIOS equipment"},
                    {PC_INT_KEYBOARD_BIOS, bios_key_wrapper, "BIOS keyboard"},
                    {PC_INT_CLOCK, bios_clock, "BIOS clock"},
                    {PC_INT_DOS, bios_dos_wrapper, "DOS"}};
    for (size_t i = 0; i < sizeof services / sizeof services[0]; ++i) {
        farptr f = pc_register_code(services[i].fn, services[i].name);
        pc_wr16(PC_IVT_SEGMENT, (uint16_t)(services[i].n * PC_IVT_ENTRY_SIZE), FP_OFF(f));
        pc_wr16(PC_IVT_SEGMENT, (uint16_t)(services[i].n * PC_IVT_ENTRY_SIZE + 2), FP_SEG(f));
    }
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_EQUIPMENT,
            0x0021); /* disk present, colour display, no joystick initially */
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_MEMORY_KB, 640);
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_BUFFER_HEAD, 0x1e);
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_BUFFER_TAIL, 0x1e);
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_BUFFER_START, 0x1e);
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_BUFFER_END, 0x3e);
    pc_wr8(PC_BDA_SEGMENT, PC_BDA_VIDEO_MODE_OPTIONS, 0x60);
    pc_wr8(PC_BDA_SEGMENT, PC_BDA_VIDEO_OPTIONS_88, 9);
    pc_wr8(PC_BDA_SEGMENT, PC_BDA_VIDEO_VGA_INFO, 0x51);
    pc_wr8(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_STATUS, 0x10);
    pc_fonts_init();
    bios_set_mode(PC_VIDEO_MODE_TEXT_80X25);
    uint16_t p = layout->psp_seg, env = (uint16_t)(p - 0x10);
    pc_wr16(p, PSP_TERMINATE_VECTOR, 0x20cd);
    pc_wr16(p, PSP_TOP_OF_MEMORY, layout->mem_top_seg);
    pc_wr16(p, PSP_PARENT_SEGMENT, p);
    pc_wr16(p, PSP_ENVIRONMENT_SEGMENT, env);
    pc_wr16(p, PSP_COMMAND_TAIL, 0x0d00);
    for (unsigned i = 0; i < 20; ++i)
        pc_wr8(p, (uint16_t)(PSP_FIRST_FCB + i), (uint8_t)(i < 5 ? i : 255));
    pc_wr16(p, PSP_HANDLE_COUNT, 20);
    pc_wr16(p, PSP_HANDLE_TABLE_OFFSET, PSP_FIRST_FCB);
    pc_wr16(p, PSP_PARENT_PSP, p);
    const char environment[] = "PATH=.\0COMSPEC=COMMAND.COM\0\0\1\0SAM.EXE\0";
    memcpy(pc_host(env, 0), environment, sizeof environment);
    if (size) {
        if (!image)
            fatal("missing DS image");
        memcpy(pc_host(layout->ds_seg, 0), image, size);
    }
}
/* Catch pc_terminate's non-local DOS exit and return its code to the launcher. */
int platform_run(void (*entry)(void)) {
    exit_ready = 1;
    exit_status = 0;
    if (!setjmp(exit_jump))
        entry();
    exit_ready = 0;
    polling = event_clock = 0;
    frame = NULL;
    call_regs = NULL;
    video_wait=0;
    return exit_status;
}
/* Model INT 21h/AH=4Ch by unwinding to the episode launcher with its DOS status. */
_Noreturn void pc_terminate(uint8_t status) {
    exit_status = status;
    pc_outb(PC_PORT_SPEAKER_CONTROL, (uint8_t)(pc_inb(PC_PORT_SPEAKER_CONTROL) & ~3u));
    if (exit_ready)
        longjmp(exit_jump, 1);
    platform_shutdown();
    exit(status);
}
