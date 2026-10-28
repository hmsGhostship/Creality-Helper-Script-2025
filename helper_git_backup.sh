#!/sh
export PATH=/usr/bin:/usr/sbin:/bin:/sbin:/opt/bin:/opt/sbin

TARGET_DIR="/usr/data/helper-script"
cd "$TARGET_DIR"

if [ ! -d ".git" ]; then
    echo "Fehler: Kein Git-Repository im Helper-Script-Ordner gefunden!"
    exit 1
fi

# DIE BRUTALE LÖSUNG: Wir verbieten Git den Zugriff auf /root 
# und zwingen es, die lokale Config des Ordners als globale Config zu nutzen!
export GIT_CONFIG_GLOBAL="$TARGET_DIR/.git/config"
export GIT_CONFIG_NOSYSTEM=1

# Altschulden loeschen
rm -f .git/*.lock .git/refs/remotes/origin/*.lock 2>/dev/null
chmod -R 777 .git 2>/dev/null

# RAM-Sperren fuer den Drucker felsenfest erzwingen
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

# Läuft jetzt ungehindert durch, da Git nicht mehr in /root blockiert wird
git push -u origin main

echo "Backup erfolgreich hochgeladen!"
chmod -R 777 .git 2>/dev/null
