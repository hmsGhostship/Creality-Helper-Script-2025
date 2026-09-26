#!/bin/sh
export HOME=/usr/data
export PATH=/opt/bin:/opt/sbin:/bin:/sbin:/usr/bin:/usr/sbin

cd /usr/data/helper-script

if [ ! -d ".git" ]; then
    echo "Fehler: Kein Git-Repository gefunden!"
    exit 1
fi

echo "Starte Helper-Script Backup..."
git branch -M main
git add .
git commit -m "Automatisches Helper-Script Backup: $(date +'%Y-%m-%d %H:%M:%S')"
git push -u origin main --force
echo "Backup erfolgreich hochgeladen!"
