#!/bin/sh

set -e

OTA_BACKUP_DIR="/usr/data/helper-script-ota-backup"

function detect_usb_mount(){
  local mnt
  for mnt in /media/creality/sda1 /media/creality/sdb1 /media/creality/sda /tmp/udisk/sda1 /tmp/udisk/sdb1 /mnt/UDISK /media/usb0; do
    if [ -d "$mnt" ] && grep -q " ${mnt} " /proc/mounts 2>/dev/null; then
      if grep " ${mnt} " /proc/mounts 2>/dev/null | grep -q " ro,"; then
        mount -o remount,rw "$mnt" 2>/dev/null || true
      fi
      if grep " ${mnt} " /proc/mounts 2>/dev/null | grep -q " rw," && [ -w "$mnt" ]; then
        echo "$mnt"
        return 0
      fi
    fi
  done
  return 1
}

function prompt_plug_usb_if_missing(){
  local usb_mnt
  usb_mnt="$(detect_usb_mount 2>/dev/null || true)"
  if [ -n "$usb_mnt" ]; then
    echo "$usb_mnt"
    return 0
  fi
  local plug_yn
  while true; do
    read -p " ${yellow}No USB drive detected.${white} Do you want to plug in a USB drive now? (${yellow}y${white}/${yellow}n${white}): ${yellow}" plug_yn
    echo -e "${white}"
    case "${plug_yn}" in
      Y|y)
        read -p " ${cyan}Plug in the USB drive, wait 2 seconds, then press Enter...${white}" _dummy
        sleep 1
        usb_mnt="$(detect_usb_mount 2>/dev/null || true)"
        if [ -n "$usb_mnt" ]; then
          echo -e " ${green}USB drive detected:${white} ${usb_mnt}"
          echo "$usb_mnt"
          return 0
        else
          error_msg "Still no USB drive detected!"
        fi
        ;;
      N|n)
        return 1;;
      *)
        error_msg "Please select y or n!";;
    esac
  done
}

function backup_ota_state_message(){
  top_line
  title 'Backup Helper-Script State (OTA Safe)' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Saves all Helper-Script configs, Moonraker DB, init scripts,   ${white}│"
  echo -e " │ ${cyan}and disabled Creality service states to /usr/data so you can   ${white}│"
  echo -e " │ ${cyan}restore your exact setup after a Creality firmware update.     ${white}│"
  inner_line
  local _u
  _u="$(detect_usb_mount 2>/dev/null || true)"
  if [ -n "$_u" ]; then
    printf " │ ${green}USB Drive:${white} %-51s │\n" "Detected (${_u})"
  else
    printf " │ ${yellow}USB Drive:${white} %-51s │\n" "Not detected (optional for USB backup)"
  fi
  hr
  bottom_line
}

function restore_ota_state_message(){
  top_line
  title 'Restore Helper-Script State (After FW Update)' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Restores your saved Helper-Script configs, init scripts,       ${white}│"
  echo -e " │ ${cyan}camera routing, and disabled Creality stock services after     ${white}│"
  echo -e " │ ${cyan}a Creality firmware update.                                    ${white}│"
  inner_line
  local _u
  _u="$(detect_usb_mount 2>/dev/null || true)"
  if [ -n "$_u" ]; then
    printf " │ ${green}USB Drive:${white} %-51s │\n" "Detected (${_u})"
  else
    printf " │ ${yellow}USB Drive:${white} %-51s │\n" "Not detected (optional for USB restore)"
  fi
  hr
  bottom_line
}


function run_ota_state_backup_core(){
  mkdir -p "$OTA_BACKUP_DIR"
  rm -f "$OTA_BACKUP_DIR/ota_configs.tar.gz" "$OTA_BACKUP_DIR/ota_initd.tar.gz" "$OTA_BACKUP_DIR/ota_state.env"

  echo -e "Info: Saving Klipper/Moonraker configs, databases & Helper-Script app configs..."
  local cfg_items=""
  local sub
  for sub in printer_data/config printer_data/database go2rtc nginx guppyscreen kamp KAMP_Settings mobileraker_companion moonraker-obico moonraker-telegram-bot spoolman crowsnest guppyflo wpa_supplicant.conf; do
    [ -e "/usr/data/$sub" ] && cfg_items="$cfg_items $sub"
  done
  if [ -d "/usr/data/octoeverywhere" ]; then
    local oe_item
    for oe_item in /usr/data/octoeverywhere/*.json /usr/data/octoeverywhere/*.conf /usr/data/octoeverywhere/*.cfg; do
      [ -f "$oe_item" ] && cfg_items="$cfg_items octoeverywhere/$(basename "$oe_item")"
    done
  fi
  if [ -n "$cfg_items" ]; then
    tar -czf "$OTA_BACKUP_DIR/ota_configs.tar.gz" -C /usr/data $cfg_items
  fi

  echo -e "Info: Saving custom Klipper extras, system binaries & crontabs..."
  if [ -d "$KLIPPY_EXTRAS" ]; then
    local extra_list=""
    local ef eb
    for ef in "$KLIPPY_EXTRAS"/*; do
      [ -e "$ef" ] || [ -L "$ef" ] || continue
      eb="$(basename "$ef")"
      if [ -L "$ef" ] || [ "$ef" -nt "$KLIPPY_EXTRAS/__init__.pyc" ] || [ "$eb" = "cfs_material_db.py" ] || [ "$eb" = "box_control.pyc" ]; then
        extra_list="$extra_list $eb"
      fi
    done
    if [ -n "$extra_list" ]; then
      tar -czf "$OTA_BACKUP_DIR/ota_extras.tar.gz" -C "$KLIPPY_EXTRAS" $extra_list
    fi
  fi

  local sys_items=""
  [ -d "/etc/crontabs" ] && sys_items="$sys_items etc/crontabs"
  [ -f "/etc/mdev.conf" ] && sys_items="$sys_items etc/mdev.conf"
  [ -d "/usr/apps/overlay" ] && sys_items="$sys_items usr/apps/overlay"
  local ub
  for ub in /usr/bin/* /usr/local/bin/*; do
    [ -L "$ub" ] || continue
    if readlink "$ub" 2>/dev/null | grep -q "^/usr/data/"; then
      sys_items="$sys_items ${ub#/}"
    fi
  done
  if [ -n "$sys_items" ]; then
    tar -czf "$OTA_BACKUP_DIR/ota_sysfiles.tar.gz" -C / $sys_items 2>/dev/null || true
  fi

  echo -e "Info: Saving init scripts & disabled service markers..."
  if [ -d "$INITD_FOLDER" ]; then
    tar -czf "$OTA_BACKUP_DIR/ota_initd.tar.gz" -C "$INITD_FOLDER" .
  fi

  echo -e "Info: Recording active modules & disabled stock services..."
  {
    echo "BACKUP_DATE='$(date '+%Y-%m-%d %H:%M:%S')'"
    echo "BACKUP_MODEL='${model}'"
    echo "GO2RTC_MODE='$(get_go2rtc_mode_k1_2025 2>/dev/null)'"
    echo "HAS_USB_CAM=$([ -f "$USB_CAMERA_FILE" ] || [ -f "$USB_CAMERA_LEGACY_FILE" ] && echo 1 || echo 0)"
    echo "HAS_BUILTIN_CAM=$([ -f "$BUILTIN_CAMERA_FILE" ] || [ -f "$BUILTIN_CAMERA_LEGACY_FILE" ] && echo 1 || echo 0)"
    echo "HAS_CFS_MAINSAIL=$([ -f "${MAINSAIL_FOLDER}/k1c-cfs-panel.js" ] && echo 1 || echo 0)"
    echo "HAS_CFS_FLUIDD=$([ -f "${FLUIDD_FOLDER}/k1c-cfs-panel.js" ] && echo 1 || echo 0)"
    local app_list=""
    local app_dir
    for app_dir in moonraker mainsail fluidd guppyscreen octoeverywhere moonraker-obico mobileraker_companion moonraker-telegram-bot spoolman crowsnest guppyflo; do
      [ -d "/usr/data/$app_dir" ] && app_list="$app_list $app_dir"
    done
    [ -f "/usr/data/entware_opt_mount.img" ] && app_list="$app_list entware_opt_mount.img"
    echo "INSTALLED_APPS='${app_list# }'"
    local disabled_list=""
    local f
    for f in "$INITD_FOLDER"/disabled.*; do
      [ -e "$f" ] || continue
      disabled_list="$disabled_list $(basename "$f" | sed 's/^disabled\.//')"
    done
    echo "DISABLED_SERVICES='${disabled_list# }'"
  } > "$OTA_BACKUP_DIR/ota_state.env"

  local target_mode="${1:-auto}"
  local usb_mnt
  usb_mnt="$(detect_usb_mount 2>/dev/null || true)"
  if [ -n "$usb_mnt" ] && { [ "$target_mode" = "usb" ] || [ "$target_mode" = "both" ] || [ "$target_mode" = "auto" ]; }; then
    local usb_dir="$usb_mnt/helper-script-ota-backup"
    mkdir -p "$usb_dir"
    cp -af "$OTA_BACKUP_DIR/." "$usb_dir/"
    sync
    echo -e "Info: USB copy saved & synced to ${usb_dir} (safe to unplug)"
  fi
  if [ "$target_mode" = "usb" ]; then
    rm -rf "$OTA_BACKUP_DIR"
  fi
}

function ota_backup_macro_message(){
  top_line
  title 'OTA State Backup Macro' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Installs the BACKUP_OTA_STATE macro in Klipper so you can      ${white}│"
  echo -e " │ ${cyan}trigger an OTA-safe Helper-Script snapshot from Mainsail/UI.   ${white}│"
  hr
  bottom_line
}

function install_ota_backup_macro(){
  ota_backup_macro_message
  local yn
  while true; do
    install_msg "OTA State Backup Macro" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        if [ ! -f "$KLIPPY_EXTRAS/gcode_shell_command.py" ]; then
          error_msg "Klipper Gcode Shell Command is required! Please install it first."
          return
        fi
        mkdir -p "$HS_CONFIG_FOLDER"
        cp -f "$HS_FILES/macros/ota-state-backup.cfg" "$HS_CONFIG_FOLDER/ota-state-backup.cfg"
        chown creality:creality "$HS_CONFIG_FOLDER/ota-state-backup.cfg" 2>/dev/null || true
        sed -i '/\[include Helper-Script\/ota-state-backup\.cfg\]/d' "$PRINTER_CFG" 2>/dev/null || true
        if grep -q "^[[:space:]]*#[[:space:]]*CreateDate:" "$PRINTER_CFG" 2>/dev/null; then
          sed -i "/^[[:space:]]*#[[:space:]]*CreateDate:.*/a [include Helper-Script/ota-state-backup.cfg]" "$PRINTER_CFG"
        else
          sed -i '1a [include Helper-Script/ota-state-backup.cfg]' "$PRINTER_CFG"
        fi
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "OTA State Backup Macro (BACKUP_OTA_STATE) has been installed!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_ota_backup_macro(){
  ota_backup_macro_message
  local yn
  while true; do
    remove_msg "OTA State Backup Macro" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        rm -f "$HS_CONFIG_FOLDER/ota-state-backup.cfg"
        sed -i '/include Helper-Script\/ota-state-backup\.cfg/d' "$PRINTER_CFG" 2>/dev/null || true
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "OTA State Backup Macro has been removed!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function backup_ota_state(){
  backup_ota_state_message
  local yn
  while true; do
    backup_msg "Helper-Script State (OTA Safe)" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        local usb_mnt target_mode="data" saved_msg="${OTA_BACKUP_DIR}"
        usb_mnt="$(prompt_plug_usb_if_missing || true)"
        usb_mnt="$(echo "$usb_mnt" | tail -n 1 | grep "^/" || true)"
        if [ -n "$usb_mnt" ]; then
          echo -e " ${cyan}USB drive detected:${white} ${usb_mnt}"
          echo -e " Where do you want to save the backup?"
          echo -e "   ${yellow}1)${white} Internal /usr/data only (${OTA_BACKUP_DIR})"
          echo -e "   ${yellow}2)${white} USB drive only (${usb_mnt}/helper-script-ota-backup)"
          echo -e "   ${yellow}3)${white} Both (/usr/data + USB drive)"
          echo
          local b_choice
          while true; do
            read -p " ${white}Select destination (${yellow}1${white}/${yellow}2${white}/${yellow}3${white}): ${yellow}" b_choice
            echo -e "${white}"
            case "${b_choice}" in
              1) target_mode="data"; saved_msg="${OTA_BACKUP_DIR}"; break;;
              2) target_mode="usb"; saved_msg="${usb_mnt}/helper-script-ota-backup"; break;;
              3) target_mode="both"; saved_msg="${OTA_BACKUP_DIR} + ${usb_mnt}/helper-script-ota-backup"; break;;
              *) error_msg "Please select 1, 2 or 3!";;
            esac
          done
        fi
        run_ota_state_backup_core "$target_mode"
        ok_msg "Helper-Script OTA snapshot saved to ${yellow}${saved_msg}${green}!"
        return;;
      N|n)
        error_msg "Backup canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function restore_ota_state(){
  restore_ota_state_message
  local usb_mnt
  usb_mnt="$(detect_usb_mount 2>/dev/null || true)"
  if [ -n "$usb_mnt" ] && [ -f "$usb_mnt/helper-script-ota-backup/ota_state.env" ]; then
    if [ ! -f "$OTA_BACKUP_DIR/ota_state.env" ]; then
      echo -e "Info: Importing snapshot from USB (${usb_mnt}/helper-script-ota-backup)..."
      mkdir -p "$OTA_BACKUP_DIR"
      cp -af "$usb_mnt/helper-script-ota-backup/." "$OTA_BACKUP_DIR/"
    else
      echo -e " ${cyan}Backups found on both /usr/data and USB (${usb_mnt}):${white}"
      echo -e "   ${yellow}1)${white} Use internal backup (/usr/data)"
      echo -e "   ${yellow}2)${white} Import & use USB backup (${usb_mnt}/helper-script-ota-backup)"
      echo
      local r_src
      while true; do
        read -p " ${white}Select backup source (${yellow}1${white}/${yellow}2${white}): ${yellow}" r_src
        echo -e "${white}"
        case "${r_src}" in
          1) break;;
          2)
            mkdir -p "$OTA_BACKUP_DIR"
            cp -af "$usb_mnt/helper-script-ota-backup/." "$OTA_BACKUP_DIR/"
            break;;
          *) error_msg "Please select 1 or 2!";;
        esac
      done
    fi
  fi
  if [ ! -f "$OTA_BACKUP_DIR/ota_state.env" ]; then
    error_msg "No OTA state snapshot found in ${OTA_BACKUP_DIR} or on USB!"
    return
  fi

  . "$OTA_BACKUP_DIR/ota_state.env"
  echo -e " ${cyan}Found snapshot from:${white} ${BACKUP_DATE:-unknown} (${BACKUP_MODEL:-K1_2025})"
  echo -e " ${cyan}Disabled stock services in snapshot:${white} ${DISABLED_SERVICES:-none}"
  echo

  local yn restore_mode
  while true; do
    restore_msg "Helper-Script State" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        if type creality_confirm_printer_idle >/dev/null 2>&1; then
          if ! creality_confirm_printer_idle; then
            return
          fi
        fi

        echo -e " How should Klipper/Moonraker configs be restored?"
        echo -e "  ${yellow}1)${white} Safe Merge (Recommended): Keep new FW printer.cfg/box.cfg, restore Helper-Script files & includes"
        echo -e "  ${yellow}2)${white} Full Restore: Overwrite all config files with your saved snapshot"
        echo
        while true; do
          read -p " ${white}Select restore mode (${yellow}1${white}/${yellow}2${white}): ${yellow}" restore_mode
          echo -e "${white}"
          case "${restore_mode}" in
            1|2) break;;
            *) error_msg "Please select a correct choice! (1 or 2)";;
          esac
        done

        # Always back up new firmware configs first before touching anything
        if [ -d "$PRINTER_DATA_FOLDER/config" ]; then
          echo -e "Info: Backing up current firmware configs to ${OTA_BACKUP_DIR}/fw_new_config_before_restore.tar.gz..."
          tar -czf "$OTA_BACKUP_DIR/fw_new_config_before_restore.tar.gz" -C /usr/data printer_data/config
        fi

        if [ -f "$OTA_BACKUP_DIR/ota_configs.tar.gz" ]; then
          if [ "$restore_mode" = "2" ]; then
            echo -e "Info: Performing full restore of Klipper/Moonraker configs & database..."
            tar -xzf "$OTA_BACKUP_DIR/ota_configs.tar.gz" -C /usr/data
          else
            echo -e "Info: Performing Safe Merge (preserving new FW printer.cfg & box.cfg)..."
            mkdir -p "$OTA_BACKUP_DIR/cfg_tmp"
            tar -xzf "$OTA_BACKUP_DIR/ota_configs.tar.gz" -C "$OTA_BACKUP_DIR/cfg_tmp"

            # Restore Moonraker DB & all saved Helper-Script app config directories
            [ -d "$OTA_BACKUP_DIR/cfg_tmp/printer_data/database" ] && cp -af "$OTA_BACKUP_DIR/cfg_tmp/printer_data/database/." "$PRINTER_DATA_FOLDER/database/"
            local app_cfg_dir
            for app_cfg_dir in go2rtc nginx guppyscreen kamp KAMP_Settings mobileraker_companion moonraker-obico moonraker-telegram-bot spoolman crowsnest guppyflo octoeverywhere; do
              if [ -d "$OTA_BACKUP_DIR/cfg_tmp/$app_cfg_dir" ]; then
                mkdir -p "/usr/data/$app_cfg_dir"
                cp -af "$OTA_BACKUP_DIR/cfg_tmp/$app_cfg_dir/." "/usr/data/$app_cfg_dir/"
              fi
            done

            # Copy Helper-Script folder & custom config files (without overwriting printer.cfg / box.cfg)
            local src_cfg="$OTA_BACKUP_DIR/cfg_tmp/printer_data/config"
            local dst_cfg="$PRINTER_DATA_FOLDER/config"
            if [ -d "$src_cfg/Helper-Script" ]; then
              mkdir -p "$dst_cfg/Helper-Script"
              cp -af "$src_cfg/Helper-Script/." "$dst_cfg/Helper-Script/"
            fi
            local f bname
            for f in "$src_cfg"/*; do
              [ -f "$f" ] || continue
              bname="$(basename "$f")"
              case "$bname" in
                printer.cfg|box.cfg|factory_printer.cfg|gcode_macro.cfg|sensorless.cfg)
                  continue;;
                *)
                  cp -pf "$f" "$dst_cfg/$bname";;
              esac
            done

            # Re-inject missing [include ...], [output_pin LED] & CFS-C SAVE_CONFIG blocks into new printer.cfg
            if [ -f "$src_cfg/printer.cfg" ] && [ -f "$dst_cfg/printer.cfg" ]; then
              echo -e "Info: Merging custom includes & CFS-C blocks into new firmware printer.cfg..."
              grep '^\[include ' "$src_cfg/printer.cfg" | while IFS= read -r inc_line; do
                if ! grep -Fq "$inc_line" "$dst_cfg/printer.cfg"; then
                  sed -i "1i\\${inc_line}" "$dst_cfg/printer.cfg"
                fi
              done
              if grep -q '^\[output_pin LED\]' "$src_cfg/printer.cfg" && ! grep -q '^\[output_pin LED\]' "$dst_cfg/printer.cfg"; then
                sed -n '/^\[output_pin LED\]/,/^$/p' "$src_cfg/printer.cfg" >> "$dst_cfg/printer.cfg"
              fi
              if grep -qE "serial_can|cm-切刀|mb-料盒" "$src_cfg/printer.cfg" && ! grep -q "mb-料盒" "$dst_cfg/printer.cfg"; then
                echo -e "Info: Restoring CFS-C SAVE_CONFIG calibration blocks..."
                grep -q "<---------------------- SAVE_CONFIG ---------------------->" "$dst_cfg/printer.cfg" || echo "#*# <---------------------- SAVE_CONFIG ---------------------->" >> "$dst_cfg/printer.cfg"
                awk '
                  BEGIN { keep = 0 }
                  /#\*# \[(serial_can|box|motor_control)/ || /cm-切刀/ || /mb-料盒/ { keep = 1; print; next }
                  /#\*# \[[a-zA-Z0-9_]+\]/ { keep = 0 }
                  { if (keep == 1 && /^#\*#/) print }
                ' "$src_cfg/printer.cfg" >> "$dst_cfg/printer.cfg"
              fi
            fi
            rm -rf "$OTA_BACKUP_DIR/cfg_tmp"
          fi
        fi

        if [ -f "$OTA_BACKUP_DIR/ota_extras.tar.gz" ] && [ -d "$KLIPPY_EXTRAS" ]; then
          echo -e "Info: Restoring custom Klipper extras..."
          [ -f "$KLIPPY_EXTRAS/box_control.pyc" ] && [ ! -f "$HS_BACKUP_FOLDER/box_control.pyc.orig" ] && mkdir -p "$HS_BACKUP_FOLDER" && cp -p "$KLIPPY_EXTRAS/box_control.pyc" "$HS_BACKUP_FOLDER/box_control.pyc.orig"
          tar -xzf "$OTA_BACKUP_DIR/ota_extras.tar.gz" -C "$KLIPPY_EXTRAS"
        fi
        if [ -f "$OTA_BACKUP_DIR/ota_sysfiles.tar.gz" ]; then
          echo -e "Info: Restoring custom system binaries & crontabs..."
          tar -xzf "$OTA_BACKUP_DIR/ota_sysfiles.tar.gz" -C / 2>/dev/null || true
        fi

        if [ -n "$INSTALLED_APPS" ]; then
          local missing_apps=""
          local chk_app
          for chk_app in $INSTALLED_APPS; do
            if [ ! -e "/usr/data/$chk_app" ]; then
              missing_apps="$missing_apps $chk_app"
            fi
          done
          if [ -n "$missing_apps" ]; then
            echo -e " ${yellow}Notice: The following Helper-Script apps were installed in your snapshot but are missing on /usr/data:${white}"
            echo -e "  ${cyan}${missing_apps# }${white}"
            echo -e " ${yellow}Please re-install them via the Helper-Script Install menu — all their configs & databases are already restored!${white}"
          fi
        fi

        if [ -f "$OTA_BACKUP_DIR/ota_initd.tar.gz" ] && [ -d "$INITD_FOLDER" ]; then
          echo -e "Info: Restoring custom init scripts..."
          mkdir -p "$OTA_BACKUP_DIR/initd_tmp"
          tar -xzf "$OTA_BACKUP_DIR/ota_initd.tar.gz" -C "$OTA_BACKUP_DIR/initd_tmp"
          local s
          for s in "$OTA_BACKUP_DIR/initd_tmp"/S* "$OTA_BACKUP_DIR/initd_tmp"/CS*; do
            [ -f "$s" ] || continue
            local sbname
            sbname="$(basename "$s")"
            if [ ! -f "$INITD_FOLDER/$sbname" ]; then
              cp -p "$s" "$INITD_FOLDER/$sbname"
              chmod +x "$INITD_FOLDER/$sbname" 2>/dev/null || true
            fi
          done
          rm -rf "$OTA_BACKUP_DIR/initd_tmp"
        fi

        if [ -n "$DISABLED_SERVICES" ] && [ -d "$INITD_FOLDER" ]; then
          echo -e "Info: Re-applying disabled Creality stock services..."
          local svc
          for svc in $DISABLED_SERVICES; do
            if [ -f "$INITD_FOLDER/$svc" ]; then
              set +e
              "$INITD_FOLDER/$svc" stop >/dev/null 2>&1
              set -e
              mv "$INITD_FOLDER/$svc" "$INITD_FOLDER/disabled.$svc" 2>/dev/null || true
            fi
          done
        fi

        if [ -n "$GO2RTC_MODE" ] && type configure_go2rtc_k1_2025 >/dev/null 2>&1; then
          configure_go2rtc_k1_2025 "$GO2RTC_MODE"
        fi

        if [ "${HAS_CFS_MAINSAIL:-0}" = "1" ] && [ -d "$MAINSAIL_FOLDER" ] && [ -f "$HS_FILES/cfs_mainsail/static/mainsail-panel.js" ]; then
          cp -f "$HS_FILES/cfs_mainsail/static/mainsail-panel.js" "$MAINSAIL_FOLDER/k1c-cfs-panel.js"
          grep -q "k1c-cfs-panel.js" "$MAINSAIL_FOLDER/index.html" 2>/dev/null || sed -i 's|</body>|<script src="k1c-cfs-panel.js"></script></body>|' "$MAINSAIL_FOLDER/index.html"
        fi
        if [ "${HAS_CFS_FLUIDD:-0}" = "1" ] && [ -d "$FLUIDD_FOLDER" ] && [ -f "$HS_FILES/cfs_mainsail/static/mainsail-panel.js" ]; then
          cp -f "$HS_FILES/cfs_mainsail/static/mainsail-panel.js" "$FLUIDD_FOLDER/k1c-cfs-panel.js"
          grep -q "k1c-cfs-panel.js" "$FLUIDD_FOLDER/index.html" 2>/dev/null || sed -i 's|</body>|<script src="k1c-cfs-panel.js"></script></body>|' "$FLUIDD_FOLDER/index.html"
        fi

        type sync_timelapse_snapshot_url_k1_2025 >/dev/null 2>&1 && sync_timelapse_snapshot_url_k1_2025
        type sync_octoeverywhere_camera_k1_2025 >/dev/null 2>&1 && sync_octoeverywhere_camera_k1_2025

        ok_msg "Helper-Script state restored! Please reboot the printer to start all services cleanly."
        local rb_yn
        read -p " ${white}Do you want to reboot the printer now? (${yellow}y${white}/${yellow}n${white}): ${yellow}" rb_yn
        echo -e "${white}"
        case "${rb_yn}" in
          Y|y)
            echo -e "Info: Rebooting printer..."
            sync
            reboot
            exit 0;;
        esac
        return;;
      N|n)
        error_msg "Restoration canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

if [ "$1" = "--check-usb" ]; then
  _u="$(detect_usb_mount 2>/dev/null || true)"
  if [ -n "$_u" ]; then
    echo "USB_DETECTED=1 ($_u)"
    exit 0
  else
    echo "USB_DETECTED=0"
    exit 1
  fi
fi

if [ "$1" = "--auto" ]; then
  HELPER_SCRIPT_FOLDER="/usr/data/helper-script"
  [ -f "$HELPER_SCRIPT_FOLDER/scripts/menu/functions.sh" ] && . "$HELPER_SCRIPT_FOLDER/scripts/menu/functions.sh"
  [ -f "$HELPER_SCRIPT_FOLDER/scripts/tools.sh" ] && . "$HELPER_SCRIPT_FOLDER/scripts/tools.sh"
  [ -f "$HELPER_SCRIPT_FOLDER/paths.sh" ] && . "$HELPER_SCRIPT_FOLDER/paths.sh"
  if command -v get_device_model >/dev/null 2>&1; then
    get_device_model >/dev/null 2>&1 || true
  fi
  [ -z "$model" ] && model="K1_2025"
  command -v set_paths >/dev/null 2>&1 && set_paths
  run_ota_state_backup_core "auto"
  _auto_usb="$(detect_usb_mount 2>/dev/null || true)"
  if [ -n "$_auto_usb" ]; then
    echo "OK: Helper-Script OTA snapshot saved to ${OTA_BACKUP_DIR} + USB (${_auto_usb}/helper-script-ota-backup)"
  else
    echo "OK: Helper-Script OTA snapshot saved to ${OTA_BACKUP_DIR} (No USB drive detected - internal backup only)"
  fi
fi
