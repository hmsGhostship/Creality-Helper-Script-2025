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
    # CLEAR HINT FOR THE USER BEFORE CONFIRMATION
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

        # 1. HARD RAM-CLEANING (Genau wie manuell im Terminal)
        echo -e "Info: Freeing up physical RAM (Killing heavy Creality services)..."
        killall -9 go2rtc_linux_mipsel >/dev/null 2>&1 || true
        killall -9 alchemistp >/dev/null 2>&1 || true
        killall -9 vectorp >/dev/null 2>&1 || true
        
        # 2. DIE ATEMPAUSE: Wartet starr, bis Linux den Speicher wirklich freigibt
        echo -e "Info: Waiting for Linux to flush RAM structures..."
        sleep 5

        echo -e "Info: Preparing directory structure on persistent storage..."
        mkdir -p "$PRINTER_DATA_FOLDER/config" "$PRINTER_DATA_FOLDER/logs" "/opt/etc/init.d"

        echo -e "Info: Downloading Mobileraker Companion..."
        git config --global http.sslVerify false
        if [ ! -d "$MOBILERAKER_COMPANION_FOLDER" ]; then
            git clone "$MOBILERAKER_COMPANION_URL" "$MOBILERAKER_COMPANION_FOLDER"
        else
            echo -e "Info: Repository already exists at $MOBILERAKER_COMPANION_FOLDER."
        fi

        echo -e "Info: Setting up Python Virtual Environment..."
        if [ ! -d "$MOBILERAKER_ENV_FOLDER" ]; then
            python3 -m venv "$MOBILERAKER_ENV_FOLDER" 2>/dev/null || {
                echo -e "Info: Built-in venv not found. Installing virtualenv..."
                python3 -m pip install --no-cache-dir virtualenv
                python3 -m virtualenv "$MOBILERAKER_ENV_FOLDER"
            }

            echo -e "Info: Upgrading pip and build tools (RAM-safe mode)..."
            "$MOBILERAKER_ENV_FOLDER/bin/pip" install --no-cache-dir --upgrade pip setuptools wheel

            if [ -d "/opt/lib" ]; then
                echo -e "Info: Applying pre-compiled Pillow from Entware..."
                cp -r /opt/lib/python3.*/site-packages/PIL* "$MOBILERAKER_ENV_FOLDER"/lib/python3.*/site-packages/ 2>/dev/null || true
                cp -r /opt/lib/python3.*/site-packages/[pP]illow* "$MOBILERAKER_ENV_FOLDER"/lib/python3.*/site-packages/ 2>/dev/null || true
            fi
            
            TMP_REQ="/tmp/mobileraker-requirements.txt"
            if [ -f "$MOBILERAKER_COMPANION_FOLDER/scripts/mobileraker-requirements.txt" ]; then
                grep -v -E -i "pillow|pybind11" "$MOBILERAKER_COMPANION_FOLDER/scripts/mobileraker-requirements.txt" > "$TMP_REQ"
                echo -e "Info: Installing requirements via Schonwaschgang..."
                # --no-build-isolation spart massiv RAM, MAX_CONCURRENT_BUILDS zwingt auf 1 Kern
                MAX_CONCURRENT_BUILDS=1 "$MOBILERAKER_ENV_FOLDER/bin/pip" install --no-cache-dir --no-build-isolation -r "$TMP_REQ"
                rm -f "$TMP_REQ"
            elif [ -f "$MOBILERAKER_COMPANION_FOLDER/requirements.txt" ]; then
                grep -v -E -i "pillow|pybind11" "$MOBILERAKER_COMPANION_FOLDER/requirements.txt" > "$TMP_REQ"
                echo -e "Info: Installing requirements via Schonwaschgang..."
                MAX_CONCURRENT_BUILDS=1 "$MOBILERAKER_ENV_FOLDER/bin/pip" install --no-cache-dir --no-build-isolation -r "$TMP_REQ"
                rm -f "$TMP_REQ"
            fi
        else
            echo -e "Info: Virtual Environment already exists."
        fi

        echo -e "Info: Creating mobileraker.conf configuration..."
        if [ ! -f "$PRINTER_DATA_FOLDER/config/mobileraker.conf" ]; then
            cat << 'EOF' > "$PRINTER_DATA_FOLDER/config/mobileraker.conf"
[main]
config_version = 1

[printer default]
moonraker_uri = ws://127.0.0.1:7125/websocket
moonraker_api_key = False
EOF
        fi

        echo -e "Info: Writing persistent Entware startup script..."
        cat << 'EOF' > "$MOBILERAKER_INIT_SCRIPT"
#!/bin/sh

case "$1" in
  start)
    echo "Starting Mobileraker Companion..."
    /usr/data/mobileraker-env/bin/python /usr/data/mobileraker_companion/mobileraker.py -c /usr/data/printer_data/config/mobileraker.conf > /usr/data/printer_data/logs/mobileraker.log 2>&1 &
    ;;
  stop)
    echo "Stopping Mobileraker Companion..."
    PIDS=$(ps -w | grep "[m]obileraker.py" | awk '{print $1}')
    if [ -n "$PIDS" ]; then
      kill -9 $PIDS >/dev/null 2>&1 || true
    fi
    ;;
  restart)
    $0 stop || true
    sleep 1
    $0 start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac
EOF
        chmod +x "$MOBILERAKER_INIT_SCRIPT"

        echo -e "Info: Injecting Update Manager block into moonraker.conf..."
        if [ -f "$MOONRAKER_CFG" ]; then
            if ! grep -q "\[update_manager mobileraker\]" "$MOONRAKER_CFG"; then
                cat << EOF >> "$MOONRAKER_CFG"

[update_manager mobileraker]
type: git_repo
path: $MOBILERAKER_COMPANION_FOLDER
origin: $MOBILERAKER_COMPANION_URL
virtualenv: $MOBILERAKER_ENV_FOLDER
primary_branch: main
requirements: scripts/mobileraker-requirements.txt
install_script: scripts/install.sh
EOF
            fi
        fi

        echo -e "Info: Starting Mobileraker daemon..."
        "$MOBILERAKER_INIT_SCRIPT" restart || true
        sleep 2

        if ps -w | grep -v grep | grep -q "mobileraker"; then
            ok_msg "Mobileraker Companion has been installed successfully!"
        else
            error_msg "Service registered, but process failed to run. Check $PRINTER_DATA_FOLDER/logs/mobileraker.log"
        fi
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

        echo -e "Info: Purging directory trees and virtual environment..."
        rm -rf "$MOBILERAKER_COMPANION_FOLDER"
        rm -rf "$MOBILERAKER_ENV_FOLDER"
        rm -f "$PRINTER_DATA_FOLDER/config/mobileraker.conf"
        rm -f "$PRINTER_DATA_FOLDER/logs/mobileraker.log"

        echo -e "Info: Stripping Update Manager block from moonraker.conf..."
        if [ -f "$MOONRAKER_CFG" ]; then
            sed -i '/\[update_manager mobileraker\]/,+8d' "$MOONRAKER_CFG"
        fi

        echo -e "Info: Restarting system services..."
        stop_moonraker
        start_moonraker
        restart_klipper
        
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
