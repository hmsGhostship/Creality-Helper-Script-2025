#!/bin/sh

set -e

function tools_menu_ui_k1_2025() {
  top_line
  title "• CREALITY $(script_title) •" "${blue}"
  title '[ TOOLS MENU ]' "${yellow}"
  inner_line
  hr
  menu_option ' 1' 'Prevent updating' 'Klipper configuration files'
  menu_option ' 2' 'Allow updating' 'Klipper configuration files'
  disabled_menu_option ' 3' 'Fix' 'printing Gcode files from folder'
  hr
  menu_option ' 4' 'Enable' 'camera settings in Moonraker'
  menu_option ' 5' 'Disable' 'camera settings in Moonraker'
  menu_option ' 6' 'Add' 'chassis light control'
  hr
  menu_option ' 7' 'Restart' 'Nginx service'
  menu_option ' 8' 'Restart' 'Moonraker service'
  menu_option ' 9' 'Restart' 'Klipper service'
  hr
  menu_option '10' 'Update' 'Entware packages'
  hr
  menu_option '11' 'Clear' 'cache'
  menu_option '12' 'Clear' 'logs files'
  hr
  disabled_menu_option '13' 'Restore' 'a previous firmware'
  hr
  disabled_menu_option '14' 'Reset' 'factory settings'
  hr
  inner_line
  hr
  bottom_menu_option 'b' 'Back to [Main Menu]' "${yellow}"
  bottom_menu_option 'q' 'Exit' "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}

function tools_menu_k1_2025() {
  clear
  tools_menu_ui_k1_2025
  local tools_menu_opt
  while true; do
    read -p " ${white}Type your choice and validate with Enter: ${yellow}" tools_menu_opt
    case "${tools_menu_opt}" in
      1)
        clear
        if [ -f "$INITD_FOLDER"/disabled.S55klipper_service ] || [ -f "$INITD_FOLDER"/disabled.CS55klipper_service ]; then
          tools_menu_ui_k1_2025
          echo
          error_msg "Updating Klipper configuration files is already prevented!"
          echo
        else
          run "prevent_updating_klipper_files" "tools_menu_ui_k1_2025"
        fi
        ;;
      2)
        clear
        if [ ! -f "$INITD_FOLDER"/disabled.S55klipper_service ] && [ ! -f "$INITD_FOLDER"/disabled.CS55klipper_service ]; then
          tools_menu_ui_k1_2025
          echo
          error_msg "Updating Klipper configuration files is already allowed!"
          echo
        else
          run "allow_updating_klipper_files" "tools_menu_ui_k1_2025"
        fi
        ;;
      3)
        clear
        disabled_feature
        ;;
      4)
        clear
        if [ ! -f "$BUILTIN_CAMERA_FILE" ] && [ ! -f "$BUILTIN_CAMERA_LEGACY_FILE" ] && [ ! -f "$USB_CAMERA_FILE" ] && [ ! -f "$USB_CAMERA_LEGACY_FILE" ]; then
          tools_menu_ui_k1_2025
          echo
          error_msg "Built-in Camera Fix or USB Camera Support is needed, please install one first!"
          echo
        elif grep -q "^\[webcam chassis\]\|^\[webcam usb\]" "$MOONRAKER_CFG"; then
          tools_menu_ui_k1_2025
          echo
          error_msg "Camera settings are already enabled in Moonraker!"
          echo
        else
          run "enable_camera_settings" "tools_menu_ui_k1_2025"
        fi
        ;;
      5)
        clear
        if ! grep -q "^\[webcam chassis\]\|^\[webcam usb\]" "$MOONRAKER_CFG"; then
          tools_menu_ui_k1_2025
          echo
          error_msg "Camera settings are already disabled in Moonraker!"
          echo
        else
          run "disable_camera_settings" "tools_menu_ui_k1_2025"
        fi
        ;;
      6)
        clear
        if grep -q "^\[output_pin LED\]" "$PRINTER_CFG"; then
          tools_menu_ui_k1_2025
          echo
          error_msg "Chassis light control is already present in printer.cfg!"
          echo
        else
          run "add_chassis_light_control" "tools_menu_ui_k1_2025"
        fi
        ;;
      7)
        clear
        if [ ! -d "$NGINX_FOLDER" ]; then
          tools_menu_ui_k1_2025
          echo
          error_msg "Nginx is not installed!"
          echo
        else
          run "restart_nginx_action" "tools_menu_ui_k1_2025"
        fi
        ;;
      8)
        clear
        if [ ! -d "$MOONRAKER_FOLDER" ]; then
          tools_menu_ui_k1_2025
          echo
          error_msg "Moonraker is not installed!"
          echo
        else
          run "restart_moonraker_action" "tools_menu_ui_k1_2025"
        fi
        ;;
      9)
        clear
        if [ ! -f "$INITD_FOLDER"/CS55klipper_service ] && [ ! -f "$INITD_FOLDER"/S55klipper_service ]; then
          tools_menu_ui_k1_2025
          echo
          error_msg "Klipper service is not present!"
          echo
        else
          run "restart_klipper_action" "tools_menu_ui_k1_2025"
        fi
        ;;
      10)
        clear
        if [ ! -f "$ENTWARE_FILE" ]; then
          tools_menu_ui_k1_2025
          echo
          error_msg "Entware is not installed!"
          echo
        else
          run "update_entware_packages" "tools_menu_ui_k1_2025"
        fi
        ;;
      11)
        clear
        run "clear_cache" "tools_menu_ui_k1_2025"
        ;;
      12)
        clear
        run "clear_logs" "tools_menu_ui_k1_2025"
        ;;
      13)
        clear
        disabled_feature
        ;;
      14)
        clear
        disabled_feature
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
  # REPARIERT: Ruft nun rekursiv die korrekte Hauptfunktion auf, um die Eingabezeile frisch zu laden
  tools_menu_k1_2025
}