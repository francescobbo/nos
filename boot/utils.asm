; The following routines may be optimized using two, four or eight byte ops.

; Can't use rep stosb here as it is limited to 16-bit addresses.
memset:
	push bp
	mov bp, sp
	push edi
	push ecx
	push ax

	mov ecx, [bp + 12]
	mov al, [bp + 8]
	mov edi, [bp + 4]

.loop:
	mov [edi], al
	inc edi
	loop .loop

	pop ax
	pop ecx
	pop edi

	mov sp, bp
	pop bp
	ret

; Can't use rep movsb here as it is limited to 16-bit addresses.
memcpy:
	push bp
	mov bp, sp
	push edi
	push esi
	push ecx
	push ax

	mov ecx, [bp + 12]
	mov esi, [bp + 8]
	mov edi, [bp + 4]

.loop:
	mov al, [esi]
	mov [edi], al
	inc edi
	inc esi
	loop .loop

	pop ax
	pop ecx
	pop esi
	pop edi

	mov sp, bp
	pop bp
	ret
