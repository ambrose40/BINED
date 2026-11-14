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

; Test-only DOS fault interception; release instructions remain direct INT 21h.
DISK_INT macro
IFDEF BINED_TEST
    call TestDiskInterrupt
ELSE
    int 21h
ENDIF
endm

STACK_BYTES     equ 4096
MAX_PARAGRAPHS  equ 8000h          ; 512 KiB, subject to conventional memory
IO_CHUNK        equ 4000h          ; never cross a 64 KiB segment boundary
PATH_BYTES      equ 128
DATA_ROWS       equ 20
DATA_TOP        equ 2
DATA_COLUMN     equ 10
TEXT_ROW_EOF    equ 0
TEXT_ROW_WRAP   equ 1
TEXT_KIND_BREAK equ 2
TEXT_CACHE_ROWS equ 128
SEARCH_BYTES    equ 32
SEARCH_INPUT_MAX equ 96
ERROR_LEFT      equ 1
ERROR_TOP       equ 5
ERROR_WIDTH     equ 78
ERROR_HEIGHT    equ 14
HELP_LEFT       equ 11
HELP_TOP        equ 2
HELP_WIDTH      equ 58
HELP_HEIGHT     equ 21
; VGA text attributes: background in the high nibble, foreground in the low.
; Black backgrounds; 01h blue, 02h dark green, 05h dark purple, 0Dh purple.
ATTR_NORMAL     equ 0Ah           ; numeric data / full-screen Text characters
ATTR_TITLE      equ 02h           ; dark-green dialog text
ATTR_OFFSET     equ 02h           ; dark-green row offsets
ATTR_SELECTED   equ 0Dh           ; purple selected byte / EOF marker
ATTR_STATUS     equ 0Ah           ; green Offset / Size / Capacity labels
ATTR_VALUE      equ 05h           ; dark-purple Offset / Size / Capacity values
ATTR_FOOTER     equ 07h           ; light-gray bottom line
ATTR_HELP_KEY   equ 0Eh           ; bright-yellow key names in F1 help
ATTR_HEADING    equ 0Fh           ; bright-white editor title
ATTR_COLUMN     equ 0Ch           ; bright-red OFFSET / DATA / ASCII labels
ATTR_MODE       equ 0Eh           ; bright-yellow HEX / BIN / ASCII / Text mode
ATTR_ASCII      equ 07h           ; light-gray ASCII preview
ATTR_ASCII_SELECTED equ 0Ch       ; bright-red selected preview in HEX/BIN numeric focus

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
editMode        db 0               ; 0 = hex, 1 = binary, 2 = ASCII, 3 = Text
viewMode        db 0               ; layout: 0 = hex, 1 = binary, 2 = full Text
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
gotoInput       db 10 dup (0)       ; nine visible chars + terminator, parsed as <=8
gotoLength      dw 0
gotoDone        db 0               ; 0 = editing, 1 = accepted, 2 = cancelled
gotoError       dw 0
searchInput     db SEARCH_INPUT_MAX+1 dup (0)
searchInputLength dw 0
searchType      db 0               ; 0 = exact, case-sensitive ASCII; 1 = hex bytes
searchSavedType db 0
searchDone      db 0               ; 0 = editing, 1 = searched, 2 = cancelled
searchError     dw 0
searchCandidate db SEARCH_BYTES dup (0)
searchCandidateLength dw 0
searchPattern   db SEARCH_BYTES dup (0)
searchLength    dw 0
searchPrefix    dw SEARCH_BYTES dup (0)
searchStart     dd 0
searchWrapped   db 0
searchHaveMatch db 0
searchLastMatch dd 0               ; raw byte position, before Text CR/LF normalization
searchCursorAtMatch dd 0
textCursorRow   dw 0
textCursorCol   dw 0
textAbsoluteLine dd 0
textGoalColumn  dw 0
textGoalValid   db 0
textRowEnd      dd 0
textRowNext     dd 0
textMoveRows    dd 0
textLastByte    db 0
textLastValid   db 0
textRowWidth    dw 0
textRowKind     db TEXT_ROW_EOF
textCacheCount  dw 0
textCacheNext   dw 0
textCacheSize   dd 0
textDirtyOffset dd 0FFFFFFFFh
textCacheOffsets dd TEXT_CACHE_ROWS dup (0)
textCacheLines   dd TEXT_CACHE_ROWS dup (0)
hexDigits       db '0123456789ABCDEF'
titleText       db ' EZ Binary Editor 3 | 486 real mode | ',0
hexText         db 'HEX',0
binText         db 'BIN',0
changedText     db ' *modified*',0
columnText      db ' OFFSET   DATA',0
asciiText       db 'ASCII',0
asciiHexText    db 'ASCII (HEX)',0
asciiBinText    db 'ASCII (BIN)',0
textModeText    db 'Text',0
textColumnText  db ' TEXT: insert characters | Enter: CR/LF | Backspace/Del: delete',0
byteHexText     db 'HEX: ',0
byteBinText     db '  BIN: ',0
textLineLabel   db 'Ln: ',0
textColLabel    db ' Col:',0
textInsertLabel db ' INS',0
saveErrorTitle  db ' Save error ',0
saveErrorLabel  db 'DOS error: ',0
saveTargetLabel db 'Target / original:',0
saveBackupLabel db 'Original backup:',0
saveStageLabel  db 'Staged data:',0
offsetText      db 'Offset: ',0
sizeText        db '  Size: ',0
capacityText    db '  Capacity: ',0
helpTitle       db ' F1 Help ',0
helpText1       db 'Arrows: move between digits, bits, bytes and rows.',0
helpText2       db 'PgUp / PgDn: move one page up / down.',0
helpText3       db 'Home / End: move to the row start / end.',0
helpText4       db 'Ctrl-Home / Ctrl-End: move to file start / EOF.',0
helpText5       db 'Ins / Del: insert 00 / delete the current byte.',0
helpText6       db '0-9 / A-F (hex), 0 / 1 (binary): type to edit.',0
helpText7       db 'ASCII / Text: overwrite / insert printable text.',0
helpText8       db 'At EOF, typing appends a byte.',0
helpText9       db 'Space: next byte in numeric; text in ASCII/Text.',0
helpText10      db 'Backspace: previous byte; deletes in Text.',0
helpText11      db 'F2 / F4: save / save the file under a new name.',0
helpText12      db 'F9 / F3: search (Tab TEXT/HEX) / next, wraps.',0
helpText13      db 'F5 / F6: switch to binary / hex digit editing.',0
helpText14      db 'F7: full-screen Text editing (Enter inserts CR/LF).',0
helpText15      db 'F8: go to a hex file offset (EOF allowed).',0
helpText16      db 'Tab: ASCII/numeric in HEX/BIN; tab byte in Text.',0
helpText17      db 'Esc: quit (prompts if changes are unsaved).',0
helpLines       dw offset helpText1, offset helpText2, offset helpText3
                dw offset helpText4, offset helpText5, offset helpText6
                dw offset helpText7, offset helpText8, offset helpText9
                dw offset helpText10, offset helpText11, offset helpText12
                dw offset helpText13, offset helpText14, offset helpText15
                dw offset helpText16, offset helpText17, 0
helpReturn      db 'Any key: return to the editor.',0
saveAsText      db 'Save as (Esc cancels, Enter accepts):',0
gotoPrompt      db 'Go to offset (HEX, 0..EOF; Enter accepts, Esc cancels):',0
gotoInvalid     db 'Enter 1-8 hex digits (0-9, A-F). Backspace corrects; Esc cancels.',0
gotoRange       db 'Offset is beyond EOF. Correct it or press Esc to cancel.',0
gotoEOFText     db 'EOF: ',0
gotoCurrentText db 'Current: ',0
searchPrompt    db 'Search: Enter finds (empty repeats), Tab TEXT/HEX, Esc cancels.',0
searchTextError db 'TEXT: enter 1-32 printable characters (case-sensitive).',0
searchHexError  db 'HEX: enter 1-32 byte pairs, e.g. 41 42 00 or 414200.',0
searchSizeError db 'Search input is too long. Backspace corrects; Esc cancels.',0
searchNoPrevious db 'No previous search. Enter a pattern first.',0
searchModeLabel db 'Mode: ',0
searchTextLabel db 'TEXT',0
searchHexLabel  db 'HEX',0
msgSearchFound  db 'Match found. F3 finds the next match.',0
msgSearchWrapped db 'Match found (wrapped). F3 finds the next match.',0
msgSearchMissing db 'Search pattern not found.',0
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
    call MarkTextChanged
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
    mov searchHaveMatch,0
    call ResetTextCache
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
    DISK_INT
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
    DISK_INT
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
    DISK_INT
    ret
CreateSiblingTemp endp

; DS:DX = target path. A staged save avoids truncating the original on errors.
; The old file is renamed to a unique sibling until the new rename succeeds.
; On install failure try to restore it; leave recovery files if that fails.
; CF clear only after the new file has been fully written, closed and installed.
SaveDocument proc
    mov saveTarget,dx
    mov lastError,0
    mov stageExists,0
    mov backupExists,0
    mov ax,4300h
    DISK_INT
    jc save_check_missing
    test cx,11h                    ; read-only or directory
    jnz save_read_only
    jmp save_create_stage
save_check_missing:
    cmp ax,2
    jne save_record_error
save_create_stage:
    mov si,saveTarget
    mov di,offset stagePath
    call CreateSiblingTemp
    jc save_record_error
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
    DISK_INT
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
    DISK_INT                       ; deletion failure leaves a harmless backup
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
    jc save_record_error           ; retain both files for manual recovery
    mov backupExists,0
    mov ax,lastError
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
    DISK_INT
    jc save_error
    mov stageExists,0
    jmp save_error
save_record_error:
    mov lastError,ax
save_error:
    mov statusText,offset msgSaveError
    stc
    ret
save_read_only:
    mov lastError,5
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
    DISK_INT
    pop es
    ret
RenameFile endp

; ---------------------------------------------------------------------------
; Editor operations. The byte buffer is the only source of truth. Drawing and
; switching modes never parse characters back out of the display.
; ---------------------------------------------------------------------------
SetMode proc
    ; AL = 0 (hex), 1 (binary), 2 (ASCII in numeric view), or 3 (Text).
    mov editMode,al
    mov digitIndex,0
    mov textLastValid,0
    mov textGoalValid,0
    cmp al,3
    jne set_mode_numeric
    cmp viewMode,2
    je set_mode_text_layout
    mov viewMode,2
    mov viewOffset,0
set_mode_text_layout:
    mov digitsPerByte,1
    mov bytesPerRow,80
    mov pageBytes,DATA_ROWS * 80
    ret
set_mode_numeric:
    cmp al,2
    je set_mode_layout
    cmp al,viewMode
    je set_mode_layout
    mov viewMode,al
    mov viewOffset,0
set_mode_layout:
    mov digitsPerByte,2
    mov bytesPerRow,16
    mov pageBytes,DATA_ROWS * 16
    cmp viewMode,1
    jne set_mode_focus
    mov digitsPerByte,8
    mov bytesPerRow,6
    mov pageBytes,DATA_ROWS * 6
set_mode_focus:
    cmp editMode,2
    jne set_mode_done
    mov digitsPerByte,1
set_mode_done:
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

; AL = printable 7-bit ASCII byte. Overwrite or append, then advance one byte.
; Controls and extended characters are ignored; hex/binary can edit any byte.
EditAscii proc
    cmp al,20h
    jb edit_ascii_done
    cmp al,7Eh
    ja edit_ascii_done
    mov dl,al
    mov eax,cursorOffset
    cmp eax,fileSize
    jb edit_ascii_existing
    cmp eax,bufferCapacity
    jae edit_ascii_full
    inc fileSize
    jmp edit_ascii_write
edit_ascii_existing:
    call ReadByte
    cmp al,dl
    je edit_ascii_advance
    mov eax,cursorOffset
edit_ascii_write:
    call WriteByte
    mov dirty,1
edit_ascii_advance:
    call MoveRight
edit_ascii_done:
    ret
edit_ascii_full:
    mov statusText,offset msgFull
    ret
EditAscii endp

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
    mov eax,esi
    call MarkTextChanged
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

; EAX changed byte -> lazy cache invalidation. Preserve all general registers.
MarkTextChanged proc
    mov searchHaveMatch,0
    mov textGoalValid,0
    cmp eax,textDirtyOffset
    jae text_changed_done
    mov textDirtyOffset,eax
text_changed_done:
    ret
MarkTextChanged endp

ResetTextCache proc
    mov textCacheCount,0
    mov textCacheNext,0
    mov textDirtyOffset,0FFFFFFFFh
    push eax
    mov eax,fileSize
    mov textCacheSize,eax
    pop eax
    ret
ResetTextCache endp

; Invalidate anchors after the earliest edit (including CR/LF boundary effects).
; This runs once per edit batch, rather than once per shifted byte.
ValidateTextCache proc
    pushad
    mov eax,textDirtyOffset
    cmp eax,0FFFFFFFFh
    jne text_cache_dirty
    mov eax,fileSize
    cmp eax,textCacheSize
    je text_cache_valid
    call ResetTextCache           ; size changed without byte writes
    jmp text_cache_valid
text_cache_dirty:
    sub eax,2
    jnc text_cache_limit
    xor eax,eax
text_cache_limit:
    xor esi,esi
    xor edi,edi
    movzx ecx,textCacheCount
text_cache_compact:
    jecxz text_cache_compacted
    mov edx,textCacheOffsets[si]
    cmp edx,eax
    jae text_cache_discard
    mov textCacheOffsets[di],edx
    mov edx,textCacheLines[si]
    mov textCacheLines[di],edx
    add edi,4
text_cache_discard:
    add esi,4
    dec ecx
    jmp text_cache_compact
text_cache_compacted:
    shr edi,2
    mov textCacheCount,di
    mov textCacheNext,di
    cmp di,TEXT_CACHE_ROWS
    jb text_cache_compact_done
    mov textCacheNext,0
text_cache_compact_done:
    mov textDirtyOffset,0FFFFFFFFh
    mov eax,fileSize
    mov textCacheSize,eax
text_cache_valid:
    popad
    ret
ValidateTextCache endp

; EAX row start, EBX absolute row -> store checkpoint in a bounded ring.
CacheTextRow proc
    pushad
    xor esi,esi
    movzx ecx,textCacheCount
text_cache_duplicate:
    jecxz text_cache_add
    cmp textCacheOffsets[si],eax
    je text_cache_added
    add esi,4
    dec ecx
    jmp text_cache_duplicate
text_cache_add:
    movzx esi,textCacheNext
    shl esi,2
    mov textCacheOffsets[si],eax
    mov textCacheLines[si],ebx
    cmp textCacheCount,TEXT_CACHE_ROWS
    jae text_cache_advance
    inc textCacheCount
text_cache_advance:
    inc textCacheNext
    cmp textCacheNext,TEXT_CACHE_ROWS
    jb text_cache_added
    mov textCacheNext,0
text_cache_added:
    popad
    ret
CacheTextRow endp

; Text rows wrap at 80 cells; CR/LF, bare CR and bare LF end a row.
; EAX row start -> EDX content end, EAX next row start (equal at hard wrap/EOF).
; Preserves EBX/ECX/ESI; all reads are bounded by fileSize.
NextTextRow proc
IFDEF BINED_TEST
    inc textRowScans
ENDIF
    push ebx
    push ecx
    push esi
    mov esi,eax
    xor ecx,ecx
    mov textRowKind,TEXT_ROW_EOF
text_row_scan:
    cmp esi,fileSize
    jae text_row_end
    mov eax,esi
    call ReadByte
    cmp al,13
    je text_row_break
    cmp al,10
    je text_row_break
    cmp al,9
    jne text_row_character
    or ecx,7
text_row_character:
    inc ecx
    inc esi
    cmp ecx,80
    jb text_row_scan
    mov textRowKind,TEXT_ROW_WRAP
    ; A newline immediately after a full row terminates that same row.
    cmp esi,fileSize
    jae text_row_end
    mov eax,esi
    call ReadByte
    cmp al,13
    je text_row_break
    cmp al,10
    je text_row_break
text_row_end:
    mov edx,esi
    mov eax,esi
    jmp text_row_return
text_row_break:
    mov textRowKind,TEXT_KIND_BREAK
    mov edx,esi
    inc esi
    cmp al,13
    jne text_row_next
    cmp esi,fileSize
    jae text_row_next
    mov eax,esi
    call ReadByte
    cmp al,10
    jne text_row_next
    inc esi
text_row_next:
    mov eax,esi
text_row_return:
    mov textRowWidth,cx
    pop esi
    pop ecx
    pop ebx
    ret
NextTextRow endp

; EAX offset -> EAX display-row start, EBX row number, ECX column, EDX row end.
; CR/LF's two offsets share one cursor cell. EOF after a wrap starts a new row.
FindTextRow proc
    push esi
    push edi
    push ebp
    call ValidateTextCache
    mov edi,eax
    cmp edi,fileSize
    jbe text_find_start
    mov edi,fileSize
text_find_start:
    xor esi,esi
    xor ebx,ebx
    xor ebp,ebp
    movzx edx,textCacheCount
    shl edx,2
text_find_anchor:
    cmp ebp,edx
    jae text_find_next
    mov eax,ds:textCacheOffsets[bp]
    cmp eax,edi
    ja text_find_anchor_skip
    cmp eax,esi
    jb text_find_anchor_skip
    mov esi,eax
    mov ebx,ds:textCacheLines[bp]
text_find_anchor_skip:
    add ebp,4
    jmp text_find_anchor
text_find_next:
    mov eax,esi
    call NextTextRow
    cmp eax,esi
    je text_find_done
    cmp edi,eax
    jb text_find_done
    cmp eax,fileSize
    jne text_find_advance
    cmp eax,edx
    jne text_find_advance
    push eax
    push edx
    mov edx,eax
    mov eax,esi
    call TextColumn
    pop edx
    pop eax
    cmp ecx,80
    jb text_find_done              ; EOF after a short row stays on that row
text_find_advance:
    mov esi,eax
    inc ebx
    test bl,31
    jnz text_find_next
    call CacheTextRow
    jmp text_find_next
text_find_done:
    cmp edi,edx
    jbe text_find_column
    mov edi,edx
text_find_column:
    push edx
    mov edx,edi
    mov eax,esi
    call TextColumn
    pop edx
    mov eax,esi
    call CacheTextRow
    cmp ecx,80
    jb text_find_visible_column
    mov ecx,79                    ; full-row newline shares the last cursor cell
text_find_visible_column:
    pop ebp
    pop edi
    pop esi
    ret
FindTextRow endp

; EAX row start, EDX byte position -> ECX display column (8-column tab stops).
; Preserves EDX/EBX/ESI. Target must be in this row's content.
TextColumn proc
    push ebx
    push esi
    mov esi,eax
    xor ecx,ecx
text_column_next:
    cmp esi,edx
    jae text_column_done
    mov eax,esi
    call ReadByte
    cmp al,9
    jne text_column_character
    or ecx,7
text_column_character:
    inc ecx
    inc esi
    jmp text_column_next
text_column_done:
    pop esi
    pop ebx
    ret
TextColumn endp

; EAX row start, EDX row end, ECX desired column -> EAX byte at/before column.
; A tab is one editable byte, with no cursor positions inside its expansion.
TextOffsetAtColumn proc
    push ebx
    push esi
    mov esi,eax
    xor ebx,ebx
text_offset_next:
    cmp esi,edx
    jae text_offset_done
    mov eax,esi
    call ReadByte
    cmp al,9
    jne text_offset_character
    or ebx,7
text_offset_character:
    inc ebx
    cmp ebx,ecx
    ja text_offset_done
    inc esi
    jmp text_offset_next
text_offset_done:
    mov eax,esi
    pop esi
    pop ebx
    ret
TextOffsetAtColumn endp

; EBX display-row number -> EAX row start, saturating at EOF.
TextLineOffset proc
    push ebp
    push ebx
    push ecx
    push edx
    push esi
    push edi
    call ValidateTextCache
    mov edi,ebx
    xor ebx,ebx
    xor esi,esi
    xor ebp,ebp
    movzx edx,textCacheCount
    shl edx,2
text_line_anchor:
    cmp ebp,edx
    jae text_line_next
    mov eax,ds:textCacheLines[bp]
    cmp eax,edi
    ja text_line_anchor_skip
    cmp eax,ebx
    jb text_line_anchor_skip
    mov ebx,eax
    mov esi,ds:textCacheOffsets[bp]
text_line_anchor_skip:
    add ebp,4
    jmp text_line_anchor
text_line_next:
    mov eax,esi
    cmp ebx,edi
    jae text_line_done
    cmp eax,fileSize
    jae text_line_done
    call NextTextRow
    mov esi,eax
    inc ebx
    test bl,31
    jnz text_line_next
    call CacheTextRow
    jmp text_line_next
text_line_done:
    call CacheTextRow
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret
TextLineOffset endp

EnsureTextVisible proc
    ; A mode change may land on the LF half of CR/LF. Use the CR cursor cell.
    mov esi,cursorOffset
    test esi,esi
    jz text_visible_find
    cmp esi,fileSize
    jae text_visible_find
    mov eax,esi
    call ReadByte
    cmp al,10
    jne text_visible_find
    lea eax,[esi-1]
    call ReadByte
    cmp al,13
    jne text_visible_find
    dec cursorOffset
text_visible_find:
    mov eax,cursorOffset
    call FindTextRow
    mov ebp,ebx
    mov textAbsoluteLine,ebx
    mov textCursorCol,cx
    mov eax,viewOffset
    call FindTextRow
    mov viewOffset,eax
    cmp ebp,ebx
    jb text_visible_above
    lea eax,[ebx+DATA_ROWS]
    cmp ebp,eax
    jb text_visible_position
    mov ebx,ebp
    sub ebx,DATA_ROWS-1
    jmp text_visible_scroll
text_visible_above:
    mov ebx,ebp
text_visible_scroll:
    call TextLineOffset
    mov viewOffset,eax
text_visible_position:
    sub ebp,ebx
    mov textCursorRow,bp
    ret
EnsureTextVisible endp

TextLeft proc
    mov esi,cursorOffset
    test esi,esi
    jz text_left_done
    dec esi
    mov eax,esi
    call ReadByte
    cmp al,10
    jne text_left_set
    test esi,esi
    jz text_left_set
    lea eax,[esi-1]
    call ReadByte
    cmp al,13
    jne text_left_set
    dec esi
text_left_set:
    mov cursorOffset,esi
text_left_done:
    ret
TextLeft endp

TextRight proc
    mov esi,cursorOffset
    cmp esi,fileSize
    jae text_right_done
    mov eax,esi
    call ReadByte
    inc esi
    cmp al,13
    jne text_right_set
    cmp esi,fileSize
    jae text_right_set
    mov eax,esi
    call ReadByte
    cmp al,10
    jne text_right_set
    inc esi
text_right_set:
    mov cursorOffset,esi
text_right_done:
    ret
TextRight endp

; EAX signed display-row displacement. Retain column, clamp on shorter rows.
TextVertical proc
    mov textMoveRows,eax
    mov eax,cursorOffset
    call FindTextRow
    cmp textGoalValid,0
    jne text_vertical_goal
    mov textGoalColumn,cx
    mov textGoalValid,1
text_vertical_goal:
    movzx ebp,textGoalColumn
    add ebx,textMoveRows
    jns text_vertical_row
    xor ebx,ebx
text_vertical_row:
    call TextLineOffset
    mov esi,eax
    call NextTextRow
    cmp textRowWidth,80
    jne text_vertical_column
    dec edx                       ; wrap boundary belongs to the next row
text_vertical_column:
    mov eax,esi
    mov ecx,ebp
    call TextOffsetAtColumn
    mov cursorOffset,eax
    ret
TextVertical endp

; Text typing inserts; Enter inserts a complete DOS CR/LF or nothing if full.
EditText proc
    cmp al,13
    je text_enter
    cmp al,9
    je text_edit_insert
    cmp al,20h
    jb text_edit_done
    cmp al,7Eh
    ja text_edit_done
text_edit_insert:
    mov edx,fileSize
    cmp edx,bufferCapacity
    jae text_edit_full
    call InsertTextCharacter
text_edit_done:
    ret
text_enter:
    mov edx,bufferCapacity
    sub edx,fileSize
    cmp edx,2
    jb text_edit_full
    mov al,13
    call InsertTextCharacter
    mov al,10
    call InsertTextCharacter
    mov textLastByte,13
    ret
text_edit_full:
    mov statusText,offset msgFull
    ret
EditText endp

; Caller has checked capacity. Insert AL and advance past it.
InsertTextCharacter proc
    mov textLastByte,al
    push ax
    call InsertByte
    pop dx
    mov eax,cursorOffset
    call WriteByte
    inc cursorOffset
    mov textLastValid,1
    ret
InsertTextCharacter endp

; Delete a complete CR/LF pair, or one ordinary byte; EOF remains a no-op.
DeleteText proc
    mov esi,cursorOffset
    cmp esi,fileSize
    jae text_delete_done
    mov eax,esi
    call ReadByte
    cmp al,13
    jne text_delete_one
    inc esi
    cmp esi,fileSize
    jae text_delete_one
    mov eax,esi
    call ReadByte
    cmp al,10
    jne text_delete_one
    call DeleteByte
text_delete_one:
    call DeleteByte
text_delete_done:
    ret
DeleteText endp

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

; F9 draft input is independent of the last committed pattern (Esc is non-destructive).
ResetSearchInput proc
    mov searchInput,0
    mov searchInputLength,0
    mov searchDone,0
    mov searchError,0
    mov al,searchSavedType
    cmp searchLength,0
    jne search_default_ready
    xor al,al
    cmp viewMode,2
    je search_default_ready
    cmp editMode,2
    je search_default_ready
    mov al,1
search_default_ready:
    mov searchType,al
    ret
ResetSearchInput endp

; Validate draft into a separate byte buffer. Hex spaces are allowed between pairs.
ParseSearchPattern proc
    mov searchCandidateLength,0
    mov cx,searchInputLength
    jcxz search_parse_empty
    cmp cx,SEARCH_INPUT_MAX-1
    ja search_parse_size
    mov si,offset searchInput
    cmp searchType,0
    jne search_parse_hex
    cmp cx,SEARCH_BYTES
    ja search_parse_text_bad
    mov searchCandidateLength,cx
    mov di,offset searchCandidate
search_parse_text:
    lodsb
    cmp al,20h
    jb search_parse_text_bad
    cmp al,7Eh
    ja search_parse_text_bad
    mov [di],al
    inc di
    loop search_parse_text
    clc
    ret
search_parse_hex:
    xor bx,bx
    xor dx,dx                     ; DL byte under construction, DH pending nibble
search_parse_hex_next:
    jcxz search_parse_hex_end
    lodsb
    dec cx
    cmp al,' '
    je search_parse_separator
    call AsciiToHex
    jc search_parse_hex_bad
    shl dl,4
    or dl,al
    xor dh,1
    jnz search_parse_hex_next
    cmp bx,SEARCH_BYTES
    jae search_parse_hex_bad
    mov searchCandidate[bx],dl
    inc bx
    xor dl,dl
    jmp search_parse_hex_next
search_parse_separator:
    test dh,dh
    jnz search_parse_hex_bad
    jmp search_parse_hex_next
search_parse_hex_end:
    test dh,dh
    jnz search_parse_hex_bad
    test bx,bx
    jz search_parse_hex_bad
    mov searchCandidateLength,bx
    clc
    ret
search_parse_empty:
    mov searchError,offset searchNoPrevious
    stc
    ret
search_parse_size:
    mov searchError,offset searchSizeError
    stc
    ret
search_parse_text_bad:
    mov searchError,offset searchTextError
    stc
    ret
search_parse_hex_bad:
    mov searchError,offset searchHexError
    stc
    ret
ParseSearchPattern endp

; Prefix lengths for KMP: search work is linear even for repetitive patterns.
BuildSearchPrefix proc
    mov searchPrefix,0
    mov si,1
    mov di,2
    xor bx,bx
search_prefix_next:
    cmp si,searchLength
    jae search_prefix_done
    mov al,searchPattern[si]
search_prefix_compare:
    cmp al,searchPattern[bx]
    je search_prefix_match
    test bx,bx
    jz search_prefix_store
    mov bp,bx
    dec bp
    shl bp,1
    mov bx,ds:searchPrefix[bp]
    jmp search_prefix_compare
search_prefix_match:
    inc bx
search_prefix_store:
    mov searchPrefix[di],bx
    inc si
    add di,2
    jmp search_prefix_next
search_prefix_done:
    ret
BuildSearchPrefix endp

CommitSearchPattern proc
    mov cx,searchCandidateLength
    mov searchLength,cx
    mov si,offset searchCandidate
    mov di,offset searchPattern
search_commit_byte:
    lodsb
    mov [di],al
    inc di
    loop search_commit_byte
    mov al,searchType
    mov searchSavedType,al
    mov searchHaveMatch,0
    call BuildSearchPrefix
    ret
CommitSearchPattern endp

; EAX start byte, EDX exclusive end byte -> EAX match start, CF if absent.
; All accesses use the DOS-owned buffer and stay below fileSize.
SearchSegment proc
    mov esi,eax
    xor bx,bx
search_segment_next:
    cmp esi,edx
    jae search_segment_absent
    mov eax,esi
    call ReadByte
IFDEF BINED_TEST
    inc searchReadCount
ENDIF
search_segment_compare:
    cmp al,searchPattern[bx]
    je search_segment_match
    test bx,bx
    jz search_segment_advance
    mov bp,bx
    dec bp
    shl bp,1
    mov bx,ds:searchPrefix[bp]
    jmp search_segment_compare
search_segment_match:
    inc bx
    cmp bx,searchLength
    jne search_segment_advance
    lea eax,[esi+1]
    movzx ecx,searchLength
    sub eax,ecx
    clc
    ret
search_segment_advance:
    inc esi
    jmp search_segment_next
search_segment_absent:
    stc
    ret
SearchSegment endp

; EAX first candidate offset. Search to EOF, then earlier candidates once.
; A match can cross the starting offset or 64 KiB, but never physical EOF.
FindSearchPattern proc
    mov searchStart,eax
    mov searchWrapped,0
    movzx edx,searchLength
    test edx,edx
    jz search_pattern_absent
    cmp edx,fileSize
    ja search_pattern_absent
    mov ecx,fileSize
    sub ecx,edx
    cmp eax,ecx
    ja search_pattern_wrap
    mov edx,fileSize
    call SearchSegment
    jnc search_pattern_return
search_pattern_wrap:
    mov edx,searchStart
    test edx,edx
    jz search_pattern_absent
    movzx ecx,searchLength
    add edx,ecx
    dec edx
    cmp edx,fileSize
    jbe search_pattern_wrap_end
    mov edx,fileSize
search_pattern_wrap_end:
    mov searchWrapped,1
    xor eax,eax
    call SearchSegment
search_pattern_return:
    ret
search_pattern_absent:
    stc
    ret
FindSearchPattern endp

; Search and navigate only on success. A miss never changes position/selection.
RunSearch proc
    mov searchHaveMatch,0
    call FindSearchPattern
    jc search_run_missing
    mov searchLastMatch,eax
    mov digitIndex,0
    mov textGoalValid,0
    mov textLastValid,0
    call SetCursor
    call EnsureVisible
    mov eax,cursorOffset
    mov searchCursorAtMatch,eax
    mov searchHaveMatch,1
    mov statusText,offset msgSearchFound
    cmp searchWrapped,0
    je search_run_done
    mov statusText,offset msgSearchWrapped
search_run_done:
    mov searchDone,1
    mov searchError,0
    clc
    ret
search_run_missing:
    mov statusText,offset msgSearchMissing
    mov searchDone,1
    mov searchError,0
    stc
    ret
RunSearch endp

RepeatSearch proc
    cmp searchLength,0
    je search_repeat_empty
    mov eax,cursorOffset
    cmp searchHaveMatch,0
    je search_repeat_start
    cmp eax,searchCursorAtMatch
    jne search_repeat_start
    mov eax,searchLastMatch        ; do not rediscover a Text-normalized LF forever
search_repeat_start:
    inc eax
    jmp RunSearch
search_repeat_empty:
    mov statusText,offset searchNoPrevious
    stc
    ret
RepeatSearch endp

AcceptSearch proc
    cmp searchInputLength,0
    jne search_accept_new
    cmp searchLength,0
    jne RepeatSearch
    mov searchError,offset searchNoPrevious
    stc
    ret
search_accept_new:
    call ParseSearchPattern
    jc search_accept_done
    call CommitSearchPattern
    mov eax,cursorOffset          ; a new search includes the selected byte
    call RunSearch
search_accept_done:
    ret
AcceptSearch endp

HandleSearchKey proc
    cmp al,27
    je search_key_cancel
    cmp al,13
    je AcceptSearch
    cmp al,9
    je search_key_type
    cmp al,8
    je search_key_backspace
    cmp al,20h
    jb search_key_done
    cmp al,7Eh
    ja search_key_done
    mov bx,searchInputLength
    cmp bx,SEARCH_INPUT_MAX
    jae search_key_limit
    mov searchInput[bx],al
    inc bx
    mov searchInput[bx],0
    mov searchInputLength,bx
    mov searchError,0
search_key_done:
    ret
search_key_limit:
    mov searchError,offset searchSizeError
    ret
search_key_cancel:
    mov searchDone,2
    ret
search_key_type:
    xor searchType,1
    mov searchError,0
    ret
search_key_backspace:
    mov bx,searchInputLength
    test bx,bx
    jz search_key_done
    dec bx
    mov searchInput[bx],0
    mov searchInputLength,bx
    mov searchError,0
    ret
HandleSearchKey endp

; DS:SI zero-terminated hexadecimal offset -> EAX, CF on empty/invalid/>8 digits.
; Parse into EDX so character conversion cannot corrupt the accumulator's AL.
ParseHexOffset proc
    xor edx,edx
    xor cx,cx
parse_offset_next:
    lodsb
    test al,al
    jz parse_offset_end
    cmp cx,8
    jae parse_offset_bad
    call AsciiToHex
    jc parse_offset_bad
    movzx ebx,al
    shl edx,4
    or edx,ebx
    inc cx
    jmp parse_offset_next
parse_offset_end:
    jcxz parse_offset_bad
    mov eax,edx
    clc
    ret
parse_offset_bad:
    stc
    ret
ParseHexOffset endp

ResetGotoInput proc
    mov gotoInput,0
    mov gotoLength,0
    mov gotoDone,0
    mov gotoError,0
    ret
ResetGotoInput endp

; Validate before changing any navigation state. Range errors do not clamp.
ApplyGotoOffset proc
    mov si,offset gotoInput
    call ParseHexOffset
    jc goto_offset_invalid
    cmp eax,fileSize
    ja goto_offset_range
    mov digitIndex,0
    mov textGoalValid,0
    mov textLastValid,0
    call SetCursor
    call EnsureVisible
    mov gotoDone,1
    mov gotoError,0
    clc
    ret
goto_offset_invalid:
    mov gotoError,offset gotoInvalid
    stc
    ret
goto_offset_range:
    mov gotoError,offset gotoRange
    stc
    ret
ApplyGotoOffset endp

; AX BIOS key -> bounded dialog input. Navigation/file state changes on accept only.
HandleGotoKey proc
    cmp al,27
    je goto_key_cancel
    cmp al,13
    je ApplyGotoOffset
    cmp al,8
    je goto_key_backspace
    cmp al,20h
    jb goto_key_done
    cmp al,7Eh
    ja goto_key_done
    mov bx,gotoLength
    cmp bx,9
    jae goto_key_limit
    mov gotoInput[bx],al
    inc bx
    mov gotoInput[bx],0
    mov gotoLength,bx
    mov gotoError,0
goto_key_done:
    ret
goto_key_limit:
    mov gotoError,offset gotoInvalid
    ret
goto_key_cancel:
    mov gotoDone,2
    ret
goto_key_backspace:
    mov bx,gotoLength
    test bx,bx
    jz goto_key_done
    dec bx
    mov gotoInput[bx],0
    mov gotoLength,bx
    mov gotoError,0
    ret
HandleGotoKey endp

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
    cmp viewMode,2
    je EnsureTextVisible
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
    mov textLastValid,0
    cmp al,0
    je key_check_vertical
    cmp al,0E0h
    jne key_reset_goal
key_check_vertical:
    cmp ah,48h
    je key_goal_ready
    cmp ah,50h
    je key_goal_ready
    cmp ah,49h
    je key_goal_ready
    cmp ah,51h
    je key_goal_ready
key_reset_goal:
    mov textGoalValid,0
key_goal_ready:
    cmp al,27
    je key_quit
    cmp al,9
    je key_toggle
    cmp al,8
    je key_previous_byte
    cmp al,0
    je key_extended
    cmp al,0E0h
    je key_extended
    cmp viewMode,2
    je key_text_input
    cmp editMode,2
    je key_ascii_input
    cmp al,' '
    je key_next_byte
    call EditDigit
    ret
key_ascii_input:
    call EditAscii
    ret
key_text_input:
    call EditText
    ret
key_extended:
    cmp ah,3Bh
    je key_help
    cmp ah,3Ch
    je key_save
    cmp ah,3Dh
    je key_search_next
    cmp ah,3Eh
    je key_save_as
    cmp ah,3Fh
    je key_binary
    cmp ah,40h
    je key_hex
    cmp ah,41h
    je key_text_mode
    cmp ah,42h
    je key_goto
    cmp ah,43h
    je key_search
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
    cmp viewMode,2
    je TextLeft
    call MoveLeft
    ret
key_right:
    cmp viewMode,2
    je TextRight
    call MoveRight
    ret
key_up:
    cmp viewMode,2
    jne key_up_numeric
    mov eax,-1
    jmp TextVertical
key_up_numeric:
    mov eax,bytesPerRow
    call MoveBackward
    ret
key_down:
    cmp viewMode,2
    jne key_down_numeric
    mov eax,1
    jmp TextVertical
key_down_numeric:
    mov eax,cursorOffset
    add eax,bytesPerRow
    call SetCursor
    ret
key_page_up:
    cmp viewMode,2
    jne key_page_up_numeric
    mov eax,-DATA_ROWS
    jmp TextVertical
key_page_up_numeric:
    mov eax,pageBytes
    call MoveBackward
    ret
key_page_down:
    cmp viewMode,2
    jne key_page_down_numeric
    mov eax,DATA_ROWS
    jmp TextVertical
key_page_down_numeric:
    mov eax,cursorOffset
    add eax,pageBytes
    call SetCursor
    ret
key_home:
    cmp viewMode,2
    jne key_home_numeric
    mov eax,cursorOffset
    call FindTextRow
    mov cursorOffset,eax
    ret
key_home_numeric:
    mov eax,cursorOffset
    xor edx,edx
    div bytesPerRow
    mov eax,cursorOffset
    sub eax,edx
    mov digitIndex,0
    call SetCursor
    ret
key_end:
    cmp viewMode,2
    jne key_end_numeric
    mov eax,cursorOffset
    call FindTextRow
    ; Full rows end on their last character, including at EOF or before CR/LF.
    cmp textRowWidth,80
    jne key_text_end
    dec edx
key_text_end:
    mov cursorOffset,edx
    ret
key_end_numeric:
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
    cmp viewMode,2
    jne key_previous_numeric
    cmp cursorOffset,0
    je key_text_back_done
    call TextLeft
    call DeleteText
key_text_back_done:
    ret
key_previous_numeric:
    mov eax,1
    mov digitIndex,0
    call MoveBackward
    ret
key_toggle:
    cmp viewMode,2
    jne key_toggle_numeric
    mov al,9
    jmp EditText
key_toggle_numeric:
    mov al,2
    cmp editMode,2
    jne key_toggle_set
    mov al,viewMode
key_toggle_set:
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
key_text_mode:
    mov al,3
    call SetMode
    ret
key_goto:
    call GotoDialog
    ret
key_search:
    call SearchDialog
    ret
key_search_next:
    call RepeatSearch
    ret
key_insert:
    call InsertByte
    ret
key_delete:
    cmp viewMode,2
    je DeleteText
    call DeleteByte
    ret
key_save:
    mov dx,offset fileName
    call SaveDocument
    jnc key_save_done
    call SaveErrorDialog
key_save_done:
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
    mov ax,ATTR_HEADING * 256 + ' '
    mov cx,80
    rep stosw
    xor di,di
    mov ah,ATTR_HEADING
    mov si,offset titleText
    call PutString
    mov si,offset hexText
    cmp viewMode,2
    jne render_numeric_mode
    mov si,offset textModeText
    jmp render_mode
render_numeric_mode:
    cmp editMode,2
    jne render_check_binary
    mov si,offset asciiHexText
    cmp viewMode,1
    jne render_mode
    mov si,offset asciiBinText
    jmp render_mode
render_check_binary:
    cmp editMode,0
    je render_mode
    mov si,offset binText
render_mode:
    mov ah,ATTR_MODE
    call PutString
    cmp dirty,0
    je render_columns
    mov ah,ATTR_HEADING
    mov si,offset changedText
    call PutString
render_columns:
    cmp viewMode,2
    jne render_numeric_columns
    mov di,160
    mov ah,ATTR_COLUMN
    mov si,offset textColumnText
    call PutString
    call RenderText
    jmp render_status
render_numeric_columns:
    mov di,160
    mov ah,ATTR_COLUMN
    mov si,offset columnText
    call PutString
    mov di,160 + 61 * 2
    cmp viewMode,1
    jne render_ascii_header
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
render_status:
    mov di,22 * 160
    mov ah,ATTR_STATUS
    mov si,offset offsetText
    call PutString
    mov eax,cursorOffset
    mov bl,ATTR_VALUE
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
    cmp viewMode,2
    jne render_text_status_done
    call RenderTextPosition
render_text_status_done:
    mov di,23 * 160
    mov ah,ATTR_SELECTED
    mov si,offset fileName
    call PutString
    mov di,24 * 160
    mov ah,ATTR_FOOTER
    mov si,statusText
    cmp viewMode,2
    jne render_full_footer
    mov cx,58
    call PutLimitedString
    jmp render_footer_done
render_full_footer:
    call PutString
render_footer_done:
    cmp viewMode,2
    jne render_inspector_done
    call RenderTextValues
render_inspector_done:
    pop es
    call PlaceCursor
    ret
RenderScreen endp

; SI/AH string, CX maximum cells in an explicitly reserved screen region.
PutLimitedString proc
    jcxz limited_string_done
limited_string_next:
    lodsb
    test al,al
    jz limited_string_done
    stosw
    loop limited_string_next
limited_string_done:
    ret
PutLimitedString endp

RenderTextPosition proc
    mov di,22*160 + 54*2
    mov ah,ATTR_STATUS
    mov si,offset textLineLabel
    call PutString
    mov eax,textAbsoluteLine
    inc eax
    mov bl,ATTR_VALUE
    call PutHex32
    mov ah,ATTR_STATUS
    mov si,offset textColLabel
    call PutString
    mov dx,textCursorCol
    inc dl
    mov al,dl
    shr al,4
    call HexCharacter
    mov ah,ATTR_VALUE
    stosw
    mov al,dl
    and al,0Fh
    call HexCharacter
    stosw
    mov ah,ATTR_MODE
    mov si,offset textInsertLabel
    call PutString
    ret
RenderTextPosition endp

; Full-width text content. Use exactly the same row parser as navigation.
RenderText proc
    mov eax,viewOffset
    mov renderOffset,eax
    mov renderRow,0
render_text_row:
    mov renderColumn,0
    mov eax,renderOffset
    call NextTextRow
    mov textRowEnd,edx
    mov textRowNext,eax
    mov ax,renderRow
    add ax,DATA_TOP
    call RowAddress
render_text_character:
    mov eax,renderOffset
    cmp eax,textRowEnd
    jae render_text_marker
    call ReadByte
    cmp al,9
    je render_text_tab
    cmp al,20h
    jb render_text_dot
    cmp al,7Eh
    jbe render_text_output
render_text_dot:
    mov al,'.'
render_text_output:
    mov ah,ATTR_NORMAL
    mov edx,renderOffset
    cmp edx,cursorOffset
    jne render_text_store
    mov ah,ATTR_SELECTED
render_text_store:
    stosw
    inc renderOffset
    inc renderColumn
    jmp render_text_character
render_text_tab:
    mov cx,renderColumn
    and cx,7
    neg cx
    add cx,8
    add renderColumn,cx
    mov ax,ATTR_NORMAL * 256 + ' '
    mov edx,renderOffset
    cmp edx,cursorOffset
    jne render_text_tab_fill
    mov ah,ATTR_SELECTED
render_text_tab_fill:
    stosw
    mov ah,ATTR_NORMAL
    loop render_text_tab_fill
    inc renderOffset
    jmp render_text_character
render_text_marker:
    ; A hard-wrapped row has no spare cell. EOF/newline use a visible cursor.
    mov eax,textRowEnd
    cmp eax,textRowNext
    jne render_text_newline
    cmp eax,fileSize
    jne render_text_advance
    ; An 80-character final row's EOF belongs on the following row.
    cmp renderColumn,80
    je render_text_advance
    mov al,'-'
    jmp render_text_marker_output
render_text_newline:
    cmp eax,cursorOffset
    jne render_text_advance
    mov al,' '
    cmp renderColumn,80
    jne render_text_marker_output
    sub di,2
    mov al,'<'                    ; selected full-width newline, no phantom row
render_text_marker_output:
    mov ah,ATTR_NORMAL
    mov edx,textRowEnd
    cmp edx,cursorOffset
    jne render_text_marker_store
    mov ah,ATTR_SELECTED
render_text_marker_store:
    stosw
render_text_advance:
    mov eax,textRowNext
    cmp eax,renderOffset
    jne render_text_continue
    cmp renderColumn,80
    je render_text_continue
    cmp eax,fileSize
    je render_text_done
render_text_continue:
    mov renderOffset,eax
    inc renderRow
    cmp renderRow,DATA_ROWS
    jb render_text_row
render_text_done:
    ret
RenderText endp

; Bottom-right byte inspector: current byte, or latest typed byte at EOF.
; Navigation clears the typed-byte fallback. Dashes mean no byte is selected.
RenderTextValues proc
    mov renderAttr,0
    mov eax,cursorOffset
    cmp eax,fileSize
    jb render_value_read
    cmp textLastValid,0
    je render_value_labels
    mov al,textLastByte
    jmp render_value_ready
render_value_read:
    call ReadByte
render_value_ready:
    mov renderValue,al
    mov renderAttr,1
render_value_labels:
    mov di,24*160 + 58*2
    mov ah,ATTR_STATUS
    mov si,offset byteHexText
    call PutString
    mov cx,2
    mov dh,renderValue
render_value_hex:
    rol dh,4
    mov al,'-'
    cmp renderAttr,0
    je render_value_hex_store
    mov al,dh
    and al,0Fh
    call HexCharacter
render_value_hex_store:
    mov ah,ATTR_VALUE
    stosw
    loop render_value_hex
    mov ah,ATTR_STATUS
    mov si,offset byteBinText
    call PutString
    mov dh,renderValue
    mov cx,8
render_value_binary:
    mov al,'-'
    cmp renderAttr,0
    je render_value_binary_store
    shl dh,1
    mov al,'0'
    adc al,0
render_value_binary_store:
    mov ah,ATTR_VALUE
    stosw
    loop render_value_binary
    ret
RenderTextValues endp

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
    cmp viewMode,1
    jne render_byte_stride
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
    mov cl,2                      ; ASCII preserves the numeric view's digits
    cmp viewMode,1
    jne render_digit_count
    mov cl,8
render_digit_count:
    mov dh,renderValue
render_digit:
    mov eax,renderOffset
    cmp eax,fileSize
    mov al,'-'
    je render_digit_output
    cmp viewMode,1
    je render_binary_digit
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
    ; Printable preview / ASCII editing column. ASCII mode also marks EOF.
    mov eax,renderOffset
    cmp eax,fileSize
    jb render_ascii_cell
    cmp editMode,2
    jne render_byte_done
render_ascii_cell:
    mov ax,renderRow
    add ax,DATA_TOP
    call RowAddress
    mov ax,renderColumn
    add ax,61
    cmp viewMode,1
    jne render_ascii_position
    add ax,5
render_ascii_position:
    shl ax,1
    add di,ax
    mov eax,renderOffset
    cmp eax,fileSize
    mov al,'-'
    je render_ascii_output
    mov al,renderValue
    cmp al,32
    jb render_ascii_dot
    cmp al,126
    jbe render_ascii_output
render_ascii_dot:
    mov al,'.'
render_ascii_output:
    mov ah,ATTR_ASCII
    mov edx,renderOffset
    cmp edx,cursorOffset
    jne render_ascii_store
    mov ah,ATTR_ASCII_SELECTED
    cmp editMode,2
    jne render_ascii_store
    mov ah,ATTR_SELECTED
render_ascii_store:
    stosw
render_byte_done:
    ret
RenderByte endp

PlaceCursor proc
    cmp viewMode,2
    jne place_numeric_cursor
    mov dx,textCursorRow
    add dl,DATA_TOP
    mov dh,dl
    mov dl,byte ptr textCursorCol
    xor bh,bh
    mov ah,02h
    int 10h
    ret
place_numeric_cursor:
    mov eax,cursorOffset
    sub eax,viewOffset
    xor edx,edx
    div bytesPerRow
    add al,DATA_TOP
    mov dh,al
    mov al,dl
    cmp editMode,2
    je cursor_ascii
    mov bl,3
    cmp editMode,1
    jne cursor_stride
    mov bl,9
cursor_stride:
    mul bl
    add al,DATA_COLUMN
    add al,digitIndex
    jmp cursor_position
cursor_ascii:
    add al,61
    cmp viewMode,1
    jne cursor_position
    add al,5
cursor_position:
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
SaveErrorDialog proc
    mov ah,03h
    xor bh,bh
    int 10h
    push cx
    mov cx,2000h
    mov ah,01h
    int 10h
    call RenderSaveError
    xor ah,ah
    int 16h
    pop cx
    mov ah,01h
    int 10h
    ret
SaveErrorDialog endp

; Full error text, numeric DOS code and bounded two-row recovery paths.
RenderSaveError proc
    push es
    mov ax,0B800h
    mov es,ax
    mov di,ERROR_TOP*160 + ERROR_LEFT*2
    mov dx,ERROR_HEIGHT
save_error_clear_row:
    mov ax,ATTR_FOOTER*256 + ' '
    mov cx,ERROR_WIDTH
    rep stosw
    add di,(80-ERROR_WIDTH)*2
    dec dx
    jnz save_error_clear_row
    mov di,ERROR_TOP*160 + ERROR_LEFT*2
    mov ax,ATTR_SELECTED*256 + 218
    stosw
    mov al,196
    mov cx,ERROR_WIDTH-2
    rep stosw
    mov al,191
    stosw
    mov di,(ERROR_TOP+1)*160 + ERROR_LEFT*2
    mov cx,ERROR_HEIGHT-2
    mov al,179
save_error_sides:
    mov es:[di],ax
    mov es:[di+(ERROR_WIDTH-1)*2],ax
    add di,160
    loop save_error_sides
    mov al,192
    stosw
    mov al,196
    mov cx,ERROR_WIDTH-2
    rep stosw
    mov al,217
    stosw
    mov di,ERROR_TOP*160 + (ERROR_LEFT+3)*2
    mov si,offset saveErrorTitle
    call PutString
    mov di,6*160 + 3*2
    mov ah,ATTR_FOOTER
    mov si,statusText
    mov cx,74
    call PutLimitedString
    mov di,7*160 + 3*2
    mov si,offset saveErrorLabel
    call PutString
    movzx eax,lastError
    mov bl,ATTR_VALUE
    call PutHex32
    mov di,8*160 + 3*2
    mov ah,ATTR_FOOTER
    mov si,offset saveTargetLabel
    cmp backupExists,0
    je save_error_target_label
    mov si,offset saveBackupLabel
save_error_target_label:
    call PutString
    mov si,saveTarget
    test si,si
    jnz save_error_target_ready
    mov si,offset fileName
save_error_target_ready:
    cmp backupExists,0
    je save_error_target_path
    mov si,offset backupPath
save_error_target_path:
    mov di,9*160 + 3*2
    mov ah,ATTR_SELECTED
    call PutRecoveryPath
    cmp stageExists,0
    je save_error_return
    mov di,11*160 + 3*2
    mov ah,ATTR_FOOTER
    mov si,offset saveStageLabel
    call PutString
    mov di,12*160 + 3*2
    mov si,offset stagePath
    mov ah,ATTR_SELECTED
    call PutRecoveryPath
save_error_return:
    mov di,17*160 + 3*2
    mov ah,ATTR_FOOTER
    mov si,offset helpReturn
    call PutHelpLine
    pop es
    ret
RenderSaveError endp

PutRecoveryPath proc
    mov dx,2
recovery_path_row:
    mov cx,74
recovery_path_character:
    lodsb
    test al,al
    jz recovery_path_done
    stosw
    loop recovery_path_character
    add di,12
    dec dx
    jnz recovery_path_row
recovery_path_done:
    ret
PutRecoveryPath endp

HelpDialog proc
    ; Hide the editing cursor while the modal is visible; preserve its shape.
    mov ah,03h
    xor bh,bh
    int 10h
    push cx
    mov cx,2000h
    mov ah,01h
    int 10h
    call RenderHelpWindow
    xor ah,ah
    int 16h
    pop cx
    mov ah,01h
    int 10h
    ret                           ; Main redraws the editor after dismissal
HelpDialog endp

; Centred, opaque CP437 text window. Each helpLines entry occupies one row.
; Draw only inside the rectangle so the surrounding editor stays visible.
RenderHelpWindow proc
    push es
    mov ax,0B800h
    mov es,ax
    mov di,HELP_TOP * 160 + HELP_LEFT * 2
    mov dx,HELP_HEIGHT
help_clear_row:
    mov ax,ATTR_NORMAL * 256 + ' '
    mov cx,HELP_WIDTH
    rep stosw
    add di,(80 - HELP_WIDTH) * 2
    dec dx
    jnz help_clear_row

    mov di,HELP_TOP * 160 + HELP_LEFT * 2
    mov ax,ATTR_SELECTED * 256 + 218 ; upper-left corner
    stosw
    mov al,196                     ; horizontal rule
    mov cx,HELP_WIDTH - 2
    rep stosw
    mov al,191                     ; upper-right corner
    stosw
    mov di,(HELP_TOP + 1) * 160 + HELP_LEFT * 2
    mov cx,HELP_HEIGHT - 2
    mov al,179                     ; vertical sides
help_border_row:
    mov es:[di],ax
    mov es:[di + (HELP_WIDTH - 1) * 2],ax
    add di,160
    loop help_border_row
    mov al,192                     ; lower-left corner
    stosw
    mov al,196
    mov cx,HELP_WIDTH - 2
    rep stosw
    mov al,217                     ; lower-right corner
    stosw

    mov di,HELP_TOP * 160 + (HELP_LEFT + 3) * 2
    mov si,offset helpTitle
    call PutString
    mov bx,offset helpLines
    mov dx,(HELP_TOP + 2) * 160 + (HELP_LEFT + 2) * 2
help_line:
    mov si,[bx]
    or si,si
    jz help_return_prompt
    mov di,dx
    mov ah,ATTR_ASCII
    call PutHelpLine
    add bx,2
    add dx,160
    jmp help_line
help_return_prompt:
    mov di,(HELP_TOP + HELP_HEIGHT - 2) * 160 + (HELP_LEFT + 2) * 2
    mov ah,ATTR_TITLE
    mov si,offset helpReturn
    call PutHelpLine
    pop es
    ret
RenderHelpWindow endp

; Draw SI in AH, highlighting the key label before ':' in bright yellow.
; A sentence with no colon stays entirely in its description colour.
; Strings are fixed help text fitting within the modal's interior width.
PutHelpLine proc
    push si
    push di
    call PutString
    pop di
    pop si
    xor cx,cx
help_find_colon:
    lodsb
    or al,al
    jz help_key_done
    cmp al,':'
    je help_colour_key
    inc cx
    jmp help_find_colon
help_colour_key:
    jcxz help_key_done
    mov al,ATTR_HELP_KEY
help_key_character:
    mov es:[di+1],al
    add di,2
    loop help_key_character
help_key_done:
    ret
PutHelpLine endp

; Clear rows 23/24, print SI prompt. ES is preserved.
DialogPrompt proc
    push es
    mov ax,0B800h
    mov es,ax
    mov di,23 * 160
    mov ax,ATTR_FOOTER * 256 + ' '
    mov cx,160
    rep stosw
    mov di,23 * 160
    call PutString
    pop es
    ret
DialogPrompt endp

RenderGotoDialog proc
    mov si,offset gotoPrompt
    cmp gotoError,0
    je goto_prompt_ready
    mov si,gotoError
goto_prompt_ready:
    call DialogPrompt
    push es
    mov ax,0B800h
    mov es,ax
    mov di,24*160
    mov ah,ATTR_SELECTED
    mov si,offset gotoInput
    call PutString
    mov di,24*160 + 12*2
    mov ah,ATTR_STATUS
    mov si,offset gotoEOFText
    call PutString
    mov eax,fileSize
    mov bl,ATTR_VALUE
    call PutHex32
    mov di,24*160 + 30*2
    mov ah,ATTR_STATUS
    mov si,offset gotoCurrentText
    call PutString
    mov eax,cursorOffset
    call PutHex32
    pop es
    mov dx,1800h
    mov ax,gotoLength
    mov dl,al
    xor bh,bh
    mov ah,02h
    int 10h
    ret
RenderGotoDialog endp

GotoDialog proc
    call ResetGotoInput
goto_dialog_next:
    call RenderGotoDialog
    xor ah,ah
    int 16h
    call HandleGotoKey
    cmp gotoDone,0
    je goto_dialog_next
    ret                           ; Main restores the editor screen/cursor
GotoDialog endp

RenderSearchDialog proc
    mov si,offset searchPrompt
    cmp searchError,0
    je search_prompt_ready
    mov si,searchError
search_prompt_ready:
    call DialogPrompt
    push es
    mov ax,0B800h
    mov es,ax
    mov di,24*160
    mov si,offset searchInput
    mov bx,searchInputLength
    cmp bx,48
    jbe search_input_visible
    sub bx,48
    add si,bx
search_input_visible:
    mov cx,48
    mov ah,ATTR_SELECTED
    call PutLimitedString
    mov di,24*160 + 52*2
    mov si,offset searchModeLabel
    mov ah,ATTR_STATUS
    call PutString
    mov si,offset searchTextLabel
    cmp searchType,0
    je search_mode_label_ready
    mov si,offset searchHexLabel
search_mode_label_ready:
    mov ah,ATTR_MODE
    call PutString
    pop es
    mov ax,searchInputLength
    cmp ax,48
    jbe search_input_cursor
    mov ax,48
search_input_cursor:
    mov dx,1800h
    mov dl,al
    xor bh,bh
    mov ah,02h
    int 10h
    ret
RenderSearchDialog endp

SearchDialog proc
    call ResetSearchInput
search_dialog_next:
    call RenderSearchDialog
    xor ah,ah
    int 16h
    call HandleSearchKey
    cmp searchDone,0
    je search_dialog_next
    ret
SearchDialog endp

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
    mov ax,ATTR_FOOTER * 256 + ' '
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
    mov ah,ATTR_SELECTED
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
    jnc save_as_saved
    call SaveErrorDialog
    jmp save_as_done
save_as_saved:
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
    jnc quit_accept
    call SaveErrorDialog
    jmp quit_cancel
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
