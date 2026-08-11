import 'package:firdan_farma_windows/data/database/database_helper.dart';
import 'package:firdan_farma_windows/data/models/supplier_model.dart';

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
