_TEXT ends
_DATA segment word public use16 'DATA'
caseGoto        db 'F8 hex parsing, bounds, cancellation, modes and navigation',13,10,'$'
caseGotoVideo   db 'F8 prompt/input colours, bounds and error feedback',13,10,'$'
gotoTestMode    dw 0
gotoTestFocus   db 0
gotoTestView    db 0
gotoTestDigit   db 0
gotoTestZero    db '00000000',0
gotoTestLarge   db '10000',0
gotoTestEOF     db '20011',0
gotoTestMax     db 'ffffffff',0
gotoTestBad     db '1g',0
gotoTestNine    db '000000000',0
gotoTestTwo     db '2',0
gotoTestOne     db '1',0
_DATA ends
_TEXT segment word public use16 'CODE'

; Type a zero-terminated dialog string without consuming BIOS input.
TypeGotoString proc
goto_test_type:
    lodsb
    test al,al
    jz goto_test_typed
    push si
    call HandleGotoKey
    pop si
    jmp goto_test_type
goto_test_typed:
    ret
TypeGotoString endp

; Type SI and accept. Does not reset existing editor state.
AcceptGotoString proc
    push si
    call ResetGotoInput
    pop si
    call TypeGotoString
    mov al,13
    call HandleGotoKey
    ret
AcceptGotoString endp

TestGotoOffset proc
    mov testCase,offset caseGoto
    mov testStack,sp
    mov fileSize,20011h
    call TestFillPattern
    mov dirty,0
    mov gotoTestMode,0
goto_test_mode_next:
    xor al,al
    call SetMode
    cmp gotoTestMode,0
    je goto_test_selected
    cmp gotoTestMode,1
    je goto_test_binary
    cmp gotoTestMode,2
    je goto_test_hex_ascii
    cmp gotoTestMode,3
    je goto_test_bin_ascii
    mov al,3
    call SetMode
    jmp goto_test_selected
goto_test_binary:
    mov al,1
    call SetMode
    jmp goto_test_selected
goto_test_bin_ascii:
    mov al,1
    call SetMode
goto_test_hex_ascii:
    mov al,2
    call SetMode
goto_test_selected:
    mov al,editMode
    mov gotoTestFocus,al
    mov al,viewMode
    mov gotoTestView,al
    mov cursorOffset,17
    mov digitIndex,0
    cmp digitsPerByte,1
    je goto_test_digit_ready
    mov digitIndex,1
goto_test_digit_ready:
    mov al,digitIndex
    mov gotoTestDigit,al
    mov viewOffset,0
    mov si,offset gotoTestMax       ; all eight bits of every hex digit preserved
    call AcceptGotoString
    cmp gotoDone,0
    jne goto_test_bad
    cmp gotoError,offset gotoRange
    jne goto_test_bad
    cmp cursorOffset,17
    jne goto_test_bad
    cmp viewOffset,0
    jne goto_test_bad
    mov al,gotoTestDigit
    cmp digitIndex,al
    jne goto_test_bad
    mov al,27
    call HandleGotoKey
    cmp gotoDone,2
    jne goto_test_bad
    cmp cursorOffset,17
    jne goto_test_bad
    mov al,gotoTestDigit
    cmp digitIndex,al
    jne goto_test_bad
    mov si,offset gotoTestBad
    call AcceptGotoString
    cmp gotoDone,0
    jne goto_test_bad
    cmp gotoError,offset gotoInvalid
    jne goto_test_bad
    cmp cursorOffset,17
    jne goto_test_bad
    mov al,8                      ; correct the invalid g; do not silently drop it
    call HandleGotoKey
    mov al,13
    call HandleGotoKey
    cmp gotoDone,1
    jne goto_test_bad
    cmp cursorOffset,1
    jne goto_test_bad
    cmp digitIndex,0
    jne goto_test_bad
    call ResetGotoInput
    mov al,13                     ; empty Enter is not an implicit zero jump
    call HandleGotoKey
    cmp gotoDone,0
    jne goto_test_bad
    cmp gotoError,offset gotoInvalid
    jne goto_test_bad
    cmp cursorOffset,1
    jne goto_test_bad
    mov si,offset gotoTestNine
    call AcceptGotoString
    cmp gotoDone,0
    jne goto_test_bad
    mov al,'0'                    ; field capacity cannot overwrite its terminator
    call HandleGotoKey
    cmp gotoLength,9
    jne goto_test_bad
    cmp gotoInput+9,0
    jne goto_test_bad
    mov al,8
    call HandleGotoKey
    mov al,13
    call HandleGotoKey
    cmp gotoDone,1
    jne goto_test_bad
    cmp cursorOffset,0
    jne goto_test_bad
    mov textGoalValid,1
    mov textLastValid,1
    mov si,offset gotoTestLarge
    call AcceptGotoString
    cmp cursorOffset,10000h
    jne goto_test_bad
    cmp gotoDone,1
    jne goto_test_bad
    cmp textGoalValid,0
    jne goto_test_bad
    cmp textLastValid,0
    jne goto_test_bad
    cmp viewMode,2
    je goto_test_text_visible
    mov eax,viewOffset
    cmp eax,cursorOffset
    ja goto_test_bad
    add eax,pageBytes
    cmp eax,cursorOffset
    jbe goto_test_bad
    jmp goto_test_mode_unchanged
goto_test_text_visible:
    cmp textCursorRow,DATA_ROWS
    jae goto_test_bad
    cmp textCursorCol,80
    jae goto_test_bad
goto_test_mode_unchanged:
    mov al,gotoTestFocus
    cmp editMode,al
    jne goto_test_bad
    mov al,gotoTestView
    cmp viewMode,al
    jne goto_test_bad
    mov si,offset gotoTestEOF
    call AcceptGotoString
    cmp cursorOffset,20011h
    jne goto_test_bad
    mov si,offset gotoTestZero
    call AcceptGotoString
    cmp cursorOffset,0
    jne goto_test_bad
    cmp dirty,0
    jne goto_test_bad
    cmp sp,testStack
    jne goto_test_bad
    inc gotoTestMode
    cmp gotoTestMode,5
    jb goto_test_mode_next
    call TestVerifyPattern
    jc goto_test_bad
    mov fileSize,4
    xor eax,eax
    mov dl,'A'
    call WriteByte
    mov eax,1
    mov dl,13
    call WriteByte
    mov eax,2
    mov dl,10
    call WriteByte
    mov eax,3
    mov dl,'B'
    call WriteByte
    mov si,offset gotoTestTwo
    call AcceptGotoString
    cmp cursorOffset,1             ; Text's shared CR/LF cell matches navigation
    jne goto_test_bad
    mov fileSize,0
    mov si,offset gotoTestZero
    call AcceptGotoString
    cmp gotoDone,1
    jne goto_test_bad
    cmp cursorOffset,0
    jne goto_test_bad
    mov si,offset gotoTestOne
    call AcceptGotoString
    cmp gotoDone,0
    jne goto_test_bad
    cmp gotoError,offset gotoRange
    jne goto_test_bad
    clc
    ret
goto_test_bad:
    stc
    ret
TestGotoOffset endp

TestGotoVideo proc
    mov testCase,offset caseGotoVideo
    mov fileSize,20011h
    mov cursorOffset,10000h
    call ResetGotoInput
    mov si,offset gotoTestBad
    call TypeGotoString
    mov al,13
    call HandleGotoKey
    call RenderGotoDialog
    cmp word ptr es:[23*160],0745h ; gray error text, E in Enter
    jne goto_video_bad
    cmp word ptr es:[24*160],0D31h ; purple input 1g
    jne goto_video_bad
    cmp word ptr es:[24*160+1*2],0D67h
    jne goto_video_bad
    cmp word ptr es:[24*160+12*2],0A45h ; green EOF label
    jne goto_video_bad
    cmp word ptr es:[24*160+24*2],0531h ; dark-purple EOF value ...1
    jne goto_video_bad
    cmp word ptr es:[24*160+42*2],0531h ; current 00010000
    jne goto_video_bad
    cmp word ptr es:[4000],0A55Ah
    jne goto_video_bad
    clc
    ret
goto_video_bad:
    stc
    ret
TestGotoVideo endp
