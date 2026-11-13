#!/bin/sh

set -e

function mobileraker_companion_message(){
  top_line
  title 'Mobileraker Companion' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Mobileraker Companion allows to push notification for          ${white}│"
  echo -e " │ ${cyan}Klipper using Moonraker for Mobileraker phone App.             ${white}│"
  hr
  bottom_line
}

function install_mobileraker_companion(){
  mobileraker_companion_message
  local yn
  while true; do
    echo -e "${yellow} ┌────────────────────────────────────────────────────────┐"
    echo -e " │  NOTICE: This installation temporarily requires free   │"
    echo -e " │  system RAM. After a successful setup, the printer will│"
    echo -e " │  AUTOMATICALLY REBOOT (Your SSH session will close)!   │"
    echo -e " └────────────────────────────────────────────────────────┘${white}"
    echo
    
    install_msg "Mobileraker Companion" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        check_ram_requirement "Mobileraker Companion" 22 || return

        # 1. Dynamische Moonraker-Python-Umgebung ermitteln (wie bei Obico & OctoEverywhere)
        echo -e "Info: Detecting Moonraker Python Environment..."
        local active_python=$(ps w | grep moonraker | grep -v grep | awk '{print $5}')
        if [ -z "$active_python" ] || [ ! -f "$active_python" ]; then
          active_python="$MOONRAKER_ENV_PYTHON"
        fi
        if [ ! -f "$active_python" ]; then
          error_msg "Fehler: Keine gültige Moonraker Python-Umgebung gefunden!"
          return 1
        fi
        echo -e "Info: Nutze Python-Umgebung: $active_python"

        # 2. RAM freimachen & schwergewichtige Dienste temporär stoppen
        echo -e "Info: Freeing up physical RAM..."
        killall -9 go2rtc_linux_mipsel >/dev/null 2>&1 || true
        killall -9 alchemistp >/dev/null 2>&1 || true
        killall -9 vectorp >/dev/null 2>&1 || true
        rm -rf "$MOBILERAKER_ENV_FOLDER"
        sleep 3

        echo -e "Info: Preparing directory structure on persistent storage..."
        mkdir -p "$PRINTER_DATA_FOLDER/config" "$PRINTER_DATA_FOLDER/logs"

        echo -e "Info: Downloading Mobileraker Companion..."
        git config --global http.sslVerify false
        if [ -d "$MOBILERAKER_COMPANION_FOLDER" ]; then
          rm -rf "$MOBILERAKER_COMPANION_FOLDER"
        fi
        git clone --depth 1 "$MOBILERAKER_COMPANION_URL" "$MOBILERAKER_COMPANION_FOLDER"

        # 3. Abhängigkeiten RAM-schonend in die Moonraker-Python-Umgebung installieren
        echo -e "Info: Installing Mobileraker dependencies..."
        local TMP_REQ="/tmp/mobileraker-requirements.txt"
        if [ -f "$MOBILERAKER_COMPANION_FOLDER/scripts/mobileraker-requirements.txt" ]; then
          grep -v -E -i "pillow|pybind11" "$MOBILERAKER_COMPANION_FOLDER/scripts/mobileraker-requirements.txt" > "$TMP_REQ"
          "$active_python" -m pip install --no-cache-dir -r "$TMP_REQ"
          rm -f "$TMP_REQ"
        elif [ -f "$MOBILERAKER_COMPANION_FOLDER/requirements.txt" ]; then
          grep -v -E -i "pillow|pybind11" "$MOBILERAKER_COMPANION_FOLDER/requirements.txt" > "$TMP_REQ"
          "$active_python" -m pip install --no-cache-dir -r "$TMP_REQ"
          rm -f "$TMP_REQ"
        fi

        # 4. Moonraker-Port ermitteln & mobileraker.conf anlegen
        local real_port=7126
        if [ -f "$MOONRAKER_CFG" ]; then
          local detected_port=$(grep -A 5 "\[server\]" "$MOONRAKER_CFG" | grep "port" | awk '{print $3}' | tr -d '\r')
          if [ -n "$detected_port" ]; then
            real_port=$detected_port
          fi
        fi

        echo -e "Info: Creating mobileraker.conf configuration on Port $real_port..."
        cat << EOF > "$PRINTER_DATA_FOLDER/config/mobileraker.conf"
[main]
config_version = 1

[printer default]
moonraker_uri = ws://127.0.0.1:$real_port/websocket
moonraker_api_key = False
EOF

        # 5. Persistentes Startskript mit Boot-Verzögerung und $active_python schreiben
        echo -e "Info: Writing persistent startup script..."
        cat << EOF > "$MOBILERAKER_INIT_SCRIPT"
#!/bin/sh

case "\$1" in
  start)
    echo "Starting Mobileraker Companion..."
    (
      if [ "\$2" != "now" ]; then
        sleep 20
      fi
      cd $MOBILERAKER_COMPANION_FOLDER || exit 1
      $active_python $MOBILERAKER_COMPANION_FOLDER/mobileraker.py -c $PRINTER_DATA_FOLDER/config/mobileraker.conf > $PRINTER_DATA_FOLDER/logs/mobileraker.log 2>&1
    ) &
    ;;
  stop)
    echo "Stopping Mobileraker Companion..."
    PIDS=\$(ps -w | grep "[m]obileraker.py" | awk '{print \$1}')
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
        chmod +x "$MOBILERAKER_INIT_SCRIPT"

        if [ -f "$MOONRAKER_CFG" ]; then
          sed -i '/\[update_manager mobileraker\]/,+8d' "$MOONRAKER_CFG" 2>/dev/null || true
        fi

        ok_msg "Mobileraker Companion has been installed successfully!"
        for i in 10 9 8 7 6 5 4 3 2 1; do
          echo -e "    Drucker startet neu in $i Sekunden... \r\c"
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

function remove_mobileraker_companion(){
  mobileraker_companion_message
  local yn
  while true; do
    remove_msg "Mobileraker Companion" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Stopping and tearing down daemon service..."
        if [ -f "$MOBILERAKER_INIT_SCRIPT" ]; then
          "$MOBILERAKER_INIT_SCRIPT" stop || true
          rm -f "$MOBILERAKER_INIT_SCRIPT"
        fi

        PIDS=$(ps -w | grep "[m]obileraker.py" | awk '{print $1}')
        if [ -n "$PIDS" ]; then
          kill -9 $PIDS >/dev/null 2>&1 || true
        fi

        echo -e "Info: Purging directory trees..."
        rm -rf "$MOBILERAKER_COMPANION_FOLDER"
        rm -rf "$MOBILERAKER_ENV_FOLDER"
        rm -f "$PRINTER_DATA_FOLDER/config/mobileraker.conf"
        rm -f "$PRINTER_DATA_FOLDER/logs/mobileraker.log"

        if [ -f "$MOONRAKER_CFG" ]; then
          sed -i '/\[update_manager mobileraker\]/,+8d' "$MOONRAKER_CFG" 2>/dev/null || true
        fi

        ok_msg "Mobileraker Companion has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}