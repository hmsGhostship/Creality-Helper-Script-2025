#!/bin/sh

NEXUSP_SVC="/usr/apps/etc/init.d/CS56nexusp_service"
NEXUSP_BACKUP="/usr/data/helper-script/backups/CS56nexusp_service.orig"
GUARD_FLAG="/usr/data/printer_data/config/Helper-Script/.lll_nexusp_guard_enabled"
CFG_TARGET="/usr/data/printer_data/config/Helper-Script/lll-plus-nexusp-switch.cfg"
CFG_SOURCE="/usr/data/helper-script/files/macros/lll-plus-nexusp-switch.cfg"
PRINTER_CFG="/usr/data/printer_data/config/printer.cfg"

is_nexusp_running() {
  ps -w | grep '/usr/apps/usr/bin/[n]exusp' >/dev/null 2>&1
}

start_nexusp_now() {
  if is_nexusp_running; then
    echo "Info: nexusp backend is already running (CFS-C mode active)."
    return 0
  fi
  if [ "$(id -u)" -eq 0 ]; then
    FORCE_NEXUSP=1 sh "$NEXUSP_SVC" start >/dev/null 2>&1
  else
    mkdir -p /usr/data/printer_data /usr/data/printer_data/logs /home/creality/run
    start-stop-daemon -S -q -b -m -p /home/creality/run/nexusp.pid --exec /usr/apps/usr/bin/nexusp -- -d /usr/data/printer_data -c /usr/apps/etc/nexusp/nexusp.conf >/dev/null 2>&1
  fi
  sleep 1
  if is_nexusp_running; then
    echo "OK: nexusp backend started (CFS-C mode active)."
  else
    echo "ERROR: Failed to start nexusp backend!"
  fi
}

retract_cfs_if_loaded() {
  # Only retract if nexusp is running AND DXC extruder sensor currently detects filament AND LLL Plus is still empty
  is_nexusp_running || return 0
  local dxc_state
  dxc_state=$(curl -s --max-time 2 "http://127.0.0" 2>/dev/null)
  if ! echo "$dxc_state" | grep -Eq '"filament_detected"[[:space:]]*:[[:space:]]*true'; then
    return 0
  fi
  local lll_state
  lll_state=$(curl -s --max-time 2 "http://127.0.0" 2>/dev/null)
  if echo "$lll_state" | grep -Eq '"filament_detected"[[:space:]]*:[[:space:]]*true'; then
    echo "Info: FLY-LLL Plus already has filament inserted - skipping automatic CFS retract."
    return 0
  fi

  echo "Info: Filament detected in extruder - triggering CFS-C Retract via port 9999 before pausing nexusp..."
  /usr/data/moonraker/moonraker-env/bin/python -c '
import asyncio, json
from tornado.websocket import websocket_connect

async def do_retract():
    ws = await websocket_connect("ws://127.0.0.1:9999")
    await ws.write_message(json.dumps({"method": "get", "params": {"boxsInfo": 1}}))
    box_id, mat_id = 1, 0
    found = False
    for _ in range(10):
        msg = await asyncio.wait_for(ws.read_message(), timeout=3.0)
        if not msg:
            break
        data = json.loads(msg)
        res = data.get("result") or data.get("params") or data
        boxes = res.get("boxsInfo") or res.get("boxes") or []
        if isinstance(boxes, dict):
            boxes = boxes.get("boxs") or boxes.get("list") or []
        for b in boxes:
            bid = b.get("boxId", b.get("id", 1))
            mats = b.get("materials") or b.get("materialList") or b.get("slots") or []
            for idx, m in enumerate(mats):
                if m.get("selected") or m.get("isSelected") or m.get("state") in (1, "loaded", "selected"):
                    box_id = bid
                    mat_id = m.get("id", m.get("materialId", idx))
                    found = True
                    break
            if found:
                break
        if found or boxes:
            break
    print(f"Info: Sending CFS-C retract command (boxId={box_id}, materialId={mat_id})...")
    await ws.write_message(json.dumps({
        "method": "set",
        "params": {"feedInOrOut": {"boxId": box_id, "materialId": mat_id, "isFeed": 0}}
    }))
    await asyncio.sleep(1.0)
    ws.close()

asyncio.run(do_retract())
' 2>/dev/null || echo "Warning: Could not send WebSocket retract on port 9999."

  # Wait up to 75s until extruder sensor reports empty
  local w=0
  while [ "$w" -lt 75 ]; do
    dxc_state=$(curl -s --max-time 2 "http://127.0.0" 2>/dev/null)
    if echo "$dxc_state" | grep -Eq '"filament_detected"[[:space:]]*:[[:space:]]*false'; then
      echo "OK: CFS-C filament retracted cleanly from extruder!"
      sleep 3
      return 0
    fi
    sleep 1
    w=$((w + 1))
  done
  echo "Warning: Timed out waiting for extruder sensor to clear - pausing nexusp anyway."
}

stop_nexusp_now() {
  if ! is_nexusp_running; then
    echo "Info: nexusp backend is already paused (External Spool / LLL Plus mode active)."
    return 0
  fi
  if [ "${SKIP_CFS_RETRACT:-0}" != "1" ]; then
    retract_cfs_if_loaded
  fi
  if [ "$(id -u)" -eq 0 ]; then
    sh "$NEXUSP_SVC" stop >/dev/null 2>&1
  else
    start-stop-daemon -K -q -p /home/creality/run/nexusp.pid >/dev/null 2>&1 || killall nexusp >/dev/null 2>&1 || true
  fi
  sleep 1
  if ! is_nexusp_running; then
    echo "OK: nexusp backend paused (External Spool / LLL Plus mode active)."
  else
    echo "ERROR: Failed to stop nexusp backend!"
  fi
}

boot_check_and_start() {
  rm -f /tmp/lll_boot_decided /tmp/lll_boot_locked
  # Wait up to 60s for Klipper (_LLL_BOOT_NEXUSP_EVAL) or Moonraker (:7126) to report lll_plus_sensor state
  local i=0
  local resp=""
  while [ "$i" -lt 60 ]; do
    if [ -f /tmp/lll_boot_locked ]; then
      logger -t lll-nexusp-guard "Boot locked by Klipper LLL Plus sensor - keeping nexusp paused."
      exit 0
    fi
    if [ -f /tmp/lll_boot_decided ]; then
      logger -t lll-nexusp-guard "Boot released by Klipper LLL Plus sensor - starting nexusp for CFS-C."
      FORCE_NEXUSP=1 sh "$NEXUSP_SVC" start >/dev/null 2>&1
      exit 0
    fi
    resp=$(curl -s --max-time 2 "http://127.0.0" 2>/dev/null)
    if echo "$resp" | grep -Eq '"filament_detected"[[:space:]]*:[[:space:]]*true'; then
      touch /tmp/lll_boot_locked
      logger -t lll-nexusp-guard "Filament detected in FLY-LLL Plus (PD7) at boot - keeping nexusp paused."
      exit 0
    fi
    if echo "$resp" | grep -Eq '"filament_detected"[[:space:]]*:[[:space:]]*false'; then
      touch /tmp/lll_boot_decided
      logger -t lll-nexusp-guard "No filament in FLY-LLL Plus (PD7) at boot - starting nexusp for CFS-C."
      FORCE_NEXUSP=1 sh "$NEXUSP_SVC" start >/dev/null 2>&1
      exit 0
    fi
    sleep 1
    i=$((i + 1))
  done

  # FAIL-SAFE: Never start nexusp blindly if Klipper/Moonraker did not respond within 60s!
  logger -t lll-nexusp-guard "FAIL-SAFE: Sensor state unavailable after 60s - keeping nexusp paused to protect CFS/extruder."
  exit 0
}

function lll_nexusp_guard_message() {
  top_line
  title 'FLY-LLL Plus Nexusp Auto-Switch (PD7)' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Uses free pin !PD7 for FLY-LLL Plus filament detection.        ${white}│"
  echo -e " │ ${cyan}At boot: if filament is inserted in LLL Plus, nexusp stays     ${white}│"
  echo -e " │ ${cyan}paused so CFS-C will not feed its slots. Also adds Mainsail    ${white}│"
  echo -e " │ ${cyan}buttons (NEXUSP_ON_CFS / NEXUSP_OFF_EXTERNAL_SPOOL).           ${white}│"
  hr
  bottom_line
}

function install_lll_nexusp_guard() {
  lll_nexusp_guard_message
  local yn
  while true; do
    install_msg "FLY-LLL Plus Nexusp Auto-Switch" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        if ! grep -q "^\[include Helper-Script/cfs_lll_safety.cfg\]" "$PRINTER_CFG" 2>/dev/null; then
          error_msg "Please install FLY-LLL PLUS Safetysystem (Install Menu Option 16) first!"
          return
        fi
        if [ ! -f "$KLIPPY_EXTRAS/gcode_shell_command.py" ]; then
          error_msg "Klipper Gcode Shell Command is required! Please install it first."
          return
        fi
        if [ ! -f "$NEXUSP_SVC" ]; then
          error_msg "Creality nexusp init script ($NEXUSP_SVC) not found!"
          return
        fi

        mkdir -p "/usr/data/helper-script/backups" "$HS_CONFIG_FOLDER"
        if [ ! -f "$NEXUSP_BACKUP" ]; then
          cp -f "$NEXUSP_SVC" "$NEXUSP_BACKUP"
        fi

        cp -f "$CFG_SOURCE" "$CFG_TARGET"
        chown creality:creality "$CFG_TARGET" 2>/dev/null || true
        touch "$GUARD_FLAG"

        # Add [include Helper-Script/lll-plus-nexusp-switch.cfg] right after # CreateDate:
        sed -i '/\[include Helper-Script\/lll-plus-nexusp-switch\.cfg\]/d' "$PRINTER_CFG" 2>/dev/null || true
        if grep -q "^[[:space:]]*#[[:space:]]*CreateDate:" "$PRINTER_CFG" 2>/dev/null; then
          sed -i "/^[[:space:]]*#[[:space:]]*CreateDate:.*/a [include Helper-Script/lll-plus-nexusp-switch.cfg]" "$PRINTER_CFG"
        else
          sed -i '1a [include Helper-Script/lll-plus-nexusp-switch.cfg]' "$PRINTER_CFG"
        fi

        # Patch CS56nexusp_service start() to defer to boot guard unless FORCE_NEXUSP=1
        if ! grep -q "lll_nexusp_guard.sh" "$NEXUSP_SVC"; then
          sed -i '/^start() {/a \      if [ -f "/usr/data/printer_data/config/Helper-Script/.lll_nexusp_guard_enabled" ] && [ "${FORCE_NEXUSP:-0}" != "1" ]; then sh /usr/data/helper-script/scripts/lll_nexusp_guard.sh boot-guard \& return 0; fi' "$NEXUSP_SVC"
          chmod +x "$NEXUSP_SVC"
        fi

        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "FLY-LLL Plus Nexusp Auto-Switch (PD7) installed successfully!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
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
        echo -e "${white}"
        rm -f "$GUARD_FLAG" "$CFG_TARGET"
        sed -i '/\[include Helper-Script\/lll-plus-nexusp-switch\.cfg\]/d' "$PRINTER_CFG" 2>/dev/null || true
        if [ -f "$NEXUSP_BACKUP" ]; then
          cp -f "$NEXUSP_BACKUP" "$NEXUSP_SVC"
          chmod +x "$NEXUSP_SVC"
        fi
        if ! is_nexusp_running; then
          sh "$NEXUSP_SVC" start >/dev/null 2>&1 || true
        fi
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "FLY-LLL Plus Nexusp Auto-Switch removed and stock nexusp restored!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

case "$1" in
  boot-guard)
    boot_check_and_start
    ;;
  boot-lock)
    touch /tmp/lll_boot_locked
    SKIP_CFS_RETRACT=1 stop_nexusp_now
    ;;
  boot-release)
    touch /tmp/lll_boot_decided
    start_nexusp_now
    ;;
  on)
    start_nexusp_now
    ;;
  off)
    stop_nexusp_now
    ;;
  toggle)
    if is_nexusp_running; then
      stop_nexusp_now
    else
      start_nexusp_now
    fi
    ;;
  status)
    if is_nexusp_running; then
      echo "Nexusp Backend: RUNNING (CFS-C Mode Active)"
    else
      echo "Nexusp Backend: PAUSED (External Spool / FLY-LLL Plus Mode Active)"
    fi
    ;;
esac
