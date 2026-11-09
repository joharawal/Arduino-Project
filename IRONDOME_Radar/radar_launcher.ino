#include <Servo.h>

// ================== PIN DEFINITIONS ==================
#define LED_MERAH   A2
#define LED_KUNING  A1
#define LED_HIJAU   A0

#define TRIG_PIN    13
#define ECHO_PIN    12

#define SERVO_SCAN_PIN     11   // servo 1: pembawa ultrasonic (radar sweep)
#define SERVO_ROTASI_PIN   10   // servo 2: rotasi launcher
#define SERVO_ELEVASI_PIN  9    // servo 3: elevasi launcher

#define BUTTON_PIN  2

#define RELAY_IGNITER_PIN  7   // relay untuk menyalakan voltage igniter roket

// ================== OBJECTS ==================
Servo servoScan;
Servo servoRotasi;
Servo servoElevasi;

// ================== KONFIGURASI ZONA (cm) ==================
const int ZONA_AMAN_MIN   = 30;   // jarak > 30cm  = zona aman   (hijau)
const int ZONA_SEDANG_MIN = 15;   // 15-30cm       = zona sedang (kuning)
                                   // < 15cm        = zona dekat  (merah)

// ================== KONFIGURASI SCAN ==================
const int SUDUT_MIN     = 0;
const int SUDUT_MAX     = 180;
const int LANGKAH_SUDUT = 2;
const int JEDA_SERVO_MS = 25;

// ================== KONFIGURASI ELEVASI ==================
const int SUDUT_ELEVASI_AWAL   = 90;  // posisi standby / reset
const int SUDUT_ELEVASI_TEMBAK = 0;   // posisi saat tombol ke-1 ditekan

const unsigned long DEBOUNCE_MS = 200;

// Lama relay igniter tetap ON saat menyalakan (non-blocking, auto-off)
const unsigned long DURASI_RELAY_MS = 1000;

// ================== STATE SISTEM ==================
enum StatusSistem { SCANNING, TARGET_TERKUNCI, SIAP_TEMBAK };
StatusSistem status = SCANNING;

int sudutSekarang = SUDUT_MIN;
int arahSapuan    = 1;
unsigned long waktuServoTerakhir = 0;

int  sudutTarget  = 0;
long jarakTarget  = 0;

unsigned long waktuTombolTerakhir = 0;
int statusTombolSebelumnya = HIGH; // pakai INPUT_PULLUP

// Pesan sementara untuk ditampilkan di Processing
int kodePesanSementara = 0;
unsigned long waktuPesanBerakhir = 0;

// Status relay igniter (non-blocking, auto mati sendiri)
bool relayIgniterAktif = false;
unsigned long waktuRelayMati = 0;

// ============================================================
void setup() {
  Serial.begin(9600);

  pinMode(LED_MERAH, OUTPUT);
  pinMode(LED_KUNING, OUTPUT);
  pinMode(LED_HIJAU, OUTPUT);

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  pinMode(BUTTON_PIN, INPUT_PULLUP); // tombol ke GND saat ditekan

  pinMode(RELAY_IGNITER_PIN, OUTPUT);
  digitalWrite(RELAY_IGNITER_PIN, LOW); // pastikan relay OFF sejak awal (safety default)

  servoScan.attach(SERVO_SCAN_PIN);
  servoRotasi.attach(SERVO_ROTASI_PIN);
  servoElevasi.attach(SERVO_ELEVASI_PIN);

  servoScan.write(sudutSekarang);
  servoRotasi.write(90);
  servoElevasi.write(SUDUT_ELEVASI_AWAL);

  matikanSemuaLed();
}

// ============================================================
void loop() {
  cekTombolLauncher();
  cekRelayIgniter(); // matikan relay otomatis setelah DURASI_RELAY_MS

  long jarak = bacaJarakStabilCM();

  if (status == SCANNING) {
    sapuRadar();
    prosesZona(jarak);
  } else if (status == TARGET_TERKUNCI) {
    // Masih tahap penguncian awal -> boleh batal kalau objek pergi
    cekObjekMasihAda(jarak);
  }
  // status == SIAP_TEMBAK -> JANGAN cek ultrasonic lagi, target sudah
  // dikunci untuk ditembak, tinggal tunggu tombol ke-2. Ini mencegah
  // servo rotasi/elevasi ter-reset sendiri gara-gara noise sensor.

  int kodeKirim = hitungKodeStatus();

  kirimDataRadar(jarak, kodeKirim);
}

// ============================================================
// Servo radar menyapu 0 - 180 derajat (non-blocking) -> HANYA saat SCANNING
void sapuRadar() {
  if (millis() - waktuServoTerakhir < (unsigned long)JEDA_SERVO_MS) return;
  waktuServoTerakhir = millis();

  sudutSekarang += arahSapuan * LANGKAH_SUDUT;

  if (sudutSekarang >= SUDUT_MAX) {
    sudutSekarang = SUDUT_MAX;
    arahSapuan = -1;
  } else if (sudutSekarang <= SUDUT_MIN) {
    sudutSekarang = SUDUT_MIN;
    arahSapuan = 1;
  }

  servoScan.write(sudutSekarang);
}

// ============================================================
long bacaJarakSekaliCM() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long durasi = pulseIn(ECHO_PIN, HIGH, 20000);
  if (durasi == 0) return -1;

  long jarak = durasi * 0.0343 / 2;
  return jarak;
}

// ============================================================
// Ambil 3 sampel jarak, tapi HANYA hitung dari sampel yang VALID
// (bukan hasil timeout). Sensor HC-SR04 sering gagal memberi echo
// yang valid justru saat objek sangat dekat (persis di zona merah),
// jadi kita tidak boleh mensyaratkan mayoritas sampel valid -
// cukup 1 pembacaan valid saja sudah dianggap ada objek, supaya
// lebih sensitif dan tidak melewatkan target dekat.
long bacaJarakStabilCM() {
  long valid[3];
  int jumlahValid = 0;

  for (int i = 0; i < 3; i++) {
    long s = bacaJarakSekaliCM();
    if (s > 0) {
      valid[jumlahValid] = s;
      jumlahValid++;
    }
    delayMicroseconds(500);
  }

  if (jumlahValid == 0) return -1; // benar-benar tidak ada objek

  if (jumlahValid == 1) return valid[0];

  if (jumlahValid == 2) return (valid[0] + valid[1]) / 2;

  // jumlahValid == 3 -> pakai median (urutkan lalu ambil tengah)
  if (valid[0] > valid[1]) { long t = valid[0]; valid[0] = valid[1]; valid[1] = t; }
  if (valid[1] > valid[2]) { long t = valid[1]; valid[1] = valid[2]; valid[2] = t; }
  if (valid[0] > valid[1]) { long t = valid[0]; valid[0] = valid[1]; valid[1] = t; }

  return valid[1];
}

// ============================================================
// Tentukan zona jarak & nyalakan LED. Kunci target (hentikan servo
// radar total) begitu masuk zona merah.
void prosesZona(long jarak) {
  if (jarak <= 0) {
    matikanSemuaLed();
    return;
  }

  if (jarak > ZONA_AMAN_MIN) {
    digitalWrite(LED_HIJAU, HIGH);
    digitalWrite(LED_KUNING, LOW);
    digitalWrite(LED_MERAH, LOW);
  } else if (jarak > ZONA_SEDANG_MIN) {
    digitalWrite(LED_HIJAU, LOW);
    digitalWrite(LED_KUNING, HIGH);
    digitalWrite(LED_MERAH, LOW);
  } else {
    // ZONA MERAH -> kunci target, servo radar berhenti total
    digitalWrite(LED_HIJAU, LOW);
    digitalWrite(LED_KUNING, LOW);
    digitalWrite(LED_MERAH, HIGH);
    kuncikanTarget(sudutSekarang, jarak);
  }
}

// ============================================================
void kuncikanTarget(int sudut, long jarak) {
  status = TARGET_TERKUNCI;
  sudutTarget = sudut;
  jarakTarget = jarak;
}

// ============================================================
// Selama TARGET_TERKUNCI, pastikan objek masih di zona merah.
// Kalau hilang, batalkan dan kembali scanning.
void cekObjekMasihAda(long jarak) {
  bool masihAda = (jarak > 0 && jarak <= ZONA_SEDANG_MIN);

  if (!masihAda) {
    status = SCANNING;
    matikanSemuaLed();
    servoRotasi.write(90);
    servoElevasi.write(SUDUT_ELEVASI_AWAL);
  }
}

// ============================================================
void matikanSemuaLed() {
  digitalWrite(LED_HIJAU, LOW);
  digitalWrite(LED_KUNING, LOW);
  digitalWrite(LED_MERAH, LOW);
}

// ============================================================
// Nyalakan relay igniter (non-blocking). Relay akan mati sendiri
// setelah DURASI_RELAY_MS lewat cekRelayIgniter() di loop().
void nyalakanRelayIgniter() {
  digitalWrite(RELAY_IGNITER_PIN, HIGH);
  relayIgniterAktif = true;
  waktuRelayMati = millis() + DURASI_RELAY_MS;
}

// ============================================================
void cekRelayIgniter() {
  if (relayIgniterAktif && millis() >= waktuRelayMati) {
    digitalWrite(RELAY_IGNITER_PIN, LOW);
    relayIgniterAktif = false;
  }
}

// ============================================================
void cekTombolLauncher() {
  int statusTombol = digitalRead(BUTTON_PIN);

  if (statusTombol == LOW && statusTombolSebelumnya == HIGH) {
    if (millis() - waktuTombolTerakhir > DEBOUNCE_MS) {
      waktuTombolTerakhir = millis();
      tombolDitekan();
    }
  }
  statusTombolSebelumnya = statusTombol;
}

// ============================================================
// Aksi tombol, tergantung state saat ini:
// - SCANNING            -> belum ada target, tampilkan peringatan
// - TARGET_TERKUNCI     -> servo rotasi ke target & servo elevasi ke posisi tembak (tombol ke-1)
// - SIAP_TEMBAK         -> luncurkan roket (tombol ke-2), servo tetap diam, lalu status ke SCANNING
void tombolDitekan() {
  if (status == SCANNING) {
    kodePesanSementara = 4; // belum ada target terkunci
    waktuPesanBerakhir = millis() + 2000;
    return;
  }

  if (status == TARGET_TERKUNCI) {
    // Tombol ke-1: arahkan servo rotasi ke target, servo elevasi ke posisi tembak
    servoRotasi.write(sudutTarget);
    servoElevasi.write(SUDUT_ELEVASI_TEMBAK);

    status = SIAP_TEMBAK;
    return;
  }

  if (status == SIAP_TEMBAK) {
    // Tombol ke-2: luncurkan -> nyalakan relay igniter
    nyalakanRelayIgniter();

    kodePesanSementara = 3; // "ROKET DILUNCURKAN"
    waktuPesanBerakhir = millis() + 3000;

    // Kembali ke scanning, tapi servo rotasi & elevasi DIAM di posisi
    // terakhir (tidak dikembalikan ke posisi awal)
    status = SCANNING;
    matikanSemuaLed();
    return;
  }
}

// ============================================================
int hitungKodeStatus() {
  // Pesan sementara (tombol tanpa target / roket meluncur) diprioritaskan
  if (kodePesanSementara != 0) {
    if (millis() < waktuPesanBerakhir) {
      return kodePesanSementara;
    } else {
      kodePesanSementara = 0;
    }
  }

  if (status == SCANNING) return 0;
  if (status == TARGET_TERKUNCI) return 1;
  if (status == SIAP_TEMBAK) return 2;
  return 0;
}

// ============================================================
// Format data serial: sudut,jarak,kode.
void kirimDataRadar(long jarak, int kodeStatus) {
  long jarakKirim = (jarak <= 0) ? 9999 : jarak;

  Serial.print(sudutSekarang);
  Serial.print(",");
  Serial.print(jarakKirim);
  Serial.print(",");
  Serial.print(kodeStatus);
  Serial.print(".");
}
