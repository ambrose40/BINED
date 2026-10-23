; Recovered earlier launcher-debugging experiment: EXEC a child COMMAND.COM
; with an INT 16h key feeder, then restore the original vector.
; On the bundled DOSBox this route captured the first menu selection but
; did not reliably run the whole batch workflow. MENUKEY.ASM is the working
; session-level version; this earlier source is retained for reference.
;
; TASM\TASM.EXE BUILD\MENUEXEC.ASM,BUILD\
; TASM\TLINK.EXE /t BUILD\MENUEXEC.OBJ,BUILD\MENUEXEC.COM
.model tiny
.code
org 100h
start:
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,offset stackEnd
    mov bx,offset stackEnd
    add bx,15
    mov cl,4
    shr bx,cl
    mov ah,4Ah
    int 21h
    mov ax,3516h
    int 21h
    mov word ptr oldKey,bx
    mov word ptr oldKey+2,es
    mov dx,offset keyboard
    mov ax,2516h
    int 21h
    mov ax,cs
    mov params+4,ax
    mov params+8,ax
    mov params+12,ax
    mov es,ax
    mov savedSP,sp
    mov bx,offset params
    mov dx,offset program
    mov ax,4B00h
    int 21h
    push cs
    pop ds
    mov ax,cs
    mov ss,ax
    mov sp,savedSP
    mov dx,word ptr oldKey
    mov ax,word ptr oldKey+2
    mov ds,ax
    mov ax,2516h
    int 21h
    mov ax,4C00h
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
    mov ax,0635h
    pop bx
    iret
keyboard endp

oldKey dd 0
savedSP dw 0
keyIndex dw 0
keys dw 0736h,3920h,0635h
keysEnd label byte
program db 'Z:\COMMAND.COM',0
params dw 0,offset tail,0,5Ch,0,6Ch,0
tail db tailEnd-tailText
tailText db ' /c call LAUNCH.BAT'
tailEnd db 13
db 512 dup (?)
stackEnd label byte
end start
