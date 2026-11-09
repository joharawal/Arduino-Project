# 🛡️ Irondome Radar

**Radar ultrasonic berbasis Arduino dengan visualisasi real-time di Processing dan simulasi peluncur roket ke titik target.**

Proyek mata kuliah **Teknik Radar dan Navigasi** — Kelompok 5 TE-3E, Sarjana Terapan Teknik Telekomunikasi, Jurusan Teknik Elektro, Polines Semarang (2026).

---

## 📖 Deskripsi

Irondome Radar adalah sistem radar mini yang memindai area setengah lingkaran (0°–180°) menggunakan sensor ultrasonic HC-SR04 yang dipasang di atas servo. Sistem mendeteksi objek, menentukan sudut dan jaraknya, lalu menampilkannya pada layar radar bergaya militer di komputer.

Selain mendeteksi, sistem memiliki fungsi pengamanan tambahan: ketika target terdeteksi pada zona dekat, radar **mengunci target**, **mengarahkan peluncur (launcher)** ke posisi target, dan meluncurkan roket **(simulasi)** melalui relay dan voltage igniter setelah operator mengonfirmasi dengan tombol.

## ✨ Fitur Utama

- Pemindaian otomatis 0°–180° dengan servo sweep
- Pengukuran jarak real-time dengan HC-SR04
- Pembagian **3 zona jarak** dengan indikator LED dan buzzer
- **Penguncian target** otomatis saat objek masuk zona dekat
- Launcher dengan **2 servo** (rotasi dan elevasi) yang diarahkan ke target
- Peluncuran roket (simulasi) dengan **konfirmasi dua tahap** (2 tombol) demi keamanan
- Visualisasi radar di **Processing**: garis sapuan dengan ekor memudar, titik deteksi (blip), marker target berdenyut, dan panel status

## 🧰 Komponen

| Komponen | Fungsi |
|---|---|
| Arduino Uno | Pengendali utama |
| Sensor ultrasonic HC-SR04 | Mengukur jarak objek |
| Servo 1 (sweep) | Memutar sensor 0°–180° |
| Servo 2 (rotasi launcher) | Mengarahkan launcher ke sudut target |
| Servo 3 (elevasi launcher) | Mengatur kemiringan launcher |
| LED (hijau, kuning, merah) | Indikator zona jarak |
| Buzzer | Peringatan suara (pola bip berbeda tiap zona) |
| Tombol | Konfirmasi operator (kunci/arahkan dan tembak) |
| Relay + voltage igniter | Pemantik peluncuran roket |
| Resistor, kabel jumper, breadboard | Pendukung rangkaian |

## 🧠 Konsep Sistem

### 1. Prinsip pengukuran jarak (ultrasonic)

HC-SR04 memancarkan gelombang suara ultrasonic (40 kHz) lewat pin *Trigger*, lalu pin *Echo* mengeluarkan pulsa selama waktu pantulan kembali. Jarak dihitung dengan:

```
jarak (cm) = (durasi × 0,034) / 2
```

Dibagi 2 karena gelombang menempuh jalur pergi-pulang.

### 2. Pemindaian sudut (sweep)

Servo memutar sensor dari 0° ke 180° dan kembali. Pada setiap sudut, Arduino mengukur jarak. Pasangan **(sudut, jarak)** inilah koordinat polar objek yang dideteksi.

### 3. Zona jarak

| Zona | Jarak | LED | Keterangan |
|---|---|---|---|
| Aman | > 30 cm | 🟢 Hijau | Objek jauh, radar tetap memindai |
| Sedang | 15 – 30 cm | 🟡 Kuning | Objek mendekat, waspada |
| Dekat | ≤ 15 cm | 🔴 Merah | Target dikunci |

Radar menampilkan objek hingga **60 cm** pada layar.

### 4. Komunikasi Arduino → Processing

Arduino mengirim data lewat **Serial (USB)** pada baud rate **9600** dengan format teks:

```
sudut,jarak,kodeStatus.
contoh: 72,12,2.
```

Tanda titik (`.`) di akhir adalah penanda akhir paket data. Processing membaca port serial, memecah data menjadi tiga angka, lalu menggambar ulang visualisasi.

| Kode | Status | Arti |
|---|---|---|
| 0 | SCANNING | Radar memindai |
| 1 | TARGET TERKUNCI | Radar berhenti, menunggu tombol ke-1 |
| 2 | SIAP TEMBAK | Launcher sudah diarahkan, menunggu tombol ke-2 |
| 3 | ROKET MELUNCUR | Pesan sementara setelah tombol ke-2 |
| 4 | PERINGATAN | Tombol ditekan tetapi belum ada target |

Nilai jarak `9999` menandakan **tidak ada objek terdeteksi**.

### 5. Konversi koordinat di layar

Processing mengubah koordinat polar (sudut, jarak) menjadi koordinat piksel (x, y):

```
x = cx + r · cos(sudut)
y = cy − r · sin(sudut)
```

dengan `r` adalah jarak yang dipetakan ke radius radar di layar (`map()` dari 0–60 cm ke 0–radius piksel).

## 🔄 Alur Kerja Sistem

```
┌──────────────┐   ┌───────────────┐   ┌────────────────────┐
│ Servo sweep  │──►│ HC-SR04 ukur  │──►│ Arduino hitung     │
│ 0° → 180°    │   │ jarak          │   │ jarak & tentukan   │
└──────────────┘   └───────────────┘   │ zona + status      │
                                        └─────────┬──────────┘
                    ┌─────────────────────────────┼──────────────────────┐
                    ▼                             ▼                      ▼
          LED + Buzzer sesuai zona     Kirim "sudut,jarak,status."   Logika penguncian
                                       via Serial ke Processing      & peluncuran
                                                  │
                                                  ▼
                                      Processing menampilkan radar
```

**Alur operasi:**

1. **Scanning (status 0):** servo menyapu 0°–180°, jarak dibaca di tiap sudut, LED dan buzzer menyesuaikan zona, data dikirim ke Processing.
2. **Target terkunci (status 1):** bila objek masuk zona dekat (≤ 15 cm), servo sweep berhenti dan sistem mengunci sudut dan jarak target.
3. **Siap tembak (status 2):** setelah tombol ke-1 ditekan, servo launcher (rotasi dan elevasi) diarahkan ke target.
4. **Roket meluncur (status 3):** setelah tombol ke-2 ditekan, relay mengaktifkan voltage igniter dengan pulsa singkat. Roket diluncurkan (simulasi), lalu sistem kembali ke mode scanning.
5. **Peringatan (status 4):** bila tombol ditekan saat belum ada target terkunci, sistem menampilkan peringatan dan tidak meluncurkan apa pun.

## 🖥️ Visualisasi Processing

Tampilan radar terdiri dari beberapa lapisan:

- Cincin jarak 15, 30, 45, dan 60 cm dengan warna sesuai zona
- Garis sudut setiap 30°
- Garis sapuan dengan ekor yang memudar (hijau saat scanning, merah saat terkunci)
- Titik deteksi (*blip*) yang memudar dalam 4 detik
- Marker target biru berdenyut dengan label jarak
- HUD berisi judul, legenda zona, serta panel sudut, jarak, dan status
- Banner berkedip saat roket meluncur atau saat ada peringatan

## 📁 Struktur Repositori

```
irondome-radar/
├──   radar_launcher.ino            # Kode Arduino (sensor, servo, launcher)
├──   irondome_radar_visual.pde     # Visualisasi radar di Processing
├──   Diagram_Wiring.jpg            # Wiring System
└──   README.md
```

> Sesuaikan nama file dan folder dengan isi repositori kamu.

## 🚀 Cara Menjalankan

### Prasyarat
- [Arduino IDE](https://www.arduino.cc/en/software)
- [Processing](https://processing.org/download) (library `processing.serial` sudah bawaan)
- Library `Servo` (bawaan Arduino IDE)

### Langkah

1. **Rakit rangkaian** sesuai skematik di file `Diagram_Wiring.jpg `.
2. **Upload** sketch Arduino ke board Arduino Uno.
3. **Tutup Serial Monitor** Arduino IDE. Satu port serial hanya bisa dipakai satu program.
4. **Buka** `irondome_radar_visual.pde` di Processing, lalu klik **Run**. Daftar port akan tampil di Console.
5. **Ubah** nilai `INDEX_PORT` sesuai posisi port Arduino pada daftar, lalu jalankan ulang.
6. Radar mulai menampilkan hasil pemindaian secara real-time.

### Konfigurasi yang harus sama antara Arduino dan Processing

| Parameter | Nilai |
|---|---|
| Baud rate | 9600 |
| Batas zona sedang | 15 cm |
| Batas zona aman | 30 cm |
| Kode status | 0–4 |
| Penanda tidak ada objek | 9999 |

## 🧪 Hasil Pengujian

Pengujian yang dilakukan pada komponen utama:

- Sensor ultrasonic HC-SR04
- LED hijau, kuning, dan merah sesuai zona jarak (diuji sampai 40 cm)
- Servo scanning 0°–180°
- Kalibrasi sudut servo

Seluruh parameter berhasil sesuai rancangan.

## ⚠️ Catatan

- Peluncuran roket pada proyek ini bersifat **simulasi** untuk keperluan pembelajaran.
- Sensor HC-SR04 memiliki sudut pandang sempit dan akurasi menurun pada permukaan miring atau menyerap suara.
- Jarak tampil maksimum pada layar dibatasi 60 cm.

## 👥 Tim — Kelompok 5 TE-3E

- Elzha Rositawati
- Johar Awal Khoiroti W
- Royan Abdilaah


