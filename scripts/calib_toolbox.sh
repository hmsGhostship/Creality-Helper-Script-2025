#!/bin/sh

STATISCHER_PFAD="/usr/data/printer_data/config/printer.cfg"

install_calib_toolbox() {
    local SOURCE_FILE="/usr/data/helper-script/files/creality-calib-toolbox/calib_tool_box.cfg"
    local TARGET_FILE="/usr/data/printer_data/config/Helper-Script/calib_tool_box.cfg"
    local INCLUDE_LINE="[include Helper-Script/calib_tool_box.cfg]"

    echo "Starte Installation der Creality Calibration Toolbox..."

    if [ ! -f "$SOURCE_FILE" ]; then
        echo "Fehler: Quell-Makro calib_tool_box.cfg nicht unter $SOURCE_FILE gefunden!"
        return 1
    fi

    [ ! -d "/usr/data/printer_data/config/Helper-Script" ] && mkdir -p "/usr/data/printer_data/config/Helper-Script"
    
    cp "$SOURCE_FILE" "$TARGET_FILE"
    
    # Alte Instanzen INKLUSIVE Zeilenumbruch sauber ausradieren (/d)
    sed -i '/^\[include Helper-Script\/calib_tool_box.cfg\]/d' "$STATISCHER_PFAD"
    sed -i '/^#[[:space:]]*\[include Helper-Script\/calib_tool_box.cfg\]/d' "$STATISCHER_PFAD"
    
    # Das neue Include exakt in Zeile 2 einsetzen
    sed -i "2i $INCLUDE_LINE" "$STATISCHER_PFAD"
    
    echo "Calibration Toolbox erfolgreich installiert."
    echo "Info: Restarting Klipper service..."
    # REPARIERT: Offizieller C0DEbrained Core-Befehl
    restart_klipper
}

remove_calib_toolbox() {
    local TARGET_FILE="/usr/data/printer_data/config/Helper-Script/calib_tool_box.cfg"

    echo "Starte Deinstallation der Calibration Toolbox..."

    # Beim Deinstallieren die Zeile mitsamt Zeilenumbruch physisch loeschen (/d)
    sed -i '/^\[include Helper-Script\/calib_tool_box.cfg\]/d' "$STATISCHER_PFAD"
    sed -i '/^#[[:space:]]*\[include Helper-Script\/calib_tool_box.cfg\]/d' "$STATISCHER_PFAD"
    
    rm -f "$TARGET_FILE"
    
    echo "Calibration Toolbox erfolgreich entfernt."
    echo "Info: Restarting Klipper service..."
    # REPARIERT: Offizieller C0DEbrained Core-Befehl
    restart_klipper
}
