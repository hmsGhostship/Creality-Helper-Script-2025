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
        
        # 1. DYNAMISCHE PFADERMITTLUNG
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

        # 3. PYTHON-INSTALLATION (NUR NOCH ABHÄNGIGKEITEN)
        cd "$MOONRAKER_OBICO_FOLDER"
        echo -e "Info: Installing Obico dependencies..."
        $active_python -m pip install --no-cache-dir -r requirements.txt

        # 4. CONFIG-ERSTELLUNG, PORT-ANPASSUNG & K1C-LOG-FIX
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
        
        # K1C-LOG-FIX: Korrigiert die Variable "path =" in der Config auf das K1C-Log-Verzeichnis
        sed -i "s|path = /home/pi/.*|path = /usr/data/printer_data/logs/moonraker-obico.log|g" "$obico_cfg"

        # 5. IN MOONRAKER.CONF EINBINDEN (Sicherer Bereinigungs-Bypass)
        # Wir fügen KEIN fehlerhaftes Include mehr hinzu, sondern stellen sicher, dass alte 
        # Absturz-Einträge aus der moonraker.conf getilgt werden, damit Moonraker booten kann.
        if [ -f "$MOONRAKER_CFG" ]; then
          sed -i '/\[include moonraker-obico-update\.cfg\]/d' "$MOONRAKER_CFG"
        fi

        # 6. AUTOSTART ANLEGEN (Mit korrektem Module-Namen .app)
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
        
        # 7. AUTOMATISCHER KOPPLUNGSPROZESS & VOLLAUTOMATISCHER SYSTEMSTART
        echo -e "${yellow}--------------------------------------------------------"
        echo -e "Starte automatischen Kopplungsprozess..."
        echo -e "Bitte gib gleich den angezeigten Code in der Obico-App ein."
        echo -e "Hinweis: Der Code ist ca. 3-5 Minuten gültig."
        echo -e "--------------------------------------------------------${white}"
        sleep 2
        
        # Das OR (|| echo...) verhindert, dass "set -e" das Skript bei einem Timeout hart abbricht!
        if ! PYTHONPATH="$MOONRAKER_OBICO_FOLDER" $active_python -m moonraker_obico.link -c "$obico_cfg"; then
          echo -e "\n${yellow}Hinweis: Der Kopplungsprozess wurde unterbrochen oder das Zeitfenster ist abgelaufen."
          echo -e "Du kannst die Kopplung später jederzeit manuell im Terminal nachholen mit:"
          echo -e "PYTHONPATH=\"$MOONRAKER_OBICO_FOLDER\" $active_python -m moonraker_obico.link -c $obico_cfg${white}\n"
        fi
        
        # DIE DIENSTE WERDEN TROTZDEM GESTARTET (Damit das System im Hintergrund bereit ist):
        echo -e "Info: Konfiguriere Systemstarts für den Live-Betrieb..."
        
        # 1. Den neu angelegten Obico-Hintergrunddienst direkt starten
        if [ -f "$INITD_FOLDER/S99moonraker_obico" ]; then
          "$INITD_FOLDER/S99moonraker_obico" start > /dev/null 2>&1 || true
        fi
        
        # 2. Moonraker sauber neu starten, damit das Plugin geladen wird
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
        
        # 1. Erst den Obico-Dienst sauber stoppen, falls er läuft
        if [ -f "$INITD_FOLDER"/S99moonraker_obico ]; then
          echo -e "Info: Stopping Moonraker Obico service..."
          "$INITD_FOLDER"/S99moonraker_obico stop > /dev/null 2>&1 || true
          rm -f "$INITD_FOLDER"/S99moonraker_obico
          # Sicherheits-Kill falls das Init-Skript hakt
          kill $(pgrep -f "moonraker_obico.app") > /dev/null 2>&1 || true
        fi

        # 2. Konfigurationen aus der moonraker.conf entfernen
        if grep -q "\[include moonraker-obico-update.cfg\]" "$MOONRAKER_CFG" ; then
          echo -e "Info: Removing Moonraker Obico configurations in moonraker.conf file..."
          sed -i '/\[include moonraker-obico-update\.cfg\]/d' "$MOONRAKER_CFG"
        else
          echo -e "Info: Moonraker Obico configurations are already removed in moonraker.conf file..."
        fi

        # 3. Reste aus der printer.cfg entfernen (falls vorhanden)
        if [ -f "$PRINTER_CFG" ] && grep -q "include moonraker_obico_macros" "$PRINTER_CFG" ; then
          echo -e "Info: Removing Moonraker Obico configurations in printer.cfg file..."
          sed -i '/include moonraker_obico_macros\.cfg/d' "$PRINTER_CFG"
        fi

        # 4. Dateien restlos und sauber löschen
        echo -e "Info: Removing files..."
        rm -rf "$MOONRAKER_OBICO_FOLDER"
        rm -rf /usr/data/moonraker-obico-env
        rm -f "$KLIPPER_CONFIG_FOLDER"/moonraker-obico-update.cfg 
        rm -f "$KLIPPER_CONFIG_FOLDER"/moonraker-obico.cfg
        rm -f "$KLIPPER_CONFIG_FOLDER"/config/moonraker-obico.cfg

        # 5. Dienste sauber neu starten
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