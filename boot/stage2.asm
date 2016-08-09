[BITS 16]
[ORG 0x500]

; Save the boot disk for the kernel
mov [bootDisk], dl

mov edi, 0x5000
mov [mmaps], edi
call readMemoryMaps

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
	mov edx, 0x0534d4150	    ; "SMAP"
	mov eax, 0xe820
	mov [es:di + 20], dword 1	; ACPI bitfield backward compatibility.
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

BootData:
  bootDisk    db 0
  mmaps       dd 0
  mmapsCount  dw  0

unsupported DB "Your sistem is way too old for NOS", 0
