; A tiny DOS integration driver. Supply deterministic BIOS keystrokes while
; EXEC runs the actual release EXE, then restore the BIOS vector and report
; the child's exit code. The editor has no special test hooks for this test.
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
    jc failed
    mov ax,3516h
    int 21h
    mov word ptr oldKeyboard,bx
    mov word ptr oldKeyboard+2,es
    mov dx,offset keyboard
    mov ax,2516h
    int 21h
    mov ax,cs
    mov tailSegment,ax
    mov fcb1Segment,ax
    mov fcb2Segment,ax
    mov es,ax
    mov savedSP,sp
    mov bx,offset execParameters
    mov dx,offset programName
    mov ax,4B00h
    int 21h
    push cs
    pop ds
    mov ax,cs
    cli
    mov ss,ax
    mov sp,savedSP
    sti
    ; Get status before any other EXEC-related DOS operation.
    jc exec_failed
    mov ah,4Dh
    int 21h
    mov childStatus,ax
    jmp restore_vector
exec_failed:
    mov childStatus,0FFFFh
restore_vector:
    mov dx,word ptr oldKeyboard
    mov ax,word ptr oldKeyboard+2
    mov ds,ax
    mov ax,2516h
    int 21h
    push cs
    pop ds
    cmp childStatus,0
    jne failed
    cmp keyIndex,offset keysEnd - offset keys
    jne failed
    mov dx,offset passedText
    mov ah,09h
    int 21h
    mov ax,4C00h
    int 21h
failed:
    mov dx,offset failedText
    mov ah,09h
    int 21h
    mov ax,4C01h
    int 21h

keyboard proc far
    cmp ah,00h
    je supply_key
    cmp ah,10h
    je supply_key
    jmp dword ptr cs:oldKeyboard
supply_key:
    push bx
    mov bx,cs:keyIndex
    cmp bx,offset keysEnd - offset keys
    jae no_more_keys
    mov ax,word ptr cs:keys[bx]
    add bx,2
    mov cs:keyIndex,bx
    pop bx
    iret
no_more_keys:
    mov ax,011Bh
    pop bx
    iret
keyboard endp

oldKeyboard     dd 0
savedSP         dw 0
childStatus     dw 0
keyIndex        dw 0
programName     db 'BUILD\BINED3.EXE',0
execParameters  dw 0
                dw offset commandTail
tailSegment     dw 0
                dw 5Ch
fcb1Segment     dw 0
                dw 6Ch
fcb2Segment     dw 0
commandTail     db tailEnd - tailText
tailText        db ' BUILD\TESTDATA\UI.BIN'
tailEnd         db 13
passedText      db 'PASS: release EXE startup, help, editing, save-as, save-and-quit.',13,10,'$'
failedText      db 'FAIL: release EXE integration test.',13,10,'$'
keys:
    dw 3B00h,0078h                ; F1, x: help and dismissal
    dw 0034h,0031h,0034h,0032h   ; hex 41 42
    dw 3F00h,7700h               ; binary, Ctrl-Home
    dw 0030h,0031h,0030h,0030h   ; first byte -> 01000011 (43)
    dw 0030h,0030h,0031h,0031h
    dw 4000h,7500h,5200h         ; hex, Ctrl-End, insert zero at EOF
    dw 0034h,0034h               ; overwrite it with 44
    dw 7700h,5300h               ; Ctrl-Home, delete: 42 44
    dw 3E00h                     ; F4 Save as
    dw 'B','U','I','L','D','\','T','E','S','T','D','A','T','A','\'
    dw 'U','I','2','.','B','I','N',13
    dw 003Fh                     ; invalid hex character: ignored
    dw 'F','F'                   ; change first byte: FF 44
    dw 011Bh,'s'                 ; Esc, save-and-quit
keysEnd:
    db 512 dup (?)
stackEnd:
end start
