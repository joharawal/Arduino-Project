# 👏 Automatic Clap-Activated Light System with Arduino

An interactive home automation project that enables hands-free lighting control using sound detection. Built around an Arduino microcontroller and an acoustic sound sensor module, the system implements a **dual-clap recognition algorithm (`ClapCount`)** to toggle a relay switch ON and OFF, preventing accidental triggers from isolated background noises.

---

## 📌 Features

* **Dual-Clap Verification (`ClapCount`):** Rejects single loud noises (doors slamming, dropped items) by requiring two distinct claps within a defined time window before toggling state.
* **Toggle Operation:** Alternates state seamlessly—two claps turn the light **ON**, and two subsequent claps turn the light **OFF**.
* **High-Power Load Control:** Uses an optocoupler-isolated relay module to safely drive standard AC light bulbs or DC fixtures.
* **Adjustable Sound Sensitivity:** Hardware potentiometer calibration directly on the microphone module allows fine-tuning to room acoustics.

---

## ⚙️ How It Works

1. **Acoustic Detection:** The sound sensor module continuously monitors ambient noise via its microphone transducer.
2. **Signal Triggering:** When a sound exceeding the set sound threshold occurs, the sensor's digital output (`DO`) registers a pulse.
3. **ClapCount State Machine:**
   * **First Clap:** The system detects the initial acoustic peak, starts an internal timer window, and sets `ClapCount = 1`.
   * **Second Clap:** If a second valid sound pulse is registered within the allowed time frame (e.g., between 200 ms and 800 ms), `ClapCount` increments to `2`.
   * **Noise Rejection:** If the second clap arrives too quickly (acoustic echo) or too late (unrelated event), the counter resets to `0`.
4. **Relay Actuation:** Once two valid claps are confirmed:
   * If the light is currently **OFF** $\rightarrow$ the relay engages, turning the light **ON**.
   * If the light is currently **ON** $\rightarrow$ the relay disengages, turning the light **OFF**.
   * `ClapCount` resets to `0` to await the next sequence.

---

## 🛠️ Hardware Requirements

| Component | Quantity | Specification / Description |
| :--- | :---: | :--- |
| **Arduino Board** | 1 | Arduino Uno / Nano / Pro Mini (ATmega328P) |
| **Sound Sensor Module** | 1 | Microphone sensor (e.g., KY-038 / LM393 Sound Detector) |
| **5V Relay Module** | 1 | 1-Channel optocoupled relay (5V coil, 10A 250VAC rated) |
| **Light Bulb / Lamp** | 1 | AC mains light or DC LED fixture |
| **Power Supply** | 1 | 5V regulated DC supply for Arduino & modules |
| **Connecting Wires** | — | DuPont / Breadboard jumper wires |

---

## 🔌 Pin Configuration

| Component Pin | Arduino Pin | Description |
| :--- | :--- | :--- |
| **Sound Sensor VCC** | `5V` | Regulated 5V rail |
| **Sound Sensor GND** | `GND` | Common ground |
| **Sound Sensor OUT / DO** | `12` | Digital pulse pin (supports hardware interrupts) |
| **Relay Module VCC** | `5V` | Regulated 5V rail |
| **Relay Module GND** | `GND` | Common ground |
| **Relay Module IN** | `13` | Relay digital trigger signal |

> ⚠️ **Safety Warning:** Working with AC mains voltage (110V/220V) poses an electrocution hazard. Always disconnect the main power source before wiring or adjusting connections to the relay terminal block (`COM` and `NO`). Ensure all high-voltage connections are properly insulated.

---

## 🚀 Getting Started

1. **Hardware Assembly:**
   * Wire the sound detector module and relay module to the Arduino board according to the pinout table above.
   * Connect your lighting load in series with the relay's `COM` (Common) and `NO` (Normally Open) ports.

2. **Sensor Calibration:**
   * Power the circuit.
   * Turn the potentiometer screw on the sound sensor module clockwise or counterclockwise until the module's onboard indicator LED flashes strictly in response to your deliberate hand claps, staying off during quiet room conversation.

3. **Upload & Run:**
   * Open the sketch in the Arduino IDE.
   * Select your target board and COM port under **Tools**.
   * Upload the program and test your dual-clap action.

---

## 📜 License

This project is open-source and distributed under the [MIT License](LICENSE). Feel free to adapt and expand it for your own home automation systems.
