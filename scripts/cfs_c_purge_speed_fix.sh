#!/bin/sh

set -e

BOX_CONTROL="${KLIPPER_EXTRAS_FOLDER}/box_control.pyc"
PYC_ORIG="${HS_BACKUP_FOLDER}/box_control.pyc.orig"

cfs_c_speed_fix_message(){
  top_line
  title 'CFS-C Speed Fix (Filament Change Optimization):' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}The CFS-C Speed Fix micro-tunes and deliberately               ${white}│"
  echo -e " │ ${cyan}slows down the initial feeding and loading speeds inside the   ${white}│"
  echo -e " │ ${cyan}hotend context. By introducing a controlled, synchronized feed ${white}│"
  echo -e " │ ${cyan}rate, it gives the hotend sufficient time to melt the incoming ${white}│"
  echo -e " │ ${cyan}material safely. This entirely eliminates back-pressure        ${white}│"
  echo -e " │ ${cyan}spikes and safeguards your extruder gears against grinding.    ${white}│"
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
            error_msg "Error: box_control.pyc was not found at ${BOX_CONTROL}!"
            break
        fi
        mkdir -p "$HS_BACKUP_FOLDER"

        # 1. Check the actual state of the live file
        if grep -q -a -b -o "E-10 F120" "$BOX_CONTROL"; then
            echo "[INFO] The Speed Fix is already active in the live file!"
            break
        fi

        # 2. Verify factory signature
        if grep -q -a -b -o "E-10 F180" "$BOX_CONTROL"; then
            echo "[OK] Original factory signature (F180) verified in live file."
            
            # Backup original file only on the very first run
            if [ ! -f "$PYC_ORIG" ]; then
                cp -f "$BOX_CONTROL" "$PYC_ORIG"
                echo "[OK] Original factory backup created."
            else
                echo "[INFO] Existing factory backup already present and protected."
            fi

            # 3. In-place bytecode patch
            sed -i 's/E-10 F180/E-10 F120/g' "$BOX_CONTROL"
            chmod 644 "$BOX_CONTROL"
            echo "[OK] Bytecode successfully throttled to F120."
            restart_klipper
        else
            error_msg "Error: Factory signature (F180) not found! Firmware incompatible."
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
        echo "=== Removal: CFS-C Universal Purge Speed Fix ==="
        if [ ! -f "$BOX_CONTROL" ]; then
            error_msg "Error: box_control.pyc was not found!"
            break
        fi

        if [ -f "$PYC_ORIG" ]; then
            cp -f "$PYC_ORIG" "$BOX_CONTROL"
            chmod 644 "$BOX_CONTROL"
            rm -f "$PYC_ORIG"
            echo "[OK] Original box_control.pyc (F180) restored from backup."
            restart_klipper
        elif grep -q -a -b -o "E-10 F120" "$BOX_CONTROL"; then
            sed -i 's/E-10 F120/E-10 F180/g' "$BOX_CONTROL"
            chmod 644 "$BOX_CONTROL"
            echo "[OK] Bytecode manually reverted in live system to factory F180."
            restart_klipper
        else
            echo "[INFO] Universal Speed Fix is not active (already at factory defaults)."
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
