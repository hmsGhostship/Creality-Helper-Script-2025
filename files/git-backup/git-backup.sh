#!/bin/sh
# Based on gitwatch.git - Fully adapted for K1C 2025 / CFS-C Layout

if [ -f /usr/data/helper-script/paths.sh ]; then
  source /usr/data/helper-script/paths.sh
  set_paths
else
  INITD_FOLDER="/usr/apps/etc/init.d"
  PRINTER_DATA_FOLDER="/usr/data/printer_data"
  PRINTER_CFG="/usr/data/printer_data/config/printer.cfg"
fi

white=`echo -en "\033[m"`
yellow=`echo -en "\033[1;33m"`
green=`echo -en "\033[01;32m"`
darkred=`echo -en "\033[31m"`

INSTALL=0
PAUSE=0
RESUME=0
STOP=0
REMOTE=""
BRANCH=""
TARGET=""
EVENTS="${EVENTS:-close_write,move,move_self,delete,create,modify}"
SLEEP_TIME=5
DATE_FMT="+%d-%m-%Y (%H:%M:%S)"
COMMITMSG="Auto-commit by Git Backup"
SKIP_IF_MERGING=0

shelp() {
    echo "Usage: $(basename "$0") [-i] [-p] [-r] [-s] -b branch -t target -g remote"
}

while getopts "iprsb:t:g:hn" option; do
    case "${option}" in
        i) INSTALL=1 ;;
        p) PAUSE=1 ;;
        r) RESUME=1 ;;
        s) STOP=1 ;;
        b) BRANCH="${OPTARG}" ;;
        t) TARGET="${OPTARG}" ;;
        g) REMOTE="${OPTARG}" ;;
        h|\?) shelp; exit 0 ;;
    esac
done

if [ "$((INSTALL + PAUSE + RESUME + STOP))" -gt 1 ]; then
    echo "Error: Only one flag is allowed at a time."
    exit 1
fi

if [ "$PAUSE" = 1 ]; then
    echo "Info: Pausing automatic backups..."
    "$INITD_FOLDER"/S52Git-Backup stop
    exit 0
elif [ "$STOP" = 1 ]; then
    echo "Info: Stopping automatic backups..."
    if [ -f "$INITD_FOLDER"/S52Git-Backup ]; then
        "$INITD_FOLDER"/S52Git-Backup stop
        mv "$INITD_FOLDER"/S52Git-Backup "$INITD_FOLDER"/disabled.S52Git-Backup
    fi
    exit 0
elif [ "$RESUME" = 1 ]; then
    echo "Info: Resuming automatic backups..."
    if [ -f "$INITD_FOLDER"/disabled.S52Git-Backup ]; then
        mv "$INITD_FOLDER"/disabled.S52Git-Backup "$INITD_FOLDER"/S52Git-Backup
    fi
    "$INITD_FOLDER"/S52Git-Backup start
    exit 0
elif [ "$INSTALL" = 1 ]; then
    # FIX: SSL-Verifizierung sofort abschalten
    git config --global http.sslVerify false

    echo "Info: Verifying required binaries..."
    if ! command -v inotifywait >/dev/null 2>&1; then
        if [ -f /opt/bin/inotifywait ]; then
            ln -sf /opt/bin/inotifywait /usr/bin/inotifywait
        else
            echo "${white}${darkred} ✗ 'inotifywait' not found. Please place it in /opt/bin/!${white}"
            exit 1
        fi
    fi
    # ==============================================================================
    # DATEN-KOPIEREN AN DEN ANFANG GEZOGEN (Damit 'remove' bei Abbruch immer funktioniert)
    # ==============================================================================
    TARGET="$PRINTER_DATA_FOLDER"/config
    
    echo "Info: Pre-copying service file to $INITD_FOLDER..."
    cp -f /usr/data/helper-script/files/git-backup/S52Git-Backup "$INITD_FOLDER"/S52Git-Backup
    
    echo "Info: Pre-copying config file..."
    mkdir -p "$TARGET"/Helper-Script
    cp -f /usr/data/helper-script/files/git-backup/git-backup.cfg "$TARGET"/Helper-Script/git-backup.cfg
    
    if grep -q "git-backup\.cfg" "$PRINTER_CFG" 2>/dev/null; then
        echo "Info: Git Backup configurations are already enabled..."
    else
        echo "Info: Adding Git Backup configurations safely to printer.cfg..."
        # SAUBERER FIX: Kein riskantes Überschreiben der Datei mehr! 
        # Wir hängen das Include einfach zerstörungsfrei ans Ende an.
        echo -e "\n[include Helper-Script/git-backup.cfg]" >> "$PRINTER_CFG"
    fi

    # ==============================================================================

    # Erst JETZT starten die interaktiven Abfragen
    echo "${white}"
    read -p " Please enter your ${green}GitHub username${white}: " USER_NAME
    while [ -z "$USER_NAME" ]; do read -p " Username: " USER_NAME; done
    
    valid_email=false
    while [ "$valid_email" != true ]; do
        read -p " Please enter your ${green}GitHub email address${white}: " USER_MAIL
        echo "$USER_MAIL" | grep -E -q "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" && valid_email=true || echo "${darkred} ✗ Invalid email!${white}"
    done
    
    read -p " Please enter your ${green}GitHub repository name${white}: " REPO_NAME
    while [ -z "$REPO_NAME" ]; do read -p " Repo name: " REPO_NAME; done
    
    read -p " Please enter your ${green}GitHub branch name${white}: " REPO_BRANCH
    while [ -z "$REPO_BRANCH" ]; do read -p " Branch name: " REPO_BRANCH; done
    
    read -p " Please enter your ${green}GitHub personal access token${white}: " GITHUB_TOKEN
    while [ -z "$GITHUB_TOKEN" ]; do read -p " Token: " GITHUB_TOKEN; done
    
    cd "$TARGET" || exit
    
    git config --global user.name "$USER_NAME"
    git config --global user.email "$USER_MAIL"
    git init
    
    # Link-freie URL-Generierung
    GITH_URL="github.com"
    PROT_PREFIX="https://"
    GITH_URL="github.com"
    PROT_PREFIX="https://"
    git remote add origin "${PROT_PREFIX}${USER_NAME}:${GITHUB_TOKEN}@${GITH_URL}/${USER_NAME}/${REPO_NAME}.git" 2>/dev/null || true
    
    # SAUBERE BRANCH-WEICHE: Verhindert doppeltes Anlegen und Abstürze
    if git show-ref --verify --quiet "refs/heads/$REPO_BRANCH"; then
        echo "Info: Branch $REPO_BRANCH already exists, switching to it..."
        git checkout "$REPO_BRANCH"
    else
        git checkout -b "$REPO_BRANCH"
        git add .
        git commit -m "Initial Backup"
    fi
    
    # ==============================================================================
    # ➔ FIX: ERZWUNGENER ONLINE-ABGLEICH (Absolut absturzsicher)
    # ==============================================================================
    echo "${white}${yellow} ℹ️ Synchronisiere lokale Klipper-Config mit GitHub...${white}"
    set +e
    git pull origin "$REPO_BRANCH" --no-rebase --allow-unrelated-histories --no-edit >/dev/null 2>&1
    git push -u origin "$REPO_BRANCH" >/dev/null 2>&1
    set -e
    # ==============================================================================
    mkdir -p "$HS_BACKUP_FOLDER"/git-backup

    ENV="$HS_BACKUP_FOLDER"/git-backup/.env
    echo "TARGET=$TARGET" > "$ENV"
    echo "GITHUB_TOKEN=$GITHUB_TOKEN" >> "$ENV"
    echo "REMOTE=$REPO_NAME" >> "$ENV"
    echo "BRANCH=$REPO_BRANCH" >> "$ENV"
    echo "USER=$USER_NAME" >> "$ENV"
    
    # Umgebungsvariablen in die S52Git-Backup eintragen
    sed -i "2i source $ENV" "$INITD_FOLDER"/S52Git-Backup
    
    echo "Info: Starting Git Backup service..."
    chmod +x "$INITD_FOLDER"/S52Git-Backup
    "$INITD_FOLDER"/S52Git-Backup start >/dev/null 2>&1
    
    # NEU: Signalisiert dem Hauptmenü den echten Installations-Erfolg
    touch /tmp/git_backup_success
    
    echo "${white}${green} ✓ Git Backup has been installed successfully!${white}"
	return 0
fi


# BACKGROUND DAEMON LOOP
stderr() { echo "$@" >&2; }
cleanup() { [ -n "$SLEEP_PID" ] && kill -0 "$SLEEP_PID" 2>/dev/null && kill "$SLEEP_PID" 2>/dev/null; exit 0; }
is_command() { command -v "$1" >/dev/null 2>&1; }
is_merging () { [ -f "$(git rev-parse --git-dir)"/MERGE_HEAD ]; }

trap "cleanup" EXIT
GIT="git"
INW="inotifywait"

IN=$(readlink -f "$TARGET")
TARGETDIR=$(echo "$IN" | sed -e "s/\/*$//")
INW_ARGS="-qmr -e $EVENTS $TARGETDIR"
GIT_ADD="git add -A ."
GIT_COMMIT_ARGS="-a"

cd "$TARGETDIR" || exit 5

if [ -n "$REMOTE" ]; then
  if [ -z "$BRANCH" ]; then PUSH_CMD="$GIT push origin"; else PUSH_CMD="$GIT push origin $BRANCH"; fi
else
  PUSH_CMD=""
fi

# BACKGROUND DAEMON LOOP - Aktiviert das automatische Live-Backup im Hintergrund
timeout() { sleep "5" & timeout_pid=$! ; trap 'kill $timeout_pid 2>/dev/null' EXIT; wait $timeout_pid 2>/dev/null; }

while true; do
  eval "$INW $INW_ARGS" | while read -r line; do
    if [ -n "$line" ]; then
      cd "$TARGETDIR" || exit 6
      STATUS=$($GIT status -s)
      if [ -n "$STATUS" ]; then
        if [ "$SKIP_IF_MERGING" -eq 1 ] && is_merging; then continue; fi
        $GIT_ADD
        $GIT commit $GIT_COMMIT_ARGS -m "$COMMITMSG"
        if [ -n "$PUSH_CMD" ]; then
          eval "$PUSH_CMD"
          killall -q inotifywait
          timeout
        fi
      fi
    fi
  done
done