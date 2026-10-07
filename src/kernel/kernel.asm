bits 32
org 0x9000


; ---------------------------
; COSTANTI
; ---------------------------

CODE_SEG equ 0x08
DATA_SEG equ 0x10

IDT_BASE equ 0x10000


; ===========================
; KERNEL
; ===========================

kernel_start:

    cli

    ; Ripristiniamo i segmenti dati
    mov ax, DATA_SEG

    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x90000


    ; ---------------------------
    ; Stampa messaggio
    ; ---------------------------

    mov esi, messaggio
    mov edi, 0xB8000

    call stampa


    ; ---------------------------
    ; Configura IDT
    ; ---------------------------

    call init_idt


    ; ---------------------------
    ; Configura PIC
    ; ---------------------------

    call init_pic


    ; Carica IDT nella CPU

    lidt [idtr]


    ; Ora possiamo accettare interrupt

    sti


kernel_loop:

    hlt

    jmp kernel_loop



; ===========================
; STAMPA STRINGA
; ===========================

stampa:

    mov al, [esi]

    cmp al, 0

    je fine_stampa


    mov byte [edi], al
    mov byte [edi + 1], 0x0F


    inc esi
    add edi, 2

    jmp stampa


fine_stampa:

    ret



; ===========================
; INIZIALIZZAZIONE IDT
; ===========================

init_idt:

    ; Puliamo 2048 byte:
    ;
    ; 256 entry * 8 byte

    mov edi, IDT_BASE

    xor eax, eax

    mov ecx, 512

    rep stosd


    ; IRQ1 della tastiera
    ;
    ; dopo il remap del PIC:
    ;
    ; IRQ0 -> 0x20
    ; IRQ1 -> 0x21
    ;
    ; quindi tastiera = IDT[0x21]


    mov eax, keyboard_isr

    mov ebx, IDT_BASE + (0x21 * 8)


    ; Parte bassa indirizzo handler

    mov word [ebx], ax


    ; Segmento codice

    mov word [ebx + 2], CODE_SEG


    ; Riservato

    mov byte [ebx + 4], 0


    ; Interrupt Gate
    ;
    ; P = 1
    ; DPL = 00
    ; type = 1110

    mov byte [ebx + 5], 10001110b


    ; Parte alta indirizzo handler

    shr eax, 16

    mov word [ebx + 6], ax


    ret



; ===========================
; CONFIGURAZIONE PIC
; ===========================

init_pic:

    ; ICW1
    mov al, 0x11

    out 0x20, al
    call io_wait

    out 0xA0, al
    call io_wait


    ; Master PIC:
    ; IRQ0 inizierà da interrupt 0x20

    mov al, 0x20

    out 0x21, al
    call io_wait


    ; Slave PIC:
    ; inizierà da interrupt 0x28

    mov al, 0x28

    out 0xA1, al
    call io_wait


    ; Master ha lo slave su IRQ2

    mov al, 0x04

    out 0x21, al
    call io_wait


    ; Slave collegato a IRQ2

    mov al, 0x02

    out 0xA1, al
    call io_wait


    ; Modalità 8086

    mov al, 0x01

    out 0x21, al
    call io_wait

    out 0xA1, al
    call io_wait


    ; ---------------------------
    ; MASCHERE
    ; ---------------------------

    ; Abilitiamo SOLO IRQ1 = tastiera
    ;
    ; 11111101
    ;       ^
    ;       IRQ1 = 0

    mov al, 11111101b

    out 0x21, al


    ; Disabilitiamo tutti gli IRQ
    ; dello slave PIC

    mov al, 0xFF

    out 0xA1, al


    ret



; ===========================
; PIC WAIT
; ===========================

io_wait:

    push eax

    xor eax, eax

    out 0x80, al

    pop eax

    ret



; ===========================
; INTERRUPT TASTIERA
; ===========================

keyboard_isr:

    pushad

    ; Leggiamo lo scan code dalla porta tastiera
    in al, 0x60

    
    cmp al, 0x0E
    je gestisci_backspace

    ; Se bit 7 = 1, il tasto è stato rilasciato
    test al, 0x80
    jnz keyboard_fine


    ; Trasforma AL in un indice a 32 bit
    movzx eax, al


    ; Cerca il carattere corrispondente
    mov al, [scancode_ascii + eax]


    ; Se vale 0, non sappiamo gestire quel tasto
    cmp al, 0
    je keyboard_fine



    ; Scrive il carattere sullo schermo
    mov edi, [keyboard_cursor]

    mov byte [edi], al
    mov byte [edi + 1], 0x0F

    add dword [keyboard_cursor], 2

    jmp keyboard_fine


gestisci_backspace:
    
    mov edi, [keyboard_cursor]

    ;evita di andare prima dell'inizio della riga
    cmp edi, 0xB80A0
    jbe keyboard_fine

    sub edi,2

    mov byte [edi], ' '
    mov byte [edi + 1], 0x0F

    mov [keyboard_cursor], edi

    jmp keyboard_fine


keyboard_fine:

    ; End Of Interrupt al PIC
    mov al, 0x20
    out 0x20, al

    popad

    iretd



; ===========================
; DATI

scancode_ascii:

    db 0          ; 0x00
    db 0          ; ESC
    db '1'        ; 0x02
    db '2'
    db '3'
    db '4'
    db '5'
    db '6'
    db '7'
    db '8'
    db '9'
    db '0'
    db '-'
    db '='
    db 0          ; Backspace
    db 0          ; Tab

    db 'q'
    db 'w'
    db 'e'
    db 'r'
    db 't'
    db 'y'
    db 'u'
    db 'i'
    db 'o'
    db 'p'
    db '['
    db ']'
    db 0          ; Enter
    db 0          ; Ctrl

    db 'a'
    db 's'
    db 'd'
    db 'f'
    db 'g'
    db 'h'
    db 'j'
    db 'k'
    db 'l'
    db ';'
    db "'"
    db '`'
    db 0          ; Shift sinistro
    db '\'

    db 'z'
    db 'x'
    db 'c'
    db 'v'
    db 'b'
    db 'n'
    db 'm'
    db ','
    db '.'
    db '/'
    db 0          ; Shift destro
    db '*'
    db 0          ; Alt
    db ' '        ; Space

    input_buffer:
        times 64 db 0

    input_length:
        dd 0

; ===========================

messaggio:

    db "Mattia OS Kernel - premi dei tasti:", 0


keyboard_cursor:

    dd 0xB80A0



; ===========================
; IDT REGISTER
; ===========================

idtr:

    dw (256 * 8) - 1

    dd IDT_BASE



; Kernel = 4 settori
; 4 * 512 = 2048

times 2048 - ($ - $$) db 0