_TEXT ends
_DATA segment word public use16 'DATA'
casePolish      db 'preferred columns, F7 viewport, position/status and save modal',13,10,'$'
polishFixture   db '0123456789',13,10,'x',13,10,'0123456789'
polishFixtureEnd label byte
_DATA ends
_TEXT segment word public use16 'CODE'

TestTextPolish proc
    mov testCase,offset casePolish
    mov fileSize,polishFixtureEnd-polishFixture
    xor edi,edi
    mov si,offset polishFixture
polish_fixture_copy:
    lodsb
    mov dl,al
    mov eax,edi
    call WriteByte
    inc edi
    cmp edi,fileSize
    jb polish_fixture_copy
    mov al,3
    call SetMode
    mov cursorOffset,8
    mov ax,5000h
    call HandleKey
    cmp cursorOffset,13
    jne polish_bad
    mov ax,5000h
    call HandleKey
    cmp cursorOffset,23
    jne polish_bad
    mov ax,4800h
    call HandleKey
    mov ax,4800h
    call HandleKey
    cmp cursorOffset,8
    jne polish_bad
    mov ax,5100h
    call HandleKey
    mov ax,4900h
    call HandleKey
    cmp cursorOffset,8
    jne polish_bad
    mov ax,4B00h                  ; horizontal motion resets the desired column
    call HandleKey
    mov ax,5000h
    call HandleKey
    mov ax,5000h
    call HandleKey
    cmp cursorOffset,22
    jne polish_bad
    mov fileSize,1600
    xor esi,esi
polish_view_fill:
    mov eax,esi
    mov dl,'A'
    call WriteByte
    inc esi
    cmp esi,fileSize
    jb polish_view_fill
    mov cursorOffset,800
    mov viewOffset,320
    call EnsureVisible
    mov ax,4100h
    call HandleKey
    call EnsureVisible
    cmp viewOffset,320
    jne polish_bad
    call RenderScreen
    cmp word ptr es:[22*160+54*2],0A4Ch ; Ln:
    jne polish_bad
    cmp word ptr es:[22*160+65*2],0542h ; one-based row 0B
    jne polish_bad
    cmp word ptr es:[22*160+72*2],0531h ; one-based column 01
    jne polish_bad
    cmp word ptr es:[22*160+74*2],0E49h ; INS indicator
    jne polish_bad
    mov statusText,offset msgSaveError
    call RenderScreen
    cmp word ptr es:[24*160+58*2],0A48h ; reserved HEX inspector survives long text
    jne polish_bad
    mov lastError,5
    mov saveTarget,offset fileName
    mov backupExists,1
    mov stageExists,1
    mov si,offset backupPath
    mov cx,100
polish_long_backup:
    mov byte ptr [si],'P'
    inc si
    loop polish_long_backup
    mov byte ptr [si],0
    mov stagePath,'S'
    mov stagePath+1,0
    mov word ptr es:[5*160],0F4Ch ; markers just outside the modal
    mov word ptr es:[5*160+79*2],0F52h
    call RenderSaveError
    cmp word ptr es:[5*160],0F4Ch
    jne polish_bad
    cmp word ptr es:[5*160+79*2],0F52h
    jne polish_bad
    cmp word ptr es:[5*160+1*2],0DDAh
    jne polish_bad
    cmp word ptr es:[6*160+3*2],0753h ; complete save-error sentence
    jne polish_bad
    cmp word ptr es:[6*160+(3+msgReadOnly-msgSaveError-2)*2],072Eh ; final period
    jne polish_bad
    cmp word ptr es:[10*160+3*2],0D50h ; recovery path wraps inside modal
    jne polish_bad
    cmp word ptr es:[12*160+3*2],0D53h ; staged-data path
    jne polish_bad
    cmp word ptr es:[4000],0A55Ah
    jne polish_bad
    mov backupExists,0
    mov stageExists,0
    mov statusText,offset msgReady
    clc
    ret
polish_bad:
    stc
    ret
TestTextPolish endp
