#ifndef SAM_PLATFORM_H
#define SAM_PLATFORM_H
/* SDL host lifecycle and test hooks plus private names for emulated PC registers and ports. */
#include "pc.h"
#include <setjmp.h>

/* SDL host controls and named hardware addresses used by the platform implementation and tests. */

/* 8086 I/O port addresses used by the emulated PC. */
#define PC_PORT_PIC_COMMAND 0x20
#define PC_PIC_NON_SPECIFIC_EOI 0x20
#define PC_PORT_PIT_CHANNEL_0 0x40
#define PC_PORT_PIT_CHANNEL_1 0x41
#define PC_PORT_PIT_CHANNEL_2 0x42
#define PC_PORT_PIT_CONTROL 0x43
#define PC_PIT_CHANNEL_INDEX_0 0
#define PC_PIT_CHANNEL_INDEX_1 1
#define PC_PIT_CHANNEL_INDEX_2 2
#define PC_PIT_CMD_LATCH_COUNTER0 0x00
#define PC_PIT_CMD_COUNTER0_LOHI_SQUARE_WAVE 0x36
#define PC_PIT_CMD_COUNTER2_LOHI_SQUARE_WAVE 0xb6
#define PC_PORT_KEYBOARD_DATA 0x60
#define PC_PORT_SPEAKER_CONTROL 0x61
#define PC_PORT_KEYBOARD_STATUS 0x64
#define PC_PORT_CMOS_INDEX 0x70
#define PC_PORT_CMOS_DATA 0x71
#define PC_PORT_VGA_ATTRIBUTE 0x3c0
#define PC_PORT_VGA_ATTRIBUTE_READ 0x3c1
#define PC_PORT_VGA_MISC_WRITE 0x3c2
#define PC_PORT_VGA_MISC_READ 0x3cc
#define PC_PORT_VGA_SEQUENCER_INDEX 0x3c4
#define PC_PORT_VGA_SEQUENCER_DATA 0x3c5
#define PC_PORT_VGA_GRAPHICS_INDEX 0x3ce
#define PC_PORT_VGA_GRAPHICS_DATA 0x3cf
#define PC_PORT_CRTC_MONO_INDEX 0x3b4
#define PC_PORT_CRTC_MONO_DATA 0x3b5
#define PC_PORT_CRTC_COLOR_INDEX 0x3d4
#define PC_PORT_CRTC_COLOR_DATA 0x3d5
#define PC_PORT_VGA_STATUS_MONO 0x3ba
#define PC_PORT_VGA_STATUS_COLOR 0x3da
#define PC_PORT_GAME 0x201
#define PC_VIDEO_TEXT_SEGMENT 0xb800
#define PC_VIDEO_PLANAR_SEGMENT 0xa000
#define PC_VIDEO_PLANAR_ADDRESS 0xa0000
#define PC_VIDEO_PLANAR_END 0xb0000
#define PC_IVT_SEGMENT 0x00
#define PC_IVT_ENTRY_SIZE 4
#define PC_BIOS_ROM_SEGMENT 0xf000
#define PC_FONT_8X8_OFFSET 0x0200
#define PC_FONT_8X14_OFFSET 0x0a00
#define PC_FONT_8X16_OFFSET 0x1800
#define PC_FONT_ALTERNATE_8X8_OFFSET (128 * 8)
#define PC_CODE_REGISTRY_BASE 0x6000
#define PC_CODE_REGISTRY_LINEAR 0xf6000
#define PC_CODE_REGISTRY_SLOT_SIZE 4
#define PC_CODE_REGISTRY_SLOT_ALIGNMENT_MASK 3
#define PC_BIOS_TICKS_PER_DAY 0x1800b0
#define PC_REAL_MODE_LOW_ALIAS_END 0x10000
#define PC_REAL_MODE_WRAP_START 0x100000

/* BIOS interrupt-vector numbers used by the platform and runtime. */
#define PC_INT_TIMER 0x08
#define PC_INT_KEYBOARD 0x09
#define PC_INT_VIDEO 0x10
#define PC_INT_EQUIPMENT 0x11
#define PC_INT_KEYBOARD_BIOS 0x16
#define PC_INT_CTRL_BREAK 0x1b
#define PC_INT_TIMER_CALLBACK 0x1c
#define PC_INT_FONT_8X8 0x1f
#define PC_INT_CLOCK 0x1a
#define PC_INT_DOS 0x21
#define PC_INT_FONT_8X16 0x43

/* BIOS mode numbers used by the video model. */
#define PC_VIDEO_MODE_TEXT_80X25 0x03
#define PC_VIDEO_MODE_EGA_320X200 0x0d
#define PC_VIDEO_MODE_EGA_640X350 0x10
#define PC_VIDEO_MODE_VGA_640X480 0x12

/* BIOS Data Area segment and offsets touched by the game-facing hardware model. */
#define PC_BDA_SEGMENT 0x40
#define PC_BDA_EQUIPMENT 0x10
#define PC_BDA_MEMORY_KB 0x13
#define PC_BDA_KEYBOARD_FLAGS 0x17
#define PC_BDA_KEYBOARD_FLAGS_2 0x18
#define PC_BDA_KEYBOARD_BUFFER_HEAD 0x1a
#define PC_BDA_KEYBOARD_BUFFER_TAIL 0x1c
#define PC_BDA_KEYBOARD_BUFFER_START 0x80
#define PC_BDA_KEYBOARD_BUFFER_END 0x82
#define PC_KEYBOARD_BUFFER_START 0x1e
#define PC_KEYBOARD_BUFFER_END 0x3e
#define PC_BDA_TIMER_TICKS_LOW 0x6c
#define PC_BDA_TIMER_TICKS_HIGH 0x6e
#define PC_BDA_MIDNIGHT_FLAG 0x70
#define PC_BDA_BREAK_FLAG 0x71
#define PC_BDA_BREAK_DETECTED_FLAG 0x80
#define PC_BDA_VIDEO_MODE_OPTIONS 0x87
#define PC_BDA_VIDEO_OPTIONS_88 0x88
#define PC_BDA_KEYBOARD_STATUS 0x96
#define PC_BDA_VIDEO_MODE 0x49
#define PC_BDA_VIDEO_COLUMNS 0x4a
#define PC_BDA_VIDEO_PAGE_SIZE 0x4c
#define PC_BDA_VIDEO_PAGE_OFFSET 0x4e
#define PC_BDA_VIDEO_ACTIVE_PAGE 0x62
#define PC_BDA_VIDEO_CRTC_PORT 0x63
#define PC_BDA_VIDEO_MODE_SELECT 0x65
#define PC_BDA_VIDEO_VGA_INFO 0x89
#define PC_BDA_VIDEO_ROWS 0x84
#define PC_BDA_VIDEO_CHARACTER_HEIGHT 0x85
#define PC_BDA_VIDEO_CURSOR_POSITIONS 0x50
#define PC_BDA_VIDEO_CURSOR_SHAPE 0x60

/* VGA register indices; the port address selects the register bank. */
#define PC_VGA_SEQ_MAP_MASK 0x02
#define PC_VGA_GC_SET_RESET 0x00
#define PC_VGA_GC_ENABLE_SET_RESET 0x01
#define PC_VGA_GC_COLOR_COMPARE 0x02
#define PC_VGA_GC_DATA_ROTATE 0x03
#define PC_VGA_GC_READ_MAP_SELECT 0x04
#define PC_VGA_GC_MODE 0x05
#define PC_VGA_GC_MISC 0x06
#define PC_VGA_GC_COLOR_DONT_CARE 0x07
#define PC_VGA_GC_BIT_MASK 0x08
#define PC_VGA_CRTC_OVERFLOW 0x07
#define PC_VGA_CRTC_CURSOR_START 0x0a
#define PC_VGA_CRTC_CURSOR_END 0x0b
#define PC_VGA_CRTC_START_ADDRESS_HIGH 0x0c
#define PC_VGA_CRTC_START_ADDRESS_LOW 0x0d
#define PC_VGA_CRTC_CURSOR_LOCATION_HIGH 0x0e
#define PC_VGA_CRTC_CURSOR_LOCATION_LOW 0x0f
#define PC_VGA_CRTC_MAX_SCAN_LINE 0x09
#define PC_VGA_CRTC_VERTICAL_DISPLAY_END 0x12
#define PC_VGA_CRTC_OFFSET 0x13
#define PC_VGA_CRTC_LINE_COMPARE 0x18
#define PC_VGA_ATTR_MODE_CONTROL 0x10
#define PC_VGA_ATTR_OVERSCAN_COLOR 0x11
#define PC_VGA_ATTR_COLOR_PLANE_ENABLE 0x12
#define PC_VGA_ATTR_PEL_PANNING 0x13

/* INT 10h AH selectors implemented by the video BIOS subset. */
#define PC_VIDEO_FN_SET_MODE 0x00
#define PC_VIDEO_FN_SET_CURSOR_SHAPE 0x01
#define PC_VIDEO_FN_SET_CURSOR_POSITION 0x02
#define PC_VIDEO_FN_GET_CURSOR_POSITION 0x03
#define PC_VIDEO_FN_SET_ACTIVE_PAGE 0x05
#define PC_VIDEO_FN_READ_CHARACTER 0x08
#define PC_VIDEO_FN_WRITE_CHARACTER_ATTRIBUTE 0x09
#define PC_VIDEO_FN_WRITE_CHARACTER 0x0a
#define PC_VIDEO_FN_SET_OVERSCAN 0x0b
#define PC_VIDEO_FN_GET_MODE 0x0f
#define PC_VIDEO_FN_PALETTE 0x10
#define PC_VIDEO_FN_FONT 0x11
#define PC_VIDEO_FN_EGA_INFO 0x12
#define PC_VIDEO_FN_DISPLAY_COMBINATION 0x1a
#define PC_VIDEO_FN_VGA_STATE_INFO 0x1b
#define PC_VIDEO_FN_VGA_STATE_SIZE 0x1c
#define PC_VIDEO_FONT_QUERY_INFO 0x30
#define PC_VIDEO_EGA_QUERY_SWITCHES 0x10
#define PC_VIDEO_AX_FONT_QUERY_INFO 0x1130

/* CMOS real-time clock register indices selected through ports 70h/71h. */
#define PC_CMOS_SECONDS 0x00
#define PC_CMOS_MINUTES 0x02
#define PC_CMOS_HOURS 0x04
#define PC_CMOS_WEEKDAY 0x06
#define PC_CMOS_DAY_OF_MONTH 0x07
#define PC_CMOS_MONTH 0x08
#define PC_CMOS_YEAR 0x09
#define PC_CMOS_STATUS_A 0x0a
#define PC_CMOS_STATUS_B 0x0b
#define PC_CMOS_STATUS_D 0x0d
#define PC_RTC_EPOCH_UNIX_SECONDS 946684800
#define PC_GAME_PORT_READ_QUANTUM_US 8
#define PC_CMOS_INDEX_MASK 127
#define PC_CPU_FLAG_ZERO 0x40
#define PC_CPU_FLAG_ZERO_U 0x40u
#define PC_BDA_EQUIPMENT_JOYSTICK_PRESENT 0x1000
#define PC_BDA_EQUIPMENT_JOYSTICK_PRESENT_U 0x1000u

/* Set-1 make codes used by the keyboard controller and SDL key translation. */
#define PC_SCAN_ESCAPE 0x01
#define PC_SCAN_A 0x1e
#define PC_SCAN_B 0x30
#define PC_SCAN_C 0x2e
#define PC_SCAN_D 0x20
#define PC_SCAN_E 0x12
#define PC_SCAN_BACKSPACE 0x0e
#define PC_SCAN_RETURN 0x1c
#define PC_SCAN_LEFT_CTRL 0x1d
#define PC_SCAN_LEFT_CTRL_BREAK 0x9d
#define PC_SCAN_LEFT_SHIFT 0x2a
#define PC_SCAN_RIGHT_SHIFT 0x36
#define PC_SCAN_LEFT_ALT 0x38
#define PC_SCAN_LEFT_ALT_BREAK 0xb8
#define PC_SCAN_CAPS_LOCK 0x3a
#define PC_SCAN_NUM_LOCK 0x45
#define PC_SCAN_SCROLL_LOCK 0x46
#define PC_SCAN_INSERT 0x52
#define PC_SCAN_CURSOR_LEFT 0x4b
#define PC_SCAN_EXT_CURSOR_LEFT 0xe04b
#define PC_SCAN_F1 0x3b
#define PC_SCAN_F10 0x44
#define PC_SCAN_F11 0x57
#define PC_SCAN_F12 0x58
#define PC_SCAN_EXTENDED_PREFIX 0xe0
#define PC_SCAN_BREAK_BIT 0x80
#define PC_SCAN_CODE_MASK 0x7f

/* INT 16h AH selectors for BIOS key reads, peeks, and shift-flag queries. */
#define PC_KEYBOARD_FN_READ 0x00
#define PC_KEYBOARD_FN_CHECK 0x01
#define PC_KEYBOARD_FN_SHIFT_FLAGS 0x02
#define PC_KEYBOARD_FN_READ_EXTENDED 0x10
#define PC_KEYBOARD_FN_CHECK_EXTENDED 0x11
#define PC_KEYBOARD_FN_EXTENDED_SHIFT_FLAGS 0x12
#define PC_KEYBOARD_AX_CHECK 0x0100
#define PC_KEYBOARD_AX_SHIFT_FLAGS 0x0200

/* BDA keyboard shift-flag bits used when interpreting make/break codes. */
#define PC_KEYFLAG_RIGHT_SHIFT 0x01
#define PC_KEYFLAG_LEFT_SHIFT 0x02
#define PC_KEYFLAG_CTRL 0x04
#define PC_KEYFLAG_CTRL_U 0x04u
#define PC_KEYFLAG_ALT 0x08
#define PC_KEYFLAG_ALT_U 0x08u
#define PC_KEYFLAG_SCROLL_LOCK 0x10
#define PC_KEYFLAG_NUM_LOCK 0x20
#define PC_KEYFLAG_CAPS_LOCK 0x40
#define PC_KEYFLAG_INSERT 0x80
#define PC_KEYFLAG_SHIFT_MASK 0x03

/* Port 61h gate bits that route timer 2's square wave to the speaker. */
#define PC_SPEAKER_GATE_TIMER2 0x01
#define PC_SPEAKER_DATA_ENABLE 0x02
#define PC_SPEAKER_GATE_MASK 0x03
#define PC_SPEAKER_GATE_MASK_U 0x03u

/* Host lifecycle/test controls are deliberately outside the binding pc.h. */
int platform_init(int argc, char **argv);
void platform_shutdown(void);
int platform_quit_requested(void);
void platform_present(void);
int platform_screenshot(const char *path);
int platform_run(void (*entry)(void)); /* catches pc_terminate, returns DOS exit code */
void pc_clock_manual(int enabled);
void pc_clock_advance(uint64_t time_us); /* absolute, monotonic; poll delivers due events */
void pc_queue_scan(uint64_t time_us, uint8_t scan);
void pc_queue_key(uint64_t time_us, uint16_t set1, int down);
void pc_joystick_set(int connected, const int16_t axes[4], uint8_t buttons);
uint32_t pc_pit_divisor(unsigned channel);
uint64_t pc_irq_count(unsigned vector);
uint64_t pc_eoi_count(void);
int pc_speaker_capture(const char *path, uint64_t end_us);

void bios_set_mode(uint8_t mode);
uint8_t vga_mode(void);
void vga_set_adapter(int vga); /* default VGA; --ega chooses EGA */
int vga_is_vga(void);
void vga_dimensions(int *width, int *height);
void vga_render_indexed(uint8_t *pixels);
void vga_render_rgb(uint32_t *pixels);                /* 0xAARRGGBB, up to 720x480 */
void vga_scanout_dimensions(int *width, int *height); /* doubled physical VGA lines */
void vga_render_scanout_rgb(uint32_t *pixels);
uint32_t vga_colour_rgb(uint8_t palette_code);
const uint8_t *vga_palette_registers(void);
uint32_t vga_border_rgb(void);
void bios_video(pc_regs *r);
void pc_fonts_init(void);
farptr pc_font_pointer(unsigned height);
#endif
