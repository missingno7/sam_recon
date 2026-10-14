; Joystick axis timing for GAMEJOY, using the game port at 201h.
; Also retains the unused four-axis sampling entry and its helper.

; Game-port capacitor timing: each loop is bounded by a 16-bit counter.
JoyAxisTimingPort               equ 201h
JoystickPollLimit               equ 0ffffh

CODE segment byte public
assume cs:CODE
public ReadJoystickAxis

; Four-axis sampling helpers.
; Unused Pascal-style entry: procedure ReadFourJoystickAxes(var X1,Y1,X2,Y2: Word).
; BP+18/14/10/6 = four far destinations; RETF 16. Saves BP/ES; AX/CX/DX/DI
; and flags are scratch. CS state: none. The helper's return mismatch below
; is an original bug preserved for exactness; this entry is not called.
ReadFourJoystickAxes proc far
    push bp
    mov bp, sp
    push es
    mov dx, JoyAxisTimingPort
    les di, [bp+12h]
    mov ah, 1
    call MeasureJoystickAxisToWord
    les di, [bp+0eh]
    mov ah, 2
    call MeasureJoystickAxisToWord
    les di, [bp+0ah]
    mov ah, 4
    call MeasureJoystickAxisToWord
    les di, [bp+6]
    mov ah, 8
    call MeasureJoystickAxisToWord
    jmp four_done            ; TASM reserves a forward-JMP slot (NOP).
ReadFourJoystickAxes endp

; Register helper: DX = game port, AH = axis mask, ES:DI = word destination.
; AX/CX and flags are scratch; CS state: none. Wait for an old sample to end,
; trigger a fresh charge, then count polls until the selected bit clears.
; Original bug preserved: near CALL sites are paired with a FAR return.
MeasureJoystickAxisToWord proc near
    mov cx, JoystickPollLimit
four_discharge:
    in al, dx
    test ah, al
    loopne four_discharge
    mov cx, JoystickPollLimit
    cli
    out dx, al
four_charge:
    in al, dx
    test ah, al
    loopne four_charge
    sti
    neg cx
    add cx, -1
    mov es:[di], cx
    retf
MeasureJoystickAxisToWord endp
four_done:
    pop es
    mov sp, bp
    pop bp
    retf 16

; Game axis-read entry.
; Pascal: function ReadJoystickAxis(AxisIndex: Word): Integer; BP+6 = AxisIndex; RETF 2.
; AX = poll count, or -1 on timeout. Saves BP; CX/DX and flags are scratch.
; CS state: none. Times game-port bit 1 shl Axis with interrupts disabled.
; Original STI enables interrupts unconditionally instead of restoring IF.
ReadJoystickAxis proc far
    push bp
    mov bp, sp
    mov dx, JoyAxisTimingPort
    mov ax, [bp+6]
    mov cl, al
    mov ah, 1
    shl ah, cl
    mov cx, JoystickPollLimit
axis_discharge:
    in al, dx
    test ah, al
    loopne axis_discharge
    mov cx, JoystickPollLimit
    cli
    out dx, al
axis_charge:
    in al, dx
    test ah, al
    loopne axis_charge
    sti
    neg cx
    add cx, -1
    mov ax, cx
    mov sp, bp
    pop bp
    ret 2
ReadJoystickAxis endp
CODE ends
end
