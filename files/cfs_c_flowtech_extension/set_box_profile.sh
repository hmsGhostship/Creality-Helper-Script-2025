#!/bin/sh
PROFILE=$1
# Der spezifische Pfad für die 2025er/2026er Creality-Architektur
INITD_FOLDER="/usr/apps/etc/init.d"

# 1. Prüfen, ob das angeforderte Profil existiert
if [ -f "/usr/data/creality/userdata/box/box_${PROFILE}.cfg" ]; then
    # Atomar kopieren (Zieldatei überschreiben)
    cp "/usr/data/creality/userdata/box/box_${PROFILE}.cfg" "/usr/data/creality/userdata/box/box.cfg"
    
    # 2. Originale Creality-Neustart-Logik für S12-Boards ausführen
    set +e
    if [ -f "$INITD_FOLDER/CS55klipper_service" ]; then
        "$INITD_FOLDER/CS55klipper_service" restart
    else
        "$INITD_FOLDER/S55klipper_service" restart
    fi
    set -e

    exit 0
else
    echo "Profil box_${PROFILE}.cfg existiert nicht!"
    exit 1
fi