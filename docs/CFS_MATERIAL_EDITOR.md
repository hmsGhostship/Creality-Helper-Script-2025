# CFS-C Material Database Editor (Port 8088)

A lightweight web interface to add, clone, edit, and back up custom filament profiles in Creality's material_database.json on K1 / K1C / K1 Max / K1 SE (2025 CFS-C) printers.
All changes are automatically synchronized across the printer's configuration files and SQLite lookup tables so custom brands appear directly on the Creality Touchscreen as well as in the Fluidd / Mainsail CFS-C panel.

## 1. Installation & Removal

1. Open SSH on your printer and launch the Helper Script: /usr/data/helper-script/helper.sh
2. Navigate to 1) Install Menu -> 20) Install CFS-C Material Database Editor (port 8088) and confirm with y.
3. The installer automatically:
   - Installs the backend and web UI to /usr/data/cfs-material-editor/
   - Creates the persistent autostart service /usr/apps/etc/init.d/S99cfs_material_editor
   - Adds a Material DB sidebar link to Mainsail (if installed)
   - Registers a Material DB Iframe camera view in Moonraker (available in both Mainsail and Fluidd)

To uninstall, run 2) Remove Menu -> 20) Remove CFS-C Material Database Editor (port 8088).

## 2. Accessing the Editor

- Direct URL: http://<PRINTER_IP>:8088
- Mainsail: Click Material DB in the left sidebar, or switch to the Material DB tab inside the Webcam panel.
- Fluidd: Open the Material DB tab inside the Camera panel on the dashboard (click the maximize icon in the top-right corner of the card for full-screen view).

## 3. Features & Usage

- Add New Filament (+ New Filament): Leave ID empty for automatic 90001+ numbering, set Brand, Name, Material Type, Nozzle/Bed temperatures, Max Volumetric Speed (mm³/s), and drying settings, then click Save.
- Clone / Edit / Delete: Clone any stock or custom profile, adjust parameters, or remove custom (90001+) entries. Stock Creality/Generic entries are protected from deletion.
- **Import OrcaSlicer JSON(s):** Select one or multiple OrcaSlicer user filament `.json` files (`OrcaSlicer/user/<id>/filament/*.json`) to directly import or update profiles on the printer (with automatic `@printer` suffix cleanup and abrasive `-CF`/`-GF` safety warning).
- One-Click Preset Pack: Imports 7 pre-tuned CFS-C profiles (90001-90007) for Sunlu, Jayo, Eryone, and eSun (idempotent—safe to click multiple times).
- Backup & Restore: Download a full material_database.json backup anytime or revert to the untouched factory .bak file.

## 4. Applying Changes to the Touchscreen

- Changes are immediately available in the Fluidd / Mainsail CFS-C web panel after a page refresh.
- Reboot the printer once after adding new brands so the Creality Touchscreen reloads the updated brand list.

> Safety Note: Do not route abrasive carbon-fiber filaments (PLA-CF, PETG-CF, PA-CF) through the CFS-C—always print CF materials from the external spool holder.
