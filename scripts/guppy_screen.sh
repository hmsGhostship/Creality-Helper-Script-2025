#!/bin/sh

set -e

function guppyscreen_message(){
  top_line
  title 'GuppyScreen (K1C 2025/2026 Edition)' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}GuppyScreen is a highly optimized, custom touchscreen GUI      ${white}│"
  echo -e " │ ${cyan}specifically built for the X2600 MIPS architecture.            ${white}│"
  echo -e " │ ${cyan}It replaces the stock Creality screen interface layout.        ${white}│"
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

        # 1. Echten Moonraker-Port dynamisch ermitteln (7126 mit CFS-C/nexusp, 7125 ohne nexusp)
        local real_port=7126
        if [ -f "$MOONRAKER_CFG" ]; then
          local detected_port=$(grep -A 5 "^\[server\]" "$MOONRAKER_CFG" | grep "^port:" | awk '{print $2}' | tr -d '\r')
          if [ -n "$detected_port" ]; then
            real_port=$detected_port
          fi
        fi
        echo -e "Info: Detected Moonraker port: $real_port"

        # 2. Repository klonen oder aktualisieren
        echo -e "Info: Downloading specialized K1C-2025 GuppyScreen package..."
        git config --global http.sslVerify false
        if [ -d "$GUPPY_SCREEN_SOURCE/.git" ]; then
          cd "$GUPPY_SCREEN_SOURCE"
          git reset --hard >/dev/null 2>&1 || true
          git pull
        else
          rm -rf "$GUPPY_SCREEN_SOURCE"
          git clone --depth 1 "$GUPPY_SCREEN_URL" "$GUPPY_SCREEN_SOURCE"
        fi

        # 3. Touchscreen-Check (goodix-ts & Hua Que) sowie Port im Source-Paket anpassen
        chmod +x "$GUPPY_SCREEN_SOURCE/installer/install.sh"
        sed -i 's/\[ "$TOUCH_NAME" = "goodix-ts" \]/[ "$TOUCH_NAME" = "goodix-ts" ] || [ "$TOUCH_NAME" = "Hua Que: Hua Que" ]/' "$GUPPY_SCREEN_SOURCE/installer/install.sh"
        if [ "$real_port" != "7125" ] && [ -f "$GUPPY_SCREEN_SOURCE/init/S57guppy_service" ]; then
          sed -i "s/7125/$real_port/g" "$GUPPY_SCREEN_SOURCE/init/S57guppy_service"
        fi

        # 4. Den offiziellen Fail-Safe-Installer aus dem Repository ausführen
        echo -e "Info: Running native fail-safe installer..."
        "$GUPPY_SCREEN_SOURCE/installer/install.sh"

        # 5. Nach dem ersten Start angelegte guppyconfig.json sicherstellen & Port synchronisieren
        if [ ! -f "$GUPPY_SCREEN_FOLDER/guppyconfig.json" ] && [ -f "$USR_DATA/guppyconfig.json" ]; then
          mv "$USR_DATA/guppyconfig.json" "$GUPPY_SCREEN_FOLDER/guppyconfig.json"
        fi
        sleep 2
        if [ "$real_port" != "7125" ] && [ -f "$GUPPY_SCREEN_FOLDER/guppyconfig.json" ]; then
          if grep -q "7125" "$GUPPY_SCREEN_FOLDER/guppyconfig.json"; then
            echo -e "Info: Updating Moonraker port in guppyconfig.json to $real_port..."
            sed -i "s/7125/$real_port/g" "$GUPPY_SCREEN_FOLDER/guppyconfig.json"
            "$INITD_FOLDER/S57guppy_service" restart >/dev/null 2>&1 || true
          fi
        fi

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

        if [ -f "$GUPPY_SCREEN_SOURCE/uninstall.sh" ]; then
          echo -e "Info: Running native uninstaller..."
          chmod +x "$GUPPY_SCREEN_SOURCE/uninstall.sh"
          sed -i 's/\[ "$TOUCH_NAME" = "goodix-ts" \]/[ "$TOUCH_NAME" = "goodix-ts" ] || [ "$TOUCH_NAME" = "Hua Que: Hua Que" ]/' "$GUPPY_SCREEN_SOURCE/uninstall.sh"
          "$GUPPY_SCREEN_SOURCE/uninstall.sh" || true
        fi

        if [ -f "$INITD_FOLDER/S57guppy_service" ]; then
          echo -e "Info: Stopping GuppyScreen background processes..."
          "$INITD_FOLDER/S57guppy_service" stop > /dev/null 2>&1 || true
          rm -f "$INITD_FOLDER/S57guppy_service"
        fi
        killall guppyscreen > /dev/null 2>&1 || true

        echo -e "Info: Removing GuppyScreen application directory and source repository..."
        rm -rf "$GUPPY_SCREEN_FOLDER"
        rm -rf "$GUPPY_SCREEN_SOURCE"
        rm -rf "/usr/data/guppyscreen-k1c-backup"

        if [ -f "$INITD_FOLDER/disabled.CS60gui_service" ]; then
          echo -e "Info: Restoring original stock Creality GUI service..."
          mv "$INITD_FOLDER/disabled.CS60gui_service" "$INITD_FOLDER/CS60gui_service"
          echo -e "Info: Launching factory Creality touchscreen layout..."
          "$INITD_FOLDER/CS60gui_service" start > /dev/null 2>&1 || true
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
