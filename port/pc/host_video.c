/* A latest-frame mailbox isolates emulation/input from Windows vsync waits.
   No SDL renderer calls are made from this worker (SDL requires the main thread).
   Only the presenter thread owns/uses the D3D11 context and flip swap chain. */
#include "host_video.h"
#include "host_metrics.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#ifdef _WIN32
#define COBJMACROS
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d11.h>
#include <dxgi1_3.h>
#include <d3dcompiler.h>
#include <stdatomic.h>

typedef struct {
    uint32_t pixels[720*480];
    int w,h;
    uint32_t border;
    uint64_t generation;
    pc_settings settings;
} video_frame;
static video_frame mailbox;
static SDL_Mutex *mail_mutex;
static SDL_Thread *thread;
static HANDLE stop_event,frame_event,done_event;
static HWND target;
static atomic_int ready;
static HRESULT failure;
static const char shader[] =
    "cbuffer C : register(b0) { float4 imageRect; float4 canvasRect; float4 border; };"
    "Texture2D picture : register(t0); SamplerState sampleMode : register(s0);"
    "struct V { float4 pos:SV_Position; float2 uv:TEXCOORD0; };"
    "V vs(uint id:SV_VertexID) { V o; float2 p=float2((id<<1)&2,id&2);"
    "o.pos=float4(p*float2(2,-2)+float2(-1,1),0,1);o.uv=p;return o; }"
    "float4 ps(V v):SV_Target { float2 p=v.uv;"
    "if(any(p<canvasRect.xy)||any(p>=canvasRect.xy+canvasRect.zw))return float4(0,0,0,1);"
    "if(any(p<imageRect.xy)||any(p>=imageRect.xy+imageRect.zw))return border;"
    "return picture.Sample(sampleMode,(p-imageRect.xy)/imageRect.zw); }";

#define RELEASE(p) do { if(p) { IUnknown_Release((IUnknown *)(p)); (p)=NULL; } } while(0)
#define TRY(call) do { failure=(call); if(FAILED(failure)) goto cleanup; } while(0)
static int SDLCALL present_thread(void *unused) {
    (void)unused;
    ID3D11Device *device=NULL;
    ID3D11DeviceContext *context=NULL;
    IDXGISwapChain *swap=NULL;
    IDXGISwapChain2 *swap2=NULL;
    ID3D11RenderTargetView *rt=NULL;
    ID3D11Texture2D *image=NULL,*back=NULL;
    ID3D11ShaderResourceView *view=NULL;
    ID3D11VertexShader *vs=NULL;
    ID3D11PixelShader *ps=NULL;
    ID3D11Buffer *constants=NULL;
    ID3D11SamplerState *point=NULL,*linear=NULL;
    ID3DBlob *code=NULL,*errors=NULL;
    HANDLE latency=NULL;
    video_frame *frame=SDL_calloc(1,sizeof *frame);
    int tw=0,th=0,cw=0,ch=0;
    uint64_t uploaded=UINT64_MAX;
    const char *capture=getenv("SAM_HOST_CAPTURE");
    const char *delay_option=getenv("SAM_HOST_PRESENT_DELAY_MS");
    unsigned delay_ms=delay_option ? (unsigned)strtoul(delay_option,NULL,10) : 0;
    if(delay_ms>1000)delay_ms=1000;
    uint64_t started=SDL_GetTicksNS();
    if(!frame) { failure=E_OUTOFMEMORY;goto cleanup; }
    DXGI_SWAP_CHAIN_DESC desc={0};
    desc.BufferDesc.Format=DXGI_FORMAT_B8G8R8A8_UNORM;
    desc.SampleDesc.Count=1;desc.BufferUsage=DXGI_USAGE_RENDER_TARGET_OUTPUT;
    desc.BufferCount=2;desc.OutputWindow=target;desc.Windowed=TRUE;
    desc.SwapEffect=DXGI_SWAP_EFFECT_FLIP_DISCARD;
    desc.Flags=DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT;
    D3D_FEATURE_LEVEL level=D3D_FEATURE_LEVEL_11_0;
    TRY(D3D11CreateDeviceAndSwapChain(NULL,D3D_DRIVER_TYPE_HARDWARE,NULL,
        D3D11_CREATE_DEVICE_BGRA_SUPPORT|D3D11_CREATE_DEVICE_SINGLETHREADED,
        &level,1,D3D11_SDK_VERSION,&desc,&swap,&device,NULL,&context));
    TRY(IDXGISwapChain_QueryInterface(swap,&IID_IDXGISwapChain2,(void **)&swap2));
    TRY(IDXGISwapChain2_SetMaximumFrameLatency(swap2,1));
    latency=IDXGISwapChain2_GetFrameLatencyWaitableObject(swap2);
    if(!latency) {failure=E_FAIL;goto cleanup;}
    TRY(D3DCompile(shader,sizeof shader-1,NULL,NULL,NULL,"vs","vs_4_0",0,0,&code,&errors));
    TRY(ID3D11Device_CreateVertexShader(device,ID3D10Blob_GetBufferPointer(code),ID3D10Blob_GetBufferSize(code),NULL,&vs));
    RELEASE(code);RELEASE(errors);
    TRY(D3DCompile(shader,sizeof shader-1,NULL,NULL,NULL,"ps","ps_4_0",0,0,&code,&errors));
    TRY(ID3D11Device_CreatePixelShader(device,ID3D10Blob_GetBufferPointer(code),ID3D10Blob_GetBufferSize(code),NULL,&ps));
    RELEASE(code);RELEASE(errors);
    D3D11_BUFFER_DESC cb={0};cb.ByteWidth=48;cb.Usage=D3D11_USAGE_DYNAMIC;
    cb.BindFlags=D3D11_BIND_CONSTANT_BUFFER;cb.CPUAccessFlags=D3D11_CPU_ACCESS_WRITE;
    TRY(ID3D11Device_CreateBuffer(device,&cb,NULL,&constants));
    D3D11_SAMPLER_DESC sd={0};sd.Filter=D3D11_FILTER_MIN_MAG_MIP_POINT;
    sd.AddressU=sd.AddressV=sd.AddressW=D3D11_TEXTURE_ADDRESS_CLAMP;sd.MaxLOD=D3D11_FLOAT32_MAX;
    TRY(ID3D11Device_CreateSamplerState(device,&sd,&point));
    sd.Filter=D3D11_FILTER_MIN_MAG_MIP_LINEAR;
    TRY(ID3D11Device_CreateSamplerState(device,&sd,&linear));
    atomic_store(&ready,1);
    if(pc_metrics_enabled)fprintf(stderr,"Host video: Windows D3D11 vsync ready\n");
    for (;;) {
        HANDLE available[]={stop_event,frame_event};
        if(WaitForMultipleObjects(2,available,FALSE,INFINITE)!=WAIT_OBJECT_0+1) break;
        RECT client;GetClientRect(target,&client);
        int w=client.right,h=client.bottom;
        if(w<=0 || h<=0 || IsIconic(target))continue;
        /* Window events can request redraw before the first completed scanout.
           Do not consume DXGI's initial capacity signal without a Present. */
        SDL_LockMutex(mail_mutex);int have_frame=mailbox.w>0;SDL_UnlockMutex(mail_mutex);
        if(!have_frame)continue;
        HANDLE capacity[]={stop_event,latency};
        if(WaitForMultipleObjects(2,capacity,FALSE,INFINITE)!=WAIT_OBJECT_0+1) break;
        if(delay_ms)SDL_Delay(delay_ms); /* diagnostic stall: never the PC thread */
        /* Copy AFTER the vsync capacity wait: intermediate emulated frames are
           intentionally replaceable, never queued to delay emulation. */
        SDL_LockMutex(mail_mutex);memcpy(frame,&mailbox,sizeof *frame);SDL_UnlockMutex(mail_mutex);
        if(!frame->w) continue;
        if(cw!=w || ch!=h) {
            ID3D11DeviceContext_OMSetRenderTargets(context,0,NULL,NULL);
            RELEASE(rt);RELEASE(back);
            TRY(IDXGISwapChain_ResizeBuffers(swap,2,(UINT)w,(UINT)h,DXGI_FORMAT_UNKNOWN,desc.Flags));
            TRY(IDXGISwapChain_GetBuffer(swap,0,&IID_ID3D11Texture2D,(void **)&back));
            TRY(ID3D11Device_CreateRenderTargetView(device,(ID3D11Resource *)back,NULL,&rt));
            RELEASE(back);cw=w;ch=h;
        }
        if(tw!=frame->w || th!=frame->h) {
            RELEASE(view);RELEASE(image);
            D3D11_TEXTURE2D_DESC td={0};td.Width=(UINT)frame->w;td.Height=(UINT)frame->h;
            td.MipLevels=td.ArraySize=1;td.Format=DXGI_FORMAT_B8G8R8A8_UNORM;td.SampleDesc.Count=1;
            td.Usage=D3D11_USAGE_DYNAMIC;td.BindFlags=D3D11_BIND_SHADER_RESOURCE;td.CPUAccessFlags=D3D11_CPU_ACCESS_WRITE;
            TRY(ID3D11Device_CreateTexture2D(device,&td,NULL,&image));
            TRY(ID3D11Device_CreateShaderResourceView(device,(ID3D11Resource *)image,NULL,&view));
            tw=frame->w;th=frame->h;uploaded=UINT64_MAX;
        }
        D3D11_MAPPED_SUBRESOURCE mapped;
        if(uploaded!=frame->generation) {
            TRY(ID3D11DeviceContext_Map(context,(ID3D11Resource *)image,0,D3D11_MAP_WRITE_DISCARD,0,&mapped));
            for(int y=0;y<th;++y) memcpy((char *)mapped.pData+y*mapped.RowPitch,frame->pixels+y*tw,(size_t)tw*4);
            ID3D11DeviceContext_Unmap(context,(ID3D11Resource *)image,0);uploaded=frame->generation;
        }
        float beam_w=tw==320 ? 320.f : 640.f,beam_h=tw==320 ? 240.f : 480.f;
        float bw=beam_w/40,bh=beam_h/40,canvas_w=beam_w+2*bw,canvas_h=beam_h+2*bh;
        float scale=SDL_min(w/canvas_w,h/canvas_h);
        if(frame->settings.integer_scale && scale>=1) scale=(float)(int)scale;
        float x=(w-canvas_w*scale)/2,y=(h-canvas_h*scale)/2;
        float values[12]={(x+bw*scale)/w,(y+bh*scale)/h,beam_w*scale/w,beam_h*scale/h,
            x/w,y/h,canvas_w*scale/w,canvas_h*scale/h,
            ((frame->border>>16)&255)/255.f,((frame->border>>8)&255)/255.f,(frame->border&255)/255.f,1};
        TRY(ID3D11DeviceContext_Map(context,(ID3D11Resource *)constants,0,D3D11_MAP_WRITE_DISCARD,0,&mapped));
        memcpy(mapped.pData,values,sizeof values);ID3D11DeviceContext_Unmap(context,(ID3D11Resource *)constants,0);
        D3D11_VIEWPORT viewport={0,0,(float)w,(float)h,0,1};
        ID3D11DeviceContext_RSSetViewports(context,1,&viewport);
        ID3D11DeviceContext_OMSetRenderTargets(context,1,&rt,NULL);
        ID3D11DeviceContext_IASetPrimitiveTopology(context,D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
        ID3D11DeviceContext_VSSetShader(context,vs,NULL,0);ID3D11DeviceContext_PSSetShader(context,ps,NULL,0);
        ID3D11DeviceContext_PSSetConstantBuffers(context,0,1,&constants);
        ID3D11DeviceContext_PSSetShaderResources(context,0,1,&view);
        ID3D11SamplerState *sampler=frame->settings.smooth ? linear : point;
        ID3D11DeviceContext_PSSetSamplers(context,0,1,&sampler);
        ID3D11DeviceContext_Draw(context,3,0);
        if(capture && SDL_GetTicksNS()-started>=2200000000u) {
            ID3D11Texture2D *source=NULL,*staging=NULL;
            TRY(IDXGISwapChain_GetBuffer(swap,0,&IID_ID3D11Texture2D,(void **)&source));
            D3D11_TEXTURE2D_DESC td;ID3D11Texture2D_GetDesc(source,&td);
            td.Usage=D3D11_USAGE_STAGING;td.BindFlags=0;td.CPUAccessFlags=D3D11_CPU_ACCESS_READ;td.MiscFlags=0;
            HRESULT result=ID3D11Device_CreateTexture2D(device,&td,NULL,&staging);
            if(SUCCEEDED(result)) {
                ID3D11DeviceContext_CopyResource(context,(ID3D11Resource *)staging,(ID3D11Resource *)source);
                if(SUCCEEDED(ID3D11DeviceContext_Map(context,(ID3D11Resource *)staging,0,D3D11_MAP_READ,0,&mapped))) {
                    SDL_Surface *surface=SDL_CreateSurfaceFrom(w,h,SDL_PIXELFORMAT_ARGB8888,mapped.pData,(int)mapped.RowPitch);
                    if(surface){SDL_SavePNG(surface,capture);SDL_DestroySurface(surface);}
                    ID3D11DeviceContext_Unmap(context,(ID3D11Resource *)staging,0);
                }
            }
            RELEASE(source);RELEASE(staging);capture=NULL;
        }
        uint64_t before=pc_metrics_enabled ? SDL_GetTicksNS() : 0;
        TRY(IDXGISwapChain_Present(swap,1,0));
        HOST_COUNT(HM_PRESENT,1);
        if(pc_metrics_enabled)pc_metrics_add(HM_PRESENT_NS,SDL_GetTicksNS()-before);
    }
cleanup:
    if(FAILED(failure)) fprintf(stderr,"Windows presenter failed: 0x%08lx\n",(unsigned long)failure);
    RELEASE(errors);RELEASE(code);RELEASE(point);RELEASE(linear);RELEASE(constants);
    RELEASE(ps);RELEASE(vs);RELEASE(view);RELEASE(image);RELEASE(rt);RELEASE(back);
    RELEASE(swap2);RELEASE(swap);RELEASE(context);RELEASE(device);
    if(latency)CloseHandle(latency);
    SDL_free(frame);
    if(!atomic_load(&ready))atomic_store(&ready,-1);
    SetEvent(done_event);return 0;
}
int pc_video_start(SDL_Window *window) {
    target=SDL_GetPointerProperty(SDL_GetWindowProperties(window),SDL_PROP_WINDOW_WIN32_HWND_POINTER,NULL);
    if(!target)return 0;
    stop_event=CreateEventW(NULL,TRUE,FALSE,NULL);frame_event=CreateEventW(NULL,FALSE,FALSE,NULL);
    done_event=CreateEventW(NULL,TRUE,FALSE,NULL);mail_mutex=SDL_CreateMutex();atomic_store(&ready,0);
    if(!stop_event || !frame_event || !done_event || !mail_mutex) {pc_video_stop();return -1;}
    memset(&mailbox,0,sizeof mailbox);
    thread=SDL_CreateThread(present_thread,"sam-vsync",NULL);
    if(!thread){pc_video_stop();return -1;}
    while(!atomic_load(&ready)) {SDL_PumpEvents();SDL_Delay(1);}
    if(atomic_load(&ready)<0){pc_video_stop();return -1;}
    return 1;
}
void pc_video_submit(const uint32_t *pixels,int w,int h,uint32_t border,uint64_t generation,const pc_settings *settings) {
    if(!thread)return;
    SDL_LockMutex(mail_mutex);
    int changed=mailbox.generation!=generation || mailbox.w!=w || mailbox.h!=h ||
        mailbox.border!=border || memcmp(&mailbox.settings,settings,sizeof *settings);
    if(mailbox.generation!=generation || mailbox.w!=w || mailbox.h!=h)
        memcpy(mailbox.pixels,pixels,(size_t)w*h*4);
    mailbox.w=w;mailbox.h=h;mailbox.border=border;mailbox.generation=generation;mailbox.settings=*settings;
    SDL_UnlockMutex(mail_mutex);
    if(changed)SetEvent(frame_event);
    if(WaitForSingleObject(done_event,0)==WAIT_OBJECT_0 && FAILED(failure)) {
        fputs("The Windows presenter stopped; terminating.\n",stderr);abort();
    }
}
void pc_video_redraw(void){if(frame_event)SetEvent(frame_event);}
void pc_video_stop(void) {
    if(thread) {
        SetEvent(stop_event);
        /* Present can depend on window messages. Keep pumping until it has
           released its device, then join; never destroy its HWND underneath it. */
        while(WaitForSingleObject(done_event,0)!=WAIT_OBJECT_0){SDL_PumpEvents();SDL_Delay(1);}
        SDL_WaitThread(thread,NULL);thread=NULL;
    }
    if(mail_mutex)SDL_DestroyMutex(mail_mutex);
    mail_mutex=NULL;
    if(stop_event)CloseHandle(stop_event);
    stop_event=NULL;
    if(frame_event)CloseHandle(frame_event);
    frame_event=NULL;
    if(done_event)CloseHandle(done_event);
    done_event=NULL;
}
#else
int pc_video_start(SDL_Window *window){(void)window;return 0;}
void pc_video_submit(const uint32_t *p,int w,int h,uint32_t b,uint64_t g,const pc_settings *s){(void)p;(void)w;(void)h;(void)b;(void)g;(void)s;}
void pc_video_stop(void){}
void pc_video_redraw(void){}
#endif
