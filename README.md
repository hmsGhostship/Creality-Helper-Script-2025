# Creality Helper Script - 2025 (CFS-C) Support

## About

This script is intended only for Creality K1 (2025 Series) printers and allows you to add more features. (Not compatible with older K1 models or the Ender-3 V3 series.)

Additional support for K1 2025 CFS-C by @hmsGhostship.

> **⚠️ Firmware Compatibility Note:** All features, patches, and CFS-C options in this repository have currently only been tested on **Creality Firmware Version `1.1.0.27`**. Newer Creality firmware updates may change internal files, services, or Klipper bytecode—always create an **OTA-Safe State Backup** (option `5` in the Backup & Restore menu or via the `BACKUP_OTA_STATE` macro, ideally with a USB drive attached) before updating.

## 📋 / ✅ Prerequisites and installation

1. **Install a root exploit**
   Choose one of the following methods depending on your setup:
   * **Web-based Method (Recommended):** [Codebrained Creality-2025-Web-Exploit](https://github.com/C0DEbrained/Creality-2025-Web-Exploit) (Runs directly from your browser over LAN)
   * **Local Python Method:** [Codebrained K1C 2025 Root Exploit Gist](https://gist.github.com/C0DEbrained/c6f508109e34f43a39f4c22e901408dd) (Requires a local Python environment and an SSH key)

   *⚠️ **Note:** Rooting your printer is done at your own risk. Please read the security guidelines and trust models in the respective repositories carefully.*

2. Install Entware:

```bash
wget -O- https://raw.githubusercontent.com/hmsGhostship/Creality-Helper-Script-2025/main/entware/install_entware.sh | sh
```

and then restart the printer.

3. Clone the 2025 CFS-C Helper-Script Repo

```bash
git clone --depth 1 https://github.com/hmsGhostship/Creality-Helper-Script-2025.git /usr/data/helper-script
```

4. Run the helper script:

```bash
sh /usr/data/helper-script/helper.sh
```

### 🔄 Updating the Helper-Script & Addons

* **Via Mainsail / Fluidd (Moonraker Update Manager):** Open **Machine / System -> Update Manager**, click **Check for Updates**, and update **Creality-Helper-Script** directly from the web UI.
* **Via SSH Main Menu:** Launch `sh /usr/data/helper-script/helper.sh` and press **`u` (`Update Helper-Script`)** to fetch the latest commits (`git fetch` + `reset --hard`) and reload the menu immediately.
* **Applying Web Addon Updates:** After pulling updates to `/usr/data/helper-script`, re-run the respective installer option (e.g., **CFS-C Web Addon** or **Material Database Editor**) so updated frontend files are copied to Mainsail, Fluidd, and `/usr/data/cfs-material-editor/`, then press **Ctrl + F5** in your browser.

### 💾 Backup, Restore & Options Profiles (`Backup & Restore Menu`)
* **OTA-Safe State Backup & Restore (Options `5` & `6` / `BACKUP_OTA_STATE` macro):** Saves configs, Moonraker databases, custom Klipper extras (`box_control.pyc`, `cfs_material_db.py`, shell commands), system overlays (`reccon`, `mdev.conf`, crontabs), and disabled service states to `/usr/data` and/or an attached **USB drive** (with automatic `sync` for safe removal). Supports **Safe Merge** (keeps new stock firmware configs and merges `[include ...]` & `SAVE_CONFIG` values) or **Full Overwrite**.
* **Installed Options Profile Backup & Selective Restore (Options `9` & `10`):** Scans all active modules from the Info Menu (separately for **CFS-C** and **Standard / Non-CFS**) and reinstalls missing or selected modules in **strict dependency order**—including automatic cross-variant upgrade/adapt merging (`Non-CFS ↔ CFS-C`).
* **Automatic Pre-Helper-Script Factory Baseline (Option `11`):** On a pristine printer, the very first launch of `helper.sh` automatically captures an immutable snapshot of your original configs, Klipper extras, system services, and file manifests (`/usr/data/helper-script-factory-baseline/`). If a baseline snapshot exists (locally or on a USB drive), **Option `11`** appears in the Backup & Restore Menu and allows a full, clean revert back to the pre-helper-script state (removing all added `.py` modules, services, Entware, and web frontends while keeping root access and Wi-Fi intact). *(Tip: Copy `/usr/data/helper-script-factory-baseline` to a USB drive after the first run, especially when testing on older firmware revisions like `1.0.0.25` or Non-CFS setups.)*


### 🚀 CFS-C Edition (Automated Submodel Detection)

This modified version by @hmsGhostship introduces full automation for K1 2025 printers equipped with the Creality CFS-C material box:

* **Full Automation:** The script automatically scans your `printer.cfg` for the `mb-料盒` entry upon startup. No manual flags required.
* **Smart UI Branching:** If the material box is active, the script seamlessly switches to the customized `K1_2025_CFS-C` menu layout.
* **Reversible & Safe:** Includes a built-in safety switch under **[Customize Menu] -> Option 12** to instantly remove the detection and revert back to the stock `K1_2025` layout if the CFS-C is disconnected.

### 🖥️ CFS-C Mainsail/Fluidd Panel Integration (Tools menu > options 20 - 23)

This custom module integrates a native, high-performance CFS multi-material control panel directly into your active Mainsail or Fluidd web interface.

<img width="660" height="624" alt="grafik" src="https://github.com/user-attachments/assets/4e570ea7-49dd-487a-b062-a05adde4321b" />

It completely bypasses the legacy port `9999` socket by communicating directly with the Klipper core and the modern Moonraker database API (`:7125`), making it fully compatible with next-gen 2025/2026 mainboard architectures.

* **Cycle-Aware UI Lock:** Automatically detects complex multi-material physical sequences (nozzle heating -> cutting via side-buffer -> retracting -> purging) and prevents premature interface unlocking. Buttons are strictly kept frozen until Klipper returns to a true `Idle` state.
* **Dual-Engine Polling:** Monitors Klipper's `idle_timeout` and the `color_box` namespace simultaneously to achieve perfect synchronization between hardware status and browser feedback.
* **Granular Control:** Safely install or remove the interface integration independently for Mainsail, Fluidd, or both via the Customize Menu without risking any system configuration mismatches.
* **Live Material Database Sync:** Automatically fetches your active printer material database (`material_database.json` via the CFS-C Material Database Editor on port `8088`) so all custom `90001+` profiles, vendors, and temperature limits are immediately selectable in the slot **Edit Material** dropdown (with seamless fallback to built-in presets).
* **Native Material DB Editor Modal (`Material DB` button):** When the CFS-C Material Database Editor service (`:8088`) is active, a **Material DB** button automatically appears next to **Purge Settings** in both **Mainsail** and **Fluidd**, opening the complete database editor in a large native overlay modal and refreshing all slot dropdowns automatically when closed.
* **Automatic Multi-Language Support (21 Languages):** Automatically detects the active UI locale in both **Mainsail** and **Fluidd** and live-translates the CFS-C panel, controls, and `Map & Print` dialog across all 21 Mainsail/Fluidd languages (`en`, `de`, `fr`, `es`, `it`, `nl`, `pl`, `cs`/`cz`, `sk`, `sl`, `da`, `sv`/`se`, `ca`, `hu`, `pt`, `ru`, `uk`, `tr`, `zh`, `ja`, `ko`).
* **Estimated Remaining Filament Display (RFID Spools):** Displays a color-matched progress bar with remaining percentage (`%`) and estimated weight (`~g`) directly on each slot card whenever a verified RFID spool (`editable: 0` with valid `total_len`) is loaded, while staying cleanly hidden for manual non-RFID spools.
* **Creality-Print-Style `Map & Print` & Slicer Upload Gate (`k1c-cfs-map.js`):** Automatically installed alongside the Mainsail/Fluidd CFS-C addon as a unified 50/50 split pill (**`Map & Print` | `Open on Print` / `Only on Mismatch`**):
  * **Automatic G-Code & Live Slot Matching:** Parses all filaments actually used in the selected G-Code (material type and slicer color) and auto-assigns them to the closest matching loaded CFS channel (`1A`–`1D`) by RGB color distance and compatible material (`PLA`, `Hyper PLA`, `PLA+`, `PETG`, `ABS`, `ASA`, `TPU`, etc.), independent of slicer tool order or slot position.
  * **Pre-Start Slicer Upload Gate & Missing-Material Safety Net:** Intercepts slicer uploads (`Send & Print` from OrcaSlicer / Creality Print) before Klipper starts printing. In **`Open on Print`** mode, the mapping dialog always opens before printing; in **`Only on Mismatch`** mode, matching spools start immediately while any missing filament automatically holds the print and opens the mapping dialog with a warning banner until a valid slot is loaded or selected.
  * **Printer-Synced Mode Switch & FLY-LLL Plus Compatibility:** The **`Open on Print` / `Only on Mismatch`** toggle is synchronized server-side across all connected browsers and devices. When `nexusp` / CFS macros are deactivated (e.g. via **FLY-LLL Plus** `NEXUSP_OFF_EXTERNAL_SPOOL`), the auto-open gate pauses automatically; users printing from an external spoolholder without FLY-LLL Plus can simply switch the toggle to **`Only on Mismatch`**.
* **Pre-Print Filament Guard (`Option 21` – Klipper Safety Net):** Validates loaded CFS materials directly inside Klipper before print execution, protecting prints started outside the web browser (e.g., directly from the printer touchscreen or print history) while seamlessly honoring slot assignments already confirmed via `Map & Print`.

> 💡 *Note: After installing or removing the addon, please perform a hard reload (**Ctrl + F5**) in your web browser to force Chrome to load the newly injected script tags.*

### 🧠 C13 / X2600 RAM Guard & Remote Access Stability

Specifically engineered for the tight memory budget of 2025/2026 K1C mainboards:

* **3-Tier RAM Guard & Live Menu Status:** Displays live available memory in all menus and validates free RAM before installing memory-intensive services to prevent OOM crashes.
* **Shared Python Runtime:** **OctoEverywhere (Option 25)** and **Mobileraker Companion (Option 28)** reuse Moonraker's active Python environment (`$active_python`), saving ~15–20 MB of permanent RAM.
* **OctoEverywhere & Camera Sync:** Includes **Option 25a** to view or regenerate the pairing code at any time, plus automatic camera stream routing (`/webcam3/` for USB, `/webcam/` for built-in).
* **Native X2600 GuppyScreen Support (`K1_2025`):** Supports both `goodix-ts` and `Hua Que` touchscreens and dynamically detects the active Moonraker port (`:7126` or `:7125`).

### 📷 Flexible Camera Architecture (Built-in, USB, Go2rtc & Creality Print)

The K1 2025 camera subsystem supports multiple simultaneous workflows while protecting `/dev/video0` and `/dev/video2` from hardware conflicts:

* **Recommended Low-RAM Dual-Camera Setup (~3 MB per stream):** Install **Built-in Camera Fix** (`/webcam/`, `/dev/video0`) and **USB Camera Support** (`/webcam3/`, `/dev/video2`) via `mjpg-streamer`. This leaves ~49 MB of free RAM so **Mainsail/Fluidd**, **Moonraker Timelapse**, and **OctoEverywhere** run simultaneously without OOM risk.
* **Keep Creality Print Camera + Mainsail USB Camera:** Leave Creality's local WebRTC daemon (`thirteenthp`) enabled for **Creality Print** on `/dev/video0` and run **USB Camera Support** (or **Go2rtc** in USB mode) on `/dev/video2` for Mainsail/Fluidd and OctoEverywhere.
* **Selectable Go2rtc Streaming (`Option 6`):** Choose at install time whether **Go2rtc** binds to the **Built-in Chassis Camera** (`/dev/video0`) or a **USB Camera** (`/dev/video2`). Includes a **35 MB RAM check** (`Go2rtc + ffmpeg`) and mutual conflict guards across all install/remove menus.
* **Granular Stock Service Restoration:** **Restore Creality Stock Services** lets you restore `alchemistp` (telemetry), `onyxp` (Creality Cloud WebRTC), and `thirteenthp` (local Creality Print WebRTC) individually, and offers a one-click reboot prompt to re-initialize the `/dev/video0` driver cleanly.

### 🛠️ Hardware & Calibration Optimizations

This repository is tailored and tested for advanced hardware modifications:

* **Phaetus DXC Extruder Integration:** Fully compatible with custom extruder configurations and fine-tuned macro settings.
* **CFS-C Purge Volume Fix (Prime Tower):** Available in the **Install Menu**, this patch fixes under-extrusion and empty extrusion inside the Prime Tower during toolchanges by adjusting the purge volume (`E40`) and feeding velocity (`120 mm/min`) in `box.cfg`. This prevents torn lines, stabilizes the Prime Tower structure, and reduces material waste across both stock and aftermarket hotends.
* **Creality Calibration Toolbox (Bed Mesh & Native Adaptive Mesh):** Integrates Creality's original **Adaptive Bed Mesh** directly into the Calibration Toolbox. You can easily switch between **Original (Full Mesh)**, **Adaptive Bed Mesh**, or **Disabled** directly from the interface, ensuring fast, localized probing and precise first layers.
* **CFS-C Material Database Editor (live-synced with Mainsail/Fluidd `Edit Material` dropdown & Touchscreen) (Port 8088):** Available in the **Install Menu (Option 20)** for CFS-C setups, this lightweight web editor lets you add, clone, edit, and back up custom filament brands and temperatures directly in `material_database.json`—automatically syncing them to both the Creality Touchscreen and Mainsail/Fluidd. See the full [CFS-C Material Database Editor Guide](docs/CFS_MATERIAL_EDITOR.md).

### ⚡ CFS-C Speed Fix (High Back-Pressure & Grinding Prevention)

By default, the Creality CFS-C multi-material engine feeds the filament too aggressively into the hotend during the loading cycle. When dealing with high volumetric melting restrictions, this rapid feeding creates severe **High Back-Pressure** inside the melt zone. As a result, the dual-drive gears lose traction, causing destructive **Filament Grinding** and irreversible toolchange jams.

The **CFS-C Speed Fix** micro-tunes and deliberately slows down the initial feeding and loading speeds inside the hotend context. By introducing a controlled, synchronized feed rate, it gives the hotend sufficient time to melt the incoming material safely. This entirely eliminates back-pressure spikes and safeguards your extruder gears against grinding.

* **Anti-Grinding Logic:** Slows down the final loading segment to prevent the extruder gears from chewing into the filament strand.
* **Back-Pressure Relief:** Drastically reduces structural tension within the heatbreak and nozzle assembly during toolchanges.
* **Increased Success Rate:** Maximizes multi-material reliability on complex, long-term prints by eliminating feed-line mechanical stress.
* **Hardware Protection:** Specifically optimized to maintain perfect structural harmony between the custom feeder lines and the hotend.

### 📐 Universal Creality Calibration Toolbox (Nexusp + Native Klipper + Slicer Control)

The **Creality Calibration Toolbox** (`Tools Menu`) automatically detects whether Creality's `nexusp` backend is running (`nexusp=1` on stock & `K1_2025_CFS-C` setups, or `nexusp=0` after `Retire Nexusp Backend`) and routes bed leveling accordingly:

* **Web UI Macro Button (`A_BED_MESH_CALIB`):** Cycles directly in Mainsail/Fluidd between **`🟥 OFF`**, **`🟩 ORIGINAL`** (full bed mesh), and **`🟦 ADAPTIVE`** (adaptive bed mesh) and persists the state across reboots.
* **Optional Slicer Start G-Code Control:** You can optionally control the bed mesh mode per print profile directly from your slicer (e.g., OrcaSlicer) by passing `MESH=OFF`, `MESH=FULL`, or `MESH=ADAPTIVE` to `START_PRINT` (e.g., `START_PRINT ... MESH=ADAPTIVE`), or by calling `SET_CALIB_MODE MODE=OFF|FULL|ADAPTIVE`.
* **Important Note for `nexusp` / `K1_2025_CFS-C` Setups:** When `nexusp` is active (`nexusp=1`), Creality's engine evaluates `SDCARD_PRINT_FILE` before `START_PRINT` runs. Therefore, passing `MESH=ADAPTIVE` or `MESH=FULL` via `START_PRINT` in your slicer start G-code will only take effect if the **`A_BED_MESH_CALIB`** button in the Web UI is set to **`🟥 OFF`** (if the button is set to `ORIGINAL` or `ADAPTIVE`, the Web UI button takes precedence).


### ⚙️ Orca Slicer Configuration & Tips (v2.5.0_dev & Phaetus DXC)

Recommended machine and profile settings for optimal integration with the CFS-C Multi-Material system:

#### 1. Machine Start G-code

#### A. For CFS-C (nexusp running)
Copy and paste the following macro into your Orca Slicer Printer Settings -> **Machine Start G-code**:

```gcode
; --- START MELODY AND SYSTEM READY ---
MUSIC_TO_START
BOX_ENABLE_CFS_PRINT ENABLE=1

; --- CORRECT 2025 CFS-C MAPPING LINE ---
BOX_MODIFY_TN T[initial_no_support_extruder]=T[initial_no_support_extruder]

; --- OPTIONAL: OVERRIDE BED MESH FROM SLICER ---
; IMPORTANT: When nexusp is active (K1_2025_CFS-C / Stock), A_BED_MESH_CALIB in the Web UI
; MUST be set to OFF before starting the print, otherwise nexusp triggers the Web UI setting first!
; Option A (Per-print override via START_PRINT):
; START_PRINT EXTRUDER_TEMP=[nozzle_temperature_initial_layer] BED_TEMP=[bed_temperature_initial_layer_single] MESH=ADAPTIVE
; Option B (Switch Web UI button state for subsequent prints):
; SET_CALIB_MODE MODE=ADAPTIVE

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

#### B. For Native Klipper (nexusp not running)

```gcode
; --- START MELODY ---
MUSIC_TO_START

; --- OPTIONAL: OVERRIDE BED MESH FROM SLICER ---
; IMPORTANT: When nexusp is active (Stock K1C 2025), A_BED_MESH_CALIB in the Web UI
; MUST be set to OFF before starting the print (not needed if nexusp is retired)!
; Option A (Per-print override via START_PRINT):
; START_PRINT EXTRUDER_TEMP=[nozzle_temperature_initial_layer] BED_TEMP=[bed_temperature_initial_layer_single] MESH=ADAPTIVE
; Option B (Switch Web UI button state for subsequent prints):
; SET_CALIB_MODE MODE=ADAPTIVE

; --- ORIGINAL CREALITY START CHAIN ---
START_PRINT EXTRUDER_TEMP=[nozzle_temperature_initial_layer] BED_TEMP=[bed_temperature_initial_layer_single]

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
* Tip: Set the **Flush multiplier** to a minimal value of **`0.4`-`0,8`** and recalculate, to prevents color bleeding on critical switches (e.g., Black to White) without wasting filament on giant purge towers.

#### 5. Layer change G-Code (Required for time-lapse recordings)
To ensure the hardware-optimized snapshot engine triggers seamlessly at every layer change, insert the following macro into the **Layer change G-code** field. If there are existing entries, place this command on a new line directly after them:

```gcode
TIMELAPSE_TAKE_FRAME
```

> ⚠️ **Crucial Operational Note:** By default, the timelapse engine initializes in a secure **Deep Sleep (OFF)** state upon printer boot to prevent any unwanted or accidental background recordings. Before starting a print where you want a timelapse video to be generated, you **MUST** click the **`TIMELAPSE_LAYER_CONTROL`** button on your Mainsail/Fluidd dashboard once. This will un-toggle the safety block and confirm via the console: `Timelapse: Layer changing snapshots 🟩 ENABLED 🟩`.

---
*Disclaimer: This software is provided "as is" without warranty of any kind. Use it at your own risk.*

### 🔄 OTA-Safe Helper-Script State Backup & Restore (`Backup & Restore Menu`)

To survive Creality OTA firmware updates without manually reconfiguring services:

* **Option 5 – Backup Helper-Script State (OTA Safe):** Saves a compact snapshot (~70 KB) of your Klipper/Moonraker configs, Moonraker database, custom `init.d` scripts, active camera mode, and disabled Creality stock services to `/usr/data/helper-script-ota-backup/`.
* **Option 6 – Restore Helper-Script State (After FW Update):** Automatically backs up the new firmware's default configs first, then lets you choose between **Safe Merge Mode** (preserves Creality's updated `printer.cfg` / `box.cfg` while re-injecting your `Helper-Script/` files and `[include]` lines) or **Full Restore**, re-applies your disabled stock services, and offers a one-click reboot.
* **Option 7 & 8 – `BACKUP_OTA_STATE` Klipper Macro (`Backup & Restore Menu`):** Installs or removes a dedicated `BACKUP_OTA_STATE` macro (powered by `gcode_shell_command`) so you can trigger an OTA-safe Helper-Script snapshot directly from Mainsail/Fluidd with live console progress (blocked automatically while a print is active).

### 🧩 Exclusive `K1_2025` (Non-CFS / Native Klipper) Features

When running a standard **`K1_2025`** (without CFS-C) and **`Retire Nexusp Backend`** is active (native Moonraker on `:7125`), three additional tuning and workflow packages are unlocked in the **Install / Remove Menus** (intentionally hidden on `K1_2025_CFS-C` and incompatible with stock `nexusp`):

* **Fans Control Macros (`Option 20`):** Restores full manual and slicer-driven control (`M106`, `M141`, `M191`) over part cooling, side auxiliary, and chamber exhaust fans on the 2025 mainboard.
* **Improved Shapers Calibrations (`Option 21` – C13 / X2600 Low-RAM Edition):** Adds `BELTS_SHAPER_CALIBRATION`, `INPUT_SHAPER_CALIBRATION`, and `TEST_RESONANCES_GRAPHS` with lightweight SVG resonance plots stored directly under `Helper-Script/improved-shapers/graphs/` (no heavy `matplotlib`/`numpy` install required) and automatic temporary pausing of companion daemons during calibration to stay safely within the 200 MB RAM budget.
* **M600 Filament Change Support (`Option 22`):** Provides a complete `M600` filament-change workflow with safe front-right parking, fan/heater state restoration, full compatibility with both the stock filament sensor and the **Phaetus DXC** extruder sensor (`dxc_sensor.cfg`), and an interactive Mainsail/Fluidd popup (`UNLOAD`, `LOAD`, `PURGE`, `RESUME`, `CANCEL`).
* **Automatic Nexusp Restore Guard:** Running **Restore Nexusp Backend** automatically detects and cleanly uninstalls **Options 20, 21, 22**, and the **`BACKUP_OTA_STATE`** macro before switching back to Creality's `nexusp` service so stock firmware startup cannot crash.

### 🔄 FLY-LLL Plus Safety & Auto-Switch (PD7) (`Install / Remove Menu -> Option 16`)

Unified 1-click installation and removal for the **FLY-LLL Plus** external buffer/filament sensor (`^PD7`, requires a **Toolhead Filament Sensor** such as the **Phaetus DXC Extruder** or an extruder-top inline microswitch on the Nozzle PCB — see `files/cfs-lll-plus-safety/firmware/README.md` for alternatives):

* **Hardware Wiring & Common Ground Requirement:** Connect the freed toolhead **`PD7`** signal line to the **Signal / Out** pin of the FLY-LLL Plus filament sensor. **Important:** The FLY-LLL Plus power supply and the printer mainboard/toolhead **`GND (-)`** **must share a common ground (same reference potential)** to prevent floating signals or hardware damage.
* **Smart Fail-Safe Boot Detection (`K1_2025_CFS-C`):** At power-on, `_LLL_BOOT_NEXUSP_EVAL` & `lll_nexusp_guard.sh` check `lll_plus_sensor` (`^PD7`). If filament is already inserted in the FLY-LLL Plus, `nexusp` remains paused (preventing the CFS-C from feeding its slots) and plays a distinctive **4-tone startup fanfare** (`LLL_EXTERNAL_SPOOL_READY_SOUND`). When the FLY-LLL Plus is empty at boot, `nexusp` starts normally for CFS-C operation.
* **One-Click Live Switching (`NEXUSP_OFF_EXTERNAL_SPOOL` / `NEXUSP_ON_CFS` / `TOGGLE_NEXUSP` / `NEXUSP_STATUS`):** Switch modes at any time in Mainsail/Fluidd without rebooting. When switching to External Spool while CFS-C filament is still loaded in the extruder, `NEXUSP_OFF_EXTERNAL_SPOOL` automatically holds the nozzle temperature (`>= 240 °C`), executes `BOX_RETRUDE_MATERIAL`, verifies completion (`T1.filament = None` and extruder sensor empty), pauses `nexusp`, and plays the 4-tone confirmation fanfare. (Blocked automatically if external filament is still present in `^PD7`.)
* **Standard `K1_2025` (Non-CFS) Support:** Installs a dedicated, lightweight runout sensor configuration (`lll_plus_sensor_nocfs.cfg`) on `^PD7` that cleanly triggers `PAUSE` during active prints when the external spool runs out.

<br>
<hr style="height: 4px; background-color: #7f8c8d; border: none; border-radius: 2px;">
<br>

Additional support for standard `K1_2025` (non-CFS) by @C0DEbrained.

> 💡 **Scope & Hardware Validation Note for `K1_2025` & `K1_2025_CFS-C` Users:** This fork automatically detects whether a CFS-C unit is present and supports both **`K1_2025_CFS-C`** and standard **`K1_2025`** (non-CFS) printers. Both branches — including `@C0DEbrained`'s `Retire Nexusp Backend`, the `K1_2025`-exclusive macro packages (`Options 20–22`), camera auto-routing, and OTA Backup/Restore — have been live-tested on physical K1C 2025 hardware and work seamlessly together. **(Do not use `Retire Nexusp Backend` on `K1_2025_CFS-C` printers.)**

---

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
