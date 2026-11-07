#!/bin/sh

set -e

function guppyflo_message(){
  top_line
  title 'GuppyFLO' "${yellow}"
  inner_line
  hr
  echo -e " │ GuppyFLO is a self-hosted service that enables local/remote    │"
  echo -e " │ management of multiple Klipper printers using Moonraker.       │"
  hr
  bottom_line
}

function install_guppyflo(){
  guppyflo_message
  local yn
  while true; do
    install_msg "GuppyFLO" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        
        # Safe stopping of old service
        if [ -f "$INITD_FOLDER"/S99guppyflo ]; then
          echo -e "Info: Stopping old GuppyFLO service..."
          "$INITD_FOLDER"/S99guppyflo stop > /dev/null 2>&1 || true
        fi
        
        if [ -f "$GUPPYFLO_FOLDER"/guppytunnel.json ]; then
          mv "$GUPPYFLO_FOLDER"/guppytunnel.json "$USR_DATA"/guppytunnel.json
        fi
        
        echo -e "Info: Cleaning up old installation folders safely..."
        rm -rf "$GUPPYFLO_FOLDER"
        rm -f "$INITD_FOLDER"/S99guppyflo
        
        echo -e "Info: Downloading GuppyFLO package..."
        "$CURL" -L "$GUPPYFLO_URL" -o "$USR_DATA"/guppyflo.zip
        echo -e "Info: Extracting files..."
        mkdir -p "$GUPPYFLO_FOLDER"
        unzip "$USR_DATA"/guppyflo.zip -d "$GUPPYFLO_FOLDER"
        rm -f "$USR_DATA"/guppyflo.zip
        
        if [ -f "$USR_DATA"/guppytunnel.json ]; then
          mv "$USR_DATA"/guppytunnel.json "$GUPPYFLO_FOLDER"/guppytunnel.json
        fi
        
        # -> SAFE SERVICE CREATION WITHOUT TOUCHING SYSTEM LIBRARIES
        echo -e "Info: Creating isolated initialization script..."
        cat << EOF > "$INITD_FOLDER/S99guppyflo"
#!/bin/sh
case "\$1" in
  start)
    echo "Starting GuppyFLO..."
    # Starts the service directly from data directory
    cd $GUPPYFLO_FOLDER
    ./guppyflo > /dev/null 2>&1 &
    ;;
  stop)
    echo "Stopping GuppyFLO..."
    killall guppyflo > /dev/null 2>&1 || true
    ;;
  *)
    echo "Usage: \$0 {start|stop}"
    exit 1
esac
exit 0
EOF
        chmod +x "$INITD_FOLDER"/S99guppyflo
        
        echo -e "Info: Starting GuppyFLO service..."
        "$INITD_FOLDER"/S99guppyflo start > /dev/null 2>&1 || true
        
        # -> DER NEUE, VOLLSTÄNDIGE INFO-BLOCK FÜR DEINEN REPOSITORY-STANDARD:
        ok_msg "GuppyFLO has been installed successfully!"
        echo -e "   ----------------------------------------------------------------"
        echo -e "   Local Access:  ${yellow}http://\$(check_ipaddress):9873${white}"
        echo -e "   ----------------------------------------------------------------"
        echo -e "   Remote Access Note:"
        echo -e "   To configure Remote Access via Tailscale or Ngrok, simply open"
        echo -e "   the Web Interface above and follow the instructions on the screen."
        echo -e "   No additional system packages are required!"
        echo -e "   ----------------------------------------------------------------"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_guppyflo(){
  guppyflo_message
  local yn
  while true; do
    remove_msg "GuppyFLO" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        
        # Stops and removes the service if the init script exists
        if [ -f "$INITD_FOLDER/S99guppyflo" ]; then
          echo -e "Info: Stopping GuppyFLO service..."
          "$INITD_FOLDER/S99guppyflo" stop > /dev/null 2>&1 || true
          echo -e "Info: Removing service initialization script..."
          rm -f "$INITD_FOLDER/S99guppyflo"
        fi
        
        # Cleans up the installation directory completely
        if [ -d "$GUPPYFLO_FOLDER" ]; then
          echo -e "Info: Removing GuppyFLO installation files..."
          rm -rf "$GUPPYFLO_FOLDER"
        fi
        
        # Safely cleans up the backup json from the user data folder if left behind
        rm -f "$USR_DATA/guppytunnel.json"
        
        ok_msg "GuppyFLO has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}
