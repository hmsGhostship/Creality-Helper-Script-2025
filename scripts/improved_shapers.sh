#!/bin/sh

set -e

# Global C13 path variables are dynamically loaded from your central paths.sh
# No redundant definitions needed here.

improved_shapers_message(){
  top_line
  title 'Improved Shapers Calibrations (C13 Edition)' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Installs advanced Shaper configurations into User-Space.       ${white}│"
  echo -e " │ ${cyan}Allows to test Belt Tension, separate X/Y resonances,          ${white}│"
  echo -e " │ ${cyan}and generate CSV tables natively on the C13 platform.          ${white}│"
  hr
  bottom_line
}

install_improved_shapers(){
  improved_shapers_message
  local yn
  while true; do
    install_msg "Improved Shapers Calibrations" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        
        # 1. VALIDATION: Check if required Klipper files exist on the C13 platform
        if [ ! -f "$PRINTER_CFG" ]; then
            error_msg "Error: printer.cfg was not found!"
            break
        fi

        echo -e "Info: Creating writeable configuration folders in User-Space..."
        # Utilizing your global variables from central paths.sh
        mkdir -p "$IMP_SHAPERS_FOLDER"/scripts
        
        # 2. FILE OPERATIONS: Copy macros and mathematical python scripts (NO system .so files!)
        echo -e "Info: Copying macro files locally..."
        cp -f "$IMP_SHAPERS_URL"/scripts/*.py "$IMP_SHAPERS_FOLDER"/scripts/ 2>/dev/null || true
        cp -f "$IMP_SHAPERS_URL"/improved-shapers.cfg "$IMP_SHAPERS_FOLDER"/improved-shapers.cfg

        # 3. STOCK MACRO DEACTIVATION: Comment out Creality's limited factory autotune macro
        if grep -q 'variable_autotune_shapers:' "$MACROS_CFG" 2>/dev/null; then
          echo -e "Info: Disabling factory AUTOTUNE_SHAPERS configuration..."
          sed -i 's/variable_autotune_shapers:/#&/' "$MACROS_CFG"
        fi

        # 4. ENFORCE INDEPENDENT X/Y CALIBRATION: Vital for your modified DXC printhead weight
        # We append the [resonance_tester] block safely to our own configuration file
        if grep -q "axis_x_use_y" "$IMP_SHAPERS_FOLDER/improved-shapers.cfg" 2>/dev/null; then
          echo -e "Info: Independent X/Y calibration is already configured in improved-shapers.cfg."
        else
          echo -e "Info: Adding independent X/Y tuning under [resonance_tester] in improved-shapers.cfg..."
          echo -e "\n[resonance_tester]\naxis_x_use_y: false" >> "$IMP_SHAPERS_FOLDER/improved-shapers.cfg"
        fi

        # 5. INJECT CONFIGURATION INCLUDE INTO PRINTER.CFG
        if grep -q "improved-shapers.cfg" "$PRINTER_CFG" ; then
          echo -e "Info: Include configuration is already present in printer.cfg."
        else
          echo -e "Info: Adding Improved Shapers include configuration to printer.cfg..."
          sed -i '/\[include printer_params\.cfg\]/a \[include Helper-Script/improved-shapers/improved-shapers\.cfg\]' "$PRINTER_CFG"
        fi
        
        # 6. SERVICE RESTART: Safely cycle Klipper using C13 framework commands
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        
        ok_msg "Improved Shapers (C13 Edition) has been installed successfully!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

remove_improved_shapers(){
  improved_shapers_message
  local yn
  while true; do
    remove_msg "Improved Shapers Calibrations" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        
        echo -e "Info: Removing Shaper configuration files..."
        rm -rf "$IMP_SHAPERS_FOLDER"
        
        # 1. Restore factory Autotune macros
        if grep -q "#variable_autotune_shapers:" "$MACROS_CFG" 2>/dev/null; then
          echo -e "Info: Restoring original factory AUTOTUNE_SHAPERS configuration..."
          sed -i 's/#variable_autotune_shapers:/variable_autotune_shapers:/' "$MACROS_CFG"
        fi
        
        # 2. Clean up the include line from printer.cfg
        if grep -q "improved-shapers.cfg" "$PRINTER_CFG" ; then
          echo -e "Info: Removing include statement from printer.cfg..."
          sed -i '/improved-shapers\.cfg/d' "$PRINTER_CFG"
        fi
        
        # 3. Service cycle to apply final removal
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        
        ok_msg "Improved Shapers (C13 Edition) has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}
