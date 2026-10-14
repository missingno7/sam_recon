/* Emulate PIT channel 2 and the PC speaker; SDL playback and WAV capture share one renderer. */
#include "pc_internal.h"
#include <math.h>
#include <stdlib.h>
#include <string.h>

#define PC_AUDIO_STARTUP_DELAY_NS 40000000u

enum {
    WAV_PCM_FORMAT = 1,
    WAV_MONO_CHANNELS = 1,
    WAV_SAMPLE_BYTES = 2,
    WAV_BITS_PER_SAMPLE = 16,
    WAV_CHUNK_ID_BYTES = 4
};

typedef struct {
    uint64_t us;
    uint32_t divisor;
    uint8_t gate, restart;
} speaker_event;
static speaker_event *events;
static size_t event_count, event_capacity;
static SDL_Mutex *mutex;
static SDL_AudioStream *stream;
static uint64_t audio_origin, sample_index;
static size_t audio_event;
static uint32_t audio_divisor = 65536;
static uint8_t audio_gate;
static double audio_phase;
static float audio_filter;
/* Guard shared history while the SDL callback renders samples on its audio thread. */
static void lock(void) {
    if (mutex)
        SDL_LockMutex(mutex);
}
static void unlock(void) {
    if (mutex)
        SDL_UnlockMutex(mutex);
}
/* Reset the PIT speaker event history, playback phase, and SDL stream position. */
void speaker_reset(void) {
    lock();
    event_count = 0;
    sample_index = 0;
    audio_event = 0;
    audio_divisor = 65536;
    audio_gate = 0;
    audio_phase = 0;
    audio_filter = 0;
    audio_origin = SDL_GetTicksNS();
    unlock();
    if (stream)
        SDL_ClearAudioStream(stream);
}
/* Record each PIT/speaker state change at its emulated timestamp for deterministic replay. */
void speaker_change(uint32_t d, uint8_t gate, int restart) {
    lock();
    if (event_count == event_capacity) {
        size_t capacity = event_capacity ? event_capacity * 2 : 1024;
        speaker_event *p = realloc(events, capacity * sizeof *events);
        if (!p) {
            unlock();
            fprintf(stderr, "speaker history allocation failed\n");
            abort();
        }
        events = p;
        event_capacity = capacity;
    }
    speaker_event e = {pc_time_us(), d ? d : 65536, gate, (uint8_t)restart};
    /* Normally already ordered. IRQs held by CLI are inserted by their scheduled time. */
    size_t i = event_count++;
    while (i && events[i - 1].us > e.us) {
        events[i] = events[i - 1];
        --i;
    }
    events[i] = e;
    unlock();
}
/* Smooth the square-wave discontinuity to reduce aliasing at the host sample rate. */
static double blep(double t, double increment) {
    if (t < increment) {
        double x = t / increment;
        return 2 * x - x * x - 1;
    }
    if (t > 1 - increment) {
        double x = (t - 1) / increment;
        return x * x + 2 * x + 1;
    }
    return 0;
}
/* Replay timestamped PIT/speaker state into the filtered, band-limited audio stream. */
void speaker_render(float *out, size_t n, uint64_t *sample, size_t *event, uint32_t *divisor,
                    uint8_t *gate, double *phase, float *filter) {
    lock();
    for (size_t i = 0; i < n; ++i) {
        uint64_t us = *sample * 1000000u / PC_AUDIO_RATE;
        while (*event < event_count && events[*event].us <= us) {
            speaker_event e = events[(*event)++];
            *divisor = e.divisor;
            *gate = e.gate;
            if (e.restart)
                *phase = 0;
        }
        double increment = (double)PC_PIT_HZ / (*divisor * PC_AUDIO_RATE);
        float level = 0;
        if (*gate & PC_SPEAKER_GATE_TIMER2) {
            *phase += increment;
            *phase -= floor(*phase);
            if (*gate == PC_SPEAKER_GATE_MASK && increment < 0.5) {
                double t = *phase + 0.5;
                if (t >= 1)
                    t -= 1;
                level = (float)((*phase < 0.5 ? 1 : -1) + blep(*phase, increment) -
                                blep(t, increment)) *
                        0.18f;
            }
        }
        *filter += (level - *filter) * 0.45f;
        out[i] = *filter;
        ++*sample;
    }
    unlock();
}
/* Feed SDL while keeping its startup buffering from advancing the emulated speaker timeline. */
static void SDLCALL fill_audio(void *user, SDL_AudioStream *s, int needed, int total) {
    (void)user;
    (void)total;
    float buffer[512];
    int count = needed / (int)sizeof(float);
    /* A fixed 40ms replay delay absorbs a safe point between device changes. */
    if (SDL_GetTicksNS() - audio_origin < PC_AUDIO_STARTUP_DELAY_NS) {
        memset(buffer, 0, sizeof buffer);
        while (count > 0) {
            int n = count < 512 ? count : 512;
            SDL_PutAudioStreamData(s, buffer, n * (int)sizeof(float));
            count -= n;
        }
        return;
    }
    while (count > 0) {
        int n = count < 512 ? count : 512;
        speaker_render(buffer, (size_t)n, &sample_index, &audio_event, &audio_divisor, &audio_gate,
                       &audio_phase, &audio_filter);
        SDL_PutAudioStreamData(s, buffer, n * (int)sizeof(float));
        count -= n;
    }
}
/* Create the mono 44.1 kHz SDL stream after resetting the emulated speaker history. */
int speaker_init(int enabled) {
    mutex = SDL_CreateMutex();
    if (!mutex)
        return 0;
    speaker_reset();
    if (!enabled)
        return 1;
    SDL_AudioSpec spec = {SDL_AUDIO_F32, 1, PC_AUDIO_RATE};
    stream = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, fill_audio, NULL);
    return stream && SDL_ResumeAudioStreamDevice(stream);
}
/* Close SDL's audio stream and release the timestamped speaker history. */
void speaker_shutdown(void) {
    if (stream)
        SDL_DestroyAudioStream(stream);
    stream = NULL;
    if (mutex)
        SDL_DestroyMutex(mutex);
    mutex = NULL;
    free(events);
    events = NULL;
    event_count = event_capacity = 0;
}
static void le16(FILE *f, uint16_t v) {
    fputc(v & 255, f);
    fputc(v >> 8, f);
}
static void le32(FILE *f, uint32_t v) {
    le16(f, (uint16_t)v);
    le16(f, (uint16_t)(v >> 16));
}
/* Write the same emulated speaker stream as PCM data in a little-endian WAV file. */
int pc_speaker_capture(const char *path, uint64_t end) {
    uint64_t frames = (end * PC_AUDIO_RATE + 999999u) / 1000000u;
    if (frames > (UINT32_MAX - 36u) / 2u)
        return 0;
    FILE *f = fopen(path, "wb");
    if (!f)
        return 0;
    uint32_t bytes = (uint32_t)frames * 2;
    fwrite("RIFF", 1, WAV_CHUNK_ID_BYTES, f);
    le32(f, bytes + 36);
    fwrite("WAVEfmt ", 1, 2 * WAV_CHUNK_ID_BYTES, f);
    le32(f, 16);
    le16(f, WAV_PCM_FORMAT);
    le16(f, WAV_MONO_CHANNELS);
    le32(f, PC_AUDIO_RATE);
    le32(f, PC_AUDIO_RATE * WAV_SAMPLE_BYTES);
    le16(f, WAV_SAMPLE_BYTES);
    le16(f, WAV_BITS_PER_SAMPLE);
    fwrite("data", 1, WAV_CHUNK_ID_BYTES, f);
    le32(f, bytes);
    uint64_t sample = 0;
    size_t event = 0;
    uint32_t divisor = 65536;
    uint8_t gate = 0;
    double phase = 0;
    float filter = 0, buffer[512];
    while (sample < frames) {
        size_t n = (size_t)(frames - sample);
        if (n > 512)
            n = 512;
        speaker_render(buffer, n, &sample, &event, &divisor, &gate, &phase, &filter);
        for (size_t i = 0; i < n; ++i)
            le16(f, (uint16_t)(int16_t)(buffer[i] * 32767));
    }
    int ok = !ferror(f);
    if (fclose(f))
        ok = 0;
    return ok;
}
