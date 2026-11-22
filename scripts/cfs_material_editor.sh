#!/bin/sh

set -e

CFS_MAT_EDITOR_DIR="/usr/data/cfs-material-editor"
CFS_MAT_EDITOR_SVC="/etc/init.d/S99cfs_material_editor"

function cfs_material_editor_message(){
  top_line
  title 'CFS-C Material Database Editor (port 8088)' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Web UI to add, clone & edit custom filament profiles in       ${white}│"
  echo -e " │ ${cyan}Creality's material_database.json (port 8088).                ${white}│"
  hr
  bottom_line
}

function install_cfs_material_editor(){
  cfs_material_editor_message
  local yn
  while true; do
    install_msg "CFS-C Material Database Editor" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        mkdir -p "$CFS_MAT_EDITOR_DIR"
        cp -f "${HELPER_SCRIPT_FOLDER}/files/cfs-material-editor/server.py" "$CFS_MAT_EDITOR_DIR/server.py"
        cp -f "${HELPER_SCRIPT_FOLDER}/files/cfs-material-editor/index.html" "$CFS_MAT_EDITOR_DIR/index.html"
        chmod 755 "$CFS_MAT_EDITOR_DIR/server.py"
        cat << 'SVC' > "$CFS_MAT_EDITOR_SVC"
#!/bin/sh
PIDFILE="/var/run/cfs_material_editor.pid"
PY_BIN="/usr/data/moonraker/moonraker-env/bin/python"
[ -x "$PY_BIN" ] || PY_BIN="$(command -v python3 || command -v python)"
case "$1" in
  start)
    start-stop-daemon -S -b -m -p "$PIDFILE" -x "$PY_BIN" -- /usr/data/cfs-material-editor/server.py
    ;;
  stop)
    start-stop-daemon -K -p "$PIDFILE" 2>/dev/null || true
    rm -f "$PIDFILE"
    ;;
  restart)
    "$0" stop
    "$0" start
    ;;
esac
SVC
        chmod 755 "$CFS_MAT_EDITOR_SVC"
        "$CFS_MAT_EDITOR_SVC" restart >/dev/null 2>&1 || true
        ok_msg "CFS-C Material Database Editor installed! Open http://$(hostname -I 2>/dev/null | awk '{print $1}'):8088"
        return;;
      N|n) error_msg "Installation canceled!"; return;;
      *) error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_cfs_material_editor(){
  cfs_material_editor_message
  local yn
  while true; do
    remove_msg "CFS-C Material Database Editor" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        [ -x "$CFS_MAT_EDITOR_SVC" ] && "$CFS_MAT_EDITOR_SVC" stop >/dev/null 2>&1 || true
        rm -f "$CFS_MAT_EDITOR_SVC"
        rm -rf "$CFS_MAT_EDITOR_DIR"
        ok_msg "CFS-C Material Database Editor removed!"
        return;;
      N|n) error_msg "Deletion canceled!"; return;;
      *) error_msg "Please select a correct choice!";;
    esac
  done
}
