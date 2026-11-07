#!/bin/sh

set -e

function usb_camera_message(){
  top_line
  title 'USB Camera Support' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}This allows to use third-party camera from your printer's      ${white}│"
  echo -e " │ ${cyan}USB port.                                                      ${white}│"
  hr
  bottom_line
}

function builtin_camera_message(){
  top_line
  title 'Built-in Camera Fix' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}This allows to use the K1 2025 built-in camera with            ${white}│"
  echo -e " │ ${cyan}Fluidd and Mainsail through mjpg-streamer.                     ${white}│"
  hr
  bottom_line
}

function sync_timelapse_snapshot_url_k1_2025() {
  if [ ! -f "$MOONRAKER_CFG" ]; then
    return
  fi

  echo -e "Info: Syncing Timelapse snapshot URL with current camera topology..."
  
  # Wir prüfen, ob die Sektion [timelapse] überhaupt in der moonraker.conf existiert
  if grep -q "^\[timelapse\]" "$MOONRAKER_CFG"; then
    # 1. Wenn die USB-Kamera reell installiert ist, nutzen wir zwingend den USB-Port 8082
    if [ -f "$USB_CAMERA_FILE" ] || [ -f "$USB_CAMERA_LEGACY_FILE" ]; then
      echo -e " -> USB Camera active. Routing Timelapse to Port 8082..."
      sed -i '/^\[timelapse\]/,/^$/ { /^snapshoturl:/d }' "$MOONRAKER_CFG"
      sed -i '/^\[timelapse\]/a snapshoturl: http:\/\/localhost:8082\/?action=snapshot' "$MOONRAKER_CFG"
    
    # 2. Wenn KEINE USB-Cam da ist, fallen wir bedingungslos auf den Standard-Chassis/Werks-Port 8080 zurück!
    else
      echo -e " -> USB Camera inactive. Falling back to Port 8080 to prevent Moonraker crash..."
      sed -i '/^\[timelapse\]/,/^$/ { /^snapshoturl:/d }' "$MOONRAKER_CFG"
      sed -i '/^\[timelapse\]/a snapshoturl: http:\/\/localhost:8080\/?action=snapshot' "$MOONRAKER_CFG"
    fi
  fi
}

function configure_usb_camera_k1_2025(){
  local usb_dev

  if [ ! -f "$MOONRAKER_CFG" ]; then
    return
  fi

  usb_dev=$(v4l2-ctl --list-devices | grep -A1 usb | sed 's/^[[:space:]]*//g' | grep '^/dev' | grep -v '^/dev/video0$' | head -n 1)
  if [ -n "$usb_dev" ]; then
    echo -e "Info: Configuring USB camera in moonraker.conf..."
    sed -i '/^\[webcam usb\]/,/^$/d' "$MOONRAKER_CFG"
    cat >> "$MOONRAKER_CFG" <<EOF

[webcam usb]
enabled: True
location: printer
service: mjpegstreamer
target_fps: 15
target_fps_idle: 5
stream_url: /webcam3/?action=stream
snapshot_url: /webcam3/?action=snapshot
flip_horizontal: False
flip_vertical: False
rotation: 0
aspect_ratio: 16:9
EOF
  fi
}

function configure_builtin_camera_k1_2025(){
  if [ ! -f "$MOONRAKER_CFG" ]; then
    return
  fi

  echo -e "Info: Configuring built-in camera in moonraker.conf..."
  sed -i '/^\[webcam chassis\]/,/^$/d' "$MOONRAKER_CFG"
  cat >> "$MOONRAKER_CFG" <<EOF

[webcam chassis]
enabled: True
location: printer
service: mjpegstreamer
target_fps: 15
target_fps_idle: 5
stream_url: /webcam/?action=stream
snapshot_url: /webcam/?action=snapshot
flip_horizontal: False
flip_vertical: False
rotation: 0
aspect_ratio: 16:9
EOF
}

function ensure_mjpg_streamer_packages(){
  if [ "$model" = "K1_2025" ] || [ "$model" = "K1_2025_CFS-C" ]; then
    [ -x /usr/bin/mjpg_streamer ] && return 0
    error_msg "mjpg_streamer not found in firmware; this model requires it."
    return 1
  fi

  echo -e "Info: Updating Entware repository for mjpg-streamer packages..."
  "$ENTWARE_FILE" update || { error_msg "Could not refresh the package list."; return 1; }
  "$ENTWARE_FILE" install mjpg-streamer mjpg-streamer-input-http \
    mjpg-streamer-input-uvc mjpg-streamer-output-http mjpg-streamer-www
}

function disable_entware_builtin_mjpg_streamer(){
  if [ "$model" = "K1_2025" ] || [ "$model" = "K1_2025_CFS-C" ]; then
    return
  fi

  if [ -f /opt/etc/init.d/S96mjpg-streamer ]; then
    echo -e "Info: Disabling conflicting Entware mjpg-streamer service..."
    set +e
    /opt/etc/init.d/S96mjpg-streamer stop
    set -e
    mv /opt/etc/init.d/S96mjpg-streamer /opt/etc/init.d/disabled.S96mjpg-streamer
  fi
}

function restore_entware_builtin_mjpg_streamer(){
  if [ "$model" = "K1_2025" ] || [ "$model" = "K1_2025_CFS-C" ]; then
    return
  fi

  if [ -f /opt/etc/init.d/disabled.S96mjpg-streamer ]; then
    echo -e "Info: Restoring Entware mjpg-streamer service..."
    mv /opt/etc/init.d/disabled.S96mjpg-streamer /opt/etc/init.d/S96mjpg-streamer
  fi
}

function install_usb_camera(){
  usb_camera_message
  local yn
  while true; do
    install_msg "USB Camera Support" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Checking necessary packages..."
        if ! ensure_mjpg_streamer_packages; then
          error_msg "USB Camera Support has not been installed!"
          return 0
        fi
        if [ "$model" = "K1_2025" ] || [ "$model" = "K1_2025_CFS-C" ]; then
          k1_2025_migrate_entware_boot_if_needed
          disable_entware_builtin_mjpg_streamer
        fi
        echo -e "Info: Copying file..."
        set +e
        [ "$USB_CAMERA_FILE" != "$USB_CAMERA_LEGACY_FILE" ] && [ -f "$USB_CAMERA_LEGACY_FILE" ] && "$USB_CAMERA_LEGACY_FILE" stop
        set -e
        rm -f "$USB_CAMERA_LEGACY_FILE"
        if [ "$model" = "K1_2025" ] || [ "$model" = "K1_2025_CFS-C" ]; then
          cp "$USB_CAMERA_K1_2025_URL" "$USB_CAMERA_FILE"
        elif [ "$model" = "K1" ]; then
          cp "$USB_CAMERA_DUAL_URL" "$USB_CAMERA_FILE"
        else
          cp "$USB_CAMERA_SINGLE_URL" "$USB_CAMERA_FILE"
          echo
          echo -e " ${darkred}Be careful with the 1080p resolution!"
          echo -e " It takes more resources and timelapses are larger and take longer to convert.${white}"
          echo -e " 720p is a good compromise between quality and performance."
          echo -e " Make sure your camera is compatible with the chosen resolution."
          echo
          local resolution
          while true; do
            read -p " What camera resolution do you want to apply? (${yellow}480p${white}/${yellow}720p${white}/${yellow}1080p${white}): ${yellow}" resolution
            case "${resolution}" in
              480p|480P)
                echo -e "${white}"
                echo -e "Info: Applying change..."
                sed -i 's/1280x720/640x480/g' "$USB_CAMERA_FILE"
              break;;
              720p|720P)
                echo -e "${white}"
                echo -e "Info: Applying change..."
              break;;
              1080p|1080P)
                echo -e "${white}"
                echo -e "Info: Applying change..."
                sed -i 's/1280x720/1920x1080/g' "$USB_CAMERA_FILE"
              break;;
              *)
                error_msg "Please select a correct choice!";;
            esac
          done
        fi
        chmod 755 "$USB_CAMERA_FILE"
        if [ "$model" = "K1_2025" ] || [ "$model" = "K1_2025_CFS-C" ]; then
          configure_usb_camera_k1_2025
        fi

        # ====================================================================
        # AUTOMATISCHE RUNTIME-SYNC: PORT RETTEN & MAKRO-FLAGS AKTIVIEREN
        # ====================================================================
        sync_timelapse_snapshot_url_k1_2025
        if [ -f "/usr/data/printer_data/config/Helper-Script/camera-settings.cfg" ]; then
          echo -e "Info: Activating USB flag (video2) in camera-settings.cfg..."
          sed -i 's/variable_has_video2:[[:space:]]*False/variable_has_video2: True/g' "/usr/data/printer_data/config/Helper-Script/camera-settings.cfg"
        fi
        # ====================================================================

        if [ -f "$INITD_FOLDER"/S56moonraker_service ]; then
          stop_moonraker
          start_moonraker
        fi
        echo -e "Info: Starting service..."
        "$USB_CAMERA_FILE" start
        ok_msg "USB Camera Support has been installed successfully!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function install_builtin_camera(){
  builtin_camera_message
  echo
  echo -e " ${yellow}Warning: Built-in camera access through CrealityPrint"
  echo -e " will stop working while this fix is installed.${white}"
  echo
  local yn
  while true; do
    install_msg "Built-in Camera Fix" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Checking necessary packages..."
        if ! ensure_mjpg_streamer_packages; then
          error_msg "Built-in Camera Fix has not been installed!"
          return 0
        fi
        k1_2025_migrate_entware_boot_if_needed
        disable_entware_builtin_mjpg_streamer
        echo -e "Info: Copying file..."
        set +e
        [ -f "$BUILTIN_CAMERA_LEGACY_FILE" ] && "$BUILTIN_CAMERA_LEGACY_FILE" stop
        set -e
        rm -f "$BUILTIN_CAMERA_LEGACY_FILE"
        cp "$BUILTIN_CAMERA_K1_2025_URL" "$BUILTIN_CAMERA_FILE"
        chmod 755 "$BUILTIN_CAMERA_FILE"
        configure_builtin_camera_k1_2025

        # ====================================================================
        # AUTOMATISCHE RUNTIME-SYNC: PORT RETTEN & MAKRO-FLAGS AKTIVIEREN
        # ====================================================================
        sync_timelapse_snapshot_url_k1_2025
        if [ -f "/usr/data/printer_data/config/Helper-Script/camera-settings.cfg" ]; then
          echo -e "Info: Activating Chassis flag (video0) in camera-settings.cfg..."
          sed -i 's/variable_has_video0:[[:space:]]*False/variable_has_video0: True/g' "/usr/data/printer_data/config/Helper-Script/camera-settings.cfg"
        fi
        # ====================================================================
        
        if [ -f "$INITD_FOLDER"/S56moonraker_service ]; then
          stop_moonraker
          start_moonraker
        fi
        echo -e "Info: Starting service..."
        "$BUILTIN_CAMERA_FILE" start
        ok_msg "Built-in Camera Fix has been installed successfully!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_builtin_camera(){
  builtin_camera_message
  local yn
  while true; do
    remove_msg "Built-in Camera Fix" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Stopping service..."
        set +e
        [ -f "$BUILTIN_CAMERA_FILE" ] && "$BUILTIN_CAMERA_FILE" stop
        [ -f "$BUILTIN_CAMERA_LEGACY_FILE" ] && "$BUILTIN_CAMERA_LEGACY_FILE" stop
        set -e
        echo -e "Info: Removing file..."
        rm -f "$BUILTIN_CAMERA_FILE"
        rm -f "$BUILTIN_CAMERA_LEGACY_FILE"
        restore_entware_builtin_mjpg_streamer

        echo -e "Info: Restoring Creality factory camera sub-systems..."
        local src_dir="/usr/apps/etc/init.d"
        set +e
        for svc in CS50builtin_camera S50builtin_camera onyxp thirteenthp solusp; do
          if [ -f "${src_dir}/disabled.${svc}" ]; then
            mv "${src_dir}/disabled.${svc}" "${src_dir}/${svc}" 2>/dev/null
            "${src_dir}/${svc}" start >/dev/null 2>&1 || true
          fi
        done
        set -e

        if [ -f "$MOONRAKER_CFG" ]; then
          echo -e "Info: Removing built-in camera configuration in moonraker.conf file..."
          sed -i '/^\[webcam chassis\]/,/^$/d' "$MOONRAKER_CFG"
        fi

        echo -e "Info: Removing packages..."
        set +e
        if [ ! -f "$USB_CAMERA_FILE" ] && [ ! -f "$USB_CAMERA_LEGACY_FILE" ]; then
          "$ENTWARE_FILE" --autoremove remove mjpg-streamer-www mjpg-streamer-output-http mjpg-streamer-input-uvc mjpg-streamer-input-http mjpg-streamer
        fi
        set -e

        # ====================================================================
        # AUTOMATISCHE RUNTIME-SYNC: PORT RETTEN & MAKRO-FLAGS DEAKTIVIEREN
        # ====================================================================
        sync_timelapse_snapshot_url_k1_2025
        if [ -f "/usr/data/printer_data/config/Helper-Script/camera-settings.cfg" ]; then
          echo -e "Info: Deactivating Chassis flag (video0) in camera-settings.cfg..."
          sed -i 's/variable_has_video0:[[:space:]]*True/variable_has_video0: False/g' "/usr/data/printer_data/config/Helper-Script/camera-settings.cfg"
        fi
        # ====================================================================

        if [ -f "$INITD_FOLDER"/S56moonraker_service ]; then
          stop_moonraker
          start_moonraker
        fi
        ok_msg "Built-in Camera Fix has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_usb_camera(){
  usb_camera_message
  local yn
  while true; do
    remove_msg "USB Camera Support" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Stopping service..."
        set +e
        [ -f "$USB_CAMERA_FILE" ] && "$USB_CAMERA_FILE" stop
        [ -f "$USB_CAMERA_LEGACY_FILE" ] && "$USB_CAMERA_LEGACY_FILE" stop
        set -e
        
        # HIER DAS rm -f ENTFERNEN! Die Dateien müssen für Moonraker noch existieren!

        if { [ "$model" = "K1_2025" ] || [ "$model" = "K1_2025_CFS-C" ]; } && [ -f "$MOONRAKER_CFG" ]; then
          echo -e "Info: Removing USB Camera configurations in moonraker.conf file..."
          sed -i '/^\[webcam usb\]/,/^$/d' "$MOONRAKER_CFG"
        fi
        
        echo -e "Info: Removing packages..."
        set +e
        if { [ "$model" != "K1_2025" ] && [ "$model" != "K1_2025_CFS-C" ]; } || { [ ! -f "$BUILTIN_CAMERA_FILE" ] && [ ! -f "$BUILTIN_CAMERA_LEGACY_FILE" ]; }; then
          "$ENTWARE_FILE" --autoremove remove mjpg-streamer-www mjpg-streamer-output-http mjpg-streamer-input-uvc mjpg-streamer-input-http mjpg-streamer
        fi
        set -e
        
        # ====================================================================
        # AUTOMATISCHE RUNTIME-SYNC: PORT RETTEN & MAKRO-FLAGS DEAKTIVIEREN
        # ====================================================================
        sync_timelapse_snapshot_url_k1_2025
        if [ -f "/usr/data/printer_data/config/Helper-Script/camera-settings.cfg" ]; then
          echo -e "Info: Deactivating USB flag (video2) in camera-settings.cfg..."
          sed -i 's/variable_has_video2:[[:space:]]*True/variable_has_video2: False/g' "/usr/data/printer_data/config/Helper-Script/camera-settings.cfg"
        fi
        # ====================================================================

        # Moonraker stoppt jetzt sauber, weil die Datei auf der Platte noch da ist!
        if [ -f "$INITD_FOLDER"/S56moonraker_service ]; then
          stop_moonraker
          start_moonraker
        fi

        # ====================================================================
        # ERST JETZT GANZ AM ENDE WERDEN DIE DATEIEN RESTLOS GELÖSCHT!
        # ====================================================================
        echo -e "Info: Removing file..."
        rm -f "$USB_CAMERA_FILE"
        rm -f "$USB_CAMERA_LEGACY_FILE"
        # ====================================================================

        ok_msg "USB Camera Support has been removed successfully!"
        echo -e "   Please reboot your printer by using power switch on back!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}