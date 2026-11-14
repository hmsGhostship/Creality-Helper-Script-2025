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
  local yn
  while true; do
    remove_msg "CFS-C Web Addon (Mainsail / Fluidd)" yn
    case "${yn}" in
      Y|y)
        echo "=== Starting removal of CFS-C Web Addon ==="

        local dir
        for dir in "$MAINSAIL_FOLDER" "$FLUIDD_FOLDER"; do
          if [ -f "${dir}/index.html" ]; then
            sed -i '/<!-- K1C_CFS_INJECT_START -->/,/<!-- K1C_CFS_INJECT_END -->/d' "${dir}/index.html"
          fi
          rm -f "${dir}/k1c-cfs-panel.js"
        done

        rm -f "$TARGET_JSON"
        rm -f "${KLIPPY_EXTRAS}/cfs_material_db.py"
        rm -f "${HS_CONFIG_FOLDER}/.cfs_addon_mainsail" "${HS_CONFIG_FOLDER}/.cfs_addon_fluidd"

        ok_msg "CFS-C Web Addon removed successfully!"
        echo "Info: Restarting Klipper service..."
        restart_klipper
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
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