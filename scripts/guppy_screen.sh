#!/bin/sh

set -e

function guppyscreen_message(){
  top_line
  title 'GuppyScreen (K1C 2025/2026 Edition)' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}GuppyScreen is a highly optimized, custom touchscreen GUI    ${white}│"
  echo -e " │ ${cyan}specifically built for the X2600 MIPS architecture.          ${white}│"
  echo -e " │ ${cyan}It replaces the stock Creality screen interface layout.       ${white}│"
  hr
  bottom_line
}

#!/bin/sh

set -e

function guppyscreen_message(){
  top_line
  title 'GuppyScreen (K1C 2025/2026 Edition)' "${yellow}"
  inner_line
  hr
  echo -e " │ GuppyScreen is a highly optimized, custom touchscreen GUI    │"
  echo -e " │ specifically built for the X2600 MIPS architecture.          │"
  echo -e " │ It replaces the stock Creality screen interface layout.       │"
  hr
  bottom_line
}

function install_guppyscreen(){
  guppyscreen_message
  local yn
  while true; do
    install_msg "GuppyScreen (X2600 Native Build)" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        
        # 1. HARDWARE- & FIRMWARE ARCHITECTURE SAFETY CHECK
        echo -e "Info: Running hardware environment validation..."
        if [ ! -c "/dev/fb1" ] || [ ! -e "/dev/input/event1" ]; then
          error_msg "Hardware check failed! /dev/fb1 or touchscreen event missing."
          echo -e " This build is strictly for K1C 2025/2026 X2600 architecture!"
          return 1
        fi

        # 2. CLEAN UP ANY PREVIOUS INSTANCES SAFELY
        if [ -f "$INITD_FOLDER/S57guppy_service" ]; then
          echo -e "Info: Stopping existing GuppyScreen service..."
          "$INITD_FOLDER/S57guppy_service" stop > /dev/null 2>&1 || true
          rm -f "$INITD_FOLDER/S57guppy_service"
        fi

        # Preserve existing configuration json if present in application folder
        if [ -f "$GUPPY_SCREEN_FOLDER/guppyconfig.json" ]; then
          echo -e "Info: Backing up existing guppyconfig.json..."
          cp "$GUPPY_SCREEN_FOLDER/guppyconfig.json" "$USR_DATA/guppyconfig.json"
        fi

        # 3. CLONE AND EXTRACT SNORRITXD FORK REPOSITORY
        echo -e "Info: Downloading specialized K1C-2025 GuppyScreen package..."
        rm -rf "$GUPPY_SCREEN_SOURCE"
        git clone --depth 1 "$GUPPY_SCREEN_URL" "$GUPPY_SCREEN_SOURCE"

        echo -e "Info: Installing specialized binaries and assets..."
        rm -rf "$GUPPY_SCREEN_FOLDER"
        mkdir -p "$GUPPY_SCREEN_FOLDER"
        
        # Copies the application data from source path to active folder
        cp -rf "$GUPPY_SCREEN_SOURCE/guppyscreen/"* "$GUPPY_SCREEN_FOLDER/"
        
        # Restore configuration backup if it existed
        if [ -f "$USR_DATA/guppyconfig.json" ]; then
          mv "$USR_DATA/guppyconfig.json" "$GUPPY_SCREEN_FOLDER/guppyconfig.json"
        fi

        # 4. DISABLE THE STOCK CREALITY TOUCHSCREEN APPS SAFELY (No permanent delete!)
        if [ -f "$INITD_FOLDER/CS60gui_service" ]; then
          echo -e "Info: Disabling factory Creality GUI service safely..."
          "$INITD_FOLDER/CS60gui_service" stop > /dev/null 2>&1 || true
          mv "$INITD_FOLDER/CS60gui_service" "$INITD_FOLDER/disabled.CS60gui_service"
        fi

        # 5. INSTALL THE NEW BOOT INIT SERVICE FROM SOURCE
        echo -e "Info: Injecting native S57guppy_service boot sequence..."
        cp -f "$GUPPY_SCREEN_SOURCE/init/S57guppy_service" "$INITD_FOLDER/S57guppy_service"
        chmod +x "$INITD_FOLDER/S57guppy_service"

        # 6. START GUPPYSCREEN LIVE RIGHT NOW
        echo -e "Info: Initializing GuppyScreen execution..."
        "$INITD_FOLDER/S57guppy_service" start > /dev/null 2>&1 || true

        ok_msg "GuppyScreen has been successfully installed and initialized on your K1C display!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_guppyscreen(){
  guppyscreen_message
  local yn
  while true; do
    remove_msg "GuppyScreen" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        
        # 1. STOP AND REMOVE GUPPYSCREEN SERVICE
        if [ -f "$INITD_FOLDER/S57guppy_service" ]; then
          echo -e "Info: Stopping GuppyScreen background processes..."
          "$INITD_FOLDER/S57guppy_service" stop > /dev/null 2>&1 || true
          rm -f "$INITD_FOLDER/S57guppy_service"
        fi
        killall guppyscreen > /dev/null 2>&1 || true

        # 2. PURGE THE INSTALLED FILES VIA NEW VARIABLES
        echo -e "Info: Removing GuppyScreen application directory and source repository..."
        rm -rf "$GUPPY_SCREEN_FOLDER"
        rm -rf "$GUPPY_SCREEN_SOURCE"

        # 3. RESTORE THE STOCK CREALITY GUI LAUNCHER UNTOUCHED
        if [ -f "$INITD_FOLDER/disabled.CS60gui_service" ]; then
          echo -e "Info: Restoring original stock Creality GUI service..."
          mv "$INITD_FOLDER/disabled.CS60gui_service" "$INITD_FOLDER/CS60gui_service"
          echo -e "Info: Launching factory Creality touchscreen layout..."
          "$INITD_FOLDER/CS60gui_service" start > /dev/null 2>&1 || true
        else
          echo -e "Warning: Stock Creality GUI service template not found in boot directory!"
        fi

        ok_msg "GuppyScreen removed completely. Factory Creality UI has been successfully restored!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}