/*
  ============================================================
  IRONDOME RADAR VISUAL - Processing (versi titik-titik / blip)
  ============================================================
  Menerima data dari Arduino lewat Serial dengan format:
    "sudut,jarak,kodeStatus."
    contoh: "72,12,2."

  Arti kodeStatus (harus sama dengan kode Arduino):
    0 = SCANNING
    1 = TARGET_TERKUNCI (radar berhenti, menunggu tombol ke-1)
    2 = SIAP_TEMBAK (servo launcher sudah diarahkan, menunggu tombol ke-2)
    3 = ROKET_MELUNCUR (pesan sementara setelah tombol ke-2)
    4 = PERINGATAN: tombol ditekan tapi belum ada target

  CARA PAKAI:
  1. Upload sketch Arduino ke board
  2. JANGAN buka Serial Monitor Arduino IDE
  3. Jalankan sketch ini, lihat Console untuk daftar port
  4. Ubah INDEX_PORT sesuai port Arduino kamu, lalu jalankan ulang
  ============================================================
*/

import processing.serial.*;

Serial myPort;

// ================== UBAH INI SESUAI PORT ARDUINO KAMU ==================
final int INDEX_PORT = 0;

// ================== KONFIGURASI RADAR (samakan dengan Arduino) ==================
final int ZONA_AMAN_MIN     = 30;
final int ZONA_SEDANG_MIN   = 15;
final int JARAK_TAMPIL_MAKS = 60;     // jarak terjauh yang digambar (cm)
final int TANDA_TIDAK_ADA_OBJEK = 9999;

// ================== KONFIGURASI EFEK VISUAL ==================
final int UMUR_BLIP_MS    = 4000;     // titik memudar dalam 4 detik
final int MAKS_BLIP       = 700;
final int JEDA_BLIP_MS    = 40;       // jeda minimal antar titik baru
final int PANJANG_JEJAK   = 36;       // panjang ekor garis sapuan

// ================== DATA DARI ARDUINO ==================
int sudut       = 90;
int jarak       = TANDA_TIDAK_ADA_OBJEK;
int kodeStatus  = 0;

// ================== STATE VISUAL ==================
float cxRadar, cyRadar, radiusRadar;
ArrayList<Blip> blips = new ArrayList<Blip>();
float[] jejak = new float[PANJANG_JEJAK];
int jarakTerkunci = TANDA_TIDAK_ADA_OBJEK;   // jarak target saat terkunci
long waktuBlipTerakhir = 0;

// Satu titik deteksi
class Blip {
  float a, d;
  int t;
  Blip(float a, float d) {
    this.a = a;
    this.d = d;
    this.t = millis();
  }
}

// ============================================================
void setup() {
  size(1000, 700);
  smooth(8);
  textFont(createFont("Consolas", 16));

  cxRadar = width / 2.0;
  cyRadar = height - 110;
  radiusRadar = (width - 100) / 2.0;

  for (int i = 0; i < PANJANG_JEJAK; i++) jejak[i] = sudut;

  println("Daftar port yang tersedia:");
  printArray(Serial.list());

  String namaPort = Serial.list()[INDEX_PORT];
  myPort = new Serial(this, namaPort, 9600);
  myPort.bufferUntil('.');
}

// ============================================================
void draw() {
  background(2, 10, 6);

  gambarGlowLatar();
  gambarLatarRadar();
  gambarBlips();
  gambarJejakSapuan();
  gambarMarkerTarget();
  gambarScanlines();
  gambarHUD();
  gambarPanelStatus();
  gambarBanner();
}

// ============================================================
boolean targetTerkunci() {
  return (kodeStatus == 1 || kodeStatus == 2);
}

// ============================================================
void serialEvent(Serial myPort) {
  String data = myPort.readStringUntil('.');
  if (data == null) return;

  data = data.trim();
  data = data.replace(".", "");

  String[] bagian = split(data, ',');
  if (bagian.length != 3) return;

  try {
    sudut      = int(bagian[0]);
    jarak      = int(bagian[1]);
    kodeStatus = int(bagian[2]);
  } catch (Exception e) {
    return;
  }

  perbaruiVisual();
}

// ============================================================
void perbaruiVisual() {
  // Ekor garis sapuan: geser riwayat sudut saat sudut berubah
  if (abs(sudut - jejak[0]) >= 1) {
    for (int i = PANJANG_JEJAK - 1; i > 0; i--) jejak[i] = jejak[i - 1];
    jejak[0] = sudut;
  }

  boolean objekAda = (jarak > 0 && jarak < TANDA_TIDAK_ADA_OBJEK);

  // Tambah titik deteksi (dengan sedikit sebaran supaya terlihat seperti kumpulan titik)
  if (objekAda && jarak <= JARAK_TAMPIL_MAKS && millis() - waktuBlipTerakhir > JEDA_BLIP_MS) {
    waktuBlipTerakhir = millis();
    for (int i = 0; i < 2; i++) {
      float a = sudut + random(-1.5, 1.5);
      float d = jarak * random(0.96, 1.04);
      blips.add(new Blip(a, d));
    }
    while (blips.size() > MAKS_BLIP) blips.remove(0);
  }

  // Jarak target saat terkunci (dibekukan setelah tombol ke-1)
  if (!targetTerkunci()) {
    jarakTerkunci = TANDA_TIDAK_ADA_OBJEK;
  } else if (objekAda && (jarakTerkunci == TANDA_TIDAK_ADA_OBJEK || kodeStatus == 1)) {
    jarakTerkunci = jarak;
  }
}

// ============================================================
float radiusDariJarak(float cm) {
  return map(constrain(cm, 0, JARAK_TAMPIL_MAKS), 0, JARAK_TAMPIL_MAKS, 0, radiusRadar);
}

float titikX(float a, float r) { return cxRadar + r * cos(radians(a)); }
float titikY(float a, float r) { return cyRadar - r * sin(radians(a)); }

color warnaZona(float cm) {
  if (cm > ZONA_AMAN_MIN)   return color(60, 255, 120);
  if (cm > ZONA_SEDANG_MIN) return color(255, 220, 50);
  return color(255, 60, 60);
}

// ============================================================
// Cahaya hijau lembut di sekitar pusat radar
void gambarGlowLatar() {
  noStroke();
  for (int i = 8; i >= 1; i--) {
    fill(0, 90, 40, 9);
    ellipse(cxRadar, cyRadar, radiusRadar * 2 * i / 8.0, radiusRadar * 2 * i / 8.0);
  }
}

// ============================================================
void gambarLatarRadar() {
  noFill();

  // Cincin jarak: 15 cm (merah), 30 cm (kuning), 45 & 60 cm (hijau)
  int[] cincin = { ZONA_SEDANG_MIN, ZONA_AMAN_MIN, 45, JARAK_TAMPIL_MAKS };
  for (int i = 0; i < cincin.length; i++) {
    float r = radiusDariJarak(cincin[i]);
    color c = warnaZona(cincin[i] - 0.1);
    if (cincin[i] > ZONA_AMAN_MIN) c = color(60, 255, 120);

    strokeWeight(i == cincin.length - 1 ? 2.5 : 1.5);
    stroke(c, i == cincin.length - 1 ? 170 : 110);
    arc(cxRadar, cyRadar, r * 2, r * 2, PI, TWO_PI);

    noStroke();
    fill(c, 200);
    textSize(12);
    textAlign(CENTER, TOP);
    text(cincin[i] + " cm", cxRadar + r - 22, cyRadar + 6);
    noFill();
  }

  // Garis sudut tiap 30 derajat
  stroke(60, 255, 120, 55);
  strokeWeight(1);
  for (int a = 0; a <= 180; a += 30) {
    line(cxRadar, cyRadar, titikX(a, radiusRadar), titikY(a, radiusRadar));

    noStroke();
    fill(60, 255, 120, 190);
    textSize(13);
    textAlign(CENTER, CENTER);
    text(a + "°", titikX(a, radiusRadar + 22), titikY(a, radiusRadar + 22));
    noFill();
    stroke(60, 255, 120, 55);
  }

  // Garis dasar
  stroke(60, 255, 120, 150);
  strokeWeight(2);
  line(cxRadar - radiusRadar, cyRadar, cxRadar + radiusRadar, cyRadar);

  // Titik pusat
  noStroke();
  fill(60, 255, 120);
  ellipse(cxRadar, cyRadar, 10, 10);
}

// ============================================================
// Titik-titik deteksi: ada halo cahaya, mengecil dan memudar seiring waktu
void gambarBlips() {
  noStroke();
  for (int i = blips.size() - 1; i >= 0; i--) {
    Blip b = blips.get(i);
    float umur = millis() - b.t;
    if (umur > UMUR_BLIP_MS) {
      blips.remove(i);
      continue;
    }

    float f = umur / UMUR_BLIP_MS;      // 0 = baru, 1 = hampir hilang
    float alpha = 255 * (1 - f);
    float r = radiusDariJarak(b.d);
    float x = titikX(b.a, r);
    float y = titikY(b.a, r);

    color c = warnaZona(b.d);

    fill(c, alpha * 0.12);
    ellipse(x, y, 26 * (1 - f * 0.5), 26 * (1 - f * 0.5));
    fill(c, alpha * 0.30);
    ellipse(x, y, 15 * (1 - f * 0.5), 15 * (1 - f * 0.5));
    fill(c, alpha);
    ellipse(x, y, 6.5 * (1 - f * 0.4), 6.5 * (1 - f * 0.4));
  }
}

// ============================================================
// Garis sapuan dengan ekor yang memudar
void gambarJejakSapuan() {
  color c = targetTerkunci() ? color(255, 60, 60) : color(60, 255, 120);

  strokeCap(ROUND);
  for (int i = PANJANG_JEJAK - 1; i >= 1; i--) {
    float alpha = map(i, 0, PANJANG_JEJAK, 110, 0);
    stroke(c, alpha);
    strokeWeight(3);
    line(cxRadar, cyRadar, titikX(jejak[i], radiusRadar), titikY(jejak[i], radiusRadar));
  }

  stroke(c);
  strokeWeight(3);
  line(cxRadar, cyRadar, titikX(sudut, radiusRadar), titikY(sudut, radiusRadar));
}

// ============================================================
// Marker berdenyut saat target terkunci
void gambarMarkerTarget() {
  if (!targetTerkunci() || jarakTerkunci >= TANDA_TIDAK_ADA_OBJEK) return;

  float r = radiusDariJarak(jarakTerkunci);
  float x = titikX(sudut, r);
  float y = titikY(sudut, r);

  color c = color(80, 200, 255);
  String label = "TARGET TERKUNCI";

  float denyut = (sin(millis() / 180.0) + 1) / 2.0;   // 0..1

  noFill();
  stroke(c, 255 - denyut * 150);
  strokeWeight(2);
  ellipse(x, y, 30 + denyut * 26, 30 + denyut * 26);

  stroke(c);
  strokeWeight(2.5);
  ellipse(x, y, 30, 30);
  line(x - 24, y, x - 10, y);
  line(x + 10, y, x + 24, y);
  line(x, y - 24, x, y - 10);
  line(x, y + 10, x, y + 24);

  noStroke();
  fill(c);
  textSize(14);
  textAlign(CENTER, BOTTOM);
  text(label, x, y - 34);
  textSize(12);
  textAlign(CENTER, TOP);
  text(jarakTerkunci + " cm", x, y + 28);
}

// ============================================================
void gambarScanlines() {
  stroke(0, 0, 0, 40);
  strokeWeight(1);
  for (int y = 0; y < height; y += 4) line(0, y, width, y);
}

// ============================================================
void gambarHUD() {
  // Judul
  noStroke();
  fill(60, 255, 120);
  textAlign(LEFT, TOP);
  textSize(22);
  text("IRONDOME RADAR", 24, 20);
  fill(60, 255, 120, 140);
  textSize(12);
  text("SCAN 0-180° | HC-SR04", 24, 48);

  // Legenda kanan atas
  textAlign(RIGHT, TOP);
  textSize(12);
  float x = width - 24;
  fill(255, 60, 60);   text("● <" + ZONA_SEDANG_MIN + " cm  ZONA DEKAT", x, 20);
  fill(255, 220, 50);  text("● " + ZONA_SEDANG_MIN + "-" + ZONA_AMAN_MIN + " cm  ZONA SEDANG", x, 38);
  fill(60, 255, 120);  text("● >" + ZONA_AMAN_MIN + " cm  ZONA AMAN", x, 56);
  fill(80, 200, 255);  text("● TARGET TERKUNCI", x, 74);
}

// ============================================================
void gambarPanelStatus() {
  noStroke();
  fill(60, 255, 120);
  textSize(16);
  textAlign(LEFT, BASELINE);
  boolean objekAda = (jarak > 0 && jarak < TANDA_TIDAK_ADA_OBJEK);
  text("Sudut : " + sudut + "°", 24, height - 66);
  text("Jarak : " + (objekAda ? jarak + " cm" : "-"), 190, height - 66);

  if (targetTerkunci()) fill(80, 200, 255);
  else                  fill(130);
  text("Target : " + (targetTerkunci() ? "TERKUNCI" : "-"), 360, height - 66);

  String teksStatus;
  color warnaStatus;

  switch (kodeStatus) {
    case 0:
      teksStatus = "STATUS: SCANNING...";
      warnaStatus = color(60, 255, 120);
      break;
    case 1:
      teksStatus = "STATUS: TARGET TERKUNCI - tekan tombol untuk arahkan launcher";
      warnaStatus = color(255, 60, 60);
      break;
    case 2:
      teksStatus = "STATUS: SIAP TEMBAK - tekan tombol lagi untuk meluncurkan";
      warnaStatus = color(255, 150, 0);
      break;
    case 3:
      teksStatus = "ROKET MELUNCUR!";
      warnaStatus = color(255, 0, 0);
      break;
    case 4:
      teksStatus = "PERINGATAN: Tombol ditekan, belum ada target terkunci";
      warnaStatus = color(255, 200, 0);
      break;
    default:
      teksStatus = "STATUS: -";
      warnaStatus = color(150);
  }

  fill(warnaStatus);
  textSize(18);
  text(teksStatus, 24, height - 28);
}

// ============================================================
// Banner besar di atas untuk pesan sementara (kode 3 dan 4)
void gambarBanner() {
  if (kodeStatus < 3) return;

  String teks;
  color c;
  float kedip = (sin(millis() / 90.0) + 1) / 2.0;

  if (kodeStatus == 3) {
    teks = "ROKET MELUNCUR!";
    c = color(255, 0, 0);
  } else {
    teks = "BELUM ADA TARGET";
    c = color(255, 200, 0);
  }

  pushStyle();
  rectMode(CENTER);
  fill(red(c), green(c), blue(c), 30 + kedip * 50);
  stroke(c);
  strokeWeight(2.5);
  rect(width / 2.0, 130, 460, 70, 10);

  noStroke();
  fill(c);
  textAlign(CENTER, CENTER);
  textSize(38);
  text(teks, width / 2.0, 130);
  popStyle();
}
