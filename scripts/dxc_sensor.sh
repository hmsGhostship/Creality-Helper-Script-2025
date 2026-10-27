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
      
      # 2. ALTE INCLUDE-EINTRÄGE REINIGEN
      sed -i '/\[include Helper-Script\/dxc_sensor.cfg\]/d' "$PRINTER_CFG"
      
      # 3. DAS NEUE INCLUDE GANZ OBEN IN ZEILE 2 EINFÜGEN
      sed -i "/^[[:space:]]*#[[:space:]]*CreateDate:.*/a $INCLUDE_LINE" "$PRINTER_CFG"
      
      # 4. PRÄZISE DEAKTIVIERUNG (Unempfindlich gegen Leerzeichen am Zeilenanfang)
      sed -i 's|\[filament_switch_sensor filament_sensor\]|# [filament_switch_sensor filament_sensor]|g' "$PRINTER_CFG"
      sed -i 's|switch_pin: !PD7|# switch_pin: !PD7|g' "$PRINTER_CFG"
      
      echo "DXC Sensor erfolgreich ganz oben in printer.cfg installiert."
      echo "Info: Restarting Klipper service..."
      restart_klipper
      ;;
      
    remove)
      echo "Starte Deinstallation des DXC Filament Sensors..."
      
      # 1. DXC-INCLUDE ENTFERNEN
      sed -i '/\[include Helper-Script\/dxc_sensor.cfg\]/d' "$PRINTER_CFG"
      
      # 2. WERKSZUSTAND WIEDERHERSTELLEN (Entfernt die Raute direkt vor dem Text)
      sed -i 's|#[[:space:]]*\[filament_switch_sensor filament_sensor\]|[filament_switch_sensor filament_sensor]|g' "$PRINTER_CFG"
      sed -i 's|#[[:space:]]*switch_pin: !PD7|switch_pin: !PD7|g' "$PRINTER_CFG"
      
      # 3. DATEI LÖSCHEN
      rm -f "$TARGET_FILE"
      
      echo "Deinstallation abgeschlossen. Info: Restarting Klipper service..."
      restart_klipper
      ;;
  esac
}
