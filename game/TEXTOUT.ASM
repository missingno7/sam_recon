; Text-memory output and BIOS video queries for TEXT80.
; Colored string writes optionally synchronize with CGA retrace.

; BIOS video services and the CGA status register.
TextBiosVideoInterrupt          equ 10h
TextBiosGetMode                 equ 0fh
TextBiosStateQuery              equ 1c00h
TextBiosStateSignature          equ 1ch
TextBiosAdapterQuery            equ 1200h
TextBiosQuerySignature          equ 12h
TextMonoBiosMode                equ 7
TextCgaStatusPort               equ 3dah
TextVerticalRetraceBit          equ 8

; Adapter classes returned by this library's capability probes.
TextAdapterMono                 equ 0
TextAdapterCga                  equ 1
TextAdapterEga                  equ 2
TextAdapterVga                  equ 3
TextAdapterStateBios            equ 4

DATA segment word public
extrn TextVideoSegment:word, TextRetraceSyncEnabled:byte, TextSavedBiosMode:byte, TextVideoAdapterClass:byte
DATA ends

CODE segment byte public
assume cs:CODE, ds:DATA
public WriteColoredText, DetectTextVideoAdapter, GetTextVideoMode

; Text VRAM addressing and string output.
; Register helper: CH = 1-based row, BL = 1-based column; returns ES:DI.
; AX/BX/CX and flags are scratch; NEAR return, no arguments, CS state: none.
; Computes (row-1)*160+(column-1)*2 in an 80-column text page.
TextCellAddress proc near
    xor ax, ax
    mov cl, al
    mov bh, al
    dec ch
    shr cx, 1
    mov di, cx
    shr di, 1
    shr di, 1
    add di, cx
    dec bx
    shl bx, 1
    add di, bx
    mov es, word ptr TextVideoSegment
    ret
TextCellAddress endp

; Pascal: procedure WriteColoredText(TextColumn,TextRow,ColorAttribute: Byte;
;   DisplayText: String).
; BP+14/12/10/6 = column/row/attribute/far string; RETF 10. Saves BP/DS;
; AX/BX/CX/DX/SI/DI/ES and flags are scratch. CS state: none.
; Writes character/attribute pairs; TextRetraceSyncEnabled bit 0 selects the
; CGA snow-avoidance path. Original STI unconditionally enables interrupts.
WriteColoredText proc far
    push bp
    mov bp, sp
    push ds
    mov ch, byte ptr [bp+0ch]
    mov bl, byte ptr [bp+0eh]
    call TextCellAddress
    mov cl, byte ptr TextRetraceSyncEnabled
    lds si, [bp+6]
    cld
    lodsb
    xchg cx, ax
    jcxz color_done
    mov ah, byte ptr [bp+0ah]
color_byte:
    rcr al, 1
    jnc color_plain
    mov dx, TextCgaStatusPort
color_lodsb:
    lodsb
    mov bx, ax
    cli
color_wait_start:
    in al, dx
    test al, TextVerticalRetraceBit
    jnz color_write
    rcr al, 1
    jb color_wait_start
color_wait_end:
    in al, dx
    rcr al, 1
    jnc color_wait_end
color_write:
    mov ax, bx
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
    mov sp, bp
    pop bp
    retf 0ah
WriteColoredText endp

; Unused Pascal-style entry: procedure WriteTextCharacters(Column,Row: Integer;
;   Text: String); BP+12/10/6 = column/row/far string; RETF 8. Saves BP/DS;
; AX/BX/CX/DX/SI/DI/ES and flags are scratch. CS state: none.
; Writes characters and skips existing attributes, with the same CGA policy.
WriteTextCharacters proc far
    push bp
    mov bp, sp
    push ds
    mov ch, byte ptr [bp+0ah]
    mov bl, byte ptr [bp+0ch]
    call TextCellAddress
    mov cl, byte ptr TextRetraceSyncEnabled
    lds si, [bp+6]
    cld
    lodsb
    xchg cx, ax
    jcxz chars_done
char_byte:
    rcr al, 1
    jnc char_plain
    mov dx, TextCgaStatusPort
char_lodsb:
    lodsb
    mov ah, al
    cli
char_wait_start:
    in al, dx
    test al, TextVerticalRetraceBit
    jnz char_write
    rcr al, 1
    jb char_wait_start
char_wait_end:
    in al, dx
    rcr al, 1
    jnc char_wait_end
char_write:
    mov al, ah
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
    mov sp, bp
    pop bp
    retf 8
WriteTextCharacters endp

; BIOS video queries.
; Register helper: no arguments; AL = BIOS mode, also saved in DS.
; NEAR return; AX/BX and flags are scratch. CS state: none.
QueryAndSaveTextVideoMode proc near
    mov ah, TextBiosGetMode
    int TextBiosVideoInterrupt
    mov byte ptr TextSavedBiosMode, al
    ret
QueryAndSaveTextVideoMode endp

; Pascal: function DetectTextVideoAdapter: Byte; FAR return, no stack arguments.
; AL = adapter class, also saved in DS. AX/BX/CX and flags are scratch.
; CS state: none. Try video-state, VGA, then EGA BIOS services; mode 7
; distinguishes the monochrome fallback from color text.
DetectTextVideoAdapter proc far
    call QueryAndSaveTextVideoMode
    mov byte ptr TextVideoAdapterClass, TextAdapterStateBios
    mov cx, 0ffffh
    mov ax, TextBiosStateQuery
    int TextBiosVideoInterrupt
    cmp al, TextBiosStateSignature
    je adapter_done
    mov byte ptr TextVideoAdapterClass, TextAdapterVga
    mov bl, 32h
    mov ax, TextBiosAdapterQuery
    int TextBiosVideoInterrupt
    cmp al, TextBiosQuerySignature
    je adapter_done
    mov byte ptr TextVideoAdapterClass, TextAdapterEga
    mov bx, 0ff10h
    mov cx, 0ffffh
    mov ax, TextBiosAdapterQuery
    int TextBiosVideoInterrupt
    xor al, al
    cmp cx, -1
    je adapter_unknown
    cmp bh, 1
    ja adapter_unknown
    cmp bh, 1
    je adapter_mode7
    cmp byte ptr TextSavedBiosMode, TextMonoBiosMode
    je adapter_unknown
    jmp short adapter_done
adapter_mode7:
    cmp byte ptr TextSavedBiosMode, TextMonoBiosMode
    jne adapter_unknown
adapter_done:
    mov al, byte ptr TextVideoAdapterClass
    retf
adapter_unknown:
    mov byte ptr TextVideoAdapterClass, TextAdapterCga
    cmp byte ptr TextSavedBiosMode, TextMonoBiosMode
    jne adapter_done
    mov byte ptr TextVideoAdapterClass, TextAdapterMono
    jmp short adapter_done
DetectTextVideoAdapter endp

; Pascal: function GetTextVideoMode: Byte; FAR return, no stack arguments.
; AL = mode; AX/BX and flags are scratch. CS state: none.
GetTextVideoMode proc far
    call QueryAndSaveTextVideoMode
    retf
GetTextVideoMode endp
CODE ends
end

