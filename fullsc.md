# Product Requirements Document (PRD)

Project: Apotek Firdan Farma
Versi: 1.1
Tanggal: 2026-08-07
Penulis: Tim Produk

## 1. Ringkasan Eksekutif

Aplikasi "Apotek Firdan Farma" adalah solusi manajemen apotek berbasis Flutter yang dirancang untuk apotek kecil dan menengah.
Aplikasi ini mengelola data obat, stok, transaksi kasir, keamanan akses PIN, backup database, dan integrasi spreadsheet lokal.
Fokus MVP adalah operasi harian yang berjalan offline dengan sinkronisasi spreadsheet sebagai opsi ekspor/import.

## 2. Tujuan dan Sasaran

- Menyediakan manajemen data obat dan stok yang mudah dioperasikan.
- Memfasilitasi proses transaksi kasir sederhana.
- Menjamin keamanan akses dengan PIN dan menjaga data melalui backup lokal.
- Menawarkan export/import spreadsheet untuk dukungan laporan dan migrasi data.
- Menyediakan dasar laporan penjualan dan stok untuk monitoring bisnis.

## 3. Ruang Lingkup

Fitur yang disertakan pada fase awal (MVP):

- Dashboard ringkasan transaksi dan status spreadsheet.
- Daftar obat: lihat, tambah, edit, hapus.
- Pengelolaan stok: stok masuk dan stok keluar.
- Transaksi penjualan: pemilihan obat, keranjang, pembayaran, simpan transaksi.
- PIN awal dan verifikasi saat aplikasi dibuka.
- Backup database lokal dan sharing file backup.
- Integrasi spreadsheet: koneksi file spreadsheet, eksport data obat, impor/pembaruan data obat.
- Data master: kategori obat dan supplier tersedia di model dan layanan.

Fitur di luar ruang lingkup MVP:

- Integrasi pembayaran gateway online.
- Sinkronisasi cloud multi-user.
- Print struk langsung dari aplikasi.
- Pembukuan akuntansi lengkap.
- Modul supplier purchase order full workflow (hanya model/layanan dasar tersedia).

## 4. Target Pengguna

- Pemilik apotek kecil sampai menengah.
- Kasir yang melakukan transaksi penjualan harian.
- Pengelola stok yang mengatur mutasi barang.
- Pemilik atau manajer yang memerlukan backup dan laporan singkat.

## 5. Asumsi & Batasan

- Aplikasi berjalan pada Android dan Web menggunakan satu codebase Flutter.
- Data utama disimpan secara lokal di SQLite (`database_helper.dart`).
- Internet tidak diperlukan untuk fungsi inti. Fitur spreadsheet memerlukan akses file lokal.
- Aplikasi harus mudah digunakan tanpa pelatihan teknis mendalam.
- UI saat ini berbasis layar modular dan state management provider.

## 6. Istilah Glossary

- Obat: produk farmasi yang dikelola dan dijual.
- Kategori Obat: pengelompokkan obat berdasarkan jenis.
- Supplier: pemasok obat (tersedia di model dan layanan).
- Stok: perubahan jumlah obat, baik masuk maupun keluar.
- Transaksi: penjualan yang disimpan sebagai record kasir.
- DetailTransaksi: item-level pada setiap transaksi.

## 7. Fitur Utama (Rinci)

- Dashboard
  - Menampilkan ringkasan transaksi hari ini.
  - Menampilkan status koneksi spreadsheet.

- Manajemen Obat
  - CRUD data obat: nama, kode obat, kategori, supplier, harga beli, harga jual, stok minimal, stok tersedia, deskripsi.
  - Pencarian data obat pada daftar.

- Pengelolaan Kategori Obat
  - Model dan database untuk kategori obat disediakan.
  - CRUD kategori tersedia di backend layanan.

- Supplier
  - Model dan layanan supplier tersedia untuk menyimpan data pemasok.
  - UI supplier CRUD belum menjadi fokus MVP penuh.

- Stok
  - Update stok masuk dan stok keluar di layar stok.
  - Catatan mutasi stok disimpan bersama jenis dan jumlah.

- Transaksi Penjualan
  - Pilih obat dan jumlah, tambahkan ke keranjang.
  - Hitung total transaksi dan verifikasi pembayaran.
  - Simpan transaksi dengan detail item.
  - Tidak ada fitur retur penuh; pembatalan kompleks dianggap di luar MVP.

- Keamanan PIN
  - Setup PIN pertama kali jika belum diset.
  - Verifikasi PIN saat aplikasi diluncurkan.

- Backup & Restore
  - Export file database `.db` dari storage sementara.
  - Share backup melalui fitur sistem.
  - Import database dari file backup.

- Spreadsheet
  - Koneksi file spreadsheet lokal.
  - Export data obat ke spreadsheet `.xlsx`.
  - Import/ sinkronisasi data obat dari spreadsheet.
  - Sinkronisasi otomatis setelah transaksi atau update stok ketika spreadsheet terhubung.

- Laporan & Analytics
  - Laporan service menyediakan ringkasan penjualan harian dan obat terlaris.
  - UI laporan penuh dapat dikembangkan setelah MVP.

## 8. User Stories (Contoh)

- Sebagai kasir, saya ingin menambahkan obat ke keranjang sehingga transaksi dapat diproses dengan cepat.
- Sebagai pengelola stok, saya ingin mencatat stok masuk dan keluar sehingga jumlah barang tetap akurat.
- Sebagai pemilik, saya ingin membuat backup data sehingga database aman jika perangkat rusak.
- Sebagai administrator, saya ingin menghubungkan spreadsheet sehingga data obat dapat diekspor atau diimpor.

## 9. Alur Pengguna (High-level)

1. Buka aplikasi → atur PIN saat pertama kali.
2. Dashboard menampilkan ringkasan transaksi dan status spreadsheet.
3. Masuk ke layar `Obat` untuk mengelola data produk.
4. Masuk ke layar `Stok` untuk mutasi masuk/keluar.
5. Masuk ke layar `Transaksi` untuk memproses penjualan.
6. Gunakan fitur backup dan spreadsheet untuk menyimpan atau memindahkan data.

## 10. Model Data (Entitas Utama)

Berdasarkan skema di `Apotek-Firdan-Farma/lib/database/database_helper.dart`:

- `kategori_obat`
  - id, nama, deskripsi
- `supplier`
  - id, nama, kontak, alamat
- `obat`
  - id, nama, kode_obat, kategori_id, supplier_id, harga_beli, harga_jual, stok_minimal, stok_tersedia, deskripsi, created_at
- `stok`
  - id, obat_id, jenis, jumlah, catatan, tanggal
- `transaksi`
  - id, nomor_transaksi, total, bayar, kembali, tanggal, jumlah_item
- `detail_transaksi`
  - id, transaksi_id, obat_id, jumlah, harga_satuan, subtotal

## 11. Arsitektur & Komponen

- Platform: Flutter 3.x, target Android dan Web.
- Persistensi: SQLite melalui `DatabaseHelper`.
- State management: provider (`ObatProvider`).
- Services:
  - `ObatService`, `StokService`, `TransaksiService`, `BackupService`, `SpreadsheetService`, `LaporanService`, `PinService`, `SupplierService`.
- UI:
  - `DashboardScreen`, `ObatListScreen`, `StokScreen`, `TransaksiScreen`, `PinScreen`.
- Widget reusable: `PinGate` untuk pengamanan akses.

## 12. Spesifikasi API Internal / Contract Layanan

- `ObatService`:
  - `getAll()`
  - `getById(id)`
  - `insert`, `update`, `delete`
- `StokService`:
  - `updateStok(obatId, jenis, jumlah, catatan)`
- `TransaksiService`:
  - `createTransaksi(nomorTransaksi, total, bayar, items)`
  - `getAll()`
  - `getTodayCount()`
- `BackupService`:
  - `exportDatabase()`
  - `importDatabase(sourcePath)`
  - `shareBackup(path)`
- `SpreadsheetService`:
  - `connectSpreadsheet()`
  - `importSpreadsheetToDb()`
  - `exportDatabaseToSpreadsheet()`
  - `syncDatabaseToSpreadsheet()`
- `LaporanService`:
  - `getLaporanHarian(dari, sampai)`
  - `getObatTerlaris(dari, sampai, limit)`
- `PinService`:
  - `hasPin()`
  - `setPin(pin)`
  - `verifyPin(pin)`

## 13. Non-Functional Requirements

- Keamanan: PIN sepanjang 6 digit; data backup file disimpan secara lokal.
- Ketahanan: operasi transaksi dan stok dapat berjalan tanpa koneksi internet.
- Performa: operasi daftar obat dan transaksi responsif pada perangkat low-end.
- Skalabilitas: dukung hingga ribuan data obat dengan indeks DB.
- Lokal: bahasa utama Bahasa Indonesia.
- Backup: kemampuan ekspor/import lokal untuk proteksi data.

## 14. Acceptance Criteria (Kriteria Penerimaan)

- Obat dapat ditambah, diubah, dan dihapus.
- Stok dapat di-update baik sebagai masuk maupun keluar.
- Transaksi penjualan disimpan beserta detail setiap item.
- Aplikasi meminta dan memverifikasi PIN pada startup.
- Backup dapat dibuat, dibagikan, dan diimpor kembali.
- Spreadsheet dapat dihubungkan, diekspor, dan diimpor untuk data obat.
- Dashboard menampilkan ringkasan transaksi harian.

## 15. Roadmap & Milestones

- Milestone 1 (MVP) — 2 minggu
  - Dashboard, Obat, Stok, Transaksi, PIN, Backup.
- Milestone 2 — 2 minggu
  - Spreadsheet import/export, laporan dasar, supplier management UI.
- Milestone 3 — 2 minggu
  - UX polish, laporan analytics, pengujian dan bugfix.

## 16. Risiko & Mitigasi

- Risiko: kehilangan data bila backup tidak tervalidasi.
  - Mitigasi: gunakan backup file yang dapat dibagikan dan restore local.
- Risiko: kesalahan input stok dan transaksi.
  - Mitigasi: validasi input, pesan error jelas, konfirmasi pengguna.
- Risiko: ketergantungan pada cara impor spreadsheet.
  - Mitigasi: dokumentasi kolom spreadsheet dan fallback manual.

## 17. KPI & Metrics

- Waktu rata-rata untuk menyelesaikan satu transaksi.
- Jumlah transaksi per hari.
- Jumlah backup yang berhasil dibuat.
- Persentase stok minimal yang terpantau.

## 18. Testing & QA

- Unit test pada service DB dan logika transaksi.
- Integrasi test untuk alur lengkap (stok → transaksi → spreadsheet).
- Manual QA pada Android dan Web.

## 19. Dokumentasi & Support

- README harus memuat cara build untuk Android dan Web.
- Dokumentasi backup/restore dan spreadsheet harus tersedia.
- Penjelasan singkat alur aplikasi untuk pengguna baru.

---

Catatan: Dokumen PRD ini diperbarui untuk mencerminkan implementasi saat ini pada repository. Jika Anda ingin menambahkan modul online sync atau fitur POS printer, beri tahu saya agar bisa ditambahkan pada PRD berikutnya.

---

# Source Code

## pubspec.yaml
`yaml
name: firdan_farma_windows
description: "A new Flutter project."
# The following line prevents the package from being accidentally published to
# pub.dev using `flutter pub publish`. This is preferred for private packages.
publish_to: 'none' # Remove this line if you wish to publish to pub.dev

# The following defines the version and build number for your application.
# A version number is three numbers separated by dots, like 1.2.43
# followed by an optional build number separated by a +.
# Both the version and the builder number may be overridden in flutter
# build by specifying --build-name and --build-number, respectively.
# In Android, build-name is used as versionName while build-number used as versionCode.
# Read more about Android versioning at https://developer.android.com/studio/publish/versioning
# In iOS, build-name is used as CFBundleShortVersionString while build-number is used as CFBundleVersion.
# Read more about iOS versioning at
# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
# In Windows, build-name is used as the major, minor, and patch parts
# of the product and file versions while build-number is used as the build suffix.
version: 1.0.0+1

environment:
  sdk: ^3.11.1

# Dependencies specify other packages that your package needs in order to work.
# To automatically upgrade your package dependencies to the latest versions
# consider running `flutter pub upgrade --major-versions`. Alternatively,
# dependencies can be manually updated by changing the version numbers below to
# the latest version available on pub.dev. To see which dependencies have newer
# versions available, run `flutter pub outdated`.
dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8
  provider: ^6.1.2
  sqflite: ^2.3.2
  sqflite_common_ffi: ^2.3.2+1
  path_provider: ^2.1.2
  path: ^1.9.0
  excel: ^4.0.3
  file_picker: ^8.0.0
  intl: ^0.19.0
  fl_chart: ^0.66.2
  google_fonts: ^6.1.0
  flutter_animate: ^4.5.0
  pdf: ^3.10.8
  printing: ^5.11.1
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter

  # The "flutter_lints" package below contains a set of recommended lints to
  # encourage good coding practices. The lint set provided by the package is
  # activated in the `analysis_options.yaml` file located at the root of your
  # package. See that file for information about deactivating specific lint
  # rules and activating additional ones.
  flutter_lints: ^6.0.0

# For information on the generic Dart part of this file, see the
# following page: https://dart.dev/tools/pub/pubspec

# The following section is specific to Flutter packages.
flutter:

  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true

  # To add assets to your application, add an assets section, like this:
  # assets:
  #   - images/a_dot_burr.jpeg
  #   - images/a_dot_ham.jpeg

  # An image asset can refer to one or more resolution-specific "variants", see
  # https://flutter.dev/to/resolution-aware-images

  # For details regarding adding assets from package dependencies, see
  # https://flutter.dev/to/asset-from-package

  # To add custom fonts to your application, add a fonts section here,
  # in this "flutter" section. Each entry in this list should have a
  # "family" key with the font family name, and a "fonts" key with a
  # list giving the asset and other descriptors for the font. For
  # example:
  # fonts:
  #   - family: Schyler
  #     fonts:
  #       - asset: fonts/Schyler-Regular.ttf
  #       - asset: fonts/Schyler-Italic.ttf
  #         style: italic
  #   - family: Trajan Pro
  #     fonts:
  #       - asset: fonts/TrajanPro.ttf
  #       - asset: fonts/TrajanPro_Bold.ttf
  #         weight: 700
  #
  # For details regarding fonts from package dependencies,
  # see https://flutter.dev/to/font-from-package

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/main.dart
`dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'theme/app_theme.dart';
import 'utils/app_constants.dart';
import 'database/database_helper.dart';

import 'providers/app_provider.dart';
import 'providers/obat_provider.dart';
import 'providers/kategori_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/stok_provider.dart';
import 'providers/transaksi_provider.dart';
import 'providers/laporan_provider.dart';
import 'providers/pin_provider.dart';

import 'screens/pin/pin_gate_screen.dart';
import 'screens/main_desktop_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite for Desktop (Windows / Linux / macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize Date Formatting Locale
  await initializeDateFormatting('id_ID', null);

  // Pre-warm database connection
  await DatabaseHelper.instance.database;

  runApp(const FirdanFarmaApp());
}

class FirdanFarmaApp extends StatelessWidget {
  const FirdanFarmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ObatProvider()),
        ChangeNotifierProvider(create: (_) => KategoriProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => StokProvider()),
        ChangeNotifierProvider(create: (_) => TransaksiProvider()),
        ChangeNotifierProvider(create: (_) => LaporanProvider()),
        ChangeNotifierProvider(create: (_) => PinProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const PinGateScreen(
          child: MainDesktopShell(),
        ),
      ),
    );
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/database/database_helper.dart
`dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_constants.dart';

class DatabaseHelper {
  static const dbFileName = AppConstants.databaseFileName;

  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<String> getDbPath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return p.join(documentsDirectory.path, dbFileName);
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final path = await getDbPath();

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
      ),
    );
  }

  /// Menutup koneksi database aktif dan mereset cache.
  Future<void> closeAndReset() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
    _database = null;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE kategori_obat (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        deskripsi TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE supplier (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        kontak TEXT,
        alamat TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE obat (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        kode_obat TEXT NOT NULL UNIQUE,
        kategori_id INTEGER NOT NULL,
        supplier_id INTEGER,
        harga_beli REAL NOT NULL,
        harga_jual REAL NOT NULL,
        stok_minimal INTEGER NOT NULL DEFAULT 5,
        stok_tersedia INTEGER NOT NULL DEFAULT 0,
        deskripsi TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (kategori_id) REFERENCES kategori_obat(id),
        FOREIGN KEY (supplier_id) REFERENCES supplier(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE stok (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        obat_id INTEGER NOT NULL,
        jenis TEXT NOT NULL,
        jumlah INTEGER NOT NULL,
        catatan TEXT,
        tanggal TEXT NOT NULL,
        FOREIGN KEY (obat_id) REFERENCES obat(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nomor_transaksi TEXT NOT NULL UNIQUE,
        total REAL NOT NULL,
        bayar REAL NOT NULL,
        kembali REAL NOT NULL,
        tanggal TEXT NOT NULL,
        jumlah_item INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE detail_transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaksi_id INTEGER NOT NULL,
        obat_id INTEGER NOT NULL,
        jumlah INTEGER NOT NULL,
        harga_satuan REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (transaksi_id) REFERENCES transaksi(id),
        FOREIGN KEY (obat_id) REFERENCES obat(id)
      )
    ''');

    await db.execute('CREATE INDEX idx_obat_kategori ON obat(kategori_id)');
    await db.execute('CREATE INDEX idx_stok_obat ON stok(obat_id)');
    await db.execute('CREATE INDEX idx_detail_transaksi ON detail_transaksi(transaksi_id)');

    await seedInitialData(db);
  }

  Future<void> seedInitialData(Database db) async {
    await db.insert('kategori_obat', {
      'nama': 'Analgesik & Antiinflamasi',
      'deskripsi': 'Pereda nyeri, pusing, dan demam',
    });
    await db.insert('kategori_obat', {
      'nama': 'Antibiotik & Kapsul',
      'deskripsi': 'Pengobatan infeksi bakteri',
    });
    await db.insert('kategori_obat', {
      'nama': 'Vitamin & Suplemen',
      'deskripsi': 'Penunjang imunitas dan daya tahan tubuh',
    });
    await db.insert('kategori_obat', {
      'nama': 'Obat Batuk & Flu',
      'deskripsi': 'Sirup dan tablet pereda gejala flu',
    });

    await db.insert('supplier', {
      'nama': 'PT Sehat Jaya Farmasi',
      'kontak': '0812-3456-7890',
      'alamat': 'Jl. Industri Farmasi No. 12, Bandung',
    });
    await db.insert('supplier', {
      'nama': 'CV Farma Mandiri Utama',
      'kontak': '0823-4567-8901',
      'alamat': 'Kawasan Medis Blok B4, Jakarta',
    });
    await db.insert('supplier', {
      'nama': 'PT Kimia Farma Distribusi',
      'kontak': '0857-9988-7766',
      'alamat': 'Jl. Merdeka No. 45, Surabaya',
    });

    final now = DateTime.now().toIso8601String();

    await db.insert('obat', {
      'nama': 'Paracetamol 500mg',
      'kode_obat': 'PCT-500',
      'kategori_id': 1,
      'supplier_id': 1,
      'harga_beli': 2500,
      'harga_jual': 5000,
      'stok_minimal': 10,
      'stok_tersedia': 45,
      'deskripsi': 'Strip 10 tablet pereda nyeri dan demam',
      'created_at': now,
    });

    await db.insert('obat', {
      'nama': 'Amoxicillin 500mg Kapsul',
      'kode_obat': 'AMX-500',
      'kategori_id': 2,
      'supplier_id': 2,
      'harga_beli': 8000,
      'harga_jual': 12500,
      'stok_minimal': 8,
      'stok_tersedia': 14,
      'deskripsi': 'Antibiotik spektrum luas resep dokter',
      'created_at': now,
    });

    await db.insert('obat', {
      'nama': 'Vitamin C 1000mg Effervescent',
      'kode_obat': 'VIT-1000',
      'kategori_id': 3,
      'supplier_id': 1,
      'harga_beli': 25000,
      'harga_jual': 38000,
      'stok_minimal': 5,
      'stok_tersedia': 3, // Low stock demo
      'deskripsi': 'Tube 10 tablet larut air rasa jeruk',
      'created_at': now,
    });

    await db.insert('obat', {
      'nama': 'OBH Sirup Batuk Plus Flu 100ml',
      'kode_obat': 'OBH-100',
      'kategori_id': 4,
      'supplier_id': 3,
      'harga_beli': 14000,
      'harga_jual': 21000,
      'stok_minimal': 6,
      'stok_tersedia': 22,
      'deskripsi': 'Botol 100ml rasa menthol legakan tenggorokan',
      'created_at': now,
    });

    // Seed Initial Stock Mutasi Log
    await db.insert('stok', {
      'obat_id': 1,
      'jenis': 'masuk',
      'jumlah': 45,
      'catatan': 'Stok awal inventaris apotek',
      'tanggal': now,
    });

    await db.insert('stok', {
      'obat_id': 2,
      'jenis': 'masuk',
      'jumlah': 14,
      'catatan': 'Stok awal inventaris apotek',
      'tanggal': now,
    });

    await db.insert('stok', {
      'obat_id': 3,
      'jenis': 'masuk',
      'jumlah': 3,
      'catatan': 'Stok awal inventaris apotek',
      'tanggal': now,
    });

    await db.insert('stok', {
      'obat_id': 4,
      'jenis': 'masuk',
      'jumlah': 22,
      'catatan': 'Stok awal inventaris apotek',
      'tanggal': now,
    });
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/models/detail_transaksi_model.dart
`dart
class DetailTransaksi {
  final int? id;
  final int? transaksiId;
  final int obatId;
  final int jumlah;
  final double hargaSatuan;
  final double subtotal;

  // Joined display field
  final String? namaObat;
  final String? kodeObat;

  DetailTransaksi({
    this.id,
    this.transaksiId,
    required this.obatId,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
    this.namaObat,
    this.kodeObat,
  });

  factory DetailTransaksi.fromMap(Map<String, dynamic> map) {
    return DetailTransaksi(
      id: map['id'] as int?,
      transaksiId: map['transaksi_id'] as int?,
      obatId: map['obat_id'] as int,
      jumlah: map['jumlah'] as int,
      hargaSatuan: (map['harga_satuan'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
      namaObat: map['nama_obat'] as String?,
      kodeObat: map['kode_obat'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (transaksiId != null) 'transaksi_id': transaksiId,
      'obat_id': obatId,
      'jumlah': jumlah,
      'harga_satuan': hargaSatuan,
      'subtotal': subtotal,
    };
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/models/kategori_model.dart
`dart
class KategoriObat {
  final int? id;
  final String nama;
  final String? deskripsi;

  KategoriObat({
    this.id,
    required this.nama,
    this.deskripsi,
  });

  factory KategoriObat.fromMap(Map<String, dynamic> map) {
    return KategoriObat(
      id: map['id'] as int?,
      nama: map['nama'] as String,
      deskripsi: map['deskripsi'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama': nama,
      'deskripsi': deskripsi,
    };
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/models/obat_model.dart
`dart
class Obat {
  final int? id;
  final String nama;
  final String kodeObat;
  final int kategoriId;
  final int? supplierId;
  final double hargaBeli;
  final double hargaJual;
  final int stokMinimal;
  final int stokTersedia;
  final String? deskripsi;
  final String createdAt;

  // Extra joined fields for display UI
  final String? namaKategori;
  final String? namaSupplier;

  Obat({
    this.id,
    required this.nama,
    required this.kodeObat,
    required this.kategoriId,
    this.supplierId,
    required this.hargaBeli,
    required this.hargaJual,
    this.stokMinimal = 5,
    this.stokTersedia = 0,
    this.deskripsi,
    required this.createdAt,
    this.namaKategori,
    this.namaSupplier,
  });

  bool get isStokMenipis => stokTersedia <= stokMinimal;
  bool get isHabis => stokTersedia <= 0;

  factory Obat.fromMap(Map<String, dynamic> map) {
    return Obat(
      id: map['id'] as int?,
      nama: map['nama'] as String,
      kodeObat: map['kode_obat'] as String,
      kategoriId: map['kategori_id'] as int,
      supplierId: map['supplier_id'] as int?,
      hargaBeli: (map['harga_beli'] as num).toDouble(),
      hargaJual: (map['harga_jual'] as num).toDouble(),
      stokMinimal: map['stok_minimal'] as int? ?? 5,
      stokTersedia: map['stok_tersedia'] as int? ?? 0,
      deskripsi: map['deskripsi'] as String?,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      namaKategori: map['nama_kategori'] as String?,
      namaSupplier: map['nama_supplier'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama': nama,
      'kode_obat': kodeObat,
      'kategori_id': kategoriId,
      'supplier_id': supplierId,
      'harga_beli': hargaBeli,
      'harga_jual': hargaJual,
      'stok_minimal': stokMinimal,
      'stok_tersedia': stokTersedia,
      'deskripsi': deskripsi,
      'created_at': createdAt,
    };
  }

  Obat copyWith({
    int? id,
    String? nama,
    String? kodeObat,
    int? kategoriId,
    int? supplierId,
    double? hargaBeli,
    double? hargaJual,
    int? stokMinimal,
    int? stokTersedia,
    String? deskripsi,
    String? createdAt,
    String? namaKategori,
    String? namaSupplier,
  }) {
    return Obat(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      kodeObat: kodeObat ?? this.kodeObat,
      kategoriId: kategoriId ?? this.kategoriId,
      supplierId: supplierId ?? this.supplierId,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      hargaJual: hargaJual ?? this.hargaJual,
      stokMinimal: stokMinimal ?? this.stokMinimal,
      stokTersedia: stokTersedia ?? this.stokTersedia,
      deskripsi: deskripsi ?? this.deskripsi,
      createdAt: createdAt ?? this.createdAt,
      namaKategori: namaKategori ?? this.namaKategori,
      namaSupplier: namaSupplier ?? this.namaSupplier,
    );
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/models/stok_model.dart
`dart
class StokMutasi {
  final int? id;
  final int obatId;
  final String jenis; // 'masuk' or 'keluar'
  final int jumlah;
  final String? catatan;
  final String tanggal;

  // Joined display field
  final String? namaObat;

  StokMutasi({
    this.id,
    required this.obatId,
    required this.jenis,
    required this.jumlah,
    this.catatan,
    required this.tanggal,
    this.namaObat,
  });

  factory StokMutasi.fromMap(Map<String, dynamic> map) {
    return StokMutasi(
      id: map['id'] as int?,
      obatId: map['obat_id'] as int,
      jenis: map['jenis'] as String,
      jumlah: map['jumlah'] as int,
      catatan: map['catatan'] as String?,
      tanggal: map['tanggal'] as String,
      namaObat: map['nama_obat'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'obat_id': obatId,
      'jenis': jenis,
      'jumlah': jumlah,
      'catatan': catatan,
      'tanggal': tanggal,
    };
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/models/supplier_model.dart
`dart
class Supplier {
  final int? id;
  final String nama;
  final String? kontak;
  final String? alamat;

  Supplier({
    this.id,
    required this.nama,
    this.kontak,
    this.alamat,
  });

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      nama: map['nama'] as String,
      kontak: map['kontak'] as String?,
      alamat: map['alamat'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama': nama,
      'kontak': kontak,
      'alamat': alamat,
    };
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/models/transaksi_model.dart
`dart
import 'detail_transaksi_model.dart';

class Transaksi {
  final int? id;
  final String nomorTransaksi;
  final double total;
  final double bayar;
  final double kembali;
  final String tanggal;
  final int jumlahItem;
  final List<DetailTransaksi> items;

  Transaksi({
    this.id,
    required this.nomorTransaksi,
    required this.total,
    required this.bayar,
    required this.kembali,
    required this.tanggal,
    required this.jumlahItem,
    this.items = const [],
  });

  factory Transaksi.fromMap(Map<String, dynamic> map, {List<DetailTransaksi> items = const []}) {
    return Transaksi(
      id: map['id'] as int?,
      nomorTransaksi: map['nomor_transaksi'] as String,
      total: (map['total'] as num).toDouble(),
      bayar: (map['bayar'] as num).toDouble(),
      kembali: (map['kembali'] as num).toDouble(),
      tanggal: map['tanggal'] as String,
      jumlahItem: map['jumlah_item'] as int? ?? 0,
      items: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nomor_transaksi': nomorTransaksi,
      'total': total,
      'bayar': bayar,
      'kembali': kembali,
      'tanggal': tanggal,
      'jumlah_item': jumlahItem,
    };
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/providers/app_provider.dart
`dart
import 'package:flutter/material.dart';
import '../services/spreadsheet_service.dart';

class AppProvider extends ChangeNotifier {
  final SpreadsheetService _spreadsheetService = SpreadsheetService();

  int _selectedNavIndex = 0;
  int get selectedNavIndex => _selectedNavIndex;

  String? _connectedSpreadsheetPath;
  String? get connectedSpreadsheetPath => _connectedSpreadsheetPath;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _notificationMessage;
  String? get notificationMessage => _notificationMessage;

  AppProvider() {
    _initSpreadsheetStatus();
  }

  void setNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }

  Future<void> _initSpreadsheetStatus() async {
    _connectedSpreadsheetPath = await _spreadsheetService.getConnectedSpreadsheetPath();
    notifyListeners();
  }

  void updateSpreadsheetPath(String? path) {
    _connectedSpreadsheetPath = path;
    notifyListeners();
  }

  void showNotification(String msg) {
    _notificationMessage = msg;
    notifyListeners();
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/providers/kategori_provider.dart
`dart
import 'package:flutter/material.dart';
import '../models/kategori_model.dart';
import '../services/kategori_service.dart';

class KategoriProvider extends ChangeNotifier {
  final KategoriService _service = KategoriService();

  List<KategoriObat> _kategoriList = [];
  List<KategoriObat> get kategoriList => _kategoriList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchKategori() async {
    _isLoading = true;
    notifyListeners();

    try {
      _kategoriList = await _service.getAll();
    } catch (e) {
      debugPrint('Error fetchKategori: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addKategori(KategoriObat kategori) async {
    await _service.insert(kategori);
    await fetchKategori();
    return true;
  }

  Future<bool> updateKategori(KategoriObat kategori) async {
    await _service.update(kategori);
    await fetchKategori();
    return true;
  }

  Future<bool> deleteKategori(int id) async {
    await _service.delete(id);
    await fetchKategori();
    return true;
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/providers/laporan_provider.dart
`dart
import 'package:flutter/material.dart';
import '../services/laporan_service.dart';

class LaporanProvider extends ChangeNotifier {
  final LaporanService _service = LaporanService();

  DateTime _dariTanggal = DateTime.now().subtract(const Duration(days: 30));
  DateTime get dariTanggal => _dariTanggal;

  DateTime _sampaiTanggal = DateTime.now();
  DateTime get sampaiTanggal => _sampaiTanggal;

  LaporanRingkasan? _ringkasan;
  LaporanRingkasan? get ringkasan => _ringkasan;

  List<ObatTerlarisItem> _obatTerlaris = [];
  List<ObatTerlarisItem> get obatTerlaris => _obatTerlaris;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchLaporan() async {
    _isLoading = true;
    notifyListeners();

    try {
      _ringkasan = await _service.getRingkasan(_dariTanggal, _sampaiTanggal);
      _obatTerlaris = await _service.getObatTerlaris(limit: 5);
    } catch (e) {
      debugPrint('Error fetchLaporan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setDateRange(DateTime dari, DateTime sampai) {
    _dariTanggal = dari;
    _sampaiTanggal = sampai;
    fetchLaporan();
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/providers/obat_provider.dart
`dart
import 'package:flutter/material.dart';
import '../models/obat_model.dart';
import '../services/obat_service.dart';

class ObatProvider extends ChangeNotifier {
  final ObatService _service = ObatService();

  List<Obat> _obatList = [];
  List<Obat> get obatList => _obatList;

  List<Obat> _lowStockList = [];
  List<Obat> get lowStockList => _lowStockList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  int? _selectedKategoriId;
  int? get selectedKategoriId => _selectedKategoriId;

  Future<void> fetchObat() async {
    _isLoading = true;
    notifyListeners();

    try {
      _obatList = await _service.getAll(
        searchQuery: _searchQuery,
        kategoriId: _selectedKategoriId,
      );
      _lowStockList = await _service.getLowStock();
    } catch (e) {
      debugPrint('Error fetchObat: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchObat();
  }

  void setKategoriFilter(int? kategoriId) {
    _selectedKategoriId = kategoriId;
    fetchObat();
  }

  Future<bool> addObat(Obat obat) async {
    try {
      await _service.insert(obat);
      await fetchObat();
      return true;
    } catch (e) {
      debugPrint('Error addObat: $e');
      rethrow;
    }
  }

  Future<bool> updateObat(Obat obat) async {
    try {
      await _service.update(obat);
      await fetchObat();
      return true;
    } catch (e) {
      debugPrint('Error updateObat: $e');
      rethrow;
    }
  }

  Future<bool> deleteObat(int id) async {
    try {
      await _service.delete(id);
      await fetchObat();
      return true;
    } catch (e) {
      debugPrint('Error deleteObat: $e');
      rethrow;
    }
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/providers/pin_provider.dart
`dart
import 'package:flutter/material.dart';
import '../services/pin_service.dart';

class PinProvider extends ChangeNotifier {
  final PinService _service = PinService();

  bool _isUnlocked = false;
  bool get isUnlocked => _isUnlocked;

  bool _hasPinSet = false;
  bool get hasPinSet => _hasPinSet;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  PinProvider() {
    checkPinState();
  }

  Future<void> checkPinState() async {
    _isLoading = true;
    notifyListeners();

    _hasPinSet = await _service.hasPin();
    if (!_hasPinSet) {
      _isUnlocked = true; // Auto unlock if no PIN set yet
    } else {
      _isUnlocked = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> unlock(String pin) async {
    final valid = await _service.verifyPin(pin);
    if (valid) {
      _isUnlocked = true;
      notifyListeners();
    }
    return valid;
  }

  void lockApp() {
    if (_hasPinSet) {
      _isUnlocked = false;
      notifyListeners();
    }
  }

  Future<bool> setupNewPin(String pin) async {
    final success = await _service.setPin(pin);
    if (success) {
      _hasPinSet = true;
      _isUnlocked = true;
      notifyListeners();
    }
    return success;
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/providers/stok_provider.dart
`dart
import 'package:flutter/material.dart';
import '../models/stok_model.dart';
import '../services/stok_service.dart';

class StokProvider extends ChangeNotifier {
  final StokService _service = StokService();

  List<StokMutasi> _mutasiList = [];
  List<StokMutasi> get mutasiList => _mutasiList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchMutasi() async {
    _isLoading = true;
    notifyListeners();

    try {
      _mutasiList = await _service.getAllMutasi();
    } catch (e) {
      debugPrint('Error fetchMutasi: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStok({
    required int obatId,
    required String jenis,
    required int jumlah,
    String? catatan,
  }) async {
    final success = await _service.updateStok(
      obatId: obatId,
      jenis: jenis,
      jumlah: jumlah,
      catatan: catatan,
    );
    if (success) {
      await fetchMutasi();
    }
    return success;
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/providers/supplier_provider.dart
`dart
import 'package:flutter/material.dart';
import '../models/supplier_model.dart';
import '../services/supplier_service.dart';

class SupplierProvider extends ChangeNotifier {
  final SupplierService _service = SupplierService();

  List<Supplier> _supplierList = [];
  List<Supplier> get supplierList => _supplierList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchSupplier() async {
    _isLoading = true;
    notifyListeners();

    try {
      _supplierList = await _service.getAll();
    } catch (e) {
      debugPrint('Error fetchSupplier: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSupplier(Supplier supplier) async {
    await _service.insert(supplier);
    await fetchSupplier();
    return true;
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    await _service.update(supplier);
    await fetchSupplier();
    return true;
  }

  Future<bool> deleteSupplier(int id) async {
    await _service.delete(id);
    await fetchSupplier();
    return true;
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/providers/transaksi_provider.dart
`dart
import 'package:flutter/material.dart';
import '../models/obat_model.dart';
import '../models/transaksi_model.dart';
import '../models/detail_transaksi_model.dart';
import '../services/transaksi_service.dart';

class CartItem {
  final Obat obat;
  int jumlah;

  CartItem({
    required this.obat,
    this.jumlah = 1,
  });

  double get subtotal => obat.hargaJual * jumlah;
}

class TransaksiProvider extends ChangeNotifier {
  final TransaksiService _service = TransaksiService();

  List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => _cartItems;

  List<Transaksi> _transaksiList = [];
  List<Transaksi> get transaksiList => _transaksiList;

  double _bayar = 0.0;
  double get bayar => _bayar;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _todayTxCount = 0;
  int get todayTxCount => _todayTxCount;

  double _todayRevenue = 0.0;
  double get todayRevenue => _todayRevenue;

  double get totalBelanja => _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  double get kembali => (_bayar >= totalBelanja) ? (_bayar - totalBelanja) : 0.0;
  int get totalItemCount => _cartItems.fold(0, (sum, item) => sum + item.jumlah);

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transaksiList = await _service.getAll();
      _todayTxCount = await _service.getTodayCount();
      _todayRevenue = await _service.getTodayRevenue();
    } catch (e) {
      debugPrint('Error fetchHistory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addToCart(Obat obat) {
    // Check stock available
    final existingIndex = _cartItems.indexWhere((item) => item.obat.id == obat.id);
    if (existingIndex >= 0) {
      if (_cartItems[existingIndex].jumlah < obat.stokTersedia) {
        _cartItems[existingIndex].jumlah += 1;
      } else {
        throw Exception('Jumlah item melebihi stok yang tersedia (${obat.stokTersedia})!');
      }
    } else {
      if (obat.stokTersedia > 0) {
        _cartItems.add(CartItem(obat: obat, jumlah: 1));
      } else {
        throw Exception('Stok obat "${obat.nama}" habis!');
      }
    }
    notifyListeners();
  }

  void updateItemQuantity(int obatId, int delta) {
    final index = _cartItems.indexWhere((item) => item.obat.id == obatId);
    if (index >= 0) {
      final newQty = _cartItems[index].jumlah + delta;
      if (newQty <= 0) {
        _cartItems.removeAt(index);
      } else if (newQty <= _cartItems[index].obat.stokTersedia) {
        _cartItems[index].jumlah = newQty;
      } else {
        throw Exception('Jumlah item melebihi stok yang tersedia!');
      }
      notifyListeners();
    }
  }

  void removeFromCart(int obatId) {
    _cartItems.removeWhere((item) => item.obat.id == obatId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _bayar = 0.0;
    notifyListeners();
  }

  void setBayar(double amount) {
    _bayar = amount;
    notifyListeners();
  }

  Future<Transaksi?> processCheckout() async {
    if (_cartItems.isEmpty) {
      throw Exception('Keranjang belanja masih kosong!');
    }
    if (_bayar < totalBelanja) {
      throw Exception('Nominal pembayaran kurang dari total!');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final detailItems = _cartItems.map((item) => DetailTransaksi(
        obatId: item.obat.id!,
        jumlah: item.jumlah,
        hargaSatuan: item.obat.hargaJual,
        subtotal: item.subtotal,
        namaObat: item.obat.nama,
        kodeObat: item.obat.kodeObat,
      )).toList();

      final resultTx = await _service.createTransaksi(
        total: totalBelanja,
        bayar: _bayar,
        items: detailItems,
      );

      clearCart();
      await fetchHistory();
      return resultTx;
    } catch (e) {
      debugPrint('Error processCheckout: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/screens/main_desktop_shell.dart
`dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../providers/pin_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'transaksi/transaksi_screen.dart';
import 'obat/obat_list_screen.dart';
import 'stok/stok_screen.dart';
import 'kategori_supplier/kategori_supplier_screen.dart';
import 'laporan/laporan_screen.dart';
import 'backup_excel/backup_excel_screen.dart';

class MainDesktopShell extends StatelessWidget {
  const MainDesktopShell({super.key});

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const TransaksiScreen();
      case 2:
        return const ObatListScreen();
      case 3:
        return const StokScreen();
      case 4:
        return const KategoriSupplierScreen();
      case 5:
        return const LaporanScreen();
      case 6:
        return const BackupExcelScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, PinProvider>(
      builder: (context, appProv, pinProv, _) {
        return Scaffold(
          body: Row(
            children: [
              // Left Desktop Navigation Sidebar
              Container(
                width: 250,
                color: AppTheme.sidebarBackground,
                child: Column(
                  children: [
                    // Brand Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_pharmacy,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'FIRDAN FARMA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Apotek Windows',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFF334155), height: 1),
                    const SizedBox(height: 16),

                    // Nav Menu Items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _buildNavItem(context, appProv, index: 0, title: 'Dashboard', icon: Icons.dashboard_outlined),
                          _buildNavItem(context, appProv, index: 1, title: 'Kasir Penjualan', icon: Icons.point_of_sale),
                          _buildNavItem(context, appProv, index: 2, title: 'Katalog Obat', icon: Icons.medication_outlined),
                          _buildNavItem(context, appProv, index: 3, title: 'Mutasi Stok', icon: Icons.swap_vert),
                          _buildNavItem(context, appProv, index: 4, title: 'Kategori & Supplier', icon: Icons.category_outlined),
                          _buildNavItem(context, appProv, index: 5, title: 'Laporan & Analitik', icon: Icons.analytics_outlined),
                          _buildNavItem(context, appProv, index: 6, title: 'Backup & Excel', icon: Icons.table_chart_outlined),
                        ],
                      ),
                    ),

                    // User Info & PIN Lock Button Footer
                    const Divider(color: Color(0xFF334155), height: 1),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryTeal,
                            child: Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Kasir Utama',
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Offline Desktop',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => pinProv.lockApp(),
                            icon: const Icon(Icons.lock_outline, color: AppTheme.warningOrange, size: 20),
                            tooltip: 'Kunci Aplikasi (PIN)',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Right Body Content Area
              Expanded(
                child: Column(
                  children: [
                    // Top App Bar Header
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      decoration: const BoxDecoration(
                        color: AppTheme.cardBg,
                        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                _getMenuTitle(appProv.selectedNavIndex),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Excel status pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: appProv.connectedSpreadsheetPath != null
                                      ? AppTheme.primaryTealLight
                                      : AppTheme.warningBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      appProv.connectedSpreadsheetPath != null ? Icons.table_chart : Icons.table_chart_outlined,
                                      size: 14,
                                      color: appProv.connectedSpreadsheetPath != null ? AppTheme.primaryTeal : AppTheme.warningOrange,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      appProv.connectedSpreadsheetPath != null ? 'Excel Terhubung' : 'Excel Disconnected',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: appProv.connectedSpreadsheetPath != null ? AppTheme.primaryTeal : AppTheme.warningOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Live Clock
                              StreamBuilder(
                                stream: Stream.periodic(const Duration(seconds: 1)),
                                builder: (context, snapshot) {
                                  final nowStr = DateFormat('HH:mm:ss').format(DateTime.now());
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgLight,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                                        const SizedBox(width: 6),
                                        Text(
                                          nowStr,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Main Active Screen View
                    Expanded(
                      child: Container(
                        color: AppTheme.bgLight,
                        child: _getScreen(appProv.selectedNavIndex),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMenuTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard Utama';
      case 1:
        return 'Kasir Penjualan (POS)';
      case 2:
        return 'Katalog & Data Obat';
      case 3:
        return 'Mutasi Stok Obat';
      case 4:
        return 'Kategori & Supplier';
      case 5:
        return 'Laporan & Analitik';
      case 6:
        return 'Backup Database & Excel';
      default:
        return 'Apotek Firdan Farma';
    }
  }

  Widget _buildNavItem(BuildContext context, AppProvider appProv, {required int index, required String title, required IconData icon}) {
    final isSelected = appProv.selectedNavIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isSelected ? AppTheme.sidebarSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => appProv.setNavIndex(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppTheme.emeraldGreen : AppTheme.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/screens/backup_excel/backup_excel_screen.dart
`dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/obat_provider.dart';
import '../../services/backup_service.dart';
import '../../services/spreadsheet_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/medical_card.dart';

class BackupExcelScreen extends StatefulWidget {
  const BackupExcelScreen({super.key});

  @override
  State<BackupExcelScreen> createState() => _BackupExcelScreenState();
}

class _BackupExcelScreenState extends State<BackupExcelScreen> {
  final BackupService _backupService = BackupService();
  final SpreadsheetService _spreadsheetService = SpreadsheetService();

  bool _isProcessing = false;

  Future<void> _handleExportDatabase() async {
    setState(() => _isProcessing = true);
    try {
      final savedPath = await _backupService.exportDatabase();
      if (savedPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup database berhasil disimpan di: $savedPath'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppTheme.dangerRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleImportDatabase() async {
    final path = await _backupService.pickBackupFile();
    if (path == null) return;

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Restore Database'),
        content: const Text('Restore database akan menimpa seluruh data saat ini dengan data dari file backup. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore Data'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final success = await _backupService.importDatabase(path);
      if (success && mounted) {
        Provider.of<ObatProvider>(context, listen: false).fetchObat();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database berhasil dipulihkan dari backup!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal restore: ${e.toString()}'), backgroundColor: AppTheme.dangerRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleExportExcel() async {
    setState(() => _isProcessing = true);
    try {
      final path = await _spreadsheetService.exportDatabaseToSpreadsheet();
      if (path != null && mounted) {
        Provider.of<AppProvider>(context, listen: false).updateSpreadsheetPath(path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data obat berhasil diekspor ke Excel: $path'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ekspor Excel: ${e.toString()}'), backgroundColor: AppTheme.dangerRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleImportExcel() async {
    final path = await _spreadsheetService.pickSpreadsheetFile();
    if (path == null) return;

    setState(() => _isProcessing = true);
    try {
      final count = await _spreadsheetService.importSpreadsheetToDb(path);
      if (mounted) {
        Provider.of<AppProvider>(context, listen: false).updateSpreadsheetPath(path);
        Provider.of<ObatProvider>(context, listen: false).fetchObat();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengimpor/memperbarui $count data obat dari Excel!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal impor Excel: ${e.toString()}'), backgroundColor: AppTheme.dangerRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProv, _) {
        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Backup & Integrasi Spreadsheet',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kelola file cadangan database lokal (.db) dan ekspor/impor data obat ke Excel (.xlsx)',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),

              if (_isProcessing)
                const LinearProgressIndicator(color: AppTheme.primaryTeal),

              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Database Backup Box
                  Expanded(
                    child: MedicalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.sd_storage_outlined, color: AppTheme.primaryTeal, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'Backup Database Lokal (.db)',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          const Text(
                            'Simpan seluruh database obat, transaksi, dan mutasi stok ke dalam file .db yang dapat dibagikan atau dipindahkan ke komputer lain.',
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _handleExportDatabase,
                              icon: const Icon(Icons.download),
                              label: const Text('Ekspor File Backup Database (.db)'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isProcessing ? null : _handleImportDatabase,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Import / Restore File Database'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Spreadsheet Box
                  Expanded(
                    child: MedicalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.table_chart_outlined, color: AppTheme.emeraldGreen, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'Integrasi Spreadsheet Excel (.xlsx)',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(
                            appProv.connectedSpreadsheetPath != null
                                ? 'Status: Terhubung ke Excel'
                                : 'Status: Belum Terhubung',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: appProv.connectedSpreadsheetPath != null ? AppTheme.emeraldGreen : AppTheme.warningOrange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appProv.connectedSpreadsheetPath ?? 'Pilih file .xlsx untuk sinkronisasi otomatis.',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen),
                              onPressed: _isProcessing ? null : _handleExportExcel,
                              icon: const Icon(Icons.file_download),
                              label: const Text('Ekspor Katalog Obat ke Excel (.xlsx)'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.emeraldGreen, side: const BorderSide(color: AppTheme.emeraldGreen)),
                              onPressed: _isProcessing ? null : _handleImportExcel,
                              icon: const Icon(Icons.file_upload),
                              label: const Text('Impor Data Obat dari File Excel'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/screens/dashboard/dashboard_screen.dart
`dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../providers/obat_provider.dart';
import '../../providers/transaksi_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/medical_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ObatProvider>(context, listen: false).fetchObat();
      Provider.of<TransaksiProvider>(context, listen: false).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Consumer3<AppProvider, ObatProvider, TransaksiProvider>(
      builder: (context, appProv, obatProv, txProv, _) {
        final totalObatCount = obatProv.obatList.length;
        final lowStockCount = obatProv.lowStockList.length;
        final todayRevenue = txProv.todayRevenue;
        final todayTxCount = txProv.todayTxCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Eksekutif Apotek',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monitoring penjualan harian, stok obat, dan koneksi spreadsheet',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryTeal),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Spreadsheet Status Banner
              MedicalCard(
                padding: const EdgeInsets.all(16),
                backgroundColor: appProv.connectedSpreadsheetPath != null
                    ? AppTheme.primaryTealLight.withOpacity(0.5)
                    : AppTheme.warningBg.withOpacity(0.6),
                border: BorderSide(
                  color: appProv.connectedSpreadsheetPath != null ? AppTheme.primaryTeal : AppTheme.warningOrange,
                ),
                child: Row(
                  children: [
                    Icon(
                      appProv.connectedSpreadsheetPath != null ? Icons.table_chart : Icons.table_chart_outlined,
                      color: appProv.connectedSpreadsheetPath != null ? AppTheme.primaryTeal : AppTheme.warningOrange,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appProv.connectedSpreadsheetPath != null
                                ? 'Spreadsheet Terhubung (.xlsx)'
                                : 'Spreadsheet Belum Terhubung',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                          ),
                          Text(
                            appProv.connectedSpreadsheetPath ?? 'Hubungkan file Excel untuk sinkronisasi otomatis data obat.',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appProv.connectedSpreadsheetPath != null ? AppTheme.primaryTeal : AppTheme.warningOrange,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => appProv.setNavIndex(6), // Navigate to Backup & Excel
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: Text(appProv.connectedSpreadsheetPath != null ? 'Kelola Spreadsheet' : 'Hubungkan Excel'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Metric StatCards Grid
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 2.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(
                    title: 'Penjualan Hari Ini',
                    value: currencyFormatter.format(todayRevenue),
                    subtitle: '$todayTxCount Transaksi Kasir',
                    icon: Icons.payments_outlined,
                    iconBgColor: AppTheme.primaryTealLight,
                    iconColor: AppTheme.primaryTeal,
                  ),
                  StatCard(
                    title: 'Transaksi Kasir',
                    value: '$todayTxCount',
                    subtitle: 'Total invoice hari ini',
                    icon: Icons.receipt_long_outlined,
                    iconBgColor: AppTheme.emeraldLight,
                    iconColor: AppTheme.emeraldGreen,
                  ),
                  StatCard(
                    title: 'Total Katalog Obat',
                    value: '$totalObatCount Item',
                    subtitle: 'SKU Aktif di Sistem',
                    icon: Icons.medication_outlined,
                    iconBgColor: const Color(0xFFE0F2FE),
                    iconColor: AppTheme.cyanAccent,
                  ),
                  StatCard(
                    title: 'Peringatan Stok Menipis',
                    value: '$lowStockCount Item',
                    subtitle: lowStockCount > 0 ? 'Perlu Restok Segera!' : 'Stok Aman',
                    icon: Icons.warning_amber_rounded,
                    iconBgColor: lowStockCount > 0 ? AppTheme.warningBg : AppTheme.successBg,
                    iconColor: lowStockCount > 0 ? AppTheme.warningOrange : AppTheme.successGreen,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Main Section: Left = Low Stock Alert, Right = Quick Actions & Recent Sales
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Low Stock List
                  Expanded(
                    flex: 6,
                    child: MedicalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined, color: AppTheme.primaryTeal),
                                  SizedBox(width: 8),
                                  Text(
                                    'Peringatan Stok Obat Menipis',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  ),
                                ],
                              ),
                              OutlinedButton(
                                onPressed: () => appProv.setNavIndex(3), // Mutasi Stok
                                child: const Text('Mutasi Stok'),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (obatProv.lowStockList.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(32),
                              alignment: Alignment.center,
                              child: Column(
                                children: const [
                                  Icon(Icons.check_circle_outline, size: 48, color: AppTheme.emeraldGreen),
                                  SizedBox(height: 12),
                                  Text('Semua stok obat dalam kondisi aman!', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: obatProv.lowStockList.length,
                              separatorBuilder: (_, __) => const Divider(height: 12),
                              itemBuilder: (context, index) {
                                final obat = obatProv.lowStockList[index];
                                return Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: obat.isHabis ? AppTheme.dangerBg : AppTheme.warningBg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        obat.isHabis ? Icons.error_outline : Icons.warning_amber_rounded,
                                        color: obat.isHabis ? AppTheme.dangerRed : AppTheme.warningOrange,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            obat.nama,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            'Kode: ${obat.kodeObat} • Kategori: ${obat.namaKategori ?? '-'}',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${obat.stokTersedia} unit',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: obat.isHabis ? AppTheme.dangerRed : AppTheme.warningOrange,
                                          ),
                                        ),
                                        Text(
                                          'Min: ${obat.stokMinimal}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Quick Action Buttons Panel
                  Expanded(
                    flex: 4,
                    child: MedicalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.flash_on, color: AppTheme.primaryTeal),
                              SizedBox(width: 8),
                              Text(
                                'Akses Cepat',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Column(
                            children: [
                              _buildQuickActionButton(
                                context,
                                label: 'Buka Kasir Penjualan',
                                icon: Icons.point_of_sale,
                                color: AppTheme.primaryTeal,
                                onTap: () => appProv.setNavIndex(1),
                              ),
                              const SizedBox(height: 12),
                              _buildQuickActionButton(
                                context,
                                label: 'Tambah Obat Baru',
                                icon: Icons.add_box_outlined,
                                color: AppTheme.emeraldGreen,
                                onTap: () => appProv.setNavIndex(2),
                              ),
                              const SizedBox(height: 12),
                              _buildQuickActionButton(
                                context,
                                label: 'Laporan Penjualan',
                                icon: Icons.analytics_outlined,
                                color: AppTheme.cyanAccent,
                                onTap: () => appProv.setNavIndex(5),
                              ),
                              const SizedBox(height: 12),
                              _buildQuickActionButton(
                                context,
                                label: 'Backup Database (.db)',
                                icon: Icons.sd_storage_outlined,
                                color: const Color(0xFF6366F1),
                                onTap: () => appProv.setNavIndex(6),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.bgLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/screens/kategori_supplier/kategori_supplier_screen.dart
`dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/kategori_model.dart';
import '../../models/supplier_model.dart';
import '../../providers/kategori_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/medical_card.dart';

class KategoriSupplierScreen extends StatefulWidget {
  const KategoriSupplierScreen({super.key});

  @override
  State<KategoriSupplierScreen> createState() => _KategoriSupplierScreenState();
}

class _KategoriSupplierScreenState extends State<KategoriSupplierScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KategoriProvider>(context, listen: false).fetchKategori();
      Provider.of<SupplierProvider>(context, listen: false).fetchSupplier();
    });
  }

  void _showKategoriDialog({KategoriObat? kategori}) {
    final namaController = TextEditingController(text: kategori?.nama ?? '');
    final deskripsiController = TextEditingController(text: kategori?.deskripsi ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(kategori == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama Kategori *')),
            const SizedBox(height: 12),
            TextField(controller: deskripsiController, decoration: const InputDecoration(labelText: 'Deskripsi')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (namaController.text.trim().isNotEmpty) {
                final katProv = Provider.of<KategoriProvider>(context, listen: false);
                final newKat = KategoriObat(
                  id: kategori?.id,
                  nama: namaController.text.trim(),
                  deskripsi: deskripsiController.text.trim(),
                );
                if (kategori == null) {
                  await katProv.addKategori(newKat);
                } else {
                  await katProv.updateKategori(newKat);
                }
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showSupplierDialog({Supplier? supplier}) {
    final namaController = TextEditingController(text: supplier?.nama ?? '');
    final kontakController = TextEditingController(text: supplier?.kontak ?? '');
    final alamatController = TextEditingController(text: supplier?.alamat ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(supplier == null ? 'Tambah Supplier' : 'Edit Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama Supplier *')),
            const SizedBox(height: 12),
            TextField(controller: kontakController, decoration: const InputDecoration(labelText: 'Kontak / No HP')),
            const SizedBox(height: 12),
            TextField(controller: alamatController, decoration: const InputDecoration(labelText: 'Alamat')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (namaController.text.trim().isNotEmpty) {
                final supProv = Provider.of<SupplierProvider>(context, listen: false);
                final newSup = Supplier(
                  id: supplier?.id,
                  nama: namaController.text.trim(),
                  kontak: kontakController.text.trim(),
                  alamat: alamatController.text.trim(),
                );
                if (supplier == null) {
                  await supProv.addSupplier(newSup);
                } else {
                  await supProv.updateSupplier(newSup);
                }
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategori Section
          Expanded(
            child: MedicalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.category_outlined, color: AppTheme.primaryTeal),
                          SizedBox(width: 8),
                          Text('Kategori Obat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showKategoriDialog(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Tambah Kategori'),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: Consumer<KategoriProvider>(
                      builder: (context, katProv, _) {
                        if (katProv.isLoading) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal));
                        }
                        return ListView.separated(
                          itemCount: katProv.kategoriList.length,
                          separatorBuilder: (_, __) => const Divider(height: 8),
                          itemBuilder: (context, index) {
                            final k = katProv.kategoriList[index];
                            return ListTile(
                              title: Text(k.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(k.deskripsi ?? '-', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppTheme.primaryTeal, size: 18),
                                    onPressed: () => _showKategoriDialog(kategori: k),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: AppTheme.dangerRed, size: 18),
                                    onPressed: () => katProv.deleteKategori(k.id!),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Supplier Section
          Expanded(
            child: MedicalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_shipping_outlined, color: AppTheme.primaryTeal),
                          SizedBox(width: 8),
                          Text('Data Supplier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showSupplierDialog(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Tambah Supplier'),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: Consumer<SupplierProvider>(
                      builder: (context, supProv, _) {
                        if (supProv.isLoading) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal));
                        }
                        return ListView.separated(
                          itemCount: supProv.supplierList.length,
                          separatorBuilder: (_, __) => const Divider(height: 8),
                          itemBuilder: (context, index) {
                            final s = supProv.supplierList[index];
                            return ListTile(
                              title: Text(s.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Kontak: ${s.kontak ?? '-'} • Alamat: ${s.alamat ?? '-'}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppTheme.primaryTeal, size: 18),
                                    onPressed: () => _showSupplierDialog(supplier: s),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: AppTheme.dangerRed, size: 18),
                                    onPressed: () => supProv.deleteSupplier(s.id!),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/screens/laporan/laporan_screen.dart
`dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/laporan_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/medical_card.dart';
import '../../widgets/stat_card.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LaporanProvider>(context, listen: false).fetchLaporan();
    });
  }

  Future<void> _pickDateRange() async {
    final lapProv = Provider.of<LaporanProvider>(context, listen: false);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: lapProv.dariTanggal, end: lapProv.sampaiTanggal),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryTeal,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      lapProv.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Consumer<LaporanProvider>(
      builder: (context, lapProv, _) {
        final ringkasan = lapProv.ringkasan;
        final dariStr = DateFormat('dd MMM yyyy').format(lapProv.dariTanggal);
        final sampaiStr = DateFormat('dd MMM yyyy').format(lapProv.sampaiTanggal);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Laporan & Analitik Penjualan',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ringkasan pendapatan, transaksi, est. keuntungan, dan obat terlaris',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.date_range, color: AppTheme.primaryTeal),
                    label: Text('Periode: $dariStr - $sampaiStr'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stat Cards Grid
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 2.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(
                    title: 'Total Penjualan',
                    value: currencyFormatter.format(ringkasan?.totalPenjualan ?? 0),
                    subtitle: 'Omset kotor periode ini',
                    icon: Icons.trending_up,
                    iconBgColor: AppTheme.primaryTealLight,
                    iconColor: AppTheme.primaryTeal,
                  ),
                  StatCard(
                    title: 'Total Transaksi',
                    value: '${ringkasan?.totalTransaksi ?? 0}',
                    subtitle: 'Struk penjualan kasir',
                    icon: Icons.receipt_long,
                    iconBgColor: AppTheme.emeraldLight,
                    iconColor: AppTheme.emeraldGreen,
                  ),
                  StatCard(
                    title: 'Item Terjual',
                    value: '${ringkasan?.totalItemTerjual ?? 0} Unit',
                    subtitle: 'Total obat terjual',
                    icon: Icons.shopping_bag_outlined,
                    iconBgColor: const Color(0xFFE0F2FE),
                    iconColor: AppTheme.cyanAccent,
                  ),
                  StatCard(
                    title: 'Est. Keuntungan Bersih',
                    value: currencyFormatter.format(ringkasan?.totalEstKeuntungan ?? 0),
                    subtitle: 'Total Harga Jual - Harga Beli',
                    icon: Icons.account_balance_wallet_outlined,
                    iconBgColor: const Color(0xFFEEF2FF),
                    iconColor: const Color(0xFF6366F1),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Obat Terlaris Table
              MedicalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.star_outline, color: AppTheme.primaryTeal),
                        SizedBox(width: 8),
                        Text(
                          'Obat Terlaris (Top 5 Best Seller)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (lapProv.isLoading)
                      const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal))
                    else if (lapProv.obatTerlaris.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('Belum ada data penjualan pada periode ini')),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: lapProv.obatTerlaris.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, index) {
                          final item = lapProv.obatTerlaris[index];
                          return Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: index == 0 ? AppTheme.warningOrange : AppTheme.primaryTealLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: index == 0 ? Colors.white : AppTheme.primaryTeal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.namaObat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('Kode Obat: ${item.kodeObat}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.totalTerjual} Unit Terjual',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryTeal),
                                  ),
                                  Text(
                                    'Total Omset: ${currencyFormatter.format(item.totalSubtotal)}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/screens/obat/obat_list_screen.dart
`dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/obat_model.dart';
import '../../providers/obat_provider.dart';
import '../../providers/kategori_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/medical_card.dart';
import '../../widgets/custom_badge.dart';

class ObatListScreen extends StatefulWidget {
  const ObatListScreen({super.key});

  @override
  State<ObatListScreen> createState() => _ObatListScreenState();
}

class _ObatListScreenState extends State<ObatListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ObatProvider>(context, listen: false).fetchObat();
      Provider.of<KategoriProvider>(context, listen: false).fetchKategori();
      Provider.of<SupplierProvider>(context, listen: false).fetchSupplier();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showObatDialog({Obat? obat}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ObatFormDialog(obat: obat),
    );
  }

  void _confirmDelete(int obatId, String namaObat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus data obat "$namaObat"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () async {
              Navigator.of(context).pop();
              await Provider.of<ObatProvider>(context, listen: false).deleteObat(obatId);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Katalog & Data Obat',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kelola inventaris obat, harga beli, harga jual, dan stok minimal',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showObatDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Obat Baru'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters Card
          MedicalCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari Nama / Kode Obat...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                Provider.of<ObatProvider>(context, listen: false).setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      Provider.of<ObatProvider>(context, listen: false).setSearchQuery(val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Consumer<KategoriProvider>(
                  builder: (context, katProv, _) {
                    final selectedKatId = Provider.of<ObatProvider>(context).selectedKategoriId;
                    return SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<int?>(
                        value: selectedKatId,
                        decoration: const InputDecoration(
                          hintText: 'Semua Kategori',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Semua Kategori'),
                          ),
                          ...katProv.kategoriList.map((k) => DropdownMenuItem<int?>(
                                value: k.id,
                                child: Text(k.nama),
                              )),
                        ],
                        onChanged: (val) {
                          Provider.of<ObatProvider>(context, listen: false).setKategoriFilter(val);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Data Table Container
          Expanded(
            child: MedicalCard(
              padding: EdgeInsets.zero,
              child: Consumer<ObatProvider>(
                builder: (context, obatProv, _) {
                  if (obatProv.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal));
                  }

                  if (obatProv.obatList.isEmpty) {
                    return const Center(
                      child: Text('Belum ada data obat', style: TextStyle(color: AppTheme.textSecondary)),
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.bgLight),
                        columns: const [
                          DataColumn(label: Text('KODE', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('NAMA OBAT', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('KATEGORI', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('SUPPLIER', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('HARGA BELI', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('HARGA JUAL', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('STOK', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('AKSI', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: obatProv.obatList.map((obat) {
                          return DataRow(
                            cells: [
                              DataCell(Text(obat.kodeObat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              DataCell(Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(obat.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  if (obat.deskripsi != null && obat.deskripsi!.isNotEmpty)
                                    Text(obat.deskripsi!, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), maxLines: 1),
                                ],
                              )),
                              DataCell(Text(obat.namaKategori ?? '-', style: const TextStyle(fontSize: 12))),
                              DataCell(Text(obat.namaSupplier ?? '-', style: const TextStyle(fontSize: 12))),
                              DataCell(Text(currencyFormatter.format(obat.hargaBeli), style: const TextStyle(fontSize: 12))),
                              DataCell(Text(currencyFormatter.format(obat.hargaJual), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal, fontSize: 13))),
                              DataCell(
                                obat.isHabis
                                    ? CustomBadge.danger('Habis (0)')
                                    : obat.isStokMenipis
                                        ? CustomBadge.warning('${obat.stokTersedia} unit')
                                        : CustomBadge.success('${obat.stokTersedia} unit'),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryTeal, size: 20),
                                      onPressed: () => _showObatDialog(obat: obat),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed, size: 20),
                                      onPressed: () => _confirmDelete(obat.id!, obat.nama),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObatFormDialog extends StatefulWidget {
  final Obat? obat;

  const _ObatFormDialog({this.obat});

  @override
  State<_ObatFormDialog> createState() => _ObatFormDialogState();
}

class _ObatFormDialogState extends State<_ObatFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _kodeController;
  late TextEditingController _namaController;
  late TextEditingController _hargaBeliController;
  late TextEditingController _hargaJualController;
  late TextEditingController _stokTersediaController;
  late TextEditingController _stokMinimalController;
  late TextEditingController _deskripsiController;

  int? _selectedKategoriId;
  int? _selectedSupplierId;

  @override
  void initState() {
    super.initState();
    final o = widget.obat;
    _kodeController = TextEditingController(text: o?.kodeObat ?? 'OBT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    _namaController = TextEditingController(text: o?.nama ?? '');
    _hargaBeliController = TextEditingController(text: o != null ? o.hargaBeli.toStringAsFixed(0) : '');
    _hargaJualController = TextEditingController(text: o != null ? o.hargaJual.toStringAsFixed(0) : '');
    _stokTersediaController = TextEditingController(text: o != null ? o.stokTersedia.toString() : '0');
    _stokMinimalController = TextEditingController(text: o != null ? o.stokMinimal.toString() : '5');
    _deskripsiController = TextEditingController(text: o?.deskripsi ?? '');

    _selectedKategoriId = o?.kategoriId;
    _selectedSupplierId = o?.supplierId;

    final katList = Provider.of<KategoriProvider>(context, listen: false).kategoriList;
    if (_selectedKategoriId == null && katList.isNotEmpty) {
      _selectedKategoriId = katList.first.id;
    }
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _hargaBeliController.dispose();
    _hargaJualController.dispose();
    _stokTersediaController.dispose();
    _stokMinimalController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedKategoriId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kategori obat terlebih dahulu!')),
        );
        return;
      }

      final obatProv = Provider.of<ObatProvider>(context, listen: false);
      final newObat = Obat(
        id: widget.obat?.id,
        nama: _namaController.text.trim(),
        kodeObat: _kodeController.text.trim(),
        kategoriId: _selectedKategoriId!,
        supplierId: _selectedSupplierId,
        hargaBeli: double.parse(_hargaBeliController.text.trim()),
        hargaJual: double.parse(_hargaJualController.text.trim()),
        stokTersedia: int.parse(_stokTersediaController.text.trim()),
        stokMinimal: int.parse(_stokMinimalController.text.trim()),
        deskripsi: _deskripsiController.text.trim(),
        createdAt: widget.obat?.createdAt ?? DateTime.now().toIso8601String(),
      );

      if (widget.obat == null) {
        await obatProv.addObat(newObat);
      } else {
        await obatProv.updateObat(newObat);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final katList = Provider.of<KategoriProvider>(context).kategoriList;
    final supList = Provider.of<SupplierProvider>(context).supplierList;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.obat == null ? 'Tambah Obat Baru' : 'Edit Data Obat',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _kodeController,
                      decoration: const InputDecoration(labelText: 'Kode Obat *'),
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _namaController,
                      decoration: const InputDecoration(labelText: 'Nama Obat *'),
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedKategoriId,
                      decoration: const InputDecoration(labelText: 'Kategori *'),
                      items: katList.map((k) => DropdownMenuItem<int?>(value: k.id, child: Text(k.nama))).toList(),
                      onChanged: (val) => setState(() => _selectedKategoriId = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedSupplierId,
                      decoration: const InputDecoration(labelText: 'Supplier'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('- Tanpa Supplier -')),
                        ...supList.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.nama))),
                      ],
                      onChanged: (val) => setState(() => _selectedSupplierId = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hargaBeliController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga Beli (Rp) *'),
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _hargaJualController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga Jual (Rp) *'),
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stokTersediaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stok Tersedia *'),
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stokMinimalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stok Minimal *'),
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Deskripsi / Indikasi Obat'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Simpan Data Obat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/screens/pin/pin_gate_screen.dart
`dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pin_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';

class PinGateScreen extends StatefulWidget {
  final Widget child;

  const PinGateScreen({super.key, required this.child});

  @override
  State<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends State<PinGateScreen> {
  String _pinInput = '';
  String _errorMessage = '';

  void _onKeyPress(String digit) {
    if (_pinInput.length < 6) {
      setState(() {
        _pinInput += digit;
        _errorMessage = '';
      });
      if (_pinInput.length == 6) {
        _submitPin();
      }
    }
  }

  void _onBackspace() {
    if (_pinInput.isNotEmpty) {
      setState(() {
        _pinInput = _pinInput.substring(0, _pinInput.length - 1);
        _errorMessage = '';
      });
    }
  }

  Future<void> _submitPin() async {
    final pinProvider = Provider.of<PinProvider>(context, listen: false);
    if (pinProvider.hasPinSet) {
      final valid = await pinProvider.unlock(_pinInput);
      if (!valid) {
        setState(() {
          _pinInput = '';
          _errorMessage = 'PIN Salah! Silakan coba lagi.';
        });
      }
    } else {
      // Setup initial PIN
      await pinProvider.setupNewPin(_pinInput);
    }
  }

  Widget _buildKeypadButton(String text, {VoidCallback? onPressed, Widget? child}) {
    return Container(
      margin: const EdgeInsets.all(6),
      child: Material(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed ?? () => _onKeyPress(text),
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: child ?? Text(
              text,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PinProvider>(
      builder: (context, pinProvider, _) {
        if (pinProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal)),
          );
        }

        if (pinProvider.isUnlocked) {
          return widget.child;
        }

        final isSetupMode = !pinProvider.hasPinSet;

        return Scaffold(
          backgroundColor: AppTheme.sidebarBackground,
          body: Center(
            child: Container(
              width: 440,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTealLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_pharmacy,
                      size: 40,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSetupMode
                        ? 'Buat PIN Keamanan Baru (6 Digit)'
                        : 'Masukkan 6 Digit PIN Pengaman',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  // PIN Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFilled = index < _pinInput.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? AppTheme.primaryTeal : Colors.transparent,
                          border: Border.all(
                            color: isFilled ? AppTheme.primaryTeal : AppTheme.borderLight,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 28),
                  // Keypad
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['1', '2', '3'].map((d) => _buildKeypadButton(d)).toList(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['4', '5', '6'].map((d) => _buildKeypadButton(d)).toList(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['7', '8', '9'].map((d) => _buildKeypadButton(d)).toList(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 84),
                          _buildKeypadButton('0'),
                          _buildKeypadButton(
                            '',
                            onPressed: _onBackspace,
                            child: const Icon(Icons.backspace_outlined, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/screens/stok/stok_screen.dart
`dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/obat_provider.dart';
import '../../providers/stok_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/medical_card.dart';

class StokScreen extends StatefulWidget {
  const StokScreen({super.key});

  @override
  State<StokScreen> createState() => _StokScreenState();
}

class _StokScreenState extends State<StokScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  int? _selectedObatId;
  String _selectedJenis = 'masuk';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ObatProvider>(context, listen: false).fetchObat();
      Provider.of<StokProvider>(context, listen: false).fetchMutasi();
    });
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _submitMutasi() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedObatId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih obat terlebih dahulu!')),
        );
        return;
      }

      final stokProv = Provider.of<StokProvider>(context, listen: false);
      final obatProv = Provider.of<ObatProvider>(context, listen: false);

      try {
        final success = await stokProv.updateStok(
          obatId: _selectedObatId!,
          jenis: _selectedJenis,
          jumlah: int.parse(_jumlahController.text.trim()),
          catatan: _catatanController.text.trim().isNotEmpty ? _catatanController.text.trim() : null,
        );

        if (success && mounted) {
          _jumlahController.clear();
          _catatanController.clear();
          await obatProv.fetchObat();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mutasi stok berhasil dicatat!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Form Input Mutasi Stok
          Expanded(
            flex: 4,
            child: MedicalCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.swap_vert, color: AppTheme.primaryTeal),
                        SizedBox(width: 8),
                        Text(
                          'Input Mutasi Stok',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Consumer<ObatProvider>(
                      builder: (context, obatProv, _) {
                        return DropdownButtonFormField<int?>(
                          value: _selectedObatId,
                          decoration: const InputDecoration(labelText: 'Pilih Obat *'),
                          items: obatProv.obatList.map((o) {
                            return DropdownMenuItem<int?>(
                              value: o.id,
                              child: Text('${o.nama} (Stok: ${o.stokTersedia})'),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedObatId = val),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Stok Masuk (+)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            value: 'masuk',
                            groupValue: _selectedJenis,
                            activeColor: AppTheme.emeraldGreen,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setState(() => _selectedJenis = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Stok Keluar (-)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            value: 'keluar',
                            groupValue: _selectedJenis,
                            activeColor: AppTheme.dangerRed,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setState(() => _selectedJenis = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _jumlahController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Jumlah Unit *'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Wajib diisi';
                        final num = int.tryParse(v);
                        if (num == null || num <= 0) return 'Jumlah harus > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _catatanController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Catatan / Alasan Mutasi'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedJenis == 'masuk' ? AppTheme.primaryTeal : AppTheme.dangerRed,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _submitMutasi,
                        icon: const Icon(Icons.save),
                        label: Text('Simpan Mutasi ${_selectedJenis.toUpperCase()}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Right: Riwayat Mutasi Table
          Expanded(
            flex: 6,
            child: MedicalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, color: AppTheme.primaryTeal),
                      SizedBox(width: 8),
                      Text(
                        'Riwayat Mutasi Stok',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: Consumer<StokProvider>(
                      builder: (context, stokProv, _) {
                        if (stokProv.isLoading) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal));
                        }

                        if (stokProv.mutasiList.isEmpty) {
                          return const Center(child: Text('Belum ada riwayat mutasi stok'));
                        }

                        return ListView.separated(
                          itemCount: stokProv.mutasiList.length,
                          separatorBuilder: (_, __) => const Divider(height: 12),
                          itemBuilder: (context, index) {
                            final mutasi = stokProv.mutasiList[index];
                            final isMasuk = mutasi.jenis == 'masuk';
                            final dateFormatted = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(mutasi.tanggal));

                            return Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isMasuk ? AppTheme.emeraldLight : AppTheme.dangerBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isMasuk ? AppTheme.emeraldGreen : AppTheme.dangerRed,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mutasi.namaObat ?? 'Obat ID ${mutasi.obatId}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        mutasi.catatan ?? (isMasuk ? 'Stok Masuk' : 'Stok Keluar'),
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isMasuk ? '+' : '-'}${mutasi.jumlah} unit',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isMasuk ? AppTheme.emeraldGreen : AppTheme.dangerRed,
                                      ),
                                    ),
                                    Text(
                                      dateFormatted,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/screens/transaksi/transaksi_screen.dart
`dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/obat_provider.dart';
import '../../providers/transaksi_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/medical_card.dart';
import '../../widgets/receipt_dialog.dart';
import '../../widgets/custom_badge.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _bayarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ObatProvider>(context, listen: false).fetchObat();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bayarController.dispose();
    super.dispose();
  }

  void _onBayarPreset(double amount, TransaksiProvider txProv) {
    txProv.setBayar(amount);
    _bayarController.text = amount.toStringAsFixed(0);
  }

  Future<void> _handleCheckout(TransaksiProvider txProv) async {
    try {
      final tx = await txProv.processCheckout();
      _bayarController.clear();
      if (tx != null && mounted) {
        showDialog(
          context: context,
          builder: (context) => ReceiptDialog(transaksi: tx),
        );
        // Refresh obat list stock
        Provider.of<ObatProvider>(context, listen: false).fetchObat();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Product Selector
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Search Bar
                MedicalCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari Nama Obat atau Scan Kode Barcode...',
                            prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      Provider.of<ObatProvider>(context, listen: false).setSearchQuery('');
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (val) {
                            Provider.of<ObatProvider>(context, listen: false).setSearchQuery(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Products Grid/List
                Expanded(
                  child: Consumer2<ObatProvider, TransaksiProvider>(
                    builder: (context, obatProv, txProv, _) {
                      if (obatProv.isLoading) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal));
                      }

                      if (obatProv.obatList.isEmpty) {
                        return const Center(
                          child: Text('Tidak ada obat ditemukan', style: TextStyle(color: AppTheme.textSecondary)),
                        );
                      }

                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: obatProv.obatList.length,
                        itemBuilder: (context, index) {
                          final obat = obatProv.obatList[index];
                          return Material(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: obat.isHabis
                                  ? null
                                  : () {
                                      try {
                                        txProv.addToCart(obat);
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString().replaceAll('Exception: ', '')),
                                            backgroundColor: AppTheme.warningOrange,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: obat.isHabis ? AppTheme.dangerBg : AppTheme.borderLight,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            obat.kodeObat,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                            maxLines: 1,
                                          ),
                                        ),
                                        if (obat.isHabis)
                                          CustomBadge.danger('Habis')
                                        else if (obat.isStokMenipis)
                                          CustomBadge.warning('Stok ${obat.stokTersedia}')
                                        else
                                          CustomBadge.success('Stok ${obat.stokTersedia}'),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      obat.nama,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: obat.isHabis ? AppTheme.textMuted : AppTheme.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          currencyFormatter.format(obat.hargaJual),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryTeal,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: obat.isHabis ? AppTheme.bgLight : AppTheme.primaryTealLight,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.add_shopping_cart,
                                            size: 16,
                                            color: obat.isHabis ? AppTheme.textMuted : AppTheme.primaryTeal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Right Side: Active Cart & Checkout
          Expanded(
            flex: 4,
            child: MedicalCard(
              child: Consumer<TransaksiProvider>(
                builder: (context, txProv, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryTeal),
                              const SizedBox(width: 8),
                              const Text(
                                'Keranjang Penjualan',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              if (txProv.cartItems.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryTeal,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${txProv.totalItemCount}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (txProv.cartItems.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => txProv.clearCart(),
                              icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.dangerRed),
                              label: const Text('Kosongkan', style: TextStyle(color: AppTheme.dangerRed, fontSize: 12)),
                            ),
                        ],
                      ),
                      const Divider(height: 20),
                      // Cart List
                      Expanded(
                        child: txProv.cartItems.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.shopping_cart_outlined, size: 48, color: AppTheme.textMuted),
                                    SizedBox(height: 12),
                                    Text('Keranjang masih kosong', style: TextStyle(color: AppTheme.textMuted)),
                                    SizedBox(height: 4),
                                    Text('Pilih obat di sebelah kiri untuk menambahkan', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: txProv.cartItems.length,
                                separatorBuilder: (_, __) => const Divider(height: 12),
                                itemBuilder: (context, index) {
                                  final item = txProv.cartItems[index];
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.obat.nama,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              maxLines: 1,
                                            ),
                                            Text(
                                              '${currencyFormatter.format(item.obat.hargaJual)} / unit',
                                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Qty Controls
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppTheme.textSecondary),
                                            onPressed: () => txProv.updateItemQuantity(item.obat.id!, -1),
                                          ),
                                          Text(
                                            '${item.jumlah}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.primaryTeal),
                                            onPressed: () {
                                              try {
                                                txProv.updateItemQuantity(item.obat.id!, 1);
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        currencyFormatter.format(item.subtotal),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryTeal),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                      const Divider(height: 20),
                      // Totals & Payment Section
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL BELANJA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(
                                currencyFormatter.format(txProv.totalBelanja),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryTeal),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Payment Input & Quick Money Buttons
                          TextField(
                            controller: _bayarController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Uang Pembayaran (Rp)',
                              prefixIcon: Icon(Icons.payments_outlined, color: AppTheme.primaryTeal),
                            ),
                            onChanged: (val) {
                              final doubleVal = double.tryParse(val) ?? 0.0;
                              txProv.setBayar(doubleVal);
                            },
                          ),
                          const SizedBox(height: 8),
                          // Preset Cash Money Buttons
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                OutlinedButton(
                                  onPressed: txProv.totalBelanja > 0 ? () => _onBayarPreset(txProv.totalBelanja, txProv) : null,
                                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                  child: const Text('Uang Pas', style: TextStyle(fontSize: 11)),
                                ),
                                const SizedBox(width: 6),
                                ...[10000, 20000, 50000, 100000].map((amt) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: OutlinedButton(
                                    onPressed: () => _onBayarPreset(amt.toDouble(), txProv),
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                    child: Text(currencyFormatter.format(amt), style: const TextStyle(fontSize: 11)),
                                  ),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Kembalian:', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                              Text(
                                currencyFormatter.format(txProv.kembali),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.emeraldGreen),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryTeal,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: (txProv.cartItems.isEmpty || txProv.bayar < txProv.totalBelanja || txProv.isLoading)
                                  ? null
                                  : () => _handleCheckout(txProv),
                              icon: txProv.isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.print, size: 20),
                              label: const Text('PROSES & CETAK STRUK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/services/backup_service.dart
`dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String?> exportDatabase() async {
    final currentDbPath = await _dbHelper.getDbPath();
    final dbFile = File(currentDbPath);

    if (!await dbFile.exists()) {
      throw Exception('File database tidak ditemukan!');
    }

    final nowStr = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final defaultFileName = 'firdan_farma_backup_$nowStr.db';

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan File Backup Database Apotek',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite'],
    );

    if (outputPath != null) {
      await dbFile.copy(outputPath);
      return outputPath;
    }
    return null;
  }

  Future<bool> importDatabase(String sourceFilePath) async {
    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) {
      throw Exception('File backup yang dipilih tidak dapat dibaca!');
    }

    // 1. Close active DB connection
    await _dbHelper.closeAndReset();

    // 2. Overwrite target DB file
    final targetDbPath = await _dbHelper.getDbPath();
    final targetFile = File(targetDbPath);

    await sourceFile.copy(targetFile.path);

    // 3. Re-open database
    await _dbHelper.database;
    return true;
  }

  Future<String?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Pilih File Backup Database (.db)',
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite'],
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files.single.path;
    }
    return null;
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/services/kategori_service.dart
`dart
import '../database/database_helper.dart';
import '../models/kategori_model.dart';

class KategoriService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<KategoriObat>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('kategori_obat', orderBy: 'nama ASC');
    return maps.map((m) => KategoriObat.fromMap(m)).toList();
  }

  Future<KategoriObat?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('kategori_obat', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return KategoriObat.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insert(KategoriObat kategori) async {
    final db = await _dbHelper.database;
    return await db.insert('kategori_obat', kategori.toMap());
  }

  Future<int> update(KategoriObat kategori) async {
    final db = await _dbHelper.database;
    return await db.update(
      'kategori_obat',
      kategori.toMap(),
      where: 'id = ?',
      whereArgs: [kategori.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('kategori_obat', where: 'id = ?', whereArgs: [id]);
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/services/laporan_service.dart
`dart
import '../database/database_helper.dart';

class LaporanRingkasan {
  final double totalPenjualan;
  final int totalTransaksi;
  final int totalItemTerjual;
  final double totalEstKeuntungan;

  LaporanRingkasan({
    required this.totalPenjualan,
    required this.totalTransaksi,
    required this.totalItemTerjual,
    required this.totalEstKeuntungan,
  });
}

class ObatTerlarisItem {
  final String namaObat;
  final String kodeObat;
  final int totalTerjual;
  final double totalSubtotal;

  ObatTerlarisItem({
    required this.namaObat,
    required this.kodeObat,
    required this.totalTerjual,
    required this.totalSubtotal,
  });
}

class LaporanService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<LaporanRingkasan> getRingkasan(DateTime dari, DateTime sampai) async {
    final db = await _dbHelper.database;
    final dariStr = dari.toIso8601String().substring(0, 10);
    final sampaiStr = sampai.toIso8601String().substring(0, 10) + 'T23:59:59';

    final txMaps = await db.rawQuery('''
      SELECT COUNT(*) as total_tx, COALESCE(SUM(total), 0) as sum_total, COALESCE(SUM(jumlah_item), 0) as sum_item
      FROM transaksi
      WHERE tanggal >= ? AND tanggal <= ?
    ''', [dariStr, sampaiStr]);

    final totalTx = txMaps.first['total_tx'] as int? ?? 0;
    final totalPenjualan = (txMaps.first['sum_total'] as num?)?.toDouble() ?? 0.0;
    final totalItemTerjual = (txMaps.first['sum_item'] as num?)?.toInt() ?? 0;

    // Estimate profit = sum( (harga_satuan - harga_beli) * jumlah )
    final profitMaps = await db.rawQuery('''
      SELECT COALESCE(SUM((d.harga_satuan - o.harga_beli) * d.jumlah), 0) as total_profit
      FROM detail_transaksi d
      JOIN transaksi t ON d.transaksi_id = t.id
      JOIN obat o ON d.obat_id = o.id
      WHERE t.tanggal >= ? AND t.tanggal <= ?
    ''', [dariStr, sampaiStr]);

    final estProfit = (profitMaps.first['total_profit'] as num?)?.toDouble() ?? 0.0;

    return LaporanRingkasan(
      totalPenjualan: totalPenjualan,
      totalTransaksi: totalTx,
      totalItemTerjual: totalItemTerjual,
      totalEstKeuntungan: estProfit,
    );
  }

  Future<List<ObatTerlarisItem>> getObatTerlaris({int limit = 5}) async {
    final db = await _dbHelper.database;
    final sql = '''
      SELECT o.nama AS nama_obat, o.kode_obat, SUM(d.jumlah) AS total_terjual, SUM(d.subtotal) AS total_subtotal
      FROM detail_transaksi d
      JOIN obat o ON d.obat_id = o.id
      GROUP BY d.obat_id
      ORDER BY total_terjual DESC
      LIMIT ?
    ''';
    final maps = await db.rawQuery(sql, [limit]);
    return maps.map((m) => ObatTerlarisItem(
      namaObat: m['nama_obat'] as String,
      kodeObat: m['kode_obat'] as String,
      totalTerjual: (m['total_terjual'] as num).toInt(),
      totalSubtotal: (m['total_subtotal'] as num).toDouble(),
    )).toList();
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/services/obat_service.dart
`dart
import '../database/database_helper.dart';
import '../models/obat_model.dart';

class ObatService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Obat>> getAll({String? searchQuery, int? kategoriId}) async {
    final db = await _dbHelper.database;
    String sql = '''
      SELECT o.*, k.nama AS nama_kategori, s.nama AS nama_supplier
      FROM obat o
      LEFT JOIN kategori_obat k ON o.kategori_id = k.id
      LEFT JOIN supplier s ON o.supplier_id = s.id
      WHERE 1=1
    ''';
    List<dynamic> args = [];

    if (kategoriId != null && kategoriId > 0) {
      sql += ' AND o.kategori_id = ?';
      args.add(kategoriId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      sql += ' AND (o.nama LIKE ? OR o.kode_obat LIKE ?)';
      args.add('%${searchQuery.trim()}%');
      args.add('%${searchQuery.trim()}%');
    }

    sql += ' ORDER BY o.nama ASC';

    final maps = await db.rawQuery(sql, args);
    return maps.map((m) => Obat.fromMap(m)).toList();
  }

  Future<List<Obat>> getLowStock() async {
    final db = await _dbHelper.database;
    final sql = '''
      SELECT o.*, k.nama AS nama_kategori, s.nama AS nama_supplier
      FROM obat o
      LEFT JOIN kategori_obat k ON o.kategori_id = k.id
      LEFT JOIN supplier s ON o.supplier_id = s.id
      WHERE o.stok_tersedia <= o.stok_minimal
      ORDER BY o.stok_tersedia ASC
    ''';
    final maps = await db.rawQuery(sql);
    return maps.map((m) => Obat.fromMap(m)).toList();
  }

  Future<Obat?> getById(int id) async {
    final db = await _dbHelper.database;
    final sql = '''
      SELECT o.*, k.nama AS nama_kategori, s.nama AS nama_supplier
      FROM obat o
      LEFT JOIN kategori_obat k ON o.kategori_id = k.id
      LEFT JOIN supplier s ON o.supplier_id = s.id
      WHERE o.id = ?
    ''';
    final maps = await db.rawQuery(sql, [id]);
    if (maps.isNotEmpty) {
      return Obat.fromMap(maps.first);
    }
    return null;
  }

  Future<Obat?> getByKode(String kodeObat) async {
    final db = await _dbHelper.database;
    final sql = '''
      SELECT o.*, k.nama AS nama_kategori, s.nama AS nama_supplier
      FROM obat o
      LEFT JOIN kategori_obat k ON o.kategori_id = k.id
      LEFT JOIN supplier s ON o.supplier_id = s.id
      WHERE o.kode_obat = ?
    ''';
    final maps = await db.rawQuery(sql, [kodeObat]);
    if (maps.isNotEmpty) {
      return Obat.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insert(Obat obat) async {
    final db = await _dbHelper.database;
    return await db.insert('obat', obat.toMap());
  }

  Future<int> update(Obat obat) async {
    final db = await _dbHelper.database;
    return await db.update(
      'obat',
      obat.toMap(),
      where: 'id = ?',
      whereArgs: [obat.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('obat', where: 'id = ?', whereArgs: [id]);
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/services/pin_service.dart
`dart
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';

class PinService {
  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(AppConstants.prefsPinKey);
    return pin != null && pin.trim().isNotEmpty;
  }

  Future<bool> verifyPin(String pinInput) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(AppConstants.prefsPinKey);
    if (savedPin == null || savedPin.isEmpty) {
      return true; // No PIN set yet
    }
    return savedPin == pinInput.trim();
  }

  Future<bool> setPin(String newPin) async {
    if (newPin.trim().length != 6) {
      throw Exception('PIN harus terdiri dari 6 angka digit!');
    }
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(AppConstants.prefsPinKey, newPin.trim());
  }

  Future<bool> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(AppConstants.prefsPinKey);
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/services/spreadsheet_service.dart
`dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/obat_model.dart';
import '../services/obat_service.dart';
import '../services/kategori_service.dart';
import '../utils/app_constants.dart';

class SpreadsheetService {
  final ObatService _obatService = ObatService();
  final KategoriService _kategoriService = KategoriService();

  Future<String?> getConnectedSpreadsheetPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefsSpreadsheetPathKey);
  }

  Future<void> setConnectedSpreadsheetPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(AppConstants.prefsSpreadsheetPathKey);
    } else {
      await prefs.setString(AppConstants.prefsSpreadsheetPathKey, path);
    }
  }

  Future<String?> pickSpreadsheetFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Pilih File Excel Data Obat (.xlsx)',
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) {
        await setConnectedSpreadsheetPath(path);
      }
      return path;
    }
    return null;
  }

  Future<String?> exportDatabaseToSpreadsheet() async {
    final obatList = await _obatService.getAll();

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Data Obat Apotek'];
    excel.setDefaultSheet('Data Obat Apotek');

    // Header row
    List<CellValue> headers = [
      TextCellValue('ID'),
      TextCellValue('Kode Obat'),
      TextCellValue('Nama Obat'),
      TextCellValue('Kategori'),
      TextCellValue('Supplier'),
      TextCellValue('Harga Beli'),
      TextCellValue('Harga Jual'),
      TextCellValue('Stok Tersedia'),
      TextCellValue('Stok Minimal'),
      TextCellValue('Deskripsi'),
    ];
    sheetObject.appendRow(headers);

    for (var obat in obatList) {
      sheetObject.appendRow([
        IntCellValue(obat.id ?? 0),
        TextCellValue(obat.kodeObat),
        TextCellValue(obat.nama),
        TextCellValue(obat.namaKategori ?? 'Umum'),
        TextCellValue(obat.namaSupplier ?? '-'),
        DoubleCellValue(obat.hargaBeli),
        DoubleCellValue(obat.hargaJual),
        IntCellValue(obat.stokTersedia),
        IntCellValue(obat.stokMinimal),
        TextCellValue(obat.deskripsi ?? ''),
      ]);
    }

    final nowStr = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final defaultFileName = 'FirdanFarma_DataObat_$nowStr.xlsx';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Ekspor Data Obat ke Excel',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (savePath != null) {
      var fileBytes = excel.save();
      if (fileBytes != null) {
        File(savePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        await setConnectedSpreadsheetPath(savePath);
        return savePath;
      }
    }
    return null;
  }

  Future<int> importSpreadsheetToDb(String filePath) async {
    final bytes = File(filePath).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    int count = 0;

    final categories = await _kategoriService.getAll();
    int defaultKategoriId = categories.isNotEmpty ? categories.first.id! : 1;

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table];
      if (sheet == null) continue;

      bool isFirstRow = true;
      for (var row in sheet.rows) {
        if (isFirstRow) {
          isFirstRow = false;
          continue; // Skip header row
        }

        if (row.length < 3) continue;

        String? kode = row[1]?.value?.toString().trim();
        String? nama = row[2]?.value?.toString().trim();

        if (nama == null || nama.isEmpty) continue;
        if (kode == null || kode.isEmpty) {
          kode = 'OBT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        }

        double hargaBeli = double.tryParse(row[5]?.value?.toString() ?? '0') ?? 0;
        double hargaJual = double.tryParse(row[6]?.value?.toString() ?? '0') ?? 0;
        int stokTersedia = int.tryParse(row[7]?.value?.toString() ?? '0') ?? 0;
        int stokMinimal = int.tryParse(row[8]?.value?.toString() ?? '5') ?? 5;
        String? deskripsi = row.length > 9 ? row[9]?.value?.toString() : '';

        // Check if code exists
        final existing = await _obatService.getByKode(kode);
        if (existing != null) {
          // Update
          await _obatService.update(existing.copyWith(
            nama: nama,
            hargaBeli: hargaBeli > 0 ? hargaBeli : existing.hargaBeli,
            hargaJual: hargaJual > 0 ? hargaJual : existing.hargaJual,
            stokTersedia: stokTersedia,
            stokMinimal: stokMinimal,
            deskripsi: deskripsi ?? existing.deskripsi,
          ));
        } else {
          // Insert
          await _obatService.insert(Obat(
            nama: nama,
            kodeObat: kode,
            kategoriId: defaultKategoriId,
            hargaBeli: hargaBeli,
            hargaJual: hargaJual,
            stokTersedia: stokTersedia,
            stokMinimal: stokMinimal,
            deskripsi: deskripsi,
            createdAt: DateTime.now().toIso8601String(),
          ));
        }
        count++;
      }
    }
    return count;
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/services/stok_service.dart
`dart
import '../database/database_helper.dart';
import '../models/stok_model.dart';

class StokService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<StokMutasi>> getAllMutasi() async {
    final db = await _dbHelper.database;
    final sql = '''
      SELECT s.*, o.nama AS nama_obat
      FROM stok s
      JOIN obat o ON s.obat_id = o.id
      ORDER BY s.tanggal DESC
    ''';
    final maps = await db.rawQuery(sql);
    return maps.map((m) => StokMutasi.fromMap(m)).toList();
  }

  Future<bool> updateStok({
    required int obatId,
    required String jenis, // 'masuk' or 'keluar'
    required int jumlah,
    String? catatan,
  }) async {
    if (jumlah <= 0) return false;

    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      final obatMaps = await txn.query('obat', where: 'id = ?', whereArgs: [obatId]);
      if (obatMaps.isEmpty) return false;

      final stokTersedia = obatMaps.first['stok_tersedia'] as int;
      int stokBaru = stokTersedia;

      if (jenis == 'masuk') {
        stokBaru += jumlah;
      } else if (jenis == 'keluar') {
        if (stokTersedia < jumlah) {
          throw Exception('Stok tidak mencukupi untuk dikurangi ($stokTersedia tersedia)');
        }
        stokBaru -= jumlah;
      } else {
        return false;
      }

      await txn.update(
        'obat',
        {'stok_tersedia': stokBaru},
        where: 'id = ?',
        whereArgs: [obatId],
      );

      final now = DateTime.now().toIso8601String();
      await txn.insert('stok', {
        'obat_id': obatId,
        'jenis': jenis,
        'jumlah': jumlah,
        'catatan': catatan ?? (jenis == 'masuk' ? 'Stok Masuk Manual' : 'Stok Keluar Manual'),
        'tanggal': now,
      });

      return true;
    });
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/services/supplier_service.dart
`dart
import '../database/database_helper.dart';
import '../models/supplier_model.dart';

class SupplierService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Supplier>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('supplier', orderBy: 'nama ASC');
    return maps.map((m) => Supplier.fromMap(m)).toList();
  }

  Future<Supplier?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('supplier', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Supplier.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insert(Supplier supplier) async {
    final db = await _dbHelper.database;
    return await db.insert('supplier', supplier.toMap());
  }

  Future<int> update(Supplier supplier) async {
    final db = await _dbHelper.database;
    return await db.update(
      'supplier',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('supplier', where: 'id = ?', whereArgs: [id]);
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/services/transaksi_service.dart
`dart
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaksi_model.dart';
import '../models/detail_transaksi_model.dart';

class TransaksiService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> generateNomorTransaksi() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final datePrefix = DateFormat('yyyyMMdd').format(now);

    final maps = await db.rawQuery(
      "SELECT COUNT(*) as count FROM transaksi WHERE nomor_transaksi LIKE ?",
      ['TRX-$datePrefix-%'],
    );
    final count = (maps.first['count'] as int? ?? 0) + 1;
    final formattedCount = count.toString().padLeft(4, '0');
    return 'TRX-$datePrefix-$formattedCount';
  }

  Future<Transaksi?> createTransaksi({
    required double total,
    required double bayar,
    required List<DetailTransaksi> items,
  }) async {
    if (items.isEmpty) return null;
    if (bayar < total) {
      throw Exception('Nominal pembayaran kurang dari total belanja!');
    }

    final db = await _dbHelper.database;
    final nomorTx = await generateNomorTransaksi();
    final nowStr = DateTime.now().toIso8601String();
    final kembali = bayar - total;
    final totalItemCount = items.fold<int>(0, (sum, item) => sum + item.jumlah);

    return await db.transaction((txn) async {
      // 1. Verify stock availability
      for (final item in items) {
        final obatMaps = await txn.query('obat', where: 'id = ?', whereArgs: [item.obatId]);
        if (obatMaps.isEmpty) {
          throw Exception('Obat ID ${item.obatId} tidak ditemukan!');
        }
        final stok = obatMaps.first['stok_tersedia'] as int;
        if (stok < item.jumlah) {
          final nama = obatMaps.first['nama'] as String;
          throw Exception('Stok obat "$nama" tidak mencukupi (tersedia: $stok, diminta: ${item.jumlah})');
        }
      }

      // 2. Insert transaksi master record
      final txId = await txn.insert('transaksi', {
        'nomor_transaksi': nomorTx,
        'total': total,
        'bayar': bayar,
        'kembali': kembali,
        'tanggal': nowStr,
        'jumlah_item': totalItemCount,
      });

      List<DetailTransaksi> savedDetails = [];

      // 3. Insert details and update stock
      for (final item in items) {
        final detailId = await txn.insert('detail_transaksi', {
          'transaksi_id': txId,
          'obat_id': item.obatId,
          'jumlah': item.jumlah,
          'harga_satuan': item.hargaSatuan,
          'subtotal': item.subtotal,
        });

        // Decrement stock
        await txn.rawUpdate(
          'UPDATE obat SET stok_tersedia = stok_tersedia - ? WHERE id = ?',
          [item.jumlah, item.obatId],
        );

        // Record stock mutation
        await txn.insert('stok', {
          'obat_id': item.obatId,
          'jenis': 'keluar',
          'jumlah': item.jumlah,
          'catatan': 'Penjualan Kasir $nomorTx',
          'tanggal': nowStr,
        });

        savedDetails.add(DetailTransaksi(
          id: detailId,
          transaksiId: txId,
          obatId: item.obatId,
          jumlah: item.jumlah,
          hargaSatuan: item.hargaSatuan,
          subtotal: item.subtotal,
          namaObat: item.namaObat,
          kodeObat: item.kodeObat,
        ));
      }

      return Transaksi(
        id: txId,
        nomorTransaksi: nomorTx,
        total: total,
        bayar: bayar,
        kembali: kembali,
        tanggal: nowStr,
        jumlahItem: totalItemCount,
        items: savedDetails,
      );
    });
  }

  Future<List<Transaksi>> getAll() async {
    final db = await _dbHelper.database;
    final txMaps = await db.query('transaksi', orderBy: 'id DESC');

    List<Transaksi> result = [];
    for (final map in txMaps) {
      final txId = map['id'] as int;
      final detailMaps = await db.rawQuery('''
        SELECT d.*, o.nama AS nama_obat, o.kode_obat AS kode_obat
        FROM detail_transaksi d
        JOIN obat o ON d.obat_id = o.id
        WHERE d.transaksi_id = ?
      ''', [txId]);

      final items = detailMaps.map((d) => DetailTransaksi.fromMap(d)).toList();
      result.add(Transaksi.fromMap(map, items: items));
    }
    return result;
  }

  Future<int> getTodayCount() async {
    final db = await _dbHelper.database;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM transaksi WHERE tanggal LIKE ?",
      ['$todayStr%'],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<double> getTodayRevenue() async {
    final db = await _dbHelper.database;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final result = await db.rawQuery(
      "SELECT SUM(total) as sum FROM transaksi WHERE tanggal LIKE ?",
      ['$todayStr%'],
    );
    return (result.first['sum'] as num?)?.toDouble() ?? 0.0;
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/theme/app_theme.dart
`dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Medical Palette
  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color primaryTealDark = Color(0xFF115E59);
  static const Color primaryTealLight = Color(0xFFCCFBF1);

  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFFD1FAE5);

  static const Color cyanAccent = Color(0xFF06B6D4);

  static const Color sidebarBackground = Color(0xFF0F172A); // Dark Slate/Navy
  static const Color sidebarSelected = Color(0xFF1E293B);

  static const Color bgLight = Color(0xFFF1F5F9);
  static const Color cardBg = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color borderLight = Color(0xFFE2E8F0);

  // Status Colors
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);

  static const Color dangerRed = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEE2E2);

  static const Color successGreen = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: bgLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: cyanAccent,
        surface: cardBg,
        error: dangerRed,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textPrimary),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: primaryTeal),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/utils/app_constants.dart
`dart
class AppConstants {
  static const String appName = 'Apotek Firdan Farma';
  static const String appSubtitle = 'Sistem Manajemen & Kasir Apotek Windows';
  static const String appVersion = '1.1 (Windows Desktop)';

  static const String databaseFileName = 'firdan_farma.db';
  static const String prefsPinKey = 'app_pin_code';
  static const String prefsSpreadsheetPathKey = 'connected_spreadsheet_path';

  static const int minStockDefault = 5;
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/widgets/custom_badge.dart
`dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const CustomBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory CustomBadge.success(String label) {
    return CustomBadge(
      label: label,
      backgroundColor: AppTheme.successBg,
      textColor: AppTheme.successGreen,
      icon: Icons.check_circle_outline,
    );
  }

  factory CustomBadge.warning(String label) {
    return CustomBadge(
      label: label,
      backgroundColor: AppTheme.warningBg,
      textColor: AppTheme.warningOrange,
      icon: Icons.warning_amber_rounded,
    );
  }

  factory CustomBadge.danger(String label) {
    return CustomBadge(
      label: label,
      backgroundColor: AppTheme.dangerBg,
      textColor: AppTheme.dangerRed,
      icon: Icons.error_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/widgets/medical_card.dart
`dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MedicalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;
  final BorderSide? border;

  const MedicalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 16,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: border?.color ?? AppTheme.borderLight,
          width: border?.width ?? 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/widgets/receipt_dialog.dart
`dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaksi_model.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';

class ReceiptDialog extends StatelessWidget {
  final Transaksi transaksi;

  const ReceiptDialog({
    super.key,
    required this.transaksi,
  });

  Future<void> _printReceipt() async {
    final pdf = pw.Document();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(AppConstants.appName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ),
              pw.Center(
                child: pw.Text('Jl. Kesehatan No. 1, Kota', style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.Divider(thickness: 0.5),
              pw.Text('No. TRX : ${transaksi.nomorTransaksi}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Tanggal : ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(transaksi.tanggal))}', style: const pw.TextStyle(fontSize: 9)),
              pw.Divider(thickness: 0.5),
              ...transaksi.items.map((item) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text('${item.namaObat ?? 'Obat'} (${item.jumlah}x)', style: const pw.TextStyle(fontSize: 9))),
                  pw.Text(currencyFormatter.format(item.subtotal), style: const pw.TextStyle(fontSize: 9)),
                ],
              )),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(currencyFormatter.format(transaksi.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bayar', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(currencyFormatter.format(transaksi.bayar), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kembali', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(currencyFormatter.format(transaksi.kembali), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('Terima Kasih Semoga Lekas Sembuh', style: const pw.TextStyle(fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatted = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(transaksi.tanggal));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long, color: AppTheme.primaryTeal),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Struk Penjualan Kasir',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'Transaksi Berhasil Disimpan',
                        style: TextStyle(fontSize: 12, color: AppTheme.emeraldGreen, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(transaksi.nomorTransaksi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(dateFormatted, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                  const Divider(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: transaksi.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = transaksi.items[index];
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.namaObat ?? 'Obat',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    '${item.jumlah} x ${currencyFormatter.format(item.hargaSatuan)}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormatter.format(item.subtotal),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Belanja', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        currencyFormatter.format(transaksi.total),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryTeal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jumlah Bayar', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      Text(currencyFormatter.format(transaksi.bayar), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kembalian', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      Text(currencyFormatter.format(transaksi.kembali), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _printReceipt,
                    icon: const Icon(Icons.print),
                    label: const Text('Cetak Struk'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Selesai'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

``n

## C:/Users/LENOVO LOQ/Apotek-Firdan-Farma/Firdan-Farma-Windows/lib/widgets/stat_card.dart
`dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconBgColor = AppTheme.primaryTealLight,
    this.iconColor = AppTheme.primaryTeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

``n
