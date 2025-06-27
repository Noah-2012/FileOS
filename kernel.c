#include <stdbool.h> // For bool type
#include <stddef.h>  // For size_t
#include <stdint.h>  // For integer types like uint32_t, uint64_t etc.

// --- Multiboot2 Header Definition ---
// This header must be 8-byte aligned
// Place this at the beginning of your kernel.c, after includes.
// This is crucial for GRUB to identify and load your kernel correctly.

#define MULTIBOOT2_HEADER_MAGIC 0xE85250D6
// KORREKT laut offizieller Multiboot2 Specification:
// '0' for i386, '0x10' for x86_64
#define MULTIBOOT_ARCHITECTURE_X86_64 0x10 // KORREKT: 0x10 für x86_64
#define MULTIBOOT_HEADER_TAG_END 0

// Multiboot2 header structure.
__attribute__((section(".multiboot_header")))
__attribute__((aligned(8)))
const struct {
    uint32_t magic;
    uint32_t architecture;
    uint32_t header_length;
    uint32_t checksum;

    // Tags follow the header. For a minimal setup, only the END tag is needed.
    uint16_t type;
    uint16_t flags;
    uint32_t size;
} multiboot2_header = {
    .magic = MULTIBOOT2_HEADER_MAGIC,
    .architecture = MULTIBOOT_ARCHITECTURE_X86_64, // KORREKT: Auf 0x10 setzen
    .header_length = 24,
    // KORREKTE Checksumme basierend auf:
    // Magic (0xE85250D6) + Architecture (0x10) + Header Length (0x18) = 0xE85250FE
    // Checksum = -(0xE85250FE) = 0x17ADAF02
    .checksum = 0x17ADAF02, // KORREKT: Korrigierte Checksumme für Arch 0x10

    // This is the mandatory END tag for the Multiboot2 header
    .type = MULTIBOOT_HEADER_TAG_END,
    .flags = 0,
    .size = 8, // Size of the end tag itself (type + flags + size)
};


// --- Multiboot Information Structure (for passing info from GRUB) ---
// This struct will be pointed to by the 'mbd' parameter in kernel_main.
// It's helpful to define it so you can access GRUB-provided info.
struct multiboot_info {
    uint32_t flags;
    uint32_t mem_lower;
    uint32_t mem_upper;
    uint32_t boot_device;
    uint32_t cmdline;
    uint32_t mods_count;
    uint32_t mods_addr;
    uint32_t syms[3];
    uint32_t mmap_length;
    uint32_t mmap_addr;
    uint32_t drives_length;
    uint32_t drives_addr;
    uint32_t config_table;
    uint32_t boot_loader_name;
    uint32_t apm_table;
    uint32_t vbe_control_info;
    uint32_t vbe_mode_info;
    uint16_t vbe_mode;
    uint16_t vbe_interface_seg;
    uint16_t vbe_interface_off;
    uint16_t vbe_interface_len;

    // Added fields for Multiboot2 framebuffer info if available
    uint64_t framebuffer_addr;
    uint32_t framebuffer_pitch;
    uint32_t framebuffer_width;
    uint32_t framebuffer_height;
    uint8_t  framebuffer_bpp;
    uint8_t  framebuffer_type;
    uint16_t reserved; // Padding

    union {
        struct {
            uint32_t framebuffer_palette_addr;
            uint16_t framebuffer_palette_num_colors;
        };
        struct {
            uint8_t framebuffer_red_field_position;
            uint8_t framebuffer_red_mask_size;
            uint8_t framebuffer_green_field_position;
            uint8_t framebuffer_green_mask_size;
            uint8_t framebuffer_blue_field_position;
            uint8_t framebuffer_blue_mask_size;
        };
    };
};

// --- Basic Serial Port (COM1) I/O Functions ---
// Used for debugging output

#define COM1_PORT 0x3F8

// Function to initialize serial port
void serial_init(void) {
    // Disable interrupts
    __asm__ volatile("outb %0, %w1" : : "a"((uint8_t)0x00), "Nd"((uint16_t)(COM1_PORT + 1)));
    // Enable DLAB (set baud rate divisor)
    __asm__ volatile("outb %0, %w1" : : "a"((uint8_t)0x80), "Nd"((uint16_t)(COM1_PORT + 3)));
    // Set baud rate to 38400 (divisor = 0x01)
    __asm__ volatile("outb %0, %w1" : : "a"((uint8_t)0x01), "Nd"((uint16_t)(COM1_PORT + 0)));
    __asm__ volatile("outb %0, %w1" : : "a"((uint8_t)0x00), "Nd"((uint16_t)(COM1_PORT + 1)));
    // 8N1 (8 data bits, no parity, 1 stop bit)
    __asm__ volatile("outb %0, %w1" : : "a"((uint8_t)0x03), "Nd"((uint16_t)(COM1_PORT + 3)));
    // Enable FIFO, clear them, with 14-byte threshold
    __asm__ volatile("outb %0, %w1" : : "a"((uint8_t)0xC7), "Nd"((uint16_t)(COM1_PORT + 2)));
    // IRQs enabled, RTS/DSR set
    __asm__ volatile("outb %0, %w1" : : "a"((uint8_t)0x0B), "Nd"((uint16_t)(COM1_PORT + 4)));
}

// Function to check if serial transmit buffer is empty
static int serial_is_transmit_empty(void) {
    uint8_t status;
    __asm__ volatile("inb %w1, %0" : "=a"(status) : "Nd"((uint16_t)(COM1_PORT + 5)));
    return status & 0x20;
}

// Function to send a character over serial
void serial_putc(char c) {
    while (!serial_is_transmit_empty()); // Wait until transmit buffer is empty
    __asm__ volatile("outb %0, %w1" : : "a"((uint8_t)c), "Nd"((uint16_t)(COM1_PORT + 0)));
}

// Function to send a string over serial
void serial_puts(const char* s) {
    while (*s) {
        serial_putc(*s++);
    }
}

// Function to print a single hexadecimal nibble
void serial_puthex_nibble(uint8_t nibble) {
    if (nibble < 10) {
        serial_putc('0' + nibble);
    } else {
        serial_putc('A' + (nibble - 10));
    }
}

// Function to print a 32-bit unsigned integer in hex
void serial_puthex(uint32_t n) {
    serial_putc('0');
    serial_putc('x');
    for (int i = 7; i >= 0; i--) {
        serial_puthex_nibble((n >> (i * 4)) & 0xF);
    }
}

// Function to print a 64-bit unsigned integer in hex
void serial_puthex64(uint64_t n) {
    serial_putc('0');
    serial_putc('x');
    for (int i = 15; i >= 0; i--) {
        serial_puthex_nibble((n >> (i * 4)) & 0xF);
    }
}

// --- VGA Text Mode Functions ---
// Basic VGA output for debugging directly on screen (if available)

// The VGA text mode buffer starts at address 0xB8000
volatile uint16_t* vga_buffer = (uint16_t*)0xB8000;
const int VGA_WIDTH = 80;
const int VGA_HEIGHT = 25;

// Function to put a character at specific VGA coordinates
void vga_putc_at(char c, uint8_t color, uint32_t x, uint32_t y) {
    if (x >= VGA_WIDTH || y >= VGA_HEIGHT) {
        return; // Out of bounds
    }
    vga_buffer[y * VGA_WIDTH + x] = (uint16_t)c | ((uint16_t)color << 8);
}

// Function to clear the VGA screen
void vga_clear_screen(void) {
    for (int y = 0; y < VGA_HEIGHT; y++) {
        for (int x = 0; x < VGA_WIDTH; x++) {
            vga_putc_at(' ', 0x0F, x, y); // Space with white on black
        }
    }
}

// Simple vga puts
void vga_puts(const char* s, uint8_t color, uint32_t x, uint32_t y) {
    uint32_t current_x = x;
    uint32_t current_y = y;
    while (*s) {
        if (*s == '\n') {
            current_x = 0;
            current_y++;
        } else {
            vga_putc_at(*s, color, current_x, current_y);
            current_x++;
            if (current_x >= VGA_WIDTH) {
                current_x = 0;
                current_y++;
            }
        }
        if (current_y >= VGA_HEIGHT) {
            current_y = 0; // Wrap around or scroll (simple wrap for now)
        }
        s++;
    }
}


// --- Kernel Main Entry Point ---
// This is the first C function called by your boot.s.
// magic: Multiboot magic number provided by GRUB (0x2BADB002 for Multiboot1, 0x36D76289 for Multiboot2)
// mbd: Pointer to the Multiboot information structure.

void kernel_main(uint32_t magic, struct multiboot_info* mbd) {
    // Initialize serial port for debugging
    serial_init();
    serial_puts("Serial port initialized.\n");

    vga_clear_screen();
    vga_puts("Hello from your 64-bit kernel!\n", 0x0A, 0, 0); // Green on black

    serial_puts("Multiboot Magic: ");
    serial_puthex(magic);
    serial_putc('\n');

    // Check if GRUB passed the correct magic number
    // For Multiboot2, the magic number passed by GRUB is 0x36D76289
    if (magic != 0x36D76289) { // WICHTIG: Die GRUB Multiboot2 Magic Nummer ist 0x36D76289
        serial_puts("ERROR: Invalid Multiboot magic number from GRUB!\n");
        vga_puts("ERROR: Invalid Multiboot magic number!\n", 0x0C, 0, 1); // Red on black
    } else {
        serial_puts("Multiboot magic from GRUB OK.\n");
        vga_puts("Multiboot magic OK.\n", 0x0A, 0, 1); // Green on black
    }

    // You can now access information from the multiboot_info structure (mbd)
    // For example, to check memory:
    if (mbd->flags & (1 << 0)) { // Check if memory info is valid
        serial_puts("Memory: lower=");
        serial_puthex(mbd->mem_lower);
        serial_puts("KB, upper=");
        serial_puthex(mbd->mem_upper);
        serial_puts("KB\n");
    }

    vga_puts("Kernel has started successfully!\n", 0x0F, 0, 3); // White on black

    // Loop indefinitely
    while (true) {
        __asm__ volatile("hlt"); // Halt CPU until next interrupt
    }
}