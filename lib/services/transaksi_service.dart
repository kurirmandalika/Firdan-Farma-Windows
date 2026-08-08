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
        LEFT JOIN obat o ON d.obat_id = o.id
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
