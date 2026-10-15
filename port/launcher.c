/* Host episode selection. Each generated entry performs a complete DOS load. */
#include "pc/platform.h"
#include "pc/settings.h"
#include "lib/samlib.h"
#include <SDL3/SDL.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

void s1_run(void);
void s2_run(void);
void s3_run(void);
static int present[4], selection, menu_result;

static int episode_present(int episode) {
    /* CFG is optional and game-owned; the old DOS EXE is not needed. Require
       every shipped runtime resource, rather than recognizing a lone title. */
    const char *patterns[] = {"SAM%d.APO", "SAM%d.TTL", "SAM%d.CRD",
        "SAM%d01.GFX", "SAM%d02.GFX", "SAM%d03.GFX",
        "SAM%d01E.SND", "SAM%d02E.SND", "SAM%d03E.SND",
        episode == 3 ? "SAM%dA.END" : "SAM%d.END", "SAM%dB.END"};
    size_t count = episode == 3 ? 11 : 10;
    for (size_t i = 0; i < count; ++i) {
        char name[32]; snprintf(name, sizeof name, patterns[i], episode);
        FILE *f = pc_fopen(name, "rb");
        if (!f) return 0;
        fclose(f);
    }
    return 1;
}
static void missing_data(void) {
    const char *message =
        "Required episode files were not found. Put your original episode files beside sam.exe, "
        "or select their folder with --data DIR. The DOS EXE is not required.\n\n"
        "For episode N (1, 2 or 3):\n"
        "SAMN.APO, SAMN.TTL, SAMN.CRD\n"
        "SAMN01.GFX, SAMN02.GFX, SAMN03.GFX\n"
        "SAMN01E.SND, SAMN02E.SND, SAMN03E.SND\n"
        "SAMN.END (episodes 1 and 2), or SAM3A.END and SAM3B.END (episode 3).\n\n"
        "SAMN.CFG and save files remain managed by the game.";
    fprintf(stderr, "%s\nData directory: %s\n", message, pc_data_dir());
    (void)SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Secret Agent episode files", message, NULL);
}
static void text(unsigned x, unsigned y, uint8_t attribute, const char *s) {
    while (*s && x < 80) {
        pc_wr16(PC_VIDEO_TEXT_SEGMENT, (uint16_t)(2 * (y * 80 + x)),
                (uint16_t)((attribute << 8) | (unsigned char)*s++));
        ++x;
    }
}
static void cell(unsigned x, unsigned y, uint8_t ch) {
    pc_wr16(PC_VIDEO_TEXT_SEGMENT, (uint16_t)(2 * (y * 80 + x)), (uint16_t)(0x1b00 | ch));
}
static void frame(const char *title) {
    for (unsigned i = 0; i < 2000; ++i)
        pc_wr16(PC_VIDEO_TEXT_SEGMENT, (uint16_t)(2 * i), 0x1720);
    for (unsigned x = 5; x < 75; ++x) { cell(x, 3, 205); cell(x, 21, 205); }
    for (unsigned y = 4; y < 21; ++y) { cell(4, y, 186); cell(75, y, 186); }
    cell(4,3,201); cell(75,3,187); cell(4,21,200); cell(75,21,188);
    text(29, 5, 0x1e, "S E C R E T  A G E N T");
    text(8, 7, 0x1f, title);
    text(8, 20, 0x1b, "Alt+Enter / F11: Fullscreen");
    /* Hide the DOS cursor while the chooser owns text mode. */
    pc_regs r = {0}; r.ax = 0x0100; r.cx = 0x2000; pc_bios_int(PC_INT_VIDEO, &r);
}
static uint16_t read_key(void) {
    pc_regs r = {0}; pc_bios_int(PC_INT_KEYBOARD_BIOS, &r); return r.ax;
}
static void settings_dialog(void) {
    for (;;) {
        const pc_settings *s = platform_settings();
        char line[100];
        frame("PORT PRESENTATION");
        snprintf(line, sizeof line, "F  Fullscreen       %s", s->fullscreen ? "On" : "Off");
        text(12, 9, 0x1f, line);
        snprintf(line, sizeof line, "I  Scaling          %s", s->integer_scale ? "Integer, aspect corrected" : "Fit, aspect corrected");
        text(12, 11, 0x1f, line);
        snprintf(line, sizeof line, "M  Smooth filter    %s", s->smooth ? "On" : "Off");
        text(12, 13, 0x1f, line);
        snprintf(line, sizeof line, "B  Overscan border  %s", s->border ? "On" : "Off (cropped)");
        text(12, 15, 0x1f, line);
        snprintf(line, sizeof line, "W  Window size      %d x %d", s->window_width, s->window_height);
        text(12, 17, 0x1f, line);
        text(12, 19, 0x1e, "Esc: Back     Changes are saved in sam.json");
        platform_present();
        int key = read_key() & 255;
        if (key == 27) return;
        pc_settings next = *platform_settings();
        if (key == 'f' || key == 'F') next.fullscreen = !next.fullscreen;
        else if (key == 'i' || key == 'I') next.integer_scale = !next.integer_scale;
        else if (key == 'm' || key == 'M') next.smooth = !next.smooth;
        else if (key == 'b' || key == 'B') next.border = !next.border;
        else if (key == 'w' || key == 'W') {
            const int sizes[][2] = {{640,480},{960,720},{1280,960}};
            unsigned i;
            for (i = 0; i < 3 && sizes[i][0] != next.window_width; ++i) {}
            i = i < 3 ? (i + 1) % 3 : 0;
            next.window_width = sizes[i][0]; next.window_height = sizes[i][1];
        } else continue;
        if (!platform_apply_settings(&next))
            fprintf(stderr, "presentation: %s\n", SDL_GetError());
    }
}
static void episode_dialog(void) {
    const pc_program menu = {PC_PSP_SEG, 0x4000, 0x6000, 0x4000, 0x6400, 0xa000};
    pc_load_program(&menu, NULL, 0);
    menu_result = 0;
    printf("LAUNCHER episodes=%s%s%s\n", present[1] ? "1" : "", present[2] ? "2" : "", present[3] ? "3" : "");
    for (;;) {
        frame("SELECT A MISSION");
        const char *labels[] = {"", "1   MISSION ONE", "2   MISSION TWO", "3   MISSION THREE"};
        for (int i = 1; i <= 3; ++i) {
            text(14, (unsigned)(8 + 2 * i), present[i] ? (selection == i ? 0x4f : 0x1f) : 0x18, labels[i]);
            if (!present[i]) text(43, (unsigned)(8 + 2 * i), 0x18, "Files not found");
        }
        text(14, 16, 0x1f, "S   Port presentation settings");
        text(14, 18, 0x1e, "Arrows + Enter / 1-3: Start     Esc: Quit");
        platform_present();
        uint16_t key = read_key(); unsigned ch = key & 255, scan = key >> 8;
        if (ch == 27) return;
        if (ch == 's' || ch == 'S') { settings_dialog(); continue; }
        if (ch >= '1' && ch <= '3' && present[ch - '0']) {
            menu_result = (int)ch - '0'; return;
        }
        if (ch == 13) { menu_result = selection; return; }
        if (scan == 0x48 || scan == 0x50) {
            do { selection = (selection + (scan == 0x48 ? 1 : 0)) % 3 + 1; }
            while (!present[selection]);
        }
    }
}
int main(int argc, char **argv) {
#ifdef _WIN32
    SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX);
#endif
    int episode = 0;
    char **platform_argv = calloc((size_t)argc + 1, sizeof *platform_argv);
    if (!platform_argv) return 2;
    int n = 0; platform_argv[n++] = argv[0];
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "--episode")) {
            if (i + 1 == argc || strlen(argv[i + 1]) != 1 || argv[i + 1][0] < '1' || argv[i + 1][0] > '3') {
                fputs("--episode requires 1, 2 or 3.\n", stderr); free(platform_argv); return 2;
            }
            episode = argv[++i][0] - '0';
        } else platform_argv[n++] = argv[i];
    }
    if (!platform_init(n, platform_argv)) { free(platform_argv); return 2; }
    int available = 0;
    for (int i = 1; i <= 3; ++i) {
        present[i] = episode_present(i);
        if (present[i]) { ++available; if (!selection) selection = i; }
    }
    if (!available || (episode && !present[episode])) {
        missing_data(); platform_shutdown(); free(platform_argv); return 2;
    }
    int direct = episode != 0, status = 0;
    if (!direct && available == 1) episode = selection;
    const pc_code_fn episodes[] = {s1_run, s2_run, s3_run};
    for (;;) {
        if (!episode) {
            platform_run(episode_dialog);
            if (platform_quit_requested() || !menu_result) break;
            episode = menu_result;
        }
        if (!direct) printf("LAUNCH episode=%d\n", episode);
        samlib_reset();
        status = platform_run(episodes[episode - 1]);
        printf("SAM%d exit=%d time_us=%llu irq0=%llu irq1=%llu\n", episode, status,
               (unsigned long long)pc_time_us(), (unsigned long long)pc_irq_count(8),
               (unsigned long long)pc_irq_count(9));
        if (direct || platform_quit_requested()) break;
        selection = episode; episode = 0;
    }
    platform_shutdown(); free(platform_argv); return status;
}
