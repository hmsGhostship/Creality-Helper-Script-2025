#!/bin/sh

set -e

function improved_shapers_message(){
  top_line
  title 'Improved Shapers Calibrations' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}It allows to calibrate Input Shaper, Belts Tension and       ${white}│"
  echo -e " │ ${cyan}generate Graphs.                                             ${white}│"
  hr
  bottom_line
}

function install_improved_shapers(){
  improved_shapers_message
  local yn
  while true; do
    install_msg "Improved Shapers Calibrations" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Backing up original file..."
        if [ ! -d "$HS_BACKUP_FOLDER"/improved-shapers ]; then
          mkdir -p "$HS_BACKUP_FOLDER"/improved-shapers
        fi
        if [ ! -f "$HS_BACKUP_FOLDER"/ft2font.cpython-38-mipsel-linux-gnu.so ]; then
          mv /usr/lib/python3.8/site-packages/matplotlib/ft2font.cpython-38-mipsel-linux-gnu.so "$HS_BACKUP_FOLDER"/improved-shapers
        fi
        echo -e "Info: Copying files locally..."
        local source_dir="$HS_FILES/improved-shapers"
        
        cp -f "$source_dir/calibrate_shaper_config.py" "$KLIPPER_EXTRAS_FOLDER"/calibrate_shaper_config.py
        
        if [ ! -d "/usr/lib/python3.8/site-packages/matplotlib-2.2.3-py3.8.egg-info" ]; then
          echo -e "Info: matplotlib ft2font module is not replaced. PSD graphs might not work..."
        else
          echo -e "Info: Replacing matplotlib ft2font module to generate PSD graphs..."
          cp -f "$source_dir/ft2font.cpython-38-mipsel-linux-gnu.so" /usr/lib/python3.8/site-packages/matplotlib/ft2font.cpython-38-mipsel-linux-gnu.so
        fi
        
        rm -rf "$HS_CONFIG_FOLDER"/improved-shapers
        mkdir -p "$HS_CONFIG_FOLDER"/improved-shapers/scripts
        
        cp -f "$source_dir"/scripts/*.py "$HS_CONFIG_FOLDER"/improved-shapers/scripts/
        cp -f "$source_dir"/improved-shapers.cfg "$HS_CONFIG_FOLDER"/improved-shapers/improved-shapers.cfg

        if grep -q 'variable_autotune_shapers:' "$MACROS_CFG" ; then
          echo -e "Info: Disabling [gcode_macro AUTOTUNE_SHAPERS] configurations in gcode_macro.cfg file..."
          sed -i 's/variable_autotune_shapers:/#&/' "$MACROS_CFG"
        else
          echo -e "Info: [gcode_macro AUTOTUNE_SHAPERS] configurations are already disabled in gcode_macro.cfg file..."
        fi
        if [ "$model" = "K1" ]; then
          if grep -q '\[gcode_macro INPUTSHAPER\]' "$MACROS_CFG" ; then
            echo -e "Info: Replacing [gcode_macro INPUTSHAPER] configurations in gcode_macro.cfg file..."
            sed -i 's/SHAPER_CALIBRATE AXIS=y/SHAPER_CALIBRATE/' "$MACROS_CFG"
          else
            echo -e "Info: [gcode_macro INPUTSHAPER] configurations are already replaced in gcode_macro.cfg file..."
          fi
        fi
        if grep -q "include Helper-Script/improved-shapers/improved-shapers" "$PRINTER_CFG" ; then
          echo -e "Info: Improved Shapers Calibration configurations are already enabled in printer.cfg file..."
        else
          echo -e "Info: Adding Improved Shapers Calibration configurations in printer.cfg file..."
          sed -i '/\[include printer_params\.cfg\]/a \[include Helper-Script/improved-shapers/improved-shapers\.cfg\]' "$PRINTER_CFG"
        fi
        echo -e "Info: Restarting Moonraker service..."
        stop_moonraker
        start_moonraker
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Improved Shapers Calibrations have been installed successfully!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_improved_shapers(){
  improved_shapers_message
  local yn
  while true; do
    remove_msg "Improved Shapers Calibrations" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        
        # 1. Das Original-Systemmodul wiederherstellen, falls Backup existiert
        if [ -f "$HS_BACKUP_FOLDER"/improved-shapers/ft2font.cpython-38-mipsel-linux-gnu.so ]; then
          echo -e "Info: Restoring original file..."
          mv "$HS_BACKUP_FOLDER"/improved-shapers/ft2font.cpython-38-mipsel-linux-gnu.so /usr/lib/python3.8/site-packages/matplotlib
          rm -rf "$HS_BACKUP_FOLDER"/improved-shapers
        fi
        
        if [ -d "$HS_BACKUP_FOLDER" ] && [ ! -n "$(ls -A "$HS_BACKUP_FOLDER")" ]; then
          rm -rf "$HS_BACKUP_FOLDER"
        fi
        
        # 2. FIX: Gezielt nur den Shaper-Ordner loeschen! (Schuetzt deine restlichen Makros!)
        echo -e "Info: Removing Shaper files..."
        rm -rf "$HS_CONFIG_FOLDER"/improved-shapers
        
        # Klipper-Dateien loeschen
        rm -f "$KLIPPER_EXTRAS_FOLDER"/calibrate_shaper_config.py
        rm -f "$KLIPPER_EXTRAS_FOLDER"/calibrate_shaper_config.pyc
        
        # 3. Klipper-Makro Konfigurationen in gcode_macro.cfg restaurieren
        if grep -q "#variable_autotune_shapers:" "$MACROS_CFG"; then
          echo -e "Info: Restoring [gcode_macro AUTOTUNE_SHAPERS] configurations in gcode_macro.cfg file..."
          sed -i 's/#variable_autotune_shapers:/variable_autotune_shapers:/' "$MACROS_CFG"
        else
          echo -e "Info: [gcode_macro AUTOTUNE_SHAPERS] configurations are already restored in gcode_macro.cfg file..."
        fi
        
        if [ "$model" = "K1" ]; then
          if grep -q '\[gcode_macro INPUTSHAPER\]' "$MACROS_CFG" ; then
            echo -e "Info: Restoring [gcode_macro INPUTSHAPER] configurations in gcode_macro.cfg file..."
            sed -i 's/SHAPER_CALIBRATE/SHAPER_CALIBRATE AXIS=y/' "$MACROS_CFG"
          else
            echo -e "Info: [gcode_macro INPUTSHAPER] configurations are already restored in gcode_macro.cfg file..."
          fi
        fi
        
        # 4. Include aus printer.cfg saubermachen
        if grep -q "include Helper-Script/improved-shapers/improved-shapers" "$PRINTER_CFG" ; then
          echo -e "Info: Removing Improved Shapers Calibrations in printer.cfg file..."
          sed -i '/include Helper-Script\/improved-shapers\/improved-shapers\.cfg/d' "$PRINTER_CFG"
        else
          echo -e "Info: Improved Shapers Calibrations are already removed in printer.cfg file..."
        fi
        
        # 5. Dienste neu starten
        echo -e "Info: Restarting Moonraker service..."
        stop_moonraker
        start_moonraker
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Improved Shapers Calibrations have been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}
