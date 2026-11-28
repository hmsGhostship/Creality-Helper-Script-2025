# Backup, Camera, Non-CFS Features & Retire Nexusp Backend

### 💾 Backup, Restore & Options Profiles (`Backup & Restore Menu`)
* **OTA-Safe State Backup & Restore (Options `5` & `6` / `BACKUP_OTA_STATE` macro):** Saves configs, Moonraker databases, custom Klipper extras (`box_control.pyc`, `cfs_material_db.py`, shell commands), system overlays (`reccon`, `mdev.conf`, crontabs), and disabled service states to `/usr/data` and/or an attached **USB drive** (with automatic `sync` for safe removal). Supports **Safe Merge** (keeps new stock firmware configs and merges `[include ...]` & `SAVE_CONFIG` values) or **Full Overwrite**.
* **Installed Options Profile Backup & Selective Restore (Options `9` & `10`):** Scans all active modules from the Info Menu (separately for **CFS-C** and **Standard / Non-CFS**) and reinstalls missing or selected modules in **strict dependency order**—including automatic cross-variant upgrade/adapt merging (`Non-CFS ↔ CFS-C`).
* **Automatic Pre-Helper-Script Factory Baseline (Option `11`):** On a pristine printer, the very first launch of `helper.sh` automatically captures an immutable snapshot of your original configs, Klipper extras, system services, and file manifests (`/usr/data/helper-script-factory-baseline/`). If a baseline snapshot exists (locally or on a USB drive), **Option `11`** appears in the Backup & Restore Menu and allows a full, clean revert back to the pre-helper-script state (removing all added `.py` modules, services, Entware, and web frontends while keeping root access and Wi-Fi intact). *(Tip: Copy `/usr/data/helper-script-factory-baseline` to a USB drive after the first run, especially when testing on older firmware revisions like `1.0.0.25` or Non-CFS setups.)*

---

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

---

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
