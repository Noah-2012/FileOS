section .multiboot_header
align 8

    dd 0xE85250D6
    dd 0x00000000
    dd 0x00000018
    dd 0x17ADAF12

    dw 0
    dw 0
    dd 8

header_end:
