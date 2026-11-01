#!/bin/sh

set -e

BOX_CFG_ORIG="${HS_BACKUP_FOLDER}/box.cfg.orig"

cfs_c_flowtech_extension_message(){
  top_line
  title 'MicroSwiss FlowTech Hotend Patch:' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Eliminates the 20% empty extrusion inside the Purge Tower      ${white}│"
  echo -e " │ ${cyan} during toolchanges and optimizes the filament feeding speed.  ${white}│"
  echo -e " │ ${cyan}This prevents torn lines, stabilizes the Purge Tower structure,${white}│"
  echo -e " │ ${cyan}and dramatically reduces material waste                        ${white}│"
  echo -e " │ ${cyan}by allowing a much smaller tower size.                         ${white}│"
  hr
  bottom_line
}

install_cfs_c_flowtech_extension() {
  cfs_c_flowtech_extension_message
  local yn
  while true; do
    install_msg "FlowTech Extension" yn
    case "${yn}" in
      Y|y)
        echo "=== Installation: Micro-Swiss FlowTech Volumetric Extension ==="
        if [ ! -f "$BOX_CFG" ]; then
            echo "Fehler: box.cfg wurde nicht gefunden!"
            break
        fi
        mkdir -p "$HS_BACKUP_FOLDER"

        # 1. Create a factory backup once, if it does not exist yet
        if [ ! -f "$BOX_CFG_ORIG" ]; then 
            cp -f "$BOX_CFG" "$BOX_CFG_ORIG"
            echo "[OK] Factory backup ($BOX_CFG_ORIG) created."
        fi

        # 2. Modify only the active box.cfg to 50
        sed -i -E 's/extrude_length:[[:space:]]*[0-9]+/extrude_length: 50/g' "$BOX_CFG"
        sed -i -E 's/Tn_extrude_velocity:[[:space:]]*[0-9]+/Tn_extrude_velocity: 120/g' "$BOX_CFG"
        chmod 644 "$BOX_CFG"
        echo "[OK] box.cfg successfully updated to E50."
        
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

remove_cfs_c_flowtech_extension() {
  cfs_c_flowtech_extension_message
  local yn
  while true; do
    remove_msg "FlowTech Extension" yn
    case "${yn}" in
      Y|y)
        echo "=== Deinstallation: Micro-Swiss FlowTech Volumetric Extension ==="
        # 1. If backup exists, restore it and delete the backup file safely
        if [ -f "$BOX_CFG_ORIG" ]; then
            cp -f "$BOX_CFG_ORIG" "$BOX_CFG"
            rm -f "$BOX_CFG_ORIG"
            echo "[OK] Factory box.cfg restored from backup."
            restart_klipper
        else
            # 2. Fallback: If backup is missing, rewrite factory defaults manually
            if grep -q "extrude_length:[[:space:]]*50" "$BOX_CFG"; then
                sed -i -E 's/extrude_length:[[:space:]]*[0-9]+/extrude_length: 20/g' "$BOX_CFG"
                sed -i -E 's/Tn_extrude_velocity:[[:space:]]*[0-9]+/Tn_extrude_velocity: 360/g' "$BOX_CFG"
                echo "[OK] box.cfg manually reverted to factory E20."
                restart_klipper
            else
                echo "[INFO] FlowTech Volumetric Extension is not active."
            fi
        fi
        break;;
      N|n)
        error_msg "Deletion canceled!"
        break;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}
