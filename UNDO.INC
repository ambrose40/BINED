; Compact, key-transaction undo. Each existing editing command changes <=2 bytes.
; This include extends the production data/code segments; no heap/screen snapshots.
UNDO_LEVELS     equ 32
UNDO_RECORD_SIZE equ 32
H_OFFSET        equ 0
H_OLD_DATA      equ 4
H_NEW_DATA      equ 6
H_OLD_LEN       equ 8
H_NEW_LEN       equ 9
H_OLD_DIGIT     equ 10
H_NEW_DIGIT     equ 11
H_OLD_CURSOR    equ 12
H_NEW_CURSOR    equ 16
H_OLD_STATE     equ 20
H_NEW_STATE     equ 24
H_OLD_SIZE      equ 28

_TEXT ends
_DATA segment word public use16 'DATA'
historyRecords  db UNDO_LEVELS * UNDO_RECORD_SIZE dup (0)
historyPending  db UNDO_RECORD_SIZE dup (0)
historyCount    dw 0
historyPosition dw 0               ; [0,position) undo; [position,count) redo
historyCapture  db 0
historyReplaying db 0
historyState    dd 0
historyNextState dd 1
historySavedState dd 0
historySavedValid db 1
historyDirection db 0              ; 0 undo, 1 redo
historyRemove   db 0
historyInsert   db 0
historyBytes    dw 0
_DATA ends
_TEXT segment word public use16 'CODE'

; Preserve general registers. Direct buffer/fixture writes start a new baseline.
ResetUndoHistory proc
    push ax
    mov historyCount,0
    mov historyPosition,0
    mov historyCapture,0
    mov historyReplaying,0
    mov historyState,0
    mov historyNextState,1
    mov historySavedState,0
    mov historySavedValid,1
    cmp dirty,0
    je history_reset_done
    mov historySavedValid,0
history_reset_done:
    pop ax
    ret
ResetUndoHistory endp

HistoryExternalWrite proc
    cmp historyCapture,0
    jne history_external_done
    cmp historyReplaying,0
    jne history_external_done
    call ResetUndoHistory
history_external_done:
    ret
HistoryExternalWrite endp

HistoryMarkSaved proc
    push eax
    mov eax,historyState
    mov historySavedState,eax
    mov historySavedValid,1
    mov dirty,0
    pop eax
    ret
HistoryMarkSaved endp

HistoryUpdateDirty proc
    push eax
    mov dirty,1
    cmp historySavedValid,0
    je history_dirty_done
    mov eax,historyState
    cmp eax,historySavedState
    jne history_dirty_done
    mov dirty,0
history_dirty_done:
    pop eax
    ret
HistoryUpdateDirty endp

; EAX offset -> DX up to two existing bytes, zero padded. Preserve other regs.
ReadHistoryWord proc
    push eax
    push esi
    mov esi,eax
    xor dx,dx
    cmp esi,fileSize
    jae history_word_done
    call ReadByte
    mov dl,al
    inc esi
    cmp esi,fileSize
    jae history_word_done
    mov eax,esi
    call ReadByte
    mov dh,al
history_word_done:
    pop esi
    pop eax
    ret
ReadHistoryWord endp

; AX BIOS key. Snapshot only editing commands; dialogs/navigation are not edits.
BeginHistoryChange proc
    pushad
    mov historyCapture,0
    cmp al,0
    je history_begin_extended
    cmp al,0E0h
    je history_begin_extended
    cmp al,20h
    jb history_begin_control
    cmp al,7Eh
    jbe history_begin_cursor
    jmp history_begin_done
history_begin_control:
    cmp viewMode,2
    jne history_begin_done
    cmp al,8
    je history_begin_backspace
    cmp al,9
    je history_begin_cursor
    cmp al,13
    je history_begin_cursor
    jmp history_begin_done
history_begin_extended:
    cmp ah,52h
    je history_begin_cursor
    cmp ah,53h
    je history_begin_cursor
    jmp history_begin_done
history_begin_backspace:
    mov esi,cursorOffset
    test esi,esi
    jz history_begin_done
    dec esi
    mov eax,esi
    call ReadByte
    cmp al,10
    jne history_begin_offset
    test esi,esi
    jz history_begin_offset
    lea eax,[esi-1]
    call ReadByte
    cmp al,13
    jne history_begin_offset
    dec esi
    jmp history_begin_offset
history_begin_cursor:
    mov esi,cursorOffset
history_begin_offset:
    cmp historyCount,0
    jne history_begin_snapshot
    call ResetUndoHistory          ; synchronize a new baseline's clean/dirty flag
history_begin_snapshot:
    mov historyCapture,1
    mov dword ptr historyPending+H_OFFSET,esi
    mov eax,fileSize
    mov dword ptr historyPending+H_OLD_SIZE,eax
    mov eax,cursorOffset
    mov dword ptr historyPending+H_OLD_CURSOR,eax
    mov al,digitIndex
    mov byte ptr historyPending+H_OLD_DIGIT,al
    mov eax,historyState
    mov dword ptr historyPending+H_OLD_STATE,eax
    mov eax,esi
    call ReadHistoryWord
    mov word ptr historyPending+H_OLD_DATA,dx
history_begin_done:
    popad
    ret
BeginHistoryChange endp

; DS:SI -> DS:DI fixed-size record. Preserve ES; preserve the caller's DF contract.
CopyHistoryRecord proc
    push es
    push ds
    pop es
    mov cx,UNDO_RECORD_SIZE/2
    rep movsw
    pop es
    ret
CopyHistoryRecord endp

EndHistoryChange proc
    cmp historyCapture,0
    je history_end_done
    pushad
    mov historyCapture,0
    mov eax,dword ptr historyPending+H_OFFSET
    call ReadHistoryWord
    mov word ptr historyPending+H_NEW_DATA,dx
    mov byte ptr historyPending+H_OLD_LEN,0
    mov byte ptr historyPending+H_NEW_LEN,0
    mov eax,dword ptr historyPending+H_OLD_SIZE
    cmp eax,fileSize
    jb history_end_insert
    ja history_end_delete
    xor dx,word ptr historyPending+H_OLD_DATA
    test dx,dx
    jz history_end_restore          ; invalid/identical/no-op input preserves redo
    mov al,1
    test dh,dh
    jz history_end_replace
    mov al,2
history_end_replace:
    mov byte ptr historyPending+H_OLD_LEN,al
    mov byte ptr historyPending+H_NEW_LEN,al
    jmp history_end_record
history_end_insert:
    mov ecx,fileSize
    sub ecx,eax
    cmp ecx,2
    ja history_end_unsupported
    mov byte ptr historyPending+H_NEW_LEN,cl
    jmp history_end_record
history_end_delete:
    sub eax,fileSize
    cmp eax,2
    ja history_end_unsupported
    mov byte ptr historyPending+H_OLD_LEN,al
history_end_record:
    mov eax,cursorOffset
    mov dword ptr historyPending+H_NEW_CURSOR,eax
    mov al,digitIndex
    mov byte ptr historyPending+H_NEW_DIGIT,al
    mov eax,historyNextState
    inc historyNextState
    mov dword ptr historyPending+H_NEW_STATE,eax
    mov historyState,eax
    mov ax,historyPosition
    mov historyCount,ax             ; a real new edit discards the redo branch
    cmp ax,UNDO_LEVELS
    jb history_end_append
    push es
    push ds
    pop es
    mov si,offset historyRecords+UNDO_RECORD_SIZE
    mov di,offset historyRecords
    mov cx,(UNDO_LEVELS-1)*UNDO_RECORD_SIZE/2
    rep movsw                      ; bounded 992-byte oldest-record eviction
    pop es
    dec historyCount
    dec historyPosition
history_end_append:
    mov di,historyCount
    shl di,5
    add di,offset historyRecords
    mov si,offset historyPending
    call CopyHistoryRecord
    inc historyCount
    inc historyPosition
    call HistoryUpdateDirty
    jmp history_end_restore
history_end_unsupported:
    mov dirty,1                    ; future larger commands require larger deltas
    call ResetUndoHistory
history_end_restore:
    popad
history_end_done:
    ret
EndHistoryChange endp

; SI record -> apply inverse/forward delta. Validate everything before mutation.
ReplayHistory proc
    mov di,offset historyPending
    call CopyHistoryRecord
    mov edx,dword ptr historyPending+H_OLD_SIZE
    cmp historyDirection,0
    jne history_replay_redo
    movzx ecx,byte ptr historyPending+H_OLD_LEN
    sub edx,ecx
    movzx ecx,byte ptr historyPending+H_NEW_LEN
    add edx,ecx
    mov al,byte ptr historyPending+H_NEW_LEN
    mov historyRemove,al
    mov al,byte ptr historyPending+H_OLD_LEN
    mov historyInsert,al
    mov ax,word ptr historyPending+H_OLD_DATA
    mov historyBytes,ax
    jmp history_replay_validate
history_replay_redo:
    mov al,byte ptr historyPending+H_OLD_LEN
    mov historyRemove,al
    mov al,byte ptr historyPending+H_NEW_LEN
    mov historyInsert,al
    mov ax,word ptr historyPending+H_NEW_DATA
    mov historyBytes,ax
history_replay_validate:
    cmp edx,fileSize
    jne history_replay_mismatch
    mov eax,dword ptr historyPending+H_OFFSET
    movzx ecx,historyRemove
    add eax,ecx
    cmp eax,fileSize
    ja history_replay_mismatch
    mov eax,fileSize
    sub eax,ecx
    movzx ecx,historyInsert
    add eax,ecx
    cmp eax,bufferCapacity
    ja history_replay_full
    mov historyReplaying,1
    mov eax,dword ptr historyPending+H_OFFSET
    mov cursorOffset,eax
    mov al,historyRemove
    cmp al,historyInsert
    jne history_replay_shift
    movzx cx,historyInsert         ; byte/bit overwrites replay in place, not O(fileSize)
history_replay_replace:
    jcxz history_replay_cursor
    mov dx,historyBytes
    mov eax,cursorOffset
    call WriteByte
    shr historyBytes,8
    inc cursorOffset
    loop history_replay_replace
    jmp history_replay_cursor
history_replay_shift:
    movzx cx,historyRemove
history_replay_delete:
    jcxz history_replay_insert_start
    push cx
    call DeleteByte
    pop cx
    loop history_replay_delete
history_replay_insert_start:
    movzx cx,historyInsert
history_replay_insert:
    jcxz history_replay_cursor
    push cx
    call InsertByte
    pop cx
    mov dx,historyBytes
    mov eax,cursorOffset
    call WriteByte
    shr historyBytes,8
    inc cursorOffset
    loop history_replay_insert
history_replay_cursor:
    mov eax,dword ptr historyPending+H_OLD_CURSOR
    mov dl,byte ptr historyPending+H_OLD_DIGIT
    mov ebx,dword ptr historyPending+H_OLD_STATE
    cmp historyDirection,0
    je history_replay_position
    mov eax,dword ptr historyPending+H_NEW_CURSOR
    mov dl,byte ptr historyPending+H_NEW_DIGIT
    mov ebx,dword ptr historyPending+H_NEW_STATE
history_replay_position:
    mov historyState,ebx
    call SetCursor
    mov digitIndex,0
    cmp dl,digitsPerByte
    jae history_replay_visible
    mov eax,cursorOffset
    cmp eax,fileSize
    jae history_replay_visible
    mov digitIndex,dl
history_replay_visible:
    mov historyReplaying,0
    mov textGoalValid,0
    mov textLastValid,0
    call EnsureVisible
    call HistoryUpdateDirty
    clc
    ret
history_replay_mismatch:
    mov statusText,offset msgUndoMismatch
    stc
    ret
history_replay_full:
    mov statusText,offset msgUndoBounds
    stc
    ret
ReplayHistory endp

UndoChange proc
    cmp historyPosition,0
    je history_undo_empty
    mov si,historyPosition
    dec si
    shl si,5
    add si,offset historyRecords
    mov historyDirection,0
    call ReplayHistory
    jc history_undo_done
    dec historyPosition
    mov statusText,offset msgUndone
history_undo_done:
    ret
history_undo_empty:
    mov statusText,offset msgNoUndo
    stc
    ret
UndoChange endp

RedoChange proc
    mov ax,historyPosition
    cmp ax,historyCount
    jae history_redo_empty
    mov si,ax
    shl si,5
    add si,offset historyRecords
    mov historyDirection,1
    call ReplayHistory
    jc history_redo_done
    inc historyPosition
    mov statusText,offset msgRedone
history_redo_done:
    ret
history_redo_empty:
    mov statusText,offset msgNoRedo
    stc
    ret
RedoChange endp
