import 'package:firdan_farma_windows/data/database/database_helper.dart';
import 'package:firdan_farma_windows/data/models/kategori_model.dart';

class KategoriService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<KategoriObat>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('kategori_obat', orderBy: 'nama ASC');
    return maps.map((m) => KategoriObat.fromMap(m)).toList();
  }

  Future<KategoriObat?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'kategori_obat',
      where: 'id = ?',
      whereArgs: [id],
    );
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
