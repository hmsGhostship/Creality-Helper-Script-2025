#!/bin/sh

set -e

function moonraker_obico_message(){
  top_line
  title 'Moonraker Obico' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Obico is a Moonraker plugin that allows you to monitor and     ${white}│"
  echo -e " │ ${cyan}control your 3D printer from anywhere.                         ${white}│"
  hr
  bottom_line
}

function install_moonraker_obico(){
  moonraker_obico_message
  local yn
  while true; do
    install_msg "Moonraker Obico" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        
        # 1. DYNAMIC PATH DETERMINATION
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

        # 2. DOWNLOAD
        if [ -d "$MOONRAKER_OBICO_FOLDER" ]; then
          echo -e "Info: Moonraker Obico folder found."
        else
          echo -e "Info: Downloading Moonraker Obico..."
          git config --global http.sslVerify false
          git clone --depth 1 "$MOONRAKER_OBICO_URL" "$MOONRAKER_OBICO_FOLDER"
        fi

        # 3. PYTHON INSTALLATION (ONLY DEPENDENCIES REMAINING)
        cd "$MOONRAKER_OBICO_FOLDER"
        echo -e "Info: Installing Obico dependencies..."
        $active_python -m pip install --no-cache-dir -r requirements.txt

        # 4. CONFIG CREATION, PORT ADJUSTMENT & K1C LOG FIX
        local obico_cfg="$KLIPPER_CONFIG_FOLDER/moonraker-obico.cfg"
        echo -e "Info: Creating moonraker-obico.cfg..."
        
        if [ -f "./moonraker-obico.cfg.sample" ]; then
          cp ./moonraker-obico.cfg.sample "$obico_cfg"
        else
          error_msg "Fehler: moonraker-obico.cfg.sample nicht im Repository gefunden!"
          return 1
        fi
        
        local real_port=7126
        if [ -f "$MOONRAKER_CFG" ]; then
          local detected_port=$(grep -A 5 "\[server\]" "$MOONRAKER_CFG" | grep "port" | awk '{print $3}' | tr -d '\r')
          if [ ! -z "$detected_port" ]; then
             real_port=$detected_port
          fi
        fi
        
        sed -i "s/host =.*/host = 127.0.0.1/g" "$obico_cfg"
        sed -i "s/port =.*/port = $real_port/g" "$obico_cfg"
        
        # K1C-LOG-FIX: Corrects the "path =" variable in the config to point to the K1C log directory
        sed -i "s|path = /home/pi/.*|path = /usr/data/printer_data/logs/moonraker-obico.log|g" "$obico_cfg"

        # 5. INTEGRATE INTO MOONRAKER.CONF (Safe cleanup bypass)
        # Instead of adding a faulty include, we ensure that any legacy 
        # crash entries are removed from moonraker.conf, allowing Moonraker to boot.
        if [ -f "$MOONRAKER_CFG" ]; then
          sed -i '/\[include moonraker-obico-update\.cfg\]/d' "$MOONRAKER_CFG"
        fi

        # 6. SET UP AUTOSTART (Using the correct module name .app)
        echo -e "Info: Creating init service in $INITD_FOLDER..."
        cat << EOF > "$INITD_FOLDER/S99moonraker_obico"
#!/bin/sh
case "\$1" in
  start)
    echo "Starting Moonraker Obico..."
    sleep 2
    export PYTHONPATH="$MOONRAKER_OBICO_FOLDER"
    $active_python -m moonraker_obico.app -c $obico_cfg > /dev/null 2>&1 &
    ;;
  stop)
    echo "Stopping Moonraker Obico..."
    kill \$(pgrep -f "moonraker_obico.app") > /dev/null 2>&1
    ;;
  *)
    echo "Usage: \$0 {start|stop}"
    exit 1
esac
exit 0
EOF
        chmod +x "$INITD_FOLDER/S99moonraker_obico"

        ok_msg "Moonraker Obico has been installed successfully!"
        
        # 7. AUTOMATIC PAIRING PROCESS & FULLY AUTOMATIC SYSTEM STARTUP
        echo -e "${yellow}--------------------------------------------------------"
        echo -e "Starte automatischen Kopplungsprozess..."
        echo -e "Bitte gib gleich den angezeigten Code in der Obico-App ein."
        echo -e "Hinweis: Der Code ist ca. 3-5 Minuten gültig."
        echo -e "--------------------------------------------------------${white}"
        sleep 2
        
        # The OR (|| echo...) prevents "set -e" from abruptly terminating the script in the event of a timeout!
        if ! PYTHONPATH="$MOONRAKER_OBICO_FOLDER" $active_python -m moonraker_obico.link -c "$obico_cfg"; then
          echo -e "\n${yellow}Hinweis: Der Kopplungsprozess wurde unterbrochen oder das Zeitfenster ist abgelaufen."
          echo -e "Du kannst die Kopplung später jederzeit manuell im Terminal nachholen mit:"
          echo -e "PYTHONPATH=\"$MOONRAKER_OBICO_FOLDER\" $active_python -m moonraker_obico.link -c $obico_cfg${white}\n"
        fi
        
        # THE SERVICES ARE STARTED NONETHELESS (So that the system is ready in the background):
        echo -e "Info: Konfiguriere Systemstarts für den Live-Betrieb..."
        
        # 1. Start the newly created Obico background service directly
        if [ -f "$INITD_FOLDER/S99moonraker_obico" ]; then
          "$INITD_FOLDER/S99moonraker_obico" start > /dev/null 2>&1 || true
        fi
        
        # 2. Perform a clean restart of Moonraker so that the plugin is loaded
        if command -v stop_moonraker >/dev/null 2>&1 && command -v start_moonraker >/dev/null 2>&1; then
          stop_moonraker && sleep 1 && start_moonraker
        elif [ -f "$INITD_FOLDER/S56moonraker_service" ]; then
          "$INITD_FOLDER/S56moonraker_service" restart > /dev/null 2>&1 || true
        fi

        ok_msg "Installation abgeschlossen! Der Drucker sollte jetzt in der App online gehen."
        return;;

      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_moonraker_obico(){
  moonraker_obico_message
  local yn
  while true; do
    remove_msg "Moonraker Obico" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        
        # 1. First, cleanly stop the Obico service, if it is running
        if [ -f "$INITD_FOLDER"/S99moonraker_obico ]; then
          echo -e "Info: Stopping Moonraker Obico service..."
          "$INITD_FOLDER"/S99moonraker_obico stop > /dev/null 2>&1 || true
          rm -f "$INITD_FOLDER"/S99moonraker_obico
          # Sicherheits-Kill falls das Init-Skript hakt
          kill $(pgrep -f "moonraker_obico.app") > /dev/null 2>&1 || true
        fi

        # 2. Remove configurations from moonraker.conf
        if grep -q "\[include moonraker-obico-update.cfg\]" "$MOONRAKER_CFG" ; then
          echo -e "Info: Removing Moonraker Obico configurations in moonraker.conf file..."
          sed -i '/\[include moonraker-obico-update\.cfg\]/d' "$MOONRAKER_CFG"
        else
          echo -e "Info: Moonraker Obico configurations are already removed in moonraker.conf file..."
        fi

        # 3. Remove remnants from printer.cfg (if present)
        if [ -f "$PRINTER_CFG" ] && grep -q "include moonraker_obico_macros" "$PRINTER_CFG" ; then
          echo -e "Info: Removing Moonraker Obico configurations in printer.cfg file..."
          sed -i '/include moonraker_obico_macros\.cfg/d' "$PRINTER_CFG"
        fi

        # 4. Deleting files completely and cleanly
        echo -e "Info: Removing files..."
        rm -rf "$MOONRAKER_OBICO_FOLDER"
        rm -rf /usr/data/moonraker-obico-env
        rm -f "$KLIPPER_CONFIG_FOLDER"/moonraker-obico-update.cfg 
        rm -f "$KLIPPER_CONFIG_FOLDER"/moonraker-obico.cfg
        rm -f "$KLIPPER_CONFIG_FOLDER"/config/moonraker-obico.cfg

        # 5. Cleanly restart services
        echo -e "Info: Restarting Moonraker service..."
        if command -v stop_moonraker >/dev/null 2>&1 && command -v start_moonraker >/dev/null 2>&1; then
          stop_moonraker
          sleep 1
          start_moonraker
        else
          if [ -f "$INITD_FOLDER"/S56moonraker_service ]; then
            "$INITD_FOLDER"/S56moonraker_service restart > /dev/null 2>&1 || true
          fi
        fi

        ok_msg "Moonraker Obico has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}