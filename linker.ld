ENTRY(start)

SECTIONS
{
    /* ----------------------------- */
    /* Virtuelle Startadresse Kernel */
    /* ----------------------------- */
    . = 0x100000;  /* 1 MiB, klassischer GRUB-Startpunkt */

    /* -------------------------------------------- */
    /* Multiboot2 Header muss am File Offset 0 sein */
    /* -------------------------------------------- */
    .multiboot_header ALIGN(8) : AT(0)
    {
        KEEP(*(.multiboot_header))
    }

    /* ----------------------------- */
    /* Code-Segment (.text)         */
    /* ----------------------------- */
    .text ALIGN(0x1000) : AT(ADDR(.multiboot_header) + SIZEOF(.multiboot_header))
    {
        *(.text)
        *(.text.*)
    }

    /* ----------------------------- */
    /* Read-only Daten (.rodata)    */
    /* ----------------------------- */
    .rodata ALIGN(0x1000) :
    {
        *(.rodata)
        *(.rodata.*)
    }

    /* ----------------------------- */
    /* Initialisierte Daten (.data) */
    /* ----------------------------- */
    .data ALIGN(0x1000) :
    {
        *(.data)
        *(.data.*)
    }

    /* ----------------------------- */
    /* Uninitialisierte Daten (.bss)*/
    /* ----------------------------- */
    .bss ALIGN(0x1000) :
    {
        *(.bss)
        *(.bss.*)
        *(COMMON)
    }

    /* ----------------------------- */
    /* Page-Tables (.paging)        */
    /* ----------------------------- */
    .paging ALIGN(0x1000) :
    {
        KEEP(*(.paging))
    }

    /* ----------------------------- */
    /* Global Descriptor Table (.gdt)*/
    /* ----------------------------- */
    .gdt ALIGN(8) :
    {
        KEEP(*(.gdt))
    }

    /* ----------------------------- */
    /* Stack (.stack)               */
    /* ----------------------------- */
    .stack ALIGN(16) :
    {
        stack_bottom = .;
        . = . + 0x4000;  /* 16 KiB Stack */
        stack_top = .;
    }

    /* ----------------------------- */
    /* Kernel-Ende-Symbol (_end)    */
    /* ----------------------------- */
    _end = .;
}
