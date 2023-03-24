#!/bin/bash

# Settings
# Available options are rv32i, rv32ic, rv32im, rv32imc
ARCH=rv32i

# some other settings
SH_LOCATION=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
WORK_DIR=$SH_LOCATION/../sim/bin
ASSEMBLER=/class/ece411/software/riscv-tools/bin/riscv32-unknown-elf-gcc
OBJCOPY=/class/ece411/software/riscv-tools/bin/riscv32-unknown-elf-objcopy
OBJDUMP=/class/ece411/software/riscv-tools/bin/riscv32-unknown-elf-objdump

# Command line parameters
IN_FILE=$1
LINK_FILE=$SH_LOCATION/link.ld
START_FILE=$SH_LOCATION/startup.s

# Color for echo
RED='\033[0;31m'
ORG='\033[0;33m'
NC='\033[0m'

# Print usage
if [[ "$#" -lt 1 ]]; then
    echo -e "[INFO]  Compile a C source file or RISC-V assembly file and write a memory file for simulation."
    echo -e "[INFO]  Usage: $0 <asm-file>"
    exit 0
fi

mkdir -p "$WORK_DIR"

# Copy files to temporary directory
cp "$IN_FILE" "$WORK_DIR"

# Testing if assembly file (only detects .s, not .asm)
if [ x"${IN_FILE##*.}" == "xs" ]; then
    START_FILE=""
fi

ELF_FILE="${WORK_DIR}/$(basename "${IN_FILE%.*}").elf"

# Assemble code
"$ASSEMBLER" -mcmodel=medany -static -fno-common -ffreestanding -nostartfiles -march=$ARCH -mabi=ilp32 -Ofast -flto -Wall -Wextra -Wno-unused -T$LINK_FILE $START_FILE "${WORK_DIR}/$(basename $IN_FILE)" -o "$ELF_FILE" -lm -static-libgcc -lgcc -lc -Wl,--no-relax

# Fail if object file doesn't exist or has no memory content
if [[ ! -e "$ELF_FILE" || "$(cat "$ELF_FILE" | wc -c)" -le "1" ]]; then
    echo -e "${RED}[ERROR]${NC} Error assembling $IN_FILE, not generating binary file" >&2
    exit 2
fi

echo -e "[INFO]  Assembled $IN_FILE to $ELF_FILE"

$SH_LOCATION/memory_from_elf.sh $ELF_FILE
