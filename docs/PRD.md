# PRD Aplikasi Apotek Firdan Farma

Versi: 4.0
Tanggal: 17 Agustus 2026
Platform: Windows Desktop
Status: Implementasi inti selesai; faktur cetak dan sinkronisasi masih menjadi pengembangan lanjutan

## 1. Ringkasan

Aplikasi Apotek Firdan Farma adalah aplikasi desktop Windows untuk mengelola operasional apotek secara offline. Fokus utama aplikasi adalah pencatatan data obat, stok, transaksi penjualan, pembelian dari supplier, laporan, audit pengguna, serta impor dan ekspor data berbasis Excel.

Sumber data utama aplikasi adalah database SQLite lokal. Format stok obat mengikuti acuan Excel apotek:

- AWL: stok awal masuk
- MSK: pemasukan setiap pembelian dari supplier
- KLR: penjualan keluar
- SISA: stok tersedia saat ini

Aturan utama stok:

```text
SISA = AWL + MSK - KLR
```

Aplikasi harus memastikan CRUD data obat berjalan penuh, data stok konsisten dengan rumus tersebut, dan riwayat transaksi tetap dapat diaudit.

## 2. Tujuan Produk

Tujuan aplikasi:

- Memudahkan pengelolaan stok obat apotek secara lokal dan offline.
- Menyamakan struktur database aplikasi dengan format Excel operasional apotek.
- Menyediakan CRUD obat yang lengkap: tambah, lihat, ubah, hapus, dan aktifkan kembali.
- Menyediakan transaksi penjualan dan pembelian yang otomatis memperbarui stok.
- Menyediakan laporan stok, penjualan, pembelian, laba, dan obat menipis.
- Menyediakan proses impor dan ekspor Excel yang aman, jelas, dan tidak merusak data lama.
- Menjaga data tetap bisa dibackup dan dipulihkan.

## 3. Pengguna Sasaran

Pengguna utama:

- Pemilik apotek
- Kasir
- Admin stok
- Petugas pembelian

Kebutuhan pengguna:

- Input obat cepat dan mudah.
- Cari obat berdasarkan nama, kode, kategori, supplier, atau satuan.
- Melakukan transaksi penjualan tanpa stok minus.
- Mencatat pembelian dari supplier.
- Melihat stok aktual dalam format yang familiar seperti Excel.
- Mencetak atau mengekspor laporan untuk arsip.

## 4. Prinsip Produk

Prinsip utama:

- Offline-first: aplikasi harus tetap berjalan tanpa internet.
- Excel-friendly: format database dan ekspor impor harus dekat dengan file Excel apotek.
- Data aman: perubahan stok penting harus tercatat di riwayat.
- CRUD jelas: data obat bisa dibuat, dibaca, diubah, dihapus, dan diaktifkan kembali sesuai aturan.
- Validasi ketat: stok tidak boleh menjadi negatif.
- Sederhana untuk kasir: transaksi harian harus cepat.
- Terukur untuk admin: laporan harus mudah dibaca dan diekspor.
- Bisa diaudit: aksi operasional penting menyimpan pengguna, waktu, alasan, nominal, dan metode pembayaran.

## 5. Ruang Lingkup MVP

Modul yang termasuk dalam versi utama:

- Dashboard
- Manajemen obat
- Transaksi penjualan
- Pembelian dari supplier
- Mutasi stok manual
- Master kategori
- Master supplier
- Laporan
- Impor dan ekspor Excel
- Backup dan restore database
- Proteksi PIN untuk akses tertentu

Di luar ruang lingkup awal:

- Multi cabang
- Multi terminal real-time
- Sinkronisasi cloud
- Barcode scanner khusus
- Cetak faktur pembelian lanjutan

## 6. Struktur Data Utama

### 6.1 Obat

Entitas obat adalah pusat aplikasi. Field utama:

- Kode obat
- Nama barang
- Satuan
- AWL
- MSK
- KLR
- SISA atau stok tersedia
- Harga beli
- Harga jual
- Stok minimal
- Kategori
- Supplier
- Status aktif
- Tanggal dibuat dan diperbarui

Aturan:

- `SISA = AWL + MSK - KLR`
- `SISA` tidak boleh negatif.
- Nama barang wajib diisi.
- Harga jual tidak boleh negatif.
- Harga beli tidak boleh negatif.
- Obat yang memiliki histori transaksi sebaiknya dihapus secara soft delete.

### 6.2 Stok

Entitas stok digunakan sebagai riwayat audit perubahan stok.

Jenis mutasi:

- Stok awal
- Masuk
- Keluar
- Penyesuaian
- Retur atau koreksi bila diperlukan

Setiap perubahan stok harus menyimpan:

- Obat terkait
- Jenis mutasi
- Jumlah
- Stok sebelum
- Stok sesudah
- Keterangan
- Referensi transaksi bila ada
- Waktu pencatatan
- Kode transaksi/laporan, misalnya `T1` untuk tunai dan `Q1` untuk QRIS.
- Nomor batch dan tanggal kedaluwarsa bila mutasi berasal dari lot tertentu.
- Pengguna yang melakukan perubahan.

Kartu stok harus dapat menampilkan jumlah masuk, jumlah keluar, selisih, saldo sebelum/sesudah,
tanggal, kode transaksi, batch, expired date, dan pengguna.

### 6.3 Transaksi Penjualan

Transaksi penjualan mencatat:

- Nomor transaksi
- Tanggal
- Daftar obat
- Jumlah
- Harga jual saat transaksi
- Subtotal
- Diskon bila ada
- Total
- Metode pembayaran

Dampak ke stok:

- Menambah `KLR`
- Mengurangi `SISA`
- Membuat riwayat mutasi stok keluar
- Menolak transaksi bila stok tidak cukup

### 6.4 Pembelian

Pembelian mencatat:

- Nomor pembelian
- Supplier
- Tanggal
- Daftar obat
- Jumlah
- Harga beli
- Total
- Status pembelian
- Nomor batch per obat dari supplier.
- Tanggal kedaluwarsa per batch.

Dampak ke stok:

- Menambah `MSK`
- Menambah `SISA`
- Membuat riwayat mutasi stok masuk
- Dapat memperbarui harga beli obat

### 6.5 Periode laporan penjualan

Jam tutup laporan apotek adalah pukul 15.00 waktu lokal.

- Transaksi sebelum pukul 15.00 masuk laporan tanggal kalender tersebut.
- Transaksi mulai pukul 15.00 masuk laporan tanggal kalender berikutnya.
- Penjualan tunai dan QRIS diringkas terpisah.
- Kode laporan dibuat berurutan per tanggal laporan dan metode: `T1`, `T2`, `Q1`, `Q2`.
- Metode transfer dan lainnya memakai prefix terpisah agar tidak bercampur dengan tunai/QRIS.

### 6.6 Pengguna dan audit aktivitas

Role aplikasi:

- `KARYAWAN`: kasir dan operasional; melihat ringkasan aktivitas inti.
- `SUPER_ADMIN`: memantau detail seluruh aksi, mengelola akun, dan memeriksa kejanggalan.

Setiap penjualan, pembelian, mutasi stok, login, logout, dan perubahan pengguna membuat audit log.
Audit detail menyimpan aksi, entitas, user, timestamp, alasan, nominal, metode pembayaran, kode transaksi,
dan catatan tambahan.

## 7. Format Excel Resmi

Format impor dan ekspor data obat mengikuti kolom berikut:

```text
No | Nama Barang | SATUAN | AWL | MSK | KLR | SISA | HargaBeli | HargaJual
```

Aturan impor:

- File `.xlsx` menjadi acuan utama.
- Aplikasi harus mendukung header dua baris seperti file sumber.
- Baris ringkasan seperti `GRAND TOTAL`, `SISA STOK`, `PEMBELIAN`, `PENJUALAN`, dan `LABA` harus dilewati.
- Cell formula tidak boleh diperlakukan sebagai kode atau nama obat.
- Jika `SISA` tersedia, nilainya harus cocok dengan `AWL + MSK - KLR` atau dinormalisasi sesuai aturan aplikasi.
- Satuan dari Excel harus masuk ke field `satuan`.
- Data yang sudah ada diperbarui berdasarkan nama atau kode sesuai strategi impor.
- Impor tidak boleh berjalan otomatis saat aplikasi dibuka.
- Sebelum impor besar, aplikasi harus menyediakan atau menyarankan backup.

Aturan ekspor:

- Ekspor obat harus memakai format kolom resmi.
- Nilai stok yang diekspor harus mencerminkan database terbaru.
- Ekspor laporan boleh menambahkan kolom analitik sesuai kebutuhan laporan.

## 8. Kebutuhan Fungsional

### 8.1 Dashboard

Dashboard harus menampilkan:

- Total obat aktif
- Total stok tersedia
- Obat stok menipis
- Penjualan hari ini
- Pembelian terbaru
- Ringkasan aktivitas terbaru

### 8.2 Manajemen Obat

Fitur wajib:

- Tambah obat baru
- Lihat daftar obat
- Cari dan filter obat
- Ubah data obat
- Hapus obat
- Aktifkan kembali obat nonaktif
- Validasi stok dan harga
- Tampilkan kolom AWL, MSK, KLR, dan SISA

Form obat:

- `Nama Barang` wajib diisi.
- `Satuan` dapat dipilih atau diketik.
- `AWL`, `MSK`, dan `KLR` dapat diisi admin.
- `SISA` dihitung otomatis dan tidak diedit manual.
- Harga beli dan harga jual wajib valid.

### 8.3 Transaksi Penjualan

Fitur wajib:

- Tambah item ke keranjang
- Ubah jumlah item
- Hapus item dari keranjang
- Hitung subtotal dan total
- Simpan transaksi
- Kurangi stok otomatis
- Tolak penjualan jika stok tidak cukup
- Cetak atau simpan bukti transaksi bila tersedia

### 8.4 Pembelian

Fitur wajib:

- Buat pembelian dari supplier
- Tambah daftar obat yang dibeli
- Simpan jumlah dan harga beli
- Tambah stok otomatis setelah pembelian selesai
- Catat mutasi stok masuk

### 8.5 Mutasi Stok

Fitur wajib:

- Tambah stok manual
- Kurangi stok manual
- Penyesuaian stok
- Catat alasan perubahan
- Update AWL, MSK, KLR, dan SISA sesuai jenis mutasi

### 8.6 Laporan

Laporan wajib:

- Laporan stok obat
- Laporan penjualan
- Laporan pembelian
- Laporan laba
- Laporan obat stok rendah
- Laporan periode tertentu
- Laporan penjualan terpisah per metode pembayaran.
- Laporan aktivitas ringkas untuk karyawan dan detail untuk Super Admin.
- Kartu stok dengan batch dan expired date.
- Pengingat batch yang mendekati kedaluwarsa.

Aturan laporan stok:

- AWL, MSK, KLR, dan SISA diambil dari snapshot obat terbaru.
- Omzet, pembelian, dan laba dihitung dari transaksi dan pembelian.
- Filter tanggal mempengaruhi transaksi keuangan, bukan mengubah snapshot stok utama.

### 8.7 Backup dan Restore

Fitur wajib:

- Backup database manual
- Restore database dari file backup
- Backup sebelum impor besar
- Informasi lokasi file database aktif

### 8.8 Diskon Penjualan

Sebelum struk dicetak, kasir wajib memilih apakah transaksi diberi diskon.

- Jika tidak, transaksi disimpan dengan diskon `0` dan langsung dapat dicetak.
- Jika iya, kasir memasukkan nominal diskon.
- Nominal diskon tidak boleh melebihi subtotal.
- Total bersih, diskon, user, dan waktu masuk ke laporan serta audit log.

### 8.9 Pengguna

- Login memakai username dan password lokal.
- Akun awal: `admin1` sebagai Super Admin dan `karyawan` sebagai Karyawan.
- Super Admin dapat mengubah username, nama tampilan, role, password, dan status aktif.

## 9. Kebutuhan Non-Fungsional

### 9.1 Platform

- Aplikasi berjalan di Windows Desktop.
- Database memakai SQLite lokal.
- Aplikasi tidak membutuhkan koneksi internet untuk operasional utama.

### 9.2 Performa

- Daftar obat sekitar 700 item harus dapat dibuka dan dicari dengan cepat.
- Transaksi kasir harus responsif.
- Impor Excel harus memberikan hasil yang jelas: jumlah berhasil, gagal, dan dilewati.

### 9.3 Keamanan Data

- Database harus tersimpan lokal.
- Fitur sensitif dapat dilindungi PIN.
- Password tidak disimpan dalam bentuk plaintext.
- Backup harus mudah dibuat sebelum operasi berisiko.
- Hapus data penting harus memakai konfirmasi.

### 9.4 Kualitas

- Perubahan database harus memakai migration versioning.
- CRUD obat harus tercakup test.
- Impor Excel harus tercakup test.
- `flutter analyze` harus bersih dari issue sebelum rilis.
- `flutter test` harus lulus sebelum rilis.

## 10. Kriteria Penerimaan

Data obat:

- Admin dapat menambah obat dengan AWL, MSK, KLR, harga beli, harga jual, dan satuan.
- SISA otomatis dihitung dari AWL + MSK - KLR.
- Aplikasi menolak penyimpanan jika SISA negatif.
- Admin dapat mengubah obat dan hasilnya tersimpan di database.
- Admin dapat menghapus obat.
- Obat dengan histori tetap aman melalui soft delete.

Impor Excel:

- File Excel apotek dapat diimpor tanpa memasukkan baris ringkasan sebagai obat.
- Kolom `SATUAN` masuk ke field satuan.
- Kolom `SISA` menjadi stok tersedia.
- Tidak ada formula Excel yang masuk sebagai kode obat.
- Jumlah obat aktif setelah impor sesuai data valid.

Transaksi:

- Penjualan mengurangi SISA dan menambah KLR.
- Penjualan ditolak jika jumlah melebihi stok.
- Pembelian menambah SISA dan menambah MSK.
- Setiap perubahan stok tercatat di riwayat stok.

Laporan:

- Laporan stok menampilkan AWL, MSK, KLR, dan SISA.
- Laporan penjualan menampilkan total omzet dan laba.
- Laporan pembelian menampilkan total pembelian.
- Laporan bisa difilter berdasarkan periode.

Periode laporan dan pembayaran:

- Penjualan pukul 14.59 masuk tanggal laporan hari berjalan.
- Penjualan pukul 15.00 masuk tanggal laporan hari berikutnya.
- Penjualan tunai pertama pada tanggal laporan mendapat kode `T1`.
- Penjualan QRIS pertama pada tanggal laporan mendapat kode `Q1`.
- Diskon tercatat dan total laporan memakai total setelah diskon.

Batch dan audit:

- Pembelian dapat menyimpan nomor batch dan expired date tiap obat.
- Penjualan mengurangi batch dengan expired date terdekat terlebih dahulu.
- Kartu stok menampilkan kode T/Q, batch, expired, jumlah masuk/keluar, dan saldo.
- Super Admin dapat melihat audit detail per aksi dan user.

Backup:

- User dapat membuat backup database.
- User dapat restore database dari backup valid.
- Backup tersedia sebelum impor besar atau migrasi besar.

## 11. Risiko dan Mitigasi

Risiko:

- Format Excel berubah.
- Data Excel berisi formula atau baris ringkasan.
- Stok menjadi tidak sinkron antara snapshot obat dan riwayat stok.
- User menghapus obat yang sudah pernah dipakai transaksi.

Mitigasi:

- Importer harus fleksibel terhadap header dua baris.
- Importer harus melewati baris ringkasan.
- Database memakai invariant `SISA = AWL + MSK - KLR`.
- Riwayat stok tetap disimpan untuk audit.
- Hapus obat historis memakai soft delete.
- Backup dibuat sebelum impor atau migrasi besar.

## 12. Roadmap Lanjutan

Prioritas berikutnya:

- Barcode scanner
- Cetak faktur pembelian
- Sinkronisasi cloud opsional
- Dashboard analitik penjualan bulanan
- Import mapping kolom manual bila format Excel berubah

## 13. Definisi Selesai

Sebuah fitur dianggap selesai bila:

- Fitur berjalan dari UI sampai database.
- Validasi input tersedia.
- Error utama ditangani dengan pesan yang jelas.
- Data tersimpan dan dapat dibaca ulang.
- Tidak merusak data lama.
- Test relevan lulus.
- `flutter analyze` tidak menemukan issue.
