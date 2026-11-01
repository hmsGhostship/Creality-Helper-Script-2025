#!/bin/sh

calib_toolbox_message(){
  top_line
  title 'Creality Calibration Toolbox (Bed Mesh):' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Optimized paths and enhanced support for precise                 ${white}│"
  echo -e " │ ${cyan}Bed Mesh calibrations,                                           ${white}│"
  echo -e " │ ${cyan}ensuring perfect first layers with advanced probing.             ${white}│"
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
    
      cp "$SOURCE_FILE" "$TARGET_FILE"
    
# -----------------------------------------------------------------
    # NEW: Disable the KAMP-Only interface immediately, as toolbox will take over
    # -----------------------------------------------------------------
    sed -i '/kamp_only\.cfg/d' "$PRINTER_CFG"
    # -----------------------------------------------------------------
    
    # Cleanly erase old instances INCLUDING line breaks (/d)
    sed -i '/^\[include Helper-Script\/calib_tool_box.cfg\]/d' "$PRINTER_CFG"
    sed -i '/^#[[:space:]]*\[include Helper-Script\/calib_tool_box.cfg\]/d' "$PRINTER_CFG"
    
    # Insert the new include exactly on line 2
    sed -i "2i $INCLUDE_LINE" "$PRINTER_CFG"
    
    echo "Calibration Toolbox erfolgreich installiert."
    echo "Info: Restarting Klipper service..."
    restart_klipper
	return;;
      N|n)
        error_msg "Backup canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
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

    # Physically delete the Toolbox line, including the line break, during uninstallation (/d)
    sed -i '/^\[include Helper-Script\/calib_tool_box.cfg\]/d' "$PRINTER_CFG"
    sed -i '/^#[[:space:]]*\[include Helper-Script\/calib_tool_box.cfg\]/d' "$PRINTER_CFG"
    
    rm -f "$TARGET_FILE"
    
# -----------------------------------------------------------------
    # OPTIMIZED SAFETY LOCK:
    # If KAMP is installed, we ensure that kamp_only.cfg is present and loaded!
    # -----------------------------------------------------------------
    if [ -d "$KAMP_FOLDER" ]; then
        echo "Info: KAMP wurde auf dem Drucker gefunden."
        
        # Security check: If the file is missing from the KAMP folder, we will re-link it live—RIGHT NOW!
        if [ ! -f "$KAMP_FOLDER/kamp_only.cfg" ]; then
            echo "Sicherheits-Fix: kamp_only.cfg fehlt im KAMP-Ordner! Verlinke neu aus Quell-Repository..."
            ln -sf "$KAMP_URL"/kamp_only.cfg "$KAMP_FOLDER"/kamp_only.cfg
        fi
        
        echo "Aktiviere KAMP-Only Interface in printer.cfg..."
        sed -i '/kamp_only\.cfg/d' "$PRINTER_CFG" # Preliminary security cleanup
        echo -e "[include Helper-Script/KAMP/kamp_only.cfg]" >> "$PRINTER_CFG"
    fi
    # -----------------------------------------------------------------
    
    echo "Calibration Toolbox erfolgreich entfernt."
    echo "Info: Restarting Klipper service..."
    restart_klipper
    return;;
      N|n)
        error_msg "Backup canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}