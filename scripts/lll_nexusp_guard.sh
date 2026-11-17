#!/bin/sh
NEXUSP_SVC="/usr/apps/etc/init.d/CS56nexusp_service"
NEXUSP_BACKUP="/usr/data/helper-script/backups/CS56nexusp_service.orig"
GUARD_FLAG="/usr/data/printer_data/config/Helper-Script/.lll_nexusp_guard_enabled"
CFG_TARGET="/usr/data/printer_data/config/Helper-Script/lll-plus-nexusp-switch.cfg"
CFG_SOURCE="/usr/data/helper-script/files/macros/lll-plus-nexusp-switch.cfg"
PRINTER_CFG="/usr/data/printer_data/config/printer.cfg"
CURL_BIN="/usr/data/helper-script/files/fixes/curl"
[ -x "$CURL_BIN" ] || CURL_BIN="curl"

is_nexusp_running() { ps -w | grep '/usr/apps/usr/bin/[n]exusp' >/dev/null 2>&1; }

query_sensor_true() {
  "$CURL_BIN" -s --max-time 2 "http://localhost:7126/printer/objects/query?filament_switch_sensor%20$1" 2>/dev/null | grep -Eq '"filament_detected"[[:space:]]*:[[:space:]]*true'
}

query_sensor_false() {
  "$CURL_BIN" -s --max-time 2 "http://localhost:7126/printer/objects/query?filament_switch_sensor%20$1" 2>/dev/null | grep -Eq '"filament_detected"[[:space:]]*:[[:space:]]*false'
}
retract_cfs_if_loaded() {
  if query_sensor_true "filament_sensor" && ! query_sensor_true "lll_plus_sensor"; then
    echo "Notice: Extruder sensor still detects filament (ensure CFS-C filament is unloaded before inserting LLL Plus)."
  fi
  return 0
}

start_nexusp_now() {
  if is_nexusp_running; then echo "Info: nexusp backend is already running (CFS-C mode active)."; return 0; fi
  if [ "$(id -u)" -eq 0 ]; then FORCE_NEXUSP=1 sh "$NEXUSP_SVC" start >/dev/null 2>&1
  else
    mkdir -p /usr/data/printer_data /usr/data/printer_data/logs /home/creality/run
    start-stop-daemon -S -q -b -m -p /home/creality/run/nexusp.pid --exec /usr/apps/usr/bin/nexusp -- -d /usr/data/printer_data -c /usr/apps/etc/nexusp/nexusp.conf >/dev/null 2>&1
  fi
  sleep 1
  is_nexusp_running && echo "OK: nexusp backend started (CFS-C mode active)." || echo "ERROR: Failed to start nexusp backend!"
}

stop_nexusp_now() {
  if ! is_nexusp_running; then echo "Info: nexusp backend is already paused (External Spool / LLL Plus mode active)."; return 0; fi
  [ "${SKIP_CFS_RETRACT:-0}" != "1" ] && retract_cfs_if_loaded
  if [ "$(id -u)" -eq 0 ]; then sh "$NEXUSP_SVC" stop >/dev/null 2>&1
  else start-stop-daemon -K -q -p /home/creality/run/nexusp.pid >/dev/null 2>&1 || killall nexusp nexusp-main >/dev/null 2>&1 || true
  fi
  sleep 1
  ! is_nexusp_running && echo "OK: nexusp backend paused (External Spool / LLL Plus mode active)." || echo "ERROR: Failed to stop nexusp backend!"
}
boot_check_and_start() {
  rm -f /tmp/lll_boot_decided /tmp/lll_boot_locked
  local i=0
  while [ "$i" -lt 60 ]; do
    [ -f /tmp/lll_boot_locked ] && exit 0
    if [ -f /tmp/lll_boot_decided ]; then FORCE_NEXUSP=1 sh "$NEXUSP_SVC" start >/dev/null 2>&1; exit 0; fi
    if query_sensor_true "lll_plus_sensor"; then touch /tmp/lll_boot_locked; exit 0; fi
    if query_sensor_false "lll_plus_sensor"; then touch /tmp/lll_boot_decided; FORCE_NEXUSP=1 sh "$NEXUSP_SVC" start >/dev/null 2>&1; exit 0; fi
    sleep 1; i=$((i + 1))
  done
}

function lll_nexusp_guard_message() {
  top_line; title 'FLY-LLL Plus Nexusp Auto-Switch (PD7)' "${yellow}"; inner_line; hr
  echo -e " │ ${cyan}Uses pin ^PD7 from cfs_lll_safety.cfg for FLY-LLL Plus.        ${white}│"
  echo -e " │ ${cyan}Pauses nexusp at boot when LLL Plus is loaded & adds switchers.${white}│"
  hr; bottom_line
}

function install_lll_nexusp_guard() {
  lll_nexusp_guard_message
  local yn
  while true; do
    install_msg "FLY-LLL Plus Nexusp Auto-Switch" yn
    case "${yn}" in
      Y|y)
        grep -q "^\[include Helper-Script/cfs_lll_safety.cfg\]" "$PRINTER_CFG" 2>/dev/null || { error_msg "Install Option 16 first!"; return; }
        [ -f "$KLIPPY_EXTRAS/gcode_shell_command.py" ] || { error_msg "Install Klipper Gcode Shell Command first!"; return; }
        mkdir -p "/usr/data/helper-script/backups" "$HS_CONFIG_FOLDER"
        [ -f "$NEXUSP_BACKUP" ] || cp -f "$NEXUSP_SVC" "$NEXUSP_BACKUP"
        cp -f "$CFG_SOURCE" "$CFG_TARGET" && touch "$GUARD_FLAG"
        sed -i '/\[include Helper-Script\/lll-plus-nexusp-switch\.cfg\]/d' "$PRINTER_CFG" 2>/dev/null || true
        sed -i "/^[[:space:]]*#[[:space:]]*CreateDate:.*/a [include Helper-Script/lll-plus-nexusp-switch.cfg]" "$PRINTER_CFG"
        grep -q "lll_nexusp_guard.sh" "$NEXUSP_SVC" || sed -i '/^start() {/a \      if [ -f "/usr/data/printer_data/config/Helper-Script/.lll_nexusp_guard_enabled" ] && [ "${FORCE_NEXUSP:-0}" != "1" ]; then sh /usr/data/helper-script/scripts/lll_nexusp_guard.sh boot-guard \& return 0; fi' "$NEXUSP_SVC"
        chmod +x "$NEXUSP_SVC"; restart_klipper; ok_msg "FLY-LLL Plus Nexusp Auto-Switch installed!"; return;;
      N|n) error_msg "Installation canceled!"; return;;
      *) error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_lll_nexusp_guard() {
  lll_nexusp_guard_message
  local yn
  while true; do
    remove_msg "FLY-LLL Plus Nexusp Auto-Switch" yn
    case "${yn}" in
      Y|y)
        rm -f "$GUARD_FLAG" "$CFG_TARGET"
        sed -i '/\[include Helper-Script\/lll-plus-nexusp-switch\.cfg\]/d' "$PRINTER_CFG" 2>/dev/null || true
        [ -f "$NEXUSP_BACKUP" ] && cp -f "$NEXUSP_BACKUP" "$NEXUSP_SVC" && chmod +x "$NEXUSP_SVC"
        is_nexusp_running || sh "$NEXUSP_SVC" start >/dev/null 2>&1 || true
        restart_klipper; ok_msg "FLY-LLL Plus Nexusp Auto-Switch removed!"; return;;
      N|n) error_msg "Deletion canceled!"; return;;
      *) error_msg "Please select a correct choice!";;
    esac
  done
}

case "$1" in
  boot-guard) boot_check_and_start ;;
  boot-lock) touch /tmp/lll_boot_locked; SKIP_CFS_RETRACT=1 stop_nexusp_now ;;
  boot-release) touch /tmp/lll_boot_decided; start_nexusp_now ;;
  on) start_nexusp_now ;;
  off) stop_nexusp_now ;;
  toggle) is_nexusp_running && stop_nexusp_now || start_nexusp_now ;;
  status) is_nexusp_running && echo "Nexusp Backend: RUNNING (CFS-C Mode Active)" || echo "Nexusp Backend: PAUSED (External Spool / FLY-LLL Plus Mode Active)" ;;
esac
