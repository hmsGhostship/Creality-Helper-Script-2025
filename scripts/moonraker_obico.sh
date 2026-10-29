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
        
        # 1. Download (falls gelöscht, ansonsten übersprungen)
        if [ -d "$MOONRAKER_OBICO_FOLDER" ]; then
          echo -e "Info: Moonraker Obico folder found."
        else
          echo -e "Info: Downloading Moonraker Obico..."
          git config --global http.sslVerify false
          git clone --depth 1 "$MOONRAKER_OBICO_URL" "$MOONRAKER_OBICO_FOLDER"
        fi

        # 2. RAM-SCHONEND: Direkt in die existierende Moonraker-Umgebung installieren
        echo -e "Info: Installing Obico dependencies into existing Moonraker Env (No Venv building!)..."
        cd "$MOONRAKER_OBICO_FOLDER"
        
        # Wir nutzen direkt das Klipper/Moonraker-Python deines Forks. 
        # --no-cache-dir verhindert, dass der RAM mit temporären Download-Dateien vollsteckt wird!
        $MOONRAKER_ENV_PYTHON -m pip install --no-cache-dir -r requirements.txt

        # 3. Port-Konfiguration aus deiner moonraker.conf auslesen
        local obico_cfg="$KLIPPER_CONFIG_FOLDER/moonraker-obico.cfg"
        echo -e "Info: Creating moonraker-obico.cfg..."
        cp ./moonraker-obico.cfg.sample "$obico_cfg"
        
        local real_port=7126
        if [ -f "$MOONRAKER_CFG" ]; then
          local detected_port=$(grep -A 5 "\[server\]" "$MOONRAKER_CFG" | grep "port" | awk '{print $3}' | tr -d '\r')
          [ ! -z "$detected_port" ] && real_port=$detected_port
        fi
        
        sed -i "s/host =.*/host = 127.0.0.1/g" "$obico_cfg"
        sed -i "s/port =.*/port = $real_port/g" "$obico_cfg"

        # 4. In moonraker.conf einbinden
        if ! grep -q "\[include moonraker-obico-update.cfg\]" "$MOONRAKER_CFG" ; then
          echo -e "\n[include moonraker-obico-update.cfg]" >> "$MOONRAKER_CFG"
        fi

        # 5. Autostart anlegen (nutzt jetzt auch das Moonraker-Python)
        echo -e "Info: Creating init service in $INITD_FOLDER..."
        cat << EOF > "$INITD_FOLDER/S99moonraker_obico"
#!/bin/sh
case "\$1" in
  start)
    echo "Starting Moonraker Obico..."
    sleep 2
    $MOONRAKER_ENV_PYTHON -m moonraker_obico.main -c $obico_cfg > /dev/null 2>&1 &
    ;;
  stop)
    echo "Stopping Moonraker Obico..."
    kill \$(pgrep -f "moonraker_obico.main") > /dev/null 2>&1
    ;;
  *)
    echo "Usage: \$0 {start|stop}"
    exit 1
esac
exit 0
EOF
        chmod +x "$INITD_FOLDER/S99moonraker_obico"

        ok_msg "Moonraker Obico has been installed successfully without crashing the RAM!"
        
        echo -e "${yellow}--------------------------------------------------------"
        echo -e "Führe jetzt diesen Befehl aus, um die App zu koppeln:"
        echo -e "$MOONRAKER_ENV_PYTHON -m moonraker_obico.link -c $obico_cfg"
        echo -e "--------------------------------------------------------${white}"
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
        fi

        # 2. Konfigurationen aus der moonraker.conf entfernen
        if grep -q "\[include moonraker-obico-update.cfg\]" "$MOONRAKER_CFG" ; then
          echo -e "Info: Removing Moonraker Obico configurations in moonraker.conf file..."
          # Nutzt eine robustere Methode, um den Include-Eintrag sauber zu löschen
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

        # 5. Dienste sauber über den Codebrained-Standard neu starten
        echo -e "Info: Restarting Moonraker service..."
        if command -v stop_moonraker >/dev/null 2>&1 && command -v start_moonraker >/dev/null 2>&1; then
          stop_moonraker
          sleep 1
          start_moonraker
        else
          # Fallback, falls die Funktionen im Kontext dieses Skripts nicht geladen sind
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