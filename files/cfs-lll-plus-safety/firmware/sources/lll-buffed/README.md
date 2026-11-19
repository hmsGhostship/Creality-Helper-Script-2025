# LLL Buffed - Mellow LLL Plus Custom Firmware

This is a custom firmware for the Mellow LLL Plus 3D printer filament buffer.

> [!NOTE]
> **Community Fork / Custom Extension (K1 / K1C + CFS-C & Y-Splitter Edition)**
> The features and configuration options in the section below are **custom additions** built on top of the original `depau/lll-buffed` firmware. They are specifically designed for setups combining a **Creality CFS-C multi-material unit** and an **external spool via a Y-splitter**. The original upstream documentation begins below the divider line.

---

## 🔧 Custom Extensions: CFS-C & Y-Splitter Guard

### Application Scope
When feeding an external spool through a **Y-splitter** shared with a **CFS-C**, standard auto-feed buffers risk pushing filament into a blocked junction if a CFS-C slot is still loaded. These custom additions prevent collisions directly in hardware:

- **Safe Idle Startup (`Manual Insert` Default):** Boots in `Hold` mode (`Motor::Off` when empty) so inserting filament never feeds automatically into a loaded CFS-C path.
- **1-Click Continuous Feed & Retract:**
  - **Forward (`<= 400 ms`):** Feeds at `55 mm/s` until reaching the extruder (`optical2`), then switches automatically to normal print buffer mode (`Regular`).
  - **Retract (`<= 400 ms`):** Retracts completely from the extruder back past the drive gears (`FULL_RETRACT_DIST_MM`), or stops immediately when the input switch clears.
  - **Emergency Stop / Manual Jog:** Clicking either button during continuous motion stops immediately; holding (`> 400 ms`) moves manually.
- **2-Button Mode Toggle (`Forward + Retract` held 1 s):** Toggles between **Manual Insert** (`1x` long LED flash) and **Auto Insert** (`3x` fast LED flashes).
- **Automatic Y-Splitter Collision Guard:** If resistance (`optical2`) occurs before `MIN_FEED_TO_EXTRUDER_DIST_MM`, the buffer detects that the Y-splitter is blocked by CFS-C filament and automatically retracts by `Y_SPLITTER_RETRACT_DIST_MM`.

### Configuring via USB-C & Persistent STM32 Flash Storage (No Recompile Required)

All Bowden lengths, speed settings, and the startup insert mode are stored permanently in the STM32F072 internal flash (`0x0800F800`) and survive power cycles. You can configure them anytime over USB-C without recompiling the firmware:

#### Option A: Browser Configurator (`configurator.html` — Recommended)
1. Download `configurator.html` to your computer and open it locally (`file:///...`) in **Google Chrome** or **Microsoft Edge** *(Firefox/Safari do not support WebSerial, and the file must be opened locally rather than over a plain HTTP LAN URL)*.
2. Connect the **FLY-LLL Plus** via USB-C and click **Connect USB** (select `FlyBufferF072`).
3. Adjust your measured lengths or pick one of the one-click presets (**CFS-C + Y-Splitter** or **Single Spool / No Y-Splitter**), then click **Save to Flash**.
4. You can also reboot the buffer directly into bootloader mode via **Reboot to DFU** without opening the case.

#### Option B: Serial Terminal (`115200` baud, `DTR = 1`)
Connect with any serial terminal (PlatformIO Monitor, PuTTY, Tera Term, HTerm) at `115200` baud with **DTR enabled** and send plain-text commands:
- `query` (`q`): Show all current values stored in flash.
- `set_speed <MM/S>`: Feed & retract speed (default `55`).
- `set_y_dist <MM>`: Distance from LLL Plus switch to Y-splitter (`300`, or `0` without splitter).
- `set_min_feed_dist <MM>`: Collision threshold past Y-splitter (`450`, or `0` to disable check).
- `set_full_dist <MM>`: Full retract distance from switch to extruder gears (`1000`).
- `set_slip_comp <MM>` / `set_ramp_ms <MS>`: Slip buffer (`20`) and motor ramp offset (`500`).
- `set_auto_insert <0|1>`: Startup mode (`0` = Manual Insert, `1` = Auto Insert; 2-button toggle on the device also auto-saves to flash).
- `save`: Persist current settings to STM32 flash.
- `defaults`: Restore factory defaults and save to flash.
- `dfu`: Reboot directly into STM32 DFU bootloader mode.

---

### Measuring & Configuring Your Bowden Lengths (`lib/buffer/buffer_logic.hpp`)
Measure along your PTFE path with a tape measure and enter your **actual distances in millimeters** (tolerances for gear slip and motor ramp are added automatically by `calcMoveTimeMs()`):

1. **`Y_SPLITTER_RETRACT_DIST_MM` (`300.0F`):** LLL Plus input switch $\rightarrow$ Y-splitter junction.
2. **`FULL_RETRACT_DIST_MM` (`1000.0F`):** LLL Plus input switch $\rightarrow$ extruder drive gears.
3. **`MIN_FEED_TO_EXTRUDER_DIST_MM` (`450.0F`):** Threshold safely past the Y-splitter (`300 mm`) and before the extruder (`1000 mm`).
   - *Note for Single-Spool / Non-CFS-C setups (no Y-splitter):* Set `MIN_FEED_TO_EXTRUDER_DIST_MM = 0.0F` if your direct PTFE tube to the extruder is shorter than `500 mm`, and enter your measured tube length in `FULL_RETRACT_DIST_MM`.

```cpp
constexpr uint32_t SHORT_PRESS_MS = 400;
constexpr float DEFAULT_SPEED_MM_S = 55.0F;

// Enter actual measured PTFE lengths in mm
constexpr float MIN_FEED_TO_EXTRUDER_DIST_MM = 450.0F;
constexpr float Y_SPLITTER_RETRACT_DIST_MM = 300.0F;
constexpr float FULL_RETRACT_DIST_MM = 1000.0F;

// Automatic tolerances (applied by calcMoveTimeMs)
constexpr float SLIP_COMPENSATION_MM = 20.0F;
constexpr uint32_t RAMP_COMPENSATION_MS = 500;
```

---

## 📖 Original Firmware Features (`depau/lll-buffed`)

In addition to the original firmware, this firmware implements the following additional features:

- **Filament hold**: When pressing a button briefly, the buffer will hold the filament in place.
- **Continuous run mode**: When a button is double-pressed (or triple-pressed, configurable), the buffer will
  continuously run the motor until a button is pressed again or the timeout (default 1m 30s, configurable) is reached.
  On timeout, the buffer will hold the filament in place.
- **Serial commands and status**: The buffer can be controlled via serial commands, and it provides status updates
  on the current state of the buffer. This allows implementing useful functionality such as assisted loading/unloading
  of filament.
- **Power save mode**: When controlled via serial commands, a power save mode can be enabled that turns off the motor
  after a few seconds of inactivity. Read more about this later in the document.

### Installation

To install the firmware, you will need to use PlatformIO Core. Follow the
official [PlatformIO installation instructions](https://platformio.org/install/cli).

1. Clone this repository to your local machine:

   ```bash
   git clone https://github.com/depau/lll-buffed.git
   cd lll-buffed
   ```

2. Unscrew and remove the top cover of the buffer, and connect the device to your computer via USB.
3. While holding the `B` (boot) button on the buffer, press and release the `R` (reset) button to put the device into
   bootloader mode. They are located on the PCB between the push/retract buttons. I usually press the `B` button with
   one side of the finger, then rotate the same finger to press and release the `R` button with the other side of the
   finger.
4. Build and upload the firmware using PlatformIO:

   ```bash
   pio run -e fly_buffer_f072c8 -t upload
   ```

If PlatformIO complains that it cannot find the device, try again putting the device into bootloader mode, it may take a
few tries to get the technique right.

### Serial Commands

The buffer can be controlled via serial commands sent over the UART interface.

The protocol is enabled via `ENABLE_UART_PROTOCOL` in `platformio.ini`. TX is on `PA2`, RX is on `PA3`. The baud rate
is 115200.

Most commands have short aliases for convenience. The commands are:

- `push` (`p`): Push the filament forward (continuous run mode).
- `retract` (`r`): Retract the filament (continuous run mode).
- `hold` (`h`): Hold the filament in place.
- `regular` (`n`): Switch to regular mode (push/retract based on sensor inputs).
- `off` (`o`): Switch to regular mode; if the filament is to be held, the motor is turned off instead. (This will be
  reset next time filament is pushed or retracted)
- `move <+/-distance>` (`m <+/-distance>`): Move the buffer a fixed distance in millimeters. A negative distance means
  retracting the filament. After the move, the buffer will hold the filament in place.
- `query` (`q`): Query the current state of the buffer.

A few commands allow tweaking the buffer settings. **The settings are stored in RAM**, so the host software will have
to reapply them after a power cycle.

- `set_timeout <MS>`: Set the timeout for the continuous run and regular modes in milliseconds. Default is 90000 (1
  minute 30 seconds).
- `set_hold_timeout <MS>`: Set the hold timeout in milliseconds. Default is 10000 (10 seconds).
- `set_hold_timeout_en <0|1>`: Enable or disable the hold timeout (power save mode). Default is 0 (disabled).
- `set_emptying_timeout <MS>`: Set the timeout after which the buffer will shut down when no filament is detected.
  Default is 5000 (5 seconds).
- `set_multi_press_count <N>`: Set the number of button presses required to enter continuous run mode. Default is 2.
- `set_speed <MM/S>`: Set the speed of the motor in millimeters per second. Default is 30.

When the status or the settings change, the buffer will send a status update over serial. The status updates are the
following:

- `mode=<mode>`: The current mode of the buffer. Possible values are:
  - `regular`: Automatic operation based on the optical sensors.
  - `continuous`: Continuous run mode started by a command or a sequence of button presses.
  - `move_command`: Move for a fixed distance issued by the host.
  - `hold`: Filament held in place with the motor enabled, ignoring sensor inputs.
  - `manual`: Motor controlled directly by a held button.
  - `emptying`: The buffer is waiting for the last bit of filament to be pushed out after the filament has run out.
- `status=<status>`: The current status of the motor. Possible values are:
  - `push`: Filament pushed forward.
  - `retract`: Filament retracted.
  - `hold`: Motor enabled with zero velocity, either in hold mode or when the buffer is idle in regular mode.
  - `off`: Driver disabled.
- `filament_present=<0|1>`: Whether the filament is present in the buffer (i.e., the sensors detect it).
- `timed_out=<0|1>`: Whether the buffer has timed out in continuous run or regular mode.
- `timeout=<MS>`: The current configured timeout in milliseconds.
- `hold_timeout=<MS>`: The current configured hold timeout in milliseconds (power save mode).
- `hold_timeout_en=<0|1>`: Whether the hold timeout (power save mode) is enabled.
- `emptying_timeout=<MS>`: The current configured emptying timeout in milliseconds.
- `multi_press_count=<N>`: The number of button presses required to enter continuous run mode.
- `speed=<MM/S>`: The current speed of the motor in millimeters per second.

Commands may be prefixed by a single digit representing the buffer ID (0-9) if multiple buffers are connected to the
same UART TX line. You can change the buffer ID by modifying the `BUFFER_ID` macro in `platformio.ini`.

### Timeout

In regular mode, the buffer will keep pushing or retracting the filament until the sensors detect that the buffer is
empty or full. In continuous run mode, the buffer will keep pushing or retracting the filament until a button is
pressed.

If the buffer does not receive any input (user or sensor) for a certain amount of time, it will time out and hold the
filament in place.

This is to prevent the buffer from running indefinitely if the sensors are not detecting the filament correctly or if
the user forgets to stop the buffer.

Timeouts are reset by any user input (button press) or via serial commands (i.e. `regular`, `push`, `retract`).

### Power Save Mode

When the buffer is controlled via serial commands, it can enter a power save mode that turns off the motor after a few
seconds of inactivity.

This is disabled by default since it can be annoying when operating the buffer manually. The idea is that the printer
host software should enable it when its own filament sensor detects the filament, since when the filament is in all the
way there's no need to hold it in place with the motor.

Operating the buffer manually will disable the power save mode, so the filament won't suddenly start moving after
stopping it manually.

### I2C Protocol

The buffer can also be controlled via I2C. This is enabled via `ENABLE_I2C_PROTOCOL` in `platformio.ini`. The default Address is `0x10`.

**Hardware Connections:**

- **SDA**: PB11
- **SCL**: PB10
- **Interrupt (INT)**: PA5 (Open-Drain, Active Low)

**Operation:**
The I2C protocol uses a Virtual Register Map. The Master writes to registers to send commands or configure parameters, and reads from registers to get status.
The **Interrupt Line (INT)** is asserted (pulled LOW) by the buffer whenever its status changes (e.g. filament status, mode change, timeout). The Master should read the `STATUS` register to clear the interrupt.

**Data Encoding:**

- **Endianness**: Little Endian (LSB first).
- **Floats**: IEEE 754 Single Precision (32-bit).
- **Integers**: Two's complement (32-bit or 8-bit).
- **Booleans**: 1 byte, `0x00` = False, `0x01` = True.

**Register Map:**

| Register             | Address | Bytes | R/W | Description                                                                  |
|:---------------------|:--------|:------|:----|:-----------------------------------------------------------------------------|
| **COMMAND**          | `0x00`  | 1     | W   | Write command code: `0`=Off, `1`=Regular, `2`=Hold, `3`=Push, `4`=Retract    |
| **MOVE_DIST**        | `0x01`  | 4     | W   | Float — trigger a move (mm). Positive=Push, Negative=Retract.                |
| **STATUS**           | `0x05`  | 1     | R   | Status flags: `Bit0`=FilamentPresent, `Bit1`=TimedOut                        |
| **MODE**             | `0x06`  | 1     | R   | Current Mode: `0`=Regular, `1`=Continuous, `2`=MoveCmd, `3`=Hold, `4`=Manual |
| **MOTOR**            | `0x07`  | 1     | R   | Motor State: `0`=Push, `1`=Retract, `2`=Hold, `3`=Off                        |
| **SPEED**            | `0x08`  | 4     | R/W | Motor speed in mm/s (float)                                                  |
| **TIMEOUT**          | `0x0C`  | 4     | R/W | Timeout in ms (uint32)                                                       |
| **EMPTYING_TIMEOUT** | `0x10`  | 4     | R/W | Emptying push timeout in ms (uint32)                                         |
| **HOLD_TIMEOUT**     | `0x14`  | 4     | R/W | Hold timeout in ms (uint32)                                                  |
| **HOLD_TIMEOUT_EN**  | `0x18`  | 1     | R/W | Enable hold timeout (0 or 1)                                                 |
| **MULTI_PRESS**      | `0x19`  | 1     | R/W | Multi-press count                                                            |

**Example Transaction:**

1. Master detects INT LOW.
2. Master writes `0x05` (STATUS Register Address).
3. Master reads 1 byte (Status flags). **INT line is released.**
4. Master checks flags (e.g., Filament Present).

To trigger a move:

1. Master writes `[0x01] [Float Byte 0] [Float Byte 1] [Float Byte 2] [Float Byte 3]`.

---

### Toolhead Filament Sensor Alternatives (Without Phaetus DXC Extruder)

To use the FLY-LLL Plus on pin `PD7` without losing toolhead filament detection (required for auto-stop on feed and the **Spool Holder** `Loaded` status in Mainsail/Fluidd), any compact switch sensor mounted directly at the extruder inlet and wired to the **Nozzle PCB** can replace the Phaetus DXC integrated sensor:

* **Option 1 — Printable Extruder-Top Microswitch Housing (Recommended):**
  * Mount a compact printed inline housing (keep height ≤ 20 mm to clear the K1C glass lid) directly on top of the stock extruder PTFE collet using a standard **Omron D2F-L** (or **KW11**) microswitch and a 5.5 mm steel ball.
  * Search terms on Printables / MakerWorld: *"K1 / K1C Extruder Filament Runout Sensor"*, *"K1 Toolhead Filament Sensor"*, or *"Voron Inline Filament Sensor D2F-L"*.
* **Option 2 — Commercial Mini Inline Sensors or Stock Sensor Relocation:**
  * Compact 3-pin inline microswitch sensors (e.g., *Trianglelab / Mellow / Fysetc Mini Inline Filament Sensor* with ECAS04/PC4-M6 fittings) or relocating the stock Creality runout sensor directly above the extruder with a printed toolhead bracket.
* **Nozzle PCB Wiring & Switch Polarity (`^` vs `^!`):**
  * Connect `GND` and `Signal` to the free 3-pin filament sensor header on the K1C Nozzle PCB.
  * Depending on whether your switch is wired Normally Open (`NO`) or Normally Closed (`NC`), adjust the `!` prefix on the sensor pin in `Helper-Script/dxc_sensor.cfg` so Klipper reports `filament_detected = True` when filament reaches the extruder gears.
