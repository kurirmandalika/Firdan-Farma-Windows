# Product Requirements Document

Project: Apotek Firdan Farma  
Platform: Flutter Windows Desktop  
Versi dokumen: 2.0  
Tanggal: 13 Agustus 2026

## 1. Ringkasan

Apotek Firdan Farma adalah aplikasi kasir dan manajemen apotek offline untuk
Windows. Aplikasi membantu karyawan mengelola obat, pembelian, stok, penjualan,
laporan, backup, dan kontrol akses PIN dalam satu database lokal.

## 2. Prinsip Produk

- Manual-first: pengguna dapat memulai dari katalog kosong dan membuat obat
  langsung melalui UI.
- SQLite-first: `firdan_farma.db` adalah satu-satunya sumber data operasional.
- Persistent: data tidak direset saat aplikasi ditutup, dibuka, atau tanggal
  berganti.
- Auditable: setiap perubahan stok memiliki riwayat, saldo sebelum/sesudah,
  waktu, dan alasan.
- Excel optional: Excel hanya digunakan untuk impor atau ekspor eksplisit.
- Historical integrity: transaksi menyimpan snapshot nama, kode, harga jual,
  harga modal, subtotal modal, dan laba.

## 3. Pengguna

- Kasir: mencari obat, membuat penjualan, menerima pembayaran, dan mencetak
  struk.
- Petugas stok: membuat obat, mencatat pembelian, restok, dan stok keluar.
- Pemilik/admin: memantau dashboard dan laporan, melakukan backup/restore, dan
  memakai reset data operasional bila benar-benar diperlukan.

## 4. Sumber Data

Seluruh halaman operasional membaca SQLite:

- Dashboard membaca master obat, transaksi, pembelian, dan stok.
- Obat membaca tabel `obat`.
- Kasir membaca obat aktif lalu menulis transaksi dan ledger stok.
- Pembelian menulis header/detail pembelian dan ledger stok.
- Stok membaca serta menulis ledger stok.
- Laporan menghitung ulang data dari transaksi, pembelian, dan ledger.

SharedPreferences hanya menyimpan preferensi ringan seperti tema dan keamanan
PIN. Master obat, stok, pembelian, transaksi, dan laporan tidak disimpan di
SharedPreferences.

## 5. Database Baru

Database baru harus memiliki:

- 0 obat.
- 0 supplier.
- 0 stok.
- 0 transaksi.
- 0 pembelian.
- Kategori bawaan yang membantu pengisian obat pertama.

Tidak ada produk, supplier, transaksi, atau stok demo yang dibuat otomatis.

## 6. Master Obat

Form obat menyediakan:

- Nama obat.
- Kode obat opsional dengan auto-generation.
- Satuan.
- Harga beli.
- Harga jual.
- Stok awal, hanya ketika create.
- Stok minimal.
- Kategori.
- Supplier opsional.
- Deskripsi opsional.

Create obat dilakukan dalam transaksi SQLite. Bila stok awal lebih dari nol,
sistem membuat ledger `SALDO_AWAL` dan menyimpan `stok_tersedia` dengan nilai
yang sama.

Edit master tidak boleh mengubah stok. Obat yang memiliki histori dinonaktifkan
secara aman, bukan dihapus bersama historinya.

## 7. Pembelian dan Stok Masuk

Pembelian mencatat tanggal, supplier opsional, nomor faktur, detail item,
jumlah, harga beli, subtotal, diskon, total, dan catatan.

Saat pembelian disimpan, sistem secara atomik:

1. Menyimpan header dan detail pembelian.
2. Menambah stok obat.
3. Memperbarui harga beli saat ini.
4. Membuat ledger `PEMBELIAN` dengan saldo sebelum dan sesudah.

Restok cepat dapat dicatat dari menu Stok sebagai `STOK_MASUK` dengan harga
beli dan catatan wajib.

## 8. Stok Keluar

Penjualan hanya dibuat melalui Kasir dan memiliki tipe ledger `PENJUALAN`.

Stok keluar non-penjualan wajib memiliki salah satu alasan:

- Penyesuaian.
- Rusak.
- Kedaluwarsa.
- Retur Supplier.
- Lainnya.

Stok keluar non-penjualan tidak boleh menambah omzet atau jumlah terjual.
Seluruh operasi harus menolak saldo stok negatif.

## 9. Kasir

Kasir menyediakan pencarian produk, keranjang, perubahan jumlah, metode
pembayaran Tunai/QRIS/Transfer/Lainnya, perhitungan kembalian, dan struk.

Checkout dilakukan dalam satu transaksi SQLite:

1. Validasi obat aktif dan stok tersedia.
2. Simpan transaksi.
3. Simpan snapshot detail transaksi.
4. Kurangi stok.
5. Buat ledger `PENJUALAN`.
6. Commit lalu refresh provider.

## 10. Laporan

Laporan default menggunakan periode Hari Ini. Filter yang tersedia:

- Hari Ini.
- Kemarin.
- 7 Hari.
- Bulan Ini.
- Custom date range.

Ringkasan menampilkan penjualan, pembelian, laba kotor, jumlah transaksi, dan
nilai stok.

Per obat, sistem menghitung:

- `AWL`: saldo sebelum periode ditambah saldo awal produk yang dibuat di dalam
  periode.
- `MSK`: seluruh stok masuk periode, tidak termasuk `SALDO_AWAL`.
- `KLR`: hanya jumlah ledger `PENJUALAN`.
- `SISA`: saldo seluruh ledger sampai akhir periode.
- Penjualan: subtotal transaksi pada periode.
- Laba kotor: subtotal penjualan dikurangi snapshot modal terjual.
- Nilai stok: SISA dikali harga beli saat ini.

Laporan adalah hasil query dan tidak disimpan sebagai state harian yang harus
direset.

## 11. Excel

Tidak ada konsep file Excel terhubung. Startup tidak mencari, membuka, atau
mengimpor file Excel.

Impor berjalan hanya setelah pengguna:

1. Membuka menu Data.
2. Memilih file `.xlsx`.
3. Menekan Impor sekarang.

Hasil impor disimpan ke SQLite. Ekspor katalog dan ekspor laporan membuat file
baru dari data SQLite.

## 12. Backup, Restore, dan Reset

Backup database menghasilkan salinan `.db` atau `.sqlite` pilihan pengguna.
Restore memvalidasi schema dan membuat backup otomatis sebelum mengganti
database aktif.

Reset Data Operasional berada di Area Admin. Reset:

- Tidak pernah berjalan otomatis.
- Memerlukan input konfirmasi `RESET DATA`.
- Membuat backup otomatis terlebih dahulu.
- Menghapus obat, stok, transaksi, dan pembelian dalam satu transaksi.
- Mempertahankan kategori dan supplier.

## 13. Persistence dan Migrasi

Database disimpan di Documents pengguna, bukan temporary directory. Migrasi
schema membuat backup otomatis sebelum perubahan versi utama. Database existing
tidak dihapus atau dikosongkan oleh migrasi.

## 14. Acceptance Criteria

- Aplikasi berjalan penuh tanpa file Excel.
- Database baru menampilkan empty state dan tombol Tambah Obat.
- Create/edit obat bertahan setelah restart.
- Stok awal, stok masuk, stok keluar, pembelian, dan penjualan bertahan setelah
  restart.
- Pergantian tanggal tidak mengubah stok.
- Penjualan memblokir stok negatif.
- Stok keluar non-penjualan tidak dihitung sebagai penjualan.
- AWL, MSK, KLR, dan SISA dihitung otomatis dari ledger.
- Dashboard, kasir, stok, dan laporan hanya membaca SQLite.
- Reset memerlukan konfirmasi dan backup otomatis.
- `flutter analyze` dan seluruh automated test lulus.
