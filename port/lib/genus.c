/* Genus PCX Programmer's Toolkit 3.56: game-selected EGA display path. */
#include "samlib.h"
#include "samlib_state.h"

#include <stdio.h>
#include <stdlib.h>

enum {
    video_interrupt = 0x10,
    dos_interrupt = 0x21,
    seq_index_port = 0x3c4,
    gc_index_port = 0x3ce,
    pcx_last_display = 21,
    display_record_bytes = 0x38,
    minimum_work_bytes = 0x800,
    work_buffer_reserve = 10,
    pcx_header_bytes = 128,
    manufacturer_byte = 0x0a,
    rle_run_marker = 0xc0,
    hercules_display = 9,
    status_open_failed = -1,
    status_small_buffer = -2,
    status_read_failed = -3,
    status_bad_header = -5,
    status_bad_display = -6,
    status_bad_mode = -7,
    status_no_descriptor = -999,
    read_state_buffer_bytes = 0,
    read_state_buffer_segment = 2,
    read_state_buffer_offset = 4,
    read_state_file_handle = 6,
    read_state_position_high = 8,
    read_state_position_low = 10,
    read_state_dispatch_ready = 12,
    display_bios_mode = 0x16,
    display_bits_per_pixel = 0x17,
    display_width = 0x18,
    display_height = 0x1a,
    display_scale_x = 0x1c,
    display_scale_y = 0x1d,
    display_video_segment = 0x1e,
    display_page_bytes = 0x20,
    display_device_class = 0x22,
    display_decode_offset = 0x24,
    display_decode_segment = 0x26,
    printer_state_port_index = 0,
    printer_state_scale_mode = 2,
    printer_state_form_feed_enabled = 4,
    printer_state_reset_enabled = 6,
    printer_state_scanline_bytes = 8,
    printer_reset_command = 0x0b,
    printer_copies_command = 0x0e,
    printer_orientation_command = 0x14,
    printer_margin_command = 0x1a,
    printer_form_feed_command = 0x22,
    printer_position_command = 0x28,
    printer_resolution_100 = 0x36,
    printer_resolution_150 = 0x3e,
    printer_resolution_300 = 0x46,
    printer_begin_raster_command = 0x4e,
    printer_end_raster_command = 0x54,
    printer_scanline_command = 0x59,
    printer_decimal_divisors = 0x69
};

typedef struct {
    uint8_t bios_mode;
    uint8_t bits_per_pixel;
    uint16_t width;
    uint16_t height;
    uint8_t scale_x;
    uint8_t scale_y;
    uint16_t video_segment;
    uint16_t page_bytes;
    uint16_t device_class;
} pcx_display_setup;

/* These values initialize the 22 static display descriptors in GENUS.ASM. */
static const pcx_display_setup display_setups[22] = {
    {0x04, 2, 320, 200, 1, 1, 0xb800, 0x0000, 1},
    {0x06, 1, 640, 200, 1, 1, 0xb800, 0x0000, 2},
    {0x0d, 1, 320, 200, 4, 8, 0xa000, 0x2000, 3},
    {0x0e, 1, 640, 200, 4, 4, 0xa000, 0x4000, 3},
    {0x0f, 1, 640, 350, 1, 2, 0xa000, 0x8000, 0},
    {0x10, 1, 640, 350, 4, 2, 0xa000, 0x8000, 3},
    {0x11, 1, 640, 480, 1, 1, 0xa000, 0x0000, 0},
    {0x12, 1, 640, 480, 4, 1, 0xa000, 0x0000, 4},
    {0x13, 8, 320, 200, 1, 1, 0xa000, 0x0000, 5},
    {0x00, 1, 720, 348, 1, 2, 0xb000, 0x8000, 0},
    {0x29, 1, 800, 600, 4, 1, 0xa000, 0x0000, 4},
    {0x2d, 8, 640, 350, 1, 1, 0xa000, 0x0000, 5},
    {0x2e, 8, 640, 480, 1, 1, 0xa000, 0x0000, 5},
    {0x30, 8, 800, 600, 1, 1, 0xa000, 0x0000, 5},
    {0x58, 1, 800, 600, 4, 1, 0xa000, 0x0000, 4},
    {0x59, 1, 800, 600, 1, 1, 0xa000, 0x0000, 0},
    {0x5e, 8, 640, 400, 1, 1, 0xa000, 0x0000, 5},
    {0x5f, 8, 640, 480, 1, 1, 0xa000, 0x0000, 5},
    {0x16, 1, 800, 600, 4, 1, 0xa000, 0x0000, 4},
    {0x1a, 8, 640, 400, 1, 1, 0xa000, 0x0000, 5},
    {0x1b, 8, 640, 480, 1, 1, 0xa000, 0x0000, 5},
    {0x1d, 8, 800, 600, 1, 1, 0xa000, 0x0000, 5}
};

static const samlib_data_offsets *data_offsets(const char *routine)
{
    return samlib_require_data_offsets(routine);
}

static uint16_t data_segment(void)
{
    return samlib_ds_segment();
}

static uint8_t ds_rd8(uint16_t offset)
{
    return pc_rd8(data_segment(), offset);
}

static uint16_t ds_rd16(uint16_t offset)
{
    return pc_rd16(data_segment(), offset);
}

static void ds_wr8(uint16_t offset, uint8_t value)
{
    pc_wr8(data_segment(), offset, value);
}

static void ds_wr16(uint16_t offset, uint16_t value)
{
    pc_wr16(data_segment(), offset, value);
}

static uint16_t display_offset(uint16_t index)
{
    return (uint16_t)(data_offsets("PcxDisplayTable")->PcxDisplayTable +
                      index * display_record_bytes);
}

static uint16_t descriptor_word(uint16_t descriptor, uint16_t field)
{
    return pc_rd16(data_segment(), (uint16_t)(descriptor + field));
}

static uint8_t descriptor_byte(uint16_t descriptor, uint16_t field)
{
    return pc_rd8(data_segment(), (uint16_t)(descriptor + field));
}

static void descriptor_write_word(uint16_t descriptor, uint16_t field, uint16_t value)
{
    pc_wr16(data_segment(), (uint16_t)(descriptor + field), value);
}

static void descriptor_write_byte(uint16_t descriptor, uint16_t field, uint8_t value)
{
    pc_wr8(data_segment(), (uint16_t)(descriptor + field), value);
}

static int16_t get_descriptor_offset(uint16_t index, uint16_t *offset)
{
    uint16_t candidate;
    if (index > pcx_last_display)
        return status_bad_display;
    candidate = display_offset(index);
    if (descriptor_byte(candidate, 0) != (uint8_t)index)
        return status_no_descriptor;
    *offset = candidate;
    return 0;
}

static int dos_call_succeeded(const pc_regs *registers)
{
    return (registers->flags & 1u) == 0;
}

static uint16_t read_far16(farptr pointer, uint16_t addend)
{
    return pc_rd16(FP_SEG(pointer), (uint16_t)(FP_OFF(pointer) + addend));
}

static uint8_t read_far8(farptr pointer, uint16_t addend)
{
    return pc_rd8(FP_SEG(pointer), (uint16_t)(FP_OFF(pointer) + addend));
}

static void write_short_string(uint16_t base, uint16_t field,
                               const uint8_t *bytes, uint8_t length)
{
    uint16_t target = (uint16_t)(base + field);
    ds_wr8(target, length);
    for (uint8_t i = 0; i < length; ++i)
        ds_wr8((uint16_t)(target + 1u + i), bytes[i]);
}

/* Adapter decoders other than EGA are not selected by the game. Their
   registered far callbacks fail explicitly if that unsupported path is used. */
static void unused_cga_decode(void) { fputs("PcxCgaDecodeContinuation is unused\n", stderr); abort(); }
static void unused_vga_decode(void) { fputs("PcxVga256DecodeContinuation is unused\n", stderr); abort(); }
static void unused_hercules_decode(void) { fputs("PcxHerculesDecodeContinuation is unused\n", stderr); abort(); }
static void unused_tseng_decode(void) { fputs("PcxTsengDecodeContinuation is unused\n", stderr); abort(); }
static void unused_paradise_decode(void) { fputs("PcxParadiseDecodeContinuation is unused\n", stderr); abort(); }
static void unused_video7_decode(void) { fputs("PcxVideo7DecodeContinuation is unused\n", stderr); abort(); }
static void ega_decode_callback(void);

static farptr dispatch_codes[7];

/* Accepts display indices 0..21 and stores the selected index; returns 0/-6. */
int16_t PcxSetDisplayType(uint16_t display_index)
{
    const samlib_data_offsets *offsets = data_offsets("PcxSetDisplayType");
    if (display_index > pcx_last_display)
        return status_bad_display;
    ds_wr16(offsets->PcxSelectedDisplay, display_index);
    return 0;
}

/* Returns the selected display index or toolkit error. */
int16_t PcxGetDisplayType(void)
{
    uint16_t selected = ds_rd16(data_offsets("PcxGetDisplayType")->PcxSelectedDisplay);
    if ((int16_t)selected < 0 || selected > pcx_last_display)
        return status_bad_display;
    return (int16_t)selected;
}

/* Returns the selected descriptor's far pointer or an encoded negative status. */
farptr PcxGetDisplayDescriptor(uint16_t display_index)
{
    uint16_t offset;
    int16_t status = get_descriptor_offset(display_index, &offset);
    if (status < 0)
        return FP(data_segment(), (uint16_t)status);
    return FP(data_segment(), offset);
}

/* Fills all 22 display descriptors and resets the display/read state. */
void PcxInitializeVideoDescriptors(void)
{
    const samlib_data_offsets *offsets = data_offsets("PcxInitializeVideoDescriptors");
    uint16_t state = offsets->PcxReadState;

    ds_wr16(offsets->PcxSelectedDisplay, 0xffff);
    ds_wr16(offsets->PcxGraphicsModeState, 0xffff);
    ds_wr16(offsets->PcxDisplayPageState, 0xffff);
    ds_wr16(offsets->PcxModeCheckPolicy, 1);
    ds_wr16((uint16_t)(state + read_state_file_handle), 0xffff);
    ds_wr16((uint16_t)(state + read_state_buffer_segment), 0xffff);
    ds_wr16((uint16_t)(state + read_state_buffer_offset), 0xffff);
    ds_wr16((uint16_t)(state + read_state_buffer_bytes), minimum_work_bytes);
    ds_wr8((uint16_t)(state + read_state_dispatch_ready), 0);
    for (uint16_t i = 0; i < 4; ++i)
        ds_wr8((uint16_t)(state + read_state_dispatch_ready + 1u + i), 0);

    for (uint16_t index = 0; index <= pcx_last_display; ++index) {
        uint16_t base = display_offset(index);
        const pcx_display_setup *setup = &display_setups[index];
        descriptor_write_byte(base, 0, (uint8_t)index);
        descriptor_write_byte(base, display_bios_mode, setup->bios_mode);
        descriptor_write_byte(base, display_bits_per_pixel, setup->bits_per_pixel);
        descriptor_write_word(base, display_width, setup->width);
        descriptor_write_word(base, display_height, setup->height);
        descriptor_write_byte(base, display_scale_x, setup->scale_x);
        descriptor_write_byte(base, display_scale_y, setup->scale_y);
        descriptor_write_word(base, display_video_segment, setup->video_segment);
        descriptor_write_word(base, display_page_bytes, setup->page_bytes);
        descriptor_write_word(base, display_device_class, setup->device_class);
        descriptor_write_word(base, display_decode_offset, 0);
        descriptor_write_word(base, display_decode_segment, 0);
        for (uint16_t field = 0x28; field < display_record_bytes; field += 2)
            descriptor_write_word(base, field, 0);
    }
}

/* Changes between graphics/text mode and checks the currently selected BIOS mode. */
int16_t PcxSetGraphicsOrTextMode(uint16_t graphics_enabled)
{
    const samlib_data_offsets *offsets = data_offsets("PcxSetGraphicsOrTextMode");
    int16_t selected = PcxGetDisplayType();
    uint16_t descriptor;
    int16_t status;
    pc_regs registers = {0};

    if (selected < 0)
        return selected;
    status = get_descriptor_offset((uint16_t)selected, &descriptor);
    if (status < 0)
        return status;
    if (graphics_enabled != 0 && graphics_enabled != 1)
        return status_bad_mode;

    ds_wr16(offsets->PcxGraphicsModeState, graphics_enabled);
    ds_wr16(offsets->PcxDisplayPageState, 0);
    if (graphics_enabled == 0) {
        registers.ax = 3;
        pc_bios_int(video_interrupt, &registers);
        return 0;
    }
    if (descriptor_byte(descriptor, 0) == hercules_display)
        return status_bad_mode; /* The game never selects Hercules. */

    registers.ax = 0x0f00;
    pc_bios_int(video_interrupt, &registers);
    if ((uint8_t)registers.ax == descriptor_byte(descriptor, display_bios_mode))
        return 0;
    registers.ax = descriptor_byte(descriptor, display_bios_mode);
    pc_bios_int(video_interrupt, &registers);
    return 0;
}

/* Selects decoder entries for all displays; only EGA mode is used by SAM. */
void PcxInitializeDisplayDispatch(void)
{
    const samlib_data_offsets *offsets = data_offsets("PcxInitializeDisplayDispatch");
    static const char *const names[7] = {
        "PcxCgaDecodeContinuation", "PcxEgaDecodeContinuation",
        "PcxVga256DecodeContinuation", "PcxHerculesDecodeContinuation",
        "PcxTsengDecodeContinuation", "PcxParadiseDecodeContinuation",
        "PcxVideo7DecodeContinuation"
    };
    static pc_code_fn const entries[7] = {
        unused_cga_decode, ega_decode_callback, unused_vga_decode,
        unused_hercules_decode, unused_tseng_decode,
        unused_paradise_decode, unused_video7_decode
    };
    static const uint8_t decoder_for_display[22] = {
        0, 0, 1, 1, 1, 1, 1, 1, 2, 3, 1, 4, 4, 4, 1, 1, 5, 5, 1, 6, 6, 6
    };
    uint16_t state = offsets->PcxReadState;

    for (uint16_t decoder = 0; decoder < 7; ++decoder)
        if (dispatch_codes[decoder] == 0)
            dispatch_codes[decoder] = pc_register_code(entries[decoder], names[decoder]);
    for (uint16_t display = 0; display <= pcx_last_display; ++display) {
        uint16_t base = display_offset(display);
        farptr code = dispatch_codes[decoder_for_display[display]];
        descriptor_write_word(base, display_decode_offset, FP_OFF(code));
        descriptor_write_word(base, display_decode_segment, FP_SEG(code));
    }
    ds_wr8((uint16_t)(state + read_state_dispatch_ready), 1);
}

static int refill_read_buffer(uint16_t cursor, uint16_t *new_cursor)
{
    const samlib_data_offsets *offsets = data_offsets("PcxRefillReadBuffer");
    uint16_t state = offsets->PcxReadState;
    uint16_t handle = ds_rd16((uint16_t)(state + read_state_file_handle));
    uint16_t buffer_segment = ds_rd16((uint16_t)(state + read_state_buffer_segment));
    uint16_t buffer_offset = ds_rd16((uint16_t)(state + read_state_buffer_offset));
    uint16_t buffer_bytes = ds_rd16((uint16_t)(state + read_state_buffer_bytes));
    uint16_t consumed;
    uint16_t position_low = ds_rd16((uint16_t)(state + read_state_position_low));
    uint16_t position_high = ds_rd16((uint16_t)(state + read_state_position_high));
    pc_regs registers = {0};

    if (handle == 0xffff)
        return 0;
    if (buffer_segment == 0xffff) {
        buffer_segment = data_segment();
        buffer_offset = offsets->PcxDefaultReadBuffer;
    }
    consumed = (uint16_t)(cursor - buffer_offset);
    position_low = (uint16_t)(position_low + consumed);
    if (position_low < consumed)
        ++position_high;
    ds_wr16((uint16_t)(state + read_state_position_low), position_low);
    ds_wr16((uint16_t)(state + read_state_position_high), position_high);

    registers.ax = 0x4200;
    registers.bx = handle;
    registers.cx = position_high;
    registers.dx = position_low;
    pc_bios_int(dos_interrupt, &registers);
    if (!dos_call_succeeded(&registers))
        return 0;

    registers.ax = 0x3f00;
    registers.bx = handle;
    registers.cx = buffer_bytes;
    registers.ds = buffer_segment;
    registers.dx = buffer_offset;
    pc_bios_int(dos_interrupt, &registers);
    if (!dos_call_succeeded(&registers))
        return 0;
    *new_cursor = buffer_offset;
    return 1;
}

static int16_t decode_ega_buffer(farptr image, uint16_t available_bytes,
                                 uint16_t image_x, uint16_t image_y,
                                 uint16_t video_page, uint16_t descriptor)
{
    uint16_t source_segment = FP_SEG(image);
    uint16_t source_offset = FP_OFF(image);
    uint16_t cursor = (uint16_t)(source_offset + pcx_header_bytes);
    uint16_t buffer_end = (uint16_t)(source_offset + available_bytes - 1u);
    uint16_t visible_width = (uint16_t)(read_far16(image, 8) - read_far16(image, 4) + 1u);
    uint16_t visible_height = (uint16_t)(read_far16(image, 10) - read_far16(image, 6) + 1u);
    uint16_t screen_width = descriptor_word(descriptor, display_width);
    uint16_t screen_height = descriptor_word(descriptor, display_height);
    uint16_t width_end = (uint16_t)(image_x + visible_width);
    uint16_t row_pixels = visible_width;
    uint16_t row_bytes_last;
    uint16_t row_bytes_in_header = read_far16(image, 0x42);
    uint16_t height = visible_height;
    uint16_t page_bytes = descriptor_word(descriptor, display_page_bytes);
    uint16_t stride_bytes = (uint16_t)(screen_width >> 3);
    uint16_t video_offset;
    uint8_t remainder;
    uint8_t partial_mask = 0;
    uint8_t partial_byte = 0;
    uint8_t planes = read_far8(image, 0x41);
    uint16_t plane_limit = 8;
    uint8_t initial_plane_mask = 1;
    uint8_t plane_mask = 1;
    uint16_t byte_in_plane = 0;
    uint16_t rows_left;

    if (width_end > screen_width) {
        row_pixels = (uint16_t)(screen_width - image_x + 1u);
        if ((row_pixels & 7u) != 0) {
            ++row_pixels;
            row_pixels = (uint16_t)((row_pixels & 0xff00u) | ((uint8_t)row_pixels & 0xf8u));
        }
    }
    {
        uint16_t bit_count = (uint16_t)(row_pixels * read_far8(image, 3));
        row_bytes_last = (uint16_t)(bit_count >> 3);
        remainder = (uint8_t)(bit_count & 7u);
        if (remainder == 0) {
            --row_bytes_last;
        } else {
            partial_byte = 1;
            partial_mask = (uint8_t)(0xffu << (8u - remainder));
        }
    }

    if ((uint16_t)(image_y + visible_height) > screen_height)
        height = (uint16_t)(screen_height - image_y + 1u);
    rows_left = height;
    video_offset = (uint16_t)((uint32_t)page_bytes * video_page + (image_x >> 3) +
                              (uint32_t)image_y * stride_bytes);

    (void)vga_port_write(gc_index_port, 5);
    (void)vga_port_write((uint16_t)(gc_index_port + 1), 0);
    (void)vga_port_write(gc_index_port, 8);
    (void)vga_port_write((uint16_t)(gc_index_port + 1), 0xff);
    (void)vga_port_write(seq_index_port, 2);
    if (planes == 3)
        plane_limit = 4;
    if (planes == 1) {
        initial_plane_mask = 0x0f;
        plane_mask = 0x0f;
        plane_limit = 1;
    }
    (void)vga_port_write((uint16_t)(seq_index_port + 1), plane_mask);

    while (rows_left != 0) {
        uint8_t encoded;
        uint32_t run;
        uint8_t value;

        if (cursor > buffer_end) {
            if (!refill_read_buffer(cursor, &cursor))
                return status_read_failed;
            buffer_end = (uint16_t)(source_offset + available_bytes - 1u);
            source_offset = cursor;
            source_segment = ds_rd16((uint16_t)(data_offsets("PcxDisplayBuffer")->PcxReadState +
                                                 read_state_buffer_segment));
            if (source_segment == 0xffff)
                source_segment = data_segment();
            buffer_end = (uint16_t)(cursor + available_bytes - 1u);
        }

        encoded = pc_rd8(source_segment, cursor++);
        if ((encoded & 0xc0u) == rle_run_marker) {
            run = (uint32_t)(encoded & 0x3fu);
            value = pc_rd8(source_segment, cursor++);
            if (run == 0)
                run = 0x10000u;
        } else {
            run = 1;
            value = encoded;
        }

        while (run != 0) {
            uint16_t target = (uint16_t)(video_offset + byte_in_plane);
            if (byte_in_plane < row_bytes_last) {
                vga_cpu_write(target, value);
            } else if (byte_in_plane == row_bytes_last) {
                if (partial_byte) {
                    (void)vga_port_write(gc_index_port, 8);
                    (void)vga_port_write((uint16_t)(gc_index_port + 1), partial_mask);
                    (void)vga_cpu_read(target);
                    vga_cpu_write(target, value);
                    (void)vga_port_write(gc_index_port, 8);
                    (void)vga_port_write((uint16_t)(gc_index_port + 1), 0xff);
                } else {
                    vga_cpu_write(target, value);
                }
            }
            ++byte_in_plane;
            if (byte_in_plane == row_bytes_in_header) {
                byte_in_plane = 0;
                plane_mask = (uint8_t)(plane_mask << 1);
                if (plane_mask <= plane_limit) {
                    (void)vga_port_write(seq_index_port, 2);
                    (void)vga_port_write((uint16_t)(seq_index_port + 1), plane_mask);
                } else {
                    plane_mask = initial_plane_mask;
                    video_offset = (uint16_t)(video_offset + stride_bytes);
                    --rows_left;
                    if (rows_left == 0) {
                        (void)vga_port_write(seq_index_port, 2);
                        (void)vga_port_write((uint16_t)(seq_index_port + 1), 0xff);
                        return 0;
                    }
                    (void)vga_port_write(seq_index_port, 2);
                    (void)vga_port_write((uint16_t)(seq_index_port + 1), plane_mask);
                }
            }
            --run;
        }
    }
    return 0;
}

typedef struct {
    farptr image;
    uint16_t available_bytes;
    uint16_t image_x;
    uint16_t image_y;
    uint16_t video_page;
    uint16_t descriptor;
    int16_t result;
} ega_decode_call;

static ega_decode_call active_ega_decode;

static void ega_decode_callback(void)
{
    active_ega_decode.result = decode_ega_buffer(
        active_ega_decode.image, active_ega_decode.available_bytes,
        active_ega_decode.image_x, active_ega_decode.image_y,
        active_ega_decode.video_page, active_ega_decode.descriptor);
}

/* Validates the PCX manufacturer, selected display and active BIOS mode. */
int16_t PcxDisplayBuffer(farptr pcx_image_buffer, uint16_t available_buffer_bytes,
                         uint16_t image_x, uint16_t image_y, uint16_t video_page)
{
    const samlib_data_offsets *offsets = data_offsets("PcxDisplayBuffer");
    uint16_t descriptor;
    int16_t selected;
    int16_t status;
    pc_regs registers = {0};
    farptr decoder;

    if (ds_rd8((uint16_t)(offsets->PcxReadState + read_state_dispatch_ready)) != 1)
        PcxInitializeDisplayDispatch();
    if (read_far8(pcx_image_buffer, 0) != manufacturer_byte)
        return status_bad_header;
    selected = PcxGetDisplayType();
    if (selected < 0)
        return selected;
    status = get_descriptor_offset((uint16_t)selected, &descriptor);
    if (status < 0)
        return status;
    if (ds_rd16(offsets->PcxModeCheckPolicy) == 1 &&
        descriptor_byte(descriptor, 0) != hercules_display) {
        registers.ax = 0x0f00;
        pc_bios_int(video_interrupt, &registers);
        if ((uint8_t)registers.ax != descriptor_byte(descriptor, display_bios_mode))
            return status_bad_mode;
    }
    decoder = FP(descriptor_word(descriptor, display_decode_segment),
                 descriptor_word(descriptor, display_decode_offset));
    active_ega_decode.image = pcx_image_buffer;
    active_ega_decode.available_bytes = available_buffer_bytes;
    active_ega_decode.image_x = image_x;
    active_ega_decode.image_y = image_y;
    active_ega_decode.video_page = video_page;
    active_ega_decode.descriptor = descriptor;
    active_ega_decode.result = status_bad_mode;
    pc_call_far(decoder);
    return active_ega_decode.result;
}

static uint16_t copy_filename_to_default_buffer(farptr filename)
{
    const samlib_data_offsets *offsets = data_offsets("PcxDisplayFile");
    uint8_t length = read_far8(filename, 0);
    uint16_t target = offsets->PcxDefaultReadBuffer;
    for (uint16_t i = 0; i < length; ++i)
        ds_wr8((uint16_t)(target + i), read_far8(filename, (uint16_t)(i + 1u)));
    ds_wr8((uint16_t)(target + length), 0);
    return target;
}

/* Opens and reads a DOS PCX file into the configured read buffer, then decodes it. */
int16_t PcxDisplayFile(farptr image_file_name, uint16_t image_x,
                       uint16_t image_y, uint16_t video_page)
{
    const samlib_data_offsets *offsets = data_offsets("PcxDisplayFile");
    uint16_t state = offsets->PcxReadState;
    uint16_t path_offset = copy_filename_to_default_buffer(image_file_name);
    uint16_t target_segment = ds_rd16((uint16_t)(state + read_state_buffer_segment));
    uint16_t target_offset = ds_rd16((uint16_t)(state + read_state_buffer_offset));
    uint16_t buffer_bytes = ds_rd16((uint16_t)(state + read_state_buffer_bytes));
    pc_regs registers = {0};
    int16_t result;

    if (target_segment == 0xffff) {
        target_segment = data_segment();
        target_offset = offsets->PcxDefaultReadBuffer;
    }
    registers.ax = 0x3d00;
    registers.ds = data_segment();
    registers.dx = path_offset;
    pc_bios_int(dos_interrupt, &registers);
    ds_wr16((uint16_t)(state + read_state_file_handle), registers.ax);
    if (!dos_call_succeeded(&registers)) {
        result = status_open_failed;
        goto finished;
    }

    ds_wr16((uint16_t)(state + read_state_position_high), 0);
    ds_wr16((uint16_t)(state + read_state_position_low), 0);
    registers.ax = 0x3f00;
    registers.bx = ds_rd16((uint16_t)(state + read_state_file_handle));
    registers.cx = buffer_bytes;
    registers.ds = target_segment;
    registers.dx = target_offset;
    pc_bios_int(dos_interrupt, &registers);
    if (!dos_call_succeeded(&registers)) {
        result = status_read_failed;
        goto close_file;
    }
    result = PcxDisplayBuffer(FP(target_segment, target_offset),
                              (uint16_t)(buffer_bytes - work_buffer_reserve),
                              image_x, image_y, video_page);

close_file:
    registers.ax = 0x3e00;
    registers.bx = ds_rd16((uint16_t)(state + read_state_file_handle));
    pc_bios_int(dos_interrupt, &registers);
finished:
    ds_wr16((uint16_t)(state + read_state_file_handle), 0xffff);
    return result;
}

/* Printer support is not called by the game; keep an explicit aborting entry. */
int16_t PcxBeginPrinterImage(uint16_t source_row_bytes, uint16_t printer_x,
                             uint16_t printer_y)
{
    (void)source_row_bytes; (void)printer_x; (void)printer_y;
    fputs("PcxBeginPrinterImage is unused by Secret Agent\n", stderr);
    abort();
}

/* Printer support is not called by the game; keep an explicit aborting entry. */
void PcxEndPrinterImage(void)
{
    fputs("PcxEndPrinterImage is unused by Secret Agent\n", stderr);
    abort();
}

/* Decimal formatting exists only for printer output, which the game does not call. */
uint16_t PcxFormatUnsignedDecimal(int32_t unsigned_value, farptr digit_buffer)
{
    (void)unsigned_value; (void)digit_buffer;
    fputs("PcxFormatUnsignedDecimal is unused by Secret Agent\n", stderr);
    abort();
}

/* Installs the original default printer commands and decimal divisors. */
void PcxInitializePrinterState(void)
{
    const samlib_data_offsets *offsets = data_offsets("PcxInitializePrinterState");
    uint16_t base = offsets->PcxPrinterState;
    static const uint8_t reset[] = {0x1b, 'E'};
    static const uint8_t copies[] = {0x1b, '&', 'l', '1', 'X'};
    static const uint8_t orientation[] = {0x1b, '&', 'l', '0', 'O'};
    static const uint8_t margin[] = {0x1b, '&', 'l', '2', 'E', 0x1b, '9'};
    static const uint8_t form_feed[] = {0x1b, '&', 'l', '0', 'H'};
    static const uint8_t position[] = {0x1b, '*', 'p'};
    static const uint8_t resolution_100[] = {0x1b, '*', 't', '1', '0', '0', 'R'};
    static const uint8_t resolution_150[] = {0x1b, '*', 't', '1', '5', '0', 'R'};
    static const uint8_t resolution_300[] = {0x1b, '*', 't', '3', '0', '0', 'R'};
    static const uint8_t begin_raster[] = {0x1b, '*', 'r', '1', 'A'};
    static const uint8_t end_raster[] = {0x1b, '*', 'r', 'B'};
    static const uint8_t scanline[] = {0x1b, '*', 'b'};
    static const uint32_t divisors[10] = {
        1000000000u, 100000000u, 10000000u, 1000000u, 100000u,
        10000u, 1000u, 100u, 10u, 1u
    };

    ds_wr16(offsets->PcxPrinterDeviceClass, 0);
    ds_wr16(offsets->PcxPrinterResolutionClass, 1);
    ds_wr16((uint16_t)(base + printer_state_port_index), 0);
    ds_wr16((uint16_t)(base + printer_state_scale_mode), 0);
    ds_wr16((uint16_t)(base + printer_state_form_feed_enabled), 1);
    ds_wr16((uint16_t)(base + printer_state_reset_enabled), 1);
    write_short_string(base, printer_reset_command, reset, sizeof(reset));
    write_short_string(base, printer_copies_command, copies, sizeof(copies));
    write_short_string(base, printer_orientation_command, orientation, sizeof(orientation));
    write_short_string(base, printer_margin_command, margin, sizeof(margin));
    write_short_string(base, printer_form_feed_command, form_feed, sizeof(form_feed));
    write_short_string(base, printer_position_command, position, sizeof(position));
    write_short_string(base, printer_resolution_100, resolution_100, sizeof(resolution_100));
    write_short_string(base, printer_resolution_150, resolution_150, sizeof(resolution_150));
    write_short_string(base, printer_resolution_300, resolution_300, sizeof(resolution_300));
    write_short_string(base, printer_begin_raster_command, begin_raster, sizeof(begin_raster));
    write_short_string(base, printer_end_raster_command, end_raster, sizeof(end_raster));
    write_short_string(base, printer_scanline_command, scanline, sizeof(scanline));
    for (uint16_t i = 0; i < 10; ++i) {
        uint16_t field = (uint16_t)(base + printer_decimal_divisors + i * 4u);
        pc_wr16(data_segment(), field, (uint16_t)divisors[i]);
        pc_wr16(data_segment(), (uint16_t)(field + 2u), (uint16_t)(divisors[i] >> 16));
    }
}
