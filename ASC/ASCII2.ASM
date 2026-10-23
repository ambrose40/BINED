.model tiny
assume cs:progg

progg segment
org 100h

;----------------------------------------------------------------------------
startup proc
call byte_write
call save_file
call exit
ret
startup endp

;----------------------------------------------------------------------------
byte_write proc
mov bx,1400h
mov cl,00h;[ds:702h]
cont:
mov byte ptr [bx],cl
inc bx
push cx
call hun_write
pop cx
inc bx
push cx
call hex_dec_write
pop cx
inc bx
mov byte ptr [bx],0Dh
inc bx
mov byte ptr [bx],0Ah
;inc bx
;inc cx
cmp cx,0100h
je endd
inc bx
inc cx
jmp cont
endd:
ret
byte_write endp

;----------------------------------------------------------------------------
hun_write proc
mov byte ptr [bx],20h
cmp cl,200d
jb skip2
inc bx
mov byte ptr [bx],32h
sub cl,200d
jmp toenda
skip2:
cmp cl,100d
jb skip1
inc bx
mov byte ptr [bx],31h
sub cl,100d
jmp toenda
skip1:
cmp cl,000d
jb toenda
inc bx
mov byte ptr [bx],30h
toenda:
call dec_write
ret
hun_write endp

;----------------------------------------------------------------------------
hex_dec_write proc
mov byte ptr [bx],20h
cmp cl,0F0h
jb skipaFh
inc bx  
mov byte ptr [bx],70d
sub cl,0F0h
jmp toendh
skipaFh:
cmp cl,0E0h
jb skipaEh
inc bx  
mov byte ptr [bx],69d
sub cl,0E0h
jmp toendh
skipaEh:
cmp cl,0D0h
jb skipaDh
inc bx  
mov byte ptr [bx],68d
sub cl,0D0h
jmp toendh
skipaDh:
cmp cl,0C0h
jb skipaCh
inc bx  
mov byte ptr [bx],67d
sub cl,0C0h
jmp toendh
skipaCh:
cmp cl,0B0h
jb skipaBh
inc bx  
mov byte ptr [bx],66d
sub cl,0B0h
jmp toendh
skipaBh:
cmp cl,0A0h
jb skipaAh
inc bx  
mov byte ptr [bx],65d
sub cl,0A0h
jmp toendh
skipaAh:
cmp cl,090h
jb skipa9h
inc bx
mov byte ptr [bx],39h
sub cl,090h
jmp toendh
skipa9h:
cmp cl,080h
jb skipa8h
inc bx
mov byte ptr [bx],38h
sub cl,080h
jmp toendh
skipa8h:
cmp cl,070h
jb skipa7h
inc bx
mov byte ptr [bx],37h
sub cl,070h
jmp toendh
skipa7h:
cmp cl,060h
jb skipa6h
inc bx
mov byte ptr [bx],36h
sub cl,060h
jmp toendh
skipa6h:
cmp cl,050h
jb skipa5h
inc bx
mov byte ptr [bx],35h
sub cl,050h
jmp toendh
skipa5h:
cmp cl,040h
jb skipa4h
inc bx
mov byte ptr [bx],34h
sub cl,040h
jmp toendh
skipa4h:
cmp cl,030h
jb skipa3h
inc bx
mov byte ptr [bx],33h
sub cl,030h
jmp toendh
skipa3h:
cmp cl,020h
jb skipa2h
inc bx
mov byte ptr [bx],32h
sub cl,020h
jmp toendh
skipa2h:
cmp cl,010h
jb skipa1h
inc bx
mov byte ptr [bx],31h
sub cl,010h
jmp toendh
skipa1h:
cmp cl,00h
jb toendh
inc bx
mov byte ptr [bx],30h
sub cl,00h
toendh:
call hex_num_write
ret
hex_dec_write endp

;----------------------------------------------------------------------------
dec_write proc
cmp cl,90d
jb skipa9
inc bx  
mov byte ptr [bx],39h
sub cl,90d
jmp toend
skipa9:
cmp cl,80d
jb skipa8
inc bx
mov byte ptr [bx],38h
sub cl,80d
jmp toend
skipa8:
cmp cl,70d
jb skipa7
inc bx
mov byte ptr [bx],37h
sub cl,70d
jmp toend
skipa7:
cmp cl,60d
jb skipa6
inc bx
mov byte ptr [bx],36h
sub cl,60d
jmp toend
skipa6:
cmp cl,50d
jb skipa5
inc bx
mov byte ptr [bx],35h
sub cl,50d
jmp toend
skipa5:
cmp cl,40d
jb skipa4
inc bx
mov byte ptr [bx],34h
sub cl,40d
jmp toend
skipa4:
cmp cl,30d
jb skipa3
inc bx
mov byte ptr [bx],33h
sub cl,30d
jmp toend
skipa3:
cmp cl,20d
jb skipa2
inc bx
mov byte ptr [bx],32h
sub cl,20d
jmp toend
skipa2:
cmp cl,10d
jb skipa1
inc bx
mov byte ptr [bx],31h
sub cl,10d
jmp toend
skipa1:
cmp cl,00d
jb toend
inc bx
mov byte ptr [bx],30h
sub cl,00d
toend:
call num_write
ret
dec_write endp

;----------------------------------------------------------------------------
hex_num_write proc
cmp cl,0Fh
jb skipbFh
inc bx  
mov byte ptr [bx],70d
sub cl,0Fh
jmp toendbh
skipbFh:
cmp cl,0Eh
jb skipbEh
inc bx  
mov byte ptr [bx],69d
sub cl,0Eh
jmp toendbh
skipbEh:
cmp cl,0Dh
jb skipbDh
inc bx  
mov byte ptr [bx],68d
sub cl,0Dh
jmp toendbh
skipbDh:
cmp cl,0Ch
jb skipbCh
inc bx  
mov byte ptr [bx],67d
sub cl,0Ch
jmp toendbh
skipbCh:
cmp cl,0Bh
jb skipbBh
inc bx  
mov byte ptr [bx],66d
sub cl,0Bh
jmp toendbh
skipbBh:
cmp cl,0Ah
jb skipbAh
inc bx  
mov byte ptr [bx],65d
sub cl,0Ah
jmp toendbh
skipbAh:
cmp cl,09h
jb skipb9h
inc bx  
mov byte ptr [bx],39h
sub cl,09h
jmp toendbh
skipb9h:
cmp cl,08h
jb skipb8h
inc bx
mov byte ptr [bx],38h
sub cl,08h
jmp toendbh
skipb8h:
cmp cl,07h
jb skipb7h
inc bx
mov byte ptr [bx],37h
sub cl,07h
jmp toendbh
skipb7h:
cmp cl,06h
jb skipb6h
inc bx
mov byte ptr [bx],36h
sub cl,06h
jmp toendbh
skipb6h:
cmp cl,05h
jb skipb5h
inc bx
mov byte ptr [bx],35h
sub cl,05h
jmp toendbh
skipb5h:
cmp cl,04h
jb skipb4h
inc bx
mov byte ptr [bx],34h
sub cl,04h
jmp toendbh
skipb4h:
cmp cl,03h
jb skipb3h
inc bx
mov byte ptr [bx],33h
sub cl,03h
jmp toendbh
skipb3h:
cmp cl,02h
jb skipb2h
inc bx
mov byte ptr [bx],32h
sub cl,02h
jmp toendbh
skipb2h:
cmp cl,01h
jb skipb1h
inc bx
mov byte ptr [bx],31h
sub cl,01h
jmp toendbh
skipb1h:
cmp cl,00h
jb toendbh
inc bx
mov byte ptr [bx],30h
sub cl,00h
toendbh:
ret
hex_num_write endp

;----------------------------------------------------------------------------
num_write proc
cmp cl,9d
jb skipb9
inc bx  
mov byte ptr [bx],39h
sub cl,9d
jmp toendb
skipb9:
cmp cl,8d
jb skipb8
inc bx
mov byte ptr [bx],38h
sub cl,8d
jmp toendb
skipb8:
cmp cl,7d
jb skipb7
inc bx
mov byte ptr [bx],37h
sub cl,7d
jmp toendb
skipb7:
cmp cl,6d
jb skipb6
inc bx
mov byte ptr [bx],36h
sub cl,6d
jmp toendb
skipb6:
cmp cl,5d
jb skipb5
inc bx
mov byte ptr [bx],35h
sub cl,5d
jmp toendb
skipb5:
cmp cl,4d
jb skipb4
inc bx
mov byte ptr [bx],34h
sub cl,4d
jmp toendb
skipb4:
cmp cl,3d
jb skipb3
inc bx
mov byte ptr [bx],33h
sub cl,3d
jmp toendb
skipb3:
cmp cl,2d
jb skipb2
inc bx
mov byte ptr [bx],32h
sub cl,2d
jmp toendb
skipb2:
cmp cl,1d
jb skipb1
inc bx
mov byte ptr [bx],31h
sub cl,1d
jmp toendb
skipb1:
cmp cl,0d
jb toendb
inc bx
mov byte ptr [bx],30h
sub cl,0d
toendb:
ret
num_write endp

;----------------------------------------------------------------------------
save_file proc
lea dx,filename
mov ah,3Ch
xor cx,cx
int 21h
push bx
mov bx,0A00h
mov dx,1400h
mov cx,bx
pop bx
push bx
mov bx,ax
mov ah,40h
int 21h
pop bx
ret
save_file endp

;----------------------------------------------------------------------------
exit proc
int 20h
ret
exit endp

filename db 'ascii.txt',0

progg ends
end startup
