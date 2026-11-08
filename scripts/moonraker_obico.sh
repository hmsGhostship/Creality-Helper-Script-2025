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

                # 4. CONFIG CREATION, PORT ADJUSTMENT, AUTOMATIC CAMERA-PRIORITY & K1C LOG FIX
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
        
        # ➔ INTELLIGENT & INDESTRUCTIBLE BLOCK REPLACEMENT FOR THE WEBCAM SECTION:
        if [ -f "$USB_CAMERA_FILE" ]; then
          echo -e "Info: USB camera detected (priority 1). Configuring port 8082..."
          # Replace the entire [webcam] section—up to the blank line—with the USB block
          sed -i '/\[webcam\]/,/^$/c\[webcam\]\ndisable_video_streaming = False\nstream_url = http://localhost:8082/?action=stream\nsnapshot_url = http://localhost:8082/?action=snapshot\n' "$obico_cfg"
        elif [ -f "$BUILTIN_CAMERA_FILE" ]; then
          echo -e "Info: Only original camera detected. Configuring Nginx system path..."
          # Replaces the entire [webcam] section—up to the blank line—neatly with the built-in block
          sed -i '/\[webcam\]/,/^$/c\[webcam\]\ndisable_video_streaming = False\nstream_url = http://localhost/webcam/?action=stream\nsnapshot_url = http://localhost/webcam/?action=snapshot\n' "$obico_cfg"
        else
          echo -e "Info: No active camera found in the framework. Leaving the webcam section neutral."
          sed -i '/\[webcam\]/,/^$/c\[webcam\]\ndisable_video_streaming = False\n' "$obico_cfg"
        fi
        
        # K1C-LOG-FIX: Corrects the "path =" variable in the config to point to the K1C log directory
        sed -i "s|path = /home/pi/.*|path = /usr/data/printer_data/logs/moonraker-obico.log|g" "$obico_cfg"

        # 5. INTEGRATE INTO MOONRAKER.CONF & AUTO-CONFIGURE TRUSTED CLIENTS (Firewall Fix)
        if [ -f "$MOONRAKER_CFG" ]; then
          sed -i '/\[include moonraker-obico-update\.cfg\]/d' "$MOONRAKER_CFG"
          
          # Checks whether trusted_clients exists in moonraker.conf
          if grep -q "trusted_clients:" "$MOONRAKER_CFG"; then
            echo "Info: trusted_clients found. Adding IPs intelligently..."
            if ! grep -q "127.0.0.1" "$MOONRAKER_CFG" && ! grep -q "127.0.0.0/8" "$MOONRAKER_CFG"; then
              sed -i '/trusted_clients:/a \  127.0.0.1' "$MOONRAKER_CFG"
            fi
            if ! grep -q "192.168.178.0" "$MOONRAKER_CFG" && ! grep -q "192.168.0.0/16" "$MOONRAKER_CFG"; then
              sed -i '/trusted_clients:/a \  192.168.178.0/24' "$MOONRAKER_CFG"
            fi
          else
            echo "Info: trusted_clients fehlt komplett. Erstelle Sektion neu..."
            if grep -q "\[authorization\]" "$MOONRAKER_CFG"; then
              sed -i '/\[authorization\]/a trusted_clients:\n  127.0.0.1\n  192.168.178.0/24' "$MOONRAKER_CFG"
            fi
          fi
        fi

        # 6. CLEAN VIRTUAL LINKING & AUTOMATIC LIVE-PATCHING OF OBICO MACROS
        local obico_macros_dest="$KLIPPER_CONFIG_FOLDER/Helper-Script/moonraker_obico_macros.cfg"
        local obico_macros_src=""

        # Intelligently check whether the folder include_cfg or include_cfgs exists in the cloned repository
        if [ -f "$MOONRAKER_OBICO_FOLDER/include_cfg/moonraker_obico_macros.cfg" ]; then
          obico_macros_src="$MOONRAKER_OBICO_FOLDER/include_cfg/moonraker_obico_macros.cfg"
        elif [ -f "$MOONRAKER_OBICO_FOLDER/include_cfgs/moonraker_obico_macros.cfg" ]; then
          obico_macros_src="$MOONRAKER_OBICO_FOLDER/include_cfgs/moonraker_obico_macros.cfg"
        fi
        
        if [ ! -z "$obico_macros_src" ] && [ -f "$obico_macros_src" ]; then
          echo -e "Info: Permanently patch the Obico macro variable to True."
          sed -i 's/variable_is_linked:.*/variable_is_linked: True/g' "$obico_macros_src"
          
          echo -e "Info: Creating a virtual symlink in the helper script folder..."
          rm -f "$obico_macros_dest"
          ln -s "$obico_macros_src" "$obico_macros_dest"
        else
          error_msg "Error: Original Obico macro file not found in the repository!"
          return 1
        fi

        if [ -f "$PRINTER_CFG" ]; then
          sed -i '/moonraker_obico_macros\.cfg/d' "$PRINTER_CFG"
          
          if grep -q "# CreateDate:" "$PRINTER_CFG"; then
            echo -e "Info: Injecting include directly below CreateDate..."
            sed -i '/# CreateDate:/a \[include Helper-Script\/moonraker_obico_macros\.cfg\]' "$PRINTER_CFG"
          else
            echo -e "Info: CreateDate not found, injecting safely into line 5..."
            sed -i '5i \[include Helper-Script\/moonraker_obico_macros\.cfg\]' "$PRINTER_CFG"
          fi
        fi

        # 7. SET UP AUTOSTART
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
        
        # 8. AUTOMATIC PAIRING PROCESS
        echo -e "${yellow}--------------------------------------------------------"
        echo -e "Starting automatic pairing process..."
        echo -e "Please enter the displayed code into the Obico app right away."
        echo -e "Note: The code is valid for approximately 3–5 minutes."
        echo -e "--------------------------------------------------------${white}"
        sleep 2
        
        if ! PYTHONPATH="$MOONRAKER_OBICO_FOLDER" $active_python -m moonraker_obico.link -c "$obico_cfg"; then
          echo -e "\n${yellow}Note: The pairing process was interrupted or the time window has expired."
          echo -e "The pairing can be performed manually in the terminal at any later time using:"
          echo -e "PYTHONPATH=\"$MOONRAKER_OBICO_FOLDER\" $active_python -m moonraker_obico.link -c $obico_cfg${white}\n"
        fi
        
        echo -e "Info: Configuring system startups for live operation..."
        if [ -f "$INITD_FOLDER/S99moonraker_obico" ]; then
          "$INITD_FOLDER/S99moonraker_obico" start > /dev/null 2>&1 || true
        fi
        
        # ➔ HERE, WE NOW MAKE USE OF THE PURE FRAMEWORK FUNCTIONS FOR MOONRAKER & KLIPPER:
        echo -e "Info: Performing a controlled system restart..."
        
        # 1. Stop Moonraker cleanly and start it fresh (bypasses the Creality restart bug)
        if command -v stop_moonraker >/dev/null 2>&1 && command -v start_moonraker >/dev/null 2>&1; then
          stop_moonraker && sleep 1 && start_moonraker
        elif [ -f "$INITD_FOLDER/S56moonraker_service" ]; then
          "$INITD_FOLDER/S56moonraker_service" restart > /dev/null 2>&1 || true
        fi

        # 2. Freshly load Klipper using the official framework function
        if command -v restart_klipper >/dev/null 2>&1; then
          echo -e "Info: Initiating Klipper restart via framework.."
          restart_klipper
        fi

        ok_msg "Installation complete! All services have been successfully loaded."
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
        
        if [ -f "$INITD_FOLDER"/S99moonraker_obico ]; then
          echo -e "Info: Stopping Moonraker Obico service..."
          "$INITD_FOLDER"/S99moonraker_obico stop > /dev/null 2>&1 || true
          rm -f "$INITD_FOLDER"/S99moonraker_obico
          kill $(pgrep -f "moonraker_obico.app") > /dev/null 2>&1 || true
        fi

        if grep -q "\[include moonraker-obico-update.cfg\]" "$MOONRAKER_CFG" ; then
          echo -e "Info: Removing Moonraker Obico configurations in moonraker.conf file..."
          sed -i '/\[include moonraker-obico-update\.cfg\]/d' "$MOONRAKER_CFG"
        fi

        if [ -f "$PRINTER_CFG" ]; then
          echo -e "Info: Cleanly removing Obico macro includes from printer.cfg..."
          sed -i '/moonraker_obico_macros\.cfg/d' "$PRINTER_CFG"
        fi

        echo -e "Info: Removing files..."
        rm -rf "$MOONRAKER_OBICO_FOLDER"
        rm -rf /usr/data/moonraker-obico-env
        rm -f "$KLIPPER_CONFIG_FOLDER"/moonraker-obico-update.cfg 
        rm -f "$KLIPPER_CONFIG_FOLDER"/moonraker-obico.cfg
        rm -f "$KLIPPER_CONFIG_FOLDER"/Helper-Script/moonraker_obico_macros.cfg

        echo -e "Info: Restarting Moonraker service..."
        if command -v stop_moonraker >/dev/null 2>&1 && command -v start_moonraker >/dev/null 2>&1; then
          stop_moonraker && sleep 1 && start_moonraker
        else
          if [ -f "$INITD_FOLDER"/S56moonraker_service ]; then
            "$INITD_FOLDER"/S56moonraker_service restart > /dev/null 2>&1 || true
          fi
        fi

        echo -e "Info: Restarting services..."
        if command -v stop_moonraker >/dev/null 2>&1 && command -v start_moonraker >/dev/null 2>&1; then
          stop_moonraker && sleep 1 && start_moonraker
        else
          if [ -f "$INITD_FOLDER"/S56moonraker_service ]; then
            "$INITD_FOLDER"/S56moonraker_service restart > /dev/null 2>&1 || true
          fi
        fi
        # Also perform a fresh load of Klipper after removal
        if command -v restart_klipper >/dev/null 2>&1; then
          restart_klipper
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

function repair_pairing_moonraker_obico(){
  moonraker_obico_message
  
  local obico_cfg="$KLIPPER_CONFIG_FOLDER/moonraker-obico.cfg"
  
  if [ ! -d "$MOONRAKER_OBICO_FOLDER" ] || [ ! -f "$obico_cfg" ]; then
    error_msg "Error: Moonraker Obico is currently not installed!"
    return 1
  fi

  local yn
  while true; do
    echo -e " ${yellow}➔ Do you want to re-link your printer with the Obico app?${white}"
    read -p "   Confirm action? (y/n): " yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        
        # 1. Dynamically detect the active Moonraker Python environment
        echo -e "Info: Detecting Moonraker Python Environment..."
        local active_python=$(ps w | grep moonraker | grep -v grep | awk '{print $5}')
        if [ -z "$active_python" ] || [ ! -f "$active_python" ]; then
          active_python="$MOONRAKER_ENV_PYTHON"
        fi
        
        if [ ! -f "$active_python" ]; then
          error_msg "Error: No valid Moonraker Python environment found!"
          return 1
        fi

        # 2. Stop the active Obico daemon to prevent token/port conflicts during configuration
        if [ -f "$INITD_FOLDER/S99moonraker_obico" ]; then
          echo -e "Info: Stopping active Obico service for re-pairing..."
          "$INITD_FOLDER/S99moonraker_obico" stop > /dev/null 2>&1 || true
          kill $(pgrep -f "moonraker_obico.app") > /dev/null 2>&1 || true
        fi

        # ====================================================================
        # THE CORE ANCHOR TRICK: Clear the old token value to completely 
        # bypass the blocking interactive prompt inside the Python script!
        # ====================================================================
        echo -e "Info: Preparing configuration file for a clean pairing process..."
        sed -i 's/^api_token[[:space:]]*=.*/api_token = /g' "$obico_cfg"

        # 3. Launch the linking process in full interactive live-waiting mode
        echo -e "${yellow}--------------------------------------------------------"
        echo -e "Starting the automatic pairing wizard..."
        echo -e "Please follow the instructions displayed below."
        echo -e "The script will pause and wait for your app confirmation."
        echo -e "--------------------------------------------------------${white}"
        sleep 1
        
        # Fully interactive terminal handshake without any piped inputs
        if ! PYTHONPATH="$MOONRAKER_OBICO_FOLDER" $active_python -m moonraker_obico.link -c "$obico_cfg"; then
          echo -e "\n${yellow}Note: The pairing process was canceled or timed out.${white}\n"
        fi
        
        # 4. Safely bring up the daemon back into action for live operations
        echo -e "Info: Restoring Obico service startups for live operations..."
        if [ -f "$INITD_FOLDER/S99moonraker_obico" ]; then
          "$INITD_FOLDER/S99moonraker_obico" start > /dev/null 2>&1 || true
        fi

        ok_msg "Re-pairing sequence completed successfully!"
        return 0
        ;;
      N|n)
        error_msg "Action canceled!"
        return 0
        ;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}