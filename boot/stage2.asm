[BITS 16]
[ORG 0x500]

; Save the boot disk for the kernel
mov [bootDisk], dl

; Load the memory maps
mov edi, 0x5000
mov [mmaps], edi
call readMemoryMaps

; Enter Unreal Mode to load the Kernel
call getUnreal

; Load the Kernel
call loadKernel

cli
hlt

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

; Load 4gb segment in DS, while still in Real Mode
; Requires a switch to protected mode.
getUnreal:
	cli
	push ds

	; Load Protected Mode GDT
	lgdt [gdtinfo]

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

loadKernel:
	call findKernel

	mov edi, 0x4000
	mov ecx, 1
	mov ebx, [firstKernelSector]
	call readSectors

	mov si, diskerror

	; Check ELF magic
	mov eax, [edi]
	cmp eax, 0x464c457f
	jne error

	; Check ELF flags
	mov eax, [edi + 4]
	cmp eax, 0x00010102
	jne error

	; More flags
	mov eax, [edi + 16]
	cmp eax, 0x003e0002
	jne error



	cli
	hlt

findKernel:
	pusha

	mov edi, 0x4000
	mov cx, 1
	mov ebx, 1
	call readSectors

	mov ebx, 0x4000
	mov ebx, [ebx]
	add ebx, 2

	mov ecx, ebx
	add ecx, 1
	mov [firstKernelSector], ecx

	mov cx, 1
	mov edi, 0x4000
	call readSectors

	mov eax, 0x4000
	mov eax, [eax]
	mov ecx, 512
	mul ecx
	mov [kernelSize], eax

	popa
	ret

; In:
;   EDI: Segment/Offset of destination
;   EBX: LBA of first sector to read
;   CX: sectors count (no more than 127)
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

readMemoryMaps:
	xor bp, bp

	; INT 15
	; In:
	;   EDX = "SMAP"
	;   EAX = 0xE820
	;   EBX = Pagination link (0 on first call)
	;   ECX = 24 (how many bytes to use in the response)
	;   ES:DI = Pointer to destination
	;   The dword in bytes 20-23 is the ACPI 3 Extended Attribute bitfield.
	;   Old firmwares may actually write only 20 bytes. Since the ACPI 3 bitfield,
	;   is used to determine whether the entry should be ignored or not, set that
	;   to 1. If the firmware actually uses 24 bytes, it will replace it during
	;   the INT call.
	; Out:
	;   Carry set on error
	;   EAX = "SMAP" on success
	;   CX = actual bytes written (may be 20 or 24 - or 0 for some invalid entries)
	;   EBX = next pagination link (0 when the list is over)
	mov edx, 0x0534d4150       ; "SMAP"
	mov eax, 0xe820
	mov [es:di + 20], dword 1  ; ACPI bitfield backward compatibility.
	mov ecx, 24
	xor ebx, ebx

	int 0x15
	jc .failed

	mov edx, 0x0534D4150
	cmp eax, edx
	jne .failed

	; ebx = 0 implies list is only 1 entry long and thus unusable
	test ebx, ebx
	je .failed

	jmp .entry

.loop:
	mov eax, 0xe820
	mov [es:di + 20], dword 1
	mov ecx, 24
	mov edx, 0x0534D4150

	int 0x15
	jc .done		; carry set means "end of list already reached"

.entry:
	; Ignore entry if CX is 0
	jcxz .skipEntry

	; Short replies (20 bytes) need some lifting
	cmp cl, 20		; got a 24 byte ACPI 3.X response?
	jbe .shortEntry

	; Extended replies (24 bytes) may be ignored if firmware asks so in ACPI bitfield.
	test byte [es:di + 20], 1
	je .skipEntry

.shortEntry:
	; Entries have an 8-byte 'length' field. If it's 0, it's worthless
	mov ecx, [es:di + 8]
	or ecx, [es:di + 12]
	jz .skipEntry

	; This was a good entry. Increment counter and go on.
	inc bp
	add di, 24

; Also used for normal "continue"
.skipEntry:
	; When EBX is 0 we're done
	test ebx, ebx
	jne .loop

.done:
	; Save the pointer and count for the kernel
	mov [mmapsCount], bp
	ret

.failed:
	mov si, unsupported
	jmp error

; Disk Address Packet for INT13 functions
dap:
	            db 0x10
	            db 0
	readCount   dw 0
	readOffset  dw 0
	readSegment dw 0
	readLBA     dd 0
	readLBA2    dd 0

diskerror DB "Error while pumping the N2O", 0
unsupported DB "Your sistem is way too old for NOS", 0

firstKernelSector DD 0
kernelSize DD 0

gdtinfo:
	dw gdt_end - gdt - 1
	dd gdt

gdt:
	dd 0, 0
	dw 0xffff, 0, 0x9200, 0x00CF
gdt_end:

BootData:
	bootDisk    db 0
	mmaps       dd 0
	mmapsCount  dw 0
