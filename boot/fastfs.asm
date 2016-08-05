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

	; Read sector 1 to 0x0000:0600
	mov edi, 0x00000600
	mov ebx, 1
	mov cx, 1
	call readSectors

	cli
	hlt

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
