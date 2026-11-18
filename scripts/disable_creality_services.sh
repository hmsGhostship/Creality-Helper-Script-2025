#!/bin/sh

set -e

CREALITY_SERVICES_NEVER_DISABLE="S55klipper_service CS55klipper_service S56nexusp_service CS56nexusp_service S59quintusp CS59quintusp S60gui_service CS60gui_service"

function disable_creality_services_message(){
  top_line
  title 'Disable Creality Stock Services' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Creality's stock firmware runs background daemons that upload  ${white}│"
  echo -e " │ ${cyan}configuration and logs to Creality, plus WebRTC daemons that   ${white}│"
  echo -e " │ ${cyan}go inert once the Built-in Camera Fix takes the camera.        ${white}│"
  echo -e " │ ${cyan}This disables the non-essential ones. It can be undone.        ${white}│"
  hr
  bottom_line
}

function restore_creality_services_message(){
  top_line
  title 'Restore Creality Stock Services' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}This re-enables the Creality stock services turned off by the  ${white}│"
  echo -e " │ ${cyan}Disable Creality Stock Services option.                        ${white}│"
  hr
  bottom_line
}

function disable_creality_mdns_message(){
  top_line
  title 'Disable Creality mDNS Advertising' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Disables Creality's mDNS daemon (CS99mdns). This stops the     ${white}│"
  echo -e " │ ${cyan}<hostname>.local resolution and automatic Creality Print / app ${white}│"
  echo -e " │ ${cyan}discovery on the local network. Useful to prevent duplicate    ${white}│"
  echo -e " │ ${cyan}printer entries in your slicer.                                ${white}│"
  hr
  bottom_line
}

function restore_creality_mdns_message(){
  top_line
  title 'Restore Creality mDNS Advertising' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Re-enables Creality's mDNS daemon (CS99mdns) for local         ${white}│"
  echo -e " │ ${cyan}<hostname>.local resolution and slicer auto-discovery.         ${white}│"
  hr
  bottom_line
}

function creality_service_disabled_path() {
  echo "$(dirname "$1")/disabled.$(basename "$1")"
}

function creality_core_services() {
  local mode="${1:-standard}"
  if [ "$mode" = "cfs" ]; then
    echo "$CREALITY_TELEMETRY_SERVICE $CREALITY_CLOUD_WEBRTC_SERVICE $CREALITY_LOCAL_WEBRTC_SERVICE"
  else
    echo "$CREALITY_TELEMETRY_SERVICE $CREALITY_CLOUD_WEBRTC_SERVICE $CREALITY_LOCAL_WEBRTC_SERVICE $CREALITY_AI_SERVICE"
  fi
}

function creality_services_pending() {
  local svc
  for svc in $(creality_core_services "$1"); do
    if [ -f "$svc" ]; then
      return 0
    fi
  done
  return 1
}

function creality_services_disabled_present() {
  local svc
  for svc in $(creality_core_services "$1"); do
    if [ -f "$(creality_service_disabled_path "$svc")" ]; then
      return 0
    fi
  done
  return 1
}

function creality_services_absent() {
  if creality_services_pending "$1" || creality_services_disabled_present "$1"; then
    return 1
  fi
  return 0
}

# Custom menu checks for mDNS
function creality_mdns_absent() {
  if [ -f "$CREALITY_MDNS_SERVICE" ] || [ -f "$(creality_service_disabled_path "$CREALITY_MDNS_SERVICE")" ]; then
    return 1
  fi
  return 0
}

function creality_mdns_disabled() {
  if [ -f "$(creality_service_disabled_path "$CREALITY_MDNS_SERVICE")" ]; then
    return 0
  fi
  return 1
}

function creality_builtin_camera_fix_installed() {
  if [ ! -f "$BUILTIN_CAMERA_FILE" ] && [ ! -f "$BUILTIN_CAMERA_LEGACY_FILE" ]; then
    return 1
  fi
  return 0
}

function creality_print_in_progress() {
  local port body state seen_idle
  seen_idle=""
  for port in 7126 7125; do
    body="$("$CURL" -s -m 3 "http://127.0.0.1:${port}/printer/objects/query?print_stats" 2>/dev/null)"
    case "$body" in
      *'"print_stats"'*)
        ;;
      *)
        continue;;
    esac
    state="$(echo "$body" | sed 's/.*"print_stats"//' | grep -o '"state"[[:space:]]*:[[:space:]]*"[A-Za-z_]*"' | head -n 1 | sed 's/.*"\([A-Za-z_]*\)"$/\1/')"
    case "$state" in
      printing|paused)
        return 0;;
      standby|complete|completed|cancelled|canceled|error)
        seen_idle="1";;
      *)
        ;;
    esac
  done
  if [ -n "$seen_idle" ]; then
    return 1
  fi
  return 2
}

CREALITY_SERVICES_CHANGED=0
CREALITY_SERVICES_FAILED=0
CREALITY_SERVICES_STILL_RUNNING=""

function creality_disable_one_service() {
  local svc="$1"
  local proc="$2"
  local label="$3"
  local disabled_svc never

  for never in $CREALITY_SERVICES_NEVER_DISABLE; do
    if [ "$(basename "$svc")" = "$never" ]; then
      error_msg "$never is required by the printer and will not be disabled!"
      CREALITY_SERVICES_FAILED=$((CREALITY_SERVICES_FAILED + 1))
      return
    fi
  done

  disabled_svc="$(creality_service_disabled_path "$svc")"
  if [ ! -f "$svc" ]; then
    if [ -f "$disabled_svc" ]; then
      echo -e "Info: $label is already disabled, skipping..."
    else
      echo -e "Info: $label is not present on this firmware, skipping..."
    fi
    return
  fi
  if [ -f "$disabled_svc" ]; then
    echo -e "${yellow}Warning: both $(basename "$svc") and $(basename "$disabled_svc") exist.${white}"
    echo -e "${yellow}The firmware likely recreated it. Leaving it alone to avoid losing the backup.${white}"
    CREALITY_SERVICES_FAILED=$((CREALITY_SERVICES_FAILED + 1))
    return
  fi

  echo -e "Info: Stopping and disabling $label..."
  set +e
  "$svc" stop > /dev/null 2>&1
  if [ -n "$proc" ]; then
    killall -q "$proc"
  fi
  set -e
  if ! mv "$svc" "$disabled_svc" 2>/dev/null; then
    error_msg "Could not rename $(basename "$svc") - is $(dirname "$svc") writable?"
    set +e
    "$svc" start > /dev/null 2>&1
    set -e
    CREALITY_SERVICES_FAILED=$((CREALITY_SERVICES_FAILED + 1))
    return
  fi
  CREALITY_SERVICES_CHANGED=$((CREALITY_SERVICES_CHANGED + 1))
  if [ -n "$proc" ]; then
    set +e
    pidof "$proc" > /dev/null 2>&1
    if [ "$?" = "0" ]; then
      CREALITY_SERVICES_STILL_RUNNING="$CREALITY_SERVICES_STILL_RUNNING $proc"
    fi
    set -e
  fi
}

function creality_restore_one_service() {
  local svc="$1"
  local label="$2"
  local disabled_svc

  disabled_svc="$(creality_service_disabled_path "$svc")"
  if [ ! -f "$disabled_svc" ]; then
    echo -e "Info: $label is not disabled, skipping..."
    return
  fi
  if [ -f "$svc" ]; then
    echo -e "${yellow}Warning: $(basename "$svc") already exists - the firmware recreated it.${white}"
    echo -e "${yellow}Keeping the newer file; $(basename "$disabled_svc") left in place.${white}"
    CREALITY_SERVICES_FAILED=$((CREALITY_SERVICES_FAILED + 1))
    return
  fi
  echo -e "Info: Restoring and starting $label..."
  if ! mv "$disabled_svc" "$svc" 2>/dev/null; then
    error_msg "Could not restore $(basename "$svc") - is $(dirname "$svc") writable?"
    CREALITY_SERVICES_FAILED=$((CREALITY_SERVICES_FAILED + 1))
    return
  fi
  CREALITY_SERVICES_CHANGED=$((CREALITY_SERVICES_CHANGED + 1))
  set +e
  "$svc" start > /dev/null 2>&1
  set -e
}

function creality_confirm_printer_idle() {
  local print_state confirm
  set +e
  creality_print_in_progress
  print_state=$?
  set -e
  if [ "$print_state" -eq 0 ]; then
    error_msg "A print is in progress, please wait until it is finished!"
    return 1
  fi
  if [ "$print_state" -eq 2 ]; then
    echo -e " ${yellow}Warning: printer state could not be read on port 7126 or 7125.${white}"
    echo
    read -p " ${white}Confirm that no print is running (${yellow}y${white}/${yellow}n${white}): ${yellow}" confirm
    echo -e "${white}"
    case "${confirm}" in
      Y|y)
        return 0;;
      *)
        error_msg "Operation canceled!"
        return 1;;
    esac
  fi
  return 0
}

function disable_creality_services(){
  local mode="${1:-standard}"
  disable_creality_services_message
  echo
  echo -e " ${yellow}Warning: these services live on a partition that survives a factory"
  echo -e " reset, so a reset will not bring them back. Use Restore Creality Stock"
  echo -e " Services to undo this.${white}"
  echo
  local yn disable_webrtc webrtc_yn disable_solusp solusp_yn
  while true; do
    disable_msg "Creality Stock Services" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        if ! creality_confirm_printer_idle; then
          return
        fi

        #1. WebRTC Camera Services (onyxp/thirteenthp)
        disable_webrtc="no"
        if creality_builtin_camera_fix_installed; then
          disable_webrtc="yes"
        else
          echo -e " ${yellow}Warning: the Built-in Camera Fix is not installed.${white}"
          echo -e " ${yellow}Disabling the WebRTC services without it will stop the built-in${white}"
          echo -e " ${yellow}camera stream in Creality Print and the Creality Cloud app.${white}"
          echo -e " ${yellow}(Mainsail/Fluidd with a USB camera are not affected.)${white}"
          echo
          read -p " ${white}Disable ${green}WebRTC camera services ${white}anyway? (${yellow}y${white}/${yellow}n${white}): ${yellow}" webrtc_yn
          echo -e "${white}"
          case "${webrtc_yn}" in
            Y|y)
              disable_webrtc="yes";;
            *)
              echo -e "Info: Leaving WebRTC services enabled to preserve stock camera..."
              echo;;
          esac
        fi

        # 2. solusp (AI & hardware service)
        disable_solusp="no"
        if [ "$mode" = "cfs" ]; then
          disable_solusp="no"
        elif creality_builtin_camera_fix_installed; then
          disable_solusp="yes"
        else
          if [ -f "$CREALITY_AI_SERVICE" ]; then
            echo -e " ${yellow}Warning: solusp handles Creality AI failure detection and parts${white}"
            echo -e " ${yellow}of the stock hardware/calibration routines (e.g. Input Shaper).${white}"
            echo -e " ${yellow}Disabling it saves RAM, but disables AI detection and may affect${white}"
            echo -e " ${yellow}stock screen calibrations.${white}"
            echo
            read -p " ${white}Also disable ${green}Creality AI / hardware service (solusp) ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" solusp_yn
            echo -e "${white}"
            case "${solusp_yn}" in
              Y|y)
                disable_solusp="yes";;
              *)
                echo -e "Info: Leaving solusp enabled..."
                echo;;
            esac
          fi
        fi

        if ! creality_confirm_printer_idle; then
          return
        fi

        CREALITY_SERVICES_CHANGED=0
        CREALITY_SERVICES_FAILED=0
        CREALITY_SERVICES_STILL_RUNNING=""
        creality_disable_one_service "$CREALITY_TELEMETRY_SERVICE" "alchemistp" "Creality telemetry agent (alchemistp)"

        if [ "$disable_webrtc" = "yes" ]; then
          creality_disable_one_service "$CREALITY_CLOUD_WEBRTC_SERVICE" "onyxp" "Creality cloud WebRTC signalling (onyxp)"
          creality_disable_one_service "$CREALITY_LOCAL_WEBRTC_SERVICE" "thirteenthp" "Creality local WebRTC media server (thirteenthp)"
        fi

        if [ "$disable_solusp" = "yes" ]; then
          creality_disable_one_service "$CREALITY_AI_SERVICE" "solusp" "Creality AI failure detection (solusp)"
        elif [ "$mode" = "cfs" ]; then
          echo -e "Info: Leaving Creality hardware/AI service (solusp) enabled for CFS-C..."
        fi

        if [ "$CREALITY_SERVICES_CHANGED" -eq 0 ]; then
          error_msg "No Creality stock services were disabled!"
          if [ "$CREALITY_SERVICES_FAILED" -gt 0 ]; then
            echo -e " ${darkred}$CREALITY_SERVICES_FAILED service(s) could not be disabled - see the messages above.${white}"
          else
            echo -e " ${darkred}None of the expected service files were found on this firmware.${white}"
          fi
          echo
          return
        fi
        ok_msg "$CREALITY_SERVICES_CHANGED Creality stock service(s) have been disabled successfully!"
        if [ "$CREALITY_SERVICES_FAILED" -gt 0 ]; then
          echo -e "   ${yellow}$CREALITY_SERVICES_FAILED service(s) were skipped - see the messages above.${white}"
        fi
        if [ -n "$CREALITY_SERVICES_STILL_RUNNING" ]; then
          echo -e "   ${yellow}Still running:$CREALITY_SERVICES_STILL_RUNNING - please reboot to stop them.${white}"
        else
          echo -e "   ${cyan}The services were stopped, so no reboot is needed.${white}"
        fi
        echo -e "   ${cyan}The change persists across reboots and factory resets until restored.${white}"
        return;;
      N|n)
        error_msg "Disabling canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function disable_creality_services_cfs_c(){
  disable_creality_services "cfs"
}

function restore_creality_services(){
  local mode="${1:-standard}"
  restore_creality_services_message
  local yn ans restore_tele restore_cloud_webrtc restore_local_webrtc restore_solusp
  while true; do
    restore_msg "Creality Stock Services" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        if ! creality_confirm_printer_idle; then
          return
        fi

        # 1. Check Built-in Camera Fix on /dev/video0
        if creality_builtin_camera_fix_installed; then
          if [ -f "$(creality_service_disabled_path "$CREALITY_CLOUD_WEBRTC_SERVICE")" ] || [ -f "$(creality_service_disabled_path "$CREALITY_LOCAL_WEBRTC_SERVICE")" ]; then
            echo -e " ${yellow}Warning: the Built-in Camera Fix is currently installed!${white}"
            echo -e " ${yellow}WebRTC camera services (onyxp / thirteenthp) cannot be restored while it is active.${white}"
            echo
            read -p " ${white}Remove ${green}Built-in Camera Fix ${white}first to allow restoring stock camera? (${yellow}y${white}/${yellow}n${white}): ${yellow}" ans
            echo -e "${white}"
            case "${ans}" in
              Y|y)
                echo -e "Info: Stopping and removing Built-in Camera Fix..."
                set +e
                [ -f "$BUILTIN_CAMERA_FILE" ] && "$BUILTIN_CAMERA_FILE" stop
                [ -f "$BUILTIN_CAMERA_LEGACY_FILE" ] && "$BUILTIN_CAMERA_LEGACY_FILE" stop
                set -e
                rm -f "$BUILTIN_CAMERA_FILE" "$BUILTIN_CAMERA_LEGACY_FILE"
                [ -f "$MOONRAKER_CFG" ] && sed -i '/^\[webcam chassis\]/,/^$/d' "$MOONRAKER_CFG"
                type sync_timelapse_snapshot_url_k1_2025 >/dev/null 2>&1 && sync_timelapse_snapshot_url_k1_2025
                type sync_octoeverywhere_camera_k1_2025 >/dev/null 2>&1 && sync_octoeverywhere_camera_k1_2025
                ;;
              *)
                echo -e "Info: Keeping Built-in Camera Fix active. Skipping WebRTC services..."
                echo;;
            esac
          fi
        fi

        # 2. Check Go2rtc in chassis mode on /dev/video0
        if [ "$(get_go2rtc_mode_k1_2025 2>/dev/null)" = "chassis" ]; then
          if [ -f "$(creality_service_disabled_path "$CREALITY_CLOUD_WEBRTC_SERVICE")" ] || [ -f "$(creality_service_disabled_path "$CREALITY_LOCAL_WEBRTC_SERVICE")" ]; then
            echo -e " ${yellow}Warning: Go2rtc is currently using the built-in chassis camera!${white}"
            echo -e " ${yellow}WebRTC camera services (onyxp / thirteenthp) cannot be restored while Go2rtc uses /dev/video0.${white}"
            echo
            read -p " ${white}Remove ${green}Go2rtc ${white}first to allow restoring stock camera? (${yellow}y${white}/${yellow}n${white}): ${yellow}" ans
            echo -e "${white}"
            case "${ans}" in
              Y|y)
                echo -e "Info: Stopping and removing Go2rtc..."
                stop_go2rtc
                rm -f "$GO2RTC_SERVICE_FILE" "$GO2RTC_CONFIG_FILE" "$GO2RTC_FILE"
                [ -f "$MOONRAKER_CFG" ] && sed -i '/^\[webcam chassis\]/,/^$/d' "$MOONRAKER_CFG"
                type sync_timelapse_snapshot_url_k1_2025 >/dev/null 2>&1 && sync_timelapse_snapshot_url_k1_2025
                type sync_octoeverywhere_camera_k1_2025 >/dev/null 2>&1 && sync_octoeverywhere_camera_k1_2025
                ;;
              *)
                echo -e "Info: Keeping Go2rtc active. Skipping WebRTC services..."
                echo;;
            esac
          fi
        fi

        restore_tele="no"
        restore_cloud_webrtc="no"
        restore_local_webrtc="no"
        restore_solusp="no"

        # Einzelabfrage 1: Telemetry (alchemistp)
        if [ -f "$(creality_service_disabled_path "$CREALITY_TELEMETRY_SERVICE")" ]; then
          echo -e " ${cyan}Info: alchemistp collects and uploads usage logs to Creality servers.${white}"
          read -p " ${white}Restore ${green}Creality telemetry agent (alchemistp)${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" ans
          echo -e "${white}"
          case "${ans}" in Y|y) restore_tele="yes";; esac
        fi

        # Einzelabfrage 2 & 3: Cloud WebRTC (onyxp) & Local WebRTC (thirteenthp) getrennt!
        if ! creality_builtin_camera_fix_installed && [ "$(get_go2rtc_mode_k1_2025 2>/dev/null)" != "chassis" ]; then
          if [ -f "$(creality_service_disabled_path "$CREALITY_CLOUD_WEBRTC_SERVICE")" ]; then
            echo -e " ${cyan}Info: onyxp provides remote camera access for the Creality Cloud app.${white}"
            read -p " ${white}Restore ${green}Creality cloud WebRTC signalling (onyxp)${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" ans
            echo -e "${white}"
            case "${ans}" in Y|y) restore_cloud_webrtc="yes";; esac
          fi
          if [ -f "$(creality_service_disabled_path "$CREALITY_LOCAL_WEBRTC_SERVICE")" ]; then
            echo -e " ${cyan}Info: thirteenthp provides the local video stream for Creality Print.${white}"
            read -p " ${white}Restore ${green}Creality local WebRTC media server (thirteenthp)${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" ans
            echo -e "${white}"
            case "${ans}" in Y|y) restore_local_webrtc="yes";; esac
          fi
        fi

        # Einzelabfrage 4: AI / hardware service (solusp)
        if [ -f "$(creality_service_disabled_path "$CREALITY_AI_SERVICE")" ]; then
          if [ "$mode" = "cfs" ]; then
            restore_solusp="yes"
          elif ! creality_builtin_camera_fix_installed && [ "$(get_go2rtc_mode_k1_2025 2>/dev/null)" != "chassis" ]; then
            echo -e " ${cyan}Info: solusp handles Creality AI failure detection and screen routines.${white}"
            read -p " ${white}Restore ${green}Creality AI / hardware service (solusp)${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" ans
            echo -e "${white}"
            case "${ans}" in Y|y) restore_solusp="yes";; esac
          fi
        fi

        CREALITY_SERVICES_CHANGED=0
        CREALITY_SERVICES_FAILED=0

        [ "$restore_tele" = "yes" ] && creality_restore_one_service "$CREALITY_TELEMETRY_SERVICE" "Creality telemetry agent (alchemistp)"
        [ "$restore_cloud_webrtc" = "yes" ] && creality_restore_one_service "$CREALITY_CLOUD_WEBRTC_SERVICE" "Creality cloud WebRTC signalling (onyxp)"
        [ "$restore_local_webrtc" = "yes" ] && creality_restore_one_service "$CREALITY_LOCAL_WEBRTC_SERVICE" "Creality local WebRTC media server (thirteenthp)"
        [ "$restore_solusp" = "yes" ] && creality_restore_one_service "$CREALITY_AI_SERVICE" "Creality AI failure detection (solusp)"

        if [ "$CREALITY_SERVICES_CHANGED" -eq 0 ]; then
          error_msg "No Creality stock services were restored!"
          return
        fi
        ok_msg "$CREALITY_SERVICES_CHANGED Creality stock service(s) have been restored successfully!"
        if [ "$restore_cloud_webrtc" = "yes" ] || [ "$restore_local_webrtc" = "yes" ]; then
          echo
          echo -e " ${yellow}Note: The camera driver (/dev/video0) often needs a reboot to re-initialize${white}"
          echo -e " ${yellow}for Creality Print / WebRTC after switching from mjpg-streamer or Go2rtc.${white}"
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

function restore_creality_services_cfs_c(){
  restore_creality_services "cfs"
}

# --- Standalone mDNS functions ---

function disable_creality_mdns(){
  disable_creality_mdns_message
  echo
  echo -e " ${yellow}Warning: disabling mDNS stops <hostname>.local resolution and"
  echo -e " automatic Creality Print / app discovery on the local network.${white}"
  echo
  local yn
  while true; do
    disable_msg "Creality mDNS Advertising" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        CREALITY_SERVICES_CHANGED=0
        CREALITY_SERVICES_FAILED=0
        CREALITY_SERVICES_STILL_RUNNING=""
        creality_disable_one_service "$CREALITY_MDNS_SERVICE" "mdns" "Creality mDNS advertising (mdns)"
        if [ "$CREALITY_SERVICES_CHANGED" -eq 0 ]; then
          error_msg "Creality mDNS advertising could not be disabled!"
          echo
          return
        fi
        ok_msg "Creality mDNS advertising has been disabled successfully!"
        if [ -n "$CREALITY_SERVICES_STILL_RUNNING" ]; then
          echo -e "   ${yellow}Still running:$CREALITY_SERVICES_STILL_RUNNING - please reboot to stop it.${white}"
        fi
        echo -e "   ${cyan}The change persists across reboots and factory resets until restored.${white}"
        return;;
      N|n)
        error_msg "Disabling canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function restore_creality_mdns(){
  restore_creality_mdns_message
  local yn
  while true; do
    restore_msg "Creality mDNS Advertising" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        CREALITY_SERVICES_CHANGED=0
        CREALITY_SERVICES_FAILED=0
        creality_restore_one_service "$CREALITY_MDNS_SERVICE" "Creality mDNS advertising (mdns)"
        if [ "$CREALITY_SERVICES_CHANGED" -eq 0 ]; then
          error_msg "Creality mDNS advertising could not be restored!"
          echo
          return
        fi
        ok_msg "Creality mDNS advertising has been restored successfully!"
        return;;
      N|n)
        error_msg "Restoration canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}
