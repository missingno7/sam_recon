/* Planar write/read pipeline adapted from duke1_recon/port/vga.c.
   Scanout uses CRTC addresses, not a separate game-specific compositor. */
#include "pc_internal.h"
#include <string.h>

static uint8_t planes[4][65536], latch[4];
static uint8_t seq[8], gc[16], crtc[32], attr[32];
static uint8_t si, gi, ci, ai, attr_phase, mode = 3, misc = 0x67;
static int adapter_vga = 1, video_enabled = 1;
static const uint8_t pal200[16] = {
    0,1,2,3,4,5,6,7,16,17,18,19,20,21,22,23
};
static const uint8_t pal350[16] = {
    0,1,2,3,4,5,20,7,56,57,58,59,60,61,62,63
};
static const uint32_t cga[16] = {
    0x000000,0x0000aa,0x00aa00,0x00aaaa,0xaa0000,0xaa00aa,0xaa5500,0xaaaaaa,
    0x555555,0x5555ff,0x55ff55,0x55ffff,0xff5555,0xff55ff,0xffff55,0xffffff
};

void vga_set_adapter(int vga) { adapter_vga = vga != 0; }
int vga_is_vga(void) { return adapter_vga; }
uint8_t vga_mode(void) { return mode; }
uint8_t *vga_plane(int p) { return p >= 0 && p < 4 ? planes[p] : NULL; }
const uint8_t *vga_palette_registers(void) { return attr; }

uint8_t vga_cpu_read(uint16_t off)
{
    for (unsigned p = 0; p < 4; ++p) latch[p] = planes[p][off];
    if (!(gc[5] & 8)) return latch[gc[4] & 3];
    uint8_t match = 0xff;
    for (unsigned p = 0; p < 4; ++p)
        if (gc[7] & (1u << p))
            match &= (gc[2] & (1u << p)) ? latch[p] : (uint8_t)~latch[p];
    return match;
}

void vga_cpu_write(uint16_t off, uint8_t value)
{
    unsigned wm = gc[5] & 3, rotate = gc[3] & 7;
    uint8_t rotated = rotate ? (uint8_t)((value >> rotate) | (value << (8-rotate))) : value;
    uint8_t mask = gc[8];
    if (wm == 3) mask &= rotated;
    for (unsigned p = 0; p < 4; ++p) {
        if (!(seq[2] & (1u << p))) continue;
        if (wm == 1) { planes[p][off] = latch[p]; continue; }
        uint8_t src = rotated;
        if (wm == 2) src = (value & (1u << p)) ? 255 : 0;
        else if (wm == 3 || (gc[1] & (1u << p))) src = (gc[0] & (1u << p)) ? 255 : 0;
        switch ((gc[3] >> 3) & 3) {
        case 1: src &= latch[p]; break;
        case 2: src |= latch[p]; break;
        case 3: src ^= latch[p]; break;
        }
        planes[p][off] = (uint8_t)((src & mask) | (latch[p] & (uint8_t)~mask));
    }
}

int vga_port_write(uint16_t port, uint8_t v)
{
    switch (port) {
    case 0x3c0:
        if (!attr_phase) { ai = v & 31; video_enabled = (v & 32) != 0; }
        else attr[ai] = v & (ai < 16 ? 63 : 255);
        attr_phase ^= 1; return 1;
    case 0x3c2: misc = v; return 1;
    case 0x3c4: si = v & 7; return 1;
    case 0x3c5: seq[si] = v; return 1;
    case 0x3ce: gi = v & 15; return 1;
    case 0x3cf: gc[gi] = v; return 1;
    case 0x3b4: case 0x3d4: ci = v & 31; return 1;
    case 0x3b5: case 0x3d5: crtc[ci] = v; return 1;
    default: return 0;
    }
}

int vga_port_read(uint16_t port, uint8_t *v)
{
    if (!v) return 0;
    switch (port) {
    case 0x3c0: *v = ai; break;
    case 0x3c1: *v = attr[ai]; break;
    case 0x3cc: *v = misc; break;
    case 0x3c2: *v = 0x10; break;
    case 0x3c4: *v = si; break;
    case 0x3c5: *v = seq[si]; break;
    case 0x3ce: *v = gi; break;
    case 0x3cf: *v = gc[gi]; break;
    case 0x3b4: case 0x3d4: *v = ci; break;
    case 0x3b5: case 0x3d5: *v = crtc[ci]; break;
    case 0x3ba: case 0x3da: {
        /* 70 Hz, 449 scanlines, 400 active, 412..413 retrace.
           Bit 0 is high during horizontal OR vertical blanking (display disabled). */
        uint64_t phase = (pc_time_us() * 70u * 449u) % 1000000u;
        unsigned line = (unsigned)((pc_time_us() * 70u * 449u / 1000000u) % 449u);
        *v = (uint8_t)((line >= 412 && line < 414 ? 8 : 0) |
                      (line >= 400 || phase >= 800000u ? 1 : 0));
        attr_phase = 0;
        break;
    }
    default: return 0;
    }
    return 1;
}

void vga_dimensions(int *w, int *h)
{
    *w = mode == 3 ? (adapter_vga ? 720 : 640) : mode == 0x0d ? 320 : 640;
    *h = mode == 3 ? (adapter_vga ? 400 : 350) : mode == 0x10 ? 350 : mode == 0x12 ? 480 : 200;
}

void bios_set_mode(uint8_t m)
{
    uint8_t preserve = m & 0x80;
    m &= 0x7f;
    if (m != 3 && m != 0x0d && m != 0x10 && m != 0x12) {
        fprintf(stderr, "unsupported BIOS video mode %02x\n", m); abort();
    }
    mode = m;
    memset(seq,0,sizeof seq); memset(gc,0,sizeof gc); memset(crtc,0,sizeof crtc);
    memset(attr,0,sizeof attr); memset(latch,0,sizeof latch);
    si = gi = ci = ai = attr_phase = 0; video_enabled = 1;
    seq[2] = 15; gc[7] = 15; gc[8] = 255;
    crtc[0x13] = m == 0x0d ? 20 : 40;
    crtc[0x18] = 255; crtc[7] = 0x10; crtc[9] = 0x40;
    /* VGA mode 0Dh repeats each memory scanline twice before line compare. */
    if (adapter_vga && m == 0x0d) crtc[9] |= 0x80;
    memcpy(attr, m == 0x10 || m == 0x12 ? pal350 : pal200,16);
    attr[0x10] = m == 3 ? 8 : 1; attr[0x12] = 15;
    crtc[0x0a] = adapter_vga ? 14 : 12; crtc[0x0b] = adapter_vga ? 15 : 13;
    pc_wr8(0x40,0x49,m); pc_wr16(0x40,0x4a,m == 0x0d ? 40 : 80);
    pc_wr16(0x40,0x4c,m == 3 ? 4096 : m == 0x0d ? 8192 : m==0x12 ? 40960 : 32768);
    pc_wr16(0x40,0x4e,0); pc_wr16(0x40,0x63,0x3d4);
    pc_wr8(0x40,0x65,m==3 ? 0x29 : m==0x0d ? 0x0a : 0x1a);
    pc_wr8(0x40,0x87,(uint8_t)(0x60|(m==3 ? 1 : 0)|(preserve ? 128 : 0)));
    pc_wr8(0x40,0x89,adapter_vga ? 0x51 : 0);
    pc_wr8(0x40,0x62,0); pc_wr8(0x40,0x84,m==0x12 ? 29 : 24);
    pc_wr16(0x40,0x85,m == 3 ? (adapter_vga ? 16 : 14) : m==0x10 ? 14 : m==0x12 ? 16 : 8);
    for (unsigned p=0;p<8;++p) pc_wr16(0x40,(uint16_t)(0x50+2*p),0);
    pc_wr16(0x40,0x60,(uint16_t)((crtc[10]<<8)|crtc[11]));
    if (!preserve) {
        memset(planes,0,sizeof planes);
        for (unsigned i=0;i<80*25;++i) pc_wr16(0xb800,(uint16_t)(2*i),0x0720);
    }
}

uint32_t vga_colour_rgb(uint8_t v)
{
    if (mode == 0x0d || mode == 3) return cga[(v & 7) | ((v & 16) ? 8 : 0)];
    unsigned r=((v>>2)&1)*170+((v>>5)&1)*85;
    unsigned g=((v>>1)&1)*170+((v>>4)&1)*85;
    unsigned b=(v&1)*170+((v>>3)&1)*85;
    return (r<<16)|(g<<8)|b;
}
uint32_t vga_border_rgb(void) { return 0xff000000u | vga_colour_rgb(attr[0x11]); }

void vga_scanout_dimensions(int *w,int *h)
{
    vga_dimensions(w,h);
    if(mode==0x0d && adapter_vga && (crtc[9]&0x80)) *h=400;
}
static uint8_t pixel(unsigned x, unsigned y,int scanout)
{
    unsigned scale = mode == 0x0d && adapter_vga && (crtc[9]&0x80) ? 2 : 1;
    unsigned compare = crtc[0x18] | ((crtc[7]&16)<<4) | (adapter_vga ? ((crtc[9]&64)<<3) : 0);
    unsigned physical = scanout ? y : y * scale;
    if(scanout) y/=scale;
    unsigned pan = attr[0x13] & 7;
    uint16_t start = (uint16_t)((crtc[12]<<8)|crtc[13]);
    if (physical > compare) {
        y = (physical - compare - 1) / scale;
        start = 0;
        if (attr[0x10]&32) pan = 0;
    }
    unsigned sx = x + pan;
    uint16_t off = (uint16_t)(start + y * (2u*crtc[0x13]) + sx/8);
    uint8_t bit=(uint8_t)(128u>>(sx&7)), colour=0;
    for (unsigned p=0;p<4;++p) if (planes[p][off]&bit) colour |= (uint8_t)(1u<<p);
    return colour & attr[0x12];
}

void vga_render_indexed(uint8_t *out)
{
    int w,h; vga_dimensions(&w,&h);
    if (mode == 3) { memset(out,0,(size_t)w*h); return; }
    for (int y=0;y<h;++y) for (int x=0;x<w;++x) out[y*w+x] = video_enabled ? pixel(x,y,0) : 0;
}

static void render_rgb(uint32_t *out,int scanout)
{
    int w,h;
    if(scanout) vga_scanout_dimensions(&w,&h); else vga_dimensions(&w,&h);
    int blink = ((pc_time_us()/266667u)&1) == 0;
    unsigned font_h = adapter_vga ? 16 : 14, cell_w = adapter_vga ? 9 : 8;
    farptr font = pc_font_pointer(font_h);
    uint16_t cursor=(uint16_t)((crtc[14]<<8)|crtc[15]);
    unsigned start=(crtc[12]<<8)|crtc[13];
    for (int y=0;y<h;++y) for (int x=0;x<w;++x) {
        uint32_t rgb;
        if (mode != 3) rgb=vga_colour_rgb(attr[video_enabled ? pixel(x,y,scanout) : 0]);
        else {
            unsigned col=(unsigned)x/cell_w,row=(unsigned)y/font_h;
            unsigned cell=start+row*80+col;
            uint16_t ch=pc_rd16(0xb800,(uint16_t)(cell*2));
            uint8_t a=(uint8_t)(ch>>8), c=(uint8_t)ch;
            unsigned px=(unsigned)x%cell_w, py=(unsigned)y%font_h;
            uint8_t bits=pc_rd8(FP_SEG(font),(uint16_t)(FP_OFF(font)+c*font_h+py));
            int lit=px<8 ? ((bits>>(7-px))&1) : (c>=0xc0 && c<=0xdf && (bits&1));
            if ((attr[0x10]&8) && (a&128) && !blink) lit=0;
            if (!(crtc[10]&32) && cell==cursor && blink && py>=(crtc[10]&31) && py<=(crtc[11]&31)) lit=1;
            unsigned bg=(a>>4)&((attr[0x10]&8) ? 7 : 15);
            rgb=cga[lit ? a&15 : bg];
        }
        out[y*w+x]=0xff000000u|rgb;
    }
}
void vga_render_rgb(uint32_t *out) { render_rgb(out,0); }
void vga_render_scanout_rgb(uint32_t *out) { render_rgb(out,1); }

void bios_video(pc_regs *r)
{
    unsigned ah=r->ax>>8, al=r->ax&255, bh=r->bx>>8, bl=r->bx&255;
    switch (ah) {
    case 0: bios_set_mode((uint8_t)al); break;
    case 1: crtc[10]=(uint8_t)(r->cx>>8); crtc[11]=(uint8_t)r->cx; pc_wr16(0x40,0x60,r->cx); break;
    case 2:
        pc_wr16(0x40,(uint16_t)(0x50+2*(bh&7)),r->dx);
        if (bh==pc_rd8(0x40,0x62)) {
            unsigned pos=(r->dx>>8)*80+(r->dx&255); crtc[14]=(uint8_t)(pos>>8); crtc[15]=(uint8_t)pos;
        } break;
    case 3: r->cx=pc_rd16(0x40,0x60); r->dx=pc_rd16(0x40,(uint16_t)(0x50+2*(bh&7))); break;
    case 5: pc_wr8(0x40,0x62,(uint8_t)al); crtc[12]=(uint8_t)(al*0x20); crtc[13]=0; break;
    case 8: {
        uint16_t pos=pc_rd16(0x40,(uint16_t)(0x50+2*(bh&7)));
        r->ax=pc_rd16(0xb800,(uint16_t)(bh*4096+((pos>>8)*80+(pos&255))*2)); break;
    }
    case 9: case 10: {
        uint16_t pos=pc_rd16(0x40,(uint16_t)(0x50+2*(bh&7)));
        uint16_t off=(uint16_t)(bh*4096+((pos>>8)*80+(pos&255))*2);
        for (unsigned n=0;n<r->cx;++n) {
            pc_wr8(0xb800,(uint16_t)(off+2*n),(uint8_t)al);
            if (ah==9) pc_wr8(0xb800,(uint16_t)(off+2*n+1),(uint8_t)bl);
        } break;
    }
    case 0x0b: if (!bh) attr[0x11]=(uint8_t)bl; break;
    case 0x0f: r->ax=(uint16_t)((pc_rd16(0x40,0x4a)<<8)|mode); r->bx=(uint16_t)((r->bx&255)|(pc_rd8(0x40,0x62)<<8)); break;
    case 0x10:
        if (al==0 && bl<16) attr[bl]=(uint8_t)(bh&63);
        else if (al==1) attr[0x11]=(uint8_t)(bh&63);
        else if (al==2) for (unsigned i=0;i<17;++i) attr[i<16 ? i : 0x11]=pc_rd8(r->es,(uint16_t)(r->dx+i));
        else if (al==3) attr[0x10]=(uint8_t)((attr[0x10]&~8u)|(bl ? 8 : 0));
        break;
    case 0x11:
        if (al==0x30) {
            unsigned fh=(bh==2 || bh==5) ? 14 : (bh==3 || bh==4) ? 8 : 16;
            farptr f=pc_font_pointer(fh);
            if (bh==4) f+=128*8;
            r->es=FP_SEG(f); r->bp=FP_OFF(f); r->cx=pc_rd16(0x40,0x85); r->dx=(uint16_t)((r->dx&0xff00)|pc_rd8(0x40,0x84));
        } break;
    case 0x12: if (bl==0x10) { r->bx=3; r->cx=9; } break; /* colour, 256 KiB, EGA switches */
    case 0x1a: if (adapter_vga) { r->ax=0x1a; r->bx=8; } break;
    case 0x1b:
        if (adapter_vga && !al && !r->bx) {
            for (unsigned i=0;i<64;++i) pc_wr8(r->es,(uint16_t)(r->di+i),0);
            pc_wr16(r->es,r->di,0x4000); pc_wr16(r->es,(uint16_t)(r->di+2),0xf000);
            for (unsigned i=0;i<30;++i) pc_wr8(r->es,(uint16_t)(r->di+4+i),pc_rd8(0x40,(uint16_t)(0x49+i)));
            pc_wr8(r->es,(uint16_t)(r->di+0x22),24); pc_wr8(r->es,(uint16_t)(r->di+0x25),8);
            pc_wr16(r->es,(uint16_t)(r->di+0x27),16); pc_wr8(r->es,(uint16_t)(r->di+0x29),8);
            r->ax=0x1b;
        } break;
    case 0x1c:
        /* VGA state-size query used by TEXTOUT; EGA leaves AL unsupported. */
        if(adapter_vga && al==0) {
            r->ax=(uint16_t)((r->ax&0xff00)|0x1c);
            r->bx=(uint16_t)(((r->cx&1) ? 2 : 0)+((r->cx&2) ? 1 : 0)+((r->cx&4) ? 12 : 0));
        }
        break;
    default: fprintf(stderr,"unsupported INT10 AH=%02x\n",ah); abort();
    }
}
