.code32                 # Start in 32-bit protected mode, as GRUB hands over control here.

.global start           # Define 'start' as the entry point for the linker.
.extern kernel_main     # Declare 'kernel_main' from kernel.c as external.

# Multiboot2 compliant bootloader
# We define the entry point and the initial setup here.
# The Multiboot2 header is defined in kernel.c, so the bootloader itself
# doesn't need to explicitly contain the magic or flags.
# GRUB will load the kernel and jump to 'start'.

start:
    # Disable interrupts
    cli

    # Disable Non-Maskable Interrupts (NMI)
    inb $0x70, %al
    orb $0x80, %al
    outb %al, $0x70
    inb $0x71, %al # dummy read

    # Load Global Descriptor Table (GDT)
    # The GDT is crucial for setting up 64-bit long mode.
    lgdt gdtr_ptr

    # Enable PAE (Physical Address Extension) in CR4
    movl %cr4, %eax
    orl $(1 << 5), %eax
    movl %eax, %cr4

    # Load the PML4 (Page Map Level 4) base address into CR3
    # This is the top-level page table for 64-bit paging.
    movl $pml4_table, %eax
    movl %eax, %cr3

    # Enable Long Mode (LME) in EFER MSR (Model Specific Register)
    # EFER MSR is at address 0xC0000080
    movl $0xC0000080, %ecx  # EFER MSR address
    rdmsr                   # Read MSR into EDX:EAX
    orl $(1 << 8), %eax     # Set LME bit (bit 8)
    wrmsr                   # Write back to MSR

    # Enable Paging in CR0
    movl %cr0, %eax
    orl $(1 << 31), %eax
    movl %eax, %cr0

    # Far jump to clear the instruction pipeline and enter 64-bit mode.
    # The '8' is the code segment selector (offset into GDT).
    ljmp $8, $long_mode_entry

.code64                 # From now on, assemble 64-bit instructions.

long_mode_entry:
    # Set up 64-bit data segments.
    # GRUB loads into 32-bit mode, so segment registers need to be reloaded for 64-bit.
    movw $16, %ax         # Data segment selector (offset 16 into GDT)
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
    movw %ax, %ss         # Stack segment

    # Set up the stack.
    # The stack grows downwards. We place it at the end of our BSS section
    # to avoid overwriting code/data.
    movq $_end, %rsp      # Use _end from linker.ld as the stack base.
    subq $4096, %rsp      # Allocate some space for the stack (e.g., 4KB)

    # Call the C kernel entry point.
    # GRUB passes the Multiboot magic number and info pointer in EAX and EBX.
    # For 64-bit, these will be sign-extended into RAX and RBX.
    # We pass them as arguments to kernel_main.
    movl %eax, %edi     # First argument (magic) goes to RDI
    movl %ebx, %esi     # Second argument (multiboot_info*) goes to RSI
    call kernel_main    # Call the C kernel entry point.

    # If kernel_main returns (it shouldn't in an OS), halt the system.
    .halt_loop:
        cli
        hlt
        jmp .halt_loop

.align 0x1000           # Align page tables to 4KB boundary.

# --- Page Tables ---
# We set up a minimal identity map for the first 4GB.
# This is a flat map: Virtual Address = Physical Address.

# Page Map Level 4 (PML4) Table
pml4_table:
    # First entry points to ptdp_table (Physical Address)
    # The '0x3' are flags: Present (bit 0), Read/Write (bit 1)
    .quad ptdp_table + 0x3

    .fill 511, 8, 0             # Fill the rest of the PML4 with zeros

# Page Directory Pointer Table (PDPT)
ptdp_table:
    # First entry points to pd_table (Physical Address)
    # The '0x3' are flags: Present (bit 0), Read/Write (bit 1)
    .quad pd_table + 0x3

    .fill 511, 8, 0             # Fill the rest of the PDPT with zeros

# Page Directory (PD) Table (for first 2MB)
pd_table:
    # Map the first 2MB (0x0 - 0x1FFFFF) as a single large page.
    # (Physical Address << 21) | Present (bit 0) | Read/Write (bit 1) | Page Size (bit 7)
    # For a 2MB page, the address itself must be 2MB aligned.
    .quad 0x0 + 0x83            # Map 0x0 - 0x1FFFFF, Present, Read/Write, 2MB Page Size

    .fill 511, 8, 0             # Fill the rest of the PD with zeros


# --- Global Descriptor Table (GDT) ---
# A minimal GDT for switching to 64-bit Long Mode.
# GDT entries are 8 bytes each.

.p2align 3              # Align GDT to an 8-byte boundary.

gdt_null:               # Null descriptor
    .quad 0x0

gdt_code:               # 64-bit Code Segment Descriptor
    .word 0x0           # Limit (ignored in 64-bit mode)
    .word 0x0           # Base (ignored in 64-bit mode)
    .byte 0x0           # Base (ignored)
    .byte 0x9A          # Access Byte: Present (1), Privl (00), Type (1010b = Code, Read/Exec)
                        #   Accessed (0), Read/Write (1), Conforming (0)
    .byte 0xA0          # Flags/Limit: Granularity (1 = 4KB), 64-bit mode (1), D/B (0 = 32-bit compat), AVL (0)
    .byte 0x0           # Base (ignored)

gdt_data:               # 64-bit Data Segment Descriptor
    .word 0x0           # Limit (ignored)
    .word 0x0           # Base (ignored)
    .byte 0x0           # Base (ignored)
    .byte 0x92          # Access Byte: Present (1), Privl (00), Type (0010b = Data, Read/Write)
                        #   Accessed (0), Read/Write (1), Expand-down (0)
    .byte 0xA0          # Flags/Limit: Granularity (1 = 4KB), 64-bit mode (1), D/B (0 = 32-bit compat), AVL (0)
    .byte 0x0           # Base (ignored)

# GDTR (Global Descriptor Table Register) pointer.
# This structure tells the CPU where the GDT is and how large it is.
gdtr_ptr:
    .word gdt_end - gdt_null - 1
    .quad gdt_null                  # GDT Base Address

.end
