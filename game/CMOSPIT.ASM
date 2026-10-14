; Program clock helpers: reads CMOS time/date into DOS and programs the PIT
; for game timing or the default timer period. Seven CS scratch bytes are undefined.
CODE segment byte public
assume cs:CODE
; ReadCmosDecimal is private: CMOS index in AL, result in AX.
public SyncDosClockFromCmos,SetFastGameTimer,RestoreDefaultTimer

CmosHourWork   db ?
CmosMinuteWork db ?
CmosSecondWork db ?
CmosMonthWork  db ?
CmosDayWork    db ?
CmosYearWork   dw ?

; CMOS reads and DOS clock synchronization.
; Selects the CMOS register through port $70, reads $71, masks BCD nibbles and uses AAD to convert them.
ReadCmosDecimal proc far
    out 70h,al
    jmp short cmos_wait1
cmos_wait1:
    jmp short cmos_wait2
cmos_wait2:
    in al,71h
    jmp short cmos_wait3
cmos_wait3:
    jmp short cmos_wait4
cmos_wait4:
    mov ah,al
    shr ah,1
    shr ah,1
    shr ah,1
    shr ah,1
    and ax,0f0fh
    aad
    ret
ReadCmosDecimal endp

; Reads CMOS time/date and invokes DOS INT 21h AH=$2D and $2B to set DOS time/date.
SyncDosClockFromCmos proc far
    sub ax,ax
    call ReadCmosDecimal
    mov cs:CmosSecondWork,al
    mov al,2
    call ReadCmosDecimal
    mov cs:CmosMinuteWork,al
    mov al,4
    call ReadCmosDecimal
    mov cs:CmosHourWork,al
    mov al,7
    call ReadCmosDecimal
    mov cs:CmosDayWork,al
    mov al,8
    call ReadCmosDecimal
    mov cs:CmosMonthWork,al
    mov al,9
    call ReadCmosDecimal
    mov cs:CmosYearWork,ax
    sub ax,ax
    mov ah,2dh
    mov ch,cs:CmosHourWork
    mov cl,cs:CmosMinuteWork
    mov dh,cs:CmosSecondWork
    mov dl,50
    int 21h
    sub ax,ax
    mov ah,2bh
    mov cx,1900
    add cx,cs:CmosYearWork
    mov dh,cs:CmosMonthWork
    mov dl,cs:CmosDayWork
    int 21h
    ret
SyncDosClockFromCmos endp

; PIT timer programming.
; Programs PIT channel 0 via ports $43/$40 with mode $36 and divisor $2147; called before the game loop.
SetFastGameTimer proc far
    mov bx,2147h
    cli
    mov al,36h
    out 43h,al
    mov al,0
    mov al,bl
    out 40h,al
    mov al,bh
    out 40h,al
    sti
    ret
SetFastGameTimer endp

; Programs PIT channel 0 with mode $36 and zero divisor, restoring the default 65536-count period.
RestoreDefaultTimer proc far
    cli
    mov al,36h
    out 43h,al
    mov al,0
    out 40h,al
    out 40h,al
    sti
    ret
RestoreDefaultTimer endp
CODE ends
end
