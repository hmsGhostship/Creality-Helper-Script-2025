#!/bin/sh

FACTORY_BASELINE_DIR="/usr/data/helper-script-factory-baseline"

function is_system_pristine_for_baseline(){
  [ -d "$MOONRAKER_FOLDER" ] && return 1
  [ -d "$MAINSAIL_FOLDER" ] && return 1
  [ -d "$FLUIDD_FOLDER" ] && return 1
  [ -d "$NGINX_FOLDER" ] && return 1
  [ -d "$OCTOEVERYWHERE_FOLDER" ] && return 1
  [ -d "$GUPPYFLO_FOLDER" ] && return 1
  [ -f "$KLIPPER_SHELL_FILE" ] && return 1
  [ -f "$ENTWARE_FILE" ] && return 1
  [ -d "$HS_CONFIG_FOLDER" ] && return 1
  return 0
}

function create_factory_baseline_snapshot(){
  mkdir -p "$FACTORY_BASELINE_DIR"
  ls -1 /usr/share/klipper/klippy/extras/ 2>/dev/null | sort > "$FACTORY_BASELINE_DIR/manifest_extras.txt"
  ls -1 /etc/init.d/ 2>/dev/null | sort > "$FACTORY_BASELINE_DIR/manifest_initd.txt"
  ls -1 /usr/apps/etc/init.d/ 2>/dev/null | sort > "$FACTORY_BASELINE_DIR/manifest_apps_initd.txt"
  ls -1 /usr/data/ 2>/dev/null | sort > "$FACTORY_BASELINE_DIR/manifest_usr_data.txt"
  ls -1 /usr/bin/ 2>/dev/null | sort > "$FACTORY_BASELINE_DIR/manifest_usr_bin.txt"
  ls -1 /usr/local/bin/ 2>/dev/null | sort > "$FACTORY_BASELINE_DIR/manifest_usr_local_bin.txt"
  ls -1 /usr/apps/overlay/sbin/ 2>/dev/null | sort > "$FACTORY_BASELINE_DIR/manifest_overlay_sbin.txt"

  tar --exclude="*.log" --exclude="*.pid" --exclude="*.sock" -czf "$FACTORY_BASELINE_DIR/baseline_configs.tar.gz" -C /usr/data printer_data/config printer_data/database 2>/dev/null || true
  tar -czf "$FACTORY_BASELINE_DIR/baseline_extras.tar.gz" -C /usr/share/klipper/klippy/extras . 2>/dev/null || true
  tar -czf "$FACTORY_BASELINE_DIR/baseline_sysfiles.tar.gz" -C / etc/init.d usr/apps/etc/init.d etc/mdev.conf etc/crontabs 2>/dev/null || true

  {
    echo "BASELINE_CREATED_AT=\"$(date '+%Y-%m-%d %H:%M:%S')\""
    echo "BASELINE_MODEL=\"${model}\""
    echo "BASELINE_FW=\"$(grep -o '1\.[0-9.]*' /etc/ota_info 2>/dev/null | head -n 1 || echo 'unknown')\""
  } > "$FACTORY_BASELINE_DIR/baseline_meta.env"
}

function ensure_factory_baseline(){
  [ -f "$FACTORY_BASELINE_DIR/baseline_meta.env" ] && return 0
  if is_system_pristine_for_baseline; then
    echo -e " ${cyan}First launch detected: Creating Pre-Helper-Script Factory Baseline snapshot...${white}"
    create_factory_baseline_snapshot
    echo -e " ${green}Factory Baseline saved to:${white} ${FACTORY_BASELINE_DIR}"
    sleep 1
  fi
}

function restore_factory_baseline(){
  top_line
  title 'Restore Factory Baseline (Pre-Helper-Script)' "${yellow}"
  inner_line
  hr
  echo -e " │ ${red}WARNING: Removes ALL Helper-Script mods, extra .py modules,   ${white}│"
  echo -e " │ ${red}services, Entware, web interfaces & restores original configs.${white}│"
  echo -e " │ ${cyan}Root access and Wi-Fi credentials remain untouched.           ${white}│"
  hr
  bottom_line

  local usb_mnt=""
  command -v detect_usb_mount >/dev/null 2>&1 && usb_mnt="$(detect_usb_mount 2>/dev/null || true)"
  if [ ! -f "$FACTORY_BASELINE_DIR/baseline_meta.env" ] && [ -n "$usb_mnt" ] && [ -f "$usb_mnt/helper-script-factory-baseline/baseline_meta.env" ]; then
    mkdir -p "$FACTORY_BASELINE_DIR"
    cp -rf "$usb_mnt/helper-script-factory-baseline/"* "$FACTORY_BASELINE_DIR/"
  fi

  if [ ! -f "$FACTORY_BASELINE_DIR/baseline_meta.env" ]; then
    error_msg "No Factory Baseline snapshot found! (Only captured on a clean system before installing mods.)"
    return
  fi

  . "$FACTORY_BASELINE_DIR/baseline_meta.env"
  echo -e "\n Baseline: ${cyan}${BASELINE_CREATED_AT}${white} | Model: ${cyan}${BASELINE_MODEL}${white} | FW: ${cyan}${BASELINE_FW}${white}\n"

  local yn confirm_word
  while true; do
    read -p " ${white}Revert printer back to Pre-Helper-Script baseline? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
    echo -e "${white}"
    case "${yn}" in
      Y|y) break;;
      N|n) error_msg "Restore canceled!"; return;;
      *) error_msg "Please select a correct choice!";;
    esac
  done

  read -p " ${red}Type RESET to confirm full removal of all Helper-Script mods:${white} ${yellow}" confirm_word
  echo -e "${white}"
  [ "$confirm_word" != "RESET" ] && { error_msg "Confirmation mismatch. Canceled!"; return; }

  local f base
  for d_m in "/etc/init.d:$FACTORY_BASELINE_DIR/manifest_initd.txt" "/usr/apps/etc/init.d:$FACTORY_BASELINE_DIR/manifest_apps_initd.txt"; do
    local d="${d_m%%:*}" m="${d_m#*:}"
    [ -f "$m" ] || continue
    for f in "$d"/*; do
      [ -e "$f" ] || [ -L "$f" ] || continue
      base="$(basename "$f")"
      grep -Fxq "$base" "$m" || { "$f" stop >/dev/null 2>&1 || true; rm -f "$f"; }
    done
  done
  killall -9 moonraker nginx octoeverywhere guppyflo go2rtc mobileraker_companion 2>/dev/null || true

  if [ -f "$FACTORY_BASELINE_DIR/manifest_extras.txt" ]; then
    for f in /usr/share/klipper/klippy/extras/*; do
      [ -e "$f" ] || [ -L "$f" ] || continue
      base="$(basename "$f")"
      grep -Fxq "$base" "$FACTORY_BASELINE_DIR/manifest_extras.txt" || rm -rf "$f"
    done
  fi
  [ -f "$FACTORY_BASELINE_DIR/baseline_extras.tar.gz" ] && tar -xzf "$FACTORY_BASELINE_DIR/baseline_extras.tar.gz" -C /usr/share/klipper/klippy/extras/ 2>/dev/null || true

  if [ -f "$FACTORY_BASELINE_DIR/manifest_usr_data.txt" ]; then
    for f in /usr/data/*; do
      [ -e "$f" ] || [ -L "$f" ] || continue
      base="$(basename "$f")"
      case "$base" in helper-script|helper-script-factory-baseline|helper-script-ota-backup|gcodes|lost+found) continue;; esac
      grep -Fxq "$base" "$FACTORY_BASELINE_DIR/manifest_usr_data.txt" || rm -rf "$f"
    done
  fi
  rm -rf /opt /usr/data/opt 2>/dev/null || true

  for d_m in "/usr/bin:$FACTORY_BASELINE_DIR/manifest_usr_bin.txt" "/usr/local/bin:$FACTORY_BASELINE_DIR/manifest_usr_local_bin.txt" "/usr/apps/overlay/sbin:$FACTORY_BASELINE_DIR/manifest_overlay_sbin.txt"; do
    local d="${d_m%%:*}" m="${d_m#*:}"
    [ -d "$d" ] && [ -f "$m" ] || continue
    for f in "$d"/*; do
      [ -e "$f" ] || [ -L "$f" ] || continue
      base="$(basename "$f")"
      grep -Fxq "$base" "$m" || rm -rf "$f"
    done
  done

  [ -f "$FACTORY_BASELINE_DIR/baseline_sysfiles.tar.gz" ] && tar -xzf "$FACTORY_BASELINE_DIR/baseline_sysfiles.tar.gz" -C / 2>/dev/null || true
  if [ -f "$FACTORY_BASELINE_DIR/baseline_configs.tar.gz" ]; then
    rm -rf /usr/data/printer_data/config/* /usr/data/printer_data/database/* 2>/dev/null || true
    tar -xzf "$FACTORY_BASELINE_DIR/baseline_configs.tar.gz" -C /usr/data/ 2>/dev/null || true
  fi

  sync
  ok_msg "Printer restored to Pre-Helper-Script Factory Baseline!"
  local rb
  read -p " ${white}Reboot printer now? (${yellow}y${white}/${yellow}n${white}): ${yellow}" rb
  echo -e "${white}"
  case "$rb" in Y|y) reboot ;; esac
}
