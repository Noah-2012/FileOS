#!/usr/bin/env bash

# Farbcodes für die Ausgabe
RED='\033[31m'
GREEN='\033[32m'
BLUE='\033[34m'
MAGENTA='\033[1;3;35m'
NC='\033[0m' # No Color

# Header anzeigen
echo
echo -e "${MAGENTA}================"
echo " ELF Linker CLI "
echo "================"
echo -e "${NC}"

# Standardwerte
NO_ELF=false
ERROR_OCCURRED=false

# Argumente verarbeiten
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-elf)
            NO_ELF=true
            shift
            ;;
        *)
            # Die ersten vier nicht-flag Argumente sind unsere Parameter
            if [[ -z "$LD" ]]; then
                LD="$1"
            elif [[ -z "$KERNEL" ]]; then
                KERNEL="$1"
            elif [[ -z "$BOOTLOADER" ]]; then
                BOOTLOADER="$1"
            elif [[ -z "$OBJCOPY" ]]; then
                OBJCOPY="$1"
            fi
            shift
            ;;
    esac
done

# Prüfung auf fehlende Argumente
if [[ -z "$LD" || -z "$KERNEL" || -z "$BOOTLOADER" || -z "$OBJCOPY" ]]; then
    echo -e "${RED}Fehler: Ungültige oder fehlende Argumente.${NC}"
    echo "Aufruf: $0 [--no-elf] <LD> <KERNEL> <BOOTLOADER> <OBJCOPY>"
    exit 8
fi

sleep 1

# Linker-Operationen
if [[ "$NO_ELF" = false ]]; then
    if ! "$LD" -T linker.ld -o "$KERNEL.elf" "$BOOTLOADER.o" "$KERNEL.o"; then
        ERROR_OCCURRED=true
    else
        echo -e "${GREEN}INFO: Binary file built successfully${NC}"

        if ! "$OBJCOPY" -O binary "$KERNEL.elf" "$KERNEL.bin"; then
            ERROR_OCCURRED=true
        else
            echo -e "${GREEN}INFO: Created '$KERNEL.bin' successfully${NC}"
            # Optional: rm "$KERNEL.elf"
        fi
    fi
else
    if ! "$LD" -T ./linker.ld -o "$KERNEL.bin" "$BOOTLOADER.o" "$KERNEL.o"; then
        ERROR_OCCURRED=true
    else
        echo -e "${GREEN}INFO: Created '$KERNEL.bin' successfully${NC}"
    fi
fi

# Abschlussmeldung
if [[ "$ERROR_OCCURRED" = false ]]; then
    echo -e "${BLUE}Linker-Warnungen sind nicht wichtig${NC}"
else
    echo -e "${RED}Fehler während des Link-Vorgangs aufgetreten${NC}"
    exit 7
fi
