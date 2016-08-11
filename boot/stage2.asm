[BITS 16]
[ORG 0x500]

; Save the boot disk for the kernel
mov [bootDisk], dl

; Load the memory maps
mov edi, 0x1000
mov [mmaps], edi
call readMemoryMaps

; Enter Unreal Mode to load the Kernel
call getUnreal

; Load the Kernel
call loadKernel

jmp boot32

; Load 4gb segment in DS, while still in Real Mode
; Requires a switch to protected mode.
getUnreal:
	cli
	push ds

	; Load Protected Mode GDT
	lgdt [unrealGDTRegister]

	; Jump into Protected Mode
	mov eax, cr0
	or al, 1
	mov cr0, eax

	jmp .reload

.reload:
	; Load DS with new Descriptor from PM
	mov bx, 0x08
	mov ds, bx

	; Back to Real Mode
	and al, 0xFE
	mov cr0, eax

	; Restore DS (this will keep the Protected Mode Limit!)
	pop ds
	sti
	ret

firstKernelSector  DD 0
kernelSize         DD 0

currentSection     DW 0
remainingSections  DW 0

loadKernel:
	call findKernel

	mov edi, 0x2000
	mov ecx, 1
	mov ebx, [firstKernelSector]
	call readSectors

	mov si, diskerror

	; Check ELF magic
	mov eax, [di]
	cmp eax, 0x464c457f
	jne error

	; Check ELF flags
	mov eax, [di + 4]
	cmp eax, 0x00010102
	jne error

	; More flags
	mov eax, [di + 16]
	cmp eax, 0x003e0002
	jne error

	; Assume that the program header table follows the ELF header and that it fits
	; in the first 512-byte sector containing the ELF header.
	;
	; This may obviously change in the future, but it's a nice assumption that
	; makes things fast and easy.

	mov eax, [di + 32]
	cmp eax, 0x40
	jne error

	; No more than 8 program headers in one sector
	mov cx, [di + 56]
	cmp cx, 8
	jg error

	add di, 0x40
	mov [currentSection], di

.nextSection:
	mov [remainingSections], cx
	call loadSection

	mov bx, [currentSection]
	add bx, 56
	mov [currentSection], bx

	mov cx, [remainingSections]
	loop .nextSection

	ret

sectionSize        DD 0
sectionSector      DD 0
sectionTarget      DD 0

loadSection:
	mov bx, [currentSection]

	; If type != 1 (load), ignore
	mov eax, [bx]
	cmp eax, 1
	je .continue
	ret

.continue:
	; memset(p_paddr, 0, p_memsz)
	mov eax, [bx + 40]
	push eax
	mov eax, 0
	push eax
	mov eax, [bx + 24]
	push eax
	call memset
	add sp, 12

	mov eax, [bx + 32]
	mov [sectionSize], eax

	; SectionSector = p_offset / 512 + firstKernelSector
	mov eax, [bx + 8]
	xor edx, edx
	mov ecx, 512
	div ecx
	add eax, [firstKernelSector]
	mov [sectionSector], eax

	; SectionTarget = p_paddr
	mov eax, [edi + 24]
	mov [sectionTarget], eax

	mov ebx, [sectionSector]
.load:
	mov ecx, 1
	mov edi, 0x6000
	call readSectors

	; memcpy(SectionTarget, 0x6000, 512)
	mov eax, 512
	push eax
	mov eax, 0x6000
	push eax
	mov eax, [sectionTarget]
	push eax
	call memcpy
	add sp, 12

	; target += 512
	mov eax, [sectionTarget]
	add eax, 512
	mov [sectionTarget], eax

	; size -= 512
	mov ecx, [sectionSize]
	sub ecx, 512
	mov [sectionSize], ecx

	; sector++
	inc ebx

	cmp ecx, 0
	jg .load

	ret

findKernel:
	pusha

	mov edi, 0x2000
	mov cx, 1
	mov ebx, 1
	call readSectors

	mov ebx, 0x2000
	mov ebx, [ebx]
	add ebx, 2

	mov ecx, ebx
	add ecx, 1
	mov [firstKernelSector], ecx

	mov cx, 1
	mov edi, 0x2000
	call readSectors

	mov eax, 0x2000
	mov eax, [eax]
	mov ecx, 512
	mul ecx
	mov [kernelSize], eax

	popa
	ret

%include 'io.asm'
%include 'memorymaps.asm'
%include 'utils.asm'
%include 'errors.asm'

boot32:
	; Disable interrupts
	cli

	; Load a protected mode GDT
	lgdt [protectedGDTRegister]

	; Enter protected mode
	mov eax, cr0
	or al, 1
	mov cr0, eax

	; Reload CS
	jmp 0x08:protectedMode

[BITS 32]
protectedMode:
	; Enable PAE, required for Long Mode
	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax

	; Set Long Mode bit. Note that we're in Protected Mode until paging is enabled.
	mov ecx, 0xC0000080
	rdmsr
	or eax, 1 << 8
	wrmsr

	; Enable Paging and Long Mode
	mov eax, cr0
	or eax, 1 << 31
	mov cr0, eax

	; We're now in IA32e mode. The 32bit submode of Long Mode
	lgdt [longGDTRegister]
	jmp 0x08:longMode

[BITS 64]
longMode:
	; Reload data segment registers
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	hlt

align 4
unrealGDTRegister:
	dw unrealGDTEnd - unrealGDT - 1
	dd unrealGDT

align 4
unrealGDT:
	dd 0, 0
	dw 0xffff, 0, 0x9200, 0x00CF
unrealGDTEnd:

align 4
protectedGDTRegister:
	dw protectedGDTEnd - protectedGDT - 1
	dd protectedGDT

align 4
protectedGDT:
	dd 0, 0
	dw 0xffff, 0, 0x9A00, 0x00CF
	dw 0xffff, 0, 0x9200, 0x00CF
protectedGDTEnd:

align 4
longGDTRegister:
	dw longGDTEnd - longGDT - 1
	dq longGDT

longGDT:
	dd 0, 0
	dw 0, 0, 0x9A, 0x0020
	dw 0, 0, 0x92, 0
longGDTEnd:

align 4
BootData:
	bootDisk    db 0
	mmaps       dd 0
	mmapsCount  dw 0
