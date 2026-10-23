.286
.model tiny
assume cs:progg

progg segment
org 100h

;----------------------------------------------------------------------------
startup proc
;At first set video resolution and page
 call set_video
;Then set default memmory variables necessary for work
 call set_defaults
;Then draw visible border (user-interface)
 call draw_border
;Then draw second part of visible border (user-interface), and go on
 mov dx,0000h
 call draw_border_bok
 mov dx,004Fh
 call draw_border_bok
;After call reading of command line parameters
 call get_commandline
;Call filepath printing to screen
 call write_path
 call restore_coordinates
 mov byte ptr hexbin,00h
;Set the starting cursor coordinates 
 call set_coordinates
;At the end switch to binary mode which is default at startup
 call mode_bin
 call read_keyboard
 ret
startup endp

;----------------------------------------------------------------------------
add_byte proc
 pusha
 mov cx,handler11
 add cx,0001h
 mov handler11,cx
 mov dx,handler14
 mov bx,handler9
 sub dx,0001h
 add bx,dx
 mov al,00h
again_insert:
 mov ah,al
 mov al,[ds:bx]
 mov [ds:bx],ah
 add bx,0001h
 cmp bx,cx
 jz end_insert
 jmp again_insert
end_insert:
 popa
 ret
add_byte endp

;----------------------------------------------------------------------------
sub_byte proc
 pusha
 mov cx,handler11
 sub cx,0001h
 mov handler11,cx
 mov dx,handler14
 mov bx,handler9
 sub dx,0001h
 add bx,dx
 cmp bx,cx
 jbe again_delete
 add cx,0001h
 mov handler11,cx
 jmp end_delete
again_delete:
 add bx,0001h
 mov al, byte ptr [bx]
 sub bx,0001h
 mov [ds:bx],al
 add bx,0001h
 cmp bx,cx
 jae end_delete
 jmp again_delete
end_delete:
 popa
 ret
sub_byte endp

;----------------------------------------------------------------------------
set_coordinates proc
 pusha
 mov byte ptr coord2,01h
 mov byte ptr coord1,01h
 mov dx,0102h
 mov [ds:memmory],dx
 mov ah,02h
 mov bh,02h
 int 10h
 popa
 ret
set_coordinates endp

;----------------------------------------------------------------------------
restore_coordinates proc
 pusha
 mov dx,[ds:memmory]
 mov ah,02h
 mov bh,02h
 int 10h
 popa
 ret
restore_coordinates endp

;----------------------------------------------------------------------------
set_video proc
 pusha
 mov ax,0003h
 int 10h
 mov ax,0502h
 int 10h
 popa
 ret
set_video endp

;----------------------------------------------------------------------------
set_defaults proc
 pusha
 mov byte ptr mode,00h
 mov byte ptr handler2,00h
 mov word ptr handler3,0000h
 mov byte ptr handler4,00h
 mov word ptr handler5,0102h
 mov byte ptr handler6,00h
 mov byte ptr handler7,00000000b
 mov byte ptr handler8,00h
 mov word ptr handler9,0000h
 mov word ptr handler10,0000h
 mov word ptr handler11,0000h
 mov word ptr handler12,173Ah
 mov word ptr handler13,0000h
 mov word ptr handler14,0102h
 popa
 ret
set_defaults endp

;----------------------------------------------------------------------------
cls proc
 pusha
;Clear screen but leave surrouning borders
 mov ah,06h
 mov al,16h
 mov bh,02h
 mov cx,coords
 lea dx,cls1
 int 10h
 popa
 ret
cls endp

;----------------------------------------------------------------------------
clear_memory proc
 pusha
;Call clear sreen procedure first
 call cls
;Then call set defaults procedure to erase all memmory links
 call set_defaults
;Return handle to keyboard reading
 call read_keyboard
 popa
 ret
clear_memory endp

;----------------------------------------------------------------------------
insert proc
 pusha
 mov bx,handler9
 mov handler10,bx
 mov bh,byte ptr hexbin
 cmp bh,00h
 jnz finish_insert_bin
 mov byte ptr mode,0F1h
 call read_binchar
 call return_to_insert_bin
finish_insert_bin:
 cmp bh,01h
 jnz finish_insert_hex
 mov byte ptr mode,0F1h
 call read_hexchar
 call read_hexchar_sub
 call read_hexchar_sub_handler
 call return_to_insert_hex
finish_insert_hex:
 call restore_coordinates
 popa
 ret
insert endp

return_to_insert_bin proc
 pusha
 mov dx,[ds:memmory]
 mov ch,byte ptr coord1
 sub ch,01h
 sub dl,ch
 add dl,07h
 mov ch,dh
 sub ch,01h
 mov dh,00h
 mov ax,dx
 mov dh,09h
 div byte ptr dh
 mov dl,al
 mov al,ch
 mov dh,08h
 mul byte ptr dh
 mov dh,00h
 add dx,ax
 mov handler14,dx
 call add_byte
 call write_binchar
 popa
 ret
return_to_insert_bin endp

;----------------------------------------------------------------------------
return_to_insert_hex proc
 pusha
 mov dx,[ds:memmory]
 mov ch,byte ptr coord1
 sub ch,01h
 sub dl,ch
 add dl,01h
 mov ch,dh
 sub ch,01h
 mov dh,00h
 mov ax,dx
 mov dh,03h
 div byte ptr dh
 mov dl,al
 mov al,ch
 mov dh,18h
 mul byte ptr dh
 mov dh,00h
 add dx,ax
 mov handler14,dx
 call add_byte
 call write_hexchar
 popa
 ret
return_to_insert_hex endp

;----------------------------------------------------------------------------
delete proc
 pusha
 mov bx,handler9
 mov handler10,bx
 mov bh,byte ptr hexbin
 cmp bh,00h
 jnz finish_delete_bin
 mov byte ptr mode,0E0h
 call read_binchar
 call return_to_delete_bin
finish_delete_bin:
 cmp bh,01h
 jnz finish_delete_hex
 mov byte ptr mode,0E0h
 call read_hexchar
 call read_hexchar_sub
 call read_hexchar_sub_handler
 call return_to_delete_hex
finish_delete_hex:
 popa
 ret
delete endp

return_to_delete_bin proc
 pusha
 mov dx,[ds:memmory]
 mov ch,byte ptr coord1
 sub ch,01h
 sub dl,ch
 add dl,07h
 mov ch,dh
 sub ch,01h
 mov dh,00h
 mov ax,dx
 mov dh,09h
 div byte ptr dh
 mov dl,al
 mov al,ch
 mov dh,08h
 mul byte ptr dh
 mov dh,00h
 add dx,ax
 mov handler14,dx
 call sub_byte
 call write_binchar
 popa 
 ret
return_to_delete_bin endp

return_to_delete_hex proc
 pusha
 mov dx,[ds:memmory]
 mov ch,byte ptr coord1
 sub ch,01h
 sub dl,ch
 add dl,01h
 mov ch,dh
 sub ch,01h
 mov dh,00h
 mov ax,dx
 mov dh,03h
 div byte ptr dh
 mov dl,al
 mov al,ch
 mov dh,18h
 mul byte ptr dh
 mov dh,00h
 add dx,ax
 mov handler14,dx
 call sub_byte
 call write_hexchar
 popa
 ret
return_to_delete_hex endp

;----------------------------------------------------------------------------
get_commandline proc
 pusha
;Terminate filepath entered from command line with null
 mov cx,0000h
 mov cl,byte ptr [ds:0080h]
 mov bx,0081h
 add bx,cx
 mov byte ptr [bx],00h
 call copy_filepath
 popa
 ret
get_commandline endp

;----------------------------------------------------------------------------
copy_filepath proc
 pusha
;Copy filepath to another memmory address
 mov ax,0000h
 mov dl,byte ptr [ds:0080h]
 mov byte ptr [ds:buffer+01h], dl
;Copy cycle
filepath_next_char:
 mov bx,0082h
 add bx,ax
 mov byte ptr dl,[bx]
 push si
 lea si,memmory
 add bx,si
 pop si
 mov [bx],dl
 add ax,0001h
 cmp ax,cx
 jna filepath_next_char
;End of copy cycle
 add bx,ax
 mov byte ptr dl,[bx]
 push si
 lea si,memmory
 add bx,si
 pop si
 mov [bx],dl
 popa
 ret
copy_filepath endp

;----------------------------------------------------------------------------
print_string proc
 pusha
;calculate address
 mov ax,80h
 mul dh
 mov cx,0000h
 mov cl,dl
 add ax,cx
;address in AX=160*y+2*x
 shl ax,1
 mov di,ax
 add di,adr_di
;save ES
 push es
;segment of screen memory in text mode
 mov ax,
 mov es,ax
print:
;load AL from DS:[SI]
 mov al,byte ptr [ds:si]
 cmp al,00h
;if AL == 0
 jz ready
;symbol for display
 mov es:[di],al
 add si,01h
 add di,1
 mov es:[di],bl
 add di,1
 jmp print
ready: 
;restore ES
 pop es
 popa
 ret
print_string endp

;----------------------------------------------------------------------------
write_path proc
 pusha
;Print entered filepath to screen
 mov dh,18h
 mov dl,02h
 lea si,buffer+02h
 mov cx,0000h
 mov cl,byte ptr [ds:buffer+01h]
 lea bx,buffer+02h
 add bx,cx
 mov byte ptr [bx],00h
 mov bl,color
 call print_string
 popa
 ret
write_path endp

;----------------------------------------------------------------------------
draw_border proc
 pusha
;Draw footer
 mov bl,color
 mov dh,17h
 mov dl,0h
 lea si,dwn
 call print_string
 mov dh,00h
 mov dl,00h
 lea si,upp
 call print_string
 popa
ret
draw_border endp

;----------------------------------------------------------------------------
draw_border_bok proc
 pusha
draw_border_bok_begin:
;Draw piece of border
 add dh,01h
 mov bl,0Ah
 lea si,bok
 call print_char
;Cycle of border render
 cmp dh,16h
 jb draw_border_bok_begin
;Check whether other side is rendered, if not then call render of second side
 popa
 ret
draw_border_bok endp

;----------------------------------------------------------------------------
mode_bin proc
 pusha
;Print out BIN word to show user the binary mode is switched on
 mov dh,17h
 mov dl,09h
 mov bl,color
 lea si,modabin
 call print_string
;Check which mode does user has switched from 
 mov bh,byte ptr hexbin
 cmp bh,01h
 jz skip_switch_hextobin
 call switch_hextobin
skip_switch_hextobin:
 popa
 ret
mode_bin endp

;----------------------------------------------------------------------------
mode_hex proc
 pusha
;Print out HEX word to show user the hexadecimal mode is switched on
 mov dh,17h
 mov dl,09h
 mov bl,color
 lea si,modahex
 call print_string
;Check which mode does user has switched from 
 mov bh,byte ptr hexbin
 cmp bh,00h
 jz skip_switch_bintohex
 call switch_bintohex
skip_switch_bintohex:
 popa
 ret
mode_hex endp

;----------------------------------------------------------------------------
switch_bintohex proc
 pusha
;Return handle to keyboard reading and set variable to 1-hex
 mov byte ptr hexbin,01h
;Set variable to F6 meaning that mode switching operation is at handle
 mov byte ptr mode,0F6h
 mov bx,handler9
 mov handler10,bx
;Call binary characters reading procedure
 call read_binchar
 popa
 ret
switch_bintohex endp

;----------------------------------------------------------------------------
switch_hextobin proc
 pusha
;Return handle to keyboard reading and set variable to 0-bin
 mov byte ptr hexbin,00h
;Set variable to F6 meaning that mode switching operation is at handle
 mov byte ptr mode,0F6h
 mov bx,handler9
 mov handler10,bx
;Call binary characters reading procedure
 call read_hexchar
 call read_hexchar_sub
 call read_hexchar_sub_handler
 popa
 ret
switch_hextobin endp

;----------------------------------------------------------------------------
write_char proc
 pusha
 mov dx,handler12
 mov bl,color
 lea si,handler13
 call print_char
 add dl,01h
 cmp dl,4Ah
 jb end_write_char
 push dx
 mov dx,pos1
 mov bh,byte ptr hexbin
 cmp bh,00h
 jnz write_char_hex
 add dx,0008h
write_char_hex:
 mov bh,byte ptr hexbin
 cmp bh,01h
 jnz write_char_bin
 add dx,0018h
write_char_bin:
 push dx
 mov dx,handler12
 add dl,02h
 mov pos1,dx
 pop dx
 call write_hex_rownumber
 mov pos1,dx
 pop dx
 mov dl,02h
 add dh,01h
 cmp dh,17h
 jnz end_write_char
 call hex_end
end_write_char:
 mov handler12,dx
 popa
 ret
write_char endp

;----------------------------------------------------------------------------
print_char proc
 pusha
;Calculate address
 mov ax,80h
 mul dh
 mov cx,0000h
 mov cl,dl
 add ax,cx
;Address in AX=160*y+2*x
 shl ax,1
 mov di,ax
 add di,adr_di
;save ES
 push es
;segment of screen memmory in text mode
 mov ax,memseg
 mov es,ax
 mov al, [ds:si]
 mov es:[di],al
 add di,1
 mov es:[di],bl
 add di,1
 pop es
 popa
ret
print_char endp

;----------------------------------------------------------------------------
write_char_number proc
 pusha
;Setting position for printing
 mov dx,pos1
;Printing character for row number
 mov bl,color
 lea si,handler13
;Adding 1 for the next position of char
 call print_char
 add dl,01h
 mov pos1,dx
 popa
 ret
write_char_number endp

;----------------------------------------------------------------------------
write_hexchar proc
;Clearing the stack
; mov sp,00h
;Clearing screen for writing of new information
 pusha
 call cls
;Preparations necessary for rendering only visible part of memmory to screen
 mov ax,handler11
 mov dx,handler9
 sub dx,0000h
 mov pos1,dx
 mov word ptr handler12,0102h
 sub ax,handler9
;Check for completition of cycle
 cmp ax,00h
 jnz hex_continue
 call hex_end
 hex_continue:
 mov word ptr cx,0000h
 mov dx,0000h
 next_byte_hex:
 mov word ptr bx,handler9
 push bx
;Reading byte from memmory
 add bx,cx
 push ds
 push si
 mov si,9000h
 mov ds,si
 mov byte ptr dl,[bx]
 pop si
 pop ds
 mov byte ptr handler4,dl
 pop bx
;Calling procedure for writing of hexadecimal bytes
 call write_hextoscreen
;Printing a point to separate bytes
 mov byte ptr handler13,2Eh
 call write_char
;Check for completition of cycle, if not goto next
 add word ptr cx,0001h
 cmp cx,ax
 jae end_hexchar
 jmp next_byte_hex
;Exit from cycle
end_hexchar:
 call hex_end
 popa
 ret
write_hexchar endp

;----------------------------------------------------------------------------
write_binchar proc
 pusha
;Clearing the stack
; mov sp,00h
;Clearing the screen
 call cls
 mov ax,handler11
 push dx
 mov dx,handler9
 mov pos1,dx
 pop dx
 mov word ptr handler12,0102h
 sub ax,handler9
 cmp ax,0000h
 jnz bin_continue
 call bin_end
bin_continue:
 mov word ptr cx,0000h
 mov dx,0000h
next_byte_bin:
 mov word ptr bx,handler9
 add bx,cx
 push ds
 push si
 mov si,9000h
 mov ds,si
 mov byte ptr dl,[bx]
 pop si
 pop ds
 mov byte ptr handler4,dl
 call write_bintoscreen
 mov byte ptr handler13,2Eh
 call write_char
 add word ptr cx,0001h
 cmp cx,ax
 jae end_binchar
 call next_byte_bin
end_binchar:
 call bin_end
 popa
 ret
write_binchar endp

;----------------------------------------------------------------------------
hex_end proc
 pusha
;Byte writing end scope
 mov byte ptr handler8,00h
;Check whether to restore or truncate cursor coordinates
 mov ch,byte ptr mode
 cmp ch,0F5h
 jb to_position_correction_hex
 call set_coordinates
to_position_correction_hex:
 call restore_coordinates
 call read_keyboard
 popa
 ret
hex_end endp

;----------------------------------------------------------------------------
bin_end proc
 pusha
;Byte writing end scope
 mov byte ptr handler8,00h
;Check whether to restore or truncate cursor coordinates
 mov ch,byte ptr mode
 cmp ch,0F5h
 jb to_position_correction_hex
 call set_coordinates
to_position_correction_hex:
 call restore_coordinates
 call read_keyboard
 popa
 ret
bin_end endp

;----------------------------------------------------------------------------
write_bintoscreen proc
 pusha
next_bin_to_screen:
 mov dl,byte ptr handler4
 mov dh,byte ptr handler4
 and dl,10000000b
 shl dh,1h
 mov byte ptr handler4,dh
 cmp dl,80h
 jnz gogo1
 push dx
 mov byte ptr handler13,31h
 call write_char
 pop dx
gogo1:
 cmp dl,00h
 jnz gogo2
 push dx
 mov byte ptr handler13,30h
 call write_char
 pop dx
gogo2:
 mov cx,handler3
 add cx,0001h
 mov handler3,cx
 cmp cx,0008h
 jb next_bin_to_screen
 mov word ptr handler3,0000h
 popa
 ret
write_bintoscreen endp

;----------------------------------------------------------------------------
write_hextoscreen proc
 pusha
 mov dh,byte ptr handler4
 mov dl,dh
 mov cl,4
 shr dl,cl
 call write_hexdigit
 mov dl,dh
 and dl,0Fh
 call write_hexdigit
 popa
 ret
write_hextoscreen endp

;----------------------------------------------------------------------------
write_hexdigit proc
 pusha
 cmp dl,0Ah    
 jae hex_letter
 add dl,30h
 jmp hex_digit
hex_letter:
 add dl,37h
hex_digit:
 mov byte ptr handler13,dl
 call write_char
 popa
 ret
write_hexdigit endp

;----------------------------------------------------------------------------
write_hex_rowdigit proc
 pusha
 cmp dl,0Ah    
 jae hex_row_letter
 add dl,30h
 jmp hex_row_digit
hex_row_letter:
 add dl,37h
hex_row_digit:
 mov byte ptr handler13,dl
 call write_char_number
 popa
 ret
write_hex_rowdigit endp

;----------------------------------------------------------------------------
write_hex_rownumber proc
 pusha
 mov dl,dh        
 mov cl,4
 shr dl,cl
 call write_hex_rowdigit
 mov dl,dh
 and dl,0Fh
 call write_hex_rowdigit
 popa
 pusha
 mov dh,dl        
 mov cl,4
 shr dl,cl
 call write_hex_rowdigit
 mov dl,dh
 and dl,0Fh
 call write_hex_rowdigit
 popa
 ret
write_hex_rownumber endp

;----------------------------------------------------------------------------
write_hex_position proc
 pusha
 mov bx,hexpos1
 mov handler12,bx
 mov dl,dh        
 mov cl,4
 shr dl,cl
 call write_hexdigit
 mov dl,dh
 and dl,0Fh
 call write_hexdigit
 popa
 pusha
 mov dh,dl
 mov cl,4
 shr dl,cl
 mov bx,hexpos2
 mov handler12,bx
 call write_hexdigit
 mov dl,dh
 and dl,0Fh
 call write_hexdigit
 popa
 ret
write_hex_position endp

;----------------------------------------------------------------------------
press_down proc
 pusha
 mov dx,[ds:memmory]
 add dh,01h
 call write_hex_position
 cmp dh,16h
 jb skip_mov_16h
 mov dh,16h
 call write_hex_position
skip_mov_16h:
 mov ah,02h
 mov bh,02h
 int 10h
 mov [ds:memmory],dx
 mov ah,08h
 mov bh,02h
 int 10h
 cmp al,20h
 ja not_space_char
 mov dx,[ds:memmory]
 sub dh,01h
 call write_hex_position
 cmp dh,01h
 ja movhu2
 mov dh,01h
 call write_hex_position
movhu2:
 mov ah,02h
 mov bh,02h
 int 10h
not_space_char:
 mov [ds:memmory],dx
 popa
 ret
press_down endp

;----------------------------------------------------------------------------
press_right proc
push ax
push dx
push bx
mov dx,[ds:memmory]
add dl,01h
call write_hex_position
cmp dl,4Ah
jb movdh
add dh,01h
cmp dh,16h
jb movhy
mov dh,16h
call write_hex_position
movhy:
mov dl,01h
call write_hex_position
movdh:
mov ah,02h
mov bh,02h
int 10h
mov [ds:memmory],dx
mov ah,08h
mov bh,02h
int 10h
cmp al,20h
ja gogogog
mov dx,[ds:memmory]
sub dl,01h
cmp dl,00h
ja movh
sub dh,01h
cmp dh,01h
ja movhe
mov dh,01h
movhe:
mov dl,4Ah
movh:
call write_hex_position
mov ah,02h
mov bh,02h
int 10h
mov [ds:memmory],dx
jmp achto6
gogogog:
mov bh,byte ptr hexbin
cmp bh,00h
jnz achto5
mov ch,byte ptr coord1
add ch,01h
mov byte ptr coord1,ch
cmp ch,09h
jnz achto5
mov byte ptr coord1,00h
mov byte ptr char,2Eh
call record_char
achto5:
cmp bh,01h
jnz achto6
mov ch,byte ptr coord2
add ch,01h
mov byte ptr coord2,ch
cmp ch,03h
jnz achto6
mov byte ptr coord2,00h
mov byte ptr char,2Eh
call  record_char
ACHTO6:
pop bx
pop dx
pop ax
call read_keyboard
ret
press_right endp

;----------------------------------------------------------------------------
read_charbuffer proc
 ;calculate address
 mov AX,80     
 mul dh
 mov cx,0000h
 mov cl,dl
 add AX,cx
 ;address in AX=160*y+2*x
 shl AX,1
 mov DI,AX
 add di,adr_di
 ;save ES
 push ES
 ;segment of screen memmory in text mode
 mov AX,memseg
 mov ES,AX
 mov al,ES:[DI]
 add DI,1
 mov ah,ES:[DI]
 add DI,1
 pop ES
ret
read_charbuffer endp

;----------------------------------------------------------------------------
press_left proc
push ax
push dx
push bx
mov dx,[ds:memmory]
mov bh,byte ptr hexbin
cmp bh,00h
jnz sledu
mov ch,byte ptr coord1
cmp ch,01h
jnz gotnext2
cmp dl,0Ah
jb sledu
sub dl,09h
mov byte ptr sympos,09h
sledu:
mov bh,byte ptr hexbin
cmp bh,01h
jnz sledu2
mov ch,byte ptr coord2
cmp ch,01h
jnz gotnext2
cmp dl,05h
jb sledu2
sub dl,03h
mov byte ptr sympos,03h
sledu2:
jmp gatta2
gotnext2:
sub dl,01h
mov byte ptr sympos,01h
gatta2:
call write_hex_position
mov ah,02h
mov bh,02h
int 10h

call read_charbuffer
mov [ds:memmory],dx
cmp al,20h
ja gogogo
mov dx,[ds:memmory]
mov bh,byte ptr sympos
add dl,bh
call write_hex_position
cmp dl,4fh
jb movdh2
cmp dh,01h
jz oint
add dh,01h
oint:
cmp dh,16h
jb movhy2
mov dh,16h
call write_hex_position
movhy2:
mov dl,01h
call write_hex_position
movdh2:
mov ah,02h
mov bh,02h
int 10h
mov [ds:memmory],dx
jmp achto4
gogogo:
mov bh,byte ptr hexbin
cmp bh,00h
jnz achto3
mov ch,byte ptr coord1
cmp ch,01h
jnz gotnext
mov ch,01h
jmp gatta
gotnext:
sub ch,01h
gatta:
mov byte ptr coord1,ch
cmp ch,09h
jnz achto3
mov byte ptr coord1,00h
mov byte ptr char,2Eh
call  record_char
achto3:
mov bh,byte ptr hexbin
cmp bh,01h
jnz achto4
mov ch,byte ptr coord2
cmp ch,01h
jnz gotnext3
mov ch,01h
jmp gatta3
gotnext3:
sub ch,01h
gatta3:
mov byte ptr coord2,ch
cmp ch,03h
jnz achto4
mov byte ptr coord2,00h
mov byte ptr char,2Eh
call  record_char
ACHTO4:
pop bx
pop dx
pop ax
call read_keyboard
ret
press_left endp

;----------------------------------------------------------------------------
press_up proc
push ax
push dx
push bx
mov dx,[ds:memmory]
sub dh,01h
call write_hex_position
cmp dh,01h
ja movhu
mov dh,01h
call write_hex_position
movhu:
mov ah,02h
mov bh,02h
int 10h
mov [ds:memmory],dx
call read_charbuffer
cmp al,20h
ja gogogoga
bacxk:
mov dx,[ds:memmory]
cmp dh,01h
jz qiit
add dh,01h
call write_hex_position
cmp dh,16h
jb movhi2
mov dh,16h
call write_hex_position
movhi2:
mov ah,02h
mov bh,02h
int 10h
mov [ds:memmory],dx
jmp qiit
gogogoga:
cmp al,0A0h
ja bacxk
qiit:
pop bx
pop dx
pop ax
call read_keyboard
ret
press_up endp

;----------------------------------------------------------------------------
mode_choice proc
 pusha
 mov byte ptr mode,0F2h
 mov bh,byte ptr hexbin
 cmp bh,00h
 jne check_hex
 mov bx,handler9
 mov handler10,bx
 call read_binchar
check_hex:
 mov bh,byte ptr hexbin
 cmp bh,01h
 jne check_end        
 mov bx,handler9
 mov handler10,bx
 call read_hexchar
 call read_hexchar_sub
 call read_hexchar_sub_handler
check_end:
 call terminate
 popa
 ret
mode_choice endp

;----------------------------------------------------------------------------
terminate proc
int 20h
ret
terminate endp

;----------------------------------------------------------------------------
press_pagedown proc
 pusha
 mov byte ptr mode,0FFh
 push bx
 mov bh,byte ptr hexbin
 cmp bh,00h
 pop bx
 jne page_down_check_hex
 push bx
 mov bx,handler9
 mov handler10,bx
 pop bx
 call read_binchar
 page_down_check_hex:
 push bx
 mov bh,byte ptr hexbin
 cmp bh,01h
 pop bx 
 jne page_down_check_end  
 push bx
 mov bx,handler9
 mov handler10,bx
 pop bx
 call read_hexchar
 call read_hexchar_sub
 call read_hexchar_sub_handler
 page_down_check_end:
 call press_pagedown_coord
 call press_pagedown_sub
 popa
 ret
press_pagedown endp

;----------------------------------------------------------------------------
press_pagedown_sub proc
 pusha
 mov bh,byte ptr hexbin
 cmp bh,00h
 push bx
 jnz page_down_sub_check_hex
 mov word ptr cx,handler9
 mov bx,handler11
 sub bx,0AFh
 cmp cx,bx
 jnb skip_pgdown_bin
 add cx,0B0h
skip_pgdown_bin:
 mov word ptr handler9,cx
 mov word ptr handler8,44h
 call write_binchar
page_down_sub_check_hex:
 pop bx
 mov bh,byte ptr hexbin
 cmp bh,01h
 push bx
 jnz page_down_sub_check_end
 mov word ptr cx,handler9
 mov bx,handler11
 sub bx,0576d
 cmp cx,bx
 ja skip_pgdown_hex
 add cx,0576d
skip_pgdown_hex:
 mov word ptr handler9,cx
 mov word ptr handler8,44h
 call write_hexchar
page_down_sub_check_end:
 pop bx
 popa
 ret
press_pagedown_sub endp

;----------------------------------------------------------------------------
press_pagedown_coord proc
 pusha
 mov ah,06h
 mov al,16h
 mov bh,02h
 mov cx,coords
 lea dx,cls1
 int 10h
 popa
 ret
press_pagedown_coord endp

;----------------------------------------------------------------------------
press_pageup proc
 pusha
 mov byte ptr mode,0FEh
 mov bh,byte ptr hexbin
 cmp bh,00h
 jne page_up_check_hex
 push bx
 mov bx,handler9
 mov handler10,bx
 pop bx
 call read_binchar
page_up_check_hex:
 mov bh,byte ptr hexbin
 cmp bh,01h
 jne page_up_check_end        
 push bx
 mov bx,handler9
 mov handler10,bx
 pop bx
 call read_hexchar
 call read_hexchar_sub
 call read_hexchar_sub_handler
page_up_check_end:
 call press_pageup_coord
 call press_pageup_sub
 popa
 ret
press_pageup endp

press_pageup_sub proc
 pusha
 mov bh,byte ptr hexbin
 cmp bh,00h
 jnz page_up_sub_check_hex
 mov word ptr cx,handler9
 cmp cx,0000h
 jbe skip_pgup_bin
 sub cx,0B0h
skip_pgup_bin:
 mov word ptr handler9,cx
 mov word ptr handler8,44h
 call write_binchar
page_up_sub_check_hex:
 mov bh,byte ptr hexbin
 cmp bh,01h
 jnz page_up_sub_check_end
 mov word ptr cx,handler9
 cmp cx,0000h
 jbe skip_pgup_hex
 sub cx,0576d
skip_pgup_hex:
 mov word ptr handler9,cx
 mov word ptr handler8,44h
 call write_hexchar
page_up_sub_check_end:
 popa
 ret
press_pageup_sub endp

;----------------------------------------------------------------------------
press_pageup_coord proc
 pusha
 mov ah,07h
 mov al,16h
 mov bh,02h
 mov cx,coords
 lea dx,cls1
 int 10h
 popa
 ret
press_pageup_coord endp

;----------------------------------------------------------------------------
press_home proc
pusha
 mov dx,[ds:memmory]
 mov dl,02h
 call write_hex_position
 mov ah,02h
 mov bh,02h
 int 10h
 mov [ds:memmory],dx
 popa
call read_keyboard
ret
press_home endp

;----------------------------------------------------------------------------
press_end proc
 pusha
 mov byte ptr coord1,01h
 mov byte ptr coord2,01h
 mov dx,[ds:memmory]
 mov ah,02h
 mov bh,02h
 int 10h
 call read_charbuffer
 cmp al,20h
 jnz skip_read_keyboard
 call read_keyboard
 skip_read_keyboard:
 add dl,01h
 mov [ds:memmory],dx
 call press_end
 popa
 ret
press_end endp

;----------------------------------------------------------------------------
read_keyboard proc
pusha
repeat_read_keyboard:
mov ah,00h
int 16h
cmp ah,left
jnz next_read_F10
jmp press_left
next_read_F10:
cmp ah,F10
jnz next_read_ins
jmp clear_memory
next_read_ins:
cmp ah,ins_key
jnz next_read_del
call insert
next_read_del:
cmp ah,del
jnz next_read_esc
call delete
next_read_esc:
cmp ah,esc_key
jnz next_read_1
jmp exit
next_read_1:
cmp ah,digit+1d
jnz next_read_F2
mov byte ptr char,char_0+1d
call record_char
next_read_F2:
cmp ah,F2
jnz next_read_F5
call mode_choice
next_read_F5:
cmp ah,F5
jnz next_read_F6
call mode_bin
next_read_F6:
cmp ah,F6
jnz next_read_right
call mode_hex
next_read_right:
cmp ah,right
jnz next_read_down
call press_right
next_read_down:
cmp ah,down
jnz next_read_space
call press_down
next_read_space:
cmp ah,space
jnz next_read_del
mov byte ptr char,2Eh
call  record_char
next_read_del:
cmp ah,del
jnz next_read_0
mov byte ptr char,20h
call  record_char
next_read_0:
cmp ah,digit+zero
jnz check_hex_bix
mov byte ptr char,char_0
call  record_char
check_hex_bix:
mov bh,byte ptr hexbin
cmp bh,00h
jnz next_read_02
call movenrf
next_read_02:
cmp ah,digit+2d
jnz next_read_03
mov byte ptr char,char_0+2d
call  record_char
next_read_03:
cmp ah,digit+3d
jnz next_read_04
mov byte ptr char,char_0+3d
call  record_char
next_read_04:
cmp ah,digit+4d
jnz next_read_05
mov byte ptr char,char_0+4d
call  record_char
next_read_05:
cmp ah,digit+5d
jnz next_read_06
mov byte ptr char,char_0+5d
call  record_char
next_read_06:
cmp ah,digit+6d
jnz next_read_07
mov byte ptr char,char_0+6d
call  record_char
next_read_07:
cmp ah,digit+7d
jnz next_read_08
mov byte ptr char,char_0+7d
call  record_char
next_read_08:
cmp ah,digit+8d
jnz next_read_09
mov byte ptr char,char_0+8d
call  record_char
next_read_09:
cmp ah,digit+9d
jnz next_read_0A
mov byte ptr char,char_0+9d
call  record_char
next_read_0A:
cmp ah,A_key
jnz next_read_0B
mov byte ptr char,char_A+0Ah
call  record_char
next_read_0B:
cmp ah,B_key
jnz next_read_0C
mov byte ptr char,char_A+0Bh
call  record_char
next_read_0C:
cmp ah,C_key
jnz next_read_0D
mov byte ptr char,char_A+0Ch
call  record_char
next_read_0D:
cmp ah,D_key
jnz next_read_0E
mov byte ptr char,char_A+0Dh
call  record_char
next_read_0E:
cmp ah,E_key
jnz next_read_0F
mov byte ptr char,char_A+0Eh
call  record_char
next_read_0F:
cmp ah,F_key
jnz next_read_F3
mov byte ptr char,char_A+0Fh
call  record_char
next_read_F3:
cmp ah,F3
jnz next_read_F4
call read_file
next_read_F4:
cmp ah,F4
jnz next_read_home
call create_file
next_read_home:
cmp ah,home
jnz next_read_end
call press_home
next_read_end:
cmp ah,end_key
jnz next_read_up
call press_end
next_read_up:
cmp ah,up
jnz next_read_pageup
call press_up
next_read_pageup:
cmp ah,pageup
jnz next_read_pagedown
call press_pageup
next_read_pagedown:
cmp ah,pagedown
jnz repeat_read
call press_pagedown
repeat_read:
jmp repeat_read_keyboard
popa
ret
read_keyboard endp

;----------------------------------------------------------------------------
record_char proc
 pusha
repeat_record:
 mov dx,[ds:memmory]
 call write_hex_position
 cmp dl,4Ah
 jb mod_hex
 add dh,01h
 cmp dh,16h
 jb do_record
 call press_pagedown
do_record:
 mov dl,02h
 call write_hex_position
mod_hex:
 lea si,char
 mov bl,color
 call print_char
 add dl,01h
 mov ah,02h
 mov bh,02h
 int 10h
 mov [ds:memmory],dx
 mov bh,byte ptr hexbin
 cmp bh,00h
 jnz record_char_check_hexbin
 mov ch,byte ptr coord1
 add ch,01h
 mov byte ptr coord1,ch
 cmp ch,09h
 jnz record_char_check_hexbin
 mov byte ptr coord1,00h
 mov byte ptr char,2Eh
 jmp repeat_record
record_char_check_hexbin:
 cmp bh,01h
 jnz end_record
 mov ch,byte ptr coord2
 add ch,01h
 mov byte ptr coord2,ch
 cmp ch,03h
 jnz end_record
 mov byte ptr coord2,00h
 mov byte ptr char,2Eh
 jmp repeat_record
end_record:
 popa
 ret
record_char endp

;----------------------------------------------------------------------------
shift_hex proc
 pusha
 mov bh,byte ptr handler7
 mov cl,04h
 shl bh
 or bh,byte ptr handler2
 mov byte ptr handler7,bh
 mov ch,byte ptr handler6
 add ch,04h
 mov byte ptr handler6,ch
 cmp ch,08h
 jnae moveby_hex
 call form_byte
moveby_hex:
 popa
 jmp quee1
 ret
shift_hex endp

;----------------------------------------------------------------------------
shift_bin proc
 pusha
 mov bh,byte ptr handler7
 shl bh,1
 or bh,byte ptr handler2
 mov byte ptr handler7,bh
 mov ch,byte ptr handler6
 add ch,01h
 mov byte ptr handler6,ch
 cmp ch,08h
 jnae moveby_bin
 call form_byte
moveby_bin:
 popa
 jmp quee
 ret
shift_bin endp

;----------------------------------------------------------------------------
form_byte proc
 pusha
 mov byte ptr handler6,00h
 push bx
 push cx
 mov word ptr bx,handler10
 mov ch,byte ptr handler7
 push ds
 push si
 mov si,9000h
 mov ds,si
 mov byte ptr [bx],ch
 pop si
 pop ds
 mov byte ptr handler7,00h
 add bx,0001h
 mov word ptr handler10,bx
 pop cx
 pop bx
 mov bh,byte ptr mode
 cmp bh,0F6h
 jz another_handle
 cmp byte ptr hexbin,00h
 jnz check_bin_form_byte
 jmp quee
check_bin_form_byte:
 cmp byte ptr hexbin,01h
 jnz another_handle
 jmp quee1
another_handle:
 cmp byte ptr hexbin,01h
 jnz check_hex_form_byte
 jmp quee
check_hex_form_byte:
 cmp byte ptr hexbin,00h
 jnz check_end_form_byte
 jmp quee1
check_end_form_byte:
 popa
 ret
form_byte endp

;----------------------------------------------------------------------------
read_binchar proc
push cx
push dx
push ax
push bx
reche0:
mov cx,handler5
mov dx,cx
call read_charbuffer
cmp al,30h
jnz nex0
mov byte ptr handler2,00h
call shift_bin
nex0:
cmp al,31h
jnz quee
mov byte ptr handler2,01h
call shift_bin
quee:
mov cx,handler5
add cl,01h
mov handler5,cx
cmp cl,4Ah
jbe reche0 
mov cl,02h
add ch,01h
mov handler5,cx
cmp ch,16h
jbe reche0
pop bx
pop ax
pop dx
pop cx
push bx
push bx
push cx
mov ax,handler11
mov bx,handler9
mov cx,handler10
mov dx,0000h
cmp cx,ax
jna skipit
mov handler11,cx
jmp skachok
skipit:
sub ax,bx
cmp ax,0B0h
jnb skachok
mov handler11,cx
skachok:
pop cx
pop bx

end_read_binchar:
ret
read_binchar endp

read_binchar_sub_handler proc
 pusha
 mov word ptr handler5,0102h
 mov bh,byte ptr mode
 cmp bh,0E0h
 jne daemp
 call return_to_delete_bin
 daemp:
 cmp bh,0F1h
 jne jaemp
 call return_to_insert_bin
 jaemp:
 cmp bh,0F2h
 jne jamp
 call save_file
 jamp:
 cmp bh,0FFh
 jnz comme2
 call press_pagedown_coord
 call press_pagedown_sub
 comme2:
 cmp bh,0FEh
 jnz comme3
 jmp goko2
 comme3:
 cmp bh,0F6h
 jne end_read_binchar
 mov word ptr handler10,0000h
 mov word ptr handler9,0000h
 call write_hexchar
 popa
 ret
read_binchar_sub_handler endp

;----------------------------------------------------------------------------
read_hexchar proc
pusha
read_hexchar_begin:
mov cx,handler5
mov dx,CX
call read_charbuffer
cmp al,char_0
jnz next_1
mov byte ptr handler2,00h
call shift_hex
next_1:
cmp al,char_0+1d
jnz next_2
mov byte ptr handler2,01h
call shift_hex
next_2:
cmp al,char_0+2d
jnz next_3
mov byte ptr handler2,02h
call shift_hex
next_3:
cmp al,char_0+3d
jnz next_4
mov byte ptr handler2,03h
call shift_hex
next_4:
cmp al,char_0+4d
jnz next_5
mov byte ptr handler2,04h
call shift_hex
next_5:
cmp al,char_0+5d
jnz next_6
mov byte ptr handler2,05h
call shift_hex
next_6:
cmp al,char_0+6d
jnz next_7
mov byte ptr handler2,06h
call shift_hex
next_7:
cmp al,char_0+7d
jnz next_8
mov byte ptr handler2,07h
call shift_hex
next_8:
cmp al,char_0+8d
jnz next_9
mov byte ptr handler2,08h
call shift_hex
next_9:
cmp al,char_0+9d
jnz next_A
mov byte ptr handler2,09h
call shift_hex
next_A:
cmp al,char_A+0Ah
jnz next_B
mov byte ptr handler2,0Ah
call shift_hex
next_B:
cmp al,char_A+0Bh
jnz next_C
mov byte ptr handler2,0Bh
call shift_hex
next_C:
cmp al,char_A+0Ch
jnz next_D
mov byte ptr handler2,0Ch
call shift_hex
next_D:
cmp al,char_A+0Dh
jnz next_E
mov byte ptr handler2,0Dh
call shift_hex
next_E:
cmp al,char_A+0Eh
jnz next_F
mov byte ptr handler2,0Eh
call shift_hex
next_F:
cmp al,char_A+0Fh
jnz check_read_hexchar
mov byte ptr handler2,0Fh
call shift_hex
check_read_hexchar:
mov cx,handler5
add cl,01H
mov handler5,cx
cmp cl,4Ah
jnbe hex_next_row
jmp read_hexchar_begin
hex_next_row:
mov cl,02H
add ch,01H
mov handler5,cx
cmp ch,16h
jnbe hex_next_end
jmp read_hexchar_begin
hex_next_end:
popa
ret
read_hexchar endp

;----------------------------------------------------------------------------
read_hexchar_sub proc
pusha
 mov ax,handler11
 mov bx,handler9
 mov cx,handler10
 mov dx,0000h
 cmp cx,ax
 jna hex_sub_skip
 mov handler11,cx
 jmp hex_sub_end
hex_sub_skip:
 sub ax,bx
 cmp ax,0576d
 jnb hex_sub_end
 mov handler11,cx
hex_sub_end:
 popa
 ret
read_hexchar_sub endp

;----------------------------------------------------------------------------
read_hexchar_sub_handler proc
pusha
 mov word ptr handler5,0102h
 mov bh,byte ptr mode
 cmp bh,0F1h
 jne to_delete_check
 call return_to_insert_hex
to_delete_check:
 cmp bh,0E0h
 jne to_fsave_check
 call return_to_delete_hex
to_fsave_check:
 cmp bh,0F2h
 call save_file
 cmp bh,0FFh
 jnz comme
 jmp goko
comme:
 cmp bh,0FEh
 jnz comme4
 jmp goko2
comme4:
 cmp bh,0F6h
 jne skip_write_hexchar
 mov word ptr handler10,0000h
 mov word ptr handler9,0000h 
 call write_binchar
skip_write_hexchar:
 popa
 ret
read_hexchar_sub_handler endp

;----------------------------------------------------------------------------
create_file proc
 pusha
 lea dx,cfile
 mov ah,02h
 mov bh,02h
 int 10h
 mov ah,0ah
 mov word ptr [ds:buffer],0FFFFh
 lea bx,buffer+00h
 mov dx,bx
 int 21h
 call write_path
 call restore_coordinates
 popa
 ret
create_file endp

;----------------------------------------------------------------------------
save_file proc
 pusha
 lea dx,ds:buffer+02h
 mov ah,3Ch
 xor cx,cx
 int 21h
 push bx
 push ds
 push si
 mov bx,handler11
 sub bx,0000h
 mov si,9000h
 mov ds,si
 mov dx,0000h
 mov cx,bx
 pop bx
 push bx
 mov bx,ax
 mov ah,40h
 int 21h
 pop si
 pop ds
 pop bx
 popa
 call restore_coordinates
 call read_keyboard
 ret
save_file endp

;----------------------------------------------------------------------------
read_file proc
 pusha
 mov byte ptr mode,0F5h
 mov byte ptr handler8,55h
 mov word ptr handler9,0000h
 lea dx,ds:buffer+02h
 mov ax,3D00h
 xor cx,cx
 int 21h
 pusha
 mov bx,ax
 sub cx,cx
 sub dx,dx
 mov ax,4202h
 int 21h
 pusha
 sub dx,dx
 mov ax,4200h
 int 21h
 popa
 mov word ptr cx,ax
 popa
 pusha
 mov si,9000h
 mov ds,si
 mov dx,0000h
 mov bx,ax
 mov ah,3Fh
 int 21h
 popa
 add cx,0000h
 mov handler11,cx
 popa
 pusha
 mov bh,byte ptr hexbin
 cmp bh,00h
 jne read_file_hex
 call write_binchar
read_file_hex:
 cmp bh,01h
 jne read_file_end
 call write_hexchar
read_file_end:
 call read_keyboard
 popa
ret
read_file endp

;----------------------------------------------------------------------------
exit proc
 call set_video
 int 20h
 ret
exit endp

;----------------------------------------------------------------------------

upp db 'ษอออออออออออออออออออออออออออ B i n a r y   E d i t o r  v1.66 อออออออออออออออออป',00h
dwn db 'ศอออออM:[   ]ออออออออออออออออออออออออออออออออออออออออออY:[01]อออออX:[02]อออออออผ',00h
bok db 'บ',00h
modabin db 'BIN',00h
modahex db 'HEX',00h
color db 0Fh
mode db 00h
handler2 db 00h
handler3 dw 0000h
handler4 db 00h
hanlder5 dw 0102h
handler6 db 00h
hanlder7 db 00000000b
handler8 db 00h
handler9 dw 0000h
handler10 dw 0000h
handler11 dw 0000h
handler12 dw 173Ah
handler13 dw 0000h
handler14 dw 0102h
mode db 00h
cls1 dw 164Eh
coord1 db 01h
coord2 db 01h
coords dw coords
pos1 dw 00h
pos2 dw 00h
hexbin db 00h
sympos db 00h
char db 00h
memseg dw 0B800h
adr_di dw 2000h
cfile dw 0000h
up db 48h
left db 4Bh
right db 4Dh
down db 50h
A_key db 1Eh
B_key db 30h
C_key db 2Eh
D_key db 20h
E_key db 12h
F_key db 21h
F2 db 3Ch
F3 db 3Dh
F4 db 3Eh
F5 db 3Fh
F6 db 40h
F10 db 44h
del db 53h
home db 47h
space db 39h
pageup db 49h
pagedown db 51h
ins_key db 52h
esc_key db 01h
end_key db 4Fh
hexpos1 dw 173Ah
hexpos2 dw 1745h
char_0 db 30h
char_A db 37h
digit db 02h
zero db 0Ah
buffer db 80 DUP(?)
memmory dw ?
progg ends
end startup