[BITS 16]
[ORG 0x7c00]

jmp 0x0:boot

boot:
	; Cleanup segments
	mov ax, 0
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	; Setup a stack
	mov ss, ax
	mov sp, 0x7c00

	; Save the boot drive number
	mov [drive], dl

	call enableA20

	; Read sector 1 to 0x0000:0600
	mov edi, 0x00000600
	mov ebx, 1
	mov cx, 1
	call readSectors

	; Read #CX sectors at 0x600 starting from LBA 2
	mov edi, 0x00000600
	mov bx, 0x600
	mov cx, [bx]
	mov ebx, 2
	call readSectors

	; Jump to stage2
	jmp 0x0:0x600

; IN:
;   EDI: Segment/Offset of destination
;   EBX: LBA of first sector to read
;		CX: sectors count (no more than 127)
readSectors:
	mov [readCount], cx
	mov [readOffset], edi
	mov [readLBA], ebx
	mov [readLBA2], dword 0

	pusha
	mov ah, 0x42
	mov dl, [drive]
	mov si, dap

	int 0x13
	jc error

	popa
	ret

enableA20:
	call checkA20
	cmp ax, 0
	jz .ok

	jmp error

.ok:
	ret

checkA20:
	pushf
	push ds
	cli

	mov ax, 0xffff
	mov ds, ax

	mov di, 0x500
	mov si, 0x510

	mov [es:di], byte 0x00
	mov [ds:si], byte 0xff

	mov ax, 1

	cmp [es:di], byte 0xff
	je .done

	mov ax, 0

.done:
	pop ds
	popf
	ret

error:
	cli
	hlt

; Drive number
drive db 0

; Disk Address Packet for INT13 functions
dap:
							db 0x10
							db 0
	readCount		dw 0
	readOffset 	dw 0
	readSegment dw 0
	readLBA			dd 0
	readLBA2		dd 0

times (510 - ($ - $$)) DB 0
dw 0xaa55
