/* Turbo Pascal Crt text, keyboard, timer, and speaker services over the BIOS device model. */
#include "crt_dos.h"
#include "../pc/platform.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

enum {
    TP_TEXT_WINDOW_MAX = 0x184f,
    BIOS_VIDEO_SET_CURSOR_POSITION_AX = 0x0200,
    BIOS_VIDEO_GET_MODE_AX = 0x0f00,
    BIOS_VIDEO_READ_CHARACTER_AX = 0x0800,
    BIOS_KEYBOARD_CHECK_AX = 0x0100,
    PIT_CHANNEL_2_SQUARE_WAVE = 0xb6
};

uint8_t tp_CrtActive;
static uint16_t crt_ds, crt_offsets[8];
/* Bind Crt's Pascal globals to their original offsets in the emulated DS segment. */
void tp_BindCrt(uint16_t ds, const tp_crt_offsets *offsets) {
    crt_ds = ds;
    memcpy(crt_offsets, offsets, sizeof crt_offsets);
    tp_CrtActive = 0;
}
/* Return an lvalue into the emulated Crt data block for the generated TP globals. */
void *tp_CrtAddress(uint8_t index) {
    if (!crt_ds || index >= 8) {
        fprintf(stderr, "Crt DATA offsets not bound\n");
        abort();
    }
    return pc_host(crt_ds, crt_offsets[index]);
}
static uint8_t x = 1, y = 1, read_pending, pending_scan;
static uint16_t video_seg = PC_VIDEO_TEXT_SEGMENT;
static unsigned left(void) {
    return tp_WindMin & 255;
}
static unsigned top(void) {
    return tp_WindMin >> 8;
}
static unsigned width(void) {
    return (tp_WindMax & 255) - left() + 1;
}
static unsigned height(void) {
    return (tp_WindMax >> 8) - top() + 1;
}
static uint16_t cell(unsigned cx, unsigned cy) {
    return (uint16_t)(((top() + cy - 1) * 80 + left() + cx - 1) * 2);
}
static void cursor(void) {
    pc_regs r = {0};
    r.ax = BIOS_VIDEO_SET_CURSOR_POSITION_AX;
    r.dx = (uint16_t)(((top() + y - 1) << 8) | (left() + x - 1));
    pc_bios_int(PC_INT_VIDEO, &r);
}
static void break_handler(void) {
    if (tp_CheckBreak)
        pc_terminate(255);
}
/* Initialise the BIOS text mode and the Crt state used by TP console routines. */
void tp_CrtInit(void) {
    pc_regs r = {0};
    r.ax = BIOS_VIDEO_GET_MODE_AX;
    pc_bios_int(PC_INT_VIDEO, &r);
    if ((r.ax & 255) != PC_VIDEO_MODE_TEXT_80X25)
        tp_TextMode(PC_VIDEO_MODE_TEXT_80X25);
    r.ax = BIOS_VIDEO_READ_CHARACTER_AX;
    r.bx = 0;
    pc_bios_int(PC_INT_VIDEO, &r);
    tp_TextAttr = (uint8_t)(r.ax >> 8);
    tp_CheckBreak = tp_DirectVideo = 1;
    tp_CheckEOF = tp_CheckSnow = 0;
    read_pending = 0;
    tp_CrtActive = 1;
    tp_WindMin = 0;
    tp_WindMax = TP_TEXT_WINDOW_MAX;
    tp_LastMode = PC_VIDEO_MODE_TEXT_80X25;
    x = y = 1;
    tp_SetIntVec(PC_INT_CTRL_BREAK, pc_register_code(break_handler, "Crt Ctrl-Break"));
    cursor();
}
void tp_Delay(uint16_t ms) {
    pc_delay_ms(ms);
}
/* Program PIT channel 2 and the speaker gate to produce Crt.Sound's square wave. */
void tp_Sound(uint16_t hz) {
    if (hz <= 18)
        return;
    if (!(pc_inb(PC_PORT_SPEAKER_CONTROL) & PC_SPEAKER_GATE_MASK)) {
        pc_outb(PC_PORT_SPEAKER_CONTROL,
                (uint8_t)(pc_inb(PC_PORT_SPEAKER_CONTROL) | PC_SPEAKER_GATE_MASK));
        pc_outb(PC_PORT_PIT_CONTROL, PIT_CHANNEL_2_SQUARE_WAVE);
    }
    uint16_t d = (uint16_t)(1193181u / hz);
    pc_outb(PC_PORT_PIT_CHANNEL_2, (uint8_t)d);
    pc_outb(PC_PORT_PIT_CHANNEL_2, (uint8_t)(d >> 8));
}
/* Turn off the gate bits that connect PIT channel 2 to the speaker. */
void tp_NoSound(void) {
    pc_outb(PC_PORT_SPEAKER_CONTROL,
            (uint8_t)(pc_inb(PC_PORT_SPEAKER_CONTROL) & ~PC_SPEAKER_GATE_MASK_U));
}
/* Query BIOS INT 16h without consuming the emulated keyboard ring-buffer word. */
uint8_t tp_KeyPressed(void) {
    if (read_pending)
        return 1;
    pc_poll();
    pc_regs r = {0};
    r.ax = BIOS_KEYBOARD_CHECK_AX;
    pc_bios_int(PC_INT_KEYBOARD_BIOS, &r);
    return (r.flags & PC_CPU_FLAG_ZERO) == 0;
}
/* Consume a BIOS key word and retain its scan byte for Crt's following ReadKey call. */
uint8_t tp_ReadKey(void) {
    if (read_pending) {
        read_pending = 0;
        return pending_scan;
    }
    pc_regs r = {0};
    pc_bios_int(PC_INT_KEYBOARD_BIOS, &r);
    if (!(r.ax & 255)) {
        pending_scan = (uint8_t)(r.ax >> 8);
        read_pending = 1;
    }
    return (uint8_t)r.ax;
}
void tp_GotoXY(uint8_t nx, uint8_t ny) {
    if (nx && ny && nx <= width() && ny <= height()) {
        x = nx;
        y = ny;
        cursor();
    }
}
uint8_t tp_WhereX(void) {
    return x;
}
uint8_t tp_WhereY(void) {
    return y;
}
void tp_TextColor(uint8_t c) {
    tp_TextAttr = (uint8_t)((tp_TextAttr & 0x70) | (c & 0x8f));
}
void tp_TextBackground(uint8_t c) {
    tp_TextAttr = (uint8_t)((tp_TextAttr & 0x8f) | ((c & 7) << 4));
}
void tp_Window(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2) {
    if (!x1 || !y1 || x1 > x2 || y1 > y2 || x2 > 80 || y2 > 25)
        return;
    tp_WindMin = (uint16_t)(((y1 - 1) << 8) | (x1 - 1));
    tp_WindMax = (uint16_t)(((y2 - 1) << 8) | (x2 - 1));
    x = y = 1;
    cursor();
}
void tp_ClrScr(void) {
    for (unsigned cy = 1; cy <= height(); ++cy)
        for (unsigned cx = 1; cx <= width(); ++cx)
            pc_wr16(video_seg, cell(cx, cy), (uint16_t)((tp_TextAttr << 8) | 32));
    x = y = 1;
    cursor();
}
void tp_ClrEol(void) {
    for (unsigned cx = x; cx <= width(); ++cx)
        pc_wr16(video_seg, cell(cx, y), (uint16_t)((tp_TextAttr << 8) | 32));
}
void tp_TextMode(int16_t m) {
    pc_regs r = {0};
    r.ax = (uint16_t)m & 255;
    pc_bios_int(PC_INT_VIDEO, &r);
    tp_LastMode = (uint16_t)m;
    video_seg = PC_VIDEO_TEXT_SEGMENT;
    tp_WindMin = 0;
    tp_WindMax = TP_TEXT_WINDOW_MAX;
    x = y = 1;
    cursor();
}
/* Scroll the active text window up one line and clear its new bottom row. */
/* Move the active B800 window up one text row and clear the last row. */
static void newline(void) {
    ++y;
    if (y <= height())
        return;
    y = (uint8_t)height();
    for (unsigned cy = 1; cy < height(); ++cy)
        for (unsigned cx = 1; cx <= width(); ++cx)
            pc_wr16(video_seg, cell(cx, cy), pc_rd16(video_seg, cell(cx, cy + 1)));
    for (unsigned cx = 1; cx <= width(); ++cx)
        pc_wr16(video_seg, cell(cx, y), (uint16_t)((tp_TextAttr << 8) | 32));
}
/* Apply Crt's CR/LF/backspace/BEL semantics while drawing through text video memory. */
void tp_CrtWrite(const uint8_t *bytes, size_t length) {
    for (size_t i = 0; i < length; ++i) {
        uint8_t ch = bytes[i];
        if (ch == 13)
            x = 1;
        else if (ch == 10)
            newline();
        else if (ch == 8) {
            if (x > 1)
                --x;
        } else if (ch == 7) { /* DOS BEL: briefly use the same speaker hardware. */
            tp_Sound(880);
            tp_Delay(30);
            tp_NoSound();
        } else {
            pc_wr16(video_seg, cell(x, y), (uint16_t)((tp_TextAttr << 8) | ch));
            if (++x > width()) {
                x = 1;
                newline();
            }
        }
        pc_poll();
    }
    cursor();
}
void tp_CrtWriteLn(void) {
    const uint8_t end[] = {13, 10};
    tp_CrtWrite(end, 2);
}
