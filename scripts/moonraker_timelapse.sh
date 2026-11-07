#!/bin/sh

set -e

function moonraker_timelapse_message(){
  top_line
  title 'Moonraker Timelapse' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Moonraker Timelapse is a 3rd party Moonraker component to      ${white}│"
  echo -e " │ ${cyan}create timelapse of 3D prints.                                 ${white}│"
  hr
  bottom_line
}

function install_moonraker_timelapse(){
  moonraker_timelapse_message
  local yn
  while true; do
    install_msg "Moonraker Timelapse" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        ensure_respond_module
        if [ -f "$HS_CONFIG_FOLDER"/timelapse.cfg ]; then
          rm -f "$HS_CONFIG_FOLDER"/timelapse.cfg
        fi
        if [ ! -d "$HS_CONFIG_FOLDER" ]; then
          mkdir -p "$HS_CONFIG_FOLDER"
        fi
        
        echo -e "Info: Linking component file..."
        ln -sf "$TIMELAPSE_URL1" "$TIMELAPSE_FILE"
        
        MOONRAKER_REPO_DIR="${TIMELAPSE_FILE%/moonraker/components/timelapse.py}"
        if [ -d "$MOONRAKER_REPO_DIR"/.git/info ]; then
          echo -e "Info: Excluding linked component from Moonraker repo..."
          grep -qxF "moonraker/components/timelapse.py" "$MOONRAKER_REPO_DIR"/.git/info/exclude 2>/dev/null \
            || echo "moonraker/components/timelapse.py" >> "$MOONRAKER_REPO_DIR"/.git/info/exclude
        fi
        
        if [ "$model" = "K1_2025" ] || [ "$model" = "K1_2025_CFS-C" ]; then
          chmod 755 "$HS_CONFIG_FOLDER"
          cp -f "$TIMELAPSE_URL2" "$HS_CONFIG_FOLDER"/timelapse.cfg
          chmod 644 "$HS_CONFIG_FOLDER"/timelapse.cfg
        else
          ln -sf "$TIMELAPSE_URL2" "$HS_CONFIG_FOLDER"/timelapse.cfg
        fi
        
        if grep -q "include Helper-Script/timelapse" "$PRINTER_CFG" ; then
          echo -e "Info: Moonraker Timelapse configurations are already enabled in printer.cfg file..."
        elif grep -q "^# CreateDate:" "$PRINTER_CFG" ; then
          echo -e "Info: Adding Moonraker Timelapse configurations under CreateDate block..."
          sed -i '/^# CreateDate:/a \[include Helper-Script/timelapse\.cfg\]' "$PRINTER_CFG"
        elif grep -q "\[include printer_params\.cfg\]" "$PRINTER_CFG" ; then
          echo -e "Info: Adding Moonraker Timelapse configurations in printer.cfg file..."
          body_include='/\[include printer_params\.cfg\]/a \[include Helper-Script/timelapse\.cfg\]'
          sed -i "$body_include" "$PRINTER_CFG"
        else
          echo -e "Info: Adding Moonraker Timelapse configurations in printer.cfg file..."
          { echo "[include Helper-Script/timelapse.cfg]"; cat "$PRINTER_CFG"; } > "$PRINTER_CFG.hs_tmp" && cat "$PRINTER_CFG.hs_tmp" > "$PRINTER_CFG" && rm -f "$PRINTER_CFG.hs_tmp"
        fi
        # -> INTELLIGENT MULTI-CAMERA DETECTION FOR HARDWARE NATIVE RENDERING
        if [ -f "$MOONRAKER_CFG" ]; then
          sed -i '/\[timelapse\]/,/^[[:space:]]*$/d' "$MOONRAKER_CFG"
          
          local CAM_PORT="8080"
          
          if grep -q "^\[webcam usb\]" "$MOONRAKER_CFG" && grep -q "^\[webcam chassis\]" "$MOONRAKER_CFG"; then
            echo -e "Note: Multiple active webcam setups detected in moonraker.conf!"
            echo
            local cam_choice
            while true; do
              read -p " Which camera should Timelapse use? (${yellow}1${white}=USB Camera / ${yellow}2${white}=Built-in Camera): ${yellow}" cam_choice
              case "${cam_choice}" in
                1)
                  echo -e "${white}Info: Routing Timelapse to USB Camera (Port 8082)."
                  CAM_PORT="8082"
                  break;;
                2)
                  echo -e "${white}Info: Routing Timelapse to Built-in Camera (Port 8080)."
                  CAM_PORT="8080"
                  break;;
                *)
                  error_msg "Please select a correct choice! (1 or 2)";;
              esac
            done
          elif grep -q "^\[webcam usb\]" "$MOONRAKER_CFG"; then
            echo -e "Info: Active USB webcam configuration found. Using port 8082..."
            CAM_PORT="8082"
          elif grep -q "^\[webcam chassis\]" "$MOONRAKER_CFG"; then
            echo -e "Info: Active Built-in webcam configuration found. Using port 8080..."
            CAM_PORT="8080"
          else
            echo -e "Warning: No custom webcam section found. Falling back to default port 8080."
          fi

          echo -e "Info: Writing hardware-optimized paths to moonraker.conf..."
          echo -e "\n[timelapse]" >> "$MOONRAKER_CFG"
          echo -e "output_path: /usr/data/printer_data/timelapse/" >> "$MOONRAKER_CFG"
          echo -e "frame_path: /usr/data/printer_data/frames/" >> "$MOONRAKER_CFG"
          # -> WIR TRAGEN HIER DIE UNZENSURIERTE ENTWARE-VERSION EIN, DAMIT DIE AUTOMATIK BEIM DRUCKENDE NIE WIEDER ABSTÜRZT:
          echo -e "ffmpeg_binary_path: /opt/bin/ffmpeg" >> "$MOONRAKER_CFG"
          echo -e "snapshoturl: http://localhost:${CAM_PORT}/?action=snapshot" >> "$MOONRAKER_CFG"
        fi
        
        # -> AUTOMATISCHES ENTWARE-FFMPEG SETUP FÜR NATIVEN CODER-SUPPORT
        if [ -f "/opt/bin/ffmpeg" ]; then
          echo -e "Info: Full-featured Entware ffmpeg detected. Ready for web-native streaming."
        else
          echo -e "Info: Installing full-featured ffmpeg via Entware package manager..."
          if [ -x "$ENTWARE_FILE" ]; then
            "$ENTWARE_FILE" update && "$ENTWARE_FILE" install ffmpeg
          else
            echo -e "Warning: Entware package manager not found. Please install Entware first!"
          fi
        fi
        
        echo -e "Info: Reinitializing Klipper service first..."
        restart_klipper
        
        sleep 2
        
        if [ "$model" = "K1_2025" ] || [ "$model" = "K1_2025_CFS-C" ]; then
          echo -e "Info: Restarting Moonraker service safely with proper umask..."
          ( umask 022
            "$INITD_FOLDER"/S56moonraker_service stop 2>/dev/null
            sleep 1
            "$INITD_FOLDER"/S56moonraker_service start 2>/dev/null ) || true
        else
          if command -v stop_moonraker >/dev/null 2>&1 && command -v start_moonraker >/dev/null 2>&1; then
            stop_moonraker && sleep 1 && start_moonraker
          fi
        fi
        
        ok_msg "Moonraker Timelapse has been installed successfully!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_moonraker_timelapse(){
  moonraker_timelapse_message
  local yn
  while true; do
    remove_msg "Moonraker Timelapse" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Removing files..."
        rm -f "$HS_CONFIG_FOLDER"/timelapse.cfg
        
        rm -f "$TIMELAPSE_FILE"
        rm -f "${TIMELAPSE_FILE}c"
        
        MOONRAKER_REPO_DIR="${TIMELAPSE_FILE%/moonraker/components/timelapse.py}"
        if [ -f "$MOONRAKER_REPO_DIR"/.git/info/exclude ]; then
          sed -i '/^moonraker\/components\/timelapse\.py$/d' "$MOONRAKER_REPO_DIR"/.git/info/exclude
        fi
        
        if [ -f /opt/bin/ffmpeg ]; then
          echo -e "Info: Autoremoving Entware ffmpeg and unneeded libraries..."
          if [ -x "$ENTWARE_FILE" ]; then
            set +e
            "$ENTWARE_FILE" --autoremove remove ffmpeg
            set -e
          fi
        fi
        
        if grep -q "include Helper-Script/timelapse" "$PRINTER_CFG" ; then
          echo -e "Info: Removing Moonraker Timelapse configurations from printer.cfg file..."
          sed -i '/include Helper-Script\/timelapse\.cfg/d' "$PRINTER_CFG"
        fi
        
        if [ -f "$MOONRAKER_CFG" ]; then
          echo -e "Info: Cleaning Moonraker configuration safely..."
          sed -i '/\[timelapse\]/,/^[[:space:]]*$/d' "$MOONRAKER_CFG"
        fi
        
        if [ ! -n "$(ls -A "$HS_CONFIG_FOLDER")" ]; then
          rm -rf "$HS_CONFIG_FOLDER"
        fi
        
        echo -e "Info: Reinitializing Klipper service first..."
        restart_klipper
        
        sleep 2
        
        echo -e "Info: Restarting Moonraker service safely..."
        if [ "$model" = "K1_2025" ] || [ "$model" = "K1_2025_CFS-C" ]; then
          ( umask 022
            "$INITD_FOLDER"/S56moonraker_service stop 2>/dev/null
            sleep 1
            "$INITD_FOLDER"/S56moonraker_service start 2>/dev/null ) || true
        else
          if command -v stop_moonraker >/dev/null 2>&1 && command -v start_moonraker >/dev/null 2>&1; then
            stop_moonraker && sleep 1 && start_moonraker
          fi
        fi
        
        ok_msg "Moonraker Timelapse has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}