echo
echo "\033[1;3;35m================"
echo " ELF Linker CLI "
echo "================\033[0m"

# Standardmäßig: kein --no-elf
NO_ELF=false

# Prüfen, ob das erste Argument --no-elf ist
if [ "$1" = "--no-elf" ]; then
  NO_ELF=true
  shift  # Entfernt $1, sodass $2 wird zu $1 usw.
fi

# Jetzt sind die Argumente wie folgt:
# $1 = LD
# $2 = Kernel
# $3 = Bootloader
# $4 = Objcopy

LD="$1"
KERNEL="$2"
BOOTLOADER="$3"
OBJCOPY="$4"
MULTIBOOT_HEADER="$5"

# Prüfung auf fehlende Argumente
if [ -z "$LD" ] || [ -z "$KERNEL" ] || [ -z "$BOOTLOADER" ] || [ -z "$OBJCOPY" ]; then
  echo "\033[31mFehler: Ungültige oder fehlende Argumente.\033[0m"
  echo "Aufruf: ./linker.sh [--no-elf] <LD> <KERNEL> <BOOTLOADER> <OBJCOPY>"
  exit 1
fi

sleep 1

if [ "$NO_ELF" = false ]; then
  "$LD" -T linker.ld -o "$KERNEL.elf" "$MULTIBOOT_HEADER.o" "$BOOTLOADER.o" "$KERNEL.o"
  echo "\033[32mINFO: Binary file build succesfully\033[0m"
  "$OBJCOPY" -O binary "$KERNEL.elf" "$KERNEL.bin"
  echo "\033[32mINFO: Created '$KERNEL.bin' succesfully\033[0m"
  #rm "$KERNEL.elf"
else
  "$LD" -T ./linker.ld -o "$KERNEL.bin" "$BOOTLOADER.o" "$KERNEL.o"
  echo "\033[32mINFO: Created '$KERNEL.bin' succesfully\033[0m"  
fi

echo "\033[34mLinker-Warnungen sind nicht wichtig\033[0m"

