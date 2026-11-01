#!/bin/sh

set -e

function kamp_message(){
  top_line
  title 'Klipper Adaptive Meshing & Purging' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}KAMP is an extension that allows to generate a mesh and        ${white}│"
  echo -e " │ ${cyan}purge line only in the area of the bed used by the objects     ${white}│"
  echo -e " │ ${cyan}being printed. When used, the method will automatically        ${white}│"
  echo -e " │ ${cyan}adjust the mesh parameters based on the area occupied by the   ${white}│"
  echo -e " │ ${cyan}defined print objects.                                         ${white}│"
  hr
  bottom_line
}

function install_kamp(){
  kamp_message
  local yn
  while true; do
    install_msg "Klipper Adaptive Meshing & Purging" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        if [ -d "$HS_CONFIG_FOLDER"/KAMP ]; then
          rm -rf "$HS_CONFIG_FOLDER"/KAMP
        fi
        echo -e "Info: Creating KAMP directory..."
        mkdir -p "$HS_CONFIG_FOLDER"/KAMP
        echo -e "Info: Linking local KAMP components..."
        ln -sf "$KAMP_URL"/Adaptive_Meshing.cfg "$KAMP_FOLDER"/Adaptive_Meshing.cfg
        ln -sf "$KAMP_URL"/Line_Purge.cfg "$KAMP_FOLDER"/Line_Purge.cfg
        ln -sf "$KAMP_URL"/Smart_Park.cfg "$KAMP_FOLDER"/Smart_Park.cfg
        ln -sf "$KAMP_URL"/kamp_only.cfg "$KAMP_FOLDER"/kamp_only.cfg
        cp "$KAMP_URL"/KAMP_Settings.cfg "$KAMP_FOLDER"/KAMP_Settings.cfg
        if grep -q "include Helper-Script/KAMP/KAMP_Settings" "$PRINTER_CFG" ; then
          echo -e "Info: KAMP configurations are already enabled in printer.cfg file..."
        else
          echo -e "Info: Adding KAMP configurations in printer.cfg file..."
          echo -e "\n[include Helper-Script/KAMP/KAMP_Settings.cfg]" >> "$PRINTER_CFG"
        fi
        if grep -q "adaptive_margin:" "$PRINTER_CFG" ; then
          echo -e "Info: Klipper Native Adaptive Engine is already configured..."
        else
          echo -e "Info: Injecting Native Adaptive parameters to ensure compatibility..."
          sed -i '/\[bed_mesh\]/a \adaptive_margin: 5' "$PRINTER_CFG"
        fi
        if [ -f "$KAMP_FOLDER"/KAMP_Settings.cfg ]; then
          sed -i 's/#\[include \.\/KAMP\/Adaptive_Meshing\.cfg\]/\[include \.\/KAMP\/Adaptive_Meshing\.cfg\]/' "$KAMP_FOLDER"/KAMP_Settings.cfg
        fi
        sed -i '/kamp_only\.cfg/d' "$PRINTER_CFG"
        if [ -f "$KLIPPER_CONFIG_FOLDER/calib_tool_box.cfg" ]; then
          echo -e "Info: hmsGhostship Toolbox erkannt! Toolbox hat absolute Priorität."
          echo -e "Info: KAMP-Only Interface wird übersprungen (Deine Toolbox übernimmt alles)."
        else
          echo -e "Info: Keine Toolbox gefunden. Aktiviere KAMP-Only Interface..."
          echo -e "[include Helper-Script/KAMP/kamp_only.cfg]" >> "$PRINTER_CFG"
        fi
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Klipper Adaptive Meshing & Purging has been installed successfully!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_kamp(){
  kamp_message
  local yn
  while true; do
    remove_msg "Klipper Adaptive Meshing & Purging" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Removing KAMP files..." 
        rm -rf "$HS_CONFIG_FOLDER"/KAMP
        
        echo -e "Info: Cleaning printer.cfg..."
        sed -i '/include Helper-Script\/KAMP\/KAMP_Settings\.cfg/d' "$PRINTER_CFG"
        sed -i '/kamp_only\.cfg/d' "$PRINTER_CFG"
        sed -i '/adaptive_margin: 5/d' "$PRINTER_CFG"
        echo -e "Info: Resetting global calibration variable..."
        if [ -f "/usr/data/printer_data/config/variables.cfg" ]; then
          sed -i 's/orca_calib_state = 2/orca_calib_state = 0/g' /usr/data/printer_data/config/variables.cfg
        fi
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Klipper Adaptive Meshing & Purging has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}