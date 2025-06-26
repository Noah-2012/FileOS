MEMORY
{
    HEADER  (rx) : ORIGIN = 0x0, LENGTH = 8K
    KERNEL  (rx) : ORIGIN = 0x100000, LENGTH = 4M
    DATA    (rw) : ORIGIN = 0x104000, LENGTH = 1M
}

SECTIONS
{
    .multiboot_header 0x0 : ALIGN(8)
    {
        KEEP(*(.multiboot_header))
    } > HEADER

    . = 0x100000;

    .text ALIGN(0x1000) :
    {
        *(.text)
        *(.text.*)
    } > KERNEL

    /* ... rest deiner Sektionen ... */

    .rodata ALIGN(0x1000) :
    {
        *(.rodata)
        *(.rodata.*)
    } > KERNEL

    .data ALIGN(0x1000) :
    {
        *(.data)
        *(.data.*)
    } > DATA

    .bss ALIGN(0x1000) :
    {
        *(.bss)
        *(.bss.*)
        *(COMMON)
    } > DATA

    _end = .;
}