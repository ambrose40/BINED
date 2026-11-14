_TEXT ends
_DATA segment word public use16 'DATA'
caseTextCache db 'Text checkpoint correctness, edit invalidation and bounded scans',13,10,'$'
_DATA ends
_TEXT segment word public use16 'CODE'

; Warm lookup must agree with a cache-free scan after each kind of mutation.
CompareTextCache proc
    mov cacheTarget,eax
    call FindTextRow
    mov cacheExpected,eax
    mov cacheExpected+4,ebx
    mov cacheExpected+8,ecx
    mov cacheExpected+12,edx
    call ResetTextCache
    mov eax,cacheTarget
    call FindTextRow
    cmp eax,cacheExpected
    jne cache_compare_bad
    cmp ebx,cacheExpected+4
    jne cache_compare_bad
    cmp ecx,cacheExpected+8
    jne cache_compare_bad
    cmp edx,cacheExpected+12
    jne cache_compare_bad
    clc
    ret
cache_compare_bad:
    stc
    ret
CompareTextCache endp

TestTextCache proc
    mov testCase,offset caseTextCache
    mov fileSize,20011h
    xor esi,esi
cache_fill:
    mov eax,esi
    mov dl,'A'
    call WriteByte
    inc esi
    cmp esi,fileSize
    jb cache_fill
    mov al,3
    call SetMode
    mov eax,fileSize
    mov cursorOffset,eax
    call ResetTextCache
    call EnsureVisible
    mov eax,fileSize
    call FindTextRow
    cmp ebx,1638
    jne cache_test_bad
    cmp ecx,49
    jne cache_test_bad
    mov textRowScans,0
    mov testLoops,32
cache_warm_navigation:
    call EnsureVisible
    dec testLoops
    jnz cache_warm_navigation
    cmp textRowScans,96            ; two local row parses per update, not 128 KiB
    ja cache_test_bad
    xor eax,eax
    mov dl,10                     ; change layout before all cached checkpoints
    call WriteByte
    mov eax,fileSize
    call CompareTextCache
    jc cache_test_bad
    mov eax,10000h
    mov dl,9                      ; tab expansion changes wrapping near 64 KiB
    call WriteByte
    mov eax,fileSize
    call CompareTextCache
    jc cache_test_bad
    mov cursorOffset,80
    call InsertByte
    mov eax,fileSize
    call CompareTextCache
    jc cache_test_bad
    call DeleteByte
    mov eax,fileSize
    call CompareTextCache
    jc cache_test_bad
    mov fileSize,0                 ; direct size changes cannot reuse old anchors
    xor eax,eax
    call FindTextRow
    test eax,eax
    jnz cache_test_bad
    test ebx,ebx
    jnz cache_test_bad
    test ecx,ecx
    jnz cache_test_bad
    clc
    ret
cache_test_bad:
    stc
    ret
TestTextCache endp
