#!/bin/sh

SOURCE_FILE="$HS_FILES/dxc-filament-sensor/dxc_sensor.cfg"
TARGET_FILE="$HS_CONFIG_FOLDER/dxc_sensor.cfg"
BACKUP_FILE="$HS_CONFIG_FOLDER/dxc_sensor_factory_backup.cfg"
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
      
      # 1. DYNAMISCHE SICHERUNG: Extrahiere den originalen Block 1:1
      if grep -q "^\[filament_switch_sensor filament_sensor\]" "$PRINTER_CFG"; then
          echo "Originalen filament_sensor Block gefunden. Sichere Werkszustand..."
          # Extrahiert alles von der Sektion bis zur naechsten Sektion [
          sed -n '/^\[filament_switch_sensor filament_sensor\]/,/^{% endif %}/p' "$PRINTER_CFG" > "$BACKUP_FILE"
          # Fuege die Original-Ueberschrift oben im Backup wieder an
          sed -i '1i [filament_switch_sensor filament_sensor]' "$BACKUP_FILE"
          echo "Werkszustand dynamisch unter $BACKUP_FILE gesichert."
          
          # 2. DEAKTIVIERUNG: Den originalen Block in der printer.cfg auskommentieren
          # Wir setzen eine Raute vor jede Zeile des Blocks, bis die naechste Sektion beginnt
          sed -i '/^\[filament_switch_sensor filament_sensor\]/,/^{% endif %}/ { /^{% endif %}/! s/^/# /; /^[[:space:]]*[^#]/ s/^/# / }' "$PRINTER_CFG"
          # Die Hauptueberschrift separat auskommentieren – das ist unser PLATZHALTER (ANKER)
          sed -i 's|^\[filament_switch_sensor filament_sensor\]|# [filament_switch_sensor filament_sensor]|g' "$PRINTER_CFG"
      else
          echo "Hinweis: Kein aktiver [filament_switch_sensor filament_sensor] Block in printer.cfg gefunden."
      fi
      
      # 3. DXC-KONFIGURATION KOPIEREN
      cp -f "$SOURCE_FILE" "$TARGET_FILE"
      chmod 644 "$TARGET_FILE"
      
      # Alten DXC-Include-Eintrag saeubern
      sed -i '/^\[include Helper-Script\/dxc_sensor.cfg\]/d' "$PRINTER_CFG"
      sed -i '/^#[[:space:]]*\[include Helper-Script\/dxc_sensor.cfg\]/d' "$PRINTER_CFG"
      
      # Das neue Include in Zeile 2 einsetzen
      sed -i "2i $INCLUDE_LINE" "$PRINTER_CFG"
      
      echo "DXC Sensor erfolgreich via Helper-Script-System installiert."
      echo "Info: Restarting Klipper service..."
      restart_klipper
      ;;
      
    remove)
      echo "Starte Deinstallation des DXC Filament Sensors..."
      
      # 1. DXC-INCLUDE ENTFERNEN
      sed -i '/^\[include Helper-Script\/dxc_sensor.cfg\]/d' "$PRINTER_CFG"
      sed -i '/^#[[:space:]]*\[include Helper-Script\/dxc_sensor.cfg\]/d' "$PRINTER_CFG"
      
      # 2. ALTEN AUSKOMMENTIERTEN BLOCK LÖSCHEN (Wir lassen die Überschrift als Zielmarkierung stehen!)
      sed -i '/^# \[filament_switch_sensor filament_sensor\]/,/^# {% endif %}/ { /^# \[filament_switch_sensor filament_sensor\]/!d }' "$PRINTER_CFG"
      
      # 3. DYNAMISCHE WIEDERHERSTELLUNG AUS BACKUP
      if [ -f "$BACKUP_FILE" ]; then
          echo "Stelle originalen Werkszustand aus Backup 1:1 wieder her..."
          # Wir fügen das Backup genau an der Stelle der übrig gebliebenen Überschrift ein
          sed -i "/^# \[filament_switch_sensor filament_sensor\]/r $BACKUP_FILE" "$PRINTER_CFG"
          # Danach löschen wir die auskommentierte Überschrift, da sie jetzt im Backup wieder sauber drinsteht
          sed -i "/^# \[filament_switch_sensor filament_sensor\]/d" "$PRINTER_CFG"
          rm -f "$BACKUP_FILE"
          echo "Werkszustand erfolgreich 1:1 rekonstruiert."
      else
          echo "Warnung: Keine Backup-Datei $BACKUP_FILE gefunden! Kann Werkszustand nicht automatisch herstellen."
      fi
      
      rm -f "$TARGET_FILE"
      echo "Deinstallation abgeschlossen. Info: Restarting Klipper service..."
      restart_klipper
      ;;
  esac
}