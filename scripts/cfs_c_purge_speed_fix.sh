#!/bin/sh

PYC_ORIG="${HS_BACKUP_FOLDER}/box_control.pyc.orig"

cfs_c_speed_fix() {
  case "$1" in
    install)
      echo "=== Installation: CFS-C Universal Purge Speed Fix ==="
      if [ ! -f "$BOX_CONTROL" ]; then
          echo "Fehler: box_control.pyc wurde nicht gefunden!"
          return 1
      fi
      mkdir -p "$HS_BACKUP_FOLDER"

      # Hellseherische Prüfung
      if grep -q -a -b -o "E-10 F120" "$BOX_CONTROL"; then
          echo "[INFO] Der Speed-Fix ist bereits aktiv (manuelle Installation erkannt)!"
          if [ ! -f "$PYC_ORIG" ]; then
              cp -f "$BOX_CONTROL" "$PYC_ORIG"
              sed -i 's/E-10 F120/E-10 F180/g' "$PYC_ORIG"
              echo "[OK] Echtes Werks-Backup der box_control.pyc erzeugt."
          fi
          return 0
      fi

      # Reguläre Installation
      if [ ! -f "$PYC_ORIG" ]; then cp -f "$BOX_CONTROL" "$PYC_ORIG"; fi
      cp -f "$PYC_ORIG" "$BOX_CONTROL"
      if grep -q -a -b -o "E-10 F180" "$BOX_CONTROL"; then
          sed -i 's/E-10 F180/E-10 F120/g' "$BOX_CONTROL"
          chmod 644 "$BOX_CONTROL"
          echo "[OK] Bytecode erfolgreich auf materialschonende F120 gedrosselt."
      else
          echo "Fehler: Werks-Signatur 'E-10 F180' nicht gefunden! Patch abgebrochen."
          return 1
      fi
      echo "Info: Restarting Klipper service..."
      restart_klipper
      ;;

    remove)
      echo "=== Deinstallation: CFS-C Universal Purge Speed Fix ==="
      if [ -f "$PYC_ORIG" ]; then
          cp -f "$PYC_ORIG" "$BOX_CONTROL"
          rm -f "$PYC_ORIG"
          echo "[OK] Originale box_control.pyc (F180) wiederhergestellt."
          echo "Info: Restarting Klipper service..."
          restart_klipper
      else
          echo "[INFO] Universal Speed Fix ist nicht aktiv."
      fi
      ;;
  esac
}