; Program clock helpers: reads CMOS time/date into DOS and programs the PIT
; for game timing or the default timer period. Seven CS scratch bytes are undefined.

; AT CMOS register selection and packed-BCD fields.
CmosIndexPort                   equ 70h
CmosDataPort                    equ 71h
CmosMinuteRegister              equ 2
CmosHourRegister                equ 4
CmosDayRegister                 equ 7
CmosMonthRegister               equ 8
CmosYearRegister                equ 9
CmosBcdNibbleMask               equ 0f0fh

; DOS clock services and the original fixed date/time assumptions.
ClockDosInterrupt               equ 21h
DosSetTimeFunction              equ 2dh
DosSetDateFunction              equ 2bh
CmosYearBase                    equ 1900
ClockHundredths                 equ 50

; PIT channel 0: low byte then high byte, mode 3 (square wave), binary count.
PitCounter0Port                 equ 40h
PitControlPort                  equ 43h
PitMode3LowHigh                 equ 36h
GameTimerDivisor                equ 2147h

CODE segment byte public
assume cs:CODE
; ReadCmosDecimal is private: CMOS index in AL, result in AX.
public SyncDosClockFromCmos, SetFastGameTimer, RestoreDefaultTimer

CmosHourWork   db ?
CmosMinuteWork db ?
CmosSecondWork db ?
CmosMonthWork  db ?
CmosDayWork    db ?
CmosYearWork   dw ?

; CMOS reads and DOS clock synchronization.
; Private register entry: AL = CMOS register; AX = decoded unsigned byte.
; FAR call/return, no stack arguments; AH and flags are scratch. CS state: none.
; Paired short jumps provide I/O delays; AAD combines the two BCD nibbles.
ReadCmosDecimal proc far
    out CmosIndexPort, al
    jmp short cmos_wait1
cmos_wait1:
    jmp short cmos_wait2
cmos_wait2:
    in al, CmosDataPort
    jmp short cmos_wait3
cmos_wait3:
    jmp short cmos_wait4
cmos_wait4:
    mov ah, al
    shr ah, 1
    shr ah, 1
    shr ah, 1
    shr ah, 1
    and ax, CmosBcdNibbleMask
    aad
    ret
ReadCmosDecimal endp

; Pascal: procedure SyncDosClockFromCmos; FAR return, no stack arguments.
; AX/CX/DX and flags are scratch. CS state: CmosHourWork through CmosYearWork.
; Original assumptions preserved: no update-in-progress check, no binary-mode
; check, no century register, and a fixed 50 hundredths when setting DOS time.
SyncDosClockFromCmos proc far
    sub ax, ax
    call ReadCmosDecimal
    mov cs:CmosSecondWork, al
    mov al, CmosMinuteRegister
    call ReadCmosDecimal
    mov cs:CmosMinuteWork, al
    mov al, CmosHourRegister
    call ReadCmosDecimal
    mov cs:CmosHourWork, al
    mov al, CmosDayRegister
    call ReadCmosDecimal
    mov cs:CmosDayWork, al
    mov al, CmosMonthRegister
    call ReadCmosDecimal
    mov cs:CmosMonthWork, al
    mov al, CmosYearRegister
    call ReadCmosDecimal
    mov cs:CmosYearWork, ax
    sub ax, ax
    mov ah, DosSetTimeFunction
    mov ch, cs:CmosHourWork
    mov cl, cs:CmosMinuteWork
    mov dh, cs:CmosSecondWork
    mov dl, ClockHundredths
    int ClockDosInterrupt
    sub ax, ax
    mov ah, DosSetDateFunction
    mov cx, CmosYearBase
    add cx, cs:CmosYearWork
    mov dh, cs:CmosMonthWork
    mov dl, cs:CmosDayWork
    int ClockDosInterrupt
    ret
SyncDosClockFromCmos endp

; PIT timer programming.
; Pascal: procedure SetFastGameTimer; FAR return, no stack arguments.
; AX/BX and flags are scratch; CS state: none. Divisor gives about 140 Hz.
; Original STI enables interrupts unconditionally instead of restoring IF.
SetFastGameTimer proc far
    mov bx, GameTimerDivisor
    cli
    mov al, PitMode3LowHigh
    out PitControlPort, al
    mov al, 0
    mov al, bl
    out PitCounter0Port, al
    mov al, bh
    out PitCounter0Port, al
    sti
    ret
SetFastGameTimer endp

; Pascal: procedure RestoreDefaultTimer; FAR return, no stack arguments.
; AL and flags are scratch; CS state: none. A zero count means 65536 ticks.
; Original STI enables interrupts unconditionally instead of restoring IF.
RestoreDefaultTimer proc far
    cli
    mov al, PitMode3LowHigh
    out PitControlPort, al
    mov al, 0
    out PitCounter0Port, al
    out PitCounter0Port, al
    sti
    ret
RestoreDefaultTimer endp
CODE ends
end
