_TEXT ends
_DATA segment word public use16 'DATA'
caseUndoBasic   db 'undo/redo HEX/BIN/ASCII, no-ops and redo branching',13,10,'$'
caseUndoText    db 'undo/redo grouped CR/LF, Text deletion/tab and zero insertion',13,10,'$'
caseUndoLimit   db '32-change eviction, complete redo and reachable savepoints',13,10,'$'
caseUndoBounds  db 'undo/redo capacity rejection and cross-64-KiB deltas',13,10,'$'
caseUndoSave    db 'undo/redo successful/failed saves, branching and load reset',13,10,'$'
caseUndoStack   db '1000 undo/redo cycles preserve stack, cache and bytes',13,10,'$'
undoTestPath    db 'BUILD\TESTDATA\UNDO.BIN',0
_DATA ends
_TEXT segment word public use16 'CODE'

HCHECK macro actual,expected
    cmp actual,expected
    jne undo_test_bad
endm
HBYTE macro address,expected
    mov eax,address
    call ReadByte
    cmp al,expected
    jne undo_test_bad
endm

; AL desired edit mode, always with HEX layout as the ASCII starting view.
FreshUndoDocument proc
    push ax
    mov fileSize,0
    mov cursorOffset,0
    mov viewOffset,0
    mov dirty,0
    xor al,al
    call SetMode
    pop ax
    call SetMode
    call ResetUndoHistory
    ret
FreshUndoDocument endp

TestUndoRedo proc
    mov testCase,offset caseUndoBasic
    mov al,2
    call FreshUndoDocument
    call UndoChange
    jnc undo_test_bad
    call RedoChange
    jnc undo_test_bad
    HCHECK dirty,0
    mov al,'A'
    call HandleKey
    HCHECK historyCount,1
    HCHECK historyPosition,1
    HCHECK fileSize,1
    mov ax,8500h
    call HandleKey
    HCHECK fileSize,0
    HCHECK cursorOffset,0
    HCHECK dirty,0
    mov ax,8600h
    call HandleKey
    HBYTE 0,'A'
    HCHECK dirty,1
    mov al,'B'
    call HandleKey
    mov ax,8500h
    call HandleKey
    HCHECK fileSize,1
    mov cursorOffset,0
    mov al,'A'                     ; identical overwrite advances, preserves redo
    call HandleKey
    mov al,7Fh
    call HandleKey
    HCHECK historyCount,2
    HCHECK historyPosition,1
    mov ax,3F00h                   ; undo/redo keep whichever editing mode is active
    call HandleKey
    mov ax,8600h
    call HandleKey
    HCHECK editMode,1
    HCHECK fileSize,2
    HBYTE 1,'B'
    mov ax,8500h
    call HandleKey
    xor al,al
    call SetMode
    mov al,2
    call SetMode
    mov al,'C'                     ; discard the undone B branch
    call HandleKey
    call RedoChange
    jnc undo_test_bad
    HBYTE 1,'C'
    HCHECK historyCount,2

    mov al,2
    call FreshUndoDocument
    mov dirty,1                    ; a reset dirty baseline has no reachable clean point
    call ResetUndoHistory
    mov al,'X'
    call HandleKey
    call UndoChange
    HCHECK fileSize,0
    HCHECK dirty,1

    xor al,al
    call FreshUndoDocument
    mov al,'4'
    call HandleKey
    mov al,'1'
    call HandleKey
    HCHECK historyCount,2           ; hex digits and binary bits are individual changes
    call UndoChange
    jc undo_test_bad
    HBYTE 0,40h
    HCHECK digitIndex,1
    call UndoChange
    jc undo_test_bad
    HCHECK fileSize,0
    call RedoChange
    call RedoChange
    HBYTE 0,41h
    mov al,1
    call SetMode
    mov cursorOffset,0
    mov digitIndex,6               ; set 41 -> 43
    mov al,'1'
    call HandleKey
    HBYTE 0,43h
    call UndoChange
    HBYTE 0,41h
    HCHECK digitIndex,6
    call RedoChange
    HBYTE 0,43h
    HCHECK digitIndex,7
    mov al,'1'                     ; already set: no new change
    call HandleKey
    mov al,'2'                     ; invalid binary input: no new change
    call HandleKey
    HCHECK historyCount,3

    mov testCase,offset caseUndoText
    mov al,3
    call FreshUndoDocument
    mov al,'A'
    call HandleKey
    mov al,13
    call HandleKey
    HCHECK historyCount,2
    HCHECK fileSize,3
    mov al,'B'
    call HandleKey
    call UndoChange
    call UndoChange
    HCHECK fileSize,1
    HBYTE 0,'A'
    call RedoChange
    HCHECK fileSize,3
    HBYTE 1,13
    HBYTE 2,10
    call RedoChange
    mov cursorOffset,3
    mov al,8                       ; one CR/LF-pair Backspace transaction
    call HandleKey
    HCHECK fileSize,2
    HBYTE 1,'B'
    call UndoChange
    HCHECK fileSize,4
    HCHECK cursorOffset,3
    HBYTE 1,13
    HBYTE 2,10
    call RedoChange
    HCHECK fileSize,2
    call UndoChange
    mov cursorOffset,1
    mov ax,5300h
    call HandleKey
    HCHECK fileSize,2
    call UndoChange
    HCHECK fileSize,4
    HBYTE 3,'B'
    mov cursorOffset,4
    mov al,9
    call HandleKey
    HBYTE 4,9
    mov ax,3F00h
    call HandleKey
    call UndoChange
    HCHECK fileSize,4
    HCHECK editMode,1
    call RedoChange
    HBYTE 4,9
    mov cursorOffset,2
    mov ax,5200h
    call HandleKey
    HBYTE 2,0
    call UndoChange
    HBYTE 2,10
    call RedoChange
    mov ax,5300h
    call HandleKey
    HCHECK fileSize,5
    call UndoChange
    HCHECK fileSize,6
    HBYTE 2,0
    call RedoChange
    HCHECK fileSize,5

    mov testCase,offset caseUndoLimit
    mov al,2
    call FreshUndoDocument
    mov testLoops,0
undo_fill_history:
    mov ax,testLoops
    add al,'A'
    call HandleKey
    inc testLoops
    cmp testLoops,40
    jb undo_fill_history
    HCHECK fileSize,40
    HCHECK historyCount,32
    mov testLoops,32
undo_limit_back:
    call UndoChange
    jc undo_test_bad
    dec testLoops
    jnz undo_limit_back
    HCHECK fileSize,8
    HCHECK dirty,1                 ; initial state fell outside the 32-change window
    call UndoChange
    jnc undo_test_bad
    call HistoryMarkSaved          ; this reachable boundary must stay clean on return
    mov testLoops,32
undo_limit_forward:
    call RedoChange
    jc undo_test_bad
    dec testLoops
    jnz undo_limit_forward
    HCHECK fileSize,40
    HBYTE 39,'h'
    HCHECK dirty,1
    mov testLoops,32
undo_return_saved:
    call UndoChange
    jc undo_test_bad
    dec testLoops
    jnz undo_return_saved
    HCHECK dirty,0
    mov al,'C'
    call HandleKey
    HCHECK historyCount,1
    HCHECK historyPosition,1
    call UndoChange
    HCHECK dirty,0
    call RedoChange
    HCHECK fileSize,9
    HCHECK dirty,1
    call RedoChange
    jnc undo_test_bad

    mov testCase,offset caseUndoBounds
    mov al,2
    call FreshUndoDocument
    mov al,'A'
    call HandleKey
    call UndoChange
    mov eax,bufferCapacity
    mov testCapacity,eax
    mov bufferCapacity,0
    call RedoChange
    jnc undo_test_bad
    HCHECK historyPosition,0
    HCHECK fileSize,0
    HCHECK dirty,0
    mov al,'B'                     ; rejected growth must not discard redo either
    call HandleKey
    HCHECK historyCount,1
    HCHECK historyPosition,0
    mov eax,testCapacity
    mov bufferCapacity,eax
    call RedoChange
    HBYTE 0,'A'
    mov fileSize,20011h
    call TestFillPattern
    mov dirty,0
    call ResetUndoHistory
    mov al,3
    call SetMode
    mov cursorOffset,0FFFFh
    mov al,13
    call HandleKey
    HCHECK historyCount,1
    HCHECK fileSize,20013h
    HBYTE 0FFFFh,13
    HBYTE 10000h,10
    call UndoChange
    jc undo_test_bad
    HCHECK fileSize,20011h
    call TestVerifyPattern
    jc undo_test_bad
    HCHECK dirty,0
    call RedoChange
    HCHECK fileSize,20013h
    mov al,8
    call HandleKey
    HCHECK fileSize,20011h
    call UndoChange
    HBYTE 0FFFFh,13
    HBYTE 10000h,10
    call UndoChange
    HCHECK fileSize,20011h
    call TestVerifyPattern
    jc undo_test_bad

    mov testCase,offset caseUndoSave
    mov al,2
    call FreshUndoDocument
    mov al,'A'
    call HandleKey
    mov dx,offset undoTestPath
    call SaveDocument
    jc undo_test_bad
    HCHECK dirty,0
    mov al,'B'
    call HandleKey
    mov faultMode,1
    mov dx,offset undoTestPath
    call SaveDocument
    mov faultMode,0
    jnc undo_test_bad
    HCHECK dirty,1
    call UndoChange
    HCHECK fileSize,1
    HCHECK dirty,0
    call RedoChange
    HCHECK dirty,1
    mov dx,offset undoTestPath
    call SaveDocument
    jc undo_test_bad
    HCHECK dirty,0
    call UndoChange
    HCHECK dirty,1
    call RedoChange
    HCHECK dirty,0
    call UndoChange
    mov dx,offset undoTestPath      ; saving an undone state retains the redo branch
    call SaveDocument
    jc undo_test_bad
    HCHECK dirty,0
    call RedoChange
    HCHECK dirty,1
    call UndoChange
    HCHECK dirty,0
    mov al,'C'                     ; branch identities must never reuse saved B state
    call HandleKey
    HBYTE 1,'C'
    HCHECK dirty,1
    call UndoChange
    HCHECK dirty,0
    call RedoChange
    HCHECK dirty,1
    mov si,offset undoTestPath
    mov di,offset fileName
    call TestCopyString
    mov cursorOffset,0
    call LoadFile
    jc undo_test_bad
    HCHECK fileSize,1
    HBYTE 0,'A'
    HCHECK dirty,0
    HCHECK historyCount,0
    call RedoChange
    jnc undo_test_bad
    mov dx,offset undoTestPath
    mov ah,41h
    int 21h
    jc undo_test_bad

    mov testCase,offset caseUndoStack
    mov al,3
    call FreshUndoDocument
    mov testStack,sp
    mov testLoops,1000
undo_stress:
    mov al,'Q'
    call HandleKey
    mov ax,8500h
    call HandleKey
    mov ax,8600h
    call HandleKey
    mov ax,8500h
    call HandleKey
    call EnsureVisible
    HCHECK fileSize,0
    HCHECK dirty,0
    cmp sp,testStack
    jne undo_test_bad
    dec testLoops
    jnz undo_stress
    clc
    ret
undo_test_bad:
    mov faultMode,0
    stc
    ret
TestUndoRedo endp
