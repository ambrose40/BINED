; Fault interception is compiled only in TEST3, never in the release editor.
_TEXT ends
_DATA segment word public use16 'DATA'
faultMode       db 0
faultHits       db 0
faultCase       db 1
faultBytes      dd 0
faultPath       db 'BUILD\TESTDATA\FAULT.BIN',0
caseSaveFault   db 'save write/short-write/close/install/restore failures',13,10,'$'
_DATA ends
_TEXT segment word public use16 'CODE'

TestDiskInterrupt proc
    ; DS is the file buffer during DOS transfers; read test state via DGROUP.
    push ds
    push ax
    mov ax,DGROUP
    mov ds,ax
    pop ax
    cmp faultMode,0
    je fault_real_dos
    cmp ah,40h
    jne fault_check_close
    cmp faultMode,1
    je fault_error
    cmp faultMode,2
    jne fault_real_dos
    inc faultHits
    pop ds
    xor ax,ax                     ; short write, not an error return
    clc
    ret
fault_check_close:
    cmp ah,3Eh
    jne fault_check_rename
    cmp faultMode,3
    jne fault_real_dos
    inc faultHits
    pop ds
    int 21h                       ; close the real handle before reporting failure
    mov ax,6
    stc
    ret
fault_check_rename:
    cmp ah,56h
    jne fault_real_dos
    cmp faultMode,4
    jb fault_real_dos
    cmp dx,offset stagePath
    je fault_error
    cmp faultMode,5
    jne fault_real_dos
    cmp dx,offset backupPath
    jne fault_real_dos
fault_error:
    inc faultHits
    pop ds
    mov ax,5
    stc
    ret
fault_real_dos:
    pop ds
    int 21h
    ret
TestDiskInterrupt endp

; EDX = four bytes, little endian. Set the four-byte in-memory document.
FaultSetBytes proc
    mov fileSize,4
    mov cursorOffset,0
    xor eax,eax
    mov cx,4
fault_set_next:
    call WriteByte
    shr edx,8
    inc eax
    loop fault_set_next
    ret
FaultSetBytes endp

; DS:DX path, EBP expected four bytes -> CF on error; always close the handle.
FaultCheckFile proc
    mov ax,3D00h
    int 21h
    jc fault_check_bad
    mov bx,ax
    mov dx,offset faultBytes
    mov cx,4
    mov ah,3Fh
    int 21h
    pushf
    push ax
    mov ah,3Eh
    int 21h
    pop ax
    popf
    jc fault_check_bad
    cmp ax,4
    jne fault_check_bad
    cmp faultBytes,ebp
    jne fault_check_bad
    clc
    ret
fault_check_bad:
    stc
    ret
FaultCheckFile endp

TestSaveFailures proc
    mov testCase,offset caseSaveFault
    mov faultCase,1
fault_test_next:
    mov faultMode,0
    mov edx,45464153h             ; SAFE
    call FaultSetBytes
    mov dx,offset faultPath
    call SaveDocument
    jc fault_test_bad
    mov edx,54494445h             ; EDIT
    call FaultSetBytes
    mov dirty,1
    mov faultHits,0
    mov al,faultCase
    mov faultMode,al
    mov dx,offset faultPath
    call SaveDocument
    mov faultMode,0
    jnc fault_test_bad
    cmp dirty,1
    jne fault_test_bad
    cmp faultHits,0
    je fault_test_bad
    cmp fileSize,4
    jne fault_test_bad
    cmp faultCase,5
    je fault_test_recovery
    mov dx,offset faultPath
    mov ebp,45464153h
    call FaultCheckFile
    jc fault_test_bad
    jmp fault_test_continue
fault_test_recovery:
    cmp faultHits,2
    jne fault_test_bad
    cmp backupExists,1
    jne fault_test_bad
    cmp stageExists,1
    jne fault_test_bad
    mov dx,offset faultPath
    mov ax,4300h
    int 21h
    jnc fault_test_bad             ; original is safely retained under backupPath
    mov dx,offset backupPath
    mov ebp,45464153h
    call FaultCheckFile
    jc fault_test_bad
    mov dx,offset stagePath
    mov ebp,54494445h
    call FaultCheckFile
    jc fault_test_bad
    mov dx,offset backupPath
    mov di,offset faultPath
    call RenameFile
    jc fault_test_bad
    mov dx,offset stagePath
    mov ah,41h
    int 21h
    jc fault_test_bad
fault_test_continue:
    inc faultCase
    cmp faultCase,6
    jb fault_test_next
    mov dx,offset faultPath
    mov ah,41h
    int 21h
    ret
fault_test_bad:
    mov faultMode,0
    stc
    ret
TestSaveFailures endp
