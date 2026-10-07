
bits 16             
org 0x7C00   

cli                             ;Disabilita temporaneamente interrupt hardware, per non mandare in crash con eventuali errori dovuti dagli interrupt

xor ax,ax
mov ds,ax
mov ss,ax
mov sp, 0x7C00

sti                             ;Riabilita interrupt
    
mov [boot_drive], dl
; Carica il secondo settore a 0x8000

mov ah, 0x02
mov al, 0x04

mov ch, 0x00
mov cl, 0x02
mov dh, 0x00

mov dl, [boot_drive]

mov bx, 0x8000

int 0x13

; se c'è stato un errore, CF = 1
jc errore

; esegui stage2
jmp 0x0000:0x8000


errore:
    mov si, messaggio_errore
    mov ah, 0x0E

stampa_errore:
    mov al, [si]
    cmp al, 0
    je stop

    int 0x10

    inc si
    jmp stampa_errore


stop:
    hlt
    jmp stop


messaggio_errore:
    db "Errore lettura disco", 0

boot_drive:
    db 0


times 510 - ($ - $$) db 0
dw 0xAA55