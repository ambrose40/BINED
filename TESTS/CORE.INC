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
caseBoundary    db 'insert/delete across 64 KiB boundaries',13,10,'$'
caseFull        db 'full-buffer and empty-file bounds',13,10,'$'
caseNavigation  db 'navigation and viewport bounds',13,10,'$'
caseStack       db '10000 dispatches preserve SP',13,10,'$'
caseVideo       db 'hex/binary rendering, cursor and screen bounds',13,10,'$'
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
    call EnsureVisible
    call RenderScreen
    cmp word ptr es:[4000],0A55Ah
    jne TestFailed
    cmp word ptr es:[2*160+10*2],0D41h  ; purple selected 'A', black background
    jne TestFailed
    cmp byte ptr es:[2*160+11*2],'5'
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
    mov cursorOffset,1
    call RenderScreen
    cmp word ptr es:[2*160+19*2],0D2Dh ; purple selected EOF '-', black background
    jne TestFailed
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
