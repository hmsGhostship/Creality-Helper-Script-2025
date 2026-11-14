#!/bin/sh

set -e

SOURCE_JS="${HS_FILES}/cfs_mainsail/static/mainsail-panel.js"
SOURCE_JSON="${HS_FILES}/cfs_mainsail/cfs-overrides.json"
SOURCE_PY="${HS_FILES}/cfs_mainsail/klipper/cfs_material_db.py"

TARGET_JSON="${HS_CONFIG_FOLDER}/cfs-overrides.json"

cfs_message() {
  top_line
  title 'CFS-C Multi-Material Suite Setup:' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}This patch installs the custom CFS-C panel interface directly  ${white}│"
  echo -e " │ ${cyan}into your installed web frontends (Mainsail / Fluidd) and      ${white}│"
  echo -e " │ ${cyan}injects the required 2025 Klipper hardware extension.          ${white}│"
  hr
  bottom_line
}

apply_cfs_to_frontend() {
  local FRONTEND="$1"
  local TARGET_DIR="$2"

  if [ -f "${TARGET_DIR}/index.html" ]; then
    echo -e "Info: Installing CFS-C Panel into ${FRONTEND}..."
    cp -f "$SOURCE_JS" "${TARGET_DIR}/k1c-cfs-panel.js"
    chmod 644 "${TARGET_DIR}/k1c-cfs-panel.js"

    sed -i '/<!-- K1C_CFS_INJECT_START -->/,/<!-- K1C_CFS_INJECT_END -->/d' "${TARGET_DIR}/index.html"
    local LOADER_BLOCK='<!-- K1C_CFS_INJECT_START -->\n<script>\nwindow.K1C_CFS_WS_URL = "ws://" + window.location.hostname + ":9999";\nif (!window.__k1c_cfs_loader_loaded) {\n  window.__k1c_cfs_loader_loaded = true;\n  const script = document.createElement("script");\n  script.src = "/k1c-cfs-panel.js?ts=" + Date.now();\n  document.head.appendChild(script);\n}\n</script>\n<!-- K1C_CFS_INJECT_END -->'
    sed -i "s|</head>|${LOADER_BLOCK}\n</head>|g" "${TARGET_DIR}/index.html"

    mkdir -p "$HS_CONFIG_FOLDER"
    touch "${HS_CONFIG_FOLDER}/.cfs_addon_${FRONTEND}"
    return 0
  fi
  return 1
}

install_cfs_integration() {
  cfs_message

  if [ ! -f "${MAINSAIL_FOLDER}/index.html" ] && [ ! -f "${FLUIDD_FOLDER}/index.html" ]; then
    error_msg "Neither Mainsail nor Fluidd is installed! Please install a web interface first."
    return 1
  fi

  local yn
  while true; do
    install_msg "CFS-C Web Addon (Mainsail / Fluidd)" yn
    case "${yn}" in
      Y|y)
        echo "=== Starting installation of CFS-C Web Addon ==="

        apply_cfs_to_frontend "mainsail" "$MAINSAIL_FOLDER" || true
        apply_cfs_to_frontend "fluidd" "$FLUIDD_FOLDER" || true

        mkdir -p "$HS_CONFIG_FOLDER"
        if [ -f "$SOURCE_JSON" ]; then
          cp -f "$SOURCE_JSON" "$TARGET_JSON"
          chmod 644 "$TARGET_JSON"
        fi

        if [ -f "$SOURCE_PY" ]; then
          cp -f "$SOURCE_PY" "${KLIPPY_EXTRAS}/"
          chmod 644 "${KLIPPY_EXTRAS}/cfs_material_db.py"
        fi

        ok_msg "CFS-C Web Addon installed successfully!"
        echo "Info: Restarting Klipper service..."
        restart_klipper
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

remove_cfs_integration() {
  cfs_message

  local has_mainsail=0
  local has_fluidd=0
  [ -f "${MAINSAIL_FOLDER}/k1c-cfs-panel.js" ] || [ -f "${HS_CONFIG_FOLDER}/.cfs_addon_mainsail" ] && has_mainsail=1
  [ -f "${FLUIDD_FOLDER}/k1c-cfs-panel.js" ] || [ -f "${HS_CONFIG_FOLDER}/.cfs_addon_fluidd" ] && has_fluidd=1

  if [ "$has_mainsail" -eq 0 ] && [ "$has_fluidd" -eq 0 ]; then
    error_msg "CFS-C Web Addon is not installed in Mainsail or Fluidd!"
    return 1
  fi

  local choice=""
  if [ "$has_mainsail" -eq 1 ] && [ "$has_fluidd" -eq 1 ]; then
    echo -e " ${white}The CFS-C Web Addon is installed in both interfaces:${white}"
    echo -e "   ${yellow}1)${white} Remove from ${cyan}ALL${white} (Mainsail & Fluidd)"
    echo -e "   ${yellow}2)${white} Remove from ${cyan}Mainsail${white} only"
    echo -e "   ${yellow}3)${white} Remove from ${cyan}Fluidd${white} only"
    echo -e "   ${yellow}c)${white} Cancel"
    echo
    while true; do
      read -p " ${white}Select an option (${yellow}1${white}/${yellow}2${white}/${yellow}3${white}/${yellow}c${white}): ${yellow}" choice
      echo -e "${white}"
      case "$choice" in
        1|2|3) break;;
        C|c) error_msg "Deletion canceled!"; return;;
        *) error_msg "Please select a correct choice!";;
      esac
    done
  else
    local yn
    while true; do
      remove_msg "CFS-C Web Addon" yn
      case "${yn}" in
        Y|y) choice="1"; break;;
        N|n) error_msg "Deletion canceled!"; return;;
        *) error_msg "Please select a correct choice!";;
      esac
    done
  fi

  echo "=== Starting removal of CFS-C Web Addon ==="

  if [ "$choice" = "1" ] || [ "$choice" = "2" ]; then
    if [ -f "${MAINSAIL_FOLDER}/index.html" ]; then
      sed -i '/<!-- K1C_CFS_INJECT_START -->/,/<!-- K1C_CFS_INJECT_END -->/d' "${MAINSAIL_FOLDER}/index.html"
    fi
    rm -f "${MAINSAIL_FOLDER}/k1c-cfs-panel.js"
    rm -f "${HS_CONFIG_FOLDER}/.cfs_addon_mainsail"
    echo -e "Info: Removed CFS-C Addon from Mainsail."
  fi

  if [ "$choice" = "1" ] || [ "$choice" = "3" ]; then
    if [ -f "${FLUIDD_FOLDER}/index.html" ]; then
      sed -i '/<!-- K1C_CFS_INJECT_START -->/,/<!-- K1C_CFS_INJECT_END -->/d' "${FLUIDD_FOLDER}/index.html"
    fi
    rm -f "${FLUIDD_FOLDER}/k1c-cfs-panel.js"
    rm -f "${HS_CONFIG_FOLDER}/.cfs_addon_fluidd"
    echo -e "Info: Removed CFS-C Addon from Fluidd."
  fi

  # Remove shared Klipper backend files only if NO frontend still uses the addon
  if [ ! -f "${HS_CONFIG_FOLDER}/.cfs_addon_mainsail" ] && [ ! -f "${HS_CONFIG_FOLDER}/.cfs_addon_fluidd" ]; then
    rm -f "$TARGET_JSON"
    rm -f "${KLIPPY_EXTRAS}/cfs_material_db.py"
    echo -e "Info: Removed shared Klipper CFS-C backend files."
  else
    echo -e "Info: Keeping shared Klipper backend active for the remaining web interface."
  fi

  ok_msg "CFS-C Web Addon removal completed!"
  echo "Info: Restarting Klipper service..."
  restart_klipper
}

reapply_cfs_frontend_patch() {
  local FRONTEND="$1"
  local TARGET_DIR=""
  [ "$FRONTEND" = "mainsail" ] && TARGET_DIR="$MAINSAIL_FOLDER"
  [ "$FRONTEND" = "fluidd" ] && TARGET_DIR="$FLUIDD_FOLDER"

  if [ -n "$TARGET_DIR" ] && [ -f "${HS_CONFIG_FOLDER}/.cfs_addon_${FRONTEND}" ]; then
    apply_cfs_to_frontend "$FRONTEND" "$TARGET_DIR" || true
  fi
}