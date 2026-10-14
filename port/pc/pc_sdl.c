#include "pc_internal.h"
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

static SDL_Window *window;
static SDL_Renderer *renderer;
static SDL_Texture *texture;
static SDL_Gamepad *gamepad;
static SDL_Joystick *joystick;
static int texture_w,texture_h,quit_requested,initialised,deterministic_script,physical_shots;
static uint32_t pixels[720*480];
static char wav_path[1024];
enum action { DOWN,UP,SHOT,QUIT };
typedef struct { uint64_t us; unsigned order; enum action action; uint16_t scan; char path[1024]; } script_event;
static script_event *script;
static size_t script_count,script_cursor;
static uint16_t repeat_scan;
static uint64_t repeat_next=UINT64_MAX,repeat_number,repeat_origin;
static uint8_t host_held[SDL_SCANCODE_COUNT];

static uint16_t xt(SDL_Scancode s)
{
    static const uint8_t letters[26]={0x1e,0x30,0x2e,0x20,0x12,0x21,0x22,0x23,0x17,0x24,0x25,0x26,0x32,0x31,0x18,0x19,0x10,0x13,0x1f,0x14,0x16,0x2f,0x11,0x2d,0x15,0x2c};
    if(s>=SDL_SCANCODE_A && s<=SDL_SCANCODE_Z) return letters[s-SDL_SCANCODE_A];
    if(s>=SDL_SCANCODE_1 && s<=SDL_SCANCODE_9) return (uint16_t)(2+s-SDL_SCANCODE_1);
    if(s>=SDL_SCANCODE_F1 && s<=SDL_SCANCODE_F10) return (uint16_t)(0x3b+s-SDL_SCANCODE_F1);
    switch(s) {
    case SDL_SCANCODE_0:return 0x0b; case SDL_SCANCODE_ESCAPE:return 1;
    case SDL_SCANCODE_MINUS:return 0x0c; case SDL_SCANCODE_EQUALS:return 0x0d;
    case SDL_SCANCODE_BACKSPACE:return 0x0e; case SDL_SCANCODE_TAB:return 0x0f;
    case SDL_SCANCODE_LEFTBRACKET:return 0x1a; case SDL_SCANCODE_RIGHTBRACKET:return 0x1b;
    case SDL_SCANCODE_RETURN:return 0x1c; case SDL_SCANCODE_LCTRL:return 0x1d;
    case SDL_SCANCODE_SEMICOLON:return 0x27; case SDL_SCANCODE_APOSTROPHE:return 0x28;
    case SDL_SCANCODE_GRAVE:return 0x29; case SDL_SCANCODE_LSHIFT:return 0x2a;
    case SDL_SCANCODE_BACKSLASH:return 0x2b; case SDL_SCANCODE_COMMA:return 0x33;
    case SDL_SCANCODE_PERIOD:return 0x34; case SDL_SCANCODE_SLASH:return 0x35;
    case SDL_SCANCODE_RSHIFT:return 0x36; case SDL_SCANCODE_KP_MULTIPLY:return 0x37;
    case SDL_SCANCODE_LALT:return 0x38; case SDL_SCANCODE_SPACE:return 0x39;
    case SDL_SCANCODE_CAPSLOCK:return 0x3a; case SDL_SCANCODE_NUMLOCKCLEAR:return 0x45;
    case SDL_SCANCODE_SCROLLLOCK:return 0x46;
    case SDL_SCANCODE_KP_7:return 0x47; case SDL_SCANCODE_KP_8:return 0x48;
    case SDL_SCANCODE_KP_9:return 0x49; case SDL_SCANCODE_KP_MINUS:return 0x4a;
    case SDL_SCANCODE_KP_4:return 0x4b; case SDL_SCANCODE_KP_5:return 0x4c;
    case SDL_SCANCODE_KP_6:return 0x4d; case SDL_SCANCODE_KP_PLUS:return 0x4e;
    case SDL_SCANCODE_KP_1:return 0x4f; case SDL_SCANCODE_KP_2:return 0x50;
    case SDL_SCANCODE_KP_3:return 0x51; case SDL_SCANCODE_KP_0:return 0x52;
    case SDL_SCANCODE_KP_PERIOD:return 0x53; case SDL_SCANCODE_NONUSBACKSLASH:return 0x56;
    case SDL_SCANCODE_F11:return 0x57; case SDL_SCANCODE_F12:return 0x58;
    case SDL_SCANCODE_HOME:return 0xe047; case SDL_SCANCODE_UP:return 0xe048;
    case SDL_SCANCODE_PAGEUP:return 0xe049; case SDL_SCANCODE_LEFT:return 0xe04b;
    case SDL_SCANCODE_RIGHT:return 0xe04d; case SDL_SCANCODE_END:return 0xe04f;
    case SDL_SCANCODE_DOWN:return 0xe050; case SDL_SCANCODE_PAGEDOWN:return 0xe051;
    case SDL_SCANCODE_INSERT:return 0xe052; case SDL_SCANCODE_DELETE:return 0xe053;
    case SDL_SCANCODE_KP_ENTER:return 0xe01c; case SDL_SCANCODE_KP_DIVIDE:return 0xe035;
    case SDL_SCANCODE_RCTRL:return 0xe01d; case SDL_SCANCODE_RALT:return 0xe038;
    default:return 0;
    }
}
static uint16_t named_scan(const char *name)
{
    if(!SDL_strcasecmp(name,"esc")) return 1;
    if(!SDL_strcasecmp(name,"enter")) return 0x1c;
    if(!SDL_strcasecmp(name,"ctrl")||!SDL_strcasecmp(name,"lctrl")) return 0x1d;
    if(!SDL_strcasecmp(name,"rctrl")) return 0xe01d;
    if(!SDL_strcasecmp(name,"alt")||!SDL_strcasecmp(name,"lalt")) return 0x38;
    if(!SDL_strcasecmp(name,"ralt")) return 0xe038;
    if(!SDL_strcasecmp(name,"shift")) return 0x2a;
    return xt(SDL_GetScancodeFromName(name));
}
static void send_key(uint64_t us,uint16_t scan,int down)
{
    pc_queue_key(us,scan,down);
    unsigned s=scan&127;
    if(down && s!=0x1d && s!=0x38 && s!=0x2a && s!=0x36 && s!=0x3a && s!=0x45 && s!=0x46) {
        repeat_scan=scan; repeat_origin=us+500000; repeat_number=0; repeat_next=repeat_origin;
    } else if(!down && scan==repeat_scan) repeat_next=UINT64_MAX;
}
static int compare_event(const void *aa,const void *bb)
{
    const script_event *a=aa,*b=bb;
    if(a->us!=b->us) return a->us<b->us ? -1 : 1;
    return a->order<b->order ? -1 : a->order>b->order;
}
static int append_event(script_event e)
{
    if(script_count>=8192) return 0;
    script_event *p=realloc(script,(script_count+1)*sizeof *script);
    if(!p) return 0;
    script=p; script[script_count++]=e; return 1;
}
static int load_script(const char *path)
{
    FILE *f=fopen(path,"r"); if(!f) return 0;
    char line[2048]; unsigned order=0,line_num=0;
    while(fgets(line,sizeof line,f)) {
        ++line_num; char *p=line; while(isspace((unsigned char)*p)) ++p;
        if(!*p || *p=='#') continue;
        unsigned long long ms; char command[32],arg[1024]="";
        if(sscanf(p,"%llu %31s %1023s",&ms,command,arg)<2) goto bad;
        script_event e={0}; e.us=(uint64_t)ms*1000; e.order=order++;
        if(!SDL_strcasecmp(command,"quit")) e.action=QUIT;
        else if(!SDL_strcasecmp(command,"shot")) {
            e.action=SHOT; if(!*arg) goto bad;
            const char *slash=strrchr(path,'/'),*back=strrchr(path,'\\');
            if(!slash || (back&&back>slash)) slash=back;
            size_t n=slash ? (size_t)(slash-path+1) : 0;
            if(arg[0]=='/' || arg[0]=='\\' || (strlen(arg)>1&&arg[1]==':')) n=0;
            if(n+strlen(arg)>=sizeof e.path) goto bad;
            memcpy(e.path,path,n); strcpy(e.path+n,arg);
        } else if(!SDL_strcasecmp(command,"key") || !SDL_strcasecmp(command,"keydown") || !SDL_strcasecmp(command,"keyup")) {
            e.scan=named_scan(arg); if(!e.scan) goto bad;
            e.action=!SDL_strcasecmp(command,"keyup") ? UP : DOWN;
            if(!SDL_strcasecmp(command,"key")) {
                if(!append_event(e)) goto bad;
                e.action=UP; e.us+=45000; e.order=order++;
            }
        } else goto bad;
        if(!append_event(e)) goto bad;
    }
    fclose(f); qsort(script,script_count,sizeof *script,compare_event); return 1;
bad:
    fprintf(stderr,"invalid script %s:%u\n",path,line_num); fclose(f); return 0;
}
uint64_t pc_script_next(void)
{
    uint64_t t=script_cursor<script_count ? script[script_cursor].us : UINT64_MAX;
    return repeat_next<t ? repeat_next : t;
}
void pc_script_dispatch(uint64_t now)
{
    if(script_cursor<script_count && script[script_cursor].us<=now) {
        script_event *e=&script[script_cursor++];
        switch(e->action) {
        case DOWN: case UP:send_key(e->us,e->scan,e->action==DOWN); break;
        case SHOT:if(!platform_screenshot(e->path)) { fprintf(stderr,"screenshot failed: %s\n",SDL_GetError()); abort(); } break;
        case QUIT:pc_request_quit(); break;
        }
    } else if(repeat_next<=now) {
        pc_queue_key(repeat_next,repeat_scan,1);
        ++repeat_number; repeat_next=repeat_origin+(repeat_number*1000000u)/30u;
    }
}
void pc_request_quit(void) { quit_requested=1; }
int platform_quit_requested(void) { return quit_requested; }
static void open_controller(SDL_JoystickID id)
{
    if(gamepad||joystick) return;
    if(SDL_IsGamepad(id)) gamepad=SDL_OpenGamepad(id);
    else joystick=SDL_OpenJoystick(id);
}
void pc_host_pump(void)
{
    if(!initialised) return;
    SDL_Event e;
    while(SDL_PollEvent(&e)) {
        uint64_t now=pc_time_us();
        if(e.type==SDL_EVENT_QUIT) quit_requested=1;
        else if(e.type==SDL_EVENT_KEY_DOWN || e.type==SDL_EVENT_KEY_UP) {
            if(deterministic_script) continue;
            SDL_Scancode s=e.key.scancode; uint16_t scan=xt(s);
            int down=e.type==SDL_EVENT_KEY_DOWN;
            if(scan&&!e.key.repeat&&host_held[s]!=down) { host_held[s]=(uint8_t)down; send_key(now,scan,down); }
        } else if(e.type==SDL_EVENT_WINDOW_FOCUS_LOST) {
            for(unsigned s=0;s<SDL_SCANCODE_COUNT;++s) if(host_held[s]) { send_key(now,xt((SDL_Scancode)s),0); host_held[s]=0; }
        } else if(e.type==SDL_EVENT_JOYSTICK_ADDED) open_controller(e.jdevice.which);
        else if(e.type==SDL_EVENT_JOYSTICK_REMOVED) {
            if(gamepad && SDL_GetGamepadID(gamepad)==e.jdevice.which) { SDL_CloseGamepad(gamepad); gamepad=NULL; }
            if(joystick && SDL_GetJoystickID(joystick)==e.jdevice.which) { SDL_CloseJoystick(joystick); joystick=NULL; }
            pc_joystick_set(0,NULL,0);
        }
    }
    if(!deterministic_script && (gamepad||joystick)) {
        int16_t axes[4]={0}; uint8_t buttons=0;
        if(gamepad) {
            axes[0]=SDL_GetGamepadAxis(gamepad,SDL_GAMEPAD_AXIS_LEFTX);
            axes[1]=SDL_GetGamepadAxis(gamepad,SDL_GAMEPAD_AXIS_LEFTY);
            if(SDL_GetGamepadButton(gamepad,SDL_GAMEPAD_BUTTON_DPAD_LEFT)) axes[0]=-32768;
            if(SDL_GetGamepadButton(gamepad,SDL_GAMEPAD_BUTTON_DPAD_RIGHT)) axes[0]=32767;
            if(SDL_GetGamepadButton(gamepad,SDL_GAMEPAD_BUTTON_DPAD_UP)) axes[1]=-32768;
            if(SDL_GetGamepadButton(gamepad,SDL_GAMEPAD_BUTTON_DPAD_DOWN)) axes[1]=32767;
            buttons=(uint8_t)((SDL_GetGamepadButton(gamepad,SDL_GAMEPAD_BUTTON_SOUTH)?1:0)|(SDL_GetGamepadButton(gamepad,SDL_GAMEPAD_BUTTON_WEST)?2:0));
        } else {
            int n=SDL_GetNumJoystickAxes(joystick);
            for(unsigned a=0;a<4&&a<(unsigned)n;++a) axes[a]=SDL_GetJoystickAxis(joystick,(int)a);
            for(unsigned b=0;b<4&&b<(unsigned)SDL_GetNumJoystickButtons(joystick);++b) if(SDL_GetJoystickButton(joystick,(int)b)) buttons|=(uint8_t)(1u<<b);
        }
        pc_joystick_set(1,axes,buttons);
    }
}
void platform_present(void)
{
    if(!renderer) return;
    int w,h; vga_scanout_dimensions(&w,&h); vga_render_scanout_rgb(pixels);
    if(!texture || texture_w!=w || texture_h!=h) {
        if(texture) SDL_DestroyTexture(texture);
        texture=SDL_CreateTexture(renderer,SDL_PIXELFORMAT_ARGB8888,SDL_TEXTUREACCESS_STREAMING,w,h);
        if(!texture) { fprintf(stderr,"texture: %s\n",SDL_GetError()); abort(); }
        texture_w=w; texture_h=h; SDL_SetTextureScaleMode(texture,SDL_SCALEMODE_NEAREST);
    }
    int beam_w=w==320 ? 320 : 640,beam_h=w==320 ? 240 : 480;
    int border_w=beam_w/40,border_h=beam_h/40;
    int canvas_w=beam_w+2*border_w,canvas_h=beam_h+2*border_h;
    SDL_SetRenderLogicalPresentation(renderer,canvas_w,canvas_h,SDL_LOGICAL_PRESENTATION_INTEGER_SCALE);
    SDL_UpdateTexture(texture,NULL,pixels,w*(int)sizeof(uint32_t));
    uint32_t border=vga_border_rgb(); SDL_SetRenderDrawColor(renderer,(uint8_t)(border>>16),(uint8_t)(border>>8),(uint8_t)border,255);
    SDL_RenderClear(renderer);
    SDL_FRect dest={(float)border_w,(float)border_h,(float)beam_w,(float)beam_h};
    SDL_RenderTexture(renderer,texture,NULL,&dest); SDL_RenderPresent(renderer);
}
int platform_screenshot(const char *path)
{
    int w,h;
    if(physical_shots) { vga_scanout_dimensions(&w,&h); vga_render_scanout_rgb(pixels); }
    else { vga_dimensions(&w,&h); vga_render_rgb(pixels); }
    SDL_Surface *s=SDL_CreateSurfaceFrom(w,h,SDL_PIXELFORMAT_ARGB8888,pixels,w*(int)sizeof(uint32_t));
    if(!s) return 0;
    int ok=SDL_SavePNG(s,path); SDL_DestroySurface(s); return ok;
}
int platform_init(int argc,char **argv)
{
    int headless=0,audio=1,script_clock=0,realtime_script=0;
    const char *script_path=NULL;
    quit_requested=0; script_cursor=0; repeat_next=UINT64_MAX; memset(host_held,0,sizeof host_held);
    physical_shots=0;
    for(int i=1;i<argc;++i) {
        if(!strcmp(argv[i],"--headless")) headless=1;
        else if(!strcmp(argv[i],"--no-audio")) audio=0;
        else if(!strcmp(argv[i],"--ega")) vga_set_adapter(0);
        else if(!strcmp(argv[i],"--vga")) vga_set_adapter(1);
        else if(!strcmp(argv[i],"--realtime-script")) realtime_script=1;
        else if(!strcmp(argv[i],"--physical-shots")) physical_shots=1;
        else if(!strcmp(argv[i],"--script")&&i+1<argc) { script_path=argv[++i]; script_clock=1; }
        else if(!strcmp(argv[i],"--data")&&i+1<argc) pc_set_data_dir(argv[++i]);
        else if(!strcmp(argv[i],"--wav")&&i+1<argc) { if(strlen(argv[i+1])>=sizeof wav_path) return 0; strcpy(wav_path,argv[++i]); }
        else { fprintf(stderr,"unknown option: %s\n",argv[i]); return 0; }
    }
    if(headless) { SDL_SetHint(SDL_HINT_VIDEO_DRIVER,"dummy"); SDL_SetHint(SDL_HINT_AUDIO_DRIVER,"dummy"); }
    if(!SDL_Init(SDL_INIT_VIDEO|SDL_INIT_AUDIO|SDL_INIT_GAMEPAD)) goto fail;
    initialised=1;
    window=SDL_CreateWindow("Secret Agent platform",960,720,SDL_WINDOW_RESIZABLE|(headless ? SDL_WINDOW_HIDDEN : 0));
    if(!window) goto fail;
    renderer=SDL_CreateRenderer(window,NULL); if(!renderer) goto fail;
    if(!speaker_init(audio)) goto fail;
    if(script_path&&!load_script(script_path)) goto fail;
    deterministic_script=script_clock&&!realtime_script;
    pc_clock_manual(deterministic_script);
    int n; SDL_JoystickID *ids=SDL_GetJoysticks(&n);
    if(ids && n) open_controller(ids[0]);
    SDL_free(ids);
    return 1;
fail:
    fprintf(stderr,"SDL platform: %s\n",SDL_GetError()); platform_shutdown(); return 0;
}
void platform_shutdown(void)
{
    if(*wav_path && !pc_speaker_capture(wav_path,pc_time_us())) fprintf(stderr,"WAV capture failed\n");
    speaker_shutdown(); pc_dos_reset();
    if(gamepad) SDL_CloseGamepad(gamepad);
    gamepad=NULL;
    if(joystick) SDL_CloseJoystick(joystick);
    joystick=NULL;
    if(texture) SDL_DestroyTexture(texture);
    texture=NULL;
    if(renderer) SDL_DestroyRenderer(renderer);
    renderer=NULL;
    if(window) SDL_DestroyWindow(window);
    window=NULL;
    free(script); script=NULL; script_count=script_cursor=0;
    initialised=0; SDL_Quit();
}
