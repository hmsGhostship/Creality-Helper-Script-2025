#!/bin/sh

STATISCHER_PFAD="/usr/data/printer_data/config/printer.cfg"
SOURCE_FILE="/usr/data/helper-script/files/dxc-filament-sensor/dxc_sensor.cfg"
TARGET_DIR="/usr/data/printer_data/config/Helper-Script"
TARGET_FILE="$TARGET_DIR/dxc_sensor.cfg"
BACKUP_FILE="$TARGET_DIR/dxc_sensor_factory_backup.cfg"
INCLUDE_LINE="[include Helper-Script/dxc_sensor.cfg]"

dxc_sensor() {
  case "$1" in
    install)
      echo "Starte Installation des DXC Filament Sensors..."
      if [ ! -f "$SOURCE_FILE" ]; then
          echo "Fehler: Quell-Makro dxc_sensor.cfg nicht unter $SOURCE_FILE gefunden!"
          return 1
      fi
      
      mkdir -p "$TARGET_DIR"
      chmod 755 "$TARGET_DIR"
      
      # 1. DYNAMISCHE SICHERUNG: Extrahiere den originalen Block 1:1
      if grep -q "^\[filament_switch_sensor filament_sensor\]" "$STATISCHER_PFAD"; then
          echo "Originalen filament_sensor Block gefunden. Sichere Werkszustand..."
          # Extrahiert alles von der Sektion bis zur naechsten Sektion [
          awk '/^\[filament_switch_sensor filament_sensor\]/,/^\[/ { if ($0 !~ /^\[/ || NR==WY) print }' "$STATISCHER_PFAD" | grep -v "^\[.*\]$" > "$BACKUP_FILE"
          # Fuege die Original-Ueberschrift oben im Backup wieder an
          sed -i '1i [filament_switch_sensor filament_sensor]' "$BACKUP_FILE"
          echo "Werkszustand dynamisch unter $BACKUP_FILE gesichert."
          
          # 2. DEAKTIVIERUNG: Den originalen Block in der printer.cfg auskommentieren
          # Wir setzen eine Raute vor jede Zeile des Blocks, bis die naechste Sektion beginnt
          sed -i '/^\[filament_switch_sensor filament_sensor\]/,/^\[/ { /^\[/! s/^/# /; /^[[:space:]]*[^#]/ s/^/# / }' "$STATISCHER_PFAD"
          # Die Hauptueberschrift separat auskommentieren
          sed -i 's|^\[filament_switch_sensor filament_sensor\]|# [filament_switch_sensor filament_sensor]|g' "$STATISCHER_PFAD"
      else
          echo "Hinweis: Kein aktiver [filament_switch_sensor filament_sensor] Block in printer.cfg gefunden."
      fi
      
      # 3. DXC-KONFIGURATION KOPIEREN
      cp -f "$SOURCE_FILE" "$TARGET_FILE"
      chmod 644 "$TARGET_FILE"
      
      # Alten DXC-Include-Eintrag saeubern
      sed -i '/^\[include Helper-Script\/dxc_sensor.cfg\]/d' "$STATISCHER_PFAD"
      sed -i '/^#[[:space:]]*\[include Helper-Script\/dxc_sensor.cfg\]/d' "$STATISCHER_PFAD"
      
      # Das neue Include in Zeile 2 einsetzen
      sed -i "2i $INCLUDE_LINE" "$STATISCHER_PFAD"
      
      echo "DXC Sensor erfolgreich via Helper-Script-System installiert."
      echo "Info: Restarting Klipper service..."
      restart_klipper
      ;;
      
    remove)
      echo "Starte Deinstallation des DXC Filament Sensors..."
      
      # 1. DXC-INCLUDE ENTFERNEN
      sed -i '/^\[include Helper-Script\/dxc_sensor.cfg\]/d' "$STATISCHER_PFAD"
      sed -i '/^#[[:space:]]*\[include Helper-Script\/dxc_sensor.cfg\]/d' "$STATISCHER_PFAD"
      
      # 2. ALTEN AUSKOMMENTIERTEN BLOCK LÖSCHEN
      # Wir loeschen den temporaer auskommentierten Bereich aus der printer.cfg
      sed -i '/^# \[filament_switch_sensor filament_sensor\]/,/^\[/ { /^\[/!d }' "$STATISCHER_PFAD"
      
      # 3. DYNAMISCHE WIEDERHERSTELLUNG AUS BACKUP
      if [ -f "$BACKUP_FILE" ]; then
          echo "Stelle originalen Werkszustand aus Backup 1:1 wieder her..."
          # Wir setzen den gesicherten Inhalt direkt wieder in Zeile 3 der printer.cfg ein
          sed -i "3r $BACKUP_FILE" "$STATISCHER_PFAD"
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