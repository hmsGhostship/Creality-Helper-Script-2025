#!/bin/sh

set -e

function camera_settings_control_message(){
  top_line
  title 'Camera Settings Control' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Installs advanced Klipper macros to adjust camera hardware     ${white}│"
  echo -e " │ ${cyan}settings like brightness, contrast, and exposure dynamically.  ${white}│"
  hr
  bottom_line
}

function install_camera_settings_control(){
  camera_settings_control_message
  local yn
  while true; do
    install_msg "Camera Settings Control" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        
        # INTELLIGENTE HARDWARE-ERKENNUNG VOR DER INSTALLATION
        echo -e "Info: Scanning hardware for compatible camera registers..."
        local REG_FOUND=0
        
        # Wir prüfen kurz, ob video0 oder video2 auf v4l2-ctl antworten
        if v4l2-ctl -d /dev/video0 --list-ctrls 2>/dev/null | grep -q "brightness" || \
           v4l2-ctl -d /dev/video2 --list-ctrls 2>/dev/null | grep -q "brightness"; then
          REG_FOUND=1
        fi
        
        if [ "$REG_FOUND" -eq 0 ]; then
          error_msg "Installation blocked: No adjustable hardware camera detected!"
          echo -e "${yellow}Note:${white} Your camera currently runs in closed auto-exposure mode"
          echo -e "or is blocked by a legacy service. Macros would have no effect."
          return
        fi

        if [ -f "$HS_CONFIG_FOLDER"/camera-settings.cfg ]; then
          rm -f "$HS_CONFIG_FOLDER"/camera-settings.cfg
        fi
        if [ ! -d "$HS_CONFIG_FOLDER" ]; then
          mkdir -p "$HS_CONFIG_FOLDER"
        fi
        
        echo -e "Info: Copying hardware-optimized configuration..."
        if [ "$model" = "K1_2025" ] || [ "$model" = "K1_2025_CFS-C" ]; then
          cp "$CAMERA_SETTINGS_K1_2025_URL" "$HS_CONFIG_FOLDER"/camera-settings.cfg
        else
          # Universeller Zukunfts-Fallback für nachfolgende Modelle (K2, etc.)
          cp "$CAMERA_SETTINGS_K1_2025_URL" "$HS_CONFIG_FOLDER"/camera-settings.cfg
        fi
        
        if grep -q "include Helper-Script/camera-settings" "$PRINTER_CFG" ; then
          echo -e "Info: Camera Settings configurations are already enabled in printer.cfg file..."
        elif grep -q "^# CreateDate:" "$PRINTER_CFG" ; then
          echo -e "Info: Adding Camera Settings configurations under CreateDate block..."
          sed -i '/^# CreateDate:/a \[include Helper-Script/camera-settings\.cfg\]' "$PRINTER_CFG"
        else
          echo -e "Info: Prepending Camera Settings configurations to top of printer.cfg file..."
          { echo "[include Helper-Script/camera-settings.cfg]"; cat "$PRINTER_CFG"; } > "$PRINTER_CFG.hs_tmp" && cat "$PRINTER_CFG.hs_tmp" > "$PRINTER_CFG" && rm -f "$PRINTER_CFG.hs_tmp"
        fi
        
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Camera Settings Control has been installed successfully!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_camera_settings_control(){
  camera_settings_control_message
  local yn
  while true; do
    remove_msg "Camera Settings Control" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Removing file..."
        rm -f "$HS_CONFIG_FOLDER"/camera-settings.cfg
        if grep -q "include Helper-Script/camera-settings" "$PRINTER_CFG" ; then
          echo -e "Info: Removing Camera Settings configurations in printer.cfg file..."
          sed -i '/include Helper-Script\/camera-settings\.cfg/d' "$PRINTER_CFG"
        fi
        if [ ! -n "$(ls -A "$HS_CONFIG_FOLDER")" ]; then
          rm -rf "$HS_CONFIG_FOLDER"
        fi
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Camera Settings Control has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

