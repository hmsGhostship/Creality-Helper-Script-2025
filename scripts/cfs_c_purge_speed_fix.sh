#!/bin/sh

cfs_c_speed_fix() {
  # Variable JETZT ERST deklarieren, damit sie den echten Pfad aus path.sh kennt!
  PYC_ORIG="${HS_BACKUP_FOLDER}/box_control.pyc.orig"

  case "$1" in
    install)
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

      if [ ! -f "$PYC_ORIG" ]; then cp -f "$BOX_CONTROL" "$PYC_ORIG"; fi
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
      ;;

    remove)
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
      ;;
  esac
}