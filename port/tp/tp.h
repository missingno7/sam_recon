/* TP 5 widths and the generated-code ABI. Host pointers are used for var
   parameters; stored Pascal pointers remain segment:offset values. */
#ifndef SAM_TP_H
#define SAM_TP_H
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include "pc/pc.h"

typedef struct { uint8_t b[256]; } tp_string;
typedef struct { uint8_t b[32]; } tp_set;
typedef struct { uint8_t bytes[128]; } tp_file;
typedef struct { uint8_t bytes[256]; } tp_text;
typedef struct { uint8_t bytes[20]; } tp_registers;
_Static_assert(sizeof(tp_file)==128, "TP FileRec");
_Static_assert(sizeof(tp_text)==256, "TP TextRec");

/* Shared System variables: bound to emulated DS by tp_BindSystem. */
void *tp_SystemAddress(uint16_t offset);
#define tp_ExitProc (*(farptr *)tp_SystemAddress(38))
#define tp_ExitCode (*(int16_t *)tp_SystemAddress(42))
#define tp_RandSeed (*(int32_t *)tp_SystemAddress(54))
#define tp_FileMode (*(uint8_t *)tp_SystemAddress(58))
#define tp_HeapError (*(farptr *)tp_SystemAddress(34))
#define tp_ErrorAddr (*(farptr *)tp_SystemAddress(44))
#define tp_PrefixSeg (*(uint16_t *)tp_SystemAddress(48))
#define tp_StackLimit (*(uint16_t *)tp_SystemAddress(50))
#define tp_InOutRes (*(uint16_t *)tp_SystemAddress(52))
#define tp_Test8087 (*(uint8_t *)tp_SystemAddress(59))
#define tp_HeapOrg (*(farptr *)tp_SystemAddress(20))
#define tp_HeapPtr (*(farptr *)tp_SystemAddress(24))
#define tp_FreePtr (*(farptr *)tp_SystemAddress(28))
#define tp_FreeMin (*(uint16_t *)tp_SystemAddress(32))
void *tp_StandardAddress(uint8_t which);
#define tp_Input (*(tp_text *)tp_StandardAddress(0))
#define tp_Output (*(tp_text *)tp_StandardAddress(1))
void tp_BindSystem(uint16_t ds, uint16_t base);
void tp_BindStandardFiles(uint16_t input_offset,uint16_t output_offset);
void tp_Init(void);

/* C signed arithmetic must not depend on overflow or out-of-range conversions. */
static inline int16_t tp_i16(uint32_t v) {
    uint16_t u=(uint16_t)v; int16_t s; memcpy(&s,&u,2); return s;
}
static inline int32_t tp_i32(uint32_t u) { int32_t s; memcpy(&s,&u,4); return s; }
static inline farptr tp_fp_add(farptr p, int32_t n) { return FP(FP_SEG(p), FP_OFF(p)+(uint32_t)n); }
int32_t tp_DivS(int32_t a,int32_t b);
int32_t tp_ModS(int32_t a,int32_t b);
uint32_t tp_DivU(uint32_t a,uint32_t b);
uint32_t tp_ModU(uint32_t a,uint32_t b);
uint32_t tp_Shift(uint32_t v,int16_t count,uint8_t bits,uint8_t right);
int32_t tp_Abs(int32_t v);
uint8_t tp_UpCase(uint8_t c);

tp_string tp_Sliteral(const uint8_t *data,uint16_t length);
tp_string tp_Schar(uint8_t c);
tp_string tp_Sfrom(const void *s);
void tp_AssignString(void *dest,uint8_t capacity,tp_string src);
tp_string tp_Concat(tp_string a,tp_string b);
int16_t tp_Compare(tp_string a,tp_string b);
uint8_t tp_Length(tp_string s);
tp_string tp_Copy(tp_string s,int16_t index,int16_t count);
int16_t tp_Pos(tp_string needle,tp_string haystack);
void tp_Insert(tp_string source,void *dest,uint8_t capacity,int16_t index);
void tp_Delete(void *dest,int16_t index,int16_t count);
void tp_Str(int32_t value,int16_t width,void *dest,uint8_t capacity);
void tp_Val(tp_string s,void *dest,uint8_t bytes,uint8_t is_signed,int16_t *code);

tp_set tp_SetEmpty(void);
tp_set tp_SetRange(int16_t lo,int16_t hi);
tp_set tp_SetLoad(const void *s,uint8_t lo,uint8_t bytes);
void tp_SetStore(void *s,uint8_t lo,uint8_t bytes,tp_set value);
tp_set tp_SetUnion(tp_set a,tp_set b);
tp_set tp_SetDiff(tp_set a,tp_set b);
tp_set tp_SetIntersect(tp_set a,tp_set b);
uint8_t tp_SetEqual(tp_set a,tp_set b);
uint8_t tp_SetUnequal(tp_set a,tp_set b);
uint8_t tp_SetSubset(tp_set a,tp_set b);
uint8_t tp_SetSuperset(tp_set a,tp_set b);
uint8_t tp_SetContains(tp_set s,int16_t value);
void tp_Move(const void *src,void *dest,uint16_t size);
void tp_FillChar(void *dest,uint16_t size,uint8_t value);

int16_t tp_Random(uint16_t range);
void tp_Randomize(void);
void tp_GetMem(farptr *p,uint16_t size);
void tp_FreeMem(farptr p,uint16_t size);
void tp_Mark(farptr *p);
void tp_Release(farptr p);
int32_t tp_MemAvail(void);
int32_t tp_MaxAvail(void);

/* Temporary SS copies of address-taken host locals. tp_Intr and tp_MsDos
   implementations must bracket BIOS calls with the sync pair. */
uint16_t tp_FrameBegin(void);
void tp_FrameEnd(uint16_t mark);
farptr tp_LocalFar(void *host,uint16_t size);
void tp_FarSyncIn(void);
void tp_FarSyncOut(void);
farptr tp_TempFar(const void *data,uint16_t size);

void tp_Assign(tp_file *f,tp_string name);
void tp_Reset(tp_file *f,uint16_t record_size,uint8_t is_text);
void tp_Rewrite(tp_file *f,uint16_t record_size,uint8_t is_text);
void tp_Close(tp_file *f);
void tp_Erase(tp_file *f);
void tp_Read(tp_file *f,void *dest);
void tp_Write(tp_file *f,const void *src);
void tp_Seek(tp_file *f,int32_t index);
int32_t tp_Filesize(tp_file *f);
int32_t tp_Filepos(tp_file *f);
uint8_t tp_Eof(tp_file *f);
uint8_t tp_Eoln(tp_file *f);
int16_t tp_IOResult(void);
void tp_WriteInteger(int32_t value,int16_t width);
void tp_WriteBoolean(uint8_t value,int16_t width);
void tp_WriteString(tp_string value,int16_t width);
void tp_WriteLn(void);
void tp_TextReadChar(tp_file *f,uint8_t *dest);
void tp_TextReadString(tp_file *f,void *dest,uint8_t cap);
void tp_TextReadInteger(tp_file *f,void *dest,uint8_t bytes,uint8_t sign);
void tp_TextReadLn(tp_file *f);
void tp_TextWriteInteger(tp_file *f,int32_t value,int16_t width);
void tp_TextWriteBoolean(tp_file *f,uint8_t value,int16_t width);
void tp_TextWriteString(tp_file *f,tp_string value,int16_t width);
void tp_TextWriteLn(tp_file *f);
_Noreturn void tp_Halt(uint16_t code);

/* Platform worker: Crt/Dos. Register argument is the 20-byte TP variant,
   not a host-aligned native CPU-register struct. */
#include "crt_dos.h"
#endif
