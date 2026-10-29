#!/bin/sh

set -e

# Globale Pfade definieren, damit sie in allen Funktionen bekannt sind
# (Stellen Sie sicher, dass $HS_BACKUP_FOLDER und $BOX_CFG aus path.sh vorher geladen wurden)
BOX_CFG_ORIG="${HS_BACKUP_FOLDER}/box.cfg.orig"

cfs_c_flowtech_extension_message(){
  top_line
  title 'MicroSwiss FlowTech Hotend Patch:' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Eliminates the 20% empty extrusion inside the Purge Tower        ${white}│"
  echo -e " │ ${cyan} during toolchanges and optimizes the filament feeding speed.    ${white}│"
  echo -e " │ ${cyan}This prevents torn lines, stabilizes the Purge Tower structure,  ${white}│"
  echo -e " │ ${cyan}and dramatically reduces material waste                          ${white}│"
  echo -e " │ ${cyan}by allowing a much smaller tower size.                           ${white}│"
  hr
  bottom_line
}

install_cfs_c_flowtech_extension() {
  cfs_c_flowtech_extension_message
  local yn
  while true; do
    backup_msg "Moonraker database" yn
    case "${yn}" in
      Y|y)
        echo "=== Installation: Micro-Swiss FlowTech Volumetric Extension ==="
        if [ ! -f "$BOX_CFG" ]; then
            echo "Fehler: box.cfg wurde nicht gefunden!"
            return 1
        fi
        mkdir -p "$HS_BACKUP_FOLDER"

        if grep -q "extrude_length:[[:space:]]*50" "$BOX_CFG"; then
            echo "[INFO] Die FlowTech Volumetric Extension ist bereits aktiv!"
            if [ ! -f "$BOX_CFG_ORIG" ]; then
                cp -f "$BOX_CFG" "$BOX_CFG_ORIG"
                sed -i -E 's/extrude_length:[[:space:]]*[0-9]+/extrude_length: 20/g' "$BOX_CFG_ORIG"
                sed -i -E 's/Tn_extrude_velocity:[[:space:]]*[0-9]+/Tn_extrude_velocity: 360/g' "$BOX_CFG_ORIG"
                echo "[OK] Echtes Werks-Backup erzeugt."
            fi
            return 0
        fi

        if [ ! -f "$BOX_CFG_ORIG" ]; then 
            cp -f "$BOX_CFG" "$BOX_CFG_ORIG"
        fi
        cp -f "$BOX_CFG_ORIG" "$BOX_CFG"
        sed -i -E 's/extrude_length:[[:space:]]*[0-9]+/extrude_length: 50/g' "$BOX_CFG"
        sed -i -E 's/Tn_extrude_velocity:[[:space:]]*[0-9]+/Tn_extrude_velocity: 120/g' "$BOX_CFG"
        chmod 644 "$BOX_CFG"
        echo "[OK] box.cfg erfolgreich auf E50 angepasst."
        restart_klipper
        return 0
        ;;
      N|n)
        error_msg "Backup canceled!"
        return 1
        ;;
      *)
        error_msg "Please select a correct choice!"
        ;;
    esac
  done
}

remove_cfs_c_flowtech_extension() {
  cfs_c_flowtech_extension_message
  
  echo "=== Deinstallation: Micro-Swiss FlowTech Volumetric Extension ==="
  if [ -f "$BOX_CFG_ORIG" ]; then
      cp -f "$BOX_CFG_ORIG" "$BOX_CFG"
      rm -f "$BOX_CFG_ORIG"
      echo "[OK] Originale Werks-box.cfg (E20) wiederhergestellt."
      restart_klipper
  else
      if grep -q "extrude_length:[[:space:]]*50" "$BOX_CFG"; then
          sed -i -E 's/extrude_length:[[:space:]]*[0-9]+/extrude_length: 20/g' "$BOX_CFG"
          sed -i -E 's/Tn_extrude_velocity:[[:space:]]*[0-9]+/Tn_extrude_velocity: 360/g' "$BOX_CFG"
          echo "[OK] box.cfg manuell auf Werkszustand E20 zurueckgesetzt."
          restart_klipper
      else
          echo "[INFO] FlowTech Volumetric Extension ist nicht aktiv (bereits Werkszustand)."
      fi
  fi
}