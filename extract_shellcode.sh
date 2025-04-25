#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <Mach-O binary>"
    exit 1
fi

INPUT="$1"
RAW="shellcode.raw"
FORMATTED="shellcode.txt"

echo "[*] Extracting .text section from: $INPUT"
llvm-objcopy --dump-section __TEXT,__text="$RAW" "$INPUT"
if [[ $? -ne 0 ]]; then
    echo "[!] Failed to extract .text section"
    exit 1
fi

echo "[*] Formatting shellcode..."
xxd -p "$RAW" | tr -d '\n' | sed 's/../\\x&/g' > "$FORMATTED"

echo "[*] Shellcode written to: $FORMATTED"
