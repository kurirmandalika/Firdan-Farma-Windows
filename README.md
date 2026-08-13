# Apotek Firdan Farma

Aplikasi desktop Windows untuk manajemen apotek: katalog obat, kasir penjualan,
stok, kategori, supplier, laporan, impor/ekspor Excel, backup database, dan
pengamanan PIN.

## Prinsip Data

- SQLite lokal (`firdan_farma.db`) adalah satu-satunya sumber data operasional.
- Database baru dimulai tanpa obat dan supplier contoh.
- Obat dibuat manual melalui UI dan tetap tersimpan setelah aplikasi ditutup.
- Excel hanya dibaca saat pengguna memilih **Impor sekarang**.
- Laporan dan ekspor Excel dihitung dari transaksi, pembelian, dan riwayat stok
  di SQLite.
- Reset data tersedia di **Data > Area Admin**, selalu membuat backup otomatis,
  dan tidak pernah berjalan saat startup.

## Struktur Folder

- `lib/` - source utama aplikasi Flutter.
- `lib/application/` - provider/state management.
- `lib/core/` - konstanta, tema, dan helper umum.
- `lib/data/` - model, database, dan service data.
- `lib/features/` - halaman fitur aplikasi.
- `lib/shared/` - widget bersama.
- `assets/` - aset aplikasi.
- `test/` - test otomatis.
- `windows/` - konfigurasi platform Windows Flutter.
- `docs/` - dokumentasi project.

## Dokumentasi

- `docs/DESKRIPSI_APLIKASI.txt`
- `docs/USERMANUAL.md`
- `docs/PRD.md`

## Perintah Pengembangan

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

## Catatan

Folder dan file generated seperti `.dart_tool/`, `build/`,
`.flutter-plugins-dependencies`, `.idea/`, file `.iml`, dan `flutter.pid`
tidak perlu dikomit karena dapat dibuat ulang oleh Flutter atau IDE.
