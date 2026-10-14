/* Exercise real-mode memory, BIOS services, VGA registers, PIT, speaker, keyboard, and DOS. */
#include "pc/platform.h"
#include "tp/crt_dos.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CHECK(e)                                                                                   \
    do {                                                                                           \
        if (!(e)) {                                                                                \
            fprintf(stderr, "FAIL line %d: %s\n", __LINE__, #e);                                   \
            exit(1);                                                                               \
        }                                                                                          \
    } while (0)
static const pc_program placement = {PC_PSP_SEG, 0x3100, 0x3900,
                                     0x4000,     0x3d00, PC_VIDEO_PLANAR_SEGMENT};
/* Restore a blank program, deterministic clock, and bound Crt DATA for each isolated test. */
static void reset(void) {
    pc_load_program(&placement, NULL, 0);
    pc_clock_manual(1);
    const tp_crt_offsets o = {0x100, 0x101, 0x102, 0x103, 0x104, 0x106, 0x108, 0x10a};
    tp_BindCrt(placement.ds_seg, &o);
}
/* Select and write a graphics-controller register through its indexed I/O port. */
static void gc(unsigned i, unsigned v) {
    pc_outw(PC_PORT_VGA_GRAPHICS_INDEX, (uint16_t)(i | (v << 8)));
}
/* Select and write a sequencer register through the VGA port pair. */
static void seq(unsigned i, unsigned v) {
    pc_outw(PC_PORT_VGA_SEQUENCER_INDEX, (uint16_t)(i | (v << 8)));
}
/* Select and write a CRTC register used for mode geometry and scanout. */
static void crtc(unsigned i, unsigned v) {
    pc_outw(PC_PORT_CRTC_COLOR_INDEX, (uint16_t)(i | (v << 8)));
}
/* Reset the attribute-controller flip-flop before writing its index and data bytes. */
static void attr(unsigned i, unsigned v) {
    (void)pc_inb(PC_PORT_VGA_STATUS_COLOR);
    pc_outb(PC_PORT_VGA_ATTRIBUTE, (uint8_t)(i | 32));
    pc_outb(PC_PORT_VGA_ATTRIBUTE, (uint8_t)v);
}
/* Enable one sequencer plane before sending a CPU write through VGA's graphics pipeline. */
static void plane_write(unsigned p, uint16_t o, uint8_t v) {
    seq(PC_VGA_SEQ_MAP_MASK, 1u << p);
    vga_cpu_write(o, v);
}

/* Verify PSP/BDA/IVT setup, segmented access, 16-bit offset wrap, and the 20-bit alias. */
static void test_memory(void) {
    uint8_t image[] = {0x19, 0x37, 0x55, 0x81};
    pc_load_program(&placement, image, sizeof image);
    pc_clock_manual(1);
    CHECK(!memcmp(pc_host(placement.ds_seg, 0), image, sizeof image));
    CHECK(pc_current_program()->ss_seg == 0x3900);
    CHECK(pc_rd16(PC_PSP_SEG, 0) == 0x20cd && pc_rd16(PC_PSP_SEG, 2) == PC_VIDEO_PLANAR_SEGMENT);
    CHECK(pc_rd16(PC_PSP_SEG, 0x2c) == PC_PSP_SEG - 0x10);
    CHECK(pc_rd16(PC_BDA_SEGMENT, PC_BDA_MEMORY_KB) == 640 &&
          pc_rd16(PC_BDA_SEGMENT, PC_BDA_VIDEO_CRTC_PORT) == PC_PORT_CRTC_COLOR_INDEX);
    CHECK(pc_rd16(PC_IVT_SEGMENT, PC_INT_TIMER * PC_IVT_ENTRY_SIZE + 2) == PC_BIOS_ROM_SEGMENT);
    pc_wr16(0x5000, 0xffff, 0xabcd);
    CHECK(pc_rd8(0x5000, 0xffff) == 0xcd && pc_rd8(0x5000, 0) == 0xab);
    CHECK(pc_rd16(0x5000, 0xffff) == 0xabcd);
    pc_wr8(0xffff, 0x20, 0x5b);
    CHECK(pc_rd8(0, 0x10) == 0x5b && pc_mem[0x100010] == 0x5b);
    puts("PASS memory/program/BIOS placement and 20-bit/offset wrapping");
}
/* Verify VGA map masks, write modes, set/reset, ALU, latches, and read comparison. */
static void test_vga(void) {
    reset();
    bios_set_mode(PC_VIDEO_MODE_EGA_320X200);
    seq(PC_VGA_SEQ_MAP_MASK, 5);
    vga_cpu_write(0x100, 0xa5);
    CHECK(vga_plane(0)[0x100] == 0xa5 && vga_plane(1)[0x100] == 0 && vga_plane(2)[0x100] == 0xa5);
    seq(PC_VGA_SEQ_MAP_MASK, 15);
    gc(PC_VGA_GC_MODE, 2);
    vga_cpu_write(0x110, 5);
    for (unsigned p = 0; p < 4; ++p)
        CHECK(vga_plane((int)p)[0x110] == ((p == 0 || p == 2) ? 255 : 0));
    gc(PC_VGA_GC_MODE, 0);
    gc(PC_VGA_GC_SET_RESET, 5);
    gc(PC_VGA_GC_ENABLE_SET_RESET, 5);
    vga_cpu_write(0x120, 0);
    CHECK(vga_plane(0)[0x120] == 255 && vga_plane(1)[0x120] == 0 && vga_plane(2)[0x120] == 255);
    gc(PC_VGA_GC_ENABLE_SET_RESET, 0);
    for (unsigned p = 0; p < 4; ++p)
        plane_write(p, 0x130, 0x55);
    seq(PC_VGA_SEQ_MAP_MASK, 15);
    gc(PC_VGA_GC_BIT_MASK, 0xf0);
    (void)vga_cpu_read(0x130);
    vga_cpu_write(0x130, 0xaa);
    for (unsigned p = 0; p < 4; ++p)
        CHECK(vga_plane((int)p)[0x130] == 0xa5);
    gc(PC_VGA_GC_BIT_MASK, 255);
    plane_write(0, 0x138, 15);
    (void)vga_cpu_read(0x138);
    gc(PC_VGA_GC_DATA_ROTATE, 0x10);
    vga_cpu_write(0x138, 0xf0);
    CHECK(vga_plane(0)[0x138] == 255);
    gc(PC_VGA_GC_DATA_ROTATE, 1);
    vga_cpu_write(0x139, 3);
    CHECK(vga_plane(0)[0x139] == 0x81);
    gc(PC_VGA_GC_DATA_ROTATE, 0);
    for (unsigned p = 0; p < 4; ++p)
        plane_write(p, 0x140, (uint8_t)(0x12 + 0x22 * p));
    seq(PC_VGA_SEQ_MAP_MASK, 15);
    gc(PC_VGA_GC_MODE, 1);
    (void)vga_cpu_read(0x140);
    vga_cpu_write(0x150, 0xff);
    for (unsigned p = 0; p < 4; ++p)
        CHECK(vga_plane((int)p)[0x150] == 0x12 + 0x22 * p);
    gc(PC_VGA_GC_MODE, 0);
    gc(PC_VGA_GC_READ_MAP_SELECT, 2);
    CHECK(vga_cpu_read(0x140) == 0x56);
    plane_write(0, 0x160, 0xf0);
    plane_write(1, 0x160, 0xcc);
    plane_write(2, 0x160, 0xaa);
    plane_write(3, 0x160, 0);
    gc(PC_VGA_GC_COLOR_COMPARE, 5);
    gc(PC_VGA_GC_COLOR_DONT_CARE, 5);
    gc(PC_VGA_GC_MODE, 8);
    CHECK(vga_cpu_read(0x160) == 0xa0);
    puts("PASS VGA write modes, map mask, set/reset, rotation, ALU, latches, read compare");
}
static unsigned pattern(unsigned x, unsigned y) {
    return ((x / 7) ^ (y / 3)) & 15;
}
/* Set one pixel bit in each selected EGA plane using the mode-0D 80-byte stride. */
static void set_pixel(unsigned x, unsigned y, unsigned c) {
    uint16_t off = (uint16_t)(y * 80 + x / 8);
    uint8_t bit = (uint8_t)(128 >> (x & 7));
    for (unsigned p = 0; p < 4; ++p)
        if (c & (1u << p))
            vga_plane((int)p)[off] |= bit;
}
/* Verify CRTC start address, pel panning, line compare, adapter scanout, and retrace timing. */
static void test_scanout(void) {
    static uint8_t out[640 * 480];
    static uint32_t physical[640 * 480];
    reset();
    bios_set_mode(PC_VIDEO_MODE_EGA_320X200);
    for (unsigned y = 0; y < 400; ++y)
        for (unsigned x = 0; x < 640; ++x)
            set_pixel(x, y, pattern(x, y));
    crtc(PC_VGA_CRTC_OFFSET, 40);
    unsigned start = 16 * 80 + 5;
    crtc(PC_VGA_CRTC_START_ADDRESS_HIGH, start >> 8);
    crtc(PC_VGA_CRTC_START_ADDRESS_LOW, start & 255);
    attr(PC_VGA_ATTR_PEL_PANNING, 3);
    attr(PC_VGA_ATTR_MODE_CONTROL, 0x21);
    crtc(PC_VGA_CRTC_LINE_COMPARE, 0x80);
    crtc(PC_VGA_CRTC_OVERFLOW, 0x10);
    crtc(PC_VGA_CRTC_MAX_SCAN_LINE, 0x80);
    vga_render_indexed(out);
    /* VGA compare 384: reset after that physical line, retaining odd phase. */
    for (unsigned y = 0; y < 200; ++y)
        for (unsigned x = 0; x < 320; ++x)
            CHECK(out[y * 320 + x] == (y <= 192 ? pattern(x + 43, y + 16) : pattern(x, y - 193)));
    vga_render_scanout_rgb(physical);
    const uint8_t *palette = vga_palette_registers();
    for (unsigned y = 0; y < 400; ++y)
        for (unsigned x = 0; x < 320; ++x) {
            unsigned c = y <= 384 ? pattern(x + 43, y / 2 + 16) : pattern(x, (y - 385) / 2);
            CHECK(physical[y * 320 + x] == (0xff000000u | vga_colour_rgb(palette[c])));
        }
    CHECK(platform_screenshot("split-vga.png"));
    vga_set_adapter(0);
    bios_set_mode(PC_VIDEO_MODE_EGA_320X200);
    for (unsigned y = 0; y < 400; ++y)
        for (unsigned x = 0; x < 640; ++x)
            set_pixel(x, y, pattern(x, y));
    crtc(PC_VGA_CRTC_OFFSET, 40);
    crtc(PC_VGA_CRTC_START_ADDRESS_HIGH, start >> 8);
    crtc(PC_VGA_CRTC_START_ADDRESS_LOW, start & 255);
    attr(PC_VGA_ATTR_PEL_PANNING, 3);
    attr(PC_VGA_ATTR_MODE_CONTROL, 0x21);
    crtc(PC_VGA_CRTC_LINE_COMPARE, 190);
    crtc(PC_VGA_CRTC_OVERFLOW, 0x01); /* EGA ignores VGA-only line-compare bit 9 */
    vga_render_indexed(out);
    for (unsigned y = 0; y < 200; ++y)
        for (unsigned x = 0; x < 320; ++x)
            CHECK(out[y * 320 + x] == (y <= 190 ? pattern(x + 43, y + 16) : pattern(x, y - 191)));
    CHECK(platform_screenshot("split-ega.png"));
    attr(PC_VGA_ATTR_MODE_CONTROL, 1);
    vga_render_indexed(out);
    CHECK(out[191 * 320] == pattern(3, 0));
    vga_set_adapter(1);
    bios_set_mode(PC_VIDEO_MODE_EGA_640X350);
    int w, h;
    vga_dimensions(&w, &h);
    CHECK(w == 640 && h == 350);
    bios_set_mode(PC_VIDEO_MODE_VGA_640X480);
    vga_dimensions(&w, &h);
    CHECK(w == 640 && h == 480);
    /* Both retrace and display-enable phases are functions of clock, never read count. */
    pc_clock_advance(0);
    CHECK((pc_inb(PC_PORT_VGA_STATUS_COLOR) & 9) == 0);
    CHECK(pc_inb(PC_PORT_VGA_STATUS_COLOR) == pc_inb(PC_PORT_VGA_STATUS_COLOR));
    pc_clock_advance(26);
    CHECK((pc_inb(PC_PORT_VGA_STATUS_COLOR) & 1) == 1);
    pc_clock_advance(13110);
    CHECK((pc_inb(PC_PORT_VGA_STATUS_COLOR) & 8) == 8);
    pc_clock_advance(13200);
    CHECK((pc_inb(PC_PORT_VGA_STATUS_COLOR) & 8) == 0);
    puts("PASS CRTC stride/start/panning, EGA/VGA split phase, modes, timed retrace");
}
/* Verify B800 text cells and the Crt/INT 10h cursor, attribute, blink, and font behavior. */
static void test_text(void) {
    static uint32_t out[720 * 480];
    reset();
    tp_CrtInit();
    tp_TextColor(14);
    tp_TextBackground(1);
    tp_Window(3, 2, 7, 4);
    tp_ClrScr();
    const uint8_t msg[] = "Hello";
    tp_CrtWrite(msg, 5);
    CHECK(pc_rd16(PC_VIDEO_TEXT_SEGMENT, ((1 * 80) + 2) * 2) == 0x1e48);
    CHECK(tp_WhereX() == 1 && tp_WhereY() == 2);
    tp_GotoXY(3, 2);
    CHECK(tp_WhereX() == 3);
    tp_ClrEol();
    tp_Window(1, 1, 80, 25);
    tp_ClrScr();
    for (unsigned c = 0; c < 256; ++c)
        pc_wr16(PC_VIDEO_TEXT_SEGMENT, (uint16_t)(c * 2), (uint16_t)(0x1700 | c));
    crtc(PC_VGA_CRTC_CURSOR_START, 32);
    vga_render_rgb(out);
    unsigned lit = 0;
    for (unsigned y = 0; y < 16; ++y)
        for (unsigned xx = 0; xx < 9; ++xx)
            if (out[y * 720 + 65 * 9 + xx] == 0xffaaaaaa)
                ++lit;
    CHECK(lit > 0 && lit < 144);
    CHECK(platform_screenshot("text-cp437.png"));
    pc_wr16(PC_VIDEO_TEXT_SEGMENT, 0, 0x9700 | 65);
    vga_render_rgb(out);
    uint32_t before[144];
    for (unsigned y = 0; y < 16; ++y)
        memcpy(before + y * 9, out + y * 720, 9 * sizeof(uint32_t));
    pc_clock_advance(266667);
    vga_render_rgb(out);
    for (unsigned y = 0; y < 16; ++y)
        for (unsigned xx = 0; xx < 9; ++xx)
            CHECK(out[y * 720 + xx] == 0xff0000aa);
    attr(PC_VGA_ATTR_MODE_CONTROL, 0);
    vga_render_rgb(out);
    CHECK(out[0] == 0xff5555ff); /* high-intensity background */
    CHECK(before[0] != 0);
    crtc(PC_VGA_CRTC_CURSOR_START, 14);
    crtc(PC_VGA_CRTC_CURSOR_END, 15);
    pc_clock_advance(533334);
    vga_render_rgb(out);
    CHECK(out[14 * 720] == 0xffaaaaaa); /* visible cursor */
    pc_regs r = {0};
    r.ax = PC_VIDEO_AX_FONT_QUERY_INFO;
    r.bx = 0x0200;
    pc_bios_int(PC_INT_VIDEO, &r);
    CHECK(r.es == PC_BIOS_ROM_SEGMENT && r.cx == 16 && r.bp == 0x0a00);
    r.ax = PC_VIDEO_AX_FONT_QUERY_INFO;
    r.bx = 0x0300;
    pc_bios_int(PC_INT_VIDEO, &r);
    CHECK(r.cx == 16 && r.bp == 0x0200);
    r.ax = PC_VIDEO_AX_FONT_QUERY_INFO;
    r.bx = 0x0600;
    pc_bios_int(PC_INT_VIDEO, &r);
    CHECK(r.cx == 16 && r.bp == 0x1800);
    puts("PASS text VRAM/Crt window, attributes, blink/intensity, cursor and licensed ROM fonts");
}
static uint16_t read_key(void) {
    pc_regs r = {0};
    pc_bios_int(PC_INT_KEYBOARD_BIOS, &r);
    return r.ax;
}
static unsigned break_calls;
static void break_hook(void) {
    ++break_calls;
}
/* Verify set-1 make/break events, BIOS buffering, INT 16h reads, and Ctrl-Break handling. */
static void test_keyboard(void) {
    reset();
    pc_queue_key(1000, PC_SCAN_A, 1);
    pc_queue_key(2000, PC_SCAN_A, 0);
    pc_clock_advance(2000);
    pc_poll();
    pc_regs r = {0};
    r.ax = PC_KEYBOARD_AX_CHECK;
    pc_bios_int(PC_INT_KEYBOARD_BIOS, &r);
    CHECK(!(r.flags & PC_CPU_FLAG_ZERO) && r.ax == 0x1e61);
    CHECK(read_key() == 0x1e61);
    r.ax = PC_KEYBOARD_AX_CHECK;
    pc_bios_int(PC_INT_KEYBOARD_BIOS, &r);
    CHECK(r.flags & PC_CPU_FLAG_ZERO);
    pc_queue_key(3000, PC_SCAN_LEFT_SHIFT, 1);
    pc_queue_key(3000, PC_SCAN_A, 1);
    pc_queue_key(3000, PC_SCAN_LEFT_SHIFT, 0);
    pc_clock_advance(3000);
    pc_poll();
    CHECK(read_key() == 0x1e41);
    pc_queue_key(4000, PC_SCAN_EXT_CURSOR_LEFT, 1);
    pc_clock_advance(4000);
    pc_poll();
    CHECK(tp_ReadKey() == 0);
    CHECK(tp_KeyPressed());
    CHECK(tp_ReadKey() == 0x4b);
    pc_queue_key(5000, PC_SCAN_LEFT_CTRL, 1);
    pc_queue_key(5000, PC_SCAN_C, 1);
    pc_clock_advance(5000);
    pc_poll();
    CHECK(read_key() == 0x2e03);
    r.ax = PC_KEYBOARD_AX_SHIFT_FLAGS;
    pc_bios_int(PC_INT_KEYBOARD_BIOS, &r);
    CHECK(r.ax & 4);
    for (unsigned n = 0; n < 20; ++n)
        pc_queue_key(6000, PC_SCAN_D, 1);
    pc_clock_advance(6000);
    pc_poll();
    unsigned count = 0;
    while (tp_KeyPressed()) {
        (void)read_key();
        ++count;
    }
    CHECK(count == 15);
    pc_queue_key(7000, PC_SCAN_E, 1);
    pc_clock_advance(7000);
    pc_poll();
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_BUFFER_TAIL,
            pc_rd16(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_BUFFER_HEAD));
    CHECK(!tp_KeyPressed());
    pc_queue_key(8000, PC_SCAN_LEFT_CTRL, 0);
    pc_queue_key(10000, PC_SCAN_B, 1);
    CHECK(read_key() == 0x3062);
    CHECK(pc_time_us() >= 10000); /* blocking INT16 allows IRQs */
    tp_SetIntVec(PC_INT_CTRL_BREAK, pc_register_code(break_hook, "test Ctrl-Break"));
    pc_queue_key(11000, PC_SCAN_LEFT_CTRL, 1);
    pc_queue_key(11000, PC_SCAN_SCROLL_LOCK, 1);
    pc_clock_advance(11000);
    pc_poll();
    CHECK(break_calls == 1 && (pc_rd8(PC_BDA_SEGMENT, PC_BDA_BREAK_FLAG) & 128) &&
          (pc_rd8(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_FLAGS_2) & 16));
    pc_queue_key(12000, PC_SCAN_SCROLL_LOCK, 0);
    pc_clock_advance(12000);
    pc_poll();
    CHECK(!(pc_rd8(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_FLAGS_2) & 16));
    puts("PASS BIOS keyboard ring, INT16 peek/read/shift, E0, Crt 0-prefix, full/discard/blocking");
}
static char trace[512];
static unsigned trace_len;
static farptr saved_key;
static void tick(void) {
    CHECK(!pc_interrupts_enabled());
    trace[trace_len++] = 'T';
}
static void key_hook(void) {
    CHECK(!pc_interrupts_enabled());
    trace[trace_len++] = 'K';
    pc_chain_interrupt(saved_key);
    trace[trace_len++] = 'X';
}
/* Verify IF gating, IRQ ordering, chained INT 9, BIOS ticks/EOIs, and PIT reprogramming. */
static void test_scheduler(void) {
    reset();
    trace_len = 0;
    tp_GetIntVec(PC_INT_KEYBOARD, &saved_key);
    tp_SetIntVec(PC_INT_KEYBOARD, pc_register_code(key_hook, "test key"));
    tp_SetIntVec(PC_INT_TIMER_CALLBACK, pc_register_code(tick, "test tick"));
    pc_queue_key(54926, PC_SCAN_A, 1);
    pc_clock_advance(54926);
    pc_poll();
    CHECK(trace_len == 2 && !memcmp(trace, "TK", 2));
    CHECK(read_key() == 0x1e61);
    CHECK(pc_eoi_count() == 2);
    pc_cli();
    pc_queue_key(60000, PC_SCAN_B, 1);
    pc_clock_advance(120000);
    pc_poll();
    CHECK(trace_len == 2);
    pc_sti();
    pc_poll();
    CHECK(trace_len == 4 && !memcmp(trace, "TKKT", 4));
    CHECK(pc_rd16(PC_BDA_SEGMENT, PC_BDA_TIMER_TICKS_LOW) == 2);
    CHECK(pc_interrupts_enabled());
    pc_outb(PC_PORT_PIT_CONTROL, PC_PIT_CMD_COUNTER0_LOHI_SQUARE_WAVE);
    pc_outb(PC_PORT_PIT_CHANNEL_0, 0x47);
    pc_outb(PC_PORT_PIT_CHANNEL_0, 0x21);
    CHECK(pc_pit_divisor(PC_PIT_CHANNEL_INDEX_0) == 8519);
    pc_clock_advance(1120000);
    pc_poll();
    CHECK(pc_irq_count(PC_INT_TIMER) == 142 &&
          pc_rd16(PC_BDA_SEGMENT, PC_BDA_TIMER_TICKS_LOW) == 142);
    CHECK(pc_eoi_count() == 144); /* 142 timer + two keyboard IRQs */
    pc_outb(PC_PORT_PIT_CONTROL, PC_PIT_CMD_LATCH_COUNTER0);
    uint16_t counter = pc_inb(PC_PORT_PIT_CHANNEL_0);
    counter |= (uint16_t)(pc_inb(PC_PORT_PIT_CHANNEL_0) << 8);
    CHECK(counter <= 8519);
    pc_outb(PC_PORT_PIT_CONTROL, PC_PIT_CMD_COUNTER0_LOHI_SQUARE_WAVE);
    pc_outb(PC_PORT_PIT_CHANNEL_0, 0);
    pc_outb(PC_PORT_PIT_CHANNEL_0, 0);
    CHECK(pc_pit_divisor(PC_PIT_CHANNEL_INDEX_0) == 65536);
    uint64_t before = pc_irq_count(PC_INT_TIMER);
    pc_clock_advance(2120000);
    pc_poll();
    CHECK(pc_irq_count(PC_INT_TIMER) - before == 18);
    puts("PASS IRQ ordering/IF/IRET/chain, BIOS tick/EOI, PIT rate/reprogram/latch");
}
/* Verify the game-port capacitor countdown, timeout, and active-low button inputs. */
static void test_joystick(void) {
    reset();
    pc_outb(PC_PORT_GAME, 0);
    for (unsigned n = 0; n < 65535; ++n)
        CHECK(pc_inb(PC_PORT_GAME) & 1);
    int16_t axes[4] = {-32768, 0, 32767, 0};
    pc_joystick_set(1, axes, 3);
    pc_outb(PC_PORT_GAME, 0);
    unsigned counts[4] = {0};
    for (unsigned n = 0; n < 600; ++n) {
        uint8_t v = pc_inb(PC_PORT_GAME);
        CHECK(!(v & 0x30));
        for (unsigned a = 0; a < 4; ++a)
            if (v & (1u << a))
                ++counts[a];
    }
    CHECK(counts[0] == 64 && counts[1] == 320 && counts[2] == 575 && counts[3] == 320);
    pc_outb(PC_PORT_GAME, 0);
    pc_clock_advance(3000);
    CHECK((pc_inb(PC_PORT_GAME) & 3) == 0);
    puts("PASS game port RC-loop calibration, timeout, timed discharge and active-low buttons");
}
static void halt_entry(void) {
    pc_terminate(17);
}
/* Verify PIT channel 2 speaker output and the DOS INT 21h file/termination services. */
static void test_sound_dos(void) {
    reset();
    tp_NoSound();
    tp_Sound(440);
    CHECK(pc_pit_divisor(PC_PIT_CHANNEL_INDEX_2) == 1193181 / 440 &&
          (pc_inb(PC_PORT_SPEAKER_CONTROL) & 3) == 3);
    tp_Sound(0);
    tp_Sound(18);
    CHECK(pc_pit_divisor(PC_PIT_CHANNEL_INDEX_2) == 1193181 / 440);
    pc_clock_advance(100000);
    tp_Sound(880);
    pc_clock_advance(200000);
    tp_NoSound();
    pc_clock_advance(300000);
    CHECK(pc_speaker_capture("speaker.wav", 300000));
    CHECK(platform_run(halt_entry) == 17);
    FILE *f = pc_fopen("MixedCase.DAT", "wb");
    CHECK(f);
    fwrite("abcde", 1, 5, f);
    fclose(f);
    pc_regs r = {0};
    const char *name = "mixedcase.dat";
    memcpy(pc_host(0x5000, 0), name, strlen(name) + 1);
    r.ax = 0x3d00;
    r.ds = 0x5000;
    pc_bios_int(PC_INT_DOS, &r);
    CHECK(!(r.flags & 1));
    uint16_t handle = r.ax;
    r.ax = 0x3f00;
    r.bx = handle;
    r.dx = 100;
    r.cx = 5;
    pc_bios_int(PC_INT_DOS, &r);
    CHECK(r.ax == 5 && !memcmp(pc_host(0x5000, 100), "abcde", 5));
    r.ax = 0x4200;
    r.cx = 0;
    r.dx = 2;
    pc_bios_int(PC_INT_DOS, &r);
    CHECK(r.ax == 2);
    r.ax = 0x4100;
    r.dx = 0;
    pc_bios_int(PC_INT_DOS, &r);
    CHECK(!(r.flags & 1));
    r.ax = 0x4200;
    r.cx = 0;
    r.dx = 1;
    pc_bios_int(PC_INT_DOS, &r);
    CHECK(r.ax == 1);
    r.ax = 0x3f00;
    r.dx = 100;
    r.cx = 3;
    pc_bios_int(PC_INT_DOS, &r);
    CHECK(r.ax == 3 && !memcmp(pc_host(0x5000, 100), "bcd", 3));
    r.ax = 0x3e00;
    pc_bios_int(PC_INT_DOS, &r);
    CHECK(!(r.flags & 1));
    r.ax = 0x4100;
    r.dx = 0;
    pc_bios_int(PC_INT_DOS, &r);
    CHECK((r.flags & 1) && r.ax == 2);
    puts("PASS speaker TP Sound/NoSound/divisor/zero semantics/WAV, DOS files and launcher unwind");
}
int main(int argc, char **argv) {
    if (!platform_init(argc, argv))
        return 2;
    test_memory();
    test_vga();
    test_scanout();
    test_text();
    test_keyboard();
    test_scheduler();
    test_joystick();
    test_sound_dos();
    platform_shutdown();
    puts("ALL PLATFORM TESTS PASSED");
    return 0;
}
