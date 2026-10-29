#!/bin/sh

set -e

# Globale Pfade definieren, damit sie in allen Funktionen bekannt sind
# (Stellen Sie sicher, dass $HS_BACKUP_FOLDER und $BOX_CONTROL aus path.sh vorher geladen wurden)
PYC_ORIG="${HS_BACKUP_FOLDER}/box_control.pyc.orig"

cfs_c_speed_fix_message(){
  top_line
  title ' CFS-C Speed Fix (Filament Change Optimization):' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}The **CFS-C Speed Fix** micro-tunes and deliberately             ${white}│"
  echo -e " │ ${cyan}slows down the initial feeding and loading speeds inside         ${white}│"
  echo -e " │ ${cyan}the hotend context. By introducing a controlled, synchronized    ${white}│"
  echo -e " │ ${cyan}feed rate, it gives the hotend sufficient time to melt the       ${white}│"
  echo -e " │ ${cyan}incoming material safely. This entirely eliminates back-pressure ${white}│"
  echo -e " │ ${cyan} spikes and safeguards your extruder gears against grinding.     ${white}│"
  hr
  bottom_line
}

install_cfs_c_speed_fix() {
  cfs_c_speed_fix_message
  local yn
  while true; do
    backup_msg "Moonraker database" yn
    case "${yn}" in
      Y|y)
        echo "=== Installation: CFS-C Universal Purge Speed Fix ==="
        if [ ! -f "$BOX_CONTROL" ]; then
            echo "Fehler: box_control.pyc wurde nicht gefunden!"
            return 1
        fi
        mkdir -p "$HS_BACKUP_FOLDER"

        if grep -q -a -b -o "E-10 F120" "$BOX_CONTROL"; then
            echo "[INFO] Der Speed-Fix ist bereits aktiv!"
            if [ ! -f "$PYC_ORIG" ]; then
                cp -f "$BOX_CONTROL" "$PYC_ORIG"
                sed -i 's/E-10 F120/E-10 F180/g' "$PYC_ORIG"
                echo "[OK] Echtes Werks-Backup erzeugt."
            fi
            return 0
        fi
        if [ ! -f "$PYC_ORIG" ]; then 
            cp -f "$BOX_CONTROL" "$PYC_ORIG"
        fi
        cp -f "$PYC_ORIG" "$BOX_CONTROL"
        if grep -q -a -b -o "E-10 F180" "$BOX_CONTROL"; then
            sed -i 's/E-10 F180/E-10 F120/g' "$BOX_CONTROL"
            chmod 644 "$BOX_CONTROL"
            echo "[OK] Bytecode erfolgreich auf F120 gedrosselt."
            restart_klipper
        else
            echo "Fehler: Werks-Signatur nicht gefunden!"
            return 1
        fi
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

remove_cfs_c_speed_fix() {
  cfs_c_speed_fix_message
  local yn
  while true; do
    backup_msg "Moonraker database" yn
    case "${yn}" in
      Y|y)
        echo "=== Deinstallation: CFS-C Universal Purge Speed Fix ==="
        if [ -f "$PYC_ORIG" ]; then
            cp -f "$PYC_ORIG" "$BOX_CONTROL"
            rm -f "$PYC_ORIG"
            echo "[OK] Originale box_control.pyc (F180) wiederhergestellt."
            restart_klipper
        else
            if grep -q -a -b -o "E-10 F120" "$BOX_CONTROL"; then
                sed -i 's/E-10 F120/E-10 F180/g' "$BOX_CONTROL"
                echo "[OK] Bytecode manuell auf Werkszustand F180 zurueckgesetzt."
                restart_klipper
            else
                echo "[INFO] Universal Speed Fix ist nicht aktiv (bereits Werkszustand)."
            fi
        fi
        return 0
        ;;
      N|n)
        error_msg "Deinstallation canceled!"
        return 1
        ;;
      *)
        error_msg "Please select a correct choice!"
        ;;
    esac
  done
}
