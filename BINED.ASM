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
 mov dh,00h
 mov dl,00h
 call draw_border_bok
 mov dh,00h
 mov dl,4Fh
 call draw_border_bok
;After call reading of command line parameters
 call get_commandline
 mov byte ptr [ds:1223h],00h
;Set the starting cursor coordinates 
 call set_coordinates
;At the end switch to binary mode which is default at startup
 call mode_bin
ret
startup endp

;----------------------------------------------------------------------------
add_byte proc
push ax
push bx
push cx
push dx
mov cx,[ds:1212h]
add cx,01h
mov [ds:1212h],cx
mov dx,[ds:1218h]
mov bx,[ds:120Eh]
sub dx,01h
add bx,dx
mov al,00h
again_insert:
mov ah,al
mov al,[ds:bx]
mov [ds:bx],ah
add bx,01h
cmp bx,cx
jz end_insert
jmp again_insert
end_insert:
pop dx
pop cx
pop bx
pop ax
ret
add_byte endp

;----------------------------------------------------------------------------
sub_byte proc
push ax
push bx
push cx
push dx
mov cx,[ds:1212h]
sub cx,01h
mov [ds:1212h],cx
mov dx,[ds:1218h]
mov bx,[ds:120Eh]
sub dx,01h
add bx,dx
cmp bx,cx
jbe again_delete
add cx,01h
mov [ds:1212h],cx
jmp end_delete
again_delete:
add bx,01h
mov al,[ds:bx]
sub bx,01h
mov [ds:bx],al
add bx,01h
cmp bx,cx
jae end_delete
jmp again_delete
end_delete:
pop dx
pop cx
pop bx
pop ax
ret
sub_byte endp

;----------------------------------------------------------------------------
set_coordinates proc
push dx
push bx
push ax
mov byte ptr [ds:120Ch],01h
mov byte ptr [ds:120Ah],01h
mov dh,01h
mov dl,02h
mov [ds:1A00h],dx
mov ah,02h
mov bh,02h
int 10h
pop ax
pop bx
pop dx
ret
set_coordinates endp

;----------------------------------------------------------------------------
restore_coordinates proc
push dx
push bx
push ax
mov dx,[ds:1A00h]
mov ah,02h
mov bh,02h
int 10h
pop ax
pop bx
pop dx
ret
restore_coordinates endp
;----------------------------------------------------------------------------
set_video proc
push ax
mov ah,00h
mov al,03h
int 10h
mov ah,05h
mov al,02h
int 10h
pop ax
ret
set_video endp

;----------------------------------------------------------------------------
set_defaults proc
push ax
push bx
push dx
mov byte ptr [ds:1200h],00h
mov byte ptr [ds:1201h],00h
mov word ptr [ds:1202h],0000h
mov byte ptr [ds:1204h],00h
mov word ptr [ds:1206h],0102h
mov byte ptr [ds:1208h],00h
mov byte ptr [ds:1209h],00000000b
mov byte ptr [ds:120Bh],00h

mov word ptr [ds:120Eh],0000h
mov word ptr [ds:1210h],0000h
mov word ptr [ds:1212h],0000h
mov word ptr [ds:1214h],173Ah
mov word ptr [ds:1216h],0000h
mov word ptr [ds:1218h],0102h
pop dx
pop bx
pop ax
ret
set_defaults endp

;----------------------------------------------------------------------------
cls proc
push ax
push bx
push cx
push dx
;Clear screen but leave surrouning borders
 mov ah,06h
 mov al,16h
 mov bh,02h
 mov cx,0101h
 mov dx,164Eh
 int 10h
pop dx
pop cx
pop bx
pop ax
ret
cls endp

;----------------------------------------------------------------------------
clear_memory proc
;Call clear sreen procedure first
 call cls
;Then call set defaults procedure to erase all memmory links
 call set_defaults
;Return handle to keyboard reading
 jmp read_keyboard
ret
clear_memory endp

;----------------------------------------------------------------------------
insert proc
push ax
push bx
push cx
push dx
mov bx,[ds:120Eh]
mov [ds:1210h],bx
mov bh,[ds:1223h]
cmp bh,00h
jnz skyp
mov byte ptr [ds:1200h],0F1h
call read_binchar
return_toinsert:
mov dx,[ds:1A00h]
mov ch,[ds:120Ah]
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
mov [ds:1218h],dx
call add_byte
call write_binchar
skyp:
cmp bh,01h
jnz skyp2
mov byte ptr [ds:1200h],0F1h
call read_hexchar
return_toinsert2:
mov dx,[ds:1A00h]
mov ch,[ds:120Ah]
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
mov [ds:1218h],dx
call add_byte
call write_hexchar
skyp2:
pop dx
pop cx
pop bx
pop ax
call restore_coordinates
jmp read_keyboard
ret
insert endp

;----------------------------------------------------------------------------
delete proc
push ax
push bx
push cx
push dx
mov bx,[ds:120Eh]
mov [ds:1210h],bx
mov bh,[ds:1223h]
cmp bh,00h
jnz skdp
mov byte ptr [ds:1200h],0E0h
call read_binchar
return_todelete:
mov dx,[ds:1A00h]
mov ch,[ds:120Ah]
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
mov [ds:1218h],dx
call sub_byte
call write_binchar
skdp:
cmp bh,01h
jnz skdp2
mov byte ptr [ds:1200h],0E0h
call read_hexchar
return_todelete2:
mov dx,[ds:1A00h]
mov ch,[ds:120Ah]
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
mov [ds:1218h],dx
call sub_byte
call write_hexchar
skdp2:
pop dx
pop cx
pop bx
pop ax
jmp read_keyboard
ret
delete endp

;----------------------------------------------------------------------------
get_commandline proc
push ax
push bx
push dx
push cx
;Terminate filepath entered from command line with null
 mov cx,0000h
 mov cl,[ds:0080h]
 mov bx,0081h
 add bx,cx
 mov byte ptr [bx],00h
push dx
push ax
push bx
;Copy filepath to another memmory address
 mov ax,0000h
 mov bx,0080h
 add bx,ax
 mov byte ptr dl,[bx]
 add bx,1281h
 mov [bx],dl
;Copy cycle
nexxx9:
 mov bx,0082h
 add bx,ax
 mov byte ptr dl,[bx]
 add bx,1280h
 mov [bx],dl
 add ax,0001h
 cmp ax,cx
 jna nexxx9
;End of copy cycle
 add bx,ax
 mov byte ptr dl,[bx]
 add bx,1280h
 mov [bx],dl
pop dx
pop ax
pop bx
pop cx
pop dx
pop bx
pop ax
;Call filepath printing to screen
call write_path
ret
get_commandline endp

print_string proc
 mov AX,80  ;вычисл€ем адрес
 mul dh
 mov cx,0000h
 mov cl,dl
 add AX,cx
 shl AX,1  ;адрес в AX=160*y+2*x
 mov DI,AX
 add di,2000h
 push ES       ;сохран€ем ES
 mov AX,0B800h ;сегмент экранной пам€ти в текстовом режиме
 mov ES,AX
 Print:
  mov al,[ds:si]      ;загр\ужаем AL из DS:[SI]
  cmp al,00h
  jz Ready   ;да, AL=0
  mov ES:[DI],AL ;символ дл€ отображени€
  add si,01h
  add DI,1
  mov ES:[DI],bl
  add DI,1
  jmp Print
 Ready: pop ES ;восстанавливаем ES
ret
print_string endp

;----------------------------------------------------------------------------
write_path proc
push ax
push bx
push dx
push cx
;Print entered filepath to screen
 mov dh,18h
 mov dl,02h
 mov si,1302h
 mov cx,0000h
 mov byte ptr cl,ds:1301h
 mov bx,1302h
 add bx,cx
 mov byte ptr [bx],00h
 mov bl,0Fh
call print_string
pop cx
pop dx
pop bx
pop ax
call restore_coordinates
ret
write_path endp

;----------------------------------------------------------------------------
draw_border proc
push ax
push bx
push dx
push cx
;Draw footer
mov bl,0Ah
 mov dh,17h
 mov dl,0h
lea si,dwn
call print_String
 mov dh,00h
 mov dl,00h
lea si,upp
call print_String
pop cx
pop dx
pop bx
pop ax
ret
draw_border endp

;----------------------------------------------------------------------------
draw_border_bok proc
push ax
push bx
push dx
push cx
draw_border_bok_begin:
;Draw piece of border
 add dh,01h
; mov ah,13h
; mov al,00h
mov bl,0Ah
; mov bh,02h
lea si,bok
call print_char
; mov cx,01h
; int 10h
;Cycle of border render
 cmp dh,16h
 jb draw_border_bok_begin
;Check whether other side is rendered, if not then call render of second side
pop cx
pop dx
pop bx
pop ax
ret
draw_border_bok endp

;----------------------------------------------------------------------------
mode_bin proc
push ax
push bx
push dx
push cx
;Print out BIN word to show user the binary mode is switched on
 mov dh,17h
 mov dl,09h
 mov bl,0Eh
 lea si,modabin
 call print_string
pop cx
pop dx
pop bx
pop ax
push bx
;Check which mode does user has switched from 
 mov bh,[ds:1223h]
 cmp bh,01h
 jz switch_hextobin
pop bx
;Return handle to keyboard reading
jmp read_keyboard
ret
mode_bin endp

;----------------------------------------------------------------------------
mode_hex proc
push ax
push bx
push dx
push cx
;Print out HEX word to show user the hexadecimal mode is switched on
 mov dh,17h
 mov dl,09h
 mov bl,0Eh
 lea si,modahex
 call print_string
pop cx
pop dx
pop bx
pop ax
push bx
;Check which mode does user has switched from 
 mov bh,[ds:1223h]
 cmp bh,00h
 jz switch_bintohex
pop bx
jmp read_keyboard
ret
mode_hex endp

;----------------------------------------------------------------------------
switch_bintohex proc
pop bx
;Return handle to keyboard reading and set variable to 1-hex
 mov byte ptr [ds:1223h],01h
;Set variable to F6 meaning that mode switching operation is at handle
 mov byte ptr [ds:1200h],0F6h
 mov bx,[ds:120Eh]
 mov [ds:1210h],bx
;Call binary characters reading procedure
 jmp read_binchar
ret
switch_bintohex endp

;----------------------------------------------------------------------------
switch_hextobin proc
pop bx
;Return handle to keyboard reading and set variable to 0-bin
 mov byte ptr [ds:1223h],00h
;Set variable to F6 meaning that mode switching operation is at handle
 mov byte ptr [ds:1200h],0F6h
 mov bx,[ds:120Eh]
 mov [ds:1210h],bx
;Call binary characters reading procedure
 jmp read_hexchar
ret
switch_hextobin endp

;----------------------------------------------------------------------------
write_char proc
push ax
push cx
push bx
push dx
mov dx,[ds:1214h]
;mov ah,02h
;mov bh,02h
;int 10h
;mov ah,0Eh
;mov bh,02h
mov bl,02h
;mov cx,01h
mov si,1216h
call print_char
;int 10h
add dl,01h
cmp dl,4Ah
jb movye
push dx
mov dx,[ds:1230h]
mov bh,[ds:1223h]
cmp bh,00h
jnz skinex
add dx,0008h
skinex:
mov bh,[ds:1223h]
cmp bh,01h
jnz skinex2
add dx,0018h
skinex2:
push dx
mov dx,[ds:1214h]
add dl,02h
mov [ds:1237h],dx
pop dx
call write_hex_rownumber
mov [ds:1230h],dx
pop dx
mov dl,02h
add dh,01h
cmp dh,17h
jnz movye
call hex_end
movye:
mov [ds:1214h],dx
pop dx
pop bx
pop cx
pop ax
ret
write_char endp

print_char proc
 mov AX,80  ;вычисл€ем адрес
 mul dh
 mov cx,0000h
 mov cl,dl
 add AX,cx
 shl AX,1  ;адрес в AX=160*y+2*x
 mov DI,AX
 add di,2000h
 push ES       ;сохран€ем ES
 mov AX,0B800h ;сегмент экранной пам€ти в текстовом режиме
 mov ES,AX
 mov al,[ds:si]
 mov ES:[DI],AL
 add DI,1
 mov ES:[DI],bL
 add DI,1
 pop ES
ret
print_char endp


;----------------------------------------------------------------------------
write_char_number proc
push ax
push cx
push bx
push dx
;Setting position for printing
mov dx,[ds:1237h]
;Printing character for row number
mov bl,06h
mov si,1216h
;Adding 1 for the next position of char
call print_char
add dl,01h
mov [ds:1237h],dx
pop dx
pop bx
pop cx
pop ax
ret
write_char_number endp

;----------------------------------------------------------------------------
write_hexchar proc
;Clearing the stack
 mov sp,00h
;Clearing screen for writing of new information
 call cls
push bx
push ax
push cx
push dx
;Preparations necessary for rendering only visible part of memmory to screen
 mov ax,[ds:1212h]
 mov dx,[ds:120Eh]
 sub dx,0000h
 mov [ds:1230h],dx
pop dx
 mov word ptr [ds:1214h],0102h
 sub ax,[ds:120Eh]
;Check for completition of cycle
 cmp ax,00h
 jnz skip8
 call hex_end
 skip8:
 mov word ptr cx,0000h
 mov dx,0000h
 nekst:
 mov word ptr bx,[ds:120Eh]
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
 mov byte ptr [ds:1204h],dl
pop bx
push cx
;Calling procedure for writing of hexadecimal bytes
 call write_hextoscreen
;Printing a point to separate bytes
 mov byte ptr [ds:1216h],2Eh
 call write_char
pop cx
;Check for completition of cycle, if not goto next
 add word ptr cx,0001h
 cmp cx,ax
 jae skok
 call nekst
;Exit from cycle
skok:
pop cx
pop ax
pop bx
call hex_end
ret
write_hexchar endp

;----------------------------------------------------------------------------
write_binchar proc
;Clearing the stack
 mov sp,00h
;Clearing the screen
 call cls
push bx
pop bx
push bx
push ax
push cx
 mov ax,[ds:1212h]
push dx
 mov dx,[ds:120Eh]
 sub dx,0000h
 mov [ds:1230h],dx
pop dx
 mov word ptr [ds:1214h],0102h
 sub ax,[ds:120Eh]
 cmp ax,0000h
 jnz skip9
 call hex_end
 skip9:
 mov word ptr cx,0000h
 mov dx,0000h
nekst2:
 mov word ptr bx,[ds:120Eh]
 add bx,cx
push ds
push si
mov si,9000h
mov ds,si
 mov byte ptr dl,[bx]
pop si
pop ds
 mov byte ptr [ds:1204h],dl
push cx
 call write_bintoscreen
 mov byte ptr [ds:1216h],2Eh
 call write_char
pop cx
 add word ptr cx,0001h
 cmp cx,ax
 jae skok2
 call nekst2
skok2:
pop cx
pop ax
pop bx
call hex_end
ret
write_binchar endp

;----------------------------------------------------------------------------
hex_end proc
;Byte writing end scope
mov byte ptr [ds:120Bh],00h
;Check whether to restore or truncate cursor coordinates
mov ch,[ds:1200h]
cmp ch,0F5h
jb toposition_correction2
call set_coordinates
toposition_correction2:
call restore_coordinates
call read_keyboard
ret
hex_end endp

;----------------------------------------------------------------------------
write_bintoscreen proc
;push ax
;push bx
;push dx
;mov dx,[ds:1214h]
;mov ah,02h
;mov bh,02h
;int 10h
;pop dx
;pop bx
;pop ax
 push CX
 push DX
 ext:
 mov dl,[ds:1204h]
 mov dh,[ds:1204h]
 and dl,10000000b
 shl dh,1h
 mov [ds:1204h],dh
 cmp dl,80h
 jnz gogo1
 PUSH DX
 mov BYTE PTR [ds:1216h],31h
 call write_char
 Pop DX
 gogo1:
 cmp dl,00h
 jnz gogo2
 PUSH DX
 mov byte ptr [ds:1216h],30h
 call write_char
 pop dx
 gogo2:
 mov cx,[ds:1202h]
 add cx,0001h
 mov [ds:1202h],cx
 cmp cx,0008h
 jb ext
 mov word PTR [ds:1202h],0000h
 pop DX
 pop CX
ret
write_bintoscreen endp

;----------------------------------------------------------------------------
write_hextoscreen proc
;push ax
;push bx
;push dx
;mov dx,[ds:1214h]
;mov ah,02h
;mov bh,02h
;int 10h
;pop dx
;pop bx
;pop ax
 push CX
 push DX
 mov dh,[ds:1204h]
 mov DL,DH
 mov CL,4
 shr DL,CL
 call write_hexdigit
 mov DL,DH
 and DL,0Fh
 call write_hexdigit
 pop DX
 pop CX
ret
write_hextoscreen endp

;----------------------------------------------------------------------------
write_hexdigit proc
 push DX
 cmp DL,0Ah    
 jae HEX_LETTER
 add DL,30h
 JMP WRITE_DIGIT
 HEX_LETTER:
 add DL,37h
 WRITE_DIGIT:
 mov [ds:1216h],dl
 call write_char
 pop DX  
 ret
write_hexdigit endp

;----------------------------------------------------------------------------
write_hex_digi proc
 push DX
 cmp DL,0Ah    
 jae HEX_LETTE
 add DL,30h
 JMP WRITE_DIGI
 HEX_LETTE:
 add DL,37h
 WRITE_DIGI:
 mov [ds:1216h],dl
 call write_char_number
 pop DX  
 ret
write_hex_digi endp

;----------------------------------------------------------------------------
write_hex_rownumber proc
push CX
push DX
 mov DL,DH        
 mov CL,4
 shr DL,CL
 call write_hex_digi
 mov DL,DH
 and DL,0Fh
 call write_hex_digi
pop DX
pop CX
push CX
push DX
 mov DH,DL        
 mov CL,4
 shr DL,CL
 call write_hex_digi
 mov DL,DH
 and DL,0Fh
 call write_hex_digi
pop DX
pop CX
ret
write_hex_rownumber endp

;----------------------------------------------------------------------------
write_hex_position proc
 mov [ds:1214h],173Ah
 push CX
 push DX
 mov DL,DH        
 mov CL,4
 shr DL,CL
 call write_hexdigit
 mov DL,DH
 and DL,0Fh
 call write_hexdigit
 pop DX
 pop CX
 push CX
 push DX
 mov DH,DL        
 mov CL,4
 shr DL,CL
 mov [ds:1214h],1745h
 call write_hexdigit
 mov DL,DH
 and DL,0Fh
 call write_hexdigit
 pop DX
 pop CX
 ret
write_hex_position endp

;----------------------------------------------------------------------------
press_down proc
push ax
push dx
push bx
mov dx,[ds:1A00h]
add dh,01h
call write_hex_position
cmp dh,16h
jb movhi
mov dh,16h
call write_hex_position
movhi:
mov ah,02h
mov bh,02h
int 10h
mov [ds:1A00h],dx
mov ah,08h
mov bh,02h
int 10h
cmp al,20h
ja gogogaga
mov dx,[ds:1A00h]
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
gogogaga:
mov [ds:1A00h],dx
pop bx
pop dx
pop ax
jmp read_keyboard
ret
press_down endp

;----------------------------------------------------------------------------
press_right proc
push ax
push dx
push bx
mov dx,[ds:1A00h]
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
mov [ds:1A00h],dx
mov ah,08h
mov bh,02h
int 10h
cmp al,20h
ja gogogog
mov dx,[ds:1A00h]
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
mov [ds:1A00h],dx
jmp achto6
gogogog:
mov bh,[ds:1223h]
cmp bh,00h
jnz achto5
mov ch,[ds:120Ah]
add ch,01h
mov [ds:120Ah],ch
cmp ch,09h
jnz achto5
mov byte ptr [ds:120Ah],00h
mov byte ptr [ds:1400h],2Eh
call record_char
achto5:
cmp bh,01h
jnz achto6
mov ch,[ds:120Ch]
add ch,01h
mov [ds:120Ch],ch
cmp ch,03h
jnz achto6
mov byte ptr [ds:120Ch],00h
mov byte ptr [ds:1400h],2Eh
call  record_char
ACHTO6:
pop bx
pop dx
pop ax
jmp read_keyboard
ret
press_right endp



read_charbuffer proc
 mov AX,80  ;вычисл€ем адрес
 mul dh
 mov cx,0000h
 mov cl,dl
 add AX,cx
 shl AX,1  ;адрес в AX=160*y+2*x
 mov DI,AX
 add di,2000h
 push ES       ;сохран€ем ES
 mov AX,0B800h ;сегмент экранной пам€ти в текстовом режиме
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
mov dx,[ds:1A00h]
mov bh,[ds:1223h]
cmp bh,00h
jnz sledu
mov ch,[ds:120Ah]
cmp ch,01h
jnz gotnext2
cmp dl,0Ah
jb sledu
sub dl,09h
mov byte ptr [ds:1220h],09h
sledu:
mov bh,[ds:1223h]
cmp bh,01h
jnz sledu2
mov ch,[ds:120Ch]
cmp ch,01h
jnz gotnext2
cmp dl,05h
jb sledu2
sub dl,03h
mov byte ptr [ds:1220h],03h
sledu2:
jmp gatta2
gotnext2:
sub dl,01h
mov byte ptr [ds:1220h],01h
gatta2:
call write_hex_position
mov ah,02h
mov bh,02h
int 10h

call read_charbuffer
mov [ds:1A00h],dx
;mov ah,08h
;mov bh,02h
;int 10h

cmp al,20h
ja gogogo
mov dx,[ds:1A00h]
mov byte ptr bh,[ds:1220h]
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
mov [ds:1A00h],dx
jmp achto4
gogogo:
mov bh,[ds:1223h]
cmp bh,00h
jnz achto3
mov ch,[ds:120Ah]
cmp ch,01h
jnz gotnext
mov ch,01h
jmp gatta
gotnext:
sub ch,01h
gatta:
mov [ds:120Ah],ch
cmp ch,09h
jnz achto3
mov byte ptr [ds:120Ah],00h
mov byte ptr [ds:1400h],2Eh
call  record_char
achto3:
mov bh,[ds:1223h]
cmp bh,01h
jnz achto4
mov ch,[ds:120Ch]
cmp ch,01h
jnz gotnext3
mov ch,01h
jmp gatta3
gotnext3:
sub ch,01h
gatta3:
mov [ds:120Ch],ch
cmp ch,03h
jnz achto4
mov byte ptr [ds:120Ch],00h
mov byte ptr [ds:1400h],2Eh
call  record_char
ACHTO4:
pop bx
pop dx
pop ax
jmp read_keyboard
ret
press_left endp

;----------------------------------------------------------------------------
press_up proc
push ax
push dx
push bx
mov dx,[ds:1A00h]
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
mov [ds:1A00h],dx
call read_charbuffer
;mov ah,08h
;mov bh,02h
;int 10h

cmp al,20h
ja gogogoga
bacxk:
mov dx,[ds:1A00h]
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
mov [ds:1A00h],dx
jmp qiit
gogogoga:
cmp al,0A0h
ja bacxk
qiit:
pop bx
pop dx
pop ax
jmp read_keyboard
ret
press_up endp

;----------------------------------------------------------------------------
mode_choice proc
mov byte ptr [ds:1200h],0F2h
push bx
mov bh,[ds:1223h]
cmp bh,00h
jne Rr0
pop bx
mov bx,[ds:120Eh]
mov [ds:1210h],bx
jmp read_binchar
Rr0:
mov bh,[ds:1223h]
cmp bh,01h
jne Rr1        
pop bx
mov bx,[ds:120Eh]
mov [ds:1210h],bx
jmp read_hexchar
Rr1:
pop bx
int 20h
ret
mode_choice endp

;----------------------------------------------------------------------------
press_pagedown proc
push ax
push bx
push cx
push dx
mov byte ptr [ds:1200h],0FFh
push bx
mov bh,[ds:1223h]
cmp bh,00h
jne Rr4
pop bx
push bx
mov bx,[ds:120Eh]
mov [ds:1210h],bx
pop bx
jmp read_binchar
rr4:
mov bh,[ds:1223h]
cmp bh,01h
jne Rr5        
pop bx
push bx
mov bx,[ds:120Eh]
mov [ds:1210h],bx
pop bx
jmp read_hexchar
rr5:
pop bx
goko:
pop dx
pop cx
pop bx
pop ax
push ax
push bx
push cx
push dx
mov ah,06h
mov al,16h
mov bh,02h
mov cx,0101h
mov dx,164Eh
int 10h
pop dx
pop cx
pop bx
pop ax
mov bh,[ds:1223h]
cmp bh,00h
jnz neeeks
mov word ptr cx,[ds:120Eh]
push bx
mov bx,[ds:1212h]
sub bx,0AFh
cmp cx,bx
jnb neksee
add cx,0B0h
neksee:
mov word ptr [ds:120Eh],cx
mov word ptr [ds:120Bh],44h
call write_binchar
neeeks:
pop bx
mov bh,[ds:1223h]
cmp bh,01h
jnz neeeks2
mov word ptr cx,[ds:120Eh]
push bx
mov bx,[ds:1212h]
sub bx,0576d
cmp cx,bx
ja neksee2
add cx, 0576d
neksee2:
mov word ptr [ds:120Eh],cx
mov word ptr [ds:120Bh],44h
call write_hexchar
neeeks2:
jmp read_keyboard
ret
press_pagedown endp

;----------------------------------------------------------------------------
press_pageup proc
push ax
push bx
push cx
push dx
mov byte ptr [ds:1200h],0FEh
push bx
mov bh,[ds:1223h]
cmp bh,00h
jne Rr6
pop bx
push bx
mov bx,[ds:120Eh]
mov [ds:1210h],bx
pop bx
jmp read_binchar
rr6:
mov bh,[ds:1223h]
cmp bh,01h
jne Rr7        
pop bx
push bx
mov bx,[ds:120Eh]
mov [ds:1210h],bx
pop bx
jmp read_hexchar
rr7:
pop bx
goko2:
pop dx
pop cx
pop bx
pop ax
push ax
push bx
push cx
push dx
mov ah,07h
mov al,16h
mov bh,02h
mov cx,0101h
mov dx,164Eh
int 10h
pop dx
pop cx
pop bx
pop ax
mov bh,[ds:1223h]
cmp bh,00h
jnz neeeks3
mov word ptr cx,[ds:120Eh]
cmp cx,0000h
jbe skiip2
Sub cx,0B0h
skiip2:
mov word ptr [ds:120Eh],cx
mov word ptr [ds:120Bh],44h
call write_binchar
neeeks3:
mov bh,[ds:1223h]
cmp bh,01h
jnz neeeks4
mov word ptr cx,[ds:120Eh]
cmp cx,0000h
jbe skiip3
Sub cx,0576d
skiip3:
mov word ptr [ds:120Eh],cx
mov word ptr [ds:120Bh],44h
call write_hexchar
neeeks4:
jmp read_keyboard
ret
press_pageup endp

;----------------------------------------------------------------------------
press_home proc
push ax
push dx
push bx
mov dx,[ds:1A00h]
mov dl,02h
call write_hex_position
mov ah,02h
mov bh,02h
int 10h
mov [ds:1A00h],dx
pop bx
pop dx
pop ax
jmp read_keyboard
ret
press_home endp

;----------------------------------------------------------------------------
press_end proc
push ax
push dx
push cx
push bx
mov byte ptr [ds:120Ah],01h
mov byte ptr [ds:120Ch],01h
mov dx,[ds:1A00h]
mov ah,02h
mov bh,02h
int 10h
call read_charbuffer
cmp al,20h
jnz skype
;sub dl,03h
;mov ah,02h
;mov bh,02h
;int 10h
;mov [ds:1A00h],dx
jmp read_keyboard
skype:
add dl,01h
mov [ds:1A00h],dx
call press_end
pop bx
pop cx
pop dx
pop ax
ret
press_end endp

;----------------------------------------------------------------------------
read_keyboard proc
mov ah,00h
int 16h
cmp ah,4Bh
jnz getto
jmp press_left
getto:
cmp ah,44h
jnz detto
jmp clear_memory
detto:
cmp ah,52h
jnz qetto
jmp insert
qetto:
cmp ah,53h
jnz wetto
jmp delete
wetto:
cmp ah,01h
jnz gettow
jmp exit
gettow:
cmp ah,02h
jnz moven
mov byte ptr [ds:1400h],31h
call  record_char
moven:
cmp ah,3Ch
jnz skipag
call mode_choice
skipag:
cmp ah,3Fh
jnz skipag6
call mode_bin
skipag6:
cmp ah,40h
jnz skipag7
call mode_hex
skipag7:
cmp ah,4Dh
jnz skipag2
call press_right
skipag2:
cmp ah,50h
jnz skipag3
call press_down
skipag3:
cmp ah,39h
jnz movee
mov byte ptr [ds:1400h],2Eh
call  record_char
movee:
cmp ah,53h
jnz moveef
mov byte ptr [ds:1400h],20h
call  record_char
moveef:
cmp ah,0Bh
jnz movenr
mov byte ptr [ds:1400h],30h
call  record_char
movenr:
mov bh,[ds:1223h]
cmp bh,00h
jnz ogo
call movenrf
ogo:
cmp ah,03h
jnz movenr2
mov byte ptr [ds:1400h],32h
call  record_char
movenr2:
cmp ah,04h
jnz movenr1
mov byte ptr [ds:1400h],33h
call  record_char
movenr1:
cmp ah,05h
jnz movenr3
mov byte ptr [ds:1400h],34h
call  record_char
movenr3:
cmp ah,06h
jnz movenr4
mov byte ptr [ds:1400h],35h
call  record_char
movenr4:
cmp ah,07h
jnz movenr5
mov byte ptr [ds:1400h],36h
call  record_char
movenr5:
cmp ah,08h
jnz movenr6
mov byte ptr [ds:1400h],37h
call  record_char
movenr6:
cmp ah,09h
jnz movenr7
mov byte ptr [ds:1400h],38h
call  record_char
movenr7:
cmp ah,0Ah
jnz movenr8
mov byte ptr [ds:1400h],39h
call  record_char
movenr8:
cmp ah,1Eh
jnz movenra
mov byte ptr [ds:1400h],41h
call  record_char
movenra:
cmp ah,30h
jnz movenrb
mov byte ptr [ds:1400h],42h
call  record_char
movenrb:
cmp ah,2Eh
jnz movenrc
mov byte ptr [ds:1400h],43h
call  record_char
movenrc:
cmp ah,20h
jnz movenrd
mov byte ptr [ds:1400h],44h
call  record_char
movenrd:
cmp ah,12h
jnz movenre
mov byte ptr [ds:1400h],45h
call  record_char
movenre:
cmp ah,21h
jnz movenrf
mov byte ptr [ds:1400h],46h
call  record_char
movenrf:
cmp ah,3Dh
jnz belka
call read_file
belka:
cmp ah,3Eh
jnz belka2
call create_file
belka2:
cmp ah,47h
jnz gotoo
call press_home
gotoo:
cmp ah,4Fh
jnz gototo
call press_end
gototo:
cmp ah,48h
jnz skipag5
call press_up
skipag5:
cmp ah,49h
jnz gotoo2
call press_pageup
gotoo2:
cmp ah,51h
jnz retro
call press_pagedown
retro:
jmp read_keyboard
ret
read_keyboard endp

;----------------------------------------------------------------------------
record_char proc
push ax
push cx
push bx
push dx
mov dx,[ds:1A00h]
call write_hex_position
cmp dl,4Ah
jb modh
add dh,01h
cmp dh,16h
jb dorec
call press_pagedown
dorec:
mov dl,02h
call write_hex_position
modh:
mov si,1400h
mov bl,02h
call print_char
add dl,01h
mov ah,02h
mov bh,02h
int 10h
;mov ah,0Eh
;mov bh,02h
;mov bl,1Ah
;mov cx,01h
;int 10h

mov [ds:1A00h],dx
mov bh,[ds:1223h]
cmp bh,00h
jnz achto
mov ch,[ds:120Ah]
add ch,01h
mov [ds:120Ah],ch
cmp ch,09h
jnz achto
mov byte ptr [ds:120Ah],00h
mov byte ptr [ds:1400h],2Eh
call record_char
achto:
cmp bh,01h
jnz achto2
mov ch,[ds:120Ch]
add ch,01h
mov [ds:120Ch],ch
cmp ch,03h
jnz achto2
mov byte ptr [ds:120Ch],00h
mov byte ptr [ds:1400h],2Eh
call  record_char
ACHTO2:
pop dx
pop bx
pop cx
pop ax
ret
record_char endp

;----------------------------------------------------------------------------
shift_hex proc
push bx
push cx
mov bh,[ds:1209h]
shl bh,1h
shl bh,1h
shl bh,1h
shl bh,1h
or bh,[ds:1201h]
mov [ds:1209h],bh
mov ch,[ds:1208h]
add ch,04h
mov [ds:1208h],ch
cmp ch,08h
jnae moveby
call form_byte
moveby:
pop cx
pop bx
jmp quee1
ret
shift_hex endp

;----------------------------------------------------------------------------
shift_bin proc
push bx
push cx
mov bh,[ds:1209h]
shl bh,1
or bh,[ds:1201h]
mov [ds:1209h],bh
mov ch,[ds:1208h]
add ch,01h
mov [ds:1208h],ch
cmp ch,08h
jae form_byte
pop cx
pop bx
jmp quee
ret
shift_bin endp

;----------------------------------------------------------------------------
form_byte proc
mov byte ptr [ds:1208h],00h
push bx
push cx
mov word ptr bx,[ds:1210h]
mov ch,[ds:1209h]
push ds
push si
mov si,9000h
mov ds,si
mov byte ptr [bx],ch
pop si
pop ds
mov byte ptr [ds:1209h],00h
add BX,0001h
MOV word ptr [ds:1210h],BX
pop cx
pop bx
pop cx
pop bx
push bx
mov bh,[ds:1200h]
cmp bh,0F6h
jz another_handle
cmp byte ptr [ds:1223h],00h
jnz susl
jmp quee
susl:
cmp byte ptr [ds:1223h],01h
jnz susl2
jmp quee1
susl2:
another_handle:
cmp byte ptr [ds:1223h],01h
jnz susl3
jmp quee
susl3:
cmp byte ptr [ds:1223h],00h
jnz susl4
jmp quee1
susl4:
ret
form_byte endp

;----------------------------------------------------------------------------
read_binchar proc
push cx
push dx
push ax
push bx
reche0:
mov cx,[ds:1206h]
mov dx,cx
;mov ah,02h
;mov bh,02h
;int 10h
call read_charbuffer
;mov ah,08h
;mov bh,02h
;int 10h
cmp al,30h
jnz nex0
mov byte ptr [ds:1201h],00h
call shift_bin
nex0:
cmp al,31h
jnz quee
mov byte ptr [ds:1201h],01h
call shift_bin
quee:
mov cx,[ds:1206h]
add cl,01h
mov [ds:1206h],cx
cmp cl,4Ah
jbe reche0 
mov cl,02h
add ch,01h
mov [ds:1206h],cx
cmp ch,16h
jbe reche0
pop bx
pop ax
pop dx
pop cx
push bx
push bx
push cx
mov ax,[ds:1212h]
mov bx,[ds:120Eh]
mov cx,[ds:1210h]
mov dx,0000h
cmp cx,ax
jna skipit
mov [ds:1212h],cx
jmp skachok
skipit:
sub ax,bx
cmp ax,0B0h
jnb skachok
mov [ds:1212h],cx
skachok:
pop cx
pop bx
mov word ptr [ds:1206h],0102h
mov bh,[ds:1200h]
cmp bh,0E0h
jne daemp
;mov word ptr [ds:1210h],0000h
;mov word ptr [ds:120Eh],0000h
jmp return_todelete
daemp:
cmp bh,0F1h
jne jaemp
;mov word ptr [ds:1210h],0000h
;mov word ptr [ds:120Eh],0000h
jmp return_toinsert
jaemp:
cmp bh,0F2h
jne jamp
call save_file
jamp:
cmp bh,0FFh
jnz comme2
jmp goko
comme2:
cmp bh,0FEh
jnz comme3
jmp goko2
comme3:
cmp bh,0F6h
jne ryzok
mov word ptr [ds:1210h],0000h
mov word ptr [ds:120Eh],0000h
call write_hexchar
ryzok:
ret
read_binchar endp

;----------------------------------------------------------------------------
read_hexchar proc
push cx
push dx
push ax
push bx
read_hexchar_begin:
mov cx,[ds:1206h]
mov dx,CX
;mov ah,02h
;mov bh,02h
;int 10h
;mov ah,08h
;mov bh,02h
;int 10h
call read_charbuffer
cmp al,30h
jnz nexz
mov byte ptr [ds:1201h],00h
call shift_hex
nexz:
cmp al,31h
jnz nex1
mov byte ptr [ds:1201h],01h
call shift_hex
nex1:
cmp al,32h
jnz nex2
mov byte ptr [ds:1201h],02h
call shift_hex
nex2:
cmp al,33h
jnz nex3
mov byte ptr [ds:1201h],03h
call shift_hex
nex3:
cmp al,34h
jnz nex4
mov byte ptr [ds:1201h],04h
call shift_hex
nex4:
cmp al,35h
jnz nex5
mov byte ptr [ds:1201h],05h
call shift_hex
nex5:
cmp al,36h
jnz nex6
mov byte ptr [ds:1201h],06h
call shift_hex
nex6:
cmp al,37h
jnz nex7
mov byte ptr [ds:1201h],07h
call shift_hex
nex7:
cmp al,38h
jnz nex8
mov byte ptr [ds:1201h],08h
call shift_hex
nex8:
cmp al,39h
jnz nex9
mov byte ptr [ds:1201h],09h
call shift_hex
nex9:
cmp al,41h
jnz nexA
mov byte ptr [ds:1201h],0Ah
call shift_hex
nexA:
cmp al,42h
jnz nexB
mov byte ptr [ds:1201h],0Bh
call shift_hex
nexB:
cmp al,43h
jnz nexC
mov byte ptr [ds:1201h],0Ch
call shift_hex
nexC:
cmp al,44h
jnz nexDd
mov byte ptr [ds:1201h],0Dh
call shift_hex
nexDd:
cmp al,45h
jnz nexE
mov byte ptr [ds:1201h],0Eh
call shift_hex
nexE:
cmp al,46h
jnz quee1
mov byte ptr [ds:1201h],0Fh
call shift_hex
quee1:
mov cx,[ds:1206h]
add cl,01H
mov [ds:1206h],cx
cmp cl,4Ah
jnbe jumpee
call read_hexchar_begin
jumpee:
mov cl,02H
add ch,01H
mov [ds:1206h],cx
cmp ch,16h
jnbe jumpee2
call read_hexchar_begin
jumpee2:
pop bx
pop ax
pop dx
pop cx
push bx
push bx
push cx
mov ax,[ds:1212h]
mov bx,[ds:120Eh]
mov cx,[ds:1210h]
mov dx,0000h
cmp cx,ax
jna skipit2
mov [ds:1212h],cx
jmp skachok2
skipit2:
sub ax,bx
cmp ax,0576d
jnb skachok2
mov [ds:1212h],cx
skachok2:
pop cx
pop bx
mov word ptr [ds:1206h],0102h
mov bh,[ds:1200h]
cmp bh,0F1h
jne jaemp2
;mov word ptr [ds:1210h],0000h
;mov word ptr [ds:120Eh],0000h 
jmp return_toinsert2
jaemp2:
cmp bh,0E0h
jne daemp2
;mov word ptr [ds:1210h],0000h
;mov word ptr [ds:120Eh],0000h 
jmp return_todelete2
daemp2:
cmp bh,0F2h
jz save_file
cmp bh,0FFh
jnz comme
jmp goko
comme:
cmp bh,0FEh
jnz comme4
jmp goko2
comme4:
cmp bh,0F6h
jne ryzok2
mov word ptr [ds:1210h],0000h
mov word ptr [ds:120Eh],0000h 
call write_binchar
ryzok2:
ret
read_hexchar endp

;----------------------------------------------------------------------------
create_file proc
push ax
push bx
push dx
mov dx,1802h
mov ah,02h
mov bh,02h
int 10h
mov ah,0ah
mov word ptr [ds:1300h],0FFFFh
mov bx,1300h
mov dx,bx
int 21h
call write_path
pop dx
pop bx
pop ax
ret
create_file endp

;----------------------------------------------------------------------------
save_file proc
pop bx
lea dx,ds:1302h
mov ah,3Ch
xor cx,cx
int 21h
push bx
mov bx,[ds:1212h]
sub bx,0000h
push ds
push si
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
call restore_coordinates
jmp read_keyboard
ret
save_file endp

;----------------------------------------------------------------------------
read_file proc
push ax
push bx
push cx
push dx
mov byte ptr [ds:1200h],0F5h
mov byte ptr [ds:120Bh],55h
mov word ptr [ds:120Eh],0000h
lea dx,ds:1302h
mov ax,3D00h
xor cx,cx
int 21h
push dx
push ax
mov bx, ax
sub cx, cx
sub dx, dx
mov ax, 4202h
int 21h
push dx
push ax
sub dx, dx
mov ax, 4200h
int 21h
pop ax
pop dx
mov word ptr cx,ax
pop ax
pop dx
push ax
push ds
push si
mov si,9000h
mov ds,si
mov dx,0000h
mov bx,ax
mov ah,3Fh
int 21h
pop si
pop ds
pop ax
add cx,0000h
mov [ds:1212h],cx
pop dx
pop cx
pop bx
pop ax
push bx
mov bh,[ds:1223h]
cmp bh,00h
jne Rr3
pop bx
jmp write_binchar
Rr3:
cmp bh,01h
jne Rr2
pop bx
jmp write_hexchar
Rr2:
pop bx
jmp read_keyboard
ret
read_file endp

;----------------------------------------------------------------------------
exit proc
call set_video
int 20h
ret
exit endp

;----------------------------------------------------------------------------
upp db '…ЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌ B i n a r y   E d i t o r  v1.66 ЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌї',0
dwn db '»ЌЌЌЌЌM:[   ]ЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌЌY:[01]ЌЌЌЌЌX:[02]ЌЌЌЌЌЌЌЉ',0
bok db 'Ї',0
modabin db 'BIN',0
modahex db 'HEX',0

progg ends
end startup

