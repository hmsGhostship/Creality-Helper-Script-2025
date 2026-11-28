# CFS-C Web Integration, Calibration & Hardware Mods

### 🖥️ CFS-C Mainsail/Fluidd Panel Integration (Tools menu > options 20 - 23)

This custom module integrates a native, high-performance CFS multi-material control panel directly into your active Mainsail or Fluidd web interface.

<img width="660" height="624" alt="grafik" src="https://github.com/user-attachments/assets/4e570ea7-49dd-487a-b062-a05adde4321b" />

It completely bypasses the legacy port `9999` socket by communicating directly with the Klipper core and the modern Moonraker database API (`:7125`), making it fully compatible with next-gen 2025/2026 mainboard architectures.

* **Cycle-Aware UI Lock:** Automatically detects complex multi-material physical sequences (nozzle heating -> cutting via side-buffer -> retracting -> purging) and prevents premature interface unlocking. Buttons are strictly kept frozen until Klipper returns to a true `Idle` state.
* **Dual-Engine Polling:** Monitors Klipper's `idle_timeout` and the `color_box` namespace simultaneously to achieve perfect synchronization between hardware status and browser feedback.
* **Granular Control:** Safely install or remove the interface integration independently for Mainsail, Fluidd, or both via the Customize Menu without risking any system configuration mismatches.
* **Live Material Database Sync:** Automatically fetches your active printer material database (`material_database.json` via the CFS-C Material Database Editor on port `8088`) so all custom `90001+` profiles, vendors, and temperature limits are immediately selectable in the slot **Edit Material** dropdown (with seamless fallback to built-in presets).
* **Native Material DB Editor Modal (`Material DB` button):** When the CFS-C Material Database Editor service (`:8088`) is active, a **Material DB** button automatically appears next to **Purge Settings** in both **Mainsail** and **Fluidd**, opening the complete database editor in a large native overlay modal and refreshing all slot dropdowns automatically when closed. Custom `90001+` profiles automatically bump the database version timestamp so they can be pulled directly over SSH into [CFS RFID (DnG-Crafts/K2-RFID)](https://github.com) to write custom **MIFARE Classic 1K** spool tags.
* **Automatic Multi-Language Support (21 Languages):** Automatically detects the active UI locale in both **Mainsail** and **Fluidd** and live-translates the CFS-C panel, controls, and `Map & Print` dialog across all 21 Mainsail/Fluidd languages (`en`, `de`, `fr`, `es`, `it`, `nl`, `pl`, `cs`/`cz`, `sk`, `sl`, `da`, `sv`/`se`, `ca`, `hu`, `pt`, `ru`, `uk`, `tr`, `zh`, `ja`, `ko`).
* **Estimated Remaining Filament Display (RFID Spools):** Displays a color-matched progress bar with remaining percentage (`%`) and estimated weight (`~g`) directly on each slot card whenever a verified RFID spool (`editable: 0` with valid `total_len`) is loaded, while staying cleanly hidden for manual non-RFID spools.
* **Creality-Print-Style `Map & Print` & Slicer Upload Gate (`k1c-cfs-map.js`):** Automatically installed alongside the Mainsail/Fluidd CFS-C addon as a unified 50/50 split pill (**`Map & Print` | `Open on Print` / `Only on Mismatch`**):
  * **Automatic G-Code & Live Slot Matching:** Parses all filaments actually used in the selected G-Code (material type and slicer color) and auto-assigns them to the closest matching loaded CFS channel (`1A`–`1D`) by RGB color distance and compatible material (`PLA`, `Hyper PLA`, `PLA+`, `PETG`, `ABS`, `ASA`, `TPU`, etc.), independent of slicer tool order or slot position.
  * **Pre-Start Slicer Upload Gate & Missing-Material Safety Net:** Intercepts slicer uploads (`Send & Print` from OrcaSlicer / Creality Print) before Klipper starts printing. In **`Open on Print`** mode, the mapping dialog always opens before printing; in **`Only on Mismatch`** mode, matching spools start immediately while any missing filament automatically holds the print and opens the mapping dialog with a warning banner until a valid slot is loaded or selected.
  * **Printer-Synced Mode Switch & FLY-LLL Plus Compatibility:** The **`Open on Print` / `Only on Mismatch`** toggle is synchronized server-side across all connected browsers and devices. When `nexusp` / CFS macros are deactivated (e.g. via **FLY-LLL Plus** `NEXUSP_OFF_EXTERNAL_SPOOL`), the auto-open gate pauses automatically; users printing from an external spoolholder without FLY-LLL Plus can simply switch the toggle to **`Only on Mismatch`**.
  * **Required Slicer Host/Port Configuration (`:4409` / `:4408`):** Because `k1c-cfs-map.js` runs inside the browser web interface, the automatic pre-start **`Map & Print`** upload gate only intercepts `Send & Print` jobs when **OrcaSlicer** is configured to connect to the **Mainsail (`http://<printer-ip>:4409`)** or **Fluidd (`http://<printer-ip>:4408`)** frontend ports (rather than raw Moonraker API ports `:7125` / `:7126`).
* **Pre-Print Filament Guard (`Option 21` – Klipper Safety Net):** Validates loaded CFS materials directly inside Klipper before print execution, protecting prints started outside the web browser (e.g., directly from the printer touchscreen or print history) while seamlessly honoring slot assignments already confirmed via `Map & Print`.

> 💡 *Note: After installing or removing the addon, please perform a hard reload (**Ctrl + F5**) in your web browser to force Chrome to load the newly injected script tags.*

---

### 🛠️ Hardware & Calibration Optimizations

This repository is tailored and tested for advanced hardware modifications:

* **Phaetus DXC Extruder Integration:** Fully compatible with custom extruder configurations and fine-tuned macro settings.
* **CFS-C Purge Volume Fix (Prime Tower):** Available in the **Install Menu**, this patch fixes under-extrusion and empty extrusion inside the Prime Tower during toolchanges by adjusting the purge volume (`E40`) and feeding velocity (`120 mm/min`) in `box.cfg`. This prevents torn lines, stabilizes the Prime Tower structure, and reduces material waste across both stock and aftermarket hotends.
* **Creality Calibration Toolbox (Bed Mesh & Native Adaptive Mesh):** Integrates Creality's original **Adaptive Bed Mesh** directly into the Calibration Toolbox. You can easily switch between **Original (Full Mesh)**, **Adaptive Bed Mesh**, or **Disabled** directly from the interface, ensuring fast, localized probing and precise first layers.
* **CFS-C Material Database Editor (live-synced with Mainsail/Fluidd `Edit Material` dropdown & Touchscreen) (Port 8088):** Available in the **Install Menu (Option 20)** for CFS-C setups, this lightweight web editor lets you add, clone, edit, and back up custom filament brands and temperatures directly in `material_database.json`—automatically syncing them to both the Creality Touchscreen and Mainsail/Fluidd. See the full [CFS-C Material Database Editor Guide](docs/CFS_MATERIAL_EDITOR.md). Custom `90001+` profiles automatically bump the database version timestamp so you can pull them directly over SSH into [CFS RFID (DnG-Crafts/K2-RFID)](https://github.com) to program your own **MIFARE Classic 1K** spool tags.

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
* **Automatic Non-ASCII / Umlaut Object Name Sanitizer (Adaptive Bed Mesh Fix):** Creality's stock `prtouch_v3` area parser silently fails and falls back to a full-bed mesh whenever `EXCLUDE_OBJECT_*` names in a G-Code contain non-ASCII characters (such as German umlauts `ä`, `ö`, `ü`, `ß`, accents, or special characters). The Calibration Toolbox installer automatically enables a lightweight background sanitizer (`server.py`) that converts `EXCLUDE_OBJECT_* NAME=...` entries in uploaded G-Codes to clean ASCII (`Würfel` -> `Wuerfel`) before print start, ensuring `CALIBRATEMODE=2` reliably probes only the object area.

---

### 🔄 FLY-LLL Plus Safety & Auto-Switch (PD7) (`Install / Remove Menu -> Option 16`)

Unified 1-click installation and removal for the **FLY-LLL Plus** external buffer/filament sensor (`^PD7`, requires a **Toolhead Filament Sensor** such as the **Phaetus DXC Extruder** or an extruder-top inline microswitch on the Nozzle PCB — see `files/cfs-lll-plus-safety/firmware/README.md` for alternatives):

* **Hardware Wiring & Common Ground Requirement:** Connect the freed toolhead **`PD7`** signal line to the **Signal / Out** pin of the FLY-LLL Plus filament sensor. **Important:** The FLY-LLL Plus power supply and the printer mainboard/toolhead **`GND (-)`** **must share a common ground (same reference potential)** to prevent floating signals or hardware damage.
* **Smart Fail-Safe Boot Detection (`K1_2025_CFS-C`):** At power-on, `_LLL_BOOT_NEXUSP_EVAL` & `lll_nexusp_guard.sh` check `lll_plus_sensor` (`^PD7`). If filament is already inserted in the FLY-LLL Plus, `nexusp` remains paused (preventing the CFS-C from feeding its slots) and plays a distinctive **4-tone startup fanfare** (`LLL_EXTERNAL_SPOOL_READY_SOUND`). When the FLY-LLL Plus is empty at boot, `nexusp` starts normally for CFS-C operation.
* **One-Click Live Switching (`NEXUSP_OFF_EXTERNAL_SPOOL` / `NEXUSP_ON_CFS` / `TOGGLE_NEXUSP` / `NEXUSP_STATUS`):** Switch modes at any time in Mainsail/Fluidd without rebooting. When switching to External Spool while CFS-C filament is still loaded in the extruder, `NEXUSP_OFF_EXTERNAL_SPOOL` automatically holds the nozzle temperature (`>= 240 °C`), executes `BOX_RETRUDE_MATERIAL`, verifies completion (`T1.filament = None` and extruder sensor empty), pauses `nexusp`, and plays the 4-tone confirmation fanfare. (Blocked automatically if external filament is still present in `^PD7`.)
* **Standard `K1_2025` (Non-CFS) Support:** Installs a dedicated, lightweight runout sensor configuration (`lll_plus_sensor_nocfs.cfg`) on `^PD7` that cleanly triggers `PAUSE` during active prints when the external spool runs out.
