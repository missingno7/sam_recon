/* Headless test double only. This is not a replacement for the platform. */
#include "tp/tp.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#ifdef _WIN32
#include <windows.h>
#include <io.h>
#include <fcntl.h>
#endif

uint8_t pc_mem[PC_MEM_SIZE];
static pc_program program;
static pc_code_fn code[128];
static unsigned code_count;
static uint64_t time_us;
static int enabled=1;
static FILE *dos_handles[32];
static uint16_t dos_delete(const char *name);
uint8_t *pc_host(uint16_t seg,uint16_t off) {
    if (seg==0xa000) { fputs("unexpected planar-memory access\n",stderr); exit(99); }
    return pc_mem+PC_LINEAR(seg,off);
}
uint8_t pc_rd8(uint16_t s,uint16_t o) { return *pc_host(s,o); }
uint16_t pc_rd16(uint16_t s,uint16_t o) { return pc_rd8(s,o)|((uint16_t)pc_rd8(s,(uint16_t)(o+1))<<8); }
void pc_wr8(uint16_t s,uint16_t o,uint8_t v) { *pc_host(s,o)=v; }
void pc_wr16(uint16_t s,uint16_t o,uint16_t v) { pc_wr8(s,o,(uint8_t)v); pc_wr8(s,(uint16_t)(o+1),(uint8_t)(v>>8)); }
void pc_load_program(const pc_program *p,const uint8_t *ds,size_t size) {
    program=*p; memset(pc_mem,0,sizeof(pc_mem)); memcpy(pc_host(p->ds_seg,0),ds,size); code_count=0;
}
const pc_program *pc_current_program(void) { return &program; }
farptr pc_register_code(pc_code_fn fn,const char *name) {
    (void)name;
    for (unsigned i=0;i<code_count;++i) if (code[i]==fn) return FP(0xf000,i);
    if (code_count==128) exit(99);
    code[code_count]=fn; return FP(0xf000,code_count++);
}
void pc_call_far(farptr p) { if (FP_SEG(p)==0xf000&&FP_OFF(p)<code_count) code[FP_OFF(p)](); }
void pc_cli(void) { enabled=0; }
void pc_sti(void) { enabled=1; }
int pc_interrupts_enabled(void) { return enabled; }
void pc_int(uint8_t n) { pc_call_far(FP(pc_rd16(0,n*4+2),pc_rd16(0,n*4))); }
void pc_chain_interrupt(farptr p) { pc_call_far(p); }
void pc_poll(void) { ++time_us; }
void pc_bios_int(uint8_t n,pc_regs *r) {
    fprintf(stderr,"pc_bios_int %02X AX=%04X\n",n,r->ax);
    /* Deterministic VGA adapter for startup; no frame rendering. */
    if (n==0x10&&r->ax==0x1b00) r->ax=0x1b;
    if (n==0x10&&r->ax==0x1a00) { r->ax=0x1a; r->bx=8; }
    if (n==0x21) {
        unsigned ah=r->ax>>8, al=r->ax&255; r->flags&=(uint16_t)~1u;
        uint16_t error=0;
        switch (ah) {
        case 0x44:
            if (al) error=1;
            else if (r->bx<5) r->dx=r->bx ? 0x80d2 : 0x80d3;
            else if (r->bx<32 && dos_handles[r->bx]) r->dx=2;
            else error=6;
            break;
        case 0x3c: case 0x3d: {
            unsigned h; for (h=5;h<32 && dos_handles[h];++h) { }
            if (h==32) { error=4; break; }
            dos_handles[h]=pc_fopen((const char *)pc_host(r->ds,r->dx),ah==0x3c ? "w+b" : al ? "r+b" : "rb");
            if (!dos_handles[h]) error=errno==ENOENT ? 2 : 5; else r->ax=(uint16_t)h;
            break;
        }
        case 0x3e:
            if (r->bx<5) break;
            if (r->bx>=32 || !dos_handles[r->bx]) error=6;
            else { fclose(dos_handles[r->bx]); dos_handles[r->bx]=NULL; }
            break;
        case 0x3f: case 0x40: {
            FILE *f=r->bx<32 ? dos_handles[r->bx] : NULL;
            if (ah==0x40 && (r->bx==1 || r->bx==2)) f=r->bx==1 ? stdout : stderr;
            if (ah==0x3f && r->bx==0) f=stdin;
            if (!f) { error=6; break; }
            void *p=pc_host(r->ds,r->dx);
            r->ax=(uint16_t)(ah==0x40 ? fwrite(p,1,r->cx,f) : fread(p,1,r->cx,f));
            if (ferror(f)) error=ah==0x40 ? 101 : 100;
            break;
        }
        case 0x42:
            if (r->bx>=32 || !dos_handles[r->bx] || al>2) error=6;
            else {
                int32_t off=tp_i32(((uint32_t)r->cx<<16)|r->dx);
                if (fseek(dos_handles[r->bx],off,al==0 ? SEEK_SET : al==1 ? SEEK_CUR : SEEK_END)) error=1;
                else { uint32_t pos=(uint32_t)ftell(dos_handles[r->bx]); r->ax=(uint16_t)pos; r->dx=(uint16_t)(pos>>16); }
            }
            break;
        }
        if (error) { r->ax=error; r->flags|=1; }
    }
    if (n==0x21&&r->ax==0x4100) {
        uint16_t error=dos_delete((const char *)pc_host(r->ds,r->dx));
        if (error) { r->ax=error; r->flags|=1; }
        else r->flags&=(uint16_t)~1u;
    }
}
uint8_t pc_inb(uint16_t p) { (void)p; return 0xff; }
uint16_t pc_inw(uint16_t p) { return pc_inb(p)|((uint16_t)pc_inb(p+1)<<8); }
void pc_outb(uint16_t p,uint8_t v) { fprintf(stderr,"pc_outb %04X %02X\n",p,v); }
void pc_outw(uint16_t p,uint16_t v) { pc_outb(p,(uint8_t)v); pc_outb(p+1,(uint8_t)(v>>8)); }
uint64_t pc_time_us(void) { return time_us; }
void pc_delay_ms(uint16_t ms) { time_us+=(uint64_t)ms*1000; pc_poll(); }
const char *pc_data_dir(void) { const char *p=getenv("SAM_ASSET_DIR"); return p?p:"assets"; }
static int same_name(const char *a,const char *b) {
    while (*a&&*b) if (toupper((unsigned char)*a++)!=toupper((unsigned char)*b++)) return 0;
    return *a==*b;
}
static uint16_t dos_delete(const char *name) {
    char path[1024]; const char *dir=pc_data_dir(); DIR *d=opendir(dir);
    if (!d) return 3;
    struct dirent *ent; int found=0;
    while ((ent=readdir(d))) if (same_name(ent->d_name,name)) {
        snprintf(path,sizeof(path),"%s/%s",dir,ent->d_name); found=1; break;
    }
    closedir(d);
    if (!found) return 2;
    return remove(path)==0?0:errno==ENOENT?2:5;
}
static FILE *dos_fopen(const char *path,const char *mode) {
#ifdef _WIN32
    /* DOS unlink is permitted with live handles. fopen's default Windows
       sharing flags deny it; this double opens with FILE_SHARE_DELETE. */
    int writing=strchr(mode,'w')!=NULL,update=strchr(mode,'+')!=NULL;
    DWORD access=writing?GENERIC_WRITE:GENERIC_READ;
    if (update) access=GENERIC_READ|GENERIC_WRITE;
    HANDLE h=CreateFileA(path,access,FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE,
                         NULL,writing?CREATE_ALWAYS:OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);
    if (h==INVALID_HANDLE_VALUE) {
        DWORD error=GetLastError(); errno=error==ERROR_FILE_NOT_FOUND||error==ERROR_PATH_NOT_FOUND?ENOENT:EACCES;
        return NULL;
    }
    int fd=_open_osfhandle((intptr_t)h,_O_BINARY|(update?_O_RDWR:writing?_O_WRONLY:_O_RDONLY));
    if (fd<0) { CloseHandle(h); return NULL; }
    FILE *f=_fdopen(fd,mode); if (!f) _close(fd); return f;
#else
    return fopen(path,mode);
#endif
}
void *pc_fopen(const char *name,const char *mode) {
    char path[1024]; const char *dir=pc_data_dir();
    snprintf(path,sizeof(path),"%s/%s",dir,name);
    FILE *f=dos_fopen(path,mode);
    if (f) return f;
    int open_errno=errno;
    DIR *d=opendir(dir); if (!d) return NULL; struct dirent *ent;
    while ((ent=readdir(d))) if (same_name(ent->d_name,name)) {
        snprintf(path,sizeof(path),"%s/%s",dir,ent->d_name); f=dos_fopen(path,mode); open_errno=errno; break;
    }
    closedir(d); if (!f) errno=open_errno; return f;
}
_Noreturn void pc_terminate(uint8_t c) { exit(c); }

void tp_Delay(uint16_t ms) { fprintf(stderr,"tp_Delay %u\n",ms); pc_delay_ms(ms); }
uint8_t tp_CrtActive;
static uint16_t crt_ds;
static tp_crt_offsets crt_offsets;
void tp_BindCrt(uint16_t ds,const tp_crt_offsets *offsets) { crt_ds=ds;crt_offsets=*offsets; }
void *tp_CrtAddress(uint8_t index) {
    const uint16_t *offsets=(const uint16_t *)&crt_offsets;
    return pc_host(crt_ds,offsets[index]);
}
void tp_CrtInit(void) { tp_CrtActive=1; tp_TextCrtInit(); fputs("tp_CrtInit\n",stderr); }
void tp_CrtWrite(const uint8_t *bytes,size_t size) { fprintf(stderr,"tp_CrtWrite %zu\n",size); fwrite(bytes,1,size,stdout); }
void tp_CrtWriteLn(void) { fputs("tp_CrtWriteLn\n",stderr); putchar('\n'); }
void tp_Sound(uint16_t f) { fprintf(stderr,"tp_Sound %u\n",f); }
void tp_NoSound(void) { fputs("tp_NoSound\n",stderr); }
uint8_t tp_KeyPressed(void) { fputs("tp_KeyPressed\n",stderr); return 0; }
uint8_t tp_ReadKey(void) { fputs("tp_ReadKey\n",stderr); return 0; }
void tp_Intr(uint8_t vector,void *p) {
    pc_regs r; memcpy(&r,p,sizeof(r)); tp_FarSyncIn(); pc_bios_int(vector,&r); tp_FarSyncOut(); memcpy(p,&r,sizeof(r));
}
void tp_MsDos(void *p) { tp_Intr(0x21,p); }
void tp_GetIntVec(uint8_t n,farptr *p) { fprintf(stderr,"tp_GetIntVec %u\n",n); *p=FP(pc_rd16(0,n*4+2),pc_rd16(0,n*4)); }
void tp_SetIntVec(uint8_t n,farptr p) { fprintf(stderr,"tp_SetIntVec %u %08lX\n",n,(unsigned long)p); pc_wr16(0,n*4,FP_OFF(p)); pc_wr16(0,n*4+2,FP_SEG(p)); }
void tp_TextMode(int16_t mode) { fprintf(stderr,"tp_TextMode %d\n",mode); }
void tp_GotoXY(uint8_t x,uint8_t y) { fprintf(stderr,"tp_GotoXY %u %u\n",x,y); }
void tp_ClrScr(void) { fputs("tp_ClrScr\n",stderr); }
void tp_TextColor(uint8_t c) { fprintf(stderr,"tp_TextColor %u\n",c); }
void tp_TextBackground(uint8_t c) { fprintf(stderr,"tp_TextBackground %u\n",c); }
