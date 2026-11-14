_TEXT ends
_DATA segment word public use16 'DATA'
caseSearch      db 'F9/F3 text/hex, bounds, overlaps, wrap, modes and linear scans',13,10,'$'
caseSearchVideo db 'F9 input/error/mode colours, scrolling and screen bounds',13,10,'$'
searchFixture   db 'aba AB aba',0,0FFh,'ABA',13,10
searchFixtureEnd label byte
searchTextABA   db 'aba',0
searchBadCase   db 'AbA',0
searchHexBytes  db '00 ff 41',0
searchHexCompact db '00ff41',0
searchHexPadded db ' 00  ff 41 ',0
searchHexSpaces db '   ',0
searchHexCross  db '00FF42E1',0
searchBadHex    db 'A B',0
searchOddHex    db 'ABC',0
searchLF        db '0A',0
searchOverlap   db 'AA',0
searchNoCyclic  db 'BA',0
searchDraft     db 'XYZ',0
searchLongMatch db 31 dup ('A'),'B',0
searchLongMiss  db 31 dup ('A'),'C',0
searchMaxHex    db 31 dup ('41 '),'42',0
searchExcessHex db 33 dup ('41'),0
searchTestMode  dw 0
searchTestFocus db 0
searchTestView  db 0
_DATA ends
_TEXT segment word public use16 'CODE'

TypeSearchString proc
search_test_type:
    lodsb
    test al,al
    jz search_test_typed
    push si
    call HandleSearchKey
    pop si
    jmp search_test_type
search_test_typed:
    ret
TypeSearchString endp

; SI query, DL type -> reset draft, type and accept (editor state is unchanged).
AcceptSearchString proc
    push si
    push dx
    call ResetSearchInput
    pop dx
    pop si
    mov searchType,dl
    call TypeSearchString
    mov al,13
    call HandleSearchKey
    ret
AcceptSearchString endp

TestSearch proc
    mov testCase,offset caseSearch
    mov testStack,sp
    mov searchLength,0
    mov searchHaveMatch,0
    mov fileSize,0
    mov cursorOffset,0
    xor al,al
    call SetMode
    call ResetSearchInput
    cmp searchType,1
    jne search_test_bad
    mov al,13
    call HandleSearchKey
    cmp searchDone,0
    jne search_test_bad
    cmp searchError,offset searchNoPrevious
    jne search_test_bad
    call RepeatSearch
    jnc search_test_bad
    cmp cursorOffset,0
    jne search_test_bad
    mov al,3
    call SetMode
    call ResetSearchInput
    cmp searchType,0
    jne search_test_bad
    xor al,al
    call SetMode
    mov al,2
    call SetMode
    call ResetSearchInput
    cmp searchType,0
    jne search_test_bad
    mov fileSize,searchFixtureEnd-searchFixture
    xor edi,edi
    mov si,offset searchFixture
search_fixture_copy:
    lodsb
    mov dl,al
    mov eax,edi
    call WriteByte
    inc edi
    cmp edi,fileSize
    jb search_fixture_copy
    mov dirty,0
    mov searchTestMode,0
search_test_mode:
    xor al,al
    call SetMode
    cmp searchTestMode,0
    je search_test_selected
    cmp searchTestMode,1
    je search_test_binary
    cmp searchTestMode,2
    je search_test_ascii
    cmp searchTestMode,3
    je search_test_bin_ascii
    mov al,3
    call SetMode
    jmp search_test_selected
search_test_binary:
    mov al,1
    call SetMode
    jmp search_test_selected
search_test_bin_ascii:
    mov al,1
    call SetMode
search_test_ascii:
    mov al,2
    call SetMode
search_test_selected:
    mov al,editMode
    mov searchTestFocus,al
    mov al,viewMode
    mov searchTestView,al
    mov cursorOffset,0
    mov si,offset searchTextABA
    xor dl,dl
    call AcceptSearchString
    cmp searchDone,1
    jne search_test_bad
    cmp cursorOffset,0
    jne search_test_bad
    call RepeatSearch
    jc search_test_bad
    cmp cursorOffset,7
    jne search_test_bad
    call RepeatSearch
    jc search_test_bad
    cmp cursorOffset,0
    jne search_test_bad
    cmp statusText,offset msgSearchWrapped
    jne search_test_bad
    mov al,searchTestFocus
    cmp editMode,al
    jne search_test_bad
    mov al,searchTestView
    cmp viewMode,al
    jne search_test_bad
    cmp digitIndex,0
    jne search_test_bad
    cmp dirty,0
    jne search_test_bad
    cmp sp,testStack
    jne search_test_bad
    inc searchTestMode
    cmp searchTestMode,5
    jb search_test_mode
    xor al,al
    call SetMode
    mov dirty,1
    mov cursorOffset,0
    call RepeatSearch
    cmp dirty,1                   ; searching must preserve an already-dirty file too
    jne search_test_bad
    mov dirty,0
    mov cursorOffset,3
    mov viewOffset,0
    mov digitIndex,1
    mov si,offset searchBadCase
    xor dl,dl
    call AcceptSearchString
    cmp statusText,offset msgSearchMissing
    jne search_test_bad
    cmp cursorOffset,3
    jne search_test_bad
    cmp digitIndex,1
    jne search_test_bad
    cmp viewOffset,0
    jne search_test_bad
    mov si,offset searchTextABA
    xor dl,dl
    call AcceptSearchString
    cmp cursorOffset,7
    jne search_test_bad
    call ResetSearchInput
    mov si,offset searchDraft
    call TypeSearchString
    mov al,27
    call HandleSearchKey
    cmp searchDone,2
    jne search_test_bad
    cmp searchLength,3
    jne search_test_bad
    cmp searchPattern,'a'
    jne search_test_bad
    call RepeatSearch
    cmp cursorOffset,0
    jne search_test_bad
    call ResetSearchInput
    mov al,13                      ; empty Enter repeats the last accepted query
    call HandleSearchKey
    cmp cursorOffset,7
    jne search_test_bad
    mov si,offset searchHexBytes
    mov dl,1
    call AcceptSearchString
    cmp cursorOffset,10
    jne search_test_bad
    cmp searchLength,3
    jne search_test_bad
    cmp searchPattern,0
    jne search_test_bad
    cmp searchPattern+1,0FFh
    jne search_test_bad
    mov si,offset searchHexCompact
    mov dl,1
    call AcceptSearchString
    cmp cursorOffset,10
    jne search_test_bad
    mov si,offset searchHexPadded
    mov dl,1
    call AcceptSearchString
    cmp cursorOffset,10
    jne search_test_bad
    mov si,offset searchHexSpaces
    mov dl,1
    call AcceptSearchString
    cmp searchDone,0
    jne search_test_bad
    cmp searchError,offset searchHexError
    jne search_test_bad
    mov si,offset searchBadHex
    mov dl,1
    call AcceptSearchString
    cmp searchDone,0
    jne search_test_bad
    cmp searchError,offset searchHexError
    jne search_test_bad
    cmp searchLength,3             ; invalid drafts never destroy the saved query
    jne search_test_bad
    mov si,offset searchOddHex
    mov dl,1
    call AcceptSearchString
    cmp searchDone,0
    jne search_test_bad
    mov al,8                      ; ABC -> AB, valid after Backspace
    call HandleSearchKey
    mov al,13
    call HandleSearchKey
    cmp searchDone,1
    jne search_test_bad
    cmp searchPattern,0ABh
    jne search_test_bad
    mov fileSize,3
    xor eax,eax
    mov dl,'A'
    call WriteByte
    inc eax
    call WriteByte
    inc eax
    call WriteByte
    mov cursorOffset,0
    mov si,offset searchOverlap
    xor dl,dl
    call AcceptSearchString
    call RepeatSearch
    cmp cursorOffset,1
    jne search_test_bad
    call RepeatSearch
    cmp cursorOffset,0
    jne search_test_bad
    mov fileSize,2
    mov eax,1
    mov dl,'B'
    call WriteByte
    mov si,offset searchNoCyclic
    xor dl,dl
    call AcceptSearchString
    cmp statusText,offset msgSearchMissing
    jne search_test_bad
    cmp cursorOffset,0
    jne search_test_bad
    mov fileSize,0                 ; pattern longer than file cannot read any byte
    mov searchReadCount,0
    call RepeatSearch
    cmp searchReadCount,0
    jne search_test_bad
    mov fileSize,20011h
    xor esi,esi
search_fill_large:
    mov eax,esi
    mov dl,'A'
    call WriteByte
    inc esi
    cmp esi,fileSize
    jb search_fill_large
    mov eax,fileSize
    dec eax
    mov dl,'B'
    call WriteByte
    mov cursorOffset,0
    mov searchReadCount,0
    mov si,offset searchLongMatch
    xor dl,dl
    call AcceptSearchString
    mov eax,fileSize
    sub eax,32
    cmp cursorOffset,eax
    jne search_test_bad
    mov eax,fileSize
    cmp searchReadCount,eax
    ja search_test_bad
    mov cursorOffset,0
    mov si,offset searchMaxHex       ; 95 input chars decode to exactly 32 bytes
    mov dl,1
    call AcceptSearchString
    mov eax,fileSize
    sub eax,32
    cmp cursorOffset,eax
    jne search_test_bad
    cmp searchLength,32
    jne search_test_bad
    mov si,offset searchExcessHex    ; 33 bytes must not overwrite pattern storage
    mov dl,1
    call AcceptSearchString
    cmp searchDone,0
    jne search_test_bad
    cmp searchLength,32
    jne search_test_bad
    mov al,27
    call HandleSearchKey
    mov cursorOffset,10000h
    mov searchReadCount,0
    mov si,offset searchLongMiss
    xor dl,dl
    call AcceptSearchString
    cmp statusText,offset msgSearchMissing
    jne search_test_bad
    cmp cursorOffset,10000h
    jne search_test_bad
    mov eax,fileSize
    add eax,32
    cmp searchReadCount,eax
    ja search_test_bad
    mov eax,0FFFFh
    xor dl,dl
    call WriteByte
    inc eax
    mov dl,0FFh
    call WriteByte
    inc eax
    mov dl,'B'
    call WriteByte
    inc eax
    mov dl,0E1h
    call WriteByte
    mov cursorOffset,0
    mov si,offset searchHexCross
    mov dl,1
    call AcceptSearchString
    cmp cursorOffset,0FFFFh
    jne search_test_bad
    mov eax,fileSize
    sub eax,4
    mov cursorOffset,eax
    xor dl,dl
    call WriteByte
    inc eax
    mov dl,0FFh
    call WriteByte
    inc eax
    mov dl,'B'
    call WriteByte
    inc eax
    mov dl,0E1h
    call WriteByte
    mov si,offset searchHexCross
    mov dl,1
    call AcceptSearchString
    mov eax,fileSize
    sub eax,4
    cmp cursorOffset,eax
    jne search_test_bad
    mov fileSize,7
    xor eax,eax
    mov dl,'A'
    call WriteByte
    inc eax
    mov dl,13
    call WriteByte
    inc eax
    mov dl,10
    call WriteByte
    inc eax
    mov dl,'B'
    call WriteByte
    inc eax
    mov dl,13
    call WriteByte
    inc eax
    mov dl,10
    call WriteByte
    inc eax
    mov dl,'C'
    call WriteByte
    mov al,3
    call SetMode
    mov cursorOffset,0
    mov si,offset searchLF
    mov dl,1
    call AcceptSearchString
    cmp cursorOffset,1
    jne search_test_bad
    cmp searchLastMatch,2
    jne search_test_bad
    call RepeatSearch
    cmp cursorOffset,4
    jne search_test_bad
    cmp searchLastMatch,5
    jne search_test_bad
    call RepeatSearch
    cmp cursorOffset,1
    jne search_test_bad
    cmp searchLastMatch,2
    jne search_test_bad
    cmp dirty,0
    jne search_test_bad
    clc
    ret
search_test_bad:
    stc
    ret
TestSearch endp

TestSearchVideo proc
    mov testCase,offset caseSearchVideo
    mov searchLength,0
    xor al,al
    call SetMode
    call ResetSearchInput
    mov si,offset searchBadHex
    call TypeSearchString
    mov al,13
    call HandleSearchKey
    call RenderSearchDialog
    cmp word ptr es:[23*160],0748h ; gray HEX error
    jne search_video_bad
    cmp word ptr es:[24*160],0D41h ; purple A in draft
    jne search_video_bad
    cmp word ptr es:[24*160+52*2],0A4Dh ; green Mode label
    jne search_video_bad
    cmp word ptr es:[24*160+58*2],0E48h ; yellow HEX type
    jne search_video_bad
    call ResetSearchInput
    mov cx,SEARCH_INPUT_MAX+5
search_video_long_input:
    mov al,'A'
    push cx
    call HandleSearchKey
    pop cx
    loop search_video_long_input
    cmp searchInputLength,SEARCH_INPUT_MAX
    jne search_video_bad
    cmp searchInput+SEARCH_INPUT_MAX,0
    jne search_video_bad
    mov al,13
    call HandleSearchKey
    cmp searchDone,0
    jne search_video_bad
    cmp searchError,offset searchSizeError
    jne search_video_bad
    call RenderSearchDialog
    mov ah,03h
    xor bh,bh
    int 10h
    cmp dx,1830h                  ; scroll input, keep caret within its field
    jne search_video_bad
    cmp word ptr es:[4000],0A55Ah
    jne search_video_bad
    clc
    ret
search_video_bad:
    stc
    ret
TestSearchVideo endp
