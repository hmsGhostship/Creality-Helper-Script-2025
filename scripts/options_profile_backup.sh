#!/bin/sh

set -e

OPT_PROFILE_DIR="/usr/data/helper-script-ota-backup"

function detect_active_profile_variant(){
  if [ "$model" = "K1_2025_CFS-C" ] || grep -q "box.cfg" "$PRINTER_CFG" 2>/dev/null; then
    echo "CFS-C"
  else
    echo "STANDARD"
  fi
}

function get_profile_filename(){
  local var="$1"
  if [ "$var" = "CFS-C" ]; then
    echo "options_profile_CFS-C.env"
  else
    echo "options_profile_STANDARD.env"
  fi
}

function backup_installed_options_profile(){
  top_line
  title 'Backup Installed Options Profile' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Scans all active Helper-Script modules from the Info Menu      ${white}│"
  echo -e " │ ${cyan}and saves a reproducible profile (separate for CFS-C / Std)    ${white}│"
  echo -e " │ ${cyan}to reinstall selected modules in proper dependency order.      ${white}│"
  hr
  bottom_line

  local variant yn
  variant="$(detect_active_profile_variant)"
  echo
  echo -e " Active menu / hardware mode detected: ${green}${variant}${white}"
  while true; do
    read -p " ${white}Do you want to backup ${green}Installed Options Profile (${variant})${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
    echo -e "${white}"
    case "${yn}" in
      Y|y)
        break;;
      N|n)
        error_msg "Backup canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done

  local fname out_file
  fname="$(get_profile_filename "$variant")"
  mkdir -p "$OPT_PROFILE_DIR"
  out_file="$OPT_PROFILE_DIR/$fname"

  local count=0
  {
    echo "# Helper-Script Installed Options Profile"
    echo "PROFILE_VARIANT=\"${variant}\""
    echo "CREATED_AT=\"$(date '+%Y-%m-%d %H:%M:%S')\""
    echo "OPT_MOONRAKER=$([ -d "$MOONRAKER_FOLDER" ] && echo 1 || echo 0)"
    echo "OPT_FLUIDD=$([ -d "$FLUIDD_FOLDER" ] && echo 1 || echo 0)"
    echo "OPT_MAINSAIL=$([ -d "$MAINSAIL_FOLDER" ] && echo 1 || echo 0)"
    echo "OPT_ENTWARE=$([ -f "$ENTWARE_FILE" ] && echo 1 || echo 0)"
    echo "OPT_GCODE_SHELL=$([ -f "$KLIPPER_SHELL_FILE" ] && echo 1 || echo 0)"
    echo "OPT_RECCON=$([ -f "$RECCON_BIN_FILE" ] && echo 1 || echo 0)"
    echo "OPT_INPUT_SHAPER=$(grep -q '^\[input_shaper\]' "$PRINTER_CFG" 2>/dev/null && echo 1 || echo 0)"
    echo "OPT_EXTENDED_GCODE=$(grep -q '^\[extended_gcode_params\]' "$PRINTER_CFG" 2>/dev/null && echo 1 || echo 0)"
    echo "OPT_DXC_SENSOR=$(grep -q '^\[include Helper-Script/dxc_sensor.cfg\]' "$PRINTER_CFG" 2>/dev/null && echo 1 || echo 0)"
    if [ "$variant" = "CFS-C" ]; then
      echo "OPT_CFS_SPEED_FIX=$([ -f "$HS_BACKUP_FOLDER/box_control.pyc.orig" ] && echo 1 || echo 0)"
      echo "OPT_CFS_VOL_FIX=$([ -f "$HS_BACKUP_FOLDER/box.cfg.orig" ] && echo 1 || echo 0)"
      echo "OPT_FLY_LLL=$(grep -q '^\[include Helper-Script/cfs_lll_safety.cfg\]' "$PRINTER_CFG" 2>/dev/null && echo 1 || echo 0)"
    else
      echo "OPT_CFS_SPEED_FIX=0"
      echo "OPT_CFS_VOL_FIX=0"
      echo "OPT_FLY_LLL=$(grep -q '^\[include Helper-Script/lll_plus_sensor_nocfs.cfg\]' "$PRINTER_CFG" 2>/dev/null && echo 1 || echo 0)"
    fi
    echo "OPT_CHASSIS_LIGHT=$(grep -q '^\[output_pin LED\]' "$PRINTER_CFG" 2>/dev/null && echo 1 || echo 0)"
    echo "OPT_CAM_MOONRAKER=$(grep -q '^\[webcam chassis\]\|^\[webcam usb\]' "$MOONRAKER_CFG" 2>/dev/null && echo 1 || echo 0)"
    echo "OPT_CAM_CONTROL=$([ -f "$CAMERA_SETTINGS_FILE" ] && echo 1 || echo 0)"
    echo "OPT_TIMELAPSE=$([ -f "$TIMELAPSE_FILE" ] && echo 1 || echo 0)"
    echo "OPT_CALIB_TOOLBOX=$(grep -q '^\[include Helper-Script/calib_tool_box.cfg\]' "$PRINTER_CFG" 2>/dev/null && echo 1 || echo 0)"
    echo "OPT_CFS_WEB_ADDON=$([ -f "${MAINSAIL_FOLDER}/k1c-cfs-panel.js" ] || [ -f "${FLUIDD_FOLDER}/k1c-cfs-panel.js" ] && echo 1 || echo 0)"
    echo "OPT_MOTOR_SOUND=$([ -f "$MOTOR_SOUND_TARGET_FILE" ] && echo 1 || echo 0)"
    echo "OPT_USEFUL_MACROS=$([ -f "$USEFUL_MACROS_FILE" ] && echo 1 || echo 0)"
    echo "OPT_GIT_BACKUP=$([ -f "$GIT_BACKUP_FILE" ] && echo 1 || echo 0)"
    echo "OPT_OCTOEVERYWHERE=$([ -d "$OCTOEVERYWHERE_FOLDER" ] && echo 1 || echo 0)"
    echo "OPT_OBICO=$([ -d "$MOONRAKER_OBICO_FOLDER" ] && echo 1 || echo 0)"
    echo "OPT_GUPPYFLO=$([ -d "$GUPPYFLO_FOLDER" ] && echo 1 || echo 0)"
    echo "OPT_MOBILERAKER=$([ -d "$MOBILERAKER_COMPANION_FOLDER" ] && echo 1 || echo 0)"
    echo "OPT_OCTOAPP=$([ -d "$OCTOAPP_COMPANION_FOLDER" ] && echo 1 || echo 0)"
    echo "OPT_SIMPLYPRINT=$(grep -q '^\[simplyprint\]' "$MOONRAKER_CFG" 2>/dev/null && echo 1 || echo 0)"
    echo "OPT_PREVENT_CFG_UPDATE=$([ -f "$KLIPPER_SERVICE_DISABLED" ] && echo 1 || echo 0)"
  } > "$out_file"

  count=$(grep -c "=1$" "$out_file" || true)
  echo -e " ${green}Saved ${variant} profile (${count} active options) to:${white}"
  echo -e "  ${cyan}${out_file}${white}"

  local usb_mnt=""
  if command -v detect_usb_mount >/dev/null 2>&1; then
    usb_mnt="$(detect_usb_mount 2>/dev/null || true)"
  fi
  if [ -z "$usb_mnt" ]; then
    local plug_yn
    while true; do
      read -p " ${yellow}No USB drive detected.${white} Do you want to plug in a USB drive now? (${yellow}y${white}/${yellow}n${white}): ${yellow}" plug_yn
      echo -e "${white}"
      case "$plug_yn" in
        Y|y)
          read -p " ${cyan}Plug in the USB drive, wait 2 seconds, then press Enter...${white}" _dummy
          sleep 1
          usb_mnt="$(detect_usb_mount 2>/dev/null || true)"
          if [ -n "$usb_mnt" ]; then
            echo -e " ${green}USB drive detected:${white} ${usb_mnt}"
            break
          else
            error_msg "Still no USB drive detected!"
          fi
          ;;
        N|n|"")
          break
          ;;
        *)
          error_msg "Please select y or n!"
          ;;
      esac
    done
  fi
  if [ -n "$usb_mnt" ]; then
    mkdir -p "$usb_mnt/helper-script-ota-backup"
    cp -f "$out_file" "$usb_mnt/helper-script-ota-backup/$fname"
    sync
    echo -e " ${green}USB copy saved & synced to:${white} ${cyan}${usb_mnt}/helper-script-ota-backup/${fname} (safe to unplug)${white}"
  fi
  echo
  ok_msg "Installed Options Profile (${variant}) has been backed up successfully!"
}

function install_fly_lll_for_profile(){
  local var="$1"
  if [ "$var" = "CFS-C" ]; then
    if ! grep -q "^\[include Helper-Script/dxc_sensor.cfg\]" "$PRINTER_CFG" 2>/dev/null; then
      error_msg "Skipping FLY-LLL Plus Safety: DXC Toolhead Sensor must be installed first!"
      return 1
    fi
    mkdir -p "$HS_CONFIG_FOLDER"
    cp /usr/data/helper-script/files/cfs-lll-plus-safety/cfs_lll_safety.cfg "$HS_CONFIG_FOLDER/"
    sed -i "/\[include Helper-Script\/cfs_lll_safety\.cfg\]/d" "$PRINTER_CFG" 2>/dev/null || true
    if grep -q "^[[:space:]]*#[[:space:]]*CreateDate:" "$PRINTER_CFG" 2>/dev/null; then
      sed -i "/^[[:space:]]*#[[:space:]]*CreateDate:.*/a [include Helper-Script/cfs_lll_safety.cfg]" "$PRINTER_CFG"
    else
      sed -i "1a [include Helper-Script/cfs_lll_safety.cfg]" "$PRINTER_CFG"
    fi
    if [ -f "$KLIPPY_EXTRAS/gcode_shell_command.py" ] && [ -f "/usr/apps/etc/init.d/CS56nexusp_service" ]; then
      mkdir -p "/usr/data/helper-script/backups" "$HS_CONFIG_FOLDER"
      [ -f "/usr/data/helper-script/backups/CS56nexusp_service.orig" ] || cp -f "/usr/apps/etc/init.d/CS56nexusp_service" "/usr/data/helper-script/backups/CS56nexusp_service.orig"
      cp -f "/usr/data/helper-script/files/macros/lll-plus-nexusp-switch.cfg" "$HS_CONFIG_FOLDER/lll-plus-nexusp-switch.cfg"
      touch "$HS_CONFIG_FOLDER/.lll_nexusp_guard_enabled"
      sed -i "/\[include Helper-Script\/lll-plus-nexusp-switch\.cfg\]/d" "$PRINTER_CFG" 2>/dev/null || true
      if grep -q "^[[:space:]]*#[[:space:]]*CreateDate:" "$PRINTER_CFG" 2>/dev/null; then
        sed -i "/^[[:space:]]*#[[:space:]]*CreateDate:.*/a [include Helper-Script/lll-plus-nexusp-switch.cfg]" "$PRINTER_CFG"
      else
        sed -i "1a [include Helper-Script/lll-plus-nexusp-switch.cfg]" "$PRINTER_CFG"
      fi
      grep -q "lll_nexusp_guard.sh" "/usr/apps/etc/init.d/CS56nexusp_service" || sed -i '/^start() {/a \      if [ -f "/usr/data/printer_data/config/Helper-Script/.lll_nexusp_guard_enabled" ] && [ "${FORCE_NEXUSP:-0}" != "1" ]; then sh /usr/data/helper-script/scripts/lll_nexusp_guard.sh boot-guard \& return 0; fi' "/usr/apps/etc/init.d/CS56nexusp_service"
      chmod +x "/usr/apps/etc/init.d/CS56nexusp_service"
    fi
    restart_klipper
  else
    if ! grep -q "^\[include Helper-Script/dxc_sensor.cfg\]" "$PRINTER_CFG" 2>/dev/null; then
      error_msg "Skipping FLY-LLL Plus Buffer Sensor: DXC Toolhead Sensor must be installed first!"
      return 1
    fi
    mkdir -p "$HS_CONFIG_FOLDER"
    cp /usr/data/helper-script/files/cfs-lll-plus-safety/lll_plus_sensor_nocfs.cfg "$HS_CONFIG_FOLDER/"
    sed -i "/\[include Helper-Script\/lll_plus_sensor_nocfs\.cfg\]/d" "$PRINTER_CFG" 2>/dev/null || true
    if grep -q "^[[:space:]]*#[[:space:]]*CreateDate:" "$PRINTER_CFG" 2>/dev/null; then
      sed -i "/^[[:space:]]*#[[:space:]]*CreateDate:.*/a [include Helper-Script/lll_plus_sensor_nocfs.cfg]" "$PRINTER_CFG"
    else
      sed -i "1a [include Helper-Script/lll_plus_sensor_nocfs.cfg]" "$PRINTER_CFG"
    fi
    restart_klipper
  fi
}

function execute_option_installer(){
  local key="$1"
  local var="$2"
  if [ "$var" = "CFS-C" ]; then
    model="K1_2025_CFS-C"
  else
    model="K1_2025"
  fi
  case "$key" in
    OPT_MOONRAKER) install_moonraker_nginx ;;
    OPT_FLUIDD) install_fluidd ;;
    OPT_MAINSAIL) install_mainsail ;;
    OPT_ENTWARE) install_entware ;;
    OPT_GCODE_SHELL) install_gcode_shell_command ;;
    OPT_RECCON) install_reccon ;;
    OPT_INPUT_SHAPER) install_restore_input_shapers ;;
    OPT_EXTENDED_GCODE) install_extended_gcode_params ;;
    OPT_DXC_SENSOR) install_dxc_sensor ;;
    OPT_CFS_SPEED_FIX) install_cfs_c_speed_fix ;;
    OPT_CFS_VOL_FIX) install_cfs_c_purge_volume_fix ;;
    OPT_FLY_LLL) install_fly_lll_for_profile "$var" ;;
    OPT_CHASSIS_LIGHT) add_chassis_light_control ;;
    OPT_CAM_MOONRAKER) enable_camera_settings ;;
    OPT_CAM_CONTROL) install_camera_settings_control ;;
    OPT_TIMELAPSE) install_moonraker_timelapse ;;
    OPT_CALIB_TOOLBOX) install_calib_toolbox ;;
    OPT_CFS_WEB_ADDON) install_cfs_integration ;;
    OPT_MOTOR_SOUND) install_motor_sound ;;
    OPT_USEFUL_MACROS) install_useful_macros ;;
    OPT_GIT_BACKUP) install_git_backup ;;
    OPT_OCTOEVERYWHERE) install_octoeverywhere ;;
    OPT_OBICO) install_moonraker_obico ;;
    OPT_GUPPYFLO) install_guppyflo ;;
    OPT_MOBILERAKER) install_mobileraker_companion ;;
    OPT_OCTOAPP) install_octoapp_companion ;;
    OPT_SIMPLYPRINT) install_simplyprint ;;
    OPT_PREVENT_CFG_UPDATE) prevent_updating_klipper_files ;;
  esac
}

function is_option_currently_installed(){
  local key="$1"
  local var="$2"
  case "$key" in
    OPT_MOONRAKER) [ -d "$MOONRAKER_FOLDER" ] ;;
    OPT_FLUIDD) [ -d "$FLUIDD_FOLDER" ] ;;
    OPT_MAINSAIL) [ -d "$MAINSAIL_FOLDER" ] ;;
    OPT_ENTWARE) [ -f "$ENTWARE_FILE" ] ;;
    OPT_GCODE_SHELL) [ -f "$KLIPPER_SHELL_FILE" ] ;;
    OPT_RECCON) [ -f "$RECCON_BIN_FILE" ] ;;
    OPT_INPUT_SHAPER) grep -q '^\[input_shaper\]' "$PRINTER_CFG" 2>/dev/null ;;
    OPT_EXTENDED_GCODE) grep -q '^\[extended_gcode_params\]' "$PRINTER_CFG" 2>/dev/null ;;
    OPT_DXC_SENSOR) grep -q '^\[include Helper-Script/dxc_sensor.cfg\]' "$PRINTER_CFG" 2>/dev/null ;;
    OPT_CFS_SPEED_FIX) [ -f "$HS_BACKUP_FOLDER/box_control.pyc.orig" ] ;;
    OPT_CFS_VOL_FIX) [ -f "$HS_BACKUP_FOLDER/box.cfg.orig" ] ;;
    OPT_FLY_LLL)
      if [ "$var" = "CFS-C" ]; then
        grep -q '^\[include Helper-Script/cfs_lll_safety.cfg\]' "$PRINTER_CFG" 2>/dev/null
      else
        grep -q '^\[include Helper-Script/lll_plus_sensor_nocfs.cfg\]' "$PRINTER_CFG" 2>/dev/null
      fi
      ;;
    OPT_CHASSIS_LIGHT) grep -q '^\[output_pin LED\]' "$PRINTER_CFG" 2>/dev/null ;;
    OPT_CAM_MOONRAKER) grep -q '^\[webcam chassis\]\|^\[webcam usb\]' "$MOONRAKER_CFG" 2>/dev/null ;;
    OPT_CAM_CONTROL) [ -f "$CAMERA_SETTINGS_FILE" ] ;;
    OPT_TIMELAPSE) [ -f "$TIMELAPSE_FILE" ] ;;
    OPT_CALIB_TOOLBOX) grep -q '^\[include Helper-Script/calib_tool_box.cfg\]' "$PRINTER_CFG" 2>/dev/null ;;
    OPT_CFS_WEB_ADDON) [ -f "${MAINSAIL_FOLDER}/k1c-cfs-panel.js" ] || [ -f "${FLUIDD_FOLDER}/k1c-cfs-panel.js" ] ;;
    OPT_MOTOR_SOUND) [ -f "$MOTOR_SOUND_TARGET_FILE" ] ;;
    OPT_USEFUL_MACROS) [ -f "$USEFUL_MACROS_FILE" ] ;;
    OPT_GIT_BACKUP) [ -f "$GIT_BACKUP_FILE" ] ;;
    OPT_OCTOEVERYWHERE) [ -d "$OCTOEVERYWHERE_FOLDER" ] ;;
    OPT_OBICO) [ -d "$MOONRAKER_OBICO_FOLDER" ] ;;
    OPT_GUPPYFLO) [ -d "$GUPPYFLO_FOLDER" ] ;;
    OPT_MOBILERAKER) [ -d "$MOBILERAKER_COMPANION_FOLDER" ] ;;
    OPT_OCTOAPP) [ -d "$OCTOAPP_COMPANION_FOLDER" ] ;;
    OPT_SIMPLYPRINT) grep -q '^\[simplyprint\]' "$MOONRAKER_CFG" 2>/dev/null ;;
    OPT_PREVENT_CFG_UPDATE) [ -f "$KLIPPER_SERVICE_DISABLED" ] ;;
    *) return 1 ;;
  esac
}

function get_option_label(){
  case "$1" in
    OPT_MOONRAKER) echo "Moonraker & Nginx" ;;
    OPT_FLUIDD) echo "Fluidd" ;;
    OPT_MAINSAIL) echo "Mainsail" ;;
    OPT_ENTWARE) echo "Entware" ;;
    OPT_GCODE_SHELL) echo "Klipper Gcode Shell Command" ;;
    OPT_RECCON) echo "Recovery Console (reccon)" ;;
    OPT_INPUT_SHAPER) echo "Restore Input Shapers" ;;
    OPT_EXTENDED_GCODE) echo "Extended Gcode Params" ;;
    OPT_DXC_SENSOR) echo "Toolhead Filament Sensor (DXC / Extruder)" ;;
    OPT_CFS_SPEED_FIX) echo "CFS-C Universal Purge Speed Fix" ;;
    OPT_CFS_VOL_FIX) echo "CFS-C Purge Volume Fix (Prime Tower)" ;;
    OPT_FLY_LLL) echo "FLY-LLL Plus Safety / Buffer Sensor" ;;
    OPT_CHASSIS_LIGHT) echo "Chassis Light Control (PA8)" ;;
    OPT_CAM_MOONRAKER) echo "Camera Settings in Moonraker" ;;
    OPT_CAM_CONTROL) echo "Camera Settings Control" ;;
    OPT_TIMELAPSE) echo "Moonraker Timelapse" ;;
    OPT_CALIB_TOOLBOX) echo "Creality Calibration Toolbox" ;;
    OPT_CFS_WEB_ADDON) echo "CFS-C / Spool Holder Web Addon" ;;
    OPT_MOTOR_SOUND) echo "Motor Sound Support" ;;
    OPT_USEFUL_MACROS) echo "Useful Macros" ;;
    OPT_GIT_BACKUP) echo "Git Backup" ;;
    OPT_OCTOEVERYWHERE) echo "OctoEverywhere" ;;
    OPT_OBICO) echo "Moonraker Obico" ;;
    OPT_GUPPYFLO) echo "GuppyFLO" ;;
    OPT_MOBILERAKER) echo "Mobileraker Companion" ;;
    OPT_OCTOAPP) echo "OctoApp Companion" ;;
    OPT_SIMPLYPRINT) echo "SimplyPrint" ;;
    OPT_PREVENT_CFG_UPDATE) echo "Prevent updating Klipper configuration files" ;;
    *) echo "$1" ;;
  esac
}

function restore_installed_options_profile(){
  top_line
  title 'Restore Installed Options Profile' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Reinstalls saved Helper-Script options in strict dependency  ${white}│"
  echo -e " │ ${cyan}order (Essentials -> Utilities -> Hardware -> Remote Access).${white}│"
  hr
  bottom_line

  # Pull profiles from USB if attached and missing locally
  local usb_mnt=""
  if command -v detect_usb_mount >/dev/null 2>&1; then
    usb_mnt="$(detect_usb_mount 2>/dev/null || true)"
  fi
  if [ -n "$usb_mnt" ]; then
    local pf
    for pf in options_profile_CFS-C.env options_profile_STANDARD.env; do
      if [ -f "$usb_mnt/helper-script-ota-backup/$pf" ] && [ ! -f "$OPT_PROFILE_DIR/$pf" ]; then
        mkdir -p "$OPT_PROFILE_DIR"
        cp -f "$usb_mnt/helper-script-ota-backup/$pf" "$OPT_PROFILE_DIR/$pf"
        echo -e " ${green}Loaded profile from USB:${white} ${cyan}$pf${white}"
      fi
    done
  fi

  local has_cfs=0 has_std=0
  [ -f "$OPT_PROFILE_DIR/options_profile_CFS-C.env" ] && has_cfs=1
  [ -f "$OPT_PROFILE_DIR/options_profile_STANDARD.env" ] && has_std=1

  if [ "$has_cfs" -eq 0 ] && [ "$has_std" -eq 0 ]; then
    error_msg "No saved Options Profile found (neither internal nor on USB)!"
    return
  fi

  local selected_file=""
  if [ "$has_cfs" -eq 1 ] && [ "$has_std" -eq 1 ]; then
    echo
    echo -e " Available saved profiles:"
    echo -e "  ${yellow}1)${white} CFS-C Profile"
    echo -e "  ${yellow}2)${white} STANDARD (Non-CFS) Profile"
    echo
    local pchoice
    read -p " ${white}Choose profile to restore (${yellow}1${white}/${yellow}2${white}): ${yellow}" pchoice
    echo -e "${white}"
    case "$pchoice" in
      1) selected_file="$OPT_PROFILE_DIR/options_profile_CFS-C.env" ;;
      2) selected_file="$OPT_PROFILE_DIR/options_profile_STANDARD.env" ;;
      *) error_msg "Canceled."; return ;;
    esac
  elif [ "$has_cfs" -eq 1 ]; then
    selected_file="$OPT_PROFILE_DIR/options_profile_CFS-C.env"
  else
    selected_file="$OPT_PROFILE_DIR/options_profile_STANDARD.env"
  fi

  # Load profile flags
  . "$selected_file"

  local current_hw
  current_hw="$(detect_active_profile_variant)"
  if [ "$PROFILE_VARIANT" = "STANDARD" ] && [ "$current_hw" = "CFS-C" ]; then
    echo
    echo -e " ${yellow}Upgrade-Merge detected:${white} Saved profile is ${cyan}STANDARD (Non-CFS)${white}, active printer is ${green}CFS-C${white}."
    local upg_yn
    read -p " ${white}Upgrade & merge profile to ${green}CFS-C${white} (CFS-C Web Addon, FLY-LLL Safety & Purge Fixes)? (${yellow}y${white}/${yellow}n${white}): ${yellow}" upg_yn
    echo -e "${white}"
    case "$upg_yn" in
      Y|y)
        PROFILE_VARIANT="CFS-C"
        OPT_CFS_SPEED_FIX=1
        OPT_CFS_VOL_FIX=1
        echo -e " ${green}Profile upgraded to CFS-C mode!${white}"
        ;;
    esac
  fi

  # Strict dependency order list
  local ORDERED_KEYS="OPT_MOONRAKER OPT_FLUIDD OPT_MAINSAIL OPT_ENTWARE OPT_GCODE_SHELL OPT_RECCON OPT_INPUT_SHAPER OPT_EXTENDED_GCODE OPT_DXC_SENSOR OPT_CFS_SPEED_FIX OPT_CFS_VOL_FIX OPT_FLY_LLL OPT_CHASSIS_LIGHT OPT_CAM_MOONRAKER OPT_CAM_CONTROL OPT_TIMELAPSE OPT_CALIB_TOOLBOX OPT_CFS_WEB_ADDON OPT_MOTOR_SOUND OPT_USEFUL_MACROS OPT_GIT_BACKUP OPT_OCTOEVERYWHERE OPT_OBICO OPT_GUPPYFLO OPT_MOBILERAKER OPT_OCTOAPP OPT_SIMPLYPRINT OPT_PREVENT_CFG_UPDATE"

  local active_keys=""
  local idx=0
  echo
  echo -e " ${cyan}Saved Profile (${PROFILE_VARIANT} - ${CREATED_AT}):${white}"
  local k val lbl status_tag
  for k in $ORDERED_KEYS; do
    eval val="\${$k:-0}"
    if [ "$val" = "1" ]; then
      idx=$((idx + 1))
      active_keys="$active_keys $k"
      lbl="$(get_option_label "$k")"
      if is_option_currently_installed "$k" "$PROFILE_VARIANT"; then
        status_tag="${green}[INSTALLED]${white}"
      else
        status_tag="${yellow}[MISSING]${white}"
      fi
      printf "  ${yellow}%2d)${white} %-46s %b\n" "$idx" "$lbl" "$status_tag"
    fi
  done

  if [ "$idx" -eq 0 ]; then
    error_msg "No active options recorded in this profile."
    return
  fi

  echo
  echo -e " ${cyan}Restore Options:${white}"
  echo -e "  ${yellow}a)${white} Reinstall ALL missing options automatically (in dependency order)"
  echo -e "  ${yellow}s)${white} Select specific option numbers (e.g. ${yellow}1 3 5${white} - keeps dependency order)"
  echo -e "  ${yellow}q)${white} Cancel"
  echo
  local mode_sel
  read -p " ${white}Choose action (${yellow}a${white}/${yellow}s${white}/${yellow}q${white}): ${yellow}" mode_sel
  echo -e "${white}"

  local chosen_numbers=""
  case "$mode_sel" in
    A|a)
      local i=1
      while [ "$i" -le "$idx" ]; do
        chosen_numbers="$chosen_numbers $i"
        i=$((i + 1))
      done
      ;;
    S|s)
      read -p " ${white}Enter option numbers separated by spaces: ${yellow}" chosen_numbers
      echo -e "${white}"
      ;;
    *)
      echo -e " ${yellow}Restore canceled.${white}"
      return
      ;;
  esac

  # Iterate in strict dependency order and run selected missing installers
  local cur_i=0
  for k in $active_keys; do
    cur_i=$((cur_i + 1))
    local matched=0 n
    for n in $chosen_numbers; do
      [ "$n" = "$cur_i" ] && matched=1
    done
    [ "$matched" -eq 0 ] && continue

    lbl="$(get_option_label "$k")"
    if is_option_currently_installed "$k" "$PROFILE_VARIANT"; then
      echo -e " ${green}Skipping (already installed):${white} $lbl"
      continue
    fi

    echo
    echo -e " ${cyan}>>> Installing [$cur_i/$idx]: ${yellow}$lbl${white}"
    execute_option_installer "$k" "$PROFILE_VARIANT" || true
  done

  echo
  ok_msg "Options Profile restore run completed!"
}
