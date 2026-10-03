# Creality Helper Script - 2025 Support

## About

This script intended for use on Creality **K1 Series** and **Ender-3 V3 Series** printers allows to add more features.

Additional support for K1 2025 CFS-C by @hmsGhostship.

### 🚀 CFS-C Edition (Automated Submodel Detection)

This modified version by @hmsGhostship introduces full automation for K1 2025 printers equipped with the Creality CFS-C material box:

* **Full Automation:** The script automatically scans your `printer.cfg` for the `mb-料盒` entry upon startup. No manual flags required.
* **Smart UI Branching:** If the material box is active, the script seamlessly switches to the customized `K1_2025_CFS-C` menu layout.
* **Reversible & Safe:** Includes a built-in safety switch under **[Customize Menu] -> Option 8** to instantly remove the detection and revert back to the stock `K1_2025` layout if the CFS-C is disconnected.

### 🛠️ Hardware & Calibration Optimizations

This repository is tailored and tested for advanced hardware modifications:

* **Phaetus DXC Extruder Integration:** Fully compatible with custom extruder configurations and fine-tuned macro settings.
* **MicroSwiss FlowTech Hotend Patch:** Available in the **Customize Menu**, this patch fixes crucial multi-material issues. It eliminates the 20% empty extrusion inside the Purge Tower during toolchanges and optimizes the filament feeding speed. This prevents torn lines, stabilizes the Purge Tower structure, and dramatically reduces material waste by allowing a much smaller tower size. 
  * *⚠️ Note: This specific patch is strictly verified and tested for the combination of the MicroSwiss FlowTech Hotend and the Phaetus DXC Extruder only!*
* **Creality Calibration Toolbox (Bed Mesh):** Optimized paths and enhanced support for precise Bed Mesh calibrations, ensuring perfect first layers with advanced probing.

### ⚙️ Orca Slicer Configuration & Tips (v2.5.0_dev & Phaetus DXC)

Recommended machine and profile settings for optimal integration with the CFS-C Multi-Material system:

#### 1. Machine Start G-code
Copy and paste the following macro into your Orca Slicer Printer Settings -> **Machine Start G-code**:

```gcode
; --- START MELODY AND SYSTEM READY ---
MUSIC_TO_START
BOX_ENABLE_CFS_PRINT ENABLE=1

; --- CORRECT 2025 CFS-C MAPPING LINE ---
BOX_MODIFY_TN T[initial_no_support_extruder]=T[initial_no_support_extruder]

; --- ORIGINAL CREALITY START CHAIN ---
START_PRINT EXTRUDER_TEMP=[nozzle_temperature_initial_layer] BED_TEMP=[bed_temperature_initial_layer_single]

T[initial_no_support_extruder]
M204 S2000
M104 S[nozzle_temperature_initial_layer]
G1 Z3 F600
M83
G92 E0
G1 Z1 F600
```

#### 2. Change Filament G-code
* Leave this field completely **empty** (clear all text).

#### 3. Template Custom G-code
* Leave this field completely **empty** (clear all text).

#### 4. Flushing Volumes & Multiplier
* To drastically save material while maintaining clean color transitions, open the **Flushing Volumes** configuration in Orca Slicer.
* Set the **Flush multiplier** to a minimal value of **`0.4`** and recalculate. This prevents color bleeding on critical switches (e.g., Black to White) without wasting filament on giant purge towers.

---
*Disclaimer: This software is provided "as is" without warranty of any kind. Use it at your own risk.*



Additional support for K1 2025 by @C0DEbrained.

## Retire Nexusp Backend (K1C 2025)

The K1C 2025 runs **two Moonrakers against one Klipper**: Creality's forked
`nexusp` on `:7125` (the touchscreen's backend) and this script's real Moonraker
on `:7126`. They share `-d /usr/data/printer_data`, so one gcode directory and
one klippy socket, but Creality namespaced the databases.

That split is not merely redundant. Querying the wrong port does not fail — **it
answers**:

```sh
curl -s http://<printer>:7125/server/spoolman/status
# nexusp -> {"error": {"code": 404, "message": "Method not found"}}
```

Read at face value that says Spoolman was never connected on this printer. It is
wrong, and every command pasted from a Klipper forum at `:7125` hits it.

**Customize menu → Retire Nexusp Backend** turns nexusp off and moves the real
Moonraker to `:7125`, the port the rest of the Klipper ecosystem assumes. It is
opt-in and off by default. The touchscreen is never patched — `vectorp`
hardcodes `http://127.0.0.1:7125`, and what answers there becomes ours.

The option:

- merges the two print histories before anything is disabled, so the screen does
  not lose everything printed before this script was installed;
- installs a small Moonraker component implementing the two JSON-RPC methods the
  screen calls and stock Moonraker does not have
  (`server.files.get_directory_ex` and `server.history.count`);
- offers to install Pillow into Moonraker's virtualenv. Pillow is **not** in the
  Moonraker this script ships, and Moonraker's own thumbnail parser needs it —
  without it a freshly uploaded file has no thumbnail on the screen at all;
- renames the nexusp init script rather than deleting anything.

**Restore Nexusp Backend** undoes all of it, and merges the prints made while
nexusp was retired back into its database first — otherwise the touchscreen's
history would silently stop at the day you retired it.

### Caveats

- **A firmware update can put the nexusp service file back.** `/usr/apps/etc/init.d`
  survives a factory reset, but an OTA can recreate `CS56nexusp_service` beside
  the disabled copy. It then loses the race for `:7125` to Moonraker and dies
  silently at every boot. The Information menu reports this with `~`, and
  running Retire Nexusp Backend again repairs it.
- **For about four seconds after a cold boot** the screen polls two methods
  (`printer.info`, `printer.objects.list`) that Moonraker only registers once
  Klipper connects. It resolves itself and needs no action.
- Two of the four Creality-only RPC methods are deliberately not implemented:
  `server.history.debug.job` and `server.debug.status`. Neither is
  screen-facing.
- **The two shimmed methods answer over the websocket only.** `curl
  http://<printer>:7125/server/files/get_directory_ex` returns 404 by design —
  that is what nexusp did, and matching it is the point. Note that this 404 is
  identical to the one you get when the component is not loaded at all, so it
  is not a way to check. To confirm the shim is live:

  ```sh
  curl -s http://<printer>:7125/server/info
  ```

  and look for `creality_compat` in `components` (and *not* in
  `failed_components`).

### Running the tests

Everything ships with tests beside it. They are the executable record of what
was measured against `nexusp` before it was switched off — once it is retired
those measurements cannot be re-derived without reviving it. No printer, no
Moonraker, no network:

```sh
python3 -m pytest -q
```

That runs both suites: the Moonraker component and history merge under
`files/moonraker/creality-compat/`, and the shell option under `tests/`. The
component suite also runs standalone from its own directory with no conftest.

The shell tests exercise `sed -i` the way the printer does, which is GNU/busybox
syntax; on macOS they skip unless `gsed` is installed (`brew install gnu-sed`).

This repository has no CI, so nothing runs any of this automatically.
