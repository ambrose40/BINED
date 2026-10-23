; EZ Binary Editor 3 -- TASM, 486 real-mode DOS EXE (small-style layout).
;
; Assemble: TASM /m2 BINED3.ASM,BUILD\
; Link:     TLINK /m BUILD\BINED3.OBJ,BUILD\BINED3.EXE
;
; The memory model and instruction set are independent. Explicit USE16
; segments permit 32-bit registers without generating 32-bit DOS segments.
; DS always addresses DGROUP except inside the bounded DOS transfer below.
; File bytes live only in a DOS-owned allocation, never in screen memory.
; Unless stated otherwise, general registers and FS are scratch. DS/ES and
; the direction flag are preserved by procedures (DF is always clear).

P486                              ; TASM 2.5 spelling of the .486 directive
DOSSEG

STACK_BYTES     equ 4096
MAX_PARAGRAPHS  equ 8000h          ; 512 KiB, subject to conventional memory
IO_CHUNK        equ 4000h          ; never cross a 64 KiB segment boundary
PATH_BYTES      equ 128
DATA_ROWS       equ 20
DATA_TOP        equ 2
DATA_COLUMN     equ 10
; VGA text attributes: background in the high nibble, foreground in the low.
; Keep every background black; 02h is dark green, 0Ah bright green, 0Dh purple.
ATTR_NORMAL     equ 0Ah           ; file bytes, ASCII preview, filename
ATTR_TITLE      equ 02h           ; dark-green title and dialog text
ATTR_OFFSET     equ 02h           ; dark-green offsets and column headings
ATTR_SELECTED   equ 0Dh           ; purple selected byte / EOF marker
ATTR_STATUS     equ 0Ah           ; green position, size and status messages

_STACK segment para stack use16 'STACK'
    db STACK_BYTES dup (?)
_STACK ends

DGROUP group _DATA
_DATA segment word public use16 'DATA'
pspSegment      dw 0
bufferSegment   dw 0
bufferCapacity  dd 0
fileSize        dd 0
cursorOffset    dd 0               ; may equal fileSize: the append position
viewOffset      dd 0               ; row-aligned logical offset
editMode        db 0               ; 0 = hexadecimal, 1 = binary
digitIndex      db 0               ; high nibble/most significant bit first
digitsPerByte   db 2
bytesPerRow     dd 16
pageBytes       dd DATA_ROWS * 16
dirty           db 0
quitRequested   db 0
exitCode        db 0
videoActive     db 0
oldVideoMode    db 3
oldVideoPage    db 0
oldCursorShape  dw 0607h
oldCursorPos    dw 0
statusText      dw offset msgReady
fileName        db 'UNTITLED.BIN',0,115 dup (0)
inputPath       db PATH_BYTES dup (0)
stagePath       db PATH_BYTES + 16 dup (0)
backupPath      db PATH_BYTES + 16 dup (0)
saveTarget      dw 0
backupExists    db 0
stageExists     db 0
fileHandle      dw 0FFFFh
ioRemaining     dd 0
ioOffset        dd 0
ioCount         dw 0
ioOperation     db 3Fh
lastError       dw 0
renderOffset    dd 0
renderRow       dw 0
renderColumn    dw 0
renderValue     db 0
renderAttr      db 0
dialogLength    dw 0
hexDigits       db '0123456789ABCDEF'
titleText       db ' EZ Binary Editor 3 | 486 real mode | ',0
hexText         db 'HEX',0
binText         db 'BIN',0
changedText     db ' *modified*',0
columnText      db ' OFFSET   DATA',0
asciiText       db 'ASCII',0
offsetText      db 'Offset: ',0
sizeText        db '  Size: ',0
capacityText    db '  Capacity: ',0
keysText        db 'F1 Help  F2 Save  F4 Save as  F5 BIN  F6 HEX  Tab Mode  Esc Quit',0
helpText1       db 'Arrows: move digits/rows. PgUp/PgDn: page. Home/End: row start/end.',0
helpText2       db 'Ctrl-Home/End: file start/EOF. Ins: insert 00. Del: delete byte.',0
helpText3       db 'Type 0-9,A-F (hex) or 0,1 (binary). At EOF, typing appends a byte.',0
helpText4       db 'Space: next byte. Backspace: previous byte. Any key returns.',0
saveAsText      db 'Save as (Esc cancels, Enter accepts):',0
quitText        db 'Unsaved changes: S = save and quit, D = discard, Esc = cancel',0
msgReady        db 'F1 Help | Sizes/offsets are hex. EOF is an append position.',0
msgNew          db 'New file. Type to append bytes, then F2 to save.',0
msgSaved        db 'Saved.',0
msgFull         db 'Buffer full: delete bytes or save the file.',0
msgSaveError    db 'Save failed. Original retained; any recovery files are beside it.',0
msgReadOnly     db 'Save failed: target is read-only or a directory.',0
usageText       db 'EZ Binary Editor 3 (486+, DOS 3.0+)',13,10
                db 'Usage: BINED3 [filename]',13,10
                db '       BINED3 "path with spaces"',13,10
                db 'Missing files start empty. F1: help, F2: save, Esc: quit.',13,10,'$'
argumentError   db 'Invalid command line. Supply one filename (quote spaces).',13,10,'$'
memoryError     db 'Not enough conventional DOS memory.',13,10,'$'
loadError       db 'Cannot load file (DOS error or incomplete read).',13,10,'$'
largeError      db 'File exceeds available editor buffer (at most 512 KiB).',13,10,'$'

_DATA ends
_TEXT segment word public use16 'CODE'
assume cs:_TEXT, ds:DGROUP

; ---------------------------------------------------------------------------
; Startup and lifetime. Only Main owns the event loop and termination.
; DOSSEG puts the stack last: shrink the PSP block through its END,
; not through the current SP. DOS can then allocate the released paragraphs.
; ---------------------------------------------------------------------------
Main proc
    mov ax,DGROUP
    mov ds,ax
    mov pspSegment,es
    cld
    call AllocateBuffer
    jnc main_memory_ready
    mov dx,offset memoryError
    jmp FatalError
main_memory_ready:
IFDEF BINED_TEST
    call RunTests
    mov exitCode,al
    jmp Shutdown
ELSE
    call ParseCommandLine
    jnc main_arguments_ready
    cmp ax,1
    je main_help
    mov dx,offset argumentError
    jmp FatalError
main_help:
    mov dx,offset usageText
    mov ah,09h
    int 21h
    jmp Shutdown
main_arguments_ready:
    call LoadFile
    jnc main_loaded
    cmp ax,8
    jne main_load_error
    mov dx,offset largeError
    jmp FatalError
main_load_error:
    mov dx,offset loadError
    jmp FatalError
main_loaded:
    call BeginVideo
main_event_loop:
    call EnsureVisible
    call RenderScreen
    xor ah,ah
    int 16h
    call HandleKey
    cmp quitRequested,0
    je main_event_loop
    jmp Shutdown
ENDIF
Main endp

FatalError proc
    mov ah,09h
    int 21h
    mov exitCode,1
    jmp Shutdown
FatalError endp

Shutdown proc
    cmp videoActive,0
    je shutdown_memory
    call EndVideo
shutdown_memory:
    mov ax,bufferSegment
    or ax,ax
    jz shutdown_exit
    mov es,ax
    mov ah,49h
    int 21h
shutdown_exit:
    mov al,exitCode
    mov ah,4Ch
    int 21h
Shutdown endp

AllocateBuffer proc
    push es
    mov ax,ss
    add ax,STACK_BYTES / 16
    sub ax,pspSegment
    mov bx,ax
    mov es,pspSegment
    mov ah,4Ah
    int 21h
    jc allocate_failed
    mov bx,MAX_PARAGRAPHS
    mov ah,48h
    int 21h
    jnc allocate_success
    ; On insufficient memory DOS returns its largest free block in BX.
    or bx,bx
    jz allocate_failed
    mov ah,48h
    int 21h
    jc allocate_failed
allocate_success:
    mov bufferSegment,ax
    movzx eax,bx
    shl eax,4
    mov bufferCapacity,eax
    pop es
    clc
    ret
allocate_failed:
    pop es
    stc
    ret
AllocateBuffer endp

; EAX = logical byte offset -> FS:BX, with BX in 0..15.
; Callers enforce offset < bufferCapacity. Preserves EAX and EDX.
MapBuffer proc
    push edx
    mov edx,eax
    shr edx,4
    add dx,bufferSegment
    mov fs,dx
    mov bx,ax
    and bx,000Fh
    pop edx
    ret
MapBuffer endp

; EAX = offset -> AL = byte. Preserves EBX, EDX, and EAX bits 8..31.
ReadByte proc
    push ebx
    call MapBuffer
    mov al,fs:[bx]
    pop ebx
    ret
ReadByte endp

; EAX = offset, DL = byte. Preserves all general registers.
WriteByte proc
    push ebx
    call MapBuffer
    mov fs:[bx],dl
    pop ebx
    ret
WriteByte endp

; ---------------------------------------------------------------------------
; Command tail: one optional filename, with quotes and surrounding whitespace.
; CF clear = success; CF set, AX=1 = help, AX=2 = invalid arguments.
; Read the PSP through ES; never assume DS still points at a COM-style PSP.
; ---------------------------------------------------------------------------
ParseCommandLine proc
    push es
    mov es,pspSegment
    mov si,81h
    movzx cx,byte ptr es:[80h]
    mov di,offset fileName
    call SkipTailSpaces
    jcxz parse_success
    cmp cx,2
    jb parse_name
    cmp word ptr es:[si],3F2Fh       ; /?
    jne parse_name
    ; Recognize help with trailing whitespace, but not a filename prefix.
    push si
    push cx
    add si,2
    sub cx,2
    call SkipTailSpaces
    or cx,cx
    pop cx
    pop si
    jz parse_help
parse_name:
    xor bx,bx                      ; BL = quoted, BH = quote closed
    cmp byte ptr es:[si],'"'
    jne parse_copy
    mov bl,1
    inc si
    dec cx
parse_copy:
    jcxz parse_end
    mov al,es:[si]
    inc si
    dec cx
    cmp al,'"'
    je parse_quote
    or bl,bl
    jnz parse_character
    cmp al,' '
    je parse_trailing
    cmp al,9
    je parse_trailing
parse_character:
    cmp al,20h
    jb parse_bad
    cmp di,offset fileName + PATH_BYTES - 1
    jae parse_bad
    mov [di],al
    inc di
    jmp parse_copy
parse_quote:
    cmp bl,1
    jne parse_bad
    mov bh,1
    jmp parse_trailing
parse_end:
    cmp bl,1
    jne parse_finish
    cmp bh,1
    jne parse_bad
parse_finish:
    cmp di,offset fileName
    je parse_bad
    mov byte ptr [di],0
parse_success:
    pop es
    clc
    ret
parse_trailing:
    call SkipTailSpaces
    or cx,cx
    jnz parse_bad
    jmp parse_end
parse_help:
    mov ax,1
    pop es
    stc
    ret
parse_bad:
    mov ax,2
    pop es
    stc
    ret
ParseCommandLine endp

; ES:SI/CX command-tail span -> skip spaces and tabs.
SkipTailSpaces proc
skip_tail_next:
    jcxz skip_tail_done
    cmp byte ptr es:[si],' '
    je skip_tail_advance
    cmp byte ptr es:[si],9
    jne skip_tail_done
skip_tail_advance:
    inc si
    dec cx
    jmp skip_tail_next
skip_tail_done:
    ret
SkipTailSpaces endp

; ---------------------------------------------------------------------------
; File I/O. Always close handles. Transfer in <=16 KiB chunks, normalize the
; far pointer on EVERY chunk, and reject short transfers instead of displaying
; uninitialized bytes or reporting incomplete saves as successful.
; ---------------------------------------------------------------------------
LoadFile proc
    mov dx,offset fileName
    mov ax,3D00h
    int 21h
    jnc load_opened
    cmp ax,2                       ; missing filename is a new document
    jne load_failed
    mov statusText,offset msgNew
    clc
    ret
load_opened:
    mov fileHandle,ax
    mov bx,ax
    xor cx,cx
    xor dx,dx
    mov ax,4202h
    int 21h
    jc load_close_failed
    shl edx,16
    mov dx,ax                      ; DX:AX -> EDX
    cmp edx,bufferCapacity
    ja load_too_large
    mov fileSize,edx
    mov ioRemaining,edx
    mov ioOffset,0
    xor cx,cx
    xor dx,dx
    mov ax,4200h
    int 21h
    jc load_close_failed
    mov ioOperation,3Fh
    call TransferFile
    jc load_close_failed
    call CloseFile
    ret
load_too_large:
    mov ax,8
load_close_failed:
    push ax
    call CloseFile
    pop ax
load_failed:
    stc
    ret
LoadFile endp

; Uses fileHandle, ioOffset, ioRemaining, ioOperation. CF reports failure.
TransferFile proc
transfer_next:
    mov eax,ioRemaining
    test eax,eax
    jz transfer_done
    cmp eax,IO_CHUNK
    jbe transfer_count_ready
    mov eax,IO_CHUNK
transfer_count_ready:
    mov ioCount,ax
    mov cx,ax
    mov eax,ioOffset
    call MapBuffer
    mov dx,bx
    mov bx,fileHandle
    mov ah,ioOperation
    push ds
    push fs
    pop ds
    int 21h
    pop ds
    jc transfer_failed
    cmp ax,ioCount
    jne transfer_short
    movzx eax,ax
    add ioOffset,eax
    sub ioRemaining,eax
    jmp transfer_next
transfer_short:
    mov ax,001Dh                   ; generic read/write fault
transfer_failed:
    stc
    ret
transfer_done:
    clc
    ret
TransferFile endp

CloseFile proc
    mov bx,fileHandle
    mov fileHandle,0FFFFh
    mov ah,3Eh
    int 21h
    ret
CloseFile endp

; SI = destination filename, DI = temp-path buffer (PATH_BYTES+16 bytes).
; DOS creates a unique sibling temporary file. Returns handle AX and CF.
CreateSiblingTemp proc
    mov bx,si
    mov dx,di
temp_scan:
    mov al,[si]
    or al,al
    jz temp_copy
    inc si
    cmp al,'\'
    je temp_separator
    cmp al,'/'
    je temp_separator
    cmp al,':'
    jne temp_scan
temp_separator:
    mov bx,si
    jmp temp_scan
temp_copy:
    mov si,saveTarget
temp_copy_next:
    cmp si,bx
    je temp_prefix_done
    mov al,[si]
    mov [di],al
    inc si
    inc di
    jmp temp_copy_next
temp_prefix_done:
    cmp di,dx
    je temp_relative
    cmp byte ptr [di-1],':'
    jne temp_terminate
temp_relative:
    mov byte ptr [di],'.'
    mov byte ptr [di+1],'\'
    add di,2
temp_terminate:
    mov byte ptr [di],0
    xor cx,cx
    mov ah,5Ah
    int 21h
    ret
CreateSiblingTemp endp

; DS:DX = target path. A staged save avoids truncating the original on errors.
; The old file is renamed to a unique sibling until the new rename succeeds.
; On install failure try to restore it; leave recovery files if that fails.
; CF clear only after the new file has been fully written, closed and installed.
SaveDocument proc
    mov saveTarget,dx
    mov stageExists,0
    mov backupExists,0
    mov ax,4300h
    int 21h
    jc save_check_missing
    test cx,11h                    ; read-only or directory
    jnz save_read_only
    jmp save_create_stage
save_check_missing:
    cmp ax,2
    jne save_error
save_create_stage:
    mov si,saveTarget
    mov di,offset stagePath
    call CreateSiblingTemp
    jc save_error
    mov stageExists,1
    mov fileHandle,ax
    mov eax,fileSize
    mov ioRemaining,eax
    mov ioOffset,0
    mov ioOperation,40h
    call TransferFile
    jc save_transfer_error
    call CloseFile
    jc save_cleanup_error
    ; Reserve a unique backup name without overwriting someone else's file.
    mov si,saveTarget
    mov di,offset backupPath
    call CreateSiblingTemp
    jc save_cleanup_error
    mov fileHandle,ax
    call CloseFile
    jc save_cleanup_error
    mov dx,offset backupPath
    mov ah,41h
    int 21h
    jc save_cleanup_error
    mov dx,saveTarget
    mov di,offset backupPath
    call RenameFile
    jnc save_backed_up
    cmp ax,2
    jne save_cleanup_error
    jmp save_install
save_backed_up:
    mov backupExists,1
save_install:
    mov dx,offset stagePath
    mov di,saveTarget
    call RenameFile
    jc save_restore
    mov stageExists,0
    cmp backupExists,0
    je save_success
    mov dx,offset backupPath
    mov ah,41h
    int 21h                        ; deletion failure leaves a harmless backup
save_success:
    mov dirty,0
    mov statusText,offset msgSaved
    clc
    ret
save_restore:
    mov lastError,ax
    cmp backupExists,0
    je save_cleanup_error
    mov dx,offset backupPath
    mov di,saveTarget
    call RenameFile
    jc save_error                  ; retain both files for manual recovery
    mov backupExists,0
    jmp save_cleanup_error
save_transfer_error:
    push ax
    call CloseFile
    pop ax
save_cleanup_error:
    mov lastError,ax
    cmp stageExists,0
    je save_error
    mov dx,offset stagePath
    mov ah,41h
    int 21h
save_error:
    mov statusText,offset msgSaveError
    stc
    ret
save_read_only:
    mov statusText,offset msgReadOnly
    stc
    ret
SaveDocument endp

; DS:DX old name, DS:DI new name. Preserve ES across DOS rename.
RenameFile proc
    push es
    push ds
    pop es
    mov ah,56h
    int 21h
    pop es
    ret
RenameFile endp

; ---------------------------------------------------------------------------
; Editor operations. The byte buffer is the only source of truth. Drawing and
; switching modes never parse characters back out of the display.
; ---------------------------------------------------------------------------
SetMode proc
    ; AL = 0 (hex) or 1 (binary).
    mov editMode,al
    mov digitIndex,0
    mov digitsPerByte,2
    mov bytesPerRow,16
    mov pageBytes,DATA_ROWS * 16
    or al,al
    jz set_mode_done
    mov digitsPerByte,8
    mov bytesPerRow,6
    mov pageBytes,DATA_ROWS * 6
set_mode_done:
    mov viewOffset,0
    ret
SetMode endp

; AL = typed ASCII character. Ignore invalid characters; modify a single
; nibble/bit, preserving the rest. A new EOF byte starts as zero.
EditDigit proc
    call AsciiToHex
    jc edit_done
    cmp editMode,0
    je edit_valid
    cmp al,1
    ja edit_done
edit_valid:
    mov dh,al
    mov esi,cursorOffset
    cmp esi,fileSize
    jb edit_existing
    cmp esi,bufferCapacity
    jae edit_full
    mov eax,esi
    xor dl,dl
    call WriteByte
    inc fileSize
    mov dirty,1
edit_existing:
    mov eax,esi
    call ReadByte
    mov dl,al
    cmp editMode,0
    jne edit_binary
    mov cl,4
    cmp digitIndex,0
    je edit_hex_shift
    xor cl,cl
edit_hex_shift:
    mov al,0Fh
    jmp edit_apply
edit_binary:
    mov cl,7
    sub cl,digitIndex
    mov al,1
edit_apply:
    shl al,cl
    not al
    and dl,al
    mov al,dh
    shl al,cl
    or dl,al
    mov eax,esi
    call ReadByte
    cmp al,dl
    je edit_advance
    mov eax,esi
    call WriteByte
    mov dirty,1
edit_advance:
    call MoveRight
edit_done:
    ret
edit_full:
    mov statusText,offset msgFull
    ret
EditDigit endp

; AL ASCII -> AL 0..15, CF on invalid input. Accept lowercase too.
AsciiToHex proc
    cmp al,'0'
    jb ascii_invalid
    cmp al,'9'
    jbe ascii_number
    and al,0DFh
    cmp al,'A'
    jb ascii_invalid
    cmp al,'F'
    ja ascii_invalid
    sub al,'A'-10
    clc
    ret
ascii_number:
    sub al,'0'
    clc
    ret
ascii_invalid:
    stc
    ret
AsciiToHex endp

InsertByte proc
    mov esi,fileSize
    cmp esi,bufferCapacity
    jae insert_full
insert_shift:
    cmp esi,cursorOffset
    jbe insert_zero
    lea eax,[esi-1]
    call ReadByte
    mov dl,al
    mov eax,esi
    call WriteByte
    dec esi
    jmp insert_shift
insert_zero:
    mov eax,cursorOffset
    xor dl,dl
    call WriteByte
    inc fileSize
    mov digitIndex,0
    mov dirty,1
    ret
insert_full:
    mov statusText,offset msgFull
    ret
InsertByte endp

DeleteByte proc
    mov esi,cursorOffset
    cmp esi,fileSize
    jae delete_done
    dec fileSize
delete_shift:
    cmp esi,fileSize
    jae delete_changed
    lea eax,[esi+1]
    call ReadByte
    mov dl,al
    mov eax,esi
    call WriteByte
    inc esi
    jmp delete_shift
delete_changed:
    mov digitIndex,0
    mov dirty,1
delete_done:
    ret
DeleteByte endp

MoveRight proc
    mov eax,cursorOffset
    cmp eax,fileSize
    jae right_done
    inc digitIndex
    mov al,digitIndex
    cmp al,digitsPerByte
    jb right_done
    mov digitIndex,0
    inc cursorOffset
right_done:
    ret
MoveRight endp

MoveLeft proc
    cmp digitIndex,0
    jne left_digit
    cmp cursorOffset,0
    je left_done
    dec cursorOffset
    mov al,digitsPerByte
    mov digitIndex,al
left_digit:
    dec digitIndex
left_done:
    ret
MoveLeft endp

; EAX = proposed cursor offset (nonnegative). Clamp to EOF.
SetCursor proc
    cmp eax,fileSize
    jbe cursor_in_range
    mov eax,fileSize
cursor_in_range:
    mov cursorOffset,eax
    cmp eax,fileSize
    jne cursor_done
    mov digitIndex,0
cursor_done:
    ret
SetCursor endp

; EAX = amount to subtract, with saturation at zero.
MoveBackward proc
    mov edx,cursorOffset
    sub edx,eax
    jnc backward_in_range
    xor edx,edx
backward_in_range:
    mov eax,edx
    call SetCursor
    ret
MoveBackward endp

EnsureVisible proc
    mov eax,viewOffset
    xor edx,edx
    div bytesPerRow
    sub viewOffset,edx
    mov eax,cursorOffset
    cmp eax,viewOffset
    jb visible_align_cursor
    mov edx,viewOffset
    add edx,pageBytes
    cmp eax,edx
    jb visible_done
    xor edx,edx
    div bytesPerRow
    imul eax,bytesPerRow
    sub eax,pageBytes
    add eax,bytesPerRow
    mov viewOffset,eax
    ret
visible_align_cursor:
    xor edx,edx
    div bytesPerRow
    imul eax,bytesPerRow
    mov viewOffset,eax
visible_done:
    ret
EnsureVisible endp

; AX = BIOS key word. Each dispatch returns to its caller; no nested event
; loops, cross-procedure jumps into epilogues, recursion, or SP resets.
HandleKey proc
    cmp al,27
    je key_quit
    cmp al,9
    je key_toggle
    cmp al,' '
    je key_next_byte
    cmp al,8
    je key_previous_byte
    cmp al,0
    je key_extended
    cmp al,0E0h
    je key_extended
    call EditDigit
    ret
key_extended:
    cmp ah,3Bh
    je key_help
    cmp ah,3Ch
    je key_save
    cmp ah,3Eh
    je key_save_as
    cmp ah,3Fh
    je key_binary
    cmp ah,40h
    je key_hex
    cmp ah,4Bh
    je key_left
    cmp ah,4Dh
    je key_right
    cmp ah,48h
    je key_up
    cmp ah,50h
    je key_down
    cmp ah,49h
    je key_page_up
    cmp ah,51h
    je key_page_down
    cmp ah,47h
    je key_home
    cmp ah,4Fh
    je key_end
    cmp ah,77h
    je key_file_home
    cmp ah,75h
    je key_file_end
    cmp ah,52h
    je key_insert
    cmp ah,53h
    je key_delete
    ret
key_left:
    call MoveLeft
    ret
key_right:
    call MoveRight
    ret
key_up:
    mov eax,bytesPerRow
    call MoveBackward
    ret
key_down:
    mov eax,cursorOffset
    add eax,bytesPerRow
    call SetCursor
    ret
key_page_up:
    mov eax,pageBytes
    call MoveBackward
    ret
key_page_down:
    mov eax,cursorOffset
    add eax,pageBytes
    call SetCursor
    ret
key_home:
    mov eax,cursorOffset
    xor edx,edx
    div bytesPerRow
    mov eax,cursorOffset
    sub eax,edx
    mov digitIndex,0
    call SetCursor
    ret
key_end:
    mov eax,cursorOffset
    xor edx,edx
    div bytesPerRow
    mov eax,cursorOffset
    sub eax,edx
    add eax,bytesPerRow
    dec eax
    call SetCursor
    mov al,digitsPerByte
    dec al
    mov digitIndex,al
    mov eax,cursorOffset
    cmp eax,fileSize
    jne key_end_done
    mov digitIndex,0
key_end_done:
    ret
key_file_home:
    xor eax,eax
    mov digitIndex,0
    call SetCursor
    ret
key_file_end:
    mov eax,fileSize
    call SetCursor
    ret
key_next_byte:
    mov eax,cursorOffset
    inc eax
    mov digitIndex,0
    call SetCursor
    ret
key_previous_byte:
    mov eax,1
    mov digitIndex,0
    call MoveBackward
    ret
key_toggle:
    mov al,editMode
    xor al,1
    call SetMode
    ret
key_binary:
    mov al,1
    call SetMode
    ret
key_hex:
    xor al,al
    call SetMode
    ret
key_insert:
    call InsertByte
    ret
key_delete:
    call DeleteByte
    ret
key_save:
    mov dx,offset fileName
    call SaveDocument
    ret
key_save_as:
    call SaveAsDialog
    ret
key_help:
    call HelpDialog
    ret
key_quit:
    call QuitDialog
    ret
HandleKey endp

; ---------------------------------------------------------------------------
; Screen output: 80x25, page zero, direct B800 writes. No display reads are
; used for editing. DI is a video BYTE offset, AH an attribute, SI a string.
; ---------------------------------------------------------------------------
BeginVideo proc
    mov ah,0Fh
    int 10h
    mov oldVideoMode,al
    mov oldVideoPage,bh
    mov ah,03h
    int 10h
    mov oldCursorShape,cx
    mov oldCursorPos,dx
    mov ax,0003h
    int 10h
    mov cx,0607h
    mov ah,01h
    int 10h
    mov videoActive,1
    ret
BeginVideo endp

EndVideo proc
    xor ah,ah
    mov al,oldVideoMode
    int 10h
    mov ah,05h
    mov al,oldVideoPage
    int 10h
    mov cx,oldCursorShape
    mov ah,01h
    int 10h
    mov dx,oldCursorPos
    mov bh,oldVideoPage
    mov ah,02h
    int 10h
    ret
EndVideo endp

; ES=B800, AH attribute, DI video offset. Bounded to the current 80-column
; row, including user-controlled filenames. Preserves AH; advances SI/DI.
PutString proc
    push bx
    push cx
    push dx
    push ax
    mov ax,di
    xor dx,dx
    mov bx,160
    div bx
    mov cx,160
    sub cx,dx
    shr cx,1
    pop ax
put_string_next:
    mov al,[si]
    or al,al
    jz put_string_done
    cmp di,4000
    jae put_string_done
    mov es:[di],ax
    add di,2
    inc si
    loop put_string_next
put_string_done:
    pop dx
    pop cx
    pop bx
    ret
PutString endp

; EAX value -> 8 hex digits at ES:DI, AH attribute passed in BL.
PutHex32 proc
    push eax
    push cx
    push edx
    mov edx,eax
    mov cx,8
put_hex32_next:
    rol edx,4
    mov al,dl
    and al,0Fh
    call HexCharacter
    mov ah,bl
    stosw
    loop put_hex32_next
    pop edx
    pop cx
    pop eax
    ret
PutHex32 endp

; AL nibble -> ASCII, preserves all other registers.
HexCharacter proc
    push bx
    xor bx,bx
    mov bl,al
    mov al,hexDigits[bx]
    pop bx
    ret
HexCharacter endp

; AX = row -> DI = row*160.
RowAddress proc
    imul di,ax,160
    ret
RowAddress endp

RenderScreen proc
    push es
    mov ax,0B800h
    mov es,ax
    xor di,di
    mov ax,ATTR_NORMAL * 256 + ' '
    mov cx,2000
    rep stosw
    xor di,di
    mov ax,ATTR_TITLE * 256 + ' '
    mov cx,80
    rep stosw
    xor di,di
    mov ah,ATTR_TITLE
    mov si,offset titleText
    call PutString
    mov si,offset hexText
    cmp editMode,0
    je render_mode
    mov si,offset binText
render_mode:
    call PutString
    cmp dirty,0
    je render_columns
    mov si,offset changedText
    call PutString
render_columns:
    mov di,160
    mov ah,ATTR_OFFSET
    mov si,offset columnText
    call PutString
    mov di,160 + 61 * 2
    cmp editMode,0
    je render_ascii_header
    mov di,160 + 66 * 2
render_ascii_header:
    mov si,offset asciiText
    call PutString
    mov eax,viewOffset
    mov renderOffset,eax
    mov renderRow,0
render_next_row:
    mov ax,renderRow
    add ax,DATA_TOP
    call RowAddress
    mov eax,renderOffset
    mov bl,ATTR_OFFSET
    call PutHex32
    mov renderColumn,0
render_next_byte:
    call RenderByte
    inc renderOffset
    inc renderColumn
    movzx eax,renderColumn
    cmp eax,bytesPerRow
    jb render_next_byte
    inc renderRow
    cmp renderRow,DATA_ROWS
    jb render_next_row
    mov di,22 * 160
    mov ah,ATTR_STATUS
    mov si,offset offsetText
    call PutString
    mov eax,cursorOffset
    mov bl,ATTR_STATUS
    call PutHex32
    mov ah,ATTR_STATUS
    mov si,offset sizeText
    call PutString
    mov eax,fileSize
    call PutHex32
    mov ah,ATTR_STATUS
    mov si,offset capacityText
    call PutString
    mov eax,bufferCapacity
    call PutHex32
    mov di,23 * 160
    mov ah,ATTR_NORMAL
    mov si,offset fileName
    call PutString
    mov di,24 * 160
    mov ah,ATTR_STATUS
    mov si,statusText
    call PutString
    pop es
    call PlaceCursor
    ret
RenderScreen endp

RenderByte proc
    mov eax,renderOffset
    cmp eax,fileSize
    ja render_byte_done
    mov renderValue,0
    je render_byte_position
    call ReadByte
    mov renderValue,al
render_byte_position:
    mov ax,renderRow
    add ax,DATA_TOP
    call RowAddress
    mov ax,renderColumn
    mov bx,3
    cmp editMode,0
    je render_byte_stride
    mov bx,9
render_byte_stride:
    mul bx
    add ax,DATA_COLUMN
    shl ax,1
    add di,ax
    mov renderAttr,ATTR_NORMAL
    mov eax,renderOffset
    cmp eax,cursorOffset
    jne render_byte_digits
    mov renderAttr,ATTR_SELECTED
render_byte_digits:
    xor ch,ch
    mov cl,digitsPerByte
    mov dh,renderValue
render_digit:
    mov eax,renderOffset
    cmp eax,fileSize
    mov al,'-'
    je render_digit_output
    cmp editMode,0
    jne render_binary_digit
    rol dh,4
    mov al,dh
    and al,0Fh
    call HexCharacter
    jmp render_digit_output
render_binary_digit:
    shl dh,1
    mov al,'0'
    adc al,0
render_digit_output:
    mov ah,renderAttr
    stosw
    loop render_digit
    ; ASCII preview: printable 7-bit characters only; EOF has no preview.
    mov eax,renderOffset
    cmp eax,fileSize
    jae render_byte_done
    mov ax,renderRow
    add ax,DATA_TOP
    call RowAddress
    mov ax,renderColumn
    add ax,61
    cmp editMode,0
    je render_ascii_position
    add ax,5
render_ascii_position:
    shl ax,1
    add di,ax
    mov al,renderValue
    cmp al,32
    jb render_ascii_dot
    cmp al,126
    jbe render_ascii_output
render_ascii_dot:
    mov al,'.'
render_ascii_output:
    mov ah,renderAttr
    stosw
render_byte_done:
    ret
RenderByte endp

PlaceCursor proc
    mov eax,cursorOffset
    sub eax,viewOffset
    xor edx,edx
    div bytesPerRow
    add al,DATA_TOP
    mov dh,al
    mov al,dl
    mov bl,3
    cmp editMode,0
    je cursor_stride
    mov bl,9
cursor_stride:
    mul bl
    add al,DATA_COLUMN
    add al,digitIndex
    mov dl,al
    xor bh,bh
    mov ah,02h
    int 10h
    ret
PlaceCursor endp

; ---------------------------------------------------------------------------
; Small modal dialogs consume keys locally and return; they never enter the
; editor loop. DOS buffered console input is avoided in the video interface.
; ---------------------------------------------------------------------------
HelpDialog proc
    push es
    mov ax,0B800h
    mov es,ax
    mov di,8 * 160
    mov ah,ATTR_TITLE
    mov si,offset helpText1
    call PutString
    mov di,9 * 160
    mov si,offset helpText2
    call PutString
    mov di,10 * 160
    mov si,offset helpText3
    call PutString
    mov di,11 * 160
    mov si,offset helpText4
    call PutString
    mov di,12 * 160
    mov si,offset keysText
    call PutString
    xor ah,ah
    int 16h
    pop es
    ret
HelpDialog endp

; Clear rows 23/24, print SI prompt. ES is preserved.
DialogPrompt proc
    push es
    mov ax,0B800h
    mov es,ax
    mov di,23 * 160
    mov ax,ATTR_TITLE * 256 + ' '
    mov cx,160
    rep stosw
    mov di,23 * 160
    call PutString
    pop es
    ret
DialogPrompt endp

SaveAsDialog proc
    mov dialogLength,0
    mov inputPath,0
    mov si,offset saveAsText
    call DialogPrompt
save_as_redraw:
    push es
    mov ax,0B800h
    mov es,ax
    mov di,24 * 160
    mov ax,ATTR_TITLE * 256 + ' '
    mov cx,80
    rep stosw
    mov di,24 * 160
    mov si,offset inputPath
    mov bx,dialogLength
    cmp bx,78
    jbe save_as_visible
    sub bx,78
    add si,bx
save_as_visible:
    mov ah,ATTR_TITLE
    call PutString
    pop es
    mov dx,1800h
    mov ax,dialogLength
    cmp ax,78
    jbe save_as_cursor
    mov ax,78
save_as_cursor:
    mov dl,al
    xor bh,bh
    mov ah,02h
    int 10h
    xor ah,ah
    int 16h
    cmp al,27
    je save_as_done
    cmp al,13
    je save_as_accept
    cmp al,8
    je save_as_backspace
    cmp al,32
    jb save_as_redraw
    cmp al,127
    jae save_as_redraw
    cmp al,'"'
    je save_as_redraw
    mov bx,dialogLength
    cmp bx,PATH_BYTES - 1
    jae save_as_redraw
    mov inputPath[bx],al
    inc bx
    mov inputPath[bx],0
    mov dialogLength,bx
    jmp save_as_redraw
save_as_backspace:
    mov bx,dialogLength
    or bx,bx
    jz save_as_redraw
    dec bx
    mov inputPath[bx],0
    mov dialogLength,bx
    jmp save_as_redraw
save_as_accept:
    cmp dialogLength,0
    je save_as_done
    mov dx,offset inputPath
    call SaveDocument
    jc save_as_done
    mov si,offset inputPath
    mov di,offset fileName
save_as_copy:
    lodsb
    mov [di],al
    inc di
    or al,al
    jnz save_as_copy
save_as_done:
    ret
SaveAsDialog endp

QuitDialog proc
    cmp dirty,0
    je quit_accept
    mov si,offset quitText
    call DialogPrompt
quit_wait:
    xor ah,ah
    int 16h
    cmp al,27
    je quit_cancel
    or al,20h
    cmp al,'d'
    je quit_accept
    cmp al,'s'
    jne quit_wait
    mov dx,offset fileName
    call SaveDocument
    jc quit_cancel
quit_accept:
    mov quitRequested,1
quit_cancel:
    ret
QuitDialog endp

IFDEF BINED_TEST
    include TESTS\CORE.INC
ENDIF

_TEXT ends
end Main
