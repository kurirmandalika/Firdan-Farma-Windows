# Panduan Pengguna Apotek Firdan Farma

Apotek Firdan Farma menggunakan SQLite lokal sebagai sumber data utama. File
Excel tidak diperlukan untuk menjalankan dashboard, kasir, stok, pembelian,
atau laporan.

## 1. Memulai Aplikasi

1. Buka aplikasi dan tunggu status sistem siap.
2. Klik layar pembuka untuk masuk.
3. Masukkan atau buat PIN jika diminta.
4. Pada database baru, dashboard dan katalog obat akan kosong.

Data tidak direset ketika aplikasi ditutup, dibuka kembali, atau ketika tanggal
berganti.

## 2. Menambah Obat Pertama

1. Buka menu **Obat**.
2. Klik **Tambah Obat**.
3. Isi Nama Obat, Satuan, Harga Beli, Harga Jual, Stok Awal, Stok Minimal,
   dan Kategori.
4. Kode obat boleh dikosongkan agar dibuat otomatis.
5. Supplier dan Deskripsi bersifat opsional.
6. Klik **Simpan Data Obat**.

Obat disimpan ke SQLite. Jika stok awal lebih dari nol, aplikasi juga membuat
riwayat `SALDO_AWAL` secara otomatis.

## 3. Mengedit Obat

Gunakan ikon edit pada daftar obat untuk mengubah nama, kode, satuan, kategori,
supplier, harga beli, harga jual, stok minimal, atau deskripsi. Stok sekarang
tidak dapat diedit dari form ini.

Gunakan aksi nonaktifkan untuk menyembunyikan obat lama tanpa merusak riwayat
transaksi. Obat nonaktif dapat diaktifkan kembali.

## 4. Pembelian dan Stok Masuk

Untuk pembelian resmi dari supplier:

1. Buka menu **Pembelian**.
2. Isi tanggal, supplier, nomor faktur, dan item.
3. Atur jumlah serta harga beli.
4. Simpan pembelian.

Stok dan harga beli saat ini diperbarui dalam satu transaksi database.

Untuk restok cepat:

1. Buka menu **Stok** dan pilih **Stok Masuk**.
2. Pilih obat, isi jumlah, harga beli, dan catatan.
3. Klik **Simpan Stok Masuk**.

## 5. Stok Keluar Non-Penjualan

Stok rusak, kedaluwarsa, retur supplier, atau koreksi dicatat dari menu
**Stok > Stok Keluar**. Pilih alasan yang sesuai dan isi catatan. Perubahan ini
tidak dihitung sebagai penjualan.

Penjualan hanya dicatat melalui menu Kasir.

## 6. Kasir

1. Buka menu **Kasir**.
2. Cari dan tambahkan obat ke keranjang.
3. Atur jumlah item.
4. Pilih metode pembayaran: Tunai, QRIS, Transfer, atau Lainnya.
5. Untuk tunai, isi nominal pembayaran.
6. Selesaikan transaksi.

Aplikasi memvalidasi stok, menyimpan transaksi dan detail harga, mengurangi
stok, serta membuat riwayat `PENJUALAN` secara atomik.

## 7. Laporan Otomatis

Menu **Laporan** dibuka pada filter Hari Ini. Filter lain yang tersedia adalah
Kemarin, 7 Hari, Bulan Ini, dan rentang custom.

Kolom laporan obat:

- `AWL`: stok pembukaan periode.
- `MSK`: stok masuk selama periode, tidak termasuk saldo awal.
- `KLR`: jumlah yang terjual melalui Kasir.
- `SISA`: saldo stok sampai akhir periode.
- `HB` dan `HJ`: harga beli dan jual saat ini.
- Penjualan, Pembelian, Laba Kotor, dan Nilai Stok.

Klik **Ekspor Excel** untuk membuat file laporan dari data SQLite pada periode
yang sedang dipilih.

## 8. Impor dan Ekspor Excel

Excel adalah fitur sekunder dan hanya diproses atas tindakan pengguna.

Untuk impor:

1. Buka menu **Data**.
2. Pilih file `.xlsx`.
3. Tentukan apakah katalog lama perlu diarsipkan.
4. Klik **Impor sekarang**.

Memilih file saja belum mengubah database. Tidak ada file Excel yang dibaca
otomatis saat startup.

Menu Data juga menyediakan ekspor katalog aktif dan template impor.

## 9. Backup dan Restore

- **Backup database** membuat salinan seluruh data ke file `.db` atau
  `.sqlite` pilihan pengguna.
- **Restore database** mengganti database aktif dengan backup yang dipilih.
  Aplikasi membuat salinan pengaman otomatis sebelum restore.

Lakukan backup rutin dan simpan salinannya di media lain.

## 10. Reset Data Operasional

Fitur ini berada di **Data > Area Admin** dan ditujukan untuk pengembangan atau
memulai instalasi baru.

1. Buka Area Admin.
2. Klik **Reset Data Operasional**.
3. Baca dampaknya dan ketik `RESET DATA`.
4. Klik **Backup dan Reset**.

Sebelum menghapus obat, stok, transaksi, dan pembelian, aplikasi membuat backup
otomatis di folder database. Kategori dan supplier dipertahankan. Reset tidak
pernah dijalankan otomatis.
