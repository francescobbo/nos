ENTRY(Entry)

KERNEL_VMA = 0xFFFFFF8002000000;
HIGHER_HALF = 0xFFFFFF8000000000;

SECTIONS
{
    . = KERNEL_VMA;

    .text : AT(ADDR(.text) - HIGHER_HALF)
    {
        _code = .;
        *(.text)
        *(.rodata*)
        . = ALIGN(4096);
    }

   .data : AT(ADDR(.data) - HIGHER_HALF)
   {
        _data = .;
        *(.data)
        . = ALIGN(4096);
   }

   .eh_frame : AT(ADDR(.eh_frame) - HIGHER_HALF)
   {
       _ehframe = .;
       *(.eh_frame)
        . = ALIGN(4096);
   }

   .bss : AT(ADDR(.bss) - HIGHER_HALF)
   {
       _bss = .;
       *(.bss)

        *(COMMON)
       . = ALIGN(4096);
   }

   _end = .;

   /DISCARD/ :
   {
        *(.comment)
   }
}
