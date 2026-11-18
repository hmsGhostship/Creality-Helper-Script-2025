#!/bin/sh

set -e

function octoeverywhere_message(){
  top_line
  title 'OctoEverywhere' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Secure, private, and unlimited remote access to your full      ${white}│"
  echo -e " │ ${cyan}web control portal from anywhere with AI print failure         ${white}│"
  echo -e " │ ${cyan}detection.                                                     ${white}│"
  hr
  bottom_line
}

function install_octoeverywhere(){
  octoeverywhere_message
  local yn
  while true; do
    echo -e "${yellow} ┌────────────────────────────────────────────────────────┐"
    echo -e " │  NOTICE: This installation temporarily requires free   │"
    echo -e " │  system RAM. After a successful setup, the printer will│"
    echo -e " │  AUTOMATICALLY REBOOT (Your SSH session will close)!   │"
    echo -e " └────────────────────────────────────────────────────────┘${white}"
    echo
    
    install_msg "OctoEverywhere" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"

        # 0. Check RAM guard (35 MB steady usage + 15 MB reserve)
        if ! check_ram_requirement "OctoEverywhere" 35; then return; fi

        # 1. Dynamische Moonraker-Python-Umgebung ermitteln
        echo -e "Info: Detecting Moonraker Python Environment..."
        local active_python=$(ps w | grep moonraker | grep -v grep | awk '{print $5}')
        if [ -z "$active_python" ] || [ ! -f "$active_python" ]; then
          active_python="$MOONRAKER_ENV_PYTHON"
        fi
        if [ ! -f "$active_python" ]; then
          error_msg "Error: No valid Moonraker Python environment found!"
          return 1
        fi
        local active_venv=$(dirname "$(dirname "$active_python")")
        echo -e "Info: Nutze Python-Umgebung: $active_python"

        # 2. Free RAM & temporarily stop Klipper (for pip installation)
        echo -e "Info: Stopping Klipper and Creality services to secure CPU & RAM..."
        if [ -f "/usr/apps/etc/init.d/CS55klipper_service" ]; then
          /usr/apps/etc/init.d/CS55klipper_service stop >/dev/null 2>&1 || true
        fi
        kill -9 $(ps w | grep "klippy.py" | grep -v grep | awk '{print $1}') 2>/dev/null || true
        killall -9 go2rtc_linux_mipsel >/dev/null 2>&1 || true
        killall -9 alchemistp >/dev/null 2>&1 || true
        rm -rf "/usr/data/octoeverywhere-env"
        sleep 3

        # 3. Repository klonen
        echo -e "Info: Updating OctoEverywhere Repository..."
        if [ -d "$OCTOEVERYWHERE_FOLDER" ]; then
          rm -rf "$OCTOEVERYWHERE_FOLDER"
        fi
        git config --global http.sslVerify false
        git clone --depth 1 "$OCTOEVERYWHERE_URL" "$OCTOEVERYWHERE_FOLDER"

        # 4. Install dependencies into Moonraker Python environment with low RAM footprint
        echo -e "Info: Installing OctoEverywhere dependencies..."
        local TMP_REQ="/tmp/octo-req.txt"
        if [ -f "$OCTOEVERYWHERE_FOLDER/requirements.txt" ]; then
          grep -v -E -i "pillow|pybind11" "$OCTOEVERYWHERE_FOLDER/requirements.txt" > "$TMP_REQ"
          "$active_python" -m pip install --no-cache-dir -r "$TMP_REQ"
          rm -f "$TMP_REQ"
        fi

        # 5. Speicherordner & Initial-Konfiguration (Frontend-Port & Kamera) anlegen
        local OCTO_STORE_DIR="${PRINTER_DATA_FOLDER}/octoeverywhere-store"
        local OCTO_CONF="${PRINTER_DATA_FOLDER}/config/octoeverywhere.conf"
        mkdir -p "$OCTO_STORE_DIR"

        local web_port=4409
        if [ ! -d "$MAINSAIL_FOLDER" ] && [ -d "$FLUIDD_FOLDER" ]; then
          web_port=4408
        fi

        local cam_auto="True"
        local cam_stream="/webcam/?action=stream"
        local cam_snap="/webcam/?action=snapshot"
        if [ -f "$USB_CAMERA_FILE" ]; then
          echo -e "Info: USB camera detected (priority 1). Configuring /webcam3/..."
          cam_auto="False"
          cam_stream="/webcam3/?action=stream"
          cam_snap="/webcam3/?action=snapshot"
        elif [ -f "$BUILTIN_CAMERA_FILE" ]; then
          echo -e "Info: Built-in Camera Fix detected. Configuring /webcam/..."
          cam_auto="False"
          cam_stream="/webcam/?action=stream"
          cam_snap="/webcam/?action=snapshot"
        fi

        local octo_log_level="WARNING"
        local octo_log_size="1"
        echo
        echo -e " ${cyan}Select OctoEverywhere log level:${white}"
        echo -e "  ${yellow}1)${white} WARNING (Recommended for K1 2025 - saves RAM & eMMC flash)"
        echo -e "  ${yellow}2)${white} INFO    (Verbose logging - useful for initial pairing/debugging)"
        echo -e "  ${yellow}3)${white} ERROR   (Minimal logging - errors only)"
        echo
        local log_choice
        read -p " ${white}Choose log level (${yellow}1${white}/${yellow}2${white}/${yellow}3${white}, default ${yellow}1${white}): ${yellow}" log_choice
        echo -e "${white}"
        case "${log_choice}" in
          2) octo_log_level="INFO"; octo_log_size="3" ;;
          3) octo_log_level="ERROR"; octo_log_size="1" ;;
          *) octo_log_level="WARNING"; octo_log_size="1" ;;
        esac

        echo -e "Info: Writing octoeverywhere.conf (Frontend Port: $web_port)..."
        cat << EOF > "$OCTO_CONF"
[logging]
log_level = ${octo_log_level}
max_file_size_mb = ${octo_log_size}
max_file_count = 1

[server]

[general]
bed_cooldown_threshold_temp_celsius = 40.0

[relay]
frontend_port = $web_port

[webcam]
webcam_name_to_use_as_primary = Default
auto_settings_detection = $cam_auto
stream_url = $cam_stream
snapshot_url = $cam_snap
flip_horizontally = False
flip_vertically = False
rotate = 0

[moonraker]
moonraker_api_key =
EOF

        # 6. Clean up Moonraker configuration (no legacy [octoeverywhere] header needed)
        if [ -f "$MOONRAKER_CFG" ]; then
          sed -i '/^\[octoeverywhere\]$/d' "$MOONRAKER_CFG" 2>/dev/null || true
        fi

        # 7. Write persistent init script with Base64 JSON config & boot delay
        echo -e "Info: Writing persistent startup script..."
        local OCTO_INIT_SCRIPT="${INITD_FOLDER}/S99octoeverywhere"
        local B64_ARGS
        B64_ARGS=$("$active_python" -c "import json, base64; cfg={'ServiceName':'octoeverywhere','VirtualEnvPath':'$active_venv','RepoRootFolder':'$OCTOEVERYWHERE_FOLDER','LocalFileStoragePath':'$OCTO_STORE_DIR','ConfigFolder':'${PRINTER_DATA_FOLDER}/config','LogFolder':'${PRINTER_DATA_FOLDER}/logs','MoonrakerConfigFile':'$MOONRAKER_CFG'}; print(base64.urlsafe_b64encode(json.dumps(cfg).encode('utf-8')).decode('utf-8'))")

        cat << EOF > "$OCTO_INIT_SCRIPT"
#!/bin/sh

case "\$1" in
  start)
    echo "Starting OctoEverywhere Daemon..."
    nohup /bin/sh -c '[ "\$1" != "now" ] && sleep 20; cd $OCTOEVERYWHERE_FOLDER && PYTHONPATH=$OCTOEVERYWHERE_FOLDER exec $active_python -m moonraker_octoeverywhere "$B64_ARGS" > ${PRINTER_DATA_FOLDER}/logs/octoeverywhere.log 2>&1' _ "\$2" </dev/null >/dev/null 2>&1 &
    ;;
  stop)
    echo "Stopping OctoEverywhere..."
    PIDS=\$(ps w | grep "moonraker_octoeverywhere" | grep -v grep | awk '{print \$1}')
    if [ -n "\$PIDS" ]; then
      kill -9 \$PIDS >/dev/null 2>&1 || true
    fi
    ;;
  restart)
    \$0 stop || true
    sleep 1
    \$0 start now
    ;;
  *)
    echo "Usage: \$0 {start|stop|restart}"
    exit 1
    ;;
esac
EOF
        chmod +x "$OCTO_INIT_SCRIPT"
        
        # 8. Automatic system reboot to clear RAM
        for i in 10 9 8 7 6 5 4 3 2 1; do
            echo -e "    Printer will reboot in $i seconds... \r\c"
            sleep 1
        done
        reboot
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_octoeverywhere(){
  octoeverywhere_message
  local yn
  while true; do
    remove_msg "OctoEverywhere" yn
    case "${yn}" in
      Y|y)
      if [ -f "${INITD_FOLDER}/S99octoeverywhere" ]; then
       "${INITD_FOLDER}/S99octoeverywhere" stop >/dev/null 2>&1 || true
       rm -f "${INITD_FOLDER}/S99octoeverywhere"
      fi
        rm -rf "$OCTOEVERYWHERE_FOLDER"
        rm -rf "/usr/data/octoeverywhere-env"
        rm -rf "${PRINTER_DATA_FOLDER}/octoeverywhere-store"
        rm -f "${PRINTER_DATA_FOLDER}/config/octoeverywhere.conf"
        rm -f "${PRINTER_DATA_FOLDER}/config/octoeverywhere-system.cfg"
        rm -f "${PRINTER_DATA_FOLDER}/logs/octoeverywhere.log"

        if [ -f "$MOONRAKER_CFG" ]; then
          sed -i '/octoeverywhere/d' "$MOONRAKER_CFG" || true
        fi

        echo -e "Info: Restarting Moonraker service..."
        if command -v stop_moonraker >/dev/null 2>&1 && command -v start_moonraker >/dev/null 2>&1; then
          stop_moonraker && sleep 1 && start_moonraker
        elif [ -f "$INITD_FOLDER/S56moonraker_service" ]; then
          "$INITD_FOLDER/S56moonraker_service" restart >/dev/null 2>&1 || true
        fi

        ok_msg "OctoEverywhere has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function show_octoeverywhere_link(){
  octoeverywhere_message
  local log_file="${PRINTER_DATA_FOLDER}/logs/octoeverywhere.log"
  local init_script="${INITD_FOLDER}/S99octoeverywhere"

  if [ ! -f "$init_script" ]; then
    error_msg "OctoEverywhere is not installed!"
    return 1
  fi

  echo -e " ${white}Checking OctoEverywhere connection status...${white}"

  # Start daemon if not running yet
  if ! ps w | grep "moonraker_octoeverywhere" | grep -v grep >/dev/null 2>&1; then
    echo -e " ${yellow}Daemon is not running. Starting OctoEverywhere now...${white}"
    "$init_script" start now >/dev/null 2>&1
    sleep 4
  fi

  local code
  code=$(grep "Code:" "$log_file" 2>/dev/null | tail -n 1 | awk '{print $NF}' | tr -d '\r')

  echo
  if grep -q "plugin-account-link-status:<true>" "$log_file" 2>/dev/null; then
    ok_msg "Your printer is ALREADY linked and connected to OctoEverywhere!"
  elif [ -n "$code" ]; then
    echo -e " ${green}┌────────────────────────────────────────────────────────┐${white}"
    echo -e " ${green}│  OCTOEVERYWHERE PAIRING CODE                           │${white}"
    echo -e " ${green}│                                                        │${white}"
    echo -e " ${green}│  1. Open:  ${cyan}https://octoeverywhere.com${green}                  │${white}"
    printf " ${green}│  2. Code:  ${yellow}%-44s${green}│${white}\n" "$code"
    echo -e " ${green}└────────────────────────────────────────────────────────┘${white}"
    echo
    local regen_yn
    read -p " ${white}Code expired? Restart daemon for a fresh code? (${yellow}y${white}/${yellow}n${white}): ${yellow}" regen_yn
    echo -e "${white}"
    case "${regen_yn}" in
      Y|y)
        echo -e " ${cyan}Restarting OctoEverywhere daemon...${white}"
        "$init_script" restart >/dev/null 2>&1
        sleep 4
        code=$(grep "Code:" "$log_file" 2>/dev/null | tail -n 1 | awk '{print $NF}' | tr -d '\r')
        echo -e " ${green}New Pairing Code: ${yellow}${code}${white}"
        echo
        ;;
    esac
  else
    echo -e " ${yellow}No pairing code found yet. Restarting daemon...${white}"
    "$init_script" restart >/dev/null 2>&1
    sleep 4
    code=$(grep "Code:" "$log_file" 2>/dev/null | tail -n 1 | awk '{print $NF}' | tr -d '\r')
    if [ -n "$code" ]; then
      echo -e " ${green}New Pairing Code: ${yellow}${code}${white}"
      echo -e " ${white}Enter at: ${cyan}https://octoeverywhere.com{white}"
    else
      error_msg "Could not read code yet. Wait 10s and run 25a again."
    fi
    echo
  fi
}

function configure_octoeverywhere_log_level(){
  octoeverywhere_message
  local octo_conf="${PRINTER_DATA_FOLDER}/config/octoeverywhere.conf"
  local init_script="${INITD_FOLDER}/S99octoeverywhere"

  if [ ! -f "$octo_conf" ] && [ ! -f "$init_script" ]; then
    error_msg "OctoEverywhere is not installed!"
    return
  fi

  local cur_level="unknown"
  if [ -f "$octo_conf" ]; then
    cur_level=$(awk -F'=' '/^log_level[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "$octo_conf" 2>/dev/null)
  fi

  echo -e " ${cyan}Current OctoEverywhere log level:${white} ${yellow}${cur_level:-INFO}${white}"
  echo -e " ${cyan}(Your OctoEverywhere Printer ID and account link remain untouched.)${white}"
  echo
  echo -e "  ${yellow}1)${white} WARNING (Recommended - saves RAM & reduces eMMC writes)"
  echo -e "  ${yellow}2)${white} INFO    (Verbose logging - for troubleshooting / pairing link)"
  echo -e "  ${yellow}3)${white} ERROR   (Minimal logging - critical errors only)"
  echo -e "  ${yellow}b)${white} Cancel"
  echo

  local choice new_level new_size
  while true; do
    read -p " ${white}Select desired log level (${yellow}1${white}/${yellow}2${white}/${yellow}3${white}/${yellow}b${white}): ${yellow}" choice
    echo -e "${white}"
    case "${choice}" in
      1) new_level="WARNING"; new_size="1"; break ;;
      2) new_level="INFO"; new_size="3"; break ;;
      3) new_level="ERROR"; new_size="1"; break ;;
      B|b) error_msg "Log level change canceled!"; return ;;
      *) error_msg "Please select a correct choice! (1, 2, 3 or b)" ;;
    esac
  done

  if [ -f "$octo_conf" ]; then
    if grep -q '^log_level[[:space:]]*=' "$octo_conf"; then
      sed -i "s/^log_level[[:space:]]*=.*/log_level = ${new_level}/" "$octo_conf"
    else
      sed -i "/^\[logging\]/a log_level = ${new_level}" "$octo_conf"
    fi
    if grep -q '^max_file_size_mb[[:space:]]*=' "$octo_conf"; then
      sed -i "s/^max_file_size_mb[[:space:]]*=.*/max_file_size_mb = ${new_size}/" "$octo_conf"
    fi
  fi

  if [ -f "$init_script" ]; then
    echo -e "Info: Restarting OctoEverywhere service..."
    set +e
    "$init_script" restart >/dev/null 2>&1
    set -e
  fi

  ok_msg "OctoEverywhere log level set to ${yellow}${new_level}${green} (max ${new_size} MB)!"
}
