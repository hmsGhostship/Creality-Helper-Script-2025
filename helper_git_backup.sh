#!/sh
export GIT_CONFIG_GLOBAL=/usr/data/.gitconfig_storage/.gitconfig
export PATH=/usr/bin:/usr/sbin:/bin:/sbin:/opt/bin:/opt/sbin

# THIS LINE SAVES THE DAY: We trick Git into seeing a clean, accessible HOME directory in RAM.
# The 'mainsail' user can now read/write here, avoiding the permission issues encountered in /root!
export HOME=/tmp

TARGET_DIR="/usr/data/helper-script"
cd "$TARGET_DIR"

if [ ! -d ".git" ]; then
    echo "Fehler: Kein Git-Repository im Helper-Script-Ordner gefunden!"
    exit 1
fi

# Delete local locks
rm -f .git/*.lock .git/refs/remotes/origin/*.lock 2>/dev/null
chmod -R 777 .git 2>/dev/null

# Enforce rock-solid RAM locks for the printer
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

# 1. Intercepting a custom message
COMMIT_MSG="$1"
if [ -z "${COMMIT_MSG}" ]; then
    COMMIT_MSG="Automatisches Helper-Script Backup: $(date +'%Y-%m-%d %H:%M:%S')"
fi

echo "Starte RAM-freies Helper-Script Backup..."

# 2. SAVE LOCALLY FIRST (Commit)
git add .
git commit -m "${COMMIT_MSG}"

# THE SOLUTION: We force Git to load the printer's system-wide credential store.
# This allows the script to automatically retrieve your token in the background!
git config --local credential.helper store

# 3. FETCH & MERGE CHANGES FROM OTHERS (Pull)
# --no-edit prevents the script from freezing when running in the background!
echo "Prüfe Online-Repository auf Updates von anderen Entwicklern..."
set +e
git pull origin main --no-rebase --no-edit --quiet
set -e

# 4. UPLOAD AS NORMAL
git push -u origin main

echo "Backup erfolgreich hochgeladen!"
chmod -R 777 .git 2>/dev/null