#include "samlib_state.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static samlib_data_offsets active_offsets;
static uint8_t offsets_bound;

void samlib_reset(void)
{
    samlib_bind_data_offsets(NULL);
    samlib_genus_reset();
    samlib_progrphx_reset();
    samlib_cmospit_reset();
}

void samlib_bind_data_offsets(const samlib_data_offsets *offsets)
{
    if (offsets == NULL) {
        memset(&active_offsets, 0, sizeof(active_offsets));
        offsets_bound = 0;
        return;
    }
    active_offsets = *offsets;
    offsets_bound = 1;
}

uint16_t samlib_ds_segment(void)
{
    const pc_program *program = pc_current_program();
    return program != NULL ? program->ds_seg : 0;
}

const samlib_data_offsets *samlib_current_data_offsets(void)
{
    return offsets_bound ? &active_offsets : NULL;
}

const samlib_data_offsets *samlib_require_data_offsets(const char *routine_name)
{
    if (!offsets_bound) {
        fprintf(stderr, "samlib: DATA offsets not bound before %s\n", routine_name);
        abort();
    }
    return &active_offsets;
}
