import 'package:firdan_farma_windows/data/database/database_helper.dart';
import 'package:firdan_farma_windows/data/models/stok_model.dart';

class StokService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<StokMutasi>> getAllMutasi({int limit = 300}) async {
    final db = await _dbHelper.database;
    final sql = '''
      SELECT s.*, o.nama AS nama_obat
      FROM stok s
      LEFT JOIN obat o ON s.obat_id = o.id
      ORDER BY s.tanggal DESC
      LIMIT ?
    ''';
    final maps = await db.rawQuery(sql, [limit]);
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
      final obatMaps = await txn.query(
        'obat',
        where: 'id = ?',
        whereArgs: [obatId],
      );
      if (obatMaps.isEmpty) return false;

      final stokTersedia = obatMaps.first['stok_tersedia'] as int;
      int stokBaru = stokTersedia;

      if (jenis == 'masuk') {
        stokBaru += jumlah;
      } else if (jenis == 'keluar') {
        if (stokTersedia < jumlah) {
          throw Exception(
            'Stok tidak mencukupi untuk dikurangi ($stokTersedia tersedia)',
          );
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
        'catatan':
            catatan ??
            (jenis == 'masuk' ? 'Stok Masuk Manual' : 'Stok Keluar Manual'),
        'tanggal': now,
      });

      return true;
    });
  }
}
