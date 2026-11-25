#!/bin/sh

set -e

calib_toolbox_message(){
  top_line
  title 'Creality Calibration Toolbox (Bed Mesh):' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Optimized paths and enhanced support for precise               ${white}│"
  echo -e " │ ${cyan}Bed Mesh calibrations,                                         ${white}│"
  echo -e " │ ${cyan}ensuring perfect first layers with advanced probing.           ${white}│"
  hr
  bottom_line
}

install_fluidd_status_bar() {
  local FLUIDD_INDEX="/usr/data/fluidd/index.html"
  local FLUIDD_JS="/usr/data/fluidd/calib_status.js"

  if [ -f "$FLUIDD_INDEX" ]; then
    echo "Info: Integrating permanent M117 status bar into Fluidd..."
    cat << 'EOF' > "$FLUIDD_JS"
(function () {
  function ensureBanner() {
    var el = document.getElementById("calib-m117-status");
    if (el) return el;
    var toolbar = document.querySelector(".v-app-bar .v-toolbar__content");
    if (!toolbar) return null;

    el = document.createElement("div");
    el.id = "calib-m117-status";
    el.style.cssText =
      "margin-left:14px;padding:4px 12px;border-radius:6px;font-size:13px;" +
      "font-weight:600;background:rgba(255,255,255,0.08);border:1px solid rgba(255,255,255,0.18);" +
      "color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:340px;";
    var spacer = toolbar.querySelector(".spacer");
    if (spacer) {
      toolbar.insertBefore(el, spacer);
    } else {
      toolbar.appendChild(el);
    }
    return el;
  }

  function updateStatus() {
    var apiUrl = window.location.protocol + "//" + window.location.hostname + ":7125/printer/objects/query?display_status";
    fetch(apiUrl)
      .then(function (r) { return r.json(); })
      .then(function (data) {
        var msg = data && data.result && data.result.status && data.result.status.display_status
          ? data.result.status.display_status.message
          : "";
        var el = ensureBanner();
        if (!el) return;
        if (!msg) {
          el.style.display = "none";
          return;
        }
        el.style.display = "inline-block";
        el.textContent = msg;
        if (msg.indexOf("ORIGINAL") !== -1) {
          el.style.borderColor = "#4caf50";
        } else if (msg.indexOf("ADAPTIVE") !== -1) {
          el.style.borderColor = "#2196f3";
        } else if (msg.indexOf("OFF") !== -1) {
          el.style.borderColor = "#f44336";
        } else {
          el.style.borderColor = "rgba(255,255,255,0.18)";
        }
      })
      .catch(function () {});
  }

  setInterval(updateStatus, 1500);
  setTimeout(updateStatus, 800);
})();
EOF
    if ! grep -q "calib_status.js" "$FLUIDD_INDEX"; then
      sed -i 's|</body>|<script src="calib_status.js"></script></body>|' "$FLUIDD_INDEX"
    fi
  fi
}

remove_fluidd_status_bar() {
  local FLUIDD_INDEX="/usr/data/fluidd/index.html"
  local FLUIDD_JS="/usr/data/fluidd/calib_status.js"

  rm -f "$FLUIDD_JS"
  if [ -f "$FLUIDD_INDEX" ]; then
    sed -i 's|<script src="calib_status.js"></script>||g' "$FLUIDD_INDEX"
  fi
}

install_calib_toolbox() {
  calib_toolbox_message
  local SOURCE_FILE="$HS_FILES/creality-calib-toolbox/calib_tool_box.cfg"
  local TARGET_FILE="$HS_CONFIG_FOLDER/calib_tool_box.cfg"
  local INCLUDE_LINE="[include Helper-Script/calib_tool_box.cfg]"
  local yn
  while true; do
    install_msg "Creality Calibration Toolbox" yn
    case "${yn}" in
      Y|y)
        echo "Starting installation of Creality Calibration Toolbox..."
        ensure_respond_module
        if [ ! -f "$SOURCE_FILE" ]; then
          echo "Error: Source macro calib_tool_box.cfg not found at $SOURCE_FILE!"
          return 1
        fi

        [ ! -d "/usr/data/printer_data/config/Helper-Script" ] && mkdir -p "/usr/data/printer_data/config/Helper-Script"
        cp -f "$SOURCE_FILE" "$TARGET_FILE"

        # Detect whether Creality nexusp daemon is active (1 = Nexusp/CFS-C, 0 = Native Klipper)
        local nexusp_flag=1
        if [ -f "${INITD_FOLDER}/disabled.CS56nexusp_service" ] || [ -f "${INITD_FOLDER}/disabled.S56nexusp_service" ]; then
          nexusp_flag=0
        elif ! pidof nexusp >/dev/null 2>&1 && [ ! -f "${INITD_FOLDER}/CS56nexusp_service" ] && [ ! -f "${INITD_FOLDER}/S56nexusp_service" ]; then
          nexusp_flag=0
        fi
        local VARS_FILE="${PRINTER_DATA_FOLDER}/config/variables.cfg"
        [ ! -f "$VARS_FILE" ] && echo "[Variables]" > "$VARS_FILE"
        grep -q "^\[Variables\]" "$VARS_FILE" || sed -i "1i [Variables]" "$VARS_FILE"
        if grep -q "^nexusp_active[[:space:]]*=" "$VARS_FILE"; then
          sed -i "s/^nexusp_active[[:space:]]*=.*/nexusp_active = ${nexusp_flag}/" "$VARS_FILE"
        else
          echo "nexusp_active = ${nexusp_flag}" >> "$VARS_FILE"
        fi

        # If gcode_shell_command is installed, enable live runtime detection of nexusp
        if [ -f "${KLIPPER_EXTRAS_FOLDER}/gcode_shell_command.py" ]; then
          cat << 'LIVE_EOF' >> "$TARGET_FILE"

# =========================================================================
# LIVE RUNTIME DETECTION (via gcode_shell_command)
# =========================================================================
[gcode_shell_command _SYNC_NEXUSP_STATE]
command: sh -c 'if pidof nexusp >/dev/null 2>&1; then val=1; else val=0; fi; f=/usr/data/printer_data/config/variables.cfg; [ ! -f "$f" ] && echo "[Variables]" > "$f"; if grep -q "^nexusp_active[[:space:]]*=" "$f"; then sed -i "s/^nexusp_active[[:space:]]*=.*/nexusp_active = $val/" "$f"; else echo "nexusp_active = $val" >> "$f"; fi'
timeout: 2.0
verbose: False

[delayed_gcode _LIVE_NEXUSP_POLL]
initial_duration: 1.0
gcode:
  RUN_SHELL_COMMAND CMD=_SYNC_NEXUSP_STATE
LIVE_EOF
        fi

        # Remove old kamp_only.cfg entries
        sed -i '/kamp_only\.cfg/d' "$PRINTER_CFG"

        # Remove old Toolbox entries to prevent duplicates
        sed -i '/calib_tool_box\.cfg/d' "$PRINTER_CFG"

        # Inject include line right below CreateDate or on line 5
        if grep -q "# CreateDate:" "$PRINTER_CFG"; then
          echo "Info: Injecting Toolbox include directly below CreateDate..."
          sed -i "/^[[:space:]]*#[[:space:]]*CreateDate:.*/a $INCLUDE_LINE" "$PRINTER_CFG"
        else
          echo "Info: CreateDate not found, injecting safely into line 5..."
          sed -i "5i $INCLUDE_LINE" "$PRINTER_CFG"
        fi

        install_fluidd_status_bar

        echo "Calibration Toolbox installed successfully."
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

make_calib_toolbox_remove() {
  echo "Init remove configuration..."
}

remove_calib_toolbox() {
  calib_toolbox_message
  local TARGET_FILE="$HS_CONFIG_FOLDER/calib_tool_box.cfg"
  local yn
  while true; do
    remove_msg "Creality Calibration Toolbox" yn
    case "${yn}" in
      Y|y)
        echo "Starting removal of Calibration Toolbox..."

        sed -i '/calib_tool_box\.cfg/d' "$PRINTER_CFG"
        rm -f "$TARGET_FILE"

        remove_fluidd_status_bar

        # Restore KAMP-Only if KAMP folder is present
        if [ -d "$KAMP_FOLDER" ]; then
          echo "Info: KAMP found on printer."

          if [ ! -f "$KAMP_FOLDER/kamp_only.cfg" ]; then
            echo "Safety-Fix: kamp_only.cfg missing! Re-linking..."
            ln -sf "$KAMP_URL/kamp_only.cfg" "$KAMP_FOLDER/kamp_only.cfg"
          fi

          echo "Restoring KAMP-Only interface..."
          sed -i '/kamp_only\.cfg/d' "$PRINTER_CFG"

          local kamp_line="[include Helper-Script/KAMP/kamp_only.cfg]"
          if grep -q "# CreateDate:" "$PRINTER_CFG"; then
            sed -i "/^[[:space:]]*#[[:space:]]*CreateDate:.*/a $kamp_line" "$PRINTER_CFG"
          else
            sed -i "5i $kamp_line" "$PRINTER_CFG"
          fi
        fi

        echo "Calibration Toolbox removed successfully."
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
