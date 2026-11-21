#!/bin/sh
# Kernel mdev hotplug handler for USB cameras (/dev/video1 .. /dev/video9)

case "$MDEV" in
  video0|"") exit 0 ;;
  video[1-9]*) ;;
  *) exit 0 ;;
esac

LOCK_FILE="/tmp/usb_cam_hotplug.lock"
if [ -f "$LOCK_FILE" ]; then
  exit 0
fi
touch "$LOCK_FILE"

(
  sleep 2
  rm -f "$LOCK_FILE"

  # Detect active USB video device (skip video0 built-in camera)
  USB_DEV=""
  if command -v v4l2-ctl >/dev/null 2>&1; then
    USB_DEV="$(v4l2-ctl --list-devices 2>/dev/null | grep -A2 -i "usb" | sed "s/^[[:space:]]*//g" | grep "^/dev/video" | grep -v "^/dev/video0$" | head -n 1)"
  fi
  if [ -z "$USB_DEV" ]; then
    for d in /dev/video2 /dev/video1 /dev/video3 /dev/video4; do
      if [ -e "$d" ]; then
        USB_DEV="$d"
        break
      fi
    done
  fi

  # Case 1: Go2rtc configured for USB camera
  GO2RTC_CFG="/usr/data/go2rtc/go2rtc.yaml"
  if [ -f "$GO2RTC_CFG" ] && grep -q "^  usb:" "$GO2RTC_CFG" 2>/dev/null; then
    if [ -n "$USB_DEV" ]; then
      sed -i "s|/dev/video[1-9][0-9]*|${USB_DEV}|g" "$GO2RTC_CFG" 2>/dev/null || true
    fi
    for svc in /usr/apps/etc/init.d/S*go2rtc* /etc/init.d/S*go2rtc*; do
      if [ -x "$svc" ]; then
        "$svc" restart >/dev/null 2>&1 || true
      fi
    done
    exit 0
  fi

  # Case 2: Classic mjpg-streamer USB camera service
  for svc in /usr/apps/etc/init.d/S*usb*cam* /etc/init.d/S*usb*cam*; do
    if [ -x "$svc" ]; then
      if [ -n "$USB_DEV" ]; then
        sed -i "s|/dev/video[1-9][0-9]*|${USB_DEV}|g" "$svc" 2>/dev/null || true
      fi
      "$svc" restart >/dev/null 2>&1 || true
    fi
  done
) >/dev/null 2>&1 &
