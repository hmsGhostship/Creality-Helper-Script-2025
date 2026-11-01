#!/bin/sh

set -e

function octoapp_companion_message(){
  top_line
  title 'OctoApp Companion' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}OctoApp Companion allows you to control your printer from      ${white}│"
  echo -e " │ ${cyan}OctoApp and get notifications for your prints.                 ${white}│"
  hr
  bottom_line
}

function install_octoapp_companion(){
  octoapp_companion_message
  local yn
  while true; do
    echo -e "${yellow} ┌────────────────────────────────────────────────────────┐"
    echo -e " │  NOTICE: This installation temporarily requires free   │"
    echo -e " │  system RAM. After a successful setup, the printer will│"
    echo -e " │  AUTOMATICALLY REBOOT (Your SSH session will close)!   │"
    echo -e " └────────────────────────────────────────────────────────┘${white}"
    echo
    
    install_msg "OctoApp Companion" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"

        # 1. Stop Klipper and Creality services (free up CPU & RAM for the K1C 2025)
        echo -e "Info: Stopping Klipper and Creality services to secure CPU & RAM..."
        if [ -f "/usr/apps/etc/init.d/CS55klipper_service" ]; then
            /usr/apps/etc/init.d/CS55klipper_service stop >/dev/null 2>&1 || true
        fi
        kill -9 $(ps -w | grep "klippy.py" | grep -v grep | awk '{print $1}') 2>/dev/null || true
        killall -9 go2rtc_linux_mipsel >/dev/null 2>&1 || true
        killall -9 alchemistp >/dev/null 2>&1 || true
        killall -9 vectorp >/dev/null 2>&1 || true
        sleep 5

        # 2. Creating directories
        mkdir -p "$PRINTER_DATA_FOLDER/config" "$PRINTER_DATA_FOLDER/logs" "$INITD_FOLDER"

        echo -e "Info: Downloading OctoApp Companion..."
        git config --global http.sslVerify false
        if [ ! -d "$OCTOAPP_COMPANION_FOLDER" ]; then
            git clone "$OCTOAPP_COMPANION_URL" "$OCTOAPP_COMPANION_FOLDER"
        else
            echo -e "Info: OctoApp Companion folder already exists. Download skipped."
        fi

        ## 3. Virtual Environment & PIP gentle cycle (K1C 2025 SYNTAX-FIX)
        echo -e "Info: Setting up Python Virtual Environment..."
        OCTOAPP_ENV_FOLDER="${MOONRAKER_FOLDER}/octoapp-env"
        
        if [ ! -d "$OCTOAPP_ENV_FOLDER" ]; then
            # Clean, linear if/else without blocking curly braces for the Creality shell
            if /usr/bin/python3 -m venv "$OCTOAPP_ENV_FOLDER" 2>/dev/null; then
                echo "Info: Built-in venv created successfully."
            else
                echo -e "Info: Built-in venv failed. Installing virtualenv via system python..."
                /usr/bin/python3 -m pip install --no-cache-dir virtualenv
                /usr/bin/python3 -m virtualenv "$OCTOAPP_ENV_FOLDER"
            fi

            echo -e "Info: Upgrading pip and build tools (RAM-safe mode)..."
            "$OCTOAPP_ENV_FOLDER/bin/pip" install --no-cache-dir --upgrade pip setuptools wheel

            # FOOLPROOF K1C FIX: We replicate the factory-installed "pillow" (cushioning/padding) that is known to be present.
            echo -e "Info: Linking factory-preinstalled Pillow binary into virtual environment..."
            if [ -d "/usr/lib/python3.8/site-packages/PIL" ]; then
                cp -r /usr/lib/python3.8/site-packages/PIL* "$OCTOAPP_ENV_FOLDER/lib/python3.8/site-packages/" 2>/dev/null || true
            fi
            
            # Install requirements without the blocking Pillow/pybind11
            TMP_REQ="/tmp/octoapp-requirements.txt"
            if [ -f "$OCTOAPP_COMPANION_FOLDER/requirements.txt" ]; then
                grep -v -E -i "pillow|pybind11" "$OCTOAPP_COMPANION_FOLDER/requirements.txt" > "$TMP_REQ"
                echo -e "Info: Installing remaining requirements via Schonwaschgang..."
                MAX_CONCURRENT_BUILDS=1 "$OCTOAPP_ENV_FOLDER/bin/pip" install --no-cache-dir --no-build-isolation -r "$TMP_REQ"
                rm -f "$TMP_REQ"
            fi
        fi

        # DYNAMIC PORT DETECTION FOR THE K1C (Interfacing with the actual Moonraker)
        local real_port=7126
        if [ -f "$MOONRAKER_CFG" ]; then
          local detected_port=$(grep -A 5 "\[server\]" "$MOONRAKER_CFG" | grep "port" | awk '{print $3}' | tr -d '\r')
          if [ ! -z "$detected_port" ]; then
             real_port=$detected_port
          fi
        fi

        # 4. Writing the verified octoapp.conf (with the dynamic port)
        echo -e "Info: Writing verified octoapp.conf structure on Port $real_port..."
        echo -e "[main]\napi_url: http://127.0.0.1:$real_port\nmoonraker_address: ws://127.0.0.1:$real_port/websocket\n\n[companion]\nip_or_hostname: 127.0.0.1\nport: $real_port" > "$PRINTER_DATA_FOLDER/config/octoapp.conf"

        # 5. Create a persistent startup script (with dynamic paths and the correct port bypass)
        echo -e "Info: Writing persistent startup script..."
        OCTOAPP_INIT_SCRIPT="${INITD_FOLDER}/S55octoapp"
        cat << EOF > "$OCTOAPP_INIT_SCRIPT"
#!/bin/sh

case "\$1" in
  start)
    echo "Starting OctoApp Companion..."
    cd $OCTOAPP_COMPANION_FOLDER
    PYTHONPATH=$OCTOAPP_COMPANION_FOLDER $OCTOAPP_ENV_FOLDER/bin/python3 -m moonraker_octoapp \$($OCTOAPP_ENV_FOLDER/bin/python3 -c 'import base64; print(base64.urlsafe_b64encode(b"{\"ServiceName\": \"octoapp\", \"VirtualEnvPath\": \"区域'$OCTOAPP_ENV_FOLDER'\", \"RepoRootFolder\": \"区域'$OCTOAPP_COMPANION_FOLDER'\", \"LocalFileStoragePath\": \"区域'$PRINTER_DATA_FOLDER'/config\", \"ConfigFolder\": \"区域'$PRINTER_DATA_FOLDER'/config\", \"LogFolder\": \"区域'$PRINTER_DATA_FOLDER'/logs\", \"IsCompanion\": false, \"MoonrakerConfigFile\": \"区域'$MOONRAKER_CFG'\"}").decode("utf-8").replace("区域",""))') > $PRINTER_DATA_FOLDER/logs/octoapp.log 2>&1 &
    ;;
  stop)
    echo "Stopping OctoApp Companion..."
    PIDS=\$(ps -w | grep "moonraker_octoapp" | grep -v grep | awk '{print \$1}')
    if [ -n "\$PIDS" ]; then
      kill -9 \$PIDS >/dev/null 2>&1 || true
    fi
    ;;
  restart)
    \$0 stop || true
    sleep 1
    \$0 start
    ;;
  *)
    echo "Usage: \$0 {start|stop|restart}"
    exit 1
esac
EOF
        chmod +x "$OCTOAPP_INIT_SCRIPT"

        # K1C-COMPATIBILITY: We are removing old, obstructive 'update_manager' remnants from the config
        if [ -f "$MOONRAKER_CFG" ]; then
            sed -i '/\[update_manager octoapp\]/,+8d' "$MOONRAKER_CFG"
        fi

        ok_msg "OctoApp Companion has been installed successfully!"
        
        # 7. Automatic System Reboot
        for i in 5 4 3 2 1; do
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

function remove_octoapp_companion(){
  octoapp_companion_message
  local yn
  while true; do
    remove_msg "OctoApp Companion" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        
        # A) Stop the service and delete the init script
        echo -e "Info: Stopping OctoApp Companion service..."
        if [ -f "${INITD_FOLDER}/S55octoapp" ]; then
            "${INITD_FOLDER}/S55octoapp" stop >/dev/null 2>&1 || true
            rm -f "${INITD_FOLDER}/S55octoapp"
        fi
        
        # B) Completely remove folders and virtual environment (Secure K1C hard-wipe)
        echo -e "Info: Removing directory structures and virtual environment..."
        rm -rf "$OCTOAPP_COMPANION_FOLDER"
        rm -rf "${MOONRAKER_FOLDER}/octoapp-env"
        rm -f "$PRINTER_DATA_FOLDER/config/octoapp.conf"
        
        # C) Remove the Update Manager from moonraker.conf, leaving no traces behind
        echo -e "Info: Cleaning up moonraker.conf..."
        if [ -f "$MOONRAKER_CFG" ]; then
            sed -i '/\[update_manager octoapp\]/,+8d' "$MOONRAKER_CFG"
        fi
        
        ok_msg "OctoApp Companion has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}
