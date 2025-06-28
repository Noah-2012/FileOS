### FileOS Makefile ###

## Paths for Debian/Ubuntu ##
#GCC = $(HOME)/opt/cross/bin/x86_64-elf-gcc
#AS = $(HOME)/opt/cross/bin/x86_64-elf-as
#LD = $(HOME)/opt/cross/bin/x86_64-elf-ld
#OBJCOPY = $(HOME)/opt/cross/bin/x86_64-elf-objcopy

## Paths for Arch Linux (brew) ##
GCC = /home/linuxbrew/.linuxbrew/Cellar/x86_64-elf-gcc/15.1.0/bin/x86_64-elf-gcc
AS = /home/linuxbrew/.linuxbrew/Cellar/x86_64-elf-binutils/2.44/bin/x86_64-elf-as
LD = /home/linuxbrew/.linuxbrew/Cellar/x86_64-elf-binutils/2.44/bin/x86_64-elf-ld
OBJCOPY = /home/linuxbrew/.linuxbrew/Cellar/x86_64-elf-binutils/2.44/bin/x86_64-elf-objcopy

BOOT = boot
KERNEL = kernel
OSNAME = fileos

.PHONY: all clean

all:
	@$(AS) $(BOOT).s -o $(BOOT).o
	@echo Created $(BOOT).o succesfully
	@./check.sh $(KERNEL) --phase-1
	@$(GCC) -c $(KERNEL).c -o $(KERNEL).o -ffreestanding -fno-builtin -Wall -Wextra -nostdlib -m64 -I. -I$(shell dirname $(shell $(CC) -print-libgcc-file-name))/include
	@echo Compiled $(KERNEL).c succesfully
	
	@./linker.sh $(LD) $(KERNEL) $(BOOT) $(OBJCOPY) $(MULTIBOOT_HEADER)
	@./check.sh $(KERNEL) $(OSNAME) $(BOOT) --phase-2

iso:
	#sudo umount /media/noadsch12/'USB DRIVE'
	@echo "--- Contents of $(OSNAME) directory before grub-mkrescue ---"
	@ls -R $(OSNAME) # Zeigt den Inhalt des fileos-Verzeichnisses rekursiv an
	@echo "---------------------------------------------------------"
	@grub-mkrescue -o $(OSNAME).iso $(OSNAME)
	#sudo dd if=$(OSNAME).iso of=/dev/sda1 bs=4M status=progress
	#sync
	
qemu: all iso
	@echo ">>> Starting QEMU with ISO and serial output (64-bit)..."
	@qemu-system-x86_64 -cdrom $(OSNAME).iso -m 128M -no-reboot -serial stdio -d guest_errors

clean:
	@rm -f $(BOOT).o
	@rm -f $(KERNEL).o
	@rm -f $(MULTIBOOT_HEADER).o
	@rm -f $(KERNEL).elf
	@if [ -f $(OSNAME)/boot/success.flag ]; then \
		rm -f $(OSNAME)/boot/$(KERNEL).bin; \
		rm -f $(OSNAME)/boot/success.flag; \
	else \
		rm -f $(KERNEL).bin; \
	fi
	@rm -f $(OSNAME).iso
