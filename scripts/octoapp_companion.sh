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

        # 1. Klipper und Creality-Dienste stoppen (CPU & RAM sichern für den K1C 2025)
        echo -e "Info: Stopping Klipper and Creality services to secure CPU & RAM..."
        if [ -f "/usr/apps/etc/init.d/CS55klipper_service" ]; then
            /usr/apps/etc/init.d/CS55klipper_service stop >/dev/null 2>&1 || true
        fi
        kill -9 $(ps -w | grep "klippy.py" | grep -v grep | awk '{print $1}') 2>/dev/null || true
        killall -9 go2rtc_linux_mipsel >/dev/null 2>&1 || true
        killall -9 alchemistp >/dev/null 2>&1 || true
        killall -9 vectorp >/dev/null 2>&1 || true
        sleep 5

        # 2. Verzeichnisse anlegen (Nutzt deine globalen Pfade)
        mkdir -p "$PRINTER_DATA_FOLDER/config" "$PRINTER_DATA_FOLDER/logs" "$INITD_FOLDER"

        echo -e "Info: Downloading OctoApp Companion..."
        git config --global http.sslVerify false
        if [ ! -d "$OCTOAPP_COMPANION_FOLDER" ]; then
            git clone "$OCTOAPP_COMPANION_URL" "$OCTOAPP_COMPANION_FOLDER"
        else
            echo -e "Info: OctoApp Companion folder already exists. Download skipped."
        fi

        # 3. Virtual Environment & PIP Schonwaschgang
        echo -e "Info: Setting up Python Virtual Environment..."
        OCTOAPP_ENV_FOLDER="${MOONRAKER_FOLDER}/octoapp-env"
        
        if [ ! -d "$OCTOAPP_ENV_FOLDER" ]; then
            python3 -m venv "$OCTOAPP_ENV_FOLDER" 2>/dev/null || {
                python3 -m pip install --no-cache-dir virtualenv
                python3 -m virtualenv "$OCTOAPP_ENV_FOLDER"
            }

            # Vorkompiliertes Pillow aus Entware injizieren (Verhindert den hängenden Compiler-Crash)
            if [ -d "/opt/lib" ]; then
                cp -r /opt/lib/python3.*/site-packages/PIL* "$OCTOAPP_ENV_FOLDER"/lib/python3.*/site-packages/ 2>/dev/null || true
                cp -r /opt/lib/python3.*/site-packages/[pP]illow* "$OCTOAPP_ENV_FOLDER"/lib/python3.*/site-packages/ 2>/dev/null || true
            fi
            
            # Anforderungen ohne das blockierende Pillow installieren
            TMP_REQ="/tmp/octoapp-requirements.txt"
            if [ -f "$OCTOAPP_COMPANION_FOLDER/requirements.txt" ]; then
                grep -v -E -i "pillow|pybind11" "$OCTOAPP_COMPANION_FOLDER/requirements.txt" > "$TMP_REQ"
                MAX_CONCURRENT_BUILDS=1 "$OCTOAPP_ENV_FOLDER/bin/pip" install --no-cache-dir --no-build-isolation -r "$TMP_REQ"
                rm -f "$TMP_REQ"
            fi
        fi

        # 4. Die verifizierte octoapp.conf schreiben (Nativer Klipper-Modus auf Port 7125)
        echo -e "Info: Writing verified octoapp.conf structure..."
        echo -e "[main]\napi_url: http://127.0.0.1:7125\nmoonraker_address: ws://127.0.0.1:7125/websocket\n\n[companion]\nip_or_hostname: 127.0.0.1\nport: 7125" > "$PRINTER_DATA_FOLDER/config/octoapp.conf"

        # 5. Persistentes Startskript erzeugen (Mit der verifizierten, fehlerfreien Base64-Inline-Logik)
        echo -e "Info: Writing persistent startup script..."
        OCTOAPP_INIT_SCRIPT="${INITD_FOLDER}/S55octoapp"
        cat << EOF > "$OCTOAPP_INIT_SCRIPT"
#!/bin/sh

case "\$1" in
  start)
    echo "Starting OctoApp Companion..."
    cd $OCTOAPP_COMPANION_FOLDER
    # Der verifizierte Startbefehl (Reiner Klipper-Modus statt Bambu-Modus)
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

        # 6. Update-Manager in moonraker.conf eintragen
        if [ -f "$MOONRAKER_CFG" ] && ! grep -q "\[update_manager octoapp\]" "$MOONRAKER_CFG"; then
            cat << EOF >> "$MOONRAKER_CFG"

[update_manager octoapp]
type: git_repo
path: $OCTOAPP_COMPANION_FOLDER
origin: $OCTOAPP_COMPANION_URL
virtualenv: $OCTOAPP_ENV_FOLDER
primary_branch: main
requirements: requirements.txt
install_script: install.sh
EOF
        fi

        ok_msg "OctoApp Companion has been installed successfully!"
        
        # 7. Automatischer System-Reboot (Flusht den RAM und bootet den neuen Service)
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

function remove_octoapp_companion(){
  octoapp_companion_message
  local yn
  while true; do
    remove_msg "OctoApp Companion" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        
        # A) Dienst beenden und das Init-Skript loeschen
        echo -e "Info: Stopping OctoApp Companion service..."
        if [ -f "${INITD_FOLDER}/S55octoapp" ]; then
            "${INITD_FOLDER}/S55octoapp" stop >/dev/null 2>&1 || true
            rm -f "${INITD_FOLDER}/S55octoapp"
        fi
        
        # B) Ordner und virtuelle Umgebung restlos entfernen (Sicherer K1C Hard-Wipe)
        echo -e "Info: Removing directory structures and virtual environment..."
        rm -rf "$OCTOAPP_COMPANION_FOLDER"
        rm -rf "${MOONRAKER_FOLDER}/octoapp-env"
        rm -f "$PRINTER_DATA_FOLDER/config/octoapp.conf"
        
        # C) Update-Manager rückstandslos aus moonraker.conf schneiden
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