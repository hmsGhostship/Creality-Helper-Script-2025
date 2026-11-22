#!/bin/sh

set -e

CFS_MAT_EDITOR_DIR="/usr/data/cfs-material-editor"
CFS_MAT_EDITOR_SVC="/usr/apps/etc/init.d/S99cfs_material_editor"

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
        DRUCKER_IP=$(ip -4 addr show 2>/dev/null | awk '/inet / && $2 !~ /^127\\./ {sub(/\\/.*/, "", $2); print $2; exit}')
        if [ -d "/usr/data/mainsail" ]; then
          mkdir -p /usr/data/printer_data/config/.theme
          if [ ! -f /usr/data/printer_data/config/.theme/navi.json ]; then
            printf '[{"title":"Material DB","href":"http://%s:8088","target":"_blank","icon":"M12,3C7.58,3 4,4.79 4,7C4,9.21 7.58,11 12,11C16.42,11 20,9.21 20,7C20,4.79 16.42,3 12,3M4,9V12C4,14.21 7.58,16 12,16C16.42,16 20,14.21 20,12V9C20,11.21 16.42,13 12,13C7.58,13 4,11.21 4,9M4,14V17C4,19.21 7.58,21 12,21C16.42,21 20,19.21 20,17V14C20,16.21 16.42,18 12,18C7.58,18 4,16.21 4,14Z"}]\n' "$DRUCKER_IP" > /usr/data/printer_data/config/.theme/navi.json
            chown -R creality:creality /usr/data/printer_data/config/.theme 2>/dev/null || true
          fi
        fi
        if [ -f "/usr/data/printer_data/database/moonraker-sql.db" ] && [ -n "$DRUCKER_IP" ]; then
          /usr/data/moonraker/moonraker-env/bin/python -c '
import json, sqlite3, uuid
ip = "${DRUCKER_IP}"
con = sqlite3.connect("/usr/data/printer_data/database/moonraker-sql.db")
rows = con.execute("SELECT key, value FROM namespace_store WHERE namespace=\"webcams\"").fetchall()
exists = any(json.loads(v.decode() if isinstance(v, bytes) else v).get("name") == "Material DB" for _, v in rows)
if not exists:
    uid = str(uuid.uuid4())
    entry = {"name": "Material DB", "location": "printer", "service": "iframe", "target_fps": 15, "target_fps_idle": 5, "stream_url": f"http://{ip}:8088", "snapshot_url": "", "flip_horizontal": False, "flip_vertical": False, "rotation": 0, "source": "database", "extra_data": {}, "uid": uid}
    con.execute("INSERT INTO namespace_store (namespace, key, value) VALUES (\"webcams\", ?, ?)", (uid, json.dumps(entry).encode()))
    con.commit()
con.close()
' 2>/dev/null || true
        fi
        ok_msg "CFS-C Material Database Editor installed! Open http://$(ip -4 addr show 2>/dev/null | awk '/inet / && $2 !~ /^127\./ {sub(/\/.*/, "", $2); print $2; exit}'):8088"
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
