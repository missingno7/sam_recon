; Unit u4 text output and video-adapter object, SAM1 04A3-05C7.
DATA segment word public
extrn TextVideoSegment:word, TextRetraceSyncEnabled:byte, TextSavedBiosMode:byte, TextVideoAdapterClass:byte
DATA ends

CODE segment byte public
assume cs:CODE, ds:DATA
public WriteColoredText, DetectTextVideoAdapter, GetTextVideoMode

; Convert text coordinates in CH and BL to an ES:DI text-cell address.
; Assembly helper computes (row-1)*160+(column-1)*2 and loads ES from d_21D6.
TextCellAddress proc near
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
    mov es,word ptr TextVideoSegment
    ret
TextCellAddress endp

; Write a colored Pascal string, using retrace synchronization for set bits.
; Writes Pascal-string characters and attribute bytes to text VRAM, with optional CGA synchronization.
WriteColoredText proc far
    push bp
    mov bp,sp
    push ds
    mov ch,byte ptr [bp+0ch]
    mov bl,byte ptr [bp+0eh]
    call TextCellAddress
    mov cl,byte ptr TextRetraceSyncEnabled
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
WriteColoredText endp

; Write only the character bytes of a Pascal string.
; Writes only character bytes to text VRAM while preserving their existing attributes.
WriteTextCharacters proc far
    push bp
    mov bp,sp
    push ds
    mov ch,byte ptr [bp+0ah]
    mov bl,byte ptr [bp+0ch]
    call TextCellAddress
    mov cl,byte ptr TextRetraceSyncEnabled
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
WriteTextCharacters endp

; Save the current BIOS video mode in d_21DE and return it in AL.
; INT 10h AH=0F saves the current mode in d_21DE and returns AL.
QueryAndSaveTextVideoMode proc near
    mov ah,0fh
    int 10h
    mov byte ptr TextSavedBiosMode,al
    ret
QueryAndSaveTextVideoMode endp

; Detect Hercules, EGA and CGA capabilities; return adapter class in AL.
; BIOS capability calls classify the display adapter and return the class byte saved in d_21DF.
DetectTextVideoAdapter proc far
    call QueryAndSaveTextVideoMode
    mov byte ptr TextVideoAdapterClass,4
    mov cx,0ffffh
    mov ax,1c00h
    int 10h
    cmp al,1ch
    je adapter_done
    mov byte ptr TextVideoAdapterClass,3
    mov bl,32h
    mov ax,1200h
    int 10h
    cmp al,12h
    je adapter_done
    mov byte ptr TextVideoAdapterClass,2
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
    cmp byte ptr TextSavedBiosMode,7
    je adapter_unknown
    jmp short adapter_done
adapter_mode7:
    cmp byte ptr TextSavedBiosMode,7
    jne adapter_unknown
adapter_done:
    mov al,byte ptr TextVideoAdapterClass
    retf
adapter_unknown:
    mov byte ptr TextVideoAdapterClass,1
    cmp byte ptr TextSavedBiosMode,7
    jne adapter_done
    mov byte ptr TextVideoAdapterClass,0
    jmp short adapter_done
DetectTextVideoAdapter endp

; Return the BIOS video mode in AL.
; Calls the BIOS-mode helper and returns its AL result.
GetTextVideoMode proc far
    call QueryAndSaveTextVideoMode
    retf
GetTextVideoMode endp
CODE ends
end




