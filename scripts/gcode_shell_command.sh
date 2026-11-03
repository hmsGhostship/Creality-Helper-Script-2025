#!/bin/sh

set -e

function gcode_shell_command_message(){
  top_line
  title 'Klipper Gcode Shell Command' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}After installing this extension you can execute Linux        ${white}│"
  echo -e " │ ${cyan}commands or even scripts from Klipper with custom commands   ${white}│"
  echo -e " │ ${cyan}defined in your configuration files.                         ${white}│"
  hr
  bottom_line
}

function install_gcode_shell_command(){
  gcode_shell_command_message
  local yn
  while true; do
    install_msg "Klipper Gcode Shell Command" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        
        # Sicherheits-Check: Existiert die lokale Quelldatei am definierten Pfad?
        if [ ! -f "$KLIPPER_SHELL_URL" ]; then
          error_msg "Fehler: Quelldatei unter $KLIPPER_SHELL_URL nicht gefunden!"
          return 1
        fi
        # SAUBERER FIX: Physisches Kopieren statt symbolischer Verlinkung!
        echo -e "Info: Copying file locally..."
        cp -f "$KLIPPER_SHELL_URL" "$KLIPPER_EXTRAS_FOLDER"/gcode_shell_command.py
        
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Klipper Gcode Shell Command has been installed successfully!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_gcode_shell_command(){
  gcode_shell_command_message
  local yn
  while true; do
    remove_msg "Klipper Gcode Shell Command" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Removing files..."
        rm -f "$KLIPPER_EXTRAS_FOLDER"/gcode_shell_command.py
        rm -f "$KLIPPER_EXTRAS_FOLDER"/gcode_shell_command.pyc
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Klipper Gcode Shell Command has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}