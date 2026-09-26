#!/bin/sh

set -e

function tools_menu_ui_k1_2025() {
  top_line
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
  menu_option '15' 'Enable' 'Creality Calibration Toolbox (BED MESH)'
  menu_option '16' 'Disable' 'Creality Calibration Toolbox (BED MESH)'
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
        if [ -f "$INITD_FOLDER"/disabled.S55klipper_service ] || [ -f "$INITD_FOLDER"/disabled.CS55klipper_service ]; then
          error_msg "Updating Klipper configuration files is already prevented!"
        else
          run "prevent_updating_klipper_files" "tools_menu_ui_k1_2025"
        fi;;
      2)
        if [ ! -f "$INITD_FOLDER"/disabled.S55klipper_service ] && [ ! -f "$INITD_FOLDER"/disabled.CS55klipper_service ]; then
          error_msg "Updating Klipper configuration files is already allowed!"
        else
          run "allow_updating_klipper_files" "tools_menu_ui_k1_2025"
        fi;;
      3)
        disabled_feature;;
#        if [ -f "$KLIPPER_KLIPPY_FOLDER"/gcode.py ]; then
#          run "printing_gcode_from_folder" "tools_menu_ui_k1_2025"
#        fi;;
      4)
        if [ ! -f "$BUILTIN_CAMERA_FILE" ] && [ ! -f "$BUILTIN_CAMERA_LEGACY_FILE" ] && [ ! -f "$USB_CAMERA_FILE" ] && [ ! -f "$USB_CAMERA_LEGACY_FILE" ]; then
          error_msg "Built-in Camera Fix or USB Camera Support is needed, please install one first!"
        elif grep -q "^\[webcam chassis\]\|^\[webcam usb\]" "$MOONRAKER_CFG"; then
          error_msg "Camera settings are already enabled in Moonraker!"
        else
          run "enable_camera_settings" "tools_menu_ui_k1_2025"
        fi;;
      5)
        if ! grep -q "^\[webcam chassis\]\|^\[webcam usb\]" "$MOONRAKER_CFG"; then
          error_msg "Camera settings are already disabled in Moonraker!"
        else
          run "disable_camera_settings" "tools_menu_ui_k1_2025"
        fi;;
      6)
        if grep -q "^\[output_pin LED\]" "$PRINTER_CFG"; then
          error_msg "Chassis light control is already present in printer.cfg!"
        else
          run "add_chassis_light_control" "tools_menu_ui_k1_2025"
        fi;;
      7)
        if [ ! -d "$NGINX_FOLDER" ]; then
          error_msg "Nginx is not installed!"
        else
          run "restart_nginx_action" "tools_menu_ui_k1_2025"
        fi;;
      8)
        if [ ! -d "$MOONRAKER_FOLDER" ]; then
          error_msg "Moonraker is not installed!"
        else
          run "restart_moonraker_action" "tools_menu_ui_k1_2025"
        fi;;
      9)
        if [ ! -f "$INITD_FOLDER"/CS55klipper_service ] && [ ! -f "$INITD_FOLDER"/S55klipper_service ]; then
          error_msg "Klipper service is not present!"
        else
          run "restart_klipper_action" "tools_menu_ui_k1_2025"
        fi;;
      10)
        if [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is not installed!"
        else
          run "update_entware_packages" "tools_menu_ui_k1_2025"
        fi;;
      11)
        run "clear_cache" "tools_menu_ui_k1_2025";;
      12)
        run "clear_logs" "tools_menu_ui_k1_2025";;
      13)
        disabled_feature;;
#        run "restore_previous_firmware" "tools_menu_ui_k1_2025";;
      14)
        disabled_feature;;
#        run "reset_factory_settings" "tools_menu_ui_k1_2025";;
      15)
        # TÜRSTEHER FÜR INSTALLATION: Wenn das Include bereits aktiv ist, blockieren wir!
        if grep -q "^\[include Helper-Script/calib_tool_box.cfg\]" /usr/data/printer_data/config/printer.cfg 2>/dev/null; then
          error_msg "Creality Calibration Toolbox ist bereits installiert und aktiv!"
        else
          # Startet die Installation über dein Skript scripts/calib_toolbox.sh
          run "install_calib_toolbox" "tools_menu_ui_k1_2025"
        fi
        ;;
      16)
        # TÜRSTEHER FÜR DEINSTALLATION: Wir fangen den Status sicher in einer Variablen ab
        grep -q "^\[include Helper-Script/calib_tool_box.cfg\]" /usr/data/printer_data/config/printer.cfg 2>/dev/null && calib_res=0 || calib_res=1
        
        # Wenn calib_res ungleich 0 ist (also 1 = nicht gefunden), gibt es nichts zu entfernen
        if [ "${calib_res}" -ne 0 ]; then
          error_msg "Creality Calibration Toolbox ist gar nicht aktiv oder bereits entfernt!"
        else
          # Startet das Deinstallieren über dein Skript scripts/calib_toolbox.sh
          run "remove_calib_toolbox" "tools_menu_ui_k1_2025"
        fi
        ;;
      B|b)
        clear; main_menu; break;;
      Q|q)
         clear; exit 0;;
      *)
         error_msg "Please select a correct choice!";;
    esac
  done
  tools_menu_k1_2025
}
