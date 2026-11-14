; Included only by TESTS\TEST3.ASM. No test code enters the release EXE.
_TEXT ends
_DATA segment word public use16 'DATA'
testCase        dw 0
testStack       dw 0
testLoops       dw 0
testCapacity    dd 0
testAttrSkipped db 0
textRowScans    dd 0
searchReadCount dd 0
cacheTarget     dd 0
cacheExpected   dd 4 dup (0)
boundaryLength  dd 0
boundaryTerm    dw 0
boundaryLengths dd 79,80,81,159,160,0
boundaryIndex   dw 0
testPath        db 'BUILD\TESTDATA\ROUND.BIN',0
emptyPath       db 'BUILD\TESTDATA\EMPTY.BIN',0
textPath        db 'BUILD\TESTDATA\TEXT.BIN',0
textFixture     db 'AB',13,10,'C',10,'DEF',13,'G'
textFixtureEnd  label byte
tabFixture      db 'A',9,'B',13,10,'0123456789',13,10,'x'
tabFixtureEnd   label byte
badPath         db 'BUILD\NO_SUCH\BAD.BIN',0
directoryPath   db 'BUILD\TESTDATA',0
tailBlank       db '   ',0
tailQuoted      db '  "BUILD\TESTDATA\ROUND.BIN"  ',0
tailMultiple    db 'FIRST.BIN SECOND.BIN',0
tailUnclosed    db '"FIRST.BIN',0
tailHelp        db '/?  ',0
binaryInput     db '10100101',0
testPass        db 'PASS: HEX/BIN/ASCII/Text, CR/LF/tab editing and navigation,',13,10
                db '      stack balance, rendering, command tail and DOS load/save.',13,10,'$'
testAttrNote    db 'NOTE: mounted DOS drive ignores read-only attributes;',13,10
                db '      directory-target protection tested instead.',13,10,'$'
testFail        db 'FAIL: $'
testNewline     db 13,10,'$'
caseMemory      db 'DOS buffer allocation',13,10,'$'
caseParse       db 'PSP command-tail parser',13,10,'$'
caseEditing     db 'hex/binary overwrite and EOF append',13,10,'$'
caseAscii       db 'ASCII input, mode cycling, navigation and EOF append',13,10,'$'
caseText        db 'Text insertion, CR/LF, navigation, bounds and round trip',13,10,'$'
caseTextFull    db 'Text full-buffer and atomic CR/LF insertion',13,10,'$'
caseTextNav     db 'Text mixed-newline navigation',13,10,'$'
caseTextBound   db 'Text CR/LF insertion/deletion across 64 KiB',13,10,'$'
caseTextStack   db 'Text insert/newline/backspace stack balance',13,10,'$'
caseTextVideo   db 'full-screen Text colours, wrapping, scrolling and values',13,10,'$'
caseTextTyped   db 'Text selected/typed byte inspector and EOF',13,10,'$'
caseTextWrap    db 'Text hard wrapping and screen bounds',13,10,'$'
caseTextLines   db 'Text empty-line scrolling and empty document',13,10,'$'
caseTextEdges   db '79/80/81/159/160-column EOF/newline/tab boundaries',13,10,'$'
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
    mov ax,0009h                  ; Tab selects ASCII, preserving bytes/offset
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
    mov viewOffset,16
    mov al,9                      ; Tab returns to numeric HEX in the same view
    call HandleKey
    cmp editMode,0
    jne TestFailed
    cmp digitsPerByte,2
    jne TestFailed
    CHECK32 viewOffset,16
    mov ax,3F00h                  ; F5 selects binary numeric editing
    call HandleKey
    cmp editMode,1
    jne TestFailed
    cmp digitsPerByte,8
    jne TestFailed
    mov al,9
    call HandleKey
    cmp editMode,2
    jne TestFailed
    cmp viewMode,1
    jne TestFailed
    CHECK32 bytesPerRow,6
    mov al,9
    call HandleKey
    cmp editMode,1
    jne TestFailed
    mov ax,4000h                  ; F6 selects HEX
    call HandleKey
    cmp editMode,0
    jne TestFailed
    mov al,9
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
    mov ax,3F00h                  ; BIN -> Tab keeps six-byte binary layout
    call HandleKey
    mov digitIndex,7
    mov viewOffset,6
    mov al,9
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
    CHECK32 viewOffset,6           ; Tab preserves current viewport
    mov al,9                      ; Tab toggles back to binary bits, not HEX
    call HandleKey
    cmp editMode,1
    jne TestFailed
    cmp viewMode,1
    jne TestFailed
    cmp digitsPerByte,8
    jne TestFailed
    CHECK32 viewOffset,6
    mov al,9
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
    mov al,9                      ; ASCII (BIN) -> BIN numeric
    call HandleKey
    cmp editMode,1
    jne TestFailed
    cmp viewMode,1
    jne TestFailed
    cmp digitsPerByte,8
    jne TestFailed
    cmp dirty,0
    jne TestFailed
    CHECK32 cursorOffset,40
    CHECKBYTE 0,'z'
    CHECKBYTE 1,20h
    CHECKBYTE 2,'!'
    mov ax,4000h
    call HandleKey

    mov testCase,offset caseText
    call TestTextBoundaries
    jc TestFailed
    mov testCase,offset caseText
    mov fileSize,0
    mov cursorOffset,0
    mov al,3
    call SetMode
    mov ax,4100h                  ; F7 selects full-screen Text
    call HandleKey
    cmp editMode,3
    jne TestFailed
    cmp viewMode,2
    jne TestFailed
    mov al,'A'
    call HandleKey
    mov al,'B'
    call HandleKey
    mov ax,4B00h
    call HandleKey
    mov al,13
    call HandleKey
    CHECK32 fileSize,4
    CHECK32 cursorOffset,3
    CHECKBYTE 0,'A'
    CHECKBYTE 1,13
    CHECKBYTE 2,10
    CHECKBYTE 3,'B'
    mov ax,4B00h                  ; CR/LF is one navigation step
    call HandleKey
    CHECK32 cursorOffset,1
    mov ax,4D00h
    call HandleKey
    CHECK32 cursorOffset,3
    mov al,8                      ; Backspace joins the two lines
    call HandleKey
    CHECK32 fileSize,2
    CHECK32 cursorOffset,1
    CHECKBYTE 0,'A'
    CHECKBYTE 1,'B'
    mov al,13
    call HandleKey
    mov ax,4B00h
    call HandleKey
    mov ax,5300h                  ; Delete joins lines at CR/LF too
    call HandleKey
    CHECK32 fileSize,2
    CHECKBYTE 1,'B'
    mov al,13
    call HandleKey
    mov dx,offset textPath
    call SaveDocument
    jc TestFailed
    mov si,offset textPath
    mov di,offset fileName
    call TestCopyString
    mov fileSize,0
    call LoadFile
    jc TestFailed
    CHECK32 fileSize,4
    CHECKBYTE 0,'A'
    CHECKBYTE 1,13
    CHECKBYTE 2,10
    CHECKBYTE 3,'B'
    mov eax,bufferCapacity
    mov testCase,offset caseTextFull
    mov testCapacity,eax
    mov bufferCapacity,5           ; only one spare byte: Enter must be atomic
    mov cursorOffset,1
    mov dirty,0
    mov al,13
    call HandleKey
    CHECK32 fileSize,4
    CHECK32 cursorOffset,1
    cmp dirty,0
    jne TestFailed
    CHECKBYTE 1,13
    CHECKBYTE 3,'B'
    mov al,'X'
    call HandleKey
    CHECK32 fileSize,5
    CHECKBYTE 1,'X'
    mov dirty,0
    mov al,'Y'
    call HandleKey
    mov al,9
    call HandleKey
    mov al,13
    call HandleKey
    CHECK32 fileSize,5
    CHECK32 cursorOffset,2
    cmp dirty,0
    jne TestFailed
    mov eax,testCapacity
    mov bufferCapacity,eax

    mov fileSize,0
    mov cursorOffset,0
    mov al,'A'
    call HandleKey
    mov al,9                      ; Text Tab inserts one 09 byte, not spaces
    call HandleKey
    mov al,'B'
    call HandleKey
    CHECK32 fileSize,3
    CHECKBYTE 0,'A'
    CHECKBYTE 1,9
    CHECKBYTE 2,'B'
    cmp viewMode,2
    jne TestFailed
    mov fileSize,tabFixtureEnd-tabFixture
    mov si,offset tabFixture
    xor edi,edi
test_tab_fixture:
    lodsb
    mov dl,al
    mov eax,edi
    call WriteByte
    inc edi
    cmp edi,fileSize
    jb test_tab_fixture
    mov cursorOffset,2             ; B is at screen column 8
    call EnsureVisible
    cmp textCursorCol,8
    jne TestFailed
    mov ax,5000h
    call HandleKey
    CHECK32 cursorOffset,13        ; same display column in an ordinary row
    mov ax,4800h
    call HandleKey
    CHECK32 cursorOffset,2
    mov ax,4B00h
    call HandleKey
    CHECK32 cursorOffset,1         ; one cursor position per tab byte
    call EnsureVisible
    cmp textCursorCol,1
    jne TestFailed

    mov testCase,offset caseTextNav
    mov fileSize,textFixtureEnd-textFixture
    xor edi,edi
    mov si,offset textFixture
test_text_fixture:
    lodsb
    mov dl,al
    mov eax,edi
    call WriteByte
    inc edi
    cmp edi,fileSize
    jb test_text_fixture
    mov dirty,0
    mov cursorOffset,7
    mov ax,4700h
    call HandleKey
    CHECK32 cursorOffset,6
    mov ax,4F00h
    call HandleKey
    CHECK32 cursorOffset,9
    mov ax,4800h
    call HandleKey
    CHECK32 cursorOffset,5          ; shorter LF row clamps the column
    mov cursorOffset,8
    mov textGoalValid,0            ; fixture cursor assignment starts a new run
    mov ax,5000h
    call HandleKey
    CHECK32 cursorOffset,11
    mov ax,4800h
    call HandleKey
    CHECK32 cursorOffset,8         ; preferred column survives the short row
    mov cursorOffset,3             ; entering Text on LF normalizes to CR
    call EnsureVisible
    CHECK32 cursorOffset,2
    cmp textCursorCol,2
    jne TestFailed
    mov ax,7500h
    call HandleKey
    mov ax,4900h
    call HandleKey
    CHECK32 cursorOffset,1
    mov ax,5100h
    call HandleKey
    CHECK32 cursorOffset,11
    cmp dirty,0
    jne TestFailed
    mov testCase,offset caseTextBound
    mov fileSize,10001h
    call TestFillPattern
    mov cursorOffset,0FFFFh
    mov al,13
    call HandleKey
    CHECK32 fileSize,10003h
    CHECKBYTE 0FFFFh,13
    CHECKBYTE 10000h,10
    CHECKBYTE 10001h,5Ah
    call EnsureVisible
    CHECK32 cursorOffset,10001h
    cmp textCursorRow,DATA_ROWS
    jae TestFailed
    cmp textCursorCol,80
    jae TestFailed
    mov al,8
    call HandleKey
    CHECK32 fileSize,10001h
    CHECK32 cursorOffset,0FFFFh
    call TestVerifyPattern
    jc TestFailed
    mov fileSize,0
    mov testCase,offset caseTextStack
    mov cursorOffset,0
    mov testStack,sp
    mov testLoops,1000
test_text_dispatch:
    mov al,'Q'
    call HandleKey
    mov al,13
    call HandleKey
    mov al,8
    call HandleKey
    mov al,8
    call HandleKey
    call EnsureVisible
    cmp sp,testStack
    jne TestFailed
    CHECK32 fileSize,0
    dec testLoops
    jnz test_text_dispatch
    mov al,8                      ; empty Text deletion and ignored controls
    call HandleKey
    mov ax,5300h
    call HandleKey
    mov ax,0001h
    call HandleKey
    mov ax,00FFh
    call HandleKey
    CHECK32 fileSize,0
    CHECK32 cursorOffset,0
    mov ax,4000h
    call HandleKey
    call TestTextCache
    jc TestFailed
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
    mov al,9
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
    mov al,9
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
    cmp word ptr es:[2*160+61*2],0C2Eh ; selected ASCII dot is bright red in HEX
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
    xor eax,eax
    mov dl,'Q'
    call WriteByte
    call RenderScreen
    cmp word ptr es:[2*160+61*2],0C51h ; selected printable Q is bright red too
    jne TestFailed
    xor eax,eax
    mov dl,0A5h
    call WriteByte
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
    cmp word ptr es:[2*160+66*2],0C2Eh ; selected ASCII dot is bright red in BIN
    jne TestFailed
    xor eax,eax
    mov dl,'Q'
    call WriteByte
    call RenderScreen
    cmp word ptr es:[2*160+66*2],0C51h ; selected printable Q in BIN
    jne TestFailed
    mov cursorOffset,1
    call RenderScreen
    cmp word ptr es:[2*160+66*2],0751h ; moving to EOF removes preview highlight
    jne TestFailed
    cmp word ptr es:[2*160+19*2],0D2Dh ; purple selected EOF '-', black background
    jne TestFailed
    xor eax,eax
    mov dl,0A5h
    call WriteByte

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
    cmp word ptr es:[11*160+13*2],0E46h ; yellow F11/F12 undo/redo instruction
    jne TestFailed
    cmp word ptr es:[11*160+21*2],0E32h ; F12 label
    jne TestFailed
    cmp word ptr es:[10*160+13*2],0E41h ; yellow ASCII input label
    jne TestFailed
    cmp word ptr es:[15*160+14*2],0E39h ; yellow F9 search key
    jne TestFailed
    cmp word ptr es:[17*160+14*2],0E37h ; yellow F7 mode key
    jne TestFailed
    cmp word ptr es:[18*160+14*2],0E38h ; yellow F8 Go to offset key
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

    mov testCase,offset caseTextVideo
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
    mov cursorOffset,3
    mov al,3
    call SetMode
    call EnsureVisible
    call RenderScreen
    cmp word ptr es:[(hexText-titleText-1)*2],0E54h ; yellow Text title
    jne TestFailed
    cmp word ptr es:[2*160],0A41h ; bright-green A at left edge, no offset gutter
    jne TestFailed
    cmp word ptr es:[3*160],0D42h ; selected B in purple after CR/LF
    jne TestFailed
    cmp word ptr es:[24*160+58*2],0A48h ; HEX: label, bottom-right
    jne TestFailed
    cmp word ptr es:[24*160+63*2],0534h ; HEX: 42
    jne TestFailed
    cmp word ptr es:[24*160+64*2],0532h
    jne TestFailed
    cmp word ptr es:[24*160+67*2],0A42h ; BIN: label
    jne TestFailed
    cmp word ptr es:[24*160+73*2],0531h ; 01000010
    jne TestFailed
    cmp word ptr es:[24*160+78*2],0531h
    jne TestFailed
    mov ah,03h
    xor bh,bh
    int 10h
    cmp dx,0300h
    jne TestFailed
    mov testCase,offset caseTextTyped
    mov cursorOffset,1
    call EnsureVisible
    call RenderScreen
    cmp word ptr es:[2*160+1*2],0D20h ; selected CR is a purple blank
    jne TestFailed
    cmp word ptr es:[24*160+64*2],0544h ; actual selected byte 0D
    jne TestFailed
    mov ax,7500h
    call HandleKey
    mov al,'Z'
    call HandleKey
    call EnsureVisible
    call RenderScreen
    cmp word ptr es:[24*160+63*2],0535h ; typed Z at EOF: 5A, not dashes
    jne TestFailed
    cmp word ptr es:[24*160+64*2],0541h
    jne TestFailed
    cmp word ptr es:[3*160+2*2],0D2Dh ; EOF after BZ
    jne TestFailed
    mov ax,4B00h
    call HandleKey
    call EnsureVisible
    call RenderScreen
    cmp word ptr es:[3*160+1*2],0D5Ah ; current editable Z in purple
    jne TestFailed
    mov ax,7500h
    call HandleKey
    call EnsureVisible
    call RenderScreen
    cmp word ptr es:[24*160+63*2],052Dh ; no selected/typed byte after navigation
    jne TestFailed
    mov fileSize,3
    mov viewOffset,0
    xor eax,eax
    mov dl,'A'
    call WriteByte
    mov eax,1
    mov dl,9
    call WriteByte
    mov eax,2
    mov dl,'B'
    call WriteByte
    mov cursorOffset,1
    call EnsureVisible
    call RenderScreen
    cmp word ptr es:[2*160+1*2],0D20h ; selected tab: purple first expansion cell
    jne TestFailed
    cmp word ptr es:[2*160+7*2],0A20h ; remainder of expansion stays green
    jne TestFailed
    cmp word ptr es:[2*160+8*2],0A42h ; next char at the 8-column tab stop
    jne TestFailed
    cmp word ptr es:[24*160+64*2],0539h ; HEX: 09 for actual tab byte
    jne TestFailed
    mov ax,4D00h
    call HandleKey
    call EnsureVisible
    call RenderScreen
    cmp word ptr es:[2*160+8*2],0D42h ; Right skips whole tab expansion
    jne TestFailed
    mov ah,03h
    xor bh,bh
    int 10h
    cmp dx,0208h
    jne TestFailed
    mov cursorOffset,0
    xor eax,eax
    mov dl,0FFh
    call WriteByte
    call EnsureVisible
    call RenderScreen
    cmp word ptr es:[2*160],0D2Eh ; non-ASCII file bytes remain editable as dots
    jne TestFailed
    cmp word ptr es:[24*160+63*2],0546h ; HEX: FF
    jne TestFailed
    mov testCase,offset caseTextWrap
    mov fileSize,1600
    xor esi,esi
test_text_wrap_fill:
    mov eax,esi
    mov dl,'x'
    call WriteByte
    inc esi
    cmp esi,fileSize
    jb test_text_wrap_fill
    mov cursorOffset,1600
    call EnsureVisible
    CHECK32 viewOffset,80
    call RenderScreen
    cmp word ptr es:[2*160],0A78h ; wrapped text uses green over black
    jne TestFailed
    cmp word ptr es:[21*160],0D2Dh ; EOF after a full screen wraps and scrolls
    jne TestFailed
    cmp word ptr es:[4000],0A55Ah
    jne TestFailed
    mov ah,03h
    xor bh,bh
    int 10h
    cmp dx,1500h
    jne TestFailed
    mov cursorOffset,0
    mov ax,4F00h
    call HandleKey
    CHECK32 cursorOffset,79
    mov ax,5000h
    call HandleKey
    CHECK32 cursorOffset,159
    mov ax,4700h
    call HandleKey
    CHECK32 cursorOffset,80
    mov testCase,offset caseTextLines
    mov fileSize,44                ; 22 empty CR/LF lines also scroll by rows
    mov viewOffset,0
    xor esi,esi
test_text_empty_lines:
    mov eax,esi
    mov dl,13
    call WriteByte
    inc esi
    mov eax,esi
    mov dl,10
    call WriteByte
    inc esi
    cmp esi,fileSize
    jb test_text_empty_lines
    mov cursorOffset,44
    call EnsureVisible
    CHECK32 viewOffset,6
    call RenderScreen
    cmp word ptr es:[21*160],0D2Dh
    jne TestFailed
    mov fileSize,0
    mov cursorOffset,0
    call EnsureVisible
    call RenderScreen
    cmp word ptr es:[2*160],0D2Dh ; empty Text buffer still has an editing cursor
    jne TestFailed
    mov fileSize,83
    xor esi,esi
test_full_row_video_fill:
    mov eax,esi
    mov dl,'A'
    call WriteByte
    inc esi
    cmp esi,80
    jb test_full_row_video_fill
    mov eax,80
    mov dl,13
    call WriteByte
    mov eax,81
    mov dl,10
    call WriteByte
    mov eax,82
    mov dl,'B'
    call WriteByte
    mov cursorOffset,80
    mov viewOffset,0
    call EnsureVisible
    call RenderScreen
    cmp word ptr es:[2*160+79*2],0D3Ch ; full-width CR marker stays on screen
    jne TestFailed
    cmp word ptr es:[3*160],0A42h ; B immediately follows the full-width row
    jne TestFailed
    cmp word ptr es:[4000],0A55Ah
    jne TestFailed
    call TestTextPolish
    jc TestFailed
    call TestGotoVideo
    jc TestFailed
    call TestSearchVideo
    jc TestFailed
    call EndVideo
    mov videoActive,0
    call TestSaveFailures
    jc TestFailed
    call TestGotoOffset
    jc TestFailed
    call TestSearch
    jc TestFailed
    call TestUndoRedo
    jc TestFailed

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

include TESTS\BOUNDS.INC
include TESTS\SAVEFAIL.INC
include TESTS\CACHE.INC
include TESTS\POLISH.INC
include TESTS\GOTO.INC
include TESTS\SEARCH.INC
include TESTS\UNDO.INC
