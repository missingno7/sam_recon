; Genus PCX Programmer's Toolkit 3.56 assembly implementation for PCXGENUS.
; Includes video modes, adapter-specific image decoding and printer raster output.

; BIOS/DOS service interrupts, hardware ports and video segments.
PcxVideoInterrupt               equ 10h
PcxKeyboardInterrupt            equ 16h
PcxPrinterInterrupt             equ 17h
PcxDosInterrupt                 equ 21h
PcxSeqIndexPort                 equ 3c4h
PcxGcIndexPort                  equ 3ceh
PcxMonoCrtcIndexPort            equ 3b4h
PcxMonoCrtcDataPort             equ 3b5h
PcxHerculesModePort             equ 3b8h
PcxHerculesConfigPort           equ 3bfh
PcxHerculesVideoSeg             equ 0b000h
PcxBiosGetVideoMode             equ 0fh
PcxDosOpenFile                  equ 3dh
PcxDosCloseFile                 equ 3eh
PcxDosReadFile                  equ 3fh
PcxDosSeekFile                  equ 42h


; SVGA bank selection and VGA miscellaneous-output ports.
PcxTsengBankPort                equ 3cdh
PcxMiscOutputReadPort           equ 3cch
PcxMiscOutputWritePort          equ 3c2h

; Toolkit sizes and PCX RLE/header values.
PcxLastDisplayIndex             equ 15h
PcxDisplayRecordBytes           equ 38h
PcxDisplayNameBytes             equ 15h
PcxMinimumWorkBytes             equ 800h
PcxWorkBufferReserve            equ 0ah
PcxHeaderBytes                  equ 80h
PcxManufacturerByte             equ 0ah
PcxRleRunMarker                 equ 0c0h
PcxHerculesDisplay              equ 9
PcxEscapeCharacter              equ 1bh
PcxDecimalZero                  equ 30h
PcxDecimalTerminator            equ 24h

; Toolkit status words (two's-complement Integer values).
PcxStatusOpenFailed             equ 0ffffh
PcxStatusSmallBuffer            equ 0fffeh
PcxStatusReadFailed             equ 0fffdh
PcxStatusBadHeader              equ 0fffbh
PcxStatusBadDisplay             equ 0fffah
PcxStatusBadMode                equ 0fff9h
PcxStatusNoDescriptor           equ 0fc19h
PcxStatusPrintFormat            equ 0ffedh
PcxStatusPrintAborted           equ 0ffech

; TPcxReadState offsets; names follow the packed Pascal record in SAMDATA.
PcxRsBufferBytes                equ 00h
PcxRsBufferSegment              equ 02h
PcxRsBufferOffset               equ 04h
PcxRsFileHandle                 equ 06h
PcxRsPositionHigh               equ 08h
PcxRsPositionLow                equ 0ah
PcxRsDispatchReady              equ 0ch
PcxRsAdapterFlags               equ 0dh

; TPcxPrinterState offsets, including Pascal short-string length bytes.
PcxPsPortIndex                  equ 00h
PcxPsScaleMode                  equ 02h
PcxPsFormFeedEnabled            equ 04h
PcxPsResetEnabled               equ 06h
PcxPsScanlineBytes              equ 08h
PcxPsAlternateRow               equ 0ah
PcxPsResetCommand               equ 0bh
PcxPsCopiesCommand              equ 0eh
PcxPsOrientationCmd             equ 14h
PcxPsMarginCommand              equ 1ah
PcxPsFormFeedCommand            equ 22h
PcxPsPositionCommand            equ 28h
PcxPsResolution100              equ 36h
PcxPsResolution150              equ 3eh
PcxPsResolution300              equ 46h
PcxPsBeginRasterCmd             equ 4eh
PcxPsEndRasterCmd               equ 54h
PcxPsScanlineCommand            equ 59h
PcxPsDecimalDivisors            equ 69h
PcxPsDivisorHighWord            equ 6bh

; TPcxDisplayInfo offsets used after a descriptor lookup.
PcxDiBiosMode                   equ 16h
PcxDiBitsPerPixel               equ 17h
PcxDiWidth                      equ 18h
PcxDiHeight                     equ 1ah
PcxDiScaleX                     equ 01ch
PcxDiScaleY                     equ 01dh
PcxDiVideoSegment               equ 1eh
PcxDiPageBytes                  equ 20h
PcxDiDeviceClass                equ 022h
PcxDiDecodeOffset               equ 24h
PcxDiDecodeSegment              equ 26h

; PCX header fields used by display and printer decoder continuations.
PcxHdrBitsPerPixel              equ 03h
PcxHdrMinX                      equ 04h
PcxHdrMinY                      equ 06h
PcxHdrMaxX                      equ 08h
PcxHdrMaxY                      equ 0ah
PcxHdrPlaneCount                equ 41h
PcxHdrBytesPerLine              equ 42h

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
assume cs:CODE, ds:DATA
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

; Accepts display index 0..21 and stores the selection; AX = toolkit status.
; Pascal: function PcxSetDisplayType(DisplayIndex: Word): Integer;
; Stack: BP+06h = DisplayIndex; FAR return, callee pops 2 argument bytes.
; Registers: AX = function result; prologue saves BP/DS/ES/SI/DI; other registers and flags
; may change.
; Direct CS state: none.
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
    mov ax, word ptr [bp+6]
    cmp ax, 0
    jb PcxSetDisplayInvalidIndex
    cmp ax, PcxLastDisplayIndex
    jbe PcxSetDisplayStoreIndex
PcxSetDisplayInvalidIndex:
    mov word ptr [bp-2], PcxStatusBadDisplay
    jmp short PcxSetDisplayReturnStatus
PcxSetDisplayStoreIndex:
    mov word ptr [PcxSelectedDisplay], ax
    mov word ptr [bp-2], 0
PcxSetDisplayReturnStatus:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 2
PcxSetDisplayType endp

; Sets the descriptor's graphics mode or mode-3 text, with a direct Hercules path.
; Pascal: function PcxSetGraphicsOrTextMode(GraphicsEnabled: Word): Integer;
; Stack: BP+06h = GraphicsEnabled; FAR return, callee pops 2 argument bytes.
; Registers: AX = function result; prologue saves BP/DS/ES/SI/DI; other registers and flags
; may change.
; Direct CS state: none.
; Original unsigned AX>=0 test is always true, including negative status words; preserve this
; error-handling bug.
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
    mov word ptr [bp-2], 0
    mov ax, word ptr [PcxSelectedDisplay]
    push ax
    call far ptr PcxGetDisplayDescriptor
    cmp ax, 0
    jae PcxModeUseDescriptor
    mov word ptr [bp-2], ax
    jmp short PcxModeReturnStatus
PcxModeUseDescriptor:
    mov di, ax
    mov ax, dx
    mov es, ax
    mov bx, word ptr [bp+6]
    cmp bx, 1
    jne PcxModeCheckTextRequest
    mov word ptr [PcxGraphicsModeState], bx
    mov word ptr [PcxDisplayPageState], 0
    cmp byte ptr es:[di], PcxHerculesDisplay
    je PcxModeSetHerculesGraphics
    push bx
    push bp
    mov ah, PcxBiosGetVideoMode
    int PcxVideoInterrupt
    pop bp
    pop bx
    cmp al, byte ptr es:[di+PcxDiBiosMode]
    je PcxModeReturnStatus
    mov al, byte ptr es:[di+PcxDiBiosMode]
    push bp
    mov ah, 0
    int PcxVideoInterrupt
    pop bp
    jmp short PcxModeReturnStatus
PcxModeSetHerculesGraphics:
    mov ax, 2
    call far ptr PcxHerculesModeHelper
    jmp short PcxModeReturnStatus
PcxModeCheckTextRequest:
    cmp bx, 0
    jne PcxModeInvalidRequest
    mov word ptr [PcxGraphicsModeState], bx
    mov word ptr [PcxDisplayPageState], 0
    cmp byte ptr es:[di], PcxHerculesDisplay
    je PcxModeSetHerculesText
    mov al, 3
    push bp
    mov ah, 0
    int PcxVideoInterrupt
    pop bp
    jmp short PcxModeReturnStatus
PcxModeSetHerculesText:
    mov ax, 20h
    call far ptr PcxHerculesModeHelper
    jmp short PcxModeReturnStatus
PcxModeInvalidRequest:
    mov word ptr [bp-2], PcxStatusBadMode
PcxModeReturnStatus:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 2
PcxSetGraphicsOrTextMode endp

; Returns the selected display index, or the original invalid-index status.
; Pascal: function PcxGetDisplayType: Integer;
; Stack: FAR return, callee pops 0 argument bytes.
; Registers: AX = function result; prologue saves BP/DS/ES/SI/DI; other registers and flags
; may change.
; Direct CS state: none.
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
    mov word ptr [bp-2], ax
    cmp ax, 0
    jl PcxGetDisplayInvalidIndex
    cmp ax, PcxLastDisplayIndex
    jle PcxGetDisplayReturnStatus
PcxGetDisplayInvalidIndex:
    mov word ptr [bp-2], PcxStatusBadDisplay
PcxGetDisplayReturnStatus:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf
PcxGetDisplayType endp

; Copies four version characters from the identity record to a Pascal short string.
; Pascal stack equivalent (no interface declaration): function
; PcxGetVersionString(VersionStringPointer: Pointer): Integer;
; Stack: BP+06h = VersionStringPointer; FAR return, callee pops 4 argument bytes.
; Registers: prologue saves BP/DS/ES/SI/DI; other registers and flags may change.
; Direct CS state: none.
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
    mov ax, word ptr [bp+8]
    mov es, ax
    mov di, word ptr [bp+6]
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov si, offset GenusPcxIdentity + 01ah
    mov cx, 4
    cld
    mov byte ptr es:[di], cl
    inc di
    rep movsb
    mov word ptr [bp-2], 0
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 4
PcxGetVersionString endp

; Installs a buffer of at least 2048 bytes; size 0 selects the internal buffer.
; Pascal stack equivalent (no interface declaration): function
; PcxSetWorkBuffer(WorkBufferPointer: Pointer; WorkBufferBytes: Word): Integer;
; Stack: BP+08h = WorkBufferPointer; BP+06h = WorkBufferBytes; FAR return, callee pops 6
; argument bytes.
; Registers: prologue saves BP/DS/ES/SI/DI; other registers and flags may change.
; Direct CS state: none.
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
    mov ax, word ptr [bp+6]
    cmp ax, PcxMinimumWorkBytes
    jae PcxWorkBufferInstallUserBuffer
    cmp ax, 0
    jne PcxWorkBufferTooSmall
    mov word ptr [PcxReadState+PcxRsBufferSegment], 0ffffh
    mov word ptr [bp-2], 0
    jmp short PcxWorkBufferReturnStatus
PcxWorkBufferTooSmall:
    mov word ptr [bp-2], PcxStatusSmallBuffer
    jmp short PcxWorkBufferReturnStatus
PcxWorkBufferInstallUserBuffer:
    mov ax, word ptr [bp+0ah]
    mov word ptr [PcxReadState+PcxRsBufferSegment], ax
    mov ax, word ptr [bp+8]
    mov word ptr [PcxReadState+PcxRsBufferOffset], ax
    mov ax, word ptr [bp+6]
    sub ax, PcxWorkBufferReserve
    mov word ptr [PcxReadState+PcxRsBufferBytes], ax
    mov word ptr [bp-2], 0
PcxWorkBufferReturnStatus:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 6
PcxSetWorkBuffer endp

; Returns a 56-byte display descriptor in DX:AX, or an AX status word.
; Pascal: function PcxGetDisplayDescriptor(DisplayIndex: Word): PPcxDisplayInfo;
; Stack: BP+06h = DisplayIndex; FAR return, callee pops 2 argument bytes.
; Registers: AX = function result; prologue saves BP/DS/ES/SI/DI; other registers and flags
; may change.
; Direct CS state: none.
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
    mov ax, word ptr [bp+6]
    cmp ax, 0
    jb PcxDescriptorInvalidIndex
    cmp ax, PcxLastDisplayIndex
    jbe PcxDescriptorComputeAddress
PcxDescriptorInvalidIndex:
    mov word ptr [bp-2], PcxStatusBadDisplay
    jmp short PcxDescriptorReturnStatus
PcxDescriptorComputeAddress:
    mov di, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, word ptr [bp+6]
    mul cx
    add di, ax
    mov ax, seg PcxSelectedDisplay
    mov es, ax
    mov ax, di
    mov dx, es
    mov bl, byte ptr es:[di]
    cmp bl, byte ptr [bp+6]
    je PcxDescriptorReturnAddress
    mov word ptr [bp-2], PcxStatusNoDescriptor
    jmp short PcxDescriptorReturnStatus
PcxDescriptorReturnAddress:
    mov word ptr [bp-2], ax
PcxDescriptorReturnStatus:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 2
PcxGetDisplayDescriptor endp

; Copies a descriptor and its 21-byte Pascal display-name record to the caller.
; Pascal stack equivalent (no interface declaration): function
; PcxGetDisplayInformation(DisplayIndex: Word; DisplayInfoPointer: Pointer): Integer;
; Stack: BP+0Ah = DisplayIndex; BP+06h = DisplayInfoPointer; FAR return, callee pops 6
; argument bytes.
; Registers: prologue saves BP/DS/ES/SI/DI; other registers and flags may change.
; Direct CS state: none.
; Original unsigned AX>=0 test is always true, including negative status words; preserve this
; error-handling bug.
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
    mov ax, word ptr [bp+0ah]
    push ax
    call far ptr PcxGetDisplayDescriptor
    cmp ax, 0
    jae PcxDisplayInfoCopyDescriptor
    mov word ptr [bp-2], PcxStatusNoDescriptor
    jmp short PcxDisplayInfoReturnStatus
PcxDisplayInfoCopyDescriptor:
    mov si, ax
    mov ax, dx
    mov ds, ax
    mov ax, word ptr [bp+8]
    mov es, ax
    mov di, word ptr [bp+6]
    mov cx, PcxDisplayRecordBytes
    cld
    rep movsb
    mov ax, seg PcxSelectedDisplay
    mov ds, ax
    mov si, offset PcxDisplayDescriptions
    mov ax, PcxDisplayNameBytes
    mov cx, word ptr [bp+0ah]
    mul cx
    add si, ax
    mov di, word ptr [bp+6]
    add di, 1
    mov cx, PcxDisplayNameBytes
    rep movsb
    mov word ptr [bp-2], 0
PcxDisplayInfoReturnStatus:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 6
PcxGetDisplayInformation endp

; Initializes 22 display descriptors, Hercules CRTC tables and work-buffer state.
; Pascal: procedure PcxInitializeVideoDescriptors;
; Stack: FAR return, callee pops 0 argument bytes.
; Registers: prologue saves BP/DS/ES/SI/DI; other registers and flags may change.
; Direct CS state: none.
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
    mov word ptr [bp-2], 0
    mov word ptr [PcxSelectedDisplay], 0ffffh
    mov word ptr [PcxGraphicsModeState], 0ffffh
    mov word ptr [PcxDisplayPageState], 0ffffh
    mov word ptr [PcxModeCheckPolicy], 1
    mov word ptr [PcxReadState+PcxRsFileHandle], 0ffffh
    mov word ptr [PcxReadState+PcxRsBufferSegment], 0ffffh
    mov word ptr [PcxReadState+PcxRsBufferOffset], 0ffffh
    mov word ptr [PcxReadState+PcxRsBufferBytes], PcxMinimumWorkBytes
    mov byte ptr [PcxReadState+PcxRsDispatchReady], 0
    mov byte ptr [PcxReadState+PcxRsAdapterFlags], 0
    mov byte ptr [PcxReadState+0eh], 0
    mov byte ptr [PcxReadState+0fh], 0
    mov byte ptr [PcxReadState+010h], 0
    mov ax, seg PcxSelectedDisplay
    mov es, ax
    ; Display 0: CGA 320x200x4.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 0
    mul cx
    add bx, ax
    mov byte ptr [bx], 0
    mov byte ptr [bx+PcxDiBiosMode], 4
    mov byte ptr [bx+PcxDiBitsPerPixel], 2
    mov word ptr [bx+PcxDiWidth], 140h
    mov word ptr [bx+PcxDiHeight], 0c8h
    mov byte ptr [bx+PcxDiScaleX], 1
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0b800h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 1
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 1: CGA 640x200x2.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 1
    mul cx
    add bx, ax
    mov byte ptr [bx], 1
    mov byte ptr [bx+PcxDiBiosMode], 6
    mov byte ptr [bx+PcxDiBitsPerPixel], 1
    mov word ptr [bx+PcxDiWidth], 280h
    mov word ptr [bx+PcxDiHeight], 0c8h
    mov byte ptr [bx+PcxDiScaleX], 1
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0b800h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 2
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 2: EGA 320x200x16.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 2
    mul cx
    add bx, ax
    mov byte ptr [bx], 2
    mov byte ptr [bx+PcxDiBiosMode], 0dh
    mov byte ptr [bx+PcxDiBitsPerPixel], 1
    mov word ptr [bx+PcxDiWidth], 140h
    mov word ptr [bx+PcxDiHeight], 0c8h
    mov byte ptr [bx+PcxDiScaleX], 4
    mov byte ptr [bx+PcxDiScaleY], 8
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 2000h
    mov word ptr [bx+PcxDiDeviceClass], 3
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 3: EGA 640x200x16.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 3
    mul cx
    add bx, ax
    mov byte ptr [bx], 3
    mov byte ptr [bx+PcxDiBiosMode], 0eh
    mov byte ptr [bx+PcxDiBitsPerPixel], 1
    mov word ptr [bx+PcxDiWidth], 280h
    mov word ptr [bx+PcxDiHeight], 0c8h
    mov byte ptr [bx+PcxDiScaleX], 4
    mov byte ptr [bx+PcxDiScaleY], 4
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 4000h
    mov word ptr [bx+PcxDiDeviceClass], 3
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 4: EGA 640x350x2.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 4
    mul cx
    add bx, ax
    mov byte ptr [bx], 4
    mov byte ptr [bx+PcxDiBiosMode], 0fh
    mov byte ptr [bx+PcxDiBitsPerPixel], 1
    mov word ptr [bx+PcxDiWidth], 280h
    mov word ptr [bx+PcxDiHeight], 15eh
    mov byte ptr [bx+PcxDiScaleX], 1
    mov byte ptr [bx+PcxDiScaleY], 2
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 8000h
    mov word ptr [bx+PcxDiDeviceClass], 0
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 5: EGA 640x350x16.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 5
    mul cx
    add bx, ax
    mov byte ptr [bx], 5
    mov byte ptr [bx+PcxDiBiosMode], 10h
    mov byte ptr [bx+PcxDiBitsPerPixel], 1
    mov word ptr [bx+PcxDiWidth], 280h
    mov word ptr [bx+PcxDiHeight], 15eh
    mov byte ptr [bx+PcxDiScaleX], 4
    mov byte ptr [bx+PcxDiScaleY], 2
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 8000h
    mov word ptr [bx+PcxDiDeviceClass], 3
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 6: VGA 640x480x2.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 6
    mul cx
    add bx, ax
    mov byte ptr [bx], 6
    mov byte ptr [bx+PcxDiBiosMode], 11h
    mov byte ptr [bx+PcxDiBitsPerPixel], 1
    mov word ptr [bx+PcxDiWidth], 280h
    mov word ptr [bx+PcxDiHeight], 1e0h
    mov byte ptr [bx+PcxDiScaleX], 1
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 0
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 7: VGA 640x480x16.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 7
    mul cx
    add bx, ax
    mov byte ptr [bx], 7
    mov byte ptr [bx+PcxDiBiosMode], 12h
    mov byte ptr [bx+PcxDiBitsPerPixel], 1
    mov word ptr [bx+PcxDiWidth], 280h
    mov word ptr [bx+PcxDiHeight], 1e0h
    mov byte ptr [bx+PcxDiScaleX], 4
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 4
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 8: VGA 320x200x256.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 8
    mul cx
    add bx, ax
    mov byte ptr [bx], 8
    mov byte ptr [bx+PcxDiBiosMode], 13h
    mov byte ptr [bx+PcxDiBitsPerPixel], 8
    mov word ptr [bx+PcxDiWidth], 140h
    mov word ptr [bx+PcxDiHeight], 0c8h
    mov byte ptr [bx+PcxDiScaleX], 1
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 5
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 9: Hercules 720x348x2.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 9
    mul cx
    add bx, ax
    mov byte ptr [bx], 9
    mov byte ptr [bx+PcxDiBiosMode], 0
    mov byte ptr [bx+PcxDiBitsPerPixel], 1
    mov word ptr [bx+PcxDiWidth], 2d0h
    mov word ptr [bx+PcxDiHeight], 15ch
    mov byte ptr [bx+PcxDiScaleX], 1
    mov byte ptr [bx+PcxDiScaleY], 2
    mov word ptr [bx+PcxDiVideoSegment], 0b000h
    mov word ptr [bx+PcxDiPageBytes], 8000h
    mov word ptr [bx+PcxDiDeviceClass], 0
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 10: Tseng 800x600x16.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 0ah
    mul cx
    add bx, ax
    mov byte ptr [bx], 0ah
    mov byte ptr [bx+PcxDiBiosMode], 29h
    mov byte ptr [bx+PcxDiBitsPerPixel], 1
    mov word ptr [bx+PcxDiWidth], 320h
    mov word ptr [bx+PcxDiHeight], 258h
    mov byte ptr [bx+PcxDiScaleX], 4
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 4
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 11: Tseng 640x350x256.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 0bh
    mul cx
    add bx, ax
    mov byte ptr [bx], 0bh
    mov byte ptr [bx+PcxDiBiosMode], 2dh
    mov byte ptr [bx+PcxDiBitsPerPixel], 8
    mov word ptr [bx+PcxDiWidth], 280h
    mov word ptr [bx+PcxDiHeight], 15eh
    mov byte ptr [bx+PcxDiScaleX], 1
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 5
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 12: Tseng 640x480x256.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 0ch
    mul cx
    add bx, ax
    mov byte ptr [bx], 0ch
    mov byte ptr [bx+PcxDiBiosMode], 2eh
    mov byte ptr [bx+PcxDiBitsPerPixel], 8
    mov word ptr [bx+PcxDiWidth], 280h
    mov word ptr [bx+PcxDiHeight], 1e0h
    mov byte ptr [bx+PcxDiScaleX], 1
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 5
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 13: Tseng 800x600x256.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 0dh
    mul cx
    add bx, ax
    mov byte ptr [bx], 0dh
    mov byte ptr [bx+PcxDiBiosMode], 30h
    mov byte ptr [bx+PcxDiBitsPerPixel], 8
    mov word ptr [bx+PcxDiWidth], 320h
    mov word ptr [bx+PcxDiHeight], 258h
    mov byte ptr [bx+PcxDiScaleX], 1
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 5
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 14: Paradise 800x600x16.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 0eh
    mul cx
    add bx, ax
    mov byte ptr [bx], 0eh
    mov byte ptr [bx+PcxDiBiosMode], 58h
    mov byte ptr [bx+PcxDiBitsPerPixel], 1
    mov word ptr [bx+PcxDiWidth], 320h
    mov word ptr [bx+PcxDiHeight], 258h
    mov byte ptr [bx+PcxDiScaleX], 4
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 4
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 15: Paradise 800x600x2.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 0fh
    mul cx
    add bx, ax
    mov byte ptr [bx], 0fh
    mov byte ptr [bx+PcxDiBiosMode], 59h
    mov byte ptr [bx+PcxDiBitsPerPixel], 1
    mov word ptr [bx+PcxDiWidth], 320h
    mov word ptr [bx+PcxDiHeight], 258h
    mov byte ptr [bx+PcxDiScaleX], 1
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 0
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 16: Paradise 640x400x256.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 10h
    mul cx
    add bx, ax
    mov byte ptr [bx], 10h
    mov byte ptr [bx+PcxDiBiosMode], 5eh
    mov byte ptr [bx+PcxDiBitsPerPixel], 8
    mov word ptr [bx+PcxDiWidth], 280h
    mov word ptr [bx+PcxDiHeight], 190h
    mov byte ptr [bx+PcxDiScaleX], 1
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 5
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 17: Paradise 640x480x256.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 11h
    mul cx
    add bx, ax
    mov byte ptr [bx], 11h
    mov byte ptr [bx+PcxDiBiosMode], 5fh
    mov byte ptr [bx+PcxDiBitsPerPixel], 8
    mov word ptr [bx+PcxDiWidth], 280h
    mov word ptr [bx+PcxDiHeight], 1e0h
    mov byte ptr [bx+PcxDiScaleX], 1
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 5
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 18: Video7 800x600x16.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 12h
    mul cx
    add bx, ax
    mov byte ptr [bx], 12h
    mov byte ptr [bx+PcxDiBiosMode], 16h
    mov byte ptr [bx+PcxDiBitsPerPixel], 1
    mov word ptr [bx+PcxDiWidth], 320h
    mov word ptr [bx+PcxDiHeight], 258h
    mov byte ptr [bx+PcxDiScaleX], 4
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 4
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 19: Video7 640x400x256.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 13h
    mul cx
    add bx, ax
    mov byte ptr [bx], 13h
    mov byte ptr [bx+PcxDiBiosMode], 1ah
    mov byte ptr [bx+PcxDiBitsPerPixel], 8
    mov word ptr [bx+PcxDiWidth], 280h
    mov word ptr [bx+PcxDiHeight], 190h
    mov byte ptr [bx+PcxDiScaleX], 1
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 5
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 20: Video7 640x480x256.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 14h
    mul cx
    add bx, ax
    mov byte ptr [bx], 14h
    mov byte ptr [bx+PcxDiBiosMode], 1bh
    mov byte ptr [bx+PcxDiBitsPerPixel], 8
    mov word ptr [bx+PcxDiWidth], 280h
    mov word ptr [bx+PcxDiHeight], 1e0h
    mov byte ptr [bx+PcxDiScaleX], 1
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 5
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Display 21: Video7 800x600x256.
    mov bx, offset PcxDisplayTable
    mov ax, PcxDisplayRecordBytes
    mov cx, 15h
    mul cx
    add bx, ax
    mov byte ptr [bx], 15h
    mov byte ptr [bx+PcxDiBiosMode], 1dh
    mov byte ptr [bx+PcxDiBitsPerPixel], 8
    mov word ptr [bx+PcxDiWidth], 320h
    mov word ptr [bx+PcxDiHeight], 258h
    mov byte ptr [bx+PcxDiScaleX], 1
    mov byte ptr [bx+PcxDiScaleY], 1
    mov word ptr [bx+PcxDiVideoSegment], 0a000h
    mov word ptr [bx+PcxDiPageBytes], 0
    mov word ptr [bx+PcxDiDeviceClass], 5
    mov word ptr [bx+PcxDiDecodeOffset], 0
    mov word ptr [bx+PcxDiDecodeSegment], 0
    mov word ptr [bx+28h], 0
    mov word ptr [bx+2ah], 0
    mov word ptr [bx+2ch], 0
    mov word ptr [bx+2eh], 0
    mov word ptr [bx+30h], 0
    mov word ptr [bx+32h], 0
    mov word ptr [bx+34h], 0
    mov word ptr [bx+36h], 0
    ; Hercules graphics CRTC registers 0..11, written in hardware order.
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
    ; Hercules text CRTC registers 0..11, written in hardware order.
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
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf
PcxInitializeVideoDescriptors endp

; Hercules mode controls.

; Programs the Hercules CRTC, clears video memory and enables the chosen mode.
; Pascal: internal register helper; no stack declaration retained.
; Registers/stack: AL = mode control (2 = graphics, other = text); DS = toolkit DATA.
; AX/BX/CX/DX/SI/DI/ES and flags scratch; FAR register return.
; Direct CS state: none.
PcxHerculesModeHelper proc far
    push ax
    cmp al, 2
    je PcxHercModeUseGraphicsTable
    mov si, offset PcxHerculesTextCrtc
    mov bx, 720h
    push bx
    mov bx, 7d0h
    push bx
    jmp short PcxHercModeProgramCrtc
PcxHercModeUseGraphicsTable:
    mov si, offset PcxHerculesGraphicsCrtc
    mov bx, 0
    push bx
    mov bx, 4000h
    push bx
PcxHercModeProgramCrtc:
    mov ah, al
    mov al, ah
    mov dx, PcxHerculesModePort
    out dx, al
    mov cx, 0ch
    xor ah, ah
    cld
PcxHercModeWriteCrtcRegister:
    mov al, ah
    mov dx, PcxMonoCrtcIndexPort
    out dx, al
    lodsb
    mov bl, al
    mov al, bl
    mov dx, PcxMonoCrtcDataPort
    out dx, al
    inc ah
    loop PcxHercModeWriteCrtcRegister
    pop cx
    mov ax, PcxHerculesVideoSeg
    mov es, ax
    xor di, di
    pop ax
    rep stosw
    pop bx
    add bl, 8
    mov al, bl
    mov dx, PcxHerculesModePort
    out dx, al
    retf
PcxHerculesModeHelper endp

; Writes Hercules configuration 1 or 3; other values are coerced to 1.
; Pascal stack equivalent (no interface declaration): function
; PcxSetHerculesControl(HerculesControl: Word): Integer;
; Stack: BP+06h = HerculesControl; FAR return, callee pops 2 argument bytes.
; Registers: prologue saves BP/DS/ES/SI/DI; other registers and flags may change.
; Direct CS state: none.
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
    mov ax, word ptr [bp+6]
    cmp ax, 3
    je PcxHercControlWriteConfigPort
    cmp ax, 1
    je PcxHercControlWriteConfigPort
    mov ax, 1
PcxHercControlWriteConfigPort:
    mov dx, PcxHerculesConfigPort
    out dx, al
    mov word ptr [bp-2], 0
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 2
PcxSetHerculesControl endp

; Stores a 0/1 BIOS-mode checking policy; other values are coerced to 1.
; Pascal stack equivalent (no interface declaration): function
; PcxSetModeCheckPolicy(ModeCheckPolicy: Word): Integer;
; Stack: BP+06h = ModeCheckPolicy; FAR return, callee pops 2 argument bytes.
; Registers: prologue saves BP/DS/ES/SI/DI; other registers and flags may change.
; Direct CS state: none.
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
    mov ax, word ptr [bp+6]
    cmp ax, 1
    je PcxModePolicyStorePolicy
    cmp ax, 0
    je PcxModePolicyStorePolicy
    mov ax, 1
PcxModePolicyStorePolicy:
    mov word ptr [PcxModeCheckPolicy], ax
    mov word ptr [bp-2], 0
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 2
PcxSetModeCheckPolicy endp

; Image validation and decoder dispatch.

; Checks the PCX manufacturer and display mode, then jumps through descriptor dispatch.
; Pascal: function PcxDisplayBuffer(PcxImageBuffer: Pointer; AvailableBufferBytes, ImageX,
; ImageY, VideoPage: Word): Integer;
; Stack: BP+06h = VideoPage; BP+08h = ImageY; BP+0Ah = ImageX; BP+0Ch = AvailableBufferBytes;
; BP+0Eh = PcxImageBuffer (far pointer); FAR return, callee pops 12 argument bytes.
; Registers: AX = function result; prologue saves BP/DS/ES/SI/DI; other registers and flags
; may change.
; Direct CS state: none.
; Original unsigned AX>=0 test is always true, including negative status words; preserve this
; error-handling bug.
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
    cmp byte ptr [PcxReadState+PcxRsDispatchReady], 1
    je PcxDisplaySaveModePolicy
    call far ptr PcxInitializeDisplayDispatch
PcxDisplaySaveModePolicy:
    mov ax, word ptr [PcxModeCheckPolicy]
    mov word ptr [bp-4], ax
    mov ax, word ptr [bp+10h]
    mov ds, ax
    mov si, word ptr [bp+0eh]
    mov word ptr [bp-8], si
    mov bx, word ptr [bp+0ch]
    add bx, word ptr [bp-8]
    dec bx
    mov word ptr [bp-0ah], bx
    mov al, byte ptr [si]
    cmp al, PcxManufacturerByte
    je PcxDisplayGetSelectedDisplay
    mov word ptr [bp-2], PcxStatusBadHeader
    jmp short PcxDisplayReturnStatus
PcxDisplayGetSelectedDisplay:
    call far ptr PcxGetDisplayType
    cmp ax, 0
    jge PcxDisplayGetDescriptor
    mov word ptr [bp-2], ax
    jmp short PcxDisplayReturnStatus
PcxDisplayGetDescriptor:
    push ax
    call far ptr PcxGetDisplayDescriptor
    cmp ax, 0
    jae PcxDisplayCheckBiosMode
    mov word ptr [bp-2], PcxStatusNoDescriptor
    jmp short PcxDisplayReturnStatus
PcxDisplayCheckBiosMode:
    mov di, ax
    mov ax, dx
    mov es, ax
    cmp word ptr [bp-4], 1
    jne PcxDisplayJumpToDecoder
    cmp byte ptr es:[di], PcxHerculesDisplay
    je PcxDisplayJumpToDecoder
    push bp
    mov ah, PcxBiosGetVideoMode
    int PcxVideoInterrupt
    pop bp
    cmp al, byte ptr es:[di+PcxDiBiosMode]
    je PcxDisplayJumpToDecoder
    mov word ptr [bp-2], PcxStatusBadMode
    jmp short PcxDisplayReturnStatus
PcxDisplayJumpToDecoder:
    jmp dword ptr es:[di+PcxDiDecodeOffset]
PcxDisplayReturnStatus:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxDisplayBuffer endp

; Installs adapter decoder far pointers in all 22 display descriptors.
; Pascal: procedure PcxInitializeDisplayDispatch;
; Registers/stack: DS = toolkit DATA. AX/BX/CX/DX and flags may change; FAR return, no stack
; arguments.
; Direct CS state: none.
PcxInitializeDisplayDispatch proc far
    mov ax, 0
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxCgaDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 1
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxCgaDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 2
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxEgaDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 3
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxEgaDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 4
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxEgaDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 5
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxEgaDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 6
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxEgaDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 7
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxEgaDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 8
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxVga256DecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 9
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxHerculesDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 0ah
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxEgaDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 0bh
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxTsengDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 0ch
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxTsengDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 0dh
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxTsengDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 0eh
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxEgaDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 0fh
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxEgaDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 10h
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxParadiseDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 11h
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxParadiseDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 12h
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxEgaDecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 13h
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxVideo7DecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 14h
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxVideo7DecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov ax, 15h
    push ax
    call far ptr PcxGetDisplayDescriptor
    mov bx, ax
    mov word ptr [bx+PcxDiDecodeOffset], offset PcxVideo7DecodeContinuation
    mov word ptr [bx+PcxDiDecodeSegment], seg CODE
    mov byte ptr [PcxReadState+PcxRsDispatchReady], 1
    retf
PcxInitializeDisplayDispatch endp

; Adapter-specific RLE decoding.

; RLE-decodes into CGA even/odd 2000h scanline banks, clipping the right edge.
; Pascal: continuation of function PcxDisplayBuffer(PcxImageBuffer: Pointer;
; AvailableBufferBytes, ImageX, ImageY, VideoPage: Word): Integer;
; Stack: inherits the display-buffer BP frame and saved BP/DS/ES/SI/DI; FAR jump entry, RETF
; 12 completes the original Pascal call.
; Registers: DS:SI = PCX header, ES:DI = display descriptor at entry; AX = status on return;
; BX/CX/DX/flags may change.
; Direct CS state: none.
PcxCgaDecodeContinuation proc far
    mov ax, word ptr [si+PcxHdrMaxX]
    sub ax, word ptr [si+PcxHdrMinX]
    inc ax
    mov bx, word ptr [bp+0ah]
    add bx, ax
    cmp bx, word ptr es:[di+PcxDiWidth]
    jbe PcxCgaComputeRowBytes
    mov ax, word ptr es:[di+PcxDiWidth]
    sub ax, word ptr [bp+0ah]
    inc ax
PcxCgaComputeRowBytes:
    mov bl, byte ptr [si+PcxHdrBitsPerPixel]
    xor bh, bh
    mul bx
    mov bl, 8
    div bl
    mov cl, ah
    xor ah, ah
    mov word ptr [bp-10h], ax
    dec word ptr [bp-10h]
    mov word ptr [bp-0eh], 0
    cmp cl, 0
    je PcxCgaComputeVideoAddress
    mov word ptr [bp-0eh], 1
    mov al, 80h
    dec cl
    sar al, cl
    mov byte ptr [bp-0ch], al
    inc word ptr [bp-10h]
PcxCgaComputeVideoAddress:
    mov dx, word ptr [bp+0ah]
    mov cl, 4
    sub cl, byte ptr es:[di+PcxDiBitsPerPixel]
    shr dx, cl
    mov ax, word ptr [bp+8]
    shr ax, 1
    mov cl, 4
    shl ax, cl
    add dx, ax
    shl ax, 1
    shl ax, 1
    add dx, ax
    mov ax, word ptr [bp+8]
    and ax, 1
    mov word ptr [bp-6], ax
    cmp ax, 1
    jne PcxCgaClipHeight
    add dx, word ptr 2000h
PcxCgaClipHeight:
    mov ax, word ptr [si+PcxHdrMaxY]
    sub ax, word ptr [si+PcxHdrMinY]
    inc ax
    mov bx, word ptr [bp+8]
    add bx, ax
    cmp bx, word ptr es:[di+PcxDiHeight]
    jbe PcxCgaSetupOutput
    mov ax, word ptr es:[di+PcxDiHeight]
    sub ax, word ptr [bp+8]
PcxCgaSetupOutput:
    mov bh, al
    mov bl, 0
    mov ax, word ptr es:[di+PcxDiVideoSegment]
    mov es, ax
    mov di, dx
    mov dx, word ptr [si+PcxHdrBytesPerLine]
    mov ax, word ptr [bp-6]
    mov dh, al
    mov ax, 2000h
    sub ax, word ptr [si+PcxHdrBytesPerLine]
    mov word ptr [bp-4], ax
    add si, word ptr PcxHeaderBytes
    cld
PcxCgaReadPacket:
    xor ch, ch
    mov cl, 1
    lodsb
    mov ah, al
    and ah, PcxRleRunMarker
    cmp ah, PcxRleRunMarker
    jne PcxCgaEmitRunByte
    mov cl, al
    sub cl, PcxRleRunMarker
    lodsb
PcxCgaEmitRunByte:
    cmp bl, byte ptr [bp-10h]
    jb PcxCgaWriteWholeByte
    ja PcxCgaAdvanceByte
    cmp word ptr [bp-0eh], 1
    jne PcxCgaWriteWholeByte
    push ax
    mov ah, byte ptr es:[di]
    or ah, byte ptr [bp-0ch]
    sub ah, byte ptr [bp-0ch]
    and al, byte ptr [bp-0ch]
    or al, ah
    mov byte ptr es:[di], al
    pop ax
    jmp short PcxCgaAdvanceByte
PcxCgaWriteWholeByte:
    mov byte ptr es:[di], al
PcxCgaAdvanceByte:
    inc di
    inc bl
    cmp bl, dl
    jne PcxCgaFinishRun
    dec bh
    xor bl, bl
    cmp bh, 0
    je PcxCgaSuccess
    xor dh, 1
    cmp dh, 1
    jne PcxCgaSelectEvenBank
    add di, word ptr [bp-4]
    jmp short PcxCgaFinishRun
PcxCgaSelectEvenBank:
    sub di, word ptr 1fb0h
    sub di, dx
PcxCgaFinishRun:
    loop PcxCgaEmitRunByte
    cmp si, word ptr [bp-0ah]
    jbe PcxCgaReadNextPacket
    push si
    call far ptr PcxRefillReadBuffer
    mov si, ax
    jae PcxCgaReadNextPacket
    mov word ptr [bp-2], PcxStatusReadFailed
    jmp short PcxCgaReturnStatus
PcxCgaReadNextPacket:
    jmp short PcxCgaReadPacket
PcxCgaSuccess:
    mov word ptr [bp-2], 0
PcxCgaReturnStatus:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxCgaDecodeContinuation endp

; RLE-decodes PCX planes into EGA video memory with page and partial-byte handling.
; Pascal: continuation of function PcxDisplayBuffer(PcxImageBuffer: Pointer;
; AvailableBufferBytes, ImageX, ImageY, VideoPage: Word): Integer;
; Stack: inherits the display-buffer BP frame and saved BP/DS/ES/SI/DI; FAR jump entry, RETF
; 12 completes the original Pascal call.
; Registers: DS:SI = PCX header, ES:DI = display descriptor at entry; AX = status on return;
; BX/CX/DX/flags may change.
; Direct CS state: none.
PcxEgaDecodeContinuation proc far
    mov ax, word ptr es:[di+PcxDiWidth]
    mov cl, 3
    shr ax, cl
    mov word ptr [bp-16h], ax
    mov word ptr [bp-0eh], 0
    mov ax, word ptr [si+PcxHdrMaxX]
    sub ax, word ptr [si+PcxHdrMinX]
    inc ax
    mov bx, word ptr [bp+0ah]
    add bx, ax
    cmp bx, word ptr es:[di+PcxDiWidth]
    jbe PcxEgaComputeRowBytes
    mov ax, word ptr es:[di+PcxDiWidth]
    sub ax, word ptr [bp+0ah]
    inc ax
    test al, 7
    je PcxEgaComputeRowBytes
    inc ax
    and al, 0f8h
PcxEgaComputeRowBytes:
    mov bl, byte ptr [si+PcxHdrBitsPerPixel]
    xor bh, bh
    mul bx
    mov bl, 8
    div bl
    mov cl, ah
    xor ah, ah
    mov word ptr [bp-10h], ax
    dec word ptr [bp-10h]
    cmp cl, 0
    je PcxEgaInitGraphics
    mov word ptr [bp-0eh], 1
    mov al, 80h
    dec cl
    sar al, cl
    mov byte ptr [bp-0ch], al
    inc word ptr [bp-10h]
PcxEgaInitGraphics:
    mov al, 5
    mov dx, PcxGcIndexPort
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    mov al, 8
    mov dx, PcxGcIndexPort
    out dx, al
    inc dx
    mov al, 0ffh
    out dx, al
    mov byte ptr [bp-18h], 1
    mov al, 2
    mov dx, PcxSeqIndexPort
    out dx, al
    inc dx
    mov al, byte ptr [bp-18h]
    out dx, al
    mov word ptr [bp-1ch], 1
    mov word ptr [bp-1ah], 8
    cmp byte ptr [si+PcxHdrPlaneCount], 3
    jne PcxEgaCheckSinglePlane
    mov word ptr [bp-1ah], 4
PcxEgaCheckSinglePlane:
    cmp byte ptr [si+PcxHdrPlaneCount], 1
    jne PcxEgaComputeVideoAddress
    mov word ptr [bp-1ch], 0fh
    mov word ptr [bp-1ah], 1
    mov al, 2
    mov dx, PcxSeqIndexPort
    out dx, al
    inc dx
    mov al, 0fh
    out dx, al
PcxEgaComputeVideoAddress:
    mov ax, word ptr es:[di+PcxDiPageBytes]
    mov bx, word ptr [bp+6]
    mul bx
    mov dx, ax
    mov ax, word ptr [bp+0ah]
    mov cl, 3
    shr ax, cl
    add dx, ax
    mov ax, word ptr [bp+8]
    cmp word ptr [bp-16h], 50h
    je PcxEgaStride80
    cmp word ptr [bp-16h], 64h
    je PcxEgaStride100
    mov cl, 3
    shl ax, cl
    add dx, ax
    shl ax, 1
    shl ax, 1
    add dx, ax
    jmp short PcxEgaClipHeight
PcxEgaStride80:
    mov cl, 4
    shl ax, cl
    add dx, ax
    shl ax, 1
    shl ax, 1
    add dx, ax
    jmp short PcxEgaClipHeight
PcxEgaStride100:
    shl ax, 1
    shl ax, 1
    add dx, ax
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add dx, ax
    shl ax, 1
    add dx, ax
PcxEgaClipHeight:
    mov ax, word ptr [si+PcxHdrMaxY]
    sub ax, word ptr [si+PcxHdrMinY]
    inc ax
    mov word ptr [bp-12h], ax
    mov bx, word ptr [bp+8]
    add bx, ax
    cmp bx, word ptr es:[di+PcxDiHeight]
    jbe PcxEgaSetupOutput
    mov ax, word ptr es:[di+PcxDiHeight]
    sub ax, word ptr [bp+8]
    inc ax
    mov word ptr [bp-12h], ax
PcxEgaSetupOutput:
    mov bx, 0
    mov ax, word ptr es:[di+PcxDiVideoSegment]
    mov es, ax
    mov di, dx
    mov ax, word ptr [si+PcxHdrBytesPerLine]
    mov word ptr [bp-14h], ax
    add si, word ptr PcxHeaderBytes
    cld
PcxEgaReadPacket:
    mov cx, 1
    lodsb
    mov ah, al
    and ah, PcxRleRunMarker
    cmp ah, PcxRleRunMarker
    jne PcxEgaEmitRunByte
    mov cl, al
    sub cl, PcxRleRunMarker
    lodsb
PcxEgaEmitRunByte:
    cmp bx, word ptr [bp-10h]
    jb PcxEgaWriteWholeByte
    ja PcxEgaAdvanceByte
    cmp word ptr [bp-0eh], 1
    jne PcxEgaWriteWholeByte
    push ax
    mov al, 8
    mov dx, PcxGcIndexPort
    out dx, al
    inc dx
    mov al, byte ptr [bp-0ch]
    out dx, al
    mov al, byte ptr es:[bx+di]
    pop ax
    mov byte ptr es:[bx+di], al
    push ax
    mov al, 8
    mov dx, PcxGcIndexPort
    out dx, al
    inc dx
    mov al, 0ffh
    out dx, al
    pop ax
    jmp short PcxEgaAdvanceByte
PcxEgaWriteWholeByte:
    mov byte ptr es:[bx+di], al
PcxEgaAdvanceByte:
    inc bx
    cmp bx, word ptr [bp-14h]
    jne PcxEgaFinishRun
    xor bx, bx
    mov dx, word ptr [bp-1ah]
    shl byte ptr [bp-18h], 1
    cmp byte ptr [bp-18h], dl
    jbe PcxEgaSelectNextPlane
    mov dx, word ptr [bp-1ch]
    mov byte ptr [bp-18h], dl
    add di, word ptr [bp-16h]
    dec word ptr [bp-12h]
    je PcxEgaSuccess
PcxEgaSelectNextPlane:
    push ax
    mov al, 2
    mov dx, PcxSeqIndexPort
    out dx, al
    inc dx
    mov al, byte ptr [bp-18h]
    out dx, al
    pop ax
PcxEgaFinishRun:
    loop PcxEgaEmitRunByte
    cmp si, word ptr [bp-0ah]
    jbe PcxEgaReadNextPacket
    push si
    call far ptr PcxRefillReadBuffer
    mov si, ax
    jae PcxEgaReadNextPacket
    mov word ptr [bp-2], PcxStatusReadFailed
    jmp short PcxEgaReturnStatus
PcxEgaReadNextPacket:
    jmp near ptr PcxEgaReadPacket
PcxEgaSuccess:
    mov al, 2
    mov dx, PcxSeqIndexPort
    out dx, al
    inc dx
    mov al, 0ffh
    out dx, al
    mov word ptr [bp-2], 0
PcxEgaReturnStatus:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxEgaDecodeContinuation endp

; RLE-decodes 256-color PCX rows into linear 320-byte VGA scanlines.
; Pascal: continuation of function PcxDisplayBuffer(PcxImageBuffer: Pointer;
; AvailableBufferBytes, ImageX, ImageY, VideoPage: Word): Integer;
; Stack: inherits the display-buffer BP frame and saved BP/DS/ES/SI/DI; FAR jump entry, RETF
; 12 completes the original Pascal call.
; Registers: DS:SI = PCX header, ES:DI = display descriptor at entry; AX = status on return;
; BX/CX/DX/flags may change.
; Direct CS state: none.
PcxVga256DecodeContinuation proc far
    mov ax, word ptr es:[di+PcxDiWidth]
    mov word ptr [bp-16h], ax
    mov ax, word ptr [si+PcxHdrMaxX]
    sub ax, word ptr [si+PcxHdrMinX]
    inc ax
    mov bx, word ptr [bp+0ah]
    add bx, ax
    cmp bx, word ptr es:[di+PcxDiWidth]
    jbe PcxVgaComputeLastColumn
    mov ax, word ptr es:[di+PcxDiWidth]
    sub ax, word ptr [bp+0ah]
PcxVgaComputeLastColumn:
    dec ax
    mov word ptr [bp-10h], ax
    mov ax, word ptr [bp+8]
    xchg ah, al
    mov dx, ax
    shr ax, 1
    shr ax, 1
    add dx, ax
    mov ax, word ptr [bp+0ah]
    add dx, ax
    mov ax, word ptr [si+PcxHdrMaxY]
    sub ax, word ptr [si+PcxHdrMinY]
    inc ax
    mov word ptr [bp-12h], ax
    mov bx, word ptr [bp+8]
    add bx, ax
    cmp bx, word ptr es:[di+PcxDiHeight]
    jbe PcxVgaSetupOutput
    mov ax, word ptr es:[di+PcxDiHeight]
    sub ax, word ptr [bp+8]
    inc ax
    mov word ptr [bp-12h], ax
PcxVgaSetupOutput:
    mov bx, 0
    mov ax, word ptr es:[di+PcxDiVideoSegment]
    mov es, ax
    mov di, dx
    mov ax, word ptr [si+PcxHdrBytesPerLine]
    mov word ptr [bp-14h], ax
    add si, word ptr PcxHeaderBytes
    cld
PcxVgaReadPacket:
    mov cx, 1
    lodsb
    mov ah, al
    and ah, PcxRleRunMarker
    cmp ah, PcxRleRunMarker
    jne PcxVgaEmitRunByte
    mov cl, al
    sub cl, PcxRleRunMarker
    lodsb
PcxVgaEmitRunByte:
    cmp bx, word ptr [bp-10h]
    ja PcxVgaAdvanceByte
    mov byte ptr es:[bx+di], al
PcxVgaAdvanceByte:
    inc bx
    cmp bx, word ptr [bp-14h]
    jne PcxVgaFinishRun
    xor bx, bx
    add di, word ptr [bp-16h]
    dec word ptr [bp-12h]
    je PcxVgaSuccess
PcxVgaFinishRun:
    loop PcxVgaEmitRunByte
    cmp si, word ptr [bp-0ah]
    jbe PcxVgaReadNextPacket
    push si
    call far ptr PcxRefillReadBuffer
    mov si, ax
    jae PcxVgaReadNextPacket
    mov word ptr [bp-2], PcxStatusReadFailed
    jmp short PcxVgaReturnStatus
PcxVgaReadNextPacket:
    jmp short PcxVgaReadPacket
PcxVgaSuccess:
    mov word ptr [bp-2], 0
PcxVgaReturnStatus:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxVga256DecodeContinuation endp

; RLE-decodes monochrome rows into Hercules interleaved scanline banks.
; Pascal: continuation of function PcxDisplayBuffer(PcxImageBuffer: Pointer;
; AvailableBufferBytes, ImageX, ImageY, VideoPage: Word): Integer;
; Stack: inherits the display-buffer BP frame and saved BP/DS/ES/SI/DI; FAR jump entry, RETF
; 12 completes the original Pascal call.
; Registers: DS:SI = PCX header, ES:DI = display descriptor at entry; AX = status on return;
; BX/CX/DX/flags may change.
; Direct CS state: none.
PcxHerculesDecodeContinuation proc far
    mov ax, word ptr [si+PcxHdrMaxX]
    sub ax, word ptr [si+PcxHdrMinX]
    inc ax
    mov bx, word ptr [bp+0ah]
    add bx, ax
    cmp bx, word ptr es:[di+PcxDiWidth]
    jbe PcxHercComputeRowBytes
    mov ax, word ptr es:[di+PcxDiWidth]
    sub ax, word ptr [bp+0ah]
    inc ax
PcxHercComputeRowBytes:
    mov bl, 8
    div bl
    mov cl, ah
    xor ah, ah
    mov word ptr [bp-10h], ax
    dec word ptr [bp-10h]
    mov word ptr [bp-0eh], 0
    cmp cl, 0
    je PcxHercComputeVideoAddress
    mov word ptr [bp-0eh], 1
    mov al, 80h
    dec cl
    sar al, cl
    mov byte ptr [bp-0ch], al
    inc word ptr [bp-10h]
PcxHercComputeVideoAddress:
    mov ax, word ptr [bp+8]
    xor ah, ah
    and al, 3
    mov word ptr [bp-6], ax
    mov ax, word ptr es:[di+PcxDiPageBytes]
    mov bx, word ptr [bp+6]
    mul bx
    mov cx, ax
    mov ax, word ptr [bp+8]
    mov bx, word ptr [bp+0ah]
    shr ax, 1
    rcr bx, 1
    shr ax, 1
    rcr bx, 1
    shr bx, 1
    mov ah, 5ah
    mul ah
    add bx, ax
    add cx, bx
    mov ax, word ptr [si+PcxHdrMaxY]
    sub ax, word ptr [si+PcxHdrMinY]
    inc ax
    mov word ptr [bp-12h], ax
    mov bx, word ptr [bp+8]
    add bx, ax
    cmp bx, word ptr es:[di+PcxDiHeight]
    jbe PcxHercSetupOutput
    mov ax, word ptr es:[di+PcxDiHeight]
    sub ax, word ptr [bp+8]
    inc ax
    mov word ptr [bp-12h], ax
PcxHercSetupOutput:
    mov bx, 0
    mov dx, word ptr [bp-6]
    mov ax, word ptr es:[di+PcxDiVideoSegment]
    mov es, ax
    mov di, cx
    mov ax, word ptr [si+PcxHdrBytesPerLine]
    mov word ptr [bp-14h], ax
    add si, word ptr PcxHeaderBytes
    cld
PcxHercReadPacket:
    mov cx, 1
    lodsb
    mov ah, al
    and ah, PcxRleRunMarker
    cmp ah, PcxRleRunMarker
    jne PcxHercEmitRunByte
    mov cl, al
    sub cl, PcxRleRunMarker
    lodsb
PcxHercEmitRunByte:
    cmp bl, byte ptr [bp-10h]
    jb PcxHercWriteWholeByte
    ja PcxHercAdvanceByte
    cmp word ptr [bp-0eh], 1
    jne PcxHercWriteWholeByte
    push ax
    mov ah, byte ptr es:[bx+di]
    or ah, byte ptr [bp-0ch]
    sub ah, byte ptr [bp-0ch]
    and al, byte ptr [bp-0ch]
    or al, ah
    mov byte ptr es:[bx+di], al
    pop ax
    jmp short PcxHercAdvanceByte
PcxHercWriteWholeByte:
    mov byte ptr es:[bx+di], al
PcxHercAdvanceByte:
    inc bx
    cmp bx, word ptr [bp-14h]
    jne PcxHercFinishRun
    xor bx, bx
    dec word ptr [bp-12h]
    je PcxHercSuccess
    inc dx
    cmp dx, 4
    jb PcxHercSelectNextBank
    sub di, word ptr 5fa6h
    xor dx, dx
    jmp short PcxHercFinishRun
PcxHercSelectNextBank:
    add di, word ptr 2000h
PcxHercFinishRun:
    loop PcxHercEmitRunByte
    cmp si, word ptr [bp-0ah]
    jbe PcxHercReadNextPacket
    push si
    call far ptr PcxRefillReadBuffer
    mov si, ax
    jae PcxHercReadNextPacket
    mov word ptr [bp-2], PcxStatusReadFailed
    jmp short PcxHercReturnStatus
PcxHercReadNextPacket:
    jmp short PcxHercReadPacket
PcxHercSuccess:
    mov word ptr [bp-2], 0
PcxHercReturnStatus:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxHerculesDecodeContinuation endp

; RLE-decodes 256-color rows while switching Paradise video-memory banks.
; Pascal: continuation of function PcxDisplayBuffer(PcxImageBuffer: Pointer;
; AvailableBufferBytes, ImageX, ImageY, VideoPage: Word): Integer;
; Stack: inherits the display-buffer BP frame and saved BP/DS/ES/SI/DI; FAR jump entry, RETF
; 12 completes the original Pascal call.
; Registers: DS:SI = PCX header, ES:DI = display descriptor at entry; AX = status on return;
; BX/CX/DX/flags may change.
; Direct CS state: none.
PcxParadiseDecodeContinuation proc far
    mov ax, word ptr es:[di+PcxDiWidth]
    mov word ptr [bp-16h], ax
    mov ax, word ptr [si+PcxHdrMaxX]
    sub ax, word ptr [si+PcxHdrMinX]
    inc ax
    mov bx, word ptr [bp+0ah]
    add bx, ax
    cmp bx, word ptr es:[di+PcxDiWidth]
    jbe PcxParadiseComputeLastColumn
    mov ax, word ptr es:[di+PcxDiWidth]
    sub ax, word ptr [bp+0ah]
PcxParadiseComputeLastColumn:
    dec ax
    mov word ptr [bp-10h], ax
    mov ax, word ptr [bp+8]
    mov bx, ax
    mov cl, 5
    shr bx, cl
    mov byte ptr [bp-1eh], bl
    shl bx, cl
    sub ax, bx
    xchg ah, al
    shl ax, 1
    mov dx, ax
    shr ax, 1
    shr ax, 1
    add dx, ax
    mov ax, word ptr [bp+0ah]
    add dx, ax
    mov ax, word ptr [si+PcxHdrMaxY]
    sub ax, word ptr [si+PcxHdrMinY]
    inc ax
    mov word ptr [bp-12h], ax
    mov bx, word ptr [bp+8]
    add bx, ax
    cmp bx, word ptr es:[di+PcxDiHeight]
    jbe PcxParadiseSetupOutput
    mov ax, word ptr es:[di+PcxDiHeight]
    sub ax, word ptr [bp+8]
    inc ax
    mov word ptr [bp-12h], ax
PcxParadiseSetupOutput:
    mov bx, 0
    mov ax, word ptr es:[di+PcxDiVideoSegment]
    mov es, ax
    mov di, dx
    mov ax, word ptr [si+PcxHdrBytesPerLine]
    mov word ptr [bp-14h], ax
    add si, word ptr PcxHeaderBytes
    cld
    mov al, 0fh
    mov dx, PcxGcIndexPort
    out dx, al
    inc dx
    mov al, 5
    out dx, al
    mov al, byte ptr [bp-1eh]
    mov ah, al
    shl al, 1
    shl al, 1
    add al, ah
    mov byte ptr [bp-1eh], al
    mov al, 9
    mov dx, PcxGcIndexPort
    out dx, al
    inc dx
    mov al, byte ptr [bp-1eh]
    out dx, al
PcxParadiseReadPacket:
    mov cx, 1
    lodsb
    mov ah, al
    and ah, PcxRleRunMarker
    cmp ah, PcxRleRunMarker
    jne PcxParadiseEmitRunByte
    mov cl, al
    sub cl, PcxRleRunMarker
    lodsb
PcxParadiseEmitRunByte:
    cmp bx, word ptr [bp-10h]
    ja PcxParadiseAdvanceByte
    mov byte ptr es:[bx+di], al
PcxParadiseAdvanceByte:
    inc bx
    cmp bx, word ptr [bp-14h]
    jne PcxParadiseFinishRun
    xor bx, bx
    add di, word ptr [bp-16h]
    dec word ptr [bp-12h]
    je PcxParadiseSuccess
    cmp di, word ptr 5000h
    jb PcxParadiseFinishRun
    push ax
    push bx
    mov bh, byte ptr [bp-1eh]
    add bh, 5
    mov byte ptr [bp-1eh], bh
    mov al, 9
    mov dx, PcxGcIndexPort
    out dx, al
    inc dx
    mov al, bh
    out dx, al
    pop bx
    pop ax
    mov di, word ptr [bp+0ah]
PcxParadiseFinishRun:
    loop PcxParadiseEmitRunByte
    cmp si, word ptr [bp-0ah]
    jbe PcxParadiseReadNextPacket
    push si
    call far ptr PcxRefillReadBuffer
    mov si, ax
    jae PcxParadiseReadNextPacket
    mov word ptr [bp-2], PcxStatusReadFailed
    jmp short PcxParadiseRestoreBank
PcxParadiseReadNextPacket:
    jmp short PcxParadiseReadPacket
PcxParadiseSuccess:
    mov word ptr [bp-2], 0
PcxParadiseRestoreBank:
    mov al, 9
    mov dx, PcxGcIndexPort
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    mov al, 0fh
    mov dx, PcxGcIndexPort
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxParadiseDecodeContinuation endp

; RLE-decodes 256-color rows while switching Tseng video-memory banks.
; Pascal: continuation of function PcxDisplayBuffer(PcxImageBuffer: Pointer;
; AvailableBufferBytes, ImageX, ImageY, VideoPage: Word): Integer;
; Stack: inherits the display-buffer BP frame and saved BP/DS/ES/SI/DI; FAR jump entry, RETF
; 12 completes the original Pascal call.
; Registers: DS:SI = PCX header, ES:DI = display descriptor at entry; AX = status on return;
; BX/CX/DX/flags may change.
; Direct CS state: none.
PcxTsengDecodeContinuation proc far
    mov ax, word ptr [si+PcxHdrMaxX]
    sub ax, word ptr [si+PcxHdrMinX]
    inc ax
    mov bx, word ptr [bp+0ah]
    add bx, ax
    cmp bx, word ptr es:[di+PcxDiWidth]
    jbe PcxTsengComputeLastColumn
    mov ax, word ptr es:[di+PcxDiWidth]
    sub ax, word ptr [bp+0ah]
PcxTsengComputeLastColumn:
    dec ax
    mov word ptr [bp-10h], ax
    mov ax, word ptr es:[di+PcxDiWidth]
    mov word ptr [bp-16h], ax
    mov bx, word ptr [bp+8]
    mul bx
    mov bx, word ptr [bp+0ah]
    add ax, bx
    adc dx, 0
    mov byte ptr [bp-1eh], dl
    mov dx, ax
    mov ax, word ptr [si+PcxHdrMaxY]
    sub ax, word ptr [si+PcxHdrMinY]
    inc ax
    mov word ptr [bp-12h], ax
    mov bx, word ptr [bp+8]
    add bx, ax
    cmp bx, word ptr es:[di+PcxDiHeight]
    jbe PcxTsengSetupOutput
    mov ax, word ptr es:[di+PcxDiHeight]
    sub ax, word ptr [bp+8]
    inc ax
    mov word ptr [bp-12h], ax
PcxTsengSetupOutput:
    mov ax, word ptr es:[di+PcxDiVideoSegment]
    mov es, ax
    mov di, dx
    push ax
    mov al, byte ptr [bp-1eh]
    mov ah, al
    shl ah, 1
    shl ah, 1
    shl ah, 1
    or al, ah
    or al, 40h
    mov dx, PcxTsengBankPort
    out dx, al
    pop ax
    mov ax, word ptr [si+PcxHdrBytesPerLine]
    mov word ptr [bp-14h], ax
    sub word ptr [bp-16h], ax
    xor bx, bx
    add si, word ptr PcxHeaderBytes
    cld
PcxTsengReadPacket:
    mov cx, 1
    lodsb
    mov ah, al
    and ah, PcxRleRunMarker
    cmp ah, PcxRleRunMarker
    jne PcxTsengEmitRunByte
    mov cl, al
    sub cl, PcxRleRunMarker
    lodsb
PcxTsengEmitRunByte:
    cmp bx, word ptr [bp-10h]
    ja PcxTsengAdvanceByte
    mov byte ptr es:[di], al
PcxTsengAdvanceByte:
    inc di
    jne PcxTsengCheckRowEnd
    inc byte ptr [bp-1eh]
    push ax
    mov al, byte ptr [bp-1eh]
    mov ah, al
    shl ah, 1
    shl ah, 1
    shl ah, 1
    or al, ah
    or al, 40h
    mov dx, PcxTsengBankPort
    out dx, al
    pop ax
PcxTsengCheckRowEnd:
    inc bx
    cmp bx, word ptr [bp-14h]
    jne PcxTsengFinishRun
    xor bx, bx
    add di, word ptr [bp-16h]
    jae PcxTsengFinishRow
    inc byte ptr [bp-1eh]
    push ax
    mov al, byte ptr [bp-1eh]
    mov ah, al
    shl ah, 1
    shl ah, 1
    shl ah, 1
    or al, ah
    or al, 40h
    mov dx, PcxTsengBankPort
    out dx, al
    pop ax
PcxTsengFinishRow:
    dec word ptr [bp-12h]
    je PcxTsengSuccess
PcxTsengFinishRun:
    loop PcxTsengEmitRunByte
    cmp si, word ptr [bp-0ah]
    jbe PcxTsengReadNextPacket
    push si
    call far ptr PcxRefillReadBuffer
    mov si, ax
    jae PcxTsengReadNextPacket
    mov word ptr [bp-2], PcxStatusReadFailed
    jmp short PcxTsengReturnStatus
PcxTsengReadNextPacket:
    jmp short PcxTsengReadPacket
PcxTsengSuccess:
    push ax
    mov al, 0
    mov ah, al
    shl ah, 1
    shl ah, 1
    shl ah, 1
    or al, ah
    or al, 40h
    mov dx, PcxTsengBankPort
    out dx, al
    pop ax
    mov word ptr [bp-2], 0
PcxTsengReturnStatus:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxTsengDecodeContinuation endp

; RLE-decodes 256-color rows while switching Video7 video-memory banks.
; Pascal: continuation of function PcxDisplayBuffer(PcxImageBuffer: Pointer;
; AvailableBufferBytes, ImageX, ImageY, VideoPage: Word): Integer;
; Stack: inherits the display-buffer BP frame and saved BP/DS/ES/SI/DI; FAR jump entry, RETF
; 12 completes the original Pascal call.
; Registers: DS:SI = PCX header, ES:DI = display descriptor at entry; AX = status on return;
; BX/CX/DX/flags may change.
; Direct CS state: none.
PcxVideo7DecodeContinuation proc far
    mov ax, word ptr es:[di+PcxDiWidth]
    mov word ptr [bp-16h], ax
    mov ax, word ptr [si+PcxHdrMaxX]
    sub ax, word ptr [si+PcxHdrMinX]
    inc ax
    mov bx, word ptr [bp+0ah]
    add bx, ax
    cmp bx, word ptr es:[di+PcxDiWidth]
    jbe PcxVideo7ComputeLastColumn
    mov ax, word ptr es:[di+PcxDiWidth]
    sub ax, word ptr [bp+0ah]
PcxVideo7ComputeLastColumn:
    dec ax
    mov word ptr [bp-10h], ax
    mov ax, word ptr es:[di+PcxDiWidth]
    mov word ptr [bp-16h], ax
    mov bx, word ptr [bp+8]
    mul bx
    mov bx, word ptr [bp+0ah]
    add ax, bx
    adc dx, 0
    mov byte ptr [bp-1eh], dl
    mov dx, ax
    mov ax, word ptr [si+PcxHdrMaxY]
    sub ax, word ptr [si+PcxHdrMinY]
    inc ax
    mov word ptr [bp-12h], ax
    mov bx, word ptr [bp+8]
    add bx, ax
    cmp bx, word ptr es:[di+PcxDiHeight]
    jbe PcxVideo7SetupOutput
    mov ax, word ptr es:[di+PcxDiHeight]
    sub ax, word ptr [bp+8]
    inc ax
    mov word ptr [bp-12h], ax
PcxVideo7SetupOutput:
    mov ax, word ptr es:[di+PcxDiVideoSegment]
    mov es, ax
    mov di, dx
    mov al, 6
    mov dx, PcxSeqIndexPort
    out dx, al
    inc dx
    mov al, 0eah
    out dx, al
    push ax
    push bx
    mov bh, byte ptr [bp-1eh]
    mov bl, bh
    and bl, 1
    mov al, 0f9h
    mov dx, PcxSeqIndexPort
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
    mov dx, PcxMiscOutputReadPort
    in al, dx
    and al, 0dfh
    or bl, al
    mov al, bl
    mov dx, PcxMiscOutputWritePort
    out dx, al
    mov al, 0f6h
    mov dx, PcxSeqIndexPort
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
    mov ax, word ptr [si+PcxHdrBytesPerLine]
    mov word ptr [bp-14h], ax
    sub word ptr [bp-16h], ax
    xor bx, bx
    add si, word ptr PcxHeaderBytes
    cld
PcxVideo7ReadPacket:
    mov cx, 1
    lodsb
    mov ah, al
    and ah, PcxRleRunMarker
    cmp ah, PcxRleRunMarker
    jne PcxVideo7EmitRunByte
    mov cl, al
    sub cl, PcxRleRunMarker
    lodsb
PcxVideo7EmitRunByte:
    cmp bx, word ptr [bp-10h]
    ja PcxVideo7AdvanceByte
    mov byte ptr es:[di], al
PcxVideo7AdvanceByte:
    inc di
    jne PcxVideo7CheckRowEnd
    inc byte ptr [bp-1eh]
    push ax
    push bx
    mov bh, byte ptr [bp-1eh]
    mov bl, bh
    and bl, 1
    mov al, 0f9h
    mov dx, PcxSeqIndexPort
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
    mov dx, PcxMiscOutputReadPort
    in al, dx
    and al, 0dfh
    or bl, al
    mov al, bl
    mov dx, PcxMiscOutputWritePort
    out dx, al
    mov al, 0f6h
    mov dx, PcxSeqIndexPort
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
PcxVideo7CheckRowEnd:
    inc bx
    cmp bx, word ptr [bp-14h]
    jne PcxVideo7FinishRun
    xor bx, bx
    add di, word ptr [bp-16h]
    jae PcxVideo7FinishRow
    inc byte ptr [bp-1eh]
    push ax
    push bx
    mov bh, byte ptr [bp-1eh]
    mov bl, bh
    and bl, 1
    mov al, 0f9h
    mov dx, PcxSeqIndexPort
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
    mov dx, PcxMiscOutputReadPort
    in al, dx
    and al, 0dfh
    or bl, al
    mov al, bl
    mov dx, PcxMiscOutputWritePort
    out dx, al
    mov al, 0f6h
    mov dx, PcxSeqIndexPort
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
PcxVideo7FinishRow:
    dec word ptr [bp-12h]
    je PcxVideo7Success
PcxVideo7FinishRun:
    dec cx
    je PcxVideo7CheckReadBuffer
    jmp near ptr PcxVideo7EmitRunByte
PcxVideo7CheckReadBuffer:
    cmp si, word ptr [bp-0ah]
    jbe PcxVideo7ReadNextPacket
    push si
    call far ptr PcxRefillReadBuffer
    mov si, ax
    jae PcxVideo7ReadNextPacket
    mov word ptr [bp-2], PcxStatusReadFailed
    jmp short PcxVideo7ReturnStatus
PcxVideo7ReadNextPacket:
    jmp near ptr PcxVideo7ReadPacket
PcxVideo7Success:
    push ax
    push bx
    mov bh, 0
    mov bl, bh
    and bl, 1
    mov al, 0f9h
    mov dx, PcxSeqIndexPort
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
    mov dx, PcxMiscOutputReadPort
    in al, dx
    and al, 0dfh
    or bl, al
    mov al, bl
    mov dx, PcxMiscOutputWritePort
    out dx, al
    mov al, 0f6h
    mov dx, PcxSeqIndexPort
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
    mov dx, PcxSeqIndexPort
    out dx, al
    inc dx
    mov al, 0aeh
    out dx, al
    mov word ptr [bp-2], 0
PcxVideo7ReturnStatus:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxVideo7DecodeContinuation endp

; DOS file reading and buffer refill.

; Converts a Pascal filename, opens/reads/closes it with DOS INT PcxDosInterrupt.
; Converts a Pascal filename, opens/reads it with DOS, displays the buffer and closes it.
; Pascal: function PcxDisplayFile(ImageFileName: String; ImageX, ImageY, VideoPage: Word):
; Integer;
; Stack: BP+06h = VideoPage; BP+08h = ImageY; BP+0Ah = ImageX; BP+0Ch = ImageFileName (far
; pointer); FAR return, callee pops 10 argument bytes.
; Registers: AX = function result; prologue saves BP/DS/ES/SI/DI; other registers and flags
; may change.
; Direct CS state: none.
; Original INT 3 breakpoint is retained at entry. The filename copy has no length guard; all
; frame and call behavior is preserved.
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
    mov ax, word ptr [bp+0eh]
    mov ds, ax
    mov ax, ss
    mov es, ax
    mov si, word ptr [bp+0ch]
    mov cl, byte ptr [si]
    xor ch, ch
    inc si
    mov di, bp
    sub di, word ptr 84h
    mov word ptr [bp+0eh], es
    mov word ptr [bp+0ch], di
    rep movsb
    mov byte ptr es:[di], 0
    pop ds
    push ds
    mov dx, word ptr [bp+0ch]
    mov ax, word ptr [bp+0eh]
    mov ds, ax
    mov al, 0
    mov ah, PcxDosOpenFile
    int PcxDosInterrupt
    pop ds
    mov word ptr [PcxReadState+PcxRsFileHandle], ax
    jae PcxFileSelectReadBuffer
    mov word ptr [bp-2], PcxStatusOpenFailed
    jmp short PcxFileReturnStatus
PcxFileSelectReadBuffer:
    mov ax, seg PcxSelectedDisplay
    mov es, ax
    mov di, offset PcxDefaultReadBuffer
    cmp word ptr [PcxReadState+PcxRsBufferSegment], -1
    je PcxFileResetFilePosition
    mov ax, word ptr [PcxReadState+PcxRsBufferSegment]
    mov es, ax
    mov di, word ptr [PcxReadState+PcxRsBufferOffset]
PcxFileResetFilePosition:
    mov word ptr [PcxReadState+PcxRsPositionHigh], 0
    mov word ptr [PcxReadState+PcxRsPositionLow], 0
    push ds
    mov bx, word ptr [PcxReadState+PcxRsFileHandle]
    mov cx, word ptr [PcxReadState+PcxRsBufferBytes]
    mov dx, di
    mov ax, es
    mov ds, ax
    mov ah, PcxDosReadFile
    int PcxDosInterrupt
    pop ds
    jae PcxFileDisplayImage
    mov word ptr [bp-2], PcxStatusReadFailed
    jmp short PcxFileCloseHandle
PcxFileDisplayImage:
    mov ax, es
    push ax
    push di
    mov ax, word ptr [PcxReadState+PcxRsBufferBytes]
    sub ax, PcxWorkBufferReserve
    push ax
    mov ax, word ptr [bp+0ah]
    push ax
    mov ax, word ptr [bp+8]
    push ax
    mov ax, word ptr [bp+6]
    push ax
    call far ptr PcxDisplayBuffer
    mov word ptr [bp-2], ax
PcxFileCloseHandle:
    mov bx, word ptr [PcxReadState+PcxRsFileHandle]
    mov ah, PcxDosCloseFile
    int PcxDosInterrupt
PcxFileReturnStatus:
    mov word ptr [PcxReadState+PcxRsFileHandle], 0ffffh
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ah
PcxDisplayFile endp

; Advances the tracked file position, seeks and reads more bytes with DOS INT PcxDosInterrupt AH=42h/3Fh.
; Advances the 32-bit file position, seeks and refills; AX = buffer offset, CF = error.
; Pascal stack equivalent (no interface declaration): function
; PcxRefillReadBuffer(ConsumedBufferOffset: Word): Word;
; Stack: BP+06h = ConsumedBufferOffset; FAR return, callee pops 2 argument bytes.
; Registers: prologue saves BP/DS/ES/SI/DI; other registers and flags may change.
; Direct CS state: none.
; Carry from DOS read survives the return. With no open handle, AX comes from an unwritten
; local; the original CF-set path is preserved.
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
    cmp word ptr [PcxReadState+PcxRsFileHandle], -1
    jne PcxRefillSelectReadBuffer
    stc
    jmp short PcxRefillReturnStatus
PcxRefillSelectReadBuffer:
    mov ax, ds
    mov es, ax
    mov di, offset PcxDefaultReadBuffer
    cmp word ptr [PcxReadState+PcxRsBufferSegment], -1
    je PcxRefillAdvanceFilePosition
    mov ax, word ptr [PcxReadState+PcxRsBufferSegment]
    mov es, ax
    mov di, word ptr [PcxReadState+PcxRsBufferOffset]
PcxRefillAdvanceFilePosition:
    mov ax, word ptr [bp+6]
    sub ax, di
    add word ptr [PcxReadState+PcxRsPositionLow], ax
    jae PcxRefillSeekAndRead
    add word ptr [PcxReadState+PcxRsPositionHigh], 1
PcxRefillSeekAndRead:
    mov bx, word ptr [PcxReadState+PcxRsFileHandle]
    mov cx, word ptr [PcxReadState+PcxRsPositionHigh]
    mov dx, word ptr [PcxReadState+PcxRsPositionLow]
    mov al, 0
    mov ah, PcxDosSeekFile
    int PcxDosInterrupt
    push ds
    mov bx, word ptr [PcxReadState+PcxRsFileHandle]
    mov cx, word ptr [PcxReadState+PcxRsBufferBytes]
    mov dx, di
    mov ax, es
    mov ds, ax
    mov ah, PcxDosReadFile
    int PcxDosInterrupt
    pop ds
    mov word ptr [bp-2], di
PcxRefillReturnStatus:
    pop dx
    pop cx
    pop bx
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 2
PcxRefillReadBuffer endp

; Printer setup and raster output.

; Validates printer device/resolution/scale settings and stores the selected policy.
; Pascal stack equivalent (no interface declaration): function
; PcxConfigurePrinter(PrinterPort: Word; PrinterDeviceClass: Word; ResolutionClass: Word;
; ScaleMode: Word; ResetEnabled: Word; FormFeedEnabled: Word): Integer;
; Stack: BP+10h = PrinterPort; BP+0Eh = PrinterDeviceClass; BP+0Ch = ResolutionClass; BP+0Ah =
; ScaleMode; BP+08h = ResetEnabled; BP+06h = FormFeedEnabled; FAR return, callee pops 12
; argument bytes.
; Registers: prologue saves BP/DS/ES/SI/DI; other registers and flags may change.
; Direct CS state: none.
; Only device class and port are range-checked here; other policy words are stored
; as supplied. This is the original validation behavior.
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
    mov ax, word ptr [bp+0eh]
    cmp ax, 0
    jb PcxPrintCfgInvalidDeviceClass
    cmp ax, 1
    jbe PcxPrintCfgCheckPort
PcxPrintCfgInvalidDeviceClass:
    mov word ptr [bp-2], 0fff0h
    jmp short PcxPrintCfgReturnStatus
PcxPrintCfgCheckPort:
    mov word ptr [PcxPrinterDeviceClass], ax
    mov ax, word ptr [bp+10h]
    cmp ax, 0
    jb PcxPrintCfgInvalidPort
    cmp ax, 2
    jbe PcxPrintCfgStorePolicy
PcxPrintCfgInvalidPort:
    mov word ptr [bp-2], 0ffefh
    jmp short PcxPrintCfgReturnStatus
PcxPrintCfgStorePolicy:
    mov word ptr [PcxPrinterState+PcxPsPortIndex], ax
    mov ax, word ptr [bp+0ch]
    mov word ptr [PcxPrinterResolutionClass], ax
    mov ax, word ptr [bp+0ah]
    mov word ptr [PcxPrinterState+PcxPsScaleMode], ax
    mov ax, word ptr [bp+6]
    mov word ptr [PcxPrinterState+PcxPsFormFeedEnabled], ax
    mov ax, word ptr [bp+8]
    mov word ptr [PcxPrinterState+PcxPsResetEnabled], ax
    mov word ptr [bp-2], 0
PcxPrintCfgReturnStatus:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PcxConfigurePrinter endp

; Sets raster position/row width and emits printer setup command strings.
; Pascal: function PcxBeginPrinterImage(SourceRowBytes, PrinterX, PrinterY: Word): Integer;
; Stack: BP+06h = PrinterY; BP+08h = PrinterX; BP+0Ah = SourceRowBytes; FAR return, callee
; pops 6 argument bytes.
; Registers: AX = function result; prologue saves BP/DS/ES/SI/DI; other registers and flags
; may change.
; Direct CS state: none.
; Original success path does not initialize the status local at BP-2; AX is
; therefore unspecified on success. The failure status and all bytes are retained.
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
    mov byte ptr [PcxPrinterState+PcxPsAlternateRow], 1
    mov ax, word ptr [bp+0ah]
    mov cx, word ptr [PcxPrinterState+PcxPsScaleMode]
    cmp cx, 0
    je PcxPrintBeginStoreRowBytes
    cmp cx, 1
    jne PcxPrintBeginCheckHalfScale
    shr ax, 1
    shr ax, 1
    mov cx, ax
    add ax, cx
    add ax, cx
    jmp short PcxPrintBeginStoreRowBytes
PcxPrintBeginCheckHalfScale:
    cmp cx, 2
    jne PcxPrintBeginCheckQuarterScale
    shr ax, 1
    jmp short PcxPrintBeginStoreRowBytes
PcxPrintBeginCheckQuarterScale:
    cmp cx, 3
    jne PcxPrintBeginCheckDoubleScale
    shr ax, 1
    shr ax, 1
    jmp short PcxPrintBeginStoreRowBytes
PcxPrintBeginCheckDoubleScale:
    cmp cx, 4
    jne PcxPrintBeginStoreRowBytes
    shl ax, 1
PcxPrintBeginStoreRowBytes:
    mov word ptr [PcxPrinterState+PcxPsScanlineBytes], ax
    cmp word ptr [PcxPrinterResolutionClass], 1
    je PcxPrintBeginFormatRowBytes
    cmp word ptr [PcxPrinterResolutionClass], 2
    je PcxPrintBeginFormatRowBytes
    shr ax, 1
PcxPrintBeginFormatRowBytes:
    mov bx, 0
    push bx
    push ax
    push es
    mov di, offset PcxPrinterState + 05dh
    push di
    call far ptr PcxFormatUnsignedDecimal
    mov di, offset PcxPrinterState + PcxPsScanlineCommand
    add al, 3
    mov byte ptr es:[di], al
    mov ax, 0
    push ax
    mov ax, word ptr [bp+8]
    push ax
    push es
    mov di, offset PcxPrinterState + 02ch
    push di
    call far ptr PcxFormatUnsignedDecimal
    add di, ax
    mov byte ptr es:[di], 78h
    inc ax
    inc di
    push ax
    mov ax, 0
    push ax
    mov ax, word ptr [bp+6]
    push ax
    push es
    push di
    call far ptr PcxFormatUnsignedDecimal
    pop bx
    add di, ax
    mov byte ptr es:[di], 59h
    inc ax
    add ax, bx
    mov di, offset PcxPrinterState + PcxPsPositionCommand
    add al, 3
    mov byte ptr es:[di], al
    mov dx, word ptr [PcxPrinterState+PcxPsPortIndex]
    mov ah, 2
    int PcxPrinterInterrupt
    test ah, 29h
    je PcxPrintBeginCheckReset
    mov word ptr [bp-2], 0ffeeh
    jmp short PcxPrintBeginReturnStatus
PcxPrintBeginCheckReset:
    cmp word ptr [PcxPrinterState+PcxPsResetEnabled], 1
    jne PcxPrintBeginSendPosition
    mov si, offset PcxPrinterState + PcxPsResetCommand
    call far ptr PcxSendPrinterString
    mov si, offset PcxPrinterState + PcxPsCopiesCommand
    call far ptr PcxSendPrinterString
PcxPrintBeginSendPosition:
    mov si, offset PcxPrinterState + PcxPsOrientationCmd
    call far ptr PcxSendPrinterString
    mov si, offset PcxPrinterState + PcxPsPositionCommand
    call far ptr PcxSendPrinterString
    cmp word ptr [PcxPrinterResolutionClass], 1
    je PcxPrintBeginSelect300Dpi
    cmp word ptr [PcxPrinterResolutionClass], 2
    je PcxPrintBeginSelect100Dpi
    mov si, offset PcxPrinterState + PcxPsResolution150
    call far ptr PcxSendPrinterString
    jmp short PcxPrintBeginStartRaster
PcxPrintBeginSelect100Dpi:
    mov si, offset PcxPrinterState + PcxPsResolution100
    call far ptr PcxSendPrinterString
    jmp short PcxPrintBeginStartRaster
PcxPrintBeginSelect300Dpi:
    mov si, offset PcxPrinterState + PcxPsResolution300
    call far ptr PcxSendPrinterString
PcxPrintBeginStartRaster:
    mov si, offset PcxPrinterState + PcxPsBeginRasterCmd
    call far ptr PcxSendPrinterString
PcxPrintBeginReturnStatus:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 6
PcxBeginPrinterImage endp

; Sends the end-raster command and the optional form-feed command.
; Pascal: procedure PcxEndPrinterImage;
; Stack: FAR return, callee pops 0 argument bytes.
; Registers: prologue saves BP/DS/ES/SI/DI; other registers and flags may change.
; Direct CS state: none.
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
    mov si, offset PcxPrinterState + PcxPsEndRasterCmd
    call far ptr PcxSendPrinterString
    cmp word ptr [PcxPrinterState+PcxPsFormFeedEnabled], 1
    jne PcxPrinterEndReturn
    mov si, offset PcxPrinterState + PcxPsFormFeedCommand
    call far ptr PcxSendPrinterString
PcxPrinterEndReturn:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf
PcxEndPrinterImage endp

; RLE-decodes a one-plane, one-bit PCX into printer scanlines; returns toolkit status.
; Pascal stack equivalent (no interface declaration): function PcxPrintBuffer(PcxImagePointer:
; Pointer; AvailableBufferBytes: Word; PrinterX: Word; PrinterY: Word): Integer;
; Stack: BP+0Ch = PcxImagePointer; BP+0Ah = AvailableBufferBytes; BP+08h = PrinterX; BP+06h =
; PrinterY; FAR return, callee pops 10 argument bytes.
; Registers: prologue saves BP/DS/ES/SI/DI; other registers and flags may change.
; Direct CS state: none.
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
    mov ax, word ptr [bp+0eh]
    mov ds, ax
    mov si, word ptr [bp+0ch]
    mov ax, seg PcxSelectedDisplay
    mov es, ax
    mov word ptr [bp-0ch], si
    mov bx, word ptr [bp+0ah]
    add bx, word ptr [bp-0ch]
    dec bx
    mov word ptr [bp-0eh], bx
    mov al, byte ptr [si]
    cmp al, PcxManufacturerByte
    je PcxPrintBufferCheckMonochrome
    mov word ptr [bp-2], PcxStatusBadHeader
    jmp near ptr PcxPrintBufferReturnStatus
PcxPrintBufferCheckMonochrome:
    cmp byte ptr [si+PcxHdrPlaneCount], 1
    jne PcxPrintBufferBadFormat
    cmp byte ptr [si+PcxHdrBitsPerPixel], 1
    jne PcxPrintBufferBadFormat
    jmp short PcxPrintBufferComputeRowBytes
PcxPrintBufferBadFormat:
    mov word ptr [bp-2], PcxStatusPrintFormat
    jmp near ptr PcxPrintBufferReturnStatus
PcxPrintBufferComputeRowBytes:
    mov ax, word ptr [si+PcxHdrMaxX]
    sub ax, word ptr [si+PcxHdrMinX]
    inc ax
    cwd
    mov bx, 8
    div bx
    mov cx, dx
    mov word ptr [bp-8], ax
    dec word ptr [bp-8]
    mov byte ptr [bp-6], 0
    cmp cl, 0
    je PcxPrintBufferSetupRaster
    mov byte ptr [bp-6], 1
    mov al, 80h
    dec cl
    sar al, cl
    mov byte ptr [bp-4], al
    inc word ptr [bp-8]
PcxPrintBufferSetupRaster:
    mov bx, word ptr [si+PcxHdrMaxY]
    sub bx, word ptr [si+PcxHdrMinY]
    inc bx
    mov word ptr es:[PcxPrintedSourceRow], bx
    mov ax, word ptr [si+PcxHdrBytesPerLine]
    mov word ptr [bp-0ah], ax
    push ax
    mov ax, word ptr [bp+8]
    push ax
    mov ax, word ptr [bp+6]
    push ax
    call far ptr PcxBeginPrinterImage
    mov ax, seg PcxSelectedDisplay
    mov es, ax
    mov di, offset PcxPrinterScanline
    mov ax, word ptr [bp+0eh]
    mov ds, ax
    mov si, word ptr [bp+0ch]
    add si, word ptr PcxHeaderBytes
    mov bx, 0
    cld
PcxPrintBufferReadPacket:
    mov cx, 1
    lodsb
    mov ah, al
    and ah, PcxRleRunMarker
    cmp ah, PcxRleRunMarker
    jne PcxPrintBufferEmitRunByte
    mov cl, al
    sub cl, PcxRleRunMarker
    lodsb
PcxPrintBufferEmitRunByte:
    cmp bx, word ptr [bp-8]
    jb PcxPrintBufferWriteWholeByte
    ja PcxPrintBufferAdvanceByte
    cmp byte ptr [bp-6], 1
    jne PcxPrintBufferWriteWholeByte
    push ax
    mov ah, byte ptr [bp-4]
    and al, ah
    xor ah, 0ffh
    or al, ah
    mov byte ptr es:[bx+di], al
    pop ax
    jmp short PcxPrintBufferAdvanceByte
PcxPrintBufferWriteWholeByte:
    mov byte ptr es:[bx+di], al
PcxPrintBufferAdvanceByte:
    inc bx
    cmp bx, word ptr [bp-0ah]
    jne PcxPrintBufferFinishRun
    mov byte ptr es:[bx+di-1], 0ffh
    push ax
    push cx
    call far ptr PcxPrintScanline
    pop cx
    pop ax
    jae PcxPrintBufferNextRow
    mov word ptr [bp-2], PcxStatusPrintAborted
    jmp short PcxPrintBufferEndRaster
PcxPrintBufferNextRow:
    xor bx, bx
    dec word ptr es:[PcxPrintedSourceRow]
    je PcxPrintBufferSuccess
PcxPrintBufferFinishRun:
    loop PcxPrintBufferEmitRunByte
    cmp si, word ptr [bp-0eh]
    jb PcxPrintBufferReadNextPacket
    push si
    call far ptr PcxRefillReadBuffer
    jb PcxPrintBufferReturnStatus
    mov si, ax
PcxPrintBufferReadNextPacket:
    jmp short PcxPrintBufferReadPacket
PcxPrintBufferSuccess:
    mov word ptr [bp-2], 0
PcxPrintBufferEndRaster:
    call far ptr PcxEndPrinterImage
PcxPrintBufferReturnStatus:
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 0ah
PcxPrintBuffer endp

; Sends a Pascal short command string through BIOS printer output.
; Pascal: internal register helper; no stack declaration retained.
; Registers/stack: DS:SI = length-prefixed command; DS = toolkit DATA for printer state.
; AX/CX/DX/SI and flags scratch; FAR return, no stack arguments.
; Direct CS state: none.
; Original LOOP executes even for a zero-length string; retain its underflow behavior.
PcxSendPrinterString proc far
    lodsb
    mov cl, al
    xor ch, ch
    mov dx, word ptr [PcxPrinterState+PcxPsPortIndex]
PcxPrinterCmdSendByte:
    lodsb
    mov ah, 0
    int PcxPrinterInterrupt
    loop PcxPrinterCmdSendByte
    retf
PcxSendPrinterString endp

; Scales a printer scanline, sends inverted raster bytes, and returns CF set on Escape.
; Pascal stack equivalent (no interface declaration): procedure PcxPrintScanline;
; Stack: FAR return, callee pops 0 argument bytes.
; Registers: prologue saves BP/DS/ES/SI/DI; other registers and flags may change.
; Direct CS state: none.
; CF is the meaningful result. AX is loaded from an unwritten status local in the original
; routine.
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
    mov word ptr [bp-4], 0
    mov ax, seg PcxSelectedDisplay
    mov es, ax
    mov si, offset PcxPrinterScanline
    mov di, si
    cmp word ptr [PcxPrinterState+PcxPsScaleMode], 0
    jne PcxPrintRowCheckScale
    jmp near ptr PcxPrintRowCheckResolution
PcxPrintRowCheckScale:
    cmp word ptr [PcxPrinterState+PcxPsScaleMode], 1
    je PcxPrintRowThreeQuarterScale
    jmp near ptr PcxPrintRowCheckHalfScale
PcxPrintRowThreeQuarterScale:
    mov ax, word ptr [PcxPrintedSourceRow]
    and ax, 3
    cmp ax, 0
    jne PcxPrintRowPackThreeQuarter
    jmp near ptr PcxPrintRowReturnSuccess
PcxPrintRowPackThreeQuarter:
    mov cx, word ptr [PcxPrinterState+PcxPsScanlineBytes]
PcxPrintRowLoopThreeQuarter:
    mov ah, byte ptr [si]
    and ah, 0e0h
    mov al, byte ptr [si]
    and al, 0eh
    shl al, 1
    or ah, al
    mov al, byte ptr [si+1]
    and al, 0c0h
    rol al, 1
    rol al, 1
    or ah, al
    mov byte ptr [di], ah
    mov ah, byte ptr [si+1]
    shl ah, 1
    shl ah, 1
    mov al, ah
    and ah, 80h
    and al, 38h
    shl al, 1
    or ah, al
    mov al, byte ptr [si+2]
    and al, 0e0h
    shr al, 1
    shr al, 1
    shr al, 1
    shr al, 1
    or ah, al
    mov al, byte ptr [si+2]
    and al, 8
    shr al, 1
    shr al, 1
    shr al, 1
    or ah, al
    mov byte ptr [di+1], ah
    mov ah, byte ptr [si+2]
    and ah, 6
    ror ah, 1
    ror ah, 1
    ror ah, 1
    mov al, byte ptr [si+3]
    and al, 0e0h
    shr al, 1
    shr al, 1
    or ah, al
    mov al, byte ptr [si+3]
    and al, 0eh
    shr al, 1
    or ah, al
    mov byte ptr [di+2], ah
    add si, 4
    add di, 3
    sub cx, 3
    cmp cx, 0
    jg PcxPrintRowLoopThreeQuarter
    jmp near ptr PcxPrintRowCheckResolution
PcxPrintRowCheckHalfScale:
    cmp word ptr [PcxPrinterState+PcxPsScaleMode], 2
    jne PcxPrintRowCheckQuarterScale
    mov ax, word ptr [PcxPrintedSourceRow]
    and ax, 1
    cmp ax, 0
    je PcxPrintRowHalfScale
    jmp near ptr PcxPrintRowReturnSuccess
PcxPrintRowHalfScale:
    mov cx, word ptr [PcxPrinterState+PcxPsScanlineBytes]
PcxPrintRowPackHalfBytes:
    mov ah, byte ptr [si]
    and ah, PcxRleRunMarker
    mov al, byte ptr [si]
    and al, 0ch
    shl al, 1
    shl al, 1
    or ah, al
    mov al, byte ptr [si+1]
    and al, 0c0h
    shr al, 1
    shr al, 1
    shr al, 1
    shr al, 1
    or ah, al
    mov al, byte ptr [si+1]
    and al, 0ch
    shr al, 1
    shr al, 1
    or ah, al
    mov byte ptr [di], ah
    add si, 2
    inc di
    loop PcxPrintRowPackHalfBytes
    jmp near ptr PcxPrintRowCheckResolution
PcxPrintRowCheckQuarterScale:
    cmp word ptr [PcxPrinterState+PcxPsScaleMode], 3
    jne PcxPrintRowCheckDoubleScale
    mov ax, word ptr [PcxPrintedSourceRow]
    and ax, 3
    cmp ax, 0
    je PcxPrintRowQuarterScale
    jmp near ptr PcxPrintRowReturnSuccess
PcxPrintRowQuarterScale:
    mov cx, word ptr [PcxPrinterState+PcxPsScanlineBytes]
PcxPrintRowPackQuarterBytes:
    mov ah, byte ptr [si]
    and ah, 80h
    mov al, byte ptr [si]
    and al, 8
    shl al, 1
    shl al, 1
    shl al, 1
    or ah, al
    mov al, byte ptr [si+1]
    and al, 80h
    shr al, 1
    shr al, 1
    or ah, al
    mov al, byte ptr [si+1]
    and al, 8
    shl al, 1
    or ah, al
    mov al, byte ptr [si+2]
    and al, 80h
    shr al, 1
    shr al, 1
    shr al, 1
    shr al, 1
    or ah, al
    mov al, byte ptr [si+2]
    and al, 8
    shr al, 1
    or ah, al
    mov al, byte ptr [si+3]
    and al, 80h
    rol al, 1
    rol al, 1
    or ah, al
    mov al, byte ptr [si+3]
    and al, 8
    shr al, 1
    shr al, 1
    shr al, 1
    or ah, al
    mov byte ptr [di], ah
    add si, 4
    inc di
    loop PcxPrintRowPackQuarterBytes
    jmp short PcxPrintRowCheckResolution
PcxPrintRowCheckDoubleScale:
    cmp word ptr [PcxPrinterState+PcxPsScaleMode], 4
    je PcxPrintRowDoubleScale
    jmp short PcxPrintRowCheckResolution
PcxPrintRowDoubleScale:
    mov cx, word ptr [PcxPrinterState+PcxPsScanlineBytes]
PcxPrintRowExpandSourceByte:
    mov bx, cx
    dec bx
    mov dh, byte ptr [bx+si]
    shl bx, 1
    inc bx
    push cx
    mov cx, 2
PcxPrintRowExpandNibble:
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
    mov byte ptr [bx+di], al
    dec bx
    shr dh, 1
    shr dh, 1
    shr dh, 1
    shr dh, 1
    loop PcxPrintRowExpandNibble
    pop cx
    loop PcxPrintRowExpandSourceByte
PcxPrintRowCheckResolution:
    cmp word ptr [PcxPrinterResolutionClass], 1
    je PcxPrintRowSendRaster
    cmp word ptr [PcxPrinterResolutionClass], 2
    je PcxPrintRowSendRaster
    xor byte ptr [PcxPrinterState+PcxPsAlternateRow], 1
    cmp byte ptr [PcxPrinterState+PcxPsAlternateRow], 1
    jne PcxPrintRowPackResolution
    jmp near ptr PcxPrintRowReturnSuccess
PcxPrintRowPackResolution:
    mov si, offset PcxPrinterScanline
    mov di, si
    mov cx, word ptr [PcxPrinterState+PcxPsScanlineBytes]
    shr cx, 1
PcxPrintRowPackResolutionBytes:
    mov ah, byte ptr [si]
    and ah, PcxRleRunMarker
    mov al, byte ptr [si]
    and al, 0ch
    shl al, 1
    shl al, 1
    or ah, al
    mov al, byte ptr [si+1]
    and al, 0c0h
    shr al, 1
    shr al, 1
    shr al, 1
    shr al, 1
    or ah, al
    mov al, byte ptr [si+1]
    and al, 0ch
    shr al, 1
    shr al, 1
    or ah, al
    mov byte ptr [di], ah
    add si, 2
    inc di
    loop PcxPrintRowPackResolutionBytes
PcxPrintRowSendRaster:
    mov si, offset PcxPrinterState + PcxPsScanlineCommand
    call far ptr PcxSendPrinterString
    mov al, 57h
    mov dx, word ptr [PcxPrinterState+PcxPsPortIndex]
    mov ah, 0
    int PcxPrinterInterrupt
    mov si, offset PcxPrinterScanline
    mov dx, word ptr [PcxPrinterState+PcxPsPortIndex]
    mov cx, word ptr [PcxPrinterState+PcxPsScanlineBytes]
    cmp word ptr [PcxPrinterResolutionClass], 1
    je PcxPrintRowSendRasterByte
    cmp word ptr [PcxPrinterResolutionClass], 2
    je PcxPrintRowSendRasterByte
    shr cx, 1
PcxPrintRowSendRasterByte:
    lodsb
    xor al, 0ffh
    mov ah, 0
    int PcxPrinterInterrupt
    loop PcxPrintRowSendRasterByte
    cmp word ptr [PcxPrinterState+PcxPsScaleMode], 4
    jne PcxPrintRowCheckEscape
    inc word ptr [bp-4]
    cmp word ptr [bp-4], 2
    jae PcxPrintRowCheckEscape
    jmp near ptr PcxPrintRowCheckResolution
PcxPrintRowCheckEscape:
    push bp
    mov ah, 1
    int PcxKeyboardInterrupt
    pop bp
    je PcxPrintRowReturnSuccess
    push bp
    mov ah, 0
    int PcxKeyboardInterrupt
    pop bp
    cmp al, PcxEscapeCharacter
    jne PcxPrintRowReturnSuccess
    stc
    jmp short PcxPrintRowReturnStatus
PcxPrintRowReturnSuccess:
    clc
PcxPrintRowReturnStatus:
    mov ax, word ptr [bp-2]
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

; Writes unsigned 32-bit decimal digits followed by a dollar sign; AX = digit count.
; Pascal: function PcxFormatUnsignedDecimal(UnsignedValue: LongInt; DigitBuffer: Pointer):
; Word;
; Stack: BP+06h = DigitBuffer (far pointer); BP+0Ah = UnsignedValue; FAR return, callee pops 8
; argument bytes.
; Registers: AX = function result; prologue saves BP/DS/ES/SI/DI; other registers and flags
; may change.
; Direct CS state: none.
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
    mov ax, word ptr [bp+8]
    mov es, ax
    mov di, word ptr [bp+6]
    mov dx, word ptr [bp+0ch]
    mov ax, word ptr [bp+0ah]
    xor cx, cx
    xor si, si
    mov byte ptr [bp-4], PcxDecimalZero
PcxDecimalSubtractDivisor:
    cmp dx, word ptr [si+PcxPrinterState+PcxPsDivisorHighWord]
    je PcxDecimalCompareLowWord
    jb PcxDecimalFinishDigit
    jmp short PcxDecimalIncrementDigit
PcxDecimalCompareLowWord:
    cmp ax, word ptr [si+PcxPrinterState+PcxPsDecimalDivisors]
    jb PcxDecimalFinishDigit
PcxDecimalIncrementDigit:
    sub ax, word ptr [si+PcxPrinterState+PcxPsDecimalDivisors]
    sbb dx, word ptr [si+PcxPrinterState+PcxPsDivisorHighWord]
    inc byte ptr [bp-4]
    jmp short PcxDecimalSubtractDivisor
PcxDecimalFinishDigit:
    cmp cx, 0
    jne PcxDecimalWriteDigit
    cmp byte ptr [bp-4], PcxDecimalZero
    je PcxDecimalNextDivisor
PcxDecimalWriteDigit:
    mov bl, byte ptr [bp-4]
    mov byte ptr es:[di], bl
    inc cx
    inc di
PcxDecimalNextDivisor:
    cmp si, 24h
    je PcxDecimalEnsureZero
    mov byte ptr [bp-4], PcxDecimalZero
    add si, 4
    jmp short PcxDecimalSubtractDivisor
PcxDecimalEnsureZero:
    cmp cx, 0
    jne PcxDecimalTerminateString
    mov byte ptr es:[di], PcxDecimalZero
    inc cx
    inc di
PcxDecimalTerminateString:
    mov byte ptr es:[di], PcxDecimalTerminator
    mov word ptr [bp-2], cx
    mov ax, word ptr [bp-2]
    pop di
    pop si
    pop es
    pop ds
    mov sp, bp
    pop bp
    retf 8
PcxFormatUnsignedDecimal endp

; Installs printer defaults, length-prefixed escape strings and powers of ten.
; Pascal: procedure PcxInitializePrinterState;
; Stack: FAR return, callee pops 0 argument bytes.
; Registers: prologue saves BP/DS/ES/SI/DI; other registers and flags may change.
; Direct CS state: none.
; Command records below are Pascal short strings. Their leading byte is a
; length, followed by the original printer escape sequence. Decimal divisors
; are stored low word first, from 1,000,000,000 down through 1.
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
    mov word ptr [bp-2], 0
    mov word ptr [PcxPrinterDeviceClass], 0
    mov word ptr [PcxPrinterResolutionClass], 1
    mov word ptr [PcxPrinterState+PcxPsPortIndex], 0
    mov word ptr [PcxPrinterState+PcxPsScaleMode], 0
    mov word ptr [PcxPrinterState+PcxPsFormFeedEnabled], 1
    mov word ptr [PcxPrinterState+PcxPsResetEnabled], 1
    mov si, offset PcxPrinterState + PcxPsResetCommand
    mov byte ptr [si], 2
    inc si
    mov byte ptr [si], 1bh
    inc si
    mov byte ptr [si], 45h
    inc si
    mov si, offset PcxPrinterState + PcxPsCopiesCommand
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
    mov si, offset PcxPrinterState + PcxPsOrientationCmd
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
    mov si, offset PcxPrinterState + PcxPsMarginCommand
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
    mov si, offset PcxPrinterState + PcxPsFormFeedCommand
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
    mov si, offset PcxPrinterState + PcxPsPositionCommand
    mov byte ptr [si], 3
    inc si
    mov byte ptr [si], 1bh
    inc si
    mov byte ptr [si], 2ah
    inc si
    mov byte ptr [si], 70h
    inc si
    mov si, offset PcxPrinterState + PcxPsResolution100
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
    mov si, offset PcxPrinterState + PcxPsResolution150
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
    mov si, offset PcxPrinterState + PcxPsResolution300
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
    mov si, offset PcxPrinterState + PcxPsBeginRasterCmd
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
    mov si, offset PcxPrinterState + PcxPsEndRasterCmd
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
    mov si, offset PcxPrinterState + PcxPsScanlineCommand
    mov byte ptr [si], 3
    inc si
    mov byte ptr [si], 1bh
    inc si
    mov byte ptr [si], 2ah
    inc si
    mov byte ptr [si], 62h
    inc si
    mov si, offset PcxPrinterState + PcxPsDecimalDivisors
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
    mov ax, word ptr [bp-2]
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
