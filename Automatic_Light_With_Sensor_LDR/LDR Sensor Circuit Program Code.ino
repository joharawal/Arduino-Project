const int ldrPin = A0;
const int relayPin = 13;

int threshold = 500;  // batas gelap-terang (sesuaikan)

void setup() {
  pinMode(relayPin, OUTPUT);
  digitalWrite(relayPin, LOW);   // awal mati
  Serial.begin(9600);
}

void loop() {
  int ldrValue = analogRead(ldrPin);
  Serial.println(ldrValue);

  // Jika nilai lebih besar dari threshold = gelap
  if (ldrValue > threshold) {
    digitalWrite(relayPin, HIGH);  // lampu nyala
    Serial.println("Gelap → Lampu ON");
  } else {
    digitalWrite(relayPin, LOW);   // lampu mati
    Serial.println("Terang → Lampu OFF");
  }

  delay(200);
}