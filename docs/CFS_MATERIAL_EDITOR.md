# CFS-C Material Database Editor (Port 8088)

A lightweight web interface to add, clone, edit, and back up custom filament profiles in Creality's `material_database.json` on **K1 / K1C / K1 Max / K1 SE (2025 CFS-C)** printers.
All changes are automatically synchronized across the printer's configuration files and SQLite lookup tables so custom brands appear directly on the **Creality Touchscreen** as well as in the **Fluidd / Mainsail CFS-C panel**.

## 1. Installation & Removal

1. Open SSH on your printer and launch the Helper Script: `/usr/data/helper-script/helper.sh`
2. Navigate to **`1) Install Menu` -> `20) Install CFS-C Material Database Editor (port 8088)`** and confirm with **`y`**.
3. The installer automatically:
   - Installs the backend and web UI to `/usr/data/cfs-material-editor/`
   - Creates the persistent autostart service `/usr/apps/etc/init.d/S99cfs_material_editor`
   - Adds a **`Material DB`** sidebar link to **Mainsail** (if installed)
   - Registers a **`Material DB`** `Iframe` camera view in **Moonraker** (available in both **Mainsail** and **Fluidd**)

To uninstall, run **`2) Remove Menu` -> `20) Remove CFS-C Material Database Editor (port 8088)`**.

## 2. Accessing the Editor

- **Direct URL:** `http://<PRINTER_IP>:8088`
- **Mainsail:** Click **`Material DB`** in the left sidebar, or switch to the **`Material DB`** tab inside the Webcam panel.
- **Fluidd:** Open the **`Material DB`** tab inside the Camera panel on the dashboard (click the maximize icon in the top-right corner of the card for full-screen view).

## 3. Features & Usage

- **Add Selection to DB (`Add Selection to DB`):** Opens a checklist of 7 pre-tuned CFS-C profiles (`90001`–`90007` for Sunlu, Jayo, Eryone, and eSun) so you can select only the specific filaments you want to install.
- **Add New Filament (`+ New Filament`):** Leave **ID** empty for automatic `90001+` numbering, set Brand, Name, Material Type, Nozzle/Bed temperatures, Max Volumetric Speed (`mm³/s`), and drying settings, then click **Save**.
- **Clone / Edit / Delete:**
  - **Clone:** Copy any stock (`Creality` / `Generic`) or custom profile into a new editable `90001+` profile.
  - **Edit / Delete:** Custom profiles (`90001+`) can always be edited or deleted. Stock profiles (`00001`–`29001`) are locked against accidental edits/deletion by default.
- **Import / Export Menu (`Import / Export ▾`):**
  - **Import OrcaSlicer JSON(s)...:** Select one or multiple local OrcaSlicer user filament `.json` files (`OrcaSlicer/user/<default_or_id>/filament/*.json`) to directly import or update profiles on the printer (automatically strips `@printer` suffixes and detects vendor/type).
  - **Download Windows Sender (.bat):** Downloads a pre-configured `Send_Filament_to_K1C.bat` filled with your printer's IP address. Run it on your Windows PC to list your local OrcaSlicer filaments, enter numbers like `1` or `1,3` to push them to the K1C, or press `q` to exit immediately.
  - **Download Database Backup (.json):** Downloads the complete active `material_database.json` to your computer.
- **Editor Settings (`⚙ Settings`):**
  - **Include abrasive CF/GF materials:** Disabled by default for CFS-C hardware safety. Controls whether `-CF` / `-GF` materials are selectable in the editor, accepted by the OrcaSlicer importer, and listed in newly downloaded `Windows Sender (.bat)` files.
  - **Allow editing stock profiles (Creality / Generic):** Disabled by default to protect factory entries; enable if you intentionally want to modify stock entries directly.
  - **Restore Factory Original (.bak):** Reverts the database back to the untouched factory backup created before your first edit.

## 4. Applying Changes to the Touchscreen

- Changes are immediately available in the **Fluidd / Mainsail CFS-C web panel** (`Edit Material` dropdown lists your custom `90001+` profiles automatically after a page refresh).
- Reboot the printer once after adding new brands so the **Creality Touchscreen** reloads the updated brand list.

> **Safety Note:** Do not route abrasive carbon-fiber or glass-fiber filaments (`PLA-CF`, `PETG-CF`, `PA-CF`) through the CFS-C—always print CF/GF materials from the external spool holder.


## Spoolman Integration & Live Online Check
* **Automatic Online Health Check:** The editor continuously checks whether your configured Spoolman server (`Host / IP` + `Port`) is reachable and displays a live green/red status indicator in the top bar. If Spoolman is offline or unconfigured, sync actions are safely blocked.
* **Three Sync Modes (`Settings -> Sync Behavior`):**
  * **`Select & Push` (Default):** Manual mode. Clicking **`Spoolman: Select & Push`** in the top bar opens a selection dialog to pick which profiles to push to Spoolman.
  * **`AutoPush`:** Automatically pushes newly added, cloned, edited, or imported filaments (`90001+`) to Spoolman. Deletions in the editor leave Spoolman untouched unless explicitly checked in the confirmation dialog.
  * **`AutoSync`:** Full automatic synchronization. Switching to `AutoSync` or saving/deleting profiles pushes all custom `90001+` profiles and removes deleted `Creality DB ID` entries from Spoolman (pre-checked in the confirmation modal).

## Automatic Multi-Language Support (21 Languages)
* Automatically detects your active **Mainsail** or **Fluidd** UI language (with browser locale fallback) and live-translates all controls, tables, and modals across all 21 Mainsail/Fluidd languages—or lets you pick a fixed language in **Settings -> Language / Sprache**.
