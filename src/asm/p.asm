; Program CMOS/date/PIT object, SAM1 p:514A-5200 (182 bytes).
; Seven bytes of CS scratch are undefined in the object, not claimed equal.
CODE segment byte public
assume cs:CODE
public p_5151,p_516d,p_51df,p_51f3

cmos_hour   db ?
cmos_minute db ?
cmos_second db ?
cmos_month  db ?
cmos_day    db ?
cmos_year   dw ?

p_5151 proc far
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
p_5151 endp

p_516d proc far
    sub ax,ax
    call p_5151
    mov cs:cmos_second,al
    mov al,2
    call p_5151
    mov cs:cmos_minute,al
    mov al,4
    call p_5151
    mov cs:cmos_hour,al
    mov al,7
    call p_5151
    mov cs:cmos_day,al
    mov al,8
    call p_5151
    mov cs:cmos_month,al
    mov al,9
    call p_5151
    mov cs:cmos_year,ax
    sub ax,ax
    mov ah,2dh
    mov ch,cs:cmos_hour
    mov cl,cs:cmos_minute
    mov dh,cs:cmos_second
    mov dl,50
    int 21h
    sub ax,ax
    mov ah,2bh
    mov cx,1900
    add cx,cs:cmos_year
    mov dh,cs:cmos_month
    mov dl,cs:cmos_day
    int 21h
    ret
p_516d endp

p_51df proc far
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
p_51df endp

p_51f3 proc far
    cli
    mov al,36h
    out 43h,al
    mov al,0
    out 40h,al
    out 40h,al
    sti
    ret
p_51f3 endp
CODE ends
end
