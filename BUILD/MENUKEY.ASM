; Recovered launcher-debugging source: final working TSR keyboard feeder.
; It supplies 6 (build/tests), Space (dismiss results), then 5 (DOS prompt).
; Run in a fresh DOSBox session and exit DOSBox after the menu check.
;
; From the project root inside DOSBox:
;   TASM\TASM.EXE BUILD\MENUKEY.ASM,BUILD\
;   TASM\TLINK.EXE /t BUILD\MENUKEY.OBJ,BUILD\MENUKEY.COM
;   set BINED_TESTED=0
;   BUILD\MENUKEY.COM
;   call LAUNCH.BAT
;   if "%BINED_TESTED%"=="1" echo PASS: launcher option 6
;
; The resident handler remains installed until this DOSBox session exits.
.model tiny
.code
org 100h
start:
    mov ax,cs
    mov ds,ax
    mov ax,3516h
    int 21h
    mov word ptr oldKey,bx
    mov word ptr oldKey+2,es
    mov dx,offset keyboard
    mov ax,2516h
    int 21h
    mov dx,offset residentEnd
    add dx,15
    mov cl,4
    shr dx,cl
    mov ax,3100h
    int 21h

keyboard proc far
    cmp ah,0
    je supply
    cmp ah,10h
    je supply
    jmp dword ptr cs:oldKey
supply:
    push bx
    mov bx,cs:keyIndex
    cmp bx,keysEnd - keys
    jae exhausted
    mov ax,word ptr cs:keys[bx]
    add bx,2
    mov cs:keyIndex,bx
    pop bx
    iret
exhausted:
    mov ax,0635h                  ; continue selecting 5 if asked again
    pop bx
    iret
keyboard endp

oldKey dd 0
keyIndex dw 0
keys dw 0736h,3920h,0635h
keysEnd label byte
residentEnd label byte
end start
