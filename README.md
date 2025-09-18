# POS RP (Point of Sale)

Aplikasi Point of Sale (POS) komprehensif yang dibangun dengan Flutter. Proyek ini menyediakan solusi untuk mengelola penjualan, inventaris, pelanggan, dan pelaporan bisnis untuk usaha kecil hingga menengah.

## Fitur Utama

- **Autentikasi Pengguna**: Sistem login dan registrasi untuk mengamankan akses, beserta manajemen profil pengguna.
- **Manajemen Produk**: Operasi CRUD (Create, Read, Update, Delete) untuk produk, termasuk detail seperti stok, harga beli, dan harga jual.
- **Manajemen Pelanggan**: Mencatat dan mengelola data pelanggan.
- **Manajemen Supplier**: Mengelola data pemasok barang.
- **Point of Sale (Kasir)**: Antarmuka kasir untuk membuat transaksi penjualan dengan fungsionalitas keranjang belanja (`Cart`).
- **Manajemen Pembelian**: Mencatat transaksi pembelian barang dari supplier dan secara otomatis memperbarui stok serta harga pokok produk.
- **Manajemen Biaya**: Mencatat semua biaya operasional bisnis.
- **Laporan Komprehensif**:
  - Laporan Penjualan
  - Laporan Laba & Rugi (P&L)
  - Laporan Inventaris
  - Laporan Arus Kas
  - Laporan Pembelian
- **Penyimpanan Lokal**: Menggunakan database SQLite untuk menyimpan semua data secara lokal di perangkat, memastikan aplikasi dapat berfungsi secara offline.

## Struktur Proyek

Proyek ini disusun dengan arsitektur yang bersih dan terukur untuk kemudahan pengembangan dan pemeliharaan.

```
lib/
├── models/         # Berisi kelas model data (Product, Customer, Transaction, dll.)
├── providers/      # Logika bisnis dan state management menggunakan Provider.
├── screens/        # Berisi file UI untuk setiap layar/halaman aplikasi.
├── services/       # Layanan backend seperti interaksi database (DatabaseHelper).
├── widgets/        # Komponen UI yang dapat digunakan kembali.
└── main.dart       # Titik masuk utama aplikasi.
```

- **`models/`**: Direktori ini berisi semua kelas model data yang merepresentasikan entitas dalam aplikasi, seperti `Product`, `Customer`, `Transaction`, dan `User`.
- **`providers/`**: Mengimplementasikan state management menggunakan `ChangeNotifier` dari paket `provider`. Setiap provider bertanggung jawab atas satu bagian dari state aplikasi (misalnya, `ProductProvider` mengelola data produk).
- **`screens/`**: Setiap file di sini mewakili satu layar dalam aplikasi, yang bertanggung jawab untuk membangun UI dan menghubungkannya dengan `provider` untuk mendapatkan dan memanipulasi data.
- **`services/`**: Berisi kelas-kelas yang menyediakan fungsionalitas spesifik, seperti `DatabaseHelper` yang mengelola semua operasi CRUD ke database SQLite.

## Teknologi yang Digunakan

- **Framework**: Flutter
- **State Management**: `provider`
- **Database**: `sqflite`
- **ID Generation**: `uuid`
- **Local Session**: `shared_preferences`
