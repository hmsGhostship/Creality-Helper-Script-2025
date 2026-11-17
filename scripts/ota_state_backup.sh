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

function run_ota_state_backup_core(){
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
        run_ota_state_backup_core
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

        # Immer zuerst die neuen Firmware-Configs sichern, bevor etwas angefasst wird
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

            # Moonraker-Datenbank & Go2rtc wiederherstellen
            [ -d "$OTA_BACKUP_DIR/cfg_tmp/printer_data/database" ] && cp -af "$OTA_BACKUP_DIR/cfg_tmp/printer_data/database/." "$PRINTER_DATA_FOLDER/database/"
            if [ -d "$OTA_BACKUP_DIR/cfg_tmp/go2rtc" ]; then
              mkdir -p /usr/data/go2rtc
              cp -af "$OTA_BACKUP_DIR/cfg_tmp/go2rtc/." /usr/data/go2rtc/
            fi

            # Helper-Script-Ordner & eigene Konfigurationsdateien übernehmen (ohne printer.cfg / box.cfg zu überschreiben)
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

            # Fehlende [include Helper-Script/...] & [output_pin LED] in die neue printer.cfg einfügen
            if [ -f "$src_cfg/printer.cfg" ] && [ -f "$dst_cfg/printer.cfg" ]; then
              echo -e "Info: Merging Helper-Script includes into new firmware printer.cfg..."
              grep '^\[include Helper-Script/' "$src_cfg/printer.cfg" | while IFS= read -r inc_line; do
                if ! grep -Fq "$inc_line" "$dst_cfg/printer.cfg"; then
                  sed -i "1i\\${inc_line}" "$dst_cfg/printer.cfg"
                fi
              done
              if grep -q '^\[output_pin LED\]' "$src_cfg/printer.cfg" && ! grep -q '^\[output_pin LED\]' "$dst_cfg/printer.cfg"; then
                sed -n '/^\[output_pin LED\]/,/^$/p' "$src_cfg/printer.cfg" >> "$dst_cfg/printer.cfg"
              fi
            fi
            rm -rf "$OTA_BACKUP_DIR/cfg_tmp"
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
  run_ota_state_backup_core
  echo "OK: Helper-Script OTA snapshot saved to ${OTA_BACKUP_DIR}"
fi
