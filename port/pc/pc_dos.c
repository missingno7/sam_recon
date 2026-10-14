#include "pc_internal.h"
#include <dirent.h>
#include <ctype.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <io.h>
#include <fcntl.h>
#endif

static char data_dir[1024]=".";
static FILE *handles[32];
const char *pc_data_dir(void) { return data_dir; }
void pc_set_data_dir(const char *dir)
{
    if (strlen(dir)>=sizeof data_dir) { fprintf(stderr,"data path too long\n"); abort(); }
    strcpy(data_dir,dir);
}
static int same_name(const char *a,const char *b)
{
    while (*a&&*b) { if(tolower((unsigned char)*a++)!=tolower((unsigned char)*b++)) return 0; }
    return *a==*b;
}
static int resolve_name(const char *name,char path[2048])
{
    char part[256];
    if (!name || !*name) { errno=ENOENT; return 0; }
    strcpy(path,data_dir);
    while (*name) {
        while (*name=='/' || *name=='\\') ++name;
        size_t n=0;
        while (*name && *name!='/' && *name!='\\') {
            if(n+1>=sizeof part) { errno=ENAMETOOLONG; return 0; }
            part[n++]=*name++;
        }
        part[n]=0;
        if (!n) break;
        if (!strcmp(part,"..") || strchr(part,':')) { errno=EACCES; return 0; }
        DIR *d=opendir(path);
        if (d) {
            struct dirent *entry;
            while ((entry=readdir(d))) if (same_name(part,entry->d_name)) { strcpy(part,entry->d_name); break; }
            closedir(d);
        }
        if(strlen(path)+strlen(part)+2>=2048) { errno=ENAMETOOLONG; return 0; }
        strcat(path,"/"); strcat(path,part);
    }
    return 1;
}
void *pc_fopen(const char *name,const char *mode)
{
    char path[2048];if(!resolve_name(name,path)) return NULL;
#ifdef _WIN32
    /* DOS permits unlinking an open file. Every runtime/library open uses this
       shared host opener, including System's FILE* handles outside the DOS table. */
    int update=strchr(mode,'+')!=NULL,write=mode[0]!='r'||update;
    DWORD access=GENERIC_READ|(write ? GENERIC_WRITE : 0);
    DWORD creation=mode[0]=='w' ? CREATE_ALWAYS : mode[0]=='a' ? OPEN_ALWAYS : OPEN_EXISTING;
    HANDLE h=CreateFileA(path,access,FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE,
                         NULL,creation,FILE_ATTRIBUTE_NORMAL,NULL);
    if(h==INVALID_HANDLE_VALUE) {
        DWORD error=GetLastError();errno=(error==ERROR_FILE_NOT_FOUND||error==ERROR_PATH_NOT_FOUND) ? ENOENT : EACCES;
        return NULL;
    }
    int flags=_O_BINARY|(update ? _O_RDWR : write ? _O_WRONLY : _O_RDONLY);
    if(mode[0]=='a') flags|=_O_APPEND;
    int fd=_open_osfhandle((intptr_t)h,flags);
    if(fd<0) {CloseHandle(h);return NULL;}
    FILE *f=_fdopen(fd,mode);if(!f) _close(fd);return f;
#else
    return fopen(path,mode);
#endif
}
static uint16_t dos_delete(const char *name)
{
    char path[2048];if(!resolve_name(name,path)) return errno==ENOENT ? 2 : 5;
#ifdef _WIN32
    if(DeleteFileA(path)) return 0;
    DWORD error=GetLastError();
    return error==ERROR_FILE_NOT_FOUND ? 2 : error==ERROR_PATH_NOT_FOUND ? 3 : 5;
#else
    struct stat st;if(stat(path,&st)) return errno==ENOENT ? 2 : 5;
    if(S_ISDIR(st.st_mode)) return 5;
    return remove(path)==0 ? 0 : 5;
#endif
}
void pc_dos_reset(void)
{
    for(unsigned i=0;i<32;++i) { if(handles[i]) fclose(handles[i]); handles[i]=NULL; }
}
static void dos_error(pc_regs *r,uint16_t error) { r->flags|=1; r->ax=error; }
void bios_dos(pc_regs *r)
{
    unsigned ah=r->ax>>8,al=r->ax&255;
    r->flags&=(uint16_t)~1u;
    switch(ah) {
    case 0x25: pc_wr16(0,(uint16_t)(al*4),r->dx); pc_wr16(0,(uint16_t)(al*4+2),r->ds); break;
    case 0x35: r->bx=pc_rd16(0,(uint16_t)(al*4)); r->es=pc_rd16(0,(uint16_t)(al*4+2)); break;
    case 0x30: r->ax=0x0005; r->bx=0; r->cx=0; break;
    case 0x2b: case 0x2d: r->ax=0; break; /* DOS clock only; no host clock mutation */
    case 0x3c: case 0x3d: {
        char name[260]; size_t i;
        for(i=0;i<sizeof name-1;++i) { name[i]=(char)pc_rd8(r->ds,(uint16_t)(r->dx+i)); if(!name[i]) break; }
        name[i]=0; unsigned h;
        for(h=5;h<32&&handles[h];++h) {}
        if(h==32) { dos_error(r,4); break; }
        const char *m=ah==0x3c ? "w+b" : al==0 ? "rb" : "r+b";
        handles[h]=pc_fopen(name,m);
        if(!handles[h]) dos_error(r,errno==ENOENT ? 2 : 5); else r->ax=(uint16_t)h;
        break;
    }
    case 0x3e:
        if(r->bx>=32 || !handles[r->bx]) dos_error(r,6);
        else { fclose(handles[r->bx]); handles[r->bx]=NULL; } break;
    case 0x3f: case 0x40: {
        FILE *f=r->bx<32 ? handles[r->bx] : NULL;
        if(ah==0x40 && (r->bx==1 || r->bx==2)) f=r->bx==1 ? stdout : stderr;
        if(!f) { dos_error(r,6); break; }
        unsigned n=0;
        for(;n<r->cx;++n) {
            if(ah==0x3f) { int ch=fgetc(f); if(ch==EOF) break; pc_wr8(r->ds,(uint16_t)(r->dx+n),(uint8_t)ch); }
            else if(fputc(pc_rd8(r->ds,(uint16_t)(r->dx+n)),f)==EOF) break;
        }
        if(ferror(f)) dos_error(r,5); else r->ax=(uint16_t)n;
        break;
    }
    case 0x42: {
        if(r->bx>=32 || !handles[r->bx] || al>2) { dos_error(r,6); break; }
        int32_t off=(int32_t)(((uint32_t)r->cx<<16)|r->dx);
        if(fseek(handles[r->bx],off,al==0 ? SEEK_SET : al==1 ? SEEK_CUR : SEEK_END)) dos_error(r,1);
        else { long pos=ftell(handles[r->bx]); r->ax=(uint16_t)pos; r->dx=(uint16_t)((uint32_t)pos>>16); }
        break;
    }
    case 0x41: {
        char name[260];unsigned i;
        for(i=0;i<sizeof name-1;++i) {name[i]=(char)pc_rd8(r->ds,(uint16_t)(r->dx+i));if(!name[i]) break;}
        name[i]=0;uint16_t error=dos_delete(name);
        if(error) dos_error(r,error);
        break;
    }
    case 0x4c: pc_terminate((uint8_t)al);
    case 0x62: case 0x51: r->bx=pc_current_program()->psp_seg; break;
    default: fprintf(stderr,"unsupported INT21 AH=%02x\n",ah); abort();
    }
}
