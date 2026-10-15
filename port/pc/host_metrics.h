#ifndef SAM_HOST_METRICS_H
#define SAM_HOST_METRICS_H
#include <stdint.h>
enum host_metric {
    HM_POLL, HM_PUMP, HM_SDL_POLL, HM_PUMP_NS, HM_WAIT, HM_SHORT_WAIT,
    HM_WAIT_REQUEST_NS, HM_WAIT_NS, HM_SCANOUT, HM_RENDER_NS, HM_PRESENT, HM_PRESENT_NS,
    HM_AUDIO, HM_AUDIO_NS, HM_AUDIO_FRAMES, HM_DELAY, HM_AUDIO_LATE, HM_AUDIO_LATE_US, HM_SPIN_NS, HM_COUNT
};
extern int pc_metrics_enabled;
void pc_metrics_init(const char *path);
void pc_metrics_add(enum host_metric which, uint64_t value);
void pc_metrics_max(enum host_metric which,uint64_t value);
void pc_metrics_tick(void);
void pc_metrics_shutdown(void);
#define HOST_COUNT(which,n) do { if (pc_metrics_enabled) pc_metrics_add(which,n); } while (0)
#endif
