#!/bin/sh

BOX_CFG_ORIG="${HS_BACKUP_FOLDER}/box.cfg.orig"

cfs_c_flowtech_extension() {
  case "$1" in
    install)
      echo "=== Installation: Micro-Swiss FlowTech Volumetric Extension ==="
      if [ ! -f "$BOX_CFG" ]; then
          echo "Fehler: box.cfg wurde im System nicht gefunden!"
          return 1
      fi
      mkdir -p "$HS_BACKUP_FOLDER"

      # Hellseherische Prüfung
      if grep -q "extrude_length:[[:space:]]*50" "$BOX_CFG"; then
          echo "[INFO] Die FlowTech Volumetric Extension ist bereits aktiv!"
          if [ ! -f "$BOX_CFG_ORIG" ]; then
              cp -f "$BOX_CFG" "$BOX_CFG_ORIG"
              sed -i 's/extrude_length:[[:space:]]*[0-9]*/extrude_length: 20/g' "$BOX_CFG_ORIG"
              sed -i 's/Tn_extrude_velocity:[[:space:]]*[0-9]*/Tn_extrude_velocity: 360/g' "$BOX_CFG_ORIG"
              echo "[OK] Echtes Werks-Backup der box.cfg erzeugt."
          fi
          return 0
      fi

      # Reguläre Installation
      if [ ! -f "$BOX_CFG_ORIG" ]; then cp -f "$BOX_CFG" "$BOX_CFG_ORIG"; fi
      cp -f "$BOX_CFG_ORIG" "$BOX_CFG"
      sed -i 's/extrude_length:[[:space:]]*[0-9]*/extrude_length: 50/g' "$BOX_CFG"
      sed -i 's/Tn_extrude_velocity:[[:space:]]*[0-9]*/Tn_extrude_velocity: 120/g' "$BOX_CFG"
      chmod 644 "$BOX_CFG"
      echo "[OK] box.cfg erfolgreich auf vergroessertes Kammervolumen (E50) angepasst."
      echo "Info: Restarting Klipper service..."
      restart_klipper
      ;;

    remove)
      echo "=== Deinstallation: Micro-Swiss FlowTech Volumetric Extension ==="
      if [ -f "$BOX_CFG_ORIG" ]; then
          cp -f "$BOX_CFG_ORIG" "$BOX_CFG"
          rm -f "$BOX_CFG_ORIG"
          echo "[OK] Originale Werks-box.cfg (E20) wiederhergestellt."
          echo "Info: Restarting Klipper service..."
          restart_klipper
      else
          echo "[INFO] FlowTech Volumetric Extension ist nicht aktiv."
      fi
      ;;
  esac
}