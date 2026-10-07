bits 16
org 0x8000

cli                             

xor ax,ax
mov ds,ax
mov ss,ax
mov sp, 0x7C00

sti       

mov si, messaggio
mov ah, 0x0E

stampa:
    mov al, [si]
    cmp al, 0
    je entra_32bit

    int 0x10

    inc si
    jmp stampa

messaggio:
    db "Stage 2 avviato", 0


entra_32bit:
    cli

    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp CODE_SEG:protected_mode


bits 32


protected_mode:
    mov ax, DATA_SEG

    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x90000


    mov esi, messaggio32
    mov edi, 0xB8000
    
    call stampa32


stampa32:
    mov al, [esi]
    cmp al,0
    je stop32

     mov byte [edi], al
    mov byte [edi + 1], 0x0F

    inc esi
    add edi, 2

    jmp stampa32

finestampa32:
    ret

stop32:
    hlt
    jmp stop32

messaggio32:
    db "Mattia OS 32 bit", 0

gdt_start:

gdt_null:
    dq 0

gdt_code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00

gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

times 2048 - ($ - $$) db 0
