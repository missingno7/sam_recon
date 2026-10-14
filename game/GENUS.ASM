; Genus PCX Programmer's Toolkit 3.56 assembly implementation for PCXGENUS.
; Includes video modes, adapter-specific image decoding and printer raster output.
DATA segment byte public
extrn GenusPcxIdentity:byte
extrn PcxDisplayDescriptions:byte
extrn PcxSelectedDisplay:byte
extrn PcxGraphicsModeState:byte
extrn PcxDisplayPageState:byte
extrn PcxModeCheckPolicy:byte
extrn PcxDefaultReadBuffer:byte
extrn PcxReadState:byte
extrn PcxPrinterScanline:byte
extrn PcxPrintedSourceRow:byte
extrn PcxPrinterDeviceClass:byte
extrn PcxPrinterResolutionClass:byte
extrn PcxDisplayTable:byte
extrn PcxHerculesGraphicsCrtc:byte
extrn PcxHerculesTextCrtc:byte
extrn PcxPrinterState:byte
DATA ends

CODE segment byte public
assume cs:CODE,ds:DATA
public PcxSetDisplayType
public PcxSetGraphicsOrTextMode
public PcxGetDisplayType
public PcxGetDisplayDescriptor
public PcxInitializeVideoDescriptors
public PcxDisplayBuffer
public PcxInitializeDisplayDispatch
public PcxDisplayFile
public PcxBeginPrinterImage
public PcxEndPrinterImage
public PcxFormatUnsignedDecimal
public PcxInitializePrinterState

; Video modes and display descriptors.
; Pcx set display type.
PcxSetDisplayType proc far
    push bp
    mov bp, sp
    sub sp, 2
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov ax, word ptr [bp + 6]
    cmp ax, 0
    jb set_display_type_error_1
    cmp ax, 15h
    jbe set_display_type_next_1
set_display_type_error_1:
    mov word ptr [bp - 2], 0fffah
    jmp short set_display_type_done_1
set_display_type_next_1:
    mov word ptr [PcxSelectedDisplay], ax
    mov word ptr [bp - 2], 0
set_display_type_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 2
PcxSetDisplayType endp

; Pcx set graphics or text mode.
PcxSetGraphicsOrTextMode proc far
    push bp
    mov bp, sp
    sub sp, 2
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov word ptr [bp - 2], 0
    mov ax, word ptr [PcxSelectedDisplay]
    push ax
    call far ptr PcxGetDisplayDescriptor
    cmp ax, 0
    jae set_graphics_or_text_mode_next_1
    mov word ptr [bp - 2], ax
    jmp short set_graphics_or_text_mode_done_1
set_graphics_or_text_mode_next_1:
    mov di, ax
    mov ax, dx
    mov es, ax
    mov bx, word ptr [bp + 6]
    cmp bx, 1
    jne set_graphics_or_text_mode_next_3
    mov word ptr [PcxGraphicsModeState], bx
    mov word ptr [PcxDisplayPageState], 0
    cmp byte ptr es:[di], 9
    je set_graphics_or_text_mode_next_2
    push bx
    push bp
    mov ah, 0fh
    int 10h
    pop bp
    pop bx
    cmp al, byte ptr es:[di + 16h]
    je set_graphics_or_text_mode_done_1
    mov al, byte ptr es:[di + 16h]
    push bp
    mov ah, 0
    int 10h
    pop bp
    jmp short set_graphics_or_text_mode_done_1
set_graphics_or_text_mode_next_2:
    mov ax, 2
    call far ptr PcxHerculesModeHelper
    jmp short set_graphics_or_text_mode_done_1
set_graphics_or_text_mode_next_3:
    cmp bx, 0
    jne set_graphics_or_text_mode_error_1
    mov word ptr [PcxGraphicsModeState], bx
    mov word ptr [PcxDisplayPageState], 0
    cmp byte ptr es:[di], 9
    je set_graphics_or_text_mode_next_4
    mov al, 3
    push bp
    mov ah, 0
    int 10h
    pop bp
    jmp short set_graphics_or_text_mode_done_1
set_graphics_or_text_mode_next_4:
    mov ax, 20h
    call far ptr PcxHerculesModeHelper
    jmp short set_graphics_or_text_mode_done_1
set_graphics_or_text_mode_error_1:
    mov word ptr [bp - 2], 0fff9h
set_graphics_or_text_mode_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 2
PcxSetGraphicsOrTextMode endp

; Pcx get display type.
PcxGetDisplayType proc far
    push bp
    mov bp, sp
    sub sp, 2
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov ax, word ptr [PcxSelectedDisplay]
    mov word ptr [bp - 2], ax
    cmp ax, 0
    jl get_display_type_error_1
    cmp ax, 15h
    jle get_display_type_done_1
get_display_type_error_1:
    mov word ptr [bp - 2], 0fffah
get_display_type_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf
PcxGetDisplayType endp

; Pcx get version string.
PcxGetVersionString proc far
    push bp
    mov bp, sp
    sub sp, 2
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov ax, word ptr [bp + 8]
    mov es, ax
    mov di, word ptr [bp + 6]
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov si, offset GenusPcxIdentity + 01Ah
    mov cx, 4
    cld
    mov byte ptr es:[di], cl
    inc di
    rep movsb
    mov word ptr [bp - 2], 0
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 4
PcxGetVersionString endp

; Pcx set work buffer.
PcxSetWorkBuffer proc far
    push bp
    mov bp, sp
    sub sp, 2
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov ax, word ptr [bp + 6]
    cmp ax, 800h
    jae set_work_buffer_next_1
    cmp ax, 0
    jne set_work_buffer_error_1
    mov word ptr [PcxReadState + 02h], 0ffffh
    mov word ptr [bp - 2], 0
    jmp short set_work_buffer_done_1
set_work_buffer_error_1:
    mov word ptr [bp - 2], 0fffeh
    jmp short set_work_buffer_done_1
set_work_buffer_next_1:
    mov ax, word ptr [bp + 0ah]
    mov word ptr [PcxReadState + 02h], ax
    mov ax, word ptr [bp + 8]
    mov word ptr [PcxReadState + 04h], ax
    mov ax, word ptr [bp + 6]
    sub ax, 0ah
    mov word ptr [PcxReadState], ax
    mov word ptr [bp - 2], 0
set_work_buffer_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 6
PcxSetWorkBuffer endp

; Pcx get display descriptor.
PcxGetDisplayDescriptor proc far
    push bp
    mov bp, sp
    sub sp, 2
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov ax, word ptr [bp + 6]
    cmp ax, 0
    jb get_display_descriptor_error_1
    cmp ax, 15h
    jbe get_display_descriptor_next_1
get_display_descriptor_error_1:
    mov word ptr [bp - 2], 0fffah
    jmp short get_display_descriptor_done_1
get_display_descriptor_next_1:
    mov di, offset PcxDisplayTable
    mov ax, 38h
    mov cx, word ptr [bp + 6]
    mul cx
    add di, ax
    mov ax, seg PcxSelectedDisplay
    mov es, ax
    mov ax, di
    mov dx, es
    mov bl, byte ptr es:[di]
    cmp bl, byte ptr [bp + 6]
    je get_display_descriptor_next_2
    mov word ptr [bp - 2], 0fc19h
    jmp short get_display_descriptor_done_1
get_display_descriptor_next_2:
    mov word ptr [bp - 2], ax
get_display_descriptor_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 2
PcxGetDisplayDescriptor endp

; Pcx get display information.
PcxGetDisplayInformation proc far
    push bp
    mov bp, sp
    sub sp, 2
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov ax, word ptr [bp + 0ah]
    push ax
    call far ptr PcxGetDisplayDescriptor
    cmp ax, 0
    jae get_display_information_next_1
    mov word ptr [bp - 2], 0fc19h
    jmp short get_display_information_done_1
get_display_information_next_1:
    mov si, ax
    mov ax, dx
    mov ds, ax
    mov ax, word ptr [bp + 8]
    mov es, ax
    mov di, word ptr [bp + 6]
    mov cx, 38h
    cld
    rep movsb
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov si, offset PcxDisplayDescriptions
    mov ax, 15h
    mov cx, word ptr [bp + 0ah]
    mul cx
    add si, ax
    mov di, word ptr [bp + 6]
    add di, 1
    mov cx, 15h
    rep movsb
    mov word ptr [bp - 2], 0
get_display_information_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 6
PcxGetDisplayInformation endp

; Pcx initialize video descriptors.
PcxInitializeVideoDescriptors proc far
    push bp
    mov bp, sp
    sub sp, 2
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov word ptr [bp - 2], 0
    mov word ptr [PcxSelectedDisplay], 0ffffh
    mov word ptr [PcxGraphicsModeState], 0ffffh
    mov word ptr [PcxDisplayPageState], 0ffffh
    mov word ptr [PcxModeCheckPolicy], 1
    mov word ptr [PcxReadState + 06h], 0ffffh
    mov word ptr [PcxReadState + 02h], 0ffffh
    mov word ptr [PcxReadState + 04h], 0ffffh
    mov word ptr [PcxReadState], 800h
    mov byte ptr [PcxReadState + 0Ch], 0
    mov byte ptr [PcxReadState + 0Dh], 0
    mov byte ptr [PcxReadState + 0Eh], 0
    mov byte ptr [PcxReadState + 0Fh], 0
    mov byte ptr [PcxReadState + 010h], 0
    mov ax, seg PcxSelectedDisplay
    mov es, ax
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 0
    mul cx
    add bx, ax
    mov byte ptr [bx], 0
    mov byte ptr [bx + 16h], 4
    mov byte ptr [bx + 17h], 2
    mov word ptr [bx + 18h], 140h
    mov word ptr [bx + 1ah], 0c8h
    mov byte ptr [bx + 1ch], 1
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0b800h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 1
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 1
    mul cx
    add bx, ax
    mov byte ptr [bx], 1
    mov byte ptr [bx + 16h], 6
    mov byte ptr [bx + 17h], 1
    mov word ptr [bx + 18h], 280h
    mov word ptr [bx + 1ah], 0c8h
    mov byte ptr [bx + 1ch], 1
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0b800h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 2
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 2
    mul cx
    add bx, ax
    mov byte ptr [bx], 2
    mov byte ptr [bx + 16h], 0dh
    mov byte ptr [bx + 17h], 1
    mov word ptr [bx + 18h], 140h
    mov word ptr [bx + 1ah], 0c8h
    mov byte ptr [bx + 1ch], 4
    mov byte ptr [bx + 1dh], 8
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 2000h
    mov word ptr [bx + 22h], 3
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 3
    mul cx
    add bx, ax
    mov byte ptr [bx], 3
    mov byte ptr [bx + 16h], 0eh
    mov byte ptr [bx + 17h], 1
    mov word ptr [bx + 18h], 280h
    mov word ptr [bx + 1ah], 0c8h
    mov byte ptr [bx + 1ch], 4
    mov byte ptr [bx + 1dh], 4
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 4000h
    mov word ptr [bx + 22h], 3
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 4
    mul cx
    add bx, ax
    mov byte ptr [bx], 4
    mov byte ptr [bx + 16h], 0fh
    mov byte ptr [bx + 17h], 1
    mov word ptr [bx + 18h], 280h
    mov word ptr [bx + 1ah], 15eh
    mov byte ptr [bx + 1ch], 1
    mov byte ptr [bx + 1dh], 2
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 8000h
    mov word ptr [bx + 22h], 0
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 5
    mul cx
    add bx, ax
    mov byte ptr [bx], 5
    mov byte ptr [bx + 16h], 10h
    mov byte ptr [bx + 17h], 1
    mov word ptr [bx + 18h], 280h
    mov word ptr [bx + 1ah], 15eh
    mov byte ptr [bx + 1ch], 4
    mov byte ptr [bx + 1dh], 2
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 8000h
    mov word ptr [bx + 22h], 3
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 6
    mul cx
    add bx, ax
    mov byte ptr [bx], 6
    mov byte ptr [bx + 16h], 11h
    mov byte ptr [bx + 17h], 1
    mov word ptr [bx + 18h], 280h
    mov word ptr [bx + 1ah], 1e0h
    mov byte ptr [bx + 1ch], 1
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 0
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 7
    mul cx
    add bx, ax
    mov byte ptr [bx], 7
    mov byte ptr [bx + 16h], 12h
    mov byte ptr [bx + 17h], 1
    mov word ptr [bx + 18h], 280h
    mov word ptr [bx + 1ah], 1e0h
    mov byte ptr [bx + 1ch], 4
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 4
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 8
    mul cx
    add bx, ax
    mov byte ptr [bx], 8
    mov byte ptr [bx + 16h], 13h
    mov byte ptr [bx + 17h], 8
    mov word ptr [bx + 18h], 140h
    mov word ptr [bx + 1ah], 0c8h
    mov byte ptr [bx + 1ch], 1
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 5
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 9
    mul cx
    add bx, ax
    mov byte ptr [bx], 9
    mov byte ptr [bx + 16h], 0
    mov byte ptr [bx + 17h], 1
    mov word ptr [bx + 18h], 2d0h
    mov word ptr [bx + 1ah], 15ch
    mov byte ptr [bx + 1ch], 1
    mov byte ptr [bx + 1dh], 2
    mov word ptr [bx + 1eh], 0b000h
    mov word ptr [bx + 20h], 8000h
    mov word ptr [bx + 22h], 0
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 0ah
    mul cx
    add bx, ax
    mov byte ptr [bx], 0ah
    mov byte ptr [bx + 16h], 29h
    mov byte ptr [bx + 17h], 1
    mov word ptr [bx + 18h], 320h
    mov word ptr [bx + 1ah], 258h
    mov byte ptr [bx + 1ch], 4
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 4
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 0bh
    mul cx
    add bx, ax
    mov byte ptr [bx], 0bh
    mov byte ptr [bx + 16h], 2dh
    mov byte ptr [bx + 17h], 8
    mov word ptr [bx + 18h], 280h
    mov word ptr [bx + 1ah], 15eh
    mov byte ptr [bx + 1ch], 1
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 5
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 0ch
    mul cx
    add bx, ax
    mov byte ptr [bx], 0ch
    mov byte ptr [bx + 16h], 2eh
    mov byte ptr [bx + 17h], 8
    mov word ptr [bx + 18h], 280h
    mov word ptr [bx + 1ah], 1e0h
    mov byte ptr [bx + 1ch], 1
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 5
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 0dh
    mul cx
    add bx, ax
    mov byte ptr [bx], 0dh
    mov byte ptr [bx + 16h], 30h
    mov byte ptr [bx + 17h], 8
    mov word ptr [bx + 18h], 320h
    mov word ptr [bx + 1ah], 258h
    mov byte ptr [bx + 1ch], 1
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 5
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 0eh
    mul cx
    add bx, ax
    mov byte ptr [bx], 0eh
    mov byte ptr [bx + 16h], 58h
    mov byte ptr [bx + 17h], 1
    mov word ptr [bx + 18h], 320h
    mov word ptr [bx + 1ah], 258h
    mov byte ptr [bx + 1ch], 4
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 4
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 0fh
    mul cx
    add bx, ax
    mov byte ptr [bx], 0fh
    mov byte ptr [bx + 16h], 59h
    mov byte ptr [bx + 17h], 1
    mov word ptr [bx + 18h], 320h
    mov word ptr [bx + 1ah], 258h
    mov byte ptr [bx + 1ch], 1
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 0
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 10h
    mul cx
    add bx, ax
    mov byte ptr [bx], 10h
    mov byte ptr [bx + 16h], 5eh
    mov byte ptr [bx + 17h], 8
    mov word ptr [bx + 18h], 280h
    mov word ptr [bx + 1ah], 190h
    mov byte ptr [bx + 1ch], 1
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 5
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 11h
    mul cx
    add bx, ax
    mov byte ptr [bx], 11h
    mov byte ptr [bx + 16h], 5fh
    mov byte ptr [bx + 17h], 8
    mov word ptr [bx + 18h], 280h
    mov word ptr [bx + 1ah], 1e0h
    mov byte ptr [bx + 1ch], 1
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 5
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 12h
    mul cx
    add bx, ax
    mov byte ptr [bx], 12h
    mov byte ptr [bx + 16h], 16h
    mov byte ptr [bx + 17h], 1
    mov word ptr [bx + 18h], 320h
    mov word ptr [bx + 1ah], 258h
    mov byte ptr [bx + 1ch], 4
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 4
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 13h
    mul cx
    add bx, ax
    mov byte ptr [bx], 13h
    mov byte ptr [bx + 16h], 1ah
    mov byte ptr [bx + 17h], 8
    mov word ptr [bx + 18h], 280h
    mov word ptr [bx + 1ah], 190h
    mov byte ptr [bx + 1ch], 1
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 5
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 14h
    mul cx
    add bx, ax
    mov byte ptr [bx], 14h
    mov byte ptr [bx + 16h], 1bh
    mov byte ptr [bx + 17h], 8
    mov word ptr [bx + 18h], 280h
    mov word ptr [bx + 1ah], 1e0h
    mov byte ptr [bx + 1ch], 1
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 5
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov bx, offset PcxDisplayTable
    mov ax, 38h
    mov cx, 15h
    mul cx
    add bx, ax
    mov byte ptr [bx], 15h
    mov byte ptr [bx + 16h], 1dh
    mov byte ptr [bx + 17h], 8
    mov word ptr [bx + 18h], 320h
    mov word ptr [bx + 1ah], 258h
    mov byte ptr [bx + 1ch], 1
    mov byte ptr [bx + 1dh], 1
    mov word ptr [bx + 1eh], 0a000h
    mov word ptr [bx + 20h], 0
    mov word ptr [bx + 22h], 5
    mov word ptr [bx + 24h], 0
    mov word ptr [bx + 26h], 0
    mov word ptr [bx + 28h], 0
    mov word ptr [bx + 2ah], 0
    mov word ptr [bx + 2ch], 0
    mov word ptr [bx + 2eh], 0
    mov word ptr [bx + 30h], 0
    mov word ptr [bx + 32h], 0
    mov word ptr [bx + 34h], 0
    mov word ptr [bx + 36h], 0
    mov si, offset PcxHerculesGraphicsCrtc
    mov byte ptr [si], 35h
    inc si
    mov byte ptr [si], 2dh
    inc si
    mov byte ptr [si], 2eh
    inc si
    mov byte ptr [si], 7
    inc si
    mov byte ptr [si], 5bh
    inc si
    mov byte ptr [si], 2
    inc si
    mov byte ptr [si], 57h
    inc si
    mov byte ptr [si], 57h
    inc si
    mov byte ptr [si], 2
    inc si
    mov byte ptr [si], 3
    inc si
    mov byte ptr [si], 0
    inc si
    mov byte ptr [si], 0
    inc si
    mov si, offset PcxHerculesTextCrtc
    mov byte ptr [si], 61h
    inc si
    mov byte ptr [si], 50h
    inc si
    mov byte ptr [si], 52h
    inc si
    mov byte ptr [si], 0fh
    inc si
    mov byte ptr [si], 19h
    inc si
    mov byte ptr [si], 6
    inc si
    mov byte ptr [si], 19h
    inc si
    mov byte ptr [si], 19h
    inc si
    mov byte ptr [si], 2
    inc si
    mov byte ptr [si], 0dh
    inc si
    mov byte ptr [si], 0bh
    inc si
    mov byte ptr [si], 0ch
    inc si
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf
PcxInitializeVideoDescriptors endp

; Hercules mode controls.
; Pcx hercules mode helper.
PcxHerculesModeHelper proc far
    push ax
    cmp al, 2
    je hercules_mode_helper_next_1
    mov si, offset PcxHerculesTextCrtc
    mov bx, 720h
    push bx
    mov bx, 7d0h
    push bx
    jmp short hercules_mode_helper_next_2
hercules_mode_helper_next_1:
    mov si, offset PcxHerculesGraphicsCrtc
    mov bx, 0
    push bx
    mov bx, 4000h
    push bx
hercules_mode_helper_next_2:
    mov ah, al
    mov al, ah
    mov dx, 3b8h
    out dx, al
    mov cx, 0ch
    xor ah, ah
    cld
hercules_mode_helper_loop_1:
    mov al, ah
    mov dx, 3b4h
    out dx, al
    lodsb
    mov bl, al
    mov al, bl
    mov dx, 3b5h
    out dx, al
    inc ah
    loop hercules_mode_helper_loop_1
    pop cx
    mov ax, 0b000h
    mov es, ax
    xor di, di
    pop ax
    rep stosw
    pop bx
    add bl, 8
    mov al, bl
    mov dx, 3b8h
    out dx, al
    retf
PcxHerculesModeHelper endp

; pcx set cga palette
; Writes a validated control byte (1 or 3) to port 3BFh; no palette register is written.
PcxSetHerculesControl proc far
    push bp
    mov bp, sp
    sub sp, 2
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov ax, word ptr [bp + 6]
    cmp ax, 3
    je set_cga_palette_next_1
    cmp ax, 1
    je set_cga_palette_next_1
    mov ax, 1
set_cga_palette_next_1:
    mov dx, 3bfh
    out dx, al
    mov word ptr [bp - 2], 0
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 2
PcxSetHerculesControl endp

; pcx set mode change policy
; Stores a validated 0/1 policy; PcxDisplayBuffer checks the selected BIOS video mode when the policy is 1.
PcxSetModeCheckPolicy proc far
    push bp
    mov bp, sp
    sub sp, 2
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov ax, word ptr [bp + 6]
    cmp ax, 1
    je set_mode_change_policy_next_1
    cmp ax, 0
    je set_mode_change_policy_next_1
    mov ax, 1
set_mode_change_policy_next_1:
    mov word ptr [PcxModeCheckPolicy], ax
    mov word ptr [bp - 2], 0
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 2
PcxSetModeCheckPolicy endp

; Image validation and decoder dispatch.
; Pcx display buffer.
PcxDisplayBuffer proc far
    push bp
    mov bp, sp
    sub sp, 1eh
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    cmp byte ptr [PcxReadState + 0Ch], 1
    je display_buffer_next_1
    call far ptr PcxInitializeDisplayDispatch
display_buffer_next_1:
    mov ax, word ptr [PcxModeCheckPolicy]
    mov word ptr [bp - 4], ax
    mov ax, word ptr [bp + 10h]
    mov ds, ax
    mov si, word ptr [bp + 0eh]
    mov word ptr [bp - 8], si
    mov bx, word ptr [bp + 0ch]
    add bx, word ptr [bp - 8]
    dec bx
    mov word ptr [bp - 0ah], bx
    mov al, byte ptr [si]
    cmp al, 0ah
    je display_buffer_next_2
    mov word ptr [bp - 2], 0fffbh
    jmp short display_buffer_done_1
display_buffer_next_2:
    call far ptr PcxGetDisplayType
    cmp ax, 0
    jge display_buffer_next_3
    mov word ptr [bp - 2], ax
    jmp short display_buffer_done_1
display_buffer_next_3:
    push ax
    call far ptr PcxGetDisplayDescriptor
    cmp ax, 0
    jae display_buffer_next_4
    mov word ptr [bp - 2], 0fc19h
    jmp short display_buffer_done_1
display_buffer_next_4:
    mov di, ax
    mov ax, dx
    mov es, ax
    cmp word ptr [bp - 4], 1
    jne display_buffer_next_5
    cmp byte ptr es:[di], 9
    je display_buffer_next_5
    push bp
    mov ah, 0fh
    int 10h
    pop bp
    cmp al, byte ptr es:[di + 16h]
    je display_buffer_next_5
    mov word ptr [bp - 2], 0fff9h
    jmp short display_buffer_done_1
display_buffer_next_5:
    jmp dword ptr es:[di + 24h]
display_buffer_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxDisplayBuffer endp

; Pcx initialize display dispatch.
PcxInitializeDisplayDispatch proc far
    mov ax, 0
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxCgaDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 1
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxCgaDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 2
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxEgaDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 3
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxEgaDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 4
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxEgaDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 5
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxEgaDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 6
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxEgaDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 7
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxEgaDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 8
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxVga256DecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 9
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxHerculesDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 0ah
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxEgaDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 0bh
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxTsengDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 0ch
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxTsengDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 0dh
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxTsengDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 0eh
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxEgaDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 0fh
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxEgaDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 10h
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxParadiseDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 11h
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxParadiseDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 12h
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxEgaDecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 13h
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxVideo7DecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 14h
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxVideo7DecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov ax, 15h
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx + 24h], offset PcxVideo7DecodeContinuation
    mov word ptr [bx + 26h], seg CODE
    mov byte ptr [PcxReadState + 0Ch], 1
    retf
PcxInitializeDisplayDispatch endp

; Adapter-specific RLE decoding.
; pcx cga decode continuation
; Far-jump continuation: BP and saved registers belong to PcxDisplayBuffer.
; Pcx cga decode continuation. RLE-decodes a PCX image using the PcxDisplayBuffer frame.
PcxCgaDecodeContinuation proc far
    mov ax, word ptr [si + 8]
    sub ax, word ptr [si + 4]
    inc ax
    mov bx, word ptr [bp + 0ah]
    add bx, ax
    cmp bx, word ptr es:[di + 18h]
    jbe cga_decode_next_1
    mov ax, word ptr es:[di + 18h]
    sub ax, word ptr [bp + 0ah]
    inc ax
cga_decode_next_1:
    mov bl, byte ptr [si + 3]
    xor bh, bh
    mul bx
    mov bl, 8
    div bl
    mov cl, ah
    xor ah, ah
    mov word ptr [bp - 10h], ax
    dec word ptr [bp - 10h]
    mov word ptr [bp - 0eh], 0
    cmp cl, 0
    je cga_decode_next_2
    mov word ptr [bp - 0eh], 1
    mov al, 80h
    dec cl
    sar al, cl
    mov byte ptr [bp - 0ch], al
    inc word ptr [bp - 10h]
cga_decode_next_2:
    mov dx, word ptr [bp + 0ah]
    mov cl, 4
    sub cl, byte ptr es:[di + 17h]
    shr dx, cl
    mov ax, word ptr [bp + 8]
    shr ax, 1
    mov cl, 4
    shl ax, cl
    add dx, ax
    shl ax, 1
    shl ax, 1
    add dx, ax
    mov ax, word ptr [bp + 8]
    and ax, 1
    mov word ptr [bp - 6], ax
    cmp ax, 1
    jne cga_decode_next_3
    add dx, word ptr 2000h
cga_decode_next_3:
    mov ax, word ptr [si + 0ah]
    sub ax, word ptr [si + 6]
    inc ax
    mov bx, word ptr [bp + 8]
    add bx, ax
    cmp bx, word ptr es:[di + 1ah]
    jbe cga_decode_next_4
    mov ax, word ptr es:[di + 1ah]
    sub ax, word ptr [bp + 8]
cga_decode_next_4:
    mov bh, al
    mov bl, 0
    mov ax, word ptr es:[di + 1eh]
    mov es, ax
    mov di, dx
    mov dx, word ptr [si + 42h]
    mov ax, word ptr [bp - 6]
    mov dh, al
    mov ax, 2000h
    sub ax, word ptr [si + 42h]
    mov word ptr [bp - 4], ax
    add si, word ptr 80h
    cld
cga_decode_loop_1:
    xor ch, ch
    mov cl, 1
    lodsb
    mov ah, al
    and ah, 0c0h
    cmp ah, 0c0h
    jne cga_decode_next_5
    mov cl, al
    sub cl, 0c0h
    lodsb
cga_decode_next_5:
    cmp bl, byte ptr [bp - 10h]
    jb cga_decode_next_6
    ja cga_decode_next_7
    cmp word ptr [bp - 0eh], 1
    jne cga_decode_next_6
    push ax
    mov ah, byte ptr es:[di]
    or ah, byte ptr [bp - 0ch]
    sub ah, byte ptr [bp - 0ch]
    and al, byte ptr [bp - 0ch]
    or al, ah
    mov byte ptr es:[di], al
    pop ax
    jmp short cga_decode_next_7
cga_decode_next_6:
    mov byte ptr es:[di], al
cga_decode_next_7:
    inc di
    inc bl
    cmp bl, dl
    jne cga_decode_next_9
    dec bh
    xor bl, bl
    cmp bh, 0
    je cga_decode_next_11
    xor dh, 1
    cmp dh, 1
    jne cga_decode_next_8
    add di, word ptr [bp - 4]
    jmp short cga_decode_next_9
cga_decode_next_8:
    sub di, word ptr 1fb0h
    sub di, dx
cga_decode_next_9:
    loop cga_decode_next_5
    cmp si, word ptr [bp - 0ah]
    jbe cga_decode_next_10
    push si
    call far ptr PcxRefillReadBuffer
    mov si, ax
    jae cga_decode_next_10
    mov word ptr [bp - 2], 0fffdh
    jmp short cga_decode_done_1
cga_decode_next_10:
    jmp short cga_decode_loop_1
cga_decode_next_11:
    mov word ptr [bp - 2], 0
cga_decode_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxCgaDecodeContinuation endp

; pcx ega decode continuation
; Far-jump continuation: BP and saved registers belong to PcxDisplayBuffer.
; Pcx ega decode continuation. RLE-decodes a PCX image using the PcxDisplayBuffer frame.
PcxEgaDecodeContinuation proc far
    mov ax, word ptr es:[di + 18h]
    mov cl, 3
    shr ax, cl
    mov word ptr [bp - 16h], ax
    mov word ptr [bp - 0eh], 0
    mov ax, word ptr [si + 8]
    sub ax, word ptr [si + 4]
    inc ax
    mov bx, word ptr [bp + 0ah]
    add bx, ax
    cmp bx, word ptr es:[di + 18h]
    jbe ega_decode_next_1
    mov ax, word ptr es:[di + 18h]
    sub ax, word ptr [bp + 0ah]
    inc ax
    test al, 7
    je ega_decode_next_1
    inc ax
    and al, 0f8h
ega_decode_next_1:
    mov bl, byte ptr [si + 3]
    xor bh, bh
    mul bx
    mov bl, 8
    div bl
    mov cl, ah
    xor ah, ah
    mov word ptr [bp - 10h], ax
    dec word ptr [bp - 10h]
    cmp cl, 0
    je ega_decode_next_2
    mov word ptr [bp - 0eh], 1
    mov al, 80h
    dec cl
    sar al, cl
    mov byte ptr [bp - 0ch], al
    inc word ptr [bp - 10h]
ega_decode_next_2:
    mov al, 5
    mov dx, 3ceh
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    mov al, 8
    mov dx, 3ceh
    out dx, al
    inc dx
    mov al, 0ffh
    out dx, al
    mov byte ptr [bp - 18h], 1
    mov al, 2
    mov dx, 3c4h
    out dx, al
    inc dx
    mov al, byte ptr [bp - 18h]
    out dx, al
    mov word ptr [bp - 1ch], 1
    mov word ptr [bp - 1ah], 8
    cmp byte ptr [si + 41h], 3
    jne ega_decode_next_3
    mov word ptr [bp - 1ah], 4
ega_decode_next_3:
    cmp byte ptr [si + 41h], 1
    jne ega_decode_next_4
    mov word ptr [bp - 1ch], 0fh
    mov word ptr [bp - 1ah], 1
    mov al, 2
    mov dx, 3c4h
    out dx, al
    inc dx
    mov al, 0fh
    out dx, al
ega_decode_next_4:
    mov ax, word ptr es:[di + 20h]
    mov bx, word ptr [bp + 6]
    mul bx
    mov dx, ax
    mov ax, word ptr [bp + 0ah]
    mov cl, 3
    shr ax, cl
    add dx, ax
    mov ax, word ptr [bp + 8]
    cmp word ptr [bp - 16h], 50h
    je ega_decode_next_5
    cmp word ptr [bp - 16h], 64h
    je ega_decode_next_6
    mov cl, 3
    shl ax, cl
    add dx, ax
    shl ax, 1
    shl ax, 1
    add dx, ax
    jmp short ega_decode_next_7
ega_decode_next_5:
    mov cl, 4
    shl ax, cl
    add dx, ax
    shl ax, 1
    shl ax, 1
    add dx, ax
    jmp short ega_decode_next_7
ega_decode_next_6:
    shl ax, 1
    shl ax, 1
    add dx, ax
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add dx, ax
    shl ax, 1
    add dx, ax
ega_decode_next_7:
    mov ax, word ptr [si + 0ah]
    sub ax, word ptr [si + 6]
    inc ax
    mov word ptr [bp - 12h], ax
    mov bx, word ptr [bp + 8]
    add bx, ax
    cmp bx, word ptr es:[di + 1ah]
    jbe ega_decode_next_8
    mov ax, word ptr es:[di + 1ah]
    sub ax, word ptr [bp + 8]
    inc ax
    mov word ptr [bp - 12h], ax
ega_decode_next_8:
    mov bx, 0
    mov ax, word ptr es:[di + 1eh]
    mov es, ax
    mov di, dx
    mov ax, word ptr [si + 42h]
    mov word ptr [bp - 14h], ax
    add si, word ptr 80h
    cld
ega_decode_loop_1:
    mov cx, 1
    lodsb
    mov ah, al
    and ah, 0c0h
    cmp ah, 0c0h
    jne ega_decode_next_9
    mov cl, al
    sub cl, 0c0h
    lodsb
ega_decode_next_9:
    cmp bx, word ptr [bp - 10h]
    jb ega_decode_next_10
    ja ega_decode_next_11
    cmp word ptr [bp - 0eh], 1
    jne ega_decode_next_10
    push ax
    mov al, 8
    mov dx, 3ceh
    out dx, al
    inc dx
    mov al, byte ptr [bp - 0ch]
    out dx, al
    mov al, byte ptr es:[bx + di]
    pop ax
    mov byte ptr es:[bx + di], al
    push ax
    mov al, 8
    mov dx, 3ceh
    out dx, al
    inc dx
    mov al, 0ffh
    out dx, al
    pop ax
    jmp short ega_decode_next_11
ega_decode_next_10:
    mov byte ptr es:[bx + di], al
ega_decode_next_11:
    inc bx
    cmp bx, word ptr [bp - 14h]
    jne ega_decode_next_13
    xor bx, bx
    mov dx, word ptr [bp - 1ah]
    shl byte ptr [bp - 18h], 1
    cmp byte ptr [bp - 18h], dl
    jbe ega_decode_next_12
    mov dx, word ptr [bp - 1ch]
    mov byte ptr [bp - 18h], dl
    add di, word ptr [bp - 16h]
    dec word ptr [bp - 12h]
    je ega_decode_next_15
ega_decode_next_12:
    push ax
    mov al, 2
    mov dx, 3c4h
    out dx, al
    inc dx
    mov al, byte ptr [bp - 18h]
    out dx, al
    pop ax
ega_decode_next_13:
    loop ega_decode_next_9
    cmp si, word ptr [bp - 0ah]
    jbe ega_decode_next_14
    push si
    call far ptr PcxRefillReadBuffer
    mov si, ax
    jae ega_decode_next_14
    mov word ptr [bp - 2], 0fffdh
    jmp short ega_decode_done_1
ega_decode_next_14:
    jmp near ptr ega_decode_loop_1
ega_decode_next_15:
    mov al, 2
    mov dx, 3c4h
    out dx, al
    inc dx
    mov al, 0ffh
    out dx, al
    mov word ptr [bp - 2], 0
ega_decode_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxEgaDecodeContinuation endp

; pcx vga 256 decode continuation
; Far-jump continuation: BP and saved registers belong to PcxDisplayBuffer.
; Pcx vga 256 decode continuation. RLE-decodes a PCX image using the PcxDisplayBuffer frame.
PcxVga256DecodeContinuation proc far
    mov ax, word ptr es:[di + 18h]
    mov word ptr [bp - 16h], ax
    mov ax, word ptr [si + 8]
    sub ax, word ptr [si + 4]
    inc ax
    mov bx, word ptr [bp + 0ah]
    add bx, ax
    cmp bx, word ptr es:[di + 18h]
    jbe vga_256_decode_next_1
    mov ax, word ptr es:[di + 18h]
    sub ax, word ptr [bp + 0ah]
vga_256_decode_next_1:
    dec ax
    mov word ptr [bp - 10h], ax
    mov ax, word ptr [bp + 8]
    xchg ah, al
    mov dx, ax
    shr ax, 1
    shr ax, 1
    add dx, ax
    mov ax, word ptr [bp + 0ah]
    add dx, ax
    mov ax, word ptr [si + 0ah]
    sub ax, word ptr [si + 6]
    inc ax
    mov word ptr [bp - 12h], ax
    mov bx, word ptr [bp + 8]
    add bx, ax
    cmp bx, word ptr es:[di + 1ah]
    jbe vga_256_decode_next_2
    mov ax, word ptr es:[di + 1ah]
    sub ax, word ptr [bp + 8]
    inc ax
    mov word ptr [bp - 12h], ax
vga_256_decode_next_2:
    mov bx, 0
    mov ax, word ptr es:[di + 1eh]
    mov es, ax
    mov di, dx
    mov ax, word ptr [si + 42h]
    mov word ptr [bp - 14h], ax
    add si, word ptr 80h
    cld
vga_256_decode_loop_1:
    mov cx, 1
    lodsb
    mov ah, al
    and ah, 0c0h
    cmp ah, 0c0h
    jne vga_256_decode_next_3
    mov cl, al
    sub cl, 0c0h
    lodsb
vga_256_decode_next_3:
    cmp bx, word ptr [bp - 10h]
    ja vga_256_decode_next_4
    mov byte ptr es:[bx + di], al
vga_256_decode_next_4:
    inc bx
    cmp bx, word ptr [bp - 14h]
    jne vga_256_decode_next_5
    xor bx, bx
    add di, word ptr [bp - 16h]
    dec word ptr [bp - 12h]
    je vga_256_decode_next_7
vga_256_decode_next_5:
    loop vga_256_decode_next_3
    cmp si, word ptr [bp - 0ah]
    jbe vga_256_decode_next_6
    push si
    call far ptr PcxRefillReadBuffer
    mov si, ax
    jae vga_256_decode_next_6
    mov word ptr [bp - 2], 0fffdh
    jmp short vga_256_decode_done_1
vga_256_decode_next_6:
    jmp short vga_256_decode_loop_1
vga_256_decode_next_7:
    mov word ptr [bp - 2], 0
vga_256_decode_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxVga256DecodeContinuation endp

; pcx hercules decode continuation
; Far-jump continuation: BP and saved registers belong to PcxDisplayBuffer.
; Pcx hercules decode continuation. RLE-decodes a PCX image using the PcxDisplayBuffer.
PcxHerculesDecodeContinuation proc far
    mov ax, word ptr [si + 8]
    sub ax, word ptr [si + 4]
    inc ax
    mov bx, word ptr [bp + 0ah]
    add bx, ax
    cmp bx, word ptr es:[di + 18h]
    jbe hercules_decode_next_1
    mov ax, word ptr es:[di + 18h]
    sub ax, word ptr [bp + 0ah]
    inc ax
hercules_decode_next_1:
    mov bl, 8
    div bl
    mov cl, ah
    xor ah, ah
    mov word ptr [bp - 10h], ax
    dec word ptr [bp - 10h]
    mov word ptr [bp - 0eh], 0
    cmp cl, 0
    je hercules_decode_next_2
    mov word ptr [bp - 0eh], 1
    mov al, 80h
    dec cl
    sar al, cl
    mov byte ptr [bp - 0ch], al
    inc word ptr [bp - 10h]
hercules_decode_next_2:
    mov ax, word ptr [bp + 8]
    xor ah, ah
    and al, 3
    mov word ptr [bp - 6], ax
    mov ax, word ptr es:[di + 20h]
    mov bx, word ptr [bp + 6]
    mul bx
    mov cx, ax
    mov ax, word ptr [bp + 8]
    mov bx, word ptr [bp + 0ah]
    shr ax, 1
    rcr bx, 1
    shr ax, 1
    rcr bx, 1
    shr bx, 1
    mov ah, 5ah
    mul ah
    add bx, ax
    add cx, bx
    mov ax, word ptr [si + 0ah]
    sub ax, word ptr [si + 6]
    inc ax
    mov word ptr [bp - 12h], ax
    mov bx, word ptr [bp + 8]
    add bx, ax
    cmp bx, word ptr es:[di + 1ah]
    jbe hercules_decode_next_3
    mov ax, word ptr es:[di + 1ah]
    sub ax, word ptr [bp + 8]
    inc ax
    mov word ptr [bp - 12h], ax
hercules_decode_next_3:
    mov bx, 0
    mov dx, word ptr [bp - 6]
    mov ax, word ptr es:[di + 1eh]
    mov es, ax
    mov di, cx
    mov ax, word ptr [si + 42h]
    mov word ptr [bp - 14h], ax
    add si, word ptr 80h
    cld
hercules_decode_loop_1:
    mov cx, 1
    lodsb
    mov ah, al
    and ah, 0c0h
    cmp ah, 0c0h
    jne hercules_decode_next_4
    mov cl, al
    sub cl, 0c0h
    lodsb
hercules_decode_next_4:
    cmp bl, byte ptr [bp - 10h]
    jb hercules_decode_next_5
    ja hercules_decode_next_6
    cmp word ptr [bp - 0eh], 1
    jne hercules_decode_next_5
    push ax
    mov ah, byte ptr es:[bx + di]
    or ah, byte ptr [bp - 0ch]
    sub ah, byte ptr [bp - 0ch]
    and al, byte ptr [bp - 0ch]
    or al, ah
    mov byte ptr es:[bx + di], al
    pop ax
    jmp short hercules_decode_next_6
hercules_decode_next_5:
    mov byte ptr es:[bx + di], al
hercules_decode_next_6:
    inc bx
    cmp bx, word ptr [bp - 14h]
    jne hercules_decode_next_8
    xor bx, bx
    dec word ptr [bp - 12h]
    je hercules_decode_next_10
    inc dx
    cmp dx, 4
    jb hercules_decode_next_7
    sub di, word ptr 5fa6h
    xor dx, dx
    jmp short hercules_decode_next_8
hercules_decode_next_7:
    add di, word ptr 2000h
hercules_decode_next_8:
    loop hercules_decode_next_4
    cmp si, word ptr [bp - 0ah]
    jbe hercules_decode_next_9
    push si
    call far ptr PcxRefillReadBuffer
    mov si, ax
    jae hercules_decode_next_9
    mov word ptr [bp - 2], 0fffdh
    jmp short hercules_decode_done_1
hercules_decode_next_9:
    jmp short hercules_decode_loop_1
hercules_decode_next_10:
    mov word ptr [bp - 2], 0
hercules_decode_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxHerculesDecodeContinuation endp

; pcx paradise decode continuation
; Far-jump continuation: BP and saved registers belong to PcxDisplayBuffer.
; Pcx paradise decode continuation. RLE-decodes a PCX image using the PcxDisplayBuffer.
PcxParadiseDecodeContinuation proc far
    mov ax, word ptr es:[di + 18h]
    mov word ptr [bp - 16h], ax
    mov ax, word ptr [si + 8]
    sub ax, word ptr [si + 4]
    inc ax
    mov bx, word ptr [bp + 0ah]
    add bx, ax
    cmp bx, word ptr es:[di + 18h]
    jbe paradise_decode_next_1
    mov ax, word ptr es:[di + 18h]
    sub ax, word ptr [bp + 0ah]
paradise_decode_next_1:
    dec ax
    mov word ptr [bp - 10h], ax
    mov ax, word ptr [bp + 8]
    mov bx, ax
    mov cl, 5
    shr bx, cl
    mov byte ptr [bp - 1eh], bl
    shl bx, cl
    sub ax, bx
    xchg ah, al
    shl ax, 1
    mov dx, ax
    shr ax, 1
    shr ax, 1
    add dx, ax
    mov ax, word ptr [bp + 0ah]
    add dx, ax
    mov ax, word ptr [si + 0ah]
    sub ax, word ptr [si + 6]
    inc ax
    mov word ptr [bp - 12h], ax
    mov bx, word ptr [bp + 8]
    add bx, ax
    cmp bx, word ptr es:[di + 1ah]
    jbe paradise_decode_next_2
    mov ax, word ptr es:[di + 1ah]
    sub ax, word ptr [bp + 8]
    inc ax
    mov word ptr [bp - 12h], ax
paradise_decode_next_2:
    mov bx, 0
    mov ax, word ptr es:[di + 1eh]
    mov es, ax
    mov di, dx
    mov ax, word ptr [si + 42h]
    mov word ptr [bp - 14h], ax
    add si, word ptr 80h
    cld
    mov al, 0fh
    mov dx, 3ceh
    out dx, al
    inc dx
    mov al, 5
    out dx, al
    mov al, byte ptr [bp - 1eh]
    mov ah, al
    shl al, 1
    shl al, 1
    add al, ah
    mov byte ptr [bp - 1eh], al
    mov al, 9
    mov dx, 3ceh
    out dx, al
    inc dx
    mov al, byte ptr [bp - 1eh]
    out dx, al
paradise_decode_loop_1:
    mov cx, 1
    lodsb
    mov ah, al
    and ah, 0c0h
    cmp ah, 0c0h
    jne paradise_decode_next_3
    mov cl, al
    sub cl, 0c0h
    lodsb
paradise_decode_next_3:
    cmp bx, word ptr [bp - 10h]
    ja paradise_decode_next_4
    mov byte ptr es:[bx + di], al
paradise_decode_next_4:
    inc bx
    cmp bx, word ptr [bp - 14h]
    jne paradise_decode_next_5
    xor bx, bx
    add di, word ptr [bp - 16h]
    dec word ptr [bp - 12h]
    je paradise_decode_next_7
    cmp di, word ptr 5000h
    jb paradise_decode_next_5
    push ax
    push bx
    mov bh, byte ptr [bp - 1eh]
    add bh, 5
    mov byte ptr [bp - 1eh], bh
    mov al, 9
    mov dx, 3ceh
    out dx, al
    inc dx
    mov al, bh
    out dx, al
    pop bx
    pop ax
    mov di, word ptr [bp + 0ah]
paradise_decode_next_5:
    loop paradise_decode_next_3
    cmp si, word ptr [bp - 0ah]
    jbe paradise_decode_next_6
    push si
    call far ptr PcxRefillReadBuffer
    mov si, ax
    jae paradise_decode_next_6
    mov word ptr [bp - 2], 0fffdh
    jmp short paradise_decode_next_8
paradise_decode_next_6:
    jmp short paradise_decode_loop_1
paradise_decode_next_7:
    mov word ptr [bp - 2], 0
paradise_decode_next_8:
    mov al, 9
    mov dx, 3ceh
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    mov al, 0fh
    mov dx, 3ceh
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxParadiseDecodeContinuation endp

; pcx tseng decode continuation
; Far-jump continuation: BP and saved registers belong to PcxDisplayBuffer.
; Pcx tseng decode continuation. RLE-decodes a PCX image using the PcxDisplayBuffer frame.
PcxTsengDecodeContinuation proc far
    mov ax, word ptr [si + 8]
    sub ax, word ptr [si + 4]
    inc ax
    mov bx, word ptr [bp + 0ah]
    add bx, ax
    cmp bx, word ptr es:[di + 18h]
    jbe tseng_decode_next_1
    mov ax, word ptr es:[di + 18h]
    sub ax, word ptr [bp + 0ah]
tseng_decode_next_1:
    dec ax
    mov word ptr [bp - 10h], ax
    mov ax, word ptr es:[di + 18h]
    mov word ptr [bp - 16h], ax
    mov bx, word ptr [bp + 8]
    mul bx
    mov bx, word ptr [bp + 0ah]
    add ax, bx
    adc dx, 0
    mov byte ptr [bp - 1eh], dl
    mov dx, ax
    mov ax, word ptr [si + 0ah]
    sub ax, word ptr [si + 6]
    inc ax
    mov word ptr [bp - 12h], ax
    mov bx, word ptr [bp + 8]
    add bx, ax
    cmp bx, word ptr es:[di + 1ah]
    jbe tseng_decode_next_2
    mov ax, word ptr es:[di + 1ah]
    sub ax, word ptr [bp + 8]
    inc ax
    mov word ptr [bp - 12h], ax
tseng_decode_next_2:
    mov ax, word ptr es:[di + 1eh]
    mov es, ax
    mov di, dx
    push ax
    mov al, byte ptr [bp - 1eh]
    mov ah, al
    shl ah, 1
    shl ah, 1
    shl ah, 1
    or al, ah
    or al, 40h
    mov dx, 3cdh
    out dx, al
    pop ax
    mov ax, word ptr [si + 42h]
    mov word ptr [bp - 14h], ax
    sub word ptr [bp - 16h], ax
    xor bx, bx
    add si, word ptr 80h
    cld
tseng_decode_loop_1:
    mov cx, 1
    lodsb
    mov ah, al
    and ah, 0c0h
    cmp ah, 0c0h
    jne tseng_decode_next_3
    mov cl, al
    sub cl, 0c0h
    lodsb
tseng_decode_next_3:
    cmp bx, word ptr [bp - 10h]
    ja tseng_decode_next_4
    mov byte ptr es:[di], al
tseng_decode_next_4:
    inc di
    jne tseng_decode_next_5
    inc byte ptr [bp - 1eh]
    push ax
    mov al, byte ptr [bp - 1eh]
    mov ah, al
    shl ah, 1
    shl ah, 1
    shl ah, 1
    or al, ah
    or al, 40h
    mov dx, 3cdh
    out dx, al
    pop ax
tseng_decode_next_5:
    inc bx
    cmp bx, word ptr [bp - 14h]
    jne tseng_decode_next_7
    xor bx, bx
    add di, word ptr [bp - 16h]
    jae tseng_decode_next_6
    inc byte ptr [bp - 1eh]
    push ax
    mov al, byte ptr [bp - 1eh]
    mov ah, al
    shl ah, 1
    shl ah, 1
    shl ah, 1
    or al, ah
    or al, 40h
    mov dx, 3cdh
    out dx, al
    pop ax
tseng_decode_next_6:
    dec word ptr [bp - 12h]
    je tseng_decode_next_9
tseng_decode_next_7:
    loop tseng_decode_next_3
    cmp si, word ptr [bp - 0ah]
    jbe tseng_decode_next_8
    push si
    call far ptr PcxRefillReadBuffer
    mov si, ax
    jae tseng_decode_next_8
    mov word ptr [bp - 2], 0fffdh
    jmp short tseng_decode_done_1
tseng_decode_next_8:
    jmp short tseng_decode_loop_1
tseng_decode_next_9:
    push ax
    mov al, 0
    mov ah, al
    shl ah, 1
    shl ah, 1
    shl ah, 1
    or al, ah
    or al, 40h
    mov dx, 3cdh
    out dx, al
    pop ax
    mov word ptr [bp - 2], 0
tseng_decode_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxTsengDecodeContinuation endp

; pcx video7 decode continuation
; Far-jump continuation: BP and saved registers belong to PcxDisplayBuffer.
; Pcx video7 decode continuation. RLE-decodes a PCX image using the PcxDisplayBuffer frame.
PcxVideo7DecodeContinuation proc far
    mov ax, word ptr es:[di + 18h]
    mov word ptr [bp - 16h], ax
    mov ax, word ptr [si + 8]
    sub ax, word ptr [si + 4]
    inc ax
    mov bx, word ptr [bp + 0ah]
    add bx, ax
    cmp bx, word ptr es:[di + 18h]
    jbe video7_decode_next_1
    mov ax, word ptr es:[di + 18h]
    sub ax, word ptr [bp + 0ah]
video7_decode_next_1:
    dec ax
    mov word ptr [bp - 10h], ax
    mov ax, word ptr es:[di + 18h]
    mov word ptr [bp - 16h], ax
    mov bx, word ptr [bp + 8]
    mul bx
    mov bx, word ptr [bp + 0ah]
    add ax, bx
    adc dx, 0
    mov byte ptr [bp - 1eh], dl
    mov dx, ax
    mov ax, word ptr [si + 0ah]
    sub ax, word ptr [si + 6]
    inc ax
    mov word ptr [bp - 12h], ax
    mov bx, word ptr [bp + 8]
    add bx, ax
    cmp bx, word ptr es:[di + 1ah]
    jbe video7_decode_next_2
    mov ax, word ptr es:[di + 1ah]
    sub ax, word ptr [bp + 8]
    inc ax
    mov word ptr [bp - 12h], ax
video7_decode_next_2:
    mov ax, word ptr es:[di + 1eh]
    mov es, ax
    mov di, dx
    mov al, 6
    mov dx, 3c4h
    out dx, al
    inc dx
    mov al, 0eah
    out dx, al
    push ax
    push bx
    mov bh, byte ptr [bp - 1eh]
    mov bl, bh
    and bl, 1
    mov al, 0f9h
    mov dx, 3c4h
    out dx, al
    inc dx
    mov al, bl
    out dx, al
    mov bl, bh
    and bl, 2
    shl bl, 1
    shl bl, 1
    shl bl, 1
    shl bl, 1
    mov dx, 3cch
    in al, dx
    and al, 0dfh
    or bl, al
    mov al, bl
    mov dx, 3c2h
    out dx, al
    mov al, 0f6h
    mov dx, 3c4h
    out dx, al
    inc dx
    in al, dx
    mov bl, bh
    shr bl, 1
    shr bl, 1
    add bl, 7
    not bl
    and bl, 5
    and al, 0f0h
    or al, bl
    out dx, al
    pop bx
    pop ax
    mov ax, word ptr [si + 42h]
    mov word ptr [bp - 14h], ax
    sub word ptr [bp - 16h], ax
    xor bx, bx
    add si, word ptr 80h
    cld
video7_decode_loop_1:
    mov cx, 1
    lodsb
    mov ah, al
    and ah, 0c0h
    cmp ah, 0c0h
    jne video7_decode_next_3
    mov cl, al
    sub cl, 0c0h
    lodsb
video7_decode_next_3:
    cmp bx, word ptr [bp - 10h]
    ja video7_decode_next_4
    mov byte ptr es:[di], al
video7_decode_next_4:
    inc di
    jne video7_decode_next_5
    inc byte ptr [bp - 1eh]
    push ax
    push bx
    mov bh, byte ptr [bp - 1eh]
    mov bl, bh
    and bl, 1
    mov al, 0f9h
    mov dx, 3c4h
    out dx, al
    inc dx
    mov al, bl
    out dx, al
    mov bl, bh
    and bl, 2
    shl bl, 1
    shl bl, 1
    shl bl, 1
    shl bl, 1
    mov dx, 3cch
    in al, dx
    and al, 0dfh
    or bl, al
    mov al, bl
    mov dx, 3c2h
    out dx, al
    mov al, 0f6h
    mov dx, 3c4h
    out dx, al
    inc dx
    in al, dx
    mov bl, bh
    shr bl, 1
    shr bl, 1
    add bl, 7
    not bl
    and bl, 5
    and al, 0f0h
    or al, bl
    out dx, al
    pop bx
    pop ax
video7_decode_next_5:
    inc bx
    cmp bx, word ptr [bp - 14h]
    jne video7_decode_next_7
    xor bx, bx
    add di, word ptr [bp - 16h]
    jae video7_decode_next_6
    inc byte ptr [bp - 1eh]
    push ax
    push bx
    mov bh, byte ptr [bp - 1eh]
    mov bl, bh
    and bl, 1
    mov al, 0f9h
    mov dx, 3c4h
    out dx, al
    inc dx
    mov al, bl
    out dx, al
    mov bl, bh
    and bl, 2
    shl bl, 1
    shl bl, 1
    shl bl, 1
    shl bl, 1
    mov dx, 3cch
    in al, dx
    and al, 0dfh
    or bl, al
    mov al, bl
    mov dx, 3c2h
    out dx, al
    mov al, 0f6h
    mov dx, 3c4h
    out dx, al
    inc dx
    in al, dx
    mov bl, bh
    shr bl, 1
    shr bl, 1
    add bl, 7
    not bl
    and bl, 5
    and al, 0f0h
    or al, bl
    out dx, al
    pop bx
    pop ax
video7_decode_next_6:
    dec word ptr [bp - 12h]
    je video7_decode_next_10
video7_decode_next_7:
    dec cx
    je video7_decode_next_8
    jmp near ptr video7_decode_next_3
video7_decode_next_8:
    cmp si, word ptr [bp - 0ah]
    jbe video7_decode_next_9
    push si
    call far ptr PcxRefillReadBuffer
    mov si, ax
    jae video7_decode_next_9
    mov word ptr [bp - 2], 0fffdh
    jmp short video7_decode_done_1
video7_decode_next_9:
    jmp near ptr video7_decode_loop_1
video7_decode_next_10:
    push ax
    push bx
    mov bh, 0
    mov bl, bh
    and bl, 1
    mov al, 0f9h
    mov dx, 3c4h
    out dx, al
    inc dx
    mov al, bl
    out dx, al
    mov bl, bh
    and bl, 2
    shl bl, 1
    shl bl, 1
    shl bl, 1
    shl bl, 1
    mov dx, 3cch
    in al, dx
    and al, 0dfh
    or bl, al
    mov al, bl
    mov dx, 3c2h
    out dx, al
    mov al, 0f6h
    mov dx, 3c4h
    out dx, al
    inc dx
    in al, dx
    mov bl, bh
    shr bl, 1
    shr bl, 1
    add bl, 7
    not bl
    and bl, 5
    and al, 0f0h
    or al, bl
    out dx, al
    pop bx
    pop ax
    mov al, 6
    mov dx, 3c4h
    out dx, al
    inc dx
    mov al, 0aeh
    out dx, al
    mov word ptr [bp - 2], 0
video7_decode_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxVideo7DecodeContinuation endp

; DOS file reading and buffer refill.
; pcx decode or print buffer
; The original caller enters at INT3, before the BP prologue.
; Converts a Pascal filename, opens/reads/closes it with DOS INT 21h.
PcxDisplayFile proc far
    int 3
    push bp
    mov bp, sp
    sub sp, word ptr 84h
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    push ds
    cld
    mov ax, word ptr [bp + 0eh]
    mov ds, ax
    mov ax, ss
    mov es, ax
    mov si, word ptr [bp + 0ch]
    mov cl, byte ptr [si]
    xor ch, ch
    inc si
    mov di, bp
    sub di, word ptr 84h
    mov word ptr [bp + 0eh], es
    mov word ptr [bp + 0ch], di
    rep movsb
    mov byte ptr es:[di], 0
    pop ds
    push ds
    mov dx, word ptr [bp + 0ch]
    mov ax, word ptr [bp + 0eh]
    mov ds, ax
    mov al, 0
    mov ah, 3dh
    int 21h
    pop ds
    mov word ptr [PcxReadState + 06h], ax
    jae decode_or_print_buffer_next_1
    mov word ptr [bp - 2], 0ffffh
    jmp short decode_or_print_buffer_next_5
decode_or_print_buffer_next_1:
    mov ax, seg PcxSelectedDisplay
    mov es, ax
    mov di, offset PcxDefaultReadBuffer
    cmp word ptr [PcxReadState + 02h], -1
    je decode_or_print_buffer_next_2
    mov ax, word ptr [PcxReadState + 02h]
    mov es, ax
    mov di, word ptr [PcxReadState + 04h]
decode_or_print_buffer_next_2:
    mov word ptr [PcxReadState + 08h], 0
    mov word ptr [PcxReadState + 0Ah], 0
    push ds
    mov bx, word ptr [PcxReadState + 06h]
    mov cx, word ptr [PcxReadState]
    mov dx, di
    mov ax, es
    mov ds, ax
    mov ah, 3fh
    int 21h
    pop ds
    jae decode_or_print_buffer_next_3
    mov word ptr [bp - 2], 0fffdh
    jmp short decode_or_print_buffer_next_4
decode_or_print_buffer_next_3:
    mov ax, es
    push ax
    push di
    mov ax, word ptr [PcxReadState]
    sub ax, 0ah
    push ax
    mov ax, word ptr [bp + 0ah]
    push ax
    mov ax, word ptr [bp + 8]
    push ax
    mov ax, word ptr [bp + 6]
    push ax
    call far ptr PcxDisplayBuffer
    mov word ptr [bp - 2], ax
decode_or_print_buffer_next_4:
    mov bx, word ptr [PcxReadState + 06h]
    mov ah, 3eh
    int 21h
decode_or_print_buffer_next_5:
    mov word ptr [PcxReadState + 06h], 0ffffh
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ah
PcxDisplayFile endp

; pcx flush print buffer
; Advances the tracked file position, seeks and reads more bytes with DOS INT 21h AH=42h/3Fh.
PcxRefillReadBuffer proc far
    push bp
    mov bp, sp
    sub sp, 2
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    push bx
    push cx
    push dx
    cmp word ptr [PcxReadState + 06h], -1
    jne flush_print_buffer_next_1
    stc
    jmp short flush_print_buffer_done_1
flush_print_buffer_next_1:
    mov ax, ds
    mov es, ax
    mov di, offset PcxDefaultReadBuffer
    cmp word ptr [PcxReadState + 02h], -1
    je flush_print_buffer_next_2
    mov ax, word ptr [PcxReadState + 02h]
    mov es, ax
    mov di, word ptr [PcxReadState + 04h]
flush_print_buffer_next_2:
    mov ax, word ptr [bp + 6]
    sub ax, di
    add word ptr [PcxReadState + 0Ah], ax
    jae flush_print_buffer_next_3
    add word ptr [PcxReadState + 08h], 1
flush_print_buffer_next_3:
    mov bx, word ptr [PcxReadState + 06h]
    mov cx, word ptr [PcxReadState + 08h]
    mov dx, word ptr [PcxReadState + 0Ah]
    mov al, 0
    mov ah, 42h
    int 21h
    push ds
    mov bx, word ptr [PcxReadState + 06h]
    mov cx, word ptr [PcxReadState]
    mov dx, di
    mov ax, es
    mov ds, ax
    mov ah, 3fh
    int 21h
    pop ds
    mov word ptr [bp - 2], di
flush_print_buffer_done_1:
    pop dx
    pop cx
    pop bx
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 2
PcxRefillReadBuffer endp

; Printer setup and raster output.
; Pcx configure printer.
PcxConfigurePrinter proc far
    push bp
    mov bp, sp
    sub sp, 2
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov ax, word ptr [bp + 0eh]
    cmp ax, 0
    jb configure_printer_error_1
    cmp ax, 1
    jbe configure_printer_next_1
configure_printer_error_1:
    mov word ptr [bp - 2], 0fff0h
    jmp short configure_printer_done_1
configure_printer_next_1:
    mov word ptr [PcxPrinterDeviceClass], ax
    mov ax, word ptr [bp + 10h]
    cmp ax, 0
    jb configure_printer_error_2
    cmp ax, 2
    jbe configure_printer_next_2
configure_printer_error_2:
    mov word ptr [bp - 2], 0ffefh
    jmp short configure_printer_done_1
configure_printer_next_2:
    mov word ptr [PcxPrinterState], ax
    mov ax, word ptr [bp + 0ch]
    mov word ptr [PcxPrinterResolutionClass], ax
    mov ax, word ptr [bp + 0ah]
    mov word ptr [PcxPrinterState + 02h], ax
    mov ax, word ptr [bp + 6]
    mov word ptr [PcxPrinterState + 04h], ax
    mov ax, word ptr [bp + 8]
    mov word ptr [PcxPrinterState + 06h], ax
    mov word ptr [bp - 2], 0
configure_printer_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxConfigurePrinter endp

; Pcx begin printer image.
PcxBeginPrinterImage proc far
    push bp
    mov bp, sp
    sub sp, 2
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov ax, seg PcxSelectedDisplay
    mov es, ax
    mov byte ptr [PcxPrinterState + 0Ah], 1
    mov ax, word ptr [bp + 0ah]
    mov cx, word ptr [PcxPrinterState + 02h]
    cmp cx, 0
    je begin_printer_image_next_4
    cmp cx, 1
    jne begin_printer_image_next_1
    shr ax, 1
    shr ax, 1
    mov cx, ax
    add ax, cx
    add ax, cx
    jmp short begin_printer_image_next_4
begin_printer_image_next_1:
    cmp cx, 2
    jne begin_printer_image_next_2
    shr ax, 1
    jmp short begin_printer_image_next_4
begin_printer_image_next_2:
    cmp cx, 3
    jne begin_printer_image_next_3
    shr ax, 1
    shr ax, 1
    jmp short begin_printer_image_next_4
begin_printer_image_next_3:
    cmp cx, 4
    jne begin_printer_image_next_4
    shl ax, 1
begin_printer_image_next_4:
    mov word ptr [PcxPrinterState + 08h], ax
    cmp word ptr [PcxPrinterResolutionClass], 1
    je begin_printer_image_next_5
    cmp word ptr [PcxPrinterResolutionClass], 2
    je begin_printer_image_next_5
    shr ax, 1
begin_printer_image_next_5:
    mov bx, 0
    push bx
    push ax
    push es
    mov di, offset PcxPrinterState + 05Dh
    push di
    call far ptr PcxFormatUnsignedDecimal
    mov di, offset PcxPrinterState + 059h
    add al, 3
    mov byte ptr es:[di], al
    mov ax, 0
    push ax
    mov ax, word ptr [bp + 8]
    push ax
    push es
    mov di, offset PcxPrinterState + 02Ch
    push di
    call far ptr PcxFormatUnsignedDecimal
    add di, ax
    mov byte ptr es:[di], 78h
    inc ax
    inc di
    push ax
    mov ax, 0
    push ax
    mov ax, word ptr [bp + 6]
    push ax
    push es
    push di
    call far ptr PcxFormatUnsignedDecimal
    pop bx
    add di, ax
    mov byte ptr es:[di], 59h
    inc ax
    add ax, bx
    mov di, offset PcxPrinterState + 028h
    add al, 3
    mov byte ptr es:[di], al
    mov dx, word ptr [PcxPrinterState]
    mov ah, 2
    int 17h
    test ah, 29h
    je begin_printer_image_next_6
    mov word ptr [bp - 2], 0ffeeh
    jmp short begin_printer_image_done_1
begin_printer_image_next_6:
    cmp word ptr [PcxPrinterState + 06h], 1
    jne begin_printer_image_next_7
    mov si, offset PcxPrinterState + 0Bh
    call far ptr PcxSendPrinterString
    mov si, offset PcxPrinterState + 0Eh
    call far ptr PcxSendPrinterString
begin_printer_image_next_7:
    mov si, offset PcxPrinterState + 014h
    call far ptr PcxSendPrinterString
    mov si, offset PcxPrinterState + 028h
    call far ptr PcxSendPrinterString
    cmp word ptr [PcxPrinterResolutionClass], 1
    je begin_printer_image_next_9
    cmp word ptr [PcxPrinterResolutionClass], 2
    je begin_printer_image_next_8
    mov si, offset PcxPrinterState + 03Eh
    call far ptr PcxSendPrinterString
    jmp short begin_printer_image_next_10
begin_printer_image_next_8:
    mov si, offset PcxPrinterState + 036h
    call far ptr PcxSendPrinterString
    jmp short begin_printer_image_next_10
begin_printer_image_next_9:
    mov si, offset PcxPrinterState + 046h
    call far ptr PcxSendPrinterString
begin_printer_image_next_10:
    mov si, offset PcxPrinterState + 04Eh
    call far ptr PcxSendPrinterString
begin_printer_image_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 6
PcxBeginPrinterImage endp

; Pcx end printer image.
PcxEndPrinterImage proc far
    push bp
    mov bp, sp
    sub sp, 2
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov si, offset PcxPrinterState + 054h
    call far ptr PcxSendPrinterString
    cmp word ptr [PcxPrinterState + 04h], 1
    jne end_printer_image_done_1
    mov si, offset PcxPrinterState + 022h
    call far ptr PcxSendPrinterString
end_printer_image_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf
PcxEndPrinterImage endp

; Pcx print buffer.
PcxPrintBuffer proc far
    push bp
    mov bp, sp
    sub sp, 0eh
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov ax, word ptr [bp + 0eh]
    mov ds, ax
    mov si, word ptr [bp + 0ch]
    mov ax, seg PcxSelectedDisplay
    mov es, ax
    mov word ptr [bp - 0ch], si
    mov bx, word ptr [bp + 0ah]
    add bx, word ptr [bp - 0ch]
    dec bx
    mov word ptr [bp - 0eh], bx
    mov al, byte ptr [si]
    cmp al, 0ah
    je print_buffer_next_1
    mov word ptr [bp - 2], 0fffbh
    jmp near ptr print_buffer_done_1
print_buffer_next_1:
    cmp byte ptr [si + 41h], 1
    jne print_buffer_error_1
    cmp byte ptr [si + 3], 1
    jne print_buffer_error_1
    jmp short print_buffer_next_2
print_buffer_error_1:
    mov word ptr [bp - 2], 0ffedh
    jmp near ptr print_buffer_done_1
print_buffer_next_2:
    mov ax, word ptr [si + 8]
    sub ax, word ptr [si + 4]
    inc ax
    cwd
    mov bx, 8
    div bx
    mov cx, dx
    mov word ptr [bp - 8], ax
    dec word ptr [bp - 8]
    mov byte ptr [bp - 6], 0
    cmp cl, 0
    je print_buffer_next_3
    mov byte ptr [bp - 6], 1
    mov al, 80h
    dec cl
    sar al, cl
    mov byte ptr [bp - 4], al
    inc word ptr [bp - 8]
print_buffer_next_3:
    mov bx, word ptr [si + 0ah]
    sub bx, word ptr [si + 6]
    inc bx
    mov word ptr es:[PcxPrintedSourceRow], bx
    mov ax, word ptr [si + 42h]
    mov word ptr [bp - 0ah], ax
    push ax
    mov ax, word ptr [bp + 8]
    push ax
    mov ax, word ptr [bp + 6]
    push ax
    call far ptr PcxBeginPrinterImage
    mov ax, seg PcxSelectedDisplay
    mov es, ax
    mov di, offset PcxPrinterScanline
    mov ax, word ptr [bp + 0eh]
    mov ds, ax
    mov si, word ptr [bp + 0ch]
    add si, word ptr 80h
    mov bx, 0
    cld
print_buffer_loop_1:
    mov cx, 1
    lodsb
    mov ah, al
    and ah, 0c0h
    cmp ah, 0c0h
    jne print_buffer_next_4
    mov cl, al
    sub cl, 0c0h
    lodsb
print_buffer_next_4:
    cmp bx, word ptr [bp - 8]
    jb print_buffer_next_5
    ja print_buffer_next_6
    cmp byte ptr [bp - 6], 1
    jne print_buffer_next_5
    push ax
    mov ah, byte ptr [bp - 4]
    and al, ah
    xor ah, 0ffh
    or al, ah
    mov byte ptr es:[bx + di], al
    pop ax
    jmp short print_buffer_next_6
print_buffer_next_5:
    mov byte ptr es:[bx + di], al
print_buffer_next_6:
    inc bx
    cmp bx, word ptr [bp - 0ah]
    jne print_buffer_next_8
    mov byte ptr es:[bx + di - 1], 0ffh
    push ax
    push cx
    call far ptr PcxPrintScanline
    pop cx
    pop ax
    jae print_buffer_next_7
    mov word ptr [bp - 2], 0ffech
    jmp short print_buffer_next_11
print_buffer_next_7:
    xor bx, bx
    dec word ptr es:[PcxPrintedSourceRow]
    je print_buffer_next_10
print_buffer_next_8:
    loop print_buffer_next_4
    cmp si, word ptr [bp - 0eh]
    jb print_buffer_next_9
    push si
    call far ptr PcxRefillReadBuffer
    jb print_buffer_done_1
    mov si, ax
print_buffer_next_9:
    jmp short print_buffer_loop_1
print_buffer_next_10:
    mov word ptr [bp - 2], 0
print_buffer_next_11:
    call far ptr PcxEndPrinterImage
print_buffer_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ah
PcxPrintBuffer endp

; Pcx send printer string.
PcxSendPrinterString proc far
    lodsb
    mov cl, al
    xor ch, ch
    mov dx, word ptr [PcxPrinterState]
send_printer_string_loop_1:
    lodsb
    mov ah, 0
    int 17h
    loop send_printer_string_loop_1
    retf
PcxSendPrinterString endp

; Pcx print scanline.
PcxPrintScanline proc far
    push bp
    mov bp, sp
    sub sp, 4
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov word ptr [bp - 4], 0
    mov ax, seg PcxSelectedDisplay
    mov es, ax
    mov si, offset PcxPrinterScanline
    mov di, si
    cmp word ptr [PcxPrinterState + 02h], 0
    jne print_scanline_next_1
    jmp near ptr print_scanline_next_10
print_scanline_next_1:
    cmp word ptr [PcxPrinterState + 02h], 1
    je print_scanline_next_2
    jmp near ptr print_scanline_next_4
print_scanline_next_2:
    mov ax, word ptr [PcxPrintedSourceRow]
    and ax, 3
    cmp ax, 0
    jne print_scanline_next_3
    jmp near ptr print_scanline_next_15
print_scanline_next_3:
    mov cx, word ptr [PcxPrinterState + 08h]
print_scanline_loop_1:
    mov ah, byte ptr [si]
    and ah, 0e0h
    mov al, byte ptr [si]
    and al, 0eh
    shl al, 1
    or ah, al
    mov al, byte ptr [si + 1]
    and al, 0c0h
    rol al, 1
    rol al, 1
    or ah, al
    mov byte ptr [di], ah
    mov ah, byte ptr [si + 1]
    shl ah, 1
    shl ah, 1
    mov al, ah
    and ah, 80h
    and al, 38h
    shl al, 1
    or ah, al
    mov al, byte ptr [si + 2]
    and al, 0e0h
    shr al, 1
    shr al, 1
    shr al, 1
    shr al, 1
    or ah, al
    mov al, byte ptr [si + 2]
    and al, 8
    shr al, 1
    shr al, 1
    shr al, 1
    or ah, al
    mov byte ptr [di + 1], ah
    mov ah, byte ptr [si + 2]
    and ah, 6
    ror ah, 1
    ror ah, 1
    ror ah, 1
    mov al, byte ptr [si + 3]
    and al, 0e0h
    shr al, 1
    shr al, 1
    or ah, al
    mov al, byte ptr [si + 3]
    and al, 0eh
    shr al, 1
    or ah, al
    mov byte ptr [di + 2], ah
    add si, 4
    add di, 3
    sub cx, 3
    cmp cx, 0
    jg print_scanline_loop_1
    jmp near ptr print_scanline_next_10
print_scanline_next_4:
    cmp word ptr [PcxPrinterState + 02h], 2
    jne print_scanline_next_6
    mov ax, word ptr [PcxPrintedSourceRow]
    and ax, 1
    cmp ax, 0
    je print_scanline_next_5
    jmp near ptr print_scanline_next_15
print_scanline_next_5:
    mov cx, word ptr [PcxPrinterState + 08h]
print_scanline_loop_2:
    mov ah, byte ptr [si]
    and ah, 0c0h
    mov al, byte ptr [si]
    and al, 0ch
    shl al, 1
    shl al, 1
    or ah, al
    mov al, byte ptr [si + 1]
    and al, 0c0h
    shr al, 1
    shr al, 1
    shr al, 1
    shr al, 1
    or ah, al
    mov al, byte ptr [si + 1]
    and al, 0ch
    shr al, 1
    shr al, 1
    or ah, al
    mov byte ptr [di], ah
    add si, 2
    inc di
    loop print_scanline_loop_2
    jmp near ptr print_scanline_next_10
print_scanline_next_6:
    cmp word ptr [PcxPrinterState + 02h], 3
    jne print_scanline_next_8
    mov ax, word ptr [PcxPrintedSourceRow]
    and ax, 3
    cmp ax, 0
    je print_scanline_next_7
    jmp near ptr print_scanline_next_15
print_scanline_next_7:
    mov cx, word ptr [PcxPrinterState + 08h]
print_scanline_loop_3:
    mov ah, byte ptr [si]
    and ah, 80h
    mov al, byte ptr [si]
    and al, 8
    shl al, 1
    shl al, 1
    shl al, 1
    or ah, al
    mov al, byte ptr [si + 1]
    and al, 80h
    shr al, 1
    shr al, 1
    or ah, al
    mov al, byte ptr [si + 1]
    and al, 8
    shl al, 1
    or ah, al
    mov al, byte ptr [si + 2]
    and al, 80h
    shr al, 1
    shr al, 1
    shr al, 1
    shr al, 1
    or ah, al
    mov al, byte ptr [si + 2]
    and al, 8
    shr al, 1
    or ah, al
    mov al, byte ptr [si + 3]
    and al, 80h
    rol al, 1
    rol al, 1
    or ah, al
    mov al, byte ptr [si + 3]
    and al, 8
    shr al, 1
    shr al, 1
    shr al, 1
    or ah, al
    mov byte ptr [di], ah
    add si, 4
    inc di
    loop print_scanline_loop_3
    jmp short print_scanline_next_10
print_scanline_next_8:
    cmp word ptr [PcxPrinterState + 02h], 4
    je print_scanline_next_9
    jmp short print_scanline_next_10
print_scanline_next_9:
    mov cx, word ptr [PcxPrinterState + 08h]
print_scanline_loop_4:
    mov bx, cx
    dec bx
    mov dh, byte ptr [bx + si]
    shl bx, 1
    inc bx
    push cx
    mov cx, 2
print_scanline_loop_5:
    xor ax, ax
    mov dl, dh
    and dl, 1
    or al, dl
    shl dl, 1
    or al, dl
    mov dl, dh
    and dl, 2
    shl dl, 1
    or al, dl
    shl dl, 1
    or al, dl
    mov dl, dh
    and dl, 4
    shl dl, 1
    shl dl, 1
    or al, dl
    shl dl, 1
    or al, dl
    mov dl, dh
    and dl, 8
    shl dl, 1
    shl dl, 1
    shl dl, 1
    or al, dl
    shl dl, 1
    or al, dl
    mov byte ptr [bx + di], al
    dec bx
    shr dh, 1
    shr dh, 1
    shr dh, 1
    shr dh, 1
    loop print_scanline_loop_5
    pop cx
    loop print_scanline_loop_4
print_scanline_next_10:
    cmp word ptr [PcxPrinterResolutionClass], 1
    je print_scanline_next_12
    cmp word ptr [PcxPrinterResolutionClass], 2
    je print_scanline_next_12
    xor byte ptr [PcxPrinterState + 0Ah], 1
    cmp byte ptr [PcxPrinterState + 0Ah], 1
    jne print_scanline_next_11
    jmp near ptr print_scanline_next_15
print_scanline_next_11:
    mov si, offset PcxPrinterScanline
    mov di, si
    mov cx, word ptr [PcxPrinterState + 08h]
    shr cx, 1
print_scanline_loop_6:
    mov ah, byte ptr [si]
    and ah, 0c0h
    mov al, byte ptr [si]
    and al, 0ch
    shl al, 1
    shl al, 1
    or ah, al
    mov al, byte ptr [si + 1]
    and al, 0c0h
    shr al, 1
    shr al, 1
    shr al, 1
    shr al, 1
    or ah, al
    mov al, byte ptr [si + 1]
    and al, 0ch
    shr al, 1
    shr al, 1
    or ah, al
    mov byte ptr [di], ah
    add si, 2
    inc di
    loop print_scanline_loop_6
print_scanline_next_12:
    mov si, offset PcxPrinterState + 059h
    call far ptr PcxSendPrinterString
    mov al, 57h
    mov dx, word ptr [PcxPrinterState]
    mov ah, 0
    int 17h
    mov si, offset PcxPrinterScanline
    mov dx, word ptr [PcxPrinterState]
    mov cx, word ptr [PcxPrinterState + 08h]
    cmp word ptr [PcxPrinterResolutionClass], 1
    je print_scanline_next_13
    cmp word ptr [PcxPrinterResolutionClass], 2
    je print_scanline_next_13
    shr cx, 1
print_scanline_next_13:
    lodsb
    xor al, 0ffh
    mov ah, 0
    int 17h
    loop print_scanline_next_13
    cmp word ptr [PcxPrinterState + 02h], 4
    jne print_scanline_next_14
    inc word ptr [bp - 4]
    cmp word ptr [bp - 4], 2
    jae print_scanline_next_14
    jmp near ptr print_scanline_next_10
print_scanline_next_14:
    push bp
    mov ah, 1
    int 16h
    pop bp
    je print_scanline_next_15
    push bp
    mov ah, 0
    int 16h
    pop bp
    cmp al, 1bh
    jne print_scanline_next_15
    stc
    jmp short print_scanline_done_1
print_scanline_next_15:
    clc
print_scanline_done_1:
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf
PcxPrintScanline endp
    retf                    
; Decimal formatting and printer defaults.
; Unreachable second RETF retained from the object.

; Pcx format unsigned decimal.
PcxFormatUnsignedDecimal proc far
    push bp
    mov bp, sp
    sub sp, 4
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov ax, word ptr [bp + 8]
    mov es, ax
    mov di, word ptr [bp + 6]
    mov dx, word ptr [bp + 0ch]
    mov ax, word ptr [bp + 0ah]
    xor cx, cx
    xor si, si
    mov byte ptr [bp - 4], 30h
format_unsigned_decimal_loop_1:
    cmp dx, word ptr [si + PcxPrinterState + 06Bh]
    je format_unsigned_decimal_next_1
    jb format_unsigned_decimal_next_3
    jmp short format_unsigned_decimal_next_2
format_unsigned_decimal_next_1:
    cmp ax, word ptr [si + PcxPrinterState + 069h]
    jb format_unsigned_decimal_next_3
format_unsigned_decimal_next_2:
    sub ax, word ptr [si + PcxPrinterState + 069h]
    sbb dx, word ptr [si + PcxPrinterState + 06Bh]
    inc byte ptr [bp - 4]
    jmp short format_unsigned_decimal_loop_1
format_unsigned_decimal_next_3:
    cmp cx, 0
    jne format_unsigned_decimal_next_4
    cmp byte ptr [bp - 4], 30h
    je format_unsigned_decimal_next_5
format_unsigned_decimal_next_4:
    mov bl, byte ptr [bp - 4]
    mov byte ptr es:[di], bl
    inc cx
    inc di
format_unsigned_decimal_next_5:
    cmp si, 24h
    je format_unsigned_decimal_next_6
    mov byte ptr [bp - 4], 30h
    add si, 4
    jmp short format_unsigned_decimal_loop_1
format_unsigned_decimal_next_6:
    cmp cx, 0
    jne format_unsigned_decimal_next_7
    mov byte ptr es:[di], 30h
    inc cx
    inc di
format_unsigned_decimal_next_7:
    mov byte ptr es:[di], 24h
    mov word ptr [bp - 2], cx
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 8
PcxFormatUnsignedDecimal endp

; Pcx initialize printer state.
PcxInitializePrinterState proc far
    push bp
    mov bp, sp
    sub sp, 2
    push ds
    push es
    push si
    push di
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov word ptr [bp - 2], 0
    mov word ptr [PcxPrinterDeviceClass], 0
    mov word ptr [PcxPrinterResolutionClass], 1
    mov word ptr [PcxPrinterState], 0
    mov word ptr [PcxPrinterState + 02h], 0
    mov word ptr [PcxPrinterState + 04h], 1
    mov word ptr [PcxPrinterState + 06h], 1
    mov si, offset PcxPrinterState + 0Bh
    mov byte ptr [si], 2
    inc si
    mov byte ptr [si], 1bh
    inc si
    mov byte ptr [si], 45h
    inc si
    mov si, offset PcxPrinterState + 0Eh
    mov byte ptr [si], 5
    inc si
    mov byte ptr [si], 1bh
    inc si
    mov byte ptr [si], 26h
    inc si
    mov byte ptr [si], 6ch
    inc si
    mov byte ptr [si], 31h
    inc si
    mov byte ptr [si], 58h
    inc si
    mov si, offset PcxPrinterState + 014h
    mov byte ptr [si], 5
    inc si
    mov byte ptr [si], 1bh
    inc si
    mov byte ptr [si], 26h
    inc si
    mov byte ptr [si], 6ch
    inc si
    mov byte ptr [si], 30h
    inc si
    mov byte ptr [si], 4fh
    inc si
    mov si, offset PcxPrinterState + 01Ah
    mov byte ptr [si], 7
    inc si
    mov byte ptr [si], 1bh
    inc si
    mov byte ptr [si], 26h
    inc si
    mov byte ptr [si], 6ch
    inc si
    mov byte ptr [si], 32h
    inc si
    mov byte ptr [si], 45h
    inc si
    mov byte ptr [si], 1bh
    inc si
    mov byte ptr [si], 39h
    inc si
    mov si, offset PcxPrinterState + 022h
    mov byte ptr [si], 5
    inc si
    mov byte ptr [si], 1bh
    inc si
    mov byte ptr [si], 26h
    inc si
    mov byte ptr [si], 6ch
    inc si
    mov byte ptr [si], 30h
    inc si
    mov byte ptr [si], 48h
    inc si
    mov si, offset PcxPrinterState + 028h
    mov byte ptr [si], 3
    inc si
    mov byte ptr [si], 1bh
    inc si
    mov byte ptr [si], 2ah
    inc si
    mov byte ptr [si], 70h
    inc si
    mov si, offset PcxPrinterState + 036h
    mov byte ptr [si], 7
    inc si
    mov byte ptr [si], 1bh
    inc si
    mov byte ptr [si], 2ah
    inc si
    mov byte ptr [si], 74h
    inc si
    mov byte ptr [si], 31h
    inc si
    mov byte ptr [si], 30h
    inc si
    mov byte ptr [si], 30h
    inc si
    mov byte ptr [si], 52h
    inc si
    mov si, offset PcxPrinterState + 03Eh
    mov byte ptr [si], 7
    inc si
    mov byte ptr [si], 1bh
    inc si
    mov byte ptr [si], 2ah
    inc si
    mov byte ptr [si], 74h
    inc si
    mov byte ptr [si], 31h
    inc si
    mov byte ptr [si], 35h
    inc si
    mov byte ptr [si], 30h
    inc si
    mov byte ptr [si], 52h
    inc si
    mov si, offset PcxPrinterState + 046h
    mov byte ptr [si], 7
    inc si
    mov byte ptr [si], 1bh
    inc si
    mov byte ptr [si], 2ah
    inc si
    mov byte ptr [si], 74h
    inc si
    mov byte ptr [si], 33h
    inc si
    mov byte ptr [si], 30h
    inc si
    mov byte ptr [si], 30h
    inc si
    mov byte ptr [si], 52h
    inc si
    mov si, offset PcxPrinterState + 04Eh
    mov byte ptr [si], 5
    inc si
    mov byte ptr [si], 1bh
    inc si
    mov byte ptr [si], 2ah
    inc si
    mov byte ptr [si], 72h
    inc si
    mov byte ptr [si], 31h
    inc si
    mov byte ptr [si], 41h
    inc si
    mov si, offset PcxPrinterState + 054h
    mov byte ptr [si], 4
    inc si
    mov byte ptr [si], 1bh
    inc si
    mov byte ptr [si], 2ah
    inc si
    mov byte ptr [si], 72h
    inc si
    mov byte ptr [si], 42h
    inc si
    mov si, offset PcxPrinterState + 059h
    mov byte ptr [si], 3
    inc si
    mov byte ptr [si], 1bh
    inc si
    mov byte ptr [si], 2ah
    inc si
    mov byte ptr [si], 62h
    inc si
    mov si, offset PcxPrinterState + 069h
    mov word ptr [si], 0ca00h
    add si, 2
    mov word ptr [si], 3b9ah
    add si, 2
    mov word ptr [si], 0e100h
    add si, 2
    mov word ptr [si], 5f5h
    add si, 2
    mov word ptr [si], 9680h
    add si, 2
    mov word ptr [si], 98h
    add si, 2
    mov word ptr [si], 4240h
    add si, 2
    mov word ptr [si], 0fh
    add si, 2
    mov word ptr [si], 86a0h
    add si, 2
    mov word ptr [si], 1
    add si, 2
    mov word ptr [si], 2710h
    add si, 2
    mov word ptr [si], 0
    add si, 2
    mov word ptr [si], 3e8h
    add si, 2
    mov word ptr [si], 0
    add si, 2
    mov word ptr [si], 64h
    add si, 2
    mov word ptr [si], 0
    add si, 2
    mov word ptr [si], 0ah
    add si, 2
    mov word ptr [si], 0
    add si, 2
    mov word ptr [si], 1
    add si, 2
    mov word ptr [si], 0
    add si, 2
    mov ax, word ptr [bp - 2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf
PcxInitializePrinterState endp
CODE ends
end
