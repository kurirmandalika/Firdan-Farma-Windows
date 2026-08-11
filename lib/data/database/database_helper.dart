import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firdan_farma_windows/core/constants/app_constants.dart';

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
        version: 3,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE obat ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (oldVersion < 3) {
      await _createIndexes(db);
    }
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
        is_active INTEGER NOT NULL DEFAULT 1,
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

    await _createIndexes(db);

    await seedInitialData(db);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_obat_kategori ON obat(kategori_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_obat_supplier ON obat(supplier_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_obat_active ON obat(is_active)',
    );
    await db.execute('CREATE INDEX IF NOT EXISTS idx_obat_nama ON obat(nama)');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_obat_kode ON obat(kode_obat)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stok_obat ON stok(obat_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stok_tanggal ON stok(tanggal)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transaksi_tanggal ON transaksi(tanggal)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_detail_transaksi ON detail_transaksi(transaksi_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_detail_transaksi_obat ON detail_transaksi(obat_id)',
    );
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
