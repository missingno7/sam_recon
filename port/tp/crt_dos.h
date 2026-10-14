#ifndef SAM_CRT_DOS_H
#define SAM_CRT_DOS_H
/* Turbo Pascal Crt/Dos ABI declarations backed by the emulated BIOS and DOS services. */
#include "../pc/pc.h"
typedef struct {
    uint16_t CheckBreak, CheckEOF, DirectVideo, CheckSnow;
    uint16_t LastMode, TextAttr, WindMin, WindMax;
} tp_crt_offsets;
void tp_BindCrt(uint16_t ds, const tp_crt_offsets *offsets);
void *tp_CrtAddress(uint8_t index);
enum {
    TP_CRT_CHECK_BREAK = 0,
    TP_CRT_CHECK_EOF = 1,
    TP_CRT_DIRECT_VIDEO = 2,
    TP_CRT_CHECK_SNOW = 3,
    TP_CRT_LAST_MODE = 4,
    TP_CRT_TEXT_ATTRIBUTE = 5,
    TP_CRT_WINDOW_MIN = 6,
    TP_CRT_WINDOW_MAX = 7
};
#define tp_CheckBreak (*(uint8_t *)tp_CrtAddress(TP_CRT_CHECK_BREAK))
#define tp_CheckEOF (*(uint8_t *)tp_CrtAddress(TP_CRT_CHECK_EOF))
#define tp_DirectVideo (*(uint8_t *)tp_CrtAddress(TP_CRT_DIRECT_VIDEO))
#define tp_CheckSnow (*(uint8_t *)tp_CrtAddress(TP_CRT_CHECK_SNOW))
#define tp_LastMode (*(uint16_t *)tp_CrtAddress(TP_CRT_LAST_MODE))
#define tp_TextAttr (*(uint8_t *)tp_CrtAddress(TP_CRT_TEXT_ATTRIBUTE))
#define tp_WindMin (*(uint16_t *)tp_CrtAddress(TP_CRT_WINDOW_MIN))
#define tp_WindMax (*(uint16_t *)tp_CrtAddress(TP_CRT_WINDOW_MAX))
extern uint8_t tp_CrtActive; /* System console writers route here after Crt init */
void tp_CrtInit(void);
void tp_Delay(uint16_t ms);
void tp_Sound(uint16_t frequency);
void tp_NoSound(void);
uint8_t tp_KeyPressed(void);
uint8_t tp_ReadKey(void);
void tp_GotoXY(uint8_t x, uint8_t y);
uint8_t tp_WhereX(void);
uint8_t tp_WhereY(void);
void tp_TextColor(uint8_t colour);
void tp_TextBackground(uint8_t colour);
void tp_ClrScr(void);
void tp_ClrEol(void);
void tp_Window(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2);
void tp_TextMode(int16_t mode);
void tp_CrtWrite(const uint8_t *bytes, size_t length);
void tp_CrtWriteLn(void);
void tp_Intr(uint8_t vector, void *registers); /* packed 20-byte TP Registers variant */
void tp_MsDos(void *registers);
void tp_GetIntVec(uint8_t vector, farptr *target);
void tp_SetIntVec(uint8_t vector, farptr target);
#endif
