function tools_menu_ui_k1_2025() {
  CURRENT_MENU_UI="tools_menu_ui_k1_2025"
#!/bin/sh

set -e


  top_line
  title "• CREALITY $(script_title) •" "${blue}"
  title '[ TOOLS MENU ]' "${yellow}"
  inner_line
  hr
  menu_option ' 1' 'Prevent updating' 'Klipper configuration files'
  menu_option ' 2' 'Allow updating' 'Klipper configuration files'
  hr
  menu_option ' 3' 'Enable' 'camera settings in Moonraker'
  menu_option ' 4' 'Disable' 'camera settings in Moonraker'
  menu_option ' 5' 'Add' 'chassis light control'
  hr
  menu_option ' 6' 'Restart' 'Nginx service'
  menu_option ' 7' 'Restart' 'Moonraker service'
  menu_option ' 8' 'Restart' 'Klipper service'
  hr
  menu_option '9' 'Update' 'Entware packages'
  hr
  menu_option '10' 'Clear' 'cache'
  menu_option '11' 'Clear' 'logs files'
  hr
#  subtitle '•CFS-C Tools:'
#  menu_option '12' 'Enable' 'Creality Calibration Toolbox (BED MESH)'
#  menu_option '13' 'Disable' 'Creality Calibration Toolbox (BED MESH)'
#  hr
#  subtitle '•CFS-C Mainsail/Fluidd integration:'
#  menu_option '14' 'Install' 'CFS-C Web Addon (Mainsail / Fluidd)'
#  menu_option '15' 'Remove' 'CFS-C Web Addon (Mainsail / Fluidd)'
  hr
  subtitle '•System Recovery:'
  menu_option '16' 'Install' 'Recovery Console (reccon)'
  menu_option '17' 'Remove' 'Recovery Console (reccon)'
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
          error_msg "Updating Klipper configuration files is already prevented!"
          echo
        else
          run "prevent_updating_klipper_files" "tools_menu_ui_k1_2025"
        fi
        ;;
      2)
        clear
        if [ ! -f "$INITD_FOLDER"/disabled.S55klipper_service ] && [ ! -f "$INITD_FOLDER"/disabled.CS55klipper_service ]; then
          error_msg "Updating Klipper configuration files is already allowed!"
          echo
        else
          run "allow_updating_klipper_files" "tools_menu_ui_k1_2025"
        fi
        ;;
      3)
        clear
        if [ ! -f "$BUILTIN_CAMERA_FILE" ] && [ ! -f "$BUILTIN_CAMERA_LEGACY_FILE" ] && [ ! -f "$USB_CAMERA_FILE" ] && [ ! -f "$USB_CAMERA_LEGACY_FILE" ] && [ ! -f "$GO2RTC_FILE" ]; then
          error_msg "Built-in Camera Fix, Go2rtc or USB Camera Support is needed, please install one first!"
          echo
        elif grep -q "^\[webcam chassis\]\|^\[webcam usb\]" "$MOONRAKER_CFG"; then
          error_msg "Camera settings are already enabled in Moonraker!"
          echo
        else
          run "enable_camera_settings" "tools_menu_ui_k1_2025"
        fi
        ;;
      4)
        clear
        if ! grep -q "^\[webcam chassis\]\|^\[webcam usb\]" "$MOONRAKER_CFG"; then
          error_msg "Camera settings are already disabled in Moonraker!"
          echo
        else
          run "disable_camera_settings" "tools_menu_ui_k1_2025"
        fi
        ;;
      5)
        clear
        if grep -q "^\[output_pin LED\]" "$PRINTER_CFG"; then
          error_msg "Chassis light control is already present in printer.cfg!"
          echo
        else
          run "add_chassis_light_control" "tools_menu_ui_k1_2025"
        fi
        ;;
      6)
        clear
        if [ ! -d "$NGINX_FOLDER" ]; then
          error_msg "Nginx is not installed!"
          echo
        else
          run "restart_nginx_action" "tools_menu_ui_k1_2025"
        fi
        ;;
      7)
        clear
        if [ ! -d "$MOONRAKER_FOLDER" ]; then
          error_msg "Moonraker is not installed!"
          echo
        else
          run "restart_moonraker_action" "tools_menu_ui_k1_2025"
        fi
        ;;
      8)
        clear
        if [ ! -f "$INITD_FOLDER"/CS55klipper_service ] && [ ! -f "$INITD_FOLDER"/S55klipper_service ]; then
          error_msg "Klipper service is not present!"
          echo
        else
          run "restart_klipper_action" "tools_menu_ui_k1_2025"
        fi
        ;;
      9)
        clear
        if [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is not installed!"
          echo
        else
          run "update_entware_packages" "tools_menu_ui_k1_2025"
        fi
        ;;
      10)
        clear
        run "clear_cache" "tools_menu_ui_k1_2025"
        ;;
      11)
        clear
        run "clear_logs" "tools_menu_ui_k1_2025"
        ;;
      12)
        clear
        if grep -q "^\[include Helper-Script/calib_tool_box.cfg\]" "$PRINTER_CFG" 2>/dev/null; then
          error_msg "Creality Calibration Toolbox is already installed and active!"
          echo
        else
          run "install_calib_toolbox" "tools_menu_ui_k1_2025"
        fi
        ;;
      13)
        clear
        grep -q "^\[include Helper-Script/calib_tool_box.cfg\]" "$PRINTER_CFG" 2>/dev/null && calib_res=0 || calib_res=1
        if [ "${calib_res}" -ne 0 ]; then
          error_msg "Creality Calibration Toolbox is not active or already removed!"
          echo
        else
          run "remove_calib_toolbox" "tools_menu_ui_k1_2025"
        fi
        ;;
      14)
        clear
        if [ -f "${MAINSAIL_FOLDER}/k1c-cfs-panel.js" ] || [ -f "${FLUIDD_FOLDER}/k1c-cfs-panel.js" ]; then
          error_msg "CFS-C Web Addon is already installed!"
          echo
        else
          run "install_cfs_integration" "tools_menu_ui_k1_2025"
        fi
        ;;
      15)
        clear
        if [ ! -f "${MAINSAIL_FOLDER}/k1c-cfs-panel.js" ] && [ ! -f "${FLUIDD_FOLDER}/k1c-cfs-panel.js" ]; then
          error_msg "CFS-C Web Addon is not installed!"
          echo
        else
          run "remove_cfs_integration" "tools_menu_ui_k1_2025"
        fi
        ;;
      16)
        clear
        if [ -f "$RECCON_BIN_FILE" ] && [ -f "$RECCON_SERVICE_FILE" ]; then
          error_msg "Recovery Console (reccon) is already installed!"
          echo
        else
          run "install_reccon" "tools_menu_ui_k1_2025"
        fi
        ;;
      17)
        clear
        if [ ! -f "$RECCON_BIN_FILE" ] && [ ! -f "$RECCON_SERVICE_FILE" ]; then
          error_msg "Recovery Console (reccon) is not installed!"
          echo
        else
          run "remove_reccon" "tools_menu_ui_k1_2025"
        fi
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
  tools_menu_k1_2025
}
