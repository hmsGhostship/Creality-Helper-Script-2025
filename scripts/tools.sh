#!/bin/sh

set -e

function prevent_updating_klipper_files_message(){
  top_line
  title 'Prevent updating Klipper configuration files' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}This prevents updating Klipper configuration files when      ${white}│"
  echo -e " │ ${cyan}Klipper restarts.                                            ${white}│"
  hr
  bottom_line
}

function allow_updating_klipper_files_message(){
  top_line
  title 'Allow updating Klipper configuration files' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}This allows updating Klipper configuration files when        ${white}│"
  echo -e " │ ${cyan}Klipper restarts.                                            ${white}│"
  hr
  bottom_line
}

function printing_gcode_from_folder_message(){
  top_line
  title 'Fix printing Gcode files from folder' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}From Fluidd or Mainsail it's possible to classify your Gcode ${white}│"
  echo -e " │ ${cyan}files in folders but by default it's not possible to start   ${white}│"
  echo -e " │ ${cyan}a print from a folder. This fix allows that.                 ${white}│"
  hr
  bottom_line
}

function enable_camera_settings_message(){
  top_line
  title 'Enable camera settings in Moonraker' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}This allows to enable camera settings in Moonraker for       ${white}│"
  echo -e " │ ${cyan}Fluidd and Mainsail Web interfaces.                          ${white}│"
  hr
  bottom_line
}

function disable_camera_settings_message(){
  top_line
  title 'Disable camera settings in Moonraker' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}This allows to disable camera settings in Moonraker for      ${white}│"
  echo -e " │ ${cyan}Fluidd and Mainsail Web interfaces.                          ${white}│"
  hr
  bottom_line
}

function add_chassis_light_control_message(){
  top_line
  title 'Add chassis light control' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}This adds K1 2025 chassis light control to printer.cfg.      ${white}│"
  echo -e " │ ${cyan}The LED is connected to PA8.                                 ${white}│"
  hr
  bottom_line
}

function restore_previous_firmware_message(){
  top_line
  title 'Restore a previous firmware' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}To restore a previous firmware, follow these steps and       ${white}│"
  echo -e " │ ${cyan}validate your choice:                                        ${white}│"
  echo -e " │                                                              │"
  echo -e " │ ${cyan}1. ${white}Copy the firmware (.img) you want to update to the root   ${white}│"
  echo -e " │    of a USB drive.                                           ${white}│"
  echo -e " │ ${cyan}2. ${white}Make sure there is only this file on the USB drive.       ${white}│"
  echo -e " │ ${cyan}3. ${white}Insert the USB drive into the printer.                    ${white}│"
  hr
  bottom_line
}

function reset_factory_settings_message(){
  top_line
  title 'Reset factory settings' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}This the best way to reset the printer to its factory        ${white}│"
  echo -e " │ ${cyan}settings.                                                    ${white}│"
  echo -e " │ ${cyan}Note that the Factory Reset function in the screen menu      ${white}│"
  echo -e " │ ${cyan}settings only performs a partial reset.                      ${white}│"
  hr
  echo -e " │ ${cyan}Note: After factory reset all features already been          ${white}│"
  echo -e " │ ${cyan}installed with Creality Helper Script must be reinstalled.   ${white}│"
  hr
  bottom_line
}

# Basename of the active Klipper init script (S55… or CS55… on newer K1C firmware), or empty.
klipper_init_script_basename() {
  if [ -f "$INITD_FOLDER/S55klipper_service" ]; then
    echo S55klipper_service
  elif [ -f "$INITD_FOLDER/CS55klipper_service" ]; then
    echo CS55klipper_service
  fi
}

klipper_disabled_backup_basename() {
  if [ -f "$INITD_FOLDER/disabled.S55klipper_service" ]; then
    echo disabled.S55klipper_service
  elif [ -f "$INITD_FOLDER/disabled.CS55klipper_service" ]; then
    echo disabled.CS55klipper_service
  fi
}

function prevent_updating_klipper_files(){
  prevent_updating_klipper_files_message
  local yn
  while true; do
    read -p "${white} Do you want to prevent updating ${green}Klipper configuration files ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        klipper_init="$(klipper_init_script_basename)"
        if [ -z "$klipper_init" ]; then
          error_msg "Klipper init script not found in ${INITD_FOLDER} (expected S55klipper_service or CS55klipper_service)."
          return
        fi
        echo -e "Info: Backup file..."
        mv "$INITD_FOLDER/$klipper_init" "$INITD_FOLDER/disabled.$klipper_init"
        echo -e "Info: Copying file..."
        cp "$KLIPPER_SERVICE_URL" "$INITD_FOLDER/$klipper_init"
        echo -e "Info: Applying permissions..."
        chmod 755 "$INITD_FOLDER/$klipper_init"
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Klipper configuration files will no longer be updated when Klipper restarts!"
        return;;
      N|n)
        error_msg "Preventing canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function allow_updating_klipper_files(){
  allow_updating_klipper_files_message
  local yn
  while true; do
    read -p "${white} Do you want to allow updating ${green}Klipper configuration files ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        disabled_backup="$(klipper_disabled_backup_basename)"
        if [ -z "$disabled_backup" ]; then
          error_msg "No disabled Klipper init backup found in ${INITD_FOLDER}."
          return
        fi
        klipper_init="${disabled_backup#disabled.}"
        echo -e "Info: Restoring file..."
        rm -f "$INITD_FOLDER/$klipper_init"
        mv "$INITD_FOLDER/$disabled_backup" "$INITD_FOLDER/$klipper_init"
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Klipper configuration files will be updated when Klipper restarts!"
        return;;
      N|n)
        error_msg "Authorization canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function printing_gcode_from_folder(){
  printing_gcode_from_folder_message
  local yn
  while true; do
    read -p "${white} Do you want to apply fix for ${green}printing Gcode files from folder ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Deleting files..."
        if [ -f "$KLIPPER_KLIPPY_FOLDER"/gcode.py ]; then
          rm -f "$KLIPPER_KLIPPY_FOLDER"/gcode.py
          rm -f "$KLIPPER_KLIPPY_FOLDER"/gcode.pyc
        fi
        echo -e "Info: Linking files..."
        if [ "$model" = "K1" ]; then
          ln -sf "$KLIPPER_GCODE_URL" "$KLIPPER_KLIPPY_FOLDER"/gcode.py
        fi
        if [ "$model" = "3V3" ]; then
          ln -sf "$KLIPPER_GCODE_3V3_URL" "$KLIPPER_KLIPPY_FOLDER"/gcode.py
        fi
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Fix has been applied successfully!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function enable_camera_settings(){
  enable_camera_settings_message
  local yn
  while true; do
    read -p "${white} Do you want to enable ${green}camera settings in Moonraker ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        if [ "$model" = "K1_2025" ] || [ "$model" = "K1_2025_CFS-C" ]; then
          if [ -f "$BUILTIN_CAMERA_FILE" ] || [ -f "$BUILTIN_CAMERA_LEGACY_FILE" ]; then
            configure_builtin_camera_k1_2025
          fi
          if [ -f "$USB_CAMERA_FILE" ] || [ -f "$USB_CAMERA_LEGACY_FILE" ]; then
            configure_usb_camera_k1_2025
          fi
        elif grep -q "#\[webcam Camera\]" "$MOONRAKER_CFG" ; then
          echo -e "Info: Enabling camera settings in moonraker.conf file..."
          sed -i -e 's/^\s*#[[:space:]]*\[webcam Camera\]/[webcam Camera]/' -e '/^\[webcam Camera\]/,/^\s*$/ s/^\(\s*\)#/\1/' "$MOONRAKER_CFG"
        else
          echo -e "Info: Camera settings are already enabled in moonraker.conf file..."        
        fi
        local ip_address
        ip_address="$(check_ipaddress)"
        if grep -q "stream_url: http://xxx.xxx.xxx.xxx:8080/?action=stream" "$MOONRAKER_CFG"; then
          echo -e "Info: Replacing stream_url IP address..."
          sed -i "s|http://xxx.xxx.xxx.xxx:|http://$ip_address:|g" "$MOONRAKER_CFG"
        fi
        if grep -q "snapshot_url: http://xxx.xxx.xxx.xxx:8080/?action=snapshot" "$MOONRAKER_CFG"; then
          echo -e "Info: Replacing snapshot_url IP address..."
          sed -i "s|http://xxx.xxx.xxx.xxx:|http://$ip_address:|g" "$MOONRAKER_CFG"
        fi
        echo -e "Info: Restarting Moonraker service..."
        stop_moonraker
        start_moonraker
        ok_msg "Camera settings have been enabled in Moonraker successfully!"
        return;;
      N|n)
        error_msg "Activation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function disable_camera_settings(){
  disable_camera_settings_message
  local yn
  while true; do
    read -p "${white} Do you want to disable ${green}camera settings in Moonraker ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        if [ "$model" = "K1_2025" ] || [ "$model" = "K1_2025_CFS-C" ]; then
          if grep -q "^\[webcam chassis\]\|^\[webcam usb\]" "$MOONRAKER_CFG"; then
            echo -e "Info: Disabling camera settings in moonraker.conf file..."
            sed -i '/^\[webcam chassis\]/,/^$/d' "$MOONRAKER_CFG"
            sed -i '/^\[webcam usb\]/,/^$/d' "$MOONRAKER_CFG"
          else
            echo -e "Info: Camera settings are already disabled in moonraker.conf file..."
          fi
        elif grep -q "\[webcam Camera\]" "$MOONRAKER_CFG" ; then
          echo -e "Info: Disabling camera settings in moonraker.conf file..."
          sed -i '/^\[webcam Camera\]/,/^\s*$/ s/^\(\s*\)\([^#]\)/#\1\2/' "$MOONRAKER_CFG"
        else
          echo -e "Info: Camera settings are already disabled in moonraker.conf file..."
        fi
        echo -e "Info: Restarting Moonraker service..."
        stop_moonraker
        start_moonraker
        ok_msg "Camera settings have been disabled in Moonraker successfully!"
        return;;
      N|n)
        error_msg "Deactivation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function add_chassis_light_control(){
  add_chassis_light_control_message
  local yn
  while true; do
    read -p "${white} Do you want to add ${green}chassis light control ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        if grep -q "^\[output_pin LED\]" "$PRINTER_CFG"; then
          error_msg "Chassis light control is already present in printer.cfg!"
          return
        fi
        echo -e "Info: Adding chassis light control to printer.cfg..."
        awk '
          BEGIN { added = 0 }
          /^\#\*\# <---------------------- SAVE_CONFIG ---------------------->/ && !added {
            print ""
            print "[output_pin LED]"
            print "pin: PA8"
            print "pwm: True"
            print "cycle_time: 0.001"
            print "value: 1"
            print "shutdown_value: 0"
            added = 1
          }
          { print }
          END {
            if (!added) {
              print ""
              print "[output_pin LED]"
              print "pin: PA8"
              print "pwm: True"
              print "cycle_time: 0.001"
              print "value: 1"
              print "shutdown_value: 0"
            }
          }
        ' "$PRINTER_CFG" > "$PRINTER_CFG.tmp" && mv "$PRINTER_CFG.tmp" "$PRINTER_CFG"
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Chassis light control has been added successfully!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function restart_nginx_action(){
  echo
  local yn
  while true; do
    restart_msg "Nginx service" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        stop_nginx
        start_nginx
        ok_msg "Nginx service has been restarted successfully!"
        return;;
      N|n)
        error_msg "Restart canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function restart_moonraker_action(){
  echo
  local yn
  while true; do
    restart_msg "Moonraker service" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        stop_moonraker
        start_moonraker
        ok_msg "Moonraker service has been restarted successfully!"
        return;;
      N|n)
        error_msg "Restart canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function restart_klipper_action(){
  echo
  local yn
  while true; do
    restart_msg "Klipper service" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        restart_klipper
        ok_msg "Klipper service has been restarted successfully!"
        return;;
      N|n)
        error_msg "Restart canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function update_entware_packages(){
  echo
  local yn
  while true; do
    read -p "${white} Are you sure you want to update ${green}Entware packages ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Updating packages list..."
        "$ENTWARE_FILE" update
        echo -e "Info: Updating packages..."
        "$ENTWARE_FILE" upgrade
        ok_msg "Entware packages have been updated!"
        return;;
      N|n)
        error_msg "Updating canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function clear_cache(){
  echo
  local yn gc_ok
  while true; do
    read -p "${white} Are you sure you want to ${green}clear cache ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn || yn=n
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Clearing root partition cache..."
        rm -rf /root/.cache
        echo -e "Info: Clearing git cache..."
        gc_ok=1
        git -C "${HELPER_SCRIPT_FOLDER}" gc --aggressive --prune=all || { gc_ok=0; error_msg "Git cache could not be cleared, continuing..."; }
        echo -e "Info: Clearing pip cache..."
        # The printer's stock /usr/bin/pip is 19.3.1, older than the `pip
        # cache` subcommand (pip 20.1), and exits 1 with 'unknown command
        # "cache"'; a newer pip exits 1 with "No matching packages" because
        # /root/.cache, where its cache lives, was removed just above. Under
        # helper.sh's global `set -e` either exit killed the whole helper.
        pip cache purge >/dev/null 2>&1 || true
        if [ "${gc_ok}" = 1 ]; then
          ok_msg "Cache has been cleared!"
        else
          ok_msg "Cache has been cleared, except the git cache!"
        fi
        return;;
      N|n)
        error_msg "Clearing cache canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function clear_logs(){
  echo
  local yn
  while true; do
    read -p "${white} Are you sure you want to clear ${green}logs files ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Clearing logs files..."
        rm -f "$USR_DATA"/creality/userdata/log/*.log
        rm -f "$USR_DATA"/creality/userdata/log/*.gz
        rm -f "$USR_DATA"/creality/userdata/fault_code/*
        rm -f "$PRINTER_DATA_FOLDER"/logs/*
        if [ -d "$GUPPYFLO_FOLDER" ]; then
          rm -f "$GUPPYFLO_FOLDER"/guppyflo.log
        fi
        ok_msg "Logs files have been cleared!"
        return;;
      N|n)
        error_msg "Clearing logs files canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function restore_previous_firmware(){
  restore_previous_firmware_message
  local yn
  while true; do
    read -p "${white} Do you want to restore a previous firmware ? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
    case "${yn}" in
      Y|y)
        if ls /tmp/udisk/sda1/*.img 1> /dev/null 2>&1; then
          echo -e "${white}"
          echo "Info: Restoring firmware..."
          rm -rf /overlay/upper/*
          /etc/ota_bin/local_ota_update.sh /tmp/udisk/sda1/*.img
          ok_msg "Firmware has been restored! Please reboot your printer."
          exit 0
        else
          error_msg "No .img file found on the USB drive. Restoration canceled!"
        fi
        return;;
      N|n)
        error_msg "Restoration canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function reset_factory_settings(){
  reset_factory_settings_message
  local yn
  while true; do
    read -p "${white} Are you sure you want to ${green}reset factory settings ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        "$INITD_FOLDER"/S58factoryreset reset
        ;;
      N|n)
        error_msg "Reset canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function ensure_respond_module(){
  if [ -f "$PRINTER_CFG" ]; then
    if grep -q "^\[respond\]" "$PRINTER_CFG"; then
      echo -e "Info: [respond] module is already enabled in printer.cfg..."
    elif grep -q "^# CreateDate:" "$PRINTER_CFG" ; then
      echo -e "Info: Adding [respond] module under CreateDate block..."
      sed -i '/^# CreateDate:/a \[respond\]' "$PRINTER_CFG"
    elif grep -q "\[include printer_params\.cfg\]" "$PRINTER_CFG" ; then
      echo -e "Info: Adding [respond] module under printer_params include..."
      sed -i '/\[include printer_params\.cfg\]/a \[respond\]' "$PRINTER_CFG"
    else
      echo -e "Info: Adding [respond] module at the top of printer.cfg..."
      { echo -e "[respond]\n"; cat "$PRINTER_CFG"; } > "$PRINTER_CFG.hs_tmp" && cat "$PRINTER_CFG.hs_tmp" > "$PRINTER_CFG" && rm -f "$PRINTER_CFG.hs_tmp"
    fi
  fi
}

# Liefert den aktuell verfügbaren Arbeitsspeicher in MB (inkl. freigebbarem Cache)
function get_available_ram_mb() {
  local avail_kb
  avail_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null)
  if [ -z "$avail_kb" ]; then
    avail_kb=$(free | awk '/^Mem:/ {print $7}')
  fi
  echo $((avail_kb / 1024))
}

# Before installation, checks whether there is enough free RAM for the service:
# - Hard block if remaining RAM after install would drop below 15 MB (OOM crash risk)
# - Warning (y/n) if remaining RAM after install would be between 15 MB and 24 MB
# - Silent pass if at least 25 MB safety reserve remains
# Usage: check_ram_requirement "module_name" <required_RAM_in_MB>
function check_ram_requirement() {
  local module_name="$1"
  local required_mb="${2:-25}"
  local hard_min_reserve_mb=15
  local soft_reserve_mb=25
  local avail_mb expected_after_mb
  avail_mb=$(get_available_ram_mb)
  expected_after_mb=$((avail_mb - required_mb))

  # 1. Everything is in the clear (at least 25 MB of RAM remaining after installation)
  if [ "$expected_after_mb" -ge "$soft_reserve_mb" ]; then
    return 0
  fi

  echo
  echo -e " ${yellow}Memory Check for ${cyan}${module_name}${yellow}:${white}"
  echo -e " ${white}- Currently available RAM:       ${cyan}${avail_mb} MB${white}"
  echo -e " ${white}- Estimated usage of module:     ${cyan}~${required_mb} MB${white}"
  echo -e " ${white}- Expected free RAM afterwards:  ${cyan}~${expected_after_mb} MB${white}"
  echo

  # 2. Hard limit: Less than 15 MB of remaining RAM -> Risk of a crash due to the OOM killer!
  if [ "$expected_after_mb" -lt "$hard_min_reserve_mb" ]; then
    error_msg "Installation blocked! Remaining RAM (~${expected_after_mb} MB) would be below the safe minimum of ${hard_min_reserve_mb} MB."
    echo -e " ${cyan}Reason: Klipper needs at least ${hard_min_reserve_mb} MB free RAM during printing and calibration.${white}"
    echo -e " ${cyan}Solution: Remove other remote companions (e.g. Obico/Mobileraker) or disable Creality Stock Services first.${white}"
    echo
    return 1
  fi

  # 3. Yellow Zone: Between 15 MB and 24 MB of remaining RAM -> Warning + explicit confirmation
  echo -e " ${yellow}Warning: Remaining RAM (~${expected_after_mb} MB) will be tight (recommended reserve: ${soft_reserve_mb} MB).${white}"
  echo -e " ${yellow}Heavy tasks like SHAPER_CALIBRATE or large prints could become unstable.${white}"
  echo -e " ${cyan}Tip: Disable Creality Stock Services or unused companions to free up more RAM.${white}"
  echo
  local ram_yn
  while true; do
    read -p " ${white}Do you still want to continue installing ${green}${module_name}${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" ram_yn
    echo -e "${white}"
    case "${ram_yn}" in
      Y|y) return 0;;
      N|n)
        error_msg "Installation of ${module_name} canceled due to low memory."
        return 1;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

