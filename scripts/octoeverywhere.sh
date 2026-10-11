#!/bin/sh

set -e

function octoeverywhere_message(){
  top_line
  title 'OctoEverywhere' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Secure, private, and unlimited remote access to your full    ${white}│"
  echo -e " │ ${cyan}web control portal from anywhere with AI print failure      ${white}│"
  echo -e " │ ${cyan}detection.                                                   ${white}│"
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
        
        # 1. RAM Sichern & Klipper stoppen (Essentiell auf dem K1C 2025)
        echo -e "Info: Stopping Klipper and Creality services to secure CPU & RAM..."
        if [ -f "/usr/apps/etc/init.d/CS55klipper_service" ]; then
            /usr/apps/etc/init.d/CS55klipper_service stop >/dev/null 2>&1 || true
        fi
        kill -9 $(ps -w | grep "klippy.py" | grep -v grep | awk '{print $1}') 2>/dev/null || true
        killall -9 go2rtc_linux_mipsel >/dev/null 2>&1 || true
        killall -9 alchemistp >/dev/null 2>&1 || true
        sleep 5

        # 2. Verzeichnisse anlegen & Klonen
        echo -e "Info: Updating OctoEverywhere Repository..."
        if [ -d "$OCTOEVERYWHERE_FOLDER" ]; then
          rm -rf "$OCTOEVERYWHERE_FOLDER"
        fi
        git config --global http.sslVerify false
        # Wir nutzen deine System-Variable zum Klonen
        git clone --depth 1 "$OCTOEVERYWHERE_URL" "$OCTOEVERYWHERE_FOLDER"
        
        # 3. Isolierte Python-Umgebung im Schonwaschgang aufbauen
        echo -e "Info: Setting up Python Virtual Environment..."
        OCTO_ENV="/usr/data/octoeverywhere-env"
        if [ ! -d "$OCTO_ENV" ]; then
            python3 -m venv "$OCTO_ENV" 2>/dev/null || {
                python3 -m pip install --no-cache-dir virtualenv
                python3 -m virtualenv "$OCTO_ENV"
            }
            
            # Anforderungen im RAM-Schonwaschgang installieren
            TMP_REQ="/tmp/octo-req.txt"
            if [ -f "$OCTOEVERYWHERE_FOLDER/requirements.txt" ]; then
                # Wir filtern ballaststoffreiche Compiler-Pakete heraus
                grep -v -E -i "pillow|pybind11" "$OCTOEVERYWHERE_FOLDER/requirements.txt" > "$TMP_REQ"
                "$OCTO_ENV/bin/pip" install --no-cache-dir -r "$TMP_REQ"
                rm -f "$TMP_REQ"
            fi
        fi
        
        # 4. Den sauberen [octoeverywhere] Block in die moonraker.conf schreiben
        echo -e "Info: Configuring moonraker.conf..."
        if [ -f "$MOONRAKER_CFG" ]; then
          sed -i '/\[octoeverywhere\]/,+2d' "$MOONRAKER_CFG" || true
          echo -e "\n[octoeverywhere]" >> "$MOONRAKER_CFG"
        fi
        
        # 5. Das echte, 2025er-kompatible Init-Startskript schreiben (Mit dem korrekten Modulaufruf)
        echo -e "Info: Writing persistent startup script..."
        OCTO_INIT_SCRIPT="${INITD_FOLDER}/S99octoeverywhere"
        cat << EOF > "$OCTO_INIT_SCRIPT"
#!/bin/sh

case "\$1" in
  start)
    echo "Starting OctoEverywhere Daemon..."
    cd $OCTOEVERYWHERE_FOLDER
    # DER ECHTE, MODERNE PYTHONAURUF ALS MODUL AUF PORT 7126
    PYTHONPATH=$OCTOEVERYWHERE_FOLDER $OCTO_ENV/bin/python3 -m octoeverywhere --port 7126 --config $PRINTER_DATA_FOLDER/config/ > $PRINTER_DATA_FOLDER/logs/octoeverywhere.log 2>&1 &
    ;;
  stop)
    echo "Stopping OctoEverywhere..."
    PIDS=\$(ps -w | grep "octoeverywhere" | grep -v grep | awk '{print \$1}')
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
        chmod +x "$OCTO_INIT_SCRIPT"
        
        ok_msg "OctoEverywhere has been integrated successfully!"
        
        # 6. Automatischer System-Reboot zur RAM-Leerung
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

function remove_octoeverywhere(){
  octoeverywhere_message
  local yn
  while true; do
    remove_msg "OctoEverywhere" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Removing OctoEverywhere components..."
        if [ -f "${INITD_FOLDER}/S99octoeverywhere" ]; then
            "${INITD_FOLDER}/S99octoeverywhere" stop >/dev/null 2>&1 || true
            rm -f "${INITD_FOLDER}/S99octoeverywhere"
        fi
        
        rm -rf "$OCTOEVERYWHERE_FOLDER"
        rm -rf "/usr/data/octoeverywhere-env"
        
        if [ -f "$MOONRAKER_CFG" ]; then
          sed -i '/\[octoeverywhere\]/d' "$MOONRAKER_CFG" || true
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