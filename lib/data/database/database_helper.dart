import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firdan_farma_windows/core/constants/app_constants.dart';

class DatabaseHelper {
  static const dbFileName = AppConstants.databaseFileName;
  static const schemaVersion = 7;

  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;
  static bool _desktopFactoryInitialized = false;

  DatabaseHelper._internal();

  static void ensureDatabaseFactory() {
    if (_desktopFactoryInitialized ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return;
    }
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _desktopFactoryInitialized = true;
  }

  static Future<Database> openInMemoryForTesting() async {
    ensureDatabaseFactory();
    await instance.closeAndReset();
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: instance._onCreate,
        onUpgrade: instance._onUpgrade,
      ),
    );
    _database = db;
    return db;
  }

  static Future<Database> openFileForTesting(String path) async {
    ensureDatabaseFactory();
    await instance.closeAndReset();
    final db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: instance._onCreate,
        onUpgrade: instance._onUpgrade,
      ),
    );
    _database = db;
    return db;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<String> getDbPath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return p.join(documentsDirectory.path, dbFileName);
  }

  Future<Database> _initDatabase() async {
    ensureDatabaseFactory();

    final path = await getDbPath();
    await _backupBeforeMajorMigration(path, targetVersion: schemaVersion);

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _backupBeforeMajorMigration(
    String path, {
    required int targetVersion,
  }) async {
    final dbFile = File(path);
    if (!await dbFile.exists()) return;

    Database? probeDb;
    try {
      probeDb = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(readOnly: true),
      );
      final versionRows = await probeDb.rawQuery('PRAGMA user_version');
      final currentVersion = versionRows.isNotEmpty
          ? versionRows.first.values.first as int? ?? 0
          : 0;
      if (currentVersion <= 0 || currentVersion >= targetVersion) return;

      final nowStr = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final backupPath = p.join(
        dbFile.parent.path,
        'firdan_farma_before_v${targetVersion}_$nowStr.db',
      );
      await dbFile.copy(backupPath);
    } catch (_) {
      // If probing fails, let the normal database open surface the real error.
    } finally {
      await probeDb?.close();
    }
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
    if (oldVersion < 4) {
      await _migrateToV4(db);
    }
    if (oldVersion < 5) {
      await _migrateToV5(db);
    }
    if (oldVersion < 6) {
      await _migrateToV6(db);
    }
    if (oldVersion < 7) {
      await _migrateToV7(db);
    }
    await _createIndexes(db);
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
        satuan TEXT NOT NULL DEFAULT 'PCS',
        kategori_id INTEGER NOT NULL,
        supplier_id INTEGER,
        harga_beli REAL NOT NULL,
        harga_jual REAL NOT NULL,
        awl INTEGER NOT NULL DEFAULT 0,
        msk INTEGER NOT NULL DEFAULT 0,
        klr INTEGER NOT NULL DEFAULT 0,
        stok_minimal INTEGER NOT NULL DEFAULT 5,
        stok_tersedia INTEGER NOT NULL DEFAULT 0,
        deskripsi TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
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
        tipe_mutasi TEXT NOT NULL DEFAULT 'PENYESUAIAN_MASUK',
        reference_type TEXT,
        reference_id INTEGER,
        harga_beli_snapshot REAL,
        stok_sebelum INTEGER,
        stok_sesudah INTEGER,
        alasan TEXT,
        catatan TEXT,
        kode_transaksi TEXT,
        batch_no TEXT,
        expired_date TEXT,
        user_id INTEGER,
        username_snapshot TEXT,
        tanggal TEXT NOT NULL,
        created_at TEXT,
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
        metode_pembayaran TEXT NOT NULL DEFAULT 'TUNAI',
        tanggal TEXT NOT NULL,
        jumlah_item INTEGER NOT NULL DEFAULT 0,
        total_sebelum_diskon REAL NOT NULL DEFAULT 0,
        diskon REAL NOT NULL DEFAULT 0,
        diberi_diskon INTEGER NOT NULL DEFAULT 0,
        laporan_tanggal TEXT,
        kode_laporan TEXT,
        user_id INTEGER,
        username_snapshot TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE detail_transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaksi_id INTEGER NOT NULL,
        obat_id INTEGER NOT NULL,
        jumlah INTEGER NOT NULL,
        harga_satuan REAL NOT NULL,
        harga_modal_satuan REAL,
        subtotal REAL NOT NULL,
        subtotal_modal REAL,
        laba_kotor REAL,
        nama_obat_snapshot TEXT,
        kode_obat_snapshot TEXT,
        FOREIGN KEY (transaksi_id) REFERENCES transaksi(id),
        FOREIGN KEY (obat_id) REFERENCES obat(id)
      )
    ''');

    await _createPurchaseTables(db);
    await _createUserTables(db);
    await _createBatchTable(db);

    await _createIndexes(db);

    await _seedDefaultCategories(db);
  }

  Future<void> _migrateToV4(Database db) async {
    await _addColumnIfMissing(db, 'obat', "satuan TEXT NOT NULL DEFAULT 'PCS'");
    await _addColumnIfMissing(db, 'obat', 'updated_at TEXT');
    await db.execute(
      "UPDATE obat SET satuan = 'PCS' WHERE satuan IS NULL OR TRIM(satuan) = ''",
    );
    await db.execute(
      'UPDATE obat SET updated_at = COALESCE(updated_at, created_at)',
    );

    await _addColumnIfMissing(
      db,
      'transaksi',
      "metode_pembayaran TEXT NOT NULL DEFAULT 'TUNAI'",
    );

    await _addColumnIfMissing(
      db,
      'detail_transaksi',
      'harga_modal_satuan REAL',
    );
    await _addColumnIfMissing(db, 'detail_transaksi', 'subtotal_modal REAL');
    await _addColumnIfMissing(db, 'detail_transaksi', 'laba_kotor REAL');
    await _addColumnIfMissing(
      db,
      'detail_transaksi',
      'nama_obat_snapshot TEXT',
    );
    await _addColumnIfMissing(
      db,
      'detail_transaksi',
      'kode_obat_snapshot TEXT',
    );
    await db.execute('''
      UPDATE detail_transaksi
      SET harga_modal_satuan = (
            SELECT harga_beli FROM obat WHERE obat.id = detail_transaksi.obat_id
          )
      WHERE harga_modal_satuan IS NULL
    ''');
    await db.execute('''
      UPDATE detail_transaksi
      SET subtotal_modal = COALESCE(harga_modal_satuan, 0) * jumlah
      WHERE subtotal_modal IS NULL
    ''');
    await db.execute('''
      UPDATE detail_transaksi
      SET laba_kotor = subtotal - COALESCE(subtotal_modal, 0)
      WHERE laba_kotor IS NULL
    ''');
    await db.execute('''
      UPDATE detail_transaksi
      SET nama_obat_snapshot = (
            SELECT nama FROM obat WHERE obat.id = detail_transaksi.obat_id
          )
      WHERE nama_obat_snapshot IS NULL
    ''');
    await db.execute('''
      UPDATE detail_transaksi
      SET kode_obat_snapshot = (
            SELECT kode_obat FROM obat WHERE obat.id = detail_transaksi.obat_id
          )
      WHERE kode_obat_snapshot IS NULL
    ''');

    await _addColumnIfMissing(
      db,
      'stok',
      "tipe_mutasi TEXT NOT NULL DEFAULT 'PENYESUAIAN_MASUK'",
    );
    await _addColumnIfMissing(db, 'stok', 'reference_type TEXT');
    await _addColumnIfMissing(db, 'stok', 'reference_id INTEGER');
    await _addColumnIfMissing(db, 'stok', 'harga_beli_snapshot REAL');
    await _addColumnIfMissing(db, 'stok', 'stok_sebelum INTEGER');
    await _addColumnIfMissing(db, 'stok', 'stok_sesudah INTEGER');
    await _addColumnIfMissing(db, 'stok', 'created_at TEXT');
    await db.execute('''
      UPDATE stok
      SET tipe_mutasi = CASE
        WHEN LOWER(COALESCE(catatan, '')) LIKE '%stok awal%' THEN 'SALDO_AWAL'
        WHEN LOWER(COALESCE(catatan, '')) LIKE '%penjualan%' THEN 'PENJUALAN'
        WHEN jenis = 'masuk' THEN 'PENYESUAIAN_MASUK'
        ELSE 'PENYESUAIAN_KELUAR'
      END
      WHERE tipe_mutasi IS NULL OR TRIM(tipe_mutasi) = ''
         OR tipe_mutasi = 'PENYESUAIAN_MASUK'
    ''');
    await db.execute(
      'UPDATE stok SET created_at = COALESCE(created_at, tanggal)',
    );

    await _createPurchaseTables(db);
  }

  Future<void> _migrateToV5(Database db) async {
    await _addColumnIfMissing(db, 'stok', 'alasan TEXT');
  }

  Future<void> _migrateToV6(Database db) async {
    await _addColumnIfMissing(db, 'obat', 'awl INTEGER NOT NULL DEFAULT 0');
    await _addColumnIfMissing(db, 'obat', 'msk INTEGER NOT NULL DEFAULT 0');
    await _addColumnIfMissing(db, 'obat', 'klr INTEGER NOT NULL DEFAULT 0');

    await db.execute('''
      UPDATE obat
      SET awl = COALESCE((
            SELECT SUM(s.jumlah)
            FROM stok s
            WHERE s.obat_id = obat.id
              AND s.jenis = 'masuk'
              AND s.tipe_mutasi = 'SALDO_AWAL'
          ), 0),
          msk = COALESCE((
            SELECT SUM(s.jumlah)
            FROM stok s
            WHERE s.obat_id = obat.id
              AND s.jenis = 'masuk'
              AND s.tipe_mutasi <> 'SALDO_AWAL'
          ), 0),
          klr = COALESCE((
            SELECT SUM(s.jumlah)
            FROM stok s
            WHERE s.obat_id = obat.id
              AND s.jenis = 'keluar'
          ), 0)
    ''');

    await db.execute('''
      UPDATE obat
      SET awl = stok_tersedia
      WHERE awl = 0 AND msk = 0 AND klr = 0 AND stok_tersedia > 0
    ''');
  }

  Future<void> _migrateToV7(Database db) async {
    await _addColumnIfMissing(
      db,
      'transaksi',
      'total_sebelum_diskon REAL NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      'transaksi',
      'diskon REAL NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      'transaksi',
      'diberi_diskon INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(db, 'transaksi', 'laporan_tanggal TEXT');
    await _addColumnIfMissing(db, 'transaksi', 'kode_laporan TEXT');
    await _addColumnIfMissing(db, 'transaksi', 'user_id INTEGER');
    await _addColumnIfMissing(db, 'transaksi', 'username_snapshot TEXT');

    await _addColumnIfMissing(db, 'stok', 'kode_transaksi TEXT');
    await _addColumnIfMissing(db, 'stok', 'batch_no TEXT');
    await _addColumnIfMissing(db, 'stok', 'expired_date TEXT');
    await _addColumnIfMissing(db, 'stok', 'user_id INTEGER');
    await _addColumnIfMissing(db, 'stok', 'username_snapshot TEXT');

    await _addColumnIfMissing(db, 'pembelian', 'user_id INTEGER');
    await _addColumnIfMissing(db, 'pembelian', 'username_snapshot TEXT');
    await _addColumnIfMissing(db, 'detail_pembelian', 'batch_no TEXT');
    await _addColumnIfMissing(db, 'detail_pembelian', 'expired_date TEXT');

    await _createUserTables(db);
    await _createBatchTable(db);
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String columnDefinition,
  ) async {
    final columnName = columnDefinition.trim().split(RegExp(r'\s+')).first;
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == columnName);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $columnDefinition');
    }
  }

  Future<void> _createPurchaseTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pembelian (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nomor_pembelian TEXT NOT NULL UNIQUE,
        supplier_id INTEGER,
        tanggal TEXT NOT NULL,
        nomor_faktur TEXT,
        subtotal REAL NOT NULL DEFAULT 0,
        diskon REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        catatan TEXT,
        user_id INTEGER,
        username_snapshot TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (supplier_id) REFERENCES supplier(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS detail_pembelian (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pembelian_id INTEGER NOT NULL,
        obat_id INTEGER NOT NULL,
        qty INTEGER NOT NULL,
        harga_beli REAL NOT NULL,
        subtotal REAL NOT NULL,
        batch_no TEXT,
        expired_date TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (pembelian_id) REFERENCES pembelian(id),
        FOREIGN KEY (obat_id) REFERENCES obat(id)
      )
    ''');
  }

  Future<void> _createUserTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pengguna (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        nama_tampilan TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'KARYAWAN',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        username_snapshot TEXT,
        role_snapshot TEXT,
        aksi TEXT NOT NULL,
        entitas TEXT NOT NULL,
        entitas_id INTEGER,
        metode_pembayaran TEXT,
        nominal REAL,
        alasan TEXT,
        detail TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES pengguna(id)
      )
    ''');
  }

  Future<void> _createBatchTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stok_batch (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        obat_id INTEGER NOT NULL,
        batch_no TEXT,
        expired_date TEXT,
        qty_masuk INTEGER NOT NULL DEFAULT 0,
        qty_keluar INTEGER NOT NULL DEFAULT 0,
        stok_sisa INTEGER NOT NULL DEFAULT 0,
        supplier_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (obat_id) REFERENCES obat(id),
        FOREIGN KEY (supplier_id) REFERENCES supplier(id)
      )
    ''');
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
      'CREATE INDEX IF NOT EXISTS idx_stok_tipe ON stok(tipe_mutasi)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stok_reference ON stok(reference_type, reference_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stok_alasan ON stok(alasan)',
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
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pembelian_tanggal ON pembelian(tanggal)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pembelian_supplier ON pembelian(supplier_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_detail_pembelian ON detail_pembelian(pembelian_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_detail_pembelian_obat ON detail_pembelian(obat_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transaksi_laporan ON transaksi(laporan_tanggal, metode_pembayaran)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stok_kode_transaksi ON stok(kode_transaksi)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stok_batch ON stok(obat_id, batch_no)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_batch_expired ON stok_batch(obat_id, expired_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_log(created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_log(user_id)',
    );
  }

  Future<void> _seedDefaultCategories(Database db) async {
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
  }
}
