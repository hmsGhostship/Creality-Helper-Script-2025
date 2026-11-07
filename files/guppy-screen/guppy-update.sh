#!/bin/sh

# Load central variables from framework
if [ -f /usr/data/helper-script/files/paths.sh ]; then
    source /usr/data/helper-script/files/paths.sh
else
    # Fallback paths if sourced incorrectly
    GUPPY_SCREEN_URL="https://github.com"
    GUPPY_SCREEN_SOURCE="/usr/data/GuppyScreen-K1C-2025"
    GUPPY_SCREEN_FOLDER="/usr/data/guppyscreen"
fi

INITD_FOLDER="/usr/apps/etc/init.d"
GUPPY_SERVICE="$INITD_FOLDER/S57guppy_service"

echo "Checking for native MIPS GuppyScreen updates..."

if [ ! -d "$GUPPY_SCREEN_SOURCE/.git" ]; then
    echo "Source repository not found. Re-cloning layout..."
    rm -rf "$GUPPY_SCREEN_SOURCE"
    git clone --depth 1 "$GUPPY_SCREEN_URL" "$GUPPY_SCREEN_SOURCE"
fi

# Step 1: Fetch latest changes from SnorritxD Fork
cd "$GUPPY_SCREEN_SOURCE"
echo "Fetching changes from GitHub..."
git fetch origin main

# Check if we actually need an update
LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse origin/main)

if [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
    echo "GuppyScreen for K1C 2025/2026 is already up to date!"
    exit 0
fi

echo "New update detected! Pulling latest source code..."
git pull origin main

# Step 2: Backup user settings before overwrite
if [ -f "$GUPPY_SCREEN_FOLDER/guppyconfig.json" ]; then
    echo "Backing up your screen configuration..."
    cp "$GUPPY_SCREEN_FOLDER/guppyconfig.json" /tmp/guppyconfig.json
fi

# Step 3: Stop screen to unlock binary file
if [ -f "$GUPPY_SERVICE" ]; then
    echo "Stopping GuppyScreen service..."
    "$GUPPY_SERVICE" stop > /dev/null 2>&1 || true
fi
killall -q guppyscreen || true

# Step 4: Sync new compiled binaries and themes
echo "Applying new updates to application folder..."
rm -rf "$GUPPY_SCREEN_FOLDER"
mkdir -p "$GUPPY_SCREEN_FOLDER"
cp -rf "$GUPPY_SCREEN_SOURCE/guppyscreen/"* "$GUPPY_SCREEN_FOLDER/"

# Update init script from source if it changed
if [ -f "$GUPPY_SCREEN_SOURCE/init/S57guppy_service" ]; then
    cp -f "$GUPPY_SCREEN_SOURCE/init/S57guppy_service" "$GUPPY_SERVICE"
    chmod +x "$GUPPY_SERVICE"
fi

# Step 5: Restore user configuration layout
if [ -f /tmp/guppyconfig.json ]; then
    echo "Restoring your screen configuration..."
    mv /tmp/guppyconfig.json "$GUPPY_SCREEN_FOLDER/guppyconfig.json"
fi

# Step 6: Restart and wake up the screen
if [ -f "$GUPPY_SERVICE" ]; then
    echo "Restarting GuppyScreen service..."
    "$GUPPY_SERVICE" start > /dev/null 2>&1 || true
fi

echo "GuppyScreen has been successfully updated to the latest MIPS build!"
exit 0
