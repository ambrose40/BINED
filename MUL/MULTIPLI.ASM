.model tiny
assume cs:progg

progg segment
org 100h

main proc
call set_vid
mov dx,offset messagenumber1
call print_message
mov bx,1100h
call get_first_number
mov dx,offset messagenumber2
call print_message
mov bx,1300h
call get_first_number
mov dx, offset cls
call print_message
mov bx,1100h
call print_numbers
mov bx,1300h
call print_numbers
call exit
ret
main endp

set_vid proc
mov ah,00h
mov al,03h
int 10h
ret
set_vid endp

print_numbers proc
mov ax,0000h
inc bx
mov byte ptr al,[bx]
add bx,ax
inc bx
mov byte ptr [bx],0Dh
inc bx
mov byte ptr [bx],0Ah
inc bx
mov byte ptr [bx],24h
mov dx,bx
sub dx,ax
sub dx,02h
call print_message
ret
print_numbers endp

get_first_number proc
get_first_number_jmp:
push bx
mov ah,0Ah
mov byte ptr [bx],0FFh
mov dx,bx
int 21h
mov dx,0000h
mov cx,0000h
inc bx
mov byte ptr dl,[bx]
add dx,bx
next_char:
inc bx
mov byte ptr cl,[bx]
cmp cx,30h
jb out_to
cmp cx,39h
ja out_to
jmp test_end_string
out_to:
mov dx,offset messagenondecimal
call print_message
pop bx
jmp get_first_number_jmp
test_end_string:
cmp bx,dx
jae end_string
jmp next_char
end_string:
pop bx
ret
get_first_number endp

print_message proc
push ax
push bx
mov al,24h
mov ah,09h
int 21h
pop bx
pop ax
ret
print_message endp


exit proc
int 20h
ret
exit endp

messagenumber1 db 'Enter first number in decimal digits: ', 0Dh, 0Ah, 24h
messagenumber2 db 'Enter second number in decimal digits: ', 0Dh, 0Ah, 24h
messagenondecimal db 'Non-decimal characters detected, Please retry.', 0Dh, 0Ah, 24h
cls db '                                                                                                                                                                                                                                          ',0Dh,0Ah,24h
progg ends
END MAIN



