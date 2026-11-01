#!/bin/sh

set -e

function install_menu_ui_k1_2025() {
  top_line
  title "• CREALITY $(script_title) •" "${blue}"
  title '[ INSTALL MENU ]' "${yellow}"
  inner_line
  hr
  subtitle '•ESSENTIALS:'
  menu_option ' 1' 'Install' 'Moonraker and Nginx'
  menu_option ' 2' 'Install' 'Fluidd (port 4408)'
  menu_option ' 3' 'Install' 'Mainsail (port 4409)'
  hr
  subtitle '•UTILITIES:'
  menu_option ' 4' 'Install' 'Entware'
  menu_option ' 5' 'Install' 'Klipper Gcode Shell Command'
  hr
  subtitle '•CAMERA:'
  menu_option ' 6' 'Install' 'Go2rtc'
  menu_option ' 7' 'Install' 'USB Camera Support'
  menu_option ' 8' 'Install' 'Built-in Camera Fix'
  menu_option ' 9' 'Install' 'Camera Settings Control'
  menu_option '10' 'Install' 'Moonraker Timelapse'
  hr
  subtitle '•IMPROVEMENTS:'
  menu_option '11' 'Install' 'Restore Input Shapers'
  menu_option '12' 'Install' 'Extended Gcode Params'
  menu_option '13' 'Install' 'DXC Filament Sensor'
# menu_option '14' 'Install' 'CFS-C Universal Purge Speed Fix'
# menu_option '15' 'Install' 'Micro-Swiss FlowTech Volumetric Extension'
# menu_option '16' 'Install' 'FLY-LLL PLUS Safetysystem (Einschalt-Sperre)'
# menu_option '17' 'Install' 'Klipper Adaptive Meshing & Purging'
  menu_option '18' 'Install' 'Motor Sound Support'
# menu_option '19' 'Install' 'Fans Control Macros'
# menu_option '20' 'Install' 'Nozzle Cleaning Fan Control'
# _menu_option '21' 'Install' 'Improved Shapers Calibrations'
  menu_option '22' 'Install' 'Useful Macros'
# menu_option '23' 'Install' 'M600 Support'
  menu_option '24' 'Install' 'Git Backup'
  hr
  subtitle '•REMOTE ACCESS:'
# menu_option '25' 'Install' 'OctoEverywhere'
  menu_option '26' 'Install' 'Moonraker Obico'
# menu_option '27' 'Install' 'GuppyFLO'
  menu_option '28' 'Install' 'Mobileraker Companion'
# menu_option '29' 'Install' 'OctoApp Companion'
# menu_option '30' 'Install' 'SimplyPrint'
  hr
  inner_line
  hr
  bottom_menu_option 'b' 'Back to [Main Menu]' "${yellow}"
  bottom_menu_option 'q' 'Exit' "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}

function install_menu_k1_2025() {
  clear
  install_menu_ui_k1_2025
  local install_menu_opt
  while true; do
    read -p " ${white}Type your choice and validate with Enter: ${yellow}" install_menu_opt
    case "${install_menu_opt}" in
      1)
        if [ -d "$MOONRAKER_FOLDER" ]; then  
          error_msg "Moonraker and Nginx are already installed!"
        elif [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is needed, please install it first!"
        else
          if [ "$(basename "$(which tar)")" != "/opt/bin" ]; then
            echo "Installing tar from opkg..."
            opkg install tar
          fi
          if [ -z "$(command -v "git")" ]; then
            echo "Installing git from opkg..."
            opkg install git git-http
          fi
          run "install_moonraker_nginx" "install_menu_ui_k1_2025"
        fi;;
      2)
        if [ -d "$FLUIDD_FOLDER" ]; then  
          error_msg "Fluidd is already installed!"
        elif [ ! -d "$MOONRAKER_FOLDER" ] && [ ! -d "$NGINX_FOLDER" ]; then
          error_msg "Moonraker and Nginx are needed, please install them first!"
        else
          run "install_fluidd" "install_menu_ui_k1_2025"
        fi;;
      3)
        if [ -d "$MAINSAIL_FOLDER" ]; then  
          error_msg "Mainsail is already installed!"
        elif [ ! -d "$MOONRAKER_FOLDER" ] && [ ! -d "$NGINX_FOLDER" ]; then
          error_msg "Moonraker and Nginx are needed, please install them first!"
        else
          run "install_mainsail" "install_menu_ui_k1_2025"
        fi;;
      4)
        if [ -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is already installed!"
        else
          run "install_entware" "install_menu_ui_k1_2025"
        fi;;
      5)
        if [ -f "$KLIPPER_SHELL_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is already installed!"
        else
          run "install_gcode_shell_command" "install_menu_ui_k1_2025"
        fi;;
      6)
        if [ -f "$GO2RTC_FILE" ]; then
          error_msg "Go2rtc is already installed!"
        else
          run "install_go2rtc" "install_menu_ui_k1_2025"
        fi;;
      7)
        if [ -f "$USB_CAMERA_FILE" ]; then
          error_msg "Camera USB Support is already installed!"
        elif [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is needed, please install it first!"
        elif [ ! -d "$MOONRAKER_FOLDER" ] || [ ! -d "$NGINX_FOLDER" ]; then
          error_msg "Moonraker and Nginx are needed, please install them first!"
        elif ! v4l2-ctl --list-devices | grep -A1 usb | sed 's/^[[:space:]]*//g' | grep '^/dev' | grep -vq '^/dev/video0$'; then
          error_msg "No third party USB camera found!"
        else
          run "install_usb_camera" "install_menu_ui_k1_2025"
        fi;;
      8)
        if [ -f "$BUILTIN_CAMERA_FILE" ]; then
          error_msg "Built-in Camera Fix is already installed!"
        elif [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is needed, please install it first!"
        elif [ ! -d "$MOONRAKER_FOLDER" ] || [ ! -d "$NGINX_FOLDER" ]; then
          error_msg "Moonraker and Nginx are needed, please install them first!"
        else
          run "install_builtin_camera" "install_menu_ui_k1_2025"
        fi;;
      9)
        if [ -f "$CAMERA_SETTINGS_FILE" ]; then
          error_msg "Camera Settings Control is already installed!"
        elif [ ! -f "$KLIPPER_SHELL_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is needed, please install it first!"
        else
          run "install_camera_settings_control" "install_menu_ui_k1_2025"
        fi;;
      10)
        if [ -f "$TIMELAPSE_FILE" ]; then
          error_msg "Moonraker Timelapse is already installed!"
        elif [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is needed, please install it first!"
        elif [ ! -d "$MOONRAKER_FOLDER" ] || [ ! -d "$NGINX_FOLDER" ]; then
          error_msg "Moonraker and Nginx are needed, please install them first!"
        else
          run "install_moonraker_timelapse" "install_menu_ui_k1_2025"
        fi;;
      11)
        clear
        if grep -q "^\[input_shaper\]" "$PRINTER_CFG" 2>/dev/null; then
          install_menu_ui_k1_2025
          echo
          error_msg "Restore Input Shapers is already active in printer.cfg!"
          echo
        else
          run "install_restore_input_shapers" "install_menu_ui_k1_2025"
        fi;;
      12)
        clear
        if grep -q "^\[extended_gcode_params\]" "$PRINTER_CFG" 2>/dev/null; then
          install_menu_ui_k1_2025
          echo
          error_msg "Extended Gcode Params is already active in printer.cfg!"
          echo
        else
          run "install_extended_gcode_params" "install_menu_ui_k1_2025"
        fi;;
      13)
        clear
        if grep -q "^\[include Helper-Script/dxc_sensor.cfg\]" "$PRINTER_CFG" 2>/dev/null; then
          install_menu_ui_k1_2025
          echo
          error_msg "DXC Filament Sensor is already active in printer.cfg!"
          echo
        else
          run "install_dxc_sensor" "install_menu_ui_k1_2025"
        fi;;
      14)
        clear
        if [ -f "$HS_BACKUP_FOLDER/box_control.pyc.orig" ]; then
          install_menu_ui_k1_2025
          echo
          error_msg "CFS-C Universal Purge Speed Fix is already installed!"
          echo
        else
          run "install_cfs_c_speed_fix" "install_menu_ui_k1_2025"
        fi;;
      15)
        clear
        if [ -f "$HS_BACKUP_FOLDER/box.cfg.orig" ]; then
          install_menu_ui_k1_2025
          echo
          error_msg "Micro-Swiss FlowTech Volumetric Extension is already installed!"
          echo
        else
          run "install_cfs_c_flowtech_extension" "install_menu_ui_k1_2025"
        fi;;
      16)
        clear
        # THE INTELLIGENT TEST LOCK: Keeps a fixed watch on the live status of the DXC sensor!
        if ! grep -q "^\[include Helper-Script/dxc_sensor.cfg\]" "$PRINTER_CFG" 2>/dev/null; then
            install_menu_ui_k1_2025
            echo
            error_msg "INSTALL-SPERRE: DXC Filament Sensor ist nicht aktiv!"
            echo -e "  Der originale Filament-Sensor belegt aktuell noch den Pin PD7."
            echo -e "  Bitte installiere zuerst den DXC Filament Sensor (Option 14)!"
            echo
        # DUAL INSTALLATION PROTECTION
        elif grep -q "^\[include Helper-Script/cfs_lll_safety.cfg\]" "$PRINTER_CFG" 2>/dev/null; then
            install_menu_ui_k1_2025
            echo
            error_msg "FLY-LLL PLUS Safetysystem is already active in printer.cfg!"
            echo
        # NATIVE INSTALL & RESTART
        else
            title "[ INSTALL: FLY-LLL PLUS SAFETYSYSTEM ]" "${yellow}"
            echo -e "  Kopiere Konfigurationsdateien..."
            cp /usr/data/helper-script/files/cfs-lll-plus-safety/cfs_lll_safety.cfg /usr/data/printer_data/config/Helper-Script/
            
            if ! grep -q "cfs_lll_safety.cfg" "$PRINTER_CFG" 2>/dev/null; then
                echo -e "\n[include Helper-Script/cfs_lll_safety.cfg]" >> "$PRINTER_CFG"
            fi
            
            echo
            echo -e "  ${green}✅ FLY-LLL PLUS erfolgreich installiert!${white}"
            echo -e "  Starte Klipper-Service automatisch neu..."
            echo
            run "restart_klipper" "install_menu_ui_k1_2025"
        fi;;
      17)
        clear
        if [ -d "$KAMP_FOLDER" ]; then
          install_menu_ui_k1_2025
          echo
          error_msg "Klipper Adaptive Meshing & Purging is already installed!"
          echo
        else
          run "install_kamp" "install_menu_ui_k1_2025"
        fi;;
      18)
        if [ -f "$MOTOR_SOUND_TARGET_FILE" ]; then
          error_msg "Motor sound Support is already installed!"
        else
          run "install_motor_sound" "install_menu_ui_k1_2025"
        fi;;
      19)
        if [ -f "$FAN_CONTROLS_FILE" ]; then
          error_msg "Fans Control Macros are already installed!"
        else
          run "install_fans_control_macros" "install_menu_ui_k1_2025"
        fi;;
      20)
        if [ -d "$NOZZLE_CLEANING_FOLDER" ]; then
          error_msg "Nozzle Cleaning Fan Control is already installed!"
        else
          run "install_nozzle_cleaning_fan_control" "install_menu_ui_k1_2025"
        fi;;
      21)
        if [ -d "$IMP_SHAPERS_FOLDER" ]; then
          error_msg "Improved Shapers Calibrations are already installed!"
        elif [ -d "$GUPPY_SCREEN_FOLDER" ]; then
          error_msg "Guppy Screen already has these features!"
        elif [ ! -f "$KLIPPER_SHELL_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is needed, please install it first!"
        else
          run "install_improved_shapers" "install_menu_ui_k1_2025"
        fi;;
     22)
        if [ -f "$USEFUL_MACROS_FILE" ]; then
          error_msg "Useful Macros are already installed!"
        elif [ ! -f "$KLIPPER_SHELL_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is needed, please install it first!"
        else
          run "install_useful_macros" "install_menu_ui_k1_2025"
        fi;;
      23)
        if [ -f "$M600_SUPPORT_FILE" ]; then
          error_msg "M600 Support is already installed!"
        else
          run "install_m600_support" "install_menu_ui_k1_2025"
        fi;;
      24)
        if [ -f "$GIT_BACKUP_FILE" ]; then
          error_msg "Git Backup is already installed!"
        elif [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is needed, please install it first!"
        elif [ ! -f "$KLIPPER_SHELL_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is needed, please install it first!"
        else
          # Startet einfach nur deine Menü-Datei
          run "install_git_backup" "install_menu_ui_k1_2025"
        fi;;
     25)
       if [ ! -d "$MOONRAKER_FOLDER" ]; then
         error_msg "Moonraker and Nginx are needed, please install them first!"
       elif [ ! -d "$FLUIDD_FOLDER" ] && [ ! -d "$MAINSAIL_FOLDER" ]; then
         error_msg "Fluidd or Mainsail is needed, please install one of them first!"
       elif [ ! -f "$ENTWARE_FILE" ]; then
         error_msg "Entware is needed, please install it first!"
       else
         run "install_octoeverywhere" "install_menu_ui_k1_2025"
         echo -e "\n${yellow} Press Enter to return to the menu...${white}" && read -r _
       fi;;
     26)
       clear
       if [ -d "$MOONRAKER_OBICO_FOLDER" ] && [ -f "$KLIPPER_CONFIG_FOLDER/moonraker-obico.cfg" ]; then
        error_msg "Moonraker Obico is already installed!"
       elif [ ! -d "$MOONRAKER_FOLDER" ]; then
         error_msg "Moonraker and Nginx are needed, please install them first!"
       elif [ ! -d "$FLUIDD_FOLDER" ] && [ ! -d "$MAINSAIL_FOLDER" ]; then
         error_msg "Fluidd or Mainsail is needed, please install one of them first!"
       elif [ ! -f "$ENTWARE_FILE" ]; then
         error_msg "Entware is needed, please install it first!"
       else
         run "install_moonraker_obico" "install_menu_ui_k1_2025"
       fi;;
     27)
       if [ ! -d "$MOONRAKER_FOLDER" ] && [ ! -d "$NGINX_FOLDER" ]; then
         error_msg "Moonraker and Nginx are needed, please install them first!"
       else
         run "install_guppyflo" "install_menu_ui_k1_2025"
       fi;;
     28)
       if [ -d "$MOBILERAKER_COMPANION_FOLDER" ]; then
         error_msg "Mobileraker Companion is already installed!"
       elif [ ! -d "$MOONRAKER_FOLDER" ]; then
         error_msg "Moonraker and Nginx are needed, please install them first!"
       elif [ ! -d "$FLUIDD_FOLDER" ] && [ ! -d "$MAINSAIL_FOLDER" ]; then
         error_msg "Fluidd or Mainsail is needed, please install one of them first!"
       elif [ ! -f "$ENTWARE_FILE" ]; then
         error_msg "Entware is needed, please install it first!"
       else
         run "install_mobileraker_companion" "install_menu_ui_k1_2025"
         # Countdown and reboot after successful execution
         if [ -d "$MOBILERAKER_COMPANION_FOLDER" ]; then
           echo -e "${yellow}"
           echo -e " ┌────────────────────────────────────────────────────────┐"
           echo -e " │  WARNUNG: Um den freigegebenen Arbeitsspeicher (RAM)   │"
           echo -e " │  wieder sauber aufzufüllen, startet der Drucker nun    │"
           echo -e " │  automatisch neu.                                      │"
           echo -e " └────────────────────────────────────────────────────────┘"
           
           for i in 10 9 8 7 6 5 4 3 2 1; do
               echo -e "    Drucker startet neu in $i Sekunden... \r\c"
               sleep 1
           done
           echo -e "${white}\nInfo: Starte System neu..."
           reboot
         else
           echo -e "\n${yellow} Press Enter to return to the menu...${white}" && read -r _
         fi
       fi;;
     29)
       if [ -d "$OCTOAPP_COMPANION_FOLDER" ]; then
         error_msg "OctoApp Companion is already installed!"
       elif [ ! -d "$MOONRAKER_FOLDER" ]; then
         error_msg "Moonraker and Nginx are needed, please install them first!"
       elif [ ! -d "$FLUIDD_FOLDER" ] && [ ! -d "$MAINSAIL_FOLDER" ]; then
         error_msg "Fluidd or Mainsail is needed, please install one of them first!"
       elif [ ! -f "$ENTWARE_FILE" ]; then
         error_msg "Entware is needed, please install it first!"
       else
         run "install_octoapp_companion" "install_menu_ui_k1_2025"
       fi;;
     30)
       if grep -q "\[simplyprint\]" "$MOONRAKER_CFG"; then
         error_msg "SimplyPrint is already installed!"
       elif [ ! -d "$MOONRAKER_FOLDER" ]; then
        error_msg "Moonraker and Nginx are needed, please install them first!"
       elif [ ! -d "$FLUIDD_FOLDER" ] && [ ! -d "$MAINSAIL_FOLDER" ]; then
         error_msg "Fluidd or Mainsail is needed, please install one of them first!"
       else
         run "install_simplyprint" "install_menu_ui_k1_2025"
       fi;;
      B|b)
        clear; main_menu; break;;
      Q|q)
         clear; exit 0;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
  install_menu_k1_2025
}