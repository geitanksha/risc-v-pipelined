#!/bin/bash

# Settings
# Change to 32 for Checkpoint 2 onwards. (For use with caches)
ADDRESSABILITY=1

# some other settings
SH_LOCATION=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
WORK_DIR=$SH_LOCATION/../sim/bin
TARGET_FILE=$SH_LOCATION/../sim/memory.lst
ASSEMBLER=/class/ece411/software/riscv-tools/bin/riscv32-unknown-elf-gcc
OBJCOPY=/class/ece411/software/riscv-tools/bin/riscv32-unknown-elf-objcopy
OBJDUMP=/class/ece411/software/riscv-tools/bin/riscv32-unknown-elf-objdump

ELF_FILE=$1

# Color for echo
RED='\033[0;31m'
ORG='\033[0;33m'
NC='\033[0m'

# Print usage
if [[ "$#" -lt 1 ]]; then
    echo -e "[INFO]  Generate memory.lst from a RISC-V ELF file."
    echo -e "[INFO]  Usage: $0 <elf-file>"
    exit 0
fi

mkdir -p "$WORK_DIR"

BIN_FILE="${WORK_DIR}/$(basename "${ELF_FILE%.*}").bin"
DIS_FILE="${WORK_DIR}/$(basename "${ELF_FILE%.*}").dis"

"$OBJDUMP" -D "$ELF_FILE" -Mnumeric > "$DIS_FILE"
"$OBJCOPY" -O binary "$ELF_FILE" "$BIN_FILE"

# Fail if binary file doesn't exist or has no memory content
if [[ ! -e "$BIN_FILE" || "$(cat "$BIN_FILE" | wc -c)" -le "1" ]]; then
    echo -e "${RED}[ERROR]${NC} Error binarizing $ELF_FILE, not generating memory file >&2"
    exit 3
fi

# Fail if the target directory doesn't exist
if [[ ! -d "$(dirname "$TARGET_FILE")" ]]; then
    echo -e "${RED}[ERROR]${NC} Directory $(dirname "$TARGET_FILE") does not exist. >&2"
    exit 4
fi

if [ -e "$TARGET_FILE" ]; then
    echo -e "${ORG}[WARN]${NC}  Target file $TARGET_FILE exists. Overwriting."
    rm "$TARGET_FILE"
fi

# Write memory to file
function log2 {
    local x=0
    for (( y=$1-1 ; $y > 0; y >>= 1 )) ; do
        let x=$x+1
    done
    echo $x
}

z=$( log2 $ADDRESSABILITY )
hex="0x80000000"
result=$(( hex >> $z ))
mem_start=$(printf "@%08x\n" $result)

{
    echo $mem_start
    hexdump -ve $ADDRESSABILITY'/1 "%02X " "\n"' "$BIN_FILE" \
        | awk '{for (i = NF; i > 0; i--) printf "%s", $i; print ""}'
} > "$TARGET_FILE"

echo -e "[INFO]  Wrote memory contents to $TARGET_FILE"
