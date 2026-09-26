#!/bin/sh

STATISCHER_PFAD="/usr/data/printer_data/config/printer.cfg"
SOURCE_FILE="/usr/data/helper-script/files/dxc-filament-sensor/dxc_sensor.cfg"
TARGET_DIR="/usr/data/printer_data/config/Helper-Script"
TARGET_FILE="$TARGET_DIR/dxc_sensor.cfg"
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
      
      cp -f "$SOURCE_FILE" "$TARGET_FILE"
      chmod 644 "$TARGET_FILE"
      
      # Alten Sensor entschaerfen
      sed -i 's|\[filament_switch_sensor filament_sensor\]|\[filament_switch_sensor original_disabled_by_dxc\]|g' "$STATISCHER_PFAD"
      
      # KORRIGIERT: Sauberer Standard-Trenner fuer BusyBox-sed (/d)
      sed -i '/^\[include Helper-Script\/dxc_sensor.cfg\]/d' "$STATISCHER_PFAD"
      sed -i '/^#[[:space:]]*\[include Helper-Script\/dxc_sensor.cfg\]/d' "$STATISCHER_PFAD"
      
      # Das neue Include exakt in Zeile 2 einsetzen
      sed -i "2i $INCLUDE_LINE" "$STATISCHER_PFAD"
      
      echo "DXC Sensor erfolgreich via Helper-Script-System installiert."
      echo "Info: Restarting Klipper service..."
      restart_klipper
      ;;
    remove)
      echo "Starte Deinstallation des DXC Filament Sensors..."
      # KORRIGIERT: Sauberer Standard-Trenner fuer BusyBox-sed (/d)
      sed -i '/^\[include Helper-Script\/dxc_sensor.cfg\]/d' "$STATISCHER_PFAD"
      sed -i '/^#[[:space:]]*\[include Helper-Script\/dxc_sensor.cfg\]/d' "$STATISCHER_PFAD"
      
      sed -i 's|\[filament_switch_sensor original_disabled_by_dxc\]|\[filament_switch_sensor filament_sensor\]|g' "$STATISCHER_PFAD"
      rm -f "$TARGET_FILE"
      
      echo "Original-Werkszustand wurde erfolgreich wiederhergestellt."
      echo "Info: Restarting Klipper service..."
      restart_klipper
      ;;
  esac
}
