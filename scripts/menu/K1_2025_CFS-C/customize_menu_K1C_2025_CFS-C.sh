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
  
  # ABSTURZSICHER: Original-Textlaengen beibehalten!
  if grep -q "mb-料盒" /usr/data/printer_data/config/printer.cfg 2>/dev/null; then
    disabled_menu_option '4' 'Disable' 'Creality Stock Services'
  else
    menu_option '4' 'Disable' 'Creality Stock Services'
  fi
  menu_option '5' 'Restore' 'Creality Stock Services'
  hr
  
  # ABSTURZSICHER: Original-Textlaengen beibehalten!
  if grep -q "mb-料盒" /usr/data/printer_data/config/printer.cfg 2>/dev/null; then
    disabled_menu_option '6' 'Retire' 'Nexusp Backend'
  else
    menu_option '6' 'Retire' 'Nexusp Backend'
  fi
  menu_option '7' 'Restore' 'Nexusp Backend'
  hr
  
  # DEINE NEUE RESET OPTION
  menu_option '8' 'Remove' 'CFS-C recognition (back to K1_2025)'
  hr

  # HIER REIHEN SICH DEINE FLOWTECH FIX OPTIONEN EIN
  menu_option '9' 'Install' 'CFS-C FlowTech Volume Prime Fix (E50/F120)'
  menu_option '10' 'Remove' 'CFS-C FlowTech Volume Prime Fix'
  hr

  inner_line
  hr
  bottom_menu_option 'b' 'Back to [Main Menu]' "${yellow}"
  bottom_menu_option 'q' 'Exit' "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}


# DEINE NEUE ENTFERNEN-FUNKTION
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
  # KORREKTUR: Ruft jetzt deine eigene UI auf
  customize_menu_ui_k1_2025_cfs_c
  local customize_menu_opt
  while true; do
    read -p " ${white}Type your choice and validate with Enter: ${yellow}" customize_menu_opt
    case "${customize_menu_opt}" in
      1)
        if [ -f "$FLUIDD_LOGO_FILE" ]; then
          error_msg "Creality Dynamic Logos for Fluidd are already installed!"
        elif [ ! -d "$FLUIDD_FOLDER" ]; then
          error_msg "Fluidd is needed, please install it first!"
        else
          run "install_creality_dynamic_logos" "customize_menu_ui_k1_2025_cfs_c"
        fi;;
      2)
        if [ -f "$CLOUD_BLOCK_SERVICE_FILE" ]; then
          error_msg "Block Creality Cloud Telemetry is already installed!"
        else
          run "install_block_creality_cloud" "customize_menu_ui_k1_2025_cfs_c"
        fi;;
      3)
        if [ ! -f "$CLOUD_BLOCK_SERVICE_FILE" ]; then
          error_msg "Block Creality Cloud Telemetry is not installed!"
        else
          run "remove_block_creality_cloud" "customize_menu_ui_k1_2025_cfs_c"
        fi;;
      4)
        if grep -q "mb-料盒" /usr/data/printer_data/config/printer.cfg 2>/dev/null; then
          disabled_feature
        elif creality_services_absent; then
          error_msg "No Creality stock services were found on this firmware!"
        elif ! creality_services_pending; then
          error_msg "Creality Stock Services are already disabled!"
        else
          run "disable_creality_services" "customize_menu_ui_k1_2025_cfs_c"
        fi
        ;;
      5)
        if creality_services_absent; then
          error_msg "No Creality stock services were found on this firmware!"
        elif ! creality_services_disabled_present; then
          error_msg "Creality Stock Services are not disabled!"
        else
          run "restore_creality_services" "customize_menu_ui_k1_2025_cfs_c"
        fi;;
      6)
        if grep -q "mb-料盒" /usr/data/printer_data/config/printer.cfg 2>/dev/null; then
          disabled_feature
        elif nexusp_absent; then
          error_msg "No nexusp service was found on this firmware!"
        elif nexusp_retired && ! nexusp_resurrected; then
          error_msg "Nexusp Backend is already retired!"
        else
          run "retire_nexusp" "customize_menu_ui_k1_2025_cfs_c"
        fi
        ;;
      7)
        if nexusp_absent; then
          error_msg "No nexusp service was found on this firmware!"
        elif ! nexusp_retired; then
          error_msg "Nexusp Backend is not retired!"
        else
          run "restore_nexusp" "customize_menu_ui_k1_2025_cfs_c"
        fi;;
      8)
        # VERKNÜPFUNG: Startet deine neue Funktion
        clear
        disable_cfsc_menu
        break;;
      9)
        # NUTZT NUN DIE VARIABLE AUS DEINER PATH.SH / PRÜFT AUF DAS WORK-BACKUP
        if [ -f "$PYC_ORIG" ]; then
          error_msg "CFS-C FlowTech Fix is already installed!"
        else
          # Führt deine im Speicher liegende Funktion mit dem Parameter 'install' aus
          run "cfs_flowtech_prime_fix install" "customize_menu_ui_k1_2025_cfs_c"
        fi;;
      10)
        if [ ! -f "$PYC_ORIG" ]; then
          error_msg "CFS-C FlowTech Fix is not installed!"
        else
          # Führt deine im Speicher liegende Funktion mit dem Parameter 'remove' aus
          run "cfs_flowtech_prime_fix remove" "customize_menu_ui_k1_2025_cfs_c"
        fi;;
      B|b)
        clear; main_menu; break;;
      Q|q)
         clear; exit 0;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
  # KORREKTUR: Endlosschleife bleibt in deiner Funktion
  customize_menu_ui_k1_2025_cfs_c
}