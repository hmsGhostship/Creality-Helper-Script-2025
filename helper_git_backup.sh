#!/sh
export PATH=/usr/bin:/usr/sbin:/bin:/sbin:/opt/bin:/opt/sbin

TARGET_DIR="/usr/data/helper-script"
cd "$TARGET_DIR"

if [ ! -d ".git" ]; then
    echo "Fehler: Kein Git-Repository im Helper-Script-Ordner gefunden!"
    exit 1
fi

# Zwingt Git, NUR diesen Ordner zu nutzen und /root komplett zu ignorieren
# Das loest die Permission-Denied-Warnungen und den fatalen Push-Fehler!
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null

# Entfernt den fehlerhaften Cache-Eintrag aus der lokalen Config
git config --local --unset credential.helper 2>/dev/null

# Altschulden loeschen
rm -f .git/*.lock .git/refs/remotes/origin/*.lock 2>/dev/null
chmod -R 777 .git 2>/dev/null

# RAM-Sperren fuer den Drucker
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
# HIER DIE ÄNDERUNG: Zwingt Git, den lokalen Token direkt beim Push zu laden
git -c credential.helper=local push -u origin main

echo "Backup erfolgreich hochgeladen!"
# Der Push nutzt nun ausschliesslich die funktionierenden Daten des Ordners
#git push -u origin main
#echo "Backup erfolgreich hochgeladen!"

chmod -R 777 .git 2>/dev/null