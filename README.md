# Tes Djadja — Aplikasi Inventory (Supplier, Barang, Pembelian, Penerimaan)

Aplikasi mobile manajemen inventaris yang dibangun dengan **Flutter** sebagai studi kasus technical test. Aplikasi terhubung ke REST API (NestJS + MySQL) untuk mengelola master data dan transaksi pembelian barang.

> Backend API berada di repository/folder terpisah (`backend_testdjaja`) — lihat README backend untuk petunjuk menjalankan API.

## Fitur

- **Supplier** — CRUD supplier, filter status (aktif/nonaktif), pencarian, statistik jumlah PO & total belanja per supplier
- **Barang** — CRUD barang, pencarian, detail stok & nilai stok
- **Pembelian (PO)** — buat PO dengan multi-item, ubah status (draft → diproses/dibatalkan), edit & hapus saat draft, detail item dengan progress penerimaan
- **Penerimaan** — buat penerimaan dari PO berstatus *diproses*, input qty terima per item (maksimal sisa PO), selesaikan penerimaan untuk menambah stok otomatis
- Umum: infinite scroll pagination, search debounce, pull-to-refresh, validasi form, dan status badge yang konsisten dengan aturan bisnis backend

## Teknologi

- **Flutter** (Dart 3) — frontend mobile
- **Provider** — state management
- **Dio** — HTTP client untuk REST API
- **Intl** — format mata uang Rupiah

## Struktur Proyek

```
lib/
├── core/            # Konfigurasi dasar (base URL API, API client)
├── models/          # Model data + parsing JSON null-safe
├── providers/       # State management (Provider) per modul
├── services/        # Komunikasi REST API per modul
└── ui/              # Halaman & widget
    ├── barang/      # List, detail, form barang
    ├── pembelian/   # List, detail, form pembelian
    ├── penerimaan/  # List, detail, form penerimaan
    ├── supplier/    # List, detail, form supplier
    └── widgets/     # Komponen reusable (card, badge, dialog, dll)
```

## Persiapan

1. Pastikan **Flutter SDK** (3.x) dan perangkat/emulator Android sudah terpasang
2. Jalankan **backend API** terlebih dahulu (lihat README di folder backend) — default berjalan di port `3000`

## Menjalankan Aplikasi

1. Sesuaikan alamat API di `lib/core/constants.dart`:

   ```dart
   // Emulator Android: 10.0.2.2 = localhost komputer
   // HP asli: ganti ke IP LAN komputer (cek: ip -4 addr show), HP & PC harus 1 WiFi
   static const String baseUrl = 'http://<IP_KOMPUTER>:3000/api/v1';
   ```

2. Install dependency dan jalankan:

   ```bash
   flutter pub get
   flutter run
   ```

## Alur Penggunaan

1. Tambah **Supplier** (kode dibuat otomatis oleh backend; telepon & alamat wajib diisi)
2. Tambah **Barang** (kode & stok awal otomatis; stok hanya bertambah lewat penerimaan)
3. Buat **Pembelian** — pilih supplier aktif, tanggal, dan item (harga otomatis dari master barang)
4. Ubah status PO menjadi **Diproses**
5. Buka tab **Penerimaan**, pilih PO diproses, isi qty terima, simpan, lalu **Selesaikan** — stok barang bertambah otomatis
