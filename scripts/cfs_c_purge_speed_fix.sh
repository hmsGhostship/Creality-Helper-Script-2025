#!/bin/sh

set -e

BOX_CFG_ORIG="${HS_BACKUP_FOLDER}/box.cfg.orig"

cfs_c_flowtech_extension_message(){
  top_line
  title 'MicroSwiss FlowTech Hotend Patch:' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Eliminates empty extrusion inside the Purge Tower              ${white}│"
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
            error_msg "Fehler: box.cfg wurde unter ${BOX_CONFIG} nicht gefunden!"
            break
        fi
        mkdir -p "$HS_BACKUP_FOLDER"

        # 1. Live-Prüfung: Ist der Patch (Wert 40) in der aktiven box.cfg bereits aktiv?
        if grep -q "extrude_length:[[:space:]]*40" "$BOX_CFG"; then
            echo "[INFO] Die FlowTech-Erweiterung (E40) ist bereits aktiv!"
            break
        fi

        # 2. Sichert das originale Creality-Werksprofil NUR BEIM ALLERERSTEN MAL.
        # Das verhindert, dass ein bereits modifizierter Wert jemals als "Original" gesichert wird.
        if [ ! -f "$BOX_CFG_ORIG" ]; then 
            cp -f "$BOX_CFG" "$BOX_CFG_ORIG"
            echo "[OK] Echtes Werks-Backup ($BOX_CFG_ORIG) erzeugt."
        else
            echo "[INFO] Altes Werks-Backup existiert bereits und wird geschuetzt."
        fi

        # 3. Gezielte Modifikation der aktiven Live-Datei auf E40
        sed -i -E 's/extrude_length:[[:space:]]*[0-9]+/extrude_length: 40/g' "$BOX_CFG"
        sed -i -E 's/Tn_extrude_velocity:[[:space:]]*[0-9]+/Tn_extrude_velocity: 120/g' "$BOX_CFG"
        chmod 644 "$BOX_CFG"
        echo "[OK] box.cfg erfolgreich auf E40 und Velocity 120 angepasst."
        
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
        if [ ! -f "$BOX_CFG" ]; then
            error_msg "Fehler: box.cfg wurde nicht gefunden!"
            break
        fi

        # Weg A: Das saubere, originale Werks-Backup existiert -> Zurückspielen und aufräumen
        if [ -f "$BOX_CFG_ORIG" ]; then
            cp -f "$BOX_CFG_ORIG" "$BOX_CFG"
            chmod 644 "$BOX_CFG"
            rm -f "$BOX_CFG_ORIG"
            echo "[OK] Originale box.cfg aus Backup wiederhergestellt."
            restart_klipper
        # Weg B: Kein Backup da, aber Live ist die Änderung aktiv -> Manuelle Inplace-Reparatur auf Creality-Standard
        elif grep -q "extrude_length:[[:space:]]*40" "$BOX_CFG"; then
            sed -i -E 's/extrude_length:[[:space:]]*[0-9]+/extrude_length: 20/g' "$BOX_CFG"
            sed -i -E 's/Tn_extrude_velocity:[[:space:]]*[0-9]+/Tn_extrude_velocity: 360/g' "$BOX_CFG"
            chmod 644 "$BOX_CFG"
            echo "[OK] box.cfg manuell im Live-System auf Werkszustand (E20 / V360) zurueckgesetzt."
            restart_klipper
        else
            echo "[INFO] FlowTech Volumetric Extension is not active (bereits Werkszustand)."
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
