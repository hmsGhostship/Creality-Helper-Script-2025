#!/bin/sh

set -e

function fluidd_message(){
  top_line
  title 'Fluidd' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Fluidd is a free and open-source Klipper Web interface for     ${white}│"
  echo -e " │ ${cyan}managing your 3d printer.                                      ${white}│"
  echo -e " │ ${cyan}It will be accessible on port 4408.                            ${white}│"
  hr
  bottom_line
}

function install_fluidd_macros_safely(){
  local macro_dest="/usr/data/printer_data/config/Helper-Script/interface_macros.cfg"
  echo -e "Info: Creating/Verifying Fluidd/Mainsail wrapper for native commands..."
  mkdir -p "/usr/data/printer_data/config/Helper-Script"
  
  cat << EOF > "$macro_dest"
[gcode_macro PAUSE]
description: Pause the actual running print
rename_existing: PAUSE_BASE
gcode:
    PAUSE_BASE

[gcode_macro RESUME]
description: Resume the actual running print
rename_existing: RESUME_BASE
gcode:
    RESUME_BASE
EOF
  chmod 644 "$macro_dest"

  if [ -f "$PRINTER_CFG" ]; then
    sed -i '/interface_macros\.cfg/d' "$PRINTER_CFG"
    if grep -q "# CreateDate:" "$PRINTER_CFG"; then
      echo -e "Info: Injecting interface_macros below CreateDate..."
      sed -i '/# CreateDate:/a \[include Helper-Script\/interface_macros\.cfg\]' "$PRINTER_CFG"
    else
      echo -e "Info: CreateDate not found, injecting safely into line 5..."
      sed -i '5i \[include Helper-Script\/interface_macros\.cfg\]' "$PRINTER_CFG"
    fi
  fi
}

function restart_all_services_correctly(){
  # -> RESTART SEQUENCE: Klipper first!
  if command -v restart_klipper >/dev/null 2>&1; then
    echo -e "Info: Reinitializing Klipper service first..."
    restart_klipper
  elif [ -f "$INITD_FOLDER/CS55klipper_service" ]; then
    "$INITD_FOLDER/CS55klipper_service" restart > /dev/null 2>&1 || true
  fi
  
  sleep 2

  echo -e "Info: Restarting Moonraker service..."
  if command -v stop_moonraker >/dev/null 2>&1 && command -v start_moonraker >/dev/null 2>&1; then
    stop_moonraker && sleep 1 && start_moonraker
  else
    if [ -f "$INITD_FOLDER"/S56moonraker_service ]; then
      "$INITD_FOLDER"/S56moonraker_service restart > /dev/null 2>&1 || true
    fi
  fi

  echo -e "Info: Restarting Nginx service..."
  restart_nginx
}

function install_fluidd(){
  fluidd_message
  local yn
  while true; do
    install_msg "Fluidd" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Downloading Fluidd file..."
        "$CURL" -L "$FLUIDD_URL" -o "$USR_DATA"/fluidd.zip
        echo -e "Info: Creating directory..."
        if [ -d "$FLUIDD_FOLDER" ]; then
          rm -rf "$FLUIDD_FOLDER"
        fi
        mkdir -p "$FLUIDD_FOLDER"
        mv "$USR_DATA"/fluidd.zip "$FLUIDD_FOLDER"
        echo -e "Info: Extracting files..."
        unzip "$FLUIDD_FOLDER"/fluidd.zip -d "$FLUIDD_FOLDER"
        echo -e "Info: Removing temporary files..."
        rm -f "$FLUIDD_FOLDER"/fluidd.zip
        
        # -> ORIGINAL MOONRAKER WORKING CONFIGURATION
        if grep -q "#\[update_manager fluidd\]" "$MOONRAKER_CFG" ; then
          echo -e "Info: Enabling Fluidd configurations for Update Manager..."
          sed -i -e 's/^\s*#[[:space:]]*\[update_manager fluidd\]/[update_manager fluidd]/' -e '/^\[update_manager fluidd\]/,/^\s*$/ s/^\(\s*\)#/\1/' "$MOONRAKER_CFG"
        else
          echo -e "Info: Fluidd configurations are already enabled for Update Manager..."        
        fi
        
        # -> Fail-safe Pause/Resume macro fix below the date
        install_fluidd_macros_safely

        # -> Automatically restore Calibration Toolbox status bar if active
        if [ -f "$HS_CONFIG_FOLDER/calib_tool_box.cfg" ] && type install_fluidd_status_bar >/dev/null 2>&1; then
          install_fluidd_status_bar
        fi
        
        # -> THE CORRECT STARTUP SEQUENCE: Klipper must come first!
        restart_all_services_correctly
        
        ok_msg "Fluidd has been installed successfully!"
        echo -e "   You can now connect to Fluidd Web Interface with ${yellow}http://\$(check_ipaddress):4408${white}"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_fluidd(){
  fluidd_message
  local yn
  while true; do
    remove_msg "Fluidd" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Removing files..."
        rm -rf "$FLUIDD_FOLDER"
        
        # -> INTELLIGENT INTERFACE PROTECTION:
        if [ ! -d "$MAINSAIL_FOLDER" ]; then
          echo -e "Info: Mainsail not found. Removing interface_macros..."
          if [ -f "$PRINTER_CFG" ]; then
            sed -i '/interface_macros\.cfg/d' "$PRINTER_CFG"
          fi
          rm -f "/usr/data/printer_data/config/Helper-Script/interface_macros.cfg"
        else
          echo -e "Info: Mainsail is still installed. Keeping interface_macros active!"
        fi

        # -> SAFE COMMENTING OUT IN MOONRAKER.CONF:
        if grep -q "\[update_manager fluidd\]" "$MOONRAKER_CFG" ; then
          echo -e "Info: Disabling Fluidd configurations for Update Manager..."
          sed -i '/^\[update_manager fluidd\]/,/^\s*$/ s/^\(\s*\)\([^#]\)/#\1\2/' "$MOONRAKER_CFG"
        fi
        
        # Services restart sequence (Klipper first!)
        restart_all_services_correctly

        ok_msg "Fluidd has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}
