#!/bin/sh
export HOME=/usr/data
export PATH=/opt/bin:/opt/sbin:/bin:/sbin:/usr/bin:/usr/sbin

TARGET_DIR="/usr/data/helper-script"
cd "$TARGET_DIR"

if [ ! -d ".git" ]; then
    echo "Fehler: Kein Git-Repository im Helper-Script-Ordner gefunden!"
    exit 1
fi

# UNZERSTÖRBARER RECHTE-ERZWINGER:
# Wir loeschen alte Geister-Locks und oeffnen die Rechte komplett,
# BEVOR Git ueberhaupt irgendetwas tut!
rm -f .git/*.lock .git/refs/remotes/origin/*.lock 2>/dev/null
chmod -R 777 .git 2>/dev/null

# RAM-Sperren felsenfest bei jedem Durchlauf erzwingen
git config core.bigFileThreshold 1k
git config pack.compression 0
git config pack.depth 1
git config pack.window 0
git config pack.windowMemory "0"
git config pack.packSizeLimit "0"
git config http.postBuffer 5242880

if [ -z "$(git status --porcelain)" ]; then
    echo "Keine Änderungen in den Helper-Skripten vorhanden."
    exit 0
fi

echo "Starte RAM-freies Helper-Script Backup..."
git add .
git commit -m "Automatisches Helper-Script Backup: $(date +'%Y-%m-%d %H:%M:%S')"
git push -u origin main
echo "Backup erfolgreich hochgeladen!"

# Nach dem Push die Rechte fuer den naechsten Durchlauf offen halten
chmod -R 777 .git 2>/dev/null
