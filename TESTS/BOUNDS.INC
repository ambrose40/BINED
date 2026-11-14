; Matrix of display widths and newline forms. CF reports a failed boundary.
TestTextBoundaries proc
    mov testCase,offset caseTextEdges
    mov boundaryIndex,0
boundary_length_next:
    mov bx,boundaryIndex
    mov eax,boundaryLengths[bx]
    test eax,eax
    jz boundary_tabs
    mov boundaryLength,eax
    mov boundaryTerm,0
boundary_variant:
    mov eax,boundaryLength
    mov fileSize,eax
    xor esi,esi
boundary_fill:
    mov eax,esi
    mov dl,'A'
    call WriteByte
    inc esi
    cmp esi,boundaryLength
    jb boundary_fill
    cmp boundaryTerm,0
    je boundary_ready
    mov eax,esi
    mov dl,10
    cmp boundaryTerm,1
    je boundary_write_break
    mov dl,13
boundary_write_break:
    call WriteByte
    inc esi
    cmp boundaryTerm,3
    jne boundary_write_b
    mov eax,esi
    mov dl,10
    call WriteByte
    inc esi
boundary_write_b:
    mov eax,esi
    mov dl,'B'
    call WriteByte
    lea eax,[esi+1]
    mov fileSize,eax
boundary_ready:
    mov cursorOffset,0
    mov al,3
    call SetMode
    mov ax,4F00h
    call HandleKey
    mov eax,boundaryLength
    cmp eax,80
    jb boundary_end_expected
    mov eax,79
boundary_end_expected:
    cmp cursorOffset,eax
    jne boundary_failed
    cmp boundaryTerm,0
    je boundary_next_variant
    mov cursorOffset,esi           ; position of B, after the terminator
    call EnsureVisible
    mov eax,boundaryLength
    dec eax
    xor edx,edx
    mov ebx,80
    div ebx
    inc eax                       ; no extra row at exact multiples of 80
    cmp textCursorRow,ax
    jne boundary_failed
    cmp textCursorCol,0
    jne boundary_failed
    mov eax,boundaryLength
    mov cursorOffset,eax
    call EnsureVisible
    cmp textCursorCol,80
    jae boundary_failed
boundary_next_variant:
    inc boundaryTerm
    cmp boundaryTerm,4
    jb boundary_variant
    add boundaryIndex,4
    jmp boundary_length_next
boundary_tabs:
    mov fileSize,13
    xor esi,esi
boundary_tab_fill:
    mov eax,esi
    mov dl,9
    call WriteByte
    inc esi
    cmp esi,10
    jb boundary_tab_fill
    mov eax,10
    mov dl,13
    call WriteByte
    mov eax,11
    mov dl,10
    call WriteByte
    mov eax,12
    mov dl,'B'
    call WriteByte
    mov cursorOffset,12
    mov al,3
    call SetMode
    call EnsureVisible
    cmp textCursorRow,1
    jne boundary_failed
    cmp textCursorCol,0
    jne boundary_failed
    mov cursorOffset,0
    mov ax,4F00h
    call HandleKey
    cmp cursorOffset,9             ; the last tab, not the following newline
    jne boundary_failed
    clc
    ret
boundary_failed:
    stc
    ret
TestTextBoundaries endp
