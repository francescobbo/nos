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

	call checkLongMode
	call enableA20
	call enableSSE

	; Some BIOSes enable some optimizations when told that the OS will be running
	; in Long Mode (64bit). Most BIOSes will do nothing.
	mov ax, 0xec00
	mov bx, 2
	int 0x15

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

checkLongMode:
	; First of all, check the CPUID instruction existance, by flipping the ID flag
	; in the EFLAGS register. If the flipping does not work (the flag is kept to 0),
	; then, CPUID (and Long Mode) is not available.

	; EAX = EFLAGS
	pushfd
	pop eax

	mov ecx, eax
	xor eax, 1 << 21

	; EFLAGS = EFLAGS ^ (1 << 21)  (the ID flag)
	push eax
	popfd

	; EAX = EFLAGS
	pushfd
	pop eax

	; EFLAGS = ECX (backup of old flags)
	push ecx
	popfd

	mov si, unsupported

	xor eax, ecx
	jz error

	; Check that we can call extended CPUID
	mov eax, 0x80000000
	cpuid
	cmp eax, 0x80000001
	jb error

	; Check long mode presence
	mov eax, 0x80000001
	cpuid
	test edx, 1 << 29
	jz error

	; Great. We have long mode!
	ret

enableSSE:
	mov eax, cr0
	and eax, ~4
	or eax, 2
	mov cr0, eax

	mov eax, cr4
	or eax, 0x600
	mov cr4, eax

	ret

%include 'io.asm'
%include 'a20.asm'
%include 'errors.asm'

; Drive number
bootDisk db 0

times (510 - ($ - $$)) DB 0
dw 0xaa55
