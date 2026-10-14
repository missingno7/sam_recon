/* CMOSPIT.ASM: DOS time synchronization and PIT programming. */
#include "samlib.h"

enum {
    cmos_index_port = 0x70,
    cmos_data_port = 0x71,
    dos_interrupt = 0x21,
    dos_set_time = 0x2d,
    dos_set_date = 0x2b,
    pit_counter0 = 0x40,
    pit_control = 0x43,
    pit_mode3_low_high = 0x36,
    game_timer_divisor = 0x2147,
    cmos_minute = 2,
    cmos_hour = 4,
    cmos_day = 7,
    cmos_month = 8,
    cmos_year = 9
};

/* The assembly keeps these scratch bytes in its CS segment. */
static uint8_t cmos_second_work;
static uint8_t cmos_minute_work;
static uint8_t cmos_hour_work;
static uint8_t cmos_day_work;
static uint8_t cmos_month_work;
static uint16_t cmos_year_work;

#ifdef SAM_LIBDIFF_TEST
void libdiff_cmospit_set_state(const uint16_t values[6])
{
    cmos_hour_work = (uint8_t)values[0];
    cmos_minute_work = (uint8_t)values[1];
    cmos_second_work = (uint8_t)values[2];
    cmos_month_work = (uint8_t)values[3];
    cmos_day_work = (uint8_t)values[4];
    cmos_year_work = values[5];
}

void libdiff_cmospit_get_state(uint16_t values[6])
{
    values[0] = cmos_hour_work;
    values[1] = cmos_minute_work;
    values[2] = cmos_second_work;
    values[3] = cmos_month_work;
    values[4] = cmos_day_work;
    values[5] = cmos_year_work;
}
#endif

static uint16_t read_cmos_decimal(uint8_t register_index)
{
    uint8_t packed_bcd;
    uint8_t high_nibble;

    pc_outb(cmos_index_port, register_index);
    packed_bcd = pc_inb(cmos_data_port);
    high_nibble = (uint8_t)((packed_bcd >> 4) & 0x0f);
    return (uint16_t)((uint16_t)high_nibble * 10u + (packed_bcd & 0x0f));
}

void SyncDosClockFromCmos(void)
{
    pc_regs registers = {0};

    cmos_second_work = (uint8_t)read_cmos_decimal(0);
    cmos_minute_work = (uint8_t)read_cmos_decimal(cmos_minute);
    cmos_hour_work = (uint8_t)read_cmos_decimal(cmos_hour);
    cmos_day_work = (uint8_t)read_cmos_decimal(cmos_day);
    cmos_month_work = (uint8_t)read_cmos_decimal(cmos_month);
    cmos_year_work = read_cmos_decimal(cmos_year);

    registers.ax = (uint16_t)((dos_set_time << 8) | 0);
    registers.cx = (uint16_t)(((uint16_t)cmos_hour_work << 8) | cmos_minute_work);
    registers.dx = (uint16_t)(((uint16_t)cmos_second_work << 8) | 50u);
    pc_bios_int(dos_interrupt, &registers);

    registers.ax = (uint16_t)(dos_set_date << 8);
    registers.cx = (uint16_t)(1900u + cmos_year_work);
    registers.dx = (uint16_t)(((uint16_t)cmos_month_work << 8) | cmos_day_work);
    pc_bios_int(dos_interrupt, &registers);
}

void SetFastGameTimer(void)
{
    pc_cli();
    pc_outb(pit_control, pit_mode3_low_high);
    pc_outb(pit_counter0, (uint8_t)(game_timer_divisor & 0xff));
    pc_outb(pit_counter0, (uint8_t)(game_timer_divisor >> 8));
    pc_sti();
}

void RestoreDefaultTimer(void)
{
    pc_cli();
    pc_outb(pit_control, pit_mode3_low_high);
    pc_outb(pit_counter0, 0);
    pc_outb(pit_counter0, 0);
    pc_sti();
}
