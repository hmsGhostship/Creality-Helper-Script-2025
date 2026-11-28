# OrcaSlicer Configuration & Multi-Color Guide (K1C 2025 & CFS-C)

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

#### 6. OrcaSlicer Printer Connection (Mainsail & Fluidd Setup)
To ensure **Send & Print** uploads trigger the automatic **`Map & Print`** dialog and live camera streams work seamlessly:
1. Click the **Wi-Fi / Connection icon** next to your printer profile in OrcaSlicer.
2. Select **Octo/Klipper** as **Host Type**.
3. Enter your printer's IP address together with the active web frontend port under **Hostname, IP or URL** (**important:** use `:4409` or `:4408`, **not** `:7125` / `:7126`):
   * **Mainsail:** `http://<printer-ip>:4409`
   * **Fluidd:** `http://<printer-ip>:4408`
4. Leave the **Device** field either **empty** (OrcaSlicer automatically mirrors the Hostname/IP URL above) or enter the exact same `:4409` / `:4408` URL so the embedded Device tab loads the web UI with `Map & Print`.
5. Leave **API Key** empty and click **Test** -> **OK**.
