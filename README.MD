# 💡 Smart Automatic Light Controller with LDR & Arduino Nano

An energy-efficient embedded systems project that automatically controls lighting based on ambient light levels. Using a Light Dependent Resistor (LDR) sensor module and an Arduino Nano, this system switches a relay on in low-light/dark conditions and off during bright conditions, eliminating unnecessary energy consumption.

---

## 📌 Features

* **Real-time Ambient Light Sensing:** Reads analog illumination levels via a photoresistor (LDR) module.
* **Automated Relay Actuation:** Triggers AC/DC loads (lamps, bulbs) seamlessly without manual user intervention.
* **Configurable Sensitivity Threshold:** Easy-to-adjust threshold parameter (`500`) to adapt to various room lighting environments.
* **Compact Footprint:** Powered by an ATmega328P-based Arduino Nano, ideal for small enclosures and home automation panels.

---

## ⚙️ How It Works

1. **Light Detection:** When powered, the LDR module continuously senses ambient light intensity and provides an analog voltage output.
2. **Analog-to-Digital Conversion (ADC):** The Arduino Nano reads this voltage through an analog pin, yielding an integer reading between `0` (pitch black) and `1023` (brightest exposure) depending on your voltage divider configuration.
3. **Threshold Evaluation:** The logic compares the sensor reading against a preset threshold value of **500**:
   * **Value > 500 (Dark condition):** The Arduino drives the control pin to activate the relay, switching the light **ON**.
   * **Value ≤ 500 (Bright condition):** The Arduino deactivates the relay, switching the light **OFF**.

---

## 🛠️ Hardware Requirements

| Component | Quantity | Specification / Description |
| :--- | :---: | :--- |
| **Arduino Nano** | 1 | ATmega328P Microcontroller Board (5V, 16MHz) |
| **LDR Sensor Module** | 1 | Photoresistor module (Analog Output / AO) |
| **5V Relay Module** | 1 | 1-Channel Relay (5V trigger, optocoupler-isolated) |
| **Light Bulb / Load** | 1 | AC/DC light source |
| **External Power Supply** | 1 | Appropriate power source for the load & Arduino (5V–12V) |
| **Jumper Wires** | — | Breadboard / DuPont wires |

---

## 🔌 Pin Configuration

| Component Pin | Arduino Nano Pin | Note |
| :--- | :--- | :--- |
| **LDR Module VCC** | `5V` | System 5V Power Bus |
| **LDR Module GND** | `GND` | Ground Bus |
| **LDR Module AO** | `A0` | Analog Input Pin |
| **Relay Module VCC** | `5V` | System 5V Power Bus |
| **Relay Module GND** | `GND` | Ground Bus |
| **Relay Module IN** | `D2` | Digital Output Pin (Control) |

> ⚠️ **Safety Warning:** When wiring mains AC electricity (110V/220V) to the relay module's `COM` and `NO` terminals, ensure all power sources are disconnected during assembly. Always insulate high-voltage connections.

---

## 🚀 Getting Started
1. **Connect Hardware:**
   * Wire the LDR sensor module, 5V relay, and Arduino Nano according to the pin configuration table above.
2. **Open the Project:**
   * Launch Arduino IDE or PlatformIO.
   * Open the project directory or main sketch file.
3. **Configure Board & Port:**
   * Go to **Tools > Board** and select **Arduino Nano**.
   * Under **Tools > Processor**, select **ATmega328P** (or *ATmega328P (Old Bootloader)* if using CH340 USB clones).
   * Select your COM port under **Tools > Port**.
4. **Upload & Calibrate:**
   * Upload the firmware to your board.
   * Open the Serial Monitor (at `9600 baud`) to inspect real-time ambient light readings and adjust the threshold value according to your environment.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE) - feel free to use, modify, and distribute for personal and educational projects.
