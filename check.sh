echo
echo "\033[1;3;35m==============="
echo " Mutliboot CLI "
echo "===============\033[0m"

sleep 1

tmp=0

check_syntax_and_grub()
{
  if [ $# -lt 3 ]; then
    echo "\033[31mUsage: $0 <kernelname> <os-folder> <asm-filename-base>\033[0m"
    exit 1
  fi

  if ! command -v grub-file > /dev/null 2>&1; then
    echo "\033[31mERROR: grub-file not found. Please install GRUB tools.\033[0m"
    exit 2
  fi
}

check_mb_s()
{
  if grep -q ".multiboot" $1.s; then
    echo "\033[32mINFO: found .multiboot Section\033[0m"
    tmp=1
  else
    echo "\033[31mERROR: did not find .multiboot Section\033[0m"
    tmp=2
  fi

  sleep 1
}

check_mb1()
{
  if grub-file --is-x86-multiboot $1.bin; then
    echo "\033[32mINFO: $1.bin: multiboot (.multiboot) confirmed\033[0m"
    if [ $tmp -ne 2 ]; then
      mv $1.bin $2/boot/$1.bin
      touch "$2/boot/success.flag"
    fi
    if [ $tmp -eq 2 ]; then
      echo "\033[34mthis is an Bug from Multiboot CLI\033[0m"
      echo
      exit 3
    fi
    echo
    exit 0
  else
    echo "\033[31mERROR: $1.bin: the file is not multiboot (.multiboot)\033[0m"
    if [ $tmp -eq 1 ]; then
      echo "\033[34mThis is mostley because "$1.bin" is not i386\033[0m"
    fi
  fi
}

check_mb2()
{
  if grub-file --is-x86-multiboot2 $1.bin; then
    echo "\033[32mINFO: $1.bin: multiboot (.multiboot2) confirmed\033[0m"
    if [ $tmp -ne 2 ]; then
      mv $1.bin $2/boot/$1.bin
      touch "$2/boot/success.flag"
    fi
    if [ $tmp -eq 2 ]; then
      echo "\033[34mthis is an Bug from Multiboot CLI\033[0m"
      echo
      exit 3
    fi
    echo
    exit 0
  else
    echo "\033[31mERROR: $1.bin: the file is not multiboot (.multiboot2)\033[0m"
    if [ $tmp -eq 1 ]; then
      echo "\033[34mPlease check Buildlog in console\033[0m"
    fi
    echo
    exit 4
  fi
}

check_header()
{
  FILE="$1.s"

  if [ ! -f "$FILE" ]; then
    echo "Fehler: Datei '$FILE' nicht gefunden."
    exit 5
  fi

  # Magic: dd mit Wert 0xE85250D6 suchen
  MAGIC=$(grep -E 'dd +0xE85250D6' "$FILE" | awk '{print $2}')

  # Architektur: dd mit Wert 0 (zweiter dd)
  ARCH=$(grep -E 'dd +0x0' "$FILE" | awk 'NR==1{print $2}')

  # Checksum: dd mit negativem Wert, z.B. dd -(...)
  CHECKSUM=$(grep -E 'dd 0x17ADAF12' "$FILE" | awk '{print $2}')


  # Ausgabe
  if [ "$MAGIC" = "0xE85250D6" ]; then
    echo "\033[32mMultiboot2 MAGIC     = $MAGIC\033[0m"
  else
    echo "\033[31mMultiboot2 MAGIC     = $MAGIC\033[0m"
  fi
  if [ "$ARCH" = "0x00000000" ]; then
    echo "\033[32mArchitecture         = $ARCH\033[0m"
  else
    echo "\033[31mArchitecture         = $ARCH\033[0m"
  fi
  if [ "$CHECKSUM" = "0x17ADAF12" ]; then
    echo "\033[32mChecksum             = $CHECKSUM\033[0m"
  else
    echo "\033[31mChecksum             = $CHECKSUM\033[0m"
    exit 6
  fi
}

if [ "$2" = "--phase-1" ]; then
  echo "\033[1mPhase 1: Checking for Values\033[0m"
  check_header $1
  echo
  sleep 1
elif [ "$4" = "--phase-2" ]; then
  echo "\033[1mPhase 2: Checking for multiboot\033[0m"
  check_syntax_and_grub $1 $2 $3
  check_mb_s $3
  check_mb1 $1 $2
  check_mb2 $1 $2
fi
