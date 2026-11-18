# Custom FLY-LLL Plus Firmware (Y-Splitter Guard & 1-Click Control)

Pre-compiled STM32F072C8 firmware (`firmware.bin`) and modified source (`buffer_logic.hpp`, based on [`depau/lll-buffed`](https://github.com)) tailored for **Creality K1C 2025 + CFS-C + Y-Splitter** setups.

## Key Features
* **No Unintended Auto-Feed at Boot:** Starts calmly in `Hold` mode (`Manual Insert` default) so inserting filament never collides with a loaded CFS-C spool.
* **1-Click Continuous Feed & Retract:**
  * Short click on **Forward** (`<= 400 ms`) feeds at `55 mm/s` until reaching the extruder (`optical2()`), then automatically switches to normal print buffer mode (`Regular`).
  * Short click on **Retract** (`<= 400 ms`) retracts up to `12.5 s` (or stops immediately when the input switch clears).
  * Clicking either button during continuous motion immediately stops the motor.
  * Holding a button (`> 400 ms`) moves manually while held.
* **2-Button Mode Toggle (`Forward + Retract` held for 1 s):**
  * Toggles between **Manual Insert** (`1x` long LED flash) and **Auto Insert** (`3x` fast LED flashes).
* **Automatic Y-Splitter Collision Protection:**
  * If filament hits resistance before `8.0 s` (e.g., Y-splitter blocked by CFS-C filament), the buffer automatically reverses and retracts for `6.5 s` before shutting off cleanly.

## Flashing via STM32 DFU
1. Disconnect **24 V printer power** completely.
2. Open the top cover of the FLY-LLL Plus to access the internal **`B` (BOOT)** and **`R` (RESET)** buttons.
3. Connect **USB-C** to your PC while holding **`B` (BOOT)**, tap **`R` (RESET)**, and release **`B`**.
4. Flash `firmware.bin` to `0x08000000` using **STM32CubeProgrammer** (or `dfu-util -a 0 -s 0x08000000:leave -D firmware.bin`).
