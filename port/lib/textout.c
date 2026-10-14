/* TEXTOUT.ASM: Pascal short-string output and BIOS video identification. */
#include "samlib.h"
#include "samlib_state.h"

enum {
    bios_video_interrupt = 0x10,
    bios_get_mode = 0x0f,
    bios_video_state_query = 0x1c00,
    bios_video_state_signature = 0x1c,
    bios_adapter_query = 0x1200,
    bios_adapter_signature = 0x12,
    mono_bios_mode = 7,
    cga_status_port = 0x3da,
    retrace_bit = 8,
    monochrome_segment = 0xb000,
    color_segment = 0xb800,
    adapter_mono = 0,
    adapter_cga = 1,
    adapter_ega = 2,
    adapter_vga = 3,
    adapter_state_bios = 4
};

static uint8_t query_and_save_text_video_mode(void)
{
    pc_regs registers = {0};
    const samlib_data_offsets *offsets = samlib_require_data_offsets("GetTextVideoMode");
    uint16_t ds = samlib_ds_segment();
    registers.ax = (uint16_t)(bios_get_mode << 8);
    pc_bios_int(bios_video_interrupt, &registers);
    pc_wr8(ds, offsets->TextSavedBiosMode, (uint8_t)registers.ax);
    return (uint8_t)registers.ax;
}

/* Register helper: returns ES:DI for an 80-column text page. */
static uint16_t text_cell_offset(uint8_t text_column, uint8_t text_row)
{
    uint16_t row = (uint8_t)(text_row - 1u);
    uint16_t column = (uint8_t)(text_column - 1u);
    return (uint16_t)((uint32_t)row * 160u + (uint32_t)column * 2u);
}

static void wait_for_cga_character_slot(void)
{
    uint8_t status;

    pc_cli();
    for (;;) {
        status = pc_inb(cga_status_port);
        if ((status & retrace_bit) != 0)
            break;
        if ((status & 1u) == 0)
            break;
        pc_poll();
    }
    if ((status & retrace_bit) == 0) {
        for (;;) {
            status = pc_inb(cga_status_port);
            if ((status & 1u) != 0)
                break;
            pc_poll();
        }
    }
}

/* Writes a Pascal String's character/attribute pairs, optionally synchronized to CGA. */
void WriteColoredText(uint8_t text_column, uint8_t text_row, uint8_t color_attribute,
                      farptr display_text)
{
    uint16_t offset = text_cell_offset(text_column, text_row);
    uint16_t segment = FP_SEG(display_text);
    uint16_t string_offset = FP_OFF(display_text);
    const samlib_data_offsets *offsets = samlib_require_data_offsets("WriteColoredText");
    uint16_t ds = samlib_ds_segment();
    uint16_t video_segment = pc_rd16(ds, offsets->TextVideoSegment);
    uint8_t retrace_sync_enabled = pc_rd8(ds, offsets->TextRetraceSyncEnabled);
    uint8_t length = pc_rd8(segment, string_offset);
    uint8_t index;

    for (index = 0; index < length; ++index) {
        uint8_t character = pc_rd8(segment, (uint16_t)(string_offset + 1u + index));
        if ((retrace_sync_enabled & 1u) != 0)
            wait_for_cga_character_slot();
        pc_wr16(video_segment, offset,
                (uint16_t)(((uint16_t)color_attribute << 8) | character));
        if ((retrace_sync_enabled & 1u) != 0)
            pc_sti();
        offset = (uint16_t)(offset + 2u);
    }
}

/* BIOS capability calls classify the adapter and save the result. */
uint8_t DetectTextVideoAdapter(void)
{
    pc_regs registers = {0};
    const samlib_data_offsets *offsets = samlib_require_data_offsets("DetectTextVideoAdapter");
    uint16_t ds = samlib_ds_segment();
    uint8_t saved_bios_mode;
    uint8_t video_adapter_class;
    (void)query_and_save_text_video_mode();
    saved_bios_mode = pc_rd8(ds, offsets->TextSavedBiosMode);

    video_adapter_class = adapter_state_bios;
    registers.cx = 0xffff;
    registers.ax = bios_video_state_query;
    pc_bios_int(bios_video_interrupt, &registers);
    if ((uint8_t)registers.ax == bios_video_state_signature)
        goto detected;

    video_adapter_class = adapter_vga;
    registers.ax = bios_adapter_query;
    registers.bx = 0x0032;
    pc_bios_int(bios_video_interrupt, &registers);
    if ((uint8_t)registers.ax == bios_adapter_signature)
        goto detected;

    video_adapter_class = adapter_ega;
    registers.ax = bios_adapter_query;
    registers.bx = 0xff10;
    registers.cx = 0xffff;
    pc_bios_int(bios_video_interrupt, &registers);
    if (registers.cx == 0xffff || (uint8_t)(registers.bx >> 8) > 1)
        goto unknown_adapter;
    if ((uint8_t)(registers.bx >> 8) == 1) {
        if (saved_bios_mode != mono_bios_mode)
            goto unknown_adapter;
    } else if (saved_bios_mode == mono_bios_mode) {
        goto unknown_adapter;
    }
    goto detected;

unknown_adapter:
    video_adapter_class = adapter_cga;
    if (saved_bios_mode == mono_bios_mode)
        video_adapter_class = adapter_mono;

detected:
    pc_wr8(ds, offsets->TextVideoAdapterClass, video_adapter_class);
    return video_adapter_class;
}

/* Calls the BIOS mode helper and returns its AL result. */
uint8_t GetTextVideoMode(void)
{
    return query_and_save_text_video_mode();
}
