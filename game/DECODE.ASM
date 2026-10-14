; Asset decoder used by SAMDATA: reverses bits and applies the cyclic
; Copyright 1991 Peder Jungck XOR key to a supplied buffer.
CODE segment byte public
assume cs:CODE
public DecryptGameAssetBuffer

; Reverses each byte's bit order and XORs a cyclic 28-byte Copyright 1991 Peder Jungck key in place.
DecryptGameAssetBuffer proc far
    push bp
    mov bp,sp
    sub sp,54h
    push si
    push di
    push ds
    mov ax,ds
    cli

    mov byte ptr [bp-54h],43h ; C
    mov byte ptr [bp-53h],6Fh ; o
    mov byte ptr [bp-52h],70h ; p
    mov byte ptr [bp-51h],79h ; y
    mov byte ptr [bp-50h],72h ; r
    mov byte ptr [bp-4Fh],69h ; i
    mov byte ptr [bp-4Eh],67h ; g
    mov byte ptr [bp-4Dh],68h ; h
    mov byte ptr [bp-4Ch],74h ; t
    mov byte ptr [bp-4Bh],20h ; space
    mov byte ptr [bp-4Ah],31h ; 1
    mov byte ptr [bp-49h],39h ; 9
    mov byte ptr [bp-48h],39h ; 9
    mov byte ptr [bp-47h],31h ; 1
    mov byte ptr [bp-46h],20h ; space
    mov byte ptr [bp-45h],50h ; P
    mov byte ptr [bp-44h],65h ; e
    mov byte ptr [bp-43h],64h ; d
    mov byte ptr [bp-42h],65h ; e
    mov byte ptr [bp-41h],72h ; r
    mov byte ptr [bp-40h],20h ; space
    mov byte ptr [bp-3Fh],4Ah ; J
    mov byte ptr [bp-3Eh],75h ; u
    mov byte ptr [bp-3Dh],6Eh ; n
    mov byte ptr [bp-3Ch],67h ; g
    mov byte ptr [bp-3Bh],63h ; c
    mov byte ptr [bp-3Ah],6Bh ; k
    mov byte ptr [bp-39h],0
    mov byte ptr [bp-38h],0
    mov byte ptr [bp-37h],0

    xor di,di
    xor si,si
    jmp short outer_test

next_byte:
    mov byte ptr [bp-3],0
    mov word ptr [bp-2],0
    jmp short bit_test

read_bit:
    les bx,[bp+8]
    mov al,es:[bx+si]
    mov ah,0
    mov dx,1
    mov cl,[bp-2]
    shl dx,cl
    test ax,dx
    jle no_set_bit
    mov cl,7
    sub cl,[bp-2]
    mov al,1
    shl al,cl
    or [bp-3],al
no_set_bit:
    inc word ptr [bp-2]
bit_test:
    cmp word ptr [bp-2],8
    jb read_bit

    les bx,[bp+8]
    mov al,[bp-3]
    mov es:[bx+si],al
    les bx,[bp+8]
    mov al,[bp+di-54h]
    xor es:[bx+si],al
    inc di
    cmp di,1Bh
    jbe no_key_wrap
    xor di,di
no_key_wrap:
    inc si
outer_test:
    cmp si,[bp+6]
    jb next_byte

    sti
    pop ds
    pop di
    pop si
    mov sp,bp
    pop bp
    retf 6
DecryptGameAssetBuffer endp
CODE ends
end
