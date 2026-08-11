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
      sql += ' AND (o.nama LIKE ? OR o.kode_obat LIKE ?)';
      args.add('%${searchQuery.trim()}%');
      args.add('%${searchQuery.trim()}%');
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
        {'is_active': 0},
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
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
