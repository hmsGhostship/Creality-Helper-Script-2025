# LLL Buffed — Mellow FLY-LLL Plus Custom Firmware (K1 / K1C + CFS-C & Y-Splitter Edition)

Custom STM32F072C8 firmware and browser-based configurator/flasher (`configurator.html`) for the **Mellow FLY-LLL Plus** filament buffer, built on top of `depau/lll-buffed`.

---

## 1. Hardware Wiring (Creality K1 / K1C Toolhead & 24V Power)

> [!IMPORTANT]
> **Always disconnect the 4-pin 24V printer cable from the FLY-LLL Plus before connecting USB-C to your PC** to prevent ground loops or back-feeding between the printer PSU and your computer.

1. **Toolhead Filament Sensor (Required to free `^PD7`):**
   - The stock K1 / K1C rear runout sensor uses pin `PD7` on the toolhead board. To use the FLY-LLL Plus on `PD7`, move toolhead filament detection to the extruder/nozzle PCB (either via a **Phaetus DXC Extruder** or an **Extruder-Top Inline Microswitch** — see Section 5 below).
2. **Connect FLY-LLL Plus to Printer:**
   - **`24V` & `GND`:** Connect to a 24V supply on the printer. **Common Ground (`GND`) between the FLY-LLL Plus and the K1C mainboard/toolhead is mandatory** so the signal level is detected reliably.
   - **`Signal / Out`:** Connect to toolhead pin **`PD7`** (the former stock filament sensor signal pin).

---

## 2. Firmware Installation & Updates via Browser (`configurator.html`)

You do **not** need to install PlatformIO or STM32CubeProgrammer. Both flashing `firmware.bin` (WebDFU) and configuring all settings (WebSerial) work directly inside **Google Chrome** or **Microsoft Edge**.

1. Download `configurator.html` and `firmware.bin` to your computer and open `configurator.html` locally (`file:///...`) in **Google Chrome** or **Microsoft Edge** *(Firefox/Safari do not support WebSerial/WebDFU, and the file must be opened locally rather than over a plain HTTP LAN URL)*.
2. **Enter DFU Bootloader Mode:**
   - **Brand-New / Stock Firmware (One-Time Case Opening):** Unscrew and open the top cover of the FLY-LLL Plus. Hold down the physical **`B` (BOOT)** button on the PCB while plugging in the USB-C cable (or hold **`B`** and briefly press/release **`R` (RESET)**), then release **`B`**.
   - **Future Updates (Once This Custom Firmware Is Installed):** **No need to open the case ever again!** Simply connect USB-C, click **Connect USB** at the top of `configurator.html`, and click **Reboot to DFU**.
3. *(Windows only — one-time setup)* If `STM32 BOOTLOADER` does not appear in the browser USB popup, open **Zadig** and assign the **WinUSB** driver to `STM32 BOOTLOADER`.
4. In the **Firmware Update (WebDFU via USB-C)** section of `configurator.html`, select `firmware.bin` and click **Flash Firmware (WebDFU)**. Once flashing reaches 100%, the buffer automatically reboots into the new firmware.

---

## 3. Configuring Lengths, Speed & Motor Current (Persistent STM32 Flash)

All parameters are stored permanently in the STM32F072 internal flash (`0x0800F800`) and survive power cycles:

### Option A: Browser Configurator (`configurator.html` — Recommended)
1. With the 4-pin 24V cable unplugged, connect the FLY-LLL Plus via USB-C and click **Connect USB** (select `FlyBufferF072`). All fields start blank and populate live with the values currently stored in flash.
2. Choose a quick preset (**CFS-C + Y-Splitter** or **Single Spool / No Y-Splitter**) or enter your actual measured PTFE distances **(always measure starting from the internal filament switch inside the FLY-LLL Plus)**:
   - **Feed & Retract Speed (`mm/s`):** Continuous feed/retract motor speed (default: `55 mm/s`).
   - **Y-Splitter Distance (`mm`):** Distance from the FLY-LLL Plus switch along the PTFE tube to the Y-splitter junction (default: `300 mm`; set to `0` if no Y-splitter is installed).
   - **Collision Threshold (`mm`):** Distance from the FLY-LLL Plus switch to ~100–150 mm past the Y-splitter, well before the extruder (default: `450 mm`; set to `0` to disable collision auto-retract).
   - **Full Retract Distance (`mm`):** Total PTFE path from the FLY-LLL Plus switch all the way to the extruder drive gears (default: `1000 mm`).
   - **Slip Compensation (`mm`) & Motor Ramp (`ms`):** Automatic tolerances (`20 mm` and `500 ms`) added on top of your measured distances so filament always clears the drive gears cleanly.
   - **1-Click Short Press Threshold (`ms`):** Presses shorter than this start 1-click continuous feed/retract; longer presses stop on release (default: `600 ms`).
   - **Stepper Motor Current (`mA`):** TMC2209 RMS motor current (`200–1200 mA`, default: `600 mA`).
   - **Power-On Insert Mode:** `0 = Manual Insert` (safe default — waits for 1-click Forward) or `1 = Auto Insert`.
3. Click **Save to Flash**.

### Option B: Serial Terminal (`115200` baud, `DTR = 1`)
You can also configure the buffer from any serial terminal (`115200` baud, **DTR enabled**):
- `query` (`q`): Display all current values stored in flash.
- `set_speed <MM/S>` | `set_y_dist <MM>` | `set_min_feed_dist <MM>` | `set_full_dist <MM>`
- `set_slip_comp <MM>` | `set_ramp_ms <MS>` | `set_short_press_ms <MS>` | `set_current <MA>` | `set_auto_insert <0|1>`
- `save`: Write current parameters permanently to STM32 flash.
- `defaults`: Restore factory defaults and save to flash.
- `dfu`: Reboot directly into the STM32 DFU bootloader without opening the case.

---

## 4. Button Controls & Safety Features

- **Safe Idle Startup (`Manual Insert` Default):** Boots in `Hold` mode (`Motor::Off` when empty) so inserting filament never feeds automatically into a loaded CFS-C path.
- **1-Click Continuous Feed & Retract (`<= 600 ms`):**
  - **Forward:** Feeds until reaching the extruder sensor (`optical2`), then switches automatically to normal print buffer mode (`Regular`).
  - **Retract:** Retracts the full configured distance (`Full Retract Distance`) back past the drive gears, or stops immediately once the input switch clears.
  - **Stop / Manual Jog:** Clicking either button during continuous motion stops immediately; holding (`> 600 ms`) moves manually until released.
- **2-Button Mode Toggle (`Forward + Retract` held 1 s):** Toggles between **Manual Insert** (`1x` long LED flash) and **Auto Insert** (`3x` fast LED flashes) and immediately saves the new state to STM32 flash.
- **Automatic Y-Splitter Collision Guard:** If resistance (`optical2`) occurs before `Collision Threshold`, the buffer detects a blocked Y-splitter and automatically retracts back by `Y-Splitter Distance`.

---

## 5. Toolhead Filament Sensor Alternatives (Without Phaetus DXC Extruder)

To use the FLY-LLL Plus on pin `PD7` without losing toolhead filament detection (required for auto-stop on feed and the **Spool Holder** `Loaded` status in Mainsail/Fluidd), any compact switch sensor mounted directly at the extruder inlet and wired to the **Nozzle PCB** can replace the Phaetus DXC integrated sensor:

* **Option 1 — Printable Extruder-Top Microswitch Housing (Recommended):**
  * Mount a compact printed inline housing (keep height ≤ 20 mm to clear the K1C glass lid) directly on top of the stock extruder PTFE collet using a standard **Omron D2F-L** (or **KW11**) microswitch and a 5.5 mm steel ball.
  * Search terms on Printables / MakerWorld: *"K1 / K1C Extruder Filament Runout Sensor"*, *"K1 Toolhead Filament Sensor"*, or *"Voron Inline Filament Sensor D2F-L"*.
* **Option 2 — Commercial Mini Inline Sensors or Stock Sensor Relocation:**
  * Compact 3-pin inline microswitch sensors (e.g., *Trianglelab / Mellow / Fysetc Mini Inline Filament Sensor* with ECAS04/PC4-M6 fittings) or relocating the stock Creality runout sensor directly above the extruder with a printed toolhead bracket.
* **Nozzle PCB Wiring & Switch Polarity (`^` vs `^!`):**
  * Connect `GND` and `Signal` to the free 3-pin filament sensor header on the K1C Nozzle PCB.
  * Depending on whether your switch is wired Normally Open (`NO`) or Normally Closed (`NC`), adjust the `!` prefix on the sensor pin in `Helper-Script/dxc_sensor.cfg` so Klipper reports `filament_detected = True` when filament reaches the extruder gears.
