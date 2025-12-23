// Pin Setup
const int soundPin = 12;   // pin D0 sensor suara
const int relayPin = 13;   // pin IN relay

// Variabel
bool lampState = false;    // status lampu (relay)
unsigned long lastClapTime = 0;
int clapCount = 0;

void setup() {
  pinMode(soundPin, INPUT);
  pinMode(relayPin, OUTPUT);

  digitalWrite(relayPin, LOW);   // relay awal mati
  Serial.begin(9600);
}

void loop() {
  int soundState = digitalRead(soundPin);

  // Jika suara terdeteksi (D0 = LOW pada beberapa sensor, HIGH pada lainnya)
  if (soundState == LOW) {
    unsigned long now = millis();

    // Deteksi interval antar tepukan (maks 500 ms)
    if (now - lastClapTime > 50) {  // debounce
      clapCount++;
      Serial.println("Tepuk Terdeteksi!");
      lastClapTime = now;
    }
    delay(100);
  }

  // Jika dalam 500ms ada 2 tepuk → toggle relay
  if (clapCount >= 2) {
    lampState = !lampState;
    digitalWrite(relayPin, lampState ? HIGH : LOW);

    if (lampState) Serial.println("Lampu MENYALA");
    else Serial.println("Lampu MATI");

    clapCount = 0;  
    delay(500);
  }

  // Reset jika tepuk hanya 1 kali dan tidak ada tepukan lanjutan
  if (millis() - lastClapTime > 500) {
    clapCount = 0;
  }
}
