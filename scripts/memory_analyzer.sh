#!/bin/sh

set -e

function box_row() {
  local plain="$1"
  local colored="$2"
  local spaces
  spaces=$(awk -v s="$plain" 'BEGIN { p = 63 - length(s); if (p < 0) p = 0; printf "%" p "s", "" }')
  printf " │ %b%s${white}│\n" "$colored" "$spaces"
}

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

  box_row "RAM Overview:" "${cyan}RAM Overview:${white}"
  box_row " Total: ${mem_total} MB   |   Available: ${mem_avail} MB" \
          " Total: ${yellow}${mem_total} MB${white}   |   Available: ${green}${mem_avail} MB${white}"
  box_row " Free:  ${mem_free} MB     |   Cached:    ${mem_cached} MB" \
          " Free:  ${mem_free} MB     |   Cached:    ${mem_cached} MB"
  hr

  box_row "Top 12 RAM Consumers (Physical VmRSS):" "${cyan}Top 12 RAM Consumers (Physical VmRSS):${white}"
  box_row " RAM       PID     PROCESS" "${darkgrey} RAM       PID     PROCESS${white}"

  local p pid rss rss_mb cmd label line_plain line_col
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
        *moonraker_octoeverywhere*|*octoeverywhere*) label="octoeverywhere (Python)" ;;
        *mobileraker*) label="mobileraker (Python)" ;;
        *octoapp*) label="octoapp (Python)" ;;
        *obico*) label="moonraker-obico (Python)" ;;
        *"-m moonraker"*|*moonraker.py*) label="moonraker (Python)" ;;
        *klippy.py*) label="klippy (Klipper)" ;;
        *nexusp*) label="nexusp (Creality :7125)" ;;
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
    line_plain=$(printf " %-9s %-7s %.43s" "$mb" "$p_id" "$p_cmd")
    line_col=$(printf " ${yellow}%-9s${white} %-7s %.43s" "$mb" "$p_id" "$p_cmd")
    box_row "$line_plain" "$line_col"
  done

  hr
  local disk_info
  disk_info=$(df -h /usr/data 2>/dev/null | awk 'NR==2 {printf "Used: %s / %s (%s) | Free: %s", $3, $2, $5, $4}')
  box_row "Storage (/usr/data) - ${disk_info}" "${cyan}Storage (/usr/data)${white} - ${disk_info}"
  box_row " SIZE       FOLDER" "${darkgrey} SIZE       FOLDER${white}"

  du -sk /usr/data/* /usr/data/printer_data/* 2>/dev/null | grep -v '[[:space:]]/usr/data/printer_data$' | sort -nr | head -n 8 | awk '{
    kb=$1; $1=""; sub(/^ /, "");
    if (kb >= 1048576) sz=sprintf("%.1f GB", kb/1048576);
    else if (kb >= 1024) sz=sprintf("%.1f MB", kb/1024);
    else sz=sprintf("%d KB", kb);
    printf "%-10s|%s\n", sz, $0
  }' | while IFS='|' read -r sz path; do
    line_plain=$(printf " %-10s %.49s" "$sz" "$path")
    line_col=$(printf " ${yellow}%-10s${white} %.49s" "$sz" "$path")
    box_row "$line_plain" "$line_col"
  done

  inner_line
  hr
  bottom_line
  echo
  read -p " ${white}Press ${yellow}Enter${white} to return to Tools Menu... " _
}
