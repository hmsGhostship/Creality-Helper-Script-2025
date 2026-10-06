#!/bin/sh

set -e

function octoeverywhere_message(){
  top_line
  title 'OctoEverywhere' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Cloud empower your Klipper printers with free, private, and  ${white}│"
  echo -e " │ ${cyan}unlimited remote access to your full web control portal from ${white}│"
  echo -e " │ ${cyan}anywhere!                                                    ${white}│"
  hr
  bottom_line
}

function install_octoeverywhere(){
  octoeverywhere_message
  local yn
  while true; do
    install_msg "OctoEverywhere" yn
    case "${yn}" in
	Y|y)
        echo -e "${white}"
        
        echo -e "Info: Aktualisiere OctoEverywhere Repository..."
        if [ -d "$OCTOEVERYWHERE_FOLDER" ]; then
          rm -rf "$OCTOEVERYWHERE_FOLDER"
        fi
        git config --global http.sslVerify false
        git clone "$OCTOEVERYWHERE_URL" "$OCTOEVERYWHERE_FOLDER"
        
        echo -e "Info: Installiere Python-Abhängigkeiten direkt in das Moonraker-System..."
        /usr/data/moonraker/moonraker-env/bin/python3 -m pip install --cache-dir /usr/data/tmp -r "$OCTOEVERYWHERE_FOLDER/requirements.txt"
        
        echo -e "Info: Trage OctoEverywhere-Plugin in die moonraker.conf ein..."
        CONF_FILE="/usr/data/printer_data/config/moonraker.conf"
        if [ -f "$CONF_FILE" ]; then
          if ! grep -q "\[octoeverywhere\]" "$CONF_FILE"; then
            echo -e "\n[octoeverywhere]\nweb_interface_target: mainsail\nweb_interface_port: 4409" >> "$CONF_FILE"
          fi
        fi
        
        echo -e "Info: Erstelle permanente System-Startkonfiguration..."
        START_SCRIPT="/usr/data/helper-script/scripts/octoeverywhere_start.sh"
        
        # FIX: Hier nutzen wir die echten Variablen des Helpers und hängen NUR den permanenten Logpath an!
        echo -e "#!/bin/sh\ncd \$OCTOEVERYWHERE_FOLDER && PYTHONPATH=\$OCTOEVERYWHERE_FOLDER \$MOONRAKER_ENV_PYTHON -m moonraker_octoeverywhere --mconf \$CONF_FILE --logpath /usr/data/printer_data/logs > /dev/null 2>&1 &" > "$START_SCRIPT"
        chmod +x "$START_SCRIPT"
        
        # Für den aktuellen Boot-Zyklus direkt verknüpfen
        ln -sf "$START_SCRIPT" /etc/init.d/S99octoeverywhere || true

        echo -e "\n${yellow}------------------------------------------------------------"
        echo -e "${cyan}   K1C 2025 NATIVE AUTOMATION BEENDET"
        echo -e "${yellow}------------------------------------------------------------${white}"
        ok_msg "OctoEverywhere erfolgreich installiert!"
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
        echo -e "Info: Entferne OctoEverywhere Komponenten..."
        rm -rf "$OCTOEVERYWHERE_FOLDER"
        rm -f /usr/data/helper-script/scripts/octoeverywhere_start.sh
        rm -f /etc/init.d/S99octoeverywhere
        
        CONF_FILE="/usr/data/printer_data/config/moonraker.conf"
        if [ -f "$CONF_FILE" ]; then
          sed -i '/\[octoeverywhere\]/,+2d' "$CONF_FILE" || true
        fi
        
        ok_msg "OctoEverywhere wurde restlos entfernt!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}