# 📖 User Manual — Firdan Farma (Sistem Manajemen Apotek)

> Panduan singkat penggunaan fitur utama aplikasi Firdan Farma Windows.

---

## 1. Masuk ke Aplikasi

Saat pertama kali membuka aplikasi, Anda akan diminta memasukkan **PIN**.

- PIN default saat instalasi baru dapat diatur melalui menu pengaturan.
- Jika lupa PIN, hubungi administrator sistem.

---

## 2. Dashboard

Halaman utama menampilkan ringkasan:
- **Total obat aktif** di katalog
- **Obat stok menipis** (stok ≤ stok minimal)
- **Total transaksi hari ini**
- **Pendapatan hari ini**

---

## 3. Katalog Obat

### Menambah Obat Baru
1. Buka menu **Obat** di sidebar kiri.
2. Klik tombol **+ Tambah Obat**.
3. Isi semua field yang diperlukan (Nama, Kode, Harga, Stok, dll.).
4. Klik **Simpan**.

### Mengedit / Menghapus Obat
- Klik ikon ✏️ pada baris obat untuk mengedit.
- Klik ikon 🗑️ untuk menghapus (obat yang pernah bertransaksi hanya dinonaktifkan, tidak dihapus permanen).

### Filter & Pencarian
- Ketik nama/kode obat di kolom **Cari Obat**.
- Gunakan dropdown **Kategori** untuk memfilter per kategori.

---

## 4. Transaksi Penjualan

1. Buka menu **Transaksi** di sidebar.
2. Ketik nama obat di kolom pencarian untuk menambahkan ke keranjang.
3. Atur **jumlah** yang dijual.
4. Klik **Proses Transaksi**.
5. Masukkan jumlah uang yang dibayar pelanggan → sistem otomatis menghitung kembalian.
6. Klik **Konfirmasi & Bayar** → struk transaksi muncul.

---

## 5. Manajemen Stok

1. Buka menu **Stok** di sidebar.
2. Pilih obat dari daftar.
3. Isi jumlah **penambahan stok** (stok masuk dari supplier).
4. Klik **Tambah Stok** → riwayat mutasi stok tercatat otomatis.

---

## 6. Ekspor & Impor Data Obat Excel

Buka menu **Backup & Sinkronisasi** di sidebar.

### 📤 Ekspor Katalog Obat ke Excel
1. Lihat info jumlah obat yang akan diekspor.
2. Klik **"Ekspor ke Excel (Pilih Lokasi Simpan)"**.
3. Pilih folder dan nama file di dialog yang muncul.
4. Klik **Simpan** → file `.xlsx` berhasil dibuat.

> File Excel berisi kolom: ID, Kode Obat, Nama Obat, Kategori, Supplier, Harga Beli, Harga Jual, Stok Tersedia, Stok Minimal, Deskripsi.

---

### 📥 Impor Data Obat dari Excel

> **Penting:** Sistem membaca **seluruh baris** di file Excel dan memasukkannya ke katalog obat secara otomatis.

**Langkah-langkah:**

1. Klik **"Klik untuk memilih file .xlsx"** (atau area kotak dengan ikon folder).
2. Browser file akan terbuka → pilih file Excel obat Anda dari komputer.
3. Nama file yang dipilih akan tampil di kotak konfirmasi.
4. Klik **"Mulai Import Data Obat"**.
5. Tunggu proses selesai (progress bar biru akan muncul).
6. Dialog hasil muncul, menampilkan:
   - ✅ Jumlah obat **baru ditambahkan**
   - 🔄 Jumlah obat **diperbarui** (kode sudah ada, data diupdate)
   - ⚠️ Jumlah baris **dilewati** (kosong atau error)
7. Klik **"Lihat Katalog Obat"** untuk verifikasi data langsung.

**Format Excel yang didukung:**

| Kolom | Keterangan |
|-------|------------|
| Kode Obat | Unik per obat. Jika kosong, digenerate otomatis |
| Nama Obat | **Wajib diisi** |
| Harga Beli | Angka (titik atau koma sebagai pemisah desimal) |
| Harga Jual | Angka |
| Stok Tersedia | Bilangan bulat |
| Stok Minimal | Bilangan bulat (default: 5 jika kosong) |
| Deskripsi | Opsional |

> Baris pertama dianggap **header** dan dilewati otomatis.
> Sistem mendeteksi nama kolom secara fleksibel (tidak bergantung posisi).

---

### 📋 Download Template Excel
Jika Anda belum punya file Excel, klik **"Download Template Excel"** untuk mendapatkan file contoh dengan format yang benar.

---

## 7. Backup & Restore Database

### Ekspor Backup
1. Di bagian **Backup Database Lokal (.db)**, klik **"Ekspor Backup (.db)"**.
2. Pilih lokasi penyimpanan.
3. File `.db` tersimpan — simpan di tempat aman.

### Restore Database
1. Klik **"Restore Database"**.
2. Pilih file `.db` backup.
3. Konfirmasi — **PERINGATAN:** semua data yang ada akan ditimpa!
4. Aplikasi memuat ulang data secara otomatis.

---

## 8. Laporan

Buka menu **Laporan** untuk melihat:
- Laporan penjualan harian / bulanan
- Grafik pendapatan
- Obat terlaris

---

## 9. Tips & Catatan Penting

| ⚠️ Penting | Keterangan |
|------------|------------|
| Backup rutin | Lakukan backup database minimal seminggu sekali |
| Template Excel | Gunakan template resmi agar import tidak error |
| Stok minimal | Atur stok minimal sesuai kebutuhan agar notifikasi stok menipis akurat |
| Kode obat | Kode obat bersifat unik — tidak boleh sama antar obat yang berbeda |

---

*Firdan Farma v1.0 — Sistem Manajemen Apotek Windows*
