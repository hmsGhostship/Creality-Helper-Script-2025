#!/bin/sh
PROFILE=$1
# Specific path for the 2025/2026 Creality architecture
INITD_FOLDER="/usr/apps/etc/init.d"

# 1. Check whether the requested profile exists
if [ -f "/usr/data/creality/userdata/box/box_${PROFILE}.cfg" ]; then
    # Atomic copy (overwrite target file)
    cp "/usr/data/creality/userdata/box/box_${PROFILE}.cfg" "/usr/data/creality/userdata/box/box.cfg"
    
    # 2. Execute original Creality restart logic for S12 boards
    set +e
    if [ -f "$INITD_FOLDER/CS55klipper_service" ]; then
        "$INITD_FOLDER/CS55klipper_service" restart
    else
        "$INITD_FOLDER/S55klipper_service" restart
    fi
    set -e

    exit 0
else
    echo "Profile box_${PROFILE}.cfg does not exist!"
    exit 1
fi