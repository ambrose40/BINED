; Included only by TESTS\TEST3.ASM. No test code enters the release EXE.
_TEXT ends
_DATA segment word public use16 'DATA'
testCase        dw 0
testStack       dw 0
testLoops       dw 0
testCapacity    dd 0
testAttrSkipped db 0
testPath        db 'BUILD\TESTDATA\ROUND.BIN',0
emptyPath       db 'BUILD\TESTDATA\EMPTY.BIN',0
badPath         db 'BUILD\NO_SUCH\BAD.BIN',0
directoryPath   db 'BUILD\TESTDATA',0
tailBlank       db '   ',0
tailQuoted      db '  "BUILD\TESTDATA\ROUND.BIN"  ',0
tailMultiple    db 'FIRST.BIN SECOND.BIN',0
tailUnclosed    db '"FIRST.BIN',0
tailHelp        db '/?  ',0
binaryInput     db '10100101',0
testPass        db 'PASS: command tail, memory boundaries, editing, navigation,',13,10
                db '      10000 dispatches, rendering, DOS load/save and errors.',13,10,'$'
testAttrNote    db 'NOTE: mounted DOS drive ignores read-only attributes;',13,10
                db '      directory-target protection tested instead.',13,10,'$'
testFail        db 'FAIL: $'
testNewline     db 13,10,'$'
caseMemory      db 'DOS buffer allocation',13,10,'$'
caseParse       db 'PSP command-tail parser',13,10,'$'
caseEditing     db 'hex/binary overwrite and EOF append',13,10,'$'
caseAscii       db 'ASCII input, mode cycling, navigation and EOF append',13,10,'$'
caseBoundary    db 'insert/delete across 64 KiB boundaries',13,10,'$'
caseFull        db 'full-buffer and empty-file bounds',13,10,'$'
caseNavigation  db 'navigation and viewport bounds',13,10,'$'
caseStack       db '10000 dispatches preserve SP',13,10,'$'
caseVideo       db 'hex/binary/ASCII rendering, cursor and screen bounds',13,10,'$'
caseHelp        db 'modal help layout, bounds and editor redraw',13,10,'$'
caseFiles       db 'multi-chunk DOS save/load and safe replacement',13,10,'$'
caseReadOnly    db 'read-only save must fail and retain dirty flag',13,10,'$'
caseSetAttr     db 'DOS set read-only attribute',13,10,'$'
caseDirty       db 'failed save retains dirty flag',13,10,'$'
caseBadPath     db 'invalid save path must fail',13,10,'$'
caseUnchanged   db 'failed save retains original contents',13,10,'$'
caseOversized   db 'oversized file must fail with AX=8',13,10,'$'
caseShort       db 'incomplete DOS transfer must fail',13,10,'$'
caseEmpty       db 'zero-byte save/load',13,10,'$'
_DATA ends
_TEXT segment word public use16 'CODE'

; Assertions live in RunTests, so failure always returns directly to Main.
CHECK32 macro actual, expected
    cmp actual,expected
    jne TestFailed
endm
CHECKBYTE macro address, expected
    mov eax,address
    call ReadByte
    cmp al,expected
    jne TestFailed
endm

RunTests proc
    mov testCase,offset caseMemory
    cmp bufferCapacity,20011h
    jb TestFailed
    mov testCase,offset caseParse
    mov si,offset tailBlank
    call TestSetTail
    call ParseCommandLine
    jc TestFailed
    mov si,offset tailQuoted
    call TestSetTail
    call ParseCommandLine
    jc TestFailed
    mov si,offset fileName
    mov di,offset testPath
    call TestCompareStrings
    jc TestFailed
    mov si,offset tailMultiple
    call TestSetTail
    call ParseCommandLine
    jnc TestFailed
    mov si,offset tailUnclosed
    call TestSetTail
    call ParseCommandLine
    jnc TestFailed
    mov si,offset tailHelp
    call TestSetTail
    call ParseCommandLine
    jnc TestFailed
    cmp ax,1
    jne TestFailed

    mov testCase,offset caseEditing
    mov fileSize,0
    mov cursorOffset,0
    xor al,al
    call SetMode
    mov al,'a'
    call HandleKey
    CHECK32 fileSize,1
    CHECK32 cursorOffset,0
    cmp digitIndex,1
    jne TestFailed
    mov al,'b'
    call HandleKey
    CHECKBYTE 0,0ABh
    CHECK32 cursorOffset,1
    mov ax,7700h
    call HandleKey
    mov ax,3F00h
    call HandleKey
    mov si,offset binaryInput
test_binary_keys:
    lodsb
    or al,al
    jz test_binary_complete
    push si
    call HandleKey
    pop si
    jmp test_binary_keys
test_binary_complete:
    CHECKBYTE 0,0A5h
    CHECK32 fileSize,1
    CHECK32 cursorOffset,1
    mov al,'2'                    ; binary rejects 2, does not append
    call HandleKey
    CHECK32 fileSize,1
    mov al,'1'
    call HandleKey
    CHECKBYTE 1,80h
    CHECK32 fileSize,2
    mov ax,4000h
    call HandleKey
    CHECKBYTE 0,0A5h
    mov testCase,offset caseAscii
    mov ax,4100h                  ; F7 selects ASCII, preserving bytes/offset
    call HandleKey
    cmp editMode,2
    jne TestFailed
    cmp digitIndex,0
    jne TestFailed
    cmp digitsPerByte,1
    jne TestFailed
    CHECK32 bytesPerRow,16
    CHECK32 pageBytes,320
    CHECK32 cursorOffset,1
    CHECKBYTE 0,0A5h
    mov al,'z'                    ; whole-byte overwrite, preserving case
    call HandleKey
    CHECKBYTE 1,'z'
    CHECK32 cursorOffset,2
    CHECK32 fileSize,2
    mov al,' '                    ; ASCII space appends, rather than skipping
    call HandleKey
    CHECKBYTE 2,20h
    CHECK32 fileSize,3
    CHECK32 cursorOffset,3
    mov dirty,0
    mov ax,000Dh                  ; Enter, controls, DEL and high bytes ignored
    call HandleKey
    mov ax,0001h
    call HandleKey
    mov ax,007Fh
    call HandleKey
    mov ax,00FFh
    call HandleKey
    CHECK32 fileSize,3
    CHECK32 cursorOffset,3
    cmp dirty,0
    jne TestFailed
    mov al,8                      ; Backspace navigates without deleting
    call HandleKey
    mov al,' '
    call HandleKey
    CHECK32 fileSize,3
    cmp dirty,0                   ; identical overwrite leaves clean state
    jne TestFailed
    mov ax,4B00h
    call HandleKey
    CHECK32 cursorOffset,2
    mov ax,4D00h
    call HandleKey
    CHECK32 cursorOffset,3
    mov testLoops,20h             ; every printable ASCII character appends
test_ascii_printable:
    mov ax,testLoops
    call HandleKey
    movzx eax,testLoops
    sub eax,20h
    add eax,3
    call ReadByte
    cmp al,byte ptr testLoops
    jne TestFailed
    inc testLoops
    cmp testLoops,7Fh
    jb test_ascii_printable
    CHECK32 fileSize,98
    CHECK32 cursorOffset,98
    mov ax,4700h                  ; ASCII Home/End and row movement
    call HandleKey
    CHECK32 cursorOffset,96
    mov ax,4800h
    call HandleKey
    CHECK32 cursorOffset,80
    mov ax,4F00h
    call HandleKey
    CHECK32 cursorOffset,95
    cmp digitIndex,0
    jne TestFailed
    mov ax,5000h
    call HandleKey
    CHECK32 cursorOffset,98
    mov dirty,0
    mov al,9                      ; Tab preserves ASCII: HEX -> BIN -> HEX
    call HandleKey
    cmp editMode,2
    jne TestFailed
    cmp viewMode,1
    jne TestFailed
    cmp digitsPerByte,1
    jne TestFailed
    CHECK32 bytesPerRow,6
    mov al,9
    call HandleKey
    cmp editMode,2
    jne TestFailed
    cmp viewMode,0
    jne TestFailed
    CHECK32 bytesPerRow,16
    mov viewOffset,16
    mov ax,4100h                  ; F7 returns to numeric HEX in the same view
    call HandleKey
    cmp editMode,0
    jne TestFailed
    cmp digitsPerByte,2
    jne TestFailed
    CHECK32 viewOffset,16
    mov al,9                      ; numeric Tab still switches HEX -> BIN -> HEX
    call HandleKey
    cmp editMode,1
    jne TestFailed
    cmp digitsPerByte,8
    jne TestFailed
    mov al,9
    call HandleKey
    cmp editMode,0
    jne TestFailed
    mov ax,4100h
    call HandleKey
    cmp editMode,2
    jne TestFailed
    CHECK32 cursorOffset,98
    cmp dirty,0
    jne TestFailed
    CHECKBYTE 1,'z'
    CHECKBYTE 2,20h
    mov cursorOffset,0FFFFh        ; ASCII overwrite crosses normalized segments
    mov fileSize,10001h
    mov al,'A'
    call HandleKey
    mov al,'b'
    call HandleKey
    CHECKBYTE 0FFFFh,'A'
    CHECKBYTE 10000h,'b'
    CHECK32 fileSize,10001h
    mov fileSize,0
    mov cursorOffset,0
    mov al,'Q'                    ; empty ASCII document appends a whole byte
    call HandleKey
    CHECK32 fileSize,1
    CHECKBYTE 0,'Q'
    mov ax,4B00h
    call HandleKey
    mov ax,5200h                  ; Insert/Delete retain byte semantics in ASCII
    call HandleKey
    CHECK32 fileSize,2
    CHECKBYTE 0,0
    CHECKBYTE 1,'Q'
    mov al,' '
    call HandleKey
    mov ax,4B00h
    call HandleKey
    mov ax,5300h
    call HandleKey
    CHECK32 fileSize,1
    CHECKBYTE 0,'Q'
    mov ax,3F00h                  ; BIN -> F7 keeps six-byte binary layout
    call HandleKey
    mov digitIndex,7
    mov viewOffset,6
    mov ax,4100h
    call HandleKey
    cmp editMode,2
    jne TestFailed
    cmp viewMode,1
    jne TestFailed
    cmp digitIndex,0
    jne TestFailed
    cmp digitsPerByte,1
    jne TestFailed
    CHECK32 bytesPerRow,6
    CHECK32 pageBytes,120
    CHECK32 viewOffset,6           ; F7 preserves current viewport
    mov ax,4100h                  ; F7 toggles back to binary bits, not HEX
    call HandleKey
    cmp editMode,1
    jne TestFailed
    cmp viewMode,1
    jne TestFailed
    cmp digitsPerByte,8
    jne TestFailed
    CHECK32 viewOffset,6
    mov ax,4100h
    call HandleKey
    mov cursorOffset,0
    mov al,'z'
    call HandleKey
    mov al,' '
    call HandleKey
    mov al,'!'
    call HandleKey
    CHECKBYTE 0,'z'
    CHECKBYTE 1,20h
    CHECKBYTE 2,'!'
    CHECK32 fileSize,3
    CHECK32 cursorOffset,3
    mov fileSize,40
    mov cursorOffset,17
    mov ax,4700h                  ; binary ASCII rows contain six bytes
    call HandleKey
    CHECK32 cursorOffset,12
    mov ax,5000h
    call HandleKey
    CHECK32 cursorOffset,18
    mov ax,4F00h
    call HandleKey
    CHECK32 cursorOffset,23
    mov ax,4800h
    call HandleKey
    CHECK32 cursorOffset,17
    mov ax,4900h
    call HandleKey
    CHECK32 cursorOffset,0
    mov ax,5100h
    call HandleKey
    CHECK32 cursorOffset,40
    mov dirty,0
    mov al,9                      ; ASCII (BIN) -> ASCII (HEX)
    call HandleKey
    cmp editMode,2
    jne TestFailed
    cmp viewMode,0
    jne TestFailed
    cmp digitsPerByte,1
    jne TestFailed
    cmp dirty,0
    jne TestFailed
    CHECK32 cursorOffset,40
    CHECKBYTE 0,'z'
    CHECKBYTE 1,20h
    CHECKBYTE 2,'!'
    mov ax,4000h
    call HandleKey
    mov testCase,offset caseBoundary
    mov fileSize,20011h
    call TestFillPattern
    mov cursorOffset,0FFFFh
    call InsertByte
    CHECK32 fileSize,20012h
    CHECKBYTE 0FFFFh,0
    CHECKBYTE 10000h,5Ah           ; original pattern byte at FFFF
    CHECKBYTE 10001h,5Ah           ; original pattern byte at 10000
    call DeleteByte
    CHECK32 fileSize,20011h
    call TestVerifyPattern
    jc TestFailed
    mov cursorOffset,0
    call InsertByte
    call DeleteByte
    call TestVerifyPattern
    jc TestFailed

    mov testCase,offset caseFull
    mov eax,bufferCapacity
    mov fileSize,eax
    mov cursorOffset,eax
    call InsertByte
    mov eax,bufferCapacity
    CHECK32 fileSize,eax
    mov al,'F'
    call EditDigit
    mov eax,bufferCapacity
    CHECK32 fileSize,eax
    mov ax,4100h
    call HandleKey
    mov dirty,0
    mov al,'X'
    call HandleKey
    mov eax,bufferCapacity
    CHECK32 fileSize,eax
    CHECK32 cursorOffset,eax
    cmp dirty,0
    jne TestFailed
    cmp statusText,offset msgFull
    jne TestFailed
    dec cursorOffset
    mov al,'!'
    call HandleKey
    mov eax,bufferCapacity
    dec eax
    call ReadByte
    cmp al,'!'
    jne TestFailed
    mov ax,4000h
    call HandleKey
    call DeleteByte               ; EOF delete must be a no-op
    mov eax,bufferCapacity
    CHECK32 fileSize,eax
    dec eax
    mov cursorOffset,eax
    mov digitIndex,0
    mov al,'5'
    call EditDigit
    mov al,'C'
    call EditDigit
    mov eax,bufferCapacity
    dec eax
    call ReadByte
    cmp al,5Ch
    jne TestFailed
    mov fileSize,0
    mov cursorOffset,0
    call DeleteByte
    CHECK32 fileSize,0
    call MoveLeft
    CHECK32 cursorOffset,0

    mov testCase,offset caseNavigation
    mov fileSize,20011h
    mov cursorOffset,0
    mov viewOffset,0
    mov ax,4900h
    call HandleKey
    CHECK32 cursorOffset,0
    mov ax,7500h
    call HandleKey
    call EnsureVisible
    mov eax,viewOffset
    add eax,pageBytes
    cmp eax,cursorOffset
    jbe TestFailed
    mov ax,7700h
    call HandleKey
    call EnsureVisible
    CHECK32 viewOffset,0
    mov cursorOffset,17
    mov ax,4700h
    call HandleKey
    CHECK32 cursorOffset,16
    mov ax,4F00h
    call HandleKey
    CHECK32 cursorOffset,31
    mov ax,7500h
    call HandleKey
    mov ax,3F00h
    call HandleKey
    call EnsureVisible
    mov eax,viewOffset
    xor edx,edx
    div bytesPerRow
    test edx,edx
    jnz TestFailed

    mov testCase,offset caseStack
    mov testStack,sp
    mov testLoops,10000
test_dispatch_loop:
    mov ax,4000h
    call HandleKey
    mov ax,5100h
    call HandleKey
    mov ax,4B00h
    call HandleKey
    mov ax,3F00h
    call HandleKey
    mov ax,4900h
    call HandleKey
    mov ax,4D00h
    call HandleKey
    mov ax,4100h
    call HandleKey
    mov ax,4B00h
    call HandleKey
    mov ax,4D00h
    call HandleKey
    call EnsureVisible
    cmp sp,testStack
    jne TestFailed
    dec testLoops
    jnz test_dispatch_loop

    mov testCase,offset caseVideo
    call BeginVideo
    xor al,al
    call SetMode
    mov fileSize,1
    mov cursorOffset,0
    xor eax,eax
    mov dl,0A5h
    call WriteByte
    mov ax,0B800h
    mov es,ax
    mov word ptr es:[4000],0A55Ah
    mov statusText,offset msgReady
    call EnsureVisible
    call RenderScreen
    cmp word ptr es:[4000],0A55Ah
    jne TestFailed
    cmp word ptr es:[2*160+10*2],0D41h  ; purple selected 'A', black background
    jne TestFailed
    cmp byte ptr es:[2*160+11*2],'5'
    jne TestFailed
    cmp word ptr es:[1*2],0F45h        ; bright-white title 'E'
    jne TestFailed
    cmp word ptr es:[(hexText-titleText-1)*2],0E48h ; yellow HEX mode 'H'
    jne TestFailed
    cmp word ptr es:[160+1*2],0C4Fh    ; bright-red OFFSET heading 'O'
    jne TestFailed
    cmp word ptr es:[160+10*2],0C44h   ; bright-red DATA heading 'D'
    jne TestFailed
    cmp word ptr es:[160+61*2],0C41h   ; bright-red ASCII heading 'A'
    jne TestFailed
    cmp word ptr es:[2*160+61*2],072Eh ; gray ASCII dot, even for selected byte
    jne TestFailed
    cmp word ptr es:[22*160+8*2],0530h  ; dark-purple Offset value
    jne TestFailed
    cmp word ptr es:[22*160+24*2+7*2],0531h ; dark-purple Size value: ...1
    jne TestFailed
    cmp byte ptr es:[22*160+44*2+1],05h ; dark-purple Capacity value
    jne TestFailed
    cmp word ptr es:[22*160],0A4Fh     ; green 'O' label
    jne TestFailed
    cmp word ptr es:[24*160],0746h     ; light-gray 'F' of F1 Help
    jne TestFailed
    mov ah,03h
    xor bh,bh
    int 10h
    cmp dx,020Ah
    jne TestFailed
    mov al,1
    call SetMode
    call RenderScreen
    cmp byte ptr es:[2*160+10*2],'1'
    jne TestFailed
    cmp byte ptr es:[2*160+11*2],'0'
    jne TestFailed
    cmp word ptr es:[(hexText-titleText-1)*2],0E42h ; yellow BIN mode 'B'
    jne TestFailed
    cmp word ptr es:[160+66*2],0C41h   ; red ASCII heading in binary mode
    jne TestFailed
    cmp word ptr es:[2*160+66*2],072Eh ; gray ASCII preview in binary mode
    jne TestFailed
    mov cursorOffset,1
    call RenderScreen
    cmp word ptr es:[2*160+19*2],0D2Dh ; purple selected EOF '-', black background
    jne TestFailed

    xor al,al
    call SetMode
    mov al,2
    call SetMode
    mov cursorOffset,0
    call RenderScreen
    cmp word ptr es:[(hexText-titleText-1)*2],0E41h ; yellow ASCII mode 'A'
    jne TestFailed
    cmp word ptr es:[2*160+61*2],0D2Eh ; selected non-printable '.' is purple
    jne TestFailed
    cmp byte ptr es:[2*160+10*2],'A' ; ASCII still displays two hex digits
    jne TestFailed
    cmp byte ptr es:[2*160+11*2],'5'
    jne TestFailed
    mov ah,03h
    xor bh,bh
    int 10h
    cmp dx,023Dh                  ; editing cursor in right-hand ASCII column
    jne TestFailed
    xor eax,eax
    mov dl,'Q'
    call WriteByte
    call RenderScreen
    cmp word ptr es:[2*160+61*2],0D51h ; selected printable Q
    jne TestFailed
    mov cursorOffset,1
    call RenderScreen
    cmp word ptr es:[2*160+61*2],0751h ; unselected ASCII remains gray
    jne TestFailed
    cmp word ptr es:[2*160+62*2],0D2Dh ; EOF visible in ASCII edit column
    jne TestFailed
    mov fileSize,320
    mov cursorOffset,320
    call EnsureVisible
    CHECK32 viewOffset,16
    call RenderScreen
    mov ah,03h
    xor bh,bh
    int 10h
    cmp dx,153Dh                  ; EOF scrolled to last data row, ASCII col 61
    jne TestFailed
    cmp word ptr es:[4000],0A55Ah
    jne TestFailed
    mov fileSize,1
    mov cursorOffset,1
    xor eax,eax
    mov dl,0A5h
    call WriteByte
    mov al,1
    call SetMode
    mov cursorOffset,0
    mov al,2
    call SetMode
    call RenderScreen
    cmp word ptr es:[(hexText-titleText-1+7)*2],0E42h ; ASCII (BIN) label B
    jne TestFailed
    cmp word ptr es:[160+66*2],0C41h ; ASCII header stays at binary column
    jne TestFailed
    cmp word ptr es:[2*160+66*2],0D2Eh ; selected ASCII dot in binary view
    jne TestFailed
    cmp byte ptr es:[2*160+10*2],'1' ; binary digits retained: 10100101
    jne TestFailed
    cmp byte ptr es:[2*160+11*2],'0'
    jne TestFailed
    cmp byte ptr es:[2*160+17*2],'1'
    jne TestFailed
    mov ah,03h
    xor bh,bh
    int 10h
    cmp dx,0242h                  ; ASCII editing starts at binary column 66
    jne TestFailed
    mov cursorOffset,1
    call RenderScreen
    cmp word ptr es:[2*160+66*2],072Eh ; unselected ASCII remains gray
    jne TestFailed
    cmp word ptr es:[2*160+67*2],0D2Dh ; ASCII EOF follows byte in binary view
    jne TestFailed
    mov fileSize,120
    mov cursorOffset,120
    call EnsureVisible
    CHECK32 viewOffset,6
    call RenderScreen
    mov ah,03h
    xor bh,bh
    int 10h
    cmp dx,1542h                  ; scrolled binary ASCII EOF, last data row
    jne TestFailed
    cmp word ptr es:[4000],0A55Ah
    jne TestFailed
    mov fileSize,1
    mov cursorOffset,1
    mov al,1
    call SetMode
    call EnsureVisible
    call RenderScreen

    mov testCase,offset caseHelp
    ; Marker inside must be cleared; markers immediately outside must survive.
    mov word ptr es:[3*160+12*2],0F58h
    mov word ptr es:[4*160+10*2],0F4Ch
    mov word ptr es:[4*160+69*2],0F52h
    call RenderHelpWindow
    cmp word ptr es:[3*160+12*2],0A20h
    jne TestFailed
    cmp word ptr es:[4*160+10*2],0F4Ch
    jne TestFailed
    cmp word ptr es:[4*160+69*2],0F52h
    jne TestFailed
    cmp word ptr es:[2*160+11*2],0DDAh ; purple top-left border
    jne TestFailed
    cmp word ptr es:[22*160+68*2],0DD9h ; purple bottom-right border
    jne TestFailed
    cmp word ptr es:[4*160+13*2],0E41h ; yellow Arrows key label
    jne TestFailed
    cmp word ptr es:[5*160+13*2],0E50h ; yellow PgUp key label
    jne TestFailed
    cmp word ptr es:[6*160+13*2],0E48h ; yellow Home key label
    jne TestFailed
    cmp word ptr es:[4*160+21*2],076Dh ; light-gray 'm' in move description
    jne TestFailed
    cmp word ptr es:[9*160+13*2],0E30h ; yellow editable-digit key label
    jne TestFailed
    cmp word ptr es:[11*160+13*2],0741h ; no-colon EOF sentence stays light gray
    jne TestFailed
    cmp word ptr es:[10*160+13*2],0E41h ; yellow ASCII input label
    jne TestFailed
    cmp word ptr es:[18*160+14*2],0E37h ; yellow F7 mode key
    jne TestFailed
    cmp word ptr es:[19*160+13*2],0E54h ; yellow Tab cycle key
    jne TestFailed
    cmp word ptr es:[21*160+13*2],0E41h ; yellow Any-key label
    jne TestFailed
    cmp word ptr es:[21*160+22*2],0272h ; dark-green 'r' in return prompt
    jne TestFailed
    cmp word ptr es:[4000],0A55Ah
    jne TestFailed
    call RenderScreen
    cmp word ptr es:[3*160+11*2],0A20h ; help border removed on redraw
    jne TestFailed
    cmp word ptr es:[2*160+19*2],0D2Dh ; selected EOF restored
    jne TestFailed
    CHECK32 fileSize,1
    CHECK32 cursorOffset,1
    CHECKBYTE 0,0A5h
    call EndVideo
    mov videoActive,0

    mov testCase,offset caseFiles
    mov fileSize,20011h
    call TestFillPattern
    mov dx,offset testPath
    call SaveDocument
    jc TestFailed
    cmp dirty,0
    jne TestFailed
    ; Save over the existing file, exercising the backup/rename path too.
    mov dirty,1
    mov dx,offset testPath
    call SaveDocument
    jc TestFailed
    mov si,offset testPath
    mov di,offset fileName
    call TestCopyString
    mov eax,10000h
    mov dl,0FFh
    call WriteByte
    call LoadFile
    jc TestFailed
    CHECK32 fileSize,20011h
    call TestVerifyPattern
    jc TestFailed

    mov testCase,offset caseSetAttr
    mov dx,offset testPath
    mov cx,1
    mov ax,4301h
    int 21h
    jc TestFailed
    mov dx,offset testPath
    mov ax,4300h
    int 21h
    jc TestFailed
    test cx,1
    jnz test_read_only_supported
    mov testAttrSkipped,1
    mov dx,offset directoryPath
    jmp test_protected_save
test_read_only_supported:
    mov dx,offset testPath
test_protected_save:
    mov testCase,offset caseReadOnly
    mov dirty,1
    call SaveDocument
    jnc TestFailed
    mov testCase,offset caseDirty
    cmp dirty,1
    jne TestFailed
    mov dx,offset testPath
    xor cx,cx
    mov ax,4301h
    int 21h
    jc TestFailed
    mov testCase,offset caseBadPath
    mov dx,offset badPath
    call SaveDocument
    jnc TestFailed
    mov testCase,offset caseUnchanged
    call LoadFile
    jc TestFailed
    call TestVerifyPattern
    jc TestFailed
    mov testCase,offset caseOversized
    mov eax,bufferCapacity
    mov testCapacity,eax
    mov bufferCapacity,20010h
    call LoadFile
    pushf
    mov edx,testCapacity
    mov bufferCapacity,edx
    popf
    jnc TestFailed
    cmp ax,8
    jne TestFailed
    mov testCase,offset caseShort
    mov dx,offset testPath
    mov ax,3D00h
    int 21h
    jc TestFailed
    mov fileHandle,ax
    mov ioRemaining,20012h          ; request one byte beyond actual EOF
    mov ioOffset,0
    mov ioOperation,3Fh
    call TransferFile
    pushf
    call CloseFile
    popf
    jnc TestFailed

    mov testCase,offset caseEmpty
    mov fileSize,0
    mov dx,offset emptyPath
    call SaveDocument
    jc TestFailed
    mov si,offset emptyPath
    mov di,offset fileName
    call TestCopyString
    mov fileSize,99
    call LoadFile
    jc TestFailed
    CHECK32 fileSize,0
    mov dx,offset testPass
    mov ah,09h
    int 21h
    cmp testAttrSkipped,0
    je test_all_done
    mov dx,offset testAttrNote
    mov ah,09h
    int 21h
test_all_done:
    xor al,al
    ret
TestFailed:
    mov dx,offset testFail
    mov ah,09h
    int 21h
    mov dx,testCase
    mov ah,09h
    int 21h
    mov al,1
    ret
RunTests endp

TestSetTail proc
    push es
    mov es,pspSegment
    mov di,81h
    xor cx,cx
test_tail_copy:
    lodsb
    or al,al
    jz test_tail_done
    stosb
    inc cx
    jmp test_tail_copy
test_tail_done:
    mov byte ptr es:[di],13
    mov es:[80h],cl
    pop es
    ret
TestSetTail endp

TestCopyString proc
test_copy_string:
    lodsb
    mov [di],al
    inc di
    or al,al
    jnz test_copy_string
    ret
TestCopyString endp

TestCompareStrings proc
test_compare_next:
    lodsb
    cmp al,[di]
    jne test_compare_bad
    inc di
    or al,al
    jnz test_compare_next
    clc
    ret
test_compare_bad:
    stc
    ret
TestCompareStrings endp

TestFillPattern proc
    xor esi,esi
test_fill_next:
    cmp esi,fileSize
    jae test_fill_done
    mov eax,esi
    mov dl,al
    xor dl,ah
    xor dl,5Ah
    call WriteByte
    inc esi
    jmp test_fill_next
test_fill_done:
    ret
TestFillPattern endp

TestVerifyPattern proc
    xor esi,esi
test_verify_next:
    cmp esi,fileSize
    jae test_verify_done
    mov eax,esi
    mov dl,al
    xor dl,ah
    xor dl,5Ah
    call ReadByte
    cmp al,dl
    jne test_verify_bad
    inc esi
    jmp test_verify_next
test_verify_done:
    clc
    ret
test_verify_bad:
    stc
    ret
TestVerifyPattern endp
