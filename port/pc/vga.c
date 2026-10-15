/* Emulate EGA/VGA planar memory, indexed registers, BIOS video calls, and CRTC-driven scanout. */
#include "pc_internal.h"
#include <string.h>
#include <stdlib.h>

static FILE *flip_log;
static int flip_log_checked;
void vga_diagnostics_close(void) {
    if(flip_log)fclose(flip_log);
    flip_log=NULL;flip_log_checked=0;
}
static void trace_flip(uint8_t high) {
    if(!flip_log_checked) {
        const char *path=getenv("SAM_DIAG_FLIPS");
        flip_log=path ? fopen(path,"w") : NULL;flip_log_checked=1;
        if(flip_log)fputs("emu_us,host_us,high\n",flip_log);
    }
    if(flip_log) {
        fprintf(flip_log,"%llu,%llu,%u\n",(unsigned long long)pc_time_us(),
            (unsigned long long)(SDL_GetTicksNS()/1000u),high);fflush(flip_log);
    }
}

static uint8_t planes[4][65536], latch[4];
static uint8_t seq[8], gc[16], crtc[32], attr[32];
static uint8_t si, gi, ci, ai, attr_phase, mode = PC_VIDEO_MODE_TEXT_80X25, misc = 0x67;
static int adapter_vga = 1, video_enabled = 1;

#ifdef SAM_LOCKSTEP
size_t pc_lockstep_vga(uint8_t *out) {
    size_t size = 0;
#define COPY_STATE(x) do { if (out) memcpy(out + size, &(x), sizeof(x)); size += sizeof(x); } while (0)
    COPY_STATE(latch); COPY_STATE(seq); COPY_STATE(gc); COPY_STATE(crtc); COPY_STATE(attr);
    COPY_STATE(si); COPY_STATE(gi); COPY_STATE(ci); COPY_STATE(ai); COPY_STATE(attr_phase);
    COPY_STATE(mode); COPY_STATE(misc); COPY_STATE(adapter_vga); COPY_STATE(video_enabled);
#undef COPY_STATE
    return size;
}
#endif
enum {
    VGA_WRITE_MODE_COPY = 0,
    VGA_WRITE_MODE_LATCH = 1,
    VGA_WRITE_MODE_COLOR_EXPAND = 2,
    VGA_WRITE_MODE_SET_RESET = 3,
    VGA_READ_MODE_COMPARE = 0x08
};
static const uint8_t pal200[16] = {0, 1, 2, 3, 4, 5, 6, 7, 16, 17, 18, 19, 20, 21, 22, 23};
static const uint8_t pal350[16] = {0, 1, 2, 3, 4, 5, 20, 7, 56, 57, 58, 59, 60, 61, 62, 63};
static const uint32_t cga[16] = {0x000000, 0x0000aa, 0x00aa00, 0x00aaaa, 0xaa0000, 0xaa00aa,
                                 0xaa5500, 0xaaaaaa, 0x555555, 0x5555ff, 0x55ff55, 0x55ffff,
                                 0xff5555, 0xff55ff, 0xffff55, 0xffffff};

void vga_set_adapter(int vga) {
    adapter_vga = vga != 0;
}
int vga_is_vga(void) {
    return adapter_vga;
}
uint8_t vga_mode(void) {
    return mode;
}
uint8_t *vga_plane(int p) {
    return p >= 0 && p < 4 ? planes[p] : NULL;
}
/* Presentation cache only. Compare bytes rather than trusting dirty flags:
   callers may legally write through vga_plane() or the plain B800 memory API. */
int vga_scanout_changed(void) {
    static uint8_t old_planes[4][65536],old_crtc[32],old_attr[32];
    static uint8_t old_text[32768],old_font[4096];
    static int valid,old_mode,old_adapter,old_enabled,old_blink;
    int blink=(int)((pc_time_us()/266667u)&1);
    int changed=!valid || old_mode!=mode || old_adapter!=adapter_vga || old_enabled!=video_enabled ||
        memcmp(old_crtc,crtc,sizeof crtc) || memcmp(old_attr,attr,sizeof attr);
    if(mode==PC_VIDEO_MODE_TEXT_80X25) {
        const uint8_t *font=pc_host_fp(pc_font_pointer(adapter_vga ? 16 : 14));
        changed=changed || old_blink!=blink || memcmp(old_text,pc_host(0xb800,0),sizeof old_text) ||
            memcmp(old_font,font,sizeof old_font);
        if(changed){memcpy(old_text,pc_host(0xb800,0),sizeof old_text);memcpy(old_font,font,sizeof old_font);}
    } else {
        changed=changed || memcmp(old_planes,planes,sizeof planes);
        if(changed)memcpy(old_planes,planes,sizeof planes);
    }
    if(changed){memcpy(old_crtc,crtc,sizeof crtc);memcpy(old_attr,attr,sizeof attr);}
    valid=1;old_mode=mode;old_adapter=adapter_vga;old_enabled=video_enabled;old_blink=blink;
    return changed;
}
const uint8_t *vga_palette_registers(void) {
    return attr;
}

/* Load all four VGA latches, then select or compare their contents per GC read mode. */
uint8_t vga_cpu_read(uint16_t off) {
    for (unsigned p = 0; p < 4; ++p)
        latch[p] = planes[p][off];
    if (!(gc[PC_VGA_GC_MODE] & VGA_READ_MODE_COMPARE))
        return latch[gc[PC_VGA_GC_READ_MAP_SELECT] & 3];
    uint8_t match = 0xff;
    for (unsigned p = 0; p < 4; ++p)
        if (gc[PC_VGA_GC_COLOR_DONT_CARE] & (1u << p))
            match &= (gc[PC_VGA_GC_COLOR_COMPARE] & (1u << p)) ? latch[p] : (uint8_t)~latch[p];
    return match;
}

/* Apply the VGA sequencer map mask and graphics-controller write mode to all planes. */
void vga_cpu_write(uint16_t off, uint8_t value) {
    unsigned wm = gc[PC_VGA_GC_MODE] & 3, rotate = gc[PC_VGA_GC_DATA_ROTATE] & 7;
    uint8_t rotated = rotate ? (uint8_t)((value >> rotate) | (value << (8 - rotate))) : value;
    uint8_t mask = gc[PC_VGA_GC_BIT_MASK];
    if (wm == VGA_WRITE_MODE_SET_RESET)
        mask &= rotated;
    for (unsigned p = 0; p < 4; ++p) {
        if (!(seq[PC_VGA_SEQ_MAP_MASK] & (1u << p)))
            continue;
        if (wm == VGA_WRITE_MODE_LATCH) {
            planes[p][off] = latch[p];
            continue;
        }
        uint8_t src = rotated;
        if (wm == VGA_WRITE_MODE_COLOR_EXPAND)
            src = (value & (1u << p)) ? 255 : 0;
        else if (wm == VGA_WRITE_MODE_SET_RESET || (gc[PC_VGA_GC_ENABLE_SET_RESET] & (1u << p)))
            src = (gc[PC_VGA_GC_SET_RESET] & (1u << p)) ? 255 : 0;
        switch ((gc[PC_VGA_GC_DATA_ROTATE] >> 3) & 3) {
        case 1:
            src &= latch[p];
            break;
        case 2:
            src |= latch[p];
            break;
        case 3:
            src ^= latch[p];
            break;
        }
        planes[p][off] = (uint8_t)((src & mask) | (latch[p] & (uint8_t)~mask));
    }
}

/* Track indexed VGA register ports and the attribute controller's index/data phase. */
int vga_port_write(uint16_t port, uint8_t v) {
    switch (port) {
    case PC_PORT_VGA_ATTRIBUTE:
        if (!attr_phase) {
            ai = v & 31;
            video_enabled = (v & 32) != 0;
        } else
            attr[ai] = v & (ai < 16 ? 63 : 255);
        attr_phase ^= 1;
        return 1;
    case PC_PORT_VGA_MISC_WRITE:
        misc = v;
        return 1;
    case PC_PORT_VGA_SEQUENCER_INDEX:
        si = v & 7;
        return 1;
    case PC_PORT_VGA_SEQUENCER_DATA:
        seq[si] = v;
        return 1;
    case PC_PORT_VGA_GRAPHICS_INDEX:
        gi = v & 15;
        return 1;
    case PC_PORT_VGA_GRAPHICS_DATA:
        gc[gi] = v;
        return 1;
    case PC_PORT_CRTC_MONO_INDEX:
    case PC_PORT_CRTC_COLOR_INDEX:
        ci = v & 31;
        return 1;
    case PC_PORT_CRTC_MONO_DATA:
    case PC_PORT_CRTC_COLOR_DATA:
        crtc[ci] = v;
        if(ci==PC_VGA_CRTC_START_ADDRESS_HIGH)trace_flip(v);
        return 1;
    default:
        return 0;
    }
}

/* Return indexed registers and timed blank/retrace bits from the selected VGA status port. */
int vga_port_read(uint16_t port, uint8_t *v) {
    if (!v)
        return 0;
    switch (port) {
    case PC_PORT_VGA_ATTRIBUTE:
        *v = ai;
        break;
    case PC_PORT_VGA_ATTRIBUTE_READ:
        *v = attr[ai];
        break;
    case PC_PORT_VGA_MISC_READ:
        *v = misc;
        break;
    case PC_PORT_VGA_MISC_WRITE:
        *v = 0x10;
        break;
    case PC_PORT_VGA_SEQUENCER_INDEX:
        *v = si;
        break;
    case PC_PORT_VGA_SEQUENCER_DATA:
        *v = seq[si];
        break;
    case PC_PORT_VGA_GRAPHICS_INDEX:
        *v = gi;
        break;
    case PC_PORT_VGA_GRAPHICS_DATA:
        *v = gc[gi];
        break;
    case PC_PORT_CRTC_MONO_INDEX:
    case PC_PORT_CRTC_COLOR_INDEX:
        *v = ci;
        break;
    case PC_PORT_CRTC_MONO_DATA:
    case PC_PORT_CRTC_COLOR_DATA:
        *v = crtc[ci];
        break;
    case PC_PORT_VGA_STATUS_MONO:
    case PC_PORT_VGA_STATUS_COLOR: {
        /* 25.175 MHz / 800 dots / 449 lines = 70.0863 Hz. 400 active, 412..413 retrace.
           Bit 0 is high during horizontal OR vertical blanking (display disabled). */
        uint64_t phase = (pc_time_us() * PC_VIDEO_LINE_DEN) % PC_VIDEO_LINE_NUM;
        unsigned line = (unsigned)(pc_video_line(pc_time_us()) % PC_VIDEO_LINES);
        *v = (uint8_t)((line >= 412 && line < 414 ? 8 : 0) |
                       (line >= 400 || phase >= PC_VIDEO_LINE_NUM*4/5 ? 1 : 0));
        attr_phase = 0;
        break;
    }
    default:
        return 0;
    }
    return 1;
}

void vga_dimensions(int *w, int *h) {
    *w = mode == PC_VIDEO_MODE_TEXT_80X25    ? (adapter_vga ? 720 : 640)
         : mode == PC_VIDEO_MODE_EGA_320X200 ? 320
                                             : 640;
    *h = mode == PC_VIDEO_MODE_TEXT_80X25    ? (adapter_vga ? 400 : 350)
         : mode == PC_VIDEO_MODE_EGA_640X350 ? 350
         : mode == PC_VIDEO_MODE_VGA_640X480 ? 480
                                             : 200;
}

/* Reset EGA/VGA registers and mirror the selected BIOS mode into the BDA. */
void bios_set_mode(uint8_t m) {
    uint8_t preserve = m & 0x80;
    m &= 0x7f;
    if (m != PC_VIDEO_MODE_TEXT_80X25 && m != PC_VIDEO_MODE_EGA_320X200 &&
        m != PC_VIDEO_MODE_EGA_640X350 && m != PC_VIDEO_MODE_VGA_640X480) {
        fprintf(stderr, "unsupported BIOS video mode %02x\n", m);
        abort();
    }
    mode = m;
    memset(seq, 0, sizeof seq);
    memset(gc, 0, sizeof gc);
    memset(crtc, 0, sizeof crtc);
    memset(attr, 0, sizeof attr);
    memset(latch, 0, sizeof latch);
    si = gi = ci = ai = attr_phase = 0;
    video_enabled = 1;
    seq[PC_VGA_SEQ_MAP_MASK] = 15;
    gc[PC_VGA_GC_COLOR_DONT_CARE] = 15;
    gc[PC_VGA_GC_BIT_MASK] = 255;
    crtc[PC_VGA_CRTC_OFFSET] = m == PC_VIDEO_MODE_EGA_320X200 ? 20 : 40;
    crtc[PC_VGA_CRTC_LINE_COMPARE] = 255;
    crtc[PC_VGA_CRTC_OVERFLOW] = 0x10;
    crtc[PC_VGA_CRTC_MAX_SCAN_LINE] = 0x40;
    /* VGA mode 0Dh repeats each memory scanline twice before line compare. */
    if (adapter_vga && m == PC_VIDEO_MODE_EGA_320X200)
        crtc[PC_VGA_CRTC_MAX_SCAN_LINE] |= 0x80;
    memcpy(attr, m == PC_VIDEO_MODE_EGA_640X350 || m == PC_VIDEO_MODE_VGA_640X480 ? pal350 : pal200,
           16);
    attr[PC_VGA_ATTR_MODE_CONTROL] = m == PC_VIDEO_MODE_TEXT_80X25 ? 8 : 1;
    attr[PC_VGA_ATTR_COLOR_PLANE_ENABLE] = 15;
    crtc[PC_VGA_CRTC_CURSOR_START] = adapter_vga ? 14 : 12;
    crtc[PC_VGA_CRTC_CURSOR_END] = adapter_vga ? 15 : 13;
    pc_wr8(PC_BDA_SEGMENT, PC_BDA_VIDEO_MODE, m);
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_VIDEO_COLUMNS, m == PC_VIDEO_MODE_EGA_320X200 ? 40 : 80);
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_VIDEO_PAGE_SIZE,
            m == PC_VIDEO_MODE_TEXT_80X25    ? 4096
            : m == PC_VIDEO_MODE_EGA_320X200 ? 8192
            : m == PC_VIDEO_MODE_VGA_640X480 ? 40960
                                             : 32768);
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_VIDEO_PAGE_OFFSET, 0);
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_VIDEO_CRTC_PORT, PC_PORT_CRTC_COLOR_INDEX);
    pc_wr8(PC_BDA_SEGMENT, PC_BDA_VIDEO_MODE_SELECT,
           m == PC_VIDEO_MODE_TEXT_80X25    ? 0x29
           : m == PC_VIDEO_MODE_EGA_320X200 ? 0x0a
                                            : 0x1a);
    pc_wr8(PC_BDA_SEGMENT, PC_BDA_VIDEO_MODE_OPTIONS,
           (uint8_t)(0x60 | (m == PC_VIDEO_MODE_TEXT_80X25 ? 1 : 0) | (preserve ? 128 : 0)));
    pc_wr8(PC_BDA_SEGMENT, PC_BDA_VIDEO_VGA_INFO, adapter_vga ? 0x51 : 0);
    pc_wr8(PC_BDA_SEGMENT, PC_BDA_VIDEO_ACTIVE_PAGE, 0);
    pc_wr8(PC_BDA_SEGMENT, PC_BDA_VIDEO_ROWS, m == PC_VIDEO_MODE_VGA_640X480 ? 29 : 24);
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_VIDEO_CHARACTER_HEIGHT,
            m == PC_VIDEO_MODE_TEXT_80X25    ? (adapter_vga ? 16 : 14)
            : m == PC_VIDEO_MODE_EGA_640X350 ? 14
            : m == PC_VIDEO_MODE_VGA_640X480 ? 16
                                             : 8);
    for (unsigned p = 0; p < 8; ++p)
        pc_wr16(PC_BDA_SEGMENT, (uint16_t)(PC_BDA_VIDEO_CURSOR_POSITIONS + 2 * p), 0);
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_VIDEO_CURSOR_SHAPE,
            (uint16_t)((crtc[PC_VGA_CRTC_CURSOR_START] << 8) | crtc[PC_VGA_CRTC_CURSOR_END]));
    if (!preserve) {
        memset(planes, 0, sizeof planes);
        for (unsigned i = 0; i < 80 * 25; ++i)
            pc_wr16(PC_VIDEO_TEXT_SEGMENT, (uint16_t)(2 * i), 0x0720);
    }
}

uint32_t vga_colour_rgb(uint8_t v) {
    if (mode == PC_VIDEO_MODE_EGA_320X200 || mode == PC_VIDEO_MODE_TEXT_80X25)
        return cga[(v & 7) | ((v & 16) ? 8 : 0)];
    unsigned r = ((v >> 2) & 1) * 170 + ((v >> 5) & 1) * 85;
    unsigned g = ((v >> 1) & 1) * 170 + ((v >> 4) & 1) * 85;
    unsigned b = (v & 1) * 170 + ((v >> 3) & 1) * 85;
    return (r << 16) | (g << 8) | b;
}
uint32_t vga_border_rgb(void) {
    return 0xff000000u | vga_colour_rgb(attr[PC_VGA_ATTR_OVERSCAN_COLOR]);
}

void vga_scanout_dimensions(int *w, int *h) {
    vga_dimensions(w, h);
    if (mode == PC_VIDEO_MODE_EGA_320X200 && adapter_vga &&
        (crtc[PC_VGA_CRTC_MAX_SCAN_LINE] & 0x80))
        *h = 400;
}
/* Fetch a pixel from planar memory using CRTC start, stride, panning, and line compare. */
static uint8_t pixel(unsigned x, unsigned y, int scanout) {
    unsigned scale =
        mode == PC_VIDEO_MODE_EGA_320X200 && adapter_vga && (crtc[PC_VGA_CRTC_MAX_SCAN_LINE] & 0x80)
            ? 2
            : 1;
    unsigned compare = crtc[PC_VGA_CRTC_LINE_COMPARE] | ((crtc[PC_VGA_CRTC_OVERFLOW] & 16) << 4) |
                       (adapter_vga ? ((crtc[PC_VGA_CRTC_MAX_SCAN_LINE] & 64) << 3) : 0);
    unsigned physical = scanout ? y : y * scale;
    if (scanout)
        y /= scale;
    unsigned pan = attr[PC_VGA_ATTR_PEL_PANNING] & 7;
    uint16_t start = (uint16_t)((crtc[PC_VGA_CRTC_START_ADDRESS_HIGH] << 8) |
                                crtc[PC_VGA_CRTC_START_ADDRESS_LOW]);
    if (physical > compare) {
        y = (physical - compare - 1) / scale;
        start = 0;
        if (attr[PC_VGA_ATTR_MODE_CONTROL] & 32)
            pan = 0;
    }
    unsigned sx = x + pan;
    uint16_t off = (uint16_t)(start + y * (2u * crtc[PC_VGA_CRTC_OFFSET]) + sx / 8);
    uint8_t bit = (uint8_t)(128u >> (sx & 7)), colour = 0;
    for (unsigned p = 0; p < 4; ++p)
        if (planes[p][off] & bit)
            colour |= (uint8_t)(1u << p);
    return colour & attr[PC_VGA_ATTR_COLOR_PLANE_ENABLE];
}

/* Render planar display modes as palette indices; text mode is composed by render_rgb. */
void vga_render_indexed(uint8_t *out) {
    int w, h;
    vga_dimensions(&w, &h);
    if (mode == PC_VIDEO_MODE_TEXT_80X25) {
        memset(out, 0, (size_t)w * h);
        return;
    }
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x)
            out[y * w + x] = video_enabled ? pixel(x, y, 0) : 0;
}

/* Decode each planar byte once, hoisting palette/CRTC work out of the pixel
   loop. The nibble expansion is computed from bits, not from game/ROM data. */
static void render_planar_rgb(uint32_t *out,int w,int h,int scanout) {
    static uint32_t spread[256];static int initialized;
    if(!initialized) {
        for(unsigned n=0;n<256;++n)
            for(unsigned bit=0;bit<8;++bit)spread[n]|=((n>>(7-bit))&1u)<<(4*bit);
        initialized=1;
    }
    uint32_t colours[16];
    for(unsigned n=0;n<16;++n)
        colours[n]=0xff000000u|vga_colour_rgb(attr[video_enabled ? n&attr[PC_VGA_ATTR_COLOR_PLANE_ENABLE] : 0]);
    unsigned scale=mode==PC_VIDEO_MODE_EGA_320X200 && adapter_vga &&
        (crtc[PC_VGA_CRTC_MAX_SCAN_LINE]&0x80) ? 2 : 1;
    unsigned compare=crtc[PC_VGA_CRTC_LINE_COMPARE]|((crtc[PC_VGA_CRTC_OVERFLOW]&16)<<4)|
        (adapter_vga ? ((crtc[PC_VGA_CRTC_MAX_SCAN_LINE]&64)<<3) : 0);
    unsigned initial=(crtc[PC_VGA_CRTC_START_ADDRESS_HIGH]<<8)|crtc[PC_VGA_CRTC_START_ADDRESS_LOW];
    unsigned previous=UINT32_MAX,previous_pan=0;
    for(int line=0;line<h;++line) {
        unsigned physical=scanout ? (unsigned)line : (unsigned)line*scale;
        unsigned row=scanout ? (unsigned)line/scale : (unsigned)line;
        unsigned start=initial,pan=attr[PC_VGA_ATTR_PEL_PANNING]&7;
        if(physical>compare) {
            row=(physical-compare-1)/scale;start=0;
            if(attr[PC_VGA_ATTR_MODE_CONTROL]&32)pan=0;
        }
        unsigned base=(uint16_t)(start+row*(2u*crtc[PC_VGA_CRTC_OFFSET]));
        uint32_t *dest=out+line*w;
        if(base==previous && pan==previous_pan) {memcpy(dest,dest-w,(size_t)w*4);continue;}
        previous=base;previous_pan=pan;
        unsigned x=0,skip=pan;
        uint16_t offset=(uint16_t)base;
        while(x<(unsigned)w) {
            uint32_t packed=spread[planes[0][offset]]|(spread[planes[1][offset]]<<1)|
                (spread[planes[2][offset]]<<2)|(spread[planes[3][offset]]<<3);
            packed>>=skip*4;
            unsigned count=8-skip;if(count>(unsigned)w-x)count=(unsigned)w-x;
            for(unsigned n=0;n<count;++n) {dest[x++]=colours[packed&15];packed>>=4;}
            skip=0;++offset;
        }
    }
}
/* Compose text glyphs or planar pixels at the active adapter's physical scanout size. */
static void render_rgb(uint32_t *out, int scanout) {
    int w, h;
    if (scanout)
        vga_scanout_dimensions(&w, &h);
    else
        vga_dimensions(&w, &h);
    if(mode!=PC_VIDEO_MODE_TEXT_80X25) {render_planar_rgb(out,w,h,scanout);return;}
    int blink = ((pc_time_us() / 266667u) & 1) == 0;
    unsigned font_h = adapter_vga ? 16 : 14, cell_w = adapter_vga ? 9 : 8;
    farptr font = pc_font_pointer(font_h);
    uint16_t cursor = (uint16_t)((crtc[PC_VGA_CRTC_CURSOR_LOCATION_HIGH] << 8) |
                                 crtc[PC_VGA_CRTC_CURSOR_LOCATION_LOW]);
    unsigned start =
        (crtc[PC_VGA_CRTC_START_ADDRESS_HIGH] << 8) | crtc[PC_VGA_CRTC_START_ADDRESS_LOW];
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) {
            uint32_t rgb;
            if (mode != PC_VIDEO_MODE_TEXT_80X25)
                rgb = vga_colour_rgb(attr[video_enabled ? pixel(x, y, scanout) : 0]);
            else {
                unsigned col = (unsigned)x / cell_w, row = (unsigned)y / font_h;
                unsigned cell = start + row * 80 + col;
                uint16_t ch = pc_rd16(PC_VIDEO_TEXT_SEGMENT, (uint16_t)(cell * 2));
                uint8_t a = (uint8_t)(ch >> 8), c = (uint8_t)ch;
                unsigned px = (unsigned)x % cell_w, py = (unsigned)y % font_h;
                uint8_t bits = pc_rd8(FP_SEG(font), (uint16_t)(FP_OFF(font) + c * font_h + py));
                int lit =
                    px < 8 ? ((bits >> (7 - px)) & 1) : (c >= 0xc0 && c <= 0xdf && (bits & 1));
                if ((attr[PC_VGA_ATTR_MODE_CONTROL] & 8) && (a & 128) && !blink)
                    lit = 0;
                if (!(crtc[PC_VGA_CRTC_CURSOR_START] & 32) && cell == cursor && blink &&
                    py >= (crtc[PC_VGA_CRTC_CURSOR_START] & 31) &&
                    py <= (crtc[PC_VGA_CRTC_CURSOR_END] & 31))
                    lit = 1;
                unsigned bg = (a >> 4) & ((attr[PC_VGA_ATTR_MODE_CONTROL] & 8) ? 7 : 15);
                rgb = cga[lit ? a & 15 : bg];
            }
            out[y * w + x] = 0xff000000u | rgb;
        }
}
void vga_render_rgb(uint32_t *out) {
    render_rgb(out, 0);
}
void vga_render_scanout_rgb(uint32_t *out) {
    render_rgb(out, 1);
}

/* Implement the INT 10h video subset used for mode, cursor, text, palette, and font queries. */
void bios_video(pc_regs *r) {
    unsigned ah = r->ax >> 8, al = r->ax & 255, bh = r->bx >> 8, bl = r->bx & 255;
    switch (ah) {
    case PC_VIDEO_FN_SET_MODE:
        bios_set_mode((uint8_t)al);
        break;
    case PC_VIDEO_FN_SET_CURSOR_SHAPE:
        crtc[PC_VGA_CRTC_CURSOR_START] = (uint8_t)(r->cx >> 8);
        crtc[PC_VGA_CRTC_CURSOR_END] = (uint8_t)r->cx;
        pc_wr16(PC_BDA_SEGMENT, PC_BDA_VIDEO_CURSOR_SHAPE, r->cx);
        break;
    case PC_VIDEO_FN_SET_CURSOR_POSITION:
        pc_wr16(PC_BDA_SEGMENT, (uint16_t)(PC_BDA_VIDEO_CURSOR_POSITIONS + 2 * (bh & 7)), r->dx);
        if (bh == pc_rd8(PC_BDA_SEGMENT, PC_BDA_VIDEO_ACTIVE_PAGE)) {
            unsigned pos = (r->dx >> 8) * 80 + (r->dx & 255);
            crtc[PC_VGA_CRTC_CURSOR_LOCATION_HIGH] = (uint8_t)(pos >> 8);
            crtc[PC_VGA_CRTC_CURSOR_LOCATION_LOW] = (uint8_t)pos;
        }
        break;
    case PC_VIDEO_FN_GET_CURSOR_POSITION:
        r->cx = pc_rd16(PC_BDA_SEGMENT, PC_BDA_VIDEO_CURSOR_SHAPE);
        r->dx = pc_rd16(PC_BDA_SEGMENT, (uint16_t)(PC_BDA_VIDEO_CURSOR_POSITIONS + 2 * (bh & 7)));
        break;
    case PC_VIDEO_FN_SET_ACTIVE_PAGE:
        pc_wr8(PC_BDA_SEGMENT, PC_BDA_VIDEO_ACTIVE_PAGE, (uint8_t)al);
        crtc[PC_VGA_CRTC_START_ADDRESS_HIGH] = (uint8_t)(al * 0x20);
        crtc[PC_VGA_CRTC_START_ADDRESS_LOW] = 0;
        break;
    case 0x06: /* Scroll text window up; AL=0 clears it. */
    case 0x07: { /* Scroll text window down. Cursor position is preserved. */
        unsigned columns=pc_rd16(PC_BDA_SEGMENT,PC_BDA_VIDEO_COLUMNS);
        unsigned rows=pc_rd8(PC_BDA_SEGMENT,0x84)+1u;
        unsigned left=r->cx&255u, top=r->cx>>8, right=r->dx&255u, bottom=r->dx>>8;
        if (!columns || !rows || left>=columns || top>=rows) break;
        if (right>=columns) right=columns-1;
        if (bottom>=rows) bottom=rows-1;
        if (left>right || top>bottom) break;
        unsigned height=bottom-top+1, count=al && al<height ? al : height;
        uint16_t segment=mode==7 ? 0xb000 : PC_VIDEO_TEXT_SEGMENT;
        unsigned page=pc_rd8(PC_BDA_SEGMENT,PC_BDA_VIDEO_ACTIVE_PAGE)*4096u;
        for (unsigned n=0;n<height;++n) {
            unsigned dest=ah==6 ? top+n : bottom-n;
            for (unsigned col=left;col<=right;++col) {
                uint16_t value=(uint16_t)((bh<<8)|32u);
                if (n+count<height) {
                    unsigned source=ah==6 ? dest+count : dest-count;
                    value=pc_rd16(segment,(uint16_t)(page+(source*columns+col)*2));
                }
                pc_wr16(segment,(uint16_t)(page+(dest*columns+col)*2),value);
            }
        }
        break;
    }
    case PC_VIDEO_FN_READ_CHARACTER: {
        uint16_t pos =
            pc_rd16(PC_BDA_SEGMENT, (uint16_t)(PC_BDA_VIDEO_CURSOR_POSITIONS + 2 * (bh & 7)));
        r->ax = pc_rd16(PC_VIDEO_TEXT_SEGMENT,
                        (uint16_t)(bh * 4096 + ((pos >> 8) * 80 + (pos & 255)) * 2));
        break;
    }
    case PC_VIDEO_FN_WRITE_CHARACTER_ATTRIBUTE:
    case PC_VIDEO_FN_WRITE_CHARACTER: {
        uint16_t pos =
            pc_rd16(PC_BDA_SEGMENT, (uint16_t)(PC_BDA_VIDEO_CURSOR_POSITIONS + 2 * (bh & 7)));
        uint16_t off = (uint16_t)(bh * 4096 + ((pos >> 8) * 80 + (pos & 255)) * 2);
        for (unsigned n = 0; n < r->cx; ++n) {
            pc_wr8(PC_VIDEO_TEXT_SEGMENT, (uint16_t)(off + 2 * n), (uint8_t)al);
            if (ah == 9)
                pc_wr8(PC_VIDEO_TEXT_SEGMENT, (uint16_t)(off + 2 * n + 1), (uint8_t)bl);
        }
        break;
    }
    case PC_VIDEO_FN_SET_OVERSCAN:
        if (!bh)
            attr[PC_VGA_ATTR_OVERSCAN_COLOR] = (uint8_t)bl;
        break;
    case PC_VIDEO_FN_GET_MODE:
        r->ax = (uint16_t)((pc_rd16(PC_BDA_SEGMENT, PC_BDA_VIDEO_COLUMNS) << 8) | mode);
        r->bx = (uint16_t)((r->bx & 255) | (pc_rd8(PC_BDA_SEGMENT, PC_BDA_VIDEO_ACTIVE_PAGE) << 8));
        break;
    case PC_VIDEO_FN_PALETTE:
        if (al == 0 && bl < 16)
            attr[bl] = (uint8_t)(bh & 63);
        else if (al == 1)
            attr[PC_VGA_ATTR_OVERSCAN_COLOR] = (uint8_t)(bh & 63);
        else if (al == 2)
            for (unsigned i = 0; i < 17; ++i)
                attr[i < 16 ? i : PC_VGA_ATTR_OVERSCAN_COLOR] =
                    pc_rd8(r->es, (uint16_t)(r->dx + i));
        else if (al == 3)
            attr[PC_VGA_ATTR_MODE_CONTROL] =
                (uint8_t)((attr[PC_VGA_ATTR_MODE_CONTROL] & ~8u) | (bl ? 8 : 0));
        break;
    case PC_VIDEO_FN_FONT:
        if (al == PC_VIDEO_FONT_QUERY_INFO) {
            unsigned fh = (bh == 2 || bh == 5) ? 14 : (bh == 3 || bh == 4) ? 8 : 16;
            farptr f = pc_font_pointer(fh);
            if (bh == 4)
                f += 128 * 8;
            r->es = FP_SEG(f);
            r->bp = FP_OFF(f);
            r->cx = pc_rd16(PC_BDA_SEGMENT, PC_BDA_VIDEO_CHARACTER_HEIGHT);
            r->dx = (uint16_t)((r->dx & 0xff00) | pc_rd8(PC_BDA_SEGMENT, PC_BDA_VIDEO_ROWS));
        }
        break;
    case PC_VIDEO_FN_EGA_INFO:
        if (bl == PC_VIDEO_EGA_QUERY_SWITCHES) {
            r->bx = 3;
            r->cx = 9;
        }
        break; /* colour, 256 KiB, EGA switches */
    case PC_VIDEO_FN_DISPLAY_COMBINATION:
        if (adapter_vga) {
            r->ax = PC_VIDEO_FN_DISPLAY_COMBINATION;
            r->bx = 8;
        }
        break;
    case PC_VIDEO_FN_VGA_STATE_INFO:
        if (adapter_vga && !al && !r->bx) {
            for (unsigned i = 0; i < 64; ++i)
                pc_wr8(r->es, (uint16_t)(r->di + i), 0);
            pc_wr16(r->es, r->di, 0x4000);
            pc_wr16(r->es, (uint16_t)(r->di + 2), 0xf000);
            for (unsigned i = 0; i < 30; ++i)
                pc_wr8(r->es, (uint16_t)(r->di + 4 + i),
                       pc_rd8(PC_BDA_SEGMENT, (uint16_t)(PC_BDA_VIDEO_MODE + i)));
            pc_wr8(r->es, (uint16_t)(r->di + 0x22), 24);
            pc_wr8(r->es, (uint16_t)(r->di + 0x25), 8);
            pc_wr16(r->es, (uint16_t)(r->di + 0x27), 16);
            pc_wr8(r->es, (uint16_t)(r->di + 0x29), 8);
            r->ax = PC_VIDEO_FN_VGA_STATE_INFO;
        }
        break;
    case PC_VIDEO_FN_VGA_STATE_SIZE:
        /* VGA state-size query used by TEXTOUT; EGA leaves AL unsupported. */
        if (adapter_vga && al == 0) {
            r->ax = (uint16_t)((r->ax & 0xff00) | PC_VIDEO_FN_VGA_STATE_SIZE);
            r->bx =
                (uint16_t)(((r->cx & 1) ? 2 : 0) + ((r->cx & 2) ? 1 : 0) + ((r->cx & 4) ? 12 : 0));
        }
        break;
    default:
        fprintf(stderr, "unsupported INT10 AH=%02x\n", ah);
        abort();
    }
}
