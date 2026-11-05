#!/bin/sh

set -e

function mainsail_message(){
  top_line
  title 'Mainsail' "${yellow}"
  inner_line
  hr
  echo -e " │ This makes Klipper more accessible by adding a                 │"
  echo -e " │ lightweight, responsive web user interface.                    │"
  echo -e " │ It will be accessible on port 4409.                            │"
  hr
  bottom_line
}

function install_mainsail(){
  mainsail_message
  local yn
  while true; do
    install_msg "Mainsail" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Downloading Mainsail file..."
        "$CURL" -L "$MAINSAIL_URL" -o "$USR_DATA"/mainsail.zip
        echo -e "Info: Creating directory..."
        if [ -d "$MAINSAIL_FOLDER" ]; then
          rm -rf "$MAINSAIL_FOLDER"
        fi
        mkdir -p "$MAINSAIL_FOLDER"
        mv "$USR_DATA"/mainsail.zip "$MAINSAIL_FOLDER"
        echo -e "Info: Extracting files..."
        unzip "$MAINSAIL_FOLDER"/mainsail.zip -d "$MAINSAIL_FOLDER"
        echo -e "Info: Removing temporary files..."
        rm -f "$MAINSAIL_FOLDER"/mainsail.zip
        
        if grep -q "#\[update_manager mainsail\]" "$MOONRAKER_CFG" ; then
          echo -e "Info: Enabling Mainsail configurations for Update Manager..."
          sed -i -e 's/^\s*#[[:space:]]*\[update_manager mainsail\]/[update_manager mainsail]/' -e '/^\[update_manager mainsail\]/,/^\s*$/ s/^\(\s*\)#/\1/' "$MOONRAKER_CFG"
        fi

        # -> INTERFACE FIX FOR NATIVE FIRMWARE COMMANDS
        local macro_dest="/usr/data/printer_data/config/Helper-Script/interface_macros.cfg"
        echo -e "Info: Creating Mainsail interface wrapper for native firmware commands..."
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

        # -> RESTART SEQUENCY (Klipper first!)
        if command -v restart_klipper >/dev/null 2>&1; then
          echo -e "Info: Reinitializing Klipper service first to apply configuration..."
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

        echo -e "Info: Restarting Nginx web server..."
        restart_nginx
        
        ok_msg "Mainsail has been installed successfully!"
        echo -e "   You can now connect to Mainsail Web Interface with ${yellow}http://\$(check_ipaddress):4409${white}"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_mainsail(){
  mainsail_message
  local yn
  while true; do
    remove_msg "Mainsail" yn
    case "${yn}" in
            Y|y)
        echo -e "${white}"
        echo -e "Info: Removing files..."
        rm -rf "$MAINSAIL_FOLDER"
        
        # -> INTELLIGENT INTERFACE CROSS-PROTECTION
        if [ ! -d "$FLUIDD_FOLDER" ]; then
          echo -e "Info: Fluidd not found. Safely removing interface_macros..."
          if [ -f "$PRINTER_CFG" ]; then
            sed -i '/interface_macros\.cfg/d' "$PRINTER_CFG"
          fi
          rm -f "/usr/data/printer_data/config/Helper-Script/interface_macros.cfg"
        else
          echo -e "Info: Fluidd is still installed. Keeping interface_macros active for Fluidd!"
        fi

        # SAFE MOONRAKER CLEANUP
        if [ -f "$MOONRAKER_CFG" ]; then
          echo -e "Info: Cleaning Moonraker configuration safely..."
          sed -i '/\[update_manager mainsail\]/,/^[[:space:]]*$/d' "$MOONRAKER_CFG"
        fi

        echo -e "Info: Restarting Nginx service..."
        restart_nginx
        
        # -> CORRECT RESTART SEQUENCE
        if command -v restart_klipper >/dev/null 2>&1; then
          echo -e "Info: Reinitializing Klipper service first..."
          restart_klipper
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

        ok_msg "Mainsail has been removed successfully! Fluidd remains untouched."
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}