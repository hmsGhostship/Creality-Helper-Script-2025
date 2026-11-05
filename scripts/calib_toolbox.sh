#!/bin/sh

set -e

calib_toolbox_message(){
  top_line
  title 'Creality Calibration Toolbox (Bed Mesh):' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Optimized paths and enhanced support for precise               ${white}│"
  echo -e " │ ${cyan}Bed Mesh calibrations,                                         ${white}│"
  echo -e " │ ${cyan}ensuring perfect first layers with advanced probing.           ${white}│"
  hr
  bottom_line
}

install_calib_toolbox() {
  calib_toolbox_message
  local SOURCE_FILE="$HS_FILES/creality-calib-toolbox/calib_tool_box.cfg"
  local TARGET_FILE="$HS_CONFIG_FOLDER/calib_tool_box.cfg"
  local INCLUDE_LINE="[include Helper-Script/calib_tool_box.cfg]"
  local yn
  while true; do
    install_msg "Creality Calibration Toolbox" yn
    case "${yn}" in
      Y|y)
        echo "Starte Installation der Creality Calibration Toolbox..."

        if [ ! -f "$SOURCE_FILE" ]; then
          echo "Fehler: Quell-Makro calib_tool_box.cfg nicht unter $SOURCE_FILE gefunden!"
          return 1
        fi

        [ ! -d "/usr/data/printer_data/config/Helper-Script" ] && mkdir -p "/usr/data/printer_data/config/Helper-Script"
    
        cp -f "$SOURCE_FILE" "$TARGET_FILE"
    
        # Bereinigt alte kamp_only.cfg Eintraege restlos
        sed -i '/kamp_only\.cfg/d' "$PRINTER_CFG"
    
        # Bereinigt alte Toolbox-Eintraege, um Doppelungen zu vermeiden
        sed -i '/calib_tool_box\.cfg/d' "$PRINTER_CFG"
    
        # ➔ DIE SAUBERE ZWEI-WEGE-EINSORTIERUNG: Direkt unter CreateDate oder auf Zeile 5
        if grep -q "# CreateDate:" "$PRINTER_CFG"; then
          echo "Info: Injecting Toolbox include directly below CreateDate..."
          sed -i "/^[[:space:]]*#[[:space:]]*CreateDate:.*/a $INCLUDE_LINE" "$PRINTER_CFG"
        else
          echo "Info: CreateDate not found, injecting safely into line 5..."
          sed -i "5i $INCLUDE_LINE" "$PRINTER_CFG"
        fi
    
        echo "Calibration Toolbox erfolgreich installiert."
        echo "Info: Restarting Klipper service..."
        restart_klipper
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

make_calib_toolbox_remove() {
  # Hilfsfunktion, da die Hauptfunktion unten aufgerufen wird
  echo "Init remove configuration..."
}

remove_calib_toolbox() {
  calib_toolbox_message
  local TARGET_FILE="$HS_CONFIG_FOLDER/calib_tool_box.cfg"
  local yn
  while true; do
    remove_msg "Creality Calibration Toolbox" yn
    case "${yn}" in
      Y|y)
        echo "Starte Deinstallation der Calibration Toolbox..."

        # Loescht die Toolbox-Zeilen sauber heraus
        sed -i '/calib_tool_box\.cfg/d' "$PRINTER_CFG"
    
        rm -f "$TARGET_FILE"
    
        # ➔ OPTIMIERTER SICHERHEITS-LOCK FÜR KAMP:
        if [ -d "$KAMP_FOLDER" ]; then
          echo "Info: KAMP wurde auf dem Drucker gefunden."
        
          # Falls kamp_only.cfg im Ordner fehlt, wird sie live neu verlinkt
          if [ ! -f "$KAMP_FOLDER/kamp_only.cfg" ]; then
            echo "Sicherheits-Fix: kamp_only.cfg fehlt! Verlinke neu..."
            ln -sf "$KAMP_URL/kamp_only.cfg" "$KAMP_FOLDER/kamp_only.cfg"
          fi
        
          echo "Aktiviere KAMP-Only Interface sauber unter dem Header..."
          sed -i '/kamp_only\.cfg/d' "$PRINTER_CFG" # Vorab-Saeuberung
          
          # Ordnet KAMP-Include ebenfalls intelligent unter CreateDate ein statt ganz unten!
          local kamp_line="[include Helper-Script/KAMP/kamp_only.cfg]"
          if grep -q "# CreateDate:" "$PRINTER_CFG"; then
            sed -i "/^[[:space:]]*#[[:space:]]*CreateDate:.*/a $kamp_line" "$PRINTER_CFG"
          else
            sed -i "5i $kamp_line" "$PRINTER_CFG"
          fi
        fi
    
        echo "Calibration Toolbox erfolgreich entfernt."
        echo "Info: Restarting Klipper service..."
        restart_klipper
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}