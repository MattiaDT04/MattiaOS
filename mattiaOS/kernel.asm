bits 32
org 0x9000

kernel_start:
    mov esi,messaggio
    mov edi,0xB8000

    call stampa

messaggio:
    db "Kernel Mattia OS avviato",0
stampa:
    mov al, [esi]
    cmp al,0
    je stop

     mov byte [edi], al
    mov byte [edi + 1], 0x0F

    inc esi
    add edi, 2

    jmp stampa

stop:
    hlt
    jmp stop