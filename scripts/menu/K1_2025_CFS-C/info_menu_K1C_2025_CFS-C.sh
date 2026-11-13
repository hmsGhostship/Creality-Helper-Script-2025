#!/bin/sh

set -e

function check_folder_k1_2025() {
  local folder_path="$1"
  if [ -d "$folder_path" ]; then
    echo -e "${green}✓"
  else
    echo -e "${red}✗"
  fi
}

function check_file_k1_2025() {
  local file_path="$1"
  
  # If $2 is equal to "-n", we check for "! -f"; otherwise, we check for "-f"
  if [ "$2" = "-n" ]; then
    [ ! -f "$file_path" ]
  else
    [ -f "$file_path" ]
  fi

  # $? holds the status of the last command (the if-check above)
  if [ $? -eq 0 ]; then
    echo -e "${green}✓"
  else
    echo -e "${red}✗"
  fi
}

# FIXED & NEW: The one and only universal check for Klipper (sections & includes)
function check_live_status_k1_2025() {
  if [ ! -f "$PRINTER_CFG" ]; then
    echo -e "${red}✗"
  elif grep -q "$1" "$PRINTER_CFG" 2>/dev/null; then
    echo -e "${green}✓"
  else
    echo -e "${red}✗"
  fi
}

function check_any_file_k1_2025() {
  local file_path
  for file_path in "$@"; do
    if [ -f "$file_path" ]; then
      echo -e "${green}✓"
      return
    fi
  done
  echo -e "${red}✗"
}

function check_start_print_calibration_k1_2025() {
  if [ ! -f "$PRINTER_CFG" ]; then
    echo -e "${red}✗"
  elif grep -q "^\[gcode_macro SDCARD_PRINT_FILE\]" "$PRINTER_CFG"; then
    echo -e "${green}✓"
  else
    echo -e "${red}✗"
  fi
}

function check_simplyprint_k1_2025() {
  if [ ! -f "$MOONRAKER_CFG" ]; then
    echo -e "${red}✗"
  elif grep -q "\[simplyprint\]" "$MOONRAKER_CFG"; then
    echo -e "${green}✓"
  else
    echo -e "${red}✗"
  fi
}

function check_creality_services_k1_2025() {
  local svc any_disabled any_enabled
  any_disabled=""
  any_enabled=""
  for svc in $(creality_core_services); do
    if [ -f "$(creality_service_disabled_path "$svc")" ]; then
      any_disabled="1"
    elif [ -f "$svc" ]; then
      any_enabled="1"
    fi
  done
  if [ -z "$any_disabled" ]; then
    echo -e "${red}✗"
  elif [ -n "$any_enabled" ]; then
    echo -e "${yellow}~"
  else
    echo -e "${green}✓"
  fi
}

function check_content_k1_2025() {
  local pattern="$1"
  local file_path="$2"
  local invert="$3"

  # grep -q searches for the pattern. 
  # Success (exit code 0) means: the pattern was found.
  grep -q "$pattern" "$file_path" 2>/dev/null
  local exit_code=$?

  # Logic for inversion (-n)
  if [ "$invert" = "-n" ]; then
    # If inverted, we want grep to have NO match (exit code other than 0)
    if [ $exit_code -ne 0 ]; then
      echo -e "${green}✓"
    else
      echo -e "${red}✗"
    fi
  else
    # Standard: If everything is normal, we want a success (exit code 0)
    if [ $exit_code -eq 0 ]; then
      echo -e "${green}✓"
    else
      echo -e "${red}✗"
    fi
  fi
}

function check_camera_capabilities_k1_2025() {
  # 1. Check in the RAM which mjpg_streamer port is actively running
  if ps -w | grep '[m]jpg_streamer' | grep -q "video2"; then
    return 0 # USB-Fix läuft aktiv
  elif ps -w | grep '[m]jpg_streamer' | grep -q "video0"; then
    return 0 # Chassis-Fix läuft aktiv
  fi

  # 2. Fallback: If no fix works, we’ll perform a quick hardware scan
  local i
  for i in 0 2; do
    if [ -e "/dev/video$i" ]; then
      if v4l2-ctl -d "/dev/video$i" --list-ctrls 2>/dev/null | grep -q "brightness"; then
        return 0 # Hardware vorhanden
      fi
    fi
  done
  return 1
}

function check_camera_settings_hardware_ui() {
  # Outputs ONLY the pure status symbol for info_line!
  if ps -w | grep '[m]jpg_streamer' | grep -qE "video0|video2"; then
    echo -e "${green}✓" # Fix läuft reell im RAM
  else
    if check_camera_capabilities_k1_2025; then
      echo -e "${yellow}~" 
    else
      echo -e "${red}✗"
    fi
  fi
}

function check_nexusp_retired_k1_2025() {
  if nexusp_absent; then
    echo -e "${cyan}-"
  elif nexusp_resurrected; then
    echo -e "${yellow}~"
  elif nexusp_retired; then
    echo -e "${green}✓"
  else
    echo -e "${red}✗"
  fi
}

function check_moonraker_port_k1_2025() {
  local port
  port="$(nexusp_moonraker_port)"
  if [ -z "$port" ]; then
    echo "port unknown"
  else
    echo "port $port"
  fi
}

function info_menu_ui_k1_2025_cfs_c() {
  top_line
  title "• CREALITY $(script_title) •" "${blue}"
  title '[ INFORMATION MENU ]' "${yellow}"
  inner_line
  hr
  subtitle '•ESSENTIALS:'
  info_line "$(check_folder_k1_2025 "$MOONRAKER_FOLDER")" 'Moonraker & Nginx'
  info_line "$(check_folder_k1_2025 "$FLUIDD_FOLDER")" 'Fluidd'
  info_line "$(check_folder_k1_2025 "$MAINSAIL_FOLDER")" 'Mainsail'
  hr
  subtitle '•UTILITIES:'
  info_line "$(check_file_k1_2025 "$ENTWARE_FILE")" 'Entware'
  info_line "$(check_file_k1_2025 "$KLIPPER_SHELL_FILE")" 'Klipper Gcode Shell Command'
  hr
  subtitle '•IMPROVEMENTS & EXPANSIONS:'
  info_line "$(check_live_status_k1_2025 "^\[input_shaper\]")" 'Restore Input Shapers'
  info_line "$(check_live_status_k1_2025 "^\[extended_gcode_params\]")" 'Extended Gcode Params'
  info_line "$(check_live_status_k1_2025 "^\[include Helper-Script/dxc_sensor.cfg\]")" 'DXC Filament Sensor'
  info_line "$(check_file_k1_2025 "$HS_BACKUP_FOLDER/box.cfg.orig")" 'CFS-C Purge Volume Fix (Prime Tower)'
  info_line "$(check_file_k1_2025 "$HS_BACKUP_FOLDER/box.cfg.orig")" 'CFS-C Purge Volume Fix (Prime Tower)'
  #info_line "$(check_live_status_k1_2025 "^\[include Helper-Script/cfs_lll_safety.cfg\]")" 'FLY-LLL PLUS Safetysystem'
  hr
  subtitle '•TOOLS & CALIBRATION:'
  info_line "$(check_file_k1_2025 "$KLIPPER_SERVICE_DISABLED")" 'Prevent updating Klipper configuration files'
  info_line "$(check_content_k1_2025 "^\[webcam chassis\]\|^\[webcam usb\]" "$MOONRAKER_CFG")" 'camera settings in Moonraker'
  info_line "$(check_live_status_k1_2025 "^\[include Helper-Script/calib_tool_box.cfg\]")" 'Creality Calibration Toolbox (BED MESH)'
  info_line "$(check_file_k1_2025 "${MAINSAIL_FOLDER}/k1c-cfs-panel.js")" 'CFS-C Mainsail Addon'
  info_line "$(check_file_k1_2025 "${FLUIDD_FOLDER}/k1c-cfs-panel.js")" 'CFS-C Fluidd Addon'
  info_line "$(check_file_k1_2025 "$MOTOR_SOUND_TARGET_FILE")" 'Motor Sound Support'
  info_line "$(check_file_k1_2025 "$USEFUL_MACROS_FILE")" 'Useful Macros'
  info_line "$(check_file_k1_2025 "$GIT_BACKUP_FILE")" 'Git Backup'
  #info_line "$(check_folder_k1_2025 "$KAMP_FOLDER")" 'Klipper Adaptive Meshing & Purging'
  #info_line "$(check_file_k1_2025 "$FAN_CONTROLS_FILE")" 'Fans Control Macros'
  #info_line "$(check_folder_k1_2025 "$NOZZLE_CLEANING_FOLDER")" 'Nozzle Cleaning Fan Control'
  #info_line "$(check_folder_k1_2025 "$IMP_SHAPERS_FOLDER")" 'Improved Shapers Calibrations'
  #info_line "$(check_file_k1_2025 "$M600_SUPPORT_FILE")" 'M600 Support'
  # ... Dein bestehender Code im Info-Menü
  # ... Dein bestehender Code im Info-Menü (Sektion 7)
  hr
  subtitle '•CAMERA:'
  info_line "$(check_file_k1_2025 "$CAMERA_SETTINGS_FILE")" 'Camera Settings Control Module'
  # NEW, MULTI-CAMERA LIVE ANALYSIS:
  local cam_text="Hardware Register Capability"
  local usb_status=""
  local chassis_status=""
  # 1. Check USB camera runtime
  if ps -w | grep '[m]jpg_streamer' | grep -q "video2" && v4l2-ctl -d /dev/video2 --list-ctrls 2>/dev/null | grep -q "brightness"; then
    usb_status="USB"
  fi
  # 2. Check chassis camera runtime
  if ps -w | grep '[m]jpg_streamer' | grep -q "video0" && v4l2-ctl -d /dev/video0 --list-ctrls 2>/dev/null | grep -q "brightness"; then
    chassis_status="Chassis"
  fi
  # 3. Dynamically assemble text based on the combination
  if [ -n "$usb_status" ] && [ -n "$chassis_status" ]; then
    cam_text="Hardware Register Capability (Active: USB & Chassis)"
  elif [ -n "$usb_status" ]; then
    cam_text="Hardware Register Capability (Active: USB Only)"
  elif [ -n "$chassis_status" ]; then
    cam_text="Hardware Register Capability (Active: Chassis Only)"
  elif check_camera_capabilities_k1_2025; then
    cam_text="Hardware Register Capability (Creality Stock Active)"
  else
    cam_text="Hardware Register Capability (No Devices / Auto-Only)"
  fi
  info_line "$(check_camera_settings_hardware_ui)" "$cam_text"
  info_line "$(check_file_k1_2025 "$GO2RTC_FILE")" 'Go2rtc'
  info_line "$(check_any_file_k1_2025 "$USB_CAMERA_FILE" "$USB_CAMERA_LEGACY_FILE")" 'USB Camera Support'
  info_line "$(check_any_file_k1_2025 "$BUILTIN_CAMERA_FILE" "$BUILTIN_CAMERA_LEGACY_FILE")" 'Built-in Camera Fix'
  info_line "$(check_file_k1_2025 "$CAMERA_SETTINGS_FILE")" 'Camera Settings Control'
  info_line "$(check_file_k1_2025 "$TIMELAPSE_FILE")" 'Moonraker Timelapse'
  hr
  subtitle '•REMOTE ACCESS:'
  info_line "$(check_folder_k1_2025 "$OCTOEVERYWHERE_FOLDER")" 'OctoEverywhere'
  info_line "$(check_folder_k1_2025 "$MOONRAKER_OBICO_FOLDER")" 'Obico'
  info_line "$(check_folder_k1_2025 "$GUPPYFLO_FOLDER")" 'GuppyFLO'
  info_line "$(check_folder_k1_2025 "$MOBILERAKER_COMPANION_FOLDER")" 'Mobileraker Companion'
  info_line "$(check_folder_k1_2025 "$OCTOAPP_COMPANION_FOLDER")" 'OctoApp Companion'
  info_line "$(check_simplyprint_k1_2025)" 'SimplyPrint'
  hr
  subtitle '•CUSTOMIZATION:'
  info_line "$(check_file_k1_2025 "$FLUIDD_LOGO_FILE")" 'Creality Dynamic Logos for Fluidd'
  info_line "$(check_file_k1_2025 "$CLOUD_BLOCK_SERVICE_FILE")" 'Block Creality Cloud Telemetry'
  info_line "$(check_creality_services_k1_2025)" 'Creality Stock Services Disabled'
  info_line "$(check_nexusp_retired_k1_2025)" "Nexusp Backend Retired (Moonraker on $(check_moonraker_port_k1_2025))"
  hr
  inner_line
  hr
  bottom_menu_option 'b' 'Back to [Main Menu]' "${yellow}"
  bottom_menu_option 'q' 'Exit' "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}

function info_menu_k1_2025_cfs_c() {
  clear
  info_menu_ui_k1_2025_cfs_c
  local info_menu_opt
  while true; do
    read -p " ${white}Type your choice and validate with Enter: ${yellow}" info_menu_opt
    case "${info_menu_opt}" in
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
  info_menu_k1_2025_cfs_c
}