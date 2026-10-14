/* Emulate the PIT, PC speaker, keyboard controller, CMOS clock, and game-port I/O devices. */
#include "pc_internal.h"
#include <string.h>
#include <time.h>

typedef struct {
    uint32_t divisor;
    uint16_t latch;
    uint8_t access, mode, low, write_phase, read_phase, latched;
    uint64_t loaded;
} pit_channel;
static pit_channel pit[3];
static uint8_t scan_latch, speaker_port, cmos_index, keyboard_e0;
static uint8_t pressed[256];
static int joy_connected, retrace_reads;
static int16_t joy_axes[4];
static uint8_t joy_buttons;
static uint64_t joy_start;
static uint32_t joy_reads;

int pc_retrace_polling(void) {
    int v = retrace_reads;
    retrace_reads = 0;
    return v;
}
uint32_t pc_pit_divisor(unsigned n) {
    return n < 3 ? pit[n].divisor : 0;
}
void pc_keyboard_latch(uint8_t scan) {
    scan_latch = scan;
}
void pc_devices_reset(void) {
    memset(pit, 0, sizeof pit);
    memset(pressed, 0, sizeof pressed);
    keyboard_e0 = 0;
    for (unsigned n = 0; n < 3; ++n) {
        pit[n].divisor = 65536;
        pit[n].access = 3;
        pit[n].mode = 3;
    }
    speaker_port = 0x0c;
    scan_latch = cmos_index = 0;
    retrace_reads = 0;
    joy_connected = 0;
    joy_buttons = 0;
    joy_reads = 0;
    memset(joy_axes, 0, sizeof joy_axes);
}
/* Mirror joystick presence into the BIOS equipment word while recording axis/button state. */
void pc_joystick_set(int connected, const int16_t axes[4], uint8_t buttons) {
    joy_connected = connected != 0;
    if (axes)
        memcpy(joy_axes, axes, sizeof joy_axes);
    joy_buttons = buttons & 15;
    uint16_t eq = pc_rd16(PC_BDA_SEGMENT, PC_BDA_EQUIPMENT);
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_EQUIPMENT,
            (uint16_t)((eq & ~PC_BDA_EQUIPMENT_JOYSTICK_PRESENT_U) |
                       (joy_connected ? PC_BDA_EQUIPMENT_JOYSTICK_PRESENT : 0)));
}
/* Derive the PIT's down-counter from elapsed emulated input clocks. */
static uint16_t pit_counter(unsigned n) {
    pit_channel *p = &pit[n];
    uint64_t elapsed = (pc_time_us() - p->loaded) * PC_PIT_HZ / 1000000u;
    return (uint16_t)(p->divisor - elapsed % p->divisor);
}
/* Preserve PIT latching and low/high byte sequencing on counter reads. */
static uint8_t pit_read(unsigned n) {
    pit_channel *p = &pit[n];
    uint16_t v = p->latched ? p->latch : pit_counter(n);
    uint8_t result =
        p->access == 2 || (p->access == 3 && p->read_phase) ? (uint8_t)(v >> 8) : (uint8_t)v;
    if (p->access == 3)
        p->read_phase ^= 1;
    if (p->access != 3 || !p->read_phase)
        p->latched = 0;
    return result;
}
/* Return CMOS RTC fields as BCD from a fixed epoch plus deterministic emulated time. */
static uint8_t cmos_read(void) {
    /* Fixed epoch + emulated seconds makes scripted RTC reads reproducible. */
    time_t epoch = PC_RTC_EPOCH_UNIX_SECONDS + (time_t)(pc_time_us() / 1000000u);
    struct tm *t = gmtime(&epoch);
    unsigned v = 0;
    switch (cmos_index & PC_CMOS_INDEX_MASK) {
    case PC_CMOS_SECONDS:
        v = (unsigned)t->tm_sec;
        break;
    case PC_CMOS_MINUTES:
        v = (unsigned)t->tm_min;
        break;
    case PC_CMOS_HOURS:
        v = (unsigned)t->tm_hour;
        break;
    case PC_CMOS_WEEKDAY:
        v = (unsigned)t->tm_wday + 1;
        break;
    case PC_CMOS_DAY_OF_MONTH:
        v = (unsigned)t->tm_mday;
        break;
    case PC_CMOS_MONTH:
        v = (unsigned)t->tm_mon + 1;
        break;
    case PC_CMOS_YEAR:
        v = (unsigned)(t->tm_year + 1900) % 100;
        break;
    case PC_CMOS_STATUS_A:
        return 0x26;
    case PC_CMOS_STATUS_B:
        return 2;
    case PC_CMOS_STATUS_D:
        return 128;
    }
    return (uint8_t)((v / 10) * 16 + v % 10);
}
/* Decode device reads, including PIT latches and capacitor timing on the game port. */
uint8_t pc_inb(uint16_t port) {
    uint8_t v;
    if (port == PC_PORT_VGA_STATUS_COLOR || port == PC_PORT_VGA_STATUS_MONO)
        retrace_reads = 1;
    if (vga_port_read(port, &v))
        return v;
    switch (port) {
    case PC_PORT_PIT_CHANNEL_0:
    case PC_PORT_PIT_CHANNEL_1:
    case PC_PORT_PIT_CHANNEL_2:
        return pit_read(port - PC_PORT_PIT_CHANNEL_0);
    case PC_PORT_KEYBOARD_DATA:
        return scan_latch;
    case PC_PORT_SPEAKER_CONTROL:
        return speaker_port;
    case PC_PORT_KEYBOARD_STATUS:
        return 0x14;
    case PC_PORT_CMOS_DATA:
        return cmos_read();
    case PC_PORT_GAME: {
        v = (uint8_t)(0xf0 & ~(joy_buttons << 4));
        ++joy_reads;
        /* One game-port read is one 8-us ISA loop quantum. Wall time can discharge
           the capacitor earlier. This also terminates translated CLI loops. */
        uint64_t dt = pc_time_us() - joy_start;
        uint64_t count = dt / PC_GAME_PORT_READ_QUANTUM_US;
        if (count < joy_reads)
            count = joy_reads;
        for (unsigned a = 0; a < 4; ++a) {
            unsigned limit = 64u + ((uint32_t)((int32_t)joy_axes[a] + 32768) * 512u / 65536u);
            if (!joy_connected || count <= limit)
                v |= (uint8_t)(1u << a);
        }
        return v;
    }
    default:
        return 255;
    }
}
uint16_t pc_inw(uint16_t p) {
    uint16_t v = pc_inb(p);
    return (uint16_t)(v | (pc_inb((uint16_t)(p + 1)) << 8));
}
/* Apply channel writes and notify the timer scheduler or speaker oscillator. */
static void pit_write(unsigned n, uint8_t v) {
    pit_channel *p = &pit[n];
    uint32_t d;
    if (p->access == 1)
        d = v;
    else if (p->access == 2)
        d = (uint32_t)v << 8;
    else if (!p->write_phase) {
        p->low = v;
        p->write_phase = 1;
        return;
    } else {
        d = p->low | ((uint32_t)v << 8);
        p->write_phase = 0;
    }
    p->divisor = d ? d : 65536;
    p->loaded = pc_time_us();
    if (n == PC_PIT_CHANNEL_INDEX_0)
        pc_pit_schedule(p->divisor);
    if (n == PC_PIT_CHANNEL_INDEX_2)
        speaker_change(p->divisor, speaker_port & PC_SPEAKER_GATE_MASK, 1);
}
/* Decode device writes and advance the appropriate timer, speaker, or keyboard state. */
void pc_outb(uint16_t port, uint8_t v) {
    if (vga_port_write(port, v))
        return;
    switch (port) {
    case PC_PORT_PIC_COMMAND:
        if (v & PC_PIC_NON_SPECIFIC_EOI)
            pc_pic_eoi();
        break;
    case PC_PORT_PIT_CHANNEL_0:
    case PC_PORT_PIT_CHANNEL_1:
    case PC_PORT_PIT_CHANNEL_2:
        pit_write(port - PC_PORT_PIT_CHANNEL_0, v);
        break;
    case PC_PORT_PIT_CONTROL: {
        unsigned n = v >> 6;
        if (n > 2)
            break;
        pit_channel *p = &pit[n];
        unsigned access = (v >> 4) & 3;
        if (!access) {
            if (!p->latched) {
                p->latch = pit_counter(n);
                p->latched = 1;
                p->read_phase = 0;
            }
        } else {
            p->access = (uint8_t)access;
            p->mode = (v >> 1) & 7;
            p->write_phase = p->read_phase = 0;
            p->latched = 0;
        }
        break;
    }
    case PC_PORT_KEYBOARD_DATA:
        scan_latch = v;
        break;
    case PC_PORT_SPEAKER_CONTROL:
        if ((v & PC_SPEAKER_GATE_MASK) != (speaker_port & PC_SPEAKER_GATE_MASK))
            speaker_change(pit[2].divisor, v & PC_SPEAKER_GATE_MASK,
                           (v & PC_SPEAKER_GATE_TIMER2) &&
                               !(speaker_port & PC_SPEAKER_GATE_TIMER2));
        speaker_port = v;
        break;
    case PC_PORT_CMOS_INDEX:
        cmos_index = v;
        break;
    case PC_PORT_GAME:
        joy_start = pc_time_us();
        joy_reads = 0;
        break;
    }
}
void pc_outw(uint16_t p, uint16_t v) {
    pc_outb(p, (uint8_t)v);
    pc_outb((uint16_t)(p + 1), (uint8_t)(v >> 8));
}

static const char normal[] = "\0\x1b"
                             "1234567890-=\b\tqwertyuiop[]\r\0asdfghjkl;'`\0\\zxcvbnm,./\0*\0 \0";
static const char shifted[] = "\0\x1b"
                              "!@#$%^&*()_+\b\tQWERTYUIOP{}\r\0ASDFGHJKL:\"~\0|ZXCVBNM<>?\0*\0 \0";
/* Enqueue a translated key word in the BIOS circular buffer if there is room. */
static void ring_put(uint16_t word) {
    uint16_t h = pc_rd16(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_BUFFER_HEAD),
             t = pc_rd16(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_BUFFER_TAIL), next = (uint16_t)(t + 2);
    if (next >= PC_KEYBOARD_BUFFER_END)
        next = PC_KEYBOARD_BUFFER_START;
    if (next == h)
        return;
    pc_wr16(PC_BDA_SEGMENT, t, word);
    pc_wr16(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_BUFFER_TAIL, next);
}
/* Decode set-1 key events into BDA flags, the BIOS ring buffer, and PIC acknowledgements. */
void bios_keyboard_irq(void) {
    unsigned code = scan_latch;
    if (code == PC_SCAN_EXTENDED_PREFIX) {
        keyboard_e0 = 1;
        pc_wr8(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_STATUS,
               (uint8_t)(pc_rd8(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_STATUS) | 2));
        pc_outb(PC_PORT_PIC_COMMAND, PC_PIC_NON_SPECIFIC_EOI);
        return;
    }
    unsigned sc = code & PC_SCAN_CODE_MASK, idx = sc + (keyboard_e0 ? 128 : 0);
    int released = (code & PC_SCAN_BREAK_BIT) != 0;
    int old = pressed[idx];
    pressed[idx] = (uint8_t)!released;
    uint8_t flags = pc_rd8(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_FLAGS),
            secondary = pc_rd8(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_FLAGS_2);
    if (!keyboard_e0 && (sc == PC_SCAN_LEFT_SHIFT || sc == PC_SCAN_RIGHT_SHIFT)) {
        uint8_t mask = sc == PC_SCAN_LEFT_SHIFT ? PC_KEYFLAG_LEFT_SHIFT : PC_KEYFLAG_RIGHT_SHIFT;
        flags = (uint8_t)((flags & ~mask) | (released ? 0 : mask));
    }
    if (sc == PC_SCAN_LEFT_CTRL) {
        flags = (uint8_t)((flags & ~PC_KEYFLAG_CTRL_U) |
                          ((pressed[PC_SCAN_LEFT_CTRL] || pressed[PC_SCAN_LEFT_CTRL_BREAK])
                               ? PC_KEYFLAG_CTRL
                               : 0));
        if (!keyboard_e0)
            secondary = (uint8_t)((secondary & ~1u) | (released ? 0 : 1));
    }
    if (sc == PC_SCAN_LEFT_ALT) {
        flags = (uint8_t)((flags & ~PC_KEYFLAG_ALT_U) |
                          ((pressed[PC_SCAN_LEFT_ALT] || pressed[PC_SCAN_LEFT_ALT_BREAK])
                               ? PC_KEYFLAG_ALT
                               : 0));
        if (!keyboard_e0)
            secondary = (uint8_t)((secondary & ~2u) | (released ? 0 : 2));
    }
    int insert = sc == PC_SCAN_INSERT && (keyboard_e0 || !(((flags & PC_KEYFLAG_NUM_LOCK) != 0) ^
                                                           ((flags & PC_KEYFLAG_SHIFT_MASK) != 0)));
    if ((sc == PC_SCAN_CAPS_LOCK || sc == PC_SCAN_NUM_LOCK || sc == PC_SCAN_SCROLL_LOCK ||
         insert) &&
        (!keyboard_e0 || insert)) {
        uint8_t mask = (uint8_t)(sc == PC_SCAN_CAPS_LOCK     ? PC_KEYFLAG_CAPS_LOCK
                                 : sc == PC_SCAN_NUM_LOCK    ? PC_KEYFLAG_NUM_LOCK
                                 : sc == PC_SCAN_SCROLL_LOCK ? PC_KEYFLAG_SCROLL_LOCK
                                                             : PC_KEYFLAG_INSERT);
        secondary = (uint8_t)((secondary & ~mask) | (released ? 0 : mask));
        if (!released && !old)
            flags ^= mask;
    }
    pc_wr8(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_FLAGS, flags);
    pc_wr8(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_FLAGS_2, secondary);
    pc_wr8(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_STATUS,
           (uint8_t)(0x10 | (pressed[PC_SCAN_LEFT_CTRL_BREAK] ? PC_KEYFLAG_CTRL : 0) |
                     (pressed[PC_SCAN_LEFT_ALT_BREAK] ? PC_KEYFLAG_ALT : 0)));
    if (!released && sc == PC_SCAN_SCROLL_LOCK && (flags & PC_KEYFLAG_CTRL)) {
        pc_wr8(PC_BDA_SEGMENT, PC_BDA_BREAK_FLAG,
               (uint8_t)(pc_rd8(PC_BDA_SEGMENT, PC_BDA_BREAK_FLAG) | PC_BDA_BREAK_DETECTED_FLAG));
        pc_wr16(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_BUFFER_TAIL,
                pc_rd16(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_BUFFER_HEAD));
        pc_int(PC_INT_CTRL_BREAK);
    }
    if (!released && sc != PC_SCAN_LEFT_SHIFT && sc != PC_SCAN_RIGHT_SHIFT &&
        sc != PC_SCAN_LEFT_CTRL && sc != PC_SCAN_LEFT_ALT && sc != PC_SCAN_CAPS_LOCK &&
        sc != PC_SCAN_NUM_LOCK && sc != PC_SCAN_SCROLL_LOCK) {
        uint8_t ascii = 0, out_scan = (uint8_t)sc;
        int shift = (flags & PC_KEYFLAG_SHIFT_MASK) != 0;
        if (sc < sizeof normal - 1) {
            ascii = (uint8_t)(shift ? shifted[sc] : normal[sc]);
            if ((flags & PC_KEYFLAG_CAPS_LOCK) &&
                ((ascii >= 'a' && ascii <= 'z') || (ascii >= 'A' && ascii <= 'Z')))
                ascii ^= 32;
            if (flags & PC_KEYFLAG_CTRL) {
                if ((ascii >= 'a' && ascii <= 'z') || (ascii >= 'A' && ascii <= 'Z'))
                    ascii &= 31;
                else if (sc == PC_SCAN_RETURN)
                    ascii = 10;
                else if (sc == PC_SCAN_BACKSPACE)
                    ascii = 127;
                else if (sc == 0x1a || sc == 0x2b || sc == 0x1b)
                    ascii = (uint8_t)(sc == 0x1a ? 27 : sc == 0x2b ? 28 : 29);
            }
            if (flags & PC_KEYFLAG_ALT)
                ascii = 0;
        }
        if (sc >= PC_SCAN_F1 && sc <= PC_SCAN_F10)
            out_scan = (uint8_t)(sc + ((flags & PC_KEYFLAG_ALT)    ? 0x2d
                                       : (flags & PC_KEYFLAG_CTRL) ? 0x23
                                       : shift                     ? 0x19
                                                                   : 0));
        if (sc == PC_SCAN_F11 || sc == PC_SCAN_F12)
            out_scan = (uint8_t)(0x85 + sc - 0x57 +
                                 ((flags & 8)   ? 6
                                  : (flags & 4) ? 4
                                  : shift       ? 2
                                                : 0));
        if (sc >= 0x47 && sc <= 0x53) {
            const char keypad[] = "789-456+1230.";
            if (!keyboard_e0 && (((flags & 32) != 0) ^ shift))
                ascii = (uint8_t)keypad[sc - 0x47];
            else if (sc == 0x4a)
                ascii = '-';
            else if (sc == 0x4e)
                ascii = '+';
        }
        if (keyboard_e0 && sc == 0x35)
            ascii = '/';
        if (ascii || (sc >= PC_SCAN_F1 && sc <= 0x53) || sc == PC_SCAN_F11 || sc == PC_SCAN_F12 ||
            (flags & PC_KEYFLAG_ALT))
            ring_put((uint16_t)((out_scan << 8) | ascii));
    }
    keyboard_e0 = 0;
    pc_outb(PC_PORT_SPEAKER_CONTROL, (uint8_t)(speaker_port | 128));
    pc_outb(PC_PORT_SPEAKER_CONTROL, (uint8_t)(speaker_port & 127));
    pc_outb(PC_PORT_PIC_COMMAND, PC_PIC_NON_SPECIFIC_EOI);
}
/* Implement INT 16h shift queries, nonblocking peeks, and blocking BIOS key reads. */
void bios_keyboard(pc_regs *r) {
    unsigned ah = r->ax >> 8;
    if (ah == PC_KEYBOARD_FN_SHIFT_FLAGS || ah == PC_KEYBOARD_FN_EXTENDED_SHIFT_FLAGS) {
        r->ax = pc_rd8(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_FLAGS);
        if (ah == PC_KEYBOARD_FN_EXTENDED_SHIFT_FLAGS)
            r->ax |= (uint16_t)(pc_rd8(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_FLAGS_2) << 8);
        return;
    }
    if (ah != PC_KEYBOARD_FN_READ && ah != PC_KEYBOARD_FN_CHECK &&
        ah != PC_KEYBOARD_FN_READ_EXTENDED && ah != PC_KEYBOARD_FN_CHECK_EXTENDED) {
        fprintf(stderr, "unsupported INT16 AH=%02x\n", ah);
        abort();
    }
    uint16_t h, t;
    for (;;) {
        h = pc_rd16(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_BUFFER_HEAD);
        t = pc_rd16(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_BUFFER_TAIL);
        if (h != t || ah == PC_KEYBOARD_FN_CHECK || ah == PC_KEYBOARD_FN_CHECK_EXTENDED)
            break;
        pc_sti();
        pc_poll();
        if (platform_quit_requested())
            pc_terminate(0);
    }
    if (h == t) {
        r->flags |= PC_CPU_FLAG_ZERO;
        return;
    }
    r->flags &= (uint16_t)~PC_CPU_FLAG_ZERO_U;
    r->ax = pc_rd16(PC_BDA_SEGMENT, h);
    if (ah == PC_KEYBOARD_FN_READ || ah == PC_KEYBOARD_FN_READ_EXTENDED) {
        h += 2;
        if (h >= PC_KEYBOARD_BUFFER_END)
            h = PC_KEYBOARD_BUFFER_START;
        pc_wr16(PC_BDA_SEGMENT, PC_BDA_KEYBOARD_BUFFER_HEAD, h);
    }
}
