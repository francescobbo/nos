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
