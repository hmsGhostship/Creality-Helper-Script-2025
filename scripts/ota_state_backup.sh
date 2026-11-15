#!/bin/sh

set -e

OTA_BACKUP_DIR="/usr/data/helper-script-ota-backup"

function backup_ota_state_message(){
  top_line
  title 'Backup Helper-Script State (OTA Safe)' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Saves all Helper-Script configs, Moonraker DB, init scripts,   ${white}│"
  echo -e " │ ${cyan}and disabled Creality service states to /usr/data so you can   ${white}│"
  echo -e " │ ${cyan}restore your exact setup after a Creality firmware update.     ${white}│"
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
  hr
  bottom_line
}

function backup_ota_state(){
  backup_ota_state_message
  local yn
  while true; do
    backup_msg "Helper-Script State (OTA Safe)" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        mkdir -p "$OTA_BACKUP_DIR"
        rm -f "$OTA_BACKUP_DIR/ota_configs.tar.gz" "$OTA_BACKUP_DIR/ota_initd.tar.gz" "$OTA_BACKUP_DIR/ota_state.env"

        echo -e "Info: Saving Klipper/Moonraker configs & database..."
        local cfg_items=""
        [ -d "$PRINTER_DATA_FOLDER/config" ] && cfg_items="$cfg_items printer_data/config"
        [ -d "$PRINTER_DATA_FOLDER/database" ] && cfg_items="$cfg_items printer_data/database"
        [ -d "/usr/data/go2rtc" ] && cfg_items="$cfg_items go2rtc"
        if [ -n "$cfg_items" ]; then
          tar -czf "$OTA_BACKUP_DIR/ota_configs.tar.gz" -C /usr/data $cfg_items
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
          local disabled_list=""
          local f
          for f in "$INITD_FOLDER"/disabled.*; do
            [ -e "$f" ] || continue
            disabled_list="$disabled_list $(basename "$f" | sed 's/^disabled\.//')"
          done
          echo "DISABLED_SERVICES='${disabled_list# }'"
        } > "$OTA_BACKUP_DIR/ota_state.env"

        ok_msg "Helper-Script OTA snapshot saved to ${yellow}${OTA_BACKUP_DIR}${green}!"
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
  if [ ! -f "$OTA_BACKUP_DIR/ota_state.env" ]; then
    error_msg "No OTA state snapshot found in ${OTA_BACKUP_DIR}!"
    return
  fi

  . "$OTA_BACKUP_DIR/ota_state.env"
  echo -e " ${cyan}Found snapshot from:${white} ${BACKUP_DATE:-unknown} (${BACKUP_MODEL:-K1_2025})"
  echo -e " ${cyan}Disabled stock services in snapshot:${white} ${DISABLED_SERVICES:-none}"
  echo

  local yn
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

        if [ -f "$OTA_BACKUP_DIR/ota_configs.tar.gz" ]; then
          echo -e "Info: Restoring Klipper/Moonraker configs & database..."
          tar -xzf "$OTA_BACKUP_DIR/ota_configs.tar.gz" -C /usr/data
        fi

        if [ -f "$OTA_BACKUP_DIR/ota_initd.tar.gz" ] && [ -d "$INITD_FOLDER" ]; then
          echo -e "Info: Restoring custom init scripts..."
          mkdir -p "$OTA_BACKUP_DIR/initd_tmp"
          tar -xzf "$OTA_BACKUP_DIR/ota_initd.tar.gz" -C "$OTA_BACKUP_DIR/initd_tmp"
          local s
          for s in "$OTA_BACKUP_DIR/initd_tmp"/S* "$OTA_BACKUP_DIR/initd_tmp"/CS*; do
            [ -f "$s" ] || continue
            local bname
            bname="$(basename "$s")"
            if [ ! -f "$INITD_FOLDER/$bname" ]; then
              cp -p "$s" "$INITD_FOLDER/$bname"
              chmod +x "$INITD_FOLDER/$bname" 2>/dev/null || true
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

        if [ "$HAS_CFS_MAINSAIL" = "1" ] || [ "$HAS_CFS_FLUIDD" = "1" ]; then
          if type install_cfs_integration >/dev/null 2>&1; then
            echo -e "Info: Note - re-run Option 14 in Tools Menu if Mainsail/Fluidd web files were updated."
          fi
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
