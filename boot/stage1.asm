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
	mov [bootDisk], dl

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
	mov dl, [bootDisk]

	; Jump to stage2
	jmp 0x0:0x500

%include 'io.asm'
%include 'a20.asm'
%include 'errors.asm'

; Drive number
bootDisk db 0

times (510 - ($ - $$)) DB 0
dw 0xaa55
