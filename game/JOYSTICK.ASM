; Joystick axis timing for GAMEJOY, using the game port at 201h.
; Also retains the unused four-axis sampling entry and its helper.
CODE segment byte public
assume cs:CODE
public ReadJoystickAxis

; Four-axis sampling helpers.
; Unused assembly entry measures game-port masks 1,2,4,8 into four passed word destinations.
ReadFourJoystickAxes proc far
    push bp
    mov bp,sp
    push es
    mov dx,201h
    les di,[bp+12h]
    mov ah,1
    call MeasureJoystickAxisToWord
    les di,[bp+0eh]
    mov ah,2
    call MeasureJoystickAxisToWord
    les di,[bp+0ah]
    mov ah,4
    call MeasureJoystickAxisToWord
    les di,[bp+6]
    mov ah,8
    call MeasureJoystickAxisToWord
    jmp four_done            ; TASM reserves a forward-JMP slot (NOP).
ReadFourJoystickAxes endp

; Helper discharges/recharges one selected axis bit and stores the measured loop count through ES:DI.
MeasureJoystickAxisToWord proc near
    mov cx,0ffffh
four_discharge:
    in al,dx
    test ah,al
    loopne four_discharge
    mov cx,0ffffh
    cli
    out dx,al
four_charge:
    in al,dx
    test ah,al
    loopne four_charge
    sti
    neg cx
    add cx,-1
    mov es:[di],cx
    retf
MeasureJoystickAxisToWord endp
four_done:
    pop es
    mov sp,bp
    pop bp
    retf 16

; Game axis-read entry.
; Times game-port bit 1 shl Axis with interrupts disabled, returning -1 on timeout.
ReadJoystickAxis proc far
    push bp
    mov bp,sp
    mov dx,201h
    mov ax,[bp+6]
    mov cl,al
    mov ah,1
    shl ah,cl
    mov cx,0ffffh
axis_discharge:
    in al,dx
    test ah,al
    loopne axis_discharge
    mov cx,0ffffh
    cli
    out dx,al
axis_charge:
    in al,dx
    test ah,al
    loopne axis_charge
    sti
    neg cx
    add cx,-1
    mov ax,cx
    mov sp,bp
    pop bp
    ret 2
ReadJoystickAxis endp
CODE ends
end
