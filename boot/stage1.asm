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

	; Read sector 1 to 0x0000:0500
	mov edi, 0x00000500
	mov ebx, 1
	mov cx, 1
	call readSectors

	; Read #CX sectors at 0x600 starting from LBA 2
	mov edi, 0x00000500
	mov bx, 0x500
	mov cx, [bx]
	mov ebx, 2
	call readSectors

	; Pass disk number through stage2
	mov dl, [drive]

	; Jump to stage2
	jmp 0x0:0x500

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

	mov si, diskerror
	jc error

	popa
	ret

error:
.repeat:
	mov al, [si]
	inc si

	cmp al, 0
	jz .done

	mov ah, 0x0e
	mov bx, 0xf4
	int 0x10
	jmp .repeat

.done:
	cli
	hlt

enableA20:
	call checkA20
	cmp ax, 0
	jz .ok

	; Try with the BIOS
	mov ax, 0x2401
	int 0x15

	call checkA20
	cmp ax, 0
	jz .ok

	; Try with the Keyboard
	call keyboardA20

	call checkA20
	cmp ax, 0
	jz .ok

	; Try the Fast Gate
	in al, 0x92
	test al, 2
	; Omg already enabled
	jnz .fastDone
	or al, 2
	; Prevent System Reset
	and al, 0xFE
	out 0x92, al
.fastDone:

	call checkA20
	cmp ax, 0
	jz .ok

	mov si, unsupported
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

keyboardA20:
	cli

	; Disable the Keyboard
	call keyboardWait
	mov al, 0xAD
	out 0x64, al

	; Read command
	call keyboardWait
	mov al, 0xD0
	out 0x64, al

	; Read data
	call keyboardWaitIn
	in al, 0x60
	push ax

	; Write command
	call keyboardWait
	mov al, 0xD1
	out 0x64, al

	; Write data (enabling the A20 line)
	call keyboardWait
	pop ax
	or al, 2
	out 0x60, al

	; Reenable the keyboard
	call keyboardWait
	mov al, 0xAE
	out 0x64, al

	call keyboardWait
	sti
	ret

keyboardWait:
	in al, 0x64
	test al, 2
	jnz keyboardWait
	ret

keyboardWaitIn:
	in al, 0x64
	test al, 1
	jz keyboardWaitIn
	ret

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

diskerror DB "Error while pumping the N2O", 0
unsupported DB "Your sistem is way too old for NOS", 0

times (510 - ($ - $$)) DB 0
dw 0xaa55
