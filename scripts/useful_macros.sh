#!/bin/sh

set -e

function backup_macros_message(){
  top_line
  title 'Backup & Restore Macros' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}It allows to use secure macros to backup and restore Klipper  ${white}│"
  echo -e " │ ${cyan}configurations files and Moonraker database.                 ${white}│"
  hr
  bottom_line
}

function install_backup_macros(){
  backup_macros_message
  local yn
  while true; do
    install_msg "Backup & Restore Macros" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        # Löscht alte Reste, falls vorhanden
        if [ -f "$BACKUP_MACROS_TARGET_FILE" ]; then
          rm -f "$BACKUP_MACROS_TARGET_FILE"
        fi
        if [ ! -d "$HS_CONFIG_FOLDER" ]; then
          mkdir -p "$HS_CONFIG_FOLDER"
        fi
        echo -e "Info: Linking file..."
        # Verknüpft direkt deine sichere, lokale Backup-Datei ohne 3V3/K1-Online-Weichen
        ln -sf "$BACKUP_MACROS_SORCE_FILE" "$BACKUP_MACROS_TARGET_FILE"
        
        # Holt den reinen Dateinamen (backup-macros.cfg) für das printer.cfg include
        local cfg_filename=$(basename "$BACKUP_MACROS_TARGET_FILE")
        
        if grep -q "include Helper-Script/$cfg_filename" "$PRINTER_CFG" ; then
          echo -e "Info: Backup Macros configurations are already enabled in printer.cfg file..."
        else
          echo -e "Info: Adding Backup Macros configurations in printer.cfg file..."
          sed -i "/\[include printer_params\.cfg\]/a \[include Helper-Script/$cfg_filename\]" "$PRINTER_CFG"
        fi
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Backup Macros have been installed successfully!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_backup_macros(){
  backup_macros_message
  local yn
  while true; do
    remove_msg "Backup & Restore Macros" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Removing file..."
        rm -f "$BACKUP_MACROS_TARGET_FILE"
        
        local cfg_filename=$(basename "$BACKUP_MACROS_TARGET_FILE")
        
        if grep -q "include Helper-Script/$cfg_filename" "$PRINTER_CFG" ; then
          echo -e "Info: Removing Backup Macros configurations in printer.cfg file..."
          sed -i "/include Helper-Script\/$cfg_filename/d" "$PRINTER_CFG"
        else
          echo -e "Info: Backup Macros configurations are already removed in printer.cfg file..."
        fi
        if [ ! -n "$(ls -A "$HS_CONFIG_FOLDER")" ]; then
          rm -rf "$HS_CONFIG_FOLDER"
        fi
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Backup Macros have been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}