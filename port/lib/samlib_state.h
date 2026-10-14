#ifndef SAMLIB_STATE_H
#define SAMLIB_STATE_H

#include "samlib.h"

uint16_t samlib_ds_segment(void);
const samlib_data_offsets *samlib_current_data_offsets(void);
const samlib_data_offsets *samlib_require_data_offsets(const char *routine_name);

#endif
