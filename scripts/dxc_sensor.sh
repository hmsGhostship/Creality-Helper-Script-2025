#!/bin/sh

SOURCE_FILE="$HS_FILES/dxc-filament-sensor/dxc_sensor.cfg"
TARGET_FILE="$HS_CONFIG_FOLDER/dxc_sensor.cfg"
INCLUDE_LINE="[include Helper-Script/dxc_sensor.cfg]"

dxc_sensor() {
  case "$1" in
    install)
      echo "Starte Installation des DXC Filament Sensors..."
      if [ ! -f "$SOURCE_FILE" ]; then
          echo "Fehler: Quell-Makro dxc_sensor.cfg nicht unter $SOURCE_FILE gefunden!"
          return 1
      fi
      
      mkdir -p "$HS_CONFIG_FOLDER"
      chmod 755 "$HS_CONFIG_FOLDER"
      
      # 1. DXC-KONFIGURATION KOPIEREN
      cp -f "$SOURCE_FILE" "$TARGET_FILE"
      chmod 644 "$TARGET_FILE"
      
      # 2. ALTE INCLUDE-EINTRÄGE REINIGEN (Falls vorhanden)
      sed -i '/^\[include Helper-Script\/dxc_sensor.cfg\]/d' "$PRINTER_CFG"
      sed -i '/^#[[:space:]]*\[include Helper-Script\/dxc_sensor.cfg\]/d' "$PRINTER_CFG"
      
      # 3. DAS NEUE INCLUDE GANZ UNTEN ANFÜGEN
      # Bei Klipper MUSS das Überschreib-Include UNTEN stehen, damit es Vorrang hat!
      echo "" >> "$PRINTER_CFG"
      echo "$INCLUDE_LINE" >> "$PRINTER_CFG"
      
      echo "DXC Sensor erfolgreich via Klipper-Override installiert."
      echo "Info: Restarting Klipper service..."
      restart_klipper
      ;;
      
    remove)
      echo "Starte Deinstallation des DXC Filament Sensors..."
      
      # 1. DXC-INCLUDE AUS DER PRINTER.CFG LÖSCHEN
      sed -i '/^\[include Helper-Script\/dxc_sensor.cfg\]/d' "$PRINTER_CFG"
      sed -i '/^#[[:space:]]*\[include Helper-Script\/dxc_sensor.cfg\]/d' "$PRINTER_CFG"
      
      # 2. DATEI LÖSCHEN
      rm -f "$TARGET_FILE"
      
      echo "Deinstallation abgeschlossen. Info: Restarting Klipper service..."
      restart_klipper
      ;;
  esac
}
