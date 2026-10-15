/* Small, versioned JSON file for the host window; the DOS game owns its config. */
#include "settings.h"
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void pc_settings_defaults(pc_settings *s) {
    *s = (pc_settings){0, 1, 0, 960, 720, 0};
}
static void space(const char **p) {
    while (isspace((unsigned char)**p)) ++*p;
}
static int string(const char **p, char *out, size_t size) {
    space(p);
    if (*(*p)++ != '"') return 0;
    size_t n = 0;
    while (**p && **p != '"') {
        unsigned char c = (unsigned char)*(*p)++;
        if (c < 32 || c == '\\' || n + 1 >= size) return 0;
        out[n++] = (char)c;
    }
    if (**p != '"') return 0;
    ++*p; out[n] = 0; return 1;
}
static int boolean(const char *v, int *out) {
    if (!strcmp(v, "true")) *out = 1;
    else if (!strcmp(v, "false")) *out = 0;
    else return 0;
    return 1;
}
static int dimension(const char *v, int minimum, int *out) {
    char *end;
    long n = strtol(v, &end, 10);
    if (!*v || *end || n < minimum || n > 8192) return 0;
    *out = (int)n; return 1;
}
int pc_settings_load(const char *path, pc_settings *settings) {
    FILE *f = fopen(path, "rb");
    if (!f) return 0;
    char data[4096]; size_t n = fread(data, 1, sizeof data - 1, f);
    int complete = !ferror(f) && feof(f); fclose(f);
    if (!complete) return -1;
    data[n] = 0;
    const char *p = data; pc_settings s = *settings;
    space(&p); if (*p++ != '{') return -1;
    space(&p);
    while (*p != '}') {
        char key[64], value[64];
        if (!string(&p, key, sizeof key)) return -1;
        space(&p); if (*p++ != ':') return -1;
        space(&p);
        int quoted = *p == '"';
        if (quoted) {
            if (!string(&p, value, sizeof value)) return -1;
        } else {
            size_t count = 0;
            while (*p && *p != ',' && *p != '}' && !isspace((unsigned char)*p)) {
                if (count + 1 >= sizeof value) return -1;
                value[count++] = *p++;
            }
            value[count] = 0;
            if (!count) return -1;
        }
        if (!strcmp(key, "version")) {
            if (quoted || strcmp(value, "1")) return -1;
        } else if (!strcmp(key, "fullscreen")) {
            if (quoted || !boolean(value, &s.fullscreen)) return -1;
        } else if (!strcmp(key, "border")) {
            if (quoted || !boolean(value, &s.border)) return -1;
        } else if (!strcmp(key, "smooth")) {
            if (quoted || !boolean(value, &s.smooth)) return -1;
        } else if (!strcmp(key, "scaling")) {
            if (!quoted) return -1;
            if (!strcmp(value, "integer")) s.integer_scale = 1;
            else if (!strcmp(value, "fit")) s.integer_scale = 0;
            else return -1;
        } else if (!strcmp(key, "window_width")) {
            if (quoted || !dimension(value, 320, &s.window_width)) return -1;
        } else if (!strcmp(key, "window_height")) {
            if (quoted || !dimension(value, 200, &s.window_height)) return -1;
        } else if (!quoted) {
            /* Unknown scalar fields are allowed for forward-compatible additions. */
            char *end; (void)strtod(value, &end);
            if (*end && strcmp(value,"true") && strcmp(value,"false") && strcmp(value,"null"))
                return -1;
        }
        space(&p);
        if (*p == '}') break;
        if (*p++ != ',') return -1;
        space(&p); if (*p == '}') return -1;
    }
    ++p; space(&p); if (*p) return -1;
    *settings = s; return 1;
}
int pc_settings_save(const char *path, const pc_settings *s) {
    FILE *f = fopen(path, "w");
    if (!f) return 0;
    int ok = fprintf(f, "{\n  \"version\": 1,\n  \"fullscreen\": %s,\n"
                     "  \"scaling\": \"%s\",\n  \"smooth\": %s,\n"
                     "  \"window_width\": %d,\n  \"window_height\": %d,\n  \"border\": %s\n}\n",
                     s->fullscreen ? "true" : "false", s->integer_scale ? "integer" : "fit",
                     s->smooth ? "true" : "false", s->window_width, s->window_height, s->border ? "true" : "false") > 0;
    if (fclose(f)) ok = 0;
    return ok;
}
