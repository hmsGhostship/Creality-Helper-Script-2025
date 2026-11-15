#!/bin/sh

set -e

function go2rtc_message(){
  top_line
  title 'Go2rtc' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Go2rtc is a versatile camera streaming application.            ${white}│"
  echo -e " │ ${cyan}On the K1 2025, it can stream either the built-in chassis      ${white}│"
  echo -e " │ ${cyan}camera (/dev/video0) or a third-party USB camera (/dev/video2).${white}│"
  hr
  bottom_line
}

function get_go2rtc_mode_k1_2025(){
  if [ -f "$GO2RTC_CONFIG_FILE" ] && grep -q '^  usb:' "$GO2RTC_CONFIG_FILE" 2>/dev/null; then
    echo "usb"
  elif [ -f "$GO2RTC_CONFIG_FILE" ] && grep -q '^  chassis:' "$GO2RTC_CONFIG_FILE" 2>/dev/null; then
    echo "chassis"
  else
    echo ""
  fi
}

function configure_go2rtc_k1_2025(){
  local cam_src="${1:-chassis}"
  local nginx_conf
  local P="http"
  local S="://"
  local TARGET="${P}${S}127.0.0.1:1984/;"

  if [ -f "$MOONRAKER_CFG" ]; then
    sed -i "/^\[webcam ${cam_src}\]/,/^$/d" "$MOONRAKER_CFG"
    echo -e "Info: Adding K1 2025 ${cam_src} camera (Go2rtc) to moonraker.conf..."
    cat >> "$MOONRAKER_CFG" <<EOF

[webcam ${cam_src}]
enabled: True
location: printer
service: mjpegstreamer
target_fps: 15
target_fps_idle: 5
stream_url: /go2rtc/api/stream.mjpeg?src=${cam_src}
snapshot_url: /go2rtc/api/frame.jpeg?src=${cam_src}
flip_horizontal: False
flip_vertical: False
rotation: 0
aspect_ratio: 16:9
EOF
  fi

  for nginx_conf in "$NGINX_FOLDER"/nginx/nginx.conf /etc/nginx/nginx.conf; do
    if [ -f "$nginx_conf" ]; then
      if ! grep -q 'location /go2rtc/' "$nginx_conf"; then
        echo -e "Info: Adding Nginx proxy for go2rtc in $nginx_conf..."
        sed -i "/location ~ \^\/(printer|api|access|machine|server)\/ {/i\\
        location /go2rtc/ {\\
            proxy_pass ${TARGET}\\
            proxy_http_version 1.1;\\
            proxy_set_header Host \$http_host;\\
            proxy_set_header X-Real-IP \$remote_addr;\\
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\\
            proxy_buffering off;\\
        }\\
\\
" "$nginx_conf"
      fi
    fi
  done
}

function install_go2rtc(){
  go2rtc_message
  local yn
  while true; do
    install_msg "Go2rtc" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        local cam_choice cam_src="chassis" video_dev="/dev/video0"
        echo -e " Which camera should ${green}Go2rtc${white} stream?"
        echo -e "  ${yellow}1)${white} Built-in Chassis Camera (/dev/video0 - replaces Built-in Fix & Creality WebRTC)"
        echo -e "  ${yellow}2)${white} USB Camera (/dev/video2 - replaces USB Camera Support, keeps Creality Print)"
        echo
        while true; do
          read -p " ${white}Select camera (${yellow}1${white}/${yellow}2${white}): ${yellow}" cam_choice
          echo -e "${white}"
          case "${cam_choice}" in
            1)
              if [ -f "$BUILTIN_CAMERA_FILE" ] || [ -f "$BUILTIN_CAMERA_LEGACY_FILE" ]; then
                error_msg "Built-in Camera Fix is active! Please remove it first to avoid a /dev/video0 conflict."
                return
              fi
              if [ -f "$CREALITY_CLOUD_WEBRTC_SERVICE" ] || [ -f "$CREALITY_LOCAL_WEBRTC_SERVICE" ]; then
                error_msg "Creality WebRTC services are still active! Please disable Creality Stock Services first."
                return
              fi
              cam_src="chassis"
              video_dev="/dev/video0"
              break;;
            2)
              if [ -f "$USB_CAMERA_FILE" ] || [ -f "$USB_CAMERA_LEGACY_FILE" ]; then
                error_msg "USB Camera Support (mjpg-streamer) is active! Please remove it first to avoid a USB camera conflict."
                return
              fi
              video_dev=$(v4l2-ctl --list-devices 2>/dev/null | grep -A1 -i usb | sed 's/^[[:space:]]*//g' | grep '^/dev/video' | grep -v '^/dev/video0$' | head -n 1)
              if [ -z "$video_dev" ]; then
                error_msg "No third-party USB camera found!"
                return
              fi
              cam_src="usb"
              break;;
            *)
              error_msg "Please select a correct choice! (1 or 2)";;
          esac
        done

        if ! check_ram_requirement "Go2rtc" 35; then return; fi
        if [ ! -x /opt/bin/ffmpeg ]; then
          if [ -x "$ENTWARE_FILE" ]; then
            echo -e "Info: Installing ffmpeg via Entware..."
            "$ENTWARE_FILE" update && "$ENTWARE_FILE" install ffmpeg
          else
            error_msg "Entware and ffmpeg are needed for Go2rtc, please install Entware first!"
            return
          fi
        fi

        echo -e "Info: Downloading go2rtc..."
        mkdir -p "$(dirname "$GO2RTC_FILE")"
        $HS_FILES/fixes/curl -L "$GO2RTC_URL" -o "$GO2RTC_FILE"
        chmod +x "$GO2RTC_FILE"

        echo -e "Info: Copying service file..."
        if [ ! -f "$GO2RTC_SERVICE_FILE" ]; then
          cp "$GO2RTC_SERVICE_URL" "$GO2RTC_SERVICE_FILE"
          chmod +x "$GO2RTC_SERVICE_FILE"
        fi

        echo -e "Info: Writing Go2rtc config for ${cam_src} (${video_dev})..."
        mkdir -p "$(dirname "$GO2RTC_CONFIG_FILE")"
        cat > "$GO2RTC_CONFIG_FILE" <<EOF
api:
  listen: ":1984"
  origin: "*"

streams:
  ${cam_src}: "exec:/opt/bin/ffmpeg -f v4l2 -input_format mjpeg -video_size 1280x720 -framerate 15 -i ${video_dev} -c:v copy -f rtsp {output}"
EOF

        if { [ "$model" = "K1_2025" ] || [ "$model" = "K1_2025_CFS-C" ]; } && [ -d "$MOONRAKER_FOLDER" ]; then
          configure_go2rtc_k1_2025 "$cam_src"
          stop_moonraker
          start_moonraker
          restart_nginx
        fi

        echo -e "Info: Starting Go2rtc service..."
        start_go2rtc
        type sync_timelapse_snapshot_url_k1_2025 >/dev/null 2>&1 && sync_timelapse_snapshot_url_k1_2025
        type sync_octoeverywhere_camera_k1_2025 >/dev/null 2>&1 && sync_octoeverywhere_camera_k1_2025

        ok_msg "Go2rtc (${cam_src}) has been installed successfully!"
        ok_msg "Stream URL: /go2rtc/api/stream.mjpeg?src=${cam_src}"
        ok_msg "Snapshot URL: /go2rtc/api/frame.jpeg?src=${cam_src}"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_go2rtc(){
  go2rtc_message
  local yn
  while true; do
    remove_msg "Go2rtc" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        local cam_src
        cam_src="$(get_go2rtc_mode_k1_2025)"
        echo -e "Info: Stopping Go2rtc service..."
        stop_go2rtc
        echo -e "Info: Removing files..."
        rm -f "$GO2RTC_SERVICE_FILE" "$GO2RTC_CONFIG_FILE" "$GO2RTC_FILE"
        if [ -f "$MOONRAKER_CFG" ]; then
          if [ -n "$cam_src" ] && grep -A 8 "^\[webcam ${cam_src}\]" "$MOONRAKER_CFG" | grep -q '/go2rtc/'; then
            echo -e "Info: Removing Go2rtc ${cam_src} webcam from moonraker.conf..."
            sed -i "/^\[webcam ${cam_src}\]/,/^$/d" "$MOONRAKER_CFG"
          else
            sed -i '/^\[webcam chassis\]/,/^$/{ /\/go2rtc\//d }' "$MOONRAKER_CFG"
          fi
          stop_moonraker
          start_moonraker
        fi
        type sync_timelapse_snapshot_url_k1_2025 >/dev/null 2>&1 && sync_timelapse_snapshot_url_k1_2025
        type sync_octoeverywhere_camera_k1_2025 >/dev/null 2>&1 && sync_octoeverywhere_camera_k1_2025
        ok_msg "Go2rtc has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}
