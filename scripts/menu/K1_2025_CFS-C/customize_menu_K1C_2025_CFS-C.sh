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
  disabled_menu_option '4' 'Disable' 'Creality Stock Services'
  menu_option '5' 'Restore' 'Creality Stock Services'
  hr
  disabled_menu_option '6' 'Retire' 'Nexusp Backend'
  menu_option '7' 'Restore' 'Nexusp Backend'
  hr
  menu_option '8' 'Remove' 'CFS-C recognition (back to K1_2025)'
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
  title "• DEAKTIVIERE CFS-C MENÜ-ERKENNUNG •" "${blue}"
  inner_line
  echo -e " │ ${yellow}Info: Der Eintrag 'mb-料盒' wird aus deiner printer.cfg gelöscht.${white} │"
  echo -e " │ Das Helper-Script startet danach wieder im Standard K1_2025 Modus. │"
  hr
  bottom_line
  echo
  
  local yn
  while true; do
    read -p " Möchtest du die Erkennung jetzt entfernen? (y/n): ${yellow}" yn
    case "${yn}" in
      Y|y)
        sed -i '/mb-料盒/d' /usr/data/printer_data/config/printer.cfg
        ok_msg "Erkennung erfolgreich entfernt!"
        echo -e " ${green}Bitte starte das Helper-Script neu, um das K1_2025 Menü zu laden.${white}"
        echo
        exit 0
        break;;
      N|n)
        break;;
      *)
        error_msg "Bitte wähle y oder n!";;
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
        if grep -q "mb-料盒" /usr/data/printer_data/config/printer.cfg 2>/dev/null; then
          disabled_feature
        elif creality_services_absent; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "No Creality stock services were found on this firmware!"
          echo
        elif ! creality_services_pending; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "Creality Stock Services are already disabled!"
          echo
        else
          run "disable_creality_services" "customize_menu_ui_k1_2025_cfs_c"
        fi
        ;;
      5)
        clear
        if creality_services_absent; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "No Creality stock services were found on this firmware!"
          echo
        elif ! creality_services_disabled_present; then
          customize_menu_ui_k1_2025_cfs_c
          echo
          error_msg "Creality Stock Services are not disabled!"
          echo
        else
          run "restore_creality_services" "customize_menu_ui_k1_2025_cfs_c"
        fi
        ;;
      6)
        clear
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
      7)
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
      8)
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
