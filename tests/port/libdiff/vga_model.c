/* Test-double EGA implementation adapted from duke1_recon/port/vga.c. */
#include "pc.h"
#include "testdouble.h"

#include <string.h>

enum { plane_bytes = 65536 };

static uint8_t planes[4][plane_bytes];
static uint8_t sequencer_index;
static uint8_t sequencer[8];
static uint8_t graphics_index;
static uint8_t graphics[16];
static uint8_t crtc_index;
static uint8_t crtc[32];
static uint8_t attribute_index;
static uint8_t attribute[32];
static uint8_t attribute_data_phase;
static uint8_t retrace_state;
static uint8_t latches[4];

uint8_t *vga_plane(int plane)
{
    return plane >= 0 && plane < 4 ? planes[plane] : NULL;
}

void libdiff_vga_reset(void)
{
    memset(planes, 0, sizeof(planes));
    memset(sequencer, 0, sizeof(sequencer));
    memset(graphics, 0, sizeof(graphics));
    memset(crtc, 0, sizeof(crtc));
    memset(attribute, 0, sizeof(attribute));
    memset(latches, 0, sizeof(latches));
    sequencer_index = graphics_index = crtc_index = attribute_index = 0;
    sequencer[2] = 0x0f;
    graphics[7] = 0x0f;
    graphics[8] = 0xff;
    attribute_data_phase = retrace_state = 0;
}

void libdiff_vga_copy_state(uint8_t *dst, size_t capacity)
{
    size_t needed = sizeof(planes) + sizeof(sequencer) + sizeof(graphics) +
                    sizeof(crtc) + sizeof(attribute) + sizeof(latches) + 6;
    uint8_t *cursor = dst;
    if (dst == NULL || capacity < needed)
        return;
#define COPY_STATE(block) do { memcpy(cursor, (block), sizeof(block)); cursor += sizeof(block); } while (0)
    COPY_STATE(planes);
    COPY_STATE(sequencer);
    COPY_STATE(graphics);
    COPY_STATE(crtc);
    COPY_STATE(attribute);
    COPY_STATE(latches);
#undef COPY_STATE
    *cursor++ = sequencer_index;
    *cursor++ = graphics_index;
    *cursor++ = crtc_index;
    *cursor++ = attribute_index;
    *cursor++ = attribute_data_phase;
    *cursor = retrace_state;
}

void vga_cpu_write(uint16_t offset, uint8_t value)
{
    unsigned plane;
    unsigned mode = graphics[5] & 3u;
    uint8_t bit_mask = graphics[8];
    uint8_t function = (graphics[3] >> 3) & 3u;
    uint8_t rotated = value;
    unsigned rotate = graphics[3] & 7u;
    if (rotate != 0)
        rotated = (uint8_t)((value >> rotate) | (value << (8u - rotate)));

    /* Keep the test-double's 1 MB memory image coherent with Unicorn's A000
       aperture backing bytes; the planar contents are compared separately. */
    pc_mem[0xa0000u + offset] = value;

    for (plane = 0; plane < 4; ++plane) {
        uint8_t source;
        if ((sequencer[2] & (1u << plane)) == 0)
            continue;
        if (mode == 1) {
            planes[plane][offset] = latches[plane];
            continue;
        }
        if (mode == 2) {
            source = (value & (1u << plane)) ? 0xff : 0x00;
        } else if ((graphics[1] & (1u << plane)) != 0) {
            source = (graphics[0] & (1u << plane)) ? 0xff : 0x00;
        } else {
            source = rotated;
        }
        switch (function) {
        case 1: source = (uint8_t)(source & latches[plane]); break;
        case 2: source = (uint8_t)(source | latches[plane]); break;
        case 3: source = (uint8_t)(source ^ latches[plane]); break;
        default: break;
        }
        planes[plane][offset] = (uint8_t)((source & bit_mask) |
                                          (latches[plane] & (uint8_t)~bit_mask));
    }
}

uint8_t vga_cpu_read(uint16_t offset)
{
    unsigned plane;
    uint8_t result;
    for (plane = 0; plane < 4; ++plane)
        latches[plane] = planes[plane][offset];
    if ((graphics[5] & 0x08u) == 0) {
        result = latches[graphics[4] & 3u];
    } else {
        uint8_t care = graphics[7] & 0x0f;
        uint8_t compare = graphics[2] & 0x0f;
        unsigned bit;
        result = 0xff;
        for (bit = 0; bit < 8; ++bit) {
            unsigned p;
            int matches = 1;
            for (p = 0; p < 4; ++p) {
                if ((care & (1u << p)) != 0 &&
                    ((latches[p] >> bit) & 1u) != ((compare >> p) & 1u)) {
                    matches = 0;
                    break;
                }
            }
            if (!matches)
                result &= (uint8_t)~(1u << bit);
        }
    }
    pc_mem[0xa0000u + offset] = result;
    return result;
}

int vga_port_write(uint16_t port, uint8_t value)
{
    switch (port) {
    case 0x03c0:
        if (!attribute_data_phase) {
            attribute_index = value & 0x1f;
            attribute_data_phase = 1;
        } else {
            attribute[attribute_index] = value;
            attribute_data_phase = 0;
        }
        return 1;
    case 0x03c2: case 0x03c3: return 1;
    case 0x03c4: sequencer_index = value & 7; return 1;
    case 0x03c5: sequencer[sequencer_index] = value; return 1;
    case 0x03ce: graphics_index = value & 0x0f; return 1;
    case 0x03cf: graphics[graphics_index] = value; return 1;
    case 0x03d4: crtc_index = value & 0x1f; return 1;
    case 0x03d5: crtc[crtc_index] = value; return 1;
    default: return 0;
    }
}

int vga_port_read(uint16_t port, uint8_t *value)
{
    if (value == NULL)
        return 0;
    switch (port) {
    case 0x03c0: *value = attribute_index; return 1;
    case 0x03c1: *value = attribute[attribute_index]; return 1;
    case 0x03c2: *value = 0; return 1;
    case 0x03c3: *value = 1; return 1;
    case 0x03c4: *value = sequencer_index; return 1;
    case 0x03c5: *value = sequencer[sequencer_index]; return 1;
    case 0x03ce: *value = graphics_index; return 1;
    case 0x03cf: *value = graphics[graphics_index]; return 1;
    case 0x03d4: *value = crtc_index; return 1;
    case 0x03d5: *value = crtc[crtc_index]; return 1;
    case 0x03da:
        retrace_state ^= 8;
        attribute_data_phase = 0;
        *value = retrace_state;
        return 1;
    default: return 0;
    }
}
