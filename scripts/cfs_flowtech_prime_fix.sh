#!/bin/sh

cfs_flowtech_prime_fix() {
  case "$1" in
    install)
      echo "=== Starte Installation: CFS-C FlowTech Volume Prime Fix ==="
      
      # 1. Pruefen ob Systemdateien existieren (Nutzt deine neuen Variablen)
      if [ ! -f "$BOX_CONTROL" ] || [ ! -f "$BOX_CFG" ]; then
          echo "Fehler: box_control.pyc oder box.cfg wurden im System nicht gefunden!"
          return 1
      fi
      
      # Backup-Verzeichnis erstellen, falls es noch nicht existiert
      mkdir -p "$HS_BACKUP_FOLDER"

      # 2. HELLSEHERISCHE PRÜFUNG: Wurde der Fix bereits manuell appliziert?
      if grep -q -a -b -o "E-10 F120" "$BOX_CONTROL" && grep -q "extrude_length:[[:space:]]*50" "$BOX_CFG"; then
          echo "[INFO] Der Fix ist bereits aktiv (manuelle Installation erkannt)!"
          
          # Wir generieren die echten Werkszustands-Backups nachträglich im Backup-Ordner
          if [ ! -f "$PYC_ORIG" ]; then
              cp -f "$BOX_CONTROL" "$PYC_ORIG"
              sed -i 's/E-10 F120/E-10 F180/g' "$PYC_ORIG"
              echo "[OK] Echtes Werks-Backup der box_control.pyc erzeugt."
          fi
          if [ ! -f "$BOX_CFG_ORIG" ]; then
              cp -f "$BOX_CFG" "$BOX_CFG_ORIG"
              sed -i 's/extrude_length:[[:space:]]*[0-9]*/extrude_length: 20/g' "$BOX_CFG_ORIG"
              sed -i 's/Tn_extrude_velocity:[[:space:]]*[0-9]*/Tn_extrude_velocity: 360/g' "$BOX_CFG_ORIG"
              echo "[OK] Echtes Werks-Backup der box.cfg erzeugt."
          fi
          echo "[OK] Fix erfolgreich im Helper-Script-System registriert."
          return 0
      fi
      
      # 3. REGULÄRE INSTALLATION (Falls unberührter Werkszustand aktiv ist)
      if [ ! -f "$PYC_ORIG" ]; then cp -f "$BOX_CONTROL" "$PYC_ORIG"; fi
      if [ ! -f "$BOX_CFG_ORIG" ]; then cp -f "$BOX_CFG" "$BOX_CFG_ORIG"; fi

      # Wir arbeiten auf Basis des sauberen Originals
      cp -f "$PYC_ORIG" "$BOX_CONTROL"
      if grep -q -a -b -o "E-10 F180" "$BOX_CONTROL"; then
          sed -i 's/E-10 F180/E-10 F120/g' "$BOX_CONTROL"
          chmod 644 "$BOX_CONTROL"
          echo "[OK] Bytecode in box_control.pyc erfolgreich auf F120 gedrosselt."
      else
          echo "Fehler: Werks-Signatur 'E-10 F180' nicht gefunden! Patch abgebrochen."
          cp -f "$PYC_ORIG" "$BOX_CONTROL"
          return 1
      fi

      cp -f "$BOX_CFG_ORIG" "$BOX_CFG"
      sed -i 's/extrude_length:[[:space:]]*[0-9]*/extrude_length: 50/g' "$BOX_CFG"
      sed -i 's/Tn_extrude_velocity:[[:space:]]*[0-9]*/Tn_extrude_velocity: 120/g' "$BOX_CFG"
      chmod 644 "$BOX_CFG"
      echo "[OK] box.cfg erfolgreich auf E50 und V120 angepasst."
      
      echo "Info: Restarting Klipper service..."
      restart_klipper
      ;;

    remove)
      echo "=== Starte Deinstallation: CFS-C FlowTech Volume Prime Fix ==="
      
      # Werkszustand aus den Backups wiederherstellen
      if [ -f "$PYC_ORIG" ]; then
          cp -f "$PYC_ORIG" "$BOX_CONTROL"
          rm -f "$PYC_ORIG"
          echo "[OK] Originale box_control.pyc wiederhergestellt."
      fi
      if [ -f "$BOX_CFG_ORIG" ]; then
          cp -f "$BOX_CFG_ORIG" "$BOX_CFG"
          rm -f "$BOX_CFG_ORIG"
          echo "[OK] Originale box.cfg wiederhergestellt."
      fi
      
      echo "Info: Restarting Klipper service..."
      restart_klipper
      ;;
  esac
}