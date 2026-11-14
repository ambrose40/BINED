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
passedText      db 'PASS: release EXE editing, F3/F4 search, universal F2 and undo.',13,10,'$'
failedText      db 'FAIL: release EXE integration test.',13,10,'$'
keys:
    dw 8500h,8600h               ; F11/F12 safely report empty history
    dw 3D00h,3E00h,4300h,13,27  ; next/previous without a pattern; F9 error/cancel
    dw 4200h,'0',13               ; F8 accepts zero in an empty document
    dw 3B00h,0078h                ; F1, x: help and dismissal
    dw 0034h,0031h,0034h,0032h   ; hex 41 42
    dw 8500h,8600h              ; undo/redo a hex digit through the release event loop
    dw 4300h,'4','2',13,'4','2'  ; F9 hex finds B; rewrite the same byte
    dw 3D00h,'4','2'             ; F3 wraps and finds that byte again
    dw 3E00h,'4','2'             ; F4 finds the previous B, without a save dialog
    dw 4200h,'0',13,3E00h,'4','2' ; previous wraps from file start
    dw 3F00h,7700h               ; binary, Ctrl-Home
    dw 0030h,0031h,0030h,0030h   ; first byte -> 01000011 (43)
    dw 0030h,0030h,0031h,0031h
    dw 8500h,8600h              ; binary bit undo/redo (identical input is not stored)
    dw 4000h,7500h,5200h         ; hex, Ctrl-End, insert zero at EOF
    dw 0034h,0034h               ; overwrite it with 44
    dw 7700h,5300h               ; Ctrl-Home, delete: 42 44
    dw 3C00h                     ; F2 prefilled name; typing replaces it (Save As)
    dw 'B','U','I','L','D','\','T','E','S','T','D','A','T','A','\'
    dw 'U','I','2','.','B','I','N',13
    dw 003Fh                     ; invalid hex character: ignored
    dw 4200h,'F','F','F','F','F','F','F','F',13,27 ; out-of-range stays open
    dw 'F',4200h,27,4300h,27,'F' ; cancelled F8/F9 preserve the selected low nibble
    dw 4300h,'0','G',13,8,'0',13 ; invalid hex corrected to 00; miss preserves cursor
    dw 8500h,8600h              ; search/dialog input does not consume undo history
    dw 0009h                     ; Tab ASCII: cursor already at byte 1
    dw 4200h,'1',13              ; F8 retains HEX's right-column ASCII focus
    dw 'z',' ','!'               ; overwrite then append: FF 7A 20 21
    dw 8500h,8600h              ; ASCII append undo/redo
    dw 3F00h,0009h,0009h        ; F5 BIN, Tab ASCII, Tab numeric
    dw 4200h,'4',13              ; EOF append in BIN, no mode switch
    dw '0','1','0','0'          ; append binary 01000001 (41)
    dw '0','0','0','1'
    dw 0009h                    ; Tab ASCII in binary layout
    dw 4200h,'4',13,'?'          ; F8 retains BIN's ASCII focus
    dw 3B00h,'x'                ; help/dismiss while ASCII mode active
    dw ' '                      ; append a space in binary ASCII focus
    dw 4000h,0009h              ; F6 -> HEX, Tab -> ASCII (HEX)
    dw 'H'                      ; append in hex ASCII focus
    dw 4100h                    ; F7 -> full-screen Text
    dw 13,8500h,8600h            ; CR/LF is one undoable Text change
    dw 'T','e','x','t',13,9,'O','k',8,'K',8500h,'K',8600h ; new edit clears redo
    dw 4300h,9,'T','e','x','t',13,5300h,'T' ; text search and same-byte replacement
    dw 3D00h,5300h,'T'          ; repeat wraps, keeping Text insertion mode
    dw 4300h,9,'0','9',13,5300h,9 ; hex search finds tab; replace with an actual tab
    dw 4300h,9,'X','Y','Z',27    ; cancellation retains the saved 09 query
    dw 3D00h,5300h,9             ; repeat that query and replace the tab again
    dw 3E00h,5300h,9             ; previous tab match, preserving Text insertion
    dw 4200h,'1','0',13,'X',8    ; Text goto byte 10h, insert then delete X
    dw 4700h,4D00h,5300h,'O',4F00h ; Home, Right past tab, replace O, End
    dw 3B00h,'x'                ; modal help in full Text view
    dw 4000h,3F00h,4100h        ; F6 HEX, F5 BIN, F7 Text; no conversion
    dw 3C00h                    ; failed renamed F2 save opens the error modal
    dw 'B','U','I','L','D','\','N','O','_','S','U','C','H','\'
    dw 'B','A','D','.','B','I','N',13,'x'
    dw 3C00h,13,8500h,8600h,'X',8 ; Enter saves same path, then undo/redo and edit
    dw 011Bh,'s',27             ; cancelling the universal save cancels quit
    dw 3C00h,13,'X',8           ; save same path, then become dirty again
    dw 011Bh,'s',13             ; save-and-quit uses the same prefilled dialog
keysEnd:
    db 512 dup (?)
stackEnd:
end start
