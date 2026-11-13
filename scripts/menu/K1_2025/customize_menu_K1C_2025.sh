#!/bin/sh

set -e

function customize_menu_ui_k1_2025() {
  top_line
  title "• CREALITY $(script_title) •" "${blue}"
  title '[ CUSTOMIZE MENU ]' "${yellow}"
  inner_line
  hr
  menu_option '1' 'Install' 'Creality Dynamic Logos for Fluidd'
  hr
  menu_option '2' 'Install' 'Block Creality Cloud Telemetry'
  menu_option '3' 'Remove' 'Block Creality Cloud Telemetry'
  menu_option '4' 'Disable' 'Creality Stock Services'
  menu_option '5' 'Restore' 'Creality Stock Services'
  hr
  menu_option '6' 'Disable' 'Creality mDNS Advertising'
  menu_option '7' 'Restore' 'Creality mDNS Advertising'
  hr
  menu_option '8' 'Retire' 'Nexusp Backend'
  menu_option '9' 'Restore' 'Nexusp Backend'
  hr
  menu_option '10' 'Install' 'Guppy Screen'
  menu_option '11' 'Remove' 'Guppy Screen'
  hr
  inner_line
  hr
  bottom_menu_option 'b' 'Back to [Main Menu]' "${yellow}"
  bottom_menu_option 'q' 'Exit' "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}


function customize_menu_k1_2025() {
  clear
  customize_menu_ui_k1_2025
  local customize_menu_opt
  while true; do
    read -p " ${white}Type your choice and validate with Enter: ${yellow}" customize_menu_opt
    case "${customize_menu_opt}" in
      1)
        clear
        if [ -f "$FLUIDD_LOGO_FILE" ]; then
          customize_menu_ui_k1_2025
          echo
          error_msg "Creality Dynamic Logos for Fluidd are already installed!"
          echo
        elif [ ! -d "$FLUIDD_FOLDER" ]; then
          customize_menu_ui_k1_2025
          echo
          error_msg "Fluidd is needed, please install it first!"
          echo
        else
          run "install_creality_dynamic_logos" "customize_menu_ui_k1_2025"
        fi
        ;;
      2)
        clear
        if [ -f "$CLOUD_BLOCK_SERVICE_FILE" ]; then
          customize_menu_ui_k1_2025
          echo
          error_msg "Block Creality Cloud Telemetry is already installed!"
          echo
        else
          run "install_block_creality_cloud" "customize_menu_ui_k1_2025"
        fi
        ;;
      3)
        clear
        if [ ! -f "$CLOUD_BLOCK_SERVICE_FILE" ]; then
          customize_menu_ui_k1_2025
          echo
          error_msg "Block Creality Cloud Telemetry is not installed!"
          echo
        else
          run "remove_block_creality_cloud" "customize_menu_ui_k1_2025"
        fi
        ;;
      4)
        clear
        if creality_services_absent; then
          customize_menu_ui_k1_2025
          echo
          error_msg "No Creality stock services were found on this firmware!"
          echo
        elif ! creality_services_pending; then
          customize_menu_ui_k1_2025
          echo
          error_msg "Creality Stock Services are already disabled!"
          echo
        else
          run "disable_creality_services" "customize_menu_ui_k1_2025"
        fi
        ;;
      5)
        clear
        if creality_services_absent; then
          customize_menu_ui_k1_2025
          echo
          error_msg "No Creality stock services were found on this firmware!"
          echo
        elif ! creality_services_disabled_present; then
          customize_menu_ui_k1_2025
          echo
          error_msg "Creality Stock Services are not disabled!"
          echo
        else
          run "restore_creality_services" "customize_menu_ui_k1_2025"
        fi
        ;;
      6)
        clear
        if creality_mdns_absent; then
          customize_menu_ui_k1_2025
          echo
          error_msg "Creality mDNS service was not found on this firmware!"
          echo
        elif creality_mdns_disabled; then
          customize_menu_ui_k1_2025
          echo
          error_msg "Creality mDNS Advertising is already disabled!"
          echo
        else
          run "disable_creality_mdns" "customize_menu_ui_k1_2025"
        fi
        ;;
      7)
        clear
        if creality_mdns_absent; then
          customize_menu_ui_k1_2025
          echo
          error_msg "Creality mDNS service was not found on this firmware!"
          echo
        elif ! creality_mdns_disabled; then
          customize_menu_ui_k1_2025
          echo
          error_msg "Creality mDNS Advertising is not disabled!"
          echo
        else
          run "restore_creality_mdns" "customize_menu_ui_k1_2025"
        fi
        ;;
      8)
        clear
        if grep -q "mb-料盒" /usr/data/printer_data/config/printer.cfg 2>/dev/null; then
          disabled_feature
        elif nexusp_absent; then
          customize_menu_ui_k1_2025
          echo
          error_msg "No nexusp service was found on this firmware!"
          echo
        elif nexusp_retired && ! nexusp_resurrected; then
          customize_menu_ui_k1_2025
          echo
          error_msg "Nexusp Backend is already retired!"
          echo
        else
          run "retire_nexusp" "customize_menu_ui_k1_2025"
        fi
        ;;
      9)
        clear
        if nexusp_absent; then
          customize_menu_ui_k1_2025
          echo
          error_msg "No nexusp service was found on this firmware!"
          echo
        elif ! nexusp_retired; then
          customize_menu_ui_k1_2025
          echo
          error_msg "Nexusp Backend is not retired!"
          echo
        else
          run "restore_nexusp" "customize_menu_ui_k1_2025"
        fi
        ;;
      10)
        clear
        if [ -d "$GUPPY_SCREEN_FOLDER" ]; then
        customize_menu_ui_k1_2025
          error_msg "Guppy Screen is already installed!"
        elif [ ! -d "$MOONRAKER_FOLDER" ] && [ ! -d "$NGINX_FOLDER" ]; then
        customize_menu_ui_k1_2025
          error_msg "Moonraker and Nginx are needed, please install them first!"
        elif ! curl -s localhost:7126/server/info 2>/dev/null | grep -Eq '"klippy_connected"[[:space:]]*:[[:space:]]*true' && ! curl -s localhost:7125/server/info 2>/dev/null | grep -Eq '"klippy_connected"[[:space:]]*:[[:space:]]*true'; then
          customize_menu_ui_k1_2025
          error_msg "Moonraker and Klipper do not seem to be functional. Please check this!"
        elif [ ! -f "$KLIPPER_SHELL_FILE" ]; then
        customize_menu_ui_k1_2025
          error_msg "Klipper Gcode Shell Command is needed, please install it first!"
        elif [ -d "$IMP_SHAPERS_FOLDER" ]; then
        customize_menu_ui_k1_2025
          error_msg "Please remove Improved Shapers Calibrations first, Guppy Screen already use it!"
        else
          run "install_guppyscreen" "customize_menu_ui_k1_2025"
        fi;;
      11)
        clear
        if [ ! -d "$GUPPY_SCREEN_FOLDER" ]; then
        customize_menu_ui_k1_2025 
        error_msg "Guppy Screen is not installed!"
        else
          run "remove_guppyscreen" "customize_menu_ui_k1_2025"
        fi;;
      B|b)
        clear
        main_menu
        break
        ;;
      Q|q)
        clear
        exit 0
        ;;
      *)
        error_msg "Please select a correct choice!"
        ;;
    esac
  done
  customize_menu_k1_2025
}
