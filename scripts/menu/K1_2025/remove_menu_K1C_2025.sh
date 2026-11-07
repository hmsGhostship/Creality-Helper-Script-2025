#!/bin/sh

set -e

function remove_menu_ui_k1_2025() {
  top_line
  title "• CREALITY $(script_title) •" "${blue}"
  title '[ REMOVE MENU ]' "${yellow}"
  inner_line
  hr
  subtitle '•ESSENTIALS:'
  menu_option ' 1' 'Remove' 'Moonraker and Nginx'
  menu_option ' 2' 'Remove' 'Fluidd (port 4408)'
  menu_option ' 3' 'Remove' 'Mainsail (port 4409)'
  hr
  subtitle '•UTILITIES:'
  menu_option ' 4' 'Remove' 'Entware'
  menu_option ' 5' 'Remove' 'Klipper Gcode Shell Command'
  hr
  subtitle '•CAMERA:'
  menu_option ' 6' 'Remove' 'Go2rtc'
  menu_option ' 7' 'Remove' 'USB Camera Support'
  menu_option ' 8' 'Remove' 'Built-in Camera Fix'
  menu_option ' 9' 'Remove' 'Camera Settings Control'
  menu_option '10' 'Remove' 'Moonraker Timelapse'
  hr
  subtitle '•IMPROVEMENTS:'
  menu_option '11' 'Remove' 'Restore Input Shapers'
  menu_option '12' 'Remove' 'Extended Gcode Params'
  menu_option '13' 'Remove' 'DXC Filament Sensor'
# menu_option '14' 'Remove' 'CFS-C Universal Purge Speed Fix'
# menu_option '15' 'Remove' 'Micro-Swiss FlowTech Volumetric Extension'
# menu_option '16' 'Remove' 'FLY-LLL PLUS Safetysystem'
  menu_option '17' 'Remove' 'Motor Sound Support'
  menu_option '18' 'Remove' 'Useful Macros'
  menu_option '19' 'Remove' 'Git Backup'
  if ! creality_services_pending && nexusp_retired && ! nexusp_resurrected; then
  :
# menu_option '20' 'Remove' 'Klipper Adaptive Meshing & Purging'
# menu_option '21' 'Remove' 'Fans Control Macros'
# menu_option '22' 'Remove' 'Nozzle Cleaning Fan Control'
# menu_option '23' 'Remove' 'Improved Shapers Calibrations'
# menu_option '24' 'Remove' 'M600 Support'
  fi
  hr
  subtitle '•REMOTE ACCESS:'
# menu_option '25' 'Remove' 'OctoEverywhere'
  menu_option '26' 'Remove' 'Moonraker Obico'
# menu_option '27' 'Remove' 'GuppyFLO'
  menu_option '28' 'Remove' 'Mobileraker Companion'
# menu_option '29' 'Remove' 'OctoApp Companion'
# menu_option '30' 'Remove' 'SimplyPrint'
  hr
  inner_line
  hr
  bottom_menu_option 'b' 'Back to [Main Menu]' "${yellow}"
  bottom_menu_option 'q' 'Exit' "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}

function remove_menu_k1_2025() {
  clear
  remove_menu_ui_k1_2025
  local remove_menu_opt
  while true; do
    read -p " ${white}Type your choice and validate with Enter: ${yellow}" remove_menu_opt
    case "${remove_menu_opt}" in
      1)
        if [ ! -d "$MOONRAKER_FOLDER" ] && [ ! -d "$NGINX_FOLDER" ]; then
          error_msg "Moonraker and Nginx are not installed!"
        elif [ -d "$GUPPY_SCREEN_FOLDER" ]; then
          error_msg "Moonraker is needed to use Guppy Screen, please uninstall it first!"
        else
         run "remove_moonraker_nginx" "remove_menu_ui_k1_2025"
        fi;;
      2)
        if [ ! -d "$FLUIDD_FOLDER" ]; then
          error_msg "Fluidd is not installed!"
        else
          run "remove_fluidd" "remove_menu_ui_k1_2025"
        fi;;
      3)
        if [ ! -d "$MAINSAIL_FOLDER" ]; then
          error_msg "Mainsail is not installed!"
        else
          run "remove_mainsail" "remove_menu_ui_k1_2025"
        fi;;
      4)
        if [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is not installed!"
        elif [ -f "$TIMELAPSE_FILE" ]; then
          error_msg "Entware is needed to use Moonraker Timelapse, please uninstall it first!"
        elif [ -f "$GIT_BACKUP_FILE" ]; then
          error_msg "Entware is needed to use Git Backup, please uninstall it first!"
        elif [ -d "$OCTOEVERYWHERE_FOLDER" ]; then
          error_msg "Entware is needed to use OctoEverywhere, please uninstall it first!"
        elif [ -d "$MOONRAKER_OBICO_FOLDER" ]; then
          error_msg "Entware is needed to use Moonraker Obico, please uninstall it first!"
        elif [ -f "$USB_CAMERA_FILE" ] || [ -f "$USB_CAMERA_LEGACY_FILE" ]; then
          error_msg "Entware is needed to use USB Camera Support, please uninstall it first!"
        elif [ -f "$BUILTIN_CAMERA_FILE" ] || [ -f "$BUILTIN_CAMERA_LEGACY_FILE" ]; then
          error_msg "Entware is needed to use Built-in Camera Fix, please uninstall it first!"
        else
          run "remove_entware" "remove_menu_ui_k1_2025"
        fi;;
      5)
        if [ ! -f "$KLIPPER_SHELL_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is not installed!"
        elif [ -f "$BUZZER_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is needed to use Buzzer Support, please uninstall it first!"
        elif [ -f "$CAMERA_SETTINGS_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is needed to use Camera Settings Control, please uninstall it first!"
        elif [ -d "$GUPPY_SCREEN_FOLDER" ]; then
          error_msg "Klipper Gcode Shell Command is needed to use Guppy Screen, please uninstall it first!"
        elif [ -d "$IMP_SHAPERS_FOLDER" ]; then
          error_msg "Klipper Gcode Shell Command is needed to use Improved Shapers Calibrations, please uninstall it first!"
        elif [ -f "$GIT_BACKUP_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is needed to use Git Backup, please uninstall it first!"
        elif [ -f "$USEFUL_MACROS_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is needed to use Useful Macros, please uninstall it first!"
        else
          run "remove_gcode_shell_command" "remove_menu_ui_k1_2025"
        fi;;

      6)
        if [ ! -f "$GO2RTC_FILE" ]; then
          error_msg "Go2rtc is not installed!"
        else
          run "remove_go2rtc" "remove_menu_ui_k1_2025"
        fi;;
      7)
        if [ ! -f "$USB_CAMERA_FILE" ] && [ ! -f "$USB_CAMERA_LEGACY_FILE" ]; then
          error_msg "USB Camera Support is not installed!"
        else
          run "remove_usb_camera" "remove_menu_ui_k1_2025"
        fi;;
      8)
        if [ ! -f "$BUILTIN_CAMERA_FILE" ] && [ ! -f "$BUILTIN_CAMERA_LEGACY_FILE" ]; then
          error_msg "Built-in Camera Fix is not installed!"
        else
          run "remove_builtin_camera" "remove_menu_ui_k1_2025"
        fi;;
      9)
        if [ ! -f "$CAMERA_SETTINGS_FILE" ]; then
          error_msg "Camera Settings Control is not installed!"
        else
          run "remove_camera_settings_control" "remove_menu_ui_k1_2025"
        fi;;
      10)
        if [ ! -f "$TIMELAPSE_FILE" ]; then
          error_msg "Moonraker Timelapse is not installed!"
        else
          run "remove_moonraker_timelapse" "remove_menu_ui_k1_2025"
        fi;;
      11)
        clear
        if ! grep -q "^\[input_shaper\]" "$PRINTER_CFG" 2>/dev/null; then
          remove_menu_ui_k1_2025
          echo
          error_msg "Restore Input Shapers is not active in printer.cfg!"
          echo
        else
          run "remove_restore_input_shapers" "remove_menu_ui_k1_2025"
        fi;;
      12)
        clear
        if ! grep -q "^\[extended_gcode_params\]" "$PRINTER_CFG" 2>/dev/null; then
          remove_menu_ui_k1_2025
          echo
          error_msg "Extended Gcode Params is not active in printer.cfg!"
          echo
        else
          run "remove_extended_gcode_params" "remove_menu_ui_k1_2025"
        fi;;
      13)
        clear
        # 1. ANTI-UNLOCK: If LLL Plus is active in live mode, we immediately block any attempt to remove it!
        if grep -q "^\[include Helper-Script/cfs_lll_safety.cfg\]" "$PRINTER_CFG" 2>/dev/null; then
            remove_menu_ui_k1_2025
            echo
            error_msg "REMOVE-SPERRE: DXC Filament Sensor blockiert!"
            echo -e "  Der Pin PD7 wird aktuell aktiv vom LLL Plus verwendet."
            echo -e "  Bitte entferne zuerst das FLY-LLL PLUS Safetysystem (Option 17)!"
            echo
        # 2. LIVE CHECK: Is the DXC sensor actually actively integrated?
        elif ! grep -q "^\[include Helper-Script/dxc_sensor.cfg\]" "$PRINTER_CFG" 2>/dev/null; then
            remove_menu_ui_k1_2025
            echo
            error_msg "DXC Filament Sensor is not active in printer.cfg!"
            echo
        else
            # Launches your new dxc_sensor.sh with dynamic backup restoration
            run "remove_dxc_sensor" "remove_menu_ui_k1_2025"
        fi
        ;;
      14)
        clear
        if [ ! -f "$HS_BACKUP_FOLDER/box_control.pyc.orig" ]; then
          remove_menu_ui_k1_2025
          echo
          error_msg "CFS-C Universal Purge Speed Fix is not installed!"
          echo
        else
          run "remove_cfs_c_speed_fix" "remove_menu_ui_k1_2025"
        fi
        ;;
      15)
        clear
        if [ ! -f "$HS_BACKUP_FOLDER/box.cfg.orig" ]; then
          remove_menu_ui_k1_2025
          echo
          error_msg "Micro-Swiss FlowTech Volumetric Extension is not installed!"
          echo
        else
          run "remove_cfs_c_flowtech_extension" "remove_menu_ui_k1_2025"
        fi
        ;;
      16)
        clear
        # CHECK: Is the LLL Plus actually live and active?
        if ! grep -q "^\[include Helper-Script/cfs_lll_safety.cfg\]" "$PRINTER_CFG" 2>/dev/null; then
            remove_menu_ui_k1_2025
            echo
            error_msg "FLY-LLL PLUS Safetysystem is not active in printer.cfg!"
            echo
        else
            title "[ REMOVE: FLY-LLL PLUS SAFETYSYSTEM ]" "${yellow}"
            echo -e "  Entferne Konfigurationsdateien..."
            rm -f /usr/data/printer_data/config/Helper-Script/cfs_lll_safety.cfg
            sed -i '/cfs_lll_safety.cfg/d' /usr/data/printer_data/config/printer.cfg
            
            echo
            echo -e "  ${green}✅ FLY-LLL PLUS erfolgreich aus dem System entfernt!${white}"
            echo -e "  Starte Klipper-Service automatisch neu..."
            echo
            run "restart_klipper" "remove_menu_ui_k1_2025"
        fi;;
      17)
         if [ ! -f "$MOTOR_SOUND_TARGET_FILE" ]; then
           error_msg "Motor Sound Support is not installed!"
         else
           run "remove_motor_sound" "remove_menu_ui_k1_2025"
         fi;;
      18)
        if [ ! -f "$USEFUL_MACROS_FILE" ]; then
          error_msg "Useful Macros are not installed!"
        else
          run "remove_useful_macros" "remove_menu_ui_k1_2025"
        fi;;
      19)
         if [ ! -f "$GIT_BACKUP_FILE" ]; then
           error_msg "Git Backup is not installed!"
          else
          run "remove_git_backup" "install_menu_ui_k1_2025"
         fi;;
      20)
        clear
        if [ ! -d "$KAMP_FOLDER" ]; then
          remove_menu_ui_k1_2025
          echo
          error_msg "Klipper Adaptive Meshing & Purging is not installed!"
          echo
        else
          run "remove_kamp" "remove_menu_ui_k1_2025"
        fi;;
      21)
        if [ ! -f "$FAN_CONTROLS_FILE" ]; then
          error_msg "Fans Control Macros are not installed!"
        else
          run "remove_fans_control_macros" "remove_menu_ui_k1_2025"
        fi;;
      22)
        if [ ! -d "$NOZZLE_CLEANING_FOLDER" ]; then
          error_msg "Nozzle Cleaning Fan Control is not installed!"
        else
          run "remove_nozzle_cleaning_fan_control" "remove_menu_ui_k1_2025"
        fi;;
      23)
        if [ ! -d "$IMP_SHAPERS_FOLDER" ]; then
          error_msg "Improved Shapers Calibrations are not installed!"
        else
          run "remove_improved_shapers" "remove_menu_ui_k1_2025"
        fi;;
      24)
        if [ ! -f "$M600_SUPPORT_FILE" ]; then
          error_msg "M600 Support is not installed!"
        else
          run "remove_m600_support" "remove_menu_ui_k1_2025"
        fi;;
      25)
        if [ ! -d "$OCTOEVERYWHERE_FOLDER" ]; then
          error_msg "OctoEverywhere is not installed!"
        else
          run "remove_octoeverywhere" "remove_menu_ui_k1_2025"
          echo -e "\n${yellow} Press Enter to return to the menu...${white}" && read -r _
        fi;;
      26)
        if [ ! -d "$MOONRAKER_OBICO_FOLDER" ]; then
           error_msg "Moonraker Obico is not installed!"
         else
           run "remove_moonraker_obico" "remove_menu_ui_k1_2025"
         fi;;
      27)
        if [ ! -d "$GUPPYFLO_FOLDER" ]; then
          error_msg "GuppyFLO is not installed!"
        else
          run "remove_guppyflo" "remove_menu_ui_k1_2025"
        fi;;
      28)
        if [ ! -d "$MOBILERAKER_COMPANION_FOLDER" ]; then
          error_msg "Mobileraker Companion is not installed!"
        else
          run "remove_mobileraker_companion" "remove_menu_ui_k1_2025"
        fi;;
      29)
        if [ ! -d "$OCTOAPP_COMPANION_FOLDER" ]; then
          error_msg "OctoApp Companion is not installed!"
        else
          run "remove_octoapp_companion" "remove_menu_ui_k1_2025"
        fi;;
      30)
        if ! grep -q "\[simplyprint\]" "$MOONRAKER_CFG"; then
          error_msg "SimplyPrint is not installed!"
        else
         run "remove_simplyprint" "remove_menu_ui_k1_2025"
        fi;;
      B|b)
        clear; main_menu; break;;
      Q|q)
         clear; exit 0;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
  remove_menu_k1_2025
}
