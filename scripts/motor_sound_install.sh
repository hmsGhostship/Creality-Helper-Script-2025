#!/bin/sh

set -e

function motor_sound_message(){
  top_line
  title 'Motor Sound Support' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}It allows to play sounds using the X and Y stepper motors.     ${white}│"
  hr
  bottom_line
}

function install_motor_sound(){
  motor_sound_message
  local yn
  while true; do
    install_msg "Motor Sound Support" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        
        # Safety check: Does the source file exist?
        if [ ! -f "$MOTOR_SOUND_SORCE_FILE" ]; then
          error_msg "Error: Source macro not found at $MOTOR_SOUND_SORCE_FILE!"
          return 1
        fi

        # Ensure target directory physically exists
        if [ ! -d "$HS_CONFIG_FOLDER" ]; then
          mkdir -p "$HS_CONFIG_FOLDER"
        fi
        
        # SAUBERER FIX: Physisches Kopieren statt instabiler Verlinkung!
        echo -e "Info: Copying macro file to configuration directory..."
        cp -f "$MOTOR_SOUND_SORCE_FILE" "$MOTOR_SOUND_TARGET_FILE"
        
        # Extract plain filename (e.g. motor-sound.cfg) for printer.cfg include
        local cfg_filename=$(basename "$MOTOR_SOUND_TARGET_FILE")
        
        if grep -q "include Helper-Script/$cfg_filename" "$PRINTER_CFG" ; then
          echo -e "Info: Motor Sound configurations are already enabled in printer.cfg file..."
        else
          echo -e "Info: Adding Motor Sound configurations in printer.cfg file..."
          if grep -q "# CreateDate:" "$PRINTER_CFG"; then sed -i "/^[[:space:]]*#[[:space:]]*CreateDate:.*/a [include Helper-Script/$cfg_filename]" "$PRINTER_CFG"; else sed -i "5i [include Helper-Script/$cfg_filename]" "$PRINTER_CFG"; fi
        fi
        
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Motor Sound Support has been installed successfully!"
        echo -e "   You can now use ${yellow}BEEP ${white}command in your macros to play sound via motors."
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_motor_sound(){
  motor_sound_message
  local yn
  while true; do
    remove_msg "Motor Sound Support" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        
        # Physically delete the copied configuration file
        echo -e "Info: Removing macro file..."
        rm -f "$MOTOR_SOUND_TARGET_FILE"
        
        local cfg_filename=$(basename "$MOTOR_SOUND_TARGET_FILE")
        
        if grep -q "include Helper-Script/$cfg_filename" "$PRINTER_CFG" ; then
          echo -e "Info: Removing Motor Sound configurations in printer.cfg file..."
          sed -i "/include Helper-Script\/$cfg_filename/d" "$PRINTER_CFG"
        else
          echo -e "Info: Motor Sound configurations are already removed in printer.cfg file..."
        fi
        
        # Clean up folder if completely empty after deletion
        if [ -d "$HS_CONFIG_FOLDER" ] && [ ! -n "$(ls -A "$HS_CONFIG_FOLDER")" ]; then
          rm -rf "$HS_CONFIG_FOLDER"
        fi
        
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Motor Sound Support has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}
