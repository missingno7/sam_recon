/* SDL3 display/input backend; host key and controller events become DOS hardware events. */
#include "pc_internal.h"
#include "settings.h"
#include "host_metrics.h"
#include "host_video.h"
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

static SDL_Window *window;
static SDL_Renderer *renderer;
static SDL_Texture *texture;
static SDL_Gamepad *gamepad;
static SDL_Joystick *joystick;
static int texture_w, texture_h, quit_requested, initialised, deterministic_script, physical_shots;
static uint32_t pixels[720 * 480];
static uint32_t next_pixels[720 * 480];
static uint32_t shot_pixels[720 * 480];
static int captured_w,captured_h;
static uint64_t next_pump,frame_generation;
static int native_video;
static char wav_path[1024];
static char settings_path[2048];
static pc_settings presentation;
static int settings_dirty, headless_mode, program_started;
static uint8_t presentation_keys[SDL_SCANCODE_COUNT];

const pc_settings *platform_settings(void) { return &presentation; }
const char *platform_settings_path(void) { return settings_path; }
int platform_apply_settings(const pc_settings *s) {
    if (s->window_width < 320 || s->window_width > 8192 ||
        s->window_height < 200 || s->window_height > 8192) return 0;
    if (window && !headless_mode && s->fullscreen != presentation.fullscreen &&
        !SDL_SetWindowFullscreen(window, s->fullscreen != 0)) return 0;
    if (window && !s->fullscreen)
        SDL_SetWindowSize(window, s->window_width, s->window_height);
    presentation = *s;
    settings_dirty = 1;
    if (texture) SDL_SetTextureScaleMode(texture, s->smooth ? SDL_SCALEMODE_LINEAR : SDL_SCALEMODE_NEAREST);
    return 1;
}
enum action { DOWN, UP, SHOT, QUIT };
typedef struct {
    uint64_t us;
    unsigned order;
    enum action action;
    uint16_t scan;
    char path[1024];
} script_event;
static script_event *script;
static size_t script_count, script_cursor;
static uint16_t repeat_scan;
static uint64_t repeat_next = UINT64_MAX, repeat_number, repeat_origin;
static uint8_t host_held[SDL_SCANCODE_COUNT];

/* Device time starts at zero on each DOS start; scripts use one session timeline.
   Keep the window/script cursor, rebase future commands, and release host keys. */
void pc_host_program_reset(void) {
    if (!initialised) return;
    if (program_started) {
        uint64_t elapsed = pc_time_us();
        for (size_t i = script_cursor; i < script_count; ++i)
            script[i].us = script[i].us > elapsed ? script[i].us - elapsed : 0;
    }
    program_started = 1;
    repeat_next = UINT64_MAX;
    repeat_scan = 0;
    memset(host_held, 0, sizeof host_held);
    memset(presentation_keys, 0, sizeof presentation_keys);
}

enum {
    SDL_PC_SCAN_0 = 0x0b,
    SDL_PC_SCAN_MINUS = 0x0c,
    SDL_PC_SCAN_EQUALS = 0x0d,
    SDL_PC_SCAN_TAB = 0x0f,
    SDL_PC_SCAN_LEFT_BRACKET = 0x1a,
    SDL_PC_SCAN_RIGHT_BRACKET = 0x1b,
    SDL_PC_SCAN_SEMICOLON = 0x27,
    SDL_PC_SCAN_APOSTROPHE = 0x28,
    SDL_PC_SCAN_GRAVE = 0x29,
    SDL_PC_SCAN_BACKSLASH = 0x2b,
    SDL_PC_SCAN_COMMA = 0x33,
    SDL_PC_SCAN_PERIOD = 0x34,
    SDL_PC_SCAN_SLASH = 0x35,
    SDL_PC_SCAN_KP_MULTIPLY = 0x37,
    SDL_PC_SCAN_SPACE = 0x39,
    SDL_PC_SCAN_KP_7 = 0x47,
    SDL_PC_SCAN_KP_8 = 0x48,
    SDL_PC_SCAN_KP_9 = 0x49,
    SDL_PC_SCAN_KP_MINUS = 0x4a,
    SDL_PC_SCAN_KP_4 = 0x4b,
    SDL_PC_SCAN_KP_5 = 0x4c,
    SDL_PC_SCAN_KP_6 = 0x4d,
    SDL_PC_SCAN_KP_PLUS = 0x4e,
    SDL_PC_SCAN_KP_1 = 0x4f,
    SDL_PC_SCAN_KP_2 = 0x50,
    SDL_PC_SCAN_KP_3 = 0x51,
    SDL_PC_SCAN_KP_0 = 0x52,
    SDL_PC_SCAN_KP_PERIOD = 0x53,
    SDL_PC_SCAN_NONUS_BACKSLASH = 0x56,
    SDL_PC_SCAN_EXT_HOME = 0xe047,
    SDL_PC_SCAN_EXT_UP = 0xe048,
    SDL_PC_SCAN_EXT_PAGE_UP = 0xe049,
    SDL_PC_SCAN_EXT_LEFT = 0xe04b,
    SDL_PC_SCAN_EXT_RIGHT = 0xe04d,
    SDL_PC_SCAN_EXT_END = 0xe04f,
    SDL_PC_SCAN_EXT_DOWN = 0xe050,
    SDL_PC_SCAN_EXT_PAGE_DOWN = 0xe051,
    SDL_PC_SCAN_EXT_INSERT = 0xe052,
    SDL_PC_SCAN_EXT_DELETE = 0xe053,
    SDL_PC_SCAN_EXT_KP_ENTER = 0xe01c,
    SDL_PC_SCAN_EXT_KP_DIVIDE = 0xe035,
    SDL_PC_SCAN_EXT_RIGHT_CTRL = 0xe01d,
    SDL_PC_SCAN_EXT_RIGHT_ALT = 0xe038
};

/* Translate SDL's physical scancode names into the set-1 make codes expected by DOS. */
static uint16_t xt(SDL_Scancode s) {
    /* SDL A..Z order mapped to the corresponding PC set-1 make codes. */
    static const uint8_t letters[26] = {0x1e, 0x30, 0x2e, 0x20, 0x12, 0x21, 0x22, 0x23, 0x17,
                                        0x24, 0x25, 0x26, 0x32, 0x31, 0x18, 0x19, 0x10, 0x13,
                                        0x1f, 0x14, 0x16, 0x2f, 0x11, 0x2d, 0x15, 0x2c};
    if (s >= SDL_SCANCODE_A && s <= SDL_SCANCODE_Z)
        return letters[s - SDL_SCANCODE_A];
    if (s >= SDL_SCANCODE_1 && s <= SDL_SCANCODE_9)
        return (uint16_t)(2 + s - SDL_SCANCODE_1);
    if (s >= SDL_SCANCODE_F1 && s <= SDL_SCANCODE_F10)
        return (uint16_t)(PC_SCAN_F1 + s - SDL_SCANCODE_F1);
    switch (s) {
    case SDL_SCANCODE_0:
        return SDL_PC_SCAN_0;
    case SDL_SCANCODE_ESCAPE:
        return 1;
    case SDL_SCANCODE_MINUS:
        return SDL_PC_SCAN_MINUS;
    case SDL_SCANCODE_EQUALS:
        return SDL_PC_SCAN_EQUALS;
    case SDL_SCANCODE_BACKSPACE:
        return 0x0e;
    case SDL_SCANCODE_TAB:
        return SDL_PC_SCAN_TAB;
    case SDL_SCANCODE_LEFTBRACKET:
        return SDL_PC_SCAN_LEFT_BRACKET;
    case SDL_SCANCODE_RIGHTBRACKET:
        return SDL_PC_SCAN_RIGHT_BRACKET;
    case SDL_SCANCODE_RETURN:
        return PC_SCAN_RETURN;
    case SDL_SCANCODE_LCTRL:
        return PC_SCAN_LEFT_CTRL;
    case SDL_SCANCODE_SEMICOLON:
        return SDL_PC_SCAN_SEMICOLON;
    case SDL_SCANCODE_APOSTROPHE:
        return SDL_PC_SCAN_APOSTROPHE;
    case SDL_SCANCODE_GRAVE:
        return SDL_PC_SCAN_GRAVE;
    case SDL_SCANCODE_LSHIFT:
        return PC_SCAN_LEFT_SHIFT;
    case SDL_SCANCODE_BACKSLASH:
        return SDL_PC_SCAN_BACKSLASH;
    case SDL_SCANCODE_COMMA:
        return SDL_PC_SCAN_COMMA;
    case SDL_SCANCODE_PERIOD:
        return SDL_PC_SCAN_PERIOD;
    case SDL_SCANCODE_SLASH:
        return SDL_PC_SCAN_SLASH;
    case SDL_SCANCODE_RSHIFT:
        return PC_SCAN_RIGHT_SHIFT;
    case SDL_SCANCODE_KP_MULTIPLY:
        return SDL_PC_SCAN_KP_MULTIPLY;
    case SDL_SCANCODE_LALT:
        return PC_SCAN_LEFT_ALT;
    case SDL_SCANCODE_SPACE:
        return SDL_PC_SCAN_SPACE;
    case SDL_SCANCODE_CAPSLOCK:
        return PC_SCAN_CAPS_LOCK;
    case SDL_SCANCODE_NUMLOCKCLEAR:
        return PC_SCAN_NUM_LOCK;
    case SDL_SCANCODE_SCROLLLOCK:
        return PC_SCAN_SCROLL_LOCK;
    case SDL_SCANCODE_KP_7:
        return SDL_PC_SCAN_KP_7;
    case SDL_SCANCODE_KP_8:
        return SDL_PC_SCAN_KP_8;
    case SDL_SCANCODE_KP_9:
        return SDL_PC_SCAN_KP_9;
    case SDL_SCANCODE_KP_MINUS:
        return SDL_PC_SCAN_KP_MINUS;
    case SDL_SCANCODE_KP_4:
        return SDL_PC_SCAN_KP_4;
    case SDL_SCANCODE_KP_5:
        return SDL_PC_SCAN_KP_5;
    case SDL_SCANCODE_KP_6:
        return SDL_PC_SCAN_KP_6;
    case SDL_SCANCODE_KP_PLUS:
        return SDL_PC_SCAN_KP_PLUS;
    case SDL_SCANCODE_KP_1:
        return SDL_PC_SCAN_KP_1;
    case SDL_SCANCODE_KP_2:
        return SDL_PC_SCAN_KP_2;
    case SDL_SCANCODE_KP_3:
        return SDL_PC_SCAN_KP_3;
    case SDL_SCANCODE_KP_0:
        return SDL_PC_SCAN_KP_0;
    case SDL_SCANCODE_KP_PERIOD:
        return SDL_PC_SCAN_KP_PERIOD;
    case SDL_SCANCODE_NONUSBACKSLASH:
        return SDL_PC_SCAN_NONUS_BACKSLASH;
    case SDL_SCANCODE_F11:
        return PC_SCAN_F11;
    case SDL_SCANCODE_F12:
        return PC_SCAN_F12;
    case SDL_SCANCODE_HOME:
        return SDL_PC_SCAN_EXT_HOME;
    case SDL_SCANCODE_UP:
        return SDL_PC_SCAN_EXT_UP;
    case SDL_SCANCODE_PAGEUP:
        return SDL_PC_SCAN_EXT_PAGE_UP;
    case SDL_SCANCODE_LEFT:
        return SDL_PC_SCAN_EXT_LEFT;
    case SDL_SCANCODE_RIGHT:
        return SDL_PC_SCAN_EXT_RIGHT;
    case SDL_SCANCODE_END:
        return SDL_PC_SCAN_EXT_END;
    case SDL_SCANCODE_DOWN:
        return SDL_PC_SCAN_EXT_DOWN;
    case SDL_SCANCODE_PAGEDOWN:
        return SDL_PC_SCAN_EXT_PAGE_DOWN;
    case SDL_SCANCODE_INSERT:
        return SDL_PC_SCAN_EXT_INSERT;
    case SDL_SCANCODE_DELETE:
        return SDL_PC_SCAN_EXT_DELETE;
    case SDL_SCANCODE_KP_ENTER:
        return SDL_PC_SCAN_EXT_KP_ENTER;
    case SDL_SCANCODE_KP_DIVIDE:
        return SDL_PC_SCAN_EXT_KP_DIVIDE;
    case SDL_SCANCODE_RCTRL:
        return SDL_PC_SCAN_EXT_RIGHT_CTRL;
    case SDL_SCANCODE_RALT:
        return SDL_PC_SCAN_EXT_RIGHT_ALT;
    default:
        return 0;
    }
}
/* Accept script key names and SDL key names as set-1 scan-code inputs. */
static uint16_t named_scan(const char *name) {
    if (!SDL_strcasecmp(name, "esc"))
        return PC_SCAN_ESCAPE;
    if (!SDL_strcasecmp(name, "enter"))
        return PC_SCAN_RETURN;
    if (!SDL_strcasecmp(name, "ctrl") || !SDL_strcasecmp(name, "lctrl"))
        return PC_SCAN_LEFT_CTRL;
    if (!SDL_strcasecmp(name, "rctrl"))
        return SDL_PC_SCAN_EXT_RIGHT_CTRL;
    if (!SDL_strcasecmp(name, "alt") || !SDL_strcasecmp(name, "lalt"))
        return PC_SCAN_LEFT_ALT;
    if (!SDL_strcasecmp(name, "ralt"))
        return SDL_PC_SCAN_EXT_RIGHT_ALT;
    if (!SDL_strcasecmp(name, "shift"))
        return PC_SCAN_LEFT_SHIFT;
    return xt(SDL_GetScancodeFromName(name));
}
/* Queue one make/break event and schedule BIOS-style repeats for held non-modifier keys. */
static void send_key(uint64_t us, uint16_t scan, int down) {
    pc_queue_key(us, scan, down);
    unsigned s = scan & PC_SCAN_CODE_MASK;
    if (down && s != PC_SCAN_LEFT_CTRL && s != PC_SCAN_LEFT_ALT && s != PC_SCAN_LEFT_SHIFT &&
        s != PC_SCAN_RIGHT_SHIFT && s != PC_SCAN_CAPS_LOCK && s != PC_SCAN_NUM_LOCK &&
        s != PC_SCAN_SCROLL_LOCK) {
        repeat_scan = scan;
        repeat_origin = us + 500000;
        repeat_number = 0;
        repeat_next = repeat_origin;
    } else if (!down && scan == repeat_scan)
        repeat_next = UINT64_MAX;
}
static int compare_event(const void *aa, const void *bb) {
    const script_event *a = aa, *b = bb;
    if (a->us != b->us)
        return a->us < b->us ? -1 : 1;
    return a->order < b->order ? -1 : a->order > b->order;
}
static int append_event(script_event e) {
    if (script_count >= 8192)
        return 0;
    script_event *p = realloc(script, (script_count + 1) * sizeof *script);
    if (!p)
        return 0;
    script = p;
    script[script_count++] = e;
    return 1;
}
/* Read a timestamped input/screenshot script and sort events by time and source order. */
static int load_script(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f)
        return 0;
    char line[2048];
    unsigned order = 0, line_num = 0;
    while (fgets(line, sizeof line, f)) {
        ++line_num;
        char *p = line;
        while (isspace((unsigned char)*p))
            ++p;
        if (!*p || *p == '#')
            continue;
        unsigned long long ms;
        char command[32], arg[1024] = "";
        if (sscanf(p, "%llu %31s %1023s", &ms, command, arg) < 2)
            goto bad;
        script_event e = {0};
        e.us = (uint64_t)ms * 1000;
        e.order = order++;
        if (!SDL_strcasecmp(command, "quit"))
            e.action = QUIT;
        else if (!SDL_strcasecmp(command, "shot")) {
            e.action = SHOT;
            if (!*arg)
                goto bad;
            const char *slash = strrchr(path, '/'), *back = strrchr(path, '\\');
            if (!slash || (back && back > slash))
                slash = back;
            size_t n = slash ? (size_t)(slash - path + 1) : 0;
            if (arg[0] == '/' || arg[0] == '\\' || (strlen(arg) > 1 && arg[1] == ':'))
                n = 0;
            if (n + strlen(arg) >= sizeof e.path)
                goto bad;
            memcpy(e.path, path, n);
            strcpy(e.path + n, arg);
        } else if (!SDL_strcasecmp(command, "key") || !SDL_strcasecmp(command, "keydown") ||
                   !SDL_strcasecmp(command, "keyup")) {
            e.scan = named_scan(arg);
            if (!e.scan)
                goto bad;
            e.action = !SDL_strcasecmp(command, "keyup") ? UP : DOWN;
            if (!SDL_strcasecmp(command, "key")) {
                if (!append_event(e))
                    goto bad;
                e.action = UP;
                e.us += 45000;
                e.order = order++;
            }
        } else
            goto bad;
        if (!append_event(e))
            goto bad;
    }
    fclose(f);
    qsort(script, script_count, sizeof *script, compare_event);
    return 1;
bad:
    fprintf(stderr, "invalid script %s:%u\n", path, line_num);
    fclose(f);
    return 0;
}
/* Return the earliest script command or synthesized key repeat for the scheduler. */
uint64_t pc_script_next(void) {
    uint64_t t = script_cursor < script_count ? script[script_cursor].us : UINT64_MAX;
    return repeat_next < t ? repeat_next : t;
}
/* Dispatch the next scripted event or the next generated key-repeat event. */
void pc_script_dispatch(uint64_t now) {
    if (script_cursor < script_count && script[script_cursor].us <= now) {
        script_event *e = &script[script_cursor++];
        switch (e->action) {
        case DOWN:
        case UP:
            send_key(e->us, e->scan, e->action == DOWN);
            break;
        case SHOT:
            if (!platform_screenshot(e->path)) {
                fprintf(stderr, "screenshot failed: %s\n", SDL_GetError());
                abort();
            }
            break;
        case QUIT:
            pc_request_quit();
            break;
        }
    } else if (repeat_next <= now) {
        pc_queue_key(repeat_next, repeat_scan, 1);
        ++repeat_number;
        repeat_next = repeat_origin + (repeat_number * 1000000u) / 30u;
    }
}
void pc_request_quit(void) {
    quit_requested = 1;
}
int platform_quit_requested(void) {
    return quit_requested;
}
/* Open the attached input as a gamepad when possible, otherwise as a raw joystick. */
static void open_controller(SDL_JoystickID id) {
    if (gamepad || joystick)
        return;
    if (SDL_IsGamepad(id))
        gamepad = SDL_OpenGamepad(id);
    else
        joystick = SDL_OpenJoystick(id);
}
/* Pump SDL input and translate host keyboard/gamepad state into emulated devices. */
void pc_host_pump(void) {
    if (!initialised)
        return;
    uint64_t wall=SDL_GetTicksNS();
    if(pc_wall_clock() && wall<next_pump)return;
    next_pump=wall+1000000u;
    HOST_COUNT(HM_PUMP,1);
    uint64_t before=pc_metrics_enabled ? SDL_GetTicksNS() : 0;
    if (pc_metrics_enabled) pc_metrics_tick();
    SDL_Event e;
    HOST_COUNT(HM_SDL_POLL,1);
    while (SDL_PollEvent(&e)) {
        HOST_COUNT(HM_SDL_POLL,1);
        if(native_video && e.type>=SDL_EVENT_WINDOW_FIRST && e.type<=SDL_EVENT_WINDOW_LAST)
            pc_video_redraw();
        uint64_t now = pc_time_us();
        if (e.type == SDL_EVENT_QUIT)
            quit_requested = 1;
        else if (e.type == SDL_EVENT_KEY_DOWN || e.type == SDL_EVENT_KEY_UP) {
            SDL_Scancode s = e.key.scancode;
            int down = e.type == SDL_EVENT_KEY_DOWN;
            if (s < 0 || s >= SDL_SCANCODE_COUNT) continue;
            if ((down && (s == SDL_SCANCODE_F11 ||
                         (s == SDL_SCANCODE_RETURN && (e.key.mod & SDL_KMOD_ALT)))) ||
                presentation_keys[s]) {
                presentation_keys[s] = (uint8_t)down;
                if (down && !e.key.repeat) {
                    pc_settings next = presentation;
                    next.fullscreen = !next.fullscreen;
                    if (!platform_apply_settings(&next))
                        fprintf(stderr, "fullscreen: %s\n", SDL_GetError());
                }
                continue;
            }
            if (deterministic_script)
                continue;
            uint16_t scan = xt(s);
            if (scan && !e.key.repeat && host_held[s] != down) {
                host_held[s] = (uint8_t)down;
                send_key(now, scan, down);
            }
        } else if (e.type == SDL_EVENT_WINDOW_RESIZED && !presentation.fullscreen) {
            if (e.window.data1 >= 320 && e.window.data2 >= 200 &&
                e.window.data1 <= 8192 && e.window.data2 <= 8192 &&
                (presentation.window_width != e.window.data1 || presentation.window_height != e.window.data2)) {
                presentation.window_width = e.window.data1;
                presentation.window_height = e.window.data2;
                settings_dirty = 1;
            }
        } else if (e.type == SDL_EVENT_WINDOW_FOCUS_LOST) {
            memset(presentation_keys, 0, sizeof presentation_keys);
            for (unsigned s = 0; s < SDL_SCANCODE_COUNT; ++s)
                if (host_held[s]) {
                    send_key(now, xt((SDL_Scancode)s), 0);
                    host_held[s] = 0;
                }
        } else if (e.type == SDL_EVENT_JOYSTICK_ADDED)
            open_controller(e.jdevice.which);
        else if (e.type == SDL_EVENT_JOYSTICK_REMOVED) {
            if (gamepad && SDL_GetGamepadID(gamepad) == e.jdevice.which) {
                SDL_CloseGamepad(gamepad);
                gamepad = NULL;
            }
            if (joystick && SDL_GetJoystickID(joystick) == e.jdevice.which) {
                SDL_CloseJoystick(joystick);
                joystick = NULL;
            }
            pc_joystick_set(0, NULL, 0);
        }
    }
    if (!deterministic_script && (gamepad || joystick)) {
        int16_t axes[4] = {0};
        uint8_t buttons = 0;
        if (gamepad) {
            axes[0] = SDL_GetGamepadAxis(gamepad, SDL_GAMEPAD_AXIS_LEFTX);
            axes[1] = SDL_GetGamepadAxis(gamepad, SDL_GAMEPAD_AXIS_LEFTY);
            if (SDL_GetGamepadButton(gamepad, SDL_GAMEPAD_BUTTON_DPAD_LEFT))
                axes[0] = -32768;
            if (SDL_GetGamepadButton(gamepad, SDL_GAMEPAD_BUTTON_DPAD_RIGHT))
                axes[0] = 32767;
            if (SDL_GetGamepadButton(gamepad, SDL_GAMEPAD_BUTTON_DPAD_UP))
                axes[1] = -32768;
            if (SDL_GetGamepadButton(gamepad, SDL_GAMEPAD_BUTTON_DPAD_DOWN))
                axes[1] = 32767;
            buttons = (uint8_t)((SDL_GetGamepadButton(gamepad, SDL_GAMEPAD_BUTTON_SOUTH) ? 1 : 0) |
                                (SDL_GetGamepadButton(gamepad, SDL_GAMEPAD_BUTTON_WEST) ? 2 : 0));
        } else {
            int n = SDL_GetNumJoystickAxes(joystick);
            for (unsigned a = 0; a < 4 && a < (unsigned)n; ++a)
                axes[a] = SDL_GetJoystickAxis(joystick, (int)a);
            for (unsigned b = 0; b < 4 && b < (unsigned)SDL_GetNumJoystickButtons(joystick); ++b)
                if (SDL_GetJoystickButton(joystick, (int)b))
                    buttons |= (uint8_t)(1u << b);
        }
        pc_joystick_set(1, axes, buttons);
    }
    if (pc_metrics_enabled) pc_metrics_add(HM_PUMP_NS,SDL_GetTicksNS()-before);
}
void pc_host_pump_force(void) { next_pump=0;pc_host_pump(); }
int pc_host_has_controller(void) { return gamepad || joystick; }
int pc_host_window_messages(void) { return !headless_mode; }
/* Capture completed emulated scanouts; host presentation owns its pacing. */
void platform_present(void) {
    HOST_COUNT(HM_SCANOUT,1);
    if(headless_mode)return;
    if(native_video) {
        int w,h;vga_scanout_dimensions(&w,&h);
        uint64_t before=pc_metrics_enabled ? SDL_GetTicksNS() : 0;
        if(!frame_generation || vga_scanout_changed()) {
            vga_render_scanout_rgb(next_pixels);
            /* The game also draws into hidden pages. Those writes invalidate
               the adapter cache but need no upload/present if scanout is equal. */
            if(!frame_generation || captured_w!=w || captured_h!=h ||
               memcmp(pixels,next_pixels,(size_t)w*h*4)) {
                memcpy(pixels,next_pixels,(size_t)w*h*4);++frame_generation;
                captured_w=w;captured_h=h;
            }
        }
        if(pc_metrics_enabled)pc_metrics_add(HM_RENDER_NS,SDL_GetTicksNS()-before);
        pc_video_submit(pixels,w,h,vga_border_rgb(),frame_generation,&presentation);
        return;
    }
    if (!renderer)
        return;
    int w, h;
    uint64_t before=pc_metrics_enabled ? SDL_GetTicksNS() : 0;
    vga_scanout_dimensions(&w, &h);
    vga_render_scanout_rgb(pixels);
    if (pc_metrics_enabled) pc_metrics_add(HM_RENDER_NS,SDL_GetTicksNS()-before);
    if (!texture || texture_w != w || texture_h != h) {
        if (texture)
            SDL_DestroyTexture(texture);
        texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
                                    w, h);
        if (!texture) {
            fprintf(stderr, "texture: %s\n", SDL_GetError());
            abort();
        }
        texture_w = w;
        texture_h = h;
        SDL_SetTextureScaleMode(texture, presentation.smooth ? SDL_SCALEMODE_LINEAR : SDL_SCALEMODE_NEAREST);
    }
    int beam_w = w == 320 ? 320 : 640, beam_h = w == 320 ? 240 : 480;
    int border_w = beam_w / 40, border_h = beam_h / 40;
    int canvas_w = beam_w + 2 * border_w, canvas_h = beam_h + 2 * border_h;
    SDL_SetRenderLogicalPresentation(renderer, canvas_w, canvas_h,
                                     presentation.integer_scale ? SDL_LOGICAL_PRESENTATION_INTEGER_SCALE
                                                                : SDL_LOGICAL_PRESENTATION_LETTERBOX);
    SDL_UpdateTexture(texture, NULL, pixels, w * (int)sizeof(uint32_t));
    uint32_t border = vga_border_rgb();
    SDL_SetRenderDrawColor(renderer, (uint8_t)(border >> 16), (uint8_t)(border >> 8),
                           (uint8_t)border, 255);
    SDL_RenderClear(renderer);
    SDL_FRect dest = {(float)border_w, (float)border_h, (float)beam_w, (float)beam_h};
    SDL_RenderTexture(renderer, texture, NULL, &dest);
    before=pc_metrics_enabled ? SDL_GetTicksNS() : 0;
    SDL_RenderPresent(renderer);
    HOST_COUNT(HM_PRESENT,1);
    if (pc_metrics_enabled) pc_metrics_add(HM_PRESENT_NS,SDL_GetTicksNS()-before);
}
/* Save either the visible 320x200 virtual frame or physical VGA scanout as a PNG. */
int platform_screenshot(const char *path) {
    if(native_video)pc_video_redraw();
    int w, h;
    if (physical_shots) {
        vga_scanout_dimensions(&w, &h);
        vga_render_scanout_rgb(shot_pixels);
    } else {
        vga_dimensions(&w, &h);
        vga_render_rgb(shot_pixels);
    }
    SDL_Surface *s =
        SDL_CreateSurfaceFrom(w, h, SDL_PIXELFORMAT_ARGB8888, shot_pixels, w * (int)sizeof(uint32_t));
    if (!s)
        return 0;
    int ok = SDL_SavePNG(s, path);
    SDL_DestroySurface(s);
    return ok;
}
/* Parse launcher options, initialise SDL devices, and choose scripted or wall-clock timing. */
int platform_init(int argc, char **argv) {
    pc_metrics_init(getenv("SAM_HOST_METRICS"));
    int headless = 0, audio = 1, script_clock = 0, realtime_script = 0;
    const char *script_path = NULL;
    const char *base = SDL_GetBasePath();
    if (!base) base = "./";
    pc_set_data_dir(base);
    if (snprintf(settings_path, sizeof settings_path, "%ssam.json", base) >= (int)sizeof settings_path)
        return 0;
    /* Find the override before loading so CLI values always take precedence. */
    for (int i = 1; i < argc; ++i)
        if (!strcmp(argv[i], "--settings") && i + 1 < argc) {
            if (strlen(argv[++i]) >= sizeof settings_path) return 0;
            strcpy(settings_path, argv[i]);
        }
    pc_settings_defaults(&presentation);
    if (pc_settings_load(settings_path, &presentation) < 0)
        fprintf(stderr, "Invalid settings in %s; using defaults.\n", settings_path);
    settings_dirty = program_started = 0;
    next_pump=frame_generation=0;native_video=0;
    captured_w=captured_h=0;
    wav_path[0] = 0;
    quit_requested = 0;
    script_cursor = 0;
    repeat_next = UINT64_MAX;
    memset(host_held, 0, sizeof host_held);
    physical_shots = 0;
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "--headless"))
            headless = 1;
        else if (!strcmp(argv[i], "--no-audio"))
            audio = 0;
        else if (!strcmp(argv[i], "--ega"))
            vga_set_adapter(0);
        else if (!strcmp(argv[i], "--vga"))
            vga_set_adapter(1);
        else if (!strcmp(argv[i], "--realtime-script"))
            realtime_script = 1;
        else if (!strcmp(argv[i], "--physical-shots"))
            physical_shots = 1;
        else if (!strcmp(argv[i], "--settings") && i + 1 < argc)
            ++i;
        else if (!strcmp(argv[i], "--fullscreen") || !strcmp(argv[i], "--windowed")) {
            presentation.fullscreen = !strcmp(argv[i], "--fullscreen"); settings_dirty = 1;
        } else if (!strcmp(argv[i], "--smooth") || !strcmp(argv[i], "--no-smooth")) {
            presentation.smooth = !strcmp(argv[i], "--smooth"); settings_dirty = 1;
        } else if (!strcmp(argv[i], "--scaling") && i + 1 < argc) {
            const char *value = argv[++i];
            if (strcmp(value, "integer") && strcmp(value, "fit")) return 0;
            presentation.integer_scale = !strcmp(value, "integer"); settings_dirty = 1;
        } else if (!strcmp(argv[i], "--window-size") && i + 1 < argc) {
            int w, h; char extra;
            if (sscanf(argv[++i], "%dx%d%c", &w, &h, &extra) != 2 ||
                w < 320 || w > 8192 || h < 200 || h > 8192) return 0;
            presentation.window_width = w; presentation.window_height = h; settings_dirty = 1;
        }
        else if (!strcmp(argv[i], "--script") && i + 1 < argc) {
            script_path = argv[++i];
            script_clock = 1;
        } else if (!strcmp(argv[i], "--data") && i + 1 < argc)
            pc_set_data_dir(argv[++i]);
        else if (!strcmp(argv[i], "--wav") && i + 1 < argc) {
            if (strlen(argv[i + 1]) >= sizeof wav_path)
                return 0;
            strcpy(wav_path, argv[++i]);
        } else {
            fprintf(stderr, "unknown option: %s\n", argv[i]);
            return 0;
        }
    }
    if (headless) {
        SDL_SetHint(SDL_HINT_VIDEO_DRIVER, "dummy");
        SDL_SetHint(SDL_HINT_AUDIO_DRIVER, "dummy");
    }
    headless_mode = headless;
    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_GAMEPAD))
        goto fail;
    initialised = 1;
    window = SDL_CreateWindow("Secret Agent", presentation.window_width, presentation.window_height,
                              SDL_WINDOW_RESIZABLE | (headless ? SDL_WINDOW_HIDDEN : 0));
    if (!window)
        goto fail;
    if(pc_metrics_enabled && !headless) {
        const SDL_DisplayMode *mode=SDL_GetCurrentDisplayMode(SDL_GetDisplayForWindow(window));
        if(mode)fprintf(stderr,"Host display: %dx%d %.3f Hz\n",mode->w,mode->h,mode->refresh_rate);
    }
    SDL_SetWindowMinimumSize(window, 320, 200);
    if (!headless && presentation.fullscreen && !SDL_SetWindowFullscreen(window, true)) goto fail;
    deterministic_script = script_clock && !realtime_script;
    if(!headless && !deterministic_script) {
        native_video=pc_video_start(window);
        if(native_video<0)goto fail;
    }
    if(!headless && !native_video) {
        renderer = SDL_CreateRenderer(window, NULL);
        if (!renderer)goto fail;
    }
    if (!speaker_init(audio))
        goto fail;
    if (script_path && !load_script(script_path))
        goto fail;
    deterministic_script = script_clock && !realtime_script;
    pc_clock_manual(deterministic_script);
    int n;
    SDL_JoystickID *ids = SDL_GetJoysticks(&n);
    if (ids && n)
        open_controller(ids[0]);
    SDL_free(ids);
    return 1;
fail:
    fprintf(stderr, "SDL platform: %s\n", SDL_GetError());
    platform_shutdown();
    return 0;
}
/* Save the requested audio capture and release SDL/input/device state. */
void platform_shutdown(void) {
    pc_video_stop();native_video=0;
    vga_diagnostics_close();
    pc_host_wait_shutdown();
    if (initialised && settings_dirty && !pc_settings_save(settings_path, &presentation))
        fprintf(stderr, "Cannot save presentation settings to %s\n", settings_path);
    if (*wav_path && !pc_speaker_capture(wav_path, pc_time_us()))
        fprintf(stderr, "WAV capture failed\n");
    speaker_shutdown();
    pc_dos_reset();
    if (gamepad)
        SDL_CloseGamepad(gamepad);
    gamepad = NULL;
    if (joystick)
        SDL_CloseJoystick(joystick);
    joystick = NULL;
    if (texture)
        SDL_DestroyTexture(texture);
    texture = NULL;
    if (renderer)
        SDL_DestroyRenderer(renderer);
    renderer = NULL;
    if (window)
        SDL_DestroyWindow(window);
    window = NULL;
    free(script);
    script = NULL;
    script_count = script_cursor = 0;
    initialised = 0;
    pc_metrics_shutdown();
    SDL_Quit();
}
