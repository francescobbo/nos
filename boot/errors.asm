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

diskerror DB "Error while pumping the N2O", 0
unsupported DB "Your sistem is way too old for NOS", 0
