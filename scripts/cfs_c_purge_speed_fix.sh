#!/bin/sh

set -e

BOX_CONTROL="${KLIPPER_EXTRAS_FOLDER}/box_control.pyc"
PYC_ORIG="${HS_BACKUP_FOLDER}/box_control.pyc.orig"

cfs_c_speed_fix_message(){
  top_line
  title ' CFS-C Speed Fix (Filament Change Optimization):' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}The **CFS-C Speed Fix** micro-tunes and deliberately           ${white}│"
  echo -e " │ ${cyan}slows down the initial feeding and loading speeds inside the   ${white}│"
  echo -e " │ ${cyan}hotend context. By introducing a controlled, synchronized feed ${white}│"
  echo -e " │ ${cyan}rate, it gives the hotend sufficient time to melt the incoming ${white}│"
  echo -e " │ ${cyan}material safely. This entirely eliminates back-pressure        ${white}│"
  echo -e " │ ${cyan} spikes and safeguards your extruder gears against grinding.   ${white}│"
  hr
  bottom_line
}

install_cfs_c_speed_fix() {
  cfs_c_speed_fix_message
  local yn
  while true; do
    install_msg "CFS-C Speed Fix" yn
    case "${yn}" in
      Y|y)
        echo "=== Installation: CFS-C Universal Purge Speed Fix ==="
        if [ ! -f "$BOX_CONTROL" ]; then
            error_msg "Fehler: box_control.pyc wurde unter ${BOX_CONTROL} nicht gefunden!"
            break
        fi
        mkdir -p "$HS_BACKUP_FOLDER"

        # 1. Prüfe den echten Zustand der Live-Datei
        if grep -q -a -b -o "E-10 F120" "$BOX_CONTROL"; then
            echo "[INFO] Der Speed-Fix ist in der aktiven Datei bereits aktiv!"
            break
        fi

        # 2. Prüfe auf Werkssignatur
        if grep -q -a -b -o "E-10 F180" "$BOX_CONTROL"; then
            echo "[OK] Originale Werks-Signatur (F180) in Live-Datei verifiziert."
            
            # Sichert das Original nur beim allerersten Mal
            if [ ! -f "$PYC_ORIG" ]; then
                cp -f "$BOX_CONTROL" "$PYC_ORIG"
                echo "[OK] Echtes Werks-Backup erzeugt."
            else
                echo "[INFO] Altes Werks-Backup existiert bereits und wird geschuetzt."
            fi

            # 3. Inplace-Patch direkt im Bytecode
            sed -i 's/E-10 F180/E-10 F120/g' "$BOX_CONTROL"
            chmod 644 "$BOX_CONTROL"
            echo "[OK] Bytecode erfolgreich auf F120 gedrosselt."
            restart_klipper
        else
            error_msg "Fehler: Werks-Signatur (F180) nicht gefunden! Firmware inkompatibel."
        fi
        break;;
      N|n)
        error_msg "Installation canceled!"
        break;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

remove_cfs_c_speed_fix() {
  cfs_c_speed_fix_message
  local yn
  while true; do
    remove_msg "CFS-C Speed Fix" yn
    case "${yn}" in
      Y|y)
        echo "=== Deinstallation: CFS-C Universal Purge Speed Fix ==="
        if [ ! -f "$BOX_CONTROL" ]; then
            error_msg "Fehler: box_control.pyc wurde nicht gefunden!"
            break
        fi

        if [ -f "$PYC_ORIG" ]; then
            cp -f "$PYC_ORIG" "$BOX_CONTROL"
            chmod 644 "$BOX_CONTROL"
            rm -f "$PYC_ORIG"
            echo "[OK] Originale box_control.pyc (F180) aus Backup wiederhergestellt."
            restart_klipper
        elif grep -q -a -b -o "E-10 F120" "$BOX_CONTROL"; then
            sed -i 's/E-10 F120/E-10 F180/g' "$BOX_CONTROL"
            chmod 644 "$BOX_CONTROL"
            echo "[OK] Bytecode manuell im Live-System auf Werkszustand F180 zurueckgesetzt."
            restart_klipper
        else
            echo "[INFO] Universal Speed Fix ist nicht aktiv (bereits Werkszustand)."
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
