#ifndef SAM_HOST_VIDEO_H
#define SAM_HOST_VIDEO_H
#include <SDL3/SDL.h>
#include "settings.h"
/* Windows presenter owns its D3D device on a separate thread. The SDL window
   and all event operations remain on the main/emulation thread. */
int pc_video_start(SDL_Window *window);
void pc_video_submit(const uint32_t *pixels,int w,int h,uint32_t border,uint64_t generation,
                     const pc_settings *settings);
void pc_video_stop(void);
void pc_video_redraw(void);
#endif
