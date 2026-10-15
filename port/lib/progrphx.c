/* ProGraphx 2.0 screen-mode, EGA drawing and screen-copy entry points. */
#include "samlib.h"

#include <stddef.h>

enum {
    bios_video_interrupt = 0x10,
    attribute_port = 0x3c0,
    sequencer_index_port = 0x3c4,
    sequencer_data_port = 0x3c5,
    graphics_index_port = 0x3ce,
    graphics_data_port = 0x3cf,
    crtc_index_port = 0x3d4,
    input_status_1_port = 0x3da,
    bios_data_segment = 0x0040,
    bda_crtc_port_offset = 0x0063,
    vertical_retrace_bit = 0x08,
    default_stride_bytes = 40,
    video_page_bytes = 0x2000,
    cached_tiles_offset = 0xfa00,
    seq_map_mask = 2,
    gc_bit_mask = 8,
    gc_mode = 5,
    gc_read_map_select = 4,
    crtc_start_high = 0x0c,
    crtc_start_low = 0x0d,
    crtc_offset = 0x13,
    crtc_line_compare = 0x18
};

/* State held by PROGRAPX.ASM in its code segment. */
static uint16_t screen_stride_bytes = default_stride_bytes;
static uint16_t draw_page;
static uint16_t draw_color = 1;
static uint16_t font8_segment, font8_offset, font14_segment, font14_offset;
static uint16_t font8_height = 8, font14_height = 14;
static uint16_t selected_font_segment, selected_font_offset;
static uint16_t selected_font_height = 14;
static uint16_t transfer_rows_remaining, transfer_row_bytes;
static uint8_t sprite_bytes_remaining, sprite_right_shift, sprite_left_shift;
static uint8_t sprite_source_mask, sprite_plane_byte[4];
static uint8_t glyph_left_shift, glyph_mask_high, glyph_mask_low;

void samlib_progrphx_reset(void)
{
    screen_stride_bytes = default_stride_bytes;
    draw_page = 0; draw_color = 1;
    font8_segment = font8_offset = font14_segment = font14_offset = 0;
    font8_height = 8; font14_height = selected_font_height = 14;
    selected_font_segment = selected_font_offset = 0;
    transfer_rows_remaining = transfer_row_bytes = 0;
    sprite_bytes_remaining = sprite_right_shift = sprite_left_shift = sprite_source_mask = 0;
    for (unsigned plane = 0; plane < 4; ++plane) sprite_plane_byte[plane] = 0;
    glyph_left_shift = glyph_mask_high = glyph_mask_low = 0;
}

#ifdef SAM_LIBDIFF_TEST
void libdiff_progrphx_set_state(const uint16_t values[25])
{
    screen_stride_bytes = values[0];
    draw_page = values[1];
    draw_color = values[2];
    font8_offset = values[3];
    font8_segment = values[4];
    font8_height = values[5];
    font14_offset = values[6];
    font14_segment = values[7];
    font14_height = values[8];
    selected_font_offset = values[9];
    selected_font_segment = values[10];
    selected_font_height = values[11];
    transfer_rows_remaining = values[12];
    transfer_row_bytes = values[13];
    sprite_bytes_remaining = (uint8_t)values[14];
    sprite_right_shift = (uint8_t)values[15];
    sprite_left_shift = (uint8_t)values[16];
    sprite_source_mask = (uint8_t)values[17];
    for (unsigned plane = 0; plane < 4; ++plane)
        sprite_plane_byte[plane] = (uint8_t)values[18 + plane];
    glyph_left_shift = (uint8_t)values[22];
    glyph_mask_high = (uint8_t)values[23];
    glyph_mask_low = (uint8_t)values[24];
}

void libdiff_progrphx_get_state(uint16_t values[25])
{
    values[0] = screen_stride_bytes;
    values[1] = draw_page;
    values[2] = draw_color;
    values[3] = font8_offset;
    values[4] = font8_segment;
    values[5] = font8_height;
    values[6] = font14_offset;
    values[7] = font14_segment;
    values[8] = font14_height;
    values[9] = selected_font_offset;
    values[10] = selected_font_segment;
    values[11] = selected_font_height;
    values[12] = transfer_rows_remaining;
    values[13] = transfer_row_bytes;
    values[14] = sprite_bytes_remaining;
    values[15] = sprite_right_shift;
    values[16] = sprite_left_shift;
    values[17] = sprite_source_mask;
    for (unsigned plane = 0; plane < 4; ++plane)
        values[18 + plane] = sprite_plane_byte[plane];
    values[22] = glyph_left_shift;
    values[23] = glyph_mask_high;
    values[24] = glyph_mask_low;
}
#endif

/* Differential-harness twin of the assembly's private PgSelectDrawPage. */
static void vga_index_data(uint16_t index_port, uint8_t index, uint8_t data)
{
    (void)vga_port_write(index_port, index);
    (void)vga_port_write((uint16_t)(index_port + 1), data);
}

static void wait_retrace_level(int set)
{
    uint8_t value;
    for (;;) {
        value = pc_inb(input_status_1_port);
        if (((value & vertical_retrace_bit) != 0) == (set != 0))
            return;
        pc_wait_video_status(vertical_retrace_bit,set ? vertical_retrace_bit : 0);
    }
}

static uint8_t read_vga_port(uint16_t port)
{
    uint8_t value = 0xff;
    if (!vga_port_read(port, &value))
        value = pc_inb(port);
    return value;
}

static void wait_retrace_start_then_end(void)
{
    wait_retrace_level(1);
    wait_retrace_level(0);
}

static uint16_t screen_offset(uint16_t xbyte, uint16_t y)
{
    return (uint16_t)((uint32_t)xbyte + (uint32_t)y * screen_stride_bytes);
}

static void add_draw_page(uint16_t *offset)
{
    uint16_t page = draw_page;
    while (page != 0) {
        *offset = (uint16_t)(*offset + video_page_bytes);
        --page;
    }
}

/* The three original entries below load their page LOOP count from entry AX.
   At every game call site AX is the last Pascal argument pushed by the caller. */
static void add_entry_ax_page_offset(uint16_t *offset, uint16_t entry_ax)
{
    if ((uint8_t)draw_page != 0)
        *offset = (uint16_t)(*offset + (uint16_t)((uint32_t)entry_ax * video_page_bytes));
}

static void vga_exchange(uint16_t offset, uint8_t value)
{
    (void)vga_cpu_read(offset);
    vga_cpu_write(offset, value);
}

static void planar_blit_byte(uint16_t offset, uint8_t source_mask,
                             const uint8_t source_planes[4], int masked)
{
    unsigned plane;
    if (masked)
        vga_index_data(graphics_index_port, gc_bit_mask, source_mask);
    for (plane = 0; plane < 4; ++plane) {
        (void)vga_port_write(sequencer_data_port, (uint8_t)(1u << plane));
        vga_exchange(offset, source_planes[plane]);
    }
}

static void restore_common_graphics_state(void)
{
    (void)vga_port_write(sequencer_data_port, 0x0f);
    vga_index_data(graphics_index_port, gc_bit_mask, 0xff);
}

static void masked_sprite(uint8_t *source, uint16_t xbyte, uint16_t y,
                          unsigned rows, unsigned groups_per_row,
                          uint16_t row_advance, int page,
                          int entry_ax_page_loop, uint16_t entry_ax)
{
    unsigned row, group, plane;
    uint16_t offset = screen_offset(xbyte, y);
    if (page) {
        if (entry_ax_page_loop)
            add_entry_ax_page_offset(&offset, entry_ax);
        else
            add_draw_page(&offset);
    }

    (void)vga_port_write(sequencer_index_port, seq_map_mask);
    for (row = 0; row < rows; ++row) {
        for (group = 0; group < groups_per_row; ++group) {
            uint8_t mask = *source++;
            uint8_t pixels[4];
            for (plane = 0; plane < 4; ++plane)
                pixels[plane] = *source++;
            planar_blit_byte(offset, mask, pixels, 1);
            ++offset;
        }
        offset = (uint16_t)(offset + row_advance);
    }
    restore_common_graphics_state();
}

static void opaque_sprite(uint8_t *source, uint16_t xbyte, uint16_t y,
                          unsigned rows, unsigned groups_per_row,
                          uint16_t row_advance, int page,
                          int entry_ax_page_loop, uint16_t entry_ax)
{
    unsigned row, group, plane;
    uint16_t offset = screen_offset(xbyte, y);
    if (page) {
        if (entry_ax_page_loop)
            add_entry_ax_page_offset(&offset, entry_ax);
        else
            add_draw_page(&offset);
    }

    (void)vga_port_write(sequencer_index_port, seq_map_mask);
    for (row = 0; row < rows; ++row) {
        for (group = 0; group < groups_per_row; ++group) {
            uint8_t pixels[4];
            ++source; /* The mask byte is present in the opaque source format. */
            for (plane = 0; plane < 4; ++plane)
                pixels[plane] = *source++;
            planar_blit_byte(offset, 0xff, pixels, 0);
            ++offset;
        }
        offset = (uint16_t)(offset + row_advance);
    }
    restore_common_graphics_state();
}

/* Maps toolbox mode 0/1/other to BIOS 0Dh/10h/12h. */
void PgSetToolboxVideoMode(uint16_t toolbox_mode)
{
    pc_regs registers = {0};
    uint8_t mode = (uint8_t)toolbox_mode;
    uint8_t ah = (uint8_t)(toolbox_mode >> 8);
    if (mode == 0)
        mode = 0x0d;
    else if (mode == 1)
        mode = 0x10;
    else {
        mode = 0x12;
        ah = 0;
    }
    registers.ax = (uint16_t)(((uint16_t)ah << 8) | mode);
    pc_bios_int(bios_video_interrupt, &registers);
}

/* Sets a BIOS video mode directly with AH=0. */
void PgSetBiosVideoMode(uint16_t bios_mode)
{
    pc_regs registers = {0};
    registers.ax = (uint8_t)bios_mode;
    pc_bios_int(bios_video_interrupt, &registers);
}

/* Clamps the planar row stride to at least 40 bytes and programs CRTC offset. */
int16_t PgSetScreenStride(uint16_t stride_bytes)
{
    uint16_t entry_ax = stride_bytes;
    if ((int16_t)stride_bytes < default_stride_bytes)
        stride_bytes = default_stride_bytes;
    screen_stride_bytes = stride_bytes;
    (void)vga_port_write(crtc_index_port, crtc_offset);
    (void)vga_port_write((uint16_t)(crtc_index_port + 1), 0);
    stride_bytes >>= 1;
    (void)vga_port_write((uint16_t)(crtc_index_port + 1), (uint8_t)stride_bytes);
    pc_outb((uint16_t)(crtc_index_port + 2), (uint8_t)(stride_bytes >> 8));
    /* All linked Pascal call sites load this argument through AX before
       pushing it, so the declared Integer result is the incoming value. */
    return (int16_t)entry_ax;
}

/* Sets the display start, then fine pan at the next retrace start. */
void PgPanDisplayAtRetraceStart(uint16_t pan_pixel_x, uint16_t pan_pixel_y)
{
    uint16_t start;
    wait_retrace_start_then_end();
    pc_cli();
    start = (uint16_t)(pan_pixel_y * screen_stride_bytes + (pan_pixel_x >> 3));
    vga_index_data(crtc_index_port, crtc_start_high, (uint8_t)(start >> 8));
    vga_index_data(crtc_index_port, crtc_start_low, (uint8_t)start);
    pc_sti();

    wait_retrace_level(1);
    pc_cli();
    (void)vga_port_write(attribute_port, 0x33);
    (void)vga_port_write(attribute_port, (uint8_t)(0x10 | (pan_pixel_x & 7)));
    pc_sti();
}

/* Sets the display start, then fine pan while retrace is clear. */
void PgPanDisplayAtRetraceEnd(uint16_t pan_pixel_x, uint16_t pan_pixel_y)
{
    uint16_t start;
    wait_retrace_start_then_end();
    pc_cli();
    start = (uint16_t)(pan_pixel_y * screen_stride_bytes + (pan_pixel_x >> 3));
    vga_index_data(crtc_index_port, crtc_start_high, (uint8_t)(start >> 8));
    vga_index_data(crtc_index_port, crtc_start_low, (uint8_t)start);
    pc_sti();

    wait_retrace_level(0);
    pc_cli();
    (void)vga_port_write(attribute_port, 0x33);
    (void)vga_port_write(attribute_port, (uint8_t)(0x10 | (pan_pixel_x & 7)));
    pc_sti();
}

/* Programs EGA line compare and its bit-8 overflow. */
void PgSetEgaSplitScanline(uint16_t split_scanline)
{
    uint16_t crtc = pc_rd16(bios_data_segment, bda_crtc_port_offset);
    uint8_t high_bit = (uint8_t)(((split_scanline >> 8) & 1) << 4);
    crtc = (uint16_t)(crtc + 6);
    wait_retrace_level(0);
    wait_retrace_level(1);
    crtc = (uint16_t)(crtc - 6);
    vga_index_data(crtc, crtc_line_compare, (uint8_t)split_scanline);
    vga_index_data(crtc, 7, (uint8_t)(0x01 | high_bit));
}

/* Waits for the current retrace to end and the next retrace to start. */
void PgWaitVerticalRetrace(void)
{
    uint8_t status = pc_inb(input_status_1_port);
    if ((status & vertical_retrace_bit) != 0)
        wait_retrace_level(0);
    wait_retrace_level(1);
}

/* Programs VGA line compare, overflow bit 8, and maximum scan line. */
void PgSetVgaSplitScanline(uint16_t split_scanline)
{
    uint8_t overflow, max_scan_line;
    PgWaitVerticalRetrace();
    (void)vga_port_write(crtc_index_port, crtc_line_compare);
    (void)vga_port_write((uint16_t)(crtc_index_port + 1), (uint8_t)split_scanline);
    (void)vga_port_write(crtc_index_port, 7);
    overflow = read_vga_port((uint16_t)(crtc_index_port + 1));
    overflow = (uint8_t)((overflow & 0xef) | (((split_scanline >> 8) & 1) << 4));
    (void)vga_port_write((uint16_t)(crtc_index_port + 1), overflow);
    (void)vga_port_write(crtc_index_port, 9);
    max_scan_line = read_vga_port((uint16_t)(crtc_index_port + 1));
    (void)vga_port_write((uint16_t)(crtc_index_port + 1), (uint8_t)(max_scan_line & 0xbf));
}

/* Sets the BIOS border/overscan color. */
void PgSetBorderColor(uint16_t border_color)
{
    pc_regs registers = {0};
    uint8_t color = (uint8_t)border_color;
    registers.ax = 0x1001;
    registers.bx = (uint16_t)(((uint16_t)color << 8) | color);
    pc_bios_int(bios_video_interrupt, &registers);
}

/* Assigns one EGA palette register through BIOS INT 10h AX=1000h. */
void PgSetPaletteRegister(int16_t palette_index, int16_t palette_color)
{
    pc_regs registers = {0};
    registers.ax = 0x1000;
    registers.bx = (uint16_t)(((uint16_t)(uint8_t)palette_color << 8) |
                              (uint8_t)palette_index);
    pc_bios_int(bios_video_interrupt, &registers);
}

/* Draws 16 rows of mask plus four plane bytes at a byte-aligned position. */
void PgBlitMasked16x16(farptr image_source_far, int16_t byte_column, int16_t pixel_row)
{
    uint8_t *image_source = pc_host_fp(image_source_far);
    masked_sprite(image_source, (uint16_t)byte_column, (uint16_t)pixel_row,
                  16, 2, (uint16_t)(screen_stride_bytes - 2), 1, 0, 0);
}

/* Draws eight rows of mask plus four plane bytes at a byte-aligned position. */
void PgBlitMasked8x8(farptr image_source_far, int16_t byte_column, int16_t pixel_row)
{
    uint8_t *image_source = pc_host_fp(image_source_far);
    masked_sprite(image_source, (uint16_t)byte_column, (uint16_t)pixel_row,
                  8, 1, (uint16_t)(screen_stride_bytes - 1), 1, 1,
                  (uint16_t)pixel_row);
}

/* Stores the four-plane fill/pixel color in assembly code-segment state. */
void PgSetDrawColor(uint16_t color)
{
    draw_color = color;
}

/* Fills WidthBytes by HeightRows on the selected draw page. */
void PgFillRectangleByteAligned(uint16_t left_byte_column, uint16_t width_bytes,
                                uint16_t top_pixel_row, uint16_t height_rows)
{
    uint16_t offset = screen_offset(left_byte_column, top_pixel_row);
    uint16_t row;
    add_entry_ax_page_offset(&offset, height_rows);
    (void)vga_port_write(sequencer_index_port, seq_map_mask);
    for (row = 0; row < height_rows; ++row) {
        uint16_t col;
        for (col = 0; col < width_bytes; ++col) {
            (void)vga_port_write(sequencer_data_port, (uint8_t)draw_color);
            vga_exchange((uint16_t)(offset + col), 0xff);
            (void)vga_port_write(sequencer_data_port, (uint8_t)(draw_color ^ 0xff));
            vga_exchange((uint16_t)(offset + col), 0x00);
        }
        offset = (uint16_t)(offset + screen_stride_bytes);
    }
    restore_common_graphics_state();
}

/* Captures four planes, preceded by row-count/byte-width header and marker. */
void PgCapturePlanarRectangle(farptr captured_image_far, int16_t left_byte_column,
                              int16_t top_pixel_row, int16_t right_byte_limit,
                              int16_t bottom_pixel_row)
{
    uint8_t *captured_image = pc_host_fp(captured_image_far);
    uint16_t width = (uint16_t)((uint16_t)right_byte_limit - (uint16_t)left_byte_column);
    uint16_t rows = (uint16_t)((uint16_t)bottom_pixel_row - (uint16_t)top_pixel_row + 1);
    uint16_t base = screen_offset((uint16_t)left_byte_column, (uint16_t)top_pixel_row);
    unsigned plane;

    add_draw_page(&base);
    transfer_rows_remaining = rows;
    transfer_row_bytes = width;
    captured_image[0] = (uint8_t)rows;
    captured_image[1] = (uint8_t)(rows >> 8);
    captured_image[2] = (uint8_t)width;
    captured_image[3] = (uint8_t)(width >> 8);
    captured_image[4] = 0xff;
    captured_image += 5;

    vga_index_data(graphics_index_port, gc_mode, 0);
    for (plane = 4; plane-- > 0;) {
        uint16_t y;
        vga_index_data(graphics_index_port, gc_read_map_select, (uint8_t)plane);
        for (y = 0; y < rows; ++y) {
            uint16_t col;
            uint16_t source = (uint16_t)(base + y * screen_stride_bytes);
            for (col = 0; col < width; ++col)
                *captured_image++ = vga_cpu_read((uint16_t)(source + col));
        }
    }
}

/* Restores a captured row-count/byte-width header and four planes. */
void PgRestorePlanarRectangle(farptr captured_image_far, int16_t byte_column,
                              int16_t pixel_row)
{
    uint8_t *captured_image = pc_host_fp(captured_image_far);
    uint16_t rows = (uint16_t)(captured_image[0] | ((uint16_t)captured_image[1] << 8));
    uint16_t width = (uint16_t)(captured_image[2] | ((uint16_t)captured_image[3] << 8));
    uint16_t base = screen_offset((uint16_t)byte_column, (uint16_t)pixel_row);
    unsigned plane;
    captured_image += 5; /* The original consumes, but does not examine, its marker. */
    transfer_rows_remaining = rows;
    transfer_row_bytes = width;
    add_draw_page(&base);

    (void)vga_port_write(sequencer_index_port, seq_map_mask);
    for (plane = 4; plane-- > 0;) {
        uint16_t y;
        (void)vga_port_write(sequencer_data_port, (uint8_t)(1u << plane));
        for (y = 0; y < rows; ++y) {
            uint16_t col;
            uint16_t dest = (uint16_t)(base + y * screen_stride_bytes);
            for (col = 0; col < width; ++col)
                vga_exchange((uint16_t)(dest + col), *captured_image++);
        }
    }
}

/* Draws a masked 16x16 sprite at a pixel position, splitting shifted bytes. */
void PgBlitMaskedShifted16x16(farptr sprite_source_far, int16_t pixel_x, int16_t pixel_y)
{
    uint8_t *sprite_source = pc_host_fp(sprite_source_far);
    unsigned row, group, plane;
    uint8_t shift = (uint8_t)pixel_x & 7;
    uint8_t left_shift = (uint8_t)(8 - shift);
    sprite_right_shift = shift;
    sprite_left_shift = left_shift;
    uint16_t row_start = screen_offset((uint16_t)((uint16_t)pixel_x >> 3), (uint16_t)pixel_y);

    (void)vga_port_write(sequencer_index_port, seq_map_mask);
    for (row = 0; row < 16; ++row) {
        uint16_t dest = row_start;
        sprite_bytes_remaining = 2;
        for (group = 0; group < 2; ++group) {
            uint8_t mask = *sprite_source++;
            uint8_t pixels[4];
            sprite_bytes_remaining = (uint8_t)(sprite_bytes_remaining - 1u);
            uint8_t low_mask = (uint8_t)(mask >> shift);
            uint8_t high_mask = (uint8_t)(mask << left_shift);
            for (plane = 0; plane < 4; ++plane) {
                pixels[plane] = *sprite_source++;
                sprite_plane_byte[plane] = pixels[plane];
            }
            planar_blit_byte(dest, low_mask,
                             (uint8_t[4]){(uint8_t)(pixels[0] >> shift),
                                         (uint8_t)(pixels[1] >> shift),
                                         (uint8_t)(pixels[2] >> shift),
                                         (uint8_t)(pixels[3] >> shift)}, 1);
            planar_blit_byte((uint16_t)(dest + 1), high_mask,
                             (uint8_t[4]){(uint8_t)(pixels[0] << left_shift),
                                         (uint8_t)(pixels[1] << left_shift),
                                         (uint8_t)(pixels[2] << left_shift),
                                         (uint8_t)(pixels[3] << left_shift)}, 1);
            ++dest;
        }
        row_start = (uint16_t)(row_start + screen_stride_bytes);
    }
    restore_common_graphics_state();
}

/* Loops over eight rows, splitting one mask and four plane bytes. */
void PgBlitMaskedShifted8x8(farptr glyph_source_far, uint16_t pixel_x, uint16_t pixel_y)
{
    uint8_t *glyph_source = pc_host_fp(glyph_source_far);
    unsigned row, plane;
    uint8_t left_shift = (uint8_t)(8 - (pixel_x & 7));
    uint8_t right_shift = (uint8_t)(pixel_x & 7);
    uint16_t row_start = screen_offset((uint16_t)(pixel_x >> 3), pixel_y);
    glyph_left_shift = left_shift;
    add_draw_page(&row_start);
    (void)vga_port_write(sequencer_index_port, seq_map_mask);
    for (row = 0; row < 8; ++row) {
        uint8_t mask = *glyph_source++;
        uint8_t mask_high = (uint8_t)(mask >> right_shift);
        uint8_t mask_low = (uint8_t)(mask << left_shift);
        glyph_mask_high = mask_high;
        glyph_mask_low = mask_low;
        uint16_t dest = row_start;
        for (plane = 0; plane < 4; ++plane) {
            (void)vga_port_write(sequencer_data_port, (uint8_t)(1u << plane));
            uint8_t pixels = *glyph_source++;
            uint8_t high = (uint8_t)(pixels >> right_shift);
            uint8_t low = (uint8_t)(pixels << left_shift);
            vga_index_data(graphics_index_port, gc_bit_mask, mask_high);
            vga_exchange(dest, high);
            vga_index_data(graphics_index_port, gc_bit_mask, mask_low);
            vga_exchange((uint16_t)(dest + 1), low);
        }
        row_start = (uint16_t)(row_start + screen_stride_bytes);
    }
    restore_common_graphics_state();
}

/* ORs 16 rows of two shifted byte groups into the current video page. */
void PgOrShifted16x16(farptr sprite_source_far, int16_t pixel_x, int16_t pixel_y)
{
    uint8_t *sprite_source = pc_host_fp(sprite_source_far);
    unsigned row, group, plane;
    uint8_t shift = (uint8_t)pixel_x & 7;
    uint8_t left_shift = (uint8_t)(8 - shift);
    sprite_right_shift = shift;
    sprite_left_shift = left_shift;
    uint16_t row_start = screen_offset((uint16_t)((uint16_t)pixel_x >> 3), (uint16_t)pixel_y);

    (void)vga_port_write(sequencer_index_port, seq_map_mask);
    for (row = 0; row < 16; ++row) {
        uint16_t dest = row_start;
        sprite_bytes_remaining = 2;
        for (group = 0; group < 2; ++group) {
            uint8_t mask = *sprite_source++;
            uint8_t pixels[4];
            unsigned half;
            sprite_bytes_remaining = (uint8_t)(sprite_bytes_remaining - 1u);
            sprite_source_mask = mask;
            for (plane = 0; plane < 4; ++plane) {
                pixels[plane] = *sprite_source++;
                sprite_plane_byte[plane] = pixels[plane];
            }
            for (half = 0; half < 2; ++half) {
                uint8_t bitmask = half ? (uint8_t)(mask << left_shift) : (uint8_t)(mask >> shift);
                uint16_t address = (uint16_t)(dest + half);
                vga_index_data(graphics_index_port, gc_bit_mask, bitmask);
                for (plane = 0; plane < 4; ++plane) {
                    uint8_t pixel = half ? (uint8_t)(pixels[plane] << left_shift)
                                         : (uint8_t)(pixels[plane] >> shift);
                    uint8_t prior;
                    (void)vga_port_write(sequencer_data_port, 0x0f);
                    (void)vga_cpu_read(address); /* MOV AH,[BX]. */
                    prior = vga_cpu_read(address); /* OR [BX],AL reads again. */
                    vga_cpu_write(address, (uint8_t)(prior | pixel));
                }
            }
            ++dest;
        }
        row_start = (uint16_t)(row_start + screen_stride_bytes);
    }
    restore_common_graphics_state();
}

/* Queries BIOS font pointers for the 8-row and 14-row ROM fonts. */
void PgInitializeRomFonts(void)
{
    pc_regs registers = {0};
    registers.ax = 0x1130;
    registers.bx = 0x0200;
    pc_bios_int(bios_video_interrupt, &registers);
    font14_offset = registers.bp;
    font14_segment = registers.es;
    font14_height = 14;

    registers.ax = 0x1130;
    registers.bx = 0x0300;
    pc_bios_int(bios_video_interrupt, &registers);
    font8_offset = registers.bp;
    font8_segment = registers.es;
    font8_height = 8;
}

/* Selects the 8-row font for index 1; other values select the 14-row font. */
void PgSelectRomFont(uint16_t font_index)
{
    if (font_index == 1) {
        selected_font_segment = font8_segment;
        selected_font_offset = font8_offset;
        selected_font_height = font8_height;
    } else {
        selected_font_segment = font14_segment;
        selected_font_offset = font14_offset;
        selected_font_height = font14_height;
    }
}

/* Draws 16 rows of four plane byte pairs, overwriting the destination. */
void PgBlitOpaque16x16(farptr image_source_far, int16_t byte_column, int16_t pixel_row)
{
    uint8_t *image_source = pc_host_fp(image_source_far);
    opaque_sprite(image_source, (uint16_t)byte_column, (uint16_t)pixel_row,
                  16, 2, (uint16_t)(screen_stride_bytes - 2), 1, 0, 0);
}

/* Draws eight rows of four plane bytes, overwriting the destination. */
void PgBlitOpaque8x8(farptr image_source_far, int16_t byte_column, int16_t pixel_row)
{
    uint8_t *image_source = pc_host_fp(image_source_far);
    opaque_sprite(image_source, (uint16_t)byte_column, (uint16_t)pixel_row,
                  8, 1, (uint16_t)(screen_stride_bytes - 1), 1, 1,
                  (uint16_t)pixel_row);
}

/* Uses EGA latches to copy a 16x16 tile from the VRAM cache at offset FA00h. */
void PgCopyCachedVideoTile16x16(int16_t byte_column, int16_t pixel_row,
                                int16_t cached_tile_index)
{
    uint16_t source = (uint16_t)(((uint16_t)cached_tile_index << 1) | cached_tiles_offset);
    uint16_t dest = screen_offset((uint16_t)byte_column, (uint16_t)pixel_row);
    unsigned row, col;
    (void)vga_port_write(sequencer_data_port, 0x0f);
    (void)vga_port_write(graphics_index_port, gc_mode);
    (void)vga_port_write(graphics_data_port, 1);
    for (row = 0; row < 16; ++row) {
        for (col = 0; col < 2; ++col) {
            uint8_t value = vga_cpu_read((uint16_t)(source + col));
            vga_cpu_write((uint16_t)(dest + col), value);
        }
        source = (uint16_t)(source + screen_stride_bytes);
        dest = (uint16_t)(dest + screen_stride_bytes);
    }
    (void)vga_port_write(graphics_data_port, 0);
}

/* Copies 200 rows of 40 bytes between video-memory regions through latches. */
void PgCopyVideoScreenRegion320x200(uint16_t source_byte_column, uint16_t source_pixel_row,
                                    uint16_t dest_byte_column, uint16_t dest_pixel_row)
{
    uint16_t source = screen_offset(source_byte_column, source_pixel_row);
    uint16_t dest = screen_offset(dest_byte_column, dest_pixel_row);
    unsigned row, col;
    (void)vga_port_write(sequencer_index_port, seq_map_mask);
    (void)vga_port_write(sequencer_data_port, 0x0f);
    (void)vga_port_write(graphics_index_port, gc_mode);
    (void)vga_port_write(graphics_data_port, 1);
    for (row = 0; row < 200; ++row) {
        for (col = 0; col < 40; ++col) {
            uint8_t value = vga_cpu_read((uint16_t)(source + col));
            vga_cpu_write((uint16_t)(dest + col), value);
        }
        source = (uint16_t)(source + screen_stride_bytes);
        dest = (uint16_t)(dest + screen_stride_bytes);
    }
    (void)vga_port_write(graphics_data_port, 0);
}

/* Copies eight 40-byte rows from VRAM offset 28h to offset zero. */
void PgCopyStatusBandTemplate(void)
{
    uint16_t source = 0x28;
    uint16_t dest = 0;
    unsigned row, col;
    (void)vga_port_write(sequencer_index_port, seq_map_mask);
    (void)vga_port_write(sequencer_data_port, 0x0f);
    (void)vga_port_write(graphics_index_port, gc_mode);
    (void)vga_port_write(graphics_data_port, 1);
    for (row = 0; row < 8; ++row) {
        for (col = 0; col < 40; ++col) {
            uint8_t value = vga_cpu_read((uint16_t)(source + col));
            vga_cpu_write((uint16_t)(dest + col), value);
        }
        source = (uint16_t)(source + 80);
        dest = (uint16_t)(dest + 80);
    }
    (void)vga_port_write(graphics_data_port, 0);
}
