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
	mov dl, [bootDisk]
	mov si, dap

	int 0x13

	mov si, diskerror
	jc error

	popa
	ret

; Disk Address Packet for INT13 functions
dap:
	            db 0x10
	            db 0
	readCount   dw 0
	readOffset  dw 0
	readSegment dw 0
	readLBA     dd 0
	readLBA2    dd 0
