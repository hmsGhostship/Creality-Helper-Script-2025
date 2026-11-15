#!/bin/sh

set -e

function show_memory_consumers(){
  clear
  top_line
  title 'Memory & Storage Consumers' "${yellow}"
  inner_line
  hr

  local mem_total mem_avail mem_free mem_cached
  mem_total=$(awk '/^MemTotal:/ {printf "%.1f", $2/1024}' /proc/meminfo 2>/dev/null)
  mem_avail=$(awk '/^MemAvailable:/ {printf "%.1f", $2/1024}' /proc/meminfo 2>/dev/null)
  mem_free=$(awk '/^MemFree:/ {printf "%.1f", $2/1024}' /proc/meminfo 2>/dev/null)
  mem_cached=$(awk '/^Cached:/ {printf "%.1f", $2/1024}' /proc/meminfo 2>/dev/null)

  echo -e " ${cyan}RAM Overview:${white}"
  echo -e "  Total: ${yellow}${mem_total} MB${white}  |  Available: ${green}${mem_avail} MB${white}"
  echo -e "  Free:  ${mem_free} MB   |  Cached:    ${mem_cached} MB"
  hr

  echo -e " ${cyan}Top 12 RAM Consumers (Physical VmRSS):${white}"
  printf "  ${darkgrey}%-9s %-7s %s${white}\n" "RAM" "PID" "PROCESS"

  local p pid rss rss_mb cmd label
  for p in /proc/[0-9]*; do
    [ -r "$p/status" ] || continue
    pid="${p#/proc/}"
    rss=$(awk '/^VmRSS:/ {print $2}' "$p/status" 2>/dev/null)
    [ -n "$rss" ] && [ "$rss" -gt 0 ] 2>/dev/null || continue
    cmd=$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null | sed 's/[[:space:]]*$//')
    if [ -z "$cmd" ]; then
      label=$(awk '/^Name:/ {print "["$2"]"}' "$p/status" 2>/dev/null)
    else
      case "$cmd" in
        *moonraker.py*|*"-m moonraker"*) label="moonraker (Python)" ;;
        *klippy.py*) label="klippy (Klipper)" ;;
        *octoeverywhere*) label="octoeverywhere (Python)" ;;
        *mobileraker*) label="mobileraker (Python)" ;;
        *octoapp*) label="octoapp (Python)" ;;
        *obico*) label="moonraker-obico (Python)" ;;
        *guppyflo*) label="guppyflo" ;;
        *go2rtc*) label="go2rtc" ;;
        *mjpg_streamer*video2*) label="mjpg_streamer (USB /dev/video2)" ;;
        *mjpg_streamer*video0*) label="mjpg_streamer (Chassis /dev/video0)" ;;
        *mjpg_streamer*) label="mjpg_streamer" ;;
        *)
          label=$(echo "$cmd" | awk '{
            sub(/^.*\//, "", $1);
            if ($1 == "sh" || $1 == "python" || $1 == "python3") {
              sub(/^.*\//, "", $2);
              print $1 " " $2
            } else {
              print $1
            }
          }')
          ;;
      esac
    fi
    rss_mb=$(awk -v r="$rss" 'BEGIN {printf "%5.1f MB", r/1024}')
    printf "%09d|%s|%-6s|%s\n" "$rss" "$rss_mb" "$pid" "$label"
  done | sort -r | head -n 12 | while IFS='|' read -r _ mb p_id p_cmd; do
    printf "  ${yellow}%-9s${white} %-7s %.42s\n" "$mb" "$p_id" "$p_cmd"
  done

  hr
  echo -e " ${cyan}Storage Usage (/usr/data):${white}"
  df -h /usr/data 2>/dev/null | awk 'NR==2 {printf "  Used: %s / %s (%s)  |  Free: %s\n", $3, $2, $5, $4}'
  echo
  printf "  ${darkgrey}%-10s %s${white}\n" "SIZE" "FOLDER"
  du -sk /usr/data/* /usr/data/printer_data/* 2>/dev/null | sort -nr | head -n 8 | awk '{
    kb=$1; $1=""; sub(/^ /, "");
    if (kb >= 1048576) sz=sprintf("%.1f GB", kb/1048576);
    else if (kb >= 1024) sz=sprintf("%.1f MB", kb/1024);
    else sz=sprintf("%d KB", kb);
    printf "  %-10s %.48s\n", sz, $0
  }'
  inner_line
  hr
  bottom_line
  read -p " ${white}Press ${yellow}Enter${white} to return to Tools Menu... " _
}
