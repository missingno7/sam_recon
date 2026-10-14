/* Demonstrate an emulated VGA line-compare split with panning and PC-speaker output. */
#include "pc/platform.h"
#include "tp/crt_dos.h"
#include <stdio.h>
/* Program an indexed CRTC register for the panned scanout demonstration. */
static void crtc(unsigned r, unsigned v) {
    pc_outw(PC_PORT_CRTC_COLOR_INDEX, (uint16_t)(r | (v << 8)));
}
/* Reset the attribute-controller index/data phase before writing a register. */
static void attr(unsigned r, unsigned v) {
    (void)pc_inb(PC_PORT_VGA_STATUS_COLOR);
    pc_outb(PC_PORT_VGA_ATTRIBUTE, (uint8_t)(r | 32));
    pc_outb(PC_PORT_VGA_ATTRIBUTE, (uint8_t)v);
}
/* Draw the split-screen test pattern and run a PIT-driven panning/speaker demo. */
int main(int argc, char **argv) {
    if (!platform_init(argc, argv))
        return 2;
    pc_program p = {PC_PSP_SEG, 0x3100, 0x3900, 0x4000, 0x3d00, PC_VIDEO_PLANAR_SEGMENT};
    pc_load_program(&p, NULL, 0);
    bios_set_mode(PC_VIDEO_MODE_EGA_320X200);
    crtc(PC_VGA_CRTC_OFFSET, 40);
    for (unsigned y = 0; y < 416; ++y)
        for (unsigned x = 0; x < 640; ++x) {
            unsigned c = y < 16 ? ((x / 20) & 15) : (((x / 32) + (y / 32)) & 15);
            if (y >= 16 && (x % 32 == 0 || y % 32 == 16))
                c = 15;
            unsigned off = y * 80 + x / 8;
            uint8_t bit = (uint8_t)(128 >> (x & 7));
            for (unsigned plane = 0; plane < 4; ++plane)
                if (c & (1u << plane))
                    vga_plane((int)plane)[off] |= bit;
        }
    attr(PC_VGA_ATTR_MODE_CONTROL, 0x21);
    crtc(PC_VGA_CRTC_LINE_COMPARE, 0x80);
    crtc(PC_VGA_CRTC_OVERFLOW, 0x10);
    crtc(PC_VGA_CRTC_MAX_SCAN_LINE, 0x80);
    tp_Sound(440);
    uint64_t last = UINT64_MAX;
    while (!platform_quit_requested()) {
        unsigned pan = (unsigned)(pc_time_us() / 10000u) % 321;
        if (pan != last) {
            unsigned start = 16 * 80 + (pan >> 3);
            crtc(PC_VGA_CRTC_START_ADDRESS_HIGH, start >> 8);
            crtc(PC_VGA_CRTC_START_ADDRESS_LOW, start & 255);
            attr(PC_VGA_ATTR_PEL_PANNING, pan & 7);
            last = pan;
        }
        if (pc_time_us() > 250000)
            tp_NoSound();
        pc_poll();
    }
    printf("demo complete at %llu us\n", (unsigned long long)pc_time_us());
    platform_shutdown();
    return 0;
}
