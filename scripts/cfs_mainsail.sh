#!/bin/sh

set -e

# Global source paths from your HS_FILES folder
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
  echo -e " │ ${cyan}into your selected web frontend and injects the required       ${white}│"
  echo -e " │ ${cyan}2025 Klipper hardware extension.                               ${white}│"
  hr
  bottom_line
}

install_cfs_integration() {
  FRONTEND="$1"
  
  if [ "${FRONTEND}" = "mainsail" ]; then
      TARGET_DIR="${MAINSAIL_FOLDER}"
  elif [ "${FRONTEND}" = "fluidd" ]; then
      TARGET_DIR="${FLUIDD_FOLDER}"
  else
      echo "Fehler: Unbekanntes Frontend angegeben!"
      return 1
  fi
  
  cfs_message
  local yn
  while true; do
    install_msg "CFS Interface & Klipper Patch" yn
    case "${yn}" in
      Y|y)
        echo "=== Starte Installation des CFS-C Patches ==="
        
        # 1. Copy the frontend JavaScript (named k1c-cfs-panel.js, just as in the original)
        mkdir -p "${TARGET_DIR}"
        cp -f "$SOURCE_JS" "${TARGET_DIR}/k1c-cfs-panel.js"
        chmod 644 "${TARGET_DIR}/k1c-cfs-panel.js"

        # 2. Save persistent marker so Fluidd/Mainsail reinstallations keep the addon
        mkdir -p "$HS_CONFIG_FOLDER"
        touch "${HS_CONFIG_FOLDER}/.cfs_addon_${FRONTEND}"

        
        # 3. THE ORIGINAL INJECTION INTO index.html (Exact replica!)
        echo "➔ Injiziere Loader-Logik in ${FRONTEND}/index.html..."
        
        # Cleaning up old artifacts: Removes any previous injection attempts from index.html
        sed -i '/<!-- K1C_CFS_INJECT_START -->/,/<!-- K1C_CFS_INJECT_END -->/d' "${TARGET_DIR}/index.html"
        
        # Prepare the original JS block (formatted in a POSIX-compliant way for sed)
        LOADER_BLOCK='<!-- K1C_CFS_INJECT_START -->\n<script>\nwindow.K1C_CFS_WS_URL = "ws://" + window.location.hostname + ":9999";\nif (!window.__k1c_cfs_loader_loaded) {\n  window.__k1c_cfs_loader_loaded = true;\n  const script = document.createElement("script");\n  script.src = "/k1c-cfs-panel.js?ts=" + Date.now();\n  document.head.appendChild(script);\n}\n</script>\n<!-- K1C_CFS_INJECT_END -->'
        
        # Insert the block precisely just BEFORE the </head> tag
        sed -i "s|</head>|${LOADER_BLOCK}\n</head>|g" "${TARGET_DIR}/index.html"
        
        # 4. Overrides to Klipper configuration folder
        mkdir -p "$HS_CONFIG_FOLDER"
        if [ -f "$SOURCE_JSON" ]; then
            cp -f "$SOURCE_JSON" "$TARGET_JSON"
            chmod 644 "$TARGET_JSON"
        fi
        
        # 5. Move the Klipper extension into the global KLIPPY_EXTRAS folder
        if [ -f "$SOURCE_PY" ]; then
            cp -f "$SOURCE_PY" "${KLIPPY_EXTRAS}/"
            chmod 644 "${KLIPPY_EXTRAS}/cfs_material_db.py"
        fi
        
        echo "[OK] CFS-C Patch erfolgreich direkt in ${FRONTEND} installiert."
        echo "Info: Restarting Klipper service..."
        restart_klipper
        break;;
      N|n)
        error_msg "Installation canceled!"
        break;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

remove_cfs_integration() {
  FRONTEND="$1"
  
  if [ "${FRONTEND}" = "mainsail" ]; then
      TARGET_DIR="${MAINSAIL_FOLDER}"
  elif [ "${FRONTEND}" = "fluidd" ]; then
      TARGET_DIR="${FLUIDD_FOLDER}"
  else
      echo "Fehler: Unbekanntes Frontend angegeben!"
      return 1
  fi
  
  cfs_message
  local yn
  while true; do
    remove_msg "CFS Interface & Klipper Patch" yn
    case "${yn}" in
      Y|y)
        echo "=== Starte Deinstallation des CFS-C Patches ==="
        
        # 1. Completely cut the injection block out of the index.html file
        sed -i '/<!-- K1C_CFS_INJECT_START -->/,/<!-- K1C_CFS_INJECT_END -->/d' "${TARGET_DIR}/index.html"
        
        # 2. Delete k1c-cfs-panel.js
        rm -f "${TARGET_DIR}/k1c-cfs-panel.js"
        
        # 3. Delete Klipper extension and overrides
        rm -f "$TARGET_JSON"
        rm -f "${KLIPPY_EXTRAS}/cfs_material_db.py"
        rm -f "${HS_CONFIG_FOLDER}/.cfs_addon_${FRONTEND}"
        
        echo "[OK] Deinstallation abgeschlossen. Info: Restarting Klipper service..."
        restart_klipper
        break;;
      N|n)
        error_msg "Deletion canceled!"
        break;;
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

  if [ -n "$TARGET_DIR" ] && [ -f "${HS_CONFIG_FOLDER}/.cfs_addon_${FRONTEND}" ] && [ -f "${TARGET_DIR}/index.html" ]; then
    echo -e "Info: Restoring CFS-C Panel integration for ${FRONTEND}..."
    cp -f "$SOURCE_JS" "${TARGET_DIR}/k1c-cfs-panel.js"
    chmod 644 "${TARGET_DIR}/k1c-cfs-panel.js"
    sed -i '/<!-- K1C_CFS_INJECT_START -->/,/<!-- K1C_CFS_INJECT_END -->/d' "${TARGET_DIR}/index.html"
    local LOADER_BLOCK='<!-- K1C_CFS_INJECT_START -->\n<script>\nwindow.K1C_CFS_WS_URL = "ws://" + window.location.hostname + ":9999";\nif (!window.__k1c_cfs_loader_loaded) {\n  window.__k1c_cfs_loader_loaded = true;\n  const script = document.createElement("script");\n  script.src = "/k1c-cfs-panel.js?ts=" + Date.now();\n  document.head.appendChild(script);\n}\n</script>\n<!-- K1C_CFS_INJECT_END -->'
    sed -i "s|</head>|${LOADER_BLOCK}\n</head>|g" "${TARGET_DIR}/index.html"
  fi
}
