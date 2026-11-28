# Creality Helper Script - 2025 (CFS-C & K1_2025)

This repository provides custom enhancements, multi-material integration, calibration tools, and low-RAM system optimizations for **Creality K1 (2025 Series)** printers (both **`K1_2025_CFS-C`** and standard **`K1_2025`** non-CFS models).

Additional support for **K1 2025 CFS-C** by [@hmsGhostship](https://github.com) and standard **`K1_2025`** (non-CFS) by [@C0DEbrained](https://github.com).

> **⚠️ Firmware Compatibility Note:** Tested on **Creality Firmware `1.1.0.27`**. Always create an **OTA-Safe State Backup** (Backup & Restore Menu → Option `5` or macro `BACKUP_OTA_STATE`, ideally with a USB drive attached) before installing firmware updates.

---

## 📋 Quick Start & Installation

1. **Root your printer** using one of the following methods:
   * **Web-based Method (Recommended):** [Codebrained Creality-2025-Web-Exploit](https://github.com/Creality-2025-Web-Exploit)
   * **Local Python Method:** [Codebrained K1C 2025 Root Exploit Gist](https://github.com)
2. **Install Entware** and reboot the printer:
   ```bash
   wget -O- https://githubusercontent.com | sh
   ```
3. **Clone the repository and launch the menu:**
   ```bash
   git clone --depth 1 https://github.com/Creality-Helper-Script-2025.git /usr/data/helper-script
   sh /usr/data/helper-script/helper.sh
   ```

### 🔄 Updating
* **Via Mainsail / Fluidd:** Open **Machine / System → Update Manager** and update **Creality-Helper-Script**.
* **Via SSH Menu:** Run `sh /usr/data/helper-script/helper.sh` and press **`u`** (*Update Helper-Script*), then re-run the installer option for any updated web addon and press **Ctrl + F5** in your browser.

---

## 📚 Documentation & Manuals

Detailed configuration guides, G-code templates, and feature manuals have been organized into dedicated guides:

* **[🏠 Proxmox LXC Setup Guide (Spoolman & Mobile App)](docs/PROXMOX_SETUP.md)**
  * Step-by-step guide to host Spoolman (`:7912`) via Docker and the K1C CFS-C Mobile App (`:8081`) in a Proxmox LXC container.
* **[⚙️ OrcaSlicer Configuration & Multi-Color Guide](docs/ORCASLICER.md)**
  * Machine Start/Change G-Code (CFS-C & Native Klipper), flushing volumes, timelapse layer macro, and `:4409` / `:4408` connection setup for `Map & Print`.
* **[🗄️ CFS-C Material Database Editor & Spoolman Sync](docs/CFS_MATERIAL_EDITOR.md)**
  * Custom `90001+` filament profiles, OrcaSlicer JSON import, **Spoolman Online Check**, **`Select & Push` / `AutoPush` / `AutoSync`**, delete confirmation dialog, and automatic 21-language UI translation.
* **[🖥️ CFS-C Web Panel, Calibration Toolbox & Hardware Mods](docs/CFS_PANEL_AND_HARDWARE.md)**
  * Mainsail/Fluidd CFS-C panel, `Map & Print` upload gate, Pre-Print Filament Guard, **Speed Fix**, **Purge Volume Fix**, **Adaptive Bed Mesh**, and **FLY-LLL Plus Safety (`^PD7`)**.
* **[💾 Backup/Restore, Camera Architecture, Non-CFS Macros & Retire Nexusp](docs/BACKUP_AND_NEXUSP.md)**
  * OTA-safe backups, factory baseline revert, low-RAM dual camera (`mjpg-streamer` / `Go2rtc`), `K1_2025` macro packages (Fans, Input Shaper, `M600`), and `@C0DEbrained`'s **Retire Nexusp Backend**.

---

*Disclaimer: This software is provided "as is" without warranty of any kind. Use it at your own risk.*
