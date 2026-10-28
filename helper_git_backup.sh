#!/sh
export PATH=/usr/bin:/usr/sbin:/bin:/sbin:/opt/bin:/opt/sbin

# DIESE ZEILE RETTET UNS: Wir gaukeln Git ein sauberes, offenes HOME im RAM vor.
# Der Mainsail-User darf hier lesen/schreiben und wird nicht mehr in /root blockiert!
export HOME=/tmp

TARGET_DIR="/usr/data/helper-script"
cd "$TARGET_DIR"

if [ ! -d ".git" ]; then
    echo "Fehler: Kein Git-Repository im Helper-Script-Ordner gefunden!"
    exit 1
fi

# Lokale Sperren loeschen
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

# Wir holen die funktionierende URL (samt Token) direkt aus dem Ordner:
LOKALE_URL=$(git remote get-url origin)

# Wir zwingen den Push, exakt diese funktionierende Adresse zu nutzen:
git push -u "$LOKALE_URL" main

echo "Backup erfolgreich hochgeladen!"
chmod -R 777 .git 2>/dev/null