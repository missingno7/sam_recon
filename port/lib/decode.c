/* DECODE.ASM: reverse each byte's bits, then XOR the cyclic publisher key. */
#include "samlib.h"

#include <stddef.h>

static const uint8_t decode_key[] = "Copyright 1991 Peder Jungck";

void DecryptGameAssetBuffer(farptr asset_buffer_far, uint16_t asset_byte_count)
{
    uint8_t *asset_buffer=pc_host_fp(asset_buffer_far);
    uint16_t byte_index;
    size_t key_index = 0;

    pc_cli();
    for (byte_index = 0; byte_index < asset_byte_count; ++byte_index) {
        uint8_t input = asset_buffer[byte_index];
        uint8_t reversed = 0;
        unsigned bit;

        for (bit = 0; bit < 8; ++bit) {
            if ((input & (uint8_t)(1u << bit)) != 0)
                reversed |= (uint8_t)(1u << (7u - bit));
        }
        asset_buffer[byte_index] = (uint8_t)(reversed ^ decode_key[key_index]);
        if (key_index == sizeof(decode_key) - 1)
            key_index = 0;
        else
            ++key_index;
    }
    pc_sti();
}
