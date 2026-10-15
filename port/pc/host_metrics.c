/* Opt-in host diagnostics. No counters or timestamps enter the emulated PC. */
#include "host_metrics.h"
#include <SDL3/SDL.h>
#include <stdatomic.h>
#include <stdio.h>
static _Atomic uint64_t counters[HM_COUNT];
static FILE *output;
static uint64_t origin, next;
int pc_metrics_enabled;
static const char *names[HM_COUNT] = {"poll","pump","sdl_poll","pump_ns","wait","short_wait",
    "wait_request_ns","wait_ns","scanout","render_ns","present","present_ns",
    "audio_callback","audio_ns","audio_frames","delay","audio_late","audio_late_us","spin_ns"};
void pc_metrics_max(enum host_metric which,uint64_t value) {
    uint64_t old=atomic_load(&counters[which]);
    while(old<value && !atomic_compare_exchange_weak(&counters[which],&old,value)) {}
}
void pc_metrics_add(enum host_metric which, uint64_t value) {
    atomic_fetch_add_explicit(&counters[which],value,memory_order_relaxed);
}
void pc_metrics_init(const char *path) {
    output = path ? fopen(path,"w") : NULL;
    pc_metrics_enabled = output != NULL;
    for (unsigned i=0;i<HM_COUNT;++i) atomic_store(&counters[i],0);
    origin=SDL_GetTicksNS(); next=origin+1000000000u;
}
void pc_metrics_tick(void) {
    if (!output) return;
    uint64_t now=SDL_GetTicksNS();
    if (now<next) return;
    fprintf(output,"{\"wall_ns\":%llu",(unsigned long long)(now-origin));
    for (unsigned i=0;i<HM_COUNT;++i)
        fprintf(output,",\"%s\":%llu",names[i],(unsigned long long)atomic_load_explicit(&counters[i],memory_order_relaxed));
    fputs("}\n",output);fflush(output);
    next=now+1000000000u;
}
void pc_metrics_shutdown(void) {
    if (output) { next=0;pc_metrics_tick();fclose(output); }
    output=NULL;pc_metrics_enabled=0;
}
