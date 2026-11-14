_TEXT ends
_DATA segment word public use16 'DATA'
caseSaveUI db 'universal F2 prefill/edit/cancel/save-as/error/savepoint behavior',13,10,'$'
caseSaveUIVideo db 'universal F2 prompt/input colours, scrolling and cursor bounds',13,10,'$'
saveUIName1 db 'BUILD\TESTDATA\SAVE1.BIN',0
saveUIName2 db 'BUILD\TESTDATA\SAVE2.BIN',0
saveUIDoc db 'SAVE',0
saveUIOldName db PATH_BYTES dup (0)
_DATA ends
_TEXT segment word public use16 'CODE'

TypeSaveString proc
save_ui_type:
    lodsb
    test al,al
    jz save_ui_typed
    push si
    call HandleSaveKey
    pop si
    jmp save_ui_type
save_ui_typed:
    ret
TypeSaveString endp

; SI desired path. Typing replaces the selected, prefilled current filename.
AcceptSaveName proc
    push si
    call ResetSaveInput
    pop si
    call TypeSaveString
    mov al,13
    call HandleSaveKey
    ret
AcceptSaveName endp

TestUniversalSave proc
    mov testCase,offset caseSaveUI
    mov dx,offset saveUIName1
    mov ah,41h
    int 21h
    mov dx,offset saveUIName2
    mov ah,41h
    int 21h
    mov al,2
    call FreshUndoDocument
    mov si,offset saveUIName1
    mov di,offset fileName
    call TestCopyString
    mov si,offset saveUIDoc
save_ui_document:
    lodsb
    test al,al
    jz save_ui_document_ready
    push si
    call HandleKey
    pop si
    jmp save_ui_document
save_ui_document_ready:
    call ResetSaveInput
    cmp saveInputSelected,1
    jne save_ui_bad
    mov si,offset inputPath
    mov di,offset saveUIName1
    call TestCompareStrings
    jc save_ui_bad
    mov al,27
    call HandleSaveKey
    cmp saveInputDone,2
    jne save_ui_bad
    cmp dirty,1
    jne save_ui_bad
    cmp historyCount,4
    jne save_ui_bad
    mov dx,offset saveUIName1
    mov ax,4300h
    int 21h
    jnc save_ui_bad                 ; cancellation did not create a file
    call ResetSaveInput
    mov al,13
    call HandleSaveKey
    jc save_ui_bad
    cmp saveInputDone,1
    jne save_ui_bad
    cmp dirty,0
    jne save_ui_bad
    cmp historyCount,4
    jne save_ui_bad
    call UndoChange
    cmp dirty,1
    jne save_ui_bad
    call RedoChange
    cmp dirty,0
    jne save_ui_bad
    call ResetSaveInput
    mov si,offset saveUIName2
    call TypeSaveString
    mov al,27
    call HandleSaveKey
    mov si,offset fileName
    mov di,offset saveUIName1
    call TestCompareStrings
    jc save_ui_bad
    mov dx,offset saveUIName2
    mov ax,4300h
    int 21h
    jnc save_ui_bad
    mov si,offset saveUIName2
    call AcceptSaveName
    jc save_ui_bad
    mov si,offset fileName
    mov di,offset saveUIName2
    call TestCompareStrings
    jc save_ui_bad
    cmp historyCount,4
    jne save_ui_bad
    mov ebp,45564153h               ; both old and new paths contain SAVE
    mov dx,offset saveUIName1
    call FaultCheckFile
    jc save_ui_bad
    mov dx,offset saveUIName2
    call FaultCheckFile
    jc save_ui_bad
    mov cursorOffset,0
    mov al,'X'
    call HandleKey
    mov si,offset badPath
    call AcceptSaveName
    jnc save_ui_bad
    cmp saveInputDone,3
    jne save_ui_bad
    cmp dirty,1
    jne save_ui_bad
    mov si,offset fileName
    mov di,offset saveUIName2
    call TestCompareStrings
    jc save_ui_bad
    call UndoChange
    cmp dirty,0
    jne save_ui_bad
    call RedoChange
    cmp dirty,1
    jne save_ui_bad
    call ResetSaveInput
    mov al,13
    call HandleSaveKey
    jc save_ui_bad
    mov ebp,45564158h               ; Enter saved XAVE to the existing active path
    mov dx,offset saveUIName2
    call FaultCheckFile
    jc save_ui_bad
    mov si,offset directoryPath
    call AcceptSaveName
    jnc save_ui_bad
    cmp dirty,0
    jne save_ui_bad
    mov si,offset fileName
    mov di,offset saveUIName2
    call TestCompareStrings
    jc save_ui_bad
    call ResetSaveInput
    mov ax,4F00h                   ; End edits the existing name instead of replacing
    call HandleSaveKey
    mov al,8
    call HandleSaveKey
    mov al,'N'
    call HandleSaveKey
    mov ax,4700h
    call HandleSaveKey
    mov ax,4D00h
    call HandleSaveKey
    mov ax,5300h
    call HandleSaveKey
    mov al,'U'
    call HandleSaveKey
    mov ax,4B00h
    call HandleSaveKey
    mov al,8
    call HandleSaveKey
    mov al,'B'
    call HandleSaveKey
    mov si,offset inputPath
    mov di,offset saveUIName2
    call TestCompareStrings
    jc save_ui_bad
    mov al,27
    call HandleSaveKey
    call ResetSaveInput
    mov al,8                       ; Backspace clears the preselected name
    call HandleSaveKey
    mov al,13
    call HandleSaveKey
    cmp saveInputDone,0
    jne save_ui_bad
    cmp saveInputError,offset saveEmptyText
    jne save_ui_bad
    call ResetSaveInput
    mov cx,PATH_BYTES+3
save_ui_long_input:
    mov al,'A'
    push cx
    call HandleSaveKey
    pop cx
    loop save_ui_long_input
    cmp dialogLength,PATH_BYTES-1
    jne save_ui_bad
    cmp inputPath+PATH_BYTES-1,0
    jne save_ui_bad
    mov al,13
    call HandleSaveKey
    cmp saveInputDone,0
    jne save_ui_bad
    cmp saveInputError,offset saveLongText
    jne save_ui_bad
    mov al,8
    call HandleSaveKey
    cmp saveInputOverflow,0
    jne save_ui_bad
    cmp dialogLength,PATH_BYTES-2
    jne save_ui_bad
    mov al,27
    call HandleSaveKey
    cmp dirty,0
    jne save_ui_bad
    cmp historyCount,5
    jne save_ui_bad
    mov dx,offset saveUIName1
    mov ah,41h
    int 21h
    jc save_ui_bad
    mov dx,offset saveUIName2
    mov ah,41h
    int 21h
    ret
save_ui_bad:
    stc
    ret
TestUniversalSave endp

TestSaveDialogVideo proc
    mov testCase,offset caseSaveUIVideo
    mov si,offset fileName
    mov di,offset saveUIOldName
    call TestCopyString
    mov si,offset saveUIName1
    mov di,offset fileName
    call TestCopyString
    call ResetSaveInput
    call RenderSaveDialog
    cmp word ptr es:[23*160],0753h ; gray Save prompt
    jne save_ui_video_bad
    cmp word ptr es:[24*160],0D42h ; purple prefilled path
    jne save_ui_video_bad
    mov ah,03h
    xor bh,bh
    int 10h
    cmp dx,1818h                   ; caret after 24-character current filename
    jne save_ui_video_bad
    mov si,offset fileName
    mov cx,PATH_BYTES-1
save_ui_video_long_name:
    mov byte ptr [si],'P'
    inc si
    loop save_ui_video_long_name
    mov byte ptr [si],0
    call ResetSaveInput
    call RenderSaveDialog
    mov ah,03h
    xor bh,bh
    int 10h
    cmp dx,184Dh                   ; scroll a long path, keep cursor at column 77
    jne save_ui_video_bad
    cmp word ptr es:[24*160+79*2],0720h
    jne save_ui_video_bad
    mov ax,4700h
    call HandleSaveKey
    call RenderSaveDialog
    mov ah,03h
    xor bh,bh
    int 10h
    cmp dx,1800h
    jne save_ui_video_bad
    cmp word ptr es:[4000],0A55Ah
    jne save_ui_video_bad
    mov si,offset saveUIOldName
    mov di,offset fileName
    call TestCopyString
    clc
    ret
save_ui_video_bad:
    stc
    ret
TestSaveDialogVideo endp
