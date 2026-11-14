#!/bin/sh

set -e

function customize_menu_ui_k1_2025_cfs_c() {
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
#  menu_option '8' 'Retire' 'Nexusp Backend'
  menu_option '9' 'Restore' 'Nexusp Backend'
#  hr
#  menu_option '10' 'Install' 'Guppy Screen'
#  menu_option '11' 'Remove' 'Guppy Screen'
#  if [ -d "$GUPPY_SCREEN_FOLDER" ]; then
#    menu_option '11a' 'Update' 'Guppy Screen'
#  else
#    unavailable_menu_option '11a' 'Update' 'Guppy Screen' 'DISABLED: Module must be installed first'
#  fi

  hr
  menu_option '12' 'Remove' 'CFS-C recognition (back to K1_2025)'
  hr
  inner_line
  hr
  bottom_menu_option 'b' 'Back to [Main Menu]' "${yellow}"
  bottom_menu_option 'q' 'Exit' "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}

# Remove the CFS-C option and revert to K1C 2025.
function disable_cfsc_menu() {
  clear
  top_line
  title "• DISABLE CFS-C MENU DETECTION •" "${blue}"
  inner_line
  echo -e " │ ${yellow}Info: The entry 'mb-料盒' will be deleted                     ${white} │"
  echo -e " │ ${yellow}from your printer.cfg                                          ${white}│"
  echo -e " │ Afterwards, the helper script restarts in the standard         │"
  echo -e " │ K1_2025 mode.                                                  │"
  hr
  bottom_line
  echo
  
  local yn
  while true; do
    read -p " Do you want to remove the detection now? (y/n): ${yellow}" yn
    case "${yn}" in
      Y|y)
        local tmp_file="${KLIPPER_CONFIG_FOLDER}/printer.cfg.tmp"

        awk '/<---------------------- SAVE_CONFIG ---------------------->/ {exit} {print}' "$PRINTER_CFG" > "$tmp_file"

        if grep -qE "bed_mesh default|input_shaper" "$PRINTER_CFG"; then
            echo "#*# <---------------------- SAVE_CONFIG ---------------------->" >> "$tmp_file"
            echo "#*# DO NOT EDIT THIS BLOCK OR BELOW. The contents are auto-generated." >> "$tmp_file"
            echo "#*#" >> "$tmp_file"
            
            awk '
            BEGIN { keep = 0 }
            /\<---------------------- SAVE_CONFIG ----------------------\>/ { next }
            /#\*# \[bed_mesh default\]/ || /#\*# \[input_shaper\]/ { keep = 1; print; next }
            /#\*# \[[a-zA-Z0-9_]+\]/ { keep = 0 }
            /#\*# \[serial_can\]/ || /cm-切刀/ || /mb-料盒/ { keep = 0; next }
            { if (keep == 1 && /#\*#/) print }
            ' "$PRINTER_CFG" >> "$tmp_file" 2>/dev/null
        fi

        mv "$tmp_file" "$PRINTER_CFG"
        
        ok_msg "Detection successfully removed and configuration thoroughly cleaned!"
        echo -e " ${green}Please restart the helper script to load the K1_2025 menu.${white}"
        echo
        exit 0
        break;;
      N|n)
        break;;
      *)
        error_msg "Please select y or n!";;
    esac
  done
}

function customize_menu_k1_2025_cfs_c() {
  clear
  customize_menu_ui_k1_2025_cfs_c
  local customize_menu_opt
  while true; do
    read -p " ${white}Type your choice and validate with Enter: ${yellow}" customize_menu_opt
    case "${customize_menu_opt}" in
      1)
        clear
        if [ -f "$FLUIDD_LOGO_FILE" ]; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "Creality Dynamic Logos for Fluidd are already installed!"
          echo
        elif [ ! -d "$FLUIDD_FOLDER" ]; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "Fluidd is needed, please install it first!"
          echo
        else
          run "install_creality_dynamic_logos" "customize_menu_ui_k1_2025_cfs_c"
        fi
        ;;
      2)
        clear
        if [ -f "$CLOUD_BLOCK_SERVICE_FILE" ]; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "Block Creality Cloud Telemetry is already installed!"
          echo
        else
          run "install_block_creality_cloud" "customize_menu_ui_k1_2025_cfs_c"
        fi
        ;;
      3)
        clear
        if [ ! -f "$CLOUD_BLOCK_SERVICE_FILE" ]; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "Block Creality Cloud Telemetry is not installed!"
          echo
        else
          run "remove_block_creality_cloud" "customize_menu_ui_k1_2025_cfs_c"
        fi
        ;;
      4)
        clear
        if creality_services_absent "cfs"; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "No Creality stock services were found on this firmware!"
          echo
        elif ! creality_services_pending "cfs"; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "Creality Stock Services are already disabled!"
          echo
        else
          run "disable_creality_services_cfs_c" "customize_menu_ui_k1_2025_cfs_c"
        fi
        ;;
      5)
        clear
        if creality_services_absent "cfs"; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "No Creality stock services were found on this firmware!"
          echo
        elif ! creality_services_disabled_present "cfs"; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "Creality Stock Services are not disabled!"
          echo
        else
          run "restore_creality_services_cfs_c" "customize_menu_ui_k1_2025_cfs_c"
        fi
        ;;
      6)
        clear
        if creality_mdns_absent; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "Creality mDNS service was not found on this firmware!"
          echo
        elif creality_mdns_disabled; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "Creality mDNS Advertising is already disabled!"
          echo
        else
          run "disable_creality_mdns" "customize_menu_ui_k1_2025_cfs_c"
        fi
        ;;
      7)
        clear
        if creality_mdns_absent; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "Creality mDNS service was not found on this firmware!"
          echo
        elif ! creality_mdns_disabled; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "Creality mDNS Advertising is not disabled!"
          echo
        else
          run "restore_creality_mdns" "customize_menu_ui_k1_2025_cfs_c"
        fi
        ;;
      8)
        clear
        disabled_feature
        continue
        if grep -q "mb-料盒" /usr/data/printer_data/config/printer.cfg 2>/dev/null; then
          disabled_feature
        elif nexusp_absent; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "No nexusp service was found on this firmware!"
          echo
        elif nexusp_retired && ! nexusp_resurrected; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "Nexusp Backend is already retired!"
          echo
        else
          run "retire_nexusp" "customize_menu_ui_k1_2025_cfs_c"
        fi
        ;;
      9)
        clear
        if nexusp_absent; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "No nexusp service was found on this firmware!"
          echo
        elif ! nexusp_retired; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "Nexusp Backend is not retired!"
          echo
        else
          run "restore_nexusp" "customize_menu_ui_k1_2025_cfs_c"
        fi
        ;;
      10|11|11a|11A)
        clear
        disabled_feature
        continue
        ;;
      10)
        clear
        disabled_feature
        continue
        if [ -d "$GUPPY_SCREEN_FOLDER" ]; then
        customize_menu_ui_k1_2025_cfs_c
          error_msg "Guppy Screen is already installed!"
        elif [ ! -d "$MOONRAKER_FOLDER" ] && [ ! -d "$NGINX_FOLDER" ]; then
        customize_menu_ui_k1_2025_cfs_c
          error_msg "Moonraker and Nginx are needed, please install them first!"
        elif ! curl -s localhost:7126/server/info 2>/dev/null | grep -Eq '"klippy_connected"[[:space:]]*:[[:space:]]*true'; then
          customize_menu_ui_k1_2025_cfs_c
          error_msg "Moonraker and Klipper do not seem to be functional. Please check this!"
        elif [ ! -f "$KLIPPER_SHELL_FILE" ]; then
        customize_menu_ui_k1_2025_cfs_c
          error_msg "Klipper Gcode Shell Command is needed, please install it first!"
        elif [ -d "$IMP_SHAPERS_FOLDER" ]; then
        customize_menu_ui_k1_2025_cfs_c
          error_msg "Please remove Improved Shapers Calibrations first, Guppy Screen already use it!"
        else
          run "install_guppyscreen" "customize_menu_ui_k1_2025_cfs_c"
        fi;;
      11)
        clear
        disabled_feature
        continue
        if [ ! -d "$GUPPY_SCREEN_FOLDER" ]; then
        customize_menu_ui_k1_2025_cfs_c        
        error_msg "Guppy Screen is not installed!"
        else
          run "remove_guppyscreen" "customize_menu_ui_k1_2025_cfs_c"
        fi;;
     11a|11A)
       clear
       disabled_feature
        continue
       if [ ! -d "$GUPPY_SCREEN_FOLDER" ]; then
         customize_menu_ui_k1_2025_2025_cfs_c
         echo
         error_msg "Guppy Screen is not installed!"
         echo
       else
         run "update_guppyscreen" "customize_menu_ui_k1_2025_2025_cfs_c"
       fi
       ;;
      12)
        clear
        disable_cfsc_menu
        break
        ;;
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
  customize_menu_k1_2025_cfs_c
}