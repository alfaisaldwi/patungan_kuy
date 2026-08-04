<div align="center">

<!-- Ganti dengan logo aplikasi kamu (mis. screenshots/logo.png) -->
<img src="screenshots/logo.png" alt="PatunganKuy Logo" width="120" />

# 🧾 PatunganKuy

**Split bill jadi gampang — scan struk, bagi tagihan, langsung share!**

Aplikasi patungan (split bill) untuk kamu dan teman-temanmu. Scan struk pakai kamera, tetapkan pesanan ke masing-masing orang, dan biarkan PatunganKuy menghitung siapa bayar berapa — lengkap dengan pembagian pajak, ongkir, dan diskon secara proporsional.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%5E3.10-0175C2?style=flat&logo=dart&logoColor=white)](https://dart.dev)
[![State Management](https://img.shields.io/badge/State-BLoC-blueviolet?style=flat)](https://bloclibrary.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean-success?style=flat)](#%EF%B8%8F-arsitektur)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat)](#)

</div>

---

## 📱 Screenshots

<!-- Simpan gambar di folder `screenshots/` lalu sesuaikan nama filenya di bawah ini -->

<div align="center">

| Halaman Utama | Scan Struk | Assign Pesanan | Hasil & Share |
| :---: | :---: | :---: | :---: |
| <img src="screenshots/home.png" width="200" alt="Halaman Utama" /> | <img src="screenshots/scan.png" width="200" alt="Scan Struk" /> | <img src="screenshots/assignment.png" width="200" alt="Assign Pesanan" /> | <img src="screenshots/result.png" width="200" alt="Hasil Perhitungan" /> |

</div>

---

## ✨ Fitur

### 📷 Scan Struk (OCR On-Device)
- Ambil foto struk lewat **kamera** atau pilih dari **galeri**.
- Teks dikenali secara **on-device** menggunakan **Google ML Kit Text Recognition** — tanpa internet, tanpa kirim data ke server.
- Parser pintar yang memahami format struk Indonesia (GoFood, GrabFood, dll):
  - Deteksi item beserta jumlah (`2x Ayam Geprek`) dan harganya (`Rp25.000`).
  - Deteksi otomatis **subtotal**, **ongkir/biaya layanan** (ongkir, pengiriman, layanan, platform, dsb.), dan **diskon/voucher/promo** — termasuk harga bernilai minus.

### 👥 Assign Pesanan ke Orang
- Setelah struk di-scan, tetapkan tiap item ke orang yang memesannya lewat **checklist bottom sheet** yang simpel.
- Tambah orang baru langsung dari halaman assignment.
- Biaya dan diskon hasil scan otomatis terbawa ke kalkulator.

### 🧮 Kalkulator Split Bill
- Bisa juga **input manual** tanpa scan — tambah orang, tambah item dan harga per orang.
- Dukung **pajak/biaya layanan**, **ongkir**, dan **diskon** (nominal `Rp` atau persentase `%`).
- Biaya dan diskon dibagi **proporsional** sesuai besar pesanan tiap orang — yang pesan lebih banyak, nanggung fee lebih besar. Adil! ⚖️
- Validasi input lengkap (nama kosong, harga ≤ 0, nilai negatif, dll).

### 🧾 Share Hasil sebagai Gambar Struk atau PDF
- Hasil perhitungan dirender menjadi **gambar struk digital** yang rapi.
- **Ekspor ke PDF** — dokumen struk profesional lengkap dengan rincian item per orang, cocok untuk arsip atau reimburse.
- Bagikan langsung ke WhatsApp, Telegram, atau aplikasi lain via **share sheet** — tinggal kirim ke grup, semua tahu harus bayar berapa.

### 🕘 Riwayat Tagihan (History)
- Setiap tagihan yang dihitung **tersimpan otomatis** secara lokal (Hive) — tanpa akun, tanpa internet.
- Buka riwayat dari AppBar: lihat tanggal, total, dan siapa saja yang ikut patungan.
- Tap sebuah entri untuk melihat **rincian lengkap** per orang beserta itemnya.
- **Load to Calculator** — muat ulang tagihan lama ke kalkulator untuk diedit atau dihitung ulang.
- Hapus per entri atau bersihkan semua riwayat.

### 🌙 Dark Mode
- Toggle terang/gelap langsung dari AppBar.
- Pilihan tema **tersimpan otomatis** dan dipulihkan saat aplikasi dibuka kembali.

---

## 🎯 Cara Pakai

1. **Scan** struk belanja/pesananmu (atau input manual).
2. **Assign** tiap item ke orang yang memesannya.
3. **Hitung** — pajak, ongkir, dan diskon dibagi otomatis secara proporsional.
4. **Share** gambar struk hasil perhitungan ke grup chat. Selesai! 🎉

---

## 🏗️ Arsitektur

Proyek ini menerapkan **Clean Architecture** dengan pemisahan layer yang jelas per fitur, ditambah **BLoC** untuk state management dan **GetIt** untuk dependency injection.

```
lib/
├── main.dart                     # Entry point & konfigurasi tema Material 3
├── injection_container.dart      # Dependency injection (GetIt)
├── core/
│   ├── theme/                    # Design system (warna, tipografi, spacing)
│   └── error/                    # Failure classes (functional error handling)
└── features/
    ├── calculator/               # Fitur split bill
    │   ├── domain/               #   Entities, repository contract, use case
    │   ├── data/                 #   Implementasi repository
    │   └── presentation/         #   BLoC, halaman, generator gambar struk
    ├── scanner/                  # Fitur scan struk (OCR)
    │   ├── domain/               #   ParsedReceipt entity & use case
    │   ├── data/                 #   ML Kit datasource + parser struk
    │   └── presentation/         #   ScannerBloc
    ├── history/                  # Fitur riwayat tagihan
    │   ├── domain/               #   BillHistory entity & use cases
    │   ├── data/                 #   Model JSON + Hive datasource
    │   └── presentation/         #   HistoryBloc & halaman riwayat
    └── assignment/               # Fitur assign item ke orang
        └── presentation/         #   BLoC, model, halaman assignment
```

**Prinsip yang dipakai:**
- **Domain layer** murni Dart, tidak bergantung pada Flutter/framework.
- Error handling fungsional dengan `Either<Failure, T>` dari **dartz**.
- Entities immutable dengan **Equatable**.
- Alur data satu arah: `UI → Event → BLoC → UseCase → Repository → DataSource`.

---

## 🛠️ Tech Stack

| Kategori | Teknologi |
| --- | --- |
| Framework | [Flutter](https://flutter.dev) (Material 3) |
| State Management | [flutter_bloc](https://pub.dev/packages/flutter_bloc) |
| Dependency Injection | [get_it](https://pub.dev/packages/get_it) |
| Functional Programming | [dartz](https://pub.dev/packages/dartz) |
| OCR | [google_mlkit_text_recognition](https://pub.dev/packages/google_mlkit_text_recognition) |
| Ambil Gambar | [image_picker](https://pub.dev/packages/image_picker) |
| Share | [share_plus](https://pub.dev/packages/share_plus) |
| Ekspor PDF | [pdf](https://pub.dev/packages/pdf) |
| Database Lokal | [hive](https://pub.dev/packages/hive) |
| Persistensi Preferensi | [shared_preferences](https://pub.dev/packages/shared_preferences) |
| Value Equality | [equatable](https://pub.dev/packages/equatable) |

---

## 🚀 Menjalankan Proyek

### Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.10`
- Android Studio / Xcode (untuk emulator atau device fisik)

### Langkah

```bash
# Clone repository
git clone https://github.com/<username>/patungan_kuy.git
cd patungan_kuy

# Install dependencies
flutter pub get

# Jalankan aplikasi
flutter run
```

> **Catatan:** Fitur scan struk menggunakan Google ML Kit yang berjalan on-device, sehingga hanya tersedia di **Android** dan **iOS**.

---

## 🤝 Kontribusi

Kontribusi selalu terbuka! Silakan:

1. Fork repository ini
2. Buat branch fitur (`git checkout -b fitur/nama-fitur`)
3. Commit perubahanmu (`git commit -m 'Menambahkan fitur X'`)
4. Push ke branch (`git push origin fitur/nama-fitur`)
5. Buka Pull Request

---

<div align="center">

Dibuat dengan ❤️ dan Flutter

**Patungan? Kuy! 🍜**

</div>
