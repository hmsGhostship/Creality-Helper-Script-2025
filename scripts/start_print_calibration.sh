#!/bin/sh

set -e

function start_print_calibration_message(){
  top_line
  title 'Start Print Calibration' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}The touchscreen runs a bed calibration before every print,   ${white}│"
  echo -e " │ ${cyan}but prints started from Fluidd/Mainsail silently skip it     ${white}│"
  echo -e " │ ${cyan}and reuse a stale mesh forever. This re-enables the          ${white}│"
  echo -e " │ ${cyan}vendor's own per-print calibration for browser starts.       ${white}│"
  hr
  echo -e " │ ${cyan}Cost: every browser print adds a probing step, about 50s     ${white}│"
  echo -e " │ ${cyan}with adaptive meshing, or a ~4 min full-bed probe when the   ${white}│"
  echo -e " │ ${cyan}slicer does not emit EXCLUDE_OBJECT (object labeling off).   ${white}│"
  hr
  bottom_line
}

function install_start_print_calibration(){
  start_print_calibration_message
  local yn
  while true; do
    install_msg "Start Print Calibration" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        # START_PRINT only calibrates when SDCARD_PRINT_FILE arrives with
        # NEEDCALIBRATE=1, which the touchscreen sends and Moonraker's print API
        # cannot. Shadowing the command and defaulting the parameter on re-arms
        # the vendor's calibrate branch for browser starts; the vendor's
        # power-loss resume passes NEEDCALIBRATE=0 explicitly, so resumes are
        # unaffected. FILENAME/ISCONTINUEPRINT/NEEDCALIBRATE is the command's
        # complete parameter surface, so nothing is dropped by the forward.
        #
        # Two rename_existing shadows of one command is a Klipper config error,
        # and users following the Discord mesh-load workaround may already have
        # their own block, so never stack a second one.
        if grep -q "^\[gcode_macro SDCARD_PRINT_FILE\]" "$PRINTER_CFG" ; then
          error_msg "printer.cfg already has a [gcode_macro SDCARD_PRINT_FILE] block!"
          echo -e " ${cyan}Remove the existing macro first if you want this option to manage it.${white}"
          return
        fi
        # Klipper owns everything below the SAVE_CONFIG marker and rewrites it,
        # so the macro goes in above the marker on any printer that has ever
        # run SAVE_CONFIG, and at the end of the file on one that has not.
        echo -e "Info: Adding Start Print Calibration macro in printer.cfg file..."
        awk '
          function print_block() {
            print "[gcode_macro SDCARD_PRINT_FILE]"
            print "rename_existing: SDCARD_PRINT_FILE_BASE"
            print "gcode:"
            print "    SDCARD_PRINT_FILE_BASE FILENAME=\"{params.FILENAME}\" ISCONTINUEPRINT={params.ISCONTINUEPRINT|default(0)} NEEDCALIBRATE={params.NEEDCALIBRATE|default(1)}"
          }
          !added && /^#\*#.*SAVE_CONFIG/ { if (prev != "") print ""; print_block(); print ""; added=1 }
          { print; prev=$0 }
          END { if (!added) { if (prev != "") print ""; print_block() } }
        ' "$PRINTER_CFG" > "$PRINTER_CFG.hs_tmp" && cat "$PRINTER_CFG.hs_tmp" > "$PRINTER_CFG" && rm -f "$PRINTER_CFG.hs_tmp"
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Start Print Calibration has been installed successfully!"
        echo -e " ${cyan}Browser-started prints now run the start calibration again.${white}"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_start_print_calibration(){
  start_print_calibration_message
  local yn
  while true; do
    remove_msg "Start Print Calibration" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        if grep -q "^\[gcode_macro SDCARD_PRINT_FILE\]" "$PRINTER_CFG" ; then
          echo -e "Info: Removing Start Print Calibration macro in printer.cfg file..."
          # Drops the section through its trailing blank line, so an
          # install/remove cycle leaves printer.cfg as it was rather than
          # growing a blank line each time.
          awk '
            /^\[gcode_macro SDCARD_PRINT_FILE\]/ { skip=1; next }
            skip && /^\[/ { skip=0 }
            skip && /^$/ { skip=0; next }
            skip { next }
            { print }
          ' "$PRINTER_CFG" > "$PRINTER_CFG.hs_tmp" && cat "$PRINTER_CFG.hs_tmp" > "$PRINTER_CFG" && rm -f "$PRINTER_CFG.hs_tmp"
        else
          echo -e "Info: Start Print Calibration macro is already removed in printer.cfg file..."
        fi
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Start Print Calibration has been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}
