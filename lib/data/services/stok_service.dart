import 'package:firdan_farma_windows/data/database/database_helper.dart';
import 'package:firdan_farma_windows/data/models/stok_model.dart';

class StokService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<StokMutasi>> getAllMutasi({int limit = 300}) async {
    final db = await _dbHelper.database;
    final sql = '''
      SELECT s.*, o.nama AS nama_obat
           , o.kode_obat AS kode_obat
           , o.satuan AS satuan
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
    String? alasan,
    double? hargaBeli,
    String? catatan,
  }) async {
    if (jumlah <= 0) return false;
    final cleanNote = catatan?.trim();
    if (cleanNote == null || cleanNote.isEmpty) {
      throw Exception('Catatan/alasan penyesuaian stok wajib diisi.');
    }

    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      final obatMaps = await txn.query(
        'obat',
        where: 'id = ?',
        whereArgs: [obatId],
      );
      if (obatMaps.isEmpty) return false;

      final stokTersedia = obatMaps.first['stok_tersedia'] as int;
      final hargaBeliSaatIni = (obatMaps.first['harga_beli'] as num).toDouble();
      int stokBaru = stokTersedia;
      late final String tipeMutasi;
      final alasanKode = alasan?.trim().toUpperCase();
      var hargaBeliEfektif = hargaBeliSaatIni;

      if (jenis == 'masuk') {
        if (hargaBeli == null || hargaBeli < 0) {
          throw Exception(
            'Harga beli stok masuk wajib diisi dan tidak boleh negatif.',
          );
        }
        stokBaru += jumlah;
        tipeMutasi = 'STOK_MASUK';
        hargaBeliEfektif = hargaBeli;
      } else if (jenis == 'keluar') {
        const allowedReasons = {
          'PENYESUAIAN',
          'RUSAK',
          'KEDALUWARSA',
          'RETUR_SUPPLIER',
          'LAINNYA',
        };
        if (alasanKode == null || !allowedReasons.contains(alasanKode)) {
          throw Exception('Pilih alasan stok keluar terlebih dahulu.');
        }
        if (stokTersedia < jumlah) {
          throw Exception(
            'Stok tidak mencukupi. Stok tersedia: $stokTersedia.',
          );
        }
        stokBaru -= jumlah;
        tipeMutasi = alasanKode == 'PENYESUAIAN'
            ? 'PENYESUAIAN_KELUAR'
            : alasanKode;
      } else {
        return false;
      }

      final now = DateTime.now().toIso8601String();
      await txn.update(
        'obat',
        {
          'stok_tersedia': stokBaru,
          if (jenis == 'masuk') 'harga_beli': hargaBeliEfektif,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [obatId],
      );

      await txn.insert('stok', {
        'obat_id': obatId,
        'jenis': jenis,
        'jumlah': jumlah,
        'tipe_mutasi': tipeMutasi,
        'reference_type': 'penyesuaian_stok',
        'harga_beli_snapshot': hargaBeliEfektif,
        'stok_sebelum': stokTersedia,
        'stok_sesudah': stokBaru,
        'alasan': jenis == 'masuk' ? 'RESTOK' : alasanKode,
        'catatan': cleanNote,
        'tanggal': now,
        'created_at': now,
      });

      return true;
    });
  }

  Future<bool> adjustToPhysicalStock({
    required int obatId,
    required int stokFisik,
    required String alasan,
    String? catatan,
  }) async {
    if (stokFisik < 0) {
      throw Exception('Stok fisik tidak boleh kurang dari 0.');
    }
    final db = await _dbHelper.database;
    return db.transaction((txn) async {
      final obatMaps = await txn.query(
        'obat',
        where: 'id = ?',
        whereArgs: [obatId],
      );
      if (obatMaps.isEmpty) return false;

      final stokSistem = obatMaps.first['stok_tersedia'] as int;
      final selisih = stokFisik - stokSistem;
      if (selisih == 0) return true;

      final hargaBeli = (obatMaps.first['harga_beli'] as num).toDouble();
      final jenis = selisih > 0 ? 'masuk' : 'keluar';
      final tipeMutasi = selisih > 0
          ? 'PENYESUAIAN_MASUK'
          : 'PENYESUAIAN_KELUAR';
      final now = DateTime.now().toIso8601String();
      await txn.update(
        'obat',
        {'stok_tersedia': stokFisik, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [obatId],
      );
      await txn.insert('stok', {
        'obat_id': obatId,
        'jenis': jenis,
        'jumlah': selisih.abs(),
        'tipe_mutasi': tipeMutasi,
        'reference_type': 'stok_opname',
        'harga_beli_snapshot': hargaBeli,
        'stok_sebelum': stokSistem,
        'stok_sesudah': stokFisik,
        'alasan': alasan.trim().toUpperCase(),
        'catatan':
            '$alasan${catatan?.trim().isNotEmpty == true ? ': ${catatan!.trim()}' : ''}',
        'tanggal': now,
        'created_at': now,
      });
      return true;
    });
  }
}
