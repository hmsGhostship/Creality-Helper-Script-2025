#!/bin/sh

set -e

function get_script_version() {
  local version
  cd "${HELPER_SCRIPT_FOLDER}"
  version="$(git describe HEAD --always --tags | sed 's/-.*//')"
  echo "${cyan}${version}${white}"
}

function version_line() {
  local content="$1"
  local avail_mb ram_color visible_left visible_right padding_length
  avail_mb=$(get_available_ram_mb)
  if [ "$avail_mb" -ge 45 ]; then
    ram_color="${green}"
  elif [ "$avail_mb" -ge 25 ]; then
    ram_color="${yellow}"
  else
    ram_color="${red}"
  fi

  # Reinen sichtbaren Text ohne Farbcodes messen (Innenbreite = 62 Zeichen)
  visible_left="Free RAM: ${avail_mb} MB"
  visible_right=$(git -C "${HELPER_SCRIPT_FOLDER}" describe HEAD --always --tags 2>/dev/null | sed 's/-.*//')
  padding_length=$((62 - ${#visible_left} - ${#visible_right}))
  if [ "$padding_length" -lt 1 ]; then
    padding_length=1
  fi

  printf " │ ${white}Free RAM: ${ram_color}${avail_mb} MB${white}%*s${cyan}%s${white} │\n" "$padding_length" '' "$visible_right"
}

function script_title() {
  local title
  if [ "$model" = "K1_2025_CFS-C" ]; then
    title="K1 2025 CFS-C MOD"
  elif [ "$model" = "K1" ]; then
    title="K1 SERIES"
  else
    title="PRINTERS"
  fi
  echo "${title}"
}

function main_menu_ui() {
  top_line
  title "• HELPER SCRIPT FOR CREALITY $(script_title) •" "${blue}"
  title "Copyright © Cyril Guislain (Guilouz)" "${white}"
  title "K1 2025 Support by @C0DEBrained" "${white}"
  inner_line
  title "/!\\ ONLY USE THIS SCRIPT WITH LATEST FIRMWARE VERSION /!\\" "${darkred}"
  inner_line
  hr
  main_menu_option '1' '[Install]' 'Menu'
  main_menu_option '2' '[Remove]' 'Menu'
  main_menu_option '3' '[Customize]' 'Menu'
  main_menu_option '4' '[Backup & Restore]' 'Menu'
  main_menu_option '5' '[Tools]' 'Menu'
  main_menu_option '6' '[Information]' 'Menu'
  main_menu_option '7' '[System]' 'Menu'
  hr
  inner_line
  hr
  bottom_menu_option 'q' 'Exit' "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}

function main_menu() {
  clear
  main_menu_ui
  local main_menu_opt

  while true; do
    read -p "${white} Type your choice and validate with Enter: ${yellow}" main_menu_opt
    case "${main_menu_opt}" in
      1) 
         clear
         if [ "$model" = "K1_2025" ]; then
           install_menu_k1_2025
         elif [ "$model" = "K1_2025_CFS-C" ]; then 
           install_menu_k1_2025_cfs_c
         fi
         clear; main_menu_ui ;; # Zeigt das Menü nach der Aktion wieder an
      2) 
         clear
         if [ "$model" = "K1_2025" ]; then
           remove_menu_k1_2025
         elif [ "$model" = "K1_2025_CFS-C" ]; then 
           remove_menu_k1_2025_cfs_c
         fi
         clear; main_menu_ui ;;
      3) 
         clear
         if [ "$model" = "K1_2025" ]; then
           customize_menu_k1_2025
         elif [ "$model" = "K1_2025_CFS-C" ]; then 
           customize_menu_k1_2025_cfs_c
         fi
         clear; main_menu_ui ;;
      4) 
         clear
         backup_restore_menu
         clear; main_menu_ui ;;
      5) 
         clear
         if [ "$model" = "K1_2025" ]; then
           tools_menu_k1_2025
         elif [ "$model" = "K1_2025_CFS-C" ]; then 
           tools_menu_k1_2025_cfs_c
         fi
         clear; main_menu_ui ;; # Hinweis: "main_ui" wurde hier zu "main_menu_ui" korrigiert
      6) 
         clear
         if [ "$model" = "K1_2025" ]; then
           info_menu_k1_2025
         elif [ "$model" = "K1_2025_CFS-C" ]; then 
           info_menu_k1_2025_cfs_c
         fi
         clear; main_menu_ui ;;
      7) 
         clear
         system_menu
         clear; main_menu_ui ;;
      Q|q)
         clear
         exit 0 ;;
      *)
         error_msg "Please select a correct choice!" ;;
    esac
  done
}
