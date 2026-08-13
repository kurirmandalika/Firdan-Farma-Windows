import 'package:intl/intl.dart';
import 'package:firdan_farma_windows/data/database/database_helper.dart';
import 'package:firdan_farma_windows/data/models/detail_pembelian_model.dart';
import 'package:firdan_farma_windows/data/models/pembelian_model.dart';

class PembelianService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> generateNomorPembelian() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final datePrefix = DateFormat('yyyyMMdd').format(now);
    final maps = await db.rawQuery(
      "SELECT COUNT(*) as count FROM pembelian WHERE nomor_pembelian LIKE ?",
      ['BELI-$datePrefix-%'],
    );
    final count = (maps.first['count'] as int? ?? 0) + 1;
    return 'BELI-$datePrefix-${count.toString().padLeft(4, '0')}';
  }

  Future<Pembelian> createPembelian({
    int? supplierId,
    DateTime? tanggal,
    String? nomorFaktur,
    double diskon = 0,
    String? catatan,
    required List<DetailPembelian> items,
  }) async {
    if (items.isEmpty) {
      throw Exception('Tambahkan minimal satu obat pada pembelian.');
    }
    if (diskon < 0) {
      throw Exception('Diskon tidak boleh kurang dari 0.');
    }
    for (final item in items) {
      if (item.qty <= 0) throw Exception('Jumlah obat harus lebih dari 0.');
      if (item.hargaBeli < 0) {
        throw Exception('Harga beli tidak boleh kurang dari 0.');
      }
    }

    final db = await _dbHelper.database;
    final nomor = await generateNomorPembelian();
    final now = DateTime.now().toIso8601String();
    final tanggalStr = (tanggal ?? DateTime.now()).toIso8601String();
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.subtotal);
    if (diskon > subtotal) {
      throw Exception('Diskon tidak boleh lebih besar dari subtotal.');
    }
    final total = subtotal - diskon;

    return db.transaction((txn) async {
      final pembelianId = await txn.insert('pembelian', {
        'nomor_pembelian': nomor,
        'supplier_id': supplierId,
        'tanggal': tanggalStr,
        'nomor_faktur': nomorFaktur?.trim().isEmpty == true
            ? null
            : nomorFaktur?.trim(),
        'subtotal': subtotal,
        'diskon': diskon,
        'total': total,
        'catatan': catatan?.trim().isEmpty == true ? null : catatan?.trim(),
        'created_at': now,
        'updated_at': now,
      });

      final savedItems = <DetailPembelian>[];
      for (final item in items) {
        final obatMaps = await txn.query(
          'obat',
          where: 'id = ?',
          whereArgs: [item.obatId],
        );
        if (obatMaps.isEmpty) {
          throw Exception('Obat ID ${item.obatId} tidak ditemukan.');
        }
        final obat = obatMaps.first;
        final stokSebelum = obat['stok_tersedia'] as int;
        final stokSesudah = stokSebelum + item.qty;

        final detailId = await txn.insert('detail_pembelian', {
          'pembelian_id': pembelianId,
          'obat_id': item.obatId,
          'qty': item.qty,
          'harga_beli': item.hargaBeli,
          'subtotal': item.subtotal,
          'created_at': now,
        });

        await txn.update(
          'obat',
          {
            'stok_tersedia': stokSesudah,
            'harga_beli': item.hargaBeli,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [item.obatId],
        );

        await txn.insert('stok', {
          'obat_id': item.obatId,
          'jenis': 'masuk',
          'jumlah': item.qty,
          'tipe_mutasi': 'PEMBELIAN',
          'reference_type': 'pembelian',
          'reference_id': pembelianId,
          'harga_beli_snapshot': item.hargaBeli,
          'stok_sebelum': stokSebelum,
          'stok_sesudah': stokSesudah,
          'alasan': 'PEMBELIAN',
          'catatan': 'Pembelian $nomor',
          'tanggal': tanggalStr,
          'created_at': now,
        });

        savedItems.add(
          DetailPembelian(
            id: detailId,
            pembelianId: pembelianId,
            obatId: item.obatId,
            qty: item.qty,
            hargaBeli: item.hargaBeli,
            subtotal: item.subtotal,
            createdAt: now,
            namaObat: obat['nama'] as String?,
            kodeObat: obat['kode_obat'] as String?,
            satuan: obat['satuan'] as String?,
          ),
        );
      }

      return Pembelian(
        id: pembelianId,
        nomorPembelian: nomor,
        supplierId: supplierId,
        tanggal: tanggalStr,
        nomorFaktur: nomorFaktur,
        subtotal: subtotal,
        diskon: diskon,
        total: total,
        catatan: catatan,
        createdAt: now,
        updatedAt: now,
        items: savedItems,
      );
    });
  }

  Future<List<Pembelian>> getAll({int limit = 100}) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT p.*, s.nama AS nama_supplier
      FROM pembelian p
      LEFT JOIN supplier s ON p.supplier_id = s.id
      ORDER BY p.tanggal DESC, p.id DESC
      LIMIT ?
      ''',
      [limit],
    );

    final result = <Pembelian>[];
    for (final map in maps) {
      final id = map['id'] as int;
      final detailMaps = await db.rawQuery(
        '''
        SELECT d.*, o.nama AS nama_obat, o.kode_obat AS kode_obat, o.satuan AS satuan
        FROM detail_pembelian d
        LEFT JOIN obat o ON d.obat_id = o.id
        WHERE d.pembelian_id = ?
        ORDER BY d.id ASC
        ''',
        [id],
      );
      result.add(
        Pembelian.fromMap(
          map,
          items: detailMaps.map(DetailPembelian.fromMap).toList(),
        ),
      );
    }
    return result;
  }

  Future<double> getTodayTotal() async {
    final db = await _dbHelper.database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final result = await db.rawQuery(
      "SELECT SUM(total) AS total FROM pembelian WHERE tanggal LIKE ?",
      ['$today%'],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
