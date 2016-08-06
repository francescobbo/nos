[BITS 16]
[ORG 0x600]

mov bx, 0xb800
mov es, bx

; Just to know we're there
xor bx, bx
mov [es:bx], byte '.'
mov [es:bx + 1], byte 0x40

cli
hlt
