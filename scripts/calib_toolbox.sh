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
    
    # -----------------------------------------------------------------
    # NEU: Das KAMP-Only Interface sofort deaktivieren, da deine Toolbox übernimmt
    # -----------------------------------------------------------------
    sed -i '/kamp_only\.cfg/d' "$STATISCHER_PFAD"
    # -----------------------------------------------------------------
    
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

    # Beim Deinstallieren die Toolbox-Zeile mitsamt Zeilenumbruch physisch löschen (/d)
    sed -i '/^\[include Helper-Script\/calib_tool_box.cfg\]/d' "$STATISCHER_PFAD"
    sed -i '/^#[[:space:]]*\[include Helper-Script\/calib_tool_box.cfg\]/d' "$STATISCHER_PFAD"
    
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
        sed -i '/kamp_only\.cfg/d' "$STATISCHER_PFAD" # Sicherheits-Bereinigung vorab
        echo -e "[include Helper-Script/KAMP/kamp_only.cfg]" >> "$STATISCHER_PFAD"
    fi
    # -----------------------------------------------------------------
    
    echo "Calibration Toolbox erfolgreich entfernt."
    echo "Info: Restarting Klipper service..."
    # Offizieller Core-Befehl zum Neustart
    restart_klipper
}