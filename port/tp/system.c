#include "tp.h"
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <errno.h>
#include <ctype.h>

static uint16_t system_ds, system_base;
static uint16_t standard_offsets[2];
void tp_BindSystem(uint16_t ds, uint16_t base) {
    system_ds = ds;
    system_base = base;
}
void tp_BindStandardFiles(uint16_t in, uint16_t out) {
    standard_offsets[0] = in;
    standard_offsets[1] = out;
}
void *tp_StandardAddress(uint8_t which) {
    return pc_host(system_ds, standard_offsets[which != 0]);
}
void *tp_SystemAddress(uint16_t off) {
    return pc_host(system_ds, system_base + off);
}
#define io_result (*(uint16_t *)tp_SystemAddress(52))
static void io_error(uint16_t code) {
    if (!io_result)
        io_result = code;
}
int16_t tp_IOResult(void) {
    uint16_t code = io_result;
    io_result = 0;
    return tp_i16(code);
}

int32_t tp_DivS(int32_t a, int32_t b) {
    if (!b || (a == INT32_MIN && b == -1))
        tp_Halt(200);
    return a / b;
}
int32_t tp_ModS(int32_t a, int32_t b) {
    if (!b)
        tp_Halt(200);
    if (a == INT32_MIN && b == -1)
        return 0;
    return a % b;
}
uint32_t tp_DivU(uint32_t a, uint32_t b) {
    if (!b)
        tp_Halt(200);
    return a / b;
}
uint32_t tp_ModU(uint32_t a, uint32_t b) {
    if (!b)
        tp_Halt(200);
    return a % b;
}
uint32_t tp_Shift(uint32_t v, int16_t count, uint8_t bits, uint8_t right) {
    uint8_t n = (uint8_t)count;
    uint32_t mask = bits == 32 ? UINT32_MAX : UINT16_MAX;
    v &= mask;
    if (n >= bits)
        return 0;
    return right ? v >> n : (v << n) & mask;
}
int32_t tp_Abs(int32_t v) {
    return v < 0 ? tp_i32(0u - (uint32_t)v) : v;
}
uint8_t tp_UpCase(uint8_t c) {
    return c >= 'a' && c <= 'z' ? (uint8_t)(c - 32) : c;
}

tp_string tp_Sliteral(const uint8_t *data, uint16_t length) {
    tp_string r = {{0}};
    if (length > 255)
        length = 255;
    r.b[0] = (uint8_t)length;
    memcpy(r.b + 1, data, length);
    return r;
}
tp_string tp_Schar(uint8_t c) {
    return tp_Sliteral(&c, 1);
}
tp_string tp_Sfrom(const void *s) {
    const uint8_t *p = s;
    return tp_Sliteral(p + 1, p[0]);
}
void tp_AssignString(void *dest, uint8_t cap, tp_string src) {
    uint8_t *p = dest;
    uint8_t n = src.b[0] > cap ? cap : src.b[0];
    p[0] = n;
    memmove(p + 1, src.b + 1, n); /* unused tail is deliberately untouched */
}
tp_string tp_Concat(tp_string a, tp_string b) {
    unsigned n = b.b[0];
    if (n > 255u - a.b[0])
        n = 255u - a.b[0];
    memcpy(a.b + 1 + a.b[0], b.b + 1, n);
    a.b[0] = (uint8_t)(a.b[0] + n);
    return a;
}
int16_t tp_Compare(tp_string a, tp_string b) {
    unsigned n = a.b[0] < b.b[0] ? a.b[0] : b.b[0];
    int c = memcmp(a.b + 1, b.b + 1, n);
    return c < 0 ? -1 : c > 0 ? 1 : a.b[0] < b.b[0] ? -1 : a.b[0] > b.b[0] ? 1 : 0;
}
uint8_t tp_Length(tp_string s) {
    return s.b[0];
}
tp_string tp_Copy(tp_string s, int16_t index, int16_t count) {
    if (index < 1)
        index = 1;
    if (index > s.b[0] || count <= 0)
        return tp_Sliteral(NULL, 0);
    unsigned n = (unsigned)count;
    if (n > (unsigned)s.b[0] - index + 1)
        n = (unsigned)s.b[0] - index + 1;
    return tp_Sliteral(s.b + index, (uint16_t)n);
}
int16_t tp_Pos(tp_string a, tp_string b) {
    if (!a.b[0])
        return 1;
    for (unsigned i = 1; i + a.b[0] - 1 <= b.b[0]; ++i)
        if (!memcmp(b.b + i, a.b + 1, a.b[0]))
            return (int16_t)i;
    return 0;
}
void tp_Insert(tp_string src, void *dest, uint8_t cap, int16_t index) {
    uint8_t *p = dest;
    if (index < 1)
        index = 1;
    if (index > p[0] + 1)
        index = p[0] + 1;
    tp_string left = tp_Copy(tp_Sfrom(p), 1, index - 1);
    tp_string right = tp_Copy(tp_Sfrom(p), index, 255);
    tp_AssignString(p, cap, tp_Concat(tp_Concat(left, src), right));
}
void tp_Delete(void *dest, int16_t index, int16_t count) {
    uint8_t *p = dest;
    if (index < 1) {
        count = (int16_t)(count + index - 1);
        index = 1;
    }
    if (index > p[0] || count <= 0)
        return;
    unsigned n = (unsigned)count;
    if (n > (unsigned)p[0] - index + 1)
        n = (unsigned)p[0] - index + 1;
    memmove(p + index, p + index + n, p[0] - index + 1 - n);
    p[0] = (uint8_t)(p[0] - n);
}
void tp_Str(int32_t value, int16_t width, void *dest, uint8_t cap) {
    char buf[32];
    int n = snprintf(buf, sizeof(buf), "%ld", (long)value);
    tp_string s = {{0}};
    int padding = width - n;
    if (padding < 0)
        padding = 0;
    if (padding > 255 - n)
        padding = 255 - n;
    memset(s.b + 1, ' ', (size_t)padding);
    memcpy(s.b + 1 + padding, buf, (size_t)n);
    s.b[0] = (uint8_t)(padding + n);
    tp_AssignString(dest, cap, s);
}
void tp_Val(tp_string s, void *dest, uint8_t bytes, uint8_t sign, int16_t *code) {
    /* Integer syntax is checked with an index, so the error reports the
       first rejected source byte rather than a host strtol end pointer. */
    uint16_t i = 1;
    uint8_t negative = 0, base = 10;
    uint32_t v = 0;
    while (i <= s.b[0] && s.b[i] == ' ')
        ++i;
    if (i <= s.b[0] && (s.b[i] == '+' || s.b[i] == '-')) {
        negative = s.b[i] == '-';
        ++i;
    }
    if (i <= s.b[0] && s.b[i] == '$') {
        base = 16;
        ++i;
    }
    uint16_t first = i;
    for (; i <= s.b[0]; ++i) {
        uint8_t c = tp_UpCase(s.b[i]);
        unsigned d = c >= '0' && c <= '9' ? c - '0' : c >= 'A' && c <= 'F' ? c - 'A' + 10 : 255;
        if (d >= base)
            break;
        uint32_t limit = negative ? 0x80000000u : 0x7fffffffu;
        if (base == 16 && !negative)
            limit = UINT32_MAX;
        if (v > (limit - d) / base)
            break;
        v = v * base + d;
    }
    *code = (i == first || i <= s.b[0]) ? (int16_t)i : 0;
    if (*code)
        v = 0;
    if (negative)
        v = 0u - v;
    /* $R- assignments truncate after the parser's LongInt conversion. */
    (void)sign;
    if (bytes == 1) {
        uint8_t x = (uint8_t)v;
        memcpy(dest, &x, 1);
    } else if (bytes == 2) {
        uint16_t x = (uint16_t)v;
        memcpy(dest, &x, 2);
    } else
        memcpy(dest, &v, 4);
}

tp_set tp_SetEmpty(void) {
    tp_set s = {{0}};
    return s;
}
tp_set tp_SetRange(int16_t lo, int16_t hi) {
    tp_set s = tp_SetEmpty();
    for (int32_t i = lo; i <= hi; ++i)
        if (i >= 0 && i <= 255)
            s.b[i / 8] |= (uint8_t)(1u << (i & 7));
    return s;
}
tp_set tp_SetLoad(const void *p, uint8_t lo, uint8_t bytes) {
    tp_set s = tp_SetEmpty();
    memcpy(s.b + lo / 8, p, bytes);
    return s;
}
void tp_SetStore(void *p, uint8_t lo, uint8_t bytes, tp_set s) {
    memcpy(p, s.b + lo / 8, bytes);
}
tp_set tp_SetUnion(tp_set a, tp_set b) {
    for (unsigned i = 0; i < 32; ++i)
        a.b[i] |= b.b[i];
    return a;
}
tp_set tp_SetDiff(tp_set a, tp_set b) {
    for (unsigned i = 0; i < 32; ++i)
        a.b[i] &= (uint8_t)~b.b[i];
    return a;
}
tp_set tp_SetIntersect(tp_set a, tp_set b) {
    for (unsigned i = 0; i < 32; ++i)
        a.b[i] &= b.b[i];
    return a;
}
uint8_t tp_SetEqual(tp_set a, tp_set b) {
    return !memcmp(a.b, b.b, 32);
}
uint8_t tp_SetUnequal(tp_set a, tp_set b) {
    return !tp_SetEqual(a, b);
}
uint8_t tp_SetSubset(tp_set a, tp_set b) {
    for (unsigned i = 0; i < 32; ++i)
        if (a.b[i] & ~b.b[i])
            return 0;
    return 1;
}
uint8_t tp_SetSuperset(tp_set a, tp_set b) {
    return tp_SetSubset(b, a);
}
uint8_t tp_SetContains(tp_set s, int16_t v) {
    return v >= 0 && v <= 255 ? (s.b[v / 8] >> (v & 7)) & 1u : 0;
}
void tp_Move(const void *src, void *dest, uint16_t size) {
    memmove(dest, src, size);
}
void tp_FillChar(void *dest, uint16_t size, uint8_t value) {
    memset(dest, value, size);
}

int16_t tp_Random(uint16_t range) {
#ifdef SAM_LOCKSTEP
    pc_lockstep_trace("TP.Random");
#endif
    uint32_t seed = (uint32_t)tp_RandSeed * 0x08088405u + 1u;
    tp_RandSeed = tp_i32(seed);
    return range ? tp_i16((seed >> 16) % range) : 0;
}
void tp_Randomize(void) {
    tp_RandSeed = tp_i32((uint32_t)pc_time_us());
}

/* TP 5.0 System, investigated with HEAP.PAS: allocations consume exact byte
   counts and return normalized offsets 0..15. Free ranges are 8-byte records
   growing downward in the top 64K segment. Removing a range swaps in the
   first table record; allocation scans that physical order, not address order.
   The table itself reduces MemAvail. No host allocator owns Pascal memory. */
static uint32_t heap_linear(farptr p) {
    return ((uint32_t)FP_SEG(p) << 4) + FP_OFF(p);
}
static farptr heap_normal(uint32_t n) {
    return FP(n >> 4, n & 15);
}
static uint32_t heap_ceiling(void) {
    uint16_t off = FP_OFF(tp_FreePtr), seg = FP_SEG(tp_FreePtr);
    uint32_t top;
    if (!off && !tp_FreeMin)
        top = ((uint32_t)seg + 0x1000u) << 4;
    else
        top = ((uint32_t)seg << 4) + (off >= tp_FreeMin ? off - tp_FreeMin : 0);
    uint32_t ptr = heap_linear(tp_HeapPtr);
    return top < ptr ? ptr : top;
}
static farptr heap_entry(uint16_t off) {
    return FP(FP_SEG(tp_FreePtr), off);
}
static farptr heap_rdptr(farptr entry, uint16_t delta) {
    uint16_t seg = FP_SEG(entry), off = FP_OFF(entry) + delta;
    return FP(pc_rd16(seg, off + 2), pc_rd16(seg, off));
}
static void heap_wrptr(farptr entry, uint16_t delta, farptr value) {
    uint16_t seg = FP_SEG(entry), off = FP_OFF(entry) + delta;
    pc_wr16(seg, off, FP_OFF(value));
    pc_wr16(seg, off + 2, FP_SEG(value));
}
static void heap_remove(uint16_t off) {
    uint16_t first = FP_OFF(tp_FreePtr);
    memmove(pc_host_fp(heap_entry(off)), pc_host_fp(heap_entry(first)), 8);
    tp_FreePtr = FP(FP_SEG(tp_FreePtr), (uint16_t)(first + 8));
}
void tp_GetMem(farptr *p, uint16_t size) {
    for (uint16_t off = FP_OFF(tp_FreePtr); off; off = (uint16_t)(off + 8)) {
        farptr entry = heap_entry(off);
        uint32_t first = heap_linear(heap_rdptr(entry, 0)), end = heap_linear(heap_rdptr(entry, 4));
        if (end - first < size)
            continue;
        *p = heap_normal(first);
        heap_wrptr(entry, 0, heap_normal(first + size));
        if (first + size == end)
            heap_remove(off);
        return;
    }
    uint32_t first = heap_linear(tp_HeapPtr);
    if (heap_ceiling() - first < size)
        tp_Halt(203);
    *p = tp_HeapPtr;
    tp_HeapPtr = heap_normal(first + size);
}
void tp_FreeMem(farptr p, uint16_t size) {
    if (!size)
        return;
    uint32_t first = heap_linear(p), end = first + size;
    if (first < heap_linear(tp_HeapOrg) || end > heap_linear(tp_HeapPtr))
        tp_Halt(204);
    uint16_t off = FP_OFF(tp_FreePtr);
    while (off) {
        farptr entry = heap_entry(off);
        uint32_t lo = heap_linear(heap_rdptr(entry, 0)), hi = heap_linear(heap_rdptr(entry, 4));
        if (first <= hi && end >= lo) {
            if (lo < first)
                first = lo;
            if (hi > end)
                end = hi;
            heap_remove(off);
        }
        off = (uint16_t)(off + 8);
    }
    if (end == heap_linear(tp_HeapPtr)) {
        tp_HeapPtr = heap_normal(first);
        return;
    }
    off = (uint16_t)(FP_OFF(tp_FreePtr) - 8);
    if (!off || ((uint32_t)FP_SEG(tp_FreePtr) + (off >> 4)) <= FP_SEG(tp_HeapPtr))
        tp_Halt(204);
    tp_FreePtr = heap_entry(off);
    heap_wrptr(tp_FreePtr, 0, heap_normal(first));
    heap_wrptr(tp_FreePtr, 4, heap_normal(end));
}
void tp_Mark(farptr *p) {
    *p = tp_HeapPtr;
}
void tp_Release(farptr p) {
    tp_HeapPtr = p;
    tp_FreePtr = FP(FP_SEG(tp_FreePtr), 0);
}
int32_t tp_MemAvail(void) {
    uint32_t size = heap_ceiling() - heap_linear(tp_HeapPtr);
    for (uint16_t off = FP_OFF(tp_FreePtr); off; off = (uint16_t)(off + 8)) {
        farptr e = heap_entry(off);
        size += heap_linear(heap_rdptr(e, 4)) - heap_linear(heap_rdptr(e, 0));
    }
    return (int32_t)size;
}
int32_t tp_MaxAvail(void) {
    uint32_t size = heap_ceiling() - heap_linear(tp_HeapPtr);
    for (uint16_t off = FP_OFF(tp_FreePtr); off; off = (uint16_t)(off + 8)) {
        farptr e = heap_entry(off);
        uint32_t n = heap_linear(heap_rdptr(e, 4)) - heap_linear(heap_rdptr(e, 0));
        if (n > size)
            size = n;
    }
    return (int32_t)size;
}

typedef struct {
    void *host;
    farptr far;
    uint16_t size;
} local_ref;
static local_ref refs[128];
static uint16_t ref_count, ref_next;
uint16_t tp_FrameBegin(void) {
    return ref_count;
}
void tp_FrameEnd(uint16_t mark) {
    if (mark > ref_count)
        tp_Halt(202);
    ref_count = mark;
    ref_next = mark ? (uint16_t)((FP_OFF(refs[mark - 1].far) + refs[mark - 1].size + 1u) & ~1u) : 0;
}
farptr tp_LocalFar(void *host, uint16_t size) {
    for (unsigned i = 0; i < ref_count; ++i)
        if (refs[i].host == host && refs[i].size == size) {
            memcpy(pc_host_fp(refs[i].far), host, size);
            return refs[i].far;
        }
    if (ref_count == 128 || (uint32_t)ref_next + size > pc_current_program()->sp)
        tp_Halt(202);
    farptr p = FP(pc_current_program()->ss_seg, ref_next);
    refs[ref_count++] = (local_ref){host, p, size};
    ref_next = (uint16_t)((ref_next + size + 1u) & ~1u);
    memcpy(pc_host_fp(p), host, size);
    return p;
}
farptr tp_TempFar(const void *data, uint16_t size) {
    if (ref_count == 128 || (uint32_t)ref_next + size > pc_current_program()->sp)
        tp_Halt(202);
    farptr p = FP(pc_current_program()->ss_seg, ref_next);
    refs[ref_count++] = (local_ref){NULL, p, size};
    ref_next = (uint16_t)((ref_next + size + 1u) & ~1u);
    memcpy(pc_host_fp(p), data, size);
    return p;
}
void tp_FarSyncIn(void) {
    for (unsigned i = 0; i < ref_count; ++i)
        if (refs[i].host)
            memcpy(pc_host_fp(refs[i].far), refs[i].host, refs[i].size);
}
void tp_FarSyncOut(void) {
    for (unsigned i = 0; i < ref_count; ++i)
        if (refs[i].host)
            memcpy(refs[i].host, pc_host_fp(refs[i].far), refs[i].size);
}

/* TP 5.0 FileRec/TextRec. DOS owns every handle; no private FILE* table.
   Offsets follow the runtime's Assign/Open/Read/Write operations, not snapshots. */
static uint16_t readword(const void *p) { uint16_t v; memcpy(&v,p,2); return v; }
static void writeword(void *p, uint16_t v) { memcpy(p,&v,2); }
static void writeptr(void *p, farptr v) { memcpy(p,&v,4); }
static farptr readptr(const void *p) { farptr v; memcpy(&v,p,4); return v; }
static farptr file_far(void *p, uint16_t size) {
    uintptr_t a=(uintptr_t)p, base=(uintptr_t)pc_mem;
    if (a>=base && a+size<=base+sizeof pc_mem) {
        uint32_t linear=(uint32_t)(a-base), dsbase=(uint32_t)system_ds*16;
        if (linear>=dsbase && linear-dsbase+size<=65536) return FP(system_ds,linear-dsbase);
        return FP(linear>>4,linear&15);
    }
    return tp_LocalFar(p,size);
}
static int dos(pc_regs *r) {
    pc_bios_int(0x21,r);
    if (r->flags & 1) { io_error(r->ax); return 0; }
    return 1;
}
static uint16_t transfer(uint8_t ah, uint16_t h, void *data, uint16_t count) {
    uint16_t mark=tp_FrameBegin();
    farptr p=file_far(data,count);
    pc_regs r={0}; r.ax=(uint16_t)ah<<8; r.bx=h; r.cx=count; r.ds=FP_SEG(p); r.dx=FP_OFF(p);
    int ok=dos(&r);
    if (ah==0x3f && ok && data!=pc_host_fp(p)) memcpy(data,pc_host_fp(p),r.ax);
    tp_FrameEnd(mark); return ok ? r.ax : 0;
}
static tp_file *text_context;
static void text_input_callback(void);
static void text_output_callback(void);
static void text_device_output_callback(void);
static void text_close_callback(void);
static void text_open_callback(void);
static void crt_text_open_callback(void);
static void crt_text_input_callback(void);
static void crt_text_output_callback(void);
static void crt_text_noop_callback(void) { }
static void text_callback(tp_file *f, unsigned field) {
    tp_file *previous=text_context; text_context=f;
    pc_call_far(readptr(f->bytes+field)); text_context=previous;
}
static void assign_record(tp_file *f, tp_string name) {
    /* Assign clears the header and terminates Name, but preserves its tail. */
    memset(f->bytes,0,48); writeword(f->bytes+2,0xd7b0);
    unsigned n=name.b[0]>79 ? 79 : name.b[0];
    memcpy(f->bytes+48,name.b+1,n); f->bytes[48+n]=0;
}
void tp_Assign(tp_file *f, tp_string name) { assign_record(f,name); }
void tp_AssignText(tp_file *f, tp_string name) {
    assign_record(f,name); writeword(f->bytes+4,128);
    writeptr(f->bytes+12,tp_fp_add(file_far(f,256),128));
    writeptr(f->bytes+16,pc_register_code(text_open_callback,"System.TextOpen"));
}
static void close_handle(tp_file *f) {
    uint16_t h=readword(f->bytes);
    if (h>4) { pc_regs r={0}; r.ax=0x3e00; r.bx=h; dos(&r); }
}
static int valid_file(tp_file *f) {
    if (readword(f->bytes+2)!=0xd7b3) { io_error(103); return 0; }
    return 1;
}
static void open_file(tp_file *f,uint16_t size,uint8_t text,uint8_t writing) {
    if (io_result) return;
    uint16_t mode=readword(f->bytes+2);
    if (text) {
        if (mode==0xd7b1 || mode==0xd7b2) tp_Close(f);
        else if (mode!=0xd7b0) { io_error(102); return; }
        writeword(f->bytes+2,writing ? 0xd7b2 : 0xd7b1);
        writeword(f->bytes+8,0); writeword(f->bytes+10,0);
        text_callback(f,16);
        if (io_result) writeword(f->bytes+2,0xd7b0);
        return;
    }
    if (mode==0xd7b3) tp_Close(f);
    else if (mode!=0xd7b0) { io_error(102); return; }
    uint16_t h=writing ? 1 : 0;
    if (f->bytes[48]) {
        pc_regs r={0}; farptr p=tp_fp_add(file_far(f,128),48);
        r.ax=writing ? 0x3c00 : (uint16_t)(0x3d00|tp_FileMode); r.ds=FP_SEG(p); r.dx=FP_OFF(p);
        if (!dos(&r)) return;
        h=r.ax;
    }
    writeword(f->bytes,h); writeword(f->bytes+2,0xd7b3); writeword(f->bytes+4,size);
}
void tp_Reset(tp_file *f,uint16_t size,uint8_t text) { open_file(f,size,text,0); }
void tp_Rewrite(tp_file *f,uint16_t size,uint8_t text) { open_file(f,size,text,1); }
void tp_Close(tp_file *f) {
    if (io_result) return;
    uint16_t mode=readword(f->bytes+2);
    if (mode==0xd7b3) close_handle(f);
    else if (mode==0xd7b1 || mode==0xd7b2) {
        if (mode==0xd7b2) text_callback(f,20);
        text_callback(f,28);
    } else { io_error(103); return; }
    writeword(f->bytes+2,0xd7b0);
}
void tp_Erase(tp_file *f) {
    if (io_result) return;
    pc_regs r={0}; farptr p=tp_fp_add(file_far(f,128),48);
    r.ax=0x4100; r.ds=FP_SEG(p); r.dx=FP_OFF(p); dos(&r);
}
void tp_Read(tp_file *f,void *p) {
    if (io_result || !valid_file(f)) return;
    uint16_t n=readword(f->bytes+4);
    if (transfer(0x3f,readword(f->bytes),p,n)!=n) io_error(100);
}
void tp_Write(tp_file *f,const void *p) {
    if (io_result || !valid_file(f)) return;
    uint16_t n=readword(f->bytes+4);
    if (transfer(0x40,readword(f->bytes),(void *)p,n)!=n) io_error(101);
}
static int32_t seek_bytes(tp_file *f,int32_t offset,uint8_t origin) {
    pc_regs r={0}; r.ax=(uint16_t)(0x4200|origin); r.bx=readword(f->bytes);
    r.cx=(uint16_t)((uint32_t)offset>>16); r.dx=(uint16_t)offset;
    return dos(&r) ? tp_i32(((uint32_t)r.dx<<16)|r.ax) : 0;
}
void tp_Seek(tp_file *f,int32_t index) {
    if (!io_result && valid_file(f)) seek_bytes(f,tp_i32((uint32_t)index*readword(f->bytes+4)),0);
}
int32_t tp_Filepos(tp_file *f) {
    if (io_result || !valid_file(f)) return 0;
    uint16_t size=readword(f->bytes+4); if (!size) tp_Halt(200);
    return seek_bytes(f,0,1)/size;
}
int32_t tp_Filesize(tp_file *f) {
    if (io_result || !valid_file(f)) return 0;
    int32_t pos=seek_bytes(f,0,1), end=seek_bytes(f,0,2); seek_bytes(f,pos,0);
    uint16_t size=readword(f->bytes+4); if (!size) tp_Halt(200);
    return end/size;
}
static tp_file *text_file(tp_file *f,uint8_t writing) {
    if (!f) f=(tp_file *)(writing ? (void *)&tp_Output : (void *)&tp_Input);
    if (readword(f->bytes+2)!=(writing ? 0xd7b2 : 0xd7b1)) io_error(writing ? 105 : 104);
    return f;
}
static uint8_t *text_buffer(tp_file *f) { return pc_host_fp(readptr(f->bytes+12)); }
static void text_input_callback(void) {
    tp_file *f=text_context; uint16_t n=transfer(0x3f,readword(f->bytes),text_buffer(f),readword(f->bytes+4));
    writeword(f->bytes+8,0); writeword(f->bytes+10,n);
}
static void text_output_callback(void) {
    tp_file *f=text_context; uint16_t n=readword(f->bytes+8); writeword(f->bytes+8,0);
    if (transfer(0x40,readword(f->bytes),text_buffer(f),n)!=n) io_error(101);
}
static void text_device_output_callback(void) { text_output_callback(); }
static void text_close_callback(void) { close_handle(text_context); }
static void text_open_callback(void) {
    tp_file *f=text_context; uint8_t writing=readword(f->bytes+2)!=0xd7b1;
    uint16_t h=writing ? 1 : 0;
    if (f->bytes[48]) {
        pc_regs r={0}; farptr p=tp_fp_add(file_far(f,256),48);
        r.ax=writing ? 0x3c02 : 0x3d00; r.ds=FP_SEG(p); r.dx=FP_OFF(p);
        if (!dos(&r)) return;
        h=r.ax;
    }
    writeword(f->bytes,h);
    pc_regs r={0}; r.ax=0x4400; r.bx=h;
    if (writing) dos(&r);
    int device=writing && (r.dx&128);
    writeptr(f->bytes+20,pc_register_code(writing ? (device ? text_device_output_callback : text_output_callback) : text_input_callback,
        writing ? (device ? "System.TextDeviceOutput" : "System.TextOutput") : "System.TextInput"));
    writeptr(f->bytes+24,device ? readptr(f->bytes+20) : 0);
    writeptr(f->bytes+28,pc_register_code(text_close_callback,"System.TextClose"));
}
static void crt_text_open_callback(void) {
    tp_file *f=text_context; int writing=readword(f->bytes+2)!=0xd7b1;
    if (writing) writeword(f->bytes+2,0xd7b2);
    farptr noop=pc_register_code(crt_text_noop_callback,"Crt.TextNoop");
    farptr output=pc_register_code(crt_text_output_callback,"Crt.TextOutput");
    writeptr(f->bytes+20,writing ? output : pc_register_code(crt_text_input_callback,"Crt.TextInput"));
    writeptr(f->bytes+24,writing ? output : noop); writeptr(f->bytes+28,noop);
}
static void crt_text_output_callback(void) {
    tp_file *f=text_context; uint16_t n=readword(f->bytes+8); writeword(f->bytes+8,0);
    tp_CrtWrite(text_buffer(f),n);
}
static void crt_text_input_callback(void) {
    tp_file *f=text_context; uint8_t *buf=text_buffer(f); uint16_t n=0, size=readword(f->bytes+4);
    while (n+2<size) {
        uint8_t ch=tp_ReadKey();
        if (ch==13) { buf[n++]=13; buf[n++]=10; break; }
        if (ch>=32) buf[n++]=ch;
    }
    writeword(f->bytes+8,0); writeword(f->bytes+10,n);
}
void tp_TextCrtInit(void) {
    for (unsigned i=0;i<2;++i) {
        tp_file *f=(tp_file *)tp_StandardAddress((uint8_t)i);
        writeword(f->bytes+2,0xd7b0); writeword(f->bytes+4,128);
        writeptr(f->bytes+12,tp_fp_add(file_far(f,256),128));
        writeptr(f->bytes+16,pc_register_code(crt_text_open_callback,"Crt.TextOpen"));
        f->bytes[48]=0; open_file(f,128,1,(uint8_t)i);
    }
}
static int text_peek(tp_file *f) {
    f=text_file(f,0); if (io_result) return 26;
    uint16_t pos=readword(f->bytes+8), end=readword(f->bytes+10);
    if (pos==end) { text_callback(f,20); pos=readword(f->bytes+8); end=readword(f->bytes+10); }
    return pos==end ? 26 : text_buffer(f)[pos];
}
static void text_take(tp_file *f) {
    f=text_file(f,0); if (io_result) return;
    uint16_t pos=readword(f->bytes+8); if (pos<readword(f->bytes+10)) writeword(f->bytes+8,(uint16_t)(pos+1));
}
static void text_put(tp_file *f,uint8_t ch) {
    f=text_file(f,1); if (io_result) return;
    uint16_t pos=readword(f->bytes+8); text_buffer(f)[pos++]=ch; writeword(f->bytes+8,pos);
    if (pos==readword(f->bytes+4)) text_callback(f,20);
}
static void text_flush_line(tp_file *f) {
    f=text_file(f,1); if (!io_result && readptr(f->bytes+24)) text_callback(f,24);
}
uint8_t tp_Eof(tp_file *f) { return readword(f->bytes+2)==0xd7b3 ? tp_Filepos(f)>=tp_Filesize(f) : text_peek(f)==26; }
uint8_t tp_Eoln(tp_file *f) { int c=text_peek(f); return c==13 || c==26; }

void tp_WriteInteger(int32_t value, int16_t width) {
    tp_TextWriteInteger(NULL, value, width);
}
void tp_WriteBoolean(uint8_t value, int16_t width) {
    tp_TextWriteBoolean(NULL, value, width);
}
void tp_WriteString(tp_string s, int16_t width) {
    tp_TextWriteString(NULL, s, width);
}
void tp_WriteLn(void) {
    tp_TextWriteLn(NULL);
}
static void text_put(tp_file *f, uint8_t ch);
static int text_peek(tp_file *f);
static void text_take(tp_file *f);
void tp_TextReadChar(tp_file *f, uint8_t *dest) {
    if (!io_result) { *dest = (uint8_t)text_peek(f); text_take(f); }
}
void tp_TextReadString(tp_file *f, void *dest, uint8_t cap) {
    if (io_result) return;
    tp_string s = {{0}};
    while (s.b[0] < cap) {
        int c = text_peek(f);
        if (c == 13 || c == 26) break;
        s.b[++s.b[0]] = (uint8_t)c; text_take(f);
    }
    tp_AssignString(dest, cap, s);
}
void tp_TextReadInteger(tp_file *f, void *dest, uint8_t bytes, uint8_t sign) {
    if (io_result) return;
    int c;
    while ((c = text_peek(f)) == ' ' || c == 9 || c == 13 || c == 10) text_take(f);
    tp_string s = {{0}};
    while (c != 26 && c != ' ' && c != 9 && c != 13 && c != 10 && s.b[0] < 255) {
        s.b[++s.b[0]] = (uint8_t)c; text_take(f); c = text_peek(f);
    }
    int16_t code; tp_Val(s, dest, bytes, sign, &code);
    if (code) io_error(106);
}
void tp_TextReadLn(tp_file *f) {
    if (io_result) return;
    int c;
    while ((c=text_peek(f)) != 26 && c != 13) text_take(f);
    if (c == 13) { text_take(f); if (text_peek(f) == 10) text_take(f); }
}
void tp_TextWriteString(tp_file *f, tp_string s, int16_t width) {
    if (io_result) return;
    for (int i=s.b[0]; i<width; ++i) text_put(f, ' ');
    for (unsigned i=1; i<=s.b[0]; ++i) text_put(f, s.b[i]);
}
void tp_TextWriteInteger(tp_file *f, int32_t value, int16_t width) {
    char data[32];
    int n = snprintf(data, sizeof(data), "%ld", (long)value);
    tp_TextWriteString(f, tp_Sliteral((const uint8_t *)data, (uint16_t)n), width);
}
void tp_TextWriteBoolean(tp_file *f, uint8_t value, int16_t width) {
    const char *s = value ? "TRUE" : "FALSE";
    tp_TextWriteString(f, tp_Sliteral((const uint8_t *)s, value ? 4 : 5), width);
}
void tp_TextWriteLn(tp_file *f) {
    if (io_result) return;
    text_put(f,13); text_put(f,10);
    text_flush_line(f);
}
void tp_Init(void) {
    ref_count = ref_next = io_result = 0;
    tp_ExitProc = 0;
    tp_ExitCode = 0;
    tp_RandSeed = 0;
    tp_FileMode = 2;
    tp_PrefixSeg = pc_current_program()->psp_seg;
    tp_HeapOrg = tp_HeapPtr = FP(pc_current_program()->heap_org_seg, 0);
    /* System startup establishes the empty overlay arena at HeapOrg and saves
       its DOS interrupt vectors before any unit installs replacement handlers. */
    for (uint16_t off = 8; off <= 12; off += 2)
        writeword(tp_SystemAddress(off), FP_SEG(tp_HeapOrg));
    static const uint8_t saved_vectors[] = {
        0x00, 0x02, 0x1b, 0x23, 0x24, 0x34, 0x35, 0x36, 0x37,
        0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, 0x75
    };
    for (unsigned i = 0; i < sizeof saved_vectors; ++i) {
        uint16_t dest = (uint16_t)(standard_offsets[1] + sizeof(tp_text) + i * 4);
        uint16_t src = (uint16_t)(saved_vectors[i] * 4);
        pc_wr16(system_ds, dest, pc_rd16(0, src));
        pc_wr16(system_ds, (uint16_t)(dest + 2), pc_rd16(0, (uint16_t)(src + 2)));
    }
    tp_FreePtr = FP(pc_current_program()->mem_top_seg - 0x1000u, 0);
    tp_FreeMin = 0;
    tp_AssignText((tp_file *)&tp_Input, tp_Sliteral(NULL,0));
    tp_Reset((tp_file *)&tp_Input,128,1);
    tp_AssignText((tp_file *)&tp_Output, tp_Sliteral(NULL,0));
    tp_Rewrite((tp_file *)&tp_Output,128,1);
}
_Noreturn void tp_Halt(uint16_t code) {
    tp_ExitCode = tp_i16(code);
    while (tp_ExitProc) {
        farptr target = tp_ExitProc;
        tp_ExitProc = 0;
        pc_call_far(target);
    }
    /* System's process finalizer closes the standard text records as well. */
    uint16_t pending_io=io_result;
    io_result=0;
    for (unsigned i=0;i<2;++i) {
        tp_file *f=(tp_file *)tp_StandardAddress((uint8_t)i);
        uint16_t mode=readword(f->bytes+2);
        if (mode==0xd7b1 || mode==0xd7b2) tp_Close(f);
    }
    if (pending_io) io_result=pending_io;
    fflush(stdout);
    pc_terminate((uint8_t)tp_ExitCode);
}
