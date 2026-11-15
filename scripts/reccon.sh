#!/bin/sh

set -e

function reccon_message(){
  top_line
  title 'Recovery Console (reccon)' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Installs a pre-boot recovery shell on the printer display      ${white}│"
  echo -e " │ ${cyan}(/dev/fb1). If a USB keyboard is connected during boot, boot   ${white}│"
  echo -e " │ ${cyan}pauses in an emergency shell until you type exit.              ${white}│"
  hr
  bottom_line
}

function install_reccon(){
  reccon_message
  local yn
  while true; do
    install_msg "Recovery Console (reccon)" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        if [ ! -f "$RECCON_BIN_URL" ] || [ ! -f "$RECCON_SERVICE_URL" ]; then
          error_msg "Required reccon files are missing in helper-script/files!"
          return
        fi

        echo -e "Info: Creating /usr/apps/overlay/sbin directory..."
        if ! mkdir -p /usr/apps/overlay/sbin 2>/dev/null; then
          error_msg "Could not create /usr/apps/overlay/sbin (filesystem read-only?)!"
          return
        fi

        echo -e "Info: Installing reccon binary & S39console boot service..."
        if ! cp "$RECCON_BIN_URL" "$RECCON_BIN_FILE" 2>/dev/null; then
          error_msg "Could not copy reccon binary to ${RECCON_BIN_FILE}!"
          return
        fi
        chmod 755 "$RECCON_BIN_FILE"

        if ! cp "$RECCON_SERVICE_URL" "$RECCON_SERVICE_FILE" 2>/dev/null; then
          rm -f "$RECCON_BIN_FILE"
          error_msg "Could not copy S39console service to ${RECCON_SERVICE_FILE}!"
          return
        fi
        chmod 755 "$RECCON_SERVICE_FILE"

        ok_msg "Recovery Console (reccon) has been installed successfully!"
        echo -e "   ${cyan}Tip: Connect a USB keyboard before powering on to enter the pre-boot shell.${white}"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_reccon(){
  reccon_message
  local yn
  while true; do
    remove_msg "Recovery Console (reccon)" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Removing S39console boot service & reccon binary..."
        rm -f "$RECCON_SERVICE_FILE"
        rm -f "$RECCON_BIN_FILE"
        rmdir -p /usr/apps/overlay/sbin 2>/dev/null || true

        ok_msg "Recovery Console (reccon) has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}
