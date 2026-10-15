#ifndef SAM_SETTINGS_H
#define SAM_SETTINGS_H
/* Host presentation only; none of these values enter Pascal memory or SAMn.CFG. */
typedef struct {
    int fullscreen, integer_scale, smooth;
    int window_width, window_height;
    int border; /* show CRT overscan; default cropped */
} pc_settings;
void pc_settings_defaults(pc_settings *settings);
int pc_settings_load(const char *path, pc_settings *settings);
int pc_settings_save(const char *path, const pc_settings *settings);
const pc_settings *platform_settings(void);
int platform_apply_settings(const pc_settings *settings);
const char *platform_settings_path(void);
#endif
