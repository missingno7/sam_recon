; Unit u4 text output and video-adapter object, SAM1 04A3-05C7.
DATA segment word public
extrn d_21D6:word, d_21D8:byte, d_21DE:byte, d_21DF:byte
DATA ends

CODE segment byte public
assume cs:CODE, ds:DATA
public u4_04bf, u4_0557, u4_05c3

; Convert text coordinates in CH and BL to an ES:DI text-cell address.
u4_04a3 proc near
    xor ax,ax
    mov cl,al
    mov bh,al
    dec ch
    shr cx,1
    mov di,cx
    shr di,1
    shr di,1
    add di,cx
    dec bx
    shl bx,1
    add di,bx
    mov es,word ptr d_21D6
    ret
u4_04a3 endp

; Write a colored Pascal string, using retrace synchronization for set bits.
u4_04bf proc far
    push bp
    mov bp,sp
    push ds
    mov ch,byte ptr [bp+0ch]
    mov bl,byte ptr [bp+0eh]
    call u4_04a3
    mov cl,byte ptr d_21D8
    lds si,[bp+6]
    cld
    lodsb
    xchg cx,ax
    jcxz color_done
    mov ah,byte ptr [bp+0ah]
color_byte:
    rcr al,1
    jnc color_plain
    mov dx,03dah
color_lodsb:
    lodsb
    mov bx,ax
    cli
color_wait_start:
    in al,dx
    test al,8
    jnz color_write
    rcr al,1
    jb color_wait_start
color_wait_end:
    in al,dx
    rcr al,1
    jnc color_wait_end
color_write:
    mov ax,bx
    stosw
    sti
    loop color_lodsb
    jmp color_done
color_plain:
    lodsb
    stosw
    loop color_plain
color_done:
    pop ds
    mov sp,bp
    pop bp
    retf 0ah
u4_04bf endp

; Write only the character bytes of a Pascal string.
u4_0508 proc far
    push bp
    mov bp,sp
    push ds
    mov ch,byte ptr [bp+0ah]
    mov bl,byte ptr [bp+0ch]
    call u4_04a3
    mov cl,byte ptr d_21D8
    lds si,[bp+6]
    cld
    lodsb
    xchg cx,ax
    jcxz chars_done
char_byte:
    rcr al,1
    jnc char_plain
    mov dx,03dah
char_lodsb:
    lodsb
    mov ah,al
    cli
char_wait_start:
    in al,dx
    test al,8
    jnz char_write
    rcr al,1
    jb char_wait_start
char_wait_end:
    in al,dx
    rcr al,1
    jnc char_wait_end
char_write:
    mov al,ah
    stosb
    sti
    inc di
    loop char_lodsb
    jmp chars_done
char_plain:
    movsb
    inc di
    loop char_plain
chars_done:
    pop ds
    mov sp,bp
    pop bp
    retf 8
u4_0508 endp

; Save the current BIOS video mode in d_21DE and return it in AL.
u4_054f proc near
    mov ah,0fh
    int 10h
    mov byte ptr d_21DE,al
    ret
u4_054f endp

; Detect Hercules, EGA and CGA capabilities; return adapter class in AL.
u4_0557 proc far
    call u4_054f
    mov byte ptr d_21DF,4
    mov cx,0ffffh
    mov ax,1c00h
    int 10h
    cmp al,1ch
    je adapter_done
    mov byte ptr d_21DF,3
    mov bl,32h
    mov ax,1200h
    int 10h
    cmp al,12h
    je adapter_done
    mov byte ptr d_21DF,2
    mov bx,0ff10h
    mov cx,0ffffh
    mov ax,1200h
    int 10h
    xor al,al
    cmp cx,-1
    je adapter_unknown
    cmp bh,1
    ja adapter_unknown
    cmp bh,1
    je adapter_mode7
    cmp byte ptr d_21DE,7
    je adapter_unknown
    jmp short adapter_done
adapter_mode7:
    cmp byte ptr d_21DE,7
    jne adapter_unknown
adapter_done:
    mov al,byte ptr d_21DF
    retf
adapter_unknown:
    mov byte ptr d_21DF,1
    cmp byte ptr d_21DE,7
    jne adapter_done
    mov byte ptr d_21DF,0
    jmp short adapter_done
u4_0557 endp

; Return the BIOS video mode in AL.
u4_05c3 proc far
    call u4_054f
    retf
u4_05c3 endp
CODE ends
end




