#!/bin/sh

set -e

function cfs_filament_guard_message(){
  top_line
  title 'CFS-C Pre-Print Filament Guard' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Verifies before heating/printing that all filament types and  ${white}│"
  echo -e " │ ${cyan}colors used in the sliced G-code are loaded in your CFS-C.    ${white}│"
  echo -e " │ ${cyan}Cancels the print immediately if a required spool is missing. ${white}│"
  hr
  bottom_line
}

function install_cfs_filament_guard(){
  cfs_filament_guard_message
  local yn
  while true; do
    install_msg "CFS-C Pre-Print Filament Guard" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        if [ ! -f "$KLIPPER_SHELL_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is needed, please install it first!"
          return
        fi
        mkdir -p "$HS_CONFIG_FOLDER"
        cp -f "${HELPER_SCRIPT_FOLDER}/files/cfs_filament_guard/cfs_filament_guard.py" "$HS_CONFIG_FOLDER/cfs_filament_guard.py"
        chmod +x "$HS_CONFIG_FOLDER/cfs_filament_guard.py"

        cat << 'EOF' > "$HS_CONFIG_FOLDER/cfs_filament_guard.cfg"
[gcode_shell_command _CHECK_CFS_FILAMENTS_CMD]
command: /usr/data/moonraker/moonraker-env/bin/python /usr/data/printer_data/config/Helper-Script/cfs_filament_guard.py
timeout: 3.0
verbose: True

[gcode_macro CHECK_CFS_FILAMENTS]
gcode:
  {% set fn = printer.print_stats.filename|default("") %}
  {% set cc = params.CHECK_COLOR|default("1") %}
  {% if fn != "" %}
    RUN_SHELL_COMMAND CMD=_CHECK_CFS_FILAMENTS_CMD PARAMS="\"{fn}\" {cc}"
  {% endif %}
EOF

        if [ ! -f "$HS_CONFIG_FOLDER/calib_tool_box.cfg" ]; then
          cat << 'EOF2' >> "$HS_CONFIG_FOLDER/cfs_filament_guard.cfg"

[gcode_macro START_PRINT]
rename_existing: START_PRINT_GUARD_BASE
gcode:
  {% set check_color = params.CHECK_COLOR|default("1") %}
  {% set skip_once = printer.save_variables.variables.cfs_skip_guard_once|default(0)|int %}
  {% if skip_once == 1 %}
    SAVE_VARIABLE VARIABLE=cfs_skip_guard_once VALUE=0
  {% else %}
    CHECK_CFS_FILAMENTS CHECK_COLOR={check_color}
  {% endif %}
  START_PRINT_GUARD_BASE {rawparams}
EOF2
        fi

        if ! grep -q "^\[include Helper-Script/cfs_filament_guard.cfg\]" "$PRINTER_CFG"; then
          sed -i "1i [include Helper-Script/cfs_filament_guard.cfg]" "$PRINTER_CFG"
        fi

        if [ -f "$HS_CONFIG_FOLDER/calib_tool_box.cfg" ]; then
          /usr/data/moonraker/moonraker-env/bin/python -c '
p = "/usr/data/printer_data/config/Helper-Script/calib_tool_box.cfg"
s = open(p, "r", encoding="utf-8").read()
if "[gcode_shell_command _CHECK_CFS_FILAMENTS_CMD]" in s:
    a = s.index("[gcode_shell_command _CHECK_CFS_FILAMENTS_CMD]")
    b = s.index("[gcode_macro START_PRINT]")
    s = s[:a] + s[b:]
target = "[gcode_macro START_PRINT]
rename_existing: START_PRINT_BASE
gcode:
"
hook = '''  {% set check_color = params.CHECK_COLOR|default("1") %}
  {% set skip_once = printer.save_variables.variables.cfs_skip_guard_once|default(0)|int %}
  {% if skip_once == 1 %}
    SAVE_VARIABLE VARIABLE=cfs_skip_guard_once VALUE=0
  {% else %}
    CHECK_CFS_FILAMENTS CHECK_COLOR={check_color}
  {% endif %}
'''
if target in s and "CHECK_CFS_FILAMENTS" not in s:
    s = s.replace(target, target + hook, 1)
open(p, "w", encoding="utf-8").write(s)
'
        fi

        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "CFS-C Pre-Print Filament Guard has been installed successfully!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_cfs_filament_guard(){
  cfs_filament_guard_message
  local yn
  while true; do
    remove_msg "CFS-C Pre-Print Filament Guard" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        rm -f "$HS_CONFIG_FOLDER/cfs_filament_guard.py" "$HS_CONFIG_FOLDER/cfs_filament_guard.cfg"
        sed -i "/^\[include Helper-Script\/cfs_filament_guard.cfg\]/d" "$PRINTER_CFG" 2>/dev/null || true
        if [ -f "$HS_CONFIG_FOLDER/calib_tool_box.cfg" ]; then
          /usr/data/moonraker/moonraker-env/bin/python -c '
p = "/usr/data/printer_data/config/Helper-Script/calib_tool_box.cfg"
s = open(p, "r", encoding="utf-8").read()
s = s.replace("  {% set check_color = params.CHECK_COLOR|default("1") %}
  CHECK_CFS_FILAMENTS CHECK_COLOR={check_color}
", "")
open(p, "w", encoding="utf-8").write(s)
'
        fi
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "CFS-C Pre-Print Filament Guard has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}
