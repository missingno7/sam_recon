; ProGraphx 2.0 by Peder Jungck, assembly implementation for PROGRPHX.
; EGA/VGA drawing, sprites, fonts and video-buffer copies; undefined scratch is retained.

; EGA/VGA hardware ports and memory segments.
PgBiosVideoInterrupt            equ 10h
PgMouseInterrupt                equ 33h
PgAttributePort                 equ 3c0h
PgSequencerIndexPort            equ 3c4h
PgSequencerDataPort             equ 3c5h
PgGraphicsIndexPort             equ 3ceh
PgGraphicsDataPort              equ 3cfh
PgCrtcIndexPort                 equ 3d4h
PgInputStatus1Port              equ 3dah
PgVideoSegment                  equ 0a000h
PgBiosDataSegment               equ 40h
PgBdaCrtcPortOffset             equ 63h
PgVerticalRetraceBit            equ 8

; Geometry of the game's 320x200 planar screen and VRAM tile cache.
PgDefaultStrideBytes            equ 40
PgScreenLastByte                equ 39
PgScreenLastPixel               equ 319
PgScreenLastRow                 equ 199
PgVideoPageBytes                equ 2000h
PgCachedTilesOffset             equ 0fa00h

; Graphics-controller and sequencer register indices.
PgSeqMapMask                    equ 2
PgGcSetReset                    equ 0
PgGcEnableSetReset              equ 1
PgGcDataRotate                  equ 3
PgGcReadMapSelect               equ 4
PgGcMode                        equ 5
PgGcColorDontCare               equ 7
PgGcBitMask                     equ 8
PgCrtcStartHigh                 equ 0ch
PgCrtcStartLow                  equ 0dh
PgCrtcOffset                    equ 13h
PgCrtcLineCompare               equ 18h

; Packed OUT DX,AX values: register index in AL, register data in AH.
PgMapMaskAllPlanes              equ 0f02h
PgMapMaskPlane3                 equ 0802h
PgEnableSetResetAll             equ (00fh shl 8) + PgGcEnableSetReset
PgBitMaskAllPixels              equ (0ffh shl 8) + PgGcBitMask
PgReadMapPlane3                 equ (003h shl 8) + PgGcReadMapSelect
PgReadMode1Pair                 equ (008h shl 8) + PgGcMode
PgColorCompareAll               equ (00fh shl 8) + PgGcColorDontCare

CODE segment byte public
assume cs:CODE
public PgSetToolboxVideoMode, PgSetBiosVideoMode, PgSetScreenStride, PgPanDisplayAtRetraceStart, PgPanDisplayAtRetraceEnd
public PgSetEgaSplitScanline, PgWaitVerticalRetrace, PgSetVgaSplitScanline, PgSetBorderColor, PgSetPaletteRegister
public PgBlitMasked16x16, PgBlitMasked8x8, PgSetDrawColor, PgFillRectangleByteAligned, PgCapturePlanarRectangle
public PgRestorePlanarRectangle, PgBlitMaskedShifted16x16, PgBlitMaskedShifted8x8, PgOrShifted16x16, PgInitializeRomFonts
public PgSelectRomFont, PgBlitOpaque16x16, PgBlitOpaque8x8, PgCopyCachedVideoTile16x16, PgCopyVideoScreenRegion320x200
public PgCopyStatusBandTemplate

; Font rendering scratch in CS; these routines share state and are not reentrant.
PgTextX                         dw ?
PgTextY                         dw ?
PgFontPixelX                    dw ?
PgFontPixelY                    dw ?
PgTextCsBase                    dw ?
PgFontRowCount                  dw ?
PgGlyphOffset                   dw ?
PgGlyphSegment                  dw ?
PgFontRowIndex                  dw ?
PgGlyphLeftByteMask             dw ?
PgGlyphRightByteMask            dw ?
PgTextCharIndex                 dw ?
PgTextCharCode                  dw ?
PgLeftMasks                     db 0ffh, 7fh, 3fh, 1fh, 0fh, 7, 3, 1
PgPixelMasks                    db 80h, 40h, 20h, 10h, 8, 4, 2, 1
PgTransferRowsRemaining         dw ?
PgTransferRowBytes              dw ?
PgRestoreRowsRemaining          dw ?
PgRestoreFirstByteMaskPair      dw ?
PgRestoreEdgeMaskPair           dw ?
PgRestoreNextByteMaskPair       dw ?
; Row geometry, draw state and clipping boundaries (CS-resident).
PgScreenStrideBytes             dw PgDefaultStrideBytes
; Unused storage retains the original object layout.
UnusedPgToolboxMarker           dw 0666h
; Unused storage retains the original object layout.
UnusedPgBannerNewlines          db 23 dup (10)
; Unused storage retains the original object layout.
UnusedPgProductBanner           db 'ProGraphx EGA/VGA Toolbox', 13, 10, 26
; Unused storage retains the original object layout.
UnusedPgVersionBanner           db 'Version 2.0 320x200 EGA/VGA', 13, 10, 26
; Unused storage retains the original object layout.
UnusedPgCopyrightBanner         db 'Copyright 1991 by Peder Jungck', 13, 10, 26
PgDrawPage                      dw 0
PgDrawColor                     dw 1
PgDrawOperation                 db 0
PgClipLeftByte                  dw 0
PgClipRightByte                 dw PgScreenLastByte
PgClipTopRow                    dw 0
PgClipBottomRow                 dw PgScreenLastRow
PgClipLeftPixel                 dw 0
PgClipRightPixel                dw PgScreenLastPixel

; Video modes, panning and palette control.

; Maps toolbox mode 0/1/other to BIOS 0Dh/10h/12h.
; Pascal: procedure PgSetToolboxVideoMode(ToolboxMode: Word);
; Stack: BP+06h = ToolboxMode; FAR return, callee pops 2 argument bytes.
; Registers: prologue saves BP; other registers and flags may change.
; Direct CS state: none.
; Original mode-0/1 paths retain entry AH; only the fallback clears it.
PgSetToolboxVideoMode proc far
    push bp
    mov bp, sp
    mov ax, word ptr [bp+6]
    cmp al, 0
    jne mode_test_ega640
    mov al, 0dh
    jmp short mode_set_bios
    nop
mode_test_ega640:
    cmp al, 1
    je mode_ega640
    xor ah, ah
    mov al, 12h
    jmp short mode_set_bios
    nop
mode_ega640:
    mov al, 10h
mode_set_bios:
    int PgBiosVideoInterrupt
    pop bp
    retf 2
PgSetToolboxVideoMode endp

; Sets a BIOS video mode directly with AH=0.
; Pascal: procedure PgSetBiosVideoMode(BiosMode: Word);
; Stack: BP+06h = BiosMode; FAR return, callee pops 2 argument bytes.
; Registers: prologue saves BP; other registers and flags may change.
; Direct CS state: none.
PgSetBiosVideoMode proc far
    push bp
    mov bp, sp
    mov ax, word ptr [bp+6]
    xor ah, ah
    int PgBiosVideoInterrupt
    pop bp
    retf 2
PgSetBiosVideoMode endp

; Clamps the planar row stride to 40 bytes and programs CRTC offset.
; Pascal: function PgSetScreenStride(StrideBytes: Word): Integer;
; Stack: BP+06h = StrideBytes; FAR return, callee pops 2 argument bytes.
; Registers: AX = function result; prologue saves BP; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes.
; AX is saved around the register writes; its original entry value is returned.
PgSetScreenStride proc far
    push bp
    mov bp, sp
    mov bx, word ptr [bp+6]
    cmp bx, PgDefaultStrideBytes
    jge PgStrideStoreClampedValue
    mov bx, PgDefaultStrideBytes
PgStrideStoreClampedValue:
    mov word ptr cs:[PgScreenStrideBytes], bx
    push ax
    mov dx, PgCrtcIndexPort
    mov ax, PgCrtcOffset
    out dx, ax
    inc dx
    mov ax, bx
    shr ax, 1
    out dx, ax
    pop ax
    pop bp
    retf 2
PgSetScreenStride endp

; Sets display start after retrace; applies fine pan at the next retrace start.
; Pascal: procedure PgPanDisplayAtRetraceStart(PanPixelX, PanPixelY: Word);
; Stack: BP+06h = PanPixelY; BP+08h = PanPixelX; FAR return, callee pops 4 argument bytes.
; Registers: prologue saves BP; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes.
PgPanDisplayAtRetraceStart proc far
    push bp
    mov bp, sp
    mov dx, PgInputStatus1Port
PgPanStartWaitRetraceStart:
    in al, dx
    test al, PgVerticalRetraceBit
    je PgPanStartWaitRetraceStart
PgPanStartWaitRetraceEnd:
    in al, dx
    test al, PgVerticalRetraceBit
    jne PgPanStartWaitRetraceEnd
    cli
    mov ax, word ptr [bp+6]
    mul word ptr cs:[PgScreenStrideBytes]
    mov cx, word ptr [bp+8]
    shr cx, 1
    shr cx, 1
    shr cx, 1
    add ax, cx
    mov bx, ax
    mov al, PgCrtcStartHigh
    mov dx, PgCrtcIndexPort
    out dx, ax
    mov al, PgCrtcStartLow
    mov ah, bl
    out dx, ax
    sti
    mov dx, PgInputStatus1Port
PgPanStartWaitFinePanRetrace:
    in al, dx
    test al, PgVerticalRetraceBit
    je PgPanStartWaitFinePanRetrace
    cli
    mov ax, word ptr [bp+8]
    and ax, 7
    or al, 10h
    mov ah, al
    mov dx, PgAttributePort
    mov al, 33h
    out dx, al
    xchg ah, al
    out dx, al
    sti
    pop bp
    retf 4
PgPanDisplayAtRetraceStart endp

; Sets display start after retrace; applies fine pan while retrace is clear.
; Pascal: procedure PgPanDisplayAtRetraceEnd(PanPixelX, PanPixelY: Word);
; Stack: BP+06h = PanPixelY; BP+08h = PanPixelX; FAR return, callee pops 4 argument bytes.
; Registers: prologue saves BP; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes.
PgPanDisplayAtRetraceEnd proc far
    push bp
    mov bp, sp
    mov dx, PgInputStatus1Port
PgPanEndWaitRetraceStart:
    in al, dx
    test al, PgVerticalRetraceBit
    je PgPanEndWaitRetraceStart
PgPanEndWaitRetraceEnd:
    in al, dx
    test al, PgVerticalRetraceBit
    jne PgPanEndWaitRetraceEnd
    cli
    mov ax, word ptr [bp+6]
    mul word ptr cs:[PgScreenStrideBytes]
    mov cx, word ptr [bp+8]
    shr cx, 1
    shr cx, 1
    shr cx, 1
    add ax, cx
    mov bx, ax
    mov al, PgCrtcStartHigh
    mov dx, PgCrtcIndexPort
    out dx, ax
    mov al, PgCrtcStartLow
    mov ah, bl
    out dx, ax
    sti
    mov dx, PgInputStatus1Port
PgPanEndWaitFinePanClear:
    in al, dx
    test al, PgVerticalRetraceBit
    jne PgPanEndWaitFinePanClear
    cli
    mov ax, word ptr [bp+8]
    and ax, 7
    or al, 10h
    mov ah, al
    mov dx, PgAttributePort
    mov al, 33h
    out dx, al
    xchg ah, al
    out dx, al
    sti
    pop bp
    retf 4
PgPanDisplayAtRetraceEnd endp

; Programs line compare and its bit-8 overflow for an EGA split screen.
; Pascal: procedure PgSetEgaSplitScanline(SplitScanline: Word);
; Stack: BP+06h = SplitScanline; FAR return, callee pops 2 argument bytes.
; Registers: prologue saves BP; other registers and flags may change.
; Direct CS state: none.
PgSetEgaSplitScanline proc far
    push bp
    mov bp, sp
    mov ax, PgBiosDataSegment
    mov es, ax
    mov dx, word ptr es:[PgBdaCrtcPortOffset]
    add dl, 6
PgEgaSplitWaitRetraceStart:
    in al, dx
    test al, PgVerticalRetraceBit
    jne PgEgaSplitWaitRetraceStart
PgEgaSplitWaitRetraceEnd:
    in al, dx
    test al, PgVerticalRetraceBit
    je PgEgaSplitWaitRetraceEnd
    sub dl, 6
    mov ax, word ptr [bp+6]
    mov bh, ah
    and bh, 1
    mov cl, 4
    shl bh, cl
    mov ah, al
    mov al, PgCrtcLineCompare
    out dx, ax
    mov ah, 11h
    and ah, 0efh
    or ah, bh
    mov al, 7
    out dx, ax
    pop bp
    retf 2
PgSetEgaSplitScanline endp

; Waits for the present retrace to finish, then for the next retrace to begin.
; Pascal: procedure PgWaitVerticalRetrace;
; Stack: FAR return, callee pops 0 argument bytes.
; Registers: prologue saves ES; other registers and flags may change.
; Direct CS state: none.
PgWaitVerticalRetrace proc far
    push es
    xor ax, ax
    mov es, ax
    mov dx, PgInputStatus1Port
    in al, dx
    jmp short PgRetraceTestInitialStatus
PgRetraceTestInitialStatus:
    test al, PgVerticalRetraceBit
    je PgRetraceWaitNextStart
PgRetraceWaitCurrentEnd:
    in al, dx
    jmp short PgRetraceTestCurrentEnd
PgRetraceTestCurrentEnd:
    test al, PgVerticalRetraceBit
    jne PgRetraceWaitCurrentEnd
PgRetraceWaitNextStart:
    in al, dx
    jmp short PgRetraceTestNextStart
PgRetraceTestNextStart:
    test al, PgVerticalRetraceBit
    je PgRetraceWaitNextStart
    pop es
    retf
PgWaitVerticalRetrace endp

; Programs VGA line compare, including overflow bits 8 and 9.
; Pascal: procedure PgSetVgaSplitScanline(SplitScanline: Word);
; Stack: BP+06h = SplitScanline; FAR return, callee pops 2 argument bytes.
; Registers: prologue saves BP; other registers and flags may change.
; Direct CS state: none.
PgSetVgaSplitScanline proc far
    push bp
    mov bp, sp
    push cs
    call near ptr PgWaitVerticalRetrace
    push es
    xor ax, ax
    mov es, ax
    mov dx, PgCrtcIndexPort
    mov al, PgCrtcLineCompare
    out dx, al
    inc dx
    mov ax, word ptr [bp+6]
    out dx, al
    dec dx
    mov al, 7
    out dx, al
    inc dx
    in al, dx
    mov bl, byte ptr [bp+7]
    and bl, 1
    mov cl, 4
    shl bl, cl
    and al, 0efh
    or al, bl
    out dx, al
    dec dx
    mov al, 9
    out dx, al
    inc dx
    in al, dx
    and al, 0bfh
    out dx, al
    jmp short PgVgaSplitMergeHighOverflowBit
    nop
PgVgaSplitMergeHighOverflowBit:
    pop es
    pop bp
    retf 2
PgSetVgaSplitScanline endp

; Sets BIOS border/overscan color with AX=1001h.
; Pascal: procedure PgSetBorderColor(BorderColor: Word);
; Stack: BP+06h = BorderColor; FAR return, callee pops 2 argument bytes.
; Registers: prologue saves BP; other registers and flags may change.
; Direct CS state: none.
PgSetBorderColor proc far
    push bp
    mov bp, sp
    mov ah, 10h
    mov al, 1
    mov bx, word ptr [bp+6]
    mov bh, bl
    int PgBiosVideoInterrupt
    pop bp
    retf 2
PgSetBorderColor endp

; Queries the active BIOS mode and sets it again.
; Pascal stack equivalent (no interface declaration): procedure PgResetCurrentVideoMode;
; Stack: FAR return, callee pops 0 argument bytes.
; Registers: other registers and flags may change.
; Direct CS state: none.
PgResetCurrentVideoMode proc far
    mov ah, 0fh
    int PgBiosVideoInterrupt
    xor ah, ah
    int PgBiosVideoInterrupt
    retf
PgResetCurrentVideoMode endp

; Sets one EGA palette register with BIOS AX=1000h.
; Pascal: procedure PgSetPaletteRegister(PaletteIndex, PaletteColor: Integer);
; Stack: BP+06h = PaletteColor; BP+08h = PaletteIndex; FAR return, callee pops 4 argument
; bytes.
; Registers: prologue saves BP; other registers and flags may change.
; Direct CS state: none.
PgSetPaletteRegister proc far
    push bp
    mov bp, sp
    mov ax, 1000h
    mov bl, byte ptr [bp+8]
    mov bh, byte ptr [bp+6]
    int PgBiosVideoInterrupt
    pop bp
    retf 4
PgSetPaletteRegister endp

; Stores the font orientation: 0 = horizontal, 1/other = opposite vertical paths.
; Pascal stack equivalent (no interface declaration): procedure
; PgSetTextDirection(TextDirection: Word);
; Stack: BP+06h = TextDirection; FAR return, callee pops 2 argument bytes.
; Registers: prologue saves BP; other registers and flags may change.
; Direct CS state: PgTextDirection.
PgSetTextDirection proc far
    push bp
    mov bp, sp
    mov ax, word ptr [bp+6]
    mov word ptr cs:[PgTextDirection], ax
    pop bp
    retf 2
PgSetTextDirection endp

; Fixed-size masked sprites.

; Draws 16 rows of a byte-aligned 32-pixel masked, four-plane sprite.
; Pascal stack equivalent (no interface declaration): procedure
; PgBlitMasked32x16(ImageSourcePointer: Pointer; ByteColumn: Integer; PixelRow: Integer);
; Stack: BP+0Ah = ImageSourcePointer; BP+08h = ByteColumn; BP+06h = PixelRow; FAR return,
; callee pops 8 argument bytes.
; Registers: prologue saves BP/DS/DI/SI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage.
PgBlitMasked32x16 proc far
    push bp
    mov bp, sp
    push ds
    push di
    push si
    lds si, dword ptr [bp+0ah]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+6]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov bx, word ptr [bp+8]
    add bx, ax
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgMask32SelectMapMask
    mov cx, ax
PgMask32AddPageOffset:
    add bx, PgVideoPageBytes
    loop PgMask32AddPageOffset
PgMask32SelectMapMask:
    mov dx, PgSequencerIndexPort
    mov al, 2
    out dx, al
    mov cx, 10h
PgMask32DrawRow:
    mov dx, PgGraphicsIndexPort
    lodsb
    mov ah, 8
    xchg ah, al
    out dx, ax
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    inc bx
    mov dx, PgGraphicsIndexPort
    lodsb
    mov ah, 8
    xchg ah, al
    out dx, ax
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    jmp short PgMask32DrawRightHalf
    nop
PgMask32RowLoopBridge:
    jmp short PgMask32DrawRow
PgMask32DrawRightHalf:
    mov dx, PgGraphicsIndexPort
    inc bx
    lodsb
    mov ah, 8
    xchg ah, al
    out dx, ax
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    inc bx
    mov dx, PgGraphicsIndexPort
    lodsb
    mov ah, 8
    xchg ah, al
    out dx, ax
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    inc bx
    add bx, word ptr cs:[PgScreenStrideBytes]
    dec bx
    dec bx
    dec bx
    dec bx
    loop PgMask32RowLoopBridge
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
PgBlitMasked32x16 endp

; Draws 16 rows of a byte-aligned 16-pixel masked, four-plane sprite.
; Pascal: procedure PgBlitMasked16x16(var ImageSource; ByteColumn, PixelRow: Integer);
; Stack: BP+06h = PixelRow; BP+08h = ByteColumn; BP+0Ah = ImageSource (far pointer); FAR
; return, callee pops 8 argument bytes.
; Registers: prologue saves BP/DS/DI/SI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage.
PgBlitMasked16x16 proc far
    push bp
    mov bp, sp
    push ds
    push di
    push si
    mov di, word ptr cs:[PgScreenStrideBytes]
    dec di
    lds si, dword ptr [bp+0ah]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+6]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov bx, word ptr [bp+8]
    add bx, ax
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgMask16SelectMapMask
    mov cx, ax
PgMask16AddPageOffset:
    add bx, PgVideoPageBytes
    loop PgMask16AddPageOffset
PgMask16SelectMapMask:
    mov dx, PgSequencerIndexPort
    mov al, 2
    out dx, al
    mov cx, 10h
PgMask16DrawRow:
    mov dx, PgGraphicsIndexPort
    lodsb
    mov ah, 8
    xchg ah, al
    out dx, ax
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    inc bx
    mov dx, PgGraphicsIndexPort
    lodsb
    mov ah, 8
    xchg ah, al
    out dx, ax
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    add bx, di
    loop PgMask16DrawRow
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
PgBlitMasked16x16 endp

; Draws eight rows of a byte-aligned 8-pixel masked, four-plane sprite.
; Pascal: procedure PgBlitMasked8x8(var ImageSource; ByteColumn, PixelRow: Integer);
; Stack: BP+06h = PixelRow; BP+08h = ByteColumn; BP+0Ah = ImageSource (far pointer); FAR
; return, callee pops 8 argument bytes.
; Registers: prologue saves BP/DS/DI/SI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage.
; Original nonzero draw-page branch uses entry AX as its loop count; preserved for exactness.
PgBlitMasked8x8 proc far
    push bp
    mov bp, sp
    push ds
    push di
    push si
    lds si, dword ptr [bp+0ah]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+8]
    mov dx, word ptr cs:[PgDrawPage]
    cmp dl, 0
    je PgMask8AddRowOffset
    mov cx, ax
PgMask8AddPageOffset:
    add bx, PgVideoPageBytes
    loop PgMask8AddPageOffset
PgMask8AddRowOffset:
    mov dx, word ptr [bp+6]
    push di
    push ax
    mov ax, dx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    add bx, ax
    mov dx, PgSequencerIndexPort
    mov al, 2
    out dx, al
    mov cx, 8
PgMask8DrawRow:
    mov dx, PgGraphicsIndexPort
    lodsb
    mov ah, 8
    xchg ah, al
    out dx, ax
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    add bx, word ptr cs:[PgScreenStrideBytes]
    loop PgMask8DrawRow
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
PgBlitMasked8x8 endp

PgPlaneRectRowsRemaining        dw 0
; Copies a byte rectangle to the planes selected by the draw-color mask.
; Pascal stack equivalent (no interface declaration): procedure
; PgBlitSinglePlaneRectangle(PlaneDataPointer: Pointer; LeftByteColumn: Word; TopPixelRow:
; Integer; WidthBytes: Word; HeightRows: Word);
; Stack: BP+0Eh = PlaneDataPointer; BP+0Ch = LeftByteColumn; BP+0Ah = TopPixelRow; BP+08h =
; WidthBytes; BP+06h = HeightRows; FAR return, callee pops 12 argument bytes.
; Registers: prologue saves BP/DS/DI/SI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage, PgDrawColor, PgPlaneRectRowsRemaining.
; Original nonzero draw-page branch uses entry AX as its loop count; preserved for exactness.
PgBlitSinglePlaneRectangle proc far
    push bp
    mov bp, sp
    push ds
    push di
    push si
    lds si, dword ptr [bp+0eh]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+0ch]
    mov dx, word ptr cs:[PgDrawPage]
    cmp dl, 0
    je PgPlaneRectAddRowOffset
    mov cx, ax
PgPlaneRectAddPageOffset:
    add bx, PgVideoPageBytes
    loop PgPlaneRectAddPageOffset
PgPlaneRectAddRowOffset:
    mov ax, word ptr [bp+0ah]
    push di
    push ax
    mov ax, ax
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov dx, di
    pop di
    mov ax, dx
    add bx, ax
    mov dx, PgSequencerIndexPort
    mov al, PgSeqMapMask
    out dx, al
    inc dx
    mov ax, word ptr [bp+6]
    mov word ptr cs:[PgPlaneRectRowsRemaining], ax
PgPlaneRectDrawRow:
    mov cx, word ptr [bp+8]
PgPlaneRectCopyByte:
    mov dx, PgSequencerDataPort
    mov ax, word ptr cs:[PgDrawColor]
    mov dx, PgSequencerDataPort
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    inc bx
    loop PgPlaneRectCopyByte
    add bx, word ptr cs:[PgScreenStrideBytes]
    sub bx, word ptr [bp+8]
    dec word ptr cs:[PgPlaneRectRowsRemaining]
    cmp word ptr cs:[PgPlaneRectRowsRemaining], 0
    je PgPlaneRectRestorePlaneMask
    jmp short PgPlaneRectDrawRow
PgPlaneRectRestorePlaneMask:
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop si
    pop di
    pop ds
    pop bp
    retf 0ch
PgBlitSinglePlaneRectangle endp

; Drawing state, pixels and mouse cursor.

; Stores the EGA color/plane mask used by subsequent drawing routines.
; Pascal: procedure PgSetDrawColor(DrawColor: Word);
; Stack: BP+06h = DrawColor; FAR return, callee pops 2 argument bytes.
; Registers: prologue saves BP; other registers and flags may change.
; Direct CS state: PgDrawColor.
PgSetDrawColor proc far
    push bp
    mov bp, sp
    mov ax, word ptr [bp+6]
    mov word ptr cs:[PgDrawColor], ax
    pop bp
    retf 2
PgSetDrawColor endp

; Stores the draw-page selector used by video addressing helpers.
; Pascal stack equivalent (no interface declaration): procedure
; PgSelectDrawPage(DrawPageIndex: Word);
; Stack: BP+06h = DrawPageIndex; FAR return, callee pops 2 argument bytes.
; Registers: prologue saves BP; other registers and flags may change.
; Direct CS state: PgDrawPage.
PgSelectDrawPage proc far
    push bp
    mov bp, sp
    mov ax, word ptr [bp+6]
    mov word ptr cs:[PgDrawPage], ax
    pop bp
    retf 2
PgSelectDrawPage endp

; Sets one pixel using EGA set/reset and a one-bit write mask.
; Pascal stack equivalent (no interface declaration): procedure PgPutPixel(PixelX: Integer;
; PixelY: Integer);
; Stack: BP+08h = PixelX; BP+06h = PixelY; FAR return, callee pops 4 argument bytes.
; Registers: prologue saves BP/DS; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage, PgDrawColor.
PgPutPixel proc far
    push bp
    mov bp, sp
    push ds
    mov dx, PgVideoSegment
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgPixelComputeByteAddress
    mov cx, ax
PgPixelAddPageSegment:
    add dx, 2000h
    loop PgPixelAddPageSegment
PgPixelComputeByteAddress:
    mov ds, dx
    mov bx, word ptr [bp+6]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov bx, word ptr [bp+8]
    shr bx, 1
    shr bx, 1
    shr bx, 1
    add bx, ax
    mov cx, word ptr [bp+8]
    and cl, 7
    xor cl, 7
    mov ch, 1
    shl ch, cl
    mov dx, PgGraphicsIndexPort
    mov al, 5
    out dx, al
    mov dx, PgGraphicsDataPort
    mov al, 2
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov al, 8
    out dx, al
    mov dx, PgGraphicsDataPort
    mov al, ch
    out dx, al
    mov al, byte ptr [bx]
    mov ax, word ptr cs:[PgDrawColor]
    mov byte ptr [bx], al
    mov dx, PgGraphicsIndexPort
    mov al, 5
    out dx, al
    mov dx, PgGraphicsDataPort
    mov al, 0
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov al, 8
    out dx, al
    mov dx, PgGraphicsDataPort
    mov al, 0ffh
    out dx, al
    pop ds
    pop bp
    retf 4
PgPutPixel endp

; Sets one pixel only if it lies within the pixel clipping rectangle.
; Pascal stack equivalent (no interface declaration): procedure PgPutPixelClipped(PixelX:
; Integer; PixelY: Integer);
; Stack: BP+08h = PixelX; BP+06h = PixelY; FAR return, callee pops 4 argument bytes.
; Registers: prologue saves BP/DS; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage, PgDrawColor, PgClipTopRow,
; PgClipBottomRow, PgClipLeftPixel, PgClipRightPixel.
PgPutPixelClipped proc far
    push bp
    mov bp, sp
    push ds
    mov dx, PgVideoSegment
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgClipPixelCheckClipBounds
    mov cx, ax
PgClipPixelAddPageSegment:
    add dx, 2000h
    loop PgClipPixelAddPageSegment
PgClipPixelCheckClipBounds:
    mov ds, dx
    mov bx, word ptr [bp+6]
    cmp bx, word ptr cs:[PgClipTopRow]
    jl PgClipPixelReturn
    cmp bx, word ptr cs:[PgClipBottomRow]
    jg PgClipPixelReturn
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov bx, word ptr [bp+8]
    cmp bx, word ptr cs:[PgClipLeftPixel]
    jl PgClipPixelReturn
    cmp bx, word ptr cs:[PgClipRightPixel]
    jg PgClipPixelReturn
    shr bx, 1
    shr bx, 1
    shr bx, 1
    add bx, ax
    mov cx, word ptr [bp+8]
    and cl, 7
    xor cl, 7
    mov ch, 1
    shl ch, cl
    mov dx, PgGraphicsIndexPort
    mov al, 5
    out dx, al
    mov dx, PgGraphicsDataPort
    mov al, 2
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov al, 8
    out dx, al
    mov dx, PgGraphicsDataPort
    mov al, ch
    out dx, al
    mov al, byte ptr [bx]
    mov ax, word ptr cs:[PgDrawColor]
    mov byte ptr [bx], al
    mov dx, PgGraphicsIndexPort
    mov al, 5
    out dx, al
    mov dx, PgGraphicsDataPort
    mov al, 0
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov al, 8
    out dx, al
    mov dx, PgGraphicsDataPort
    mov al, 0ffh
    out dx, al
PgClipPixelReturn:
    pop ds
    pop bp
    retf 4
PgPutPixelClipped endp

; Reads the four EGA planes and combines their bits into a color value.
; Pascal stack equivalent (no interface declaration): function PgGetPixel(PixelX: Integer;
; PixelY: Integer): Word;
; Stack: BP+08h = PixelX; BP+06h = PixelY; FAR return, callee pops 4 argument bytes.
; Registers: prologue saves BP/DS; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage.
PgGetPixel proc far
    push bp
    mov bp, sp
    push ds
    mov bx, word ptr [bp+8]
    mov cx, word ptr [bp+6]
    mov dx, PgVideoSegment
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgReadPixelSelectReadPlane
    mov cx, ax
PgReadPixelAddPageSegment:
    add dx, 2000h
    loop PgReadPixelAddPageSegment
PgReadPixelSelectReadPlane:
    mov ds, dx
    push di
    push ax
    mov ax, cx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov cx, bx
    shr bx, 1
    shr bx, 1
    shr bx, 1
    add bx, ax
    and cl, 7
    xor cl, 7
    mov ch, 1
    shl ch, cl
    mov ah, 3
PgReadPixelReadPlane:
    mov dx, PgGraphicsIndexPort
    mov al, 4
    out dx, al
    mov dx, PgGraphicsDataPort
    mov al, ah
    out dx, al
    mov al, byte ptr [bx]
    shl cl, 1
    and al, ch
    je PgReadPixelNextPlane
    or cl, 1
PgReadPixelNextPlane:
    dec ah
    jge PgReadPixelReadPlane
    and cx, 0fh
    mov ax, cx
    pop ds
    pop bp
    retf 4
PgGetPixel endp

; Selects the displayed BIOS video page with AH=5.
; Pascal stack equivalent (no interface declaration): procedure
; PgShowVideoPageBios(VisibleVideoPage: Word);
; Stack: BP+06h = VisibleVideoPage; FAR return, callee pops 2 argument bytes.
; Registers: prologue saves BP; other registers and flags may change.
; Direct CS state: none.
PgShowVideoPageBios proc far
    push bp
    mov bp, sp
    mov ax, word ptr [bp+6]
    mov ah, 5
    int PgBiosVideoInterrupt
    pop bp
    retf 2
PgShowVideoPageBios endp

; Calls mouse INT PgMouseInterrupt AX=9 with a shape pointer and hotspot operands; the original loads BX twice.
; Submits a graphics cursor shape to mouse INT 33h AX=9.
; Pascal stack equivalent (no interface declaration): procedure
; PgSetMouseCursorShape(MouseShapePointer: Pointer; FirstHotspotWord: Word; SecondHotspotWord:
; Word);
; Stack: BP+0Ah = MouseShapePointer; BP+08h = FirstHotspotWord; BP+06h = SecondHotspotWord;
; FAR return, callee pops 8 argument bytes.
; Registers: prologue saves BP/DS; other registers and flags may change.
; Direct CS state: none.
; Original bug preserved: both hotspot words are loaded into BX; CX is not initialized here.
; The shape offset is also incremented.
PgSetMouseCursorShape proc far
    push bp
    mov bp, sp
    push ds
    mov ax, 9
    mov bx, word ptr [bp+8]
    mov bx, word ptr [bp+6]
    les dx, dword ptr [bp+0ah]
    inc dx
    int PgMouseInterrupt
    pop ds
    pop bp
    retf 8
PgSetMouseCursorShape endp

PgByteRectRowsRemaining         dw 0

; Rectangles and line drawing.

; Fills a byte-aligned rectangle by writing set and clear color planes.
; Pascal: procedure PgFillRectangleByteAligned(LeftByteColumn, WidthBytes, TopPixelRow,
; HeightRows: Word);
; Stack: BP+06h = HeightRows; BP+08h = TopPixelRow; BP+0Ah = WidthBytes; BP+0Ch =
; LeftByteColumn; FAR return, callee pops 8 argument bytes.
; Registers: prologue saves BP/DS; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage, PgDrawColor, PgByteRectRowsRemaining.
; Original nonzero draw-page branch uses entry AX as its loop count; preserved for exactness.
PgFillRectangleByteAligned proc far
    push bp
    mov bp, sp
    push ds
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+0ch]
    mov dx, word ptr cs:[PgDrawPage]
    cmp dl, 0
    je PgByteFillAddRowOffset
    mov cx, ax
PgByteFillAddPageOffset:
    add bx, PgVideoPageBytes
    loop PgByteFillAddPageOffset
PgByteFillAddRowOffset:
    mov ax, word ptr [bp+8]
    push di
    push ax
    mov ax, ax
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov dx, di
    pop di
    mov ax, dx
    add bx, ax
    mov dx, PgSequencerIndexPort
    mov al, PgSeqMapMask
    out dx, al
    inc dx
    mov ax, word ptr [bp+6]
    mov word ptr cs:[PgByteRectRowsRemaining], ax
PgByteFillDrawRow:
    mov cx, word ptr [bp+0ah]
PgByteFillFillByte:
    mov dx, PgSequencerDataPort
    mov ax, word ptr cs:[PgDrawColor]
    mov dx, PgSequencerDataPort
    out dx, al
    mov ax, 0ffh
    xchg byte ptr es:[bx], al
    mov ax, word ptr cs:[PgDrawColor]
    xor ax, 0ffh
    mov dx, PgSequencerDataPort
    out dx, al
    mov ax, 0
    xchg byte ptr es:[bx], al
    inc bx
    loop PgByteFillFillByte
    add bx, word ptr cs:[PgScreenStrideBytes]
    sub bx, word ptr [bp+0ah]
    dec word ptr cs:[PgByteRectRowsRemaining]
    cmp word ptr cs:[PgByteRectRowsRemaining], 0
    je PgByteFillRestorePlaneMask
    jmp short PgByteFillDrawRow
PgByteFillRestorePlaneMask:
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop ds
    pop bp
    retf 8
PgFillRectangleByteAligned endp

; Clips a byte-aligned fill against byte-column and row boundaries.
; Pascal stack equivalent (no interface declaration): procedure
; PgFillRectangleClipped(LeftByteColumn: Word; WidthBytes: Word; TopPixelRow: Integer;
; HeightRows: Word);
; Stack: BP+0Ch = LeftByteColumn; BP+0Ah = WidthBytes; BP+08h = TopPixelRow; BP+06h =
; HeightRows; FAR return, callee pops 8 argument bytes.
; Registers: prologue saves BP/DS; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage, PgDrawColor, PgClipLeftByte,
; PgClipRightByte, PgClipTopRow, PgClipBottomRow, PgByteRectRowsRemaining.
; Original nonzero draw-page branch uses entry AX as its loop count; preserved for exactness.
; Original right-edge trim subtracts PgClipBottomRow instead of PgClipRightByte;
; this clipping bug and the loop arithmetic are preserved for exactness.
PgFillRectangleClipped proc far
    push bp
    mov bp, sp
    push ds
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+0ch]
    cmp bx, word ptr cs:[PgClipRightByte]
    jle PgClipByteFillCheckLeftEdge
PgClipByteFillExitBridge:
    jmp near ptr PgClipByteFillRestoreRegisters
PgClipByteFillCheckLeftEdge:
    cmp bx, word ptr cs:[PgClipLeftByte]
    jge PgClipByteFillCheckRightEdge
    mov dx, word ptr [bp+0ah]
PgClipByteFillTrimLeftColumns:
    inc bx
    dec dx
    cmp bx, word ptr cs:[PgClipLeftByte]
    jl PgClipByteFillTrimLeftColumns
    mov word ptr [bp+0ah], dx
    mov word ptr [bp+0ch], bx
PgClipByteFillCheckRightEdge:
    mov cx, word ptr [bp+0ch]
    add cx, word ptr [bp+0ah]
    cmp cx, word ptr cs:[PgClipRightByte]
    jle PgClipByteFillSelectDrawPage
    sub cx, word ptr cs:[PgClipBottomRow]
    mov dx, word ptr [bp+0ah]
PgClipByteFillTrimRightColumns:
    dec dx
    loop PgClipByteFillTrimRightColumns
    mov word ptr [bp+0ah], dx
PgClipByteFillSelectDrawPage:
    mov dx, word ptr cs:[PgDrawPage]
    cmp dl, 0
    je PgClipByteFillCheckTopEdge
    mov cx, ax
PgClipByteFillAddPageOffset:
    add bx, PgVideoPageBytes
    loop PgClipByteFillAddPageOffset
PgClipByteFillCheckTopEdge:
    mov ax, word ptr [bp+8]
    cmp ax, word ptr cs:[PgClipBottomRow]
    jg PgClipByteFillExitBridge
    cmp ax, word ptr cs:[PgClipTopRow]
    jge PgClipByteFillCheckBottomEdge
    mov dx, word ptr [bp+6]
PgClipByteFillTrimTopRows:
    inc ax
    dec dx
    cmp ax, word ptr cs:[PgClipTopRow]
    jl PgClipByteFillTrimTopRows
    mov word ptr [bp+6], dx
    mov word ptr [bp+8], ax
PgClipByteFillCheckBottomEdge:
    mov cx, word ptr [bp+8]
    add cx, word ptr [bp+6]
    cmp cx, word ptr cs:[PgClipBottomRow]
    jle PgClipByteFillComputeRowAddress
    sub cx, word ptr cs:[PgClipBottomRow]
    mov dx, word ptr [bp+6]
PgClipByteFillTrimBottomRows:
    dec dx
    loop PgClipByteFillTrimBottomRows
    mov word ptr [bp+6], dx
PgClipByteFillComputeRowAddress:
    push di
    push ax
    mov ax, ax
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov dx, di
    pop di
    mov ax, dx
    add bx, ax
    mov dx, PgSequencerIndexPort
    mov al, PgSeqMapMask
    out dx, al
    inc dx
    mov ax, word ptr [bp+6]
    mov word ptr cs:[PgByteRectRowsRemaining], ax
PgClipByteFillDrawRow:
    mov cx, word ptr [bp+0ah]
PgClipByteFillFillByte:
    mov dx, PgSequencerDataPort
    mov ax, word ptr cs:[PgDrawColor]
    mov dx, PgSequencerDataPort
    out dx, al
    mov ax, 0ffh
    xchg byte ptr es:[bx], al
    mov ax, word ptr cs:[PgDrawColor]
    xor ax, 0ffh
    mov dx, PgSequencerDataPort
    out dx, al
    mov ax, 0
    xchg byte ptr es:[bx], al
    inc bx
    loop PgClipByteFillFillByte
    add bx, word ptr cs:[PgScreenStrideBytes]
    sub bx, word ptr [bp+0ah]
    dec word ptr cs:[PgByteRectRowsRemaining]
    cmp word ptr cs:[PgByteRectRowsRemaining], 0
    je PgClipByteFillRestoreRegisters
    jmp short PgClipByteFillDrawRow
PgClipByteFillRestoreRegisters:
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop ds
    pop bp
    retf 8
PgFillRectangleClipped endp

; Converts a pixel coordinate to a planar byte address and bit shift.
; Pascal: internal register helper; no stack declaration retained.
; Registers/stack: AX = pixel Y, BX = pixel X; ES:BX = byte address, CL = 7-(X and 7), AH = 1.
; DX/DI saved; FAR register return.
; Direct CS state: PgScreenStrideBytes, PgDrawPage.
PgPixelAddressAndBitHelper proc far
    mov cl, bl
    push dx
    push di
    push ax
    mov ax, ax
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov dx, di
    pop di
    mov ax, dx
    pop dx
    shr bx, 1
    shr bx, 1
    shr bx, 1
    add bx, ax
    push cx
    mov cx, word ptr cs:[PgDrawPage]
    mov ax, PgVideoSegment
    cmp cx, 0
    je PgPixelAddrReturnBitShift
PgPixelAddrAddPageSegment:
    add ax, 2000h
    loop PgPixelAddrAddPageSegment
PgPixelAddrReturnBitShift:
    mov es, ax
    pop cx
    and cl, 7
    xor cl, 7
    mov ah, 1
    retf
PgPixelAddressAndBitHelper endp

PgLineRowAddressStep            dw ?
PgLineDoubleMinorDelta          dw ?
PgLineErrorAdjustment           dw ?
PgLineMajorAxis                 dw ?
; Draws a pixel line with integer Bresenham error updates.
; Pascal stack equivalent (no interface declaration): procedure
; PgDrawLineBresenham(StartPixelX: Integer; StartPixelY: Integer; EndPixelX: Integer;
; EndPixelY: Integer);
; Stack: BP+0Ch = StartPixelX; BP+0Ah = StartPixelY; BP+08h = EndPixelX; BP+06h = EndPixelY;
; FAR return, callee pops 8 argument bytes.
; Registers: prologue saves BP/SI/DI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawColor, PgLineRowAddressStep,
; PgLineDoubleMinorDelta, PgLineErrorAdjustment, PgLineMajorAxis.
PgDrawLineBresenham proc far
    push bp
    mov bp, sp
    push si
    push di
    mov dx, PgGraphicsIndexPort
    mov ah, byte ptr cs:[PgDrawColor]
    xor al, al
    out dx, ax
    mov ax, PgEnableSetResetAll
    out dx, ax
    mov ah, 0
    mov al, 3
    out dx, ax
    mov si, word ptr cs:[PgScreenStrideBytes]
    mov cx, word ptr [bp+8]
    sub cx, word ptr [bp+0ch]
    je PgLineVerticalSpecialCase
    jns PgLineComputeYDelta
    neg cx
    mov bx, word ptr [bp+8]
    xchg word ptr [bp+0ch], bx
    mov word ptr [bp+8], bx
    mov bx, word ptr [bp+6]
    xchg word ptr [bp+0ah], bx
    mov word ptr [bp+6], bx
PgLineComputeYDelta:
    mov bx, word ptr [bp+6]
    sub bx, word ptr [bp+0ah]
    je PgLineHorizontalSpecialCase
    jns PgLineStoreRowStep
    neg bx
    neg si
PgLineStoreRowStep:
    mov word ptr cs:[PgLineRowAddressStep], si
    mov word ptr cs:[PgLineMajorAxis], 0
    cmp bx, cx
    jle PgLineInitDecision
    mov word ptr cs:[PgLineMajorAxis], 1
    xchg bx, cx
PgLineInitDecision:
    shl bx, 1
    mov word ptr cs:[PgLineDoubleMinorDelta], bx
    sub bx, cx
    mov si, bx
    sub bx, cx
    mov word ptr cs:[PgLineErrorAdjustment], bx
    push cx
    mov ax, word ptr [bp+0ah]
    mov bx, word ptr [bp+0ch]
    push cs
    call near ptr PgPixelAddressAndBitHelper
    mov di, bx
    shl ah, cl
    mov bl, ah
    mov al, 8
    pop cx
    inc cx
    cmp word ptr cs:[PgLineMajorAxis], 0
    jg PgLineYMajorBridge
    jmp near ptr PgLineStartXMajorByte
PgLineYMajorBridge:
    jmp near ptr PgLineSetupYMajor
PgLineVerticalSpecialCase:
    mov ax, word ptr [bp+0ah]
    mov bx, word ptr [bp+6]
    mov cx, bx
    sub cx, ax
    jge PgLineSetupVertical
    neg cx
    mov ax, bx
PgLineSetupVertical:
    inc cx
    mov bx, word ptr [bp+0ch]
    push cx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    shl ah, cl
    mov al, 8
    out dx, ax
    pop cx
PgLineDrawVertical:
    or byte ptr es:[bx], al
    add bx, si
    loop PgLineDrawVertical
    jmp near ptr PgLineRestoreRegisters
PgLineHorizontalSpecialCase:
    push ds
    mov ax, word ptr [bp+0ah]
    mov bx, word ptr [bp+0ch]
    push cs
    call near ptr PgPixelAddressAndBitHelper
    mov di, bx
    mov dh, ah
    not dh
    shl dh, cl
    not dh
    mov cx, word ptr [bp+8]
    and cl, 7
    xor cl, 7
    mov dl, 0ffh
    shl dl, cl
    mov ax, word ptr [bp+8]
    mov bx, word ptr [bp+0ch]
    mov cl, 3
    shr ax, cl
    shr bx, cl
    mov cx, ax
    sub cx, bx
    mov bx, dx
    mov dx, PgGraphicsIndexPort
    mov al, 8
    push es
    pop ds
    mov si, di
    or bh, bh
    js PgLineDrawWholeBytes
    or cx, cx
    jne PgLineDrawLeadingByte
    and bl, bh
    jmp short PgLineDrawTrailingByte
PgLineDrawLeadingByte:
    mov ah, bh
    out dx, ax
    movsb
    dec cx
PgLineDrawWholeBytes:
    mov ah, 0ffh
    out dx, ax
    rep movsb
PgLineDrawTrailingByte:
    mov ah, bl
    out dx, ax
    movsb
    pop ds
    jmp short PgLineRestoreRegisters
PgLineStartXMajorByte:
    mov ah, bl
PgLineAccumulateXMajor:
    or ah, bl
    ror bl, 1
    jb PgLineAdvanceXMajorByte
    or si, si
    jns PgLineStepXMajorRow
    add si, word ptr cs:[PgLineDoubleMinorDelta]
    loop PgLineAccumulateXMajor
    out dx, ax
    or byte ptr es:[di], al
    jmp short PgLineRestoreRegisters
PgLineStepXMajorRow:
    add si, word ptr cs:[PgLineErrorAdjustment]
    out dx, ax
    or byte ptr es:[di], al
    add di, word ptr cs:[PgLineRowAddressStep]
    loop PgLineStartXMajorByte
    jmp short PgLineRestoreRegisters
PgLineAdvanceXMajorByte:
    out dx, ax
    or byte ptr es:[di], al
    inc di
    or si, si
    jns PgLineStepRowAtByteBoundary
    add si, word ptr cs:[PgLineDoubleMinorDelta]
    loop PgLineStartXMajorByte
    jmp short PgLineRestoreRegisters
PgLineStepRowAtByteBoundary:
    add si, word ptr cs:[PgLineErrorAdjustment]
    add di, word ptr cs:[PgLineRowAddressStep]
    loop PgLineStartXMajorByte
    jmp short PgLineRestoreRegisters
PgLineSetupYMajor:
    mov bx, word ptr cs:[PgLineRowAddressStep]
PgLineDrawYMajor:
    out dx, ax
    or byte ptr es:[di], al
    add di, bx
    or si, si
    jns PgLineStepYMajorColumn
    add si, word ptr cs:[PgLineDoubleMinorDelta]
    loop PgLineDrawYMajor
    jmp short PgLineRestoreRegisters
PgLineStepYMajorColumn:
    add si, word ptr cs:[PgLineErrorAdjustment]
    ror ah, 1
    adc di, 0
    loop PgLineDrawYMajor
PgLineRestoreRegisters:
    xor ax, ax
    out dx, ax
    inc ax
    out dx, ax
    mov al, 3
    out dx, ax
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop di
    pop si
    pop bp
    retf 8
PgDrawLineBresenham endp

; Draws a pixel line through the library's second Bresenham path.
; Pascal stack equivalent (no interface declaration): procedure
; PgDrawLineBresenhamVariant(StartPixelX: Integer; StartPixelY: Integer; EndPixelX: Integer;
; EndPixelY: Integer);
; Stack: BP+0Ch = StartPixelX; BP+0Ah = StartPixelY; BP+08h = EndPixelX; BP+06h = EndPixelY;
; FAR return, callee pops 8 argument bytes.
; Registers: prologue saves BP/SI/DI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawColor, PgLineRowAddressStep,
; PgLineDoubleMinorDelta, PgLineErrorAdjustment, PgLineMajorAxis.
PgDrawLineBresenhamVariant proc far
    push bp
    mov bp, sp
    push si
    push di
    mov dx, PgGraphicsIndexPort
    mov ax, 5
    out dx, ax
    mov ah, byte ptr cs:[PgDrawColor]
    xor al, al
    out dx, ax
    mov ax, PgEnableSetResetAll
    out dx, ax
    mov ah, 18h
    mov al, 3
    out dx, ax
    mov si, word ptr cs:[PgScreenStrideBytes]
    mov cx, word ptr [bp+8]
    sub cx, word ptr [bp+0ch]
    je PgLineAltVerticalSpecialCase
    jns PgLineAltComputeYDelta
    neg cx
    mov bx, word ptr [bp+8]
    xchg word ptr [bp+0ch], bx
    mov word ptr [bp+8], bx
    mov bx, word ptr [bp+6]
    xchg word ptr [bp+0ah], bx
    mov word ptr [bp+6], bx
PgLineAltComputeYDelta:
    mov bx, word ptr [bp+6]
    sub bx, word ptr [bp+0ah]
    je PgLineAltHorizontalSpecialCase
    jns PgLineAltStoreRowStep
    neg bx
    neg si
PgLineAltStoreRowStep:
    mov word ptr cs:[PgLineRowAddressStep], si
    mov word ptr cs:[PgLineMajorAxis], 0
    cmp bx, cx
    jle PgLineAltInitDecision
    mov word ptr cs:[PgLineMajorAxis], 1
    xchg bx, cx
PgLineAltInitDecision:
    shl bx, 1
    mov word ptr cs:[PgLineDoubleMinorDelta], bx
    sub bx, cx
    mov si, bx
    sub bx, cx
    mov word ptr cs:[PgLineErrorAdjustment], bx
    push cx
    mov ax, word ptr [bp+0ah]
    mov bx, word ptr [bp+0ch]
    push cs
    call near ptr PgPixelAddressAndBitHelper
    mov di, bx
    shl ah, cl
    mov bl, ah
    mov al, 8
    pop cx
    inc cx
    cmp word ptr cs:[PgLineMajorAxis], 0
    jg PgLineAltYMajorBridge
    jmp near ptr PgLineAltStartXMajorByte
PgLineAltYMajorBridge:
    jmp near ptr PgLineAltSetupYMajor
PgLineAltVerticalSpecialCase:
    mov ax, word ptr [bp+0ah]
    mov bx, word ptr [bp+6]
    mov cx, bx
    sub cx, ax
    jge PgLineAltSetupVertical
    neg cx
    mov ax, bx
PgLineAltSetupVertical:
    inc cx
    mov bx, word ptr [bp+0ch]
    push cx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    shl ah, cl
    mov al, 8
    out dx, ax
    pop cx
PgLineAltDrawVertical:
    xor byte ptr es:[bx], al
    add bx, si
    loop PgLineAltDrawVertical
    jmp near ptr PgLineAltRestoreRegisters
PgLineAltHorizontalSpecialCase:
    push ds
    mov ax, word ptr [bp+0ah]
    mov bx, word ptr [bp+0ch]
    push cs
    call near ptr PgPixelAddressAndBitHelper
    mov di, bx
    mov dh, ah
    not dh
    shl dh, cl
    not dh
    mov cx, word ptr [bp+8]
    and cl, 7
    xor cl, 7
    mov dl, 0ffh
    shl dl, cl
    mov ax, word ptr [bp+8]
    mov bx, word ptr [bp+0ch]
    mov cl, 3
    shr ax, cl
    shr bx, cl
    mov cx, ax
    sub cx, bx
    mov bx, dx
    mov dx, PgGraphicsIndexPort
    mov al, 8
    push es
    pop ds
    mov si, di
    or bh, bh
    js PgLineAltDrawWholeBytes
    or cx, cx
    jne PgLineAltDrawLeadingByte
    and bl, bh
    jmp short PgLineAltDrawTrailingByte
PgLineAltDrawLeadingByte:
    mov ah, bh
    out dx, ax
    movsb
    dec cx
PgLineAltDrawWholeBytes:
    mov ah, 0ffh
    out dx, ax
    rep movsb
PgLineAltDrawTrailingByte:
    mov ah, bl
    out dx, ax
    movsb
    pop ds
    jmp short PgLineAltRestoreRegisters
PgLineAltStartXMajorByte:
    mov ah, bl
PgLineAltAccumulateXMajor:
    or ah, bl
    ror bl, 1
    jb PgLineAltAdvanceXMajorByte
    or si, si
    jns PgLineAltStepXMajorRow
    add si, word ptr cs:[PgLineDoubleMinorDelta]
    loop PgLineAltAccumulateXMajor
    out dx, ax
    xor byte ptr es:[di], al
    jmp short PgLineAltRestoreRegisters
PgLineAltStepXMajorRow:
    add si, word ptr cs:[PgLineErrorAdjustment]
    out dx, ax
    xor byte ptr es:[di], al
    add di, word ptr cs:[PgLineRowAddressStep]
    loop PgLineAltStartXMajorByte
    jmp short PgLineAltRestoreRegisters
PgLineAltAdvanceXMajorByte:
    out dx, ax
    xor byte ptr es:[di], al
    inc di
    or si, si
    jns PgLineAltStepRowAtByteBoundary
    add si, word ptr cs:[PgLineDoubleMinorDelta]
    loop PgLineAltStartXMajorByte
    jmp short PgLineAltRestoreRegisters
PgLineAltStepRowAtByteBoundary:
    add si, word ptr cs:[PgLineErrorAdjustment]
    add di, word ptr cs:[PgLineRowAddressStep]
    loop PgLineAltStartXMajorByte
    jmp short PgLineAltRestoreRegisters
PgLineAltSetupYMajor:
    mov bx, word ptr cs:[PgLineRowAddressStep]
PgLineAltDrawYMajor:
    out dx, ax
    xor byte ptr es:[di], al
    add di, bx
    or si, si
    jns PgLineAltStepYMajorColumn
    add si, word ptr cs:[PgLineDoubleMinorDelta]
    loop PgLineAltDrawYMajor
    jmp short PgLineAltRestoreRegisters
PgLineAltStepYMajorColumn:
    add si, word ptr cs:[PgLineErrorAdjustment]
    ror ah, 1
    adc di, 0
    loop PgLineAltDrawYMajor
PgLineAltRestoreRegisters:
    xor ax, ax
    out dx, ax
    inc ax
    out dx, ax
    mov al, 3
    out dx, ax
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop di
    pop si
    pop bp
    retf 8
PgDrawLineBresenhamVariant endp

; Draws four rectangle edges using EGA bit masks and the draw operation.
; Pascal stack equivalent (no interface declaration): procedure
; PgDrawRectangleOutline(StartPixelX: Integer; StartPixelY: Integer; EndPixelX: Integer;
; EndPixelY: Integer);
; Stack: BP+0Ch = StartPixelX; BP+0Ah = StartPixelY; BP+08h = EndPixelX; BP+06h = EndPixelY;
; FAR return, callee pops 8 argument bytes.
; Registers: prologue saves BP/SI/DI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawColor, PgDrawOperation.
PgDrawRectangleOutline proc far
    push bp
    mov bp, sp
    push si
    push di
    mov dx, PgGraphicsIndexPort
    mov ax, word ptr cs:[PgDrawColor]
    xchg ah, al
    xor al, al
    out dx, ax
    mov ax, PgEnableSetResetAll
    out dx, ax
    mov ah, 0
    mov al, 3
    out dx, ax
    mov dx, PgGraphicsIndexPort
    mov al, 3
    mov ah, byte ptr cs:[PgDrawOperation]
    shl ah, 1
    shl ah, 1
    shl ah, 1
    out dx, ax
    mov si, word ptr cs:[PgScreenStrideBytes]
    mov ax, word ptr [bp+0ah]
    mov bx, word ptr [bp+6]
    mov cx, bx
    sub cx, ax
    jge PgOutlineSetupLeftEdge
    neg cx
    mov ax, bx
PgOutlineSetupLeftEdge:
    inc cx
    mov bx, word ptr [bp+0ch]
    push cx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    shl ah, cl
    mov al, 8
    out dx, ax
    pop cx
PgOutlineDrawLeftEdge:
    or byte ptr es:[bx], al
    add bx, si
    loop PgOutlineDrawLeftEdge
    mov ax, word ptr [bp+0ah]
    mov bx, word ptr [bp+6]
    mov cx, bx
    sub cx, ax
    jge PgOutlineSetupRightEdge
    neg cx
    mov ax, bx
PgOutlineSetupRightEdge:
    inc cx
    mov bx, word ptr [bp+8]
    push cx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    shl ah, cl
    mov al, 8
    out dx, ax
    pop cx
PgOutlineDrawRightEdge:
    or byte ptr es:[bx], al
    add bx, si
    loop PgOutlineDrawRightEdge
    push ds
    mov ax, word ptr [bp+0ah]
    mov bx, word ptr [bp+0ch]
    push cs
    call near ptr PgPixelAddressAndBitHelper
    mov di, bx
    mov dh, ah
    not dh
    shl dh, cl
    not dh
    mov cx, word ptr [bp+8]
    and cl, 7
    xor cl, 7
    mov dl, 0ffh
    shl dl, cl
    mov ax, word ptr [bp+8]
    mov bx, word ptr [bp+0ch]
    mov cl, 3
    shr ax, cl
    shr bx, cl
    mov cx, ax
    sub cx, bx
    mov bx, dx
    mov dx, PgGraphicsIndexPort
    mov al, 8
    push es
    pop ds
    mov si, di
    or bh, bh
    js PgOutlineTopWholeBytes
    or cx, cx
    jne PgOutlineTopLeadingByte
    and bl, bh
    jmp short PgOutlineTopTrailingByte
PgOutlineTopLeadingByte:
    mov ah, bh
    out dx, ax
    movsb
    dec cx
PgOutlineTopWholeBytes:
    mov ah, 0ffh
    out dx, ax
    rep movsb
PgOutlineTopTrailingByte:
    mov ah, bl
    out dx, ax
    movsb
    pop ds
    push ds
    mov ax, word ptr [bp+6]
    mov bx, word ptr [bp+0ch]
    push cs
    call near ptr PgPixelAddressAndBitHelper
    mov di, bx
    mov dh, ah
    not dh
    shl dh, cl
    not dh
    mov cx, word ptr [bp+8]
    and cl, 7
    xor cl, 7
    mov dl, 0ffh
    shl dl, cl
    mov ax, word ptr [bp+8]
    mov bx, word ptr [bp+0ch]
    mov cl, 3
    shr ax, cl
    shr bx, cl
    mov cx, ax
    sub cx, bx
    mov bx, dx
    mov dx, PgGraphicsIndexPort
    mov al, 8
    push es
    pop ds
    mov si, di
    or bh, bh
    js PgOutlineBottomWholeBytes
    or cx, cx
    jne PgOutlineBottomLeadingByte
    and bl, bh
    jmp short PgOutlineBottomTrailingByte
PgOutlineBottomLeadingByte:
    mov ah, bh
    out dx, ax
    movsb
    dec cx
PgOutlineBottomWholeBytes:
    mov ah, 0ffh
    out dx, ax
    rep movsb
PgOutlineBottomTrailingByte:
    mov ah, bl
    out dx, ax
    movsb
    pop ds
    xor ax, ax
    out dx, ax
    inc ax
    out dx, ax
    mov al, 3
    out dx, ax
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop di
    pop si
    pop bp
    retf 8
PgDrawRectangleOutline endp

; Draws rectangle edges within the pixel clipping rectangle.
; Pascal stack equivalent (no interface declaration): procedure
; PgDrawRectangleOutlineClipped(StartPixelX: Integer; StartPixelY: Integer; EndPixelX:
; Integer; EndPixelY: Integer);
; Stack: BP+0Ch = StartPixelX; BP+0Ah = StartPixelY; BP+08h = EndPixelX; BP+06h = EndPixelY;
; FAR return, callee pops 8 argument bytes.
; Registers: prologue saves BP/SI/DI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawColor, PgClipTopRow, PgClipBottomRow,
; PgClipLeftPixel, PgClipRightPixel.
; Original skipped horizontal-edge paths can bypass POP DS after PUSH DS;
; preserve the resulting stack bug in this unexported entry.
PgDrawRectangleOutlineClipped proc far
    push bp
    mov bp, sp
    push si
    push di
    mov dx, PgGraphicsIndexPort
    mov ax, word ptr cs:[PgDrawColor]
    xchg ah, al
    xor al, al
    out dx, ax
    mov ax, PgEnableSetResetAll
    out dx, ax
    mov ah, 0
    mov al, 3
    out dx, ax
    mov dx, PgGraphicsIndexPort
    mov al, 3
    mov ah, 0
    out dx, ax
    mov si, word ptr cs:[PgScreenStrideBytes]
    mov ax, word ptr [bp+0ch]
    mov bx, word ptr [bp+8]
    cmp ax, bx
    jle PgClipOutlineSortY
    xchg bx, ax
    mov word ptr [bp+0ch], ax
    mov word ptr [bp+8], bx
PgClipOutlineSortY:
    mov ax, word ptr [bp+0ah]
    mov bx, word ptr [bp+6]
    cmp ax, bx
    jle PgClipOutlineClampTop
    xchg bx, ax
    mov word ptr [bp+0ah], ax
    mov word ptr [bp+6], bx
PgClipOutlineClampTop:
    cmp ax, word ptr cs:[PgClipTopRow]
    jge PgClipOutlineClampBottom
    mov ax, word ptr cs:[PgClipTopRow]
PgClipOutlineClampBottom:
    mov bx, word ptr [bp+6]
    cmp bx, word ptr cs:[PgClipBottomRow]
    jle PgClipOutlineSetupLeftHeight
    mov bx, word ptr cs:[PgClipBottomRow]
PgClipOutlineSetupLeftHeight:
    mov cx, bx
    sub cx, ax
    jge PgClipOutlineSetupLeftEdge
    neg cx
    mov ax, bx
PgClipOutlineSetupLeftEdge:
    inc cx
    mov bx, word ptr [bp+0ch]
    cmp bx, word ptr cs:[PgClipLeftPixel]
    jl PgClipOutlineSetupRightTop
    cmp bx, word ptr cs:[PgClipRightPixel]
    jg PgClipOutlineExitBridge
    push cx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    shl ah, cl
    mov al, 8
    out dx, ax
    pop cx
PgClipOutlineDrawLeftEdge:
    or byte ptr es:[bx], al
    add bx, si
    loop PgClipOutlineDrawLeftEdge
PgClipOutlineSetupRightTop:
    mov ax, word ptr [bp+0ah]
    cmp ax, word ptr cs:[PgClipTopRow]
    jg PgClipOutlineSetupRightBottom
    mov ax, word ptr cs:[PgClipTopRow]
PgClipOutlineSetupRightBottom:
    mov bx, word ptr [bp+6]
    cmp bx, word ptr cs:[PgClipBottomRow]
    jl PgClipOutlineSetupRightHeight
    mov bx, word ptr cs:[PgClipBottomRow]
PgClipOutlineSetupRightHeight:
    mov cx, bx
    sub cx, ax
    jge PgClipOutlineSetupRightEdge
    neg cx
    mov ax, bx
PgClipOutlineSetupRightEdge:
    inc cx
    mov bx, word ptr [bp+8]
    cmp bx, word ptr cs:[PgClipLeftPixel]
    jl PgClipOutlineExitBridge
    cmp bx, word ptr cs:[PgClipRightPixel]
    jg PgClipOutlineSetupTopEdge
    push cx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    shl ah, cl
    mov al, 8
    out dx, ax
    pop cx
PgClipOutlineDrawRightEdge:
    or byte ptr es:[bx], al
    add bx, si
    loop PgClipOutlineDrawRightEdge
    jmp short PgClipOutlineSetupTopEdge
    nop
PgClipOutlineExitBridge:
    jmp near ptr PgClipOutlineRestoreRegisters
PgClipOutlineBottomEdgeBridge:
    jmp near ptr PgClipOutlineSetupBottomEdge
PgClipOutlineSetupTopEdge:
    push ds
    mov ax, word ptr [bp+0ah]
    cmp ax, word ptr cs:[PgClipTopRow]
    jl PgClipOutlineBottomEdgeBridge
    cmp ax, word ptr cs:[PgClipBottomRow]
    jg PgClipOutlineExitBridge
    mov bx, word ptr [bp+0ch]
    cmp bx, word ptr cs:[PgClipLeftPixel]
    jge PgClipOutlineTopStartAddress
    mov bx, word ptr cs:[PgClipLeftPixel]
PgClipOutlineTopStartAddress:
    push cs
    call near ptr PgPixelAddressAndBitHelper
    mov di, bx
    mov dh, ah
    not dh
    shl dh, cl
    not dh
    mov cx, word ptr [bp+8]
    cmp cx, word ptr cs:[PgClipRightPixel]
    jle PgClipOutlineTopEndMask
    mov cx, word ptr cs:[PgClipRightPixel]
PgClipOutlineTopEndMask:
    and cl, 7
    xor cl, 7
    mov dl, 0ffh
    shl dl, cl
    mov ax, word ptr [bp+8]
    cmp ax, word ptr cs:[PgClipRightPixel]
    jle PgClipOutlineTopRightByte
    mov ax, word ptr cs:[PgClipRightPixel]
PgClipOutlineTopRightByte:
    mov bx, word ptr [bp+0ch]
    cmp bx, word ptr cs:[PgClipLeftPixel]
    jge PgClipOutlineTopByteCount
    mov bx, word ptr cs:[PgClipLeftPixel]
PgClipOutlineTopByteCount:
    mov cl, 3
    shr ax, cl
    shr bx, cl
    mov cx, ax
    sub cx, bx
    mov bx, dx
    mov dx, PgGraphicsIndexPort
    mov al, 8
    push es
    pop ds
    mov si, di
    or bh, bh
    js PgClipOutlineTopWholeBytes
    or cx, cx
    jne PgClipOutlineTopLeadingByte
    and bl, bh
    jmp short PgClipOutlineTopTrailingByte
PgClipOutlineTopLeadingByte:
    mov ah, bh
    out dx, ax
    movsb
    dec cx
PgClipOutlineTopWholeBytes:
    mov ah, 0ffh
    out dx, ax
    rep movsb
PgClipOutlineTopTrailingByte:
    mov ah, bl
    out dx, ax
    movsb
    pop ds
    jmp short PgClipOutlineSetupBottomEdge
    nop
PgClipOutlineExitBottomBridge:
    jmp near ptr PgClipOutlineRestoreRegisters
PgClipOutlineSetupBottomEdge:
    push ds
    mov ax, word ptr [bp+6]
    cmp ax, word ptr cs:[PgClipTopRow]
    jl PgClipOutlineExitBottomBridge
    cmp ax, word ptr cs:[PgClipBottomRow]
    jg PgClipOutlineExitBottomBridge
    mov bx, word ptr [bp+0ch]
    cmp bx, word ptr cs:[PgClipLeftPixel]
    jge PgClipOutlineBottomStartAddress
    mov bx, word ptr cs:[PgClipLeftPixel]
PgClipOutlineBottomStartAddress:
    push cs
    call near ptr PgPixelAddressAndBitHelper
    mov di, bx
    mov dh, ah
    not dh
    shl dh, cl
    not dh
    mov cx, word ptr [bp+8]
    cmp cx, word ptr cs:[PgClipRightPixel]
    jle PgClipOutlineBottomEndMask
    mov cx, word ptr cs:[PgClipRightPixel]
PgClipOutlineBottomEndMask:
    and cl, 7
    xor cl, 7
    mov dl, 0ffh
    shl dl, cl
    mov ax, word ptr [bp+8]
    cmp ax, word ptr cs:[PgClipRightPixel]
    jle PgClipOutlineBottomRightByte
    mov ax, word ptr cs:[PgClipRightPixel]
PgClipOutlineBottomRightByte:
    mov bx, word ptr [bp+0ch]
    cmp bx, word ptr cs:[PgClipLeftPixel]
    jge PgClipOutlineBottomByteCount
    mov bx, word ptr cs:[PgClipLeftPixel]
PgClipOutlineBottomByteCount:
    mov cl, 3
    shr ax, cl
    shr bx, cl
    mov cx, ax
    sub cx, bx
    mov bx, dx
    mov dx, PgGraphicsIndexPort
    mov al, 8
    push es
    pop ds
    mov si, di
    or bh, bh
    js PgClipOutlineBottomWholeBytes
    or cx, cx
    jne PgClipOutlineBottomLeadingByte
    and bl, bh
    jmp short PgClipOutlineBottomTrailingByte
PgClipOutlineBottomLeadingByte:
    mov ah, bh
    out dx, ax
    movsb
    dec cx
PgClipOutlineBottomWholeBytes:
    mov ah, 0ffh
    out dx, ax
    rep movsb
PgClipOutlineBottomTrailingByte:
    mov ah, bl
    out dx, ax
    movsb
    pop ds
PgClipOutlineRestoreRegisters:
    xor ax, ax
    out dx, ax
    inc ax
    out dx, ax
    mov al, 3
    out dx, ax
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop di
    pop si
    pop bp
    retf 8
PgDrawRectangleOutlineClipped endp

; Fills an inclusive pixel rectangle, masking partial endpoint bytes.
; Pascal stack equivalent (no interface declaration): procedure PgFillRectangle(StartPixelX:
; Integer; StartPixelY: Integer; EndPixelX: Integer; EndPixelY: Integer);
; Stack: BP+0Ch = StartPixelX; BP+0Ah = StartPixelY; BP+08h = EndPixelX; BP+06h = EndPixelY;
; FAR return, callee pops 8 argument bytes.
; Registers: prologue saves BP/SI/DI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawColor.
PgFillRectangle proc far
    push bp
    mov bp, sp
    push si
    push di
    mov dx, PgGraphicsIndexPort
    mov ah, byte ptr cs:[PgDrawColor]
    xor al, al
    out dx, ax
    mov ax, PgEnableSetResetAll
    out dx, ax
    mov ah, 0
    mov al, 3
    out dx, ax
PgFillDrawRow:
    mov si, word ptr cs:[PgScreenStrideBytes]
    push ds
    mov ax, word ptr [bp+0ah]
    mov bx, word ptr [bp+0ch]
    push cs
    call near ptr PgPixelAddressAndBitHelper
    mov di, bx
    mov dh, ah
    not dh
    shl dh, cl
    not dh
    mov cx, word ptr [bp+8]
    and cl, 7
    xor cl, 7
    mov dl, 0ffh
    shl dl, cl
    mov ax, word ptr [bp+8]
    mov bx, word ptr [bp+0ch]
    mov cl, 3
    shr ax, cl
    shr bx, cl
    mov cx, ax
    sub cx, bx
    mov bx, dx
    mov dx, PgGraphicsIndexPort
    mov al, 8
    push es
    pop ds
    mov si, di
    or bh, bh
    js PgFillDrawWholeBytes
    or cx, cx
    jne PgFillDrawLeadingByte
    and bl, bh
    jmp short PgFillDrawTrailingByte
PgFillDrawLeadingByte:
    mov ah, bh
    out dx, ax
    movsb
    dec cx
PgFillDrawWholeBytes:
    mov ah, 0ffh
    out dx, ax
    rep movsb
PgFillDrawTrailingByte:
    mov ah, bl
    out dx, ax
    movsb
    pop ds
    mov cx, word ptr [bp+0ah]
    inc cx
    mov word ptr [bp+0ah], cx
    mov bx, word ptr [bp+6]
    cmp cx, bx
    jle PgFillDrawRow
    xor ax, ax
    out dx, ax
    inc ax
    out dx, ax
    mov al, 3
    out dx, ax
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop di
    pop si
    pop bp
    retf 8
PgFillRectangle endp

; Clips and fills an inclusive pixel rectangle.
; Pascal stack equivalent (no interface declaration): procedure
; PgFillRectangleClippedPixels(StartPixelX: Integer; StartPixelY: Integer; EndPixelX: Integer;
; EndPixelY: Integer);
; Stack: BP+0Ch = StartPixelX; BP+0Ah = StartPixelY; BP+08h = EndPixelX; BP+06h = EndPixelY;
; FAR return, callee pops 8 argument bytes.
; Registers: prologue saves BP/SI/DI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawColor, PgClipTopRow, PgClipBottomRow,
; PgClipLeftPixel, PgClipRightPixel.
PgFillRectangleClippedPixels proc far
    push bp
    mov bp, sp
    push si
    push di
    jmp short PgClipFillCheckLeft
PgClipFillExitBridge:
    jmp near ptr PgClipFillRestoreRegisters
PgClipFillCheckLeft:
    mov ax, word ptr [bp+0ch]
    cmp ax, word ptr cs:[PgClipRightPixel]
    jg PgClipFillExitBridge
    cmp ax, word ptr cs:[PgClipLeftPixel]
    jge PgClipFillClampRight
    mov ax, word ptr cs:[PgClipLeftPixel]
    mov word ptr [bp+0ch], ax
PgClipFillClampRight:
    mov ax, word ptr [bp+8]
    cmp ax, word ptr cs:[PgClipLeftPixel]
    jl PgClipFillExitBridge
    cmp ax, word ptr cs:[PgClipRightPixel]
    jle PgClipFillCheckTop
    mov ax, word ptr cs:[PgClipRightPixel]
    mov word ptr [bp+8], ax
PgClipFillCheckTop:
    mov ax, word ptr [bp+0ah]
    cmp ax, word ptr cs:[PgClipBottomRow]
    jg PgClipFillExitBridge
    cmp ax, word ptr cs:[PgClipTopRow]
    jge PgClipFillClampBottom
    mov ax, word ptr cs:[PgClipTopRow]
    mov word ptr [bp+0ah], ax
PgClipFillClampBottom:
    mov ax, word ptr [bp+6]
    cmp ax, word ptr cs:[PgClipTopRow]
    jl PgClipFillExitBridge
    cmp ax, word ptr cs:[PgClipBottomRow]
    jle PgClipFillInitGraphics
    mov ax, word ptr cs:[PgClipBottomRow]
    mov word ptr [bp+6], ax
PgClipFillInitGraphics:
    mov dx, PgGraphicsIndexPort
    mov ax, word ptr cs:[PgDrawColor]
    xchg ah, al
    xor al, al
    out dx, ax
    mov ax, PgEnableSetResetAll
    out dx, ax
    mov ah, 0
    mov al, 3
    out dx, ax
PgClipFillDrawRow:
    mov si, word ptr cs:[PgScreenStrideBytes]
    push ds
    mov ax, word ptr [bp+0ah]
    mov bx, word ptr [bp+0ch]
    push cs
    call near ptr PgPixelAddressAndBitHelper
    mov di, bx
    mov dh, ah
    not dh
    shl dh, cl
    not dh
    mov cx, word ptr [bp+8]
    and cl, 7
    xor cl, 7
    mov dl, 0ffh
    shl dl, cl
    mov ax, word ptr [bp+8]
    mov bx, word ptr [bp+0ch]
    mov cl, 3
    shr ax, cl
    shr bx, cl
    mov cx, ax
    sub cx, bx
    mov bx, dx
    mov dx, PgGraphicsIndexPort
    mov al, 8
    push es
    pop ds
    mov si, di
    or bh, bh
    js PgClipFillDrawWholeBytes
    or cx, cx
    jne PgClipFillDrawLeadingByte
    and bl, bh
    jmp short PgClipFillDrawTrailingByte
PgClipFillDrawLeadingByte:
    mov ah, bh
    out dx, ax
    movsb
    dec cx
PgClipFillDrawWholeBytes:
    mov ah, 0ffh
    out dx, ax
    rep movsb
PgClipFillDrawTrailingByte:
    mov ah, bl
    out dx, ax
    movsb
    pop ds
    mov cx, word ptr [bp+0ah]
    inc cx
    mov word ptr [bp+0ah], cx
    mov bx, word ptr [bp+6]
    cmp cx, bx
    jle PgClipFillDrawRow
PgClipFillRestoreRegisters:
    mov dx, PgGraphicsIndexPort
    xor ax, ax
    out dx, ax
    inc ax
    out dx, ax
    mov al, 3
    out dx, ax
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop di
    pop si
    pop bp
    retf 8
PgFillRectangleClippedPixels endp

; Draws a horizontal pixel span with masked endpoint bytes.
; Pascal stack equivalent (no interface declaration): procedure
; PgDrawHorizontalSpan(StartPixelX: Integer; EndPixelX: Integer; PixelY: Integer);
; Stack: BP+0Ah = StartPixelX; BP+08h = EndPixelX; BP+06h = PixelY; FAR return, callee pops 6
; argument bytes.
; Registers: prologue saves BP/SI/DI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawColor.
PgDrawHorizontalSpan proc far
    push bp
    mov bp, sp
    push si
    push di
    mov dx, PgGraphicsIndexPort
    mov ah, byte ptr cs:[PgDrawColor]
    xor al, al
    out dx, ax
    mov ax, PgEnableSetResetAll
    out dx, ax
    mov ah, 0
    mov al, 3
    out dx, ax
    mov si, word ptr cs:[PgScreenStrideBytes]
    mov ax, word ptr [bp+0ah]
    mov bx, word ptr [bp+8]
    cmp ax, bx
    jl PgHSpanSetupEndpoints
    mov word ptr [bp+0ah], bx
    mov word ptr [bp+8], ax
PgHSpanSetupEndpoints:
    push ds
    mov ax, word ptr [bp+6]
    mov bx, word ptr [bp+0ah]
    push cs
    call near ptr PgPixelAddressAndBitHelper
    mov di, bx
    mov dh, ah
    not dh
    shl dh, cl
    not dh
    mov cx, word ptr [bp+8]
    and cl, 7
    xor cl, 7
    mov dl, 0ffh
    shl dl, cl
    mov ax, word ptr [bp+8]
    mov bx, word ptr [bp+0ah]
    mov cl, 3
    shr ax, cl
    shr bx, cl
    mov cx, ax
    sub cx, bx
    mov bx, dx
    mov dx, PgGraphicsIndexPort
    mov al, 8
    push es
    pop ds
    mov si, di
    or bh, bh
    js PgHSpanDrawWholeBytes
    or cx, cx
    jne PgHSpanDrawLeadingByte
    and bl, bh
    jmp short PgHSpanDrawTrailingByte
PgHSpanDrawLeadingByte:
    mov ah, bh
    out dx, ax
    movsb
    dec cx
PgHSpanDrawWholeBytes:
    mov ah, 0ffh
    out dx, ax
    rep movsb
PgHSpanDrawTrailingByte:
    mov ah, bl
    out dx, ax
    movsb
    pop ds
    xor ax, ax
    out dx, ax
    inc ax
    out dx, ax
    mov al, 3
    out dx, ax
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop di
    pop si
    pop bp
    retf 6
PgDrawHorizontalSpan endp

; Draws an inclusive vertical span using one pixel mask per row.
; Pascal stack equivalent (no interface declaration): procedure
; PgDrawVerticalSpan(StartPixelY: Integer; EndPixelY: Integer; PixelX: Integer);
; Stack: BP+0Ah = StartPixelY; BP+08h = EndPixelY; BP+06h = PixelX; FAR return, callee pops 6
; argument bytes.
; Registers: prologue saves BP/SI/DI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawColor.
PgDrawVerticalSpan proc far
    push bp
    mov bp, sp
    push si
    push di
    mov dx, PgGraphicsIndexPort
    mov ah, byte ptr cs:[PgDrawColor]
    xor al, al
    out dx, ax
    mov ax, PgEnableSetResetAll
    out dx, ax
    mov ah, 0
    mov al, 3
    out dx, ax
    mov si, word ptr cs:[PgScreenStrideBytes]
    mov ax, word ptr [bp+0ah]
    mov bx, word ptr [bp+8]
    mov cx, bx
    sub cx, ax
    jge PgVSpanSetupTopRow
    neg cx
    mov ax, bx
PgVSpanSetupTopRow:
    inc cx
    mov bx, word ptr [bp+6]
    push cx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    shl ah, cl
    mov al, 8
    out dx, ax
    pop cx
PgVSpanDrawPixel:
    or byte ptr es:[bx], al
    add bx, si
    loop PgVSpanDrawPixel
    xor ax, ax
    out dx, ax
    inc ax
    out dx, ax
    mov al, 3
    out dx, ax
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop di
    pop si
    pop bp
    retf 6
PgDrawVerticalSpan endp

PgFillCircleOctantX             dw ?
PgFillCircleOctantY             dw ?
PgFillCircleDecision            dw ?
PgCircleSpanLeft                dw ?
PgCircleSpanRight               dw ?

; Circle drawing.

; Fills a circle with symmetric spans and the 3-2*radius midpoint decision.
; Pascal stack equivalent (no interface declaration): procedure PgFillCircle(CenterPixelX:
; Integer; CenterPixelY: Integer; RadiusPixels: Word);
; Stack: BP+0Ah = CenterPixelX; BP+08h = CenterPixelY; BP+06h = RadiusPixels; FAR return,
; callee pops 6 argument bytes.
; Registers: prologue saves BP/SI/DI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawColor, PgFillCircleOctantX, PgFillCircleOctantY,
; PgFillCircleDecision, PgCircleSpanLeft, PgCircleSpanRight.
PgFillCircle proc far
    push bp
    mov bp, sp
    push si
    push di
    mov dx, PgGraphicsIndexPort
    mov ah, byte ptr cs:[PgDrawColor]
    xor al, al
    out dx, ax
    mov ax, PgEnableSetResetAll
    out dx, ax
    mov ah, 0
    mov al, 3
    out dx, ax
    mov word ptr cs:[PgFillCircleOctantX], 0
    mov si, word ptr [bp+6]
    mov word ptr cs:[PgFillCircleOctantY], si
    mov si, 3
    sub si, word ptr [bp+6]
    sub si, word ptr [bp+6]
    mov word ptr cs:[PgFillCircleDecision], si
PgFillCircleNextOctant:
    mov si, word ptr cs:[PgScreenStrideBytes]
    push ds
    mov ax, word ptr [bp+8]
    add ax, word ptr cs:[PgFillCircleOctantY]
    mov bx, word ptr [bp+0ah]
    sub bx, word ptr cs:[PgFillCircleOctantX]
    mov word ptr cs:[PgCircleSpanLeft], bx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    mov di, bx
    mov dh, ah
    not dh
    shl dh, cl
    not dh
    mov cx, word ptr [bp+0ah]
    add cx, word ptr cs:[PgFillCircleOctantX]
    mov word ptr cs:[PgCircleSpanRight], cx
    and cl, 7
    xor cl, 7
    mov dl, 0ffh
    shl dl, cl
    mov ax, word ptr cs:[PgCircleSpanRight]
    mov bx, word ptr cs:[PgCircleSpanLeft]
    mov cl, 3
    shr ax, cl
    shr bx, cl
    mov cx, ax
    sub cx, bx
    mov bx, dx
    mov dx, PgGraphicsIndexPort
    mov al, 8
    push es
    pop ds
    mov si, di
    or bh, bh
    js PgFillCircleLowerOuterWhole
    or cx, cx
    jne PgFillCircleLowerOuterLeading
    and bl, bh
    jmp short PgFillCircleLowerOuterTrailing
PgFillCircleLowerOuterLeading:
    mov ah, bh
    out dx, ax
    movsb
    dec cx
PgFillCircleLowerOuterWhole:
    mov ah, 0ffh
    out dx, ax
    rep movsb
PgFillCircleLowerOuterTrailing:
    mov ah, bl
    out dx, ax
    movsb
    mov si, word ptr cs:[PgScreenStrideBytes]
    mov ax, word ptr [bp+8]
    sub ax, word ptr cs:[PgFillCircleOctantY]
    mov bx, word ptr [bp+0ah]
    sub bx, word ptr cs:[PgFillCircleOctantX]
    mov word ptr cs:[PgCircleSpanLeft], bx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    mov di, bx
    mov dh, ah
    not dh
    shl dh, cl
    not dh
    mov cx, word ptr [bp+0ah]
    add cx, word ptr cs:[PgFillCircleOctantX]
    mov word ptr cs:[PgCircleSpanRight], cx
    and cl, 7
    xor cl, 7
    mov dl, 0ffh
    shl dl, cl
    mov ax, word ptr cs:[PgCircleSpanRight]
    mov bx, word ptr cs:[PgCircleSpanLeft]
    mov cl, 3
    shr ax, cl
    shr bx, cl
    mov cx, ax
    sub cx, bx
    mov bx, dx
    mov dx, PgGraphicsIndexPort
    mov al, 8
    push es
    pop ds
    mov si, di
    or bh, bh
    js PgFillCircleUpperOuterWhole
    or cx, cx
    jne PgFillCircleUpperOuterLeading
    and bl, bh
    jmp short PgFillCircleUpperOuterTrailing
PgFillCircleUpperOuterLeading:
    mov ah, bh
    out dx, ax
    movsb
    dec cx
PgFillCircleUpperOuterWhole:
    mov ah, 0ffh
    out dx, ax
    rep movsb
PgFillCircleUpperOuterTrailing:
    mov ah, bl
    out dx, ax
    movsb
    mov si, word ptr cs:[PgScreenStrideBytes]
    mov ax, word ptr [bp+8]
    add ax, word ptr cs:[PgFillCircleOctantX]
    mov bx, word ptr [bp+0ah]
    sub bx, word ptr cs:[PgFillCircleOctantY]
    mov word ptr cs:[PgCircleSpanLeft], bx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    mov di, bx
    mov dh, ah
    not dh
    shl dh, cl
    not dh
    mov cx, word ptr [bp+0ah]
    add cx, word ptr cs:[PgFillCircleOctantY]
    mov word ptr cs:[PgCircleSpanRight], cx
    and cl, 7
    xor cl, 7
    mov dl, 0ffh
    shl dl, cl
    mov ax, word ptr cs:[PgCircleSpanRight]
    mov bx, word ptr cs:[PgCircleSpanLeft]
    mov cl, 3
    shr ax, cl
    shr bx, cl
    mov cx, ax
    sub cx, bx
    mov bx, dx
    mov dx, PgGraphicsIndexPort
    mov al, 8
    push es
    pop ds
    mov si, di
    or bh, bh
    js PgFillCircleLowerInnerWhole
    or cx, cx
    jne PgFillCircleLowerInnerLeading
    and bl, bh
    jmp short PgFillCircleLowerInnerTrailing
PgFillCircleLowerInnerLeading:
    mov ah, bh
    out dx, ax
    movsb
    dec cx
PgFillCircleLowerInnerWhole:
    mov ah, 0ffh
    out dx, ax
    rep movsb
PgFillCircleLowerInnerTrailing:
    mov ah, bl
    out dx, ax
    movsb
    mov si, word ptr cs:[PgScreenStrideBytes]
    mov ax, word ptr [bp+8]
    sub ax, word ptr cs:[PgFillCircleOctantX]
    mov bx, word ptr [bp+0ah]
    sub bx, word ptr cs:[PgFillCircleOctantY]
    mov word ptr cs:[PgCircleSpanLeft], bx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    mov di, bx
    mov dh, ah
    not dh
    shl dh, cl
    not dh
    mov cx, word ptr [bp+0ah]
    add cx, word ptr cs:[PgFillCircleOctantY]
    mov word ptr cs:[PgCircleSpanRight], cx
    and cl, 7
    xor cl, 7
    mov dl, 0ffh
    shl dl, cl
    mov ax, word ptr cs:[PgCircleSpanRight]
    mov bx, word ptr cs:[PgCircleSpanLeft]
    mov cl, 3
    shr ax, cl
    shr bx, cl
    mov cx, ax
    sub cx, bx
    mov bx, dx
    mov dx, PgGraphicsIndexPort
    mov al, 8
    push es
    pop ds
    mov si, di
    or bh, bh
    js PgFillCircleUpperInnerWhole
    or cx, cx
    jne PgFillCircleUpperInnerLeading
    and bl, bh
    jmp short PgFillCircleUpperInnerTrailing
PgFillCircleUpperInnerLeading:
    mov ah, bh
    out dx, ax
    movsb
    dec cx
PgFillCircleUpperInnerWhole:
    mov ah, 0ffh
    out dx, ax
    rep movsb
PgFillCircleUpperInnerTrailing:
    mov ah, bl
    out dx, ax
    movsb
    pop ds
    mov si, word ptr cs:[PgFillCircleDecision]
    cmp si, 0
    jle PgFillCircleKeepOctantY
    mov si, word ptr cs:[PgFillCircleDecision]
    add si, 0ah
    mov di, word ptr cs:[PgFillCircleOctantX]
    sub di, word ptr cs:[PgFillCircleOctantY]
    shl di, 1
    shl di, 1
    add si, di
    mov word ptr cs:[PgFillCircleDecision], si
    mov si, word ptr cs:[PgFillCircleOctantY]
    dec si
    mov word ptr cs:[PgFillCircleOctantY], si
    jmp short PgFillCircleAdvanceOctantX
    nop
PgFillCircleKeepOctantY:
    mov si, word ptr cs:[PgFillCircleDecision]
    add si, 6
    mov di, word ptr cs:[PgFillCircleOctantX]
    shl di, 1
    shl di, 1
    add si, di
    mov word ptr cs:[PgFillCircleDecision], si
PgFillCircleAdvanceOctantX:
    mov di, word ptr cs:[PgFillCircleOctantX]
    inc di
    mov word ptr cs:[PgFillCircleOctantX], di
    mov si, word ptr cs:[PgFillCircleOctantY]
    cmp si, di
    jl PgFillCircleRestoreRegisters
    jmp near ptr PgFillCircleNextOctant
PgFillCircleRestoreRegisters:
    xor ax, ax
    out dx, ax
    inc ax
    out dx, ax
    mov al, 3
    out dx, ax
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop di
    pop si
    pop bp
    retf 6
PgFillCircle endp

PgOutlineCircleOctantX          dw ?
PgOutlineCircleOctantY          dw ?
PgOutlineCircleDecision         dw ?
; Unused storage retains the original object layout.
UnusedPgCircleWord1             dw ?
; Unused storage retains the original object layout.
UnusedPgCircleWord2             dw ?
; Plots the eight symmetric points of each midpoint-circle octant step.
; Pascal stack equivalent (no interface declaration): procedure PgDrawCircle(CenterPixelX:
; Integer; CenterPixelY: Integer; RadiusPixels: Word);
; Stack: BP+0Ah = CenterPixelX; BP+08h = CenterPixelY; BP+06h = RadiusPixels; FAR return,
; callee pops 6 argument bytes.
; Registers: prologue saves BP/SI/DI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawColor, PgOutlineCircleOctantX,
; PgOutlineCircleOctantY, PgOutlineCircleDecision.
PgDrawCircle proc far
    push bp
    mov bp, sp
    push si
    push di
    mov dx, PgGraphicsIndexPort
    mov ah, byte ptr cs:[PgDrawColor]
    xor al, al
    out dx, ax
    mov ax, PgEnableSetResetAll
    out dx, ax
    mov ah, 0
    mov al, 3
    out dx, ax
    mov word ptr cs:[PgOutlineCircleOctantX], 0
    mov si, word ptr [bp+6]
    mov word ptr cs:[PgOutlineCircleOctantY], si
    mov si, 3
    sub si, word ptr [bp+6]
    sub si, word ptr [bp+6]
    mov word ptr cs:[PgOutlineCircleDecision], si
PgOutlineCircleNextOctant:
    mov si, word ptr cs:[PgScreenStrideBytes]
    mov ax, word ptr [bp+8]
    add ax, word ptr cs:[PgOutlineCircleOctantY]
    mov bx, word ptr [bp+0ah]
    add bx, word ptr cs:[PgOutlineCircleOctantX]
    push cx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    shl ah, cl
    mov al, 8
    out dx, ax
    pop cx
    or byte ptr es:[bx], al
    mov ax, word ptr [bp+8]
    sub ax, word ptr cs:[PgOutlineCircleOctantY]
    mov bx, word ptr [bp+0ah]
    add bx, word ptr cs:[PgOutlineCircleOctantX]
    push cx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    shl ah, cl
    mov al, 8
    out dx, ax
    pop cx
    or byte ptr es:[bx], al
    mov ax, word ptr [bp+8]
    add ax, word ptr cs:[PgOutlineCircleOctantY]
    mov bx, word ptr [bp+0ah]
    sub bx, word ptr cs:[PgOutlineCircleOctantX]
    push cx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    shl ah, cl
    mov al, 8
    out dx, ax
    pop cx
    or byte ptr es:[bx], al
    mov ax, word ptr [bp+8]
    sub ax, word ptr cs:[PgOutlineCircleOctantY]
    mov bx, word ptr [bp+0ah]
    sub bx, word ptr cs:[PgOutlineCircleOctantX]
    push cx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    shl ah, cl
    mov al, 8
    out dx, ax
    pop cx
    or byte ptr es:[bx], al
    mov ax, word ptr [bp+8]
    add ax, word ptr cs:[PgOutlineCircleOctantX]
    mov bx, word ptr [bp+0ah]
    add bx, word ptr cs:[PgOutlineCircleOctantY]
    push cx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    shl ah, cl
    mov al, 8
    out dx, ax
    pop cx
    or byte ptr es:[bx], al
    mov ax, word ptr [bp+8]
    sub ax, word ptr cs:[PgOutlineCircleOctantX]
    mov bx, word ptr [bp+0ah]
    add bx, word ptr cs:[PgOutlineCircleOctantY]
    push cx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    shl ah, cl
    mov al, 8
    out dx, ax
    pop cx
    or byte ptr es:[bx], al
    mov ax, word ptr [bp+8]
    add ax, word ptr cs:[PgOutlineCircleOctantX]
    mov bx, word ptr [bp+0ah]
    sub bx, word ptr cs:[PgOutlineCircleOctantY]
    push cx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    shl ah, cl
    mov al, 8
    out dx, ax
    pop cx
    or byte ptr es:[bx], al
    mov ax, word ptr [bp+8]
    sub ax, word ptr cs:[PgOutlineCircleOctantX]
    mov bx, word ptr [bp+0ah]
    sub bx, word ptr cs:[PgOutlineCircleOctantY]
    push cx
    push cs
    call near ptr PgPixelAddressAndBitHelper
    shl ah, cl
    mov al, 8
    out dx, ax
    pop cx
    or byte ptr es:[bx], al
    mov si, word ptr cs:[PgOutlineCircleDecision]
    cmp si, 0
    jle PgOutlineCircleKeepOctantY
    mov si, word ptr cs:[PgOutlineCircleDecision]
    add si, 0ah
    mov di, word ptr cs:[PgOutlineCircleOctantX]
    sub di, word ptr cs:[PgOutlineCircleOctantY]
    shl di, 1
    shl di, 1
    add si, di
    mov word ptr cs:[PgOutlineCircleDecision], si
    mov si, word ptr cs:[PgOutlineCircleOctantY]
    dec si
    mov word ptr cs:[PgOutlineCircleOctantY], si
    jmp short PgOutlineCircleAdvanceOctantX
    nop
PgOutlineCircleKeepOctantY:
    mov si, word ptr cs:[PgOutlineCircleDecision]
    add si, 6
    mov di, word ptr cs:[PgOutlineCircleOctantX]
    shl di, 1
    shl di, 1
    add si, di
    mov word ptr cs:[PgOutlineCircleDecision], si
PgOutlineCircleAdvanceOctantX:
    mov di, word ptr cs:[PgOutlineCircleOctantX]
    inc di
    mov word ptr cs:[PgOutlineCircleOctantX], di
    mov si, word ptr cs:[PgOutlineCircleOctantY]
    cmp si, di
    jl PgOutlineCircleRestoreRegisters
    jmp near ptr PgOutlineCircleNextOctant
PgOutlineCircleRestoreRegisters:
    xor ax, ax
    out dx, ax
    inc ax
    out dx, ax
    mov al, 3
    out dx, ax
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop di
    pop si
    pop bp
    retf 6
PgDrawCircle endp

; Clip rectangle state.

; Stores byte-column left/right limits and shared top/bottom row limits.
; Pascal stack equivalent (no interface declaration): procedure
; PgSetByteClipRectangle(LeftByteColumn: Word; TopPixelRow: Integer; RightByteColumn: Word;
; BottomPixelRow: Integer);
; Stack: BP+0Ch = LeftByteColumn; BP+0Ah = TopPixelRow; BP+08h = RightByteColumn; BP+06h =
; BottomPixelRow; FAR return, callee pops 8 argument bytes.
; Registers: prologue saves BP; other registers and flags may change.
; Direct CS state: PgClipLeftByte, PgClipRightByte, PgClipTopRow, PgClipBottomRow.
PgSetByteClipRectangle proc far
    push bp
    mov bp, sp
    mov ax, word ptr [bp+0ch]
    mov word ptr cs:[PgClipLeftByte], ax
    mov ax, word ptr [bp+8]
    mov word ptr cs:[PgClipRightByte], ax
    mov ax, word ptr [bp+0ah]
    mov word ptr cs:[PgClipTopRow], ax
    mov ax, word ptr [bp+6]
    mov word ptr cs:[PgClipBottomRow], ax
    pop bp
    retf 8
PgSetByteClipRectangle endp

; Returns the byte-column left clip limit in AX.
; Pascal stack equivalent (no interface declaration): function PgGetByteClipLeft: Integer;
; Stack: FAR return, callee pops 0 argument bytes.
; Registers: other registers and flags may change.
; Direct CS state: PgClipLeftByte.
PgGetByteClipLeft proc far
    mov ax, word ptr cs:[PgClipLeftByte]
    retf
PgGetByteClipLeft endp

; Returns the byte-column right clip limit in AX.
; Pascal stack equivalent (no interface declaration): function PgGetByteClipRight: Integer;
; Stack: FAR return, callee pops 0 argument bytes.
; Registers: other registers and flags may change.
; Direct CS state: PgClipRightByte.
PgGetByteClipRight proc far
    mov ax, word ptr cs:[PgClipRightByte]
    retf
PgGetByteClipRight endp

; Stores pixel left/right limits and shared top/bottom row limits.
; Pascal stack equivalent (no interface declaration): procedure
; PgSetPixelClipRectangle(LeftPixelX: Integer; TopPixelY: Integer; RightPixelX: Integer;
; BottomPixelY: Integer);
; Stack: BP+0Ch = LeftPixelX; BP+0Ah = TopPixelY; BP+08h = RightPixelX; BP+06h = BottomPixelY;
; FAR return, callee pops 8 argument bytes.
; Registers: prologue saves BP; other registers and flags may change.
; Direct CS state: PgClipTopRow, PgClipBottomRow, PgClipLeftPixel, PgClipRightPixel.
PgSetPixelClipRectangle proc far
    push bp
    mov bp, sp
    mov ax, word ptr [bp+0ch]
    mov word ptr cs:[PgClipLeftPixel], ax
    mov ax, word ptr [bp+8]
    mov word ptr cs:[PgClipRightPixel], ax
    mov ax, word ptr [bp+0ah]
    mov word ptr cs:[PgClipTopRow], ax
    mov ax, word ptr [bp+6]
    mov word ptr cs:[PgClipBottomRow], ax
    pop bp
    retf 8
PgSetPixelClipRectangle endp

; Returns the pixel left clip limit in AX.
; Pascal stack equivalent (no interface declaration): function PgGetPixelClipLeft: Integer;
; Stack: FAR return, callee pops 0 argument bytes.
; Registers: other registers and flags may change.
; Direct CS state: PgClipLeftPixel.
PgGetPixelClipLeft proc far
    mov ax, word ptr cs:[PgClipLeftPixel]
    retf
PgGetPixelClipLeft endp

; Returns the pixel right clip limit in AX.
; Pascal stack equivalent (no interface declaration): function PgGetPixelClipRight: Integer;
; Stack: FAR return, callee pops 0 argument bytes.
; Registers: other registers and flags may change.
; Direct CS state: PgClipRightPixel.
PgGetPixelClipRight proc far
    mov ax, word ptr cs:[PgClipRightPixel]
    retf
PgGetPixelClipRight endp

; Returns the shared top row clip limit in AX.
; Pascal stack equivalent (no interface declaration): function PgGetClipTop: Integer;
; Stack: FAR return, callee pops 0 argument bytes.
; Registers: other registers and flags may change.
; Direct CS state: PgClipTopRow.
PgGetClipTop proc far
    mov ax, word ptr cs:[PgClipTopRow]
    retf
PgGetClipTop endp

; Returns the shared bottom row clip limit in AX.
; Pascal stack equivalent (no interface declaration): function PgGetClipBottom: Integer;
; Stack: FAR return, callee pops 0 argument bytes.
; Registers: other registers and flags may change.
; Direct CS state: PgClipBottomRow.
PgGetClipBottom proc far
    mov ax, word ptr cs:[PgClipBottomRow]
    retf
PgGetClipBottom endp

; Planar rectangle capture and shifted sprites.

; Captures a byte-aligned rectangle: row count, row bytes, FFh mask, then planes 3..0.
; Pascal: procedure PgCapturePlanarRectangle(var CapturedImage; LeftByteColumn, TopPixelRow,
; RightByteLimit, BottomPixelRow: Integer);
; Stack: BP+06h = BottomPixelRow; BP+08h = RightByteLimit; BP+0Ah = TopPixelRow; BP+0Ch =
; LeftByteColumn; BP+0Eh = CapturedImage (far pointer); FAR return, callee pops 12 argument
; bytes.
; Registers: prologue saves BP/DS/SI/DI; other registers and flags may change.
; Direct CS state: PgTransferRowsRemaining, PgTransferRowBytes, PgScreenStrideBytes,
; PgDrawPage.
; Right byte limit is exclusive; bottom row is inclusive. The image header stores row count
; before row bytes.
PgCapturePlanarRectangle proc far
    push bp
    mov bp, sp
    push ds
    push si
    push di
    mov ax, word ptr [bp+8]
    sub ax, word ptr [bp+0ch]
    push ax
    mov ax, word ptr [bp+6]
    sub ax, word ptr [bp+0ah]
    inc ax
    push ax
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+0ah]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov bx, word ptr [bp+0ch]
    add bx, ax
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgCaptureWriteHeader
    mov cx, ax
PgCaptureAddPageOffset:
    add bx, PgVideoPageBytes
    loop PgCaptureAddPageOffset
PgCaptureWriteHeader:
    push es
    pop ds
    mov si, bx
    les di, dword ptr [bp+0eh]
    nop
    pop ax
    mov word ptr cs:[PgTransferRowsRemaining], ax
    stosw
    pop ax
    mov word ptr cs:[PgTransferRowBytes], ax
    stosw
    mov al, 0ffh
    stosb
    mov dx, PgGraphicsIndexPort
    mov ax, 5
    out dx, ax
    mov ax, PgReadMapPlane3
PgCaptureReadPlane:
    out dx, ax
    push ax
    push word ptr cs:[PgTransferRowsRemaining]
    push si
PgCaptureReadRow:
    mov bx, word ptr cs:[PgTransferRowBytes]
    push si
PgCaptureCopyByte:
    lodsb
    stosb
    dec bx
    jne PgCaptureCopyByte
    pop si
    add si, word ptr cs:[PgScreenStrideBytes]
    dec word ptr cs:[PgTransferRowsRemaining]
    jne PgCaptureReadRow
    pop si
    pop word ptr cs:[PgTransferRowsRemaining]
    pop ax
    dec ah
    jns PgCaptureReadPlane
    mov ax, di
    sub ax, word ptr [bp+0eh]
    nop
    pop di
    pop si
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PgCapturePlanarRectangle endp

; Restores the row-count/row-bytes/mask header and four captured planes.
; Pascal: procedure PgRestorePlanarRectangle(var CapturedImage; ByteColumn, PixelRow:
; Integer);
; Stack: BP+06h = PixelRow; BP+08h = ByteColumn; BP+0Ah = CapturedImage (far pointer); FAR
; return, callee pops 8 argument bytes.
; Registers: prologue saves BP/DS/SI/DI; other registers and flags may change.
; Direct CS state: PgTransferRowsRemaining, PgTransferRowBytes, PgScreenStrideBytes,
; PgDrawPage.
; Original final AX calculation reads BP+0Eh beyond this entry's declared arguments; retained
; for exactness.
PgRestorePlanarRectangle proc far
    push bp
    mov bp, sp
    push ds
    push si
    push di
    lds si, dword ptr [bp+0ah]
    lodsw
    mov word ptr cs:[PgTransferRowsRemaining], ax
    lodsw
    mov word ptr cs:[PgTransferRowBytes], ax
    lodsb
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+6]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov bx, word ptr [bp+8]
    add bx, ax
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgRestoreSelectMapMask
    mov cx, ax
PgRestoreAddPageOffset:
    add bx, PgVideoPageBytes
    loop PgRestoreAddPageOffset
PgRestoreSelectMapMask:
    mov di, bx
    mov dx, PgSequencerIndexPort
    mov al, PgSeqMapMask
    out dx, al
    mov dx, PgSequencerDataPort
    mov ax, 8
PgRestoreWritePlane:
    out dx, al
    shr ax, 1
    push ax
    push word ptr cs:[PgTransferRowsRemaining]
    push di
PgRestoreWriteRow:
    mov bx, word ptr cs:[PgTransferRowBytes]
PgRestoreCopyByte:
    lodsb
    xchg byte ptr es:[di], al
    inc di
    dec bx
    jne PgRestoreCopyByte
    add di, word ptr cs:[PgScreenStrideBytes]
    sub di, word ptr cs:[PgTransferRowBytes]
    dec word ptr cs:[PgTransferRowsRemaining]
    jne PgRestoreWriteRow
    pop di
    pop word ptr cs:[PgTransferRowsRemaining]
    pop ax
    cmp ax, 0
    jg PgRestoreWritePlane
    mov ax, si
    sub ax, word ptr [bp+0eh]
    nop
    pop di
    pop si
    pop ds
    mov sp, bp
    pop bp
    retf 8
PgRestorePlanarRectangle endp

PgSpriteBytesRemaining          db ?
PgSpriteRightShift              db ?
PgSpriteLeftShift               db ?
PgSpriteSourceMask              db ?
PgSpritePlane0Byte              db ?
PgSpritePlane1                  db ?
PgSpritePlane2                  db ?
PgSpritePlane3                  db ?
; Splits shifted 32x16 sprite bytes across neighboring destination bytes.
; Pascal stack equivalent (no interface declaration): procedure
; PgBlitMaskedShifted32x16(ImageSourcePointer: Pointer; PixelX: Integer; PixelY: Integer);
; Stack: BP+0Ah = ImageSourcePointer; BP+08h = PixelX; BP+06h = PixelY; FAR return, callee
; pops 8 argument bytes.
; Registers: prologue saves BP/DS/SI/DI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage, PgSpriteBytesRemaining,
; PgSpriteRightShift, PgSpriteLeftShift, PgSpriteSourceMask, PgSpritePlane0Byte,
; PgSpritePlane1, PgSpritePlane2, PgSpritePlane3.
PgBlitMaskedShifted32x16 proc far
    push bp
    mov bp, sp
    push ds
    push si
    push di
    lds si, dword ptr [bp+0ah]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+6]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov bx, word ptr [bp+8]
    mov cl, 3
    shr bx, cl
    add bx, ax
    mov ax, word ptr [bp+8]
    and ax, 7
    mov byte ptr cs:[PgSpriteRightShift], al
    mov al, 8
    sub al, byte ptr cs:[PgSpriteRightShift]
    mov byte ptr cs:[PgSpriteLeftShift], al
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgShiftMask32SelectMapMask
    mov cx, ax
PgShiftMask32AddPageOffset:
    add bx, PgVideoPageBytes
    loop PgShiftMask32AddPageOffset
PgShiftMask32SelectMapMask:
    mov dx, PgSequencerIndexPort
    mov al, 2
    out dx, al
    mov cx, 10h
PgShiftMask32DrawRow:
    mov byte ptr cs:[PgSpriteBytesRemaining], 4
PgShiftMask32DrawByteGroup:
    mov dl, byte ptr cs:[PgSpriteBytesRemaining]
    dec dl
    mov byte ptr cs:[PgSpriteBytesRemaining], dl
    push cx
    mov dx, PgGraphicsIndexPort
    lodsb
    mov byte ptr cs:[PgSpriteSourceMask], al
    mov ah, byte ptr cs:[PgSpriteSourceMask]
    mov cl, byte ptr cs:[PgSpriteRightShift]
    shr ah, cl
    mov al, 8
    out dx, ax
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    mov byte ptr cs:[PgSpritePlane0Byte], al
    shr al, cl
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    mov byte ptr cs:[PgSpritePlane1], al
    shr al, cl
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    mov byte ptr cs:[PgSpritePlane2], al
    shr al, cl
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    mov byte ptr cs:[PgSpritePlane3], al
    shr al, cl
    xchg byte ptr es:[bx], al
    jmp short PgShiftMask32WriteHighParts
    nop
PgShiftMask32RowLoopBridge:
    jmp short PgShiftMask32DrawRow
PgShiftMask32GroupLoopBridge:
    jmp short PgShiftMask32DrawByteGroup
PgShiftMask32WriteHighParts:
    inc bx
    mov dx, PgGraphicsIndexPort
    mov ah, byte ptr cs:[PgSpriteSourceMask]
    mov cl, byte ptr cs:[PgSpriteLeftShift]
    shl ah, cl
    mov al, 8
    out dx, ax
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    mov al, byte ptr cs:[PgSpritePlane0Byte]
    shl al, cl
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    mov al, byte ptr cs:[PgSpritePlane1]
    shl al, cl
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    mov al, byte ptr cs:[PgSpritePlane2]
    shl al, cl
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    mov al, byte ptr cs:[PgSpritePlane3]
    shl al, cl
    xchg byte ptr es:[bx], al
    pop cx
    mov dl, byte ptr cs:[PgSpriteBytesRemaining]
    cmp dl, 0
    jg PgShiftMask32GroupLoopBridge
    add bx, word ptr cs:[PgScreenStrideBytes]
    dec bx
    dec bx
    dec bx
    dec bx
    loop PgShiftMask32RowLoopBridge
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop di
    pop si
    pop ds
    pop bp
    retf 8
PgBlitMaskedShifted32x16 endp

; Splits shifted 16x16 sprite bytes across neighboring destination bytes.
; Pascal: procedure PgBlitMaskedShifted16x16(var SpriteSource; PixelX, PixelY: Integer);
; Stack: BP+06h = PixelY; BP+08h = PixelX; BP+0Ah = SpriteSource (far pointer); FAR return,
; callee pops 8 argument bytes.
; Registers: prologue saves BP/DS/SI/DI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgSpriteBytesRemaining, PgSpriteRightShift,
; PgSpriteLeftShift, PgSpritePlane0Byte, PgSpritePlane1, PgSpritePlane2, PgSpritePlane3.
PgBlitMaskedShifted16x16 proc far
    push bp
    mov bp, sp
    push ds
    push si
    push di
    mov di, word ptr cs:[PgScreenStrideBytes]
    dec di
    dec di
    lds si, dword ptr [bp+0ah]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+6]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov bx, word ptr [bp+8]
    mov cl, 3
    shr bx, cl
    add bx, ax
    mov ax, word ptr [bp+8]
    and ax, 7
    mov byte ptr cs:[PgSpriteRightShift], al
    mov al, 8
    sub al, byte ptr cs:[PgSpriteRightShift]
    mov byte ptr cs:[PgSpriteLeftShift], al
    mov dx, PgSequencerIndexPort
    mov al, 2
    out dx, al
    mov cx, 10h
PgShiftMask16DrawRow:
    mov byte ptr cs:[PgSpriteBytesRemaining], 2
PgShiftMask16DrawByteGroup:
    mov dl, byte ptr cs:[PgSpriteBytesRemaining]
    dec dl
    mov byte ptr cs:[PgSpriteBytesRemaining], dl
    push cx
    push di
    mov dx, PgGraphicsIndexPort
    lodsb
    mov ah, al
    mov di, ax
    mov cl, byte ptr cs:[PgSpriteRightShift]
    shr ah, cl
    mov al, 8
    out dx, ax
    mov dx, PgSequencerDataPort
    mov ch, 1
    mov al, ch
    out dx, al
    lodsb
    mov byte ptr cs:[PgSpritePlane0Byte], al
    shr al, cl
    xchg byte ptr es:[bx], al
    shl ch, 1
    mov al, ch
    out dx, al
    lodsb
    mov byte ptr cs:[PgSpritePlane1], al
    shr al, cl
    xchg byte ptr es:[bx], al
    shl ch, 1
    mov al, ch
    out dx, al
    lodsb
    mov byte ptr cs:[PgSpritePlane2], al
    shr al, cl
    xchg byte ptr es:[bx], al
    shl ch, 1
    mov al, ch
    out dx, al
    lodsb
    mov byte ptr cs:[PgSpritePlane3], al
    shr al, cl
    xchg byte ptr es:[bx], al
    jmp short PgShiftMask16WriteHighParts
    nop
PgShiftMask16RowLoopBridge:
    jmp short PgShiftMask16DrawRow
PgShiftMask16GroupLoopBridge:
    jmp short PgShiftMask16DrawByteGroup
PgShiftMask16WriteHighParts:
    inc bx
    mov dx, PgGraphicsIndexPort
    mov ax, di
    mov cl, byte ptr cs:[PgSpriteLeftShift]
    shl ah, cl
    mov al, 8
    out dx, ax
    mov dx, PgSequencerDataPort
    mov ch, 1
    mov al, ch
    out dx, al
    mov al, byte ptr cs:[PgSpritePlane0Byte]
    shl al, cl
    xchg byte ptr es:[bx], al
    shl ch, 1
    mov al, ch
    out dx, al
    mov al, byte ptr cs:[PgSpritePlane1]
    shl al, cl
    xchg byte ptr es:[bx], al
    shl ch, 1
    mov al, ch
    out dx, al
    mov al, byte ptr cs:[PgSpritePlane2]
    shl al, cl
    xchg byte ptr es:[bx], al
    shl ch, 1
    mov al, ch
    out dx, al
    mov al, byte ptr cs:[PgSpritePlane3]
    shl al, cl
    xchg byte ptr es:[bx], al
    pop di
    pop cx
    mov dl, byte ptr cs:[PgSpriteBytesRemaining]
    cmp dl, 0
    jg PgShiftMask16GroupLoopBridge
    add bx, di
    loop PgShiftMask16RowLoopBridge
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop di
    pop si
    pop ds
    pop bp
    retf 8
PgBlitMaskedShifted16x16 endp

PgGlyphMaskHigh                 db ?
PgGlyphMaskLow                  db ?
; Unused storage retains the original object layout.
UnusedPgSpriteByte1             db ?
; Unused storage retains the original object layout.
UnusedPgSpriteByte2             db ?
PgGlyphLeftShift                db ?
; Splits each masked 8x8 sprite row across two destination bytes.
; Pascal: procedure PgBlitMaskedShifted8x8(var GlyphSource: Byte; PixelX, PixelY: Word);
; Stack: BP+06h = PixelY; BP+08h = PixelX; BP+0Ah = GlyphSource (far pointer); FAR return,
; callee pops 8 argument bytes.
; Registers: prologue saves BP/DS/DI/SI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage, PgGlyphMaskHigh, PgGlyphMaskLow,
; PgGlyphLeftShift.
PgBlitMaskedShifted8x8 proc far
    push bp
    mov bp, sp
    push ds
    push di
    push si
    lds si, dword ptr [bp+0ah]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+6]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov cx, word ptr [bp+8]
    and cx, 7
    xor cl, 7
    inc cl
    mov byte ptr cs:[PgGlyphLeftShift], cl
    mov bx, word ptr [bp+8]
    shr bx, 1
    shr bx, 1
    shr bx, 1
    add bx, ax
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgShiftMask8SelectMapMask
    mov cx, ax
PgShiftMask8AddPageOffset:
    add bx, PgVideoPageBytes
    loop PgShiftMask8AddPageOffset
PgShiftMask8SelectMapMask:
    mov dx, PgSequencerIndexPort
    mov al, 2
    out dx, al
    mov cx, 8
PgShiftMask8DrawRow:
    push cx
    lodsb
    mov ah, 0
    mov cl, byte ptr cs:[PgGlyphLeftShift]
    rol ax, cl
    mov byte ptr cs:[PgGlyphMaskHigh], ah
    mov byte ptr cs:[PgGlyphMaskLow], al
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    mov ah, 0
    mov cl, byte ptr cs:[PgGlyphLeftShift]
    rol ax, cl
    mov cx, ax
    mov dx, PgGraphicsIndexPort
    mov al, 8
    mov ah, byte ptr cs:[PgGlyphMaskHigh]
    out dx, ax
    xchg byte ptr es:[bx], ch
    mov ah, byte ptr cs:[PgGlyphMaskLow]
    out dx, ax
    xchg byte ptr es:[bx+1], cl
    mov dx, PgSequencerDataPort
    mov al, 2
    out dx, al
    lodsb
    mov ah, 0
    mov cl, byte ptr cs:[PgGlyphLeftShift]
    rol ax, cl
    mov cx, ax
    mov dx, PgGraphicsIndexPort
    mov al, 8
    mov ah, byte ptr cs:[PgGlyphMaskHigh]
    out dx, ax
    xchg byte ptr es:[bx], ch
    mov ah, byte ptr cs:[PgGlyphMaskLow]
    out dx, ax
    xchg byte ptr es:[bx+1], cl
    jmp short PgShiftMask8WriteHighParts
    nop
PgShiftMask8RowLoopBridge:
    jmp short PgShiftMask8DrawRow
PgShiftMask8WriteHighParts:
    mov dx, PgSequencerDataPort
    mov al, 4
    out dx, al
    lodsb
    mov ah, 0
    mov cl, byte ptr cs:[PgGlyphLeftShift]
    rol ax, cl
    mov cx, ax
    mov dx, PgGraphicsIndexPort
    mov al, 8
    mov ah, byte ptr cs:[PgGlyphMaskHigh]
    out dx, ax
    xchg byte ptr es:[bx], ch
    mov ah, byte ptr cs:[PgGlyphMaskLow]
    out dx, ax
    xchg byte ptr es:[bx+1], cl
    mov dx, PgSequencerDataPort
    mov al, 8
    out dx, al
    lodsb
    mov ah, 0
    mov cl, byte ptr cs:[PgGlyphLeftShift]
    rol ax, cl
    mov cx, ax
    mov dx, PgGraphicsIndexPort
    mov al, 8
    mov ah, byte ptr cs:[PgGlyphMaskHigh]
    out dx, ax
    xchg byte ptr es:[bx], ch
    mov ah, byte ptr cs:[PgGlyphMaskLow]
    out dx, ax
    xchg byte ptr es:[bx+1], cl
    add bx, word ptr cs:[PgScreenStrideBytes]
    pop cx
    loop PgShiftMask8RowLoopBridge
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
PgBlitMaskedShifted8x8 endp

; Ellipse plotting.

; Draws an ellipse using squared radii and four-way symmetric pixel updates.
; Pascal stack equivalent (no interface declaration): procedure PgDrawEllipse(CenterPixelX:
; Integer; CenterPixelY: Integer; RadiusX: Word; RadiusY: Word);
; Stack: BP+0Ch = CenterPixelX; BP+0Ah = CenterPixelY; BP+08h = RadiusX; BP+06h = RadiusY; FAR
; return, callee pops 8 argument bytes.
; Registers: prologue saves BP/SI/DI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawColor.
PgDrawEllipse proc far
    push bp
    mov bp, sp
    sub sp, 28h
    push si
    push di
    mov dx, PgGraphicsIndexPort
    mov ax, 5
    out dx, ax
    mov ah, 0
    mov al, 3
    out dx, ax
    mov ax, word ptr cs:[PgDrawColor]
    mov ah, al
    mov al, 0
    out dx, ax
    mov ax, PgEnableSetResetAll
    out dx, ax
    mov ax, word ptr [bp+8]
    mul ax
    mov word ptr [bp-20h], ax
    mov word ptr [bp-1eh], dx
    shl ax, 1
    rcl dx, 1
    mov word ptr [bp-28h], ax
    mov word ptr [bp-26h], dx
    mov ax, word ptr [bp+6]
    mul ax
    mov word ptr [bp-24h], ax
    mov word ptr [bp-22h], dx
    shl ax, 1
    rcl dx, 1
    mov word ptr [bp-2ch], ax
    mov word ptr [bp-2ah], dx
    mov ax, word ptr cs:[PgScreenStrideBytes]
    mul word ptr [bp+6]
    mov si, ax
    mov di, ax
    mov ax, word ptr [bp+0ah]
    mov bx, word ptr [bp+0ch]
    push cs
    call near ptr PgPixelAddressAndBitHelper
    mov ah, 1
    shl ah, cl
    mov byte ptr [bp-0eh], ah
    mov byte ptr [bp-10h], ah
    add si, bx
    mov word ptr [bp-6], si
    mov word ptr [bp-8], si
    sub bx, di
    mov word ptr [bp-0ah], bx
    mov word ptr [bp-0ch], bx
    xor ax, ax
    mov word ptr [bp-18h], ax
    mov word ptr [bp-16h], ax
    mov ax, word ptr [bp-28h]
    mov dx, word ptr [bp-26h]
    mov cx, word ptr [bp+6]
    call near ptr PgMultiplyPartialProductsHelper
    mov word ptr [bp-1ch], ax
    mov word ptr [bp-1ah], dx
    mov ax, word ptr [bp-20h]
    mov dx, word ptr [bp-1eh]
    sar dx, 1
    rcr ax, 1
    sar dx, 1
    rcr ax, 1
    add ax, word ptr [bp-24h]
    adc dx, word ptr [bp-22h]
    mov word ptr [bp-14h], ax
    mov word ptr [bp-12h], dx
    mov ax, word ptr [bp-20h]
    mov dx, word ptr [bp-1eh]
    mov cx, word ptr [bp+6]
    call near ptr PgMultiplyPartialProductsHelper
    sub word ptr [bp-14h], ax
    sbb word ptr [bp-12h], dx
    mov bx, word ptr [bp+6]
    xor cx, cx
PgEllipseFirstRegion:
    mov ax, word ptr [bp-18h]
    mov dx, word ptr [bp-16h]
    sub ax, word ptr [bp-1ch]
    sbb dx, word ptr [bp-1ah]
    jns PgEllipseInitSecondRegion
    call near ptr PgPlotEllipseSymmetricPixels
    mov cx, 1
    cmp word ptr [bp-12h], 0
    js PgEllipseAdvanceFirstX
    mov ch, 1
    dec bx
    mov ax, word ptr [bp-1ch]
    mov dx, word ptr [bp-1ah]
    sub ax, word ptr [bp-28h]
    sbb dx, word ptr [bp-26h]
    mov word ptr [bp-1ch], ax
    mov word ptr [bp-1ah], dx
    sub word ptr [bp-14h], ax
    sbb word ptr [bp-12h], dx
PgEllipseAdvanceFirstX:
    mov ax, word ptr [bp-18h]
    mov dx, word ptr [bp-16h]
    add ax, word ptr [bp-2ch]
    adc dx, word ptr [bp-2ah]
    mov word ptr [bp-18h], ax
    mov word ptr [bp-16h], dx
    add ax, word ptr [bp-24h]
    adc dx, word ptr [bp-22h]
    add word ptr [bp-14h], ax
    adc word ptr [bp-12h], dx
    jmp short PgEllipseFirstRegion
PgEllipseInitSecondRegion:
    push bx
    push cx
    mov ax, word ptr [bp-20h]
    mov dx, word ptr [bp-1eh]
    sub ax, word ptr [bp-24h]
    sbb dx, word ptr [bp-22h]
    mov bx, ax
    mov cx, dx
    sar dx, 1
    rcr ax, 1
    add ax, bx
    adc dx, cx
    sub ax, word ptr [bp-18h]
    sbb dx, word ptr [bp-16h]
    sub ax, word ptr [bp-1ch]
    sbb dx, word ptr [bp-1ah]
    sar dx, 1
    rcr ax, 1
    add word ptr [bp-14h], ax
    adc word ptr [bp-12h], dx
    pop cx
    pop bx
PgEllipseSecondRegion:
    call near ptr PgPlotEllipseSymmetricPixels
    mov cx, 100h
    cmp word ptr [bp-12h], 0
    jns PgEllipseAdvanceSecondY
    mov cl, 1
    mov ax, word ptr [bp-18h]
    mov dx, word ptr [bp-16h]
    add ax, word ptr [bp-2ch]
    adc dx, word ptr [bp-2ah]
    mov word ptr [bp-18h], ax
    mov word ptr [bp-16h], dx
    add word ptr [bp-14h], ax
    adc word ptr [bp-12h], dx
PgEllipseAdvanceSecondY:
    mov ax, word ptr [bp-1ch]
    mov dx, word ptr [bp-1ah]
    sub ax, word ptr [bp-28h]
    sbb dx, word ptr [bp-26h]
    mov word ptr [bp-1ch], ax
    mov word ptr [bp-1ah], dx
    sub ax, word ptr [bp-20h]
    sbb dx, word ptr [bp-1eh]
    sub word ptr [bp-14h], ax
    sbb word ptr [bp-12h], dx
    dec bx
    jns PgEllipseSecondRegion
    mov ax, PgBitMaskAllPixels
    mov dx, PgGraphicsIndexPort
    out dx, ax
    mov ax, 3
    out dx, ax
    mov ax, 1
    out dx, ax
    pop di
    pop si
    mov sp, bp
    pop bp
    retf 8
PgDrawEllipse endp

; Advances ellipse masks/addresses and writes four symmetric pixels.
; Pascal: internal register helper; no stack declaration retained.
; Registers/stack: Inherits PgDrawEllipse BP frame and ES; CL/CH steer mask/row movement.
; AX/BX/DX saved; CX/SI/DI and flags scratch; NEAR return.
; Direct CS state: PgScreenStrideBytes.
PgPlotEllipseSymmetricPixels proc near
    push ax
    push bx
    push dx
    mov dx, PgGraphicsIndexPort
    xor bx, bx
    test ch, ch
    je PgEllipsePixRotateAndWriteMasks
    mov bx, word ptr cs:[PgScreenStrideBytes]
    neg bx
PgEllipsePixRotateAndWriteMasks:
    mov al, 8
    xor si, si
    mov ah, byte ptr [bp-0eh]
    rol ah, cl
    rcl si, 1
    neg si
    mov di, si
    add si, word ptr [bp-6]
    add si, bx
    add di, word ptr [bp-0ah]
    sub di, bx
    mov byte ptr [bp-0eh], ah
    mov word ptr [bp-6], si
    mov word ptr [bp-0ah], di
    out dx, ax
    mov ch, byte ptr es:[si]
    mov byte ptr es:[si], ch
    mov ch, byte ptr es:[di]
    mov byte ptr es:[di], ch
    xor si, si
    mov ah, byte ptr [bp-10h]
    ror ah, cl
    rcl si, 1
    mov di, si
    add si, word ptr [bp-8]
    add si, bx
    add di, word ptr [bp-0ch]
    sub di, bx
    mov byte ptr [bp-10h], ah
    mov word ptr [bp-8], si
    mov word ptr [bp-0ch], di
    out dx, ax
    mov ch, byte ptr es:[si]
    mov byte ptr es:[si], ch
    mov ch, byte ptr es:[di]
    mov byte ptr es:[di], ch
    pop dx
    pop bx
    pop ax
    ret
PgPlotEllipseSymmetricPixels endp

; Multiplies an unsigned 32-bit value by a word, retaining the low 32 bits.
; Pascal: internal register helper; no stack declaration retained.
; Registers/stack: DX:AX = multiplicand, CX = multiplier; DX:AX = low 32-bit product; CX and
; flags scratch; NEAR return.
; Direct CS state: none.
PgMultiplyPartialProductsHelper proc near
    push ax
    mov ax, dx
    mul cx
    xchg cx, ax
    pop dx
    mul dx
    add dx, cx
    ret
PgMultiplyPartialProductsHelper endp

PgSpriteSkipFirstGroup              dw 0
PgSpriteSkipSecondGroup32           dw 0
PgSpriteSkipThirdGroup32             dw 0
PgSpriteSkipLastGroup            dw 0

; Clipped sprites and pixel rectangle capture.

; Applies the original horizontal byte-group skip logic to a masked 32x16 sprite.
; Pascal stack equivalent (no interface declaration): procedure
; PgBlitMasked32x16Clipped(ImageSourcePointer: Pointer; ByteColumn: Integer; PixelRow:
; Integer);
; Stack: BP+0Ah = ImageSourcePointer; BP+08h = ByteColumn; BP+06h = PixelRow; FAR return,
; callee pops 8 argument bytes.
; Registers: prologue saves BP/DS/DI/SI/CX; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage, PgSpriteSkipFirstGroup, PgSpriteSkipSecondGroup32,
; PgSpriteSkipThirdGroup32, PgSpriteSkipLastGroup.
; Original bug preserved: an in-range X falls through to the skip-flags block.
; These paths choose horizontal groups only; they do not test the Y coordinate.
PgBlitMasked32x16Clipped proc far
    push bp
    mov bp, sp
    push ds
    push di
    push si
    push cx
    mov word ptr cs:[PgSpriteSkipFirstGroup], 0
    mov word ptr cs:[PgSpriteSkipSecondGroup32], 0
    mov word ptr cs:[PgSpriteSkipThirdGroup32], 0
    mov word ptr cs:[PgSpriteSkipLastGroup], 0
    mov bx, word ptr [bp+8]
    cmp bx, -4
    jle PgClipMask32SkipAllGroups
    cmp bx, -3
    je PgClipMask32SkipFirstThree
    cmp bx, -2
    je PgClipMask32SkipFirstTwo
    cmp bx, -1
    je PgClipMask32SkipFirstGroup
    mov cx, word ptr cs:[PgScreenStrideBytes]
    cmp bx, cx
    jge PgClipMask32SkipAllGroups
    dec cx
    cmp bx, cx
    je PgClipMask32SkipLastThree
    dec cx
    cmp bx, cx
    je PgClipMask32SkipLastTwo
    dec cx
    cmp bx, cx
    je PgClipMask32SkipLastGroup
PgClipMask32SkipAllGroups:
    mov word ptr cs:[PgSpriteSkipLastGroup], 1
PgClipMask32SkipFirstThree:
    mov word ptr cs:[PgSpriteSkipThirdGroup32], 1
PgClipMask32SkipFirstTwo:
    mov word ptr cs:[PgSpriteSkipSecondGroup32], 1
PgClipMask32SkipFirstGroup:
    mov word ptr cs:[PgSpriteSkipFirstGroup], 1
    jmp short PgClipMask32SetupAddress
    nop
PgClipMask32SkipLastThree:
    mov word ptr cs:[PgSpriteSkipSecondGroup32], 1
PgClipMask32SkipLastTwo:
    mov word ptr cs:[PgSpriteSkipThirdGroup32], 1
PgClipMask32SkipLastGroup:
    mov word ptr cs:[PgSpriteSkipLastGroup], 1
PgClipMask32SetupAddress:
    pop cx
    lds si, dword ptr [bp+0ah]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+6]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov bx, word ptr [bp+8]
    add bx, ax
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgClipMask32SelectMapMask
    mov cx, ax
PgClipMask32AddPageOffset:
    add bx, PgVideoPageBytes
    loop PgClipMask32AddPageOffset
PgClipMask32SelectMapMask:
    mov dx, PgSequencerIndexPort
    mov al, 2
    out dx, al
    mov cx, 10h
PgClipMask32DrawRow:
    mov dx, PgGraphicsIndexPort
    lodsb
    mov ah, 8
    xchg ah, al
    out dx, ax
    mov dx, word ptr cs:[PgSpriteSkipFirstGroup]
    cmp dx, 1
    je PgClipMask32DiscardFirstGroup
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    jmp short PgClipMask32DrawSecondGroup
    nop
PgClipMask32DiscardFirstGroup:
    lodsb
    lodsb
    lodsb
    lodsb
PgClipMask32DrawSecondGroup:
    inc bx
    mov dx, PgGraphicsIndexPort
    lodsb
    mov ah, 8
    xchg ah, al
    out dx, ax
    mov dx, word ptr cs:[PgSpriteSkipSecondGroup32]
    cmp dx, 1
    je PgClipMask32DiscardSecondGroup
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    jmp short PgClipMask32WriteMiddleGroup
    nop
PgClipMask32DiscardSecondGroup:
    lodsb
    lodsb
    lodsb
    lodsb
    inc bx
    mov dx, PgGraphicsIndexPort
    lodsb
    mov ah, 8
    xchg ah, al
    out dx, ax
    mov dx, word ptr cs:[PgSpriteSkipThirdGroup32]
    cmp dx, 1
    je PgClipMask32DiscardThirdGroup
    mov dx, PgSequencerDataPort
    jmp short PgClipMask32WriteMiddleGroup
    nop
PgClipMask32RowLoopBridge:
    jmp near ptr PgClipMask32DrawRow
PgClipMask32WriteMiddleGroup:
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    jmp short PgClipMask32DrawLastGroup
    nop
PgClipMask32DiscardThirdGroup:
    lodsb
    lodsb
    lodsb
    lodsb
PgClipMask32DrawLastGroup:
    inc bx
    mov dx, PgGraphicsIndexPort
    lodsb
    mov ah, 8
    xchg ah, al
    out dx, ax
    mov dx, word ptr cs:[PgSpriteSkipLastGroup]
    cmp dx, 1
    je PgClipMask32DiscardLastGroup
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    jmp short PgClipMask32AdvanceRow
    nop
PgClipMask32DiscardLastGroup:
    lodsb
    lodsb
    lodsb
    lodsb
PgClipMask32AdvanceRow:
    inc bx
    add bx, word ptr cs:[PgScreenStrideBytes]
    dec bx
    dec bx
    dec bx
    dec bx
    loop PgClipMask32RowLoopBridge
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
PgBlitMasked32x16Clipped endp

; Applies the original horizontal byte-group skip logic to a masked 16x16 sprite.
; Pascal stack equivalent (no interface declaration): procedure
; PgBlitMasked16x16Clipped(ImageSourcePointer: Pointer; ByteColumn: Integer; PixelRow:
; Integer);
; Stack: BP+0Ah = ImageSourcePointer; BP+08h = ByteColumn; BP+06h = PixelRow; FAR return,
; callee pops 8 argument bytes.
; Registers: prologue saves BP/DS/DI/SI/CX; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage, PgSpriteSkipFirstGroup, PgSpriteSkipSecondGroup32,
; PgSpriteSkipThirdGroup32, PgSpriteSkipLastGroup.
; Original bug preserved: an in-range X falls through to the skip-flags block.
; These paths choose horizontal groups only; they do not test the Y coordinate.
PgBlitMasked16x16Clipped proc far
    push bp
    mov bp, sp
    push ds
    push di
    push si
    push cx
    mov word ptr cs:[PgSpriteSkipFirstGroup], 0
    mov word ptr cs:[PgSpriteSkipSecondGroup32], 0
    mov word ptr cs:[PgSpriteSkipThirdGroup32], 0
    mov word ptr cs:[PgSpriteSkipLastGroup], 0
    mov bx, word ptr [bp+8]
    cmp bx, -2
    jle PgClipMask16SkipBothGroups
    cmp bx, -1
    je PgClipMask16SkipFirstGroup
    mov cx, word ptr cs:[PgScreenStrideBytes]
    cmp bx, cx
    jge PgClipMask16SkipBothGroups
    dec cx
    cmp bx, cx
    je PgClipMask16SkipLastGroup
PgClipMask16SkipBothGroups:
    mov word ptr cs:[PgSpriteSkipLastGroup], 1
PgClipMask16SkipFirstGroup:
    mov word ptr cs:[PgSpriteSkipFirstGroup], 1
    jmp short PgClipMask16SetupAddress
    nop
PgClipMask16SkipLastGroup:
    mov word ptr cs:[PgSpriteSkipLastGroup], 1
PgClipMask16SetupAddress:
    pop cx
    lds si, dword ptr [bp+0ah]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+6]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov bx, word ptr [bp+8]
    add bx, ax
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgClipMask16SelectMapMask
    mov cx, ax
PgClipMask16AddPageOffset:
    add bx, PgVideoPageBytes
    loop PgClipMask16AddPageOffset
PgClipMask16SelectMapMask:
    mov dx, PgSequencerIndexPort
    mov al, 2
    out dx, al
    mov cx, 10h
PgClipMask16DrawRow:
    mov dx, PgGraphicsIndexPort
    lodsb
    mov ah, 8
    xchg ah, al
    out dx, ax
    mov dx, word ptr cs:[PgSpriteSkipFirstGroup]
    cmp dx, 1
    je PgClipMask16DiscardFirstGroup
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    jmp short PgClipMask16DrawLastGroup
    nop
PgClipMask16DiscardFirstGroup:
    lodsb
    lodsb
    lodsb
    lodsb
PgClipMask16DrawLastGroup:
    inc bx
    mov dx, PgGraphicsIndexPort
    lodsb
    mov ah, 8
    xchg ah, al
    out dx, ax
    mov dx, word ptr cs:[PgSpriteSkipSecondGroup32]
    cmp dx, 1
    je PgClipMask16DiscardLastGroup
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    jmp short PgClipMask16AdvanceRow
    nop
PgClipMask16DiscardLastGroup:
    lodsb
    lodsb
    lodsb
    lodsb
PgClipMask16AdvanceRow:
    inc bx
    add bx, word ptr cs:[PgScreenStrideBytes]
    dec bx
    dec bx
    loop PgClipMask16DrawRow
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
PgBlitMasked16x16Clipped endp

; Captures an inclusive pixel rectangle, shifting rows and storing the last-byte mask.
; Pascal stack equivalent (no interface declaration): procedure
; PgCapturePixelRectangle(CapturedImagePointer: Pointer; LeftPixelX: Integer; TopPixelY:
; Integer; RightPixelX: Integer; BottomPixelY: Integer);
; Stack: BP+0Eh = CapturedImagePointer; BP+0Ch = LeftPixelX; BP+0Ah = TopPixelY; BP+08h =
; RightPixelX; BP+06h = BottomPixelY; FAR return, callee pops 12 argument bytes.
; Registers: prologue saves BP/DS/SI/DI; other registers and flags may change.
; Direct CS state: PgTransferRowsRemaining, PgTransferRowBytes, PgScreenStrideBytes.
; Both endpoint pixels/rows are included. The image header stores row count before row bytes.
PgCapturePixelRectangle proc far
    push bp
    mov bp, sp
    push ds
    push si
    push di
    mov ax, word ptr [bp+8]
    sub ax, word ptr [bp+0ch]
    mov cx, 0ff07h
    and cl, al
    xor cl, 7
    shl ch, cl
    mov cl, ch
    push cx
    mov cl, 3
    shr ax, cl
    inc ax
    push ax
    mov ax, word ptr [bp+6]
    sub ax, word ptr [bp+0ah]
    inc ax
    push ax
    mov ax, word ptr [bp+0ah]
    mov bx, word ptr [bp+0ch]
    push cs
    call near ptr PgPixelAddressAndBitHelper
    xor cl, 7
    push es
    pop ds
    mov si, bx
    les di, dword ptr [bp+0eh]
    pop ax
    mov word ptr cs:[PgTransferRowsRemaining], ax
    stosw
    pop ax
    mov word ptr cs:[PgTransferRowBytes], ax
    stosw
    pop ax
    mov ch, al
    stosb
    mov dx, PgGraphicsIndexPort
    mov ax, 5
    out dx, ax
    mov ax, PgReadMapPlane3
PgPixelCaptureReadPlane:
    out dx, ax
    push ax
    push word ptr cs:[PgTransferRowsRemaining]
    push si
PgPixelCaptureReadRow:
    mov bx, word ptr cs:[PgTransferRowBytes]
    push si
PgPixelCaptureShiftByte:
    lodsw
    dec si
    rol ax, cl
    stosb
    dec bx
    jne PgPixelCaptureShiftByte
    and byte ptr es:[di-1], ch
    pop si
    add si, word ptr cs:[PgScreenStrideBytes]
    dec word ptr cs:[PgTransferRowsRemaining]
    jne PgPixelCaptureReadRow
    pop si
    pop word ptr cs:[PgTransferRowsRemaining]
    pop ax
    dec ah
    jns PgPixelCaptureReadPlane
    mov ax, di
    sub ax, word ptr [bp+0eh]
    pop di
    pop si
    pop ds
    mov sp, bp
    pop bp
    retf 0ch
PgCapturePixelRectangle endp

; Restores captured pixels at a new bit alignment using masked edge writes.
; Pascal stack equivalent (no interface declaration): procedure
; PgRestorePixelRectangle(ImageSourcePointer: Pointer; PixelX: Integer; PixelY: Integer);
; Stack: BP+0Ah = ImageSourcePointer; BP+08h = PixelX; BP+06h = PixelY; FAR return, callee
; pops 8 argument bytes.
; Registers: prologue saves BP/DS/SI/DI; other registers and flags may change.
; Direct CS state: PgTransferRowsRemaining, PgTransferRowBytes, PgRestoreRowsRemaining,
; PgRestoreFirstByteMaskPair, PgRestoreEdgeMaskPair, PgRestoreNextByteMaskPair,
; PgScreenStrideBytes.
PgRestorePixelRectangle proc far
    push bp
    mov bp, sp
    push ds
    push si
    push di
    mov ax, word ptr [bp+6]
    mov bx, word ptr [bp+8]
    push cs
    call near ptr PgPixelAddressAndBitHelper
    inc cl
    and cl, 7
    mov di, bx
    lds si, dword ptr [bp+0ah]
    lodsw
    mov word ptr cs:[PgTransferRowsRemaining], ax
    lodsw
    mov word ptr cs:[PgTransferRowBytes], ax
    lodsb
    mov ch, al
    mov dx, PgGraphicsIndexPort
    mov ah, 18h
    mov al, 3
    out dx, ax
    mov ax, PgReadMode1Pair
    out dx, ax
    mov ax, 7
    out dx, ax
    mov ax, PgBitMaskAllPixels
    out dx, ax
    mov al, 3
    mov dx, PgGraphicsIndexPort
    out dx, al
    mov al, 0
    inc dx
    out dx, al
    mov dl, 0c4h
    mov ax, PgMapMaskPlane3
    cmp cx, 0ff00h
    jne PgPxRestoreSetupShiftedMasks
    mov cx, word ptr cs:[PgTransferRowBytes]
PgPxRestoreAlignedPlane:
    out dx, ax
    push ax
    push di
    mov bx, word ptr cs:[PgTransferRowsRemaining]
PgPxRestoreAlignedRow:
    push di
    push cx
PgPxRestoreAlignedByte:
    lodsb
    and byte ptr es:[di], al
    inc di
    loop PgPxRestoreAlignedByte
    pop cx
    pop di
    add di, word ptr cs:[PgScreenStrideBytes]
    dec bx
    jne PgPxRestoreAlignedRow
    pop di
    pop ax
    shr ah, 1
    jne PgPxRestoreAlignedPlane
    jmp near ptr PgPxRestoreRestoreRegisters
PgPxRestoreSetupShiftedMasks:
    push ax
    mov bx, 0ffh
    mov al, ch
    cbw
    cmp word ptr cs:[PgTransferRowBytes], 1
    jne PgPxRestoreShiftMasks
    mov bl, ch
    mov ah, ch
    xor al, al
PgPxRestoreShiftMasks:
    shl ax, cl
    shl bx, cl
    mov bl, al
    mov al, 8
    mov word ptr cs:[PgRestoreEdgeMaskPair], ax
    mov ah, bl
    mov word ptr cs:[PgRestoreNextByteMaskPair], ax
    mov ah, bh
    mov word ptr cs:[PgRestoreFirstByteMaskPair], ax
    mov bx, word ptr cs:[PgTransferRowBytes]
    pop ax
PgPxRestoreShiftedPlane:
    out dx, ax
    push ax
    push di
    mov dl, 0ceh
    mov ax, word ptr cs:[PgTransferRowsRemaining]
    mov word ptr cs:[PgRestoreRowsRemaining], ax
PgPxRestoreShiftedRow:
    push di
    push si
    push bx
    mov ax, word ptr cs:[PgRestoreFirstByteMaskPair]
    out dx, ax
    lodsw
    dec si
    test cl, cl
    jne PgPxRestoreWriteLeadingPart
    dec bx
    jne PgPxRestoreWriteMiddleParts
    jmp short PgPxRestoreWriteTrailingParts
PgPxRestoreWriteLeadingPart:
    rol ax, cl
    and byte ptr es:[di], ah
    inc di
    dec bx
PgPxRestoreWriteMiddleParts:
    push ax
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop ax
    dec bx
    jle PgPxRestoreWriteTrailingParts
PgPxRestoreShiftMiddleByte:
    and byte ptr es:[di], al
    inc di
    lodsw
    dec si
    rol ax, cl
    dec bx
    jne PgPxRestoreShiftMiddleByte
PgPxRestoreWriteTrailingParts:
    mov bx, ax
    mov ax, word ptr cs:[PgRestoreEdgeMaskPair]
    out dx, ax
    and byte ptr es:[di], bl
    mov ax, word ptr cs:[PgRestoreNextByteMaskPair]
    out dx, ax
    and byte ptr es:[di+1], bh
    pop bx
    pop si
    add si, bx
    pop di
    add di, word ptr cs:[PgScreenStrideBytes]
    dec word ptr cs:[PgRestoreRowsRemaining]
    jne PgPxRestoreShiftedRow
    pop di
    pop ax
    mov dl, 0c4h
    shr ah, 1
    jne PgPxRestoreShiftedPlane
PgPxRestoreRestoreRegisters:
    mov ax, PgMapMaskAllPlanes
    out dx, ax
    mov dl, 0ceh
    mov ax, 3
    out dx, ax
    mov ax, 5
    out dx, ax
    mov ax, PgColorCompareAll
    out dx, ax
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop di
    pop si
    pop ds
    mov sp, bp
    pop bp
    retf 8
PgRestorePixelRectangle endp

; Shifted read-before-OR sprite drawing.

; Draws a shifted 32x16 sprite with read-before-OR writes and source masks.
; Pascal stack equivalent (no interface declaration): procedure
; PgOrShifted32x16(ImageSourcePointer: Pointer; PixelX: Integer; PixelY: Integer);
; Stack: BP+0Ah = ImageSourcePointer; BP+08h = PixelX; BP+06h = PixelY; FAR return, callee
; pops 8 argument bytes.
; Registers: prologue saves BP/DS/SI/DI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage, PgSpriteBytesRemaining,
; PgSpriteRightShift, PgSpriteLeftShift, PgSpriteSourceMask, PgSpritePlane0Byte,
; PgSpritePlane1, PgSpritePlane2, PgSpritePlane3.
PgOrShifted32x16 proc far
    push bp
    mov bp, sp
    push ds
    push si
    push di
    lds si, dword ptr [bp+0ah]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+6]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov bx, word ptr [bp+8]
    mov cl, 3
    shr bx, cl
    add bx, ax
    mov ax, word ptr [bp+8]
    and ax, 7
    mov byte ptr cs:[PgSpriteRightShift], al
    mov al, 8
    sub al, byte ptr cs:[PgSpriteRightShift]
    mov byte ptr cs:[PgSpriteLeftShift], al
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgShiftOr32SelectMapMask
    mov cx, ax
PgShiftOr32AddPageOffset:
    add bx, PgVideoPageBytes
    loop PgShiftOr32AddPageOffset
PgShiftOr32SelectMapMask:
    mov dx, PgSequencerIndexPort
    mov al, PgSeqMapMask
    out dx, al
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    mov cx, 10h
PgShiftOr32DrawRow:
    mov byte ptr cs:[PgSpriteBytesRemaining], 4
PgShiftOr32DrawByteGroup:
    mov dl, byte ptr cs:[PgSpriteBytesRemaining]
    dec dl
    mov byte ptr cs:[PgSpriteBytesRemaining], dl
    push cx
    mov dx, PgGraphicsIndexPort
    lodsb
    mov byte ptr cs:[PgSpriteSourceMask], al
    mov ah, byte ptr cs:[PgSpriteSourceMask]
    mov cl, byte ptr cs:[PgSpriteRightShift]
    shr ah, cl
    mov al, 8
    out dx, ax
    lodsb
    mov byte ptr cs:[PgSpritePlane0Byte], al
    shr al, cl
    mov di, word ptr es:[bx]
    or byte ptr es:[bx], al
    lodsb
    mov byte ptr cs:[PgSpritePlane1], al
    shr al, cl
    mov di, word ptr es:[bx]
    or byte ptr es:[bx], al
    lodsb
    mov byte ptr cs:[PgSpritePlane2], al
    shr al, cl
    mov di, word ptr es:[bx]
    or byte ptr es:[bx], al
    lodsb
    mov byte ptr cs:[PgSpritePlane3], al
    shr al, cl
    mov di, word ptr es:[bx]
    or byte ptr es:[bx], al
    jmp short PgShiftOr32WriteHighParts
    nop
PgShiftOr32RowLoopBridge:
    jmp short PgShiftOr32DrawRow
PgShiftOr32GroupLoopBridge:
    jmp short PgShiftOr32DrawByteGroup
PgShiftOr32WriteHighParts:
    inc bx
    mov dx, PgGraphicsIndexPort
    mov ah, byte ptr cs:[PgSpriteSourceMask]
    mov cl, byte ptr cs:[PgSpriteLeftShift]
    shl ah, cl
    mov al, 8
    out dx, ax
    mov al, byte ptr cs:[PgSpritePlane0Byte]
    shl al, cl
    mov di, word ptr es:[bx]
    or byte ptr es:[bx], al
    mov al, byte ptr cs:[PgSpritePlane1]
    shl al, cl
    mov di, word ptr es:[bx]
    or byte ptr es:[bx], al
    mov al, byte ptr cs:[PgSpritePlane2]
    shl al, cl
    mov di, word ptr es:[bx]
    or byte ptr es:[bx], al
    mov al, byte ptr cs:[PgSpritePlane3]
    shl al, cl
    mov di, word ptr es:[bx]
    or byte ptr es:[bx], al
    pop cx
    mov dl, byte ptr cs:[PgSpriteBytesRemaining]
    cmp dl, 0
    jg PgShiftOr32GroupLoopBridge
    add bx, word ptr cs:[PgScreenStrideBytes]
    dec bx
    dec bx
    dec bx
    dec bx
    loop PgShiftOr32RowLoopBridge
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop di
    pop si
    pop ds
    pop bp
    retf 8
PgOrShifted32x16 endp

; Draws a shifted 16x16 sprite with read-before-OR writes and source masks.
; Pascal: procedure PgOrShifted16x16(var SpriteSource; PixelX, PixelY: Integer);
; Stack: BP+06h = PixelY; BP+08h = PixelX; BP+0Ah = SpriteSource (far pointer); FAR return,
; callee pops 8 argument bytes.
; Registers: prologue saves BP/DS/SI/DI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgSpriteBytesRemaining, PgSpriteRightShift,
; PgSpriteLeftShift, PgSpriteSourceMask, PgSpritePlane0Byte, PgSpritePlane1, PgSpritePlane2,
; PgSpritePlane3.
PgOrShifted16x16 proc far
    push bp
    mov bp, sp
    push ds
    push si
    push di
    mov di, word ptr cs:[PgScreenStrideBytes]
    dec di
    dec di
    lds si, dword ptr [bp+0ah]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+6]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov bx, word ptr [bp+8]
    mov cl, 3
    shr bx, cl
    add bx, ax
    mov ax, word ptr [bp+8]
    and ax, 7
    mov byte ptr cs:[PgSpriteRightShift], al
    mov al, 8
    sub al, byte ptr cs:[PgSpriteRightShift]
    mov byte ptr cs:[PgSpriteLeftShift], al
    mov dx, PgSequencerIndexPort
    mov al, 2
    out dx, al
    mov cx, 10h
PgShiftOr16DrawRow:
    mov byte ptr cs:[PgSpriteBytesRemaining], 2
PgShiftOr16DrawByteGroup:
    mov dl, byte ptr cs:[PgSpriteBytesRemaining]
    dec dl
    mov byte ptr cs:[PgSpriteBytesRemaining], dl
    push cx
    mov dx, PgGraphicsIndexPort
    lodsb
    mov byte ptr cs:[PgSpriteSourceMask], al
    mov ah, byte ptr cs:[PgSpriteSourceMask]
    mov cl, byte ptr cs:[PgSpriteRightShift]
    shr ah, cl
    mov al, 8
    out dx, ax
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    lodsb
    mov byte ptr cs:[PgSpritePlane0Byte], al
    shr al, cl
    mov ah, byte ptr es:[bx]
    or byte ptr es:[bx], al
    mov al, 0fh
    out dx, al
    lodsb
    mov byte ptr cs:[PgSpritePlane1], al
    shr al, cl
    mov ah, byte ptr es:[bx]
    or byte ptr es:[bx], al
    mov al, 0fh
    out dx, al
    lodsb
    mov byte ptr cs:[PgSpritePlane2], al
    shr al, cl
    mov ah, byte ptr es:[bx]
    or byte ptr es:[bx], al
    mov al, 0fh
    out dx, al
    lodsb
    mov byte ptr cs:[PgSpritePlane3], al
    shr al, cl
    mov ah, byte ptr es:[bx]
    or byte ptr es:[bx], al
    jmp short PgShiftOr16WriteHighParts
    nop
PgShiftOr16RowLoopBridge:
    jmp short PgShiftOr16DrawRow
PgShiftOr16GroupLoopBridge:
    jmp short PgShiftOr16DrawByteGroup
PgShiftOr16WriteHighParts:
    inc bx
    mov dx, PgGraphicsIndexPort
    mov ah, byte ptr cs:[PgSpriteSourceMask]
    mov cl, byte ptr cs:[PgSpriteLeftShift]
    shl ah, cl
    mov al, 8
    out dx, ax
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    mov al, byte ptr cs:[PgSpritePlane0Byte]
    shl al, cl
    mov ah, byte ptr es:[bx]
    or byte ptr es:[bx], al
    mov al, 0fh
    out dx, al
    mov al, byte ptr cs:[PgSpritePlane1]
    shl al, cl
    mov ah, byte ptr es:[bx]
    or byte ptr es:[bx], al
    mov al, 0fh
    out dx, al
    mov al, byte ptr cs:[PgSpritePlane2]
    shl al, cl
    mov ah, byte ptr es:[bx]
    or byte ptr es:[bx], al
    mov al, 0fh
    out dx, al
    mov al, byte ptr cs:[PgSpritePlane3]
    shl al, cl
    mov ah, byte ptr es:[bx]
    or byte ptr es:[bx], al
    pop cx
    mov dl, byte ptr cs:[PgSpriteBytesRemaining]
    cmp dl, 0
    jg PgShiftOr16GroupLoopBridge
    add bx, di
    loop PgShiftOr16RowLoopBridge
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop di
    pop si
    pop ds
    pop bp
    retf 8
PgOrShifted16x16 endp

; Draws a shifted 8x8 sprite with read-before-OR writes.
; Pascal stack equivalent (no interface declaration): procedure
; PgOrShifted8x8(ImageSourcePointer: Pointer; PixelX: Integer; PixelY: Integer);
; Stack: BP+0Ah = ImageSourcePointer; BP+08h = PixelX; BP+06h = PixelY; FAR return, callee
; pops 8 argument bytes.
; Registers: prologue saves BP/DS/DI/SI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage, PgGlyphMaskHigh, PgGlyphMaskLow,
; PgGlyphLeftShift.
PgOrShifted8x8 proc far
    push bp
    mov bp, sp
    push ds
    push di
    push si
    lds si, dword ptr [bp+0ah]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+6]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov cx, word ptr [bp+8]
    and cx, 7
    xor cl, 7
    inc cl
    mov byte ptr cs:[PgGlyphLeftShift], cl
    mov bx, word ptr [bp+8]
    shr bx, 1
    shr bx, 1
    shr bx, 1
    add bx, ax
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgShiftOr8SelectMapMask
    mov cx, ax
PgShiftOr8AddPageOffset:
    add bx, PgVideoPageBytes
    loop PgShiftOr8AddPageOffset
PgShiftOr8SelectMapMask:
    mov dx, PgSequencerIndexPort
    mov al, 2
    out dx, al
    mov cx, 8
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
PgShiftOr8DrawRow:
    push cx
    lodsb
    mov ah, 0
    mov cl, byte ptr cs:[PgGlyphLeftShift]
    rol ax, cl
    mov byte ptr cs:[PgGlyphMaskHigh], ah
    mov byte ptr cs:[PgGlyphMaskLow], al
    lodsb
    mov ah, 0
    mov cl, byte ptr cs:[PgGlyphLeftShift]
    rol ax, cl
    mov cx, ax
    mov dx, PgGraphicsIndexPort
    mov al, 8
    mov ah, byte ptr cs:[PgGlyphMaskHigh]
    out dx, ax
    mov di, word ptr es:[bx]
    or byte ptr es:[bx], ch
    mov ah, byte ptr cs:[PgGlyphMaskLow]
    out dx, ax
    mov di, word ptr es:[bx+1]
    or byte ptr es:[bx+1], cl
    lodsb
    mov ah, 0
    mov cl, byte ptr cs:[PgGlyphLeftShift]
    rol ax, cl
    mov cx, ax
    mov dx, PgGraphicsIndexPort
    mov al, 8
    mov ah, byte ptr cs:[PgGlyphMaskHigh]
    out dx, ax
    mov di, word ptr es:[bx]
    or byte ptr es:[bx], ch
    mov ah, byte ptr cs:[PgGlyphMaskLow]
    out dx, ax
    mov di, word ptr es:[bx+1]
    or byte ptr es:[bx+1], cl
    jmp short PgShiftOr8WriteHighParts
    nop
PgShiftOr8RowLoopBridge:
    jmp short PgShiftOr8DrawRow
PgShiftOr8WriteHighParts:
    lodsb
    mov ah, 0
    mov cl, byte ptr cs:[PgGlyphLeftShift]
    rol ax, cl
    mov cx, ax
    mov dx, PgGraphicsIndexPort
    mov al, 8
    mov ah, byte ptr cs:[PgGlyphMaskHigh]
    out dx, ax
    mov di, word ptr es:[bx]
    or byte ptr es:[bx], ch
    mov ah, byte ptr cs:[PgGlyphMaskLow]
    out dx, ax
    mov di, word ptr es:[bx+1]
    or byte ptr es:[bx+1], cl
    lodsb
    mov ah, 0
    mov cl, byte ptr cs:[PgGlyphLeftShift]
    rol ax, cl
    mov cx, ax
    mov dx, PgGraphicsIndexPort
    mov al, 8
    mov ah, byte ptr cs:[PgGlyphMaskHigh]
    out dx, ax
    mov di, word ptr es:[bx]
    or byte ptr es:[bx], ch
    mov ah, byte ptr cs:[PgGlyphMaskLow]
    out dx, ax
    mov di, word ptr es:[bx+1]
    or byte ptr es:[bx+1], cl
    add bx, word ptr cs:[PgScreenStrideBytes]
    pop cx
    loop PgShiftOr8RowLoopBridge
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
PgOrShifted8x8 endp

PgFontOffset                    dw ?
PgFontSegment                   dw ?
PgFontHeight                    dw ?
; Unused storage retains the original object layout.
UnusedPgFontDefaultOffset       dw 0
; Unused storage retains the original object layout.
UnusedPgFontDefaultHeight       dw 8
PgRom8Offset                    dw ?
PgRom8Segment                   dw ?
PgRom8Height                    dw 8
PgRom14Offset                   dw ?
PgRom14Segment                  dw ?
PgRom14Height                   dw 14
; Unused storage retains the original object layout.
UnusedPgFontWord                dw ?
PgTextDirection                 dw 0

; ROM font text output.

; Draws a Pascal short string with the selected ROM font and orientation.
; Pascal stack equivalent (no interface declaration): procedure
; PgDrawPascalString(PascalTextPointer: Pointer; TextPixelX: Integer; TextPixelY: Integer);
; Stack: BP+0Ch = PascalTextPointer; BP+0Ah = TextPixelX; BP+08h = TextPixelY; FAR return,
; callee pops 8 argument bytes.
; Registers: prologue saves DS/BP/DI/SI; other registers and flags may change.
; Direct CS state: PgTextX, PgTextY, PgTextCsBase, PgFontRowCount, PgGlyphOffset,
; PgGlyphSegment, PgFontRowIndex, PgTextCharIndex, PgTextCharCode, PgFontOffset,
; PgFontSegment, PgFontHeight, PgTextDirection.
; PUSH DS precedes the BP frame, so stack arguments start at BP+8. The call/pop label derives
; the table-address adjustment.
PgDrawPascalString proc far
    push ds
    push bp
    mov bp, sp
    sub sp, 4
    push di
    push si
    call near ptr PgTextLocateCodeBase
PgTextLocateCodeBase:
    pop ax
    sub ax, offset PgTextLocateCodeBase
    mov word ptr cs:[PgTextCsBase], ax
    mov word ptr cs:[PgTextCharIndex], 0
PgTextNextCharacter:
    inc word ptr cs:[PgTextCharIndex]
    les bx, dword ptr [bp+0ch]
    mov al, byte ptr es:[bx]
    xor ah, ah
    cmp word ptr cs:[PgTextCharIndex], ax
    jbe PgTextSetupGlyph
    jmp near ptr PgTextRestoreRegisters
PgTextSetupGlyph:
    add bx, word ptr cs:[PgTextCharIndex]
    mov al, byte ptr es:[bx]
    xor ah, ah
    mov word ptr cs:[PgTextCharCode], ax
    mov ax, word ptr cs:[PgFontHeight]
    mov word ptr cs:[PgFontRowCount], ax
    mul word ptr cs:[PgTextCharCode]
    mov si, word ptr cs:[PgFontOffset]
    mov bx, word ptr cs:[PgFontSegment]
    push bx
    pop ds
    add si, ax
    mov word ptr cs:[PgGlyphOffset], si
    mov word ptr cs:[PgGlyphSegment], ds
    mov word ptr cs:[PgFontRowIndex], 1
PgTextDrawGlyphRow:
    mov ax, word ptr [bp+0ah]
    mov word ptr cs:[PgTextX], ax
    mov ax, word ptr [bp+8]
    mov word ptr cs:[PgTextY], ax
    lds si, dword ptr cs:[PgGlyphOffset]
    inc word ptr cs:[PgGlyphOffset]
    mov dl, byte ptr [si]
    xor dh, dh
    mov ax, word ptr cs:[PgTextDirection]
    cmp ax, 0
    jne PgTextDrawVerticalRow
    call near ptr PgDrawFontRowHorizontalHelper
    inc word ptr [bp+8]
    jmp short PgTextNextGlyphRow
PgTextDrawVerticalRow:
    call near ptr PgDrawFontRowVerticalHelper
    mov ax, word ptr cs:[PgTextDirection]
    cmp ax, 1
    jne PgTextStepNegativeX
    inc word ptr [bp+0ah]
    jmp short PgTextNextGlyphRow
PgTextStepNegativeX:
    dec word ptr [bp+0ah]
PgTextNextGlyphRow:
    inc word ptr cs:[PgFontRowIndex]
    mov ax, word ptr cs:[PgFontRowIndex]
    cmp ax, word ptr cs:[PgFontRowCount]
    ja PgTextAdvanceCharacter
    jmp short PgTextDrawGlyphRow
PgTextAdvanceCharacter:
    mov ax, word ptr cs:[PgTextDirection]
    mov bx, 8
    mov cx, word ptr cs:[PgFontRowCount]
    cmp ax, 0
    jne PgTextAdvanceVerticalChar
    add word ptr [bp+0ah], bx
    sub word ptr [bp+8], cx
    jmp near ptr PgTextNextCharacter
PgTextAdvanceVerticalChar:
    cmp ax, 1
    jne PgTextAdvanceOtherVerticalChar
    sub word ptr [bp+8], bx
    sub word ptr [bp+0ah], cx
    jmp near ptr PgTextNextCharacter
PgTextAdvanceOtherVerticalChar:
    add word ptr [bp+8], bx
    add word ptr [bp+0ah], cx
    jmp near ptr PgTextNextCharacter
PgTextRestoreRegisters:
    pop si
    pop di
    mov sp, bp
    pop bp
    pop ds
    retf 8
PgDrawPascalString endp

; Queries BIOS pointers to the 8-row and 14-row ROM font tables.
; Pascal: procedure PgInitializeRomFonts;
; Stack: FAR return, callee pops 0 argument bytes.
; Registers: prologue saves BP/DI/SI/DS/ES; other registers and flags may change.
; Direct CS state: PgRom8Offset, PgRom8Segment, PgRom8Height, PgRom14Offset, PgRom14Segment,
; PgRom14Height.
PgInitializeRomFonts proc far
    push bp
    mov bp, sp
    push di
    push si
    push ds
    push es
    push cs
    pop ds
    push bp
    mov ax, 1130h
    mov bx, 200h
    int PgBiosVideoInterrupt
    mov ax, bp
    pop bp
    mov word ptr cs:[PgRom14Offset], ax
    mov word ptr cs:[PgRom14Segment], es
    mov word ptr cs:[PgRom14Height], 0eh
    push bp
    mov ax, 1130h
    mov bx, 300h
    int PgBiosVideoInterrupt
    mov ax, bp
    pop bp
    mov word ptr cs:[PgRom8Offset], ax
    mov word ptr cs:[PgRom8Segment], es
    mov word ptr cs:[PgRom8Height], 8
    pop es
    pop ds
    pop si
    pop di
    pop bp
    retf
PgInitializeRomFonts endp

; Rotates a glyph row and writes the left/right byte masks.
; Pascal: internal register helper; no stack declaration retained.
; Registers/stack: DL = glyph bits; text origin comes from CS. AX/BX/CX/DX/SI/DI/ES and flags
; scratch; NEAR return.
; Direct CS state: PgTextX, PgTextY, PgFontPixelX, PgFontPixelY, PgTextCsBase,
; PgGlyphLeftByteMask, PgGlyphRightByteMask, PgLeftMasks, PgDrawColor, PgDrawOperation.
PgDrawFontRowHorizontalHelper proc near
    mov ax, word ptr cs:[PgTextX]
    and ax, 7
    mov si, ax
    mov cx, ax
    ror dl, cl
    xor dh, dh
    add si, word ptr cs:[PgTextCsBase]
    mov al, byte ptr cs:[si+PgLeftMasks]
    mov cx, ax
    and cx, dx
    mov word ptr cs:[PgGlyphLeftByteMask], cx
    not ax
    and ax, dx
    mov word ptr cs:[PgGlyphRightByteMask], ax
    mov ax, word ptr cs:[PgTextX]
    mov word ptr cs:[PgFontPixelX], ax
    mov ax, word ptr cs:[PgTextY]
    mov word ptr cs:[PgFontPixelY], ax
    call near ptr PgFontPixelAddressHelper
    mov ax, word ptr cs:[PgDrawColor]
    mov bx, 0fh
    call near ptr PgSetEgaSetResetHelper
    mov al, byte ptr cs:[PgDrawOperation]
    mov ah, 0
    call near ptr PgSetEgaDataRotateHelper
    mov ax, word ptr cs:[PgGlyphLeftByteMask]
    call near ptr PgSetEgaBitMaskHelper
    mov al, byte ptr es:[di]
    mov byte ptr es:[di], al
    inc di
    mov ax, word ptr cs:[PgGlyphRightByteMask]
    call near ptr PgSetEgaBitMaskHelper
    mov al, byte ptr es:[di]
    mov byte ptr es:[di], al
    mov ax, 0ffh
    call near ptr PgSetEgaBitMaskHelper
    xor ax, ax
    xor bx, bx
    call near ptr PgSetEgaSetResetHelper
    xor ax, ax
    call near ptr PgSetEgaDataRotateHelper
    ret
PgDrawFontRowHorizontalHelper endp

; Plots the eight glyph-row bits along a vertical text direction.
; Pascal: internal register helper; no stack declaration retained.
; Registers/stack: DX = glyph bits; origin/direction come from CS. AX/BX/CX/SI/DI/ES and flags
; scratch; DX saved around pixel calls; NEAR return.
; Direct CS state: PgTextX, PgTextY, PgFontPixelX, PgFontPixelY, PgTextDirection.
PgDrawFontRowVerticalHelper proc near
    mov ax, word ptr cs:[PgTextX]
    mov word ptr cs:[PgFontPixelX], ax
    mov ax, word ptr cs:[PgTextY]
    add ax, 8
    mov word ptr cs:[PgFontPixelY], ax
    mov cx, 8
    mov bx, 80h
PgVerticalFontTestGlyphBit:
    mov ax, dx
    and ax, bx
    je PgVerticalFontStepPixel
    push dx
    push bx
    push cx
    call near ptr PgDrawFontPixelHelper
    pop cx
    pop bx
    pop dx
PgVerticalFontStepPixel:
    shr bx, 1
    cmp word ptr cs:[PgTextDirection], 1
    jne PgVerticalFontStepPositiveY
    dec word ptr cs:[PgFontPixelY]
    jmp short PgVerticalFontNextGlyphBit
PgVerticalFontStepPositiveY:
    inc word ptr cs:[PgFontPixelY]
PgVerticalFontNextGlyphBit:
    loop PgVerticalFontTestGlyphBit
    ret
PgDrawFontRowVerticalHelper endp

; Writes AL to the graphics-controller bit-mask register.
; Pascal: internal register helper; no stack declaration retained.
; Registers/stack: AL = pixel bit mask; AX/DX scratch, flags unchanged by this helper; NEAR
; return.
; Direct CS state: none.
PgSetEgaBitMaskHelper proc near
    mov ah, al
    mov al, PgGcBitMask
    mov dx, PgGraphicsIndexPort
    out dx, ax
    ret
PgSetEgaBitMaskHelper endp

; Writes AL as set/reset color and BL as its enabled-plane mask.
; Pascal: internal register helper; no stack declaration retained.
; Registers/stack: AL = color, BL = enabled planes; AX/DX scratch, flags unchanged by this
; helper; NEAR return.
; Direct CS state: none.
PgSetEgaSetResetHelper proc near
    mov ah, al
    mov al, PgGcSetReset
    mov dx, PgGraphicsIndexPort
    out dx, ax
    mov ah, bl
    mov al, PgGcEnableSetReset
    out dx, ax
    ret
PgSetEgaSetResetHelper endp

; Writes AL to the graphics-controller data-rotate register.
; Pascal: internal register helper; no stack declaration retained.
; Registers/stack: AL = data rotate/logical operation; AX/DX scratch, flags unchanged by this
; helper; NEAR return.
; Direct CS state: none.
PgSetEgaDataRotateHelper proc near
    mov ah, al
    mov al, PgGcDataRotate
    mov dx, PgGraphicsIndexPort
    out dx, ax
    ret
PgSetEgaDataRotateHelper endp

; Computes the font pixel byte address from CS coordinates and draw page.
; Pascal: internal register helper; no stack declaration retained.
; Registers/stack: Coordinates come from CS; ES:DI = font pixel byte address. AX/BX/CX/DX and
; flags scratch; NEAR return.
; Direct CS state: PgFontPixelX, PgFontPixelY, PgScreenStrideBytes, PgDrawPage.
PgFontPixelAddressHelper proc near
    mov ax, word ptr cs:[PgFontPixelY]
    mov cx, word ptr cs:[PgScreenStrideBytes]
    mul cx
    mov bx, word ptr cs:[PgFontPixelX]
    mov cx, 3
    shr bx, cl
    add ax, bx
    mov di, ax
    mov cx, word ptr cs:[PgDrawPage]
    mov ax, PgVideoSegment
    cmp cx, 0
    je PgFontAddrReturnAddress
PgFontAddrAddPageSegment:
    add ax, 2000h
    loop PgFontAddrAddPageSegment
PgFontAddrReturnAddress:
    mov es, ax
    ret
PgFontPixelAddressHelper endp

; Writes one font pixel with the current draw color and operation.
; Pascal: internal register helper; no stack declaration retained.
; Registers/stack: Coordinates come from CS; AX/BX/CX/DX/DI/ES and flags scratch; NEAR return.
; Direct CS state: PgFontPixelX, PgTextCsBase, PgPixelMasks, PgDrawColor, PgDrawOperation.
PgDrawFontPixelHelper proc near
    call near ptr PgFontPixelAddressHelper
    mov ax, word ptr cs:[PgFontPixelX]
    and ax, 7
    mov bx, word ptr cs:[PgTextCsBase]
    add bx, ax
    mov ah, byte ptr cs:[bx+PgPixelMasks]
    mov al, 8
    mov dx, PgGraphicsIndexPort
    out dx, ax
    mov al, byte ptr cs:[PgDrawOperation]
    mov ah, 0
    mov ah, al
    mov al, 3
    out dx, ax
    mov ax, word ptr cs:[PgDrawColor]
    mov bx, 0fh
    call near ptr PgSetEgaSetResetHelper
    mov ch, byte ptr es:[di]
    mov byte ptr es:[di], 0ffh
    xor ax, ax
    call near ptr PgSetEgaDataRotateHelper
    xor ax, ax
    xor bx, bx
    call near ptr PgSetEgaSetResetHelper
    mov ax, 0ffh
    call near ptr PgSetEgaBitMaskHelper
    ret
PgDrawFontPixelHelper endp

; Selects the 8-row ROM font for index 1; every other index selects 14 rows.
; Pascal: procedure PgSelectRomFont(FontIndex: Word);
; Stack: BP+06h = FontIndex; FAR return, callee pops 2 argument bytes.
; Registers: prologue saves BP; other registers and flags may change.
; Direct CS state: PgFontOffset, PgFontSegment, PgFontHeight, PgRom8Offset, PgRom8Segment,
; PgRom8Height, PgRom14Offset, PgRom14Segment, PgRom14Height.
PgSelectRomFont proc far
    push bp
    mov bp, sp
    mov ax, word ptr [bp+6]
    cmp ax, 1
    je PgFontSelectUseEightRowFont
    mov ax, word ptr cs:[PgRom14Offset]
    mov word ptr cs:[PgFontOffset], ax
    mov ax, word ptr cs:[PgRom14Segment]
    mov word ptr cs:[PgFontSegment], ax
    mov ax, word ptr cs:[PgRom14Height]
    mov word ptr cs:[PgFontHeight], ax
    jmp short PgFontSelectReturn
    nop
PgFontSelectUseEightRowFont:
    mov ax, word ptr cs:[PgRom8Offset]
    mov word ptr cs:[PgFontOffset], ax
    mov ax, word ptr cs:[PgRom8Segment]
    mov word ptr cs:[PgFontSegment], ax
    mov ax, word ptr cs:[PgRom8Height]
    mov word ptr cs:[PgFontHeight], ax
PgFontSelectReturn:
    pop bp
    retf 2
PgSelectRomFont endp

; Opaque fixed-size sprite drawing.

; Overwrites four planes with a byte-aligned 32x16 sprite.
; Pascal stack equivalent (no interface declaration): procedure
; PgBlitOpaque32x16(ImageSourcePointer: Pointer; ByteColumn: Integer; PixelRow: Integer);
; Stack: BP+0Ah = ImageSourcePointer; BP+08h = ByteColumn; BP+06h = PixelRow; FAR return,
; callee pops 8 argument bytes.
; Registers: prologue saves BP/DS/DI/SI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage.
PgBlitOpaque32x16 proc far
    push bp
    mov bp, sp
    push ds
    push di
    push si
    mov di, word ptr cs:[PgScreenStrideBytes]
    dec di
    dec di
    dec di
    dec di
    lds si, dword ptr [bp+0ah]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+6]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov bx, word ptr [bp+8]
    add bx, ax
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgOpaque32SelectMapMask
    mov cx, ax
PgOpaque32AddPageOffset:
    add bx, PgVideoPageBytes
    loop PgOpaque32AddPageOffset
PgOpaque32SelectMapMask:
    mov dx, PgSequencerIndexPort
    mov al, 2
    out dx, al
    mov cx, 10h
PgOpaque32DrawRow:
    lodsb
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    inc bx
    lodsb
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    jmp short PgOpaque32DrawRightHalf
    nop
PgOpaque32RowLoopBridge:
    jmp short PgOpaque32DrawRow
PgOpaque32DrawRightHalf:
    inc bx
    lodsb
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    inc bx
    lodsb
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    inc bx
    add bx, di
    loop PgOpaque32RowLoopBridge
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
PgBlitOpaque32x16 endp

; Overwrites four planes with a byte-aligned 16x16 sprite.
; Pascal: procedure PgBlitOpaque16x16(var ImageSource; ByteColumn, PixelRow: Integer);
; Stack: BP+06h = PixelRow; BP+08h = ByteColumn; BP+0Ah = ImageSource (far pointer); FAR
; return, callee pops 8 argument bytes.
; Registers: prologue saves BP/DS/DI/SI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage.
PgBlitOpaque16x16 proc far
    push bp
    mov bp, sp
    push ds
    push di
    push si
    mov di, word ptr cs:[PgScreenStrideBytes]
    dec di
    dec di
    lds si, dword ptr [bp+0ah]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+6]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov bx, word ptr [bp+8]
    add bx, ax
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgOpaque16SelectMapMask
    mov cx, ax
PgOpaque16AddPageOffset:
    add bx, PgVideoPageBytes
    loop PgOpaque16AddPageOffset
PgOpaque16SelectMapMask:
    mov dx, PgSequencerIndexPort
    mov al, 2
    out dx, al
    mov cx, 10h
PgOpaque16DrawRow:
    lodsb
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    inc bx
    lodsb
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    inc bx
    add bx, di
    loop PgOpaque16DrawRow
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
PgBlitOpaque16x16 endp

; Overwrites four planes with a byte-aligned 8x8 sprite.
; Pascal: procedure PgBlitOpaque8x8(var ImageSource; ByteColumn, PixelRow: Integer);
; Stack: BP+06h = PixelRow; BP+08h = ByteColumn; BP+0Ah = ImageSource (far pointer); FAR
; return, callee pops 8 argument bytes.
; Registers: prologue saves BP/DS/DI/SI; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage.
; Original nonzero draw-page branch uses entry AX as its loop count; preserved for exactness.
PgBlitOpaque8x8 proc far
    push bp
    mov bp, sp
    push ds
    push di
    push si
    mov di, word ptr cs:[PgScreenStrideBytes]
    lds si, dword ptr [bp+0ah]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+8]
    mov dx, word ptr cs:[PgDrawPage]
    cmp dl, 0
    je PgOpaque8SelectMapMask
    mov cx, ax
PgOpaque8AddPageOffset:
    add bx, PgVideoPageBytes
    loop PgOpaque8AddPageOffset
PgOpaque8SelectMapMask:
    mov dx, word ptr [bp+6]
    push di
    push ax
    mov ax, dx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    add bx, ax
    mov dx, PgSequencerIndexPort
    mov al, 2
    out dx, al
    mov cx, 8
PgOpaque8DrawRow:
    lodsb
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    add bx, di
    loop PgOpaque8DrawRow
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
PgBlitOpaque8x8 endp

; Applies the original horizontal byte-group skip logic to an opaque 32x16 sprite.
; Pascal stack equivalent (no interface declaration): procedure
; PgBlitOpaque32x16Clipped(ImageSourcePointer: Pointer; ByteColumn: Integer; PixelRow:
; Integer);
; Stack: BP+0Ah = ImageSourcePointer; BP+08h = ByteColumn; BP+06h = PixelRow; FAR return,
; callee pops 8 argument bytes.
; Registers: prologue saves BP/DS/DI/SI/CX; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage, PgSpriteSkipFirstGroup, PgSpriteSkipSecondGroup32,
; PgSpriteSkipThirdGroup32, PgSpriteSkipLastGroup.
; Original bug preserved: an in-range X falls through to the skip-flags block.
; These paths choose horizontal groups only; they do not test the Y coordinate.
PgBlitOpaque32x16Clipped proc far
    push bp
    mov bp, sp
    push ds
    push di
    push si
    push cx
    mov word ptr cs:[PgSpriteSkipFirstGroup], 0
    mov word ptr cs:[PgSpriteSkipSecondGroup32], 0
    mov word ptr cs:[PgSpriteSkipThirdGroup32], 0
    mov word ptr cs:[PgSpriteSkipLastGroup], 0
    mov bx, word ptr [bp+8]
    cmp bx, -4
    jle PgClipOp32SkipAllGroups
    cmp bx, -3
    je PgClipOp32SkipFirstThree
    cmp bx, -2
    je PgClipOp32SkipFirstTwo
    cmp bx, -1
    je PgClipOp32SkipFirstGroup
    mov cx, word ptr cs:[PgScreenStrideBytes]
    cmp bx, cx
    jge PgClipOp32SkipAllGroups
    dec cx
    cmp bx, cx
    je PgClipOp32SkipLastThree
    dec cx
    cmp bx, cx
    je PgClipOp32SkipLastTwo
    dec cx
    cmp bx, cx
    je PgClipOp32SkipLastGroup
PgClipOp32SkipAllGroups:
    mov word ptr cs:[PgSpriteSkipLastGroup], 1
PgClipOp32SkipFirstThree:
    mov word ptr cs:[PgSpriteSkipThirdGroup32], 1
PgClipOp32SkipFirstTwo:
    mov word ptr cs:[PgSpriteSkipSecondGroup32], 1
PgClipOp32SkipFirstGroup:
    mov word ptr cs:[PgSpriteSkipFirstGroup], 1
    jmp short PgClipOp32SetupAddress
    nop
PgClipOp32SkipLastThree:
    mov word ptr cs:[PgSpriteSkipSecondGroup32], 1
PgClipOp32SkipLastTwo:
    mov word ptr cs:[PgSpriteSkipThirdGroup32], 1
PgClipOp32SkipLastGroup:
    mov word ptr cs:[PgSpriteSkipLastGroup], 1
PgClipOp32SetupAddress:
    pop cx
    lds si, dword ptr [bp+0ah]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+6]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov bx, word ptr [bp+8]
    add bx, ax
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgClipOp32SelectMapMask
    mov cx, ax
PgClipOp32AddPageOffset:
    add bx, PgVideoPageBytes
    loop PgClipOp32AddPageOffset
PgClipOp32SelectMapMask:
    mov dx, PgSequencerIndexPort
    mov al, 2
    out dx, al
    mov cx, 10h
PgClipOp32DrawRow:
    lodsb
    mov dx, word ptr cs:[PgSpriteSkipFirstGroup]
    cmp dx, 1
    je PgClipOp32DiscardFirstGroup
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    jmp near ptr PgClipMask32DrawSecondGroup
PgClipOp32DiscardFirstGroup:
    lodsb
    lodsb
    lodsb
    lodsb
    inc bx
    lodsb
    mov dx, word ptr cs:[PgSpriteSkipSecondGroup32]
    cmp dx, 1
    je PgClipOp32DiscardSecondGroup
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    jmp short PgClipOp32WriteMiddleGroup
    nop
PgClipOp32DiscardSecondGroup:
    lodsb
    lodsb
    lodsb
    lodsb
    inc bx
    lodsb
    mov dx, word ptr cs:[PgSpriteSkipThirdGroup32]
    cmp dx, 1
    je PgClipOp32DiscardThirdGroup
    mov dx, PgSequencerDataPort
    jmp short PgClipOp32WriteMiddleGroup
    nop
PgClipOp32RowLoopBridge:
    jmp short PgClipOp32DrawRow
PgClipOp32WriteMiddleGroup:
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    jmp near ptr PgClipMask32DrawLastGroup
PgClipOp32DiscardThirdGroup:
    lodsb
    lodsb
    lodsb
    lodsb
    inc bx
    lodsb
    mov dx, word ptr cs:[PgSpriteSkipLastGroup]
    cmp dx, 1
    je PgClipOp32DiscardLastGroup
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    jmp short PgClipOp32AdvanceRow
    nop
PgClipOp32DiscardLastGroup:
    lodsb
    lodsb
    lodsb
    lodsb
PgClipOp32AdvanceRow:
    inc bx
    add bx, word ptr cs:[PgScreenStrideBytes]
    dec bx
    dec bx
    dec bx
    dec bx
    loop PgClipOp32RowLoopBridge
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
PgBlitOpaque32x16Clipped endp

; Applies the original horizontal byte-group skip logic to an opaque 16x16 sprite.
; Pascal stack equivalent (no interface declaration): procedure
; PgBlitOpaque16x16Clipped(ImageSourcePointer: Pointer; ByteColumn: Integer; PixelRow:
; Integer);
; Stack: BP+0Ah = ImageSourcePointer; BP+08h = ByteColumn; BP+06h = PixelRow; FAR return,
; callee pops 8 argument bytes.
; Registers: prologue saves BP/DS/DI/SI/CX; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes, PgDrawPage, PgSpriteSkipFirstGroup, PgSpriteSkipSecondGroup32,
; PgSpriteSkipThirdGroup32, PgSpriteSkipLastGroup.
; Original bug preserved: an in-range X falls through to the skip-flags block.
; These paths choose horizontal groups only; they do not test the Y coordinate.
PgBlitOpaque16x16Clipped proc far
    push bp
    mov bp, sp
    push ds
    push di
    push si
    push cx
    mov word ptr cs:[PgSpriteSkipFirstGroup], 0
    mov word ptr cs:[PgSpriteSkipSecondGroup32], 0
    mov word ptr cs:[PgSpriteSkipThirdGroup32], 0
    mov word ptr cs:[PgSpriteSkipLastGroup], 0
    mov bx, word ptr [bp+8]
    cmp bx, -2
    jle PgClipOp16SkipBothGroups
    cmp bx, -1
    je PgClipOp16SkipFirstGroup
    mov cx, word ptr cs:[PgScreenStrideBytes]
    cmp bx, cx
    jge PgClipOp16SkipBothGroups
    dec cx
    cmp bx, cx
    je PgClipOp16SkipLastGroup
PgClipOp16SkipBothGroups:
    mov word ptr cs:[PgSpriteSkipLastGroup], 1
PgClipOp16SkipFirstGroup:
    mov word ptr cs:[PgSpriteSkipFirstGroup], 1
    jmp short PgClipOp16SetupAddress
    nop
PgClipOp16SkipLastGroup:
    mov word ptr cs:[PgSpriteSkipLastGroup], 1
PgClipOp16SetupAddress:
    pop cx
    lds si, dword ptr [bp+0ah]
    mov dx, PgVideoSegment
    mov es, dx
    mov bx, word ptr [bp+6]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov bx, word ptr [bp+8]
    add bx, ax
    mov ax, word ptr cs:[PgDrawPage]
    cmp al, 0
    je PgClipOp16SelectMapMask
    mov cx, ax
PgClipOp16AddPageOffset:
    add bx, PgVideoPageBytes
    loop PgClipOp16AddPageOffset
PgClipOp16SelectMapMask:
    mov dx, PgSequencerIndexPort
    mov al, 2
    out dx, al
    mov cx, 10h
PgClipOp16DrawRow:
    lodsb
    mov dx, word ptr cs:[PgSpriteSkipFirstGroup]
    cmp dx, 1
    je PgClipOp16DiscardFirstGroup
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    jmp short PgClipOp16DrawLastGroup
    nop
PgClipOp16DiscardFirstGroup:
    lodsb
    lodsb
    lodsb
    lodsb
PgClipOp16DrawLastGroup:
    inc bx
    lodsb
    mov dx, word ptr cs:[PgSpriteSkipSecondGroup32]
    cmp dx, 1
    je PgClipOp16DiscardLastGroup
    mov dx, PgSequencerDataPort
    mov al, 1
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 2
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 4
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    mov al, 8
    out dx, al
    lodsb
    xchg byte ptr es:[bx], al
    jmp short PgClipOp16AdvanceRow
    nop
PgClipOp16DiscardLastGroup:
    lodsb
    lodsb
    lodsb
    lodsb
PgClipOp16AdvanceRow:
    inc bx
    add bx, word ptr cs:[PgScreenStrideBytes]
    dec bx
    dec bx
    loop PgClipOp16DrawRow
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov ax, PgBitMaskAllPixels
    out dx, ax
    pop si
    pop di
    pop ds
    pop bp
    retf 8
PgBlitOpaque16x16Clipped endp

; Cached tiles and video-buffer copies.

; Copies a 16x16 tile from the FA00h VRAM cache using EGA latches.
; Pascal: procedure PgCopyCachedVideoTile16x16(ByteColumn, PixelRow, CachedTileIndex:
; Integer);
; Stack: BP+06h = CachedTileIndex; BP+08h = PixelRow; BP+0Ah = ByteColumn; FAR return, callee
; pops 6 argument bytes.
; Registers: prologue saves BP/SI/DI/DS; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes.
PgCopyCachedVideoTile16x16 proc far
    push bp
    mov bp, sp
    push si
    push di
    push ds
    mov dx, PgVideoSegment
    mov es, dx
    mov ds, dx
    mov si, word ptr [bp+6]
    shl si, 1
    or si, PgCachedTilesOffset
    mov bx, word ptr [bp+8]
    push di
    push ax
    mov ax, bx
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, ax
    pop ax
    mov ax, di
    pop di
    mov di, word ptr [bp+0ah]
    add di, ax
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov al, 5
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    mov cx, 1
    mov dl, 10h
    mov ax, word ptr cs:[PgScreenStrideBytes]
    dec ax
    dec ax
PgCacheTileCopyRow:
    movsb
    movsb
    add si, ax
    add di, ax
    dec dl
    cmp dl, 0
    jg PgCacheTileCopyRow
    mov dx, PgGraphicsDataPort
    mov al, 0
    out dx, al
    pop ds
    pop di
    pop si
    pop bp
    retf 6
PgCopyCachedVideoTile16x16 endp

; Copies 200 rows of 40 bytes between VRAM regions using EGA latches.
; Pascal: procedure PgCopyVideoScreenRegion320x200(SourceByteColumn, SourcePixelRow,
; DestByteColumn, DestPixelRow: Word);
; Stack: BP+06h = DestPixelRow; BP+08h = DestByteColumn; BP+0Ah = SourcePixelRow; BP+0Ch =
; SourceByteColumn; FAR return, callee pops 8 argument bytes.
; Registers: prologue saves BP/SI/DI/DS; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes.
PgCopyVideoScreenRegion320x200 proc far
    push bp
    mov bp, sp
    push si
    push di
    push ds
    mov dx, PgVideoSegment
    mov es, dx
    mov ds, dx
    mov ax, word ptr [bp+0ah]
    mul word ptr cs:[PgScreenStrideBytes]
    mov si, word ptr [bp+0ch]
    add si, ax
    mov ax, word ptr [bp+6]
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, word ptr [bp+8]
    add di, ax
    mov dx, PgSequencerIndexPort
    mov al, PgSeqMapMask
    out dx, al
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov al, 5
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    mov ax, word ptr cs:[PgScreenStrideBytes]
    sub ax, 28h
    mov bx, 0c8h
PgScreenCopyCopyRow:
    mov cx, 28h
    rep movsb
    add si, ax
    add di, ax
    dec bx
    cmp bx, 0
    jg PgScreenCopyCopyRow
    mov dx, PgGraphicsDataPort
    mov al, 0
    out dx, al
    pop ds
    pop di
    pop si
    pop bp
    retf 8
PgCopyVideoScreenRegion320x200 endp

; Copies eight 40-byte rows from VRAM offset 28h to offset 0 using EGA latches.
; Pascal: procedure PgCopyStatusBandTemplate;
; Stack: FAR return, callee pops 0 argument bytes.
; Registers: prologue saves BP/SI/DI/DS; other registers and flags may change.
; Direct CS state: none.
PgCopyStatusBandTemplate proc far
    push bp
    mov bp, sp
    push si
    push di
    push ds
    mov dx, PgVideoSegment
    mov es, dx
    mov ds, dx
    mov si, 28h
    mov di, 0
    mov dx, PgSequencerIndexPort
    mov al, PgSeqMapMask
    out dx, al
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov al, 5
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    mov ax, 28h
    mov bx, 8
PgStatusCopyCopyRow:
    mov cx, 28h
    rep movsb
    add si, ax
    add di, ax
    dec bx
    cmp bx, 0
    jg PgStatusCopyCopyRow
    mov dx, PgGraphicsDataPort
    mov al, 0
    out dx, al
    pop ds
    pop di
    pop si
    pop bp
    retf
PgCopyStatusBandTemplate endp

; Unused caller-cleanup copy entries.

; Unused latch-copy entry for a 16x16 video-memory tile.
; Pascal stack equivalent (no interface declaration): procedure
; PgCopyVideoTile16x16UnusedCdecl(SourceByteColumn: Word; SourcePixelRow: Integer;
; DestByteColumn: Word; DestPixelRow: Integer);
; Stack: BP+0Ch = SourceByteColumn; BP+0Ah = SourcePixelRow; BP+08h = DestByteColumn; BP+06h =
; DestPixelRow; FAR return, callee pops 0 argument bytes.
; Registers: prologue saves BP/SI/DI/DS; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes.
; Original active RETF uses caller cleanup. The following unreachable RETF 8 is preserved.
PgCopyVideoTile16x16UnusedCdecl proc far
    push bp
    mov bp, sp
    push si
    push di
    push ds
    mov dx, PgVideoSegment
    mov es, dx
    mov ds, dx
    mov ax, word ptr [bp+0ah]
    mul word ptr cs:[PgScreenStrideBytes]
    mov si, word ptr [bp+0ch]
    add si, ax
    mov ax, word ptr [bp+6]
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, word ptr [bp+8]
    add di, ax
    mov dx, PgSequencerIndexPort
    mov al, PgSeqMapMask
    out dx, al
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov al, 5
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    mov ax, word ptr cs:[PgScreenStrideBytes]
    dec ax
    dec ax
    mov cx, 10h
PgUnusedTileCopyRow:
    movsb
    movsb
    add si, ax
    add di, ax
    loop PgUnusedTileCopyRow
    mov dx, PgGraphicsDataPort
    mov al, 0
    out dx, al
    pop ds
    pop di
    pop si
    pop bp
    retf
    retf 8
PgCopyVideoTile16x16UnusedCdecl endp

; Unused latch-copy entry for a byte-column/row video-memory rectangle.
; Pascal stack equivalent (no interface declaration): procedure
; PgCopyVideoRectangleUnusedCdecl(SourceByteColumn: Word; SourcePixelRow: Integer;
; DestByteColumn: Word; DestPixelRow: Integer; WidthBytes: Word; HeightRows: Word);
; Stack: BP+10h = SourceByteColumn; BP+0Eh = SourcePixelRow; BP+0Ch = DestByteColumn; BP+0Ah =
; DestPixelRow; BP+08h = WidthBytes; BP+06h = HeightRows; FAR return, callee pops 0 argument
; bytes.
; Registers: prologue saves BP/SI/DI/DS; other registers and flags may change.
; Direct CS state: PgScreenStrideBytes.
; Original active RETF uses caller cleanup. The following unreachable RETF 12 is preserved.
PgCopyVideoRectangleUnusedCdecl proc far
    push bp
    mov bp, sp
    push si
    push di
    push ds
    mov dx, PgVideoSegment
    mov es, dx
    mov ds, dx
    mov ax, word ptr [bp+0eh]
    mul word ptr cs:[PgScreenStrideBytes]
    mov si, word ptr [bp+10h]
    add si, ax
    mov ax, word ptr [bp+0ah]
    mul word ptr cs:[PgScreenStrideBytes]
    mov di, word ptr [bp+0ch]
    add di, ax
    mov dx, PgSequencerIndexPort
    mov al, PgSeqMapMask
    out dx, al
    mov dx, PgSequencerDataPort
    mov al, 0fh
    out dx, al
    mov dx, PgGraphicsIndexPort
    mov al, 5
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    mov ax, word ptr cs:[PgScreenStrideBytes]
    mov bx, word ptr [bp+8]
    sub ax, bx
    mov cx, word ptr [bp+6]
PgUnusedRectCopyRow:
    push cx
    mov cx, bx
    rep movsb
    pop cx
    add si, ax
    add di, ax
    loop PgUnusedRectCopyRow
    mov dx, PgGraphicsDataPort
    mov al, 0
    out dx, al
    pop ds
    pop di
    pop si
    pop bp
    retf
    retf 0ch
PgCopyVideoRectangleUnusedCdecl endp
CODE ends
end
