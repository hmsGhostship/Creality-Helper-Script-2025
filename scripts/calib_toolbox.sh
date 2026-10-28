#!/bin/sh

install_calib_toolbox() {
    local SOURCE_FILE="$HS_FILES/creality-calib-toolbox/calib_tool_box.cfg"
    local TARGET_FILE="$HS_CONFIG_FOLDER/calib_tool_box.cfg"
    local INCLUDE_LINE="[include Helper-Script/calib_tool_box.cfg]"

    echo "Starte Installation der Creality Calibration Toolbox..."

    if [ ! -f "$SOURCE_FILE" ]; then
        echo "Fehler: Quell-Makro calib_tool_box.cfg nicht unter $SOURCE_FILE gefunden!"
        return 1
    fi

    [ ! -d "/usr/data/printer_data/config/Helper-Script" ] && mkdir -p "/usr/data/printer_data/config/Helper-Script"
    
    cp "$SOURCE_FILE" "$TARGET_FILE"
    
    # -----------------------------------------------------------------
    # NEU: Das KAMP-Only Interface sofort deaktivieren, da deine Toolbox übernimmt
    # -----------------------------------------------------------------
    sed -i '/kamp_only\.cfg/d' "$PRINTER_CFG"
    # -----------------------------------------------------------------
    
    # Alte Instanzen INKLUSIVE Zeilenumbruch sauber ausradieren (/d)
    sed -i '/^\[include Helper-Script\/calib_tool_box.cfg\]/d' "$PRINTER_CFG"
    sed -i '/^#[[:space:]]*\[include Helper-Script\/calib_tool_box.cfg\]/d' "$PRINTER_CFG"
    
    # Das neue Include exakt in Zeile 2 einsetzen
    sed -i "2i $INCLUDE_LINE" "$PRINTER_CFG"
    
    echo "Calibration Toolbox erfolgreich installiert."
    echo "Info: Restarting Klipper service..."
    # REPARIERT: Offizieller C0DEbrained Core-Befehl
    restart_klipper
}

remove_calib_toolbox() {
    local TARGET_FILE="$HS_CONFIG_FOLDER/calib_tool_box.cfg"

    echo "Starte Deinstallation der Calibration Toolbox..."

    # Beim Deinstallieren die Toolbox-Zeile mitsamt Zeilenumbruch physisch löschen (/d)
    sed -i '/^\[include Helper-Script\/calib_tool_box.cfg\]/d' "$PRINTER_CFG"
    sed -i '/^#[[:space:]]*\[include Helper-Script\/calib_tool_box.cfg\]/d' "$PRINTER_CFG"
    
    rm -f "$TARGET_FILE"
    
    # -----------------------------------------------------------------
    # OPTIMIERTES SICHERHEITS-SCHLOSS:
    # Wenn KAMP installiert ist, stellen wir sicher, dass kamp_only.cfg da ist und geladen wird!
    # -----------------------------------------------------------------
    if [ -d "$KAMP_FOLDER" ]; then
        echo "Info: KAMP wurde auf dem Drucker gefunden."
        
        # Sicherheits-Check: Falls die Datei im KAMP-Ordner fehlt, verlinken wir sie JETZT live neu!
        if [ ! -f "$KAMP_FOLDER/kamp_only.cfg" ]; then
            echo "Sicherheits-Fix: kamp_only.cfg fehlt im KAMP-Ordner! Verlinke neu aus Quell-Repository..."
            ln -sf "$KAMP_URL"/kamp_only.cfg "$KAMP_FOLDER"/kamp_only.cfg
        fi
        
        echo "Aktiviere KAMP-Only Interface in printer.cfg..."
        sed -i '/kamp_only\.cfg/d' "$PRINTER_CFG" # Sicherheits-Bereinigung vorab
        echo -e "[include Helper-Script/KAMP/kamp_only.cfg]" >> "$PRINTER_CFG"
    fi
    # -----------------------------------------------------------------
    
    echo "Calibration Toolbox erfolgreich entfernt."
    echo "Info: Restarting Klipper service..."
    # Offizieller Core-Befehl zum Neustart
    restart_klipper
}