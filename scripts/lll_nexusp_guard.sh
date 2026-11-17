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
  is_nexusp_running || return 0
  query_sensor_true "filament_sensor" || return 0
  if query_sensor_true "lll_plus_sensor"; then
    echo "Info: FLY-LLL Plus already has filament inserted - skipping CFS retract."
    return 0
  fi

  local box_json
  box_json=$("$CURL_BIN" -s --max-time 2 "http://localhost:7125/server/database/item?namespace=color_box&key=box_info" 2>/dev/null)
  local mat_id=""
  mat_id=$(/usr/data/moonraker/moonraker-env/bin/python -c '
import json, sys
try:
    d = json.loads(sys.argv[1])
    val = (d.get("result") or {}).get("value") or {}
    for idx, k in enumerate(["T1", "T2", "T3", "T4"]):
        slot = val.get(k) or {}
        if str(slot.get("state", "")) in ("2", "loaded", "selected") or int(slot.get("selected") or 0) == 1:
            print(idx); sys.exit(0)
    # Fallback: if T1..T4 only stores filament state via current_filament / loaded
    cur = str(val.get("current_filament") or val.get("selected") or "")
    for idx, k in enumerate(["T1", "T2", "T3", "T4"]):
        if k in cur or chr(65+idx) in cur:
            print(idx); sys.exit(0)
except Exception:
    pass
' "$box_json" 2>/dev/null)

  echo "Info: Filament in extruder - triggering CFS-C Retract via port 9999..."
  /usr/data/moonraker/moonraker-env/bin/python -c '
import asyncio, json, sys
from tornado.websocket import websocket_connect

async def go(preset_mid):
    ws = None
    for _ in range(15):
        try:
            ws = await websocket_connect("ws://localhost:9999")
            break
        except Exception:
            await asyncio.sleep(1.0)
    if ws is None:
        print("Warning: Port 9999 not reachable - skipping CFS retract.")
        sys.exit(2)
    await ws.write_message(json.dumps({"ModeCode": "heart_beat"}))
    await asyncio.sleep(0.2)
    bid, mid, found = 1, 0, False
    if preset_mid != "":
        mid = int(preset_mid); found = True
    else:
        await ws.write_message(json.dumps({"method": "get", "params": {"boxsInfo": 1}}))
        for _ in range(10):
            msg = await asyncio.wait_for(ws.read_message(), timeout=2.0)
            if not msg: break
            d = json.loads(msg)
            if not isinstance(d, dict): continue
            bi = d.get("boxsInfo") or (d.get("result") or {}).get("boxsInfo") or (d.get("params") or {}).get("boxsInfo")
            mboxes = bi if isinstance(bi, list) else (bi.get("materialBoxs") if isinstance(bi, dict) else [])
            for b in mboxes:
                if isinstance(b, dict) and b.get("type") == 0:
                    bid = b.get("id", 1)
                    for m in (b.get("materials") or []):
                        if isinstance(m, dict) and int(m.get("selected") or 0) == 1:
                            mid = int(m.get("id", 0)); found = True; break
                if found: break
            if mboxes: break
    if not found:
        print("Info: No active CFS-C slot selected - skipping CFS retract.")
        ws.close(); sys.exit(2)
    print(f"Info: Sending CFS-C Retract command for slot {bid}{chr(65+mid)}...")
    await ws.write_message(json.dumps({"method": "set", "params": {"feedInOrOut": {"boxId": bid, "materialId": mid, "isFeed": 0}}}))
    await asyncio.sleep(1.0)
    ws.close()

asyncio.run(go(sys.argv[1] if len(sys.argv) > 1 else ""))
' "$mat_id" || return 0

  local w=0
  while [ "$w" -lt 85 ]; do
    if query_sensor_false "filament_sensor"; then
      echo "OK: CFS-C filament retracted cleanly from extruder!"
      sleep 3; return 0
    fi
    sleep 1; w=$((w + 1))
  done
  echo "Warning: Timed out waiting for extruder sensor - pausing nexusp anyway."
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
