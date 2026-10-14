; Game-port joystick object, SAM1 u6:007F-00FB (124 bytes).
; The unused four-axis reader calls a NEAR helper that returns RETF.
; This is the observed original convention, including its inconsistency.
CODE segment byte public
assume cs:CODE
public u6_00cc

u6_007f proc far
    push bp
    mov bp,sp
    push es
    mov dx,201h
    les di,[bp+12h]
    mov ah,1
    call u6_00a9
    les di,[bp+0eh]
    mov ah,2
    call u6_00a9
    les di,[bp+0ah]
    mov ah,4
    call u6_00a9
    les di,[bp+6]
    mov ah,8
    call u6_00a9
    jmp four_done            ; TASM reserves a forward-JMP slot (NOP).
u6_007f endp

u6_00a9 proc near
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
u6_00a9 endp
four_done:
    pop es
    mov sp,bp
    pop bp
    retf 16

u6_00cc proc far
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
u6_00cc endp
CODE ends
end
