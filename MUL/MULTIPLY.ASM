.model tiny
assume cs:progg

progg segment
org 100h

main proc
mov bh,00h
mov [ds:2012h],bh
mov bx,0002h
mov [ds:3032h],bx
mov bx,001ah
mov [ds:3042h],bx
call set_vid
call get_char
;mov word ptr [ds:1102h],0CC88h
call cnt_char
call prnt_code
call exit
ret
main endp

set_vid proc
mov ah,00h
mov al,13h
int 10h
ret
set_vid endp

get_char proc
push ax
push bx
push dx
mov ah,0ah
mov word ptr [ds:1100h],0FFFFh
mov bx,1100h
mov dx,bx
int 21h
pop dx
pop bx
pop ax
ret
get_char endp

cnt_char proc
mov ch,00h
sled:
mov bx,1102h
add bl,ch
mov dh,[ds:bx]
cmp dh,0Dh
jnz nekt
mov [ds:4010h],ch
call endd
nekt:
add ch,01h
jmp sled
endd:
call prnt_code
ret
cnt_char endp

prnt_code proc
mov bh,05h
mov [ds:2010h],bh
push dx
push cx
call draw_pix
pop cx
pop dx
mov dl,00h
mov byte ptr [ds:3010h],00h
gogogo:
mov dl,[ds:3010h]
mov bx,1102h
add bl,[ds:4010h]
sub bl,01h
sub bl,dl
mov ah,[ds:bx]
and ah,80h
mov ch,[ds:bx]
shl ch,01h
mov [ds:bx],ch
cmp ah,80h
jnz neeks
mov bh,0fh
mov [ds:2010h],bh
push dx
push cx
call draw_pix
push cx
pop dx
neeks:
cmp ah,00h
jnz entt
mov bh,00h
mov [ds:2010h],bh
push dx
push cx
call draw_pix
pop cx
pop dx
entt:
mov ch,[ds:2012h]
add ch,01h
mov [ds:2012h],ch
cmp ch,08h
jnz gogogo
mov dl,[ds:3010h]
add dl,01h
mov [ds:3010h],dl
mov byte ptr [ds:2012h],00h
cmp dl,[ds:4010h]
jb gogogo
mov bh,05h
mov [ds:2010h],bh
call draw_pix
call exit
ret
prnt_code endp

pos_pix proc
mov ah,02h
sub bh,bh
mov dh,[ds:3032h]
mov dl,[ds:3042h]
int 10h
ret
pos_pix endp

draw_pix proc
mov cx,[ds:3032h]
mov dx,[ds:3042h]
newnew:
mov ah,0ch
mov al,[ds:2010h]
int 10h
add dx,01h
cmp dx,32h
jna newnew
add cx,01h
mov [ds:3032h],cx
mov word ptr [ds:3042h],001ah
ret
draw_pix endp

exit proc
int 20h
ret
exit endp

progg ends
END MAIN



