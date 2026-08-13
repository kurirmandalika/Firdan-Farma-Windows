import 'package:firdan_farma_windows/data/database/database_helper.dart';
import 'package:firdan_farma_windows/data/models/obat_model.dart';

class ObatService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Obat>> getAll({
    String? searchQuery,
    int? kategoriId,
    bool includeInactive = false,
  }) async {
    final db = await _dbHelper.database;
    String sql = '''
      SELECT o.*, k.nama AS nama_kategori, s.nama AS nama_supplier
      FROM obat o
      LEFT JOIN kategori_obat k ON o.kategori_id = k.id
      LEFT JOIN supplier s ON o.supplier_id = s.id
      WHERE 1=1
    ''';
    List<dynamic> args = [];

    if (!includeInactive) {
      sql += ' AND o.is_active = 1';
    }

    if (kategoriId != null && kategoriId > 0) {
      sql += ' AND o.kategori_id = ?';
      args.add(kategoriId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      sql += ' AND (LOWER(o.nama) LIKE ? OR LOWER(o.kode_obat) LIKE ?)';
      final q = '%${searchQuery.trim().toLowerCase()}%';
      args.add(q);
      args.add(q);
    }

    sql += ' ORDER BY o.nama ASC';

    final maps = await db.rawQuery(sql, args);
    return maps.map((m) => Obat.fromMap(m)).toList();
  }

  Future<int> countActive() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM obat WHERE is_active = 1',
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<List<Obat>> getLowStock() async {
    final db = await _dbHelper.database;
    final sql = '''
      SELECT o.*, k.nama AS nama_kategori, s.nama AS nama_supplier
      FROM obat o
      LEFT JOIN kategori_obat k ON o.kategori_id = k.id
      LEFT JOIN supplier s ON o.supplier_id = s.id
      WHERE o.is_active = 1 AND o.stok_tersedia <= o.stok_minimal
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
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      final kode = obat.kodeObat.trim().isEmpty
          ? await _generateNextKodeObat(txn)
          : obat.kodeObat.trim().toUpperCase();

      final id = await txn.insert('obat', {
        'nama': obat.nama.trim(),
        'kode_obat': kode,
        'satuan': obat.satuan.trim().isEmpty
            ? 'PCS'
            : obat.satuan.trim().toUpperCase(),
        'kategori_id': obat.kategoriId,
        'supplier_id': obat.supplierId,
        'harga_beli': obat.hargaBeli,
        'harga_jual': obat.hargaJual,
        'stok_minimal': obat.stokMinimal,
        'stok_tersedia': obat.stokTersedia,
        'deskripsi': obat.deskripsi?.trim(),
        'is_active': obat.isActive ? 1 : 0,
        'created_at': obat.createdAt,
        'updated_at': now,
      });

      if (obat.stokTersedia > 0) {
        await txn.insert('stok', {
          'obat_id': id,
          'jenis': 'masuk',
          'jumlah': obat.stokTersedia,
          'tipe_mutasi': 'SALDO_AWAL',
          'harga_beli_snapshot': obat.hargaBeli,
          'stok_sebelum': 0,
          'stok_sesudah': obat.stokTersedia,
          'alasan': 'SALDO_AWAL',
          'catatan': 'Stok awal saat obat dibuat',
          'tanggal': now,
          'created_at': now,
        });
      }

      return id;
    });
  }

  Future<int> update(Obat obat) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return await db.update(
      'obat',
      {
        'nama': obat.nama.trim(),
        'kode_obat': obat.kodeObat.trim().toUpperCase(),
        'satuan': obat.satuan.trim().isEmpty
            ? 'PCS'
            : obat.satuan.trim().toUpperCase(),
        'kategori_id': obat.kategoriId,
        'supplier_id': obat.supplierId,
        'harga_beli': obat.hargaBeli,
        'harga_jual': obat.hargaJual,
        'stok_minimal': obat.stokMinimal,
        'deskripsi': obat.deskripsi?.trim(),
        'is_active': obat.isActive ? 1 : 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [obat.id],
    );
  }

  Future<String> _generateNextKodeObat(dynamic executor) async {
    final maps = await executor.rawQuery(
      "SELECT kode_obat FROM obat WHERE kode_obat LIKE 'OBT%' ORDER BY id DESC LIMIT 1",
    );
    var next = 1;
    if (maps.isNotEmpty) {
      final code = maps.first['kode_obat'] as String? ?? '';
      final digits = RegExp(r'(\d+)$').firstMatch(code)?.group(1);
      if (digits != null) next = (int.tryParse(digits) ?? 0) + 1;
    }
    return 'OBT${next.toString().padLeft(6, '0')}';
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    final txMaps = await db.rawQuery(
      'SELECT COUNT(*) as count FROM detail_transaksi WHERE obat_id = ?',
      [id],
    );
    final stokMaps = await db.rawQuery(
      'SELECT COUNT(*) as count FROM stok WHERE obat_id = ?',
      [id],
    );

    final txCount = txMaps.first['count'] as int? ?? 0;
    final stokCount = stokMaps.first['count'] as int? ?? 0;

    if (txCount > 0 || stokCount > 0) {
      // Soft delete
      return await db.update(
        'obat',
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      // Hard delete
      return await db.delete('obat', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<int> reactivate(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'obat',
      {'is_active': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Archives active medicines that are not present in a replacement import.
  ///
  /// Soft deletion keeps transaction and stock history valid while removing
  /// stale rows from the default active catalog.
  Future<int> archiveExceptCodes(Set<String> codes) async {
    final db = await _dbHelper.database;
    if (codes.isEmpty) {
      return db.update('obat', {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      }, where: 'is_active = 1');
    }

    final placeholders = List.filled(codes.length, '?').join(', ');
    return db.rawUpdate(
      'UPDATE obat SET is_active = 0, updated_at = ? '
      'WHERE is_active = 1 AND kode_obat NOT IN ($placeholders)',
      [DateTime.now().toIso8601String(), ...codes],
    );
  }
}
