; ProGraphx 2.0 toolbox object: SAM1 u9:00E6-303A.
; CS scratch is reserved with ?; it is not linker-buffer data.
; Explicit SHORT/NEAR preserves the original jump encodings.
; NOPs are the original reserved forward-JMP slots.
CODE segment byte public
assume cs:CODE
public u9_01a3,u9_01c5,u9_01d3,u9_01f9,u9_024c
public u9_029f,u9_02db,u9_02fa,u9_0337,u9_0352
public u9_0475,u9_051f,u9_0625,u9_07ee,u9_1795
public u9_1831,u9_19f9,u9_1b27,u9_2463,u9_27e2
public u9_2981,u9_2a9f,u9_2b38,u9_2e6d,u9_2ecf
public u9_2f32

text_x                 dw ?
text_y                 dw ?
font_pixel_x           dw ?
font_pixel_y           dw ?
text_cs_base           dw ?
font_rows              dw ?
glyph_offset           dw ?
glyph_segment          dw ?
font_row_index         dw ?
glyph_left             dw ?
glyph_right            dw ?
text_char_index        dw ?
text_char_code         dw ?
left_masks             db 0ffh,7fh,3fh,1fh,0fh,7,3,1
pixel_masks            db 80h,40h,20h,10h,8,4,2,1
transfer_width         dw ?
transfer_height        dw ?
transfer_x_end         dw ?
transfer_y_end         dw ?
transfer_x_start       dw ?
transfer_y_start       dw ?
screen_stride          dw 40
toolbox_marker         dw 0666h
banner_newlines        db 23 dup (10)
banner                 db 'ProGraphx EGA/VGA Toolbox',13,10,26
version                db 'Version 2.0 320x200 EGA/VGA',13,10,26
copyright              db 'Copyright 1991 by Peder Jungck',13,10,26
draw_page              dw 0
draw_color             dw 1
draw_operation         db 0
clip_left              dw 0
clip_right             dw 39
clip_top               dw 0
clip_bottom            dw 199
clip_left_pixels       dw 0
clip_right_pixels      dw 319
; set toolbox video mode
u9_01a3 proc far
    push bp
    mov bp,sp
    mov ax,word ptr [bp+6]
    cmp al,0
    jne mode_test_ega640
    mov al,0dh
    jmp short mode_set_bios
    nop
mode_test_ega640:
    cmp al,1
    je mode_ega640
    xor ah,ah
    mov al,12h
    jmp short mode_set_bios
    nop
mode_ega640:
    mov al,10h
mode_set_bios:
    int 10h
    pop bp
    retf 2
u9_01a3 endp

; set bios video mode
u9_01c5 proc far
    push bp
    mov bp,sp
    mov ax,word ptr [bp+6]
    xor ah,ah
    int 10h
    pop bp
    retf 2
u9_01c5 endp

; set screen stride
u9_01d3 proc far
    push bp
    mov bp,sp
    mov bx,word ptr [bp+6]
    cmp bx,28h
    jge stride_ge_e
    mov bx,28h
stride_ge_e:
    mov word ptr cs:[screen_stride],bx
    push ax
    mov dx,3d4h
    mov ax,13h
    out dx,ax
    inc dx
    mov ax,bx
    shr ax,1
    out dx,ax
    pop ax
    pop bp
    retf 2
u9_01d3 endp

; pan display retrace variant a
u9_01f9 proc far
    push bp
    mov bp,sp
    mov dx,3dah
pan_a_repeat_6:
    in al,dx
    test al,8
    je pan_a_repeat_6
pan_a_repeat_b:
    in al,dx
    test al,8
    jne pan_a_repeat_b
    cli
    mov ax,word ptr [bp+6]
    mul word ptr cs:[screen_stride]
    mov cx,word ptr [bp+8]
    shr cx,1
    shr cx,1
    shr cx,1
    add ax,cx
    mov bx,ax
    mov al,0ch
    mov dx,3d4h
    out dx,ax
    mov al,0dh
    mov ah,bl
    out dx,ax
    sti
    mov dx,3dah
pan_a_repeat_35:
    in al,dx
    test al,8
    je pan_a_repeat_35
    cli
    mov ax,word ptr [bp+8]
    and ax,7
    or al,10h
    mov ah,al
    mov dx,3c0h
    mov al,33h
    out dx,al
    xchg ah,al
    out dx,al
    sti
    pop bp
    retf 4
u9_01f9 endp

; pan display retrace variant b
u9_024c proc far
    push bp
    mov bp,sp
    mov dx,3dah
pan_b_repeat_6:
    in al,dx
    test al,8
    je pan_b_repeat_6
pan_b_repeat_b:
    in al,dx
    test al,8
    jne pan_b_repeat_b
    cli
    mov ax,word ptr [bp+6]
    mul word ptr cs:[screen_stride]
    mov cx,word ptr [bp+8]
    shr cx,1
    shr cx,1
    shr cx,1
    add ax,cx
    mov bx,ax
    mov al,0ch
    mov dx,3d4h
    out dx,ax
    mov al,0dh
    mov ah,bl
    out dx,ax
    sti
    mov dx,3dah
pan_b_repeat_35:
    in al,dx
    test al,8
    jne pan_b_repeat_35
    cli
    mov ax,word ptr [bp+8]
    and ax,7
    or al,10h
    mov ah,al
    mov dx,3c0h
    mov al,33h
    out dx,al
    xchg ah,al
    out dx,al
    sti
    pop bp
    retf 4
u9_024c endp

; set split scanline
u9_029f proc far
    push bp
    mov bp,sp
    mov ax,40h
    mov es,ax
    mov dx,word ptr es:[63h]
    add dl,6
split_repeat_10:
    in al,dx
    test al,8
    jne split_repeat_10
split_repeat_15:
    in al,dx
    test al,8
    je split_repeat_15
    sub dl,6
    mov ax,word ptr [bp+6]
    mov bh,ah
    and bh,1
    mov cl,4
    shl bh,cl
    mov ah,al
    mov al,18h
    out dx,ax
    mov ah,11h
    and ah,0efh
    or ah,bh
    mov al,7
    out dx,ax
    pop bp
    retf 2
u9_029f endp

; wait vertical retrace
u9_02db proc far
    push es
    xor ax,ax
    mov es,ax
    mov dx,3dah
    in al,dx
    jmp short retrace_continue_b
retrace_continue_b:
    test al,8
    je retrace_equal_16
retrace_repeat_f:
    in al,dx
    jmp short retrace_continue_12
retrace_continue_12:
    test al,8
    jne retrace_repeat_f
retrace_equal_16:
    in al,dx
    jmp short retrace_continue_19
retrace_continue_19:
    test al,8
    je retrace_equal_16
    pop es
    retf
u9_02db endp

; set split scanline registers
u9_02fa proc far
    push bp
    mov bp,sp
    push cs
    call near ptr u9_02db
    push es
    xor ax,ax
    mov es,ax
    mov dx,3d4h
    mov al,18h
    out dx,al
    inc dx
    mov ax,word ptr [bp+6]
    out dx,al
    dec dx
    mov al,7
    out dx,al
    inc dx
    in al,dx
    mov bl,byte ptr [bp+7]
    and bl,1
    mov cl,4
    shl bl,cl
    and al,0efh
    or al,bl
    out dx,al
    dec dx
    mov al,9
    out dx,al
    inc dx
    in al,dx
    and al,0bfh
    out dx,al
    jmp short splitregs_continue_38
    nop
splitregs_continue_38:
    pop es
    pop bp
    retf 2
u9_02fa endp

; set border color
u9_0337 proc far
    push bp
    mov bp,sp
    mov ah,10h
    mov al,1
    mov bx,word ptr [bp+6]
    mov bh,bl
    int 10h
    pop bp
    retf 2
u9_0337 endp

; reset current video mode
u9_0349 proc far
    mov ah,0fh
    int 10h
    xor ah,ah
    int 10h
    retf
u9_0349 endp

; set palette register
u9_0352 proc far
    push bp
    mov bp,sp
    mov ax,1000h
    mov bl,byte ptr [bp+8]
    mov bh,byte ptr [bp+6]
    int 10h
    pop bp
    retf 4
u9_0352 endp

; set text direction
u9_0364 proc far
    push bp
    mov bp,sp
    mov ax,word ptr [bp+6]
    mov word ptr cs:[text_direction],ax
    pop bp
    retf 2
u9_0364 endp

; blit masked 32x16
u9_0372 proc far
    push bp
    mov bp,sp
    push ds
    push di
    push si
    lds si,dword ptr [bp+0ah]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+6]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov bx,word ptr [bp+8]
    add bx,ax
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je masked32_equal_35
    mov cx,ax
masked32_row_loop_2f:
    add bx,2000h
    loop masked32_row_loop_2f
masked32_equal_35:
    mov dx,3c4h
    mov al,2
    out dx,al
    mov cx,10h
masked32_repeat_3e:
    mov dx,3ceh
    lodsb
    mov ah,8
    xchg ah,al
    out dx,ax
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    inc bx
    mov dx,3ceh
    lodsb
    mov ah,8
    xchg ah,al
    out dx,ax
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    jmp short masked32_continue_94
    nop
masked32_row_loop_92:
    jmp short masked32_repeat_3e
masked32_continue_94:
    mov dx,3ceh
    inc bx
    lodsb
    mov ah,8
    xchg ah,al
    out dx,ax
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    inc bx
    mov dx,3ceh
    lodsb
    mov ah,8
    xchg ah,al
    out dx,ax
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    inc bx
    add bx,word ptr cs:[screen_stride]
    dec bx
    dec bx
    dec bx
    dec bx
    loop masked32_row_loop_92
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
u9_0372 endp

; blit masked 16x16
u9_0475 proc far
    push bp
    mov bp,sp
    push ds
    push di
    push si
    mov di,word ptr cs:[screen_stride]
    dec di
    lds si,dword ptr [bp+0ah]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+6]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov bx,word ptr [bp+8]
    add bx,ax
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je masked16_equal_3b
    mov cx,ax
masked16_row_loop_35:
    add bx,2000h
    loop masked16_row_loop_35
masked16_equal_3b:
    mov dx,3c4h
    mov al,2
    out dx,al
    mov cx,10h
masked16_row_loop_44:
    mov dx,3ceh
    lodsb
    mov ah,8
    xchg ah,al
    out dx,ax
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    inc bx
    mov dx,3ceh
    lodsb
    mov ah,8
    xchg ah,al
    out dx,ax
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    add bx,di
    loop masked16_row_loop_44
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
u9_0475 endp

; blit masked 8x8
u9_051f proc far
    push bp
    mov bp,sp
    push ds
    push di
    push si
    lds si,dword ptr [bp+0ah]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+8]
    mov dx,word ptr cs:[draw_page]
    cmp dl,0
    je masked8_equal_23
    mov cx,ax
masked8_row_loop_1d:
    add bx,2000h
    loop masked8_row_loop_1d
masked8_equal_23:
    mov dx,word ptr [bp+6]
    push di
    push ax
    mov ax,dx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    add bx,ax
    mov dx,3c4h
    mov al,2
    out dx,al
    mov cx,8
masked8_row_loop_40:
    mov dx,3ceh
    lodsb
    mov ah,8
    xchg ah,al
    out dx,ax
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    add bx,word ptr cs:[screen_stride]
    loop masked8_row_loop_40
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
u9_051f endp

plane_rect_height      dw 0
; blit single plane rectangle
u9_05a1 proc far
    push bp
    mov bp,sp
    push ds
    push di
    push si
    lds si,dword ptr [bp+0eh]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+0ch]
    mov dx,word ptr cs:[draw_page]
    cmp dl,0
    je plane_rect_equal_23
    mov cx,ax
plane_rect_loop_1d:
    add bx,2000h
    loop plane_rect_loop_1d
plane_rect_equal_23:
    mov ax,word ptr [bp+0ah]
    push di
    push ax
    mov ax,ax
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov dx,di
    pop di
    mov ax,dx
    add bx,ax
    mov dx,3c4h
    mov al,2
    out dx,al
    inc dx
    mov ax,word ptr [bp+6]
    mov word ptr cs:[plane_rect_height],ax
plane_rect_repeat_47:
    mov cx,word ptr [bp+8]
plane_rect_loop_4a:
    mov dx,3c5h
    mov ax,word ptr cs:[draw_color]
    mov dx,3c5h
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    inc bx
    loop plane_rect_loop_4a
    add bx,word ptr cs:[screen_stride]
    sub bx,word ptr [bp+8]
    dec word ptr cs:[plane_rect_height]
    cmp word ptr cs:[plane_rect_height],0
    je plane_rect_equal_73
    jmp short plane_rect_repeat_47
plane_rect_equal_73:
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop si
    pop di
    pop ds
    pop bp
    retf 0ch
u9_05a1 endp

; set color or plane mask
u9_0625 proc far
    push bp
    mov bp,sp
    mov ax,word ptr [bp+6]
    mov word ptr cs:[draw_color],ax
    pop bp
    retf 2
u9_0625 endp

; select draw page
u9_0633 proc far
    push bp
    mov bp,sp
    mov ax,word ptr [bp+6]
    mov word ptr cs:[draw_page],ax
    pop bp
    retf 2
u9_0633 endp

; put pixel
u9_0641 proc far
    push bp
    mov bp,sp
    push ds
    mov dx,0a000h
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je putpixel_equal_17
    mov cx,ax
putpixel_loop_11:
    add dx,2000h
    loop putpixel_loop_11
putpixel_equal_17:
    mov ds,dx
    mov bx,word ptr [bp+6]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov bx,word ptr [bp+8]
    shr bx,1
    shr bx,1
    shr bx,1
    add bx,ax
    mov cx,word ptr [bp+8]
    and cl,7
    xor cl,7
    mov ch,1
    shl ch,cl
    mov dx,3ceh
    mov al,5
    out dx,al
    mov dx,3cfh
    mov al,2
    out dx,al
    mov dx,3ceh
    mov al,8
    out dx,al
    mov dx,3cfh
    mov al,ch
    out dx,al
    mov al,byte ptr [bx]
    mov ax,word ptr cs:[draw_color]
    mov byte ptr [bx],al
    mov dx,3ceh
    mov al,5
    out dx,al
    mov dx,3cfh
    mov al,0
    out dx,al
    mov dx,3ceh
    mov al,8
    out dx,al
    mov dx,3cfh
    mov al,0ffh
    out dx,al
    pop ds
    pop bp
    retf 4
u9_0641 endp

; put pixel clipped
u9_06c1 proc far
    push bp
    mov bp,sp
    push ds
    mov dx,0a000h
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je clip_pixel_equal_17
    mov cx,ax
clip_pixel_loop_11:
    add dx,2000h
    loop clip_pixel_loop_11
clip_pixel_equal_17:
    mov ds,dx
    mov bx,word ptr [bp+6]
    cmp bx,word ptr cs:[clip_top]
    jl clip_pixel_less_97
    cmp bx,word ptr cs:[clip_bottom]
    jg clip_pixel_less_97
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov bx,word ptr [bp+8]
    cmp bx,word ptr cs:[clip_left_pixels]
    jl clip_pixel_less_97
    cmp bx,word ptr cs:[clip_right_pixels]
    jg clip_pixel_less_97
    shr bx,1
    shr bx,1
    shr bx,1
    add bx,ax
    mov cx,word ptr [bp+8]
    and cl,7
    xor cl,7
    mov ch,1
    shl ch,cl
    mov dx,3ceh
    mov al,5
    out dx,al
    mov dx,3cfh
    mov al,2
    out dx,al
    mov dx,3ceh
    mov al,8
    out dx,al
    mov dx,3cfh
    mov al,ch
    out dx,al
    mov al,byte ptr [bx]
    mov ax,word ptr cs:[draw_color]
    mov byte ptr [bx],al
    mov dx,3ceh
    mov al,5
    out dx,al
    mov dx,3cfh
    mov al,0
    out dx,al
    mov dx,3ceh
    mov al,8
    out dx,al
    mov dx,3cfh
    mov al,0ffh
    out dx,al
clip_pixel_less_97:
    pop ds
    pop bp
    retf 4
u9_06c1 endp

; get pixel
u9_075d proc far
    push bp
    mov bp,sp
    push ds
    mov bx,word ptr [bp+8]
    mov cx,word ptr [bp+6]
    mov dx,0a000h
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je getpixel_equal_1d
    mov cx,ax
getpixel_loop_17:
    add dx,2000h
    loop getpixel_loop_17
getpixel_equal_1d:
    mov ds,dx
    push di
    push ax
    mov ax,cx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov cx,bx
    shr bx,1
    shr bx,1
    shr bx,1
    add bx,ax
    and cl,7
    xor cl,7
    mov ch,1
    shl ch,cl
    mov ah,3
getpixel_repeat_44:
    mov dx,3ceh
    mov al,4
    out dx,al
    mov dx,3cfh
    mov al,ah
    out dx,al
    mov al,byte ptr [bx]
    shl cl,1
    and al,ch
    je getpixel_equal_5b
    or cl,1
getpixel_equal_5b:
    dec ah
    jge getpixel_repeat_44
    and cx,0fh
    mov ax,cx
    pop ds
    pop bp
    retf 4
u9_075d endp

; show video page bios
u9_07c6 proc far
    push bp
    mov bp,sp
    mov ax,word ptr [bp+6]
    mov ah,5
    int 10h
    pop bp
    retf 2
u9_07c6 endp

; set mouse cursor shape
u9_07d4 proc far
    push bp
    mov bp,sp
    push ds
    mov ax,9
    mov bx,word ptr [bp+8]
    mov bx,word ptr [bp+6]
    les dx,dword ptr [bp+0ah]
    inc dx
    int 33h
    pop ds
    pop bp
    retf 8
u9_07d4 endp

byte_rect_height       dw 0
; fill rectangle byte aligned
u9_07ee proc far
    push bp
    mov bp,sp
    push ds
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+0ch]
    mov dx,word ptr cs:[draw_page]
    cmp dl,0
    je rect_bytes_equal_1e
    mov cx,ax
rect_bytes_loop_18:
    add bx,2000h
    loop rect_bytes_loop_18
rect_bytes_equal_1e:
    mov ax,word ptr [bp+8]
    push di
    push ax
    mov ax,ax
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov dx,di
    pop di
    mov ax,dx
    add bx,ax
    mov dx,3c4h
    mov al,2
    out dx,al
    inc dx
    mov ax,word ptr [bp+6]
    mov word ptr cs:[byte_rect_height],ax
rect_bytes_repeat_42:
    mov cx,word ptr [bp+0ah]
rect_bytes_loop_45:
    mov dx,3c5h
    mov ax,word ptr cs:[draw_color]
    mov dx,3c5h
    out dx,al
    mov ax,0ffh
    xchg byte ptr es:[bx],al
    mov ax,word ptr cs:[draw_color]
    xor ax,0ffh
    mov dx,3c5h
    out dx,al
    mov ax,0
    xchg byte ptr es:[bx],al
    inc bx
    loop rect_bytes_loop_45
    add bx,word ptr cs:[screen_stride]
    sub bx,word ptr [bp+0ah]
    dec word ptr cs:[byte_rect_height]
    cmp word ptr cs:[byte_rect_height],0
    je rect_bytes_equal_81
    jmp short rect_bytes_repeat_42
rect_bytes_equal_81:
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop ds
    pop bp
    retf 8
u9_07ee endp

; fill rectangle clipped
u9_087e proc far
    push bp
    mov bp,sp
    push ds
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+0ch]
    cmp bx,word ptr cs:[clip_right]
    jle clip_rect_bytes_le_16
clip_rect_bytes_repeat_13:
    jmp near ptr clip_rect_bytes_continue_fa
clip_rect_bytes_le_16:
    cmp bx,word ptr cs:[clip_left]
    jge clip_rect_bytes_ge_2f
    mov dx,word ptr [bp+0ah]
clip_rect_bytes_repeat_20:
    inc bx
    dec dx
    cmp bx,word ptr cs:[clip_left]
    jl clip_rect_bytes_repeat_20
    mov word ptr [bp+0ah],dx
    mov word ptr [bp+0ch],bx
clip_rect_bytes_ge_2f:
    mov cx,word ptr [bp+0ch]
    add cx,word ptr [bp+0ah]
    cmp cx,word ptr cs:[clip_right]
    jle clip_rect_bytes_le_4a
    sub cx,word ptr cs:[clip_bottom]
    mov dx,word ptr [bp+0ah]
clip_rect_bytes_loop_44:
    dec dx
    loop clip_rect_bytes_loop_44
    mov word ptr [bp+0ah],dx
clip_rect_bytes_le_4a:
    mov dx,word ptr cs:[draw_page]
    cmp dl,0
    je clip_rect_bytes_equal_5c
    mov cx,ax
clip_rect_bytes_loop_56:
    add bx,2000h
    loop clip_rect_bytes_loop_56
clip_rect_bytes_equal_5c:
    mov ax,word ptr [bp+8]
    cmp ax,word ptr cs:[clip_bottom]
    jg clip_rect_bytes_repeat_13
    cmp ax,word ptr cs:[clip_top]
    jge clip_rect_bytes_ge_7f
    mov dx,word ptr [bp+6]
clip_rect_bytes_repeat_70:
    inc ax
    dec dx
    cmp ax,word ptr cs:[clip_top]
    jl clip_rect_bytes_repeat_70
    mov word ptr [bp+6],dx
    mov word ptr [bp+8],ax
clip_rect_bytes_ge_7f:
    mov cx,word ptr [bp+8]
    add cx,word ptr [bp+6]
    cmp cx,word ptr cs:[clip_bottom]
    jle clip_rect_bytes_le_9a
    sub cx,word ptr cs:[clip_bottom]
    mov dx,word ptr [bp+6]
clip_rect_bytes_loop_94:
    dec dx
    loop clip_rect_bytes_loop_94
    mov word ptr [bp+6],dx
clip_rect_bytes_le_9a:
    push di
    push ax
    mov ax,ax
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov dx,di
    pop di
    mov ax,dx
    add bx,ax
    mov dx,3c4h
    mov al,2
    out dx,al
    inc dx
    mov ax,word ptr [bp+6]
    mov word ptr cs:[byte_rect_height],ax
clip_rect_bytes_repeat_bb:
    mov cx,word ptr [bp+0ah]
clip_rect_bytes_loop_be:
    mov dx,3c5h
    mov ax,word ptr cs:[draw_color]
    mov dx,3c5h
    out dx,al
    mov ax,0ffh
    xchg byte ptr es:[bx],al
    mov ax,word ptr cs:[draw_color]
    xor ax,0ffh
    mov dx,3c5h
    out dx,al
    mov ax,0
    xchg byte ptr es:[bx],al
    inc bx
    loop clip_rect_bytes_loop_be
    add bx,word ptr cs:[screen_stride]
    sub bx,word ptr [bp+0ah]
    dec word ptr cs:[byte_rect_height]
    cmp word ptr cs:[byte_rect_height],0
    je clip_rect_bytes_continue_fa
    jmp short clip_rect_bytes_repeat_bb
clip_rect_bytes_continue_fa:
    mov dx,3c5h
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop ds
    pop bp
    retf 8
u9_087e endp

; pixel address and bit helper
u9_098a proc far
    mov cl,bl
    push dx
    push di
    push ax
    mov ax,ax
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov dx,di
    pop di
    mov ax,dx
    pop dx
    shr bx,1
    shr bx,1
    shr bx,1
    add bx,ax
    push cx
    mov cx,word ptr cs:[draw_page]
    mov ax,0a000h
    cmp cx,0
    je pixel_address_equal_30
pixel_address_loop_2b:
    add ax,2000h
    loop pixel_address_loop_2b
pixel_address_equal_30:
    mov es,ax
    pop cx
    and cl,7
    xor cl,7
    mov ah,1
    retf
u9_098a endp

line_x_step            dw ?
line_y_step            dw ?
line_error             dw ?
line_major_delta       dw ?
; draw line bresenham
u9_09ce proc far
    push bp
    mov bp,sp
    push si
    push di
    mov dx,3ceh
    mov ah,byte ptr cs:[draw_color]
    xor al,al
    out dx,ax
    mov ax,0f01h
    out dx,ax
    mov ah,0
    mov al,3
    out dx,ax
    mov si,word ptr cs:[screen_stride]
    mov cx,word ptr [bp+8]
    sub cx,word ptr [bp+0ch]
    je line_a_equal_98
    jns line_a_nonnegative_3c
    neg cx
    mov bx,word ptr [bp+8]
    xchg word ptr [bp+0ch],bx
    mov word ptr [bp+8],bx
    mov bx,word ptr [bp+6]
    xchg word ptr [bp+0ah],bx
    mov word ptr [bp+6],bx
line_a_nonnegative_3c:
    mov bx,word ptr [bp+6]
    sub bx,word ptr [bp+0ah]
    je line_a_equal_c1
    jns line_a_nonnegative_4a
    neg bx
    neg si
line_a_nonnegative_4a:
    mov word ptr cs:[line_x_step],si
    mov word ptr cs:[line_major_delta],0
    cmp bx,cx
    jle line_a_le_63
    mov word ptr cs:[line_major_delta],1
    xchg bx,cx
line_a_le_63:
    shl bx,1
    mov word ptr cs:[line_y_step],bx
    sub bx,cx
    mov si,bx
    sub bx,cx
    mov word ptr cs:[line_error],bx
    push cx
    mov ax,word ptr [bp+0ah]
    mov bx,word ptr [bp+0ch]
    push cs
    call near ptr u9_098a
    mov di,bx
    shl ah,cl
    mov bl,ah
    mov al,8
    pop cx
    inc cx
    cmp word ptr cs:[line_major_delta],0
    jg line_a_greater_95
    jmp near ptr line_a_loop_11b
line_a_greater_95:
    jmp near ptr line_a_continue_166
line_a_equal_98:
    mov ax,word ptr [bp+0ah]
    mov bx,word ptr [bp+6]
    mov cx,bx
    sub cx,ax
    jge line_a_ge_a8
    neg cx
    mov ax,bx
line_a_ge_a8:
    inc cx
    mov bx,word ptr [bp+0ch]
    push cx
    push cs
    call near ptr u9_098a
    shl ah,cl
    mov al,8
    out dx,ax
    pop cx
line_a_loop_b7:
    or byte ptr es:[bx],al
    add bx,si
    loop line_a_loop_b7
    jmp near ptr line_a_continue_18a
line_a_equal_c1:
    push ds
    mov ax,word ptr [bp+0ah]
    mov bx,word ptr [bp+0ch]
    push cs
    call near ptr u9_098a
    mov di,bx
    mov dh,ah
    not dh
    shl dh,cl
    not dh
    mov cx,word ptr [bp+8]
    and cl,7
    xor cl,7
    mov dl,0ffh
    shl dl,cl
    mov ax,word ptr [bp+8]
    mov bx,word ptr [bp+0ch]
    mov cl,3
    shr ax,cl
    shr bx,cl
    mov cx,ax
    sub cx,bx
    mov bx,dx
    mov dx,3ceh
    mov al,8
    push es
    pop ds
    mov si,di
    or bh,bh
    js line_a_negative_10f
    or cx,cx
    jne line_a_different_10a
    and bl,bh
    jmp short line_a_continue_114
line_a_different_10a:
    mov ah,bh
    out dx,ax
    movsb
    dec cx
line_a_negative_10f:
    mov ah,0ffh
    out dx,ax
    rep movsb
line_a_continue_114:
    mov ah,bl
    out dx,ax
    movsb
    pop ds
    jmp short line_a_continue_18a
line_a_loop_11b:
    mov ah,bl
line_a_loop_11d:
    or ah,bl
    ror bl,1
    jb line_a_branch_146
    or si,si
    jns line_a_nonnegative_134
    add si,word ptr cs:[line_y_step]
    loop line_a_loop_11d
    out dx,ax
    or byte ptr es:[di],al
    jmp short line_a_continue_18a
line_a_nonnegative_134:
    add si,word ptr cs:[line_error]
    out dx,ax
    or byte ptr es:[di],al
    add di,word ptr cs:[line_x_step]
    loop line_a_loop_11b
    jmp short line_a_continue_18a
line_a_branch_146:
    out dx,ax
    or byte ptr es:[di],al
    inc di
    or si,si
    jns line_a_nonnegative_158
    add si,word ptr cs:[line_y_step]
    loop line_a_loop_11b
    jmp short line_a_continue_18a
line_a_nonnegative_158:
    add si,word ptr cs:[line_error]
    add di,word ptr cs:[line_x_step]
    loop line_a_loop_11b
    jmp short line_a_continue_18a
line_a_continue_166:
    mov bx,word ptr cs:[line_x_step]
line_a_loop_16b:
    out dx,ax
    or byte ptr es:[di],al
    add di,bx
    or si,si
    jns line_a_nonnegative_17e
    add si,word ptr cs:[line_y_step]
    loop line_a_loop_16b
    jmp short line_a_continue_18a
line_a_nonnegative_17e:
    add si,word ptr cs:[line_error]
    ror ah,1
    adc di,0
    loop line_a_loop_16b
line_a_continue_18a:
    xor ax,ax
    out dx,ax
    inc ax
    out dx,ax
    mov al,3
    out dx,ax
    mov ax,0ff08h
    out dx,ax
    pop di
    pop si
    pop bp
    retf 8
u9_09ce endp

; draw line bresenham variant
u9_0b6a proc far
    push bp
    mov bp,sp
    push si
    push di
    mov dx,3ceh
    mov ax,5
    out dx,ax
    mov ah,byte ptr cs:[draw_color]
    xor al,al
    out dx,ax
    mov ax,0f01h
    out dx,ax
    mov ah,18h
    mov al,3
    out dx,ax
    mov si,word ptr cs:[screen_stride]
    mov cx,word ptr [bp+8]
    sub cx,word ptr [bp+0ch]
    je line_b_equal_9c
    jns line_b_nonnegative_40
    neg cx
    mov bx,word ptr [bp+8]
    xchg word ptr [bp+0ch],bx
    mov word ptr [bp+8],bx
    mov bx,word ptr [bp+6]
    xchg word ptr [bp+0ah],bx
    mov word ptr [bp+6],bx
line_b_nonnegative_40:
    mov bx,word ptr [bp+6]
    sub bx,word ptr [bp+0ah]
    je line_b_equal_c5
    jns line_b_nonnegative_4e
    neg bx
    neg si
line_b_nonnegative_4e:
    mov word ptr cs:[line_x_step],si
    mov word ptr cs:[line_major_delta],0
    cmp bx,cx
    jle line_b_le_67
    mov word ptr cs:[line_major_delta],1
    xchg bx,cx
line_b_le_67:
    shl bx,1
    mov word ptr cs:[line_y_step],bx
    sub bx,cx
    mov si,bx
    sub bx,cx
    mov word ptr cs:[line_error],bx
    push cx
    mov ax,word ptr [bp+0ah]
    mov bx,word ptr [bp+0ch]
    push cs
    call near ptr u9_098a
    mov di,bx
    shl ah,cl
    mov bl,ah
    mov al,8
    pop cx
    inc cx
    cmp word ptr cs:[line_major_delta],0
    jg line_b_greater_99
    jmp near ptr line_b_loop_11f
line_b_greater_99:
    jmp near ptr line_b_continue_16a
line_b_equal_9c:
    mov ax,word ptr [bp+0ah]
    mov bx,word ptr [bp+6]
    mov cx,bx
    sub cx,ax
    jge line_b_ge_ac
    neg cx
    mov ax,bx
line_b_ge_ac:
    inc cx
    mov bx,word ptr [bp+0ch]
    push cx
    push cs
    call near ptr u9_098a
    shl ah,cl
    mov al,8
    out dx,ax
    pop cx
line_b_loop_bb:
    xor byte ptr es:[bx],al
    add bx,si
    loop line_b_loop_bb
    jmp near ptr line_b_continue_18e
line_b_equal_c5:
    push ds
    mov ax,word ptr [bp+0ah]
    mov bx,word ptr [bp+0ch]
    push cs
    call near ptr u9_098a
    mov di,bx
    mov dh,ah
    not dh
    shl dh,cl
    not dh
    mov cx,word ptr [bp+8]
    and cl,7
    xor cl,7
    mov dl,0ffh
    shl dl,cl
    mov ax,word ptr [bp+8]
    mov bx,word ptr [bp+0ch]
    mov cl,3
    shr ax,cl
    shr bx,cl
    mov cx,ax
    sub cx,bx
    mov bx,dx
    mov dx,3ceh
    mov al,8
    push es
    pop ds
    mov si,di
    or bh,bh
    js line_b_negative_113
    or cx,cx
    jne line_b_different_10e
    and bl,bh
    jmp short line_b_continue_118
line_b_different_10e:
    mov ah,bh
    out dx,ax
    movsb
    dec cx
line_b_negative_113:
    mov ah,0ffh
    out dx,ax
    rep movsb
line_b_continue_118:
    mov ah,bl
    out dx,ax
    movsb
    pop ds
    jmp short line_b_continue_18e
line_b_loop_11f:
    mov ah,bl
line_b_loop_121:
    or ah,bl
    ror bl,1
    jb line_b_branch_14a
    or si,si
    jns line_b_nonnegative_138
    add si,word ptr cs:[line_y_step]
    loop line_b_loop_121
    out dx,ax
    xor byte ptr es:[di],al
    jmp short line_b_continue_18e
line_b_nonnegative_138:
    add si,word ptr cs:[line_error]
    out dx,ax
    xor byte ptr es:[di],al
    add di,word ptr cs:[line_x_step]
    loop line_b_loop_11f
    jmp short line_b_continue_18e
line_b_branch_14a:
    out dx,ax
    xor byte ptr es:[di],al
    inc di
    or si,si
    jns line_b_nonnegative_15c
    add si,word ptr cs:[line_y_step]
    loop line_b_loop_11f
    jmp short line_b_continue_18e
line_b_nonnegative_15c:
    add si,word ptr cs:[line_error]
    add di,word ptr cs:[line_x_step]
    loop line_b_loop_11f
    jmp short line_b_continue_18e
line_b_continue_16a:
    mov bx,word ptr cs:[line_x_step]
line_b_loop_16f:
    out dx,ax
    xor byte ptr es:[di],al
    add di,bx
    or si,si
    jns line_b_nonnegative_182
    add si,word ptr cs:[line_y_step]
    loop line_b_loop_16f
    jmp short line_b_continue_18e
line_b_nonnegative_182:
    add si,word ptr cs:[line_error]
    ror ah,1
    adc di,0
    loop line_b_loop_16f
line_b_continue_18e:
    xor ax,ax
    out dx,ax
    inc ax
    out dx,ax
    mov al,3
    out dx,ax
    mov ax,0ff08h
    out dx,ax
    pop di
    pop si
    pop bp
    retf 8
u9_0b6a endp

; draw rectangle outline
u9_0d0a proc far
    push bp
    mov bp,sp
    push si
    push di
    mov dx,3ceh
    mov ax,word ptr cs:[draw_color]
    xchg ah,al
    xor al,al
    out dx,ax
    mov ax,0f01h
    out dx,ax
    mov ah,0
    mov al,3
    out dx,ax
    mov dx,3ceh
    mov al,3
    mov ah,byte ptr cs:[draw_operation]
    shl ah,1
    shl ah,1
    shl ah,1
    out dx,ax
    mov si,word ptr cs:[screen_stride]
    mov ax,word ptr [bp+0ah]
    mov bx,word ptr [bp+6]
    mov cx,bx
    sub cx,ax
    jge outline_ge_40
    neg cx
    mov ax,bx
outline_ge_40:
    inc cx
    mov bx,word ptr [bp+0ch]
    push cx
    push cs
    call near ptr u9_098a
    shl ah,cl
    mov al,8
    out dx,ax
    pop cx
outline_loop_4f:
    or byte ptr es:[bx],al
    add bx,si
    loop outline_loop_4f
    mov ax,word ptr [bp+0ah]
    mov bx,word ptr [bp+6]
    mov cx,bx
    sub cx,ax
    jge outline_ge_66
    neg cx
    mov ax,bx
outline_ge_66:
    inc cx
    mov bx,word ptr [bp+8]
    push cx
    push cs
    call near ptr u9_098a
    shl ah,cl
    mov al,8
    out dx,ax
    pop cx
outline_loop_75:
    or byte ptr es:[bx],al
    add bx,si
    loop outline_loop_75
    push ds
    mov ax,word ptr [bp+0ah]
    mov bx,word ptr [bp+0ch]
    push cs
    call near ptr u9_098a
    mov di,bx
    mov dh,ah
    not dh
    shl dh,cl
    not dh
    mov cx,word ptr [bp+8]
    and cl,7
    xor cl,7
    mov dl,0ffh
    shl dl,cl
    mov ax,word ptr [bp+8]
    mov bx,word ptr [bp+0ch]
    mov cl,3
    shr ax,cl
    shr bx,cl
    mov cx,ax
    sub cx,bx
    mov bx,dx
    mov dx,3ceh
    mov al,8
    push es
    pop ds
    mov si,di
    or bh,bh
    js outline_negative_ca
    or cx,cx
    jne outline_different_c5
    and bl,bh
    jmp short outline_continue_cf
outline_different_c5:
    mov ah,bh
    out dx,ax
    movsb
    dec cx
outline_negative_ca:
    mov ah,0ffh
    out dx,ax
    rep movsb
outline_continue_cf:
    mov ah,bl
    out dx,ax
    movsb
    pop ds
    push ds
    mov ax,word ptr [bp+6]
    mov bx,word ptr [bp+0ch]
    push cs
    call near ptr u9_098a
    mov di,bx
    mov dh,ah
    not dh
    shl dh,cl
    not dh
    mov cx,word ptr [bp+8]
    and cl,7
    xor cl,7
    mov dl,0ffh
    shl dl,cl
    mov ax,word ptr [bp+8]
    mov bx,word ptr [bp+0ch]
    mov cl,3
    shr ax,cl
    shr bx,cl
    mov cx,ax
    sub cx,bx
    mov bx,dx
    mov dx,3ceh
    mov al,8
    push es
    pop ds
    mov si,di
    or bh,bh
    js outline_negative_122
    or cx,cx
    jne outline_different_11d
    and bl,bh
    jmp short outline_continue_127
outline_different_11d:
    mov ah,bh
    out dx,ax
    movsb
    dec cx
outline_negative_122:
    mov ah,0ffh
    out dx,ax
    rep movsb
outline_continue_127:
    mov ah,bl
    out dx,ax
    movsb
    pop ds
    xor ax,ax
    out dx,ax
    inc ax
    out dx,ax
    mov al,3
    out dx,ax
    mov ax,0ff08h
    out dx,ax
    pop di
    pop si
    pop bp
    retf 8
u9_0d0a endp

; draw rectangle outline clipped
u9_0e48 proc far
    push bp
    mov bp,sp
    push si
    push di
    mov dx,3ceh
    mov ax,word ptr cs:[draw_color]
    xchg ah,al
    xor al,al
    out dx,ax
    mov ax,0f01h
    out dx,ax
    mov ah,0
    mov al,3
    out dx,ax
    mov dx,3ceh
    mov al,3
    mov ah,0
    out dx,ax
    mov si,word ptr cs:[screen_stride]
    mov ax,word ptr [bp+0ch]
    mov bx,word ptr [bp+8]
    cmp ax,bx
    jle clip_outline_le_38
    xchg bx,ax
    mov word ptr [bp+0ch],ax
    mov word ptr [bp+8],bx
clip_outline_le_38:
    mov ax,word ptr [bp+0ah]
    mov bx,word ptr [bp+6]
    cmp ax,bx
    jle clip_outline_le_49
    xchg bx,ax
    mov word ptr [bp+0ah],ax
    mov word ptr [bp+6],bx
clip_outline_le_49:
    cmp ax,word ptr cs:[clip_top]
    jge clip_outline_ge_54
    mov ax,word ptr cs:[clip_top]
clip_outline_ge_54:
    mov bx,word ptr [bp+6]
    cmp bx,word ptr cs:[clip_bottom]
    jle clip_outline_le_63
    mov bx,word ptr cs:[clip_bottom]
clip_outline_le_63:
    mov cx,bx
    sub cx,ax
    jge clip_outline_ge_6d
    neg cx
    mov ax,bx
clip_outline_ge_6d:
    inc cx
    mov bx,word ptr [bp+0ch]
    cmp bx,word ptr cs:[clip_left_pixels]
    jl clip_outline_less_91
    cmp bx,word ptr cs:[clip_right_pixels]
    jg clip_outline_greater_df
    push cx
    push cs
    call near ptr u9_098a
    shl ah,cl
    mov al,8
    out dx,ax
    pop cx
clip_outline_loop_8a:
    or byte ptr es:[bx],al
    add bx,si
    loop clip_outline_loop_8a
clip_outline_less_91:
    mov ax,word ptr [bp+0ah]
    cmp ax,word ptr cs:[clip_top]
    jg clip_outline_greater_9f
    mov ax,word ptr cs:[clip_top]
clip_outline_greater_9f:
    mov bx,word ptr [bp+6]
    cmp bx,word ptr cs:[clip_bottom]
    jl clip_outline_less_ae
    mov bx,word ptr cs:[clip_bottom]
clip_outline_less_ae:
    mov cx,bx
    sub cx,ax
    jge clip_outline_ge_b8
    neg cx
    mov ax,bx
clip_outline_ge_b8:
    inc cx
    mov bx,word ptr [bp+8]
    cmp bx,word ptr cs:[clip_left_pixels]
    jl clip_outline_greater_df
    cmp bx,word ptr cs:[clip_right_pixels]
    jg clip_outline_greater_e5
    push cx
    push cs
    call near ptr u9_098a
    shl ah,cl
    mov al,8
    out dx,ax
    pop cx
clip_outline_loop_d5:
    or byte ptr es:[bx],al
    add bx,si
    loop clip_outline_loop_d5
    jmp short clip_outline_greater_e5
    nop
clip_outline_greater_df:
    jmp near ptr clip_outline_continue_215
clip_outline_repeat_e2:
    jmp near ptr clip_outline_continue_180
clip_outline_greater_e5:
    push ds
    mov ax,word ptr [bp+0ah]
    cmp ax,word ptr cs:[clip_top]
    jl clip_outline_repeat_e2
    cmp ax,word ptr cs:[clip_bottom]
    jg clip_outline_greater_df
    mov bx,word ptr [bp+0ch]
    cmp bx,word ptr cs:[clip_left_pixels]
    jge clip_outline_ge_106
    mov bx,word ptr cs:[clip_left_pixels]
clip_outline_ge_106:
    push cs
    call near ptr u9_098a
    mov di,bx
    mov dh,ah
    not dh
    shl dh,cl
    not dh
    mov cx,word ptr [bp+8]
    cmp cx,word ptr cs:[clip_right_pixels]
    jle clip_outline_le_123
    mov cx,word ptr cs:[clip_right_pixels]
clip_outline_le_123:
    and cl,7
    xor cl,7
    mov dl,0ffh
    shl dl,cl
    mov ax,word ptr [bp+8]
    cmp ax,word ptr cs:[clip_right_pixels]
    jle clip_outline_le_13b
    mov ax,word ptr cs:[clip_right_pixels]
clip_outline_le_13b:
    mov bx,word ptr [bp+0ch]
    cmp bx,word ptr cs:[clip_left_pixels]
    jge clip_outline_ge_14a
    mov bx,word ptr cs:[clip_left_pixels]
clip_outline_ge_14a:
    mov cl,3
    shr ax,cl
    shr bx,cl
    mov cx,ax
    sub cx,bx
    mov bx,dx
    mov dx,3ceh
    mov al,8
    push es
    pop ds
    mov si,di
    or bh,bh
    js clip_outline_negative_170
    or cx,cx
    jne clip_outline_different_16b
    and bl,bh
    jmp short clip_outline_continue_175
clip_outline_different_16b:
    mov ah,bh
    out dx,ax
    movsb
    dec cx
clip_outline_negative_170:
    mov ah,0ffh
    out dx,ax
    rep movsb
clip_outline_continue_175:
    mov ah,bl
    out dx,ax
    movsb
    pop ds
    jmp short clip_outline_continue_180
    nop
clip_outline_repeat_17d:
    jmp near ptr clip_outline_continue_215
clip_outline_continue_180:
    push ds
    mov ax,word ptr [bp+6]
    cmp ax,word ptr cs:[clip_top]
    jl clip_outline_repeat_17d
    cmp ax,word ptr cs:[clip_bottom]
    jg clip_outline_repeat_17d
    mov bx,word ptr [bp+0ch]
    cmp bx,word ptr cs:[clip_left_pixels]
    jge clip_outline_ge_1a1
    mov bx,word ptr cs:[clip_left_pixels]
clip_outline_ge_1a1:
    push cs
    call near ptr u9_098a
    mov di,bx
    mov dh,ah
    not dh
    shl dh,cl
    not dh
    mov cx,word ptr [bp+8]
    cmp cx,word ptr cs:[clip_right_pixels]
    jle clip_outline_le_1be
    mov cx,word ptr cs:[clip_right_pixels]
clip_outline_le_1be:
    and cl,7
    xor cl,7
    mov dl,0ffh
    shl dl,cl
    mov ax,word ptr [bp+8]
    cmp ax,word ptr cs:[clip_right_pixels]
    jle clip_outline_le_1d6
    mov ax,word ptr cs:[clip_right_pixels]
clip_outline_le_1d6:
    mov bx,word ptr [bp+0ch]
    cmp bx,word ptr cs:[clip_left_pixels]
    jge clip_outline_ge_1e5
    mov bx,word ptr cs:[clip_left_pixels]
clip_outline_ge_1e5:
    mov cl,3
    shr ax,cl
    shr bx,cl
    mov cx,ax
    sub cx,bx
    mov bx,dx
    mov dx,3ceh
    mov al,8
    push es
    pop ds
    mov si,di
    or bh,bh
    js clip_outline_negative_20b
    or cx,cx
    jne clip_outline_different_206
    and bl,bh
    jmp short clip_outline_continue_210
clip_outline_different_206:
    mov ah,bh
    out dx,ax
    movsb
    dec cx
clip_outline_negative_20b:
    mov ah,0ffh
    out dx,ax
    rep movsb
clip_outline_continue_210:
    mov ah,bl
    out dx,ax
    movsb
    pop ds
clip_outline_continue_215:
    xor ax,ax
    out dx,ax
    inc ax
    out dx,ax
    mov al,3
    out dx,ax
    mov ax,0ff08h
    out dx,ax
    pop di
    pop si
    pop bp
    retf 8
u9_0e48 endp

; fill rectangle
u9_106f proc far
    push bp
    mov bp,sp
    push si
    push di
    mov dx,3ceh
    mov ah,byte ptr cs:[draw_color]
    xor al,al
    out dx,ax
    mov ax,0f01h
    out dx,ax
    mov ah,0
    mov al,3
    out dx,ax
fill_rect_repeat_19:
    mov si,word ptr cs:[screen_stride]
    push ds
    mov ax,word ptr [bp+0ah]
    mov bx,word ptr [bp+0ch]
    push cs
    call near ptr u9_098a
    mov di,bx
    mov dh,ah
    not dh
    shl dh,cl
    not dh
    mov cx,word ptr [bp+8]
    and cl,7
    xor cl,7
    mov dl,0ffh
    shl dl,cl
    mov ax,word ptr [bp+8]
    mov bx,word ptr [bp+0ch]
    mov cl,3
    shr ax,cl
    shr bx,cl
    mov cx,ax
    sub cx,bx
    mov bx,dx
    mov dx,3ceh
    mov al,8
    push es
    pop ds
    mov si,di
    or bh,bh
    js fill_rect_negative_6c
    or cx,cx
    jne fill_rect_different_67
    and bl,bh
    jmp short fill_rect_continue_71
fill_rect_different_67:
    mov ah,bh
    out dx,ax
    movsb
    dec cx
fill_rect_negative_6c:
    mov ah,0ffh
    out dx,ax
    rep movsb
fill_rect_continue_71:
    mov ah,bl
    out dx,ax
    movsb
    pop ds
    mov cx,word ptr [bp+0ah]
    inc cx
    mov word ptr [bp+0ah],cx
    mov bx,word ptr [bp+6]
    cmp cx,bx
    jle fill_rect_repeat_19
    xor ax,ax
    out dx,ax
    inc ax
    out dx,ax
    mov al,3
    out dx,ax
    mov ax,0ff08h
    out dx,ax
    pop di
    pop si
    pop bp
    retf 8
u9_106f endp

; fill rectangle clipped pixels
u9_1105 proc far
    push bp
    mov bp,sp
    push si
    push di
    jmp short clip_fill_rect_continue_a
clip_fill_rect_repeat_7:
    jmp near ptr clip_fill_rect_continue_ea
clip_fill_rect_continue_a:
    mov ax,word ptr [bp+0ch]
    cmp ax,word ptr cs:[clip_right_pixels]
    jg clip_fill_rect_repeat_7
    cmp ax,word ptr cs:[clip_left_pixels]
    jge clip_fill_rect_ge_22
    mov ax,word ptr cs:[clip_left_pixels]
    mov word ptr [bp+0ch],ax
clip_fill_rect_ge_22:
    mov ax,word ptr [bp+8]
    cmp ax,word ptr cs:[clip_left_pixels]
    jl clip_fill_rect_repeat_7
    cmp ax,word ptr cs:[clip_right_pixels]
    jle clip_fill_rect_le_3a
    mov ax,word ptr cs:[clip_right_pixels]
    mov word ptr [bp+8],ax
clip_fill_rect_le_3a:
    mov ax,word ptr [bp+0ah]
    cmp ax,word ptr cs:[clip_bottom]
    jg clip_fill_rect_repeat_7
    cmp ax,word ptr cs:[clip_top]
    jge clip_fill_rect_ge_52
    mov ax,word ptr cs:[clip_top]
    mov word ptr [bp+0ah],ax
clip_fill_rect_ge_52:
    mov ax,word ptr [bp+6]
    cmp ax,word ptr cs:[clip_top]
    jl clip_fill_rect_repeat_7
    cmp ax,word ptr cs:[clip_bottom]
    jle clip_fill_rect_le_6a
    mov ax,word ptr cs:[clip_bottom]
    mov word ptr [bp+6],ax
clip_fill_rect_le_6a:
    mov dx,3ceh
    mov ax,word ptr cs:[draw_color]
    xchg ah,al
    xor al,al
    out dx,ax
    mov ax,0f01h
    out dx,ax
    mov ah,0
    mov al,3
    out dx,ax
clip_fill_rect_repeat_7f:
    mov si,word ptr cs:[screen_stride]
    push ds
    mov ax,word ptr [bp+0ah]
    mov bx,word ptr [bp+0ch]
    push cs
    call near ptr u9_098a
    mov di,bx
    mov dh,ah
    not dh
    shl dh,cl
    not dh
    mov cx,word ptr [bp+8]
    and cl,7
    xor cl,7
    mov dl,0ffh
    shl dl,cl
    mov ax,word ptr [bp+8]
    mov bx,word ptr [bp+0ch]
    mov cl,3
    shr ax,cl
    shr bx,cl
    mov cx,ax
    sub cx,bx
    mov bx,dx
    mov dx,3ceh
    mov al,8
    push es
    pop ds
    mov si,di
    or bh,bh
    js clip_fill_rect_negative_d2
    or cx,cx
    jne clip_fill_rect_different_cd
    and bl,bh
    jmp short clip_fill_rect_continue_d7
clip_fill_rect_different_cd:
    mov ah,bh
    out dx,ax
    movsb
    dec cx
clip_fill_rect_negative_d2:
    mov ah,0ffh
    out dx,ax
    rep movsb
clip_fill_rect_continue_d7:
    mov ah,bl
    out dx,ax
    movsb
    pop ds
    mov cx,word ptr [bp+0ah]
    inc cx
    mov word ptr [bp+0ah],cx
    mov bx,word ptr [bp+6]
    cmp cx,bx
    jle clip_fill_rect_repeat_7f
clip_fill_rect_continue_ea:
    mov dx,3ceh
    xor ax,ax
    out dx,ax
    inc ax
    out dx,ax
    mov al,3
    out dx,ax
    mov ax,0ff08h
    out dx,ax
    pop di
    pop si
    pop bp
    retf 8
u9_1105 endp

; draw horizontal span
u9_1204 proc far
    push bp
    mov bp,sp
    push si
    push di
    mov dx,3ceh
    mov ah,byte ptr cs:[draw_color]
    xor al,al
    out dx,ax
    mov ax,0f01h
    out dx,ax
    mov ah,0
    mov al,3
    out dx,ax
    mov si,word ptr cs:[screen_stride]
    mov ax,word ptr [bp+0ah]
    mov bx,word ptr [bp+8]
    cmp ax,bx
    jl hspan_less_2e
    mov word ptr [bp+0ah],bx
    mov word ptr [bp+8],ax
hspan_less_2e:
    push ds
    mov ax,word ptr [bp+6]
    mov bx,word ptr [bp+0ah]
    push cs
    call near ptr u9_098a
    mov di,bx
    mov dh,ah
    not dh
    shl dh,cl
    not dh
    mov cx,word ptr [bp+8]
    and cl,7
    xor cl,7
    mov dl,0ffh
    shl dl,cl
    mov ax,word ptr [bp+8]
    mov bx,word ptr [bp+0ah]
    mov cl,3
    shr ax,cl
    shr bx,cl
    mov cx,ax
    sub cx,bx
    mov bx,dx
    mov dx,3ceh
    mov al,8
    push es
    pop ds
    mov si,di
    or bh,bh
    js hspan_negative_7c
    or cx,cx
    jne hspan_different_77
    and bl,bh
    jmp short hspan_continue_81
hspan_different_77:
    mov ah,bh
    out dx,ax
    movsb
    dec cx
hspan_negative_7c:
    mov ah,0ffh
    out dx,ax
    rep movsb
hspan_continue_81:
    mov ah,bl
    out dx,ax
    movsb
    pop ds
    xor ax,ax
    out dx,ax
    inc ax
    out dx,ax
    mov al,3
    out dx,ax
    mov ax,0ff08h
    out dx,ax
    pop di
    pop si
    pop bp
    retf 6
u9_1204 endp

; draw vertical span
u9_129c proc far
    push bp
    mov bp,sp
    push si
    push di
    mov dx,3ceh
    mov ah,byte ptr cs:[draw_color]
    xor al,al
    out dx,ax
    mov ax,0f01h
    out dx,ax
    mov ah,0
    mov al,3
    out dx,ax
    mov si,word ptr cs:[screen_stride]
    mov ax,word ptr [bp+0ah]
    mov bx,word ptr [bp+8]
    mov cx,bx
    sub cx,ax
    jge vspan_ge_2e
    neg cx
    mov ax,bx
vspan_ge_2e:
    inc cx
    mov bx,word ptr [bp+6]
    push cx
    push cs
    call near ptr u9_098a
    shl ah,cl
    mov al,8
    out dx,ax
    pop cx
vspan_loop_3d:
    or byte ptr es:[bx],al
    add bx,si
    loop vspan_loop_3d
    xor ax,ax
    out dx,ax
    inc ax
    out dx,ax
    mov al,3
    out dx,ax
    mov ax,0ff08h
    out dx,ax
    pop di
    pop si
    pop bp
    retf 6
u9_129c endp

circle_x               dw ?
circle_y               dw ?
circle_error           dw ?
circle_x_delta         dw ?
circle_y_delta         dw ?
; draw circle variant a
u9_12fc proc far
    push bp
    mov bp,sp
    push si
    push di
    mov dx,3ceh
    mov ah,byte ptr cs:[draw_color]
    xor al,al
    out dx,ax
    mov ax,0f01h
    out dx,ax
    mov ah,0
    mov al,3
    out dx,ax
    mov word ptr cs:[circle_x],0
    mov si,word ptr [bp+6]
    mov word ptr cs:[circle_y],si
    mov si,3
    sub si,word ptr [bp+6]
    sub si,word ptr [bp+6]
    mov word ptr cs:[circle_error],si
circle_a_repeat_36:
    mov si,word ptr cs:[screen_stride]
    push ds
    mov ax,word ptr [bp+8]
    add ax,word ptr cs:[circle_y]
    mov bx,word ptr [bp+0ah]
    sub bx,word ptr cs:[circle_x]
    mov word ptr cs:[circle_x_delta],bx
    push cs
    call near ptr u9_098a
    mov di,bx
    mov dh,ah
    not dh
    shl dh,cl
    not dh
    mov cx,word ptr [bp+0ah]
    add cx,word ptr cs:[circle_x]
    mov word ptr cs:[circle_y_delta],cx
    and cl,7
    xor cl,7
    mov dl,0ffh
    shl dl,cl
    mov ax,word ptr cs:[circle_y_delta]
    mov bx,word ptr cs:[circle_x_delta]
    mov cl,3
    shr ax,cl
    shr bx,cl
    mov cx,ax
    sub cx,bx
    mov bx,dx
    mov dx,3ceh
    mov al,8
    push es
    pop ds
    mov si,di
    or bh,bh
    js circle_a_negative_a5
    or cx,cx
    jne circle_a_different_a0
    and bl,bh
    jmp short circle_a_continue_aa
circle_a_different_a0:
    mov ah,bh
    out dx,ax
    movsb
    dec cx
circle_a_negative_a5:
    mov ah,0ffh
    out dx,ax
    rep movsb
circle_a_continue_aa:
    mov ah,bl
    out dx,ax
    movsb
    mov si,word ptr cs:[screen_stride]
    mov ax,word ptr [bp+8]
    sub ax,word ptr cs:[circle_y]
    mov bx,word ptr [bp+0ah]
    sub bx,word ptr cs:[circle_x]
    mov word ptr cs:[circle_x_delta],bx
    push cs
    call near ptr u9_098a
    mov di,bx
    mov dh,ah
    not dh
    shl dh,cl
    not dh
    mov cx,word ptr [bp+0ah]
    add cx,word ptr cs:[circle_x]
    mov word ptr cs:[circle_y_delta],cx
    and cl,7
    xor cl,7
    mov dl,0ffh
    shl dl,cl
    mov ax,word ptr cs:[circle_y_delta]
    mov bx,word ptr cs:[circle_x_delta]
    mov cl,3
    shr ax,cl
    shr bx,cl
    mov cx,ax
    sub cx,bx
    mov bx,dx
    mov dx,3ceh
    mov al,8
    push es
    pop ds
    mov si,di
    or bh,bh
    js circle_a_negative_11c
    or cx,cx
    jne circle_a_different_117
    and bl,bh
    jmp short circle_a_continue_121
circle_a_different_117:
    mov ah,bh
    out dx,ax
    movsb
    dec cx
circle_a_negative_11c:
    mov ah,0ffh
    out dx,ax
    rep movsb
circle_a_continue_121:
    mov ah,bl
    out dx,ax
    movsb
    mov si,word ptr cs:[screen_stride]
    mov ax,word ptr [bp+8]
    add ax,word ptr cs:[circle_x]
    mov bx,word ptr [bp+0ah]
    sub bx,word ptr cs:[circle_y]
    mov word ptr cs:[circle_x_delta],bx
    push cs
    call near ptr u9_098a
    mov di,bx
    mov dh,ah
    not dh
    shl dh,cl
    not dh
    mov cx,word ptr [bp+0ah]
    add cx,word ptr cs:[circle_y]
    mov word ptr cs:[circle_y_delta],cx
    and cl,7
    xor cl,7
    mov dl,0ffh
    shl dl,cl
    mov ax,word ptr cs:[circle_y_delta]
    mov bx,word ptr cs:[circle_x_delta]
    mov cl,3
    shr ax,cl
    shr bx,cl
    mov cx,ax
    sub cx,bx
    mov bx,dx
    mov dx,3ceh
    mov al,8
    push es
    pop ds
    mov si,di
    or bh,bh
    js circle_a_negative_193
    or cx,cx
    jne circle_a_different_18e
    and bl,bh
    jmp short circle_a_continue_198
circle_a_different_18e:
    mov ah,bh
    out dx,ax
    movsb
    dec cx
circle_a_negative_193:
    mov ah,0ffh
    out dx,ax
    rep movsb
circle_a_continue_198:
    mov ah,bl
    out dx,ax
    movsb
    mov si,word ptr cs:[screen_stride]
    mov ax,word ptr [bp+8]
    sub ax,word ptr cs:[circle_x]
    mov bx,word ptr [bp+0ah]
    sub bx,word ptr cs:[circle_y]
    mov word ptr cs:[circle_x_delta],bx
    push cs
    call near ptr u9_098a
    mov di,bx
    mov dh,ah
    not dh
    shl dh,cl
    not dh
    mov cx,word ptr [bp+0ah]
    add cx,word ptr cs:[circle_y]
    mov word ptr cs:[circle_y_delta],cx
    and cl,7
    xor cl,7
    mov dl,0ffh
    shl dl,cl
    mov ax,word ptr cs:[circle_y_delta]
    mov bx,word ptr cs:[circle_x_delta]
    mov cl,3
    shr ax,cl
    shr bx,cl
    mov cx,ax
    sub cx,bx
    mov bx,dx
    mov dx,3ceh
    mov al,8
    push es
    pop ds
    mov si,di
    or bh,bh
    js circle_a_negative_20a
    or cx,cx
    jne circle_a_different_205
    and bl,bh
    jmp short circle_a_continue_20f
circle_a_different_205:
    mov ah,bh
    out dx,ax
    movsb
    dec cx
circle_a_negative_20a:
    mov ah,0ffh
    out dx,ax
    rep movsb
circle_a_continue_20f:
    mov ah,bl
    out dx,ax
    movsb
    pop ds
    mov si,word ptr cs:[circle_error]
    cmp si,0
    jle circle_a_le_249
    mov si,word ptr cs:[circle_error]
    add si,0ah
    mov di,word ptr cs:[circle_x]
    sub di,word ptr cs:[circle_y]
    shl di,1
    shl di,1
    add si,di
    mov word ptr cs:[circle_error],si
    mov si,word ptr cs:[circle_y]
    dec si
    mov word ptr cs:[circle_y],si
    jmp short circle_a_continue_261
    nop
circle_a_le_249:
    mov si,word ptr cs:[circle_error]
    add si,6
    mov di,word ptr cs:[circle_x]
    shl di,1
    shl di,1
    add si,di
    mov word ptr cs:[circle_error],si
circle_a_continue_261:
    mov di,word ptr cs:[circle_x]
    inc di
    mov word ptr cs:[circle_x],di
    mov si,word ptr cs:[circle_y]
    cmp si,di
    jl circle_a_less_278
    jmp near ptr circle_a_repeat_36
circle_a_less_278:
    xor ax,ax
    out dx,ax
    inc ax
    out dx,ax
    mov al,3
    out dx,ax
    mov ax,0ff08h
    out dx,ax
    pop di
    pop si
    pop bp
    retf 6
u9_12fc endp

circle2_x              dw ?
circle2_y              dw ?
circle2_error          dw ?
circle2_work1          dw ?
circle2_work2          dw ?
; draw circle symmetric
u9_1590 proc far
    push bp
    mov bp,sp
    push si
    push di
    mov dx,3ceh
    mov ah,byte ptr cs:[draw_color]
    xor al,al
    out dx,ax
    mov ax,0f01h
    out dx,ax
    mov ah,0
    mov al,3
    out dx,ax
    mov word ptr cs:[circle2_x],0
    mov si,word ptr [bp+6]
    mov word ptr cs:[circle2_y],si
    mov si,3
    sub si,word ptr [bp+6]
    sub si,word ptr [bp+6]
    mov word ptr cs:[circle2_error],si
circle_b_repeat_36:
    mov si,word ptr cs:[screen_stride]
    mov ax,word ptr [bp+8]
    add ax,word ptr cs:[circle2_y]
    mov bx,word ptr [bp+0ah]
    add bx,word ptr cs:[circle2_x]
    push cx
    push cs
    call near ptr u9_098a
    shl ah,cl
    mov al,8
    out dx,ax
    pop cx
    or byte ptr es:[bx],al
    mov ax,word ptr [bp+8]
    sub ax,word ptr cs:[circle2_y]
    mov bx,word ptr [bp+0ah]
    add bx,word ptr cs:[circle2_x]
    push cx
    push cs
    call near ptr u9_098a
    shl ah,cl
    mov al,8
    out dx,ax
    pop cx
    or byte ptr es:[bx],al
    mov ax,word ptr [bp+8]
    add ax,word ptr cs:[circle2_y]
    mov bx,word ptr [bp+0ah]
    sub bx,word ptr cs:[circle2_x]
    push cx
    push cs
    call near ptr u9_098a
    shl ah,cl
    mov al,8
    out dx,ax
    pop cx
    or byte ptr es:[bx],al
    mov ax,word ptr [bp+8]
    sub ax,word ptr cs:[circle2_y]
    mov bx,word ptr [bp+0ah]
    sub bx,word ptr cs:[circle2_x]
    push cx
    push cs
    call near ptr u9_098a
    shl ah,cl
    mov al,8
    out dx,ax
    pop cx
    or byte ptr es:[bx],al
    mov ax,word ptr [bp+8]
    add ax,word ptr cs:[circle2_x]
    mov bx,word ptr [bp+0ah]
    add bx,word ptr cs:[circle2_y]
    push cx
    push cs
    call near ptr u9_098a
    shl ah,cl
    mov al,8
    out dx,ax
    pop cx
    or byte ptr es:[bx],al
    mov ax,word ptr [bp+8]
    sub ax,word ptr cs:[circle2_x]
    mov bx,word ptr [bp+0ah]
    add bx,word ptr cs:[circle2_y]
    push cx
    push cs
    call near ptr u9_098a
    shl ah,cl
    mov al,8
    out dx,ax
    pop cx
    or byte ptr es:[bx],al
    mov ax,word ptr [bp+8]
    add ax,word ptr cs:[circle2_x]
    mov bx,word ptr [bp+0ah]
    sub bx,word ptr cs:[circle2_y]
    push cx
    push cs
    call near ptr u9_098a
    shl ah,cl
    mov al,8
    out dx,ax
    pop cx
    or byte ptr es:[bx],al
    mov ax,word ptr [bp+8]
    sub ax,word ptr cs:[circle2_x]
    mov bx,word ptr [bp+0ah]
    sub bx,word ptr cs:[circle2_y]
    push cx
    push cs
    call near ptr u9_098a
    shl ah,cl
    mov al,8
    out dx,ax
    pop cx
    or byte ptr es:[bx],al
    mov si,word ptr cs:[circle2_error]
    cmp si,0
    jle circle_b_le_160
    mov si,word ptr cs:[circle2_error]
    add si,0ah
    mov di,word ptr cs:[circle2_x]
    sub di,word ptr cs:[circle2_y]
    shl di,1
    shl di,1
    add si,di
    mov word ptr cs:[circle2_error],si
    mov si,word ptr cs:[circle2_y]
    dec si
    mov word ptr cs:[circle2_y],si
    jmp short circle_b_continue_178
    nop
circle_b_le_160:
    mov si,word ptr cs:[circle2_error]
    add si,6
    mov di,word ptr cs:[circle2_x]
    shl di,1
    shl di,1
    add si,di
    mov word ptr cs:[circle2_error],si
circle_b_continue_178:
    mov di,word ptr cs:[circle2_x]
    inc di
    mov word ptr cs:[circle2_x],di
    mov si,word ptr cs:[circle2_y]
    cmp si,di
    jl circle_b_less_18f
    jmp near ptr circle_b_repeat_36
circle_b_less_18f:
    xor ax,ax
    out dx,ax
    inc ax
    out dx,ax
    mov al,3
    out dx,ax
    mov ax,0ff08h
    out dx,ax
    pop di
    pop si
    pop bp
    retf 6
u9_1590 endp

; set clip rectangle
u9_1731 proc far
    push bp
    mov bp,sp
    mov ax,word ptr [bp+0ch]
    mov word ptr cs:[clip_left],ax
    mov ax,word ptr [bp+8]
    mov word ptr cs:[clip_right],ax
    mov ax,word ptr [bp+0ah]
    mov word ptr cs:[clip_top],ax
    mov ax,word ptr [bp+6]
    mov word ptr cs:[clip_bottom],ax
    pop bp
    retf 8
u9_1731 endp

; get clip left
u9_1754 proc far
    mov ax,word ptr cs:[clip_left]
    retf
u9_1754 endp

; get clip right
u9_1759 proc far
    mov ax,word ptr cs:[clip_right]
    retf
u9_1759 endp

; set clip rectangle variant
u9_175e proc far
    push bp
    mov bp,sp
    mov ax,word ptr [bp+0ch]
    mov word ptr cs:[clip_left_pixels],ax
    mov ax,word ptr [bp+8]
    mov word ptr cs:[clip_right_pixels],ax
    mov ax,word ptr [bp+0ah]
    mov word ptr cs:[clip_top],ax
    mov ax,word ptr [bp+6]
    mov word ptr cs:[clip_bottom],ax
    pop bp
    retf 8
u9_175e endp

; get clip left variant
u9_1781 proc far
    mov ax,word ptr cs:[clip_left_pixels]
    retf
u9_1781 endp

; get clip right variant
u9_1786 proc far
    mov ax,word ptr cs:[clip_right_pixels]
    retf
u9_1786 endp

; get clip top
u9_178b proc far
    mov ax,word ptr cs:[clip_top]
    retf
u9_178b endp

; get clip bottom
u9_1790 proc far
    mov ax,word ptr cs:[clip_bottom]
    retf
u9_1790 endp

; capture planar rectangle
u9_1795 proc far
    push bp
    mov bp,sp
    push ds
    push si
    push di
    mov ax,word ptr [bp+8]
    sub ax,word ptr [bp+0ch]
    push ax
    mov ax,word ptr [bp+6]
    sub ax,word ptr [bp+0ah]
    inc ax
    push ax
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+0ah]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov bx,word ptr [bp+0ch]
    add bx,ax
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je capture_equal_41
    mov cx,ax
capture_loop_3b:
    add bx,2000h
    loop capture_loop_3b
capture_equal_41:
    push es
    pop ds
    mov si,bx
    les di,dword ptr [bp+0eh]
    nop
    pop ax
    mov word ptr cs:[transfer_width],ax
    stosw
    pop ax
    mov word ptr cs:[transfer_height],ax
    stosw
    mov al,0ffh
    stosb
    mov dx,3ceh
    mov ax,5
    out dx,ax
    mov ax,304h
capture_repeat_62:
    out dx,ax
    push ax
    push word ptr cs:[transfer_width]
    push si
capture_repeat_6a:
    mov bx,word ptr cs:[transfer_height]
    push si
capture_repeat_70:
    lodsb
    stosb
    dec bx
    jne capture_repeat_70
    pop si
    add si,word ptr cs:[screen_stride]
    dec word ptr cs:[transfer_width]
    jne capture_repeat_6a
    pop si
    pop word ptr cs:[transfer_width]
    pop ax
    dec ah
    jns capture_repeat_62
    mov ax,di
    sub ax,word ptr [bp+0eh]
    nop
    pop di
    pop si
    pop ds
    mov sp,bp
    pop bp
    retf 0ch
u9_1795 endp

; restore planar rectangle
u9_1831 proc far
    push bp
    mov bp,sp
    push ds
    push si
    push di
    lds si,dword ptr [bp+0ah]
    lodsw
    mov word ptr cs:[transfer_width],ax
    lodsw
    mov word ptr cs:[transfer_height],ax
    lodsb
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+6]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov bx,word ptr [bp+8]
    add bx,ax
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je restore_equal_40
    mov cx,ax
restore_loop_3a:
    add bx,2000h
    loop restore_loop_3a
restore_equal_40:
    mov di,bx
    mov dx,3c4h
    mov al,2
    out dx,al
    mov dx,3c5h
    mov ax,8
restore_repeat_4e:
    out dx,al
    shr ax,1
    push ax
    push word ptr cs:[transfer_width]
    push di
restore_repeat_58:
    mov bx,word ptr cs:[transfer_height]
restore_repeat_5d:
    lodsb
    xchg byte ptr es:[di],al
    inc di
    dec bx
    jne restore_repeat_5d
    add di,word ptr cs:[screen_stride]
    sub di,word ptr cs:[transfer_height]
    dec word ptr cs:[transfer_width]
    jne restore_repeat_58
    pop di
    pop word ptr cs:[transfer_width]
    pop ax
    cmp ax,0
    jg restore_repeat_4e
    mov ax,si
    sub ax,word ptr [bp+0eh]
    nop
    pop di
    pop si
    pop ds
    mov sp,bp
    pop bp
    retf 8
u9_1831 endp

sprite_shift           db ?
sprite_unshift         db ?
sprite_mask_left       db ?
sprite_mask_right      db ?
sprite_rows            db ?
sprite_plane1          db ?
sprite_plane2          db ?
sprite_plane3          db ?
; blit masked shifted sprite variant a
u9_18ca proc far
    push bp
    mov bp,sp
    push ds
    push si
    push di
    lds si,dword ptr [bp+0ah]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+6]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov bx,word ptr [bp+8]
    mov cl,3
    shr bx,cl
    add bx,ax
    mov ax,word ptr [bp+8]
    and ax,7
    mov byte ptr cs:[sprite_unshift],al
    mov al,8
    sub al,byte ptr cs:[sprite_unshift]
    mov byte ptr cs:[sprite_mask_left],al
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je masked_shift_equal_4e
    mov cx,ax
masked_shift_row_loop_48:
    add bx,2000h
    loop masked_shift_row_loop_48
masked_shift_equal_4e:
    mov dx,3c4h
    mov al,2
    out dx,al
    mov cx,10h
masked_shift_repeat_57:
    mov byte ptr cs:[sprite_shift],4
masked_shift_repeat_5d:
    mov dl,byte ptr cs:[sprite_shift]
    dec dl
    mov byte ptr cs:[sprite_shift],dl
    push cx
    mov dx,3ceh
    lodsb
    mov byte ptr cs:[sprite_mask_right],al
    mov ah,byte ptr cs:[sprite_mask_right]
    mov cl,byte ptr cs:[sprite_unshift]
    shr ah,cl
    mov al,8
    out dx,ax
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    mov byte ptr cs:[sprite_rows],al
    shr al,cl
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    mov byte ptr cs:[sprite_plane1],al
    shr al,cl
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    mov byte ptr cs:[sprite_plane2],al
    shr al,cl
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    mov byte ptr cs:[sprite_plane3],al
    shr al,cl
    xchg byte ptr es:[bx],al
    jmp short masked_shift_continue_bf
    nop
masked_shift_row_loop_bb:
    jmp short masked_shift_repeat_57
masked_shift_repeat_bd:
    jmp short masked_shift_repeat_5d
masked_shift_continue_bf:
    inc bx
    mov dx,3ceh
    mov ah,byte ptr cs:[sprite_mask_right]
    mov cl,byte ptr cs:[sprite_mask_left]
    shl ah,cl
    mov al,8
    out dx,ax
    mov dx,3c5h
    mov al,1
    out dx,al
    mov al,byte ptr cs:[sprite_rows]
    shl al,cl
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    mov al,byte ptr cs:[sprite_plane1]
    shl al,cl
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    mov al,byte ptr cs:[sprite_plane2]
    shl al,cl
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    mov al,byte ptr cs:[sprite_plane3]
    shl al,cl
    xchg byte ptr es:[bx],al
    pop cx
    mov dl,byte ptr cs:[sprite_shift]
    cmp dl,0
    jg masked_shift_repeat_bd
    add bx,word ptr cs:[screen_stride]
    dec bx
    dec bx
    dec bx
    dec bx
    loop masked_shift_row_loop_bb
    mov dx,3c5h
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop di
    pop si
    pop ds
    pop bp
    retf 8
u9_18ca endp

; blit masked shifted 16x16
u9_19f9 proc far
    push bp
    mov bp,sp
    push ds
    push si
    push di
    mov di,word ptr cs:[screen_stride]
    dec di
    dec di
    lds si,dword ptr [bp+0ah]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+6]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov bx,word ptr [bp+8]
    mov cl,3
    shr bx,cl
    add bx,ax
    mov ax,word ptr [bp+8]
    and ax,7
    mov byte ptr cs:[sprite_unshift],al
    mov al,8
    sub al,byte ptr cs:[sprite_unshift]
    mov byte ptr cs:[sprite_mask_left],al
    mov dx,3c4h
    mov al,2
    out dx,al
    mov cx,10h
masked_shift16_repeat_4e:
    mov byte ptr cs:[sprite_shift],2
masked_shift16_repeat_54:
    mov dl,byte ptr cs:[sprite_shift]
    dec dl
    mov byte ptr cs:[sprite_shift],dl
    push cx
    push di
    mov dx,3ceh
    lodsb
    mov ah,al
    mov di,ax
    mov cl,byte ptr cs:[sprite_unshift]
    shr ah,cl
    mov al,8
    out dx,ax
    mov dx,3c5h
    mov ch,1
    mov al,ch
    out dx,al
    lodsb
    mov byte ptr cs:[sprite_rows],al
    shr al,cl
    xchg byte ptr es:[bx],al
    shl ch,1
    mov al,ch
    out dx,al
    lodsb
    mov byte ptr cs:[sprite_plane1],al
    shr al,cl
    xchg byte ptr es:[bx],al
    shl ch,1
    mov al,ch
    out dx,al
    lodsb
    mov byte ptr cs:[sprite_plane2],al
    shr al,cl
    xchg byte ptr es:[bx],al
    shl ch,1
    mov al,ch
    out dx,al
    lodsb
    mov byte ptr cs:[sprite_plane3],al
    shr al,cl
    xchg byte ptr es:[bx],al
    jmp short masked_shift16_continue_ba
    nop
masked_shift16_row_loop_b6:
    jmp short masked_shift16_repeat_4e
masked_shift16_repeat_b8:
    jmp short masked_shift16_repeat_54
masked_shift16_continue_ba:
    inc bx
    mov dx,3ceh
    mov ax,di
    mov cl,byte ptr cs:[sprite_mask_left]
    shl ah,cl
    mov al,8
    out dx,ax
    mov dx,3c5h
    mov ch,1
    mov al,ch
    out dx,al
    mov al,byte ptr cs:[sprite_rows]
    shl al,cl
    xchg byte ptr es:[bx],al
    shl ch,1
    mov al,ch
    out dx,al
    mov al,byte ptr cs:[sprite_plane1]
    shl al,cl
    xchg byte ptr es:[bx],al
    shl ch,1
    mov al,ch
    out dx,al
    mov al,byte ptr cs:[sprite_plane2]
    shl al,cl
    xchg byte ptr es:[bx],al
    shl ch,1
    mov al,ch
    out dx,al
    mov al,byte ptr cs:[sprite_plane3]
    shl al,cl
    xchg byte ptr es:[bx],al
    pop di
    pop cx
    mov dl,byte ptr cs:[sprite_shift]
    cmp dl,0
    jg masked_shift16_repeat_b8
    add bx,di
    loop masked_shift16_row_loop_b6
    mov dx,3c5h
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop di
    pop si
    pop ds
    pop bp
    retf 8
u9_19f9 endp

sprite_width           db ?
sprite_height          db ?
sprite_work1           db ?
sprite_work2           db ?
sprite_stride          db ?
; blit masked variable sprite
u9_1b27 proc far
    push bp
    mov bp,sp
    push ds
    push di
    push si
    lds si,dword ptr [bp+0ah]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+6]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov cx,word ptr [bp+8]
    and cx,7
    xor cl,7
    inc cl
    mov byte ptr cs:[sprite_stride],cl
    mov bx,word ptr [bp+8]
    shr bx,1
    shr bx,1
    shr bx,1
    add bx,ax
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je masked_var_equal_4b
    mov cx,ax
masked_var_row_loop_45:
    add bx,2000h
    loop masked_var_row_loop_45
masked_var_equal_4b:
    mov dx,3c4h
    mov al,2
    out dx,al
    mov cx,8
masked_var_repeat_54:
    push cx
    lodsb
    mov ah,0
    mov cl,byte ptr cs:[sprite_stride]
    rol ax,cl
    mov byte ptr cs:[sprite_width],ah
    mov byte ptr cs:[sprite_height],al
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    mov ah,0
    mov cl,byte ptr cs:[sprite_stride]
    rol ax,cl
    mov cx,ax
    mov dx,3ceh
    mov al,8
    mov ah,byte ptr cs:[sprite_width]
    out dx,ax
    xchg byte ptr es:[bx],ch
    mov ah,byte ptr cs:[sprite_height]
    out dx,ax
    xchg byte ptr es:[bx+1],cl
    mov dx,3c5h
    mov al,2
    out dx,al
    lodsb
    mov ah,0
    mov cl,byte ptr cs:[sprite_stride]
    rol ax,cl
    mov cx,ax
    mov dx,3ceh
    mov al,8
    mov ah,byte ptr cs:[sprite_width]
    out dx,ax
    xchg byte ptr es:[bx],ch
    mov ah,byte ptr cs:[sprite_height]
    out dx,ax
    xchg byte ptr es:[bx+1],cl
    jmp short masked_var_continue_c1
    nop
masked_var_row_loop_bf:
    jmp short masked_var_repeat_54
masked_var_continue_c1:
    mov dx,3c5h
    mov al,4
    out dx,al
    lodsb
    mov ah,0
    mov cl,byte ptr cs:[sprite_stride]
    rol ax,cl
    mov cx,ax
    mov dx,3ceh
    mov al,8
    mov ah,byte ptr cs:[sprite_width]
    out dx,ax
    xchg byte ptr es:[bx],ch
    mov ah,byte ptr cs:[sprite_height]
    out dx,ax
    xchg byte ptr es:[bx+1],cl
    mov dx,3c5h
    mov al,8
    out dx,al
    lodsb
    mov ah,0
    mov cl,byte ptr cs:[sprite_stride]
    rol ax,cl
    mov cx,ax
    mov dx,3ceh
    mov al,8
    mov ah,byte ptr cs:[sprite_width]
    out dx,ax
    xchg byte ptr es:[bx],ch
    mov ah,byte ptr cs:[sprite_height]
    out dx,ax
    xchg byte ptr es:[bx+1],cl
    add bx,word ptr cs:[screen_stride]
    pop cx
    loop masked_var_row_loop_bf
    mov dx,3c5h
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
u9_1b27 endp

; draw ellipse or curve
u9_1c58 proc far
    push bp
    mov bp,sp
    sub sp,28h
    push si
    push di
    mov dx,3ceh
    mov ax,5
    out dx,ax
    mov ah,0
    mov al,3
    out dx,ax
    mov ax,word ptr cs:[draw_color]
    mov ah,al
    mov al,0
    out dx,ax
    mov ax,0f01h
    out dx,ax
    mov ax,word ptr [bp+8]
    mul ax
    mov word ptr [bp-20h],ax
    mov word ptr [bp-1eh],dx
    shl ax,1
    rcl dx,1
    mov word ptr [bp-28h],ax
    mov word ptr [bp-26h],dx
    mov ax,word ptr [bp+6]
    mul ax
    mov word ptr [bp-24h],ax
    mov word ptr [bp-22h],dx
    shl ax,1
    rcl dx,1
    mov word ptr [bp-2ch],ax
    mov word ptr [bp-2ah],dx
    mov ax,word ptr cs:[screen_stride]
    mul word ptr [bp+6]
    mov si,ax
    mov di,ax
    mov ax,word ptr [bp+0ah]
    mov bx,word ptr [bp+0ch]
    push cs
    call near ptr u9_098a
    mov ah,1
    shl ah,cl
    mov byte ptr [bp-0eh],ah
    mov byte ptr [bp-10h],ah
    add si,bx
    mov word ptr [bp-6],si
    mov word ptr [bp-8],si
    sub bx,di
    mov word ptr [bp-0ah],bx
    mov word ptr [bp-0ch],bx
    xor ax,ax
    mov word ptr [bp-18h],ax
    mov word ptr [bp-16h],ax
    mov ax,word ptr [bp-28h]
    mov dx,word ptr [bp-26h]
    mov cx,word ptr [bp+6]
    call near ptr u9_1e73
    mov word ptr [bp-1ch],ax
    mov word ptr [bp-1ah],dx
    mov ax,word ptr [bp-20h]
    mov dx,word ptr [bp-1eh]
    sar dx,1
    rcr ax,1
    sar dx,1
    rcr ax,1
    add ax,word ptr [bp-24h]
    adc dx,word ptr [bp-22h]
    mov word ptr [bp-14h],ax
    mov word ptr [bp-12h],dx
    mov ax,word ptr [bp-20h]
    mov dx,word ptr [bp-1eh]
    mov cx,word ptr [bp+6]
    call near ptr u9_1e73
    sub word ptr [bp-14h],ax
    sbb word ptr [bp-12h],dx
    mov bx,word ptr [bp+6]
    xor cx,cx
ellipse_repeat_c5:
    mov ax,word ptr [bp-18h]
    mov dx,word ptr [bp-16h]
    sub ax,word ptr [bp-1ch]
    sbb dx,word ptr [bp-1ah]
    jns ellipse_nonnegative_11a
    call near ptr u9_1e02
    mov cx,1
    cmp word ptr [bp-12h],0
    js ellipse_negative_fa
    mov ch,1
    dec bx
    mov ax,word ptr [bp-1ch]
    mov dx,word ptr [bp-1ah]
    sub ax,word ptr [bp-28h]
    sbb dx,word ptr [bp-26h]
    mov word ptr [bp-1ch],ax
    mov word ptr [bp-1ah],dx
    sub word ptr [bp-14h],ax
    sbb word ptr [bp-12h],dx
ellipse_negative_fa:
    mov ax,word ptr [bp-18h]
    mov dx,word ptr [bp-16h]
    add ax,word ptr [bp-2ch]
    adc dx,word ptr [bp-2ah]
    mov word ptr [bp-18h],ax
    mov word ptr [bp-16h],dx
    add ax,word ptr [bp-24h]
    adc dx,word ptr [bp-22h]
    add word ptr [bp-14h],ax
    adc word ptr [bp-12h],dx
    jmp short ellipse_repeat_c5
ellipse_nonnegative_11a:
    push bx
    push cx
    mov ax,word ptr [bp-20h]
    mov dx,word ptr [bp-1eh]
    sub ax,word ptr [bp-24h]
    sbb dx,word ptr [bp-22h]
    mov bx,ax
    mov cx,dx
    sar dx,1
    rcr ax,1
    add ax,bx
    adc dx,cx
    sub ax,word ptr [bp-18h]
    sbb dx,word ptr [bp-16h]
    sub ax,word ptr [bp-1ch]
    sbb dx,word ptr [bp-1ah]
    sar dx,1
    rcr ax,1
    add word ptr [bp-14h],ax
    adc word ptr [bp-12h],dx
    pop cx
    pop bx
ellipse_repeat_14c:
    call near ptr u9_1e02
    mov cx,100h
    cmp word ptr [bp-12h],0
    jns ellipse_nonnegative_172
    mov cl,1
    mov ax,word ptr [bp-18h]
    mov dx,word ptr [bp-16h]
    add ax,word ptr [bp-2ch]
    adc dx,word ptr [bp-2ah]
    mov word ptr [bp-18h],ax
    mov word ptr [bp-16h],dx
    add word ptr [bp-14h],ax
    adc word ptr [bp-12h],dx
ellipse_nonnegative_172:
    mov ax,word ptr [bp-1ch]
    mov dx,word ptr [bp-1ah]
    sub ax,word ptr [bp-28h]
    sbb dx,word ptr [bp-26h]
    mov word ptr [bp-1ch],ax
    mov word ptr [bp-1ah],dx
    sub ax,word ptr [bp-20h]
    sbb dx,word ptr [bp-1eh]
    sub word ptr [bp-14h],ax
    sbb word ptr [bp-12h],dx
    dec bx
    jns ellipse_repeat_14c
    mov ax,0ff08h
    mov dx,3ceh
    out dx,ax
    mov ax,3
    out dx,ax
    mov ax,1
    out dx,ax
    pop di
    pop si
    mov sp,bp
    pop bp
    retf 8
u9_1c58 endp

; curve symmetric pixel helper
u9_1e02 proc near
    push ax
    push bx
    push dx
    mov dx,3ceh
    xor bx,bx
    test ch,ch
    je curve_pixels_equal_13
    mov bx,word ptr cs:[screen_stride]
    neg bx
curve_pixels_equal_13:
    mov al,8
    xor si,si
    mov ah,byte ptr [bp-0eh]
    rol ah,cl
    rcl si,1
    neg si
    mov di,si
    add si,word ptr [bp-6]
    add si,bx
    add di,word ptr [bp-0ah]
    sub di,bx
    mov byte ptr [bp-0eh],ah
    mov word ptr [bp-6],si
    mov word ptr [bp-0ah],di
    out dx,ax
    mov ch,byte ptr es:[si]
    mov byte ptr es:[si],ch
    mov ch,byte ptr es:[di]
    mov byte ptr es:[di],ch
    xor si,si
    mov ah,byte ptr [bp-10h]
    ror ah,cl
    rcl si,1
    mov di,si
    add si,word ptr [bp-8]
    add si,bx
    add di,word ptr [bp-0ch]
    sub di,bx
    mov byte ptr [bp-10h],ah
    mov word ptr [bp-8],si
    mov word ptr [bp-0ch],di
    out dx,ax
    mov ch,byte ptr es:[si]
    mov byte ptr es:[si],ch
    mov ch,byte ptr es:[di]
    mov byte ptr es:[di],ch
    pop dx
    pop bx
    pop ax
    ret
u9_1e02 endp

; multiply partial products helper
u9_1e73 proc near
    push ax
    mov ax,dx
    mul cx
    xchg cx,ax
    pop dx
    mul dx
    add dx,cx
    ret
u9_1e73 endp

sprite_clip_top        dw 0
sprite_clip_bottom     dw 0
sprite_clip_left       dw 0
sprite_clip_right      dw 0
; blit masked 32x16 clipped
u9_1e87 proc far
    push bp
    mov bp,sp
    push ds
    push di
    push si
    push cx
    mov word ptr cs:[sprite_clip_top],0
    mov word ptr cs:[sprite_clip_bottom],0
    mov word ptr cs:[sprite_clip_left],0
    mov word ptr cs:[sprite_clip_right],0
    mov bx,word ptr [bp+8]
    cmp bx,-4
    jle clip_masked32_le_52
    cmp bx,-3
    je clip_masked32_equal_59
    cmp bx,-2
    je clip_masked32_equal_60
    cmp bx,-1
    je clip_masked32_equal_67
    mov cx,word ptr cs:[screen_stride]
    cmp bx,cx
    jge clip_masked32_le_52
    dec cx
    cmp bx,cx
    je clip_masked32_equal_71
    dec cx
    cmp bx,cx
    je clip_masked32_equal_78
    dec cx
    cmp bx,cx
    je clip_masked32_equal_7f
clip_masked32_le_52:
    mov word ptr cs:[sprite_clip_right],1
clip_masked32_equal_59:
    mov word ptr cs:[sprite_clip_left],1
clip_masked32_equal_60:
    mov word ptr cs:[sprite_clip_bottom],1
clip_masked32_equal_67:
    mov word ptr cs:[sprite_clip_top],1
    jmp short clip_masked32_continue_86
    nop
clip_masked32_equal_71:
    mov word ptr cs:[sprite_clip_bottom],1
clip_masked32_equal_78:
    mov word ptr cs:[sprite_clip_left],1
clip_masked32_equal_7f:
    mov word ptr cs:[sprite_clip_right],1
clip_masked32_continue_86:
    pop cx
    lds si,dword ptr [bp+0ah]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+6]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov bx,word ptr [bp+8]
    add bx,ax
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je clip_masked32_equal_b6
    mov cx,ax
clip_masked32_row_loop_b0:
    add bx,2000h
    loop clip_masked32_row_loop_b0
clip_masked32_equal_b6:
    mov dx,3c4h
    mov al,2
    out dx,al
    mov cx,10h
clip_masked32_repeat_bf:
    mov dx,3ceh
    lodsb
    mov ah,8
    xchg ah,al
    out dx,ax
    mov dx,word ptr cs:[sprite_clip_top]
    cmp dx,1
    je clip_masked32_equal_f4
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    jmp short clip_masked32_right_half
    nop
clip_masked32_equal_f4:
    lodsb
    lodsb
    lodsb
    lodsb
clip_masked32_right_half:
    inc bx
    mov dx,3ceh
    lodsb
    mov ah,8
    xchg ah,al
    out dx,ax
    mov dx,word ptr cs:[sprite_clip_bottom]
    cmp dx,1
    je clip_masked32_equal_12e
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    jmp short clip_masked32_continue_14f
    nop
clip_masked32_equal_12e:
    lodsb
    lodsb
    lodsb
    lodsb
    inc bx
    mov dx,3ceh
    lodsb
    mov ah,8
    xchg ah,al
    out dx,ax
    mov dx,word ptr cs:[sprite_clip_left]
    cmp dx,1
    je clip_masked32_equal_16e
    mov dx,3c5h
    jmp short clip_masked32_continue_14f
    nop
clip_masked32_row_loop_14c:
    jmp near ptr clip_masked32_repeat_bf
clip_masked32_continue_14f:
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    jmp short clip_masked32_tail
    nop
clip_masked32_equal_16e:
    lodsb
    lodsb
    lodsb
    lodsb
clip_masked32_tail:
    inc bx
    mov dx,3ceh
    lodsb
    mov ah,8
    xchg ah,al
    out dx,ax
    mov dx,word ptr cs:[sprite_clip_right]
    cmp dx,1
    je clip_masked32_equal_1a8
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    jmp short clip_masked32_continue_1ac
    nop
clip_masked32_equal_1a8:
    lodsb
    lodsb
    lodsb
    lodsb
clip_masked32_continue_1ac:
    inc bx
    add bx,word ptr cs:[screen_stride]
    dec bx
    dec bx
    dec bx
    dec bx
    loop clip_masked32_row_loop_14c
    mov dx,3c5h
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
u9_1e87 endp

; blit masked 16x16 clipped
u9_2053 proc far
    push bp
    mov bp,sp
    push ds
    push di
    push si
    push cx
    mov word ptr cs:[sprite_clip_top],0
    mov word ptr cs:[sprite_clip_bottom],0
    mov word ptr cs:[sprite_clip_left],0
    mov word ptr cs:[sprite_clip_right],0
    mov bx,word ptr [bp+8]
    cmp bx,-2
    jle clip_masked16_le_3e
    cmp bx,-1
    je clip_masked16_equal_45
    mov cx,word ptr cs:[screen_stride]
    cmp bx,cx
    jge clip_masked16_le_3e
    dec cx
    cmp bx,cx
    je clip_masked16_equal_4f
clip_masked16_le_3e:
    mov word ptr cs:[sprite_clip_right],1
clip_masked16_equal_45:
    mov word ptr cs:[sprite_clip_top],1
    jmp short clip_masked16_continue_56
    nop
clip_masked16_equal_4f:
    mov word ptr cs:[sprite_clip_right],1
clip_masked16_continue_56:
    pop cx
    lds si,dword ptr [bp+0ah]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+6]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov bx,word ptr [bp+8]
    add bx,ax
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je clip_masked16_equal_86
    mov cx,ax
clip_masked16_row_loop_80:
    add bx,2000h
    loop clip_masked16_row_loop_80
clip_masked16_equal_86:
    mov dx,3c4h
    mov al,2
    out dx,al
    mov cx,10h
clip_masked16_row_loop_8f:
    mov dx,3ceh
    lodsb
    mov ah,8
    xchg ah,al
    out dx,ax
    mov dx,word ptr cs:[sprite_clip_top]
    cmp dx,1
    je clip_masked16_equal_c4
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    jmp short clip_masked16_continue_c8
    nop
clip_masked16_equal_c4:
    lodsb
    lodsb
    lodsb
    lodsb
clip_masked16_continue_c8:
    inc bx
    mov dx,3ceh
    lodsb
    mov ah,8
    xchg ah,al
    out dx,ax
    mov dx,word ptr cs:[sprite_clip_bottom]
    cmp dx,1
    je clip_masked16_equal_fe
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    jmp short clip_masked16_continue_102
    nop
clip_masked16_equal_fe:
    lodsb
    lodsb
    lodsb
    lodsb
clip_masked16_continue_102:
    inc bx
    add bx,word ptr cs:[screen_stride]
    dec bx
    dec bx
    loop clip_masked16_row_loop_8f
    mov dx,3c5h
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
u9_2053 endp

; capture planar rectangle variant
u9_2173 proc far
    push bp
    mov bp,sp
    push ds
    push si
    push di
    mov ax,word ptr [bp+8]
    sub ax,word ptr [bp+0ch]
    mov cx,0ff07h
    and cl,al
    xor cl,7
    shl ch,cl
    mov cl,ch
    push cx
    mov cl,3
    shr ax,cl
    inc ax
    push ax
    mov ax,word ptr [bp+6]
    sub ax,word ptr [bp+0ah]
    inc ax
    push ax
    mov ax,word ptr [bp+0ah]
    mov bx,word ptr [bp+0ch]
    push cs
    call near ptr u9_098a
    xor cl,7
    push es
    pop ds
    mov si,bx
    les di,dword ptr [bp+0eh]
    pop ax
    mov word ptr cs:[transfer_width],ax
    stosw
    pop ax
    mov word ptr cs:[transfer_height],ax
    stosw
    pop ax
    mov ch,al
    stosb
    mov dx,3ceh
    mov ax,5
    out dx,ax
    mov ax,304h
capture_b_repeat_55:
    out dx,ax
    push ax
    push word ptr cs:[transfer_width]
    push si
capture_b_repeat_5d:
    mov bx,word ptr cs:[transfer_height]
    push si
capture_b_repeat_63:
    lodsw
    dec si
    rol ax,cl
    stosb
    dec bx
    jne capture_b_repeat_63
    and byte ptr es:[di-1],ch
    pop si
    add si,word ptr cs:[screen_stride]
    dec word ptr cs:[transfer_width]
    jne capture_b_repeat_5d
    pop si
    pop word ptr cs:[transfer_width]
    pop ax
    dec ah
    jns capture_b_repeat_55
    mov ax,di
    sub ax,word ptr [bp+0eh]
    pop di
    pop si
    pop ds
    mov sp,bp
    pop bp
    retf 0ch
u9_2173 endp

; restore planar rectangle variant
u9_2208 proc far
    push bp
    mov bp,sp
    push ds
    push si
    push di
    mov ax,word ptr [bp+6]
    mov bx,word ptr [bp+8]
    push cs
    call near ptr u9_098a
    inc cl
    and cl,7
    mov di,bx
    lds si,dword ptr [bp+0ah]
    lodsw
    mov word ptr cs:[transfer_width],ax
    lodsw
    mov word ptr cs:[transfer_height],ax
    lodsb
    mov ch,al
    mov dx,3ceh
    mov ah,18h
    mov al,3
    out dx,ax
    mov ax,805h
    out dx,ax
    mov ax,7
    out dx,ax
    mov ax,0ff08h
    out dx,ax
    mov al,3
    mov dx,3ceh
    out dx,al
    mov al,0
    inc dx
    out dx,al
    mov dl,0c4h
    mov ax,802h
    cmp cx,0ff00h
    jne restore_b_different_79
    mov cx,word ptr cs:[transfer_height]
restore_b_repeat_55:
    out dx,ax
    push ax
    push di
    mov bx,word ptr cs:[transfer_width]
restore_b_repeat_5d:
    push di
    push cx
restore_b_loop_5f:
    lodsb
    and byte ptr es:[di],al
    inc di
    loop restore_b_loop_5f
    pop cx
    pop di
    add di,word ptr cs:[screen_stride]
    dec bx
    jne restore_b_repeat_5d
    pop di
    pop ax
    shr ah,1
    jne restore_b_repeat_55
    jmp near ptr restore_b_continue_113
restore_b_different_79:
    push ax
    mov bx,0ffh
    mov al,ch
    cbw
    cmp word ptr cs:[transfer_height],1
    jne restore_b_different_8e
    mov bl,ch
    mov ah,ch
    xor al,al
restore_b_different_8e:
    shl ax,cl
    shl bx,cl
    mov bl,al
    mov al,8
    mov word ptr cs:[transfer_x_start],ax
    mov ah,bl
    mov word ptr cs:[transfer_y_start],ax
    mov ah,bh
    mov word ptr cs:[transfer_y_end],ax
    mov bx,word ptr cs:[transfer_height]
    pop ax
restore_b_repeat_ac:
    out dx,ax
    push ax
    push di
    mov dl,0ceh
    mov ax,word ptr cs:[transfer_width]
    mov word ptr cs:[transfer_x_end],ax
restore_b_repeat_b9:
    push di
    push si
    push bx
    mov ax,word ptr cs:[transfer_y_end]
    out dx,ax
    lodsw
    dec si
    test cl,cl
    jne restore_b_different_cc
    dec bx
    jne restore_b_different_d3
    jmp short restore_b_continue_e7
restore_b_different_cc:
    rol ax,cl
    and byte ptr es:[di],ah
    inc di
    dec bx
restore_b_different_d3:
    push ax
    mov ax,0ff08h
    out dx,ax
    pop ax
    dec bx
    jle restore_b_continue_e7
restore_b_repeat_dc:
    and byte ptr es:[di],al
    inc di
    lodsw
    dec si
    rol ax,cl
    dec bx
    jne restore_b_repeat_dc
restore_b_continue_e7:
    mov bx,ax
    mov ax,word ptr cs:[transfer_x_start]
    out dx,ax
    and byte ptr es:[di],bl
    mov ax,word ptr cs:[transfer_y_start]
    out dx,ax
    and byte ptr es:[di+1],bh
    pop bx
    pop si
    add si,bx
    pop di
    add di,word ptr cs:[screen_stride]
    dec word ptr cs:[transfer_x_end]
    jne restore_b_repeat_b9
    pop di
    pop ax
    mov dl,0c4h
    shr ah,1
    jne restore_b_repeat_ac
restore_b_continue_113:
    mov ax,0f02h
    out dx,ax
    mov dl,0ceh
    mov ax,3
    out dx,ax
    mov ax,5
    out dx,ax
    mov ax,0f07h
    out dx,ax
    mov ax,0ff08h
    out dx,ax
    pop di
    pop si
    pop ds
    mov sp,bp
    pop bp
    retf 8
u9_2208 endp

; blit opaque shifted sprite variant a
u9_233a proc far
    push bp
    mov bp,sp
    push ds
    push si
    push di
    lds si,dword ptr [bp+0ah]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+6]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov bx,word ptr [bp+8]
    mov cl,3
    shr bx,cl
    add bx,ax
    mov ax,word ptr [bp+8]
    and ax,7
    mov byte ptr cs:[sprite_unshift],al
    mov al,8
    sub al,byte ptr cs:[sprite_unshift]
    mov byte ptr cs:[sprite_mask_left],al
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je opaque_shift_equal_4e
    mov cx,ax
opaque_shift_row_loop_48:
    add bx,2000h
    loop opaque_shift_row_loop_48
opaque_shift_equal_4e:
    mov dx,3c4h
    mov al,2
    out dx,al
    mov dx,3c5h
    mov al,0fh
    out dx,al
    mov cx,10h
opaque_shift_repeat_5d:
    mov byte ptr cs:[sprite_shift],4
opaque_shift_repeat_63:
    mov dl,byte ptr cs:[sprite_shift]
    dec dl
    mov byte ptr cs:[sprite_shift],dl
    push cx
    mov dx,3ceh
    lodsb
    mov byte ptr cs:[sprite_mask_right],al
    mov ah,byte ptr cs:[sprite_mask_right]
    mov cl,byte ptr cs:[sprite_unshift]
    shr ah,cl
    mov al,8
    out dx,ax
    lodsb
    mov byte ptr cs:[sprite_rows],al
    shr al,cl
    mov di,word ptr es:[bx]
    or byte ptr es:[bx],al
    lodsb
    mov byte ptr cs:[sprite_plane1],al
    shr al,cl
    mov di,word ptr es:[bx]
    or byte ptr es:[bx],al
    lodsb
    mov byte ptr cs:[sprite_plane2],al
    shr al,cl
    mov di,word ptr es:[bx]
    or byte ptr es:[bx],al
    lodsb
    mov byte ptr cs:[sprite_plane3],al
    shr al,cl
    mov di,word ptr es:[bx]
    or byte ptr es:[bx],al
    jmp short opaque_shift_continue_c2
    nop
opaque_shift_row_loop_be:
    jmp short opaque_shift_repeat_5d
opaque_shift_repeat_c0:
    jmp short opaque_shift_repeat_63
opaque_shift_continue_c2:
    inc bx
    mov dx,3ceh
    mov ah,byte ptr cs:[sprite_mask_right]
    mov cl,byte ptr cs:[sprite_mask_left]
    shl ah,cl
    mov al,8
    out dx,ax
    mov al,byte ptr cs:[sprite_rows]
    shl al,cl
    mov di,word ptr es:[bx]
    or byte ptr es:[bx],al
    mov al,byte ptr cs:[sprite_plane1]
    shl al,cl
    mov di,word ptr es:[bx]
    or byte ptr es:[bx],al
    mov al,byte ptr cs:[sprite_plane2]
    shl al,cl
    mov di,word ptr es:[bx]
    or byte ptr es:[bx],al
    mov al,byte ptr cs:[sprite_plane3]
    shl al,cl
    mov di,word ptr es:[bx]
    or byte ptr es:[bx],al
    pop cx
    mov dl,byte ptr cs:[sprite_shift]
    cmp dl,0
    jg opaque_shift_repeat_c0
    add bx,word ptr cs:[screen_stride]
    dec bx
    dec bx
    dec bx
    dec bx
    loop opaque_shift_row_loop_be
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop di
    pop si
    pop ds
    pop bp
    retf 8
u9_233a endp

; blit opaque shifted 16x16
u9_2463 proc far
    push bp
    mov bp,sp
    push ds
    push si
    push di
    mov di,word ptr cs:[screen_stride]
    dec di
    dec di
    lds si,dword ptr [bp+0ah]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+6]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov bx,word ptr [bp+8]
    mov cl,3
    shr bx,cl
    add bx,ax
    mov ax,word ptr [bp+8]
    and ax,7
    mov byte ptr cs:[sprite_unshift],al
    mov al,8
    sub al,byte ptr cs:[sprite_unshift]
    mov byte ptr cs:[sprite_mask_left],al
    mov dx,3c4h
    mov al,2
    out dx,al
    mov cx,10h
opaque_shift16_repeat_4e:
    mov byte ptr cs:[sprite_shift],2
opaque_shift16_repeat_54:
    mov dl,byte ptr cs:[sprite_shift]
    dec dl
    mov byte ptr cs:[sprite_shift],dl
    push cx
    mov dx,3ceh
    lodsb
    mov byte ptr cs:[sprite_mask_right],al
    mov ah,byte ptr cs:[sprite_mask_right]
    mov cl,byte ptr cs:[sprite_unshift]
    shr ah,cl
    mov al,8
    out dx,ax
    mov dx,3c5h
    mov al,0fh
    out dx,al
    lodsb
    mov byte ptr cs:[sprite_rows],al
    shr al,cl
    mov ah,byte ptr es:[bx]
    or byte ptr es:[bx],al
    mov al,0fh
    out dx,al
    lodsb
    mov byte ptr cs:[sprite_plane1],al
    shr al,cl
    mov ah,byte ptr es:[bx]
    or byte ptr es:[bx],al
    mov al,0fh
    out dx,al
    lodsb
    mov byte ptr cs:[sprite_plane2],al
    shr al,cl
    mov ah,byte ptr es:[bx]
    or byte ptr es:[bx],al
    mov al,0fh
    out dx,al
    lodsb
    mov byte ptr cs:[sprite_plane3],al
    shr al,cl
    mov ah,byte ptr es:[bx]
    or byte ptr es:[bx],al
    jmp short opaque_shift16_continue_c2
    nop
opaque_shift16_row_loop_be:
    jmp short opaque_shift16_repeat_4e
opaque_shift16_repeat_c0:
    jmp short opaque_shift16_repeat_54
opaque_shift16_continue_c2:
    inc bx
    mov dx,3ceh
    mov ah,byte ptr cs:[sprite_mask_right]
    mov cl,byte ptr cs:[sprite_mask_left]
    shl ah,cl
    mov al,8
    out dx,ax
    mov dx,3c5h
    mov al,0fh
    out dx,al
    mov al,byte ptr cs:[sprite_rows]
    shl al,cl
    mov ah,byte ptr es:[bx]
    or byte ptr es:[bx],al
    mov al,0fh
    out dx,al
    mov al,byte ptr cs:[sprite_plane1]
    shl al,cl
    mov ah,byte ptr es:[bx]
    or byte ptr es:[bx],al
    mov al,0fh
    out dx,al
    mov al,byte ptr cs:[sprite_plane2]
    shl al,cl
    mov ah,byte ptr es:[bx]
    or byte ptr es:[bx],al
    mov al,0fh
    out dx,al
    mov al,byte ptr cs:[sprite_plane3]
    shl al,cl
    mov ah,byte ptr es:[bx]
    or byte ptr es:[bx],al
    pop cx
    mov dl,byte ptr cs:[sprite_shift]
    cmp dl,0
    jg opaque_shift16_repeat_c0
    add bx,di
    loop opaque_shift16_row_loop_be
    mov dx,3c5h
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop di
    pop si
    pop ds
    pop bp
    retf 8
u9_2463 endp

; blit opaque variable sprite
u9_259a proc far
    push bp
    mov bp,sp
    push ds
    push di
    push si
    lds si,dword ptr [bp+0ah]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+6]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov cx,word ptr [bp+8]
    and cx,7
    xor cl,7
    inc cl
    mov byte ptr cs:[sprite_stride],cl
    mov bx,word ptr [bp+8]
    shr bx,1
    shr bx,1
    shr bx,1
    add bx,ax
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je opaque_var_equal_4b
    mov cx,ax
opaque_var_row_loop_45:
    add bx,2000h
    loop opaque_var_row_loop_45
opaque_var_equal_4b:
    mov dx,3c4h
    mov al,2
    out dx,al
    mov cx,8
    mov dx,3c5h
    mov al,0fh
    out dx,al
opaque_var_repeat_5a:
    push cx
    lodsb
    mov ah,0
    mov cl,byte ptr cs:[sprite_stride]
    rol ax,cl
    mov byte ptr cs:[sprite_width],ah
    mov byte ptr cs:[sprite_height],al
    lodsb
    mov ah,0
    mov cl,byte ptr cs:[sprite_stride]
    rol ax,cl
    mov cx,ax
    mov dx,3ceh
    mov al,8
    mov ah,byte ptr cs:[sprite_width]
    out dx,ax
    mov di,word ptr es:[bx]
    or byte ptr es:[bx],ch
    mov ah,byte ptr cs:[sprite_height]
    out dx,ax
    mov di,word ptr es:[bx+1]
    or byte ptr es:[bx+1],cl
    lodsb
    mov ah,0
    mov cl,byte ptr cs:[sprite_stride]
    rol ax,cl
    mov cx,ax
    mov dx,3ceh
    mov al,8
    mov ah,byte ptr cs:[sprite_width]
    out dx,ax
    mov di,word ptr es:[bx]
    or byte ptr es:[bx],ch
    mov ah,byte ptr cs:[sprite_height]
    out dx,ax
    mov di,word ptr es:[bx+1]
    or byte ptr es:[bx+1],cl
    jmp short opaque_var_continue_c9
    nop
opaque_var_row_loop_c7:
    jmp short opaque_var_repeat_5a
opaque_var_continue_c9:
    lodsb
    mov ah,0
    mov cl,byte ptr cs:[sprite_stride]
    rol ax,cl
    mov cx,ax
    mov dx,3ceh
    mov al,8
    mov ah,byte ptr cs:[sprite_width]
    out dx,ax
    mov di,word ptr es:[bx]
    or byte ptr es:[bx],ch
    mov ah,byte ptr cs:[sprite_height]
    out dx,ax
    mov di,word ptr es:[bx+1]
    or byte ptr es:[bx+1],cl
    lodsb
    mov ah,0
    mov cl,byte ptr cs:[sprite_stride]
    rol ax,cl
    mov cx,ax
    mov dx,3ceh
    mov al,8
    mov ah,byte ptr cs:[sprite_width]
    out dx,ax
    mov di,word ptr es:[bx]
    or byte ptr es:[bx],ch
    mov ah,byte ptr cs:[sprite_height]
    out dx,ax
    mov di,word ptr es:[bx+1]
    or byte ptr es:[bx+1],cl
    add bx,word ptr cs:[screen_stride]
    pop cx
    loop opaque_var_row_loop_c7
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
u9_259a endp

font_offset            dw ?
font_segment           dw ?
font_height            dw ?
font_default_offset    dw 0
font_default_height    dw 8
rom8_offset            dw ?
rom8_segment           dw ?
rom8_height            dw 8
rom14_offset           dw ?
rom14_segment          dw ?
rom14_height           dw 14
font_work3             dw ?
text_direction         dw 0
; draw pascal string
; PUSH DS precedes BP: arguments start at BP+8.
u9_26e9 proc far
    push ds
    push bp
    mov bp,sp
    sub sp,4
    push di
    push si
    call near ptr text_get_cs_base
text_get_cs_base:
    pop ax
    sub ax,offset text_get_cs_base
    mov word ptr cs:[text_cs_base],ax
    mov word ptr cs:[text_char_index],0
text_repeat_1b:
    inc word ptr cs:[text_char_index]
    les bx,dword ptr [bp+0ch]
    mov al,byte ptr es:[bx]
    xor ah,ah
    cmp word ptr cs:[text_char_index],ax
    jbe text_branch_32
    jmp near ptr text_continue_f0
text_branch_32:
    add bx,word ptr cs:[text_char_index]
    mov al,byte ptr es:[bx]
    xor ah,ah
    mov word ptr cs:[text_char_code],ax
    mov ax,word ptr cs:[font_height]
    mov word ptr cs:[font_rows],ax
    mul word ptr cs:[text_char_code]
    mov si,word ptr cs:[font_offset]
    mov bx,word ptr cs:[font_segment]
    push bx
    pop ds
    add si,ax
    mov word ptr cs:[glyph_offset],si
    mov word ptr cs:[glyph_segment],ds
    mov word ptr cs:[font_row_index],1
text_repeat_6c:
    mov ax,word ptr [bp+0ah]
    mov word ptr cs:[text_x],ax
    mov ax,word ptr [bp+8]
    mov word ptr cs:[text_y],ax
    lds si,dword ptr cs:[glyph_offset]
    inc word ptr cs:[glyph_offset]
    mov dl,byte ptr [si]
    xor dh,dh
    mov ax,word ptr cs:[text_direction]
    cmp ax,0
    jne text_different_99
    call near ptr u9_2829
    inc word ptr [bp+8]
    jmp short text_continue_ad
text_different_99:
    call near ptr u9_28a7
    mov ax,word ptr cs:[text_direction]
    cmp ax,1
    jne text_different_aa
    inc word ptr [bp+0ah]
    jmp short text_continue_ad
text_different_aa:
    dec word ptr [bp+0ah]
text_continue_ad:
    inc word ptr cs:[font_row_index]
    mov ax,word ptr cs:[font_row_index]
    cmp ax,word ptr cs:[font_rows]
    ja text_branch_bf
    jmp short text_repeat_6c
text_branch_bf:
    mov ax,word ptr cs:[text_direction]
    mov bx,8
    mov cx,word ptr cs:[font_rows]
    cmp ax,0
    jne text_different_d9
    add word ptr [bp+0ah],bx
    sub word ptr [bp+8],cx
    jmp near ptr text_repeat_1b
text_different_d9:
    cmp ax,1
    jne text_different_e7
    sub word ptr [bp+8],bx
    sub word ptr [bp+0ah],cx
    jmp near ptr text_repeat_1b
text_different_e7:
    add word ptr [bp+8],bx
    add word ptr [bp+0ah],cx
    jmp near ptr text_repeat_1b
text_continue_f0:
    pop si
    pop di
    mov sp,bp
    pop bp
    pop ds
    retf 8
u9_26e9 endp

; initialize rom fonts
u9_27e2 proc far
    push bp
    mov bp,sp
    push di
    push si
    push ds
    push es
    push cs
    pop ds
    push bp
    mov ax,1130h
    mov bx,200h
    int 10h
    mov ax,bp
    pop bp
    mov word ptr cs:[rom14_offset],ax
    mov word ptr cs:[rom14_segment],es
    mov word ptr cs:[rom14_height],0eh
    push bp
    mov ax,1130h
    mov bx,300h
    int 10h
    mov ax,bp
    pop bp
    mov word ptr cs:[rom8_offset],ax
    mov word ptr cs:[rom8_segment],es
    mov word ptr cs:[rom8_height],8
    pop es
    pop ds
    pop si
    pop di
    pop bp
    retf
u9_27e2 endp

; draw font row horizontal helper
u9_2829 proc near
    mov ax,word ptr cs:[text_x]
    and ax,7
    mov si,ax
    mov cx,ax
    ror dl,cl
    xor dh,dh
    add si,word ptr cs:[text_cs_base]
    mov al,byte ptr cs:[si+left_masks]
    mov cx,ax
    and cx,dx
    mov word ptr cs:[glyph_left],cx
    not ax
    and ax,dx
    mov word ptr cs:[glyph_right],ax
    mov ax,word ptr cs:[text_x]
    mov word ptr cs:[font_pixel_x],ax
    mov ax,word ptr cs:[text_y]
    mov word ptr cs:[font_pixel_y],ax
    call near ptr u9_2908
    mov ax,word ptr cs:[draw_color]
    mov bx,0fh
    call near ptr u9_28f1
    mov al,byte ptr cs:[draw_operation]
    mov ah,0
    call near ptr u9_28ff
    mov ax,word ptr cs:[glyph_left]
    call near ptr u9_28e8
    mov al,byte ptr es:[di]
    mov byte ptr es:[di],al
    inc di
    mov ax,word ptr cs:[glyph_right]
    call near ptr u9_28e8
    mov al,byte ptr es:[di]
    mov byte ptr es:[di],al
    mov ax,0ffh
    call near ptr u9_28e8
    xor ax,ax
    xor bx,bx
    call near ptr u9_28f1
    xor ax,ax
    call near ptr u9_28ff
    ret
u9_2829 endp

; draw font row vertical helper
u9_28a7 proc near
    mov ax,word ptr cs:[text_x]
    mov word ptr cs:[font_pixel_x],ax
    mov ax,word ptr cs:[text_y]
    add ax,8
    mov word ptr cs:[font_pixel_y],ax
    mov cx,8
    mov bx,80h
font_vrow_loop_19:
    mov ax,dx
    and ax,bx
    je font_vrow_equal_28
    push dx
    push bx
    push cx
    call near ptr u9_2936
    pop cx
    pop bx
    pop dx
font_vrow_equal_28:
    shr bx,1
    cmp word ptr cs:[text_direction],1
    jne font_vrow_different_39
    dec word ptr cs:[font_pixel_y]
    jmp short font_vrow_continue_3e
font_vrow_different_39:
    inc word ptr cs:[font_pixel_y]
font_vrow_continue_3e:
    loop font_vrow_loop_19
    ret
u9_28a7 endp

; set ega bit mask helper
u9_28e8 proc near
    mov ah,al
    mov al,8
    mov dx,3ceh
    out dx,ax
    ret
u9_28e8 endp

; set ega set reset helper
u9_28f1 proc near
    mov ah,al
    mov al,0
    mov dx,3ceh
    out dx,ax
    mov ah,bl
    mov al,1
    out dx,ax
    ret
u9_28f1 endp

; set ega data rotate helper
u9_28ff proc near
    mov ah,al
    mov al,3
    mov dx,3ceh
    out dx,ax
    ret
u9_28ff endp

; font pixel address helper
u9_2908 proc near
    mov ax,word ptr cs:[font_pixel_y]
    mov cx,word ptr cs:[screen_stride]
    mul cx
    mov bx,word ptr cs:[font_pixel_x]
    mov cx,3
    shr bx,cl
    add ax,bx
    mov di,ax
    mov cx,word ptr cs:[draw_page]
    mov ax,0a000h
    cmp cx,0
    je font_address_equal_2b
font_address_loop_26:
    add ax,2000h
    loop font_address_loop_26
font_address_equal_2b:
    mov es,ax
    ret
u9_2908 endp

; draw font pixel helper
u9_2936 proc near
    call near ptr u9_2908
    mov ax,word ptr cs:[font_pixel_x]
    and ax,7
    mov bx,word ptr cs:[text_cs_base]
    add bx,ax
    mov ah,byte ptr cs:[bx+pixel_masks]
    mov al,8
    mov dx,3ceh
    out dx,ax
    mov al,byte ptr cs:[draw_operation]
    mov ah,0
    mov ah,al
    mov al,3
    out dx,ax
    mov ax,word ptr cs:[draw_color]
    mov bx,0fh
    call near ptr u9_28f1
    mov ch,byte ptr es:[di]
    mov byte ptr es:[di],0ffh
    xor ax,ax
    call near ptr u9_28ff
    xor ax,ax
    xor bx,bx
    call near ptr u9_28f1
    mov ax,0ffh
    call near ptr u9_28e8
    ret
u9_2936 endp

; select rom font
u9_2981 proc far
    push bp
    mov bp,sp
    mov ax,word ptr [bp+6]
    cmp ax,1
    je selectfont_equal_26
    mov ax,word ptr cs:[rom14_offset]
    mov word ptr cs:[font_offset],ax
    mov ax,word ptr cs:[rom14_segment]
    mov word ptr cs:[font_segment],ax
    mov ax,word ptr cs:[rom14_height]
    mov word ptr cs:[font_height],ax
    jmp short selectfont_continue_3e
    nop
selectfont_equal_26:
    mov ax,word ptr cs:[rom8_offset]
    mov word ptr cs:[font_offset],ax
    mov ax,word ptr cs:[rom8_segment]
    mov word ptr cs:[font_segment],ax
    mov ax,word ptr cs:[rom8_height]
    mov word ptr cs:[font_height],ax
selectfont_continue_3e:
    pop bp
    retf 2
u9_2981 endp

; blit opaque 32x16
u9_29c3 proc far
    push bp
    mov bp,sp
    push ds
    push di
    push si
    mov di,word ptr cs:[screen_stride]
    dec di
    dec di
    dec di
    dec di
    lds si,dword ptr [bp+0ah]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+6]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov bx,word ptr [bp+8]
    add bx,ax
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je opaque32_equal_3e
    mov cx,ax
opaque32_row_loop_38:
    add bx,2000h
    loop opaque32_row_loop_38
opaque32_equal_3e:
    mov dx,3c4h
    mov al,2
    out dx,al
    mov cx,10h
opaque32_repeat_47:
    lodsb
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    inc bx
    lodsb
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    jmp short opaque32_continue_8a
    nop
opaque32_row_loop_88:
    jmp short opaque32_repeat_47
opaque32_continue_8a:
    inc bx
    lodsb
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    inc bx
    lodsb
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    inc bx
    add bx,di
    loop opaque32_row_loop_88
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
u9_29c3 endp

; blit opaque 16x16
u9_2a9f proc far
    push bp
    mov bp,sp
    push ds
    push di
    push si
    mov di,word ptr cs:[screen_stride]
    dec di
    dec di
    lds si,dword ptr [bp+0ah]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+6]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov bx,word ptr [bp+8]
    add bx,ax
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je opaque16_equal_3c
    mov cx,ax
opaque16_row_loop_36:
    add bx,2000h
    loop opaque16_row_loop_36
opaque16_equal_3c:
    mov dx,3c4h
    mov al,2
    out dx,al
    mov cx,10h
opaque16_row_loop_45:
    lodsb
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    inc bx
    lodsb
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    inc bx
    add bx,di
    loop opaque16_row_loop_45
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
u9_2a9f endp

; blit opaque 8x8
u9_2b38 proc far
    push bp
    mov bp,sp
    push ds
    push di
    push si
    mov di,word ptr cs:[screen_stride]
    lds si,dword ptr [bp+0ah]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+8]
    mov dx,word ptr cs:[draw_page]
    cmp dl,0
    je opaque8_equal_28
    mov cx,ax
opaque8_row_loop_22:
    add bx,2000h
    loop opaque8_row_loop_22
opaque8_equal_28:
    mov dx,word ptr [bp+6]
    push di
    push ax
    mov ax,dx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    add bx,ax
    mov dx,3c4h
    mov al,2
    out dx,al
    mov cx,8
opaque8_row_loop_45:
    lodsb
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    add bx,di
    loop opaque8_row_loop_45
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
u9_2b38 endp

; blit opaque 32x16 clipped
u9_2bb2 proc far
    push bp
    mov bp,sp
    push ds
    push di
    push si
    push cx
    mov word ptr cs:[sprite_clip_top],0
    mov word ptr cs:[sprite_clip_bottom],0
    mov word ptr cs:[sprite_clip_left],0
    mov word ptr cs:[sprite_clip_right],0
    mov bx,word ptr [bp+8]
    cmp bx,-4
    jle clip_opaque32_le_52
    cmp bx,-3
    je clip_opaque32_equal_59
    cmp bx,-2
    je clip_opaque32_equal_60
    cmp bx,-1
    je clip_opaque32_equal_67
    mov cx,word ptr cs:[screen_stride]
    cmp bx,cx
    jge clip_opaque32_le_52
    dec cx
    cmp bx,cx
    je clip_opaque32_equal_71
    dec cx
    cmp bx,cx
    je clip_opaque32_equal_78
    dec cx
    cmp bx,cx
    je clip_opaque32_equal_7f
clip_opaque32_le_52:
    mov word ptr cs:[sprite_clip_right],1
clip_opaque32_equal_59:
    mov word ptr cs:[sprite_clip_left],1
clip_opaque32_equal_60:
    mov word ptr cs:[sprite_clip_bottom],1
clip_opaque32_equal_67:
    mov word ptr cs:[sprite_clip_top],1
    jmp short clip_opaque32_continue_86
    nop
clip_opaque32_equal_71:
    mov word ptr cs:[sprite_clip_bottom],1
clip_opaque32_equal_78:
    mov word ptr cs:[sprite_clip_left],1
clip_opaque32_equal_7f:
    mov word ptr cs:[sprite_clip_right],1
clip_opaque32_continue_86:
    pop cx
    lds si,dword ptr [bp+0ah]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+6]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov bx,word ptr [bp+8]
    add bx,ax
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je clip_opaque32_equal_b6
    mov cx,ax
clip_opaque32_row_loop_b0:
    add bx,2000h
    loop clip_opaque32_row_loop_b0
clip_opaque32_equal_b6:
    mov dx,3c4h
    mov al,2
    out dx,al
    mov cx,10h
clip_opaque32_repeat_bf:
    lodsb
    mov dx,word ptr cs:[sprite_clip_top]
    cmp dx,1
    je clip_opaque32_equal_ec
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    jmp near ptr clip_masked32_right_half
clip_opaque32_equal_ec:
    lodsb
    lodsb
    lodsb
    lodsb
    inc bx
    lodsb
    mov dx,word ptr cs:[sprite_clip_bottom]
    cmp dx,1
    je clip_opaque32_equal_11e
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    jmp short clip_opaque32_continue_136
    nop
clip_opaque32_equal_11e:
    lodsb
    lodsb
    lodsb
    lodsb
    inc bx
    lodsb
    mov dx,word ptr cs:[sprite_clip_left]
    cmp dx,1
    je clip_opaque32_equal_155
    mov dx,3c5h
    jmp short clip_opaque32_continue_136
    nop
clip_opaque32_row_loop_134:
    jmp short clip_opaque32_repeat_bf
clip_opaque32_continue_136:
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    jmp near ptr clip_masked32_tail
clip_opaque32_equal_155:
    lodsb
    lodsb
    lodsb
    lodsb
    inc bx
    lodsb
    mov dx,word ptr cs:[sprite_clip_right]
    cmp dx,1
    je clip_opaque32_equal_187
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    jmp short clip_opaque32_continue_18b
    nop
clip_opaque32_equal_187:
    lodsb
    lodsb
    lodsb
    lodsb
clip_opaque32_continue_18b:
    inc bx
    add bx,word ptr cs:[screen_stride]
    dec bx
    dec bx
    dec bx
    dec bx
    loop clip_opaque32_row_loop_134
    mov dx,3c5h
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
u9_2bb2 endp

; blit opaque 16x16 clipped
u9_2d5d proc far
    push bp
    mov bp,sp
    push ds
    push di
    push si
    push cx
    mov word ptr cs:[sprite_clip_top],0
    mov word ptr cs:[sprite_clip_bottom],0
    mov word ptr cs:[sprite_clip_left],0
    mov word ptr cs:[sprite_clip_right],0
    mov bx,word ptr [bp+8]
    cmp bx,-2
    jle clip_opaque16_le_3e
    cmp bx,-1
    je clip_opaque16_equal_45
    mov cx,word ptr cs:[screen_stride]
    cmp bx,cx
    jge clip_opaque16_le_3e
    dec cx
    cmp bx,cx
    je clip_opaque16_equal_4f
clip_opaque16_le_3e:
    mov word ptr cs:[sprite_clip_right],1
clip_opaque16_equal_45:
    mov word ptr cs:[sprite_clip_top],1
    jmp short clip_opaque16_continue_56
    nop
clip_opaque16_equal_4f:
    mov word ptr cs:[sprite_clip_right],1
clip_opaque16_continue_56:
    pop cx
    lds si,dword ptr [bp+0ah]
    mov dx,0a000h
    mov es,dx
    mov bx,word ptr [bp+6]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov bx,word ptr [bp+8]
    add bx,ax
    mov ax,word ptr cs:[draw_page]
    cmp al,0
    je clip_opaque16_equal_86
    mov cx,ax
clip_opaque16_row_loop_80:
    add bx,2000h
    loop clip_opaque16_row_loop_80
clip_opaque16_equal_86:
    mov dx,3c4h
    mov al,2
    out dx,al
    mov cx,10h
clip_opaque16_row_loop_8f:
    lodsb
    mov dx,word ptr cs:[sprite_clip_top]
    cmp dx,1
    je clip_opaque16_equal_bc
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    jmp short clip_opaque16_continue_c0
    nop
clip_opaque16_equal_bc:
    lodsb
    lodsb
    lodsb
    lodsb
clip_opaque16_continue_c0:
    inc bx
    lodsb
    mov dx,word ptr cs:[sprite_clip_bottom]
    cmp dx,1
    je clip_opaque16_equal_ee
    mov dx,3c5h
    mov al,1
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,2
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,4
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    mov al,8
    out dx,al
    lodsb
    xchg byte ptr es:[bx],al
    jmp short clip_opaque16_continue_f2
    nop
clip_opaque16_equal_ee:
    lodsb
    lodsb
    lodsb
    lodsb
clip_opaque16_continue_f2:
    inc bx
    add bx,word ptr cs:[screen_stride]
    dec bx
    dec bx
    loop clip_opaque16_row_loop_8f
    mov dx,3c5h
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov ax,0ff08h
    out dx,ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
u9_2d5d endp

; copy cached video tile 16x16
u9_2e6d proc far
    push bp
    mov bp,sp
    push si
    push di
    push ds
    mov dx,0a000h
    mov es,dx
    mov ds,dx
    mov si,word ptr [bp+6]
    shl si,1
    or si,0fa00h
    mov bx,word ptr [bp+8]
    push di
    push ax
    mov ax,bx
    mul word ptr cs:[screen_stride]
    mov di,ax
    pop ax
    mov ax,di
    pop di
    mov di,word ptr [bp+0ah]
    add di,ax
    mov dx,3c5h
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov al,5
    out dx,al
    inc dx
    mov al,1
    out dx,al
    mov cx,1
    mov dl,10h
    mov ax,word ptr cs:[screen_stride]
    dec ax
    dec ax
cache_copy_repeat_48:
    movsb
    movsb
    add si,ax
    add di,ax
    dec dl
    cmp dl,0
    jg cache_copy_repeat_48
    mov dx,3cfh
    mov al,0
    out dx,al
    pop ds
    pop di
    pop si
    pop bp
    retf 6
u9_2e6d endp

; copy video screen region 320x200
u9_2ecf proc far
    push bp
    mov bp,sp
    push si
    push di
    push ds
    mov dx,0a000h
    mov es,dx
    mov ds,dx
    mov ax,word ptr [bp+0ah]
    mul word ptr cs:[screen_stride]
    mov si,word ptr [bp+0ch]
    add si,ax
    mov ax,word ptr [bp+6]
    mul word ptr cs:[screen_stride]
    mov di,word ptr [bp+8]
    add di,ax
    mov dx,3c4h
    mov al,2
    out dx,al
    mov dx,3c5h
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov al,5
    out dx,al
    inc dx
    mov al,1
    out dx,al
    mov ax,word ptr cs:[screen_stride]
    sub ax,28h
    mov bx,0c8h
screen_copy_repeat_47:
    mov cx,28h
    rep movsb
    add si,ax
    add di,ax
    dec bx
    cmp bx,0
    jg screen_copy_repeat_47
    mov dx,3cfh
    mov al,0
    out dx,al
    pop ds
    pop di
    pop si
    pop bp
    retf 8
u9_2ecf endp

; copy video band 320x8
u9_2f32 proc far
    push bp
    mov bp,sp
    push si
    push di
    push ds
    mov dx,0a000h
    mov es,dx
    mov ds,dx
    mov si,28h
    mov di,0
    mov dx,3c4h
    mov al,2
    out dx,al
    mov dx,3c5h
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov al,5
    out dx,al
    inc dx
    mov al,1
    out dx,al
    mov ax,28h
    mov bx,8
band_copy_repeat_2f:
    mov cx,28h
    rep movsb
    add si,ax
    add di,ax
    dec bx
    cmp bx,0
    jg band_copy_repeat_2f
    mov dx,3cfh
    mov al,0
    out dx,al
    pop ds
    pop di
    pop si
    pop bp
    retf
u9_2f32 endp

; copy video tile 16x16 unused cdecl
; Active caller-cleanup RETF, then unreachable Pascal RETF n.
u9_2f7b proc far
    push bp
    mov bp,sp
    push si
    push di
    push ds
    mov dx,0a000h
    mov es,dx
    mov ds,dx
    mov ax,word ptr [bp+0ah]
    mul word ptr cs:[screen_stride]
    mov si,word ptr [bp+0ch]
    add si,ax
    mov ax,word ptr [bp+6]
    mul word ptr cs:[screen_stride]
    mov di,word ptr [bp+8]
    add di,ax
    mov dx,3c4h
    mov al,2
    out dx,al
    mov dx,3c5h
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov al,5
    out dx,al
    inc dx
    mov al,1
    out dx,al
    mov ax,word ptr cs:[screen_stride]
    dec ax
    dec ax
    mov cx,10h
tile_copy_row_loop_46:
    movsb
    movsb
    add si,ax
    add di,ax
    loop tile_copy_row_loop_46
    mov dx,3cfh
    mov al,0
    out dx,al
    pop ds
    pop di
    pop si
    pop bp
    retf
    retf 8
u9_2f7b endp

; copy video rectangle unused cdecl
; Active caller-cleanup RETF, then unreachable Pascal RETF n.
u9_2fd7 proc far
    push bp
    mov bp,sp
    push si
    push di
    push ds
    mov dx,0a000h
    mov es,dx
    mov ds,dx
    mov ax,word ptr [bp+0eh]
    mul word ptr cs:[screen_stride]
    mov si,word ptr [bp+10h]
    add si,ax
    mov ax,word ptr [bp+0ah]
    mul word ptr cs:[screen_stride]
    mov di,word ptr [bp+0ch]
    add di,ax
    mov dx,3c4h
    mov al,2
    out dx,al
    mov dx,3c5h
    mov al,0fh
    out dx,al
    mov dx,3ceh
    mov al,5
    out dx,al
    inc dx
    mov al,1
    out dx,al
    mov ax,word ptr cs:[screen_stride]
    mov bx,word ptr [bp+8]
    sub ax,bx
    mov cx,word ptr [bp+6]
rect_copy_row_loop_49:
    push cx
    mov cx,bx
    rep movsb
    pop cx
    add si,ax
    add di,ax
    loop rect_copy_row_loop_49
    mov dx,3cfh
    mov al,0
    out dx,al
    pop ds
    pop di
    pop si
    pop bp
    retf
    retf 0ch
u9_2fd7 endp
CODE ends
end
