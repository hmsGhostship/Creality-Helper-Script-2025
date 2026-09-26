#!/bin/sh

STATISCHER_PFAD="/usr/data/printer_data/config/printer.cfg"
TEMP_CFG="/usr/data/printer_data/config/printer_clean.tmp"

if [ ! -f "$STATISCHER_PFAD" ]; then
    echo "Fehler: printer.cfg nicht gefunden!"
    exit 1
fi

echo "Starte sichere Konfigurations-Bereinigung..."

cp "$STATISCHER_PFAD" "${STATISCHER_PFAD}.bak"

awk '
    /^#\*# <-----------/ { 
        if (seen_divider++) { next } 
    }
    /^#\*# DO NOT EDIT/ { 
        if (seen_warn++) { next } 
    }
    { print }
' "$STATISCHER_PFAD" > "$TEMP_CFG"

mv "$TEMP_CFG" "$STATISCHER_PFAD"

echo "Bereinigung erfolgreich abgeschlossen!"
echo "HINWEIS: Bitte Klipper jetzt einmal manuell in Mainsail neu starten."
