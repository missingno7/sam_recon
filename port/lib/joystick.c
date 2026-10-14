/* JOYSTICK.ASM: charge and time one game-port axis. */
#include "samlib.h"

enum { joystick_port = 0x201, joystick_poll_limit = 0xffff };

int16_t ReadJoystickAxis(uint16_t axis_index)
{
    uint8_t axis_shift = (uint8_t)axis_index;
    uint8_t axis_mask = axis_shift < 8 ? (uint8_t)(1u << axis_shift) : 0;
    uint8_t port_value = 0;
    uint16_t polls;

    /* Wait for any previous charge to finish; its count is discarded. */
    for (polls = joystick_poll_limit; polls != 0; --polls) {
        port_value = pc_inb(joystick_port);
        if ((port_value & axis_mask) == 0)
            break;
    }

    polls = joystick_poll_limit;
    pc_cli();
    pc_outb(joystick_port, port_value);
    while (polls != 0) {
        port_value = pc_inb(joystick_port);
        --polls;
        if ((port_value & axis_mask) == 0)
            break;
    }
    pc_sti();

    /* LOOPNE's CX decrement makes the first clear read return 1 and an
       uncleared bit after 65535 reads return -1. */
    return (int16_t)(uint16_t)(0u - polls - 1u);
}
